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
  .label __errno = $eb
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
// void snputc(__mem() char c)
snputc: {
    .const OFFSET_STACK_C = 0
    // [10] snputc::c#0 = stackidx(char,snputc::OFFSET_STACK_C) -- vbum1=_stackidxbyte_vbuc1 
    tsx
    lda STACK_BASE+OFFSET_STACK_C,x
    sta c
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
    // [16] phi snputc::c#2 = 0 [phi:snputc::@1->snputc::@2#0] -- vbum1=vbuc1 
    lda #0
    sta c
    // [15] phi from snputc::@1 to snputc::@3 [phi:snputc::@1->snputc::@3]
    // snputc::@3
    // [16] phi from snputc::@3 to snputc::@2 [phi:snputc::@3->snputc::@2]
    // [16] phi snputc::c#2 = snputc::c#0 [phi:snputc::@3->snputc::@2#0] -- register_copy 
    // snputc::@2
  __b2:
    // *(__snprintf_buffer++) = c
    // [17] *__snprintf_buffer = snputc::c#2 -- _deref_pbum1=vbum2 
    // Append char
    lda c
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
  .segment Data
    c: .byte 0
}
.segment Code
  // conio_x16_init
/// Set initial screen values.
conio_x16_init: {
    .label conio_x16_init__5 = $db
    // screenlayer1()
    // [20] call screenlayer1
    jsr screenlayer1
    // [21] phi from conio_x16_init to conio_x16_init::@1 [phi:conio_x16_init->conio_x16_init::@1]
    // conio_x16_init::@1
    // textcolor(CONIO_TEXTCOLOR_DEFAULT)
    // [22] call textcolor
    // [374] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [374] phi textcolor::color#16 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [23] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [24] call bgcolor
    // [379] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [379] phi bgcolor::color#14 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbuz1=vbuc1 
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
    // [392] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [392] phi gotoxy::y#26 = gotoxy::y#2 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [392] phi gotoxy::x#26 = gotoxy::x#2 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
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
// void cputc(__zp($30) char c)
cputc: {
    .const OFFSET_STACK_C = 0
    .label cputc__1 = $22
    .label cputc__2 = $a9
    .label cputc__3 = $aa
    .label c = $30
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
    .const bank_set_brom5_bank = 4
    .const bank_set_brom6_bank = 0
    .label main__34 = $c0
    .label main__107 = $f3
    .label rom_differences = $37
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
    // main::@43
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
    // [77] phi from main::cx16_k_screen_set_charset1 to main::@44 [phi:main::cx16_k_screen_set_charset1->main::@44]
    // main::@44
    // frame_init()
    // [78] call frame_init
    // [413] phi from main::@44 to frame_init [phi:main::@44->frame_init]
    jsr frame_init
    // [79] phi from main::@44 to main::@55 [phi:main::@44->main::@55]
    // main::@55
    // frame_draw()
    // [80] call frame_draw
    // [433] phi from main::@55 to frame_draw [phi:main::@55->frame_draw]
    jsr frame_draw
    // [81] phi from main::@55 to main::@56 [phi:main::@55->main::@56]
    // main::@56
    // info_title("Commander X16 Flash Utility!")
    // [82] call info_title
    // [476] phi from main::@56 to info_title [phi:main::@56->info_title]
    jsr info_title
    // [83] phi from main::@56 to main::@57 [phi:main::@56->main::@57]
    // main::@57
    // progress_clear()
    // [84] call progress_clear
    // [481] phi from main::@57 to progress_clear [phi:main::@57->progress_clear]
    jsr progress_clear
    // [85] phi from main::@57 to main::@58 [phi:main::@57->main::@58]
    // main::@58
    // info_clear_all()
    // [86] call info_clear_all
    // [496] phi from main::@58 to info_clear_all [phi:main::@58->info_clear_all]
    jsr info_clear_all
    // [87] phi from main::@58 to main::@59 [phi:main::@58->main::@59]
    // main::@59
    // info_progress("Detecting SMC, VERA and ROM chipsets ...")
    // [88] call info_progress
  // info_print(0, "The SMC chip on the X16 board controls the power on/off, keyboard and mouse pheripherals.");
  // info_print(1, "It is essential that the SMC chip gets updated together with the latest ROM on the X16 board.");
  // info_print(2, "On the X16 board, near the SMC chip are two jumpers");
    // [506] phi from main::@59 to info_progress [phi:main::@59->info_progress]
    // [506] phi info_progress::info_text#4 = main::info_text1 [phi:main::@59->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z info_progress.info_text
    lda #>info_text1
    sta.z info_progress.info_text+1
    jsr info_progress
    // main::SEI1
    // asm
    // asm { sei  }
    sei
    // [90] phi from main::SEI1 to main::@45 [phi:main::SEI1->main::@45]
    // main::@45
    // smc_detect()
    // [91] call smc_detect
    // [520] phi from main::@45 to smc_detect [phi:main::@45->smc_detect]
    jsr smc_detect
    // [92] phi from main::@45 to main::@60 [phi:main::@45->main::@60]
    // main::@60
    // chip_smc()
    // [93] call chip_smc
    // [522] phi from main::@60 to chip_smc [phi:main::@60->chip_smc]
    jsr chip_smc
    // [94] phi from main::@60 to main::@5 [phi:main::@60->main::@5]
    // main::@5
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [95] call snprintf_init
    jsr snprintf_init
    // [96] phi from main::@5 to main::@61 [phi:main::@5->main::@61]
    // main::@61
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [97] call printf_str
    // [531] phi from main::@61 to printf_str [phi:main::@61->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:main::@61->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = main::s2 [phi:main::@61->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // [98] phi from main::@61 to main::@62 [phi:main::@61->main::@62]
    // main::@62
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [99] call printf_uint
    // [540] phi from main::@62 to printf_uint [phi:main::@62->printf_uint]
    // [540] phi printf_uint::format_zero_padding#12 = 1 [phi:main::@62->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [540] phi printf_uint::format_min_length#12 = 2 [phi:main::@62->printf_uint#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uint.format_min_length
    // [540] phi printf_uint::putc#12 = &snputc [phi:main::@62->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [540] phi printf_uint::format_radix#12 = HEXADECIMAL [phi:main::@62->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [540] phi printf_uint::uvalue#12 = smc_detect::return#0 [phi:main::@62->printf_uint#4] -- vwuz1=vwuc1 
    lda #<smc_detect.return
    sta.z printf_uint.uvalue
    lda #>smc_detect.return
    sta.z printf_uint.uvalue+1
    jsr printf_uint
    // main::@63
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [100] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [101] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_smc(STATUS_DETECTED, info_text)
    // [103] call info_smc
    // [551] phi from main::@63 to info_smc [phi:main::@63->info_smc]
    // [551] phi info_smc::info_text#10 = info_text [phi:main::@63->info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_smc.info_text
    lda #>@info_text
    sta.z info_smc.info_text+1
    // [551] phi smc_file_size#12 = 0 [phi:main::@63->info_smc#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size_1
    sta smc_file_size_1+1
    // [551] phi info_smc::info_status#10 = 0 [phi:main::@63->info_smc#2] -- vbum1=vbuc1 
    sta info_smc.info_status
    jsr info_smc
    // main::CLI1
    // asm
    // asm { cli  }
    cli
    // [105] phi from main::CLI1 to main::@46 [phi:main::CLI1->main::@46]
    // main::@46
    // chip_vera()
    // [106] call chip_vera
  // Detecting VERA FPGA.
    // [570] phi from main::@46 to chip_vera [phi:main::@46->chip_vera]
    jsr chip_vera
    // [107] phi from main::@46 to main::@64 [phi:main::@46->main::@64]
    // main::@64
    // info_vera(STATUS_DETECTED, "VERA installed, OK")
    // [108] call info_vera
    jsr info_vera
    // main::SEI2
    // asm
    // asm { sei  }
    sei
    // [110] phi from main::SEI2 to main::@47 [phi:main::SEI2->main::@47]
    // main::@47
    // rom_detect()
    // [111] call rom_detect
  // Detecting ROM chips
    // [588] phi from main::@47 to rom_detect [phi:main::@47->rom_detect]
    jsr rom_detect
    // [112] phi from main::@47 to main::@65 [phi:main::@47->main::@65]
    // main::@65
    // chip_rom()
    // [113] call chip_rom
    // [646] phi from main::@65 to chip_rom [phi:main::@65->chip_rom]
    jsr chip_rom
    // [114] phi from main::@65 to main::@10 [phi:main::@65->main::@10]
    // [114] phi main::rom_error#102 = 0 [phi:main::@65->main::@10#0] -- vbum1=vbuc1 
    lda #0
    sta rom_error
    // [114] phi main::rom_chip#10 = 0 [phi:main::@65->main::@10#1] -- vbum1=vbuc1 
    sta rom_chip
    // main::@10
  __b10:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [115] if(main::rom_chip#10<8) goto main::@11 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcs !__b11+
    jmp __b11
  !__b11:
    // main::CLI2
    // asm
    // asm { cli  }
    cli
    // main::bank_set_brom2
    // BROM = bank
    // [117] BROM = main::bank_set_brom2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom2_bank
    sta.z BROM
    // main::@121
    // if (smc_error || rom_error || vera_error)
    // [118] if(0!=main::rom_error#102) goto main::@19 -- 0_neq_vbum1_then_la1 
    lda rom_error
    beq !__b19+
    jmp __b19
  !__b19:
    // [119] phi from main::@121 main::@68 to main::@1 [phi:main::@121/main::@68->main::@1]
    // main::@1
  __b1:
    // info_progress("Checking files SMC.BIN, VERA.BIN, ROM(x).BIN: (.) data, ( ) empty")
    // [120] call info_progress
    // [506] phi from main::@1 to info_progress [phi:main::@1->info_progress]
    // [506] phi info_progress::info_text#4 = main::info_text9 [phi:main::@1->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text9
    sta.z info_progress.info_text
    lda #>info_text9
    sta.z info_progress.info_text+1
    jsr info_progress
    // main::SEI3
    // asm
    // asm { sei  }
    sei
    // [122] phi from main::SEI3 to main::@48 [phi:main::SEI3->main::@48]
    // main::@48
    // info_smc(STATUS_CHECKING, "Checking SMC.BIN file contents ...")
    // [123] call info_smc
  // Read the smc file content.
    // [551] phi from main::@48 to info_smc [phi:main::@48->info_smc]
    // [551] phi info_smc::info_text#10 = main::info_text10 [phi:main::@48->info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text10
    sta.z info_smc.info_text
    lda #>info_text10
    sta.z info_smc.info_text+1
    // [551] phi smc_file_size#12 = 0 [phi:main::@48->info_smc#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size_1
    sta smc_file_size_1+1
    // [551] phi info_smc::info_status#10 = 2 [phi:main::@48->info_smc#2] -- vbum1=vbuc1 
    lda #2
    sta info_smc.info_status
    jsr info_smc
    // [124] phi from main::@48 to main::@66 [phi:main::@48->main::@66]
    // main::@66
    // smc_read(PROGRESS_X, PROGRESS_Y, PROGRESS_W, 8, 512, (ram_ptr_t)RAM_BASE)
    // [125] call smc_read
    // [664] phi from main::@66 to smc_read [phi:main::@66->smc_read]
    jsr smc_read
    // smc_read(PROGRESS_X, PROGRESS_Y, PROGRESS_W, 8, 512, (ram_ptr_t)RAM_BASE)
    // [126] smc_read::return#2 = smc_read::return#0
    // main::@67
    // smc_file_size = smc_read(PROGRESS_X, PROGRESS_Y, PROGRESS_W, 8, 512, (ram_ptr_t)RAM_BASE)
    // [127] smc_file_size#0 = smc_read::return#2 -- vwum1=vwuz2 
    lda.z smc_read.return
    sta smc_file_size
    lda.z smc_read.return+1
    sta smc_file_size+1
    // if (!smc_file_size)
    // [128] if(0==smc_file_size#0) goto main::@2 -- 0_eq_vwum1_then_la1 
    // In case no file was found, set the status to error and skip to the next, else, mention the amount of bytes read.
    lda smc_file_size
    ora smc_file_size+1
    bne !__b2+
    jmp __b2
  !__b2:
    // main::@6
    // if(smc_file_size > 0x1E00)
    // [129] if(smc_file_size#0>$1e00) goto main::@20 -- vwum1_gt_vwuc1_then_la1 
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
    // [130] phi from main::@6 to main::@7 [phi:main::@6->main::@7]
    // main::@7
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [131] call snprintf_init
    jsr snprintf_init
    // [132] phi from main::@7 to main::@69 [phi:main::@7->main::@69]
    // main::@69
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [133] call printf_str
    // [531] phi from main::@69 to printf_str [phi:main::@69->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:main::@69->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = main::s2 [phi:main::@69->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // [134] phi from main::@69 to main::@70 [phi:main::@69->main::@70]
    // main::@70
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [135] call printf_uint
    // [540] phi from main::@70 to printf_uint [phi:main::@70->printf_uint]
    // [540] phi printf_uint::format_zero_padding#12 = 1 [phi:main::@70->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [540] phi printf_uint::format_min_length#12 = 2 [phi:main::@70->printf_uint#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uint.format_min_length
    // [540] phi printf_uint::putc#12 = &snputc [phi:main::@70->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [540] phi printf_uint::format_radix#12 = HEXADECIMAL [phi:main::@70->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [540] phi printf_uint::uvalue#12 = smc_detect::return#0 [phi:main::@70->printf_uint#4] -- vwuz1=vwuc1 
    lda #<smc_detect.return
    sta.z printf_uint.uvalue
    lda #>smc_detect.return
    sta.z printf_uint.uvalue+1
    jsr printf_uint
    // main::@71
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [136] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [137] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [139] smc_file_size#202 = smc_file_size#0 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_1
    lda smc_file_size+1
    sta smc_file_size_1+1
    // info_smc(STATUS_CHECKED, info_text)
    // [140] call info_smc
    // [551] phi from main::@71 to info_smc [phi:main::@71->info_smc]
    // [551] phi info_smc::info_text#10 = info_text [phi:main::@71->info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_smc.info_text
    lda #>@info_text
    sta.z info_smc.info_text+1
    // [551] phi smc_file_size#12 = smc_file_size#202 [phi:main::@71->info_smc#1] -- register_copy 
    // [551] phi info_smc::info_status#10 = 3 [phi:main::@71->info_smc#2] -- vbum1=vbuc1 
    lda #3
    sta info_smc.info_status
    jsr info_smc
    // [141] phi from main::@71 to main::CLI3 [phi:main::@71->main::CLI3]
    // [141] phi main::smc_error#56 = 0 [phi:main::@71->main::CLI3#0] -- vbum1=vbuc1 
    lda #0
    sta smc_error
    // main::CLI3
  CLI3:
    // asm
    // asm { cli  }
    cli
    // main::SEI4
    // asm { sei  }
    sei
    // [144] phi from main::SEI4 to main::@21 [phi:main::SEI4->main::@21]
    // [144] phi __errno#103 = __errno#153 [phi:main::SEI4->main::@21#0] -- register_copy 
    // [144] phi main::rom_error#10 = main::rom_error#102 [phi:main::SEI4->main::@21#1] -- register_copy 
    // [144] phi main::rom_chip1#10 = 0 [phi:main::SEI4->main::@21#2] -- vbum1=vbuc1 
    lda #0
    sta rom_chip1
  // For checking, we loop first all the ROM chips and check the file contents.
  // Any error identified gets reported and this chip will not be flashed.
  // In case of ROM0.BIN in error, no flashing will be done!
    // main::@21
  __b21:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [145] if(main::rom_chip1#10<8) goto main::bank_set_brom3 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip1
    cmp #8
    bcs !bank_set_brom3+
    jmp bank_set_brom3
  !bank_set_brom3:
    // main::bank_set_brom4
    // BROM = bank
    // [146] BROM = main::bank_set_brom4_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom4_bank
    sta.z BROM
    // main::CLI4
    // asm
    // asm { cli  }
    cli
    // [148] phi from main::CLI4 to main::@50 [phi:main::CLI4->main::@50]
    // main::@50
    // unsigned char ch = wait_key("Continue with flashing? [Y/N]", "nyNY")
    // [149] call wait_key
    // [697] phi from main::@50 to wait_key [phi:main::@50->wait_key]
    // [697] phi wait_key::filter#13 = main::filter1 [phi:main::@50->wait_key#0] -- pbuz1=pbuc1 
    lda #<filter1
    sta.z wait_key.filter
    lda #>filter1
    sta.z wait_key.filter+1
    // [697] phi wait_key::info_text#3 = main::info_text14 [phi:main::@50->wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text14
    sta.z wait_key.info_text
    lda #>info_text14
    sta.z wait_key.info_text+1
    jsr wait_key
    // unsigned char ch = wait_key("Continue with flashing? [Y/N]", "nyNY")
    // [150] wait_key::return#3 = wait_key::ch#4 -- vbum1=vwum2 
    lda wait_key.ch
    sta wait_key.return
    // main::@78
    // [151] main::ch#0 = wait_key::return#3
    // strchr("nN", ch)
    // [152] strchr::c#1 = main::ch#0
    // [153] call strchr
    // [721] phi from main::@78 to strchr [phi:main::@78->strchr]
    // [721] phi strchr::c#4 = strchr::c#1 [phi:main::@78->strchr#0] -- register_copy 
    // [721] phi strchr::str#2 = (const void *)main::$150 [phi:main::@78->strchr#1] -- pvoz1=pvoc1 
    lda #<main__150
    sta.z strchr.str
    lda #>main__150
    sta.z strchr.str+1
    jsr strchr
    // strchr("nN", ch)
    // [154] strchr::return#4 = strchr::return#2
    // main::@79
    // [155] main::$34 = strchr::return#4
    // if(strchr("nN", ch))
    // [156] if((void *)0==main::$34) goto main::@3 -- pvoc1_eq_pvoz1_then_la1 
    lda.z main__34
    cmp #<0
    bne !+
    lda.z main__34+1
    cmp #>0
    beq __b3
  !:
    // [157] phi from main::@79 to main::@28 [phi:main::@79->main::@28]
    // main::@28
    // info_line("The checked chipset does not match the flash requirements, exiting ... ")
    // [158] call info_line
    // [730] phi from main::@28 to info_line [phi:main::@28->info_line]
    // [730] phi info_line::info_text#18 = main::info_text16 [phi:main::@28->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text16
    sta.z info_line.info_text
    lda #>info_text16
    sta.z info_line.info_text+1
    jsr info_line
    // main::@return
    // }
    // [159] return 
    rts
    // main::@3
  __b3:
    // if (!smc_error && !rom_error && !flash_error && !vera_error)
    // [160] if(0!=main::smc_error#56) goto main::@4 -- 0_neq_vbum1_then_la1 
    lda smc_error
    bne __b7
    // main::@122
    // [161] if(0!=main::rom_error#10) goto main::@4 -- 0_neq_vbum1_then_la1 
    lda rom_error
    bne __b4
    // main::SEI5
    // asm
    // asm { sei  }
    sei
    // [163] phi from main::SEI5 to main::@52 [phi:main::SEI5->main::@52]
    // main::@52
    // info_line("Flashing SMC chip ...")
    // [164] call info_line
  // Flash the SMC chip.
    // [730] phi from main::@52 to info_line [phi:main::@52->info_line]
    // [730] phi info_line::info_text#18 = main::info_text17 [phi:main::@52->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text17
    sta.z info_line.info_text
    lda #>info_text17
    sta.z info_line.info_text+1
    jsr info_line
    // main::@94
    // if (!smc_file_size)
    // [165] if(0!=smc_file_size#0) goto main::@29 -- 0_neq_vwum1_then_la1 
    lda smc_file_size
    ora smc_file_size+1
    bne __b5
    // [166] phi from main::@94 to main::@8 [phi:main::@94->main::@8]
    // main::@8
    // info_line("To flash the SMC chip, press both POWER/RESET buttons on the CX16 board!")
    // [167] call info_line
    // [730] phi from main::@8 to info_line [phi:main::@8->info_line]
    // [730] phi info_line::info_text#18 = main::info_text18 [phi:main::@8->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text18
    sta.z info_line.info_text
    lda #>info_text18
    sta.z info_line.info_text+1
    jsr info_line
    // main::@95
    // [168] smc_file_size#203 = smc_file_size#0 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_1
    lda smc_file_size+1
    sta smc_file_size_1+1
    // info_smc(STATUS_FLASHING, "Press POWER/RESET!")
    // [169] call info_smc
    // [551] phi from main::@95 to info_smc [phi:main::@95->info_smc]
    // [551] phi info_smc::info_text#10 = main::info_text19 [phi:main::@95->info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text19
    sta.z info_smc.info_text
    lda #>info_text19
    sta.z info_smc.info_text+1
    // [551] phi smc_file_size#12 = smc_file_size#203 [phi:main::@95->info_smc#1] -- register_copy 
    // [551] phi info_smc::info_status#10 = 6 [phi:main::@95->info_smc#2] -- vbum1=vbuc1 
    lda #6
    sta info_smc.info_status
    jsr info_smc
    // main::@96
    // unsigned long flashed_bytes = flash_smc(PROGRESS_X, PROGRESS_Y, PROGRESS_W, smc_file_size, 8, 512, (ram_ptr_t)RAM_BASE)
    // [170] flash_smc::smc_bytes_total#0 = smc_file_size#0 -- vwuz1=vwum2 
    lda smc_file_size
    sta.z flash_smc.smc_bytes_total
    lda smc_file_size+1
    sta.z flash_smc.smc_bytes_total+1
    // [171] call flash_smc
    jsr flash_smc
    // main::@97
    // [172] smc_file_size#204 = smc_file_size#0 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_1
    lda smc_file_size+1
    sta smc_file_size_1+1
    // info_smc(STATUS_FLASHED, "OK!")
    // [173] call info_smc
    // [551] phi from main::@97 to info_smc [phi:main::@97->info_smc]
    // [551] phi info_smc::info_text#10 = main::info_text7 [phi:main::@97->info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z info_smc.info_text
    lda #>info_text7
    sta.z info_smc.info_text+1
    // [551] phi smc_file_size#12 = smc_file_size#204 [phi:main::@97->info_smc#1] -- register_copy 
    // [551] phi info_smc::info_status#10 = 7 [phi:main::@97->info_smc#2] -- vbum1=vbuc1 
    lda #7
    sta info_smc.info_status
    jsr info_smc
    // [174] phi from main::@94 main::@97 to main::@29 [phi:main::@94/main::@97->main::@29]
  __b5:
    // [174] phi __errno#105 = __errno#103 [phi:main::@94/main::@97->main::@29#0] -- register_copy 
    // [174] phi main::flash_error#12 = 0 [phi:main::@94/main::@97->main::@29#1] -- vbum1=vbuc1 
    lda #0
    sta flash_error
    // [174] phi main::rom_chip2#10 = 0 [phi:main::@94/main::@97->main::@29#2] -- vbum1=vbuc1 
    sta rom_chip2
  // Flash the ROM chips. 
  // We loop first all the ROM chips and read the file contents.
  // Then we verify the file contents and flash the ROM only for the differences.
  // If the file contents are the same as the ROM contents, then no flashing is required.
    // main::@29
  __b29:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [175] if(main::rom_chip2#10<8) goto main::bank_set_brom6 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip2
    cmp #8
    bcs !bank_set_brom6+
    jmp bank_set_brom6
  !bank_set_brom6:
    // [176] phi from main::@29 to main::@4 [phi:main::@29->main::@4]
    // [176] phi main::flash_error#10 = main::flash_error#12 [phi:main::@29->main::@4#0] -- register_copy 
    jmp __b4
    // [176] phi from main::@122 to main::@4 [phi:main::@122->main::@4]
    // [176] phi from main::@3 to main::@4 [phi:main::@3->main::@4]
  __b7:
    // [176] phi main::flash_error#10 = 0 [phi:main::@3->main::@4#0] -- vbum1=vbuc1 
    lda #0
    sta flash_error
    // main::@4
  __b4:
    // main::bank_set_brom5
    // BROM = bank
    // [177] BROM = main::bank_set_brom5_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom5_bank
    sta.z BROM
    // main::CLI5
    // asm
    // asm { cli  }
    cli
    // main::@51
    // if(smc_error || rom_error || vera_error || flash_error)
    // [179] if(0!=main::smc_error#56) goto main::vera_display_set_border_color1 -- 0_neq_vbum1_then_la1 
    lda smc_error
    beq !vera_display_set_border_color1+
    jmp vera_display_set_border_color1
  !vera_display_set_border_color1:
    // main::@124
    // [180] if(0!=main::rom_error#10) goto main::vera_display_set_border_color1 -- 0_neq_vbum1_then_la1 
    lda rom_error
    beq !vera_display_set_border_color1+
    jmp vera_display_set_border_color1
  !vera_display_set_border_color1:
    // main::@123
    // [181] if(0!=main::flash_error#10) goto main::vera_display_set_border_color1 -- 0_neq_vbum1_then_la1 
    lda flash_error
    beq !vera_display_set_border_color1+
    jmp vera_display_set_border_color1
  !vera_display_set_border_color1:
    // [182] phi from main::@123 to main::@9 [phi:main::@123->main::@9]
    // main::@9
    // wait_key("Flashing success, press any key to reset your CX16 ...", NULL)
    // [183] call wait_key
    // [697] phi from main::@9 to wait_key [phi:main::@9->wait_key]
    // [697] phi wait_key::filter#13 = 0 [phi:main::@9->wait_key#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z wait_key.filter
    sta.z wait_key.filter+1
    // [697] phi wait_key::info_text#3 = main::info_text25 [phi:main::@9->wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text25
    sta.z wait_key.info_text
    lda #>info_text25
    sta.z wait_key.info_text+1
    jsr wait_key
    // [184] phi from main::@9 to main::@38 [phi:main::@9->main::@38]
    // [184] phi main::flash_reset#10 = 0 [phi:main::@9->main::@38#0] -- vbum1=vbuc1 
    lda #0
    sta flash_reset
    // main::@38
  __b38:
    // for(unsigned char flash_reset=0; flash_reset<120; flash_reset++)
    // [185] if(main::flash_reset#10<$78) goto main::@40 -- vbum1_lt_vbuc1_then_la1 
    lda flash_reset
    cmp #$78
    bcc __b8
    // [186] phi from main::@38 to main::@39 [phi:main::@38->main::@39]
    // main::@39
    // system_reset()
    // [187] call system_reset
    // [908] phi from main::@39 to system_reset [phi:main::@39->system_reset]
    jsr system_reset
    rts
    // [188] phi from main::@38 to main::@40 [phi:main::@38->main::@40]
  __b8:
    // [188] phi main::reset_wait#2 = 0 [phi:main::@38->main::@40#0] -- vwum1=vwuc1 
    lda #<0
    sta reset_wait
    sta reset_wait+1
    // main::@40
  __b40:
    // for(unsigned int reset_wait=0; reset_wait<0xFFFF; reset_wait++)
    // [189] if(main::reset_wait#2<$ffff) goto main::@41 -- vwum1_lt_vwuc1_then_la1 
    lda reset_wait+1
    cmp #>$ffff
    bcc __b41
    bne !+
    lda reset_wait
    cmp #<$ffff
    bcc __b41
  !:
    // [190] phi from main::@40 to main::@42 [phi:main::@40->main::@42]
    // main::@42
    // sprintf(info_text, "Resetting your CX16 ... (%u)", flash_reset)
    // [191] call snprintf_init
    jsr snprintf_init
    // [192] phi from main::@42 to main::@116 [phi:main::@42->main::@116]
    // main::@116
    // sprintf(info_text, "Resetting your CX16 ... (%u)", flash_reset)
    // [193] call printf_str
    // [531] phi from main::@116 to printf_str [phi:main::@116->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:main::@116->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = main::s15 [phi:main::@116->printf_str#1] -- pbuz1=pbuc1 
    lda #<s15
    sta.z printf_str.s
    lda #>s15
    sta.z printf_str.s+1
    jsr printf_str
    // main::@117
    // sprintf(info_text, "Resetting your CX16 ... (%u)", flash_reset)
    // [194] printf_uchar::uvalue#7 = main::flash_reset#10 -- vbuz1=vbum2 
    lda flash_reset
    sta.z printf_uchar.uvalue
    // [195] call printf_uchar
    // [913] phi from main::@117 to printf_uchar [phi:main::@117->printf_uchar]
    // [913] phi printf_uchar::format_zero_padding#10 = 0 [phi:main::@117->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [913] phi printf_uchar::format_min_length#10 = 0 [phi:main::@117->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [913] phi printf_uchar::putc#10 = &snputc [phi:main::@117->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [913] phi printf_uchar::format_radix#10 = DECIMAL [phi:main::@117->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [913] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#7 [phi:main::@117->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [196] phi from main::@117 to main::@118 [phi:main::@117->main::@118]
    // main::@118
    // sprintf(info_text, "Resetting your CX16 ... (%u)", flash_reset)
    // [197] call printf_str
    // [531] phi from main::@118 to printf_str [phi:main::@118->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:main::@118->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = main::s16 [phi:main::@118->printf_str#1] -- pbuz1=pbuc1 
    lda #<s16
    sta.z printf_str.s
    lda #>s16
    sta.z printf_str.s+1
    jsr printf_str
    // main::@119
    // sprintf(info_text, "Resetting your CX16 ... (%u)", flash_reset)
    // [198] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [199] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [201] call info_line
    // [730] phi from main::@119 to info_line [phi:main::@119->info_line]
    // [730] phi info_line::info_text#18 = info_text [phi:main::@119->info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_line.info_text
    lda #>@info_text
    sta.z info_line.info_text+1
    jsr info_line
    // main::@120
    // for(unsigned char flash_reset=0; flash_reset<120; flash_reset++)
    // [202] main::flash_reset#1 = ++ main::flash_reset#10 -- vbum1=_inc_vbum1 
    inc flash_reset
    // [184] phi from main::@120 to main::@38 [phi:main::@120->main::@38]
    // [184] phi main::flash_reset#10 = main::flash_reset#1 [phi:main::@120->main::@38#0] -- register_copy 
    jmp __b38
    // main::@41
  __b41:
    // for(unsigned int reset_wait=0; reset_wait<0xFFFF; reset_wait++)
    // [203] main::reset_wait#1 = ++ main::reset_wait#2 -- vwum1=_inc_vwum1 
    inc reset_wait
    bne !+
    inc reset_wait+1
  !:
    // [188] phi from main::@41 to main::@40 [phi:main::@41->main::@40]
    // [188] phi main::reset_wait#2 = main::reset_wait#1 [phi:main::@41->main::@40#0] -- register_copy 
    jmp __b40
    // main::vera_display_set_border_color1
  vera_display_set_border_color1:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [204] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [205] *VERA_DC_BORDER = RED -- _deref_pbuc1=vbuc2 
    lda #RED
    sta VERA_DC_BORDER
    // [206] phi from main::vera_display_set_border_color1 to main::@54 [phi:main::vera_display_set_border_color1->main::@54]
    // main::@54
    // info_line("FLASH ERRORS! Your CX16 may be bricked! Take a foto of your screen!")
    // [207] call info_line
    // [730] phi from main::@54 to info_line [phi:main::@54->info_line]
    // [730] phi info_line::info_text#18 = main::info_text24 [phi:main::@54->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text24
    sta.z info_line.info_text
    lda #>info_text24
    sta.z info_line.info_text+1
    jsr info_line
    // [208] phi from main::@37 main::@54 to main::@37 [phi:main::@37/main::@54->main::@37]
    // main::@37
  __b37:
    jmp __b37
    // main::bank_set_brom6
  bank_set_brom6:
    // BROM = bank
    // [209] BROM = main::bank_set_brom6_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom6_bank
    sta.z BROM
    // main::@53
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [210] if(rom_device_ids[main::rom_chip2#10]==$55) goto main::@30 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    ldy rom_chip2
    lda rom_device_ids,y
    cmp #$55
    bne !__b30+
    jmp __b30
  !__b30:
    // [211] phi from main::@53 to main::@33 [phi:main::@53->main::@33]
    // main::@33
    // strcpy(file, "ROM .BIN")
    // [212] call strcpy
    // [924] phi from main::@33 to strcpy [phi:main::@33->strcpy]
    // [924] phi strcpy::dst#0 = file [phi:main::@33->strcpy#0] -- pbuz1=pbuc1 
    lda #<file
    sta.z strcpy.dst
    lda #>file
    sta.z strcpy.dst+1
    // [924] phi strcpy::src#0 = main::source [phi:main::@33->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // main::@98
    // 48+rom_chip
    // [213] main::$107 = $30 + main::rom_chip2#10 -- vbuz1=vbuc1_plus_vbum2 
    lda #$30
    clc
    adc rom_chip2
    sta.z main__107
    // file[3] = 48+rom_chip
    // [214] *(file+3) = main::$107 -- _deref_pbuc1=vbuz1 
    sta file+3
    // sprintf(info_text, "Reading ROM file %s ...", file)
    // [215] call snprintf_init
    jsr snprintf_init
    // [216] phi from main::@98 to main::@99 [phi:main::@98->main::@99]
    // main::@99
    // sprintf(info_text, "Reading ROM file %s ...", file)
    // [217] call printf_str
    // [531] phi from main::@99 to printf_str [phi:main::@99->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:main::@99->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = main::s11 [phi:main::@99->printf_str#1] -- pbuz1=pbuc1 
    lda #<s11
    sta.z printf_str.s
    lda #>s11
    sta.z printf_str.s+1
    jsr printf_str
    // [218] phi from main::@99 to main::@100 [phi:main::@99->main::@100]
    // main::@100
    // sprintf(info_text, "Reading ROM file %s ...", file)
    // [219] call printf_string
    // [932] phi from main::@100 to printf_string [phi:main::@100->printf_string]
    // [932] phi printf_string::putc#14 = &snputc [phi:main::@100->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [932] phi printf_string::str#14 = file [phi:main::@100->printf_string#1] -- pbuz1=pbuc1 
    lda #<file
    sta.z printf_string.str
    lda #>file
    sta.z printf_string.str+1
    // [932] phi printf_string::format_justify_left#14 = 0 [phi:main::@100->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [932] phi printf_string::format_min_length#14 = 0 [phi:main::@100->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [220] phi from main::@100 to main::@101 [phi:main::@100->main::@101]
    // main::@101
    // sprintf(info_text, "Reading ROM file %s ...", file)
    // [221] call printf_str
    // [531] phi from main::@101 to printf_str [phi:main::@101->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:main::@101->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = s5 [phi:main::@101->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // main::@102
    // sprintf(info_text, "Reading ROM file %s ...", file)
    // [222] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [223] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [225] call info_line
    // [730] phi from main::@102 to info_line [phi:main::@102->info_line]
    // [730] phi info_line::info_text#18 = info_text [phi:main::@102->info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_line.info_text
    lda #>@info_text
    sta.z info_line.info_text+1
    jsr info_line
    // [226] phi from main::@102 to main::@103 [phi:main::@102->main::@103]
    // main::@103
    // progress_clear()
    // [227] call progress_clear
    // [481] phi from main::@103 to progress_clear [phi:main::@103->progress_clear]
    jsr progress_clear
    // main::@104
    // unsigned char rom_bank = rom_chip * 32
    // [228] main::rom_bank1#0 = main::rom_chip2#10 << 5 -- vbum1=vbum2_rol_5 
    lda rom_chip2
    asl
    asl
    asl
    asl
    asl
    sta rom_bank1
    // unsigned long rom_bytes_read = rom_read(rom_bank, rom_sizes[rom_chip])
    // [229] main::$135 = main::rom_chip2#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip2
    asl
    asl
    sta main__135
    // [230] rom_read::rom_bank_start#2 = main::rom_bank1#0 -- vbum1=vbum2 
    lda rom_bank1
    sta rom_read.rom_bank_start
    // [231] rom_read::rom_size#1 = rom_sizes[main::$135] -- vdum1=pduc1_derefidx_vbum2 
    ldy main__135
    lda rom_sizes,y
    sta rom_read.rom_size
    lda rom_sizes+1,y
    sta rom_read.rom_size+1
    lda rom_sizes+2,y
    sta rom_read.rom_size+2
    lda rom_sizes+3,y
    sta rom_read.rom_size+3
    // [232] call rom_read
    // [957] phi from main::@104 to rom_read [phi:main::@104->rom_read]
    // [957] phi rom_read::rom_size#12 = rom_read::rom_size#1 [phi:main::@104->rom_read#0] -- register_copy 
    // [957] phi __errno#35 = __errno#105 [phi:main::@104->rom_read#1] -- register_copy 
    // [957] phi rom_read::rom_bank_start#11 = rom_read::rom_bank_start#2 [phi:main::@104->rom_read#2] -- register_copy 
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(rom_bank, rom_sizes[rom_chip])
    // [233] rom_read::return#3 = rom_read::return#0
    // main::@105
    // [234] main::rom_bytes_read1#0 = rom_read::return#3
    // if(rom_bytes_read)
    // [235] if(0==main::rom_bytes_read1#0) goto main::@30 -- 0_eq_vdum1_then_la1 
    lda rom_bytes_read1
    ora rom_bytes_read1+1
    ora rom_bytes_read1+2
    ora rom_bytes_read1+3
    bne !__b30+
    jmp __b30
  !__b30:
    // main::@34
    // info_rom(rom_chip, STATUS_EQUATING, "")
    // [236] info_rom::rom_chip#12 = main::rom_chip2#10 -- vbuz1=vbum2 
    lda rom_chip2
    sta.z info_rom.rom_chip
    // [237] call info_rom
    // [1001] phi from main::@34 to info_rom [phi:main::@34->info_rom]
    // [1001] phi info_rom::info_text#17 = info_text5 [phi:main::@34->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z info_rom.info_text
    lda #>info_text5
    sta.z info_rom.info_text+1
    // [1001] phi info_rom::info_status#17 = 4 [phi:main::@34->info_rom#1] -- vbuz1=vbuc1 
    lda #4
    sta.z info_rom.info_status
    // [1001] phi info_rom::rom_chip#17 = info_rom::rom_chip#12 [phi:main::@34->info_rom#2] -- register_copy 
    jsr info_rom
    // main::@106
    // unsigned long rom_differences = rom_verify(
    //                         rom_chip, rom_bank, file_sizes[rom_chip])
    // [238] rom_verify::rom_chip#0 = main::rom_chip2#10 -- vbum1=vbum2 
    lda rom_chip2
    sta rom_verify.rom_chip
    // [239] rom_verify::rom_bank_start#0 = main::rom_bank1#0 -- vbuz1=vbum2 
    lda rom_bank1
    sta.z rom_verify.rom_bank_start
    // [240] rom_verify::file_size#0 = file_sizes[main::$135] -- vduz1=pduc1_derefidx_vbum2 
    ldy main__135
    lda file_sizes,y
    sta.z rom_verify.file_size
    lda file_sizes+1,y
    sta.z rom_verify.file_size+1
    lda file_sizes+2,y
    sta.z rom_verify.file_size+2
    lda file_sizes+3,y
    sta.z rom_verify.file_size+3
    // [241] call rom_verify
  // Verify the ROM...
    // [1035] phi from main::@106 to rom_verify [phi:main::@106->rom_verify]
    jsr rom_verify
    // unsigned long rom_differences = rom_verify(
    //                         rom_chip, rom_bank, file_sizes[rom_chip])
    // [242] rom_verify::return#2 = rom_verify::rom_different_bytes#10
    // main::@107
    // [243] main::rom_differences#0 = rom_verify::return#2 -- vduz1=vduz2 
    lda.z rom_verify.return
    sta.z rom_differences
    lda.z rom_verify.return+1
    sta.z rom_differences+1
    lda.z rom_verify.return+2
    sta.z rom_differences+2
    lda.z rom_verify.return+3
    sta.z rom_differences+3
    // if (!rom_differences)
    // [244] if(0==main::rom_differences#0) goto main::@31 -- 0_eq_vduz1_then_la1 
    lda.z rom_differences
    ora.z rom_differences+1
    ora.z rom_differences+2
    ora.z rom_differences+3
    bne !__b31+
    jmp __b31
  !__b31:
    // [245] phi from main::@107 to main::@35 [phi:main::@107->main::@35]
    // main::@35
    // sprintf(info_text, "%05x differences found!", rom_differences)
    // [246] call snprintf_init
    jsr snprintf_init
    // main::@108
    // [247] printf_ulong::uvalue#5 = main::rom_differences#0
    // [248] call printf_ulong
    // [1101] phi from main::@108 to printf_ulong [phi:main::@108->printf_ulong]
    // [1101] phi printf_ulong::putc#10 = &snputc [phi:main::@108->printf_ulong#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1101] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#5 [phi:main::@108->printf_ulong#1] -- register_copy 
    jsr printf_ulong
    // [249] phi from main::@108 to main::@109 [phi:main::@108->main::@109]
    // main::@109
    // sprintf(info_text, "%05x differences found!", rom_differences)
    // [250] call printf_str
    // [531] phi from main::@109 to printf_str [phi:main::@109->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:main::@109->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = main::s13 [phi:main::@109->printf_str#1] -- pbuz1=pbuc1 
    lda #<s13
    sta.z printf_str.s
    lda #>s13
    sta.z printf_str.s+1
    jsr printf_str
    // main::@110
    // sprintf(info_text, "%05x differences found!", rom_differences)
    // [251] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [252] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom(rom_chip, STATUS_EQUATED, info_text)
    // [254] info_rom::rom_chip#14 = main::rom_chip2#10 -- vbuz1=vbum2 
    lda rom_chip2
    sta.z info_rom.rom_chip
    // [255] call info_rom
    // [1001] phi from main::@110 to info_rom [phi:main::@110->info_rom]
    // [1001] phi info_rom::info_text#17 = info_text [phi:main::@110->info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_rom.info_text
    lda #>@info_text
    sta.z info_rom.info_text+1
    // [1001] phi info_rom::info_status#17 = 5 [phi:main::@110->info_rom#1] -- vbuz1=vbuc1 
    lda #5
    sta.z info_rom.info_status
    // [1001] phi info_rom::rom_chip#17 = info_rom::rom_chip#14 [phi:main::@110->info_rom#2] -- register_copy 
    jsr info_rom
    // main::@111
    // unsigned long rom_flash_errors = rom_flash(
    //                             rom_chip, rom_bank, file_sizes[rom_chip])
    // [256] rom_flash::rom_chip#0 = main::rom_chip2#10 -- vbum1=vbum2 
    lda rom_chip2
    sta rom_flash.rom_chip
    // [257] rom_flash::rom_bank_start#0 = main::rom_bank1#0 -- vbum1=vbum2 
    lda rom_bank1
    sta rom_flash.rom_bank_start
    // [258] rom_flash::file_size#0 = file_sizes[main::$135] -- vdum1=pduc1_derefidx_vbum2 
    ldy main__135
    lda file_sizes,y
    sta rom_flash.file_size
    lda file_sizes+1,y
    sta rom_flash.file_size+1
    lda file_sizes+2,y
    sta rom_flash.file_size+2
    lda file_sizes+3,y
    sta rom_flash.file_size+3
    // [259] call rom_flash
  // Now we can flash the ROM ...
    // [1109] phi from main::@111 to rom_flash [phi:main::@111->rom_flash]
    jsr rom_flash
    // unsigned long rom_flash_errors = rom_flash(
    //                             rom_chip, rom_bank, file_sizes[rom_chip])
    // [260] rom_flash::return#2 = rom_flash::flash_errors#2 -- vdum1=vwuz2 
    lda.z rom_flash.flash_errors
    sta rom_flash.return
    lda.z rom_flash.flash_errors+1
    sta rom_flash.return+1
    lda #0
    sta rom_flash.return+2
    sta rom_flash.return+3
    // main::@112
    // [261] main::rom_flash_errors#0 = rom_flash::return#2
    // if(!rom_flash_errors)
    // [262] if(0==main::rom_flash_errors#0) goto main::@32 -- 0_eq_vdum1_then_la1 
    lda rom_flash_errors
    ora rom_flash_errors+1
    ora rom_flash_errors+2
    ora rom_flash_errors+3
    beq __b32
    // main::@36
    // info_rom(rom_chip, STATUS_FLASHED, "OK!")
    // [263] info_rom::rom_chip#16 = main::rom_chip2#10 -- vbuz1=vbum2 
    lda rom_chip2
    sta.z info_rom.rom_chip
    // [264] call info_rom
    // [1001] phi from main::@36 to info_rom [phi:main::@36->info_rom]
    // [1001] phi info_rom::info_text#17 = main::info_text7 [phi:main::@36->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z info_rom.info_text
    lda #>info_text7
    sta.z info_rom.info_text+1
    // [1001] phi info_rom::info_status#17 = 7 [phi:main::@36->info_rom#1] -- vbuz1=vbuc1 
    lda #7
    sta.z info_rom.info_status
    // [1001] phi info_rom::rom_chip#17 = info_rom::rom_chip#16 [phi:main::@36->info_rom#2] -- register_copy 
    jsr info_rom
    // [265] phi from main::@105 main::@31 main::@36 main::@53 to main::@30 [phi:main::@105/main::@31/main::@36/main::@53->main::@30]
    // [265] phi __errno#191 = __errno#153 [phi:main::@105/main::@31/main::@36/main::@53->main::@30#0] -- register_copy 
    // [265] phi main::flash_error#15 = main::flash_error#12 [phi:main::@105/main::@31/main::@36/main::@53->main::@30#1] -- register_copy 
    // main::@30
  __b30:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [266] main::rom_chip2#1 = ++ main::rom_chip2#10 -- vbum1=_inc_vbum1 
    inc rom_chip2
    // [174] phi from main::@30 to main::@29 [phi:main::@30->main::@29]
    // [174] phi __errno#105 = __errno#191 [phi:main::@30->main::@29#0] -- register_copy 
    // [174] phi main::flash_error#12 = main::flash_error#15 [phi:main::@30->main::@29#1] -- register_copy 
    // [174] phi main::rom_chip2#10 = main::rom_chip2#1 [phi:main::@30->main::@29#2] -- register_copy 
    jmp __b29
    // [267] phi from main::@112 to main::@32 [phi:main::@112->main::@32]
    // main::@32
  __b32:
    // sprintf(info_text, "%05x flashing errors!", rom_flash_errors)
    // [268] call snprintf_init
    jsr snprintf_init
    // main::@113
    // [269] printf_ulong::uvalue#6 = main::rom_flash_errors#0 -- vduz1=vdum2 
    lda rom_flash_errors
    sta.z printf_ulong.uvalue
    lda rom_flash_errors+1
    sta.z printf_ulong.uvalue+1
    lda rom_flash_errors+2
    sta.z printf_ulong.uvalue+2
    lda rom_flash_errors+3
    sta.z printf_ulong.uvalue+3
    // [270] call printf_ulong
    // [1101] phi from main::@113 to printf_ulong [phi:main::@113->printf_ulong]
    // [1101] phi printf_ulong::putc#10 = &snputc [phi:main::@113->printf_ulong#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1101] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#6 [phi:main::@113->printf_ulong#1] -- register_copy 
    jsr printf_ulong
    // [271] phi from main::@113 to main::@114 [phi:main::@113->main::@114]
    // main::@114
    // sprintf(info_text, "%05x flashing errors!", rom_flash_errors)
    // [272] call printf_str
    // [531] phi from main::@114 to printf_str [phi:main::@114->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:main::@114->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = main::s14 [phi:main::@114->printf_str#1] -- pbuz1=pbuc1 
    lda #<s14
    sta.z printf_str.s
    lda #>s14
    sta.z printf_str.s+1
    jsr printf_str
    // main::@115
    // sprintf(info_text, "%05x flashing errors!", rom_flash_errors)
    // [273] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [274] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom(rom_chip, STATUS_ERROR, info_text)
    // [276] info_rom::rom_chip#15 = main::rom_chip2#10 -- vbuz1=vbum2 
    lda rom_chip2
    sta.z info_rom.rom_chip
    // [277] call info_rom
    // [1001] phi from main::@115 to info_rom [phi:main::@115->info_rom]
    // [1001] phi info_rom::info_text#17 = info_text [phi:main::@115->info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_rom.info_text
    lda #>@info_text
    sta.z info_rom.info_text+1
    // [1001] phi info_rom::info_status#17 = 8 [phi:main::@115->info_rom#1] -- vbuz1=vbuc1 
    lda #8
    sta.z info_rom.info_status
    // [1001] phi info_rom::rom_chip#17 = info_rom::rom_chip#15 [phi:main::@115->info_rom#2] -- register_copy 
    jsr info_rom
    // [265] phi from main::@115 to main::@30 [phi:main::@115->main::@30]
    // [265] phi __errno#191 = __errno#153 [phi:main::@115->main::@30#0] -- register_copy 
    // [265] phi main::flash_error#15 = 1 [phi:main::@115->main::@30#1] -- vbum1=vbuc1 
    lda #1
    sta flash_error
    jmp __b30
    // main::@31
  __b31:
    // info_rom(rom_chip, STATUS_EQUATED, "No flashing required!")
    // [278] info_rom::rom_chip#13 = main::rom_chip2#10 -- vbuz1=vbum2 
    lda rom_chip2
    sta.z info_rom.rom_chip
    // [279] call info_rom
    // [1001] phi from main::@31 to info_rom [phi:main::@31->info_rom]
    // [1001] phi info_rom::info_text#17 = main::info_text22 [phi:main::@31->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text22
    sta.z info_rom.info_text
    lda #>info_text22
    sta.z info_rom.info_text+1
    // [1001] phi info_rom::info_status#17 = 5 [phi:main::@31->info_rom#1] -- vbuz1=vbuc1 
    lda #5
    sta.z info_rom.info_status
    // [1001] phi info_rom::rom_chip#17 = info_rom::rom_chip#13 [phi:main::@31->info_rom#2] -- register_copy 
    jsr info_rom
    jmp __b30
    // main::bank_set_brom3
  bank_set_brom3:
    // BROM = bank
    // [280] BROM = main::bank_set_brom3_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom3_bank
    sta.z BROM
    // [281] phi from main::bank_set_brom3 to main::@49 [phi:main::bank_set_brom3->main::@49]
    // main::@49
    // strcpy(file, "ROM .BIN")
    // [282] call strcpy
    // [924] phi from main::@49 to strcpy [phi:main::@49->strcpy]
    // [924] phi strcpy::dst#0 = file [phi:main::@49->strcpy#0] -- pbuz1=pbuc1 
    lda #<file
    sta.z strcpy.dst
    lda #>file
    sta.z strcpy.dst+1
    // [924] phi strcpy::src#0 = main::source [phi:main::@49->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // main::@72
    // 48+rom_chip
    // [283] main::$76 = $30 + main::rom_chip1#10 -- vbum1=vbuc1_plus_vbum2 
    lda #$30
    clc
    adc rom_chip1
    sta main__76
    // file[3] = 48+rom_chip
    // [284] *(file+3) = main::$76 -- _deref_pbuc1=vbum1 
    sta file+3
    // sprintf(info_text, "Checking ROM file %s ...", file)
    // [285] call snprintf_init
    jsr snprintf_init
    // [286] phi from main::@72 to main::@73 [phi:main::@72->main::@73]
    // main::@73
    // sprintf(info_text, "Checking ROM file %s ...", file)
    // [287] call printf_str
    // [531] phi from main::@73 to printf_str [phi:main::@73->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:main::@73->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = main::s4 [phi:main::@73->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // [288] phi from main::@73 to main::@74 [phi:main::@73->main::@74]
    // main::@74
    // sprintf(info_text, "Checking ROM file %s ...", file)
    // [289] call printf_string
    // [932] phi from main::@74 to printf_string [phi:main::@74->printf_string]
    // [932] phi printf_string::putc#14 = &snputc [phi:main::@74->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [932] phi printf_string::str#14 = file [phi:main::@74->printf_string#1] -- pbuz1=pbuc1 
    lda #<file
    sta.z printf_string.str
    lda #>file
    sta.z printf_string.str+1
    // [932] phi printf_string::format_justify_left#14 = 0 [phi:main::@74->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [932] phi printf_string::format_min_length#14 = 0 [phi:main::@74->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [290] phi from main::@74 to main::@75 [phi:main::@74->main::@75]
    // main::@75
    // sprintf(info_text, "Checking ROM file %s ...", file)
    // [291] call printf_str
    // [531] phi from main::@75 to printf_str [phi:main::@75->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:main::@75->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = s5 [phi:main::@75->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // main::@76
    // sprintf(info_text, "Checking ROM file %s ...", file)
    // [292] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [293] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [295] call info_line
    // [730] phi from main::@76 to info_line [phi:main::@76->info_line]
    // [730] phi info_line::info_text#18 = info_text [phi:main::@76->info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_line.info_text
    lda #>@info_text
    sta.z info_line.info_text+1
    jsr info_line
    // main::@77
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [296] if(rom_device_ids[main::rom_chip1#10]==$55) goto main::@22 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    ldy rom_chip1
    lda rom_device_ids,y
    cmp #$55
    bne !__b22+
    jmp __b22
  !__b22:
    // main::@25
    // info_rom(rom_chip, STATUS_CHECKING, "")
    // [297] info_rom::rom_chip#8 = main::rom_chip1#10 -- vbuz1=vbum2 
    tya
    sta.z info_rom.rom_chip
    // [298] call info_rom
    // [1001] phi from main::@25 to info_rom [phi:main::@25->info_rom]
    // [1001] phi info_rom::info_text#17 = info_text5 [phi:main::@25->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z info_rom.info_text
    lda #>info_text5
    sta.z info_rom.info_text+1
    // [1001] phi info_rom::info_status#17 = 2 [phi:main::@25->info_rom#1] -- vbuz1=vbuc1 
    lda #2
    sta.z info_rom.info_status
    // [1001] phi info_rom::rom_chip#17 = info_rom::rom_chip#8 [phi:main::@25->info_rom#2] -- register_copy 
    jsr info_rom
    // [299] phi from main::@25 to main::@80 [phi:main::@25->main::@80]
    // main::@80
    // progress_clear()
    // [300] call progress_clear
  // Set the info for the ROMs to Checking.
    // [481] phi from main::@80 to progress_clear [phi:main::@80->progress_clear]
    jsr progress_clear
    // main::@81
    // unsigned char rom_bank = rom_chip * 32
    // [301] main::rom_bank#0 = main::rom_chip1#10 << 5 -- vbum1=vbum2_rol_5 
    // sprintf(info_text, "Opening %s flash file from SD card ...", file);
    // info_line(info_text);
    lda rom_chip1
    asl
    asl
    asl
    asl
    asl
    sta rom_bank
    // unsigned long rom_bytes_read = rom_read(rom_bank, rom_sizes[rom_chip])
    // [302] main::$133 = main::rom_chip1#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip1
    asl
    asl
    sta main__133
    // [303] rom_read::rom_bank_start#1 = main::rom_bank#0
    // [304] rom_read::rom_size#0 = rom_sizes[main::$133] -- vdum1=pduc1_derefidx_vbum2 
    tay
    lda rom_sizes,y
    sta rom_read.rom_size
    lda rom_sizes+1,y
    sta rom_read.rom_size+1
    lda rom_sizes+2,y
    sta rom_read.rom_size+2
    lda rom_sizes+3,y
    sta rom_read.rom_size+3
    // [305] call rom_read
    // [957] phi from main::@81 to rom_read [phi:main::@81->rom_read]
    // [957] phi rom_read::rom_size#12 = rom_read::rom_size#0 [phi:main::@81->rom_read#0] -- register_copy 
    // [957] phi __errno#35 = __errno#103 [phi:main::@81->rom_read#1] -- register_copy 
    // [957] phi rom_read::rom_bank_start#11 = rom_read::rom_bank_start#1 [phi:main::@81->rom_read#2] -- register_copy 
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(rom_bank, rom_sizes[rom_chip])
    // [306] rom_read::return#2 = rom_read::return#0
    // main::@82
    // [307] main::rom_bytes_read#0 = rom_read::return#2 -- vdum1=vdum2 
    lda rom_read.return
    sta rom_bytes_read
    lda rom_read.return+1
    sta rom_bytes_read+1
    lda rom_read.return+2
    sta rom_bytes_read+2
    lda rom_read.return+3
    sta rom_bytes_read+3
    // if (!rom_bytes_read)
    // [308] if(0==main::rom_bytes_read#0) goto main::@23 -- 0_eq_vdum1_then_la1 
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
    // [309] main::rom_file_modulo#0 = main::rom_bytes_read#0 & $4000-1 -- vdum1=vdum2_band_vduc1 
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
    // [310] if(0!=main::rom_file_modulo#0) goto main::@24 -- 0_neq_vdum1_then_la1 
    lda rom_file_modulo
    ora rom_file_modulo+1
    ora rom_file_modulo+2
    ora rom_file_modulo+3
    bne __b24
    // [311] phi from main::@26 to main::@27 [phi:main::@26->main::@27]
    // main::@27
    // sprintf(info_text, "OK!", file, rom_bytes_read)
    // [312] call snprintf_init
    jsr snprintf_init
    // [313] phi from main::@27 to main::@91 [phi:main::@27->main::@91]
    // main::@91
    // sprintf(info_text, "OK!", file, rom_bytes_read)
    // [314] call printf_str
    // [531] phi from main::@91 to printf_str [phi:main::@91->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:main::@91->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = main::info_text7 [phi:main::@91->printf_str#1] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z printf_str.s
    lda #>info_text7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@92
    // sprintf(info_text, "OK!", file, rom_bytes_read)
    // [315] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [316] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom(rom_chip, STATUS_CHECKED, info_text)
    // [318] info_rom::rom_chip#11 = main::rom_chip1#10 -- vbuz1=vbum2 
    lda rom_chip1
    sta.z info_rom.rom_chip
    // [319] call info_rom
    // [1001] phi from main::@92 to info_rom [phi:main::@92->info_rom]
    // [1001] phi info_rom::info_text#17 = info_text [phi:main::@92->info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_rom.info_text
    lda #>@info_text
    sta.z info_rom.info_text+1
    // [1001] phi info_rom::info_status#17 = 3 [phi:main::@92->info_rom#1] -- vbuz1=vbuc1 
    lda #3
    sta.z info_rom.info_status
    // [1001] phi info_rom::rom_chip#17 = info_rom::rom_chip#11 [phi:main::@92->info_rom#2] -- register_copy 
    jsr info_rom
    // main::@93
    // file_sizes[rom_chip] = rom_bytes_read
    // [320] file_sizes[main::$133] = main::rom_bytes_read#0 -- pduc1_derefidx_vbum1=vdum2 
    ldy main__133
    lda rom_bytes_read
    sta file_sizes,y
    lda rom_bytes_read+1
    sta file_sizes+1,y
    lda rom_bytes_read+2
    sta file_sizes+2,y
    lda rom_bytes_read+3
    sta file_sizes+3,y
    // [321] phi from main::@77 main::@86 main::@93 to main::@22 [phi:main::@77/main::@86/main::@93->main::@22]
    // [321] phi __errno#156 = __errno#103 [phi:main::@77/main::@86/main::@93->main::@22#0] -- register_copy 
    // [321] phi main::rom_error#50 = main::rom_error#10 [phi:main::@77/main::@86/main::@93->main::@22#1] -- register_copy 
    // main::@22
  __b22:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [322] main::rom_chip1#1 = ++ main::rom_chip1#10 -- vbum1=_inc_vbum1 
    inc rom_chip1
    // [144] phi from main::@22 to main::@21 [phi:main::@22->main::@21]
    // [144] phi __errno#103 = __errno#156 [phi:main::@22->main::@21#0] -- register_copy 
    // [144] phi main::rom_error#10 = main::rom_error#50 [phi:main::@22->main::@21#1] -- register_copy 
    // [144] phi main::rom_chip1#10 = main::rom_chip1#1 [phi:main::@22->main::@21#2] -- register_copy 
    jmp __b21
    // [323] phi from main::@26 to main::@24 [phi:main::@26->main::@24]
    // main::@24
  __b24:
    // sprintf(info_text, "File %s size error!", file)
    // [324] call snprintf_init
    jsr snprintf_init
    // [325] phi from main::@24 to main::@87 [phi:main::@24->main::@87]
    // main::@87
    // sprintf(info_text, "File %s size error!", file)
    // [326] call printf_str
    // [531] phi from main::@87 to printf_str [phi:main::@87->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:main::@87->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = main::s6 [phi:main::@87->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // [327] phi from main::@87 to main::@88 [phi:main::@87->main::@88]
    // main::@88
    // sprintf(info_text, "File %s size error!", file)
    // [328] call printf_string
    // [932] phi from main::@88 to printf_string [phi:main::@88->printf_string]
    // [932] phi printf_string::putc#14 = &snputc [phi:main::@88->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [932] phi printf_string::str#14 = file [phi:main::@88->printf_string#1] -- pbuz1=pbuc1 
    lda #<file
    sta.z printf_string.str
    lda #>file
    sta.z printf_string.str+1
    // [932] phi printf_string::format_justify_left#14 = 0 [phi:main::@88->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [932] phi printf_string::format_min_length#14 = 0 [phi:main::@88->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [329] phi from main::@88 to main::@89 [phi:main::@88->main::@89]
    // main::@89
    // sprintf(info_text, "File %s size error!", file)
    // [330] call printf_str
    // [531] phi from main::@89 to printf_str [phi:main::@89->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:main::@89->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = main::s9 [phi:main::@89->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // main::@90
    // sprintf(info_text, "File %s size error!", file)
    // [331] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [332] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom(rom_chip, STATUS_ERROR, info_text)
    // [334] info_rom::rom_chip#10 = main::rom_chip1#10 -- vbuz1=vbum2 
    lda rom_chip1
    sta.z info_rom.rom_chip
    // [335] call info_rom
    // [1001] phi from main::@90 to info_rom [phi:main::@90->info_rom]
    // [1001] phi info_rom::info_text#17 = info_text [phi:main::@90->info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_rom.info_text
    lda #>@info_text
    sta.z info_rom.info_text+1
    // [1001] phi info_rom::info_status#17 = 8 [phi:main::@90->info_rom#1] -- vbuz1=vbuc1 
    lda #8
    sta.z info_rom.info_status
    // [1001] phi info_rom::rom_chip#17 = info_rom::rom_chip#10 [phi:main::@90->info_rom#2] -- register_copy 
    jsr info_rom
    // [321] phi from main::@90 to main::@22 [phi:main::@90->main::@22]
    // [321] phi __errno#156 = __errno#153 [phi:main::@90->main::@22#0] -- register_copy 
    // [321] phi main::rom_error#50 = 1 [phi:main::@90->main::@22#1] -- vbum1=vbuc1 
    lda #1
    sta rom_error
    jmp __b22
    // [336] phi from main::@82 to main::@23 [phi:main::@82->main::@23]
    // main::@23
  __b23:
    // sprintf(info_text, "File %s error!", file)
    // [337] call snprintf_init
    jsr snprintf_init
    // [338] phi from main::@23 to main::@83 [phi:main::@23->main::@83]
    // main::@83
    // sprintf(info_text, "File %s error!", file)
    // [339] call printf_str
    // [531] phi from main::@83 to printf_str [phi:main::@83->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:main::@83->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = main::s6 [phi:main::@83->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // [340] phi from main::@83 to main::@84 [phi:main::@83->main::@84]
    // main::@84
    // sprintf(info_text, "File %s error!", file)
    // [341] call printf_string
    // [932] phi from main::@84 to printf_string [phi:main::@84->printf_string]
    // [932] phi printf_string::putc#14 = &snputc [phi:main::@84->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [932] phi printf_string::str#14 = file [phi:main::@84->printf_string#1] -- pbuz1=pbuc1 
    lda #<file
    sta.z printf_string.str
    lda #>file
    sta.z printf_string.str+1
    // [932] phi printf_string::format_justify_left#14 = 0 [phi:main::@84->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [932] phi printf_string::format_min_length#14 = 0 [phi:main::@84->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [342] phi from main::@84 to main::@85 [phi:main::@84->main::@85]
    // main::@85
    // sprintf(info_text, "File %s error!", file)
    // [343] call printf_str
    // [531] phi from main::@85 to printf_str [phi:main::@85->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:main::@85->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = main::s7 [phi:main::@85->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@86
    // sprintf(info_text, "File %s error!", file)
    // [344] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [345] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom(rom_chip, STATUS_NONE, info_text)
    // [347] info_rom::rom_chip#9 = main::rom_chip1#10 -- vbuz1=vbum2 
    lda rom_chip1
    sta.z info_rom.rom_chip
    // [348] call info_rom
    // [1001] phi from main::@86 to info_rom [phi:main::@86->info_rom]
    // [1001] phi info_rom::info_text#17 = info_text [phi:main::@86->info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_rom.info_text
    lda #>@info_text
    sta.z info_rom.info_text+1
    // [1001] phi info_rom::info_status#17 = 1 [phi:main::@86->info_rom#1] -- vbuz1=vbuc1 
    lda #1
    sta.z info_rom.info_status
    // [1001] phi info_rom::rom_chip#17 = info_rom::rom_chip#9 [phi:main::@86->info_rom#2] -- register_copy 
    jsr info_rom
    jmp __b22
    // main::@20
  __b20:
    // [349] smc_file_size#205 = smc_file_size#0 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_1
    lda smc_file_size+1
    sta smc_file_size_1+1
    // info_smc(STATUS_ERROR, "SMC.BIN too large!")
    // [350] call info_smc
    // [551] phi from main::@20 to info_smc [phi:main::@20->info_smc]
    // [551] phi info_smc::info_text#10 = main::info_text13 [phi:main::@20->info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text13
    sta.z info_smc.info_text
    lda #>info_text13
    sta.z info_smc.info_text+1
    // [551] phi smc_file_size#12 = smc_file_size#205 [phi:main::@20->info_smc#1] -- register_copy 
    // [551] phi info_smc::info_status#10 = 8 [phi:main::@20->info_smc#2] -- vbum1=vbuc1 
    lda #8
    sta info_smc.info_status
    jsr info_smc
    // [141] phi from main::@2 main::@20 to main::CLI3 [phi:main::@2/main::@20->main::CLI3]
  __b9:
    // [141] phi main::smc_error#56 = 1 [phi:main::@2/main::@20->main::CLI3#0] -- vbum1=vbuc1 
    lda #1
    sta smc_error
    jmp CLI3
    // main::@2
  __b2:
    // [351] smc_file_size#206 = smc_file_size#0 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_1
    lda smc_file_size+1
    sta smc_file_size_1+1
    // info_smc(STATUS_ERROR, "No SMC.BIN or empty!")
    // [352] call info_smc
    // [551] phi from main::@2 to info_smc [phi:main::@2->info_smc]
    // [551] phi info_smc::info_text#10 = main::info_text12 [phi:main::@2->info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text12
    sta.z info_smc.info_text
    lda #>info_text12
    sta.z info_smc.info_text+1
    // [551] phi smc_file_size#12 = smc_file_size#206 [phi:main::@2->info_smc#1] -- register_copy 
    // [551] phi info_smc::info_status#10 = 8 [phi:main::@2->info_smc#2] -- vbum1=vbuc1 
    lda #8
    sta info_smc.info_status
    jsr info_smc
    jmp __b9
    // [353] phi from main::@121 to main::@19 [phi:main::@121->main::@19]
    // main::@19
  __b19:
    // wait_key("Mandatory chipsets not detected! Press [SPACE] to exit!", " ")
    // [354] call wait_key
    // [697] phi from main::@19 to wait_key [phi:main::@19->wait_key]
    // [697] phi wait_key::filter#13 = main::filter [phi:main::@19->wait_key#0] -- pbuz1=pbuc1 
    lda #<filter
    sta.z wait_key.filter
    lda #>filter
    sta.z wait_key.filter+1
    // [697] phi wait_key::info_text#3 = main::info_text11 [phi:main::@19->wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text11
    sta.z wait_key.info_text
    lda #>info_text11
    sta.z wait_key.info_text+1
    jsr wait_key
    // [355] phi from main::@19 to main::@68 [phi:main::@19->main::@68]
    // main::@68
    // system_reset()
    // [356] call system_reset
    // [908] phi from main::@68 to system_reset [phi:main::@68->system_reset]
    jsr system_reset
    jmp __b1
    // main::@11
  __b11:
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [357] if(rom_device_ids[main::rom_chip#10]!=$55) goto main::@12 -- pbuc1_derefidx_vbum1_neq_vbuc2_then_la1 
    lda #$55
    ldy rom_chip
    cmp rom_device_ids,y
    bne __b12
    // main::@16
    // if(rom_chip != 0)
    // [358] if(main::rom_chip#10!=0) goto main::@13 -- vbum1_neq_0_then_la1 
    tya
    bne __b13
    // main::@17
    // info_rom(rom_chip, STATUS_ERROR, "CX16 ROM not found!")
    // [359] info_rom::rom_chip#5 = main::rom_chip#10 -- vbuz1=vbum2 
    sta.z info_rom.rom_chip
    // [360] call info_rom
    // [1001] phi from main::@17 to info_rom [phi:main::@17->info_rom]
    // [1001] phi info_rom::info_text#17 = main::info_text6 [phi:main::@17->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text6
    sta.z info_rom.info_text
    lda #>info_text6
    sta.z info_rom.info_text+1
    // [1001] phi info_rom::info_status#17 = 8 [phi:main::@17->info_rom#1] -- vbuz1=vbuc1 
    lda #8
    sta.z info_rom.info_status
    // [1001] phi info_rom::rom_chip#17 = info_rom::rom_chip#5 [phi:main::@17->info_rom#2] -- register_copy 
    jsr info_rom
    // [361] phi from main::@17 to main::@14 [phi:main::@17->main::@14]
    // [361] phi main::rom_error#18 = 1 [phi:main::@17->main::@14#0] -- vbum1=vbuc1 
    lda #1
    sta rom_error
    // main::@14
  __b14:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [362] main::rom_chip#1 = ++ main::rom_chip#10 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [114] phi from main::@14 to main::@10 [phi:main::@14->main::@10]
    // [114] phi main::rom_error#102 = main::rom_error#18 [phi:main::@14->main::@10#0] -- register_copy 
    // [114] phi main::rom_chip#10 = main::rom_chip#1 [phi:main::@14->main::@10#1] -- register_copy 
    jmp __b10
    // main::@13
  __b13:
    // info_rom(rom_chip, STATUS_NONE, "")
    // [363] info_rom::rom_chip#4 = main::rom_chip#10 -- vbuz1=vbum2 
    lda rom_chip
    sta.z info_rom.rom_chip
    // [364] call info_rom
    // [1001] phi from main::@13 to info_rom [phi:main::@13->info_rom]
    // [1001] phi info_rom::info_text#17 = info_text5 [phi:main::@13->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z info_rom.info_text
    lda #>info_text5
    sta.z info_rom.info_text+1
    // [1001] phi info_rom::info_status#17 = 1 [phi:main::@13->info_rom#1] -- vbuz1=vbuc1 
    lda #1
    sta.z info_rom.info_status
    // [1001] phi info_rom::rom_chip#17 = info_rom::rom_chip#4 [phi:main::@13->info_rom#2] -- register_copy 
    jsr info_rom
    // [361] phi from main::@13 main::@15 main::@18 to main::@14 [phi:main::@13/main::@15/main::@18->main::@14]
    // [361] phi main::rom_error#18 = main::rom_error#102 [phi:main::@13/main::@15/main::@18->main::@14#0] -- register_copy 
    jmp __b14
    // main::@12
  __b12:
    // if(rom_chip != 0)
    // [365] if(main::rom_chip#10!=0) goto main::@15 -- vbum1_neq_0_then_la1 
    lda rom_chip
    bne __b15
    // main::@18
    // info_rom(rom_chip, STATUS_DETECTED, "OK!")
    // [366] info_rom::rom_chip#7 = main::rom_chip#10 -- vbuz1=vbum2 
    sta.z info_rom.rom_chip
    // [367] call info_rom
    // [1001] phi from main::@18 to info_rom [phi:main::@18->info_rom]
    // [1001] phi info_rom::info_text#17 = main::info_text7 [phi:main::@18->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z info_rom.info_text
    lda #>info_text7
    sta.z info_rom.info_text+1
    // [1001] phi info_rom::info_status#17 = 0 [phi:main::@18->info_rom#1] -- vbuz1=vbuc1 
    lda #0
    sta.z info_rom.info_status
    // [1001] phi info_rom::rom_chip#17 = info_rom::rom_chip#7 [phi:main::@18->info_rom#2] -- register_copy 
    jsr info_rom
    jmp __b14
    // main::@15
  __b15:
    // info_rom(rom_chip, STATUS_DETECTED, "OK!")
    // [368] info_rom::rom_chip#6 = main::rom_chip#10 -- vbuz1=vbum2 
    lda rom_chip
    sta.z info_rom.rom_chip
    // [369] call info_rom
    // [1001] phi from main::@15 to info_rom [phi:main::@15->info_rom]
    // [1001] phi info_rom::info_text#17 = main::info_text7 [phi:main::@15->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z info_rom.info_text
    lda #>info_text7
    sta.z info_rom.info_text+1
    // [1001] phi info_rom::info_status#17 = 0 [phi:main::@15->info_rom#1] -- vbuz1=vbuc1 
    lda #0
    sta.z info_rom.info_status
    // [1001] phi info_rom::rom_chip#17 = info_rom::rom_chip#6 [phi:main::@15->info_rom#2] -- register_copy 
    jsr info_rom
    jmp __b14
  .segment Data
    info_text: .text "Commander X16 Flash Utility!"
    .byte 0
    info_text1: .text "Detecting SMC, VERA and ROM chipsets ..."
    .byte 0
    s2: .text "Bootloader v"
    .byte 0
    info_text4: .text "VERA installed, OK"
    .byte 0
    info_text6: .text "CX16 ROM not found!"
    .byte 0
    info_text7: .text "OK!"
    .byte 0
    info_text9: .text "Checking files SMC.BIN, VERA.BIN, ROM(x).BIN: (.) data, ( ) empty"
    .byte 0
    info_text10: .text "Checking SMC.BIN file contents ..."
    .byte 0
    info_text11: .text "Mandatory chipsets not detected! Press [SPACE] to exit!"
    .byte 0
    filter: .text " "
    .byte 0
    info_text12: .text "No SMC.BIN or empty!"
    .byte 0
    info_text13: .text "SMC.BIN too large!"
    .byte 0
    source: .text "ROM .BIN"
    .byte 0
    s4: .text "Checking ROM file "
    .byte 0
    info_text14: .text "Continue with flashing? [Y/N]"
    .byte 0
    filter1: .text "nyNY"
    .byte 0
    main__150: .text "nN"
    .byte 0
    s6: .text "File "
    .byte 0
    s7: .text " error!"
    .byte 0
    s9: .text " size error!"
    .byte 0
    info_text16: .text "The checked chipset does not match the flash requirements, exiting ... "
    .byte 0
    info_text17: .text "Flashing SMC chip ..."
    .byte 0
    info_text18: .text "To flash the SMC chip, press both POWER/RESET buttons on the CX16 board!"
    .byte 0
    info_text19: .text "Press POWER/RESET!"
    .byte 0
    s11: .text "Reading ROM file "
    .byte 0
    info_text22: .text "No flashing required!"
    .byte 0
    s13: .text " differences found!"
    .byte 0
    s14: .text " flashing errors!"
    .byte 0
    info_text24: .text "FLASH ERRORS! Your CX16 may be bricked! Take a foto of your screen!"
    .byte 0
    info_text25: .text "Flashing success, press any key to reset your CX16 ..."
    .byte 0
    s15: .text "Resetting your CX16 ... ("
    .byte 0
    s16: .text ")"
    .byte 0
    main__76: .byte 0
    main__133: .byte 0
    main__135: .byte 0
    cx16_k_screen_set_charset1_charset: .byte 0
    cx16_k_screen_set_charset1_offset: .word 0
    rom_chip: .byte 0
    .label ch = strchr.c
    rom_chip1: .byte 0
    .label rom_bank = rom_read.rom_bank_start
    rom_bytes_read: .dword 0
    rom_file_modulo: .dword 0
    rom_chip2: .byte 0
    rom_bank1: .byte 0
    .label rom_bytes_read1 = rom_read.return
    .label rom_flash_errors = rom_flash.return
    reset_wait: .word 0
    flash_reset: .byte 0
    // The ROM chip on the CX16 should be installed!
    rom_error: .byte 0
    flash_error: .byte 0
    smc_error: .byte 0
}
.segment Code
  // screenlayer1
// Set the layer with which the conio will interact.
screenlayer1: {
    // screenlayer(1, *VERA_L1_MAPBASE, *VERA_L1_CONFIG)
    // [370] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbuz1=_deref_pbuc1 
    lda VERA_L1_MAPBASE
    sta.z screenlayer.mapbase
    // [371] screenlayer::config#0 = *VERA_L1_CONFIG -- vbuz1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta.z screenlayer.config
    // [372] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [373] return 
    rts
}
  // textcolor
// Set the front color for text output. The old front text color setting is returned.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char textcolor(__zp($db) char color)
textcolor: {
    .label textcolor__0 = $dd
    .label textcolor__1 = $db
    .label color = $db
    // __conio.color & 0xF0
    // [375] textcolor::$0 = *((char *)&__conio+$d) & $f0 -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$d
    sta.z textcolor__0
    // __conio.color & 0xF0 | color
    // [376] textcolor::$1 = textcolor::$0 | textcolor::color#16 -- vbuz1=vbuz2_bor_vbuz1 
    lda.z textcolor__1
    ora.z textcolor__0
    sta.z textcolor__1
    // __conio.color = __conio.color & 0xF0 | color
    // [377] *((char *)&__conio+$d) = textcolor::$1 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // textcolor::@return
    // }
    // [378] return 
    rts
}
  // bgcolor
// Set the back color for text output.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char bgcolor(__zp($db) char color)
bgcolor: {
    .label bgcolor__0 = $dc
    .label bgcolor__1 = $db
    .label bgcolor__2 = $dc
    .label color = $db
    // __conio.color & 0x0F
    // [380] bgcolor::$0 = *((char *)&__conio+$d) & $f -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$d
    sta.z bgcolor__0
    // color << 4
    // [381] bgcolor::$1 = bgcolor::color#14 << 4 -- vbuz1=vbuz1_rol_4 
    lda.z bgcolor__1
    asl
    asl
    asl
    asl
    sta.z bgcolor__1
    // __conio.color & 0x0F | color << 4
    // [382] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbuz1=vbuz1_bor_vbuz2 
    lda.z bgcolor__2
    ora.z bgcolor__1
    sta.z bgcolor__2
    // __conio.color = __conio.color & 0x0F | color << 4
    // [383] *((char *)&__conio+$d) = bgcolor::$2 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // bgcolor::@return
    // }
    // [384] return 
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
    // [385] *((char *)&__conio+$c) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$c
    // cursor::@return
    // }
    // [386] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    // __mem unsigned char x
    // [387] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [388] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [390] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwum1=vbum2_word_vbum3 
    lda x
    sta return+1
    lda y
    sta return
    // cbm_k_plot_get::@return
    // }
    // [391] return 
    rts
  .segment Data
    x: .byte 0
    y: .byte 0
    return: .word 0
}
.segment Code
  // gotoxy
// Set the cursor to the specified position
// void gotoxy(__zp($3e) char x, __zp($4a) char y)
gotoxy: {
    .label gotoxy__2 = $3e
    .label gotoxy__3 = $3e
    .label gotoxy__6 = $3d
    .label gotoxy__7 = $3d
    .label gotoxy__8 = $54
    .label gotoxy__9 = $4d
    .label gotoxy__10 = $4a
    .label x = $3e
    .label y = $4a
    .label gotoxy__14 = $3d
    // (x>=__conio.width)?__conio.width:x
    // [393] if(gotoxy::x#26>=*((char *)&__conio+6)) goto gotoxy::@1 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z x
    cmp __conio+6
    bcs __b1
    // [395] phi from gotoxy gotoxy::@1 to gotoxy::@2 [phi:gotoxy/gotoxy::@1->gotoxy::@2]
    // [395] phi gotoxy::$3 = gotoxy::x#26 [phi:gotoxy/gotoxy::@1->gotoxy::@2#0] -- register_copy 
    jmp __b2
    // gotoxy::@1
  __b1:
    // [394] gotoxy::$2 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z gotoxy__2
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [396] *((char *)&__conio) = gotoxy::$3 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__3
    sta __conio
    // (y>=__conio.height)?__conio.height:y
    // [397] if(gotoxy::y#26>=*((char *)&__conio+7)) goto gotoxy::@3 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z y
    cmp __conio+7
    bcs __b3
    // gotoxy::@4
    // [398] gotoxy::$14 = gotoxy::y#26 -- vbuz1=vbuz2 
    sta.z gotoxy__14
    // [399] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [399] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [400] *((char *)&__conio+1) = gotoxy::$7 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__7
    sta __conio+1
    // __conio.cursor_x << 1
    // [401] gotoxy::$8 = *((char *)&__conio) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio
    asl
    sta.z gotoxy__8
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [402] gotoxy::$10 = gotoxy::y#26 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z gotoxy__10
    // [403] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwuz1=pwuc1_derefidx_vbuz2_plus_vbuz3 
    ldy.z gotoxy__10
    clc
    adc __conio+$15,y
    sta.z gotoxy__9
    lda __conio+$15+1,y
    adc #0
    sta.z gotoxy__9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [404] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwuz1 
    lda.z gotoxy__9
    sta __conio+$13
    lda.z gotoxy__9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [405] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [406] gotoxy::$6 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
    lda __conio+7
    sta.z gotoxy__6
    jmp __b5
}
  // cputln
// Print a newline
cputln: {
    .label cputln__2 = $6f
    // __conio.cursor_x = 0
    // [407] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y++;
    // [408] *((char *)&__conio+1) = ++ *((char *)&__conio+1) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+1
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [409] cputln::$2 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z cputln__2
    // [410] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [411] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [412] return 
    rts
}
  // frame_init
frame_init: {
    .const vera_display_set_hstart1_start = $b
    .const vera_display_set_hstop1_stop = $93
    .const vera_display_set_vstart1_start = $13
    .const vera_display_set_vstop1_stop = $db
    // textcolor(WHITE)
    // [414] call textcolor
  // Set the charset to lower case.
  // screenlayer1();
    // [374] phi from frame_init to textcolor [phi:frame_init->textcolor]
    // [374] phi textcolor::color#16 = WHITE [phi:frame_init->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [415] phi from frame_init to frame_init::@2 [phi:frame_init->frame_init::@2]
    // frame_init::@2
    // bgcolor(BLUE)
    // [416] call bgcolor
    // [379] phi from frame_init::@2 to bgcolor [phi:frame_init::@2->bgcolor]
    // [379] phi bgcolor::color#14 = BLUE [phi:frame_init::@2->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [417] phi from frame_init::@2 to frame_init::@3 [phi:frame_init::@2->frame_init::@3]
    // frame_init::@3
    // scroll(0)
    // [418] call scroll
    jsr scroll
    // [419] phi from frame_init::@3 to frame_init::@4 [phi:frame_init::@3->frame_init::@4]
    // frame_init::@4
    // clrscr()
    // [420] call clrscr
    jsr clrscr
    // frame_init::vera_display_set_hstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [421] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTART = start
    // [422] *VERA_DC_HSTART = frame_init::vera_display_set_hstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstart1_start
    sta VERA_DC_HSTART
    // frame_init::vera_display_set_hstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [423] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTOP = stop
    // [424] *VERA_DC_HSTOP = frame_init::vera_display_set_hstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstop1_stop
    sta VERA_DC_HSTOP
    // frame_init::vera_display_set_vstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [425] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTART = start
    // [426] *VERA_DC_VSTART = frame_init::vera_display_set_vstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstart1_start
    sta VERA_DC_VSTART
    // frame_init::vera_display_set_vstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [427] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTOP = stop
    // [428] *VERA_DC_VSTOP = frame_init::vera_display_set_vstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstop1_stop
    sta VERA_DC_VSTOP
    // frame_init::@1
    // cx16_k_screen_set_charset(3, (char *)0)
    // [429] frame_init::cx16_k_screen_set_charset1_charset = 3 -- vbum1=vbuc1 
    lda #3
    sta cx16_k_screen_set_charset1_charset
    // [430] frame_init::cx16_k_screen_set_charset1_offset = (char *) 0 -- pbum1=pbuc1 
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
    // [432] return 
    rts
  .segment Data
    cx16_k_screen_set_charset1_charset: .byte 0
    cx16_k_screen_set_charset1_offset: .word 0
}
.segment Code
  // frame_draw
frame_draw: {
    // textcolor(WHITE)
    // [434] call textcolor
    // [374] phi from frame_draw to textcolor [phi:frame_draw->textcolor]
    // [374] phi textcolor::color#16 = WHITE [phi:frame_draw->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [435] phi from frame_draw to frame_draw::@1 [phi:frame_draw->frame_draw::@1]
    // frame_draw::@1
    // bgcolor(BLUE)
    // [436] call bgcolor
    // [379] phi from frame_draw::@1 to bgcolor [phi:frame_draw::@1->bgcolor]
    // [379] phi bgcolor::color#14 = BLUE [phi:frame_draw::@1->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [437] phi from frame_draw::@1 to frame_draw::@2 [phi:frame_draw::@1->frame_draw::@2]
    // frame_draw::@2
    // clrscr()
    // [438] call clrscr
    jsr clrscr
    // [439] phi from frame_draw::@2 to frame_draw::@3 [phi:frame_draw::@2->frame_draw::@3]
    // frame_draw::@3
    // frame(0, 0, 67, 15)
    // [440] call frame
    // [1291] phi from frame_draw::@3 to frame [phi:frame_draw::@3->frame]
    // [1291] phi frame::y#0 = 0 [phi:frame_draw::@3->frame#0] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.y
    // [1291] phi frame::y1#17 = $f [phi:frame_draw::@3->frame#1] -- vbuz1=vbuc1 
    lda #$f
    sta.z frame.y1
    // [1291] phi frame::x#0 = 0 [phi:frame_draw::@3->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1291] phi frame::x1#17 = $43 [phi:frame_draw::@3->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [441] phi from frame_draw::@3 to frame_draw::@4 [phi:frame_draw::@3->frame_draw::@4]
    // frame_draw::@4
    // frame(0, 0, 67, 2)
    // [442] call frame
    // [1291] phi from frame_draw::@4 to frame [phi:frame_draw::@4->frame]
    // [1291] phi frame::y#0 = 0 [phi:frame_draw::@4->frame#0] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.y
    // [1291] phi frame::y1#17 = 2 [phi:frame_draw::@4->frame#1] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y1
    // [1291] phi frame::x#0 = 0 [phi:frame_draw::@4->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1291] phi frame::x1#17 = $43 [phi:frame_draw::@4->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [443] phi from frame_draw::@4 to frame_draw::@5 [phi:frame_draw::@4->frame_draw::@5]
    // frame_draw::@5
    // frame(0, 2, 67, 13)
    // [444] call frame
    // [1291] phi from frame_draw::@5 to frame [phi:frame_draw::@5->frame]
    // [1291] phi frame::y#0 = 2 [phi:frame_draw::@5->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1291] phi frame::y1#17 = $d [phi:frame_draw::@5->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1291] phi frame::x#0 = 0 [phi:frame_draw::@5->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1291] phi frame::x1#17 = $43 [phi:frame_draw::@5->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [445] phi from frame_draw::@5 to frame_draw::@6 [phi:frame_draw::@5->frame_draw::@6]
    // frame_draw::@6
    // frame(0, 13, 67, 15)
    // [446] call frame
    // [1291] phi from frame_draw::@6 to frame [phi:frame_draw::@6->frame]
    // [1291] phi frame::y#0 = $d [phi:frame_draw::@6->frame#0] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y
    // [1291] phi frame::y1#17 = $f [phi:frame_draw::@6->frame#1] -- vbuz1=vbuc1 
    lda #$f
    sta.z frame.y1
    // [1291] phi frame::x#0 = 0 [phi:frame_draw::@6->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1291] phi frame::x1#17 = $43 [phi:frame_draw::@6->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [447] phi from frame_draw::@6 to frame_draw::@7 [phi:frame_draw::@6->frame_draw::@7]
    // frame_draw::@7
    // frame(0, 2, 8, 13)
    // [448] call frame
    // [1291] phi from frame_draw::@7 to frame [phi:frame_draw::@7->frame]
    // [1291] phi frame::y#0 = 2 [phi:frame_draw::@7->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1291] phi frame::y1#17 = $d [phi:frame_draw::@7->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1291] phi frame::x#0 = 0 [phi:frame_draw::@7->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1291] phi frame::x1#17 = 8 [phi:frame_draw::@7->frame#3] -- vbuz1=vbuc1 
    lda #8
    sta.z frame.x1
    jsr frame
    // [449] phi from frame_draw::@7 to frame_draw::@8 [phi:frame_draw::@7->frame_draw::@8]
    // frame_draw::@8
    // frame(8, 2, 19, 13)
    // [450] call frame
    // [1291] phi from frame_draw::@8 to frame [phi:frame_draw::@8->frame]
    // [1291] phi frame::y#0 = 2 [phi:frame_draw::@8->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1291] phi frame::y1#17 = $d [phi:frame_draw::@8->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1291] phi frame::x#0 = 8 [phi:frame_draw::@8->frame#2] -- vbuz1=vbuc1 
    lda #8
    sta.z frame.x
    // [1291] phi frame::x1#17 = $13 [phi:frame_draw::@8->frame#3] -- vbuz1=vbuc1 
    lda #$13
    sta.z frame.x1
    jsr frame
    // [451] phi from frame_draw::@8 to frame_draw::@9 [phi:frame_draw::@8->frame_draw::@9]
    // frame_draw::@9
    // frame(19, 2, 25, 13)
    // [452] call frame
    // [1291] phi from frame_draw::@9 to frame [phi:frame_draw::@9->frame]
    // [1291] phi frame::y#0 = 2 [phi:frame_draw::@9->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1291] phi frame::y1#17 = $d [phi:frame_draw::@9->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1291] phi frame::x#0 = $13 [phi:frame_draw::@9->frame#2] -- vbuz1=vbuc1 
    lda #$13
    sta.z frame.x
    // [1291] phi frame::x1#17 = $19 [phi:frame_draw::@9->frame#3] -- vbuz1=vbuc1 
    lda #$19
    sta.z frame.x1
    jsr frame
    // [453] phi from frame_draw::@9 to frame_draw::@10 [phi:frame_draw::@9->frame_draw::@10]
    // frame_draw::@10
    // frame(25, 2, 31, 13)
    // [454] call frame
    // [1291] phi from frame_draw::@10 to frame [phi:frame_draw::@10->frame]
    // [1291] phi frame::y#0 = 2 [phi:frame_draw::@10->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1291] phi frame::y1#17 = $d [phi:frame_draw::@10->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1291] phi frame::x#0 = $19 [phi:frame_draw::@10->frame#2] -- vbuz1=vbuc1 
    lda #$19
    sta.z frame.x
    // [1291] phi frame::x1#17 = $1f [phi:frame_draw::@10->frame#3] -- vbuz1=vbuc1 
    lda #$1f
    sta.z frame.x1
    jsr frame
    // [455] phi from frame_draw::@10 to frame_draw::@11 [phi:frame_draw::@10->frame_draw::@11]
    // frame_draw::@11
    // frame(31, 2, 37, 13)
    // [456] call frame
    // [1291] phi from frame_draw::@11 to frame [phi:frame_draw::@11->frame]
    // [1291] phi frame::y#0 = 2 [phi:frame_draw::@11->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1291] phi frame::y1#17 = $d [phi:frame_draw::@11->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1291] phi frame::x#0 = $1f [phi:frame_draw::@11->frame#2] -- vbuz1=vbuc1 
    lda #$1f
    sta.z frame.x
    // [1291] phi frame::x1#17 = $25 [phi:frame_draw::@11->frame#3] -- vbuz1=vbuc1 
    lda #$25
    sta.z frame.x1
    jsr frame
    // [457] phi from frame_draw::@11 to frame_draw::@12 [phi:frame_draw::@11->frame_draw::@12]
    // frame_draw::@12
    // frame(37, 2, 43, 13)
    // [458] call frame
    // [1291] phi from frame_draw::@12 to frame [phi:frame_draw::@12->frame]
    // [1291] phi frame::y#0 = 2 [phi:frame_draw::@12->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1291] phi frame::y1#17 = $d [phi:frame_draw::@12->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1291] phi frame::x#0 = $25 [phi:frame_draw::@12->frame#2] -- vbuz1=vbuc1 
    lda #$25
    sta.z frame.x
    // [1291] phi frame::x1#17 = $2b [phi:frame_draw::@12->frame#3] -- vbuz1=vbuc1 
    lda #$2b
    sta.z frame.x1
    jsr frame
    // [459] phi from frame_draw::@12 to frame_draw::@13 [phi:frame_draw::@12->frame_draw::@13]
    // frame_draw::@13
    // frame(43, 2, 49, 13)
    // [460] call frame
    // [1291] phi from frame_draw::@13 to frame [phi:frame_draw::@13->frame]
    // [1291] phi frame::y#0 = 2 [phi:frame_draw::@13->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1291] phi frame::y1#17 = $d [phi:frame_draw::@13->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1291] phi frame::x#0 = $2b [phi:frame_draw::@13->frame#2] -- vbuz1=vbuc1 
    lda #$2b
    sta.z frame.x
    // [1291] phi frame::x1#17 = $31 [phi:frame_draw::@13->frame#3] -- vbuz1=vbuc1 
    lda #$31
    sta.z frame.x1
    jsr frame
    // [461] phi from frame_draw::@13 to frame_draw::@14 [phi:frame_draw::@13->frame_draw::@14]
    // frame_draw::@14
    // frame(49, 2, 55, 13)
    // [462] call frame
    // [1291] phi from frame_draw::@14 to frame [phi:frame_draw::@14->frame]
    // [1291] phi frame::y#0 = 2 [phi:frame_draw::@14->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1291] phi frame::y1#17 = $d [phi:frame_draw::@14->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1291] phi frame::x#0 = $31 [phi:frame_draw::@14->frame#2] -- vbuz1=vbuc1 
    lda #$31
    sta.z frame.x
    // [1291] phi frame::x1#17 = $37 [phi:frame_draw::@14->frame#3] -- vbuz1=vbuc1 
    lda #$37
    sta.z frame.x1
    jsr frame
    // [463] phi from frame_draw::@14 to frame_draw::@15 [phi:frame_draw::@14->frame_draw::@15]
    // frame_draw::@15
    // frame(55, 2, 61, 13)
    // [464] call frame
    // [1291] phi from frame_draw::@15 to frame [phi:frame_draw::@15->frame]
    // [1291] phi frame::y#0 = 2 [phi:frame_draw::@15->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1291] phi frame::y1#17 = $d [phi:frame_draw::@15->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1291] phi frame::x#0 = $37 [phi:frame_draw::@15->frame#2] -- vbuz1=vbuc1 
    lda #$37
    sta.z frame.x
    // [1291] phi frame::x1#17 = $3d [phi:frame_draw::@15->frame#3] -- vbuz1=vbuc1 
    lda #$3d
    sta.z frame.x1
    jsr frame
    // [465] phi from frame_draw::@15 to frame_draw::@16 [phi:frame_draw::@15->frame_draw::@16]
    // frame_draw::@16
    // frame(61, 2, 67, 13)
    // [466] call frame
    // [1291] phi from frame_draw::@16 to frame [phi:frame_draw::@16->frame]
    // [1291] phi frame::y#0 = 2 [phi:frame_draw::@16->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1291] phi frame::y1#17 = $d [phi:frame_draw::@16->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1291] phi frame::x#0 = $3d [phi:frame_draw::@16->frame#2] -- vbuz1=vbuc1 
    lda #$3d
    sta.z frame.x
    // [1291] phi frame::x1#17 = $43 [phi:frame_draw::@16->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [467] phi from frame_draw::@16 to frame_draw::@17 [phi:frame_draw::@16->frame_draw::@17]
    // frame_draw::@17
    // frame(0, 13, 67, 29)
    // [468] call frame
    // [1291] phi from frame_draw::@17 to frame [phi:frame_draw::@17->frame]
    // [1291] phi frame::y#0 = $d [phi:frame_draw::@17->frame#0] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y
    // [1291] phi frame::y1#17 = $1d [phi:frame_draw::@17->frame#1] -- vbuz1=vbuc1 
    lda #$1d
    sta.z frame.y1
    // [1291] phi frame::x#0 = 0 [phi:frame_draw::@17->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1291] phi frame::x1#17 = $43 [phi:frame_draw::@17->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [469] phi from frame_draw::@17 to frame_draw::@18 [phi:frame_draw::@17->frame_draw::@18]
    // frame_draw::@18
    // frame(0, 29, 67, 31)
    // [470] call frame
    // [1291] phi from frame_draw::@18 to frame [phi:frame_draw::@18->frame]
    // [1291] phi frame::y#0 = $1d [phi:frame_draw::@18->frame#0] -- vbuz1=vbuc1 
    lda #$1d
    sta.z frame.y
    // [1291] phi frame::y1#17 = $1f [phi:frame_draw::@18->frame#1] -- vbuz1=vbuc1 
    lda #$1f
    sta.z frame.y1
    // [1291] phi frame::x#0 = 0 [phi:frame_draw::@18->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1291] phi frame::x1#17 = $43 [phi:frame_draw::@18->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [471] phi from frame_draw::@18 to frame_draw::@19 [phi:frame_draw::@18->frame_draw::@19]
    // frame_draw::@19
    // frame(0, 31, 67, 49)
    // [472] call frame
    // [1291] phi from frame_draw::@19 to frame [phi:frame_draw::@19->frame]
    // [1291] phi frame::y#0 = $1f [phi:frame_draw::@19->frame#0] -- vbuz1=vbuc1 
    lda #$1f
    sta.z frame.y
    // [1291] phi frame::y1#17 = $31 [phi:frame_draw::@19->frame#1] -- vbuz1=vbuc1 
    lda #$31
    sta.z frame.y1
    // [1291] phi frame::x#0 = 0 [phi:frame_draw::@19->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1291] phi frame::x1#17 = $43 [phi:frame_draw::@19->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [473] phi from frame_draw::@19 to frame_draw::@20 [phi:frame_draw::@19->frame_draw::@20]
    // frame_draw::@20
    // cputsxy(2, 14, "status")
    // [474] call cputsxy
  // cputsxy(2, 3, "led colors");
  // cputsxy(2, 5, "    no chip"); print_chip_led(2, 5, DARK_GREY, BLUE);
  // cputsxy(2, 6, "    update"); print_chip_led(2, 6, CYAN, BLUE);
  // cputsxy(2, 7, "    ok"); print_chip_led(2, 7, WHITE, BLUE);
  // cputsxy(2, 8, "    todo"); print_chip_led(2, 8, PURPLE, BLUE);
  // cputsxy(2, 9, "    error"); print_chip_led(2, 9, RED, BLUE);
  // cputsxy(2, 10, "    no file"); print_chip_led(2, 10, GREY, BLUE);
    // [1425] phi from frame_draw::@20 to cputsxy [phi:frame_draw::@20->cputsxy]
    // [1425] phi cputsxy::s#2 = frame_draw::s [phi:frame_draw::@20->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [1425] phi cputsxy::y#2 = $e [phi:frame_draw::@20->cputsxy#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z cputsxy.y
    // [1425] phi cputsxy::x#2 = 2 [phi:frame_draw::@20->cputsxy#2] -- vbuz1=vbuc1 
    lda #2
    sta.z cputsxy.x
    jsr cputsxy
    // frame_draw::@return
    // }
    // [475] return 
    rts
  .segment Data
    s: .text "status"
    .byte 0
}
.segment Code
  // info_title
// void info_title(char *info_text)
info_title: {
    // gotoxy(2, 1)
    // [477] call gotoxy
    // [392] phi from info_title to gotoxy [phi:info_title->gotoxy]
    // [392] phi gotoxy::y#26 = 1 [phi:info_title->gotoxy#0] -- vbuz1=vbuc1 
    lda #1
    sta.z gotoxy.y
    // [392] phi gotoxy::x#26 = 2 [phi:info_title->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // [478] phi from info_title to info_title::@1 [phi:info_title->info_title::@1]
    // info_title::@1
    // printf("%-60s", info_text)
    // [479] call printf_string
    // [932] phi from info_title::@1 to printf_string [phi:info_title::@1->printf_string]
    // [932] phi printf_string::putc#14 = &cputc [phi:info_title::@1->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [932] phi printf_string::str#14 = main::info_text [phi:info_title::@1->printf_string#1] -- pbuz1=pbuc1 
    lda #<main.info_text
    sta.z printf_string.str
    lda #>main.info_text
    sta.z printf_string.str+1
    // [932] phi printf_string::format_justify_left#14 = 1 [phi:info_title::@1->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [932] phi printf_string::format_min_length#14 = $3c [phi:info_title::@1->printf_string#3] -- vbuz1=vbuc1 
    lda #$3c
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_title::@return
    // }
    // [480] return 
    rts
}
  // progress_clear
/**
 * @brief Clean the progress area for the flashing.
 */
progress_clear: {
    .const h = $21+$10
    .const w = $40
    .label x = $e9
    .label i = $ea
    .label y = $f3
    // textcolor(WHITE)
    // [482] call textcolor
    // [374] phi from progress_clear to textcolor [phi:progress_clear->textcolor]
    // [374] phi textcolor::color#16 = WHITE [phi:progress_clear->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [483] phi from progress_clear to progress_clear::@5 [phi:progress_clear->progress_clear::@5]
    // progress_clear::@5
    // bgcolor(BLUE)
    // [484] call bgcolor
    // [379] phi from progress_clear::@5 to bgcolor [phi:progress_clear::@5->bgcolor]
    // [379] phi bgcolor::color#14 = BLUE [phi:progress_clear::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [485] phi from progress_clear::@5 to progress_clear::@1 [phi:progress_clear::@5->progress_clear::@1]
    // [485] phi progress_clear::y#2 = $21 [phi:progress_clear::@5->progress_clear::@1#0] -- vbuz1=vbuc1 
    lda #$21
    sta.z y
    // progress_clear::@1
  __b1:
    // while (y < h)
    // [486] if(progress_clear::y#2<progress_clear::h) goto progress_clear::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y
    cmp #h
    bcc __b4
    // progress_clear::@return
    // }
    // [487] return 
    rts
    // [488] phi from progress_clear::@1 to progress_clear::@2 [phi:progress_clear::@1->progress_clear::@2]
  __b4:
    // [488] phi progress_clear::x#2 = 2 [phi:progress_clear::@1->progress_clear::@2#0] -- vbuz1=vbuc1 
    lda #2
    sta.z x
    // [488] phi progress_clear::i#2 = 0 [phi:progress_clear::@1->progress_clear::@2#1] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // progress_clear::@2
  __b2:
    // for(unsigned char i = 0; i < w; i++)
    // [489] if(progress_clear::i#2<progress_clear::w) goto progress_clear::@3 -- vbuz1_lt_vbuc1_then_la1 
    lda.z i
    cmp #w
    bcc __b3
    // progress_clear::@4
    // y++;
    // [490] progress_clear::y#1 = ++ progress_clear::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [485] phi from progress_clear::@4 to progress_clear::@1 [phi:progress_clear::@4->progress_clear::@1]
    // [485] phi progress_clear::y#2 = progress_clear::y#1 [phi:progress_clear::@4->progress_clear::@1#0] -- register_copy 
    jmp __b1
    // progress_clear::@3
  __b3:
    // cputcxy(x, y, ' ')
    // [491] cputcxy::x#9 = progress_clear::x#2 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [492] cputcxy::y#9 = progress_clear::y#2 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [493] call cputcxy
    // [1432] phi from progress_clear::@3 to cputcxy [phi:progress_clear::@3->cputcxy]
    // [1432] phi cputcxy::c#13 = ' ' [phi:progress_clear::@3->cputcxy#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z cputcxy.c
    // [1432] phi cputcxy::y#13 = cputcxy::y#9 [phi:progress_clear::@3->cputcxy#1] -- register_copy 
    // [1432] phi cputcxy::x#13 = cputcxy::x#9 [phi:progress_clear::@3->cputcxy#2] -- register_copy 
    jsr cputcxy
    // progress_clear::@6
    // x++;
    // [494] progress_clear::x#1 = ++ progress_clear::x#2 -- vbuz1=_inc_vbuz1 
    inc.z x
    // for(unsigned char i = 0; i < w; i++)
    // [495] progress_clear::i#1 = ++ progress_clear::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [488] phi from progress_clear::@6 to progress_clear::@2 [phi:progress_clear::@6->progress_clear::@2]
    // [488] phi progress_clear::x#2 = progress_clear::x#1 [phi:progress_clear::@6->progress_clear::@2#0] -- register_copy 
    // [488] phi progress_clear::i#2 = progress_clear::i#1 [phi:progress_clear::@6->progress_clear::@2#1] -- register_copy 
    jmp __b2
}
  // info_clear_all
/**
 * @brief Clean the information area.
 * 
 */
info_clear_all: {
    // textcolor(WHITE)
    // [497] call textcolor
    // [374] phi from info_clear_all to textcolor [phi:info_clear_all->textcolor]
    // [374] phi textcolor::color#16 = WHITE [phi:info_clear_all->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [498] phi from info_clear_all to info_clear_all::@3 [phi:info_clear_all->info_clear_all::@3]
    // info_clear_all::@3
    // bgcolor(BLUE)
    // [499] call bgcolor
    // [379] phi from info_clear_all::@3 to bgcolor [phi:info_clear_all::@3->bgcolor]
    // [379] phi bgcolor::color#14 = BLUE [phi:info_clear_all::@3->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [500] phi from info_clear_all::@3 to info_clear_all::@1 [phi:info_clear_all::@3->info_clear_all::@1]
    // [500] phi info_clear_all::l#2 = 0 [phi:info_clear_all::@3->info_clear_all::@1#0] -- vbum1=vbuc1 
    lda #0
    sta l
    // info_clear_all::@1
  __b1:
    // while (l < INFO_H)
    // [501] if(info_clear_all::l#2<$a) goto info_clear_all::@2 -- vbum1_lt_vbuc1_then_la1 
    lda l
    cmp #$a
    bcc __b2
    // info_clear_all::@return
    // }
    // [502] return 
    rts
    // info_clear_all::@2
  __b2:
    // info_clear(l)
    // [503] info_clear::l#0 = info_clear_all::l#2 -- vbuz1=vbum2 
    lda l
    sta.z info_clear.l
    // [504] call info_clear
    // [1440] phi from info_clear_all::@2 to info_clear [phi:info_clear_all::@2->info_clear]
    // [1440] phi info_clear::l#4 = info_clear::l#0 [phi:info_clear_all::@2->info_clear#0] -- register_copy 
    jsr info_clear
    // info_clear_all::@4
    // l++;
    // [505] info_clear_all::l#1 = ++ info_clear_all::l#2 -- vbum1=_inc_vbum1 
    inc l
    // [500] phi from info_clear_all::@4 to info_clear_all::@1 [phi:info_clear_all::@4->info_clear_all::@1]
    // [500] phi info_clear_all::l#2 = info_clear_all::l#1 [phi:info_clear_all::@4->info_clear_all::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    .label l = strchr.c
}
.segment Code
  // info_progress
// void info_progress(__zp($c0) char *info_text)
info_progress: {
    .label info_text = $c0
    // unsigned char x = wherex()
    // [507] call wherex
    jsr wherex
    // [508] wherex::return#2 = wherex::return#0
    // info_progress::@1
    // [509] info_progress::x#0 = wherex::return#2
    // unsigned char y = wherey()
    // [510] call wherey
    jsr wherey
    // [511] wherey::return#2 = wherey::return#0
    // info_progress::@2
    // [512] info_progress::y#0 = wherey::return#2
    // gotoxy(2, PROGRESS_Y-3)
    // [513] call gotoxy
    // [392] phi from info_progress::@2 to gotoxy [phi:info_progress::@2->gotoxy]
    // [392] phi gotoxy::y#26 = $21-3 [phi:info_progress::@2->gotoxy#0] -- vbuz1=vbuc1 
    lda #$21-3
    sta.z gotoxy.y
    // [392] phi gotoxy::x#26 = 2 [phi:info_progress::@2->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // info_progress::@3
    // printf("%-60s", info_text)
    // [514] printf_string::str#0 = info_progress::info_text#4
    // [515] call printf_string
    // [932] phi from info_progress::@3 to printf_string [phi:info_progress::@3->printf_string]
    // [932] phi printf_string::putc#14 = &cputc [phi:info_progress::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [932] phi printf_string::str#14 = printf_string::str#0 [phi:info_progress::@3->printf_string#1] -- register_copy 
    // [932] phi printf_string::format_justify_left#14 = 1 [phi:info_progress::@3->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [932] phi printf_string::format_min_length#14 = $3c [phi:info_progress::@3->printf_string#3] -- vbuz1=vbuc1 
    lda #$3c
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_progress::@4
    // gotoxy(x, y)
    // [516] gotoxy::x#10 = info_progress::x#0 -- vbuz1=vbum2 
    lda x
    sta.z gotoxy.x
    // [517] gotoxy::y#10 = info_progress::y#0 -- vbuz1=vbum2 
    lda y
    sta.z gotoxy.y
    // [518] call gotoxy
    // [392] phi from info_progress::@4 to gotoxy [phi:info_progress::@4->gotoxy]
    // [392] phi gotoxy::y#26 = gotoxy::y#10 [phi:info_progress::@4->gotoxy#0] -- register_copy 
    // [392] phi gotoxy::x#26 = gotoxy::x#10 [phi:info_progress::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // info_progress::@return
    // }
    // [519] return 
    rts
  .segment Data
    .label x = rom_detect.rom_detect__38
    .label y = rom_detect.rom_detect__25
}
.segment Code
  // smc_detect
smc_detect: {
    // This conditional compilation ensures that only the detection interpretation happens if it is switched on.
    .label return = 1
    // smc_detect::@return
    // [521] return 
    rts
}
  // chip_smc
chip_smc: {
    // print_smc_led(GREY)
    // [523] call print_smc_led
    // [1456] phi from chip_smc to print_smc_led [phi:chip_smc->print_smc_led]
    // [1456] phi print_smc_led::c#2 = GREY [phi:chip_smc->print_smc_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z print_smc_led.c
    jsr print_smc_led
    // [524] phi from chip_smc to chip_smc::@1 [phi:chip_smc->chip_smc::@1]
    // chip_smc::@1
    // print_chip(CHIP_SMC_X, CHIP_SMC_Y+1, CHIP_SMC_W, "smc     ")
    // [525] call print_chip
    // [1460] phi from chip_smc::@1 to print_chip [phi:chip_smc::@1->print_chip]
    // [1460] phi print_chip::text#11 = chip_smc::text [phi:chip_smc::@1->print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z print_chip.text_2
    lda #>text
    sta.z print_chip.text_2+1
    // [1460] phi print_chip::w#10 = 5 [phi:chip_smc::@1->print_chip#1] -- vbum1=vbuc1 
    lda #5
    sta print_chip.w
    // [1460] phi print_chip::x#10 = 1 [phi:chip_smc::@1->print_chip#2] -- vbuz1=vbuc1 
    lda #1
    sta.z print_chip.x
    jsr print_chip
    // chip_smc::@return
    // }
    // [526] return 
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
    // [527] __snprintf_capacity = $ffff -- vwum1=vwuc1 
    lda #<$ffff
    sta __snprintf_capacity
    lda #>$ffff
    sta __snprintf_capacity+1
    // __snprintf_size = 0
    // [528] __snprintf_size = 0 -- vwum1=vbuc1 
    lda #<0
    sta __snprintf_size
    sta __snprintf_size+1
    // __snprintf_buffer = s
    // [529] __snprintf_buffer = info_text -- pbum1=pbuc1 
    lda #<info_text
    sta __snprintf_buffer
    lda #>info_text
    sta __snprintf_buffer+1
    // snprintf_init::@return
    // }
    // [530] return 
    rts
}
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($60) void (*putc)(char), __zp($c0) const char *s)
printf_str: {
    .label c = $cd
    .label s = $c0
    .label putc = $60
    // [532] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [532] phi printf_str::s#52 = printf_str::s#53 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [533] printf_str::c#1 = *printf_str::s#52 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta.z c
    // [534] printf_str::s#0 = ++ printf_str::s#52 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [535] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // printf_str::@return
    // }
    // [536] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [537] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [538] callexecute *printf_str::putc#53  -- call__deref_pprz1 
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
// void printf_uint(__zp($60) void (*putc)(char), __zp($48) unsigned int uvalue, __zp($ea) char format_min_length, char format_justify_left, char format_sign_always, __zp($e9) char format_zero_padding, char format_upper_case, __zp($f3) char format_radix)
printf_uint: {
    .label uvalue = $48
    .label format_radix = $f3
    .label putc = $60
    .label format_min_length = $ea
    .label format_zero_padding = $e9
    // printf_uint::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [541] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [542] utoa::value#1 = printf_uint::uvalue#12
    // [543] utoa::radix#0 = printf_uint::format_radix#12
    // [544] call utoa
    // Format number into buffer
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [545] printf_number_buffer::putc#1 = printf_uint::putc#12
    // [546] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [547] printf_number_buffer::format_min_length#1 = printf_uint::format_min_length#12
    // [548] printf_number_buffer::format_zero_padding#1 = printf_uint::format_zero_padding#12
    // [549] call printf_number_buffer
  // Print using format
    // [1534] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    // [1534] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#1 [phi:printf_uint::@2->printf_number_buffer#0] -- register_copy 
    // [1534] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_uint::@2->printf_number_buffer#1] -- register_copy 
    // [1534] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#1 [phi:printf_uint::@2->printf_number_buffer#2] -- register_copy 
    // [1534] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#1 [phi:printf_uint::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [550] return 
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
// void info_smc(__mem() char info_status, __zp($2e) char *info_text)
info_smc: {
    .label info_text = $2e
    // print_smc_led(status_color[info_status])
    // [552] print_smc_led::c#1 = status_color[info_smc::info_status#10] -- vbuz1=pbuc1_derefidx_vbum2 
    ldy info_status
    lda status_color,y
    sta.z print_smc_led.c
    // [553] call print_smc_led
    // [1456] phi from info_smc to print_smc_led [phi:info_smc->print_smc_led]
    // [1456] phi print_smc_led::c#2 = print_smc_led::c#1 [phi:info_smc->print_smc_led#0] -- register_copy 
    jsr print_smc_led
    // [554] phi from info_smc to info_smc::@1 [phi:info_smc->info_smc::@1]
    // info_smc::@1
    // info_clear(0)
    // [555] call info_clear
    // [1440] phi from info_smc::@1 to info_clear [phi:info_smc::@1->info_clear]
    // [1440] phi info_clear::l#4 = 0 [phi:info_smc::@1->info_clear#0] -- vbuz1=vbuc1 
    lda #0
    sta.z info_clear.l
    jsr info_clear
    // [556] phi from info_smc::@1 to info_smc::@2 [phi:info_smc::@1->info_smc::@2]
    // info_smc::@2
    // printf("SMC  - %-8s - ATTiny - %05x / 01E00 - %s", status_text[info_status], smc_file_size, info_text)
    // [557] call printf_str
    // [531] phi from info_smc::@2 to printf_str [phi:info_smc::@2->printf_str]
    // [531] phi printf_str::putc#53 = &cputc [phi:info_smc::@2->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = info_smc::s [phi:info_smc::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // info_smc::@3
    // printf("SMC  - %-8s - ATTiny - %05x / 01E00 - %s", status_text[info_status], smc_file_size, info_text)
    // [558] info_smc::$3 = info_smc::info_status#10 << 1 -- vbum1=vbum1_rol_1 
    asl info_smc__3
    // [559] printf_string::str#3 = status_text[info_smc::$3] -- pbuz1=qbuc1_derefidx_vbum2 
    ldy info_smc__3
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [560] call printf_string
    // [932] phi from info_smc::@3 to printf_string [phi:info_smc::@3->printf_string]
    // [932] phi printf_string::putc#14 = &cputc [phi:info_smc::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [932] phi printf_string::str#14 = printf_string::str#3 [phi:info_smc::@3->printf_string#1] -- register_copy 
    // [932] phi printf_string::format_justify_left#14 = 1 [phi:info_smc::@3->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [932] phi printf_string::format_min_length#14 = 8 [phi:info_smc::@3->printf_string#3] -- vbuz1=vbuc1 
    lda #8
    sta.z printf_string.format_min_length
    jsr printf_string
    // [561] phi from info_smc::@3 to info_smc::@4 [phi:info_smc::@3->info_smc::@4]
    // info_smc::@4
    // printf("SMC  - %-8s - ATTiny - %05x / 01E00 - %s", status_text[info_status], smc_file_size, info_text)
    // [562] call printf_str
    // [531] phi from info_smc::@4 to printf_str [phi:info_smc::@4->printf_str]
    // [531] phi printf_str::putc#53 = &cputc [phi:info_smc::@4->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = info_smc::s1 [phi:info_smc::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_smc::@5
    // printf("SMC  - %-8s - ATTiny - %05x / 01E00 - %s", status_text[info_status], smc_file_size, info_text)
    // [563] printf_uint::uvalue#0 = smc_file_size#12 -- vwuz1=vwum2 
    lda smc_file_size_1
    sta.z printf_uint.uvalue
    lda smc_file_size_1+1
    sta.z printf_uint.uvalue+1
    // [564] call printf_uint
    // [540] phi from info_smc::@5 to printf_uint [phi:info_smc::@5->printf_uint]
    // [540] phi printf_uint::format_zero_padding#12 = 1 [phi:info_smc::@5->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [540] phi printf_uint::format_min_length#12 = 5 [phi:info_smc::@5->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [540] phi printf_uint::putc#12 = &cputc [phi:info_smc::@5->printf_uint#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uint.putc
    lda #>cputc
    sta.z printf_uint.putc+1
    // [540] phi printf_uint::format_radix#12 = HEXADECIMAL [phi:info_smc::@5->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [540] phi printf_uint::uvalue#12 = printf_uint::uvalue#0 [phi:info_smc::@5->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [565] phi from info_smc::@5 to info_smc::@6 [phi:info_smc::@5->info_smc::@6]
    // info_smc::@6
    // printf("SMC  - %-8s - ATTiny - %05x / 01E00 - %s", status_text[info_status], smc_file_size, info_text)
    // [566] call printf_str
    // [531] phi from info_smc::@6 to printf_str [phi:info_smc::@6->printf_str]
    // [531] phi printf_str::putc#53 = &cputc [phi:info_smc::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = info_smc::s2 [phi:info_smc::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // info_smc::@7
    // printf("SMC  - %-8s - ATTiny - %05x / 01E00 - %s", status_text[info_status], smc_file_size, info_text)
    // [567] printf_string::str#4 = info_smc::info_text#10 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [568] call printf_string
    // [932] phi from info_smc::@7 to printf_string [phi:info_smc::@7->printf_string]
    // [932] phi printf_string::putc#14 = &cputc [phi:info_smc::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [932] phi printf_string::str#14 = printf_string::str#4 [phi:info_smc::@7->printf_string#1] -- register_copy 
    // [932] phi printf_string::format_justify_left#14 = 0 [phi:info_smc::@7->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [932] phi printf_string::format_min_length#14 = 0 [phi:info_smc::@7->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_smc::@return
    // }
    // [569] return 
    rts
  .segment Data
    s: .text "SMC  - "
    .byte 0
    s1: .text " - ATTiny - "
    .byte 0
    s2: .text " / 01E00 - "
    .byte 0
    .label info_smc__3 = wait_key.bank_get_brom1_return
    .label info_status = wait_key.bank_get_brom1_return
}
.segment Code
  // chip_vera
chip_vera: {
    // print_vera_led(GREY)
    // [571] call print_vera_led
    // [1565] phi from chip_vera to print_vera_led [phi:chip_vera->print_vera_led]
    // [1565] phi print_vera_led::c#2 = GREY [phi:chip_vera->print_vera_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z print_vera_led.c
    jsr print_vera_led
    // [572] phi from chip_vera to chip_vera::@1 [phi:chip_vera->chip_vera::@1]
    // chip_vera::@1
    // print_chip(CHIP_VERA_X, CHIP_VERA_Y+1, CHIP_VERA_W, "vera     ")
    // [573] call print_chip
    // [1460] phi from chip_vera::@1 to print_chip [phi:chip_vera::@1->print_chip]
    // [1460] phi print_chip::text#11 = chip_vera::text [phi:chip_vera::@1->print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z print_chip.text_2
    lda #>text
    sta.z print_chip.text_2+1
    // [1460] phi print_chip::w#10 = 8 [phi:chip_vera::@1->print_chip#1] -- vbum1=vbuc1 
    lda #8
    sta print_chip.w
    // [1460] phi print_chip::x#10 = 9 [phi:chip_vera::@1->print_chip#2] -- vbuz1=vbuc1 
    lda #9
    sta.z print_chip.x
    jsr print_chip
    // chip_vera::@return
    // }
    // [574] return 
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
// void info_vera(char info_status, char *info_text)
info_vera: {
    // print_vera_led(status_color[info_status])
    // [575] print_vera_led::c#1 = *status_color -- vbuz1=_deref_pbuc1 
    lda status_color
    sta.z print_vera_led.c
    // [576] call print_vera_led
    // [1565] phi from info_vera to print_vera_led [phi:info_vera->print_vera_led]
    // [1565] phi print_vera_led::c#2 = print_vera_led::c#1 [phi:info_vera->print_vera_led#0] -- register_copy 
    jsr print_vera_led
    // [577] phi from info_vera to info_vera::@1 [phi:info_vera->info_vera::@1]
    // info_vera::@1
    // info_clear(1)
    // [578] call info_clear
    // [1440] phi from info_vera::@1 to info_clear [phi:info_vera::@1->info_clear]
    // [1440] phi info_clear::l#4 = 1 [phi:info_vera::@1->info_clear#0] -- vbuz1=vbuc1 
    lda #1
    sta.z info_clear.l
    jsr info_clear
    // [579] phi from info_vera::@1 to info_vera::@2 [phi:info_vera::@1->info_vera::@2]
    // info_vera::@2
    // printf("VERA - %-8s - FPGA   - 1a000 / 1a000 - %s", status_text[info_status], info_text)
    // [580] call printf_str
    // [531] phi from info_vera::@2 to printf_str [phi:info_vera::@2->printf_str]
    // [531] phi printf_str::putc#53 = &cputc [phi:info_vera::@2->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = info_vera::s [phi:info_vera::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // info_vera::@3
    // printf("VERA - %-8s - FPGA   - 1a000 / 1a000 - %s", status_text[info_status], info_text)
    // [581] printf_string::str#5 = *status_text -- pbuz1=_deref_qbuc1 
    lda status_text
    sta.z printf_string.str
    lda status_text+1
    sta.z printf_string.str+1
    // [582] call printf_string
    // [932] phi from info_vera::@3 to printf_string [phi:info_vera::@3->printf_string]
    // [932] phi printf_string::putc#14 = &cputc [phi:info_vera::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [932] phi printf_string::str#14 = printf_string::str#5 [phi:info_vera::@3->printf_string#1] -- register_copy 
    // [932] phi printf_string::format_justify_left#14 = 1 [phi:info_vera::@3->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [932] phi printf_string::format_min_length#14 = 8 [phi:info_vera::@3->printf_string#3] -- vbuz1=vbuc1 
    lda #8
    sta.z printf_string.format_min_length
    jsr printf_string
    // [583] phi from info_vera::@3 to info_vera::@4 [phi:info_vera::@3->info_vera::@4]
    // info_vera::@4
    // printf("VERA - %-8s - FPGA   - 1a000 / 1a000 - %s", status_text[info_status], info_text)
    // [584] call printf_str
    // [531] phi from info_vera::@4 to printf_str [phi:info_vera::@4->printf_str]
    // [531] phi printf_str::putc#53 = &cputc [phi:info_vera::@4->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = info_vera::s1 [phi:info_vera::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // [585] phi from info_vera::@4 to info_vera::@5 [phi:info_vera::@4->info_vera::@5]
    // info_vera::@5
    // printf("VERA - %-8s - FPGA   - 1a000 / 1a000 - %s", status_text[info_status], info_text)
    // [586] call printf_string
    // [932] phi from info_vera::@5 to printf_string [phi:info_vera::@5->printf_string]
    // [932] phi printf_string::putc#14 = &cputc [phi:info_vera::@5->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [932] phi printf_string::str#14 = main::info_text4 [phi:info_vera::@5->printf_string#1] -- pbuz1=pbuc1 
    lda #<main.info_text4
    sta.z printf_string.str
    lda #>main.info_text4
    sta.z printf_string.str+1
    // [932] phi printf_string::format_justify_left#14 = 0 [phi:info_vera::@5->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [932] phi printf_string::format_min_length#14 = 0 [phi:info_vera::@5->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_vera::@return
    // }
    // [587] return 
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
    .label rom_detect__19 = $e9
    .label rom_detect__23 = $ea
    .label rom_detect__26 = $cd
    .label rom_chip = $ce
    .label rom_detect_address = $62
    // [589] phi from rom_detect to rom_detect::@1 [phi:rom_detect->rom_detect::@1]
    // [589] phi rom_detect::rom_chip#10 = 0 [phi:rom_detect->rom_detect::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip
    // [589] phi rom_detect::rom_detect_address#10 = 0 [phi:rom_detect->rom_detect::@1#1] -- vduz1=vduc1 
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
    // [590] if(rom_detect::rom_detect_address#10<8*$80000) goto rom_detect::@2 -- vduz1_lt_vduc1_then_la1 
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
    // [591] return 
    rts
    // rom_detect::@2
  __b2:
    // rom_manufacturer_ids[rom_chip] = 0
    // [592] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    ldy.z rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = 0
    // [593] rom_device_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta rom_device_ids,y
    // if (rom_detect_address == 0x0)
    // [594] if(rom_detect::rom_detect_address#10!=0) goto rom_detect::@3 -- vduz1_neq_0_then_la1 
    lda.z rom_detect_address
    ora.z rom_detect_address+1
    ora.z rom_detect_address+2
    ora.z rom_detect_address+3
    bne __b3
    // rom_detect::@14
    // rom_manufacturer_ids[rom_chip] = 0x9f
    // [595] rom_manufacturer_ids[rom_detect::rom_chip#10] = $9f -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$9f
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF040
    // [596] rom_device_ids[rom_detect::rom_chip#10] = $b7 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$b7
    sta rom_device_ids,y
    // rom_detect::@3
  __b3:
    // if (rom_detect_address == 0x80000)
    // [597] if(rom_detect::rom_detect_address#10!=$80000) goto rom_detect::@4 -- vduz1_neq_vduc1_then_la1 
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
    // [598] rom_manufacturer_ids[rom_detect::rom_chip#10] = $9f -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$9f
    ldy.z rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF040
    // [599] rom_device_ids[rom_detect::rom_chip#10] = $b7 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$b7
    sta rom_device_ids,y
    // rom_detect::@4
  __b4:
    // if (rom_detect_address == 0x100000)
    // [600] if(rom_detect::rom_detect_address#10!=$100000) goto rom_detect::@5 -- vduz1_neq_vduc1_then_la1 
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
    // [601] rom_manufacturer_ids[rom_detect::rom_chip#10] = $9f -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$9f
    ldy.z rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF020A
    // [602] rom_device_ids[rom_detect::rom_chip#10] = $b6 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$b6
    sta rom_device_ids,y
    // rom_detect::@5
  __b5:
    // if (rom_detect_address == 0x180000)
    // [603] if(rom_detect::rom_detect_address#10!=$180000) goto rom_detect::@6 -- vduz1_neq_vduc1_then_la1 
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
    // [604] rom_manufacturer_ids[rom_detect::rom_chip#10] = $9f -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$9f
    ldy.z rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF010A
    // [605] rom_device_ids[rom_detect::rom_chip#10] = $b5 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$b5
    sta rom_device_ids,y
    // rom_detect::@6
  __b6:
    // if (rom_detect_address == 0x200000)
    // [606] if(rom_detect::rom_detect_address#10!=$200000) goto rom_detect::@7 -- vduz1_neq_vduc1_then_la1 
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
    // [607] rom_manufacturer_ids[rom_detect::rom_chip#10] = $9f -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$9f
    ldy.z rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF040
    // [608] rom_device_ids[rom_detect::rom_chip#10] = $b7 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$b7
    sta rom_device_ids,y
    // rom_detect::@7
  __b7:
    // if (rom_detect_address == 0x280000)
    // [609] if(rom_detect::rom_detect_address#10!=$280000) goto rom_detect::bank_set_brom1 -- vduz1_neq_vduc1_then_la1 
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
    // [610] rom_manufacturer_ids[rom_detect::rom_chip#10] = $9f -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$9f
    ldy.z rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF040
    // [611] rom_device_ids[rom_detect::rom_chip#10] = $b7 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$b7
    sta rom_device_ids,y
    // rom_detect::bank_set_brom1
  bank_set_brom1:
    // BROM = bank
    // [612] BROM = rom_detect::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // rom_detect::@22
    // case SST39SF010A:
    //             rom_device_names[rom_chip] = "f010a";
    //             rom_size_strings[rom_chip] = "128";
    //             rom_sizes[rom_chip] = 128 * 1024;
    //             break;
    // [613] if(rom_device_ids[rom_detect::rom_chip#10]==$b5) goto rom_detect::@8 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
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
    // [614] if(rom_device_ids[rom_detect::rom_chip#10]==$b6) goto rom_detect::@9 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
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
    // [615] if(rom_device_ids[rom_detect::rom_chip#10]==$b7) goto rom_detect::@10 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b7
    bne !__b10+
    jmp __b10
  !__b10:
    // rom_detect::@11
    // rom_manufacturer_ids[rom_chip] = 0
    // [616] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    sta rom_manufacturer_ids,y
    // rom_device_names[rom_chip] = "----"
    // [617] rom_detect::$28 = rom_detect::rom_chip#10 << 1 -- vbum1=vbuz2_rol_1 
    tya
    asl
    sta rom_detect__28
    // [618] rom_device_names[rom_detect::$28] = rom_detect::$36 -- qbuc1_derefidx_vbum1=pbuc2 
    tay
    lda #<rom_detect__36
    sta rom_device_names,y
    lda #>rom_detect__36
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "000"
    // [619] rom_size_strings[rom_detect::$28] = rom_detect::$37 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__37
    sta rom_size_strings,y
    lda #>rom_detect__37
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 0
    // [620] rom_detect::$29 = rom_detect::rom_chip#10 << 2 -- vbum1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta rom_detect__29
    // [621] rom_sizes[rom_detect::$29] = 0 -- pduc1_derefidx_vbum1=vbuc2 
    tay
    lda #0
    sta rom_sizes,y
    sta rom_sizes+1,y
    sta rom_sizes+2,y
    sta rom_sizes+3,y
    // rom_device_ids[rom_chip] = UNKNOWN
    // [622] rom_device_ids[rom_detect::rom_chip#10] = $55 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$55
    ldy.z rom_chip
    sta rom_device_ids,y
    // rom_detect::@12
  __b12:
    // rom_chip*3
    // [623] rom_detect::$38 = rom_detect::rom_chip#10 << 1 -- vbum1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta rom_detect__38
    // [624] rom_detect::$14 = rom_detect::$38 + rom_detect::rom_chip#10 -- vbum1=vbum1_plus_vbuz2 
    lda rom_detect__14
    clc
    adc.z rom_chip
    sta rom_detect__14
    // gotoxy(rom_chip*3+40, 1)
    // [625] gotoxy::x#19 = rom_detect::$14 + $28 -- vbuz1=vbum2_plus_vbuc1 
    lda #$28
    clc
    adc rom_detect__14
    sta.z gotoxy.x
    // [626] call gotoxy
    // [392] phi from rom_detect::@12 to gotoxy [phi:rom_detect::@12->gotoxy]
    // [392] phi gotoxy::y#26 = 1 [phi:rom_detect::@12->gotoxy#0] -- vbuz1=vbuc1 
    lda #1
    sta.z gotoxy.y
    // [392] phi gotoxy::x#26 = gotoxy::x#19 [phi:rom_detect::@12->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_detect::@23
    // printf("%02x", rom_device_ids[rom_chip])
    // [627] printf_uchar::uvalue#4 = rom_device_ids[rom_detect::rom_chip#10] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z rom_chip
    lda rom_device_ids,y
    sta.z printf_uchar.uvalue
    // [628] call printf_uchar
    // [913] phi from rom_detect::@23 to printf_uchar [phi:rom_detect::@23->printf_uchar]
    // [913] phi printf_uchar::format_zero_padding#10 = 1 [phi:rom_detect::@23->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [913] phi printf_uchar::format_min_length#10 = 2 [phi:rom_detect::@23->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [913] phi printf_uchar::putc#10 = &cputc [phi:rom_detect::@23->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [913] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:rom_detect::@23->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [913] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#4 [phi:rom_detect::@23->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // rom_detect::@24
    // rom_chip++;
    // [629] rom_detect::rom_chip#1 = ++ rom_detect::rom_chip#10 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip
    // rom_detect::@13
    // rom_detect_address += 0x80000
    // [630] rom_detect::rom_detect_address#1 = rom_detect::rom_detect_address#10 + $80000 -- vduz1=vduz1_plus_vduc1 
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
    // [589] phi from rom_detect::@13 to rom_detect::@1 [phi:rom_detect::@13->rom_detect::@1]
    // [589] phi rom_detect::rom_chip#10 = rom_detect::rom_chip#1 [phi:rom_detect::@13->rom_detect::@1#0] -- register_copy 
    // [589] phi rom_detect::rom_detect_address#10 = rom_detect::rom_detect_address#1 [phi:rom_detect::@13->rom_detect::@1#1] -- register_copy 
    jmp __b1
    // rom_detect::@10
  __b10:
    // rom_device_names[rom_chip] = "f040"
    // [631] rom_detect::$25 = rom_detect::rom_chip#10 << 1 -- vbum1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta rom_detect__25
    // [632] rom_device_names[rom_detect::$25] = rom_detect::$34 -- qbuc1_derefidx_vbum1=pbuc2 
    tay
    lda #<rom_detect__34
    sta rom_device_names,y
    lda #>rom_detect__34
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "512"
    // [633] rom_size_strings[rom_detect::$25] = rom_detect::$35 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__35
    sta rom_size_strings,y
    lda #>rom_detect__35
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 512 * 1024
    // [634] rom_detect::$26 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta.z rom_detect__26
    // [635] rom_sizes[rom_detect::$26] = (unsigned long)$200*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
    // [636] rom_detect::$22 = rom_detect::rom_chip#10 << 1 -- vbum1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta rom_detect__22
    // [637] rom_device_names[rom_detect::$22] = rom_detect::$32 -- qbuc1_derefidx_vbum1=pbuc2 
    tay
    lda #<rom_detect__32
    sta rom_device_names,y
    lda #>rom_detect__32
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "256"
    // [638] rom_size_strings[rom_detect::$22] = rom_detect::$33 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__33
    sta rom_size_strings,y
    lda #>rom_detect__33
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 256 * 1024
    // [639] rom_detect::$23 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta.z rom_detect__23
    // [640] rom_sizes[rom_detect::$23] = (unsigned long)$100*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
    // [641] rom_detect::$19 = rom_detect::rom_chip#10 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta.z rom_detect__19
    // [642] rom_device_names[rom_detect::$19] = rom_detect::$30 -- qbuc1_derefidx_vbuz1=pbuc2 
    tay
    lda #<rom_detect__30
    sta rom_device_names,y
    lda #>rom_detect__30
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "128"
    // [643] rom_size_strings[rom_detect::$19] = rom_detect::$31 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__31
    sta rom_size_strings,y
    lda #>rom_detect__31
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 128 * 1024
    // [644] rom_detect::$20 = rom_detect::rom_chip#10 << 2 -- vbum1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta rom_detect__20
    // [645] rom_sizes[rom_detect::$20] = (unsigned long)$80*$400 -- pduc1_derefidx_vbum1=vduc2 
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
    .label rom_detect__14 = rom_detect__38
    .label rom_detect__20 = wait_key.bank_get_brom1_return
    .label rom_detect__22 = chip_rom.chip_rom__9
    rom_detect__25: .byte 0
    rom_detect__28: .byte 0
    rom_detect__29: .byte 0
    rom_detect__38: .byte 0
}
.segment Code
  // chip_rom
chip_rom: {
    .label chip_rom__3 = $ea
    .label chip_rom__5 = $4c
    .label r = $36
    // [647] phi from chip_rom to chip_rom::@1 [phi:chip_rom->chip_rom::@1]
    // [647] phi chip_rom::r#2 = 0 [phi:chip_rom->chip_rom::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z r
    // chip_rom::@1
  __b1:
    // for (unsigned char r = 0; r < 8; r++)
    // [648] if(chip_rom::r#2<8) goto chip_rom::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z r
    cmp #8
    bcc __b2
    // chip_rom::@return
    // }
    // [649] return 
    rts
    // [650] phi from chip_rom::@1 to chip_rom::@2 [phi:chip_rom::@1->chip_rom::@2]
    // chip_rom::@2
  __b2:
    // strcpy(rom, "rom0 ")
    // [651] call strcpy
    // [924] phi from chip_rom::@2 to strcpy [phi:chip_rom::@2->strcpy]
    // [924] phi strcpy::dst#0 = chip_rom::rom [phi:chip_rom::@2->strcpy#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z strcpy.dst
    lda #>rom
    sta.z strcpy.dst+1
    // [924] phi strcpy::src#0 = chip_rom::source [phi:chip_rom::@2->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // chip_rom::@3
    // strcat(rom, rom_size_strings[r])
    // [652] chip_rom::$9 = chip_rom::r#2 << 1 -- vbum1=vbuz2_rol_1 
    lda.z r
    asl
    sta chip_rom__9
    // [653] strcat::source#0 = rom_size_strings[chip_rom::$9] -- pbuz1=qbuc1_derefidx_vbum2 
    tay
    lda rom_size_strings,y
    sta.z strcat.source
    lda rom_size_strings+1,y
    sta.z strcat.source+1
    // [654] call strcat
    // [1569] phi from chip_rom::@3 to strcat [phi:chip_rom::@3->strcat]
    jsr strcat
    // chip_rom::@4
    // r+'0'
    // [655] chip_rom::$3 = chip_rom::r#2 + '0' -- vbuz1=vbuz2_plus_vbuc1 
    lda #'0'
    clc
    adc.z r
    sta.z chip_rom__3
    // *(rom+3) = r+'0'
    // [656] *(chip_rom::rom+3) = chip_rom::$3 -- _deref_pbuc1=vbuz1 
    sta rom+3
    // print_rom_led(r, GREY)
    // [657] print_rom_led::chip#0 = chip_rom::r#2 -- vbuz1=vbuz2 
    lda.z r
    sta.z print_rom_led.chip
    // [658] call print_rom_led
    // [1581] phi from chip_rom::@4 to print_rom_led [phi:chip_rom::@4->print_rom_led]
    // [1581] phi print_rom_led::c#2 = GREY [phi:chip_rom::@4->print_rom_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z print_rom_led.c
    // [1581] phi print_rom_led::chip#2 = print_rom_led::chip#0 [phi:chip_rom::@4->print_rom_led#1] -- register_copy 
    jsr print_rom_led
    // chip_rom::@5
    // r*6
    // [659] chip_rom::$10 = chip_rom::$9 + chip_rom::r#2 -- vbum1=vbum1_plus_vbuz2 
    lda chip_rom__10
    clc
    adc.z r
    sta chip_rom__10
    // [660] chip_rom::$5 = chip_rom::$10 << 1 -- vbuz1=vbum2_rol_1 
    asl
    sta.z chip_rom__5
    // print_chip(CHIP_ROM_X+r*6, CHIP_ROM_Y+1, CHIP_ROM_W, rom)
    // [661] print_chip::x#2 = $14 + chip_rom::$5 -- vbuz1=vbuc1_plus_vbuz1 
    lda #$14
    clc
    adc.z print_chip.x
    sta.z print_chip.x
    // [662] call print_chip
    // [1460] phi from chip_rom::@5 to print_chip [phi:chip_rom::@5->print_chip]
    // [1460] phi print_chip::text#11 = chip_rom::rom [phi:chip_rom::@5->print_chip#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z print_chip.text_2
    lda #>rom
    sta.z print_chip.text_2+1
    // [1460] phi print_chip::w#10 = 3 [phi:chip_rom::@5->print_chip#1] -- vbum1=vbuc1 
    lda #3
    sta print_chip.w
    // [1460] phi print_chip::x#10 = print_chip::x#2 [phi:chip_rom::@5->print_chip#2] -- register_copy 
    jsr print_chip
    // chip_rom::@6
    // for (unsigned char r = 0; r < 8; r++)
    // [663] chip_rom::r#1 = ++ chip_rom::r#2 -- vbuz1=_inc_vbuz1 
    inc.z r
    // [647] phi from chip_rom::@6 to chip_rom::@1 [phi:chip_rom::@6->chip_rom::@1]
    // [647] phi chip_rom::r#2 = chip_rom::r#1 [phi:chip_rom::@6->chip_rom::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    rom: .fill $10, 0
    source: .text "rom0 "
    .byte 0
    chip_rom__9: .byte 0
    .label chip_rom__10 = chip_rom__9
}
.segment Code
  // smc_read
// __zp($48) unsigned int smc_read(char x, __zp($e5) char y, char w, char b, unsigned int progress_row_size, __zp($60) char *flash_ram_address)
smc_read: {
    .const x = 2
    .const b = 8
    .const progress_row_size = $200
    .label fp = $bc
    .label return = $48
    .label smc_file_read = $ad
    .label flash_ram_address = $60
    .label smc_file_size = $48
    /// Holds the amount of bytes actually read in the memory to be flashed.
    .label progress_row_bytes = $57
    .label y = $e5
    // info_line("Reading SMC.BIN flash file into CX16 RAM ...")
    // [665] call info_line
    // [730] phi from smc_read to info_line [phi:smc_read->info_line]
    // [730] phi info_line::info_text#18 = smc_read::info_text [phi:smc_read->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    // [666] phi from smc_read to smc_read::@7 [phi:smc_read->smc_read::@7]
    // smc_read::@7
    // textcolor(WHITE)
    // [667] call textcolor
    // [374] phi from smc_read::@7 to textcolor [phi:smc_read::@7->textcolor]
    // [374] phi textcolor::color#16 = WHITE [phi:smc_read::@7->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [668] phi from smc_read::@7 to smc_read::@8 [phi:smc_read::@7->smc_read::@8]
    // smc_read::@8
    // gotoxy(x, y)
    // [669] call gotoxy
    // [392] phi from smc_read::@8 to gotoxy [phi:smc_read::@8->gotoxy]
    // [392] phi gotoxy::y#26 = $21 [phi:smc_read::@8->gotoxy#0] -- vbuz1=vbuc1 
    lda #$21
    sta.z gotoxy.y
    // [392] phi gotoxy::x#26 = smc_read::x#0 [phi:smc_read::@8->gotoxy#1] -- vbuz1=vbuc1 
    lda #x
    sta.z gotoxy.x
    jsr gotoxy
    // [670] phi from smc_read::@8 to smc_read::@9 [phi:smc_read::@8->smc_read::@9]
    // smc_read::@9
    // FILE *fp = fopen("SMC.BIN", "r")
    // [671] call fopen
    // [1589] phi from smc_read::@9 to fopen [phi:smc_read::@9->fopen]
    // [1589] phi __errno#257 = 0 [phi:smc_read::@9->fopen#0] -- vwsz1=vwsc1 
    lda #<0
    sta.z __errno
    sta.z __errno+1
    // [1589] phi fopen::pathtoken#0 = smc_read::path [phi:smc_read::@9->fopen#1] -- pbuz1=pbuc1 
    lda #<path
    sta.z fopen.pathtoken
    lda #>path
    sta.z fopen.pathtoken+1
    jsr fopen
    // FILE *fp = fopen("SMC.BIN", "r")
    // [672] fopen::return#3 = fopen::return#2
    // smc_read::@10
    // [673] smc_read::fp#0 = fopen::return#3
    // if (fp)
    // [674] if((struct $2 *)0==smc_read::fp#0) goto smc_read::@1 -- pssc1_eq_pssz1_then_la1 
    lda.z fp
    cmp #<0
    bne !+
    lda.z fp+1
    cmp #>0
    beq __b4
  !:
    // [675] phi from smc_read::@10 to smc_read::@2 [phi:smc_read::@10->smc_read::@2]
    // [675] phi smc_read::y#3 = $21 [phi:smc_read::@10->smc_read::@2#0] -- vbuz1=vbuc1 
    lda #$21
    sta.z y
    // [675] phi smc_read::smc_file_size#10 = 0 [phi:smc_read::@10->smc_read::@2#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z smc_file_size
    sta.z smc_file_size+1
    // [675] phi smc_read::progress_row_bytes#3 = 0 [phi:smc_read::@10->smc_read::@2#2] -- vwuz1=vwuc1 
    sta.z progress_row_bytes
    sta.z progress_row_bytes+1
    // [675] phi smc_read::flash_ram_address#2 = (char *)$6000 [phi:smc_read::@10->smc_read::@2#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z flash_ram_address
    lda #>$6000
    sta.z flash_ram_address+1
  // We read b bytes at a time, and each b bytes we plot a dot.
  // Every r bytes we move to the next line.
    // smc_read::@2
  __b2:
    // fgets(flash_ram_address, b, fp)
    // [676] fgets::ptr#2 = smc_read::flash_ram_address#2 -- pbuz1=pbuz2 
    lda.z flash_ram_address
    sta.z fgets.ptr
    lda.z flash_ram_address+1
    sta.z fgets.ptr+1
    // [677] fgets::stream#0 = smc_read::fp#0 -- pssm1=pssz2 
    lda.z fp
    sta fgets.stream
    lda.z fp+1
    sta fgets.stream+1
    // [678] call fgets
    // [1670] phi from smc_read::@2 to fgets [phi:smc_read::@2->fgets]
    // [1670] phi fgets::ptr#12 = fgets::ptr#2 [phi:smc_read::@2->fgets#0] -- register_copy 
    // [1670] phi fgets::size#10 = smc_read::b#0 [phi:smc_read::@2->fgets#1] -- vwuz1=vbuc1 
    lda #<b
    sta.z fgets.size
    lda #>b
    sta.z fgets.size+1
    // [1670] phi fgets::stream#2 = fgets::stream#0 [phi:smc_read::@2->fgets#2] -- register_copy 
    jsr fgets
    // fgets(flash_ram_address, b, fp)
    // [679] fgets::return#5 = fgets::return#1
    // smc_read::@11
    // smc_file_read = fgets(flash_ram_address, b, fp)
    // [680] smc_read::smc_file_read#1 = fgets::return#5
    // while (smc_file_read = fgets(flash_ram_address, b, fp))
    // [681] if(0!=smc_read::smc_file_read#1) goto smc_read::@3 -- 0_neq_vwuz1_then_la1 
    lda.z smc_file_read
    ora.z smc_file_read+1
    bne __b3
    // smc_read::@4
    // fclose(fp)
    // [682] fclose::stream#0 = smc_read::fp#0
    // [683] call fclose
    // [1724] phi from smc_read::@4 to fclose [phi:smc_read::@4->fclose]
    // [1724] phi fclose::stream#2 = fclose::stream#0 [phi:smc_read::@4->fclose#0] -- register_copy 
    jsr fclose
    // [684] phi from smc_read::@4 to smc_read::@1 [phi:smc_read::@4->smc_read::@1]
    // [684] phi smc_read::return#0 = smc_read::smc_file_size#10 [phi:smc_read::@4->smc_read::@1#0] -- register_copy 
    rts
    // [684] phi from smc_read::@10 to smc_read::@1 [phi:smc_read::@10->smc_read::@1]
  __b4:
    // [684] phi smc_read::return#0 = 0 [phi:smc_read::@10->smc_read::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // smc_read::@1
    // smc_read::@return
    // }
    // [685] return 
    rts
    // smc_read::@3
  __b3:
    // if (progress_row_bytes == progress_row_size)
    // [686] if(smc_read::progress_row_bytes#3!=smc_read::progress_row_size#0) goto smc_read::@5 -- vwuz1_neq_vwuc1_then_la1 
    lda.z progress_row_bytes+1
    cmp #>progress_row_size
    bne __b5
    lda.z progress_row_bytes
    cmp #<progress_row_size
    bne __b5
    // smc_read::@6
    // gotoxy(x, ++y);
    // [687] smc_read::y#0 = ++ smc_read::y#3 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [688] gotoxy::y#16 = smc_read::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [689] call gotoxy
    // [392] phi from smc_read::@6 to gotoxy [phi:smc_read::@6->gotoxy]
    // [392] phi gotoxy::y#26 = gotoxy::y#16 [phi:smc_read::@6->gotoxy#0] -- register_copy 
    // [392] phi gotoxy::x#26 = smc_read::x#0 [phi:smc_read::@6->gotoxy#1] -- vbuz1=vbuc1 
    lda #x
    sta.z gotoxy.x
    jsr gotoxy
    // [690] phi from smc_read::@6 to smc_read::@5 [phi:smc_read::@6->smc_read::@5]
    // [690] phi smc_read::y#10 = smc_read::y#0 [phi:smc_read::@6->smc_read::@5#0] -- register_copy 
    // [690] phi smc_read::progress_row_bytes#4 = 0 [phi:smc_read::@6->smc_read::@5#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z progress_row_bytes
    sta.z progress_row_bytes+1
    // [690] phi from smc_read::@3 to smc_read::@5 [phi:smc_read::@3->smc_read::@5]
    // [690] phi smc_read::y#10 = smc_read::y#3 [phi:smc_read::@3->smc_read::@5#0] -- register_copy 
    // [690] phi smc_read::progress_row_bytes#4 = smc_read::progress_row_bytes#3 [phi:smc_read::@3->smc_read::@5#1] -- register_copy 
    // smc_read::@5
  __b5:
    // cputc('+')
    // [691] stackpush(char) = '+' -- _stackpushbyte_=vbuc1 
    lda #'+'
    pha
    // [692] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // flash_ram_address += smc_file_read
    // [694] smc_read::flash_ram_address#0 = smc_read::flash_ram_address#2 + smc_read::smc_file_read#1 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z flash_ram_address
    adc.z smc_file_read
    sta.z flash_ram_address
    lda.z flash_ram_address+1
    adc.z smc_file_read+1
    sta.z flash_ram_address+1
    // smc_file_size += smc_file_read
    // [695] smc_read::smc_file_size#1 = smc_read::smc_file_size#10 + smc_read::smc_file_read#1 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z smc_file_size
    adc.z smc_file_read
    sta.z smc_file_size
    lda.z smc_file_size+1
    adc.z smc_file_read+1
    sta.z smc_file_size+1
    // progress_row_bytes += smc_file_read
    // [696] smc_read::progress_row_bytes#1 = smc_read::progress_row_bytes#4 + smc_read::smc_file_read#1 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z progress_row_bytes
    adc.z smc_file_read
    sta.z progress_row_bytes
    lda.z progress_row_bytes+1
    adc.z smc_file_read+1
    sta.z progress_row_bytes+1
    // [675] phi from smc_read::@5 to smc_read::@2 [phi:smc_read::@5->smc_read::@2]
    // [675] phi smc_read::y#3 = smc_read::y#10 [phi:smc_read::@5->smc_read::@2#0] -- register_copy 
    // [675] phi smc_read::smc_file_size#10 = smc_read::smc_file_size#1 [phi:smc_read::@5->smc_read::@2#1] -- register_copy 
    // [675] phi smc_read::progress_row_bytes#3 = smc_read::progress_row_bytes#1 [phi:smc_read::@5->smc_read::@2#2] -- register_copy 
    // [675] phi smc_read::flash_ram_address#2 = smc_read::flash_ram_address#0 [phi:smc_read::@5->smc_read::@2#3] -- register_copy 
    jmp __b2
  .segment Data
    info_text: .text "Reading SMC.BIN flash file into CX16 RAM ..."
    .byte 0
    path: .text "SMC.BIN"
    .byte 0
}
.segment Code
  // wait_key
// __mem() char wait_key(__zp($c3) char *info_text, __zp($3f) char *filter)
wait_key: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    .label wait_key__9 = $c0
    .label bram = $e9
    .label info_text = $c3
    .label filter = $3f
    // info_line(info_text)
    // [698] info_line::info_text#0 = wait_key::info_text#3
    // [699] call info_line
    // [730] phi from wait_key to info_line [phi:wait_key->info_line]
    // [730] phi info_line::info_text#18 = info_line::info_text#0 [phi:wait_key->info_line#0] -- register_copy 
    jsr info_line
    // wait_key::bank_get_bram1
    // return BRAM;
    // [700] wait_key::bram#0 = BRAM -- vbuz1=vbuz2 
    lda.z BRAM
    sta.z bram
    // wait_key::bank_get_brom1
    // return BROM;
    // [701] wait_key::bank_get_brom1_return#0 = BROM -- vbum1=vbuz2 
    lda.z BROM
    sta bank_get_brom1_return
    // wait_key::bank_set_bram1
    // BRAM = bank
    // [702] BRAM = wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // wait_key::bank_set_brom1
    // BROM = bank
    // [703] BROM = wait_key::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [704] phi from wait_key::@2 wait_key::@5 wait_key::bank_set_brom1 to wait_key::kbhit1 [phi:wait_key::@2/wait_key::@5/wait_key::bank_set_brom1->wait_key::kbhit1]
    // wait_key::kbhit1
  kbhit1:
    // wait_key::kbhit1_cbm_k_clrchn1
    // asm
    // asm { jsrCBM_CLRCHN  }
    jsr CBM_CLRCHN
    // [706] phi from wait_key::kbhit1_cbm_k_clrchn1 to wait_key::kbhit1_@2 [phi:wait_key::kbhit1_cbm_k_clrchn1->wait_key::kbhit1_@2]
    // wait_key::kbhit1_@2
    // cbm_k_getin()
    // [707] call cbm_k_getin
    jsr cbm_k_getin
    // [708] cbm_k_getin::return#2 = cbm_k_getin::return#1
    // wait_key::@4
    // [709] wait_key::ch#4 = cbm_k_getin::return#2 -- vwum1=vbum2 
    lda cbm_k_getin.return
    sta ch
    lda #0
    sta ch+1
    // wait_key::@3
    // if (filter)
    // [710] if((char *)0!=wait_key::filter#13) goto wait_key::@1 -- pbuc1_neq_pbuz1_then_la1 
    // if there is a filter, check the filter, otherwise return ch.
    lda.z filter+1
    cmp #>0
    bne __b1
    lda.z filter
    cmp #<0
    bne __b1
    // wait_key::@2
    // if(ch)
    // [711] if(0!=wait_key::ch#4) goto wait_key::bank_set_bram2 -- 0_neq_vwum1_then_la1 
    lda ch
    ora ch+1
    bne bank_set_bram2
    jmp kbhit1
    // wait_key::bank_set_bram2
  bank_set_bram2:
    // BRAM = bank
    // [712] BRAM = wait_key::bram#0 -- vbuz1=vbuz2 
    lda.z bram
    sta.z BRAM
    // wait_key::bank_set_brom2
    // BROM = bank
    // [713] BROM = wait_key::bank_get_brom1_return#0 -- vbuz1=vbum2 
    lda bank_get_brom1_return
    sta.z BROM
    // wait_key::@return
    // }
    // [714] return 
    rts
    // wait_key::@1
  __b1:
    // strchr(filter, ch)
    // [715] strchr::str#0 = (const void *)wait_key::filter#13 -- pvoz1=pvoz2 
    lda.z filter
    sta.z strchr.str
    lda.z filter+1
    sta.z strchr.str+1
    // [716] strchr::c#0 = wait_key::ch#4 -- vbum1=vwum2 
    lda ch
    sta strchr.c
    // [717] call strchr
    // [721] phi from wait_key::@1 to strchr [phi:wait_key::@1->strchr]
    // [721] phi strchr::c#4 = strchr::c#0 [phi:wait_key::@1->strchr#0] -- register_copy 
    // [721] phi strchr::str#2 = strchr::str#0 [phi:wait_key::@1->strchr#1] -- register_copy 
    jsr strchr
    // strchr(filter, ch)
    // [718] strchr::return#3 = strchr::return#2
    // wait_key::@5
    // [719] wait_key::$9 = strchr::return#3
    // if(strchr(filter, ch) != NULL)
    // [720] if(wait_key::$9!=0) goto wait_key::bank_set_bram2 -- pvoz1_neq_0_then_la1 
    lda.z wait_key__9
    ora.z wait_key__9+1
    bne bank_set_bram2
    jmp kbhit1
  .segment Data
    bank_get_brom1_return: .byte 0
    .label return = strchr.c
    .label ch = rom_read.fp
}
.segment Code
  // strchr
// Searches for the first occurrence of the character c (an unsigned char) in the string pointed to, by the argument str.
// - str: The memory to search
// - c: A character to search for
// Return: A pointer to the matching byte or NULL if the character does not occur in the given memory area.
// __zp($c0) void * strchr(__zp($c0) const void *str, __mem() char c)
strchr: {
    .label ptr = $c0
    .label return = $c0
    .label str = $c0
    // [722] strchr::ptr#6 = (char *)strchr::str#2
    // [723] phi from strchr strchr::@3 to strchr::@1 [phi:strchr/strchr::@3->strchr::@1]
    // [723] phi strchr::ptr#2 = strchr::ptr#6 [phi:strchr/strchr::@3->strchr::@1#0] -- register_copy 
    // strchr::@1
  __b1:
    // while(*ptr)
    // [724] if(0!=*strchr::ptr#2) goto strchr::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (ptr),y
    cmp #0
    bne __b2
    // [725] phi from strchr::@1 to strchr::@return [phi:strchr::@1->strchr::@return]
    // [725] phi strchr::return#2 = (void *) 0 [phi:strchr::@1->strchr::@return#0] -- pvoz1=pvoc1 
    tya
    sta.z return
    sta.z return+1
    // strchr::@return
    // }
    // [726] return 
    rts
    // strchr::@2
  __b2:
    // if(*ptr==c)
    // [727] if(*strchr::ptr#2!=strchr::c#4) goto strchr::@3 -- _deref_pbuz1_neq_vbum2_then_la1 
    ldy #0
    lda (ptr),y
    cmp c
    bne __b3
    // strchr::@4
    // [728] strchr::return#8 = (void *)strchr::ptr#2
    // [725] phi from strchr::@4 to strchr::@return [phi:strchr::@4->strchr::@return]
    // [725] phi strchr::return#2 = strchr::return#8 [phi:strchr::@4->strchr::@return#0] -- register_copy 
    rts
    // strchr::@3
  __b3:
    // ptr++;
    // [729] strchr::ptr#1 = ++ strchr::ptr#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr
    bne !+
    inc.z ptr+1
  !:
    jmp __b1
  .segment Data
    c: .byte 0
}
.segment Code
  // info_line
// void info_line(__zp($c3) char *info_text)
info_line: {
    .label info_text = $c3
    // unsigned char x = wherex()
    // [731] call wherex
    jsr wherex
    // [732] wherex::return#3 = wherex::return#0 -- vbum1=vbum2 
    lda wherex.return
    sta wherex.return_1
    // info_line::@1
    // [733] info_line::x#0 = wherex::return#3
    // unsigned char y = wherey()
    // [734] call wherey
    jsr wherey
    // [735] wherey::return#3 = wherey::return#0 -- vbum1=vbum2 
    lda wherey.return
    sta wherey.return_1
    // info_line::@2
    // [736] info_line::y#0 = wherey::return#3
    // gotoxy(2, 14)
    // [737] call gotoxy
    // [392] phi from info_line::@2 to gotoxy [phi:info_line::@2->gotoxy]
    // [392] phi gotoxy::y#26 = $e [phi:info_line::@2->gotoxy#0] -- vbuz1=vbuc1 
    lda #$e
    sta.z gotoxy.y
    // [392] phi gotoxy::x#26 = 2 [phi:info_line::@2->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // info_line::@3
    // printf("%-60s", info_text)
    // [738] printf_string::str#1 = info_line::info_text#18 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [739] call printf_string
    // [932] phi from info_line::@3 to printf_string [phi:info_line::@3->printf_string]
    // [932] phi printf_string::putc#14 = &cputc [phi:info_line::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [932] phi printf_string::str#14 = printf_string::str#1 [phi:info_line::@3->printf_string#1] -- register_copy 
    // [932] phi printf_string::format_justify_left#14 = 1 [phi:info_line::@3->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [932] phi printf_string::format_min_length#14 = $3c [phi:info_line::@3->printf_string#3] -- vbuz1=vbuc1 
    lda #$3c
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_line::@4
    // gotoxy(x, y)
    // [740] gotoxy::x#12 = info_line::x#0 -- vbuz1=vbum2 
    lda x
    sta.z gotoxy.x
    // [741] gotoxy::y#12 = info_line::y#0 -- vbuz1=vbum2 
    lda y
    sta.z gotoxy.y
    // [742] call gotoxy
    // [392] phi from info_line::@4 to gotoxy [phi:info_line::@4->gotoxy]
    // [392] phi gotoxy::y#26 = gotoxy::y#12 [phi:info_line::@4->gotoxy#0] -- register_copy 
    // [392] phi gotoxy::x#26 = gotoxy::x#12 [phi:info_line::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // info_line::@return
    // }
    // [743] return 
    rts
  .segment Data
    .label x = wherex.return_1
    .label y = flash_smc.smc_byte_upload
}
.segment Code
  // flash_smc
// unsigned int flash_smc(char x, __zp($7e) char y, char w, __zp($c7) unsigned int smc_bytes_total, char b, unsigned int smc_row_total, __zp($d4) char *smc_ram_ptr)
flash_smc: {
    .const x = 2
    .const smc_row_total = $200
    .label flash_smc__25 = $ce
    .label flash_smc__26 = $ce
    .label cx16_k_i2c_write_byte1_return = $36
    .label smc_bootloader_start = $36
    .label smc_bootloader_not_activated1 = $48
    // Wait an other 5 seconds to ensure the bootloader is activated.
    .label smc_bootloader_activation_countdown = $79
    .label smc_bootloader_not_activated = $48
    .label x2 = $62
    // Wait an other 5 seconds to ensure the bootloader is activated.
    .label smc_bootloader_activation_countdown_1 = $7f
    .label smc_ram_ptr = $d4
    .label smc_bytes_checksum = $ce
    .label smc_package_flashed = $2e
    .label smc_commit_result = $48
    .label smc_attempts_flashed = $c5
    .label smc_row_bytes = $cf
    .label y = $7e
    .label smc_bytes_total = $c7
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [744] flash_smc::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [745] flash_smc::cx16_k_i2c_write_byte1_offset = $8f -- vbum1=vbuc1 
    lda #$8f
    sta cx16_k_i2c_write_byte1_offset
    // [746] flash_smc::cx16_k_i2c_write_byte1_value = $31 -- vbum1=vbuc1 
    lda #$31
    sta cx16_k_i2c_write_byte1_value
    // flash_smc::cx16_k_i2c_write_byte1
    // unsigned char result
    // [747] flash_smc::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
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
    // [749] flash_smc::cx16_k_i2c_write_byte1_return#0 = flash_smc::cx16_k_i2c_write_byte1_result -- vbuz1=vbum2 
    lda cx16_k_i2c_write_byte1_result
    sta.z cx16_k_i2c_write_byte1_return
    // flash_smc::cx16_k_i2c_write_byte1_@return
    // }
    // [750] flash_smc::cx16_k_i2c_write_byte1_return#1 = flash_smc::cx16_k_i2c_write_byte1_return#0
    // flash_smc::@27
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [751] flash_smc::smc_bootloader_start#0 = flash_smc::cx16_k_i2c_write_byte1_return#1
    // if(smc_bootloader_start)
    // [752] if(0==flash_smc::smc_bootloader_start#0) goto flash_smc::@3 -- 0_eq_vbuz1_then_la1 
    lda.z smc_bootloader_start
    beq __b2
    // [753] phi from flash_smc::@27 to flash_smc::@2 [phi:flash_smc::@27->flash_smc::@2]
    // flash_smc::@2
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [754] call snprintf_init
    jsr snprintf_init
    // [755] phi from flash_smc::@2 to flash_smc::@30 [phi:flash_smc::@2->flash_smc::@30]
    // flash_smc::@30
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [756] call printf_str
    // [531] phi from flash_smc::@30 to printf_str [phi:flash_smc::@30->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:flash_smc::@30->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = flash_smc::s [phi:flash_smc::@30->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@31
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [757] printf_uchar::uvalue#1 = flash_smc::smc_bootloader_start#0
    // [758] call printf_uchar
    // [913] phi from flash_smc::@31 to printf_uchar [phi:flash_smc::@31->printf_uchar]
    // [913] phi printf_uchar::format_zero_padding#10 = 0 [phi:flash_smc::@31->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [913] phi printf_uchar::format_min_length#10 = 0 [phi:flash_smc::@31->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [913] phi printf_uchar::putc#10 = &snputc [phi:flash_smc::@31->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [913] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:flash_smc::@31->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [913] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#1 [phi:flash_smc::@31->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // flash_smc::@32
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [759] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [760] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [762] call info_line
    // [730] phi from flash_smc::@32 to info_line [phi:flash_smc::@32->info_line]
    // [730] phi info_line::info_text#18 = info_text [phi:flash_smc::@32->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    // flash_smc::@33
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [763] flash_smc::cx16_k_i2c_write_byte2_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte2_device
    // [764] flash_smc::cx16_k_i2c_write_byte2_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte2_offset
    // [765] flash_smc::cx16_k_i2c_write_byte2_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte2_value
    // flash_smc::cx16_k_i2c_write_byte2
    // unsigned char result
    // [766] flash_smc::cx16_k_i2c_write_byte2_result = 0 -- vbum1=vbuc1 
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
    // [768] return 
    rts
    // [769] phi from flash_smc::@27 to flash_smc::@3 [phi:flash_smc::@27->flash_smc::@3]
  __b2:
    // [769] phi flash_smc::smc_bootloader_activation_countdown#22 = $14 [phi:flash_smc::@27->flash_smc::@3#0] -- vbuz1=vbuc1 
    lda #$14
    sta.z smc_bootloader_activation_countdown
    // flash_smc::@3
  __b3:
    // while(smc_bootloader_activation_countdown)
    // [770] if(0!=flash_smc::smc_bootloader_activation_countdown#22) goto flash_smc::@4 -- 0_neq_vbuz1_then_la1 
    lda.z smc_bootloader_activation_countdown
    beq !__b4+
    jmp __b4
  !__b4:
    // [771] phi from flash_smc::@3 flash_smc::@34 to flash_smc::@9 [phi:flash_smc::@3/flash_smc::@34->flash_smc::@9]
  __b5:
    // [771] phi flash_smc::smc_bootloader_activation_countdown#23 = 5 [phi:flash_smc::@3/flash_smc::@34->flash_smc::@9#0] -- vbuz1=vbuc1 
    lda #5
    sta.z smc_bootloader_activation_countdown_1
    // flash_smc::@9
  __b9:
    // while(smc_bootloader_activation_countdown)
    // [772] if(0!=flash_smc::smc_bootloader_activation_countdown#23) goto flash_smc::@11 -- 0_neq_vbuz1_then_la1 
    lda.z smc_bootloader_activation_countdown_1
    beq !__b13+
    jmp __b13
  !__b13:
    // flash_smc::@10
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [773] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [774] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [775] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [776] cx16_k_i2c_read_byte::return#3 = cx16_k_i2c_read_byte::return#1
    // flash_smc::@39
    // smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [777] flash_smc::smc_bootloader_not_activated#1 = cx16_k_i2c_read_byte::return#3
    // if(smc_bootloader_not_activated)
    // [778] if(0==flash_smc::smc_bootloader_not_activated#1) goto flash_smc::@1 -- 0_eq_vwuz1_then_la1 
    lda.z smc_bootloader_not_activated
    ora.z smc_bootloader_not_activated+1
    beq __b1
    // [779] phi from flash_smc::@39 to flash_smc::@14 [phi:flash_smc::@39->flash_smc::@14]
    // flash_smc::@14
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [780] call snprintf_init
    jsr snprintf_init
    // [781] phi from flash_smc::@14 to flash_smc::@46 [phi:flash_smc::@14->flash_smc::@46]
    // flash_smc::@46
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [782] call printf_str
    // [531] phi from flash_smc::@46 to printf_str [phi:flash_smc::@46->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:flash_smc::@46->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = flash_smc::s5 [phi:flash_smc::@46->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@47
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [783] printf_uint::uvalue#1 = flash_smc::smc_bootloader_not_activated#1
    // [784] call printf_uint
    // [540] phi from flash_smc::@47 to printf_uint [phi:flash_smc::@47->printf_uint]
    // [540] phi printf_uint::format_zero_padding#12 = 0 [phi:flash_smc::@47->printf_uint#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uint.format_zero_padding
    // [540] phi printf_uint::format_min_length#12 = 0 [phi:flash_smc::@47->printf_uint#1] -- vbuz1=vbuc1 
    sta.z printf_uint.format_min_length
    // [540] phi printf_uint::putc#12 = &snputc [phi:flash_smc::@47->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [540] phi printf_uint::format_radix#12 = HEXADECIMAL [phi:flash_smc::@47->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [540] phi printf_uint::uvalue#12 = printf_uint::uvalue#1 [phi:flash_smc::@47->printf_uint#4] -- register_copy 
    jsr printf_uint
    // flash_smc::@48
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [785] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [786] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [788] call info_line
    // [730] phi from flash_smc::@48 to info_line [phi:flash_smc::@48->info_line]
    // [730] phi info_line::info_text#18 = info_text [phi:flash_smc::@48->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    rts
    // [789] phi from flash_smc::@39 to flash_smc::@1 [phi:flash_smc::@39->flash_smc::@1]
    // flash_smc::@1
  __b1:
    // textcolor(WHITE)
    // [790] call textcolor
    // [374] phi from flash_smc::@1 to textcolor [phi:flash_smc::@1->textcolor]
    // [374] phi textcolor::color#16 = WHITE [phi:flash_smc::@1->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [791] phi from flash_smc::@1 to flash_smc::@45 [phi:flash_smc::@1->flash_smc::@45]
    // flash_smc::@45
    // gotoxy(x, y)
    // [792] call gotoxy
    // [392] phi from flash_smc::@45 to gotoxy [phi:flash_smc::@45->gotoxy]
    // [392] phi gotoxy::y#26 = $21 [phi:flash_smc::@45->gotoxy#0] -- vbuz1=vbuc1 
    lda #$21
    sta.z gotoxy.y
    // [392] phi gotoxy::x#26 = flash_smc::x#0 [phi:flash_smc::@45->gotoxy#1] -- vbuz1=vbuc1 
    lda #x
    sta.z gotoxy.x
    jsr gotoxy
    // [793] phi from flash_smc::@45 to flash_smc::@15 [phi:flash_smc::@45->flash_smc::@15]
    // [793] phi flash_smc::y#33 = $21 [phi:flash_smc::@45->flash_smc::@15#0] -- vbuz1=vbuc1 
    lda #$21
    sta.z y
    // [793] phi flash_smc::smc_attempts_total#21 = 0 [phi:flash_smc::@45->flash_smc::@15#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_attempts_total
    sta smc_attempts_total+1
    // [793] phi flash_smc::smc_row_bytes#14 = 0 [phi:flash_smc::@45->flash_smc::@15#2] -- vwuz1=vwuc1 
    sta.z smc_row_bytes
    sta.z smc_row_bytes+1
    // [793] phi flash_smc::smc_ram_ptr#13 = (char *)$6000 [phi:flash_smc::@45->flash_smc::@15#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z smc_ram_ptr
    lda #>$6000
    sta.z smc_ram_ptr+1
    // [793] phi flash_smc::smc_bytes_flashed#13 = 0 [phi:flash_smc::@45->flash_smc::@15#4] -- vwum1=vwuc1 
    lda #<0
    sta smc_bytes_flashed
    sta smc_bytes_flashed+1
    // [793] phi from flash_smc::@18 to flash_smc::@15 [phi:flash_smc::@18->flash_smc::@15]
    // [793] phi flash_smc::y#33 = flash_smc::y#23 [phi:flash_smc::@18->flash_smc::@15#0] -- register_copy 
    // [793] phi flash_smc::smc_attempts_total#21 = flash_smc::smc_attempts_total#17 [phi:flash_smc::@18->flash_smc::@15#1] -- register_copy 
    // [793] phi flash_smc::smc_row_bytes#14 = flash_smc::smc_row_bytes#10 [phi:flash_smc::@18->flash_smc::@15#2] -- register_copy 
    // [793] phi flash_smc::smc_ram_ptr#13 = flash_smc::smc_ram_ptr#10 [phi:flash_smc::@18->flash_smc::@15#3] -- register_copy 
    // [793] phi flash_smc::smc_bytes_flashed#13 = flash_smc::smc_bytes_flashed#12 [phi:flash_smc::@18->flash_smc::@15#4] -- register_copy 
    // flash_smc::@15
  __b15:
    // while(smc_bytes_flashed < smc_bytes_total)
    // [794] if(flash_smc::smc_bytes_flashed#13<flash_smc::smc_bytes_total#0) goto flash_smc::@17 -- vwum1_lt_vwuz2_then_la1 
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
    // [795] flash_smc::cx16_k_i2c_write_byte3_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte3_device
    // [796] flash_smc::cx16_k_i2c_write_byte3_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte3_offset
    // [797] flash_smc::cx16_k_i2c_write_byte3_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte3_value
    // flash_smc::cx16_k_i2c_write_byte3
    // unsigned char result
    // [798] flash_smc::cx16_k_i2c_write_byte3_result = 0 -- vbum1=vbuc1 
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
    // [800] phi from flash_smc::@15 to flash_smc::@17 [phi:flash_smc::@15->flash_smc::@17]
  __b8:
    // [800] phi flash_smc::y#23 = flash_smc::y#33 [phi:flash_smc::@15->flash_smc::@17#0] -- register_copy 
    // [800] phi flash_smc::smc_attempts_total#17 = flash_smc::smc_attempts_total#21 [phi:flash_smc::@15->flash_smc::@17#1] -- register_copy 
    // [800] phi flash_smc::smc_row_bytes#10 = flash_smc::smc_row_bytes#14 [phi:flash_smc::@15->flash_smc::@17#2] -- register_copy 
    // [800] phi flash_smc::smc_ram_ptr#10 = flash_smc::smc_ram_ptr#13 [phi:flash_smc::@15->flash_smc::@17#3] -- register_copy 
    // [800] phi flash_smc::smc_bytes_flashed#12 = flash_smc::smc_bytes_flashed#13 [phi:flash_smc::@15->flash_smc::@17#4] -- register_copy 
    // [800] phi flash_smc::smc_attempts_flashed#19 = 0 [phi:flash_smc::@15->flash_smc::@17#5] -- vbuz1=vbuc1 
    lda #0
    sta.z smc_attempts_flashed
    // [800] phi flash_smc::smc_package_committed#2 = 0 [phi:flash_smc::@15->flash_smc::@17#6] -- vbum1=vbuc1 
    sta smc_package_committed
    // flash_smc::@17
  __b17:
    // while(!smc_package_committed && smc_attempts_flashed < 10)
    // [801] if(0!=flash_smc::smc_package_committed#2) goto flash_smc::@18 -- 0_neq_vbum1_then_la1 
    lda smc_package_committed
    bne __b18
    // flash_smc::@61
    // [802] if(flash_smc::smc_attempts_flashed#19<$a) goto flash_smc::@19 -- vbuz1_lt_vbuc1_then_la1 
    lda.z smc_attempts_flashed
    cmp #$a
    bcc __b10
    // flash_smc::@18
  __b18:
    // if(smc_attempts_flashed >= 10)
    // [803] if(flash_smc::smc_attempts_flashed#19<$a) goto flash_smc::@15 -- vbuz1_lt_vbuc1_then_la1 
    lda.z smc_attempts_flashed
    cmp #$a
    bcc __b15
    // [804] phi from flash_smc::@18 to flash_smc::@26 [phi:flash_smc::@18->flash_smc::@26]
    // flash_smc::@26
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [805] call snprintf_init
    jsr snprintf_init
    // [806] phi from flash_smc::@26 to flash_smc::@58 [phi:flash_smc::@26->flash_smc::@58]
    // flash_smc::@58
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [807] call printf_str
    // [531] phi from flash_smc::@58 to printf_str [phi:flash_smc::@58->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:flash_smc::@58->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = flash_smc::s10 [phi:flash_smc::@58->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@59
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [808] printf_uint::uvalue#5 = flash_smc::smc_bytes_flashed#12 -- vwuz1=vwum2 
    lda smc_bytes_flashed
    sta.z printf_uint.uvalue
    lda smc_bytes_flashed+1
    sta.z printf_uint.uvalue+1
    // [809] call printf_uint
    // [540] phi from flash_smc::@59 to printf_uint [phi:flash_smc::@59->printf_uint]
    // [540] phi printf_uint::format_zero_padding#12 = 1 [phi:flash_smc::@59->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [540] phi printf_uint::format_min_length#12 = 4 [phi:flash_smc::@59->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [540] phi printf_uint::putc#12 = &snputc [phi:flash_smc::@59->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [540] phi printf_uint::format_radix#12 = HEXADECIMAL [phi:flash_smc::@59->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [540] phi printf_uint::uvalue#12 = printf_uint::uvalue#5 [phi:flash_smc::@59->printf_uint#4] -- register_copy 
    jsr printf_uint
    // flash_smc::@60
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [810] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [811] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [813] call info_line
    // [730] phi from flash_smc::@60 to info_line [phi:flash_smc::@60->info_line]
    // [730] phi info_line::info_text#18 = info_text [phi:flash_smc::@60->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    rts
    // [814] phi from flash_smc::@61 to flash_smc::@19 [phi:flash_smc::@61->flash_smc::@19]
  __b10:
    // [814] phi flash_smc::smc_bytes_checksum#2 = 0 [phi:flash_smc::@61->flash_smc::@19#0] -- vbuz1=vbuc1 
    lda #0
    sta.z smc_bytes_checksum
    // [814] phi flash_smc::smc_ram_ptr#12 = flash_smc::smc_ram_ptr#10 [phi:flash_smc::@61->flash_smc::@19#1] -- register_copy 
    // [814] phi flash_smc::smc_package_flashed#2 = 0 [phi:flash_smc::@61->flash_smc::@19#2] -- vwuz1=vwuc1 
    sta.z smc_package_flashed
    sta.z smc_package_flashed+1
    // flash_smc::@19
  __b19:
    // while(smc_package_flashed < 8)
    // [815] if(flash_smc::smc_package_flashed#2<8) goto flash_smc::@20 -- vwuz1_lt_vbuc1_then_la1 
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
    // [816] flash_smc::$25 = flash_smc::smc_bytes_checksum#2 ^ $ff -- vbuz1=vbuz1_bxor_vbuc1 
    lda #$ff
    eor.z flash_smc__25
    sta.z flash_smc__25
    // (smc_bytes_checksum ^ 0xFF)+1
    // [817] flash_smc::$26 = flash_smc::$25 + 1 -- vbuz1=vbuz1_plus_1 
    inc.z flash_smc__26
    // unsigned char smc_checksum_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, (smc_bytes_checksum ^ 0xFF)+1)
    // [818] flash_smc::cx16_k_i2c_write_byte5_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte5_device
    // [819] flash_smc::cx16_k_i2c_write_byte5_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte5_offset
    // [820] flash_smc::cx16_k_i2c_write_byte5_value = flash_smc::$26 -- vbum1=vbuz2 
    lda.z flash_smc__26
    sta cx16_k_i2c_write_byte5_value
    // flash_smc::cx16_k_i2c_write_byte5
    // unsigned char result
    // [821] flash_smc::cx16_k_i2c_write_byte5_result = 0 -- vbum1=vbuc1 
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
    // [823] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [824] cx16_k_i2c_read_byte::offset = $81 -- vbum1=vbuc1 
    lda #$81
    sta cx16_k_i2c_read_byte.offset
    // [825] call cx16_k_i2c_read_byte
    // Now send the commit command.
    jsr cx16_k_i2c_read_byte
    // [826] cx16_k_i2c_read_byte::return#4 = cx16_k_i2c_read_byte::return#1
    // flash_smc::@49
    // [827] flash_smc::smc_commit_result#0 = cx16_k_i2c_read_byte::return#4
    // if(smc_commit_result == 1)
    // [828] if(flash_smc::smc_commit_result#0==1) goto flash_smc::@23 -- vwuz1_eq_vbuc1_then_la1 
    lda.z smc_commit_result+1
    bne !+
    lda.z smc_commit_result
    cmp #1
    beq __b23
  !:
    // flash_smc::@22
    // smc_ram_ptr -= 8
    // [829] flash_smc::smc_ram_ptr#1 = flash_smc::smc_ram_ptr#12 - 8 -- pbuz1=pbuz1_minus_vbuc1 
    sec
    lda.z smc_ram_ptr
    sbc #8
    sta.z smc_ram_ptr
    lda.z smc_ram_ptr+1
    sbc #0
    sta.z smc_ram_ptr+1
    // smc_attempts_flashed++;
    // [830] flash_smc::smc_attempts_flashed#1 = ++ flash_smc::smc_attempts_flashed#19 -- vbuz1=_inc_vbuz1 
    inc.z smc_attempts_flashed
    // [800] phi from flash_smc::@22 to flash_smc::@17 [phi:flash_smc::@22->flash_smc::@17]
    // [800] phi flash_smc::y#23 = flash_smc::y#23 [phi:flash_smc::@22->flash_smc::@17#0] -- register_copy 
    // [800] phi flash_smc::smc_attempts_total#17 = flash_smc::smc_attempts_total#17 [phi:flash_smc::@22->flash_smc::@17#1] -- register_copy 
    // [800] phi flash_smc::smc_row_bytes#10 = flash_smc::smc_row_bytes#10 [phi:flash_smc::@22->flash_smc::@17#2] -- register_copy 
    // [800] phi flash_smc::smc_ram_ptr#10 = flash_smc::smc_ram_ptr#1 [phi:flash_smc::@22->flash_smc::@17#3] -- register_copy 
    // [800] phi flash_smc::smc_bytes_flashed#12 = flash_smc::smc_bytes_flashed#12 [phi:flash_smc::@22->flash_smc::@17#4] -- register_copy 
    // [800] phi flash_smc::smc_attempts_flashed#19 = flash_smc::smc_attempts_flashed#1 [phi:flash_smc::@22->flash_smc::@17#5] -- register_copy 
    // [800] phi flash_smc::smc_package_committed#2 = flash_smc::smc_package_committed#2 [phi:flash_smc::@22->flash_smc::@17#6] -- register_copy 
    jmp __b17
    // flash_smc::@23
  __b23:
    // if (smc_row_bytes == smc_row_total)
    // [831] if(flash_smc::smc_row_bytes#10!=flash_smc::smc_row_total#0) goto flash_smc::@24 -- vwuz1_neq_vwuc1_then_la1 
    lda.z smc_row_bytes+1
    cmp #>smc_row_total
    bne __b24
    lda.z smc_row_bytes
    cmp #<smc_row_total
    bne __b24
    // flash_smc::@25
    // gotoxy(x, ++y);
    // [832] flash_smc::y#0 = ++ flash_smc::y#23 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [833] gotoxy::y#18 = flash_smc::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [834] call gotoxy
    // [392] phi from flash_smc::@25 to gotoxy [phi:flash_smc::@25->gotoxy]
    // [392] phi gotoxy::y#26 = gotoxy::y#18 [phi:flash_smc::@25->gotoxy#0] -- register_copy 
    // [392] phi gotoxy::x#26 = flash_smc::x#0 [phi:flash_smc::@25->gotoxy#1] -- vbuz1=vbuc1 
    lda #x
    sta.z gotoxy.x
    jsr gotoxy
    // [835] phi from flash_smc::@25 to flash_smc::@24 [phi:flash_smc::@25->flash_smc::@24]
    // [835] phi flash_smc::y#35 = flash_smc::y#0 [phi:flash_smc::@25->flash_smc::@24#0] -- register_copy 
    // [835] phi flash_smc::smc_row_bytes#4 = 0 [phi:flash_smc::@25->flash_smc::@24#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z smc_row_bytes
    sta.z smc_row_bytes+1
    // [835] phi from flash_smc::@23 to flash_smc::@24 [phi:flash_smc::@23->flash_smc::@24]
    // [835] phi flash_smc::y#35 = flash_smc::y#23 [phi:flash_smc::@23->flash_smc::@24#0] -- register_copy 
    // [835] phi flash_smc::smc_row_bytes#4 = flash_smc::smc_row_bytes#10 [phi:flash_smc::@23->flash_smc::@24#1] -- register_copy 
    // flash_smc::@24
  __b24:
    // cputc('*')
    // [836] stackpush(char) = '*' -- _stackpushbyte_=vbuc1 
    lda #'*'
    pha
    // [837] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_bytes_flashed += 8
    // [839] flash_smc::smc_bytes_flashed#1 = flash_smc::smc_bytes_flashed#12 + 8 -- vwum1=vwum1_plus_vbuc1 
    lda #8
    clc
    adc smc_bytes_flashed
    sta smc_bytes_flashed
    bcc !+
    inc smc_bytes_flashed+1
  !:
    // smc_row_bytes += 8
    // [840] flash_smc::smc_row_bytes#1 = flash_smc::smc_row_bytes#4 + 8 -- vwuz1=vwuz1_plus_vbuc1 
    lda #8
    clc
    adc.z smc_row_bytes
    sta.z smc_row_bytes
    bcc !+
    inc.z smc_row_bytes+1
  !:
    // smc_attempts_total += smc_attempts_flashed
    // [841] flash_smc::smc_attempts_total#1 = flash_smc::smc_attempts_total#17 + flash_smc::smc_attempts_flashed#19 -- vwum1=vwum1_plus_vbuz2 
    lda.z smc_attempts_flashed
    clc
    adc smc_attempts_total
    sta smc_attempts_total
    bcc !+
    inc smc_attempts_total+1
  !:
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [842] call snprintf_init
    jsr snprintf_init
    // [843] phi from flash_smc::@24 to flash_smc::@50 [phi:flash_smc::@24->flash_smc::@50]
    // flash_smc::@50
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [844] call printf_str
    // [531] phi from flash_smc::@50 to printf_str [phi:flash_smc::@50->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:flash_smc::@50->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = flash_smc::s6 [phi:flash_smc::@50->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@51
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [845] printf_uint::uvalue#2 = flash_smc::smc_bytes_flashed#1 -- vwuz1=vwum2 
    lda smc_bytes_flashed
    sta.z printf_uint.uvalue
    lda smc_bytes_flashed+1
    sta.z printf_uint.uvalue+1
    // [846] call printf_uint
    // [540] phi from flash_smc::@51 to printf_uint [phi:flash_smc::@51->printf_uint]
    // [540] phi printf_uint::format_zero_padding#12 = 1 [phi:flash_smc::@51->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [540] phi printf_uint::format_min_length#12 = 5 [phi:flash_smc::@51->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [540] phi printf_uint::putc#12 = &snputc [phi:flash_smc::@51->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [540] phi printf_uint::format_radix#12 = DECIMAL [phi:flash_smc::@51->printf_uint#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [540] phi printf_uint::uvalue#12 = printf_uint::uvalue#2 [phi:flash_smc::@51->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [847] phi from flash_smc::@51 to flash_smc::@52 [phi:flash_smc::@51->flash_smc::@52]
    // flash_smc::@52
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [848] call printf_str
    // [531] phi from flash_smc::@52 to printf_str [phi:flash_smc::@52->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:flash_smc::@52->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = flash_smc::s7 [phi:flash_smc::@52->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@53
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [849] printf_uint::uvalue#3 = flash_smc::smc_bytes_total#0 -- vwuz1=vwuz2 
    lda.z smc_bytes_total
    sta.z printf_uint.uvalue
    lda.z smc_bytes_total+1
    sta.z printf_uint.uvalue+1
    // [850] call printf_uint
    // [540] phi from flash_smc::@53 to printf_uint [phi:flash_smc::@53->printf_uint]
    // [540] phi printf_uint::format_zero_padding#12 = 1 [phi:flash_smc::@53->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [540] phi printf_uint::format_min_length#12 = 5 [phi:flash_smc::@53->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [540] phi printf_uint::putc#12 = &snputc [phi:flash_smc::@53->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [540] phi printf_uint::format_radix#12 = DECIMAL [phi:flash_smc::@53->printf_uint#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [540] phi printf_uint::uvalue#12 = printf_uint::uvalue#3 [phi:flash_smc::@53->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [851] phi from flash_smc::@53 to flash_smc::@54 [phi:flash_smc::@53->flash_smc::@54]
    // flash_smc::@54
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [852] call printf_str
    // [531] phi from flash_smc::@54 to printf_str [phi:flash_smc::@54->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:flash_smc::@54->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = flash_smc::s8 [phi:flash_smc::@54->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@55
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [853] printf_uint::uvalue#4 = flash_smc::smc_attempts_total#1 -- vwuz1=vwum2 
    lda smc_attempts_total
    sta.z printf_uint.uvalue
    lda smc_attempts_total+1
    sta.z printf_uint.uvalue+1
    // [854] call printf_uint
    // [540] phi from flash_smc::@55 to printf_uint [phi:flash_smc::@55->printf_uint]
    // [540] phi printf_uint::format_zero_padding#12 = 1 [phi:flash_smc::@55->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [540] phi printf_uint::format_min_length#12 = 2 [phi:flash_smc::@55->printf_uint#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uint.format_min_length
    // [540] phi printf_uint::putc#12 = &snputc [phi:flash_smc::@55->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [540] phi printf_uint::format_radix#12 = DECIMAL [phi:flash_smc::@55->printf_uint#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [540] phi printf_uint::uvalue#12 = printf_uint::uvalue#4 [phi:flash_smc::@55->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [855] phi from flash_smc::@55 to flash_smc::@56 [phi:flash_smc::@55->flash_smc::@56]
    // flash_smc::@56
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [856] call printf_str
    // [531] phi from flash_smc::@56 to printf_str [phi:flash_smc::@56->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:flash_smc::@56->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = flash_smc::s9 [phi:flash_smc::@56->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@57
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [857] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [858] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [860] call info_line
    // [730] phi from flash_smc::@57 to info_line [phi:flash_smc::@57->info_line]
    // [730] phi info_line::info_text#18 = info_text [phi:flash_smc::@57->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    // [800] phi from flash_smc::@57 to flash_smc::@17 [phi:flash_smc::@57->flash_smc::@17]
    // [800] phi flash_smc::y#23 = flash_smc::y#35 [phi:flash_smc::@57->flash_smc::@17#0] -- register_copy 
    // [800] phi flash_smc::smc_attempts_total#17 = flash_smc::smc_attempts_total#1 [phi:flash_smc::@57->flash_smc::@17#1] -- register_copy 
    // [800] phi flash_smc::smc_row_bytes#10 = flash_smc::smc_row_bytes#1 [phi:flash_smc::@57->flash_smc::@17#2] -- register_copy 
    // [800] phi flash_smc::smc_ram_ptr#10 = flash_smc::smc_ram_ptr#12 [phi:flash_smc::@57->flash_smc::@17#3] -- register_copy 
    // [800] phi flash_smc::smc_bytes_flashed#12 = flash_smc::smc_bytes_flashed#1 [phi:flash_smc::@57->flash_smc::@17#4] -- register_copy 
    // [800] phi flash_smc::smc_attempts_flashed#19 = flash_smc::smc_attempts_flashed#19 [phi:flash_smc::@57->flash_smc::@17#5] -- register_copy 
    // [800] phi flash_smc::smc_package_committed#2 = 1 [phi:flash_smc::@57->flash_smc::@17#6] -- vbum1=vbuc1 
    lda #1
    sta smc_package_committed
    jmp __b17
    // flash_smc::@20
  __b20:
    // unsigned char smc_byte_upload = *smc_ram_ptr
    // [861] flash_smc::smc_byte_upload#0 = *flash_smc::smc_ram_ptr#12 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (smc_ram_ptr),y
    sta smc_byte_upload
    // smc_ram_ptr++;
    // [862] flash_smc::smc_ram_ptr#0 = ++ flash_smc::smc_ram_ptr#12 -- pbuz1=_inc_pbuz1 
    inc.z smc_ram_ptr
    bne !+
    inc.z smc_ram_ptr+1
  !:
    // smc_bytes_checksum += smc_byte_upload
    // [863] flash_smc::smc_bytes_checksum#1 = flash_smc::smc_bytes_checksum#2 + flash_smc::smc_byte_upload#0 -- vbuz1=vbuz1_plus_vbum2 
    lda smc_byte_upload
    clc
    adc.z smc_bytes_checksum
    sta.z smc_bytes_checksum
    // unsigned char smc_upload_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, smc_byte_upload)
    // [864] flash_smc::cx16_k_i2c_write_byte4_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte4_device
    // [865] flash_smc::cx16_k_i2c_write_byte4_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte4_offset
    // [866] flash_smc::cx16_k_i2c_write_byte4_value = flash_smc::smc_byte_upload#0 -- vbum1=vbum2 
    lda smc_byte_upload
    sta cx16_k_i2c_write_byte4_value
    // flash_smc::cx16_k_i2c_write_byte4
    // unsigned char result
    // [867] flash_smc::cx16_k_i2c_write_byte4_result = 0 -- vbum1=vbuc1 
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
    // [869] flash_smc::smc_package_flashed#1 = ++ flash_smc::smc_package_flashed#2 -- vwuz1=_inc_vwuz1 
    inc.z smc_package_flashed
    bne !+
    inc.z smc_package_flashed+1
  !:
    // [814] phi from flash_smc::@28 to flash_smc::@19 [phi:flash_smc::@28->flash_smc::@19]
    // [814] phi flash_smc::smc_bytes_checksum#2 = flash_smc::smc_bytes_checksum#1 [phi:flash_smc::@28->flash_smc::@19#0] -- register_copy 
    // [814] phi flash_smc::smc_ram_ptr#12 = flash_smc::smc_ram_ptr#0 [phi:flash_smc::@28->flash_smc::@19#1] -- register_copy 
    // [814] phi flash_smc::smc_package_flashed#2 = flash_smc::smc_package_flashed#1 [phi:flash_smc::@28->flash_smc::@19#2] -- register_copy 
    jmp __b19
    // [870] phi from flash_smc::@9 to flash_smc::@11 [phi:flash_smc::@9->flash_smc::@11]
  __b13:
    // [870] phi flash_smc::x2#2 = $10000*1 [phi:flash_smc::@9->flash_smc::@11#0] -- vduz1=vduc1 
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
    // [871] if(flash_smc::x2#2>0) goto flash_smc::@12 -- vduz1_gt_0_then_la1 
    lda.z x2+3
    bne __b12
    lda.z x2+2
    bne __b12
    lda.z x2+1
    bne __b12
    lda.z x2
    bne __b12
  !:
    // [872] phi from flash_smc::@11 to flash_smc::@13 [phi:flash_smc::@11->flash_smc::@13]
    // flash_smc::@13
    // sprintf(info_text, "Waiting an other %u seconds before flashing the SMC!", smc_bootloader_activation_countdown)
    // [873] call snprintf_init
    jsr snprintf_init
    // [874] phi from flash_smc::@13 to flash_smc::@40 [phi:flash_smc::@13->flash_smc::@40]
    // flash_smc::@40
    // sprintf(info_text, "Waiting an other %u seconds before flashing the SMC!", smc_bootloader_activation_countdown)
    // [875] call printf_str
    // [531] phi from flash_smc::@40 to printf_str [phi:flash_smc::@40->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:flash_smc::@40->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = flash_smc::s3 [phi:flash_smc::@40->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@41
    // sprintf(info_text, "Waiting an other %u seconds before flashing the SMC!", smc_bootloader_activation_countdown)
    // [876] printf_uchar::uvalue#3 = flash_smc::smc_bootloader_activation_countdown#23 -- vbuz1=vbuz2 
    lda.z smc_bootloader_activation_countdown_1
    sta.z printf_uchar.uvalue
    // [877] call printf_uchar
    // [913] phi from flash_smc::@41 to printf_uchar [phi:flash_smc::@41->printf_uchar]
    // [913] phi printf_uchar::format_zero_padding#10 = 0 [phi:flash_smc::@41->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [913] phi printf_uchar::format_min_length#10 = 0 [phi:flash_smc::@41->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [913] phi printf_uchar::putc#10 = &snputc [phi:flash_smc::@41->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [913] phi printf_uchar::format_radix#10 = DECIMAL [phi:flash_smc::@41->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [913] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#3 [phi:flash_smc::@41->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [878] phi from flash_smc::@41 to flash_smc::@42 [phi:flash_smc::@41->flash_smc::@42]
    // flash_smc::@42
    // sprintf(info_text, "Waiting an other %u seconds before flashing the SMC!", smc_bootloader_activation_countdown)
    // [879] call printf_str
    // [531] phi from flash_smc::@42 to printf_str [phi:flash_smc::@42->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:flash_smc::@42->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = flash_smc::s4 [phi:flash_smc::@42->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@43
    // sprintf(info_text, "Waiting an other %u seconds before flashing the SMC!", smc_bootloader_activation_countdown)
    // [880] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [881] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [883] call info_line
    // [730] phi from flash_smc::@43 to info_line [phi:flash_smc::@43->info_line]
    // [730] phi info_line::info_text#18 = info_text [phi:flash_smc::@43->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    // flash_smc::@44
    // smc_bootloader_activation_countdown--;
    // [884] flash_smc::smc_bootloader_activation_countdown#3 = -- flash_smc::smc_bootloader_activation_countdown#23 -- vbuz1=_dec_vbuz1 
    dec.z smc_bootloader_activation_countdown_1
    // [771] phi from flash_smc::@44 to flash_smc::@9 [phi:flash_smc::@44->flash_smc::@9]
    // [771] phi flash_smc::smc_bootloader_activation_countdown#23 = flash_smc::smc_bootloader_activation_countdown#3 [phi:flash_smc::@44->flash_smc::@9#0] -- register_copy 
    jmp __b9
    // flash_smc::@12
  __b12:
    // for(unsigned long x=65536*1; x>0; x--)
    // [885] flash_smc::x2#1 = -- flash_smc::x2#2 -- vduz1=_dec_vduz1 
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
    // [870] phi from flash_smc::@12 to flash_smc::@11 [phi:flash_smc::@12->flash_smc::@11]
    // [870] phi flash_smc::x2#2 = flash_smc::x2#1 [phi:flash_smc::@12->flash_smc::@11#0] -- register_copy 
    jmp __b11
    // flash_smc::@4
  __b4:
    // unsigned int smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [886] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [887] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [888] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [889] cx16_k_i2c_read_byte::return#2 = cx16_k_i2c_read_byte::return#1
    // flash_smc::@34
    // [890] flash_smc::smc_bootloader_not_activated1#0 = cx16_k_i2c_read_byte::return#2
    // if(smc_bootloader_not_activated)
    // [891] if(0!=flash_smc::smc_bootloader_not_activated1#0) goto flash_smc::@6 -- 0_neq_vwuz1_then_la1 
    lda.z smc_bootloader_not_activated1
    ora.z smc_bootloader_not_activated1+1
    bne __b14
    jmp __b5
    // [892] phi from flash_smc::@34 to flash_smc::@6 [phi:flash_smc::@34->flash_smc::@6]
  __b14:
    // [892] phi flash_smc::x1#2 = $10000*6 [phi:flash_smc::@34->flash_smc::@6#0] -- vdum1=vduc1 
    lda #<$10000*6
    sta x1
    lda #>$10000*6
    sta x1+1
    lda #<$10000*6>>$10
    sta x1+2
    lda #>$10000*6>>$10
    sta x1+3
    // flash_smc::@6
  __b6:
    // for(unsigned long x=65536*6; x>0; x--)
    // [893] if(flash_smc::x1#2>0) goto flash_smc::@7 -- vdum1_gt_0_then_la1 
    lda x1+3
    bne __b7
    lda x1+2
    bne __b7
    lda x1+1
    bne __b7
    lda x1
    bne __b7
  !:
    // [894] phi from flash_smc::@6 to flash_smc::@8 [phi:flash_smc::@6->flash_smc::@8]
    // flash_smc::@8
    // sprintf(info_text, "Press POWER and RESET on the CX16 within %u seconds!", smc_bootloader_activation_countdown)
    // [895] call snprintf_init
    jsr snprintf_init
    // [896] phi from flash_smc::@8 to flash_smc::@35 [phi:flash_smc::@8->flash_smc::@35]
    // flash_smc::@35
    // sprintf(info_text, "Press POWER and RESET on the CX16 within %u seconds!", smc_bootloader_activation_countdown)
    // [897] call printf_str
    // [531] phi from flash_smc::@35 to printf_str [phi:flash_smc::@35->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:flash_smc::@35->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = flash_smc::s1 [phi:flash_smc::@35->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@36
    // sprintf(info_text, "Press POWER and RESET on the CX16 within %u seconds!", smc_bootloader_activation_countdown)
    // [898] printf_uchar::uvalue#2 = flash_smc::smc_bootloader_activation_countdown#22 -- vbuz1=vbuz2 
    lda.z smc_bootloader_activation_countdown
    sta.z printf_uchar.uvalue
    // [899] call printf_uchar
    // [913] phi from flash_smc::@36 to printf_uchar [phi:flash_smc::@36->printf_uchar]
    // [913] phi printf_uchar::format_zero_padding#10 = 0 [phi:flash_smc::@36->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [913] phi printf_uchar::format_min_length#10 = 0 [phi:flash_smc::@36->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [913] phi printf_uchar::putc#10 = &snputc [phi:flash_smc::@36->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [913] phi printf_uchar::format_radix#10 = DECIMAL [phi:flash_smc::@36->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [913] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#2 [phi:flash_smc::@36->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [900] phi from flash_smc::@36 to flash_smc::@37 [phi:flash_smc::@36->flash_smc::@37]
    // flash_smc::@37
    // sprintf(info_text, "Press POWER and RESET on the CX16 within %u seconds!", smc_bootloader_activation_countdown)
    // [901] call printf_str
    // [531] phi from flash_smc::@37 to printf_str [phi:flash_smc::@37->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:flash_smc::@37->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = flash_smc::s2 [phi:flash_smc::@37->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@38
    // sprintf(info_text, "Press POWER and RESET on the CX16 within %u seconds!", smc_bootloader_activation_countdown)
    // [902] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [903] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [905] call info_line
    // [730] phi from flash_smc::@38 to info_line [phi:flash_smc::@38->info_line]
    // [730] phi info_line::info_text#18 = info_text [phi:flash_smc::@38->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    // flash_smc::@5
    // smc_bootloader_activation_countdown--;
    // [906] flash_smc::smc_bootloader_activation_countdown#2 = -- flash_smc::smc_bootloader_activation_countdown#22 -- vbuz1=_dec_vbuz1 
    dec.z smc_bootloader_activation_countdown
    // [769] phi from flash_smc::@5 to flash_smc::@3 [phi:flash_smc::@5->flash_smc::@3]
    // [769] phi flash_smc::smc_bootloader_activation_countdown#22 = flash_smc::smc_bootloader_activation_countdown#2 [phi:flash_smc::@5->flash_smc::@3#0] -- register_copy 
    jmp __b3
    // flash_smc::@7
  __b7:
    // for(unsigned long x=65536*6; x>0; x--)
    // [907] flash_smc::x1#1 = -- flash_smc::x1#2 -- vdum1=_dec_vdum1 
    lda x1
    sec
    sbc #1
    sta x1
    lda x1+1
    sbc #0
    sta x1+1
    lda x1+2
    sbc #0
    sta x1+2
    lda x1+3
    sbc #0
    sta x1+3
    // [892] phi from flash_smc::@7 to flash_smc::@6 [phi:flash_smc::@7->flash_smc::@6]
    // [892] phi flash_smc::x1#2 = flash_smc::x1#1 [phi:flash_smc::@7->flash_smc::@6#0] -- register_copy 
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
    .label x1 = rom_flash.return
    smc_byte_upload: .byte 0
    .label smc_bytes_flashed = fopen.pathtoken_1
    .label smc_attempts_total = fgets.stream
    .label smc_package_committed = wait_key.bank_get_brom1_return
}
.segment Code
  // system_reset
system_reset: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    // system_reset::bank_set_bram1
    // BRAM = bank
    // [909] BRAM = system_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // system_reset::bank_set_brom1
    // BROM = bank
    // [910] BROM = system_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // system_reset::@1
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // system_reset::@return
    // }
    // [912] return 
}
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(__zp($60) void (*putc)(char), __zp($36) char uvalue, __zp($ea) char format_min_length, char format_justify_left, char format_sign_always, __zp($e9) char format_zero_padding, char format_upper_case, __zp($e5) char format_radix)
printf_uchar: {
    .label uvalue = $36
    .label format_radix = $e5
    .label putc = $60
    .label format_min_length = $ea
    .label format_zero_padding = $e9
    // printf_uchar::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [914] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [915] uctoa::value#1 = printf_uchar::uvalue#10
    // [916] uctoa::radix#0 = printf_uchar::format_radix#10
    // [917] call uctoa
    // Format number into buffer
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [918] printf_number_buffer::putc#2 = printf_uchar::putc#10
    // [919] printf_number_buffer::buffer_sign#2 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [920] printf_number_buffer::format_min_length#2 = printf_uchar::format_min_length#10
    // [921] printf_number_buffer::format_zero_padding#2 = printf_uchar::format_zero_padding#10
    // [922] call printf_number_buffer
  // Print using format
    // [1534] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [1534] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#2 [phi:printf_uchar::@2->printf_number_buffer#0] -- register_copy 
    // [1534] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#2 [phi:printf_uchar::@2->printf_number_buffer#1] -- register_copy 
    // [1534] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#2 [phi:printf_uchar::@2->printf_number_buffer#2] -- register_copy 
    // [1534] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#2 [phi:printf_uchar::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [923] return 
    rts
}
  // strcpy
// Copies the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcpy(char *destination, char *source)
strcpy: {
    .label src = $57
    .label dst = $c3
    // [925] phi from strcpy strcpy::@2 to strcpy::@1 [phi:strcpy/strcpy::@2->strcpy::@1]
    // [925] phi strcpy::dst#2 = strcpy::dst#0 [phi:strcpy/strcpy::@2->strcpy::@1#0] -- register_copy 
    // [925] phi strcpy::src#2 = strcpy::src#0 [phi:strcpy/strcpy::@2->strcpy::@1#1] -- register_copy 
    // strcpy::@1
  __b1:
    // while(*src)
    // [926] if(0!=*strcpy::src#2) goto strcpy::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcpy::@3
    // *dst = 0
    // [927] *strcpy::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcpy::@return
    // }
    // [928] return 
    rts
    // strcpy::@2
  __b2:
    // *dst++ = *src++
    // [929] *strcpy::dst#2 = *strcpy::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [930] strcpy::dst#1 = ++ strcpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [931] strcpy::src#1 = ++ strcpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    jmp __b1
}
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(__zp($41) void (*putc)(char), __zp($c0) char *str, __zp($d7) char format_min_length, __zp($e4) char format_justify_left)
printf_string: {
    .label printf_string__9 = $ab
    .label len = $e7
    .label padding = $d7
    .label str = $c0
    .label format_min_length = $d7
    .label format_justify_left = $e4
    .label putc = $41
    // if(format.min_length)
    // [933] if(0==printf_string::format_min_length#14) goto printf_string::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b3
    // printf_string::@3
    // strlen(str)
    // [934] strlen::str#3 = printf_string::str#14 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [935] call strlen
    // [1790] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [1790] phi strlen::str#8 = strlen::str#3 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [936] strlen::return#10 = strlen::len#2
    // printf_string::@6
    // [937] printf_string::$9 = strlen::return#10
    // signed char len = (signed char)strlen(str)
    // [938] printf_string::len#0 = (signed char)printf_string::$9 -- vbsz1=_sbyte_vwuz2 
    lda.z printf_string__9
    sta.z len
    // padding = (signed char)format.min_length  - len
    // [939] printf_string::padding#1 = (signed char)printf_string::format_min_length#14 - printf_string::len#0 -- vbsz1=vbsz1_minus_vbsz2 
    lda.z padding
    sec
    sbc.z len
    sta.z padding
    // if(padding<0)
    // [940] if(printf_string::padding#1>=0) goto printf_string::@10 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [942] phi from printf_string printf_string::@6 to printf_string::@1 [phi:printf_string/printf_string::@6->printf_string::@1]
  __b3:
    // [942] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@6->printf_string::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [941] phi from printf_string::@6 to printf_string::@10 [phi:printf_string::@6->printf_string::@10]
    // printf_string::@10
    // [942] phi from printf_string::@10 to printf_string::@1 [phi:printf_string::@10->printf_string::@1]
    // [942] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@10->printf_string::@1#0] -- register_copy 
    // printf_string::@1
  __b1:
    // if(!format.justify_left && padding)
    // [943] if(0!=printf_string::format_justify_left#14) goto printf_string::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_justify_left
    bne __b2
    // printf_string::@8
    // [944] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b4
    jmp __b2
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [945] printf_padding::putc#3 = printf_string::putc#14 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [946] printf_padding::length#3 = (char)printf_string::padding#3 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [947] call printf_padding
    // [1796] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [1796] phi printf_padding::putc#7 = printf_padding::putc#3 [phi:printf_string::@4->printf_padding#0] -- register_copy 
    // [1796] phi printf_padding::pad#7 = ' ' [phi:printf_string::@4->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1796] phi printf_padding::length#6 = printf_padding::length#3 [phi:printf_string::@4->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [948] printf_str::putc#1 = printf_string::putc#14 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_str.putc
    lda.z putc+1
    sta.z printf_str.putc+1
    // [949] printf_str::s#2 = printf_string::str#14
    // [950] call printf_str
    // [531] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [531] phi printf_str::putc#53 = printf_str::putc#1 [phi:printf_string::@2->printf_str#0] -- register_copy 
    // [531] phi printf_str::s#53 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@7
    // if(format.justify_left && padding)
    // [951] if(0==printf_string::format_justify_left#14) goto printf_string::@return -- 0_eq_vbuz1_then_la1 
    lda.z format_justify_left
    beq __breturn
    // printf_string::@9
    // [952] if(0!=printf_string::padding#3) goto printf_string::@5 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b5
    rts
    // printf_string::@5
  __b5:
    // printf_padding(putc, ' ',(char)padding)
    // [953] printf_padding::putc#4 = printf_string::putc#14 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [954] printf_padding::length#4 = (char)printf_string::padding#3 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [955] call printf_padding
    // [1796] phi from printf_string::@5 to printf_padding [phi:printf_string::@5->printf_padding]
    // [1796] phi printf_padding::putc#7 = printf_padding::putc#4 [phi:printf_string::@5->printf_padding#0] -- register_copy 
    // [1796] phi printf_padding::pad#7 = ' ' [phi:printf_string::@5->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1796] phi printf_padding::length#6 = printf_padding::length#4 [phi:printf_string::@5->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@return
  __breturn:
    // }
    // [956] return 
    rts
}
  // rom_read
// __mem() unsigned long rom_read(__mem() char rom_bank_start, __mem() unsigned long rom_size)
rom_read: {
    .const x = 2
    .label rom_read__5 = $ed
    .label rom_address = $37
    .label rom_package_read = $59
    .label ram_address = $41
    /// Holds the amount of bytes actually read in the memory to be flashed.
    .label rom_row_current = $e0
    .label y = $e4
    .label bram_bank = $d7
    // gotoxy(x, y)
    // [958] call gotoxy
    // [392] phi from rom_read to gotoxy [phi:rom_read->gotoxy]
    // [392] phi gotoxy::y#26 = $21 [phi:rom_read->gotoxy#0] -- vbuz1=vbuc1 
    lda #$21
    sta.z gotoxy.y
    // [392] phi gotoxy::x#26 = rom_read::x [phi:rom_read->gotoxy#1] -- vbuz1=vbuc1 
    lda #x
    sta.z gotoxy.x
    jsr gotoxy
    // rom_read::@13
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [959] rom_address_from_bank::rom_bank#0 = rom_read::rom_bank_start#11 -- vbuz1=vbum2 
    lda rom_bank_start
    sta.z rom_address_from_bank.rom_bank
    // [960] call rom_address_from_bank
    // [1804] phi from rom_read::@13 to rom_address_from_bank [phi:rom_read::@13->rom_address_from_bank]
    // [1804] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#0 [phi:rom_read::@13->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [961] rom_address_from_bank::return#2 = rom_address_from_bank::return#0
    // rom_read::@14
    // [962] rom_read::rom_address#0 = rom_address_from_bank::return#2
    // FILE *fp = fopen(file, "r")
    // [963] call fopen
    // [1589] phi from rom_read::@14 to fopen [phi:rom_read::@14->fopen]
    // [1589] phi __errno#257 = __errno#35 [phi:rom_read::@14->fopen#0] -- register_copy 
    // [1589] phi fopen::pathtoken#0 = file [phi:rom_read::@14->fopen#1] -- pbuz1=pbuc1 
    lda #<file
    sta.z fopen.pathtoken
    lda #>file
    sta.z fopen.pathtoken+1
    jsr fopen
    // FILE *fp = fopen(file, "r")
    // [964] fopen::return#4 = fopen::return#2
    // rom_read::@15
    // [965] rom_read::fp#0 = fopen::return#4 -- pssm1=pssz2 
    lda.z fopen.return
    sta fp
    lda.z fopen.return+1
    sta fp+1
    // if (fp)
    // [966] if((struct $2 *)0==rom_read::fp#0) goto rom_read::@1 -- pssc1_eq_pssm1_then_la1 
    lda fp
    cmp #<0
    bne !+
    lda fp+1
    cmp #>0
    beq __b9
  !:
    // [967] phi from rom_read::@15 to rom_read::@2 [phi:rom_read::@15->rom_read::@2]
    // [967] phi rom_read::y#10 = $21 [phi:rom_read::@15->rom_read::@2#0] -- vbuz1=vbuc1 
    lda #$21
    sta.z y
    // [967] phi rom_read::rom_row_current#10 = 0 [phi:rom_read::@15->rom_read::@2#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z rom_row_current
    sta.z rom_row_current+1
    // [967] phi rom_read::ram_address#10 = (char *)$6000 [phi:rom_read::@15->rom_read::@2#2] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z ram_address
    lda #>$6000
    sta.z ram_address+1
    // [967] phi rom_read::rom_bank_start#4 = rom_read::rom_bank_start#11 [phi:rom_read::@15->rom_read::@2#3] -- register_copy 
    // [967] phi rom_read::bram_bank#10 = 0 [phi:rom_read::@15->rom_read::@2#4] -- vbuz1=vbuc1 
    lda #0
    sta.z bram_bank
    // [967] phi rom_read::rom_address#10 = rom_read::rom_address#0 [phi:rom_read::@15->rom_read::@2#5] -- register_copy 
    // [967] phi rom_read::rom_file_read#10 = 0 [phi:rom_read::@15->rom_read::@2#6] -- vdum1=vduc1 
    sta rom_file_read
    sta rom_file_read+1
    lda #<0>>$10
    sta rom_file_read+2
    lda #>0>>$10
    sta rom_file_read+3
    // rom_read::@2
  __b2:
    // while (rom_file_read < rom_size)
    // [968] if(rom_read::rom_file_read#10<rom_read::rom_size#12) goto rom_read::@3 -- vdum1_lt_vdum2_then_la1 
    lda rom_file_read+3
    cmp rom_size+3
    bcc __b3
    bne !+
    lda rom_file_read+2
    cmp rom_size+2
    bcc __b3
    bne !+
    lda rom_file_read+1
    cmp rom_size+1
    bcc __b3
    bne !+
    lda rom_file_read
    cmp rom_size
    bcc __b3
  !:
    // rom_read::@6
  __b6:
    // fclose(fp)
    // [969] fclose::stream#1 = rom_read::fp#0 -- pssz1=pssm2 
    lda fp
    sta.z fclose.stream
    lda fp+1
    sta.z fclose.stream+1
    // [970] call fclose
    // [1724] phi from rom_read::@6 to fclose [phi:rom_read::@6->fclose]
    // [1724] phi fclose::stream#2 = fclose::stream#1 [phi:rom_read::@6->fclose#0] -- register_copy 
    jsr fclose
    // [971] phi from rom_read::@6 to rom_read::@1 [phi:rom_read::@6->rom_read::@1]
    // [971] phi rom_read::return#0 = rom_read::rom_file_read#10 [phi:rom_read::@6->rom_read::@1#0] -- register_copy 
    rts
    // [971] phi from rom_read::@15 to rom_read::@1 [phi:rom_read::@15->rom_read::@1]
  __b9:
    // [971] phi rom_read::return#0 = 0 [phi:rom_read::@15->rom_read::@1#0] -- vdum1=vduc1 
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
    // [972] return 
    rts
    // rom_read::@3
  __b3:
    // rom_address % 0x04000
    // [973] rom_read::$5 = rom_read::rom_address#10 & $4000-1 -- vduz1=vduz2_band_vduc1 
    lda.z rom_address
    and #<$4000-1
    sta.z rom_read__5
    lda.z rom_address+1
    and #>$4000-1
    sta.z rom_read__5+1
    lda.z rom_address+2
    and #<$4000-1>>$10
    sta.z rom_read__5+2
    lda.z rom_address+3
    and #>$4000-1>>$10
    sta.z rom_read__5+3
    // if (!(rom_address % 0x04000))
    // [974] if(0!=rom_read::$5) goto rom_read::@4 -- 0_neq_vduz1_then_la1 
    lda.z rom_read__5
    ora.z rom_read__5+1
    ora.z rom_read__5+2
    ora.z rom_read__5+3
    bne __b4
    // rom_read::@9
    // rom_bank_start++;
    // [975] rom_read::rom_bank_start#0 = ++ rom_read::rom_bank_start#4 -- vbum1=_inc_vbum1 
    inc rom_bank_start
    // [976] phi from rom_read::@3 rom_read::@9 to rom_read::@4 [phi:rom_read::@3/rom_read::@9->rom_read::@4]
    // [976] phi rom_read::rom_bank_start#10 = rom_read::rom_bank_start#4 [phi:rom_read::@3/rom_read::@9->rom_read::@4#0] -- register_copy 
    // rom_read::@4
  __b4:
    // rom_read::bank_set_bram1
    // BRAM = bank
    // [977] BRAM = rom_read::bram_bank#10 -- vbuz1=vbuz2 
    lda.z bram_bank
    sta.z BRAM
    // rom_read::@12
    // unsigned int rom_package_read = fgets(ram_address, PROGRESS_CELL, fp)
    // [978] fgets::ptr#3 = rom_read::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z fgets.ptr
    lda.z ram_address+1
    sta.z fgets.ptr+1
    // [979] fgets::stream#1 = rom_read::fp#0 -- pssm1=pssm2 
    lda fp
    sta fgets.stream
    lda fp+1
    sta fgets.stream+1
    // [980] call fgets
    // [1670] phi from rom_read::@12 to fgets [phi:rom_read::@12->fgets]
    // [1670] phi fgets::ptr#12 = fgets::ptr#3 [phi:rom_read::@12->fgets#0] -- register_copy 
    // [1670] phi fgets::size#10 = PROGRESS_CELL [phi:rom_read::@12->fgets#1] -- vwuz1=vwuc1 
    lda #<PROGRESS_CELL
    sta.z fgets.size
    lda #>PROGRESS_CELL
    sta.z fgets.size+1
    // [1670] phi fgets::stream#2 = fgets::stream#1 [phi:rom_read::@12->fgets#2] -- register_copy 
    jsr fgets
    // unsigned int rom_package_read = fgets(ram_address, PROGRESS_CELL, fp)
    // [981] fgets::return#6 = fgets::return#1
    // rom_read::@16
    // [982] rom_read::rom_package_read#0 = fgets::return#6 -- vwuz1=vwuz2 
    lda.z fgets.return
    sta.z rom_package_read
    lda.z fgets.return+1
    sta.z rom_package_read+1
    // if (!rom_package_read)
    // [983] if(0!=rom_read::rom_package_read#0) goto rom_read::@5 -- 0_neq_vwuz1_then_la1 
    lda.z rom_package_read
    ora.z rom_package_read+1
    bne __b5
    jmp __b6
    // rom_read::@5
  __b5:
    // if (rom_row_current == PROGRESS_ROW)
    // [984] if(rom_read::rom_row_current#10!=PROGRESS_ROW) goto rom_read::@7 -- vwuz1_neq_vwuc1_then_la1 
    lda.z rom_row_current+1
    cmp #>PROGRESS_ROW
    bne __b7
    lda.z rom_row_current
    cmp #<PROGRESS_ROW
    bne __b7
    // rom_read::@10
    // gotoxy(x, ++y);
    // [985] rom_read::y#1 = ++ rom_read::y#10 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [986] gotoxy::y#21 = rom_read::y#1 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [987] call gotoxy
    // [392] phi from rom_read::@10 to gotoxy [phi:rom_read::@10->gotoxy]
    // [392] phi gotoxy::y#26 = gotoxy::y#21 [phi:rom_read::@10->gotoxy#0] -- register_copy 
    // [392] phi gotoxy::x#26 = rom_read::x [phi:rom_read::@10->gotoxy#1] -- vbuz1=vbuc1 
    lda #x
    sta.z gotoxy.x
    jsr gotoxy
    // [988] phi from rom_read::@10 to rom_read::@7 [phi:rom_read::@10->rom_read::@7]
    // [988] phi rom_read::y#11 = rom_read::y#1 [phi:rom_read::@10->rom_read::@7#0] -- register_copy 
    // [988] phi rom_read::rom_row_current#4 = 0 [phi:rom_read::@10->rom_read::@7#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z rom_row_current
    sta.z rom_row_current+1
    // [988] phi from rom_read::@5 to rom_read::@7 [phi:rom_read::@5->rom_read::@7]
    // [988] phi rom_read::y#11 = rom_read::y#10 [phi:rom_read::@5->rom_read::@7#0] -- register_copy 
    // [988] phi rom_read::rom_row_current#4 = rom_read::rom_row_current#10 [phi:rom_read::@5->rom_read::@7#1] -- register_copy 
    // rom_read::@7
  __b7:
    // cputc('.')
    // [989] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [990] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // ram_address += rom_package_read
    // [992] rom_read::ram_address#1 = rom_read::ram_address#10 + rom_read::rom_package_read#0 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z ram_address
    adc.z rom_package_read
    sta.z ram_address
    lda.z ram_address+1
    adc.z rom_package_read+1
    sta.z ram_address+1
    // rom_address += rom_package_read
    // [993] rom_read::rom_address#1 = rom_read::rom_address#10 + rom_read::rom_package_read#0 -- vduz1=vduz1_plus_vwuz2 
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
    // rom_file_read += rom_package_read
    // [994] rom_read::rom_file_read#1 = rom_read::rom_file_read#10 + rom_read::rom_package_read#0 -- vdum1=vdum1_plus_vwuz2 
    lda rom_file_read
    clc
    adc.z rom_package_read
    sta rom_file_read
    lda rom_file_read+1
    adc.z rom_package_read+1
    sta rom_file_read+1
    lda rom_file_read+2
    adc #0
    sta rom_file_read+2
    lda rom_file_read+3
    adc #0
    sta rom_file_read+3
    // rom_row_current += rom_package_read
    // [995] rom_read::rom_row_current#1 = rom_read::rom_row_current#4 + rom_read::rom_package_read#0 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z rom_row_current
    adc.z rom_package_read
    sta.z rom_row_current
    lda.z rom_row_current+1
    adc.z rom_package_read+1
    sta.z rom_row_current+1
    // if (ram_address == (ram_ptr_t)BRAM_HIGH)
    // [996] if(rom_read::ram_address#1!=(char *)$c000) goto rom_read::@8 -- pbuz1_neq_pbuc1_then_la1 
    lda.z ram_address+1
    cmp #>$c000
    bne __b8
    lda.z ram_address
    cmp #<$c000
    bne __b8
    // rom_read::@11
    // bram_bank++;
    // [997] rom_read::bram_bank#1 = ++ rom_read::bram_bank#10 -- vbuz1=_inc_vbuz1 
    inc.z bram_bank
    // [998] phi from rom_read::@11 to rom_read::@8 [phi:rom_read::@11->rom_read::@8]
    // [998] phi rom_read::bram_bank#12 = rom_read::bram_bank#1 [phi:rom_read::@11->rom_read::@8#0] -- register_copy 
    // [998] phi rom_read::ram_address#6 = (char *)$a000 [phi:rom_read::@11->rom_read::@8#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [998] phi from rom_read::@7 to rom_read::@8 [phi:rom_read::@7->rom_read::@8]
    // [998] phi rom_read::bram_bank#12 = rom_read::bram_bank#10 [phi:rom_read::@7->rom_read::@8#0] -- register_copy 
    // [998] phi rom_read::ram_address#6 = rom_read::ram_address#1 [phi:rom_read::@7->rom_read::@8#1] -- register_copy 
    // rom_read::@8
  __b8:
    // if (ram_address == (ram_ptr_t)RAM_HIGH)
    // [999] if(rom_read::ram_address#6!=(char *)$8000) goto rom_read::@17 -- pbuz1_neq_pbuc1_then_la1 
    lda.z ram_address+1
    cmp #>$8000
    beq !__b2+
    jmp __b2
  !__b2:
    lda.z ram_address
    cmp #<$8000
    beq !__b2+
    jmp __b2
  !__b2:
    // [967] phi from rom_read::@8 to rom_read::@2 [phi:rom_read::@8->rom_read::@2]
    // [967] phi rom_read::y#10 = rom_read::y#11 [phi:rom_read::@8->rom_read::@2#0] -- register_copy 
    // [967] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#1 [phi:rom_read::@8->rom_read::@2#1] -- register_copy 
    // [967] phi rom_read::ram_address#10 = (char *)$a000 [phi:rom_read::@8->rom_read::@2#2] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [967] phi rom_read::rom_bank_start#4 = rom_read::rom_bank_start#10 [phi:rom_read::@8->rom_read::@2#3] -- register_copy 
    // [967] phi rom_read::bram_bank#10 = 1 [phi:rom_read::@8->rom_read::@2#4] -- vbuz1=vbuc1 
    lda #1
    sta.z bram_bank
    // [967] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@8->rom_read::@2#5] -- register_copy 
    // [967] phi rom_read::rom_file_read#10 = rom_read::rom_file_read#1 [phi:rom_read::@8->rom_read::@2#6] -- register_copy 
    jmp __b2
    // [1000] phi from rom_read::@8 to rom_read::@17 [phi:rom_read::@8->rom_read::@17]
    // rom_read::@17
    // [967] phi from rom_read::@17 to rom_read::@2 [phi:rom_read::@17->rom_read::@2]
    // [967] phi rom_read::y#10 = rom_read::y#11 [phi:rom_read::@17->rom_read::@2#0] -- register_copy 
    // [967] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#1 [phi:rom_read::@17->rom_read::@2#1] -- register_copy 
    // [967] phi rom_read::ram_address#10 = rom_read::ram_address#6 [phi:rom_read::@17->rom_read::@2#2] -- register_copy 
    // [967] phi rom_read::rom_bank_start#4 = rom_read::rom_bank_start#10 [phi:rom_read::@17->rom_read::@2#3] -- register_copy 
    // [967] phi rom_read::bram_bank#10 = rom_read::bram_bank#12 [phi:rom_read::@17->rom_read::@2#4] -- register_copy 
    // [967] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@17->rom_read::@2#5] -- register_copy 
    // [967] phi rom_read::rom_file_read#10 = rom_read::rom_file_read#1 [phi:rom_read::@17->rom_read::@2#6] -- register_copy 
  .segment Data
    fp: .word 0
    return: .dword 0
    rom_bank_start: .byte 0
    .label rom_file_read = return
    .label rom_size = rom_flash.return
}
.segment Code
  // info_rom
// void info_rom(__zp($df) char rom_chip, __zp($5b) char info_status, __zp($d1) char *info_text)
info_rom: {
    .label info_rom__4 = $5b
    .label info_rom__5 = $e7
    .label info_rom__7 = $e5
    .label rom_chip = $df
    .label info_status = $5b
    .label info_text = $d1
    // print_rom_led(rom_chip, status_color[info_status])
    // [1002] print_rom_led::chip#1 = info_rom::rom_chip#17 -- vbuz1=vbuz2 
    lda.z rom_chip
    sta.z print_rom_led.chip
    // [1003] print_rom_led::c#1 = status_color[info_rom::info_status#17] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z print_rom_led.c
    // [1004] call print_rom_led
    // [1581] phi from info_rom to print_rom_led [phi:info_rom->print_rom_led]
    // [1581] phi print_rom_led::c#2 = print_rom_led::c#1 [phi:info_rom->print_rom_led#0] -- register_copy 
    // [1581] phi print_rom_led::chip#2 = print_rom_led::chip#1 [phi:info_rom->print_rom_led#1] -- register_copy 
    jsr print_rom_led
    // info_rom::@1
    // info_clear(2+rom_chip)
    // [1005] info_clear::l#3 = 2 + info_rom::rom_chip#17 -- vbuz1=vbuc1_plus_vbuz2 
    lda #2
    clc
    adc.z rom_chip
    sta.z info_clear.l
    // [1006] call info_clear
    // [1440] phi from info_rom::@1 to info_clear [phi:info_rom::@1->info_clear]
    // [1440] phi info_clear::l#4 = info_clear::l#3 [phi:info_rom::@1->info_clear#0] -- register_copy 
    jsr info_clear
    // [1007] phi from info_rom::@1 to info_rom::@2 [phi:info_rom::@1->info_rom::@2]
    // info_rom::@2
    // printf("ROM%u - %-8s - %-6s - %05x / %05x - %s", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip], info_text )
    // [1008] call printf_str
    // [531] phi from info_rom::@2 to printf_str [phi:info_rom::@2->printf_str]
    // [531] phi printf_str::putc#53 = &cputc [phi:info_rom::@2->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = info_rom::s [phi:info_rom::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@3
    // printf("ROM%u - %-8s - %-6s - %05x / %05x - %s", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip], info_text )
    // [1009] printf_uchar::uvalue#0 = info_rom::rom_chip#17 -- vbuz1=vbuz2 
    lda.z rom_chip
    sta.z printf_uchar.uvalue
    // [1010] call printf_uchar
    // [913] phi from info_rom::@3 to printf_uchar [phi:info_rom::@3->printf_uchar]
    // [913] phi printf_uchar::format_zero_padding#10 = 0 [phi:info_rom::@3->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [913] phi printf_uchar::format_min_length#10 = 0 [phi:info_rom::@3->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [913] phi printf_uchar::putc#10 = &cputc [phi:info_rom::@3->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [913] phi printf_uchar::format_radix#10 = DECIMAL [phi:info_rom::@3->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [913] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#0 [phi:info_rom::@3->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1011] phi from info_rom::@3 to info_rom::@4 [phi:info_rom::@3->info_rom::@4]
    // info_rom::@4
    // printf("ROM%u - %-8s - %-6s - %05x / %05x - %s", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip], info_text )
    // [1012] call printf_str
    // [531] phi from info_rom::@4 to printf_str [phi:info_rom::@4->printf_str]
    // [531] phi printf_str::putc#53 = &cputc [phi:info_rom::@4->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = info_rom::s1 [phi:info_rom::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@5
    // printf("ROM%u - %-8s - %-6s - %05x / %05x - %s", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip], info_text )
    // [1013] info_rom::$4 = info_rom::info_status#17 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z info_rom__4
    // [1014] printf_string::str#7 = status_text[info_rom::$4] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z info_rom__4
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [1015] call printf_string
    // [932] phi from info_rom::@5 to printf_string [phi:info_rom::@5->printf_string]
    // [932] phi printf_string::putc#14 = &cputc [phi:info_rom::@5->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [932] phi printf_string::str#14 = printf_string::str#7 [phi:info_rom::@5->printf_string#1] -- register_copy 
    // [932] phi printf_string::format_justify_left#14 = 1 [phi:info_rom::@5->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [932] phi printf_string::format_min_length#14 = 8 [phi:info_rom::@5->printf_string#3] -- vbuz1=vbuc1 
    lda #8
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1016] phi from info_rom::@5 to info_rom::@6 [phi:info_rom::@5->info_rom::@6]
    // info_rom::@6
    // printf("ROM%u - %-8s - %-6s - %05x / %05x - %s", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip], info_text )
    // [1017] call printf_str
    // [531] phi from info_rom::@6 to printf_str [phi:info_rom::@6->printf_str]
    // [531] phi printf_str::putc#53 = &cputc [phi:info_rom::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = info_rom::s1 [phi:info_rom::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@7
    // printf("ROM%u - %-8s - %-6s - %05x / %05x - %s", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip], info_text )
    // [1018] info_rom::$5 = info_rom::rom_chip#17 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta.z info_rom__5
    // [1019] printf_string::str#8 = rom_device_names[info_rom::$5] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda rom_device_names,y
    sta.z printf_string.str
    lda rom_device_names+1,y
    sta.z printf_string.str+1
    // [1020] call printf_string
    // [932] phi from info_rom::@7 to printf_string [phi:info_rom::@7->printf_string]
    // [932] phi printf_string::putc#14 = &cputc [phi:info_rom::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [932] phi printf_string::str#14 = printf_string::str#8 [phi:info_rom::@7->printf_string#1] -- register_copy 
    // [932] phi printf_string::format_justify_left#14 = 1 [phi:info_rom::@7->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [932] phi printf_string::format_min_length#14 = 6 [phi:info_rom::@7->printf_string#3] -- vbuz1=vbuc1 
    lda #6
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1021] phi from info_rom::@7 to info_rom::@8 [phi:info_rom::@7->info_rom::@8]
    // info_rom::@8
    // printf("ROM%u - %-8s - %-6s - %05x / %05x - %s", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip], info_text )
    // [1022] call printf_str
    // [531] phi from info_rom::@8 to printf_str [phi:info_rom::@8->printf_str]
    // [531] phi printf_str::putc#53 = &cputc [phi:info_rom::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = info_rom::s1 [phi:info_rom::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@9
    // printf("ROM%u - %-8s - %-6s - %05x / %05x - %s", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip], info_text )
    // [1023] info_rom::$7 = info_rom::rom_chip#17 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta.z info_rom__7
    // [1024] printf_ulong::uvalue#0 = file_sizes[info_rom::$7] -- vduz1=pduc1_derefidx_vbuz2 
    tay
    lda file_sizes,y
    sta.z printf_ulong.uvalue
    lda file_sizes+1,y
    sta.z printf_ulong.uvalue+1
    lda file_sizes+2,y
    sta.z printf_ulong.uvalue+2
    lda file_sizes+3,y
    sta.z printf_ulong.uvalue+3
    // [1025] call printf_ulong
    // [1101] phi from info_rom::@9 to printf_ulong [phi:info_rom::@9->printf_ulong]
    // [1101] phi printf_ulong::putc#10 = &cputc [phi:info_rom::@9->printf_ulong#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_ulong.putc
    lda #>cputc
    sta.z printf_ulong.putc+1
    // [1101] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#0 [phi:info_rom::@9->printf_ulong#1] -- register_copy 
    jsr printf_ulong
    // [1026] phi from info_rom::@9 to info_rom::@10 [phi:info_rom::@9->info_rom::@10]
    // info_rom::@10
    // printf("ROM%u - %-8s - %-6s - %05x / %05x - %s", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip], info_text )
    // [1027] call printf_str
    // [531] phi from info_rom::@10 to printf_str [phi:info_rom::@10->printf_str]
    // [531] phi printf_str::putc#53 = &cputc [phi:info_rom::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = info_rom::s4 [phi:info_rom::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@11
    // printf("ROM%u - %-8s - %-6s - %05x / %05x - %s", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip], info_text )
    // [1028] printf_ulong::uvalue#1 = rom_sizes[info_rom::$7] -- vduz1=pduc1_derefidx_vbuz2 
    ldy.z info_rom__7
    lda rom_sizes,y
    sta.z printf_ulong.uvalue
    lda rom_sizes+1,y
    sta.z printf_ulong.uvalue+1
    lda rom_sizes+2,y
    sta.z printf_ulong.uvalue+2
    lda rom_sizes+3,y
    sta.z printf_ulong.uvalue+3
    // [1029] call printf_ulong
    // [1101] phi from info_rom::@11 to printf_ulong [phi:info_rom::@11->printf_ulong]
    // [1101] phi printf_ulong::putc#10 = &cputc [phi:info_rom::@11->printf_ulong#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_ulong.putc
    lda #>cputc
    sta.z printf_ulong.putc+1
    // [1101] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#1 [phi:info_rom::@11->printf_ulong#1] -- register_copy 
    jsr printf_ulong
    // [1030] phi from info_rom::@11 to info_rom::@12 [phi:info_rom::@11->info_rom::@12]
    // info_rom::@12
    // printf("ROM%u - %-8s - %-6s - %05x / %05x - %s", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip], info_text )
    // [1031] call printf_str
    // [531] phi from info_rom::@12 to printf_str [phi:info_rom::@12->printf_str]
    // [531] phi printf_str::putc#53 = &cputc [phi:info_rom::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = info_rom::s1 [phi:info_rom::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@13
    // printf("ROM%u - %-8s - %-6s - %05x / %05x - %s", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip], info_text )
    // [1032] printf_string::str#9 = info_rom::info_text#17 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1033] call printf_string
    // [932] phi from info_rom::@13 to printf_string [phi:info_rom::@13->printf_string]
    // [932] phi printf_string::putc#14 = &cputc [phi:info_rom::@13->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [932] phi printf_string::str#14 = printf_string::str#9 [phi:info_rom::@13->printf_string#1] -- register_copy 
    // [932] phi printf_string::format_justify_left#14 = 0 [phi:info_rom::@13->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [932] phi printf_string::format_min_length#14 = 0 [phi:info_rom::@13->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_rom::@return
    // }
    // [1034] return 
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
// __zp($73) unsigned long rom_verify(__mem() char rom_chip, __zp($bf) char rom_bank_start, __zp($4f) unsigned long file_size)
rom_verify: {
    .const x = 2
    .label rom_verify__18 = $69
    .label rom_address = $6b
    .label equal_bytes = $69
    .label y = $da
    .label ram_address = $7a
    .label bram_bank = $53
    .label rom_different_bytes = $73
    .label rom_bank_start = $bf
    .label file_size = $4f
    .label return = $73
    .label progress_row_current = $b8
    // info_progress("Comparing ... (.) same, (*) different.")
    // [1036] call info_progress
  // Now we compare the RAM with the actual ROM contents.
    // [506] phi from rom_verify to info_progress [phi:rom_verify->info_progress]
    // [506] phi info_progress::info_text#4 = rom_verify::info_text [phi:rom_verify->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_progress.info_text
    lda #>info_text
    sta.z info_progress.info_text+1
    jsr info_progress
    // rom_verify::@12
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [1037] rom_address_from_bank::rom_bank#1 = rom_verify::rom_bank_start#0
    // [1038] call rom_address_from_bank
    // [1804] phi from rom_verify::@12 to rom_address_from_bank [phi:rom_verify::@12->rom_address_from_bank]
    // [1804] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#1 [phi:rom_verify::@12->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [1039] rom_address_from_bank::return#3 = rom_address_from_bank::return#0 -- vduz1=vduz2 
    lda.z rom_address_from_bank.return
    sta.z rom_address_from_bank.return_1
    lda.z rom_address_from_bank.return+1
    sta.z rom_address_from_bank.return_1+1
    lda.z rom_address_from_bank.return+2
    sta.z rom_address_from_bank.return_1+2
    lda.z rom_address_from_bank.return+3
    sta.z rom_address_from_bank.return_1+3
    // rom_verify::@13
    // [1040] rom_verify::rom_address#0 = rom_address_from_bank::return#3
    // unsigned long rom_boundary = rom_address + file_size
    // [1041] rom_verify::rom_boundary#0 = rom_verify::rom_address#0 + rom_verify::file_size#0 -- vdum1=vduz2_plus_vduz3 
    lda.z rom_address
    clc
    adc.z file_size
    sta rom_boundary
    lda.z rom_address+1
    adc.z file_size+1
    sta rom_boundary+1
    lda.z rom_address+2
    adc.z file_size+2
    sta rom_boundary+2
    lda.z rom_address+3
    adc.z file_size+3
    sta rom_boundary+3
    // info_rom(rom_chip, STATUS_EQUATING, "Comparing ...")
    // [1042] info_rom::rom_chip#0 = rom_verify::rom_chip#0 -- vbuz1=vbum2 
    lda rom_chip
    sta.z info_rom.rom_chip
    // [1043] call info_rom
    // [1001] phi from rom_verify::@13 to info_rom [phi:rom_verify::@13->info_rom]
    // [1001] phi info_rom::info_text#17 = rom_verify::info_text1 [phi:rom_verify::@13->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z info_rom.info_text
    lda #>info_text1
    sta.z info_rom.info_text+1
    // [1001] phi info_rom::info_status#17 = 4 [phi:rom_verify::@13->info_rom#1] -- vbuz1=vbuc1 
    lda #4
    sta.z info_rom.info_status
    // [1001] phi info_rom::rom_chip#17 = info_rom::rom_chip#0 [phi:rom_verify::@13->info_rom#2] -- register_copy 
    jsr info_rom
    // [1044] phi from rom_verify::@13 to rom_verify::@14 [phi:rom_verify::@13->rom_verify::@14]
    // rom_verify::@14
    // gotoxy(x, y)
    // [1045] call gotoxy
    // [392] phi from rom_verify::@14 to gotoxy [phi:rom_verify::@14->gotoxy]
    // [392] phi gotoxy::y#26 = $21 [phi:rom_verify::@14->gotoxy#0] -- vbuz1=vbuc1 
    lda #$21
    sta.z gotoxy.y
    // [392] phi gotoxy::x#26 = rom_verify::x [phi:rom_verify::@14->gotoxy#1] -- vbuz1=vbuc1 
    lda #x
    sta.z gotoxy.x
    jsr gotoxy
    // [1046] phi from rom_verify::@14 to rom_verify::@1 [phi:rom_verify::@14->rom_verify::@1]
    // [1046] phi rom_verify::y#3 = $21 [phi:rom_verify::@14->rom_verify::@1#0] -- vbuz1=vbuc1 
    lda #$21
    sta.z y
    // [1046] phi rom_verify::rom_different_bytes#10 = 0 [phi:rom_verify::@14->rom_verify::@1#1] -- vduz1=vduc1 
    lda #<0
    sta.z rom_different_bytes
    sta.z rom_different_bytes+1
    lda #<0>>$10
    sta.z rom_different_bytes+2
    lda #>0>>$10
    sta.z rom_different_bytes+3
    // [1046] phi rom_verify::progress_row_current#3 = 0 [phi:rom_verify::@14->rom_verify::@1#2] -- vwuz1=vwuc1 
    lda #<0
    sta.z progress_row_current
    sta.z progress_row_current+1
    // [1046] phi rom_verify::ram_address#10 = (char *)$6000 [phi:rom_verify::@14->rom_verify::@1#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z ram_address
    lda #>$6000
    sta.z ram_address+1
    // [1046] phi rom_verify::bram_bank#11 = 0 [phi:rom_verify::@14->rom_verify::@1#4] -- vbuz1=vbuc1 
    lda #0
    sta.z bram_bank
    // [1046] phi rom_verify::rom_address#12 = rom_verify::rom_address#0 [phi:rom_verify::@14->rom_verify::@1#5] -- register_copy 
    // rom_verify::@1
  __b1:
    // while (rom_address < rom_boundary)
    // [1047] if(rom_verify::rom_address#12<rom_verify::rom_boundary#0) goto rom_verify::@2 -- vduz1_lt_vdum2_then_la1 
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
    // rom_verify::@3
    // info_rom(rom_chip, STATUS_EQUATED, "Compared.")
    // [1048] info_rom::rom_chip#1 = rom_verify::rom_chip#0 -- vbuz1=vbum2 
    lda rom_chip
    sta.z info_rom.rom_chip
    // [1049] call info_rom
    // [1001] phi from rom_verify::@3 to info_rom [phi:rom_verify::@3->info_rom]
    // [1001] phi info_rom::info_text#17 = rom_verify::info_text2 [phi:rom_verify::@3->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z info_rom.info_text
    lda #>info_text2
    sta.z info_rom.info_text+1
    // [1001] phi info_rom::info_status#17 = 5 [phi:rom_verify::@3->info_rom#1] -- vbuz1=vbuc1 
    lda #5
    sta.z info_rom.info_status
    // [1001] phi info_rom::rom_chip#17 = info_rom::rom_chip#1 [phi:rom_verify::@3->info_rom#2] -- register_copy 
    jsr info_rom
    // rom_verify::@return
    // }
    // [1050] return 
    rts
    // rom_verify::@2
  __b2:
    // unsigned int equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1051] rom_compare::bank_ram#0 = rom_verify::bram_bank#11 -- vbuz1=vbuz2 
    lda.z bram_bank
    sta.z rom_compare.bank_ram
    // [1052] rom_compare::ptr_ram#1 = rom_verify::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_compare.ptr_ram
    lda.z ram_address+1
    sta.z rom_compare.ptr_ram+1
    // [1053] rom_compare::rom_compare_address#0 = rom_verify::rom_address#12 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_compare.rom_compare_address
    lda.z rom_address+1
    sta.z rom_compare.rom_compare_address+1
    lda.z rom_address+2
    sta.z rom_compare.rom_compare_address+2
    lda.z rom_address+3
    sta.z rom_compare.rom_compare_address+3
    // [1054] call rom_compare
  // {asm{.byte $db}}
    // [1808] phi from rom_verify::@2 to rom_compare [phi:rom_verify::@2->rom_compare]
    // [1808] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#1 [phi:rom_verify::@2->rom_compare#0] -- register_copy 
    // [1808] phi rom_compare::rom_compare_size#11 = PROGRESS_CELL [phi:rom_verify::@2->rom_compare#1] -- vwuz1=vwuc1 
    lda #<PROGRESS_CELL
    sta.z rom_compare.rom_compare_size
    lda #>PROGRESS_CELL
    sta.z rom_compare.rom_compare_size+1
    // [1808] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#0 [phi:rom_verify::@2->rom_compare#2] -- register_copy 
    // [1808] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#0 [phi:rom_verify::@2->rom_compare#3] -- register_copy 
    jsr rom_compare
    // unsigned int equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1055] rom_compare::return#2 = rom_compare::equal_bytes#2
    // rom_verify::@15
    // [1056] rom_verify::equal_bytes#0 = rom_compare::return#2
    // if (progress_row_current == PROGRESS_ROW)
    // [1057] if(rom_verify::progress_row_current#3!=PROGRESS_ROW) goto rom_verify::@4 -- vwuz1_neq_vwuc1_then_la1 
    lda.z progress_row_current+1
    cmp #>PROGRESS_ROW
    bne __b4
    lda.z progress_row_current
    cmp #<PROGRESS_ROW
    bne __b4
    // rom_verify::@9
    // gotoxy(x, ++y);
    // [1058] rom_verify::y#1 = ++ rom_verify::y#3 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [1059] gotoxy::y#23 = rom_verify::y#1 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1060] call gotoxy
    // [392] phi from rom_verify::@9 to gotoxy [phi:rom_verify::@9->gotoxy]
    // [392] phi gotoxy::y#26 = gotoxy::y#23 [phi:rom_verify::@9->gotoxy#0] -- register_copy 
    // [392] phi gotoxy::x#26 = rom_verify::x [phi:rom_verify::@9->gotoxy#1] -- vbuz1=vbuc1 
    lda #x
    sta.z gotoxy.x
    jsr gotoxy
    // [1061] phi from rom_verify::@9 to rom_verify::@4 [phi:rom_verify::@9->rom_verify::@4]
    // [1061] phi rom_verify::y#10 = rom_verify::y#1 [phi:rom_verify::@9->rom_verify::@4#0] -- register_copy 
    // [1061] phi rom_verify::progress_row_current#4 = 0 [phi:rom_verify::@9->rom_verify::@4#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z progress_row_current
    sta.z progress_row_current+1
    // [1061] phi from rom_verify::@15 to rom_verify::@4 [phi:rom_verify::@15->rom_verify::@4]
    // [1061] phi rom_verify::y#10 = rom_verify::y#3 [phi:rom_verify::@15->rom_verify::@4#0] -- register_copy 
    // [1061] phi rom_verify::progress_row_current#4 = rom_verify::progress_row_current#3 [phi:rom_verify::@15->rom_verify::@4#1] -- register_copy 
    // rom_verify::@4
  __b4:
    // if (equal_bytes != PROGRESS_CELL)
    // [1062] if(rom_verify::equal_bytes#0!=PROGRESS_CELL) goto rom_verify::@5 -- vwuz1_neq_vwuc1_then_la1 
    lda.z equal_bytes+1
    cmp #>PROGRESS_CELL
    beq !__b5+
    jmp __b5
  !__b5:
    lda.z equal_bytes
    cmp #<PROGRESS_CELL
    beq !__b5+
    jmp __b5
  !__b5:
    // rom_verify::@10
    // cputc('=')
    // [1063] stackpush(char) = '=' -- _stackpushbyte_=vbuc1 
    lda #'='
    pha
    // [1064] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_verify::@6
  __b6:
    // ram_address += PROGRESS_CELL
    // [1066] rom_verify::ram_address#1 = rom_verify::ram_address#10 + PROGRESS_CELL -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address
    clc
    adc #<PROGRESS_CELL
    sta.z ram_address
    lda.z ram_address+1
    adc #>PROGRESS_CELL
    sta.z ram_address+1
    // rom_address += PROGRESS_CELL
    // [1067] rom_verify::rom_address#1 = rom_verify::rom_address#12 + PROGRESS_CELL -- vduz1=vduz1_plus_vwuc1 
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
    // [1068] rom_verify::progress_row_current#11 = rom_verify::progress_row_current#4 + PROGRESS_CELL -- vwuz1=vwuz1_plus_vwuc1 
    lda.z progress_row_current
    clc
    adc #<PROGRESS_CELL
    sta.z progress_row_current
    lda.z progress_row_current+1
    adc #>PROGRESS_CELL
    sta.z progress_row_current+1
    // if (ram_address == BRAM_HIGH)
    // [1069] if(rom_verify::ram_address#1!=$c000) goto rom_verify::@7 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address+1
    cmp #>$c000
    bne __b7
    lda.z ram_address
    cmp #<$c000
    bne __b7
    // rom_verify::@11
    // bram_bank++;
    // [1070] rom_verify::bram_bank#1 = ++ rom_verify::bram_bank#11 -- vbuz1=_inc_vbuz1 
    inc.z bram_bank
    // [1071] phi from rom_verify::@11 to rom_verify::@7 [phi:rom_verify::@11->rom_verify::@7]
    // [1071] phi rom_verify::bram_bank#25 = rom_verify::bram_bank#1 [phi:rom_verify::@11->rom_verify::@7#0] -- register_copy 
    // [1071] phi rom_verify::ram_address#6 = (char *)$a000 [phi:rom_verify::@11->rom_verify::@7#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1071] phi from rom_verify::@6 to rom_verify::@7 [phi:rom_verify::@6->rom_verify::@7]
    // [1071] phi rom_verify::bram_bank#25 = rom_verify::bram_bank#11 [phi:rom_verify::@6->rom_verify::@7#0] -- register_copy 
    // [1071] phi rom_verify::ram_address#6 = rom_verify::ram_address#1 [phi:rom_verify::@6->rom_verify::@7#1] -- register_copy 
    // rom_verify::@7
  __b7:
    // if (ram_address == RAM_HIGH)
    // [1072] if(rom_verify::ram_address#6!=$8000) goto rom_verify::@25 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address+1
    cmp #>$8000
    bne __b8
    lda.z ram_address
    cmp #<$8000
    bne __b8
    // [1074] phi from rom_verify::@7 to rom_verify::@8 [phi:rom_verify::@7->rom_verify::@8]
    // [1074] phi rom_verify::ram_address#11 = (char *)$a000 [phi:rom_verify::@7->rom_verify::@8#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1074] phi rom_verify::bram_bank#10 = 1 [phi:rom_verify::@7->rom_verify::@8#1] -- vbuz1=vbuc1 
    lda #1
    sta.z bram_bank
    // [1073] phi from rom_verify::@7 to rom_verify::@25 [phi:rom_verify::@7->rom_verify::@25]
    // rom_verify::@25
    // [1074] phi from rom_verify::@25 to rom_verify::@8 [phi:rom_verify::@25->rom_verify::@8]
    // [1074] phi rom_verify::ram_address#11 = rom_verify::ram_address#6 [phi:rom_verify::@25->rom_verify::@8#0] -- register_copy 
    // [1074] phi rom_verify::bram_bank#10 = rom_verify::bram_bank#25 [phi:rom_verify::@25->rom_verify::@8#1] -- register_copy 
    // rom_verify::@8
  __b8:
    // PROGRESS_CELL - equal_bytes
    // [1075] rom_verify::$18 = PROGRESS_CELL - rom_verify::equal_bytes#0 -- vwuz1=vwuc1_minus_vwuz1 
    lda #<PROGRESS_CELL
    sec
    sbc.z rom_verify__18
    sta.z rom_verify__18
    lda #>PROGRESS_CELL
    sbc.z rom_verify__18+1
    sta.z rom_verify__18+1
    // rom_different_bytes += (PROGRESS_CELL - equal_bytes)
    // [1076] rom_verify::rom_different_bytes#1 = rom_verify::rom_different_bytes#10 + rom_verify::$18 -- vduz1=vduz1_plus_vwuz2 
    lda.z rom_different_bytes
    clc
    adc.z rom_verify__18
    sta.z rom_different_bytes
    lda.z rom_different_bytes+1
    adc.z rom_verify__18+1
    sta.z rom_different_bytes+1
    lda.z rom_different_bytes+2
    adc #0
    sta.z rom_different_bytes+2
    lda.z rom_different_bytes+3
    adc #0
    sta.z rom_different_bytes+3
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1077] call snprintf_init
    jsr snprintf_init
    // [1078] phi from rom_verify::@8 to rom_verify::@16 [phi:rom_verify::@8->rom_verify::@16]
    // rom_verify::@16
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1079] call printf_str
    // [531] phi from rom_verify::@16 to printf_str [phi:rom_verify::@16->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:rom_verify::@16->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = rom_verify::s [phi:rom_verify::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@17
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1080] printf_ulong::uvalue#2 = rom_verify::rom_different_bytes#1 -- vduz1=vduz2 
    lda.z rom_different_bytes
    sta.z printf_ulong.uvalue
    lda.z rom_different_bytes+1
    sta.z printf_ulong.uvalue+1
    lda.z rom_different_bytes+2
    sta.z printf_ulong.uvalue+2
    lda.z rom_different_bytes+3
    sta.z printf_ulong.uvalue+3
    // [1081] call printf_ulong
    // [1101] phi from rom_verify::@17 to printf_ulong [phi:rom_verify::@17->printf_ulong]
    // [1101] phi printf_ulong::putc#10 = &snputc [phi:rom_verify::@17->printf_ulong#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1101] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#2 [phi:rom_verify::@17->printf_ulong#1] -- register_copy 
    jsr printf_ulong
    // [1082] phi from rom_verify::@17 to rom_verify::@18 [phi:rom_verify::@17->rom_verify::@18]
    // rom_verify::@18
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1083] call printf_str
    // [531] phi from rom_verify::@18 to printf_str [phi:rom_verify::@18->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:rom_verify::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = rom_verify::s1 [phi:rom_verify::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@19
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1084] printf_uchar::uvalue#5 = rom_verify::bram_bank#10 -- vbuz1=vbuz2 
    lda.z bram_bank
    sta.z printf_uchar.uvalue
    // [1085] call printf_uchar
    // [913] phi from rom_verify::@19 to printf_uchar [phi:rom_verify::@19->printf_uchar]
    // [913] phi printf_uchar::format_zero_padding#10 = 1 [phi:rom_verify::@19->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [913] phi printf_uchar::format_min_length#10 = 2 [phi:rom_verify::@19->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [913] phi printf_uchar::putc#10 = &snputc [phi:rom_verify::@19->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [913] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:rom_verify::@19->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [913] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#5 [phi:rom_verify::@19->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1086] phi from rom_verify::@19 to rom_verify::@20 [phi:rom_verify::@19->rom_verify::@20]
    // rom_verify::@20
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1087] call printf_str
    // [531] phi from rom_verify::@20 to printf_str [phi:rom_verify::@20->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:rom_verify::@20->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = s2 [phi:rom_verify::@20->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@21
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1088] printf_uint::uvalue#6 = (unsigned int)rom_verify::ram_address#11 -- vwuz1=vwuz2 
    lda.z ram_address
    sta.z printf_uint.uvalue
    lda.z ram_address+1
    sta.z printf_uint.uvalue+1
    // [1089] call printf_uint
    // [540] phi from rom_verify::@21 to printf_uint [phi:rom_verify::@21->printf_uint]
    // [540] phi printf_uint::format_zero_padding#12 = 1 [phi:rom_verify::@21->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [540] phi printf_uint::format_min_length#12 = 4 [phi:rom_verify::@21->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [540] phi printf_uint::putc#12 = &snputc [phi:rom_verify::@21->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [540] phi printf_uint::format_radix#12 = HEXADECIMAL [phi:rom_verify::@21->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [540] phi printf_uint::uvalue#12 = printf_uint::uvalue#6 [phi:rom_verify::@21->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1090] phi from rom_verify::@21 to rom_verify::@22 [phi:rom_verify::@21->rom_verify::@22]
    // rom_verify::@22
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1091] call printf_str
    // [531] phi from rom_verify::@22 to printf_str [phi:rom_verify::@22->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:rom_verify::@22->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = rom_verify::s3 [phi:rom_verify::@22->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@23
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1092] printf_ulong::uvalue#3 = rom_verify::rom_address#1 -- vduz1=vduz2 
    lda.z rom_address
    sta.z printf_ulong.uvalue
    lda.z rom_address+1
    sta.z printf_ulong.uvalue+1
    lda.z rom_address+2
    sta.z printf_ulong.uvalue+2
    lda.z rom_address+3
    sta.z printf_ulong.uvalue+3
    // [1093] call printf_ulong
    // [1101] phi from rom_verify::@23 to printf_ulong [phi:rom_verify::@23->printf_ulong]
    // [1101] phi printf_ulong::putc#10 = &snputc [phi:rom_verify::@23->printf_ulong#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1101] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#3 [phi:rom_verify::@23->printf_ulong#1] -- register_copy 
    jsr printf_ulong
    // rom_verify::@24
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1094] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1095] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [1097] call info_line
    // [730] phi from rom_verify::@24 to info_line [phi:rom_verify::@24->info_line]
    // [730] phi info_line::info_text#18 = info_text [phi:rom_verify::@24->info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_line.info_text
    lda #>@info_text
    sta.z info_line.info_text+1
    jsr info_line
    // [1046] phi from rom_verify::@24 to rom_verify::@1 [phi:rom_verify::@24->rom_verify::@1]
    // [1046] phi rom_verify::y#3 = rom_verify::y#10 [phi:rom_verify::@24->rom_verify::@1#0] -- register_copy 
    // [1046] phi rom_verify::rom_different_bytes#10 = rom_verify::rom_different_bytes#1 [phi:rom_verify::@24->rom_verify::@1#1] -- register_copy 
    // [1046] phi rom_verify::progress_row_current#3 = rom_verify::progress_row_current#11 [phi:rom_verify::@24->rom_verify::@1#2] -- register_copy 
    // [1046] phi rom_verify::ram_address#10 = rom_verify::ram_address#11 [phi:rom_verify::@24->rom_verify::@1#3] -- register_copy 
    // [1046] phi rom_verify::bram_bank#11 = rom_verify::bram_bank#10 [phi:rom_verify::@24->rom_verify::@1#4] -- register_copy 
    // [1046] phi rom_verify::rom_address#12 = rom_verify::rom_address#1 [phi:rom_verify::@24->rom_verify::@1#5] -- register_copy 
    jmp __b1
    // rom_verify::@5
  __b5:
    // cputc('*')
    // [1098] stackpush(char) = '*' -- _stackpushbyte_=vbuc1 
    lda #'*'
    pha
    // [1099] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b6
  .segment Data
    info_text: .text "Comparing ... (.) same, (*) different."
    .byte 0
    info_text1: .text "Comparing ..."
    .byte 0
    info_text2: .text "Compared."
    .byte 0
    s: .text "Comparing: "
    .byte 0
    s1: .text " differences between RAM:"
    .byte 0
    s3: .text " <-> ROM:"
    .byte 0
    .label rom_boundary = rom_flash.rom_flash__26
    .label rom_chip = main.main__76
}
.segment Code
  // printf_ulong
// Print an unsigned int using a specific format
// void printf_ulong(__zp($60) void (*putc)(char), __zp($37) unsigned long uvalue, char format_min_length, char format_justify_left, char format_sign_always, char format_zero_padding, char format_upper_case, char format_radix)
printf_ulong: {
    .label uvalue = $37
    .label putc = $60
    // printf_ulong::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1102] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // ultoa(uvalue, printf_buffer.digits, format.radix)
    // [1103] ultoa::value#1 = printf_ulong::uvalue#10
    // [1104] call ultoa
  // Format number into buffer
    // [1834] phi from printf_ulong::@1 to ultoa [phi:printf_ulong::@1->ultoa]
    jsr ultoa
    // printf_ulong::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1105] printf_number_buffer::putc#0 = printf_ulong::putc#10
    // [1106] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [1107] call printf_number_buffer
  // Print using format
    // [1534] phi from printf_ulong::@2 to printf_number_buffer [phi:printf_ulong::@2->printf_number_buffer]
    // [1534] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#0 [phi:printf_ulong::@2->printf_number_buffer#0] -- register_copy 
    // [1534] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_ulong::@2->printf_number_buffer#1] -- register_copy 
    // [1534] phi printf_number_buffer::format_zero_padding#10 = 1 [phi:printf_ulong::@2->printf_number_buffer#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_number_buffer.format_zero_padding
    // [1534] phi printf_number_buffer::format_min_length#3 = 5 [phi:printf_ulong::@2->printf_number_buffer#3] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_number_buffer.format_min_length
    jsr printf_number_buffer
    // printf_ulong::@return
    // }
    // [1108] return 
    rts
}
  // rom_flash
// __mem() unsigned long rom_flash(__mem() char rom_chip, __mem() char rom_bank_start, __mem() unsigned long file_size)
rom_flash: {
    .label equal_bytes = $69
    .label ram_address_sector = $67
    .label equal_bytes_1 = $f8
    .label flash_errors_sector = $e8
    .label ram_address = $f1
    .label rom_address = $ed
    .label x = $e6
    .label flash_errors = $b4
    .label x_sector = $fa
    // info_progress("Flashing ROM ... (-) same, (+) flashed, (!) error.")
    // [1110] call info_progress
  // Now we compare the RAM with the actual ROM contents.
    // [506] phi from rom_flash to info_progress [phi:rom_flash->info_progress]
    // [506] phi info_progress::info_text#4 = rom_flash::info_text [phi:rom_flash->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_progress.info_text
    lda #>info_text
    sta.z info_progress.info_text+1
    jsr info_progress
    // rom_flash::@19
    // unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start)
    // [1111] rom_address_from_bank::rom_bank#2 = rom_flash::rom_bank_start#0 -- vbuz1=vbum2 
    lda rom_bank_start
    sta.z rom_address_from_bank.rom_bank
    // [1112] call rom_address_from_bank
    // [1804] phi from rom_flash::@19 to rom_address_from_bank [phi:rom_flash::@19->rom_address_from_bank]
    // [1804] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#2 [phi:rom_flash::@19->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start)
    // [1113] rom_address_from_bank::return#4 = rom_address_from_bank::return#0 -- vdum1=vduz2 
    lda.z rom_address_from_bank.return
    sta rom_address_from_bank.return_2
    lda.z rom_address_from_bank.return+1
    sta rom_address_from_bank.return_2+1
    lda.z rom_address_from_bank.return+2
    sta rom_address_from_bank.return_2+2
    lda.z rom_address_from_bank.return+3
    sta rom_address_from_bank.return_2+3
    // rom_flash::@20
    // [1114] rom_flash::rom_address_sector#0 = rom_address_from_bank::return#4
    // unsigned long rom_boundary = rom_address_sector + file_size
    // [1115] rom_flash::rom_boundary#0 = rom_flash::rom_address_sector#0 + rom_flash::file_size#0 -- vdum1=vdum2_plus_vdum3 
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
    // [1116] info_rom::rom_chip#2 = rom_flash::rom_chip#0 -- vbuz1=vbum2 
    lda rom_chip
    sta.z info_rom.rom_chip
    // [1117] call info_rom
    // [1001] phi from rom_flash::@20 to info_rom [phi:rom_flash::@20->info_rom]
    // [1001] phi info_rom::info_text#17 = rom_flash::info_text1 [phi:rom_flash::@20->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z info_rom.info_text
    lda #>info_text1
    sta.z info_rom.info_text+1
    // [1001] phi info_rom::info_status#17 = 6 [phi:rom_flash::@20->info_rom#1] -- vbuz1=vbuc1 
    lda #6
    sta.z info_rom.info_status
    // [1001] phi info_rom::rom_chip#17 = info_rom::rom_chip#2 [phi:rom_flash::@20->info_rom#2] -- register_copy 
    jsr info_rom
    // [1118] phi from rom_flash::@20 to rom_flash::@1 [phi:rom_flash::@20->rom_flash::@1]
    // [1118] phi rom_flash::y_sector#13 = $21 [phi:rom_flash::@20->rom_flash::@1#0] -- vbum1=vbuc1 
    lda #$21
    sta y_sector
    // [1118] phi rom_flash::x_sector#10 = 2 [phi:rom_flash::@20->rom_flash::@1#1] -- vbuz1=vbuc1 
    lda #2
    sta.z x_sector
    // [1118] phi rom_flash::flash_errors#2 = 0 [phi:rom_flash::@20->rom_flash::@1#2] -- vwuz1=vwuc1 
    lda #<0
    sta.z flash_errors
    sta.z flash_errors+1
    // [1118] phi rom_flash::ram_address_sector#11 = (char *)$6000 [phi:rom_flash::@20->rom_flash::@1#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z ram_address_sector
    lda #>$6000
    sta.z ram_address_sector+1
    // [1118] phi rom_flash::bram_bank_sector#14 = 0 [phi:rom_flash::@20->rom_flash::@1#4] -- vbum1=vbuc1 
    lda #0
    sta bram_bank_sector
    // [1118] phi rom_flash::rom_address_sector#12 = rom_flash::rom_address_sector#0 [phi:rom_flash::@20->rom_flash::@1#5] -- register_copy 
    // rom_flash::@1
  __b1:
    // while (rom_address_sector < rom_boundary)
    // [1119] if(rom_flash::rom_address_sector#12<rom_flash::rom_boundary#0) goto rom_flash::@2 -- vdum1_lt_vdum2_then_la1 
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
    // [1120] phi from rom_flash::@1 to rom_flash::@3 [phi:rom_flash::@1->rom_flash::@3]
    // rom_flash::@3
    // info_line("Flashed ...")
    // [1121] call info_line
    // [730] phi from rom_flash::@3 to info_line [phi:rom_flash::@3->info_line]
    // [730] phi info_line::info_text#18 = rom_flash::info_text2 [phi:rom_flash::@3->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z info_line.info_text
    lda #>info_text2
    sta.z info_line.info_text+1
    jsr info_line
    // rom_flash::@return
    // }
    // [1122] return 
    rts
    // rom_flash::@2
  __b2:
    // unsigned int equal_bytes = rom_compare(bram_bank_sector, (ram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR)
    // [1123] rom_compare::bank_ram#1 = rom_flash::bram_bank_sector#14 -- vbuz1=vbum2 
    lda bram_bank_sector
    sta.z rom_compare.bank_ram
    // [1124] rom_compare::ptr_ram#2 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z rom_compare.ptr_ram
    lda.z ram_address_sector+1
    sta.z rom_compare.ptr_ram+1
    // [1125] rom_compare::rom_compare_address#1 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_compare.rom_compare_address
    lda rom_address_sector+1
    sta.z rom_compare.rom_compare_address+1
    lda rom_address_sector+2
    sta.z rom_compare.rom_compare_address+2
    lda rom_address_sector+3
    sta.z rom_compare.rom_compare_address+3
    // [1126] call rom_compare
  // {asm{.byte $db}}
    // [1808] phi from rom_flash::@2 to rom_compare [phi:rom_flash::@2->rom_compare]
    // [1808] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#2 [phi:rom_flash::@2->rom_compare#0] -- register_copy 
    // [1808] phi rom_compare::rom_compare_size#11 = $1000 [phi:rom_flash::@2->rom_compare#1] -- vwuz1=vwuc1 
    lda #<$1000
    sta.z rom_compare.rom_compare_size
    lda #>$1000
    sta.z rom_compare.rom_compare_size+1
    // [1808] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#1 [phi:rom_flash::@2->rom_compare#2] -- register_copy 
    // [1808] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#1 [phi:rom_flash::@2->rom_compare#3] -- register_copy 
    jsr rom_compare
    // unsigned int equal_bytes = rom_compare(bram_bank_sector, (ram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR)
    // [1127] rom_compare::return#3 = rom_compare::equal_bytes#2
    // rom_flash::@21
    // [1128] rom_flash::equal_bytes#0 = rom_compare::return#3
    // if (equal_bytes != ROM_SECTOR)
    // [1129] if(rom_flash::equal_bytes#0!=$1000) goto rom_flash::@5 -- vwuz1_neq_vwuc1_then_la1 
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
    // [1130] cputsxy::x#1 = rom_flash::x_sector#10 -- vbuz1=vbuz2 
    lda.z x_sector
    sta.z cputsxy.x
    // [1131] cputsxy::y#1 = rom_flash::y_sector#13 -- vbuz1=vbum2 
    lda y_sector
    sta.z cputsxy.y
    // [1132] call cputsxy
    // [1425] phi from rom_flash::@16 to cputsxy [phi:rom_flash::@16->cputsxy]
    // [1425] phi cputsxy::s#2 = rom_flash::s [phi:rom_flash::@16->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [1425] phi cputsxy::y#2 = cputsxy::y#1 [phi:rom_flash::@16->cputsxy#1] -- register_copy 
    // [1425] phi cputsxy::x#2 = cputsxy::x#1 [phi:rom_flash::@16->cputsxy#2] -- register_copy 
    jsr cputsxy
    // [1133] phi from rom_flash::@12 rom_flash::@16 to rom_flash::@4 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4]
    // [1133] phi rom_flash::flash_errors#10 = rom_flash::flash_errors#1 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4#0] -- register_copy 
    // rom_flash::@4
  __b4:
    // ram_address_sector += ROM_SECTOR
    // [1134] rom_flash::ram_address_sector#1 = rom_flash::ram_address_sector#11 + $1000 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address_sector
    clc
    adc #<$1000
    sta.z ram_address_sector
    lda.z ram_address_sector+1
    adc #>$1000
    sta.z ram_address_sector+1
    // rom_address_sector += ROM_SECTOR
    // [1135] rom_flash::rom_address_sector#1 = rom_flash::rom_address_sector#12 + $1000 -- vdum1=vdum1_plus_vwuc1 
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
    // [1136] if(rom_flash::ram_address_sector#1!=$c000) goto rom_flash::@13 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address_sector+1
    cmp #>$c000
    bne __b13
    lda.z ram_address_sector
    cmp #<$c000
    bne __b13
    // rom_flash::@17
    // bram_bank_sector++;
    // [1137] rom_flash::bram_bank_sector#1 = ++ rom_flash::bram_bank_sector#14 -- vbum1=_inc_vbum1 
    inc bram_bank_sector
    // [1138] phi from rom_flash::@17 to rom_flash::@13 [phi:rom_flash::@17->rom_flash::@13]
    // [1138] phi rom_flash::bram_bank_sector#28 = rom_flash::bram_bank_sector#1 [phi:rom_flash::@17->rom_flash::@13#0] -- register_copy 
    // [1138] phi rom_flash::ram_address_sector#7 = (char *)$a000 [phi:rom_flash::@17->rom_flash::@13#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address_sector
    lda #>$a000
    sta.z ram_address_sector+1
    // [1138] phi from rom_flash::@4 to rom_flash::@13 [phi:rom_flash::@4->rom_flash::@13]
    // [1138] phi rom_flash::bram_bank_sector#28 = rom_flash::bram_bank_sector#14 [phi:rom_flash::@4->rom_flash::@13#0] -- register_copy 
    // [1138] phi rom_flash::ram_address_sector#7 = rom_flash::ram_address_sector#1 [phi:rom_flash::@4->rom_flash::@13#1] -- register_copy 
    // rom_flash::@13
  __b13:
    // if (ram_address_sector == RAM_HIGH)
    // [1139] if(rom_flash::ram_address_sector#7!=$8000) goto rom_flash::@42 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address_sector+1
    cmp #>$8000
    bne __b14
    lda.z ram_address_sector
    cmp #<$8000
    bne __b14
    // [1141] phi from rom_flash::@13 to rom_flash::@14 [phi:rom_flash::@13->rom_flash::@14]
    // [1141] phi rom_flash::ram_address_sector#13 = (char *)$a000 [phi:rom_flash::@13->rom_flash::@14#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address_sector
    lda #>$a000
    sta.z ram_address_sector+1
    // [1141] phi rom_flash::bram_bank_sector#10 = 1 [phi:rom_flash::@13->rom_flash::@14#1] -- vbum1=vbuc1 
    lda #1
    sta bram_bank_sector
    // [1140] phi from rom_flash::@13 to rom_flash::@42 [phi:rom_flash::@13->rom_flash::@42]
    // rom_flash::@42
    // [1141] phi from rom_flash::@42 to rom_flash::@14 [phi:rom_flash::@42->rom_flash::@14]
    // [1141] phi rom_flash::ram_address_sector#13 = rom_flash::ram_address_sector#7 [phi:rom_flash::@42->rom_flash::@14#0] -- register_copy 
    // [1141] phi rom_flash::bram_bank_sector#10 = rom_flash::bram_bank_sector#28 [phi:rom_flash::@42->rom_flash::@14#1] -- register_copy 
    // rom_flash::@14
  __b14:
    // x_sector += 8
    // [1142] rom_flash::x_sector#1 = rom_flash::x_sector#10 + 8 -- vbuz1=vbuz1_plus_vbuc1 
    lda #8
    clc
    adc.z x_sector
    sta.z x_sector
    // rom_address_sector % PROGRESS_ROW
    // [1143] rom_flash::$26 = rom_flash::rom_address_sector#1 & PROGRESS_ROW-1 -- vdum1=vdum2_band_vduc1 
    lda rom_address_sector
    and #<PROGRESS_ROW-1
    sta rom_flash__26
    lda rom_address_sector+1
    and #>PROGRESS_ROW-1
    sta rom_flash__26+1
    lda rom_address_sector+2
    and #<PROGRESS_ROW-1>>$10
    sta rom_flash__26+2
    lda rom_address_sector+3
    and #>PROGRESS_ROW-1>>$10
    sta rom_flash__26+3
    // if (!(rom_address_sector % PROGRESS_ROW))
    // [1144] if(0!=rom_flash::$26) goto rom_flash::@15 -- 0_neq_vdum1_then_la1 
    lda rom_flash__26
    ora rom_flash__26+1
    ora rom_flash__26+2
    ora rom_flash__26+3
    bne __b15
    // rom_flash::@18
    // y_sector++;
    // [1145] rom_flash::y_sector#1 = ++ rom_flash::y_sector#13 -- vbum1=_inc_vbum1 
    inc y_sector
    // [1146] phi from rom_flash::@18 to rom_flash::@15 [phi:rom_flash::@18->rom_flash::@15]
    // [1146] phi rom_flash::y_sector#18 = rom_flash::y_sector#1 [phi:rom_flash::@18->rom_flash::@15#0] -- register_copy 
    // [1146] phi rom_flash::x_sector#20 = 2 [phi:rom_flash::@18->rom_flash::@15#1] -- vbuz1=vbuc1 
    lda #2
    sta.z x_sector
    // [1146] phi from rom_flash::@14 to rom_flash::@15 [phi:rom_flash::@14->rom_flash::@15]
    // [1146] phi rom_flash::y_sector#18 = rom_flash::y_sector#13 [phi:rom_flash::@14->rom_flash::@15#0] -- register_copy 
    // [1146] phi rom_flash::x_sector#20 = rom_flash::x_sector#1 [phi:rom_flash::@14->rom_flash::@15#1] -- register_copy 
    // rom_flash::@15
  __b15:
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors)
    // [1147] call snprintf_init
    jsr snprintf_init
    // [1148] phi from rom_flash::@15 to rom_flash::@29 [phi:rom_flash::@15->rom_flash::@29]
    // rom_flash::@29
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors)
    // [1149] call printf_str
    // [531] phi from rom_flash::@29 to printf_str [phi:rom_flash::@29->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:rom_flash::@29->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = rom_flash::s2 [phi:rom_flash::@29->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@30
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors)
    // [1150] printf_uchar::uvalue#6 = rom_flash::bram_bank_sector#10 -- vbuz1=vbum2 
    lda bram_bank_sector
    sta.z printf_uchar.uvalue
    // [1151] call printf_uchar
    // [913] phi from rom_flash::@30 to printf_uchar [phi:rom_flash::@30->printf_uchar]
    // [913] phi printf_uchar::format_zero_padding#10 = 1 [phi:rom_flash::@30->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [913] phi printf_uchar::format_min_length#10 = 2 [phi:rom_flash::@30->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [913] phi printf_uchar::putc#10 = &snputc [phi:rom_flash::@30->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [913] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:rom_flash::@30->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [913] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#6 [phi:rom_flash::@30->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1152] phi from rom_flash::@30 to rom_flash::@31 [phi:rom_flash::@30->rom_flash::@31]
    // rom_flash::@31
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors)
    // [1153] call printf_str
    // [531] phi from rom_flash::@31 to printf_str [phi:rom_flash::@31->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:rom_flash::@31->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = s2 [phi:rom_flash::@31->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s2
    sta.z printf_str.s
    lda #>@s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@32
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors)
    // [1154] printf_uint::uvalue#7 = (unsigned int)rom_flash::ram_address_sector#13 -- vwuz1=vwuz2 
    lda.z ram_address_sector
    sta.z printf_uint.uvalue
    lda.z ram_address_sector+1
    sta.z printf_uint.uvalue+1
    // [1155] call printf_uint
    // [540] phi from rom_flash::@32 to printf_uint [phi:rom_flash::@32->printf_uint]
    // [540] phi printf_uint::format_zero_padding#12 = 1 [phi:rom_flash::@32->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [540] phi printf_uint::format_min_length#12 = 4 [phi:rom_flash::@32->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [540] phi printf_uint::putc#12 = &snputc [phi:rom_flash::@32->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [540] phi printf_uint::format_radix#12 = HEXADECIMAL [phi:rom_flash::@32->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [540] phi printf_uint::uvalue#12 = printf_uint::uvalue#7 [phi:rom_flash::@32->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1156] phi from rom_flash::@32 to rom_flash::@33 [phi:rom_flash::@32->rom_flash::@33]
    // rom_flash::@33
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors)
    // [1157] call printf_str
    // [531] phi from rom_flash::@33 to printf_str [phi:rom_flash::@33->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:rom_flash::@33->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = rom_flash::s4 [phi:rom_flash::@33->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@34
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors)
    // [1158] printf_ulong::uvalue#4 = rom_flash::rom_address_sector#1 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z printf_ulong.uvalue
    lda rom_address_sector+1
    sta.z printf_ulong.uvalue+1
    lda rom_address_sector+2
    sta.z printf_ulong.uvalue+2
    lda rom_address_sector+3
    sta.z printf_ulong.uvalue+3
    // [1159] call printf_ulong
    // [1101] phi from rom_flash::@34 to printf_ulong [phi:rom_flash::@34->printf_ulong]
    // [1101] phi printf_ulong::putc#10 = &snputc [phi:rom_flash::@34->printf_ulong#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1101] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#4 [phi:rom_flash::@34->printf_ulong#1] -- register_copy 
    jsr printf_ulong
    // [1160] phi from rom_flash::@34 to rom_flash::@35 [phi:rom_flash::@34->rom_flash::@35]
    // rom_flash::@35
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors)
    // [1161] call printf_str
    // [531] phi from rom_flash::@35 to printf_str [phi:rom_flash::@35->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:rom_flash::@35->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = s5 [phi:rom_flash::@35->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@36
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors)
    // [1162] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1163] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [1165] call info_line
    // [730] phi from rom_flash::@36 to info_line [phi:rom_flash::@36->info_line]
    // [730] phi info_line::info_text#18 = info_text [phi:rom_flash::@36->info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_line.info_text
    lda #>@info_text
    sta.z info_line.info_text+1
    jsr info_line
    // [1166] phi from rom_flash::@36 to rom_flash::@37 [phi:rom_flash::@36->rom_flash::@37]
    // rom_flash::@37
    // sprintf(info_text, "%05x errors ...", flash_errors)
    // [1167] call snprintf_init
    jsr snprintf_init
    // rom_flash::@38
    // [1168] printf_uint::uvalue#8 = rom_flash::flash_errors#10 -- vwuz1=vwuz2 
    lda.z flash_errors
    sta.z printf_uint.uvalue
    lda.z flash_errors+1
    sta.z printf_uint.uvalue+1
    // [1169] call printf_uint
    // [540] phi from rom_flash::@38 to printf_uint [phi:rom_flash::@38->printf_uint]
    // [540] phi printf_uint::format_zero_padding#12 = 1 [phi:rom_flash::@38->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [540] phi printf_uint::format_min_length#12 = 5 [phi:rom_flash::@38->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [540] phi printf_uint::putc#12 = &snputc [phi:rom_flash::@38->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [540] phi printf_uint::format_radix#12 = HEXADECIMAL [phi:rom_flash::@38->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [540] phi printf_uint::uvalue#12 = printf_uint::uvalue#8 [phi:rom_flash::@38->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1170] phi from rom_flash::@38 to rom_flash::@39 [phi:rom_flash::@38->rom_flash::@39]
    // rom_flash::@39
    // sprintf(info_text, "%05x errors ...", flash_errors)
    // [1171] call printf_str
    // [531] phi from rom_flash::@39 to printf_str [phi:rom_flash::@39->printf_str]
    // [531] phi printf_str::putc#53 = &snputc [phi:rom_flash::@39->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = rom_flash::s6 [phi:rom_flash::@39->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@40
    // sprintf(info_text, "%05x errors ...", flash_errors)
    // [1172] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1173] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom(rom_chip, STATUS_FLASHING, info_text)
    // [1175] info_rom::rom_chip#3 = rom_flash::rom_chip#0 -- vbuz1=vbum2 
    lda rom_chip
    sta.z info_rom.rom_chip
    // [1176] call info_rom
    // [1001] phi from rom_flash::@40 to info_rom [phi:rom_flash::@40->info_rom]
    // [1001] phi info_rom::info_text#17 = info_text [phi:rom_flash::@40->info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_rom.info_text
    lda #>@info_text
    sta.z info_rom.info_text+1
    // [1001] phi info_rom::info_status#17 = 6 [phi:rom_flash::@40->info_rom#1] -- vbuz1=vbuc1 
    lda #6
    sta.z info_rom.info_status
    // [1001] phi info_rom::rom_chip#17 = info_rom::rom_chip#3 [phi:rom_flash::@40->info_rom#2] -- register_copy 
    jsr info_rom
    // [1118] phi from rom_flash::@40 to rom_flash::@1 [phi:rom_flash::@40->rom_flash::@1]
    // [1118] phi rom_flash::y_sector#13 = rom_flash::y_sector#18 [phi:rom_flash::@40->rom_flash::@1#0] -- register_copy 
    // [1118] phi rom_flash::x_sector#10 = rom_flash::x_sector#20 [phi:rom_flash::@40->rom_flash::@1#1] -- register_copy 
    // [1118] phi rom_flash::flash_errors#2 = rom_flash::flash_errors#10 [phi:rom_flash::@40->rom_flash::@1#2] -- register_copy 
    // [1118] phi rom_flash::ram_address_sector#11 = rom_flash::ram_address_sector#13 [phi:rom_flash::@40->rom_flash::@1#3] -- register_copy 
    // [1118] phi rom_flash::bram_bank_sector#14 = rom_flash::bram_bank_sector#10 [phi:rom_flash::@40->rom_flash::@1#4] -- register_copy 
    // [1118] phi rom_flash::rom_address_sector#12 = rom_flash::rom_address_sector#1 [phi:rom_flash::@40->rom_flash::@1#5] -- register_copy 
    jmp __b1
    // [1177] phi from rom_flash::@21 to rom_flash::@5 [phi:rom_flash::@21->rom_flash::@5]
  __b3:
    // [1177] phi rom_flash::flash_errors_sector#10 = 0 [phi:rom_flash::@21->rom_flash::@5#0] -- vbuz1=vbuc1 
    lda #0
    sta.z flash_errors_sector
    // [1177] phi rom_flash::retries#12 = 0 [phi:rom_flash::@21->rom_flash::@5#1] -- vbum1=vbuc1 
    sta retries
    // [1177] phi from rom_flash::@41 to rom_flash::@5 [phi:rom_flash::@41->rom_flash::@5]
    // [1177] phi rom_flash::flash_errors_sector#10 = rom_flash::flash_errors_sector#11 [phi:rom_flash::@41->rom_flash::@5#0] -- register_copy 
    // [1177] phi rom_flash::retries#12 = rom_flash::retries#1 [phi:rom_flash::@41->rom_flash::@5#1] -- register_copy 
    // rom_flash::@5
  __b5:
    // rom_sector_erase(rom_address_sector)
    // [1178] rom_sector_erase::address#0 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_sector_erase.address
    lda rom_address_sector+1
    sta.z rom_sector_erase.address+1
    lda rom_address_sector+2
    sta.z rom_sector_erase.address+2
    lda rom_address_sector+3
    sta.z rom_sector_erase.address+3
    // [1179] call rom_sector_erase
    // [1855] phi from rom_flash::@5 to rom_sector_erase [phi:rom_flash::@5->rom_sector_erase]
    jsr rom_sector_erase
    // rom_flash::@22
    // unsigned long rom_sector_boundary = rom_address_sector + ROM_SECTOR
    // [1180] rom_flash::rom_sector_boundary#0 = rom_flash::rom_address_sector#12 + $1000 -- vdum1=vdum2_plus_vwuc1 
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
    // [1181] gotoxy::x#24 = rom_flash::x_sector#10 -- vbuz1=vbuz2 
    lda.z x_sector
    sta.z gotoxy.x
    // [1182] gotoxy::y#24 = rom_flash::y_sector#13 -- vbuz1=vbum2 
    lda y_sector
    sta.z gotoxy.y
    // [1183] call gotoxy
    // [392] phi from rom_flash::@22 to gotoxy [phi:rom_flash::@22->gotoxy]
    // [392] phi gotoxy::y#26 = gotoxy::y#24 [phi:rom_flash::@22->gotoxy#0] -- register_copy 
    // [392] phi gotoxy::x#26 = gotoxy::x#24 [phi:rom_flash::@22->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1184] phi from rom_flash::@22 to rom_flash::@23 [phi:rom_flash::@22->rom_flash::@23]
    // rom_flash::@23
    // printf("........")
    // [1185] call printf_str
    // [531] phi from rom_flash::@23 to printf_str [phi:rom_flash::@23->printf_str]
    // [531] phi printf_str::putc#53 = &cputc [phi:rom_flash::@23->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [531] phi printf_str::s#53 = rom_flash::s1 [phi:rom_flash::@23->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@24
    // [1186] rom_flash::rom_address#15 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_address
    lda rom_address_sector+1
    sta.z rom_address+1
    lda rom_address_sector+2
    sta.z rom_address+2
    lda rom_address_sector+3
    sta.z rom_address+3
    // [1187] rom_flash::ram_address#15 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z ram_address
    lda.z ram_address_sector+1
    sta.z ram_address+1
    // [1188] rom_flash::x#15 = rom_flash::x_sector#10 -- vbuz1=vbuz2 
    lda.z x_sector
    sta.z x
    // [1189] phi from rom_flash::@10 rom_flash::@24 to rom_flash::@6 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6]
    // [1189] phi rom_flash::x#10 = rom_flash::x#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#0] -- register_copy 
    // [1189] phi rom_flash::flash_errors_sector#11 = rom_flash::flash_errors_sector#7 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#1] -- register_copy 
    // [1189] phi rom_flash::ram_address#10 = rom_flash::ram_address#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#2] -- register_copy 
    // [1189] phi rom_flash::rom_address#10 = rom_flash::rom_address#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#3] -- register_copy 
    // rom_flash::@6
  __b6:
    // while (rom_address < rom_sector_boundary)
    // [1190] if(rom_flash::rom_address#10<rom_flash::rom_sector_boundary#0) goto rom_flash::@7 -- vduz1_lt_vdum2_then_la1 
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
    // [1191] rom_flash::retries#1 = ++ rom_flash::retries#12 -- vbum1=_inc_vbum1 
    inc retries
    // while (flash_errors_sector && retries <= 3)
    // [1192] if(0==rom_flash::flash_errors_sector#11) goto rom_flash::@12 -- 0_eq_vbuz1_then_la1 
    lda.z flash_errors_sector
    beq __b12
    // rom_flash::@41
    // [1193] if(rom_flash::retries#1<3+1) goto rom_flash::@5 -- vbum1_lt_vbuc1_then_la1 
    lda retries
    cmp #3+1
    bcs !__b5+
    jmp __b5
  !__b5:
    // rom_flash::@12
  __b12:
    // flash_errors += flash_errors_sector
    // [1194] rom_flash::flash_errors#1 = rom_flash::flash_errors#2 + rom_flash::flash_errors_sector#11 -- vwuz1=vwuz1_plus_vbuz2 
    lda.z flash_errors_sector
    clc
    adc.z flash_errors
    sta.z flash_errors
    bcc !+
    inc.z flash_errors+1
  !:
    jmp __b4
    // rom_flash::@7
  __b7:
    // unsigned long written_bytes = rom_write(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1195] rom_write::flash_ram_bank#0 = rom_flash::bram_bank_sector#14 -- vbuz1=vbum2 
    lda bram_bank_sector
    sta.z rom_write.flash_ram_bank
    // [1196] rom_write::flash_ram_address#1 = rom_flash::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_write.flash_ram_address
    lda.z ram_address+1
    sta.z rom_write.flash_ram_address+1
    // [1197] rom_write::flash_rom_address#1 = rom_flash::rom_address#10 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_write.flash_rom_address
    lda.z rom_address+1
    sta.z rom_write.flash_rom_address+1
    lda.z rom_address+2
    sta.z rom_write.flash_rom_address+2
    lda.z rom_address+3
    sta.z rom_write.flash_rom_address+3
    // [1198] call rom_write
    jsr rom_write
    // rom_flash::@25
    // rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1199] rom_compare::bank_ram#2 = rom_flash::bram_bank_sector#14 -- vbuz1=vbum2 
    lda bram_bank_sector
    sta.z rom_compare.bank_ram
    // [1200] rom_compare::ptr_ram#3 = rom_flash::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_compare.ptr_ram
    lda.z ram_address+1
    sta.z rom_compare.ptr_ram+1
    // [1201] rom_compare::rom_compare_address#2 = rom_flash::rom_address#10 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_compare.rom_compare_address
    lda.z rom_address+1
    sta.z rom_compare.rom_compare_address+1
    lda.z rom_address+2
    sta.z rom_compare.rom_compare_address+2
    lda.z rom_address+3
    sta.z rom_compare.rom_compare_address+3
    // [1202] call rom_compare
    // [1808] phi from rom_flash::@25 to rom_compare [phi:rom_flash::@25->rom_compare]
    // [1808] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#3 [phi:rom_flash::@25->rom_compare#0] -- register_copy 
    // [1808] phi rom_compare::rom_compare_size#11 = PROGRESS_CELL [phi:rom_flash::@25->rom_compare#1] -- vwuz1=vwuc1 
    lda #<PROGRESS_CELL
    sta.z rom_compare.rom_compare_size
    lda #>PROGRESS_CELL
    sta.z rom_compare.rom_compare_size+1
    // [1808] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#2 [phi:rom_flash::@25->rom_compare#2] -- register_copy 
    // [1808] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#2 [phi:rom_flash::@25->rom_compare#3] -- register_copy 
    jsr rom_compare
    // rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1203] rom_compare::return#4 = rom_compare::equal_bytes#2
    // rom_flash::@26
    // equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1204] rom_flash::equal_bytes#1 = rom_compare::return#4 -- vwuz1=vwuz2 
    lda.z rom_compare.return
    sta.z equal_bytes_1
    lda.z rom_compare.return+1
    sta.z equal_bytes_1+1
    // gotoxy(x, y)
    // [1205] gotoxy::x#25 = rom_flash::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1206] gotoxy::y#25 = rom_flash::y_sector#13 -- vbuz1=vbum2 
    lda y_sector
    sta.z gotoxy.y
    // [1207] call gotoxy
    // [392] phi from rom_flash::@26 to gotoxy [phi:rom_flash::@26->gotoxy]
    // [392] phi gotoxy::y#26 = gotoxy::y#25 [phi:rom_flash::@26->gotoxy#0] -- register_copy 
    // [392] phi gotoxy::x#26 = gotoxy::x#25 [phi:rom_flash::@26->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_flash::@27
    // if (equal_bytes != PROGRESS_CELL)
    // [1208] if(rom_flash::equal_bytes#1!=PROGRESS_CELL) goto rom_flash::@9 -- vwuz1_neq_vwuc1_then_la1 
    lda.z equal_bytes_1+1
    cmp #>PROGRESS_CELL
    bne __b9
    lda.z equal_bytes_1
    cmp #<PROGRESS_CELL
    bne __b9
    // rom_flash::@11
    // cputcxy(x,y,'+')
    // [1209] cputcxy::x#12 = rom_flash::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1210] cputcxy::y#12 = rom_flash::y_sector#13 -- vbuz1=vbum2 
    lda y_sector
    sta.z cputcxy.y
    // [1211] call cputcxy
    // [1432] phi from rom_flash::@11 to cputcxy [phi:rom_flash::@11->cputcxy]
    // [1432] phi cputcxy::c#13 = '+' [phi:rom_flash::@11->cputcxy#0] -- vbuz1=vbuc1 
    lda #'+'
    sta.z cputcxy.c
    // [1432] phi cputcxy::y#13 = cputcxy::y#12 [phi:rom_flash::@11->cputcxy#1] -- register_copy 
    // [1432] phi cputcxy::x#13 = cputcxy::x#12 [phi:rom_flash::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [1212] phi from rom_flash::@11 rom_flash::@28 to rom_flash::@10 [phi:rom_flash::@11/rom_flash::@28->rom_flash::@10]
    // [1212] phi rom_flash::flash_errors_sector#7 = rom_flash::flash_errors_sector#11 [phi:rom_flash::@11/rom_flash::@28->rom_flash::@10#0] -- register_copy 
    // rom_flash::@10
  __b10:
    // ram_address += PROGRESS_CELL
    // [1213] rom_flash::ram_address#1 = rom_flash::ram_address#10 + PROGRESS_CELL -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address
    clc
    adc #<PROGRESS_CELL
    sta.z ram_address
    lda.z ram_address+1
    adc #>PROGRESS_CELL
    sta.z ram_address+1
    // rom_address += PROGRESS_CELL
    // [1214] rom_flash::rom_address#1 = rom_flash::rom_address#10 + PROGRESS_CELL -- vduz1=vduz1_plus_vwuc1 
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
    // [1215] rom_flash::x#1 = ++ rom_flash::x#10 -- vbuz1=_inc_vbuz1 
    inc.z x
    jmp __b6
    // rom_flash::@9
  __b9:
    // cputcxy(x,y,'!')
    // [1216] cputcxy::x#11 = rom_flash::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1217] cputcxy::y#11 = rom_flash::y_sector#13 -- vbuz1=vbum2 
    lda y_sector
    sta.z cputcxy.y
    // [1218] call cputcxy
    // [1432] phi from rom_flash::@9 to cputcxy [phi:rom_flash::@9->cputcxy]
    // [1432] phi cputcxy::c#13 = '!' [phi:rom_flash::@9->cputcxy#0] -- vbuz1=vbuc1 
    lda #'!'
    sta.z cputcxy.c
    // [1432] phi cputcxy::y#13 = cputcxy::y#11 [phi:rom_flash::@9->cputcxy#1] -- register_copy 
    // [1432] phi cputcxy::x#13 = cputcxy::x#11 [phi:rom_flash::@9->cputcxy#2] -- register_copy 
    jsr cputcxy
    // rom_flash::@28
    // flash_errors_sector++;
    // [1219] rom_flash::flash_errors_sector#1 = ++ rom_flash::flash_errors_sector#11 -- vbuz1=_inc_vbuz1 
    inc.z flash_errors_sector
    jmp __b10
  .segment Data
    info_text: .text "Flashing ROM ... (-) same, (+) flashed, (!) error."
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
    s6: .text " errors ..."
    .byte 0
    rom_flash__26: .dword 0
    .label rom_address_sector = main.rom_file_modulo
    rom_boundary: .dword 0
    rom_sector_boundary: .dword 0
    .label retries = frame_maskxy.return
    .label bram_bank_sector = frame_maskxy.cpeekcxy1_y
    .label y_sector = frame_maskxy.cpeekcxy1_x
    .label rom_chip = rom_detect.rom_detect__28
    .label rom_bank_start = rom_detect.rom_detect__29
    file_size: .dword 0
    return: .dword 0
}
.segment Code
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __zp($dd) char mapbase, __zp($dc) char config)
screenlayer: {
    .label screenlayer__1 = $dd
    .label screenlayer__5 = $dc
    .label screenlayer__6 = $dc
    .label mapbase = $dd
    .label config = $dc
    .label y = $db
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [1220] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [1221] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [1222] *((char *)&__conio+2) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+2
    // mapbase >> 7
    // [1223] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbum1=vbuz2_ror_7 
    lda.z mapbase
    rol
    rol
    and #1
    sta screenlayer__0
    // __conio.mapbase_bank = mapbase >> 7
    // [1224] *((char *)&__conio+5) = screenlayer::$0 -- _deref_pbuc1=vbum1 
    sta __conio+5
    // (mapbase)<<1
    // [1225] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z screenlayer__1
    // MAKEWORD((mapbase)<<1,0)
    // [1226] screenlayer::$2 = screenlayer::$1 w= 0 -- vwum1=vbuz2_word_vbuc1 
    lda #0
    ldy.z screenlayer__1
    sty screenlayer__2+1
    sta screenlayer__2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [1227] *((unsigned int *)&__conio+3) = screenlayer::$2 -- _deref_pwuc1=vwum1 
    sta __conio+3
    tya
    sta __conio+3+1
    // config & VERA_LAYER_WIDTH_MASK
    // [1228] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbum1=vbuz2_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and.z config
    sta screenlayer__7
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [1229] screenlayer::$8 = screenlayer::$7 >> 4 -- vbum1=vbum1_ror_4 
    lda screenlayer__8
    lsr
    lsr
    lsr
    lsr
    sta screenlayer__8
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [1230] *((char *)&__conio+8) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbum1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+8
    // config & VERA_LAYER_HEIGHT_MASK
    // [1231] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbuz1=vbuz1_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and.z screenlayer__5
    sta.z screenlayer__5
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [1232] screenlayer::$6 = screenlayer::$5 >> 6 -- vbuz1=vbuz1_ror_6 
    lda.z screenlayer__6
    rol
    rol
    rol
    and #3
    sta.z screenlayer__6
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [1233] *((char *)&__conio+9) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+9
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [1234] screenlayer::$16 = screenlayer::$8 << 1 -- vbum1=vbum1_rol_1 
    asl screenlayer__16
    // [1235] *((unsigned int *)&__conio+$a) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbum1 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    ldy screenlayer__16
    lda VERA_LAYER_SKIP,y
    sta __conio+$a
    lda VERA_LAYER_SKIP+1,y
    sta __conio+$a+1
    // vera_dc_hscale_temp == 0x80
    // [1236] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vbom1=vbum2_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta screenlayer__9
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [1237] screenlayer::$18 = (char)screenlayer::$9
    // [1238] screenlayer::$10 = $28 << screenlayer::$18 -- vbum1=vbuc1_rol_vbum1 
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
    // [1239] screenlayer::$11 = screenlayer::$10 - 1 -- vbum1=vbum1_minus_1 
    dec screenlayer__11
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [1240] *((char *)&__conio+6) = screenlayer::$11 -- _deref_pbuc1=vbum1 
    lda screenlayer__11
    sta __conio+6
    // vera_dc_vscale_temp == 0x80
    // [1241] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vbom1=vbum2_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta screenlayer__12
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [1242] screenlayer::$19 = (char)screenlayer::$12
    // [1243] screenlayer::$13 = $1e << screenlayer::$19 -- vbum1=vbuc1_rol_vbum1 
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
    // [1244] screenlayer::$14 = screenlayer::$13 - 1 -- vbum1=vbum1_minus_1 
    dec screenlayer__14
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1245] *((char *)&__conio+7) = screenlayer::$14 -- _deref_pbuc1=vbum1 
    lda screenlayer__14
    sta __conio+7
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [1246] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta mapbase_offset
    lda __conio+3+1
    sta mapbase_offset+1
    // [1247] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [1247] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [1247] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [1248] if(screenlayer::y#2<=*((char *)&__conio+7)) goto screenlayer::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+7
    cmp.z y
    bcs __b2
    // screenlayer::@return
    // }
    // [1249] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [1250] screenlayer::$17 = screenlayer::y#2 << 1 -- vbum1=vbuz2_rol_1 
    lda.z y
    asl
    sta screenlayer__17
    // [1251] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbum1=vwum2 
    tay
    lda mapbase_offset
    sta __conio+$15,y
    lda mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [1252] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda mapbase_offset
    adc __conio+$a
    sta mapbase_offset
    lda mapbase_offset+1
    adc __conio+$a+1
    sta mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [1253] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [1247] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [1247] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [1247] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
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
    // [1254] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [1255] if(0!=((char *)&__conio+$f)[*((char *)&__conio+2)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [1256] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // [1257] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [1258] call gotoxy
    // [392] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [392] phi gotoxy::y#26 = 0 [phi:cscroll::@3->gotoxy#0] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.y
    // [392] phi gotoxy::x#26 = 0 [phi:cscroll::@3->gotoxy#1] -- vbuz1=vbuc1 
    sta.z gotoxy.x
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [1259] return 
    rts
    // [1260] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [1261] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [1262] gotoxy::y#3 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
    lda __conio+7
    sta.z gotoxy.y
    // [1263] call gotoxy
    // [392] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [392] phi gotoxy::y#26 = gotoxy::y#3 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [392] phi gotoxy::x#26 = 0 [phi:cscroll::@5->gotoxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.x
    jsr gotoxy
    // [1264] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [1265] call clearline
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
    // [1266] ((char *)&__conio+$f)[*((char *)&__conio+2)] = scroll::onoff#0 -- pbuc1_derefidx_(_deref_pbuc2)=vbuc3 
    lda #onoff
    ldy __conio+2
    sta __conio+$f,y
    // scroll::@return
    // }
    // [1267] return 
    rts
}
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    .label line_text = $3f
    .label l = $79
    .label ch = $3f
    .label c = $7f
    // unsigned int line_text = __conio.mapbase_offset
    // [1268] clrscr::line_text#0 = *((unsigned int *)&__conio+3) -- vwuz1=_deref_pwuc1 
    lda __conio+3
    sta.z line_text
    lda __conio+3+1
    sta.z line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1269] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [1270] clrscr::$0 = *((char *)&__conio+5) | VERA_INC_1 -- vbum1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta clrscr__0
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1271] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [1272] clrscr::l#0 = *((char *)&__conio+9) -- vbuz1=_deref_pbuc1 
    lda __conio+9
    sta.z l
    // [1273] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [1273] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [1273] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [1274] clrscr::$1 = byte0  clrscr::ch#0 -- vbum1=_byte0_vwuz2 
    lda.z ch
    sta clrscr__1
    // *VERA_ADDRX_L = BYTE0(ch)
    // [1275] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbum1 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [1276] clrscr::$2 = byte1  clrscr::ch#0 -- vbum1=_byte1_vwuz2 
    lda.z ch+1
    sta clrscr__2
    // *VERA_ADDRX_M = BYTE1(ch)
    // [1277] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth+1
    // [1278] clrscr::c#0 = *((char *)&__conio+8) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+8
    inc
    sta.z c
    // [1279] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [1279] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [1280] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1281] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [1282] clrscr::c#1 = -- clrscr::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [1283] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [1284] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+$a) -- vwuz1=vwuz1_plus__deref_pwuc1 
    clc
    lda.z line_text
    adc __conio+$a
    sta.z line_text
    lda.z line_text+1
    adc __conio+$a+1
    sta.z line_text+1
    // l--;
    // [1285] clrscr::l#1 = -- clrscr::l#4 -- vbuz1=_dec_vbuz1 
    dec.z l
    // while(l)
    // [1286] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbuz1_then_la1 
    lda.z l
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [1287] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y = 0
    // [1288] *((char *)&__conio+1) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+1
    // __conio.offset = __conio.mapbase_offset
    // [1289] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+3) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+3
    sta __conio+$13
    lda __conio+3+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [1290] return 
    rts
  .segment Data
    .label clrscr__0 = frame.w
    .label clrscr__1 = frame.h
    .label clrscr__2 = print_chip_end.w
}
.segment Code
  // frame
// Draw a line horizontal from a given xy position and a given length.
// The line should calculate the matching characters to draw and glue them.
// So it first needs to peek the characters at the given position.
// And then calculate the resulting characters to draw.
// void frame(char x0, char y0, __zp($cd) char x1, __zp($e7) char y1)
frame: {
    .label x = $24
    .label y = $de
    .label c = $43
    .label x_1 = $d6
    .label y_1 = $29
    .label x1 = $cd
    .label y1 = $e7
    // unsigned char w = x1 - x0
    // [1292] frame::w#0 = frame::x1#17 - frame::x#0 -- vbum1=vbuz2_minus_vbuz3 
    lda.z x1
    sec
    sbc.z x
    sta w
    // unsigned char h = y1 - y0
    // [1293] frame::h#0 = frame::y1#17 - frame::y#0 -- vbum1=vbuz2_minus_vbuz3 
    lda.z y1
    sec
    sbc.z y
    sta h
    // unsigned char mask = frame_maskxy(x, y)
    // [1294] frame_maskxy::x#0 = frame::x#0 -- vbum1=vbuz2 
    lda.z x
    sta frame_maskxy.x
    // [1295] frame_maskxy::y#0 = frame::y#0 -- vbum1=vbuz2 
    lda.z y
    sta frame_maskxy.y
    // [1296] call frame_maskxy
    // [1913] phi from frame to frame_maskxy [phi:frame->frame_maskxy]
    // [1913] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#0 [phi:frame->frame_maskxy#0] -- register_copy 
    // [1913] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#0 [phi:frame->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // unsigned char mask = frame_maskxy(x, y)
    // [1297] frame_maskxy::return#13 = frame_maskxy::return#12
    // frame::@13
    // [1298] frame::mask#0 = frame_maskxy::return#13
    // mask |= 0b0110
    // [1299] frame::mask#1 = frame::mask#0 | 6 -- vbum1=vbum1_bor_vbuc1 
    lda #6
    ora mask
    sta mask
    // unsigned char c = frame_char(mask)
    // [1300] frame_char::mask#0 = frame::mask#1
    // [1301] call frame_char
  // Add a corner.
    // [1939] phi from frame::@13 to frame_char [phi:frame::@13->frame_char]
    // [1939] phi frame_char::mask#10 = frame_char::mask#0 [phi:frame::@13->frame_char#0] -- register_copy 
    jsr frame_char
    // unsigned char c = frame_char(mask)
    // [1302] frame_char::return#13 = frame_char::return#12
    // frame::@14
    // [1303] frame::c#0 = frame_char::return#13
    // cputcxy(x, y, c)
    // [1304] cputcxy::x#0 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1305] cputcxy::y#0 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [1306] cputcxy::c#0 = frame::c#0
    // [1307] call cputcxy
    // [1432] phi from frame::@14 to cputcxy [phi:frame::@14->cputcxy]
    // [1432] phi cputcxy::c#13 = cputcxy::c#0 [phi:frame::@14->cputcxy#0] -- register_copy 
    // [1432] phi cputcxy::y#13 = cputcxy::y#0 [phi:frame::@14->cputcxy#1] -- register_copy 
    // [1432] phi cputcxy::x#13 = cputcxy::x#0 [phi:frame::@14->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@15
    // if(w>=2)
    // [1308] if(frame::w#0<2) goto frame::@36 -- vbum1_lt_vbuc1_then_la1 
    lda w
    cmp #2
    bcs !__b36+
    jmp __b36
  !__b36:
    // frame::@2
    // x++;
    // [1309] frame::x#1 = ++ frame::x#0 -- vbuz1=_inc_vbuz2 
    lda.z x
    inc
    sta.z x_1
    // [1310] phi from frame::@2 frame::@21 to frame::@4 [phi:frame::@2/frame::@21->frame::@4]
    // [1310] phi frame::x#10 = frame::x#1 [phi:frame::@2/frame::@21->frame::@4#0] -- register_copy 
    // frame::@4
  __b4:
    // while(x < x1)
    // [1311] if(frame::x#10<frame::x1#17) goto frame::@5 -- vbuz1_lt_vbuz2_then_la1 
    lda.z x_1
    cmp.z x1
    bcs !__b5+
    jmp __b5
  !__b5:
    // [1312] phi from frame::@36 frame::@4 to frame::@1 [phi:frame::@36/frame::@4->frame::@1]
    // [1312] phi frame::x#24 = frame::x#30 [phi:frame::@36/frame::@4->frame::@1#0] -- register_copy 
    // frame::@1
  __b1:
    // frame_maskxy(x, y)
    // [1313] frame_maskxy::x#1 = frame::x#24 -- vbum1=vbuz2 
    lda.z x_1
    sta frame_maskxy.x
    // [1314] frame_maskxy::y#1 = frame::y#0 -- vbum1=vbuz2 
    lda.z y
    sta frame_maskxy.y
    // [1315] call frame_maskxy
    // [1913] phi from frame::@1 to frame_maskxy [phi:frame::@1->frame_maskxy]
    // [1913] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#1 [phi:frame::@1->frame_maskxy#0] -- register_copy 
    // [1913] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#1 [phi:frame::@1->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [1316] frame_maskxy::return#14 = frame_maskxy::return#12
    // frame::@16
    // mask = frame_maskxy(x, y)
    // [1317] frame::mask#2 = frame_maskxy::return#14
    // mask |= 0b0011
    // [1318] frame::mask#3 = frame::mask#2 | 3 -- vbum1=vbum1_bor_vbuc1 
    lda #3
    ora mask
    sta mask
    // frame_char(mask)
    // [1319] frame_char::mask#1 = frame::mask#3
    // [1320] call frame_char
    // [1939] phi from frame::@16 to frame_char [phi:frame::@16->frame_char]
    // [1939] phi frame_char::mask#10 = frame_char::mask#1 [phi:frame::@16->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1321] frame_char::return#14 = frame_char::return#12
    // frame::@17
    // c = frame_char(mask)
    // [1322] frame::c#1 = frame_char::return#14
    // cputcxy(x, y, c)
    // [1323] cputcxy::x#1 = frame::x#24 -- vbuz1=vbuz2 
    lda.z x_1
    sta.z cputcxy.x
    // [1324] cputcxy::y#1 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [1325] cputcxy::c#1 = frame::c#1
    // [1326] call cputcxy
    // [1432] phi from frame::@17 to cputcxy [phi:frame::@17->cputcxy]
    // [1432] phi cputcxy::c#13 = cputcxy::c#1 [phi:frame::@17->cputcxy#0] -- register_copy 
    // [1432] phi cputcxy::y#13 = cputcxy::y#1 [phi:frame::@17->cputcxy#1] -- register_copy 
    // [1432] phi cputcxy::x#13 = cputcxy::x#1 [phi:frame::@17->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@18
    // if(h>=2)
    // [1327] if(frame::h#0<2) goto frame::@return -- vbum1_lt_vbuc1_then_la1 
    lda h
    cmp #2
    bcc __breturn
    // frame::@3
    // y++;
    // [1328] frame::y#1 = ++ frame::y#0 -- vbuz1=_inc_vbuz2 
    lda.z y
    inc
    sta.z y_1
    // [1329] phi from frame::@27 frame::@3 to frame::@6 [phi:frame::@27/frame::@3->frame::@6]
    // [1329] phi frame::y#10 = frame::y#2 [phi:frame::@27/frame::@3->frame::@6#0] -- register_copy 
    // frame::@6
  __b6:
    // while(y < y1)
    // [1330] if(frame::y#10<frame::y1#17) goto frame::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z y_1
    cmp.z y1
    bcc __b7
    // frame::@8
    // frame_maskxy(x, y)
    // [1331] frame_maskxy::x#5 = frame::x#0 -- vbum1=vbuz2 
    lda.z x
    sta frame_maskxy.x
    // [1332] frame_maskxy::y#5 = frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta frame_maskxy.y
    // [1333] call frame_maskxy
    // [1913] phi from frame::@8 to frame_maskxy [phi:frame::@8->frame_maskxy]
    // [1913] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#5 [phi:frame::@8->frame_maskxy#0] -- register_copy 
    // [1913] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#5 [phi:frame::@8->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [1334] frame_maskxy::return#18 = frame_maskxy::return#12
    // frame::@28
    // mask = frame_maskxy(x, y)
    // [1335] frame::mask#10 = frame_maskxy::return#18
    // mask |= 0b1100
    // [1336] frame::mask#11 = frame::mask#10 | $c -- vbum1=vbum1_bor_vbuc1 
    lda #$c
    ora mask
    sta mask
    // frame_char(mask)
    // [1337] frame_char::mask#5 = frame::mask#11
    // [1338] call frame_char
    // [1939] phi from frame::@28 to frame_char [phi:frame::@28->frame_char]
    // [1939] phi frame_char::mask#10 = frame_char::mask#5 [phi:frame::@28->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1339] frame_char::return#18 = frame_char::return#12
    // frame::@29
    // c = frame_char(mask)
    // [1340] frame::c#5 = frame_char::return#18
    // cputcxy(x, y, c)
    // [1341] cputcxy::x#5 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1342] cputcxy::y#5 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1343] cputcxy::c#5 = frame::c#5
    // [1344] call cputcxy
    // [1432] phi from frame::@29 to cputcxy [phi:frame::@29->cputcxy]
    // [1432] phi cputcxy::c#13 = cputcxy::c#5 [phi:frame::@29->cputcxy#0] -- register_copy 
    // [1432] phi cputcxy::y#13 = cputcxy::y#5 [phi:frame::@29->cputcxy#1] -- register_copy 
    // [1432] phi cputcxy::x#13 = cputcxy::x#5 [phi:frame::@29->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@30
    // if(w>=2)
    // [1345] if(frame::w#0<2) goto frame::@10 -- vbum1_lt_vbuc1_then_la1 
    lda w
    cmp #2
    bcc __b10
    // frame::@9
    // x++;
    // [1346] frame::x#4 = ++ frame::x#0 -- vbuz1=_inc_vbuz1 
    inc.z x
    // [1347] phi from frame::@35 frame::@9 to frame::@11 [phi:frame::@35/frame::@9->frame::@11]
    // [1347] phi frame::x#18 = frame::x#5 [phi:frame::@35/frame::@9->frame::@11#0] -- register_copy 
    // frame::@11
  __b11:
    // while(x < x1)
    // [1348] if(frame::x#18<frame::x1#17) goto frame::@12 -- vbuz1_lt_vbuz2_then_la1 
    lda.z x
    cmp.z x1
    bcc __b12
    // [1349] phi from frame::@11 frame::@30 to frame::@10 [phi:frame::@11/frame::@30->frame::@10]
    // [1349] phi frame::x#15 = frame::x#18 [phi:frame::@11/frame::@30->frame::@10#0] -- register_copy 
    // frame::@10
  __b10:
    // frame_maskxy(x, y)
    // [1350] frame_maskxy::x#6 = frame::x#15 -- vbum1=vbuz2 
    lda.z x
    sta frame_maskxy.x
    // [1351] frame_maskxy::y#6 = frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta frame_maskxy.y
    // [1352] call frame_maskxy
    // [1913] phi from frame::@10 to frame_maskxy [phi:frame::@10->frame_maskxy]
    // [1913] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#6 [phi:frame::@10->frame_maskxy#0] -- register_copy 
    // [1913] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#6 [phi:frame::@10->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [1353] frame_maskxy::return#19 = frame_maskxy::return#12
    // frame::@31
    // mask = frame_maskxy(x, y)
    // [1354] frame::mask#12 = frame_maskxy::return#19
    // mask |= 0b1001
    // [1355] frame::mask#13 = frame::mask#12 | 9 -- vbum1=vbum1_bor_vbuc1 
    lda #9
    ora mask
    sta mask
    // frame_char(mask)
    // [1356] frame_char::mask#6 = frame::mask#13
    // [1357] call frame_char
    // [1939] phi from frame::@31 to frame_char [phi:frame::@31->frame_char]
    // [1939] phi frame_char::mask#10 = frame_char::mask#6 [phi:frame::@31->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1358] frame_char::return#19 = frame_char::return#12
    // frame::@32
    // c = frame_char(mask)
    // [1359] frame::c#6 = frame_char::return#19
    // cputcxy(x, y, c)
    // [1360] cputcxy::x#6 = frame::x#15 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1361] cputcxy::y#6 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1362] cputcxy::c#6 = frame::c#6
    // [1363] call cputcxy
    // [1432] phi from frame::@32 to cputcxy [phi:frame::@32->cputcxy]
    // [1432] phi cputcxy::c#13 = cputcxy::c#6 [phi:frame::@32->cputcxy#0] -- register_copy 
    // [1432] phi cputcxy::y#13 = cputcxy::y#6 [phi:frame::@32->cputcxy#1] -- register_copy 
    // [1432] phi cputcxy::x#13 = cputcxy::x#6 [phi:frame::@32->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@return
  __breturn:
    // }
    // [1364] return 
    rts
    // frame::@12
  __b12:
    // frame_maskxy(x, y)
    // [1365] frame_maskxy::x#7 = frame::x#18 -- vbum1=vbuz2 
    lda.z x
    sta frame_maskxy.x
    // [1366] frame_maskxy::y#7 = frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta frame_maskxy.y
    // [1367] call frame_maskxy
    // [1913] phi from frame::@12 to frame_maskxy [phi:frame::@12->frame_maskxy]
    // [1913] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#7 [phi:frame::@12->frame_maskxy#0] -- register_copy 
    // [1913] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#7 [phi:frame::@12->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [1368] frame_maskxy::return#20 = frame_maskxy::return#12
    // frame::@33
    // mask = frame_maskxy(x, y)
    // [1369] frame::mask#14 = frame_maskxy::return#20
    // mask |= 0b0101
    // [1370] frame::mask#15 = frame::mask#14 | 5 -- vbum1=vbum1_bor_vbuc1 
    lda #5
    ora mask
    sta mask
    // frame_char(mask)
    // [1371] frame_char::mask#7 = frame::mask#15
    // [1372] call frame_char
    // [1939] phi from frame::@33 to frame_char [phi:frame::@33->frame_char]
    // [1939] phi frame_char::mask#10 = frame_char::mask#7 [phi:frame::@33->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1373] frame_char::return#20 = frame_char::return#12
    // frame::@34
    // c = frame_char(mask)
    // [1374] frame::c#7 = frame_char::return#20
    // cputcxy(x, y, c)
    // [1375] cputcxy::x#7 = frame::x#18 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1376] cputcxy::y#7 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1377] cputcxy::c#7 = frame::c#7
    // [1378] call cputcxy
    // [1432] phi from frame::@34 to cputcxy [phi:frame::@34->cputcxy]
    // [1432] phi cputcxy::c#13 = cputcxy::c#7 [phi:frame::@34->cputcxy#0] -- register_copy 
    // [1432] phi cputcxy::y#13 = cputcxy::y#7 [phi:frame::@34->cputcxy#1] -- register_copy 
    // [1432] phi cputcxy::x#13 = cputcxy::x#7 [phi:frame::@34->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@35
    // x++;
    // [1379] frame::x#5 = ++ frame::x#18 -- vbuz1=_inc_vbuz1 
    inc.z x
    jmp __b11
    // frame::@7
  __b7:
    // frame_maskxy(x0, y)
    // [1380] frame_maskxy::x#3 = frame::x#0 -- vbum1=vbuz2 
    lda.z x
    sta frame_maskxy.x
    // [1381] frame_maskxy::y#3 = frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta frame_maskxy.y
    // [1382] call frame_maskxy
    // [1913] phi from frame::@7 to frame_maskxy [phi:frame::@7->frame_maskxy]
    // [1913] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#3 [phi:frame::@7->frame_maskxy#0] -- register_copy 
    // [1913] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#3 [phi:frame::@7->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x0, y)
    // [1383] frame_maskxy::return#16 = frame_maskxy::return#12
    // frame::@22
    // mask = frame_maskxy(x0, y)
    // [1384] frame::mask#6 = frame_maskxy::return#16
    // mask |= 0b1010
    // [1385] frame::mask#7 = frame::mask#6 | $a -- vbum1=vbum1_bor_vbuc1 
    lda #$a
    ora mask
    sta mask
    // frame_char(mask)
    // [1386] frame_char::mask#3 = frame::mask#7
    // [1387] call frame_char
    // [1939] phi from frame::@22 to frame_char [phi:frame::@22->frame_char]
    // [1939] phi frame_char::mask#10 = frame_char::mask#3 [phi:frame::@22->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1388] frame_char::return#16 = frame_char::return#12
    // frame::@23
    // c = frame_char(mask)
    // [1389] frame::c#3 = frame_char::return#16
    // cputcxy(x0, y, c)
    // [1390] cputcxy::x#3 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1391] cputcxy::y#3 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1392] cputcxy::c#3 = frame::c#3
    // [1393] call cputcxy
    // [1432] phi from frame::@23 to cputcxy [phi:frame::@23->cputcxy]
    // [1432] phi cputcxy::c#13 = cputcxy::c#3 [phi:frame::@23->cputcxy#0] -- register_copy 
    // [1432] phi cputcxy::y#13 = cputcxy::y#3 [phi:frame::@23->cputcxy#1] -- register_copy 
    // [1432] phi cputcxy::x#13 = cputcxy::x#3 [phi:frame::@23->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@24
    // frame_maskxy(x1, y)
    // [1394] frame_maskxy::x#4 = frame::x1#17 -- vbum1=vbuz2 
    lda.z x1
    sta frame_maskxy.x
    // [1395] frame_maskxy::y#4 = frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta frame_maskxy.y
    // [1396] call frame_maskxy
    // [1913] phi from frame::@24 to frame_maskxy [phi:frame::@24->frame_maskxy]
    // [1913] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#4 [phi:frame::@24->frame_maskxy#0] -- register_copy 
    // [1913] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#4 [phi:frame::@24->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x1, y)
    // [1397] frame_maskxy::return#17 = frame_maskxy::return#12
    // frame::@25
    // mask = frame_maskxy(x1, y)
    // [1398] frame::mask#8 = frame_maskxy::return#17
    // mask |= 0b1010
    // [1399] frame::mask#9 = frame::mask#8 | $a -- vbum1=vbum1_bor_vbuc1 
    lda #$a
    ora mask
    sta mask
    // frame_char(mask)
    // [1400] frame_char::mask#4 = frame::mask#9
    // [1401] call frame_char
    // [1939] phi from frame::@25 to frame_char [phi:frame::@25->frame_char]
    // [1939] phi frame_char::mask#10 = frame_char::mask#4 [phi:frame::@25->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1402] frame_char::return#17 = frame_char::return#12
    // frame::@26
    // c = frame_char(mask)
    // [1403] frame::c#4 = frame_char::return#17
    // cputcxy(x1, y, c)
    // [1404] cputcxy::x#4 = frame::x1#17 -- vbuz1=vbuz2 
    lda.z x1
    sta.z cputcxy.x
    // [1405] cputcxy::y#4 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1406] cputcxy::c#4 = frame::c#4
    // [1407] call cputcxy
    // [1432] phi from frame::@26 to cputcxy [phi:frame::@26->cputcxy]
    // [1432] phi cputcxy::c#13 = cputcxy::c#4 [phi:frame::@26->cputcxy#0] -- register_copy 
    // [1432] phi cputcxy::y#13 = cputcxy::y#4 [phi:frame::@26->cputcxy#1] -- register_copy 
    // [1432] phi cputcxy::x#13 = cputcxy::x#4 [phi:frame::@26->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@27
    // y++;
    // [1408] frame::y#2 = ++ frame::y#10 -- vbuz1=_inc_vbuz1 
    inc.z y_1
    jmp __b6
    // frame::@5
  __b5:
    // frame_maskxy(x, y)
    // [1409] frame_maskxy::x#2 = frame::x#10 -- vbum1=vbuz2 
    lda.z x_1
    sta frame_maskxy.x
    // [1410] frame_maskxy::y#2 = frame::y#0 -- vbum1=vbuz2 
    lda.z y
    sta frame_maskxy.y
    // [1411] call frame_maskxy
    // [1913] phi from frame::@5 to frame_maskxy [phi:frame::@5->frame_maskxy]
    // [1913] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#2 [phi:frame::@5->frame_maskxy#0] -- register_copy 
    // [1913] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#2 [phi:frame::@5->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [1412] frame_maskxy::return#15 = frame_maskxy::return#12
    // frame::@19
    // mask = frame_maskxy(x, y)
    // [1413] frame::mask#4 = frame_maskxy::return#15
    // mask |= 0b0101
    // [1414] frame::mask#5 = frame::mask#4 | 5 -- vbum1=vbum1_bor_vbuc1 
    lda #5
    ora mask
    sta mask
    // frame_char(mask)
    // [1415] frame_char::mask#2 = frame::mask#5
    // [1416] call frame_char
    // [1939] phi from frame::@19 to frame_char [phi:frame::@19->frame_char]
    // [1939] phi frame_char::mask#10 = frame_char::mask#2 [phi:frame::@19->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1417] frame_char::return#15 = frame_char::return#12
    // frame::@20
    // c = frame_char(mask)
    // [1418] frame::c#2 = frame_char::return#15
    // cputcxy(x, y, c)
    // [1419] cputcxy::x#2 = frame::x#10 -- vbuz1=vbuz2 
    lda.z x_1
    sta.z cputcxy.x
    // [1420] cputcxy::y#2 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [1421] cputcxy::c#2 = frame::c#2
    // [1422] call cputcxy
    // [1432] phi from frame::@20 to cputcxy [phi:frame::@20->cputcxy]
    // [1432] phi cputcxy::c#13 = cputcxy::c#2 [phi:frame::@20->cputcxy#0] -- register_copy 
    // [1432] phi cputcxy::y#13 = cputcxy::y#2 [phi:frame::@20->cputcxy#1] -- register_copy 
    // [1432] phi cputcxy::x#13 = cputcxy::x#2 [phi:frame::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@21
    // x++;
    // [1423] frame::x#2 = ++ frame::x#10 -- vbuz1=_inc_vbuz1 
    inc.z x_1
    jmp __b4
    // frame::@36
  __b36:
    // [1424] frame::x#30 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z x_1
    jmp __b1
  .segment Data
    w: .byte 0
    h: .byte 0
    .label mask = frame_maskxy.return
}
.segment Code
  // cputsxy
// Move cursor and output a NUL-terminated string
// Same as "gotoxy (x, y); puts (s);"
// void cputsxy(__zp($7e) char x, __zp($c5) char y, __zp($ab) const char *s)
cputsxy: {
    .label x = $7e
    .label y = $c5
    .label s = $ab
    // gotoxy(x, y)
    // [1426] gotoxy::x#1 = cputsxy::x#2 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1427] gotoxy::y#1 = cputsxy::y#2 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1428] call gotoxy
    // [392] phi from cputsxy to gotoxy [phi:cputsxy->gotoxy]
    // [392] phi gotoxy::y#26 = gotoxy::y#1 [phi:cputsxy->gotoxy#0] -- register_copy 
    // [392] phi gotoxy::x#26 = gotoxy::x#1 [phi:cputsxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputsxy::@1
    // cputs(s)
    // [1429] cputs::s#1 = cputsxy::s#2 -- pbuz1=pbuz2 
    lda.z s
    sta.z cputs.s
    lda.z s+1
    sta.z cputs.s+1
    // [1430] call cputs
    // [1954] phi from cputsxy::@1 to cputs [phi:cputsxy::@1->cputs]
    jsr cputs
    // cputsxy::@return
    // }
    // [1431] return 
    rts
}
  // cputcxy
// Move cursor and output one character
// Same as "gotoxy (x, y); cputc (c);"
// void cputcxy(__zp($be) char x, __zp($ba) char y, __zp($43) char c)
cputcxy: {
    .label x = $be
    .label y = $ba
    .label c = $43
    // gotoxy(x, y)
    // [1433] gotoxy::x#0 = cputcxy::x#13 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1434] gotoxy::y#0 = cputcxy::y#13 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1435] call gotoxy
    // [392] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [392] phi gotoxy::y#26 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [392] phi gotoxy::x#26 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [1436] stackpush(char) = cputcxy::c#13 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [1437] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [1439] return 
    rts
}
  // info_clear
// void info_clear(__zp($4b) char l)
info_clear: {
    .const w = $40+1
    .label y = $4b
    .label x = $c2
    .label i = $56
    .label l = $4b
    // unsigned char y = INFO_Y+l
    // [1441] info_clear::y#0 = $11 + info_clear::l#4 -- vbuz1=vbuc1_plus_vbuz1 
    lda #$11
    clc
    adc.z y
    sta.z y
    // [1442] phi from info_clear to info_clear::@1 [phi:info_clear->info_clear::@1]
    // [1442] phi info_clear::x#2 = 2 [phi:info_clear->info_clear::@1#0] -- vbuz1=vbuc1 
    lda #2
    sta.z x
    // [1442] phi info_clear::i#2 = 0 [phi:info_clear->info_clear::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // info_clear::@1
  __b1:
    // for(unsigned char i = 0; i < w; i++)
    // [1443] if(info_clear::i#2<info_clear::w) goto info_clear::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z i
    cmp #w
    bcc __b2
    // info_clear::@3
    // gotoxy(INFO_X, y)
    // [1444] gotoxy::y#14 = info_clear::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1445] call gotoxy
    // [392] phi from info_clear::@3 to gotoxy [phi:info_clear::@3->gotoxy]
    // [392] phi gotoxy::y#26 = gotoxy::y#14 [phi:info_clear::@3->gotoxy#0] -- register_copy 
    // [392] phi gotoxy::x#26 = 2 [phi:info_clear::@3->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // info_clear::@return
    // }
    // [1446] return 
    rts
    // info_clear::@2
  __b2:
    // cputcxy(x, y, ' ')
    // [1447] cputcxy::x#10 = info_clear::x#2 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1448] cputcxy::y#10 = info_clear::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [1449] call cputcxy
    // [1432] phi from info_clear::@2 to cputcxy [phi:info_clear::@2->cputcxy]
    // [1432] phi cputcxy::c#13 = ' ' [phi:info_clear::@2->cputcxy#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z cputcxy.c
    // [1432] phi cputcxy::y#13 = cputcxy::y#10 [phi:info_clear::@2->cputcxy#1] -- register_copy 
    // [1432] phi cputcxy::x#13 = cputcxy::x#10 [phi:info_clear::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // info_clear::@4
    // x++;
    // [1450] info_clear::x#1 = ++ info_clear::x#2 -- vbuz1=_inc_vbuz1 
    inc.z x
    // for(unsigned char i = 0; i < w; i++)
    // [1451] info_clear::i#1 = ++ info_clear::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1442] phi from info_clear::@4 to info_clear::@1 [phi:info_clear::@4->info_clear::@1]
    // [1442] phi info_clear::x#2 = info_clear::x#1 [phi:info_clear::@4->info_clear::@1#0] -- register_copy 
    // [1442] phi info_clear::i#2 = info_clear::i#1 [phi:info_clear::@4->info_clear::@1#1] -- register_copy 
    jmp __b1
}
  // wherex
// Return the x position of the cursor
wherex: {
    // return __conio.cursor_x;
    // [1452] wherex::return#0 = *((char *)&__conio) -- vbum1=_deref_pbuc1 
    lda __conio
    sta return
    // wherex::@return
    // }
    // [1453] return 
    rts
  .segment Data
    .label return = rom_detect.rom_detect__38
    return_1: .byte 0
}
.segment Code
  // wherey
// Return the y position of the cursor
wherey: {
    // return __conio.cursor_y;
    // [1454] wherey::return#0 = *((char *)&__conio+1) -- vbum1=_deref_pbuc1 
    lda __conio+1
    sta return
    // wherey::@return
    // }
    // [1455] return 
    rts
  .segment Data
    .label return = rom_detect.rom_detect__25
    .label return_1 = flash_smc.smc_byte_upload
}
.segment Code
  // print_smc_led
// void print_smc_led(__zp($c6) char c)
print_smc_led: {
    .label c = $c6
    // print_chip_led(CHIP_SMC_X+1, CHIP_SMC_Y, CHIP_SMC_W, c, BLUE)
    // [1457] print_chip_led::tc#0 = print_smc_led::c#2
    // [1458] call print_chip_led
    // [1963] phi from print_smc_led to print_chip_led [phi:print_smc_led->print_chip_led]
    // [1963] phi print_chip_led::w#5 = 5 [phi:print_smc_led->print_chip_led#0] -- vbuz1=vbuc1 
    lda #5
    sta.z print_chip_led.w
    // [1963] phi print_chip_led::tc#3 = print_chip_led::tc#0 [phi:print_smc_led->print_chip_led#1] -- register_copy 
    // [1963] phi print_chip_led::x#3 = 1+1 [phi:print_smc_led->print_chip_led#2] -- vbuz1=vbuc1 
    lda #1+1
    sta.z print_chip_led.x
    jsr print_chip_led
    // print_smc_led::@return
    // }
    // [1459] return 
    rts
}
  // print_chip
// void print_chip(__zp($4c) char x, char y, __mem() char w, __zp($d8) char *text)
print_chip: {
    .label y = 3+1+1+1+1+1+1+1+1+1
    .label text = $d8
    .label x = $4c
    .label text_2 = $7c
    .label text_4 = $cb
    .label text_5 = $e2
    .label text_6 = $c9
    // print_chip_line(x, y++, w, *text++)
    // [1461] print_chip_line::x#0 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1462] print_chip_line::w#0 = print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z print_chip_line.w
    // [1463] print_chip_line::c#0 = *print_chip::text#11 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_2),y
    sta.z print_chip_line.c
    // [1464] call print_chip_line
    // [1981] phi from print_chip to print_chip_line [phi:print_chip->print_chip_line]
    // [1981] phi print_chip_line::c#15 = print_chip_line::c#0 [phi:print_chip->print_chip_line#0] -- register_copy 
    // [1981] phi print_chip_line::w#10 = print_chip_line::w#0 [phi:print_chip->print_chip_line#1] -- register_copy 
    // [1981] phi print_chip_line::y#16 = 3+1 [phi:print_chip->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1
    sta.z print_chip_line.y
    // [1981] phi print_chip_line::x#16 = print_chip_line::x#0 [phi:print_chip->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@1
    // print_chip_line(x, y++, w, *text++);
    // [1465] print_chip::text#0 = ++ print_chip::text#11 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_2
    adc #1
    sta.z text
    lda.z text_2+1
    adc #0
    sta.z text+1
    // print_chip_line(x, y++, w, *text++)
    // [1466] print_chip_line::x#1 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1467] print_chip_line::w#1 = print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z print_chip_line.w
    // [1468] print_chip_line::c#1 = *print_chip::text#0 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text),y
    sta.z print_chip_line.c
    // [1469] call print_chip_line
    // [1981] phi from print_chip::@1 to print_chip_line [phi:print_chip::@1->print_chip_line]
    // [1981] phi print_chip_line::c#15 = print_chip_line::c#1 [phi:print_chip::@1->print_chip_line#0] -- register_copy 
    // [1981] phi print_chip_line::w#10 = print_chip_line::w#1 [phi:print_chip::@1->print_chip_line#1] -- register_copy 
    // [1981] phi print_chip_line::y#16 = ++3+1 [phi:print_chip::@1->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1
    sta.z print_chip_line.y
    // [1981] phi print_chip_line::x#16 = print_chip_line::x#1 [phi:print_chip::@1->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@2
    // print_chip_line(x, y++, w, *text++);
    // [1470] print_chip::text#1 = ++ print_chip::text#0 -- pbum1=_inc_pbuz2 
    clc
    lda.z text
    adc #1
    sta text_1
    lda.z text+1
    adc #0
    sta text_1+1
    // print_chip_line(x, y++, w, *text++)
    // [1471] print_chip_line::x#2 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1472] print_chip_line::w#2 = print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z print_chip_line.w
    // [1473] print_chip_line::c#2 = *print_chip::text#1 -- vbuz1=_deref_pbum2 
    ldy text_1
    sty.z $fe
    ldy text_1+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta.z print_chip_line.c
    // [1474] call print_chip_line
    // [1981] phi from print_chip::@2 to print_chip_line [phi:print_chip::@2->print_chip_line]
    // [1981] phi print_chip_line::c#15 = print_chip_line::c#2 [phi:print_chip::@2->print_chip_line#0] -- register_copy 
    // [1981] phi print_chip_line::w#10 = print_chip_line::w#2 [phi:print_chip::@2->print_chip_line#1] -- register_copy 
    // [1981] phi print_chip_line::y#16 = ++++3+1 [phi:print_chip::@2->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1
    sta.z print_chip_line.y
    // [1981] phi print_chip_line::x#16 = print_chip_line::x#2 [phi:print_chip::@2->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@3
    // print_chip_line(x, y++, w, *text++);
    // [1475] print_chip::text#15 = ++ print_chip::text#1 -- pbum1=_inc_pbum2 
    clc
    lda text_1
    adc #1
    sta text_3
    lda text_1+1
    adc #0
    sta text_3+1
    // print_chip_line(x, y++, w, *text++)
    // [1476] print_chip_line::x#3 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1477] print_chip_line::w#3 = print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z print_chip_line.w
    // [1478] print_chip_line::c#3 = *print_chip::text#15 -- vbuz1=_deref_pbum2 
    ldy text_3
    sty.z $fe
    ldy text_3+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta.z print_chip_line.c
    // [1479] call print_chip_line
    // [1981] phi from print_chip::@3 to print_chip_line [phi:print_chip::@3->print_chip_line]
    // [1981] phi print_chip_line::c#15 = print_chip_line::c#3 [phi:print_chip::@3->print_chip_line#0] -- register_copy 
    // [1981] phi print_chip_line::w#10 = print_chip_line::w#3 [phi:print_chip::@3->print_chip_line#1] -- register_copy 
    // [1981] phi print_chip_line::y#16 = ++++++3+1 [phi:print_chip::@3->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1+1
    sta.z print_chip_line.y
    // [1981] phi print_chip_line::x#16 = print_chip_line::x#3 [phi:print_chip::@3->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@4
    // print_chip_line(x, y++, w, *text++);
    // [1480] print_chip::text#16 = ++ print_chip::text#15 -- pbuz1=_inc_pbum2 
    clc
    lda text_3
    adc #1
    sta.z text_4
    lda text_3+1
    adc #0
    sta.z text_4+1
    // print_chip_line(x, y++, w, *text++)
    // [1481] print_chip_line::x#4 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1482] print_chip_line::w#4 = print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z print_chip_line.w
    // [1483] print_chip_line::c#4 = *print_chip::text#16 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_4),y
    sta.z print_chip_line.c
    // [1484] call print_chip_line
    // [1981] phi from print_chip::@4 to print_chip_line [phi:print_chip::@4->print_chip_line]
    // [1981] phi print_chip_line::c#15 = print_chip_line::c#4 [phi:print_chip::@4->print_chip_line#0] -- register_copy 
    // [1981] phi print_chip_line::w#10 = print_chip_line::w#4 [phi:print_chip::@4->print_chip_line#1] -- register_copy 
    // [1981] phi print_chip_line::y#16 = ++++++++3+1 [phi:print_chip::@4->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1+1+1
    sta.z print_chip_line.y
    // [1981] phi print_chip_line::x#16 = print_chip_line::x#4 [phi:print_chip::@4->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@5
    // print_chip_line(x, y++, w, *text++);
    // [1485] print_chip::text#17 = ++ print_chip::text#16 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_4
    adc #1
    sta.z text_5
    lda.z text_4+1
    adc #0
    sta.z text_5+1
    // print_chip_line(x, y++, w, *text++)
    // [1486] print_chip_line::x#5 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1487] print_chip_line::w#5 = print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z print_chip_line.w
    // [1488] print_chip_line::c#5 = *print_chip::text#17 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_5),y
    sta.z print_chip_line.c
    // [1489] call print_chip_line
    // [1981] phi from print_chip::@5 to print_chip_line [phi:print_chip::@5->print_chip_line]
    // [1981] phi print_chip_line::c#15 = print_chip_line::c#5 [phi:print_chip::@5->print_chip_line#0] -- register_copy 
    // [1981] phi print_chip_line::w#10 = print_chip_line::w#5 [phi:print_chip::@5->print_chip_line#1] -- register_copy 
    // [1981] phi print_chip_line::y#16 = ++++++++++3+1 [phi:print_chip::@5->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1+1+1+1
    sta.z print_chip_line.y
    // [1981] phi print_chip_line::x#16 = print_chip_line::x#5 [phi:print_chip::@5->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@6
    // print_chip_line(x, y++, w, *text++);
    // [1490] print_chip::text#18 = ++ print_chip::text#17 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_5
    adc #1
    sta.z text_6
    lda.z text_5+1
    adc #0
    sta.z text_6+1
    // print_chip_line(x, y++, w, *text++)
    // [1491] print_chip_line::x#6 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1492] print_chip_line::w#6 = print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z print_chip_line.w
    // [1493] print_chip_line::c#6 = *print_chip::text#18 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta.z print_chip_line.c
    // [1494] call print_chip_line
    // [1981] phi from print_chip::@6 to print_chip_line [phi:print_chip::@6->print_chip_line]
    // [1981] phi print_chip_line::c#15 = print_chip_line::c#6 [phi:print_chip::@6->print_chip_line#0] -- register_copy 
    // [1981] phi print_chip_line::w#10 = print_chip_line::w#6 [phi:print_chip::@6->print_chip_line#1] -- register_copy 
    // [1981] phi print_chip_line::y#16 = ++++++++++++3+1 [phi:print_chip::@6->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1+1+1+1+1
    sta.z print_chip_line.y
    // [1981] phi print_chip_line::x#16 = print_chip_line::x#6 [phi:print_chip::@6->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@7
    // print_chip_line(x, y++, w, *text++);
    // [1495] print_chip::text#19 = ++ print_chip::text#18 -- pbuz1=_inc_pbuz1 
    inc.z text_6
    bne !+
    inc.z text_6+1
  !:
    // print_chip_line(x, y++, w, *text++)
    // [1496] print_chip_line::x#7 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1497] print_chip_line::w#7 = print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z print_chip_line.w
    // [1498] print_chip_line::c#7 = *print_chip::text#19 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta.z print_chip_line.c
    // [1499] call print_chip_line
    // [1981] phi from print_chip::@7 to print_chip_line [phi:print_chip::@7->print_chip_line]
    // [1981] phi print_chip_line::c#15 = print_chip_line::c#7 [phi:print_chip::@7->print_chip_line#0] -- register_copy 
    // [1981] phi print_chip_line::w#10 = print_chip_line::w#7 [phi:print_chip::@7->print_chip_line#1] -- register_copy 
    // [1981] phi print_chip_line::y#16 = ++++++++++++++3+1 [phi:print_chip::@7->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1+1+1+1+1+1
    sta.z print_chip_line.y
    // [1981] phi print_chip_line::x#16 = print_chip_line::x#7 [phi:print_chip::@7->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@8
    // print_chip_end(x, y++, w)
    // [1500] print_chip_end::x#0 = print_chip::x#10
    // [1501] print_chip_end::w#0 = print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta print_chip_end.w
    // [1502] call print_chip_end
    jsr print_chip_end
    // print_chip::@return
    // }
    // [1503] return 
    rts
  .segment Data
    .label text_1 = fopen.fopen__11
    .label text_3 = ferror.return
    .label w = ferror.errno_len
}
.segment Code
  // utoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void utoa(__zp($48) unsigned int value, __zp($d1) char *buffer, __zp($f3) char radix)
utoa: {
    .label utoa__4 = $d7
    .label utoa__10 = $d6
    .label utoa__11 = $de
    .label digit_value = $59
    .label buffer = $d1
    .label digit = $5b
    .label value = $48
    .label radix = $f3
    .label started = $cd
    .label max_digits = $df
    .label digit_values = $e0
    // if(radix==DECIMAL)
    // [1504] if(utoa::radix#0==DECIMAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp.z radix
    beq __b2
    // utoa::@2
    // if(radix==HEXADECIMAL)
    // [1505] if(utoa::radix#0==HEXADECIMAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp.z radix
    beq __b3
    // utoa::@3
    // if(radix==OCTAL)
    // [1506] if(utoa::radix#0==OCTAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp.z radix
    beq __b4
    // utoa::@4
    // if(radix==BINARY)
    // [1507] if(utoa::radix#0==BINARY) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp.z radix
    beq __b5
    // utoa::@5
    // *buffer++ = 'e'
    // [1508] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1509] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1510] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1511] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // utoa::@return
    // }
    // [1512] return 
    rts
    // [1513] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
  __b2:
    // [1513] phi utoa::digit_values#8 = RADIX_DECIMAL_VALUES [phi:utoa->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_DECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES
    sta.z digit_values+1
    // [1513] phi utoa::max_digits#7 = 5 [phi:utoa->utoa::@1#1] -- vbuz1=vbuc1 
    lda #5
    sta.z max_digits
    jmp __b1
    // [1513] phi from utoa::@2 to utoa::@1 [phi:utoa::@2->utoa::@1]
  __b3:
    // [1513] phi utoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES [phi:utoa::@2->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_HEXADECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES
    sta.z digit_values+1
    // [1513] phi utoa::max_digits#7 = 4 [phi:utoa::@2->utoa::@1#1] -- vbuz1=vbuc1 
    lda #4
    sta.z max_digits
    jmp __b1
    // [1513] phi from utoa::@3 to utoa::@1 [phi:utoa::@3->utoa::@1]
  __b4:
    // [1513] phi utoa::digit_values#8 = RADIX_OCTAL_VALUES [phi:utoa::@3->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_OCTAL_VALUES
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES
    sta.z digit_values+1
    // [1513] phi utoa::max_digits#7 = 6 [phi:utoa::@3->utoa::@1#1] -- vbuz1=vbuc1 
    lda #6
    sta.z max_digits
    jmp __b1
    // [1513] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
  __b5:
    // [1513] phi utoa::digit_values#8 = RADIX_BINARY_VALUES [phi:utoa::@4->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_BINARY_VALUES
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES
    sta.z digit_values+1
    // [1513] phi utoa::max_digits#7 = $10 [phi:utoa::@4->utoa::@1#1] -- vbuz1=vbuc1 
    lda #$10
    sta.z max_digits
    // utoa::@1
  __b1:
    // [1514] phi from utoa::@1 to utoa::@6 [phi:utoa::@1->utoa::@6]
    // [1514] phi utoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa::@1->utoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1514] phi utoa::started#2 = 0 [phi:utoa::@1->utoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [1514] phi utoa::value#2 = utoa::value#1 [phi:utoa::@1->utoa::@6#2] -- register_copy 
    // [1514] phi utoa::digit#2 = 0 [phi:utoa::@1->utoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // utoa::@6
  __b6:
    // max_digits-1
    // [1515] utoa::$4 = utoa::max_digits#7 - 1 -- vbuz1=vbuz2_minus_1 
    ldx.z max_digits
    dex
    stx.z utoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1516] if(utoa::digit#2<utoa::$4) goto utoa::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z digit
    cmp.z utoa__4
    bcc __b7
    // utoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1517] utoa::$11 = (char)utoa::value#2 -- vbuz1=_byte_vwuz2 
    lda.z value
    sta.z utoa__11
    // [1518] *utoa::buffer#11 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1519] utoa::buffer#3 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1520] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // utoa::@7
  __b7:
    // unsigned int digit_value = digit_values[digit]
    // [1521] utoa::$10 = utoa::digit#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z digit
    asl
    sta.z utoa__10
    // [1522] utoa::digit_value#0 = utoa::digit_values#8[utoa::$10] -- vwuz1=pwuz2_derefidx_vbuz3 
    tay
    lda (digit_values),y
    sta.z digit_value
    iny
    lda (digit_values),y
    sta.z digit_value+1
    // if (started || value >= digit_value)
    // [1523] if(0!=utoa::started#2) goto utoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // utoa::@12
    // [1524] if(utoa::value#2>=utoa::digit_value#0) goto utoa::@10 -- vwuz1_ge_vwuz2_then_la1 
    lda.z digit_value+1
    cmp.z value+1
    bne !+
    lda.z digit_value
    cmp.z value
    beq __b10
  !:
    bcc __b10
    // [1525] phi from utoa::@12 to utoa::@9 [phi:utoa::@12->utoa::@9]
    // [1525] phi utoa::buffer#14 = utoa::buffer#11 [phi:utoa::@12->utoa::@9#0] -- register_copy 
    // [1525] phi utoa::started#4 = utoa::started#2 [phi:utoa::@12->utoa::@9#1] -- register_copy 
    // [1525] phi utoa::value#6 = utoa::value#2 [phi:utoa::@12->utoa::@9#2] -- register_copy 
    // utoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1526] utoa::digit#1 = ++ utoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1514] phi from utoa::@9 to utoa::@6 [phi:utoa::@9->utoa::@6]
    // [1514] phi utoa::buffer#11 = utoa::buffer#14 [phi:utoa::@9->utoa::@6#0] -- register_copy 
    // [1514] phi utoa::started#2 = utoa::started#4 [phi:utoa::@9->utoa::@6#1] -- register_copy 
    // [1514] phi utoa::value#2 = utoa::value#6 [phi:utoa::@9->utoa::@6#2] -- register_copy 
    // [1514] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@9->utoa::@6#3] -- register_copy 
    jmp __b6
    // utoa::@10
  __b10:
    // utoa_append(buffer++, value, digit_value)
    // [1527] utoa_append::buffer#0 = utoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [1528] utoa_append::value#0 = utoa::value#2
    // [1529] utoa_append::sub#0 = utoa::digit_value#0
    // [1530] call utoa_append
    // [2042] phi from utoa::@10 to utoa_append [phi:utoa::@10->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [1531] utoa_append::return#0 = utoa_append::value#2
    // utoa::@11
    // value = utoa_append(buffer++, value, digit_value)
    // [1532] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [1533] utoa::buffer#4 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1525] phi from utoa::@11 to utoa::@9 [phi:utoa::@11->utoa::@9]
    // [1525] phi utoa::buffer#14 = utoa::buffer#4 [phi:utoa::@11->utoa::@9#0] -- register_copy 
    // [1525] phi utoa::started#4 = 1 [phi:utoa::@11->utoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [1525] phi utoa::value#6 = utoa::value#0 [phi:utoa::@11->utoa::@9#2] -- register_copy 
    jmp __b9
}
  // printf_number_buffer
// Print the contents of the number buffer using a specific format.
// This handles minimum length, zero-filling, and left/right justification from the format
// void printf_number_buffer(__zp($60) void (*putc)(char), __zp($e7) char buffer_sign, char *buffer_digits, __zp($ea) char format_min_length, char format_justify_left, char format_sign_always, __zp($e9) char format_zero_padding, char format_upper_case, char format_radix)
printf_number_buffer: {
    .label printf_number_buffer__19 = $ab
    .label putc = $60
    .label buffer_sign = $e7
    .label format_min_length = $ea
    .label format_zero_padding = $e9
    .label len = $de
    .label padding = $de
    // if(format.min_length)
    // [1535] if(0==printf_number_buffer::format_min_length#3) goto printf_number_buffer::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b5
    // [1536] phi from printf_number_buffer to printf_number_buffer::@5 [phi:printf_number_buffer->printf_number_buffer::@5]
    // printf_number_buffer::@5
    // strlen(buffer.digits)
    // [1537] call strlen
    // [1790] phi from printf_number_buffer::@5 to strlen [phi:printf_number_buffer::@5->strlen]
    // [1790] phi strlen::str#8 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [1538] strlen::return#3 = strlen::len#2
    // printf_number_buffer::@11
    // [1539] printf_number_buffer::$19 = strlen::return#3
    // signed char len = (signed char)strlen(buffer.digits)
    // [1540] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsz1=_sbyte_vwuz2 
    // There is a minimum length - work out the padding
    lda.z printf_number_buffer__19
    sta.z len
    // if(buffer.sign)
    // [1541] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@10 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b10
    // printf_number_buffer::@6
    // len++;
    // [1542] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsz1=_inc_vbsz1 
    inc.z len
    // [1543] phi from printf_number_buffer::@11 printf_number_buffer::@6 to printf_number_buffer::@10 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10]
    // [1543] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10#0] -- register_copy 
    // printf_number_buffer::@10
  __b10:
    // padding = (signed char)format.min_length - len
    // [1544] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#3 - printf_number_buffer::len#2 -- vbsz1=vbsz2_minus_vbsz1 
    lda.z format_min_length
    sec
    sbc.z padding
    sta.z padding
    // if(padding<0)
    // [1545] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@15 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1547] phi from printf_number_buffer printf_number_buffer::@10 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1]
  __b5:
    // [1547] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [1546] phi from printf_number_buffer::@10 to printf_number_buffer::@15 [phi:printf_number_buffer::@10->printf_number_buffer::@15]
    // printf_number_buffer::@15
    // [1547] phi from printf_number_buffer::@15 to printf_number_buffer::@1 [phi:printf_number_buffer::@15->printf_number_buffer::@1]
    // [1547] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@15->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // printf_number_buffer::@13
    // if(!format.justify_left && !format.zero_padding && padding)
    // [1548] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_zero_padding
    bne __b2
    // printf_number_buffer::@12
    // [1549] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@7 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b7
    jmp __b2
    // printf_number_buffer::@7
  __b7:
    // printf_padding(putc, ' ',(char)padding)
    // [1550] printf_padding::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1551] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1552] call printf_padding
    // [1796] phi from printf_number_buffer::@7 to printf_padding [phi:printf_number_buffer::@7->printf_padding]
    // [1796] phi printf_padding::putc#7 = printf_padding::putc#0 [phi:printf_number_buffer::@7->printf_padding#0] -- register_copy 
    // [1796] phi printf_padding::pad#7 = ' ' [phi:printf_number_buffer::@7->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1796] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@7->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [1553] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b3
    // printf_number_buffer::@8
    // putc(buffer.sign)
    // [1554] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbuz1 
    pha
    // [1555] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall27
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [1557] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbuz1_then_la1 
    lda.z format_zero_padding
    beq __b4
    // printf_number_buffer::@14
    // [1558] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@9 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b9
    jmp __b4
    // printf_number_buffer::@9
  __b9:
    // printf_padding(putc, '0',(char)padding)
    // [1559] printf_padding::putc#1 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1560] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1561] call printf_padding
    // [1796] phi from printf_number_buffer::@9 to printf_padding [phi:printf_number_buffer::@9->printf_padding]
    // [1796] phi printf_padding::putc#7 = printf_padding::putc#1 [phi:printf_number_buffer::@9->printf_padding#0] -- register_copy 
    // [1796] phi printf_padding::pad#7 = '0' [phi:printf_number_buffer::@9->printf_padding#1] -- vbuz1=vbuc1 
    lda #'0'
    sta.z printf_padding.pad
    // [1796] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@9->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // printf_str(putc, buffer.digits)
    // [1562] printf_str::putc#0 = printf_number_buffer::putc#10
    // [1563] call printf_str
    // [531] phi from printf_number_buffer::@4 to printf_str [phi:printf_number_buffer::@4->printf_str]
    // [531] phi printf_str::putc#53 = printf_str::putc#0 [phi:printf_number_buffer::@4->printf_str#0] -- register_copy 
    // [531] phi printf_str::s#53 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@return
    // }
    // [1564] return 
    rts
    // Outside Flow
  icall27:
    jmp (putc)
}
  // print_vera_led
// void print_vera_led(__zp($c6) char c)
print_vera_led: {
    .label c = $c6
    // print_chip_led(CHIP_VERA_X+1, CHIP_VERA_Y, CHIP_VERA_W, c, BLUE)
    // [1566] print_chip_led::tc#1 = print_vera_led::c#2
    // [1567] call print_chip_led
    // [1963] phi from print_vera_led to print_chip_led [phi:print_vera_led->print_chip_led]
    // [1963] phi print_chip_led::w#5 = 8 [phi:print_vera_led->print_chip_led#0] -- vbuz1=vbuc1 
    lda #8
    sta.z print_chip_led.w
    // [1963] phi print_chip_led::tc#3 = print_chip_led::tc#1 [phi:print_vera_led->print_chip_led#1] -- register_copy 
    // [1963] phi print_chip_led::x#3 = 9+1 [phi:print_vera_led->print_chip_led#2] -- vbuz1=vbuc1 
    lda #9+1
    sta.z print_chip_led.x
    jsr print_chip_led
    // print_vera_led::@return
    // }
    // [1568] return 
    rts
}
  // strcat
// Concatenates the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcat(char *destination, __zp($f1) char *source)
strcat: {
    .label strcat__0 = $ab
    .label dst = $ab
    .label src = $f1
    .label source = $f1
    // strlen(destination)
    // [1570] call strlen
    // [1790] phi from strcat to strlen [phi:strcat->strlen]
    // [1790] phi strlen::str#8 = chip_rom::rom [phi:strcat->strlen#0] -- pbuz1=pbuc1 
    lda #<chip_rom.rom
    sta.z strlen.str
    lda #>chip_rom.rom
    sta.z strlen.str+1
    jsr strlen
    // strlen(destination)
    // [1571] strlen::return#0 = strlen::len#2
    // strcat::@4
    // [1572] strcat::$0 = strlen::return#0
    // char* dst = destination + strlen(destination)
    // [1573] strcat::dst#0 = chip_rom::rom + strcat::$0 -- pbuz1=pbuc1_plus_vwuz1 
    lda.z dst
    clc
    adc #<chip_rom.rom
    sta.z dst
    lda.z dst+1
    adc #>chip_rom.rom
    sta.z dst+1
    // [1574] phi from strcat::@2 strcat::@4 to strcat::@1 [phi:strcat::@2/strcat::@4->strcat::@1]
    // [1574] phi strcat::dst#2 = strcat::dst#1 [phi:strcat::@2/strcat::@4->strcat::@1#0] -- register_copy 
    // [1574] phi strcat::src#2 = strcat::src#1 [phi:strcat::@2/strcat::@4->strcat::@1#1] -- register_copy 
    // strcat::@1
  __b1:
    // while(*src)
    // [1575] if(0!=*strcat::src#2) goto strcat::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcat::@3
    // *dst = 0
    // [1576] *strcat::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcat::@return
    // }
    // [1577] return 
    rts
    // strcat::@2
  __b2:
    // *dst++ = *src++
    // [1578] *strcat::dst#2 = *strcat::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [1579] strcat::dst#1 = ++ strcat::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [1580] strcat::src#1 = ++ strcat::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    jmp __b1
}
  // print_rom_led
// void print_rom_led(__zp($d6) char chip, __zp($c6) char c)
print_rom_led: {
    .label print_rom_led__0 = $d6
    .label chip = $d6
    .label c = $c6
    .label print_rom_led__4 = $d7
    .label print_rom_led__5 = $d6
    // chip*6
    // [1582] print_rom_led::$4 = print_rom_led::chip#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z chip
    asl
    sta.z print_rom_led__4
    // [1583] print_rom_led::$5 = print_rom_led::$4 + print_rom_led::chip#2 -- vbuz1=vbuz2_plus_vbuz1 
    lda.z print_rom_led__5
    clc
    adc.z print_rom_led__4
    sta.z print_rom_led__5
    // CHIP_ROM_X+chip*6
    // [1584] print_rom_led::$0 = print_rom_led::$5 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z print_rom_led__0
    // print_chip_led(CHIP_ROM_X+chip*6+1, CHIP_ROM_Y, CHIP_ROM_W, c, BLUE)
    // [1585] print_chip_led::x#2 = print_rom_led::$0 + $14+1 -- vbuz1=vbuz1_plus_vbuc1 
    lda #$14+1
    clc
    adc.z print_chip_led.x
    sta.z print_chip_led.x
    // [1586] print_chip_led::tc#2 = print_rom_led::c#2
    // [1587] call print_chip_led
    // [1963] phi from print_rom_led to print_chip_led [phi:print_rom_led->print_chip_led]
    // [1963] phi print_chip_led::w#5 = 3 [phi:print_rom_led->print_chip_led#0] -- vbuz1=vbuc1 
    lda #3
    sta.z print_chip_led.w
    // [1963] phi print_chip_led::tc#3 = print_chip_led::tc#2 [phi:print_rom_led->print_chip_led#1] -- register_copy 
    // [1963] phi print_chip_led::x#3 = print_chip_led::x#2 [phi:print_rom_led->print_chip_led#2] -- register_copy 
    jsr print_chip_led
    // print_rom_led::@return
    // }
    // [1588] return 
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
// __zp($bc) struct $2 * fopen(__zp($d4) const char *path, const char *mode)
fopen: {
    .label fopen__4 = $ce
    .label fopen__9 = $36
    .label fopen__15 = $79
    .label fopen__26 = $b4
    .label fopen__28 = $f8
    .label fopen__30 = $bc
    .label cbm_k_setnam1_fopen__0 = $ab
    .label sp = $de
    .label stream = $bc
    .label pathtoken = $d4
    .label pathpos = $d6
    .label pathpos_1 = $53
    .label pathcmp = $7f
    .label path = $d4
    // Parse path
    .label pathstep = $da
    .label num = $fa
    .label cbm_k_readst1_return = $79
    .label return = $bc
    // unsigned char sp = __stdio_filecount
    // [1590] fopen::sp#0 = __stdio_filecount -- vbuz1=vbum2 
    lda __stdio_filecount
    sta.z sp
    // (unsigned int)sp | 0x8000
    // [1591] fopen::$30 = (unsigned int)fopen::sp#0 -- vwuz1=_word_vbuz2 
    sta.z fopen__30
    lda #0
    sta.z fopen__30+1
    // [1592] fopen::stream#0 = fopen::$30 | $8000 -- vwuz1=vwuz1_bor_vwuc1 
    lda.z stream
    ora #<$8000
    sta.z stream
    lda.z stream+1
    ora #>$8000
    sta.z stream+1
    // char pathpos = sp * __STDIO_FILECOUNT
    // [1593] fopen::pathpos#0 = fopen::sp#0 << 3 -- vbuz1=vbuz2_rol_3 
    lda.z sp
    asl
    asl
    asl
    sta.z pathpos
    // __logical = 0
    // [1594] ((char *)&__stdio_file+$100)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    ldy.z sp
    sta __stdio_file+$100,y
    // __device = 0
    // [1595] ((char *)&__stdio_file+$108)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$108,y
    // __channel = 0
    // [1596] ((char *)&__stdio_file+$110)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$110,y
    // [1597] fopen::pathtoken#21 = fopen::pathtoken#0 -- pbum1=pbuz2 
    lda.z pathtoken
    sta pathtoken_1
    lda.z pathtoken+1
    sta pathtoken_1+1
    // [1598] fopen::pathpos#21 = fopen::pathpos#0 -- vbuz1=vbuz2 
    lda.z pathpos
    sta.z pathpos_1
    // [1599] phi from fopen to fopen::@8 [phi:fopen->fopen::@8]
    // [1599] phi fopen::num#10 = 0 [phi:fopen->fopen::@8#0] -- vbuz1=vbuc1 
    lda #0
    sta.z num
    // [1599] phi fopen::pathpos#10 = fopen::pathpos#21 [phi:fopen->fopen::@8#1] -- register_copy 
    // [1599] phi fopen::path#10 = fopen::pathtoken#0 [phi:fopen->fopen::@8#2] -- register_copy 
    // [1599] phi fopen::pathstep#10 = 0 [phi:fopen->fopen::@8#3] -- vbuz1=vbuc1 
    sta.z pathstep
    // [1599] phi fopen::pathtoken#10 = fopen::pathtoken#21 [phi:fopen->fopen::@8#4] -- register_copy 
  // Iterate while path is not \0.
    // [1599] phi from fopen::@22 to fopen::@8 [phi:fopen::@22->fopen::@8]
    // [1599] phi fopen::num#10 = fopen::num#13 [phi:fopen::@22->fopen::@8#0] -- register_copy 
    // [1599] phi fopen::pathpos#10 = fopen::pathpos#7 [phi:fopen::@22->fopen::@8#1] -- register_copy 
    // [1599] phi fopen::path#10 = fopen::path#11 [phi:fopen::@22->fopen::@8#2] -- register_copy 
    // [1599] phi fopen::pathstep#10 = fopen::pathstep#11 [phi:fopen::@22->fopen::@8#3] -- register_copy 
    // [1599] phi fopen::pathtoken#10 = fopen::pathtoken#1 [phi:fopen::@22->fopen::@8#4] -- register_copy 
    // fopen::@8
  __b8:
    // if (*pathtoken == ',' || *pathtoken == '\0')
    // [1600] if(*fopen::pathtoken#10==',') goto fopen::@9 -- _deref_pbum1_eq_vbuc1_then_la1 
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
    // [1601] if(*fopen::pathtoken#10=='@') goto fopen::@9 -- _deref_pbum1_eq_vbuc1_then_la1 
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
    // [1602] if(fopen::pathstep#10!=0) goto fopen::@10 -- vbuz1_neq_0_then_la1 
    lda.z pathstep
    bne __b10
    // fopen::@24
    // __stdio_file.filename[pathpos] = *pathtoken
    // [1603] ((char *)&__stdio_file)[fopen::pathpos#10] = *fopen::pathtoken#10 -- pbuc1_derefidx_vbuz1=_deref_pbum2 
    ldy pathtoken_1
    sty.z $fe
    ldy pathtoken_1+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    ldy.z pathpos_1
    sta __stdio_file,y
    // pathpos++;
    // [1604] fopen::pathpos#1 = ++ fopen::pathpos#10 -- vbuz1=_inc_vbuz1 
    inc.z pathpos_1
    // [1605] phi from fopen::@12 fopen::@23 fopen::@24 to fopen::@10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10]
    // [1605] phi fopen::num#13 = fopen::num#15 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#0] -- register_copy 
    // [1605] phi fopen::pathpos#7 = fopen::pathpos#10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#1] -- register_copy 
    // [1605] phi fopen::path#11 = fopen::path#13 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#2] -- register_copy 
    // [1605] phi fopen::pathstep#11 = fopen::pathstep#1 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#3] -- register_copy 
    // fopen::@10
  __b10:
    // pathtoken++;
    // [1606] fopen::pathtoken#1 = ++ fopen::pathtoken#10 -- pbum1=_inc_pbum1 
    inc pathtoken_1
    bne !+
    inc pathtoken_1+1
  !:
    // fopen::@22
    // pathtoken - 1
    // [1607] fopen::$28 = fopen::pathtoken#1 - 1 -- pbuz1=pbum2_minus_1 
    lda pathtoken_1
    sec
    sbc #1
    sta.z fopen__28
    lda pathtoken_1+1
    sbc #0
    sta.z fopen__28+1
    // while (*(pathtoken - 1))
    // [1608] if(0!=*fopen::$28) goto fopen::@8 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (fopen__28),y
    cmp #0
    bne __b8
    // fopen::@26
    // __status = 0
    // [1609] ((char *)&__stdio_file+$118)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    tya
    ldy.z sp
    sta __stdio_file+$118,y
    // if(!__logical)
    // [1610] if(0!=((char *)&__stdio_file+$100)[fopen::sp#0]) goto fopen::@1 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$100,y
    cmp #0
    bne __b1
    // fopen::@27
    // __stdio_filecount+1
    // [1611] fopen::$4 = __stdio_filecount + 1 -- vbuz1=vbum2_plus_1 
    lda __stdio_filecount
    inc
    sta.z fopen__4
    // __logical = __stdio_filecount+1
    // [1612] ((char *)&__stdio_file+$100)[fopen::sp#0] = fopen::$4 -- pbuc1_derefidx_vbuz1=vbuz2 
    sta __stdio_file+$100,y
    // fopen::@1
  __b1:
    // if(!__device)
    // [1613] if(0!=((char *)&__stdio_file+$108)[fopen::sp#0]) goto fopen::@2 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    ldy.z sp
    lda __stdio_file+$108,y
    cmp #0
    bne __b2
    // fopen::@5
    // __device = 8
    // [1614] ((char *)&__stdio_file+$108)[fopen::sp#0] = 8 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #8
    sta __stdio_file+$108,y
    // fopen::@2
  __b2:
    // if(!__channel)
    // [1615] if(0!=((char *)&__stdio_file+$110)[fopen::sp#0]) goto fopen::@3 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    ldy.z sp
    lda __stdio_file+$110,y
    cmp #0
    bne __b3
    // fopen::@6
    // __stdio_filecount+2
    // [1616] fopen::$9 = __stdio_filecount + 2 -- vbuz1=vbum2_plus_2 
    lda __stdio_filecount
    clc
    adc #2
    sta.z fopen__9
    // __channel = __stdio_filecount+2
    // [1617] ((char *)&__stdio_file+$110)[fopen::sp#0] = fopen::$9 -- pbuc1_derefidx_vbuz1=vbuz2 
    sta __stdio_file+$110,y
    // fopen::@3
  __b3:
    // __filename
    // [1618] fopen::$11 = (char *)&__stdio_file + fopen::pathpos#0 -- pbum1=pbuc1_plus_vbuz2 
    lda.z pathpos
    clc
    adc #<__stdio_file
    sta fopen__11
    lda #>__stdio_file
    adc #0
    sta fopen__11+1
    // cbm_k_setnam(__filename)
    // [1619] fopen::cbm_k_setnam1_filename = fopen::$11 -- pbum1=pbum2 
    lda fopen__11
    sta cbm_k_setnam1_filename
    lda fopen__11+1
    sta cbm_k_setnam1_filename+1
    // fopen::cbm_k_setnam1
    // strlen(filename)
    // [1620] strlen::str#4 = fopen::cbm_k_setnam1_filename -- pbuz1=pbum2 
    lda cbm_k_setnam1_filename
    sta.z strlen.str
    lda cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [1621] call strlen
    // [1790] phi from fopen::cbm_k_setnam1 to strlen [phi:fopen::cbm_k_setnam1->strlen]
    // [1790] phi strlen::str#8 = strlen::str#4 [phi:fopen::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [1622] strlen::return#11 = strlen::len#2
    // fopen::@31
    // [1623] fopen::cbm_k_setnam1_$0 = strlen::return#11
    // char filename_len = (char)strlen(filename)
    // [1624] fopen::cbm_k_setnam1_filename_len = (char)fopen::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
    lda.z cbm_k_setnam1_fopen__0
    sta cbm_k_setnam1_filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx cbm_k_setnam1_filename
    ldy cbm_k_setnam1_filename+1
    jsr CBM_SETNAM
    // fopen::@28
    // cbm_k_setlfs(__logical, __device, __channel)
    // [1626] cbm_k_setlfs::channel = ((char *)&__stdio_file+$100)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$100,y
    sta cbm_k_setlfs.channel
    // [1627] cbm_k_setlfs::device = ((char *)&__stdio_file+$108)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    lda __stdio_file+$108,y
    sta cbm_k_setlfs.device
    // [1628] cbm_k_setlfs::command = ((char *)&__stdio_file+$110)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    lda __stdio_file+$110,y
    sta cbm_k_setlfs.command
    // [1629] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // fopen::cbm_k_open1
    // asm
    // asm { jsrCBM_OPEN  }
    jsr CBM_OPEN
    // fopen::cbm_k_readst1
    // char status
    // [1631] fopen::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [1633] fopen::cbm_k_readst1_return#0 = fopen::cbm_k_readst1_status -- vbuz1=vbum2 
    sta.z cbm_k_readst1_return
    // fopen::cbm_k_readst1_@return
    // }
    // [1634] fopen::cbm_k_readst1_return#1 = fopen::cbm_k_readst1_return#0
    // fopen::@29
    // cbm_k_readst()
    // [1635] fopen::$15 = fopen::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [1636] ((char *)&__stdio_file+$118)[fopen::sp#0] = fopen::$15 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fopen__15
    ldy.z sp
    sta __stdio_file+$118,y
    // ferror(stream)
    // [1637] ferror::stream#0 = (struct $2 *)fopen::stream#0
    // [1638] call ferror
    jsr ferror
    // [1639] ferror::return#0 = ferror::return#1
    // fopen::@32
    // [1640] fopen::$16 = ferror::return#0
    // if (ferror(stream))
    // [1641] if(0==fopen::$16) goto fopen::@4 -- 0_eq_vwsm1_then_la1 
    lda fopen__16
    ora fopen__16+1
    beq __b4
    // fopen::@7
    // cbm_k_close(__logical)
    // [1642] fopen::cbm_k_close1_channel = ((char *)&__stdio_file+$100)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$100,y
    sta cbm_k_close1_channel
    // fopen::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // [1644] phi from fopen::cbm_k_close1 to fopen::@return [phi:fopen::cbm_k_close1->fopen::@return]
    // [1644] phi fopen::return#2 = 0 [phi:fopen::cbm_k_close1->fopen::@return#0] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [1645] return 
    rts
    // fopen::@4
  __b4:
    // __stdio_filecount++;
    // [1646] __stdio_filecount = ++ __stdio_filecount -- vbum1=_inc_vbum1 
    inc __stdio_filecount
    // [1647] fopen::return#8 = (struct $2 *)fopen::stream#0
    // [1644] phi from fopen::@4 to fopen::@return [phi:fopen::@4->fopen::@return]
    // [1644] phi fopen::return#2 = fopen::return#8 [phi:fopen::@4->fopen::@return#0] -- register_copy 
    rts
    // fopen::@9
  __b9:
    // if (pathstep > 0)
    // [1648] if(fopen::pathstep#10>0) goto fopen::@11 -- vbuz1_gt_0_then_la1 
    lda.z pathstep
    bne __b11
    // fopen::@25
    // __stdio_file.filename[pathpos] = '\0'
    // [1649] ((char *)&__stdio_file)[fopen::pathpos#10] = '@' -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #'@'
    ldy.z pathpos_1
    sta __stdio_file,y
    // path = pathtoken + 1
    // [1650] fopen::path#0 = fopen::pathtoken#10 + 1 -- pbuz1=pbum2_plus_1 
    clc
    lda pathtoken_1
    adc #1
    sta.z path
    lda pathtoken_1+1
    adc #0
    sta.z path+1
    // [1651] phi from fopen::@16 fopen::@17 fopen::@18 fopen::@19 fopen::@25 to fopen::@12 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12]
    // [1651] phi fopen::num#15 = fopen::num#2 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#0] -- register_copy 
    // [1651] phi fopen::path#13 = fopen::path#16 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#1] -- register_copy 
    // fopen::@12
  __b12:
    // pathstep++;
    // [1652] fopen::pathstep#1 = ++ fopen::pathstep#10 -- vbuz1=_inc_vbuz1 
    inc.z pathstep
    jmp __b10
    // fopen::@11
  __b11:
    // char pathcmp = *path
    // [1653] fopen::pathcmp#0 = *fopen::path#10 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (path),y
    sta.z pathcmp
    // case 'D':
    // [1654] if(fopen::pathcmp#0=='D') goto fopen::@13 -- vbuz1_eq_vbuc1_then_la1 
    lda #'D'
    cmp.z pathcmp
    beq __b13
    // fopen::@20
    // case 'L':
    // [1655] if(fopen::pathcmp#0=='L') goto fopen::@13 -- vbuz1_eq_vbuc1_then_la1 
    lda #'L'
    cmp.z pathcmp
    beq __b13
    // fopen::@21
    // case 'C':
    //                     num = (char)atoi(path + 1);
    //                     path = pathtoken + 1;
    // [1656] if(fopen::pathcmp#0=='C') goto fopen::@13 -- vbuz1_eq_vbuc1_then_la1 
    lda #'C'
    cmp.z pathcmp
    beq __b13
    // [1657] phi from fopen::@21 fopen::@30 to fopen::@14 [phi:fopen::@21/fopen::@30->fopen::@14]
    // [1657] phi fopen::path#16 = fopen::path#10 [phi:fopen::@21/fopen::@30->fopen::@14#0] -- register_copy 
    // [1657] phi fopen::num#2 = fopen::num#10 [phi:fopen::@21/fopen::@30->fopen::@14#1] -- register_copy 
    // fopen::@14
  __b14:
    // case 'L':
    //                     __logical = num;
    //                     break;
    // [1658] if(fopen::pathcmp#0=='L') goto fopen::@17 -- vbuz1_eq_vbuc1_then_la1 
    lda #'L'
    cmp.z pathcmp
    beq __b17
    // fopen::@15
    // case 'D':
    //                     __device = num;
    //                     break;
    // [1659] if(fopen::pathcmp#0=='D') goto fopen::@18 -- vbuz1_eq_vbuc1_then_la1 
    lda #'D'
    cmp.z pathcmp
    beq __b18
    // fopen::@16
    // case 'C':
    //                     __channel = num;
    //                     break;
    // [1660] if(fopen::pathcmp#0!='C') goto fopen::@12 -- vbuz1_neq_vbuc1_then_la1 
    lda #'C'
    cmp.z pathcmp
    bne __b12
    // fopen::@19
    // __channel = num
    // [1661] ((char *)&__stdio_file+$110)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z num
    ldy.z sp
    sta __stdio_file+$110,y
    jmp __b12
    // fopen::@18
  __b18:
    // __device = num
    // [1662] ((char *)&__stdio_file+$108)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z num
    ldy.z sp
    sta __stdio_file+$108,y
    jmp __b12
    // fopen::@17
  __b17:
    // __logical = num
    // [1663] ((char *)&__stdio_file+$100)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z num
    ldy.z sp
    sta __stdio_file+$100,y
    jmp __b12
    // fopen::@13
  __b13:
    // atoi(path + 1)
    // [1664] atoi::str#0 = fopen::path#10 + 1 -- pbuz1=pbuz1_plus_1 
    inc.z atoi.str
    bne !+
    inc.z atoi.str+1
  !:
    // [1665] call atoi
    // [2103] phi from fopen::@13 to atoi [phi:fopen::@13->atoi]
    // [2103] phi atoi::str#2 = atoi::str#0 [phi:fopen::@13->atoi#0] -- register_copy 
    jsr atoi
    // atoi(path + 1)
    // [1666] atoi::return#3 = atoi::return#2
    // fopen::@30
    // [1667] fopen::$26 = atoi::return#3
    // num = (char)atoi(path + 1)
    // [1668] fopen::num#1 = (char)fopen::$26 -- vbuz1=_byte_vwsz2 
    lda.z fopen__26
    sta.z num
    // path = pathtoken + 1
    // [1669] fopen::path#1 = fopen::pathtoken#10 + 1 -- pbuz1=pbum2_plus_1 
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
// __zp($ad) unsigned int fgets(__zp($7a) char *ptr, __zp($cf) unsigned int size, __mem() struct $2 *stream)
fgets: {
    .label fgets__1 = $36
    .label fgets__8 = $79
    .label fgets__9 = $7f
    .label fgets__13 = $7e
    .label cbm_k_chkin1_channel = $fb
    .label cbm_k_chkin1_status = $f4
    .label cbm_k_readst1_status = $f5
    .label cbm_k_readst2_status = $af
    .label sp = $ce
    .label cbm_k_readst1_return = $36
    .label return = $ad
    .label bytes = $67
    .label cbm_k_readst2_return = $79
    .label read = $ad
    .label ptr = $7a
    .label remaining = $b8
    .label size = $cf
    // unsigned char sp = (unsigned char)stream
    // [1671] fgets::sp#0 = (char)fgets::stream#2 -- vbuz1=_byte_pssm2 
    lda stream
    sta.z sp
    // cbm_k_chkin(__logical)
    // [1672] fgets::cbm_k_chkin1_channel = ((char *)&__stdio_file+$100)[fgets::sp#0] -- vbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda __stdio_file+$100,y
    sta.z cbm_k_chkin1_channel
    // fgets::cbm_k_chkin1
    // char status
    // [1673] fgets::cbm_k_chkin1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fgets::cbm_k_readst1
    // char status
    // [1675] fgets::cbm_k_readst1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [1677] fgets::cbm_k_readst1_return#0 = fgets::cbm_k_readst1_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst1_return
    // fgets::cbm_k_readst1_@return
    // }
    // [1678] fgets::cbm_k_readst1_return#1 = fgets::cbm_k_readst1_return#0
    // fgets::@11
    // cbm_k_readst()
    // [1679] fgets::$1 = fgets::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [1680] ((char *)&__stdio_file+$118)[fgets::sp#0] = fgets::$1 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fgets__1
    ldy.z sp
    sta __stdio_file+$118,y
    // if (__status)
    // [1681] if(0==((char *)&__stdio_file+$118)[fgets::sp#0]) goto fgets::@1 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$118,y
    cmp #0
    beq __b1
    // [1682] phi from fgets::@11 fgets::@12 fgets::@5 to fgets::@return [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return]
  __b8:
    // [1682] phi fgets::return#1 = 0 [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return#0] -- vwuz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fgets::@return
    // }
    // [1683] return 
    rts
    // fgets::@1
  __b1:
    // [1684] fgets::remaining#22 = fgets::size#10 -- vwuz1=vwuz2 
    lda.z size
    sta.z remaining
    lda.z size+1
    sta.z remaining+1
    // [1685] phi from fgets::@1 to fgets::@2 [phi:fgets::@1->fgets::@2]
    // [1685] phi fgets::read#10 = 0 [phi:fgets::@1->fgets::@2#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z read
    sta.z read+1
    // [1685] phi fgets::remaining#11 = fgets::remaining#22 [phi:fgets::@1->fgets::@2#1] -- register_copy 
    // [1685] phi fgets::ptr#10 = fgets::ptr#12 [phi:fgets::@1->fgets::@2#2] -- register_copy 
    // [1685] phi from fgets::@17 fgets::@18 to fgets::@2 [phi:fgets::@17/fgets::@18->fgets::@2]
    // [1685] phi fgets::read#10 = fgets::read#1 [phi:fgets::@17/fgets::@18->fgets::@2#0] -- register_copy 
    // [1685] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@17/fgets::@18->fgets::@2#1] -- register_copy 
    // [1685] phi fgets::ptr#10 = fgets::ptr#13 [phi:fgets::@17/fgets::@18->fgets::@2#2] -- register_copy 
    // fgets::@2
  __b2:
    // if (!size)
    // [1686] if(0==fgets::size#10) goto fgets::@3 -- 0_eq_vwuz1_then_la1 
    lda.z size
    ora.z size+1
    bne !__b3+
    jmp __b3
  !__b3:
    // fgets::@8
    // if (remaining >= 512)
    // [1687] if(fgets::remaining#11>=$200) goto fgets::@4 -- vwuz1_ge_vwuc1_then_la1 
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
    // [1688] cx16_k_macptr::bytes = fgets::remaining#11 -- vbuz1=vwuz2 
    lda.z remaining
    sta.z cx16_k_macptr.bytes
    // [1689] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [1690] call cx16_k_macptr
    jsr cx16_k_macptr
    // [1691] cx16_k_macptr::return#4 = cx16_k_macptr::return#1
    // fgets::@15
  __b15:
    // bytes = cx16_k_macptr(remaining, ptr)
    // [1692] fgets::bytes#3 = cx16_k_macptr::return#4
    // [1693] phi from fgets::@13 fgets::@14 fgets::@15 to fgets::cbm_k_readst2 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2]
    // [1693] phi fgets::bytes#10 = fgets::bytes#1 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2#0] -- register_copy 
    // fgets::cbm_k_readst2
    // char status
    // [1694] fgets::cbm_k_readst2_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [1696] fgets::cbm_k_readst2_return#0 = fgets::cbm_k_readst2_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst2_return
    // fgets::cbm_k_readst2_@return
    // }
    // [1697] fgets::cbm_k_readst2_return#1 = fgets::cbm_k_readst2_return#0
    // fgets::@12
    // cbm_k_readst()
    // [1698] fgets::$8 = fgets::cbm_k_readst2_return#1
    // __status = cbm_k_readst()
    // [1699] ((char *)&__stdio_file+$118)[fgets::sp#0] = fgets::$8 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fgets__8
    ldy.z sp
    sta __stdio_file+$118,y
    // __status & 0xBF
    // [1700] fgets::$9 = ((char *)&__stdio_file+$118)[fgets::sp#0] & $bf -- vbuz1=pbuc1_derefidx_vbuz2_band_vbuc2 
    lda #$bf
    and __stdio_file+$118,y
    sta.z fgets__9
    // if (__status & 0xBF)
    // [1701] if(0==fgets::$9) goto fgets::@5 -- 0_eq_vbuz1_then_la1 
    beq __b5
    jmp __b8
    // fgets::@5
  __b5:
    // if (bytes == 0xFFFF)
    // [1702] if(fgets::bytes#10!=$ffff) goto fgets::@6 -- vwuz1_neq_vwuc1_then_la1 
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
    // [1703] fgets::read#1 = fgets::read#10 + fgets::bytes#10 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z read
    adc.z bytes
    sta.z read
    lda.z read+1
    adc.z bytes+1
    sta.z read+1
    // ptr += bytes
    // [1704] fgets::ptr#0 = fgets::ptr#10 + fgets::bytes#10 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z ptr
    adc.z bytes
    sta.z ptr
    lda.z ptr+1
    adc.z bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [1705] fgets::$13 = byte1  fgets::ptr#0 -- vbuz1=_byte1_pbuz2 
    sta.z fgets__13
    // if (BYTE1(ptr) == 0xC0)
    // [1706] if(fgets::$13!=$c0) goto fgets::@7 -- vbuz1_neq_vbuc1_then_la1 
    lda #$c0
    cmp.z fgets__13
    bne __b7
    // fgets::@10
    // ptr -= 0x2000
    // [1707] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [1708] phi from fgets::@10 fgets::@6 to fgets::@7 [phi:fgets::@10/fgets::@6->fgets::@7]
    // [1708] phi fgets::ptr#13 = fgets::ptr#1 [phi:fgets::@10/fgets::@6->fgets::@7#0] -- register_copy 
    // fgets::@7
  __b7:
    // remaining -= bytes
    // [1709] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#10 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z remaining
    sec
    sbc.z bytes
    sta.z remaining
    lda.z remaining+1
    sbc.z bytes+1
    sta.z remaining+1
    // while ((__status == 0) && ((size && remaining) || !size))
    // [1710] if(((char *)&__stdio_file+$118)[fgets::sp#0]==0) goto fgets::@16 -- pbuc1_derefidx_vbuz1_eq_0_then_la1 
    ldy.z sp
    lda __stdio_file+$118,y
    cmp #0
    beq __b16
    // [1682] phi from fgets::@17 fgets::@7 to fgets::@return [phi:fgets::@17/fgets::@7->fgets::@return]
    // [1682] phi fgets::return#1 = fgets::read#1 [phi:fgets::@17/fgets::@7->fgets::@return#0] -- register_copy 
    rts
    // fgets::@16
  __b16:
    // while ((__status == 0) && ((size && remaining) || !size))
    // [1711] if(0==fgets::size#10) goto fgets::@17 -- 0_eq_vwuz1_then_la1 
    lda.z size
    ora.z size+1
    beq __b17
    // fgets::@18
    // [1712] if(0!=fgets::remaining#1) goto fgets::@2 -- 0_neq_vwuz1_then_la1 
    lda.z remaining
    ora.z remaining+1
    beq !__b2+
    jmp __b2
  !__b2:
    // fgets::@17
  __b17:
    // [1713] if(0==fgets::size#10) goto fgets::@2 -- 0_eq_vwuz1_then_la1 
    lda.z size
    ora.z size+1
    bne !__b2+
    jmp __b2
  !__b2:
    rts
    // fgets::@4
  __b4:
    // cx16_k_macptr(512, ptr)
    // [1714] cx16_k_macptr::bytes = $200 -- vbuz1=vwuc1 
    lda #<$200
    sta.z cx16_k_macptr.bytes
    // [1715] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [1716] call cx16_k_macptr
    jsr cx16_k_macptr
    // [1717] cx16_k_macptr::return#3 = cx16_k_macptr::return#1
    // fgets::@14
    // bytes = cx16_k_macptr(512, ptr)
    // [1718] fgets::bytes#2 = cx16_k_macptr::return#3
    jmp __b15
    // fgets::@3
  __b3:
    // cx16_k_macptr(0, ptr)
    // [1719] cx16_k_macptr::bytes = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cx16_k_macptr.bytes
    // [1720] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [1721] call cx16_k_macptr
    jsr cx16_k_macptr
    // [1722] cx16_k_macptr::return#2 = cx16_k_macptr::return#1
    // fgets::@13
    // bytes = cx16_k_macptr(0, ptr)
    // [1723] fgets::bytes#1 = cx16_k_macptr::return#2
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
// int fclose(__zp($bc) struct $2 *stream)
fclose: {
    .label fclose__1 = $ba
    .label fclose__4 = $43
    .label fclose__6 = $7e
    .label sp = $7e
    .label cbm_k_readst1_return = $ba
    .label cbm_k_readst2_return = $43
    .label stream = $bc
    // unsigned char sp = (unsigned char)stream
    // [1725] fclose::sp#0 = (char)fclose::stream#2 -- vbuz1=_byte_pssz2 
    lda.z stream
    sta.z sp
    // cbm_k_chkin(__logical)
    // [1726] fclose::cbm_k_chkin1_channel = ((char *)&__stdio_file+$100)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    tay
    lda __stdio_file+$100,y
    sta cbm_k_chkin1_channel
    // fclose::cbm_k_chkin1
    // char status
    // [1727] fclose::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fclose::cbm_k_readst1
    // char status
    // [1729] fclose::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [1731] fclose::cbm_k_readst1_return#0 = fclose::cbm_k_readst1_status -- vbuz1=vbum2 
    sta.z cbm_k_readst1_return
    // fclose::cbm_k_readst1_@return
    // }
    // [1732] fclose::cbm_k_readst1_return#1 = fclose::cbm_k_readst1_return#0
    // fclose::@3
    // cbm_k_readst()
    // [1733] fclose::$1 = fclose::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [1734] ((char *)&__stdio_file+$118)[fclose::sp#0] = fclose::$1 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fclose__1
    ldy.z sp
    sta __stdio_file+$118,y
    // if (__status)
    // [1735] if(0==((char *)&__stdio_file+$118)[fclose::sp#0]) goto fclose::@1 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$118,y
    cmp #0
    beq __b1
    // fclose::@return
    // }
    // [1736] return 
    rts
    // fclose::@1
  __b1:
    // cbm_k_close(__logical)
    // [1737] fclose::cbm_k_close1_channel = ((char *)&__stdio_file+$100)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$100,y
    sta cbm_k_close1_channel
    // fclose::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // fclose::cbm_k_readst2
    // char status
    // [1739] fclose::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [1741] fclose::cbm_k_readst2_return#0 = fclose::cbm_k_readst2_status -- vbuz1=vbum2 
    sta.z cbm_k_readst2_return
    // fclose::cbm_k_readst2_@return
    // }
    // [1742] fclose::cbm_k_readst2_return#1 = fclose::cbm_k_readst2_return#0
    // fclose::@4
    // cbm_k_readst()
    // [1743] fclose::$4 = fclose::cbm_k_readst2_return#1
    // __status = cbm_k_readst()
    // [1744] ((char *)&__stdio_file+$118)[fclose::sp#0] = fclose::$4 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fclose__4
    ldy.z sp
    sta __stdio_file+$118,y
    // if (__status)
    // [1745] if(0==((char *)&__stdio_file+$118)[fclose::sp#0]) goto fclose::@2 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$118,y
    cmp #0
    beq __b2
    rts
    // fclose::@2
  __b2:
    // __logical = 0
    // [1746] ((char *)&__stdio_file+$100)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    ldy.z sp
    sta __stdio_file+$100,y
    // __device = 0
    // [1747] ((char *)&__stdio_file+$108)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$108,y
    // __channel = 0
    // [1748] ((char *)&__stdio_file+$110)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$110,y
    // __filename
    // [1749] fclose::$6 = fclose::sp#0 << 3 -- vbuz1=vbuz1_rol_3 
    lda.z fclose__6
    asl
    asl
    asl
    sta.z fclose__6
    // *__filename = '\0'
    // [1750] ((char *)&__stdio_file)[fclose::$6] = '@' -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #'@'
    ldy.z fclose__6
    sta __stdio_file,y
    // __stdio_filecount--;
    // [1751] __stdio_filecount = -- __stdio_filecount -- vbum1=_dec_vbum1 
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
  // cbm_k_getin
/**
 * @brief Scan a character from keyboard without pressing enter.
 * 
 * @return char The character read.
 */
cbm_k_getin: {
    // __mem unsigned char ch
    // [1752] cbm_k_getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsrCBM_GETIN stach  }
    jsr CBM_GETIN
    sta ch
    // return ch;
    // [1754] cbm_k_getin::return#0 = cbm_k_getin::ch -- vbum1=vbum2 
    sta return
    // cbm_k_getin::@return
    // }
    // [1755] cbm_k_getin::return#1 = cbm_k_getin::return#0
    // [1756] return 
    rts
  .segment Data
    ch: .byte 0
    .label return = wherex.return_1
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
// __zp($48) unsigned int cx16_k_i2c_read_byte(__mem() volatile char device, __mem() volatile char offset)
cx16_k_i2c_read_byte: {
    .label return = $48
    // unsigned int result
    // [1757] cx16_k_i2c_read_byte::result = 0 -- vwum1=vwuc1 
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
    // [1759] cx16_k_i2c_read_byte::return#0 = cx16_k_i2c_read_byte::result -- vwuz1=vwum2 
    sta.z return
    lda result+1
    sta.z return+1
    // cx16_k_i2c_read_byte::@return
    // }
    // [1760] cx16_k_i2c_read_byte::return#1 = cx16_k_i2c_read_byte::return#0
    // [1761] return 
    rts
  .segment Data
    device: .byte 0
    offset: .byte 0
    result: .word 0
}
.segment Code
  // uctoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void uctoa(__zp($36) char value, __zp($bc) char *buffer, __zp($e5) char radix)
uctoa: {
    .label uctoa__4 = $ba
    .label digit_value = $43
    .label buffer = $bc
    .label digit = $24
    .label value = $36
    .label radix = $e5
    .label started = $be
    .label max_digits = $29
    .label digit_values = $7c
    // if(radix==DECIMAL)
    // [1762] if(uctoa::radix#0==DECIMAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp.z radix
    beq __b2
    // uctoa::@2
    // if(radix==HEXADECIMAL)
    // [1763] if(uctoa::radix#0==HEXADECIMAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp.z radix
    beq __b3
    // uctoa::@3
    // if(radix==OCTAL)
    // [1764] if(uctoa::radix#0==OCTAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp.z radix
    beq __b4
    // uctoa::@4
    // if(radix==BINARY)
    // [1765] if(uctoa::radix#0==BINARY) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp.z radix
    beq __b5
    // uctoa::@5
    // *buffer++ = 'e'
    // [1766] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1767] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1768] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1769] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // uctoa::@return
    // }
    // [1770] return 
    rts
    // [1771] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
  __b2:
    // [1771] phi uctoa::digit_values#8 = RADIX_DECIMAL_VALUES_CHAR [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1771] phi uctoa::max_digits#7 = 3 [phi:uctoa->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [1771] phi from uctoa::@2 to uctoa::@1 [phi:uctoa::@2->uctoa::@1]
  __b3:
    // [1771] phi uctoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_CHAR [phi:uctoa::@2->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1771] phi uctoa::max_digits#7 = 2 [phi:uctoa::@2->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #2
    sta.z max_digits
    jmp __b1
    // [1771] phi from uctoa::@3 to uctoa::@1 [phi:uctoa::@3->uctoa::@1]
  __b4:
    // [1771] phi uctoa::digit_values#8 = RADIX_OCTAL_VALUES_CHAR [phi:uctoa::@3->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values+1
    // [1771] phi uctoa::max_digits#7 = 3 [phi:uctoa::@3->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [1771] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
  __b5:
    // [1771] phi uctoa::digit_values#8 = RADIX_BINARY_VALUES_CHAR [phi:uctoa::@4->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_BINARY_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_CHAR
    sta.z digit_values+1
    // [1771] phi uctoa::max_digits#7 = 8 [phi:uctoa::@4->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #8
    sta.z max_digits
    // uctoa::@1
  __b1:
    // [1772] phi from uctoa::@1 to uctoa::@6 [phi:uctoa::@1->uctoa::@6]
    // [1772] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa::@1->uctoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1772] phi uctoa::started#2 = 0 [phi:uctoa::@1->uctoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [1772] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa::@1->uctoa::@6#2] -- register_copy 
    // [1772] phi uctoa::digit#2 = 0 [phi:uctoa::@1->uctoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // uctoa::@6
  __b6:
    // max_digits-1
    // [1773] uctoa::$4 = uctoa::max_digits#7 - 1 -- vbuz1=vbuz2_minus_1 
    ldx.z max_digits
    dex
    stx.z uctoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1774] if(uctoa::digit#2<uctoa::$4) goto uctoa::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z digit
    cmp.z uctoa__4
    bcc __b7
    // uctoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1775] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z value
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1776] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1777] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // uctoa::@7
  __b7:
    // unsigned char digit_value = digit_values[digit]
    // [1778] uctoa::digit_value#0 = uctoa::digit_values#8[uctoa::digit#2] -- vbuz1=pbuz2_derefidx_vbuz3 
    ldy.z digit
    lda (digit_values),y
    sta.z digit_value
    // if (started || value >= digit_value)
    // [1779] if(0!=uctoa::started#2) goto uctoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // uctoa::@12
    // [1780] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@10 -- vbuz1_ge_vbuz2_then_la1 
    lda.z value
    cmp.z digit_value
    bcs __b10
    // [1781] phi from uctoa::@12 to uctoa::@9 [phi:uctoa::@12->uctoa::@9]
    // [1781] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@12->uctoa::@9#0] -- register_copy 
    // [1781] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@12->uctoa::@9#1] -- register_copy 
    // [1781] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@12->uctoa::@9#2] -- register_copy 
    // uctoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1782] uctoa::digit#1 = ++ uctoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1772] phi from uctoa::@9 to uctoa::@6 [phi:uctoa::@9->uctoa::@6]
    // [1772] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@9->uctoa::@6#0] -- register_copy 
    // [1772] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@9->uctoa::@6#1] -- register_copy 
    // [1772] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@9->uctoa::@6#2] -- register_copy 
    // [1772] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@9->uctoa::@6#3] -- register_copy 
    jmp __b6
    // uctoa::@10
  __b10:
    // uctoa_append(buffer++, value, digit_value)
    // [1783] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [1784] uctoa_append::value#0 = uctoa::value#2
    // [1785] uctoa_append::sub#0 = uctoa::digit_value#0
    // [1786] call uctoa_append
    // [2124] phi from uctoa::@10 to uctoa_append [phi:uctoa::@10->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [1787] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@11
    // value = uctoa_append(buffer++, value, digit_value)
    // [1788] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [1789] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1781] phi from uctoa::@11 to uctoa::@9 [phi:uctoa::@11->uctoa::@9]
    // [1781] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@11->uctoa::@9#0] -- register_copy 
    // [1781] phi uctoa::started#4 = 1 [phi:uctoa::@11->uctoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [1781] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@11->uctoa::@9#2] -- register_copy 
    jmp __b9
}
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __zp($ab) unsigned int strlen(__zp($7c) char *str)
strlen: {
    .label return = $ab
    .label len = $ab
    .label str = $7c
    // [1791] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [1791] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z len
    sta.z len+1
    // [1791] phi strlen::str#6 = strlen::str#8 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [1792] if(0!=*strlen::str#6) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [1793] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [1794] strlen::len#1 = ++ strlen::len#2 -- vwuz1=_inc_vwuz1 
    inc.z len
    bne !+
    inc.z len+1
  !:
    // str++;
    // [1795] strlen::str#1 = ++ strlen::str#6 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [1791] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [1791] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [1791] phi strlen::str#6 = strlen::str#1 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
}
  // printf_padding
// Print a padding char a number of times
// void printf_padding(__zp($7c) void (*putc)(char), __zp($43) char pad, __zp($ba) char length)
printf_padding: {
    .label i = $4b
    .label putc = $7c
    .label length = $ba
    .label pad = $43
    // [1797] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [1797] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [1798] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z length
    bcc __b2
    // printf_padding::@return
    // }
    // [1799] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [1800] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbuz1 
    lda.z pad
    pha
    // [1801] callexecute *printf_padding::putc#7  -- call__deref_pprz1 
    jsr icall28
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [1803] printf_padding::i#1 = ++ printf_padding::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1797] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [1797] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
    jmp __b1
    // Outside Flow
  icall28:
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
// __mem() unsigned long rom_address_from_bank(__zp($bf) char rom_bank)
rom_address_from_bank: {
    .label rom_address_from_bank__1 = $37
    .label return = $37
    .label rom_bank = $bf
    .label return_1 = $6b
    // ((unsigned long)(rom_bank)) << 14
    // [1805] rom_address_from_bank::$1 = (unsigned long)rom_address_from_bank::rom_bank#3 -- vduz1=_dword_vbuz2 
    lda.z rom_bank
    sta.z rom_address_from_bank__1
    lda #0
    sta.z rom_address_from_bank__1+1
    sta.z rom_address_from_bank__1+2
    sta.z rom_address_from_bank__1+3
    // [1806] rom_address_from_bank::return#0 = rom_address_from_bank::$1 << $e -- vduz1=vduz1_rol_vbuc1 
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
    // [1807] return 
    rts
  .segment Data
    .label return_2 = main.rom_file_modulo
}
.segment Code
  // rom_compare
// __zp($69) unsigned int rom_compare(__zp($56) char bank_ram, __zp($71) char *ptr_ram, __zp($62) unsigned long rom_compare_address, __zp($ad) unsigned int rom_compare_size)
rom_compare: {
    .label rom_compare__5 = $66
    .label rom_bank1_rom_compare__0 = $e4
    .label rom_bank1_rom_compare__1 = $c5
    .label rom_bank1_rom_compare__2 = $e2
    .label rom_ptr1_rom_compare__0 = $60
    .label rom_ptr1_rom_compare__2 = $60
    .label bank_set_bram1_bank = $56
    .label rom_bank1_bank_unshifted = $e2
    .label rom_bank1_return = $df
    .label rom_ptr1_return = $60
    .label ptr_rom = $60
    .label ptr_ram = $71
    .label compared_bytes = $48
    /// Holds the amount of bytes actually verified between the ROM and the RAM.
    .label equal_bytes = $69
    .label bank_ram = $56
    .label rom_compare_address = $62
    .label return = $69
    .label rom_compare_size = $ad
    // rom_compare::bank_set_bram1
    // BRAM = bank
    // [1809] BRAM = rom_compare::bank_set_bram1_bank#0 -- vbuz1=vbuz2 
    lda.z bank_set_bram1_bank
    sta.z BRAM
    // rom_compare::rom_bank1
    // BYTE2(address)
    // [1810] rom_compare::rom_bank1_$0 = byte2  rom_compare::rom_compare_address#3 -- vbuz1=_byte2_vduz2 
    lda.z rom_compare_address+2
    sta.z rom_bank1_rom_compare__0
    // BYTE1(address)
    // [1811] rom_compare::rom_bank1_$1 = byte1  rom_compare::rom_compare_address#3 -- vbuz1=_byte1_vduz2 
    lda.z rom_compare_address+1
    sta.z rom_bank1_rom_compare__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [1812] rom_compare::rom_bank1_$2 = rom_compare::rom_bank1_$0 w= rom_compare::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_compare__0
    sta.z rom_bank1_rom_compare__2+1
    lda.z rom_bank1_rom_compare__1
    sta.z rom_bank1_rom_compare__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [1813] rom_compare::rom_bank1_bank_unshifted#0 = rom_compare::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [1814] rom_compare::rom_bank1_return#0 = byte1  rom_compare::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwuz2 
    lda.z rom_bank1_bank_unshifted+1
    sta.z rom_bank1_return
    // rom_compare::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [1815] rom_compare::rom_ptr1_$2 = (unsigned int)rom_compare::rom_compare_address#3 -- vwuz1=_word_vduz2 
    lda.z rom_compare_address
    sta.z rom_ptr1_rom_compare__2
    lda.z rom_compare_address+1
    sta.z rom_ptr1_rom_compare__2+1
    // [1816] rom_compare::rom_ptr1_$0 = rom_compare::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_compare__0
    and #<$3fff
    sta.z rom_ptr1_rom_compare__0
    lda.z rom_ptr1_rom_compare__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_compare__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [1817] rom_compare::rom_ptr1_return#0 = rom_compare::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_compare::bank_set_brom1
    // BROM = bank
    // [1818] BROM = rom_compare::rom_bank1_return#0 -- vbuz1=vbuz2 
    lda.z rom_bank1_return
    sta.z BROM
    // [1819] rom_compare::ptr_rom#9 = (char *)rom_compare::rom_ptr1_return#0
    // [1820] phi from rom_compare::bank_set_brom1 to rom_compare::@1 [phi:rom_compare::bank_set_brom1->rom_compare::@1]
    // [1820] phi rom_compare::equal_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z equal_bytes
    sta.z equal_bytes+1
    // [1820] phi rom_compare::ptr_ram#4 = rom_compare::ptr_ram#10 [phi:rom_compare::bank_set_brom1->rom_compare::@1#1] -- register_copy 
    // [1820] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#9 [phi:rom_compare::bank_set_brom1->rom_compare::@1#2] -- register_copy 
    // [1820] phi rom_compare::compared_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#3] -- vwuz1=vwuc1 
    sta.z compared_bytes
    sta.z compared_bytes+1
    // rom_compare::@1
  __b1:
    // while (compared_bytes < rom_compare_size)
    // [1821] if(rom_compare::compared_bytes#2<rom_compare::rom_compare_size#11) goto rom_compare::@2 -- vwuz1_lt_vwuz2_then_la1 
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
    // [1822] return 
    rts
    // rom_compare::@2
  __b2:
    // rom_byte_compare(ptr_rom, *ptr_ram)
    // [1823] rom_byte_compare::ptr_rom#0 = rom_compare::ptr_rom#2
    // [1824] rom_byte_compare::value#0 = *rom_compare::ptr_ram#4 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (ptr_ram),y
    sta.z rom_byte_compare.value
    // [1825] call rom_byte_compare
    jsr rom_byte_compare
    // [1826] rom_byte_compare::return#2 = rom_byte_compare::return#0
    // rom_compare::@5
    // [1827] rom_compare::$5 = rom_byte_compare::return#2
    // if (rom_byte_compare(ptr_rom, *ptr_ram))
    // [1828] if(0==rom_compare::$5) goto rom_compare::@3 -- 0_eq_vbuz1_then_la1 
    lda.z rom_compare__5
    beq __b3
    // rom_compare::@4
    // equal_bytes++;
    // [1829] rom_compare::equal_bytes#1 = ++ rom_compare::equal_bytes#2 -- vwuz1=_inc_vwuz1 
    inc.z equal_bytes
    bne !+
    inc.z equal_bytes+1
  !:
    // [1830] phi from rom_compare::@4 rom_compare::@5 to rom_compare::@3 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3]
    // [1830] phi rom_compare::equal_bytes#6 = rom_compare::equal_bytes#1 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3#0] -- register_copy 
    // rom_compare::@3
  __b3:
    // ptr_rom++;
    // [1831] rom_compare::ptr_rom#1 = ++ rom_compare::ptr_rom#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr_rom
    bne !+
    inc.z ptr_rom+1
  !:
    // ptr_ram++;
    // [1832] rom_compare::ptr_ram#0 = ++ rom_compare::ptr_ram#4 -- pbuz1=_inc_pbuz1 
    inc.z ptr_ram
    bne !+
    inc.z ptr_ram+1
  !:
    // compared_bytes++;
    // [1833] rom_compare::compared_bytes#1 = ++ rom_compare::compared_bytes#2 -- vwuz1=_inc_vwuz1 
    inc.z compared_bytes
    bne !+
    inc.z compared_bytes+1
  !:
    // [1820] phi from rom_compare::@3 to rom_compare::@1 [phi:rom_compare::@3->rom_compare::@1]
    // [1820] phi rom_compare::equal_bytes#2 = rom_compare::equal_bytes#6 [phi:rom_compare::@3->rom_compare::@1#0] -- register_copy 
    // [1820] phi rom_compare::ptr_ram#4 = rom_compare::ptr_ram#0 [phi:rom_compare::@3->rom_compare::@1#1] -- register_copy 
    // [1820] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#1 [phi:rom_compare::@3->rom_compare::@1#2] -- register_copy 
    // [1820] phi rom_compare::compared_bytes#2 = rom_compare::compared_bytes#1 [phi:rom_compare::@3->rom_compare::@1#3] -- register_copy 
    jmp __b1
}
  // ultoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void ultoa(__zp($37) unsigned long value, __zp($48) char *buffer, char radix)
ultoa: {
    .label ultoa__10 = $c5
    .label ultoa__11 = $e4
    .label digit_value = $44
    .label buffer = $48
    .label digit = $c2
    .label value = $37
    .label started = $c6
    // [1835] phi from ultoa to ultoa::@1 [phi:ultoa->ultoa::@1]
    // [1835] phi ultoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:ultoa->ultoa::@1#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1835] phi ultoa::started#2 = 0 [phi:ultoa->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [1835] phi ultoa::value#2 = ultoa::value#1 [phi:ultoa->ultoa::@1#2] -- register_copy 
    // [1835] phi ultoa::digit#2 = 0 [phi:ultoa->ultoa::@1#3] -- vbuz1=vbuc1 
    sta.z digit
    // ultoa::@1
  __b1:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1836] if(ultoa::digit#2<8-1) goto ultoa::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z digit
    cmp #8-1
    bcc __b2
    // ultoa::@3
    // *buffer++ = DIGITS[(char)value]
    // [1837] ultoa::$11 = (char)ultoa::value#2 -- vbuz1=_byte_vduz2 
    lda.z value
    sta.z ultoa__11
    // [1838] *ultoa::buffer#11 = DIGITS[ultoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1839] ultoa::buffer#3 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1840] *ultoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    // ultoa::@return
    // }
    // [1841] return 
    rts
    // ultoa::@2
  __b2:
    // unsigned long digit_value = digit_values[digit]
    // [1842] ultoa::$10 = ultoa::digit#2 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z digit
    asl
    asl
    sta.z ultoa__10
    // [1843] ultoa::digit_value#0 = RADIX_HEXADECIMAL_VALUES_LONG[ultoa::$10] -- vduz1=pduc1_derefidx_vbuz2 
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
    // [1844] if(0!=ultoa::started#2) goto ultoa::@5 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b5
    // ultoa::@7
    // [1845] if(ultoa::value#2>=ultoa::digit_value#0) goto ultoa::@5 -- vduz1_ge_vduz2_then_la1 
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
    // [1846] phi from ultoa::@7 to ultoa::@4 [phi:ultoa::@7->ultoa::@4]
    // [1846] phi ultoa::buffer#14 = ultoa::buffer#11 [phi:ultoa::@7->ultoa::@4#0] -- register_copy 
    // [1846] phi ultoa::started#4 = ultoa::started#2 [phi:ultoa::@7->ultoa::@4#1] -- register_copy 
    // [1846] phi ultoa::value#6 = ultoa::value#2 [phi:ultoa::@7->ultoa::@4#2] -- register_copy 
    // ultoa::@4
  __b4:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1847] ultoa::digit#1 = ++ ultoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1835] phi from ultoa::@4 to ultoa::@1 [phi:ultoa::@4->ultoa::@1]
    // [1835] phi ultoa::buffer#11 = ultoa::buffer#14 [phi:ultoa::@4->ultoa::@1#0] -- register_copy 
    // [1835] phi ultoa::started#2 = ultoa::started#4 [phi:ultoa::@4->ultoa::@1#1] -- register_copy 
    // [1835] phi ultoa::value#2 = ultoa::value#6 [phi:ultoa::@4->ultoa::@1#2] -- register_copy 
    // [1835] phi ultoa::digit#2 = ultoa::digit#1 [phi:ultoa::@4->ultoa::@1#3] -- register_copy 
    jmp __b1
    // ultoa::@5
  __b5:
    // ultoa_append(buffer++, value, digit_value)
    // [1848] ultoa_append::buffer#0 = ultoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z ultoa_append.buffer
    lda.z buffer+1
    sta.z ultoa_append.buffer+1
    // [1849] ultoa_append::value#0 = ultoa::value#2
    // [1850] ultoa_append::sub#0 = ultoa::digit_value#0
    // [1851] call ultoa_append
    // [2135] phi from ultoa::@5 to ultoa_append [phi:ultoa::@5->ultoa_append]
    jsr ultoa_append
    // ultoa_append(buffer++, value, digit_value)
    // [1852] ultoa_append::return#0 = ultoa_append::value#2
    // ultoa::@6
    // value = ultoa_append(buffer++, value, digit_value)
    // [1853] ultoa::value#0 = ultoa_append::return#0
    // value = ultoa_append(buffer++, value, digit_value);
    // [1854] ultoa::buffer#4 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1846] phi from ultoa::@6 to ultoa::@4 [phi:ultoa::@6->ultoa::@4]
    // [1846] phi ultoa::buffer#14 = ultoa::buffer#4 [phi:ultoa::@6->ultoa::@4#0] -- register_copy 
    // [1846] phi ultoa::started#4 = 1 [phi:ultoa::@6->ultoa::@4#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [1846] phi ultoa::value#6 = ultoa::value#0 [phi:ultoa::@6->ultoa::@4#2] -- register_copy 
    jmp __b4
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
// void rom_sector_erase(__zp($44) unsigned long address)
rom_sector_erase: {
    .label rom_ptr1_rom_sector_erase__0 = $2e
    .label rom_ptr1_rom_sector_erase__2 = $2e
    .label rom_ptr1_return = $2e
    .label rom_chip_address = $62
    .label address = $44
    // rom_sector_erase::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [1856] rom_sector_erase::rom_ptr1_$2 = (unsigned int)rom_sector_erase::address#0 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_sector_erase__2
    lda.z address+1
    sta.z rom_ptr1_rom_sector_erase__2+1
    // [1857] rom_sector_erase::rom_ptr1_$0 = rom_sector_erase::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_sector_erase__0
    and #<$3fff
    sta.z rom_ptr1_rom_sector_erase__0
    lda.z rom_ptr1_rom_sector_erase__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_sector_erase__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [1858] rom_sector_erase::rom_ptr1_return#0 = rom_sector_erase::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_sector_erase::@1
    // unsigned long rom_chip_address = address & ROM_CHIP_MASK
    // [1859] rom_sector_erase::rom_chip_address#0 = rom_sector_erase::address#0 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [1860] rom_unlock::address#0 = rom_sector_erase::rom_chip_address#0 + $5555 -- vduz1=vduz1_plus_vwuc1 
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
    // [1861] call rom_unlock
    // [2142] phi from rom_sector_erase::@1 to rom_unlock [phi:rom_sector_erase::@1->rom_unlock]
    // [2142] phi rom_unlock::unlock_code#3 = $80 [phi:rom_sector_erase::@1->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$80
    sta.z rom_unlock.unlock_code
    // [2142] phi rom_unlock::address#3 = rom_unlock::address#0 [phi:rom_sector_erase::@1->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@2
    // rom_unlock(address, 0x30)
    // [1862] rom_unlock::address#1 = rom_sector_erase::address#0 -- vduz1=vduz2 
    lda.z address
    sta.z rom_unlock.address
    lda.z address+1
    sta.z rom_unlock.address+1
    lda.z address+2
    sta.z rom_unlock.address+2
    lda.z address+3
    sta.z rom_unlock.address+3
    // [1863] call rom_unlock
    // [2142] phi from rom_sector_erase::@2 to rom_unlock [phi:rom_sector_erase::@2->rom_unlock]
    // [2142] phi rom_unlock::unlock_code#3 = $30 [phi:rom_sector_erase::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$30
    sta.z rom_unlock.unlock_code
    // [2142] phi rom_unlock::address#3 = rom_unlock::address#1 [phi:rom_sector_erase::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@3
    // rom_wait(ptr_rom)
    // [1864] rom_wait::ptr_rom#0 = (char *)rom_sector_erase::rom_ptr1_return#0
    // [1865] call rom_wait
    // [2152] phi from rom_sector_erase::@3 to rom_wait [phi:rom_sector_erase::@3->rom_wait]
    // [2152] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#0 [phi:rom_sector_erase::@3->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_sector_erase::@return
    // }
    // [1866] return 
    rts
}
  // rom_write
/* inline */
// unsigned long rom_write(__zp($e5) char flash_ram_bank, __zp($60) char *flash_ram_address, __zp($73) unsigned long flash_rom_address, unsigned int flash_rom_size)
rom_write: {
    .label rom_chip_address = $b0
    .label flash_rom_address = $73
    .label flash_ram_address = $60
    .label flashed_bytes = $6b
    .label flash_ram_bank = $e5
    // unsigned long rom_chip_address = flash_rom_address & ROM_CHIP_MASK
    // [1867] rom_write::rom_chip_address#0 = rom_write::flash_rom_address#1 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [1868] BRAM = rom_write::flash_ram_bank#0 -- vbuz1=vbuz2 
    lda.z flash_ram_bank
    sta.z BRAM
    // [1869] phi from rom_write::bank_set_bram1 to rom_write::@1 [phi:rom_write::bank_set_bram1->rom_write::@1]
    // [1869] phi rom_write::flash_ram_address#2 = rom_write::flash_ram_address#1 [phi:rom_write::bank_set_bram1->rom_write::@1#0] -- register_copy 
    // [1869] phi rom_write::flash_rom_address#3 = rom_write::flash_rom_address#1 [phi:rom_write::bank_set_bram1->rom_write::@1#1] -- register_copy 
    // [1869] phi rom_write::flashed_bytes#2 = 0 [phi:rom_write::bank_set_bram1->rom_write::@1#2] -- vduz1=vduc1 
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
    // [1870] if(rom_write::flashed_bytes#2<PROGRESS_CELL) goto rom_write::@2 -- vduz1_lt_vduc1_then_la1 
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
    // [1871] return 
    rts
    // rom_write::@2
  __b2:
    // rom_unlock(rom_chip_address + 0x05555, 0xA0)
    // [1872] rom_unlock::address#2 = rom_write::rom_chip_address#0 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [1873] call rom_unlock
    // [2142] phi from rom_write::@2 to rom_unlock [phi:rom_write::@2->rom_unlock]
    // [2142] phi rom_unlock::unlock_code#3 = $a0 [phi:rom_write::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$a0
    sta.z rom_unlock.unlock_code
    // [2142] phi rom_unlock::address#3 = rom_unlock::address#2 [phi:rom_write::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_write::@3
    // rom_byte_program(flash_rom_address, *flash_ram_address)
    // [1874] rom_byte_program::address#0 = rom_write::flash_rom_address#3 -- vduz1=vduz2 
    lda.z flash_rom_address
    sta.z rom_byte_program.address
    lda.z flash_rom_address+1
    sta.z rom_byte_program.address+1
    lda.z flash_rom_address+2
    sta.z rom_byte_program.address+2
    lda.z flash_rom_address+3
    sta.z rom_byte_program.address+3
    // [1875] rom_byte_program::value#0 = *rom_write::flash_ram_address#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (flash_ram_address),y
    sta.z rom_byte_program.value
    // [1876] call rom_byte_program
    // [2159] phi from rom_write::@3 to rom_byte_program [phi:rom_write::@3->rom_byte_program]
    jsr rom_byte_program
    // rom_write::@4
    // flash_rom_address++;
    // [1877] rom_write::flash_rom_address#0 = ++ rom_write::flash_rom_address#3 -- vduz1=_inc_vduz1 
    inc.z flash_rom_address
    bne !+
    inc.z flash_rom_address+1
    bne !+
    inc.z flash_rom_address+2
    bne !+
    inc.z flash_rom_address+3
  !:
    // flash_ram_address++;
    // [1878] rom_write::flash_ram_address#0 = ++ rom_write::flash_ram_address#2 -- pbuz1=_inc_pbuz1 
    inc.z flash_ram_address
    bne !+
    inc.z flash_ram_address+1
  !:
    // flashed_bytes++;
    // [1879] rom_write::flashed_bytes#1 = ++ rom_write::flashed_bytes#2 -- vduz1=_inc_vduz1 
    inc.z flashed_bytes
    bne !+
    inc.z flashed_bytes+1
    bne !+
    inc.z flashed_bytes+2
    bne !+
    inc.z flashed_bytes+3
  !:
    // [1869] phi from rom_write::@4 to rom_write::@1 [phi:rom_write::@4->rom_write::@1]
    // [1869] phi rom_write::flash_ram_address#2 = rom_write::flash_ram_address#0 [phi:rom_write::@4->rom_write::@1#0] -- register_copy 
    // [1869] phi rom_write::flash_rom_address#3 = rom_write::flash_rom_address#0 [phi:rom_write::@4->rom_write::@1#1] -- register_copy 
    // [1869] phi rom_write::flashed_bytes#2 = rom_write::flashed_bytes#1 [phi:rom_write::@4->rom_write::@1#2] -- register_copy 
    jmp __b1
}
  // insertup
// Insert a new line, and scroll the upper part of the screen up.
// void insertup(char rows)
insertup: {
    .label insertup__0 = $35
    .label insertup__4 = $33
    .label insertup__6 = $34
    .label insertup__7 = $33
    .label width = $35
    .label y = $30
    // __conio.width+1
    // [1880] insertup::$0 = *((char *)&__conio+6) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+6
    inc
    sta.z insertup__0
    // unsigned char width = (__conio.width+1) * 2
    // [1881] insertup::width#0 = insertup::$0 << 1 -- vbuz1=vbuz1_rol_1 
    // {asm{.byte $db}}
    asl.z width
    // [1882] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [1882] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [1883] if(insertup::y#2<*((char *)&__conio+1)) goto insertup::@2 -- vbuz1_lt__deref_pbuc1_then_la1 
    lda.z y
    cmp __conio+1
    bcc __b2
    // [1884] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [1885] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [1886] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [1887] insertup::$4 = insertup::y#2 + 1 -- vbuz1=vbuz2_plus_1 
    lda.z y
    inc
    sta.z insertup__4
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [1888] insertup::$6 = insertup::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z insertup__6
    // [1889] insertup::$7 = insertup::$4 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z insertup__7
    // [1890] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z memcpy8_vram_vram.dbank_vram
    // [1891] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__6
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.doffset_vram+1
    // [1892] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z memcpy8_vram_vram.sbank_vram
    // [1893] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__7
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.soffset_vram+1
    // [1894] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbuz1=vbuz2 
    lda.z width
    sta.z memcpy8_vram_vram.num8_1
    // [1895] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [1896] insertup::y#1 = ++ insertup::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [1882] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [1882] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
    jmp __b1
}
  // clearline
clearline: {
    .label clearline__0 = $25
    .label clearline__1 = $27
    .label clearline__2 = $28
    .label clearline__3 = $26
    .label addr = $31
    .label c = $22
    // unsigned int addr = __conio.offsets[__conio.cursor_y]
    // [1897] clearline::$3 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z clearline__3
    // [1898] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwuz1=pwuc1_derefidx_vbuz2 
    tay
    lda __conio+$15,y
    sta.z addr
    lda __conio+$15+1,y
    sta.z addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1899] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [1900] clearline::$0 = byte0  clearline::addr#0 -- vbuz1=_byte0_vwuz2 
    lda.z addr
    sta.z clearline__0
    // *VERA_ADDRX_L = BYTE0(addr)
    // [1901] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [1902] clearline::$1 = byte1  clearline::addr#0 -- vbuz1=_byte1_vwuz2 
    lda.z addr+1
    sta.z clearline__1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [1903] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [1904] clearline::$2 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clearline__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1905] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [1906] clearline::c#0 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z c
    // [1907] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [1907] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [1908] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1909] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [1910] clearline::c#1 = -- clearline::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [1911] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b1
    // clearline::@return
    // }
    // [1912] return 
    rts
}
  // frame_maskxy
// __mem() char frame_maskxy(__mem() char x, __mem() char y)
frame_maskxy: {
    .label cpeekcxy1_cpeekc1_frame_maskxy__0 = $df
    .label cpeekcxy1_cpeekc1_frame_maskxy__1 = $5b
    .label cpeekcxy1_cpeekc1_frame_maskxy__2 = $da
    .label c = $be
    // frame_maskxy::cpeekcxy1
    // gotoxy(x,y)
    // [1914] gotoxy::x#5 = frame_maskxy::cpeekcxy1_x#0 -- vbuz1=vbum2 
    lda cpeekcxy1_x
    sta.z gotoxy.x
    // [1915] gotoxy::y#5 = frame_maskxy::cpeekcxy1_y#0 -- vbuz1=vbum2 
    lda cpeekcxy1_y
    sta.z gotoxy.y
    // [1916] call gotoxy
    // [392] phi from frame_maskxy::cpeekcxy1 to gotoxy [phi:frame_maskxy::cpeekcxy1->gotoxy]
    // [392] phi gotoxy::y#26 = gotoxy::y#5 [phi:frame_maskxy::cpeekcxy1->gotoxy#0] -- register_copy 
    // [392] phi gotoxy::x#26 = gotoxy::x#5 [phi:frame_maskxy::cpeekcxy1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // frame_maskxy::cpeekcxy1_cpeekc1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1917] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [1918] frame_maskxy::cpeekcxy1_cpeekc1_$0 = byte0  *((unsigned int *)&__conio+$13) -- vbuz1=_byte0__deref_pwuc1 
    lda __conio+$13
    sta.z cpeekcxy1_cpeekc1_frame_maskxy__0
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [1919] *VERA_ADDRX_L = frame_maskxy::cpeekcxy1_cpeekc1_$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [1920] frame_maskxy::cpeekcxy1_cpeekc1_$1 = byte1  *((unsigned int *)&__conio+$13) -- vbuz1=_byte1__deref_pwuc1 
    lda __conio+$13+1
    sta.z cpeekcxy1_cpeekc1_frame_maskxy__1
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [1921] *VERA_ADDRX_M = frame_maskxy::cpeekcxy1_cpeekc1_$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_0
    // [1922] frame_maskxy::cpeekcxy1_cpeekc1_$2 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z cpeekcxy1_cpeekc1_frame_maskxy__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_0
    // [1923] *VERA_ADDRX_H = frame_maskxy::cpeekcxy1_cpeekc1_$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // return *VERA_DATA0;
    // [1924] frame_maskxy::c#0 = *VERA_DATA0 -- vbuz1=_deref_pbuc1 
    lda VERA_DATA0
    sta.z c
    // frame_maskxy::@12
    // case 0x70: // DR corner.
    //             return 0b0110;
    // [1925] if(frame_maskxy::c#0==$70) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$70
    cmp.z c
    beq __b2
    // frame_maskxy::@1
    // case 0x6E: // DL corner.
    //             return 0b0011;
    // [1926] if(frame_maskxy::c#0==$6e) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6e
    cmp.z c
    beq __b1
    // frame_maskxy::@2
    // case 0x6D: // UR corner.
    //             return 0b1100;
    // [1927] if(frame_maskxy::c#0==$6d) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6d
    cmp.z c
    beq __b3
    // frame_maskxy::@3
    // case 0x7D: // UL corner.
    //             return 0b1001;
    // [1928] if(frame_maskxy::c#0==$7d) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$7d
    cmp.z c
    beq __b4
    // frame_maskxy::@4
    // case 0x40: // HL line.
    //             return 0b0101;
    // [1929] if(frame_maskxy::c#0==$40) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$40
    cmp.z c
    beq __b5
    // frame_maskxy::@5
    // case 0x5D: // VL line.
    //             return 0b1010;
    // [1930] if(frame_maskxy::c#0==$5d) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$5d
    cmp.z c
    beq __b6
    // frame_maskxy::@6
    // case 0x6B: // VR junction.
    //             return 0b1110;
    // [1931] if(frame_maskxy::c#0==$6b) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6b
    cmp.z c
    beq __b7
    // frame_maskxy::@7
    // case 0x73: // VL junction.
    //             return 0b1011;
    // [1932] if(frame_maskxy::c#0==$73) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$73
    cmp.z c
    beq __b8
    // frame_maskxy::@8
    // case 0x72: // HD junction.
    //             return 0b0111;
    // [1933] if(frame_maskxy::c#0==$72) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$72
    cmp.z c
    beq __b9
    // frame_maskxy::@9
    // case 0x71: // HU junction.
    //             return 0b1101;
    // [1934] if(frame_maskxy::c#0==$71) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$71
    cmp.z c
    beq __b10
    // frame_maskxy::@10
    // case 0x5B: // HV junction.
    //             return 0b1111;
    // [1935] if(frame_maskxy::c#0==$5b) goto frame_maskxy::@11 -- vbuz1_eq_vbuc1_then_la1 
    lda #$5b
    cmp.z c
    beq __b11
    // [1937] phi from frame_maskxy::@10 to frame_maskxy::@return [phi:frame_maskxy::@10->frame_maskxy::@return]
    // [1937] phi frame_maskxy::return#12 = 0 [phi:frame_maskxy::@10->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    rts
    // [1936] phi from frame_maskxy::@10 to frame_maskxy::@11 [phi:frame_maskxy::@10->frame_maskxy::@11]
    // frame_maskxy::@11
  __b11:
    // [1937] phi from frame_maskxy::@11 to frame_maskxy::@return [phi:frame_maskxy::@11->frame_maskxy::@return]
    // [1937] phi frame_maskxy::return#12 = $f [phi:frame_maskxy::@11->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$f
    sta return
    rts
    // [1937] phi from frame_maskxy::@1 to frame_maskxy::@return [phi:frame_maskxy::@1->frame_maskxy::@return]
  __b1:
    // [1937] phi frame_maskxy::return#12 = 3 [phi:frame_maskxy::@1->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #3
    sta return
    rts
    // [1937] phi from frame_maskxy::@12 to frame_maskxy::@return [phi:frame_maskxy::@12->frame_maskxy::@return]
  __b2:
    // [1937] phi frame_maskxy::return#12 = 6 [phi:frame_maskxy::@12->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #6
    sta return
    rts
    // [1937] phi from frame_maskxy::@2 to frame_maskxy::@return [phi:frame_maskxy::@2->frame_maskxy::@return]
  __b3:
    // [1937] phi frame_maskxy::return#12 = $c [phi:frame_maskxy::@2->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$c
    sta return
    rts
    // [1937] phi from frame_maskxy::@3 to frame_maskxy::@return [phi:frame_maskxy::@3->frame_maskxy::@return]
  __b4:
    // [1937] phi frame_maskxy::return#12 = 9 [phi:frame_maskxy::@3->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #9
    sta return
    rts
    // [1937] phi from frame_maskxy::@4 to frame_maskxy::@return [phi:frame_maskxy::@4->frame_maskxy::@return]
  __b5:
    // [1937] phi frame_maskxy::return#12 = 5 [phi:frame_maskxy::@4->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #5
    sta return
    rts
    // [1937] phi from frame_maskxy::@5 to frame_maskxy::@return [phi:frame_maskxy::@5->frame_maskxy::@return]
  __b6:
    // [1937] phi frame_maskxy::return#12 = $a [phi:frame_maskxy::@5->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$a
    sta return
    rts
    // [1937] phi from frame_maskxy::@6 to frame_maskxy::@return [phi:frame_maskxy::@6->frame_maskxy::@return]
  __b7:
    // [1937] phi frame_maskxy::return#12 = $e [phi:frame_maskxy::@6->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$e
    sta return
    rts
    // [1937] phi from frame_maskxy::@7 to frame_maskxy::@return [phi:frame_maskxy::@7->frame_maskxy::@return]
  __b8:
    // [1937] phi frame_maskxy::return#12 = $b [phi:frame_maskxy::@7->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$b
    sta return
    rts
    // [1937] phi from frame_maskxy::@8 to frame_maskxy::@return [phi:frame_maskxy::@8->frame_maskxy::@return]
  __b9:
    // [1937] phi frame_maskxy::return#12 = 7 [phi:frame_maskxy::@8->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #7
    sta return
    rts
    // [1937] phi from frame_maskxy::@9 to frame_maskxy::@return [phi:frame_maskxy::@9->frame_maskxy::@return]
  __b10:
    // [1937] phi frame_maskxy::return#12 = $d [phi:frame_maskxy::@9->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$d
    sta return
    // frame_maskxy::@return
    // }
    // [1938] return 
    rts
  .segment Data
    cpeekcxy1_x: .byte 0
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
    .label x = cpeekcxy1_x
    .label y = cpeekcxy1_y
}
.segment Code
  // frame_char
// __zp($43) char frame_char(__mem() char mask)
frame_char: {
    .label return = $43
    // case 0b0110:
    //             return 0x70;
    // [1940] if(frame_char::mask#10==6) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    lda #6
    cmp mask
    beq __b1
    // frame_char::@1
    // case 0b0011:
    //             return 0x6E;
    // [1941] if(frame_char::mask#10==3) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // DR corner.
    lda #3
    cmp mask
    beq __b2
    // frame_char::@2
    // case 0b1100:
    //             return 0x6D;
    // [1942] if(frame_char::mask#10==$c) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // DL corner.
    lda #$c
    cmp mask
    beq __b3
    // frame_char::@3
    // case 0b1001:
    //             return 0x7D;
    // [1943] if(frame_char::mask#10==9) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // UR corner.
    lda #9
    cmp mask
    beq __b4
    // frame_char::@4
    // case 0b0101:
    //             return 0x40;
    // [1944] if(frame_char::mask#10==5) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // UL corner.
    lda #5
    cmp mask
    beq __b5
    // frame_char::@5
    // case 0b1010:
    //             return 0x5D;
    // [1945] if(frame_char::mask#10==$a) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // HL line.
    lda #$a
    cmp mask
    beq __b6
    // frame_char::@6
    // case 0b1110:
    //             return 0x6B;
    // [1946] if(frame_char::mask#10==$e) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // VL line.
    lda #$e
    cmp mask
    beq __b7
    // frame_char::@7
    // case 0b1011:
    //             return 0x73;
    // [1947] if(frame_char::mask#10==$b) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // VR junction.
    lda #$b
    cmp mask
    beq __b8
    // frame_char::@8
    // case 0b0111:
    //             return 0x72;
    // [1948] if(frame_char::mask#10==7) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // VL junction.
    lda #7
    cmp mask
    beq __b9
    // frame_char::@9
    // case 0b1101:
    //             return 0x71;
    // [1949] if(frame_char::mask#10==$d) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // HD junction.
    lda #$d
    cmp mask
    beq __b10
    // frame_char::@10
    // case 0b1111:
    //             return 0x5B;
    // [1950] if(frame_char::mask#10==$f) goto frame_char::@11 -- vbum1_eq_vbuc1_then_la1 
    // HU junction.
    lda #$f
    cmp mask
    beq __b11
    // [1952] phi from frame_char::@10 to frame_char::@return [phi:frame_char::@10->frame_char::@return]
    // [1952] phi frame_char::return#12 = $20 [phi:frame_char::@10->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$20
    sta.z return
    rts
    // [1951] phi from frame_char::@10 to frame_char::@11 [phi:frame_char::@10->frame_char::@11]
    // frame_char::@11
  __b11:
    // [1952] phi from frame_char::@11 to frame_char::@return [phi:frame_char::@11->frame_char::@return]
    // [1952] phi frame_char::return#12 = $5b [phi:frame_char::@11->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z return
    rts
    // [1952] phi from frame_char to frame_char::@return [phi:frame_char->frame_char::@return]
  __b1:
    // [1952] phi frame_char::return#12 = $70 [phi:frame_char->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$70
    sta.z return
    rts
    // [1952] phi from frame_char::@1 to frame_char::@return [phi:frame_char::@1->frame_char::@return]
  __b2:
    // [1952] phi frame_char::return#12 = $6e [phi:frame_char::@1->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6e
    sta.z return
    rts
    // [1952] phi from frame_char::@2 to frame_char::@return [phi:frame_char::@2->frame_char::@return]
  __b3:
    // [1952] phi frame_char::return#12 = $6d [phi:frame_char::@2->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6d
    sta.z return
    rts
    // [1952] phi from frame_char::@3 to frame_char::@return [phi:frame_char::@3->frame_char::@return]
  __b4:
    // [1952] phi frame_char::return#12 = $7d [phi:frame_char::@3->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$7d
    sta.z return
    rts
    // [1952] phi from frame_char::@4 to frame_char::@return [phi:frame_char::@4->frame_char::@return]
  __b5:
    // [1952] phi frame_char::return#12 = $40 [phi:frame_char::@4->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z return
    rts
    // [1952] phi from frame_char::@5 to frame_char::@return [phi:frame_char::@5->frame_char::@return]
  __b6:
    // [1952] phi frame_char::return#12 = $5d [phi:frame_char::@5->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z return
    rts
    // [1952] phi from frame_char::@6 to frame_char::@return [phi:frame_char::@6->frame_char::@return]
  __b7:
    // [1952] phi frame_char::return#12 = $6b [phi:frame_char::@6->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z return
    rts
    // [1952] phi from frame_char::@7 to frame_char::@return [phi:frame_char::@7->frame_char::@return]
  __b8:
    // [1952] phi frame_char::return#12 = $73 [phi:frame_char::@7->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z return
    rts
    // [1952] phi from frame_char::@8 to frame_char::@return [phi:frame_char::@8->frame_char::@return]
  __b9:
    // [1952] phi frame_char::return#12 = $72 [phi:frame_char::@8->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z return
    rts
    // [1952] phi from frame_char::@9 to frame_char::@return [phi:frame_char::@9->frame_char::@return]
  __b10:
    // [1952] phi frame_char::return#12 = $71 [phi:frame_char::@9->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z return
    // frame_char::@return
    // }
    // [1953] return 
    rts
  .segment Data
    .label mask = frame_maskxy.return
}
.segment Code
  // cputs
// Output a NUL-terminated string at the current cursor position
// void cputs(__zp($71) const char *s)
cputs: {
    .label c = $da
    .label s = $71
    // [1955] phi from cputs cputs::@2 to cputs::@1 [phi:cputs/cputs::@2->cputs::@1]
    // [1955] phi cputs::s#2 = cputs::s#1 [phi:cputs/cputs::@2->cputs::@1#0] -- register_copy 
    // cputs::@1
  __b1:
    // while(c=*s++)
    // [1956] cputs::c#1 = *cputs::s#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta.z c
    // [1957] cputs::s#0 = ++ cputs::s#2 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [1958] if(0!=cputs::c#1) goto cputs::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // cputs::@return
    // }
    // [1959] return 
    rts
    // cputs::@2
  __b2:
    // cputc(c)
    // [1960] stackpush(char) = cputs::c#1 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [1961] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
}
  // print_chip_led
// void print_chip_led(__zp($d6) char x, char y, __zp($d3) char w, __zp($c6) char tc, char bc)
print_chip_led: {
    .label i = $3b
    .label tc = $c6
    .label x = $d6
    .label w = $d3
    // gotoxy(x, y)
    // [1964] gotoxy::x#8 = print_chip_led::x#3 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1965] call gotoxy
    // [392] phi from print_chip_led to gotoxy [phi:print_chip_led->gotoxy]
    // [392] phi gotoxy::y#26 = 3 [phi:print_chip_led->gotoxy#0] -- vbuz1=vbuc1 
    lda #3
    sta.z gotoxy.y
    // [392] phi gotoxy::x#26 = gotoxy::x#8 [phi:print_chip_led->gotoxy#1] -- register_copy 
    jsr gotoxy
    // print_chip_led::@4
    // textcolor(tc)
    // [1966] textcolor::color#10 = print_chip_led::tc#3 -- vbuz1=vbuz2 
    lda.z tc
    sta.z textcolor.color
    // [1967] call textcolor
    // [374] phi from print_chip_led::@4 to textcolor [phi:print_chip_led::@4->textcolor]
    // [374] phi textcolor::color#16 = textcolor::color#10 [phi:print_chip_led::@4->textcolor#0] -- register_copy 
    jsr textcolor
    // [1968] phi from print_chip_led::@4 to print_chip_led::@5 [phi:print_chip_led::@4->print_chip_led::@5]
    // print_chip_led::@5
    // bgcolor(bc)
    // [1969] call bgcolor
    // [379] phi from print_chip_led::@5 to bgcolor [phi:print_chip_led::@5->bgcolor]
    // [379] phi bgcolor::color#14 = BLUE [phi:print_chip_led::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [1970] phi from print_chip_led::@5 to print_chip_led::@1 [phi:print_chip_led::@5->print_chip_led::@1]
    // [1970] phi print_chip_led::i#2 = 0 [phi:print_chip_led::@5->print_chip_led::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // print_chip_led::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [1971] if(print_chip_led::i#2<print_chip_led::w#5) goto print_chip_led::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [1972] phi from print_chip_led::@1 to print_chip_led::@3 [phi:print_chip_led::@1->print_chip_led::@3]
    // print_chip_led::@3
    // textcolor(WHITE)
    // [1973] call textcolor
    // [374] phi from print_chip_led::@3 to textcolor [phi:print_chip_led::@3->textcolor]
    // [374] phi textcolor::color#16 = WHITE [phi:print_chip_led::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [1974] phi from print_chip_led::@3 to print_chip_led::@6 [phi:print_chip_led::@3->print_chip_led::@6]
    // print_chip_led::@6
    // bgcolor(BLUE)
    // [1975] call bgcolor
    // [379] phi from print_chip_led::@6 to bgcolor [phi:print_chip_led::@6->bgcolor]
    // [379] phi bgcolor::color#14 = BLUE [phi:print_chip_led::@6->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_led::@return
    // }
    // [1976] return 
    rts
    // print_chip_led::@2
  __b2:
    // cputc(0xE2)
    // [1977] stackpush(char) = $e2 -- _stackpushbyte_=vbuc1 
    lda #$e2
    pha
    // [1978] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [1980] print_chip_led::i#1 = ++ print_chip_led::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1970] phi from print_chip_led::@2 to print_chip_led::@1 [phi:print_chip_led::@2->print_chip_led::@1]
    // [1970] phi print_chip_led::i#2 = print_chip_led::i#1 [phi:print_chip_led::@2->print_chip_led::@1#0] -- register_copy 
    jmp __b1
}
  // print_chip_line
// void print_chip_line(__zp($be) char x, __zp($ba) char y, __zp($66) char w, __zp($3c) char c)
print_chip_line: {
    .label i = $70
    .label x = $be
    .label w = $66
    .label c = $3c
    .label y = $ba
    // gotoxy(x, y)
    // [1982] gotoxy::x#6 = print_chip_line::x#16 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1983] gotoxy::y#6 = print_chip_line::y#16 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1984] call gotoxy
    // [392] phi from print_chip_line to gotoxy [phi:print_chip_line->gotoxy]
    // [392] phi gotoxy::y#26 = gotoxy::y#6 [phi:print_chip_line->gotoxy#0] -- register_copy 
    // [392] phi gotoxy::x#26 = gotoxy::x#6 [phi:print_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1985] phi from print_chip_line to print_chip_line::@4 [phi:print_chip_line->print_chip_line::@4]
    // print_chip_line::@4
    // textcolor(GREY)
    // [1986] call textcolor
    // [374] phi from print_chip_line::@4 to textcolor [phi:print_chip_line::@4->textcolor]
    // [374] phi textcolor::color#16 = GREY [phi:print_chip_line::@4->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [1987] phi from print_chip_line::@4 to print_chip_line::@5 [phi:print_chip_line::@4->print_chip_line::@5]
    // print_chip_line::@5
    // bgcolor(BLUE)
    // [1988] call bgcolor
    // [379] phi from print_chip_line::@5 to bgcolor [phi:print_chip_line::@5->bgcolor]
    // [379] phi bgcolor::color#14 = BLUE [phi:print_chip_line::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@6
    // cputc(VERA_CHR_UR)
    // [1989] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [1990] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [1992] call textcolor
    // [374] phi from print_chip_line::@6 to textcolor [phi:print_chip_line::@6->textcolor]
    // [374] phi textcolor::color#16 = WHITE [phi:print_chip_line::@6->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [1993] phi from print_chip_line::@6 to print_chip_line::@7 [phi:print_chip_line::@6->print_chip_line::@7]
    // print_chip_line::@7
    // bgcolor(BLACK)
    // [1994] call bgcolor
    // [379] phi from print_chip_line::@7 to bgcolor [phi:print_chip_line::@7->bgcolor]
    // [379] phi bgcolor::color#14 = BLACK [phi:print_chip_line::@7->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // [1995] phi from print_chip_line::@7 to print_chip_line::@1 [phi:print_chip_line::@7->print_chip_line::@1]
    // [1995] phi print_chip_line::i#2 = 0 [phi:print_chip_line::@7->print_chip_line::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // print_chip_line::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [1996] if(print_chip_line::i#2<print_chip_line::w#10) goto print_chip_line::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [1997] phi from print_chip_line::@1 to print_chip_line::@3 [phi:print_chip_line::@1->print_chip_line::@3]
    // print_chip_line::@3
    // textcolor(GREY)
    // [1998] call textcolor
    // [374] phi from print_chip_line::@3 to textcolor [phi:print_chip_line::@3->textcolor]
    // [374] phi textcolor::color#16 = GREY [phi:print_chip_line::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [1999] phi from print_chip_line::@3 to print_chip_line::@8 [phi:print_chip_line::@3->print_chip_line::@8]
    // print_chip_line::@8
    // bgcolor(BLUE)
    // [2000] call bgcolor
    // [379] phi from print_chip_line::@8 to bgcolor [phi:print_chip_line::@8->bgcolor]
    // [379] phi bgcolor::color#14 = BLUE [phi:print_chip_line::@8->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@9
    // cputc(VERA_CHR_UL)
    // [2001] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [2002] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [2004] call textcolor
    // [374] phi from print_chip_line::@9 to textcolor [phi:print_chip_line::@9->textcolor]
    // [374] phi textcolor::color#16 = WHITE [phi:print_chip_line::@9->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [2005] phi from print_chip_line::@9 to print_chip_line::@10 [phi:print_chip_line::@9->print_chip_line::@10]
    // print_chip_line::@10
    // bgcolor(BLACK)
    // [2006] call bgcolor
    // [379] phi from print_chip_line::@10 to bgcolor [phi:print_chip_line::@10->bgcolor]
    // [379] phi bgcolor::color#14 = BLACK [phi:print_chip_line::@10->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@11
    // cputcxy(x+2, y, c)
    // [2007] cputcxy::x#8 = print_chip_line::x#16 + 2 -- vbuz1=vbuz1_plus_2 
    lda.z cputcxy.x
    clc
    adc #2
    sta.z cputcxy.x
    // [2008] cputcxy::y#8 = print_chip_line::y#16
    // [2009] cputcxy::c#8 = print_chip_line::c#15 -- vbuz1=vbuz2 
    lda.z c
    sta.z cputcxy.c
    // [2010] call cputcxy
    // [1432] phi from print_chip_line::@11 to cputcxy [phi:print_chip_line::@11->cputcxy]
    // [1432] phi cputcxy::c#13 = cputcxy::c#8 [phi:print_chip_line::@11->cputcxy#0] -- register_copy 
    // [1432] phi cputcxy::y#13 = cputcxy::y#8 [phi:print_chip_line::@11->cputcxy#1] -- register_copy 
    // [1432] phi cputcxy::x#13 = cputcxy::x#8 [phi:print_chip_line::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // print_chip_line::@return
    // }
    // [2011] return 
    rts
    // print_chip_line::@2
  __b2:
    // cputc(VERA_CHR_SPACE)
    // [2012] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [2013] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [2015] print_chip_line::i#1 = ++ print_chip_line::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1995] phi from print_chip_line::@2 to print_chip_line::@1 [phi:print_chip_line::@2->print_chip_line::@1]
    // [1995] phi print_chip_line::i#2 = print_chip_line::i#1 [phi:print_chip_line::@2->print_chip_line::@1#0] -- register_copy 
    jmp __b1
}
  // print_chip_end
// void print_chip_end(__zp($4c) char x, char y, __mem() char w)
print_chip_end: {
    .label i = $55
    .label x = $4c
    // gotoxy(x, y)
    // [2016] gotoxy::x#7 = print_chip_end::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [2017] call gotoxy
    // [392] phi from print_chip_end to gotoxy [phi:print_chip_end->gotoxy]
    // [392] phi gotoxy::y#26 = print_chip::y#21 [phi:print_chip_end->gotoxy#0] -- vbuz1=vbuc1 
    lda #print_chip.y
    sta.z gotoxy.y
    // [392] phi gotoxy::x#26 = gotoxy::x#7 [phi:print_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [2018] phi from print_chip_end to print_chip_end::@4 [phi:print_chip_end->print_chip_end::@4]
    // print_chip_end::@4
    // textcolor(GREY)
    // [2019] call textcolor
    // [374] phi from print_chip_end::@4 to textcolor [phi:print_chip_end::@4->textcolor]
    // [374] phi textcolor::color#16 = GREY [phi:print_chip_end::@4->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [2020] phi from print_chip_end::@4 to print_chip_end::@5 [phi:print_chip_end::@4->print_chip_end::@5]
    // print_chip_end::@5
    // bgcolor(BLUE)
    // [2021] call bgcolor
    // [379] phi from print_chip_end::@5 to bgcolor [phi:print_chip_end::@5->bgcolor]
    // [379] phi bgcolor::color#14 = BLUE [phi:print_chip_end::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_end::@6
    // cputc(VERA_CHR_UR)
    // [2022] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [2023] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [2025] call textcolor
    // [374] phi from print_chip_end::@6 to textcolor [phi:print_chip_end::@6->textcolor]
    // [374] phi textcolor::color#16 = BLUE [phi:print_chip_end::@6->textcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z textcolor.color
    jsr textcolor
    // [2026] phi from print_chip_end::@6 to print_chip_end::@7 [phi:print_chip_end::@6->print_chip_end::@7]
    // print_chip_end::@7
    // bgcolor(BLACK)
    // [2027] call bgcolor
    // [379] phi from print_chip_end::@7 to bgcolor [phi:print_chip_end::@7->bgcolor]
    // [379] phi bgcolor::color#14 = BLACK [phi:print_chip_end::@7->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // [2028] phi from print_chip_end::@7 to print_chip_end::@1 [phi:print_chip_end::@7->print_chip_end::@1]
    // [2028] phi print_chip_end::i#2 = 0 [phi:print_chip_end::@7->print_chip_end::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // print_chip_end::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [2029] if(print_chip_end::i#2<print_chip_end::w#0) goto print_chip_end::@2 -- vbuz1_lt_vbum2_then_la1 
    lda.z i
    cmp w
    bcc __b2
    // [2030] phi from print_chip_end::@1 to print_chip_end::@3 [phi:print_chip_end::@1->print_chip_end::@3]
    // print_chip_end::@3
    // textcolor(GREY)
    // [2031] call textcolor
    // [374] phi from print_chip_end::@3 to textcolor [phi:print_chip_end::@3->textcolor]
    // [374] phi textcolor::color#16 = GREY [phi:print_chip_end::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [2032] phi from print_chip_end::@3 to print_chip_end::@8 [phi:print_chip_end::@3->print_chip_end::@8]
    // print_chip_end::@8
    // bgcolor(BLUE)
    // [2033] call bgcolor
    // [379] phi from print_chip_end::@8 to bgcolor [phi:print_chip_end::@8->bgcolor]
    // [379] phi bgcolor::color#14 = BLUE [phi:print_chip_end::@8->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_end::@9
    // cputc(VERA_CHR_UL)
    // [2034] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [2035] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_end::@return
    // }
    // [2037] return 
    rts
    // print_chip_end::@2
  __b2:
    // cputc(VERA_CHR_HL)
    // [2038] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [2039] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [2041] print_chip_end::i#1 = ++ print_chip_end::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2028] phi from print_chip_end::@2 to print_chip_end::@1 [phi:print_chip_end::@2->print_chip_end::@1]
    // [2028] phi print_chip_end::i#2 = print_chip_end::i#1 [phi:print_chip_end::@2->print_chip_end::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    w: .byte 0
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
// __zp($48) unsigned int utoa_append(__zp($d8) char *buffer, __zp($48) unsigned int value, __zp($59) unsigned int sub)
utoa_append: {
    .label buffer = $d8
    .label value = $48
    .label sub = $59
    .label return = $48
    .label digit = $4c
    // [2043] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [2043] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [2043] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [2044] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwuz1_ge_vwuz2_then_la1 
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
    // [2045] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // utoa_append::@return
    // }
    // [2046] return 
    rts
    // utoa_append::@2
  __b2:
    // digit++;
    // [2047] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [2048] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    lda.z value+1
    sbc.z sub+1
    sta.z value+1
    // [2043] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [2043] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [2043] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
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
    // [2050] return 
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
// __mem() int ferror(__zp($bc) struct $2 *stream)
ferror: {
    .label ferror__6 = $29
    .label ferror__15 = $e6
    .label cbm_k_setnam1_ferror__0 = $ab
    .label cbm_k_readst1_status = $f6
    .label cbm_k_chrin2_ch = $f7
    .label stream = $bc
    .label sp = $be
    .label cbm_k_chrin1_return = $e6
    .label ch = $e6
    .label cbm_k_readst1_return = $29
    .label st = $29
    .label cbm_k_chrin2_return = $e6
    .label errno_parsed = $e8
    // unsigned char sp = (unsigned char)stream
    // [2051] ferror::sp#0 = (char)ferror::stream#0 -- vbuz1=_byte_pssz2 
    lda.z stream
    sta.z sp
    // cbm_k_setlfs(15, 8, 15)
    // [2052] cbm_k_setlfs::channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.channel
    // [2053] cbm_k_setlfs::device = 8 -- vbum1=vbuc1 
    lda #8
    sta cbm_k_setlfs.device
    // [2054] cbm_k_setlfs::command = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.command
    // [2055] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // ferror::@11
    // cbm_k_setnam("")
    // [2056] ferror::cbm_k_setnam1_filename = info_text5 -- pbum1=pbuc1 
    lda #<info_text5
    sta cbm_k_setnam1_filename
    lda #>info_text5
    sta cbm_k_setnam1_filename+1
    // ferror::cbm_k_setnam1
    // strlen(filename)
    // [2057] strlen::str#5 = ferror::cbm_k_setnam1_filename -- pbuz1=pbum2 
    lda cbm_k_setnam1_filename
    sta.z strlen.str
    lda cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [2058] call strlen
    // [1790] phi from ferror::cbm_k_setnam1 to strlen [phi:ferror::cbm_k_setnam1->strlen]
    // [1790] phi strlen::str#8 = strlen::str#5 [phi:ferror::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [2059] strlen::return#12 = strlen::len#2
    // ferror::@12
    // [2060] ferror::cbm_k_setnam1_$0 = strlen::return#12
    // char filename_len = (char)strlen(filename)
    // [2061] ferror::cbm_k_setnam1_filename_len = (char)ferror::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
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
    // [2064] ferror::cbm_k_chkin1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_chkin1_channel
    // ferror::cbm_k_chkin1
    // char status
    // [2065] ferror::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // ferror::cbm_k_chrin1
    // char ch
    // [2067] ferror::cbm_k_chrin1_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin1_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin1_ch
    // return ch;
    // [2069] ferror::cbm_k_chrin1_return#0 = ferror::cbm_k_chrin1_ch -- vbuz1=vbum2 
    sta.z cbm_k_chrin1_return
    // ferror::cbm_k_chrin1_@return
    // }
    // [2070] ferror::cbm_k_chrin1_return#1 = ferror::cbm_k_chrin1_return#0
    // ferror::@7
    // char ch = cbm_k_chrin()
    // [2071] ferror::ch#0 = ferror::cbm_k_chrin1_return#1
    // [2072] phi from ferror::@7 to ferror::cbm_k_readst1 [phi:ferror::@7->ferror::cbm_k_readst1]
    // [2072] phi __errno#153 = __errno#257 [phi:ferror::@7->ferror::cbm_k_readst1#0] -- register_copy 
    // [2072] phi ferror::errno_len#10 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#1] -- vbum1=vbuc1 
    lda #0
    sta errno_len
    // [2072] phi ferror::ch#10 = ferror::ch#0 [phi:ferror::@7->ferror::cbm_k_readst1#2] -- register_copy 
    // [2072] phi ferror::errno_parsed#2 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#3] -- vbuz1=vbuc1 
    sta.z errno_parsed
    // ferror::cbm_k_readst1
  cbm_k_readst1:
    // char status
    // [2073] ferror::cbm_k_readst1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2075] ferror::cbm_k_readst1_return#0 = ferror::cbm_k_readst1_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst1_return
    // ferror::cbm_k_readst1_@return
    // }
    // [2076] ferror::cbm_k_readst1_return#1 = ferror::cbm_k_readst1_return#0
    // ferror::@8
    // cbm_k_readst()
    // [2077] ferror::$6 = ferror::cbm_k_readst1_return#1
    // st = cbm_k_readst()
    // [2078] ferror::st#1 = ferror::$6
    // while (!(st = cbm_k_readst()))
    // [2079] if(0==ferror::st#1) goto ferror::@1 -- 0_eq_vbuz1_then_la1 
    lda.z st
    beq __b1
    // ferror::@2
    // __status = st
    // [2080] ((char *)&__stdio_file+$118)[ferror::sp#0] = ferror::st#1 -- pbuc1_derefidx_vbuz1=vbuz2 
    ldy.z sp
    sta __stdio_file+$118,y
    // cbm_k_close(15)
    // [2081] ferror::cbm_k_close1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_close1_channel
    // ferror::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // ferror::@9
    // return __errno;
    // [2083] ferror::return#1 = __errno#153 -- vwsm1=vwsz2 
    lda.z __errno
    sta return
    lda.z __errno+1
    sta return+1
    // ferror::@return
    // }
    // [2084] return 
    rts
    // ferror::@1
  __b1:
    // if (!errno_parsed)
    // [2085] if(0!=ferror::errno_parsed#2) goto ferror::@3 -- 0_neq_vbuz1_then_la1 
    lda.z errno_parsed
    bne __b3
    // ferror::@4
    // if (ch == ',')
    // [2086] if(ferror::ch#10!=',') goto ferror::@3 -- vbuz1_neq_vbuc1_then_la1 
    lda #','
    cmp.z ch
    bne __b3
    // ferror::@5
    // errno_parsed++;
    // [2087] ferror::errno_parsed#1 = ++ ferror::errno_parsed#2 -- vbuz1=_inc_vbuz1 
    inc.z errno_parsed
    // strncpy(temp, __errno_error, errno_len+1)
    // [2088] strncpy::n#0 = ferror::errno_len#10 + 1 -- vwuz1=vbum2_plus_1 
    lda errno_len
    clc
    adc #1
    sta.z strncpy.n
    lda #0
    adc #0
    sta.z strncpy.n+1
    // [2089] call strncpy
    // [2189] phi from ferror::@5 to strncpy [phi:ferror::@5->strncpy]
    jsr strncpy
    // [2090] phi from ferror::@5 to ferror::@13 [phi:ferror::@5->ferror::@13]
    // ferror::@13
    // atoi(temp)
    // [2091] call atoi
    // [2103] phi from ferror::@13 to atoi [phi:ferror::@13->atoi]
    // [2103] phi atoi::str#2 = ferror::temp [phi:ferror::@13->atoi#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z atoi.str
    lda #>temp
    sta.z atoi.str+1
    jsr atoi
    // atoi(temp)
    // [2092] atoi::return#4 = atoi::return#2
    // ferror::@14
    // __errno = atoi(temp)
    // [2093] __errno#2 = atoi::return#4 -- vwsz1=vwsz2 
    lda.z atoi.return
    sta.z __errno
    lda.z atoi.return+1
    sta.z __errno+1
    // [2094] phi from ferror::@1 ferror::@14 ferror::@4 to ferror::@3 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3]
    // [2094] phi __errno#111 = __errno#153 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#0] -- register_copy 
    // [2094] phi ferror::errno_parsed#11 = ferror::errno_parsed#2 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#1] -- register_copy 
    // ferror::@3
  __b3:
    // __errno_error[errno_len] = ch
    // [2095] __errno_error[ferror::errno_len#10] = ferror::ch#10 -- pbuc1_derefidx_vbum1=vbuz2 
    lda.z ch
    ldy errno_len
    sta __errno_error,y
    // errno_len++;
    // [2096] ferror::errno_len#1 = ++ ferror::errno_len#10 -- vbum1=_inc_vbum1 
    inc errno_len
    // ferror::cbm_k_chrin2
    // char ch
    // [2097] ferror::cbm_k_chrin2_ch = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chrin2_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin2_ch
    // return ch;
    // [2099] ferror::cbm_k_chrin2_return#0 = ferror::cbm_k_chrin2_ch -- vbuz1=vbuz2 
    sta.z cbm_k_chrin2_return
    // ferror::cbm_k_chrin2_@return
    // }
    // [2100] ferror::cbm_k_chrin2_return#1 = ferror::cbm_k_chrin2_return#0
    // ferror::@10
    // cbm_k_chrin()
    // [2101] ferror::$15 = ferror::cbm_k_chrin2_return#1
    // ch = cbm_k_chrin()
    // [2102] ferror::ch#1 = ferror::$15
    // [2072] phi from ferror::@10 to ferror::cbm_k_readst1 [phi:ferror::@10->ferror::cbm_k_readst1]
    // [2072] phi __errno#153 = __errno#111 [phi:ferror::@10->ferror::cbm_k_readst1#0] -- register_copy 
    // [2072] phi ferror::errno_len#10 = ferror::errno_len#1 [phi:ferror::@10->ferror::cbm_k_readst1#1] -- register_copy 
    // [2072] phi ferror::ch#10 = ferror::ch#1 [phi:ferror::@10->ferror::cbm_k_readst1#2] -- register_copy 
    // [2072] phi ferror::errno_parsed#2 = ferror::errno_parsed#11 [phi:ferror::@10->ferror::cbm_k_readst1#3] -- register_copy 
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
    errno_len: .byte 0
}
.segment Code
  // atoi
// Converts the string argument str to an integer.
// __zp($b4) int atoi(__zp($d4) const char *str)
atoi: {
    .label atoi__6 = $b4
    .label atoi__7 = $b4
    .label res = $b4
    // Initialize sign as positive
    .label i = $bf
    .label return = $b4
    .label str = $d4
    // Initialize result
    .label negative = $d3
    .label atoi__10 = $c3
    .label atoi__11 = $b4
    // if (str[i] == '-')
    // [2104] if(*atoi::str#2!='-') goto atoi::@3 -- _deref_pbuz1_neq_vbuc1_then_la1 
    ldy #0
    lda (str),y
    cmp #'-'
    bne __b2
    // [2105] phi from atoi to atoi::@2 [phi:atoi->atoi::@2]
    // atoi::@2
    // [2106] phi from atoi::@2 to atoi::@3 [phi:atoi::@2->atoi::@3]
    // [2106] phi atoi::negative#2 = 1 [phi:atoi::@2->atoi::@3#0] -- vbuz1=vbuc1 
    lda #1
    sta.z negative
    // [2106] phi atoi::res#2 = 0 [phi:atoi::@2->atoi::@3#1] -- vwsz1=vwsc1 
    tya
    sta.z res
    sta.z res+1
    // [2106] phi atoi::i#4 = 1 [phi:atoi::@2->atoi::@3#2] -- vbuz1=vbuc1 
    lda #1
    sta.z i
    jmp __b3
  // Iterate through all digits and update the result
    // [2106] phi from atoi to atoi::@3 [phi:atoi->atoi::@3]
  __b2:
    // [2106] phi atoi::negative#2 = 0 [phi:atoi->atoi::@3#0] -- vbuz1=vbuc1 
    lda #0
    sta.z negative
    // [2106] phi atoi::res#2 = 0 [phi:atoi->atoi::@3#1] -- vwsz1=vwsc1 
    sta.z res
    sta.z res+1
    // [2106] phi atoi::i#4 = 0 [phi:atoi->atoi::@3#2] -- vbuz1=vbuc1 
    sta.z i
    // atoi::@3
  __b3:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [2107] if(atoi::str#2[atoi::i#4]<'0') goto atoi::@5 -- pbuz1_derefidx_vbuz2_lt_vbuc1_then_la1 
    ldy.z i
    lda (str),y
    cmp #'0'
    bcc __b5
    // atoi::@6
    // [2108] if(atoi::str#2[atoi::i#4]<='9') goto atoi::@4 -- pbuz1_derefidx_vbuz2_le_vbuc1_then_la1 
    lda (str),y
    cmp #'9'
    bcc __b4
    beq __b4
    // atoi::@5
  __b5:
    // if(negative)
    // [2109] if(0!=atoi::negative#2) goto atoi::@1 -- 0_neq_vbuz1_then_la1 
    // Return result with sign
    lda.z negative
    bne __b1
    // [2111] phi from atoi::@1 atoi::@5 to atoi::@return [phi:atoi::@1/atoi::@5->atoi::@return]
    // [2111] phi atoi::return#2 = atoi::return#0 [phi:atoi::@1/atoi::@5->atoi::@return#0] -- register_copy 
    rts
    // atoi::@1
  __b1:
    // return -res;
    // [2110] atoi::return#0 = - atoi::res#2 -- vwsz1=_neg_vwsz1 
    lda #0
    sec
    sbc.z return
    sta.z return
    lda #0
    sbc.z return+1
    sta.z return+1
    // atoi::@return
    // }
    // [2112] return 
    rts
    // atoi::@4
  __b4:
    // res * 10
    // [2113] atoi::$10 = atoi::res#2 << 2 -- vwsz1=vwsz2_rol_2 
    lda.z res
    asl
    sta.z atoi__10
    lda.z res+1
    rol
    sta.z atoi__10+1
    asl.z atoi__10
    rol.z atoi__10+1
    // [2114] atoi::$11 = atoi::$10 + atoi::res#2 -- vwsz1=vwsz2_plus_vwsz1 
    clc
    lda.z atoi__11
    adc.z atoi__10
    sta.z atoi__11
    lda.z atoi__11+1
    adc.z atoi__10+1
    sta.z atoi__11+1
    // [2115] atoi::$6 = atoi::$11 << 1 -- vwsz1=vwsz1_rol_1 
    asl.z atoi__6
    rol.z atoi__6+1
    // res * 10 + str[i]
    // [2116] atoi::$7 = atoi::$6 + atoi::str#2[atoi::i#4] -- vwsz1=vwsz1_plus_pbuz2_derefidx_vbuz3 
    ldy.z i
    lda.z atoi__7
    clc
    adc (str),y
    sta.z atoi__7
    bcc !+
    inc.z atoi__7+1
  !:
    // res = res * 10 + str[i] - '0'
    // [2117] atoi::res#1 = atoi::$7 - '0' -- vwsz1=vwsz1_minus_vbuc1 
    lda.z res
    sec
    sbc #'0'
    sta.z res
    bcs !+
    dec.z res+1
  !:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [2118] atoi::i#2 = ++ atoi::i#4 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2106] phi from atoi::@4 to atoi::@3 [phi:atoi::@4->atoi::@3]
    // [2106] phi atoi::negative#2 = atoi::negative#2 [phi:atoi::@4->atoi::@3#0] -- register_copy 
    // [2106] phi atoi::res#2 = atoi::res#1 [phi:atoi::@4->atoi::@3#1] -- register_copy 
    // [2106] phi atoi::i#4 = atoi::i#2 [phi:atoi::@4->atoi::@3#2] -- register_copy 
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
// __zp($67) unsigned int cx16_k_macptr(__zp($bb) volatile char bytes, __zp($b6) void * volatile buffer)
cx16_k_macptr: {
    .label bytes = $bb
    .label buffer = $b6
    .label bytes_read = $77
    .label return = $67
    // unsigned int bytes_read
    // [2119] cx16_k_macptr::bytes_read = 0 -- vwuz1=vwuc1 
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
    // [2121] cx16_k_macptr::return#0 = cx16_k_macptr::bytes_read -- vwuz1=vwuz2 
    lda.z bytes_read
    sta.z return
    lda.z bytes_read+1
    sta.z return+1
    // cx16_k_macptr::@return
    // }
    // [2122] cx16_k_macptr::return#1 = cx16_k_macptr::return#0
    // [2123] return 
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
// __zp($36) char uctoa_append(__zp($cb) char *buffer, __zp($36) char value, __zp($43) char sub)
uctoa_append: {
    .label buffer = $cb
    .label value = $36
    .label sub = $43
    .label return = $36
    .label digit = $3b
    // [2125] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [2125] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [2125] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [2126] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbuz1_ge_vbuz2_then_la1 
    lda.z value
    cmp.z sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [2127] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [2128] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [2129] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [2130] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbuz1=vbuz1_minus_vbuz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    // [2125] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [2125] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [2125] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
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
// __zp($66) char rom_byte_compare(__zp($60) char *ptr_rom, __zp($5b) char value)
rom_byte_compare: {
    .label return = $66
    .label ptr_rom = $60
    .label value = $5b
    // if (*ptr_rom != value)
    // [2131] if(*rom_byte_compare::ptr_rom#0==rom_byte_compare::value#0) goto rom_byte_compare::@1 -- _deref_pbuz1_eq_vbuz2_then_la1 
    lda.z value
    ldy #0
    cmp (ptr_rom),y
    beq __b2
    // [2132] phi from rom_byte_compare to rom_byte_compare::@2 [phi:rom_byte_compare->rom_byte_compare::@2]
    // rom_byte_compare::@2
    // [2133] phi from rom_byte_compare::@2 to rom_byte_compare::@1 [phi:rom_byte_compare::@2->rom_byte_compare::@1]
    // [2133] phi rom_byte_compare::return#0 = 0 [phi:rom_byte_compare::@2->rom_byte_compare::@1#0] -- vbuz1=vbuc1 
    tya
    sta.z return
    rts
    // [2133] phi from rom_byte_compare to rom_byte_compare::@1 [phi:rom_byte_compare->rom_byte_compare::@1]
  __b2:
    // [2133] phi rom_byte_compare::return#0 = 1 [phi:rom_byte_compare->rom_byte_compare::@1#0] -- vbuz1=vbuc1 
    lda #1
    sta.z return
    // rom_byte_compare::@1
    // rom_byte_compare::@return
    // }
    // [2134] return 
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
// __zp($37) unsigned long ultoa_append(__zp($c9) char *buffer, __zp($37) unsigned long value, __zp($44) unsigned long sub)
ultoa_append: {
    .label buffer = $c9
    .label value = $37
    .label sub = $44
    .label return = $37
    .label digit = $3c
    // [2136] phi from ultoa_append to ultoa_append::@1 [phi:ultoa_append->ultoa_append::@1]
    // [2136] phi ultoa_append::digit#2 = 0 [phi:ultoa_append->ultoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [2136] phi ultoa_append::value#2 = ultoa_append::value#0 [phi:ultoa_append->ultoa_append::@1#1] -- register_copy 
    // ultoa_append::@1
  __b1:
    // while (value >= sub)
    // [2137] if(ultoa_append::value#2>=ultoa_append::sub#0) goto ultoa_append::@2 -- vduz1_ge_vduz2_then_la1 
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
    // [2138] *ultoa_append::buffer#0 = DIGITS[ultoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // ultoa_append::@return
    // }
    // [2139] return 
    rts
    // ultoa_append::@2
  __b2:
    // digit++;
    // [2140] ultoa_append::digit#1 = ++ ultoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [2141] ultoa_append::value#1 = ultoa_append::value#2 - ultoa_append::sub#0 -- vduz1=vduz1_minus_vduz2 
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
    // [2136] phi from ultoa_append::@2 to ultoa_append::@1 [phi:ultoa_append::@2->ultoa_append::@1]
    // [2136] phi ultoa_append::digit#2 = ultoa_append::digit#1 [phi:ultoa_append::@2->ultoa_append::@1#0] -- register_copy 
    // [2136] phi ultoa_append::value#2 = ultoa_append::value#1 [phi:ultoa_append::@2->ultoa_append::@1#1] -- register_copy 
    jmp __b1
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
// void rom_unlock(__zp($62) unsigned long address, __zp($70) char unlock_code)
rom_unlock: {
    .label chip_address = $5c
    .label address = $62
    .label unlock_code = $70
    // unsigned long chip_address = address & ROM_CHIP_MASK
    // [2143] rom_unlock::chip_address#0 = rom_unlock::address#3 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [2144] rom_write_byte::address#0 = rom_unlock::chip_address#0 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [2145] call rom_write_byte
  // This is a very important operation...
    // [2200] phi from rom_unlock to rom_write_byte [phi:rom_unlock->rom_write_byte]
    // [2200] phi rom_write_byte::value#10 = $aa [phi:rom_unlock->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$aa
    sta.z rom_write_byte.value
    // [2200] phi rom_write_byte::address#4 = rom_write_byte::address#0 [phi:rom_unlock->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@1
    // rom_write_byte(chip_address + 0x02AAA, 0x55)
    // [2146] rom_write_byte::address#1 = rom_unlock::chip_address#0 + $2aaa -- vduz1=vduz2_plus_vwuc1 
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
    // [2147] call rom_write_byte
    // [2200] phi from rom_unlock::@1 to rom_write_byte [phi:rom_unlock::@1->rom_write_byte]
    // [2200] phi rom_write_byte::value#10 = $55 [phi:rom_unlock::@1->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$55
    sta.z rom_write_byte.value
    // [2200] phi rom_write_byte::address#4 = rom_write_byte::address#1 [phi:rom_unlock::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@2
    // rom_write_byte(address, unlock_code)
    // [2148] rom_write_byte::address#2 = rom_unlock::address#3 -- vduz1=vduz2 
    lda.z address
    sta.z rom_write_byte.address
    lda.z address+1
    sta.z rom_write_byte.address+1
    lda.z address+2
    sta.z rom_write_byte.address+2
    lda.z address+3
    sta.z rom_write_byte.address+3
    // [2149] rom_write_byte::value#2 = rom_unlock::unlock_code#3 -- vbuz1=vbuz2 
    lda.z unlock_code
    sta.z rom_write_byte.value
    // [2150] call rom_write_byte
    // [2200] phi from rom_unlock::@2 to rom_write_byte [phi:rom_unlock::@2->rom_write_byte]
    // [2200] phi rom_write_byte::value#10 = rom_write_byte::value#2 [phi:rom_unlock::@2->rom_write_byte#0] -- register_copy 
    // [2200] phi rom_write_byte::address#4 = rom_write_byte::address#2 [phi:rom_unlock::@2->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@return
    // }
    // [2151] return 
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
// void rom_wait(__zp($2e) char *ptr_rom)
rom_wait: {
    .label rom_wait__0 = $29
    .label rom_wait__1 = $24
    .label test1 = $29
    .label test2 = $24
    .label ptr_rom = $2e
    // rom_wait::@1
  __b1:
    // test1 = *((brom_ptr_t)ptr_rom)
    // [2153] rom_wait::test1#1 = *rom_wait::ptr_rom#3 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (ptr_rom),y
    sta.z test1
    // test2 = *((brom_ptr_t)ptr_rom)
    // [2154] rom_wait::test2#1 = *rom_wait::ptr_rom#3 -- vbuz1=_deref_pbuz2 
    lda (ptr_rom),y
    sta.z test2
    // test1 & 0x40
    // [2155] rom_wait::$0 = rom_wait::test1#1 & $40 -- vbuz1=vbuz1_band_vbuc1 
    lda #$40
    and.z rom_wait__0
    sta.z rom_wait__0
    // test2 & 0x40
    // [2156] rom_wait::$1 = rom_wait::test2#1 & $40 -- vbuz1=vbuz1_band_vbuc1 
    lda #$40
    and.z rom_wait__1
    sta.z rom_wait__1
    // while ((test1 & 0x40) != (test2 & 0x40))
    // [2157] if(rom_wait::$0!=rom_wait::$1) goto rom_wait::@1 -- vbuz1_neq_vbuz2_then_la1 
    lda.z rom_wait__0
    cmp.z rom_wait__1
    bne __b1
    // rom_wait::@return
    // }
    // [2158] return 
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
// void rom_byte_program(__zp($4f) unsigned long address, __zp($55) char value)
rom_byte_program: {
    .label rom_ptr1_rom_byte_program__0 = $57
    .label rom_ptr1_rom_byte_program__2 = $57
    .label rom_ptr1_return = $57
    .label address = $4f
    .label value = $55
    // rom_byte_program::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2160] rom_byte_program::rom_ptr1_$2 = (unsigned int)rom_byte_program::address#0 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_byte_program__2
    lda.z address+1
    sta.z rom_ptr1_rom_byte_program__2+1
    // [2161] rom_byte_program::rom_ptr1_$0 = rom_byte_program::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_byte_program__0
    and #<$3fff
    sta.z rom_ptr1_rom_byte_program__0
    lda.z rom_ptr1_rom_byte_program__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_byte_program__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2162] rom_byte_program::rom_ptr1_return#0 = rom_byte_program::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_byte_program::@1
    // rom_write_byte(address, value)
    // [2163] rom_write_byte::address#3 = rom_byte_program::address#0
    // [2164] rom_write_byte::value#3 = rom_byte_program::value#0
    // [2165] call rom_write_byte
    // [2200] phi from rom_byte_program::@1 to rom_write_byte [phi:rom_byte_program::@1->rom_write_byte]
    // [2200] phi rom_write_byte::value#10 = rom_write_byte::value#3 [phi:rom_byte_program::@1->rom_write_byte#0] -- register_copy 
    // [2200] phi rom_write_byte::address#4 = rom_write_byte::address#3 [phi:rom_byte_program::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_byte_program::@2
    // rom_wait(ptr_rom)
    // [2166] rom_wait::ptr_rom#1 = (char *)rom_byte_program::rom_ptr1_return#0 -- pbuz1=pbuz2 
    lda.z rom_ptr1_return
    sta.z rom_wait.ptr_rom
    lda.z rom_ptr1_return+1
    sta.z rom_wait.ptr_rom+1
    // [2167] call rom_wait
    // [2152] phi from rom_byte_program::@2 to rom_wait [phi:rom_byte_program::@2->rom_wait]
    // [2152] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#1 [phi:rom_byte_program::@2->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_byte_program::@return
    // }
    // [2168] return 
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
// void memcpy8_vram_vram(__zp($26) char dbank_vram, __zp($31) unsigned int doffset_vram, __zp($25) char sbank_vram, __zp($2c) unsigned int soffset_vram, __zp($23) char num8)
memcpy8_vram_vram: {
    .label memcpy8_vram_vram__0 = $27
    .label memcpy8_vram_vram__1 = $28
    .label memcpy8_vram_vram__2 = $25
    .label memcpy8_vram_vram__3 = $2a
    .label memcpy8_vram_vram__4 = $2b
    .label memcpy8_vram_vram__5 = $26
    .label num8 = $23
    .label dbank_vram = $26
    .label doffset_vram = $31
    .label sbank_vram = $25
    .label soffset_vram = $2c
    .label num8_1 = $22
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2169] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [2170] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte0_vwuz2 
    lda.z soffset_vram
    sta.z memcpy8_vram_vram__0
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [2171] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [2172] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte1_vwuz2 
    lda.z soffset_vram+1
    sta.z memcpy8_vram_vram__1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [2173] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [2174] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuz1=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z memcpy8_vram_vram__2
    sta.z memcpy8_vram_vram__2
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [2175] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [2176] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [2177] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte0_vwuz2 
    lda.z doffset_vram
    sta.z memcpy8_vram_vram__3
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [2178] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [2179] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte1_vwuz2 
    lda.z doffset_vram+1
    sta.z memcpy8_vram_vram__4
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [2180] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [2181] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuz1=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z memcpy8_vram_vram__5
    sta.z memcpy8_vram_vram__5
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [2182] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // [2183] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [2183] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [2184] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbuz1=_dec_vbuz2 
    ldy.z num8_1
    dey
    sty.z num8
    // [2185] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbuz1_then_la1 
    lda.z num8_1
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [2186] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [2187] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [2188] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbuz1=vbuz2 
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
// char * strncpy(__zp($c7) char *dst, __zp($2e) const char *src, __zp($c3) unsigned int n)
strncpy: {
    .label c = $24
    .label dst = $c7
    .label i = $69
    .label src = $2e
    .label n = $c3
    // [2190] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [2190] phi strncpy::dst#2 = ferror::temp [phi:strncpy->strncpy::@1#0] -- pbuz1=pbuc1 
    lda #<ferror.temp
    sta.z dst
    lda #>ferror.temp
    sta.z dst+1
    // [2190] phi strncpy::src#2 = __errno_error [phi:strncpy->strncpy::@1#1] -- pbuz1=pbuc1 
    lda #<__errno_error
    sta.z src
    lda #>__errno_error
    sta.z src+1
    // [2190] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwuz1=vwuc1 
    lda #<0
    sta.z i
    sta.z i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [2191] if(strncpy::i#2<strncpy::n#0) goto strncpy::@2 -- vwuz1_lt_vwuz2_then_la1 
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
    // [2192] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [2193] strncpy::c#0 = *strncpy::src#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta.z c
    // if(c)
    // [2194] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbuz1_then_la1 
    beq __b3
    // strncpy::@4
    // src++;
    // [2195] strncpy::src#0 = ++ strncpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [2196] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [2196] phi strncpy::src#6 = strncpy::src#2 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [2197] *strncpy::dst#2 = strncpy::c#0 -- _deref_pbuz1=vbuz2 
    lda.z c
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [2198] strncpy::dst#0 = ++ strncpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [2199] strncpy::i#1 = ++ strncpy::i#2 -- vwuz1=_inc_vwuz1 
    inc.z i
    bne !+
    inc.z i+1
  !:
    // [2190] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [2190] phi strncpy::dst#2 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [2190] phi strncpy::src#2 = strncpy::src#6 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [2190] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
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
// void rom_write_byte(__zp($4f) unsigned long address, __zp($55) char value)
rom_write_byte: {
    .label rom_bank1_rom_write_byte__0 = $53
    .label rom_bank1_rom_write_byte__1 = $4b
    .label rom_bank1_rom_write_byte__2 = $41
    .label rom_ptr1_rom_write_byte__0 = $3f
    .label rom_ptr1_rom_write_byte__2 = $3f
    .label rom_bank1_bank_unshifted = $41
    .label rom_bank1_return = $56
    .label rom_ptr1_return = $3f
    .label address = $4f
    .label value = $55
    // rom_write_byte::rom_bank1
    // BYTE2(address)
    // [2201] rom_write_byte::rom_bank1_$0 = byte2  rom_write_byte::address#4 -- vbuz1=_byte2_vduz2 
    lda.z address+2
    sta.z rom_bank1_rom_write_byte__0
    // BYTE1(address)
    // [2202] rom_write_byte::rom_bank1_$1 = byte1  rom_write_byte::address#4 -- vbuz1=_byte1_vduz2 
    lda.z address+1
    sta.z rom_bank1_rom_write_byte__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2203] rom_write_byte::rom_bank1_$2 = rom_write_byte::rom_bank1_$0 w= rom_write_byte::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_write_byte__0
    sta.z rom_bank1_rom_write_byte__2+1
    lda.z rom_bank1_rom_write_byte__1
    sta.z rom_bank1_rom_write_byte__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2204] rom_write_byte::rom_bank1_bank_unshifted#0 = rom_write_byte::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2205] rom_write_byte::rom_bank1_return#0 = byte1  rom_write_byte::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwuz2 
    lda.z rom_bank1_bank_unshifted+1
    sta.z rom_bank1_return
    // rom_write_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2206] rom_write_byte::rom_ptr1_$2 = (unsigned int)rom_write_byte::address#4 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_write_byte__2
    lda.z address+1
    sta.z rom_ptr1_rom_write_byte__2+1
    // [2207] rom_write_byte::rom_ptr1_$0 = rom_write_byte::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_write_byte__0
    and #<$3fff
    sta.z rom_ptr1_rom_write_byte__0
    lda.z rom_ptr1_rom_write_byte__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_write_byte__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2208] rom_write_byte::rom_ptr1_return#0 = rom_write_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_write_byte::bank_set_brom1
    // BROM = bank
    // [2209] BROM = rom_write_byte::rom_bank1_return#0 -- vbuz1=vbuz2 
    lda.z rom_bank1_return
    sta.z BROM
    // rom_write_byte::@1
    // *ptr_rom = value
    // [2210] *((char *)rom_write_byte::rom_ptr1_return#0) = rom_write_byte::value#10 -- _deref_pbuz1=vbuz2 
    lda.z value
    ldy #0
    sta (rom_ptr1_return),y
    // rom_write_byte::@return
    // }
    // [2211] return 
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
  // Values of hexadecimal digits
  RADIX_HEXADECIMAL_VALUES_LONG: .dword $10000000, $1000000, $100000, $10000, $1000, $100, $10
  // Some addressing constants.
  // The different device IDs that can be returned from the manufacturer ID read sequence.
  // To print the graphics on the vera.
  file: .fill $20, 0
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
  status_text: .word __3, __4, __5, __6, __7, __8, __9, __10, __11
  status_color: .byte WHITE, BLACK, CYAN, CYAN, CYAN, CYAN, YELLOW, GREEN, RED
  __3: .text "Detected"
  .byte 0
  __4: .text "None"
  .byte 0
  __5: .text "Checking"
  .byte 0
  __6: .text "Checked"
  .byte 0
  __7: .text "Equating"
  .byte 0
  __8: .text "Equated"
  .byte 0
  __9: .text "Flashing"
  .byte 0
  __10: .text "Flashed"
  .byte 0
  __11: .text "Error"
  .byte 0
  info_text5: .text ""
  .byte 0
  s2: .text ":"
  .byte 0
  s5: .text " ..."
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
  smc_file_size: .word 0
  smc_file_size_1: .word 0
