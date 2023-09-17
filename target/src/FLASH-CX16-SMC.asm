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
  .label __snprintf_buffer = $e9
  .label __errno = $c1
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
// void snputc(__zp($c3) char c)
snputc: {
    .const OFFSET_STACK_C = 0
    .label c = $c3
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
    // [17] *__snprintf_buffer = snputc::c#2 -- _deref_pbuz1=vbuz2 
    // Append char
    lda.z c
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
    .label conio_x16_init__5 = $be
    // screenlayer1()
    // [20] call screenlayer1
    jsr screenlayer1
    // [21] phi from conio_x16_init to conio_x16_init::@1 [phi:conio_x16_init->conio_x16_init::@1]
    // conio_x16_init::@1
    // textcolor(CONIO_TEXTCOLOR_DEFAULT)
    // [22] call textcolor
    // [316] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [316] phi textcolor::color#16 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [23] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [24] call bgcolor
    // [321] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [321] phi bgcolor::color#14 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbuz1=vbuc1 
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
    // [334] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [334] phi gotoxy::y#22 = gotoxy::y#2 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [334] phi gotoxy::x#22 = gotoxy::x#2 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
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
// void cputc(__zp($3d) char c)
cputc: {
    .const OFFSET_STACK_C = 0
    .label cputc__1 = $22
    .label cputc__2 = $b4
    .label cputc__3 = $b5
    .label c = $3d
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
    .label main__33 = $d0
    .label main__77 = $b9
    .label ch = $eb
    .label rom_differences = $25
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
    // main::@30
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
    // [77] phi from main::cx16_k_screen_set_charset1 to main::@31 [phi:main::cx16_k_screen_set_charset1->main::@31]
    // main::@31
    // frame_init()
    // [78] call frame_init
    // [355] phi from main::@31 to frame_init [phi:main::@31->frame_init]
    jsr frame_init
    // [79] phi from main::@31 to main::@40 [phi:main::@31->main::@40]
    // main::@40
    // frame_draw()
    // [80] call frame_draw
    // [375] phi from main::@40 to frame_draw [phi:main::@40->frame_draw]
    jsr frame_draw
    // [81] phi from main::@40 to main::@41 [phi:main::@40->main::@41]
    // main::@41
    // info_title("Commander X16 Flash Utility!")
    // [82] call info_title
    // [416] phi from main::@41 to info_title [phi:main::@41->info_title]
    jsr info_title
    // [83] phi from main::@41 to main::@42 [phi:main::@41->main::@42]
    // main::@42
    // progress_clear()
    // [84] call progress_clear
    // [421] phi from main::@42 to progress_clear [phi:main::@42->progress_clear]
    jsr progress_clear
    // [85] phi from main::@42 to main::@43 [phi:main::@42->main::@43]
    // main::@43
    // info_clear_all()
    // [86] call info_clear_all
    // [436] phi from main::@43 to info_clear_all [phi:main::@43->info_clear_all]
    jsr info_clear_all
    // [87] phi from main::@43 to main::@44 [phi:main::@43->main::@44]
    // main::@44
    // info_line("Detecting SMC, VERA and ROM chipsets ...")
    // [88] call info_line
  // info_print(0, "The SMC chip on the X16 board controls the power on/off, keyboard and mouse pheripherals.");
  // info_print(1, "It is essential that the SMC chip gets updated together with the latest ROM on the X16 board.");
  // info_print(2, "On the X16 board, near the SMC chip are two jumpers");
    // [446] phi from main::@44 to info_line [phi:main::@44->info_line]
    // [446] phi info_line::info_text#16 = main::info_text1 [phi:main::@44->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z info_line.info_text
    lda #>info_text1
    sta.z info_line.info_text+1
    jsr info_line
    // main::SEI1
    // asm
    // asm { sei  }
    sei
    // [90] phi from main::SEI1 to main::@32 [phi:main::SEI1->main::@32]
    // main::@32
    // smc_detect()
    // [91] call smc_detect
    // [460] phi from main::@32 to smc_detect [phi:main::@32->smc_detect]
    jsr smc_detect
    // [92] phi from main::@32 to main::@45 [phi:main::@32->main::@45]
    // main::@45
    // chip_smc()
    // [93] call chip_smc
    // [462] phi from main::@45 to chip_smc [phi:main::@45->chip_smc]
    jsr chip_smc
    // [94] phi from main::@45 to main::@4 [phi:main::@45->main::@4]
    // main::@4
    // sprintf(info_text, "SMC installed, bootloader v%02x", smc_bootloader)
    // [95] call snprintf_init
    jsr snprintf_init
    // [96] phi from main::@4 to main::@46 [phi:main::@4->main::@46]
    // main::@46
    // sprintf(info_text, "SMC installed, bootloader v%02x", smc_bootloader)
    // [97] call printf_str
    // [471] phi from main::@46 to printf_str [phi:main::@46->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:main::@46->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = main::s1 [phi:main::@46->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // [98] phi from main::@46 to main::@47 [phi:main::@46->main::@47]
    // main::@47
    // sprintf(info_text, "SMC installed, bootloader v%02x", smc_bootloader)
    // [99] call printf_uint
    // [480] phi from main::@47 to printf_uint [phi:main::@47->printf_uint]
    // [480] phi printf_uint::format_zero_padding#11 = 1 [phi:main::@47->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [480] phi printf_uint::format_min_length#11 = 2 [phi:main::@47->printf_uint#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uint.format_min_length
    // [480] phi printf_uint::format_radix#11 = HEXADECIMAL [phi:main::@47->printf_uint#2] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [480] phi printf_uint::uvalue#11 = smc_detect::return#0 [phi:main::@47->printf_uint#3] -- vwuz1=vwuc1 
    lda #<smc_detect.return
    sta.z printf_uint.uvalue
    lda #>smc_detect.return
    sta.z printf_uint.uvalue+1
    jsr printf_uint
    // main::@48
    // sprintf(info_text, "SMC installed, bootloader v%02x", smc_bootloader)
    // [100] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [101] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_smc(STATUS_DETECTED, info_text)
    // [103] call info_smc
    // [490] phi from main::@48 to info_smc [phi:main::@48->info_smc]
    // [490] phi info_smc::info_text#10 = info_text [phi:main::@48->info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_smc.info_text
    lda #>@info_text
    sta.z info_smc.info_text+1
    // [490] phi info_smc::info_status#10 = 0 [phi:main::@48->info_smc#1] -- vbum1=vbuc1 
    lda #0
    sta info_smc.info_status
    jsr info_smc
    // main::CLI1
    // asm
    // asm { cli  }
    cli
    // [105] phi from main::CLI1 to main::@33 [phi:main::CLI1->main::@33]
    // main::@33
    // chip_vera()
    // [106] call chip_vera
  // Detecting VERA FPGA.
    // [505] phi from main::@33 to chip_vera [phi:main::@33->chip_vera]
    jsr chip_vera
    // [107] phi from main::@33 to main::@49 [phi:main::@33->main::@49]
    // main::@49
    // info_vera(STATUS_DETECTED, "VERA installed, OK")
    // [108] call info_vera
    jsr info_vera
    // main::SEI2
    // asm
    // asm { sei  }
    sei
    // [110] phi from main::SEI2 to main::@34 [phi:main::SEI2->main::@34]
    // main::@34
    // rom_detect()
    // [111] call rom_detect
  // Detecting ROM chips
    // [523] phi from main::@34 to rom_detect [phi:main::@34->rom_detect]
    jsr rom_detect
    // [112] phi from main::@34 to main::@50 [phi:main::@34->main::@50]
    // main::@50
    // chip_rom()
    // [113] call chip_rom
    // [581] phi from main::@50 to chip_rom [phi:main::@50->chip_rom]
    jsr chip_rom
    // [114] phi from main::@50 to main::@8 [phi:main::@50->main::@8]
    // [114] phi main::rom_error#104 = 0 [phi:main::@50->main::@8#0] -- vbum1=vbuc1 
    lda #0
    sta rom_error
    // [114] phi main::rom_chip#10 = 0 [phi:main::@50->main::@8#1] -- vbum1=vbuc1 
    sta rom_chip
    // main::@8
  __b8:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [115] if(main::rom_chip#10<8) goto main::@9 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcs !__b9+
    jmp __b9
  !__b9:
    // main::CLI2
    // asm
    // asm { cli  }
    cli
    // main::bank_set_brom2
    // BROM = bank
    // [117] BROM = main::bank_set_brom2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom2_bank
    sta.z BROM
    // main::@98
    // if (smc_error || rom_error || vera_error)
    // [118] if(0!=main::rom_error#104) goto main::@17 -- 0_neq_vbum1_then_la1 
    lda rom_error
    beq !__b17+
    jmp __b17
  !__b17:
    // [119] phi from main::@53 main::@98 to main::@1 [phi:main::@53/main::@98->main::@1]
    // main::@1
  __b1:
    // info_line("Checking update files SMC.BIN, VERA.BIN, ROM(x).BIN ...")
    // [120] call info_line
    // [446] phi from main::@1 to info_line [phi:main::@1->info_line]
    // [446] phi info_line::info_text#16 = main::info_text9 [phi:main::@1->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text9
    sta.z info_line.info_text
    lda #>info_text9
    sta.z info_line.info_text+1
    jsr info_line
    // main::SEI3
    // asm
    // asm { sei  }
    sei
    // [122] phi from main::SEI3 to main::@35 [phi:main::SEI3->main::@35]
    // main::@35
    // info_smc(STATUS_CHECKING, "Checking SMC.BIN file contents ...")
    // [123] call info_smc
  // Read the smc file content.
    // [490] phi from main::@35 to info_smc [phi:main::@35->info_smc]
    // [490] phi info_smc::info_text#10 = main::info_text10 [phi:main::@35->info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text10
    sta.z info_smc.info_text
    lda #>info_text10
    sta.z info_smc.info_text+1
    // [490] phi info_smc::info_status#10 = 2 [phi:main::@35->info_smc#1] -- vbum1=vbuc1 
    lda #2
    sta info_smc.info_status
    jsr info_smc
    // [124] phi from main::@35 to main::@51 [phi:main::@35->main::@51]
    // main::@51
    // unsigned int smc_file_size = smc_read(PROGRESS_X, PROGRESS_Y, PROGRESS_W, 8, 512, (ram_ptr_t)RAM_BASE)
    // [125] call smc_read
    // [599] phi from main::@51 to smc_read [phi:main::@51->smc_read]
    jsr smc_read
    // unsigned int smc_file_size = smc_read(PROGRESS_X, PROGRESS_Y, PROGRESS_W, 8, 512, (ram_ptr_t)RAM_BASE)
    // [126] smc_read::return#2 = smc_read::return#0
    // main::@52
    // [127] main::smc_file_size#0 = smc_read::return#2 -- vwum1=vwuz2 
    lda.z smc_read.return
    sta smc_file_size
    lda.z smc_read.return+1
    sta smc_file_size+1
    // if (!smc_file_size)
    // [128] if(0==main::smc_file_size#0) goto main::@2 -- 0_eq_vwum1_then_la1 
    // In case no file was found, set the status to error and skip to the next, else, mention the amount of bytes read.
    lda smc_file_size
    ora smc_file_size+1
    bne !__b2+
    jmp __b2
  !__b2:
    // main::@5
    // if(smc_file_size > 0x1E00)
    // [129] if(main::smc_file_size#0>$1e00) goto main::@18 -- vwum1_gt_vwuc1_then_la1 
    // If the smc.bin file size is larger than 0x1E00 then there is an error!
    lda #>$1e00
    cmp smc_file_size+1
    bcs !__b18+
    jmp __b18
  !__b18:
    bne !+
    lda #<$1e00
    cmp smc_file_size
    bcs !__b18+
    jmp __b18
  !__b18:
  !:
    // [130] phi from main::@5 to main::@6 [phi:main::@5->main::@6]
    // main::@6
    // sprintf(info_text, "SMC.BIN size %04x, OK!", smc_file_size)
    // [131] call snprintf_init
    jsr snprintf_init
    // [132] phi from main::@6 to main::@58 [phi:main::@6->main::@58]
    // main::@58
    // sprintf(info_text, "SMC.BIN size %04x, OK!", smc_file_size)
    // [133] call printf_str
    // [471] phi from main::@58 to printf_str [phi:main::@58->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:main::@58->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = main::s2 [phi:main::@58->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main::@59
    // sprintf(info_text, "SMC.BIN size %04x, OK!", smc_file_size)
    // [134] printf_uint::uvalue#10 = main::smc_file_size#0 -- vwuz1=vwum2 
    lda smc_file_size
    sta.z printf_uint.uvalue
    lda smc_file_size+1
    sta.z printf_uint.uvalue+1
    // [135] call printf_uint
    // [480] phi from main::@59 to printf_uint [phi:main::@59->printf_uint]
    // [480] phi printf_uint::format_zero_padding#11 = 1 [phi:main::@59->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [480] phi printf_uint::format_min_length#11 = 4 [phi:main::@59->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [480] phi printf_uint::format_radix#11 = HEXADECIMAL [phi:main::@59->printf_uint#2] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [480] phi printf_uint::uvalue#11 = printf_uint::uvalue#10 [phi:main::@59->printf_uint#3] -- register_copy 
    jsr printf_uint
    // [136] phi from main::@59 to main::@60 [phi:main::@59->main::@60]
    // main::@60
    // sprintf(info_text, "SMC.BIN size %04x, OK!", smc_file_size)
    // [137] call printf_str
    // [471] phi from main::@60 to printf_str [phi:main::@60->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:main::@60->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = main::s5 [phi:main::@60->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // main::@61
    // sprintf(info_text, "SMC.BIN size %04x, OK!", smc_file_size)
    // [138] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [139] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_smc(STATUS_CHECKED, info_text)
    // [141] call info_smc
    // [490] phi from main::@61 to info_smc [phi:main::@61->info_smc]
    // [490] phi info_smc::info_text#10 = info_text [phi:main::@61->info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_smc.info_text
    lda #>@info_text
    sta.z info_smc.info_text+1
    // [490] phi info_smc::info_status#10 = 3 [phi:main::@61->info_smc#1] -- vbum1=vbuc1 
    lda #3
    sta info_smc.info_status
    jsr info_smc
    // [142] phi from main::@61 to main::CLI3 [phi:main::@61->main::CLI3]
    // [142] phi main::smc_error#31 = 0 [phi:main::@61->main::CLI3#0] -- vbum1=vbuc1 
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
    // [145] phi from main::SEI4 to main::@19 [phi:main::SEI4->main::@19]
    // [145] phi __errno#10 = __errno#137 [phi:main::SEI4->main::@19#0] -- register_copy 
    // [145] phi main::rom_error#10 = main::rom_error#104 [phi:main::SEI4->main::@19#1] -- register_copy 
    // [145] phi main::rom_chip1#10 = 0 [phi:main::SEI4->main::@19#2] -- vbum1=vbuc1 
    lda #0
    sta rom_chip1
  // For checking, we loop first all the ROM chips and check the file contents.
  // Any error identified gets reported and this chip will not be flashed.
  // In case of ROM0.BIN in error, no flashing will be done!
    // main::@19
  __b19:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [146] if(main::rom_chip1#10<8) goto main::@20 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip1
    cmp #8
    bcs !__b20+
    jmp __b20
  !__b20:
    // main::bank_set_brom3
    // BROM = bank
    // [147] BROM = main::bank_set_brom3_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom3_bank
    sta.z BROM
    // [148] phi from main::bank_set_brom3 to main::@36 [phi:main::bank_set_brom3->main::@36]
    // main::@36
    // unsigned char ch = wait_key("Continue with flashing? [Y/N]", "nyNY")
    // [149] call wait_key
    // [632] phi from main::@36 to wait_key [phi:main::@36->wait_key]
    // [632] phi wait_key::filter#13 = main::filter1 [phi:main::@36->wait_key#0] -- pbuz1=pbuc1 
    lda #<filter1
    sta.z wait_key.filter
    lda #>filter1
    sta.z wait_key.filter+1
    // [632] phi wait_key::info_text#3 = main::info_text13 [phi:main::@36->wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text13
    sta.z wait_key.info_text
    lda #>info_text13
    sta.z wait_key.info_text+1
    jsr wait_key
    // unsigned char ch = wait_key("Continue with flashing? [Y/N]", "nyNY")
    // [150] wait_key::return#3 = wait_key::ch#4 -- vbuz1=vwuz2 
    lda.z wait_key.ch
    sta.z wait_key.return
    // main::@62
    // [151] main::ch#0 = wait_key::return#3
    // strchr("nN", ch)
    // [152] strchr::c#1 = main::ch#0
    // [153] call strchr
    // [656] phi from main::@62 to strchr [phi:main::@62->strchr]
    // [656] phi strchr::c#4 = strchr::c#1 [phi:main::@62->strchr#0] -- register_copy 
    // [656] phi strchr::str#2 = (const void *)main::$116 [phi:main::@62->strchr#1] -- pvoz1=pvoc1 
    lda #<main__116
    sta.z strchr.str
    lda #>main__116
    sta.z strchr.str+1
    jsr strchr
    // strchr("nN", ch)
    // [154] strchr::return#4 = strchr::return#2
    // main::@63
    // [155] main::$33 = strchr::return#4
    // if(strchr("nN", ch))
    // [156] if((void *)0==main::$33) goto main::@3 -- pvoc1_eq_pvoz1_then_la1 
    lda.z main__33
    cmp #<0
    bne !+
    lda.z main__33+1
    cmp #>0
    beq __b3
  !:
    // [157] phi from main::@63 to main::@29 [phi:main::@63->main::@29]
    // main::@29
    // info_line("The checked chipset does not match the flash requirements, exiting ... ")
    // [158] call info_line
    // [446] phi from main::@29 to info_line [phi:main::@29->info_line]
    // [446] phi info_line::info_text#16 = main::info_text16 [phi:main::@29->info_line#0] -- pbuz1=pbuc1 
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
    // [160] if(0!=main::smc_error#31) goto main::bank_set_brom5 -- 0_neq_vbum1_then_la1 
    lda smc_error
    bne bank_set_brom5
    // main::@99
    // [161] if(0!=main::rom_error#10) goto main::bank_set_brom5 -- 0_neq_vbum1_then_la1 
    lda rom_error
    bne bank_set_brom5
    // main::SEI5
    // asm
    // asm { sei  }
    sei
    // [163] phi from main::SEI5 to main::@39 [phi:main::SEI5->main::@39]
    // main::@39
    // info_line("Flashing SMC chip ...")
    // [164] call info_line
    // [446] phi from main::@39 to info_line [phi:main::@39->info_line]
    // [446] phi info_line::info_text#16 = main::info_text18 [phi:main::@39->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text18
    sta.z info_line.info_text
    lda #>info_text18
    sta.z info_line.info_text+1
    jsr info_line
    // main::@95
    // if (!smc_file_size)
    // [165] if(0!=main::smc_file_size#0) goto main::bank_set_brom5 -- 0_neq_vwum1_then_la1 
    lda smc_file_size
    ora smc_file_size+1
    bne bank_set_brom5
    // [166] phi from main::@95 to main::@7 [phi:main::@95->main::@7]
    // main::@7
    // info_smc(STATUS_FLASHING, "Press POWER/RESET on CX16 board!")
    // [167] call info_smc
    // [490] phi from main::@7 to info_smc [phi:main::@7->info_smc]
    // [490] phi info_smc::info_text#10 = main::info_text19 [phi:main::@7->info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text19
    sta.z info_smc.info_text
    lda #>info_text19
    sta.z info_smc.info_text+1
    // [490] phi info_smc::info_status#10 = 6 [phi:main::@7->info_smc#1] -- vbum1=vbuc1 
    lda #6
    sta info_smc.info_status
    jsr info_smc
    // main::@96
    // unsigned long flashed_bytes = flash_smc(PROGRESS_X, PROGRESS_Y, PROGRESS_W, smc_file_size, 8, 512, (ram_ptr_t)RAM_BASE)
    // [168] flash_smc::smc_bytes_total#0 = main::smc_file_size#0 -- vwuz1=vwum2 
    lda smc_file_size
    sta.z flash_smc.smc_bytes_total
    lda smc_file_size+1
    sta.z flash_smc.smc_bytes_total+1
    // [169] call flash_smc
    jsr flash_smc
    // [170] phi from main::@96 to main::@97 [phi:main::@96->main::@97]
    // main::@97
    // info_smc(STATUS_UPDATED, "OK")
    // [171] call info_smc
    // [490] phi from main::@97 to info_smc [phi:main::@97->info_smc]
    // [490] phi info_smc::info_text#10 = main::info_text20 [phi:main::@97->info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text20
    sta.z info_smc.info_text
    lda #>info_text20
    sta.z info_smc.info_text+1
    // [490] phi info_smc::info_status#10 = 7 [phi:main::@97->info_smc#1] -- vbum1=vbuc1 
    lda #7
    sta info_smc.info_status
    jsr info_smc
    // main::bank_set_brom5
  bank_set_brom5:
    // BROM = bank
    // [172] BROM = main::bank_set_brom5_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom5_bank
    sta.z BROM
    // main::CLI4
    // asm
    // asm { cli  }
    cli
    // [174] phi from main::CLI4 to main::@38 [phi:main::CLI4->main::@38]
    // main::@38
    // wait_key("Press any key ...", NULL)
    // [175] call wait_key
    // [632] phi from main::@38 to wait_key [phi:main::@38->wait_key]
    // [632] phi wait_key::filter#13 = 0 [phi:main::@38->wait_key#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z wait_key.filter
    sta.z wait_key.filter+1
    // [632] phi wait_key::info_text#3 = main::info_text17 [phi:main::@38->wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text17
    sta.z wait_key.info_text
    lda #>info_text17
    sta.z wait_key.info_text+1
    jsr wait_key
    rts
    // main::@20
  __b20:
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [176] if(rom_device_ids[main::rom_chip1#10]==$55) goto main::@21 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    ldy rom_chip1
    lda rom_device_ids,y
    cmp #$55
    bne !__b21+
    jmp __b21
  !__b21:
    // main::@25
    // info_rom(rom_chip, STATUS_CHECKING, "")
    // [177] info_rom::rom_chip#6 = main::rom_chip1#10 -- vbuz1=vbum2 
    tya
    sta.z info_rom.rom_chip
    // [178] call info_rom
  // Read the smc file content.
    // [829] phi from main::@25 to info_rom [phi:main::@25->info_rom]
    // [829] phi info_rom::info_text#12 = info_text14 [phi:main::@25->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text14
    sta.z info_rom.info_text
    lda #>info_text14
    sta.z info_rom.info_text+1
    // [829] phi info_rom::info_status#12 = 2 [phi:main::@25->info_rom#1] -- vbuz1=vbuc1 
    lda #2
    sta.z info_rom.info_status
    // [829] phi info_rom::rom_chip#12 = info_rom::rom_chip#6 [phi:main::@25->info_rom#2] -- register_copy 
    jsr info_rom
    // [179] phi from main::@25 to main::@64 [phi:main::@25->main::@64]
    // main::@64
    // progress_clear()
    // [180] call progress_clear
  // Set the info for the ROMs to Checking.
    // [421] phi from main::@64 to progress_clear [phi:main::@64->progress_clear]
    jsr progress_clear
    // main::bank_set_brom4
    // BROM = bank
    // [181] BROM = main::bank_set_brom4_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom4_bank
    sta.z BROM
    // [182] phi from main::bank_set_brom4 to main::@37 [phi:main::bank_set_brom4->main::@37]
    // main::@37
    // strcpy(file, "ROM .BIN")
    // [183] call strcpy
    // [858] phi from main::@37 to strcpy [phi:main::@37->strcpy]
    // [858] phi strcpy::dst#0 = file [phi:main::@37->strcpy#0] -- pbuz1=pbuc1 
    lda #<file
    sta.z strcpy.dst
    lda #>file
    sta.z strcpy.dst+1
    // [858] phi strcpy::src#0 = main::source [phi:main::@37->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // main::@65
    // 48+rom_chip
    // [184] main::$77 = $30 + main::rom_chip1#10 -- vbuz1=vbuc1_plus_vbum2 
    lda #$30
    clc
    adc rom_chip1
    sta.z main__77
    // file[3] = 48+rom_chip
    // [185] *(file+3) = main::$77 -- _deref_pbuc1=vbuz1 
    sta file+3
    // sprintf(info_text, "Opening %s flash file from SD card ...", file)
    // [186] call snprintf_init
    jsr snprintf_init
    // [187] phi from main::@65 to main::@66 [phi:main::@65->main::@66]
    // main::@66
    // sprintf(info_text, "Opening %s flash file from SD card ...", file)
    // [188] call printf_str
    // [471] phi from main::@66 to printf_str [phi:main::@66->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:main::@66->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = main::s6 [phi:main::@66->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // [189] phi from main::@66 to main::@67 [phi:main::@66->main::@67]
    // main::@67
    // sprintf(info_text, "Opening %s flash file from SD card ...", file)
    // [190] call printf_string
    // [866] phi from main::@67 to printf_string [phi:main::@67->printf_string]
    // [866] phi printf_string::putc#15 = &snputc [phi:main::@67->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [866] phi printf_string::str#15 = file [phi:main::@67->printf_string#1] -- pbuz1=pbuc1 
    lda #<file
    sta.z printf_string.str
    lda #>file
    sta.z printf_string.str+1
    // [866] phi printf_string::format_justify_left#15 = 0 [phi:main::@67->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [866] phi printf_string::format_min_length#15 = 0 [phi:main::@67->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [191] phi from main::@67 to main::@68 [phi:main::@67->main::@68]
    // main::@68
    // sprintf(info_text, "Opening %s flash file from SD card ...", file)
    // [192] call printf_str
    // [471] phi from main::@68 to printf_str [phi:main::@68->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:main::@68->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = main::s7 [phi:main::@68->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@69
    // sprintf(info_text, "Opening %s flash file from SD card ...", file)
    // [193] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [194] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [196] call info_line
    // [446] phi from main::@69 to info_line [phi:main::@69->info_line]
    // [446] phi info_line::info_text#16 = info_text [phi:main::@69->info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_line.info_text
    lda #>@info_text
    sta.z info_line.info_text+1
    jsr info_line
    // main::@70
    // unsigned char rom_bank = rom_chip * 32
    // [197] main::rom_bank#0 = main::rom_chip1#10 << 5 -- vbum1=vbum2_rol_5 
    lda rom_chip1
    asl
    asl
    asl
    asl
    asl
    sta rom_bank
    // unsigned long rom_bytes_read = rom_read(rom_bank, rom_sizes[rom_chip])
    // [198] main::$105 = main::rom_chip1#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip1
    asl
    asl
    sta main__105
    // [199] rom_read::rom_bank_start#1 = main::rom_bank#0 -- vbuz1=vbum2 
    lda rom_bank
    sta.z rom_read.rom_bank_start
    // [200] rom_read::rom_size#0 = rom_sizes[main::$105] -- vdum1=pduc1_derefidx_vbum2 
    ldy main__105
    lda rom_sizes,y
    sta rom_read.rom_size
    lda rom_sizes+1,y
    sta rom_read.rom_size+1
    lda rom_sizes+2,y
    sta rom_read.rom_size+2
    lda rom_sizes+3,y
    sta rom_read.rom_size+3
    // [201] call rom_read
    // [891] phi from main::@70 to rom_read [phi:main::@70->rom_read]
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(rom_bank, rom_sizes[rom_chip])
    // [202] rom_read::return#2 = rom_read::return#0
    // main::@71
    // [203] main::rom_bytes_read#0 = rom_read::return#2 -- vdum1=vduz2 
    lda.z rom_read.return
    sta rom_bytes_read
    lda.z rom_read.return+1
    sta rom_bytes_read+1
    lda.z rom_read.return+2
    sta rom_bytes_read+2
    lda.z rom_read.return+3
    sta rom_bytes_read+3
    // if (!rom_bytes_read)
    // [204] if(0==main::rom_bytes_read#0) goto main::@22 -- 0_eq_vdum1_then_la1 
    // In case no file was found, set the status to none and skip to the next, else, mention the amount of bytes read.
    lda rom_bytes_read
    ora rom_bytes_read+1
    ora rom_bytes_read+2
    ora rom_bytes_read+3
    bne !__b22+
    jmp __b22
  !__b22:
    // main::@26
    // unsigned long rom_file_modulo = rom_bytes_read % 0x4000
    // [205] main::rom_file_modulo#0 = main::rom_bytes_read#0 & $4000-1 -- vdum1=vdum2_band_vduc1 
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
    // [206] if(0!=main::rom_file_modulo#0) goto main::@23 -- 0_neq_vdum1_then_la1 
    lda rom_file_modulo
    ora rom_file_modulo+1
    ora rom_file_modulo+2
    ora rom_file_modulo+3
    beq !__b23+
    jmp __b23
  !__b23:
    // [207] phi from main::@26 to main::@27 [phi:main::@26->main::@27]
    // main::@27
    // sprintf(info_text, "File %s size %05x, OK!", file, rom_bytes_read)
    // [208] call snprintf_init
    jsr snprintf_init
    // [209] phi from main::@27 to main::@84 [phi:main::@27->main::@84]
    // main::@84
    // sprintf(info_text, "File %s size %05x, OK!", file, rom_bytes_read)
    // [210] call printf_str
    // [471] phi from main::@84 to printf_str [phi:main::@84->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:main::@84->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = main::s8 [phi:main::@84->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // [211] phi from main::@84 to main::@85 [phi:main::@84->main::@85]
    // main::@85
    // sprintf(info_text, "File %s size %05x, OK!", file, rom_bytes_read)
    // [212] call printf_string
    // [866] phi from main::@85 to printf_string [phi:main::@85->printf_string]
    // [866] phi printf_string::putc#15 = &snputc [phi:main::@85->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [866] phi printf_string::str#15 = file [phi:main::@85->printf_string#1] -- pbuz1=pbuc1 
    lda #<file
    sta.z printf_string.str
    lda #>file
    sta.z printf_string.str+1
    // [866] phi printf_string::format_justify_left#15 = 0 [phi:main::@85->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [866] phi printf_string::format_min_length#15 = 0 [phi:main::@85->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [213] phi from main::@85 to main::@86 [phi:main::@85->main::@86]
    // main::@86
    // sprintf(info_text, "File %s size %05x, OK!", file, rom_bytes_read)
    // [214] call printf_str
    // [471] phi from main::@86 to printf_str [phi:main::@86->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:main::@86->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = main::s11 [phi:main::@86->printf_str#1] -- pbuz1=pbuc1 
    lda #<s11
    sta.z printf_str.s
    lda #>s11
    sta.z printf_str.s+1
    jsr printf_str
    // main::@87
    // sprintf(info_text, "File %s size %05x, OK!", file, rom_bytes_read)
    // [215] printf_ulong::uvalue#6 = main::rom_bytes_read#0 -- vduz1=vdum2 
    lda rom_bytes_read
    sta.z printf_ulong.uvalue
    lda rom_bytes_read+1
    sta.z printf_ulong.uvalue+1
    lda rom_bytes_read+2
    sta.z printf_ulong.uvalue+2
    lda rom_bytes_read+3
    sta.z printf_ulong.uvalue+3
    // [216] call printf_ulong
    // [963] phi from main::@87 to printf_ulong [phi:main::@87->printf_ulong]
    // [963] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#6 [phi:main::@87->printf_ulong#0] -- register_copy 
    jsr printf_ulong
    // [217] phi from main::@87 to main::@88 [phi:main::@87->main::@88]
    // main::@88
    // sprintf(info_text, "File %s size %05x, OK!", file, rom_bytes_read)
    // [218] call printf_str
    // [471] phi from main::@88 to printf_str [phi:main::@88->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:main::@88->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = main::s5 [phi:main::@88->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // main::@89
    // sprintf(info_text, "File %s size %05x, OK!", file, rom_bytes_read)
    // [219] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [220] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom(rom_chip, STATUS_CHECKED, info_text)
    // [222] info_rom::rom_chip#9 = main::rom_chip1#10 -- vbuz1=vbum2 
    lda rom_chip1
    sta.z info_rom.rom_chip
    // [223] call info_rom
    // [829] phi from main::@89 to info_rom [phi:main::@89->info_rom]
    // [829] phi info_rom::info_text#12 = info_text [phi:main::@89->info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_rom.info_text
    lda #>@info_text
    sta.z info_rom.info_text+1
    // [829] phi info_rom::info_status#12 = 3 [phi:main::@89->info_rom#1] -- vbuz1=vbuc1 
    lda #3
    sta.z info_rom.info_status
    // [829] phi info_rom::rom_chip#12 = info_rom::rom_chip#9 [phi:main::@89->info_rom#2] -- register_copy 
    jsr info_rom
    // main::@90
    // file_sizes[rom_chip] = rom_bytes_read
    // [224] file_sizes[main::$105] = main::rom_bytes_read#0 -- pduc1_derefidx_vbum1=vdum2 
    ldy main__105
    lda rom_bytes_read
    sta file_sizes,y
    lda rom_bytes_read+1
    sta file_sizes+1,y
    lda rom_bytes_read+2
    sta file_sizes+2,y
    lda rom_bytes_read+3
    sta file_sizes+3,y
    // unsigned long rom_differences = rom_verify(
    //                         rom_chip, rom_bank, file_sizes[rom_chip])
    // [225] rom_verify::rom_chip#0 = main::rom_chip1#10 -- vbum1=vbum2 
    lda rom_chip1
    sta rom_verify.rom_chip
    // [226] rom_verify::rom_bank_start#0 = main::rom_bank#0 -- vbuz1=vbum2 
    lda rom_bank
    sta.z rom_verify.rom_bank_start
    // [227] rom_verify::file_size#0 = file_sizes[main::$105] -- vdum1=pduc1_derefidx_vbum2 
    lda file_sizes,y
    sta rom_verify.file_size
    lda file_sizes+1,y
    sta rom_verify.file_size+1
    lda file_sizes+2,y
    sta rom_verify.file_size+2
    lda file_sizes+3,y
    sta rom_verify.file_size+3
    // [228] call rom_verify
  // Verify the ROM...
    // [970] phi from main::@90 to rom_verify [phi:main::@90->rom_verify]
    jsr rom_verify
    // unsigned long rom_differences = rom_verify(
    //                         rom_chip, rom_bank, file_sizes[rom_chip])
    // [229] rom_verify::return#2 = rom_verify::rom_difference_bytes#10
    // main::@91
    // [230] main::rom_differences#0 = rom_verify::return#2 -- vduz1=vdum2 
    lda rom_verify.return
    sta.z rom_differences
    lda rom_verify.return+1
    sta.z rom_differences+1
    lda rom_verify.return+2
    sta.z rom_differences+2
    lda rom_verify.return+3
    sta.z rom_differences+3
    // if (rom_differences)
    // [231] if(0!=main::rom_differences#0) goto main::@24 -- 0_neq_vduz1_then_la1 
    lda.z rom_differences
    ora.z rom_differences+1
    ora.z rom_differences+2
    ora.z rom_differences+3
    bne __b24
    // main::@28
    // info_rom(rom_chip, STATUS_NONE, "No flashing required!")
    // [232] info_rom::rom_chip#11 = main::rom_chip1#10 -- vbuz1=vbum2 
    lda rom_chip1
    sta.z info_rom.rom_chip
    // [233] call info_rom
    // [829] phi from main::@28 to info_rom [phi:main::@28->info_rom]
    // [829] phi info_rom::info_text#12 = main::info_text15 [phi:main::@28->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text15
    sta.z info_rom.info_text
    lda #>info_text15
    sta.z info_rom.info_text+1
    // [829] phi info_rom::info_status#12 = 1 [phi:main::@28->info_rom#1] -- vbuz1=vbuc1 
    lda #1
    sta.z info_rom.info_status
    // [829] phi info_rom::rom_chip#12 = info_rom::rom_chip#11 [phi:main::@28->info_rom#2] -- register_copy 
    jsr info_rom
    // [234] phi from main::@20 main::@28 main::@75 main::@94 to main::@21 [phi:main::@20/main::@28/main::@75/main::@94->main::@21]
    // [234] phi __errno#130 = __errno#10 [phi:main::@20/main::@28/main::@75/main::@94->main::@21#0] -- register_copy 
    // [234] phi main::rom_error#25 = main::rom_error#10 [phi:main::@20/main::@28/main::@75/main::@94->main::@21#1] -- register_copy 
    // main::@21
  __b21:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [235] main::rom_chip1#1 = ++ main::rom_chip1#10 -- vbum1=_inc_vbum1 
    inc rom_chip1
    // [145] phi from main::@21 to main::@19 [phi:main::@21->main::@19]
    // [145] phi __errno#10 = __errno#130 [phi:main::@21->main::@19#0] -- register_copy 
    // [145] phi main::rom_error#10 = main::rom_error#25 [phi:main::@21->main::@19#1] -- register_copy 
    // [145] phi main::rom_chip1#10 = main::rom_chip1#1 [phi:main::@21->main::@19#2] -- register_copy 
    jmp __b19
    // [236] phi from main::@91 to main::@24 [phi:main::@91->main::@24]
    // main::@24
  __b24:
    // sprintf(info_text, "%05x differences found!", rom_differences)
    // [237] call snprintf_init
    jsr snprintf_init
    // main::@92
    // [238] printf_ulong::uvalue#7 = main::rom_differences#0
    // [239] call printf_ulong
    // [963] phi from main::@92 to printf_ulong [phi:main::@92->printf_ulong]
    // [963] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#7 [phi:main::@92->printf_ulong#0] -- register_copy 
    jsr printf_ulong
    // [240] phi from main::@92 to main::@93 [phi:main::@92->main::@93]
    // main::@93
    // sprintf(info_text, "%05x differences found!", rom_differences)
    // [241] call printf_str
    // [471] phi from main::@93 to printf_str [phi:main::@93->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:main::@93->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = main::s17 [phi:main::@93->printf_str#1] -- pbuz1=pbuc1 
    lda #<s17
    sta.z printf_str.s
    lda #>s17
    sta.z printf_str.s+1
    jsr printf_str
    // main::@94
    // sprintf(info_text, "%05x differences found!", rom_differences)
    // [242] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [243] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom(rom_chip, STATUS_COMPARED, info_text)
    // [245] info_rom::rom_chip#10 = main::rom_chip1#10 -- vbuz1=vbum2 
    lda rom_chip1
    sta.z info_rom.rom_chip
    // [246] call info_rom
    // [829] phi from main::@94 to info_rom [phi:main::@94->info_rom]
    // [829] phi info_rom::info_text#12 = info_text [phi:main::@94->info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_rom.info_text
    lda #>@info_text
    sta.z info_rom.info_text+1
    // [829] phi info_rom::info_status#12 = 5 [phi:main::@94->info_rom#1] -- vbuz1=vbuc1 
    lda #5
    sta.z info_rom.info_status
    // [829] phi info_rom::rom_chip#12 = info_rom::rom_chip#10 [phi:main::@94->info_rom#2] -- register_copy 
    jsr info_rom
    jmp __b21
    // main::@23
  __b23:
    // sprintf(info_text, "File %s size %05x, %05x off!", file, rom_bytes_read, 0x4000UL - rom_file_modulo)
    // [247] printf_ulong::uvalue#5 = $4000 - main::rom_file_modulo#0 -- vdum1=vduc1_minus_vdum1 
    lda #<$4000
    sec
    sbc printf_ulong.uvalue_1
    sta printf_ulong.uvalue_1
    lda #>$4000
    sbc printf_ulong.uvalue_1+1
    sta printf_ulong.uvalue_1+1
    lda #<$4000>>$10
    sbc printf_ulong.uvalue_1+2
    sta printf_ulong.uvalue_1+2
    lda #>$4000>>$10
    sbc printf_ulong.uvalue_1+3
    sta printf_ulong.uvalue_1+3
    // [248] call snprintf_init
    jsr snprintf_init
    // [249] phi from main::@23 to main::@76 [phi:main::@23->main::@76]
    // main::@76
    // sprintf(info_text, "File %s size %05x, %05x off!", file, rom_bytes_read, 0x4000UL - rom_file_modulo)
    // [250] call printf_str
    // [471] phi from main::@76 to printf_str [phi:main::@76->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:main::@76->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = main::s8 [phi:main::@76->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // [251] phi from main::@76 to main::@77 [phi:main::@76->main::@77]
    // main::@77
    // sprintf(info_text, "File %s size %05x, %05x off!", file, rom_bytes_read, 0x4000UL - rom_file_modulo)
    // [252] call printf_string
    // [866] phi from main::@77 to printf_string [phi:main::@77->printf_string]
    // [866] phi printf_string::putc#15 = &snputc [phi:main::@77->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [866] phi printf_string::str#15 = file [phi:main::@77->printf_string#1] -- pbuz1=pbuc1 
    lda #<file
    sta.z printf_string.str
    lda #>file
    sta.z printf_string.str+1
    // [866] phi printf_string::format_justify_left#15 = 0 [phi:main::@77->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [866] phi printf_string::format_min_length#15 = 0 [phi:main::@77->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [253] phi from main::@77 to main::@78 [phi:main::@77->main::@78]
    // main::@78
    // sprintf(info_text, "File %s size %05x, %05x off!", file, rom_bytes_read, 0x4000UL - rom_file_modulo)
    // [254] call printf_str
    // [471] phi from main::@78 to printf_str [phi:main::@78->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:main::@78->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = main::s11 [phi:main::@78->printf_str#1] -- pbuz1=pbuc1 
    lda #<s11
    sta.z printf_str.s
    lda #>s11
    sta.z printf_str.s+1
    jsr printf_str
    // main::@79
    // sprintf(info_text, "File %s size %05x, %05x off!", file, rom_bytes_read, 0x4000UL - rom_file_modulo)
    // [255] printf_ulong::uvalue#4 = main::rom_bytes_read#0 -- vduz1=vdum2 
    lda rom_bytes_read
    sta.z printf_ulong.uvalue
    lda rom_bytes_read+1
    sta.z printf_ulong.uvalue+1
    lda rom_bytes_read+2
    sta.z printf_ulong.uvalue+2
    lda rom_bytes_read+3
    sta.z printf_ulong.uvalue+3
    // [256] call printf_ulong
    // [963] phi from main::@79 to printf_ulong [phi:main::@79->printf_ulong]
    // [963] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#4 [phi:main::@79->printf_ulong#0] -- register_copy 
    jsr printf_ulong
    // [257] phi from main::@79 to main::@80 [phi:main::@79->main::@80]
    // main::@80
    // sprintf(info_text, "File %s size %05x, %05x off!", file, rom_bytes_read, 0x4000UL - rom_file_modulo)
    // [258] call printf_str
    // [471] phi from main::@80 to printf_str [phi:main::@80->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:main::@80->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = main::s12 [phi:main::@80->printf_str#1] -- pbuz1=pbuc1 
    lda #<s12
    sta.z printf_str.s
    lda #>s12
    sta.z printf_str.s+1
    jsr printf_str
    // main::@81
    // [259] printf_ulong::uvalue#13 = printf_ulong::uvalue#5 -- vduz1=vdum2 
    lda printf_ulong.uvalue_1
    sta.z printf_ulong.uvalue
    lda printf_ulong.uvalue_1+1
    sta.z printf_ulong.uvalue+1
    lda printf_ulong.uvalue_1+2
    sta.z printf_ulong.uvalue+2
    lda printf_ulong.uvalue_1+3
    sta.z printf_ulong.uvalue+3
    // sprintf(info_text, "File %s size %05x, %05x off!", file, rom_bytes_read, 0x4000UL - rom_file_modulo)
    // [260] call printf_ulong
    // [963] phi from main::@81 to printf_ulong [phi:main::@81->printf_ulong]
    // [963] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#13 [phi:main::@81->printf_ulong#0] -- register_copy 
    jsr printf_ulong
    // [261] phi from main::@81 to main::@82 [phi:main::@81->main::@82]
    // main::@82
    // sprintf(info_text, "File %s size %05x, %05x off!", file, rom_bytes_read, 0x4000UL - rom_file_modulo)
    // [262] call printf_str
    // [471] phi from main::@82 to printf_str [phi:main::@82->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:main::@82->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = main::s13 [phi:main::@82->printf_str#1] -- pbuz1=pbuc1 
    lda #<s13
    sta.z printf_str.s
    lda #>s13
    sta.z printf_str.s+1
    jsr printf_str
    // main::@83
    // sprintf(info_text, "File %s size %05x, %05x off!", file, rom_bytes_read, 0x4000UL - rom_file_modulo)
    // [263] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [264] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom(rom_chip, STATUS_ERROR, info_text)
    // [266] info_rom::rom_chip#8 = main::rom_chip1#10 -- vbuz1=vbum2 
    lda rom_chip1
    sta.z info_rom.rom_chip
    // [267] call info_rom
    // [829] phi from main::@83 to info_rom [phi:main::@83->info_rom]
    // [829] phi info_rom::info_text#12 = info_text [phi:main::@83->info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_rom.info_text
    lda #>@info_text
    sta.z info_rom.info_text+1
    // [829] phi info_rom::info_status#12 = 8 [phi:main::@83->info_rom#1] -- vbuz1=vbuc1 
    lda #8
    sta.z info_rom.info_status
    // [829] phi info_rom::rom_chip#12 = info_rom::rom_chip#8 [phi:main::@83->info_rom#2] -- register_copy 
    jsr info_rom
    // [234] phi from main::@83 to main::@21 [phi:main::@83->main::@21]
    // [234] phi __errno#130 = __errno#137 [phi:main::@83->main::@21#0] -- register_copy 
    // [234] phi main::rom_error#25 = 1 [phi:main::@83->main::@21#1] -- vbum1=vbuc1 
    lda #1
    sta rom_error
    jmp __b21
    // [268] phi from main::@71 to main::@22 [phi:main::@71->main::@22]
    // main::@22
  __b22:
    // sprintf(info_text, "File %s empty or not found!", file)
    // [269] call snprintf_init
    jsr snprintf_init
    // [270] phi from main::@22 to main::@72 [phi:main::@22->main::@72]
    // main::@72
    // sprintf(info_text, "File %s empty or not found!", file)
    // [271] call printf_str
    // [471] phi from main::@72 to printf_str [phi:main::@72->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:main::@72->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = main::s8 [phi:main::@72->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // [272] phi from main::@72 to main::@73 [phi:main::@72->main::@73]
    // main::@73
    // sprintf(info_text, "File %s empty or not found!", file)
    // [273] call printf_string
    // [866] phi from main::@73 to printf_string [phi:main::@73->printf_string]
    // [866] phi printf_string::putc#15 = &snputc [phi:main::@73->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [866] phi printf_string::str#15 = file [phi:main::@73->printf_string#1] -- pbuz1=pbuc1 
    lda #<file
    sta.z printf_string.str
    lda #>file
    sta.z printf_string.str+1
    // [866] phi printf_string::format_justify_left#15 = 0 [phi:main::@73->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [866] phi printf_string::format_min_length#15 = 0 [phi:main::@73->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [274] phi from main::@73 to main::@74 [phi:main::@73->main::@74]
    // main::@74
    // sprintf(info_text, "File %s empty or not found!", file)
    // [275] call printf_str
    // [471] phi from main::@74 to printf_str [phi:main::@74->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:main::@74->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = main::s9 [phi:main::@74->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // main::@75
    // sprintf(info_text, "File %s empty or not found!", file)
    // [276] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [277] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom(rom_chip, STATUS_NONE, info_text)
    // [279] info_rom::rom_chip#7 = main::rom_chip1#10 -- vbuz1=vbum2 
    lda rom_chip1
    sta.z info_rom.rom_chip
    // [280] call info_rom
    // [829] phi from main::@75 to info_rom [phi:main::@75->info_rom]
    // [829] phi info_rom::info_text#12 = info_text [phi:main::@75->info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_rom.info_text
    lda #>@info_text
    sta.z info_rom.info_text+1
    // [829] phi info_rom::info_status#12 = 1 [phi:main::@75->info_rom#1] -- vbuz1=vbuc1 
    lda #1
    sta.z info_rom.info_status
    // [829] phi info_rom::rom_chip#12 = info_rom::rom_chip#7 [phi:main::@75->info_rom#2] -- register_copy 
    jsr info_rom
    jmp __b21
    // [281] phi from main::@5 to main::@18 [phi:main::@5->main::@18]
    // main::@18
  __b18:
    // sprintf(info_text, "SMC.BIN size %04x, too large!", smc_file_size)
    // [282] call snprintf_init
    jsr snprintf_init
    // [283] phi from main::@18 to main::@54 [phi:main::@18->main::@54]
    // main::@54
    // sprintf(info_text, "SMC.BIN size %04x, too large!", smc_file_size)
    // [284] call printf_str
    // [471] phi from main::@54 to printf_str [phi:main::@54->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:main::@54->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = main::s2 [phi:main::@54->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main::@55
    // sprintf(info_text, "SMC.BIN size %04x, too large!", smc_file_size)
    // [285] printf_uint::uvalue#9 = main::smc_file_size#0 -- vwuz1=vwum2 
    lda smc_file_size
    sta.z printf_uint.uvalue
    lda smc_file_size+1
    sta.z printf_uint.uvalue+1
    // [286] call printf_uint
    // [480] phi from main::@55 to printf_uint [phi:main::@55->printf_uint]
    // [480] phi printf_uint::format_zero_padding#11 = 1 [phi:main::@55->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [480] phi printf_uint::format_min_length#11 = 4 [phi:main::@55->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [480] phi printf_uint::format_radix#11 = HEXADECIMAL [phi:main::@55->printf_uint#2] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [480] phi printf_uint::uvalue#11 = printf_uint::uvalue#9 [phi:main::@55->printf_uint#3] -- register_copy 
    jsr printf_uint
    // [287] phi from main::@55 to main::@56 [phi:main::@55->main::@56]
    // main::@56
    // sprintf(info_text, "SMC.BIN size %04x, too large!", smc_file_size)
    // [288] call printf_str
    // [471] phi from main::@56 to printf_str [phi:main::@56->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:main::@56->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = main::s3 [phi:main::@56->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // main::@57
    // sprintf(info_text, "SMC.BIN size %04x, too large!", smc_file_size)
    // [289] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [290] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_smc(STATUS_ERROR, info_text)
    // [292] call info_smc
    // [490] phi from main::@57 to info_smc [phi:main::@57->info_smc]
    // [490] phi info_smc::info_text#10 = info_text [phi:main::@57->info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_smc.info_text
    lda #>@info_text
    sta.z info_smc.info_text+1
    // [490] phi info_smc::info_status#10 = 8 [phi:main::@57->info_smc#1] -- vbum1=vbuc1 
    lda #8
    sta info_smc.info_status
    jsr info_smc
    // [142] phi from main::@2 main::@57 to main::CLI3 [phi:main::@2/main::@57->main::CLI3]
  __b4:
    // [142] phi main::smc_error#31 = 1 [phi:main::@2/main::@57->main::CLI3#0] -- vbum1=vbuc1 
    lda #1
    sta smc_error
    jmp CLI3
    // [293] phi from main::@52 to main::@2 [phi:main::@52->main::@2]
    // main::@2
  __b2:
    // info_smc(STATUS_ERROR, "SMC.BIN empty or not found!")
    // [294] call info_smc
    // [490] phi from main::@2 to info_smc [phi:main::@2->info_smc]
    // [490] phi info_smc::info_text#10 = main::info_text12 [phi:main::@2->info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text12
    sta.z info_smc.info_text
    lda #>info_text12
    sta.z info_smc.info_text+1
    // [490] phi info_smc::info_status#10 = 8 [phi:main::@2->info_smc#1] -- vbum1=vbuc1 
    lda #8
    sta info_smc.info_status
    jsr info_smc
    jmp __b4
    // [295] phi from main::@98 to main::@17 [phi:main::@98->main::@17]
    // main::@17
  __b17:
    // wait_key("Mandatory chipsets not detected! Press [SPACE] to exit!", " ")
    // [296] call wait_key
    // [632] phi from main::@17 to wait_key [phi:main::@17->wait_key]
    // [632] phi wait_key::filter#13 = main::filter [phi:main::@17->wait_key#0] -- pbuz1=pbuc1 
    lda #<filter
    sta.z wait_key.filter
    lda #>filter
    sta.z wait_key.filter+1
    // [632] phi wait_key::info_text#3 = main::info_text11 [phi:main::@17->wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text11
    sta.z wait_key.info_text
    lda #>info_text11
    sta.z wait_key.info_text+1
    jsr wait_key
    // [297] phi from main::@17 to main::@53 [phi:main::@17->main::@53]
    // main::@53
    // system_reset()
    // [298] call system_reset
    // [1035] phi from main::@53 to system_reset [phi:main::@53->system_reset]
    jsr system_reset
    jmp __b1
    // main::@9
  __b9:
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [299] if(rom_device_ids[main::rom_chip#10]!=$55) goto main::@10 -- pbuc1_derefidx_vbum1_neq_vbuc2_then_la1 
    lda #$55
    ldy rom_chip
    cmp rom_device_ids,y
    bne __b10
    // main::@14
    // if(rom_chip != 0)
    // [300] if(main::rom_chip#10!=0) goto main::@11 -- vbum1_neq_0_then_la1 
    tya
    bne __b11
    // main::@15
    // info_rom(rom_chip, STATUS_ERROR, "CX16 ROM not installed!")
    // [301] info_rom::rom_chip#3 = main::rom_chip#10 -- vbuz1=vbum2 
    sta.z info_rom.rom_chip
    // [302] call info_rom
    // [829] phi from main::@15 to info_rom [phi:main::@15->info_rom]
    // [829] phi info_rom::info_text#12 = main::info_text6 [phi:main::@15->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text6
    sta.z info_rom.info_text
    lda #>info_text6
    sta.z info_rom.info_text+1
    // [829] phi info_rom::info_status#12 = 8 [phi:main::@15->info_rom#1] -- vbuz1=vbuc1 
    lda #8
    sta.z info_rom.info_status
    // [829] phi info_rom::rom_chip#12 = info_rom::rom_chip#3 [phi:main::@15->info_rom#2] -- register_copy 
    jsr info_rom
    // [303] phi from main::@15 to main::@12 [phi:main::@15->main::@12]
    // [303] phi main::rom_error#13 = 1 [phi:main::@15->main::@12#0] -- vbum1=vbuc1 
    lda #1
    sta rom_error
    // main::@12
  __b12:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [304] main::rom_chip#1 = ++ main::rom_chip#10 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [114] phi from main::@12 to main::@8 [phi:main::@12->main::@8]
    // [114] phi main::rom_error#104 = main::rom_error#13 [phi:main::@12->main::@8#0] -- register_copy 
    // [114] phi main::rom_chip#10 = main::rom_chip#1 [phi:main::@12->main::@8#1] -- register_copy 
    jmp __b8
    // main::@11
  __b11:
    // info_rom(rom_chip, STATUS_NONE, "CARD ROM not installed!")
    // [305] info_rom::rom_chip#2 = main::rom_chip#10 -- vbuz1=vbum2 
    lda rom_chip
    sta.z info_rom.rom_chip
    // [306] call info_rom
    // [829] phi from main::@11 to info_rom [phi:main::@11->info_rom]
    // [829] phi info_rom::info_text#12 = main::info_text5 [phi:main::@11->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z info_rom.info_text
    lda #>info_text5
    sta.z info_rom.info_text+1
    // [829] phi info_rom::info_status#12 = 1 [phi:main::@11->info_rom#1] -- vbuz1=vbuc1 
    lda #1
    sta.z info_rom.info_status
    // [829] phi info_rom::rom_chip#12 = info_rom::rom_chip#2 [phi:main::@11->info_rom#2] -- register_copy 
    jsr info_rom
    // [303] phi from main::@11 main::@13 main::@16 to main::@12 [phi:main::@11/main::@13/main::@16->main::@12]
    // [303] phi main::rom_error#13 = main::rom_error#104 [phi:main::@11/main::@13/main::@16->main::@12#0] -- register_copy 
    jmp __b12
    // main::@10
  __b10:
    // if(rom_chip != 0)
    // [307] if(main::rom_chip#10!=0) goto main::@13 -- vbum1_neq_0_then_la1 
    lda rom_chip
    bne __b13
    // main::@16
    // info_rom(rom_chip, STATUS_DETECTED, "CX16 ROM installed, OK!")
    // [308] info_rom::rom_chip#5 = main::rom_chip#10 -- vbuz1=vbum2 
    sta.z info_rom.rom_chip
    // [309] call info_rom
    // [829] phi from main::@16 to info_rom [phi:main::@16->info_rom]
    // [829] phi info_rom::info_text#12 = main::info_text8 [phi:main::@16->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z info_rom.info_text
    lda #>info_text8
    sta.z info_rom.info_text+1
    // [829] phi info_rom::info_status#12 = 0 [phi:main::@16->info_rom#1] -- vbuz1=vbuc1 
    lda #0
    sta.z info_rom.info_status
    // [829] phi info_rom::rom_chip#12 = info_rom::rom_chip#5 [phi:main::@16->info_rom#2] -- register_copy 
    jsr info_rom
    jmp __b12
    // main::@13
  __b13:
    // info_rom(rom_chip, STATUS_DETECTED, "CARD ROM installed, OK!")
    // [310] info_rom::rom_chip#4 = main::rom_chip#10 -- vbuz1=vbum2 
    lda rom_chip
    sta.z info_rom.rom_chip
    // [311] call info_rom
    // [829] phi from main::@13 to info_rom [phi:main::@13->info_rom]
    // [829] phi info_rom::info_text#12 = main::info_text7 [phi:main::@13->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z info_rom.info_text
    lda #>info_text7
    sta.z info_rom.info_text+1
    // [829] phi info_rom::info_status#12 = 0 [phi:main::@13->info_rom#1] -- vbuz1=vbuc1 
    lda #0
    sta.z info_rom.info_status
    // [829] phi info_rom::rom_chip#12 = info_rom::rom_chip#4 [phi:main::@13->info_rom#2] -- register_copy 
    jsr info_rom
    jmp __b12
  .segment Data
    info_text: .text "Commander X16 Flash Utility!"
    .byte 0
    info_text1: .text "Detecting SMC, VERA and ROM chipsets ..."
    .byte 0
    s1: .text "SMC installed, bootloader v"
    .byte 0
    info_text4: .text "VERA installed, OK"
    .byte 0
    info_text5: .text "CARD ROM not installed!"
    .byte 0
    info_text6: .text "CX16 ROM not installed!"
    .byte 0
    info_text7: .text "CARD ROM installed, OK!"
    .byte 0
    info_text8: .text "CX16 ROM installed, OK!"
    .byte 0
    info_text9: .text "Checking update files SMC.BIN, VERA.BIN, ROM(x).BIN ..."
    .byte 0
    info_text10: .text "Checking SMC.BIN file contents ..."
    .byte 0
    info_text11: .text "Mandatory chipsets not detected! Press [SPACE] to exit!"
    .byte 0
    filter: .text " "
    .byte 0
    info_text12: .text "SMC.BIN empty or not found!"
    .byte 0
    s2: .text "SMC.BIN size "
    .byte 0
    s3: .text ", too large!"
    .byte 0
    s5: .text ", OK!"
    .byte 0
    info_text13: .text "Continue with flashing? [Y/N]"
    .byte 0
    filter1: .text "nyNY"
    .byte 0
    main__116: .text "nN"
    .byte 0
    source: .text "ROM .BIN"
    .byte 0
    s6: .text "Opening "
    .byte 0
    s7: .text " flash file from SD card ..."
    .byte 0
    s8: .text "File "
    .byte 0
    s9: .text " empty or not found!"
    .byte 0
    s11: .text " size "
    .byte 0
    s12: .text ", "
    .byte 0
    s13: .text " off!"
    .byte 0
    s17: .text " differences found!"
    .byte 0
    info_text15: .text "No flashing required!"
    .byte 0
    info_text16: .text "The checked chipset does not match the flash requirements, exiting ... "
    .byte 0
    info_text17: .text "Press any key ..."
    .byte 0
    info_text18: .text "Flashing SMC chip ..."
    .byte 0
    info_text19: .text "Press POWER/RESET on CX16 board!"
    .byte 0
    info_text20: .text "OK"
    .byte 0
    main__105: .byte 0
    cx16_k_screen_set_charset1_charset: .byte 0
    cx16_k_screen_set_charset1_offset: .word 0
    rom_chip: .byte 0
    smc_file_size: .word 0
    rom_chip1: .byte 0
    rom_bank: .byte 0
    rom_bytes_read: .dword 0
    rom_file_modulo: .dword 0
    // The ROM chip on the CX16 should be installed!
    rom_error: .byte 0
    smc_error: .byte 0
}
.segment Code
  // screenlayer1
// Set the layer with which the conio will interact.
screenlayer1: {
    // screenlayer(1, *VERA_L1_MAPBASE, *VERA_L1_CONFIG)
    // [312] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbuz1=_deref_pbuc1 
    lda VERA_L1_MAPBASE
    sta.z screenlayer.mapbase
    // [313] screenlayer::config#0 = *VERA_L1_CONFIG -- vbuz1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta.z screenlayer.config
    // [314] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [315] return 
    rts
}
  // textcolor
// Set the front color for text output. The old front text color setting is returned.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char textcolor(__zp($be) char color)
textcolor: {
    .label textcolor__0 = $c4
    .label textcolor__1 = $be
    .label color = $be
    // __conio.color & 0xF0
    // [317] textcolor::$0 = *((char *)&__conio+$d) & $f0 -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$d
    sta.z textcolor__0
    // __conio.color & 0xF0 | color
    // [318] textcolor::$1 = textcolor::$0 | textcolor::color#16 -- vbuz1=vbuz2_bor_vbuz1 
    lda.z textcolor__1
    ora.z textcolor__0
    sta.z textcolor__1
    // __conio.color = __conio.color & 0xF0 | color
    // [319] *((char *)&__conio+$d) = textcolor::$1 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // textcolor::@return
    // }
    // [320] return 
    rts
}
  // bgcolor
// Set the back color for text output.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char bgcolor(__zp($be) char color)
bgcolor: {
    .label bgcolor__0 = $c0
    .label bgcolor__1 = $be
    .label bgcolor__2 = $c0
    .label color = $be
    // __conio.color & 0x0F
    // [322] bgcolor::$0 = *((char *)&__conio+$d) & $f -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$d
    sta.z bgcolor__0
    // color << 4
    // [323] bgcolor::$1 = bgcolor::color#14 << 4 -- vbuz1=vbuz1_rol_4 
    lda.z bgcolor__1
    asl
    asl
    asl
    asl
    sta.z bgcolor__1
    // __conio.color & 0x0F | color << 4
    // [324] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbuz1=vbuz1_bor_vbuz2 
    lda.z bgcolor__2
    ora.z bgcolor__1
    sta.z bgcolor__2
    // __conio.color = __conio.color & 0x0F | color << 4
    // [325] *((char *)&__conio+$d) = bgcolor::$2 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // bgcolor::@return
    // }
    // [326] return 
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
    // [327] *((char *)&__conio+$c) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$c
    // cursor::@return
    // }
    // [328] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    // __mem unsigned char x
    // [329] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [330] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [332] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwum1=vbum2_word_vbum3 
    lda x
    sta return+1
    lda y
    sta return
    // cbm_k_plot_get::@return
    // }
    // [333] return 
    rts
  .segment Data
    x: .byte 0
    y: .byte 0
    return: .word 0
}
.segment Code
  // gotoxy
// Set the cursor to the specified position
// void gotoxy(__zp($4c) char x, __zp($56) char y)
gotoxy: {
    .label gotoxy__2 = $4c
    .label gotoxy__3 = $4c
    .label gotoxy__6 = $4b
    .label gotoxy__7 = $4b
    .label gotoxy__8 = $68
    .label gotoxy__9 = $5d
    .label gotoxy__10 = $56
    .label x = $4c
    .label y = $56
    .label gotoxy__14 = $4b
    // (x>=__conio.width)?__conio.width:x
    // [335] if(gotoxy::x#22>=*((char *)&__conio+6)) goto gotoxy::@1 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z x
    cmp __conio+6
    bcs __b1
    // [337] phi from gotoxy gotoxy::@1 to gotoxy::@2 [phi:gotoxy/gotoxy::@1->gotoxy::@2]
    // [337] phi gotoxy::$3 = gotoxy::x#22 [phi:gotoxy/gotoxy::@1->gotoxy::@2#0] -- register_copy 
    jmp __b2
    // gotoxy::@1
  __b1:
    // [336] gotoxy::$2 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z gotoxy__2
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [338] *((char *)&__conio) = gotoxy::$3 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__3
    sta __conio
    // (y>=__conio.height)?__conio.height:y
    // [339] if(gotoxy::y#22>=*((char *)&__conio+7)) goto gotoxy::@3 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z y
    cmp __conio+7
    bcs __b3
    // gotoxy::@4
    // [340] gotoxy::$14 = gotoxy::y#22 -- vbuz1=vbuz2 
    sta.z gotoxy__14
    // [341] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [341] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [342] *((char *)&__conio+1) = gotoxy::$7 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__7
    sta __conio+1
    // __conio.cursor_x << 1
    // [343] gotoxy::$8 = *((char *)&__conio) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio
    asl
    sta.z gotoxy__8
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [344] gotoxy::$10 = gotoxy::y#22 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z gotoxy__10
    // [345] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwuz1=pwuc1_derefidx_vbuz2_plus_vbuz3 
    ldy.z gotoxy__10
    clc
    adc __conio+$15,y
    sta.z gotoxy__9
    lda __conio+$15+1,y
    adc #0
    sta.z gotoxy__9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [346] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwuz1 
    lda.z gotoxy__9
    sta __conio+$13
    lda.z gotoxy__9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [347] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [348] gotoxy::$6 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
    lda __conio+7
    sta.z gotoxy__6
    jmp __b5
}
  // cputln
// Print a newline
cputln: {
    .label cputln__2 = $ac
    // __conio.cursor_x = 0
    // [349] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y++;
    // [350] *((char *)&__conio+1) = ++ *((char *)&__conio+1) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+1
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [351] cputln::$2 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z cputln__2
    // [352] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [353] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [354] return 
    rts
}
  // frame_init
frame_init: {
    .const vera_display_set_hstart1_start = $b
    .const vera_display_set_hstop1_stop = $93
    .const vera_display_set_vstart1_start = $13
    .const vera_display_set_vstop1_stop = $db
    // textcolor(WHITE)
    // [356] call textcolor
  // Set the charset to lower case.
  // screenlayer1();
    // [316] phi from frame_init to textcolor [phi:frame_init->textcolor]
    // [316] phi textcolor::color#16 = WHITE [phi:frame_init->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [357] phi from frame_init to frame_init::@2 [phi:frame_init->frame_init::@2]
    // frame_init::@2
    // bgcolor(BLUE)
    // [358] call bgcolor
    // [321] phi from frame_init::@2 to bgcolor [phi:frame_init::@2->bgcolor]
    // [321] phi bgcolor::color#14 = BLUE [phi:frame_init::@2->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [359] phi from frame_init::@2 to frame_init::@3 [phi:frame_init::@2->frame_init::@3]
    // frame_init::@3
    // scroll(0)
    // [360] call scroll
    jsr scroll
    // [361] phi from frame_init::@3 to frame_init::@4 [phi:frame_init::@3->frame_init::@4]
    // frame_init::@4
    // clrscr()
    // [362] call clrscr
    jsr clrscr
    // frame_init::vera_display_set_hstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [363] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTART = start
    // [364] *VERA_DC_HSTART = frame_init::vera_display_set_hstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstart1_start
    sta VERA_DC_HSTART
    // frame_init::vera_display_set_hstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [365] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTOP = stop
    // [366] *VERA_DC_HSTOP = frame_init::vera_display_set_hstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstop1_stop
    sta VERA_DC_HSTOP
    // frame_init::vera_display_set_vstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [367] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTART = start
    // [368] *VERA_DC_VSTART = frame_init::vera_display_set_vstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstart1_start
    sta VERA_DC_VSTART
    // frame_init::vera_display_set_vstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [369] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTOP = stop
    // [370] *VERA_DC_VSTOP = frame_init::vera_display_set_vstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstop1_stop
    sta VERA_DC_VSTOP
    // frame_init::@1
    // cx16_k_screen_set_charset(3, (char *)0)
    // [371] frame_init::cx16_k_screen_set_charset1_charset = 3 -- vbum1=vbuc1 
    lda #3
    sta cx16_k_screen_set_charset1_charset
    // [372] frame_init::cx16_k_screen_set_charset1_offset = (char *) 0 -- pbum1=pbuc1 
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
    // [374] return 
    rts
  .segment Data
    cx16_k_screen_set_charset1_charset: .byte 0
    cx16_k_screen_set_charset1_offset: .word 0
}
.segment Code
  // frame_draw
frame_draw: {
    // textcolor(WHITE)
    // [376] call textcolor
    // [316] phi from frame_draw to textcolor [phi:frame_draw->textcolor]
    // [316] phi textcolor::color#16 = WHITE [phi:frame_draw->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [377] phi from frame_draw to frame_draw::@1 [phi:frame_draw->frame_draw::@1]
    // frame_draw::@1
    // bgcolor(BLUE)
    // [378] call bgcolor
    // [321] phi from frame_draw::@1 to bgcolor [phi:frame_draw::@1->bgcolor]
    // [321] phi bgcolor::color#14 = BLUE [phi:frame_draw::@1->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [379] phi from frame_draw::@1 to frame_draw::@2 [phi:frame_draw::@1->frame_draw::@2]
    // frame_draw::@2
    // clrscr()
    // [380] call clrscr
    jsr clrscr
    // [381] phi from frame_draw::@2 to frame_draw::@3 [phi:frame_draw::@2->frame_draw::@3]
    // frame_draw::@3
    // frame(0, 0, 67, 15)
    // [382] call frame
    // [1111] phi from frame_draw::@3 to frame [phi:frame_draw::@3->frame]
    // [1111] phi frame::y#0 = 0 [phi:frame_draw::@3->frame#0] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.y
    // [1111] phi frame::y1#16 = $f [phi:frame_draw::@3->frame#1] -- vbuz1=vbuc1 
    lda #$f
    sta.z frame.y1
    // [1111] phi frame::x#0 = 0 [phi:frame_draw::@3->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1111] phi frame::x1#16 = $43 [phi:frame_draw::@3->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [383] phi from frame_draw::@3 to frame_draw::@4 [phi:frame_draw::@3->frame_draw::@4]
    // frame_draw::@4
    // frame(0, 0, 67, 2)
    // [384] call frame
    // [1111] phi from frame_draw::@4 to frame [phi:frame_draw::@4->frame]
    // [1111] phi frame::y#0 = 0 [phi:frame_draw::@4->frame#0] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.y
    // [1111] phi frame::y1#16 = 2 [phi:frame_draw::@4->frame#1] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y1
    // [1111] phi frame::x#0 = 0 [phi:frame_draw::@4->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1111] phi frame::x1#16 = $43 [phi:frame_draw::@4->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [385] phi from frame_draw::@4 to frame_draw::@5 [phi:frame_draw::@4->frame_draw::@5]
    // frame_draw::@5
    // frame(0, 2, 67, 13)
    // [386] call frame
    // [1111] phi from frame_draw::@5 to frame [phi:frame_draw::@5->frame]
    // [1111] phi frame::y#0 = 2 [phi:frame_draw::@5->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1111] phi frame::y1#16 = $d [phi:frame_draw::@5->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1111] phi frame::x#0 = 0 [phi:frame_draw::@5->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1111] phi frame::x1#16 = $43 [phi:frame_draw::@5->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [387] phi from frame_draw::@5 to frame_draw::@6 [phi:frame_draw::@5->frame_draw::@6]
    // frame_draw::@6
    // frame(0, 13, 67, 15)
    // [388] call frame
    // [1111] phi from frame_draw::@6 to frame [phi:frame_draw::@6->frame]
    // [1111] phi frame::y#0 = $d [phi:frame_draw::@6->frame#0] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y
    // [1111] phi frame::y1#16 = $f [phi:frame_draw::@6->frame#1] -- vbuz1=vbuc1 
    lda #$f
    sta.z frame.y1
    // [1111] phi frame::x#0 = 0 [phi:frame_draw::@6->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1111] phi frame::x1#16 = $43 [phi:frame_draw::@6->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [389] phi from frame_draw::@6 to frame_draw::@7 [phi:frame_draw::@6->frame_draw::@7]
    // frame_draw::@7
    // frame(0, 2, 8, 13)
    // [390] call frame
    // [1111] phi from frame_draw::@7 to frame [phi:frame_draw::@7->frame]
    // [1111] phi frame::y#0 = 2 [phi:frame_draw::@7->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1111] phi frame::y1#16 = $d [phi:frame_draw::@7->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1111] phi frame::x#0 = 0 [phi:frame_draw::@7->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1111] phi frame::x1#16 = 8 [phi:frame_draw::@7->frame#3] -- vbuz1=vbuc1 
    lda #8
    sta.z frame.x1
    jsr frame
    // [391] phi from frame_draw::@7 to frame_draw::@8 [phi:frame_draw::@7->frame_draw::@8]
    // frame_draw::@8
    // frame(8, 2, 19, 13)
    // [392] call frame
    // [1111] phi from frame_draw::@8 to frame [phi:frame_draw::@8->frame]
    // [1111] phi frame::y#0 = 2 [phi:frame_draw::@8->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1111] phi frame::y1#16 = $d [phi:frame_draw::@8->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1111] phi frame::x#0 = 8 [phi:frame_draw::@8->frame#2] -- vbuz1=vbuc1 
    lda #8
    sta.z frame.x
    // [1111] phi frame::x1#16 = $13 [phi:frame_draw::@8->frame#3] -- vbuz1=vbuc1 
    lda #$13
    sta.z frame.x1
    jsr frame
    // [393] phi from frame_draw::@8 to frame_draw::@9 [phi:frame_draw::@8->frame_draw::@9]
    // frame_draw::@9
    // frame(19, 2, 25, 13)
    // [394] call frame
    // [1111] phi from frame_draw::@9 to frame [phi:frame_draw::@9->frame]
    // [1111] phi frame::y#0 = 2 [phi:frame_draw::@9->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1111] phi frame::y1#16 = $d [phi:frame_draw::@9->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1111] phi frame::x#0 = $13 [phi:frame_draw::@9->frame#2] -- vbuz1=vbuc1 
    lda #$13
    sta.z frame.x
    // [1111] phi frame::x1#16 = $19 [phi:frame_draw::@9->frame#3] -- vbuz1=vbuc1 
    lda #$19
    sta.z frame.x1
    jsr frame
    // [395] phi from frame_draw::@9 to frame_draw::@10 [phi:frame_draw::@9->frame_draw::@10]
    // frame_draw::@10
    // frame(25, 2, 31, 13)
    // [396] call frame
    // [1111] phi from frame_draw::@10 to frame [phi:frame_draw::@10->frame]
    // [1111] phi frame::y#0 = 2 [phi:frame_draw::@10->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1111] phi frame::y1#16 = $d [phi:frame_draw::@10->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1111] phi frame::x#0 = $19 [phi:frame_draw::@10->frame#2] -- vbuz1=vbuc1 
    lda #$19
    sta.z frame.x
    // [1111] phi frame::x1#16 = $1f [phi:frame_draw::@10->frame#3] -- vbuz1=vbuc1 
    lda #$1f
    sta.z frame.x1
    jsr frame
    // [397] phi from frame_draw::@10 to frame_draw::@11 [phi:frame_draw::@10->frame_draw::@11]
    // frame_draw::@11
    // frame(31, 2, 37, 13)
    // [398] call frame
    // [1111] phi from frame_draw::@11 to frame [phi:frame_draw::@11->frame]
    // [1111] phi frame::y#0 = 2 [phi:frame_draw::@11->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1111] phi frame::y1#16 = $d [phi:frame_draw::@11->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1111] phi frame::x#0 = $1f [phi:frame_draw::@11->frame#2] -- vbuz1=vbuc1 
    lda #$1f
    sta.z frame.x
    // [1111] phi frame::x1#16 = $25 [phi:frame_draw::@11->frame#3] -- vbuz1=vbuc1 
    lda #$25
    sta.z frame.x1
    jsr frame
    // [399] phi from frame_draw::@11 to frame_draw::@12 [phi:frame_draw::@11->frame_draw::@12]
    // frame_draw::@12
    // frame(37, 2, 43, 13)
    // [400] call frame
    // [1111] phi from frame_draw::@12 to frame [phi:frame_draw::@12->frame]
    // [1111] phi frame::y#0 = 2 [phi:frame_draw::@12->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1111] phi frame::y1#16 = $d [phi:frame_draw::@12->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1111] phi frame::x#0 = $25 [phi:frame_draw::@12->frame#2] -- vbuz1=vbuc1 
    lda #$25
    sta.z frame.x
    // [1111] phi frame::x1#16 = $2b [phi:frame_draw::@12->frame#3] -- vbuz1=vbuc1 
    lda #$2b
    sta.z frame.x1
    jsr frame
    // [401] phi from frame_draw::@12 to frame_draw::@13 [phi:frame_draw::@12->frame_draw::@13]
    // frame_draw::@13
    // frame(43, 2, 49, 13)
    // [402] call frame
    // [1111] phi from frame_draw::@13 to frame [phi:frame_draw::@13->frame]
    // [1111] phi frame::y#0 = 2 [phi:frame_draw::@13->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1111] phi frame::y1#16 = $d [phi:frame_draw::@13->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1111] phi frame::x#0 = $2b [phi:frame_draw::@13->frame#2] -- vbuz1=vbuc1 
    lda #$2b
    sta.z frame.x
    // [1111] phi frame::x1#16 = $31 [phi:frame_draw::@13->frame#3] -- vbuz1=vbuc1 
    lda #$31
    sta.z frame.x1
    jsr frame
    // [403] phi from frame_draw::@13 to frame_draw::@14 [phi:frame_draw::@13->frame_draw::@14]
    // frame_draw::@14
    // frame(49, 2, 55, 13)
    // [404] call frame
    // [1111] phi from frame_draw::@14 to frame [phi:frame_draw::@14->frame]
    // [1111] phi frame::y#0 = 2 [phi:frame_draw::@14->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1111] phi frame::y1#16 = $d [phi:frame_draw::@14->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1111] phi frame::x#0 = $31 [phi:frame_draw::@14->frame#2] -- vbuz1=vbuc1 
    lda #$31
    sta.z frame.x
    // [1111] phi frame::x1#16 = $37 [phi:frame_draw::@14->frame#3] -- vbuz1=vbuc1 
    lda #$37
    sta.z frame.x1
    jsr frame
    // [405] phi from frame_draw::@14 to frame_draw::@15 [phi:frame_draw::@14->frame_draw::@15]
    // frame_draw::@15
    // frame(55, 2, 61, 13)
    // [406] call frame
    // [1111] phi from frame_draw::@15 to frame [phi:frame_draw::@15->frame]
    // [1111] phi frame::y#0 = 2 [phi:frame_draw::@15->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1111] phi frame::y1#16 = $d [phi:frame_draw::@15->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1111] phi frame::x#0 = $37 [phi:frame_draw::@15->frame#2] -- vbuz1=vbuc1 
    lda #$37
    sta.z frame.x
    // [1111] phi frame::x1#16 = $3d [phi:frame_draw::@15->frame#3] -- vbuz1=vbuc1 
    lda #$3d
    sta.z frame.x1
    jsr frame
    // [407] phi from frame_draw::@15 to frame_draw::@16 [phi:frame_draw::@15->frame_draw::@16]
    // frame_draw::@16
    // frame(61, 2, 67, 13)
    // [408] call frame
    // [1111] phi from frame_draw::@16 to frame [phi:frame_draw::@16->frame]
    // [1111] phi frame::y#0 = 2 [phi:frame_draw::@16->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1111] phi frame::y1#16 = $d [phi:frame_draw::@16->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1111] phi frame::x#0 = $3d [phi:frame_draw::@16->frame#2] -- vbuz1=vbuc1 
    lda #$3d
    sta.z frame.x
    // [1111] phi frame::x1#16 = $43 [phi:frame_draw::@16->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [409] phi from frame_draw::@16 to frame_draw::@17 [phi:frame_draw::@16->frame_draw::@17]
    // frame_draw::@17
    // frame(0, 13, 67, 29)
    // [410] call frame
    // [1111] phi from frame_draw::@17 to frame [phi:frame_draw::@17->frame]
    // [1111] phi frame::y#0 = $d [phi:frame_draw::@17->frame#0] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y
    // [1111] phi frame::y1#16 = $1d [phi:frame_draw::@17->frame#1] -- vbuz1=vbuc1 
    lda #$1d
    sta.z frame.y1
    // [1111] phi frame::x#0 = 0 [phi:frame_draw::@17->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1111] phi frame::x1#16 = $43 [phi:frame_draw::@17->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [411] phi from frame_draw::@17 to frame_draw::@18 [phi:frame_draw::@17->frame_draw::@18]
    // frame_draw::@18
    // frame(0, 29, 67, 49)
    // [412] call frame
    // [1111] phi from frame_draw::@18 to frame [phi:frame_draw::@18->frame]
    // [1111] phi frame::y#0 = $1d [phi:frame_draw::@18->frame#0] -- vbuz1=vbuc1 
    lda #$1d
    sta.z frame.y
    // [1111] phi frame::y1#16 = $31 [phi:frame_draw::@18->frame#1] -- vbuz1=vbuc1 
    lda #$31
    sta.z frame.y1
    // [1111] phi frame::x#0 = 0 [phi:frame_draw::@18->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1111] phi frame::x1#16 = $43 [phi:frame_draw::@18->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [413] phi from frame_draw::@18 to frame_draw::@19 [phi:frame_draw::@18->frame_draw::@19]
    // frame_draw::@19
    // cputsxy(2, 14, "status")
    // [414] call cputsxy
  // cputsxy(2, 3, "led colors");
  // cputsxy(2, 5, "    no chip"); print_chip_led(2, 5, DARK_GREY, BLUE);
  // cputsxy(2, 6, "    update"); print_chip_led(2, 6, CYAN, BLUE);
  // cputsxy(2, 7, "    ok"); print_chip_led(2, 7, WHITE, BLUE);
  // cputsxy(2, 8, "    todo"); print_chip_led(2, 8, PURPLE, BLUE);
  // cputsxy(2, 9, "    error"); print_chip_led(2, 9, RED, BLUE);
  // cputsxy(2, 10, "    no file"); print_chip_led(2, 10, GREY, BLUE);
    // [1245] phi from frame_draw::@19 to cputsxy [phi:frame_draw::@19->cputsxy]
    jsr cputsxy
    // frame_draw::@return
    // }
    // [415] return 
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
    // [417] call gotoxy
    // [334] phi from info_title to gotoxy [phi:info_title->gotoxy]
    // [334] phi gotoxy::y#22 = 1 [phi:info_title->gotoxy#0] -- vbuz1=vbuc1 
    lda #1
    sta.z gotoxy.y
    // [334] phi gotoxy::x#22 = 2 [phi:info_title->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // [418] phi from info_title to info_title::@1 [phi:info_title->info_title::@1]
    // info_title::@1
    // printf("%-60s", info_text)
    // [419] call printf_string
    // [866] phi from info_title::@1 to printf_string [phi:info_title::@1->printf_string]
    // [866] phi printf_string::putc#15 = &cputc [phi:info_title::@1->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [866] phi printf_string::str#15 = main::info_text [phi:info_title::@1->printf_string#1] -- pbuz1=pbuc1 
    lda #<main.info_text
    sta.z printf_string.str
    lda #>main.info_text
    sta.z printf_string.str+1
    // [866] phi printf_string::format_justify_left#15 = 1 [phi:info_title::@1->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [866] phi printf_string::format_min_length#15 = $3c [phi:info_title::@1->printf_string#3] -- vbuz1=vbuc1 
    lda #$3c
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_title::@return
    // }
    // [420] return 
    rts
}
  // progress_clear
/**
 * @brief Clean the progress area for the flashing.
 */
progress_clear: {
    .const h = $1f+$10
    .const w = $40
    .label x = $bd
    .label i = $bf
    .label y = $b9
    // textcolor(WHITE)
    // [422] call textcolor
    // [316] phi from progress_clear to textcolor [phi:progress_clear->textcolor]
    // [316] phi textcolor::color#16 = WHITE [phi:progress_clear->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [423] phi from progress_clear to progress_clear::@5 [phi:progress_clear->progress_clear::@5]
    // progress_clear::@5
    // bgcolor(BLUE)
    // [424] call bgcolor
    // [321] phi from progress_clear::@5 to bgcolor [phi:progress_clear::@5->bgcolor]
    // [321] phi bgcolor::color#14 = BLUE [phi:progress_clear::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [425] phi from progress_clear::@5 to progress_clear::@1 [phi:progress_clear::@5->progress_clear::@1]
    // [425] phi progress_clear::y#2 = $1f [phi:progress_clear::@5->progress_clear::@1#0] -- vbuz1=vbuc1 
    lda #$1f
    sta.z y
    // progress_clear::@1
  __b1:
    // while (y < h)
    // [426] if(progress_clear::y#2<progress_clear::h) goto progress_clear::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y
    cmp #h
    bcc __b4
    // progress_clear::@return
    // }
    // [427] return 
    rts
    // [428] phi from progress_clear::@1 to progress_clear::@2 [phi:progress_clear::@1->progress_clear::@2]
  __b4:
    // [428] phi progress_clear::x#2 = 2 [phi:progress_clear::@1->progress_clear::@2#0] -- vbuz1=vbuc1 
    lda #2
    sta.z x
    // [428] phi progress_clear::i#2 = 0 [phi:progress_clear::@1->progress_clear::@2#1] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // progress_clear::@2
  __b2:
    // for(unsigned char i = 0; i < w; i++)
    // [429] if(progress_clear::i#2<progress_clear::w) goto progress_clear::@3 -- vbuz1_lt_vbuc1_then_la1 
    lda.z i
    cmp #w
    bcc __b3
    // progress_clear::@4
    // y++;
    // [430] progress_clear::y#1 = ++ progress_clear::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [425] phi from progress_clear::@4 to progress_clear::@1 [phi:progress_clear::@4->progress_clear::@1]
    // [425] phi progress_clear::y#2 = progress_clear::y#1 [phi:progress_clear::@4->progress_clear::@1#0] -- register_copy 
    jmp __b1
    // progress_clear::@3
  __b3:
    // cputcxy(x, y, ' ')
    // [431] cputcxy::x#9 = progress_clear::x#2 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [432] cputcxy::y#9 = progress_clear::y#2 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [433] call cputcxy
    // [1250] phi from progress_clear::@3 to cputcxy [phi:progress_clear::@3->cputcxy]
    // [1250] phi cputcxy::c#11 = ' ' [phi:progress_clear::@3->cputcxy#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z cputcxy.c
    // [1250] phi cputcxy::y#11 = cputcxy::y#9 [phi:progress_clear::@3->cputcxy#1] -- register_copy 
    // [1250] phi cputcxy::x#11 = cputcxy::x#9 [phi:progress_clear::@3->cputcxy#2] -- register_copy 
    jsr cputcxy
    // progress_clear::@6
    // x++;
    // [434] progress_clear::x#1 = ++ progress_clear::x#2 -- vbuz1=_inc_vbuz1 
    inc.z x
    // for(unsigned char i = 0; i < w; i++)
    // [435] progress_clear::i#1 = ++ progress_clear::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [428] phi from progress_clear::@6 to progress_clear::@2 [phi:progress_clear::@6->progress_clear::@2]
    // [428] phi progress_clear::x#2 = progress_clear::x#1 [phi:progress_clear::@6->progress_clear::@2#0] -- register_copy 
    // [428] phi progress_clear::i#2 = progress_clear::i#1 [phi:progress_clear::@6->progress_clear::@2#1] -- register_copy 
    jmp __b2
}
  // info_clear_all
/**
 * @brief Clean the information area.
 * 
 */
info_clear_all: {
    .label l = $eb
    // textcolor(WHITE)
    // [437] call textcolor
    // [316] phi from info_clear_all to textcolor [phi:info_clear_all->textcolor]
    // [316] phi textcolor::color#16 = WHITE [phi:info_clear_all->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [438] phi from info_clear_all to info_clear_all::@3 [phi:info_clear_all->info_clear_all::@3]
    // info_clear_all::@3
    // bgcolor(BLUE)
    // [439] call bgcolor
    // [321] phi from info_clear_all::@3 to bgcolor [phi:info_clear_all::@3->bgcolor]
    // [321] phi bgcolor::color#14 = BLUE [phi:info_clear_all::@3->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [440] phi from info_clear_all::@3 to info_clear_all::@1 [phi:info_clear_all::@3->info_clear_all::@1]
    // [440] phi info_clear_all::l#2 = 0 [phi:info_clear_all::@3->info_clear_all::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z l
    // info_clear_all::@1
  __b1:
    // while (l < INFO_H)
    // [441] if(info_clear_all::l#2<$a) goto info_clear_all::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z l
    cmp #$a
    bcc __b2
    // info_clear_all::@return
    // }
    // [442] return 
    rts
    // info_clear_all::@2
  __b2:
    // info_clear(l)
    // [443] info_clear::l#0 = info_clear_all::l#2 -- vbuz1=vbuz2 
    lda.z l
    sta.z info_clear.l
    // [444] call info_clear
    // [1258] phi from info_clear_all::@2 to info_clear [phi:info_clear_all::@2->info_clear]
    // [1258] phi info_clear::l#4 = info_clear::l#0 [phi:info_clear_all::@2->info_clear#0] -- register_copy 
    jsr info_clear
    // info_clear_all::@4
    // l++;
    // [445] info_clear_all::l#1 = ++ info_clear_all::l#2 -- vbuz1=_inc_vbuz1 
    inc.z l
    // [440] phi from info_clear_all::@4 to info_clear_all::@1 [phi:info_clear_all::@4->info_clear_all::@1]
    // [440] phi info_clear_all::l#2 = info_clear_all::l#1 [phi:info_clear_all::@4->info_clear_all::@1#0] -- register_copy 
    jmp __b1
}
  // info_line
// void info_line(__zp($6e) char *info_text)
info_line: {
    .label info_text = $6e
    .label x = $bc
    .label y = $bb
    // unsigned char x = wherex()
    // [447] call wherex
    jsr wherex
    // [448] wherex::return#2 = wherex::return#0
    // info_line::@1
    // [449] info_line::x#0 = wherex::return#2
    // unsigned char y = wherey()
    // [450] call wherey
    jsr wherey
    // [451] wherey::return#2 = wherey::return#0
    // info_line::@2
    // [452] info_line::y#0 = wherey::return#2
    // gotoxy(2, 14)
    // [453] call gotoxy
    // [334] phi from info_line::@2 to gotoxy [phi:info_line::@2->gotoxy]
    // [334] phi gotoxy::y#22 = $e [phi:info_line::@2->gotoxy#0] -- vbuz1=vbuc1 
    lda #$e
    sta.z gotoxy.y
    // [334] phi gotoxy::x#22 = 2 [phi:info_line::@2->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // info_line::@3
    // printf("%-60s", info_text)
    // [454] printf_string::str#0 = info_line::info_text#16
    // [455] call printf_string
    // [866] phi from info_line::@3 to printf_string [phi:info_line::@3->printf_string]
    // [866] phi printf_string::putc#15 = &cputc [phi:info_line::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [866] phi printf_string::str#15 = printf_string::str#0 [phi:info_line::@3->printf_string#1] -- register_copy 
    // [866] phi printf_string::format_justify_left#15 = 1 [phi:info_line::@3->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [866] phi printf_string::format_min_length#15 = $3c [phi:info_line::@3->printf_string#3] -- vbuz1=vbuc1 
    lda #$3c
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_line::@4
    // gotoxy(x, y)
    // [456] gotoxy::x#10 = info_line::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [457] gotoxy::y#10 = info_line::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [458] call gotoxy
    // [334] phi from info_line::@4 to gotoxy [phi:info_line::@4->gotoxy]
    // [334] phi gotoxy::y#22 = gotoxy::y#10 [phi:info_line::@4->gotoxy#0] -- register_copy 
    // [334] phi gotoxy::x#22 = gotoxy::x#10 [phi:info_line::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // info_line::@return
    // }
    // [459] return 
    rts
}
  // smc_detect
smc_detect: {
    // This conditional compilation ensures that only the detection interpretation happens if it is switched on.
    .label return = 1
    // smc_detect::@return
    // [461] return 
    rts
}
  // chip_smc
chip_smc: {
    // print_smc_led(GREY)
    // [463] call print_smc_led
    // [1274] phi from chip_smc to print_smc_led [phi:chip_smc->print_smc_led]
    // [1274] phi print_smc_led::c#2 = GREY [phi:chip_smc->print_smc_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z print_smc_led.c
    jsr print_smc_led
    // [464] phi from chip_smc to chip_smc::@1 [phi:chip_smc->chip_smc::@1]
    // chip_smc::@1
    // print_chip(CHIP_SMC_X, CHIP_SMC_Y+1, CHIP_SMC_W, "smc     ")
    // [465] call print_chip
    // [1278] phi from chip_smc::@1 to print_chip [phi:chip_smc::@1->print_chip]
    // [1278] phi print_chip::text#11 = chip_smc::text [phi:chip_smc::@1->print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z print_chip.text_2
    lda #>text
    sta.z print_chip.text_2+1
    // [1278] phi print_chip::w#10 = 5 [phi:chip_smc::@1->print_chip#1] -- vbuz1=vbuc1 
    lda #5
    sta.z print_chip.w
    // [1278] phi print_chip::x#10 = 1 [phi:chip_smc::@1->print_chip#2] -- vbuz1=vbuc1 
    lda #1
    sta.z print_chip.x
    jsr print_chip
    // chip_smc::@return
    // }
    // [466] return 
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
    // [467] __snprintf_capacity = $ffff -- vwum1=vwuc1 
    lda #<$ffff
    sta __snprintf_capacity
    lda #>$ffff
    sta __snprintf_capacity+1
    // __snprintf_size = 0
    // [468] __snprintf_size = 0 -- vwum1=vbuc1 
    lda #<0
    sta __snprintf_size
    sta __snprintf_size+1
    // __snprintf_buffer = s
    // [469] __snprintf_buffer = info_text -- pbuz1=pbuc1 
    lda #<info_text
    sta.z __snprintf_buffer
    lda #>info_text
    sta.z __snprintf_buffer+1
    // snprintf_init::@return
    // }
    // [470] return 
    rts
}
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($b0) void (*putc)(char), __zp($6e) const char *s)
printf_str: {
    .label c = $78
    .label s = $6e
    .label putc = $b0
    // [472] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [472] phi printf_str::s#51 = printf_str::s#52 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [473] printf_str::c#1 = *printf_str::s#51 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta.z c
    // [474] printf_str::s#0 = ++ printf_str::s#51 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [475] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // printf_str::@return
    // }
    // [476] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [477] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [478] callexecute *printf_str::putc#52  -- call__deref_pprz1 
    jsr icall9
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
    // Outside Flow
  icall9:
    jmp (putc)
}
  // printf_uint
// Print an unsigned int using a specific format
// void printf_uint(void (*putc)(char), __zp($29) unsigned int uvalue, __zp($bf) char format_min_length, char format_justify_left, char format_sign_always, __zp($bd) char format_zero_padding, char format_upper_case, __zp($b9) char format_radix)
printf_uint: {
    .label uvalue = $29
    .label format_radix = $b9
    .label format_min_length = $bf
    .label format_zero_padding = $bd
    // printf_uint::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [481] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [482] utoa::value#1 = printf_uint::uvalue#11
    // [483] utoa::radix#0 = printf_uint::format_radix#11
    // [484] call utoa
    // Format number into buffer
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [485] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [486] printf_number_buffer::format_min_length#1 = printf_uint::format_min_length#11
    // [487] printf_number_buffer::format_zero_padding#1 = printf_uint::format_zero_padding#11
    // [488] call printf_number_buffer
  // Print using format
    // [1352] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    // [1352] phi printf_number_buffer::putc#10 = &snputc [phi:printf_uint::@2->printf_number_buffer#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_number_buffer.putc
    lda #>snputc
    sta.z printf_number_buffer.putc+1
    // [1352] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_uint::@2->printf_number_buffer#1] -- register_copy 
    // [1352] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#1 [phi:printf_uint::@2->printf_number_buffer#2] -- register_copy 
    // [1352] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#1 [phi:printf_uint::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [489] return 
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
// void info_smc(__mem() char info_status, __zp($d0) char *info_text)
info_smc: {
    .label info_text = $d0
    // print_smc_led(status_color[info_status])
    // [491] print_smc_led::c#1 = status_color[info_smc::info_status#10] -- vbuz1=pbuc1_derefidx_vbum2 
    ldy info_status
    lda status_color,y
    sta.z print_smc_led.c
    // [492] call print_smc_led
    // [1274] phi from info_smc to print_smc_led [phi:info_smc->print_smc_led]
    // [1274] phi print_smc_led::c#2 = print_smc_led::c#1 [phi:info_smc->print_smc_led#0] -- register_copy 
    jsr print_smc_led
    // [493] phi from info_smc to info_smc::@1 [phi:info_smc->info_smc::@1]
    // info_smc::@1
    // info_clear(0)
    // [494] call info_clear
    // [1258] phi from info_smc::@1 to info_clear [phi:info_smc::@1->info_clear]
    // [1258] phi info_clear::l#4 = 0 [phi:info_smc::@1->info_clear#0] -- vbuz1=vbuc1 
    lda #0
    sta.z info_clear.l
    jsr info_clear
    // [495] phi from info_smc::@1 to info_smc::@2 [phi:info_smc::@1->info_smc::@2]
    // info_smc::@2
    // printf("SMC  - %-8s - %s", status_text[info_status], info_text)
    // [496] call printf_str
    // [471] phi from info_smc::@2 to printf_str [phi:info_smc::@2->printf_str]
    // [471] phi printf_str::putc#52 = &cputc [phi:info_smc::@2->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = info_smc::s [phi:info_smc::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // info_smc::@3
    // printf("SMC  - %-8s - %s", status_text[info_status], info_text)
    // [497] info_smc::$3 = info_smc::info_status#10 << 1 -- vbum1=vbum1_rol_1 
    asl info_smc__3
    // [498] printf_string::str#2 = status_text[info_smc::$3] -- pbuz1=qbuc1_derefidx_vbum2 
    ldy info_smc__3
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [499] call printf_string
    // [866] phi from info_smc::@3 to printf_string [phi:info_smc::@3->printf_string]
    // [866] phi printf_string::putc#15 = &cputc [phi:info_smc::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [866] phi printf_string::str#15 = printf_string::str#2 [phi:info_smc::@3->printf_string#1] -- register_copy 
    // [866] phi printf_string::format_justify_left#15 = 1 [phi:info_smc::@3->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [866] phi printf_string::format_min_length#15 = 8 [phi:info_smc::@3->printf_string#3] -- vbuz1=vbuc1 
    lda #8
    sta.z printf_string.format_min_length
    jsr printf_string
    // [500] phi from info_smc::@3 to info_smc::@4 [phi:info_smc::@3->info_smc::@4]
    // info_smc::@4
    // printf("SMC  - %-8s - %s", status_text[info_status], info_text)
    // [501] call printf_str
    // [471] phi from info_smc::@4 to printf_str [phi:info_smc::@4->printf_str]
    // [471] phi printf_str::putc#52 = &cputc [phi:info_smc::@4->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = s1 [phi:info_smc::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_smc::@5
    // printf("SMC  - %-8s - %s", status_text[info_status], info_text)
    // [502] printf_string::str#3 = info_smc::info_text#10 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [503] call printf_string
    // [866] phi from info_smc::@5 to printf_string [phi:info_smc::@5->printf_string]
    // [866] phi printf_string::putc#15 = &cputc [phi:info_smc::@5->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [866] phi printf_string::str#15 = printf_string::str#3 [phi:info_smc::@5->printf_string#1] -- register_copy 
    // [866] phi printf_string::format_justify_left#15 = 0 [phi:info_smc::@5->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [866] phi printf_string::format_min_length#15 = 0 [phi:info_smc::@5->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_smc::@return
    // }
    // [504] return 
    rts
  .segment Data
    s: .text "SMC  - "
    .byte 0
    .label info_smc__3 = wait_key.bank_get_brom1_return
    .label info_status = wait_key.bank_get_brom1_return
}
.segment Code
  // chip_vera
chip_vera: {
    // print_vera_led(GREY)
    // [506] call print_vera_led
    // [1383] phi from chip_vera to print_vera_led [phi:chip_vera->print_vera_led]
    // [1383] phi print_vera_led::c#2 = GREY [phi:chip_vera->print_vera_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z print_vera_led.c
    jsr print_vera_led
    // [507] phi from chip_vera to chip_vera::@1 [phi:chip_vera->chip_vera::@1]
    // chip_vera::@1
    // print_chip(CHIP_VERA_X, CHIP_VERA_Y+1, CHIP_VERA_W, "vera     ")
    // [508] call print_chip
    // [1278] phi from chip_vera::@1 to print_chip [phi:chip_vera::@1->print_chip]
    // [1278] phi print_chip::text#11 = chip_vera::text [phi:chip_vera::@1->print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z print_chip.text_2
    lda #>text
    sta.z print_chip.text_2+1
    // [1278] phi print_chip::w#10 = 8 [phi:chip_vera::@1->print_chip#1] -- vbuz1=vbuc1 
    lda #8
    sta.z print_chip.w
    // [1278] phi print_chip::x#10 = 9 [phi:chip_vera::@1->print_chip#2] -- vbuz1=vbuc1 
    lda #9
    sta.z print_chip.x
    jsr print_chip
    // chip_vera::@return
    // }
    // [509] return 
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
    // [510] print_vera_led::c#1 = *status_color -- vbuz1=_deref_pbuc1 
    lda status_color
    sta.z print_vera_led.c
    // [511] call print_vera_led
    // [1383] phi from info_vera to print_vera_led [phi:info_vera->print_vera_led]
    // [1383] phi print_vera_led::c#2 = print_vera_led::c#1 [phi:info_vera->print_vera_led#0] -- register_copy 
    jsr print_vera_led
    // [512] phi from info_vera to info_vera::@1 [phi:info_vera->info_vera::@1]
    // info_vera::@1
    // info_clear(1)
    // [513] call info_clear
    // [1258] phi from info_vera::@1 to info_clear [phi:info_vera::@1->info_clear]
    // [1258] phi info_clear::l#4 = 1 [phi:info_vera::@1->info_clear#0] -- vbuz1=vbuc1 
    lda #1
    sta.z info_clear.l
    jsr info_clear
    // [514] phi from info_vera::@1 to info_vera::@2 [phi:info_vera::@1->info_vera::@2]
    // info_vera::@2
    // printf("VERA - %-8s - %s", status_text[info_status], info_text)
    // [515] call printf_str
    // [471] phi from info_vera::@2 to printf_str [phi:info_vera::@2->printf_str]
    // [471] phi printf_str::putc#52 = &cputc [phi:info_vera::@2->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = info_vera::s [phi:info_vera::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // info_vera::@3
    // printf("VERA - %-8s - %s", status_text[info_status], info_text)
    // [516] printf_string::str#4 = *status_text -- pbuz1=_deref_qbuc1 
    lda status_text
    sta.z printf_string.str
    lda status_text+1
    sta.z printf_string.str+1
    // [517] call printf_string
    // [866] phi from info_vera::@3 to printf_string [phi:info_vera::@3->printf_string]
    // [866] phi printf_string::putc#15 = &cputc [phi:info_vera::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [866] phi printf_string::str#15 = printf_string::str#4 [phi:info_vera::@3->printf_string#1] -- register_copy 
    // [866] phi printf_string::format_justify_left#15 = 1 [phi:info_vera::@3->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [866] phi printf_string::format_min_length#15 = 8 [phi:info_vera::@3->printf_string#3] -- vbuz1=vbuc1 
    lda #8
    sta.z printf_string.format_min_length
    jsr printf_string
    // [518] phi from info_vera::@3 to info_vera::@4 [phi:info_vera::@3->info_vera::@4]
    // info_vera::@4
    // printf("VERA - %-8s - %s", status_text[info_status], info_text)
    // [519] call printf_str
    // [471] phi from info_vera::@4 to printf_str [phi:info_vera::@4->printf_str]
    // [471] phi printf_str::putc#52 = &cputc [phi:info_vera::@4->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = s1 [phi:info_vera::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // [520] phi from info_vera::@4 to info_vera::@5 [phi:info_vera::@4->info_vera::@5]
    // info_vera::@5
    // printf("VERA - %-8s - %s", status_text[info_status], info_text)
    // [521] call printf_string
    // [866] phi from info_vera::@5 to printf_string [phi:info_vera::@5->printf_string]
    // [866] phi printf_string::putc#15 = &cputc [phi:info_vera::@5->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [866] phi printf_string::str#15 = main::info_text4 [phi:info_vera::@5->printf_string#1] -- pbuz1=pbuc1 
    lda #<main.info_text4
    sta.z printf_string.str
    lda #>main.info_text4
    sta.z printf_string.str+1
    // [866] phi printf_string::format_justify_left#15 = 0 [phi:info_vera::@5->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [866] phi printf_string::format_min_length#15 = 0 [phi:info_vera::@5->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_vera::@return
    // }
    // [522] return 
    rts
  .segment Data
    s: .text "VERA - "
    .byte 0
}
.segment Code
  // rom_detect
rom_detect: {
    .const bank_set_brom1_bank = 4
    .label rom_detect__14 = $bb
    .label rom_detect__20 = $e8
    .label rom_detect__22 = $bf
    .label rom_detect__23 = $bd
    .label rom_detect__25 = $78
    .label rom_detect__29 = $bc
    .label rom_chip = $7b
    .label rom_detect_address = $25
    .label rom_detect__38 = $bb
    // [524] phi from rom_detect to rom_detect::@1 [phi:rom_detect->rom_detect::@1]
    // [524] phi rom_detect::rom_chip#10 = 0 [phi:rom_detect->rom_detect::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip
    // [524] phi rom_detect::rom_detect_address#10 = 0 [phi:rom_detect->rom_detect::@1#1] -- vduz1=vduc1 
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
    // [525] if(rom_detect::rom_detect_address#10<8*$80000) goto rom_detect::@2 -- vduz1_lt_vduc1_then_la1 
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
    // [526] return 
    rts
    // rom_detect::@2
  __b2:
    // rom_manufacturer_ids[rom_chip] = 0
    // [527] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    ldy.z rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = 0
    // [528] rom_device_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta rom_device_ids,y
    // if (rom_detect_address == 0x0)
    // [529] if(rom_detect::rom_detect_address#10!=0) goto rom_detect::@3 -- vduz1_neq_0_then_la1 
    lda.z rom_detect_address
    ora.z rom_detect_address+1
    ora.z rom_detect_address+2
    ora.z rom_detect_address+3
    bne __b3
    // rom_detect::@14
    // rom_manufacturer_ids[rom_chip] = 0x9f
    // [530] rom_manufacturer_ids[rom_detect::rom_chip#10] = $9f -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$9f
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF040
    // [531] rom_device_ids[rom_detect::rom_chip#10] = $b7 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$b7
    sta rom_device_ids,y
    // rom_detect::@3
  __b3:
    // if (rom_detect_address == 0x80000)
    // [532] if(rom_detect::rom_detect_address#10!=$80000) goto rom_detect::@4 -- vduz1_neq_vduc1_then_la1 
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
    // [533] rom_manufacturer_ids[rom_detect::rom_chip#10] = $9f -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$9f
    ldy.z rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF040
    // [534] rom_device_ids[rom_detect::rom_chip#10] = $b7 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$b7
    sta rom_device_ids,y
    // rom_detect::@4
  __b4:
    // if (rom_detect_address == 0x100000)
    // [535] if(rom_detect::rom_detect_address#10!=$100000) goto rom_detect::@5 -- vduz1_neq_vduc1_then_la1 
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
    // [536] rom_manufacturer_ids[rom_detect::rom_chip#10] = $9f -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$9f
    ldy.z rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF020A
    // [537] rom_device_ids[rom_detect::rom_chip#10] = $b6 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$b6
    sta rom_device_ids,y
    // rom_detect::@5
  __b5:
    // if (rom_detect_address == 0x180000)
    // [538] if(rom_detect::rom_detect_address#10!=$180000) goto rom_detect::@6 -- vduz1_neq_vduc1_then_la1 
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
    // [539] rom_manufacturer_ids[rom_detect::rom_chip#10] = $9f -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$9f
    ldy.z rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF010A
    // [540] rom_device_ids[rom_detect::rom_chip#10] = $b5 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$b5
    sta rom_device_ids,y
    // rom_detect::@6
  __b6:
    // if (rom_detect_address == 0x200000)
    // [541] if(rom_detect::rom_detect_address#10!=$200000) goto rom_detect::@7 -- vduz1_neq_vduc1_then_la1 
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
    // [542] rom_manufacturer_ids[rom_detect::rom_chip#10] = $9f -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$9f
    ldy.z rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF040
    // [543] rom_device_ids[rom_detect::rom_chip#10] = $b7 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$b7
    sta rom_device_ids,y
    // rom_detect::@7
  __b7:
    // if (rom_detect_address == 0x280000)
    // [544] if(rom_detect::rom_detect_address#10!=$280000) goto rom_detect::bank_set_brom1 -- vduz1_neq_vduc1_then_la1 
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
    // [545] rom_manufacturer_ids[rom_detect::rom_chip#10] = $9f -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$9f
    ldy.z rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF040
    // [546] rom_device_ids[rom_detect::rom_chip#10] = $b7 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$b7
    sta rom_device_ids,y
    // rom_detect::bank_set_brom1
  bank_set_brom1:
    // BROM = bank
    // [547] BROM = rom_detect::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // rom_detect::@22
    // case SST39SF010A:
    //             rom_device_names[rom_chip] = "f010a";
    //             rom_size_strings[rom_chip] = "128";
    //             rom_sizes[rom_chip] = 128 * 1024;
    //             break;
    // [548] if(rom_device_ids[rom_detect::rom_chip#10]==$b5) goto rom_detect::@8 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
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
    // [549] if(rom_device_ids[rom_detect::rom_chip#10]==$b6) goto rom_detect::@9 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
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
    // [550] if(rom_device_ids[rom_detect::rom_chip#10]==$b7) goto rom_detect::@10 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b7
    bne !__b10+
    jmp __b10
  !__b10:
    // rom_detect::@11
    // rom_manufacturer_ids[rom_chip] = 0
    // [551] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    sta rom_manufacturer_ids,y
    // rom_device_names[rom_chip] = "----"
    // [552] rom_detect::$28 = rom_detect::rom_chip#10 << 1 -- vbum1=vbuz2_rol_1 
    tya
    asl
    sta rom_detect__28
    // [553] rom_device_names[rom_detect::$28] = rom_detect::$36 -- qbuc1_derefidx_vbum1=pbuc2 
    tay
    lda #<rom_detect__36
    sta rom_device_names,y
    lda #>rom_detect__36
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "000"
    // [554] rom_size_strings[rom_detect::$28] = rom_detect::$37 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__37
    sta rom_size_strings,y
    lda #>rom_detect__37
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 0
    // [555] rom_detect::$29 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta.z rom_detect__29
    // [556] rom_sizes[rom_detect::$29] = 0 -- pduc1_derefidx_vbuz1=vbuc2 
    tay
    lda #0
    sta rom_sizes,y
    sta rom_sizes+1,y
    sta rom_sizes+2,y
    sta rom_sizes+3,y
    // rom_device_ids[rom_chip] = UNKNOWN
    // [557] rom_device_ids[rom_detect::rom_chip#10] = $55 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$55
    ldy.z rom_chip
    sta rom_device_ids,y
    // rom_detect::@12
  __b12:
    // rom_chip*3
    // [558] rom_detect::$38 = rom_detect::rom_chip#10 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta.z rom_detect__38
    // [559] rom_detect::$14 = rom_detect::$38 + rom_detect::rom_chip#10 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z rom_detect__14
    clc
    adc.z rom_chip
    sta.z rom_detect__14
    // gotoxy(rom_chip*3+40, 1)
    // [560] gotoxy::x#17 = rom_detect::$14 + $28 -- vbuz1=vbuz2_plus_vbuc1 
    lda #$28
    clc
    adc.z rom_detect__14
    sta.z gotoxy.x
    // [561] call gotoxy
    // [334] phi from rom_detect::@12 to gotoxy [phi:rom_detect::@12->gotoxy]
    // [334] phi gotoxy::y#22 = 1 [phi:rom_detect::@12->gotoxy#0] -- vbuz1=vbuc1 
    lda #1
    sta.z gotoxy.y
    // [334] phi gotoxy::x#22 = gotoxy::x#17 [phi:rom_detect::@12->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_detect::@23
    // printf("%02x", rom_device_ids[rom_chip])
    // [562] printf_uchar::uvalue#4 = rom_device_ids[rom_detect::rom_chip#10] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z rom_chip
    lda rom_device_ids,y
    sta.z printf_uchar.uvalue
    // [563] call printf_uchar
    // [1387] phi from rom_detect::@23 to printf_uchar [phi:rom_detect::@23->printf_uchar]
    // [1387] phi printf_uchar::format_zero_padding#10 = 1 [phi:rom_detect::@23->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1387] phi printf_uchar::format_min_length#10 = 2 [phi:rom_detect::@23->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [1387] phi printf_uchar::putc#10 = &cputc [phi:rom_detect::@23->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1387] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:rom_detect::@23->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [1387] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#4 [phi:rom_detect::@23->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // rom_detect::@24
    // rom_chip++;
    // [564] rom_detect::rom_chip#1 = ++ rom_detect::rom_chip#10 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip
    // rom_detect::@13
    // rom_detect_address += 0x80000
    // [565] rom_detect::rom_detect_address#1 = rom_detect::rom_detect_address#10 + $80000 -- vduz1=vduz1_plus_vduc1 
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
    // [524] phi from rom_detect::@13 to rom_detect::@1 [phi:rom_detect::@13->rom_detect::@1]
    // [524] phi rom_detect::rom_chip#10 = rom_detect::rom_chip#1 [phi:rom_detect::@13->rom_detect::@1#0] -- register_copy 
    // [524] phi rom_detect::rom_detect_address#10 = rom_detect::rom_detect_address#1 [phi:rom_detect::@13->rom_detect::@1#1] -- register_copy 
    jmp __b1
    // rom_detect::@10
  __b10:
    // rom_device_names[rom_chip] = "f040"
    // [566] rom_detect::$25 = rom_detect::rom_chip#10 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta.z rom_detect__25
    // [567] rom_device_names[rom_detect::$25] = rom_detect::$34 -- qbuc1_derefidx_vbuz1=pbuc2 
    tay
    lda #<rom_detect__34
    sta rom_device_names,y
    lda #>rom_detect__34
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "512"
    // [568] rom_size_strings[rom_detect::$25] = rom_detect::$35 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__35
    sta rom_size_strings,y
    lda #>rom_detect__35
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 512 * 1024
    // [569] rom_detect::$26 = rom_detect::rom_chip#10 << 2 -- vbum1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta rom_detect__26
    // [570] rom_sizes[rom_detect::$26] = (unsigned long)$200*$400 -- pduc1_derefidx_vbum1=vduc2 
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
    // [571] rom_detect::$22 = rom_detect::rom_chip#10 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta.z rom_detect__22
    // [572] rom_device_names[rom_detect::$22] = rom_detect::$32 -- qbuc1_derefidx_vbuz1=pbuc2 
    tay
    lda #<rom_detect__32
    sta rom_device_names,y
    lda #>rom_detect__32
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "256"
    // [573] rom_size_strings[rom_detect::$22] = rom_detect::$33 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__33
    sta rom_size_strings,y
    lda #>rom_detect__33
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 256 * 1024
    // [574] rom_detect::$23 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta.z rom_detect__23
    // [575] rom_sizes[rom_detect::$23] = (unsigned long)$100*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
    // [576] rom_detect::$19 = rom_detect::rom_chip#10 << 1 -- vbum1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta rom_detect__19
    // [577] rom_device_names[rom_detect::$19] = rom_detect::$30 -- qbuc1_derefidx_vbum1=pbuc2 
    tay
    lda #<rom_detect__30
    sta rom_device_names,y
    lda #>rom_detect__30
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "128"
    // [578] rom_size_strings[rom_detect::$19] = rom_detect::$31 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__31
    sta rom_size_strings,y
    lda #>rom_detect__31
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 128 * 1024
    // [579] rom_detect::$20 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta.z rom_detect__20
    // [580] rom_sizes[rom_detect::$20] = (unsigned long)$80*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
    .label rom_detect__19 = wait_key.bank_get_brom1_return
    .label rom_detect__26 = chip_rom.chip_rom__9
    rom_detect__28: .byte 0
}
.segment Code
  // chip_rom
chip_rom: {
    .label chip_rom__3 = $bf
    .label chip_rom__5 = $79
    .label r = $78
    // [582] phi from chip_rom to chip_rom::@1 [phi:chip_rom->chip_rom::@1]
    // [582] phi chip_rom::r#2 = 0 [phi:chip_rom->chip_rom::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z r
    // chip_rom::@1
  __b1:
    // for (unsigned char r = 0; r < 8; r++)
    // [583] if(chip_rom::r#2<8) goto chip_rom::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z r
    cmp #8
    bcc __b2
    // chip_rom::@return
    // }
    // [584] return 
    rts
    // [585] phi from chip_rom::@1 to chip_rom::@2 [phi:chip_rom::@1->chip_rom::@2]
    // chip_rom::@2
  __b2:
    // strcpy(rom, "rom0 ")
    // [586] call strcpy
    // [858] phi from chip_rom::@2 to strcpy [phi:chip_rom::@2->strcpy]
    // [858] phi strcpy::dst#0 = chip_rom::rom [phi:chip_rom::@2->strcpy#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z strcpy.dst
    lda #>rom
    sta.z strcpy.dst+1
    // [858] phi strcpy::src#0 = chip_rom::source [phi:chip_rom::@2->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // chip_rom::@3
    // strcat(rom, rom_size_strings[r])
    // [587] chip_rom::$9 = chip_rom::r#2 << 1 -- vbum1=vbuz2_rol_1 
    lda.z r
    asl
    sta chip_rom__9
    // [588] strcat::source#0 = rom_size_strings[chip_rom::$9] -- pbuz1=qbuc1_derefidx_vbum2 
    tay
    lda rom_size_strings,y
    sta.z strcat.source
    lda rom_size_strings+1,y
    sta.z strcat.source+1
    // [589] call strcat
    // [1398] phi from chip_rom::@3 to strcat [phi:chip_rom::@3->strcat]
    jsr strcat
    // chip_rom::@4
    // r+'0'
    // [590] chip_rom::$3 = chip_rom::r#2 + '0' -- vbuz1=vbuz2_plus_vbuc1 
    lda #'0'
    clc
    adc.z r
    sta.z chip_rom__3
    // *(rom+3) = r+'0'
    // [591] *(chip_rom::rom+3) = chip_rom::$3 -- _deref_pbuc1=vbuz1 
    sta rom+3
    // print_rom_led(r, GREY)
    // [592] print_rom_led::chip#0 = chip_rom::r#2 -- vbuz1=vbuz2 
    lda.z r
    sta.z print_rom_led.chip
    // [593] call print_rom_led
    // [1410] phi from chip_rom::@4 to print_rom_led [phi:chip_rom::@4->print_rom_led]
    // [1410] phi print_rom_led::c#2 = GREY [phi:chip_rom::@4->print_rom_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z print_rom_led.c
    // [1410] phi print_rom_led::chip#2 = print_rom_led::chip#0 [phi:chip_rom::@4->print_rom_led#1] -- register_copy 
    jsr print_rom_led
    // chip_rom::@5
    // r*6
    // [594] chip_rom::$10 = chip_rom::$9 + chip_rom::r#2 -- vbum1=vbum1_plus_vbuz2 
    lda chip_rom__10
    clc
    adc.z r
    sta chip_rom__10
    // [595] chip_rom::$5 = chip_rom::$10 << 1 -- vbuz1=vbum2_rol_1 
    asl
    sta.z chip_rom__5
    // print_chip(CHIP_ROM_X+r*6, CHIP_ROM_Y+1, CHIP_ROM_W, rom)
    // [596] print_chip::x#2 = $14 + chip_rom::$5 -- vbuz1=vbuc1_plus_vbuz1 
    lda #$14
    clc
    adc.z print_chip.x
    sta.z print_chip.x
    // [597] call print_chip
    // [1278] phi from chip_rom::@5 to print_chip [phi:chip_rom::@5->print_chip]
    // [1278] phi print_chip::text#11 = chip_rom::rom [phi:chip_rom::@5->print_chip#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z print_chip.text_2
    lda #>rom
    sta.z print_chip.text_2+1
    // [1278] phi print_chip::w#10 = 3 [phi:chip_rom::@5->print_chip#1] -- vbuz1=vbuc1 
    lda #3
    sta.z print_chip.w
    // [1278] phi print_chip::x#10 = print_chip::x#2 [phi:chip_rom::@5->print_chip#2] -- register_copy 
    jsr print_chip
    // chip_rom::@6
    // for (unsigned char r = 0; r < 8; r++)
    // [598] chip_rom::r#1 = ++ chip_rom::r#2 -- vbuz1=_inc_vbuz1 
    inc.z r
    // [582] phi from chip_rom::@6 to chip_rom::@1 [phi:chip_rom::@6->chip_rom::@1]
    // [582] phi chip_rom::r#2 = chip_rom::r#1 [phi:chip_rom::@6->chip_rom::@1#0] -- register_copy 
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
// __zp($29) unsigned int smc_read(char x, __zp($e8) char y, char w, char b, unsigned int progress_row_size, __zp($b0) char *flash_ram_address)
smc_read: {
    .const x = 2
    .const b = 8
    .const progress_row_size = $200
    .label fp = $51
    .label return = $29
    .label smc_file_read = $6c
    .label flash_ram_address = $b0
    .label smc_file_size = $29
    /// Holds the amount of bytes actually read in the memory to be flashed.
    .label progress_row_bytes = $53
    .label y = $e8
    // info_line("Reading SMC.BIN flash file into CX16 RAM ...")
    // [600] call info_line
    // [446] phi from smc_read to info_line [phi:smc_read->info_line]
    // [446] phi info_line::info_text#16 = smc_read::info_text [phi:smc_read->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    // [601] phi from smc_read to smc_read::@7 [phi:smc_read->smc_read::@7]
    // smc_read::@7
    // textcolor(WHITE)
    // [602] call textcolor
    // [316] phi from smc_read::@7 to textcolor [phi:smc_read::@7->textcolor]
    // [316] phi textcolor::color#16 = WHITE [phi:smc_read::@7->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [603] phi from smc_read::@7 to smc_read::@8 [phi:smc_read::@7->smc_read::@8]
    // smc_read::@8
    // gotoxy(x, y)
    // [604] call gotoxy
    // [334] phi from smc_read::@8 to gotoxy [phi:smc_read::@8->gotoxy]
    // [334] phi gotoxy::y#22 = $1f [phi:smc_read::@8->gotoxy#0] -- vbuz1=vbuc1 
    lda #$1f
    sta.z gotoxy.y
    // [334] phi gotoxy::x#22 = smc_read::x#0 [phi:smc_read::@8->gotoxy#1] -- vbuz1=vbuc1 
    lda #x
    sta.z gotoxy.x
    jsr gotoxy
    // [605] phi from smc_read::@8 to smc_read::@9 [phi:smc_read::@8->smc_read::@9]
    // smc_read::@9
    // FILE *fp = fopen("SMC.BIN", "r")
    // [606] call fopen
    // [1418] phi from smc_read::@9 to fopen [phi:smc_read::@9->fopen]
    // [1418] phi __errno#228 = 0 [phi:smc_read::@9->fopen#0] -- vwsz1=vwsc1 
    lda #<0
    sta.z __errno
    sta.z __errno+1
    // [1418] phi fopen::pathtoken#0 = smc_read::path [phi:smc_read::@9->fopen#1] -- pbuz1=pbuc1 
    lda #<path
    sta.z fopen.pathtoken
    lda #>path
    sta.z fopen.pathtoken+1
    jsr fopen
    // FILE *fp = fopen("SMC.BIN", "r")
    // [607] fopen::return#3 = fopen::return#2
    // smc_read::@10
    // [608] smc_read::fp#0 = fopen::return#3
    // if (fp)
    // [609] if((struct $2 *)0==smc_read::fp#0) goto smc_read::@1 -- pssc1_eq_pssz1_then_la1 
    lda.z fp
    cmp #<0
    bne !+
    lda.z fp+1
    cmp #>0
    beq __b4
  !:
    // [610] phi from smc_read::@10 to smc_read::@2 [phi:smc_read::@10->smc_read::@2]
    // [610] phi smc_read::y#3 = $1f [phi:smc_read::@10->smc_read::@2#0] -- vbuz1=vbuc1 
    lda #$1f
    sta.z y
    // [610] phi smc_read::smc_file_size#10 = 0 [phi:smc_read::@10->smc_read::@2#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z smc_file_size
    sta.z smc_file_size+1
    // [610] phi smc_read::progress_row_bytes#3 = 0 [phi:smc_read::@10->smc_read::@2#2] -- vwuz1=vwuc1 
    sta.z progress_row_bytes
    sta.z progress_row_bytes+1
    // [610] phi smc_read::flash_ram_address#2 = (char *)$6000 [phi:smc_read::@10->smc_read::@2#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z flash_ram_address
    lda #>$6000
    sta.z flash_ram_address+1
  // We read b bytes at a time, and each b bytes we plot a dot.
  // Every r bytes we move to the next line.
    // smc_read::@2
  __b2:
    // fgets(flash_ram_address, b, fp)
    // [611] fgets::ptr#2 = smc_read::flash_ram_address#2 -- pbuz1=pbuz2 
    lda.z flash_ram_address
    sta.z fgets.ptr
    lda.z flash_ram_address+1
    sta.z fgets.ptr+1
    // [612] fgets::stream#0 = smc_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.stream
    lda.z fp+1
    sta.z fgets.stream+1
    // [613] call fgets
    // [1499] phi from smc_read::@2 to fgets [phi:smc_read::@2->fgets]
    // [1499] phi fgets::ptr#12 = fgets::ptr#2 [phi:smc_read::@2->fgets#0] -- register_copy 
    // [1499] phi fgets::size#10 = smc_read::b#0 [phi:smc_read::@2->fgets#1] -- vwuz1=vbuc1 
    lda #<b
    sta.z fgets.size
    lda #>b
    sta.z fgets.size+1
    // [1499] phi fgets::stream#2 = fgets::stream#0 [phi:smc_read::@2->fgets#2] -- register_copy 
    jsr fgets
    // fgets(flash_ram_address, b, fp)
    // [614] fgets::return#5 = fgets::return#1
    // smc_read::@11
    // smc_file_read = fgets(flash_ram_address, b, fp)
    // [615] smc_read::smc_file_read#1 = fgets::return#5
    // while (smc_file_read = fgets(flash_ram_address, b, fp))
    // [616] if(0!=smc_read::smc_file_read#1) goto smc_read::@3 -- 0_neq_vwuz1_then_la1 
    lda.z smc_file_read
    ora.z smc_file_read+1
    bne __b3
    // smc_read::@4
    // fclose(fp)
    // [617] fclose::stream#0 = smc_read::fp#0
    // [618] call fclose
    // [1553] phi from smc_read::@4 to fclose [phi:smc_read::@4->fclose]
    // [1553] phi fclose::stream#2 = fclose::stream#0 [phi:smc_read::@4->fclose#0] -- register_copy 
    jsr fclose
    // [619] phi from smc_read::@4 to smc_read::@1 [phi:smc_read::@4->smc_read::@1]
    // [619] phi smc_read::return#0 = smc_read::smc_file_size#10 [phi:smc_read::@4->smc_read::@1#0] -- register_copy 
    rts
    // [619] phi from smc_read::@10 to smc_read::@1 [phi:smc_read::@10->smc_read::@1]
  __b4:
    // [619] phi smc_read::return#0 = 0 [phi:smc_read::@10->smc_read::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // smc_read::@1
    // smc_read::@return
    // }
    // [620] return 
    rts
    // smc_read::@3
  __b3:
    // if (progress_row_bytes == progress_row_size)
    // [621] if(smc_read::progress_row_bytes#3!=smc_read::progress_row_size#0) goto smc_read::@5 -- vwuz1_neq_vwuc1_then_la1 
    lda.z progress_row_bytes+1
    cmp #>progress_row_size
    bne __b5
    lda.z progress_row_bytes
    cmp #<progress_row_size
    bne __b5
    // smc_read::@6
    // gotoxy(x, ++y);
    // [622] smc_read::y#0 = ++ smc_read::y#3 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [623] gotoxy::y#14 = smc_read::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [624] call gotoxy
    // [334] phi from smc_read::@6 to gotoxy [phi:smc_read::@6->gotoxy]
    // [334] phi gotoxy::y#22 = gotoxy::y#14 [phi:smc_read::@6->gotoxy#0] -- register_copy 
    // [334] phi gotoxy::x#22 = smc_read::x#0 [phi:smc_read::@6->gotoxy#1] -- vbuz1=vbuc1 
    lda #x
    sta.z gotoxy.x
    jsr gotoxy
    // [625] phi from smc_read::@6 to smc_read::@5 [phi:smc_read::@6->smc_read::@5]
    // [625] phi smc_read::y#10 = smc_read::y#0 [phi:smc_read::@6->smc_read::@5#0] -- register_copy 
    // [625] phi smc_read::progress_row_bytes#4 = 0 [phi:smc_read::@6->smc_read::@5#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z progress_row_bytes
    sta.z progress_row_bytes+1
    // [625] phi from smc_read::@3 to smc_read::@5 [phi:smc_read::@3->smc_read::@5]
    // [625] phi smc_read::y#10 = smc_read::y#3 [phi:smc_read::@3->smc_read::@5#0] -- register_copy 
    // [625] phi smc_read::progress_row_bytes#4 = smc_read::progress_row_bytes#3 [phi:smc_read::@3->smc_read::@5#1] -- register_copy 
    // smc_read::@5
  __b5:
    // cputc('+')
    // [626] stackpush(char) = '+' -- _stackpushbyte_=vbuc1 
    lda #'+'
    pha
    // [627] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // flash_ram_address += smc_file_read
    // [629] smc_read::flash_ram_address#0 = smc_read::flash_ram_address#2 + smc_read::smc_file_read#1 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z flash_ram_address
    adc.z smc_file_read
    sta.z flash_ram_address
    lda.z flash_ram_address+1
    adc.z smc_file_read+1
    sta.z flash_ram_address+1
    // smc_file_size += smc_file_read
    // [630] smc_read::smc_file_size#1 = smc_read::smc_file_size#10 + smc_read::smc_file_read#1 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z smc_file_size
    adc.z smc_file_read
    sta.z smc_file_size
    lda.z smc_file_size+1
    adc.z smc_file_read+1
    sta.z smc_file_size+1
    // progress_row_bytes += smc_file_read
    // [631] smc_read::progress_row_bytes#1 = smc_read::progress_row_bytes#4 + smc_read::smc_file_read#1 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z progress_row_bytes
    adc.z smc_file_read
    sta.z progress_row_bytes
    lda.z progress_row_bytes+1
    adc.z smc_file_read+1
    sta.z progress_row_bytes+1
    // [610] phi from smc_read::@5 to smc_read::@2 [phi:smc_read::@5->smc_read::@2]
    // [610] phi smc_read::y#3 = smc_read::y#10 [phi:smc_read::@5->smc_read::@2#0] -- register_copy 
    // [610] phi smc_read::smc_file_size#10 = smc_read::smc_file_size#1 [phi:smc_read::@5->smc_read::@2#1] -- register_copy 
    // [610] phi smc_read::progress_row_bytes#3 = smc_read::progress_row_bytes#1 [phi:smc_read::@5->smc_read::@2#2] -- register_copy 
    // [610] phi smc_read::flash_ram_address#2 = smc_read::flash_ram_address#0 [phi:smc_read::@5->smc_read::@2#3] -- register_copy 
    jmp __b2
  .segment Data
    info_text: .text "Reading SMC.BIN flash file into CX16 RAM ..."
    .byte 0
    path: .text "SMC.BIN"
    .byte 0
}
.segment Code
  // wait_key
// __zp($eb) char wait_key(__zp($6e) char *info_text, __zp($4d) char *filter)
wait_key: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    .label wait_key__9 = $d0
    .label bram = $bd
    .label return = $eb
    .label info_text = $6e
    .label ch = $71
    .label filter = $4d
    // info_line(info_text)
    // [633] info_line::info_text#0 = wait_key::info_text#3
    // [634] call info_line
    // [446] phi from wait_key to info_line [phi:wait_key->info_line]
    // [446] phi info_line::info_text#16 = info_line::info_text#0 [phi:wait_key->info_line#0] -- register_copy 
    jsr info_line
    // wait_key::bank_get_bram1
    // return BRAM;
    // [635] wait_key::bram#0 = BRAM -- vbuz1=vbuz2 
    lda.z BRAM
    sta.z bram
    // wait_key::bank_get_brom1
    // return BROM;
    // [636] wait_key::bank_get_brom1_return#0 = BROM -- vbum1=vbuz2 
    lda.z BROM
    sta bank_get_brom1_return
    // wait_key::bank_set_bram1
    // BRAM = bank
    // [637] BRAM = wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // wait_key::bank_set_brom1
    // BROM = bank
    // [638] BROM = wait_key::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [639] phi from wait_key::@2 wait_key::@5 wait_key::bank_set_brom1 to wait_key::kbhit1 [phi:wait_key::@2/wait_key::@5/wait_key::bank_set_brom1->wait_key::kbhit1]
    // wait_key::kbhit1
  kbhit1:
    // wait_key::kbhit1_cbm_k_clrchn1
    // asm
    // asm { jsrCBM_CLRCHN  }
    jsr CBM_CLRCHN
    // [641] phi from wait_key::kbhit1_cbm_k_clrchn1 to wait_key::kbhit1_@2 [phi:wait_key::kbhit1_cbm_k_clrchn1->wait_key::kbhit1_@2]
    // wait_key::kbhit1_@2
    // cbm_k_getin()
    // [642] call cbm_k_getin
    jsr cbm_k_getin
    // [643] cbm_k_getin::return#2 = cbm_k_getin::return#1
    // wait_key::@4
    // [644] wait_key::ch#4 = cbm_k_getin::return#2 -- vwuz1=vbuz2 
    lda.z cbm_k_getin.return
    sta.z ch
    lda #0
    sta.z ch+1
    // wait_key::@3
    // if (filter)
    // [645] if((char *)0!=wait_key::filter#13) goto wait_key::@1 -- pbuc1_neq_pbuz1_then_la1 
    // if there is a filter, check the filter, otherwise return ch.
    lda.z filter+1
    cmp #>0
    bne __b1
    lda.z filter
    cmp #<0
    bne __b1
    // wait_key::@2
    // if(ch)
    // [646] if(0!=wait_key::ch#4) goto wait_key::bank_set_bram2 -- 0_neq_vwuz1_then_la1 
    lda.z ch
    ora.z ch+1
    bne bank_set_bram2
    jmp kbhit1
    // wait_key::bank_set_bram2
  bank_set_bram2:
    // BRAM = bank
    // [647] BRAM = wait_key::bram#0 -- vbuz1=vbuz2 
    lda.z bram
    sta.z BRAM
    // wait_key::bank_set_brom2
    // BROM = bank
    // [648] BROM = wait_key::bank_get_brom1_return#0 -- vbuz1=vbum2 
    lda bank_get_brom1_return
    sta.z BROM
    // wait_key::@return
    // }
    // [649] return 
    rts
    // wait_key::@1
  __b1:
    // strchr(filter, ch)
    // [650] strchr::str#0 = (const void *)wait_key::filter#13 -- pvoz1=pvoz2 
    lda.z filter
    sta.z strchr.str
    lda.z filter+1
    sta.z strchr.str+1
    // [651] strchr::c#0 = wait_key::ch#4 -- vbuz1=vwuz2 
    lda.z ch
    sta.z strchr.c
    // [652] call strchr
    // [656] phi from wait_key::@1 to strchr [phi:wait_key::@1->strchr]
    // [656] phi strchr::c#4 = strchr::c#0 [phi:wait_key::@1->strchr#0] -- register_copy 
    // [656] phi strchr::str#2 = strchr::str#0 [phi:wait_key::@1->strchr#1] -- register_copy 
    jsr strchr
    // strchr(filter, ch)
    // [653] strchr::return#3 = strchr::return#2
    // wait_key::@5
    // [654] wait_key::$9 = strchr::return#3
    // if(strchr(filter, ch) != NULL)
    // [655] if(wait_key::$9!=0) goto wait_key::bank_set_bram2 -- pvoz1_neq_0_then_la1 
    lda.z wait_key__9
    ora.z wait_key__9+1
    bne bank_set_bram2
    jmp kbhit1
  .segment Data
    bank_get_brom1_return: .byte 0
}
.segment Code
  // strchr
// Searches for the first occurrence of the character c (an unsigned char) in the string pointed to, by the argument str.
// - str: The memory to search
// - c: A character to search for
// Return: A pointer to the matching byte or NULL if the character does not occur in the given memory area.
// __zp($d0) void * strchr(__zp($d0) const void *str, __zp($eb) char c)
strchr: {
    .label ptr = $d0
    .label return = $d0
    .label str = $d0
    .label c = $eb
    // [657] strchr::ptr#6 = (char *)strchr::str#2
    // [658] phi from strchr strchr::@3 to strchr::@1 [phi:strchr/strchr::@3->strchr::@1]
    // [658] phi strchr::ptr#2 = strchr::ptr#6 [phi:strchr/strchr::@3->strchr::@1#0] -- register_copy 
    // strchr::@1
  __b1:
    // while(*ptr)
    // [659] if(0!=*strchr::ptr#2) goto strchr::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (ptr),y
    cmp #0
    bne __b2
    // [660] phi from strchr::@1 to strchr::@return [phi:strchr::@1->strchr::@return]
    // [660] phi strchr::return#2 = (void *) 0 [phi:strchr::@1->strchr::@return#0] -- pvoz1=pvoc1 
    tya
    sta.z return
    sta.z return+1
    // strchr::@return
    // }
    // [661] return 
    rts
    // strchr::@2
  __b2:
    // if(*ptr==c)
    // [662] if(*strchr::ptr#2!=strchr::c#4) goto strchr::@3 -- _deref_pbuz1_neq_vbuz2_then_la1 
    ldy #0
    lda (ptr),y
    cmp.z c
    bne __b3
    // strchr::@4
    // [663] strchr::return#8 = (void *)strchr::ptr#2
    // [660] phi from strchr::@4 to strchr::@return [phi:strchr::@4->strchr::@return]
    // [660] phi strchr::return#2 = strchr::return#8 [phi:strchr::@4->strchr::@return#0] -- register_copy 
    rts
    // strchr::@3
  __b3:
    // ptr++;
    // [664] strchr::ptr#1 = ++ strchr::ptr#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr
    bne !+
    inc.z ptr+1
  !:
    jmp __b1
}
  // flash_smc
// unsigned int flash_smc(char x, __zp($cf) char y, char w, __zp($74) unsigned int smc_bytes_total, char b, unsigned int smc_row_total, __zp($dd) char *smc_ram_ptr)
flash_smc: {
    .const x = 2
    .const smc_row_total = $200
    .label flash_smc__25 = $7b
    .label flash_smc__26 = $7b
    .label cx16_k_i2c_write_byte4_offset = $f8
    .label cx16_k_i2c_write_byte4_value = $f6
    .label cx16_k_i2c_write_byte4_result = $ec
    .label cx16_k_i2c_write_byte1_return = $24
    .label smc_bootloader_start = $24
    .label smc_bootloader_not_activated1 = $29
    // Wait an other 5 seconds to ensure the bootloader is activated.
    .label smc_bootloader_activation_countdown = $b8
    .label x1 = $e4
    .label smc_bootloader_not_activated = $29
    .label x2 = $25
    // Wait an other 5 seconds to ensure the bootloader is activated.
    .label smc_bootloader_activation_countdown_1 = $5c
    .label smc_byte_upload = $61
    .label smc_ram_ptr = $dd
    .label smc_bytes_checksum = $7b
    .label smc_package_flashed = $6e
    .label smc_commit_result = $29
    .label smc_attempts_flashed = $ca
    .label smc_bytes_flashed = $71
    .label smc_row_bytes = $d2
    .label smc_attempts_total = $a9
    .label y = $cf
    .label smc_bytes_total = $74
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [665] flash_smc::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [666] flash_smc::cx16_k_i2c_write_byte1_offset = $8f -- vbum1=vbuc1 
    lda #$8f
    sta cx16_k_i2c_write_byte1_offset
    // [667] flash_smc::cx16_k_i2c_write_byte1_value = $31 -- vbum1=vbuc1 
    lda #$31
    sta cx16_k_i2c_write_byte1_value
    // flash_smc::cx16_k_i2c_write_byte1
    // unsigned char result
    // [668] flash_smc::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
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
    // [670] flash_smc::cx16_k_i2c_write_byte1_return#0 = flash_smc::cx16_k_i2c_write_byte1_result -- vbuz1=vbum2 
    lda cx16_k_i2c_write_byte1_result
    sta.z cx16_k_i2c_write_byte1_return
    // flash_smc::cx16_k_i2c_write_byte1_@return
    // }
    // [671] flash_smc::cx16_k_i2c_write_byte1_return#1 = flash_smc::cx16_k_i2c_write_byte1_return#0
    // flash_smc::@27
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [672] flash_smc::smc_bootloader_start#0 = flash_smc::cx16_k_i2c_write_byte1_return#1
    // if(smc_bootloader_start)
    // [673] if(0==flash_smc::smc_bootloader_start#0) goto flash_smc::@3 -- 0_eq_vbuz1_then_la1 
    lda.z smc_bootloader_start
    beq __b2
    // [674] phi from flash_smc::@27 to flash_smc::@2 [phi:flash_smc::@27->flash_smc::@2]
    // flash_smc::@2
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [675] call snprintf_init
    jsr snprintf_init
    // [676] phi from flash_smc::@2 to flash_smc::@30 [phi:flash_smc::@2->flash_smc::@30]
    // flash_smc::@30
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [677] call printf_str
    // [471] phi from flash_smc::@30 to printf_str [phi:flash_smc::@30->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:flash_smc::@30->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = flash_smc::s [phi:flash_smc::@30->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@31
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [678] printf_uchar::uvalue#1 = flash_smc::smc_bootloader_start#0
    // [679] call printf_uchar
    // [1387] phi from flash_smc::@31 to printf_uchar [phi:flash_smc::@31->printf_uchar]
    // [1387] phi printf_uchar::format_zero_padding#10 = 0 [phi:flash_smc::@31->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1387] phi printf_uchar::format_min_length#10 = 0 [phi:flash_smc::@31->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1387] phi printf_uchar::putc#10 = &snputc [phi:flash_smc::@31->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1387] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:flash_smc::@31->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [1387] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#1 [phi:flash_smc::@31->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // flash_smc::@32
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [680] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [681] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [683] call info_line
    // [446] phi from flash_smc::@32 to info_line [phi:flash_smc::@32->info_line]
    // [446] phi info_line::info_text#16 = info_text [phi:flash_smc::@32->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    // flash_smc::@33
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [684] flash_smc::cx16_k_i2c_write_byte2_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte2_device
    // [685] flash_smc::cx16_k_i2c_write_byte2_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte2_offset
    // [686] flash_smc::cx16_k_i2c_write_byte2_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte2_value
    // flash_smc::cx16_k_i2c_write_byte2
    // unsigned char result
    // [687] flash_smc::cx16_k_i2c_write_byte2_result = 0 -- vbum1=vbuc1 
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
    // [689] return 
    rts
    // [690] phi from flash_smc::@27 to flash_smc::@3 [phi:flash_smc::@27->flash_smc::@3]
  __b2:
    // [690] phi flash_smc::smc_bootloader_activation_countdown#22 = $14 [phi:flash_smc::@27->flash_smc::@3#0] -- vbuz1=vbuc1 
    lda #$14
    sta.z smc_bootloader_activation_countdown
    // flash_smc::@3
  __b3:
    // while(smc_bootloader_activation_countdown)
    // [691] if(0!=flash_smc::smc_bootloader_activation_countdown#22) goto flash_smc::@4 -- 0_neq_vbuz1_then_la1 
    lda.z smc_bootloader_activation_countdown
    beq !__b4+
    jmp __b4
  !__b4:
    // [692] phi from flash_smc::@3 flash_smc::@34 to flash_smc::@9 [phi:flash_smc::@3/flash_smc::@34->flash_smc::@9]
  __b5:
    // [692] phi flash_smc::smc_bootloader_activation_countdown#23 = 5 [phi:flash_smc::@3/flash_smc::@34->flash_smc::@9#0] -- vbuz1=vbuc1 
    lda #5
    sta.z smc_bootloader_activation_countdown_1
    // flash_smc::@9
  __b9:
    // while(smc_bootloader_activation_countdown)
    // [693] if(0!=flash_smc::smc_bootloader_activation_countdown#23) goto flash_smc::@11 -- 0_neq_vbuz1_then_la1 
    lda.z smc_bootloader_activation_countdown_1
    beq !__b13+
    jmp __b13
  !__b13:
    // flash_smc::@10
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [694] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [695] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [696] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [697] cx16_k_i2c_read_byte::return#3 = cx16_k_i2c_read_byte::return#1
    // flash_smc::@39
    // smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [698] flash_smc::smc_bootloader_not_activated#1 = cx16_k_i2c_read_byte::return#3
    // if(smc_bootloader_not_activated)
    // [699] if(0==flash_smc::smc_bootloader_not_activated#1) goto flash_smc::@1 -- 0_eq_vwuz1_then_la1 
    lda.z smc_bootloader_not_activated
    ora.z smc_bootloader_not_activated+1
    beq __b1
    // [700] phi from flash_smc::@39 to flash_smc::@14 [phi:flash_smc::@39->flash_smc::@14]
    // flash_smc::@14
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [701] call snprintf_init
    jsr snprintf_init
    // [702] phi from flash_smc::@14 to flash_smc::@46 [phi:flash_smc::@14->flash_smc::@46]
    // flash_smc::@46
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [703] call printf_str
    // [471] phi from flash_smc::@46 to printf_str [phi:flash_smc::@46->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:flash_smc::@46->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = flash_smc::s5 [phi:flash_smc::@46->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@47
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [704] printf_uint::uvalue#0 = flash_smc::smc_bootloader_not_activated#1
    // [705] call printf_uint
    // [480] phi from flash_smc::@47 to printf_uint [phi:flash_smc::@47->printf_uint]
    // [480] phi printf_uint::format_zero_padding#11 = 0 [phi:flash_smc::@47->printf_uint#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uint.format_zero_padding
    // [480] phi printf_uint::format_min_length#11 = 0 [phi:flash_smc::@47->printf_uint#1] -- vbuz1=vbuc1 
    sta.z printf_uint.format_min_length
    // [480] phi printf_uint::format_radix#11 = HEXADECIMAL [phi:flash_smc::@47->printf_uint#2] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [480] phi printf_uint::uvalue#11 = printf_uint::uvalue#0 [phi:flash_smc::@47->printf_uint#3] -- register_copy 
    jsr printf_uint
    // flash_smc::@48
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [706] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [707] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [709] call info_line
    // [446] phi from flash_smc::@48 to info_line [phi:flash_smc::@48->info_line]
    // [446] phi info_line::info_text#16 = info_text [phi:flash_smc::@48->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    rts
    // [710] phi from flash_smc::@39 to flash_smc::@1 [phi:flash_smc::@39->flash_smc::@1]
    // flash_smc::@1
  __b1:
    // textcolor(WHITE)
    // [711] call textcolor
    // [316] phi from flash_smc::@1 to textcolor [phi:flash_smc::@1->textcolor]
    // [316] phi textcolor::color#16 = WHITE [phi:flash_smc::@1->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [712] phi from flash_smc::@1 to flash_smc::@45 [phi:flash_smc::@1->flash_smc::@45]
    // flash_smc::@45
    // gotoxy(x, y)
    // [713] call gotoxy
    // [334] phi from flash_smc::@45 to gotoxy [phi:flash_smc::@45->gotoxy]
    // [334] phi gotoxy::y#22 = $1f [phi:flash_smc::@45->gotoxy#0] -- vbuz1=vbuc1 
    lda #$1f
    sta.z gotoxy.y
    // [334] phi gotoxy::x#22 = flash_smc::x#0 [phi:flash_smc::@45->gotoxy#1] -- vbuz1=vbuc1 
    lda #x
    sta.z gotoxy.x
    jsr gotoxy
    // [714] phi from flash_smc::@45 to flash_smc::@15 [phi:flash_smc::@45->flash_smc::@15]
    // [714] phi flash_smc::y#33 = $1f [phi:flash_smc::@45->flash_smc::@15#0] -- vbuz1=vbuc1 
    lda #$1f
    sta.z y
    // [714] phi flash_smc::smc_attempts_total#21 = 0 [phi:flash_smc::@45->flash_smc::@15#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z smc_attempts_total
    sta.z smc_attempts_total+1
    // [714] phi flash_smc::smc_row_bytes#14 = 0 [phi:flash_smc::@45->flash_smc::@15#2] -- vwuz1=vwuc1 
    sta.z smc_row_bytes
    sta.z smc_row_bytes+1
    // [714] phi flash_smc::smc_ram_ptr#13 = (char *)$6000 [phi:flash_smc::@45->flash_smc::@15#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z smc_ram_ptr
    lda #>$6000
    sta.z smc_ram_ptr+1
    // [714] phi flash_smc::smc_bytes_flashed#13 = 0 [phi:flash_smc::@45->flash_smc::@15#4] -- vwuz1=vwuc1 
    lda #<0
    sta.z smc_bytes_flashed
    sta.z smc_bytes_flashed+1
    // [714] phi from flash_smc::@18 to flash_smc::@15 [phi:flash_smc::@18->flash_smc::@15]
    // [714] phi flash_smc::y#33 = flash_smc::y#23 [phi:flash_smc::@18->flash_smc::@15#0] -- register_copy 
    // [714] phi flash_smc::smc_attempts_total#21 = flash_smc::smc_attempts_total#17 [phi:flash_smc::@18->flash_smc::@15#1] -- register_copy 
    // [714] phi flash_smc::smc_row_bytes#14 = flash_smc::smc_row_bytes#10 [phi:flash_smc::@18->flash_smc::@15#2] -- register_copy 
    // [714] phi flash_smc::smc_ram_ptr#13 = flash_smc::smc_ram_ptr#10 [phi:flash_smc::@18->flash_smc::@15#3] -- register_copy 
    // [714] phi flash_smc::smc_bytes_flashed#13 = flash_smc::smc_bytes_flashed#12 [phi:flash_smc::@18->flash_smc::@15#4] -- register_copy 
    // flash_smc::@15
  __b15:
    // while(smc_bytes_flashed < smc_bytes_total)
    // [715] if(flash_smc::smc_bytes_flashed#13<flash_smc::smc_bytes_total#0) goto flash_smc::@17 -- vwuz1_lt_vwuz2_then_la1 
    lda.z smc_bytes_flashed+1
    cmp.z smc_bytes_total+1
    bcc __b8
    bne !+
    lda.z smc_bytes_flashed
    cmp.z smc_bytes_total
    bcc __b8
  !:
    // flash_smc::@16
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [716] flash_smc::cx16_k_i2c_write_byte3_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte3_device
    // [717] flash_smc::cx16_k_i2c_write_byte3_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte3_offset
    // [718] flash_smc::cx16_k_i2c_write_byte3_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte3_value
    // flash_smc::cx16_k_i2c_write_byte3
    // unsigned char result
    // [719] flash_smc::cx16_k_i2c_write_byte3_result = 0 -- vbum1=vbuc1 
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
    // [721] phi from flash_smc::@15 to flash_smc::@17 [phi:flash_smc::@15->flash_smc::@17]
  __b8:
    // [721] phi flash_smc::y#23 = flash_smc::y#33 [phi:flash_smc::@15->flash_smc::@17#0] -- register_copy 
    // [721] phi flash_smc::smc_attempts_total#17 = flash_smc::smc_attempts_total#21 [phi:flash_smc::@15->flash_smc::@17#1] -- register_copy 
    // [721] phi flash_smc::smc_row_bytes#10 = flash_smc::smc_row_bytes#14 [phi:flash_smc::@15->flash_smc::@17#2] -- register_copy 
    // [721] phi flash_smc::smc_ram_ptr#10 = flash_smc::smc_ram_ptr#13 [phi:flash_smc::@15->flash_smc::@17#3] -- register_copy 
    // [721] phi flash_smc::smc_bytes_flashed#12 = flash_smc::smc_bytes_flashed#13 [phi:flash_smc::@15->flash_smc::@17#4] -- register_copy 
    // [721] phi flash_smc::smc_attempts_flashed#19 = 0 [phi:flash_smc::@15->flash_smc::@17#5] -- vbuz1=vbuc1 
    lda #0
    sta.z smc_attempts_flashed
    // [721] phi flash_smc::smc_package_committed#2 = 0 [phi:flash_smc::@15->flash_smc::@17#6] -- vbum1=vbuc1 
    sta smc_package_committed
    // flash_smc::@17
  __b17:
    // while(!smc_package_committed && smc_attempts_flashed < 10)
    // [722] if(0!=flash_smc::smc_package_committed#2) goto flash_smc::@18 -- 0_neq_vbum1_then_la1 
    lda smc_package_committed
    bne __b18
    // flash_smc::@61
    // [723] if(flash_smc::smc_attempts_flashed#19<$a) goto flash_smc::@19 -- vbuz1_lt_vbuc1_then_la1 
    lda.z smc_attempts_flashed
    cmp #$a
    bcc __b10
    // flash_smc::@18
  __b18:
    // if(smc_attempts_flashed >= 10)
    // [724] if(flash_smc::smc_attempts_flashed#19<$a) goto flash_smc::@15 -- vbuz1_lt_vbuc1_then_la1 
    lda.z smc_attempts_flashed
    cmp #$a
    bcc __b15
    // [725] phi from flash_smc::@18 to flash_smc::@26 [phi:flash_smc::@18->flash_smc::@26]
    // flash_smc::@26
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [726] call snprintf_init
    jsr snprintf_init
    // [727] phi from flash_smc::@26 to flash_smc::@58 [phi:flash_smc::@26->flash_smc::@58]
    // flash_smc::@58
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [728] call printf_str
    // [471] phi from flash_smc::@58 to printf_str [phi:flash_smc::@58->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:flash_smc::@58->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = flash_smc::s10 [phi:flash_smc::@58->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@59
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [729] printf_uint::uvalue#4 = flash_smc::smc_bytes_flashed#12 -- vwuz1=vwuz2 
    lda.z smc_bytes_flashed
    sta.z printf_uint.uvalue
    lda.z smc_bytes_flashed+1
    sta.z printf_uint.uvalue+1
    // [730] call printf_uint
    // [480] phi from flash_smc::@59 to printf_uint [phi:flash_smc::@59->printf_uint]
    // [480] phi printf_uint::format_zero_padding#11 = 1 [phi:flash_smc::@59->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [480] phi printf_uint::format_min_length#11 = 4 [phi:flash_smc::@59->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [480] phi printf_uint::format_radix#11 = HEXADECIMAL [phi:flash_smc::@59->printf_uint#2] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [480] phi printf_uint::uvalue#11 = printf_uint::uvalue#4 [phi:flash_smc::@59->printf_uint#3] -- register_copy 
    jsr printf_uint
    // flash_smc::@60
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [731] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [732] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [734] call info_line
    // [446] phi from flash_smc::@60 to info_line [phi:flash_smc::@60->info_line]
    // [446] phi info_line::info_text#16 = info_text [phi:flash_smc::@60->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    rts
    // [735] phi from flash_smc::@61 to flash_smc::@19 [phi:flash_smc::@61->flash_smc::@19]
  __b10:
    // [735] phi flash_smc::smc_bytes_checksum#2 = 0 [phi:flash_smc::@61->flash_smc::@19#0] -- vbuz1=vbuc1 
    lda #0
    sta.z smc_bytes_checksum
    // [735] phi flash_smc::smc_ram_ptr#12 = flash_smc::smc_ram_ptr#10 [phi:flash_smc::@61->flash_smc::@19#1] -- register_copy 
    // [735] phi flash_smc::smc_package_flashed#2 = 0 [phi:flash_smc::@61->flash_smc::@19#2] -- vwuz1=vwuc1 
    sta.z smc_package_flashed
    sta.z smc_package_flashed+1
    // flash_smc::@19
  __b19:
    // while(smc_package_flashed < 8)
    // [736] if(flash_smc::smc_package_flashed#2<8) goto flash_smc::@20 -- vwuz1_lt_vbuc1_then_la1 
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
    // [737] flash_smc::$25 = flash_smc::smc_bytes_checksum#2 ^ $ff -- vbuz1=vbuz1_bxor_vbuc1 
    lda #$ff
    eor.z flash_smc__25
    sta.z flash_smc__25
    // (smc_bytes_checksum ^ 0xFF)+1
    // [738] flash_smc::$26 = flash_smc::$25 + 1 -- vbuz1=vbuz1_plus_1 
    inc.z flash_smc__26
    // unsigned char smc_checksum_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, (smc_bytes_checksum ^ 0xFF)+1)
    // [739] flash_smc::cx16_k_i2c_write_byte5_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte5_device
    // [740] flash_smc::cx16_k_i2c_write_byte5_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte5_offset
    // [741] flash_smc::cx16_k_i2c_write_byte5_value = flash_smc::$26 -- vbum1=vbuz2 
    lda.z flash_smc__26
    sta cx16_k_i2c_write_byte5_value
    // flash_smc::cx16_k_i2c_write_byte5
    // unsigned char result
    // [742] flash_smc::cx16_k_i2c_write_byte5_result = 0 -- vbum1=vbuc1 
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
    // [744] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [745] cx16_k_i2c_read_byte::offset = $81 -- vbum1=vbuc1 
    lda #$81
    sta cx16_k_i2c_read_byte.offset
    // [746] call cx16_k_i2c_read_byte
    // Now send the commit command.
    jsr cx16_k_i2c_read_byte
    // [747] cx16_k_i2c_read_byte::return#4 = cx16_k_i2c_read_byte::return#1
    // flash_smc::@49
    // [748] flash_smc::smc_commit_result#0 = cx16_k_i2c_read_byte::return#4
    // if(smc_commit_result == 1)
    // [749] if(flash_smc::smc_commit_result#0==1) goto flash_smc::@23 -- vwuz1_eq_vbuc1_then_la1 
    lda.z smc_commit_result+1
    bne !+
    lda.z smc_commit_result
    cmp #1
    beq __b23
  !:
    // flash_smc::@22
    // smc_ram_ptr -= 8
    // [750] flash_smc::smc_ram_ptr#1 = flash_smc::smc_ram_ptr#12 - 8 -- pbuz1=pbuz1_minus_vbuc1 
    sec
    lda.z smc_ram_ptr
    sbc #8
    sta.z smc_ram_ptr
    lda.z smc_ram_ptr+1
    sbc #0
    sta.z smc_ram_ptr+1
    // smc_attempts_flashed++;
    // [751] flash_smc::smc_attempts_flashed#1 = ++ flash_smc::smc_attempts_flashed#19 -- vbuz1=_inc_vbuz1 
    inc.z smc_attempts_flashed
    // [721] phi from flash_smc::@22 to flash_smc::@17 [phi:flash_smc::@22->flash_smc::@17]
    // [721] phi flash_smc::y#23 = flash_smc::y#23 [phi:flash_smc::@22->flash_smc::@17#0] -- register_copy 
    // [721] phi flash_smc::smc_attempts_total#17 = flash_smc::smc_attempts_total#17 [phi:flash_smc::@22->flash_smc::@17#1] -- register_copy 
    // [721] phi flash_smc::smc_row_bytes#10 = flash_smc::smc_row_bytes#10 [phi:flash_smc::@22->flash_smc::@17#2] -- register_copy 
    // [721] phi flash_smc::smc_ram_ptr#10 = flash_smc::smc_ram_ptr#1 [phi:flash_smc::@22->flash_smc::@17#3] -- register_copy 
    // [721] phi flash_smc::smc_bytes_flashed#12 = flash_smc::smc_bytes_flashed#12 [phi:flash_smc::@22->flash_smc::@17#4] -- register_copy 
    // [721] phi flash_smc::smc_attempts_flashed#19 = flash_smc::smc_attempts_flashed#1 [phi:flash_smc::@22->flash_smc::@17#5] -- register_copy 
    // [721] phi flash_smc::smc_package_committed#2 = flash_smc::smc_package_committed#2 [phi:flash_smc::@22->flash_smc::@17#6] -- register_copy 
    jmp __b17
    // flash_smc::@23
  __b23:
    // if (smc_row_bytes == smc_row_total)
    // [752] if(flash_smc::smc_row_bytes#10!=flash_smc::smc_row_total#0) goto flash_smc::@24 -- vwuz1_neq_vwuc1_then_la1 
    lda.z smc_row_bytes+1
    cmp #>smc_row_total
    bne __b24
    lda.z smc_row_bytes
    cmp #<smc_row_total
    bne __b24
    // flash_smc::@25
    // gotoxy(x, ++y);
    // [753] flash_smc::y#0 = ++ flash_smc::y#23 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [754] gotoxy::y#16 = flash_smc::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [755] call gotoxy
    // [334] phi from flash_smc::@25 to gotoxy [phi:flash_smc::@25->gotoxy]
    // [334] phi gotoxy::y#22 = gotoxy::y#16 [phi:flash_smc::@25->gotoxy#0] -- register_copy 
    // [334] phi gotoxy::x#22 = flash_smc::x#0 [phi:flash_smc::@25->gotoxy#1] -- vbuz1=vbuc1 
    lda #x
    sta.z gotoxy.x
    jsr gotoxy
    // [756] phi from flash_smc::@25 to flash_smc::@24 [phi:flash_smc::@25->flash_smc::@24]
    // [756] phi flash_smc::y#35 = flash_smc::y#0 [phi:flash_smc::@25->flash_smc::@24#0] -- register_copy 
    // [756] phi flash_smc::smc_row_bytes#4 = 0 [phi:flash_smc::@25->flash_smc::@24#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z smc_row_bytes
    sta.z smc_row_bytes+1
    // [756] phi from flash_smc::@23 to flash_smc::@24 [phi:flash_smc::@23->flash_smc::@24]
    // [756] phi flash_smc::y#35 = flash_smc::y#23 [phi:flash_smc::@23->flash_smc::@24#0] -- register_copy 
    // [756] phi flash_smc::smc_row_bytes#4 = flash_smc::smc_row_bytes#10 [phi:flash_smc::@23->flash_smc::@24#1] -- register_copy 
    // flash_smc::@24
  __b24:
    // cputc('*')
    // [757] stackpush(char) = '*' -- _stackpushbyte_=vbuc1 
    lda #'*'
    pha
    // [758] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_bytes_flashed += 8
    // [760] flash_smc::smc_bytes_flashed#1 = flash_smc::smc_bytes_flashed#12 + 8 -- vwuz1=vwuz1_plus_vbuc1 
    lda #8
    clc
    adc.z smc_bytes_flashed
    sta.z smc_bytes_flashed
    bcc !+
    inc.z smc_bytes_flashed+1
  !:
    // smc_row_bytes += 8
    // [761] flash_smc::smc_row_bytes#1 = flash_smc::smc_row_bytes#4 + 8 -- vwuz1=vwuz1_plus_vbuc1 
    lda #8
    clc
    adc.z smc_row_bytes
    sta.z smc_row_bytes
    bcc !+
    inc.z smc_row_bytes+1
  !:
    // smc_attempts_total += smc_attempts_flashed
    // [762] flash_smc::smc_attempts_total#1 = flash_smc::smc_attempts_total#17 + flash_smc::smc_attempts_flashed#19 -- vwuz1=vwuz1_plus_vbuz2 
    lda.z smc_attempts_flashed
    clc
    adc.z smc_attempts_total
    sta.z smc_attempts_total
    bcc !+
    inc.z smc_attempts_total+1
  !:
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [763] call snprintf_init
    jsr snprintf_init
    // [764] phi from flash_smc::@24 to flash_smc::@50 [phi:flash_smc::@24->flash_smc::@50]
    // flash_smc::@50
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [765] call printf_str
    // [471] phi from flash_smc::@50 to printf_str [phi:flash_smc::@50->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:flash_smc::@50->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = flash_smc::s6 [phi:flash_smc::@50->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@51
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [766] printf_uint::uvalue#1 = flash_smc::smc_bytes_flashed#1 -- vwuz1=vwuz2 
    lda.z smc_bytes_flashed
    sta.z printf_uint.uvalue
    lda.z smc_bytes_flashed+1
    sta.z printf_uint.uvalue+1
    // [767] call printf_uint
    // [480] phi from flash_smc::@51 to printf_uint [phi:flash_smc::@51->printf_uint]
    // [480] phi printf_uint::format_zero_padding#11 = 1 [phi:flash_smc::@51->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [480] phi printf_uint::format_min_length#11 = 5 [phi:flash_smc::@51->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [480] phi printf_uint::format_radix#11 = DECIMAL [phi:flash_smc::@51->printf_uint#2] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [480] phi printf_uint::uvalue#11 = printf_uint::uvalue#1 [phi:flash_smc::@51->printf_uint#3] -- register_copy 
    jsr printf_uint
    // [768] phi from flash_smc::@51 to flash_smc::@52 [phi:flash_smc::@51->flash_smc::@52]
    // flash_smc::@52
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [769] call printf_str
    // [471] phi from flash_smc::@52 to printf_str [phi:flash_smc::@52->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:flash_smc::@52->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = s7 [phi:flash_smc::@52->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@53
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [770] printf_uint::uvalue#2 = flash_smc::smc_bytes_total#0 -- vwuz1=vwuz2 
    lda.z smc_bytes_total
    sta.z printf_uint.uvalue
    lda.z smc_bytes_total+1
    sta.z printf_uint.uvalue+1
    // [771] call printf_uint
    // [480] phi from flash_smc::@53 to printf_uint [phi:flash_smc::@53->printf_uint]
    // [480] phi printf_uint::format_zero_padding#11 = 1 [phi:flash_smc::@53->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [480] phi printf_uint::format_min_length#11 = 5 [phi:flash_smc::@53->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [480] phi printf_uint::format_radix#11 = DECIMAL [phi:flash_smc::@53->printf_uint#2] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [480] phi printf_uint::uvalue#11 = printf_uint::uvalue#2 [phi:flash_smc::@53->printf_uint#3] -- register_copy 
    jsr printf_uint
    // [772] phi from flash_smc::@53 to flash_smc::@54 [phi:flash_smc::@53->flash_smc::@54]
    // flash_smc::@54
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [773] call printf_str
    // [471] phi from flash_smc::@54 to printf_str [phi:flash_smc::@54->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:flash_smc::@54->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = flash_smc::s8 [phi:flash_smc::@54->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@55
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [774] printf_uint::uvalue#3 = flash_smc::smc_attempts_total#1 -- vwuz1=vwuz2 
    lda.z smc_attempts_total
    sta.z printf_uint.uvalue
    lda.z smc_attempts_total+1
    sta.z printf_uint.uvalue+1
    // [775] call printf_uint
    // [480] phi from flash_smc::@55 to printf_uint [phi:flash_smc::@55->printf_uint]
    // [480] phi printf_uint::format_zero_padding#11 = 1 [phi:flash_smc::@55->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [480] phi printf_uint::format_min_length#11 = 2 [phi:flash_smc::@55->printf_uint#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uint.format_min_length
    // [480] phi printf_uint::format_radix#11 = DECIMAL [phi:flash_smc::@55->printf_uint#2] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [480] phi printf_uint::uvalue#11 = printf_uint::uvalue#3 [phi:flash_smc::@55->printf_uint#3] -- register_copy 
    jsr printf_uint
    // [776] phi from flash_smc::@55 to flash_smc::@56 [phi:flash_smc::@55->flash_smc::@56]
    // flash_smc::@56
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [777] call printf_str
    // [471] phi from flash_smc::@56 to printf_str [phi:flash_smc::@56->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:flash_smc::@56->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = flash_smc::s9 [phi:flash_smc::@56->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@57
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [778] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [779] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [781] call info_line
    // [446] phi from flash_smc::@57 to info_line [phi:flash_smc::@57->info_line]
    // [446] phi info_line::info_text#16 = info_text [phi:flash_smc::@57->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    // [721] phi from flash_smc::@57 to flash_smc::@17 [phi:flash_smc::@57->flash_smc::@17]
    // [721] phi flash_smc::y#23 = flash_smc::y#35 [phi:flash_smc::@57->flash_smc::@17#0] -- register_copy 
    // [721] phi flash_smc::smc_attempts_total#17 = flash_smc::smc_attempts_total#1 [phi:flash_smc::@57->flash_smc::@17#1] -- register_copy 
    // [721] phi flash_smc::smc_row_bytes#10 = flash_smc::smc_row_bytes#1 [phi:flash_smc::@57->flash_smc::@17#2] -- register_copy 
    // [721] phi flash_smc::smc_ram_ptr#10 = flash_smc::smc_ram_ptr#12 [phi:flash_smc::@57->flash_smc::@17#3] -- register_copy 
    // [721] phi flash_smc::smc_bytes_flashed#12 = flash_smc::smc_bytes_flashed#1 [phi:flash_smc::@57->flash_smc::@17#4] -- register_copy 
    // [721] phi flash_smc::smc_attempts_flashed#19 = flash_smc::smc_attempts_flashed#19 [phi:flash_smc::@57->flash_smc::@17#5] -- register_copy 
    // [721] phi flash_smc::smc_package_committed#2 = 1 [phi:flash_smc::@57->flash_smc::@17#6] -- vbum1=vbuc1 
    lda #1
    sta smc_package_committed
    jmp __b17
    // flash_smc::@20
  __b20:
    // unsigned char smc_byte_upload = *smc_ram_ptr
    // [782] flash_smc::smc_byte_upload#0 = *flash_smc::smc_ram_ptr#12 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (smc_ram_ptr),y
    sta.z smc_byte_upload
    // smc_ram_ptr++;
    // [783] flash_smc::smc_ram_ptr#0 = ++ flash_smc::smc_ram_ptr#12 -- pbuz1=_inc_pbuz1 
    inc.z smc_ram_ptr
    bne !+
    inc.z smc_ram_ptr+1
  !:
    // smc_bytes_checksum += smc_byte_upload
    // [784] flash_smc::smc_bytes_checksum#1 = flash_smc::smc_bytes_checksum#2 + flash_smc::smc_byte_upload#0 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z smc_bytes_checksum
    clc
    adc.z smc_byte_upload
    sta.z smc_bytes_checksum
    // unsigned char smc_upload_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, smc_byte_upload)
    // [785] flash_smc::cx16_k_i2c_write_byte4_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte4_device
    // [786] flash_smc::cx16_k_i2c_write_byte4_offset = $80 -- vbuz1=vbuc1 
    lda #$80
    sta.z cx16_k_i2c_write_byte4_offset
    // [787] flash_smc::cx16_k_i2c_write_byte4_value = flash_smc::smc_byte_upload#0 -- vbuz1=vbuz2 
    lda.z smc_byte_upload
    sta.z cx16_k_i2c_write_byte4_value
    // flash_smc::cx16_k_i2c_write_byte4
    // unsigned char result
    // [788] flash_smc::cx16_k_i2c_write_byte4_result = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cx16_k_i2c_write_byte4_result
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
    // [790] flash_smc::smc_package_flashed#1 = ++ flash_smc::smc_package_flashed#2 -- vwuz1=_inc_vwuz1 
    inc.z smc_package_flashed
    bne !+
    inc.z smc_package_flashed+1
  !:
    // [735] phi from flash_smc::@28 to flash_smc::@19 [phi:flash_smc::@28->flash_smc::@19]
    // [735] phi flash_smc::smc_bytes_checksum#2 = flash_smc::smc_bytes_checksum#1 [phi:flash_smc::@28->flash_smc::@19#0] -- register_copy 
    // [735] phi flash_smc::smc_ram_ptr#12 = flash_smc::smc_ram_ptr#0 [phi:flash_smc::@28->flash_smc::@19#1] -- register_copy 
    // [735] phi flash_smc::smc_package_flashed#2 = flash_smc::smc_package_flashed#1 [phi:flash_smc::@28->flash_smc::@19#2] -- register_copy 
    jmp __b19
    // [791] phi from flash_smc::@9 to flash_smc::@11 [phi:flash_smc::@9->flash_smc::@11]
  __b13:
    // [791] phi flash_smc::x2#2 = $10000*1 [phi:flash_smc::@9->flash_smc::@11#0] -- vduz1=vduc1 
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
    // [792] if(flash_smc::x2#2>0) goto flash_smc::@12 -- vduz1_gt_0_then_la1 
    lda.z x2+3
    bne __b12
    lda.z x2+2
    bne __b12
    lda.z x2+1
    bne __b12
    lda.z x2
    bne __b12
  !:
    // [793] phi from flash_smc::@11 to flash_smc::@13 [phi:flash_smc::@11->flash_smc::@13]
    // flash_smc::@13
    // sprintf(info_text, "Waiting an other %u seconds before flashing the SMC!", smc_bootloader_activation_countdown)
    // [794] call snprintf_init
    jsr snprintf_init
    // [795] phi from flash_smc::@13 to flash_smc::@40 [phi:flash_smc::@13->flash_smc::@40]
    // flash_smc::@40
    // sprintf(info_text, "Waiting an other %u seconds before flashing the SMC!", smc_bootloader_activation_countdown)
    // [796] call printf_str
    // [471] phi from flash_smc::@40 to printf_str [phi:flash_smc::@40->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:flash_smc::@40->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = flash_smc::s3 [phi:flash_smc::@40->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@41
    // sprintf(info_text, "Waiting an other %u seconds before flashing the SMC!", smc_bootloader_activation_countdown)
    // [797] printf_uchar::uvalue#3 = flash_smc::smc_bootloader_activation_countdown#23 -- vbuz1=vbuz2 
    lda.z smc_bootloader_activation_countdown_1
    sta.z printf_uchar.uvalue
    // [798] call printf_uchar
    // [1387] phi from flash_smc::@41 to printf_uchar [phi:flash_smc::@41->printf_uchar]
    // [1387] phi printf_uchar::format_zero_padding#10 = 0 [phi:flash_smc::@41->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1387] phi printf_uchar::format_min_length#10 = 0 [phi:flash_smc::@41->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1387] phi printf_uchar::putc#10 = &snputc [phi:flash_smc::@41->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1387] phi printf_uchar::format_radix#10 = DECIMAL [phi:flash_smc::@41->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1387] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#3 [phi:flash_smc::@41->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [799] phi from flash_smc::@41 to flash_smc::@42 [phi:flash_smc::@41->flash_smc::@42]
    // flash_smc::@42
    // sprintf(info_text, "Waiting an other %u seconds before flashing the SMC!", smc_bootloader_activation_countdown)
    // [800] call printf_str
    // [471] phi from flash_smc::@42 to printf_str [phi:flash_smc::@42->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:flash_smc::@42->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = flash_smc::s4 [phi:flash_smc::@42->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@43
    // sprintf(info_text, "Waiting an other %u seconds before flashing the SMC!", smc_bootloader_activation_countdown)
    // [801] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [802] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [804] call info_line
    // [446] phi from flash_smc::@43 to info_line [phi:flash_smc::@43->info_line]
    // [446] phi info_line::info_text#16 = info_text [phi:flash_smc::@43->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    // flash_smc::@44
    // smc_bootloader_activation_countdown--;
    // [805] flash_smc::smc_bootloader_activation_countdown#3 = -- flash_smc::smc_bootloader_activation_countdown#23 -- vbuz1=_dec_vbuz1 
    dec.z smc_bootloader_activation_countdown_1
    // [692] phi from flash_smc::@44 to flash_smc::@9 [phi:flash_smc::@44->flash_smc::@9]
    // [692] phi flash_smc::smc_bootloader_activation_countdown#23 = flash_smc::smc_bootloader_activation_countdown#3 [phi:flash_smc::@44->flash_smc::@9#0] -- register_copy 
    jmp __b9
    // flash_smc::@12
  __b12:
    // for(unsigned long x=65536*1; x>0; x--)
    // [806] flash_smc::x2#1 = -- flash_smc::x2#2 -- vduz1=_dec_vduz1 
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
    // [791] phi from flash_smc::@12 to flash_smc::@11 [phi:flash_smc::@12->flash_smc::@11]
    // [791] phi flash_smc::x2#2 = flash_smc::x2#1 [phi:flash_smc::@12->flash_smc::@11#0] -- register_copy 
    jmp __b11
    // flash_smc::@4
  __b4:
    // unsigned int smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [807] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [808] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [809] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [810] cx16_k_i2c_read_byte::return#2 = cx16_k_i2c_read_byte::return#1
    // flash_smc::@34
    // [811] flash_smc::smc_bootloader_not_activated1#0 = cx16_k_i2c_read_byte::return#2
    // if(smc_bootloader_not_activated)
    // [812] if(0!=flash_smc::smc_bootloader_not_activated1#0) goto flash_smc::@6 -- 0_neq_vwuz1_then_la1 
    lda.z smc_bootloader_not_activated1
    ora.z smc_bootloader_not_activated1+1
    bne __b14
    jmp __b5
    // [813] phi from flash_smc::@34 to flash_smc::@6 [phi:flash_smc::@34->flash_smc::@6]
  __b14:
    // [813] phi flash_smc::x1#2 = $10000*6 [phi:flash_smc::@34->flash_smc::@6#0] -- vduz1=vduc1 
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
    // [814] if(flash_smc::x1#2>0) goto flash_smc::@7 -- vduz1_gt_0_then_la1 
    lda.z x1+3
    bne __b7
    lda.z x1+2
    bne __b7
    lda.z x1+1
    bne __b7
    lda.z x1
    bne __b7
  !:
    // [815] phi from flash_smc::@6 to flash_smc::@8 [phi:flash_smc::@6->flash_smc::@8]
    // flash_smc::@8
    // sprintf(info_text, "Press POWER and RESET on the CX16 within %u seconds!", smc_bootloader_activation_countdown)
    // [816] call snprintf_init
    jsr snprintf_init
    // [817] phi from flash_smc::@8 to flash_smc::@35 [phi:flash_smc::@8->flash_smc::@35]
    // flash_smc::@35
    // sprintf(info_text, "Press POWER and RESET on the CX16 within %u seconds!", smc_bootloader_activation_countdown)
    // [818] call printf_str
    // [471] phi from flash_smc::@35 to printf_str [phi:flash_smc::@35->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:flash_smc::@35->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = flash_smc::s1 [phi:flash_smc::@35->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@36
    // sprintf(info_text, "Press POWER and RESET on the CX16 within %u seconds!", smc_bootloader_activation_countdown)
    // [819] printf_uchar::uvalue#2 = flash_smc::smc_bootloader_activation_countdown#22 -- vbuz1=vbuz2 
    lda.z smc_bootloader_activation_countdown
    sta.z printf_uchar.uvalue
    // [820] call printf_uchar
    // [1387] phi from flash_smc::@36 to printf_uchar [phi:flash_smc::@36->printf_uchar]
    // [1387] phi printf_uchar::format_zero_padding#10 = 0 [phi:flash_smc::@36->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1387] phi printf_uchar::format_min_length#10 = 0 [phi:flash_smc::@36->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1387] phi printf_uchar::putc#10 = &snputc [phi:flash_smc::@36->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1387] phi printf_uchar::format_radix#10 = DECIMAL [phi:flash_smc::@36->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1387] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#2 [phi:flash_smc::@36->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [821] phi from flash_smc::@36 to flash_smc::@37 [phi:flash_smc::@36->flash_smc::@37]
    // flash_smc::@37
    // sprintf(info_text, "Press POWER and RESET on the CX16 within %u seconds!", smc_bootloader_activation_countdown)
    // [822] call printf_str
    // [471] phi from flash_smc::@37 to printf_str [phi:flash_smc::@37->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:flash_smc::@37->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = flash_smc::s2 [phi:flash_smc::@37->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@38
    // sprintf(info_text, "Press POWER and RESET on the CX16 within %u seconds!", smc_bootloader_activation_countdown)
    // [823] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [824] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [826] call info_line
    // [446] phi from flash_smc::@38 to info_line [phi:flash_smc::@38->info_line]
    // [446] phi info_line::info_text#16 = info_text [phi:flash_smc::@38->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    // flash_smc::@5
    // smc_bootloader_activation_countdown--;
    // [827] flash_smc::smc_bootloader_activation_countdown#2 = -- flash_smc::smc_bootloader_activation_countdown#22 -- vbuz1=_dec_vbuz1 
    dec.z smc_bootloader_activation_countdown
    // [690] phi from flash_smc::@5 to flash_smc::@3 [phi:flash_smc::@5->flash_smc::@3]
    // [690] phi flash_smc::smc_bootloader_activation_countdown#22 = flash_smc::smc_bootloader_activation_countdown#2 [phi:flash_smc::@5->flash_smc::@3#0] -- register_copy 
    jmp __b3
    // flash_smc::@7
  __b7:
    // for(unsigned long x=65536*6; x>0; x--)
    // [828] flash_smc::x1#1 = -- flash_smc::x1#2 -- vduz1=_dec_vduz1 
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
    // [813] phi from flash_smc::@7 to flash_smc::@6 [phi:flash_smc::@7->flash_smc::@6]
    // [813] phi flash_smc::x1#2 = flash_smc::x1#1 [phi:flash_smc::@7->flash_smc::@6#0] -- register_copy 
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
    cx16_k_i2c_write_byte5_device: .byte 0
    cx16_k_i2c_write_byte5_offset: .byte 0
    cx16_k_i2c_write_byte5_value: .byte 0
    cx16_k_i2c_write_byte5_result: .byte 0
    .label smc_package_committed = wait_key.bank_get_brom1_return
}
.segment Code
  // info_rom
// void info_rom(__zp($7a) char rom_chip, __zp($4a) char info_status, __zp($7c) char *info_text)
info_rom: {
    .label info_rom__4 = $4a
    .label info_rom__6 = $61
    .label rom_chip = $7a
    .label info_status = $4a
    .label info_text = $7c
    // print_rom_led(rom_chip, status_color[info_status])
    // [830] print_rom_led::chip#1 = info_rom::rom_chip#12 -- vbuz1=vbuz2 
    lda.z rom_chip
    sta.z print_rom_led.chip
    // [831] print_rom_led::c#1 = status_color[info_rom::info_status#12] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z print_rom_led.c
    // [832] call print_rom_led
    // [1410] phi from info_rom to print_rom_led [phi:info_rom->print_rom_led]
    // [1410] phi print_rom_led::c#2 = print_rom_led::c#1 [phi:info_rom->print_rom_led#0] -- register_copy 
    // [1410] phi print_rom_led::chip#2 = print_rom_led::chip#1 [phi:info_rom->print_rom_led#1] -- register_copy 
    jsr print_rom_led
    // info_rom::@1
    // info_clear(2+rom_chip)
    // [833] info_clear::l#3 = 2 + info_rom::rom_chip#12 -- vbuz1=vbuc1_plus_vbuz2 
    lda #2
    clc
    adc.z rom_chip
    sta.z info_clear.l
    // [834] call info_clear
    // [1258] phi from info_rom::@1 to info_clear [phi:info_rom::@1->info_clear]
    // [1258] phi info_clear::l#4 = info_clear::l#3 [phi:info_rom::@1->info_clear#0] -- register_copy 
    jsr info_clear
    // [835] phi from info_rom::@1 to info_rom::@2 [phi:info_rom::@1->info_rom::@2]
    // info_rom::@2
    // printf("ROM%u - %-8s - %-5s - %-3s - %s", rom_chip, status_text[info_status], rom_device_names[rom_chip], rom_size_strings[rom_chip], info_text )
    // [836] call printf_str
    // [471] phi from info_rom::@2 to printf_str [phi:info_rom::@2->printf_str]
    // [471] phi printf_str::putc#52 = &cputc [phi:info_rom::@2->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = info_rom::s [phi:info_rom::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@3
    // printf("ROM%u - %-8s - %-5s - %-3s - %s", rom_chip, status_text[info_status], rom_device_names[rom_chip], rom_size_strings[rom_chip], info_text )
    // [837] printf_uchar::uvalue#0 = info_rom::rom_chip#12 -- vbuz1=vbuz2 
    lda.z rom_chip
    sta.z printf_uchar.uvalue
    // [838] call printf_uchar
    // [1387] phi from info_rom::@3 to printf_uchar [phi:info_rom::@3->printf_uchar]
    // [1387] phi printf_uchar::format_zero_padding#10 = 0 [phi:info_rom::@3->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1387] phi printf_uchar::format_min_length#10 = 0 [phi:info_rom::@3->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1387] phi printf_uchar::putc#10 = &cputc [phi:info_rom::@3->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1387] phi printf_uchar::format_radix#10 = DECIMAL [phi:info_rom::@3->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1387] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#0 [phi:info_rom::@3->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [839] phi from info_rom::@3 to info_rom::@4 [phi:info_rom::@3->info_rom::@4]
    // info_rom::@4
    // printf("ROM%u - %-8s - %-5s - %-3s - %s", rom_chip, status_text[info_status], rom_device_names[rom_chip], rom_size_strings[rom_chip], info_text )
    // [840] call printf_str
    // [471] phi from info_rom::@4 to printf_str [phi:info_rom::@4->printf_str]
    // [471] phi printf_str::putc#52 = &cputc [phi:info_rom::@4->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = s1 [phi:info_rom::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@5
    // printf("ROM%u - %-8s - %-5s - %-3s - %s", rom_chip, status_text[info_status], rom_device_names[rom_chip], rom_size_strings[rom_chip], info_text )
    // [841] info_rom::$4 = info_rom::info_status#12 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z info_rom__4
    // [842] printf_string::str#6 = status_text[info_rom::$4] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z info_rom__4
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [843] call printf_string
    // [866] phi from info_rom::@5 to printf_string [phi:info_rom::@5->printf_string]
    // [866] phi printf_string::putc#15 = &cputc [phi:info_rom::@5->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [866] phi printf_string::str#15 = printf_string::str#6 [phi:info_rom::@5->printf_string#1] -- register_copy 
    // [866] phi printf_string::format_justify_left#15 = 1 [phi:info_rom::@5->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [866] phi printf_string::format_min_length#15 = 8 [phi:info_rom::@5->printf_string#3] -- vbuz1=vbuc1 
    lda #8
    sta.z printf_string.format_min_length
    jsr printf_string
    // [844] phi from info_rom::@5 to info_rom::@6 [phi:info_rom::@5->info_rom::@6]
    // info_rom::@6
    // printf("ROM%u - %-8s - %-5s - %-3s - %s", rom_chip, status_text[info_status], rom_device_names[rom_chip], rom_size_strings[rom_chip], info_text )
    // [845] call printf_str
    // [471] phi from info_rom::@6 to printf_str [phi:info_rom::@6->printf_str]
    // [471] phi printf_str::putc#52 = &cputc [phi:info_rom::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = s1 [phi:info_rom::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@7
    // printf("ROM%u - %-8s - %-5s - %-3s - %s", rom_chip, status_text[info_status], rom_device_names[rom_chip], rom_size_strings[rom_chip], info_text )
    // [846] info_rom::$6 = info_rom::rom_chip#12 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta.z info_rom__6
    // [847] printf_string::str#7 = rom_device_names[info_rom::$6] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda rom_device_names,y
    sta.z printf_string.str
    lda rom_device_names+1,y
    sta.z printf_string.str+1
    // [848] call printf_string
    // [866] phi from info_rom::@7 to printf_string [phi:info_rom::@7->printf_string]
    // [866] phi printf_string::putc#15 = &cputc [phi:info_rom::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [866] phi printf_string::str#15 = printf_string::str#7 [phi:info_rom::@7->printf_string#1] -- register_copy 
    // [866] phi printf_string::format_justify_left#15 = 1 [phi:info_rom::@7->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [866] phi printf_string::format_min_length#15 = 5 [phi:info_rom::@7->printf_string#3] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_string.format_min_length
    jsr printf_string
    // [849] phi from info_rom::@7 to info_rom::@8 [phi:info_rom::@7->info_rom::@8]
    // info_rom::@8
    // printf("ROM%u - %-8s - %-5s - %-3s - %s", rom_chip, status_text[info_status], rom_device_names[rom_chip], rom_size_strings[rom_chip], info_text )
    // [850] call printf_str
    // [471] phi from info_rom::@8 to printf_str [phi:info_rom::@8->printf_str]
    // [471] phi printf_str::putc#52 = &cputc [phi:info_rom::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = s1 [phi:info_rom::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@9
    // printf("ROM%u - %-8s - %-5s - %-3s - %s", rom_chip, status_text[info_status], rom_device_names[rom_chip], rom_size_strings[rom_chip], info_text )
    // [851] printf_string::str#8 = rom_size_strings[info_rom::$6] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z info_rom__6
    lda rom_size_strings,y
    sta.z printf_string.str
    lda rom_size_strings+1,y
    sta.z printf_string.str+1
    // [852] call printf_string
    // [866] phi from info_rom::@9 to printf_string [phi:info_rom::@9->printf_string]
    // [866] phi printf_string::putc#15 = &cputc [phi:info_rom::@9->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [866] phi printf_string::str#15 = printf_string::str#8 [phi:info_rom::@9->printf_string#1] -- register_copy 
    // [866] phi printf_string::format_justify_left#15 = 1 [phi:info_rom::@9->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [866] phi printf_string::format_min_length#15 = 3 [phi:info_rom::@9->printf_string#3] -- vbuz1=vbuc1 
    lda #3
    sta.z printf_string.format_min_length
    jsr printf_string
    // [853] phi from info_rom::@9 to info_rom::@10 [phi:info_rom::@9->info_rom::@10]
    // info_rom::@10
    // printf("ROM%u - %-8s - %-5s - %-3s - %s", rom_chip, status_text[info_status], rom_device_names[rom_chip], rom_size_strings[rom_chip], info_text )
    // [854] call printf_str
    // [471] phi from info_rom::@10 to printf_str [phi:info_rom::@10->printf_str]
    // [471] phi printf_str::putc#52 = &cputc [phi:info_rom::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = s1 [phi:info_rom::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@11
    // printf("ROM%u - %-8s - %-5s - %-3s - %s", rom_chip, status_text[info_status], rom_device_names[rom_chip], rom_size_strings[rom_chip], info_text )
    // [855] printf_string::str#9 = info_rom::info_text#12 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [856] call printf_string
    // [866] phi from info_rom::@11 to printf_string [phi:info_rom::@11->printf_string]
    // [866] phi printf_string::putc#15 = &cputc [phi:info_rom::@11->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [866] phi printf_string::str#15 = printf_string::str#9 [phi:info_rom::@11->printf_string#1] -- register_copy 
    // [866] phi printf_string::format_justify_left#15 = 0 [phi:info_rom::@11->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [866] phi printf_string::format_min_length#15 = 0 [phi:info_rom::@11->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_rom::@return
    // }
    // [857] return 
    rts
  .segment Data
    s: .text "ROM"
    .byte 0
}
.segment Code
  // strcpy
// Copies the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcpy(char *destination, char *source)
strcpy: {
    .label src = $53
    .label dst = $4d
    // [859] phi from strcpy strcpy::@2 to strcpy::@1 [phi:strcpy/strcpy::@2->strcpy::@1]
    // [859] phi strcpy::dst#2 = strcpy::dst#0 [phi:strcpy/strcpy::@2->strcpy::@1#0] -- register_copy 
    // [859] phi strcpy::src#2 = strcpy::src#0 [phi:strcpy/strcpy::@2->strcpy::@1#1] -- register_copy 
    // strcpy::@1
  __b1:
    // while(*src)
    // [860] if(0!=*strcpy::src#2) goto strcpy::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcpy::@3
    // *dst = 0
    // [861] *strcpy::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcpy::@return
    // }
    // [862] return 
    rts
    // strcpy::@2
  __b2:
    // *dst++ = *src++
    // [863] *strcpy::dst#2 = *strcpy::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [864] strcpy::dst#1 = ++ strcpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [865] strcpy::src#1 = ++ strcpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    jmp __b1
}
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(__zp($62) void (*putc)(char), __zp($6e) char *str, __zp($5a) char format_min_length, __zp($5b) char format_justify_left)
printf_string: {
    .label printf_string__9 = $46
    .label len = $b7
    .label padding = $5a
    .label str = $6e
    .label format_min_length = $5a
    .label format_justify_left = $5b
    .label putc = $62
    // if(format.min_length)
    // [867] if(0==printf_string::format_min_length#15) goto printf_string::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b3
    // printf_string::@3
    // strlen(str)
    // [868] strlen::str#3 = printf_string::str#15 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [869] call strlen
    // [1591] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [1591] phi strlen::str#8 = strlen::str#3 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [870] strlen::return#10 = strlen::len#2
    // printf_string::@6
    // [871] printf_string::$9 = strlen::return#10
    // signed char len = (signed char)strlen(str)
    // [872] printf_string::len#0 = (signed char)printf_string::$9 -- vbsz1=_sbyte_vwuz2 
    lda.z printf_string__9
    sta.z len
    // padding = (signed char)format.min_length  - len
    // [873] printf_string::padding#1 = (signed char)printf_string::format_min_length#15 - printf_string::len#0 -- vbsz1=vbsz1_minus_vbsz2 
    lda.z padding
    sec
    sbc.z len
    sta.z padding
    // if(padding<0)
    // [874] if(printf_string::padding#1>=0) goto printf_string::@10 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [876] phi from printf_string printf_string::@6 to printf_string::@1 [phi:printf_string/printf_string::@6->printf_string::@1]
  __b3:
    // [876] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@6->printf_string::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [875] phi from printf_string::@6 to printf_string::@10 [phi:printf_string::@6->printf_string::@10]
    // printf_string::@10
    // [876] phi from printf_string::@10 to printf_string::@1 [phi:printf_string::@10->printf_string::@1]
    // [876] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@10->printf_string::@1#0] -- register_copy 
    // printf_string::@1
  __b1:
    // if(!format.justify_left && padding)
    // [877] if(0!=printf_string::format_justify_left#15) goto printf_string::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_justify_left
    bne __b2
    // printf_string::@8
    // [878] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b4
    jmp __b2
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [879] printf_padding::putc#3 = printf_string::putc#15 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [880] printf_padding::length#3 = (char)printf_string::padding#3 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [881] call printf_padding
    // [1597] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [1597] phi printf_padding::putc#7 = printf_padding::putc#3 [phi:printf_string::@4->printf_padding#0] -- register_copy 
    // [1597] phi printf_padding::pad#7 = ' ' [phi:printf_string::@4->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1597] phi printf_padding::length#6 = printf_padding::length#3 [phi:printf_string::@4->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [882] printf_str::putc#1 = printf_string::putc#15 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_str.putc
    lda.z putc+1
    sta.z printf_str.putc+1
    // [883] printf_str::s#2 = printf_string::str#15
    // [884] call printf_str
    // [471] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [471] phi printf_str::putc#52 = printf_str::putc#1 [phi:printf_string::@2->printf_str#0] -- register_copy 
    // [471] phi printf_str::s#52 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@7
    // if(format.justify_left && padding)
    // [885] if(0==printf_string::format_justify_left#15) goto printf_string::@return -- 0_eq_vbuz1_then_la1 
    lda.z format_justify_left
    beq __breturn
    // printf_string::@9
    // [886] if(0!=printf_string::padding#3) goto printf_string::@5 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b5
    rts
    // printf_string::@5
  __b5:
    // printf_padding(putc, ' ',(char)padding)
    // [887] printf_padding::putc#4 = printf_string::putc#15 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [888] printf_padding::length#4 = (char)printf_string::padding#3 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [889] call printf_padding
    // [1597] phi from printf_string::@5 to printf_padding [phi:printf_string::@5->printf_padding]
    // [1597] phi printf_padding::putc#7 = printf_padding::putc#4 [phi:printf_string::@5->printf_padding#0] -- register_copy 
    // [1597] phi printf_padding::pad#7 = ' ' [phi:printf_string::@5->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1597] phi printf_padding::length#6 = printf_padding::length#4 [phi:printf_string::@5->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@return
  __breturn:
    // }
    // [890] return 
    rts
}
  // rom_read
// __zp($df) unsigned long rom_read(__zp($d5) char rom_bank_start, __mem() unsigned long rom_size)
rom_read: {
    .const x = 2
    .label rom_read__7 = $d6
    .label rom_address = $e4
    .label fp = $76
    .label return = $df
    .label rom_package_read = $cd
    .label rom_bank_start = $d5
    .label ram_address = $b2
    .label rom_file_read = $df
    /// Holds the amount of bytes actually read in the memory to be flashed.
    .label rom_row_current = $ad
    .label y = $dc
    .label bram_bank = $d4
    // gotoxy(x, y)
    // [892] call gotoxy
    // [334] phi from rom_read to gotoxy [phi:rom_read->gotoxy]
    // [334] phi gotoxy::y#22 = $1f [phi:rom_read->gotoxy#0] -- vbuz1=vbuc1 
    lda #$1f
    sta.z gotoxy.y
    // [334] phi gotoxy::x#22 = rom_read::x [phi:rom_read->gotoxy#1] -- vbuz1=vbuc1 
    lda #x
    sta.z gotoxy.x
    jsr gotoxy
    // rom_read::@13
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [893] rom_address_from_bank::rom_bank#0 = rom_read::rom_bank_start#1 -- vbuz1=vbuz2 
    lda.z rom_bank_start
    sta.z rom_address_from_bank.rom_bank
    // [894] call rom_address_from_bank
    // [1605] phi from rom_read::@13 to rom_address_from_bank [phi:rom_read::@13->rom_address_from_bank]
    // [1605] phi rom_address_from_bank::rom_bank#2 = rom_address_from_bank::rom_bank#0 [phi:rom_read::@13->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [895] rom_address_from_bank::return#2 = rom_address_from_bank::return#0
    // rom_read::@14
    // [896] rom_read::rom_address#0 = rom_address_from_bank::return#2
    // FILE *fp = fopen(file, "r")
    // [897] call fopen
    // [1418] phi from rom_read::@14 to fopen [phi:rom_read::@14->fopen]
    // [1418] phi __errno#228 = __errno#10 [phi:rom_read::@14->fopen#0] -- register_copy 
    // [1418] phi fopen::pathtoken#0 = file [phi:rom_read::@14->fopen#1] -- pbuz1=pbuc1 
    lda #<file
    sta.z fopen.pathtoken
    lda #>file
    sta.z fopen.pathtoken+1
    jsr fopen
    // FILE *fp = fopen(file, "r")
    // [898] fopen::return#4 = fopen::return#2
    // rom_read::@15
    // [899] rom_read::fp#0 = fopen::return#4 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [900] if((struct $2 *)0==rom_read::fp#0) goto rom_read::@1 -- pssc1_eq_pssz1_then_la1 
    lda.z fp
    cmp #<0
    bne !+
    lda.z fp+1
    cmp #>0
    beq __b9
  !:
    // [901] phi from rom_read::@15 to rom_read::@2 [phi:rom_read::@15->rom_read::@2]
    // [901] phi rom_read::y#10 = $1f [phi:rom_read::@15->rom_read::@2#0] -- vbuz1=vbuc1 
    lda #$1f
    sta.z y
    // [901] phi rom_read::rom_row_current#10 = 0 [phi:rom_read::@15->rom_read::@2#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z rom_row_current
    sta.z rom_row_current+1
    // [901] phi rom_read::rom_bank_start#10 = rom_read::rom_bank_start#1 [phi:rom_read::@15->rom_read::@2#2] -- register_copy 
    // [901] phi rom_read::rom_address#10 = rom_read::rom_address#0 [phi:rom_read::@15->rom_read::@2#3] -- register_copy 
    // [901] phi rom_read::ram_address#10 = (char *)$6000 [phi:rom_read::@15->rom_read::@2#4] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z ram_address
    lda #>$6000
    sta.z ram_address+1
    // [901] phi rom_read::bram_bank#10 = 0 [phi:rom_read::@15->rom_read::@2#5] -- vbuz1=vbuc1 
    lda #0
    sta.z bram_bank
    // [901] phi rom_read::rom_file_read#10 = 0 [phi:rom_read::@15->rom_read::@2#6] -- vduz1=vduc1 
    sta.z rom_file_read
    sta.z rom_file_read+1
    lda #<0>>$10
    sta.z rom_file_read+2
    lda #>0>>$10
    sta.z rom_file_read+3
    // rom_read::@2
  __b2:
    // while (rom_file_read < rom_size)
    // [902] if(rom_read::rom_file_read#10<rom_read::rom_size#0) goto rom_read::@3 -- vduz1_lt_vdum2_then_la1 
    lda.z rom_file_read+3
    cmp rom_size+3
    bcc __b3
    bne !+
    lda.z rom_file_read+2
    cmp rom_size+2
    bcc __b3
    bne !+
    lda.z rom_file_read+1
    cmp rom_size+1
    bcc __b3
    bne !+
    lda.z rom_file_read
    cmp rom_size
    bcc __b3
  !:
    // rom_read::@6
  __b6:
    // fclose(fp)
    // [903] fclose::stream#1 = rom_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fclose.stream
    lda.z fp+1
    sta.z fclose.stream+1
    // [904] call fclose
    // [1553] phi from rom_read::@6 to fclose [phi:rom_read::@6->fclose]
    // [1553] phi fclose::stream#2 = fclose::stream#1 [phi:rom_read::@6->fclose#0] -- register_copy 
    jsr fclose
    // [905] phi from rom_read::@6 to rom_read::@1 [phi:rom_read::@6->rom_read::@1]
    // [905] phi rom_read::return#0 = rom_read::rom_file_read#10 [phi:rom_read::@6->rom_read::@1#0] -- register_copy 
    rts
    // [905] phi from rom_read::@15 to rom_read::@1 [phi:rom_read::@15->rom_read::@1]
  __b9:
    // [905] phi rom_read::return#0 = 0 [phi:rom_read::@15->rom_read::@1#0] -- vduz1=vduc1 
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
    // [906] return 
    rts
    // [907] phi from rom_read::@2 to rom_read::@3 [phi:rom_read::@2->rom_read::@3]
    // rom_read::@3
  __b3:
    // sprintf(info_text, "Reading %s ROM %05x of %05x in RAM %02x:%04p ...", fp->filename, rom_file_read, rom_size, bram_bank, ram_address)
    // [908] call snprintf_init
    jsr snprintf_init
    // [909] phi from rom_read::@3 to rom_read::@16 [phi:rom_read::@3->rom_read::@16]
    // rom_read::@16
    // sprintf(info_text, "Reading %s ROM %05x of %05x in RAM %02x:%04p ...", fp->filename, rom_file_read, rom_size, bram_bank, ram_address)
    // [910] call printf_str
    // [471] phi from rom_read::@16 to printf_str [phi:rom_read::@16->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:rom_read::@16->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = rom_read::s [phi:rom_read::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@17
    // sprintf(info_text, "Reading %s ROM %05x of %05x in RAM %02x:%04p ...", fp->filename, rom_file_read, rom_size, bram_bank, ram_address)
    // [911] printf_string::str#10 = (char *)rom_read::fp#0 -- pbuz1=pbuz2 
    lda.z fp
    sta.z printf_string.str
    lda.z fp+1
    sta.z printf_string.str+1
    // [912] call printf_string
    // [866] phi from rom_read::@17 to printf_string [phi:rom_read::@17->printf_string]
    // [866] phi printf_string::putc#15 = &snputc [phi:rom_read::@17->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [866] phi printf_string::str#15 = printf_string::str#10 [phi:rom_read::@17->printf_string#1] -- register_copy 
    // [866] phi printf_string::format_justify_left#15 = 0 [phi:rom_read::@17->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [866] phi printf_string::format_min_length#15 = 0 [phi:rom_read::@17->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [913] phi from rom_read::@17 to rom_read::@18 [phi:rom_read::@17->rom_read::@18]
    // rom_read::@18
    // sprintf(info_text, "Reading %s ROM %05x of %05x in RAM %02x:%04p ...", fp->filename, rom_file_read, rom_size, bram_bank, ram_address)
    // [914] call printf_str
    // [471] phi from rom_read::@18 to printf_str [phi:rom_read::@18->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:rom_read::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = rom_read::s1 [phi:rom_read::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@19
    // sprintf(info_text, "Reading %s ROM %05x of %05x in RAM %02x:%04p ...", fp->filename, rom_file_read, rom_size, bram_bank, ram_address)
    // [915] printf_ulong::uvalue#0 = rom_read::rom_file_read#10 -- vduz1=vduz2 
    lda.z rom_file_read
    sta.z printf_ulong.uvalue
    lda.z rom_file_read+1
    sta.z printf_ulong.uvalue+1
    lda.z rom_file_read+2
    sta.z printf_ulong.uvalue+2
    lda.z rom_file_read+3
    sta.z printf_ulong.uvalue+3
    // [916] call printf_ulong
    // [963] phi from rom_read::@19 to printf_ulong [phi:rom_read::@19->printf_ulong]
    // [963] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#0 [phi:rom_read::@19->printf_ulong#0] -- register_copy 
    jsr printf_ulong
    // [917] phi from rom_read::@19 to rom_read::@20 [phi:rom_read::@19->rom_read::@20]
    // rom_read::@20
    // sprintf(info_text, "Reading %s ROM %05x of %05x in RAM %02x:%04p ...", fp->filename, rom_file_read, rom_size, bram_bank, ram_address)
    // [918] call printf_str
    // [471] phi from rom_read::@20 to printf_str [phi:rom_read::@20->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:rom_read::@20->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = s7 [phi:rom_read::@20->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@21
    // sprintf(info_text, "Reading %s ROM %05x of %05x in RAM %02x:%04p ...", fp->filename, rom_file_read, rom_size, bram_bank, ram_address)
    // [919] printf_ulong::uvalue#1 = rom_read::rom_size#0 -- vduz1=vdum2 
    lda rom_size
    sta.z printf_ulong.uvalue
    lda rom_size+1
    sta.z printf_ulong.uvalue+1
    lda rom_size+2
    sta.z printf_ulong.uvalue+2
    lda rom_size+3
    sta.z printf_ulong.uvalue+3
    // [920] call printf_ulong
    // [963] phi from rom_read::@21 to printf_ulong [phi:rom_read::@21->printf_ulong]
    // [963] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#1 [phi:rom_read::@21->printf_ulong#0] -- register_copy 
    jsr printf_ulong
    // [921] phi from rom_read::@21 to rom_read::@22 [phi:rom_read::@21->rom_read::@22]
    // rom_read::@22
    // sprintf(info_text, "Reading %s ROM %05x of %05x in RAM %02x:%04p ...", fp->filename, rom_file_read, rom_size, bram_bank, ram_address)
    // [922] call printf_str
    // [471] phi from rom_read::@22 to printf_str [phi:rom_read::@22->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:rom_read::@22->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = rom_read::s3 [phi:rom_read::@22->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@23
    // sprintf(info_text, "Reading %s ROM %05x of %05x in RAM %02x:%04p ...", fp->filename, rom_file_read, rom_size, bram_bank, ram_address)
    // [923] printf_uchar::uvalue#5 = rom_read::bram_bank#10 -- vbuz1=vbuz2 
    lda.z bram_bank
    sta.z printf_uchar.uvalue
    // [924] call printf_uchar
    // [1387] phi from rom_read::@23 to printf_uchar [phi:rom_read::@23->printf_uchar]
    // [1387] phi printf_uchar::format_zero_padding#10 = 1 [phi:rom_read::@23->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1387] phi printf_uchar::format_min_length#10 = 2 [phi:rom_read::@23->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [1387] phi printf_uchar::putc#10 = &snputc [phi:rom_read::@23->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1387] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:rom_read::@23->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [1387] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#5 [phi:rom_read::@23->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [925] phi from rom_read::@23 to rom_read::@24 [phi:rom_read::@23->rom_read::@24]
    // rom_read::@24
    // sprintf(info_text, "Reading %s ROM %05x of %05x in RAM %02x:%04p ...", fp->filename, rom_file_read, rom_size, bram_bank, ram_address)
    // [926] call printf_str
    // [471] phi from rom_read::@24 to printf_str [phi:rom_read::@24->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:rom_read::@24->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = s4 [phi:rom_read::@24->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@25
    // sprintf(info_text, "Reading %s ROM %05x of %05x in RAM %02x:%04p ...", fp->filename, rom_file_read, rom_size, bram_bank, ram_address)
    // [927] printf_uint::uvalue#5 = (unsigned int)rom_read::ram_address#10 -- vwuz1=vwuz2 
    lda.z ram_address
    sta.z printf_uint.uvalue
    lda.z ram_address+1
    sta.z printf_uint.uvalue+1
    // [928] call printf_uint
    // [480] phi from rom_read::@25 to printf_uint [phi:rom_read::@25->printf_uint]
    // [480] phi printf_uint::format_zero_padding#11 = 1 [phi:rom_read::@25->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [480] phi printf_uint::format_min_length#11 = 4 [phi:rom_read::@25->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [480] phi printf_uint::format_radix#11 = HEXADECIMAL [phi:rom_read::@25->printf_uint#2] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [480] phi printf_uint::uvalue#11 = printf_uint::uvalue#5 [phi:rom_read::@25->printf_uint#3] -- register_copy 
    jsr printf_uint
    // [929] phi from rom_read::@25 to rom_read::@26 [phi:rom_read::@25->rom_read::@26]
    // rom_read::@26
    // sprintf(info_text, "Reading %s ROM %05x of %05x in RAM %02x:%04p ...", fp->filename, rom_file_read, rom_size, bram_bank, ram_address)
    // [930] call printf_str
    // [471] phi from rom_read::@26 to printf_str [phi:rom_read::@26->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:rom_read::@26->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = rom_read::s5 [phi:rom_read::@26->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@27
    // sprintf(info_text, "Reading %s ROM %05x of %05x in RAM %02x:%04p ...", fp->filename, rom_file_read, rom_size, bram_bank, ram_address)
    // [931] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [932] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [934] call info_line
    // [446] phi from rom_read::@27 to info_line [phi:rom_read::@27->info_line]
    // [446] phi info_line::info_text#16 = info_text [phi:rom_read::@27->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    // rom_read::@28
    // rom_address % 0x04000
    // [935] rom_read::$7 = rom_read::rom_address#10 & $4000-1 -- vduz1=vduz2_band_vduc1 
    lda.z rom_address
    and #<$4000-1
    sta.z rom_read__7
    lda.z rom_address+1
    and #>$4000-1
    sta.z rom_read__7+1
    lda.z rom_address+2
    and #<$4000-1>>$10
    sta.z rom_read__7+2
    lda.z rom_address+3
    and #>$4000-1>>$10
    sta.z rom_read__7+3
    // if (!(rom_address % 0x04000))
    // [936] if(0!=rom_read::$7) goto rom_read::@4 -- 0_neq_vduz1_then_la1 
    lda.z rom_read__7
    ora.z rom_read__7+1
    ora.z rom_read__7+2
    ora.z rom_read__7+3
    bne __b4
    // rom_read::@9
    // rom_bank_start++;
    // [937] rom_read::rom_bank_start#0 = ++ rom_read::rom_bank_start#10 -- vbuz1=_inc_vbuz1 
    inc.z rom_bank_start
    // [938] phi from rom_read::@28 rom_read::@9 to rom_read::@4 [phi:rom_read::@28/rom_read::@9->rom_read::@4]
    // [938] phi rom_read::rom_bank_start#20 = rom_read::rom_bank_start#10 [phi:rom_read::@28/rom_read::@9->rom_read::@4#0] -- register_copy 
    // rom_read::@4
  __b4:
    // rom_read::bank_set_bram1
    // BRAM = bank
    // [939] BRAM = rom_read::bram_bank#10 -- vbuz1=vbuz2 
    lda.z bram_bank
    sta.z BRAM
    // rom_read::@12
    // unsigned int rom_package_read = fgets(ram_address, PROGRESS_CELL, fp)
    // [940] fgets::ptr#3 = rom_read::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z fgets.ptr
    lda.z ram_address+1
    sta.z fgets.ptr+1
    // [941] fgets::stream#1 = rom_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.stream
    lda.z fp+1
    sta.z fgets.stream+1
    // [942] call fgets
    // [1499] phi from rom_read::@12 to fgets [phi:rom_read::@12->fgets]
    // [1499] phi fgets::ptr#12 = fgets::ptr#3 [phi:rom_read::@12->fgets#0] -- register_copy 
    // [1499] phi fgets::size#10 = PROGRESS_CELL [phi:rom_read::@12->fgets#1] -- vwuz1=vwuc1 
    lda #<PROGRESS_CELL
    sta.z fgets.size
    lda #>PROGRESS_CELL
    sta.z fgets.size+1
    // [1499] phi fgets::stream#2 = fgets::stream#1 [phi:rom_read::@12->fgets#2] -- register_copy 
    jsr fgets
    // unsigned int rom_package_read = fgets(ram_address, PROGRESS_CELL, fp)
    // [943] fgets::return#6 = fgets::return#1
    // rom_read::@29
    // [944] rom_read::rom_package_read#0 = fgets::return#6 -- vwuz1=vwuz2 
    lda.z fgets.return
    sta.z rom_package_read
    lda.z fgets.return+1
    sta.z rom_package_read+1
    // if (!rom_package_read)
    // [945] if(0!=rom_read::rom_package_read#0) goto rom_read::@5 -- 0_neq_vwuz1_then_la1 
    lda.z rom_package_read
    ora.z rom_package_read+1
    bne __b5
    jmp __b6
    // rom_read::@5
  __b5:
    // if (rom_row_current == PROGRESS_ROW)
    // [946] if(rom_read::rom_row_current#10!=PROGRESS_ROW) goto rom_read::@7 -- vwuz1_neq_vwuc1_then_la1 
    lda.z rom_row_current+1
    cmp #>PROGRESS_ROW
    bne __b7
    lda.z rom_row_current
    cmp #<PROGRESS_ROW
    bne __b7
    // rom_read::@10
    // gotoxy(x, ++y);
    // [947] rom_read::y#1 = ++ rom_read::y#10 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [948] gotoxy::y#19 = rom_read::y#1 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [949] call gotoxy
    // [334] phi from rom_read::@10 to gotoxy [phi:rom_read::@10->gotoxy]
    // [334] phi gotoxy::y#22 = gotoxy::y#19 [phi:rom_read::@10->gotoxy#0] -- register_copy 
    // [334] phi gotoxy::x#22 = rom_read::x [phi:rom_read::@10->gotoxy#1] -- vbuz1=vbuc1 
    lda #x
    sta.z gotoxy.x
    jsr gotoxy
    // [950] phi from rom_read::@10 to rom_read::@7 [phi:rom_read::@10->rom_read::@7]
    // [950] phi rom_read::y#24 = rom_read::y#1 [phi:rom_read::@10->rom_read::@7#0] -- register_copy 
    // [950] phi rom_read::rom_row_current#4 = 0 [phi:rom_read::@10->rom_read::@7#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z rom_row_current
    sta.z rom_row_current+1
    // [950] phi from rom_read::@5 to rom_read::@7 [phi:rom_read::@5->rom_read::@7]
    // [950] phi rom_read::y#24 = rom_read::y#10 [phi:rom_read::@5->rom_read::@7#0] -- register_copy 
    // [950] phi rom_read::rom_row_current#4 = rom_read::rom_row_current#10 [phi:rom_read::@5->rom_read::@7#1] -- register_copy 
    // rom_read::@7
  __b7:
    // cputc('.')
    // [951] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [952] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // ram_address += rom_package_read
    // [954] rom_read::ram_address#1 = rom_read::ram_address#10 + rom_read::rom_package_read#0 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z ram_address
    adc.z rom_package_read
    sta.z ram_address
    lda.z ram_address+1
    adc.z rom_package_read+1
    sta.z ram_address+1
    // rom_address += rom_package_read
    // [955] rom_read::rom_address#1 = rom_read::rom_address#10 + rom_read::rom_package_read#0 -- vduz1=vduz1_plus_vwuz2 
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
    // [956] rom_read::rom_file_read#1 = rom_read::rom_file_read#10 + rom_read::rom_package_read#0 -- vduz1=vduz1_plus_vwuz2 
    lda.z rom_file_read
    clc
    adc.z rom_package_read
    sta.z rom_file_read
    lda.z rom_file_read+1
    adc.z rom_package_read+1
    sta.z rom_file_read+1
    lda.z rom_file_read+2
    adc #0
    sta.z rom_file_read+2
    lda.z rom_file_read+3
    adc #0
    sta.z rom_file_read+3
    // rom_row_current += rom_package_read
    // [957] rom_read::rom_row_current#1 = rom_read::rom_row_current#4 + rom_read::rom_package_read#0 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z rom_row_current
    adc.z rom_package_read
    sta.z rom_row_current
    lda.z rom_row_current+1
    adc.z rom_package_read+1
    sta.z rom_row_current+1
    // if (ram_address == (ram_ptr_t)BRAM_HIGH)
    // [958] if(rom_read::ram_address#1!=(char *)$c000) goto rom_read::@8 -- pbuz1_neq_pbuc1_then_la1 
    lda.z ram_address+1
    cmp #>$c000
    bne __b8
    lda.z ram_address
    cmp #<$c000
    bne __b8
    // rom_read::@11
    // bram_bank++;
    // [959] rom_read::bram_bank#1 = ++ rom_read::bram_bank#10 -- vbuz1=_inc_vbuz1 
    inc.z bram_bank
    // [960] phi from rom_read::@11 to rom_read::@8 [phi:rom_read::@11->rom_read::@8]
    // [960] phi rom_read::bram_bank#29 = rom_read::bram_bank#1 [phi:rom_read::@11->rom_read::@8#0] -- register_copy 
    // [960] phi rom_read::ram_address#7 = (char *)$a000 [phi:rom_read::@11->rom_read::@8#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [960] phi from rom_read::@7 to rom_read::@8 [phi:rom_read::@7->rom_read::@8]
    // [960] phi rom_read::bram_bank#29 = rom_read::bram_bank#10 [phi:rom_read::@7->rom_read::@8#0] -- register_copy 
    // [960] phi rom_read::ram_address#7 = rom_read::ram_address#1 [phi:rom_read::@7->rom_read::@8#1] -- register_copy 
    // rom_read::@8
  __b8:
    // if (ram_address == (ram_ptr_t)RAM_HIGH)
    // [961] if(rom_read::ram_address#7!=(char *)$8000) goto rom_read::@30 -- pbuz1_neq_pbuc1_then_la1 
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
    // [901] phi from rom_read::@8 to rom_read::@2 [phi:rom_read::@8->rom_read::@2]
    // [901] phi rom_read::y#10 = rom_read::y#24 [phi:rom_read::@8->rom_read::@2#0] -- register_copy 
    // [901] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#1 [phi:rom_read::@8->rom_read::@2#1] -- register_copy 
    // [901] phi rom_read::rom_bank_start#10 = rom_read::rom_bank_start#20 [phi:rom_read::@8->rom_read::@2#2] -- register_copy 
    // [901] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@8->rom_read::@2#3] -- register_copy 
    // [901] phi rom_read::ram_address#10 = (char *)$a000 [phi:rom_read::@8->rom_read::@2#4] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [901] phi rom_read::bram_bank#10 = 1 [phi:rom_read::@8->rom_read::@2#5] -- vbuz1=vbuc1 
    lda #1
    sta.z bram_bank
    // [901] phi rom_read::rom_file_read#10 = rom_read::rom_file_read#1 [phi:rom_read::@8->rom_read::@2#6] -- register_copy 
    jmp __b2
    // [962] phi from rom_read::@8 to rom_read::@30 [phi:rom_read::@8->rom_read::@30]
    // rom_read::@30
    // [901] phi from rom_read::@30 to rom_read::@2 [phi:rom_read::@30->rom_read::@2]
    // [901] phi rom_read::y#10 = rom_read::y#24 [phi:rom_read::@30->rom_read::@2#0] -- register_copy 
    // [901] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#1 [phi:rom_read::@30->rom_read::@2#1] -- register_copy 
    // [901] phi rom_read::rom_bank_start#10 = rom_read::rom_bank_start#20 [phi:rom_read::@30->rom_read::@2#2] -- register_copy 
    // [901] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@30->rom_read::@2#3] -- register_copy 
    // [901] phi rom_read::ram_address#10 = rom_read::ram_address#7 [phi:rom_read::@30->rom_read::@2#4] -- register_copy 
    // [901] phi rom_read::bram_bank#10 = rom_read::bram_bank#29 [phi:rom_read::@30->rom_read::@2#5] -- register_copy 
    // [901] phi rom_read::rom_file_read#10 = rom_read::rom_file_read#1 [phi:rom_read::@30->rom_read::@2#6] -- register_copy 
  .segment Data
    s: .text "Reading "
    .byte 0
    s1: .text " ROM "
    .byte 0
    s3: .text " in RAM "
    .byte 0
    s5: .text " ..."
    .byte 0
    rom_size: .dword 0
}
.segment Code
  // printf_ulong
// Print an unsigned int using a specific format
// void printf_ulong(void (*putc)(char), __zp($25) unsigned long uvalue, char format_min_length, char format_justify_left, char format_sign_always, char format_zero_padding, char format_upper_case, char format_radix)
printf_ulong: {
    .label uvalue = $25
    // printf_ulong::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [964] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // ultoa(uvalue, printf_buffer.digits, format.radix)
    // [965] ultoa::value#1 = printf_ulong::uvalue#10
    // [966] call ultoa
  // Format number into buffer
    // [1609] phi from printf_ulong::@1 to ultoa [phi:printf_ulong::@1->ultoa]
    jsr ultoa
    // printf_ulong::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [967] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [968] call printf_number_buffer
  // Print using format
    // [1352] phi from printf_ulong::@2 to printf_number_buffer [phi:printf_ulong::@2->printf_number_buffer]
    // [1352] phi printf_number_buffer::putc#10 = &snputc [phi:printf_ulong::@2->printf_number_buffer#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_number_buffer.putc
    lda #>snputc
    sta.z printf_number_buffer.putc+1
    // [1352] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_ulong::@2->printf_number_buffer#1] -- register_copy 
    // [1352] phi printf_number_buffer::format_zero_padding#10 = 1 [phi:printf_ulong::@2->printf_number_buffer#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_number_buffer.format_zero_padding
    // [1352] phi printf_number_buffer::format_min_length#3 = 5 [phi:printf_ulong::@2->printf_number_buffer#3] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_number_buffer.format_min_length
    jsr printf_number_buffer
    // printf_ulong::@return
    // }
    // [969] return 
    rts
  .segment Data
    .label uvalue_1 = main.rom_file_modulo
}
.segment Code
  // rom_verify
// __mem() unsigned long rom_verify(__mem() char rom_chip, __zp($cc) char rom_bank_start, __mem() unsigned long file_size)
rom_verify: {
    .const x = 2
    .label rom_address = $d6
    .label difference_bytes = $43
    .label y = $c5
    .label ram_address = $7e
    .label bram_bank = $ba
    .label rom_bank_start = $cc
    .label progress_row_current = $4f
    // info_line("Comparing with existing ROM ... (.) same, (*) different.")
    // [971] call info_line
  // Now we compare the RAM with the actual ROM contents.
    // [446] phi from rom_verify to info_line [phi:rom_verify->info_line]
    // [446] phi info_line::info_text#16 = rom_verify::info_text [phi:rom_verify->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    // rom_verify::@12
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [972] rom_address_from_bank::rom_bank#1 = rom_verify::rom_bank_start#0
    // [973] call rom_address_from_bank
    // [1605] phi from rom_verify::@12 to rom_address_from_bank [phi:rom_verify::@12->rom_address_from_bank]
    // [1605] phi rom_address_from_bank::rom_bank#2 = rom_address_from_bank::rom_bank#1 [phi:rom_verify::@12->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [974] rom_address_from_bank::return#3 = rom_address_from_bank::return#0 -- vduz1=vduz2 
    lda.z rom_address_from_bank.return
    sta.z rom_address_from_bank.return_1
    lda.z rom_address_from_bank.return+1
    sta.z rom_address_from_bank.return_1+1
    lda.z rom_address_from_bank.return+2
    sta.z rom_address_from_bank.return_1+2
    lda.z rom_address_from_bank.return+3
    sta.z rom_address_from_bank.return_1+3
    // rom_verify::@13
    // [975] rom_verify::rom_address#0 = rom_address_from_bank::return#3
    // unsigned long rom_boundary = rom_address + file_size
    // [976] rom_verify::rom_boundary#0 = rom_verify::rom_address#0 + rom_verify::file_size#0 -- vdum1=vduz2_plus_vdum3 
    lda.z rom_address
    clc
    adc file_size
    sta rom_boundary
    lda.z rom_address+1
    adc file_size+1
    sta rom_boundary+1
    lda.z rom_address+2
    adc file_size+2
    sta rom_boundary+2
    lda.z rom_address+3
    adc file_size+3
    sta rom_boundary+3
    // info_rom(rom_chip, STATUS_COMPARING, "Comparing ...")
    // [977] info_rom::rom_chip#0 = rom_verify::rom_chip#0 -- vbuz1=vbum2 
    lda rom_chip
    sta.z info_rom.rom_chip
    // [978] call info_rom
    // [829] phi from rom_verify::@13 to info_rom [phi:rom_verify::@13->info_rom]
    // [829] phi info_rom::info_text#12 = rom_verify::info_text1 [phi:rom_verify::@13->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z info_rom.info_text
    lda #>info_text1
    sta.z info_rom.info_text+1
    // [829] phi info_rom::info_status#12 = 4 [phi:rom_verify::@13->info_rom#1] -- vbuz1=vbuc1 
    lda #4
    sta.z info_rom.info_status
    // [829] phi info_rom::rom_chip#12 = info_rom::rom_chip#0 [phi:rom_verify::@13->info_rom#2] -- register_copy 
    jsr info_rom
    // [979] phi from rom_verify::@13 to rom_verify::@14 [phi:rom_verify::@13->rom_verify::@14]
    // rom_verify::@14
    // gotoxy(x, y)
    // [980] call gotoxy
    // [334] phi from rom_verify::@14 to gotoxy [phi:rom_verify::@14->gotoxy]
    // [334] phi gotoxy::y#22 = $1f [phi:rom_verify::@14->gotoxy#0] -- vbuz1=vbuc1 
    lda #$1f
    sta.z gotoxy.y
    // [334] phi gotoxy::x#22 = rom_verify::x [phi:rom_verify::@14->gotoxy#1] -- vbuz1=vbuc1 
    lda #x
    sta.z gotoxy.x
    jsr gotoxy
    // [981] phi from rom_verify::@14 to rom_verify::@1 [phi:rom_verify::@14->rom_verify::@1]
    // [981] phi rom_verify::y#3 = $1f [phi:rom_verify::@14->rom_verify::@1#0] -- vbuz1=vbuc1 
    lda #$1f
    sta.z y
    // [981] phi rom_verify::rom_difference_bytes#10 = 0 [phi:rom_verify::@14->rom_verify::@1#1] -- vdum1=vduc1 
    lda #<0
    sta rom_difference_bytes
    sta rom_difference_bytes+1
    lda #<0>>$10
    sta rom_difference_bytes+2
    lda #>0>>$10
    sta rom_difference_bytes+3
    // [981] phi rom_verify::progress_row_current#3 = 0 [phi:rom_verify::@14->rom_verify::@1#2] -- vwuz1=vwuc1 
    lda #<0
    sta.z progress_row_current
    sta.z progress_row_current+1
    // [981] phi rom_verify::ram_address#10 = (char *)$6000 [phi:rom_verify::@14->rom_verify::@1#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z ram_address
    lda #>$6000
    sta.z ram_address+1
    // [981] phi rom_verify::bram_bank#11 = 0 [phi:rom_verify::@14->rom_verify::@1#4] -- vbuz1=vbuc1 
    lda #0
    sta.z bram_bank
    // [981] phi rom_verify::rom_address#12 = rom_verify::rom_address#0 [phi:rom_verify::@14->rom_verify::@1#5] -- register_copy 
    // rom_verify::@1
  __b1:
    // while (rom_address < rom_boundary)
    // [982] if(rom_verify::rom_address#12<rom_verify::rom_boundary#0) goto rom_verify::@2 -- vduz1_lt_vdum2_then_la1 
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
    // info_rom(rom_chip, STATUS_COMPARED, "Compared.")
    // [983] info_rom::rom_chip#1 = rom_verify::rom_chip#0 -- vbuz1=vbum2 
    lda rom_chip
    sta.z info_rom.rom_chip
    // [984] call info_rom
    // [829] phi from rom_verify::@3 to info_rom [phi:rom_verify::@3->info_rom]
    // [829] phi info_rom::info_text#12 = rom_verify::info_text2 [phi:rom_verify::@3->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z info_rom.info_text
    lda #>info_text2
    sta.z info_rom.info_text+1
    // [829] phi info_rom::info_status#12 = 5 [phi:rom_verify::@3->info_rom#1] -- vbuz1=vbuc1 
    lda #5
    sta.z info_rom.info_status
    // [829] phi info_rom::rom_chip#12 = info_rom::rom_chip#1 [phi:rom_verify::@3->info_rom#2] -- register_copy 
    jsr info_rom
    // rom_verify::@return
    // }
    // [985] return 
    rts
    // rom_verify::@2
  __b2:
    // unsigned int difference_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [986] rom_compare::bank_ram#0 = rom_verify::bram_bank#11 -- vbuz1=vbuz2 
    lda.z bram_bank
    sta.z rom_compare.bank_ram
    // [987] rom_compare::ptr_ram#1 = rom_verify::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_compare.ptr_ram
    lda.z ram_address+1
    sta.z rom_compare.ptr_ram+1
    // [988] rom_compare::rom_compare_address#0 = rom_verify::rom_address#12 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_compare.rom_compare_address
    lda.z rom_address+1
    sta.z rom_compare.rom_compare_address+1
    lda.z rom_address+2
    sta.z rom_compare.rom_compare_address+2
    lda.z rom_address+3
    sta.z rom_compare.rom_compare_address+3
    // [989] call rom_compare
  // {asm{.byte $db}}
    // [1630] phi from rom_verify::@2 to rom_compare [phi:rom_verify::@2->rom_compare]
    jsr rom_compare
    // unsigned int difference_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [990] rom_compare::return#2 = rom_compare::difference_bytes#2
    // rom_verify::@15
    // [991] rom_verify::difference_bytes#0 = rom_compare::return#2
    // if (progress_row_current == PROGRESS_ROW)
    // [992] if(rom_verify::progress_row_current#3!=PROGRESS_ROW) goto rom_verify::@4 -- vwuz1_neq_vwuc1_then_la1 
    lda.z progress_row_current+1
    cmp #>PROGRESS_ROW
    bne __b4
    lda.z progress_row_current
    cmp #<PROGRESS_ROW
    bne __b4
    // rom_verify::@9
    // gotoxy(x, ++y);
    // [993] rom_verify::y#1 = ++ rom_verify::y#3 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [994] gotoxy::y#21 = rom_verify::y#1 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [995] call gotoxy
    // [334] phi from rom_verify::@9 to gotoxy [phi:rom_verify::@9->gotoxy]
    // [334] phi gotoxy::y#22 = gotoxy::y#21 [phi:rom_verify::@9->gotoxy#0] -- register_copy 
    // [334] phi gotoxy::x#22 = rom_verify::x [phi:rom_verify::@9->gotoxy#1] -- vbuz1=vbuc1 
    lda #x
    sta.z gotoxy.x
    jsr gotoxy
    // [996] phi from rom_verify::@9 to rom_verify::@4 [phi:rom_verify::@9->rom_verify::@4]
    // [996] phi rom_verify::y#10 = rom_verify::y#1 [phi:rom_verify::@9->rom_verify::@4#0] -- register_copy 
    // [996] phi rom_verify::progress_row_current#4 = 0 [phi:rom_verify::@9->rom_verify::@4#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z progress_row_current
    sta.z progress_row_current+1
    // [996] phi from rom_verify::@15 to rom_verify::@4 [phi:rom_verify::@15->rom_verify::@4]
    // [996] phi rom_verify::y#10 = rom_verify::y#3 [phi:rom_verify::@15->rom_verify::@4#0] -- register_copy 
    // [996] phi rom_verify::progress_row_current#4 = rom_verify::progress_row_current#3 [phi:rom_verify::@15->rom_verify::@4#1] -- register_copy 
    // rom_verify::@4
  __b4:
    // if (difference_bytes)
    // [997] if(0!=rom_verify::difference_bytes#0) goto rom_verify::@5 -- 0_neq_vwuz1_then_la1 
    lda.z difference_bytes
    ora.z difference_bytes+1
    beq !__b5+
    jmp __b5
  !__b5:
    // rom_verify::@10
    // cputc('=')
    // [998] stackpush(char) = '=' -- _stackpushbyte_=vbuc1 
    lda #'='
    pha
    // [999] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_verify::@6
  __b6:
    // ram_address += PROGRESS_CELL
    // [1001] rom_verify::ram_address#1 = rom_verify::ram_address#10 + PROGRESS_CELL -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address
    clc
    adc #<PROGRESS_CELL
    sta.z ram_address
    lda.z ram_address+1
    adc #>PROGRESS_CELL
    sta.z ram_address+1
    // rom_address += PROGRESS_CELL
    // [1002] rom_verify::rom_address#1 = rom_verify::rom_address#12 + PROGRESS_CELL -- vduz1=vduz1_plus_vwuc1 
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
    // [1003] rom_verify::progress_row_current#11 = rom_verify::progress_row_current#4 + PROGRESS_CELL -- vwuz1=vwuz1_plus_vwuc1 
    lda.z progress_row_current
    clc
    adc #<PROGRESS_CELL
    sta.z progress_row_current
    lda.z progress_row_current+1
    adc #>PROGRESS_CELL
    sta.z progress_row_current+1
    // if (ram_address == BRAM_HIGH)
    // [1004] if(rom_verify::ram_address#1!=$c000) goto rom_verify::@7 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address+1
    cmp #>$c000
    bne __b7
    lda.z ram_address
    cmp #<$c000
    bne __b7
    // rom_verify::@11
    // bram_bank++;
    // [1005] rom_verify::bram_bank#1 = ++ rom_verify::bram_bank#11 -- vbuz1=_inc_vbuz1 
    inc.z bram_bank
    // [1006] phi from rom_verify::@11 to rom_verify::@7 [phi:rom_verify::@11->rom_verify::@7]
    // [1006] phi rom_verify::bram_bank#25 = rom_verify::bram_bank#1 [phi:rom_verify::@11->rom_verify::@7#0] -- register_copy 
    // [1006] phi rom_verify::ram_address#6 = (char *)$a000 [phi:rom_verify::@11->rom_verify::@7#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1006] phi from rom_verify::@6 to rom_verify::@7 [phi:rom_verify::@6->rom_verify::@7]
    // [1006] phi rom_verify::bram_bank#25 = rom_verify::bram_bank#11 [phi:rom_verify::@6->rom_verify::@7#0] -- register_copy 
    // [1006] phi rom_verify::ram_address#6 = rom_verify::ram_address#1 [phi:rom_verify::@6->rom_verify::@7#1] -- register_copy 
    // rom_verify::@7
  __b7:
    // if (ram_address == RAM_HIGH)
    // [1007] if(rom_verify::ram_address#6!=$8000) goto rom_verify::@25 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address+1
    cmp #>$8000
    bne __b8
    lda.z ram_address
    cmp #<$8000
    bne __b8
    // [1009] phi from rom_verify::@7 to rom_verify::@8 [phi:rom_verify::@7->rom_verify::@8]
    // [1009] phi rom_verify::ram_address#11 = (char *)$a000 [phi:rom_verify::@7->rom_verify::@8#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1009] phi rom_verify::bram_bank#10 = 1 [phi:rom_verify::@7->rom_verify::@8#1] -- vbuz1=vbuc1 
    lda #1
    sta.z bram_bank
    // [1008] phi from rom_verify::@7 to rom_verify::@25 [phi:rom_verify::@7->rom_verify::@25]
    // rom_verify::@25
    // [1009] phi from rom_verify::@25 to rom_verify::@8 [phi:rom_verify::@25->rom_verify::@8]
    // [1009] phi rom_verify::ram_address#11 = rom_verify::ram_address#6 [phi:rom_verify::@25->rom_verify::@8#0] -- register_copy 
    // [1009] phi rom_verify::bram_bank#10 = rom_verify::bram_bank#25 [phi:rom_verify::@25->rom_verify::@8#1] -- register_copy 
    // rom_verify::@8
  __b8:
    // rom_difference_bytes += difference_bytes
    // [1010] rom_verify::rom_difference_bytes#1 = rom_verify::rom_difference_bytes#10 + rom_verify::difference_bytes#0 -- vdum1=vdum1_plus_vwuz2 
    lda rom_difference_bytes
    clc
    adc.z difference_bytes
    sta rom_difference_bytes
    lda rom_difference_bytes+1
    adc.z difference_bytes+1
    sta rom_difference_bytes+1
    lda rom_difference_bytes+2
    adc #0
    sta rom_difference_bytes+2
    lda rom_difference_bytes+3
    adc #0
    sta rom_difference_bytes+3
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_difference_bytes, bram_bank, ram_address, rom_address)
    // [1011] call snprintf_init
    jsr snprintf_init
    // [1012] phi from rom_verify::@8 to rom_verify::@16 [phi:rom_verify::@8->rom_verify::@16]
    // rom_verify::@16
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_difference_bytes, bram_bank, ram_address, rom_address)
    // [1013] call printf_str
    // [471] phi from rom_verify::@16 to printf_str [phi:rom_verify::@16->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:rom_verify::@16->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = rom_verify::s [phi:rom_verify::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@17
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_difference_bytes, bram_bank, ram_address, rom_address)
    // [1014] printf_ulong::uvalue#2 = rom_verify::rom_difference_bytes#1 -- vduz1=vdum2 
    lda rom_difference_bytes
    sta.z printf_ulong.uvalue
    lda rom_difference_bytes+1
    sta.z printf_ulong.uvalue+1
    lda rom_difference_bytes+2
    sta.z printf_ulong.uvalue+2
    lda rom_difference_bytes+3
    sta.z printf_ulong.uvalue+3
    // [1015] call printf_ulong
    // [963] phi from rom_verify::@17 to printf_ulong [phi:rom_verify::@17->printf_ulong]
    // [963] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#2 [phi:rom_verify::@17->printf_ulong#0] -- register_copy 
    jsr printf_ulong
    // [1016] phi from rom_verify::@17 to rom_verify::@18 [phi:rom_verify::@17->rom_verify::@18]
    // rom_verify::@18
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_difference_bytes, bram_bank, ram_address, rom_address)
    // [1017] call printf_str
    // [471] phi from rom_verify::@18 to printf_str [phi:rom_verify::@18->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:rom_verify::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = rom_verify::s1 [phi:rom_verify::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@19
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_difference_bytes, bram_bank, ram_address, rom_address)
    // [1018] printf_uchar::uvalue#6 = rom_verify::bram_bank#10 -- vbuz1=vbuz2 
    lda.z bram_bank
    sta.z printf_uchar.uvalue
    // [1019] call printf_uchar
    // [1387] phi from rom_verify::@19 to printf_uchar [phi:rom_verify::@19->printf_uchar]
    // [1387] phi printf_uchar::format_zero_padding#10 = 1 [phi:rom_verify::@19->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1387] phi printf_uchar::format_min_length#10 = 2 [phi:rom_verify::@19->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [1387] phi printf_uchar::putc#10 = &snputc [phi:rom_verify::@19->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1387] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:rom_verify::@19->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [1387] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#6 [phi:rom_verify::@19->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1020] phi from rom_verify::@19 to rom_verify::@20 [phi:rom_verify::@19->rom_verify::@20]
    // rom_verify::@20
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_difference_bytes, bram_bank, ram_address, rom_address)
    // [1021] call printf_str
    // [471] phi from rom_verify::@20 to printf_str [phi:rom_verify::@20->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:rom_verify::@20->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = s4 [phi:rom_verify::@20->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@21
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_difference_bytes, bram_bank, ram_address, rom_address)
    // [1022] printf_uint::uvalue#6 = (unsigned int)rom_verify::ram_address#11 -- vwuz1=vwuz2 
    lda.z ram_address
    sta.z printf_uint.uvalue
    lda.z ram_address+1
    sta.z printf_uint.uvalue+1
    // [1023] call printf_uint
    // [480] phi from rom_verify::@21 to printf_uint [phi:rom_verify::@21->printf_uint]
    // [480] phi printf_uint::format_zero_padding#11 = 1 [phi:rom_verify::@21->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [480] phi printf_uint::format_min_length#11 = 4 [phi:rom_verify::@21->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [480] phi printf_uint::format_radix#11 = HEXADECIMAL [phi:rom_verify::@21->printf_uint#2] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [480] phi printf_uint::uvalue#11 = printf_uint::uvalue#6 [phi:rom_verify::@21->printf_uint#3] -- register_copy 
    jsr printf_uint
    // [1024] phi from rom_verify::@21 to rom_verify::@22 [phi:rom_verify::@21->rom_verify::@22]
    // rom_verify::@22
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_difference_bytes, bram_bank, ram_address, rom_address)
    // [1025] call printf_str
    // [471] phi from rom_verify::@22 to printf_str [phi:rom_verify::@22->printf_str]
    // [471] phi printf_str::putc#52 = &snputc [phi:rom_verify::@22->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [471] phi printf_str::s#52 = rom_verify::s3 [phi:rom_verify::@22->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@23
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_difference_bytes, bram_bank, ram_address, rom_address)
    // [1026] printf_ulong::uvalue#3 = rom_verify::rom_address#1 -- vduz1=vduz2 
    lda.z rom_address
    sta.z printf_ulong.uvalue
    lda.z rom_address+1
    sta.z printf_ulong.uvalue+1
    lda.z rom_address+2
    sta.z printf_ulong.uvalue+2
    lda.z rom_address+3
    sta.z printf_ulong.uvalue+3
    // [1027] call printf_ulong
    // [963] phi from rom_verify::@23 to printf_ulong [phi:rom_verify::@23->printf_ulong]
    // [963] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#3 [phi:rom_verify::@23->printf_ulong#0] -- register_copy 
    jsr printf_ulong
    // rom_verify::@24
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_difference_bytes, bram_bank, ram_address, rom_address)
    // [1028] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1029] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [1031] call info_line
    // [446] phi from rom_verify::@24 to info_line [phi:rom_verify::@24->info_line]
    // [446] phi info_line::info_text#16 = info_text [phi:rom_verify::@24->info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_line.info_text
    lda #>@info_text
    sta.z info_line.info_text+1
    jsr info_line
    // [981] phi from rom_verify::@24 to rom_verify::@1 [phi:rom_verify::@24->rom_verify::@1]
    // [981] phi rom_verify::y#3 = rom_verify::y#10 [phi:rom_verify::@24->rom_verify::@1#0] -- register_copy 
    // [981] phi rom_verify::rom_difference_bytes#10 = rom_verify::rom_difference_bytes#1 [phi:rom_verify::@24->rom_verify::@1#1] -- register_copy 
    // [981] phi rom_verify::progress_row_current#3 = rom_verify::progress_row_current#11 [phi:rom_verify::@24->rom_verify::@1#2] -- register_copy 
    // [981] phi rom_verify::ram_address#10 = rom_verify::ram_address#11 [phi:rom_verify::@24->rom_verify::@1#3] -- register_copy 
    // [981] phi rom_verify::bram_bank#11 = rom_verify::bram_bank#10 [phi:rom_verify::@24->rom_verify::@1#4] -- register_copy 
    // [981] phi rom_verify::rom_address#12 = rom_verify::rom_address#1 [phi:rom_verify::@24->rom_verify::@1#5] -- register_copy 
    jmp __b1
    // rom_verify::@5
  __b5:
    // cputc('*')
    // [1032] stackpush(char) = '*' -- _stackpushbyte_=vbuc1 
    lda #'*'
    pha
    // [1033] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b6
  .segment Data
    info_text: .text "Comparing with existing ROM ... (.) same, (*) different."
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
    rom_boundary: .dword 0
    rom_difference_bytes: .dword 0
    .label rom_chip = rom_detect.rom_detect__28
    file_size: .dword 0
    .label return = rom_difference_bytes
}
.segment Code
  // system_reset
system_reset: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    // system_reset::bank_set_bram1
    // BRAM = bank
    // [1036] BRAM = system_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // system_reset::bank_set_brom1
    // BROM = bank
    // [1037] BROM = system_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // system_reset::@1
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // system_reset::@return
    // }
    // [1039] return 
}
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __zp($c4) char mapbase, __zp($c0) char config)
screenlayer: {
    .label screenlayer__1 = $c4
    .label screenlayer__5 = $c0
    .label screenlayer__6 = $c0
    .label mapbase = $c4
    .label config = $c0
    .label y = $be
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [1040] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [1041] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [1042] *((char *)&__conio+2) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+2
    // mapbase >> 7
    // [1043] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbum1=vbuz2_ror_7 
    lda.z mapbase
    rol
    rol
    and #1
    sta screenlayer__0
    // __conio.mapbase_bank = mapbase >> 7
    // [1044] *((char *)&__conio+5) = screenlayer::$0 -- _deref_pbuc1=vbum1 
    sta __conio+5
    // (mapbase)<<1
    // [1045] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z screenlayer__1
    // MAKEWORD((mapbase)<<1,0)
    // [1046] screenlayer::$2 = screenlayer::$1 w= 0 -- vwum1=vbuz2_word_vbuc1 
    lda #0
    ldy.z screenlayer__1
    sty screenlayer__2+1
    sta screenlayer__2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [1047] *((unsigned int *)&__conio+3) = screenlayer::$2 -- _deref_pwuc1=vwum1 
    sta __conio+3
    tya
    sta __conio+3+1
    // config & VERA_LAYER_WIDTH_MASK
    // [1048] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbum1=vbuz2_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and.z config
    sta screenlayer__7
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [1049] screenlayer::$8 = screenlayer::$7 >> 4 -- vbum1=vbum1_ror_4 
    lda screenlayer__8
    lsr
    lsr
    lsr
    lsr
    sta screenlayer__8
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [1050] *((char *)&__conio+8) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbum1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+8
    // config & VERA_LAYER_HEIGHT_MASK
    // [1051] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbuz1=vbuz1_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and.z screenlayer__5
    sta.z screenlayer__5
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [1052] screenlayer::$6 = screenlayer::$5 >> 6 -- vbuz1=vbuz1_ror_6 
    lda.z screenlayer__6
    rol
    rol
    rol
    and #3
    sta.z screenlayer__6
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [1053] *((char *)&__conio+9) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+9
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [1054] screenlayer::$16 = screenlayer::$8 << 1 -- vbum1=vbum1_rol_1 
    asl screenlayer__16
    // [1055] *((unsigned int *)&__conio+$a) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbum1 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    ldy screenlayer__16
    lda VERA_LAYER_SKIP,y
    sta __conio+$a
    lda VERA_LAYER_SKIP+1,y
    sta __conio+$a+1
    // vera_dc_hscale_temp == 0x80
    // [1056] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vbom1=vbum2_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta screenlayer__9
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [1057] screenlayer::$18 = (char)screenlayer::$9
    // [1058] screenlayer::$10 = $28 << screenlayer::$18 -- vbum1=vbuc1_rol_vbum1 
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
    // [1059] screenlayer::$11 = screenlayer::$10 - 1 -- vbum1=vbum1_minus_1 
    dec screenlayer__11
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [1060] *((char *)&__conio+6) = screenlayer::$11 -- _deref_pbuc1=vbum1 
    lda screenlayer__11
    sta __conio+6
    // vera_dc_vscale_temp == 0x80
    // [1061] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vbom1=vbum2_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta screenlayer__12
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [1062] screenlayer::$19 = (char)screenlayer::$12
    // [1063] screenlayer::$13 = $1e << screenlayer::$19 -- vbum1=vbuc1_rol_vbum1 
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
    // [1064] screenlayer::$14 = screenlayer::$13 - 1 -- vbum1=vbum1_minus_1 
    dec screenlayer__14
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1065] *((char *)&__conio+7) = screenlayer::$14 -- _deref_pbuc1=vbum1 
    lda screenlayer__14
    sta __conio+7
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [1066] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta mapbase_offset
    lda __conio+3+1
    sta mapbase_offset+1
    // [1067] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [1067] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [1067] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [1068] if(screenlayer::y#2<=*((char *)&__conio+7)) goto screenlayer::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+7
    cmp.z y
    bcs __b2
    // screenlayer::@return
    // }
    // [1069] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [1070] screenlayer::$17 = screenlayer::y#2 << 1 -- vbum1=vbuz2_rol_1 
    lda.z y
    asl
    sta screenlayer__17
    // [1071] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbum1=vwum2 
    tay
    lda mapbase_offset
    sta __conio+$15,y
    lda mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [1072] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda mapbase_offset
    adc __conio+$a
    sta mapbase_offset
    lda mapbase_offset+1
    adc __conio+$a+1
    sta mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [1073] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [1067] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [1067] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [1067] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
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
    // [1074] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [1075] if(0!=((char *)&__conio+$f)[*((char *)&__conio+2)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [1076] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // [1077] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [1078] call gotoxy
    // [334] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [334] phi gotoxy::y#22 = 0 [phi:cscroll::@3->gotoxy#0] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.y
    // [334] phi gotoxy::x#22 = 0 [phi:cscroll::@3->gotoxy#1] -- vbuz1=vbuc1 
    sta.z gotoxy.x
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [1079] return 
    rts
    // [1080] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [1081] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [1082] gotoxy::y#3 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
    lda __conio+7
    sta.z gotoxy.y
    // [1083] call gotoxy
    // [334] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [334] phi gotoxy::y#22 = gotoxy::y#3 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [334] phi gotoxy::x#22 = 0 [phi:cscroll::@5->gotoxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.x
    jsr gotoxy
    // [1084] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [1085] call clearline
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
    // [1086] ((char *)&__conio+$f)[*((char *)&__conio+2)] = scroll::onoff#0 -- pbuc1_derefidx_(_deref_pbuc2)=vbuc3 
    lda #onoff
    ldy __conio+2
    sta __conio+$f,y
    // scroll::@return
    // }
    // [1087] return 
    rts
}
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    .label clrscr__2 = $e3
    .label line_text = $71
    .label l = $78
    .label ch = $71
    .label c = $e8
    // unsigned int line_text = __conio.mapbase_offset
    // [1088] clrscr::line_text#0 = *((unsigned int *)&__conio+3) -- vwuz1=_deref_pwuc1 
    lda __conio+3
    sta.z line_text
    lda __conio+3+1
    sta.z line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1089] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [1090] clrscr::$0 = *((char *)&__conio+5) | VERA_INC_1 -- vbum1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta clrscr__0
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1091] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [1092] clrscr::l#0 = *((char *)&__conio+9) -- vbuz1=_deref_pbuc1 
    lda __conio+9
    sta.z l
    // [1093] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [1093] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [1093] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [1094] clrscr::$1 = byte0  clrscr::ch#0 -- vbum1=_byte0_vwuz2 
    lda.z ch
    sta clrscr__1
    // *VERA_ADDRX_L = BYTE0(ch)
    // [1095] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbum1 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [1096] clrscr::$2 = byte1  clrscr::ch#0 -- vbuz1=_byte1_vwuz2 
    lda.z ch+1
    sta.z clrscr__2
    // *VERA_ADDRX_M = BYTE1(ch)
    // [1097] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth+1
    // [1098] clrscr::c#0 = *((char *)&__conio+8) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+8
    inc
    sta.z c
    // [1099] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [1099] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [1100] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1101] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [1102] clrscr::c#1 = -- clrscr::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [1103] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [1104] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+$a) -- vwuz1=vwuz1_plus__deref_pwuc1 
    clc
    lda.z line_text
    adc __conio+$a
    sta.z line_text
    lda.z line_text+1
    adc __conio+$a+1
    sta.z line_text+1
    // l--;
    // [1105] clrscr::l#1 = -- clrscr::l#4 -- vbuz1=_dec_vbuz1 
    dec.z l
    // while(l)
    // [1106] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbuz1_then_la1 
    lda.z l
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [1107] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y = 0
    // [1108] *((char *)&__conio+1) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+1
    // __conio.offset = __conio.mapbase_offset
    // [1109] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+3) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+3
    sta __conio+$13
    lda __conio+3+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [1110] return 
    rts
  .segment Data
    .label clrscr__0 = frame.w
    .label clrscr__1 = frame.h
}
.segment Code
  // frame
// Draw a line horizontal from a given xy position and a given length.
// The line should calculate the matching characters to draw and glue them.
// So it first needs to peek the characters at the given position.
// And then calculate the resulting characters to draw.
// void frame(char x0, char y0, __zp($5a) char x1, __zp($5b) char y1)
frame: {
    .label x = $24
    .label y = $61
    .label mask = $dc
    .label c = $55
    .label x_1 = $b7
    .label y_1 = $b6
    .label x1 = $5a
    .label y1 = $5b
    // unsigned char w = x1 - x0
    // [1112] frame::w#0 = frame::x1#16 - frame::x#0 -- vbum1=vbuz2_minus_vbuz3 
    lda.z x1
    sec
    sbc.z x
    sta w
    // unsigned char h = y1 - y0
    // [1113] frame::h#0 = frame::y1#16 - frame::y#0 -- vbum1=vbuz2_minus_vbuz3 
    lda.z y1
    sec
    sbc.z y
    sta h
    // unsigned char mask = frame_maskxy(x, y)
    // [1114] frame_maskxy::x#0 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z frame_maskxy.x
    // [1115] frame_maskxy::y#0 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z frame_maskxy.y
    // [1116] call frame_maskxy
    // [1689] phi from frame to frame_maskxy [phi:frame->frame_maskxy]
    // [1689] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#0 [phi:frame->frame_maskxy#0] -- register_copy 
    // [1689] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#0 [phi:frame->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // unsigned char mask = frame_maskxy(x, y)
    // [1117] frame_maskxy::return#13 = frame_maskxy::return#12
    // frame::@13
    // [1118] frame::mask#0 = frame_maskxy::return#13
    // mask |= 0b0110
    // [1119] frame::mask#1 = frame::mask#0 | 6 -- vbuz1=vbuz1_bor_vbuc1 
    lda #6
    ora.z mask
    sta.z mask
    // unsigned char c = frame_char(mask)
    // [1120] frame_char::mask#0 = frame::mask#1
    // [1121] call frame_char
  // Add a corner.
    // [1715] phi from frame::@13 to frame_char [phi:frame::@13->frame_char]
    // [1715] phi frame_char::mask#10 = frame_char::mask#0 [phi:frame::@13->frame_char#0] -- register_copy 
    jsr frame_char
    // unsigned char c = frame_char(mask)
    // [1122] frame_char::return#13 = frame_char::return#12
    // frame::@14
    // [1123] frame::c#0 = frame_char::return#13
    // cputcxy(x, y, c)
    // [1124] cputcxy::x#0 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1125] cputcxy::y#0 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [1126] cputcxy::c#0 = frame::c#0
    // [1127] call cputcxy
    // [1250] phi from frame::@14 to cputcxy [phi:frame::@14->cputcxy]
    // [1250] phi cputcxy::c#11 = cputcxy::c#0 [phi:frame::@14->cputcxy#0] -- register_copy 
    // [1250] phi cputcxy::y#11 = cputcxy::y#0 [phi:frame::@14->cputcxy#1] -- register_copy 
    // [1250] phi cputcxy::x#11 = cputcxy::x#0 [phi:frame::@14->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@15
    // if(w>=2)
    // [1128] if(frame::w#0<2) goto frame::@36 -- vbum1_lt_vbuc1_then_la1 
    lda w
    cmp #2
    bcs !__b36+
    jmp __b36
  !__b36:
    // frame::@2
    // x++;
    // [1129] frame::x#1 = ++ frame::x#0 -- vbuz1=_inc_vbuz2 
    lda.z x
    inc
    sta.z x_1
    // [1130] phi from frame::@2 frame::@21 to frame::@4 [phi:frame::@2/frame::@21->frame::@4]
    // [1130] phi frame::x#10 = frame::x#1 [phi:frame::@2/frame::@21->frame::@4#0] -- register_copy 
    // frame::@4
  __b4:
    // while(x < x1)
    // [1131] if(frame::x#10<frame::x1#16) goto frame::@5 -- vbuz1_lt_vbuz2_then_la1 
    lda.z x_1
    cmp.z x1
    bcs !__b5+
    jmp __b5
  !__b5:
    // [1132] phi from frame::@36 frame::@4 to frame::@1 [phi:frame::@36/frame::@4->frame::@1]
    // [1132] phi frame::x#24 = frame::x#30 [phi:frame::@36/frame::@4->frame::@1#0] -- register_copy 
    // frame::@1
  __b1:
    // frame_maskxy(x, y)
    // [1133] frame_maskxy::x#1 = frame::x#24 -- vbuz1=vbuz2 
    lda.z x_1
    sta.z frame_maskxy.x
    // [1134] frame_maskxy::y#1 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z frame_maskxy.y
    // [1135] call frame_maskxy
    // [1689] phi from frame::@1 to frame_maskxy [phi:frame::@1->frame_maskxy]
    // [1689] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#1 [phi:frame::@1->frame_maskxy#0] -- register_copy 
    // [1689] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#1 [phi:frame::@1->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [1136] frame_maskxy::return#14 = frame_maskxy::return#12
    // frame::@16
    // mask = frame_maskxy(x, y)
    // [1137] frame::mask#2 = frame_maskxy::return#14
    // mask |= 0b0011
    // [1138] frame::mask#3 = frame::mask#2 | 3 -- vbuz1=vbuz1_bor_vbuc1 
    lda #3
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [1139] frame_char::mask#1 = frame::mask#3
    // [1140] call frame_char
    // [1715] phi from frame::@16 to frame_char [phi:frame::@16->frame_char]
    // [1715] phi frame_char::mask#10 = frame_char::mask#1 [phi:frame::@16->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1141] frame_char::return#14 = frame_char::return#12
    // frame::@17
    // c = frame_char(mask)
    // [1142] frame::c#1 = frame_char::return#14
    // cputcxy(x, y, c)
    // [1143] cputcxy::x#1 = frame::x#24 -- vbuz1=vbuz2 
    lda.z x_1
    sta.z cputcxy.x
    // [1144] cputcxy::y#1 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [1145] cputcxy::c#1 = frame::c#1
    // [1146] call cputcxy
    // [1250] phi from frame::@17 to cputcxy [phi:frame::@17->cputcxy]
    // [1250] phi cputcxy::c#11 = cputcxy::c#1 [phi:frame::@17->cputcxy#0] -- register_copy 
    // [1250] phi cputcxy::y#11 = cputcxy::y#1 [phi:frame::@17->cputcxy#1] -- register_copy 
    // [1250] phi cputcxy::x#11 = cputcxy::x#1 [phi:frame::@17->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@18
    // if(h>=2)
    // [1147] if(frame::h#0<2) goto frame::@return -- vbum1_lt_vbuc1_then_la1 
    lda h
    cmp #2
    bcc __breturn
    // frame::@3
    // y++;
    // [1148] frame::y#1 = ++ frame::y#0 -- vbuz1=_inc_vbuz2 
    lda.z y
    inc
    sta.z y_1
    // [1149] phi from frame::@27 frame::@3 to frame::@6 [phi:frame::@27/frame::@3->frame::@6]
    // [1149] phi frame::y#10 = frame::y#2 [phi:frame::@27/frame::@3->frame::@6#0] -- register_copy 
    // frame::@6
  __b6:
    // while(y < y1)
    // [1150] if(frame::y#10<frame::y1#16) goto frame::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z y_1
    cmp.z y1
    bcc __b7
    // frame::@8
    // frame_maskxy(x, y)
    // [1151] frame_maskxy::x#5 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z frame_maskxy.x
    // [1152] frame_maskxy::y#5 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z frame_maskxy.y
    // [1153] call frame_maskxy
    // [1689] phi from frame::@8 to frame_maskxy [phi:frame::@8->frame_maskxy]
    // [1689] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#5 [phi:frame::@8->frame_maskxy#0] -- register_copy 
    // [1689] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#5 [phi:frame::@8->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [1154] frame_maskxy::return#18 = frame_maskxy::return#12
    // frame::@28
    // mask = frame_maskxy(x, y)
    // [1155] frame::mask#10 = frame_maskxy::return#18
    // mask |= 0b1100
    // [1156] frame::mask#11 = frame::mask#10 | $c -- vbuz1=vbuz1_bor_vbuc1 
    lda #$c
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [1157] frame_char::mask#5 = frame::mask#11
    // [1158] call frame_char
    // [1715] phi from frame::@28 to frame_char [phi:frame::@28->frame_char]
    // [1715] phi frame_char::mask#10 = frame_char::mask#5 [phi:frame::@28->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1159] frame_char::return#18 = frame_char::return#12
    // frame::@29
    // c = frame_char(mask)
    // [1160] frame::c#5 = frame_char::return#18
    // cputcxy(x, y, c)
    // [1161] cputcxy::x#5 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1162] cputcxy::y#5 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1163] cputcxy::c#5 = frame::c#5
    // [1164] call cputcxy
    // [1250] phi from frame::@29 to cputcxy [phi:frame::@29->cputcxy]
    // [1250] phi cputcxy::c#11 = cputcxy::c#5 [phi:frame::@29->cputcxy#0] -- register_copy 
    // [1250] phi cputcxy::y#11 = cputcxy::y#5 [phi:frame::@29->cputcxy#1] -- register_copy 
    // [1250] phi cputcxy::x#11 = cputcxy::x#5 [phi:frame::@29->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@30
    // if(w>=2)
    // [1165] if(frame::w#0<2) goto frame::@10 -- vbum1_lt_vbuc1_then_la1 
    lda w
    cmp #2
    bcc __b10
    // frame::@9
    // x++;
    // [1166] frame::x#4 = ++ frame::x#0 -- vbuz1=_inc_vbuz1 
    inc.z x
    // [1167] phi from frame::@35 frame::@9 to frame::@11 [phi:frame::@35/frame::@9->frame::@11]
    // [1167] phi frame::x#18 = frame::x#5 [phi:frame::@35/frame::@9->frame::@11#0] -- register_copy 
    // frame::@11
  __b11:
    // while(x < x1)
    // [1168] if(frame::x#18<frame::x1#16) goto frame::@12 -- vbuz1_lt_vbuz2_then_la1 
    lda.z x
    cmp.z x1
    bcc __b12
    // [1169] phi from frame::@11 frame::@30 to frame::@10 [phi:frame::@11/frame::@30->frame::@10]
    // [1169] phi frame::x#15 = frame::x#18 [phi:frame::@11/frame::@30->frame::@10#0] -- register_copy 
    // frame::@10
  __b10:
    // frame_maskxy(x, y)
    // [1170] frame_maskxy::x#6 = frame::x#15 -- vbuz1=vbuz2 
    lda.z x
    sta.z frame_maskxy.x
    // [1171] frame_maskxy::y#6 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z frame_maskxy.y
    // [1172] call frame_maskxy
    // [1689] phi from frame::@10 to frame_maskxy [phi:frame::@10->frame_maskxy]
    // [1689] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#6 [phi:frame::@10->frame_maskxy#0] -- register_copy 
    // [1689] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#6 [phi:frame::@10->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [1173] frame_maskxy::return#19 = frame_maskxy::return#12
    // frame::@31
    // mask = frame_maskxy(x, y)
    // [1174] frame::mask#12 = frame_maskxy::return#19
    // mask |= 0b1001
    // [1175] frame::mask#13 = frame::mask#12 | 9 -- vbuz1=vbuz1_bor_vbuc1 
    lda #9
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [1176] frame_char::mask#6 = frame::mask#13
    // [1177] call frame_char
    // [1715] phi from frame::@31 to frame_char [phi:frame::@31->frame_char]
    // [1715] phi frame_char::mask#10 = frame_char::mask#6 [phi:frame::@31->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1178] frame_char::return#19 = frame_char::return#12
    // frame::@32
    // c = frame_char(mask)
    // [1179] frame::c#6 = frame_char::return#19
    // cputcxy(x, y, c)
    // [1180] cputcxy::x#6 = frame::x#15 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1181] cputcxy::y#6 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1182] cputcxy::c#6 = frame::c#6
    // [1183] call cputcxy
    // [1250] phi from frame::@32 to cputcxy [phi:frame::@32->cputcxy]
    // [1250] phi cputcxy::c#11 = cputcxy::c#6 [phi:frame::@32->cputcxy#0] -- register_copy 
    // [1250] phi cputcxy::y#11 = cputcxy::y#6 [phi:frame::@32->cputcxy#1] -- register_copy 
    // [1250] phi cputcxy::x#11 = cputcxy::x#6 [phi:frame::@32->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@return
  __breturn:
    // }
    // [1184] return 
    rts
    // frame::@12
  __b12:
    // frame_maskxy(x, y)
    // [1185] frame_maskxy::x#7 = frame::x#18 -- vbuz1=vbuz2 
    lda.z x
    sta.z frame_maskxy.x
    // [1186] frame_maskxy::y#7 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z frame_maskxy.y
    // [1187] call frame_maskxy
    // [1689] phi from frame::@12 to frame_maskxy [phi:frame::@12->frame_maskxy]
    // [1689] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#7 [phi:frame::@12->frame_maskxy#0] -- register_copy 
    // [1689] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#7 [phi:frame::@12->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [1188] frame_maskxy::return#20 = frame_maskxy::return#12
    // frame::@33
    // mask = frame_maskxy(x, y)
    // [1189] frame::mask#14 = frame_maskxy::return#20
    // mask |= 0b0101
    // [1190] frame::mask#15 = frame::mask#14 | 5 -- vbuz1=vbuz1_bor_vbuc1 
    lda #5
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [1191] frame_char::mask#7 = frame::mask#15
    // [1192] call frame_char
    // [1715] phi from frame::@33 to frame_char [phi:frame::@33->frame_char]
    // [1715] phi frame_char::mask#10 = frame_char::mask#7 [phi:frame::@33->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1193] frame_char::return#20 = frame_char::return#12
    // frame::@34
    // c = frame_char(mask)
    // [1194] frame::c#7 = frame_char::return#20
    // cputcxy(x, y, c)
    // [1195] cputcxy::x#7 = frame::x#18 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1196] cputcxy::y#7 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1197] cputcxy::c#7 = frame::c#7
    // [1198] call cputcxy
    // [1250] phi from frame::@34 to cputcxy [phi:frame::@34->cputcxy]
    // [1250] phi cputcxy::c#11 = cputcxy::c#7 [phi:frame::@34->cputcxy#0] -- register_copy 
    // [1250] phi cputcxy::y#11 = cputcxy::y#7 [phi:frame::@34->cputcxy#1] -- register_copy 
    // [1250] phi cputcxy::x#11 = cputcxy::x#7 [phi:frame::@34->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@35
    // x++;
    // [1199] frame::x#5 = ++ frame::x#18 -- vbuz1=_inc_vbuz1 
    inc.z x
    jmp __b11
    // frame::@7
  __b7:
    // frame_maskxy(x0, y)
    // [1200] frame_maskxy::x#3 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z frame_maskxy.x
    // [1201] frame_maskxy::y#3 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z frame_maskxy.y
    // [1202] call frame_maskxy
    // [1689] phi from frame::@7 to frame_maskxy [phi:frame::@7->frame_maskxy]
    // [1689] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#3 [phi:frame::@7->frame_maskxy#0] -- register_copy 
    // [1689] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#3 [phi:frame::@7->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x0, y)
    // [1203] frame_maskxy::return#16 = frame_maskxy::return#12
    // frame::@22
    // mask = frame_maskxy(x0, y)
    // [1204] frame::mask#6 = frame_maskxy::return#16
    // mask |= 0b1010
    // [1205] frame::mask#7 = frame::mask#6 | $a -- vbuz1=vbuz1_bor_vbuc1 
    lda #$a
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [1206] frame_char::mask#3 = frame::mask#7
    // [1207] call frame_char
    // [1715] phi from frame::@22 to frame_char [phi:frame::@22->frame_char]
    // [1715] phi frame_char::mask#10 = frame_char::mask#3 [phi:frame::@22->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1208] frame_char::return#16 = frame_char::return#12
    // frame::@23
    // c = frame_char(mask)
    // [1209] frame::c#3 = frame_char::return#16
    // cputcxy(x0, y, c)
    // [1210] cputcxy::x#3 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1211] cputcxy::y#3 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1212] cputcxy::c#3 = frame::c#3
    // [1213] call cputcxy
    // [1250] phi from frame::@23 to cputcxy [phi:frame::@23->cputcxy]
    // [1250] phi cputcxy::c#11 = cputcxy::c#3 [phi:frame::@23->cputcxy#0] -- register_copy 
    // [1250] phi cputcxy::y#11 = cputcxy::y#3 [phi:frame::@23->cputcxy#1] -- register_copy 
    // [1250] phi cputcxy::x#11 = cputcxy::x#3 [phi:frame::@23->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@24
    // frame_maskxy(x1, y)
    // [1214] frame_maskxy::x#4 = frame::x1#16 -- vbuz1=vbuz2 
    lda.z x1
    sta.z frame_maskxy.x
    // [1215] frame_maskxy::y#4 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z frame_maskxy.y
    // [1216] call frame_maskxy
    // [1689] phi from frame::@24 to frame_maskxy [phi:frame::@24->frame_maskxy]
    // [1689] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#4 [phi:frame::@24->frame_maskxy#0] -- register_copy 
    // [1689] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#4 [phi:frame::@24->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x1, y)
    // [1217] frame_maskxy::return#17 = frame_maskxy::return#12
    // frame::@25
    // mask = frame_maskxy(x1, y)
    // [1218] frame::mask#8 = frame_maskxy::return#17
    // mask |= 0b1010
    // [1219] frame::mask#9 = frame::mask#8 | $a -- vbuz1=vbuz1_bor_vbuc1 
    lda #$a
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [1220] frame_char::mask#4 = frame::mask#9
    // [1221] call frame_char
    // [1715] phi from frame::@25 to frame_char [phi:frame::@25->frame_char]
    // [1715] phi frame_char::mask#10 = frame_char::mask#4 [phi:frame::@25->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1222] frame_char::return#17 = frame_char::return#12
    // frame::@26
    // c = frame_char(mask)
    // [1223] frame::c#4 = frame_char::return#17
    // cputcxy(x1, y, c)
    // [1224] cputcxy::x#4 = frame::x1#16 -- vbuz1=vbuz2 
    lda.z x1
    sta.z cputcxy.x
    // [1225] cputcxy::y#4 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1226] cputcxy::c#4 = frame::c#4
    // [1227] call cputcxy
    // [1250] phi from frame::@26 to cputcxy [phi:frame::@26->cputcxy]
    // [1250] phi cputcxy::c#11 = cputcxy::c#4 [phi:frame::@26->cputcxy#0] -- register_copy 
    // [1250] phi cputcxy::y#11 = cputcxy::y#4 [phi:frame::@26->cputcxy#1] -- register_copy 
    // [1250] phi cputcxy::x#11 = cputcxy::x#4 [phi:frame::@26->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@27
    // y++;
    // [1228] frame::y#2 = ++ frame::y#10 -- vbuz1=_inc_vbuz1 
    inc.z y_1
    jmp __b6
    // frame::@5
  __b5:
    // frame_maskxy(x, y)
    // [1229] frame_maskxy::x#2 = frame::x#10 -- vbuz1=vbuz2 
    lda.z x_1
    sta.z frame_maskxy.x
    // [1230] frame_maskxy::y#2 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z frame_maskxy.y
    // [1231] call frame_maskxy
    // [1689] phi from frame::@5 to frame_maskxy [phi:frame::@5->frame_maskxy]
    // [1689] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#2 [phi:frame::@5->frame_maskxy#0] -- register_copy 
    // [1689] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#2 [phi:frame::@5->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [1232] frame_maskxy::return#15 = frame_maskxy::return#12
    // frame::@19
    // mask = frame_maskxy(x, y)
    // [1233] frame::mask#4 = frame_maskxy::return#15
    // mask |= 0b0101
    // [1234] frame::mask#5 = frame::mask#4 | 5 -- vbuz1=vbuz1_bor_vbuc1 
    lda #5
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [1235] frame_char::mask#2 = frame::mask#5
    // [1236] call frame_char
    // [1715] phi from frame::@19 to frame_char [phi:frame::@19->frame_char]
    // [1715] phi frame_char::mask#10 = frame_char::mask#2 [phi:frame::@19->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1237] frame_char::return#15 = frame_char::return#12
    // frame::@20
    // c = frame_char(mask)
    // [1238] frame::c#2 = frame_char::return#15
    // cputcxy(x, y, c)
    // [1239] cputcxy::x#2 = frame::x#10 -- vbuz1=vbuz2 
    lda.z x_1
    sta.z cputcxy.x
    // [1240] cputcxy::y#2 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [1241] cputcxy::c#2 = frame::c#2
    // [1242] call cputcxy
    // [1250] phi from frame::@20 to cputcxy [phi:frame::@20->cputcxy]
    // [1250] phi cputcxy::c#11 = cputcxy::c#2 [phi:frame::@20->cputcxy#0] -- register_copy 
    // [1250] phi cputcxy::y#11 = cputcxy::y#2 [phi:frame::@20->cputcxy#1] -- register_copy 
    // [1250] phi cputcxy::x#11 = cputcxy::x#2 [phi:frame::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@21
    // x++;
    // [1243] frame::x#2 = ++ frame::x#10 -- vbuz1=_inc_vbuz1 
    inc.z x_1
    jmp __b4
    // frame::@36
  __b36:
    // [1244] frame::x#30 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z x_1
    jmp __b1
  .segment Data
    w: .byte 0
    h: .byte 0
}
.segment Code
  // cputsxy
// Move cursor and output a NUL-terminated string
// Same as "gotoxy (x, y); puts (s);"
// void cputsxy(char x, char y, const char *s)
cputsxy: {
    .const x = 2
    .const y = $e
    // gotoxy(x, y)
    // [1246] call gotoxy
    // [334] phi from cputsxy to gotoxy [phi:cputsxy->gotoxy]
    // [334] phi gotoxy::y#22 = cputsxy::y#0 [phi:cputsxy->gotoxy#0] -- vbuz1=vbuc1 
    lda #y
    sta.z gotoxy.y
    // [334] phi gotoxy::x#22 = cputsxy::x#0 [phi:cputsxy->gotoxy#1] -- vbuz1=vbuc1 
    lda #x
    sta.z gotoxy.x
    jsr gotoxy
    // [1247] phi from cputsxy to cputsxy::@1 [phi:cputsxy->cputsxy::@1]
    // cputsxy::@1
    // cputs(s)
    // [1248] call cputs
    // [1730] phi from cputsxy::@1 to cputs [phi:cputsxy::@1->cputs]
    jsr cputs
    // cputsxy::@return
    // }
    // [1249] return 
    rts
}
  // cputcxy
// Move cursor and output one character
// Same as "gotoxy (x, y); cputc (c);"
// void cputcxy(__zp($59) char x, __zp($58) char y, __zp($55) char c)
cputcxy: {
    .label x = $59
    .label y = $58
    .label c = $55
    // gotoxy(x, y)
    // [1251] gotoxy::x#0 = cputcxy::x#11 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1252] gotoxy::y#0 = cputcxy::y#11 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1253] call gotoxy
    // [334] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [334] phi gotoxy::y#22 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [334] phi gotoxy::x#22 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [1254] stackpush(char) = cputcxy::c#11 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [1255] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [1257] return 
    rts
}
  // info_clear
// void info_clear(__zp($45) char l)
info_clear: {
    .const w = $40
    .label y = $45
    .label x = $5f
    .label i = $2e
    .label l = $45
    // unsigned char y = INFO_Y+l
    // [1259] info_clear::y#0 = $11 + info_clear::l#4 -- vbuz1=vbuc1_plus_vbuz1 
    lda #$11
    clc
    adc.z y
    sta.z y
    // [1260] phi from info_clear to info_clear::@1 [phi:info_clear->info_clear::@1]
    // [1260] phi info_clear::x#2 = 2 [phi:info_clear->info_clear::@1#0] -- vbuz1=vbuc1 
    lda #2
    sta.z x
    // [1260] phi info_clear::i#2 = 0 [phi:info_clear->info_clear::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // info_clear::@1
  __b1:
    // for(unsigned char i = 0; i < w; i++)
    // [1261] if(info_clear::i#2<info_clear::w) goto info_clear::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z i
    cmp #w
    bcc __b2
    // info_clear::@3
    // gotoxy(PROGRESS_X, y)
    // [1262] gotoxy::y#12 = info_clear::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1263] call gotoxy
    // [334] phi from info_clear::@3 to gotoxy [phi:info_clear::@3->gotoxy]
    // [334] phi gotoxy::y#22 = gotoxy::y#12 [phi:info_clear::@3->gotoxy#0] -- register_copy 
    // [334] phi gotoxy::x#22 = 2 [phi:info_clear::@3->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // info_clear::@return
    // }
    // [1264] return 
    rts
    // info_clear::@2
  __b2:
    // cputcxy(x, y, ' ')
    // [1265] cputcxy::x#10 = info_clear::x#2 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1266] cputcxy::y#10 = info_clear::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [1267] call cputcxy
    // [1250] phi from info_clear::@2 to cputcxy [phi:info_clear::@2->cputcxy]
    // [1250] phi cputcxy::c#11 = ' ' [phi:info_clear::@2->cputcxy#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z cputcxy.c
    // [1250] phi cputcxy::y#11 = cputcxy::y#10 [phi:info_clear::@2->cputcxy#1] -- register_copy 
    // [1250] phi cputcxy::x#11 = cputcxy::x#10 [phi:info_clear::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // info_clear::@4
    // x++;
    // [1268] info_clear::x#1 = ++ info_clear::x#2 -- vbuz1=_inc_vbuz1 
    inc.z x
    // for(unsigned char i = 0; i < w; i++)
    // [1269] info_clear::i#1 = ++ info_clear::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1260] phi from info_clear::@4 to info_clear::@1 [phi:info_clear::@4->info_clear::@1]
    // [1260] phi info_clear::x#2 = info_clear::x#1 [phi:info_clear::@4->info_clear::@1#0] -- register_copy 
    // [1260] phi info_clear::i#2 = info_clear::i#1 [phi:info_clear::@4->info_clear::@1#1] -- register_copy 
    jmp __b1
}
  // wherex
// Return the x position of the cursor
wherex: {
    .label return = $bc
    // return __conio.cursor_x;
    // [1270] wherex::return#0 = *((char *)&__conio) -- vbuz1=_deref_pbuc1 
    lda __conio
    sta.z return
    // wherex::@return
    // }
    // [1271] return 
    rts
}
  // wherey
// Return the y position of the cursor
wherey: {
    .label return = $bb
    // return __conio.cursor_y;
    // [1272] wherey::return#0 = *((char *)&__conio+1) -- vbuz1=_deref_pbuc1 
    lda __conio+1
    sta.z return
    // wherey::@return
    // }
    // [1273] return 
    rts
}
  // print_smc_led
// void print_smc_led(__zp($2b) char c)
print_smc_led: {
    .label c = $2b
    // print_chip_led(CHIP_SMC_X+1, CHIP_SMC_Y, CHIP_SMC_W, c, BLUE)
    // [1275] print_chip_led::tc#0 = print_smc_led::c#2
    // [1276] call print_chip_led
    // [1739] phi from print_smc_led to print_chip_led [phi:print_smc_led->print_chip_led]
    // [1739] phi print_chip_led::w#5 = 5 [phi:print_smc_led->print_chip_led#0] -- vbuz1=vbuc1 
    lda #5
    sta.z print_chip_led.w
    // [1739] phi print_chip_led::tc#3 = print_chip_led::tc#0 [phi:print_smc_led->print_chip_led#1] -- register_copy 
    // [1739] phi print_chip_led::x#3 = 1+1 [phi:print_smc_led->print_chip_led#2] -- vbuz1=vbuc1 
    lda #1+1
    sta.z print_chip_led.x
    jsr print_chip_led
    // print_smc_led::@return
    // }
    // [1277] return 
    rts
}
  // print_chip
// void print_chip(__zp($79) char x, char y, __zp($57) char w, __zp($2f) char *text)
print_chip: {
    .label y = 3+1+1+1+1+1+1+1+1+1
    .label text = $2f
    .label text_1 = $66
    .label x = $79
    .label text_2 = $62
    .label text_3 = $da
    .label text_5 = $f3
    .label text_6 = $64
    .label w = $57
    // print_chip_line(x, y++, w, *text++)
    // [1279] print_chip_line::x#0 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1280] print_chip_line::w#0 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1281] print_chip_line::c#0 = *print_chip::text#11 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_2),y
    sta.z print_chip_line.c
    // [1282] call print_chip_line
    // [1757] phi from print_chip to print_chip_line [phi:print_chip->print_chip_line]
    // [1757] phi print_chip_line::c#15 = print_chip_line::c#0 [phi:print_chip->print_chip_line#0] -- register_copy 
    // [1757] phi print_chip_line::w#10 = print_chip_line::w#0 [phi:print_chip->print_chip_line#1] -- register_copy 
    // [1757] phi print_chip_line::y#16 = 3+1 [phi:print_chip->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1
    sta.z print_chip_line.y
    // [1757] phi print_chip_line::x#16 = print_chip_line::x#0 [phi:print_chip->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@1
    // print_chip_line(x, y++, w, *text++);
    // [1283] print_chip::text#0 = ++ print_chip::text#11 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_2
    adc #1
    sta.z text
    lda.z text_2+1
    adc #0
    sta.z text+1
    // print_chip_line(x, y++, w, *text++)
    // [1284] print_chip_line::x#1 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1285] print_chip_line::w#1 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1286] print_chip_line::c#1 = *print_chip::text#0 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text),y
    sta.z print_chip_line.c
    // [1287] call print_chip_line
    // [1757] phi from print_chip::@1 to print_chip_line [phi:print_chip::@1->print_chip_line]
    // [1757] phi print_chip_line::c#15 = print_chip_line::c#1 [phi:print_chip::@1->print_chip_line#0] -- register_copy 
    // [1757] phi print_chip_line::w#10 = print_chip_line::w#1 [phi:print_chip::@1->print_chip_line#1] -- register_copy 
    // [1757] phi print_chip_line::y#16 = ++3+1 [phi:print_chip::@1->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1
    sta.z print_chip_line.y
    // [1757] phi print_chip_line::x#16 = print_chip_line::x#1 [phi:print_chip::@1->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@2
    // print_chip_line(x, y++, w, *text++);
    // [1288] print_chip::text#1 = ++ print_chip::text#0 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text
    adc #1
    sta.z text_1
    lda.z text+1
    adc #0
    sta.z text_1+1
    // print_chip_line(x, y++, w, *text++)
    // [1289] print_chip_line::x#2 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1290] print_chip_line::w#2 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1291] print_chip_line::c#2 = *print_chip::text#1 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_1),y
    sta.z print_chip_line.c
    // [1292] call print_chip_line
    // [1757] phi from print_chip::@2 to print_chip_line [phi:print_chip::@2->print_chip_line]
    // [1757] phi print_chip_line::c#15 = print_chip_line::c#2 [phi:print_chip::@2->print_chip_line#0] -- register_copy 
    // [1757] phi print_chip_line::w#10 = print_chip_line::w#2 [phi:print_chip::@2->print_chip_line#1] -- register_copy 
    // [1757] phi print_chip_line::y#16 = ++++3+1 [phi:print_chip::@2->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1
    sta.z print_chip_line.y
    // [1757] phi print_chip_line::x#16 = print_chip_line::x#2 [phi:print_chip::@2->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@3
    // print_chip_line(x, y++, w, *text++);
    // [1293] print_chip::text#15 = ++ print_chip::text#1 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_1
    adc #1
    sta.z text_3
    lda.z text_1+1
    adc #0
    sta.z text_3+1
    // print_chip_line(x, y++, w, *text++)
    // [1294] print_chip_line::x#3 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1295] print_chip_line::w#3 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1296] print_chip_line::c#3 = *print_chip::text#15 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_3),y
    sta.z print_chip_line.c
    // [1297] call print_chip_line
    // [1757] phi from print_chip::@3 to print_chip_line [phi:print_chip::@3->print_chip_line]
    // [1757] phi print_chip_line::c#15 = print_chip_line::c#3 [phi:print_chip::@3->print_chip_line#0] -- register_copy 
    // [1757] phi print_chip_line::w#10 = print_chip_line::w#3 [phi:print_chip::@3->print_chip_line#1] -- register_copy 
    // [1757] phi print_chip_line::y#16 = ++++++3+1 [phi:print_chip::@3->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1+1
    sta.z print_chip_line.y
    // [1757] phi print_chip_line::x#16 = print_chip_line::x#3 [phi:print_chip::@3->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@4
    // print_chip_line(x, y++, w, *text++);
    // [1298] print_chip::text#16 = ++ print_chip::text#15 -- pbum1=_inc_pbuz2 
    clc
    lda.z text_3
    adc #1
    sta text_4
    lda.z text_3+1
    adc #0
    sta text_4+1
    // print_chip_line(x, y++, w, *text++)
    // [1299] print_chip_line::x#4 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1300] print_chip_line::w#4 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1301] print_chip_line::c#4 = *print_chip::text#16 -- vbuz1=_deref_pbum2 
    ldy text_4
    sty.z $fe
    ldy text_4+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta.z print_chip_line.c
    // [1302] call print_chip_line
    // [1757] phi from print_chip::@4 to print_chip_line [phi:print_chip::@4->print_chip_line]
    // [1757] phi print_chip_line::c#15 = print_chip_line::c#4 [phi:print_chip::@4->print_chip_line#0] -- register_copy 
    // [1757] phi print_chip_line::w#10 = print_chip_line::w#4 [phi:print_chip::@4->print_chip_line#1] -- register_copy 
    // [1757] phi print_chip_line::y#16 = ++++++++3+1 [phi:print_chip::@4->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1+1+1
    sta.z print_chip_line.y
    // [1757] phi print_chip_line::x#16 = print_chip_line::x#4 [phi:print_chip::@4->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@5
    // print_chip_line(x, y++, w, *text++);
    // [1303] print_chip::text#17 = ++ print_chip::text#16 -- pbuz1=_inc_pbum2 
    clc
    lda text_4
    adc #1
    sta.z text_5
    lda text_4+1
    adc #0
    sta.z text_5+1
    // print_chip_line(x, y++, w, *text++)
    // [1304] print_chip_line::x#5 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1305] print_chip_line::w#5 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1306] print_chip_line::c#5 = *print_chip::text#17 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_5),y
    sta.z print_chip_line.c
    // [1307] call print_chip_line
    // [1757] phi from print_chip::@5 to print_chip_line [phi:print_chip::@5->print_chip_line]
    // [1757] phi print_chip_line::c#15 = print_chip_line::c#5 [phi:print_chip::@5->print_chip_line#0] -- register_copy 
    // [1757] phi print_chip_line::w#10 = print_chip_line::w#5 [phi:print_chip::@5->print_chip_line#1] -- register_copy 
    // [1757] phi print_chip_line::y#16 = ++++++++++3+1 [phi:print_chip::@5->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1+1+1+1
    sta.z print_chip_line.y
    // [1757] phi print_chip_line::x#16 = print_chip_line::x#5 [phi:print_chip::@5->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@6
    // print_chip_line(x, y++, w, *text++);
    // [1308] print_chip::text#18 = ++ print_chip::text#17 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_5
    adc #1
    sta.z text_6
    lda.z text_5+1
    adc #0
    sta.z text_6+1
    // print_chip_line(x, y++, w, *text++)
    // [1309] print_chip_line::x#6 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1310] print_chip_line::w#6 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1311] print_chip_line::c#6 = *print_chip::text#18 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta.z print_chip_line.c
    // [1312] call print_chip_line
    // [1757] phi from print_chip::@6 to print_chip_line [phi:print_chip::@6->print_chip_line]
    // [1757] phi print_chip_line::c#15 = print_chip_line::c#6 [phi:print_chip::@6->print_chip_line#0] -- register_copy 
    // [1757] phi print_chip_line::w#10 = print_chip_line::w#6 [phi:print_chip::@6->print_chip_line#1] -- register_copy 
    // [1757] phi print_chip_line::y#16 = ++++++++++++3+1 [phi:print_chip::@6->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1+1+1+1+1
    sta.z print_chip_line.y
    // [1757] phi print_chip_line::x#16 = print_chip_line::x#6 [phi:print_chip::@6->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@7
    // print_chip_line(x, y++, w, *text++);
    // [1313] print_chip::text#19 = ++ print_chip::text#18 -- pbuz1=_inc_pbuz1 
    inc.z text_6
    bne !+
    inc.z text_6+1
  !:
    // print_chip_line(x, y++, w, *text++)
    // [1314] print_chip_line::x#7 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1315] print_chip_line::w#7 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1316] print_chip_line::c#7 = *print_chip::text#19 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta.z print_chip_line.c
    // [1317] call print_chip_line
    // [1757] phi from print_chip::@7 to print_chip_line [phi:print_chip::@7->print_chip_line]
    // [1757] phi print_chip_line::c#15 = print_chip_line::c#7 [phi:print_chip::@7->print_chip_line#0] -- register_copy 
    // [1757] phi print_chip_line::w#10 = print_chip_line::w#7 [phi:print_chip::@7->print_chip_line#1] -- register_copy 
    // [1757] phi print_chip_line::y#16 = ++++++++++++++3+1 [phi:print_chip::@7->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1+1+1+1+1+1
    sta.z print_chip_line.y
    // [1757] phi print_chip_line::x#16 = print_chip_line::x#7 [phi:print_chip::@7->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@8
    // print_chip_end(x, y++, w)
    // [1318] print_chip_end::x#0 = print_chip::x#10
    // [1319] print_chip_end::w#0 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_end.w
    // [1320] call print_chip_end
    jsr print_chip_end
    // print_chip::@return
    // }
    // [1321] return 
    rts
  .segment Data
    .label text_4 = fopen.fopen__11
}
.segment Code
  // utoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void utoa(__zp($29) unsigned int value, __zp($53) char *buffer, __zp($b9) char radix)
utoa: {
    .label utoa__4 = $5a
    .label utoa__10 = $5b
    .label utoa__11 = $b6
    .label digit_value = $2f
    .label buffer = $53
    .label digit = $4a
    .label value = $29
    .label radix = $b9
    .label started = $61
    .label max_digits = $7a
    .label digit_values = $7c
    // if(radix==DECIMAL)
    // [1322] if(utoa::radix#0==DECIMAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp.z radix
    beq __b2
    // utoa::@2
    // if(radix==HEXADECIMAL)
    // [1323] if(utoa::radix#0==HEXADECIMAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp.z radix
    beq __b3
    // utoa::@3
    // if(radix==OCTAL)
    // [1324] if(utoa::radix#0==OCTAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp.z radix
    beq __b4
    // utoa::@4
    // if(radix==BINARY)
    // [1325] if(utoa::radix#0==BINARY) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp.z radix
    beq __b5
    // utoa::@5
    // *buffer++ = 'e'
    // [1326] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1327] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1328] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1329] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // utoa::@return
    // }
    // [1330] return 
    rts
    // [1331] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
  __b2:
    // [1331] phi utoa::digit_values#8 = RADIX_DECIMAL_VALUES [phi:utoa->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_DECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES
    sta.z digit_values+1
    // [1331] phi utoa::max_digits#7 = 5 [phi:utoa->utoa::@1#1] -- vbuz1=vbuc1 
    lda #5
    sta.z max_digits
    jmp __b1
    // [1331] phi from utoa::@2 to utoa::@1 [phi:utoa::@2->utoa::@1]
  __b3:
    // [1331] phi utoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES [phi:utoa::@2->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_HEXADECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES
    sta.z digit_values+1
    // [1331] phi utoa::max_digits#7 = 4 [phi:utoa::@2->utoa::@1#1] -- vbuz1=vbuc1 
    lda #4
    sta.z max_digits
    jmp __b1
    // [1331] phi from utoa::@3 to utoa::@1 [phi:utoa::@3->utoa::@1]
  __b4:
    // [1331] phi utoa::digit_values#8 = RADIX_OCTAL_VALUES [phi:utoa::@3->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_OCTAL_VALUES
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES
    sta.z digit_values+1
    // [1331] phi utoa::max_digits#7 = 6 [phi:utoa::@3->utoa::@1#1] -- vbuz1=vbuc1 
    lda #6
    sta.z max_digits
    jmp __b1
    // [1331] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
  __b5:
    // [1331] phi utoa::digit_values#8 = RADIX_BINARY_VALUES [phi:utoa::@4->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_BINARY_VALUES
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES
    sta.z digit_values+1
    // [1331] phi utoa::max_digits#7 = $10 [phi:utoa::@4->utoa::@1#1] -- vbuz1=vbuc1 
    lda #$10
    sta.z max_digits
    // utoa::@1
  __b1:
    // [1332] phi from utoa::@1 to utoa::@6 [phi:utoa::@1->utoa::@6]
    // [1332] phi utoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa::@1->utoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1332] phi utoa::started#2 = 0 [phi:utoa::@1->utoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [1332] phi utoa::value#2 = utoa::value#1 [phi:utoa::@1->utoa::@6#2] -- register_copy 
    // [1332] phi utoa::digit#2 = 0 [phi:utoa::@1->utoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // utoa::@6
  __b6:
    // max_digits-1
    // [1333] utoa::$4 = utoa::max_digits#7 - 1 -- vbuz1=vbuz2_minus_1 
    ldx.z max_digits
    dex
    stx.z utoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1334] if(utoa::digit#2<utoa::$4) goto utoa::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z digit
    cmp.z utoa__4
    bcc __b7
    // utoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1335] utoa::$11 = (char)utoa::value#2 -- vbuz1=_byte_vwuz2 
    lda.z value
    sta.z utoa__11
    // [1336] *utoa::buffer#11 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1337] utoa::buffer#3 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1338] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // utoa::@7
  __b7:
    // unsigned int digit_value = digit_values[digit]
    // [1339] utoa::$10 = utoa::digit#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z digit
    asl
    sta.z utoa__10
    // [1340] utoa::digit_value#0 = utoa::digit_values#8[utoa::$10] -- vwuz1=pwuz2_derefidx_vbuz3 
    tay
    lda (digit_values),y
    sta.z digit_value
    iny
    lda (digit_values),y
    sta.z digit_value+1
    // if (started || value >= digit_value)
    // [1341] if(0!=utoa::started#2) goto utoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // utoa::@12
    // [1342] if(utoa::value#2>=utoa::digit_value#0) goto utoa::@10 -- vwuz1_ge_vwuz2_then_la1 
    lda.z digit_value+1
    cmp.z value+1
    bne !+
    lda.z digit_value
    cmp.z value
    beq __b10
  !:
    bcc __b10
    // [1343] phi from utoa::@12 to utoa::@9 [phi:utoa::@12->utoa::@9]
    // [1343] phi utoa::buffer#14 = utoa::buffer#11 [phi:utoa::@12->utoa::@9#0] -- register_copy 
    // [1343] phi utoa::started#4 = utoa::started#2 [phi:utoa::@12->utoa::@9#1] -- register_copy 
    // [1343] phi utoa::value#6 = utoa::value#2 [phi:utoa::@12->utoa::@9#2] -- register_copy 
    // utoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1344] utoa::digit#1 = ++ utoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1332] phi from utoa::@9 to utoa::@6 [phi:utoa::@9->utoa::@6]
    // [1332] phi utoa::buffer#11 = utoa::buffer#14 [phi:utoa::@9->utoa::@6#0] -- register_copy 
    // [1332] phi utoa::started#2 = utoa::started#4 [phi:utoa::@9->utoa::@6#1] -- register_copy 
    // [1332] phi utoa::value#2 = utoa::value#6 [phi:utoa::@9->utoa::@6#2] -- register_copy 
    // [1332] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@9->utoa::@6#3] -- register_copy 
    jmp __b6
    // utoa::@10
  __b10:
    // utoa_append(buffer++, value, digit_value)
    // [1345] utoa_append::buffer#0 = utoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [1346] utoa_append::value#0 = utoa::value#2
    // [1347] utoa_append::sub#0 = utoa::digit_value#0
    // [1348] call utoa_append
    // [1818] phi from utoa::@10 to utoa_append [phi:utoa::@10->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [1349] utoa_append::return#0 = utoa_append::value#2
    // utoa::@11
    // value = utoa_append(buffer++, value, digit_value)
    // [1350] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [1351] utoa::buffer#4 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1343] phi from utoa::@11 to utoa::@9 [phi:utoa::@11->utoa::@9]
    // [1343] phi utoa::buffer#14 = utoa::buffer#4 [phi:utoa::@11->utoa::@9#0] -- register_copy 
    // [1343] phi utoa::started#4 = 1 [phi:utoa::@11->utoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [1343] phi utoa::value#6 = utoa::value#0 [phi:utoa::@11->utoa::@9#2] -- register_copy 
    jmp __b9
}
  // printf_number_buffer
// Print the contents of the number buffer using a specific format.
// This handles minimum length, zero-filling, and left/right justification from the format
// void printf_number_buffer(__zp($b0) void (*putc)(char), __zp($b7) char buffer_sign, char *buffer_digits, __zp($bf) char format_min_length, char format_justify_left, char format_sign_always, __zp($bd) char format_zero_padding, char format_upper_case, char format_radix)
printf_number_buffer: {
    .label printf_number_buffer__19 = $46
    .label buffer_sign = $b7
    .label format_min_length = $bf
    .label format_zero_padding = $bd
    .label putc = $b0
    .label len = $b6
    .label padding = $b6
    // if(format.min_length)
    // [1353] if(0==printf_number_buffer::format_min_length#3) goto printf_number_buffer::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b5
    // [1354] phi from printf_number_buffer to printf_number_buffer::@5 [phi:printf_number_buffer->printf_number_buffer::@5]
    // printf_number_buffer::@5
    // strlen(buffer.digits)
    // [1355] call strlen
    // [1591] phi from printf_number_buffer::@5 to strlen [phi:printf_number_buffer::@5->strlen]
    // [1591] phi strlen::str#8 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [1356] strlen::return#3 = strlen::len#2
    // printf_number_buffer::@11
    // [1357] printf_number_buffer::$19 = strlen::return#3
    // signed char len = (signed char)strlen(buffer.digits)
    // [1358] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsz1=_sbyte_vwuz2 
    // There is a minimum length - work out the padding
    lda.z printf_number_buffer__19
    sta.z len
    // if(buffer.sign)
    // [1359] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@10 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b10
    // printf_number_buffer::@6
    // len++;
    // [1360] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsz1=_inc_vbsz1 
    inc.z len
    // [1361] phi from printf_number_buffer::@11 printf_number_buffer::@6 to printf_number_buffer::@10 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10]
    // [1361] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10#0] -- register_copy 
    // printf_number_buffer::@10
  __b10:
    // padding = (signed char)format.min_length - len
    // [1362] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#3 - printf_number_buffer::len#2 -- vbsz1=vbsz2_minus_vbsz1 
    lda.z format_min_length
    sec
    sbc.z padding
    sta.z padding
    // if(padding<0)
    // [1363] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@15 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1365] phi from printf_number_buffer printf_number_buffer::@10 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1]
  __b5:
    // [1365] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [1364] phi from printf_number_buffer::@10 to printf_number_buffer::@15 [phi:printf_number_buffer::@10->printf_number_buffer::@15]
    // printf_number_buffer::@15
    // [1365] phi from printf_number_buffer::@15 to printf_number_buffer::@1 [phi:printf_number_buffer::@15->printf_number_buffer::@1]
    // [1365] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@15->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // printf_number_buffer::@13
    // if(!format.justify_left && !format.zero_padding && padding)
    // [1366] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_zero_padding
    bne __b2
    // printf_number_buffer::@12
    // [1367] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@7 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b7
    jmp __b2
    // printf_number_buffer::@7
  __b7:
    // printf_padding(putc, ' ',(char)padding)
    // [1368] printf_padding::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1369] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1370] call printf_padding
    // [1597] phi from printf_number_buffer::@7 to printf_padding [phi:printf_number_buffer::@7->printf_padding]
    // [1597] phi printf_padding::putc#7 = printf_padding::putc#0 [phi:printf_number_buffer::@7->printf_padding#0] -- register_copy 
    // [1597] phi printf_padding::pad#7 = ' ' [phi:printf_number_buffer::@7->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1597] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@7->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [1371] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b3
    // printf_number_buffer::@8
    // putc(buffer.sign)
    // [1372] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbuz1 
    pha
    // [1373] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall24
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [1375] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbuz1_then_la1 
    lda.z format_zero_padding
    beq __b4
    // printf_number_buffer::@14
    // [1376] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@9 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b9
    jmp __b4
    // printf_number_buffer::@9
  __b9:
    // printf_padding(putc, '0',(char)padding)
    // [1377] printf_padding::putc#1 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1378] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1379] call printf_padding
    // [1597] phi from printf_number_buffer::@9 to printf_padding [phi:printf_number_buffer::@9->printf_padding]
    // [1597] phi printf_padding::putc#7 = printf_padding::putc#1 [phi:printf_number_buffer::@9->printf_padding#0] -- register_copy 
    // [1597] phi printf_padding::pad#7 = '0' [phi:printf_number_buffer::@9->printf_padding#1] -- vbuz1=vbuc1 
    lda #'0'
    sta.z printf_padding.pad
    // [1597] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@9->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // printf_str(putc, buffer.digits)
    // [1380] printf_str::putc#0 = printf_number_buffer::putc#10
    // [1381] call printf_str
    // [471] phi from printf_number_buffer::@4 to printf_str [phi:printf_number_buffer::@4->printf_str]
    // [471] phi printf_str::putc#52 = printf_str::putc#0 [phi:printf_number_buffer::@4->printf_str#0] -- register_copy 
    // [471] phi printf_str::s#52 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@return
    // }
    // [1382] return 
    rts
    // Outside Flow
  icall24:
    jmp (putc)
}
  // print_vera_led
// void print_vera_led(__zp($2b) char c)
print_vera_led: {
    .label c = $2b
    // print_chip_led(CHIP_VERA_X+1, CHIP_VERA_Y, CHIP_VERA_W, c, BLUE)
    // [1384] print_chip_led::tc#1 = print_vera_led::c#2
    // [1385] call print_chip_led
    // [1739] phi from print_vera_led to print_chip_led [phi:print_vera_led->print_chip_led]
    // [1739] phi print_chip_led::w#5 = 8 [phi:print_vera_led->print_chip_led#0] -- vbuz1=vbuc1 
    lda #8
    sta.z print_chip_led.w
    // [1739] phi print_chip_led::tc#3 = print_chip_led::tc#1 [phi:print_vera_led->print_chip_led#1] -- register_copy 
    // [1739] phi print_chip_led::x#3 = 9+1 [phi:print_vera_led->print_chip_led#2] -- vbuz1=vbuc1 
    lda #9+1
    sta.z print_chip_led.x
    jsr print_chip_led
    // print_vera_led::@return
    // }
    // [1386] return 
    rts
}
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(__zp($b0) void (*putc)(char), __zp($24) char uvalue, __zp($bf) char format_min_length, char format_justify_left, char format_sign_always, __zp($bd) char format_zero_padding, char format_upper_case, __zp($59) char format_radix)
printf_uchar: {
    .label uvalue = $24
    .label format_radix = $59
    .label putc = $b0
    .label format_min_length = $bf
    .label format_zero_padding = $bd
    // printf_uchar::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1388] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [1389] uctoa::value#1 = printf_uchar::uvalue#10
    // [1390] uctoa::radix#0 = printf_uchar::format_radix#10
    // [1391] call uctoa
    // Format number into buffer
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1392] printf_number_buffer::putc#2 = printf_uchar::putc#10
    // [1393] printf_number_buffer::buffer_sign#2 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [1394] printf_number_buffer::format_min_length#2 = printf_uchar::format_min_length#10
    // [1395] printf_number_buffer::format_zero_padding#2 = printf_uchar::format_zero_padding#10
    // [1396] call printf_number_buffer
  // Print using format
    // [1352] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [1352] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#2 [phi:printf_uchar::@2->printf_number_buffer#0] -- register_copy 
    // [1352] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#2 [phi:printf_uchar::@2->printf_number_buffer#1] -- register_copy 
    // [1352] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#2 [phi:printf_uchar::@2->printf_number_buffer#2] -- register_copy 
    // [1352] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#2 [phi:printf_uchar::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [1397] return 
    rts
}
  // strcat
// Concatenates the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcat(char *destination, __zp($53) char *source)
strcat: {
    .label strcat__0 = $46
    .label dst = $46
    .label src = $53
    .label source = $53
    // strlen(destination)
    // [1399] call strlen
    // [1591] phi from strcat to strlen [phi:strcat->strlen]
    // [1591] phi strlen::str#8 = chip_rom::rom [phi:strcat->strlen#0] -- pbuz1=pbuc1 
    lda #<chip_rom.rom
    sta.z strlen.str
    lda #>chip_rom.rom
    sta.z strlen.str+1
    jsr strlen
    // strlen(destination)
    // [1400] strlen::return#0 = strlen::len#2
    // strcat::@4
    // [1401] strcat::$0 = strlen::return#0
    // char* dst = destination + strlen(destination)
    // [1402] strcat::dst#0 = chip_rom::rom + strcat::$0 -- pbuz1=pbuc1_plus_vwuz1 
    lda.z dst
    clc
    adc #<chip_rom.rom
    sta.z dst
    lda.z dst+1
    adc #>chip_rom.rom
    sta.z dst+1
    // [1403] phi from strcat::@2 strcat::@4 to strcat::@1 [phi:strcat::@2/strcat::@4->strcat::@1]
    // [1403] phi strcat::dst#2 = strcat::dst#1 [phi:strcat::@2/strcat::@4->strcat::@1#0] -- register_copy 
    // [1403] phi strcat::src#2 = strcat::src#1 [phi:strcat::@2/strcat::@4->strcat::@1#1] -- register_copy 
    // strcat::@1
  __b1:
    // while(*src)
    // [1404] if(0!=*strcat::src#2) goto strcat::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcat::@3
    // *dst = 0
    // [1405] *strcat::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcat::@return
    // }
    // [1406] return 
    rts
    // strcat::@2
  __b2:
    // *dst++ = *src++
    // [1407] *strcat::dst#2 = *strcat::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [1408] strcat::dst#1 = ++ strcat::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [1409] strcat::src#1 = ++ strcat::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    jmp __b1
}
  // print_rom_led
// void print_rom_led(__zp($b8) char chip, __zp($2b) char c)
print_rom_led: {
    .label print_rom_led__0 = $b8
    .label chip = $b8
    .label c = $2b
    .label print_rom_led__4 = $5a
    .label print_rom_led__5 = $b8
    // chip*6
    // [1411] print_rom_led::$4 = print_rom_led::chip#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z chip
    asl
    sta.z print_rom_led__4
    // [1412] print_rom_led::$5 = print_rom_led::$4 + print_rom_led::chip#2 -- vbuz1=vbuz2_plus_vbuz1 
    lda.z print_rom_led__5
    clc
    adc.z print_rom_led__4
    sta.z print_rom_led__5
    // CHIP_ROM_X+chip*6
    // [1413] print_rom_led::$0 = print_rom_led::$5 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z print_rom_led__0
    // print_chip_led(CHIP_ROM_X+chip*6+1, CHIP_ROM_Y, CHIP_ROM_W, c, BLUE)
    // [1414] print_chip_led::x#2 = print_rom_led::$0 + $14+1 -- vbuz1=vbuz1_plus_vbuc1 
    lda #$14+1
    clc
    adc.z print_chip_led.x
    sta.z print_chip_led.x
    // [1415] print_chip_led::tc#2 = print_rom_led::c#2
    // [1416] call print_chip_led
    // [1739] phi from print_rom_led to print_chip_led [phi:print_rom_led->print_chip_led]
    // [1739] phi print_chip_led::w#5 = 3 [phi:print_rom_led->print_chip_led#0] -- vbuz1=vbuc1 
    lda #3
    sta.z print_chip_led.w
    // [1739] phi print_chip_led::tc#3 = print_chip_led::tc#2 [phi:print_rom_led->print_chip_led#1] -- register_copy 
    // [1739] phi print_chip_led::x#3 = print_chip_led::x#2 [phi:print_rom_led->print_chip_led#2] -- register_copy 
    jsr print_chip_led
    // print_rom_led::@return
    // }
    // [1417] return 
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
// __zp($51) struct $2 * fopen(__zp($a9) const char *path, const char *mode)
fopen: {
    .label fopen__4 = $7b
    .label fopen__9 = $7a
    .label fopen__15 = $4a
    .label fopen__16 = $f3
    .label fopen__26 = $4d
    .label fopen__28 = $da
    .label fopen__30 = $51
    .label cbm_k_setnam1_fopen__0 = $46
    .label sp = $b6
    .label stream = $51
    .label pathtoken = $a9
    .label pathpos = $5b
    .label pathpos_1 = $cf
    .label pathtoken_1 = $dd
    .label pathcmp = $24
    .label path = $a9
    // Parse path
    .label pathstep = $5c
    .label num = $ca
    .label cbm_k_readst1_return = $4a
    .label return = $51
    // unsigned char sp = __stdio_filecount
    // [1419] fopen::sp#0 = __stdio_filecount -- vbuz1=vbum2 
    lda __stdio_filecount
    sta.z sp
    // (unsigned int)sp | 0x8000
    // [1420] fopen::$30 = (unsigned int)fopen::sp#0 -- vwuz1=_word_vbuz2 
    sta.z fopen__30
    lda #0
    sta.z fopen__30+1
    // [1421] fopen::stream#0 = fopen::$30 | $8000 -- vwuz1=vwuz1_bor_vwuc1 
    lda.z stream
    ora #<$8000
    sta.z stream
    lda.z stream+1
    ora #>$8000
    sta.z stream+1
    // char pathpos = sp * __STDIO_FILECOUNT
    // [1422] fopen::pathpos#0 = fopen::sp#0 << 3 -- vbuz1=vbuz2_rol_3 
    lda.z sp
    asl
    asl
    asl
    sta.z pathpos
    // __logical = 0
    // [1423] ((char *)&__stdio_file+$100)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    ldy.z sp
    sta __stdio_file+$100,y
    // __device = 0
    // [1424] ((char *)&__stdio_file+$108)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$108,y
    // __channel = 0
    // [1425] ((char *)&__stdio_file+$110)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$110,y
    // [1426] fopen::pathtoken#21 = fopen::pathtoken#0 -- pbuz1=pbuz2 
    lda.z pathtoken
    sta.z pathtoken_1
    lda.z pathtoken+1
    sta.z pathtoken_1+1
    // [1427] fopen::pathpos#21 = fopen::pathpos#0 -- vbuz1=vbuz2 
    lda.z pathpos
    sta.z pathpos_1
    // [1428] phi from fopen to fopen::@8 [phi:fopen->fopen::@8]
    // [1428] phi fopen::num#10 = 0 [phi:fopen->fopen::@8#0] -- vbuz1=vbuc1 
    lda #0
    sta.z num
    // [1428] phi fopen::pathpos#10 = fopen::pathpos#21 [phi:fopen->fopen::@8#1] -- register_copy 
    // [1428] phi fopen::path#10 = fopen::pathtoken#0 [phi:fopen->fopen::@8#2] -- register_copy 
    // [1428] phi fopen::pathstep#10 = 0 [phi:fopen->fopen::@8#3] -- vbuz1=vbuc1 
    sta.z pathstep
    // [1428] phi fopen::pathtoken#10 = fopen::pathtoken#21 [phi:fopen->fopen::@8#4] -- register_copy 
  // Iterate while path is not \0.
    // [1428] phi from fopen::@22 to fopen::@8 [phi:fopen::@22->fopen::@8]
    // [1428] phi fopen::num#10 = fopen::num#13 [phi:fopen::@22->fopen::@8#0] -- register_copy 
    // [1428] phi fopen::pathpos#10 = fopen::pathpos#7 [phi:fopen::@22->fopen::@8#1] -- register_copy 
    // [1428] phi fopen::path#10 = fopen::path#11 [phi:fopen::@22->fopen::@8#2] -- register_copy 
    // [1428] phi fopen::pathstep#10 = fopen::pathstep#11 [phi:fopen::@22->fopen::@8#3] -- register_copy 
    // [1428] phi fopen::pathtoken#10 = fopen::pathtoken#1 [phi:fopen::@22->fopen::@8#4] -- register_copy 
    // fopen::@8
  __b8:
    // if (*pathtoken == ',' || *pathtoken == '\0')
    // [1429] if(*fopen::pathtoken#10==',') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #','
    ldy #0
    cmp (pathtoken_1),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@33
    // [1430] if(*fopen::pathtoken#10=='@') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #'@'
    cmp (pathtoken_1),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@23
    // if (pathstep == 0)
    // [1431] if(fopen::pathstep#10!=0) goto fopen::@10 -- vbuz1_neq_0_then_la1 
    lda.z pathstep
    bne __b10
    // fopen::@24
    // __stdio_file.filename[pathpos] = *pathtoken
    // [1432] ((char *)&__stdio_file)[fopen::pathpos#10] = *fopen::pathtoken#10 -- pbuc1_derefidx_vbuz1=_deref_pbuz2 
    lda (pathtoken_1),y
    ldy.z pathpos_1
    sta __stdio_file,y
    // pathpos++;
    // [1433] fopen::pathpos#1 = ++ fopen::pathpos#10 -- vbuz1=_inc_vbuz1 
    inc.z pathpos_1
    // [1434] phi from fopen::@12 fopen::@23 fopen::@24 to fopen::@10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10]
    // [1434] phi fopen::num#13 = fopen::num#15 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#0] -- register_copy 
    // [1434] phi fopen::pathpos#7 = fopen::pathpos#10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#1] -- register_copy 
    // [1434] phi fopen::path#11 = fopen::path#13 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#2] -- register_copy 
    // [1434] phi fopen::pathstep#11 = fopen::pathstep#1 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#3] -- register_copy 
    // fopen::@10
  __b10:
    // pathtoken++;
    // [1435] fopen::pathtoken#1 = ++ fopen::pathtoken#10 -- pbuz1=_inc_pbuz1 
    inc.z pathtoken_1
    bne !+
    inc.z pathtoken_1+1
  !:
    // fopen::@22
    // pathtoken - 1
    // [1436] fopen::$28 = fopen::pathtoken#1 - 1 -- pbuz1=pbuz2_minus_1 
    lda.z pathtoken_1
    sec
    sbc #1
    sta.z fopen__28
    lda.z pathtoken_1+1
    sbc #0
    sta.z fopen__28+1
    // while (*(pathtoken - 1))
    // [1437] if(0!=*fopen::$28) goto fopen::@8 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (fopen__28),y
    cmp #0
    bne __b8
    // fopen::@26
    // __status = 0
    // [1438] ((char *)&__stdio_file+$118)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    tya
    ldy.z sp
    sta __stdio_file+$118,y
    // if(!__logical)
    // [1439] if(0!=((char *)&__stdio_file+$100)[fopen::sp#0]) goto fopen::@1 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$100,y
    cmp #0
    bne __b1
    // fopen::@27
    // __stdio_filecount+1
    // [1440] fopen::$4 = __stdio_filecount + 1 -- vbuz1=vbum2_plus_1 
    lda __stdio_filecount
    inc
    sta.z fopen__4
    // __logical = __stdio_filecount+1
    // [1441] ((char *)&__stdio_file+$100)[fopen::sp#0] = fopen::$4 -- pbuc1_derefidx_vbuz1=vbuz2 
    sta __stdio_file+$100,y
    // fopen::@1
  __b1:
    // if(!__device)
    // [1442] if(0!=((char *)&__stdio_file+$108)[fopen::sp#0]) goto fopen::@2 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    ldy.z sp
    lda __stdio_file+$108,y
    cmp #0
    bne __b2
    // fopen::@5
    // __device = 8
    // [1443] ((char *)&__stdio_file+$108)[fopen::sp#0] = 8 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #8
    sta __stdio_file+$108,y
    // fopen::@2
  __b2:
    // if(!__channel)
    // [1444] if(0!=((char *)&__stdio_file+$110)[fopen::sp#0]) goto fopen::@3 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    ldy.z sp
    lda __stdio_file+$110,y
    cmp #0
    bne __b3
    // fopen::@6
    // __stdio_filecount+2
    // [1445] fopen::$9 = __stdio_filecount + 2 -- vbuz1=vbum2_plus_2 
    lda __stdio_filecount
    clc
    adc #2
    sta.z fopen__9
    // __channel = __stdio_filecount+2
    // [1446] ((char *)&__stdio_file+$110)[fopen::sp#0] = fopen::$9 -- pbuc1_derefidx_vbuz1=vbuz2 
    sta __stdio_file+$110,y
    // fopen::@3
  __b3:
    // __filename
    // [1447] fopen::$11 = (char *)&__stdio_file + fopen::pathpos#0 -- pbum1=pbuc1_plus_vbuz2 
    lda.z pathpos
    clc
    adc #<__stdio_file
    sta fopen__11
    lda #>__stdio_file
    adc #0
    sta fopen__11+1
    // cbm_k_setnam(__filename)
    // [1448] fopen::cbm_k_setnam1_filename = fopen::$11 -- pbum1=pbum2 
    lda fopen__11
    sta cbm_k_setnam1_filename
    lda fopen__11+1
    sta cbm_k_setnam1_filename+1
    // fopen::cbm_k_setnam1
    // strlen(filename)
    // [1449] strlen::str#4 = fopen::cbm_k_setnam1_filename -- pbuz1=pbum2 
    lda cbm_k_setnam1_filename
    sta.z strlen.str
    lda cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [1450] call strlen
    // [1591] phi from fopen::cbm_k_setnam1 to strlen [phi:fopen::cbm_k_setnam1->strlen]
    // [1591] phi strlen::str#8 = strlen::str#4 [phi:fopen::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [1451] strlen::return#11 = strlen::len#2
    // fopen::@31
    // [1452] fopen::cbm_k_setnam1_$0 = strlen::return#11
    // char filename_len = (char)strlen(filename)
    // [1453] fopen::cbm_k_setnam1_filename_len = (char)fopen::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
    lda.z cbm_k_setnam1_fopen__0
    sta cbm_k_setnam1_filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx cbm_k_setnam1_filename
    ldy cbm_k_setnam1_filename+1
    jsr CBM_SETNAM
    // fopen::@28
    // cbm_k_setlfs(__logical, __device, __channel)
    // [1455] cbm_k_setlfs::channel = ((char *)&__stdio_file+$100)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$100,y
    sta cbm_k_setlfs.channel
    // [1456] cbm_k_setlfs::device = ((char *)&__stdio_file+$108)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    lda __stdio_file+$108,y
    sta cbm_k_setlfs.device
    // [1457] cbm_k_setlfs::command = ((char *)&__stdio_file+$110)[fopen::sp#0] -- vbuz1=pbuc1_derefidx_vbuz2 
    lda __stdio_file+$110,y
    sta.z cbm_k_setlfs.command
    // [1458] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // fopen::cbm_k_open1
    // asm
    // asm { jsrCBM_OPEN  }
    jsr CBM_OPEN
    // fopen::cbm_k_readst1
    // char status
    // [1460] fopen::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [1462] fopen::cbm_k_readst1_return#0 = fopen::cbm_k_readst1_status -- vbuz1=vbum2 
    sta.z cbm_k_readst1_return
    // fopen::cbm_k_readst1_@return
    // }
    // [1463] fopen::cbm_k_readst1_return#1 = fopen::cbm_k_readst1_return#0
    // fopen::@29
    // cbm_k_readst()
    // [1464] fopen::$15 = fopen::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [1465] ((char *)&__stdio_file+$118)[fopen::sp#0] = fopen::$15 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fopen__15
    ldy.z sp
    sta __stdio_file+$118,y
    // ferror(stream)
    // [1466] ferror::stream#0 = (struct $2 *)fopen::stream#0
    // [1467] call ferror
    jsr ferror
    // [1468] ferror::return#0 = ferror::return#1
    // fopen::@32
    // [1469] fopen::$16 = ferror::return#0
    // if (ferror(stream))
    // [1470] if(0==fopen::$16) goto fopen::@4 -- 0_eq_vwsz1_then_la1 
    lda.z fopen__16
    ora.z fopen__16+1
    beq __b4
    // fopen::@7
    // cbm_k_close(__logical)
    // [1471] fopen::cbm_k_close1_channel = ((char *)&__stdio_file+$100)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$100,y
    sta cbm_k_close1_channel
    // fopen::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // [1473] phi from fopen::cbm_k_close1 to fopen::@return [phi:fopen::cbm_k_close1->fopen::@return]
    // [1473] phi fopen::return#2 = 0 [phi:fopen::cbm_k_close1->fopen::@return#0] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [1474] return 
    rts
    // fopen::@4
  __b4:
    // __stdio_filecount++;
    // [1475] __stdio_filecount = ++ __stdio_filecount -- vbum1=_inc_vbum1 
    inc __stdio_filecount
    // [1476] fopen::return#8 = (struct $2 *)fopen::stream#0
    // [1473] phi from fopen::@4 to fopen::@return [phi:fopen::@4->fopen::@return]
    // [1473] phi fopen::return#2 = fopen::return#8 [phi:fopen::@4->fopen::@return#0] -- register_copy 
    rts
    // fopen::@9
  __b9:
    // if (pathstep > 0)
    // [1477] if(fopen::pathstep#10>0) goto fopen::@11 -- vbuz1_gt_0_then_la1 
    lda.z pathstep
    bne __b11
    // fopen::@25
    // __stdio_file.filename[pathpos] = '\0'
    // [1478] ((char *)&__stdio_file)[fopen::pathpos#10] = '@' -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #'@'
    ldy.z pathpos_1
    sta __stdio_file,y
    // path = pathtoken + 1
    // [1479] fopen::path#0 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
    clc
    lda.z pathtoken_1
    adc #1
    sta.z path
    lda.z pathtoken_1+1
    adc #0
    sta.z path+1
    // [1480] phi from fopen::@16 fopen::@17 fopen::@18 fopen::@19 fopen::@25 to fopen::@12 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12]
    // [1480] phi fopen::num#15 = fopen::num#2 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#0] -- register_copy 
    // [1480] phi fopen::path#13 = fopen::path#16 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#1] -- register_copy 
    // fopen::@12
  __b12:
    // pathstep++;
    // [1481] fopen::pathstep#1 = ++ fopen::pathstep#10 -- vbuz1=_inc_vbuz1 
    inc.z pathstep
    jmp __b10
    // fopen::@11
  __b11:
    // char pathcmp = *path
    // [1482] fopen::pathcmp#0 = *fopen::path#10 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (path),y
    sta.z pathcmp
    // case 'D':
    // [1483] if(fopen::pathcmp#0=='D') goto fopen::@13 -- vbuz1_eq_vbuc1_then_la1 
    lda #'D'
    cmp.z pathcmp
    beq __b13
    // fopen::@20
    // case 'L':
    // [1484] if(fopen::pathcmp#0=='L') goto fopen::@13 -- vbuz1_eq_vbuc1_then_la1 
    lda #'L'
    cmp.z pathcmp
    beq __b13
    // fopen::@21
    // case 'C':
    //                     num = (char)atoi(path + 1);
    //                     path = pathtoken + 1;
    // [1485] if(fopen::pathcmp#0=='C') goto fopen::@13 -- vbuz1_eq_vbuc1_then_la1 
    lda #'C'
    cmp.z pathcmp
    beq __b13
    // [1486] phi from fopen::@21 fopen::@30 to fopen::@14 [phi:fopen::@21/fopen::@30->fopen::@14]
    // [1486] phi fopen::path#16 = fopen::path#10 [phi:fopen::@21/fopen::@30->fopen::@14#0] -- register_copy 
    // [1486] phi fopen::num#2 = fopen::num#10 [phi:fopen::@21/fopen::@30->fopen::@14#1] -- register_copy 
    // fopen::@14
  __b14:
    // case 'L':
    //                     __logical = num;
    //                     break;
    // [1487] if(fopen::pathcmp#0=='L') goto fopen::@17 -- vbuz1_eq_vbuc1_then_la1 
    lda #'L'
    cmp.z pathcmp
    beq __b17
    // fopen::@15
    // case 'D':
    //                     __device = num;
    //                     break;
    // [1488] if(fopen::pathcmp#0=='D') goto fopen::@18 -- vbuz1_eq_vbuc1_then_la1 
    lda #'D'
    cmp.z pathcmp
    beq __b18
    // fopen::@16
    // case 'C':
    //                     __channel = num;
    //                     break;
    // [1489] if(fopen::pathcmp#0!='C') goto fopen::@12 -- vbuz1_neq_vbuc1_then_la1 
    lda #'C'
    cmp.z pathcmp
    bne __b12
    // fopen::@19
    // __channel = num
    // [1490] ((char *)&__stdio_file+$110)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z num
    ldy.z sp
    sta __stdio_file+$110,y
    jmp __b12
    // fopen::@18
  __b18:
    // __device = num
    // [1491] ((char *)&__stdio_file+$108)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z num
    ldy.z sp
    sta __stdio_file+$108,y
    jmp __b12
    // fopen::@17
  __b17:
    // __logical = num
    // [1492] ((char *)&__stdio_file+$100)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z num
    ldy.z sp
    sta __stdio_file+$100,y
    jmp __b12
    // fopen::@13
  __b13:
    // atoi(path + 1)
    // [1493] atoi::str#0 = fopen::path#10 + 1 -- pbuz1=pbuz1_plus_1 
    inc.z atoi.str
    bne !+
    inc.z atoi.str+1
  !:
    // [1494] call atoi
    // [1907] phi from fopen::@13 to atoi [phi:fopen::@13->atoi]
    // [1907] phi atoi::str#2 = atoi::str#0 [phi:fopen::@13->atoi#0] -- register_copy 
    jsr atoi
    // atoi(path + 1)
    // [1495] atoi::return#3 = atoi::return#2
    // fopen::@30
    // [1496] fopen::$26 = atoi::return#3
    // num = (char)atoi(path + 1)
    // [1497] fopen::num#1 = (char)fopen::$26 -- vbuz1=_byte_vwsz2 
    lda.z fopen__26
    sta.z num
    // path = pathtoken + 1
    // [1498] fopen::path#1 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
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
    cbm_k_setnam1_filename: .word 0
    cbm_k_setnam1_filename_len: .byte 0
    cbm_k_readst1_status: .byte 0
    cbm_k_close1_channel: .byte 0
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
// __zp($6c) unsigned int fgets(__zp($4f) char *ptr, __zp($7e) unsigned int size, __zp($d2) struct $2 *stream)
fgets: {
    .label fgets__1 = $7a
    .label fgets__8 = $4a
    .label fgets__9 = $24
    .label fgets__13 = $59
    .label cbm_k_chkin1_channel = $cb
    .label cbm_k_chkin1_status = $c6
    .label cbm_k_readst1_status = $c7
    .label cbm_k_readst2_status = $69
    .label sp = $7b
    .label cbm_k_readst1_return = $7a
    .label return = $6c
    .label bytes = $43
    .label cbm_k_readst2_return = $4a
    .label read = $6c
    .label ptr = $4f
    .label remaining = $46
    .label stream = $d2
    .label size = $7e
    // unsigned char sp = (unsigned char)stream
    // [1500] fgets::sp#0 = (char)fgets::stream#2 -- vbuz1=_byte_pssz2 
    lda.z stream
    sta.z sp
    // cbm_k_chkin(__logical)
    // [1501] fgets::cbm_k_chkin1_channel = ((char *)&__stdio_file+$100)[fgets::sp#0] -- vbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda __stdio_file+$100,y
    sta.z cbm_k_chkin1_channel
    // fgets::cbm_k_chkin1
    // char status
    // [1502] fgets::cbm_k_chkin1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fgets::cbm_k_readst1
    // char status
    // [1504] fgets::cbm_k_readst1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [1506] fgets::cbm_k_readst1_return#0 = fgets::cbm_k_readst1_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst1_return
    // fgets::cbm_k_readst1_@return
    // }
    // [1507] fgets::cbm_k_readst1_return#1 = fgets::cbm_k_readst1_return#0
    // fgets::@11
    // cbm_k_readst()
    // [1508] fgets::$1 = fgets::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [1509] ((char *)&__stdio_file+$118)[fgets::sp#0] = fgets::$1 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fgets__1
    ldy.z sp
    sta __stdio_file+$118,y
    // if (__status)
    // [1510] if(0==((char *)&__stdio_file+$118)[fgets::sp#0]) goto fgets::@1 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$118,y
    cmp #0
    beq __b1
    // [1511] phi from fgets::@11 fgets::@12 fgets::@5 to fgets::@return [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return]
  __b8:
    // [1511] phi fgets::return#1 = 0 [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return#0] -- vwuz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fgets::@return
    // }
    // [1512] return 
    rts
    // fgets::@1
  __b1:
    // [1513] fgets::remaining#22 = fgets::size#10 -- vwuz1=vwuz2 
    lda.z size
    sta.z remaining
    lda.z size+1
    sta.z remaining+1
    // [1514] phi from fgets::@1 to fgets::@2 [phi:fgets::@1->fgets::@2]
    // [1514] phi fgets::read#10 = 0 [phi:fgets::@1->fgets::@2#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z read
    sta.z read+1
    // [1514] phi fgets::remaining#11 = fgets::remaining#22 [phi:fgets::@1->fgets::@2#1] -- register_copy 
    // [1514] phi fgets::ptr#10 = fgets::ptr#12 [phi:fgets::@1->fgets::@2#2] -- register_copy 
    // [1514] phi from fgets::@17 fgets::@18 to fgets::@2 [phi:fgets::@17/fgets::@18->fgets::@2]
    // [1514] phi fgets::read#10 = fgets::read#1 [phi:fgets::@17/fgets::@18->fgets::@2#0] -- register_copy 
    // [1514] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@17/fgets::@18->fgets::@2#1] -- register_copy 
    // [1514] phi fgets::ptr#10 = fgets::ptr#13 [phi:fgets::@17/fgets::@18->fgets::@2#2] -- register_copy 
    // fgets::@2
  __b2:
    // if (!size)
    // [1515] if(0==fgets::size#10) goto fgets::@3 -- 0_eq_vwuz1_then_la1 
    lda.z size
    ora.z size+1
    bne !__b3+
    jmp __b3
  !__b3:
    // fgets::@8
    // if (remaining >= 512)
    // [1516] if(fgets::remaining#11>=$200) goto fgets::@4 -- vwuz1_ge_vwuc1_then_la1 
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
    // [1517] cx16_k_macptr::bytes = fgets::remaining#11 -- vbuz1=vwuz2 
    lda.z remaining
    sta.z cx16_k_macptr.bytes
    // [1518] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [1519] call cx16_k_macptr
    jsr cx16_k_macptr
    // [1520] cx16_k_macptr::return#4 = cx16_k_macptr::return#1
    // fgets::@15
  __b15:
    // bytes = cx16_k_macptr(remaining, ptr)
    // [1521] fgets::bytes#3 = cx16_k_macptr::return#4
    // [1522] phi from fgets::@13 fgets::@14 fgets::@15 to fgets::cbm_k_readst2 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2]
    // [1522] phi fgets::bytes#10 = fgets::bytes#1 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2#0] -- register_copy 
    // fgets::cbm_k_readst2
    // char status
    // [1523] fgets::cbm_k_readst2_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [1525] fgets::cbm_k_readst2_return#0 = fgets::cbm_k_readst2_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst2_return
    // fgets::cbm_k_readst2_@return
    // }
    // [1526] fgets::cbm_k_readst2_return#1 = fgets::cbm_k_readst2_return#0
    // fgets::@12
    // cbm_k_readst()
    // [1527] fgets::$8 = fgets::cbm_k_readst2_return#1
    // __status = cbm_k_readst()
    // [1528] ((char *)&__stdio_file+$118)[fgets::sp#0] = fgets::$8 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fgets__8
    ldy.z sp
    sta __stdio_file+$118,y
    // __status & 0xBF
    // [1529] fgets::$9 = ((char *)&__stdio_file+$118)[fgets::sp#0] & $bf -- vbuz1=pbuc1_derefidx_vbuz2_band_vbuc2 
    lda #$bf
    and __stdio_file+$118,y
    sta.z fgets__9
    // if (__status & 0xBF)
    // [1530] if(0==fgets::$9) goto fgets::@5 -- 0_eq_vbuz1_then_la1 
    beq __b5
    jmp __b8
    // fgets::@5
  __b5:
    // if (bytes == 0xFFFF)
    // [1531] if(fgets::bytes#10!=$ffff) goto fgets::@6 -- vwuz1_neq_vwuc1_then_la1 
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
    // [1532] fgets::read#1 = fgets::read#10 + fgets::bytes#10 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z read
    adc.z bytes
    sta.z read
    lda.z read+1
    adc.z bytes+1
    sta.z read+1
    // ptr += bytes
    // [1533] fgets::ptr#0 = fgets::ptr#10 + fgets::bytes#10 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z ptr
    adc.z bytes
    sta.z ptr
    lda.z ptr+1
    adc.z bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [1534] fgets::$13 = byte1  fgets::ptr#0 -- vbuz1=_byte1_pbuz2 
    sta.z fgets__13
    // if (BYTE1(ptr) == 0xC0)
    // [1535] if(fgets::$13!=$c0) goto fgets::@7 -- vbuz1_neq_vbuc1_then_la1 
    lda #$c0
    cmp.z fgets__13
    bne __b7
    // fgets::@10
    // ptr -= 0x2000
    // [1536] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [1537] phi from fgets::@10 fgets::@6 to fgets::@7 [phi:fgets::@10/fgets::@6->fgets::@7]
    // [1537] phi fgets::ptr#13 = fgets::ptr#1 [phi:fgets::@10/fgets::@6->fgets::@7#0] -- register_copy 
    // fgets::@7
  __b7:
    // remaining -= bytes
    // [1538] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#10 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z remaining
    sec
    sbc.z bytes
    sta.z remaining
    lda.z remaining+1
    sbc.z bytes+1
    sta.z remaining+1
    // while ((__status == 0) && ((size && remaining) || !size))
    // [1539] if(((char *)&__stdio_file+$118)[fgets::sp#0]==0) goto fgets::@16 -- pbuc1_derefidx_vbuz1_eq_0_then_la1 
    ldy.z sp
    lda __stdio_file+$118,y
    cmp #0
    beq __b16
    // [1511] phi from fgets::@17 fgets::@7 to fgets::@return [phi:fgets::@17/fgets::@7->fgets::@return]
    // [1511] phi fgets::return#1 = fgets::read#1 [phi:fgets::@17/fgets::@7->fgets::@return#0] -- register_copy 
    rts
    // fgets::@16
  __b16:
    // while ((__status == 0) && ((size && remaining) || !size))
    // [1540] if(0==fgets::size#10) goto fgets::@17 -- 0_eq_vwuz1_then_la1 
    lda.z size
    ora.z size+1
    beq __b17
    // fgets::@18
    // [1541] if(0!=fgets::remaining#1) goto fgets::@2 -- 0_neq_vwuz1_then_la1 
    lda.z remaining
    ora.z remaining+1
    beq !__b2+
    jmp __b2
  !__b2:
    // fgets::@17
  __b17:
    // [1542] if(0==fgets::size#10) goto fgets::@2 -- 0_eq_vwuz1_then_la1 
    lda.z size
    ora.z size+1
    bne !__b2+
    jmp __b2
  !__b2:
    rts
    // fgets::@4
  __b4:
    // cx16_k_macptr(512, ptr)
    // [1543] cx16_k_macptr::bytes = $200 -- vbuz1=vwuc1 
    lda #<$200
    sta.z cx16_k_macptr.bytes
    // [1544] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [1545] call cx16_k_macptr
    jsr cx16_k_macptr
    // [1546] cx16_k_macptr::return#3 = cx16_k_macptr::return#1
    // fgets::@14
    // bytes = cx16_k_macptr(512, ptr)
    // [1547] fgets::bytes#2 = cx16_k_macptr::return#3
    jmp __b15
    // fgets::@3
  __b3:
    // cx16_k_macptr(0, ptr)
    // [1548] cx16_k_macptr::bytes = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cx16_k_macptr.bytes
    // [1549] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [1550] call cx16_k_macptr
    jsr cx16_k_macptr
    // [1551] cx16_k_macptr::return#2 = cx16_k_macptr::return#1
    // fgets::@13
    // bytes = cx16_k_macptr(0, ptr)
    // [1552] fgets::bytes#1 = cx16_k_macptr::return#2
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
// int fclose(__zp($51) struct $2 *stream)
fclose: {
    .label fclose__1 = $b8
    .label fclose__4 = $5c
    .label fclose__6 = $59
    .label sp = $59
    .label cbm_k_readst1_return = $b8
    .label cbm_k_readst2_return = $5c
    .label stream = $51
    // unsigned char sp = (unsigned char)stream
    // [1554] fclose::sp#0 = (char)fclose::stream#2 -- vbuz1=_byte_pssz2 
    lda.z stream
    sta.z sp
    // cbm_k_chkin(__logical)
    // [1555] fclose::cbm_k_chkin1_channel = ((char *)&__stdio_file+$100)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    tay
    lda __stdio_file+$100,y
    sta cbm_k_chkin1_channel
    // fclose::cbm_k_chkin1
    // char status
    // [1556] fclose::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fclose::cbm_k_readst1
    // char status
    // [1558] fclose::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [1560] fclose::cbm_k_readst1_return#0 = fclose::cbm_k_readst1_status -- vbuz1=vbum2 
    sta.z cbm_k_readst1_return
    // fclose::cbm_k_readst1_@return
    // }
    // [1561] fclose::cbm_k_readst1_return#1 = fclose::cbm_k_readst1_return#0
    // fclose::@3
    // cbm_k_readst()
    // [1562] fclose::$1 = fclose::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [1563] ((char *)&__stdio_file+$118)[fclose::sp#0] = fclose::$1 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fclose__1
    ldy.z sp
    sta __stdio_file+$118,y
    // if (__status)
    // [1564] if(0==((char *)&__stdio_file+$118)[fclose::sp#0]) goto fclose::@1 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$118,y
    cmp #0
    beq __b1
    // fclose::@return
    // }
    // [1565] return 
    rts
    // fclose::@1
  __b1:
    // cbm_k_close(__logical)
    // [1566] fclose::cbm_k_close1_channel = ((char *)&__stdio_file+$100)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$100,y
    sta cbm_k_close1_channel
    // fclose::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // fclose::cbm_k_readst2
    // char status
    // [1568] fclose::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [1570] fclose::cbm_k_readst2_return#0 = fclose::cbm_k_readst2_status -- vbuz1=vbum2 
    sta.z cbm_k_readst2_return
    // fclose::cbm_k_readst2_@return
    // }
    // [1571] fclose::cbm_k_readst2_return#1 = fclose::cbm_k_readst2_return#0
    // fclose::@4
    // cbm_k_readst()
    // [1572] fclose::$4 = fclose::cbm_k_readst2_return#1
    // __status = cbm_k_readst()
    // [1573] ((char *)&__stdio_file+$118)[fclose::sp#0] = fclose::$4 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fclose__4
    ldy.z sp
    sta __stdio_file+$118,y
    // if (__status)
    // [1574] if(0==((char *)&__stdio_file+$118)[fclose::sp#0]) goto fclose::@2 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$118,y
    cmp #0
    beq __b2
    rts
    // fclose::@2
  __b2:
    // __logical = 0
    // [1575] ((char *)&__stdio_file+$100)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    ldy.z sp
    sta __stdio_file+$100,y
    // __device = 0
    // [1576] ((char *)&__stdio_file+$108)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$108,y
    // __channel = 0
    // [1577] ((char *)&__stdio_file+$110)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$110,y
    // __filename
    // [1578] fclose::$6 = fclose::sp#0 << 3 -- vbuz1=vbuz1_rol_3 
    lda.z fclose__6
    asl
    asl
    asl
    sta.z fclose__6
    // *__filename = '\0'
    // [1579] ((char *)&__stdio_file)[fclose::$6] = '@' -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #'@'
    ldy.z fclose__6
    sta __stdio_file,y
    // __stdio_filecount--;
    // [1580] __stdio_filecount = -- __stdio_filecount -- vbum1=_dec_vbum1 
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
    .label return = $e8
    // __mem unsigned char ch
    // [1581] cbm_k_getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsrCBM_GETIN stach  }
    jsr CBM_GETIN
    sta ch
    // return ch;
    // [1583] cbm_k_getin::return#0 = cbm_k_getin::ch -- vbuz1=vbum2 
    sta.z return
    // cbm_k_getin::@return
    // }
    // [1584] cbm_k_getin::return#1 = cbm_k_getin::return#0
    // [1585] return 
    rts
  .segment Data
    ch: .byte 0
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
// __zp($29) unsigned int cx16_k_i2c_read_byte(__mem() volatile char device, __mem() volatile char offset)
cx16_k_i2c_read_byte: {
    .label result = $ed
    .label return = $29
    // unsigned int result
    // [1586] cx16_k_i2c_read_byte::result = 0 -- vwuz1=vwuc1 
    lda #<0
    sta.z result
    sta.z result+1
    // asm
    // asm { ldxdevice ldyoffset stzresult+1 jsrCX16_I2C_READ_BYTE staresult rolresult+1  }
    ldx device
    ldy offset
    stz result+1
    jsr CX16_I2C_READ_BYTE
    sta result
    rol result+1
    // return result;
    // [1588] cx16_k_i2c_read_byte::return#0 = cx16_k_i2c_read_byte::result -- vwuz1=vwuz2 
    sta.z return
    lda.z result+1
    sta.z return+1
    // cx16_k_i2c_read_byte::@return
    // }
    // [1589] cx16_k_i2c_read_byte::return#1 = cx16_k_i2c_read_byte::return#0
    // [1590] return 
    rts
  .segment Data
    device: .byte 0
    offset: .byte 0
}
.segment Code
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __zp($46) unsigned int strlen(__zp($43) char *str)
strlen: {
    .label return = $46
    .label len = $46
    .label str = $43
    // [1592] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [1592] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z len
    sta.z len+1
    // [1592] phi strlen::str#6 = strlen::str#8 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [1593] if(0!=*strlen::str#6) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [1594] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [1595] strlen::len#1 = ++ strlen::len#2 -- vwuz1=_inc_vwuz1 
    inc.z len
    bne !+
    inc.z len+1
  !:
    // str++;
    // [1596] strlen::str#1 = ++ strlen::str#6 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [1592] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [1592] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [1592] phi strlen::str#6 = strlen::str#1 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
}
  // printf_padding
// Print a padding char a number of times
// void printf_padding(__zp($43) void (*putc)(char), __zp($55) char pad, __zp($58) char length)
printf_padding: {
    .label i = $45
    .label putc = $43
    .label length = $58
    .label pad = $55
    // [1598] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [1598] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [1599] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z length
    bcc __b2
    // printf_padding::@return
    // }
    // [1600] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [1601] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbuz1 
    lda.z pad
    pha
    // [1602] callexecute *printf_padding::putc#7  -- call__deref_pprz1 
    jsr icall25
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [1604] printf_padding::i#1 = ++ printf_padding::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1598] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [1598] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
    jmp __b1
    // Outside Flow
  icall25:
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
// __zp($d6) unsigned long rom_address_from_bank(__zp($cc) char rom_bank)
rom_address_from_bank: {
    .label rom_address_from_bank__1 = $e4
    .label return = $e4
    .label rom_bank = $cc
    .label return_1 = $d6
    // ((unsigned long)(rom_bank)) << 14
    // [1606] rom_address_from_bank::$1 = (unsigned long)rom_address_from_bank::rom_bank#2 -- vduz1=_dword_vbuz2 
    lda.z rom_bank
    sta.z rom_address_from_bank__1
    lda #0
    sta.z rom_address_from_bank__1+1
    sta.z rom_address_from_bank__1+2
    sta.z rom_address_from_bank__1+3
    // [1607] rom_address_from_bank::return#0 = rom_address_from_bank::$1 << $e -- vduz1=vduz1_rol_vbuc1 
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
    // [1608] return 
    rts
}
  // ultoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void ultoa(__zp($25) unsigned long value, __zp($51) char *buffer, char radix)
ultoa: {
    .label ultoa__10 = $5c
    .label ultoa__11 = $b8
    .label digit_value = $31
    .label buffer = $51
    .label digit = $2e
    .label value = $25
    .label started = $5f
    // [1610] phi from ultoa to ultoa::@1 [phi:ultoa->ultoa::@1]
    // [1610] phi ultoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:ultoa->ultoa::@1#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1610] phi ultoa::started#2 = 0 [phi:ultoa->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [1610] phi ultoa::value#2 = ultoa::value#1 [phi:ultoa->ultoa::@1#2] -- register_copy 
    // [1610] phi ultoa::digit#2 = 0 [phi:ultoa->ultoa::@1#3] -- vbuz1=vbuc1 
    sta.z digit
    // ultoa::@1
  __b1:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1611] if(ultoa::digit#2<8-1) goto ultoa::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z digit
    cmp #8-1
    bcc __b2
    // ultoa::@3
    // *buffer++ = DIGITS[(char)value]
    // [1612] ultoa::$11 = (char)ultoa::value#2 -- vbuz1=_byte_vduz2 
    lda.z value
    sta.z ultoa__11
    // [1613] *ultoa::buffer#11 = DIGITS[ultoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1614] ultoa::buffer#3 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1615] *ultoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    // ultoa::@return
    // }
    // [1616] return 
    rts
    // ultoa::@2
  __b2:
    // unsigned long digit_value = digit_values[digit]
    // [1617] ultoa::$10 = ultoa::digit#2 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z digit
    asl
    asl
    sta.z ultoa__10
    // [1618] ultoa::digit_value#0 = RADIX_HEXADECIMAL_VALUES_LONG[ultoa::$10] -- vduz1=pduc1_derefidx_vbuz2 
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
    // [1619] if(0!=ultoa::started#2) goto ultoa::@5 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b5
    // ultoa::@7
    // [1620] if(ultoa::value#2>=ultoa::digit_value#0) goto ultoa::@5 -- vduz1_ge_vduz2_then_la1 
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
    // [1621] phi from ultoa::@7 to ultoa::@4 [phi:ultoa::@7->ultoa::@4]
    // [1621] phi ultoa::buffer#14 = ultoa::buffer#11 [phi:ultoa::@7->ultoa::@4#0] -- register_copy 
    // [1621] phi ultoa::started#4 = ultoa::started#2 [phi:ultoa::@7->ultoa::@4#1] -- register_copy 
    // [1621] phi ultoa::value#6 = ultoa::value#2 [phi:ultoa::@7->ultoa::@4#2] -- register_copy 
    // ultoa::@4
  __b4:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1622] ultoa::digit#1 = ++ ultoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1610] phi from ultoa::@4 to ultoa::@1 [phi:ultoa::@4->ultoa::@1]
    // [1610] phi ultoa::buffer#11 = ultoa::buffer#14 [phi:ultoa::@4->ultoa::@1#0] -- register_copy 
    // [1610] phi ultoa::started#2 = ultoa::started#4 [phi:ultoa::@4->ultoa::@1#1] -- register_copy 
    // [1610] phi ultoa::value#2 = ultoa::value#6 [phi:ultoa::@4->ultoa::@1#2] -- register_copy 
    // [1610] phi ultoa::digit#2 = ultoa::digit#1 [phi:ultoa::@4->ultoa::@1#3] -- register_copy 
    jmp __b1
    // ultoa::@5
  __b5:
    // ultoa_append(buffer++, value, digit_value)
    // [1623] ultoa_append::buffer#0 = ultoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z ultoa_append.buffer
    lda.z buffer+1
    sta.z ultoa_append.buffer+1
    // [1624] ultoa_append::value#0 = ultoa::value#2
    // [1625] ultoa_append::sub#0 = ultoa::digit_value#0
    // [1626] call ultoa_append
    // [1928] phi from ultoa::@5 to ultoa_append [phi:ultoa::@5->ultoa_append]
    jsr ultoa_append
    // ultoa_append(buffer++, value, digit_value)
    // [1627] ultoa_append::return#0 = ultoa_append::value#2
    // ultoa::@6
    // value = ultoa_append(buffer++, value, digit_value)
    // [1628] ultoa::value#0 = ultoa_append::return#0
    // value = ultoa_append(buffer++, value, digit_value);
    // [1629] ultoa::buffer#4 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1621] phi from ultoa::@6 to ultoa::@4 [phi:ultoa::@6->ultoa::@4]
    // [1621] phi ultoa::buffer#14 = ultoa::buffer#4 [phi:ultoa::@6->ultoa::@4#0] -- register_copy 
    // [1621] phi ultoa::started#4 = 1 [phi:ultoa::@6->ultoa::@4#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [1621] phi ultoa::value#6 = ultoa::value#0 [phi:ultoa::@6->ultoa::@4#2] -- register_copy 
    jmp __b4
}
  // rom_compare
// __zp($43) unsigned int rom_compare(__zp($b7) char bank_ram, __zp($6c) char *ptr_ram, __zp($df) unsigned long rom_compare_address, unsigned int rom_compare_size)
rom_compare: {
    .label rom_compare__5 = $af
    .label rom_bank1_rom_compare__0 = $cf
    .label rom_bank1_rom_compare__1 = $ca
    .label rom_bank1_rom_compare__2 = $cd
    .label rom_ptr1_rom_compare__0 = $ad
    .label rom_ptr1_rom_compare__2 = $ad
    .label rom_bank1_bank_unshifted = $cd
    .label rom_bank1_return = $58
    .label rom_ptr1_return = $ad
    .label ptr_rom = $ad
    .label ptr_ram = $6c
    .label compared_bytes = $b2
    /// Holds the amount of bytes actually verified between the ROM and the RAM.
    .label difference_bytes = $43
    .label bank_ram = $b7
    .label rom_compare_address = $df
    .label return = $43
    // rom_compare::bank_set_bram1
    // BRAM = bank
    // [1631] BRAM = rom_compare::bank_ram#0 -- vbuz1=vbuz2 
    lda.z bank_ram
    sta.z BRAM
    // rom_compare::rom_bank1
    // BYTE2(address)
    // [1632] rom_compare::rom_bank1_$0 = byte2  rom_compare::rom_compare_address#0 -- vbuz1=_byte2_vduz2 
    lda.z rom_compare_address+2
    sta.z rom_bank1_rom_compare__0
    // BYTE1(address)
    // [1633] rom_compare::rom_bank1_$1 = byte1  rom_compare::rom_compare_address#0 -- vbuz1=_byte1_vduz2 
    lda.z rom_compare_address+1
    sta.z rom_bank1_rom_compare__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [1634] rom_compare::rom_bank1_$2 = rom_compare::rom_bank1_$0 w= rom_compare::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_compare__0
    sta.z rom_bank1_rom_compare__2+1
    lda.z rom_bank1_rom_compare__1
    sta.z rom_bank1_rom_compare__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [1635] rom_compare::rom_bank1_bank_unshifted#0 = rom_compare::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [1636] rom_compare::rom_bank1_return#0 = byte1  rom_compare::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwuz2 
    lda.z rom_bank1_bank_unshifted+1
    sta.z rom_bank1_return
    // rom_compare::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [1637] rom_compare::rom_ptr1_$2 = (unsigned int)rom_compare::rom_compare_address#0 -- vwuz1=_word_vduz2 
    lda.z rom_compare_address
    sta.z rom_ptr1_rom_compare__2
    lda.z rom_compare_address+1
    sta.z rom_ptr1_rom_compare__2+1
    // [1638] rom_compare::rom_ptr1_$0 = rom_compare::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_compare__0
    and #<$3fff
    sta.z rom_ptr1_rom_compare__0
    lda.z rom_ptr1_rom_compare__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_compare__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [1639] rom_compare::rom_ptr1_return#0 = rom_compare::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_compare::bank_set_brom1
    // BROM = bank
    // [1640] BROM = rom_compare::rom_bank1_return#0 -- vbuz1=vbuz2 
    lda.z rom_bank1_return
    sta.z BROM
    // [1641] rom_compare::ptr_rom#9 = (char *)rom_compare::rom_ptr1_return#0
    // [1642] phi from rom_compare::bank_set_brom1 to rom_compare::@1 [phi:rom_compare::bank_set_brom1->rom_compare::@1]
    // [1642] phi rom_compare::difference_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z difference_bytes
    sta.z difference_bytes+1
    // [1642] phi rom_compare::ptr_ram#2 = rom_compare::ptr_ram#1 [phi:rom_compare::bank_set_brom1->rom_compare::@1#1] -- register_copy 
    // [1642] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#9 [phi:rom_compare::bank_set_brom1->rom_compare::@1#2] -- register_copy 
    // [1642] phi rom_compare::compared_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#3] -- vwuz1=vwuc1 
    sta.z compared_bytes
    sta.z compared_bytes+1
    // rom_compare::@1
  __b1:
    // while (compared_bytes < rom_compare_size)
    // [1643] if(rom_compare::compared_bytes#2<PROGRESS_CELL) goto rom_compare::@2 -- vwuz1_lt_vwuc1_then_la1 
    lda.z compared_bytes+1
    cmp #>PROGRESS_CELL
    bcc __b2
    bne !+
    lda.z compared_bytes
    cmp #<PROGRESS_CELL
    bcc __b2
  !:
    // rom_compare::@return
    // }
    // [1644] return 
    rts
    // rom_compare::@2
  __b2:
    // rom_byte_compare(ptr_rom, *ptr_ram)
    // [1645] rom_byte_compare::ptr_rom#0 = rom_compare::ptr_rom#2
    // [1646] rom_byte_compare::value#0 = *rom_compare::ptr_ram#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (ptr_ram),y
    sta.z rom_byte_compare.value
    // [1647] call rom_byte_compare
    jsr rom_byte_compare
    // [1648] rom_byte_compare::return#2 = rom_byte_compare::return#0
    // rom_compare::@5
    // [1649] rom_compare::$5 = rom_byte_compare::return#2
    // if (!rom_byte_compare(ptr_rom, *ptr_ram))
    // [1650] if(0!=rom_compare::$5) goto rom_compare::@3 -- 0_neq_vbuz1_then_la1 
    lda.z rom_compare__5
    bne __b3
    // rom_compare::@4
    // difference_bytes++;
    // [1651] rom_compare::difference_bytes#1 = ++ rom_compare::difference_bytes#2 -- vwuz1=_inc_vwuz1 
    inc.z difference_bytes
    bne !+
    inc.z difference_bytes+1
  !:
    // [1652] phi from rom_compare::@4 rom_compare::@5 to rom_compare::@3 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3]
    // [1652] phi rom_compare::difference_bytes#6 = rom_compare::difference_bytes#1 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3#0] -- register_copy 
    // rom_compare::@3
  __b3:
    // ptr_rom++;
    // [1653] rom_compare::ptr_rom#1 = ++ rom_compare::ptr_rom#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr_rom
    bne !+
    inc.z ptr_rom+1
  !:
    // ptr_ram++;
    // [1654] rom_compare::ptr_ram#0 = ++ rom_compare::ptr_ram#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr_ram
    bne !+
    inc.z ptr_ram+1
  !:
    // compared_bytes++;
    // [1655] rom_compare::compared_bytes#1 = ++ rom_compare::compared_bytes#2 -- vwuz1=_inc_vwuz1 
    inc.z compared_bytes
    bne !+
    inc.z compared_bytes+1
  !:
    // [1642] phi from rom_compare::@3 to rom_compare::@1 [phi:rom_compare::@3->rom_compare::@1]
    // [1642] phi rom_compare::difference_bytes#2 = rom_compare::difference_bytes#6 [phi:rom_compare::@3->rom_compare::@1#0] -- register_copy 
    // [1642] phi rom_compare::ptr_ram#2 = rom_compare::ptr_ram#0 [phi:rom_compare::@3->rom_compare::@1#1] -- register_copy 
    // [1642] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#1 [phi:rom_compare::@3->rom_compare::@1#2] -- register_copy 
    // [1642] phi rom_compare::compared_bytes#2 = rom_compare::compared_bytes#1 [phi:rom_compare::@3->rom_compare::@1#3] -- register_copy 
    jmp __b1
}
  // insertup
// Insert a new line, and scroll the upper part of the screen up.
// void insertup(char rows)
insertup: {
    .label insertup__0 = $42
    .label insertup__4 = $40
    .label insertup__6 = $41
    .label insertup__7 = $40
    .label width = $42
    .label y = $3d
    // __conio.width+1
    // [1656] insertup::$0 = *((char *)&__conio+6) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+6
    inc
    sta.z insertup__0
    // unsigned char width = (__conio.width+1) * 2
    // [1657] insertup::width#0 = insertup::$0 << 1 -- vbuz1=vbuz1_rol_1 
    // {asm{.byte $db}}
    asl.z width
    // [1658] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [1658] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [1659] if(insertup::y#2<*((char *)&__conio+1)) goto insertup::@2 -- vbuz1_lt__deref_pbuc1_then_la1 
    lda.z y
    cmp __conio+1
    bcc __b2
    // [1660] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [1661] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [1662] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [1663] insertup::$4 = insertup::y#2 + 1 -- vbuz1=vbuz2_plus_1 
    lda.z y
    inc
    sta.z insertup__4
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [1664] insertup::$6 = insertup::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z insertup__6
    // [1665] insertup::$7 = insertup::$4 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z insertup__7
    // [1666] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z memcpy8_vram_vram.dbank_vram
    // [1667] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__6
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.doffset_vram+1
    // [1668] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z memcpy8_vram_vram.sbank_vram
    // [1669] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__7
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.soffset_vram+1
    // [1670] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbuz1=vbuz2 
    lda.z width
    sta.z memcpy8_vram_vram.num8_1
    // [1671] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [1672] insertup::y#1 = ++ insertup::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [1658] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [1658] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
    jmp __b1
}
  // clearline
clearline: {
    .label clearline__0 = $35
    .label clearline__1 = $37
    .label clearline__2 = $38
    .label clearline__3 = $36
    .label addr = $3e
    .label c = $22
    // unsigned int addr = __conio.offsets[__conio.cursor_y]
    // [1673] clearline::$3 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z clearline__3
    // [1674] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwuz1=pwuc1_derefidx_vbuz2 
    tay
    lda __conio+$15,y
    sta.z addr
    lda __conio+$15+1,y
    sta.z addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1675] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [1676] clearline::$0 = byte0  clearline::addr#0 -- vbuz1=_byte0_vwuz2 
    lda.z addr
    sta.z clearline__0
    // *VERA_ADDRX_L = BYTE0(addr)
    // [1677] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [1678] clearline::$1 = byte1  clearline::addr#0 -- vbuz1=_byte1_vwuz2 
    lda.z addr+1
    sta.z clearline__1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [1679] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [1680] clearline::$2 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clearline__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1681] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [1682] clearline::c#0 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z c
    // [1683] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [1683] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [1684] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1685] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [1686] clearline::c#1 = -- clearline::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [1687] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b1
    // clearline::@return
    // }
    // [1688] return 
    rts
}
  // frame_maskxy
// __zp($dc) char frame_maskxy(__zp($d4) char x, __zp($d5) char y)
frame_maskxy: {
    .label cpeekcxy1_cpeekc1_frame_maskxy__0 = $cf
    .label cpeekcxy1_cpeekc1_frame_maskxy__1 = $ca
    .label cpeekcxy1_cpeekc1_frame_maskxy__2 = $58
    .label cpeekcxy1_x = $d4
    .label cpeekcxy1_y = $d5
    .label c = $45
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
    .label return = $dc
    .label x = $d4
    .label y = $d5
    // frame_maskxy::cpeekcxy1
    // gotoxy(x,y)
    // [1690] gotoxy::x#5 = frame_maskxy::cpeekcxy1_x#0 -- vbuz1=vbuz2 
    lda.z cpeekcxy1_x
    sta.z gotoxy.x
    // [1691] gotoxy::y#5 = frame_maskxy::cpeekcxy1_y#0 -- vbuz1=vbuz2 
    lda.z cpeekcxy1_y
    sta.z gotoxy.y
    // [1692] call gotoxy
    // [334] phi from frame_maskxy::cpeekcxy1 to gotoxy [phi:frame_maskxy::cpeekcxy1->gotoxy]
    // [334] phi gotoxy::y#22 = gotoxy::y#5 [phi:frame_maskxy::cpeekcxy1->gotoxy#0] -- register_copy 
    // [334] phi gotoxy::x#22 = gotoxy::x#5 [phi:frame_maskxy::cpeekcxy1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // frame_maskxy::cpeekcxy1_cpeekc1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1693] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [1694] frame_maskxy::cpeekcxy1_cpeekc1_$0 = byte0  *((unsigned int *)&__conio+$13) -- vbuz1=_byte0__deref_pwuc1 
    lda __conio+$13
    sta.z cpeekcxy1_cpeekc1_frame_maskxy__0
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [1695] *VERA_ADDRX_L = frame_maskxy::cpeekcxy1_cpeekc1_$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [1696] frame_maskxy::cpeekcxy1_cpeekc1_$1 = byte1  *((unsigned int *)&__conio+$13) -- vbuz1=_byte1__deref_pwuc1 
    lda __conio+$13+1
    sta.z cpeekcxy1_cpeekc1_frame_maskxy__1
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [1697] *VERA_ADDRX_M = frame_maskxy::cpeekcxy1_cpeekc1_$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_0
    // [1698] frame_maskxy::cpeekcxy1_cpeekc1_$2 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z cpeekcxy1_cpeekc1_frame_maskxy__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_0
    // [1699] *VERA_ADDRX_H = frame_maskxy::cpeekcxy1_cpeekc1_$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // return *VERA_DATA0;
    // [1700] frame_maskxy::c#0 = *VERA_DATA0 -- vbuz1=_deref_pbuc1 
    lda VERA_DATA0
    sta.z c
    // frame_maskxy::@12
    // case 0x70: // DR corner.
    //             return 0b0110;
    // [1701] if(frame_maskxy::c#0==$70) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$70
    cmp.z c
    beq __b2
    // frame_maskxy::@1
    // case 0x6E: // DL corner.
    //             return 0b0011;
    // [1702] if(frame_maskxy::c#0==$6e) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6e
    cmp.z c
    beq __b1
    // frame_maskxy::@2
    // case 0x6D: // UR corner.
    //             return 0b1100;
    // [1703] if(frame_maskxy::c#0==$6d) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6d
    cmp.z c
    beq __b3
    // frame_maskxy::@3
    // case 0x7D: // UL corner.
    //             return 0b1001;
    // [1704] if(frame_maskxy::c#0==$7d) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$7d
    cmp.z c
    beq __b4
    // frame_maskxy::@4
    // case 0x40: // HL line.
    //             return 0b0101;
    // [1705] if(frame_maskxy::c#0==$40) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$40
    cmp.z c
    beq __b5
    // frame_maskxy::@5
    // case 0x5D: // VL line.
    //             return 0b1010;
    // [1706] if(frame_maskxy::c#0==$5d) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$5d
    cmp.z c
    beq __b6
    // frame_maskxy::@6
    // case 0x6B: // VR junction.
    //             return 0b1110;
    // [1707] if(frame_maskxy::c#0==$6b) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6b
    cmp.z c
    beq __b7
    // frame_maskxy::@7
    // case 0x73: // VL junction.
    //             return 0b1011;
    // [1708] if(frame_maskxy::c#0==$73) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$73
    cmp.z c
    beq __b8
    // frame_maskxy::@8
    // case 0x72: // HD junction.
    //             return 0b0111;
    // [1709] if(frame_maskxy::c#0==$72) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$72
    cmp.z c
    beq __b9
    // frame_maskxy::@9
    // case 0x71: // HU junction.
    //             return 0b1101;
    // [1710] if(frame_maskxy::c#0==$71) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$71
    cmp.z c
    beq __b10
    // frame_maskxy::@10
    // case 0x5B: // HV junction.
    //             return 0b1111;
    // [1711] if(frame_maskxy::c#0==$5b) goto frame_maskxy::@11 -- vbuz1_eq_vbuc1_then_la1 
    lda #$5b
    cmp.z c
    beq __b11
    // [1713] phi from frame_maskxy::@10 to frame_maskxy::@return [phi:frame_maskxy::@10->frame_maskxy::@return]
    // [1713] phi frame_maskxy::return#12 = 0 [phi:frame_maskxy::@10->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #0
    sta.z return
    rts
    // [1712] phi from frame_maskxy::@10 to frame_maskxy::@11 [phi:frame_maskxy::@10->frame_maskxy::@11]
    // frame_maskxy::@11
  __b11:
    // [1713] phi from frame_maskxy::@11 to frame_maskxy::@return [phi:frame_maskxy::@11->frame_maskxy::@return]
    // [1713] phi frame_maskxy::return#12 = $f [phi:frame_maskxy::@11->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$f
    sta.z return
    rts
    // [1713] phi from frame_maskxy::@1 to frame_maskxy::@return [phi:frame_maskxy::@1->frame_maskxy::@return]
  __b1:
    // [1713] phi frame_maskxy::return#12 = 3 [phi:frame_maskxy::@1->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #3
    sta.z return
    rts
    // [1713] phi from frame_maskxy::@12 to frame_maskxy::@return [phi:frame_maskxy::@12->frame_maskxy::@return]
  __b2:
    // [1713] phi frame_maskxy::return#12 = 6 [phi:frame_maskxy::@12->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #6
    sta.z return
    rts
    // [1713] phi from frame_maskxy::@2 to frame_maskxy::@return [phi:frame_maskxy::@2->frame_maskxy::@return]
  __b3:
    // [1713] phi frame_maskxy::return#12 = $c [phi:frame_maskxy::@2->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$c
    sta.z return
    rts
    // [1713] phi from frame_maskxy::@3 to frame_maskxy::@return [phi:frame_maskxy::@3->frame_maskxy::@return]
  __b4:
    // [1713] phi frame_maskxy::return#12 = 9 [phi:frame_maskxy::@3->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #9
    sta.z return
    rts
    // [1713] phi from frame_maskxy::@4 to frame_maskxy::@return [phi:frame_maskxy::@4->frame_maskxy::@return]
  __b5:
    // [1713] phi frame_maskxy::return#12 = 5 [phi:frame_maskxy::@4->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #5
    sta.z return
    rts
    // [1713] phi from frame_maskxy::@5 to frame_maskxy::@return [phi:frame_maskxy::@5->frame_maskxy::@return]
  __b6:
    // [1713] phi frame_maskxy::return#12 = $a [phi:frame_maskxy::@5->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$a
    sta.z return
    rts
    // [1713] phi from frame_maskxy::@6 to frame_maskxy::@return [phi:frame_maskxy::@6->frame_maskxy::@return]
  __b7:
    // [1713] phi frame_maskxy::return#12 = $e [phi:frame_maskxy::@6->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$e
    sta.z return
    rts
    // [1713] phi from frame_maskxy::@7 to frame_maskxy::@return [phi:frame_maskxy::@7->frame_maskxy::@return]
  __b8:
    // [1713] phi frame_maskxy::return#12 = $b [phi:frame_maskxy::@7->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$b
    sta.z return
    rts
    // [1713] phi from frame_maskxy::@8 to frame_maskxy::@return [phi:frame_maskxy::@8->frame_maskxy::@return]
  __b9:
    // [1713] phi frame_maskxy::return#12 = 7 [phi:frame_maskxy::@8->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #7
    sta.z return
    rts
    // [1713] phi from frame_maskxy::@9 to frame_maskxy::@return [phi:frame_maskxy::@9->frame_maskxy::@return]
  __b10:
    // [1713] phi frame_maskxy::return#12 = $d [phi:frame_maskxy::@9->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$d
    sta.z return
    // frame_maskxy::@return
    // }
    // [1714] return 
    rts
}
  // frame_char
// __zp($55) char frame_char(__zp($dc) char mask)
frame_char: {
    .label return = $55
    .label mask = $dc
    // case 0b0110:
    //             return 0x70;
    // [1716] if(frame_char::mask#10==6) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #6
    cmp.z mask
    beq __b1
    // frame_char::@1
    // case 0b0011:
    //             return 0x6E;
    // [1717] if(frame_char::mask#10==3) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // DR corner.
    lda #3
    cmp.z mask
    beq __b2
    // frame_char::@2
    // case 0b1100:
    //             return 0x6D;
    // [1718] if(frame_char::mask#10==$c) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // DL corner.
    lda #$c
    cmp.z mask
    beq __b3
    // frame_char::@3
    // case 0b1001:
    //             return 0x7D;
    // [1719] if(frame_char::mask#10==9) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // UR corner.
    lda #9
    cmp.z mask
    beq __b4
    // frame_char::@4
    // case 0b0101:
    //             return 0x40;
    // [1720] if(frame_char::mask#10==5) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // UL corner.
    lda #5
    cmp.z mask
    beq __b5
    // frame_char::@5
    // case 0b1010:
    //             return 0x5D;
    // [1721] if(frame_char::mask#10==$a) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // HL line.
    lda #$a
    cmp.z mask
    beq __b6
    // frame_char::@6
    // case 0b1110:
    //             return 0x6B;
    // [1722] if(frame_char::mask#10==$e) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VL line.
    lda #$e
    cmp.z mask
    beq __b7
    // frame_char::@7
    // case 0b1011:
    //             return 0x73;
    // [1723] if(frame_char::mask#10==$b) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VR junction.
    lda #$b
    cmp.z mask
    beq __b8
    // frame_char::@8
    // case 0b0111:
    //             return 0x72;
    // [1724] if(frame_char::mask#10==7) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VL junction.
    lda #7
    cmp.z mask
    beq __b9
    // frame_char::@9
    // case 0b1101:
    //             return 0x71;
    // [1725] if(frame_char::mask#10==$d) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // HD junction.
    lda #$d
    cmp.z mask
    beq __b10
    // frame_char::@10
    // case 0b1111:
    //             return 0x5B;
    // [1726] if(frame_char::mask#10==$f) goto frame_char::@11 -- vbuz1_eq_vbuc1_then_la1 
    // HU junction.
    lda #$f
    cmp.z mask
    beq __b11
    // [1728] phi from frame_char::@10 to frame_char::@return [phi:frame_char::@10->frame_char::@return]
    // [1728] phi frame_char::return#12 = $20 [phi:frame_char::@10->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$20
    sta.z return
    rts
    // [1727] phi from frame_char::@10 to frame_char::@11 [phi:frame_char::@10->frame_char::@11]
    // frame_char::@11
  __b11:
    // [1728] phi from frame_char::@11 to frame_char::@return [phi:frame_char::@11->frame_char::@return]
    // [1728] phi frame_char::return#12 = $5b [phi:frame_char::@11->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z return
    rts
    // [1728] phi from frame_char to frame_char::@return [phi:frame_char->frame_char::@return]
  __b1:
    // [1728] phi frame_char::return#12 = $70 [phi:frame_char->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$70
    sta.z return
    rts
    // [1728] phi from frame_char::@1 to frame_char::@return [phi:frame_char::@1->frame_char::@return]
  __b2:
    // [1728] phi frame_char::return#12 = $6e [phi:frame_char::@1->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6e
    sta.z return
    rts
    // [1728] phi from frame_char::@2 to frame_char::@return [phi:frame_char::@2->frame_char::@return]
  __b3:
    // [1728] phi frame_char::return#12 = $6d [phi:frame_char::@2->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6d
    sta.z return
    rts
    // [1728] phi from frame_char::@3 to frame_char::@return [phi:frame_char::@3->frame_char::@return]
  __b4:
    // [1728] phi frame_char::return#12 = $7d [phi:frame_char::@3->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$7d
    sta.z return
    rts
    // [1728] phi from frame_char::@4 to frame_char::@return [phi:frame_char::@4->frame_char::@return]
  __b5:
    // [1728] phi frame_char::return#12 = $40 [phi:frame_char::@4->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z return
    rts
    // [1728] phi from frame_char::@5 to frame_char::@return [phi:frame_char::@5->frame_char::@return]
  __b6:
    // [1728] phi frame_char::return#12 = $5d [phi:frame_char::@5->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z return
    rts
    // [1728] phi from frame_char::@6 to frame_char::@return [phi:frame_char::@6->frame_char::@return]
  __b7:
    // [1728] phi frame_char::return#12 = $6b [phi:frame_char::@6->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z return
    rts
    // [1728] phi from frame_char::@7 to frame_char::@return [phi:frame_char::@7->frame_char::@return]
  __b8:
    // [1728] phi frame_char::return#12 = $73 [phi:frame_char::@7->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z return
    rts
    // [1728] phi from frame_char::@8 to frame_char::@return [phi:frame_char::@8->frame_char::@return]
  __b9:
    // [1728] phi frame_char::return#12 = $72 [phi:frame_char::@8->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z return
    rts
    // [1728] phi from frame_char::@9 to frame_char::@return [phi:frame_char::@9->frame_char::@return]
  __b10:
    // [1728] phi frame_char::return#12 = $71 [phi:frame_char::@9->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z return
    // frame_char::@return
    // }
    // [1729] return 
    rts
}
  // cputs
// Output a NUL-terminated string at the current cursor position
// void cputs(__zp($46) const char *s)
cputs: {
    .label c = $55
    .label s = $46
    // [1731] phi from cputs to cputs::@1 [phi:cputs->cputs::@1]
    // [1731] phi cputs::s#2 = frame_draw::s [phi:cputs->cputs::@1#0] -- pbuz1=pbuc1 
    lda #<frame_draw.s
    sta.z s
    lda #>frame_draw.s
    sta.z s+1
    // cputs::@1
  __b1:
    // while(c=*s++)
    // [1732] cputs::c#1 = *cputs::s#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta.z c
    // [1733] cputs::s#0 = ++ cputs::s#2 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [1734] if(0!=cputs::c#1) goto cputs::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // cputs::@return
    // }
    // [1735] return 
    rts
    // cputs::@2
  __b2:
    // cputc(c)
    // [1736] stackpush(char) = cputs::c#1 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [1737] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [1731] phi from cputs::@2 to cputs::@1 [phi:cputs::@2->cputs::@1]
    // [1731] phi cputs::s#2 = cputs::s#0 [phi:cputs::@2->cputs::@1#0] -- register_copy 
    jmp __b1
}
  // print_chip_led
// void print_chip_led(__zp($b8) char x, char y, __zp($60) char w, __zp($2b) char tc, char bc)
print_chip_led: {
    .label i = $73
    .label tc = $2b
    .label x = $b8
    .label w = $60
    // gotoxy(x, y)
    // [1740] gotoxy::x#8 = print_chip_led::x#3 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1741] call gotoxy
    // [334] phi from print_chip_led to gotoxy [phi:print_chip_led->gotoxy]
    // [334] phi gotoxy::y#22 = 3 [phi:print_chip_led->gotoxy#0] -- vbuz1=vbuc1 
    lda #3
    sta.z gotoxy.y
    // [334] phi gotoxy::x#22 = gotoxy::x#8 [phi:print_chip_led->gotoxy#1] -- register_copy 
    jsr gotoxy
    // print_chip_led::@4
    // textcolor(tc)
    // [1742] textcolor::color#10 = print_chip_led::tc#3 -- vbuz1=vbuz2 
    lda.z tc
    sta.z textcolor.color
    // [1743] call textcolor
    // [316] phi from print_chip_led::@4 to textcolor [phi:print_chip_led::@4->textcolor]
    // [316] phi textcolor::color#16 = textcolor::color#10 [phi:print_chip_led::@4->textcolor#0] -- register_copy 
    jsr textcolor
    // [1744] phi from print_chip_led::@4 to print_chip_led::@5 [phi:print_chip_led::@4->print_chip_led::@5]
    // print_chip_led::@5
    // bgcolor(bc)
    // [1745] call bgcolor
    // [321] phi from print_chip_led::@5 to bgcolor [phi:print_chip_led::@5->bgcolor]
    // [321] phi bgcolor::color#14 = BLUE [phi:print_chip_led::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [1746] phi from print_chip_led::@5 to print_chip_led::@1 [phi:print_chip_led::@5->print_chip_led::@1]
    // [1746] phi print_chip_led::i#2 = 0 [phi:print_chip_led::@5->print_chip_led::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // print_chip_led::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [1747] if(print_chip_led::i#2<print_chip_led::w#5) goto print_chip_led::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [1748] phi from print_chip_led::@1 to print_chip_led::@3 [phi:print_chip_led::@1->print_chip_led::@3]
    // print_chip_led::@3
    // textcolor(WHITE)
    // [1749] call textcolor
    // [316] phi from print_chip_led::@3 to textcolor [phi:print_chip_led::@3->textcolor]
    // [316] phi textcolor::color#16 = WHITE [phi:print_chip_led::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [1750] phi from print_chip_led::@3 to print_chip_led::@6 [phi:print_chip_led::@3->print_chip_led::@6]
    // print_chip_led::@6
    // bgcolor(BLUE)
    // [1751] call bgcolor
    // [321] phi from print_chip_led::@6 to bgcolor [phi:print_chip_led::@6->bgcolor]
    // [321] phi bgcolor::color#14 = BLUE [phi:print_chip_led::@6->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_led::@return
    // }
    // [1752] return 
    rts
    // print_chip_led::@2
  __b2:
    // cputc(0xE2)
    // [1753] stackpush(char) = $e2 -- _stackpushbyte_=vbuc1 
    lda #$e2
    pha
    // [1754] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [1756] print_chip_led::i#1 = ++ print_chip_led::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1746] phi from print_chip_led::@2 to print_chip_led::@1 [phi:print_chip_led::@2->print_chip_led::@1]
    // [1746] phi print_chip_led::i#2 = print_chip_led::i#1 [phi:print_chip_led::@2->print_chip_led::@1#0] -- register_copy 
    jmp __b1
}
  // print_chip_line
// void print_chip_line(__zp($59) char x, __zp($58) char y, __zp($ab) char w, __zp($2d) char c)
print_chip_line: {
    .label i = $af
    .label x = $59
    .label w = $ab
    .label c = $2d
    .label y = $58
    // gotoxy(x, y)
    // [1758] gotoxy::x#6 = print_chip_line::x#16 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1759] gotoxy::y#6 = print_chip_line::y#16 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1760] call gotoxy
    // [334] phi from print_chip_line to gotoxy [phi:print_chip_line->gotoxy]
    // [334] phi gotoxy::y#22 = gotoxy::y#6 [phi:print_chip_line->gotoxy#0] -- register_copy 
    // [334] phi gotoxy::x#22 = gotoxy::x#6 [phi:print_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1761] phi from print_chip_line to print_chip_line::@4 [phi:print_chip_line->print_chip_line::@4]
    // print_chip_line::@4
    // textcolor(GREY)
    // [1762] call textcolor
    // [316] phi from print_chip_line::@4 to textcolor [phi:print_chip_line::@4->textcolor]
    // [316] phi textcolor::color#16 = GREY [phi:print_chip_line::@4->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [1763] phi from print_chip_line::@4 to print_chip_line::@5 [phi:print_chip_line::@4->print_chip_line::@5]
    // print_chip_line::@5
    // bgcolor(BLUE)
    // [1764] call bgcolor
    // [321] phi from print_chip_line::@5 to bgcolor [phi:print_chip_line::@5->bgcolor]
    // [321] phi bgcolor::color#14 = BLUE [phi:print_chip_line::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@6
    // cputc(VERA_CHR_UR)
    // [1765] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [1766] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [1768] call textcolor
    // [316] phi from print_chip_line::@6 to textcolor [phi:print_chip_line::@6->textcolor]
    // [316] phi textcolor::color#16 = WHITE [phi:print_chip_line::@6->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [1769] phi from print_chip_line::@6 to print_chip_line::@7 [phi:print_chip_line::@6->print_chip_line::@7]
    // print_chip_line::@7
    // bgcolor(BLACK)
    // [1770] call bgcolor
    // [321] phi from print_chip_line::@7 to bgcolor [phi:print_chip_line::@7->bgcolor]
    // [321] phi bgcolor::color#14 = BLACK [phi:print_chip_line::@7->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // [1771] phi from print_chip_line::@7 to print_chip_line::@1 [phi:print_chip_line::@7->print_chip_line::@1]
    // [1771] phi print_chip_line::i#2 = 0 [phi:print_chip_line::@7->print_chip_line::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // print_chip_line::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [1772] if(print_chip_line::i#2<print_chip_line::w#10) goto print_chip_line::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [1773] phi from print_chip_line::@1 to print_chip_line::@3 [phi:print_chip_line::@1->print_chip_line::@3]
    // print_chip_line::@3
    // textcolor(GREY)
    // [1774] call textcolor
    // [316] phi from print_chip_line::@3 to textcolor [phi:print_chip_line::@3->textcolor]
    // [316] phi textcolor::color#16 = GREY [phi:print_chip_line::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [1775] phi from print_chip_line::@3 to print_chip_line::@8 [phi:print_chip_line::@3->print_chip_line::@8]
    // print_chip_line::@8
    // bgcolor(BLUE)
    // [1776] call bgcolor
    // [321] phi from print_chip_line::@8 to bgcolor [phi:print_chip_line::@8->bgcolor]
    // [321] phi bgcolor::color#14 = BLUE [phi:print_chip_line::@8->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@9
    // cputc(VERA_CHR_UL)
    // [1777] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [1778] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [1780] call textcolor
    // [316] phi from print_chip_line::@9 to textcolor [phi:print_chip_line::@9->textcolor]
    // [316] phi textcolor::color#16 = WHITE [phi:print_chip_line::@9->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [1781] phi from print_chip_line::@9 to print_chip_line::@10 [phi:print_chip_line::@9->print_chip_line::@10]
    // print_chip_line::@10
    // bgcolor(BLACK)
    // [1782] call bgcolor
    // [321] phi from print_chip_line::@10 to bgcolor [phi:print_chip_line::@10->bgcolor]
    // [321] phi bgcolor::color#14 = BLACK [phi:print_chip_line::@10->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@11
    // cputcxy(x+2, y, c)
    // [1783] cputcxy::x#8 = print_chip_line::x#16 + 2 -- vbuz1=vbuz1_plus_2 
    lda.z cputcxy.x
    clc
    adc #2
    sta.z cputcxy.x
    // [1784] cputcxy::y#8 = print_chip_line::y#16
    // [1785] cputcxy::c#8 = print_chip_line::c#15 -- vbuz1=vbuz2 
    lda.z c
    sta.z cputcxy.c
    // [1786] call cputcxy
    // [1250] phi from print_chip_line::@11 to cputcxy [phi:print_chip_line::@11->cputcxy]
    // [1250] phi cputcxy::c#11 = cputcxy::c#8 [phi:print_chip_line::@11->cputcxy#0] -- register_copy 
    // [1250] phi cputcxy::y#11 = cputcxy::y#8 [phi:print_chip_line::@11->cputcxy#1] -- register_copy 
    // [1250] phi cputcxy::x#11 = cputcxy::x#8 [phi:print_chip_line::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // print_chip_line::@return
    // }
    // [1787] return 
    rts
    // print_chip_line::@2
  __b2:
    // cputc(VERA_CHR_SPACE)
    // [1788] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [1789] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [1791] print_chip_line::i#1 = ++ print_chip_line::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1771] phi from print_chip_line::@2 to print_chip_line::@1 [phi:print_chip_line::@2->print_chip_line::@1]
    // [1771] phi print_chip_line::i#2 = print_chip_line::i#1 [phi:print_chip_line::@2->print_chip_line::@1#0] -- register_copy 
    jmp __b1
}
  // print_chip_end
// void print_chip_end(__zp($79) char x, char y, __zp($e3) char w)
print_chip_end: {
    .label i = $2c
    .label x = $79
    .label w = $e3
    // gotoxy(x, y)
    // [1792] gotoxy::x#7 = print_chip_end::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1793] call gotoxy
    // [334] phi from print_chip_end to gotoxy [phi:print_chip_end->gotoxy]
    // [334] phi gotoxy::y#22 = print_chip::y#21 [phi:print_chip_end->gotoxy#0] -- vbuz1=vbuc1 
    lda #print_chip.y
    sta.z gotoxy.y
    // [334] phi gotoxy::x#22 = gotoxy::x#7 [phi:print_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1794] phi from print_chip_end to print_chip_end::@4 [phi:print_chip_end->print_chip_end::@4]
    // print_chip_end::@4
    // textcolor(GREY)
    // [1795] call textcolor
    // [316] phi from print_chip_end::@4 to textcolor [phi:print_chip_end::@4->textcolor]
    // [316] phi textcolor::color#16 = GREY [phi:print_chip_end::@4->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [1796] phi from print_chip_end::@4 to print_chip_end::@5 [phi:print_chip_end::@4->print_chip_end::@5]
    // print_chip_end::@5
    // bgcolor(BLUE)
    // [1797] call bgcolor
    // [321] phi from print_chip_end::@5 to bgcolor [phi:print_chip_end::@5->bgcolor]
    // [321] phi bgcolor::color#14 = BLUE [phi:print_chip_end::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_end::@6
    // cputc(VERA_CHR_UR)
    // [1798] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [1799] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [1801] call textcolor
    // [316] phi from print_chip_end::@6 to textcolor [phi:print_chip_end::@6->textcolor]
    // [316] phi textcolor::color#16 = BLUE [phi:print_chip_end::@6->textcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z textcolor.color
    jsr textcolor
    // [1802] phi from print_chip_end::@6 to print_chip_end::@7 [phi:print_chip_end::@6->print_chip_end::@7]
    // print_chip_end::@7
    // bgcolor(BLACK)
    // [1803] call bgcolor
    // [321] phi from print_chip_end::@7 to bgcolor [phi:print_chip_end::@7->bgcolor]
    // [321] phi bgcolor::color#14 = BLACK [phi:print_chip_end::@7->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // [1804] phi from print_chip_end::@7 to print_chip_end::@1 [phi:print_chip_end::@7->print_chip_end::@1]
    // [1804] phi print_chip_end::i#2 = 0 [phi:print_chip_end::@7->print_chip_end::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // print_chip_end::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [1805] if(print_chip_end::i#2<print_chip_end::w#0) goto print_chip_end::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [1806] phi from print_chip_end::@1 to print_chip_end::@3 [phi:print_chip_end::@1->print_chip_end::@3]
    // print_chip_end::@3
    // textcolor(GREY)
    // [1807] call textcolor
    // [316] phi from print_chip_end::@3 to textcolor [phi:print_chip_end::@3->textcolor]
    // [316] phi textcolor::color#16 = GREY [phi:print_chip_end::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [1808] phi from print_chip_end::@3 to print_chip_end::@8 [phi:print_chip_end::@3->print_chip_end::@8]
    // print_chip_end::@8
    // bgcolor(BLUE)
    // [1809] call bgcolor
    // [321] phi from print_chip_end::@8 to bgcolor [phi:print_chip_end::@8->bgcolor]
    // [321] phi bgcolor::color#14 = BLUE [phi:print_chip_end::@8->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_end::@9
    // cputc(VERA_CHR_UL)
    // [1810] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [1811] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_end::@return
    // }
    // [1813] return 
    rts
    // print_chip_end::@2
  __b2:
    // cputc(VERA_CHR_HL)
    // [1814] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [1815] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [1817] print_chip_end::i#1 = ++ print_chip_end::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1804] phi from print_chip_end::@2 to print_chip_end::@1 [phi:print_chip_end::@2->print_chip_end::@1]
    // [1804] phi print_chip_end::i#2 = print_chip_end::i#1 [phi:print_chip_end::@2->print_chip_end::@1#0] -- register_copy 
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
// __zp($29) unsigned int utoa_append(__zp($66) char *buffer, __zp($29) unsigned int value, __zp($2f) unsigned int sub)
utoa_append: {
    .label buffer = $66
    .label value = $29
    .label sub = $2f
    .label return = $29
    .label digit = $2b
    // [1819] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [1819] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [1819] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [1820] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwuz1_ge_vwuz2_then_la1 
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
    // [1821] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // utoa_append::@return
    // }
    // [1822] return 
    rts
    // utoa_append::@2
  __b2:
    // digit++;
    // [1823] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [1824] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    lda.z value+1
    sbc.z sub+1
    sta.z value+1
    // [1819] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [1819] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [1819] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
    jmp __b1
}
  // uctoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void uctoa(__zp($24) char value, __zp($4d) char *buffer, __zp($59) char radix)
uctoa: {
    .label uctoa__4 = $55
    .label digit_value = $2e
    .label buffer = $4d
    .label digit = $57
    .label value = $24
    .label radix = $59
    .label started = $60
    .label max_digits = $79
    .label digit_values = $46
    // if(radix==DECIMAL)
    // [1825] if(uctoa::radix#0==DECIMAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp.z radix
    beq __b2
    // uctoa::@2
    // if(radix==HEXADECIMAL)
    // [1826] if(uctoa::radix#0==HEXADECIMAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp.z radix
    beq __b3
    // uctoa::@3
    // if(radix==OCTAL)
    // [1827] if(uctoa::radix#0==OCTAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp.z radix
    beq __b4
    // uctoa::@4
    // if(radix==BINARY)
    // [1828] if(uctoa::radix#0==BINARY) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp.z radix
    beq __b5
    // uctoa::@5
    // *buffer++ = 'e'
    // [1829] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1830] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1831] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1832] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // uctoa::@return
    // }
    // [1833] return 
    rts
    // [1834] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
  __b2:
    // [1834] phi uctoa::digit_values#8 = RADIX_DECIMAL_VALUES_CHAR [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1834] phi uctoa::max_digits#7 = 3 [phi:uctoa->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [1834] phi from uctoa::@2 to uctoa::@1 [phi:uctoa::@2->uctoa::@1]
  __b3:
    // [1834] phi uctoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_CHAR [phi:uctoa::@2->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1834] phi uctoa::max_digits#7 = 2 [phi:uctoa::@2->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #2
    sta.z max_digits
    jmp __b1
    // [1834] phi from uctoa::@3 to uctoa::@1 [phi:uctoa::@3->uctoa::@1]
  __b4:
    // [1834] phi uctoa::digit_values#8 = RADIX_OCTAL_VALUES_CHAR [phi:uctoa::@3->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values+1
    // [1834] phi uctoa::max_digits#7 = 3 [phi:uctoa::@3->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [1834] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
  __b5:
    // [1834] phi uctoa::digit_values#8 = RADIX_BINARY_VALUES_CHAR [phi:uctoa::@4->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_BINARY_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_CHAR
    sta.z digit_values+1
    // [1834] phi uctoa::max_digits#7 = 8 [phi:uctoa::@4->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #8
    sta.z max_digits
    // uctoa::@1
  __b1:
    // [1835] phi from uctoa::@1 to uctoa::@6 [phi:uctoa::@1->uctoa::@6]
    // [1835] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa::@1->uctoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1835] phi uctoa::started#2 = 0 [phi:uctoa::@1->uctoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [1835] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa::@1->uctoa::@6#2] -- register_copy 
    // [1835] phi uctoa::digit#2 = 0 [phi:uctoa::@1->uctoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // uctoa::@6
  __b6:
    // max_digits-1
    // [1836] uctoa::$4 = uctoa::max_digits#7 - 1 -- vbuz1=vbuz2_minus_1 
    ldx.z max_digits
    dex
    stx.z uctoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1837] if(uctoa::digit#2<uctoa::$4) goto uctoa::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z digit
    cmp.z uctoa__4
    bcc __b7
    // uctoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1838] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z value
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1839] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1840] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // uctoa::@7
  __b7:
    // unsigned char digit_value = digit_values[digit]
    // [1841] uctoa::digit_value#0 = uctoa::digit_values#8[uctoa::digit#2] -- vbuz1=pbuz2_derefidx_vbuz3 
    ldy.z digit
    lda (digit_values),y
    sta.z digit_value
    // if (started || value >= digit_value)
    // [1842] if(0!=uctoa::started#2) goto uctoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // uctoa::@12
    // [1843] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@10 -- vbuz1_ge_vbuz2_then_la1 
    lda.z value
    cmp.z digit_value
    bcs __b10
    // [1844] phi from uctoa::@12 to uctoa::@9 [phi:uctoa::@12->uctoa::@9]
    // [1844] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@12->uctoa::@9#0] -- register_copy 
    // [1844] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@12->uctoa::@9#1] -- register_copy 
    // [1844] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@12->uctoa::@9#2] -- register_copy 
    // uctoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1845] uctoa::digit#1 = ++ uctoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1835] phi from uctoa::@9 to uctoa::@6 [phi:uctoa::@9->uctoa::@6]
    // [1835] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@9->uctoa::@6#0] -- register_copy 
    // [1835] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@9->uctoa::@6#1] -- register_copy 
    // [1835] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@9->uctoa::@6#2] -- register_copy 
    // [1835] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@9->uctoa::@6#3] -- register_copy 
    jmp __b6
    // uctoa::@10
  __b10:
    // uctoa_append(buffer++, value, digit_value)
    // [1846] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [1847] uctoa_append::value#0 = uctoa::value#2
    // [1848] uctoa_append::sub#0 = uctoa::digit_value#0
    // [1849] call uctoa_append
    // [1959] phi from uctoa::@10 to uctoa_append [phi:uctoa::@10->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [1850] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@11
    // value = uctoa_append(buffer++, value, digit_value)
    // [1851] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [1852] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1844] phi from uctoa::@11 to uctoa::@9 [phi:uctoa::@11->uctoa::@9]
    // [1844] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@11->uctoa::@9#0] -- register_copy 
    // [1844] phi uctoa::started#4 = 1 [phi:uctoa::@11->uctoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [1844] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@11->uctoa::@9#2] -- register_copy 
    jmp __b9
}
  // cbm_k_setlfs
/**
 * @brief Sets the logical file channel.
 *
 * @param channel the logical file number.
 * @param device the device number.
 * @param command the command.
 */
// void cbm_k_setlfs(__mem() volatile char channel, __mem() volatile char device, __zp($f5) volatile char command)
cbm_k_setlfs: {
    .label command = $f5
    // asm
    // asm { ldxdevice ldachannel ldycommand jsrCBM_SETLFS  }
    ldx device
    lda channel
    ldy command
    jsr CBM_SETLFS
    // cbm_k_setlfs::@return
    // }
    // [1854] return 
    rts
  .segment Data
    channel: .byte 0
    device: .byte 0
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
// __zp($f3) int ferror(__zp($51) struct $2 *stream)
ferror: {
    .label ferror__6 = $5f
    .label ferror__15 = $ba
    .label cbm_k_setnam1_filename = $f9
    .label cbm_k_setnam1_filename_len = $ef
    .label cbm_k_setnam1_ferror__0 = $46
    .label cbm_k_chkin1_channel = $f7
    .label cbm_k_chkin1_status = $f0
    .label cbm_k_chrin1_ch = $f1
    .label cbm_k_readst1_status = $c8
    .label cbm_k_close1_channel = $f2
    .label cbm_k_chrin2_ch = $c9
    .label stream = $51
    .label return = $f3
    .label sp = $2e
    .label cbm_k_chrin1_return = $ba
    .label ch = $ba
    .label cbm_k_readst1_return = $5f
    .label st = $5f
    .label errno_len = $cc
    .label cbm_k_chrin2_return = $ba
    .label errno_parsed = $c5
    // unsigned char sp = (unsigned char)stream
    // [1855] ferror::sp#0 = (char)ferror::stream#0 -- vbuz1=_byte_pssz2 
    lda.z stream
    sta.z sp
    // cbm_k_setlfs(15, 8, 15)
    // [1856] cbm_k_setlfs::channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.channel
    // [1857] cbm_k_setlfs::device = 8 -- vbum1=vbuc1 
    lda #8
    sta cbm_k_setlfs.device
    // [1858] cbm_k_setlfs::command = $f -- vbuz1=vbuc1 
    lda #$f
    sta.z cbm_k_setlfs.command
    // [1859] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // ferror::@11
    // cbm_k_setnam("")
    // [1860] ferror::cbm_k_setnam1_filename = info_text14 -- pbuz1=pbuc1 
    lda #<info_text14
    sta.z cbm_k_setnam1_filename
    lda #>info_text14
    sta.z cbm_k_setnam1_filename+1
    // ferror::cbm_k_setnam1
    // strlen(filename)
    // [1861] strlen::str#5 = ferror::cbm_k_setnam1_filename -- pbuz1=pbuz2 
    lda.z cbm_k_setnam1_filename
    sta.z strlen.str
    lda.z cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [1862] call strlen
    // [1591] phi from ferror::cbm_k_setnam1 to strlen [phi:ferror::cbm_k_setnam1->strlen]
    // [1591] phi strlen::str#8 = strlen::str#5 [phi:ferror::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [1863] strlen::return#12 = strlen::len#2
    // ferror::@12
    // [1864] ferror::cbm_k_setnam1_$0 = strlen::return#12
    // char filename_len = (char)strlen(filename)
    // [1865] ferror::cbm_k_setnam1_filename_len = (char)ferror::cbm_k_setnam1_$0 -- vbuz1=_byte_vwuz2 
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
    // [1868] ferror::cbm_k_chkin1_channel = $f -- vbuz1=vbuc1 
    lda #$f
    sta.z cbm_k_chkin1_channel
    // ferror::cbm_k_chkin1
    // char status
    // [1869] ferror::cbm_k_chkin1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // ferror::cbm_k_chrin1
    // char ch
    // [1871] ferror::cbm_k_chrin1_ch = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chrin1_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin1_ch
    // return ch;
    // [1873] ferror::cbm_k_chrin1_return#0 = ferror::cbm_k_chrin1_ch -- vbuz1=vbuz2 
    sta.z cbm_k_chrin1_return
    // ferror::cbm_k_chrin1_@return
    // }
    // [1874] ferror::cbm_k_chrin1_return#1 = ferror::cbm_k_chrin1_return#0
    // ferror::@7
    // char ch = cbm_k_chrin()
    // [1875] ferror::ch#0 = ferror::cbm_k_chrin1_return#1
    // [1876] phi from ferror::@7 to ferror::cbm_k_readst1 [phi:ferror::@7->ferror::cbm_k_readst1]
    // [1876] phi __errno#137 = __errno#228 [phi:ferror::@7->ferror::cbm_k_readst1#0] -- register_copy 
    // [1876] phi ferror::errno_len#10 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z errno_len
    // [1876] phi ferror::ch#10 = ferror::ch#0 [phi:ferror::@7->ferror::cbm_k_readst1#2] -- register_copy 
    // [1876] phi ferror::errno_parsed#2 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#3] -- vbuz1=vbuc1 
    sta.z errno_parsed
    // ferror::cbm_k_readst1
  cbm_k_readst1:
    // char status
    // [1877] ferror::cbm_k_readst1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [1879] ferror::cbm_k_readst1_return#0 = ferror::cbm_k_readst1_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst1_return
    // ferror::cbm_k_readst1_@return
    // }
    // [1880] ferror::cbm_k_readst1_return#1 = ferror::cbm_k_readst1_return#0
    // ferror::@8
    // cbm_k_readst()
    // [1881] ferror::$6 = ferror::cbm_k_readst1_return#1
    // st = cbm_k_readst()
    // [1882] ferror::st#1 = ferror::$6
    // while (!(st = cbm_k_readst()))
    // [1883] if(0==ferror::st#1) goto ferror::@1 -- 0_eq_vbuz1_then_la1 
    lda.z st
    beq __b1
    // ferror::@2
    // __status = st
    // [1884] ((char *)&__stdio_file+$118)[ferror::sp#0] = ferror::st#1 -- pbuc1_derefidx_vbuz1=vbuz2 
    ldy.z sp
    sta __stdio_file+$118,y
    // cbm_k_close(15)
    // [1885] ferror::cbm_k_close1_channel = $f -- vbuz1=vbuc1 
    lda #$f
    sta.z cbm_k_close1_channel
    // ferror::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // ferror::@9
    // return __errno;
    // [1887] ferror::return#1 = __errno#137 -- vwsz1=vwsz2 
    lda.z __errno
    sta.z return
    lda.z __errno+1
    sta.z return+1
    // ferror::@return
    // }
    // [1888] return 
    rts
    // ferror::@1
  __b1:
    // if (!errno_parsed)
    // [1889] if(0!=ferror::errno_parsed#2) goto ferror::@3 -- 0_neq_vbuz1_then_la1 
    lda.z errno_parsed
    bne __b3
    // ferror::@4
    // if (ch == ',')
    // [1890] if(ferror::ch#10!=',') goto ferror::@3 -- vbuz1_neq_vbuc1_then_la1 
    lda #','
    cmp.z ch
    bne __b3
    // ferror::@5
    // errno_parsed++;
    // [1891] ferror::errno_parsed#1 = ++ ferror::errno_parsed#2 -- vbuz1=_inc_vbuz1 
    inc.z errno_parsed
    // strncpy(temp, __errno_error, errno_len+1)
    // [1892] strncpy::n#0 = ferror::errno_len#10 + 1 -- vwuz1=vbuz2_plus_1 
    lda.z errno_len
    clc
    adc #1
    sta.z strncpy.n
    lda #0
    adc #0
    sta.z strncpy.n+1
    // [1893] call strncpy
    // [1966] phi from ferror::@5 to strncpy [phi:ferror::@5->strncpy]
    jsr strncpy
    // [1894] phi from ferror::@5 to ferror::@13 [phi:ferror::@5->ferror::@13]
    // ferror::@13
    // atoi(temp)
    // [1895] call atoi
    // [1907] phi from ferror::@13 to atoi [phi:ferror::@13->atoi]
    // [1907] phi atoi::str#2 = ferror::temp [phi:ferror::@13->atoi#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z atoi.str
    lda #>temp
    sta.z atoi.str+1
    jsr atoi
    // atoi(temp)
    // [1896] atoi::return#4 = atoi::return#2
    // ferror::@14
    // __errno = atoi(temp)
    // [1897] __errno#2 = atoi::return#4 -- vwsz1=vwsz2 
    lda.z atoi.return
    sta.z __errno
    lda.z atoi.return+1
    sta.z __errno+1
    // [1898] phi from ferror::@1 ferror::@14 ferror::@4 to ferror::@3 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3]
    // [1898] phi __errno#100 = __errno#137 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#0] -- register_copy 
    // [1898] phi ferror::errno_parsed#11 = ferror::errno_parsed#2 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#1] -- register_copy 
    // ferror::@3
  __b3:
    // __errno_error[errno_len] = ch
    // [1899] __errno_error[ferror::errno_len#10] = ferror::ch#10 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z ch
    ldy.z errno_len
    sta __errno_error,y
    // errno_len++;
    // [1900] ferror::errno_len#1 = ++ ferror::errno_len#10 -- vbuz1=_inc_vbuz1 
    inc.z errno_len
    // ferror::cbm_k_chrin2
    // char ch
    // [1901] ferror::cbm_k_chrin2_ch = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chrin2_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin2_ch
    // return ch;
    // [1903] ferror::cbm_k_chrin2_return#0 = ferror::cbm_k_chrin2_ch -- vbuz1=vbuz2 
    sta.z cbm_k_chrin2_return
    // ferror::cbm_k_chrin2_@return
    // }
    // [1904] ferror::cbm_k_chrin2_return#1 = ferror::cbm_k_chrin2_return#0
    // ferror::@10
    // cbm_k_chrin()
    // [1905] ferror::$15 = ferror::cbm_k_chrin2_return#1
    // ch = cbm_k_chrin()
    // [1906] ferror::ch#1 = ferror::$15
    // [1876] phi from ferror::@10 to ferror::cbm_k_readst1 [phi:ferror::@10->ferror::cbm_k_readst1]
    // [1876] phi __errno#137 = __errno#100 [phi:ferror::@10->ferror::cbm_k_readst1#0] -- register_copy 
    // [1876] phi ferror::errno_len#10 = ferror::errno_len#1 [phi:ferror::@10->ferror::cbm_k_readst1#1] -- register_copy 
    // [1876] phi ferror::ch#10 = ferror::ch#1 [phi:ferror::@10->ferror::cbm_k_readst1#2] -- register_copy 
    // [1876] phi ferror::errno_parsed#2 = ferror::errno_parsed#11 [phi:ferror::@10->ferror::cbm_k_readst1#3] -- register_copy 
    jmp cbm_k_readst1
  .segment Data
    temp: .fill 4, 0
}
.segment Code
  // atoi
// Converts the string argument str to an integer.
// __zp($4d) int atoi(__zp($a9) const char *str)
atoi: {
    .label atoi__6 = $4d
    .label atoi__7 = $4d
    .label res = $4d
    // Initialize sign as positive
    .label i = $73
    .label return = $4d
    .label str = $a9
    // Initialize result
    .label negative = $ab
    .label atoi__10 = $6e
    .label atoi__11 = $4d
    // if (str[i] == '-')
    // [1908] if(*atoi::str#2!='-') goto atoi::@3 -- _deref_pbuz1_neq_vbuc1_then_la1 
    ldy #0
    lda (str),y
    cmp #'-'
    bne __b2
    // [1909] phi from atoi to atoi::@2 [phi:atoi->atoi::@2]
    // atoi::@2
    // [1910] phi from atoi::@2 to atoi::@3 [phi:atoi::@2->atoi::@3]
    // [1910] phi atoi::negative#2 = 1 [phi:atoi::@2->atoi::@3#0] -- vbuz1=vbuc1 
    lda #1
    sta.z negative
    // [1910] phi atoi::res#2 = 0 [phi:atoi::@2->atoi::@3#1] -- vwsz1=vwsc1 
    tya
    sta.z res
    sta.z res+1
    // [1910] phi atoi::i#4 = 1 [phi:atoi::@2->atoi::@3#2] -- vbuz1=vbuc1 
    lda #1
    sta.z i
    jmp __b3
  // Iterate through all digits and update the result
    // [1910] phi from atoi to atoi::@3 [phi:atoi->atoi::@3]
  __b2:
    // [1910] phi atoi::negative#2 = 0 [phi:atoi->atoi::@3#0] -- vbuz1=vbuc1 
    lda #0
    sta.z negative
    // [1910] phi atoi::res#2 = 0 [phi:atoi->atoi::@3#1] -- vwsz1=vwsc1 
    sta.z res
    sta.z res+1
    // [1910] phi atoi::i#4 = 0 [phi:atoi->atoi::@3#2] -- vbuz1=vbuc1 
    sta.z i
    // atoi::@3
  __b3:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [1911] if(atoi::str#2[atoi::i#4]<'0') goto atoi::@5 -- pbuz1_derefidx_vbuz2_lt_vbuc1_then_la1 
    ldy.z i
    lda (str),y
    cmp #'0'
    bcc __b5
    // atoi::@6
    // [1912] if(atoi::str#2[atoi::i#4]<='9') goto atoi::@4 -- pbuz1_derefidx_vbuz2_le_vbuc1_then_la1 
    lda (str),y
    cmp #'9'
    bcc __b4
    beq __b4
    // atoi::@5
  __b5:
    // if(negative)
    // [1913] if(0!=atoi::negative#2) goto atoi::@1 -- 0_neq_vbuz1_then_la1 
    // Return result with sign
    lda.z negative
    bne __b1
    // [1915] phi from atoi::@1 atoi::@5 to atoi::@return [phi:atoi::@1/atoi::@5->atoi::@return]
    // [1915] phi atoi::return#2 = atoi::return#0 [phi:atoi::@1/atoi::@5->atoi::@return#0] -- register_copy 
    rts
    // atoi::@1
  __b1:
    // return -res;
    // [1914] atoi::return#0 = - atoi::res#2 -- vwsz1=_neg_vwsz1 
    lda #0
    sec
    sbc.z return
    sta.z return
    lda #0
    sbc.z return+1
    sta.z return+1
    // atoi::@return
    // }
    // [1916] return 
    rts
    // atoi::@4
  __b4:
    // res * 10
    // [1917] atoi::$10 = atoi::res#2 << 2 -- vwsz1=vwsz2_rol_2 
    lda.z res
    asl
    sta.z atoi__10
    lda.z res+1
    rol
    sta.z atoi__10+1
    asl.z atoi__10
    rol.z atoi__10+1
    // [1918] atoi::$11 = atoi::$10 + atoi::res#2 -- vwsz1=vwsz2_plus_vwsz1 
    clc
    lda.z atoi__11
    adc.z atoi__10
    sta.z atoi__11
    lda.z atoi__11+1
    adc.z atoi__10+1
    sta.z atoi__11+1
    // [1919] atoi::$6 = atoi::$11 << 1 -- vwsz1=vwsz1_rol_1 
    asl.z atoi__6
    rol.z atoi__6+1
    // res * 10 + str[i]
    // [1920] atoi::$7 = atoi::$6 + atoi::str#2[atoi::i#4] -- vwsz1=vwsz1_plus_pbuz2_derefidx_vbuz3 
    ldy.z i
    lda.z atoi__7
    clc
    adc (str),y
    sta.z atoi__7
    bcc !+
    inc.z atoi__7+1
  !:
    // res = res * 10 + str[i] - '0'
    // [1921] atoi::res#1 = atoi::$7 - '0' -- vwsz1=vwsz1_minus_vbuc1 
    lda.z res
    sec
    sbc #'0'
    sta.z res
    bcs !+
    dec.z res+1
  !:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [1922] atoi::i#2 = ++ atoi::i#4 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1910] phi from atoi::@4 to atoi::@3 [phi:atoi::@4->atoi::@3]
    // [1910] phi atoi::negative#2 = atoi::negative#2 [phi:atoi::@4->atoi::@3#0] -- register_copy 
    // [1910] phi atoi::res#2 = atoi::res#1 [phi:atoi::@4->atoi::@3#1] -- register_copy 
    // [1910] phi atoi::i#4 = atoi::i#2 [phi:atoi::@4->atoi::@3#2] -- register_copy 
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
// __zp($43) unsigned int cx16_k_macptr(__zp($70) volatile char bytes, __zp($6a) void * volatile buffer)
cx16_k_macptr: {
    .label bytes = $70
    .label buffer = $6a
    .label bytes_read = $48
    .label return = $43
    // unsigned int bytes_read
    // [1923] cx16_k_macptr::bytes_read = 0 -- vwuz1=vwuc1 
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
    // [1925] cx16_k_macptr::return#0 = cx16_k_macptr::bytes_read -- vwuz1=vwuz2 
    lda.z bytes_read
    sta.z return
    lda.z bytes_read+1
    sta.z return+1
    // cx16_k_macptr::@return
    // }
    // [1926] cx16_k_macptr::return#1 = cx16_k_macptr::return#0
    // [1927] return 
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
// __zp($25) unsigned long ultoa_append(__zp($64) char *buffer, __zp($25) unsigned long value, __zp($31) unsigned long sub)
ultoa_append: {
    .label buffer = $64
    .label value = $25
    .label sub = $31
    .label return = $25
    .label digit = $2d
    // [1929] phi from ultoa_append to ultoa_append::@1 [phi:ultoa_append->ultoa_append::@1]
    // [1929] phi ultoa_append::digit#2 = 0 [phi:ultoa_append->ultoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [1929] phi ultoa_append::value#2 = ultoa_append::value#0 [phi:ultoa_append->ultoa_append::@1#1] -- register_copy 
    // ultoa_append::@1
  __b1:
    // while (value >= sub)
    // [1930] if(ultoa_append::value#2>=ultoa_append::sub#0) goto ultoa_append::@2 -- vduz1_ge_vduz2_then_la1 
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
    // [1931] *ultoa_append::buffer#0 = DIGITS[ultoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // ultoa_append::@return
    // }
    // [1932] return 
    rts
    // ultoa_append::@2
  __b2:
    // digit++;
    // [1933] ultoa_append::digit#1 = ++ ultoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [1934] ultoa_append::value#1 = ultoa_append::value#2 - ultoa_append::sub#0 -- vduz1=vduz1_minus_vduz2 
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
    // [1929] phi from ultoa_append::@2 to ultoa_append::@1 [phi:ultoa_append::@2->ultoa_append::@1]
    // [1929] phi ultoa_append::digit#2 = ultoa_append::digit#1 [phi:ultoa_append::@2->ultoa_append::@1#0] -- register_copy 
    // [1929] phi ultoa_append::value#2 = ultoa_append::value#1 [phi:ultoa_append::@2->ultoa_append::@1#1] -- register_copy 
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
// __zp($af) char rom_byte_compare(__zp($ad) char *ptr_rom, __zp($45) char value)
rom_byte_compare: {
    .label return = $af
    .label ptr_rom = $ad
    .label value = $45
    // if (*ptr_rom != value)
    // [1935] if(*rom_byte_compare::ptr_rom#0==rom_byte_compare::value#0) goto rom_byte_compare::@1 -- _deref_pbuz1_eq_vbuz2_then_la1 
    lda.z value
    ldy #0
    cmp (ptr_rom),y
    beq __b2
    // [1936] phi from rom_byte_compare to rom_byte_compare::@2 [phi:rom_byte_compare->rom_byte_compare::@2]
    // rom_byte_compare::@2
    // [1937] phi from rom_byte_compare::@2 to rom_byte_compare::@1 [phi:rom_byte_compare::@2->rom_byte_compare::@1]
    // [1937] phi rom_byte_compare::return#0 = 0 [phi:rom_byte_compare::@2->rom_byte_compare::@1#0] -- vbuz1=vbuc1 
    tya
    sta.z return
    rts
    // [1937] phi from rom_byte_compare to rom_byte_compare::@1 [phi:rom_byte_compare->rom_byte_compare::@1]
  __b2:
    // [1937] phi rom_byte_compare::return#0 = 1 [phi:rom_byte_compare->rom_byte_compare::@1#0] -- vbuz1=vbuc1 
    lda #1
    sta.z return
    // rom_byte_compare::@1
    // rom_byte_compare::@return
    // }
    // [1938] return 
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
// void memcpy8_vram_vram(__zp($36) char dbank_vram, __zp($3e) unsigned int doffset_vram, __zp($35) char sbank_vram, __zp($3b) unsigned int soffset_vram, __zp($23) char num8)
memcpy8_vram_vram: {
    .label memcpy8_vram_vram__0 = $37
    .label memcpy8_vram_vram__1 = $38
    .label memcpy8_vram_vram__2 = $35
    .label memcpy8_vram_vram__3 = $39
    .label memcpy8_vram_vram__4 = $3a
    .label memcpy8_vram_vram__5 = $36
    .label num8 = $23
    .label dbank_vram = $36
    .label doffset_vram = $3e
    .label sbank_vram = $35
    .label soffset_vram = $3b
    .label num8_1 = $22
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1939] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [1940] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte0_vwuz2 
    lda.z soffset_vram
    sta.z memcpy8_vram_vram__0
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [1941] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [1942] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte1_vwuz2 
    lda.z soffset_vram+1
    sta.z memcpy8_vram_vram__1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [1943] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [1944] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuz1=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z memcpy8_vram_vram__2
    sta.z memcpy8_vram_vram__2
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [1945] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [1946] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [1947] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte0_vwuz2 
    lda.z doffset_vram
    sta.z memcpy8_vram_vram__3
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [1948] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [1949] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte1_vwuz2 
    lda.z doffset_vram+1
    sta.z memcpy8_vram_vram__4
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [1950] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [1951] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuz1=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z memcpy8_vram_vram__5
    sta.z memcpy8_vram_vram__5
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [1952] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // [1953] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [1953] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [1954] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbuz1=_dec_vbuz2 
    ldy.z num8_1
    dey
    sty.z num8
    // [1955] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbuz1_then_la1 
    lda.z num8_1
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [1956] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [1957] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [1958] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbuz1=vbuz2 
    lda.z num8
    sta.z num8_1
    jmp __b1
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
// __zp($24) char uctoa_append(__zp($62) char *buffer, __zp($24) char value, __zp($2e) char sub)
uctoa_append: {
    .label buffer = $62
    .label value = $24
    .label sub = $2e
    .label return = $24
    .label digit = $2c
    // [1960] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [1960] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [1960] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [1961] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbuz1_ge_vbuz2_then_la1 
    lda.z value
    cmp.z sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [1962] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [1963] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [1964] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [1965] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbuz1=vbuz1_minus_vbuz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    // [1960] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [1960] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [1960] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
    jmp __b1
}
  // strncpy
/// Copies up to n characters from the string pointed to, by src to dst.
/// In a case where the length of src is less than that of n, the remainder of dst will be padded with null bytes.
/// @param dst ? This is the pointer to the destination array where the content is to be copied.
/// @param src ? This is the string to be copied.
/// @param n ? The number of characters to be copied from source.
/// @return The destination
// char * strncpy(__zp($76) char *dst, __zp($71) const char *src, __zp($62) unsigned int n)
strncpy: {
    .label c = $2b
    .label dst = $76
    .label i = $74
    .label src = $71
    .label n = $62
    // [1967] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [1967] phi strncpy::dst#2 = ferror::temp [phi:strncpy->strncpy::@1#0] -- pbuz1=pbuc1 
    lda #<ferror.temp
    sta.z dst
    lda #>ferror.temp
    sta.z dst+1
    // [1967] phi strncpy::src#2 = __errno_error [phi:strncpy->strncpy::@1#1] -- pbuz1=pbuc1 
    lda #<__errno_error
    sta.z src
    lda #>__errno_error
    sta.z src+1
    // [1967] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwuz1=vwuc1 
    lda #<0
    sta.z i
    sta.z i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [1968] if(strncpy::i#2<strncpy::n#0) goto strncpy::@2 -- vwuz1_lt_vwuz2_then_la1 
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
    // [1969] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [1970] strncpy::c#0 = *strncpy::src#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta.z c
    // if(c)
    // [1971] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbuz1_then_la1 
    beq __b3
    // strncpy::@4
    // src++;
    // [1972] strncpy::src#0 = ++ strncpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1973] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [1973] phi strncpy::src#6 = strncpy::src#2 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [1974] *strncpy::dst#2 = strncpy::c#0 -- _deref_pbuz1=vbuz2 
    lda.z c
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [1975] strncpy::dst#0 = ++ strncpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [1976] strncpy::i#1 = ++ strncpy::i#2 -- vwuz1=_inc_vwuz1 
    inc.z i
    bne !+
    inc.z i+1
  !:
    // [1967] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [1967] phi strncpy::dst#2 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [1967] phi strncpy::src#2 = strncpy::src#6 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [1967] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
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
  __7: .text "Comparing"
  .byte 0
  __8: .text "Compared"
  .byte 0
  __9: .text "Flashing"
  .byte 0
  __10: .text "Flashed"
  .byte 0
  __11: .text "Error"
  .byte 0
  info_text14: .text ""
  .byte 0
  s1: .text " - "
  .byte 0
  s7: .text " of "
  .byte 0
  s4: .text ":"
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
