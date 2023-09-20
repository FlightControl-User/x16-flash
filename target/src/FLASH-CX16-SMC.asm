  // File Comments
/**
 * @mainpage cx16-rom-flash.c
 * @author Sven Van de Velde (https://www.commanderx16.com/forum/index.php?/profile/1249-svenvandevelde/)
 * @author Wavicle from CX16 forums (https://www.commanderx16.com/forum/index.php?/profile/1585-wavicle/)
 * @brief COMMANDER X16 ROM FLASH UTILITY
 *
 *
 *
 * @version 1.1
 * @date 2023-02-27
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
  .const STATUS_CHECKING = 3
  .const STATUS_COMPARING = 4
  .const STATUS_FLASH = 5
  .const STATUS_FLASHING = 6
  .const STATUS_FLASHED = 7
  .const STATUS_ISSUE = 8
  .const STATUS_ERROR = 9
  .const PROGRESS_CELL = $200
  .const PROGRESS_ROW = $8000
  .const OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS = 1
  .const STACK_BASE = $103
  .const SIZEOF_STRUCT___1 = $8f
  .const SIZEOF_STRUCT_PRINTF_BUFFER_NUMBER = $c
  .const SIZEOF_STRUCT___2 = $120
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
  .label __errno = $e7
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
// void snputc(__zp($e1) char c)
snputc: {
    .const OFFSET_STACK_C = 0
    .label c = $e1
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
    .label conio_x16_init__5 = $d7
    // screenlayer1()
    // [20] call screenlayer1
    jsr screenlayer1
    // [21] phi from conio_x16_init to conio_x16_init::@1 [phi:conio_x16_init->conio_x16_init::@1]
    // conio_x16_init::@1
    // textcolor(CONIO_TEXTCOLOR_DEFAULT)
    // [22] call textcolor
    // [461] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [461] phi textcolor::color#16 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [23] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [24] call bgcolor
    // [466] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [466] phi bgcolor::color#14 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbuz1=vbuc1 
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
    // [479] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [479] phi gotoxy::y#29 = gotoxy::y#2 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [479] phi gotoxy::x#29 = gotoxy::x#2 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
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
// void cputc(__zp($40) char c)
cputc: {
    .const OFFSET_STACK_C = 0
    .label cputc__1 = $22
    .label cputc__2 = $ba
    .label cputc__3 = $bb
    .label c = $40
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
    .const bank_set_brom4_bank = 4
    .const bank_set_brom5_bank = 0
    .label main__93 = $2a
    .label check_smc1_main__0 = $32
    .label check_smc2_main__0 = $de
    .label check_cx16_rom1_check_rom1_main__0 = $dd
    .label check_smc4_main__0 = $25
    .label check_rom1_main__0 = $e4
    .label check_smc5_main__0 = $dc
    .label check_roms1_check_rom1_main__0 = $da
    .label check_smc6_main__0 = $db
    .label check_smc1_return = $32
    .label check_smc2_return = $de
    .label check_cx16_rom1_check_rom1_return = $dd
    .label check_smc4_return = $25
    .label check_rom1_return = $e4
    .label check_smc5_return = $dc
    .label check_roms1_check_rom1_return = $da
    .label rom_differences = $26
    .label check_smc6_return = $db
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
    // main::@45
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
    // [77] phi from main::cx16_k_screen_set_charset1 to main::@46 [phi:main::cx16_k_screen_set_charset1->main::@46]
    // main::@46
    // frame_init()
    // [78] call frame_init
    // [500] phi from main::@46 to frame_init [phi:main::@46->frame_init]
    jsr frame_init
    // [79] phi from main::@46 to main::@64 [phi:main::@46->main::@64]
    // main::@64
    // frame_draw()
    // [80] call frame_draw
    // [520] phi from main::@64 to frame_draw [phi:main::@64->frame_draw]
    jsr frame_draw
    // [81] phi from main::@64 to main::@65 [phi:main::@64->main::@65]
    // main::@65
    // info_title("Commander X16 Flash Utility!")
    // [82] call info_title
    // [559] phi from main::@65 to info_title [phi:main::@65->info_title]
    jsr info_title
    // [83] phi from main::@65 to main::@66 [phi:main::@65->main::@66]
    // main::@66
    // progress_clear()
    // [84] call progress_clear
    // [564] phi from main::@66 to progress_clear [phi:main::@66->progress_clear]
    jsr progress_clear
    // [85] phi from main::@66 to main::@67 [phi:main::@66->main::@67]
    // main::@67
    // info_clear_all()
    // [86] call info_clear_all
    // [579] phi from main::@67 to info_clear_all [phi:main::@67->info_clear_all]
    jsr info_clear_all
    // [87] phi from main::@67 to main::@68 [phi:main::@67->main::@68]
    // main::@68
    // info_progress("Detecting SMC, VERA and ROM chipsets ...")
    // [88] call info_progress
  // info_print(0, "The SMC chip on the X16 board controls the power on/off, keyboard and mouse pheripherals.");
  // info_print(1, "It is essential that the SMC chip gets updated together with the latest ROM on the X16 board.");
  // info_print(2, "On the X16 board, near the SMC chip are two jumpers");
    // [589] phi from main::@68 to info_progress [phi:main::@68->info_progress]
    // [589] phi info_progress::info_text#12 = main::info_text1 [phi:main::@68->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z info_progress.info_text
    lda #>info_text1
    sta.z info_progress.info_text+1
    jsr info_progress
    // main::SEI1
    // asm
    // asm { sei  }
    sei
    // [90] phi from main::SEI1 to main::@47 [phi:main::SEI1->main::@47]
    // main::@47
    // smc_detect()
    // [91] call smc_detect
    jsr smc_detect
    // [92] smc_detect::return#2 = smc_detect::return#0
    // main::@69
    // smc_bootloader = smc_detect()
    // [93] smc_bootloader#0 = smc_detect::return#2 -- vwum1=vwuz2 
    lda.z smc_detect.return
    sta smc_bootloader
    lda.z smc_detect.return+1
    sta smc_bootloader+1
    // chip_smc()
    // [94] call chip_smc
    // [614] phi from main::@69 to chip_smc [phi:main::@69->chip_smc]
    jsr chip_smc
    // main::@70
    // if(smc_bootloader == 0x0100)
    // [95] if(smc_bootloader#0==$100) goto main::@1 -- vwum1_eq_vwuc1_then_la1 
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
    // [96] if(smc_bootloader#0==$200) goto main::@9 -- vwum1_eq_vwuc1_then_la1 
    lda smc_bootloader
    cmp #<$200
    bne !+
    lda smc_bootloader+1
    cmp #>$200
    bne !__b9+
    jmp __b9
  !__b9:
  !:
    // main::@4
    // if(smc_bootloader > 0x2)
    // [97] if(smc_bootloader#0>=2+1) goto main::@10 -- vwum1_ge_vbuc1_then_la1 
    lda smc_bootloader+1
    beq !__b10+
    jmp __b10
  !__b10:
    lda smc_bootloader
    cmp #2+1
    bcc !__b10+
    jmp __b10
  !__b10:
  !:
    // [98] phi from main::@4 to main::@5 [phi:main::@4->main::@5]
    // main::@5
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [99] call snprintf_init
    jsr snprintf_init
    // [100] phi from main::@5 to main::@75 [phi:main::@5->main::@75]
    // main::@75
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [101] call printf_str
    // [623] phi from main::@75 to printf_str [phi:main::@75->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:main::@75->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = main::s [phi:main::@75->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // main::@76
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [102] printf_uint::uvalue#14 = smc_bootloader#0 -- vwuz1=vwum2 
    lda smc_bootloader
    sta.z printf_uint.uvalue
    lda smc_bootloader+1
    sta.z printf_uint.uvalue+1
    // [103] call printf_uint
    // [632] phi from main::@76 to printf_uint [phi:main::@76->printf_uint]
    // [632] phi printf_uint::format_zero_padding#16 = 1 [phi:main::@76->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [632] phi printf_uint::format_min_length#16 = 2 [phi:main::@76->printf_uint#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uint.format_min_length
    // [632] phi printf_uint::putc#16 = &snputc [phi:main::@76->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [632] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:main::@76->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [632] phi printf_uint::uvalue#16 = printf_uint::uvalue#14 [phi:main::@76->printf_uint#4] -- register_copy 
    jsr printf_uint
    // main::@77
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [104] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [105] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_smc(STATUS_DETECTED, info_text)
    // [107] call info_smc
    // [643] phi from main::@77 to info_smc [phi:main::@77->info_smc]
    // [643] phi info_smc::info_text#11 = info_text [phi:main::@77->info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_smc.info_text
    lda #>@info_text
    sta.z info_smc.info_text+1
    // [643] phi smc_file_size#12 = 0 [phi:main::@77->info_smc#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size_2
    sta smc_file_size_2+1
    // [643] phi info_smc::info_status#11 = STATUS_DETECTED [phi:main::@77->info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_DETECTED
    sta info_smc.info_status
    jsr info_smc
    // main::CLI1
  CLI1:
    // asm
    // asm { cli  }
    cli
    // [109] phi from main::CLI1 to main::@48 [phi:main::CLI1->main::@48]
    // main::@48
    // chip_vera()
    // [110] call chip_vera
  // Detecting VERA FPGA.
    // [664] phi from main::@48 to chip_vera [phi:main::@48->chip_vera]
    jsr chip_vera
    // [111] phi from main::@48 to main::@78 [phi:main::@48->main::@78]
    // main::@78
    // info_vera(STATUS_DETECTED, "VERA installed, OK")
    // [112] call info_vera
    // [669] phi from main::@78 to info_vera [phi:main::@78->info_vera]
    // [669] phi info_vera::info_text#2 = main::info_text4 [phi:main::@78->info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z info_vera.info_text
    lda #>info_text4
    sta.z info_vera.info_text+1
    // [669] phi info_vera::info_status#2 = STATUS_DETECTED [phi:main::@78->info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_DETECTED
    sta.z info_vera.info_status
    jsr info_vera
    // main::SEI2
    // asm
    // asm { sei  }
    sei
    // [114] phi from main::SEI2 to main::@49 [phi:main::SEI2->main::@49]
    // main::@49
    // rom_detect()
    // [115] call rom_detect
  // Detecting ROM chips
    // [686] phi from main::@49 to rom_detect [phi:main::@49->rom_detect]
    jsr rom_detect
    // [116] phi from main::@49 to main::@79 [phi:main::@49->main::@79]
    // main::@79
    // chip_rom()
    // [117] call chip_rom
    // [736] phi from main::@79 to chip_rom [phi:main::@79->chip_rom]
    jsr chip_rom
    // [118] phi from main::@79 to main::@11 [phi:main::@79->main::@11]
    // [118] phi main::rom_chip#2 = 0 [phi:main::@79->main::@11#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // main::@11
  __b11:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [119] if(main::rom_chip#2<8) goto main::@12 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcs !__b12+
    jmp __b12
  !__b12:
    // main::CLI2
    // asm
    // asm { cli  }
    cli
    // main::SEI3
    // asm { sei  }
    sei
    // main::check_smc1
    // status_smc == status
    // [122] main::check_smc1_$0 = status_smc#0 == STATUS_DETECTED -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_DETECTED
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_smc1_main__0
    // return (unsigned char)(status_smc == status);
    // [123] main::check_smc1_return#0 = (char)main::check_smc1_$0
    // main::@50
    // if(check_smc(STATUS_DETECTED))
    // [124] if(0==main::check_smc1_return#0) goto main::CLI3 -- 0_eq_vbuz1_then_la1 
    lda.z check_smc1_return
    bne !__b4+
    jmp __b4
  !__b4:
    // [125] phi from main::@50 to main::@16 [phi:main::@50->main::@16]
    // main::@16
    // smc_read(8, 512)
    // [126] call smc_read
    // [754] phi from main::@16 to smc_read [phi:main::@16->smc_read]
    // [754] phi __errno#35 = 0 [phi:main::@16->smc_read#0] -- vwsz1=vwsc1 
    lda #<0
    sta.z __errno
    sta.z __errno+1
    jsr smc_read
    // smc_read(8, 512)
    // [127] smc_read::return#2 = smc_read::return#0
    // main::@80
    // smc_file_size = smc_read(8, 512)
    // [128] smc_file_size#0 = smc_read::return#2 -- vwum1=vwum2 
    lda smc_read.return
    sta smc_file_size
    lda smc_read.return+1
    sta smc_file_size+1
    // if (!smc_file_size)
    // [129] if(0==smc_file_size#0) goto main::@19 -- 0_eq_vwum1_then_la1 
    // In case no file was found, set the status to error and skip to the next, else, mention the amount of bytes read.
    lda smc_file_size
    ora smc_file_size+1
    bne !__b19+
    jmp __b19
  !__b19:
    // main::@17
    // if(smc_file_size > 0x1E00)
    // [130] if(smc_file_size#0>$1e00) goto main::@20 -- vwum1_gt_vwuc1_then_la1 
    // If the smc.bin file size is larger than 0x1E00 then there is an error!
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
    // [131] phi from main::@17 to main::@18 [phi:main::@17->main::@18]
    // main::@18
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [132] call snprintf_init
    jsr snprintf_init
    // [133] phi from main::@18 to main::@81 [phi:main::@18->main::@81]
    // main::@81
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [134] call printf_str
    // [623] phi from main::@81 to printf_str [phi:main::@81->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:main::@81->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = main::s [phi:main::@81->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // main::@82
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [135] printf_uint::uvalue#15 = smc_bootloader#0 -- vwuz1=vwum2 
    lda smc_bootloader
    sta.z printf_uint.uvalue
    lda smc_bootloader+1
    sta.z printf_uint.uvalue+1
    // [136] call printf_uint
    // [632] phi from main::@82 to printf_uint [phi:main::@82->printf_uint]
    // [632] phi printf_uint::format_zero_padding#16 = 1 [phi:main::@82->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [632] phi printf_uint::format_min_length#16 = 2 [phi:main::@82->printf_uint#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uint.format_min_length
    // [632] phi printf_uint::putc#16 = &snputc [phi:main::@82->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [632] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:main::@82->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [632] phi printf_uint::uvalue#16 = printf_uint::uvalue#15 [phi:main::@82->printf_uint#4] -- register_copy 
    jsr printf_uint
    // main::@83
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [137] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [138] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [140] smc_file_size#283 = smc_file_size#0 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // info_smc(STATUS_FLASH, info_text)
    // [141] call info_smc
    // [643] phi from main::@83 to info_smc [phi:main::@83->info_smc]
    // [643] phi info_smc::info_text#11 = info_text [phi:main::@83->info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_smc.info_text
    lda #>@info_text
    sta.z info_smc.info_text+1
    // [643] phi smc_file_size#12 = smc_file_size#283 [phi:main::@83->info_smc#1] -- register_copy 
    // [643] phi info_smc::info_status#11 = STATUS_FLASH [phi:main::@83->info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta info_smc.info_status
    jsr info_smc
    // [142] phi from main::@19 main::@20 main::@83 to main::CLI3 [phi:main::@19/main::@20/main::@83->main::CLI3]
    // [142] phi smc_file_size#165 = smc_file_size#0 [phi:main::@19/main::@20/main::@83->main::CLI3#0] -- register_copy 
    // [142] phi __errno#248 = __errno#176 [phi:main::@19/main::@20/main::@83->main::CLI3#1] -- register_copy 
    jmp CLI3
    // [142] phi from main::@50 to main::CLI3 [phi:main::@50->main::CLI3]
  __b4:
    // [142] phi smc_file_size#165 = 0 [phi:main::@50->main::CLI3#0] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size
    sta smc_file_size+1
    // [142] phi __errno#248 = 0 [phi:main::@50->main::CLI3#1] -- vwsz1=vwsc1 
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
    // [145] phi from main::SEI4 to main::@21 [phi:main::SEI4->main::@21]
    // [145] phi __errno#110 = __errno#248 [phi:main::SEI4->main::@21#0] -- register_copy 
    // [145] phi main::rom_chip1#10 = 0 [phi:main::SEI4->main::@21#1] -- vbum1=vbuc1 
    lda #0
    sta rom_chip1
  // We loop all the possible ROM chip slots on the board and on the extension card,
  // and we check the file contents.
  // Any error identified gets reported and this chip will not be flashed.
  // In case of ROM0.BIN in error, no flashing will be done!
    // main::@21
  __b21:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [146] if(main::rom_chip1#10<8) goto main::bank_set_brom2 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip1
    cmp #8
    bcs !bank_set_brom2+
    jmp bank_set_brom2
  !bank_set_brom2:
    // main::bank_set_brom3
    // BROM = bank
    // [147] BROM = main::bank_set_brom3_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom3_bank
    sta.z BROM
    // main::CLI4
    // asm
    // asm { cli  }
    cli
    // main::check_smc2
    // status_smc == status
    // [149] main::check_smc2_$0 = status_smc#0 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_smc2_main__0
    // return (unsigned char)(status_smc == status);
    // [150] main::check_smc2_return#0 = (char)main::check_smc2_$0
    // [151] phi from main::check_smc2 to main::check_cx16_rom1 [phi:main::check_smc2->main::check_cx16_rom1]
    // main::check_cx16_rom1
    // main::check_cx16_rom1_check_rom1
    // status_rom[rom_chip] == status
    // [152] main::check_cx16_rom1_check_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_cx16_rom1_check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [153] main::check_cx16_rom1_check_rom1_return#0 = (char)main::check_cx16_rom1_check_rom1_$0
    // main::@52
    // if(!check_smc(STATUS_FLASH) ||!check_cx16_rom(STATUS_FLASH))
    // [154] if(0==main::check_smc2_return#0) goto main::@28 -- 0_eq_vbuz1_then_la1 
    lda.z check_smc2_return
    bne !__b28+
    jmp __b28
  !__b28:
    // main::@141
    // [155] if(0==main::check_cx16_rom1_check_rom1_return#0) goto main::@28 -- 0_eq_vbuz1_then_la1 
    lda.z check_cx16_rom1_check_rom1_return
    bne !__b28+
    jmp __b28
  !__b28:
    // main::check_smc3
  check_smc3:
    // status_smc == status
    // [156] main::check_smc3_$0 = status_smc#0 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_smc3_main__0
    // return (unsigned char)(status_smc == status);
    // [157] main::check_smc3_return#0 = (char)main::check_smc3_$0
    // [158] phi from main::check_smc3 to main::check_cx16_rom2 [phi:main::check_smc3->main::check_cx16_rom2]
    // main::check_cx16_rom2
    // main::check_cx16_rom2_check_rom1
    // status_rom[rom_chip] == status
    // [159] main::check_cx16_rom2_check_rom1_$0 = *status_rom == STATUS_FLASH -- vbom1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_cx16_rom2_check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [160] main::check_cx16_rom2_check_rom1_return#0 = (char)main::check_cx16_rom2_check_rom1_$0
    // [161] phi from main::check_cx16_rom2_check_rom1 to main::check_card_roms1 [phi:main::check_cx16_rom2_check_rom1->main::check_card_roms1]
    // main::check_card_roms1
    // [162] phi from main::check_card_roms1 to main::check_card_roms1_@1 [phi:main::check_card_roms1->main::check_card_roms1_@1]
    // [162] phi main::check_card_roms1_rom_chip#2 = 1 [phi:main::check_card_roms1->main::check_card_roms1_@1#0] -- vbum1=vbuc1 
    lda #1
    sta check_card_roms1_rom_chip
    // main::check_card_roms1_@1
  check_card_roms1___b1:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [163] if(main::check_card_roms1_rom_chip#2<8) goto main::check_card_roms1_check_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda check_card_roms1_rom_chip
    cmp #8
    bcs !check_card_roms1_check_rom1+
    jmp check_card_roms1_check_rom1
  !check_card_roms1_check_rom1:
    // [164] phi from main::check_card_roms1_@1 to main::check_card_roms1_@return [phi:main::check_card_roms1_@1->main::check_card_roms1_@return]
    // [164] phi main::check_card_roms1_return#2 = STATUS_NONE [phi:main::check_card_roms1_@1->main::check_card_roms1_@return#0] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta check_card_roms1_return
    // main::check_card_roms1_@return
    // main::@53
  __b53:
    // if(check_smc(STATUS_FLASH) && check_cx16_rom(STATUS_FLASH) || check_card_roms(STATUS_FLASH))
    // [165] if(0==main::check_smc3_return#0) goto main::@142 -- 0_eq_vbum1_then_la1 
    lda check_smc3_return
    beq __b142
    // main::@143
    // [166] if(0!=main::check_cx16_rom2_check_rom1_return#0) goto main::@6 -- 0_neq_vbum1_then_la1 
    lda check_cx16_rom2_check_rom1_return
    beq !__b6+
    jmp __b6
  !__b6:
    // main::@142
  __b142:
    // [167] if(0!=main::check_card_roms1_return#2) goto main::@6 -- 0_neq_vbum1_then_la1 
    lda check_card_roms1_return
    beq !__b6+
    jmp __b6
  !__b6:
    // main::check_smc4
  check_smc4:
    // status_smc == status
    // [168] main::check_smc4_$0 = status_smc#0 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_smc4_main__0
    // return (unsigned char)(status_smc == status);
    // [169] main::check_smc4_return#0 = (char)main::check_smc4_$0
    // main::@54
    // if (check_smc(STATUS_FLASH))
    // [170] if(0==main::check_smc4_return#0) goto main::@2 -- 0_eq_vbuz1_then_la1 
    lda.z check_smc4_return
    beq __b2
    // main::SEI5
    // asm
    // asm { sei  }
    sei
    // [172] phi from main::SEI5 to main::@55 [phi:main::SEI5->main::@55]
    // main::@55
    // smc_read(8, 512)
    // [173] call smc_read
    // [754] phi from main::@55 to smc_read [phi:main::@55->smc_read]
    // [754] phi __errno#35 = __errno#110 [phi:main::@55->smc_read#0] -- register_copy 
    jsr smc_read
    // smc_read(8, 512)
    // [174] smc_read::return#3 = smc_read::return#0
    // main::@110
    // smc_file_size = smc_read(8, 512)
    // [175] smc_file_size#1 = smc_read::return#3 -- vwum1=vwum2 
    lda smc_read.return
    sta smc_file_size_1
    lda smc_read.return+1
    sta smc_file_size_1+1
    // if(smc_file_size)
    // [176] if(0==smc_file_size#1) goto main::@2 -- 0_eq_vwum1_then_la1 
    lda smc_file_size_1
    ora smc_file_size_1+1
    beq __b2
    // [177] phi from main::@110 to main::@8 [phi:main::@110->main::@8]
    // main::@8
    // info_line("Press both POWER/RESET buttons on the CX16 board!")
    // [178] call info_line
  // Flash the SMC chip.
    // [811] phi from main::@8 to info_line [phi:main::@8->info_line]
    // [811] phi info_line::info_text#17 = main::info_text19 [phi:main::@8->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text19
    sta.z info_line.info_text
    lda #>info_text19
    sta.z info_line.info_text+1
    jsr info_line
    // main::@111
    // [179] smc_file_size#285 = smc_file_size#1 -- vwum1=vwum2 
    lda smc_file_size_1
    sta smc_file_size_2
    lda smc_file_size_1+1
    sta smc_file_size_2+1
    // info_smc(STATUS_FLASHING, "Press POWER/RESET!")
    // [180] call info_smc
    // [643] phi from main::@111 to info_smc [phi:main::@111->info_smc]
    // [643] phi info_smc::info_text#11 = main::info_text20 [phi:main::@111->info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text20
    sta.z info_smc.info_text
    lda #>info_text20
    sta.z info_smc.info_text+1
    // [643] phi smc_file_size#12 = smc_file_size#285 [phi:main::@111->info_smc#1] -- register_copy 
    // [643] phi info_smc::info_status#11 = STATUS_FLASHING [phi:main::@111->info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHING
    sta info_smc.info_status
    jsr info_smc
    // main::@112
    // unsigned long flashed_bytes = flash_smc(PROGRESS_X, PROGRESS_Y, PROGRESS_W, smc_file_size, 8, 512, (ram_ptr_t)RAM_BASE)
    // [181] flash_smc::smc_bytes_total#0 = smc_file_size#1 -- vwuz1=vwum2 
    lda smc_file_size_1
    sta.z flash_smc.smc_bytes_total
    lda smc_file_size_1+1
    sta.z flash_smc.smc_bytes_total+1
    // [182] call flash_smc
    jsr flash_smc
    // main::@113
    // [183] smc_file_size#286 = smc_file_size#1 -- vwum1=vwum2 
    lda smc_file_size_1
    sta smc_file_size_2
    lda smc_file_size_1+1
    sta smc_file_size_2+1
    // info_smc(STATUS_FLASHED, "OK!")
    // [184] call info_smc
    // [643] phi from main::@113 to info_smc [phi:main::@113->info_smc]
    // [643] phi info_smc::info_text#11 = main::info_text10 [phi:main::@113->info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text10
    sta.z info_smc.info_text
    lda #>info_text10
    sta.z info_smc.info_text+1
    // [643] phi smc_file_size#12 = smc_file_size#286 [phi:main::@113->info_smc#1] -- register_copy 
    // [643] phi info_smc::info_status#11 = STATUS_FLASHED [phi:main::@113->info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHED
    sta info_smc.info_status
    jsr info_smc
    // [185] phi from main::@110 main::@113 main::@54 to main::@2 [phi:main::@110/main::@113/main::@54->main::@2]
    // [185] phi __errno#289 = __errno#176 [phi:main::@110/main::@113/main::@54->main::@2#0] -- register_copy 
    // main::@2
  __b2:
    // [186] phi from main::@2 to main::@32 [phi:main::@2->main::@32]
    // [186] phi __errno#112 = __errno#289 [phi:main::@2->main::@32#0] -- register_copy 
    // [186] phi main::rom_chip3#10 = 7 [phi:main::@2->main::@32#1] -- vbum1=vbuc1 
    lda #7
    sta rom_chip3
  // Flash the ROM chips. 
  // We loop first all the ROM chips and read the file contents.
  // Then we verify the file contents and flash the ROM only for the differences.
  // If the file contents are the same as the ROM contents, then no flashing is required.
    // main::@32
  __b32:
    // for(unsigned char rom_chip = 7; rom_chip != 255; rom_chip--)
    // [187] if(main::rom_chip3#10!=$ff) goto main::check_rom1 -- vbum1_neq_vbuc1_then_la1 
    lda #$ff
    cmp rom_chip3
    beq !check_rom1+
    jmp check_rom1
  !check_rom1:
    // main::bank_set_brom4
    // BROM = bank
    // [188] BROM = main::bank_set_brom4_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom4_bank
    sta.z BROM
    // main::CLI5
    // asm
    // asm { cli  }
    cli
    // [190] phi from main::CLI5 to main::@57 [phi:main::CLI5->main::@57]
    // main::@57
    // info_progress("Update finished ...")
    // [191] call info_progress
    // [589] phi from main::@57 to info_progress [phi:main::@57->info_progress]
    // [589] phi info_progress::info_text#12 = main::info_text22 [phi:main::@57->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text22
    sta.z info_progress.info_text
    lda #>info_text22
    sta.z info_progress.info_text+1
    jsr info_progress
    // main::check_smc5
    // status_smc == status
    // [192] main::check_smc5_$0 = status_smc#0 == STATUS_ERROR -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_smc5_main__0
    // return (unsigned char)(status_smc == status);
    // [193] main::check_smc5_return#0 = (char)main::check_smc5_$0
    // main::check_vera1
    // status_vera == status
    // [194] main::check_vera1_$0 = status_vera#0 == STATUS_ERROR -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta check_vera1_main__0
    // return (unsigned char)(status_vera == status);
    // [195] main::check_vera1_return#0 = (char)main::check_vera1_$0
    // [196] phi from main::check_vera1 to main::check_roms1 [phi:main::check_vera1->main::check_roms1]
    // main::check_roms1
    // [197] phi from main::check_roms1 to main::check_roms1_@1 [phi:main::check_roms1->main::check_roms1_@1]
    // [197] phi main::check_roms1_rom_chip#2 = 0 [phi:main::check_roms1->main::check_roms1_@1#0] -- vbum1=vbuc1 
    lda #0
    sta check_roms1_rom_chip
    // main::check_roms1_@1
  check_roms1___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [198] if(main::check_roms1_rom_chip#2<8) goto main::check_roms1_check_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda check_roms1_rom_chip
    cmp #8
    bcs !check_roms1_check_rom1+
    jmp check_roms1_check_rom1
  !check_roms1_check_rom1:
    // [199] phi from main::check_roms1_@1 to main::check_roms1_@return [phi:main::check_roms1_@1->main::check_roms1_@return]
    // [199] phi main::check_roms1_return#2 = STATUS_NONE [phi:main::check_roms1_@1->main::check_roms1_@return#0] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta check_roms1_return
    // main::check_roms1_@return
    // main::@58
  __b58:
    // if(check_smc(STATUS_ERROR) || check_vera(STATUS_ERROR) || check_roms(STATUS_ERROR))
    // [200] if(0!=main::check_smc5_return#0) goto main::vera_display_set_border_color1 -- 0_neq_vbuz1_then_la1 
    lda.z check_smc5_return
    beq !vera_display_set_border_color1+
    jmp vera_display_set_border_color1
  !vera_display_set_border_color1:
    // main::@145
    // [201] if(0!=main::check_vera1_return#0) goto main::vera_display_set_border_color1 -- 0_neq_vbum1_then_la1 
    lda check_vera1_return
    beq !vera_display_set_border_color1+
    jmp vera_display_set_border_color1
  !vera_display_set_border_color1:
    // main::@144
    // [202] if(0!=main::check_roms1_return#2) goto main::vera_display_set_border_color1 -- 0_neq_vbum1_then_la1 
    lda check_roms1_return
    beq !vera_display_set_border_color1+
    jmp vera_display_set_border_color1
  !vera_display_set_border_color1:
    // main::check_smc6
    // status_smc == status
    // [203] main::check_smc6_$0 = status_smc#0 == STATUS_ISSUE -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_smc6_main__0
    // return (unsigned char)(status_smc == status);
    // [204] main::check_smc6_return#0 = (char)main::check_smc6_$0
    // main::check_vera2
    // status_vera == status
    // [205] main::check_vera2_$0 = status_vera#0 == STATUS_ISSUE -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta check_vera2_main__0
    // return (unsigned char)(status_vera == status);
    // [206] main::check_vera2_return#0 = (char)main::check_vera2_$0
    // [207] phi from main::check_vera2 to main::check_roms2 [phi:main::check_vera2->main::check_roms2]
    // main::check_roms2
    // [208] phi from main::check_roms2 to main::check_roms2_@1 [phi:main::check_roms2->main::check_roms2_@1]
    // [208] phi main::check_roms2_rom_chip#2 = 0 [phi:main::check_roms2->main::check_roms2_@1#0] -- vbum1=vbuc1 
    lda #0
    sta check_roms2_rom_chip
    // main::check_roms2_@1
  check_roms2___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [209] if(main::check_roms2_rom_chip#2<8) goto main::check_roms2_check_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda check_roms2_rom_chip
    cmp #8
    bcs !check_roms2_check_rom1+
    jmp check_roms2_check_rom1
  !check_roms2_check_rom1:
    // [210] phi from main::check_roms2_@1 to main::check_roms2_@return [phi:main::check_roms2_@1->main::check_roms2_@return]
    // [210] phi main::check_roms2_return#2 = STATUS_NONE [phi:main::check_roms2_@1->main::check_roms2_@return#0] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta check_roms2_return
    // main::check_roms2_@return
    // main::@61
  __b61:
    // if(check_smc(STATUS_ISSUE) || check_vera(STATUS_ISSUE) || check_roms(STATUS_ISSUE))
    // [211] if(0!=main::check_smc6_return#0) goto main::vera_display_set_border_color2 -- 0_neq_vbuz1_then_la1 
    lda.z check_smc6_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::@147
    // [212] if(0!=main::check_vera2_return#0) goto main::vera_display_set_border_color2 -- 0_neq_vbum1_then_la1 
    lda check_vera2_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::@146
    // [213] if(0!=main::check_roms2_return#2) goto main::vera_display_set_border_color2 -- 0_neq_vbum1_then_la1 
    lda check_roms2_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::vera_display_set_border_color3
    // *VERA_CTRL &= ~VERA_DCSEL
    // [214] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [215] *VERA_DC_BORDER = GREEN -- _deref_pbuc1=vbuc2 
    lda #GREEN
    sta VERA_DC_BORDER
    // [216] phi from main::vera_display_set_border_color3 to main::@63 [phi:main::vera_display_set_border_color3->main::@63]
    // main::@63
    // info_progress("Upgrade Success!")
    // [217] call info_progress
    // [589] phi from main::@63 to info_progress [phi:main::@63->info_progress]
    // [589] phi info_progress::info_text#12 = main::info_text31 [phi:main::@63->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text31
    sta.z info_progress.info_text
    lda #>info_text31
    sta.z info_progress.info_text+1
    jsr info_progress
    // [218] phi from main::@63 to main::@135 [phi:main::@63->main::@135]
    // main::@135
    // wait_key("Press any key to reset your CX16 ...", NULL)
    // [219] call wait_key
    // [989] phi from main::@135 to wait_key [phi:main::@135->wait_key]
    // [989] phi wait_key::filter#14 = 0 [phi:main::@135->wait_key#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z wait_key.filter
    sta.z wait_key.filter+1
    // [989] phi wait_key::info_text#4 = main::info_text32 [phi:main::@135->wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text32
    sta.z wait_key.info_text
    lda #>info_text32
    sta.z wait_key.info_text+1
    jsr wait_key
    // [220] phi from main::@134 main::@135 to main::@40 [phi:main::@134/main::@135->main::@40]
  __b5:
    // [220] phi main::flash_reset#10 = 0 [phi:main::@134/main::@135->main::@40#0] -- vbum1=vbuc1 
    lda #0
    sta flash_reset
    // main::@40
  __b40:
    // for(unsigned char flash_reset=0; flash_reset<120; flash_reset++)
    // [221] if(main::flash_reset#10<$78) goto main::@42 -- vbum1_lt_vbuc1_then_la1 
    lda flash_reset
    cmp #$78
    bcc __b7
    // [222] phi from main::@40 to main::@41 [phi:main::@40->main::@41]
    // main::@41
    // system_reset()
    // [223] call system_reset
    // [1013] phi from main::@41 to system_reset [phi:main::@41->system_reset]
    jsr system_reset
    // main::@return
    // }
    // [224] return 
    rts
    // [225] phi from main::@40 to main::@42 [phi:main::@40->main::@42]
  __b7:
    // [225] phi main::reset_wait#2 = 0 [phi:main::@40->main::@42#0] -- vwum1=vwuc1 
    lda #<0
    sta reset_wait
    sta reset_wait+1
    // main::@42
  __b42:
    // for(unsigned int reset_wait=0; reset_wait<0xFFFF; reset_wait++)
    // [226] if(main::reset_wait#2<$ffff) goto main::@43 -- vwum1_lt_vwuc1_then_la1 
    lda reset_wait+1
    cmp #>$ffff
    bcc __b43
    bne !+
    lda reset_wait
    cmp #<$ffff
    bcc __b43
  !:
    // [227] phi from main::@42 to main::@44 [phi:main::@42->main::@44]
    // main::@44
    // sprintf(info_text, "Resetting your CX16 ... (%u)", flash_reset)
    // [228] call snprintf_init
    jsr snprintf_init
    // [229] phi from main::@44 to main::@136 [phi:main::@44->main::@136]
    // main::@136
    // sprintf(info_text, "Resetting your CX16 ... (%u)", flash_reset)
    // [230] call printf_str
    // [623] phi from main::@136 to printf_str [phi:main::@136->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:main::@136->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = main::s14 [phi:main::@136->printf_str#1] -- pbuz1=pbuc1 
    lda #<s14
    sta.z printf_str.s
    lda #>s14
    sta.z printf_str.s+1
    jsr printf_str
    // main::@137
    // sprintf(info_text, "Resetting your CX16 ... (%u)", flash_reset)
    // [231] printf_uchar::uvalue#8 = main::flash_reset#10 -- vbuz1=vbum2 
    lda flash_reset
    sta.z printf_uchar.uvalue
    // [232] call printf_uchar
    // [1018] phi from main::@137 to printf_uchar [phi:main::@137->printf_uchar]
    // [1018] phi printf_uchar::format_zero_padding#10 = 0 [phi:main::@137->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1018] phi printf_uchar::format_min_length#10 = 0 [phi:main::@137->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1018] phi printf_uchar::putc#10 = &snputc [phi:main::@137->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1018] phi printf_uchar::format_radix#10 = DECIMAL [phi:main::@137->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1018] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#8 [phi:main::@137->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [233] phi from main::@137 to main::@138 [phi:main::@137->main::@138]
    // main::@138
    // sprintf(info_text, "Resetting your CX16 ... (%u)", flash_reset)
    // [234] call printf_str
    // [623] phi from main::@138 to printf_str [phi:main::@138->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:main::@138->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = main::s15 [phi:main::@138->printf_str#1] -- pbuz1=pbuc1 
    lda #<s15
    sta.z printf_str.s
    lda #>s15
    sta.z printf_str.s+1
    jsr printf_str
    // main::@139
    // sprintf(info_text, "Resetting your CX16 ... (%u)", flash_reset)
    // [235] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [236] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [238] call info_line
    // [811] phi from main::@139 to info_line [phi:main::@139->info_line]
    // [811] phi info_line::info_text#17 = info_text [phi:main::@139->info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_line.info_text
    lda #>@info_text
    sta.z info_line.info_text+1
    jsr info_line
    // main::@140
    // for(unsigned char flash_reset=0; flash_reset<120; flash_reset++)
    // [239] main::flash_reset#1 = ++ main::flash_reset#10 -- vbum1=_inc_vbum1 
    inc flash_reset
    // [220] phi from main::@140 to main::@40 [phi:main::@140->main::@40]
    // [220] phi main::flash_reset#10 = main::flash_reset#1 [phi:main::@140->main::@40#0] -- register_copy 
    jmp __b40
    // main::@43
  __b43:
    // for(unsigned int reset_wait=0; reset_wait<0xFFFF; reset_wait++)
    // [240] main::reset_wait#1 = ++ main::reset_wait#2 -- vwum1=_inc_vwum1 
    inc reset_wait
    bne !+
    inc reset_wait+1
  !:
    // [225] phi from main::@43 to main::@42 [phi:main::@43->main::@42]
    // [225] phi main::reset_wait#2 = main::reset_wait#1 [phi:main::@43->main::@42#0] -- register_copy 
    jmp __b42
    // main::vera_display_set_border_color2
  vera_display_set_border_color2:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [241] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [242] *VERA_DC_BORDER = YELLOW -- _deref_pbuc1=vbuc2 
    lda #YELLOW
    sta VERA_DC_BORDER
    // [243] phi from main::vera_display_set_border_color2 to main::@62 [phi:main::vera_display_set_border_color2->main::@62]
    // main::@62
    // info_progress("Upgrade Issues ...")
    // [244] call info_progress
    // [589] phi from main::@62 to info_progress [phi:main::@62->info_progress]
    // [589] phi info_progress::info_text#12 = main::info_text29 [phi:main::@62->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text29
    sta.z info_progress.info_text
    lda #>info_text29
    sta.z info_progress.info_text+1
    jsr info_progress
    // [245] phi from main::@62 to main::@134 [phi:main::@62->main::@134]
    // main::@134
    // wait_key("Take a foto of this screen. Press a key for next steps ...", NULL)
    // [246] call wait_key
    // [989] phi from main::@134 to wait_key [phi:main::@134->wait_key]
    // [989] phi wait_key::filter#14 = 0 [phi:main::@134->wait_key#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z wait_key.filter
    sta.z wait_key.filter+1
    // [989] phi wait_key::info_text#4 = main::info_text30 [phi:main::@134->wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text30
    sta.z wait_key.info_text
    lda #>info_text30
    sta.z wait_key.info_text+1
    jsr wait_key
    jmp __b5
    // main::check_roms2_check_rom1
  check_roms2_check_rom1:
    // status_rom[rom_chip] == status
    // [247] main::check_roms2_check_rom1_$0 = status_rom[main::check_roms2_rom_chip#2] == STATUS_ISSUE -- vbom1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_ISSUE
    ldy check_roms2_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta check_roms2_check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [248] main::check_roms2_check_rom1_return#0 = (char)main::check_roms2_check_rom1_$0
    // main::check_roms2_@11
    // if(check_rom(rom_chip, status) == status)
    // [249] if(main::check_roms2_check_rom1_return#0!=STATUS_ISSUE) goto main::check_roms2_@4 -- vbum1_neq_vbuc1_then_la1 
    lda #STATUS_ISSUE
    cmp check_roms2_check_rom1_return
    bne check_roms2___b4
    // [210] phi from main::check_roms2_@11 to main::check_roms2_@return [phi:main::check_roms2_@11->main::check_roms2_@return]
    // [210] phi main::check_roms2_return#2 = STATUS_ISSUE [phi:main::check_roms2_@11->main::check_roms2_@return#0] -- vbum1=vbuc1 
    sta check_roms2_return
    jmp __b61
    // main::check_roms2_@4
  check_roms2___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [250] main::check_roms2_rom_chip#1 = ++ main::check_roms2_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_roms2_rom_chip
    // [208] phi from main::check_roms2_@4 to main::check_roms2_@1 [phi:main::check_roms2_@4->main::check_roms2_@1]
    // [208] phi main::check_roms2_rom_chip#2 = main::check_roms2_rom_chip#1 [phi:main::check_roms2_@4->main::check_roms2_@1#0] -- register_copy 
    jmp check_roms2___b1
    // main::vera_display_set_border_color1
  vera_display_set_border_color1:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [251] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [252] *VERA_DC_BORDER = RED -- _deref_pbuc1=vbuc2 
    lda #RED
    sta VERA_DC_BORDER
    // [253] phi from main::vera_display_set_border_color1 to main::@60 [phi:main::vera_display_set_border_color1->main::@60]
    // main::@60
    // info_progress("Upgrade Failure! Your CX16 may be bricked!")
    // [254] call info_progress
    // [589] phi from main::@60 to info_progress [phi:main::@60->info_progress]
    // [589] phi info_progress::info_text#12 = main::info_text27 [phi:main::@60->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text27
    sta.z info_progress.info_text
    lda #>info_text27
    sta.z info_progress.info_text+1
    jsr info_progress
    // [255] phi from main::@60 to main::@133 [phi:main::@60->main::@133]
    // main::@133
    // info_line("Take a foto of this screen. And shut down power ...")
    // [256] call info_line
    // [811] phi from main::@133 to info_line [phi:main::@133->info_line]
    // [811] phi info_line::info_text#17 = main::info_text28 [phi:main::@133->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text28
    sta.z info_line.info_text
    lda #>info_text28
    sta.z info_line.info_text+1
    jsr info_line
    // [257] phi from main::@133 main::@39 to main::@39 [phi:main::@133/main::@39->main::@39]
    // main::@39
  __b39:
    jmp __b39
    // main::check_roms1_check_rom1
  check_roms1_check_rom1:
    // status_rom[rom_chip] == status
    // [258] main::check_roms1_check_rom1_$0 = status_rom[main::check_roms1_rom_chip#2] == STATUS_ERROR -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_ERROR
    ldy check_roms1_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_roms1_check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [259] main::check_roms1_check_rom1_return#0 = (char)main::check_roms1_check_rom1_$0
    // main::check_roms1_@11
    // if(check_rom(rom_chip, status) == status)
    // [260] if(main::check_roms1_check_rom1_return#0!=STATUS_ERROR) goto main::check_roms1_@4 -- vbuz1_neq_vbuc1_then_la1 
    lda #STATUS_ERROR
    cmp.z check_roms1_check_rom1_return
    bne check_roms1___b4
    // [199] phi from main::check_roms1_@11 to main::check_roms1_@return [phi:main::check_roms1_@11->main::check_roms1_@return]
    // [199] phi main::check_roms1_return#2 = STATUS_ERROR [phi:main::check_roms1_@11->main::check_roms1_@return#0] -- vbum1=vbuc1 
    sta check_roms1_return
    jmp __b58
    // main::check_roms1_@4
  check_roms1___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [261] main::check_roms1_rom_chip#1 = ++ main::check_roms1_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_roms1_rom_chip
    // [197] phi from main::check_roms1_@4 to main::check_roms1_@1 [phi:main::check_roms1_@4->main::check_roms1_@1]
    // [197] phi main::check_roms1_rom_chip#2 = main::check_roms1_rom_chip#1 [phi:main::check_roms1_@4->main::check_roms1_@1#0] -- register_copy 
    jmp check_roms1___b1
    // main::check_rom1
  check_rom1:
    // status_rom[rom_chip] == status
    // [262] main::check_rom1_$0 = status_rom[main::rom_chip3#10] == STATUS_FLASH -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_FLASH
    ldy rom_chip3
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [263] main::check_rom1_return#0 = (char)main::check_rom1_$0
    // main::@56
    // if(check_rom(rom_chip, STATUS_FLASH))
    // [264] if(0==main::check_rom1_return#0) goto main::@33 -- 0_eq_vbuz1_then_la1 
    lda.z check_rom1_return
    bne !__b33+
    jmp __b33
  !__b33:
    // main::bank_set_brom5
    // BROM = bank
    // [265] BROM = main::bank_set_brom5_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom5_bank
    sta.z BROM
    // [266] phi from main::bank_set_brom5 to main::@59 [phi:main::bank_set_brom5->main::@59]
    // main::@59
    // progress_clear()
    // [267] call progress_clear
    // [564] phi from main::@59 to progress_clear [phi:main::@59->progress_clear]
    jsr progress_clear
    // main::@114
    // unsigned char rom_bank = rom_chip * 32
    // [268] main::rom_bank1#0 = main::rom_chip3#10 << 5 -- vbum1=vbum2_rol_5 
    lda rom_chip3
    asl
    asl
    asl
    asl
    asl
    sta rom_bank1
    // unsigned char* file = rom_file(rom_chip)
    // [269] rom_file::rom_chip#1 = main::rom_chip3#10 -- vbum1=vbum2 
    lda rom_chip3
    sta rom_file.rom_chip
    // [270] call rom_file
    // [1029] phi from main::@114 to rom_file [phi:main::@114->rom_file]
    // [1029] phi rom_file::rom_chip#2 = rom_file::rom_chip#1 [phi:main::@114->rom_file#0] -- register_copy 
    jsr rom_file
    // [271] phi from main::@114 to main::@115 [phi:main::@114->main::@115]
    // main::@115
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [272] call snprintf_init
    jsr snprintf_init
    // [273] phi from main::@115 to main::@116 [phi:main::@115->main::@116]
    // main::@116
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [274] call printf_str
    // [623] phi from main::@116 to printf_str [phi:main::@116->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:main::@116->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = s10 [phi:main::@116->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // [275] phi from main::@116 to main::@117 [phi:main::@116->main::@117]
    // main::@117
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [276] call printf_string
    // [1034] phi from main::@117 to printf_string [phi:main::@117->printf_string]
    // [1034] phi printf_string::putc#16 = &snputc [phi:main::@117->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1034] phi printf_string::str#16 = rom_file::file [phi:main::@117->printf_string#1] -- pbuz1=pbuc1 
    lda #<rom_file.file
    sta.z printf_string.str
    lda #>rom_file.file
    sta.z printf_string.str+1
    // [1034] phi printf_string::format_justify_left#16 = 0 [phi:main::@117->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1034] phi printf_string::format_min_length#16 = 0 [phi:main::@117->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [277] phi from main::@117 to main::@118 [phi:main::@117->main::@118]
    // main::@118
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [278] call printf_str
    // [623] phi from main::@118 to printf_str [phi:main::@118->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:main::@118->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = main::s5 [phi:main::@118->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // main::@119
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [279] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [280] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_progress(info_text)
    // [282] call info_progress
    // [589] phi from main::@119 to info_progress [phi:main::@119->info_progress]
    // [589] phi info_progress::info_text#12 = info_text [phi:main::@119->info_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_progress.info_text
    lda #>@info_text
    sta.z info_progress.info_text+1
    jsr info_progress
    // main::@120
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, rom_bank, rom_sizes[rom_chip])
    // [283] main::$150 = main::rom_chip3#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip3
    asl
    asl
    sta main__150
    // [284] rom_read::brom_bank_start#2 = main::rom_bank1#0 -- vbuz1=vbum2 
    lda rom_bank1
    sta.z rom_read.brom_bank_start
    // [285] rom_read::rom_size#1 = rom_sizes[main::$150] -- vduz1=pduc1_derefidx_vbum2 
    ldy main__150
    lda rom_sizes,y
    sta.z rom_read.rom_size
    lda rom_sizes+1,y
    sta.z rom_read.rom_size+1
    lda rom_sizes+2,y
    sta.z rom_read.rom_size+2
    lda rom_sizes+3,y
    sta.z rom_read.rom_size+3
    // [286] call rom_read
    // [1059] phi from main::@120 to rom_read [phi:main::@120->rom_read]
    // [1059] phi rom_read::rom_size#12 = rom_read::rom_size#1 [phi:main::@120->rom_read#0] -- register_copy 
    // [1059] phi __errno#104 = __errno#112 [phi:main::@120->rom_read#1] -- register_copy 
    // [1059] phi rom_read::brom_bank_start#21 = rom_read::brom_bank_start#2 [phi:main::@120->rom_read#2] -- register_copy 
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, rom_bank, rom_sizes[rom_chip])
    // [287] rom_read::return#3 = rom_read::return#0
    // main::@121
    // [288] main::rom_bytes_read1#0 = rom_read::return#3
    // if(rom_bytes_read)
    // [289] if(0==main::rom_bytes_read1#0) goto main::@33 -- 0_eq_vdum1_then_la1 
    lda rom_bytes_read1
    ora rom_bytes_read1+1
    ora rom_bytes_read1+2
    ora rom_bytes_read1+3
    bne !__b33+
    jmp __b33
  !__b33:
    // [290] phi from main::@121 to main::@36 [phi:main::@121->main::@36]
    // main::@36
    // info_progress("Comparing ... (.) same, (*) different.")
    // [291] call info_progress
  // Now we compare the RAM with the actual ROM contents.
    // [589] phi from main::@36 to info_progress [phi:main::@36->info_progress]
    // [589] phi info_progress::info_text#12 = main::info_text23 [phi:main::@36->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text23
    sta.z info_progress.info_text
    lda #>info_text23
    sta.z info_progress.info_text+1
    jsr info_progress
    // main::@122
    // info_rom(rom_chip, STATUS_COMPARING, "")
    // [292] info_rom::rom_chip#11 = main::rom_chip3#10 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z info_rom.rom_chip
    // [293] call info_rom
    // [1147] phi from main::@122 to info_rom [phi:main::@122->info_rom]
    // [1147] phi info_rom::info_text#16 = info_text5 [phi:main::@122->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z info_rom.info_text
    lda #>info_text5
    sta.z info_rom.info_text+1
    // [1147] phi info_rom::rom_chip#16 = info_rom::rom_chip#11 [phi:main::@122->info_rom#1] -- register_copy 
    // [1147] phi info_rom::info_status#16 = STATUS_COMPARING [phi:main::@122->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_COMPARING
    sta.z info_rom.info_status
    jsr info_rom
    // main::@123
    // unsigned long rom_differences = rom_verify(
    //                     rom_chip, rom_bank, file_sizes[rom_chip])
    // [294] rom_verify::rom_chip#0 = main::rom_chip3#10 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z rom_verify.rom_chip
    // [295] rom_verify::rom_bank_start#0 = main::rom_bank1#0 -- vbuz1=vbum2 
    lda rom_bank1
    sta.z rom_verify.rom_bank_start
    // [296] rom_verify::file_size#0 = file_sizes[main::$150] -- vduz1=pduc1_derefidx_vbum2 
    ldy main__150
    lda file_sizes,y
    sta.z rom_verify.file_size
    lda file_sizes+1,y
    sta.z rom_verify.file_size+1
    lda file_sizes+2,y
    sta.z rom_verify.file_size+2
    lda file_sizes+3,y
    sta.z rom_verify.file_size+3
    // [297] call rom_verify
    // Verify the ROM...
    jsr rom_verify
    // [298] rom_verify::return#2 = rom_verify::rom_different_bytes#11
    // main::@124
    // [299] main::rom_differences#0 = rom_verify::return#2 -- vduz1=vduz2 
    lda.z rom_verify.return
    sta.z rom_differences
    lda.z rom_verify.return+1
    sta.z rom_differences+1
    lda.z rom_verify.return+2
    sta.z rom_differences+2
    lda.z rom_verify.return+3
    sta.z rom_differences+3
    // if (!rom_differences)
    // [300] if(0==main::rom_differences#0) goto main::@34 -- 0_eq_vduz1_then_la1 
    lda.z rom_differences
    ora.z rom_differences+1
    ora.z rom_differences+2
    ora.z rom_differences+3
    bne !__b34+
    jmp __b34
  !__b34:
    // [301] phi from main::@124 to main::@37 [phi:main::@124->main::@37]
    // main::@37
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [302] call snprintf_init
    jsr snprintf_init
    // main::@125
    // [303] printf_ulong::uvalue#9 = main::rom_differences#0
    // [304] call printf_ulong
    // [1245] phi from main::@125 to printf_ulong [phi:main::@125->printf_ulong]
    // [1245] phi printf_ulong::format_zero_padding#11 = 1 [phi:main::@125->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1245] phi printf_ulong::format_min_length#11 = 5 [phi:main::@125->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1245] phi printf_ulong::putc#11 = &snputc [phi:main::@125->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1245] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:main::@125->printf_ulong#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1245] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#9 [phi:main::@125->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [305] phi from main::@125 to main::@126 [phi:main::@125->main::@126]
    // main::@126
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [306] call printf_str
    // [623] phi from main::@126 to printf_str [phi:main::@126->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:main::@126->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = main::s12 [phi:main::@126->printf_str#1] -- pbuz1=pbuc1 
    lda #<s12
    sta.z printf_str.s
    lda #>s12
    sta.z printf_str.s+1
    jsr printf_str
    // main::@127
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [307] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [308] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom(rom_chip, STATUS_FLASH, info_text)
    // [310] info_rom::rom_chip#13 = main::rom_chip3#10 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z info_rom.rom_chip
    // [311] call info_rom
    // [1147] phi from main::@127 to info_rom [phi:main::@127->info_rom]
    // [1147] phi info_rom::info_text#16 = info_text [phi:main::@127->info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_rom.info_text
    lda #>@info_text
    sta.z info_rom.info_text+1
    // [1147] phi info_rom::rom_chip#16 = info_rom::rom_chip#13 [phi:main::@127->info_rom#1] -- register_copy 
    // [1147] phi info_rom::info_status#16 = STATUS_FLASH [phi:main::@127->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASH
    sta.z info_rom.info_status
    jsr info_rom
    // main::@128
    // unsigned long rom_flash_errors = rom_flash(
    //                         rom_chip, rom_bank, file_sizes[rom_chip])
    // [312] rom_flash::rom_chip#0 = main::rom_chip3#10 -- vbum1=vbum2 
    lda rom_chip3
    sta rom_flash.rom_chip
    // [313] rom_flash::rom_bank_start#0 = main::rom_bank1#0 -- vbuz1=vbum2 
    lda rom_bank1
    sta.z rom_flash.rom_bank_start
    // [314] rom_flash::file_size#0 = file_sizes[main::$150] -- vdum1=pduc1_derefidx_vbum2 
    ldy main__150
    lda file_sizes,y
    sta rom_flash.file_size
    lda file_sizes+1,y
    sta rom_flash.file_size+1
    lda file_sizes+2,y
    sta rom_flash.file_size+2
    lda file_sizes+3,y
    sta rom_flash.file_size+3
    // [315] call rom_flash
    // [1256] phi from main::@128 to rom_flash [phi:main::@128->rom_flash]
    jsr rom_flash
    // unsigned long rom_flash_errors = rom_flash(
    //                         rom_chip, rom_bank, file_sizes[rom_chip])
    // [316] rom_flash::return#2 = rom_flash::flash_errors#10
    // main::@129
    // [317] main::rom_flash_errors#0 = rom_flash::return#2 -- vdum1=vdum2 
    lda rom_flash.return
    sta rom_flash_errors
    lda rom_flash.return+1
    sta rom_flash_errors+1
    lda rom_flash.return+2
    sta rom_flash_errors+2
    lda rom_flash.return+3
    sta rom_flash_errors+3
    // if(rom_flash_errors)
    // [318] if(0!=main::rom_flash_errors#0) goto main::@35 -- 0_neq_vdum1_then_la1 
    lda rom_flash_errors
    ora rom_flash_errors+1
    ora rom_flash_errors+2
    ora rom_flash_errors+3
    bne __b35
    // main::@38
    // info_rom(rom_chip, STATUS_FLASHED, "OK!")
    // [319] info_rom::rom_chip#15 = main::rom_chip3#10 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z info_rom.rom_chip
    // [320] call info_rom
    // [1147] phi from main::@38 to info_rom [phi:main::@38->info_rom]
    // [1147] phi info_rom::info_text#16 = main::info_text10 [phi:main::@38->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text10
    sta.z info_rom.info_text
    lda #>info_text10
    sta.z info_rom.info_text+1
    // [1147] phi info_rom::rom_chip#16 = info_rom::rom_chip#15 [phi:main::@38->info_rom#1] -- register_copy 
    // [1147] phi info_rom::info_status#16 = STATUS_FLASHED [phi:main::@38->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHED
    sta.z info_rom.info_status
    jsr info_rom
    // [321] phi from main::@121 main::@132 main::@34 main::@38 main::@56 to main::@33 [phi:main::@121/main::@132/main::@34/main::@38/main::@56->main::@33]
    // [321] phi __errno#290 = __errno#176 [phi:main::@121/main::@132/main::@34/main::@38/main::@56->main::@33#0] -- register_copy 
    // main::@33
  __b33:
    // for(unsigned char rom_chip = 7; rom_chip != 255; rom_chip--)
    // [322] main::rom_chip3#1 = -- main::rom_chip3#10 -- vbum1=_dec_vbum1 
    dec rom_chip3
    // [186] phi from main::@33 to main::@32 [phi:main::@33->main::@32]
    // [186] phi __errno#112 = __errno#290 [phi:main::@33->main::@32#0] -- register_copy 
    // [186] phi main::rom_chip3#10 = main::rom_chip3#1 [phi:main::@33->main::@32#1] -- register_copy 
    jmp __b32
    // [323] phi from main::@129 to main::@35 [phi:main::@129->main::@35]
    // main::@35
  __b35:
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [324] call snprintf_init
    jsr snprintf_init
    // main::@130
    // [325] printf_ulong::uvalue#10 = main::rom_flash_errors#0 -- vduz1=vdum2 
    lda rom_flash_errors
    sta.z printf_ulong.uvalue
    lda rom_flash_errors+1
    sta.z printf_ulong.uvalue+1
    lda rom_flash_errors+2
    sta.z printf_ulong.uvalue+2
    lda rom_flash_errors+3
    sta.z printf_ulong.uvalue+3
    // [326] call printf_ulong
    // [1245] phi from main::@130 to printf_ulong [phi:main::@130->printf_ulong]
    // [1245] phi printf_ulong::format_zero_padding#11 = 0 [phi:main::@130->printf_ulong#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_ulong.format_zero_padding
    // [1245] phi printf_ulong::format_min_length#11 = 0 [phi:main::@130->printf_ulong#1] -- vbuz1=vbuc1 
    sta.z printf_ulong.format_min_length
    // [1245] phi printf_ulong::putc#11 = &snputc [phi:main::@130->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1245] phi printf_ulong::format_radix#11 = DECIMAL [phi:main::@130->printf_ulong#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_ulong.format_radix
    // [1245] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#10 [phi:main::@130->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [327] phi from main::@130 to main::@131 [phi:main::@130->main::@131]
    // main::@131
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [328] call printf_str
    // [623] phi from main::@131 to printf_str [phi:main::@131->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:main::@131->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = main::s13 [phi:main::@131->printf_str#1] -- pbuz1=pbuc1 
    lda #<s13
    sta.z printf_str.s
    lda #>s13
    sta.z printf_str.s+1
    jsr printf_str
    // main::@132
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [329] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [330] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom(rom_chip, STATUS_ERROR, info_text)
    // [332] info_rom::rom_chip#14 = main::rom_chip3#10 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z info_rom.rom_chip
    // [333] call info_rom
    // [1147] phi from main::@132 to info_rom [phi:main::@132->info_rom]
    // [1147] phi info_rom::info_text#16 = info_text [phi:main::@132->info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_rom.info_text
    lda #>@info_text
    sta.z info_rom.info_text+1
    // [1147] phi info_rom::rom_chip#16 = info_rom::rom_chip#14 [phi:main::@132->info_rom#1] -- register_copy 
    // [1147] phi info_rom::info_status#16 = STATUS_ERROR [phi:main::@132->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z info_rom.info_status
    jsr info_rom
    jmp __b33
    // main::@34
  __b34:
    // info_rom(rom_chip, STATUS_FLASHED, "No update required")
    // [334] info_rom::rom_chip#12 = main::rom_chip3#10 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z info_rom.rom_chip
    // [335] call info_rom
    // [1147] phi from main::@34 to info_rom [phi:main::@34->info_rom]
    // [1147] phi info_rom::info_text#16 = main::info_text25 [phi:main::@34->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text25
    sta.z info_rom.info_text
    lda #>info_text25
    sta.z info_rom.info_text+1
    // [1147] phi info_rom::rom_chip#16 = info_rom::rom_chip#12 [phi:main::@34->info_rom#1] -- register_copy 
    // [1147] phi info_rom::info_status#16 = STATUS_FLASHED [phi:main::@34->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHED
    sta.z info_rom.info_status
    jsr info_rom
    jmp __b33
    // [336] phi from main::@142 main::@143 to main::@6 [phi:main::@142/main::@143->main::@6]
    // main::@6
  __b6:
    // info_progress("Chipsets have been detected and update files validated!")
    // [337] call info_progress
    // [589] phi from main::@6 to info_progress [phi:main::@6->info_progress]
    // [589] phi info_progress::info_text#12 = main::info_text13 [phi:main::@6->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text13
    sta.z info_progress.info_text
    lda #>info_text13
    sta.z info_progress.info_text+1
    jsr info_progress
    // [338] phi from main::@6 to main::@105 [phi:main::@6->main::@105]
    // main::@105
    // unsigned char ch = wait_key("Continue with update? [Y/N]", "nyNY")
    // [339] call wait_key
    // [989] phi from main::@105 to wait_key [phi:main::@105->wait_key]
    // [989] phi wait_key::filter#14 = main::filter1 [phi:main::@105->wait_key#0] -- pbuz1=pbuc1 
    lda #<filter1
    sta.z wait_key.filter
    lda #>filter1
    sta.z wait_key.filter+1
    // [989] phi wait_key::info_text#4 = main::info_text14 [phi:main::@105->wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text14
    sta.z wait_key.info_text
    lda #>info_text14
    sta.z wait_key.info_text+1
    jsr wait_key
    // unsigned char ch = wait_key("Continue with update? [Y/N]", "nyNY")
    // [340] wait_key::return#3 = wait_key::ch#4 -- vbum1=vwum2 
    lda wait_key.ch
    sta wait_key.return
    // main::@106
    // [341] main::ch#0 = wait_key::return#3
    // strchr("nN", ch)
    // [342] strchr::c#1 = main::ch#0
    // [343] call strchr
    // [1371] phi from main::@106 to strchr [phi:main::@106->strchr]
    // [1371] phi strchr::c#4 = strchr::c#1 [phi:main::@106->strchr#0] -- register_copy 
    // [1371] phi strchr::str#2 = (const void *)main::$166 [phi:main::@106->strchr#1] -- pvoz1=pvoc1 
    lda #<main__166
    sta.z strchr.str
    lda #>main__166
    sta.z strchr.str+1
    jsr strchr
    // strchr("nN", ch)
    // [344] strchr::return#4 = strchr::return#2
    // main::@107
    // [345] main::$93 = strchr::return#4
    // if(strchr("nN", ch))
    // [346] if((void *)0==main::$93) goto main::check_smc4 -- pvoc1_eq_pvoz1_then_la1 
    lda.z main__93
    cmp #<0
    bne !+
    lda.z main__93+1
    cmp #>0
    bne !check_smc4+
    jmp check_smc4
  !check_smc4:
  !:
    // main::@7
    // [347] smc_file_size#282 = smc_file_size#165 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // info_smc(STATUS_SKIP, "Cancelled")
    // [348] call info_smc
    // [643] phi from main::@7 to info_smc [phi:main::@7->info_smc]
    // [643] phi info_smc::info_text#11 = main::info_text15 [phi:main::@7->info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text15
    sta.z info_smc.info_text
    lda #>info_text15
    sta.z info_smc.info_text+1
    // [643] phi smc_file_size#12 = smc_file_size#282 [phi:main::@7->info_smc#1] -- register_copy 
    // [643] phi info_smc::info_status#11 = STATUS_SKIP [phi:main::@7->info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta info_smc.info_status
    jsr info_smc
    // [349] phi from main::@7 to main::@108 [phi:main::@7->main::@108]
    // main::@108
    // info_vera(STATUS_SKIP, "Cancelled")
    // [350] call info_vera
    // [669] phi from main::@108 to info_vera [phi:main::@108->info_vera]
    // [669] phi info_vera::info_text#2 = main::info_text15 [phi:main::@108->info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text15
    sta.z info_vera.info_text
    lda #>info_text15
    sta.z info_vera.info_text+1
    // [669] phi info_vera::info_status#2 = STATUS_SKIP [phi:main::@108->info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z info_vera.info_status
    jsr info_vera
    // [351] phi from main::@108 to main::@29 [phi:main::@108->main::@29]
    // [351] phi main::rom_chip2#2 = 1 [phi:main::@108->main::@29#0] -- vbum1=vbuc1 
    lda #1
    sta rom_chip2
    // main::@29
  __b29:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [352] if(main::rom_chip2#2<8) goto main::@30 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip2
    cmp #8
    bcc __b30
    // [353] phi from main::@29 to main::@31 [phi:main::@29->main::@31]
    // main::@31
    // info_line("You have selected not to cancel the update ... ")
    // [354] call info_line
    // [811] phi from main::@31 to info_line [phi:main::@31->info_line]
    // [811] phi info_line::info_text#17 = main::info_text18 [phi:main::@31->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text18
    sta.z info_line.info_text
    lda #>info_text18
    sta.z info_line.info_text+1
    jsr info_line
    jmp check_smc4
    // main::@30
  __b30:
    // info_rom(rom_chip, STATUS_SKIP, "Cancelled")
    // [355] info_rom::rom_chip#10 = main::rom_chip2#2 -- vbuz1=vbum2 
    lda rom_chip2
    sta.z info_rom.rom_chip
    // [356] call info_rom
    // [1147] phi from main::@30 to info_rom [phi:main::@30->info_rom]
    // [1147] phi info_rom::info_text#16 = main::info_text15 [phi:main::@30->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text15
    sta.z info_rom.info_text
    lda #>info_text15
    sta.z info_rom.info_text+1
    // [1147] phi info_rom::rom_chip#16 = info_rom::rom_chip#10 [phi:main::@30->info_rom#1] -- register_copy 
    // [1147] phi info_rom::info_status#16 = STATUS_SKIP [phi:main::@30->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z info_rom.info_status
    jsr info_rom
    // main::@109
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [357] main::rom_chip2#1 = ++ main::rom_chip2#2 -- vbum1=_inc_vbum1 
    inc rom_chip2
    // [351] phi from main::@109 to main::@29 [phi:main::@109->main::@29]
    // [351] phi main::rom_chip2#2 = main::rom_chip2#1 [phi:main::@109->main::@29#0] -- register_copy 
    jmp __b29
    // main::check_card_roms1_check_rom1
  check_card_roms1_check_rom1:
    // status_rom[rom_chip] == status
    // [358] main::check_card_roms1_check_rom1_$0 = status_rom[main::check_card_roms1_rom_chip#2] == STATUS_FLASH -- vbom1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_FLASH
    ldy check_card_roms1_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta check_card_roms1_check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [359] main::check_card_roms1_check_rom1_return#0 = (char)main::check_card_roms1_check_rom1_$0
    // main::check_card_roms1_@11
    // if(check_rom(rom_chip, status))
    // [360] if(0==main::check_card_roms1_check_rom1_return#0) goto main::check_card_roms1_@4 -- 0_eq_vbum1_then_la1 
    lda check_card_roms1_check_rom1_return
    beq check_card_roms1___b4
    // [164] phi from main::check_card_roms1_@11 to main::check_card_roms1_@return [phi:main::check_card_roms1_@11->main::check_card_roms1_@return]
    // [164] phi main::check_card_roms1_return#2 = STATUS_FLASH [phi:main::check_card_roms1_@11->main::check_card_roms1_@return#0] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta check_card_roms1_return
    jmp __b53
    // main::check_card_roms1_@4
  check_card_roms1___b4:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [361] main::check_card_roms1_rom_chip#1 = ++ main::check_card_roms1_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_card_roms1_rom_chip
    // [162] phi from main::check_card_roms1_@4 to main::check_card_roms1_@1 [phi:main::check_card_roms1_@4->main::check_card_roms1_@1]
    // [162] phi main::check_card_roms1_rom_chip#2 = main::check_card_roms1_rom_chip#1 [phi:main::check_card_roms1_@4->main::check_card_roms1_@1#0] -- register_copy 
    jmp check_card_roms1___b1
    // [362] phi from main::@141 main::@52 to main::@28 [phi:main::@141/main::@52->main::@28]
    // main::@28
  __b28:
    // info_progress("There is an issue with either the SMC or the CX16 main ROM!")
    // [363] call info_progress
    // [589] phi from main::@28 to info_progress [phi:main::@28->info_progress]
    // [589] phi info_progress::info_text#12 = main::info_text11 [phi:main::@28->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text11
    sta.z info_progress.info_text
    lda #>info_text11
    sta.z info_progress.info_text+1
    jsr info_progress
    // [364] phi from main::@28 to main::@102 [phi:main::@28->main::@102]
    // main::@102
    // wait_key("Press [SPACE] to continue [ ]", " ")
    // [365] call wait_key
    // [989] phi from main::@102 to wait_key [phi:main::@102->wait_key]
    // [989] phi wait_key::filter#14 = main::filter [phi:main::@102->wait_key#0] -- pbuz1=pbuc1 
    lda #<filter
    sta.z wait_key.filter
    lda #>filter
    sta.z wait_key.filter+1
    // [989] phi wait_key::info_text#4 = main::info_text12 [phi:main::@102->wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text12
    sta.z wait_key.info_text
    lda #>info_text12
    sta.z wait_key.info_text+1
    jsr wait_key
    // main::@103
    // [366] smc_file_size#284 = smc_file_size#165 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // info_smc(STATUS_ISSUE, NULL)
    // [367] call info_smc
    // [643] phi from main::@103 to info_smc [phi:main::@103->info_smc]
    // [643] phi info_smc::info_text#11 = 0 [phi:main::@103->info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z info_smc.info_text
    sta.z info_smc.info_text+1
    // [643] phi smc_file_size#12 = smc_file_size#284 [phi:main::@103->info_smc#1] -- register_copy 
    // [643] phi info_smc::info_status#11 = STATUS_ISSUE [phi:main::@103->info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta info_smc.info_status
    jsr info_smc
    // [368] phi from main::@103 to main::@104 [phi:main::@103->main::@104]
    // main::@104
    // info_cx16_rom(STATUS_ISSUE, NULL)
    // [369] call info_cx16_rom
    // [1380] phi from main::@104 to info_cx16_rom [phi:main::@104->info_cx16_rom]
    jsr info_cx16_rom
    jmp check_smc3
    // main::bank_set_brom2
  bank_set_brom2:
    // BROM = bank
    // [370] BROM = main::bank_set_brom2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom2_bank
    sta.z BROM
    // main::@51
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [371] if(rom_device_ids[main::rom_chip1#10]==$55) goto main::@22 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    ldy rom_chip1
    lda rom_device_ids,y
    cmp #$55
    bne !__b22+
    jmp __b22
  !__b22:
    // main::@25
    // info_rom(rom_chip, STATUS_CHECKING, "")
    // [372] info_rom::rom_chip#6 = main::rom_chip1#10 -- vbuz1=vbum2 
    tya
    sta.z info_rom.rom_chip
    // [373] call info_rom
    // [1147] phi from main::@25 to info_rom [phi:main::@25->info_rom]
    // [1147] phi info_rom::info_text#16 = info_text5 [phi:main::@25->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z info_rom.info_text
    lda #>info_text5
    sta.z info_rom.info_text+1
    // [1147] phi info_rom::rom_chip#16 = info_rom::rom_chip#6 [phi:main::@25->info_rom#1] -- register_copy 
    // [1147] phi info_rom::info_status#16 = STATUS_CHECKING [phi:main::@25->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_CHECKING
    sta.z info_rom.info_status
    jsr info_rom
    // [374] phi from main::@25 to main::@84 [phi:main::@25->main::@84]
    // main::@84
    // progress_clear()
    // [375] call progress_clear
  // Set the info for the ROMs to Checking.
    // [564] phi from main::@84 to progress_clear [phi:main::@84->progress_clear]
    jsr progress_clear
    // main::@85
    // unsigned char rom_bank = rom_chip * 32
    // [376] main::rom_bank#0 = main::rom_chip1#10 << 5 -- vbum1=vbum2_rol_5 
    lda rom_chip1
    asl
    asl
    asl
    asl
    asl
    sta rom_bank
    // unsigned char* file = rom_file(rom_chip)
    // [377] rom_file::rom_chip#0 = main::rom_chip1#10 -- vbum1=vbum2 
    lda rom_chip1
    sta rom_file.rom_chip
    // [378] call rom_file
    // [1029] phi from main::@85 to rom_file [phi:main::@85->rom_file]
    // [1029] phi rom_file::rom_chip#2 = rom_file::rom_chip#0 [phi:main::@85->rom_file#0] -- register_copy 
    jsr rom_file
    // [379] phi from main::@85 to main::@86 [phi:main::@85->main::@86]
    // main::@86
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [380] call snprintf_init
    jsr snprintf_init
    // [381] phi from main::@86 to main::@87 [phi:main::@86->main::@87]
    // main::@87
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [382] call printf_str
    // [623] phi from main::@87 to printf_str [phi:main::@87->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:main::@87->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = main::s4 [phi:main::@87->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // [383] phi from main::@87 to main::@88 [phi:main::@87->main::@88]
    // main::@88
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [384] call printf_string
    // [1034] phi from main::@88 to printf_string [phi:main::@88->printf_string]
    // [1034] phi printf_string::putc#16 = &snputc [phi:main::@88->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1034] phi printf_string::str#16 = rom_file::file [phi:main::@88->printf_string#1] -- pbuz1=pbuc1 
    lda #<rom_file.file
    sta.z printf_string.str
    lda #>rom_file.file
    sta.z printf_string.str+1
    // [1034] phi printf_string::format_justify_left#16 = 0 [phi:main::@88->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1034] phi printf_string::format_min_length#16 = 0 [phi:main::@88->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [385] phi from main::@88 to main::@89 [phi:main::@88->main::@89]
    // main::@89
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [386] call printf_str
    // [623] phi from main::@89 to printf_str [phi:main::@89->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:main::@89->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = main::s5 [phi:main::@89->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // main::@90
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [387] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [388] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_progress(info_text)
    // [390] call info_progress
    // [589] phi from main::@90 to info_progress [phi:main::@90->info_progress]
    // [589] phi info_progress::info_text#12 = info_text [phi:main::@90->info_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_progress.info_text
    lda #>@info_text
    sta.z info_progress.info_text+1
    jsr info_progress
    // main::@91
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, rom_bank, rom_sizes[rom_chip])
    // [391] main::$148 = main::rom_chip1#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip1
    asl
    asl
    sta main__148
    // [392] rom_read::brom_bank_start#1 = main::rom_bank#0 -- vbuz1=vbum2 
    lda rom_bank
    sta.z rom_read.brom_bank_start
    // [393] rom_read::rom_size#0 = rom_sizes[main::$148] -- vduz1=pduc1_derefidx_vbum2 
    ldy main__148
    lda rom_sizes,y
    sta.z rom_read.rom_size
    lda rom_sizes+1,y
    sta.z rom_read.rom_size+1
    lda rom_sizes+2,y
    sta.z rom_read.rom_size+2
    lda rom_sizes+3,y
    sta.z rom_read.rom_size+3
    // [394] call rom_read
    // [1059] phi from main::@91 to rom_read [phi:main::@91->rom_read]
    // [1059] phi rom_read::rom_size#12 = rom_read::rom_size#0 [phi:main::@91->rom_read#0] -- register_copy 
    // [1059] phi __errno#104 = __errno#110 [phi:main::@91->rom_read#1] -- register_copy 
    // [1059] phi rom_read::brom_bank_start#21 = rom_read::brom_bank_start#1 [phi:main::@91->rom_read#2] -- register_copy 
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, rom_bank, rom_sizes[rom_chip])
    // [395] rom_read::return#2 = rom_read::return#0
    // main::@92
    // [396] main::rom_bytes_read#0 = rom_read::return#2 -- vdum1=vdum2 
    lda rom_read.return
    sta rom_bytes_read
    lda rom_read.return+1
    sta rom_bytes_read+1
    lda rom_read.return+2
    sta rom_bytes_read+2
    lda rom_read.return+3
    sta rom_bytes_read+3
    // if (!rom_bytes_read)
    // [397] if(0==main::rom_bytes_read#0) goto main::@23 -- 0_eq_vdum1_then_la1 
    // In case no file was found, set the status to none and skip to the next, else, mention the amount of bytes read.
    lda rom_bytes_read
    ora rom_bytes_read+1
    ora rom_bytes_read+2
    ora rom_bytes_read+3
    bne !__b23+
    jmp __b23
  !__b23:
    // main::@26
    // unsigned long rom_file_modulo = rom_bytes_read % 0x4000
    // [398] main::rom_file_modulo#0 = main::rom_bytes_read#0 & $4000-1 -- vdum1=vdum2_band_vduc1 
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
    // [399] if(0!=main::rom_file_modulo#0) goto main::@24 -- 0_neq_vdum1_then_la1 
    lda rom_file_modulo
    ora rom_file_modulo+1
    ora rom_file_modulo+2
    ora rom_file_modulo+3
    bne __b24
    // main::@27
    // info_rom(rom_chip, STATUS_FLASH, "OK!")
    // [400] info_rom::rom_chip#9 = main::rom_chip1#10 -- vbuz1=vbum2 
    lda rom_chip1
    sta.z info_rom.rom_chip
    // [401] call info_rom
    // [1147] phi from main::@27 to info_rom [phi:main::@27->info_rom]
    // [1147] phi info_rom::info_text#16 = main::info_text10 [phi:main::@27->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text10
    sta.z info_rom.info_text
    lda #>info_text10
    sta.z info_rom.info_text+1
    // [1147] phi info_rom::rom_chip#16 = info_rom::rom_chip#9 [phi:main::@27->info_rom#1] -- register_copy 
    // [1147] phi info_rom::info_status#16 = STATUS_FLASH [phi:main::@27->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASH
    sta.z info_rom.info_status
    jsr info_rom
    // main::@101
    // file_sizes[rom_chip] = rom_bytes_read
    // [402] file_sizes[main::$148] = main::rom_bytes_read#0 -- pduc1_derefidx_vbum1=vdum2 
    ldy main__148
    lda rom_bytes_read
    sta file_sizes,y
    lda rom_bytes_read+1
    sta file_sizes+1,y
    lda rom_bytes_read+2
    sta file_sizes+2,y
    lda rom_bytes_read+3
    sta file_sizes+3,y
    // [403] phi from main::@100 main::@101 main::@51 main::@96 to main::@22 [phi:main::@100/main::@101/main::@51/main::@96->main::@22]
    // [403] phi __errno#247 = __errno#176 [phi:main::@100/main::@101/main::@51/main::@96->main::@22#0] -- register_copy 
    // main::@22
  __b22:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [404] main::rom_chip1#1 = ++ main::rom_chip1#10 -- vbum1=_inc_vbum1 
    inc rom_chip1
    // [145] phi from main::@22 to main::@21 [phi:main::@22->main::@21]
    // [145] phi __errno#110 = __errno#247 [phi:main::@22->main::@21#0] -- register_copy 
    // [145] phi main::rom_chip1#10 = main::rom_chip1#1 [phi:main::@22->main::@21#1] -- register_copy 
    jmp __b21
    // [405] phi from main::@26 to main::@24 [phi:main::@26->main::@24]
    // main::@24
  __b24:
    // sprintf(info_text, "File %s size error!", file)
    // [406] call snprintf_init
    jsr snprintf_init
    // [407] phi from main::@24 to main::@97 [phi:main::@24->main::@97]
    // main::@97
    // sprintf(info_text, "File %s size error!", file)
    // [408] call printf_str
    // [623] phi from main::@97 to printf_str [phi:main::@97->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:main::@97->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = main::s8 [phi:main::@97->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // [409] phi from main::@97 to main::@98 [phi:main::@97->main::@98]
    // main::@98
    // sprintf(info_text, "File %s size error!", file)
    // [410] call printf_string
    // [1034] phi from main::@98 to printf_string [phi:main::@98->printf_string]
    // [1034] phi printf_string::putc#16 = &snputc [phi:main::@98->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1034] phi printf_string::str#16 = rom_file::file [phi:main::@98->printf_string#1] -- pbuz1=pbuc1 
    lda #<rom_file.file
    sta.z printf_string.str
    lda #>rom_file.file
    sta.z printf_string.str+1
    // [1034] phi printf_string::format_justify_left#16 = 0 [phi:main::@98->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1034] phi printf_string::format_min_length#16 = 0 [phi:main::@98->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [411] phi from main::@98 to main::@99 [phi:main::@98->main::@99]
    // main::@99
    // sprintf(info_text, "File %s size error!", file)
    // [412] call printf_str
    // [623] phi from main::@99 to printf_str [phi:main::@99->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:main::@99->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = main::s9 [phi:main::@99->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // main::@100
    // sprintf(info_text, "File %s size error!", file)
    // [413] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [414] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom(rom_chip, STATUS_ERROR, info_text)
    // [416] info_rom::rom_chip#8 = main::rom_chip1#10 -- vbuz1=vbum2 
    lda rom_chip1
    sta.z info_rom.rom_chip
    // [417] call info_rom
    // [1147] phi from main::@100 to info_rom [phi:main::@100->info_rom]
    // [1147] phi info_rom::info_text#16 = info_text [phi:main::@100->info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_rom.info_text
    lda #>@info_text
    sta.z info_rom.info_text+1
    // [1147] phi info_rom::rom_chip#16 = info_rom::rom_chip#8 [phi:main::@100->info_rom#1] -- register_copy 
    // [1147] phi info_rom::info_status#16 = STATUS_ERROR [phi:main::@100->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z info_rom.info_status
    jsr info_rom
    jmp __b22
    // [418] phi from main::@92 to main::@23 [phi:main::@92->main::@23]
    // main::@23
  __b23:
    // sprintf(info_text, "No %s, skipped", file)
    // [419] call snprintf_init
    jsr snprintf_init
    // [420] phi from main::@23 to main::@93 [phi:main::@23->main::@93]
    // main::@93
    // sprintf(info_text, "No %s, skipped", file)
    // [421] call printf_str
    // [623] phi from main::@93 to printf_str [phi:main::@93->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:main::@93->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = main::s6 [phi:main::@93->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // [422] phi from main::@93 to main::@94 [phi:main::@93->main::@94]
    // main::@94
    // sprintf(info_text, "No %s, skipped", file)
    // [423] call printf_string
    // [1034] phi from main::@94 to printf_string [phi:main::@94->printf_string]
    // [1034] phi printf_string::putc#16 = &snputc [phi:main::@94->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1034] phi printf_string::str#16 = rom_file::file [phi:main::@94->printf_string#1] -- pbuz1=pbuc1 
    lda #<rom_file.file
    sta.z printf_string.str
    lda #>rom_file.file
    sta.z printf_string.str+1
    // [1034] phi printf_string::format_justify_left#16 = 0 [phi:main::@94->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1034] phi printf_string::format_min_length#16 = 0 [phi:main::@94->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [424] phi from main::@94 to main::@95 [phi:main::@94->main::@95]
    // main::@95
    // sprintf(info_text, "No %s, skipped", file)
    // [425] call printf_str
    // [623] phi from main::@95 to printf_str [phi:main::@95->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:main::@95->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = main::s7 [phi:main::@95->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@96
    // sprintf(info_text, "No %s, skipped", file)
    // [426] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [427] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom(rom_chip, STATUS_NONE, info_text)
    // [429] info_rom::rom_chip#7 = main::rom_chip1#10 -- vbuz1=vbum2 
    lda rom_chip1
    sta.z info_rom.rom_chip
    // [430] call info_rom
    // [1147] phi from main::@96 to info_rom [phi:main::@96->info_rom]
    // [1147] phi info_rom::info_text#16 = info_text [phi:main::@96->info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_rom.info_text
    lda #>@info_text
    sta.z info_rom.info_text+1
    // [1147] phi info_rom::rom_chip#16 = info_rom::rom_chip#7 [phi:main::@96->info_rom#1] -- register_copy 
    // [1147] phi info_rom::info_status#16 = STATUS_NONE [phi:main::@96->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_NONE
    sta.z info_rom.info_status
    jsr info_rom
    jmp __b22
    // main::@20
  __b20:
    // [431] smc_file_size#288 = smc_file_size#0 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // info_smc(STATUS_ERROR, "SMC.BIN too large!")
    // [432] call info_smc
    // [643] phi from main::@20 to info_smc [phi:main::@20->info_smc]
    // [643] phi info_smc::info_text#11 = main::info_text8 [phi:main::@20->info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z info_smc.info_text
    lda #>info_text8
    sta.z info_smc.info_text+1
    // [643] phi smc_file_size#12 = smc_file_size#288 [phi:main::@20->info_smc#1] -- register_copy 
    // [643] phi info_smc::info_status#11 = STATUS_ERROR [phi:main::@20->info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta info_smc.info_status
    jsr info_smc
    jmp CLI3
    // main::@19
  __b19:
    // [433] smc_file_size#287 = smc_file_size#0 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // info_smc(STATUS_ERROR, "No SMC.BIN!")
    // [434] call info_smc
    // [643] phi from main::@19 to info_smc [phi:main::@19->info_smc]
    // [643] phi info_smc::info_text#11 = main::info_text7 [phi:main::@19->info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z info_smc.info_text
    lda #>info_text7
    sta.z info_smc.info_text+1
    // [643] phi smc_file_size#12 = smc_file_size#287 [phi:main::@19->info_smc#1] -- register_copy 
    // [643] phi info_smc::info_status#11 = STATUS_ERROR [phi:main::@19->info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta info_smc.info_status
    jsr info_smc
    jmp CLI3
    // main::@12
  __b12:
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [435] if(rom_device_ids[main::rom_chip#2]!=$55) goto main::@13 -- pbuc1_derefidx_vbum1_neq_vbuc2_then_la1 
    lda #$55
    ldy rom_chip
    cmp rom_device_ids,y
    bne __b13
    // main::@15
    // info_rom(rom_chip, STATUS_NONE, "")
    // [436] info_rom::rom_chip#5 = main::rom_chip#2 -- vbuz1=vbum2 
    tya
    sta.z info_rom.rom_chip
    // [437] call info_rom
    // [1147] phi from main::@15 to info_rom [phi:main::@15->info_rom]
    // [1147] phi info_rom::info_text#16 = info_text5 [phi:main::@15->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z info_rom.info_text
    lda #>info_text5
    sta.z info_rom.info_text+1
    // [1147] phi info_rom::rom_chip#16 = info_rom::rom_chip#5 [phi:main::@15->info_rom#1] -- register_copy 
    // [1147] phi info_rom::info_status#16 = STATUS_NONE [phi:main::@15->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_NONE
    sta.z info_rom.info_status
    jsr info_rom
    // main::@14
  __b14:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [438] main::rom_chip#1 = ++ main::rom_chip#2 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [118] phi from main::@14 to main::@11 [phi:main::@14->main::@11]
    // [118] phi main::rom_chip#2 = main::rom_chip#1 [phi:main::@14->main::@11#0] -- register_copy 
    jmp __b11
    // main::@13
  __b13:
    // info_rom(rom_chip, STATUS_DETECTED, "")
    // [439] info_rom::rom_chip#4 = main::rom_chip#2 -- vbuz1=vbum2 
    lda rom_chip
    sta.z info_rom.rom_chip
    // [440] call info_rom
    // [1147] phi from main::@13 to info_rom [phi:main::@13->info_rom]
    // [1147] phi info_rom::info_text#16 = info_text5 [phi:main::@13->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z info_rom.info_text
    lda #>info_text5
    sta.z info_rom.info_text+1
    // [1147] phi info_rom::rom_chip#16 = info_rom::rom_chip#4 [phi:main::@13->info_rom#1] -- register_copy 
    // [1147] phi info_rom::info_status#16 = STATUS_DETECTED [phi:main::@13->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_DETECTED
    sta.z info_rom.info_status
    jsr info_rom
    jmp __b14
    // [441] phi from main::@4 to main::@10 [phi:main::@4->main::@10]
    // main::@10
  __b10:
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [442] call snprintf_init
    jsr snprintf_init
    // [443] phi from main::@10 to main::@71 [phi:main::@10->main::@71]
    // main::@71
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [444] call printf_str
    // [623] phi from main::@71 to printf_str [phi:main::@71->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:main::@71->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = main::s [phi:main::@71->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // main::@72
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [445] printf_uint::uvalue#13 = smc_bootloader#0 -- vwuz1=vwum2 
    lda smc_bootloader
    sta.z printf_uint.uvalue
    lda smc_bootloader+1
    sta.z printf_uint.uvalue+1
    // [446] call printf_uint
    // [632] phi from main::@72 to printf_uint [phi:main::@72->printf_uint]
    // [632] phi printf_uint::format_zero_padding#16 = 1 [phi:main::@72->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [632] phi printf_uint::format_min_length#16 = 2 [phi:main::@72->printf_uint#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uint.format_min_length
    // [632] phi printf_uint::putc#16 = &snputc [phi:main::@72->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [632] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:main::@72->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [632] phi printf_uint::uvalue#16 = printf_uint::uvalue#13 [phi:main::@72->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [447] phi from main::@72 to main::@73 [phi:main::@72->main::@73]
    // main::@73
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [448] call printf_str
    // [623] phi from main::@73 to printf_str [phi:main::@73->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:main::@73->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = main::s1 [phi:main::@73->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // main::@74
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [449] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [450] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_smc(STATUS_ERROR, info_text)
    // [452] call info_smc
    // [643] phi from main::@74 to info_smc [phi:main::@74->info_smc]
    // [643] phi info_smc::info_text#11 = info_text [phi:main::@74->info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_smc.info_text
    lda #>@info_text
    sta.z info_smc.info_text+1
    // [643] phi smc_file_size#12 = 0 [phi:main::@74->info_smc#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size_2
    sta smc_file_size_2+1
    // [643] phi info_smc::info_status#11 = STATUS_ERROR [phi:main::@74->info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta info_smc.info_status
    jsr info_smc
    jmp CLI1
    // [453] phi from main::@3 to main::@9 [phi:main::@3->main::@9]
    // main::@9
  __b9:
    // info_smc(STATUS_ERROR, "Unreachable!")
    // [454] call info_smc
  // TODO: explain next steps ...
    // [643] phi from main::@9 to info_smc [phi:main::@9->info_smc]
    // [643] phi info_smc::info_text#11 = main::info_text3 [phi:main::@9->info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text3
    sta.z info_smc.info_text
    lda #>info_text3
    sta.z info_smc.info_text+1
    // [643] phi smc_file_size#12 = 0 [phi:main::@9->info_smc#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size_2
    sta smc_file_size_2+1
    // [643] phi info_smc::info_status#11 = STATUS_ERROR [phi:main::@9->info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta info_smc.info_status
    jsr info_smc
    jmp CLI1
    // [455] phi from main::@70 to main::@1 [phi:main::@70->main::@1]
    // main::@1
  __b1:
    // info_smc(STATUS_ERROR, "No Bootloader!")
    // [456] call info_smc
  // TODO: explain next steps ...
    // [643] phi from main::@1 to info_smc [phi:main::@1->info_smc]
    // [643] phi info_smc::info_text#11 = main::info_text2 [phi:main::@1->info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z info_smc.info_text
    lda #>info_text2
    sta.z info_smc.info_text+1
    // [643] phi smc_file_size#12 = 0 [phi:main::@1->info_smc#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size_2
    sta smc_file_size_2+1
    // [643] phi info_smc::info_status#11 = STATUS_ERROR [phi:main::@1->info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta info_smc.info_status
    jsr info_smc
    jmp CLI1
  .segment Data
    info_text: .text "Commander X16 Flash Utility!"
    .byte 0
    info_text1: .text "Detecting SMC, VERA and ROM chipsets ..."
    .byte 0
    info_text2: .text "No Bootloader!"
    .byte 0
    info_text3: .text "Unreachable!"
    .byte 0
    s: .text "Bootloader v"
    .byte 0
    s1: .text " invalid! !"
    .byte 0
    info_text4: .text "VERA installed, OK"
    .byte 0
    info_text7: .text "No SMC.BIN!"
    .byte 0
    info_text8: .text "SMC.BIN too large!"
    .byte 0
    s4: .text "Checking "
    .byte 0
    s5: .text " ... (.) data ( ) empty"
    .byte 0
    s6: .text "No "
    .byte 0
    s7: .text ", skipped"
    .byte 0
    s8: .text "File "
    .byte 0
    s9: .text " size error!"
    .byte 0
    info_text10: .text "OK!"
    .byte 0
    info_text11: .text "There is an issue with either the SMC or the CX16 main ROM!"
    .byte 0
    info_text12: .text "Press [SPACE] to continue [ ]"
    .byte 0
    filter: .text " "
    .byte 0
    info_text13: .text "Chipsets have been detected and update files validated!"
    .byte 0
    info_text14: .text "Continue with update? [Y/N]"
    .byte 0
    filter1: .text "nyNY"
    .byte 0
    main__166: .text "nN"
    .byte 0
    info_text15: .text "Cancelled"
    .byte 0
    info_text18: .text "You have selected not to cancel the update ... "
    .byte 0
    info_text19: .text "Press both POWER/RESET buttons on the CX16 board!"
    .byte 0
    info_text20: .text "Press POWER/RESET!"
    .byte 0
    info_text22: .text "Update finished ..."
    .byte 0
    info_text23: .text "Comparing ... (.) same, (*) different."
    .byte 0
    info_text25: .text "No update required"
    .byte 0
    s12: .text " differences!"
    .byte 0
    s13: .text " flash errors!"
    .byte 0
    info_text27: .text "Upgrade Failure! Your CX16 may be bricked!"
    .byte 0
    info_text28: .text "Take a foto of this screen. And shut down power ..."
    .byte 0
    info_text29: .text "Upgrade Issues ..."
    .byte 0
    info_text30: .text "Take a foto of this screen. Press a key for next steps ..."
    .byte 0
    info_text31: .text "Upgrade Success!"
    .byte 0
    info_text32: .text "Press any key to reset your CX16 ..."
    .byte 0
    s14: .text "Resetting your CX16 ... ("
    .byte 0
    s15: .text ")"
    .byte 0
    main__148: .byte 0
    main__150: .byte 0
    cx16_k_screen_set_charset1_charset: .byte 0
    cx16_k_screen_set_charset1_offset: .word 0
    check_smc3_main__0: .byte 0
    check_cx16_rom2_check_rom1_main__0: .byte 0
    check_card_roms1_check_rom1_main__0: .byte 0
    check_vera1_main__0: .byte 0
    check_vera2_main__0: .byte 0
    check_roms2_check_rom1_main__0: .byte 0
    rom_chip: .byte 0
    rom_chip1: .byte 0
    rom_bank: .byte 0
    rom_bytes_read: .dword 0
    rom_file_modulo: .dword 0
    .label check_smc3_return = check_smc3_main__0
    .label check_cx16_rom2_check_rom1_return = check_cx16_rom2_check_rom1_main__0
    .label check_card_roms1_check_rom1_return = check_card_roms1_check_rom1_main__0
    check_card_roms1_rom_chip: .byte 0
    check_card_roms1_return: .byte 0
    .label ch = strchr.c
    rom_chip2: .byte 0
    .label check_vera1_return = check_vera1_main__0
    check_roms1_rom_chip: .byte 0
    check_roms1_return: .byte 0
    rom_chip3: .byte 0
    rom_bank1: .byte 0
    .label rom_bytes_read1 = rom_read.return
    rom_flash_errors: .dword 0
    .label check_vera2_return = check_vera2_main__0
    .label check_roms2_check_rom1_return = check_roms2_check_rom1_main__0
    check_roms2_rom_chip: .byte 0
    check_roms2_return: .byte 0
    reset_wait: .word 0
    flash_reset: .byte 0
}
.segment Code
  // screenlayer1
// Set the layer with which the conio will interact.
screenlayer1: {
    // screenlayer(1, *VERA_L1_MAPBASE, *VERA_L1_CONFIG)
    // [457] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbuz1=_deref_pbuc1 
    lda VERA_L1_MAPBASE
    sta.z screenlayer.mapbase
    // [458] screenlayer::config#0 = *VERA_L1_CONFIG -- vbuz1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta.z screenlayer.config
    // [459] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [460] return 
    rts
}
  // textcolor
// Set the front color for text output. The old front text color setting is returned.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char textcolor(__zp($d7) char color)
textcolor: {
    .label textcolor__0 = $d9
    .label textcolor__1 = $d7
    .label color = $d7
    // __conio.color & 0xF0
    // [462] textcolor::$0 = *((char *)&__conio+$d) & $f0 -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$d
    sta.z textcolor__0
    // __conio.color & 0xF0 | color
    // [463] textcolor::$1 = textcolor::$0 | textcolor::color#16 -- vbuz1=vbuz2_bor_vbuz1 
    lda.z textcolor__1
    ora.z textcolor__0
    sta.z textcolor__1
    // __conio.color = __conio.color & 0xF0 | color
    // [464] *((char *)&__conio+$d) = textcolor::$1 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // textcolor::@return
    // }
    // [465] return 
    rts
}
  // bgcolor
// Set the back color for text output.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char bgcolor(__zp($d7) char color)
bgcolor: {
    .label bgcolor__0 = $d8
    .label bgcolor__1 = $d7
    .label bgcolor__2 = $d8
    .label color = $d7
    // __conio.color & 0x0F
    // [467] bgcolor::$0 = *((char *)&__conio+$d) & $f -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$d
    sta.z bgcolor__0
    // color << 4
    // [468] bgcolor::$1 = bgcolor::color#14 << 4 -- vbuz1=vbuz1_rol_4 
    lda.z bgcolor__1
    asl
    asl
    asl
    asl
    sta.z bgcolor__1
    // __conio.color & 0x0F | color << 4
    // [469] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbuz1=vbuz1_bor_vbuz2 
    lda.z bgcolor__2
    ora.z bgcolor__1
    sta.z bgcolor__2
    // __conio.color = __conio.color & 0x0F | color << 4
    // [470] *((char *)&__conio+$d) = bgcolor::$2 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // bgcolor::@return
    // }
    // [471] return 
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
    // [472] *((char *)&__conio+$c) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$c
    // cursor::@return
    // }
    // [473] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    // __mem unsigned char x
    // [474] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [475] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [477] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwum1=vbum2_word_vbum3 
    lda x
    sta return+1
    lda y
    sta return
    // cbm_k_plot_get::@return
    // }
    // [478] return 
    rts
  .segment Data
    x: .byte 0
    y: .byte 0
    return: .word 0
}
.segment Code
  // gotoxy
// Set the cursor to the specified position
// void gotoxy(__zp($47) char x, __zp($4f) char y)
gotoxy: {
    .label gotoxy__2 = $47
    .label gotoxy__3 = $47
    .label gotoxy__6 = $46
    .label gotoxy__7 = $46
    .label gotoxy__8 = $5a
    .label gotoxy__9 = $51
    .label gotoxy__10 = $4f
    .label x = $47
    .label y = $4f
    .label gotoxy__14 = $46
    // (x>=__conio.width)?__conio.width:x
    // [480] if(gotoxy::x#29>=*((char *)&__conio+6)) goto gotoxy::@1 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z x
    cmp __conio+6
    bcs __b1
    // [482] phi from gotoxy gotoxy::@1 to gotoxy::@2 [phi:gotoxy/gotoxy::@1->gotoxy::@2]
    // [482] phi gotoxy::$3 = gotoxy::x#29 [phi:gotoxy/gotoxy::@1->gotoxy::@2#0] -- register_copy 
    jmp __b2
    // gotoxy::@1
  __b1:
    // [481] gotoxy::$2 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z gotoxy__2
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [483] *((char *)&__conio) = gotoxy::$3 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__3
    sta __conio
    // (y>=__conio.height)?__conio.height:y
    // [484] if(gotoxy::y#29>=*((char *)&__conio+7)) goto gotoxy::@3 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z y
    cmp __conio+7
    bcs __b3
    // gotoxy::@4
    // [485] gotoxy::$14 = gotoxy::y#29 -- vbuz1=vbuz2 
    sta.z gotoxy__14
    // [486] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [486] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [487] *((char *)&__conio+1) = gotoxy::$7 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__7
    sta __conio+1
    // __conio.cursor_x << 1
    // [488] gotoxy::$8 = *((char *)&__conio) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio
    asl
    sta.z gotoxy__8
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [489] gotoxy::$10 = gotoxy::y#29 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z gotoxy__10
    // [490] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwuz1=pwuc1_derefidx_vbuz2_plus_vbuz3 
    ldy.z gotoxy__10
    clc
    adc __conio+$15,y
    sta.z gotoxy__9
    lda __conio+$15+1,y
    adc #0
    sta.z gotoxy__9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [491] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwuz1 
    lda.z gotoxy__9
    sta __conio+$13
    lda.z gotoxy__9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [492] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [493] gotoxy::$6 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
    lda __conio+7
    sta.z gotoxy__6
    jmp __b5
}
  // cputln
// Print a newline
cputln: {
    .label cputln__2 = $7e
    // __conio.cursor_x = 0
    // [494] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y++;
    // [495] *((char *)&__conio+1) = ++ *((char *)&__conio+1) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+1
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [496] cputln::$2 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z cputln__2
    // [497] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [498] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [499] return 
    rts
}
  // frame_init
frame_init: {
    .const vera_display_set_hstart1_start = $b
    .const vera_display_set_hstop1_stop = $93
    .const vera_display_set_vstart1_start = $13
    .const vera_display_set_vstop1_stop = $db
    // textcolor(WHITE)
    // [501] call textcolor
  // Set the charset to lower case.
  // screenlayer1();
    // [461] phi from frame_init to textcolor [phi:frame_init->textcolor]
    // [461] phi textcolor::color#16 = WHITE [phi:frame_init->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [502] phi from frame_init to frame_init::@2 [phi:frame_init->frame_init::@2]
    // frame_init::@2
    // bgcolor(BLUE)
    // [503] call bgcolor
    // [466] phi from frame_init::@2 to bgcolor [phi:frame_init::@2->bgcolor]
    // [466] phi bgcolor::color#14 = BLUE [phi:frame_init::@2->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [504] phi from frame_init::@2 to frame_init::@3 [phi:frame_init::@2->frame_init::@3]
    // frame_init::@3
    // scroll(0)
    // [505] call scroll
    jsr scroll
    // [506] phi from frame_init::@3 to frame_init::@4 [phi:frame_init::@3->frame_init::@4]
    // frame_init::@4
    // clrscr()
    // [507] call clrscr
    jsr clrscr
    // frame_init::vera_display_set_hstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [508] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTART = start
    // [509] *VERA_DC_HSTART = frame_init::vera_display_set_hstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstart1_start
    sta VERA_DC_HSTART
    // frame_init::vera_display_set_hstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [510] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTOP = stop
    // [511] *VERA_DC_HSTOP = frame_init::vera_display_set_hstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstop1_stop
    sta VERA_DC_HSTOP
    // frame_init::vera_display_set_vstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [512] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTART = start
    // [513] *VERA_DC_VSTART = frame_init::vera_display_set_vstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstart1_start
    sta VERA_DC_VSTART
    // frame_init::vera_display_set_vstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [514] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTOP = stop
    // [515] *VERA_DC_VSTOP = frame_init::vera_display_set_vstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstop1_stop
    sta VERA_DC_VSTOP
    // frame_init::@1
    // cx16_k_screen_set_charset(3, (char *)0)
    // [516] frame_init::cx16_k_screen_set_charset1_charset = 3 -- vbum1=vbuc1 
    lda #3
    sta cx16_k_screen_set_charset1_charset
    // [517] frame_init::cx16_k_screen_set_charset1_offset = (char *) 0 -- pbum1=pbuc1 
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
    // [519] return 
    rts
  .segment Data
    cx16_k_screen_set_charset1_charset: .byte 0
    cx16_k_screen_set_charset1_offset: .word 0
}
.segment Code
  // frame_draw
frame_draw: {
    // textcolor(WHITE)
    // [521] call textcolor
    // [461] phi from frame_draw to textcolor [phi:frame_draw->textcolor]
    // [461] phi textcolor::color#16 = WHITE [phi:frame_draw->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [522] phi from frame_draw to frame_draw::@1 [phi:frame_draw->frame_draw::@1]
    // frame_draw::@1
    // bgcolor(BLUE)
    // [523] call bgcolor
    // [466] phi from frame_draw::@1 to bgcolor [phi:frame_draw::@1->bgcolor]
    // [466] phi bgcolor::color#14 = BLUE [phi:frame_draw::@1->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [524] phi from frame_draw::@1 to frame_draw::@2 [phi:frame_draw::@1->frame_draw::@2]
    // frame_draw::@2
    // clrscr()
    // [525] call clrscr
    jsr clrscr
    // [526] phi from frame_draw::@2 to frame_draw::@3 [phi:frame_draw::@2->frame_draw::@3]
    // frame_draw::@3
    // frame(0, 0, 67, 13)
    // [527] call frame
    // [1454] phi from frame_draw::@3 to frame [phi:frame_draw::@3->frame]
    // [1454] phi frame::y#0 = 0 [phi:frame_draw::@3->frame#0] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.y
    // [1454] phi frame::y1#16 = $d [phi:frame_draw::@3->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1454] phi frame::x#0 = 0 [phi:frame_draw::@3->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1454] phi frame::x1#16 = $43 [phi:frame_draw::@3->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [528] phi from frame_draw::@3 to frame_draw::@4 [phi:frame_draw::@3->frame_draw::@4]
    // frame_draw::@4
    // frame(0, 0, 67, 2)
    // [529] call frame
    // [1454] phi from frame_draw::@4 to frame [phi:frame_draw::@4->frame]
    // [1454] phi frame::y#0 = 0 [phi:frame_draw::@4->frame#0] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.y
    // [1454] phi frame::y1#16 = 2 [phi:frame_draw::@4->frame#1] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y1
    // [1454] phi frame::x#0 = 0 [phi:frame_draw::@4->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1454] phi frame::x1#16 = $43 [phi:frame_draw::@4->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [530] phi from frame_draw::@4 to frame_draw::@5 [phi:frame_draw::@4->frame_draw::@5]
    // frame_draw::@5
    // frame(0, 2, 67, 13)
    // [531] call frame
    // [1454] phi from frame_draw::@5 to frame [phi:frame_draw::@5->frame]
    // [1454] phi frame::y#0 = 2 [phi:frame_draw::@5->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1454] phi frame::y1#16 = $d [phi:frame_draw::@5->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1454] phi frame::x#0 = 0 [phi:frame_draw::@5->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1454] phi frame::x1#16 = $43 [phi:frame_draw::@5->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [532] phi from frame_draw::@5 to frame_draw::@6 [phi:frame_draw::@5->frame_draw::@6]
    // frame_draw::@6
    // frame(0, 2, 8, 13)
    // [533] call frame
    // [1454] phi from frame_draw::@6 to frame [phi:frame_draw::@6->frame]
    // [1454] phi frame::y#0 = 2 [phi:frame_draw::@6->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1454] phi frame::y1#16 = $d [phi:frame_draw::@6->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1454] phi frame::x#0 = 0 [phi:frame_draw::@6->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1454] phi frame::x1#16 = 8 [phi:frame_draw::@6->frame#3] -- vbuz1=vbuc1 
    lda #8
    sta.z frame.x1
    jsr frame
    // [534] phi from frame_draw::@6 to frame_draw::@7 [phi:frame_draw::@6->frame_draw::@7]
    // frame_draw::@7
    // frame(8, 2, 19, 13)
    // [535] call frame
    // [1454] phi from frame_draw::@7 to frame [phi:frame_draw::@7->frame]
    // [1454] phi frame::y#0 = 2 [phi:frame_draw::@7->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1454] phi frame::y1#16 = $d [phi:frame_draw::@7->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1454] phi frame::x#0 = 8 [phi:frame_draw::@7->frame#2] -- vbuz1=vbuc1 
    lda #8
    sta.z frame.x
    // [1454] phi frame::x1#16 = $13 [phi:frame_draw::@7->frame#3] -- vbuz1=vbuc1 
    lda #$13
    sta.z frame.x1
    jsr frame
    // [536] phi from frame_draw::@7 to frame_draw::@8 [phi:frame_draw::@7->frame_draw::@8]
    // frame_draw::@8
    // frame(19, 2, 25, 13)
    // [537] call frame
    // [1454] phi from frame_draw::@8 to frame [phi:frame_draw::@8->frame]
    // [1454] phi frame::y#0 = 2 [phi:frame_draw::@8->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1454] phi frame::y1#16 = $d [phi:frame_draw::@8->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1454] phi frame::x#0 = $13 [phi:frame_draw::@8->frame#2] -- vbuz1=vbuc1 
    lda #$13
    sta.z frame.x
    // [1454] phi frame::x1#16 = $19 [phi:frame_draw::@8->frame#3] -- vbuz1=vbuc1 
    lda #$19
    sta.z frame.x1
    jsr frame
    // [538] phi from frame_draw::@8 to frame_draw::@9 [phi:frame_draw::@8->frame_draw::@9]
    // frame_draw::@9
    // frame(25, 2, 31, 13)
    // [539] call frame
    // [1454] phi from frame_draw::@9 to frame [phi:frame_draw::@9->frame]
    // [1454] phi frame::y#0 = 2 [phi:frame_draw::@9->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1454] phi frame::y1#16 = $d [phi:frame_draw::@9->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1454] phi frame::x#0 = $19 [phi:frame_draw::@9->frame#2] -- vbuz1=vbuc1 
    lda #$19
    sta.z frame.x
    // [1454] phi frame::x1#16 = $1f [phi:frame_draw::@9->frame#3] -- vbuz1=vbuc1 
    lda #$1f
    sta.z frame.x1
    jsr frame
    // [540] phi from frame_draw::@9 to frame_draw::@10 [phi:frame_draw::@9->frame_draw::@10]
    // frame_draw::@10
    // frame(31, 2, 37, 13)
    // [541] call frame
    // [1454] phi from frame_draw::@10 to frame [phi:frame_draw::@10->frame]
    // [1454] phi frame::y#0 = 2 [phi:frame_draw::@10->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1454] phi frame::y1#16 = $d [phi:frame_draw::@10->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1454] phi frame::x#0 = $1f [phi:frame_draw::@10->frame#2] -- vbuz1=vbuc1 
    lda #$1f
    sta.z frame.x
    // [1454] phi frame::x1#16 = $25 [phi:frame_draw::@10->frame#3] -- vbuz1=vbuc1 
    lda #$25
    sta.z frame.x1
    jsr frame
    // [542] phi from frame_draw::@10 to frame_draw::@11 [phi:frame_draw::@10->frame_draw::@11]
    // frame_draw::@11
    // frame(37, 2, 43, 13)
    // [543] call frame
    // [1454] phi from frame_draw::@11 to frame [phi:frame_draw::@11->frame]
    // [1454] phi frame::y#0 = 2 [phi:frame_draw::@11->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1454] phi frame::y1#16 = $d [phi:frame_draw::@11->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1454] phi frame::x#0 = $25 [phi:frame_draw::@11->frame#2] -- vbuz1=vbuc1 
    lda #$25
    sta.z frame.x
    // [1454] phi frame::x1#16 = $2b [phi:frame_draw::@11->frame#3] -- vbuz1=vbuc1 
    lda #$2b
    sta.z frame.x1
    jsr frame
    // [544] phi from frame_draw::@11 to frame_draw::@12 [phi:frame_draw::@11->frame_draw::@12]
    // frame_draw::@12
    // frame(43, 2, 49, 13)
    // [545] call frame
    // [1454] phi from frame_draw::@12 to frame [phi:frame_draw::@12->frame]
    // [1454] phi frame::y#0 = 2 [phi:frame_draw::@12->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1454] phi frame::y1#16 = $d [phi:frame_draw::@12->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1454] phi frame::x#0 = $2b [phi:frame_draw::@12->frame#2] -- vbuz1=vbuc1 
    lda #$2b
    sta.z frame.x
    // [1454] phi frame::x1#16 = $31 [phi:frame_draw::@12->frame#3] -- vbuz1=vbuc1 
    lda #$31
    sta.z frame.x1
    jsr frame
    // [546] phi from frame_draw::@12 to frame_draw::@13 [phi:frame_draw::@12->frame_draw::@13]
    // frame_draw::@13
    // frame(49, 2, 55, 13)
    // [547] call frame
    // [1454] phi from frame_draw::@13 to frame [phi:frame_draw::@13->frame]
    // [1454] phi frame::y#0 = 2 [phi:frame_draw::@13->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1454] phi frame::y1#16 = $d [phi:frame_draw::@13->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1454] phi frame::x#0 = $31 [phi:frame_draw::@13->frame#2] -- vbuz1=vbuc1 
    lda #$31
    sta.z frame.x
    // [1454] phi frame::x1#16 = $37 [phi:frame_draw::@13->frame#3] -- vbuz1=vbuc1 
    lda #$37
    sta.z frame.x1
    jsr frame
    // [548] phi from frame_draw::@13 to frame_draw::@14 [phi:frame_draw::@13->frame_draw::@14]
    // frame_draw::@14
    // frame(55, 2, 61, 13)
    // [549] call frame
    // [1454] phi from frame_draw::@14 to frame [phi:frame_draw::@14->frame]
    // [1454] phi frame::y#0 = 2 [phi:frame_draw::@14->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1454] phi frame::y1#16 = $d [phi:frame_draw::@14->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1454] phi frame::x#0 = $37 [phi:frame_draw::@14->frame#2] -- vbuz1=vbuc1 
    lda #$37
    sta.z frame.x
    // [1454] phi frame::x1#16 = $3d [phi:frame_draw::@14->frame#3] -- vbuz1=vbuc1 
    lda #$3d
    sta.z frame.x1
    jsr frame
    // [550] phi from frame_draw::@14 to frame_draw::@15 [phi:frame_draw::@14->frame_draw::@15]
    // frame_draw::@15
    // frame(61, 2, 67, 13)
    // [551] call frame
    // [1454] phi from frame_draw::@15 to frame [phi:frame_draw::@15->frame]
    // [1454] phi frame::y#0 = 2 [phi:frame_draw::@15->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1454] phi frame::y1#16 = $d [phi:frame_draw::@15->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1454] phi frame::x#0 = $3d [phi:frame_draw::@15->frame#2] -- vbuz1=vbuc1 
    lda #$3d
    sta.z frame.x
    // [1454] phi frame::x1#16 = $43 [phi:frame_draw::@15->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [552] phi from frame_draw::@15 to frame_draw::@16 [phi:frame_draw::@15->frame_draw::@16]
    // frame_draw::@16
    // frame(0, 13, 67, PROGRESS_Y-5)
    // [553] call frame
    // [1454] phi from frame_draw::@16 to frame [phi:frame_draw::@16->frame]
    // [1454] phi frame::y#0 = $d [phi:frame_draw::@16->frame#0] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y
    // [1454] phi frame::y1#16 = PROGRESS_Y-5 [phi:frame_draw::@16->frame#1] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-5
    sta.z frame.y1
    // [1454] phi frame::x#0 = 0 [phi:frame_draw::@16->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1454] phi frame::x1#16 = $43 [phi:frame_draw::@16->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [554] phi from frame_draw::@16 to frame_draw::@17 [phi:frame_draw::@16->frame_draw::@17]
    // frame_draw::@17
    // frame(0, PROGRESS_Y-5, 67, PROGRESS_Y-2)
    // [555] call frame
    // [1454] phi from frame_draw::@17 to frame [phi:frame_draw::@17->frame]
    // [1454] phi frame::y#0 = PROGRESS_Y-5 [phi:frame_draw::@17->frame#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-5
    sta.z frame.y
    // [1454] phi frame::y1#16 = PROGRESS_Y-2 [phi:frame_draw::@17->frame#1] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-2
    sta.z frame.y1
    // [1454] phi frame::x#0 = 0 [phi:frame_draw::@17->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1454] phi frame::x1#16 = $43 [phi:frame_draw::@17->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [556] phi from frame_draw::@17 to frame_draw::@18 [phi:frame_draw::@17->frame_draw::@18]
    // frame_draw::@18
    // frame(0, PROGRESS_Y-2, 67, 49)
    // [557] call frame
    // [1454] phi from frame_draw::@18 to frame [phi:frame_draw::@18->frame]
    // [1454] phi frame::y#0 = PROGRESS_Y-2 [phi:frame_draw::@18->frame#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-2
    sta.z frame.y
    // [1454] phi frame::y1#16 = $31 [phi:frame_draw::@18->frame#1] -- vbuz1=vbuc1 
    lda #$31
    sta.z frame.y1
    // [1454] phi frame::x#0 = 0 [phi:frame_draw::@18->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1454] phi frame::x1#16 = $43 [phi:frame_draw::@18->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // frame_draw::@return
    // }
    // [558] return 
    rts
}
  // info_title
// void info_title(char *info_text)
info_title: {
    // gotoxy(2, 1)
    // [560] call gotoxy
    // [479] phi from info_title to gotoxy [phi:info_title->gotoxy]
    // [479] phi gotoxy::y#29 = 1 [phi:info_title->gotoxy#0] -- vbuz1=vbuc1 
    lda #1
    sta.z gotoxy.y
    // [479] phi gotoxy::x#29 = 2 [phi:info_title->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // [561] phi from info_title to info_title::@1 [phi:info_title->info_title::@1]
    // info_title::@1
    // printf("%-65s", info_text)
    // [562] call printf_string
    // [1034] phi from info_title::@1 to printf_string [phi:info_title::@1->printf_string]
    // [1034] phi printf_string::putc#16 = &cputc [phi:info_title::@1->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1034] phi printf_string::str#16 = main::info_text [phi:info_title::@1->printf_string#1] -- pbuz1=pbuc1 
    lda #<main.info_text
    sta.z printf_string.str
    lda #>main.info_text
    sta.z printf_string.str+1
    // [1034] phi printf_string::format_justify_left#16 = 1 [phi:info_title::@1->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1034] phi printf_string::format_min_length#16 = $41 [phi:info_title::@1->printf_string#3] -- vbuz1=vbuc1 
    lda #$41
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_title::@return
    // }
    // [563] return 
    rts
}
  // progress_clear
/**
 * @brief Clean the progress area for the flashing.
 */
progress_clear: {
    .const h = PROGRESS_Y+PROGRESS_H
    .label x = $dd
    .label i = $de
    .label y = $32
    // textcolor(WHITE)
    // [565] call textcolor
    // [461] phi from progress_clear to textcolor [phi:progress_clear->textcolor]
    // [461] phi textcolor::color#16 = WHITE [phi:progress_clear->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [566] phi from progress_clear to progress_clear::@5 [phi:progress_clear->progress_clear::@5]
    // progress_clear::@5
    // bgcolor(BLUE)
    // [567] call bgcolor
    // [466] phi from progress_clear::@5 to bgcolor [phi:progress_clear::@5->bgcolor]
    // [466] phi bgcolor::color#14 = BLUE [phi:progress_clear::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [568] phi from progress_clear::@5 to progress_clear::@1 [phi:progress_clear::@5->progress_clear::@1]
    // [568] phi progress_clear::y#2 = PROGRESS_Y [phi:progress_clear::@5->progress_clear::@1#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // progress_clear::@1
  __b1:
    // while (y < h)
    // [569] if(progress_clear::y#2<progress_clear::h) goto progress_clear::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y
    cmp #h
    bcc __b4
    // progress_clear::@return
    // }
    // [570] return 
    rts
    // [571] phi from progress_clear::@1 to progress_clear::@2 [phi:progress_clear::@1->progress_clear::@2]
  __b4:
    // [571] phi progress_clear::x#2 = PROGRESS_X [phi:progress_clear::@1->progress_clear::@2#0] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z x
    // [571] phi progress_clear::i#2 = 0 [phi:progress_clear::@1->progress_clear::@2#1] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // progress_clear::@2
  __b2:
    // for(unsigned char i = 0; i < w; i++)
    // [572] if(progress_clear::i#2<PROGRESS_W) goto progress_clear::@3 -- vbuz1_lt_vbuc1_then_la1 
    lda.z i
    cmp #PROGRESS_W
    bcc __b3
    // progress_clear::@4
    // y++;
    // [573] progress_clear::y#1 = ++ progress_clear::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [568] phi from progress_clear::@4 to progress_clear::@1 [phi:progress_clear::@4->progress_clear::@1]
    // [568] phi progress_clear::y#2 = progress_clear::y#1 [phi:progress_clear::@4->progress_clear::@1#0] -- register_copy 
    jmp __b1
    // progress_clear::@3
  __b3:
    // cputcxy(x, y, ' ')
    // [574] cputcxy::x#9 = progress_clear::x#2 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [575] cputcxy::y#9 = progress_clear::y#2 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [576] call cputcxy
    // [1588] phi from progress_clear::@3 to cputcxy [phi:progress_clear::@3->cputcxy]
    // [1588] phi cputcxy::c#13 = ' ' [phi:progress_clear::@3->cputcxy#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z cputcxy.c
    // [1588] phi cputcxy::y#13 = cputcxy::y#9 [phi:progress_clear::@3->cputcxy#1] -- register_copy 
    // [1588] phi cputcxy::x#13 = cputcxy::x#9 [phi:progress_clear::@3->cputcxy#2] -- register_copy 
    jsr cputcxy
    // progress_clear::@6
    // x++;
    // [577] progress_clear::x#1 = ++ progress_clear::x#2 -- vbuz1=_inc_vbuz1 
    inc.z x
    // for(unsigned char i = 0; i < w; i++)
    // [578] progress_clear::i#1 = ++ progress_clear::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [571] phi from progress_clear::@6 to progress_clear::@2 [phi:progress_clear::@6->progress_clear::@2]
    // [571] phi progress_clear::x#2 = progress_clear::x#1 [phi:progress_clear::@6->progress_clear::@2#0] -- register_copy 
    // [571] phi progress_clear::i#2 = progress_clear::i#1 [phi:progress_clear::@6->progress_clear::@2#1] -- register_copy 
    jmp __b2
}
  // info_clear_all
/**
 * @brief Clean the information area.
 * 
 */
info_clear_all: {
    // textcolor(WHITE)
    // [580] call textcolor
    // [461] phi from info_clear_all to textcolor [phi:info_clear_all->textcolor]
    // [461] phi textcolor::color#16 = WHITE [phi:info_clear_all->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [581] phi from info_clear_all to info_clear_all::@3 [phi:info_clear_all->info_clear_all::@3]
    // info_clear_all::@3
    // bgcolor(BLUE)
    // [582] call bgcolor
    // [466] phi from info_clear_all::@3 to bgcolor [phi:info_clear_all::@3->bgcolor]
    // [466] phi bgcolor::color#14 = BLUE [phi:info_clear_all::@3->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [583] phi from info_clear_all::@3 to info_clear_all::@1 [phi:info_clear_all::@3->info_clear_all::@1]
    // [583] phi info_clear_all::l#2 = 0 [phi:info_clear_all::@3->info_clear_all::@1#0] -- vbum1=vbuc1 
    lda #0
    sta l
    // info_clear_all::@1
  __b1:
    // while (l < INFO_H)
    // [584] if(info_clear_all::l#2<$a) goto info_clear_all::@2 -- vbum1_lt_vbuc1_then_la1 
    lda l
    cmp #$a
    bcc __b2
    // info_clear_all::@return
    // }
    // [585] return 
    rts
    // info_clear_all::@2
  __b2:
    // info_clear(l)
    // [586] info_clear::l#0 = info_clear_all::l#2
    // [587] call info_clear
    jsr info_clear
    // info_clear_all::@4
    // l++;
    // [588] info_clear_all::l#1 = ++ info_clear_all::l#2 -- vbum1=_inc_vbum1 
    inc l
    // [583] phi from info_clear_all::@4 to info_clear_all::@1 [phi:info_clear_all::@4->info_clear_all::@1]
    // [583] phi info_clear_all::l#2 = info_clear_all::l#1 [phi:info_clear_all::@4->info_clear_all::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    .label l = main.check_smc3_main__0
}
.segment Code
  // info_progress
// void info_progress(__zp($5f) char *info_text)
info_progress: {
    .label x = $33
    .label y = $24
    .label info_text = $5f
    // unsigned char x = wherex()
    // [590] call wherex
    jsr wherex
    // [591] wherex::return#2 = wherex::return#0
    // info_progress::@1
    // [592] info_progress::x#0 = wherex::return#2
    // unsigned char y = wherey()
    // [593] call wherey
    jsr wherey
    // [594] wherey::return#2 = wherey::return#0
    // info_progress::@2
    // [595] info_progress::y#0 = wherey::return#2
    // gotoxy(2, PROGRESS_Y-4)
    // [596] call gotoxy
    // [479] phi from info_progress::@2 to gotoxy [phi:info_progress::@2->gotoxy]
    // [479] phi gotoxy::y#29 = PROGRESS_Y-4 [phi:info_progress::@2->gotoxy#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-4
    sta.z gotoxy.y
    // [479] phi gotoxy::x#29 = 2 [phi:info_progress::@2->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // info_progress::@3
    // printf("%-65s", info_text)
    // [597] printf_string::str#0 = info_progress::info_text#12
    // [598] call printf_string
    // [1034] phi from info_progress::@3 to printf_string [phi:info_progress::@3->printf_string]
    // [1034] phi printf_string::putc#16 = &cputc [phi:info_progress::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1034] phi printf_string::str#16 = printf_string::str#0 [phi:info_progress::@3->printf_string#1] -- register_copy 
    // [1034] phi printf_string::format_justify_left#16 = 1 [phi:info_progress::@3->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1034] phi printf_string::format_min_length#16 = $41 [phi:info_progress::@3->printf_string#3] -- vbuz1=vbuc1 
    lda #$41
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_progress::@4
    // gotoxy(x, y)
    // [599] gotoxy::x#10 = info_progress::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [600] gotoxy::y#10 = info_progress::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [601] call gotoxy
    // [479] phi from info_progress::@4 to gotoxy [phi:info_progress::@4->gotoxy]
    // [479] phi gotoxy::y#29 = gotoxy::y#10 [phi:info_progress::@4->gotoxy#0] -- register_copy 
    // [479] phi gotoxy::x#29 = gotoxy::x#10 [phi:info_progress::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // info_progress::@return
    // }
    // [602] return 
    rts
}
  // smc_detect
smc_detect: {
    .label smc_detect__1 = $33
    // When the bootloader is not present, 0xFF is returned.
    .label smc_bootloader_version = $2a
    .label return = $2a
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [603] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [604] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [605] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [606] cx16_k_i2c_read_byte::return#10 = cx16_k_i2c_read_byte::return#1
    // smc_detect::@3
    // smc_bootloader_version = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [607] smc_detect::smc_bootloader_version#1 = cx16_k_i2c_read_byte::return#10
    // BYTE1(smc_bootloader_version)
    // [608] smc_detect::$1 = byte1  smc_detect::smc_bootloader_version#1 -- vbuz1=_byte1_vwuz2 
    lda.z smc_bootloader_version+1
    sta.z smc_detect__1
    // if(!BYTE1(smc_bootloader_version))
    // [609] if(0==smc_detect::$1) goto smc_detect::@1 -- 0_eq_vbuz1_then_la1 
    beq __b1
    // [612] phi from smc_detect::@3 to smc_detect::@2 [phi:smc_detect::@3->smc_detect::@2]
    // [612] phi smc_detect::return#0 = $200 [phi:smc_detect::@3->smc_detect::@2#0] -- vwuz1=vwuc1 
    lda #<$200
    sta.z return
    lda #>$200
    sta.z return+1
    rts
    // smc_detect::@1
  __b1:
    // if(smc_bootloader_version == 0xFF)
    // [610] if(smc_detect::smc_bootloader_version#1!=$ff) goto smc_detect::@4 -- vwuz1_neq_vbuc1_then_la1 
    lda.z smc_bootloader_version+1
    bne __b2
    lda.z smc_bootloader_version
    cmp #$ff
    bne __b2
    // [612] phi from smc_detect::@1 to smc_detect::@2 [phi:smc_detect::@1->smc_detect::@2]
    // [612] phi smc_detect::return#0 = $100 [phi:smc_detect::@1->smc_detect::@2#0] -- vwuz1=vwuc1 
    lda #<$100
    sta.z return
    lda #>$100
    sta.z return+1
    rts
    // [611] phi from smc_detect::@1 to smc_detect::@4 [phi:smc_detect::@1->smc_detect::@4]
    // smc_detect::@4
    // [612] phi from smc_detect::@4 to smc_detect::@2 [phi:smc_detect::@4->smc_detect::@2]
    // [612] phi smc_detect::return#0 = smc_detect::smc_bootloader_version#1 [phi:smc_detect::@4->smc_detect::@2#0] -- register_copy 
    // smc_detect::@2
  __b2:
    // smc_detect::@return
    // }
    // [613] return 
    rts
}
  // chip_smc
chip_smc: {
    // print_smc_led(GREY)
    // [615] call print_smc_led
    // [1616] phi from chip_smc to print_smc_led [phi:chip_smc->print_smc_led]
    // [1616] phi print_smc_led::c#2 = GREY [phi:chip_smc->print_smc_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z print_smc_led.c
    jsr print_smc_led
    // [616] phi from chip_smc to chip_smc::@1 [phi:chip_smc->chip_smc::@1]
    // chip_smc::@1
    // print_chip(CHIP_SMC_X, CHIP_SMC_Y+1, CHIP_SMC_W, "smc     ")
    // [617] call print_chip
    // [1620] phi from chip_smc::@1 to print_chip [phi:chip_smc::@1->print_chip]
    // [1620] phi print_chip::text#11 = chip_smc::text [phi:chip_smc::@1->print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z print_chip.text_2
    lda #>text
    sta.z print_chip.text_2+1
    // [1620] phi print_chip::w#10 = 5 [phi:chip_smc::@1->print_chip#1] -- vbuz1=vbuc1 
    lda #5
    sta.z print_chip.w
    // [1620] phi print_chip::x#10 = 1 [phi:chip_smc::@1->print_chip#2] -- vbuz1=vbuc1 
    lda #1
    sta.z print_chip.x
    jsr print_chip
    // chip_smc::@return
    // }
    // [618] return 
    rts
  .segment Data
    text: .text "smc     "
    .byte 0
}
.segment Code
  // snprintf_init
/// Initialize the snprintf() state
// void snprintf_init(char *s, unsigned int n)
snprintf_init: {
    // __snprintf_capacity = n
    // [619] __snprintf_capacity = $ffff -- vwum1=vwuc1 
    lda #<$ffff
    sta __snprintf_capacity
    lda #>$ffff
    sta __snprintf_capacity+1
    // __snprintf_size = 0
    // [620] __snprintf_size = 0 -- vwum1=vbuc1 
    lda #<0
    sta __snprintf_size
    sta __snprintf_size+1
    // __snprintf_buffer = s
    // [621] __snprintf_buffer = info_text -- pbum1=pbuc1 
    lda #<info_text
    sta __snprintf_buffer
    lda #>info_text
    sta __snprintf_buffer+1
    // snprintf_init::@return
    // }
    // [622] return 
    rts
}
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($4a) void (*putc)(char), __zp($5f) const char *s)
printf_str: {
    .label c = $67
    .label s = $5f
    .label putc = $4a
    // [624] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [624] phi printf_str::s#65 = printf_str::s#66 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [625] printf_str::c#1 = *printf_str::s#65 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta.z c
    // [626] printf_str::s#0 = ++ printf_str::s#65 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [627] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // printf_str::@return
    // }
    // [628] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [629] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [630] callexecute *printf_str::putc#66  -- call__deref_pprz1 
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
// void printf_uint(__zp($4a) void (*putc)(char), __zp($2a) unsigned int uvalue, __zp($de) char format_min_length, char format_justify_left, char format_sign_always, __zp($dd) char format_zero_padding, char format_upper_case, __zp($32) char format_radix)
printf_uint: {
    .label uvalue = $2a
    .label format_radix = $32
    .label putc = $4a
    .label format_min_length = $de
    .label format_zero_padding = $dd
    // printf_uint::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [633] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [634] utoa::value#1 = printf_uint::uvalue#16
    // [635] utoa::radix#0 = printf_uint::format_radix#16
    // [636] call utoa
    // Format number into buffer
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [637] printf_number_buffer::putc#1 = printf_uint::putc#16
    // [638] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [639] printf_number_buffer::format_min_length#1 = printf_uint::format_min_length#16
    // [640] printf_number_buffer::format_zero_padding#1 = printf_uint::format_zero_padding#16
    // [641] call printf_number_buffer
  // Print using format
    // [1694] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    // [1694] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#1 [phi:printf_uint::@2->printf_number_buffer#0] -- register_copy 
    // [1694] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_uint::@2->printf_number_buffer#1] -- register_copy 
    // [1694] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#1 [phi:printf_uint::@2->printf_number_buffer#2] -- register_copy 
    // [1694] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#1 [phi:printf_uint::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [642] return 
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
// void info_smc(__mem() char info_status, __zp($6c) char *info_text)
info_smc: {
    .label info_text = $6c
    // status_smc = info_status
    // [644] status_smc#0 = info_smc::info_status#11 -- vbum1=vbum2 
    lda info_status
    sta status_smc
    // print_smc_led(status_color[info_status])
    // [645] print_smc_led::c#1 = status_color[info_smc::info_status#11] -- vbuz1=pbuc1_derefidx_vbum2 
    ldy info_status
    lda status_color,y
    sta.z print_smc_led.c
    // [646] call print_smc_led
    // [1616] phi from info_smc to print_smc_led [phi:info_smc->print_smc_led]
    // [1616] phi print_smc_led::c#2 = print_smc_led::c#1 [phi:info_smc->print_smc_led#0] -- register_copy 
    jsr print_smc_led
    // [647] phi from info_smc to info_smc::@2 [phi:info_smc->info_smc::@2]
    // info_smc::@2
    // gotoxy(INFO_X, INFO_Y)
    // [648] call gotoxy
    // [479] phi from info_smc::@2 to gotoxy [phi:info_smc::@2->gotoxy]
    // [479] phi gotoxy::y#29 = $11 [phi:info_smc::@2->gotoxy#0] -- vbuz1=vbuc1 
    lda #$11
    sta.z gotoxy.y
    // [479] phi gotoxy::x#29 = 2 [phi:info_smc::@2->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // [649] phi from info_smc::@2 to info_smc::@3 [phi:info_smc::@2->info_smc::@3]
    // info_smc::@3
    // printf("SMC  - %-9s - ATTiny - %05x / 01E00 - ", status_text[info_status], smc_file_size)
    // [650] call printf_str
    // [623] phi from info_smc::@3 to printf_str [phi:info_smc::@3->printf_str]
    // [623] phi printf_str::putc#66 = &cputc [phi:info_smc::@3->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = info_smc::s [phi:info_smc::@3->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // info_smc::@4
    // printf("SMC  - %-9s - ATTiny - %05x / 01E00 - ", status_text[info_status], smc_file_size)
    // [651] info_smc::$5 = info_smc::info_status#11 << 1 -- vbum1=vbum1_rol_1 
    asl info_smc__5
    // [652] printf_string::str#3 = status_text[info_smc::$5] -- pbuz1=qbuc1_derefidx_vbum2 
    ldy info_smc__5
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [653] call printf_string
    // [1034] phi from info_smc::@4 to printf_string [phi:info_smc::@4->printf_string]
    // [1034] phi printf_string::putc#16 = &cputc [phi:info_smc::@4->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1034] phi printf_string::str#16 = printf_string::str#3 [phi:info_smc::@4->printf_string#1] -- register_copy 
    // [1034] phi printf_string::format_justify_left#16 = 1 [phi:info_smc::@4->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1034] phi printf_string::format_min_length#16 = 9 [phi:info_smc::@4->printf_string#3] -- vbuz1=vbuc1 
    lda #9
    sta.z printf_string.format_min_length
    jsr printf_string
    // [654] phi from info_smc::@4 to info_smc::@5 [phi:info_smc::@4->info_smc::@5]
    // info_smc::@5
    // printf("SMC  - %-9s - ATTiny - %05x / 01E00 - ", status_text[info_status], smc_file_size)
    // [655] call printf_str
    // [623] phi from info_smc::@5 to printf_str [phi:info_smc::@5->printf_str]
    // [623] phi printf_str::putc#66 = &cputc [phi:info_smc::@5->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = info_smc::s1 [phi:info_smc::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_smc::@6
    // printf("SMC  - %-9s - ATTiny - %05x / 01E00 - ", status_text[info_status], smc_file_size)
    // [656] printf_uint::uvalue#0 = smc_file_size#12 -- vwuz1=vwum2 
    lda smc_file_size_2
    sta.z printf_uint.uvalue
    lda smc_file_size_2+1
    sta.z printf_uint.uvalue+1
    // [657] call printf_uint
    // [632] phi from info_smc::@6 to printf_uint [phi:info_smc::@6->printf_uint]
    // [632] phi printf_uint::format_zero_padding#16 = 1 [phi:info_smc::@6->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [632] phi printf_uint::format_min_length#16 = 5 [phi:info_smc::@6->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [632] phi printf_uint::putc#16 = &cputc [phi:info_smc::@6->printf_uint#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uint.putc
    lda #>cputc
    sta.z printf_uint.putc+1
    // [632] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:info_smc::@6->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [632] phi printf_uint::uvalue#16 = printf_uint::uvalue#0 [phi:info_smc::@6->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [658] phi from info_smc::@6 to info_smc::@7 [phi:info_smc::@6->info_smc::@7]
    // info_smc::@7
    // printf("SMC  - %-9s - ATTiny - %05x / 01E00 - ", status_text[info_status], smc_file_size)
    // [659] call printf_str
    // [623] phi from info_smc::@7 to printf_str [phi:info_smc::@7->printf_str]
    // [623] phi printf_str::putc#66 = &cputc [phi:info_smc::@7->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = info_smc::s2 [phi:info_smc::@7->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // info_smc::@8
    // if(info_text)
    // [660] if((char *)0==info_smc::info_text#11) goto info_smc::@return -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __breturn
  !:
    // info_smc::@1
    // printf("%20s", info_text)
    // [661] printf_string::str#4 = info_smc::info_text#11 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [662] call printf_string
    // [1034] phi from info_smc::@1 to printf_string [phi:info_smc::@1->printf_string]
    // [1034] phi printf_string::putc#16 = &cputc [phi:info_smc::@1->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1034] phi printf_string::str#16 = printf_string::str#4 [phi:info_smc::@1->printf_string#1] -- register_copy 
    // [1034] phi printf_string::format_justify_left#16 = 0 [phi:info_smc::@1->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1034] phi printf_string::format_min_length#16 = $14 [phi:info_smc::@1->printf_string#3] -- vbuz1=vbuc1 
    lda #$14
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_smc::@return
  __breturn:
    // }
    // [663] return 
    rts
  .segment Data
    s: .text "SMC  - "
    .byte 0
    s1: .text " - ATTiny - "
    .byte 0
    s2: .text " / 01E00 - "
    .byte 0
    .label info_smc__5 = main.check_cx16_rom2_check_rom1_main__0
    .label info_status = main.check_cx16_rom2_check_rom1_main__0
}
.segment Code
  // chip_vera
chip_vera: {
    // print_vera_led(GREY)
    // [665] call print_vera_led
    // [1725] phi from chip_vera to print_vera_led [phi:chip_vera->print_vera_led]
    // [1725] phi print_vera_led::c#2 = GREY [phi:chip_vera->print_vera_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z print_vera_led.c
    jsr print_vera_led
    // [666] phi from chip_vera to chip_vera::@1 [phi:chip_vera->chip_vera::@1]
    // chip_vera::@1
    // print_chip(CHIP_VERA_X, CHIP_VERA_Y+1, CHIP_VERA_W, "vera     ")
    // [667] call print_chip
    // [1620] phi from chip_vera::@1 to print_chip [phi:chip_vera::@1->print_chip]
    // [1620] phi print_chip::text#11 = chip_vera::text [phi:chip_vera::@1->print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z print_chip.text_2
    lda #>text
    sta.z print_chip.text_2+1
    // [1620] phi print_chip::w#10 = 8 [phi:chip_vera::@1->print_chip#1] -- vbuz1=vbuc1 
    lda #8
    sta.z print_chip.w
    // [1620] phi print_chip::x#10 = 9 [phi:chip_vera::@1->print_chip#2] -- vbuz1=vbuc1 
    lda #9
    sta.z print_chip.x
    jsr print_chip
    // chip_vera::@return
    // }
    // [668] return 
    rts
  .segment Data
    text: .text "vera     "
    .byte 0
}
.segment Code
  // info_vera
/**
 * @brief Print the VERA status.
 * 
 * @param info_status The STATUS_ 
 */
// void info_vera(__zp($dc) char info_status, __zp($5d) char *info_text)
info_vera: {
    .label info_vera__5 = $dc
    .label info_status = $dc
    .label info_text = $5d
    // status_vera = info_status
    // [670] status_vera#0 = info_vera::info_status#2 -- vbum1=vbuz2 
    lda.z info_status
    sta status_vera
    // print_vera_led(status_color[info_status])
    // [671] print_vera_led::c#1 = status_color[info_vera::info_status#2] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z print_vera_led.c
    // [672] call print_vera_led
    // [1725] phi from info_vera to print_vera_led [phi:info_vera->print_vera_led]
    // [1725] phi print_vera_led::c#2 = print_vera_led::c#1 [phi:info_vera->print_vera_led#0] -- register_copy 
    jsr print_vera_led
    // [673] phi from info_vera to info_vera::@2 [phi:info_vera->info_vera::@2]
    // info_vera::@2
    // gotoxy(INFO_X, INFO_Y+1)
    // [674] call gotoxy
    // [479] phi from info_vera::@2 to gotoxy [phi:info_vera::@2->gotoxy]
    // [479] phi gotoxy::y#29 = $11+1 [phi:info_vera::@2->gotoxy#0] -- vbuz1=vbuc1 
    lda #$11+1
    sta.z gotoxy.y
    // [479] phi gotoxy::x#29 = 2 [phi:info_vera::@2->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // [675] phi from info_vera::@2 to info_vera::@3 [phi:info_vera::@2->info_vera::@3]
    // info_vera::@3
    // printf("VERA - %-9s - FPGA   - 1a000 / 1a000 - ", status_text[info_status])
    // [676] call printf_str
    // [623] phi from info_vera::@3 to printf_str [phi:info_vera::@3->printf_str]
    // [623] phi printf_str::putc#66 = &cputc [phi:info_vera::@3->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = info_vera::s [phi:info_vera::@3->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // info_vera::@4
    // printf("VERA - %-9s - FPGA   - 1a000 / 1a000 - ", status_text[info_status])
    // [677] info_vera::$5 = info_vera::info_status#2 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z info_vera__5
    // [678] printf_string::str#5 = status_text[info_vera::$5] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z info_vera__5
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [679] call printf_string
    // [1034] phi from info_vera::@4 to printf_string [phi:info_vera::@4->printf_string]
    // [1034] phi printf_string::putc#16 = &cputc [phi:info_vera::@4->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1034] phi printf_string::str#16 = printf_string::str#5 [phi:info_vera::@4->printf_string#1] -- register_copy 
    // [1034] phi printf_string::format_justify_left#16 = 1 [phi:info_vera::@4->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1034] phi printf_string::format_min_length#16 = 9 [phi:info_vera::@4->printf_string#3] -- vbuz1=vbuc1 
    lda #9
    sta.z printf_string.format_min_length
    jsr printf_string
    // [680] phi from info_vera::@4 to info_vera::@5 [phi:info_vera::@4->info_vera::@5]
    // info_vera::@5
    // printf("VERA - %-9s - FPGA   - 1a000 / 1a000 - ", status_text[info_status])
    // [681] call printf_str
    // [623] phi from info_vera::@5 to printf_str [phi:info_vera::@5->printf_str]
    // [623] phi printf_str::putc#66 = &cputc [phi:info_vera::@5->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = info_vera::s1 [phi:info_vera::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_vera::@6
    // if(info_text)
    // [682] if((char *)0==info_vera::info_text#2) goto info_vera::@return -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __breturn
  !:
    // info_vera::@1
    // printf("%20s", info_text)
    // [683] printf_string::str#6 = info_vera::info_text#2 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [684] call printf_string
    // [1034] phi from info_vera::@1 to printf_string [phi:info_vera::@1->printf_string]
    // [1034] phi printf_string::putc#16 = &cputc [phi:info_vera::@1->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1034] phi printf_string::str#16 = printf_string::str#6 [phi:info_vera::@1->printf_string#1] -- register_copy 
    // [1034] phi printf_string::format_justify_left#16 = 0 [phi:info_vera::@1->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1034] phi printf_string::format_min_length#16 = $14 [phi:info_vera::@1->printf_string#3] -- vbuz1=vbuc1 
    lda #$14
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_vera::@return
  __breturn:
    // }
    // [685] return 
    rts
  .segment Data
    s: .text "VERA - "
    .byte 0
    s1: .text " - FPGA   - 1a000 / 1a000 - "
    .byte 0
}
.segment Code
  // rom_detect
rom_detect: {
    .const bank_set_brom1_bank = 4
    .label rom_detect__3 = $24
    .label rom_detect__5 = $24
    .label rom_detect__9 = $67
    .label rom_detect__15 = $b5
    .label rom_detect__18 = $e0
    .label rom_detect__21 = $e2
    .label rom_detect_address = $26
    // [687] phi from rom_detect to rom_detect::@1 [phi:rom_detect->rom_detect::@1]
    // [687] phi rom_detect::rom_chip#10 = 0 [phi:rom_detect->rom_detect::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // [687] phi rom_detect::rom_detect_address#10 = 0 [phi:rom_detect->rom_detect::@1#1] -- vduz1=vduc1 
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
    // [688] if(rom_detect::rom_detect_address#10<8*$80000) goto rom_detect::@2 -- vduz1_lt_vduc1_then_la1 
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
    // [689] return 
    rts
    // rom_detect::@2
  __b2:
    // rom_manufacturer_ids[rom_chip] = 0
    // [690] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = 0
    // [691] rom_device_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta rom_device_ids,y
    // rom_unlock(rom_detect_address + 0x05555, 0x90)
    // [692] rom_unlock::address#2 = rom_detect::rom_detect_address#10 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [693] call rom_unlock
    // [1729] phi from rom_detect::@2 to rom_unlock [phi:rom_detect::@2->rom_unlock]
    // [1729] phi rom_unlock::unlock_code#5 = $90 [phi:rom_detect::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$90
    sta.z rom_unlock.unlock_code
    // [1729] phi rom_unlock::address#5 = rom_unlock::address#2 [phi:rom_detect::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_detect::@12
    // rom_read_byte(rom_detect_address)
    // [694] rom_read_byte::address#0 = rom_detect::rom_detect_address#10 -- vduz1=vduz2 
    lda.z rom_detect_address
    sta.z rom_read_byte.address
    lda.z rom_detect_address+1
    sta.z rom_read_byte.address+1
    lda.z rom_detect_address+2
    sta.z rom_read_byte.address+2
    lda.z rom_detect_address+3
    sta.z rom_read_byte.address+3
    // [695] call rom_read_byte
    // [1739] phi from rom_detect::@12 to rom_read_byte [phi:rom_detect::@12->rom_read_byte]
    // [1739] phi rom_read_byte::address#2 = rom_read_byte::address#0 [phi:rom_detect::@12->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(rom_detect_address)
    // [696] rom_read_byte::return#2 = rom_read_byte::return#0
    // rom_detect::@13
    // [697] rom_detect::$3 = rom_read_byte::return#2
    // rom_manufacturer_ids[rom_chip] = rom_read_byte(rom_detect_address)
    // [698] rom_manufacturer_ids[rom_detect::rom_chip#10] = rom_detect::$3 -- pbuc1_derefidx_vbum1=vbuz2 
    lda.z rom_detect__3
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_read_byte(rom_detect_address + 1)
    // [699] rom_read_byte::address#1 = rom_detect::rom_detect_address#10 + 1 -- vduz1=vduz2_plus_1 
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
    // [700] call rom_read_byte
    // [1739] phi from rom_detect::@13 to rom_read_byte [phi:rom_detect::@13->rom_read_byte]
    // [1739] phi rom_read_byte::address#2 = rom_read_byte::address#1 [phi:rom_detect::@13->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(rom_detect_address + 1)
    // [701] rom_read_byte::return#3 = rom_read_byte::return#0
    // rom_detect::@14
    // [702] rom_detect::$5 = rom_read_byte::return#3
    // rom_device_ids[rom_chip] = rom_read_byte(rom_detect_address + 1)
    // [703] rom_device_ids[rom_detect::rom_chip#10] = rom_detect::$5 -- pbuc1_derefidx_vbum1=vbuz2 
    lda.z rom_detect__5
    ldy rom_chip
    sta rom_device_ids,y
    // rom_unlock(rom_detect_address + 0x05555, 0xF0)
    // [704] rom_unlock::address#3 = rom_detect::rom_detect_address#10 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [705] call rom_unlock
    // [1729] phi from rom_detect::@14 to rom_unlock [phi:rom_detect::@14->rom_unlock]
    // [1729] phi rom_unlock::unlock_code#5 = $f0 [phi:rom_detect::@14->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$f0
    sta.z rom_unlock.unlock_code
    // [1729] phi rom_unlock::address#5 = rom_unlock::address#3 [phi:rom_detect::@14->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_detect::bank_set_brom1
    // BROM = bank
    // [706] BROM = rom_detect::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // rom_detect::@11
    // rom_chip*3
    // [707] rom_detect::$14 = rom_detect::rom_chip#10 << 1 -- vbum1=vbum2_rol_1 
    lda rom_chip
    asl
    sta rom_detect__14
    // [708] rom_detect::$9 = rom_detect::$14 + rom_detect::rom_chip#10 -- vbuz1=vbum2_plus_vbum3 
    clc
    adc rom_chip
    sta.z rom_detect__9
    // gotoxy(rom_chip*3+40, 1)
    // [709] gotoxy::x#22 = rom_detect::$9 + $28 -- vbuz1=vbuz2_plus_vbuc1 
    lda #$28
    clc
    adc.z rom_detect__9
    sta.z gotoxy.x
    // [710] call gotoxy
    // [479] phi from rom_detect::@11 to gotoxy [phi:rom_detect::@11->gotoxy]
    // [479] phi gotoxy::y#29 = 1 [phi:rom_detect::@11->gotoxy#0] -- vbuz1=vbuc1 
    lda #1
    sta.z gotoxy.y
    // [479] phi gotoxy::x#29 = gotoxy::x#22 [phi:rom_detect::@11->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_detect::@15
    // printf("%02x", rom_device_ids[rom_chip])
    // [711] printf_uchar::uvalue#4 = rom_device_ids[rom_detect::rom_chip#10] -- vbuz1=pbuc1_derefidx_vbum2 
    ldy rom_chip
    lda rom_device_ids,y
    sta.z printf_uchar.uvalue
    // [712] call printf_uchar
    // [1018] phi from rom_detect::@15 to printf_uchar [phi:rom_detect::@15->printf_uchar]
    // [1018] phi printf_uchar::format_zero_padding#10 = 1 [phi:rom_detect::@15->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1018] phi printf_uchar::format_min_length#10 = 2 [phi:rom_detect::@15->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [1018] phi printf_uchar::putc#10 = &cputc [phi:rom_detect::@15->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1018] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:rom_detect::@15->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [1018] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#4 [phi:rom_detect::@15->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // rom_detect::@16
    // case SST39SF010A:
    //             rom_device_names[rom_chip] = "f010a";
    //             rom_size_strings[rom_chip] = "128";
    //             rom_sizes[rom_chip] = 128 * 1024;
    //             break;
    // [713] if(rom_device_ids[rom_detect::rom_chip#10]==$b5) goto rom_detect::@3 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
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
    // [714] if(rom_device_ids[rom_detect::rom_chip#10]==$b6) goto rom_detect::@4 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
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
    // [715] if(rom_device_ids[rom_detect::rom_chip#10]==$b7) goto rom_detect::@5 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b7
    beq __b5
    // rom_detect::@6
    // rom_manufacturer_ids[rom_chip] = 0
    // [716] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    sta rom_manufacturer_ids,y
    // rom_device_names[rom_chip] = "----"
    // [717] rom_device_names[rom_detect::$14] = rom_detect::$31 -- qbuc1_derefidx_vbum1=pbuc2 
    ldy rom_detect__14
    lda #<rom_detect__31
    sta rom_device_names,y
    lda #>rom_detect__31
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "000"
    // [718] rom_size_strings[rom_detect::$14] = rom_detect::$32 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__32
    sta rom_size_strings,y
    lda #>rom_detect__32
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 0
    // [719] rom_detect::$24 = rom_detect::rom_chip#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta rom_detect__24
    // [720] rom_sizes[rom_detect::$24] = 0 -- pduc1_derefidx_vbum1=vbuc2 
    tay
    lda #0
    sta rom_sizes,y
    sta rom_sizes+1,y
    sta rom_sizes+2,y
    sta rom_sizes+3,y
    // rom_device_ids[rom_chip] = UNKNOWN
    // [721] rom_device_ids[rom_detect::rom_chip#10] = $55 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$55
    ldy rom_chip
    sta rom_device_ids,y
    // rom_detect::@7
  __b7:
    // rom_chip++;
    // [722] rom_detect::rom_chip#1 = ++ rom_detect::rom_chip#10 -- vbum1=_inc_vbum1 
    inc rom_chip
    // rom_detect::@8
    // rom_detect_address += 0x80000
    // [723] rom_detect::rom_detect_address#1 = rom_detect::rom_detect_address#10 + $80000 -- vduz1=vduz1_plus_vduc1 
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
    // [687] phi from rom_detect::@8 to rom_detect::@1 [phi:rom_detect::@8->rom_detect::@1]
    // [687] phi rom_detect::rom_chip#10 = rom_detect::rom_chip#1 [phi:rom_detect::@8->rom_detect::@1#0] -- register_copy 
    // [687] phi rom_detect::rom_detect_address#10 = rom_detect::rom_detect_address#1 [phi:rom_detect::@8->rom_detect::@1#1] -- register_copy 
    jmp __b1
    // rom_detect::@5
  __b5:
    // rom_device_names[rom_chip] = "f040"
    // [724] rom_device_names[rom_detect::$14] = rom_detect::$29 -- qbuc1_derefidx_vbum1=pbuc2 
    ldy rom_detect__14
    lda #<rom_detect__29
    sta rom_device_names,y
    lda #>rom_detect__29
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "512"
    // [725] rom_size_strings[rom_detect::$14] = rom_detect::$30 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__30
    sta rom_size_strings,y
    lda #>rom_detect__30
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 512 * 1024
    // [726] rom_detect::$21 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__21
    // [727] rom_sizes[rom_detect::$21] = (unsigned long)$200*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
    // [728] rom_device_names[rom_detect::$14] = rom_detect::$27 -- qbuc1_derefidx_vbum1=pbuc2 
    ldy rom_detect__14
    lda #<rom_detect__27
    sta rom_device_names,y
    lda #>rom_detect__27
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "256"
    // [729] rom_size_strings[rom_detect::$14] = rom_detect::$28 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__28
    sta rom_size_strings,y
    lda #>rom_detect__28
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 256 * 1024
    // [730] rom_detect::$18 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__18
    // [731] rom_sizes[rom_detect::$18] = (unsigned long)$100*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
    // [732] rom_device_names[rom_detect::$14] = rom_detect::$25 -- qbuc1_derefidx_vbum1=pbuc2 
    ldy rom_detect__14
    lda #<rom_detect__25
    sta rom_device_names,y
    lda #>rom_detect__25
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "128"
    // [733] rom_size_strings[rom_detect::$14] = rom_detect::$26 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__26
    sta rom_size_strings,y
    lda #>rom_detect__26
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 128 * 1024
    // [734] rom_detect::$15 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__15
    // [735] rom_sizes[rom_detect::$15] = (unsigned long)$80*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
    .label rom_detect__14 = chip_rom.chip_rom__3
    .label rom_detect__24 = chip_rom.chip_rom__9
    .label rom_chip = main.check_vera1_main__0
}
.segment Code
  // chip_rom
chip_rom: {
    .label chip_rom__5 = $b1
    .label r = $25
    // [737] phi from chip_rom to chip_rom::@1 [phi:chip_rom->chip_rom::@1]
    // [737] phi chip_rom::r#2 = 0 [phi:chip_rom->chip_rom::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z r
    // chip_rom::@1
  __b1:
    // for (unsigned char r = 0; r < 8; r++)
    // [738] if(chip_rom::r#2<8) goto chip_rom::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z r
    cmp #8
    bcc __b2
    // chip_rom::@return
    // }
    // [739] return 
    rts
    // [740] phi from chip_rom::@1 to chip_rom::@2 [phi:chip_rom::@1->chip_rom::@2]
    // chip_rom::@2
  __b2:
    // strcpy(rom, "rom0 ")
    // [741] call strcpy
    // [1751] phi from chip_rom::@2 to strcpy [phi:chip_rom::@2->strcpy]
    // [1751] phi strcpy::dst#0 = chip_rom::rom [phi:chip_rom::@2->strcpy#0] -- pbum1=pbuc1 
    lda #<rom
    sta strcpy.dst
    lda #>rom
    sta strcpy.dst+1
    // [1751] phi strcpy::src#0 = chip_rom::source [phi:chip_rom::@2->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // chip_rom::@3
    // strcat(rom, rom_size_strings[r])
    // [742] chip_rom::$9 = chip_rom::r#2 << 1 -- vbum1=vbuz2_rol_1 
    lda.z r
    asl
    sta chip_rom__9
    // [743] strcat::source#0 = rom_size_strings[chip_rom::$9] -- pbuz1=qbuc1_derefidx_vbum2 
    tay
    lda rom_size_strings,y
    sta.z strcat.source
    lda rom_size_strings+1,y
    sta.z strcat.source+1
    // [744] call strcat
    // [1759] phi from chip_rom::@3 to strcat [phi:chip_rom::@3->strcat]
    jsr strcat
    // chip_rom::@4
    // r+'0'
    // [745] chip_rom::$3 = chip_rom::r#2 + '0' -- vbum1=vbuz2_plus_vbuc1 
    lda #'0'
    clc
    adc.z r
    sta chip_rom__3
    // *(rom+3) = r+'0'
    // [746] *(chip_rom::rom+3) = chip_rom::$3 -- _deref_pbuc1=vbum1 
    sta rom+3
    // print_rom_led(r, GREY)
    // [747] print_rom_led::chip#0 = chip_rom::r#2 -- vbuz1=vbuz2 
    lda.z r
    sta.z print_rom_led.chip
    // [748] call print_rom_led
    // [1771] phi from chip_rom::@4 to print_rom_led [phi:chip_rom::@4->print_rom_led]
    // [1771] phi print_rom_led::c#2 = GREY [phi:chip_rom::@4->print_rom_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z print_rom_led.c
    // [1771] phi print_rom_led::chip#2 = print_rom_led::chip#0 [phi:chip_rom::@4->print_rom_led#1] -- register_copy 
    jsr print_rom_led
    // chip_rom::@5
    // r*6
    // [749] chip_rom::$10 = chip_rom::$9 + chip_rom::r#2 -- vbum1=vbum1_plus_vbuz2 
    lda chip_rom__10
    clc
    adc.z r
    sta chip_rom__10
    // [750] chip_rom::$5 = chip_rom::$10 << 1 -- vbuz1=vbum2_rol_1 
    asl
    sta.z chip_rom__5
    // print_chip(CHIP_ROM_X+r*6, CHIP_ROM_Y+1, CHIP_ROM_W, rom)
    // [751] print_chip::x#2 = $14 + chip_rom::$5 -- vbuz1=vbuc1_plus_vbuz1 
    lda #$14
    clc
    adc.z print_chip.x
    sta.z print_chip.x
    // [752] call print_chip
    // [1620] phi from chip_rom::@5 to print_chip [phi:chip_rom::@5->print_chip]
    // [1620] phi print_chip::text#11 = chip_rom::rom [phi:chip_rom::@5->print_chip#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z print_chip.text_2
    lda #>rom
    sta.z print_chip.text_2+1
    // [1620] phi print_chip::w#10 = 3 [phi:chip_rom::@5->print_chip#1] -- vbuz1=vbuc1 
    lda #3
    sta.z print_chip.w
    // [1620] phi print_chip::x#10 = print_chip::x#2 [phi:chip_rom::@5->print_chip#2] -- register_copy 
    jsr print_chip
    // chip_rom::@6
    // for (unsigned char r = 0; r < 8; r++)
    // [753] chip_rom::r#1 = ++ chip_rom::r#2 -- vbuz1=_inc_vbuz1 
    inc.z r
    // [737] phi from chip_rom::@6 to chip_rom::@1 [phi:chip_rom::@6->chip_rom::@1]
    // [737] phi chip_rom::r#2 = chip_rom::r#1 [phi:chip_rom::@6->chip_rom::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    rom: .fill $10, 0
    source: .text "rom0 "
    .byte 0
    chip_rom__3: .byte 0
    chip_rom__9: .byte 0
    .label chip_rom__10 = chip_rom__9
}
.segment Code
  // smc_read
// __mem() unsigned int smc_read(char b, unsigned int progress_row_size)
smc_read: {
    .label fp = $b6
    .label smc_file_read = $a9
    .label ram_address = $f9
    /// Holds the amount of bytes actually read in the memory to be flashed.
    .label progress_row_bytes = $b3
    .label y = $db
    // info_progress("Reading SMC.BIN ... (.) data, ( ) empty")
    // [755] call info_progress
  // It is assume that one RAM bank is 0X2000 bytes.
    // [589] phi from smc_read to info_progress [phi:smc_read->info_progress]
    // [589] phi info_progress::info_text#12 = smc_read::info_text [phi:smc_read->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_progress.info_text
    lda #>info_text
    sta.z info_progress.info_text+1
    jsr info_progress
    // [756] phi from smc_read to smc_read::@7 [phi:smc_read->smc_read::@7]
    // smc_read::@7
    // textcolor(WHITE)
    // [757] call textcolor
    // [461] phi from smc_read::@7 to textcolor [phi:smc_read::@7->textcolor]
    // [461] phi textcolor::color#16 = WHITE [phi:smc_read::@7->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [758] phi from smc_read::@7 to smc_read::@8 [phi:smc_read::@7->smc_read::@8]
    // smc_read::@8
    // gotoxy(x, y)
    // [759] call gotoxy
    // [479] phi from smc_read::@8 to gotoxy [phi:smc_read::@8->gotoxy]
    // [479] phi gotoxy::y#29 = PROGRESS_Y [phi:smc_read::@8->gotoxy#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z gotoxy.y
    // [479] phi gotoxy::x#29 = PROGRESS_X [phi:smc_read::@8->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [760] phi from smc_read::@8 to smc_read::@9 [phi:smc_read::@8->smc_read::@9]
    // smc_read::@9
    // FILE *fp = fopen("SMC.BIN", "r")
    // [761] call fopen
    // [1779] phi from smc_read::@9 to fopen [phi:smc_read::@9->fopen]
    // [1779] phi __errno#295 = __errno#35 [phi:smc_read::@9->fopen#0] -- register_copy 
    // [1779] phi fopen::pathtoken#0 = smc_read::path [phi:smc_read::@9->fopen#1] -- pbuz1=pbuc1 
    lda #<path
    sta.z fopen.pathtoken
    lda #>path
    sta.z fopen.pathtoken+1
    jsr fopen
    // FILE *fp = fopen("SMC.BIN", "r")
    // [762] fopen::return#3 = fopen::return#2
    // smc_read::@10
    // [763] smc_read::fp#0 = fopen::return#3 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [764] if((struct $2 *)0==smc_read::fp#0) goto smc_read::@1 -- pssc1_eq_pssz1_then_la1 
    lda.z fp
    cmp #<0
    bne !+
    lda.z fp+1
    cmp #>0
    beq __b4
  !:
    // [765] phi from smc_read::@10 to smc_read::@2 [phi:smc_read::@10->smc_read::@2]
    // [765] phi smc_read::y#10 = PROGRESS_Y [phi:smc_read::@10->smc_read::@2#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // [765] phi smc_read::progress_row_bytes#10 = 0 [phi:smc_read::@10->smc_read::@2#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z progress_row_bytes
    sta.z progress_row_bytes+1
    // [765] phi smc_read::smc_file_size#11 = 0 [phi:smc_read::@10->smc_read::@2#2] -- vwum1=vwuc1 
    sta smc_file_size
    sta smc_file_size+1
    // [765] phi smc_read::ram_address#10 = (char *)$6000 [phi:smc_read::@10->smc_read::@2#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z ram_address
    lda #>$6000
    sta.z ram_address+1
  // We read b bytes at a time, and each b bytes we plot a dot.
  // Every r bytes we move to the next line.
    // smc_read::@2
  __b2:
    // fgets(ram_address, b, fp)
    // [766] fgets::ptr#2 = smc_read::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z fgets.ptr
    lda.z ram_address+1
    sta.z fgets.ptr+1
    // [767] fgets::stream#0 = smc_read::fp#0 -- pssm1=pssz2 
    lda.z fp
    sta fgets.stream
    lda.z fp+1
    sta fgets.stream+1
    // [768] call fgets
    // [1860] phi from smc_read::@2 to fgets [phi:smc_read::@2->fgets]
    // [1860] phi fgets::ptr#12 = fgets::ptr#2 [phi:smc_read::@2->fgets#0] -- register_copy 
    // [1860] phi fgets::size#10 = 8 [phi:smc_read::@2->fgets#1] -- vwuz1=vbuc1 
    lda #<8
    sta.z fgets.size
    lda #>8
    sta.z fgets.size+1
    // [1860] phi fgets::stream#2 = fgets::stream#0 [phi:smc_read::@2->fgets#2] -- register_copy 
    jsr fgets
    // fgets(ram_address, b, fp)
    // [769] fgets::return#5 = fgets::return#1
    // smc_read::@11
    // smc_file_read = fgets(ram_address, b, fp)
    // [770] smc_read::smc_file_read#1 = fgets::return#5
    // while (smc_file_read = fgets(ram_address, b, fp))
    // [771] if(0!=smc_read::smc_file_read#1) goto smc_read::@3 -- 0_neq_vwuz1_then_la1 
    lda.z smc_file_read
    ora.z smc_file_read+1
    bne __b3
    // smc_read::@4
    // fclose(fp)
    // [772] fclose::stream#0 = smc_read::fp#0
    // [773] call fclose
    // [1914] phi from smc_read::@4 to fclose [phi:smc_read::@4->fclose]
    // [1914] phi fclose::stream#2 = fclose::stream#0 [phi:smc_read::@4->fclose#0] -- register_copy 
    jsr fclose
    // [774] phi from smc_read::@4 to smc_read::@1 [phi:smc_read::@4->smc_read::@1]
    // [774] phi smc_read::return#0 = smc_read::smc_file_size#11 [phi:smc_read::@4->smc_read::@1#0] -- register_copy 
    rts
    // [774] phi from smc_read::@10 to smc_read::@1 [phi:smc_read::@10->smc_read::@1]
  __b4:
    // [774] phi smc_read::return#0 = 0 [phi:smc_read::@10->smc_read::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta return
    sta return+1
    // smc_read::@1
    // smc_read::@return
    // }
    // [775] return 
    rts
    // [776] phi from smc_read::@11 to smc_read::@3 [phi:smc_read::@11->smc_read::@3]
    // smc_read::@3
  __b3:
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [777] call snprintf_init
    jsr snprintf_init
    // [778] phi from smc_read::@3 to smc_read::@12 [phi:smc_read::@3->smc_read::@12]
    // smc_read::@12
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [779] call printf_str
    // [623] phi from smc_read::@12 to printf_str [phi:smc_read::@12->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:smc_read::@12->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = smc_read::s [phi:smc_read::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@13
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [780] printf_uint::uvalue#1 = smc_read::smc_file_read#1 -- vwuz1=vwuz2 
    lda.z smc_file_read
    sta.z printf_uint.uvalue
    lda.z smc_file_read+1
    sta.z printf_uint.uvalue+1
    // [781] call printf_uint
    // [632] phi from smc_read::@13 to printf_uint [phi:smc_read::@13->printf_uint]
    // [632] phi printf_uint::format_zero_padding#16 = 1 [phi:smc_read::@13->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [632] phi printf_uint::format_min_length#16 = 5 [phi:smc_read::@13->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [632] phi printf_uint::putc#16 = &snputc [phi:smc_read::@13->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [632] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:smc_read::@13->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [632] phi printf_uint::uvalue#16 = printf_uint::uvalue#1 [phi:smc_read::@13->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [782] phi from smc_read::@13 to smc_read::@14 [phi:smc_read::@13->smc_read::@14]
    // smc_read::@14
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [783] call printf_str
    // [623] phi from smc_read::@14 to printf_str [phi:smc_read::@14->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:smc_read::@14->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = s1 [phi:smc_read::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@15
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [784] printf_uint::uvalue#2 = smc_read::smc_file_size#11 -- vwuz1=vwum2 
    lda smc_file_size
    sta.z printf_uint.uvalue
    lda smc_file_size+1
    sta.z printf_uint.uvalue+1
    // [785] call printf_uint
    // [632] phi from smc_read::@15 to printf_uint [phi:smc_read::@15->printf_uint]
    // [632] phi printf_uint::format_zero_padding#16 = 1 [phi:smc_read::@15->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [632] phi printf_uint::format_min_length#16 = 5 [phi:smc_read::@15->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [632] phi printf_uint::putc#16 = &snputc [phi:smc_read::@15->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [632] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:smc_read::@15->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [632] phi printf_uint::uvalue#16 = printf_uint::uvalue#2 [phi:smc_read::@15->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [786] phi from smc_read::@15 to smc_read::@16 [phi:smc_read::@15->smc_read::@16]
    // smc_read::@16
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [787] call printf_str
    // [623] phi from smc_read::@16 to printf_str [phi:smc_read::@16->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:smc_read::@16->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = s2 [phi:smc_read::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // [788] phi from smc_read::@16 to smc_read::@17 [phi:smc_read::@16->smc_read::@17]
    // smc_read::@17
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [789] call printf_uint
    // [632] phi from smc_read::@17 to printf_uint [phi:smc_read::@17->printf_uint]
    // [632] phi printf_uint::format_zero_padding#16 = 1 [phi:smc_read::@17->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [632] phi printf_uint::format_min_length#16 = 2 [phi:smc_read::@17->printf_uint#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uint.format_min_length
    // [632] phi printf_uint::putc#16 = &snputc [phi:smc_read::@17->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [632] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:smc_read::@17->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [632] phi printf_uint::uvalue#16 = 0 [phi:smc_read::@17->printf_uint#4] -- vwuz1=vbuc1 
    lda #<0
    sta.z printf_uint.uvalue
    sta.z printf_uint.uvalue+1
    jsr printf_uint
    // [790] phi from smc_read::@17 to smc_read::@18 [phi:smc_read::@17->smc_read::@18]
    // smc_read::@18
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [791] call printf_str
    // [623] phi from smc_read::@18 to printf_str [phi:smc_read::@18->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:smc_read::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = s3 [phi:smc_read::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@19
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [792] printf_uint::uvalue#4 = (unsigned int)smc_read::ram_address#10 -- vwuz1=vwuz2 
    lda.z ram_address
    sta.z printf_uint.uvalue
    lda.z ram_address+1
    sta.z printf_uint.uvalue+1
    // [793] call printf_uint
    // [632] phi from smc_read::@19 to printf_uint [phi:smc_read::@19->printf_uint]
    // [632] phi printf_uint::format_zero_padding#16 = 1 [phi:smc_read::@19->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [632] phi printf_uint::format_min_length#16 = 4 [phi:smc_read::@19->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [632] phi printf_uint::putc#16 = &snputc [phi:smc_read::@19->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [632] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:smc_read::@19->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [632] phi printf_uint::uvalue#16 = printf_uint::uvalue#4 [phi:smc_read::@19->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [794] phi from smc_read::@19 to smc_read::@20 [phi:smc_read::@19->smc_read::@20]
    // smc_read::@20
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [795] call printf_str
    // [623] phi from smc_read::@20 to printf_str [phi:smc_read::@20->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:smc_read::@20->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = s4 [phi:smc_read::@20->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@21
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [796] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [797] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [799] call info_line
    // [811] phi from smc_read::@21 to info_line [phi:smc_read::@21->info_line]
    // [811] phi info_line::info_text#17 = info_text [phi:smc_read::@21->info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_line.info_text
    lda #>@info_text
    sta.z info_line.info_text+1
    jsr info_line
    // smc_read::@22
    // if (progress_row_bytes == progress_row_size)
    // [800] if(smc_read::progress_row_bytes#10!=$200) goto smc_read::@5 -- vwuz1_neq_vwuc1_then_la1 
    lda.z progress_row_bytes+1
    cmp #>$200
    bne __b5
    lda.z progress_row_bytes
    cmp #<$200
    bne __b5
    // smc_read::@6
    // gotoxy(x, ++y);
    // [801] smc_read::y#1 = ++ smc_read::y#10 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [802] gotoxy::y#19 = smc_read::y#1 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [803] call gotoxy
    // [479] phi from smc_read::@6 to gotoxy [phi:smc_read::@6->gotoxy]
    // [479] phi gotoxy::y#29 = gotoxy::y#19 [phi:smc_read::@6->gotoxy#0] -- register_copy 
    // [479] phi gotoxy::x#29 = PROGRESS_X [phi:smc_read::@6->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [804] phi from smc_read::@6 to smc_read::@5 [phi:smc_read::@6->smc_read::@5]
    // [804] phi smc_read::y#20 = smc_read::y#1 [phi:smc_read::@6->smc_read::@5#0] -- register_copy 
    // [804] phi smc_read::progress_row_bytes#4 = 0 [phi:smc_read::@6->smc_read::@5#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z progress_row_bytes
    sta.z progress_row_bytes+1
    // [804] phi from smc_read::@22 to smc_read::@5 [phi:smc_read::@22->smc_read::@5]
    // [804] phi smc_read::y#20 = smc_read::y#10 [phi:smc_read::@22->smc_read::@5#0] -- register_copy 
    // [804] phi smc_read::progress_row_bytes#4 = smc_read::progress_row_bytes#10 [phi:smc_read::@22->smc_read::@5#1] -- register_copy 
    // smc_read::@5
  __b5:
    // cputc('+')
    // [805] stackpush(char) = '+' -- _stackpushbyte_=vbuc1 
    lda #'+'
    pha
    // [806] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // ram_address += smc_file_read
    // [808] smc_read::ram_address#1 = smc_read::ram_address#10 + smc_read::smc_file_read#1 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z ram_address
    adc.z smc_file_read
    sta.z ram_address
    lda.z ram_address+1
    adc.z smc_file_read+1
    sta.z ram_address+1
    // smc_file_size += smc_file_read
    // [809] smc_read::smc_file_size#1 = smc_read::smc_file_size#11 + smc_read::smc_file_read#1 -- vwum1=vwum1_plus_vwuz2 
    clc
    lda smc_file_size
    adc.z smc_file_read
    sta smc_file_size
    lda smc_file_size+1
    adc.z smc_file_read+1
    sta smc_file_size+1
    // progress_row_bytes += smc_file_read
    // [810] smc_read::progress_row_bytes#1 = smc_read::progress_row_bytes#4 + smc_read::smc_file_read#1 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z progress_row_bytes
    adc.z smc_file_read
    sta.z progress_row_bytes
    lda.z progress_row_bytes+1
    adc.z smc_file_read+1
    sta.z progress_row_bytes+1
    // [765] phi from smc_read::@5 to smc_read::@2 [phi:smc_read::@5->smc_read::@2]
    // [765] phi smc_read::y#10 = smc_read::y#20 [phi:smc_read::@5->smc_read::@2#0] -- register_copy 
    // [765] phi smc_read::progress_row_bytes#10 = smc_read::progress_row_bytes#1 [phi:smc_read::@5->smc_read::@2#1] -- register_copy 
    // [765] phi smc_read::smc_file_size#11 = smc_read::smc_file_size#1 [phi:smc_read::@5->smc_read::@2#2] -- register_copy 
    // [765] phi smc_read::ram_address#10 = smc_read::ram_address#1 [phi:smc_read::@5->smc_read::@2#3] -- register_copy 
    jmp __b2
  .segment Data
    info_text: .text "Reading SMC.BIN ... (.) data, ( ) empty"
    .byte 0
    path: .text "SMC.BIN"
    .byte 0
    s: .text "Reading SMC.BIN:"
    .byte 0
    .label return = strcpy.dst
    .label smc_file_size = strcpy.dst
}
.segment Code
  // info_line
// void info_line(__zp($4a) char *info_text)
info_line: {
    .label info_text = $4a
    .label x = $e2
    .label y = $e0
    // unsigned char x = wherex()
    // [812] call wherex
    jsr wherex
    // [813] wherex::return#3 = wherex::return#0 -- vbuz1=vbuz2 
    lda.z wherex.return
    sta.z wherex.return_1
    // info_line::@1
    // [814] info_line::x#0 = wherex::return#3
    // unsigned char y = wherey()
    // [815] call wherey
    jsr wherey
    // [816] wherey::return#3 = wherey::return#0 -- vbuz1=vbuz2 
    lda.z wherey.return
    sta.z wherey.return_1
    // info_line::@2
    // [817] info_line::y#0 = wherey::return#3
    // gotoxy(2, PROGRESS_Y-3)
    // [818] call gotoxy
    // [479] phi from info_line::@2 to gotoxy [phi:info_line::@2->gotoxy]
    // [479] phi gotoxy::y#29 = PROGRESS_Y-3 [phi:info_line::@2->gotoxy#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-3
    sta.z gotoxy.y
    // [479] phi gotoxy::x#29 = 2 [phi:info_line::@2->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // info_line::@3
    // printf("%-65s", info_text)
    // [819] printf_string::str#1 = info_line::info_text#17 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [820] call printf_string
    // [1034] phi from info_line::@3 to printf_string [phi:info_line::@3->printf_string]
    // [1034] phi printf_string::putc#16 = &cputc [phi:info_line::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1034] phi printf_string::str#16 = printf_string::str#1 [phi:info_line::@3->printf_string#1] -- register_copy 
    // [1034] phi printf_string::format_justify_left#16 = 1 [phi:info_line::@3->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1034] phi printf_string::format_min_length#16 = $41 [phi:info_line::@3->printf_string#3] -- vbuz1=vbuc1 
    lda #$41
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_line::@4
    // gotoxy(x, y)
    // [821] gotoxy::x#12 = info_line::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [822] gotoxy::y#12 = info_line::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [823] call gotoxy
    // [479] phi from info_line::@4 to gotoxy [phi:info_line::@4->gotoxy]
    // [479] phi gotoxy::y#29 = gotoxy::y#12 [phi:info_line::@4->gotoxy#0] -- register_copy 
    // [479] phi gotoxy::x#29 = gotoxy::x#12 [phi:info_line::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // info_line::@return
    // }
    // [824] return 
    rts
}
  // flash_smc
// unsigned int flash_smc(char x, __mem() char y, char w, __zp($cf) unsigned int smc_bytes_total, char b, unsigned int smc_row_total, __zp($d3) char *smc_ram_ptr)
flash_smc: {
    .const smc_row_total = $200
    .label cx16_k_i2c_write_byte1_return = $25
    .label smc_bootloader_start = $25
    .label smc_bootloader_not_activated1 = $2a
    .label x1 = $ab
    .label smc_bootloader_not_activated = $2a
    .label x2 = $26
    .label smc_byte_upload = $b5
    .label smc_ram_ptr = $d3
    .label smc_package_flashed = $5f
    .label smc_commit_result = $2a
    .label smc_attempts_flashed = $7f
    .label smc_row_bytes = $d1
    .label smc_bytes_total = $cf
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [825] flash_smc::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [826] flash_smc::cx16_k_i2c_write_byte1_offset = $8f -- vbum1=vbuc1 
    lda #$8f
    sta cx16_k_i2c_write_byte1_offset
    // [827] flash_smc::cx16_k_i2c_write_byte1_value = $31 -- vbum1=vbuc1 
    lda #$31
    sta cx16_k_i2c_write_byte1_value
    // flash_smc::cx16_k_i2c_write_byte1
    // unsigned char result
    // [828] flash_smc::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
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
    // [830] flash_smc::cx16_k_i2c_write_byte1_return#0 = flash_smc::cx16_k_i2c_write_byte1_result -- vbuz1=vbum2 
    lda cx16_k_i2c_write_byte1_result
    sta.z cx16_k_i2c_write_byte1_return
    // flash_smc::cx16_k_i2c_write_byte1_@return
    // }
    // [831] flash_smc::cx16_k_i2c_write_byte1_return#1 = flash_smc::cx16_k_i2c_write_byte1_return#0
    // flash_smc::@27
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [832] flash_smc::smc_bootloader_start#0 = flash_smc::cx16_k_i2c_write_byte1_return#1
    // if(smc_bootloader_start)
    // [833] if(0==flash_smc::smc_bootloader_start#0) goto flash_smc::@3 -- 0_eq_vbuz1_then_la1 
    lda.z smc_bootloader_start
    beq __b2
    // [834] phi from flash_smc::@27 to flash_smc::@2 [phi:flash_smc::@27->flash_smc::@2]
    // flash_smc::@2
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [835] call snprintf_init
    jsr snprintf_init
    // [836] phi from flash_smc::@2 to flash_smc::@30 [phi:flash_smc::@2->flash_smc::@30]
    // flash_smc::@30
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [837] call printf_str
    // [623] phi from flash_smc::@30 to printf_str [phi:flash_smc::@30->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:flash_smc::@30->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = flash_smc::s [phi:flash_smc::@30->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@31
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [838] printf_uchar::uvalue#1 = flash_smc::smc_bootloader_start#0
    // [839] call printf_uchar
    // [1018] phi from flash_smc::@31 to printf_uchar [phi:flash_smc::@31->printf_uchar]
    // [1018] phi printf_uchar::format_zero_padding#10 = 0 [phi:flash_smc::@31->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1018] phi printf_uchar::format_min_length#10 = 0 [phi:flash_smc::@31->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1018] phi printf_uchar::putc#10 = &snputc [phi:flash_smc::@31->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1018] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:flash_smc::@31->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [1018] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#1 [phi:flash_smc::@31->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // flash_smc::@32
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [840] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [841] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [843] call info_line
    // [811] phi from flash_smc::@32 to info_line [phi:flash_smc::@32->info_line]
    // [811] phi info_line::info_text#17 = info_text [phi:flash_smc::@32->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    // flash_smc::@33
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [844] flash_smc::cx16_k_i2c_write_byte2_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte2_device
    // [845] flash_smc::cx16_k_i2c_write_byte2_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte2_offset
    // [846] flash_smc::cx16_k_i2c_write_byte2_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte2_value
    // flash_smc::cx16_k_i2c_write_byte2
    // unsigned char result
    // [847] flash_smc::cx16_k_i2c_write_byte2_result = 0 -- vbum1=vbuc1 
    sta cx16_k_i2c_write_byte2_result
    // asm
    // asm { ldxdevice ldyoffset ldavalue stzresult jsrCX16_I2C_WRITE_BYTE rolresult  }
    ldx cx16_k_i2c_write_byte2_device
    ldy cx16_k_i2c_write_byte2_offset
    lda cx16_k_i2c_write_byte2_value
    stz cx16_k_i2c_write_byte2_result
    jsr CX16_I2C_WRITE_BYTE
    rol cx16_k_i2c_write_byte2_result
    // flash_smc::@return
    // }
    // [849] return 
    rts
    // [850] phi from flash_smc::@27 to flash_smc::@3 [phi:flash_smc::@27->flash_smc::@3]
  __b2:
    // [850] phi flash_smc::smc_bootloader_activation_countdown#22 = $14 [phi:flash_smc::@27->flash_smc::@3#0] -- vbum1=vbuc1 
    lda #$14
    sta smc_bootloader_activation_countdown
    // flash_smc::@3
  __b3:
    // while(smc_bootloader_activation_countdown)
    // [851] if(0!=flash_smc::smc_bootloader_activation_countdown#22) goto flash_smc::@4 -- 0_neq_vbum1_then_la1 
    lda smc_bootloader_activation_countdown
    beq !__b4+
    jmp __b4
  !__b4:
    // [852] phi from flash_smc::@3 flash_smc::@34 to flash_smc::@9 [phi:flash_smc::@3/flash_smc::@34->flash_smc::@9]
  __b5:
    // [852] phi flash_smc::smc_bootloader_activation_countdown#23 = 5 [phi:flash_smc::@3/flash_smc::@34->flash_smc::@9#0] -- vbum1=vbuc1 
    lda #5
    sta smc_bootloader_activation_countdown_1
    // flash_smc::@9
  __b9:
    // while(smc_bootloader_activation_countdown)
    // [853] if(0!=flash_smc::smc_bootloader_activation_countdown#23) goto flash_smc::@11 -- 0_neq_vbum1_then_la1 
    lda smc_bootloader_activation_countdown_1
    beq !__b13+
    jmp __b13
  !__b13:
    // flash_smc::@10
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [854] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [855] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [856] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [857] cx16_k_i2c_read_byte::return#3 = cx16_k_i2c_read_byte::return#1
    // flash_smc::@39
    // smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [858] flash_smc::smc_bootloader_not_activated#1 = cx16_k_i2c_read_byte::return#3
    // if(smc_bootloader_not_activated)
    // [859] if(0==flash_smc::smc_bootloader_not_activated#1) goto flash_smc::@1 -- 0_eq_vwuz1_then_la1 
    lda.z smc_bootloader_not_activated
    ora.z smc_bootloader_not_activated+1
    beq __b1
    // [860] phi from flash_smc::@39 to flash_smc::@14 [phi:flash_smc::@39->flash_smc::@14]
    // flash_smc::@14
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [861] call snprintf_init
    jsr snprintf_init
    // [862] phi from flash_smc::@14 to flash_smc::@46 [phi:flash_smc::@14->flash_smc::@46]
    // flash_smc::@46
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [863] call printf_str
    // [623] phi from flash_smc::@46 to printf_str [phi:flash_smc::@46->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:flash_smc::@46->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = flash_smc::s5 [phi:flash_smc::@46->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@47
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [864] printf_uint::uvalue#5 = flash_smc::smc_bootloader_not_activated#1
    // [865] call printf_uint
    // [632] phi from flash_smc::@47 to printf_uint [phi:flash_smc::@47->printf_uint]
    // [632] phi printf_uint::format_zero_padding#16 = 0 [phi:flash_smc::@47->printf_uint#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uint.format_zero_padding
    // [632] phi printf_uint::format_min_length#16 = 0 [phi:flash_smc::@47->printf_uint#1] -- vbuz1=vbuc1 
    sta.z printf_uint.format_min_length
    // [632] phi printf_uint::putc#16 = &snputc [phi:flash_smc::@47->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [632] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:flash_smc::@47->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [632] phi printf_uint::uvalue#16 = printf_uint::uvalue#5 [phi:flash_smc::@47->printf_uint#4] -- register_copy 
    jsr printf_uint
    // flash_smc::@48
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [866] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [867] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [869] call info_line
    // [811] phi from flash_smc::@48 to info_line [phi:flash_smc::@48->info_line]
    // [811] phi info_line::info_text#17 = info_text [phi:flash_smc::@48->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    rts
    // [870] phi from flash_smc::@39 to flash_smc::@1 [phi:flash_smc::@39->flash_smc::@1]
    // flash_smc::@1
  __b1:
    // textcolor(WHITE)
    // [871] call textcolor
    // [461] phi from flash_smc::@1 to textcolor [phi:flash_smc::@1->textcolor]
    // [461] phi textcolor::color#16 = WHITE [phi:flash_smc::@1->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [872] phi from flash_smc::@1 to flash_smc::@45 [phi:flash_smc::@1->flash_smc::@45]
    // flash_smc::@45
    // gotoxy(x, y)
    // [873] call gotoxy
    // [479] phi from flash_smc::@45 to gotoxy [phi:flash_smc::@45->gotoxy]
    // [479] phi gotoxy::y#29 = PROGRESS_Y [phi:flash_smc::@45->gotoxy#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z gotoxy.y
    // [479] phi gotoxy::x#29 = PROGRESS_X [phi:flash_smc::@45->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [874] phi from flash_smc::@45 to flash_smc::@15 [phi:flash_smc::@45->flash_smc::@15]
    // [874] phi flash_smc::y#33 = PROGRESS_Y [phi:flash_smc::@45->flash_smc::@15#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [874] phi flash_smc::smc_attempts_total#21 = 0 [phi:flash_smc::@45->flash_smc::@15#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_attempts_total
    sta smc_attempts_total+1
    // [874] phi flash_smc::smc_row_bytes#14 = 0 [phi:flash_smc::@45->flash_smc::@15#2] -- vwuz1=vwuc1 
    sta.z smc_row_bytes
    sta.z smc_row_bytes+1
    // [874] phi flash_smc::smc_ram_ptr#13 = (char *)$6000 [phi:flash_smc::@45->flash_smc::@15#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z smc_ram_ptr
    lda #>$6000
    sta.z smc_ram_ptr+1
    // [874] phi flash_smc::smc_bytes_flashed#13 = 0 [phi:flash_smc::@45->flash_smc::@15#4] -- vwum1=vwuc1 
    lda #<0
    sta smc_bytes_flashed
    sta smc_bytes_flashed+1
    // [874] phi from flash_smc::@18 to flash_smc::@15 [phi:flash_smc::@18->flash_smc::@15]
    // [874] phi flash_smc::y#33 = flash_smc::y#23 [phi:flash_smc::@18->flash_smc::@15#0] -- register_copy 
    // [874] phi flash_smc::smc_attempts_total#21 = flash_smc::smc_attempts_total#17 [phi:flash_smc::@18->flash_smc::@15#1] -- register_copy 
    // [874] phi flash_smc::smc_row_bytes#14 = flash_smc::smc_row_bytes#10 [phi:flash_smc::@18->flash_smc::@15#2] -- register_copy 
    // [874] phi flash_smc::smc_ram_ptr#13 = flash_smc::smc_ram_ptr#10 [phi:flash_smc::@18->flash_smc::@15#3] -- register_copy 
    // [874] phi flash_smc::smc_bytes_flashed#13 = flash_smc::smc_bytes_flashed#12 [phi:flash_smc::@18->flash_smc::@15#4] -- register_copy 
    // flash_smc::@15
  __b15:
    // while(smc_bytes_flashed < smc_bytes_total)
    // [875] if(flash_smc::smc_bytes_flashed#13<flash_smc::smc_bytes_total#0) goto flash_smc::@17 -- vwum1_lt_vwuz2_then_la1 
    lda smc_bytes_flashed+1
    cmp.z smc_bytes_total+1
    bcc __b8
    bne !+
    lda smc_bytes_flashed
    cmp.z smc_bytes_total
    bcc __b8
  !:
    // flash_smc::@16
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [876] flash_smc::cx16_k_i2c_write_byte3_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte3_device
    // [877] flash_smc::cx16_k_i2c_write_byte3_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte3_offset
    // [878] flash_smc::cx16_k_i2c_write_byte3_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte3_value
    // flash_smc::cx16_k_i2c_write_byte3
    // unsigned char result
    // [879] flash_smc::cx16_k_i2c_write_byte3_result = 0 -- vbum1=vbuc1 
    sta cx16_k_i2c_write_byte3_result
    // asm
    // asm { ldxdevice ldyoffset ldavalue stzresult jsrCX16_I2C_WRITE_BYTE rolresult  }
    ldx cx16_k_i2c_write_byte3_device
    ldy cx16_k_i2c_write_byte3_offset
    lda cx16_k_i2c_write_byte3_value
    stz cx16_k_i2c_write_byte3_result
    jsr CX16_I2C_WRITE_BYTE
    rol cx16_k_i2c_write_byte3_result
    rts
    // [881] phi from flash_smc::@15 to flash_smc::@17 [phi:flash_smc::@15->flash_smc::@17]
  __b8:
    // [881] phi flash_smc::y#23 = flash_smc::y#33 [phi:flash_smc::@15->flash_smc::@17#0] -- register_copy 
    // [881] phi flash_smc::smc_attempts_total#17 = flash_smc::smc_attempts_total#21 [phi:flash_smc::@15->flash_smc::@17#1] -- register_copy 
    // [881] phi flash_smc::smc_row_bytes#10 = flash_smc::smc_row_bytes#14 [phi:flash_smc::@15->flash_smc::@17#2] -- register_copy 
    // [881] phi flash_smc::smc_ram_ptr#10 = flash_smc::smc_ram_ptr#13 [phi:flash_smc::@15->flash_smc::@17#3] -- register_copy 
    // [881] phi flash_smc::smc_bytes_flashed#12 = flash_smc::smc_bytes_flashed#13 [phi:flash_smc::@15->flash_smc::@17#4] -- register_copy 
    // [881] phi flash_smc::smc_attempts_flashed#19 = 0 [phi:flash_smc::@15->flash_smc::@17#5] -- vbuz1=vbuc1 
    lda #0
    sta.z smc_attempts_flashed
    // [881] phi flash_smc::smc_package_committed#2 = 0 [phi:flash_smc::@15->flash_smc::@17#6] -- vbum1=vbuc1 
    sta smc_package_committed
    // flash_smc::@17
  __b17:
    // while(!smc_package_committed && smc_attempts_flashed < 10)
    // [882] if(0!=flash_smc::smc_package_committed#2) goto flash_smc::@18 -- 0_neq_vbum1_then_la1 
    lda smc_package_committed
    bne __b18
    // flash_smc::@61
    // [883] if(flash_smc::smc_attempts_flashed#19<$a) goto flash_smc::@19 -- vbuz1_lt_vbuc1_then_la1 
    lda.z smc_attempts_flashed
    cmp #$a
    bcc __b10
    // flash_smc::@18
  __b18:
    // if(smc_attempts_flashed >= 10)
    // [884] if(flash_smc::smc_attempts_flashed#19<$a) goto flash_smc::@15 -- vbuz1_lt_vbuc1_then_la1 
    lda.z smc_attempts_flashed
    cmp #$a
    bcc __b15
    // [885] phi from flash_smc::@18 to flash_smc::@26 [phi:flash_smc::@18->flash_smc::@26]
    // flash_smc::@26
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [886] call snprintf_init
    jsr snprintf_init
    // [887] phi from flash_smc::@26 to flash_smc::@58 [phi:flash_smc::@26->flash_smc::@58]
    // flash_smc::@58
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [888] call printf_str
    // [623] phi from flash_smc::@58 to printf_str [phi:flash_smc::@58->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:flash_smc::@58->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = flash_smc::s10 [phi:flash_smc::@58->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@59
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [889] printf_uint::uvalue#9 = flash_smc::smc_bytes_flashed#12 -- vwuz1=vwum2 
    lda smc_bytes_flashed
    sta.z printf_uint.uvalue
    lda smc_bytes_flashed+1
    sta.z printf_uint.uvalue+1
    // [890] call printf_uint
    // [632] phi from flash_smc::@59 to printf_uint [phi:flash_smc::@59->printf_uint]
    // [632] phi printf_uint::format_zero_padding#16 = 1 [phi:flash_smc::@59->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [632] phi printf_uint::format_min_length#16 = 4 [phi:flash_smc::@59->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [632] phi printf_uint::putc#16 = &snputc [phi:flash_smc::@59->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [632] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:flash_smc::@59->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [632] phi printf_uint::uvalue#16 = printf_uint::uvalue#9 [phi:flash_smc::@59->printf_uint#4] -- register_copy 
    jsr printf_uint
    // flash_smc::@60
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [891] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [892] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [894] call info_line
    // [811] phi from flash_smc::@60 to info_line [phi:flash_smc::@60->info_line]
    // [811] phi info_line::info_text#17 = info_text [phi:flash_smc::@60->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    rts
    // [895] phi from flash_smc::@61 to flash_smc::@19 [phi:flash_smc::@61->flash_smc::@19]
  __b10:
    // [895] phi flash_smc::smc_bytes_checksum#2 = 0 [phi:flash_smc::@61->flash_smc::@19#0] -- vbum1=vbuc1 
    lda #0
    sta smc_bytes_checksum
    // [895] phi flash_smc::smc_ram_ptr#12 = flash_smc::smc_ram_ptr#10 [phi:flash_smc::@61->flash_smc::@19#1] -- register_copy 
    // [895] phi flash_smc::smc_package_flashed#2 = 0 [phi:flash_smc::@61->flash_smc::@19#2] -- vwuz1=vwuc1 
    sta.z smc_package_flashed
    sta.z smc_package_flashed+1
    // flash_smc::@19
  __b19:
    // while(smc_package_flashed < 8)
    // [896] if(flash_smc::smc_package_flashed#2<8) goto flash_smc::@20 -- vwuz1_lt_vbuc1_then_la1 
    lda.z smc_package_flashed+1
    bne !+
    lda.z smc_package_flashed
    cmp #8
    bcs !__b20+
    jmp __b20
  !__b20:
  !:
    // flash_smc::@21
    // smc_bytes_checksum ^ 0xFF
    // [897] flash_smc::$25 = flash_smc::smc_bytes_checksum#2 ^ $ff -- vbum1=vbum1_bxor_vbuc1 
    lda #$ff
    eor flash_smc__25
    sta flash_smc__25
    // (smc_bytes_checksum ^ 0xFF)+1
    // [898] flash_smc::$26 = flash_smc::$25 + 1 -- vbum1=vbum1_plus_1 
    inc flash_smc__26
    // unsigned char smc_checksum_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, (smc_bytes_checksum ^ 0xFF)+1)
    // [899] flash_smc::cx16_k_i2c_write_byte5_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte5_device
    // [900] flash_smc::cx16_k_i2c_write_byte5_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte5_offset
    // [901] flash_smc::cx16_k_i2c_write_byte5_value = flash_smc::$26 -- vbum1=vbum2 
    lda flash_smc__26
    sta cx16_k_i2c_write_byte5_value
    // flash_smc::cx16_k_i2c_write_byte5
    // unsigned char result
    // [902] flash_smc::cx16_k_i2c_write_byte5_result = 0 -- vbum1=vbuc1 
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
    // flash_smc::@29
    // unsigned int smc_commit_result = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_COMMIT)
    // [904] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [905] cx16_k_i2c_read_byte::offset = $81 -- vbum1=vbuc1 
    lda #$81
    sta cx16_k_i2c_read_byte.offset
    // [906] call cx16_k_i2c_read_byte
    // Now send the commit command.
    jsr cx16_k_i2c_read_byte
    // [907] cx16_k_i2c_read_byte::return#4 = cx16_k_i2c_read_byte::return#1
    // flash_smc::@49
    // [908] flash_smc::smc_commit_result#0 = cx16_k_i2c_read_byte::return#4
    // if(smc_commit_result == 1)
    // [909] if(flash_smc::smc_commit_result#0==1) goto flash_smc::@23 -- vwuz1_eq_vbuc1_then_la1 
    lda.z smc_commit_result+1
    bne !+
    lda.z smc_commit_result
    cmp #1
    beq __b23
  !:
    // flash_smc::@22
    // smc_ram_ptr -= 8
    // [910] flash_smc::smc_ram_ptr#1 = flash_smc::smc_ram_ptr#12 - 8 -- pbuz1=pbuz1_minus_vbuc1 
    sec
    lda.z smc_ram_ptr
    sbc #8
    sta.z smc_ram_ptr
    lda.z smc_ram_ptr+1
    sbc #0
    sta.z smc_ram_ptr+1
    // smc_attempts_flashed++;
    // [911] flash_smc::smc_attempts_flashed#1 = ++ flash_smc::smc_attempts_flashed#19 -- vbuz1=_inc_vbuz1 
    inc.z smc_attempts_flashed
    // [881] phi from flash_smc::@22 to flash_smc::@17 [phi:flash_smc::@22->flash_smc::@17]
    // [881] phi flash_smc::y#23 = flash_smc::y#23 [phi:flash_smc::@22->flash_smc::@17#0] -- register_copy 
    // [881] phi flash_smc::smc_attempts_total#17 = flash_smc::smc_attempts_total#17 [phi:flash_smc::@22->flash_smc::@17#1] -- register_copy 
    // [881] phi flash_smc::smc_row_bytes#10 = flash_smc::smc_row_bytes#10 [phi:flash_smc::@22->flash_smc::@17#2] -- register_copy 
    // [881] phi flash_smc::smc_ram_ptr#10 = flash_smc::smc_ram_ptr#1 [phi:flash_smc::@22->flash_smc::@17#3] -- register_copy 
    // [881] phi flash_smc::smc_bytes_flashed#12 = flash_smc::smc_bytes_flashed#12 [phi:flash_smc::@22->flash_smc::@17#4] -- register_copy 
    // [881] phi flash_smc::smc_attempts_flashed#19 = flash_smc::smc_attempts_flashed#1 [phi:flash_smc::@22->flash_smc::@17#5] -- register_copy 
    // [881] phi flash_smc::smc_package_committed#2 = flash_smc::smc_package_committed#2 [phi:flash_smc::@22->flash_smc::@17#6] -- register_copy 
    jmp __b17
    // flash_smc::@23
  __b23:
    // if (smc_row_bytes == smc_row_total)
    // [912] if(flash_smc::smc_row_bytes#10!=flash_smc::smc_row_total#0) goto flash_smc::@24 -- vwuz1_neq_vwuc1_then_la1 
    lda.z smc_row_bytes+1
    cmp #>smc_row_total
    bne __b24
    lda.z smc_row_bytes
    cmp #<smc_row_total
    bne __b24
    // flash_smc::@25
    // gotoxy(x, ++y);
    // [913] flash_smc::y#0 = ++ flash_smc::y#23 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [914] gotoxy::y#21 = flash_smc::y#0 -- vbuz1=vbum2 
    lda y
    sta.z gotoxy.y
    // [915] call gotoxy
    // [479] phi from flash_smc::@25 to gotoxy [phi:flash_smc::@25->gotoxy]
    // [479] phi gotoxy::y#29 = gotoxy::y#21 [phi:flash_smc::@25->gotoxy#0] -- register_copy 
    // [479] phi gotoxy::x#29 = PROGRESS_X [phi:flash_smc::@25->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [916] phi from flash_smc::@25 to flash_smc::@24 [phi:flash_smc::@25->flash_smc::@24]
    // [916] phi flash_smc::y#35 = flash_smc::y#0 [phi:flash_smc::@25->flash_smc::@24#0] -- register_copy 
    // [916] phi flash_smc::smc_row_bytes#4 = 0 [phi:flash_smc::@25->flash_smc::@24#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z smc_row_bytes
    sta.z smc_row_bytes+1
    // [916] phi from flash_smc::@23 to flash_smc::@24 [phi:flash_smc::@23->flash_smc::@24]
    // [916] phi flash_smc::y#35 = flash_smc::y#23 [phi:flash_smc::@23->flash_smc::@24#0] -- register_copy 
    // [916] phi flash_smc::smc_row_bytes#4 = flash_smc::smc_row_bytes#10 [phi:flash_smc::@23->flash_smc::@24#1] -- register_copy 
    // flash_smc::@24
  __b24:
    // cputc('*')
    // [917] stackpush(char) = '*' -- _stackpushbyte_=vbuc1 
    lda #'*'
    pha
    // [918] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_bytes_flashed += 8
    // [920] flash_smc::smc_bytes_flashed#1 = flash_smc::smc_bytes_flashed#12 + 8 -- vwum1=vwum1_plus_vbuc1 
    lda #8
    clc
    adc smc_bytes_flashed
    sta smc_bytes_flashed
    bcc !+
    inc smc_bytes_flashed+1
  !:
    // smc_row_bytes += 8
    // [921] flash_smc::smc_row_bytes#1 = flash_smc::smc_row_bytes#4 + 8 -- vwuz1=vwuz1_plus_vbuc1 
    lda #8
    clc
    adc.z smc_row_bytes
    sta.z smc_row_bytes
    bcc !+
    inc.z smc_row_bytes+1
  !:
    // smc_attempts_total += smc_attempts_flashed
    // [922] flash_smc::smc_attempts_total#1 = flash_smc::smc_attempts_total#17 + flash_smc::smc_attempts_flashed#19 -- vwum1=vwum1_plus_vbuz2 
    lda.z smc_attempts_flashed
    clc
    adc smc_attempts_total
    sta smc_attempts_total
    bcc !+
    inc smc_attempts_total+1
  !:
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [923] call snprintf_init
    jsr snprintf_init
    // [924] phi from flash_smc::@24 to flash_smc::@50 [phi:flash_smc::@24->flash_smc::@50]
    // flash_smc::@50
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [925] call printf_str
    // [623] phi from flash_smc::@50 to printf_str [phi:flash_smc::@50->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:flash_smc::@50->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = flash_smc::s6 [phi:flash_smc::@50->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@51
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [926] printf_uint::uvalue#6 = flash_smc::smc_bytes_flashed#1 -- vwuz1=vwum2 
    lda smc_bytes_flashed
    sta.z printf_uint.uvalue
    lda smc_bytes_flashed+1
    sta.z printf_uint.uvalue+1
    // [927] call printf_uint
    // [632] phi from flash_smc::@51 to printf_uint [phi:flash_smc::@51->printf_uint]
    // [632] phi printf_uint::format_zero_padding#16 = 1 [phi:flash_smc::@51->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [632] phi printf_uint::format_min_length#16 = 5 [phi:flash_smc::@51->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [632] phi printf_uint::putc#16 = &snputc [phi:flash_smc::@51->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [632] phi printf_uint::format_radix#16 = DECIMAL [phi:flash_smc::@51->printf_uint#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [632] phi printf_uint::uvalue#16 = printf_uint::uvalue#6 [phi:flash_smc::@51->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [928] phi from flash_smc::@51 to flash_smc::@52 [phi:flash_smc::@51->flash_smc::@52]
    // flash_smc::@52
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [929] call printf_str
    // [623] phi from flash_smc::@52 to printf_str [phi:flash_smc::@52->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:flash_smc::@52->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = flash_smc::s7 [phi:flash_smc::@52->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@53
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [930] printf_uint::uvalue#7 = flash_smc::smc_bytes_total#0 -- vwuz1=vwuz2 
    lda.z smc_bytes_total
    sta.z printf_uint.uvalue
    lda.z smc_bytes_total+1
    sta.z printf_uint.uvalue+1
    // [931] call printf_uint
    // [632] phi from flash_smc::@53 to printf_uint [phi:flash_smc::@53->printf_uint]
    // [632] phi printf_uint::format_zero_padding#16 = 1 [phi:flash_smc::@53->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [632] phi printf_uint::format_min_length#16 = 5 [phi:flash_smc::@53->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [632] phi printf_uint::putc#16 = &snputc [phi:flash_smc::@53->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [632] phi printf_uint::format_radix#16 = DECIMAL [phi:flash_smc::@53->printf_uint#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [632] phi printf_uint::uvalue#16 = printf_uint::uvalue#7 [phi:flash_smc::@53->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [932] phi from flash_smc::@53 to flash_smc::@54 [phi:flash_smc::@53->flash_smc::@54]
    // flash_smc::@54
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [933] call printf_str
    // [623] phi from flash_smc::@54 to printf_str [phi:flash_smc::@54->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:flash_smc::@54->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = flash_smc::s8 [phi:flash_smc::@54->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@55
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [934] printf_uint::uvalue#8 = flash_smc::smc_attempts_total#1 -- vwuz1=vwum2 
    lda smc_attempts_total
    sta.z printf_uint.uvalue
    lda smc_attempts_total+1
    sta.z printf_uint.uvalue+1
    // [935] call printf_uint
    // [632] phi from flash_smc::@55 to printf_uint [phi:flash_smc::@55->printf_uint]
    // [632] phi printf_uint::format_zero_padding#16 = 1 [phi:flash_smc::@55->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [632] phi printf_uint::format_min_length#16 = 2 [phi:flash_smc::@55->printf_uint#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uint.format_min_length
    // [632] phi printf_uint::putc#16 = &snputc [phi:flash_smc::@55->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [632] phi printf_uint::format_radix#16 = DECIMAL [phi:flash_smc::@55->printf_uint#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [632] phi printf_uint::uvalue#16 = printf_uint::uvalue#8 [phi:flash_smc::@55->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [936] phi from flash_smc::@55 to flash_smc::@56 [phi:flash_smc::@55->flash_smc::@56]
    // flash_smc::@56
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [937] call printf_str
    // [623] phi from flash_smc::@56 to printf_str [phi:flash_smc::@56->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:flash_smc::@56->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = flash_smc::s9 [phi:flash_smc::@56->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@57
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [938] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [939] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [941] call info_line
    // [811] phi from flash_smc::@57 to info_line [phi:flash_smc::@57->info_line]
    // [811] phi info_line::info_text#17 = info_text [phi:flash_smc::@57->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    // [881] phi from flash_smc::@57 to flash_smc::@17 [phi:flash_smc::@57->flash_smc::@17]
    // [881] phi flash_smc::y#23 = flash_smc::y#35 [phi:flash_smc::@57->flash_smc::@17#0] -- register_copy 
    // [881] phi flash_smc::smc_attempts_total#17 = flash_smc::smc_attempts_total#1 [phi:flash_smc::@57->flash_smc::@17#1] -- register_copy 
    // [881] phi flash_smc::smc_row_bytes#10 = flash_smc::smc_row_bytes#1 [phi:flash_smc::@57->flash_smc::@17#2] -- register_copy 
    // [881] phi flash_smc::smc_ram_ptr#10 = flash_smc::smc_ram_ptr#12 [phi:flash_smc::@57->flash_smc::@17#3] -- register_copy 
    // [881] phi flash_smc::smc_bytes_flashed#12 = flash_smc::smc_bytes_flashed#1 [phi:flash_smc::@57->flash_smc::@17#4] -- register_copy 
    // [881] phi flash_smc::smc_attempts_flashed#19 = flash_smc::smc_attempts_flashed#19 [phi:flash_smc::@57->flash_smc::@17#5] -- register_copy 
    // [881] phi flash_smc::smc_package_committed#2 = 1 [phi:flash_smc::@57->flash_smc::@17#6] -- vbum1=vbuc1 
    lda #1
    sta smc_package_committed
    jmp __b17
    // flash_smc::@20
  __b20:
    // unsigned char smc_byte_upload = *smc_ram_ptr
    // [942] flash_smc::smc_byte_upload#0 = *flash_smc::smc_ram_ptr#12 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (smc_ram_ptr),y
    sta.z smc_byte_upload
    // smc_ram_ptr++;
    // [943] flash_smc::smc_ram_ptr#0 = ++ flash_smc::smc_ram_ptr#12 -- pbuz1=_inc_pbuz1 
    inc.z smc_ram_ptr
    bne !+
    inc.z smc_ram_ptr+1
  !:
    // smc_bytes_checksum += smc_byte_upload
    // [944] flash_smc::smc_bytes_checksum#1 = flash_smc::smc_bytes_checksum#2 + flash_smc::smc_byte_upload#0 -- vbum1=vbum1_plus_vbuz2 
    lda smc_bytes_checksum
    clc
    adc.z smc_byte_upload
    sta smc_bytes_checksum
    // unsigned char smc_upload_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, smc_byte_upload)
    // [945] flash_smc::cx16_k_i2c_write_byte4_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte4_device
    // [946] flash_smc::cx16_k_i2c_write_byte4_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte4_offset
    // [947] flash_smc::cx16_k_i2c_write_byte4_value = flash_smc::smc_byte_upload#0 -- vbum1=vbuz2 
    lda.z smc_byte_upload
    sta cx16_k_i2c_write_byte4_value
    // flash_smc::cx16_k_i2c_write_byte4
    // unsigned char result
    // [948] flash_smc::cx16_k_i2c_write_byte4_result = 0 -- vbum1=vbuc1 
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
    // flash_smc::@28
    // smc_package_flashed++;
    // [950] flash_smc::smc_package_flashed#1 = ++ flash_smc::smc_package_flashed#2 -- vwuz1=_inc_vwuz1 
    inc.z smc_package_flashed
    bne !+
    inc.z smc_package_flashed+1
  !:
    // [895] phi from flash_smc::@28 to flash_smc::@19 [phi:flash_smc::@28->flash_smc::@19]
    // [895] phi flash_smc::smc_bytes_checksum#2 = flash_smc::smc_bytes_checksum#1 [phi:flash_smc::@28->flash_smc::@19#0] -- register_copy 
    // [895] phi flash_smc::smc_ram_ptr#12 = flash_smc::smc_ram_ptr#0 [phi:flash_smc::@28->flash_smc::@19#1] -- register_copy 
    // [895] phi flash_smc::smc_package_flashed#2 = flash_smc::smc_package_flashed#1 [phi:flash_smc::@28->flash_smc::@19#2] -- register_copy 
    jmp __b19
    // [951] phi from flash_smc::@9 to flash_smc::@11 [phi:flash_smc::@9->flash_smc::@11]
  __b13:
    // [951] phi flash_smc::x2#2 = $10000*1 [phi:flash_smc::@9->flash_smc::@11#0] -- vduz1=vduc1 
    lda #<$10000*1
    sta.z x2
    lda #>$10000*1
    sta.z x2+1
    lda #<$10000*1>>$10
    sta.z x2+2
    lda #>$10000*1>>$10
    sta.z x2+3
    // flash_smc::@11
  __b11:
    // for(unsigned long x=65536*1; x>0; x--)
    // [952] if(flash_smc::x2#2>0) goto flash_smc::@12 -- vduz1_gt_0_then_la1 
    lda.z x2+3
    bne __b12
    lda.z x2+2
    bne __b12
    lda.z x2+1
    bne __b12
    lda.z x2
    bne __b12
  !:
    // [953] phi from flash_smc::@11 to flash_smc::@13 [phi:flash_smc::@11->flash_smc::@13]
    // flash_smc::@13
    // sprintf(info_text, "Waiting an other %u seconds before flashing the SMC!", smc_bootloader_activation_countdown)
    // [954] call snprintf_init
    jsr snprintf_init
    // [955] phi from flash_smc::@13 to flash_smc::@40 [phi:flash_smc::@13->flash_smc::@40]
    // flash_smc::@40
    // sprintf(info_text, "Waiting an other %u seconds before flashing the SMC!", smc_bootloader_activation_countdown)
    // [956] call printf_str
    // [623] phi from flash_smc::@40 to printf_str [phi:flash_smc::@40->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:flash_smc::@40->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = flash_smc::s3 [phi:flash_smc::@40->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@41
    // sprintf(info_text, "Waiting an other %u seconds before flashing the SMC!", smc_bootloader_activation_countdown)
    // [957] printf_uchar::uvalue#3 = flash_smc::smc_bootloader_activation_countdown#23 -- vbuz1=vbum2 
    lda smc_bootloader_activation_countdown_1
    sta.z printf_uchar.uvalue
    // [958] call printf_uchar
    // [1018] phi from flash_smc::@41 to printf_uchar [phi:flash_smc::@41->printf_uchar]
    // [1018] phi printf_uchar::format_zero_padding#10 = 0 [phi:flash_smc::@41->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1018] phi printf_uchar::format_min_length#10 = 0 [phi:flash_smc::@41->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1018] phi printf_uchar::putc#10 = &snputc [phi:flash_smc::@41->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1018] phi printf_uchar::format_radix#10 = DECIMAL [phi:flash_smc::@41->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1018] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#3 [phi:flash_smc::@41->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [959] phi from flash_smc::@41 to flash_smc::@42 [phi:flash_smc::@41->flash_smc::@42]
    // flash_smc::@42
    // sprintf(info_text, "Waiting an other %u seconds before flashing the SMC!", smc_bootloader_activation_countdown)
    // [960] call printf_str
    // [623] phi from flash_smc::@42 to printf_str [phi:flash_smc::@42->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:flash_smc::@42->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = flash_smc::s4 [phi:flash_smc::@42->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@43
    // sprintf(info_text, "Waiting an other %u seconds before flashing the SMC!", smc_bootloader_activation_countdown)
    // [961] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [962] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [964] call info_line
    // [811] phi from flash_smc::@43 to info_line [phi:flash_smc::@43->info_line]
    // [811] phi info_line::info_text#17 = info_text [phi:flash_smc::@43->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    // flash_smc::@44
    // smc_bootloader_activation_countdown--;
    // [965] flash_smc::smc_bootloader_activation_countdown#3 = -- flash_smc::smc_bootloader_activation_countdown#23 -- vbum1=_dec_vbum1 
    dec smc_bootloader_activation_countdown_1
    // [852] phi from flash_smc::@44 to flash_smc::@9 [phi:flash_smc::@44->flash_smc::@9]
    // [852] phi flash_smc::smc_bootloader_activation_countdown#23 = flash_smc::smc_bootloader_activation_countdown#3 [phi:flash_smc::@44->flash_smc::@9#0] -- register_copy 
    jmp __b9
    // flash_smc::@12
  __b12:
    // for(unsigned long x=65536*1; x>0; x--)
    // [966] flash_smc::x2#1 = -- flash_smc::x2#2 -- vduz1=_dec_vduz1 
    lda.z x2
    sec
    sbc #1
    sta.z x2
    lda.z x2+1
    sbc #0
    sta.z x2+1
    lda.z x2+2
    sbc #0
    sta.z x2+2
    lda.z x2+3
    sbc #0
    sta.z x2+3
    // [951] phi from flash_smc::@12 to flash_smc::@11 [phi:flash_smc::@12->flash_smc::@11]
    // [951] phi flash_smc::x2#2 = flash_smc::x2#1 [phi:flash_smc::@12->flash_smc::@11#0] -- register_copy 
    jmp __b11
    // flash_smc::@4
  __b4:
    // unsigned int smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [967] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [968] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [969] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [970] cx16_k_i2c_read_byte::return#2 = cx16_k_i2c_read_byte::return#1
    // flash_smc::@34
    // [971] flash_smc::smc_bootloader_not_activated1#0 = cx16_k_i2c_read_byte::return#2
    // if(smc_bootloader_not_activated)
    // [972] if(0!=flash_smc::smc_bootloader_not_activated1#0) goto flash_smc::@6 -- 0_neq_vwuz1_then_la1 
    lda.z smc_bootloader_not_activated1
    ora.z smc_bootloader_not_activated1+1
    bne __b14
    jmp __b5
    // [973] phi from flash_smc::@34 to flash_smc::@6 [phi:flash_smc::@34->flash_smc::@6]
  __b14:
    // [973] phi flash_smc::x1#2 = $10000*6 [phi:flash_smc::@34->flash_smc::@6#0] -- vduz1=vduc1 
    lda #<$10000*6
    sta.z x1
    lda #>$10000*6
    sta.z x1+1
    lda #<$10000*6>>$10
    sta.z x1+2
    lda #>$10000*6>>$10
    sta.z x1+3
    // flash_smc::@6
  __b6:
    // for(unsigned long x=65536*6; x>0; x--)
    // [974] if(flash_smc::x1#2>0) goto flash_smc::@7 -- vduz1_gt_0_then_la1 
    lda.z x1+3
    bne __b7
    lda.z x1+2
    bne __b7
    lda.z x1+1
    bne __b7
    lda.z x1
    bne __b7
  !:
    // [975] phi from flash_smc::@6 to flash_smc::@8 [phi:flash_smc::@6->flash_smc::@8]
    // flash_smc::@8
    // sprintf(info_text, "Press POWER and RESET on the CX16 within %u seconds!", smc_bootloader_activation_countdown)
    // [976] call snprintf_init
    jsr snprintf_init
    // [977] phi from flash_smc::@8 to flash_smc::@35 [phi:flash_smc::@8->flash_smc::@35]
    // flash_smc::@35
    // sprintf(info_text, "Press POWER and RESET on the CX16 within %u seconds!", smc_bootloader_activation_countdown)
    // [978] call printf_str
    // [623] phi from flash_smc::@35 to printf_str [phi:flash_smc::@35->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:flash_smc::@35->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = flash_smc::s1 [phi:flash_smc::@35->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@36
    // sprintf(info_text, "Press POWER and RESET on the CX16 within %u seconds!", smc_bootloader_activation_countdown)
    // [979] printf_uchar::uvalue#2 = flash_smc::smc_bootloader_activation_countdown#22 -- vbuz1=vbum2 
    lda smc_bootloader_activation_countdown
    sta.z printf_uchar.uvalue
    // [980] call printf_uchar
    // [1018] phi from flash_smc::@36 to printf_uchar [phi:flash_smc::@36->printf_uchar]
    // [1018] phi printf_uchar::format_zero_padding#10 = 0 [phi:flash_smc::@36->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1018] phi printf_uchar::format_min_length#10 = 0 [phi:flash_smc::@36->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1018] phi printf_uchar::putc#10 = &snputc [phi:flash_smc::@36->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1018] phi printf_uchar::format_radix#10 = DECIMAL [phi:flash_smc::@36->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1018] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#2 [phi:flash_smc::@36->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [981] phi from flash_smc::@36 to flash_smc::@37 [phi:flash_smc::@36->flash_smc::@37]
    // flash_smc::@37
    // sprintf(info_text, "Press POWER and RESET on the CX16 within %u seconds!", smc_bootloader_activation_countdown)
    // [982] call printf_str
    // [623] phi from flash_smc::@37 to printf_str [phi:flash_smc::@37->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:flash_smc::@37->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = flash_smc::s2 [phi:flash_smc::@37->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@38
    // sprintf(info_text, "Press POWER and RESET on the CX16 within %u seconds!", smc_bootloader_activation_countdown)
    // [983] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [984] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [986] call info_line
    // [811] phi from flash_smc::@38 to info_line [phi:flash_smc::@38->info_line]
    // [811] phi info_line::info_text#17 = info_text [phi:flash_smc::@38->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    // flash_smc::@5
    // smc_bootloader_activation_countdown--;
    // [987] flash_smc::smc_bootloader_activation_countdown#2 = -- flash_smc::smc_bootloader_activation_countdown#22 -- vbum1=_dec_vbum1 
    dec smc_bootloader_activation_countdown
    // [850] phi from flash_smc::@5 to flash_smc::@3 [phi:flash_smc::@5->flash_smc::@3]
    // [850] phi flash_smc::smc_bootloader_activation_countdown#22 = flash_smc::smc_bootloader_activation_countdown#2 [phi:flash_smc::@5->flash_smc::@3#0] -- register_copy 
    jmp __b3
    // flash_smc::@7
  __b7:
    // for(unsigned long x=65536*6; x>0; x--)
    // [988] flash_smc::x1#1 = -- flash_smc::x1#2 -- vduz1=_dec_vduz1 
    lda.z x1
    sec
    sbc #1
    sta.z x1
    lda.z x1+1
    sbc #0
    sta.z x1+1
    lda.z x1+2
    sbc #0
    sta.z x1+2
    lda.z x1+3
    sbc #0
    sta.z x1+3
    // [973] phi from flash_smc::@7 to flash_smc::@6 [phi:flash_smc::@7->flash_smc::@6]
    // [973] phi flash_smc::x1#2 = flash_smc::x1#1 [phi:flash_smc::@7->flash_smc::@6#0] -- register_copy 
    jmp __b6
  .segment Data
    s: .text "There was a problem starting the SMC bootloader: "
    .byte 0
    s1: .text "Press POWER and RESET on the CX16 within "
    .byte 0
    s2: .text " seconds!"
    .byte 0
    s3: .text "Waiting an other "
    .byte 0
    s4: .text " seconds before flashing the SMC!"
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
    .label flash_smc__25 = main.check_cx16_rom2_check_rom1_main__0
    .label flash_smc__26 = main.check_cx16_rom2_check_rom1_main__0
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
    // Wait an other 5 seconds to ensure the bootloader is activated.
    .label smc_bootloader_activation_countdown = strchr.c
    // Wait an other 5 seconds to ensure the bootloader is activated.
    .label smc_bootloader_activation_countdown_1 = main.check_vera2_main__0
    .label smc_bytes_checksum = main.check_cx16_rom2_check_rom1_main__0
    .label smc_bytes_flashed = fopen.pathtoken_1
    .label smc_attempts_total = fgets.stream
    .label y = main.check_roms2_check_rom1_main__0
    .label smc_package_committed = main.check_smc3_main__0
}
.segment Code
  // wait_key
// __mem() char wait_key(__zp($4a) char *info_text, __zp($61) char *filter)
wait_key: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    .label wait_key__9 = $2a
    .label bram = $df
    .label bank_get_brom1_return = $b2
    .label info_text = $4a
    .label filter = $61
    // info_line(info_text)
    // [990] info_line::info_text#0 = wait_key::info_text#4
    // [991] call info_line
    // [811] phi from wait_key to info_line [phi:wait_key->info_line]
    // [811] phi info_line::info_text#17 = info_line::info_text#0 [phi:wait_key->info_line#0] -- register_copy 
    jsr info_line
    // wait_key::bank_get_bram1
    // return BRAM;
    // [992] wait_key::bram#0 = BRAM -- vbuz1=vbuz2 
    lda.z BRAM
    sta.z bram
    // wait_key::bank_get_brom1
    // return BROM;
    // [993] wait_key::bank_get_brom1_return#0 = BROM -- vbuz1=vbuz2 
    lda.z BROM
    sta.z bank_get_brom1_return
    // wait_key::bank_set_bram1
    // BRAM = bank
    // [994] BRAM = wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // wait_key::bank_set_brom1
    // BROM = bank
    // [995] BROM = wait_key::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [996] phi from wait_key::@2 wait_key::@5 wait_key::bank_set_brom1 to wait_key::kbhit1 [phi:wait_key::@2/wait_key::@5/wait_key::bank_set_brom1->wait_key::kbhit1]
    // wait_key::kbhit1
  kbhit1:
    // wait_key::kbhit1_cbm_k_clrchn1
    // asm
    // asm { jsrCBM_CLRCHN  }
    jsr CBM_CLRCHN
    // [998] phi from wait_key::kbhit1_cbm_k_clrchn1 to wait_key::kbhit1_@2 [phi:wait_key::kbhit1_cbm_k_clrchn1->wait_key::kbhit1_@2]
    // wait_key::kbhit1_@2
    // cbm_k_getin()
    // [999] call cbm_k_getin
    jsr cbm_k_getin
    // [1000] cbm_k_getin::return#2 = cbm_k_getin::return#1
    // wait_key::@4
    // [1001] wait_key::ch#4 = cbm_k_getin::return#2 -- vwum1=vbuz2 
    lda.z cbm_k_getin.return
    sta ch
    lda #0
    sta ch+1
    // wait_key::@3
    // if (filter)
    // [1002] if((char *)0!=wait_key::filter#14) goto wait_key::@1 -- pbuc1_neq_pbuz1_then_la1 
    // if there is a filter, check the filter, otherwise return ch.
    lda.z filter+1
    cmp #>0
    bne __b1
    lda.z filter
    cmp #<0
    bne __b1
    // wait_key::@2
    // if(ch)
    // [1003] if(0!=wait_key::ch#4) goto wait_key::bank_set_bram2 -- 0_neq_vwum1_then_la1 
    lda ch
    ora ch+1
    bne bank_set_bram2
    jmp kbhit1
    // wait_key::bank_set_bram2
  bank_set_bram2:
    // BRAM = bank
    // [1004] BRAM = wait_key::bram#0 -- vbuz1=vbuz2 
    lda.z bram
    sta.z BRAM
    // wait_key::bank_set_brom2
    // BROM = bank
    // [1005] BROM = wait_key::bank_get_brom1_return#0 -- vbuz1=vbuz2 
    lda.z bank_get_brom1_return
    sta.z BROM
    // wait_key::@return
    // }
    // [1006] return 
    rts
    // wait_key::@1
  __b1:
    // strchr(filter, ch)
    // [1007] strchr::str#0 = (const void *)wait_key::filter#14 -- pvoz1=pvoz2 
    lda.z filter
    sta.z strchr.str
    lda.z filter+1
    sta.z strchr.str+1
    // [1008] strchr::c#0 = wait_key::ch#4 -- vbum1=vwum2 
    lda ch
    sta strchr.c
    // [1009] call strchr
    // [1371] phi from wait_key::@1 to strchr [phi:wait_key::@1->strchr]
    // [1371] phi strchr::c#4 = strchr::c#0 [phi:wait_key::@1->strchr#0] -- register_copy 
    // [1371] phi strchr::str#2 = strchr::str#0 [phi:wait_key::@1->strchr#1] -- register_copy 
    jsr strchr
    // strchr(filter, ch)
    // [1010] strchr::return#3 = strchr::return#2
    // wait_key::@5
    // [1011] wait_key::$9 = strchr::return#3
    // if(strchr(filter, ch) != NULL)
    // [1012] if(wait_key::$9!=0) goto wait_key::bank_set_bram2 -- pvoz1_neq_0_then_la1 
    lda.z wait_key__9
    ora.z wait_key__9+1
    bne bank_set_bram2
    jmp kbhit1
  .segment Data
    .label return = strchr.c
    .label ch = rom_read.fp
}
.segment Code
  // system_reset
system_reset: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    // system_reset::bank_set_bram1
    // BRAM = bank
    // [1014] BRAM = system_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // system_reset::bank_set_brom1
    // BROM = bank
    // [1015] BROM = system_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // system_reset::@1
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // system_reset::@return
    // }
    // [1017] return 
}
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(__zp($4a) void (*putc)(char), __zp($25) char uvalue, __zp($de) char format_min_length, char format_justify_left, char format_sign_always, __zp($dd) char format_zero_padding, char format_upper_case, __zp($dc) char format_radix)
printf_uchar: {
    .label uvalue = $25
    .label format_radix = $dc
    .label putc = $4a
    .label format_min_length = $de
    .label format_zero_padding = $dd
    // printf_uchar::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1019] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [1020] uctoa::value#1 = printf_uchar::uvalue#10
    // [1021] uctoa::radix#0 = printf_uchar::format_radix#10
    // [1022] call uctoa
    // Format number into buffer
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1023] printf_number_buffer::putc#2 = printf_uchar::putc#10
    // [1024] printf_number_buffer::buffer_sign#2 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [1025] printf_number_buffer::format_min_length#2 = printf_uchar::format_min_length#10
    // [1026] printf_number_buffer::format_zero_padding#2 = printf_uchar::format_zero_padding#10
    // [1027] call printf_number_buffer
  // Print using format
    // [1694] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [1694] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#2 [phi:printf_uchar::@2->printf_number_buffer#0] -- register_copy 
    // [1694] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#2 [phi:printf_uchar::@2->printf_number_buffer#1] -- register_copy 
    // [1694] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#2 [phi:printf_uchar::@2->printf_number_buffer#2] -- register_copy 
    // [1694] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#2 [phi:printf_uchar::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [1028] return 
    rts
}
  // rom_file
// char * rom_file(__mem() char rom_chip)
rom_file: {
    // strcpy(file, "ROM .BIN")
    // [1030] call strcpy
    // [1751] phi from rom_file to strcpy [phi:rom_file->strcpy]
    // [1751] phi strcpy::dst#0 = rom_file::file [phi:rom_file->strcpy#0] -- pbum1=pbuc1 
    lda #<file
    sta strcpy.dst
    lda #>file
    sta strcpy.dst+1
    // [1751] phi strcpy::src#0 = rom_file::source [phi:rom_file->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // rom_file::@1
    // 48+rom_chip
    // [1031] rom_file::$1 = $30 + rom_file::rom_chip#2 -- vbum1=vbuc1_plus_vbum1 
    lda #$30
    clc
    adc rom_file__1
    sta rom_file__1
    // file[3] = 48+rom_chip
    // [1032] *(rom_file::file+3) = rom_file::$1 -- _deref_pbuc1=vbum1 
    sta file+3
    // rom_file::@return
    // }
    // [1033] return 
    rts
  .segment Data
    file: .fill $c, 0
    source: .text "ROM .BIN"
    .byte 0
    .label rom_file__1 = main.check_vera1_main__0
    .label rom_chip = main.check_vera1_main__0
}
.segment Code
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(__zp($48) void (*putc)(char), __zp($5f) char *str, __zp($da) char format_min_length, __zp($e4) char format_justify_left)
printf_string: {
    .label printf_string__9 = $53
    .label len = $6b
    .label padding = $da
    .label str = $5f
    .label format_min_length = $da
    .label format_justify_left = $e4
    .label putc = $48
    // if(format.min_length)
    // [1035] if(0==printf_string::format_min_length#16) goto printf_string::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b3
    // printf_string::@3
    // strlen(str)
    // [1036] strlen::str#3 = printf_string::str#16 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [1037] call strlen
    // [1975] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [1975] phi strlen::str#8 = strlen::str#3 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [1038] strlen::return#10 = strlen::len#2
    // printf_string::@6
    // [1039] printf_string::$9 = strlen::return#10
    // signed char len = (signed char)strlen(str)
    // [1040] printf_string::len#0 = (signed char)printf_string::$9 -- vbsz1=_sbyte_vwuz2 
    lda.z printf_string__9
    sta.z len
    // padding = (signed char)format.min_length  - len
    // [1041] printf_string::padding#1 = (signed char)printf_string::format_min_length#16 - printf_string::len#0 -- vbsz1=vbsz1_minus_vbsz2 
    lda.z padding
    sec
    sbc.z len
    sta.z padding
    // if(padding<0)
    // [1042] if(printf_string::padding#1>=0) goto printf_string::@10 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1044] phi from printf_string printf_string::@6 to printf_string::@1 [phi:printf_string/printf_string::@6->printf_string::@1]
  __b3:
    // [1044] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@6->printf_string::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [1043] phi from printf_string::@6 to printf_string::@10 [phi:printf_string::@6->printf_string::@10]
    // printf_string::@10
    // [1044] phi from printf_string::@10 to printf_string::@1 [phi:printf_string::@10->printf_string::@1]
    // [1044] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@10->printf_string::@1#0] -- register_copy 
    // printf_string::@1
  __b1:
    // if(!format.justify_left && padding)
    // [1045] if(0!=printf_string::format_justify_left#16) goto printf_string::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_justify_left
    bne __b2
    // printf_string::@8
    // [1046] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b4
    jmp __b2
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [1047] printf_padding::putc#3 = printf_string::putc#16 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1048] printf_padding::length#3 = (char)printf_string::padding#3 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1049] call printf_padding
    // [1981] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [1981] phi printf_padding::putc#7 = printf_padding::putc#3 [phi:printf_string::@4->printf_padding#0] -- register_copy 
    // [1981] phi printf_padding::pad#7 = ' ' [phi:printf_string::@4->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1981] phi printf_padding::length#6 = printf_padding::length#3 [phi:printf_string::@4->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [1050] printf_str::putc#1 = printf_string::putc#16 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_str.putc
    lda.z putc+1
    sta.z printf_str.putc+1
    // [1051] printf_str::s#2 = printf_string::str#16
    // [1052] call printf_str
    // [623] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [623] phi printf_str::putc#66 = printf_str::putc#1 [phi:printf_string::@2->printf_str#0] -- register_copy 
    // [623] phi printf_str::s#66 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@7
    // if(format.justify_left && padding)
    // [1053] if(0==printf_string::format_justify_left#16) goto printf_string::@return -- 0_eq_vbuz1_then_la1 
    lda.z format_justify_left
    beq __breturn
    // printf_string::@9
    // [1054] if(0!=printf_string::padding#3) goto printf_string::@5 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b5
    rts
    // printf_string::@5
  __b5:
    // printf_padding(putc, ' ',(char)padding)
    // [1055] printf_padding::putc#4 = printf_string::putc#16 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1056] printf_padding::length#4 = (char)printf_string::padding#3 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1057] call printf_padding
    // [1981] phi from printf_string::@5 to printf_padding [phi:printf_string::@5->printf_padding]
    // [1981] phi printf_padding::putc#7 = printf_padding::putc#4 [phi:printf_string::@5->printf_padding#0] -- register_copy 
    // [1981] phi printf_padding::pad#7 = ' ' [phi:printf_string::@5->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1981] phi printf_padding::length#6 = printf_padding::length#4 [phi:printf_string::@5->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@return
  __breturn:
    // }
    // [1058] return 
    rts
}
  // rom_read
// __mem() unsigned long rom_read(char rom_chip, char *file, __zp($e3) char brom_bank_start, __zp($ab) unsigned long rom_size)
rom_read: {
    .const bank_set_brom1_bank = 0
    .label rom_address = $71
    .label brom_bank_start = $e3
    .label ram_address = $c8
    .label rom_row_current = $7c
    .label bram_bank = $70
    .label rom_size = $ab
    // unsigned long rom_address = rom_address_from_bank(brom_bank_start)
    // [1060] rom_address_from_bank::rom_bank#0 = rom_read::brom_bank_start#21 -- vbuz1=vbuz2 
    lda.z brom_bank_start
    sta.z rom_address_from_bank.rom_bank
    // [1061] call rom_address_from_bank
    // [1989] phi from rom_read to rom_address_from_bank [phi:rom_read->rom_address_from_bank]
    // [1989] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#0 [phi:rom_read->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(brom_bank_start)
    // [1062] rom_address_from_bank::return#2 = rom_address_from_bank::return#0
    // rom_read::@15
    // [1063] rom_read::rom_address#0 = rom_address_from_bank::return#2
    // rom_read::bank_set_bram1
    // BRAM = bank
    // [1064] BRAM = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z BRAM
    // rom_read::bank_set_brom1
    // BROM = bank
    // [1065] BROM = rom_read::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [1066] phi from rom_read::bank_set_brom1 to rom_read::@13 [phi:rom_read::bank_set_brom1->rom_read::@13]
    // rom_read::@13
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1067] call snprintf_init
    jsr snprintf_init
    // [1068] phi from rom_read::@13 to rom_read::@16 [phi:rom_read::@13->rom_read::@16]
    // rom_read::@16
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1069] call printf_str
    // [623] phi from rom_read::@16 to printf_str [phi:rom_read::@16->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:rom_read::@16->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = rom_read::s [phi:rom_read::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // [1070] phi from rom_read::@16 to rom_read::@17 [phi:rom_read::@16->rom_read::@17]
    // rom_read::@17
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1071] call printf_string
    // [1034] phi from rom_read::@17 to printf_string [phi:rom_read::@17->printf_string]
    // [1034] phi printf_string::putc#16 = &snputc [phi:rom_read::@17->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1034] phi printf_string::str#16 = rom_file::file [phi:rom_read::@17->printf_string#1] -- pbuz1=pbuc1 
    lda #<rom_file.file
    sta.z printf_string.str
    lda #>rom_file.file
    sta.z printf_string.str+1
    // [1034] phi printf_string::format_justify_left#16 = 0 [phi:rom_read::@17->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1034] phi printf_string::format_min_length#16 = 0 [phi:rom_read::@17->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1072] phi from rom_read::@17 to rom_read::@18 [phi:rom_read::@17->rom_read::@18]
    // rom_read::@18
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1073] call printf_str
    // [623] phi from rom_read::@18 to printf_str [phi:rom_read::@18->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:rom_read::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = rom_read::s1 [phi:rom_read::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@19
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1074] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1075] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [1077] call info_line
    // [811] phi from rom_read::@19 to info_line [phi:rom_read::@19->info_line]
    // [811] phi info_line::info_text#17 = info_text [phi:rom_read::@19->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    // [1078] phi from rom_read::@19 to rom_read::@20 [phi:rom_read::@19->rom_read::@20]
    // rom_read::@20
    // FILE *fp = fopen(file, "r")
    // [1079] call fopen
    // [1779] phi from rom_read::@20 to fopen [phi:rom_read::@20->fopen]
    // [1779] phi __errno#295 = __errno#104 [phi:rom_read::@20->fopen#0] -- register_copy 
    // [1779] phi fopen::pathtoken#0 = rom_file::file [phi:rom_read::@20->fopen#1] -- pbuz1=pbuc1 
    lda #<rom_file.file
    sta.z fopen.pathtoken
    lda #>rom_file.file
    sta.z fopen.pathtoken+1
    jsr fopen
    // FILE *fp = fopen(file, "r")
    // [1080] fopen::return#4 = fopen::return#2
    // rom_read::@21
    // [1081] rom_read::fp#0 = fopen::return#4 -- pssm1=pssz2 
    lda.z fopen.return
    sta fp
    lda.z fopen.return+1
    sta fp+1
    // if (fp)
    // [1082] if((struct $2 *)0==rom_read::fp#0) goto rom_read::@1 -- pssc1_eq_pssm1_then_la1 
    lda fp
    cmp #<0
    bne !+
    lda fp+1
    cmp #>0
    beq __b2
  !:
    // [1083] phi from rom_read::@21 to rom_read::@2 [phi:rom_read::@21->rom_read::@2]
    // rom_read::@2
    // gotoxy(x, y)
    // [1084] call gotoxy
    // [479] phi from rom_read::@2 to gotoxy [phi:rom_read::@2->gotoxy]
    // [479] phi gotoxy::y#29 = PROGRESS_Y [phi:rom_read::@2->gotoxy#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z gotoxy.y
    // [479] phi gotoxy::x#29 = PROGRESS_X [phi:rom_read::@2->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [1085] phi from rom_read::@2 to rom_read::@3 [phi:rom_read::@2->rom_read::@3]
    // [1085] phi rom_read::y#11 = PROGRESS_Y [phi:rom_read::@2->rom_read::@3#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1085] phi rom_read::rom_row_current#10 = 0 [phi:rom_read::@2->rom_read::@3#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z rom_row_current
    sta.z rom_row_current+1
    // [1085] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#21 [phi:rom_read::@2->rom_read::@3#2] -- register_copy 
    // [1085] phi rom_read::rom_address#10 = rom_read::rom_address#0 [phi:rom_read::@2->rom_read::@3#3] -- register_copy 
    // [1085] phi rom_read::ram_address#10 = (char *)$6000 [phi:rom_read::@2->rom_read::@3#4] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z ram_address
    lda #>$6000
    sta.z ram_address+1
    // [1085] phi rom_read::bram_bank#10 = 0 [phi:rom_read::@2->rom_read::@3#5] -- vbuz1=vbuc1 
    lda #0
    sta.z bram_bank
    // [1085] phi rom_read::rom_file_read#11 = 0 [phi:rom_read::@2->rom_read::@3#6] -- vdum1=vduc1 
    sta rom_file_read
    sta rom_file_read+1
    lda #<0>>$10
    sta rom_file_read+2
    lda #>0>>$10
    sta rom_file_read+3
    // rom_read::@3
  __b3:
    // while (rom_file_read < rom_size)
    // [1086] if(rom_read::rom_file_read#11<rom_read::rom_size#12) goto rom_read::@4 -- vdum1_lt_vduz2_then_la1 
    lda rom_file_read+3
    cmp.z rom_size+3
    bcc __b4
    bne !+
    lda rom_file_read+2
    cmp.z rom_size+2
    bcc __b4
    bne !+
    lda rom_file_read+1
    cmp.z rom_size+1
    bcc __b4
    bne !+
    lda rom_file_read
    cmp.z rom_size
    bcc __b4
  !:
    // rom_read::@7
  __b7:
    // fclose(fp)
    // [1087] fclose::stream#1 = rom_read::fp#0 -- pssz1=pssm2 
    lda fp
    sta.z fclose.stream
    lda fp+1
    sta.z fclose.stream+1
    // [1088] call fclose
    // [1914] phi from rom_read::@7 to fclose [phi:rom_read::@7->fclose]
    // [1914] phi fclose::stream#2 = fclose::stream#1 [phi:rom_read::@7->fclose#0] -- register_copy 
    jsr fclose
    // [1089] phi from rom_read::@7 to rom_read::@1 [phi:rom_read::@7->rom_read::@1]
    // [1089] phi rom_read::return#0 = rom_read::rom_file_read#11 [phi:rom_read::@7->rom_read::@1#0] -- register_copy 
    rts
    // [1089] phi from rom_read::@21 to rom_read::@1 [phi:rom_read::@21->rom_read::@1]
  __b2:
    // [1089] phi rom_read::return#0 = 0 [phi:rom_read::@21->rom_read::@1#0] -- vdum1=vduc1 
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
    // [1090] return 
    rts
    // [1091] phi from rom_read::@3 to rom_read::@4 [phi:rom_read::@3->rom_read::@4]
    // rom_read::@4
  __b4:
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_read, rom_size, bram_bank, ram_address)
    // [1092] call snprintf_init
    jsr snprintf_init
    // [1093] phi from rom_read::@4 to rom_read::@22 [phi:rom_read::@4->rom_read::@22]
    // rom_read::@22
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_read, rom_size, bram_bank, ram_address)
    // [1094] call printf_str
    // [623] phi from rom_read::@22 to printf_str [phi:rom_read::@22->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:rom_read::@22->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = s10 [phi:rom_read::@22->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // [1095] phi from rom_read::@22 to rom_read::@23 [phi:rom_read::@22->rom_read::@23]
    // rom_read::@23
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_read, rom_size, bram_bank, ram_address)
    // [1096] call printf_string
    // [1034] phi from rom_read::@23 to printf_string [phi:rom_read::@23->printf_string]
    // [1034] phi printf_string::putc#16 = &snputc [phi:rom_read::@23->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1034] phi printf_string::str#16 = rom_file::file [phi:rom_read::@23->printf_string#1] -- pbuz1=pbuc1 
    lda #<rom_file.file
    sta.z printf_string.str
    lda #>rom_file.file
    sta.z printf_string.str+1
    // [1034] phi printf_string::format_justify_left#16 = 0 [phi:rom_read::@23->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1034] phi printf_string::format_min_length#16 = 0 [phi:rom_read::@23->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1097] phi from rom_read::@23 to rom_read::@24 [phi:rom_read::@23->rom_read::@24]
    // rom_read::@24
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_read, rom_size, bram_bank, ram_address)
    // [1098] call printf_str
    // [623] phi from rom_read::@24 to printf_str [phi:rom_read::@24->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:rom_read::@24->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = s3 [phi:rom_read::@24->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@25
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_read, rom_size, bram_bank, ram_address)
    // [1099] printf_ulong::uvalue#2 = rom_read::rom_file_read#11 -- vduz1=vdum2 
    lda rom_file_read
    sta.z printf_ulong.uvalue
    lda rom_file_read+1
    sta.z printf_ulong.uvalue+1
    lda rom_file_read+2
    sta.z printf_ulong.uvalue+2
    lda rom_file_read+3
    sta.z printf_ulong.uvalue+3
    // [1100] call printf_ulong
    // [1245] phi from rom_read::@25 to printf_ulong [phi:rom_read::@25->printf_ulong]
    // [1245] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_read::@25->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1245] phi printf_ulong::format_min_length#11 = 5 [phi:rom_read::@25->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1245] phi printf_ulong::putc#11 = &snputc [phi:rom_read::@25->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1245] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_read::@25->printf_ulong#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1245] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#2 [phi:rom_read::@25->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1101] phi from rom_read::@25 to rom_read::@26 [phi:rom_read::@25->rom_read::@26]
    // rom_read::@26
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_read, rom_size, bram_bank, ram_address)
    // [1102] call printf_str
    // [623] phi from rom_read::@26 to printf_str [phi:rom_read::@26->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:rom_read::@26->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = s1 [phi:rom_read::@26->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s1
    sta.z printf_str.s
    lda #>@s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@27
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_read, rom_size, bram_bank, ram_address)
    // [1103] printf_ulong::uvalue#3 = rom_read::rom_size#12 -- vduz1=vduz2 
    lda.z rom_size
    sta.z printf_ulong.uvalue
    lda.z rom_size+1
    sta.z printf_ulong.uvalue+1
    lda.z rom_size+2
    sta.z printf_ulong.uvalue+2
    lda.z rom_size+3
    sta.z printf_ulong.uvalue+3
    // [1104] call printf_ulong
    // [1245] phi from rom_read::@27 to printf_ulong [phi:rom_read::@27->printf_ulong]
    // [1245] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_read::@27->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1245] phi printf_ulong::format_min_length#11 = 5 [phi:rom_read::@27->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1245] phi printf_ulong::putc#11 = &snputc [phi:rom_read::@27->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1245] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_read::@27->printf_ulong#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1245] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#3 [phi:rom_read::@27->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1105] phi from rom_read::@27 to rom_read::@28 [phi:rom_read::@27->rom_read::@28]
    // rom_read::@28
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_read, rom_size, bram_bank, ram_address)
    // [1106] call printf_str
    // [623] phi from rom_read::@28 to printf_str [phi:rom_read::@28->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:rom_read::@28->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = s2 [phi:rom_read::@28->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@29
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_read, rom_size, bram_bank, ram_address)
    // [1107] printf_uchar::uvalue#5 = rom_read::bram_bank#10 -- vbuz1=vbuz2 
    lda.z bram_bank
    sta.z printf_uchar.uvalue
    // [1108] call printf_uchar
    // [1018] phi from rom_read::@29 to printf_uchar [phi:rom_read::@29->printf_uchar]
    // [1018] phi printf_uchar::format_zero_padding#10 = 1 [phi:rom_read::@29->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1018] phi printf_uchar::format_min_length#10 = 2 [phi:rom_read::@29->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [1018] phi printf_uchar::putc#10 = &snputc [phi:rom_read::@29->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1018] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:rom_read::@29->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [1018] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#5 [phi:rom_read::@29->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1109] phi from rom_read::@29 to rom_read::@30 [phi:rom_read::@29->rom_read::@30]
    // rom_read::@30
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_read, rom_size, bram_bank, ram_address)
    // [1110] call printf_str
    // [623] phi from rom_read::@30 to printf_str [phi:rom_read::@30->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:rom_read::@30->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = s3 [phi:rom_read::@30->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@31
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_read, rom_size, bram_bank, ram_address)
    // [1111] printf_uint::uvalue#10 = (unsigned int)rom_read::ram_address#10 -- vwuz1=vwuz2 
    lda.z ram_address
    sta.z printf_uint.uvalue
    lda.z ram_address+1
    sta.z printf_uint.uvalue+1
    // [1112] call printf_uint
    // [632] phi from rom_read::@31 to printf_uint [phi:rom_read::@31->printf_uint]
    // [632] phi printf_uint::format_zero_padding#16 = 1 [phi:rom_read::@31->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [632] phi printf_uint::format_min_length#16 = 4 [phi:rom_read::@31->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [632] phi printf_uint::putc#16 = &snputc [phi:rom_read::@31->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [632] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:rom_read::@31->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [632] phi printf_uint::uvalue#16 = printf_uint::uvalue#10 [phi:rom_read::@31->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1113] phi from rom_read::@31 to rom_read::@32 [phi:rom_read::@31->rom_read::@32]
    // rom_read::@32
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_read, rom_size, bram_bank, ram_address)
    // [1114] call printf_str
    // [623] phi from rom_read::@32 to printf_str [phi:rom_read::@32->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:rom_read::@32->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = s4 [phi:rom_read::@32->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@33
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_read, rom_size, bram_bank, ram_address)
    // [1115] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1116] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [1118] call info_line
    // [811] phi from rom_read::@33 to info_line [phi:rom_read::@33->info_line]
    // [811] phi info_line::info_text#17 = info_text [phi:rom_read::@33->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    // rom_read::@34
    // rom_address % 0x04000
    // [1119] rom_read::$11 = rom_read::rom_address#10 & $4000-1 -- vdum1=vduz2_band_vduc1 
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
    // [1120] if(0!=rom_read::$11) goto rom_read::@5 -- 0_neq_vdum1_then_la1 
    lda rom_read__11
    ora rom_read__11+1
    ora rom_read__11+2
    ora rom_read__11+3
    bne __b5
    // rom_read::@10
    // brom_bank_start++;
    // [1121] rom_read::brom_bank_start#0 = ++ rom_read::brom_bank_start#10 -- vbuz1=_inc_vbuz1 
    inc.z brom_bank_start
    // [1122] phi from rom_read::@10 rom_read::@34 to rom_read::@5 [phi:rom_read::@10/rom_read::@34->rom_read::@5]
    // [1122] phi rom_read::brom_bank_start#20 = rom_read::brom_bank_start#0 [phi:rom_read::@10/rom_read::@34->rom_read::@5#0] -- register_copy 
    // rom_read::@5
  __b5:
    // rom_read::bank_set_bram2
    // BRAM = bank
    // [1123] BRAM = rom_read::bram_bank#10 -- vbuz1=vbuz2 
    lda.z bram_bank
    sta.z BRAM
    // rom_read::@14
    // unsigned int rom_package_read = fgets(ram_address, PROGRESS_CELL, fp)
    // [1124] fgets::ptr#3 = rom_read::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z fgets.ptr
    lda.z ram_address+1
    sta.z fgets.ptr+1
    // [1125] fgets::stream#1 = rom_read::fp#0 -- pssm1=pssm2 
    lda fp
    sta fgets.stream
    lda fp+1
    sta fgets.stream+1
    // [1126] call fgets
    // [1860] phi from rom_read::@14 to fgets [phi:rom_read::@14->fgets]
    // [1860] phi fgets::ptr#12 = fgets::ptr#3 [phi:rom_read::@14->fgets#0] -- register_copy 
    // [1860] phi fgets::size#10 = PROGRESS_CELL [phi:rom_read::@14->fgets#1] -- vwuz1=vwuc1 
    lda #<PROGRESS_CELL
    sta.z fgets.size
    lda #>PROGRESS_CELL
    sta.z fgets.size+1
    // [1860] phi fgets::stream#2 = fgets::stream#1 [phi:rom_read::@14->fgets#2] -- register_copy 
    jsr fgets
    // unsigned int rom_package_read = fgets(ram_address, PROGRESS_CELL, fp)
    // [1127] fgets::return#6 = fgets::return#1
    // rom_read::@35
    // [1128] rom_read::rom_package_read#0 = fgets::return#6 -- vwum1=vwuz2 
    lda.z fgets.return
    sta rom_package_read
    lda.z fgets.return+1
    sta rom_package_read+1
    // if (!rom_package_read)
    // [1129] if(0!=rom_read::rom_package_read#0) goto rom_read::@6 -- 0_neq_vwum1_then_la1 
    lda rom_package_read
    ora rom_package_read+1
    bne __b6
    jmp __b7
    // rom_read::@6
  __b6:
    // if (rom_row_current == PROGRESS_ROW)
    // [1130] if(rom_read::rom_row_current#10!=PROGRESS_ROW) goto rom_read::@8 -- vwuz1_neq_vwuc1_then_la1 
    lda.z rom_row_current+1
    cmp #>PROGRESS_ROW
    bne __b8
    lda.z rom_row_current
    cmp #<PROGRESS_ROW
    bne __b8
    // rom_read::@11
    // gotoxy(x, ++y);
    // [1131] rom_read::y#1 = ++ rom_read::y#11 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1132] gotoxy::y#24 = rom_read::y#1 -- vbuz1=vbum2 
    lda y
    sta.z gotoxy.y
    // [1133] call gotoxy
    // [479] phi from rom_read::@11 to gotoxy [phi:rom_read::@11->gotoxy]
    // [479] phi gotoxy::y#29 = gotoxy::y#24 [phi:rom_read::@11->gotoxy#0] -- register_copy 
    // [479] phi gotoxy::x#29 = PROGRESS_X [phi:rom_read::@11->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [1134] phi from rom_read::@11 to rom_read::@8 [phi:rom_read::@11->rom_read::@8]
    // [1134] phi rom_read::y#36 = rom_read::y#1 [phi:rom_read::@11->rom_read::@8#0] -- register_copy 
    // [1134] phi rom_read::rom_row_current#4 = 0 [phi:rom_read::@11->rom_read::@8#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z rom_row_current
    sta.z rom_row_current+1
    // [1134] phi from rom_read::@6 to rom_read::@8 [phi:rom_read::@6->rom_read::@8]
    // [1134] phi rom_read::y#36 = rom_read::y#11 [phi:rom_read::@6->rom_read::@8#0] -- register_copy 
    // [1134] phi rom_read::rom_row_current#4 = rom_read::rom_row_current#10 [phi:rom_read::@6->rom_read::@8#1] -- register_copy 
    // rom_read::@8
  __b8:
    // cputc('.')
    // [1135] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [1136] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // ram_address += rom_package_read
    // [1138] rom_read::ram_address#1 = rom_read::ram_address#10 + rom_read::rom_package_read#0 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z ram_address
    adc rom_package_read
    sta.z ram_address
    lda.z ram_address+1
    adc rom_package_read+1
    sta.z ram_address+1
    // rom_address += rom_package_read
    // [1139] rom_read::rom_address#1 = rom_read::rom_address#10 + rom_read::rom_package_read#0 -- vduz1=vduz1_plus_vwum2 
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
    // rom_file_read += rom_package_read
    // [1140] rom_read::rom_file_read#1 = rom_read::rom_file_read#11 + rom_read::rom_package_read#0 -- vdum1=vdum1_plus_vwum2 
    lda rom_file_read
    clc
    adc rom_package_read
    sta rom_file_read
    lda rom_file_read+1
    adc rom_package_read+1
    sta rom_file_read+1
    lda rom_file_read+2
    adc #0
    sta rom_file_read+2
    lda rom_file_read+3
    adc #0
    sta rom_file_read+3
    // rom_row_current += rom_package_read
    // [1141] rom_read::rom_row_current#1 = rom_read::rom_row_current#4 + rom_read::rom_package_read#0 -- vwuz1=vwuz1_plus_vwum2 
    clc
    lda.z rom_row_current
    adc rom_package_read
    sta.z rom_row_current
    lda.z rom_row_current+1
    adc rom_package_read+1
    sta.z rom_row_current+1
    // if (ram_address == (ram_ptr_t)BRAM_HIGH)
    // [1142] if(rom_read::ram_address#1!=(char *)$c000) goto rom_read::@9 -- pbuz1_neq_pbuc1_then_la1 
    lda.z ram_address+1
    cmp #>$c000
    bne __b9
    lda.z ram_address
    cmp #<$c000
    bne __b9
    // rom_read::@12
    // bram_bank++;
    // [1143] rom_read::bram_bank#1 = ++ rom_read::bram_bank#10 -- vbuz1=_inc_vbuz1 
    inc.z bram_bank
    // [1144] phi from rom_read::@12 to rom_read::@9 [phi:rom_read::@12->rom_read::@9]
    // [1144] phi rom_read::bram_bank#30 = rom_read::bram_bank#1 [phi:rom_read::@12->rom_read::@9#0] -- register_copy 
    // [1144] phi rom_read::ram_address#7 = (char *)$a000 [phi:rom_read::@12->rom_read::@9#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1144] phi from rom_read::@8 to rom_read::@9 [phi:rom_read::@8->rom_read::@9]
    // [1144] phi rom_read::bram_bank#30 = rom_read::bram_bank#10 [phi:rom_read::@8->rom_read::@9#0] -- register_copy 
    // [1144] phi rom_read::ram_address#7 = rom_read::ram_address#1 [phi:rom_read::@8->rom_read::@9#1] -- register_copy 
    // rom_read::@9
  __b9:
    // if (ram_address == (ram_ptr_t)RAM_HIGH)
    // [1145] if(rom_read::ram_address#7!=(char *)$8000) goto rom_read::@36 -- pbuz1_neq_pbuc1_then_la1 
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
    // [1085] phi from rom_read::@9 to rom_read::@3 [phi:rom_read::@9->rom_read::@3]
    // [1085] phi rom_read::y#11 = rom_read::y#36 [phi:rom_read::@9->rom_read::@3#0] -- register_copy 
    // [1085] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#1 [phi:rom_read::@9->rom_read::@3#1] -- register_copy 
    // [1085] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#20 [phi:rom_read::@9->rom_read::@3#2] -- register_copy 
    // [1085] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@9->rom_read::@3#3] -- register_copy 
    // [1085] phi rom_read::ram_address#10 = (char *)$a000 [phi:rom_read::@9->rom_read::@3#4] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1085] phi rom_read::bram_bank#10 = 1 [phi:rom_read::@9->rom_read::@3#5] -- vbuz1=vbuc1 
    lda #1
    sta.z bram_bank
    // [1085] phi rom_read::rom_file_read#11 = rom_read::rom_file_read#1 [phi:rom_read::@9->rom_read::@3#6] -- register_copy 
    jmp __b3
    // [1146] phi from rom_read::@9 to rom_read::@36 [phi:rom_read::@9->rom_read::@36]
    // rom_read::@36
    // [1085] phi from rom_read::@36 to rom_read::@3 [phi:rom_read::@36->rom_read::@3]
    // [1085] phi rom_read::y#11 = rom_read::y#36 [phi:rom_read::@36->rom_read::@3#0] -- register_copy 
    // [1085] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#1 [phi:rom_read::@36->rom_read::@3#1] -- register_copy 
    // [1085] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#20 [phi:rom_read::@36->rom_read::@3#2] -- register_copy 
    // [1085] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@36->rom_read::@3#3] -- register_copy 
    // [1085] phi rom_read::ram_address#10 = rom_read::ram_address#7 [phi:rom_read::@36->rom_read::@3#4] -- register_copy 
    // [1085] phi rom_read::bram_bank#10 = rom_read::bram_bank#30 [phi:rom_read::@36->rom_read::@3#5] -- register_copy 
    // [1085] phi rom_read::rom_file_read#11 = rom_read::rom_file_read#1 [phi:rom_read::@36->rom_read::@3#6] -- register_copy 
  .segment Data
    s: .text "Opening "
    .byte 0
    s1: .text " from SD card ..."
    .byte 0
    rom_read__11: .dword 0
    fp: .word 0
    return: .dword 0
    .label rom_package_read = rom_read_byte.rom_bank1_rom_read_byte__2
    .label rom_file_read = return
    .label y = frame_maskxy.cpeekcxy1_x
}
.segment Code
  // info_rom
// void info_rom(__zp($59) char rom_chip, __zp($b5) char info_status, __zp($b8) char *info_text)
info_rom: {
    .label info_rom__7 = $b5
    .label info_rom__8 = $df
    .label info_rom__10 = $b2
    .label rom_chip = $59
    .label info_status = $b5
    .label info_text = $b8
    // status_rom[rom_chip] = info_status
    // [1148] status_rom[info_rom::rom_chip#16] = info_rom::info_status#16 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z info_status
    ldy.z rom_chip
    sta status_rom,y
    // print_rom_led(rom_chip, status_color[info_status])
    // [1149] print_rom_led::chip#1 = info_rom::rom_chip#16 -- vbuz1=vbuz2 
    tya
    sta.z print_rom_led.chip
    // [1150] print_rom_led::c#1 = status_color[info_rom::info_status#16] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z print_rom_led.c
    // [1151] call print_rom_led
    // [1771] phi from info_rom to print_rom_led [phi:info_rom->print_rom_led]
    // [1771] phi print_rom_led::c#2 = print_rom_led::c#1 [phi:info_rom->print_rom_led#0] -- register_copy 
    // [1771] phi print_rom_led::chip#2 = print_rom_led::chip#1 [phi:info_rom->print_rom_led#1] -- register_copy 
    jsr print_rom_led
    // info_rom::@2
    // gotoxy(INFO_X, INFO_Y+rom_chip+2)
    // [1152] gotoxy::y#17 = info_rom::rom_chip#16 + $11+2 -- vbuz1=vbuz2_plus_vbuc1 
    lda #$11+2
    clc
    adc.z rom_chip
    sta.z gotoxy.y
    // [1153] call gotoxy
    // [479] phi from info_rom::@2 to gotoxy [phi:info_rom::@2->gotoxy]
    // [479] phi gotoxy::y#29 = gotoxy::y#17 [phi:info_rom::@2->gotoxy#0] -- register_copy 
    // [479] phi gotoxy::x#29 = 2 [phi:info_rom::@2->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // [1154] phi from info_rom::@2 to info_rom::@3 [phi:info_rom::@2->info_rom::@3]
    // info_rom::@3
    // printf("ROM%u - %-9s - %-6s - %05x / %05x - ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1155] call printf_str
    // [623] phi from info_rom::@3 to printf_str [phi:info_rom::@3->printf_str]
    // [623] phi printf_str::putc#66 = &cputc [phi:info_rom::@3->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = info_rom::s [phi:info_rom::@3->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@4
    // printf("ROM%u - %-9s - %-6s - %05x / %05x - ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1156] printf_uchar::uvalue#0 = info_rom::rom_chip#16 -- vbuz1=vbuz2 
    lda.z rom_chip
    sta.z printf_uchar.uvalue
    // [1157] call printf_uchar
    // [1018] phi from info_rom::@4 to printf_uchar [phi:info_rom::@4->printf_uchar]
    // [1018] phi printf_uchar::format_zero_padding#10 = 0 [phi:info_rom::@4->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1018] phi printf_uchar::format_min_length#10 = 0 [phi:info_rom::@4->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1018] phi printf_uchar::putc#10 = &cputc [phi:info_rom::@4->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1018] phi printf_uchar::format_radix#10 = DECIMAL [phi:info_rom::@4->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1018] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#0 [phi:info_rom::@4->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1158] phi from info_rom::@4 to info_rom::@5 [phi:info_rom::@4->info_rom::@5]
    // info_rom::@5
    // printf("ROM%u - %-9s - %-6s - %05x / %05x - ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1159] call printf_str
    // [623] phi from info_rom::@5 to printf_str [phi:info_rom::@5->printf_str]
    // [623] phi printf_str::putc#66 = &cputc [phi:info_rom::@5->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = info_rom::s1 [phi:info_rom::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@6
    // printf("ROM%u - %-9s - %-6s - %05x / %05x - ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1160] info_rom::$7 = info_rom::info_status#16 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z info_rom__7
    // [1161] printf_string::str#7 = status_text[info_rom::$7] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z info_rom__7
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [1162] call printf_string
    // [1034] phi from info_rom::@6 to printf_string [phi:info_rom::@6->printf_string]
    // [1034] phi printf_string::putc#16 = &cputc [phi:info_rom::@6->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1034] phi printf_string::str#16 = printf_string::str#7 [phi:info_rom::@6->printf_string#1] -- register_copy 
    // [1034] phi printf_string::format_justify_left#16 = 1 [phi:info_rom::@6->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1034] phi printf_string::format_min_length#16 = 9 [phi:info_rom::@6->printf_string#3] -- vbuz1=vbuc1 
    lda #9
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1163] phi from info_rom::@6 to info_rom::@7 [phi:info_rom::@6->info_rom::@7]
    // info_rom::@7
    // printf("ROM%u - %-9s - %-6s - %05x / %05x - ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1164] call printf_str
    // [623] phi from info_rom::@7 to printf_str [phi:info_rom::@7->printf_str]
    // [623] phi printf_str::putc#66 = &cputc [phi:info_rom::@7->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = info_rom::s1 [phi:info_rom::@7->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@8
    // printf("ROM%u - %-9s - %-6s - %05x / %05x - ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1165] info_rom::$8 = info_rom::rom_chip#16 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta.z info_rom__8
    // [1166] printf_string::str#8 = rom_device_names[info_rom::$8] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda rom_device_names,y
    sta.z printf_string.str
    lda rom_device_names+1,y
    sta.z printf_string.str+1
    // [1167] call printf_string
    // [1034] phi from info_rom::@8 to printf_string [phi:info_rom::@8->printf_string]
    // [1034] phi printf_string::putc#16 = &cputc [phi:info_rom::@8->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1034] phi printf_string::str#16 = printf_string::str#8 [phi:info_rom::@8->printf_string#1] -- register_copy 
    // [1034] phi printf_string::format_justify_left#16 = 1 [phi:info_rom::@8->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1034] phi printf_string::format_min_length#16 = 6 [phi:info_rom::@8->printf_string#3] -- vbuz1=vbuc1 
    lda #6
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1168] phi from info_rom::@8 to info_rom::@9 [phi:info_rom::@8->info_rom::@9]
    // info_rom::@9
    // printf("ROM%u - %-9s - %-6s - %05x / %05x - ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1169] call printf_str
    // [623] phi from info_rom::@9 to printf_str [phi:info_rom::@9->printf_str]
    // [623] phi printf_str::putc#66 = &cputc [phi:info_rom::@9->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = info_rom::s1 [phi:info_rom::@9->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@10
    // printf("ROM%u - %-9s - %-6s - %05x / %05x - ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1170] info_rom::$10 = info_rom::rom_chip#16 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta.z info_rom__10
    // [1171] printf_ulong::uvalue#0 = file_sizes[info_rom::$10] -- vduz1=pduc1_derefidx_vbuz2 
    tay
    lda file_sizes,y
    sta.z printf_ulong.uvalue
    lda file_sizes+1,y
    sta.z printf_ulong.uvalue+1
    lda file_sizes+2,y
    sta.z printf_ulong.uvalue+2
    lda file_sizes+3,y
    sta.z printf_ulong.uvalue+3
    // [1172] call printf_ulong
    // [1245] phi from info_rom::@10 to printf_ulong [phi:info_rom::@10->printf_ulong]
    // [1245] phi printf_ulong::format_zero_padding#11 = 1 [phi:info_rom::@10->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1245] phi printf_ulong::format_min_length#11 = 5 [phi:info_rom::@10->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1245] phi printf_ulong::putc#11 = &cputc [phi:info_rom::@10->printf_ulong#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_ulong.putc
    lda #>cputc
    sta.z printf_ulong.putc+1
    // [1245] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:info_rom::@10->printf_ulong#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1245] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#0 [phi:info_rom::@10->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1173] phi from info_rom::@10 to info_rom::@11 [phi:info_rom::@10->info_rom::@11]
    // info_rom::@11
    // printf("ROM%u - %-9s - %-6s - %05x / %05x - ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1174] call printf_str
    // [623] phi from info_rom::@11 to printf_str [phi:info_rom::@11->printf_str]
    // [623] phi printf_str::putc#66 = &cputc [phi:info_rom::@11->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = info_rom::s4 [phi:info_rom::@11->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@12
    // printf("ROM%u - %-9s - %-6s - %05x / %05x - ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1175] printf_ulong::uvalue#1 = rom_sizes[info_rom::$10] -- vduz1=pduc1_derefidx_vbuz2 
    ldy.z info_rom__10
    lda rom_sizes,y
    sta.z printf_ulong.uvalue
    lda rom_sizes+1,y
    sta.z printf_ulong.uvalue+1
    lda rom_sizes+2,y
    sta.z printf_ulong.uvalue+2
    lda rom_sizes+3,y
    sta.z printf_ulong.uvalue+3
    // [1176] call printf_ulong
    // [1245] phi from info_rom::@12 to printf_ulong [phi:info_rom::@12->printf_ulong]
    // [1245] phi printf_ulong::format_zero_padding#11 = 1 [phi:info_rom::@12->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1245] phi printf_ulong::format_min_length#11 = 5 [phi:info_rom::@12->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1245] phi printf_ulong::putc#11 = &cputc [phi:info_rom::@12->printf_ulong#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_ulong.putc
    lda #>cputc
    sta.z printf_ulong.putc+1
    // [1245] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:info_rom::@12->printf_ulong#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1245] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#1 [phi:info_rom::@12->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1177] phi from info_rom::@12 to info_rom::@13 [phi:info_rom::@12->info_rom::@13]
    // info_rom::@13
    // printf("ROM%u - %-9s - %-6s - %05x / %05x - ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1178] call printf_str
    // [623] phi from info_rom::@13 to printf_str [phi:info_rom::@13->printf_str]
    // [623] phi printf_str::putc#66 = &cputc [phi:info_rom::@13->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = info_rom::s1 [phi:info_rom::@13->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@14
    // if(info_text)
    // [1179] if((char *)0==info_rom::info_text#16) goto info_rom::@return -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __breturn
  !:
    // info_rom::@1
    // printf("%20s", info_text)
    // [1180] printf_string::str#9 = info_rom::info_text#16 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1181] call printf_string
    // [1034] phi from info_rom::@1 to printf_string [phi:info_rom::@1->printf_string]
    // [1034] phi printf_string::putc#16 = &cputc [phi:info_rom::@1->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1034] phi printf_string::str#16 = printf_string::str#9 [phi:info_rom::@1->printf_string#1] -- register_copy 
    // [1034] phi printf_string::format_justify_left#16 = 0 [phi:info_rom::@1->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1034] phi printf_string::format_min_length#16 = $14 [phi:info_rom::@1->printf_string#3] -- vbuz1=vbuc1 
    lda #$14
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_rom::@return
  __breturn:
    // }
    // [1182] return 
    rts
  .segment Data
    s: .text "ROM"
    .byte 0
    s1: .text " - "
    .byte 0
    s4: .text " / "
    .byte 0
}
.segment Code
  // rom_verify
// __zp($78) unsigned long rom_verify(__zp($59) char rom_chip, __zp($cc) char rom_bank_start, __zp($55) unsigned long file_size)
rom_verify: {
    .label rom_verify__16 = $4c
    .label rom_address = $bd
    .label rom_boundary = $55
    .label equal_bytes = $4c
    .label y = $50
    .label ram_address = $c5
    .label bram_bank = $5c
    .label rom_different_bytes = $78
    .label rom_chip = $59
    .label rom_bank_start = $cc
    .label file_size = $55
    .label return = $78
    .label progress_row_current = $76
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [1183] rom_address_from_bank::rom_bank#1 = rom_verify::rom_bank_start#0
    // [1184] call rom_address_from_bank
    // [1989] phi from rom_verify to rom_address_from_bank [phi:rom_verify->rom_address_from_bank]
    // [1989] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#1 [phi:rom_verify->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [1185] rom_address_from_bank::return#3 = rom_address_from_bank::return#0 -- vduz1=vduz2 
    lda.z rom_address_from_bank.return
    sta.z rom_address_from_bank.return_1
    lda.z rom_address_from_bank.return+1
    sta.z rom_address_from_bank.return_1+1
    lda.z rom_address_from_bank.return+2
    sta.z rom_address_from_bank.return_1+2
    lda.z rom_address_from_bank.return+3
    sta.z rom_address_from_bank.return_1+3
    // rom_verify::@11
    // [1186] rom_verify::rom_address#0 = rom_address_from_bank::return#3
    // unsigned long rom_boundary = rom_address + file_size
    // [1187] rom_verify::rom_boundary#0 = rom_verify::rom_address#0 + rom_verify::file_size#0 -- vduz1=vduz2_plus_vduz1 
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
    // info_rom(rom_chip, STATUS_COMPARING, "Comparing ...")
    // [1188] info_rom::rom_chip#1 = rom_verify::rom_chip#0
    // [1189] call info_rom
    // [1147] phi from rom_verify::@11 to info_rom [phi:rom_verify::@11->info_rom]
    // [1147] phi info_rom::info_text#16 = rom_verify::info_text [phi:rom_verify::@11->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_rom.info_text
    lda #>info_text
    sta.z info_rom.info_text+1
    // [1147] phi info_rom::rom_chip#16 = info_rom::rom_chip#1 [phi:rom_verify::@11->info_rom#1] -- register_copy 
    // [1147] phi info_rom::info_status#16 = STATUS_COMPARING [phi:rom_verify::@11->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_COMPARING
    sta.z info_rom.info_status
    jsr info_rom
    // [1190] phi from rom_verify::@11 to rom_verify::@12 [phi:rom_verify::@11->rom_verify::@12]
    // rom_verify::@12
    // gotoxy(x, y)
    // [1191] call gotoxy
    // [479] phi from rom_verify::@12 to gotoxy [phi:rom_verify::@12->gotoxy]
    // [479] phi gotoxy::y#29 = PROGRESS_Y [phi:rom_verify::@12->gotoxy#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z gotoxy.y
    // [479] phi gotoxy::x#29 = PROGRESS_X [phi:rom_verify::@12->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [1192] phi from rom_verify::@12 to rom_verify::@1 [phi:rom_verify::@12->rom_verify::@1]
    // [1192] phi rom_verify::y#3 = PROGRESS_Y [phi:rom_verify::@12->rom_verify::@1#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // [1192] phi rom_verify::progress_row_current#3 = 0 [phi:rom_verify::@12->rom_verify::@1#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z progress_row_current
    sta.z progress_row_current+1
    // [1192] phi rom_verify::rom_different_bytes#11 = 0 [phi:rom_verify::@12->rom_verify::@1#2] -- vduz1=vduc1 
    sta.z rom_different_bytes
    sta.z rom_different_bytes+1
    lda #<0>>$10
    sta.z rom_different_bytes+2
    lda #>0>>$10
    sta.z rom_different_bytes+3
    // [1192] phi rom_verify::ram_address#10 = (char *)$6000 [phi:rom_verify::@12->rom_verify::@1#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z ram_address
    lda #>$6000
    sta.z ram_address+1
    // [1192] phi rom_verify::bram_bank#11 = 0 [phi:rom_verify::@12->rom_verify::@1#4] -- vbuz1=vbuc1 
    lda #0
    sta.z bram_bank
    // [1192] phi rom_verify::rom_address#12 = rom_verify::rom_address#0 [phi:rom_verify::@12->rom_verify::@1#5] -- register_copy 
    // rom_verify::@1
  __b1:
    // while (rom_address < rom_boundary)
    // [1193] if(rom_verify::rom_address#12<rom_verify::rom_boundary#0) goto rom_verify::@2 -- vduz1_lt_vduz2_then_la1 
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
    // [1194] return 
    rts
    // rom_verify::@2
  __b2:
    // unsigned int equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1195] rom_compare::bank_ram#0 = rom_verify::bram_bank#11 -- vbuz1=vbuz2 
    lda.z bram_bank
    sta.z rom_compare.bank_ram
    // [1196] rom_compare::ptr_ram#1 = rom_verify::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_compare.ptr_ram
    lda.z ram_address+1
    sta.z rom_compare.ptr_ram+1
    // [1197] rom_compare::rom_compare_address#0 = rom_verify::rom_address#12 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_compare.rom_compare_address
    lda.z rom_address+1
    sta.z rom_compare.rom_compare_address+1
    lda.z rom_address+2
    sta.z rom_compare.rom_compare_address+2
    lda.z rom_address+3
    sta.z rom_compare.rom_compare_address+3
    // [1198] call rom_compare
  // {asm{.byte $db}}
    // [1993] phi from rom_verify::@2 to rom_compare [phi:rom_verify::@2->rom_compare]
    // [1993] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#1 [phi:rom_verify::@2->rom_compare#0] -- register_copy 
    // [1993] phi rom_compare::rom_compare_size#11 = PROGRESS_CELL [phi:rom_verify::@2->rom_compare#1] -- vwuz1=vwuc1 
    lda #<PROGRESS_CELL
    sta.z rom_compare.rom_compare_size
    lda #>PROGRESS_CELL
    sta.z rom_compare.rom_compare_size+1
    // [1993] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#0 [phi:rom_verify::@2->rom_compare#2] -- register_copy 
    // [1993] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#0 [phi:rom_verify::@2->rom_compare#3] -- register_copy 
    jsr rom_compare
    // unsigned int equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1199] rom_compare::return#2 = rom_compare::equal_bytes#2
    // rom_verify::@13
    // [1200] rom_verify::equal_bytes#0 = rom_compare::return#2
    // if (progress_row_current == PROGRESS_ROW)
    // [1201] if(rom_verify::progress_row_current#3!=PROGRESS_ROW) goto rom_verify::@3 -- vwuz1_neq_vwuc1_then_la1 
    lda.z progress_row_current+1
    cmp #>PROGRESS_ROW
    bne __b3
    lda.z progress_row_current
    cmp #<PROGRESS_ROW
    bne __b3
    // rom_verify::@8
    // gotoxy(x, ++y);
    // [1202] rom_verify::y#1 = ++ rom_verify::y#3 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [1203] gotoxy::y#26 = rom_verify::y#1 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1204] call gotoxy
    // [479] phi from rom_verify::@8 to gotoxy [phi:rom_verify::@8->gotoxy]
    // [479] phi gotoxy::y#29 = gotoxy::y#26 [phi:rom_verify::@8->gotoxy#0] -- register_copy 
    // [479] phi gotoxy::x#29 = PROGRESS_X [phi:rom_verify::@8->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [1205] phi from rom_verify::@8 to rom_verify::@3 [phi:rom_verify::@8->rom_verify::@3]
    // [1205] phi rom_verify::y#10 = rom_verify::y#1 [phi:rom_verify::@8->rom_verify::@3#0] -- register_copy 
    // [1205] phi rom_verify::progress_row_current#4 = 0 [phi:rom_verify::@8->rom_verify::@3#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z progress_row_current
    sta.z progress_row_current+1
    // [1205] phi from rom_verify::@13 to rom_verify::@3 [phi:rom_verify::@13->rom_verify::@3]
    // [1205] phi rom_verify::y#10 = rom_verify::y#3 [phi:rom_verify::@13->rom_verify::@3#0] -- register_copy 
    // [1205] phi rom_verify::progress_row_current#4 = rom_verify::progress_row_current#3 [phi:rom_verify::@13->rom_verify::@3#1] -- register_copy 
    // rom_verify::@3
  __b3:
    // if (equal_bytes != PROGRESS_CELL)
    // [1206] if(rom_verify::equal_bytes#0!=PROGRESS_CELL) goto rom_verify::@4 -- vwuz1_neq_vwuc1_then_la1 
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
    // [1207] stackpush(char) = '=' -- _stackpushbyte_=vbuc1 
    lda #'='
    pha
    // [1208] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_verify::@5
  __b5:
    // ram_address += PROGRESS_CELL
    // [1210] rom_verify::ram_address#1 = rom_verify::ram_address#10 + PROGRESS_CELL -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address
    clc
    adc #<PROGRESS_CELL
    sta.z ram_address
    lda.z ram_address+1
    adc #>PROGRESS_CELL
    sta.z ram_address+1
    // rom_address += PROGRESS_CELL
    // [1211] rom_verify::rom_address#1 = rom_verify::rom_address#12 + PROGRESS_CELL -- vduz1=vduz1_plus_vwuc1 
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
    // [1212] rom_verify::progress_row_current#11 = rom_verify::progress_row_current#4 + PROGRESS_CELL -- vwuz1=vwuz1_plus_vwuc1 
    lda.z progress_row_current
    clc
    adc #<PROGRESS_CELL
    sta.z progress_row_current
    lda.z progress_row_current+1
    adc #>PROGRESS_CELL
    sta.z progress_row_current+1
    // if (ram_address == BRAM_HIGH)
    // [1213] if(rom_verify::ram_address#1!=$c000) goto rom_verify::@6 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address+1
    cmp #>$c000
    bne __b6
    lda.z ram_address
    cmp #<$c000
    bne __b6
    // rom_verify::@10
    // bram_bank++;
    // [1214] rom_verify::bram_bank#1 = ++ rom_verify::bram_bank#11 -- vbuz1=_inc_vbuz1 
    inc.z bram_bank
    // [1215] phi from rom_verify::@10 to rom_verify::@6 [phi:rom_verify::@10->rom_verify::@6]
    // [1215] phi rom_verify::bram_bank#24 = rom_verify::bram_bank#1 [phi:rom_verify::@10->rom_verify::@6#0] -- register_copy 
    // [1215] phi rom_verify::ram_address#6 = (char *)$a000 [phi:rom_verify::@10->rom_verify::@6#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1215] phi from rom_verify::@5 to rom_verify::@6 [phi:rom_verify::@5->rom_verify::@6]
    // [1215] phi rom_verify::bram_bank#24 = rom_verify::bram_bank#11 [phi:rom_verify::@5->rom_verify::@6#0] -- register_copy 
    // [1215] phi rom_verify::ram_address#6 = rom_verify::ram_address#1 [phi:rom_verify::@5->rom_verify::@6#1] -- register_copy 
    // rom_verify::@6
  __b6:
    // if (ram_address == RAM_HIGH)
    // [1216] if(rom_verify::ram_address#6!=$8000) goto rom_verify::@23 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address+1
    cmp #>$8000
    bne __b7
    lda.z ram_address
    cmp #<$8000
    bne __b7
    // [1218] phi from rom_verify::@6 to rom_verify::@7 [phi:rom_verify::@6->rom_verify::@7]
    // [1218] phi rom_verify::ram_address#11 = (char *)$a000 [phi:rom_verify::@6->rom_verify::@7#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1218] phi rom_verify::bram_bank#10 = 1 [phi:rom_verify::@6->rom_verify::@7#1] -- vbuz1=vbuc1 
    lda #1
    sta.z bram_bank
    // [1217] phi from rom_verify::@6 to rom_verify::@23 [phi:rom_verify::@6->rom_verify::@23]
    // rom_verify::@23
    // [1218] phi from rom_verify::@23 to rom_verify::@7 [phi:rom_verify::@23->rom_verify::@7]
    // [1218] phi rom_verify::ram_address#11 = rom_verify::ram_address#6 [phi:rom_verify::@23->rom_verify::@7#0] -- register_copy 
    // [1218] phi rom_verify::bram_bank#10 = rom_verify::bram_bank#24 [phi:rom_verify::@23->rom_verify::@7#1] -- register_copy 
    // rom_verify::@7
  __b7:
    // PROGRESS_CELL - equal_bytes
    // [1219] rom_verify::$16 = PROGRESS_CELL - rom_verify::equal_bytes#0 -- vwuz1=vwuc1_minus_vwuz1 
    lda #<PROGRESS_CELL
    sec
    sbc.z rom_verify__16
    sta.z rom_verify__16
    lda #>PROGRESS_CELL
    sbc.z rom_verify__16+1
    sta.z rom_verify__16+1
    // rom_different_bytes += (PROGRESS_CELL - equal_bytes)
    // [1220] rom_verify::rom_different_bytes#1 = rom_verify::rom_different_bytes#11 + rom_verify::$16 -- vduz1=vduz1_plus_vwuz2 
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
    // [1221] call snprintf_init
    jsr snprintf_init
    // [1222] phi from rom_verify::@7 to rom_verify::@14 [phi:rom_verify::@7->rom_verify::@14]
    // rom_verify::@14
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1223] call printf_str
    // [623] phi from rom_verify::@14 to printf_str [phi:rom_verify::@14->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:rom_verify::@14->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = rom_verify::s [phi:rom_verify::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@15
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1224] printf_ulong::uvalue#4 = rom_verify::rom_different_bytes#1 -- vduz1=vduz2 
    lda.z rom_different_bytes
    sta.z printf_ulong.uvalue
    lda.z rom_different_bytes+1
    sta.z printf_ulong.uvalue+1
    lda.z rom_different_bytes+2
    sta.z printf_ulong.uvalue+2
    lda.z rom_different_bytes+3
    sta.z printf_ulong.uvalue+3
    // [1225] call printf_ulong
    // [1245] phi from rom_verify::@15 to printf_ulong [phi:rom_verify::@15->printf_ulong]
    // [1245] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_verify::@15->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1245] phi printf_ulong::format_min_length#11 = 5 [phi:rom_verify::@15->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1245] phi printf_ulong::putc#11 = &snputc [phi:rom_verify::@15->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1245] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_verify::@15->printf_ulong#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1245] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#4 [phi:rom_verify::@15->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1226] phi from rom_verify::@15 to rom_verify::@16 [phi:rom_verify::@15->rom_verify::@16]
    // rom_verify::@16
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1227] call printf_str
    // [623] phi from rom_verify::@16 to printf_str [phi:rom_verify::@16->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:rom_verify::@16->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = rom_verify::s1 [phi:rom_verify::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@17
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1228] printf_uchar::uvalue#6 = rom_verify::bram_bank#10 -- vbuz1=vbuz2 
    lda.z bram_bank
    sta.z printf_uchar.uvalue
    // [1229] call printf_uchar
    // [1018] phi from rom_verify::@17 to printf_uchar [phi:rom_verify::@17->printf_uchar]
    // [1018] phi printf_uchar::format_zero_padding#10 = 1 [phi:rom_verify::@17->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1018] phi printf_uchar::format_min_length#10 = 2 [phi:rom_verify::@17->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [1018] phi printf_uchar::putc#10 = &snputc [phi:rom_verify::@17->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1018] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:rom_verify::@17->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [1018] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#6 [phi:rom_verify::@17->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1230] phi from rom_verify::@17 to rom_verify::@18 [phi:rom_verify::@17->rom_verify::@18]
    // rom_verify::@18
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1231] call printf_str
    // [623] phi from rom_verify::@18 to printf_str [phi:rom_verify::@18->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:rom_verify::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = s3 [phi:rom_verify::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s3
    sta.z printf_str.s
    lda #>@s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@19
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1232] printf_uint::uvalue#11 = (unsigned int)rom_verify::ram_address#11 -- vwuz1=vwuz2 
    lda.z ram_address
    sta.z printf_uint.uvalue
    lda.z ram_address+1
    sta.z printf_uint.uvalue+1
    // [1233] call printf_uint
    // [632] phi from rom_verify::@19 to printf_uint [phi:rom_verify::@19->printf_uint]
    // [632] phi printf_uint::format_zero_padding#16 = 1 [phi:rom_verify::@19->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [632] phi printf_uint::format_min_length#16 = 4 [phi:rom_verify::@19->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [632] phi printf_uint::putc#16 = &snputc [phi:rom_verify::@19->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [632] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:rom_verify::@19->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [632] phi printf_uint::uvalue#16 = printf_uint::uvalue#11 [phi:rom_verify::@19->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1234] phi from rom_verify::@19 to rom_verify::@20 [phi:rom_verify::@19->rom_verify::@20]
    // rom_verify::@20
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1235] call printf_str
    // [623] phi from rom_verify::@20 to printf_str [phi:rom_verify::@20->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:rom_verify::@20->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = rom_verify::s3 [phi:rom_verify::@20->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@21
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1236] printf_ulong::uvalue#5 = rom_verify::rom_address#1 -- vduz1=vduz2 
    lda.z rom_address
    sta.z printf_ulong.uvalue
    lda.z rom_address+1
    sta.z printf_ulong.uvalue+1
    lda.z rom_address+2
    sta.z printf_ulong.uvalue+2
    lda.z rom_address+3
    sta.z printf_ulong.uvalue+3
    // [1237] call printf_ulong
    // [1245] phi from rom_verify::@21 to printf_ulong [phi:rom_verify::@21->printf_ulong]
    // [1245] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_verify::@21->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1245] phi printf_ulong::format_min_length#11 = 5 [phi:rom_verify::@21->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1245] phi printf_ulong::putc#11 = &snputc [phi:rom_verify::@21->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1245] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_verify::@21->printf_ulong#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1245] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#5 [phi:rom_verify::@21->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // rom_verify::@22
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1238] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1239] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [1241] call info_line
    // [811] phi from rom_verify::@22 to info_line [phi:rom_verify::@22->info_line]
    // [811] phi info_line::info_text#17 = info_text [phi:rom_verify::@22->info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_line.info_text
    lda #>@info_text
    sta.z info_line.info_text+1
    jsr info_line
    // [1192] phi from rom_verify::@22 to rom_verify::@1 [phi:rom_verify::@22->rom_verify::@1]
    // [1192] phi rom_verify::y#3 = rom_verify::y#10 [phi:rom_verify::@22->rom_verify::@1#0] -- register_copy 
    // [1192] phi rom_verify::progress_row_current#3 = rom_verify::progress_row_current#11 [phi:rom_verify::@22->rom_verify::@1#1] -- register_copy 
    // [1192] phi rom_verify::rom_different_bytes#11 = rom_verify::rom_different_bytes#1 [phi:rom_verify::@22->rom_verify::@1#2] -- register_copy 
    // [1192] phi rom_verify::ram_address#10 = rom_verify::ram_address#11 [phi:rom_verify::@22->rom_verify::@1#3] -- register_copy 
    // [1192] phi rom_verify::bram_bank#11 = rom_verify::bram_bank#10 [phi:rom_verify::@22->rom_verify::@1#4] -- register_copy 
    // [1192] phi rom_verify::rom_address#12 = rom_verify::rom_address#1 [phi:rom_verify::@22->rom_verify::@1#5] -- register_copy 
    jmp __b1
    // rom_verify::@4
  __b4:
    // cputc('*')
    // [1242] stackpush(char) = '*' -- _stackpushbyte_=vbuc1 
    lda #'*'
    pha
    // [1243] callexecute cputc  -- call_vprc1 
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
}
.segment Code
  // printf_ulong
// Print an unsigned int using a specific format
// void printf_ulong(__zp($4a) void (*putc)(char), __zp($26) unsigned long uvalue, __zp($de) char format_min_length, char format_justify_left, char format_sign_always, __zp($dd) char format_zero_padding, char format_upper_case, __zp($db) char format_radix)
printf_ulong: {
    .label uvalue = $26
    .label uvalue_1 = $f5
    .label format_radix = $db
    .label putc = $4a
    .label format_min_length = $de
    .label format_zero_padding = $dd
    // printf_ulong::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1246] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // ultoa(uvalue, printf_buffer.digits, format.radix)
    // [1247] ultoa::value#1 = printf_ulong::uvalue#11
    // [1248] ultoa::radix#0 = printf_ulong::format_radix#11
    // [1249] call ultoa
    // Format number into buffer
    jsr ultoa
    // printf_ulong::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1250] printf_number_buffer::putc#0 = printf_ulong::putc#11
    // [1251] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [1252] printf_number_buffer::format_min_length#0 = printf_ulong::format_min_length#11
    // [1253] printf_number_buffer::format_zero_padding#0 = printf_ulong::format_zero_padding#11
    // [1254] call printf_number_buffer
  // Print using format
    // [1694] phi from printf_ulong::@2 to printf_number_buffer [phi:printf_ulong::@2->printf_number_buffer]
    // [1694] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#0 [phi:printf_ulong::@2->printf_number_buffer#0] -- register_copy 
    // [1694] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_ulong::@2->printf_number_buffer#1] -- register_copy 
    // [1694] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#0 [phi:printf_ulong::@2->printf_number_buffer#2] -- register_copy 
    // [1694] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#0 [phi:printf_ulong::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_ulong::@return
    // }
    // [1255] return 
    rts
}
  // rom_flash
// __mem() unsigned long rom_flash(__mem() char rom_chip, __zp($cc) char rom_bank_start, __mem() unsigned long file_size)
rom_flash: {
    .label rom_flash__29 = $71
    .label equal_bytes = $4c
    .label ram_address_sector = $c1
    .label equal_bytes_1 = $f2
    .label retries = $e5
    .label flash_errors_sector = $cd
    .label ram_address = $ca
    .label rom_address = $ea
    .label x = $e6
    .label bram_bank_sector = $e9
    .label rom_bank_start = $cc
    // info_progress("Flashing ... (-) equal, (+) flashed, (!) error.")
    // [1257] call info_progress
  // Now we compare the RAM with the actual ROM contents.
    // [589] phi from rom_flash to info_progress [phi:rom_flash->info_progress]
    // [589] phi info_progress::info_text#12 = rom_flash::info_text [phi:rom_flash->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_progress.info_text
    lda #>info_text
    sta.z info_progress.info_text+1
    jsr info_progress
    // rom_flash::@19
    // unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start)
    // [1258] rom_address_from_bank::rom_bank#2 = rom_flash::rom_bank_start#0
    // [1259] call rom_address_from_bank
    // [1989] phi from rom_flash::@19 to rom_address_from_bank [phi:rom_flash::@19->rom_address_from_bank]
    // [1989] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#2 [phi:rom_flash::@19->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start)
    // [1260] rom_address_from_bank::return#4 = rom_address_from_bank::return#0 -- vdum1=vduz2 
    lda.z rom_address_from_bank.return
    sta rom_address_from_bank.return_2
    lda.z rom_address_from_bank.return+1
    sta rom_address_from_bank.return_2+1
    lda.z rom_address_from_bank.return+2
    sta rom_address_from_bank.return_2+2
    lda.z rom_address_from_bank.return+3
    sta rom_address_from_bank.return_2+3
    // rom_flash::@20
    // [1261] rom_flash::rom_address_sector#0 = rom_address_from_bank::return#4
    // unsigned long rom_boundary = rom_address_sector + file_size
    // [1262] rom_flash::rom_boundary#0 = rom_flash::rom_address_sector#0 + rom_flash::file_size#0 -- vdum1=vdum2_plus_vdum3 
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
    // [1263] info_rom::rom_chip#2 = rom_flash::rom_chip#0 -- vbuz1=vbum2 
    lda rom_chip
    sta.z info_rom.rom_chip
    // [1264] call info_rom
    // [1147] phi from rom_flash::@20 to info_rom [phi:rom_flash::@20->info_rom]
    // [1147] phi info_rom::info_text#16 = rom_flash::info_text1 [phi:rom_flash::@20->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z info_rom.info_text
    lda #>info_text1
    sta.z info_rom.info_text+1
    // [1147] phi info_rom::rom_chip#16 = info_rom::rom_chip#2 [phi:rom_flash::@20->info_rom#1] -- register_copy 
    // [1147] phi info_rom::info_status#16 = STATUS_FLASHING [phi:rom_flash::@20->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHING
    sta.z info_rom.info_status
    jsr info_rom
    // [1265] phi from rom_flash::@20 to rom_flash::@1 [phi:rom_flash::@20->rom_flash::@1]
    // [1265] phi rom_flash::y_sector#13 = PROGRESS_Y [phi:rom_flash::@20->rom_flash::@1#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y_sector
    // [1265] phi rom_flash::x_sector#10 = PROGRESS_X [phi:rom_flash::@20->rom_flash::@1#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [1265] phi rom_flash::flash_errors#10 = 0 [phi:rom_flash::@20->rom_flash::@1#2] -- vdum1=vduc1 
    lda #<0
    sta flash_errors
    sta flash_errors+1
    lda #<0>>$10
    sta flash_errors+2
    lda #>0>>$10
    sta flash_errors+3
    // [1265] phi rom_flash::ram_address_sector#11 = (char *)$6000 [phi:rom_flash::@20->rom_flash::@1#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z ram_address_sector
    lda #>$6000
    sta.z ram_address_sector+1
    // [1265] phi rom_flash::bram_bank_sector#14 = 0 [phi:rom_flash::@20->rom_flash::@1#4] -- vbuz1=vbuc1 
    lda #0
    sta.z bram_bank_sector
    // [1265] phi rom_flash::rom_address_sector#12 = rom_flash::rom_address_sector#0 [phi:rom_flash::@20->rom_flash::@1#5] -- register_copy 
    // rom_flash::@1
  __b1:
    // while (rom_address_sector < rom_boundary)
    // [1266] if(rom_flash::rom_address_sector#12<rom_flash::rom_boundary#0) goto rom_flash::@2 -- vdum1_lt_vdum2_then_la1 
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
    // [1267] phi from rom_flash::@1 to rom_flash::@3 [phi:rom_flash::@1->rom_flash::@3]
    // rom_flash::@3
    // info_line("Flashed ...")
    // [1268] call info_line
    // [811] phi from rom_flash::@3 to info_line [phi:rom_flash::@3->info_line]
    // [811] phi info_line::info_text#17 = rom_flash::info_text2 [phi:rom_flash::@3->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z info_line.info_text
    lda #>info_text2
    sta.z info_line.info_text+1
    jsr info_line
    // rom_flash::@return
    // }
    // [1269] return 
    rts
    // rom_flash::@2
  __b2:
    // unsigned int equal_bytes = rom_compare(bram_bank_sector, (ram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR)
    // [1270] rom_compare::bank_ram#1 = rom_flash::bram_bank_sector#14 -- vbuz1=vbuz2 
    lda.z bram_bank_sector
    sta.z rom_compare.bank_ram
    // [1271] rom_compare::ptr_ram#2 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z rom_compare.ptr_ram
    lda.z ram_address_sector+1
    sta.z rom_compare.ptr_ram+1
    // [1272] rom_compare::rom_compare_address#1 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_compare.rom_compare_address
    lda rom_address_sector+1
    sta.z rom_compare.rom_compare_address+1
    lda rom_address_sector+2
    sta.z rom_compare.rom_compare_address+2
    lda rom_address_sector+3
    sta.z rom_compare.rom_compare_address+3
    // [1273] call rom_compare
  // {asm{.byte $db}}
    // [1993] phi from rom_flash::@2 to rom_compare [phi:rom_flash::@2->rom_compare]
    // [1993] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#2 [phi:rom_flash::@2->rom_compare#0] -- register_copy 
    // [1993] phi rom_compare::rom_compare_size#11 = $1000 [phi:rom_flash::@2->rom_compare#1] -- vwuz1=vwuc1 
    lda #<$1000
    sta.z rom_compare.rom_compare_size
    lda #>$1000
    sta.z rom_compare.rom_compare_size+1
    // [1993] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#1 [phi:rom_flash::@2->rom_compare#2] -- register_copy 
    // [1993] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#1 [phi:rom_flash::@2->rom_compare#3] -- register_copy 
    jsr rom_compare
    // unsigned int equal_bytes = rom_compare(bram_bank_sector, (ram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR)
    // [1274] rom_compare::return#3 = rom_compare::equal_bytes#2
    // rom_flash::@21
    // [1275] rom_flash::equal_bytes#0 = rom_compare::return#3
    // if (equal_bytes != ROM_SECTOR)
    // [1276] if(rom_flash::equal_bytes#0!=$1000) goto rom_flash::@5 -- vwuz1_neq_vwuc1_then_la1 
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
    // [1277] cputsxy::x#0 = rom_flash::x_sector#10
    // [1278] cputsxy::y#0 = rom_flash::y_sector#13 -- vbuz1=vbum2 
    lda y_sector
    sta.z cputsxy.y
    // [1279] call cputsxy
    jsr cputsxy
    // [1280] phi from rom_flash::@12 rom_flash::@16 to rom_flash::@4 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4]
    // [1280] phi rom_flash::flash_errors#13 = rom_flash::flash_errors#1 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4#0] -- register_copy 
    // rom_flash::@4
  __b4:
    // ram_address_sector += ROM_SECTOR
    // [1281] rom_flash::ram_address_sector#1 = rom_flash::ram_address_sector#11 + $1000 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address_sector
    clc
    adc #<$1000
    sta.z ram_address_sector
    lda.z ram_address_sector+1
    adc #>$1000
    sta.z ram_address_sector+1
    // rom_address_sector += ROM_SECTOR
    // [1282] rom_flash::rom_address_sector#1 = rom_flash::rom_address_sector#12 + $1000 -- vdum1=vdum1_plus_vwuc1 
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
    // [1283] if(rom_flash::ram_address_sector#1!=$c000) goto rom_flash::@13 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address_sector+1
    cmp #>$c000
    bne __b13
    lda.z ram_address_sector
    cmp #<$c000
    bne __b13
    // rom_flash::@17
    // bram_bank_sector++;
    // [1284] rom_flash::bram_bank_sector#1 = ++ rom_flash::bram_bank_sector#14 -- vbuz1=_inc_vbuz1 
    inc.z bram_bank_sector
    // [1285] phi from rom_flash::@17 to rom_flash::@13 [phi:rom_flash::@17->rom_flash::@13]
    // [1285] phi rom_flash::bram_bank_sector#38 = rom_flash::bram_bank_sector#1 [phi:rom_flash::@17->rom_flash::@13#0] -- register_copy 
    // [1285] phi rom_flash::ram_address_sector#8 = (char *)$a000 [phi:rom_flash::@17->rom_flash::@13#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address_sector
    lda #>$a000
    sta.z ram_address_sector+1
    // [1285] phi from rom_flash::@4 to rom_flash::@13 [phi:rom_flash::@4->rom_flash::@13]
    // [1285] phi rom_flash::bram_bank_sector#38 = rom_flash::bram_bank_sector#14 [phi:rom_flash::@4->rom_flash::@13#0] -- register_copy 
    // [1285] phi rom_flash::ram_address_sector#8 = rom_flash::ram_address_sector#1 [phi:rom_flash::@4->rom_flash::@13#1] -- register_copy 
    // rom_flash::@13
  __b13:
    // if (ram_address_sector == RAM_HIGH)
    // [1286] if(rom_flash::ram_address_sector#8!=$8000) goto rom_flash::@44 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address_sector+1
    cmp #>$8000
    bne __b14
    lda.z ram_address_sector
    cmp #<$8000
    bne __b14
    // [1288] phi from rom_flash::@13 to rom_flash::@14 [phi:rom_flash::@13->rom_flash::@14]
    // [1288] phi rom_flash::ram_address_sector#15 = (char *)$a000 [phi:rom_flash::@13->rom_flash::@14#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address_sector
    lda #>$a000
    sta.z ram_address_sector+1
    // [1288] phi rom_flash::bram_bank_sector#12 = 1 [phi:rom_flash::@13->rom_flash::@14#1] -- vbuz1=vbuc1 
    lda #1
    sta.z bram_bank_sector
    // [1287] phi from rom_flash::@13 to rom_flash::@44 [phi:rom_flash::@13->rom_flash::@44]
    // rom_flash::@44
    // [1288] phi from rom_flash::@44 to rom_flash::@14 [phi:rom_flash::@44->rom_flash::@14]
    // [1288] phi rom_flash::ram_address_sector#15 = rom_flash::ram_address_sector#8 [phi:rom_flash::@44->rom_flash::@14#0] -- register_copy 
    // [1288] phi rom_flash::bram_bank_sector#12 = rom_flash::bram_bank_sector#38 [phi:rom_flash::@44->rom_flash::@14#1] -- register_copy 
    // rom_flash::@14
  __b14:
    // x_sector += 8
    // [1289] rom_flash::x_sector#1 = rom_flash::x_sector#10 + 8 -- vbum1=vbum1_plus_vbuc1 
    lda #8
    clc
    adc x_sector
    sta x_sector
    // rom_address_sector % PROGRESS_ROW
    // [1290] rom_flash::$29 = rom_flash::rom_address_sector#1 & PROGRESS_ROW-1 -- vduz1=vdum2_band_vduc1 
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
    // [1291] if(0!=rom_flash::$29) goto rom_flash::@15 -- 0_neq_vduz1_then_la1 
    lda.z rom_flash__29
    ora.z rom_flash__29+1
    ora.z rom_flash__29+2
    ora.z rom_flash__29+3
    bne __b15
    // rom_flash::@18
    // y_sector++;
    // [1292] rom_flash::y_sector#1 = ++ rom_flash::y_sector#13 -- vbum1=_inc_vbum1 
    inc y_sector
    // [1293] phi from rom_flash::@18 to rom_flash::@15 [phi:rom_flash::@18->rom_flash::@15]
    // [1293] phi rom_flash::y_sector#18 = rom_flash::y_sector#1 [phi:rom_flash::@18->rom_flash::@15#0] -- register_copy 
    // [1293] phi rom_flash::x_sector#20 = PROGRESS_X [phi:rom_flash::@18->rom_flash::@15#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [1293] phi from rom_flash::@14 to rom_flash::@15 [phi:rom_flash::@14->rom_flash::@15]
    // [1293] phi rom_flash::y_sector#18 = rom_flash::y_sector#13 [phi:rom_flash::@14->rom_flash::@15#0] -- register_copy 
    // [1293] phi rom_flash::x_sector#20 = rom_flash::x_sector#1 [phi:rom_flash::@14->rom_flash::@15#1] -- register_copy 
    // rom_flash::@15
  __b15:
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1294] call snprintf_init
    jsr snprintf_init
    // rom_flash::@40
    // [1295] printf_ulong::uvalue#8 = rom_flash::flash_errors#13 -- vduz1=vdum2 
    lda flash_errors
    sta.z printf_ulong.uvalue
    lda flash_errors+1
    sta.z printf_ulong.uvalue+1
    lda flash_errors+2
    sta.z printf_ulong.uvalue+2
    lda flash_errors+3
    sta.z printf_ulong.uvalue+3
    // [1296] call printf_ulong
    // [1245] phi from rom_flash::@40 to printf_ulong [phi:rom_flash::@40->printf_ulong]
    // [1245] phi printf_ulong::format_zero_padding#11 = 0 [phi:rom_flash::@40->printf_ulong#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_ulong.format_zero_padding
    // [1245] phi printf_ulong::format_min_length#11 = 0 [phi:rom_flash::@40->printf_ulong#1] -- vbuz1=vbuc1 
    sta.z printf_ulong.format_min_length
    // [1245] phi printf_ulong::putc#11 = &snputc [phi:rom_flash::@40->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1245] phi printf_ulong::format_radix#11 = DECIMAL [phi:rom_flash::@40->printf_ulong#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_ulong.format_radix
    // [1245] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#8 [phi:rom_flash::@40->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1297] phi from rom_flash::@40 to rom_flash::@41 [phi:rom_flash::@40->rom_flash::@41]
    // rom_flash::@41
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1298] call printf_str
    // [623] phi from rom_flash::@41 to printf_str [phi:rom_flash::@41->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:rom_flash::@41->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = rom_flash::s6 [phi:rom_flash::@41->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@42
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1299] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1300] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom(rom_chip, STATUS_FLASHING, info_text)
    // [1302] info_rom::rom_chip#3 = rom_flash::rom_chip#0 -- vbuz1=vbum2 
    lda rom_chip
    sta.z info_rom.rom_chip
    // [1303] call info_rom
    // [1147] phi from rom_flash::@42 to info_rom [phi:rom_flash::@42->info_rom]
    // [1147] phi info_rom::info_text#16 = info_text [phi:rom_flash::@42->info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_rom.info_text
    lda #>@info_text
    sta.z info_rom.info_text+1
    // [1147] phi info_rom::rom_chip#16 = info_rom::rom_chip#3 [phi:rom_flash::@42->info_rom#1] -- register_copy 
    // [1147] phi info_rom::info_status#16 = STATUS_FLASHING [phi:rom_flash::@42->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHING
    sta.z info_rom.info_status
    jsr info_rom
    // [1265] phi from rom_flash::@42 to rom_flash::@1 [phi:rom_flash::@42->rom_flash::@1]
    // [1265] phi rom_flash::y_sector#13 = rom_flash::y_sector#18 [phi:rom_flash::@42->rom_flash::@1#0] -- register_copy 
    // [1265] phi rom_flash::x_sector#10 = rom_flash::x_sector#20 [phi:rom_flash::@42->rom_flash::@1#1] -- register_copy 
    // [1265] phi rom_flash::flash_errors#10 = rom_flash::flash_errors#13 [phi:rom_flash::@42->rom_flash::@1#2] -- register_copy 
    // [1265] phi rom_flash::ram_address_sector#11 = rom_flash::ram_address_sector#15 [phi:rom_flash::@42->rom_flash::@1#3] -- register_copy 
    // [1265] phi rom_flash::bram_bank_sector#14 = rom_flash::bram_bank_sector#12 [phi:rom_flash::@42->rom_flash::@1#4] -- register_copy 
    // [1265] phi rom_flash::rom_address_sector#12 = rom_flash::rom_address_sector#1 [phi:rom_flash::@42->rom_flash::@1#5] -- register_copy 
    jmp __b1
    // [1304] phi from rom_flash::@21 to rom_flash::@5 [phi:rom_flash::@21->rom_flash::@5]
  __b3:
    // [1304] phi rom_flash::retries#12 = 0 [phi:rom_flash::@21->rom_flash::@5#0] -- vbuz1=vbuc1 
    lda #0
    sta.z retries
    // [1304] phi rom_flash::flash_errors_sector#11 = 0 [phi:rom_flash::@21->rom_flash::@5#1] -- vwuz1=vwuc1 
    sta.z flash_errors_sector
    sta.z flash_errors_sector+1
    // [1304] phi from rom_flash::@43 to rom_flash::@5 [phi:rom_flash::@43->rom_flash::@5]
    // [1304] phi rom_flash::retries#12 = rom_flash::retries#1 [phi:rom_flash::@43->rom_flash::@5#0] -- register_copy 
    // [1304] phi rom_flash::flash_errors_sector#11 = rom_flash::flash_errors_sector#10 [phi:rom_flash::@43->rom_flash::@5#1] -- register_copy 
    // rom_flash::@5
  __b5:
    // rom_sector_erase(rom_address_sector)
    // [1305] rom_sector_erase::address#0 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_sector_erase.address
    lda rom_address_sector+1
    sta.z rom_sector_erase.address+1
    lda rom_address_sector+2
    sta.z rom_sector_erase.address+2
    lda rom_address_sector+3
    sta.z rom_sector_erase.address+3
    // [1306] call rom_sector_erase
    // [2055] phi from rom_flash::@5 to rom_sector_erase [phi:rom_flash::@5->rom_sector_erase]
    jsr rom_sector_erase
    // rom_flash::@22
    // unsigned long rom_sector_boundary = rom_address_sector + ROM_SECTOR
    // [1307] rom_flash::rom_sector_boundary#0 = rom_flash::rom_address_sector#12 + $1000 -- vdum1=vdum2_plus_vwuc1 
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
    // [1308] gotoxy::x#27 = rom_flash::x_sector#10 -- vbuz1=vbum2 
    lda x_sector
    sta.z gotoxy.x
    // [1309] gotoxy::y#27 = rom_flash::y_sector#13 -- vbuz1=vbum2 
    lda y_sector
    sta.z gotoxy.y
    // [1310] call gotoxy
    // [479] phi from rom_flash::@22 to gotoxy [phi:rom_flash::@22->gotoxy]
    // [479] phi gotoxy::y#29 = gotoxy::y#27 [phi:rom_flash::@22->gotoxy#0] -- register_copy 
    // [479] phi gotoxy::x#29 = gotoxy::x#27 [phi:rom_flash::@22->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1311] phi from rom_flash::@22 to rom_flash::@23 [phi:rom_flash::@22->rom_flash::@23]
    // rom_flash::@23
    // printf("........")
    // [1312] call printf_str
    // [623] phi from rom_flash::@23 to printf_str [phi:rom_flash::@23->printf_str]
    // [623] phi printf_str::putc#66 = &cputc [phi:rom_flash::@23->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = rom_flash::s1 [phi:rom_flash::@23->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@24
    // [1313] rom_flash::rom_address#26 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_address
    lda rom_address_sector+1
    sta.z rom_address+1
    lda rom_address_sector+2
    sta.z rom_address+2
    lda rom_address_sector+3
    sta.z rom_address+3
    // [1314] rom_flash::ram_address#26 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z ram_address
    lda.z ram_address_sector+1
    sta.z ram_address+1
    // [1315] rom_flash::x#26 = rom_flash::x_sector#10 -- vbuz1=vbum2 
    lda x_sector
    sta.z x
    // [1316] phi from rom_flash::@10 rom_flash::@24 to rom_flash::@6 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6]
    // [1316] phi rom_flash::x#10 = rom_flash::x#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#0] -- register_copy 
    // [1316] phi rom_flash::ram_address#10 = rom_flash::ram_address#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#1] -- register_copy 
    // [1316] phi rom_flash::flash_errors_sector#10 = rom_flash::flash_errors_sector#8 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#2] -- register_copy 
    // [1316] phi rom_flash::rom_address#11 = rom_flash::rom_address#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#3] -- register_copy 
    // rom_flash::@6
  __b6:
    // while (rom_address < rom_sector_boundary)
    // [1317] if(rom_flash::rom_address#11<rom_flash::rom_sector_boundary#0) goto rom_flash::@7 -- vduz1_lt_vdum2_then_la1 
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
    // [1318] rom_flash::retries#1 = ++ rom_flash::retries#12 -- vbuz1=_inc_vbuz1 
    inc.z retries
    // while (flash_errors_sector && retries <= 3)
    // [1319] if(0==rom_flash::flash_errors_sector#10) goto rom_flash::@12 -- 0_eq_vwuz1_then_la1 
    lda.z flash_errors_sector
    ora.z flash_errors_sector+1
    beq __b12
    // rom_flash::@43
    // [1320] if(rom_flash::retries#1<3+1) goto rom_flash::@5 -- vbuz1_lt_vbuc1_then_la1 
    lda.z retries
    cmp #3+1
    bcs !__b5+
    jmp __b5
  !__b5:
    // rom_flash::@12
  __b12:
    // flash_errors += flash_errors_sector
    // [1321] rom_flash::flash_errors#1 = rom_flash::flash_errors#10 + rom_flash::flash_errors_sector#10 -- vdum1=vdum1_plus_vwuz2 
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
    // [1322] printf_ulong::uvalue#7 = rom_flash::flash_errors_sector#10 + rom_flash::flash_errors#10 -- vduz1=vwuz2_plus_vdum3 
    lda flash_errors
    clc
    adc.z flash_errors_sector
    sta.z printf_ulong.uvalue_1
    lda flash_errors+1
    adc.z flash_errors_sector+1
    sta.z printf_ulong.uvalue_1+1
    lda flash_errors+2
    adc #0
    sta.z printf_ulong.uvalue_1+2
    lda flash_errors+3
    adc #0
    sta.z printf_ulong.uvalue_1+3
    // [1323] call snprintf_init
    jsr snprintf_init
    // [1324] phi from rom_flash::@7 to rom_flash::@25 [phi:rom_flash::@7->rom_flash::@25]
    // rom_flash::@25
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1325] call printf_str
    // [623] phi from rom_flash::@25 to printf_str [phi:rom_flash::@25->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:rom_flash::@25->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = rom_flash::s2 [phi:rom_flash::@25->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@26
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1326] printf_uchar::uvalue#7 = rom_flash::bram_bank_sector#14 -- vbuz1=vbuz2 
    lda.z bram_bank_sector
    sta.z printf_uchar.uvalue
    // [1327] call printf_uchar
    // [1018] phi from rom_flash::@26 to printf_uchar [phi:rom_flash::@26->printf_uchar]
    // [1018] phi printf_uchar::format_zero_padding#10 = 1 [phi:rom_flash::@26->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1018] phi printf_uchar::format_min_length#10 = 2 [phi:rom_flash::@26->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [1018] phi printf_uchar::putc#10 = &snputc [phi:rom_flash::@26->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1018] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:rom_flash::@26->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [1018] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#7 [phi:rom_flash::@26->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1328] phi from rom_flash::@26 to rom_flash::@27 [phi:rom_flash::@26->rom_flash::@27]
    // rom_flash::@27
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1329] call printf_str
    // [623] phi from rom_flash::@27 to printf_str [phi:rom_flash::@27->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:rom_flash::@27->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = s3 [phi:rom_flash::@27->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@28
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1330] printf_uint::uvalue#12 = (unsigned int)rom_flash::ram_address_sector#11 -- vwuz1=vwuz2 
    lda.z ram_address_sector
    sta.z printf_uint.uvalue
    lda.z ram_address_sector+1
    sta.z printf_uint.uvalue+1
    // [1331] call printf_uint
    // [632] phi from rom_flash::@28 to printf_uint [phi:rom_flash::@28->printf_uint]
    // [632] phi printf_uint::format_zero_padding#16 = 1 [phi:rom_flash::@28->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [632] phi printf_uint::format_min_length#16 = 4 [phi:rom_flash::@28->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [632] phi printf_uint::putc#16 = &snputc [phi:rom_flash::@28->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [632] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:rom_flash::@28->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [632] phi printf_uint::uvalue#16 = printf_uint::uvalue#12 [phi:rom_flash::@28->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1332] phi from rom_flash::@28 to rom_flash::@29 [phi:rom_flash::@28->rom_flash::@29]
    // rom_flash::@29
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1333] call printf_str
    // [623] phi from rom_flash::@29 to printf_str [phi:rom_flash::@29->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:rom_flash::@29->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = rom_flash::s4 [phi:rom_flash::@29->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@30
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1334] printf_ulong::uvalue#6 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z printf_ulong.uvalue
    lda rom_address_sector+1
    sta.z printf_ulong.uvalue+1
    lda rom_address_sector+2
    sta.z printf_ulong.uvalue+2
    lda rom_address_sector+3
    sta.z printf_ulong.uvalue+3
    // [1335] call printf_ulong
    // [1245] phi from rom_flash::@30 to printf_ulong [phi:rom_flash::@30->printf_ulong]
    // [1245] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_flash::@30->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1245] phi printf_ulong::format_min_length#11 = 5 [phi:rom_flash::@30->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1245] phi printf_ulong::putc#11 = &snputc [phi:rom_flash::@30->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1245] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_flash::@30->printf_ulong#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1245] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#6 [phi:rom_flash::@30->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1336] phi from rom_flash::@30 to rom_flash::@31 [phi:rom_flash::@30->rom_flash::@31]
    // rom_flash::@31
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1337] call printf_str
    // [623] phi from rom_flash::@31 to printf_str [phi:rom_flash::@31->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:rom_flash::@31->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = rom_flash::s5 [phi:rom_flash::@31->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@32
    // [1338] printf_ulong::uvalue#20 = printf_ulong::uvalue#7 -- vduz1=vduz2 
    lda.z printf_ulong.uvalue_1
    sta.z printf_ulong.uvalue
    lda.z printf_ulong.uvalue_1+1
    sta.z printf_ulong.uvalue+1
    lda.z printf_ulong.uvalue_1+2
    sta.z printf_ulong.uvalue+2
    lda.z printf_ulong.uvalue_1+3
    sta.z printf_ulong.uvalue+3
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1339] call printf_ulong
    // [1245] phi from rom_flash::@32 to printf_ulong [phi:rom_flash::@32->printf_ulong]
    // [1245] phi printf_ulong::format_zero_padding#11 = 0 [phi:rom_flash::@32->printf_ulong#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_ulong.format_zero_padding
    // [1245] phi printf_ulong::format_min_length#11 = 0 [phi:rom_flash::@32->printf_ulong#1] -- vbuz1=vbuc1 
    sta.z printf_ulong.format_min_length
    // [1245] phi printf_ulong::putc#11 = &snputc [phi:rom_flash::@32->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1245] phi printf_ulong::format_radix#11 = DECIMAL [phi:rom_flash::@32->printf_ulong#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_ulong.format_radix
    // [1245] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#20 [phi:rom_flash::@32->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1340] phi from rom_flash::@32 to rom_flash::@33 [phi:rom_flash::@32->rom_flash::@33]
    // rom_flash::@33
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1341] call printf_str
    // [623] phi from rom_flash::@33 to printf_str [phi:rom_flash::@33->printf_str]
    // [623] phi printf_str::putc#66 = &snputc [phi:rom_flash::@33->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [623] phi printf_str::s#66 = rom_flash::s6 [phi:rom_flash::@33->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@34
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1342] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1343] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [1345] call info_line
    // [811] phi from rom_flash::@34 to info_line [phi:rom_flash::@34->info_line]
    // [811] phi info_line::info_text#17 = info_text [phi:rom_flash::@34->info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_line.info_text
    lda #>@info_text
    sta.z info_line.info_text+1
    jsr info_line
    // rom_flash::@35
    // unsigned long written_bytes = rom_write(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1346] rom_write::flash_ram_bank#0 = rom_flash::bram_bank_sector#14 -- vbuz1=vbuz2 
    lda.z bram_bank_sector
    sta.z rom_write.flash_ram_bank
    // [1347] rom_write::flash_ram_address#1 = rom_flash::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_write.flash_ram_address
    lda.z ram_address+1
    sta.z rom_write.flash_ram_address+1
    // [1348] rom_write::flash_rom_address#1 = rom_flash::rom_address#11 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_write.flash_rom_address
    lda.z rom_address+1
    sta.z rom_write.flash_rom_address+1
    lda.z rom_address+2
    sta.z rom_write.flash_rom_address+2
    lda.z rom_address+3
    sta.z rom_write.flash_rom_address+3
    // [1349] call rom_write
    jsr rom_write
    // rom_flash::@36
    // rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1350] rom_compare::bank_ram#2 = rom_flash::bram_bank_sector#14 -- vbuz1=vbuz2 
    lda.z bram_bank_sector
    sta.z rom_compare.bank_ram
    // [1351] rom_compare::ptr_ram#3 = rom_flash::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_compare.ptr_ram
    lda.z ram_address+1
    sta.z rom_compare.ptr_ram+1
    // [1352] rom_compare::rom_compare_address#2 = rom_flash::rom_address#11 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_compare.rom_compare_address
    lda.z rom_address+1
    sta.z rom_compare.rom_compare_address+1
    lda.z rom_address+2
    sta.z rom_compare.rom_compare_address+2
    lda.z rom_address+3
    sta.z rom_compare.rom_compare_address+3
    // [1353] call rom_compare
    // [1993] phi from rom_flash::@36 to rom_compare [phi:rom_flash::@36->rom_compare]
    // [1993] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#3 [phi:rom_flash::@36->rom_compare#0] -- register_copy 
    // [1993] phi rom_compare::rom_compare_size#11 = PROGRESS_CELL [phi:rom_flash::@36->rom_compare#1] -- vwuz1=vwuc1 
    lda #<PROGRESS_CELL
    sta.z rom_compare.rom_compare_size
    lda #>PROGRESS_CELL
    sta.z rom_compare.rom_compare_size+1
    // [1993] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#2 [phi:rom_flash::@36->rom_compare#2] -- register_copy 
    // [1993] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#2 [phi:rom_flash::@36->rom_compare#3] -- register_copy 
    jsr rom_compare
    // rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1354] rom_compare::return#4 = rom_compare::equal_bytes#2
    // rom_flash::@37
    // equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1355] rom_flash::equal_bytes#1 = rom_compare::return#4 -- vwuz1=vwuz2 
    lda.z rom_compare.return
    sta.z equal_bytes_1
    lda.z rom_compare.return+1
    sta.z equal_bytes_1+1
    // gotoxy(x, y)
    // [1356] gotoxy::x#28 = rom_flash::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1357] gotoxy::y#28 = rom_flash::y_sector#13 -- vbuz1=vbum2 
    lda y_sector
    sta.z gotoxy.y
    // [1358] call gotoxy
    // [479] phi from rom_flash::@37 to gotoxy [phi:rom_flash::@37->gotoxy]
    // [479] phi gotoxy::y#29 = gotoxy::y#28 [phi:rom_flash::@37->gotoxy#0] -- register_copy 
    // [479] phi gotoxy::x#29 = gotoxy::x#28 [phi:rom_flash::@37->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_flash::@38
    // if (equal_bytes != PROGRESS_CELL)
    // [1359] if(rom_flash::equal_bytes#1!=PROGRESS_CELL) goto rom_flash::@9 -- vwuz1_neq_vwuc1_then_la1 
    lda.z equal_bytes_1+1
    cmp #>PROGRESS_CELL
    bne __b9
    lda.z equal_bytes_1
    cmp #<PROGRESS_CELL
    bne __b9
    // rom_flash::@11
    // cputcxy(x,y,'+')
    // [1360] cputcxy::x#12 = rom_flash::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1361] cputcxy::y#12 = rom_flash::y_sector#13 -- vbuz1=vbum2 
    lda y_sector
    sta.z cputcxy.y
    // [1362] call cputcxy
    // [1588] phi from rom_flash::@11 to cputcxy [phi:rom_flash::@11->cputcxy]
    // [1588] phi cputcxy::c#13 = '+' [phi:rom_flash::@11->cputcxy#0] -- vbuz1=vbuc1 
    lda #'+'
    sta.z cputcxy.c
    // [1588] phi cputcxy::y#13 = cputcxy::y#12 [phi:rom_flash::@11->cputcxy#1] -- register_copy 
    // [1588] phi cputcxy::x#13 = cputcxy::x#12 [phi:rom_flash::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [1363] phi from rom_flash::@11 rom_flash::@39 to rom_flash::@10 [phi:rom_flash::@11/rom_flash::@39->rom_flash::@10]
    // [1363] phi rom_flash::flash_errors_sector#8 = rom_flash::flash_errors_sector#10 [phi:rom_flash::@11/rom_flash::@39->rom_flash::@10#0] -- register_copy 
    // rom_flash::@10
  __b10:
    // ram_address += PROGRESS_CELL
    // [1364] rom_flash::ram_address#1 = rom_flash::ram_address#10 + PROGRESS_CELL -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address
    clc
    adc #<PROGRESS_CELL
    sta.z ram_address
    lda.z ram_address+1
    adc #>PROGRESS_CELL
    sta.z ram_address+1
    // rom_address += PROGRESS_CELL
    // [1365] rom_flash::rom_address#1 = rom_flash::rom_address#11 + PROGRESS_CELL -- vduz1=vduz1_plus_vwuc1 
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
    // [1366] rom_flash::x#1 = ++ rom_flash::x#10 -- vbuz1=_inc_vbuz1 
    inc.z x
    jmp __b6
    // rom_flash::@9
  __b9:
    // cputcxy(x,y,'!')
    // [1367] cputcxy::x#11 = rom_flash::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1368] cputcxy::y#11 = rom_flash::y_sector#13 -- vbuz1=vbum2 
    lda y_sector
    sta.z cputcxy.y
    // [1369] call cputcxy
    // [1588] phi from rom_flash::@9 to cputcxy [phi:rom_flash::@9->cputcxy]
    // [1588] phi cputcxy::c#13 = '!' [phi:rom_flash::@9->cputcxy#0] -- vbuz1=vbuc1 
    lda #'!'
    sta.z cputcxy.c
    // [1588] phi cputcxy::y#13 = cputcxy::y#11 [phi:rom_flash::@9->cputcxy#1] -- register_copy 
    // [1588] phi cputcxy::x#13 = cputcxy::x#11 [phi:rom_flash::@9->cputcxy#2] -- register_copy 
    jsr cputcxy
    // rom_flash::@39
    // flash_errors_sector++;
    // [1370] rom_flash::flash_errors_sector#1 = ++ rom_flash::flash_errors_sector#10 -- vwuz1=_inc_vwuz1 
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
    .label rom_address_sector = main.rom_file_modulo
    rom_boundary: .dword 0
    rom_sector_boundary: .dword 0
    .label flash_errors = rom_read.rom_read__11
    .label x_sector = fclose.sp
    .label y_sector = frame_maskxy.return
    .label rom_chip = main.check_card_roms1_check_rom1_main__0
    .label file_size = main.rom_flash_errors
    .label return = rom_read.rom_read__11
}
.segment Code
  // strchr
// Searches for the first occurrence of the character c (an unsigned char) in the string pointed to, by the argument str.
// - str: The memory to search
// - c: A character to search for
// Return: A pointer to the matching byte or NULL if the character does not occur in the given memory area.
// __zp($2a) void * strchr(__zp($2a) const void *str, __mem() char c)
strchr: {
    .label ptr = $2a
    .label return = $2a
    .label str = $2a
    // [1372] strchr::ptr#6 = (char *)strchr::str#2
    // [1373] phi from strchr strchr::@3 to strchr::@1 [phi:strchr/strchr::@3->strchr::@1]
    // [1373] phi strchr::ptr#2 = strchr::ptr#6 [phi:strchr/strchr::@3->strchr::@1#0] -- register_copy 
    // strchr::@1
  __b1:
    // while(*ptr)
    // [1374] if(0!=*strchr::ptr#2) goto strchr::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (ptr),y
    cmp #0
    bne __b2
    // [1375] phi from strchr::@1 to strchr::@return [phi:strchr::@1->strchr::@return]
    // [1375] phi strchr::return#2 = (void *) 0 [phi:strchr::@1->strchr::@return#0] -- pvoz1=pvoc1 
    tya
    sta.z return
    sta.z return+1
    // strchr::@return
    // }
    // [1376] return 
    rts
    // strchr::@2
  __b2:
    // if(*ptr==c)
    // [1377] if(*strchr::ptr#2!=strchr::c#4) goto strchr::@3 -- _deref_pbuz1_neq_vbum2_then_la1 
    ldy #0
    lda (ptr),y
    cmp c
    bne __b3
    // strchr::@4
    // [1378] strchr::return#8 = (void *)strchr::ptr#2
    // [1375] phi from strchr::@4 to strchr::@return [phi:strchr::@4->strchr::@return]
    // [1375] phi strchr::return#2 = strchr::return#8 [phi:strchr::@4->strchr::@return#0] -- register_copy 
    rts
    // strchr::@3
  __b3:
    // ptr++;
    // [1379] strchr::ptr#1 = ++ strchr::ptr#2 -- pbuz1=_inc_pbuz1 
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
// void info_cx16_rom(char info_status, char *info_text)
info_cx16_rom: {
    .label info_text = 0
    // info_rom(0, info_status, info_text)
    // [1381] call info_rom
    // [1147] phi from info_cx16_rom to info_rom [phi:info_cx16_rom->info_rom]
    // [1147] phi info_rom::info_text#16 = info_cx16_rom::info_text#0 [phi:info_cx16_rom->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_rom.info_text
    lda #>info_text
    sta.z info_rom.info_text+1
    // [1147] phi info_rom::rom_chip#16 = 0 [phi:info_cx16_rom->info_rom#1] -- vbuz1=vbuc1 
    lda #0
    sta.z info_rom.rom_chip
    // [1147] phi info_rom::info_status#16 = STATUS_ISSUE [phi:info_cx16_rom->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z info_rom.info_status
    jsr info_rom
    // info_cx16_rom::@return
    // }
    // [1382] return 
    rts
}
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __zp($d9) char mapbase, __zp($d8) char config)
screenlayer: {
    .label screenlayer__1 = $d9
    .label screenlayer__5 = $d8
    .label screenlayer__6 = $d8
    .label mapbase = $d9
    .label config = $d8
    .label y = $d7
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [1383] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [1384] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [1385] *((char *)&__conio+2) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+2
    // mapbase >> 7
    // [1386] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbum1=vbuz2_ror_7 
    lda.z mapbase
    rol
    rol
    and #1
    sta screenlayer__0
    // __conio.mapbase_bank = mapbase >> 7
    // [1387] *((char *)&__conio+5) = screenlayer::$0 -- _deref_pbuc1=vbum1 
    sta __conio+5
    // (mapbase)<<1
    // [1388] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z screenlayer__1
    // MAKEWORD((mapbase)<<1,0)
    // [1389] screenlayer::$2 = screenlayer::$1 w= 0 -- vwum1=vbuz2_word_vbuc1 
    lda #0
    ldy.z screenlayer__1
    sty screenlayer__2+1
    sta screenlayer__2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [1390] *((unsigned int *)&__conio+3) = screenlayer::$2 -- _deref_pwuc1=vwum1 
    sta __conio+3
    tya
    sta __conio+3+1
    // config & VERA_LAYER_WIDTH_MASK
    // [1391] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbum1=vbuz2_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and.z config
    sta screenlayer__7
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [1392] screenlayer::$8 = screenlayer::$7 >> 4 -- vbum1=vbum1_ror_4 
    lda screenlayer__8
    lsr
    lsr
    lsr
    lsr
    sta screenlayer__8
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [1393] *((char *)&__conio+8) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbum1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+8
    // config & VERA_LAYER_HEIGHT_MASK
    // [1394] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbuz1=vbuz1_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and.z screenlayer__5
    sta.z screenlayer__5
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [1395] screenlayer::$6 = screenlayer::$5 >> 6 -- vbuz1=vbuz1_ror_6 
    lda.z screenlayer__6
    rol
    rol
    rol
    and #3
    sta.z screenlayer__6
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [1396] *((char *)&__conio+9) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+9
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [1397] screenlayer::$16 = screenlayer::$8 << 1 -- vbum1=vbum1_rol_1 
    asl screenlayer__16
    // [1398] *((unsigned int *)&__conio+$a) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbum1 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    ldy screenlayer__16
    lda VERA_LAYER_SKIP,y
    sta __conio+$a
    lda VERA_LAYER_SKIP+1,y
    sta __conio+$a+1
    // vera_dc_hscale_temp == 0x80
    // [1399] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vbom1=vbum2_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta screenlayer__9
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [1400] screenlayer::$18 = (char)screenlayer::$9
    // [1401] screenlayer::$10 = $28 << screenlayer::$18 -- vbum1=vbuc1_rol_vbum1 
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
    // [1402] screenlayer::$11 = screenlayer::$10 - 1 -- vbum1=vbum1_minus_1 
    dec screenlayer__11
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [1403] *((char *)&__conio+6) = screenlayer::$11 -- _deref_pbuc1=vbum1 
    lda screenlayer__11
    sta __conio+6
    // vera_dc_vscale_temp == 0x80
    // [1404] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vbom1=vbum2_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta screenlayer__12
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [1405] screenlayer::$19 = (char)screenlayer::$12
    // [1406] screenlayer::$13 = $1e << screenlayer::$19 -- vbum1=vbuc1_rol_vbum1 
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
    // [1407] screenlayer::$14 = screenlayer::$13 - 1 -- vbum1=vbum1_minus_1 
    dec screenlayer__14
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1408] *((char *)&__conio+7) = screenlayer::$14 -- _deref_pbuc1=vbum1 
    lda screenlayer__14
    sta __conio+7
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [1409] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta mapbase_offset
    lda __conio+3+1
    sta mapbase_offset+1
    // [1410] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [1410] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [1410] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [1411] if(screenlayer::y#2<=*((char *)&__conio+7)) goto screenlayer::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+7
    cmp.z y
    bcs __b2
    // screenlayer::@return
    // }
    // [1412] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [1413] screenlayer::$17 = screenlayer::y#2 << 1 -- vbum1=vbuz2_rol_1 
    lda.z y
    asl
    sta screenlayer__17
    // [1414] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbum1=vwum2 
    tay
    lda mapbase_offset
    sta __conio+$15,y
    lda mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [1415] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda mapbase_offset
    adc __conio+$a
    sta mapbase_offset
    lda mapbase_offset+1
    adc __conio+$a+1
    sta mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [1416] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [1410] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [1410] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [1410] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
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
    // [1417] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [1418] if(0!=((char *)&__conio+$f)[*((char *)&__conio+2)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [1419] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // [1420] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [1421] call gotoxy
    // [479] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [479] phi gotoxy::y#29 = 0 [phi:cscroll::@3->gotoxy#0] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.y
    // [479] phi gotoxy::x#29 = 0 [phi:cscroll::@3->gotoxy#1] -- vbuz1=vbuc1 
    sta.z gotoxy.x
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [1422] return 
    rts
    // [1423] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [1424] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [1425] gotoxy::y#3 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
    lda __conio+7
    sta.z gotoxy.y
    // [1426] call gotoxy
    // [479] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [479] phi gotoxy::y#29 = gotoxy::y#3 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [479] phi gotoxy::x#29 = 0 [phi:cscroll::@5->gotoxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.x
    jsr gotoxy
    // [1427] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [1428] call clearline
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
    // [1429] ((char *)&__conio+$f)[*((char *)&__conio+2)] = scroll::onoff#0 -- pbuc1_derefidx_(_deref_pbuc2)=vbuc3 
    lda #onoff
    ldy __conio+2
    sta __conio+$f,y
    // scroll::@return
    // }
    // [1430] return 
    rts
}
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    .label line_text = $6c
    .label ch = $6c
    // unsigned int line_text = __conio.mapbase_offset
    // [1431] clrscr::line_text#0 = *((unsigned int *)&__conio+3) -- vwuz1=_deref_pwuc1 
    lda __conio+3
    sta.z line_text
    lda __conio+3+1
    sta.z line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1432] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [1433] clrscr::$0 = *((char *)&__conio+5) | VERA_INC_1 -- vbum1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta clrscr__0
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1434] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [1435] clrscr::l#0 = *((char *)&__conio+9) -- vbum1=_deref_pbuc1 
    lda __conio+9
    sta l
    // [1436] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [1436] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [1436] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [1437] clrscr::$1 = byte0  clrscr::ch#0 -- vbum1=_byte0_vwuz2 
    lda.z ch
    sta clrscr__1
    // *VERA_ADDRX_L = BYTE0(ch)
    // [1438] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbum1 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [1439] clrscr::$2 = byte1  clrscr::ch#0 -- vbum1=_byte1_vwuz2 
    lda.z ch+1
    sta clrscr__2
    // *VERA_ADDRX_M = BYTE1(ch)
    // [1440] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth+1
    // [1441] clrscr::c#0 = *((char *)&__conio+8) + 1 -- vbum1=_deref_pbuc1_plus_1 
    lda __conio+8
    inc
    sta c
    // [1442] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [1442] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [1443] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1444] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [1445] clrscr::c#1 = -- clrscr::c#2 -- vbum1=_dec_vbum1 
    dec c
    // while(c)
    // [1446] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [1447] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+$a) -- vwuz1=vwuz1_plus__deref_pwuc1 
    clc
    lda.z line_text
    adc __conio+$a
    sta.z line_text
    lda.z line_text+1
    adc __conio+$a+1
    sta.z line_text+1
    // l--;
    // [1448] clrscr::l#1 = -- clrscr::l#4 -- vbum1=_dec_vbum1 
    dec l
    // while(l)
    // [1449] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbum1_then_la1 
    lda l
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [1450] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y = 0
    // [1451] *((char *)&__conio+1) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+1
    // __conio.offset = __conio.mapbase_offset
    // [1452] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+3) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+3
    sta __conio+$13
    lda __conio+3+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [1453] return 
    rts
  .segment Data
    .label clrscr__0 = frame.w
    .label clrscr__1 = frame.h
    .label clrscr__2 = info_clear.y
    .label l = main.check_vera2_main__0
    .label c = main.check_roms2_check_rom1_main__0
}
.segment Code
  // frame
// Draw a line horizontal from a given xy position and a given length.
// The line should calculate the matching characters to draw and glue them.
// So it first needs to peek the characters at the given position.
// And then calculate the resulting characters to draw.
// void frame(char x0, char y0, __zp($da) char x1, __zp($e4) char y1)
frame: {
    .label x = $d6
    .label y = $67
    .label c = $63
    .label x_1 = $6b
    .label y_1 = $df
    .label x1 = $da
    .label y1 = $e4
    // unsigned char w = x1 - x0
    // [1455] frame::w#0 = frame::x1#16 - frame::x#0 -- vbum1=vbuz2_minus_vbuz3 
    lda.z x1
    sec
    sbc.z x
    sta w
    // unsigned char h = y1 - y0
    // [1456] frame::h#0 = frame::y1#16 - frame::y#0 -- vbum1=vbuz2_minus_vbuz3 
    lda.z y1
    sec
    sbc.z y
    sta h
    // unsigned char mask = frame_maskxy(x, y)
    // [1457] frame_maskxy::x#0 = frame::x#0 -- vbum1=vbuz2 
    lda.z x
    sta frame_maskxy.x
    // [1458] frame_maskxy::y#0 = frame::y#0 -- vbum1=vbuz2 
    lda.z y
    sta frame_maskxy.y
    // [1459] call frame_maskxy
    // [2113] phi from frame to frame_maskxy [phi:frame->frame_maskxy]
    // [2113] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#0 [phi:frame->frame_maskxy#0] -- register_copy 
    // [2113] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#0 [phi:frame->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // unsigned char mask = frame_maskxy(x, y)
    // [1460] frame_maskxy::return#13 = frame_maskxy::return#12
    // frame::@13
    // [1461] frame::mask#0 = frame_maskxy::return#13
    // mask |= 0b0110
    // [1462] frame::mask#1 = frame::mask#0 | 6 -- vbum1=vbum1_bor_vbuc1 
    lda #6
    ora mask
    sta mask
    // unsigned char c = frame_char(mask)
    // [1463] frame_char::mask#0 = frame::mask#1
    // [1464] call frame_char
  // Add a corner.
    // [2139] phi from frame::@13 to frame_char [phi:frame::@13->frame_char]
    // [2139] phi frame_char::mask#10 = frame_char::mask#0 [phi:frame::@13->frame_char#0] -- register_copy 
    jsr frame_char
    // unsigned char c = frame_char(mask)
    // [1465] frame_char::return#13 = frame_char::return#12
    // frame::@14
    // [1466] frame::c#0 = frame_char::return#13
    // cputcxy(x, y, c)
    // [1467] cputcxy::x#0 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1468] cputcxy::y#0 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [1469] cputcxy::c#0 = frame::c#0
    // [1470] call cputcxy
    // [1588] phi from frame::@14 to cputcxy [phi:frame::@14->cputcxy]
    // [1588] phi cputcxy::c#13 = cputcxy::c#0 [phi:frame::@14->cputcxy#0] -- register_copy 
    // [1588] phi cputcxy::y#13 = cputcxy::y#0 [phi:frame::@14->cputcxy#1] -- register_copy 
    // [1588] phi cputcxy::x#13 = cputcxy::x#0 [phi:frame::@14->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@15
    // if(w>=2)
    // [1471] if(frame::w#0<2) goto frame::@36 -- vbum1_lt_vbuc1_then_la1 
    lda w
    cmp #2
    bcs !__b36+
    jmp __b36
  !__b36:
    // frame::@2
    // x++;
    // [1472] frame::x#1 = ++ frame::x#0 -- vbuz1=_inc_vbuz2 
    lda.z x
    inc
    sta.z x_1
    // [1473] phi from frame::@2 frame::@21 to frame::@4 [phi:frame::@2/frame::@21->frame::@4]
    // [1473] phi frame::x#10 = frame::x#1 [phi:frame::@2/frame::@21->frame::@4#0] -- register_copy 
    // frame::@4
  __b4:
    // while(x < x1)
    // [1474] if(frame::x#10<frame::x1#16) goto frame::@5 -- vbuz1_lt_vbuz2_then_la1 
    lda.z x_1
    cmp.z x1
    bcs !__b5+
    jmp __b5
  !__b5:
    // [1475] phi from frame::@36 frame::@4 to frame::@1 [phi:frame::@36/frame::@4->frame::@1]
    // [1475] phi frame::x#24 = frame::x#30 [phi:frame::@36/frame::@4->frame::@1#0] -- register_copy 
    // frame::@1
  __b1:
    // frame_maskxy(x, y)
    // [1476] frame_maskxy::x#1 = frame::x#24 -- vbum1=vbuz2 
    lda.z x_1
    sta frame_maskxy.x
    // [1477] frame_maskxy::y#1 = frame::y#0 -- vbum1=vbuz2 
    lda.z y
    sta frame_maskxy.y
    // [1478] call frame_maskxy
    // [2113] phi from frame::@1 to frame_maskxy [phi:frame::@1->frame_maskxy]
    // [2113] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#1 [phi:frame::@1->frame_maskxy#0] -- register_copy 
    // [2113] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#1 [phi:frame::@1->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [1479] frame_maskxy::return#14 = frame_maskxy::return#12
    // frame::@16
    // mask = frame_maskxy(x, y)
    // [1480] frame::mask#2 = frame_maskxy::return#14
    // mask |= 0b0011
    // [1481] frame::mask#3 = frame::mask#2 | 3 -- vbum1=vbum1_bor_vbuc1 
    lda #3
    ora mask
    sta mask
    // frame_char(mask)
    // [1482] frame_char::mask#1 = frame::mask#3
    // [1483] call frame_char
    // [2139] phi from frame::@16 to frame_char [phi:frame::@16->frame_char]
    // [2139] phi frame_char::mask#10 = frame_char::mask#1 [phi:frame::@16->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1484] frame_char::return#14 = frame_char::return#12
    // frame::@17
    // c = frame_char(mask)
    // [1485] frame::c#1 = frame_char::return#14
    // cputcxy(x, y, c)
    // [1486] cputcxy::x#1 = frame::x#24 -- vbuz1=vbuz2 
    lda.z x_1
    sta.z cputcxy.x
    // [1487] cputcxy::y#1 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [1488] cputcxy::c#1 = frame::c#1
    // [1489] call cputcxy
    // [1588] phi from frame::@17 to cputcxy [phi:frame::@17->cputcxy]
    // [1588] phi cputcxy::c#13 = cputcxy::c#1 [phi:frame::@17->cputcxy#0] -- register_copy 
    // [1588] phi cputcxy::y#13 = cputcxy::y#1 [phi:frame::@17->cputcxy#1] -- register_copy 
    // [1588] phi cputcxy::x#13 = cputcxy::x#1 [phi:frame::@17->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@18
    // if(h>=2)
    // [1490] if(frame::h#0<2) goto frame::@return -- vbum1_lt_vbuc1_then_la1 
    lda h
    cmp #2
    bcc __breturn
    // frame::@3
    // y++;
    // [1491] frame::y#1 = ++ frame::y#0 -- vbuz1=_inc_vbuz2 
    lda.z y
    inc
    sta.z y_1
    // [1492] phi from frame::@27 frame::@3 to frame::@6 [phi:frame::@27/frame::@3->frame::@6]
    // [1492] phi frame::y#10 = frame::y#2 [phi:frame::@27/frame::@3->frame::@6#0] -- register_copy 
    // frame::@6
  __b6:
    // while(y < y1)
    // [1493] if(frame::y#10<frame::y1#16) goto frame::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z y_1
    cmp.z y1
    bcc __b7
    // frame::@8
    // frame_maskxy(x, y)
    // [1494] frame_maskxy::x#5 = frame::x#0 -- vbum1=vbuz2 
    lda.z x
    sta frame_maskxy.x
    // [1495] frame_maskxy::y#5 = frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta frame_maskxy.y
    // [1496] call frame_maskxy
    // [2113] phi from frame::@8 to frame_maskxy [phi:frame::@8->frame_maskxy]
    // [2113] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#5 [phi:frame::@8->frame_maskxy#0] -- register_copy 
    // [2113] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#5 [phi:frame::@8->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [1497] frame_maskxy::return#18 = frame_maskxy::return#12
    // frame::@28
    // mask = frame_maskxy(x, y)
    // [1498] frame::mask#10 = frame_maskxy::return#18
    // mask |= 0b1100
    // [1499] frame::mask#11 = frame::mask#10 | $c -- vbum1=vbum1_bor_vbuc1 
    lda #$c
    ora mask
    sta mask
    // frame_char(mask)
    // [1500] frame_char::mask#5 = frame::mask#11
    // [1501] call frame_char
    // [2139] phi from frame::@28 to frame_char [phi:frame::@28->frame_char]
    // [2139] phi frame_char::mask#10 = frame_char::mask#5 [phi:frame::@28->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1502] frame_char::return#18 = frame_char::return#12
    // frame::@29
    // c = frame_char(mask)
    // [1503] frame::c#5 = frame_char::return#18
    // cputcxy(x, y, c)
    // [1504] cputcxy::x#5 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1505] cputcxy::y#5 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1506] cputcxy::c#5 = frame::c#5
    // [1507] call cputcxy
    // [1588] phi from frame::@29 to cputcxy [phi:frame::@29->cputcxy]
    // [1588] phi cputcxy::c#13 = cputcxy::c#5 [phi:frame::@29->cputcxy#0] -- register_copy 
    // [1588] phi cputcxy::y#13 = cputcxy::y#5 [phi:frame::@29->cputcxy#1] -- register_copy 
    // [1588] phi cputcxy::x#13 = cputcxy::x#5 [phi:frame::@29->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@30
    // if(w>=2)
    // [1508] if(frame::w#0<2) goto frame::@10 -- vbum1_lt_vbuc1_then_la1 
    lda w
    cmp #2
    bcc __b10
    // frame::@9
    // x++;
    // [1509] frame::x#4 = ++ frame::x#0 -- vbuz1=_inc_vbuz1 
    inc.z x
    // [1510] phi from frame::@35 frame::@9 to frame::@11 [phi:frame::@35/frame::@9->frame::@11]
    // [1510] phi frame::x#18 = frame::x#5 [phi:frame::@35/frame::@9->frame::@11#0] -- register_copy 
    // frame::@11
  __b11:
    // while(x < x1)
    // [1511] if(frame::x#18<frame::x1#16) goto frame::@12 -- vbuz1_lt_vbuz2_then_la1 
    lda.z x
    cmp.z x1
    bcc __b12
    // [1512] phi from frame::@11 frame::@30 to frame::@10 [phi:frame::@11/frame::@30->frame::@10]
    // [1512] phi frame::x#15 = frame::x#18 [phi:frame::@11/frame::@30->frame::@10#0] -- register_copy 
    // frame::@10
  __b10:
    // frame_maskxy(x, y)
    // [1513] frame_maskxy::x#6 = frame::x#15 -- vbum1=vbuz2 
    lda.z x
    sta frame_maskxy.x
    // [1514] frame_maskxy::y#6 = frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta frame_maskxy.y
    // [1515] call frame_maskxy
    // [2113] phi from frame::@10 to frame_maskxy [phi:frame::@10->frame_maskxy]
    // [2113] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#6 [phi:frame::@10->frame_maskxy#0] -- register_copy 
    // [2113] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#6 [phi:frame::@10->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [1516] frame_maskxy::return#19 = frame_maskxy::return#12
    // frame::@31
    // mask = frame_maskxy(x, y)
    // [1517] frame::mask#12 = frame_maskxy::return#19
    // mask |= 0b1001
    // [1518] frame::mask#13 = frame::mask#12 | 9 -- vbum1=vbum1_bor_vbuc1 
    lda #9
    ora mask
    sta mask
    // frame_char(mask)
    // [1519] frame_char::mask#6 = frame::mask#13
    // [1520] call frame_char
    // [2139] phi from frame::@31 to frame_char [phi:frame::@31->frame_char]
    // [2139] phi frame_char::mask#10 = frame_char::mask#6 [phi:frame::@31->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1521] frame_char::return#19 = frame_char::return#12
    // frame::@32
    // c = frame_char(mask)
    // [1522] frame::c#6 = frame_char::return#19
    // cputcxy(x, y, c)
    // [1523] cputcxy::x#6 = frame::x#15 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1524] cputcxy::y#6 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1525] cputcxy::c#6 = frame::c#6
    // [1526] call cputcxy
    // [1588] phi from frame::@32 to cputcxy [phi:frame::@32->cputcxy]
    // [1588] phi cputcxy::c#13 = cputcxy::c#6 [phi:frame::@32->cputcxy#0] -- register_copy 
    // [1588] phi cputcxy::y#13 = cputcxy::y#6 [phi:frame::@32->cputcxy#1] -- register_copy 
    // [1588] phi cputcxy::x#13 = cputcxy::x#6 [phi:frame::@32->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@return
  __breturn:
    // }
    // [1527] return 
    rts
    // frame::@12
  __b12:
    // frame_maskxy(x, y)
    // [1528] frame_maskxy::x#7 = frame::x#18 -- vbum1=vbuz2 
    lda.z x
    sta frame_maskxy.x
    // [1529] frame_maskxy::y#7 = frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta frame_maskxy.y
    // [1530] call frame_maskxy
    // [2113] phi from frame::@12 to frame_maskxy [phi:frame::@12->frame_maskxy]
    // [2113] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#7 [phi:frame::@12->frame_maskxy#0] -- register_copy 
    // [2113] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#7 [phi:frame::@12->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [1531] frame_maskxy::return#20 = frame_maskxy::return#12
    // frame::@33
    // mask = frame_maskxy(x, y)
    // [1532] frame::mask#14 = frame_maskxy::return#20
    // mask |= 0b0101
    // [1533] frame::mask#15 = frame::mask#14 | 5 -- vbum1=vbum1_bor_vbuc1 
    lda #5
    ora mask
    sta mask
    // frame_char(mask)
    // [1534] frame_char::mask#7 = frame::mask#15
    // [1535] call frame_char
    // [2139] phi from frame::@33 to frame_char [phi:frame::@33->frame_char]
    // [2139] phi frame_char::mask#10 = frame_char::mask#7 [phi:frame::@33->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1536] frame_char::return#20 = frame_char::return#12
    // frame::@34
    // c = frame_char(mask)
    // [1537] frame::c#7 = frame_char::return#20
    // cputcxy(x, y, c)
    // [1538] cputcxy::x#7 = frame::x#18 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1539] cputcxy::y#7 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1540] cputcxy::c#7 = frame::c#7
    // [1541] call cputcxy
    // [1588] phi from frame::@34 to cputcxy [phi:frame::@34->cputcxy]
    // [1588] phi cputcxy::c#13 = cputcxy::c#7 [phi:frame::@34->cputcxy#0] -- register_copy 
    // [1588] phi cputcxy::y#13 = cputcxy::y#7 [phi:frame::@34->cputcxy#1] -- register_copy 
    // [1588] phi cputcxy::x#13 = cputcxy::x#7 [phi:frame::@34->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@35
    // x++;
    // [1542] frame::x#5 = ++ frame::x#18 -- vbuz1=_inc_vbuz1 
    inc.z x
    jmp __b11
    // frame::@7
  __b7:
    // frame_maskxy(x0, y)
    // [1543] frame_maskxy::x#3 = frame::x#0 -- vbum1=vbuz2 
    lda.z x
    sta frame_maskxy.x
    // [1544] frame_maskxy::y#3 = frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta frame_maskxy.y
    // [1545] call frame_maskxy
    // [2113] phi from frame::@7 to frame_maskxy [phi:frame::@7->frame_maskxy]
    // [2113] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#3 [phi:frame::@7->frame_maskxy#0] -- register_copy 
    // [2113] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#3 [phi:frame::@7->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x0, y)
    // [1546] frame_maskxy::return#16 = frame_maskxy::return#12
    // frame::@22
    // mask = frame_maskxy(x0, y)
    // [1547] frame::mask#6 = frame_maskxy::return#16
    // mask |= 0b1010
    // [1548] frame::mask#7 = frame::mask#6 | $a -- vbum1=vbum1_bor_vbuc1 
    lda #$a
    ora mask
    sta mask
    // frame_char(mask)
    // [1549] frame_char::mask#3 = frame::mask#7
    // [1550] call frame_char
    // [2139] phi from frame::@22 to frame_char [phi:frame::@22->frame_char]
    // [2139] phi frame_char::mask#10 = frame_char::mask#3 [phi:frame::@22->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1551] frame_char::return#16 = frame_char::return#12
    // frame::@23
    // c = frame_char(mask)
    // [1552] frame::c#3 = frame_char::return#16
    // cputcxy(x0, y, c)
    // [1553] cputcxy::x#3 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1554] cputcxy::y#3 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1555] cputcxy::c#3 = frame::c#3
    // [1556] call cputcxy
    // [1588] phi from frame::@23 to cputcxy [phi:frame::@23->cputcxy]
    // [1588] phi cputcxy::c#13 = cputcxy::c#3 [phi:frame::@23->cputcxy#0] -- register_copy 
    // [1588] phi cputcxy::y#13 = cputcxy::y#3 [phi:frame::@23->cputcxy#1] -- register_copy 
    // [1588] phi cputcxy::x#13 = cputcxy::x#3 [phi:frame::@23->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@24
    // frame_maskxy(x1, y)
    // [1557] frame_maskxy::x#4 = frame::x1#16 -- vbum1=vbuz2 
    lda.z x1
    sta frame_maskxy.x
    // [1558] frame_maskxy::y#4 = frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta frame_maskxy.y
    // [1559] call frame_maskxy
    // [2113] phi from frame::@24 to frame_maskxy [phi:frame::@24->frame_maskxy]
    // [2113] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#4 [phi:frame::@24->frame_maskxy#0] -- register_copy 
    // [2113] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#4 [phi:frame::@24->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x1, y)
    // [1560] frame_maskxy::return#17 = frame_maskxy::return#12
    // frame::@25
    // mask = frame_maskxy(x1, y)
    // [1561] frame::mask#8 = frame_maskxy::return#17
    // mask |= 0b1010
    // [1562] frame::mask#9 = frame::mask#8 | $a -- vbum1=vbum1_bor_vbuc1 
    lda #$a
    ora mask
    sta mask
    // frame_char(mask)
    // [1563] frame_char::mask#4 = frame::mask#9
    // [1564] call frame_char
    // [2139] phi from frame::@25 to frame_char [phi:frame::@25->frame_char]
    // [2139] phi frame_char::mask#10 = frame_char::mask#4 [phi:frame::@25->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1565] frame_char::return#17 = frame_char::return#12
    // frame::@26
    // c = frame_char(mask)
    // [1566] frame::c#4 = frame_char::return#17
    // cputcxy(x1, y, c)
    // [1567] cputcxy::x#4 = frame::x1#16 -- vbuz1=vbuz2 
    lda.z x1
    sta.z cputcxy.x
    // [1568] cputcxy::y#4 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1569] cputcxy::c#4 = frame::c#4
    // [1570] call cputcxy
    // [1588] phi from frame::@26 to cputcxy [phi:frame::@26->cputcxy]
    // [1588] phi cputcxy::c#13 = cputcxy::c#4 [phi:frame::@26->cputcxy#0] -- register_copy 
    // [1588] phi cputcxy::y#13 = cputcxy::y#4 [phi:frame::@26->cputcxy#1] -- register_copy 
    // [1588] phi cputcxy::x#13 = cputcxy::x#4 [phi:frame::@26->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@27
    // y++;
    // [1571] frame::y#2 = ++ frame::y#10 -- vbuz1=_inc_vbuz1 
    inc.z y_1
    jmp __b6
    // frame::@5
  __b5:
    // frame_maskxy(x, y)
    // [1572] frame_maskxy::x#2 = frame::x#10 -- vbum1=vbuz2 
    lda.z x_1
    sta frame_maskxy.x
    // [1573] frame_maskxy::y#2 = frame::y#0 -- vbum1=vbuz2 
    lda.z y
    sta frame_maskxy.y
    // [1574] call frame_maskxy
    // [2113] phi from frame::@5 to frame_maskxy [phi:frame::@5->frame_maskxy]
    // [2113] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#2 [phi:frame::@5->frame_maskxy#0] -- register_copy 
    // [2113] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#2 [phi:frame::@5->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [1575] frame_maskxy::return#15 = frame_maskxy::return#12
    // frame::@19
    // mask = frame_maskxy(x, y)
    // [1576] frame::mask#4 = frame_maskxy::return#15
    // mask |= 0b0101
    // [1577] frame::mask#5 = frame::mask#4 | 5 -- vbum1=vbum1_bor_vbuc1 
    lda #5
    ora mask
    sta mask
    // frame_char(mask)
    // [1578] frame_char::mask#2 = frame::mask#5
    // [1579] call frame_char
    // [2139] phi from frame::@19 to frame_char [phi:frame::@19->frame_char]
    // [2139] phi frame_char::mask#10 = frame_char::mask#2 [phi:frame::@19->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1580] frame_char::return#15 = frame_char::return#12
    // frame::@20
    // c = frame_char(mask)
    // [1581] frame::c#2 = frame_char::return#15
    // cputcxy(x, y, c)
    // [1582] cputcxy::x#2 = frame::x#10 -- vbuz1=vbuz2 
    lda.z x_1
    sta.z cputcxy.x
    // [1583] cputcxy::y#2 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [1584] cputcxy::c#2 = frame::c#2
    // [1585] call cputcxy
    // [1588] phi from frame::@20 to cputcxy [phi:frame::@20->cputcxy]
    // [1588] phi cputcxy::c#13 = cputcxy::c#2 [phi:frame::@20->cputcxy#0] -- register_copy 
    // [1588] phi cputcxy::y#13 = cputcxy::y#2 [phi:frame::@20->cputcxy#1] -- register_copy 
    // [1588] phi cputcxy::x#13 = cputcxy::x#2 [phi:frame::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@21
    // x++;
    // [1586] frame::x#2 = ++ frame::x#10 -- vbuz1=_inc_vbuz1 
    inc.z x_1
    jmp __b4
    // frame::@36
  __b36:
    // [1587] frame::x#30 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z x_1
    jmp __b1
  .segment Data
    w: .byte 0
    h: .byte 0
    .label mask = frame_maskxy.return
}
.segment Code
  // cputcxy
// Move cursor and output one character
// Same as "gotoxy (x, y); cputc (c);"
// void cputcxy(__zp($b2) char x, __zp($66) char y, __zp($63) char c)
cputcxy: {
    .label x = $b2
    .label y = $66
    .label c = $63
    // gotoxy(x, y)
    // [1589] gotoxy::x#0 = cputcxy::x#13 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1590] gotoxy::y#0 = cputcxy::y#13 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1591] call gotoxy
    // [479] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [479] phi gotoxy::y#29 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [479] phi gotoxy::x#29 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [1592] stackpush(char) = cputcxy::c#13 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [1593] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [1595] return 
    rts
}
  // info_clear
// void info_clear(__mem() char l)
info_clear: {
    .const w = $40+1
    .label x = $6a
    .label i = $68
    // unsigned char y = INFO_Y+l
    // [1596] info_clear::y#0 = $11 + info_clear::l#0 -- vbum1=vbuc1_plus_vbum2 
    lda #$11
    clc
    adc l
    sta y
    // [1597] phi from info_clear to info_clear::@1 [phi:info_clear->info_clear::@1]
    // [1597] phi info_clear::x#2 = 2 [phi:info_clear->info_clear::@1#0] -- vbuz1=vbuc1 
    lda #2
    sta.z x
    // [1597] phi info_clear::i#2 = 0 [phi:info_clear->info_clear::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // info_clear::@1
  __b1:
    // for(unsigned char i = 0; i < w-16; i++)
    // [1598] if(info_clear::i#2<info_clear::w-$10) goto info_clear::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z i
    cmp #w-$10
    bcc __b2
    // info_clear::@3
    // gotoxy(INFO_X, y)
    // [1599] gotoxy::y#14 = info_clear::y#0 -- vbuz1=vbum2 
    lda y
    sta.z gotoxy.y
    // [1600] call gotoxy
    // [479] phi from info_clear::@3 to gotoxy [phi:info_clear::@3->gotoxy]
    // [479] phi gotoxy::y#29 = gotoxy::y#14 [phi:info_clear::@3->gotoxy#0] -- register_copy 
    // [479] phi gotoxy::x#29 = 2 [phi:info_clear::@3->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // info_clear::@return
    // }
    // [1601] return 
    rts
    // info_clear::@2
  __b2:
    // cputcxy(x, y, ' ')
    // [1602] cputcxy::x#10 = info_clear::x#2 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1603] cputcxy::y#10 = info_clear::y#0 -- vbuz1=vbum2 
    lda y
    sta.z cputcxy.y
    // [1604] call cputcxy
    // [1588] phi from info_clear::@2 to cputcxy [phi:info_clear::@2->cputcxy]
    // [1588] phi cputcxy::c#13 = ' ' [phi:info_clear::@2->cputcxy#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z cputcxy.c
    // [1588] phi cputcxy::y#13 = cputcxy::y#10 [phi:info_clear::@2->cputcxy#1] -- register_copy 
    // [1588] phi cputcxy::x#13 = cputcxy::x#10 [phi:info_clear::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // info_clear::@4
    // x++;
    // [1605] info_clear::x#1 = ++ info_clear::x#2 -- vbuz1=_inc_vbuz1 
    inc.z x
    // for(unsigned char i = 0; i < w-16; i++)
    // [1606] info_clear::i#1 = ++ info_clear::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1597] phi from info_clear::@4 to info_clear::@1 [phi:info_clear::@4->info_clear::@1]
    // [1597] phi info_clear::x#2 = info_clear::x#1 [phi:info_clear::@4->info_clear::@1#0] -- register_copy 
    // [1597] phi info_clear::i#2 = info_clear::i#1 [phi:info_clear::@4->info_clear::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    y: .byte 0
    .label l = main.check_smc3_main__0
}
.segment Code
  // wherex
// Return the x position of the cursor
wherex: {
    .label return = $33
    .label return_1 = $e2
    // return __conio.cursor_x;
    // [1607] wherex::return#0 = *((char *)&__conio) -- vbuz1=_deref_pbuc1 
    lda __conio
    sta.z return
    // wherex::@return
    // }
    // [1608] return 
    rts
}
  // wherey
// Return the y position of the cursor
wherey: {
    .label return = $24
    .label return_1 = $e0
    // return __conio.cursor_y;
    // [1609] wherey::return#0 = *((char *)&__conio+1) -- vbuz1=_deref_pbuc1 
    lda __conio+1
    sta.z return
    // wherey::@return
    // }
    // [1610] return 
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
// __zp($2a) unsigned int cx16_k_i2c_read_byte(__mem() volatile char device, __mem() volatile char offset)
cx16_k_i2c_read_byte: {
    .label return = $2a
    // unsigned int result
    // [1611] cx16_k_i2c_read_byte::result = 0 -- vwum1=vwuc1 
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
    // [1613] cx16_k_i2c_read_byte::return#0 = cx16_k_i2c_read_byte::result -- vwuz1=vwum2 
    sta.z return
    lda result+1
    sta.z return+1
    // cx16_k_i2c_read_byte::@return
    // }
    // [1614] cx16_k_i2c_read_byte::return#1 = cx16_k_i2c_read_byte::return#0
    // [1615] return 
    rts
  .segment Data
    device: .byte 0
    offset: .byte 0
    result: .word 0
}
.segment Code
  // print_smc_led
// void print_smc_led(__zp($4e) char c)
print_smc_led: {
    .label c = $4e
    // print_chip_led(CHIP_SMC_X+1, CHIP_SMC_Y, CHIP_SMC_W, c, BLUE)
    // [1617] print_chip_led::tc#0 = print_smc_led::c#2
    // [1618] call print_chip_led
    // [2154] phi from print_smc_led to print_chip_led [phi:print_smc_led->print_chip_led]
    // [2154] phi print_chip_led::w#5 = 5 [phi:print_smc_led->print_chip_led#0] -- vbuz1=vbuc1 
    lda #5
    sta.z print_chip_led.w
    // [2154] phi print_chip_led::tc#3 = print_chip_led::tc#0 [phi:print_smc_led->print_chip_led#1] -- register_copy 
    // [2154] phi print_chip_led::x#3 = 1+1 [phi:print_smc_led->print_chip_led#2] -- vbuz1=vbuc1 
    lda #1+1
    sta.z print_chip_led.x
    jsr print_chip_led
    // print_smc_led::@return
    // }
    // [1619] return 
    rts
}
  // print_chip
// void print_chip(__zp($b1) char x, char y, __zp($65) char w, __zp($3e) char *text)
print_chip: {
    .label y = 3+1+1+1+1+1+1+1+1+1
    .label text = $3e
    .label text_1 = $53
    .label x = $b1
    .label text_2 = $48
    .label text_6 = $6e
    .label w = $65
    // print_chip_line(x, y++, w, *text++)
    // [1621] print_chip_line::x#0 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1622] print_chip_line::w#0 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1623] print_chip_line::c#0 = *print_chip::text#11 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_2),y
    sta.z print_chip_line.c
    // [1624] call print_chip_line
    // [2172] phi from print_chip to print_chip_line [phi:print_chip->print_chip_line]
    // [2172] phi print_chip_line::c#15 = print_chip_line::c#0 [phi:print_chip->print_chip_line#0] -- register_copy 
    // [2172] phi print_chip_line::w#10 = print_chip_line::w#0 [phi:print_chip->print_chip_line#1] -- register_copy 
    // [2172] phi print_chip_line::y#16 = 3+1 [phi:print_chip->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1
    sta.z print_chip_line.y
    // [2172] phi print_chip_line::x#16 = print_chip_line::x#0 [phi:print_chip->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@1
    // print_chip_line(x, y++, w, *text++);
    // [1625] print_chip::text#0 = ++ print_chip::text#11 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_2
    adc #1
    sta.z text
    lda.z text_2+1
    adc #0
    sta.z text+1
    // print_chip_line(x, y++, w, *text++)
    // [1626] print_chip_line::x#1 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1627] print_chip_line::w#1 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1628] print_chip_line::c#1 = *print_chip::text#0 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text),y
    sta.z print_chip_line.c
    // [1629] call print_chip_line
    // [2172] phi from print_chip::@1 to print_chip_line [phi:print_chip::@1->print_chip_line]
    // [2172] phi print_chip_line::c#15 = print_chip_line::c#1 [phi:print_chip::@1->print_chip_line#0] -- register_copy 
    // [2172] phi print_chip_line::w#10 = print_chip_line::w#1 [phi:print_chip::@1->print_chip_line#1] -- register_copy 
    // [2172] phi print_chip_line::y#16 = ++3+1 [phi:print_chip::@1->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1
    sta.z print_chip_line.y
    // [2172] phi print_chip_line::x#16 = print_chip_line::x#1 [phi:print_chip::@1->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@2
    // print_chip_line(x, y++, w, *text++);
    // [1630] print_chip::text#1 = ++ print_chip::text#0 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text
    adc #1
    sta.z text_1
    lda.z text+1
    adc #0
    sta.z text_1+1
    // print_chip_line(x, y++, w, *text++)
    // [1631] print_chip_line::x#2 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1632] print_chip_line::w#2 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1633] print_chip_line::c#2 = *print_chip::text#1 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_1),y
    sta.z print_chip_line.c
    // [1634] call print_chip_line
    // [2172] phi from print_chip::@2 to print_chip_line [phi:print_chip::@2->print_chip_line]
    // [2172] phi print_chip_line::c#15 = print_chip_line::c#2 [phi:print_chip::@2->print_chip_line#0] -- register_copy 
    // [2172] phi print_chip_line::w#10 = print_chip_line::w#2 [phi:print_chip::@2->print_chip_line#1] -- register_copy 
    // [2172] phi print_chip_line::y#16 = ++++3+1 [phi:print_chip::@2->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1
    sta.z print_chip_line.y
    // [2172] phi print_chip_line::x#16 = print_chip_line::x#2 [phi:print_chip::@2->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@3
    // print_chip_line(x, y++, w, *text++);
    // [1635] print_chip::text#15 = ++ print_chip::text#1 -- pbum1=_inc_pbuz2 
    clc
    lda.z text_1
    adc #1
    sta text_3
    lda.z text_1+1
    adc #0
    sta text_3+1
    // print_chip_line(x, y++, w, *text++)
    // [1636] print_chip_line::x#3 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1637] print_chip_line::w#3 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1638] print_chip_line::c#3 = *print_chip::text#15 -- vbuz1=_deref_pbum2 
    ldy text_3
    sty.z $fe
    ldy text_3+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta.z print_chip_line.c
    // [1639] call print_chip_line
    // [2172] phi from print_chip::@3 to print_chip_line [phi:print_chip::@3->print_chip_line]
    // [2172] phi print_chip_line::c#15 = print_chip_line::c#3 [phi:print_chip::@3->print_chip_line#0] -- register_copy 
    // [2172] phi print_chip_line::w#10 = print_chip_line::w#3 [phi:print_chip::@3->print_chip_line#1] -- register_copy 
    // [2172] phi print_chip_line::y#16 = ++++++3+1 [phi:print_chip::@3->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1+1
    sta.z print_chip_line.y
    // [2172] phi print_chip_line::x#16 = print_chip_line::x#3 [phi:print_chip::@3->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@4
    // print_chip_line(x, y++, w, *text++);
    // [1640] print_chip::text#16 = ++ print_chip::text#15 -- pbum1=_inc_pbum2 
    clc
    lda text_3
    adc #1
    sta text_4
    lda text_3+1
    adc #0
    sta text_4+1
    // print_chip_line(x, y++, w, *text++)
    // [1641] print_chip_line::x#4 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1642] print_chip_line::w#4 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1643] print_chip_line::c#4 = *print_chip::text#16 -- vbuz1=_deref_pbum2 
    ldy text_4
    sty.z $fe
    ldy text_4+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta.z print_chip_line.c
    // [1644] call print_chip_line
    // [2172] phi from print_chip::@4 to print_chip_line [phi:print_chip::@4->print_chip_line]
    // [2172] phi print_chip_line::c#15 = print_chip_line::c#4 [phi:print_chip::@4->print_chip_line#0] -- register_copy 
    // [2172] phi print_chip_line::w#10 = print_chip_line::w#4 [phi:print_chip::@4->print_chip_line#1] -- register_copy 
    // [2172] phi print_chip_line::y#16 = ++++++++3+1 [phi:print_chip::@4->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1+1+1
    sta.z print_chip_line.y
    // [2172] phi print_chip_line::x#16 = print_chip_line::x#4 [phi:print_chip::@4->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@5
    // print_chip_line(x, y++, w, *text++);
    // [1645] print_chip::text#17 = ++ print_chip::text#16 -- pbum1=_inc_pbum2 
    clc
    lda text_4
    adc #1
    sta text_5
    lda text_4+1
    adc #0
    sta text_5+1
    // print_chip_line(x, y++, w, *text++)
    // [1646] print_chip_line::x#5 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1647] print_chip_line::w#5 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1648] print_chip_line::c#5 = *print_chip::text#17 -- vbuz1=_deref_pbum2 
    ldy text_5
    sty.z $fe
    ldy text_5+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta.z print_chip_line.c
    // [1649] call print_chip_line
    // [2172] phi from print_chip::@5 to print_chip_line [phi:print_chip::@5->print_chip_line]
    // [2172] phi print_chip_line::c#15 = print_chip_line::c#5 [phi:print_chip::@5->print_chip_line#0] -- register_copy 
    // [2172] phi print_chip_line::w#10 = print_chip_line::w#5 [phi:print_chip::@5->print_chip_line#1] -- register_copy 
    // [2172] phi print_chip_line::y#16 = ++++++++++3+1 [phi:print_chip::@5->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1+1+1+1
    sta.z print_chip_line.y
    // [2172] phi print_chip_line::x#16 = print_chip_line::x#5 [phi:print_chip::@5->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@6
    // print_chip_line(x, y++, w, *text++);
    // [1650] print_chip::text#18 = ++ print_chip::text#17 -- pbuz1=_inc_pbum2 
    clc
    lda text_5
    adc #1
    sta.z text_6
    lda text_5+1
    adc #0
    sta.z text_6+1
    // print_chip_line(x, y++, w, *text++)
    // [1651] print_chip_line::x#6 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1652] print_chip_line::w#6 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1653] print_chip_line::c#6 = *print_chip::text#18 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta.z print_chip_line.c
    // [1654] call print_chip_line
    // [2172] phi from print_chip::@6 to print_chip_line [phi:print_chip::@6->print_chip_line]
    // [2172] phi print_chip_line::c#15 = print_chip_line::c#6 [phi:print_chip::@6->print_chip_line#0] -- register_copy 
    // [2172] phi print_chip_line::w#10 = print_chip_line::w#6 [phi:print_chip::@6->print_chip_line#1] -- register_copy 
    // [2172] phi print_chip_line::y#16 = ++++++++++++3+1 [phi:print_chip::@6->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1+1+1+1+1
    sta.z print_chip_line.y
    // [2172] phi print_chip_line::x#16 = print_chip_line::x#6 [phi:print_chip::@6->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@7
    // print_chip_line(x, y++, w, *text++);
    // [1655] print_chip::text#19 = ++ print_chip::text#18 -- pbuz1=_inc_pbuz1 
    inc.z text_6
    bne !+
    inc.z text_6+1
  !:
    // print_chip_line(x, y++, w, *text++)
    // [1656] print_chip_line::x#7 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1657] print_chip_line::w#7 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1658] print_chip_line::c#7 = *print_chip::text#19 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta.z print_chip_line.c
    // [1659] call print_chip_line
    // [2172] phi from print_chip::@7 to print_chip_line [phi:print_chip::@7->print_chip_line]
    // [2172] phi print_chip_line::c#15 = print_chip_line::c#7 [phi:print_chip::@7->print_chip_line#0] -- register_copy 
    // [2172] phi print_chip_line::w#10 = print_chip_line::w#7 [phi:print_chip::@7->print_chip_line#1] -- register_copy 
    // [2172] phi print_chip_line::y#16 = ++++++++++++++3+1 [phi:print_chip::@7->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1+1+1+1+1+1
    sta.z print_chip_line.y
    // [2172] phi print_chip_line::x#16 = print_chip_line::x#7 [phi:print_chip::@7->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@8
    // print_chip_end(x, y++, w)
    // [1660] print_chip_end::x#0 = print_chip::x#10
    // [1661] print_chip_end::w#0 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_end.w
    // [1662] call print_chip_end
    jsr print_chip_end
    // print_chip::@return
    // }
    // [1663] return 
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
// void utoa(__zp($2a) unsigned int value, __zp($61) char *buffer, __zp($32) char radix)
utoa: {
    .label utoa__4 = $69
    .label utoa__10 = $63
    .label utoa__11 = $66
    .label digit_value = $3e
    .label buffer = $61
    .label digit = $67
    .label value = $2a
    .label radix = $32
    .label started = $6b
    .label max_digits = $b5
    .label digit_values = $5d
    // if(radix==DECIMAL)
    // [1664] if(utoa::radix#0==DECIMAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp.z radix
    beq __b2
    // utoa::@2
    // if(radix==HEXADECIMAL)
    // [1665] if(utoa::radix#0==HEXADECIMAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp.z radix
    beq __b3
    // utoa::@3
    // if(radix==OCTAL)
    // [1666] if(utoa::radix#0==OCTAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp.z radix
    beq __b4
    // utoa::@4
    // if(radix==BINARY)
    // [1667] if(utoa::radix#0==BINARY) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp.z radix
    beq __b5
    // utoa::@5
    // *buffer++ = 'e'
    // [1668] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1669] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1670] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1671] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // utoa::@return
    // }
    // [1672] return 
    rts
    // [1673] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
  __b2:
    // [1673] phi utoa::digit_values#8 = RADIX_DECIMAL_VALUES [phi:utoa->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_DECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES
    sta.z digit_values+1
    // [1673] phi utoa::max_digits#7 = 5 [phi:utoa->utoa::@1#1] -- vbuz1=vbuc1 
    lda #5
    sta.z max_digits
    jmp __b1
    // [1673] phi from utoa::@2 to utoa::@1 [phi:utoa::@2->utoa::@1]
  __b3:
    // [1673] phi utoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES [phi:utoa::@2->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_HEXADECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES
    sta.z digit_values+1
    // [1673] phi utoa::max_digits#7 = 4 [phi:utoa::@2->utoa::@1#1] -- vbuz1=vbuc1 
    lda #4
    sta.z max_digits
    jmp __b1
    // [1673] phi from utoa::@3 to utoa::@1 [phi:utoa::@3->utoa::@1]
  __b4:
    // [1673] phi utoa::digit_values#8 = RADIX_OCTAL_VALUES [phi:utoa::@3->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_OCTAL_VALUES
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES
    sta.z digit_values+1
    // [1673] phi utoa::max_digits#7 = 6 [phi:utoa::@3->utoa::@1#1] -- vbuz1=vbuc1 
    lda #6
    sta.z max_digits
    jmp __b1
    // [1673] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
  __b5:
    // [1673] phi utoa::digit_values#8 = RADIX_BINARY_VALUES [phi:utoa::@4->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_BINARY_VALUES
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES
    sta.z digit_values+1
    // [1673] phi utoa::max_digits#7 = $10 [phi:utoa::@4->utoa::@1#1] -- vbuz1=vbuc1 
    lda #$10
    sta.z max_digits
    // utoa::@1
  __b1:
    // [1674] phi from utoa::@1 to utoa::@6 [phi:utoa::@1->utoa::@6]
    // [1674] phi utoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa::@1->utoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1674] phi utoa::started#2 = 0 [phi:utoa::@1->utoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [1674] phi utoa::value#2 = utoa::value#1 [phi:utoa::@1->utoa::@6#2] -- register_copy 
    // [1674] phi utoa::digit#2 = 0 [phi:utoa::@1->utoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // utoa::@6
  __b6:
    // max_digits-1
    // [1675] utoa::$4 = utoa::max_digits#7 - 1 -- vbuz1=vbuz2_minus_1 
    ldx.z max_digits
    dex
    stx.z utoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1676] if(utoa::digit#2<utoa::$4) goto utoa::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z digit
    cmp.z utoa__4
    bcc __b7
    // utoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1677] utoa::$11 = (char)utoa::value#2 -- vbuz1=_byte_vwuz2 
    lda.z value
    sta.z utoa__11
    // [1678] *utoa::buffer#11 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1679] utoa::buffer#3 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1680] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // utoa::@7
  __b7:
    // unsigned int digit_value = digit_values[digit]
    // [1681] utoa::$10 = utoa::digit#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z digit
    asl
    sta.z utoa__10
    // [1682] utoa::digit_value#0 = utoa::digit_values#8[utoa::$10] -- vwuz1=pwuz2_derefidx_vbuz3 
    tay
    lda (digit_values),y
    sta.z digit_value
    iny
    lda (digit_values),y
    sta.z digit_value+1
    // if (started || value >= digit_value)
    // [1683] if(0!=utoa::started#2) goto utoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // utoa::@12
    // [1684] if(utoa::value#2>=utoa::digit_value#0) goto utoa::@10 -- vwuz1_ge_vwuz2_then_la1 
    lda.z digit_value+1
    cmp.z value+1
    bne !+
    lda.z digit_value
    cmp.z value
    beq __b10
  !:
    bcc __b10
    // [1685] phi from utoa::@12 to utoa::@9 [phi:utoa::@12->utoa::@9]
    // [1685] phi utoa::buffer#14 = utoa::buffer#11 [phi:utoa::@12->utoa::@9#0] -- register_copy 
    // [1685] phi utoa::started#4 = utoa::started#2 [phi:utoa::@12->utoa::@9#1] -- register_copy 
    // [1685] phi utoa::value#6 = utoa::value#2 [phi:utoa::@12->utoa::@9#2] -- register_copy 
    // utoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1686] utoa::digit#1 = ++ utoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1674] phi from utoa::@9 to utoa::@6 [phi:utoa::@9->utoa::@6]
    // [1674] phi utoa::buffer#11 = utoa::buffer#14 [phi:utoa::@9->utoa::@6#0] -- register_copy 
    // [1674] phi utoa::started#2 = utoa::started#4 [phi:utoa::@9->utoa::@6#1] -- register_copy 
    // [1674] phi utoa::value#2 = utoa::value#6 [phi:utoa::@9->utoa::@6#2] -- register_copy 
    // [1674] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@9->utoa::@6#3] -- register_copy 
    jmp __b6
    // utoa::@10
  __b10:
    // utoa_append(buffer++, value, digit_value)
    // [1687] utoa_append::buffer#0 = utoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [1688] utoa_append::value#0 = utoa::value#2
    // [1689] utoa_append::sub#0 = utoa::digit_value#0
    // [1690] call utoa_append
    // [2233] phi from utoa::@10 to utoa_append [phi:utoa::@10->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [1691] utoa_append::return#0 = utoa_append::value#2
    // utoa::@11
    // value = utoa_append(buffer++, value, digit_value)
    // [1692] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [1693] utoa::buffer#4 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1685] phi from utoa::@11 to utoa::@9 [phi:utoa::@11->utoa::@9]
    // [1685] phi utoa::buffer#14 = utoa::buffer#4 [phi:utoa::@11->utoa::@9#0] -- register_copy 
    // [1685] phi utoa::started#4 = 1 [phi:utoa::@11->utoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [1685] phi utoa::value#6 = utoa::value#0 [phi:utoa::@11->utoa::@9#2] -- register_copy 
    jmp __b9
}
  // printf_number_buffer
// Print the contents of the number buffer using a specific format.
// This handles minimum length, zero-filling, and left/right justification from the format
// void printf_number_buffer(__zp($4a) void (*putc)(char), __zp($df) char buffer_sign, char *buffer_digits, __zp($de) char format_min_length, char format_justify_left, char format_sign_always, __zp($dd) char format_zero_padding, char format_upper_case, char format_radix)
printf_number_buffer: {
    .label printf_number_buffer__19 = $53
    .label putc = $4a
    .label buffer_sign = $df
    .label format_min_length = $de
    .label format_zero_padding = $dd
    .label len = $d6
    .label padding = $d6
    // if(format.min_length)
    // [1695] if(0==printf_number_buffer::format_min_length#3) goto printf_number_buffer::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b5
    // [1696] phi from printf_number_buffer to printf_number_buffer::@5 [phi:printf_number_buffer->printf_number_buffer::@5]
    // printf_number_buffer::@5
    // strlen(buffer.digits)
    // [1697] call strlen
    // [1975] phi from printf_number_buffer::@5 to strlen [phi:printf_number_buffer::@5->strlen]
    // [1975] phi strlen::str#8 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [1698] strlen::return#3 = strlen::len#2
    // printf_number_buffer::@11
    // [1699] printf_number_buffer::$19 = strlen::return#3
    // signed char len = (signed char)strlen(buffer.digits)
    // [1700] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsz1=_sbyte_vwuz2 
    // There is a minimum length - work out the padding
    lda.z printf_number_buffer__19
    sta.z len
    // if(buffer.sign)
    // [1701] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@10 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b10
    // printf_number_buffer::@6
    // len++;
    // [1702] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsz1=_inc_vbsz1 
    inc.z len
    // [1703] phi from printf_number_buffer::@11 printf_number_buffer::@6 to printf_number_buffer::@10 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10]
    // [1703] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10#0] -- register_copy 
    // printf_number_buffer::@10
  __b10:
    // padding = (signed char)format.min_length - len
    // [1704] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#3 - printf_number_buffer::len#2 -- vbsz1=vbsz2_minus_vbsz1 
    lda.z format_min_length
    sec
    sbc.z padding
    sta.z padding
    // if(padding<0)
    // [1705] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@15 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1707] phi from printf_number_buffer printf_number_buffer::@10 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1]
  __b5:
    // [1707] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [1706] phi from printf_number_buffer::@10 to printf_number_buffer::@15 [phi:printf_number_buffer::@10->printf_number_buffer::@15]
    // printf_number_buffer::@15
    // [1707] phi from printf_number_buffer::@15 to printf_number_buffer::@1 [phi:printf_number_buffer::@15->printf_number_buffer::@1]
    // [1707] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@15->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // printf_number_buffer::@13
    // if(!format.justify_left && !format.zero_padding && padding)
    // [1708] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_zero_padding
    bne __b2
    // printf_number_buffer::@12
    // [1709] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@7 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b7
    jmp __b2
    // printf_number_buffer::@7
  __b7:
    // printf_padding(putc, ' ',(char)padding)
    // [1710] printf_padding::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1711] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1712] call printf_padding
    // [1981] phi from printf_number_buffer::@7 to printf_padding [phi:printf_number_buffer::@7->printf_padding]
    // [1981] phi printf_padding::putc#7 = printf_padding::putc#0 [phi:printf_number_buffer::@7->printf_padding#0] -- register_copy 
    // [1981] phi printf_padding::pad#7 = ' ' [phi:printf_number_buffer::@7->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1981] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@7->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [1713] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b3
    // printf_number_buffer::@8
    // putc(buffer.sign)
    // [1714] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbuz1 
    pha
    // [1715] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall30
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [1717] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbuz1_then_la1 
    lda.z format_zero_padding
    beq __b4
    // printf_number_buffer::@14
    // [1718] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@9 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b9
    jmp __b4
    // printf_number_buffer::@9
  __b9:
    // printf_padding(putc, '0',(char)padding)
    // [1719] printf_padding::putc#1 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1720] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1721] call printf_padding
    // [1981] phi from printf_number_buffer::@9 to printf_padding [phi:printf_number_buffer::@9->printf_padding]
    // [1981] phi printf_padding::putc#7 = printf_padding::putc#1 [phi:printf_number_buffer::@9->printf_padding#0] -- register_copy 
    // [1981] phi printf_padding::pad#7 = '0' [phi:printf_number_buffer::@9->printf_padding#1] -- vbuz1=vbuc1 
    lda #'0'
    sta.z printf_padding.pad
    // [1981] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@9->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // printf_str(putc, buffer.digits)
    // [1722] printf_str::putc#0 = printf_number_buffer::putc#10
    // [1723] call printf_str
    // [623] phi from printf_number_buffer::@4 to printf_str [phi:printf_number_buffer::@4->printf_str]
    // [623] phi printf_str::putc#66 = printf_str::putc#0 [phi:printf_number_buffer::@4->printf_str#0] -- register_copy 
    // [623] phi printf_str::s#66 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@return
    // }
    // [1724] return 
    rts
    // Outside Flow
  icall30:
    jmp (putc)
}
  // print_vera_led
// void print_vera_led(__zp($4e) char c)
print_vera_led: {
    .label c = $4e
    // print_chip_led(CHIP_VERA_X+1, CHIP_VERA_Y, CHIP_VERA_W, c, BLUE)
    // [1726] print_chip_led::tc#1 = print_vera_led::c#2
    // [1727] call print_chip_led
    // [2154] phi from print_vera_led to print_chip_led [phi:print_vera_led->print_chip_led]
    // [2154] phi print_chip_led::w#5 = 8 [phi:print_vera_led->print_chip_led#0] -- vbuz1=vbuc1 
    lda #8
    sta.z print_chip_led.w
    // [2154] phi print_chip_led::tc#3 = print_chip_led::tc#1 [phi:print_vera_led->print_chip_led#1] -- register_copy 
    // [2154] phi print_chip_led::x#3 = 9+1 [phi:print_vera_led->print_chip_led#2] -- vbuz1=vbuc1 
    lda #9+1
    sta.z print_chip_led.x
    jsr print_chip_led
    // print_vera_led::@return
    // }
    // [1728] return 
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
// void rom_unlock(__zp($71) unsigned long address, __zp($7f) char unlock_code)
rom_unlock: {
    .label chip_address = $3a
    .label address = $71
    .label unlock_code = $7f
    // unsigned long chip_address = address & ROM_CHIP_MASK
    // [1730] rom_unlock::chip_address#0 = rom_unlock::address#5 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [1731] rom_write_byte::address#0 = rom_unlock::chip_address#0 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [1732] call rom_write_byte
  // This is a very important operation...
    // [2240] phi from rom_unlock to rom_write_byte [phi:rom_unlock->rom_write_byte]
    // [2240] phi rom_write_byte::value#10 = $aa [phi:rom_unlock->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$aa
    sta.z rom_write_byte.value
    // [2240] phi rom_write_byte::address#4 = rom_write_byte::address#0 [phi:rom_unlock->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@1
    // rom_write_byte(chip_address + 0x02AAA, 0x55)
    // [1733] rom_write_byte::address#1 = rom_unlock::chip_address#0 + $2aaa -- vduz1=vduz2_plus_vwuc1 
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
    // [1734] call rom_write_byte
    // [2240] phi from rom_unlock::@1 to rom_write_byte [phi:rom_unlock::@1->rom_write_byte]
    // [2240] phi rom_write_byte::value#10 = $55 [phi:rom_unlock::@1->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$55
    sta.z rom_write_byte.value
    // [2240] phi rom_write_byte::address#4 = rom_write_byte::address#1 [phi:rom_unlock::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@2
    // rom_write_byte(address, unlock_code)
    // [1735] rom_write_byte::address#2 = rom_unlock::address#5 -- vduz1=vduz2 
    lda.z address
    sta.z rom_write_byte.address
    lda.z address+1
    sta.z rom_write_byte.address+1
    lda.z address+2
    sta.z rom_write_byte.address+2
    lda.z address+3
    sta.z rom_write_byte.address+3
    // [1736] rom_write_byte::value#2 = rom_unlock::unlock_code#5 -- vbuz1=vbuz2 
    lda.z unlock_code
    sta.z rom_write_byte.value
    // [1737] call rom_write_byte
    // [2240] phi from rom_unlock::@2 to rom_write_byte [phi:rom_unlock::@2->rom_write_byte]
    // [2240] phi rom_write_byte::value#10 = rom_write_byte::value#2 [phi:rom_unlock::@2->rom_write_byte#0] -- register_copy 
    // [2240] phi rom_write_byte::address#4 = rom_write_byte::address#2 [phi:rom_unlock::@2->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@return
    // }
    // [1738] return 
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
// __zp($24) char rom_read_byte(__zp($bd) unsigned long address)
rom_read_byte: {
    .label rom_bank1_rom_read_byte__0 = $66
    .label rom_bank1_rom_read_byte__1 = $63
    .label rom_ptr1_rom_read_byte__0 = $f2
    .label rom_ptr1_rom_read_byte__2 = $f2
    .label rom_bank1_return = $7f
    .label rom_ptr1_return = $f2
    .label return = $24
    .label address = $bd
    // rom_read_byte::rom_bank1
    // BYTE2(address)
    // [1740] rom_read_byte::rom_bank1_$0 = byte2  rom_read_byte::address#2 -- vbuz1=_byte2_vduz2 
    lda.z address+2
    sta.z rom_bank1_rom_read_byte__0
    // BYTE1(address)
    // [1741] rom_read_byte::rom_bank1_$1 = byte1  rom_read_byte::address#2 -- vbuz1=_byte1_vduz2 
    lda.z address+1
    sta.z rom_bank1_rom_read_byte__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [1742] rom_read_byte::rom_bank1_$2 = rom_read_byte::rom_bank1_$0 w= rom_read_byte::rom_bank1_$1 -- vwum1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_read_byte__0
    sta rom_bank1_rom_read_byte__2+1
    lda.z rom_bank1_rom_read_byte__1
    sta rom_bank1_rom_read_byte__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [1743] rom_read_byte::rom_bank1_bank_unshifted#0 = rom_read_byte::rom_bank1_$2 << 2 -- vwum1=vwum1_rol_2 
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [1744] rom_read_byte::rom_bank1_return#0 = byte1  rom_read_byte::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwum2 
    lda rom_bank1_bank_unshifted+1
    sta.z rom_bank1_return
    // rom_read_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [1745] rom_read_byte::rom_ptr1_$2 = (unsigned int)rom_read_byte::address#2 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_read_byte__2
    lda.z address+1
    sta.z rom_ptr1_rom_read_byte__2+1
    // [1746] rom_read_byte::rom_ptr1_$0 = rom_read_byte::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_read_byte__0
    and #<$3fff
    sta.z rom_ptr1_rom_read_byte__0
    lda.z rom_ptr1_rom_read_byte__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_read_byte__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [1747] rom_read_byte::rom_ptr1_return#0 = rom_read_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_read_byte::bank_set_brom1
    // BROM = bank
    // [1748] BROM = rom_read_byte::rom_bank1_return#0 -- vbuz1=vbuz2 
    lda.z rom_bank1_return
    sta.z BROM
    // rom_read_byte::@1
    // return *ptr_rom;
    // [1749] rom_read_byte::return#0 = *((char *)rom_read_byte::rom_ptr1_return#0) -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (rom_ptr1_return),y
    sta.z return
    // rom_read_byte::@return
    // }
    // [1750] return 
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
    .label src = $f9
    // [1752] phi from strcpy strcpy::@2 to strcpy::@1 [phi:strcpy/strcpy::@2->strcpy::@1]
    // [1752] phi strcpy::dst#2 = strcpy::dst#0 [phi:strcpy/strcpy::@2->strcpy::@1#0] -- register_copy 
    // [1752] phi strcpy::src#2 = strcpy::src#0 [phi:strcpy/strcpy::@2->strcpy::@1#1] -- register_copy 
    // strcpy::@1
  __b1:
    // while(*src)
    // [1753] if(0!=*strcpy::src#2) goto strcpy::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcpy::@3
    // *dst = 0
    // [1754] *strcpy::dst#2 = 0 -- _deref_pbum1=vbuc1 
    tya
    ldy dst
    sty.z $fe
    ldy dst+1
    sty.z $ff
    tay
    sta ($fe),y
    // strcpy::@return
    // }
    // [1755] return 
    rts
    // strcpy::@2
  __b2:
    // *dst++ = *src++
    // [1756] *strcpy::dst#2 = *strcpy::src#2 -- _deref_pbum1=_deref_pbuz2 
    ldy #0
    lda (src),y
    ldy dst
    sty.z $fe
    ldy dst+1
    sty.z $ff
    ldy #0
    sta ($fe),y
    // *dst++ = *src++;
    // [1757] strcpy::dst#1 = ++ strcpy::dst#2 -- pbum1=_inc_pbum1 
    inc dst
    bne !+
    inc dst+1
  !:
    // [1758] strcpy::src#1 = ++ strcpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    jmp __b1
  .segment Data
    dst: .word 0
}
.segment Code
  // strcat
// Concatenates the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcat(char *destination, __zp($38) char *source)
strcat: {
    .label strcat__0 = $53
    .label dst = $53
    .label src = $38
    .label source = $38
    // strlen(destination)
    // [1760] call strlen
    // [1975] phi from strcat to strlen [phi:strcat->strlen]
    // [1975] phi strlen::str#8 = chip_rom::rom [phi:strcat->strlen#0] -- pbuz1=pbuc1 
    lda #<chip_rom.rom
    sta.z strlen.str
    lda #>chip_rom.rom
    sta.z strlen.str+1
    jsr strlen
    // strlen(destination)
    // [1761] strlen::return#0 = strlen::len#2
    // strcat::@4
    // [1762] strcat::$0 = strlen::return#0
    // char* dst = destination + strlen(destination)
    // [1763] strcat::dst#0 = chip_rom::rom + strcat::$0 -- pbuz1=pbuc1_plus_vwuz1 
    lda.z dst
    clc
    adc #<chip_rom.rom
    sta.z dst
    lda.z dst+1
    adc #>chip_rom.rom
    sta.z dst+1
    // [1764] phi from strcat::@2 strcat::@4 to strcat::@1 [phi:strcat::@2/strcat::@4->strcat::@1]
    // [1764] phi strcat::dst#2 = strcat::dst#1 [phi:strcat::@2/strcat::@4->strcat::@1#0] -- register_copy 
    // [1764] phi strcat::src#2 = strcat::src#1 [phi:strcat::@2/strcat::@4->strcat::@1#1] -- register_copy 
    // strcat::@1
  __b1:
    // while(*src)
    // [1765] if(0!=*strcat::src#2) goto strcat::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcat::@3
    // *dst = 0
    // [1766] *strcat::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcat::@return
    // }
    // [1767] return 
    rts
    // strcat::@2
  __b2:
    // *dst++ = *src++
    // [1768] *strcat::dst#2 = *strcat::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [1769] strcat::dst#1 = ++ strcat::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [1770] strcat::src#1 = ++ strcat::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    jmp __b1
}
  // print_rom_led
// void print_rom_led(__zp($70) char chip, __zp($4e) char c)
print_rom_led: {
    .label print_rom_led__0 = $70
    .label chip = $70
    .label c = $4e
    .label print_rom_led__4 = $7f
    .label print_rom_led__5 = $70
    // chip*6
    // [1772] print_rom_led::$4 = print_rom_led::chip#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z chip
    asl
    sta.z print_rom_led__4
    // [1773] print_rom_led::$5 = print_rom_led::$4 + print_rom_led::chip#2 -- vbuz1=vbuz2_plus_vbuz1 
    lda.z print_rom_led__5
    clc
    adc.z print_rom_led__4
    sta.z print_rom_led__5
    // CHIP_ROM_X+chip*6
    // [1774] print_rom_led::$0 = print_rom_led::$5 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z print_rom_led__0
    // print_chip_led(CHIP_ROM_X+chip*6+1, CHIP_ROM_Y, CHIP_ROM_W, c, BLUE)
    // [1775] print_chip_led::x#2 = print_rom_led::$0 + $14+1 -- vbuz1=vbuz1_plus_vbuc1 
    lda #$14+1
    clc
    adc.z print_chip_led.x
    sta.z print_chip_led.x
    // [1776] print_chip_led::tc#2 = print_rom_led::c#2
    // [1777] call print_chip_led
    // [2154] phi from print_rom_led to print_chip_led [phi:print_rom_led->print_chip_led]
    // [2154] phi print_chip_led::w#5 = 3 [phi:print_rom_led->print_chip_led#0] -- vbuz1=vbuc1 
    lda #3
    sta.z print_chip_led.w
    // [2154] phi print_chip_led::tc#3 = print_chip_led::tc#2 [phi:print_rom_led->print_chip_led#1] -- register_copy 
    // [2154] phi print_chip_led::x#3 = print_chip_led::x#2 [phi:print_rom_led->print_chip_led#2] -- register_copy 
    jsr print_chip_led
    // print_rom_led::@return
    // }
    // [1778] return 
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
// __zp($3e) struct $2 * fopen(__zp($d3) const char *path, const char *mode)
fopen: {
    .label fopen__4 = $4e
    .label fopen__9 = $b1
    .label fopen__15 = $65
    .label fopen__26 = $c1
    .label fopen__30 = $3e
    .label cbm_k_setnam1_fopen__0 = $53
    .label sp = $68
    .label stream = $3e
    .label pathtoken = $d3
    .label pathpos = $6a
    .label pathpos_1 = $50
    .label path = $d3
    // Parse path
    .label pathstep = $59
    .label num = $5c
    .label cbm_k_readst1_return = $65
    .label return = $3e
    // unsigned char sp = __stdio_filecount
    // [1780] fopen::sp#0 = __stdio_filecount -- vbuz1=vbum2 
    lda __stdio_filecount
    sta.z sp
    // (unsigned int)sp | 0x8000
    // [1781] fopen::$30 = (unsigned int)fopen::sp#0 -- vwuz1=_word_vbuz2 
    sta.z fopen__30
    lda #0
    sta.z fopen__30+1
    // [1782] fopen::stream#0 = fopen::$30 | $8000 -- vwuz1=vwuz1_bor_vwuc1 
    lda.z stream
    ora #<$8000
    sta.z stream
    lda.z stream+1
    ora #>$8000
    sta.z stream+1
    // char pathpos = sp * __STDIO_FILECOUNT
    // [1783] fopen::pathpos#0 = fopen::sp#0 << 3 -- vbuz1=vbuz2_rol_3 
    lda.z sp
    asl
    asl
    asl
    sta.z pathpos
    // __logical = 0
    // [1784] ((char *)&__stdio_file+$100)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    ldy.z sp
    sta __stdio_file+$100,y
    // __device = 0
    // [1785] ((char *)&__stdio_file+$108)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$108,y
    // __channel = 0
    // [1786] ((char *)&__stdio_file+$110)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$110,y
    // [1787] fopen::pathtoken#21 = fopen::pathtoken#0 -- pbum1=pbuz2 
    lda.z pathtoken
    sta pathtoken_1
    lda.z pathtoken+1
    sta pathtoken_1+1
    // [1788] fopen::pathpos#21 = fopen::pathpos#0 -- vbuz1=vbuz2 
    lda.z pathpos
    sta.z pathpos_1
    // [1789] phi from fopen to fopen::@8 [phi:fopen->fopen::@8]
    // [1789] phi fopen::num#10 = 0 [phi:fopen->fopen::@8#0] -- vbuz1=vbuc1 
    lda #0
    sta.z num
    // [1789] phi fopen::pathpos#10 = fopen::pathpos#21 [phi:fopen->fopen::@8#1] -- register_copy 
    // [1789] phi fopen::path#10 = fopen::pathtoken#0 [phi:fopen->fopen::@8#2] -- register_copy 
    // [1789] phi fopen::pathstep#10 = 0 [phi:fopen->fopen::@8#3] -- vbuz1=vbuc1 
    sta.z pathstep
    // [1789] phi fopen::pathtoken#10 = fopen::pathtoken#21 [phi:fopen->fopen::@8#4] -- register_copy 
  // Iterate while path is not \0.
    // [1789] phi from fopen::@22 to fopen::@8 [phi:fopen::@22->fopen::@8]
    // [1789] phi fopen::num#10 = fopen::num#13 [phi:fopen::@22->fopen::@8#0] -- register_copy 
    // [1789] phi fopen::pathpos#10 = fopen::pathpos#7 [phi:fopen::@22->fopen::@8#1] -- register_copy 
    // [1789] phi fopen::path#10 = fopen::path#11 [phi:fopen::@22->fopen::@8#2] -- register_copy 
    // [1789] phi fopen::pathstep#10 = fopen::pathstep#11 [phi:fopen::@22->fopen::@8#3] -- register_copy 
    // [1789] phi fopen::pathtoken#10 = fopen::pathtoken#1 [phi:fopen::@22->fopen::@8#4] -- register_copy 
    // fopen::@8
  __b8:
    // if (*pathtoken == ',' || *pathtoken == '\0')
    // [1790] if(*fopen::pathtoken#10==',') goto fopen::@9 -- _deref_pbum1_eq_vbuc1_then_la1 
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
    // [1791] if(*fopen::pathtoken#10=='@') goto fopen::@9 -- _deref_pbum1_eq_vbuc1_then_la1 
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
    // [1792] if(fopen::pathstep#10!=0) goto fopen::@10 -- vbuz1_neq_0_then_la1 
    lda.z pathstep
    bne __b10
    // fopen::@24
    // __stdio_file.filename[pathpos] = *pathtoken
    // [1793] ((char *)&__stdio_file)[fopen::pathpos#10] = *fopen::pathtoken#10 -- pbuc1_derefidx_vbuz1=_deref_pbum2 
    ldy pathtoken_1
    sty.z $fe
    ldy pathtoken_1+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    ldy.z pathpos_1
    sta __stdio_file,y
    // pathpos++;
    // [1794] fopen::pathpos#1 = ++ fopen::pathpos#10 -- vbuz1=_inc_vbuz1 
    inc.z pathpos_1
    // [1795] phi from fopen::@12 fopen::@23 fopen::@24 to fopen::@10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10]
    // [1795] phi fopen::num#13 = fopen::num#15 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#0] -- register_copy 
    // [1795] phi fopen::pathpos#7 = fopen::pathpos#10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#1] -- register_copy 
    // [1795] phi fopen::path#11 = fopen::path#13 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#2] -- register_copy 
    // [1795] phi fopen::pathstep#11 = fopen::pathstep#1 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#3] -- register_copy 
    // fopen::@10
  __b10:
    // pathtoken++;
    // [1796] fopen::pathtoken#1 = ++ fopen::pathtoken#10 -- pbum1=_inc_pbum1 
    inc pathtoken_1
    bne !+
    inc pathtoken_1+1
  !:
    // fopen::@22
    // pathtoken - 1
    // [1797] fopen::$28 = fopen::pathtoken#1 - 1 -- pbum1=pbum2_minus_1 
    lda pathtoken_1
    sec
    sbc #1
    sta fopen__28
    lda pathtoken_1+1
    sbc #0
    sta fopen__28+1
    // while (*(pathtoken - 1))
    // [1798] if(0!=*fopen::$28) goto fopen::@8 -- 0_neq__deref_pbum1_then_la1 
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
    // [1799] ((char *)&__stdio_file+$118)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    tya
    ldy.z sp
    sta __stdio_file+$118,y
    // if(!__logical)
    // [1800] if(0!=((char *)&__stdio_file+$100)[fopen::sp#0]) goto fopen::@1 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$100,y
    cmp #0
    bne __b1
    // fopen::@27
    // __stdio_filecount+1
    // [1801] fopen::$4 = __stdio_filecount + 1 -- vbuz1=vbum2_plus_1 
    lda __stdio_filecount
    inc
    sta.z fopen__4
    // __logical = __stdio_filecount+1
    // [1802] ((char *)&__stdio_file+$100)[fopen::sp#0] = fopen::$4 -- pbuc1_derefidx_vbuz1=vbuz2 
    sta __stdio_file+$100,y
    // fopen::@1
  __b1:
    // if(!__device)
    // [1803] if(0!=((char *)&__stdio_file+$108)[fopen::sp#0]) goto fopen::@2 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    ldy.z sp
    lda __stdio_file+$108,y
    cmp #0
    bne __b2
    // fopen::@5
    // __device = 8
    // [1804] ((char *)&__stdio_file+$108)[fopen::sp#0] = 8 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #8
    sta __stdio_file+$108,y
    // fopen::@2
  __b2:
    // if(!__channel)
    // [1805] if(0!=((char *)&__stdio_file+$110)[fopen::sp#0]) goto fopen::@3 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    ldy.z sp
    lda __stdio_file+$110,y
    cmp #0
    bne __b3
    // fopen::@6
    // __stdio_filecount+2
    // [1806] fopen::$9 = __stdio_filecount + 2 -- vbuz1=vbum2_plus_2 
    lda __stdio_filecount
    clc
    adc #2
    sta.z fopen__9
    // __channel = __stdio_filecount+2
    // [1807] ((char *)&__stdio_file+$110)[fopen::sp#0] = fopen::$9 -- pbuc1_derefidx_vbuz1=vbuz2 
    sta __stdio_file+$110,y
    // fopen::@3
  __b3:
    // __filename
    // [1808] fopen::$11 = (char *)&__stdio_file + fopen::pathpos#0 -- pbum1=pbuc1_plus_vbuz2 
    lda.z pathpos
    clc
    adc #<__stdio_file
    sta fopen__11
    lda #>__stdio_file
    adc #0
    sta fopen__11+1
    // cbm_k_setnam(__filename)
    // [1809] fopen::cbm_k_setnam1_filename = fopen::$11 -- pbum1=pbum2 
    lda fopen__11
    sta cbm_k_setnam1_filename
    lda fopen__11+1
    sta cbm_k_setnam1_filename+1
    // fopen::cbm_k_setnam1
    // strlen(filename)
    // [1810] strlen::str#4 = fopen::cbm_k_setnam1_filename -- pbuz1=pbum2 
    lda cbm_k_setnam1_filename
    sta.z strlen.str
    lda cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [1811] call strlen
    // [1975] phi from fopen::cbm_k_setnam1 to strlen [phi:fopen::cbm_k_setnam1->strlen]
    // [1975] phi strlen::str#8 = strlen::str#4 [phi:fopen::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [1812] strlen::return#11 = strlen::len#2
    // fopen::@31
    // [1813] fopen::cbm_k_setnam1_$0 = strlen::return#11
    // char filename_len = (char)strlen(filename)
    // [1814] fopen::cbm_k_setnam1_filename_len = (char)fopen::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
    lda.z cbm_k_setnam1_fopen__0
    sta cbm_k_setnam1_filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx cbm_k_setnam1_filename
    ldy cbm_k_setnam1_filename+1
    jsr CBM_SETNAM
    // fopen::@28
    // cbm_k_setlfs(__logical, __device, __channel)
    // [1816] cbm_k_setlfs::channel = ((char *)&__stdio_file+$100)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$100,y
    sta cbm_k_setlfs.channel
    // [1817] cbm_k_setlfs::device = ((char *)&__stdio_file+$108)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    lda __stdio_file+$108,y
    sta cbm_k_setlfs.device
    // [1818] cbm_k_setlfs::command = ((char *)&__stdio_file+$110)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    lda __stdio_file+$110,y
    sta cbm_k_setlfs.command
    // [1819] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // fopen::cbm_k_open1
    // asm
    // asm { jsrCBM_OPEN  }
    jsr CBM_OPEN
    // fopen::cbm_k_readst1
    // char status
    // [1821] fopen::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [1823] fopen::cbm_k_readst1_return#0 = fopen::cbm_k_readst1_status -- vbuz1=vbum2 
    sta.z cbm_k_readst1_return
    // fopen::cbm_k_readst1_@return
    // }
    // [1824] fopen::cbm_k_readst1_return#1 = fopen::cbm_k_readst1_return#0
    // fopen::@29
    // cbm_k_readst()
    // [1825] fopen::$15 = fopen::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [1826] ((char *)&__stdio_file+$118)[fopen::sp#0] = fopen::$15 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fopen__15
    ldy.z sp
    sta __stdio_file+$118,y
    // ferror(stream)
    // [1827] ferror::stream#0 = (struct $2 *)fopen::stream#0
    // [1828] call ferror
    jsr ferror
    // [1829] ferror::return#0 = ferror::return#1
    // fopen::@32
    // [1830] fopen::$16 = ferror::return#0
    // if (ferror(stream))
    // [1831] if(0==fopen::$16) goto fopen::@4 -- 0_eq_vwsm1_then_la1 
    lda fopen__16
    ora fopen__16+1
    beq __b4
    // fopen::@7
    // cbm_k_close(__logical)
    // [1832] fopen::cbm_k_close1_channel = ((char *)&__stdio_file+$100)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$100,y
    sta cbm_k_close1_channel
    // fopen::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // [1834] phi from fopen::cbm_k_close1 to fopen::@return [phi:fopen::cbm_k_close1->fopen::@return]
    // [1834] phi fopen::return#2 = 0 [phi:fopen::cbm_k_close1->fopen::@return#0] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [1835] return 
    rts
    // fopen::@4
  __b4:
    // __stdio_filecount++;
    // [1836] __stdio_filecount = ++ __stdio_filecount -- vbum1=_inc_vbum1 
    inc __stdio_filecount
    // [1837] fopen::return#8 = (struct $2 *)fopen::stream#0
    // [1834] phi from fopen::@4 to fopen::@return [phi:fopen::@4->fopen::@return]
    // [1834] phi fopen::return#2 = fopen::return#8 [phi:fopen::@4->fopen::@return#0] -- register_copy 
    rts
    // fopen::@9
  __b9:
    // if (pathstep > 0)
    // [1838] if(fopen::pathstep#10>0) goto fopen::@11 -- vbuz1_gt_0_then_la1 
    lda.z pathstep
    bne __b11
    // fopen::@25
    // __stdio_file.filename[pathpos] = '\0'
    // [1839] ((char *)&__stdio_file)[fopen::pathpos#10] = '@' -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #'@'
    ldy.z pathpos_1
    sta __stdio_file,y
    // path = pathtoken + 1
    // [1840] fopen::path#0 = fopen::pathtoken#10 + 1 -- pbuz1=pbum2_plus_1 
    clc
    lda pathtoken_1
    adc #1
    sta.z path
    lda pathtoken_1+1
    adc #0
    sta.z path+1
    // [1841] phi from fopen::@16 fopen::@17 fopen::@18 fopen::@19 fopen::@25 to fopen::@12 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12]
    // [1841] phi fopen::num#15 = fopen::num#2 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#0] -- register_copy 
    // [1841] phi fopen::path#13 = fopen::path#16 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#1] -- register_copy 
    // fopen::@12
  __b12:
    // pathstep++;
    // [1842] fopen::pathstep#1 = ++ fopen::pathstep#10 -- vbuz1=_inc_vbuz1 
    inc.z pathstep
    jmp __b10
    // fopen::@11
  __b11:
    // char pathcmp = *path
    // [1843] fopen::pathcmp#0 = *fopen::path#10 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (path),y
    sta pathcmp
    // case 'D':
    // [1844] if(fopen::pathcmp#0=='D') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'D'
    cmp pathcmp
    beq __b13
    // fopen::@20
    // case 'L':
    // [1845] if(fopen::pathcmp#0=='L') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'L'
    cmp pathcmp
    beq __b13
    // fopen::@21
    // case 'C':
    //                     num = (char)atoi(path + 1);
    //                     path = pathtoken + 1;
    // [1846] if(fopen::pathcmp#0=='C') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'C'
    cmp pathcmp
    beq __b13
    // [1847] phi from fopen::@21 fopen::@30 to fopen::@14 [phi:fopen::@21/fopen::@30->fopen::@14]
    // [1847] phi fopen::path#16 = fopen::path#10 [phi:fopen::@21/fopen::@30->fopen::@14#0] -- register_copy 
    // [1847] phi fopen::num#2 = fopen::num#10 [phi:fopen::@21/fopen::@30->fopen::@14#1] -- register_copy 
    // fopen::@14
  __b14:
    // case 'L':
    //                     __logical = num;
    //                     break;
    // [1848] if(fopen::pathcmp#0=='L') goto fopen::@17 -- vbum1_eq_vbuc1_then_la1 
    lda #'L'
    cmp pathcmp
    beq __b17
    // fopen::@15
    // case 'D':
    //                     __device = num;
    //                     break;
    // [1849] if(fopen::pathcmp#0=='D') goto fopen::@18 -- vbum1_eq_vbuc1_then_la1 
    lda #'D'
    cmp pathcmp
    beq __b18
    // fopen::@16
    // case 'C':
    //                     __channel = num;
    //                     break;
    // [1850] if(fopen::pathcmp#0!='C') goto fopen::@12 -- vbum1_neq_vbuc1_then_la1 
    lda #'C'
    cmp pathcmp
    bne __b12
    // fopen::@19
    // __channel = num
    // [1851] ((char *)&__stdio_file+$110)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z num
    ldy.z sp
    sta __stdio_file+$110,y
    jmp __b12
    // fopen::@18
  __b18:
    // __device = num
    // [1852] ((char *)&__stdio_file+$108)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z num
    ldy.z sp
    sta __stdio_file+$108,y
    jmp __b12
    // fopen::@17
  __b17:
    // __logical = num
    // [1853] ((char *)&__stdio_file+$100)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z num
    ldy.z sp
    sta __stdio_file+$100,y
    jmp __b12
    // fopen::@13
  __b13:
    // atoi(path + 1)
    // [1854] atoi::str#0 = fopen::path#10 + 1 -- pbuz1=pbuz1_plus_1 
    inc.z atoi.str
    bne !+
    inc.z atoi.str+1
  !:
    // [1855] call atoi
    // [2306] phi from fopen::@13 to atoi [phi:fopen::@13->atoi]
    // [2306] phi atoi::str#2 = atoi::str#0 [phi:fopen::@13->atoi#0] -- register_copy 
    jsr atoi
    // atoi(path + 1)
    // [1856] atoi::return#3 = atoi::return#2
    // fopen::@30
    // [1857] fopen::$26 = atoi::return#3
    // num = (char)atoi(path + 1)
    // [1858] fopen::num#1 = (char)fopen::$26 -- vbuz1=_byte_vwsz2 
    lda.z fopen__26
    sta.z num
    // path = pathtoken + 1
    // [1859] fopen::path#1 = fopen::pathtoken#10 + 1 -- pbuz1=pbum2_plus_1 
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
    .label pathcmp = fclose.sp
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
// __zp($a9) unsigned int fgets(__zp($b8) char *ptr, __zp($d1) unsigned int size, __mem() struct $2 *stream)
fgets: {
    .label fgets__1 = $6a
    .label fgets__8 = $4e
    .label fgets__9 = $b1
    .label fgets__13 = $65
    .label cbm_k_chkin1_channel = $f4
    .label cbm_k_chkin1_status = $ee
    .label cbm_k_readst1_status = $ef
    .label cbm_k_readst2_status = $bc
    .label sp = $68
    .label cbm_k_readst1_return = $6a
    .label return = $a9
    .label bytes = $76
    .label cbm_k_readst2_return = $4e
    .label read = $a9
    .label ptr = $b8
    .label remaining = $c5
    .label size = $d1
    // unsigned char sp = (unsigned char)stream
    // [1861] fgets::sp#0 = (char)fgets::stream#2 -- vbuz1=_byte_pssm2 
    lda stream
    sta.z sp
    // cbm_k_chkin(__logical)
    // [1862] fgets::cbm_k_chkin1_channel = ((char *)&__stdio_file+$100)[fgets::sp#0] -- vbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda __stdio_file+$100,y
    sta.z cbm_k_chkin1_channel
    // fgets::cbm_k_chkin1
    // char status
    // [1863] fgets::cbm_k_chkin1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fgets::cbm_k_readst1
    // char status
    // [1865] fgets::cbm_k_readst1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [1867] fgets::cbm_k_readst1_return#0 = fgets::cbm_k_readst1_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst1_return
    // fgets::cbm_k_readst1_@return
    // }
    // [1868] fgets::cbm_k_readst1_return#1 = fgets::cbm_k_readst1_return#0
    // fgets::@11
    // cbm_k_readst()
    // [1869] fgets::$1 = fgets::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [1870] ((char *)&__stdio_file+$118)[fgets::sp#0] = fgets::$1 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fgets__1
    ldy.z sp
    sta __stdio_file+$118,y
    // if (__status)
    // [1871] if(0==((char *)&__stdio_file+$118)[fgets::sp#0]) goto fgets::@1 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$118,y
    cmp #0
    beq __b1
    // [1872] phi from fgets::@11 fgets::@12 fgets::@5 to fgets::@return [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return]
  __b8:
    // [1872] phi fgets::return#1 = 0 [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return#0] -- vwuz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fgets::@return
    // }
    // [1873] return 
    rts
    // fgets::@1
  __b1:
    // [1874] fgets::remaining#22 = fgets::size#10 -- vwuz1=vwuz2 
    lda.z size
    sta.z remaining
    lda.z size+1
    sta.z remaining+1
    // [1875] phi from fgets::@1 to fgets::@2 [phi:fgets::@1->fgets::@2]
    // [1875] phi fgets::read#10 = 0 [phi:fgets::@1->fgets::@2#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z read
    sta.z read+1
    // [1875] phi fgets::remaining#11 = fgets::remaining#22 [phi:fgets::@1->fgets::@2#1] -- register_copy 
    // [1875] phi fgets::ptr#10 = fgets::ptr#12 [phi:fgets::@1->fgets::@2#2] -- register_copy 
    // [1875] phi from fgets::@17 fgets::@18 to fgets::@2 [phi:fgets::@17/fgets::@18->fgets::@2]
    // [1875] phi fgets::read#10 = fgets::read#1 [phi:fgets::@17/fgets::@18->fgets::@2#0] -- register_copy 
    // [1875] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@17/fgets::@18->fgets::@2#1] -- register_copy 
    // [1875] phi fgets::ptr#10 = fgets::ptr#13 [phi:fgets::@17/fgets::@18->fgets::@2#2] -- register_copy 
    // fgets::@2
  __b2:
    // if (!size)
    // [1876] if(0==fgets::size#10) goto fgets::@3 -- 0_eq_vwuz1_then_la1 
    lda.z size
    ora.z size+1
    bne !__b3+
    jmp __b3
  !__b3:
    // fgets::@8
    // if (remaining >= 512)
    // [1877] if(fgets::remaining#11>=$200) goto fgets::@4 -- vwuz1_ge_vwuc1_then_la1 
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
    // [1878] cx16_k_macptr::bytes = fgets::remaining#11 -- vbuz1=vwuz2 
    lda.z remaining
    sta.z cx16_k_macptr.bytes
    // [1879] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [1880] call cx16_k_macptr
    jsr cx16_k_macptr
    // [1881] cx16_k_macptr::return#4 = cx16_k_macptr::return#1
    // fgets::@15
  __b15:
    // bytes = cx16_k_macptr(remaining, ptr)
    // [1882] fgets::bytes#3 = cx16_k_macptr::return#4
    // [1883] phi from fgets::@13 fgets::@14 fgets::@15 to fgets::cbm_k_readst2 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2]
    // [1883] phi fgets::bytes#10 = fgets::bytes#1 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2#0] -- register_copy 
    // fgets::cbm_k_readst2
    // char status
    // [1884] fgets::cbm_k_readst2_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [1886] fgets::cbm_k_readst2_return#0 = fgets::cbm_k_readst2_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst2_return
    // fgets::cbm_k_readst2_@return
    // }
    // [1887] fgets::cbm_k_readst2_return#1 = fgets::cbm_k_readst2_return#0
    // fgets::@12
    // cbm_k_readst()
    // [1888] fgets::$8 = fgets::cbm_k_readst2_return#1
    // __status = cbm_k_readst()
    // [1889] ((char *)&__stdio_file+$118)[fgets::sp#0] = fgets::$8 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fgets__8
    ldy.z sp
    sta __stdio_file+$118,y
    // __status & 0xBF
    // [1890] fgets::$9 = ((char *)&__stdio_file+$118)[fgets::sp#0] & $bf -- vbuz1=pbuc1_derefidx_vbuz2_band_vbuc2 
    lda #$bf
    and __stdio_file+$118,y
    sta.z fgets__9
    // if (__status & 0xBF)
    // [1891] if(0==fgets::$9) goto fgets::@5 -- 0_eq_vbuz1_then_la1 
    beq __b5
    jmp __b8
    // fgets::@5
  __b5:
    // if (bytes == 0xFFFF)
    // [1892] if(fgets::bytes#10!=$ffff) goto fgets::@6 -- vwuz1_neq_vwuc1_then_la1 
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
    // [1893] fgets::read#1 = fgets::read#10 + fgets::bytes#10 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z read
    adc.z bytes
    sta.z read
    lda.z read+1
    adc.z bytes+1
    sta.z read+1
    // ptr += bytes
    // [1894] fgets::ptr#0 = fgets::ptr#10 + fgets::bytes#10 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z ptr
    adc.z bytes
    sta.z ptr
    lda.z ptr+1
    adc.z bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [1895] fgets::$13 = byte1  fgets::ptr#0 -- vbuz1=_byte1_pbuz2 
    sta.z fgets__13
    // if (BYTE1(ptr) == 0xC0)
    // [1896] if(fgets::$13!=$c0) goto fgets::@7 -- vbuz1_neq_vbuc1_then_la1 
    lda #$c0
    cmp.z fgets__13
    bne __b7
    // fgets::@10
    // ptr -= 0x2000
    // [1897] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [1898] phi from fgets::@10 fgets::@6 to fgets::@7 [phi:fgets::@10/fgets::@6->fgets::@7]
    // [1898] phi fgets::ptr#13 = fgets::ptr#1 [phi:fgets::@10/fgets::@6->fgets::@7#0] -- register_copy 
    // fgets::@7
  __b7:
    // remaining -= bytes
    // [1899] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#10 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z remaining
    sec
    sbc.z bytes
    sta.z remaining
    lda.z remaining+1
    sbc.z bytes+1
    sta.z remaining+1
    // while ((__status == 0) && ((size && remaining) || !size))
    // [1900] if(((char *)&__stdio_file+$118)[fgets::sp#0]==0) goto fgets::@16 -- pbuc1_derefidx_vbuz1_eq_0_then_la1 
    ldy.z sp
    lda __stdio_file+$118,y
    cmp #0
    beq __b16
    // [1872] phi from fgets::@17 fgets::@7 to fgets::@return [phi:fgets::@17/fgets::@7->fgets::@return]
    // [1872] phi fgets::return#1 = fgets::read#1 [phi:fgets::@17/fgets::@7->fgets::@return#0] -- register_copy 
    rts
    // fgets::@16
  __b16:
    // while ((__status == 0) && ((size && remaining) || !size))
    // [1901] if(0==fgets::size#10) goto fgets::@17 -- 0_eq_vwuz1_then_la1 
    lda.z size
    ora.z size+1
    beq __b17
    // fgets::@18
    // [1902] if(0!=fgets::remaining#1) goto fgets::@2 -- 0_neq_vwuz1_then_la1 
    lda.z remaining
    ora.z remaining+1
    beq !__b2+
    jmp __b2
  !__b2:
    // fgets::@17
  __b17:
    // [1903] if(0==fgets::size#10) goto fgets::@2 -- 0_eq_vwuz1_then_la1 
    lda.z size
    ora.z size+1
    bne !__b2+
    jmp __b2
  !__b2:
    rts
    // fgets::@4
  __b4:
    // cx16_k_macptr(512, ptr)
    // [1904] cx16_k_macptr::bytes = $200 -- vbuz1=vwuc1 
    lda #<$200
    sta.z cx16_k_macptr.bytes
    // [1905] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [1906] call cx16_k_macptr
    jsr cx16_k_macptr
    // [1907] cx16_k_macptr::return#3 = cx16_k_macptr::return#1
    // fgets::@14
    // bytes = cx16_k_macptr(512, ptr)
    // [1908] fgets::bytes#2 = cx16_k_macptr::return#3
    jmp __b15
    // fgets::@3
  __b3:
    // cx16_k_macptr(0, ptr)
    // [1909] cx16_k_macptr::bytes = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cx16_k_macptr.bytes
    // [1910] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [1911] call cx16_k_macptr
    jsr cx16_k_macptr
    // [1912] cx16_k_macptr::return#2 = cx16_k_macptr::return#1
    // fgets::@13
    // bytes = cx16_k_macptr(0, ptr)
    // [1913] fgets::bytes#1 = cx16_k_macptr::return#2
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
// int fclose(__zp($b6) struct $2 *stream)
fclose: {
    .label fclose__1 = $64
    .label fclose__4 = $2c
    .label cbm_k_readst1_return = $64
    .label cbm_k_readst2_return = $2c
    .label stream = $b6
    // unsigned char sp = (unsigned char)stream
    // [1915] fclose::sp#0 = (char)fclose::stream#2 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_chkin(__logical)
    // [1916] fclose::cbm_k_chkin1_channel = ((char *)&__stdio_file+$100)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    tay
    lda __stdio_file+$100,y
    sta cbm_k_chkin1_channel
    // fclose::cbm_k_chkin1
    // char status
    // [1917] fclose::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fclose::cbm_k_readst1
    // char status
    // [1919] fclose::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [1921] fclose::cbm_k_readst1_return#0 = fclose::cbm_k_readst1_status -- vbuz1=vbum2 
    sta.z cbm_k_readst1_return
    // fclose::cbm_k_readst1_@return
    // }
    // [1922] fclose::cbm_k_readst1_return#1 = fclose::cbm_k_readst1_return#0
    // fclose::@3
    // cbm_k_readst()
    // [1923] fclose::$1 = fclose::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [1924] ((char *)&__stdio_file+$118)[fclose::sp#0] = fclose::$1 -- pbuc1_derefidx_vbum1=vbuz2 
    lda.z fclose__1
    ldy sp
    sta __stdio_file+$118,y
    // if (__status)
    // [1925] if(0==((char *)&__stdio_file+$118)[fclose::sp#0]) goto fclose::@1 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$118,y
    cmp #0
    beq __b1
    // fclose::@return
    // }
    // [1926] return 
    rts
    // fclose::@1
  __b1:
    // cbm_k_close(__logical)
    // [1927] fclose::cbm_k_close1_channel = ((char *)&__stdio_file+$100)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$100,y
    sta cbm_k_close1_channel
    // fclose::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // fclose::cbm_k_readst2
    // char status
    // [1929] fclose::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [1931] fclose::cbm_k_readst2_return#0 = fclose::cbm_k_readst2_status -- vbuz1=vbum2 
    sta.z cbm_k_readst2_return
    // fclose::cbm_k_readst2_@return
    // }
    // [1932] fclose::cbm_k_readst2_return#1 = fclose::cbm_k_readst2_return#0
    // fclose::@4
    // cbm_k_readst()
    // [1933] fclose::$4 = fclose::cbm_k_readst2_return#1
    // __status = cbm_k_readst()
    // [1934] ((char *)&__stdio_file+$118)[fclose::sp#0] = fclose::$4 -- pbuc1_derefidx_vbum1=vbuz2 
    lda.z fclose__4
    ldy sp
    sta __stdio_file+$118,y
    // if (__status)
    // [1935] if(0==((char *)&__stdio_file+$118)[fclose::sp#0]) goto fclose::@2 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$118,y
    cmp #0
    beq __b2
    rts
    // fclose::@2
  __b2:
    // __logical = 0
    // [1936] ((char *)&__stdio_file+$100)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy sp
    sta __stdio_file+$100,y
    // __device = 0
    // [1937] ((char *)&__stdio_file+$108)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$108,y
    // __channel = 0
    // [1938] ((char *)&__stdio_file+$110)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$110,y
    // __filename
    // [1939] fclose::$6 = fclose::sp#0 << 3 -- vbum1=vbum1_rol_3 
    lda fclose__6
    asl
    asl
    asl
    sta fclose__6
    // *__filename = '\0'
    // [1940] ((char *)&__stdio_file)[fclose::$6] = '@' -- pbuc1_derefidx_vbum1=vbuc2 
    lda #'@'
    ldy fclose__6
    sta __stdio_file,y
    // __stdio_filecount--;
    // [1941] __stdio_filecount = -- __stdio_filecount -- vbum1=_dec_vbum1 
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
  // cbm_k_getin
/**
 * @brief Scan a character from keyboard without pressing enter.
 * 
 * @return char The character read.
 */
cbm_k_getin: {
    .label return = $6b
    // __mem unsigned char ch
    // [1942] cbm_k_getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsrCBM_GETIN stach  }
    jsr CBM_GETIN
    sta ch
    // return ch;
    // [1944] cbm_k_getin::return#0 = cbm_k_getin::ch -- vbuz1=vbum2 
    sta.z return
    // cbm_k_getin::@return
    // }
    // [1945] cbm_k_getin::return#1 = cbm_k_getin::return#0
    // [1946] return 
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
// void uctoa(__zp($25) char value, __zp($38) char *buffer, __zp($dc) char radix)
uctoa: {
    .label uctoa__4 = $64
    .label digit_value = $2c
    .label buffer = $38
    .label digit = $66
    .label value = $25
    .label radix = $dc
    .label started = $63
    .label max_digits = $b2
    .label digit_values = $b3
    // if(radix==DECIMAL)
    // [1947] if(uctoa::radix#0==DECIMAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp.z radix
    beq __b2
    // uctoa::@2
    // if(radix==HEXADECIMAL)
    // [1948] if(uctoa::radix#0==HEXADECIMAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp.z radix
    beq __b3
    // uctoa::@3
    // if(radix==OCTAL)
    // [1949] if(uctoa::radix#0==OCTAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp.z radix
    beq __b4
    // uctoa::@4
    // if(radix==BINARY)
    // [1950] if(uctoa::radix#0==BINARY) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp.z radix
    beq __b5
    // uctoa::@5
    // *buffer++ = 'e'
    // [1951] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1952] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1953] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1954] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // uctoa::@return
    // }
    // [1955] return 
    rts
    // [1956] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
  __b2:
    // [1956] phi uctoa::digit_values#8 = RADIX_DECIMAL_VALUES_CHAR [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1956] phi uctoa::max_digits#7 = 3 [phi:uctoa->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [1956] phi from uctoa::@2 to uctoa::@1 [phi:uctoa::@2->uctoa::@1]
  __b3:
    // [1956] phi uctoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_CHAR [phi:uctoa::@2->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1956] phi uctoa::max_digits#7 = 2 [phi:uctoa::@2->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #2
    sta.z max_digits
    jmp __b1
    // [1956] phi from uctoa::@3 to uctoa::@1 [phi:uctoa::@3->uctoa::@1]
  __b4:
    // [1956] phi uctoa::digit_values#8 = RADIX_OCTAL_VALUES_CHAR [phi:uctoa::@3->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values+1
    // [1956] phi uctoa::max_digits#7 = 3 [phi:uctoa::@3->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [1956] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
  __b5:
    // [1956] phi uctoa::digit_values#8 = RADIX_BINARY_VALUES_CHAR [phi:uctoa::@4->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_BINARY_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_CHAR
    sta.z digit_values+1
    // [1956] phi uctoa::max_digits#7 = 8 [phi:uctoa::@4->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #8
    sta.z max_digits
    // uctoa::@1
  __b1:
    // [1957] phi from uctoa::@1 to uctoa::@6 [phi:uctoa::@1->uctoa::@6]
    // [1957] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa::@1->uctoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1957] phi uctoa::started#2 = 0 [phi:uctoa::@1->uctoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [1957] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa::@1->uctoa::@6#2] -- register_copy 
    // [1957] phi uctoa::digit#2 = 0 [phi:uctoa::@1->uctoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // uctoa::@6
  __b6:
    // max_digits-1
    // [1958] uctoa::$4 = uctoa::max_digits#7 - 1 -- vbuz1=vbuz2_minus_1 
    ldx.z max_digits
    dex
    stx.z uctoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1959] if(uctoa::digit#2<uctoa::$4) goto uctoa::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z digit
    cmp.z uctoa__4
    bcc __b7
    // uctoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1960] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z value
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1961] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1962] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // uctoa::@7
  __b7:
    // unsigned char digit_value = digit_values[digit]
    // [1963] uctoa::digit_value#0 = uctoa::digit_values#8[uctoa::digit#2] -- vbuz1=pbuz2_derefidx_vbuz3 
    ldy.z digit
    lda (digit_values),y
    sta.z digit_value
    // if (started || value >= digit_value)
    // [1964] if(0!=uctoa::started#2) goto uctoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // uctoa::@12
    // [1965] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@10 -- vbuz1_ge_vbuz2_then_la1 
    lda.z value
    cmp.z digit_value
    bcs __b10
    // [1966] phi from uctoa::@12 to uctoa::@9 [phi:uctoa::@12->uctoa::@9]
    // [1966] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@12->uctoa::@9#0] -- register_copy 
    // [1966] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@12->uctoa::@9#1] -- register_copy 
    // [1966] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@12->uctoa::@9#2] -- register_copy 
    // uctoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1967] uctoa::digit#1 = ++ uctoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1957] phi from uctoa::@9 to uctoa::@6 [phi:uctoa::@9->uctoa::@6]
    // [1957] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@9->uctoa::@6#0] -- register_copy 
    // [1957] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@9->uctoa::@6#1] -- register_copy 
    // [1957] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@9->uctoa::@6#2] -- register_copy 
    // [1957] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@9->uctoa::@6#3] -- register_copy 
    jmp __b6
    // uctoa::@10
  __b10:
    // uctoa_append(buffer++, value, digit_value)
    // [1968] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [1969] uctoa_append::value#0 = uctoa::value#2
    // [1970] uctoa_append::sub#0 = uctoa::digit_value#0
    // [1971] call uctoa_append
    // [2327] phi from uctoa::@10 to uctoa_append [phi:uctoa::@10->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [1972] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@11
    // value = uctoa_append(buffer++, value, digit_value)
    // [1973] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [1974] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1966] phi from uctoa::@11 to uctoa::@9 [phi:uctoa::@11->uctoa::@9]
    // [1966] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@11->uctoa::@9#0] -- register_copy 
    // [1966] phi uctoa::started#4 = 1 [phi:uctoa::@11->uctoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [1966] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@11->uctoa::@9#2] -- register_copy 
    jmp __b9
}
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __zp($53) unsigned int strlen(__zp($4c) char *str)
strlen: {
    .label return = $53
    .label len = $53
    .label str = $4c
    // [1976] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [1976] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z len
    sta.z len+1
    // [1976] phi strlen::str#6 = strlen::str#8 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [1977] if(0!=*strlen::str#6) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [1978] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [1979] strlen::len#1 = ++ strlen::len#2 -- vwuz1=_inc_vwuz1 
    inc.z len
    bne !+
    inc.z len+1
  !:
    // str++;
    // [1980] strlen::str#1 = ++ strlen::str#6 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [1976] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [1976] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [1976] phi strlen::str#6 = strlen::str#1 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
}
  // printf_padding
// Print a padding char a number of times
// void printf_padding(__zp($3e) void (*putc)(char), __zp($6a) char pad, __zp($68) char length)
printf_padding: {
    .label i = $4e
    .label putc = $3e
    .label length = $68
    .label pad = $6a
    // [1982] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [1982] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [1983] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z length
    bcc __b2
    // printf_padding::@return
    // }
    // [1984] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [1985] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbuz1 
    lda.z pad
    pha
    // [1986] callexecute *printf_padding::putc#7  -- call__deref_pprz1 
    jsr icall31
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [1988] printf_padding::i#1 = ++ printf_padding::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1982] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [1982] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
    jmp __b1
    // Outside Flow
  icall31:
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
// __mem() unsigned long rom_address_from_bank(__zp($cc) char rom_bank)
rom_address_from_bank: {
    .label rom_address_from_bank__1 = $71
    .label return = $71
    .label rom_bank = $cc
    .label return_1 = $bd
    // ((unsigned long)(rom_bank)) << 14
    // [1990] rom_address_from_bank::$1 = (unsigned long)rom_address_from_bank::rom_bank#3 -- vduz1=_dword_vbuz2 
    lda.z rom_bank
    sta.z rom_address_from_bank__1
    lda #0
    sta.z rom_address_from_bank__1+1
    sta.z rom_address_from_bank__1+2
    sta.z rom_address_from_bank__1+3
    // [1991] rom_address_from_bank::return#0 = rom_address_from_bank::$1 << $e -- vduz1=vduz1_rol_vbuc1 
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
    // [1992] return 
    rts
  .segment Data
    .label return_2 = main.rom_file_modulo
}
.segment Code
  // rom_compare
// __zp($4c) unsigned int rom_compare(__zp($e3) char bank_ram, __zp($a9) char *ptr_ram, __zp($ab) unsigned long rom_compare_address, __zp($c8) unsigned int rom_compare_size)
rom_compare: {
    .label rom_compare__5 = $75
    .label rom_bank1_rom_compare__0 = $5b
    .label rom_bank1_rom_compare__1 = $d5
    .label rom_bank1_rom_compare__2 = $6c
    .label rom_ptr1_rom_compare__0 = $53
    .label rom_ptr1_rom_compare__2 = $53
    .label bank_set_bram1_bank = $e3
    .label rom_bank1_bank_unshifted = $6c
    .label rom_bank1_return = $31
    .label rom_ptr1_return = $53
    .label ptr_rom = $53
    .label ptr_ram = $a9
    .label compared_bytes = $7c
    /// Holds the amount of bytes actually verified between the ROM and the RAM.
    .label equal_bytes = $4c
    .label bank_ram = $e3
    .label rom_compare_address = $ab
    .label return = $4c
    .label rom_compare_size = $c8
    // rom_compare::bank_set_bram1
    // BRAM = bank
    // [1994] BRAM = rom_compare::bank_set_bram1_bank#0 -- vbuz1=vbuz2 
    lda.z bank_set_bram1_bank
    sta.z BRAM
    // rom_compare::rom_bank1
    // BYTE2(address)
    // [1995] rom_compare::rom_bank1_$0 = byte2  rom_compare::rom_compare_address#3 -- vbuz1=_byte2_vduz2 
    lda.z rom_compare_address+2
    sta.z rom_bank1_rom_compare__0
    // BYTE1(address)
    // [1996] rom_compare::rom_bank1_$1 = byte1  rom_compare::rom_compare_address#3 -- vbuz1=_byte1_vduz2 
    lda.z rom_compare_address+1
    sta.z rom_bank1_rom_compare__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [1997] rom_compare::rom_bank1_$2 = rom_compare::rom_bank1_$0 w= rom_compare::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_compare__0
    sta.z rom_bank1_rom_compare__2+1
    lda.z rom_bank1_rom_compare__1
    sta.z rom_bank1_rom_compare__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [1998] rom_compare::rom_bank1_bank_unshifted#0 = rom_compare::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [1999] rom_compare::rom_bank1_return#0 = byte1  rom_compare::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwuz2 
    lda.z rom_bank1_bank_unshifted+1
    sta.z rom_bank1_return
    // rom_compare::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2000] rom_compare::rom_ptr1_$2 = (unsigned int)rom_compare::rom_compare_address#3 -- vwuz1=_word_vduz2 
    lda.z rom_compare_address
    sta.z rom_ptr1_rom_compare__2
    lda.z rom_compare_address+1
    sta.z rom_ptr1_rom_compare__2+1
    // [2001] rom_compare::rom_ptr1_$0 = rom_compare::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_compare__0
    and #<$3fff
    sta.z rom_ptr1_rom_compare__0
    lda.z rom_ptr1_rom_compare__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_compare__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2002] rom_compare::rom_ptr1_return#0 = rom_compare::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_compare::bank_set_brom1
    // BROM = bank
    // [2003] BROM = rom_compare::rom_bank1_return#0 -- vbuz1=vbuz2 
    lda.z rom_bank1_return
    sta.z BROM
    // [2004] rom_compare::ptr_rom#9 = (char *)rom_compare::rom_ptr1_return#0
    // [2005] phi from rom_compare::bank_set_brom1 to rom_compare::@1 [phi:rom_compare::bank_set_brom1->rom_compare::@1]
    // [2005] phi rom_compare::equal_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z equal_bytes
    sta.z equal_bytes+1
    // [2005] phi rom_compare::ptr_ram#4 = rom_compare::ptr_ram#10 [phi:rom_compare::bank_set_brom1->rom_compare::@1#1] -- register_copy 
    // [2005] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#9 [phi:rom_compare::bank_set_brom1->rom_compare::@1#2] -- register_copy 
    // [2005] phi rom_compare::compared_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#3] -- vwuz1=vwuc1 
    sta.z compared_bytes
    sta.z compared_bytes+1
    // rom_compare::@1
  __b1:
    // while (compared_bytes < rom_compare_size)
    // [2006] if(rom_compare::compared_bytes#2<rom_compare::rom_compare_size#11) goto rom_compare::@2 -- vwuz1_lt_vwuz2_then_la1 
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
    // [2007] return 
    rts
    // rom_compare::@2
  __b2:
    // rom_byte_compare(ptr_rom, *ptr_ram)
    // [2008] rom_byte_compare::ptr_rom#0 = rom_compare::ptr_rom#2
    // [2009] rom_byte_compare::value#0 = *rom_compare::ptr_ram#4 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (ptr_ram),y
    sta.z rom_byte_compare.value
    // [2010] call rom_byte_compare
    jsr rom_byte_compare
    // [2011] rom_byte_compare::return#2 = rom_byte_compare::return#0
    // rom_compare::@5
    // [2012] rom_compare::$5 = rom_byte_compare::return#2
    // if (rom_byte_compare(ptr_rom, *ptr_ram))
    // [2013] if(0==rom_compare::$5) goto rom_compare::@3 -- 0_eq_vbuz1_then_la1 
    lda.z rom_compare__5
    beq __b3
    // rom_compare::@4
    // equal_bytes++;
    // [2014] rom_compare::equal_bytes#1 = ++ rom_compare::equal_bytes#2 -- vwuz1=_inc_vwuz1 
    inc.z equal_bytes
    bne !+
    inc.z equal_bytes+1
  !:
    // [2015] phi from rom_compare::@4 rom_compare::@5 to rom_compare::@3 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3]
    // [2015] phi rom_compare::equal_bytes#6 = rom_compare::equal_bytes#1 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3#0] -- register_copy 
    // rom_compare::@3
  __b3:
    // ptr_rom++;
    // [2016] rom_compare::ptr_rom#1 = ++ rom_compare::ptr_rom#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr_rom
    bne !+
    inc.z ptr_rom+1
  !:
    // ptr_ram++;
    // [2017] rom_compare::ptr_ram#0 = ++ rom_compare::ptr_ram#4 -- pbuz1=_inc_pbuz1 
    inc.z ptr_ram
    bne !+
    inc.z ptr_ram+1
  !:
    // compared_bytes++;
    // [2018] rom_compare::compared_bytes#1 = ++ rom_compare::compared_bytes#2 -- vwuz1=_inc_vwuz1 
    inc.z compared_bytes
    bne !+
    inc.z compared_bytes+1
  !:
    // [2005] phi from rom_compare::@3 to rom_compare::@1 [phi:rom_compare::@3->rom_compare::@1]
    // [2005] phi rom_compare::equal_bytes#2 = rom_compare::equal_bytes#6 [phi:rom_compare::@3->rom_compare::@1#0] -- register_copy 
    // [2005] phi rom_compare::ptr_ram#4 = rom_compare::ptr_ram#0 [phi:rom_compare::@3->rom_compare::@1#1] -- register_copy 
    // [2005] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#1 [phi:rom_compare::@3->rom_compare::@1#2] -- register_copy 
    // [2005] phi rom_compare::compared_bytes#2 = rom_compare::compared_bytes#1 [phi:rom_compare::@3->rom_compare::@1#3] -- register_copy 
    jmp __b1
}
  // ultoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void ultoa(__zp($26) unsigned long value, __zp($5f) char *buffer, __zp($db) char radix)
ultoa: {
    .label ultoa__4 = $5b
    .label ultoa__10 = $31
    .label ultoa__11 = $d5
    .label digit_value = $3a
    .label buffer = $5f
    .label digit = $65
    .label value = $26
    .label radix = $db
    .label started = $64
    .label max_digits = $b1
    .label digit_values = $b6
    // if(radix==DECIMAL)
    // [2019] if(ultoa::radix#0==DECIMAL) goto ultoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp.z radix
    beq __b2
    // ultoa::@2
    // if(radix==HEXADECIMAL)
    // [2020] if(ultoa::radix#0==HEXADECIMAL) goto ultoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp.z radix
    beq __b3
    // ultoa::@3
    // if(radix==OCTAL)
    // [2021] if(ultoa::radix#0==OCTAL) goto ultoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp.z radix
    beq __b4
    // ultoa::@4
    // if(radix==BINARY)
    // [2022] if(ultoa::radix#0==BINARY) goto ultoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp.z radix
    beq __b5
    // ultoa::@5
    // *buffer++ = 'e'
    // [2023] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2024] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2025] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2026] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // ultoa::@return
    // }
    // [2027] return 
    rts
    // [2028] phi from ultoa to ultoa::@1 [phi:ultoa->ultoa::@1]
  __b2:
    // [2028] phi ultoa::digit_values#8 = RADIX_DECIMAL_VALUES_LONG [phi:ultoa->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2028] phi ultoa::max_digits#7 = $a [phi:ultoa->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #$a
    sta.z max_digits
    jmp __b1
    // [2028] phi from ultoa::@2 to ultoa::@1 [phi:ultoa::@2->ultoa::@1]
  __b3:
    // [2028] phi ultoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_LONG [phi:ultoa::@2->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2028] phi ultoa::max_digits#7 = 8 [phi:ultoa::@2->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #8
    sta.z max_digits
    jmp __b1
    // [2028] phi from ultoa::@3 to ultoa::@1 [phi:ultoa::@3->ultoa::@1]
  __b4:
    // [2028] phi ultoa::digit_values#8 = RADIX_OCTAL_VALUES_LONG [phi:ultoa::@3->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_OCTAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_LONG
    sta.z digit_values+1
    // [2028] phi ultoa::max_digits#7 = $b [phi:ultoa::@3->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #$b
    sta.z max_digits
    jmp __b1
    // [2028] phi from ultoa::@4 to ultoa::@1 [phi:ultoa::@4->ultoa::@1]
  __b5:
    // [2028] phi ultoa::digit_values#8 = RADIX_BINARY_VALUES_LONG [phi:ultoa::@4->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_BINARY_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_LONG
    sta.z digit_values+1
    // [2028] phi ultoa::max_digits#7 = $20 [phi:ultoa::@4->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #$20
    sta.z max_digits
    // ultoa::@1
  __b1:
    // [2029] phi from ultoa::@1 to ultoa::@6 [phi:ultoa::@1->ultoa::@6]
    // [2029] phi ultoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:ultoa::@1->ultoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2029] phi ultoa::started#2 = 0 [phi:ultoa::@1->ultoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [2029] phi ultoa::value#2 = ultoa::value#1 [phi:ultoa::@1->ultoa::@6#2] -- register_copy 
    // [2029] phi ultoa::digit#2 = 0 [phi:ultoa::@1->ultoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // ultoa::@6
  __b6:
    // max_digits-1
    // [2030] ultoa::$4 = ultoa::max_digits#7 - 1 -- vbuz1=vbuz2_minus_1 
    ldx.z max_digits
    dex
    stx.z ultoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2031] if(ultoa::digit#2<ultoa::$4) goto ultoa::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z digit
    cmp.z ultoa__4
    bcc __b7
    // ultoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2032] ultoa::$11 = (char)ultoa::value#2 -- vbuz1=_byte_vduz2 
    lda.z value
    sta.z ultoa__11
    // [2033] *ultoa::buffer#11 = DIGITS[ultoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2034] ultoa::buffer#3 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2035] *ultoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // ultoa::@7
  __b7:
    // unsigned long digit_value = digit_values[digit]
    // [2036] ultoa::$10 = ultoa::digit#2 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z digit
    asl
    asl
    sta.z ultoa__10
    // [2037] ultoa::digit_value#0 = ultoa::digit_values#8[ultoa::$10] -- vduz1=pduz2_derefidx_vbuz3 
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
    // [2038] if(0!=ultoa::started#2) goto ultoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // ultoa::@12
    // [2039] if(ultoa::value#2>=ultoa::digit_value#0) goto ultoa::@10 -- vduz1_ge_vduz2_then_la1 
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
    // [2040] phi from ultoa::@12 to ultoa::@9 [phi:ultoa::@12->ultoa::@9]
    // [2040] phi ultoa::buffer#14 = ultoa::buffer#11 [phi:ultoa::@12->ultoa::@9#0] -- register_copy 
    // [2040] phi ultoa::started#4 = ultoa::started#2 [phi:ultoa::@12->ultoa::@9#1] -- register_copy 
    // [2040] phi ultoa::value#6 = ultoa::value#2 [phi:ultoa::@12->ultoa::@9#2] -- register_copy 
    // ultoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2041] ultoa::digit#1 = ++ ultoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [2029] phi from ultoa::@9 to ultoa::@6 [phi:ultoa::@9->ultoa::@6]
    // [2029] phi ultoa::buffer#11 = ultoa::buffer#14 [phi:ultoa::@9->ultoa::@6#0] -- register_copy 
    // [2029] phi ultoa::started#2 = ultoa::started#4 [phi:ultoa::@9->ultoa::@6#1] -- register_copy 
    // [2029] phi ultoa::value#2 = ultoa::value#6 [phi:ultoa::@9->ultoa::@6#2] -- register_copy 
    // [2029] phi ultoa::digit#2 = ultoa::digit#1 [phi:ultoa::@9->ultoa::@6#3] -- register_copy 
    jmp __b6
    // ultoa::@10
  __b10:
    // ultoa_append(buffer++, value, digit_value)
    // [2042] ultoa_append::buffer#0 = ultoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z ultoa_append.buffer
    lda.z buffer+1
    sta.z ultoa_append.buffer+1
    // [2043] ultoa_append::value#0 = ultoa::value#2
    // [2044] ultoa_append::sub#0 = ultoa::digit_value#0
    // [2045] call ultoa_append
    // [2338] phi from ultoa::@10 to ultoa_append [phi:ultoa::@10->ultoa_append]
    jsr ultoa_append
    // ultoa_append(buffer++, value, digit_value)
    // [2046] ultoa_append::return#0 = ultoa_append::value#2
    // ultoa::@11
    // value = ultoa_append(buffer++, value, digit_value)
    // [2047] ultoa::value#0 = ultoa_append::return#0
    // value = ultoa_append(buffer++, value, digit_value);
    // [2048] ultoa::buffer#4 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2040] phi from ultoa::@11 to ultoa::@9 [phi:ultoa::@11->ultoa::@9]
    // [2040] phi ultoa::buffer#14 = ultoa::buffer#4 [phi:ultoa::@11->ultoa::@9#0] -- register_copy 
    // [2040] phi ultoa::started#4 = 1 [phi:ultoa::@11->ultoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [2040] phi ultoa::value#6 = ultoa::value#0 [phi:ultoa::@11->ultoa::@9#2] -- register_copy 
    jmp __b9
}
  // cputsxy
// Move cursor and output a NUL-terminated string
// Same as "gotoxy (x, y); puts (s);"
// void cputsxy(__mem() char x, __zp($d6) char y, const char *s)
cputsxy: {
    .label y = $d6
    // gotoxy(x, y)
    // [2049] gotoxy::x#1 = cputsxy::x#0 -- vbuz1=vbum2 
    lda x
    sta.z gotoxy.x
    // [2050] gotoxy::y#1 = cputsxy::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [2051] call gotoxy
    // [479] phi from cputsxy to gotoxy [phi:cputsxy->gotoxy]
    // [479] phi gotoxy::y#29 = gotoxy::y#1 [phi:cputsxy->gotoxy#0] -- register_copy 
    // [479] phi gotoxy::x#29 = gotoxy::x#1 [phi:cputsxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [2052] phi from cputsxy to cputsxy::@1 [phi:cputsxy->cputsxy::@1]
    // cputsxy::@1
    // cputs(s)
    // [2053] call cputs
    // [2345] phi from cputsxy::@1 to cputs [phi:cputsxy::@1->cputs]
    jsr cputs
    // cputsxy::@return
    // }
    // [2054] return 
    rts
  .segment Data
    .label x = fclose.sp
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
// void rom_sector_erase(__zp($f5) unsigned long address)
rom_sector_erase: {
    .label rom_ptr1_rom_sector_erase__0 = $38
    .label rom_ptr1_rom_sector_erase__2 = $38
    .label rom_ptr1_return = $38
    .label rom_chip_address = $71
    .label address = $f5
    // rom_sector_erase::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2056] rom_sector_erase::rom_ptr1_$2 = (unsigned int)rom_sector_erase::address#0 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_sector_erase__2
    lda.z address+1
    sta.z rom_ptr1_rom_sector_erase__2+1
    // [2057] rom_sector_erase::rom_ptr1_$0 = rom_sector_erase::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_sector_erase__0
    and #<$3fff
    sta.z rom_ptr1_rom_sector_erase__0
    lda.z rom_ptr1_rom_sector_erase__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_sector_erase__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2058] rom_sector_erase::rom_ptr1_return#0 = rom_sector_erase::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_sector_erase::@1
    // unsigned long rom_chip_address = address & ROM_CHIP_MASK
    // [2059] rom_sector_erase::rom_chip_address#0 = rom_sector_erase::address#0 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [2060] rom_unlock::address#0 = rom_sector_erase::rom_chip_address#0 + $5555 -- vduz1=vduz1_plus_vwuc1 
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
    // [2061] call rom_unlock
    // [1729] phi from rom_sector_erase::@1 to rom_unlock [phi:rom_sector_erase::@1->rom_unlock]
    // [1729] phi rom_unlock::unlock_code#5 = $80 [phi:rom_sector_erase::@1->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$80
    sta.z rom_unlock.unlock_code
    // [1729] phi rom_unlock::address#5 = rom_unlock::address#0 [phi:rom_sector_erase::@1->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@2
    // rom_unlock(address, 0x30)
    // [2062] rom_unlock::address#1 = rom_sector_erase::address#0 -- vduz1=vduz2 
    lda.z address
    sta.z rom_unlock.address
    lda.z address+1
    sta.z rom_unlock.address+1
    lda.z address+2
    sta.z rom_unlock.address+2
    lda.z address+3
    sta.z rom_unlock.address+3
    // [2063] call rom_unlock
    // [1729] phi from rom_sector_erase::@2 to rom_unlock [phi:rom_sector_erase::@2->rom_unlock]
    // [1729] phi rom_unlock::unlock_code#5 = $30 [phi:rom_sector_erase::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$30
    sta.z rom_unlock.unlock_code
    // [1729] phi rom_unlock::address#5 = rom_unlock::address#1 [phi:rom_sector_erase::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@3
    // rom_wait(ptr_rom)
    // [2064] rom_wait::ptr_rom#0 = (char *)rom_sector_erase::rom_ptr1_return#0
    // [2065] call rom_wait
    // [2354] phi from rom_sector_erase::@3 to rom_wait [phi:rom_sector_erase::@3->rom_wait]
    // [2354] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#0 [phi:rom_sector_erase::@3->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_sector_erase::@return
    // }
    // [2066] return 
    rts
}
  // rom_write
/* inline */
// unsigned long rom_write(__zp($d6) char flash_ram_bank, __zp($5f) char *flash_ram_address, __zp($ab) unsigned long flash_rom_address, unsigned int flash_rom_size)
rom_write: {
    .label rom_chip_address = $bd
    .label flash_rom_address = $ab
    .label flash_ram_address = $5f
    .label flashed_bytes = $78
    .label flash_ram_bank = $d6
    // unsigned long rom_chip_address = flash_rom_address & ROM_CHIP_MASK
    // [2067] rom_write::rom_chip_address#0 = rom_write::flash_rom_address#1 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [2068] BRAM = rom_write::flash_ram_bank#0 -- vbuz1=vbuz2 
    lda.z flash_ram_bank
    sta.z BRAM
    // [2069] phi from rom_write::bank_set_bram1 to rom_write::@1 [phi:rom_write::bank_set_bram1->rom_write::@1]
    // [2069] phi rom_write::flash_ram_address#2 = rom_write::flash_ram_address#1 [phi:rom_write::bank_set_bram1->rom_write::@1#0] -- register_copy 
    // [2069] phi rom_write::flash_rom_address#3 = rom_write::flash_rom_address#1 [phi:rom_write::bank_set_bram1->rom_write::@1#1] -- register_copy 
    // [2069] phi rom_write::flashed_bytes#2 = 0 [phi:rom_write::bank_set_bram1->rom_write::@1#2] -- vduz1=vduc1 
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
    // [2070] if(rom_write::flashed_bytes#2<PROGRESS_CELL) goto rom_write::@2 -- vduz1_lt_vduc1_then_la1 
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
    // [2071] return 
    rts
    // rom_write::@2
  __b2:
    // rom_unlock(rom_chip_address + 0x05555, 0xA0)
    // [2072] rom_unlock::address#4 = rom_write::rom_chip_address#0 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [2073] call rom_unlock
    // [1729] phi from rom_write::@2 to rom_unlock [phi:rom_write::@2->rom_unlock]
    // [1729] phi rom_unlock::unlock_code#5 = $a0 [phi:rom_write::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$a0
    sta.z rom_unlock.unlock_code
    // [1729] phi rom_unlock::address#5 = rom_unlock::address#4 [phi:rom_write::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_write::@3
    // rom_byte_program(flash_rom_address, *flash_ram_address)
    // [2074] rom_byte_program::address#0 = rom_write::flash_rom_address#3 -- vduz1=vduz2 
    lda.z flash_rom_address
    sta.z rom_byte_program.address
    lda.z flash_rom_address+1
    sta.z rom_byte_program.address+1
    lda.z flash_rom_address+2
    sta.z rom_byte_program.address+2
    lda.z flash_rom_address+3
    sta.z rom_byte_program.address+3
    // [2075] rom_byte_program::value#0 = *rom_write::flash_ram_address#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (flash_ram_address),y
    sta.z rom_byte_program.value
    // [2076] call rom_byte_program
    // [2361] phi from rom_write::@3 to rom_byte_program [phi:rom_write::@3->rom_byte_program]
    jsr rom_byte_program
    // rom_write::@4
    // flash_rom_address++;
    // [2077] rom_write::flash_rom_address#0 = ++ rom_write::flash_rom_address#3 -- vduz1=_inc_vduz1 
    inc.z flash_rom_address
    bne !+
    inc.z flash_rom_address+1
    bne !+
    inc.z flash_rom_address+2
    bne !+
    inc.z flash_rom_address+3
  !:
    // flash_ram_address++;
    // [2078] rom_write::flash_ram_address#0 = ++ rom_write::flash_ram_address#2 -- pbuz1=_inc_pbuz1 
    inc.z flash_ram_address
    bne !+
    inc.z flash_ram_address+1
  !:
    // flashed_bytes++;
    // [2079] rom_write::flashed_bytes#1 = ++ rom_write::flashed_bytes#2 -- vduz1=_inc_vduz1 
    inc.z flashed_bytes
    bne !+
    inc.z flashed_bytes+1
    bne !+
    inc.z flashed_bytes+2
    bne !+
    inc.z flashed_bytes+3
  !:
    // [2069] phi from rom_write::@4 to rom_write::@1 [phi:rom_write::@4->rom_write::@1]
    // [2069] phi rom_write::flash_ram_address#2 = rom_write::flash_ram_address#0 [phi:rom_write::@4->rom_write::@1#0] -- register_copy 
    // [2069] phi rom_write::flash_rom_address#3 = rom_write::flash_rom_address#0 [phi:rom_write::@4->rom_write::@1#1] -- register_copy 
    // [2069] phi rom_write::flashed_bytes#2 = rom_write::flashed_bytes#1 [phi:rom_write::@4->rom_write::@1#2] -- register_copy 
    jmp __b1
}
  // insertup
// Insert a new line, and scroll the upper part of the screen up.
// void insertup(char rows)
insertup: {
    .label insertup__0 = $45
    .label insertup__4 = $43
    .label insertup__6 = $44
    .label insertup__7 = $43
    .label width = $45
    .label y = $40
    // __conio.width+1
    // [2080] insertup::$0 = *((char *)&__conio+6) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+6
    inc
    sta.z insertup__0
    // unsigned char width = (__conio.width+1) * 2
    // [2081] insertup::width#0 = insertup::$0 << 1 -- vbuz1=vbuz1_rol_1 
    // {asm{.byte $db}}
    asl.z width
    // [2082] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [2082] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [2083] if(insertup::y#2<*((char *)&__conio+1)) goto insertup::@2 -- vbuz1_lt__deref_pbuc1_then_la1 
    lda.z y
    cmp __conio+1
    bcc __b2
    // [2084] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [2085] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [2086] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [2087] insertup::$4 = insertup::y#2 + 1 -- vbuz1=vbuz2_plus_1 
    lda.z y
    inc
    sta.z insertup__4
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [2088] insertup::$6 = insertup::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z insertup__6
    // [2089] insertup::$7 = insertup::$4 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z insertup__7
    // [2090] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z memcpy8_vram_vram.dbank_vram
    // [2091] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__6
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.doffset_vram+1
    // [2092] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z memcpy8_vram_vram.sbank_vram
    // [2093] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__7
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.soffset_vram+1
    // [2094] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbuz1=vbuz2 
    lda.z width
    sta.z memcpy8_vram_vram.num8_1
    // [2095] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [2096] insertup::y#1 = ++ insertup::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [2082] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [2082] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
    jmp __b1
}
  // clearline
clearline: {
    .label clearline__0 = $2d
    .label clearline__1 = $2f
    .label clearline__2 = $30
    .label clearline__3 = $2e
    .label addr = $41
    .label c = $22
    // unsigned int addr = __conio.offsets[__conio.cursor_y]
    // [2097] clearline::$3 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z clearline__3
    // [2098] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwuz1=pwuc1_derefidx_vbuz2 
    tay
    lda __conio+$15,y
    sta.z addr
    lda __conio+$15+1,y
    sta.z addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2099] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [2100] clearline::$0 = byte0  clearline::addr#0 -- vbuz1=_byte0_vwuz2 
    lda.z addr
    sta.z clearline__0
    // *VERA_ADDRX_L = BYTE0(addr)
    // [2101] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [2102] clearline::$1 = byte1  clearline::addr#0 -- vbuz1=_byte1_vwuz2 
    lda.z addr+1
    sta.z clearline__1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [2103] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [2104] clearline::$2 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clearline__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [2105] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [2106] clearline::c#0 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z c
    // [2107] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [2107] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [2108] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [2109] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [2110] clearline::c#1 = -- clearline::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [2111] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b1
    // clearline::@return
    // }
    // [2112] return 
    rts
}
  // frame_maskxy
// __mem() char frame_maskxy(__mem() char x, __mem() char y)
frame_maskxy: {
    .label cpeekcxy1_cpeekc1_frame_maskxy__0 = $70
    .label cpeekcxy1_cpeekc1_frame_maskxy__1 = $59
    .label cpeekcxy1_cpeekc1_frame_maskxy__2 = $50
    .label c = $5c
    // frame_maskxy::cpeekcxy1
    // gotoxy(x,y)
    // [2114] gotoxy::x#5 = frame_maskxy::cpeekcxy1_x#0 -- vbuz1=vbum2 
    lda cpeekcxy1_x
    sta.z gotoxy.x
    // [2115] gotoxy::y#5 = frame_maskxy::cpeekcxy1_y#0 -- vbuz1=vbum2 
    lda cpeekcxy1_y
    sta.z gotoxy.y
    // [2116] call gotoxy
    // [479] phi from frame_maskxy::cpeekcxy1 to gotoxy [phi:frame_maskxy::cpeekcxy1->gotoxy]
    // [479] phi gotoxy::y#29 = gotoxy::y#5 [phi:frame_maskxy::cpeekcxy1->gotoxy#0] -- register_copy 
    // [479] phi gotoxy::x#29 = gotoxy::x#5 [phi:frame_maskxy::cpeekcxy1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // frame_maskxy::cpeekcxy1_cpeekc1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2117] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [2118] frame_maskxy::cpeekcxy1_cpeekc1_$0 = byte0  *((unsigned int *)&__conio+$13) -- vbuz1=_byte0__deref_pwuc1 
    lda __conio+$13
    sta.z cpeekcxy1_cpeekc1_frame_maskxy__0
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [2119] *VERA_ADDRX_L = frame_maskxy::cpeekcxy1_cpeekc1_$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [2120] frame_maskxy::cpeekcxy1_cpeekc1_$1 = byte1  *((unsigned int *)&__conio+$13) -- vbuz1=_byte1__deref_pwuc1 
    lda __conio+$13+1
    sta.z cpeekcxy1_cpeekc1_frame_maskxy__1
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [2121] *VERA_ADDRX_M = frame_maskxy::cpeekcxy1_cpeekc1_$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_0
    // [2122] frame_maskxy::cpeekcxy1_cpeekc1_$2 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z cpeekcxy1_cpeekc1_frame_maskxy__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_0
    // [2123] *VERA_ADDRX_H = frame_maskxy::cpeekcxy1_cpeekc1_$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // return *VERA_DATA0;
    // [2124] frame_maskxy::c#0 = *VERA_DATA0 -- vbuz1=_deref_pbuc1 
    lda VERA_DATA0
    sta.z c
    // frame_maskxy::@12
    // case 0x70: // DR corner.
    //             return 0b0110;
    // [2125] if(frame_maskxy::c#0==$70) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$70
    cmp.z c
    beq __b2
    // frame_maskxy::@1
    // case 0x6E: // DL corner.
    //             return 0b0011;
    // [2126] if(frame_maskxy::c#0==$6e) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6e
    cmp.z c
    beq __b1
    // frame_maskxy::@2
    // case 0x6D: // UR corner.
    //             return 0b1100;
    // [2127] if(frame_maskxy::c#0==$6d) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6d
    cmp.z c
    beq __b3
    // frame_maskxy::@3
    // case 0x7D: // UL corner.
    //             return 0b1001;
    // [2128] if(frame_maskxy::c#0==$7d) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$7d
    cmp.z c
    beq __b4
    // frame_maskxy::@4
    // case 0x40: // HL line.
    //             return 0b0101;
    // [2129] if(frame_maskxy::c#0==$40) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$40
    cmp.z c
    beq __b5
    // frame_maskxy::@5
    // case 0x5D: // VL line.
    //             return 0b1010;
    // [2130] if(frame_maskxy::c#0==$5d) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$5d
    cmp.z c
    beq __b6
    // frame_maskxy::@6
    // case 0x6B: // VR junction.
    //             return 0b1110;
    // [2131] if(frame_maskxy::c#0==$6b) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6b
    cmp.z c
    beq __b7
    // frame_maskxy::@7
    // case 0x73: // VL junction.
    //             return 0b1011;
    // [2132] if(frame_maskxy::c#0==$73) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$73
    cmp.z c
    beq __b8
    // frame_maskxy::@8
    // case 0x72: // HD junction.
    //             return 0b0111;
    // [2133] if(frame_maskxy::c#0==$72) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$72
    cmp.z c
    beq __b9
    // frame_maskxy::@9
    // case 0x71: // HU junction.
    //             return 0b1101;
    // [2134] if(frame_maskxy::c#0==$71) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$71
    cmp.z c
    beq __b10
    // frame_maskxy::@10
    // case 0x5B: // HV junction.
    //             return 0b1111;
    // [2135] if(frame_maskxy::c#0==$5b) goto frame_maskxy::@11 -- vbuz1_eq_vbuc1_then_la1 
    lda #$5b
    cmp.z c
    beq __b11
    // [2137] phi from frame_maskxy::@10 to frame_maskxy::@return [phi:frame_maskxy::@10->frame_maskxy::@return]
    // [2137] phi frame_maskxy::return#12 = 0 [phi:frame_maskxy::@10->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    rts
    // [2136] phi from frame_maskxy::@10 to frame_maskxy::@11 [phi:frame_maskxy::@10->frame_maskxy::@11]
    // frame_maskxy::@11
  __b11:
    // [2137] phi from frame_maskxy::@11 to frame_maskxy::@return [phi:frame_maskxy::@11->frame_maskxy::@return]
    // [2137] phi frame_maskxy::return#12 = $f [phi:frame_maskxy::@11->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$f
    sta return
    rts
    // [2137] phi from frame_maskxy::@1 to frame_maskxy::@return [phi:frame_maskxy::@1->frame_maskxy::@return]
  __b1:
    // [2137] phi frame_maskxy::return#12 = 3 [phi:frame_maskxy::@1->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #3
    sta return
    rts
    // [2137] phi from frame_maskxy::@12 to frame_maskxy::@return [phi:frame_maskxy::@12->frame_maskxy::@return]
  __b2:
    // [2137] phi frame_maskxy::return#12 = 6 [phi:frame_maskxy::@12->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #6
    sta return
    rts
    // [2137] phi from frame_maskxy::@2 to frame_maskxy::@return [phi:frame_maskxy::@2->frame_maskxy::@return]
  __b3:
    // [2137] phi frame_maskxy::return#12 = $c [phi:frame_maskxy::@2->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$c
    sta return
    rts
    // [2137] phi from frame_maskxy::@3 to frame_maskxy::@return [phi:frame_maskxy::@3->frame_maskxy::@return]
  __b4:
    // [2137] phi frame_maskxy::return#12 = 9 [phi:frame_maskxy::@3->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #9
    sta return
    rts
    // [2137] phi from frame_maskxy::@4 to frame_maskxy::@return [phi:frame_maskxy::@4->frame_maskxy::@return]
  __b5:
    // [2137] phi frame_maskxy::return#12 = 5 [phi:frame_maskxy::@4->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #5
    sta return
    rts
    // [2137] phi from frame_maskxy::@5 to frame_maskxy::@return [phi:frame_maskxy::@5->frame_maskxy::@return]
  __b6:
    // [2137] phi frame_maskxy::return#12 = $a [phi:frame_maskxy::@5->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$a
    sta return
    rts
    // [2137] phi from frame_maskxy::@6 to frame_maskxy::@return [phi:frame_maskxy::@6->frame_maskxy::@return]
  __b7:
    // [2137] phi frame_maskxy::return#12 = $e [phi:frame_maskxy::@6->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$e
    sta return
    rts
    // [2137] phi from frame_maskxy::@7 to frame_maskxy::@return [phi:frame_maskxy::@7->frame_maskxy::@return]
  __b8:
    // [2137] phi frame_maskxy::return#12 = $b [phi:frame_maskxy::@7->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$b
    sta return
    rts
    // [2137] phi from frame_maskxy::@8 to frame_maskxy::@return [phi:frame_maskxy::@8->frame_maskxy::@return]
  __b9:
    // [2137] phi frame_maskxy::return#12 = 7 [phi:frame_maskxy::@8->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #7
    sta return
    rts
    // [2137] phi from frame_maskxy::@9 to frame_maskxy::@return [phi:frame_maskxy::@9->frame_maskxy::@return]
  __b10:
    // [2137] phi frame_maskxy::return#12 = $d [phi:frame_maskxy::@9->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$d
    sta return
    // frame_maskxy::@return
    // }
    // [2138] return 
    rts
  .segment Data
    cpeekcxy1_x: .byte 0
    .label cpeekcxy1_y = fclose.sp
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
    .label x = cpeekcxy1_x
    .label y = fclose.sp
}
.segment Code
  // frame_char
// __zp($63) char frame_char(__mem() char mask)
frame_char: {
    .label return = $63
    // case 0b0110:
    //             return 0x70;
    // [2140] if(frame_char::mask#10==6) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    lda #6
    cmp mask
    beq __b1
    // frame_char::@1
    // case 0b0011:
    //             return 0x6E;
    // [2141] if(frame_char::mask#10==3) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // DR corner.
    lda #3
    cmp mask
    beq __b2
    // frame_char::@2
    // case 0b1100:
    //             return 0x6D;
    // [2142] if(frame_char::mask#10==$c) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // DL corner.
    lda #$c
    cmp mask
    beq __b3
    // frame_char::@3
    // case 0b1001:
    //             return 0x7D;
    // [2143] if(frame_char::mask#10==9) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // UR corner.
    lda #9
    cmp mask
    beq __b4
    // frame_char::@4
    // case 0b0101:
    //             return 0x40;
    // [2144] if(frame_char::mask#10==5) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // UL corner.
    lda #5
    cmp mask
    beq __b5
    // frame_char::@5
    // case 0b1010:
    //             return 0x5D;
    // [2145] if(frame_char::mask#10==$a) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // HL line.
    lda #$a
    cmp mask
    beq __b6
    // frame_char::@6
    // case 0b1110:
    //             return 0x6B;
    // [2146] if(frame_char::mask#10==$e) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // VL line.
    lda #$e
    cmp mask
    beq __b7
    // frame_char::@7
    // case 0b1011:
    //             return 0x73;
    // [2147] if(frame_char::mask#10==$b) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // VR junction.
    lda #$b
    cmp mask
    beq __b8
    // frame_char::@8
    // case 0b0111:
    //             return 0x72;
    // [2148] if(frame_char::mask#10==7) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // VL junction.
    lda #7
    cmp mask
    beq __b9
    // frame_char::@9
    // case 0b1101:
    //             return 0x71;
    // [2149] if(frame_char::mask#10==$d) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // HD junction.
    lda #$d
    cmp mask
    beq __b10
    // frame_char::@10
    // case 0b1111:
    //             return 0x5B;
    // [2150] if(frame_char::mask#10==$f) goto frame_char::@11 -- vbum1_eq_vbuc1_then_la1 
    // HU junction.
    lda #$f
    cmp mask
    beq __b11
    // [2152] phi from frame_char::@10 to frame_char::@return [phi:frame_char::@10->frame_char::@return]
    // [2152] phi frame_char::return#12 = $20 [phi:frame_char::@10->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$20
    sta.z return
    rts
    // [2151] phi from frame_char::@10 to frame_char::@11 [phi:frame_char::@10->frame_char::@11]
    // frame_char::@11
  __b11:
    // [2152] phi from frame_char::@11 to frame_char::@return [phi:frame_char::@11->frame_char::@return]
    // [2152] phi frame_char::return#12 = $5b [phi:frame_char::@11->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z return
    rts
    // [2152] phi from frame_char to frame_char::@return [phi:frame_char->frame_char::@return]
  __b1:
    // [2152] phi frame_char::return#12 = $70 [phi:frame_char->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$70
    sta.z return
    rts
    // [2152] phi from frame_char::@1 to frame_char::@return [phi:frame_char::@1->frame_char::@return]
  __b2:
    // [2152] phi frame_char::return#12 = $6e [phi:frame_char::@1->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6e
    sta.z return
    rts
    // [2152] phi from frame_char::@2 to frame_char::@return [phi:frame_char::@2->frame_char::@return]
  __b3:
    // [2152] phi frame_char::return#12 = $6d [phi:frame_char::@2->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6d
    sta.z return
    rts
    // [2152] phi from frame_char::@3 to frame_char::@return [phi:frame_char::@3->frame_char::@return]
  __b4:
    // [2152] phi frame_char::return#12 = $7d [phi:frame_char::@3->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$7d
    sta.z return
    rts
    // [2152] phi from frame_char::@4 to frame_char::@return [phi:frame_char::@4->frame_char::@return]
  __b5:
    // [2152] phi frame_char::return#12 = $40 [phi:frame_char::@4->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z return
    rts
    // [2152] phi from frame_char::@5 to frame_char::@return [phi:frame_char::@5->frame_char::@return]
  __b6:
    // [2152] phi frame_char::return#12 = $5d [phi:frame_char::@5->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z return
    rts
    // [2152] phi from frame_char::@6 to frame_char::@return [phi:frame_char::@6->frame_char::@return]
  __b7:
    // [2152] phi frame_char::return#12 = $6b [phi:frame_char::@6->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z return
    rts
    // [2152] phi from frame_char::@7 to frame_char::@return [phi:frame_char::@7->frame_char::@return]
  __b8:
    // [2152] phi frame_char::return#12 = $73 [phi:frame_char::@7->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z return
    rts
    // [2152] phi from frame_char::@8 to frame_char::@return [phi:frame_char::@8->frame_char::@return]
  __b9:
    // [2152] phi frame_char::return#12 = $72 [phi:frame_char::@8->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z return
    rts
    // [2152] phi from frame_char::@9 to frame_char::@return [phi:frame_char::@9->frame_char::@return]
  __b10:
    // [2152] phi frame_char::return#12 = $71 [phi:frame_char::@9->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z return
    // frame_char::@return
    // }
    // [2153] return 
    rts
  .segment Data
    .label mask = frame_maskxy.return
}
.segment Code
  // print_chip_led
// void print_chip_led(__zp($70) char x, char y, __zp($64) char w, __zp($4e) char tc, char bc)
print_chip_led: {
    .label i = $2c
    .label tc = $4e
    .label x = $70
    .label w = $64
    // gotoxy(x, y)
    // [2155] gotoxy::x#8 = print_chip_led::x#3 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [2156] call gotoxy
    // [479] phi from print_chip_led to gotoxy [phi:print_chip_led->gotoxy]
    // [479] phi gotoxy::y#29 = 3 [phi:print_chip_led->gotoxy#0] -- vbuz1=vbuc1 
    lda #3
    sta.z gotoxy.y
    // [479] phi gotoxy::x#29 = gotoxy::x#8 [phi:print_chip_led->gotoxy#1] -- register_copy 
    jsr gotoxy
    // print_chip_led::@4
    // textcolor(tc)
    // [2157] textcolor::color#10 = print_chip_led::tc#3 -- vbuz1=vbuz2 
    lda.z tc
    sta.z textcolor.color
    // [2158] call textcolor
    // [461] phi from print_chip_led::@4 to textcolor [phi:print_chip_led::@4->textcolor]
    // [461] phi textcolor::color#16 = textcolor::color#10 [phi:print_chip_led::@4->textcolor#0] -- register_copy 
    jsr textcolor
    // [2159] phi from print_chip_led::@4 to print_chip_led::@5 [phi:print_chip_led::@4->print_chip_led::@5]
    // print_chip_led::@5
    // bgcolor(bc)
    // [2160] call bgcolor
    // [466] phi from print_chip_led::@5 to bgcolor [phi:print_chip_led::@5->bgcolor]
    // [466] phi bgcolor::color#14 = BLUE [phi:print_chip_led::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [2161] phi from print_chip_led::@5 to print_chip_led::@1 [phi:print_chip_led::@5->print_chip_led::@1]
    // [2161] phi print_chip_led::i#2 = 0 [phi:print_chip_led::@5->print_chip_led::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // print_chip_led::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [2162] if(print_chip_led::i#2<print_chip_led::w#5) goto print_chip_led::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [2163] phi from print_chip_led::@1 to print_chip_led::@3 [phi:print_chip_led::@1->print_chip_led::@3]
    // print_chip_led::@3
    // textcolor(WHITE)
    // [2164] call textcolor
    // [461] phi from print_chip_led::@3 to textcolor [phi:print_chip_led::@3->textcolor]
    // [461] phi textcolor::color#16 = WHITE [phi:print_chip_led::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [2165] phi from print_chip_led::@3 to print_chip_led::@6 [phi:print_chip_led::@3->print_chip_led::@6]
    // print_chip_led::@6
    // bgcolor(BLUE)
    // [2166] call bgcolor
    // [466] phi from print_chip_led::@6 to bgcolor [phi:print_chip_led::@6->bgcolor]
    // [466] phi bgcolor::color#14 = BLUE [phi:print_chip_led::@6->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_led::@return
    // }
    // [2167] return 
    rts
    // print_chip_led::@2
  __b2:
    // cputc(0xE2)
    // [2168] stackpush(char) = $e2 -- _stackpushbyte_=vbuc1 
    lda #$e2
    pha
    // [2169] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [2171] print_chip_led::i#1 = ++ print_chip_led::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2161] phi from print_chip_led::@2 to print_chip_led::@1 [phi:print_chip_led::@2->print_chip_led::@1]
    // [2161] phi print_chip_led::i#2 = print_chip_led::i#1 [phi:print_chip_led::@2->print_chip_led::@1#0] -- register_copy 
    jmp __b1
}
  // print_chip_line
// void print_chip_line(__zp($b2) char x, __zp($66) char y, __zp($5b) char w, __zp($d5) char c)
print_chip_line: {
    .label i = $31
    .label x = $b2
    .label w = $5b
    .label c = $d5
    .label y = $66
    // gotoxy(x, y)
    // [2173] gotoxy::x#6 = print_chip_line::x#16 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [2174] gotoxy::y#6 = print_chip_line::y#16 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [2175] call gotoxy
    // [479] phi from print_chip_line to gotoxy [phi:print_chip_line->gotoxy]
    // [479] phi gotoxy::y#29 = gotoxy::y#6 [phi:print_chip_line->gotoxy#0] -- register_copy 
    // [479] phi gotoxy::x#29 = gotoxy::x#6 [phi:print_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [2176] phi from print_chip_line to print_chip_line::@4 [phi:print_chip_line->print_chip_line::@4]
    // print_chip_line::@4
    // textcolor(GREY)
    // [2177] call textcolor
    // [461] phi from print_chip_line::@4 to textcolor [phi:print_chip_line::@4->textcolor]
    // [461] phi textcolor::color#16 = GREY [phi:print_chip_line::@4->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [2178] phi from print_chip_line::@4 to print_chip_line::@5 [phi:print_chip_line::@4->print_chip_line::@5]
    // print_chip_line::@5
    // bgcolor(BLUE)
    // [2179] call bgcolor
    // [466] phi from print_chip_line::@5 to bgcolor [phi:print_chip_line::@5->bgcolor]
    // [466] phi bgcolor::color#14 = BLUE [phi:print_chip_line::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@6
    // cputc(VERA_CHR_UR)
    // [2180] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [2181] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [2183] call textcolor
    // [461] phi from print_chip_line::@6 to textcolor [phi:print_chip_line::@6->textcolor]
    // [461] phi textcolor::color#16 = WHITE [phi:print_chip_line::@6->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [2184] phi from print_chip_line::@6 to print_chip_line::@7 [phi:print_chip_line::@6->print_chip_line::@7]
    // print_chip_line::@7
    // bgcolor(BLACK)
    // [2185] call bgcolor
    // [466] phi from print_chip_line::@7 to bgcolor [phi:print_chip_line::@7->bgcolor]
    // [466] phi bgcolor::color#14 = BLACK [phi:print_chip_line::@7->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // [2186] phi from print_chip_line::@7 to print_chip_line::@1 [phi:print_chip_line::@7->print_chip_line::@1]
    // [2186] phi print_chip_line::i#2 = 0 [phi:print_chip_line::@7->print_chip_line::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // print_chip_line::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [2187] if(print_chip_line::i#2<print_chip_line::w#10) goto print_chip_line::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [2188] phi from print_chip_line::@1 to print_chip_line::@3 [phi:print_chip_line::@1->print_chip_line::@3]
    // print_chip_line::@3
    // textcolor(GREY)
    // [2189] call textcolor
    // [461] phi from print_chip_line::@3 to textcolor [phi:print_chip_line::@3->textcolor]
    // [461] phi textcolor::color#16 = GREY [phi:print_chip_line::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [2190] phi from print_chip_line::@3 to print_chip_line::@8 [phi:print_chip_line::@3->print_chip_line::@8]
    // print_chip_line::@8
    // bgcolor(BLUE)
    // [2191] call bgcolor
    // [466] phi from print_chip_line::@8 to bgcolor [phi:print_chip_line::@8->bgcolor]
    // [466] phi bgcolor::color#14 = BLUE [phi:print_chip_line::@8->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@9
    // cputc(VERA_CHR_UL)
    // [2192] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [2193] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [2195] call textcolor
    // [461] phi from print_chip_line::@9 to textcolor [phi:print_chip_line::@9->textcolor]
    // [461] phi textcolor::color#16 = WHITE [phi:print_chip_line::@9->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [2196] phi from print_chip_line::@9 to print_chip_line::@10 [phi:print_chip_line::@9->print_chip_line::@10]
    // print_chip_line::@10
    // bgcolor(BLACK)
    // [2197] call bgcolor
    // [466] phi from print_chip_line::@10 to bgcolor [phi:print_chip_line::@10->bgcolor]
    // [466] phi bgcolor::color#14 = BLACK [phi:print_chip_line::@10->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@11
    // cputcxy(x+2, y, c)
    // [2198] cputcxy::x#8 = print_chip_line::x#16 + 2 -- vbuz1=vbuz1_plus_2 
    lda.z cputcxy.x
    clc
    adc #2
    sta.z cputcxy.x
    // [2199] cputcxy::y#8 = print_chip_line::y#16
    // [2200] cputcxy::c#8 = print_chip_line::c#15 -- vbuz1=vbuz2 
    lda.z c
    sta.z cputcxy.c
    // [2201] call cputcxy
    // [1588] phi from print_chip_line::@11 to cputcxy [phi:print_chip_line::@11->cputcxy]
    // [1588] phi cputcxy::c#13 = cputcxy::c#8 [phi:print_chip_line::@11->cputcxy#0] -- register_copy 
    // [1588] phi cputcxy::y#13 = cputcxy::y#8 [phi:print_chip_line::@11->cputcxy#1] -- register_copy 
    // [1588] phi cputcxy::x#13 = cputcxy::x#8 [phi:print_chip_line::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // print_chip_line::@return
    // }
    // [2202] return 
    rts
    // print_chip_line::@2
  __b2:
    // cputc(VERA_CHR_SPACE)
    // [2203] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [2204] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [2206] print_chip_line::i#1 = ++ print_chip_line::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2186] phi from print_chip_line::@2 to print_chip_line::@1 [phi:print_chip_line::@2->print_chip_line::@1]
    // [2186] phi print_chip_line::i#2 = print_chip_line::i#1 [phi:print_chip_line::@2->print_chip_line::@1#0] -- register_copy 
    jmp __b1
}
  // print_chip_end
// void print_chip_end(__zp($b1) char x, char y, __zp($69) char w)
print_chip_end: {
    .label i = $75
    .label x = $b1
    .label w = $69
    // gotoxy(x, y)
    // [2207] gotoxy::x#7 = print_chip_end::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [2208] call gotoxy
    // [479] phi from print_chip_end to gotoxy [phi:print_chip_end->gotoxy]
    // [479] phi gotoxy::y#29 = print_chip::y#21 [phi:print_chip_end->gotoxy#0] -- vbuz1=vbuc1 
    lda #print_chip.y
    sta.z gotoxy.y
    // [479] phi gotoxy::x#29 = gotoxy::x#7 [phi:print_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [2209] phi from print_chip_end to print_chip_end::@4 [phi:print_chip_end->print_chip_end::@4]
    // print_chip_end::@4
    // textcolor(GREY)
    // [2210] call textcolor
    // [461] phi from print_chip_end::@4 to textcolor [phi:print_chip_end::@4->textcolor]
    // [461] phi textcolor::color#16 = GREY [phi:print_chip_end::@4->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [2211] phi from print_chip_end::@4 to print_chip_end::@5 [phi:print_chip_end::@4->print_chip_end::@5]
    // print_chip_end::@5
    // bgcolor(BLUE)
    // [2212] call bgcolor
    // [466] phi from print_chip_end::@5 to bgcolor [phi:print_chip_end::@5->bgcolor]
    // [466] phi bgcolor::color#14 = BLUE [phi:print_chip_end::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_end::@6
    // cputc(VERA_CHR_UR)
    // [2213] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [2214] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [2216] call textcolor
    // [461] phi from print_chip_end::@6 to textcolor [phi:print_chip_end::@6->textcolor]
    // [461] phi textcolor::color#16 = BLUE [phi:print_chip_end::@6->textcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z textcolor.color
    jsr textcolor
    // [2217] phi from print_chip_end::@6 to print_chip_end::@7 [phi:print_chip_end::@6->print_chip_end::@7]
    // print_chip_end::@7
    // bgcolor(BLACK)
    // [2218] call bgcolor
    // [466] phi from print_chip_end::@7 to bgcolor [phi:print_chip_end::@7->bgcolor]
    // [466] phi bgcolor::color#14 = BLACK [phi:print_chip_end::@7->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // [2219] phi from print_chip_end::@7 to print_chip_end::@1 [phi:print_chip_end::@7->print_chip_end::@1]
    // [2219] phi print_chip_end::i#2 = 0 [phi:print_chip_end::@7->print_chip_end::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // print_chip_end::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [2220] if(print_chip_end::i#2<print_chip_end::w#0) goto print_chip_end::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [2221] phi from print_chip_end::@1 to print_chip_end::@3 [phi:print_chip_end::@1->print_chip_end::@3]
    // print_chip_end::@3
    // textcolor(GREY)
    // [2222] call textcolor
    // [461] phi from print_chip_end::@3 to textcolor [phi:print_chip_end::@3->textcolor]
    // [461] phi textcolor::color#16 = GREY [phi:print_chip_end::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [2223] phi from print_chip_end::@3 to print_chip_end::@8 [phi:print_chip_end::@3->print_chip_end::@8]
    // print_chip_end::@8
    // bgcolor(BLUE)
    // [2224] call bgcolor
    // [466] phi from print_chip_end::@8 to bgcolor [phi:print_chip_end::@8->bgcolor]
    // [466] phi bgcolor::color#14 = BLUE [phi:print_chip_end::@8->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_end::@9
    // cputc(VERA_CHR_UL)
    // [2225] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [2226] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_end::@return
    // }
    // [2228] return 
    rts
    // print_chip_end::@2
  __b2:
    // cputc(VERA_CHR_HL)
    // [2229] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [2230] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [2232] print_chip_end::i#1 = ++ print_chip_end::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2219] phi from print_chip_end::@2 to print_chip_end::@1 [phi:print_chip_end::@2->print_chip_end::@1]
    // [2219] phi print_chip_end::i#2 = print_chip_end::i#1 [phi:print_chip_end::@2->print_chip_end::@1#0] -- register_copy 
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
// __zp($2a) unsigned int utoa_append(__zp($53) char *buffer, __zp($2a) unsigned int value, __zp($3e) unsigned int sub)
utoa_append: {
    .label buffer = $53
    .label value = $2a
    .label sub = $3e
    .label return = $2a
    .label digit = $2c
    // [2234] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [2234] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [2234] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [2235] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwuz1_ge_vwuz2_then_la1 
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
    // [2236] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // utoa_append::@return
    // }
    // [2237] return 
    rts
    // utoa_append::@2
  __b2:
    // digit++;
    // [2238] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [2239] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    lda.z value+1
    sbc.z sub+1
    sta.z value+1
    // [2234] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [2234] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [2234] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
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
// void rom_write_byte(__zp($55) unsigned long address, __zp($5b) char value)
rom_write_byte: {
    .label rom_bank1_rom_write_byte__0 = $59
    .label rom_bank1_rom_write_byte__1 = $50
    .label rom_bank1_rom_write_byte__2 = $4a
    .label rom_ptr1_rom_write_byte__0 = $48
    .label rom_ptr1_rom_write_byte__2 = $48
    .label rom_bank1_bank_unshifted = $4a
    .label rom_bank1_return = $5c
    .label rom_ptr1_return = $48
    .label address = $55
    .label value = $5b
    // rom_write_byte::rom_bank1
    // BYTE2(address)
    // [2241] rom_write_byte::rom_bank1_$0 = byte2  rom_write_byte::address#4 -- vbuz1=_byte2_vduz2 
    lda.z address+2
    sta.z rom_bank1_rom_write_byte__0
    // BYTE1(address)
    // [2242] rom_write_byte::rom_bank1_$1 = byte1  rom_write_byte::address#4 -- vbuz1=_byte1_vduz2 
    lda.z address+1
    sta.z rom_bank1_rom_write_byte__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2243] rom_write_byte::rom_bank1_$2 = rom_write_byte::rom_bank1_$0 w= rom_write_byte::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_write_byte__0
    sta.z rom_bank1_rom_write_byte__2+1
    lda.z rom_bank1_rom_write_byte__1
    sta.z rom_bank1_rom_write_byte__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2244] rom_write_byte::rom_bank1_bank_unshifted#0 = rom_write_byte::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2245] rom_write_byte::rom_bank1_return#0 = byte1  rom_write_byte::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwuz2 
    lda.z rom_bank1_bank_unshifted+1
    sta.z rom_bank1_return
    // rom_write_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2246] rom_write_byte::rom_ptr1_$2 = (unsigned int)rom_write_byte::address#4 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_write_byte__2
    lda.z address+1
    sta.z rom_ptr1_rom_write_byte__2+1
    // [2247] rom_write_byte::rom_ptr1_$0 = rom_write_byte::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_write_byte__0
    and #<$3fff
    sta.z rom_ptr1_rom_write_byte__0
    lda.z rom_ptr1_rom_write_byte__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_write_byte__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2248] rom_write_byte::rom_ptr1_return#0 = rom_write_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_write_byte::bank_set_brom1
    // BROM = bank
    // [2249] BROM = rom_write_byte::rom_bank1_return#0 -- vbuz1=vbuz2 
    lda.z rom_bank1_return
    sta.z BROM
    // rom_write_byte::@1
    // *ptr_rom = value
    // [2250] *((char *)rom_write_byte::rom_ptr1_return#0) = rom_write_byte::value#10 -- _deref_pbuz1=vbuz2 
    lda.z value
    ldy #0
    sta (rom_ptr1_return),y
    // rom_write_byte::@return
    // }
    // [2251] return 
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
    // [2253] return 
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
// __mem() int ferror(__zp($3e) struct $2 *stream)
ferror: {
    .label ferror__6 = $33
    .label ferror__15 = $e5
    .label cbm_k_setnam1_ferror__0 = $53
    .label cbm_k_readst1_status = $f0
    .label cbm_k_chrin2_ch = $f1
    .label stream = $3e
    .label sp = $75
    .label cbm_k_chrin1_return = $e5
    .label ch = $e5
    .label cbm_k_readst1_return = $33
    .label st = $33
    .label errno_len = $e6
    .label cbm_k_chrin2_return = $e5
    .label errno_parsed = $e9
    // unsigned char sp = (unsigned char)stream
    // [2254] ferror::sp#0 = (char)ferror::stream#0 -- vbuz1=_byte_pssz2 
    lda.z stream
    sta.z sp
    // cbm_k_setlfs(15, 8, 15)
    // [2255] cbm_k_setlfs::channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.channel
    // [2256] cbm_k_setlfs::device = 8 -- vbum1=vbuc1 
    lda #8
    sta cbm_k_setlfs.device
    // [2257] cbm_k_setlfs::command = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.command
    // [2258] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // ferror::@11
    // cbm_k_setnam("")
    // [2259] ferror::cbm_k_setnam1_filename = info_text5 -- pbum1=pbuc1 
    lda #<info_text5
    sta cbm_k_setnam1_filename
    lda #>info_text5
    sta cbm_k_setnam1_filename+1
    // ferror::cbm_k_setnam1
    // strlen(filename)
    // [2260] strlen::str#5 = ferror::cbm_k_setnam1_filename -- pbuz1=pbum2 
    lda cbm_k_setnam1_filename
    sta.z strlen.str
    lda cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [2261] call strlen
    // [1975] phi from ferror::cbm_k_setnam1 to strlen [phi:ferror::cbm_k_setnam1->strlen]
    // [1975] phi strlen::str#8 = strlen::str#5 [phi:ferror::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [2262] strlen::return#12 = strlen::len#2
    // ferror::@12
    // [2263] ferror::cbm_k_setnam1_$0 = strlen::return#12
    // char filename_len = (char)strlen(filename)
    // [2264] ferror::cbm_k_setnam1_filename_len = (char)ferror::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
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
    // [2267] ferror::cbm_k_chkin1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_chkin1_channel
    // ferror::cbm_k_chkin1
    // char status
    // [2268] ferror::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // ferror::cbm_k_chrin1
    // char ch
    // [2270] ferror::cbm_k_chrin1_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin1_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin1_ch
    // return ch;
    // [2272] ferror::cbm_k_chrin1_return#0 = ferror::cbm_k_chrin1_ch -- vbuz1=vbum2 
    sta.z cbm_k_chrin1_return
    // ferror::cbm_k_chrin1_@return
    // }
    // [2273] ferror::cbm_k_chrin1_return#1 = ferror::cbm_k_chrin1_return#0
    // ferror::@7
    // char ch = cbm_k_chrin()
    // [2274] ferror::ch#0 = ferror::cbm_k_chrin1_return#1
    // [2275] phi from ferror::@7 to ferror::cbm_k_readst1 [phi:ferror::@7->ferror::cbm_k_readst1]
    // [2275] phi __errno#176 = __errno#295 [phi:ferror::@7->ferror::cbm_k_readst1#0] -- register_copy 
    // [2275] phi ferror::errno_len#10 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z errno_len
    // [2275] phi ferror::ch#10 = ferror::ch#0 [phi:ferror::@7->ferror::cbm_k_readst1#2] -- register_copy 
    // [2275] phi ferror::errno_parsed#2 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#3] -- vbuz1=vbuc1 
    sta.z errno_parsed
    // ferror::cbm_k_readst1
  cbm_k_readst1:
    // char status
    // [2276] ferror::cbm_k_readst1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2278] ferror::cbm_k_readst1_return#0 = ferror::cbm_k_readst1_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst1_return
    // ferror::cbm_k_readst1_@return
    // }
    // [2279] ferror::cbm_k_readst1_return#1 = ferror::cbm_k_readst1_return#0
    // ferror::@8
    // cbm_k_readst()
    // [2280] ferror::$6 = ferror::cbm_k_readst1_return#1
    // st = cbm_k_readst()
    // [2281] ferror::st#1 = ferror::$6
    // while (!(st = cbm_k_readst()))
    // [2282] if(0==ferror::st#1) goto ferror::@1 -- 0_eq_vbuz1_then_la1 
    lda.z st
    beq __b1
    // ferror::@2
    // __status = st
    // [2283] ((char *)&__stdio_file+$118)[ferror::sp#0] = ferror::st#1 -- pbuc1_derefidx_vbuz1=vbuz2 
    ldy.z sp
    sta __stdio_file+$118,y
    // cbm_k_close(15)
    // [2284] ferror::cbm_k_close1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_close1_channel
    // ferror::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // ferror::@9
    // return __errno;
    // [2286] ferror::return#1 = __errno#176 -- vwsm1=vwsz2 
    lda.z __errno
    sta return
    lda.z __errno+1
    sta return+1
    // ferror::@return
    // }
    // [2287] return 
    rts
    // ferror::@1
  __b1:
    // if (!errno_parsed)
    // [2288] if(0!=ferror::errno_parsed#2) goto ferror::@3 -- 0_neq_vbuz1_then_la1 
    lda.z errno_parsed
    bne __b3
    // ferror::@4
    // if (ch == ',')
    // [2289] if(ferror::ch#10!=',') goto ferror::@3 -- vbuz1_neq_vbuc1_then_la1 
    lda #','
    cmp.z ch
    bne __b3
    // ferror::@5
    // errno_parsed++;
    // [2290] ferror::errno_parsed#1 = ++ ferror::errno_parsed#2 -- vbuz1=_inc_vbuz1 
    inc.z errno_parsed
    // strncpy(temp, __errno_error, errno_len+1)
    // [2291] strncpy::n#0 = ferror::errno_len#10 + 1 -- vwuz1=vbuz2_plus_1 
    lda.z errno_len
    clc
    adc #1
    sta.z strncpy.n
    lda #0
    adc #0
    sta.z strncpy.n+1
    // [2292] call strncpy
    // [2391] phi from ferror::@5 to strncpy [phi:ferror::@5->strncpy]
    jsr strncpy
    // [2293] phi from ferror::@5 to ferror::@13 [phi:ferror::@5->ferror::@13]
    // ferror::@13
    // atoi(temp)
    // [2294] call atoi
    // [2306] phi from ferror::@13 to atoi [phi:ferror::@13->atoi]
    // [2306] phi atoi::str#2 = ferror::temp [phi:ferror::@13->atoi#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z atoi.str
    lda #>temp
    sta.z atoi.str+1
    jsr atoi
    // atoi(temp)
    // [2295] atoi::return#4 = atoi::return#2
    // ferror::@14
    // __errno = atoi(temp)
    // [2296] __errno#2 = atoi::return#4 -- vwsz1=vwsz2 
    lda.z atoi.return
    sta.z __errno
    lda.z atoi.return+1
    sta.z __errno+1
    // [2297] phi from ferror::@1 ferror::@14 ferror::@4 to ferror::@3 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3]
    // [2297] phi __errno#101 = __errno#176 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#0] -- register_copy 
    // [2297] phi ferror::errno_parsed#11 = ferror::errno_parsed#2 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#1] -- register_copy 
    // ferror::@3
  __b3:
    // __errno_error[errno_len] = ch
    // [2298] __errno_error[ferror::errno_len#10] = ferror::ch#10 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z ch
    ldy.z errno_len
    sta __errno_error,y
    // errno_len++;
    // [2299] ferror::errno_len#1 = ++ ferror::errno_len#10 -- vbuz1=_inc_vbuz1 
    inc.z errno_len
    // ferror::cbm_k_chrin2
    // char ch
    // [2300] ferror::cbm_k_chrin2_ch = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chrin2_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin2_ch
    // return ch;
    // [2302] ferror::cbm_k_chrin2_return#0 = ferror::cbm_k_chrin2_ch -- vbuz1=vbuz2 
    sta.z cbm_k_chrin2_return
    // ferror::cbm_k_chrin2_@return
    // }
    // [2303] ferror::cbm_k_chrin2_return#1 = ferror::cbm_k_chrin2_return#0
    // ferror::@10
    // cbm_k_chrin()
    // [2304] ferror::$15 = ferror::cbm_k_chrin2_return#1
    // ch = cbm_k_chrin()
    // [2305] ferror::ch#1 = ferror::$15
    // [2275] phi from ferror::@10 to ferror::cbm_k_readst1 [phi:ferror::@10->ferror::cbm_k_readst1]
    // [2275] phi __errno#176 = __errno#101 [phi:ferror::@10->ferror::cbm_k_readst1#0] -- register_copy 
    // [2275] phi ferror::errno_len#10 = ferror::errno_len#1 [phi:ferror::@10->ferror::cbm_k_readst1#1] -- register_copy 
    // [2275] phi ferror::ch#10 = ferror::ch#1 [phi:ferror::@10->ferror::cbm_k_readst1#2] -- register_copy 
    // [2275] phi ferror::errno_parsed#2 = ferror::errno_parsed#11 [phi:ferror::@10->ferror::cbm_k_readst1#3] -- register_copy 
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
// __zp($c1) int atoi(__zp($d3) const char *str)
atoi: {
    .label atoi__6 = $c1
    .label atoi__7 = $c1
    .label res = $c1
    // Initialize sign as positive
    .label i = $cc
    .label return = $c1
    .label str = $d3
    // Initialize result
    .label negative = $d5
    .label atoi__10 = $48
    .label atoi__11 = $c1
    // if (str[i] == '-')
    // [2307] if(*atoi::str#2!='-') goto atoi::@3 -- _deref_pbuz1_neq_vbuc1_then_la1 
    ldy #0
    lda (str),y
    cmp #'-'
    bne __b2
    // [2308] phi from atoi to atoi::@2 [phi:atoi->atoi::@2]
    // atoi::@2
    // [2309] phi from atoi::@2 to atoi::@3 [phi:atoi::@2->atoi::@3]
    // [2309] phi atoi::negative#2 = 1 [phi:atoi::@2->atoi::@3#0] -- vbuz1=vbuc1 
    lda #1
    sta.z negative
    // [2309] phi atoi::res#2 = 0 [phi:atoi::@2->atoi::@3#1] -- vwsz1=vwsc1 
    tya
    sta.z res
    sta.z res+1
    // [2309] phi atoi::i#4 = 1 [phi:atoi::@2->atoi::@3#2] -- vbuz1=vbuc1 
    lda #1
    sta.z i
    jmp __b3
  // Iterate through all digits and update the result
    // [2309] phi from atoi to atoi::@3 [phi:atoi->atoi::@3]
  __b2:
    // [2309] phi atoi::negative#2 = 0 [phi:atoi->atoi::@3#0] -- vbuz1=vbuc1 
    lda #0
    sta.z negative
    // [2309] phi atoi::res#2 = 0 [phi:atoi->atoi::@3#1] -- vwsz1=vwsc1 
    sta.z res
    sta.z res+1
    // [2309] phi atoi::i#4 = 0 [phi:atoi->atoi::@3#2] -- vbuz1=vbuc1 
    sta.z i
    // atoi::@3
  __b3:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [2310] if(atoi::str#2[atoi::i#4]<'0') goto atoi::@5 -- pbuz1_derefidx_vbuz2_lt_vbuc1_then_la1 
    ldy.z i
    lda (str),y
    cmp #'0'
    bcc __b5
    // atoi::@6
    // [2311] if(atoi::str#2[atoi::i#4]<='9') goto atoi::@4 -- pbuz1_derefidx_vbuz2_le_vbuc1_then_la1 
    lda (str),y
    cmp #'9'
    bcc __b4
    beq __b4
    // atoi::@5
  __b5:
    // if(negative)
    // [2312] if(0!=atoi::negative#2) goto atoi::@1 -- 0_neq_vbuz1_then_la1 
    // Return result with sign
    lda.z negative
    bne __b1
    // [2314] phi from atoi::@1 atoi::@5 to atoi::@return [phi:atoi::@1/atoi::@5->atoi::@return]
    // [2314] phi atoi::return#2 = atoi::return#0 [phi:atoi::@1/atoi::@5->atoi::@return#0] -- register_copy 
    rts
    // atoi::@1
  __b1:
    // return -res;
    // [2313] atoi::return#0 = - atoi::res#2 -- vwsz1=_neg_vwsz1 
    lda #0
    sec
    sbc.z return
    sta.z return
    lda #0
    sbc.z return+1
    sta.z return+1
    // atoi::@return
    // }
    // [2315] return 
    rts
    // atoi::@4
  __b4:
    // res * 10
    // [2316] atoi::$10 = atoi::res#2 << 2 -- vwsz1=vwsz2_rol_2 
    lda.z res
    asl
    sta.z atoi__10
    lda.z res+1
    rol
    sta.z atoi__10+1
    asl.z atoi__10
    rol.z atoi__10+1
    // [2317] atoi::$11 = atoi::$10 + atoi::res#2 -- vwsz1=vwsz2_plus_vwsz1 
    clc
    lda.z atoi__11
    adc.z atoi__10
    sta.z atoi__11
    lda.z atoi__11+1
    adc.z atoi__10+1
    sta.z atoi__11+1
    // [2318] atoi::$6 = atoi::$11 << 1 -- vwsz1=vwsz1_rol_1 
    asl.z atoi__6
    rol.z atoi__6+1
    // res * 10 + str[i]
    // [2319] atoi::$7 = atoi::$6 + atoi::str#2[atoi::i#4] -- vwsz1=vwsz1_plus_pbuz2_derefidx_vbuz3 
    ldy.z i
    lda.z atoi__7
    clc
    adc (str),y
    sta.z atoi__7
    bcc !+
    inc.z atoi__7+1
  !:
    // res = res * 10 + str[i] - '0'
    // [2320] atoi::res#1 = atoi::$7 - '0' -- vwsz1=vwsz1_minus_vbuc1 
    lda.z res
    sec
    sbc #'0'
    sta.z res
    bcs !+
    dec.z res+1
  !:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [2321] atoi::i#2 = ++ atoi::i#4 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2309] phi from atoi::@4 to atoi::@3 [phi:atoi::@4->atoi::@3]
    // [2309] phi atoi::negative#2 = atoi::negative#2 [phi:atoi::@4->atoi::@3#0] -- register_copy 
    // [2309] phi atoi::res#2 = atoi::res#1 [phi:atoi::@4->atoi::@3#1] -- register_copy 
    // [2309] phi atoi::i#4 = atoi::i#2 [phi:atoi::@4->atoi::@3#2] -- register_copy 
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
// __zp($76) unsigned int cx16_k_macptr(__zp($c7) volatile char bytes, __zp($c3) void * volatile buffer)
cx16_k_macptr: {
    .label bytes = $c7
    .label buffer = $c3
    .label bytes_read = $af
    .label return = $76
    // unsigned int bytes_read
    // [2322] cx16_k_macptr::bytes_read = 0 -- vwuz1=vwuc1 
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
    // [2324] cx16_k_macptr::return#0 = cx16_k_macptr::bytes_read -- vwuz1=vwuz2 
    lda.z bytes_read
    sta.z return
    lda.z bytes_read+1
    sta.z return+1
    // cx16_k_macptr::@return
    // }
    // [2325] cx16_k_macptr::return#1 = cx16_k_macptr::return#0
    // [2326] return 
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
// __zp($25) char uctoa_append(__zp($6e) char *buffer, __zp($25) char value, __zp($2c) char sub)
uctoa_append: {
    .label buffer = $6e
    .label value = $25
    .label sub = $2c
    .label return = $25
    .label digit = $31
    // [2328] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [2328] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [2328] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [2329] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbuz1_ge_vbuz2_then_la1 
    lda.z value
    cmp.z sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [2330] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [2331] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [2332] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [2333] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbuz1=vbuz1_minus_vbuz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    // [2328] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [2328] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [2328] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
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
// __zp($75) char rom_byte_compare(__zp($53) char *ptr_rom, __zp($70) char value)
rom_byte_compare: {
    .label return = $75
    .label ptr_rom = $53
    .label value = $70
    // if (*ptr_rom != value)
    // [2334] if(*rom_byte_compare::ptr_rom#0==rom_byte_compare::value#0) goto rom_byte_compare::@1 -- _deref_pbuz1_eq_vbuz2_then_la1 
    lda.z value
    ldy #0
    cmp (ptr_rom),y
    beq __b2
    // [2335] phi from rom_byte_compare to rom_byte_compare::@2 [phi:rom_byte_compare->rom_byte_compare::@2]
    // rom_byte_compare::@2
    // [2336] phi from rom_byte_compare::@2 to rom_byte_compare::@1 [phi:rom_byte_compare::@2->rom_byte_compare::@1]
    // [2336] phi rom_byte_compare::return#0 = 0 [phi:rom_byte_compare::@2->rom_byte_compare::@1#0] -- vbuz1=vbuc1 
    tya
    sta.z return
    rts
    // [2336] phi from rom_byte_compare to rom_byte_compare::@1 [phi:rom_byte_compare->rom_byte_compare::@1]
  __b2:
    // [2336] phi rom_byte_compare::return#0 = 1 [phi:rom_byte_compare->rom_byte_compare::@1#0] -- vbuz1=vbuc1 
    lda #1
    sta.z return
    // rom_byte_compare::@1
    // rom_byte_compare::@return
    // }
    // [2337] return 
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
// __zp($26) unsigned long ultoa_append(__zp($6c) char *buffer, __zp($26) unsigned long value, __zp($3a) unsigned long sub)
ultoa_append: {
    .label buffer = $6c
    .label value = $26
    .label sub = $3a
    .label return = $26
    .label digit = $32
    // [2339] phi from ultoa_append to ultoa_append::@1 [phi:ultoa_append->ultoa_append::@1]
    // [2339] phi ultoa_append::digit#2 = 0 [phi:ultoa_append->ultoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [2339] phi ultoa_append::value#2 = ultoa_append::value#0 [phi:ultoa_append->ultoa_append::@1#1] -- register_copy 
    // ultoa_append::@1
  __b1:
    // while (value >= sub)
    // [2340] if(ultoa_append::value#2>=ultoa_append::sub#0) goto ultoa_append::@2 -- vduz1_ge_vduz2_then_la1 
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
    // [2341] *ultoa_append::buffer#0 = DIGITS[ultoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // ultoa_append::@return
    // }
    // [2342] return 
    rts
    // ultoa_append::@2
  __b2:
    // digit++;
    // [2343] ultoa_append::digit#1 = ++ ultoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [2344] ultoa_append::value#1 = ultoa_append::value#2 - ultoa_append::sub#0 -- vduz1=vduz1_minus_vduz2 
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
    // [2339] phi from ultoa_append::@2 to ultoa_append::@1 [phi:ultoa_append::@2->ultoa_append::@1]
    // [2339] phi ultoa_append::digit#2 = ultoa_append::digit#1 [phi:ultoa_append::@2->ultoa_append::@1#0] -- register_copy 
    // [2339] phi ultoa_append::value#2 = ultoa_append::value#1 [phi:ultoa_append::@2->ultoa_append::@1#1] -- register_copy 
    jmp __b1
}
  // cputs
// Output a NUL-terminated string at the current cursor position
// void cputs(__zp($38) const char *s)
cputs: {
    .label c = $75
    .label s = $38
    // [2346] phi from cputs to cputs::@1 [phi:cputs->cputs::@1]
    // [2346] phi cputs::s#2 = rom_flash::s [phi:cputs->cputs::@1#0] -- pbuz1=pbuc1 
    lda #<rom_flash.s
    sta.z s
    lda #>rom_flash.s
    sta.z s+1
    // cputs::@1
  __b1:
    // while(c=*s++)
    // [2347] cputs::c#1 = *cputs::s#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta.z c
    // [2348] cputs::s#0 = ++ cputs::s#2 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [2349] if(0!=cputs::c#1) goto cputs::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // cputs::@return
    // }
    // [2350] return 
    rts
    // cputs::@2
  __b2:
    // cputc(c)
    // [2351] stackpush(char) = cputs::c#1 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [2352] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [2346] phi from cputs::@2 to cputs::@1 [phi:cputs::@2->cputs::@1]
    // [2346] phi cputs::s#2 = cputs::s#0 [phi:cputs::@2->cputs::@1#0] -- register_copy 
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
// void rom_wait(__zp($38) char *ptr_rom)
rom_wait: {
    .label rom_wait__0 = $33
    .label rom_wait__1 = $24
    .label test1 = $33
    .label test2 = $24
    .label ptr_rom = $38
    // rom_wait::@1
  __b1:
    // test1 = *((brom_ptr_t)ptr_rom)
    // [2355] rom_wait::test1#1 = *rom_wait::ptr_rom#3 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (ptr_rom),y
    sta.z test1
    // test2 = *((brom_ptr_t)ptr_rom)
    // [2356] rom_wait::test2#1 = *rom_wait::ptr_rom#3 -- vbuz1=_deref_pbuz2 
    lda (ptr_rom),y
    sta.z test2
    // test1 & 0x40
    // [2357] rom_wait::$0 = rom_wait::test1#1 & $40 -- vbuz1=vbuz1_band_vbuc1 
    lda #$40
    and.z rom_wait__0
    sta.z rom_wait__0
    // test2 & 0x40
    // [2358] rom_wait::$1 = rom_wait::test2#1 & $40 -- vbuz1=vbuz1_band_vbuc1 
    lda #$40
    and.z rom_wait__1
    sta.z rom_wait__1
    // while ((test1 & 0x40) != (test2 & 0x40))
    // [2359] if(rom_wait::$0!=rom_wait::$1) goto rom_wait::@1 -- vbuz1_neq_vbuz2_then_la1 
    lda.z rom_wait__0
    cmp.z rom_wait__1
    bne __b1
    // rom_wait::@return
    // }
    // [2360] return 
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
// void rom_byte_program(__zp($55) unsigned long address, __zp($5b) char value)
rom_byte_program: {
    .label rom_ptr1_rom_byte_program__0 = $5d
    .label rom_ptr1_rom_byte_program__2 = $5d
    .label rom_ptr1_return = $5d
    .label address = $55
    .label value = $5b
    // rom_byte_program::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2362] rom_byte_program::rom_ptr1_$2 = (unsigned int)rom_byte_program::address#0 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_byte_program__2
    lda.z address+1
    sta.z rom_ptr1_rom_byte_program__2+1
    // [2363] rom_byte_program::rom_ptr1_$0 = rom_byte_program::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_byte_program__0
    and #<$3fff
    sta.z rom_ptr1_rom_byte_program__0
    lda.z rom_ptr1_rom_byte_program__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_byte_program__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2364] rom_byte_program::rom_ptr1_return#0 = rom_byte_program::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_byte_program::@1
    // rom_write_byte(address, value)
    // [2365] rom_write_byte::address#3 = rom_byte_program::address#0
    // [2366] rom_write_byte::value#3 = rom_byte_program::value#0
    // [2367] call rom_write_byte
    // [2240] phi from rom_byte_program::@1 to rom_write_byte [phi:rom_byte_program::@1->rom_write_byte]
    // [2240] phi rom_write_byte::value#10 = rom_write_byte::value#3 [phi:rom_byte_program::@1->rom_write_byte#0] -- register_copy 
    // [2240] phi rom_write_byte::address#4 = rom_write_byte::address#3 [phi:rom_byte_program::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_byte_program::@2
    // rom_wait(ptr_rom)
    // [2368] rom_wait::ptr_rom#1 = (char *)rom_byte_program::rom_ptr1_return#0 -- pbuz1=pbuz2 
    lda.z rom_ptr1_return
    sta.z rom_wait.ptr_rom
    lda.z rom_ptr1_return+1
    sta.z rom_wait.ptr_rom+1
    // [2369] call rom_wait
    // [2354] phi from rom_byte_program::@2 to rom_wait [phi:rom_byte_program::@2->rom_wait]
    // [2354] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#1 [phi:rom_byte_program::@2->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_byte_program::@return
    // }
    // [2370] return 
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
// void memcpy8_vram_vram(__zp($2e) char dbank_vram, __zp($41) unsigned int doffset_vram, __zp($2d) char sbank_vram, __zp($36) unsigned int soffset_vram, __zp($23) char num8)
memcpy8_vram_vram: {
    .label memcpy8_vram_vram__0 = $2f
    .label memcpy8_vram_vram__1 = $30
    .label memcpy8_vram_vram__2 = $2d
    .label memcpy8_vram_vram__3 = $34
    .label memcpy8_vram_vram__4 = $35
    .label memcpy8_vram_vram__5 = $2e
    .label num8 = $23
    .label dbank_vram = $2e
    .label doffset_vram = $41
    .label sbank_vram = $2d
    .label soffset_vram = $36
    .label num8_1 = $22
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2371] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [2372] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte0_vwuz2 
    lda.z soffset_vram
    sta.z memcpy8_vram_vram__0
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [2373] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [2374] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte1_vwuz2 
    lda.z soffset_vram+1
    sta.z memcpy8_vram_vram__1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [2375] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [2376] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuz1=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z memcpy8_vram_vram__2
    sta.z memcpy8_vram_vram__2
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [2377] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [2378] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [2379] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte0_vwuz2 
    lda.z doffset_vram
    sta.z memcpy8_vram_vram__3
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [2380] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [2381] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte1_vwuz2 
    lda.z doffset_vram+1
    sta.z memcpy8_vram_vram__4
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [2382] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [2383] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuz1=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z memcpy8_vram_vram__5
    sta.z memcpy8_vram_vram__5
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [2384] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // [2385] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [2385] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [2386] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbuz1=_dec_vbuz2 
    ldy.z num8_1
    dey
    sty.z num8
    // [2387] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbuz1_then_la1 
    lda.z num8_1
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [2388] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [2389] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [2390] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbuz1=vbuz2 
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
// char * strncpy(__zp($cf) char *dst, __zp($ca) const char *src, __zp($4a) unsigned int n)
strncpy: {
    .label c = $24
    .label dst = $cf
    .label i = $cd
    .label src = $ca
    .label n = $4a
    // [2392] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [2392] phi strncpy::dst#2 = ferror::temp [phi:strncpy->strncpy::@1#0] -- pbuz1=pbuc1 
    lda #<ferror.temp
    sta.z dst
    lda #>ferror.temp
    sta.z dst+1
    // [2392] phi strncpy::src#2 = __errno_error [phi:strncpy->strncpy::@1#1] -- pbuz1=pbuc1 
    lda #<__errno_error
    sta.z src
    lda #>__errno_error
    sta.z src+1
    // [2392] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwuz1=vwuc1 
    lda #<0
    sta.z i
    sta.z i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [2393] if(strncpy::i#2<strncpy::n#0) goto strncpy::@2 -- vwuz1_lt_vwuz2_then_la1 
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
    // [2394] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [2395] strncpy::c#0 = *strncpy::src#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta.z c
    // if(c)
    // [2396] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbuz1_then_la1 
    beq __b3
    // strncpy::@4
    // src++;
    // [2397] strncpy::src#0 = ++ strncpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [2398] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [2398] phi strncpy::src#6 = strncpy::src#2 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [2399] *strncpy::dst#2 = strncpy::c#0 -- _deref_pbuz1=vbuz2 
    lda.z c
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [2400] strncpy::dst#0 = ++ strncpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [2401] strncpy::i#1 = ++ strncpy::i#2 -- vwuz1=_inc_vwuz1 
    inc.z i
    bne !+
    inc.z i+1
  !:
    // [2392] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [2392] phi strncpy::dst#2 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [2392] phi strncpy::src#2 = strncpy::src#6 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [2392] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
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
  rom_manufacturer_ids: .byte 0
  .fill 7, 0
  rom_sizes: .dword 0
  .fill 4*7, 0
  file_sizes: .dword 0
  .fill 4*7, 0
  status_text: .word __3, __4, __5, __6, __7, __8, __9, __10, __11, __12
  status_color: .byte BLACK, GREY, WHITE, CYAN, CYAN, CYAN, PURPLE, GREEN, YELLOW, RED
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
  __7: .text "Comparing"
  .byte 0
  __8: .text "Flash"
  .byte 0
  __9: .text "Flashing"
  .byte 0
  __10: .text "Flashed"
  .byte 0
  __11: .text "Issue"
  .byte 0
  __12: .text "Error"
  .byte 0
  info_text5: .text ""
  .byte 0
  s1: .text "/"
  .byte 0
  s2: .text " -> RAM:"
  .byte 0
  s3: .text ":"
  .byte 0
  s4: .text " ..."
  .byte 0
  s10: .text "Reading "
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
  status_smc: .byte 0
  status_vera: .byte 0
  smc_bootloader: .word 0
  smc_file_size: .word 0
  smc_file_size_1: .word 0
  smc_file_size_2: .word 0
