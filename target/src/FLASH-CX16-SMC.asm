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
    .label conio_x16_init__5 = $d6
    // screenlayer1()
    // [20] call screenlayer1
    jsr screenlayer1
    // [21] phi from conio_x16_init to conio_x16_init::@1 [phi:conio_x16_init->conio_x16_init::@1]
    // conio_x16_init::@1
    // textcolor(CONIO_TEXTCOLOR_DEFAULT)
    // [22] call textcolor
    // [468] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [468] phi textcolor::color#16 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [23] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [24] call bgcolor
    // [473] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [473] phi bgcolor::color#14 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbuz1=vbuc1 
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
    // [486] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [486] phi gotoxy::y#29 = gotoxy::y#2 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [486] phi gotoxy::x#29 = gotoxy::x#2 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
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
// void cputc(__zp($41) char c)
cputc: {
    .const OFFSET_STACK_C = 0
    .label cputc__1 = $22
    .label cputc__2 = $ba
    .label cputc__3 = $bb
    .label c = $41
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
    .label main__91 = $2a
    .label check_smc1_main__0 = $32
    .label check_smc2_main__0 = $dd
    .label check_cx16_rom1_check_rom1_main__0 = $dc
    .label check_vera1_main__0 = $25
    .label check_smc5_main__0 = $db
    .label check_roms2_check_rom1_main__0 = $da
    .label check_smc1_return = $32
    .label check_smc2_return = $dd
    .label check_cx16_rom1_check_rom1_return = $dc
    .label check_vera1_return = $25
    .label rom_differences = $26
    .label check_smc5_return = $db
    .label check_roms2_check_rom1_return = $da
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
    // main::@51
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
    // [77] phi from main::cx16_k_screen_set_charset1 to main::@52 [phi:main::cx16_k_screen_set_charset1->main::@52]
    // main::@52
    // frame_init()
    // [78] call frame_init
    // [507] phi from main::@52 to frame_init [phi:main::@52->frame_init]
    jsr frame_init
    // [79] phi from main::@52 to main::@70 [phi:main::@52->main::@70]
    // main::@70
    // frame_draw()
    // [80] call frame_draw
    // [527] phi from main::@70 to frame_draw [phi:main::@70->frame_draw]
    jsr frame_draw
    // [81] phi from main::@70 to main::@71 [phi:main::@70->main::@71]
    // main::@71
    // info_title("Commander X16 Flash Utility!")
    // [82] call info_title
    // [566] phi from main::@71 to info_title [phi:main::@71->info_title]
    jsr info_title
    // [83] phi from main::@71 to main::@72 [phi:main::@71->main::@72]
    // main::@72
    // progress_clear()
    // [84] call progress_clear
    // [571] phi from main::@72 to progress_clear [phi:main::@72->progress_clear]
    jsr progress_clear
    // [85] phi from main::@72 to main::@73 [phi:main::@72->main::@73]
    // main::@73
    // info_clear_all()
    // [86] call info_clear_all
    // [586] phi from main::@73 to info_clear_all [phi:main::@73->info_clear_all]
    jsr info_clear_all
    // [87] phi from main::@73 to main::@74 [phi:main::@73->main::@74]
    // main::@74
    // info_progress("Detecting SMC, VERA and ROM chipsets ...")
    // [88] call info_progress
  // info_print(0, "The SMC chip on the X16 board controls the power on/off, keyboard and mouse pheripherals.");
  // info_print(1, "It is essential that the SMC chip gets updated together with the latest ROM on the X16 board.");
  // info_print(2, "On the X16 board, near the SMC chip are two jumpers");
    // [596] phi from main::@74 to info_progress [phi:main::@74->info_progress]
    // [596] phi info_progress::info_text#12 = main::info_text1 [phi:main::@74->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z info_progress.info_text
    lda #>info_text1
    sta.z info_progress.info_text+1
    jsr info_progress
    // main::SEI1
    // asm
    // asm { sei  }
    sei
    // [90] phi from main::SEI1 to main::@53 [phi:main::SEI1->main::@53]
    // main::@53
    // smc_detect()
    // [91] call smc_detect
    jsr smc_detect
    // [92] smc_detect::return#2 = smc_detect::return#0
    // main::@75
    // smc_bootloader = smc_detect()
    // [93] smc_bootloader#0 = smc_detect::return#2 -- vwum1=vwuz2 
    lda.z smc_detect.return
    sta smc_bootloader
    lda.z smc_detect.return+1
    sta smc_bootloader+1
    // chip_smc()
    // [94] call chip_smc
    // [621] phi from main::@75 to chip_smc [phi:main::@75->chip_smc]
    jsr chip_smc
    // main::@76
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
    // main::@6
    // if(smc_bootloader == 0x0200)
    // [96] if(smc_bootloader#0==$200) goto main::@12 -- vwum1_eq_vwuc1_then_la1 
    lda smc_bootloader
    cmp #<$200
    bne !+
    lda smc_bootloader+1
    cmp #>$200
    bne !__b12+
    jmp __b12
  !__b12:
  !:
    // main::@7
    // if(smc_bootloader > 0x2)
    // [97] if(smc_bootloader#0>=2+1) goto main::@13 -- vwum1_ge_vbuc1_then_la1 
    lda smc_bootloader+1
    beq !__b13+
    jmp __b13
  !__b13:
    lda smc_bootloader
    cmp #2+1
    bcc !__b13+
    jmp __b13
  !__b13:
  !:
    // [98] phi from main::@7 to main::@8 [phi:main::@7->main::@8]
    // main::@8
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [99] call snprintf_init
    jsr snprintf_init
    // [100] phi from main::@8 to main::@81 [phi:main::@8->main::@81]
    // main::@81
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [101] call printf_str
    // [630] phi from main::@81 to printf_str [phi:main::@81->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:main::@81->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = main::s [phi:main::@81->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // main::@82
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [102] printf_uint::uvalue#14 = smc_bootloader#0 -- vwuz1=vwum2 
    lda smc_bootloader
    sta.z printf_uint.uvalue
    lda smc_bootloader+1
    sta.z printf_uint.uvalue+1
    // [103] call printf_uint
    // [639] phi from main::@82 to printf_uint [phi:main::@82->printf_uint]
    // [639] phi printf_uint::format_zero_padding#16 = 1 [phi:main::@82->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [639] phi printf_uint::format_min_length#16 = 2 [phi:main::@82->printf_uint#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uint.format_min_length
    // [639] phi printf_uint::putc#16 = &snputc [phi:main::@82->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [639] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:main::@82->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [639] phi printf_uint::uvalue#16 = printf_uint::uvalue#14 [phi:main::@82->printf_uint#4] -- register_copy 
    jsr printf_uint
    // main::@83
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
    // [650] phi from main::@83 to info_smc [phi:main::@83->info_smc]
    // [650] phi info_smc::info_text#11 = info_text [phi:main::@83->info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_smc.info_text
    lda #>@info_text
    sta.z info_smc.info_text+1
    // [650] phi smc_file_size#12 = 0 [phi:main::@83->info_smc#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size_2
    sta smc_file_size_2+1
    // [650] phi info_smc::info_status#11 = STATUS_DETECTED [phi:main::@83->info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_DETECTED
    sta info_smc.info_status
    jsr info_smc
    // main::CLI1
  CLI1:
    // asm
    // asm { cli  }
    cli
    // [109] phi from main::CLI1 to main::@54 [phi:main::CLI1->main::@54]
    // main::@54
    // chip_vera()
    // [110] call chip_vera
  // Detecting VERA FPGA.
    // [671] phi from main::@54 to chip_vera [phi:main::@54->chip_vera]
    jsr chip_vera
    // [111] phi from main::@54 to main::@84 [phi:main::@54->main::@84]
    // main::@84
    // info_vera(STATUS_DETECTED, "VERA installed, OK")
    // [112] call info_vera
    // [676] phi from main::@84 to info_vera [phi:main::@84->info_vera]
    // [676] phi info_vera::info_text#3 = main::info_text4 [phi:main::@84->info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z info_vera.info_text
    lda #>info_text4
    sta.z info_vera.info_text+1
    // [676] phi info_vera::info_status#3 = STATUS_DETECTED [phi:main::@84->info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_DETECTED
    sta.z info_vera.info_status
    jsr info_vera
    // main::SEI2
    // asm
    // asm { sei  }
    sei
    // [114] phi from main::SEI2 to main::@55 [phi:main::SEI2->main::@55]
    // main::@55
    // rom_detect()
    // [115] call rom_detect
  // Detecting ROM chips
    // [693] phi from main::@55 to rom_detect [phi:main::@55->rom_detect]
    jsr rom_detect
    // [116] phi from main::@55 to main::@85 [phi:main::@55->main::@85]
    // main::@85
    // chip_rom()
    // [117] call chip_rom
    // [743] phi from main::@85 to chip_rom [phi:main::@85->chip_rom]
    jsr chip_rom
    // [118] phi from main::@85 to main::@14 [phi:main::@85->main::@14]
    // [118] phi main::rom_chip#2 = 0 [phi:main::@85->main::@14#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // main::@14
  __b14:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [119] if(main::rom_chip#2<8) goto main::@15 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcs !__b15+
    jmp __b15
  !__b15:
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
    // main::@56
    // if(check_smc(STATUS_DETECTED))
    // [124] if(0==main::check_smc1_return#0) goto main::CLI3 -- 0_eq_vbuz1_then_la1 
    lda.z check_smc1_return
    bne !__b7+
    jmp __b7
  !__b7:
    // [125] phi from main::@56 to main::@19 [phi:main::@56->main::@19]
    // main::@19
    // smc_read(8, 512)
    // [126] call smc_read
    // [761] phi from main::@19 to smc_read [phi:main::@19->smc_read]
    // [761] phi __errno#35 = 0 [phi:main::@19->smc_read#0] -- vwsz1=vwsc1 
    lda #<0
    sta.z __errno
    sta.z __errno+1
    jsr smc_read
    // smc_read(8, 512)
    // [127] smc_read::return#2 = smc_read::return#0
    // main::@86
    // smc_file_size = smc_read(8, 512)
    // [128] smc_file_size#0 = smc_read::return#2 -- vwum1=vwum2 
    lda smc_read.return
    sta smc_file_size
    lda smc_read.return+1
    sta smc_file_size+1
    // if (!smc_file_size)
    // [129] if(0==smc_file_size#0) goto main::@22 -- 0_eq_vwum1_then_la1 
    // In case no file was found, set the status to error and skip to the next, else, mention the amount of bytes read.
    lda smc_file_size
    ora smc_file_size+1
    bne !__b22+
    jmp __b22
  !__b22:
    // main::@20
    // if(smc_file_size > 0x1E00)
    // [130] if(smc_file_size#0>$1e00) goto main::@23 -- vwum1_gt_vwuc1_then_la1 
    // If the smc.bin file size is larger than 0x1E00 then there is an error!
    lda #>$1e00
    cmp smc_file_size+1
    bcs !__b23+
    jmp __b23
  !__b23:
    bne !+
    lda #<$1e00
    cmp smc_file_size
    bcs !__b23+
    jmp __b23
  !__b23:
  !:
    // [131] phi from main::@20 to main::@21 [phi:main::@20->main::@21]
    // main::@21
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [132] call snprintf_init
    jsr snprintf_init
    // [133] phi from main::@21 to main::@87 [phi:main::@21->main::@87]
    // main::@87
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [134] call printf_str
    // [630] phi from main::@87 to printf_str [phi:main::@87->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:main::@87->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = main::s [phi:main::@87->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // main::@88
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [135] printf_uint::uvalue#15 = smc_bootloader#0 -- vwuz1=vwum2 
    lda smc_bootloader
    sta.z printf_uint.uvalue
    lda smc_bootloader+1
    sta.z printf_uint.uvalue+1
    // [136] call printf_uint
    // [639] phi from main::@88 to printf_uint [phi:main::@88->printf_uint]
    // [639] phi printf_uint::format_zero_padding#16 = 1 [phi:main::@88->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [639] phi printf_uint::format_min_length#16 = 2 [phi:main::@88->printf_uint#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uint.format_min_length
    // [639] phi printf_uint::putc#16 = &snputc [phi:main::@88->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [639] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:main::@88->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [639] phi printf_uint::uvalue#16 = printf_uint::uvalue#15 [phi:main::@88->printf_uint#4] -- register_copy 
    jsr printf_uint
    // main::@89
    // sprintf(info_text, "Bootloader v%02x", smc_bootloader)
    // [137] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [138] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [140] smc_file_size#282 = smc_file_size#0 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // info_smc(STATUS_FLASH, info_text)
    // [141] call info_smc
    // [650] phi from main::@89 to info_smc [phi:main::@89->info_smc]
    // [650] phi info_smc::info_text#11 = info_text [phi:main::@89->info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_smc.info_text
    lda #>@info_text
    sta.z info_smc.info_text+1
    // [650] phi smc_file_size#12 = smc_file_size#282 [phi:main::@89->info_smc#1] -- register_copy 
    // [650] phi info_smc::info_status#11 = STATUS_FLASH [phi:main::@89->info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta info_smc.info_status
    jsr info_smc
    // [142] phi from main::@22 main::@23 main::@89 to main::CLI3 [phi:main::@22/main::@23/main::@89->main::CLI3]
    // [142] phi smc_file_size#176 = smc_file_size#0 [phi:main::@22/main::@23/main::@89->main::CLI3#0] -- register_copy 
    // [142] phi __errno#248 = __errno#175 [phi:main::@22/main::@23/main::@89->main::CLI3#1] -- register_copy 
    jmp CLI3
    // [142] phi from main::@56 to main::CLI3 [phi:main::@56->main::CLI3]
  __b7:
    // [142] phi smc_file_size#176 = 0 [phi:main::@56->main::CLI3#0] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size
    sta smc_file_size+1
    // [142] phi __errno#248 = 0 [phi:main::@56->main::CLI3#1] -- vwsz1=vwsc1 
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
    // [145] phi from main::SEI4 to main::@24 [phi:main::SEI4->main::@24]
    // [145] phi __errno#110 = __errno#248 [phi:main::SEI4->main::@24#0] -- register_copy 
    // [145] phi main::rom_chip1#10 = 0 [phi:main::SEI4->main::@24#1] -- vbum1=vbuc1 
    lda #0
    sta rom_chip1
  // We loop all the possible ROM chip slots on the board and on the extension card,
  // and we check the file contents.
  // Any error identified gets reported and this chip will not be flashed.
  // In case of ROM0.BIN in error, no flashing will be done!
    // main::@24
  __b24:
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
    // main::@58
    // if(check_smc(STATUS_FLASH)  && check_cx16_rom(STATUS_FLASH))
    // [154] if(0==main::check_smc2_return#0) goto main::@2 -- 0_eq_vbuz1_then_la1 
    lda.z check_smc2_return
    beq __b9
    // main::@149
    // [155] if(0==main::check_cx16_rom1_check_rom1_return#0) goto main::@2 -- 0_eq_vbuz1_then_la1 
    lda.z check_cx16_rom1_check_rom1_return
    beq __b2
    // [156] phi from main::@149 to main::@31 [phi:main::@149->main::@31]
    // main::@31
    // [157] phi from main::@31 to main::@2 [phi:main::@31->main::@2]
    // [157] phi main::flash#10 = 1 [phi:main::@31->main::@2#0] -- vwum1=vbuc1 
    lda #<1
    sta flash
    lda #>1
    sta flash+1
    jmp __b2
    // [157] phi from main::@149 to main::@2 [phi:main::@149->main::@2]
    // [157] phi from main::@58 to main::@2 [phi:main::@58->main::@2]
  __b9:
    // [157] phi main::flash#10 = 0 [phi:main::@58->main::@2#0] -- vwum1=vwuc1 
    lda #<0
    sta flash
    sta flash+1
    // main::@2
  __b2:
    // [158] phi from main::@2 to main::check_card_roms1 [phi:main::@2->main::check_card_roms1]
    // main::check_card_roms1
    // [159] phi from main::check_card_roms1 to main::check_card_roms1_@1 [phi:main::check_card_roms1->main::check_card_roms1_@1]
    // [159] phi main::check_card_roms1_rom_chip#2 = 1 [phi:main::check_card_roms1->main::check_card_roms1_@1#0] -- vbum1=vbuc1 
    lda #1
    sta check_card_roms1_rom_chip
    // main::check_card_roms1_@1
  check_card_roms1___b1:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [160] if(main::check_card_roms1_rom_chip#2<8) goto main::check_card_roms1_check_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda check_card_roms1_rom_chip
    cmp #8
    bcs !check_card_roms1_check_rom1+
    jmp check_card_roms1_check_rom1
  !check_card_roms1_check_rom1:
    // [161] phi from main::check_card_roms1_@1 to main::check_card_roms1_@return [phi:main::check_card_roms1_@1->main::check_card_roms1_@return]
    // [161] phi main::check_card_roms1_return#2 = STATUS_NONE [phi:main::check_card_roms1_@1->main::check_card_roms1_@return#0] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta check_card_roms1_return
    // main::check_card_roms1_@return
    // main::@59
  __b59:
    // if(check_card_roms(STATUS_FLASH))
    // [162] if(0==main::check_card_roms1_return#2) goto main::@154 -- 0_eq_vbum1_then_la1 
    lda check_card_roms1_return
    beq __b3
    // [164] phi from main::@59 to main::@3 [phi:main::@59->main::@3]
    // [164] phi main::flash#3 = 1 [phi:main::@59->main::@3#0] -- vwum1=vbuc1 
    lda #<1
    sta flash
    lda #>1
    sta flash+1
    // [163] phi from main::@59 to main::@154 [phi:main::@59->main::@154]
    // main::@154
    // [164] phi from main::@154 to main::@3 [phi:main::@154->main::@3]
    // [164] phi main::flash#3 = main::flash#10 [phi:main::@154->main::@3#0] -- register_copy 
    // main::@3
  __b3:
    // if(flash)
    // [165] if(0!=main::flash#3) goto main::@4 -- 0_neq_vwum1_then_la1 
    lda flash
    ora flash+1
    beq !__b4+
    jmp __b4
  !__b4:
    // [166] phi from main::@3 to main::@9 [phi:main::@3->main::@9]
    // main::@9
    // info_progress("The SMC and the CX16 main ROM must be flashed together!")
    // [167] call info_progress
    // [596] phi from main::@9 to info_progress [phi:main::@9->info_progress]
    // [596] phi info_progress::info_text#12 = main::info_text13 [phi:main::@9->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text13
    sta.z info_progress.info_text
    lda #>info_text13
    sta.z info_progress.info_text+1
    jsr info_progress
    // [168] phi from main::@9 to main::@111 [phi:main::@9->main::@111]
    // main::@111
    // wait_key("Press [SPACE] to continue [ ]", " ")
    // [169] call wait_key
    // [818] phi from main::@111 to wait_key [phi:main::@111->wait_key]
    // [818] phi wait_key::filter#14 = main::filter1 [phi:main::@111->wait_key#0] -- pbuz1=pbuc1 
    lda #<filter1
    sta.z wait_key.filter
    lda #>filter1
    sta.z wait_key.filter+1
    // [818] phi wait_key::info_text#4 = main::info_text14 [phi:main::@111->wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text14
    sta.z wait_key.info_text
    lda #>info_text14
    sta.z wait_key.info_text+1
    jsr wait_key
    // main::@112
    // [170] smc_file_size#284 = smc_file_size#176 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // info_smc(STATUS_ISSUE, NULL)
    // [171] call info_smc
    // [650] phi from main::@112 to info_smc [phi:main::@112->info_smc]
    // [650] phi info_smc::info_text#11 = 0 [phi:main::@112->info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z info_smc.info_text
    sta.z info_smc.info_text+1
    // [650] phi smc_file_size#12 = smc_file_size#284 [phi:main::@112->info_smc#1] -- register_copy 
    // [650] phi info_smc::info_status#11 = STATUS_ISSUE [phi:main::@112->info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta info_smc.info_status
    jsr info_smc
    // [172] phi from main::@112 to main::@113 [phi:main::@112->main::@113]
    // main::@113
    // info_vera(STATUS_ISSUE, NULL)
    // [173] call info_vera
    // [676] phi from main::@113 to info_vera [phi:main::@113->info_vera]
    // [676] phi info_vera::info_text#3 = 0 [phi:main::@113->info_vera#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z info_vera.info_text
    sta.z info_vera.info_text+1
    // [676] phi info_vera::info_status#3 = STATUS_ISSUE [phi:main::@113->info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z info_vera.info_status
    jsr info_vera
    // [174] phi from main::@113 to main::@114 [phi:main::@113->main::@114]
    // main::@114
    // info_cx16_rom(STATUS_ISSUE, NULL)
    // [175] call info_cx16_rom
    // [842] phi from main::@114 to info_cx16_rom [phi:main::@114->info_cx16_rom]
    jsr info_cx16_rom
    // [176] phi from main::@114 to main::@32 [phi:main::@114->main::@32]
    // [176] phi main::rom_chip2#2 = 1 [phi:main::@114->main::@32#0] -- vbum1=vbuc1 
    lda #1
    sta rom_chip2
    // main::@32
  __b32:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [177] if(main::rom_chip2#2<8) goto main::@33 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip2
    cmp #8
    bcs !__b33+
    jmp __b33
  !__b33:
    // [178] phi from main::@32 to main::@34 [phi:main::@32->main::@34]
    // main::@34
    // info_line("No chipset will be flashed and there is an issue ... ")
    // [179] call info_line
    // [845] phi from main::@34 to info_line [phi:main::@34->info_line]
    // [845] phi info_line::info_text#18 = main::info_text16 [phi:main::@34->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text16
    sta.z info_line.info_text
    lda #>info_text16
    sta.z info_line.info_text+1
    jsr info_line
    // main::check_smc3
  check_smc3:
    // status_smc == status
    // [180] main::check_smc3_$0 = status_smc#0 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_smc3_main__0
    // return (unsigned char)(status_smc == status);
    // [181] main::check_smc3_return#0 = (char)main::check_smc3_$0
    // main::@60
    // if (check_smc(STATUS_FLASH))
    // [182] if(0==main::check_smc3_return#0) goto main::@5 -- 0_eq_vbum1_then_la1 
    lda check_smc3_return
    beq __b5
    // main::SEI5
    // asm
    // asm { sei  }
    sei
    // [184] phi from main::SEI5 to main::@61 [phi:main::SEI5->main::@61]
    // main::@61
    // smc_read(8, 512)
    // [185] call smc_read
    // [761] phi from main::@61 to smc_read [phi:main::@61->smc_read]
    // [761] phi __errno#35 = __errno#110 [phi:main::@61->smc_read#0] -- register_copy 
    jsr smc_read
    // smc_read(8, 512)
    // [186] smc_read::return#3 = smc_read::return#0
    // main::@118
    // smc_file_size = smc_read(8, 512)
    // [187] smc_file_size#1 = smc_read::return#3 -- vwum1=vwum2 
    lda smc_read.return
    sta smc_file_size_1
    lda smc_read.return+1
    sta smc_file_size_1+1
    // if(smc_file_size)
    // [188] if(0==smc_file_size#1) goto main::@5 -- 0_eq_vwum1_then_la1 
    lda smc_file_size_1
    ora smc_file_size_1+1
    beq __b5
    // [189] phi from main::@118 to main::@11 [phi:main::@118->main::@11]
    // main::@11
    // info_line("Press both POWER/RESET buttons on the CX16 board!")
    // [190] call info_line
  // Flash the SMC chip.
    // [845] phi from main::@11 to info_line [phi:main::@11->info_line]
    // [845] phi info_line::info_text#18 = main::info_text21 [phi:main::@11->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text21
    sta.z info_line.info_text
    lda #>info_text21
    sta.z info_line.info_text+1
    jsr info_line
    // main::@119
    // [191] smc_file_size#285 = smc_file_size#1 -- vwum1=vwum2 
    lda smc_file_size_1
    sta smc_file_size_2
    lda smc_file_size_1+1
    sta smc_file_size_2+1
    // info_smc(STATUS_FLASHING, "Press POWER/RESET!")
    // [192] call info_smc
    // [650] phi from main::@119 to info_smc [phi:main::@119->info_smc]
    // [650] phi info_smc::info_text#11 = main::info_text22 [phi:main::@119->info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text22
    sta.z info_smc.info_text
    lda #>info_text22
    sta.z info_smc.info_text+1
    // [650] phi smc_file_size#12 = smc_file_size#285 [phi:main::@119->info_smc#1] -- register_copy 
    // [650] phi info_smc::info_status#11 = STATUS_FLASHING [phi:main::@119->info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHING
    sta info_smc.info_status
    jsr info_smc
    // main::@120
    // unsigned long flashed_bytes = flash_smc(PROGRESS_X, PROGRESS_Y, PROGRESS_W, smc_file_size, 8, 512, (ram_ptr_t)RAM_BASE)
    // [193] flash_smc::smc_bytes_total#0 = smc_file_size#1 -- vwuz1=vwum2 
    lda smc_file_size_1
    sta.z flash_smc.smc_bytes_total
    lda smc_file_size_1+1
    sta.z flash_smc.smc_bytes_total+1
    // [194] call flash_smc
    jsr flash_smc
    // main::@121
    // [195] smc_file_size#286 = smc_file_size#1 -- vwum1=vwum2 
    lda smc_file_size_1
    sta smc_file_size_2
    lda smc_file_size_1+1
    sta smc_file_size_2+1
    // info_smc(STATUS_FLASHED, "OK!")
    // [196] call info_smc
    // [650] phi from main::@121 to info_smc [phi:main::@121->info_smc]
    // [650] phi info_smc::info_text#11 = main::info_text10 [phi:main::@121->info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text10
    sta.z info_smc.info_text
    lda #>info_text10
    sta.z info_smc.info_text+1
    // [650] phi smc_file_size#12 = smc_file_size#286 [phi:main::@121->info_smc#1] -- register_copy 
    // [650] phi info_smc::info_status#11 = STATUS_FLASHED [phi:main::@121->info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHED
    sta info_smc.info_status
    jsr info_smc
    // [197] phi from main::@118 main::@121 main::@60 to main::@5 [phi:main::@118/main::@121/main::@60->main::@5]
    // [197] phi __errno#296 = __errno#175 [phi:main::@118/main::@121/main::@60->main::@5#0] -- register_copy 
    // main::@5
  __b5:
    // [198] phi from main::@5 to main::@38 [phi:main::@5->main::@38]
    // [198] phi __errno#112 = __errno#296 [phi:main::@5->main::@38#0] -- register_copy 
    // [198] phi main::rom_chip4#10 = 0 [phi:main::@5->main::@38#1] -- vbum1=vbuc1 
    lda #0
    sta rom_chip4
  // Flash the ROM chips. 
  // We loop first all the ROM chips and read the file contents.
  // Then we verify the file contents and flash the ROM only for the differences.
  // If the file contents are the same as the ROM contents, then no flashing is required.
    // main::@38
  __b38:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [199] if(main::rom_chip4#10<8) goto main::check_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip4
    cmp #8
    bcs !check_rom1+
    jmp check_rom1
  !check_rom1:
    // main::bank_set_brom4
    // BROM = bank
    // [200] BROM = main::bank_set_brom4_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom4_bank
    sta.z BROM
    // main::CLI5
    // asm
    // asm { cli  }
    cli
    // [202] phi from main::CLI5 to main::@63 [phi:main::CLI5->main::@63]
    // main::@63
    // info_progress("Update finished ...")
    // [203] call info_progress
    // [596] phi from main::@63 to info_progress [phi:main::@63->info_progress]
    // [596] phi info_progress::info_text#12 = main::info_text24 [phi:main::@63->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text24
    sta.z info_progress.info_text
    lda #>info_text24
    sta.z info_progress.info_text+1
    jsr info_progress
    // main::check_smc4
    // status_smc == status
    // [204] main::check_smc4_$0 = status_smc#0 == STATUS_ERROR -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta check_smc4_main__0
    // return (unsigned char)(status_smc == status);
    // [205] main::check_smc4_return#0 = (char)main::check_smc4_$0
    // main::check_vera1
    // status_vera == status
    // [206] main::check_vera1_$0 = status_vera#0 == STATUS_ERROR -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_vera1_main__0
    // return (unsigned char)(status_vera == status);
    // [207] main::check_vera1_return#0 = (char)main::check_vera1_$0
    // [208] phi from main::check_vera1 to main::check_roms1 [phi:main::check_vera1->main::check_roms1]
    // main::check_roms1
    // [209] phi from main::check_roms1 to main::check_roms1_@1 [phi:main::check_roms1->main::check_roms1_@1]
    // [209] phi main::check_roms1_rom_chip#2 = 0 [phi:main::check_roms1->main::check_roms1_@1#0] -- vbum1=vbuc1 
    lda #0
    sta check_roms1_rom_chip
    // main::check_roms1_@1
  check_roms1___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [210] if(main::check_roms1_rom_chip#2<8) goto main::check_roms1_check_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda check_roms1_rom_chip
    cmp #8
    bcs !check_roms1_check_rom1+
    jmp check_roms1_check_rom1
  !check_roms1_check_rom1:
    // [211] phi from main::check_roms1_@1 to main::check_roms1_@return [phi:main::check_roms1_@1->main::check_roms1_@return]
    // [211] phi main::check_roms1_return#2 = STATUS_NONE [phi:main::check_roms1_@1->main::check_roms1_@return#0] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta check_roms1_return
    // main::check_roms1_@return
    // main::@64
  __b64:
    // if(check_smc(STATUS_ERROR) || check_vera(STATUS_ERROR) || check_roms(STATUS_ERROR))
    // [212] if(0!=main::check_smc4_return#0) goto main::vera_display_set_border_color1 -- 0_neq_vbum1_then_la1 
    lda check_smc4_return
    beq !vera_display_set_border_color1+
    jmp vera_display_set_border_color1
  !vera_display_set_border_color1:
    // main::@151
    // [213] if(0!=main::check_vera1_return#0) goto main::vera_display_set_border_color1 -- 0_neq_vbuz1_then_la1 
    lda.z check_vera1_return
    beq !vera_display_set_border_color1+
    jmp vera_display_set_border_color1
  !vera_display_set_border_color1:
    // main::@150
    // [214] if(0!=main::check_roms1_return#2) goto main::vera_display_set_border_color1 -- 0_neq_vbum1_then_la1 
    lda check_roms1_return
    beq !vera_display_set_border_color1+
    jmp vera_display_set_border_color1
  !vera_display_set_border_color1:
    // main::check_smc5
    // status_smc == status
    // [215] main::check_smc5_$0 = status_smc#0 == STATUS_ISSUE -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_smc5_main__0
    // return (unsigned char)(status_smc == status);
    // [216] main::check_smc5_return#0 = (char)main::check_smc5_$0
    // main::check_vera2
    // status_vera == status
    // [217] main::check_vera2_$0 = status_vera#0 == STATUS_ISSUE -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta check_vera2_main__0
    // return (unsigned char)(status_vera == status);
    // [218] main::check_vera2_return#0 = (char)main::check_vera2_$0
    // [219] phi from main::check_vera2 to main::check_roms2 [phi:main::check_vera2->main::check_roms2]
    // main::check_roms2
    // [220] phi from main::check_roms2 to main::check_roms2_@1 [phi:main::check_roms2->main::check_roms2_@1]
    // [220] phi main::check_roms2_rom_chip#2 = 0 [phi:main::check_roms2->main::check_roms2_@1#0] -- vbum1=vbuc1 
    lda #0
    sta check_roms2_rom_chip
    // main::check_roms2_@1
  check_roms2___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [221] if(main::check_roms2_rom_chip#2<8) goto main::check_roms2_check_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda check_roms2_rom_chip
    cmp #8
    bcs !check_roms2_check_rom1+
    jmp check_roms2_check_rom1
  !check_roms2_check_rom1:
    // [222] phi from main::check_roms2_@1 to main::check_roms2_@return [phi:main::check_roms2_@1->main::check_roms2_@return]
    // [222] phi main::check_roms2_return#2 = STATUS_NONE [phi:main::check_roms2_@1->main::check_roms2_@return#0] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta check_roms2_return
    // main::check_roms2_@return
    // main::@67
  __b67:
    // if(check_smc(STATUS_ISSUE) || check_vera(STATUS_ISSUE) || check_roms(STATUS_ISSUE))
    // [223] if(0!=main::check_smc5_return#0) goto main::vera_display_set_border_color2 -- 0_neq_vbuz1_then_la1 
    lda.z check_smc5_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::@153
    // [224] if(0!=main::check_vera2_return#0) goto main::vera_display_set_border_color2 -- 0_neq_vbum1_then_la1 
    lda check_vera2_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::@152
    // [225] if(0!=main::check_roms2_return#2) goto main::vera_display_set_border_color2 -- 0_neq_vbum1_then_la1 
    lda check_roms2_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::vera_display_set_border_color3
    // *VERA_CTRL &= ~VERA_DCSEL
    // [226] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [227] *VERA_DC_BORDER = GREEN -- _deref_pbuc1=vbuc2 
    lda #GREEN
    sta VERA_DC_BORDER
    // [228] phi from main::vera_display_set_border_color3 to main::@69 [phi:main::vera_display_set_border_color3->main::@69]
    // main::@69
    // info_progress("Upgrade Success!")
    // [229] call info_progress
    // [596] phi from main::@69 to info_progress [phi:main::@69->info_progress]
    // [596] phi info_progress::info_text#12 = main::info_text33 [phi:main::@69->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text33
    sta.z info_progress.info_text
    lda #>info_text33
    sta.z info_progress.info_text+1
    jsr info_progress
    // [230] phi from main::@69 to main::@143 [phi:main::@69->main::@143]
    // main::@143
    // wait_key("Press any key to reset your CX16 ...", NULL)
    // [231] call wait_key
    // [818] phi from main::@143 to wait_key [phi:main::@143->wait_key]
    // [818] phi wait_key::filter#14 = 0 [phi:main::@143->wait_key#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z wait_key.filter
    sta.z wait_key.filter+1
    // [818] phi wait_key::info_text#4 = main::info_text34 [phi:main::@143->wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text34
    sta.z wait_key.info_text
    lda #>info_text34
    sta.z wait_key.info_text+1
    jsr wait_key
    // [232] phi from main::@142 main::@143 to main::@46 [phi:main::@142/main::@143->main::@46]
  __b10:
    // [232] phi main::flash_reset#10 = 0 [phi:main::@142/main::@143->main::@46#0] -- vbum1=vbuc1 
    lda #0
    sta flash_reset
    // main::@46
  __b46:
    // for(unsigned char flash_reset=0; flash_reset<120; flash_reset++)
    // [233] if(main::flash_reset#10<$78) goto main::@48 -- vbum1_lt_vbuc1_then_la1 
    lda flash_reset
    cmp #$78
    bcc __b11
    // [234] phi from main::@46 to main::@47 [phi:main::@46->main::@47]
    // main::@47
    // system_reset()
    // [235] call system_reset
    // [1023] phi from main::@47 to system_reset [phi:main::@47->system_reset]
    jsr system_reset
    // main::@return
    // }
    // [236] return 
    rts
    // [237] phi from main::@46 to main::@48 [phi:main::@46->main::@48]
  __b11:
    // [237] phi main::reset_wait#2 = 0 [phi:main::@46->main::@48#0] -- vwum1=vwuc1 
    lda #<0
    sta reset_wait
    sta reset_wait+1
    // main::@48
  __b48:
    // for(unsigned int reset_wait=0; reset_wait<0xFFFF; reset_wait++)
    // [238] if(main::reset_wait#2<$ffff) goto main::@49 -- vwum1_lt_vwuc1_then_la1 
    lda reset_wait+1
    cmp #>$ffff
    bcc __b49
    bne !+
    lda reset_wait
    cmp #<$ffff
    bcc __b49
  !:
    // [239] phi from main::@48 to main::@50 [phi:main::@48->main::@50]
    // main::@50
    // sprintf(info_text, "Resetting your CX16 ... (%u)", flash_reset)
    // [240] call snprintf_init
    jsr snprintf_init
    // [241] phi from main::@50 to main::@144 [phi:main::@50->main::@144]
    // main::@144
    // sprintf(info_text, "Resetting your CX16 ... (%u)", flash_reset)
    // [242] call printf_str
    // [630] phi from main::@144 to printf_str [phi:main::@144->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:main::@144->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = main::s14 [phi:main::@144->printf_str#1] -- pbuz1=pbuc1 
    lda #<s14
    sta.z printf_str.s
    lda #>s14
    sta.z printf_str.s+1
    jsr printf_str
    // main::@145
    // sprintf(info_text, "Resetting your CX16 ... (%u)", flash_reset)
    // [243] printf_uchar::uvalue#8 = main::flash_reset#10 -- vbuz1=vbum2 
    lda flash_reset
    sta.z printf_uchar.uvalue
    // [244] call printf_uchar
    // [1028] phi from main::@145 to printf_uchar [phi:main::@145->printf_uchar]
    // [1028] phi printf_uchar::format_zero_padding#10 = 0 [phi:main::@145->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1028] phi printf_uchar::format_min_length#10 = 0 [phi:main::@145->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1028] phi printf_uchar::putc#10 = &snputc [phi:main::@145->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1028] phi printf_uchar::format_radix#10 = DECIMAL [phi:main::@145->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1028] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#8 [phi:main::@145->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [245] phi from main::@145 to main::@146 [phi:main::@145->main::@146]
    // main::@146
    // sprintf(info_text, "Resetting your CX16 ... (%u)", flash_reset)
    // [246] call printf_str
    // [630] phi from main::@146 to printf_str [phi:main::@146->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:main::@146->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = main::s15 [phi:main::@146->printf_str#1] -- pbuz1=pbuc1 
    lda #<s15
    sta.z printf_str.s
    lda #>s15
    sta.z printf_str.s+1
    jsr printf_str
    // main::@147
    // sprintf(info_text, "Resetting your CX16 ... (%u)", flash_reset)
    // [247] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [248] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [250] call info_line
    // [845] phi from main::@147 to info_line [phi:main::@147->info_line]
    // [845] phi info_line::info_text#18 = info_text [phi:main::@147->info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_line.info_text
    lda #>@info_text
    sta.z info_line.info_text+1
    jsr info_line
    // main::@148
    // for(unsigned char flash_reset=0; flash_reset<120; flash_reset++)
    // [251] main::flash_reset#1 = ++ main::flash_reset#10 -- vbum1=_inc_vbum1 
    inc flash_reset
    // [232] phi from main::@148 to main::@46 [phi:main::@148->main::@46]
    // [232] phi main::flash_reset#10 = main::flash_reset#1 [phi:main::@148->main::@46#0] -- register_copy 
    jmp __b46
    // main::@49
  __b49:
    // for(unsigned int reset_wait=0; reset_wait<0xFFFF; reset_wait++)
    // [252] main::reset_wait#1 = ++ main::reset_wait#2 -- vwum1=_inc_vwum1 
    inc reset_wait
    bne !+
    inc reset_wait+1
  !:
    // [237] phi from main::@49 to main::@48 [phi:main::@49->main::@48]
    // [237] phi main::reset_wait#2 = main::reset_wait#1 [phi:main::@49->main::@48#0] -- register_copy 
    jmp __b48
    // main::vera_display_set_border_color2
  vera_display_set_border_color2:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [253] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [254] *VERA_DC_BORDER = YELLOW -- _deref_pbuc1=vbuc2 
    lda #YELLOW
    sta VERA_DC_BORDER
    // [255] phi from main::vera_display_set_border_color2 to main::@68 [phi:main::vera_display_set_border_color2->main::@68]
    // main::@68
    // info_progress("Upgrade Issues ...")
    // [256] call info_progress
    // [596] phi from main::@68 to info_progress [phi:main::@68->info_progress]
    // [596] phi info_progress::info_text#12 = main::info_text31 [phi:main::@68->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text31
    sta.z info_progress.info_text
    lda #>info_text31
    sta.z info_progress.info_text+1
    jsr info_progress
    // [257] phi from main::@68 to main::@142 [phi:main::@68->main::@142]
    // main::@142
    // wait_key("Take a foto of this screen. Press a key for next steps ...", NULL)
    // [258] call wait_key
    // [818] phi from main::@142 to wait_key [phi:main::@142->wait_key]
    // [818] phi wait_key::filter#14 = 0 [phi:main::@142->wait_key#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z wait_key.filter
    sta.z wait_key.filter+1
    // [818] phi wait_key::info_text#4 = main::info_text32 [phi:main::@142->wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text32
    sta.z wait_key.info_text
    lda #>info_text32
    sta.z wait_key.info_text+1
    jsr wait_key
    jmp __b10
    // main::check_roms2_check_rom1
  check_roms2_check_rom1:
    // status_rom[rom_chip] == status
    // [259] main::check_roms2_check_rom1_$0 = status_rom[main::check_roms2_rom_chip#2] == STATUS_ISSUE -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_ISSUE
    ldy check_roms2_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_roms2_check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [260] main::check_roms2_check_rom1_return#0 = (char)main::check_roms2_check_rom1_$0
    // main::check_roms2_@11
    // if(check_rom(rom_chip, status) == status)
    // [261] if(main::check_roms2_check_rom1_return#0!=STATUS_ISSUE) goto main::check_roms2_@4 -- vbuz1_neq_vbuc1_then_la1 
    lda #STATUS_ISSUE
    cmp.z check_roms2_check_rom1_return
    bne check_roms2___b4
    // [222] phi from main::check_roms2_@11 to main::check_roms2_@return [phi:main::check_roms2_@11->main::check_roms2_@return]
    // [222] phi main::check_roms2_return#2 = STATUS_ISSUE [phi:main::check_roms2_@11->main::check_roms2_@return#0] -- vbum1=vbuc1 
    sta check_roms2_return
    jmp __b67
    // main::check_roms2_@4
  check_roms2___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [262] main::check_roms2_rom_chip#1 = ++ main::check_roms2_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_roms2_rom_chip
    // [220] phi from main::check_roms2_@4 to main::check_roms2_@1 [phi:main::check_roms2_@4->main::check_roms2_@1]
    // [220] phi main::check_roms2_rom_chip#2 = main::check_roms2_rom_chip#1 [phi:main::check_roms2_@4->main::check_roms2_@1#0] -- register_copy 
    jmp check_roms2___b1
    // main::vera_display_set_border_color1
  vera_display_set_border_color1:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [263] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [264] *VERA_DC_BORDER = RED -- _deref_pbuc1=vbuc2 
    lda #RED
    sta VERA_DC_BORDER
    // [265] phi from main::vera_display_set_border_color1 to main::@66 [phi:main::vera_display_set_border_color1->main::@66]
    // main::@66
    // info_progress("Upgrade Failure! Your CX16 may be bricked!")
    // [266] call info_progress
    // [596] phi from main::@66 to info_progress [phi:main::@66->info_progress]
    // [596] phi info_progress::info_text#12 = main::info_text29 [phi:main::@66->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text29
    sta.z info_progress.info_text
    lda #>info_text29
    sta.z info_progress.info_text+1
    jsr info_progress
    // [267] phi from main::@66 to main::@141 [phi:main::@66->main::@141]
    // main::@141
    // info_line("Take a foto of this screen. And shut down power ...")
    // [268] call info_line
    // [845] phi from main::@141 to info_line [phi:main::@141->info_line]
    // [845] phi info_line::info_text#18 = main::info_text30 [phi:main::@141->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text30
    sta.z info_line.info_text
    lda #>info_text30
    sta.z info_line.info_text+1
    jsr info_line
    // [269] phi from main::@141 main::@45 to main::@45 [phi:main::@141/main::@45->main::@45]
    // main::@45
  __b45:
    jmp __b45
    // main::check_roms1_check_rom1
  check_roms1_check_rom1:
    // status_rom[rom_chip] == status
    // [270] main::check_roms1_check_rom1_$0 = status_rom[main::check_roms1_rom_chip#2] == STATUS_ERROR -- vbom1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_ERROR
    ldy check_roms1_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta check_roms1_check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [271] main::check_roms1_check_rom1_return#0 = (char)main::check_roms1_check_rom1_$0
    // main::check_roms1_@11
    // if(check_rom(rom_chip, status) == status)
    // [272] if(main::check_roms1_check_rom1_return#0!=STATUS_ERROR) goto main::check_roms1_@4 -- vbum1_neq_vbuc1_then_la1 
    lda #STATUS_ERROR
    cmp check_roms1_check_rom1_return
    bne check_roms1___b4
    // [211] phi from main::check_roms1_@11 to main::check_roms1_@return [phi:main::check_roms1_@11->main::check_roms1_@return]
    // [211] phi main::check_roms1_return#2 = STATUS_ERROR [phi:main::check_roms1_@11->main::check_roms1_@return#0] -- vbum1=vbuc1 
    sta check_roms1_return
    jmp __b64
    // main::check_roms1_@4
  check_roms1___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [273] main::check_roms1_rom_chip#1 = ++ main::check_roms1_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_roms1_rom_chip
    // [209] phi from main::check_roms1_@4 to main::check_roms1_@1 [phi:main::check_roms1_@4->main::check_roms1_@1]
    // [209] phi main::check_roms1_rom_chip#2 = main::check_roms1_rom_chip#1 [phi:main::check_roms1_@4->main::check_roms1_@1#0] -- register_copy 
    jmp check_roms1___b1
    // main::check_rom1
  check_rom1:
    // status_rom[rom_chip] == status
    // [274] main::check_rom1_$0 = status_rom[main::rom_chip4#10] == STATUS_FLASH -- vbom1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_FLASH
    ldy rom_chip4
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [275] main::check_rom1_return#0 = (char)main::check_rom1_$0
    // main::@62
    // if(check_rom(rom_chip, STATUS_FLASH))
    // [276] if(0==main::check_rom1_return#0) goto main::@39 -- 0_eq_vbum1_then_la1 
    lda check_rom1_return
    bne !__b39+
    jmp __b39
  !__b39:
    // main::bank_set_brom5
    // BROM = bank
    // [277] BROM = main::bank_set_brom5_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom5_bank
    sta.z BROM
    // [278] phi from main::bank_set_brom5 to main::@65 [phi:main::bank_set_brom5->main::@65]
    // main::@65
    // progress_clear()
    // [279] call progress_clear
    // [571] phi from main::@65 to progress_clear [phi:main::@65->progress_clear]
    jsr progress_clear
    // main::@122
    // unsigned char rom_bank = rom_chip * 32
    // [280] main::rom_bank1#0 = main::rom_chip4#10 << 5 -- vbum1=vbum2_rol_5 
    lda rom_chip4
    asl
    asl
    asl
    asl
    asl
    sta rom_bank1
    // unsigned char* file = rom_file(rom_chip)
    // [281] rom_file::rom_chip#1 = main::rom_chip4#10 -- vbum1=vbum2 
    lda rom_chip4
    sta rom_file.rom_chip
    // [282] call rom_file
    // [1039] phi from main::@122 to rom_file [phi:main::@122->rom_file]
    // [1039] phi rom_file::rom_chip#2 = rom_file::rom_chip#1 [phi:main::@122->rom_file#0] -- register_copy 
    jsr rom_file
    // [283] phi from main::@122 to main::@123 [phi:main::@122->main::@123]
    // main::@123
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [284] call snprintf_init
    jsr snprintf_init
    // [285] phi from main::@123 to main::@124 [phi:main::@123->main::@124]
    // main::@124
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [286] call printf_str
    // [630] phi from main::@124 to printf_str [phi:main::@124->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:main::@124->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = s10 [phi:main::@124->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // [287] phi from main::@124 to main::@125 [phi:main::@124->main::@125]
    // main::@125
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [288] call printf_string
    // [1044] phi from main::@125 to printf_string [phi:main::@125->printf_string]
    // [1044] phi printf_string::putc#16 = &snputc [phi:main::@125->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1044] phi printf_string::str#16 = rom_file::file [phi:main::@125->printf_string#1] -- pbuz1=pbuc1 
    lda #<rom_file.file
    sta.z printf_string.str
    lda #>rom_file.file
    sta.z printf_string.str+1
    // [1044] phi printf_string::format_justify_left#16 = 0 [phi:main::@125->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1044] phi printf_string::format_min_length#16 = 0 [phi:main::@125->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [289] phi from main::@125 to main::@126 [phi:main::@125->main::@126]
    // main::@126
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [290] call printf_str
    // [630] phi from main::@126 to printf_str [phi:main::@126->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:main::@126->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = main::s5 [phi:main::@126->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // main::@127
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [291] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [292] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_progress(info_text)
    // [294] call info_progress
    // [596] phi from main::@127 to info_progress [phi:main::@127->info_progress]
    // [596] phi info_progress::info_text#12 = info_text [phi:main::@127->info_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_progress.info_text
    lda #>@info_text
    sta.z info_progress.info_text+1
    jsr info_progress
    // main::@128
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, rom_bank, rom_sizes[rom_chip])
    // [295] main::$148 = main::rom_chip4#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip4
    asl
    asl
    sta main__148
    // [296] rom_read::brom_bank_start#2 = main::rom_bank1#0 -- vbuz1=vbum2 
    lda rom_bank1
    sta.z rom_read.brom_bank_start
    // [297] rom_read::rom_size#1 = rom_sizes[main::$148] -- vduz1=pduc1_derefidx_vbum2 
    ldy main__148
    lda rom_sizes,y
    sta.z rom_read.rom_size
    lda rom_sizes+1,y
    sta.z rom_read.rom_size+1
    lda rom_sizes+2,y
    sta.z rom_read.rom_size+2
    lda rom_sizes+3,y
    sta.z rom_read.rom_size+3
    // [298] call rom_read
    // [1069] phi from main::@128 to rom_read [phi:main::@128->rom_read]
    // [1069] phi rom_read::rom_size#12 = rom_read::rom_size#1 [phi:main::@128->rom_read#0] -- register_copy 
    // [1069] phi __errno#104 = __errno#112 [phi:main::@128->rom_read#1] -- register_copy 
    // [1069] phi rom_read::brom_bank_start#21 = rom_read::brom_bank_start#2 [phi:main::@128->rom_read#2] -- register_copy 
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, rom_bank, rom_sizes[rom_chip])
    // [299] rom_read::return#3 = rom_read::return#0
    // main::@129
    // [300] main::rom_bytes_read1#0 = rom_read::return#3
    // if(rom_bytes_read)
    // [301] if(0==main::rom_bytes_read1#0) goto main::@39 -- 0_eq_vdum1_then_la1 
    lda rom_bytes_read1
    ora rom_bytes_read1+1
    ora rom_bytes_read1+2
    ora rom_bytes_read1+3
    bne !__b39+
    jmp __b39
  !__b39:
    // [302] phi from main::@129 to main::@42 [phi:main::@129->main::@42]
    // main::@42
    // info_progress("Comparing ... (.) same, (*) different.")
    // [303] call info_progress
  // Now we compare the RAM with the actual ROM contents.
    // [596] phi from main::@42 to info_progress [phi:main::@42->info_progress]
    // [596] phi info_progress::info_text#12 = main::info_text25 [phi:main::@42->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text25
    sta.z info_progress.info_text
    lda #>info_text25
    sta.z info_progress.info_text+1
    jsr info_progress
    // main::@130
    // info_rom(rom_chip, STATUS_COMPARING, "")
    // [304] info_rom::rom_chip#12 = main::rom_chip4#10 -- vbuz1=vbum2 
    lda rom_chip4
    sta.z info_rom.rom_chip
    // [305] call info_rom
    // [1157] phi from main::@130 to info_rom [phi:main::@130->info_rom]
    // [1157] phi info_rom::info_text#17 = info_text5 [phi:main::@130->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z info_rom.info_text
    lda #>info_text5
    sta.z info_rom.info_text+1
    // [1157] phi info_rom::rom_chip#17 = info_rom::rom_chip#12 [phi:main::@130->info_rom#1] -- register_copy 
    // [1157] phi info_rom::info_status#17 = STATUS_COMPARING [phi:main::@130->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_COMPARING
    sta.z info_rom.info_status
    jsr info_rom
    // main::@131
    // unsigned long rom_differences = rom_verify(
    //                     rom_chip, rom_bank, file_sizes[rom_chip])
    // [306] rom_verify::rom_chip#0 = main::rom_chip4#10 -- vbuz1=vbum2 
    lda rom_chip4
    sta.z rom_verify.rom_chip
    // [307] rom_verify::rom_bank_start#0 = main::rom_bank1#0 -- vbuz1=vbum2 
    lda rom_bank1
    sta.z rom_verify.rom_bank_start
    // [308] rom_verify::file_size#0 = file_sizes[main::$148] -- vduz1=pduc1_derefidx_vbum2 
    ldy main__148
    lda file_sizes,y
    sta.z rom_verify.file_size
    lda file_sizes+1,y
    sta.z rom_verify.file_size+1
    lda file_sizes+2,y
    sta.z rom_verify.file_size+2
    lda file_sizes+3,y
    sta.z rom_verify.file_size+3
    // [309] call rom_verify
    // Verify the ROM...
    jsr rom_verify
    // [310] rom_verify::return#2 = rom_verify::rom_different_bytes#11
    // main::@132
    // [311] main::rom_differences#0 = rom_verify::return#2 -- vduz1=vduz2 
    lda.z rom_verify.return
    sta.z rom_differences
    lda.z rom_verify.return+1
    sta.z rom_differences+1
    lda.z rom_verify.return+2
    sta.z rom_differences+2
    lda.z rom_verify.return+3
    sta.z rom_differences+3
    // if (!rom_differences)
    // [312] if(0==main::rom_differences#0) goto main::@40 -- 0_eq_vduz1_then_la1 
    lda.z rom_differences
    ora.z rom_differences+1
    ora.z rom_differences+2
    ora.z rom_differences+3
    bne !__b40+
    jmp __b40
  !__b40:
    // [313] phi from main::@132 to main::@43 [phi:main::@132->main::@43]
    // main::@43
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [314] call snprintf_init
    jsr snprintf_init
    // main::@133
    // [315] printf_ulong::uvalue#9 = main::rom_differences#0
    // [316] call printf_ulong
    // [1255] phi from main::@133 to printf_ulong [phi:main::@133->printf_ulong]
    // [1255] phi printf_ulong::format_zero_padding#11 = 1 [phi:main::@133->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1255] phi printf_ulong::format_min_length#11 = 5 [phi:main::@133->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1255] phi printf_ulong::putc#11 = &snputc [phi:main::@133->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1255] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:main::@133->printf_ulong#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1255] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#9 [phi:main::@133->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [317] phi from main::@133 to main::@134 [phi:main::@133->main::@134]
    // main::@134
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [318] call printf_str
    // [630] phi from main::@134 to printf_str [phi:main::@134->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:main::@134->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = main::s12 [phi:main::@134->printf_str#1] -- pbuz1=pbuc1 
    lda #<s12
    sta.z printf_str.s
    lda #>s12
    sta.z printf_str.s+1
    jsr printf_str
    // main::@135
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [319] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [320] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom(rom_chip, STATUS_FLASH, info_text)
    // [322] info_rom::rom_chip#14 = main::rom_chip4#10 -- vbuz1=vbum2 
    lda rom_chip4
    sta.z info_rom.rom_chip
    // [323] call info_rom
    // [1157] phi from main::@135 to info_rom [phi:main::@135->info_rom]
    // [1157] phi info_rom::info_text#17 = info_text [phi:main::@135->info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_rom.info_text
    lda #>@info_text
    sta.z info_rom.info_text+1
    // [1157] phi info_rom::rom_chip#17 = info_rom::rom_chip#14 [phi:main::@135->info_rom#1] -- register_copy 
    // [1157] phi info_rom::info_status#17 = STATUS_FLASH [phi:main::@135->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASH
    sta.z info_rom.info_status
    jsr info_rom
    // main::@136
    // unsigned long rom_flash_errors = rom_flash(
    //                         rom_chip, rom_bank, file_sizes[rom_chip])
    // [324] rom_flash::rom_chip#0 = main::rom_chip4#10 -- vbum1=vbum2 
    lda rom_chip4
    sta rom_flash.rom_chip
    // [325] rom_flash::rom_bank_start#0 = main::rom_bank1#0 -- vbuz1=vbum2 
    lda rom_bank1
    sta.z rom_flash.rom_bank_start
    // [326] rom_flash::file_size#0 = file_sizes[main::$148] -- vdum1=pduc1_derefidx_vbum2 
    ldy main__148
    lda file_sizes,y
    sta rom_flash.file_size
    lda file_sizes+1,y
    sta rom_flash.file_size+1
    lda file_sizes+2,y
    sta rom_flash.file_size+2
    lda file_sizes+3,y
    sta rom_flash.file_size+3
    // [327] call rom_flash
    // [1266] phi from main::@136 to rom_flash [phi:main::@136->rom_flash]
    jsr rom_flash
    // unsigned long rom_flash_errors = rom_flash(
    //                         rom_chip, rom_bank, file_sizes[rom_chip])
    // [328] rom_flash::return#2 = rom_flash::flash_errors#10
    // main::@137
    // [329] main::rom_flash_errors#0 = rom_flash::return#2 -- vdum1=vdum2 
    lda rom_flash.return
    sta rom_flash_errors
    lda rom_flash.return+1
    sta rom_flash_errors+1
    lda rom_flash.return+2
    sta rom_flash_errors+2
    lda rom_flash.return+3
    sta rom_flash_errors+3
    // if(rom_flash_errors)
    // [330] if(0!=main::rom_flash_errors#0) goto main::@41 -- 0_neq_vdum1_then_la1 
    lda rom_flash_errors
    ora rom_flash_errors+1
    ora rom_flash_errors+2
    ora rom_flash_errors+3
    bne __b41
    // main::@44
    // info_rom(rom_chip, STATUS_FLASHED, "OK!")
    // [331] info_rom::rom_chip#16 = main::rom_chip4#10 -- vbuz1=vbum2 
    lda rom_chip4
    sta.z info_rom.rom_chip
    // [332] call info_rom
    // [1157] phi from main::@44 to info_rom [phi:main::@44->info_rom]
    // [1157] phi info_rom::info_text#17 = main::info_text10 [phi:main::@44->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text10
    sta.z info_rom.info_text
    lda #>info_text10
    sta.z info_rom.info_text+1
    // [1157] phi info_rom::rom_chip#17 = info_rom::rom_chip#16 [phi:main::@44->info_rom#1] -- register_copy 
    // [1157] phi info_rom::info_status#17 = STATUS_FLASHED [phi:main::@44->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHED
    sta.z info_rom.info_status
    jsr info_rom
    // [333] phi from main::@129 main::@140 main::@40 main::@44 main::@62 to main::@39 [phi:main::@129/main::@140/main::@40/main::@44/main::@62->main::@39]
    // [333] phi __errno#295 = __errno#175 [phi:main::@129/main::@140/main::@40/main::@44/main::@62->main::@39#0] -- register_copy 
    // main::@39
  __b39:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [334] main::rom_chip4#1 = ++ main::rom_chip4#10 -- vbum1=_inc_vbum1 
    inc rom_chip4
    // [198] phi from main::@39 to main::@38 [phi:main::@39->main::@38]
    // [198] phi __errno#112 = __errno#295 [phi:main::@39->main::@38#0] -- register_copy 
    // [198] phi main::rom_chip4#10 = main::rom_chip4#1 [phi:main::@39->main::@38#1] -- register_copy 
    jmp __b38
    // [335] phi from main::@137 to main::@41 [phi:main::@137->main::@41]
    // main::@41
  __b41:
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [336] call snprintf_init
    jsr snprintf_init
    // main::@138
    // [337] printf_ulong::uvalue#10 = main::rom_flash_errors#0 -- vduz1=vdum2 
    lda rom_flash_errors
    sta.z printf_ulong.uvalue
    lda rom_flash_errors+1
    sta.z printf_ulong.uvalue+1
    lda rom_flash_errors+2
    sta.z printf_ulong.uvalue+2
    lda rom_flash_errors+3
    sta.z printf_ulong.uvalue+3
    // [338] call printf_ulong
    // [1255] phi from main::@138 to printf_ulong [phi:main::@138->printf_ulong]
    // [1255] phi printf_ulong::format_zero_padding#11 = 0 [phi:main::@138->printf_ulong#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_ulong.format_zero_padding
    // [1255] phi printf_ulong::format_min_length#11 = 0 [phi:main::@138->printf_ulong#1] -- vbuz1=vbuc1 
    sta.z printf_ulong.format_min_length
    // [1255] phi printf_ulong::putc#11 = &snputc [phi:main::@138->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1255] phi printf_ulong::format_radix#11 = DECIMAL [phi:main::@138->printf_ulong#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_ulong.format_radix
    // [1255] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#10 [phi:main::@138->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [339] phi from main::@138 to main::@139 [phi:main::@138->main::@139]
    // main::@139
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [340] call printf_str
    // [630] phi from main::@139 to printf_str [phi:main::@139->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:main::@139->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = main::s13 [phi:main::@139->printf_str#1] -- pbuz1=pbuc1 
    lda #<s13
    sta.z printf_str.s
    lda #>s13
    sta.z printf_str.s+1
    jsr printf_str
    // main::@140
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [341] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [342] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom(rom_chip, STATUS_ERROR, info_text)
    // [344] info_rom::rom_chip#15 = main::rom_chip4#10 -- vbuz1=vbum2 
    lda rom_chip4
    sta.z info_rom.rom_chip
    // [345] call info_rom
    // [1157] phi from main::@140 to info_rom [phi:main::@140->info_rom]
    // [1157] phi info_rom::info_text#17 = info_text [phi:main::@140->info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_rom.info_text
    lda #>@info_text
    sta.z info_rom.info_text+1
    // [1157] phi info_rom::rom_chip#17 = info_rom::rom_chip#15 [phi:main::@140->info_rom#1] -- register_copy 
    // [1157] phi info_rom::info_status#17 = STATUS_ERROR [phi:main::@140->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z info_rom.info_status
    jsr info_rom
    jmp __b39
    // main::@40
  __b40:
    // info_rom(rom_chip, STATUS_FLASHED, "No update required")
    // [346] info_rom::rom_chip#13 = main::rom_chip4#10 -- vbuz1=vbum2 
    lda rom_chip4
    sta.z info_rom.rom_chip
    // [347] call info_rom
    // [1157] phi from main::@40 to info_rom [phi:main::@40->info_rom]
    // [1157] phi info_rom::info_text#17 = main::info_text27 [phi:main::@40->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text27
    sta.z info_rom.info_text
    lda #>info_text27
    sta.z info_rom.info_text+1
    // [1157] phi info_rom::rom_chip#17 = info_rom::rom_chip#13 [phi:main::@40->info_rom#1] -- register_copy 
    // [1157] phi info_rom::info_status#17 = STATUS_FLASHED [phi:main::@40->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHED
    sta.z info_rom.info_status
    jsr info_rom
    jmp __b39
    // main::@33
  __b33:
    // info_rom(rom_chip, STATUS_SKIP, "No flash")
    // [348] info_rom::rom_chip#10 = main::rom_chip2#2 -- vbuz1=vbum2 
    lda rom_chip2
    sta.z info_rom.rom_chip
    // [349] call info_rom
    // [1157] phi from main::@33 to info_rom [phi:main::@33->info_rom]
    // [1157] phi info_rom::info_text#17 = main::info_text15 [phi:main::@33->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text15
    sta.z info_rom.info_text
    lda #>info_text15
    sta.z info_rom.info_text+1
    // [1157] phi info_rom::rom_chip#17 = info_rom::rom_chip#10 [phi:main::@33->info_rom#1] -- register_copy 
    // [1157] phi info_rom::info_status#17 = STATUS_SKIP [phi:main::@33->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z info_rom.info_status
    jsr info_rom
    // main::@115
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [350] main::rom_chip2#1 = ++ main::rom_chip2#2 -- vbum1=_inc_vbum1 
    inc rom_chip2
    // [176] phi from main::@115 to main::@32 [phi:main::@115->main::@32]
    // [176] phi main::rom_chip2#2 = main::rom_chip2#1 [phi:main::@115->main::@32#0] -- register_copy 
    jmp __b32
    // [351] phi from main::@3 to main::@4 [phi:main::@3->main::@4]
    // main::@4
  __b4:
    // info_progress("Chipset has been detected and update files validated!")
    // [352] call info_progress
    // [596] phi from main::@4 to info_progress [phi:main::@4->info_progress]
    // [596] phi info_progress::info_text#12 = main::info_text11 [phi:main::@4->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text11
    sta.z info_progress.info_text
    lda #>info_text11
    sta.z info_progress.info_text+1
    jsr info_progress
    // [353] phi from main::@4 to main::@108 [phi:main::@4->main::@108]
    // main::@108
    // unsigned char ch = wait_key("Continue with flashing? [Y/N]", "nyNY")
    // [354] call wait_key
    // [818] phi from main::@108 to wait_key [phi:main::@108->wait_key]
    // [818] phi wait_key::filter#14 = main::filter [phi:main::@108->wait_key#0] -- pbuz1=pbuc1 
    lda #<filter
    sta.z wait_key.filter
    lda #>filter
    sta.z wait_key.filter+1
    // [818] phi wait_key::info_text#4 = main::info_text12 [phi:main::@108->wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text12
    sta.z wait_key.info_text
    lda #>info_text12
    sta.z wait_key.info_text+1
    jsr wait_key
    // unsigned char ch = wait_key("Continue with flashing? [Y/N]", "nyNY")
    // [355] wait_key::return#2 = wait_key::ch#4 -- vbum1=vwum2 
    lda wait_key.ch
    sta wait_key.return
    // main::@109
    // [356] main::ch#0 = wait_key::return#2
    // strchr("nN", ch)
    // [357] strchr::c#1 = main::ch#0
    // [358] call strchr
    // [1381] phi from main::@109 to strchr [phi:main::@109->strchr]
    // [1381] phi strchr::c#4 = strchr::c#1 [phi:main::@109->strchr#0] -- register_copy 
    // [1381] phi strchr::str#2 = (const void *)main::$164 [phi:main::@109->strchr#1] -- pvoz1=pvoc1 
    lda #<main__164
    sta.z strchr.str
    lda #>main__164
    sta.z strchr.str+1
    jsr strchr
    // strchr("nN", ch)
    // [359] strchr::return#4 = strchr::return#2
    // main::@110
    // [360] main::$91 = strchr::return#4
    // if(strchr("nN", ch))
    // [361] if((void *)0==main::$91) goto main::check_smc3 -- pvoc1_eq_pvoz1_then_la1 
    lda.z main__91
    cmp #<0
    bne !+
    lda.z main__91+1
    cmp #>0
    bne !check_smc3+
    jmp check_smc3
  !check_smc3:
  !:
    // main::@10
    // [362] smc_file_size#283 = smc_file_size#176 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // info_smc(STATUS_SKIP, "Cancelled")
    // [363] call info_smc
    // [650] phi from main::@10 to info_smc [phi:main::@10->info_smc]
    // [650] phi info_smc::info_text#11 = main::info_text17 [phi:main::@10->info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text17
    sta.z info_smc.info_text
    lda #>info_text17
    sta.z info_smc.info_text+1
    // [650] phi smc_file_size#12 = smc_file_size#283 [phi:main::@10->info_smc#1] -- register_copy 
    // [650] phi info_smc::info_status#11 = STATUS_SKIP [phi:main::@10->info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta info_smc.info_status
    jsr info_smc
    // [364] phi from main::@10 to main::@116 [phi:main::@10->main::@116]
    // main::@116
    // info_vera(STATUS_SKIP, "Cancelled")
    // [365] call info_vera
    // [676] phi from main::@116 to info_vera [phi:main::@116->info_vera]
    // [676] phi info_vera::info_text#3 = main::info_text17 [phi:main::@116->info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text17
    sta.z info_vera.info_text
    lda #>info_text17
    sta.z info_vera.info_text+1
    // [676] phi info_vera::info_status#3 = STATUS_SKIP [phi:main::@116->info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z info_vera.info_status
    jsr info_vera
    // [366] phi from main::@116 to main::@35 [phi:main::@116->main::@35]
    // [366] phi main::rom_chip3#2 = 1 [phi:main::@116->main::@35#0] -- vbum1=vbuc1 
    lda #1
    sta rom_chip3
    // main::@35
  __b35:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [367] if(main::rom_chip3#2<8) goto main::@36 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip3
    cmp #8
    bcc __b36
    // [368] phi from main::@35 to main::@37 [phi:main::@35->main::@37]
    // main::@37
    // info_line("You have selected not to cancel the update ... ")
    // [369] call info_line
    // [845] phi from main::@37 to info_line [phi:main::@37->info_line]
    // [845] phi info_line::info_text#18 = main::info_text20 [phi:main::@37->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text20
    sta.z info_line.info_text
    lda #>info_text20
    sta.z info_line.info_text+1
    jsr info_line
    jmp check_smc3
    // main::@36
  __b36:
    // info_rom(rom_chip, STATUS_SKIP, "Cancelled")
    // [370] info_rom::rom_chip#11 = main::rom_chip3#2 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z info_rom.rom_chip
    // [371] call info_rom
    // [1157] phi from main::@36 to info_rom [phi:main::@36->info_rom]
    // [1157] phi info_rom::info_text#17 = main::info_text17 [phi:main::@36->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text17
    sta.z info_rom.info_text
    lda #>info_text17
    sta.z info_rom.info_text+1
    // [1157] phi info_rom::rom_chip#17 = info_rom::rom_chip#11 [phi:main::@36->info_rom#1] -- register_copy 
    // [1157] phi info_rom::info_status#17 = STATUS_SKIP [phi:main::@36->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z info_rom.info_status
    jsr info_rom
    // main::@117
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [372] main::rom_chip3#1 = ++ main::rom_chip3#2 -- vbum1=_inc_vbum1 
    inc rom_chip3
    // [366] phi from main::@117 to main::@35 [phi:main::@117->main::@35]
    // [366] phi main::rom_chip3#2 = main::rom_chip3#1 [phi:main::@117->main::@35#0] -- register_copy 
    jmp __b35
    // main::check_card_roms1_check_rom1
  check_card_roms1_check_rom1:
    // status_rom[rom_chip] == status
    // [373] main::check_card_roms1_check_rom1_$0 = status_rom[main::check_card_roms1_rom_chip#2] == STATUS_FLASH -- vbom1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_FLASH
    ldy check_card_roms1_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta check_card_roms1_check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [374] main::check_card_roms1_check_rom1_return#0 = (char)main::check_card_roms1_check_rom1_$0
    // main::check_card_roms1_@11
    // if(check_rom(rom_chip, status))
    // [375] if(0==main::check_card_roms1_check_rom1_return#0) goto main::check_card_roms1_@4 -- 0_eq_vbum1_then_la1 
    lda check_card_roms1_check_rom1_return
    beq check_card_roms1___b4
    // [161] phi from main::check_card_roms1_@11 to main::check_card_roms1_@return [phi:main::check_card_roms1_@11->main::check_card_roms1_@return]
    // [161] phi main::check_card_roms1_return#2 = STATUS_FLASH [phi:main::check_card_roms1_@11->main::check_card_roms1_@return#0] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta check_card_roms1_return
    jmp __b59
    // main::check_card_roms1_@4
  check_card_roms1___b4:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [376] main::check_card_roms1_rom_chip#1 = ++ main::check_card_roms1_rom_chip#2 -- vbum1=_inc_vbum1 
    inc check_card_roms1_rom_chip
    // [159] phi from main::check_card_roms1_@4 to main::check_card_roms1_@1 [phi:main::check_card_roms1_@4->main::check_card_roms1_@1]
    // [159] phi main::check_card_roms1_rom_chip#2 = main::check_card_roms1_rom_chip#1 [phi:main::check_card_roms1_@4->main::check_card_roms1_@1#0] -- register_copy 
    jmp check_card_roms1___b1
    // main::bank_set_brom2
  bank_set_brom2:
    // BROM = bank
    // [377] BROM = main::bank_set_brom2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom2_bank
    sta.z BROM
    // main::@57
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [378] if(rom_device_ids[main::rom_chip1#10]==$55) goto main::@25 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    ldy rom_chip1
    lda rom_device_ids,y
    cmp #$55
    bne !__b25+
    jmp __b25
  !__b25:
    // main::@28
    // info_rom(rom_chip, STATUS_CHECKING, "")
    // [379] info_rom::rom_chip#6 = main::rom_chip1#10 -- vbuz1=vbum2 
    tya
    sta.z info_rom.rom_chip
    // [380] call info_rom
    // [1157] phi from main::@28 to info_rom [phi:main::@28->info_rom]
    // [1157] phi info_rom::info_text#17 = info_text5 [phi:main::@28->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z info_rom.info_text
    lda #>info_text5
    sta.z info_rom.info_text+1
    // [1157] phi info_rom::rom_chip#17 = info_rom::rom_chip#6 [phi:main::@28->info_rom#1] -- register_copy 
    // [1157] phi info_rom::info_status#17 = STATUS_CHECKING [phi:main::@28->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_CHECKING
    sta.z info_rom.info_status
    jsr info_rom
    // [381] phi from main::@28 to main::@90 [phi:main::@28->main::@90]
    // main::@90
    // progress_clear()
    // [382] call progress_clear
  // Set the info for the ROMs to Checking.
    // [571] phi from main::@90 to progress_clear [phi:main::@90->progress_clear]
    jsr progress_clear
    // main::@91
    // unsigned char rom_bank = rom_chip * 32
    // [383] main::rom_bank#0 = main::rom_chip1#10 << 5 -- vbum1=vbum2_rol_5 
    lda rom_chip1
    asl
    asl
    asl
    asl
    asl
    sta rom_bank
    // unsigned char* file = rom_file(rom_chip)
    // [384] rom_file::rom_chip#0 = main::rom_chip1#10 -- vbum1=vbum2 
    lda rom_chip1
    sta rom_file.rom_chip
    // [385] call rom_file
    // [1039] phi from main::@91 to rom_file [phi:main::@91->rom_file]
    // [1039] phi rom_file::rom_chip#2 = rom_file::rom_chip#0 [phi:main::@91->rom_file#0] -- register_copy 
    jsr rom_file
    // [386] phi from main::@91 to main::@92 [phi:main::@91->main::@92]
    // main::@92
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [387] call snprintf_init
    jsr snprintf_init
    // [388] phi from main::@92 to main::@93 [phi:main::@92->main::@93]
    // main::@93
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [389] call printf_str
    // [630] phi from main::@93 to printf_str [phi:main::@93->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:main::@93->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = main::s4 [phi:main::@93->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // [390] phi from main::@93 to main::@94 [phi:main::@93->main::@94]
    // main::@94
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [391] call printf_string
    // [1044] phi from main::@94 to printf_string [phi:main::@94->printf_string]
    // [1044] phi printf_string::putc#16 = &snputc [phi:main::@94->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1044] phi printf_string::str#16 = rom_file::file [phi:main::@94->printf_string#1] -- pbuz1=pbuc1 
    lda #<rom_file.file
    sta.z printf_string.str
    lda #>rom_file.file
    sta.z printf_string.str+1
    // [1044] phi printf_string::format_justify_left#16 = 0 [phi:main::@94->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1044] phi printf_string::format_min_length#16 = 0 [phi:main::@94->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [392] phi from main::@94 to main::@95 [phi:main::@94->main::@95]
    // main::@95
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [393] call printf_str
    // [630] phi from main::@95 to printf_str [phi:main::@95->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:main::@95->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = main::s5 [phi:main::@95->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // main::@96
    // sprintf(info_text, "Checking %s ... (.) data ( ) empty", file)
    // [394] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [395] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_progress(info_text)
    // [397] call info_progress
    // [596] phi from main::@96 to info_progress [phi:main::@96->info_progress]
    // [596] phi info_progress::info_text#12 = info_text [phi:main::@96->info_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_progress.info_text
    lda #>@info_text
    sta.z info_progress.info_text+1
    jsr info_progress
    // main::@97
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, rom_bank, rom_sizes[rom_chip])
    // [398] main::$146 = main::rom_chip1#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip1
    asl
    asl
    sta main__146
    // [399] rom_read::brom_bank_start#1 = main::rom_bank#0 -- vbuz1=vbum2 
    lda rom_bank
    sta.z rom_read.brom_bank_start
    // [400] rom_read::rom_size#0 = rom_sizes[main::$146] -- vduz1=pduc1_derefidx_vbum2 
    ldy main__146
    lda rom_sizes,y
    sta.z rom_read.rom_size
    lda rom_sizes+1,y
    sta.z rom_read.rom_size+1
    lda rom_sizes+2,y
    sta.z rom_read.rom_size+2
    lda rom_sizes+3,y
    sta.z rom_read.rom_size+3
    // [401] call rom_read
    // [1069] phi from main::@97 to rom_read [phi:main::@97->rom_read]
    // [1069] phi rom_read::rom_size#12 = rom_read::rom_size#0 [phi:main::@97->rom_read#0] -- register_copy 
    // [1069] phi __errno#104 = __errno#110 [phi:main::@97->rom_read#1] -- register_copy 
    // [1069] phi rom_read::brom_bank_start#21 = rom_read::brom_bank_start#1 [phi:main::@97->rom_read#2] -- register_copy 
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, rom_bank, rom_sizes[rom_chip])
    // [402] rom_read::return#2 = rom_read::return#0
    // main::@98
    // [403] main::rom_bytes_read#0 = rom_read::return#2 -- vdum1=vdum2 
    lda rom_read.return
    sta rom_bytes_read
    lda rom_read.return+1
    sta rom_bytes_read+1
    lda rom_read.return+2
    sta rom_bytes_read+2
    lda rom_read.return+3
    sta rom_bytes_read+3
    // if (!rom_bytes_read)
    // [404] if(0==main::rom_bytes_read#0) goto main::@26 -- 0_eq_vdum1_then_la1 
    // In case no file was found, set the status to none and skip to the next, else, mention the amount of bytes read.
    lda rom_bytes_read
    ora rom_bytes_read+1
    ora rom_bytes_read+2
    ora rom_bytes_read+3
    bne !__b26+
    jmp __b26
  !__b26:
    // main::@29
    // unsigned long rom_file_modulo = rom_bytes_read % 0x4000
    // [405] main::rom_file_modulo#0 = main::rom_bytes_read#0 & $4000-1 -- vdum1=vdum2_band_vduc1 
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
    // [406] if(0!=main::rom_file_modulo#0) goto main::@27 -- 0_neq_vdum1_then_la1 
    lda rom_file_modulo
    ora rom_file_modulo+1
    ora rom_file_modulo+2
    ora rom_file_modulo+3
    bne __b27
    // main::@30
    // info_rom(rom_chip, STATUS_FLASH, "OK!")
    // [407] info_rom::rom_chip#9 = main::rom_chip1#10 -- vbuz1=vbum2 
    lda rom_chip1
    sta.z info_rom.rom_chip
    // [408] call info_rom
    // [1157] phi from main::@30 to info_rom [phi:main::@30->info_rom]
    // [1157] phi info_rom::info_text#17 = main::info_text10 [phi:main::@30->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text10
    sta.z info_rom.info_text
    lda #>info_text10
    sta.z info_rom.info_text+1
    // [1157] phi info_rom::rom_chip#17 = info_rom::rom_chip#9 [phi:main::@30->info_rom#1] -- register_copy 
    // [1157] phi info_rom::info_status#17 = STATUS_FLASH [phi:main::@30->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASH
    sta.z info_rom.info_status
    jsr info_rom
    // main::@107
    // file_sizes[rom_chip] = rom_bytes_read
    // [409] file_sizes[main::$146] = main::rom_bytes_read#0 -- pduc1_derefidx_vbum1=vdum2 
    ldy main__146
    lda rom_bytes_read
    sta file_sizes,y
    lda rom_bytes_read+1
    sta file_sizes+1,y
    lda rom_bytes_read+2
    sta file_sizes+2,y
    lda rom_bytes_read+3
    sta file_sizes+3,y
    // [410] phi from main::@102 main::@106 main::@107 main::@57 to main::@25 [phi:main::@102/main::@106/main::@107/main::@57->main::@25]
    // [410] phi __errno#247 = __errno#175 [phi:main::@102/main::@106/main::@107/main::@57->main::@25#0] -- register_copy 
    // main::@25
  __b25:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [411] main::rom_chip1#1 = ++ main::rom_chip1#10 -- vbum1=_inc_vbum1 
    inc rom_chip1
    // [145] phi from main::@25 to main::@24 [phi:main::@25->main::@24]
    // [145] phi __errno#110 = __errno#247 [phi:main::@25->main::@24#0] -- register_copy 
    // [145] phi main::rom_chip1#10 = main::rom_chip1#1 [phi:main::@25->main::@24#1] -- register_copy 
    jmp __b24
    // [412] phi from main::@29 to main::@27 [phi:main::@29->main::@27]
    // main::@27
  __b27:
    // sprintf(info_text, "File %s size error!", file)
    // [413] call snprintf_init
    jsr snprintf_init
    // [414] phi from main::@27 to main::@103 [phi:main::@27->main::@103]
    // main::@103
    // sprintf(info_text, "File %s size error!", file)
    // [415] call printf_str
    // [630] phi from main::@103 to printf_str [phi:main::@103->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:main::@103->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = main::s8 [phi:main::@103->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // [416] phi from main::@103 to main::@104 [phi:main::@103->main::@104]
    // main::@104
    // sprintf(info_text, "File %s size error!", file)
    // [417] call printf_string
    // [1044] phi from main::@104 to printf_string [phi:main::@104->printf_string]
    // [1044] phi printf_string::putc#16 = &snputc [phi:main::@104->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1044] phi printf_string::str#16 = rom_file::file [phi:main::@104->printf_string#1] -- pbuz1=pbuc1 
    lda #<rom_file.file
    sta.z printf_string.str
    lda #>rom_file.file
    sta.z printf_string.str+1
    // [1044] phi printf_string::format_justify_left#16 = 0 [phi:main::@104->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1044] phi printf_string::format_min_length#16 = 0 [phi:main::@104->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [418] phi from main::@104 to main::@105 [phi:main::@104->main::@105]
    // main::@105
    // sprintf(info_text, "File %s size error!", file)
    // [419] call printf_str
    // [630] phi from main::@105 to printf_str [phi:main::@105->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:main::@105->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = main::s9 [phi:main::@105->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // main::@106
    // sprintf(info_text, "File %s size error!", file)
    // [420] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [421] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom(rom_chip, STATUS_ERROR, info_text)
    // [423] info_rom::rom_chip#8 = main::rom_chip1#10 -- vbuz1=vbum2 
    lda rom_chip1
    sta.z info_rom.rom_chip
    // [424] call info_rom
    // [1157] phi from main::@106 to info_rom [phi:main::@106->info_rom]
    // [1157] phi info_rom::info_text#17 = info_text [phi:main::@106->info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_rom.info_text
    lda #>@info_text
    sta.z info_rom.info_text+1
    // [1157] phi info_rom::rom_chip#17 = info_rom::rom_chip#8 [phi:main::@106->info_rom#1] -- register_copy 
    // [1157] phi info_rom::info_status#17 = STATUS_ERROR [phi:main::@106->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z info_rom.info_status
    jsr info_rom
    jmp __b25
    // [425] phi from main::@98 to main::@26 [phi:main::@98->main::@26]
    // main::@26
  __b26:
    // sprintf(info_text, "No %s, skipped", file)
    // [426] call snprintf_init
    jsr snprintf_init
    // [427] phi from main::@26 to main::@99 [phi:main::@26->main::@99]
    // main::@99
    // sprintf(info_text, "No %s, skipped", file)
    // [428] call printf_str
    // [630] phi from main::@99 to printf_str [phi:main::@99->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:main::@99->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = main::s6 [phi:main::@99->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // [429] phi from main::@99 to main::@100 [phi:main::@99->main::@100]
    // main::@100
    // sprintf(info_text, "No %s, skipped", file)
    // [430] call printf_string
    // [1044] phi from main::@100 to printf_string [phi:main::@100->printf_string]
    // [1044] phi printf_string::putc#16 = &snputc [phi:main::@100->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1044] phi printf_string::str#16 = rom_file::file [phi:main::@100->printf_string#1] -- pbuz1=pbuc1 
    lda #<rom_file.file
    sta.z printf_string.str
    lda #>rom_file.file
    sta.z printf_string.str+1
    // [1044] phi printf_string::format_justify_left#16 = 0 [phi:main::@100->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1044] phi printf_string::format_min_length#16 = 0 [phi:main::@100->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [431] phi from main::@100 to main::@101 [phi:main::@100->main::@101]
    // main::@101
    // sprintf(info_text, "No %s, skipped", file)
    // [432] call printf_str
    // [630] phi from main::@101 to printf_str [phi:main::@101->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:main::@101->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = main::s7 [phi:main::@101->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@102
    // sprintf(info_text, "No %s, skipped", file)
    // [433] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [434] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom(rom_chip, STATUS_NONE, info_text)
    // [436] info_rom::rom_chip#7 = main::rom_chip1#10 -- vbuz1=vbum2 
    lda rom_chip1
    sta.z info_rom.rom_chip
    // [437] call info_rom
    // [1157] phi from main::@102 to info_rom [phi:main::@102->info_rom]
    // [1157] phi info_rom::info_text#17 = info_text [phi:main::@102->info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_rom.info_text
    lda #>@info_text
    sta.z info_rom.info_text+1
    // [1157] phi info_rom::rom_chip#17 = info_rom::rom_chip#7 [phi:main::@102->info_rom#1] -- register_copy 
    // [1157] phi info_rom::info_status#17 = STATUS_NONE [phi:main::@102->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_NONE
    sta.z info_rom.info_status
    jsr info_rom
    jmp __b25
    // main::@23
  __b23:
    // [438] smc_file_size#288 = smc_file_size#0 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // info_smc(STATUS_ERROR, "SMC.BIN too large!")
    // [439] call info_smc
    // [650] phi from main::@23 to info_smc [phi:main::@23->info_smc]
    // [650] phi info_smc::info_text#11 = main::info_text8 [phi:main::@23->info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z info_smc.info_text
    lda #>info_text8
    sta.z info_smc.info_text+1
    // [650] phi smc_file_size#12 = smc_file_size#288 [phi:main::@23->info_smc#1] -- register_copy 
    // [650] phi info_smc::info_status#11 = STATUS_ERROR [phi:main::@23->info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta info_smc.info_status
    jsr info_smc
    jmp CLI3
    // main::@22
  __b22:
    // [440] smc_file_size#287 = smc_file_size#0 -- vwum1=vwum2 
    lda smc_file_size
    sta smc_file_size_2
    lda smc_file_size+1
    sta smc_file_size_2+1
    // info_smc(STATUS_ERROR, "No SMC.BIN!")
    // [441] call info_smc
    // [650] phi from main::@22 to info_smc [phi:main::@22->info_smc]
    // [650] phi info_smc::info_text#11 = main::info_text7 [phi:main::@22->info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z info_smc.info_text
    lda #>info_text7
    sta.z info_smc.info_text+1
    // [650] phi smc_file_size#12 = smc_file_size#287 [phi:main::@22->info_smc#1] -- register_copy 
    // [650] phi info_smc::info_status#11 = STATUS_ERROR [phi:main::@22->info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta info_smc.info_status
    jsr info_smc
    jmp CLI3
    // main::@15
  __b15:
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [442] if(rom_device_ids[main::rom_chip#2]!=$55) goto main::@16 -- pbuc1_derefidx_vbum1_neq_vbuc2_then_la1 
    lda #$55
    ldy rom_chip
    cmp rom_device_ids,y
    bne __b16
    // main::@18
    // info_rom(rom_chip, STATUS_NONE, "")
    // [443] info_rom::rom_chip#5 = main::rom_chip#2 -- vbuz1=vbum2 
    tya
    sta.z info_rom.rom_chip
    // [444] call info_rom
    // [1157] phi from main::@18 to info_rom [phi:main::@18->info_rom]
    // [1157] phi info_rom::info_text#17 = info_text5 [phi:main::@18->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z info_rom.info_text
    lda #>info_text5
    sta.z info_rom.info_text+1
    // [1157] phi info_rom::rom_chip#17 = info_rom::rom_chip#5 [phi:main::@18->info_rom#1] -- register_copy 
    // [1157] phi info_rom::info_status#17 = STATUS_NONE [phi:main::@18->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_NONE
    sta.z info_rom.info_status
    jsr info_rom
    // main::@17
  __b17:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [445] main::rom_chip#1 = ++ main::rom_chip#2 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [118] phi from main::@17 to main::@14 [phi:main::@17->main::@14]
    // [118] phi main::rom_chip#2 = main::rom_chip#1 [phi:main::@17->main::@14#0] -- register_copy 
    jmp __b14
    // main::@16
  __b16:
    // info_rom(rom_chip, STATUS_DETECTED, "")
    // [446] info_rom::rom_chip#4 = main::rom_chip#2 -- vbuz1=vbum2 
    lda rom_chip
    sta.z info_rom.rom_chip
    // [447] call info_rom
    // [1157] phi from main::@16 to info_rom [phi:main::@16->info_rom]
    // [1157] phi info_rom::info_text#17 = info_text5 [phi:main::@16->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z info_rom.info_text
    lda #>info_text5
    sta.z info_rom.info_text+1
    // [1157] phi info_rom::rom_chip#17 = info_rom::rom_chip#4 [phi:main::@16->info_rom#1] -- register_copy 
    // [1157] phi info_rom::info_status#17 = STATUS_DETECTED [phi:main::@16->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_DETECTED
    sta.z info_rom.info_status
    jsr info_rom
    jmp __b17
    // [448] phi from main::@7 to main::@13 [phi:main::@7->main::@13]
    // main::@13
  __b13:
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [449] call snprintf_init
    jsr snprintf_init
    // [450] phi from main::@13 to main::@77 [phi:main::@13->main::@77]
    // main::@77
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [451] call printf_str
    // [630] phi from main::@77 to printf_str [phi:main::@77->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:main::@77->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = main::s [phi:main::@77->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // main::@78
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [452] printf_uint::uvalue#13 = smc_bootloader#0 -- vwuz1=vwum2 
    lda smc_bootloader
    sta.z printf_uint.uvalue
    lda smc_bootloader+1
    sta.z printf_uint.uvalue+1
    // [453] call printf_uint
    // [639] phi from main::@78 to printf_uint [phi:main::@78->printf_uint]
    // [639] phi printf_uint::format_zero_padding#16 = 1 [phi:main::@78->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [639] phi printf_uint::format_min_length#16 = 2 [phi:main::@78->printf_uint#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uint.format_min_length
    // [639] phi printf_uint::putc#16 = &snputc [phi:main::@78->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [639] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:main::@78->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [639] phi printf_uint::uvalue#16 = printf_uint::uvalue#13 [phi:main::@78->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [454] phi from main::@78 to main::@79 [phi:main::@78->main::@79]
    // main::@79
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [455] call printf_str
    // [630] phi from main::@79 to printf_str [phi:main::@79->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:main::@79->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = main::s1 [phi:main::@79->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // main::@80
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [456] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [457] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_smc(STATUS_ERROR, info_text)
    // [459] call info_smc
    // [650] phi from main::@80 to info_smc [phi:main::@80->info_smc]
    // [650] phi info_smc::info_text#11 = info_text [phi:main::@80->info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_smc.info_text
    lda #>@info_text
    sta.z info_smc.info_text+1
    // [650] phi smc_file_size#12 = 0 [phi:main::@80->info_smc#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size_2
    sta smc_file_size_2+1
    // [650] phi info_smc::info_status#11 = STATUS_ERROR [phi:main::@80->info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta info_smc.info_status
    jsr info_smc
    jmp CLI1
    // [460] phi from main::@6 to main::@12 [phi:main::@6->main::@12]
    // main::@12
  __b12:
    // info_smc(STATUS_ERROR, "Unreachable!")
    // [461] call info_smc
  // TODO: explain next steps ...
    // [650] phi from main::@12 to info_smc [phi:main::@12->info_smc]
    // [650] phi info_smc::info_text#11 = main::info_text3 [phi:main::@12->info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text3
    sta.z info_smc.info_text
    lda #>info_text3
    sta.z info_smc.info_text+1
    // [650] phi smc_file_size#12 = 0 [phi:main::@12->info_smc#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size_2
    sta smc_file_size_2+1
    // [650] phi info_smc::info_status#11 = STATUS_ERROR [phi:main::@12->info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta info_smc.info_status
    jsr info_smc
    jmp CLI1
    // [462] phi from main::@76 to main::@1 [phi:main::@76->main::@1]
    // main::@1
  __b1:
    // info_smc(STATUS_ERROR, "No Bootloader!")
    // [463] call info_smc
  // TODO: explain next steps ...
    // [650] phi from main::@1 to info_smc [phi:main::@1->info_smc]
    // [650] phi info_smc::info_text#11 = main::info_text2 [phi:main::@1->info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z info_smc.info_text
    lda #>info_text2
    sta.z info_smc.info_text+1
    // [650] phi smc_file_size#12 = 0 [phi:main::@1->info_smc#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_file_size_2
    sta smc_file_size_2+1
    // [650] phi info_smc::info_status#11 = STATUS_ERROR [phi:main::@1->info_smc#2] -- vbum1=vbuc1 
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
    info_text11: .text "Chipset has been detected and update files validated!"
    .byte 0
    info_text12: .text "Continue with flashing? [Y/N]"
    .byte 0
    filter: .text "nyNY"
    .byte 0
    main__164: .text "nN"
    .byte 0
    info_text13: .text "The SMC and the CX16 main ROM must be flashed together!"
    .byte 0
    info_text14: .text "Press [SPACE] to continue [ ]"
    .byte 0
    filter1: .text " "
    .byte 0
    info_text15: .text "No flash"
    .byte 0
    info_text16: .text "No chipset will be flashed and there is an issue ... "
    .byte 0
    info_text17: .text "Cancelled"
    .byte 0
    info_text20: .text "You have selected not to cancel the update ... "
    .byte 0
    info_text21: .text "Press both POWER/RESET buttons on the CX16 board!"
    .byte 0
    info_text22: .text "Press POWER/RESET!"
    .byte 0
    info_text24: .text "Update finished ..."
    .byte 0
    info_text25: .text "Comparing ... (.) same, (*) different."
    .byte 0
    info_text27: .text "No update required"
    .byte 0
    s12: .text " differences!"
    .byte 0
    s13: .text " flash errors!"
    .byte 0
    info_text29: .text "Upgrade Failure! Your CX16 may be bricked!"
    .byte 0
    info_text30: .text "Take a foto of this screen. And shut down power ..."
    .byte 0
    info_text31: .text "Upgrade Issues ..."
    .byte 0
    info_text32: .text "Take a foto of this screen. Press a key for next steps ..."
    .byte 0
    info_text33: .text "Upgrade Success!"
    .byte 0
    info_text34: .text "Press any key to reset your CX16 ..."
    .byte 0
    s14: .text "Resetting your CX16 ... ("
    .byte 0
    s15: .text ")"
    .byte 0
    main__146: .byte 0
    main__148: .byte 0
    cx16_k_screen_set_charset1_charset: .byte 0
    cx16_k_screen_set_charset1_offset: .word 0
    check_card_roms1_check_rom1_main__0: .byte 0
    check_smc3_main__0: .byte 0
    check_rom1_main__0: .byte 0
    check_smc4_main__0: .byte 0
    check_roms1_check_rom1_main__0: .byte 0
    check_vera2_main__0: .byte 0
    rom_chip: .byte 0
    rom_chip1: .byte 0
    rom_bank: .byte 0
    rom_bytes_read: .dword 0
    rom_file_modulo: .dword 0
    .label check_card_roms1_check_rom1_return = check_card_roms1_check_rom1_main__0
    check_card_roms1_rom_chip: .byte 0
    check_card_roms1_return: .byte 0
    .label ch = strchr.c
    rom_chip2: .byte 0
    .label check_smc3_return = check_smc3_main__0
    rom_chip3: .byte 0
    .label check_rom1_return = check_rom1_main__0
    .label check_smc4_return = check_smc4_main__0
    .label check_roms1_check_rom1_return = check_roms1_check_rom1_main__0
    check_roms1_rom_chip: .byte 0
    check_roms1_return: .byte 0
    rom_chip4: .byte 0
    rom_bank1: .byte 0
    .label rom_bytes_read1 = rom_read.return
    rom_flash_errors: .dword 0
    .label check_vera2_return = check_vera2_main__0
    check_roms2_rom_chip: .byte 0
    check_roms2_return: .byte 0
    reset_wait: .word 0
    flash_reset: .byte 0
    // We validate the need for flashing by evaluating multiple state combinations.
    flash: .word 0
}
.segment Code
  // screenlayer1
// Set the layer with which the conio will interact.
screenlayer1: {
    // screenlayer(1, *VERA_L1_MAPBASE, *VERA_L1_CONFIG)
    // [464] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbuz1=_deref_pbuc1 
    lda VERA_L1_MAPBASE
    sta.z screenlayer.mapbase
    // [465] screenlayer::config#0 = *VERA_L1_CONFIG -- vbuz1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta.z screenlayer.config
    // [466] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [467] return 
    rts
}
  // textcolor
// Set the front color for text output. The old front text color setting is returned.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char textcolor(__zp($d6) char color)
textcolor: {
    .label textcolor__0 = $d8
    .label textcolor__1 = $d6
    .label color = $d6
    // __conio.color & 0xF0
    // [469] textcolor::$0 = *((char *)&__conio+$d) & $f0 -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$d
    sta.z textcolor__0
    // __conio.color & 0xF0 | color
    // [470] textcolor::$1 = textcolor::$0 | textcolor::color#16 -- vbuz1=vbuz2_bor_vbuz1 
    lda.z textcolor__1
    ora.z textcolor__0
    sta.z textcolor__1
    // __conio.color = __conio.color & 0xF0 | color
    // [471] *((char *)&__conio+$d) = textcolor::$1 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // textcolor::@return
    // }
    // [472] return 
    rts
}
  // bgcolor
// Set the back color for text output.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char bgcolor(__zp($d6) char color)
bgcolor: {
    .label bgcolor__0 = $d7
    .label bgcolor__1 = $d6
    .label bgcolor__2 = $d7
    .label color = $d6
    // __conio.color & 0x0F
    // [474] bgcolor::$0 = *((char *)&__conio+$d) & $f -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$d
    sta.z bgcolor__0
    // color << 4
    // [475] bgcolor::$1 = bgcolor::color#14 << 4 -- vbuz1=vbuz1_rol_4 
    lda.z bgcolor__1
    asl
    asl
    asl
    asl
    sta.z bgcolor__1
    // __conio.color & 0x0F | color << 4
    // [476] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbuz1=vbuz1_bor_vbuz2 
    lda.z bgcolor__2
    ora.z bgcolor__1
    sta.z bgcolor__2
    // __conio.color = __conio.color & 0x0F | color << 4
    // [477] *((char *)&__conio+$d) = bgcolor::$2 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // bgcolor::@return
    // }
    // [478] return 
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
    // [479] *((char *)&__conio+$c) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$c
    // cursor::@return
    // }
    // [480] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    // __mem unsigned char x
    // [481] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [482] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [484] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwum1=vbum2_word_vbum3 
    lda x
    sta return+1
    lda y
    sta return
    // cbm_k_plot_get::@return
    // }
    // [485] return 
    rts
  .segment Data
    x: .byte 0
    y: .byte 0
    return: .word 0
}
.segment Code
  // gotoxy
// Set the cursor to the specified position
// void gotoxy(__zp($48) char x, __zp($50) char y)
gotoxy: {
    .label gotoxy__2 = $48
    .label gotoxy__3 = $48
    .label gotoxy__6 = $47
    .label gotoxy__7 = $47
    .label gotoxy__8 = $5b
    .label gotoxy__9 = $52
    .label gotoxy__10 = $50
    .label x = $48
    .label y = $50
    .label gotoxy__14 = $47
    // (x>=__conio.width)?__conio.width:x
    // [487] if(gotoxy::x#29>=*((char *)&__conio+6)) goto gotoxy::@1 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z x
    cmp __conio+6
    bcs __b1
    // [489] phi from gotoxy gotoxy::@1 to gotoxy::@2 [phi:gotoxy/gotoxy::@1->gotoxy::@2]
    // [489] phi gotoxy::$3 = gotoxy::x#29 [phi:gotoxy/gotoxy::@1->gotoxy::@2#0] -- register_copy 
    jmp __b2
    // gotoxy::@1
  __b1:
    // [488] gotoxy::$2 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z gotoxy__2
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [490] *((char *)&__conio) = gotoxy::$3 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__3
    sta __conio
    // (y>=__conio.height)?__conio.height:y
    // [491] if(gotoxy::y#29>=*((char *)&__conio+7)) goto gotoxy::@3 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z y
    cmp __conio+7
    bcs __b3
    // gotoxy::@4
    // [492] gotoxy::$14 = gotoxy::y#29 -- vbuz1=vbuz2 
    sta.z gotoxy__14
    // [493] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [493] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [494] *((char *)&__conio+1) = gotoxy::$7 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__7
    sta __conio+1
    // __conio.cursor_x << 1
    // [495] gotoxy::$8 = *((char *)&__conio) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio
    asl
    sta.z gotoxy__8
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [496] gotoxy::$10 = gotoxy::y#29 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z gotoxy__10
    // [497] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwuz1=pwuc1_derefidx_vbuz2_plus_vbuz3 
    ldy.z gotoxy__10
    clc
    adc __conio+$15,y
    sta.z gotoxy__9
    lda __conio+$15+1,y
    adc #0
    sta.z gotoxy__9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [498] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwuz1 
    lda.z gotoxy__9
    sta __conio+$13
    lda.z gotoxy__9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [499] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [500] gotoxy::$6 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
    lda __conio+7
    sta.z gotoxy__6
    jmp __b5
}
  // cputln
// Print a newline
cputln: {
    .label cputln__2 = $7f
    // __conio.cursor_x = 0
    // [501] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y++;
    // [502] *((char *)&__conio+1) = ++ *((char *)&__conio+1) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+1
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [503] cputln::$2 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z cputln__2
    // [504] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [505] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [506] return 
    rts
}
  // frame_init
frame_init: {
    .const vera_display_set_hstart1_start = $b
    .const vera_display_set_hstop1_stop = $93
    .const vera_display_set_vstart1_start = $13
    .const vera_display_set_vstop1_stop = $db
    // textcolor(WHITE)
    // [508] call textcolor
  // Set the charset to lower case.
  // screenlayer1();
    // [468] phi from frame_init to textcolor [phi:frame_init->textcolor]
    // [468] phi textcolor::color#16 = WHITE [phi:frame_init->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [509] phi from frame_init to frame_init::@2 [phi:frame_init->frame_init::@2]
    // frame_init::@2
    // bgcolor(BLUE)
    // [510] call bgcolor
    // [473] phi from frame_init::@2 to bgcolor [phi:frame_init::@2->bgcolor]
    // [473] phi bgcolor::color#14 = BLUE [phi:frame_init::@2->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [511] phi from frame_init::@2 to frame_init::@3 [phi:frame_init::@2->frame_init::@3]
    // frame_init::@3
    // scroll(0)
    // [512] call scroll
    jsr scroll
    // [513] phi from frame_init::@3 to frame_init::@4 [phi:frame_init::@3->frame_init::@4]
    // frame_init::@4
    // clrscr()
    // [514] call clrscr
    jsr clrscr
    // frame_init::vera_display_set_hstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [515] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTART = start
    // [516] *VERA_DC_HSTART = frame_init::vera_display_set_hstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstart1_start
    sta VERA_DC_HSTART
    // frame_init::vera_display_set_hstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [517] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTOP = stop
    // [518] *VERA_DC_HSTOP = frame_init::vera_display_set_hstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstop1_stop
    sta VERA_DC_HSTOP
    // frame_init::vera_display_set_vstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [519] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTART = start
    // [520] *VERA_DC_VSTART = frame_init::vera_display_set_vstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstart1_start
    sta VERA_DC_VSTART
    // frame_init::vera_display_set_vstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [521] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTOP = stop
    // [522] *VERA_DC_VSTOP = frame_init::vera_display_set_vstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstop1_stop
    sta VERA_DC_VSTOP
    // frame_init::@1
    // cx16_k_screen_set_charset(3, (char *)0)
    // [523] frame_init::cx16_k_screen_set_charset1_charset = 3 -- vbum1=vbuc1 
    lda #3
    sta cx16_k_screen_set_charset1_charset
    // [524] frame_init::cx16_k_screen_set_charset1_offset = (char *) 0 -- pbum1=pbuc1 
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
    // [526] return 
    rts
  .segment Data
    cx16_k_screen_set_charset1_charset: .byte 0
    cx16_k_screen_set_charset1_offset: .word 0
}
.segment Code
  // frame_draw
frame_draw: {
    // textcolor(WHITE)
    // [528] call textcolor
    // [468] phi from frame_draw to textcolor [phi:frame_draw->textcolor]
    // [468] phi textcolor::color#16 = WHITE [phi:frame_draw->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [529] phi from frame_draw to frame_draw::@1 [phi:frame_draw->frame_draw::@1]
    // frame_draw::@1
    // bgcolor(BLUE)
    // [530] call bgcolor
    // [473] phi from frame_draw::@1 to bgcolor [phi:frame_draw::@1->bgcolor]
    // [473] phi bgcolor::color#14 = BLUE [phi:frame_draw::@1->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [531] phi from frame_draw::@1 to frame_draw::@2 [phi:frame_draw::@1->frame_draw::@2]
    // frame_draw::@2
    // clrscr()
    // [532] call clrscr
    jsr clrscr
    // [533] phi from frame_draw::@2 to frame_draw::@3 [phi:frame_draw::@2->frame_draw::@3]
    // frame_draw::@3
    // frame(0, 0, 67, 13)
    // [534] call frame
    // [1461] phi from frame_draw::@3 to frame [phi:frame_draw::@3->frame]
    // [1461] phi frame::y#0 = 0 [phi:frame_draw::@3->frame#0] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.y
    // [1461] phi frame::y1#16 = $d [phi:frame_draw::@3->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1461] phi frame::x#0 = 0 [phi:frame_draw::@3->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1461] phi frame::x1#16 = $43 [phi:frame_draw::@3->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [535] phi from frame_draw::@3 to frame_draw::@4 [phi:frame_draw::@3->frame_draw::@4]
    // frame_draw::@4
    // frame(0, 0, 67, 2)
    // [536] call frame
    // [1461] phi from frame_draw::@4 to frame [phi:frame_draw::@4->frame]
    // [1461] phi frame::y#0 = 0 [phi:frame_draw::@4->frame#0] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.y
    // [1461] phi frame::y1#16 = 2 [phi:frame_draw::@4->frame#1] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y1
    // [1461] phi frame::x#0 = 0 [phi:frame_draw::@4->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1461] phi frame::x1#16 = $43 [phi:frame_draw::@4->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [537] phi from frame_draw::@4 to frame_draw::@5 [phi:frame_draw::@4->frame_draw::@5]
    // frame_draw::@5
    // frame(0, 2, 67, 13)
    // [538] call frame
    // [1461] phi from frame_draw::@5 to frame [phi:frame_draw::@5->frame]
    // [1461] phi frame::y#0 = 2 [phi:frame_draw::@5->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1461] phi frame::y1#16 = $d [phi:frame_draw::@5->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1461] phi frame::x#0 = 0 [phi:frame_draw::@5->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1461] phi frame::x1#16 = $43 [phi:frame_draw::@5->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [539] phi from frame_draw::@5 to frame_draw::@6 [phi:frame_draw::@5->frame_draw::@6]
    // frame_draw::@6
    // frame(0, 2, 8, 13)
    // [540] call frame
    // [1461] phi from frame_draw::@6 to frame [phi:frame_draw::@6->frame]
    // [1461] phi frame::y#0 = 2 [phi:frame_draw::@6->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1461] phi frame::y1#16 = $d [phi:frame_draw::@6->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1461] phi frame::x#0 = 0 [phi:frame_draw::@6->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1461] phi frame::x1#16 = 8 [phi:frame_draw::@6->frame#3] -- vbuz1=vbuc1 
    lda #8
    sta.z frame.x1
    jsr frame
    // [541] phi from frame_draw::@6 to frame_draw::@7 [phi:frame_draw::@6->frame_draw::@7]
    // frame_draw::@7
    // frame(8, 2, 19, 13)
    // [542] call frame
    // [1461] phi from frame_draw::@7 to frame [phi:frame_draw::@7->frame]
    // [1461] phi frame::y#0 = 2 [phi:frame_draw::@7->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1461] phi frame::y1#16 = $d [phi:frame_draw::@7->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1461] phi frame::x#0 = 8 [phi:frame_draw::@7->frame#2] -- vbuz1=vbuc1 
    lda #8
    sta.z frame.x
    // [1461] phi frame::x1#16 = $13 [phi:frame_draw::@7->frame#3] -- vbuz1=vbuc1 
    lda #$13
    sta.z frame.x1
    jsr frame
    // [543] phi from frame_draw::@7 to frame_draw::@8 [phi:frame_draw::@7->frame_draw::@8]
    // frame_draw::@8
    // frame(19, 2, 25, 13)
    // [544] call frame
    // [1461] phi from frame_draw::@8 to frame [phi:frame_draw::@8->frame]
    // [1461] phi frame::y#0 = 2 [phi:frame_draw::@8->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1461] phi frame::y1#16 = $d [phi:frame_draw::@8->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1461] phi frame::x#0 = $13 [phi:frame_draw::@8->frame#2] -- vbuz1=vbuc1 
    lda #$13
    sta.z frame.x
    // [1461] phi frame::x1#16 = $19 [phi:frame_draw::@8->frame#3] -- vbuz1=vbuc1 
    lda #$19
    sta.z frame.x1
    jsr frame
    // [545] phi from frame_draw::@8 to frame_draw::@9 [phi:frame_draw::@8->frame_draw::@9]
    // frame_draw::@9
    // frame(25, 2, 31, 13)
    // [546] call frame
    // [1461] phi from frame_draw::@9 to frame [phi:frame_draw::@9->frame]
    // [1461] phi frame::y#0 = 2 [phi:frame_draw::@9->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1461] phi frame::y1#16 = $d [phi:frame_draw::@9->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1461] phi frame::x#0 = $19 [phi:frame_draw::@9->frame#2] -- vbuz1=vbuc1 
    lda #$19
    sta.z frame.x
    // [1461] phi frame::x1#16 = $1f [phi:frame_draw::@9->frame#3] -- vbuz1=vbuc1 
    lda #$1f
    sta.z frame.x1
    jsr frame
    // [547] phi from frame_draw::@9 to frame_draw::@10 [phi:frame_draw::@9->frame_draw::@10]
    // frame_draw::@10
    // frame(31, 2, 37, 13)
    // [548] call frame
    // [1461] phi from frame_draw::@10 to frame [phi:frame_draw::@10->frame]
    // [1461] phi frame::y#0 = 2 [phi:frame_draw::@10->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1461] phi frame::y1#16 = $d [phi:frame_draw::@10->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1461] phi frame::x#0 = $1f [phi:frame_draw::@10->frame#2] -- vbuz1=vbuc1 
    lda #$1f
    sta.z frame.x
    // [1461] phi frame::x1#16 = $25 [phi:frame_draw::@10->frame#3] -- vbuz1=vbuc1 
    lda #$25
    sta.z frame.x1
    jsr frame
    // [549] phi from frame_draw::@10 to frame_draw::@11 [phi:frame_draw::@10->frame_draw::@11]
    // frame_draw::@11
    // frame(37, 2, 43, 13)
    // [550] call frame
    // [1461] phi from frame_draw::@11 to frame [phi:frame_draw::@11->frame]
    // [1461] phi frame::y#0 = 2 [phi:frame_draw::@11->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1461] phi frame::y1#16 = $d [phi:frame_draw::@11->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1461] phi frame::x#0 = $25 [phi:frame_draw::@11->frame#2] -- vbuz1=vbuc1 
    lda #$25
    sta.z frame.x
    // [1461] phi frame::x1#16 = $2b [phi:frame_draw::@11->frame#3] -- vbuz1=vbuc1 
    lda #$2b
    sta.z frame.x1
    jsr frame
    // [551] phi from frame_draw::@11 to frame_draw::@12 [phi:frame_draw::@11->frame_draw::@12]
    // frame_draw::@12
    // frame(43, 2, 49, 13)
    // [552] call frame
    // [1461] phi from frame_draw::@12 to frame [phi:frame_draw::@12->frame]
    // [1461] phi frame::y#0 = 2 [phi:frame_draw::@12->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1461] phi frame::y1#16 = $d [phi:frame_draw::@12->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1461] phi frame::x#0 = $2b [phi:frame_draw::@12->frame#2] -- vbuz1=vbuc1 
    lda #$2b
    sta.z frame.x
    // [1461] phi frame::x1#16 = $31 [phi:frame_draw::@12->frame#3] -- vbuz1=vbuc1 
    lda #$31
    sta.z frame.x1
    jsr frame
    // [553] phi from frame_draw::@12 to frame_draw::@13 [phi:frame_draw::@12->frame_draw::@13]
    // frame_draw::@13
    // frame(49, 2, 55, 13)
    // [554] call frame
    // [1461] phi from frame_draw::@13 to frame [phi:frame_draw::@13->frame]
    // [1461] phi frame::y#0 = 2 [phi:frame_draw::@13->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1461] phi frame::y1#16 = $d [phi:frame_draw::@13->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1461] phi frame::x#0 = $31 [phi:frame_draw::@13->frame#2] -- vbuz1=vbuc1 
    lda #$31
    sta.z frame.x
    // [1461] phi frame::x1#16 = $37 [phi:frame_draw::@13->frame#3] -- vbuz1=vbuc1 
    lda #$37
    sta.z frame.x1
    jsr frame
    // [555] phi from frame_draw::@13 to frame_draw::@14 [phi:frame_draw::@13->frame_draw::@14]
    // frame_draw::@14
    // frame(55, 2, 61, 13)
    // [556] call frame
    // [1461] phi from frame_draw::@14 to frame [phi:frame_draw::@14->frame]
    // [1461] phi frame::y#0 = 2 [phi:frame_draw::@14->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1461] phi frame::y1#16 = $d [phi:frame_draw::@14->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1461] phi frame::x#0 = $37 [phi:frame_draw::@14->frame#2] -- vbuz1=vbuc1 
    lda #$37
    sta.z frame.x
    // [1461] phi frame::x1#16 = $3d [phi:frame_draw::@14->frame#3] -- vbuz1=vbuc1 
    lda #$3d
    sta.z frame.x1
    jsr frame
    // [557] phi from frame_draw::@14 to frame_draw::@15 [phi:frame_draw::@14->frame_draw::@15]
    // frame_draw::@15
    // frame(61, 2, 67, 13)
    // [558] call frame
    // [1461] phi from frame_draw::@15 to frame [phi:frame_draw::@15->frame]
    // [1461] phi frame::y#0 = 2 [phi:frame_draw::@15->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [1461] phi frame::y1#16 = $d [phi:frame_draw::@15->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [1461] phi frame::x#0 = $3d [phi:frame_draw::@15->frame#2] -- vbuz1=vbuc1 
    lda #$3d
    sta.z frame.x
    // [1461] phi frame::x1#16 = $43 [phi:frame_draw::@15->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [559] phi from frame_draw::@15 to frame_draw::@16 [phi:frame_draw::@15->frame_draw::@16]
    // frame_draw::@16
    // frame(0, 13, 67, PROGRESS_Y-5)
    // [560] call frame
    // [1461] phi from frame_draw::@16 to frame [phi:frame_draw::@16->frame]
    // [1461] phi frame::y#0 = $d [phi:frame_draw::@16->frame#0] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y
    // [1461] phi frame::y1#16 = PROGRESS_Y-5 [phi:frame_draw::@16->frame#1] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-5
    sta.z frame.y1
    // [1461] phi frame::x#0 = 0 [phi:frame_draw::@16->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1461] phi frame::x1#16 = $43 [phi:frame_draw::@16->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [561] phi from frame_draw::@16 to frame_draw::@17 [phi:frame_draw::@16->frame_draw::@17]
    // frame_draw::@17
    // frame(0, PROGRESS_Y-5, 67, PROGRESS_Y-2)
    // [562] call frame
    // [1461] phi from frame_draw::@17 to frame [phi:frame_draw::@17->frame]
    // [1461] phi frame::y#0 = PROGRESS_Y-5 [phi:frame_draw::@17->frame#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-5
    sta.z frame.y
    // [1461] phi frame::y1#16 = PROGRESS_Y-2 [phi:frame_draw::@17->frame#1] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-2
    sta.z frame.y1
    // [1461] phi frame::x#0 = 0 [phi:frame_draw::@17->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1461] phi frame::x1#16 = $43 [phi:frame_draw::@17->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [563] phi from frame_draw::@17 to frame_draw::@18 [phi:frame_draw::@17->frame_draw::@18]
    // frame_draw::@18
    // frame(0, PROGRESS_Y-2, 67, 49)
    // [564] call frame
    // [1461] phi from frame_draw::@18 to frame [phi:frame_draw::@18->frame]
    // [1461] phi frame::y#0 = PROGRESS_Y-2 [phi:frame_draw::@18->frame#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-2
    sta.z frame.y
    // [1461] phi frame::y1#16 = $31 [phi:frame_draw::@18->frame#1] -- vbuz1=vbuc1 
    lda #$31
    sta.z frame.y1
    // [1461] phi frame::x#0 = 0 [phi:frame_draw::@18->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [1461] phi frame::x1#16 = $43 [phi:frame_draw::@18->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // frame_draw::@return
    // }
    // [565] return 
    rts
}
  // info_title
// void info_title(char *info_text)
info_title: {
    // gotoxy(2, 1)
    // [567] call gotoxy
    // [486] phi from info_title to gotoxy [phi:info_title->gotoxy]
    // [486] phi gotoxy::y#29 = 1 [phi:info_title->gotoxy#0] -- vbuz1=vbuc1 
    lda #1
    sta.z gotoxy.y
    // [486] phi gotoxy::x#29 = 2 [phi:info_title->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // [568] phi from info_title to info_title::@1 [phi:info_title->info_title::@1]
    // info_title::@1
    // printf("%-65s", info_text)
    // [569] call printf_string
    // [1044] phi from info_title::@1 to printf_string [phi:info_title::@1->printf_string]
    // [1044] phi printf_string::putc#16 = &cputc [phi:info_title::@1->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1044] phi printf_string::str#16 = main::info_text [phi:info_title::@1->printf_string#1] -- pbuz1=pbuc1 
    lda #<main.info_text
    sta.z printf_string.str
    lda #>main.info_text
    sta.z printf_string.str+1
    // [1044] phi printf_string::format_justify_left#16 = 1 [phi:info_title::@1->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1044] phi printf_string::format_min_length#16 = $41 [phi:info_title::@1->printf_string#3] -- vbuz1=vbuc1 
    lda #$41
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_title::@return
    // }
    // [570] return 
    rts
}
  // progress_clear
/**
 * @brief Clean the progress area for the flashing.
 */
progress_clear: {
    .const h = PROGRESS_Y+PROGRESS_H
    .label x = $dc
    .label i = $dd
    .label y = $32
    // textcolor(WHITE)
    // [572] call textcolor
    // [468] phi from progress_clear to textcolor [phi:progress_clear->textcolor]
    // [468] phi textcolor::color#16 = WHITE [phi:progress_clear->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [573] phi from progress_clear to progress_clear::@5 [phi:progress_clear->progress_clear::@5]
    // progress_clear::@5
    // bgcolor(BLUE)
    // [574] call bgcolor
    // [473] phi from progress_clear::@5 to bgcolor [phi:progress_clear::@5->bgcolor]
    // [473] phi bgcolor::color#14 = BLUE [phi:progress_clear::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [575] phi from progress_clear::@5 to progress_clear::@1 [phi:progress_clear::@5->progress_clear::@1]
    // [575] phi progress_clear::y#2 = PROGRESS_Y [phi:progress_clear::@5->progress_clear::@1#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // progress_clear::@1
  __b1:
    // while (y < h)
    // [576] if(progress_clear::y#2<progress_clear::h) goto progress_clear::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y
    cmp #h
    bcc __b4
    // progress_clear::@return
    // }
    // [577] return 
    rts
    // [578] phi from progress_clear::@1 to progress_clear::@2 [phi:progress_clear::@1->progress_clear::@2]
  __b4:
    // [578] phi progress_clear::x#2 = PROGRESS_X [phi:progress_clear::@1->progress_clear::@2#0] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z x
    // [578] phi progress_clear::i#2 = 0 [phi:progress_clear::@1->progress_clear::@2#1] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // progress_clear::@2
  __b2:
    // for(unsigned char i = 0; i < w; i++)
    // [579] if(progress_clear::i#2<PROGRESS_W) goto progress_clear::@3 -- vbuz1_lt_vbuc1_then_la1 
    lda.z i
    cmp #PROGRESS_W
    bcc __b3
    // progress_clear::@4
    // y++;
    // [580] progress_clear::y#1 = ++ progress_clear::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [575] phi from progress_clear::@4 to progress_clear::@1 [phi:progress_clear::@4->progress_clear::@1]
    // [575] phi progress_clear::y#2 = progress_clear::y#1 [phi:progress_clear::@4->progress_clear::@1#0] -- register_copy 
    jmp __b1
    // progress_clear::@3
  __b3:
    // cputcxy(x, y, ' ')
    // [581] cputcxy::x#9 = progress_clear::x#2 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [582] cputcxy::y#9 = progress_clear::y#2 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [583] call cputcxy
    // [1595] phi from progress_clear::@3 to cputcxy [phi:progress_clear::@3->cputcxy]
    // [1595] phi cputcxy::c#13 = ' ' [phi:progress_clear::@3->cputcxy#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z cputcxy.c
    // [1595] phi cputcxy::y#13 = cputcxy::y#9 [phi:progress_clear::@3->cputcxy#1] -- register_copy 
    // [1595] phi cputcxy::x#13 = cputcxy::x#9 [phi:progress_clear::@3->cputcxy#2] -- register_copy 
    jsr cputcxy
    // progress_clear::@6
    // x++;
    // [584] progress_clear::x#1 = ++ progress_clear::x#2 -- vbuz1=_inc_vbuz1 
    inc.z x
    // for(unsigned char i = 0; i < w; i++)
    // [585] progress_clear::i#1 = ++ progress_clear::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [578] phi from progress_clear::@6 to progress_clear::@2 [phi:progress_clear::@6->progress_clear::@2]
    // [578] phi progress_clear::x#2 = progress_clear::x#1 [phi:progress_clear::@6->progress_clear::@2#0] -- register_copy 
    // [578] phi progress_clear::i#2 = progress_clear::i#1 [phi:progress_clear::@6->progress_clear::@2#1] -- register_copy 
    jmp __b2
}
  // info_clear_all
/**
 * @brief Clean the information area.
 * 
 */
info_clear_all: {
    // textcolor(WHITE)
    // [587] call textcolor
    // [468] phi from info_clear_all to textcolor [phi:info_clear_all->textcolor]
    // [468] phi textcolor::color#16 = WHITE [phi:info_clear_all->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [588] phi from info_clear_all to info_clear_all::@3 [phi:info_clear_all->info_clear_all::@3]
    // info_clear_all::@3
    // bgcolor(BLUE)
    // [589] call bgcolor
    // [473] phi from info_clear_all::@3 to bgcolor [phi:info_clear_all::@3->bgcolor]
    // [473] phi bgcolor::color#14 = BLUE [phi:info_clear_all::@3->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [590] phi from info_clear_all::@3 to info_clear_all::@1 [phi:info_clear_all::@3->info_clear_all::@1]
    // [590] phi info_clear_all::l#2 = 0 [phi:info_clear_all::@3->info_clear_all::@1#0] -- vbum1=vbuc1 
    lda #0
    sta l
    // info_clear_all::@1
  __b1:
    // while (l < INFO_H)
    // [591] if(info_clear_all::l#2<$a) goto info_clear_all::@2 -- vbum1_lt_vbuc1_then_la1 
    lda l
    cmp #$a
    bcc __b2
    // info_clear_all::@return
    // }
    // [592] return 
    rts
    // info_clear_all::@2
  __b2:
    // info_clear(l)
    // [593] info_clear::l#0 = info_clear_all::l#2
    // [594] call info_clear
    jsr info_clear
    // info_clear_all::@4
    // l++;
    // [595] info_clear_all::l#1 = ++ info_clear_all::l#2 -- vbum1=_inc_vbum1 
    inc l
    // [590] phi from info_clear_all::@4 to info_clear_all::@1 [phi:info_clear_all::@4->info_clear_all::@1]
    // [590] phi info_clear_all::l#2 = info_clear_all::l#1 [phi:info_clear_all::@4->info_clear_all::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    .label l = main.check_smc3_main__0
}
.segment Code
  // info_progress
// void info_progress(__zp($61) char *info_text)
info_progress: {
    .label x = $24
    .label y = $df
    .label info_text = $61
    // unsigned char x = wherex()
    // [597] call wherex
    jsr wherex
    // [598] wherex::return#2 = wherex::return#0
    // info_progress::@1
    // [599] info_progress::x#0 = wherex::return#2
    // unsigned char y = wherey()
    // [600] call wherey
    jsr wherey
    // [601] wherey::return#2 = wherey::return#0
    // info_progress::@2
    // [602] info_progress::y#0 = wherey::return#2
    // gotoxy(2, PROGRESS_Y-4)
    // [603] call gotoxy
    // [486] phi from info_progress::@2 to gotoxy [phi:info_progress::@2->gotoxy]
    // [486] phi gotoxy::y#29 = PROGRESS_Y-4 [phi:info_progress::@2->gotoxy#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-4
    sta.z gotoxy.y
    // [486] phi gotoxy::x#29 = 2 [phi:info_progress::@2->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // info_progress::@3
    // printf("%-65s", info_text)
    // [604] printf_string::str#0 = info_progress::info_text#12
    // [605] call printf_string
    // [1044] phi from info_progress::@3 to printf_string [phi:info_progress::@3->printf_string]
    // [1044] phi printf_string::putc#16 = &cputc [phi:info_progress::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1044] phi printf_string::str#16 = printf_string::str#0 [phi:info_progress::@3->printf_string#1] -- register_copy 
    // [1044] phi printf_string::format_justify_left#16 = 1 [phi:info_progress::@3->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1044] phi printf_string::format_min_length#16 = $41 [phi:info_progress::@3->printf_string#3] -- vbuz1=vbuc1 
    lda #$41
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_progress::@4
    // gotoxy(x, y)
    // [606] gotoxy::x#10 = info_progress::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [607] gotoxy::y#10 = info_progress::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [608] call gotoxy
    // [486] phi from info_progress::@4 to gotoxy [phi:info_progress::@4->gotoxy]
    // [486] phi gotoxy::y#29 = gotoxy::y#10 [phi:info_progress::@4->gotoxy#0] -- register_copy 
    // [486] phi gotoxy::x#29 = gotoxy::x#10 [phi:info_progress::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // info_progress::@return
    // }
    // [609] return 
    rts
}
  // smc_detect
smc_detect: {
    .label smc_detect__1 = $24
    // When the bootloader is not present, 0xFF is returned.
    .label smc_bootloader_version = $2a
    .label return = $2a
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [610] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [611] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [612] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [613] cx16_k_i2c_read_byte::return#10 = cx16_k_i2c_read_byte::return#1
    // smc_detect::@3
    // smc_bootloader_version = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [614] smc_detect::smc_bootloader_version#1 = cx16_k_i2c_read_byte::return#10
    // BYTE1(smc_bootloader_version)
    // [615] smc_detect::$1 = byte1  smc_detect::smc_bootloader_version#1 -- vbuz1=_byte1_vwuz2 
    lda.z smc_bootloader_version+1
    sta.z smc_detect__1
    // if(!BYTE1(smc_bootloader_version))
    // [616] if(0==smc_detect::$1) goto smc_detect::@1 -- 0_eq_vbuz1_then_la1 
    beq __b1
    // [619] phi from smc_detect::@3 to smc_detect::@2 [phi:smc_detect::@3->smc_detect::@2]
    // [619] phi smc_detect::return#0 = $200 [phi:smc_detect::@3->smc_detect::@2#0] -- vwuz1=vwuc1 
    lda #<$200
    sta.z return
    lda #>$200
    sta.z return+1
    rts
    // smc_detect::@1
  __b1:
    // if(smc_bootloader_version == 0xFF)
    // [617] if(smc_detect::smc_bootloader_version#1!=$ff) goto smc_detect::@4 -- vwuz1_neq_vbuc1_then_la1 
    lda.z smc_bootloader_version+1
    bne __b2
    lda.z smc_bootloader_version
    cmp #$ff
    bne __b2
    // [619] phi from smc_detect::@1 to smc_detect::@2 [phi:smc_detect::@1->smc_detect::@2]
    // [619] phi smc_detect::return#0 = $100 [phi:smc_detect::@1->smc_detect::@2#0] -- vwuz1=vwuc1 
    lda #<$100
    sta.z return
    lda #>$100
    sta.z return+1
    rts
    // [618] phi from smc_detect::@1 to smc_detect::@4 [phi:smc_detect::@1->smc_detect::@4]
    // smc_detect::@4
    // [619] phi from smc_detect::@4 to smc_detect::@2 [phi:smc_detect::@4->smc_detect::@2]
    // [619] phi smc_detect::return#0 = smc_detect::smc_bootloader_version#1 [phi:smc_detect::@4->smc_detect::@2#0] -- register_copy 
    // smc_detect::@2
  __b2:
    // smc_detect::@return
    // }
    // [620] return 
    rts
}
  // chip_smc
chip_smc: {
    // print_smc_led(GREY)
    // [622] call print_smc_led
    // [1623] phi from chip_smc to print_smc_led [phi:chip_smc->print_smc_led]
    // [1623] phi print_smc_led::c#2 = GREY [phi:chip_smc->print_smc_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z print_smc_led.c
    jsr print_smc_led
    // [623] phi from chip_smc to chip_smc::@1 [phi:chip_smc->chip_smc::@1]
    // chip_smc::@1
    // print_chip(CHIP_SMC_X, CHIP_SMC_Y+1, CHIP_SMC_W, "smc     ")
    // [624] call print_chip
    // [1627] phi from chip_smc::@1 to print_chip [phi:chip_smc::@1->print_chip]
    // [1627] phi print_chip::text#11 = chip_smc::text [phi:chip_smc::@1->print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z print_chip.text_2
    lda #>text
    sta.z print_chip.text_2+1
    // [1627] phi print_chip::w#10 = 5 [phi:chip_smc::@1->print_chip#1] -- vbuz1=vbuc1 
    lda #5
    sta.z print_chip.w
    // [1627] phi print_chip::x#10 = 1 [phi:chip_smc::@1->print_chip#2] -- vbuz1=vbuc1 
    lda #1
    sta.z print_chip.x
    jsr print_chip
    // chip_smc::@return
    // }
    // [625] return 
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
    // [626] __snprintf_capacity = $ffff -- vwum1=vwuc1 
    lda #<$ffff
    sta __snprintf_capacity
    lda #>$ffff
    sta __snprintf_capacity+1
    // __snprintf_size = 0
    // [627] __snprintf_size = 0 -- vwum1=vbuc1 
    lda #<0
    sta __snprintf_size
    sta __snprintf_size+1
    // __snprintf_buffer = s
    // [628] __snprintf_buffer = info_text -- pbum1=pbuc1 
    lda #<info_text
    sta __snprintf_buffer
    lda #>info_text
    sta __snprintf_buffer+1
    // snprintf_init::@return
    // }
    // [629] return 
    rts
}
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($4b) void (*putc)(char), __zp($61) const char *s)
printf_str: {
    .label c = $66
    .label s = $61
    .label putc = $4b
    // [631] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [631] phi printf_str::s#65 = printf_str::s#66 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [632] printf_str::c#1 = *printf_str::s#65 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta.z c
    // [633] printf_str::s#0 = ++ printf_str::s#65 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [634] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // printf_str::@return
    // }
    // [635] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [636] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [637] callexecute *printf_str::putc#66  -- call__deref_pprz1 
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
// void printf_uint(__zp($4b) void (*putc)(char), __zp($2a) unsigned int uvalue, __zp($dd) char format_min_length, char format_justify_left, char format_sign_always, __zp($dc) char format_zero_padding, char format_upper_case, __zp($32) char format_radix)
printf_uint: {
    .label uvalue = $2a
    .label format_radix = $32
    .label putc = $4b
    .label format_min_length = $dd
    .label format_zero_padding = $dc
    // printf_uint::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [640] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [641] utoa::value#1 = printf_uint::uvalue#16
    // [642] utoa::radix#0 = printf_uint::format_radix#16
    // [643] call utoa
    // Format number into buffer
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [644] printf_number_buffer::putc#1 = printf_uint::putc#16
    // [645] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [646] printf_number_buffer::format_min_length#1 = printf_uint::format_min_length#16
    // [647] printf_number_buffer::format_zero_padding#1 = printf_uint::format_zero_padding#16
    // [648] call printf_number_buffer
  // Print using format
    // [1701] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    // [1701] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#1 [phi:printf_uint::@2->printf_number_buffer#0] -- register_copy 
    // [1701] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_uint::@2->printf_number_buffer#1] -- register_copy 
    // [1701] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#1 [phi:printf_uint::@2->printf_number_buffer#2] -- register_copy 
    // [1701] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#1 [phi:printf_uint::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [649] return 
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
// void info_smc(__mem() char info_status, __zp($6e) char *info_text)
info_smc: {
    .label info_text = $6e
    // status_smc = info_status
    // [651] status_smc#0 = info_smc::info_status#11 -- vbum1=vbum2 
    lda info_status
    sta status_smc
    // print_smc_led(status_color[info_status])
    // [652] print_smc_led::c#1 = status_color[info_smc::info_status#11] -- vbuz1=pbuc1_derefidx_vbum2 
    ldy info_status
    lda status_color,y
    sta.z print_smc_led.c
    // [653] call print_smc_led
    // [1623] phi from info_smc to print_smc_led [phi:info_smc->print_smc_led]
    // [1623] phi print_smc_led::c#2 = print_smc_led::c#1 [phi:info_smc->print_smc_led#0] -- register_copy 
    jsr print_smc_led
    // [654] phi from info_smc to info_smc::@2 [phi:info_smc->info_smc::@2]
    // info_smc::@2
    // gotoxy(INFO_X, INFO_Y)
    // [655] call gotoxy
    // [486] phi from info_smc::@2 to gotoxy [phi:info_smc::@2->gotoxy]
    // [486] phi gotoxy::y#29 = $11 [phi:info_smc::@2->gotoxy#0] -- vbuz1=vbuc1 
    lda #$11
    sta.z gotoxy.y
    // [486] phi gotoxy::x#29 = 2 [phi:info_smc::@2->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // [656] phi from info_smc::@2 to info_smc::@3 [phi:info_smc::@2->info_smc::@3]
    // info_smc::@3
    // printf("SMC  - %-9s - ATTiny - %05x / 01E00 - ", status_text[info_status], smc_file_size)
    // [657] call printf_str
    // [630] phi from info_smc::@3 to printf_str [phi:info_smc::@3->printf_str]
    // [630] phi printf_str::putc#66 = &cputc [phi:info_smc::@3->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = info_smc::s [phi:info_smc::@3->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // info_smc::@4
    // printf("SMC  - %-9s - ATTiny - %05x / 01E00 - ", status_text[info_status], smc_file_size)
    // [658] info_smc::$5 = info_smc::info_status#11 << 1 -- vbum1=vbum1_rol_1 
    asl info_smc__5
    // [659] printf_string::str#3 = status_text[info_smc::$5] -- pbuz1=qbuc1_derefidx_vbum2 
    ldy info_smc__5
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [660] call printf_string
    // [1044] phi from info_smc::@4 to printf_string [phi:info_smc::@4->printf_string]
    // [1044] phi printf_string::putc#16 = &cputc [phi:info_smc::@4->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1044] phi printf_string::str#16 = printf_string::str#3 [phi:info_smc::@4->printf_string#1] -- register_copy 
    // [1044] phi printf_string::format_justify_left#16 = 1 [phi:info_smc::@4->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1044] phi printf_string::format_min_length#16 = 9 [phi:info_smc::@4->printf_string#3] -- vbuz1=vbuc1 
    lda #9
    sta.z printf_string.format_min_length
    jsr printf_string
    // [661] phi from info_smc::@4 to info_smc::@5 [phi:info_smc::@4->info_smc::@5]
    // info_smc::@5
    // printf("SMC  - %-9s - ATTiny - %05x / 01E00 - ", status_text[info_status], smc_file_size)
    // [662] call printf_str
    // [630] phi from info_smc::@5 to printf_str [phi:info_smc::@5->printf_str]
    // [630] phi printf_str::putc#66 = &cputc [phi:info_smc::@5->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = info_smc::s1 [phi:info_smc::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_smc::@6
    // printf("SMC  - %-9s - ATTiny - %05x / 01E00 - ", status_text[info_status], smc_file_size)
    // [663] printf_uint::uvalue#0 = smc_file_size#12 -- vwuz1=vwum2 
    lda smc_file_size_2
    sta.z printf_uint.uvalue
    lda smc_file_size_2+1
    sta.z printf_uint.uvalue+1
    // [664] call printf_uint
    // [639] phi from info_smc::@6 to printf_uint [phi:info_smc::@6->printf_uint]
    // [639] phi printf_uint::format_zero_padding#16 = 1 [phi:info_smc::@6->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [639] phi printf_uint::format_min_length#16 = 5 [phi:info_smc::@6->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [639] phi printf_uint::putc#16 = &cputc [phi:info_smc::@6->printf_uint#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uint.putc
    lda #>cputc
    sta.z printf_uint.putc+1
    // [639] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:info_smc::@6->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [639] phi printf_uint::uvalue#16 = printf_uint::uvalue#0 [phi:info_smc::@6->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [665] phi from info_smc::@6 to info_smc::@7 [phi:info_smc::@6->info_smc::@7]
    // info_smc::@7
    // printf("SMC  - %-9s - ATTiny - %05x / 01E00 - ", status_text[info_status], smc_file_size)
    // [666] call printf_str
    // [630] phi from info_smc::@7 to printf_str [phi:info_smc::@7->printf_str]
    // [630] phi printf_str::putc#66 = &cputc [phi:info_smc::@7->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = info_smc::s2 [phi:info_smc::@7->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // info_smc::@8
    // if(info_text)
    // [667] if((char *)0==info_smc::info_text#11) goto info_smc::@return -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __breturn
  !:
    // info_smc::@1
    // printf("%20s", info_text)
    // [668] printf_string::str#4 = info_smc::info_text#11 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [669] call printf_string
    // [1044] phi from info_smc::@1 to printf_string [phi:info_smc::@1->printf_string]
    // [1044] phi printf_string::putc#16 = &cputc [phi:info_smc::@1->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1044] phi printf_string::str#16 = printf_string::str#4 [phi:info_smc::@1->printf_string#1] -- register_copy 
    // [1044] phi printf_string::format_justify_left#16 = 0 [phi:info_smc::@1->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1044] phi printf_string::format_min_length#16 = $14 [phi:info_smc::@1->printf_string#3] -- vbuz1=vbuc1 
    lda #$14
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_smc::@return
  __breturn:
    // }
    // [670] return 
    rts
  .segment Data
    s: .text "SMC  - "
    .byte 0
    s1: .text " - ATTiny - "
    .byte 0
    s2: .text " / 01E00 - "
    .byte 0
    .label info_smc__5 = main.check_smc4_main__0
    .label info_status = main.check_smc4_main__0
}
.segment Code
  // chip_vera
chip_vera: {
    // print_vera_led(GREY)
    // [672] call print_vera_led
    // [1732] phi from chip_vera to print_vera_led [phi:chip_vera->print_vera_led]
    // [1732] phi print_vera_led::c#2 = GREY [phi:chip_vera->print_vera_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z print_vera_led.c
    jsr print_vera_led
    // [673] phi from chip_vera to chip_vera::@1 [phi:chip_vera->chip_vera::@1]
    // chip_vera::@1
    // print_chip(CHIP_VERA_X, CHIP_VERA_Y+1, CHIP_VERA_W, "vera     ")
    // [674] call print_chip
    // [1627] phi from chip_vera::@1 to print_chip [phi:chip_vera::@1->print_chip]
    // [1627] phi print_chip::text#11 = chip_vera::text [phi:chip_vera::@1->print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z print_chip.text_2
    lda #>text
    sta.z print_chip.text_2+1
    // [1627] phi print_chip::w#10 = 8 [phi:chip_vera::@1->print_chip#1] -- vbuz1=vbuc1 
    lda #8
    sta.z print_chip.w
    // [1627] phi print_chip::x#10 = 9 [phi:chip_vera::@1->print_chip#2] -- vbuz1=vbuc1 
    lda #9
    sta.z print_chip.x
    jsr print_chip
    // chip_vera::@return
    // }
    // [675] return 
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
// void info_vera(__zp($db) char info_status, __zp($5e) char *info_text)
info_vera: {
    .label info_vera__5 = $db
    .label info_status = $db
    .label info_text = $5e
    // status_vera = info_status
    // [677] status_vera#0 = info_vera::info_status#3 -- vbum1=vbuz2 
    lda.z info_status
    sta status_vera
    // print_vera_led(status_color[info_status])
    // [678] print_vera_led::c#1 = status_color[info_vera::info_status#3] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z print_vera_led.c
    // [679] call print_vera_led
    // [1732] phi from info_vera to print_vera_led [phi:info_vera->print_vera_led]
    // [1732] phi print_vera_led::c#2 = print_vera_led::c#1 [phi:info_vera->print_vera_led#0] -- register_copy 
    jsr print_vera_led
    // [680] phi from info_vera to info_vera::@2 [phi:info_vera->info_vera::@2]
    // info_vera::@2
    // gotoxy(INFO_X, INFO_Y+1)
    // [681] call gotoxy
    // [486] phi from info_vera::@2 to gotoxy [phi:info_vera::@2->gotoxy]
    // [486] phi gotoxy::y#29 = $11+1 [phi:info_vera::@2->gotoxy#0] -- vbuz1=vbuc1 
    lda #$11+1
    sta.z gotoxy.y
    // [486] phi gotoxy::x#29 = 2 [phi:info_vera::@2->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // [682] phi from info_vera::@2 to info_vera::@3 [phi:info_vera::@2->info_vera::@3]
    // info_vera::@3
    // printf("VERA - %-9s - FPGA   - 1a000 / 1a000 - ", status_text[info_status])
    // [683] call printf_str
    // [630] phi from info_vera::@3 to printf_str [phi:info_vera::@3->printf_str]
    // [630] phi printf_str::putc#66 = &cputc [phi:info_vera::@3->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = info_vera::s [phi:info_vera::@3->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // info_vera::@4
    // printf("VERA - %-9s - FPGA   - 1a000 / 1a000 - ", status_text[info_status])
    // [684] info_vera::$5 = info_vera::info_status#3 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z info_vera__5
    // [685] printf_string::str#5 = status_text[info_vera::$5] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z info_vera__5
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [686] call printf_string
    // [1044] phi from info_vera::@4 to printf_string [phi:info_vera::@4->printf_string]
    // [1044] phi printf_string::putc#16 = &cputc [phi:info_vera::@4->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1044] phi printf_string::str#16 = printf_string::str#5 [phi:info_vera::@4->printf_string#1] -- register_copy 
    // [1044] phi printf_string::format_justify_left#16 = 1 [phi:info_vera::@4->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1044] phi printf_string::format_min_length#16 = 9 [phi:info_vera::@4->printf_string#3] -- vbuz1=vbuc1 
    lda #9
    sta.z printf_string.format_min_length
    jsr printf_string
    // [687] phi from info_vera::@4 to info_vera::@5 [phi:info_vera::@4->info_vera::@5]
    // info_vera::@5
    // printf("VERA - %-9s - FPGA   - 1a000 / 1a000 - ", status_text[info_status])
    // [688] call printf_str
    // [630] phi from info_vera::@5 to printf_str [phi:info_vera::@5->printf_str]
    // [630] phi printf_str::putc#66 = &cputc [phi:info_vera::@5->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = info_vera::s1 [phi:info_vera::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_vera::@6
    // if(info_text)
    // [689] if((char *)0==info_vera::info_text#3) goto info_vera::@return -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __breturn
  !:
    // info_vera::@1
    // printf("%20s", info_text)
    // [690] printf_string::str#6 = info_vera::info_text#3 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [691] call printf_string
    // [1044] phi from info_vera::@1 to printf_string [phi:info_vera::@1->printf_string]
    // [1044] phi printf_string::putc#16 = &cputc [phi:info_vera::@1->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1044] phi printf_string::str#16 = printf_string::str#6 [phi:info_vera::@1->printf_string#1] -- register_copy 
    // [1044] phi printf_string::format_justify_left#16 = 0 [phi:info_vera::@1->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1044] phi printf_string::format_min_length#16 = $14 [phi:info_vera::@1->printf_string#3] -- vbuz1=vbuc1 
    lda #$14
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_vera::@return
  __breturn:
    // }
    // [692] return 
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
    .label rom_detect__3 = $df
    .label rom_detect__5 = $df
    .label rom_detect__9 = $66
    .label rom_detect__15 = $b4
    .label rom_detect__18 = $e4
    .label rom_detect__21 = $d9
    .label rom_detect_address = $26
    // [694] phi from rom_detect to rom_detect::@1 [phi:rom_detect->rom_detect::@1]
    // [694] phi rom_detect::rom_chip#10 = 0 [phi:rom_detect->rom_detect::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // [694] phi rom_detect::rom_detect_address#10 = 0 [phi:rom_detect->rom_detect::@1#1] -- vduz1=vduc1 
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
    // [695] if(rom_detect::rom_detect_address#10<8*$80000) goto rom_detect::@2 -- vduz1_lt_vduc1_then_la1 
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
    // [696] return 
    rts
    // rom_detect::@2
  __b2:
    // rom_manufacturer_ids[rom_chip] = 0
    // [697] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = 0
    // [698] rom_device_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta rom_device_ids,y
    // rom_unlock(rom_detect_address + 0x05555, 0x90)
    // [699] rom_unlock::address#2 = rom_detect::rom_detect_address#10 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [700] call rom_unlock
    // [1736] phi from rom_detect::@2 to rom_unlock [phi:rom_detect::@2->rom_unlock]
    // [1736] phi rom_unlock::unlock_code#5 = $90 [phi:rom_detect::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$90
    sta.z rom_unlock.unlock_code
    // [1736] phi rom_unlock::address#5 = rom_unlock::address#2 [phi:rom_detect::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_detect::@12
    // rom_read_byte(rom_detect_address)
    // [701] rom_read_byte::address#0 = rom_detect::rom_detect_address#10 -- vduz1=vduz2 
    lda.z rom_detect_address
    sta.z rom_read_byte.address
    lda.z rom_detect_address+1
    sta.z rom_read_byte.address+1
    lda.z rom_detect_address+2
    sta.z rom_read_byte.address+2
    lda.z rom_detect_address+3
    sta.z rom_read_byte.address+3
    // [702] call rom_read_byte
    // [1746] phi from rom_detect::@12 to rom_read_byte [phi:rom_detect::@12->rom_read_byte]
    // [1746] phi rom_read_byte::address#2 = rom_read_byte::address#0 [phi:rom_detect::@12->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(rom_detect_address)
    // [703] rom_read_byte::return#2 = rom_read_byte::return#0
    // rom_detect::@13
    // [704] rom_detect::$3 = rom_read_byte::return#2
    // rom_manufacturer_ids[rom_chip] = rom_read_byte(rom_detect_address)
    // [705] rom_manufacturer_ids[rom_detect::rom_chip#10] = rom_detect::$3 -- pbuc1_derefidx_vbum1=vbuz2 
    lda.z rom_detect__3
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_read_byte(rom_detect_address + 1)
    // [706] rom_read_byte::address#1 = rom_detect::rom_detect_address#10 + 1 -- vduz1=vduz2_plus_1 
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
    // [707] call rom_read_byte
    // [1746] phi from rom_detect::@13 to rom_read_byte [phi:rom_detect::@13->rom_read_byte]
    // [1746] phi rom_read_byte::address#2 = rom_read_byte::address#1 [phi:rom_detect::@13->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(rom_detect_address + 1)
    // [708] rom_read_byte::return#3 = rom_read_byte::return#0
    // rom_detect::@14
    // [709] rom_detect::$5 = rom_read_byte::return#3
    // rom_device_ids[rom_chip] = rom_read_byte(rom_detect_address + 1)
    // [710] rom_device_ids[rom_detect::rom_chip#10] = rom_detect::$5 -- pbuc1_derefidx_vbum1=vbuz2 
    lda.z rom_detect__5
    ldy rom_chip
    sta rom_device_ids,y
    // rom_unlock(rom_detect_address + 0x05555, 0xF0)
    // [711] rom_unlock::address#3 = rom_detect::rom_detect_address#10 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [712] call rom_unlock
    // [1736] phi from rom_detect::@14 to rom_unlock [phi:rom_detect::@14->rom_unlock]
    // [1736] phi rom_unlock::unlock_code#5 = $f0 [phi:rom_detect::@14->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$f0
    sta.z rom_unlock.unlock_code
    // [1736] phi rom_unlock::address#5 = rom_unlock::address#3 [phi:rom_detect::@14->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_detect::bank_set_brom1
    // BROM = bank
    // [713] BROM = rom_detect::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // rom_detect::@11
    // rom_chip*3
    // [714] rom_detect::$14 = rom_detect::rom_chip#10 << 1 -- vbum1=vbum2_rol_1 
    lda rom_chip
    asl
    sta rom_detect__14
    // [715] rom_detect::$9 = rom_detect::$14 + rom_detect::rom_chip#10 -- vbuz1=vbum2_plus_vbum3 
    clc
    adc rom_chip
    sta.z rom_detect__9
    // gotoxy(rom_chip*3+40, 1)
    // [716] gotoxy::x#22 = rom_detect::$9 + $28 -- vbuz1=vbuz2_plus_vbuc1 
    lda #$28
    clc
    adc.z rom_detect__9
    sta.z gotoxy.x
    // [717] call gotoxy
    // [486] phi from rom_detect::@11 to gotoxy [phi:rom_detect::@11->gotoxy]
    // [486] phi gotoxy::y#29 = 1 [phi:rom_detect::@11->gotoxy#0] -- vbuz1=vbuc1 
    lda #1
    sta.z gotoxy.y
    // [486] phi gotoxy::x#29 = gotoxy::x#22 [phi:rom_detect::@11->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_detect::@15
    // printf("%02x", rom_device_ids[rom_chip])
    // [718] printf_uchar::uvalue#4 = rom_device_ids[rom_detect::rom_chip#10] -- vbuz1=pbuc1_derefidx_vbum2 
    ldy rom_chip
    lda rom_device_ids,y
    sta.z printf_uchar.uvalue
    // [719] call printf_uchar
    // [1028] phi from rom_detect::@15 to printf_uchar [phi:rom_detect::@15->printf_uchar]
    // [1028] phi printf_uchar::format_zero_padding#10 = 1 [phi:rom_detect::@15->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1028] phi printf_uchar::format_min_length#10 = 2 [phi:rom_detect::@15->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [1028] phi printf_uchar::putc#10 = &cputc [phi:rom_detect::@15->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1028] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:rom_detect::@15->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [1028] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#4 [phi:rom_detect::@15->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // rom_detect::@16
    // case SST39SF010A:
    //             rom_device_names[rom_chip] = "f010a";
    //             rom_size_strings[rom_chip] = "128";
    //             rom_sizes[rom_chip] = 128 * 1024;
    //             break;
    // [720] if(rom_device_ids[rom_detect::rom_chip#10]==$b5) goto rom_detect::@3 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
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
    // [721] if(rom_device_ids[rom_detect::rom_chip#10]==$b6) goto rom_detect::@4 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
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
    // [722] if(rom_device_ids[rom_detect::rom_chip#10]==$b7) goto rom_detect::@5 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b7
    beq __b5
    // rom_detect::@6
    // rom_manufacturer_ids[rom_chip] = 0
    // [723] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    sta rom_manufacturer_ids,y
    // rom_device_names[rom_chip] = "----"
    // [724] rom_device_names[rom_detect::$14] = rom_detect::$31 -- qbuc1_derefidx_vbum1=pbuc2 
    ldy rom_detect__14
    lda #<rom_detect__31
    sta rom_device_names,y
    lda #>rom_detect__31
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "000"
    // [725] rom_size_strings[rom_detect::$14] = rom_detect::$32 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__32
    sta rom_size_strings,y
    lda #>rom_detect__32
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 0
    // [726] rom_detect::$24 = rom_detect::rom_chip#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta rom_detect__24
    // [727] rom_sizes[rom_detect::$24] = 0 -- pduc1_derefidx_vbum1=vbuc2 
    tay
    lda #0
    sta rom_sizes,y
    sta rom_sizes+1,y
    sta rom_sizes+2,y
    sta rom_sizes+3,y
    // rom_device_ids[rom_chip] = UNKNOWN
    // [728] rom_device_ids[rom_detect::rom_chip#10] = $55 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$55
    ldy rom_chip
    sta rom_device_ids,y
    // rom_detect::@7
  __b7:
    // rom_chip++;
    // [729] rom_detect::rom_chip#1 = ++ rom_detect::rom_chip#10 -- vbum1=_inc_vbum1 
    inc rom_chip
    // rom_detect::@8
    // rom_detect_address += 0x80000
    // [730] rom_detect::rom_detect_address#1 = rom_detect::rom_detect_address#10 + $80000 -- vduz1=vduz1_plus_vduc1 
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
    // [694] phi from rom_detect::@8 to rom_detect::@1 [phi:rom_detect::@8->rom_detect::@1]
    // [694] phi rom_detect::rom_chip#10 = rom_detect::rom_chip#1 [phi:rom_detect::@8->rom_detect::@1#0] -- register_copy 
    // [694] phi rom_detect::rom_detect_address#10 = rom_detect::rom_detect_address#1 [phi:rom_detect::@8->rom_detect::@1#1] -- register_copy 
    jmp __b1
    // rom_detect::@5
  __b5:
    // rom_device_names[rom_chip] = "f040"
    // [731] rom_device_names[rom_detect::$14] = rom_detect::$29 -- qbuc1_derefidx_vbum1=pbuc2 
    ldy rom_detect__14
    lda #<rom_detect__29
    sta rom_device_names,y
    lda #>rom_detect__29
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "512"
    // [732] rom_size_strings[rom_detect::$14] = rom_detect::$30 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__30
    sta rom_size_strings,y
    lda #>rom_detect__30
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 512 * 1024
    // [733] rom_detect::$21 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__21
    // [734] rom_sizes[rom_detect::$21] = (unsigned long)$200*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
    // [735] rom_device_names[rom_detect::$14] = rom_detect::$27 -- qbuc1_derefidx_vbum1=pbuc2 
    ldy rom_detect__14
    lda #<rom_detect__27
    sta rom_device_names,y
    lda #>rom_detect__27
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "256"
    // [736] rom_size_strings[rom_detect::$14] = rom_detect::$28 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__28
    sta rom_size_strings,y
    lda #>rom_detect__28
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 256 * 1024
    // [737] rom_detect::$18 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__18
    // [738] rom_sizes[rom_detect::$18] = (unsigned long)$100*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
    // [739] rom_device_names[rom_detect::$14] = rom_detect::$25 -- qbuc1_derefidx_vbum1=pbuc2 
    ldy rom_detect__14
    lda #<rom_detect__25
    sta rom_device_names,y
    lda #>rom_detect__25
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "128"
    // [740] rom_size_strings[rom_detect::$14] = rom_detect::$26 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__26
    sta rom_size_strings,y
    lda #>rom_detect__26
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 128 * 1024
    // [741] rom_detect::$15 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__15
    // [742] rom_sizes[rom_detect::$15] = (unsigned long)$80*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
    .label rom_chip = main.check_vera2_main__0
}
.segment Code
  // chip_rom
chip_rom: {
    .label chip_rom__5 = $b5
    .label r = $25
    // [744] phi from chip_rom to chip_rom::@1 [phi:chip_rom->chip_rom::@1]
    // [744] phi chip_rom::r#2 = 0 [phi:chip_rom->chip_rom::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z r
    // chip_rom::@1
  __b1:
    // for (unsigned char r = 0; r < 8; r++)
    // [745] if(chip_rom::r#2<8) goto chip_rom::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z r
    cmp #8
    bcc __b2
    // chip_rom::@return
    // }
    // [746] return 
    rts
    // [747] phi from chip_rom::@1 to chip_rom::@2 [phi:chip_rom::@1->chip_rom::@2]
    // chip_rom::@2
  __b2:
    // strcpy(rom, "rom0 ")
    // [748] call strcpy
    // [1758] phi from chip_rom::@2 to strcpy [phi:chip_rom::@2->strcpy]
    // [1758] phi strcpy::dst#0 = chip_rom::rom [phi:chip_rom::@2->strcpy#0] -- pbum1=pbuc1 
    lda #<rom
    sta strcpy.dst
    lda #>rom
    sta strcpy.dst+1
    // [1758] phi strcpy::src#0 = chip_rom::source [phi:chip_rom::@2->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // chip_rom::@3
    // strcat(rom, rom_size_strings[r])
    // [749] chip_rom::$9 = chip_rom::r#2 << 1 -- vbum1=vbuz2_rol_1 
    lda.z r
    asl
    sta chip_rom__9
    // [750] strcat::source#0 = rom_size_strings[chip_rom::$9] -- pbuz1=qbuc1_derefidx_vbum2 
    tay
    lda rom_size_strings,y
    sta.z strcat.source
    lda rom_size_strings+1,y
    sta.z strcat.source+1
    // [751] call strcat
    // [1766] phi from chip_rom::@3 to strcat [phi:chip_rom::@3->strcat]
    jsr strcat
    // chip_rom::@4
    // r+'0'
    // [752] chip_rom::$3 = chip_rom::r#2 + '0' -- vbum1=vbuz2_plus_vbuc1 
    lda #'0'
    clc
    adc.z r
    sta chip_rom__3
    // *(rom+3) = r+'0'
    // [753] *(chip_rom::rom+3) = chip_rom::$3 -- _deref_pbuc1=vbum1 
    sta rom+3
    // print_rom_led(r, GREY)
    // [754] print_rom_led::chip#0 = chip_rom::r#2 -- vbuz1=vbuz2 
    lda.z r
    sta.z print_rom_led.chip
    // [755] call print_rom_led
    // [1778] phi from chip_rom::@4 to print_rom_led [phi:chip_rom::@4->print_rom_led]
    // [1778] phi print_rom_led::c#2 = GREY [phi:chip_rom::@4->print_rom_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z print_rom_led.c
    // [1778] phi print_rom_led::chip#2 = print_rom_led::chip#0 [phi:chip_rom::@4->print_rom_led#1] -- register_copy 
    jsr print_rom_led
    // chip_rom::@5
    // r*6
    // [756] chip_rom::$10 = chip_rom::$9 + chip_rom::r#2 -- vbum1=vbum1_plus_vbuz2 
    lda chip_rom__10
    clc
    adc.z r
    sta chip_rom__10
    // [757] chip_rom::$5 = chip_rom::$10 << 1 -- vbuz1=vbum2_rol_1 
    asl
    sta.z chip_rom__5
    // print_chip(CHIP_ROM_X+r*6, CHIP_ROM_Y+1, CHIP_ROM_W, rom)
    // [758] print_chip::x#2 = $14 + chip_rom::$5 -- vbuz1=vbuc1_plus_vbuz1 
    lda #$14
    clc
    adc.z print_chip.x
    sta.z print_chip.x
    // [759] call print_chip
    // [1627] phi from chip_rom::@5 to print_chip [phi:chip_rom::@5->print_chip]
    // [1627] phi print_chip::text#11 = chip_rom::rom [phi:chip_rom::@5->print_chip#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z print_chip.text_2
    lda #>rom
    sta.z print_chip.text_2+1
    // [1627] phi print_chip::w#10 = 3 [phi:chip_rom::@5->print_chip#1] -- vbuz1=vbuc1 
    lda #3
    sta.z print_chip.w
    // [1627] phi print_chip::x#10 = print_chip::x#2 [phi:chip_rom::@5->print_chip#2] -- register_copy 
    jsr print_chip
    // chip_rom::@6
    // for (unsigned char r = 0; r < 8; r++)
    // [760] chip_rom::r#1 = ++ chip_rom::r#2 -- vbuz1=_inc_vbuz1 
    inc.z r
    // [744] phi from chip_rom::@6 to chip_rom::@1 [phi:chip_rom::@6->chip_rom::@1]
    // [744] phi chip_rom::r#2 = chip_rom::r#1 [phi:chip_rom::@6->chip_rom::@1#0] -- register_copy 
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
    .label smc_file_read = $aa
    .label ram_address = $f9
    /// Holds the amount of bytes actually read in the memory to be flashed.
    .label progress_row_bytes = $b2
    .label y = $da
    // info_progress("Reading SMC.BIN ... (.) data, ( ) empty")
    // [762] call info_progress
  // It is assume that one RAM bank is 0X2000 bytes.
    // [596] phi from smc_read to info_progress [phi:smc_read->info_progress]
    // [596] phi info_progress::info_text#12 = smc_read::info_text [phi:smc_read->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_progress.info_text
    lda #>info_text
    sta.z info_progress.info_text+1
    jsr info_progress
    // [763] phi from smc_read to smc_read::@7 [phi:smc_read->smc_read::@7]
    // smc_read::@7
    // textcolor(WHITE)
    // [764] call textcolor
    // [468] phi from smc_read::@7 to textcolor [phi:smc_read::@7->textcolor]
    // [468] phi textcolor::color#16 = WHITE [phi:smc_read::@7->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [765] phi from smc_read::@7 to smc_read::@8 [phi:smc_read::@7->smc_read::@8]
    // smc_read::@8
    // gotoxy(x, y)
    // [766] call gotoxy
    // [486] phi from smc_read::@8 to gotoxy [phi:smc_read::@8->gotoxy]
    // [486] phi gotoxy::y#29 = PROGRESS_Y [phi:smc_read::@8->gotoxy#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z gotoxy.y
    // [486] phi gotoxy::x#29 = PROGRESS_X [phi:smc_read::@8->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [767] phi from smc_read::@8 to smc_read::@9 [phi:smc_read::@8->smc_read::@9]
    // smc_read::@9
    // FILE *fp = fopen("SMC.BIN", "r")
    // [768] call fopen
    // [1786] phi from smc_read::@9 to fopen [phi:smc_read::@9->fopen]
    // [1786] phi __errno#301 = __errno#35 [phi:smc_read::@9->fopen#0] -- register_copy 
    // [1786] phi fopen::pathtoken#0 = smc_read::path [phi:smc_read::@9->fopen#1] -- pbuz1=pbuc1 
    lda #<path
    sta.z fopen.pathtoken
    lda #>path
    sta.z fopen.pathtoken+1
    jsr fopen
    // FILE *fp = fopen("SMC.BIN", "r")
    // [769] fopen::return#3 = fopen::return#2
    // smc_read::@10
    // [770] smc_read::fp#0 = fopen::return#3 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [771] if((struct $2 *)0==smc_read::fp#0) goto smc_read::@1 -- pssc1_eq_pssz1_then_la1 
    lda.z fp
    cmp #<0
    bne !+
    lda.z fp+1
    cmp #>0
    beq __b4
  !:
    // [772] phi from smc_read::@10 to smc_read::@2 [phi:smc_read::@10->smc_read::@2]
    // [772] phi smc_read::y#10 = PROGRESS_Y [phi:smc_read::@10->smc_read::@2#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // [772] phi smc_read::progress_row_bytes#10 = 0 [phi:smc_read::@10->smc_read::@2#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z progress_row_bytes
    sta.z progress_row_bytes+1
    // [772] phi smc_read::smc_file_size#11 = 0 [phi:smc_read::@10->smc_read::@2#2] -- vwum1=vwuc1 
    sta smc_file_size
    sta smc_file_size+1
    // [772] phi smc_read::ram_address#10 = (char *)$6000 [phi:smc_read::@10->smc_read::@2#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z ram_address
    lda #>$6000
    sta.z ram_address+1
  // We read b bytes at a time, and each b bytes we plot a dot.
  // Every r bytes we move to the next line.
    // smc_read::@2
  __b2:
    // fgets(ram_address, b, fp)
    // [773] fgets::ptr#2 = smc_read::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z fgets.ptr
    lda.z ram_address+1
    sta.z fgets.ptr+1
    // [774] fgets::stream#0 = smc_read::fp#0 -- pssm1=pssz2 
    lda.z fp
    sta fgets.stream
    lda.z fp+1
    sta fgets.stream+1
    // [775] call fgets
    // [1867] phi from smc_read::@2 to fgets [phi:smc_read::@2->fgets]
    // [1867] phi fgets::ptr#12 = fgets::ptr#2 [phi:smc_read::@2->fgets#0] -- register_copy 
    // [1867] phi fgets::size#10 = 8 [phi:smc_read::@2->fgets#1] -- vwuz1=vbuc1 
    lda #<8
    sta.z fgets.size
    lda #>8
    sta.z fgets.size+1
    // [1867] phi fgets::stream#2 = fgets::stream#0 [phi:smc_read::@2->fgets#2] -- register_copy 
    jsr fgets
    // fgets(ram_address, b, fp)
    // [776] fgets::return#5 = fgets::return#1
    // smc_read::@11
    // smc_file_read = fgets(ram_address, b, fp)
    // [777] smc_read::smc_file_read#1 = fgets::return#5
    // while (smc_file_read = fgets(ram_address, b, fp))
    // [778] if(0!=smc_read::smc_file_read#1) goto smc_read::@3 -- 0_neq_vwuz1_then_la1 
    lda.z smc_file_read
    ora.z smc_file_read+1
    bne __b3
    // smc_read::@4
    // fclose(fp)
    // [779] fclose::stream#0 = smc_read::fp#0
    // [780] call fclose
    // [1921] phi from smc_read::@4 to fclose [phi:smc_read::@4->fclose]
    // [1921] phi fclose::stream#2 = fclose::stream#0 [phi:smc_read::@4->fclose#0] -- register_copy 
    jsr fclose
    // [781] phi from smc_read::@4 to smc_read::@1 [phi:smc_read::@4->smc_read::@1]
    // [781] phi smc_read::return#0 = smc_read::smc_file_size#11 [phi:smc_read::@4->smc_read::@1#0] -- register_copy 
    rts
    // [781] phi from smc_read::@10 to smc_read::@1 [phi:smc_read::@10->smc_read::@1]
  __b4:
    // [781] phi smc_read::return#0 = 0 [phi:smc_read::@10->smc_read::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta return
    sta return+1
    // smc_read::@1
    // smc_read::@return
    // }
    // [782] return 
    rts
    // [783] phi from smc_read::@11 to smc_read::@3 [phi:smc_read::@11->smc_read::@3]
    // smc_read::@3
  __b3:
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [784] call snprintf_init
    jsr snprintf_init
    // [785] phi from smc_read::@3 to smc_read::@12 [phi:smc_read::@3->smc_read::@12]
    // smc_read::@12
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [786] call printf_str
    // [630] phi from smc_read::@12 to printf_str [phi:smc_read::@12->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:smc_read::@12->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = smc_read::s [phi:smc_read::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@13
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [787] printf_uint::uvalue#1 = smc_read::smc_file_read#1 -- vwuz1=vwuz2 
    lda.z smc_file_read
    sta.z printf_uint.uvalue
    lda.z smc_file_read+1
    sta.z printf_uint.uvalue+1
    // [788] call printf_uint
    // [639] phi from smc_read::@13 to printf_uint [phi:smc_read::@13->printf_uint]
    // [639] phi printf_uint::format_zero_padding#16 = 1 [phi:smc_read::@13->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [639] phi printf_uint::format_min_length#16 = 5 [phi:smc_read::@13->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [639] phi printf_uint::putc#16 = &snputc [phi:smc_read::@13->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [639] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:smc_read::@13->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [639] phi printf_uint::uvalue#16 = printf_uint::uvalue#1 [phi:smc_read::@13->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [789] phi from smc_read::@13 to smc_read::@14 [phi:smc_read::@13->smc_read::@14]
    // smc_read::@14
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [790] call printf_str
    // [630] phi from smc_read::@14 to printf_str [phi:smc_read::@14->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:smc_read::@14->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = s1 [phi:smc_read::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@15
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [791] printf_uint::uvalue#2 = smc_read::smc_file_size#11 -- vwuz1=vwum2 
    lda smc_file_size
    sta.z printf_uint.uvalue
    lda smc_file_size+1
    sta.z printf_uint.uvalue+1
    // [792] call printf_uint
    // [639] phi from smc_read::@15 to printf_uint [phi:smc_read::@15->printf_uint]
    // [639] phi printf_uint::format_zero_padding#16 = 1 [phi:smc_read::@15->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [639] phi printf_uint::format_min_length#16 = 5 [phi:smc_read::@15->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [639] phi printf_uint::putc#16 = &snputc [phi:smc_read::@15->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [639] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:smc_read::@15->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [639] phi printf_uint::uvalue#16 = printf_uint::uvalue#2 [phi:smc_read::@15->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [793] phi from smc_read::@15 to smc_read::@16 [phi:smc_read::@15->smc_read::@16]
    // smc_read::@16
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [794] call printf_str
    // [630] phi from smc_read::@16 to printf_str [phi:smc_read::@16->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:smc_read::@16->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = s2 [phi:smc_read::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // [795] phi from smc_read::@16 to smc_read::@17 [phi:smc_read::@16->smc_read::@17]
    // smc_read::@17
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [796] call printf_uint
    // [639] phi from smc_read::@17 to printf_uint [phi:smc_read::@17->printf_uint]
    // [639] phi printf_uint::format_zero_padding#16 = 1 [phi:smc_read::@17->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [639] phi printf_uint::format_min_length#16 = 2 [phi:smc_read::@17->printf_uint#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uint.format_min_length
    // [639] phi printf_uint::putc#16 = &snputc [phi:smc_read::@17->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [639] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:smc_read::@17->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [639] phi printf_uint::uvalue#16 = 0 [phi:smc_read::@17->printf_uint#4] -- vwuz1=vbuc1 
    lda #<0
    sta.z printf_uint.uvalue
    sta.z printf_uint.uvalue+1
    jsr printf_uint
    // [797] phi from smc_read::@17 to smc_read::@18 [phi:smc_read::@17->smc_read::@18]
    // smc_read::@18
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [798] call printf_str
    // [630] phi from smc_read::@18 to printf_str [phi:smc_read::@18->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:smc_read::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = s3 [phi:smc_read::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@19
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [799] printf_uint::uvalue#4 = (unsigned int)smc_read::ram_address#10 -- vwuz1=vwuz2 
    lda.z ram_address
    sta.z printf_uint.uvalue
    lda.z ram_address+1
    sta.z printf_uint.uvalue+1
    // [800] call printf_uint
    // [639] phi from smc_read::@19 to printf_uint [phi:smc_read::@19->printf_uint]
    // [639] phi printf_uint::format_zero_padding#16 = 1 [phi:smc_read::@19->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [639] phi printf_uint::format_min_length#16 = 4 [phi:smc_read::@19->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [639] phi printf_uint::putc#16 = &snputc [phi:smc_read::@19->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [639] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:smc_read::@19->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [639] phi printf_uint::uvalue#16 = printf_uint::uvalue#4 [phi:smc_read::@19->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [801] phi from smc_read::@19 to smc_read::@20 [phi:smc_read::@19->smc_read::@20]
    // smc_read::@20
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [802] call printf_str
    // [630] phi from smc_read::@20 to printf_str [phi:smc_read::@20->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:smc_read::@20->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = s4 [phi:smc_read::@20->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // smc_read::@21
    // sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_address)
    // [803] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [804] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [806] call info_line
    // [845] phi from smc_read::@21 to info_line [phi:smc_read::@21->info_line]
    // [845] phi info_line::info_text#18 = info_text [phi:smc_read::@21->info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_line.info_text
    lda #>@info_text
    sta.z info_line.info_text+1
    jsr info_line
    // smc_read::@22
    // if (progress_row_bytes == progress_row_size)
    // [807] if(smc_read::progress_row_bytes#10!=$200) goto smc_read::@5 -- vwuz1_neq_vwuc1_then_la1 
    lda.z progress_row_bytes+1
    cmp #>$200
    bne __b5
    lda.z progress_row_bytes
    cmp #<$200
    bne __b5
    // smc_read::@6
    // gotoxy(x, ++y);
    // [808] smc_read::y#1 = ++ smc_read::y#10 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [809] gotoxy::y#19 = smc_read::y#1 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [810] call gotoxy
    // [486] phi from smc_read::@6 to gotoxy [phi:smc_read::@6->gotoxy]
    // [486] phi gotoxy::y#29 = gotoxy::y#19 [phi:smc_read::@6->gotoxy#0] -- register_copy 
    // [486] phi gotoxy::x#29 = PROGRESS_X [phi:smc_read::@6->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [811] phi from smc_read::@6 to smc_read::@5 [phi:smc_read::@6->smc_read::@5]
    // [811] phi smc_read::y#20 = smc_read::y#1 [phi:smc_read::@6->smc_read::@5#0] -- register_copy 
    // [811] phi smc_read::progress_row_bytes#4 = 0 [phi:smc_read::@6->smc_read::@5#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z progress_row_bytes
    sta.z progress_row_bytes+1
    // [811] phi from smc_read::@22 to smc_read::@5 [phi:smc_read::@22->smc_read::@5]
    // [811] phi smc_read::y#20 = smc_read::y#10 [phi:smc_read::@22->smc_read::@5#0] -- register_copy 
    // [811] phi smc_read::progress_row_bytes#4 = smc_read::progress_row_bytes#10 [phi:smc_read::@22->smc_read::@5#1] -- register_copy 
    // smc_read::@5
  __b5:
    // cputc('+')
    // [812] stackpush(char) = '+' -- _stackpushbyte_=vbuc1 
    lda #'+'
    pha
    // [813] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // ram_address += smc_file_read
    // [815] smc_read::ram_address#1 = smc_read::ram_address#10 + smc_read::smc_file_read#1 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z ram_address
    adc.z smc_file_read
    sta.z ram_address
    lda.z ram_address+1
    adc.z smc_file_read+1
    sta.z ram_address+1
    // smc_file_size += smc_file_read
    // [816] smc_read::smc_file_size#1 = smc_read::smc_file_size#11 + smc_read::smc_file_read#1 -- vwum1=vwum1_plus_vwuz2 
    clc
    lda smc_file_size
    adc.z smc_file_read
    sta smc_file_size
    lda smc_file_size+1
    adc.z smc_file_read+1
    sta smc_file_size+1
    // progress_row_bytes += smc_file_read
    // [817] smc_read::progress_row_bytes#1 = smc_read::progress_row_bytes#4 + smc_read::smc_file_read#1 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z progress_row_bytes
    adc.z smc_file_read
    sta.z progress_row_bytes
    lda.z progress_row_bytes+1
    adc.z smc_file_read+1
    sta.z progress_row_bytes+1
    // [772] phi from smc_read::@5 to smc_read::@2 [phi:smc_read::@5->smc_read::@2]
    // [772] phi smc_read::y#10 = smc_read::y#20 [phi:smc_read::@5->smc_read::@2#0] -- register_copy 
    // [772] phi smc_read::progress_row_bytes#10 = smc_read::progress_row_bytes#1 [phi:smc_read::@5->smc_read::@2#1] -- register_copy 
    // [772] phi smc_read::smc_file_size#11 = smc_read::smc_file_size#1 [phi:smc_read::@5->smc_read::@2#2] -- register_copy 
    // [772] phi smc_read::ram_address#10 = smc_read::ram_address#1 [phi:smc_read::@5->smc_read::@2#3] -- register_copy 
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
  // wait_key
// __mem() char wait_key(__zp($4b) char *info_text, __zp($63) char *filter)
wait_key: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    .label wait_key__9 = $2a
    .label bram = $d9
    .label bank_get_brom1_return = $e4
    .label info_text = $4b
    .label filter = $63
    // info_line(info_text)
    // [819] info_line::info_text#0 = wait_key::info_text#4
    // [820] call info_line
    // [845] phi from wait_key to info_line [phi:wait_key->info_line]
    // [845] phi info_line::info_text#18 = info_line::info_text#0 [phi:wait_key->info_line#0] -- register_copy 
    jsr info_line
    // wait_key::bank_get_bram1
    // return BRAM;
    // [821] wait_key::bram#0 = BRAM -- vbuz1=vbuz2 
    lda.z BRAM
    sta.z bram
    // wait_key::bank_get_brom1
    // return BROM;
    // [822] wait_key::bank_get_brom1_return#0 = BROM -- vbuz1=vbuz2 
    lda.z BROM
    sta.z bank_get_brom1_return
    // wait_key::bank_set_bram1
    // BRAM = bank
    // [823] BRAM = wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // wait_key::bank_set_brom1
    // BROM = bank
    // [824] BROM = wait_key::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [825] phi from wait_key::@2 wait_key::@5 wait_key::bank_set_brom1 to wait_key::kbhit1 [phi:wait_key::@2/wait_key::@5/wait_key::bank_set_brom1->wait_key::kbhit1]
    // wait_key::kbhit1
  kbhit1:
    // wait_key::kbhit1_cbm_k_clrchn1
    // asm
    // asm { jsrCBM_CLRCHN  }
    jsr CBM_CLRCHN
    // [827] phi from wait_key::kbhit1_cbm_k_clrchn1 to wait_key::kbhit1_@2 [phi:wait_key::kbhit1_cbm_k_clrchn1->wait_key::kbhit1_@2]
    // wait_key::kbhit1_@2
    // cbm_k_getin()
    // [828] call cbm_k_getin
    jsr cbm_k_getin
    // [829] cbm_k_getin::return#2 = cbm_k_getin::return#1
    // wait_key::@4
    // [830] wait_key::ch#4 = cbm_k_getin::return#2 -- vwum1=vbuz2 
    lda.z cbm_k_getin.return
    sta ch
    lda #0
    sta ch+1
    // wait_key::@3
    // if (filter)
    // [831] if((char *)0!=wait_key::filter#14) goto wait_key::@1 -- pbuc1_neq_pbuz1_then_la1 
    // if there is a filter, check the filter, otherwise return ch.
    lda.z filter+1
    cmp #>0
    bne __b1
    lda.z filter
    cmp #<0
    bne __b1
    // wait_key::@2
    // if(ch)
    // [832] if(0!=wait_key::ch#4) goto wait_key::bank_set_bram2 -- 0_neq_vwum1_then_la1 
    lda ch
    ora ch+1
    bne bank_set_bram2
    jmp kbhit1
    // wait_key::bank_set_bram2
  bank_set_bram2:
    // BRAM = bank
    // [833] BRAM = wait_key::bram#0 -- vbuz1=vbuz2 
    lda.z bram
    sta.z BRAM
    // wait_key::bank_set_brom2
    // BROM = bank
    // [834] BROM = wait_key::bank_get_brom1_return#0 -- vbuz1=vbuz2 
    lda.z bank_get_brom1_return
    sta.z BROM
    // wait_key::@return
    // }
    // [835] return 
    rts
    // wait_key::@1
  __b1:
    // strchr(filter, ch)
    // [836] strchr::str#0 = (const void *)wait_key::filter#14 -- pvoz1=pvoz2 
    lda.z filter
    sta.z strchr.str
    lda.z filter+1
    sta.z strchr.str+1
    // [837] strchr::c#0 = wait_key::ch#4 -- vbum1=vwum2 
    lda ch
    sta strchr.c
    // [838] call strchr
    // [1381] phi from wait_key::@1 to strchr [phi:wait_key::@1->strchr]
    // [1381] phi strchr::c#4 = strchr::c#0 [phi:wait_key::@1->strchr#0] -- register_copy 
    // [1381] phi strchr::str#2 = strchr::str#0 [phi:wait_key::@1->strchr#1] -- register_copy 
    jsr strchr
    // strchr(filter, ch)
    // [839] strchr::return#3 = strchr::return#2
    // wait_key::@5
    // [840] wait_key::$9 = strchr::return#3
    // if(strchr(filter, ch) != NULL)
    // [841] if(wait_key::$9!=0) goto wait_key::bank_set_bram2 -- pvoz1_neq_0_then_la1 
    lda.z wait_key__9
    ora.z wait_key__9+1
    bne bank_set_bram2
    jmp kbhit1
  .segment Data
    .label return = strchr.c
    .label ch = rom_read.fp
}
.segment Code
  // info_cx16_rom
// void info_cx16_rom(char info_status, char *info_text)
info_cx16_rom: {
    .label info_text = 0
    // info_rom(0, info_status, info_text)
    // [843] call info_rom
    // [1157] phi from info_cx16_rom to info_rom [phi:info_cx16_rom->info_rom]
    // [1157] phi info_rom::info_text#17 = info_cx16_rom::info_text#0 [phi:info_cx16_rom->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_rom.info_text
    lda #>info_text
    sta.z info_rom.info_text+1
    // [1157] phi info_rom::rom_chip#17 = 0 [phi:info_cx16_rom->info_rom#1] -- vbuz1=vbuc1 
    lda #0
    sta.z info_rom.rom_chip
    // [1157] phi info_rom::info_status#17 = STATUS_ISSUE [phi:info_cx16_rom->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z info_rom.info_status
    jsr info_rom
    // info_cx16_rom::@return
    // }
    // [844] return 
    rts
}
  // info_line
// void info_line(__zp($4b) char *info_text)
info_line: {
    .label info_text = $4b
    .label x = $e2
    .label y = $e0
    // unsigned char x = wherex()
    // [846] call wherex
    jsr wherex
    // [847] wherex::return#3 = wherex::return#0 -- vbuz1=vbuz2 
    lda.z wherex.return
    sta.z wherex.return_1
    // info_line::@1
    // [848] info_line::x#0 = wherex::return#3
    // unsigned char y = wherey()
    // [849] call wherey
    jsr wherey
    // [850] wherey::return#3 = wherey::return#0 -- vbuz1=vbuz2 
    lda.z wherey.return
    sta.z wherey.return_1
    // info_line::@2
    // [851] info_line::y#0 = wherey::return#3
    // gotoxy(2, PROGRESS_Y-3)
    // [852] call gotoxy
    // [486] phi from info_line::@2 to gotoxy [phi:info_line::@2->gotoxy]
    // [486] phi gotoxy::y#29 = PROGRESS_Y-3 [phi:info_line::@2->gotoxy#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-3
    sta.z gotoxy.y
    // [486] phi gotoxy::x#29 = 2 [phi:info_line::@2->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // info_line::@3
    // printf("%-65s", info_text)
    // [853] printf_string::str#1 = info_line::info_text#18 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [854] call printf_string
    // [1044] phi from info_line::@3 to printf_string [phi:info_line::@3->printf_string]
    // [1044] phi printf_string::putc#16 = &cputc [phi:info_line::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1044] phi printf_string::str#16 = printf_string::str#1 [phi:info_line::@3->printf_string#1] -- register_copy 
    // [1044] phi printf_string::format_justify_left#16 = 1 [phi:info_line::@3->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1044] phi printf_string::format_min_length#16 = $41 [phi:info_line::@3->printf_string#3] -- vbuz1=vbuc1 
    lda #$41
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_line::@4
    // gotoxy(x, y)
    // [855] gotoxy::x#12 = info_line::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [856] gotoxy::y#12 = info_line::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [857] call gotoxy
    // [486] phi from info_line::@4 to gotoxy [phi:info_line::@4->gotoxy]
    // [486] phi gotoxy::y#29 = gotoxy::y#12 [phi:info_line::@4->gotoxy#0] -- register_copy 
    // [486] phi gotoxy::x#29 = gotoxy::x#12 [phi:info_line::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // info_line::@return
    // }
    // [858] return 
    rts
}
  // flash_smc
// unsigned int flash_smc(char x, __mem() char y, char w, __zp($cf) unsigned int smc_bytes_total, char b, unsigned int smc_row_total, __zp($d3) char *smc_ram_ptr)
flash_smc: {
    .const smc_row_total = $200
    .label cx16_k_i2c_write_byte1_return = $25
    .label smc_bootloader_start = $25
    .label smc_bootloader_not_activated1 = $2a
    .label x1 = $ac
    .label smc_bootloader_not_activated = $2a
    .label x2 = $26
    .label smc_byte_upload = $e2
    .label smc_ram_ptr = $d3
    .label smc_package_flashed = $61
    .label smc_commit_result = $2a
    .label smc_attempts_flashed = $a9
    .label smc_row_bytes = $d1
    .label smc_bytes_total = $cf
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [859] flash_smc::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [860] flash_smc::cx16_k_i2c_write_byte1_offset = $8f -- vbum1=vbuc1 
    lda #$8f
    sta cx16_k_i2c_write_byte1_offset
    // [861] flash_smc::cx16_k_i2c_write_byte1_value = $31 -- vbum1=vbuc1 
    lda #$31
    sta cx16_k_i2c_write_byte1_value
    // flash_smc::cx16_k_i2c_write_byte1
    // unsigned char result
    // [862] flash_smc::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
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
    // [864] flash_smc::cx16_k_i2c_write_byte1_return#0 = flash_smc::cx16_k_i2c_write_byte1_result -- vbuz1=vbum2 
    lda cx16_k_i2c_write_byte1_result
    sta.z cx16_k_i2c_write_byte1_return
    // flash_smc::cx16_k_i2c_write_byte1_@return
    // }
    // [865] flash_smc::cx16_k_i2c_write_byte1_return#1 = flash_smc::cx16_k_i2c_write_byte1_return#0
    // flash_smc::@27
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [866] flash_smc::smc_bootloader_start#0 = flash_smc::cx16_k_i2c_write_byte1_return#1
    // if(smc_bootloader_start)
    // [867] if(0==flash_smc::smc_bootloader_start#0) goto flash_smc::@3 -- 0_eq_vbuz1_then_la1 
    lda.z smc_bootloader_start
    beq __b2
    // [868] phi from flash_smc::@27 to flash_smc::@2 [phi:flash_smc::@27->flash_smc::@2]
    // flash_smc::@2
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [869] call snprintf_init
    jsr snprintf_init
    // [870] phi from flash_smc::@2 to flash_smc::@30 [phi:flash_smc::@2->flash_smc::@30]
    // flash_smc::@30
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [871] call printf_str
    // [630] phi from flash_smc::@30 to printf_str [phi:flash_smc::@30->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:flash_smc::@30->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = flash_smc::s [phi:flash_smc::@30->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@31
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [872] printf_uchar::uvalue#1 = flash_smc::smc_bootloader_start#0
    // [873] call printf_uchar
    // [1028] phi from flash_smc::@31 to printf_uchar [phi:flash_smc::@31->printf_uchar]
    // [1028] phi printf_uchar::format_zero_padding#10 = 0 [phi:flash_smc::@31->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1028] phi printf_uchar::format_min_length#10 = 0 [phi:flash_smc::@31->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1028] phi printf_uchar::putc#10 = &snputc [phi:flash_smc::@31->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1028] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:flash_smc::@31->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [1028] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#1 [phi:flash_smc::@31->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // flash_smc::@32
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [874] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [875] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [877] call info_line
    // [845] phi from flash_smc::@32 to info_line [phi:flash_smc::@32->info_line]
    // [845] phi info_line::info_text#18 = info_text [phi:flash_smc::@32->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    // flash_smc::@33
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [878] flash_smc::cx16_k_i2c_write_byte2_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte2_device
    // [879] flash_smc::cx16_k_i2c_write_byte2_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte2_offset
    // [880] flash_smc::cx16_k_i2c_write_byte2_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte2_value
    // flash_smc::cx16_k_i2c_write_byte2
    // unsigned char result
    // [881] flash_smc::cx16_k_i2c_write_byte2_result = 0 -- vbum1=vbuc1 
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
    // [883] return 
    rts
    // [884] phi from flash_smc::@27 to flash_smc::@3 [phi:flash_smc::@27->flash_smc::@3]
  __b2:
    // [884] phi flash_smc::smc_bootloader_activation_countdown#22 = $14 [phi:flash_smc::@27->flash_smc::@3#0] -- vbum1=vbuc1 
    lda #$14
    sta smc_bootloader_activation_countdown
    // flash_smc::@3
  __b3:
    // while(smc_bootloader_activation_countdown)
    // [885] if(0!=flash_smc::smc_bootloader_activation_countdown#22) goto flash_smc::@4 -- 0_neq_vbum1_then_la1 
    lda smc_bootloader_activation_countdown
    beq !__b4+
    jmp __b4
  !__b4:
    // [886] phi from flash_smc::@3 flash_smc::@34 to flash_smc::@9 [phi:flash_smc::@3/flash_smc::@34->flash_smc::@9]
  __b5:
    // [886] phi flash_smc::smc_bootloader_activation_countdown#23 = 5 [phi:flash_smc::@3/flash_smc::@34->flash_smc::@9#0] -- vbum1=vbuc1 
    lda #5
    sta smc_bootloader_activation_countdown_1
    // flash_smc::@9
  __b9:
    // while(smc_bootloader_activation_countdown)
    // [887] if(0!=flash_smc::smc_bootloader_activation_countdown#23) goto flash_smc::@11 -- 0_neq_vbum1_then_la1 
    lda smc_bootloader_activation_countdown_1
    beq !__b13+
    jmp __b13
  !__b13:
    // flash_smc::@10
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [888] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [889] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [890] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [891] cx16_k_i2c_read_byte::return#3 = cx16_k_i2c_read_byte::return#1
    // flash_smc::@39
    // smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [892] flash_smc::smc_bootloader_not_activated#1 = cx16_k_i2c_read_byte::return#3
    // if(smc_bootloader_not_activated)
    // [893] if(0==flash_smc::smc_bootloader_not_activated#1) goto flash_smc::@1 -- 0_eq_vwuz1_then_la1 
    lda.z smc_bootloader_not_activated
    ora.z smc_bootloader_not_activated+1
    beq __b1
    // [894] phi from flash_smc::@39 to flash_smc::@14 [phi:flash_smc::@39->flash_smc::@14]
    // flash_smc::@14
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [895] call snprintf_init
    jsr snprintf_init
    // [896] phi from flash_smc::@14 to flash_smc::@46 [phi:flash_smc::@14->flash_smc::@46]
    // flash_smc::@46
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [897] call printf_str
    // [630] phi from flash_smc::@46 to printf_str [phi:flash_smc::@46->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:flash_smc::@46->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = flash_smc::s5 [phi:flash_smc::@46->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@47
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [898] printf_uint::uvalue#5 = flash_smc::smc_bootloader_not_activated#1
    // [899] call printf_uint
    // [639] phi from flash_smc::@47 to printf_uint [phi:flash_smc::@47->printf_uint]
    // [639] phi printf_uint::format_zero_padding#16 = 0 [phi:flash_smc::@47->printf_uint#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uint.format_zero_padding
    // [639] phi printf_uint::format_min_length#16 = 0 [phi:flash_smc::@47->printf_uint#1] -- vbuz1=vbuc1 
    sta.z printf_uint.format_min_length
    // [639] phi printf_uint::putc#16 = &snputc [phi:flash_smc::@47->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [639] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:flash_smc::@47->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [639] phi printf_uint::uvalue#16 = printf_uint::uvalue#5 [phi:flash_smc::@47->printf_uint#4] -- register_copy 
    jsr printf_uint
    // flash_smc::@48
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [900] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [901] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [903] call info_line
    // [845] phi from flash_smc::@48 to info_line [phi:flash_smc::@48->info_line]
    // [845] phi info_line::info_text#18 = info_text [phi:flash_smc::@48->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    rts
    // [904] phi from flash_smc::@39 to flash_smc::@1 [phi:flash_smc::@39->flash_smc::@1]
    // flash_smc::@1
  __b1:
    // textcolor(WHITE)
    // [905] call textcolor
    // [468] phi from flash_smc::@1 to textcolor [phi:flash_smc::@1->textcolor]
    // [468] phi textcolor::color#16 = WHITE [phi:flash_smc::@1->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [906] phi from flash_smc::@1 to flash_smc::@45 [phi:flash_smc::@1->flash_smc::@45]
    // flash_smc::@45
    // gotoxy(x, y)
    // [907] call gotoxy
    // [486] phi from flash_smc::@45 to gotoxy [phi:flash_smc::@45->gotoxy]
    // [486] phi gotoxy::y#29 = PROGRESS_Y [phi:flash_smc::@45->gotoxy#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z gotoxy.y
    // [486] phi gotoxy::x#29 = PROGRESS_X [phi:flash_smc::@45->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [908] phi from flash_smc::@45 to flash_smc::@15 [phi:flash_smc::@45->flash_smc::@15]
    // [908] phi flash_smc::y#33 = PROGRESS_Y [phi:flash_smc::@45->flash_smc::@15#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [908] phi flash_smc::smc_attempts_total#21 = 0 [phi:flash_smc::@45->flash_smc::@15#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_attempts_total
    sta smc_attempts_total+1
    // [908] phi flash_smc::smc_row_bytes#14 = 0 [phi:flash_smc::@45->flash_smc::@15#2] -- vwuz1=vwuc1 
    sta.z smc_row_bytes
    sta.z smc_row_bytes+1
    // [908] phi flash_smc::smc_ram_ptr#13 = (char *)$6000 [phi:flash_smc::@45->flash_smc::@15#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z smc_ram_ptr
    lda #>$6000
    sta.z smc_ram_ptr+1
    // [908] phi flash_smc::smc_bytes_flashed#13 = 0 [phi:flash_smc::@45->flash_smc::@15#4] -- vwum1=vwuc1 
    lda #<0
    sta smc_bytes_flashed
    sta smc_bytes_flashed+1
    // [908] phi from flash_smc::@18 to flash_smc::@15 [phi:flash_smc::@18->flash_smc::@15]
    // [908] phi flash_smc::y#33 = flash_smc::y#23 [phi:flash_smc::@18->flash_smc::@15#0] -- register_copy 
    // [908] phi flash_smc::smc_attempts_total#21 = flash_smc::smc_attempts_total#17 [phi:flash_smc::@18->flash_smc::@15#1] -- register_copy 
    // [908] phi flash_smc::smc_row_bytes#14 = flash_smc::smc_row_bytes#10 [phi:flash_smc::@18->flash_smc::@15#2] -- register_copy 
    // [908] phi flash_smc::smc_ram_ptr#13 = flash_smc::smc_ram_ptr#10 [phi:flash_smc::@18->flash_smc::@15#3] -- register_copy 
    // [908] phi flash_smc::smc_bytes_flashed#13 = flash_smc::smc_bytes_flashed#12 [phi:flash_smc::@18->flash_smc::@15#4] -- register_copy 
    // flash_smc::@15
  __b15:
    // while(smc_bytes_flashed < smc_bytes_total)
    // [909] if(flash_smc::smc_bytes_flashed#13<flash_smc::smc_bytes_total#0) goto flash_smc::@17 -- vwum1_lt_vwuz2_then_la1 
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
    // [910] flash_smc::cx16_k_i2c_write_byte3_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte3_device
    // [911] flash_smc::cx16_k_i2c_write_byte3_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte3_offset
    // [912] flash_smc::cx16_k_i2c_write_byte3_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte3_value
    // flash_smc::cx16_k_i2c_write_byte3
    // unsigned char result
    // [913] flash_smc::cx16_k_i2c_write_byte3_result = 0 -- vbum1=vbuc1 
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
    // [915] phi from flash_smc::@15 to flash_smc::@17 [phi:flash_smc::@15->flash_smc::@17]
  __b8:
    // [915] phi flash_smc::y#23 = flash_smc::y#33 [phi:flash_smc::@15->flash_smc::@17#0] -- register_copy 
    // [915] phi flash_smc::smc_attempts_total#17 = flash_smc::smc_attempts_total#21 [phi:flash_smc::@15->flash_smc::@17#1] -- register_copy 
    // [915] phi flash_smc::smc_row_bytes#10 = flash_smc::smc_row_bytes#14 [phi:flash_smc::@15->flash_smc::@17#2] -- register_copy 
    // [915] phi flash_smc::smc_ram_ptr#10 = flash_smc::smc_ram_ptr#13 [phi:flash_smc::@15->flash_smc::@17#3] -- register_copy 
    // [915] phi flash_smc::smc_bytes_flashed#12 = flash_smc::smc_bytes_flashed#13 [phi:flash_smc::@15->flash_smc::@17#4] -- register_copy 
    // [915] phi flash_smc::smc_attempts_flashed#19 = 0 [phi:flash_smc::@15->flash_smc::@17#5] -- vbuz1=vbuc1 
    lda #0
    sta.z smc_attempts_flashed
    // [915] phi flash_smc::smc_package_committed#2 = 0 [phi:flash_smc::@15->flash_smc::@17#6] -- vbum1=vbuc1 
    sta smc_package_committed
    // flash_smc::@17
  __b17:
    // while(!smc_package_committed && smc_attempts_flashed < 10)
    // [916] if(0!=flash_smc::smc_package_committed#2) goto flash_smc::@18 -- 0_neq_vbum1_then_la1 
    lda smc_package_committed
    bne __b18
    // flash_smc::@61
    // [917] if(flash_smc::smc_attempts_flashed#19<$a) goto flash_smc::@19 -- vbuz1_lt_vbuc1_then_la1 
    lda.z smc_attempts_flashed
    cmp #$a
    bcc __b10
    // flash_smc::@18
  __b18:
    // if(smc_attempts_flashed >= 10)
    // [918] if(flash_smc::smc_attempts_flashed#19<$a) goto flash_smc::@15 -- vbuz1_lt_vbuc1_then_la1 
    lda.z smc_attempts_flashed
    cmp #$a
    bcc __b15
    // [919] phi from flash_smc::@18 to flash_smc::@26 [phi:flash_smc::@18->flash_smc::@26]
    // flash_smc::@26
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [920] call snprintf_init
    jsr snprintf_init
    // [921] phi from flash_smc::@26 to flash_smc::@58 [phi:flash_smc::@26->flash_smc::@58]
    // flash_smc::@58
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [922] call printf_str
    // [630] phi from flash_smc::@58 to printf_str [phi:flash_smc::@58->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:flash_smc::@58->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = flash_smc::s10 [phi:flash_smc::@58->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@59
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [923] printf_uint::uvalue#9 = flash_smc::smc_bytes_flashed#12 -- vwuz1=vwum2 
    lda smc_bytes_flashed
    sta.z printf_uint.uvalue
    lda smc_bytes_flashed+1
    sta.z printf_uint.uvalue+1
    // [924] call printf_uint
    // [639] phi from flash_smc::@59 to printf_uint [phi:flash_smc::@59->printf_uint]
    // [639] phi printf_uint::format_zero_padding#16 = 1 [phi:flash_smc::@59->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [639] phi printf_uint::format_min_length#16 = 4 [phi:flash_smc::@59->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [639] phi printf_uint::putc#16 = &snputc [phi:flash_smc::@59->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [639] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:flash_smc::@59->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [639] phi printf_uint::uvalue#16 = printf_uint::uvalue#9 [phi:flash_smc::@59->printf_uint#4] -- register_copy 
    jsr printf_uint
    // flash_smc::@60
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [925] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [926] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [928] call info_line
    // [845] phi from flash_smc::@60 to info_line [phi:flash_smc::@60->info_line]
    // [845] phi info_line::info_text#18 = info_text [phi:flash_smc::@60->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    rts
    // [929] phi from flash_smc::@61 to flash_smc::@19 [phi:flash_smc::@61->flash_smc::@19]
  __b10:
    // [929] phi flash_smc::smc_bytes_checksum#2 = 0 [phi:flash_smc::@61->flash_smc::@19#0] -- vbum1=vbuc1 
    lda #0
    sta smc_bytes_checksum
    // [929] phi flash_smc::smc_ram_ptr#12 = flash_smc::smc_ram_ptr#10 [phi:flash_smc::@61->flash_smc::@19#1] -- register_copy 
    // [929] phi flash_smc::smc_package_flashed#2 = 0 [phi:flash_smc::@61->flash_smc::@19#2] -- vwuz1=vwuc1 
    sta.z smc_package_flashed
    sta.z smc_package_flashed+1
    // flash_smc::@19
  __b19:
    // while(smc_package_flashed < 8)
    // [930] if(flash_smc::smc_package_flashed#2<8) goto flash_smc::@20 -- vwuz1_lt_vbuc1_then_la1 
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
    // [931] flash_smc::$25 = flash_smc::smc_bytes_checksum#2 ^ $ff -- vbum1=vbum1_bxor_vbuc1 
    lda #$ff
    eor flash_smc__25
    sta flash_smc__25
    // (smc_bytes_checksum ^ 0xFF)+1
    // [932] flash_smc::$26 = flash_smc::$25 + 1 -- vbum1=vbum1_plus_1 
    inc flash_smc__26
    // unsigned char smc_checksum_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, (smc_bytes_checksum ^ 0xFF)+1)
    // [933] flash_smc::cx16_k_i2c_write_byte5_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte5_device
    // [934] flash_smc::cx16_k_i2c_write_byte5_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte5_offset
    // [935] flash_smc::cx16_k_i2c_write_byte5_value = flash_smc::$26 -- vbum1=vbum2 
    lda flash_smc__26
    sta cx16_k_i2c_write_byte5_value
    // flash_smc::cx16_k_i2c_write_byte5
    // unsigned char result
    // [936] flash_smc::cx16_k_i2c_write_byte5_result = 0 -- vbum1=vbuc1 
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
    // [938] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [939] cx16_k_i2c_read_byte::offset = $81 -- vbum1=vbuc1 
    lda #$81
    sta cx16_k_i2c_read_byte.offset
    // [940] call cx16_k_i2c_read_byte
    // Now send the commit command.
    jsr cx16_k_i2c_read_byte
    // [941] cx16_k_i2c_read_byte::return#4 = cx16_k_i2c_read_byte::return#1
    // flash_smc::@49
    // [942] flash_smc::smc_commit_result#0 = cx16_k_i2c_read_byte::return#4
    // if(smc_commit_result == 1)
    // [943] if(flash_smc::smc_commit_result#0==1) goto flash_smc::@23 -- vwuz1_eq_vbuc1_then_la1 
    lda.z smc_commit_result+1
    bne !+
    lda.z smc_commit_result
    cmp #1
    beq __b23
  !:
    // flash_smc::@22
    // smc_ram_ptr -= 8
    // [944] flash_smc::smc_ram_ptr#1 = flash_smc::smc_ram_ptr#12 - 8 -- pbuz1=pbuz1_minus_vbuc1 
    sec
    lda.z smc_ram_ptr
    sbc #8
    sta.z smc_ram_ptr
    lda.z smc_ram_ptr+1
    sbc #0
    sta.z smc_ram_ptr+1
    // smc_attempts_flashed++;
    // [945] flash_smc::smc_attempts_flashed#1 = ++ flash_smc::smc_attempts_flashed#19 -- vbuz1=_inc_vbuz1 
    inc.z smc_attempts_flashed
    // [915] phi from flash_smc::@22 to flash_smc::@17 [phi:flash_smc::@22->flash_smc::@17]
    // [915] phi flash_smc::y#23 = flash_smc::y#23 [phi:flash_smc::@22->flash_smc::@17#0] -- register_copy 
    // [915] phi flash_smc::smc_attempts_total#17 = flash_smc::smc_attempts_total#17 [phi:flash_smc::@22->flash_smc::@17#1] -- register_copy 
    // [915] phi flash_smc::smc_row_bytes#10 = flash_smc::smc_row_bytes#10 [phi:flash_smc::@22->flash_smc::@17#2] -- register_copy 
    // [915] phi flash_smc::smc_ram_ptr#10 = flash_smc::smc_ram_ptr#1 [phi:flash_smc::@22->flash_smc::@17#3] -- register_copy 
    // [915] phi flash_smc::smc_bytes_flashed#12 = flash_smc::smc_bytes_flashed#12 [phi:flash_smc::@22->flash_smc::@17#4] -- register_copy 
    // [915] phi flash_smc::smc_attempts_flashed#19 = flash_smc::smc_attempts_flashed#1 [phi:flash_smc::@22->flash_smc::@17#5] -- register_copy 
    // [915] phi flash_smc::smc_package_committed#2 = flash_smc::smc_package_committed#2 [phi:flash_smc::@22->flash_smc::@17#6] -- register_copy 
    jmp __b17
    // flash_smc::@23
  __b23:
    // if (smc_row_bytes == smc_row_total)
    // [946] if(flash_smc::smc_row_bytes#10!=flash_smc::smc_row_total#0) goto flash_smc::@24 -- vwuz1_neq_vwuc1_then_la1 
    lda.z smc_row_bytes+1
    cmp #>smc_row_total
    bne __b24
    lda.z smc_row_bytes
    cmp #<smc_row_total
    bne __b24
    // flash_smc::@25
    // gotoxy(x, ++y);
    // [947] flash_smc::y#0 = ++ flash_smc::y#23 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [948] gotoxy::y#21 = flash_smc::y#0 -- vbuz1=vbum2 
    lda y
    sta.z gotoxy.y
    // [949] call gotoxy
    // [486] phi from flash_smc::@25 to gotoxy [phi:flash_smc::@25->gotoxy]
    // [486] phi gotoxy::y#29 = gotoxy::y#21 [phi:flash_smc::@25->gotoxy#0] -- register_copy 
    // [486] phi gotoxy::x#29 = PROGRESS_X [phi:flash_smc::@25->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [950] phi from flash_smc::@25 to flash_smc::@24 [phi:flash_smc::@25->flash_smc::@24]
    // [950] phi flash_smc::y#35 = flash_smc::y#0 [phi:flash_smc::@25->flash_smc::@24#0] -- register_copy 
    // [950] phi flash_smc::smc_row_bytes#4 = 0 [phi:flash_smc::@25->flash_smc::@24#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z smc_row_bytes
    sta.z smc_row_bytes+1
    // [950] phi from flash_smc::@23 to flash_smc::@24 [phi:flash_smc::@23->flash_smc::@24]
    // [950] phi flash_smc::y#35 = flash_smc::y#23 [phi:flash_smc::@23->flash_smc::@24#0] -- register_copy 
    // [950] phi flash_smc::smc_row_bytes#4 = flash_smc::smc_row_bytes#10 [phi:flash_smc::@23->flash_smc::@24#1] -- register_copy 
    // flash_smc::@24
  __b24:
    // cputc('*')
    // [951] stackpush(char) = '*' -- _stackpushbyte_=vbuc1 
    lda #'*'
    pha
    // [952] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_bytes_flashed += 8
    // [954] flash_smc::smc_bytes_flashed#1 = flash_smc::smc_bytes_flashed#12 + 8 -- vwum1=vwum1_plus_vbuc1 
    lda #8
    clc
    adc smc_bytes_flashed
    sta smc_bytes_flashed
    bcc !+
    inc smc_bytes_flashed+1
  !:
    // smc_row_bytes += 8
    // [955] flash_smc::smc_row_bytes#1 = flash_smc::smc_row_bytes#4 + 8 -- vwuz1=vwuz1_plus_vbuc1 
    lda #8
    clc
    adc.z smc_row_bytes
    sta.z smc_row_bytes
    bcc !+
    inc.z smc_row_bytes+1
  !:
    // smc_attempts_total += smc_attempts_flashed
    // [956] flash_smc::smc_attempts_total#1 = flash_smc::smc_attempts_total#17 + flash_smc::smc_attempts_flashed#19 -- vwum1=vwum1_plus_vbuz2 
    lda.z smc_attempts_flashed
    clc
    adc smc_attempts_total
    sta smc_attempts_total
    bcc !+
    inc smc_attempts_total+1
  !:
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [957] call snprintf_init
    jsr snprintf_init
    // [958] phi from flash_smc::@24 to flash_smc::@50 [phi:flash_smc::@24->flash_smc::@50]
    // flash_smc::@50
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [959] call printf_str
    // [630] phi from flash_smc::@50 to printf_str [phi:flash_smc::@50->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:flash_smc::@50->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = flash_smc::s6 [phi:flash_smc::@50->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@51
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [960] printf_uint::uvalue#6 = flash_smc::smc_bytes_flashed#1 -- vwuz1=vwum2 
    lda smc_bytes_flashed
    sta.z printf_uint.uvalue
    lda smc_bytes_flashed+1
    sta.z printf_uint.uvalue+1
    // [961] call printf_uint
    // [639] phi from flash_smc::@51 to printf_uint [phi:flash_smc::@51->printf_uint]
    // [639] phi printf_uint::format_zero_padding#16 = 1 [phi:flash_smc::@51->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [639] phi printf_uint::format_min_length#16 = 5 [phi:flash_smc::@51->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [639] phi printf_uint::putc#16 = &snputc [phi:flash_smc::@51->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [639] phi printf_uint::format_radix#16 = DECIMAL [phi:flash_smc::@51->printf_uint#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [639] phi printf_uint::uvalue#16 = printf_uint::uvalue#6 [phi:flash_smc::@51->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [962] phi from flash_smc::@51 to flash_smc::@52 [phi:flash_smc::@51->flash_smc::@52]
    // flash_smc::@52
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [963] call printf_str
    // [630] phi from flash_smc::@52 to printf_str [phi:flash_smc::@52->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:flash_smc::@52->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = flash_smc::s7 [phi:flash_smc::@52->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@53
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [964] printf_uint::uvalue#7 = flash_smc::smc_bytes_total#0 -- vwuz1=vwuz2 
    lda.z smc_bytes_total
    sta.z printf_uint.uvalue
    lda.z smc_bytes_total+1
    sta.z printf_uint.uvalue+1
    // [965] call printf_uint
    // [639] phi from flash_smc::@53 to printf_uint [phi:flash_smc::@53->printf_uint]
    // [639] phi printf_uint::format_zero_padding#16 = 1 [phi:flash_smc::@53->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [639] phi printf_uint::format_min_length#16 = 5 [phi:flash_smc::@53->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [639] phi printf_uint::putc#16 = &snputc [phi:flash_smc::@53->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [639] phi printf_uint::format_radix#16 = DECIMAL [phi:flash_smc::@53->printf_uint#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [639] phi printf_uint::uvalue#16 = printf_uint::uvalue#7 [phi:flash_smc::@53->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [966] phi from flash_smc::@53 to flash_smc::@54 [phi:flash_smc::@53->flash_smc::@54]
    // flash_smc::@54
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [967] call printf_str
    // [630] phi from flash_smc::@54 to printf_str [phi:flash_smc::@54->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:flash_smc::@54->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = flash_smc::s8 [phi:flash_smc::@54->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@55
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [968] printf_uint::uvalue#8 = flash_smc::smc_attempts_total#1 -- vwuz1=vwum2 
    lda smc_attempts_total
    sta.z printf_uint.uvalue
    lda smc_attempts_total+1
    sta.z printf_uint.uvalue+1
    // [969] call printf_uint
    // [639] phi from flash_smc::@55 to printf_uint [phi:flash_smc::@55->printf_uint]
    // [639] phi printf_uint::format_zero_padding#16 = 1 [phi:flash_smc::@55->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [639] phi printf_uint::format_min_length#16 = 2 [phi:flash_smc::@55->printf_uint#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uint.format_min_length
    // [639] phi printf_uint::putc#16 = &snputc [phi:flash_smc::@55->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [639] phi printf_uint::format_radix#16 = DECIMAL [phi:flash_smc::@55->printf_uint#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [639] phi printf_uint::uvalue#16 = printf_uint::uvalue#8 [phi:flash_smc::@55->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [970] phi from flash_smc::@55 to flash_smc::@56 [phi:flash_smc::@55->flash_smc::@56]
    // flash_smc::@56
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [971] call printf_str
    // [630] phi from flash_smc::@56 to printf_str [phi:flash_smc::@56->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:flash_smc::@56->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = flash_smc::s9 [phi:flash_smc::@56->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@57
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [972] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [973] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [975] call info_line
    // [845] phi from flash_smc::@57 to info_line [phi:flash_smc::@57->info_line]
    // [845] phi info_line::info_text#18 = info_text [phi:flash_smc::@57->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    // [915] phi from flash_smc::@57 to flash_smc::@17 [phi:flash_smc::@57->flash_smc::@17]
    // [915] phi flash_smc::y#23 = flash_smc::y#35 [phi:flash_smc::@57->flash_smc::@17#0] -- register_copy 
    // [915] phi flash_smc::smc_attempts_total#17 = flash_smc::smc_attempts_total#1 [phi:flash_smc::@57->flash_smc::@17#1] -- register_copy 
    // [915] phi flash_smc::smc_row_bytes#10 = flash_smc::smc_row_bytes#1 [phi:flash_smc::@57->flash_smc::@17#2] -- register_copy 
    // [915] phi flash_smc::smc_ram_ptr#10 = flash_smc::smc_ram_ptr#12 [phi:flash_smc::@57->flash_smc::@17#3] -- register_copy 
    // [915] phi flash_smc::smc_bytes_flashed#12 = flash_smc::smc_bytes_flashed#1 [phi:flash_smc::@57->flash_smc::@17#4] -- register_copy 
    // [915] phi flash_smc::smc_attempts_flashed#19 = flash_smc::smc_attempts_flashed#19 [phi:flash_smc::@57->flash_smc::@17#5] -- register_copy 
    // [915] phi flash_smc::smc_package_committed#2 = 1 [phi:flash_smc::@57->flash_smc::@17#6] -- vbum1=vbuc1 
    lda #1
    sta smc_package_committed
    jmp __b17
    // flash_smc::@20
  __b20:
    // unsigned char smc_byte_upload = *smc_ram_ptr
    // [976] flash_smc::smc_byte_upload#0 = *flash_smc::smc_ram_ptr#12 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (smc_ram_ptr),y
    sta.z smc_byte_upload
    // smc_ram_ptr++;
    // [977] flash_smc::smc_ram_ptr#0 = ++ flash_smc::smc_ram_ptr#12 -- pbuz1=_inc_pbuz1 
    inc.z smc_ram_ptr
    bne !+
    inc.z smc_ram_ptr+1
  !:
    // smc_bytes_checksum += smc_byte_upload
    // [978] flash_smc::smc_bytes_checksum#1 = flash_smc::smc_bytes_checksum#2 + flash_smc::smc_byte_upload#0 -- vbum1=vbum1_plus_vbuz2 
    lda smc_bytes_checksum
    clc
    adc.z smc_byte_upload
    sta smc_bytes_checksum
    // unsigned char smc_upload_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, smc_byte_upload)
    // [979] flash_smc::cx16_k_i2c_write_byte4_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte4_device
    // [980] flash_smc::cx16_k_i2c_write_byte4_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte4_offset
    // [981] flash_smc::cx16_k_i2c_write_byte4_value = flash_smc::smc_byte_upload#0 -- vbum1=vbuz2 
    lda.z smc_byte_upload
    sta cx16_k_i2c_write_byte4_value
    // flash_smc::cx16_k_i2c_write_byte4
    // unsigned char result
    // [982] flash_smc::cx16_k_i2c_write_byte4_result = 0 -- vbum1=vbuc1 
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
    // [984] flash_smc::smc_package_flashed#1 = ++ flash_smc::smc_package_flashed#2 -- vwuz1=_inc_vwuz1 
    inc.z smc_package_flashed
    bne !+
    inc.z smc_package_flashed+1
  !:
    // [929] phi from flash_smc::@28 to flash_smc::@19 [phi:flash_smc::@28->flash_smc::@19]
    // [929] phi flash_smc::smc_bytes_checksum#2 = flash_smc::smc_bytes_checksum#1 [phi:flash_smc::@28->flash_smc::@19#0] -- register_copy 
    // [929] phi flash_smc::smc_ram_ptr#12 = flash_smc::smc_ram_ptr#0 [phi:flash_smc::@28->flash_smc::@19#1] -- register_copy 
    // [929] phi flash_smc::smc_package_flashed#2 = flash_smc::smc_package_flashed#1 [phi:flash_smc::@28->flash_smc::@19#2] -- register_copy 
    jmp __b19
    // [985] phi from flash_smc::@9 to flash_smc::@11 [phi:flash_smc::@9->flash_smc::@11]
  __b13:
    // [985] phi flash_smc::x2#2 = $10000*1 [phi:flash_smc::@9->flash_smc::@11#0] -- vduz1=vduc1 
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
    // [986] if(flash_smc::x2#2>0) goto flash_smc::@12 -- vduz1_gt_0_then_la1 
    lda.z x2+3
    bne __b12
    lda.z x2+2
    bne __b12
    lda.z x2+1
    bne __b12
    lda.z x2
    bne __b12
  !:
    // [987] phi from flash_smc::@11 to flash_smc::@13 [phi:flash_smc::@11->flash_smc::@13]
    // flash_smc::@13
    // sprintf(info_text, "Waiting an other %u seconds before flashing the SMC!", smc_bootloader_activation_countdown)
    // [988] call snprintf_init
    jsr snprintf_init
    // [989] phi from flash_smc::@13 to flash_smc::@40 [phi:flash_smc::@13->flash_smc::@40]
    // flash_smc::@40
    // sprintf(info_text, "Waiting an other %u seconds before flashing the SMC!", smc_bootloader_activation_countdown)
    // [990] call printf_str
    // [630] phi from flash_smc::@40 to printf_str [phi:flash_smc::@40->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:flash_smc::@40->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = flash_smc::s3 [phi:flash_smc::@40->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@41
    // sprintf(info_text, "Waiting an other %u seconds before flashing the SMC!", smc_bootloader_activation_countdown)
    // [991] printf_uchar::uvalue#3 = flash_smc::smc_bootloader_activation_countdown#23 -- vbuz1=vbum2 
    lda smc_bootloader_activation_countdown_1
    sta.z printf_uchar.uvalue
    // [992] call printf_uchar
    // [1028] phi from flash_smc::@41 to printf_uchar [phi:flash_smc::@41->printf_uchar]
    // [1028] phi printf_uchar::format_zero_padding#10 = 0 [phi:flash_smc::@41->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1028] phi printf_uchar::format_min_length#10 = 0 [phi:flash_smc::@41->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1028] phi printf_uchar::putc#10 = &snputc [phi:flash_smc::@41->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1028] phi printf_uchar::format_radix#10 = DECIMAL [phi:flash_smc::@41->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1028] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#3 [phi:flash_smc::@41->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [993] phi from flash_smc::@41 to flash_smc::@42 [phi:flash_smc::@41->flash_smc::@42]
    // flash_smc::@42
    // sprintf(info_text, "Waiting an other %u seconds before flashing the SMC!", smc_bootloader_activation_countdown)
    // [994] call printf_str
    // [630] phi from flash_smc::@42 to printf_str [phi:flash_smc::@42->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:flash_smc::@42->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = flash_smc::s4 [phi:flash_smc::@42->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@43
    // sprintf(info_text, "Waiting an other %u seconds before flashing the SMC!", smc_bootloader_activation_countdown)
    // [995] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [996] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [998] call info_line
    // [845] phi from flash_smc::@43 to info_line [phi:flash_smc::@43->info_line]
    // [845] phi info_line::info_text#18 = info_text [phi:flash_smc::@43->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    // flash_smc::@44
    // smc_bootloader_activation_countdown--;
    // [999] flash_smc::smc_bootloader_activation_countdown#3 = -- flash_smc::smc_bootloader_activation_countdown#23 -- vbum1=_dec_vbum1 
    dec smc_bootloader_activation_countdown_1
    // [886] phi from flash_smc::@44 to flash_smc::@9 [phi:flash_smc::@44->flash_smc::@9]
    // [886] phi flash_smc::smc_bootloader_activation_countdown#23 = flash_smc::smc_bootloader_activation_countdown#3 [phi:flash_smc::@44->flash_smc::@9#0] -- register_copy 
    jmp __b9
    // flash_smc::@12
  __b12:
    // for(unsigned long x=65536*1; x>0; x--)
    // [1000] flash_smc::x2#1 = -- flash_smc::x2#2 -- vduz1=_dec_vduz1 
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
    // [985] phi from flash_smc::@12 to flash_smc::@11 [phi:flash_smc::@12->flash_smc::@11]
    // [985] phi flash_smc::x2#2 = flash_smc::x2#1 [phi:flash_smc::@12->flash_smc::@11#0] -- register_copy 
    jmp __b11
    // flash_smc::@4
  __b4:
    // unsigned int smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1001] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1002] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [1003] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [1004] cx16_k_i2c_read_byte::return#2 = cx16_k_i2c_read_byte::return#1
    // flash_smc::@34
    // [1005] flash_smc::smc_bootloader_not_activated1#0 = cx16_k_i2c_read_byte::return#2
    // if(smc_bootloader_not_activated)
    // [1006] if(0!=flash_smc::smc_bootloader_not_activated1#0) goto flash_smc::@6 -- 0_neq_vwuz1_then_la1 
    lda.z smc_bootloader_not_activated1
    ora.z smc_bootloader_not_activated1+1
    bne __b14
    jmp __b5
    // [1007] phi from flash_smc::@34 to flash_smc::@6 [phi:flash_smc::@34->flash_smc::@6]
  __b14:
    // [1007] phi flash_smc::x1#2 = $10000*6 [phi:flash_smc::@34->flash_smc::@6#0] -- vduz1=vduc1 
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
    // [1008] if(flash_smc::x1#2>0) goto flash_smc::@7 -- vduz1_gt_0_then_la1 
    lda.z x1+3
    bne __b7
    lda.z x1+2
    bne __b7
    lda.z x1+1
    bne __b7
    lda.z x1
    bne __b7
  !:
    // [1009] phi from flash_smc::@6 to flash_smc::@8 [phi:flash_smc::@6->flash_smc::@8]
    // flash_smc::@8
    // sprintf(info_text, "Press POWER and RESET on the CX16 within %u seconds!", smc_bootloader_activation_countdown)
    // [1010] call snprintf_init
    jsr snprintf_init
    // [1011] phi from flash_smc::@8 to flash_smc::@35 [phi:flash_smc::@8->flash_smc::@35]
    // flash_smc::@35
    // sprintf(info_text, "Press POWER and RESET on the CX16 within %u seconds!", smc_bootloader_activation_countdown)
    // [1012] call printf_str
    // [630] phi from flash_smc::@35 to printf_str [phi:flash_smc::@35->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:flash_smc::@35->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = flash_smc::s1 [phi:flash_smc::@35->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@36
    // sprintf(info_text, "Press POWER and RESET on the CX16 within %u seconds!", smc_bootloader_activation_countdown)
    // [1013] printf_uchar::uvalue#2 = flash_smc::smc_bootloader_activation_countdown#22 -- vbuz1=vbum2 
    lda smc_bootloader_activation_countdown
    sta.z printf_uchar.uvalue
    // [1014] call printf_uchar
    // [1028] phi from flash_smc::@36 to printf_uchar [phi:flash_smc::@36->printf_uchar]
    // [1028] phi printf_uchar::format_zero_padding#10 = 0 [phi:flash_smc::@36->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1028] phi printf_uchar::format_min_length#10 = 0 [phi:flash_smc::@36->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1028] phi printf_uchar::putc#10 = &snputc [phi:flash_smc::@36->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1028] phi printf_uchar::format_radix#10 = DECIMAL [phi:flash_smc::@36->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1028] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#2 [phi:flash_smc::@36->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1015] phi from flash_smc::@36 to flash_smc::@37 [phi:flash_smc::@36->flash_smc::@37]
    // flash_smc::@37
    // sprintf(info_text, "Press POWER and RESET on the CX16 within %u seconds!", smc_bootloader_activation_countdown)
    // [1016] call printf_str
    // [630] phi from flash_smc::@37 to printf_str [phi:flash_smc::@37->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:flash_smc::@37->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = flash_smc::s2 [phi:flash_smc::@37->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@38
    // sprintf(info_text, "Press POWER and RESET on the CX16 within %u seconds!", smc_bootloader_activation_countdown)
    // [1017] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1018] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [1020] call info_line
    // [845] phi from flash_smc::@38 to info_line [phi:flash_smc::@38->info_line]
    // [845] phi info_line::info_text#18 = info_text [phi:flash_smc::@38->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    // flash_smc::@5
    // smc_bootloader_activation_countdown--;
    // [1021] flash_smc::smc_bootloader_activation_countdown#2 = -- flash_smc::smc_bootloader_activation_countdown#22 -- vbum1=_dec_vbum1 
    dec smc_bootloader_activation_countdown
    // [884] phi from flash_smc::@5 to flash_smc::@3 [phi:flash_smc::@5->flash_smc::@3]
    // [884] phi flash_smc::smc_bootloader_activation_countdown#22 = flash_smc::smc_bootloader_activation_countdown#2 [phi:flash_smc::@5->flash_smc::@3#0] -- register_copy 
    jmp __b3
    // flash_smc::@7
  __b7:
    // for(unsigned long x=65536*6; x>0; x--)
    // [1022] flash_smc::x1#1 = -- flash_smc::x1#2 -- vduz1=_dec_vduz1 
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
    // [1007] phi from flash_smc::@7 to flash_smc::@6 [phi:flash_smc::@7->flash_smc::@6]
    // [1007] phi flash_smc::x1#2 = flash_smc::x1#1 [phi:flash_smc::@7->flash_smc::@6#0] -- register_copy 
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
    .label flash_smc__25 = main.check_smc4_main__0
    .label flash_smc__26 = main.check_smc4_main__0
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
    .label smc_bootloader_activation_countdown_1 = main.check_roms1_check_rom1_main__0
    .label smc_bytes_checksum = main.check_smc4_main__0
    .label smc_bytes_flashed = fopen.pathtoken_1
    .label smc_attempts_total = fgets.stream
    .label y = main.check_rom1_main__0
    .label smc_package_committed = main.check_smc3_main__0
}
.segment Code
  // system_reset
system_reset: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    // system_reset::bank_set_bram1
    // BRAM = bank
    // [1024] BRAM = system_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // system_reset::bank_set_brom1
    // BROM = bank
    // [1025] BROM = system_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // system_reset::@1
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // system_reset::@return
    // }
    // [1027] return 
}
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(__zp($4b) void (*putc)(char), __zp($25) char uvalue, __zp($dd) char format_min_length, char format_justify_left, char format_sign_always, __zp($dc) char format_zero_padding, char format_upper_case, __zp($db) char format_radix)
printf_uchar: {
    .label uvalue = $25
    .label format_radix = $db
    .label putc = $4b
    .label format_min_length = $dd
    .label format_zero_padding = $dc
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
    // [1035] printf_number_buffer::format_min_length#2 = printf_uchar::format_min_length#10
    // [1036] printf_number_buffer::format_zero_padding#2 = printf_uchar::format_zero_padding#10
    // [1037] call printf_number_buffer
  // Print using format
    // [1701] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [1701] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#2 [phi:printf_uchar::@2->printf_number_buffer#0] -- register_copy 
    // [1701] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#2 [phi:printf_uchar::@2->printf_number_buffer#1] -- register_copy 
    // [1701] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#2 [phi:printf_uchar::@2->printf_number_buffer#2] -- register_copy 
    // [1701] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#2 [phi:printf_uchar::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [1038] return 
    rts
}
  // rom_file
// char * rom_file(__mem() char rom_chip)
rom_file: {
    // strcpy(file, "ROM .BIN")
    // [1040] call strcpy
    // [1758] phi from rom_file to strcpy [phi:rom_file->strcpy]
    // [1758] phi strcpy::dst#0 = rom_file::file [phi:rom_file->strcpy#0] -- pbum1=pbuc1 
    lda #<file
    sta strcpy.dst
    lda #>file
    sta strcpy.dst+1
    // [1758] phi strcpy::src#0 = rom_file::source [phi:rom_file->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // rom_file::@1
    // 48+rom_chip
    // [1041] rom_file::$1 = $30 + rom_file::rom_chip#2 -- vbum1=vbuc1_plus_vbum1 
    lda #$30
    clc
    adc rom_file__1
    sta rom_file__1
    // file[3] = 48+rom_chip
    // [1042] *(rom_file::file+3) = rom_file::$1 -- _deref_pbuc1=vbum1 
    sta file+3
    // rom_file::@return
    // }
    // [1043] return 
    rts
  .segment Data
    file: .fill $c, 0
    source: .text "ROM .BIN"
    .byte 0
    .label rom_file__1 = main.check_vera2_main__0
    .label rom_chip = main.check_vera2_main__0
}
.segment Code
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(__zp($49) void (*putc)(char), __zp($61) char *str, __zp($d9) char format_min_length, __zp($e4) char format_justify_left)
printf_string: {
    .label printf_string__9 = $54
    .label len = $6d
    .label padding = $d9
    .label str = $61
    .label format_min_length = $d9
    .label format_justify_left = $e4
    .label putc = $49
    // if(format.min_length)
    // [1045] if(0==printf_string::format_min_length#16) goto printf_string::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b3
    // printf_string::@3
    // strlen(str)
    // [1046] strlen::str#3 = printf_string::str#16 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [1047] call strlen
    // [1982] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [1982] phi strlen::str#8 = strlen::str#3 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [1048] strlen::return#10 = strlen::len#2
    // printf_string::@6
    // [1049] printf_string::$9 = strlen::return#10
    // signed char len = (signed char)strlen(str)
    // [1050] printf_string::len#0 = (signed char)printf_string::$9 -- vbsz1=_sbyte_vwuz2 
    lda.z printf_string__9
    sta.z len
    // padding = (signed char)format.min_length  - len
    // [1051] printf_string::padding#1 = (signed char)printf_string::format_min_length#16 - printf_string::len#0 -- vbsz1=vbsz1_minus_vbsz2 
    lda.z padding
    sec
    sbc.z len
    sta.z padding
    // if(padding<0)
    // [1052] if(printf_string::padding#1>=0) goto printf_string::@10 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1054] phi from printf_string printf_string::@6 to printf_string::@1 [phi:printf_string/printf_string::@6->printf_string::@1]
  __b3:
    // [1054] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@6->printf_string::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [1053] phi from printf_string::@6 to printf_string::@10 [phi:printf_string::@6->printf_string::@10]
    // printf_string::@10
    // [1054] phi from printf_string::@10 to printf_string::@1 [phi:printf_string::@10->printf_string::@1]
    // [1054] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@10->printf_string::@1#0] -- register_copy 
    // printf_string::@1
  __b1:
    // if(!format.justify_left && padding)
    // [1055] if(0!=printf_string::format_justify_left#16) goto printf_string::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_justify_left
    bne __b2
    // printf_string::@8
    // [1056] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b4
    jmp __b2
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [1057] printf_padding::putc#3 = printf_string::putc#16 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1058] printf_padding::length#3 = (char)printf_string::padding#3 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1059] call printf_padding
    // [1988] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [1988] phi printf_padding::putc#7 = printf_padding::putc#3 [phi:printf_string::@4->printf_padding#0] -- register_copy 
    // [1988] phi printf_padding::pad#7 = ' ' [phi:printf_string::@4->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1988] phi printf_padding::length#6 = printf_padding::length#3 [phi:printf_string::@4->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [1060] printf_str::putc#1 = printf_string::putc#16 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_str.putc
    lda.z putc+1
    sta.z printf_str.putc+1
    // [1061] printf_str::s#2 = printf_string::str#16
    // [1062] call printf_str
    // [630] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [630] phi printf_str::putc#66 = printf_str::putc#1 [phi:printf_string::@2->printf_str#0] -- register_copy 
    // [630] phi printf_str::s#66 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@7
    // if(format.justify_left && padding)
    // [1063] if(0==printf_string::format_justify_left#16) goto printf_string::@return -- 0_eq_vbuz1_then_la1 
    lda.z format_justify_left
    beq __breturn
    // printf_string::@9
    // [1064] if(0!=printf_string::padding#3) goto printf_string::@5 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b5
    rts
    // printf_string::@5
  __b5:
    // printf_padding(putc, ' ',(char)padding)
    // [1065] printf_padding::putc#4 = printf_string::putc#16 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1066] printf_padding::length#4 = (char)printf_string::padding#3 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1067] call printf_padding
    // [1988] phi from printf_string::@5 to printf_padding [phi:printf_string::@5->printf_padding]
    // [1988] phi printf_padding::putc#7 = printf_padding::putc#4 [phi:printf_string::@5->printf_padding#0] -- register_copy 
    // [1988] phi printf_padding::pad#7 = ' ' [phi:printf_string::@5->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1988] phi printf_padding::length#6 = printf_padding::length#4 [phi:printf_string::@5->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@return
  __breturn:
    // }
    // [1068] return 
    rts
}
  // rom_read
// __mem() unsigned long rom_read(char rom_chip, char *file, __zp($e3) char brom_bank_start, __zp($ac) unsigned long rom_size)
rom_read: {
    .const bank_set_brom1_bank = 0
    .label rom_address = $73
    .label brom_bank_start = $e3
    .label ram_address = $c8
    .label rom_row_current = $7d
    .label bram_bank = $72
    .label rom_size = $ac
    // unsigned long rom_address = rom_address_from_bank(brom_bank_start)
    // [1070] rom_address_from_bank::rom_bank#0 = rom_read::brom_bank_start#21 -- vbuz1=vbuz2 
    lda.z brom_bank_start
    sta.z rom_address_from_bank.rom_bank
    // [1071] call rom_address_from_bank
    // [1996] phi from rom_read to rom_address_from_bank [phi:rom_read->rom_address_from_bank]
    // [1996] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#0 [phi:rom_read->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(brom_bank_start)
    // [1072] rom_address_from_bank::return#2 = rom_address_from_bank::return#0
    // rom_read::@15
    // [1073] rom_read::rom_address#0 = rom_address_from_bank::return#2
    // rom_read::bank_set_bram1
    // BRAM = bank
    // [1074] BRAM = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z BRAM
    // rom_read::bank_set_brom1
    // BROM = bank
    // [1075] BROM = rom_read::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [1076] phi from rom_read::bank_set_brom1 to rom_read::@13 [phi:rom_read::bank_set_brom1->rom_read::@13]
    // rom_read::@13
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1077] call snprintf_init
    jsr snprintf_init
    // [1078] phi from rom_read::@13 to rom_read::@16 [phi:rom_read::@13->rom_read::@16]
    // rom_read::@16
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1079] call printf_str
    // [630] phi from rom_read::@16 to printf_str [phi:rom_read::@16->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:rom_read::@16->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = rom_read::s [phi:rom_read::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // [1080] phi from rom_read::@16 to rom_read::@17 [phi:rom_read::@16->rom_read::@17]
    // rom_read::@17
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1081] call printf_string
    // [1044] phi from rom_read::@17 to printf_string [phi:rom_read::@17->printf_string]
    // [1044] phi printf_string::putc#16 = &snputc [phi:rom_read::@17->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1044] phi printf_string::str#16 = rom_file::file [phi:rom_read::@17->printf_string#1] -- pbuz1=pbuc1 
    lda #<rom_file.file
    sta.z printf_string.str
    lda #>rom_file.file
    sta.z printf_string.str+1
    // [1044] phi printf_string::format_justify_left#16 = 0 [phi:rom_read::@17->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1044] phi printf_string::format_min_length#16 = 0 [phi:rom_read::@17->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1082] phi from rom_read::@17 to rom_read::@18 [phi:rom_read::@17->rom_read::@18]
    // rom_read::@18
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1083] call printf_str
    // [630] phi from rom_read::@18 to printf_str [phi:rom_read::@18->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:rom_read::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = rom_read::s1 [phi:rom_read::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@19
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1084] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1085] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [1087] call info_line
    // [845] phi from rom_read::@19 to info_line [phi:rom_read::@19->info_line]
    // [845] phi info_line::info_text#18 = info_text [phi:rom_read::@19->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    // [1088] phi from rom_read::@19 to rom_read::@20 [phi:rom_read::@19->rom_read::@20]
    // rom_read::@20
    // FILE *fp = fopen(file, "r")
    // [1089] call fopen
    // [1786] phi from rom_read::@20 to fopen [phi:rom_read::@20->fopen]
    // [1786] phi __errno#301 = __errno#104 [phi:rom_read::@20->fopen#0] -- register_copy 
    // [1786] phi fopen::pathtoken#0 = rom_file::file [phi:rom_read::@20->fopen#1] -- pbuz1=pbuc1 
    lda #<rom_file.file
    sta.z fopen.pathtoken
    lda #>rom_file.file
    sta.z fopen.pathtoken+1
    jsr fopen
    // FILE *fp = fopen(file, "r")
    // [1090] fopen::return#4 = fopen::return#2
    // rom_read::@21
    // [1091] rom_read::fp#0 = fopen::return#4 -- pssm1=pssz2 
    lda.z fopen.return
    sta fp
    lda.z fopen.return+1
    sta fp+1
    // if (fp)
    // [1092] if((struct $2 *)0==rom_read::fp#0) goto rom_read::@1 -- pssc1_eq_pssm1_then_la1 
    lda fp
    cmp #<0
    bne !+
    lda fp+1
    cmp #>0
    beq __b2
  !:
    // [1093] phi from rom_read::@21 to rom_read::@2 [phi:rom_read::@21->rom_read::@2]
    // rom_read::@2
    // gotoxy(x, y)
    // [1094] call gotoxy
    // [486] phi from rom_read::@2 to gotoxy [phi:rom_read::@2->gotoxy]
    // [486] phi gotoxy::y#29 = PROGRESS_Y [phi:rom_read::@2->gotoxy#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z gotoxy.y
    // [486] phi gotoxy::x#29 = PROGRESS_X [phi:rom_read::@2->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [1095] phi from rom_read::@2 to rom_read::@3 [phi:rom_read::@2->rom_read::@3]
    // [1095] phi rom_read::y#11 = PROGRESS_Y [phi:rom_read::@2->rom_read::@3#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1095] phi rom_read::rom_row_current#10 = 0 [phi:rom_read::@2->rom_read::@3#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z rom_row_current
    sta.z rom_row_current+1
    // [1095] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#21 [phi:rom_read::@2->rom_read::@3#2] -- register_copy 
    // [1095] phi rom_read::rom_address#10 = rom_read::rom_address#0 [phi:rom_read::@2->rom_read::@3#3] -- register_copy 
    // [1095] phi rom_read::ram_address#10 = (char *)$6000 [phi:rom_read::@2->rom_read::@3#4] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z ram_address
    lda #>$6000
    sta.z ram_address+1
    // [1095] phi rom_read::bram_bank#10 = 0 [phi:rom_read::@2->rom_read::@3#5] -- vbuz1=vbuc1 
    lda #0
    sta.z bram_bank
    // [1095] phi rom_read::rom_file_read#11 = 0 [phi:rom_read::@2->rom_read::@3#6] -- vdum1=vduc1 
    sta rom_file_read
    sta rom_file_read+1
    lda #<0>>$10
    sta rom_file_read+2
    lda #>0>>$10
    sta rom_file_read+3
    // rom_read::@3
  __b3:
    // while (rom_file_read < rom_size)
    // [1096] if(rom_read::rom_file_read#11<rom_read::rom_size#12) goto rom_read::@4 -- vdum1_lt_vduz2_then_la1 
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
    // [1097] fclose::stream#1 = rom_read::fp#0 -- pssz1=pssm2 
    lda fp
    sta.z fclose.stream
    lda fp+1
    sta.z fclose.stream+1
    // [1098] call fclose
    // [1921] phi from rom_read::@7 to fclose [phi:rom_read::@7->fclose]
    // [1921] phi fclose::stream#2 = fclose::stream#1 [phi:rom_read::@7->fclose#0] -- register_copy 
    jsr fclose
    // [1099] phi from rom_read::@7 to rom_read::@1 [phi:rom_read::@7->rom_read::@1]
    // [1099] phi rom_read::return#0 = rom_read::rom_file_read#11 [phi:rom_read::@7->rom_read::@1#0] -- register_copy 
    rts
    // [1099] phi from rom_read::@21 to rom_read::@1 [phi:rom_read::@21->rom_read::@1]
  __b2:
    // [1099] phi rom_read::return#0 = 0 [phi:rom_read::@21->rom_read::@1#0] -- vdum1=vduc1 
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
    // [1100] return 
    rts
    // [1101] phi from rom_read::@3 to rom_read::@4 [phi:rom_read::@3->rom_read::@4]
    // rom_read::@4
  __b4:
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_read, rom_size, bram_bank, ram_address)
    // [1102] call snprintf_init
    jsr snprintf_init
    // [1103] phi from rom_read::@4 to rom_read::@22 [phi:rom_read::@4->rom_read::@22]
    // rom_read::@22
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_read, rom_size, bram_bank, ram_address)
    // [1104] call printf_str
    // [630] phi from rom_read::@22 to printf_str [phi:rom_read::@22->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:rom_read::@22->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = s10 [phi:rom_read::@22->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // [1105] phi from rom_read::@22 to rom_read::@23 [phi:rom_read::@22->rom_read::@23]
    // rom_read::@23
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_read, rom_size, bram_bank, ram_address)
    // [1106] call printf_string
    // [1044] phi from rom_read::@23 to printf_string [phi:rom_read::@23->printf_string]
    // [1044] phi printf_string::putc#16 = &snputc [phi:rom_read::@23->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1044] phi printf_string::str#16 = rom_file::file [phi:rom_read::@23->printf_string#1] -- pbuz1=pbuc1 
    lda #<rom_file.file
    sta.z printf_string.str
    lda #>rom_file.file
    sta.z printf_string.str+1
    // [1044] phi printf_string::format_justify_left#16 = 0 [phi:rom_read::@23->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1044] phi printf_string::format_min_length#16 = 0 [phi:rom_read::@23->printf_string#3] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1107] phi from rom_read::@23 to rom_read::@24 [phi:rom_read::@23->rom_read::@24]
    // rom_read::@24
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_read, rom_size, bram_bank, ram_address)
    // [1108] call printf_str
    // [630] phi from rom_read::@24 to printf_str [phi:rom_read::@24->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:rom_read::@24->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = s3 [phi:rom_read::@24->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@25
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_read, rom_size, bram_bank, ram_address)
    // [1109] printf_ulong::uvalue#2 = rom_read::rom_file_read#11 -- vduz1=vdum2 
    lda rom_file_read
    sta.z printf_ulong.uvalue
    lda rom_file_read+1
    sta.z printf_ulong.uvalue+1
    lda rom_file_read+2
    sta.z printf_ulong.uvalue+2
    lda rom_file_read+3
    sta.z printf_ulong.uvalue+3
    // [1110] call printf_ulong
    // [1255] phi from rom_read::@25 to printf_ulong [phi:rom_read::@25->printf_ulong]
    // [1255] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_read::@25->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1255] phi printf_ulong::format_min_length#11 = 5 [phi:rom_read::@25->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1255] phi printf_ulong::putc#11 = &snputc [phi:rom_read::@25->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1255] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_read::@25->printf_ulong#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1255] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#2 [phi:rom_read::@25->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1111] phi from rom_read::@25 to rom_read::@26 [phi:rom_read::@25->rom_read::@26]
    // rom_read::@26
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_read, rom_size, bram_bank, ram_address)
    // [1112] call printf_str
    // [630] phi from rom_read::@26 to printf_str [phi:rom_read::@26->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:rom_read::@26->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = s1 [phi:rom_read::@26->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s1
    sta.z printf_str.s
    lda #>@s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@27
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_read, rom_size, bram_bank, ram_address)
    // [1113] printf_ulong::uvalue#3 = rom_read::rom_size#12 -- vduz1=vduz2 
    lda.z rom_size
    sta.z printf_ulong.uvalue
    lda.z rom_size+1
    sta.z printf_ulong.uvalue+1
    lda.z rom_size+2
    sta.z printf_ulong.uvalue+2
    lda.z rom_size+3
    sta.z printf_ulong.uvalue+3
    // [1114] call printf_ulong
    // [1255] phi from rom_read::@27 to printf_ulong [phi:rom_read::@27->printf_ulong]
    // [1255] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_read::@27->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1255] phi printf_ulong::format_min_length#11 = 5 [phi:rom_read::@27->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1255] phi printf_ulong::putc#11 = &snputc [phi:rom_read::@27->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1255] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_read::@27->printf_ulong#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1255] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#3 [phi:rom_read::@27->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1115] phi from rom_read::@27 to rom_read::@28 [phi:rom_read::@27->rom_read::@28]
    // rom_read::@28
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_read, rom_size, bram_bank, ram_address)
    // [1116] call printf_str
    // [630] phi from rom_read::@28 to printf_str [phi:rom_read::@28->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:rom_read::@28->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = s2 [phi:rom_read::@28->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@29
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_read, rom_size, bram_bank, ram_address)
    // [1117] printf_uchar::uvalue#5 = rom_read::bram_bank#10 -- vbuz1=vbuz2 
    lda.z bram_bank
    sta.z printf_uchar.uvalue
    // [1118] call printf_uchar
    // [1028] phi from rom_read::@29 to printf_uchar [phi:rom_read::@29->printf_uchar]
    // [1028] phi printf_uchar::format_zero_padding#10 = 1 [phi:rom_read::@29->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1028] phi printf_uchar::format_min_length#10 = 2 [phi:rom_read::@29->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [1028] phi printf_uchar::putc#10 = &snputc [phi:rom_read::@29->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1028] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:rom_read::@29->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [1028] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#5 [phi:rom_read::@29->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1119] phi from rom_read::@29 to rom_read::@30 [phi:rom_read::@29->rom_read::@30]
    // rom_read::@30
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_read, rom_size, bram_bank, ram_address)
    // [1120] call printf_str
    // [630] phi from rom_read::@30 to printf_str [phi:rom_read::@30->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:rom_read::@30->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = s3 [phi:rom_read::@30->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@31
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_read, rom_size, bram_bank, ram_address)
    // [1121] printf_uint::uvalue#10 = (unsigned int)rom_read::ram_address#10 -- vwuz1=vwuz2 
    lda.z ram_address
    sta.z printf_uint.uvalue
    lda.z ram_address+1
    sta.z printf_uint.uvalue+1
    // [1122] call printf_uint
    // [639] phi from rom_read::@31 to printf_uint [phi:rom_read::@31->printf_uint]
    // [639] phi printf_uint::format_zero_padding#16 = 1 [phi:rom_read::@31->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [639] phi printf_uint::format_min_length#16 = 4 [phi:rom_read::@31->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [639] phi printf_uint::putc#16 = &snputc [phi:rom_read::@31->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [639] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:rom_read::@31->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [639] phi printf_uint::uvalue#16 = printf_uint::uvalue#10 [phi:rom_read::@31->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1123] phi from rom_read::@31 to rom_read::@32 [phi:rom_read::@31->rom_read::@32]
    // rom_read::@32
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_read, rom_size, bram_bank, ram_address)
    // [1124] call printf_str
    // [630] phi from rom_read::@32 to printf_str [phi:rom_read::@32->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:rom_read::@32->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = s4 [phi:rom_read::@32->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@33
    // sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_read, rom_size, bram_bank, ram_address)
    // [1125] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1126] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [1128] call info_line
    // [845] phi from rom_read::@33 to info_line [phi:rom_read::@33->info_line]
    // [845] phi info_line::info_text#18 = info_text [phi:rom_read::@33->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    // rom_read::@34
    // rom_address % 0x04000
    // [1129] rom_read::$11 = rom_read::rom_address#10 & $4000-1 -- vdum1=vduz2_band_vduc1 
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
    // [1130] if(0!=rom_read::$11) goto rom_read::@5 -- 0_neq_vdum1_then_la1 
    lda rom_read__11
    ora rom_read__11+1
    ora rom_read__11+2
    ora rom_read__11+3
    bne __b5
    // rom_read::@10
    // brom_bank_start++;
    // [1131] rom_read::brom_bank_start#0 = ++ rom_read::brom_bank_start#10 -- vbuz1=_inc_vbuz1 
    inc.z brom_bank_start
    // [1132] phi from rom_read::@10 rom_read::@34 to rom_read::@5 [phi:rom_read::@10/rom_read::@34->rom_read::@5]
    // [1132] phi rom_read::brom_bank_start#20 = rom_read::brom_bank_start#0 [phi:rom_read::@10/rom_read::@34->rom_read::@5#0] -- register_copy 
    // rom_read::@5
  __b5:
    // rom_read::bank_set_bram2
    // BRAM = bank
    // [1133] BRAM = rom_read::bram_bank#10 -- vbuz1=vbuz2 
    lda.z bram_bank
    sta.z BRAM
    // rom_read::@14
    // unsigned int rom_package_read = fgets(ram_address, PROGRESS_CELL, fp)
    // [1134] fgets::ptr#3 = rom_read::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z fgets.ptr
    lda.z ram_address+1
    sta.z fgets.ptr+1
    // [1135] fgets::stream#1 = rom_read::fp#0 -- pssm1=pssm2 
    lda fp
    sta fgets.stream
    lda fp+1
    sta fgets.stream+1
    // [1136] call fgets
    // [1867] phi from rom_read::@14 to fgets [phi:rom_read::@14->fgets]
    // [1867] phi fgets::ptr#12 = fgets::ptr#3 [phi:rom_read::@14->fgets#0] -- register_copy 
    // [1867] phi fgets::size#10 = PROGRESS_CELL [phi:rom_read::@14->fgets#1] -- vwuz1=vwuc1 
    lda #<PROGRESS_CELL
    sta.z fgets.size
    lda #>PROGRESS_CELL
    sta.z fgets.size+1
    // [1867] phi fgets::stream#2 = fgets::stream#1 [phi:rom_read::@14->fgets#2] -- register_copy 
    jsr fgets
    // unsigned int rom_package_read = fgets(ram_address, PROGRESS_CELL, fp)
    // [1137] fgets::return#6 = fgets::return#1
    // rom_read::@35
    // [1138] rom_read::rom_package_read#0 = fgets::return#6 -- vwum1=vwuz2 
    lda.z fgets.return
    sta rom_package_read
    lda.z fgets.return+1
    sta rom_package_read+1
    // if (!rom_package_read)
    // [1139] if(0!=rom_read::rom_package_read#0) goto rom_read::@6 -- 0_neq_vwum1_then_la1 
    lda rom_package_read
    ora rom_package_read+1
    bne __b6
    jmp __b7
    // rom_read::@6
  __b6:
    // if (rom_row_current == PROGRESS_ROW)
    // [1140] if(rom_read::rom_row_current#10!=PROGRESS_ROW) goto rom_read::@8 -- vwuz1_neq_vwuc1_then_la1 
    lda.z rom_row_current+1
    cmp #>PROGRESS_ROW
    bne __b8
    lda.z rom_row_current
    cmp #<PROGRESS_ROW
    bne __b8
    // rom_read::@11
    // gotoxy(x, ++y);
    // [1141] rom_read::y#1 = ++ rom_read::y#11 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1142] gotoxy::y#24 = rom_read::y#1 -- vbuz1=vbum2 
    lda y
    sta.z gotoxy.y
    // [1143] call gotoxy
    // [486] phi from rom_read::@11 to gotoxy [phi:rom_read::@11->gotoxy]
    // [486] phi gotoxy::y#29 = gotoxy::y#24 [phi:rom_read::@11->gotoxy#0] -- register_copy 
    // [486] phi gotoxy::x#29 = PROGRESS_X [phi:rom_read::@11->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [1144] phi from rom_read::@11 to rom_read::@8 [phi:rom_read::@11->rom_read::@8]
    // [1144] phi rom_read::y#36 = rom_read::y#1 [phi:rom_read::@11->rom_read::@8#0] -- register_copy 
    // [1144] phi rom_read::rom_row_current#4 = 0 [phi:rom_read::@11->rom_read::@8#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z rom_row_current
    sta.z rom_row_current+1
    // [1144] phi from rom_read::@6 to rom_read::@8 [phi:rom_read::@6->rom_read::@8]
    // [1144] phi rom_read::y#36 = rom_read::y#11 [phi:rom_read::@6->rom_read::@8#0] -- register_copy 
    // [1144] phi rom_read::rom_row_current#4 = rom_read::rom_row_current#10 [phi:rom_read::@6->rom_read::@8#1] -- register_copy 
    // rom_read::@8
  __b8:
    // cputc('.')
    // [1145] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [1146] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // ram_address += rom_package_read
    // [1148] rom_read::ram_address#1 = rom_read::ram_address#10 + rom_read::rom_package_read#0 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z ram_address
    adc rom_package_read
    sta.z ram_address
    lda.z ram_address+1
    adc rom_package_read+1
    sta.z ram_address+1
    // rom_address += rom_package_read
    // [1149] rom_read::rom_address#1 = rom_read::rom_address#10 + rom_read::rom_package_read#0 -- vduz1=vduz1_plus_vwum2 
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
    // [1150] rom_read::rom_file_read#1 = rom_read::rom_file_read#11 + rom_read::rom_package_read#0 -- vdum1=vdum1_plus_vwum2 
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
    // [1151] rom_read::rom_row_current#1 = rom_read::rom_row_current#4 + rom_read::rom_package_read#0 -- vwuz1=vwuz1_plus_vwum2 
    clc
    lda.z rom_row_current
    adc rom_package_read
    sta.z rom_row_current
    lda.z rom_row_current+1
    adc rom_package_read+1
    sta.z rom_row_current+1
    // if (ram_address == (ram_ptr_t)BRAM_HIGH)
    // [1152] if(rom_read::ram_address#1!=(char *)$c000) goto rom_read::@9 -- pbuz1_neq_pbuc1_then_la1 
    lda.z ram_address+1
    cmp #>$c000
    bne __b9
    lda.z ram_address
    cmp #<$c000
    bne __b9
    // rom_read::@12
    // bram_bank++;
    // [1153] rom_read::bram_bank#1 = ++ rom_read::bram_bank#10 -- vbuz1=_inc_vbuz1 
    inc.z bram_bank
    // [1154] phi from rom_read::@12 to rom_read::@9 [phi:rom_read::@12->rom_read::@9]
    // [1154] phi rom_read::bram_bank#30 = rom_read::bram_bank#1 [phi:rom_read::@12->rom_read::@9#0] -- register_copy 
    // [1154] phi rom_read::ram_address#7 = (char *)$a000 [phi:rom_read::@12->rom_read::@9#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1154] phi from rom_read::@8 to rom_read::@9 [phi:rom_read::@8->rom_read::@9]
    // [1154] phi rom_read::bram_bank#30 = rom_read::bram_bank#10 [phi:rom_read::@8->rom_read::@9#0] -- register_copy 
    // [1154] phi rom_read::ram_address#7 = rom_read::ram_address#1 [phi:rom_read::@8->rom_read::@9#1] -- register_copy 
    // rom_read::@9
  __b9:
    // if (ram_address == (ram_ptr_t)RAM_HIGH)
    // [1155] if(rom_read::ram_address#7!=(char *)$8000) goto rom_read::@36 -- pbuz1_neq_pbuc1_then_la1 
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
    // [1095] phi from rom_read::@9 to rom_read::@3 [phi:rom_read::@9->rom_read::@3]
    // [1095] phi rom_read::y#11 = rom_read::y#36 [phi:rom_read::@9->rom_read::@3#0] -- register_copy 
    // [1095] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#1 [phi:rom_read::@9->rom_read::@3#1] -- register_copy 
    // [1095] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#20 [phi:rom_read::@9->rom_read::@3#2] -- register_copy 
    // [1095] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@9->rom_read::@3#3] -- register_copy 
    // [1095] phi rom_read::ram_address#10 = (char *)$a000 [phi:rom_read::@9->rom_read::@3#4] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1095] phi rom_read::bram_bank#10 = 1 [phi:rom_read::@9->rom_read::@3#5] -- vbuz1=vbuc1 
    lda #1
    sta.z bram_bank
    // [1095] phi rom_read::rom_file_read#11 = rom_read::rom_file_read#1 [phi:rom_read::@9->rom_read::@3#6] -- register_copy 
    jmp __b3
    // [1156] phi from rom_read::@9 to rom_read::@36 [phi:rom_read::@9->rom_read::@36]
    // rom_read::@36
    // [1095] phi from rom_read::@36 to rom_read::@3 [phi:rom_read::@36->rom_read::@3]
    // [1095] phi rom_read::y#11 = rom_read::y#36 [phi:rom_read::@36->rom_read::@3#0] -- register_copy 
    // [1095] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#1 [phi:rom_read::@36->rom_read::@3#1] -- register_copy 
    // [1095] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#20 [phi:rom_read::@36->rom_read::@3#2] -- register_copy 
    // [1095] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@36->rom_read::@3#3] -- register_copy 
    // [1095] phi rom_read::ram_address#10 = rom_read::ram_address#7 [phi:rom_read::@36->rom_read::@3#4] -- register_copy 
    // [1095] phi rom_read::bram_bank#10 = rom_read::bram_bank#30 [phi:rom_read::@36->rom_read::@3#5] -- register_copy 
    // [1095] phi rom_read::rom_file_read#11 = rom_read::rom_file_read#1 [phi:rom_read::@36->rom_read::@3#6] -- register_copy 
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
// void info_rom(__zp($5a) char rom_chip, __zp($b4) char info_status, __zp($b8) char *info_text)
info_rom: {
    .label info_rom__7 = $b4
    .label info_rom__8 = $e0
    .label info_rom__10 = $6d
    .label rom_chip = $5a
    .label info_status = $b4
    .label info_text = $b8
    // status_rom[rom_chip] = info_status
    // [1158] status_rom[info_rom::rom_chip#17] = info_rom::info_status#17 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z info_status
    ldy.z rom_chip
    sta status_rom,y
    // print_rom_led(rom_chip, status_color[info_status])
    // [1159] print_rom_led::chip#1 = info_rom::rom_chip#17 -- vbuz1=vbuz2 
    tya
    sta.z print_rom_led.chip
    // [1160] print_rom_led::c#1 = status_color[info_rom::info_status#17] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z print_rom_led.c
    // [1161] call print_rom_led
    // [1778] phi from info_rom to print_rom_led [phi:info_rom->print_rom_led]
    // [1778] phi print_rom_led::c#2 = print_rom_led::c#1 [phi:info_rom->print_rom_led#0] -- register_copy 
    // [1778] phi print_rom_led::chip#2 = print_rom_led::chip#1 [phi:info_rom->print_rom_led#1] -- register_copy 
    jsr print_rom_led
    // info_rom::@2
    // gotoxy(INFO_X, INFO_Y+rom_chip+2)
    // [1162] gotoxy::y#17 = info_rom::rom_chip#17 + $11+2 -- vbuz1=vbuz2_plus_vbuc1 
    lda #$11+2
    clc
    adc.z rom_chip
    sta.z gotoxy.y
    // [1163] call gotoxy
    // [486] phi from info_rom::@2 to gotoxy [phi:info_rom::@2->gotoxy]
    // [486] phi gotoxy::y#29 = gotoxy::y#17 [phi:info_rom::@2->gotoxy#0] -- register_copy 
    // [486] phi gotoxy::x#29 = 2 [phi:info_rom::@2->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // [1164] phi from info_rom::@2 to info_rom::@3 [phi:info_rom::@2->info_rom::@3]
    // info_rom::@3
    // printf("ROM%u - %-9s - %-6s - %05x / %05x - ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1165] call printf_str
    // [630] phi from info_rom::@3 to printf_str [phi:info_rom::@3->printf_str]
    // [630] phi printf_str::putc#66 = &cputc [phi:info_rom::@3->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = info_rom::s [phi:info_rom::@3->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@4
    // printf("ROM%u - %-9s - %-6s - %05x / %05x - ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1166] printf_uchar::uvalue#0 = info_rom::rom_chip#17 -- vbuz1=vbuz2 
    lda.z rom_chip
    sta.z printf_uchar.uvalue
    // [1167] call printf_uchar
    // [1028] phi from info_rom::@4 to printf_uchar [phi:info_rom::@4->printf_uchar]
    // [1028] phi printf_uchar::format_zero_padding#10 = 0 [phi:info_rom::@4->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1028] phi printf_uchar::format_min_length#10 = 0 [phi:info_rom::@4->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1028] phi printf_uchar::putc#10 = &cputc [phi:info_rom::@4->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1028] phi printf_uchar::format_radix#10 = DECIMAL [phi:info_rom::@4->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1028] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#0 [phi:info_rom::@4->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1168] phi from info_rom::@4 to info_rom::@5 [phi:info_rom::@4->info_rom::@5]
    // info_rom::@5
    // printf("ROM%u - %-9s - %-6s - %05x / %05x - ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1169] call printf_str
    // [630] phi from info_rom::@5 to printf_str [phi:info_rom::@5->printf_str]
    // [630] phi printf_str::putc#66 = &cputc [phi:info_rom::@5->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = info_rom::s1 [phi:info_rom::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@6
    // printf("ROM%u - %-9s - %-6s - %05x / %05x - ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1170] info_rom::$7 = info_rom::info_status#17 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z info_rom__7
    // [1171] printf_string::str#7 = status_text[info_rom::$7] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z info_rom__7
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [1172] call printf_string
    // [1044] phi from info_rom::@6 to printf_string [phi:info_rom::@6->printf_string]
    // [1044] phi printf_string::putc#16 = &cputc [phi:info_rom::@6->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1044] phi printf_string::str#16 = printf_string::str#7 [phi:info_rom::@6->printf_string#1] -- register_copy 
    // [1044] phi printf_string::format_justify_left#16 = 1 [phi:info_rom::@6->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1044] phi printf_string::format_min_length#16 = 9 [phi:info_rom::@6->printf_string#3] -- vbuz1=vbuc1 
    lda #9
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1173] phi from info_rom::@6 to info_rom::@7 [phi:info_rom::@6->info_rom::@7]
    // info_rom::@7
    // printf("ROM%u - %-9s - %-6s - %05x / %05x - ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1174] call printf_str
    // [630] phi from info_rom::@7 to printf_str [phi:info_rom::@7->printf_str]
    // [630] phi printf_str::putc#66 = &cputc [phi:info_rom::@7->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = info_rom::s1 [phi:info_rom::@7->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@8
    // printf("ROM%u - %-9s - %-6s - %05x / %05x - ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1175] info_rom::$8 = info_rom::rom_chip#17 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta.z info_rom__8
    // [1176] printf_string::str#8 = rom_device_names[info_rom::$8] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda rom_device_names,y
    sta.z printf_string.str
    lda rom_device_names+1,y
    sta.z printf_string.str+1
    // [1177] call printf_string
    // [1044] phi from info_rom::@8 to printf_string [phi:info_rom::@8->printf_string]
    // [1044] phi printf_string::putc#16 = &cputc [phi:info_rom::@8->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1044] phi printf_string::str#16 = printf_string::str#8 [phi:info_rom::@8->printf_string#1] -- register_copy 
    // [1044] phi printf_string::format_justify_left#16 = 1 [phi:info_rom::@8->printf_string#2] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1044] phi printf_string::format_min_length#16 = 6 [phi:info_rom::@8->printf_string#3] -- vbuz1=vbuc1 
    lda #6
    sta.z printf_string.format_min_length
    jsr printf_string
    // [1178] phi from info_rom::@8 to info_rom::@9 [phi:info_rom::@8->info_rom::@9]
    // info_rom::@9
    // printf("ROM%u - %-9s - %-6s - %05x / %05x - ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1179] call printf_str
    // [630] phi from info_rom::@9 to printf_str [phi:info_rom::@9->printf_str]
    // [630] phi printf_str::putc#66 = &cputc [phi:info_rom::@9->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = info_rom::s1 [phi:info_rom::@9->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@10
    // printf("ROM%u - %-9s - %-6s - %05x / %05x - ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1180] info_rom::$10 = info_rom::rom_chip#17 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta.z info_rom__10
    // [1181] printf_ulong::uvalue#0 = file_sizes[info_rom::$10] -- vduz1=pduc1_derefidx_vbuz2 
    tay
    lda file_sizes,y
    sta.z printf_ulong.uvalue
    lda file_sizes+1,y
    sta.z printf_ulong.uvalue+1
    lda file_sizes+2,y
    sta.z printf_ulong.uvalue+2
    lda file_sizes+3,y
    sta.z printf_ulong.uvalue+3
    // [1182] call printf_ulong
    // [1255] phi from info_rom::@10 to printf_ulong [phi:info_rom::@10->printf_ulong]
    // [1255] phi printf_ulong::format_zero_padding#11 = 1 [phi:info_rom::@10->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1255] phi printf_ulong::format_min_length#11 = 5 [phi:info_rom::@10->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1255] phi printf_ulong::putc#11 = &cputc [phi:info_rom::@10->printf_ulong#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_ulong.putc
    lda #>cputc
    sta.z printf_ulong.putc+1
    // [1255] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:info_rom::@10->printf_ulong#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1255] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#0 [phi:info_rom::@10->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1183] phi from info_rom::@10 to info_rom::@11 [phi:info_rom::@10->info_rom::@11]
    // info_rom::@11
    // printf("ROM%u - %-9s - %-6s - %05x / %05x - ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1184] call printf_str
    // [630] phi from info_rom::@11 to printf_str [phi:info_rom::@11->printf_str]
    // [630] phi printf_str::putc#66 = &cputc [phi:info_rom::@11->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = info_rom::s4 [phi:info_rom::@11->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@12
    // printf("ROM%u - %-9s - %-6s - %05x / %05x - ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1185] printf_ulong::uvalue#1 = rom_sizes[info_rom::$10] -- vduz1=pduc1_derefidx_vbuz2 
    ldy.z info_rom__10
    lda rom_sizes,y
    sta.z printf_ulong.uvalue
    lda rom_sizes+1,y
    sta.z printf_ulong.uvalue+1
    lda rom_sizes+2,y
    sta.z printf_ulong.uvalue+2
    lda rom_sizes+3,y
    sta.z printf_ulong.uvalue+3
    // [1186] call printf_ulong
    // [1255] phi from info_rom::@12 to printf_ulong [phi:info_rom::@12->printf_ulong]
    // [1255] phi printf_ulong::format_zero_padding#11 = 1 [phi:info_rom::@12->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1255] phi printf_ulong::format_min_length#11 = 5 [phi:info_rom::@12->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1255] phi printf_ulong::putc#11 = &cputc [phi:info_rom::@12->printf_ulong#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_ulong.putc
    lda #>cputc
    sta.z printf_ulong.putc+1
    // [1255] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:info_rom::@12->printf_ulong#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1255] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#1 [phi:info_rom::@12->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1187] phi from info_rom::@12 to info_rom::@13 [phi:info_rom::@12->info_rom::@13]
    // info_rom::@13
    // printf("ROM%u - %-9s - %-6s - %05x / %05x - ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [1188] call printf_str
    // [630] phi from info_rom::@13 to printf_str [phi:info_rom::@13->printf_str]
    // [630] phi printf_str::putc#66 = &cputc [phi:info_rom::@13->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = info_rom::s1 [phi:info_rom::@13->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@14
    // if(info_text)
    // [1189] if((char *)0==info_rom::info_text#17) goto info_rom::@return -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __breturn
  !:
    // info_rom::@1
    // printf("%20s", info_text)
    // [1190] printf_string::str#9 = info_rom::info_text#17 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1191] call printf_string
    // [1044] phi from info_rom::@1 to printf_string [phi:info_rom::@1->printf_string]
    // [1044] phi printf_string::putc#16 = &cputc [phi:info_rom::@1->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1044] phi printf_string::str#16 = printf_string::str#9 [phi:info_rom::@1->printf_string#1] -- register_copy 
    // [1044] phi printf_string::format_justify_left#16 = 0 [phi:info_rom::@1->printf_string#2] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1044] phi printf_string::format_min_length#16 = $14 [phi:info_rom::@1->printf_string#3] -- vbuz1=vbuc1 
    lda #$14
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_rom::@return
  __breturn:
    // }
    // [1192] return 
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
// __zp($79) unsigned long rom_verify(__zp($5a) char rom_chip, __zp($cc) char rom_bank_start, __zp($56) unsigned long file_size)
rom_verify: {
    .label rom_verify__16 = $4d
    .label rom_address = $bd
    .label rom_boundary = $56
    .label equal_bytes = $4d
    .label y = $51
    .label ram_address = $c5
    .label bram_bank = $5d
    .label rom_different_bytes = $79
    .label rom_chip = $5a
    .label rom_bank_start = $cc
    .label file_size = $56
    .label return = $79
    .label progress_row_current = $77
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [1193] rom_address_from_bank::rom_bank#1 = rom_verify::rom_bank_start#0
    // [1194] call rom_address_from_bank
    // [1996] phi from rom_verify to rom_address_from_bank [phi:rom_verify->rom_address_from_bank]
    // [1996] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#1 [phi:rom_verify->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [1195] rom_address_from_bank::return#3 = rom_address_from_bank::return#0 -- vduz1=vduz2 
    lda.z rom_address_from_bank.return
    sta.z rom_address_from_bank.return_1
    lda.z rom_address_from_bank.return+1
    sta.z rom_address_from_bank.return_1+1
    lda.z rom_address_from_bank.return+2
    sta.z rom_address_from_bank.return_1+2
    lda.z rom_address_from_bank.return+3
    sta.z rom_address_from_bank.return_1+3
    // rom_verify::@11
    // [1196] rom_verify::rom_address#0 = rom_address_from_bank::return#3
    // unsigned long rom_boundary = rom_address + file_size
    // [1197] rom_verify::rom_boundary#0 = rom_verify::rom_address#0 + rom_verify::file_size#0 -- vduz1=vduz2_plus_vduz1 
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
    // [1198] info_rom::rom_chip#1 = rom_verify::rom_chip#0
    // [1199] call info_rom
    // [1157] phi from rom_verify::@11 to info_rom [phi:rom_verify::@11->info_rom]
    // [1157] phi info_rom::info_text#17 = rom_verify::info_text [phi:rom_verify::@11->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_rom.info_text
    lda #>info_text
    sta.z info_rom.info_text+1
    // [1157] phi info_rom::rom_chip#17 = info_rom::rom_chip#1 [phi:rom_verify::@11->info_rom#1] -- register_copy 
    // [1157] phi info_rom::info_status#17 = STATUS_COMPARING [phi:rom_verify::@11->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_COMPARING
    sta.z info_rom.info_status
    jsr info_rom
    // [1200] phi from rom_verify::@11 to rom_verify::@12 [phi:rom_verify::@11->rom_verify::@12]
    // rom_verify::@12
    // gotoxy(x, y)
    // [1201] call gotoxy
    // [486] phi from rom_verify::@12 to gotoxy [phi:rom_verify::@12->gotoxy]
    // [486] phi gotoxy::y#29 = PROGRESS_Y [phi:rom_verify::@12->gotoxy#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z gotoxy.y
    // [486] phi gotoxy::x#29 = PROGRESS_X [phi:rom_verify::@12->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [1202] phi from rom_verify::@12 to rom_verify::@1 [phi:rom_verify::@12->rom_verify::@1]
    // [1202] phi rom_verify::y#3 = PROGRESS_Y [phi:rom_verify::@12->rom_verify::@1#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // [1202] phi rom_verify::progress_row_current#3 = 0 [phi:rom_verify::@12->rom_verify::@1#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z progress_row_current
    sta.z progress_row_current+1
    // [1202] phi rom_verify::rom_different_bytes#11 = 0 [phi:rom_verify::@12->rom_verify::@1#2] -- vduz1=vduc1 
    sta.z rom_different_bytes
    sta.z rom_different_bytes+1
    lda #<0>>$10
    sta.z rom_different_bytes+2
    lda #>0>>$10
    sta.z rom_different_bytes+3
    // [1202] phi rom_verify::ram_address#10 = (char *)$6000 [phi:rom_verify::@12->rom_verify::@1#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z ram_address
    lda #>$6000
    sta.z ram_address+1
    // [1202] phi rom_verify::bram_bank#11 = 0 [phi:rom_verify::@12->rom_verify::@1#4] -- vbuz1=vbuc1 
    lda #0
    sta.z bram_bank
    // [1202] phi rom_verify::rom_address#12 = rom_verify::rom_address#0 [phi:rom_verify::@12->rom_verify::@1#5] -- register_copy 
    // rom_verify::@1
  __b1:
    // while (rom_address < rom_boundary)
    // [1203] if(rom_verify::rom_address#12<rom_verify::rom_boundary#0) goto rom_verify::@2 -- vduz1_lt_vduz2_then_la1 
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
    // [1204] return 
    rts
    // rom_verify::@2
  __b2:
    // unsigned int equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1205] rom_compare::bank_ram#0 = rom_verify::bram_bank#11 -- vbuz1=vbuz2 
    lda.z bram_bank
    sta.z rom_compare.bank_ram
    // [1206] rom_compare::ptr_ram#1 = rom_verify::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_compare.ptr_ram
    lda.z ram_address+1
    sta.z rom_compare.ptr_ram+1
    // [1207] rom_compare::rom_compare_address#0 = rom_verify::rom_address#12 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_compare.rom_compare_address
    lda.z rom_address+1
    sta.z rom_compare.rom_compare_address+1
    lda.z rom_address+2
    sta.z rom_compare.rom_compare_address+2
    lda.z rom_address+3
    sta.z rom_compare.rom_compare_address+3
    // [1208] call rom_compare
  // {asm{.byte $db}}
    // [2000] phi from rom_verify::@2 to rom_compare [phi:rom_verify::@2->rom_compare]
    // [2000] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#1 [phi:rom_verify::@2->rom_compare#0] -- register_copy 
    // [2000] phi rom_compare::rom_compare_size#11 = PROGRESS_CELL [phi:rom_verify::@2->rom_compare#1] -- vwuz1=vwuc1 
    lda #<PROGRESS_CELL
    sta.z rom_compare.rom_compare_size
    lda #>PROGRESS_CELL
    sta.z rom_compare.rom_compare_size+1
    // [2000] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#0 [phi:rom_verify::@2->rom_compare#2] -- register_copy 
    // [2000] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#0 [phi:rom_verify::@2->rom_compare#3] -- register_copy 
    jsr rom_compare
    // unsigned int equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1209] rom_compare::return#2 = rom_compare::equal_bytes#2
    // rom_verify::@13
    // [1210] rom_verify::equal_bytes#0 = rom_compare::return#2
    // if (progress_row_current == PROGRESS_ROW)
    // [1211] if(rom_verify::progress_row_current#3!=PROGRESS_ROW) goto rom_verify::@3 -- vwuz1_neq_vwuc1_then_la1 
    lda.z progress_row_current+1
    cmp #>PROGRESS_ROW
    bne __b3
    lda.z progress_row_current
    cmp #<PROGRESS_ROW
    bne __b3
    // rom_verify::@8
    // gotoxy(x, ++y);
    // [1212] rom_verify::y#1 = ++ rom_verify::y#3 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [1213] gotoxy::y#26 = rom_verify::y#1 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1214] call gotoxy
    // [486] phi from rom_verify::@8 to gotoxy [phi:rom_verify::@8->gotoxy]
    // [486] phi gotoxy::y#29 = gotoxy::y#26 [phi:rom_verify::@8->gotoxy#0] -- register_copy 
    // [486] phi gotoxy::x#29 = PROGRESS_X [phi:rom_verify::@8->gotoxy#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z gotoxy.x
    jsr gotoxy
    // [1215] phi from rom_verify::@8 to rom_verify::@3 [phi:rom_verify::@8->rom_verify::@3]
    // [1215] phi rom_verify::y#10 = rom_verify::y#1 [phi:rom_verify::@8->rom_verify::@3#0] -- register_copy 
    // [1215] phi rom_verify::progress_row_current#4 = 0 [phi:rom_verify::@8->rom_verify::@3#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z progress_row_current
    sta.z progress_row_current+1
    // [1215] phi from rom_verify::@13 to rom_verify::@3 [phi:rom_verify::@13->rom_verify::@3]
    // [1215] phi rom_verify::y#10 = rom_verify::y#3 [phi:rom_verify::@13->rom_verify::@3#0] -- register_copy 
    // [1215] phi rom_verify::progress_row_current#4 = rom_verify::progress_row_current#3 [phi:rom_verify::@13->rom_verify::@3#1] -- register_copy 
    // rom_verify::@3
  __b3:
    // if (equal_bytes != PROGRESS_CELL)
    // [1216] if(rom_verify::equal_bytes#0!=PROGRESS_CELL) goto rom_verify::@4 -- vwuz1_neq_vwuc1_then_la1 
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
    // [1217] stackpush(char) = '=' -- _stackpushbyte_=vbuc1 
    lda #'='
    pha
    // [1218] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_verify::@5
  __b5:
    // ram_address += PROGRESS_CELL
    // [1220] rom_verify::ram_address#1 = rom_verify::ram_address#10 + PROGRESS_CELL -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address
    clc
    adc #<PROGRESS_CELL
    sta.z ram_address
    lda.z ram_address+1
    adc #>PROGRESS_CELL
    sta.z ram_address+1
    // rom_address += PROGRESS_CELL
    // [1221] rom_verify::rom_address#1 = rom_verify::rom_address#12 + PROGRESS_CELL -- vduz1=vduz1_plus_vwuc1 
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
    // [1222] rom_verify::progress_row_current#11 = rom_verify::progress_row_current#4 + PROGRESS_CELL -- vwuz1=vwuz1_plus_vwuc1 
    lda.z progress_row_current
    clc
    adc #<PROGRESS_CELL
    sta.z progress_row_current
    lda.z progress_row_current+1
    adc #>PROGRESS_CELL
    sta.z progress_row_current+1
    // if (ram_address == BRAM_HIGH)
    // [1223] if(rom_verify::ram_address#1!=$c000) goto rom_verify::@6 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address+1
    cmp #>$c000
    bne __b6
    lda.z ram_address
    cmp #<$c000
    bne __b6
    // rom_verify::@10
    // bram_bank++;
    // [1224] rom_verify::bram_bank#1 = ++ rom_verify::bram_bank#11 -- vbuz1=_inc_vbuz1 
    inc.z bram_bank
    // [1225] phi from rom_verify::@10 to rom_verify::@6 [phi:rom_verify::@10->rom_verify::@6]
    // [1225] phi rom_verify::bram_bank#24 = rom_verify::bram_bank#1 [phi:rom_verify::@10->rom_verify::@6#0] -- register_copy 
    // [1225] phi rom_verify::ram_address#6 = (char *)$a000 [phi:rom_verify::@10->rom_verify::@6#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1225] phi from rom_verify::@5 to rom_verify::@6 [phi:rom_verify::@5->rom_verify::@6]
    // [1225] phi rom_verify::bram_bank#24 = rom_verify::bram_bank#11 [phi:rom_verify::@5->rom_verify::@6#0] -- register_copy 
    // [1225] phi rom_verify::ram_address#6 = rom_verify::ram_address#1 [phi:rom_verify::@5->rom_verify::@6#1] -- register_copy 
    // rom_verify::@6
  __b6:
    // if (ram_address == RAM_HIGH)
    // [1226] if(rom_verify::ram_address#6!=$8000) goto rom_verify::@23 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address+1
    cmp #>$8000
    bne __b7
    lda.z ram_address
    cmp #<$8000
    bne __b7
    // [1228] phi from rom_verify::@6 to rom_verify::@7 [phi:rom_verify::@6->rom_verify::@7]
    // [1228] phi rom_verify::ram_address#11 = (char *)$a000 [phi:rom_verify::@6->rom_verify::@7#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address
    lda #>$a000
    sta.z ram_address+1
    // [1228] phi rom_verify::bram_bank#10 = 1 [phi:rom_verify::@6->rom_verify::@7#1] -- vbuz1=vbuc1 
    lda #1
    sta.z bram_bank
    // [1227] phi from rom_verify::@6 to rom_verify::@23 [phi:rom_verify::@6->rom_verify::@23]
    // rom_verify::@23
    // [1228] phi from rom_verify::@23 to rom_verify::@7 [phi:rom_verify::@23->rom_verify::@7]
    // [1228] phi rom_verify::ram_address#11 = rom_verify::ram_address#6 [phi:rom_verify::@23->rom_verify::@7#0] -- register_copy 
    // [1228] phi rom_verify::bram_bank#10 = rom_verify::bram_bank#24 [phi:rom_verify::@23->rom_verify::@7#1] -- register_copy 
    // rom_verify::@7
  __b7:
    // PROGRESS_CELL - equal_bytes
    // [1229] rom_verify::$16 = PROGRESS_CELL - rom_verify::equal_bytes#0 -- vwuz1=vwuc1_minus_vwuz1 
    lda #<PROGRESS_CELL
    sec
    sbc.z rom_verify__16
    sta.z rom_verify__16
    lda #>PROGRESS_CELL
    sbc.z rom_verify__16+1
    sta.z rom_verify__16+1
    // rom_different_bytes += (PROGRESS_CELL - equal_bytes)
    // [1230] rom_verify::rom_different_bytes#1 = rom_verify::rom_different_bytes#11 + rom_verify::$16 -- vduz1=vduz1_plus_vwuz2 
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
    // [1231] call snprintf_init
    jsr snprintf_init
    // [1232] phi from rom_verify::@7 to rom_verify::@14 [phi:rom_verify::@7->rom_verify::@14]
    // rom_verify::@14
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1233] call printf_str
    // [630] phi from rom_verify::@14 to printf_str [phi:rom_verify::@14->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:rom_verify::@14->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = rom_verify::s [phi:rom_verify::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@15
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1234] printf_ulong::uvalue#4 = rom_verify::rom_different_bytes#1 -- vduz1=vduz2 
    lda.z rom_different_bytes
    sta.z printf_ulong.uvalue
    lda.z rom_different_bytes+1
    sta.z printf_ulong.uvalue+1
    lda.z rom_different_bytes+2
    sta.z printf_ulong.uvalue+2
    lda.z rom_different_bytes+3
    sta.z printf_ulong.uvalue+3
    // [1235] call printf_ulong
    // [1255] phi from rom_verify::@15 to printf_ulong [phi:rom_verify::@15->printf_ulong]
    // [1255] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_verify::@15->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1255] phi printf_ulong::format_min_length#11 = 5 [phi:rom_verify::@15->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1255] phi printf_ulong::putc#11 = &snputc [phi:rom_verify::@15->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1255] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_verify::@15->printf_ulong#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1255] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#4 [phi:rom_verify::@15->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1236] phi from rom_verify::@15 to rom_verify::@16 [phi:rom_verify::@15->rom_verify::@16]
    // rom_verify::@16
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1237] call printf_str
    // [630] phi from rom_verify::@16 to printf_str [phi:rom_verify::@16->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:rom_verify::@16->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = rom_verify::s1 [phi:rom_verify::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@17
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1238] printf_uchar::uvalue#6 = rom_verify::bram_bank#10 -- vbuz1=vbuz2 
    lda.z bram_bank
    sta.z printf_uchar.uvalue
    // [1239] call printf_uchar
    // [1028] phi from rom_verify::@17 to printf_uchar [phi:rom_verify::@17->printf_uchar]
    // [1028] phi printf_uchar::format_zero_padding#10 = 1 [phi:rom_verify::@17->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1028] phi printf_uchar::format_min_length#10 = 2 [phi:rom_verify::@17->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [1028] phi printf_uchar::putc#10 = &snputc [phi:rom_verify::@17->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1028] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:rom_verify::@17->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [1028] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#6 [phi:rom_verify::@17->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1240] phi from rom_verify::@17 to rom_verify::@18 [phi:rom_verify::@17->rom_verify::@18]
    // rom_verify::@18
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1241] call printf_str
    // [630] phi from rom_verify::@18 to printf_str [phi:rom_verify::@18->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:rom_verify::@18->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = s3 [phi:rom_verify::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s3
    sta.z printf_str.s
    lda #>@s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@19
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1242] printf_uint::uvalue#11 = (unsigned int)rom_verify::ram_address#11 -- vwuz1=vwuz2 
    lda.z ram_address
    sta.z printf_uint.uvalue
    lda.z ram_address+1
    sta.z printf_uint.uvalue+1
    // [1243] call printf_uint
    // [639] phi from rom_verify::@19 to printf_uint [phi:rom_verify::@19->printf_uint]
    // [639] phi printf_uint::format_zero_padding#16 = 1 [phi:rom_verify::@19->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [639] phi printf_uint::format_min_length#16 = 4 [phi:rom_verify::@19->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [639] phi printf_uint::putc#16 = &snputc [phi:rom_verify::@19->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [639] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:rom_verify::@19->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [639] phi printf_uint::uvalue#16 = printf_uint::uvalue#11 [phi:rom_verify::@19->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1244] phi from rom_verify::@19 to rom_verify::@20 [phi:rom_verify::@19->rom_verify::@20]
    // rom_verify::@20
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1245] call printf_str
    // [630] phi from rom_verify::@20 to printf_str [phi:rom_verify::@20->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:rom_verify::@20->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = rom_verify::s3 [phi:rom_verify::@20->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@21
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1246] printf_ulong::uvalue#5 = rom_verify::rom_address#1 -- vduz1=vduz2 
    lda.z rom_address
    sta.z printf_ulong.uvalue
    lda.z rom_address+1
    sta.z printf_ulong.uvalue+1
    lda.z rom_address+2
    sta.z printf_ulong.uvalue+2
    lda.z rom_address+3
    sta.z printf_ulong.uvalue+3
    // [1247] call printf_ulong
    // [1255] phi from rom_verify::@21 to printf_ulong [phi:rom_verify::@21->printf_ulong]
    // [1255] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_verify::@21->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1255] phi printf_ulong::format_min_length#11 = 5 [phi:rom_verify::@21->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1255] phi printf_ulong::putc#11 = &snputc [phi:rom_verify::@21->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1255] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_verify::@21->printf_ulong#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1255] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#5 [phi:rom_verify::@21->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // rom_verify::@22
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address)
    // [1248] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1249] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [1251] call info_line
    // [845] phi from rom_verify::@22 to info_line [phi:rom_verify::@22->info_line]
    // [845] phi info_line::info_text#18 = info_text [phi:rom_verify::@22->info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_line.info_text
    lda #>@info_text
    sta.z info_line.info_text+1
    jsr info_line
    // [1202] phi from rom_verify::@22 to rom_verify::@1 [phi:rom_verify::@22->rom_verify::@1]
    // [1202] phi rom_verify::y#3 = rom_verify::y#10 [phi:rom_verify::@22->rom_verify::@1#0] -- register_copy 
    // [1202] phi rom_verify::progress_row_current#3 = rom_verify::progress_row_current#11 [phi:rom_verify::@22->rom_verify::@1#1] -- register_copy 
    // [1202] phi rom_verify::rom_different_bytes#11 = rom_verify::rom_different_bytes#1 [phi:rom_verify::@22->rom_verify::@1#2] -- register_copy 
    // [1202] phi rom_verify::ram_address#10 = rom_verify::ram_address#11 [phi:rom_verify::@22->rom_verify::@1#3] -- register_copy 
    // [1202] phi rom_verify::bram_bank#11 = rom_verify::bram_bank#10 [phi:rom_verify::@22->rom_verify::@1#4] -- register_copy 
    // [1202] phi rom_verify::rom_address#12 = rom_verify::rom_address#1 [phi:rom_verify::@22->rom_verify::@1#5] -- register_copy 
    jmp __b1
    // rom_verify::@4
  __b4:
    // cputc('*')
    // [1252] stackpush(char) = '*' -- _stackpushbyte_=vbuc1 
    lda #'*'
    pha
    // [1253] callexecute cputc  -- call_vprc1 
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
// void printf_ulong(__zp($4b) void (*putc)(char), __zp($26) unsigned long uvalue, __zp($dd) char format_min_length, char format_justify_left, char format_sign_always, __zp($dc) char format_zero_padding, char format_upper_case, __zp($da) char format_radix)
printf_ulong: {
    .label uvalue = $26
    .label uvalue_1 = $f5
    .label format_radix = $da
    .label putc = $4b
    .label format_min_length = $dd
    .label format_zero_padding = $dc
    // printf_ulong::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1256] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // ultoa(uvalue, printf_buffer.digits, format.radix)
    // [1257] ultoa::value#1 = printf_ulong::uvalue#11
    // [1258] ultoa::radix#0 = printf_ulong::format_radix#11
    // [1259] call ultoa
    // Format number into buffer
    jsr ultoa
    // printf_ulong::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1260] printf_number_buffer::putc#0 = printf_ulong::putc#11
    // [1261] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [1262] printf_number_buffer::format_min_length#0 = printf_ulong::format_min_length#11
    // [1263] printf_number_buffer::format_zero_padding#0 = printf_ulong::format_zero_padding#11
    // [1264] call printf_number_buffer
  // Print using format
    // [1701] phi from printf_ulong::@2 to printf_number_buffer [phi:printf_ulong::@2->printf_number_buffer]
    // [1701] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#0 [phi:printf_ulong::@2->printf_number_buffer#0] -- register_copy 
    // [1701] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_ulong::@2->printf_number_buffer#1] -- register_copy 
    // [1701] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#0 [phi:printf_ulong::@2->printf_number_buffer#2] -- register_copy 
    // [1701] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#0 [phi:printf_ulong::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_ulong::@return
    // }
    // [1265] return 
    rts
}
  // rom_flash
// __mem() unsigned long rom_flash(__mem() char rom_chip, __zp($cc) char rom_bank_start, __mem() unsigned long file_size)
rom_flash: {
    .label rom_flash__29 = $73
    .label equal_bytes = $4d
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
    // [1267] call info_progress
  // Now we compare the RAM with the actual ROM contents.
    // [596] phi from rom_flash to info_progress [phi:rom_flash->info_progress]
    // [596] phi info_progress::info_text#12 = rom_flash::info_text [phi:rom_flash->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_progress.info_text
    lda #>info_text
    sta.z info_progress.info_text+1
    jsr info_progress
    // rom_flash::@19
    // unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start)
    // [1268] rom_address_from_bank::rom_bank#2 = rom_flash::rom_bank_start#0
    // [1269] call rom_address_from_bank
    // [1996] phi from rom_flash::@19 to rom_address_from_bank [phi:rom_flash::@19->rom_address_from_bank]
    // [1996] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#2 [phi:rom_flash::@19->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start)
    // [1270] rom_address_from_bank::return#4 = rom_address_from_bank::return#0 -- vdum1=vduz2 
    lda.z rom_address_from_bank.return
    sta rom_address_from_bank.return_2
    lda.z rom_address_from_bank.return+1
    sta rom_address_from_bank.return_2+1
    lda.z rom_address_from_bank.return+2
    sta rom_address_from_bank.return_2+2
    lda.z rom_address_from_bank.return+3
    sta rom_address_from_bank.return_2+3
    // rom_flash::@20
    // [1271] rom_flash::rom_address_sector#0 = rom_address_from_bank::return#4
    // unsigned long rom_boundary = rom_address_sector + file_size
    // [1272] rom_flash::rom_boundary#0 = rom_flash::rom_address_sector#0 + rom_flash::file_size#0 -- vdum1=vdum2_plus_vdum3 
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
    // [1273] info_rom::rom_chip#2 = rom_flash::rom_chip#0 -- vbuz1=vbum2 
    lda rom_chip
    sta.z info_rom.rom_chip
    // [1274] call info_rom
    // [1157] phi from rom_flash::@20 to info_rom [phi:rom_flash::@20->info_rom]
    // [1157] phi info_rom::info_text#17 = rom_flash::info_text1 [phi:rom_flash::@20->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z info_rom.info_text
    lda #>info_text1
    sta.z info_rom.info_text+1
    // [1157] phi info_rom::rom_chip#17 = info_rom::rom_chip#2 [phi:rom_flash::@20->info_rom#1] -- register_copy 
    // [1157] phi info_rom::info_status#17 = STATUS_FLASHING [phi:rom_flash::@20->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHING
    sta.z info_rom.info_status
    jsr info_rom
    // [1275] phi from rom_flash::@20 to rom_flash::@1 [phi:rom_flash::@20->rom_flash::@1]
    // [1275] phi rom_flash::y_sector#13 = PROGRESS_Y [phi:rom_flash::@20->rom_flash::@1#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y_sector
    // [1275] phi rom_flash::x_sector#10 = PROGRESS_X [phi:rom_flash::@20->rom_flash::@1#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [1275] phi rom_flash::flash_errors#10 = 0 [phi:rom_flash::@20->rom_flash::@1#2] -- vdum1=vduc1 
    lda #<0
    sta flash_errors
    sta flash_errors+1
    lda #<0>>$10
    sta flash_errors+2
    lda #>0>>$10
    sta flash_errors+3
    // [1275] phi rom_flash::ram_address_sector#11 = (char *)$6000 [phi:rom_flash::@20->rom_flash::@1#3] -- pbuz1=pbuc1 
    lda #<$6000
    sta.z ram_address_sector
    lda #>$6000
    sta.z ram_address_sector+1
    // [1275] phi rom_flash::bram_bank_sector#14 = 0 [phi:rom_flash::@20->rom_flash::@1#4] -- vbuz1=vbuc1 
    lda #0
    sta.z bram_bank_sector
    // [1275] phi rom_flash::rom_address_sector#12 = rom_flash::rom_address_sector#0 [phi:rom_flash::@20->rom_flash::@1#5] -- register_copy 
    // rom_flash::@1
  __b1:
    // while (rom_address_sector < rom_boundary)
    // [1276] if(rom_flash::rom_address_sector#12<rom_flash::rom_boundary#0) goto rom_flash::@2 -- vdum1_lt_vdum2_then_la1 
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
    // [1277] phi from rom_flash::@1 to rom_flash::@3 [phi:rom_flash::@1->rom_flash::@3]
    // rom_flash::@3
    // info_line("Flashed ...")
    // [1278] call info_line
    // [845] phi from rom_flash::@3 to info_line [phi:rom_flash::@3->info_line]
    // [845] phi info_line::info_text#18 = rom_flash::info_text2 [phi:rom_flash::@3->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z info_line.info_text
    lda #>info_text2
    sta.z info_line.info_text+1
    jsr info_line
    // rom_flash::@return
    // }
    // [1279] return 
    rts
    // rom_flash::@2
  __b2:
    // unsigned int equal_bytes = rom_compare(bram_bank_sector, (ram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR)
    // [1280] rom_compare::bank_ram#1 = rom_flash::bram_bank_sector#14 -- vbuz1=vbuz2 
    lda.z bram_bank_sector
    sta.z rom_compare.bank_ram
    // [1281] rom_compare::ptr_ram#2 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z rom_compare.ptr_ram
    lda.z ram_address_sector+1
    sta.z rom_compare.ptr_ram+1
    // [1282] rom_compare::rom_compare_address#1 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_compare.rom_compare_address
    lda rom_address_sector+1
    sta.z rom_compare.rom_compare_address+1
    lda rom_address_sector+2
    sta.z rom_compare.rom_compare_address+2
    lda rom_address_sector+3
    sta.z rom_compare.rom_compare_address+3
    // [1283] call rom_compare
  // {asm{.byte $db}}
    // [2000] phi from rom_flash::@2 to rom_compare [phi:rom_flash::@2->rom_compare]
    // [2000] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#2 [phi:rom_flash::@2->rom_compare#0] -- register_copy 
    // [2000] phi rom_compare::rom_compare_size#11 = $1000 [phi:rom_flash::@2->rom_compare#1] -- vwuz1=vwuc1 
    lda #<$1000
    sta.z rom_compare.rom_compare_size
    lda #>$1000
    sta.z rom_compare.rom_compare_size+1
    // [2000] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#1 [phi:rom_flash::@2->rom_compare#2] -- register_copy 
    // [2000] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#1 [phi:rom_flash::@2->rom_compare#3] -- register_copy 
    jsr rom_compare
    // unsigned int equal_bytes = rom_compare(bram_bank_sector, (ram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR)
    // [1284] rom_compare::return#3 = rom_compare::equal_bytes#2
    // rom_flash::@21
    // [1285] rom_flash::equal_bytes#0 = rom_compare::return#3
    // if (equal_bytes != ROM_SECTOR)
    // [1286] if(rom_flash::equal_bytes#0!=$1000) goto rom_flash::@5 -- vwuz1_neq_vwuc1_then_la1 
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
    // [1287] cputsxy::x#0 = rom_flash::x_sector#10
    // [1288] cputsxy::y#0 = rom_flash::y_sector#13 -- vbuz1=vbum2 
    lda y_sector
    sta.z cputsxy.y
    // [1289] call cputsxy
    jsr cputsxy
    // [1290] phi from rom_flash::@12 rom_flash::@16 to rom_flash::@4 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4]
    // [1290] phi rom_flash::flash_errors#13 = rom_flash::flash_errors#1 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4#0] -- register_copy 
    // rom_flash::@4
  __b4:
    // ram_address_sector += ROM_SECTOR
    // [1291] rom_flash::ram_address_sector#1 = rom_flash::ram_address_sector#11 + $1000 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address_sector
    clc
    adc #<$1000
    sta.z ram_address_sector
    lda.z ram_address_sector+1
    adc #>$1000
    sta.z ram_address_sector+1
    // rom_address_sector += ROM_SECTOR
    // [1292] rom_flash::rom_address_sector#1 = rom_flash::rom_address_sector#12 + $1000 -- vdum1=vdum1_plus_vwuc1 
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
    // [1293] if(rom_flash::ram_address_sector#1!=$c000) goto rom_flash::@13 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address_sector+1
    cmp #>$c000
    bne __b13
    lda.z ram_address_sector
    cmp #<$c000
    bne __b13
    // rom_flash::@17
    // bram_bank_sector++;
    // [1294] rom_flash::bram_bank_sector#1 = ++ rom_flash::bram_bank_sector#14 -- vbuz1=_inc_vbuz1 
    inc.z bram_bank_sector
    // [1295] phi from rom_flash::@17 to rom_flash::@13 [phi:rom_flash::@17->rom_flash::@13]
    // [1295] phi rom_flash::bram_bank_sector#38 = rom_flash::bram_bank_sector#1 [phi:rom_flash::@17->rom_flash::@13#0] -- register_copy 
    // [1295] phi rom_flash::ram_address_sector#8 = (char *)$a000 [phi:rom_flash::@17->rom_flash::@13#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address_sector
    lda #>$a000
    sta.z ram_address_sector+1
    // [1295] phi from rom_flash::@4 to rom_flash::@13 [phi:rom_flash::@4->rom_flash::@13]
    // [1295] phi rom_flash::bram_bank_sector#38 = rom_flash::bram_bank_sector#14 [phi:rom_flash::@4->rom_flash::@13#0] -- register_copy 
    // [1295] phi rom_flash::ram_address_sector#8 = rom_flash::ram_address_sector#1 [phi:rom_flash::@4->rom_flash::@13#1] -- register_copy 
    // rom_flash::@13
  __b13:
    // if (ram_address_sector == RAM_HIGH)
    // [1296] if(rom_flash::ram_address_sector#8!=$8000) goto rom_flash::@44 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address_sector+1
    cmp #>$8000
    bne __b14
    lda.z ram_address_sector
    cmp #<$8000
    bne __b14
    // [1298] phi from rom_flash::@13 to rom_flash::@14 [phi:rom_flash::@13->rom_flash::@14]
    // [1298] phi rom_flash::ram_address_sector#15 = (char *)$a000 [phi:rom_flash::@13->rom_flash::@14#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address_sector
    lda #>$a000
    sta.z ram_address_sector+1
    // [1298] phi rom_flash::bram_bank_sector#12 = 1 [phi:rom_flash::@13->rom_flash::@14#1] -- vbuz1=vbuc1 
    lda #1
    sta.z bram_bank_sector
    // [1297] phi from rom_flash::@13 to rom_flash::@44 [phi:rom_flash::@13->rom_flash::@44]
    // rom_flash::@44
    // [1298] phi from rom_flash::@44 to rom_flash::@14 [phi:rom_flash::@44->rom_flash::@14]
    // [1298] phi rom_flash::ram_address_sector#15 = rom_flash::ram_address_sector#8 [phi:rom_flash::@44->rom_flash::@14#0] -- register_copy 
    // [1298] phi rom_flash::bram_bank_sector#12 = rom_flash::bram_bank_sector#38 [phi:rom_flash::@44->rom_flash::@14#1] -- register_copy 
    // rom_flash::@14
  __b14:
    // x_sector += 8
    // [1299] rom_flash::x_sector#1 = rom_flash::x_sector#10 + 8 -- vbum1=vbum1_plus_vbuc1 
    lda #8
    clc
    adc x_sector
    sta x_sector
    // rom_address_sector % PROGRESS_ROW
    // [1300] rom_flash::$29 = rom_flash::rom_address_sector#1 & PROGRESS_ROW-1 -- vduz1=vdum2_band_vduc1 
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
    // [1301] if(0!=rom_flash::$29) goto rom_flash::@15 -- 0_neq_vduz1_then_la1 
    lda.z rom_flash__29
    ora.z rom_flash__29+1
    ora.z rom_flash__29+2
    ora.z rom_flash__29+3
    bne __b15
    // rom_flash::@18
    // y_sector++;
    // [1302] rom_flash::y_sector#1 = ++ rom_flash::y_sector#13 -- vbum1=_inc_vbum1 
    inc y_sector
    // [1303] phi from rom_flash::@18 to rom_flash::@15 [phi:rom_flash::@18->rom_flash::@15]
    // [1303] phi rom_flash::y_sector#18 = rom_flash::y_sector#1 [phi:rom_flash::@18->rom_flash::@15#0] -- register_copy 
    // [1303] phi rom_flash::x_sector#20 = PROGRESS_X [phi:rom_flash::@18->rom_flash::@15#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [1303] phi from rom_flash::@14 to rom_flash::@15 [phi:rom_flash::@14->rom_flash::@15]
    // [1303] phi rom_flash::y_sector#18 = rom_flash::y_sector#13 [phi:rom_flash::@14->rom_flash::@15#0] -- register_copy 
    // [1303] phi rom_flash::x_sector#20 = rom_flash::x_sector#1 [phi:rom_flash::@14->rom_flash::@15#1] -- register_copy 
    // rom_flash::@15
  __b15:
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1304] call snprintf_init
    jsr snprintf_init
    // rom_flash::@40
    // [1305] printf_ulong::uvalue#8 = rom_flash::flash_errors#13 -- vduz1=vdum2 
    lda flash_errors
    sta.z printf_ulong.uvalue
    lda flash_errors+1
    sta.z printf_ulong.uvalue+1
    lda flash_errors+2
    sta.z printf_ulong.uvalue+2
    lda flash_errors+3
    sta.z printf_ulong.uvalue+3
    // [1306] call printf_ulong
    // [1255] phi from rom_flash::@40 to printf_ulong [phi:rom_flash::@40->printf_ulong]
    // [1255] phi printf_ulong::format_zero_padding#11 = 0 [phi:rom_flash::@40->printf_ulong#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_ulong.format_zero_padding
    // [1255] phi printf_ulong::format_min_length#11 = 0 [phi:rom_flash::@40->printf_ulong#1] -- vbuz1=vbuc1 
    sta.z printf_ulong.format_min_length
    // [1255] phi printf_ulong::putc#11 = &snputc [phi:rom_flash::@40->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1255] phi printf_ulong::format_radix#11 = DECIMAL [phi:rom_flash::@40->printf_ulong#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_ulong.format_radix
    // [1255] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#8 [phi:rom_flash::@40->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1307] phi from rom_flash::@40 to rom_flash::@41 [phi:rom_flash::@40->rom_flash::@41]
    // rom_flash::@41
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1308] call printf_str
    // [630] phi from rom_flash::@41 to printf_str [phi:rom_flash::@41->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:rom_flash::@41->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = rom_flash::s6 [phi:rom_flash::@41->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@42
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1309] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1310] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom(rom_chip, STATUS_FLASHING, info_text)
    // [1312] info_rom::rom_chip#3 = rom_flash::rom_chip#0 -- vbuz1=vbum2 
    lda rom_chip
    sta.z info_rom.rom_chip
    // [1313] call info_rom
    // [1157] phi from rom_flash::@42 to info_rom [phi:rom_flash::@42->info_rom]
    // [1157] phi info_rom::info_text#17 = info_text [phi:rom_flash::@42->info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_rom.info_text
    lda #>@info_text
    sta.z info_rom.info_text+1
    // [1157] phi info_rom::rom_chip#17 = info_rom::rom_chip#3 [phi:rom_flash::@42->info_rom#1] -- register_copy 
    // [1157] phi info_rom::info_status#17 = STATUS_FLASHING [phi:rom_flash::@42->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHING
    sta.z info_rom.info_status
    jsr info_rom
    // [1275] phi from rom_flash::@42 to rom_flash::@1 [phi:rom_flash::@42->rom_flash::@1]
    // [1275] phi rom_flash::y_sector#13 = rom_flash::y_sector#18 [phi:rom_flash::@42->rom_flash::@1#0] -- register_copy 
    // [1275] phi rom_flash::x_sector#10 = rom_flash::x_sector#20 [phi:rom_flash::@42->rom_flash::@1#1] -- register_copy 
    // [1275] phi rom_flash::flash_errors#10 = rom_flash::flash_errors#13 [phi:rom_flash::@42->rom_flash::@1#2] -- register_copy 
    // [1275] phi rom_flash::ram_address_sector#11 = rom_flash::ram_address_sector#15 [phi:rom_flash::@42->rom_flash::@1#3] -- register_copy 
    // [1275] phi rom_flash::bram_bank_sector#14 = rom_flash::bram_bank_sector#12 [phi:rom_flash::@42->rom_flash::@1#4] -- register_copy 
    // [1275] phi rom_flash::rom_address_sector#12 = rom_flash::rom_address_sector#1 [phi:rom_flash::@42->rom_flash::@1#5] -- register_copy 
    jmp __b1
    // [1314] phi from rom_flash::@21 to rom_flash::@5 [phi:rom_flash::@21->rom_flash::@5]
  __b3:
    // [1314] phi rom_flash::retries#12 = 0 [phi:rom_flash::@21->rom_flash::@5#0] -- vbuz1=vbuc1 
    lda #0
    sta.z retries
    // [1314] phi rom_flash::flash_errors_sector#11 = 0 [phi:rom_flash::@21->rom_flash::@5#1] -- vwuz1=vwuc1 
    sta.z flash_errors_sector
    sta.z flash_errors_sector+1
    // [1314] phi from rom_flash::@43 to rom_flash::@5 [phi:rom_flash::@43->rom_flash::@5]
    // [1314] phi rom_flash::retries#12 = rom_flash::retries#1 [phi:rom_flash::@43->rom_flash::@5#0] -- register_copy 
    // [1314] phi rom_flash::flash_errors_sector#11 = rom_flash::flash_errors_sector#10 [phi:rom_flash::@43->rom_flash::@5#1] -- register_copy 
    // rom_flash::@5
  __b5:
    // rom_sector_erase(rom_address_sector)
    // [1315] rom_sector_erase::address#0 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_sector_erase.address
    lda rom_address_sector+1
    sta.z rom_sector_erase.address+1
    lda rom_address_sector+2
    sta.z rom_sector_erase.address+2
    lda rom_address_sector+3
    sta.z rom_sector_erase.address+3
    // [1316] call rom_sector_erase
    // [2062] phi from rom_flash::@5 to rom_sector_erase [phi:rom_flash::@5->rom_sector_erase]
    jsr rom_sector_erase
    // rom_flash::@22
    // unsigned long rom_sector_boundary = rom_address_sector + ROM_SECTOR
    // [1317] rom_flash::rom_sector_boundary#0 = rom_flash::rom_address_sector#12 + $1000 -- vdum1=vdum2_plus_vwuc1 
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
    // [1318] gotoxy::x#27 = rom_flash::x_sector#10 -- vbuz1=vbum2 
    lda x_sector
    sta.z gotoxy.x
    // [1319] gotoxy::y#27 = rom_flash::y_sector#13 -- vbuz1=vbum2 
    lda y_sector
    sta.z gotoxy.y
    // [1320] call gotoxy
    // [486] phi from rom_flash::@22 to gotoxy [phi:rom_flash::@22->gotoxy]
    // [486] phi gotoxy::y#29 = gotoxy::y#27 [phi:rom_flash::@22->gotoxy#0] -- register_copy 
    // [486] phi gotoxy::x#29 = gotoxy::x#27 [phi:rom_flash::@22->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1321] phi from rom_flash::@22 to rom_flash::@23 [phi:rom_flash::@22->rom_flash::@23]
    // rom_flash::@23
    // printf("........")
    // [1322] call printf_str
    // [630] phi from rom_flash::@23 to printf_str [phi:rom_flash::@23->printf_str]
    // [630] phi printf_str::putc#66 = &cputc [phi:rom_flash::@23->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = rom_flash::s1 [phi:rom_flash::@23->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@24
    // [1323] rom_flash::rom_address#26 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_address
    lda rom_address_sector+1
    sta.z rom_address+1
    lda rom_address_sector+2
    sta.z rom_address+2
    lda rom_address_sector+3
    sta.z rom_address+3
    // [1324] rom_flash::ram_address#26 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z ram_address
    lda.z ram_address_sector+1
    sta.z ram_address+1
    // [1325] rom_flash::x#26 = rom_flash::x_sector#10 -- vbuz1=vbum2 
    lda x_sector
    sta.z x
    // [1326] phi from rom_flash::@10 rom_flash::@24 to rom_flash::@6 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6]
    // [1326] phi rom_flash::x#10 = rom_flash::x#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#0] -- register_copy 
    // [1326] phi rom_flash::ram_address#10 = rom_flash::ram_address#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#1] -- register_copy 
    // [1326] phi rom_flash::flash_errors_sector#10 = rom_flash::flash_errors_sector#8 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#2] -- register_copy 
    // [1326] phi rom_flash::rom_address#11 = rom_flash::rom_address#1 [phi:rom_flash::@10/rom_flash::@24->rom_flash::@6#3] -- register_copy 
    // rom_flash::@6
  __b6:
    // while (rom_address < rom_sector_boundary)
    // [1327] if(rom_flash::rom_address#11<rom_flash::rom_sector_boundary#0) goto rom_flash::@7 -- vduz1_lt_vdum2_then_la1 
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
    // [1328] rom_flash::retries#1 = ++ rom_flash::retries#12 -- vbuz1=_inc_vbuz1 
    inc.z retries
    // while (flash_errors_sector && retries <= 3)
    // [1329] if(0==rom_flash::flash_errors_sector#10) goto rom_flash::@12 -- 0_eq_vwuz1_then_la1 
    lda.z flash_errors_sector
    ora.z flash_errors_sector+1
    beq __b12
    // rom_flash::@43
    // [1330] if(rom_flash::retries#1<3+1) goto rom_flash::@5 -- vbuz1_lt_vbuc1_then_la1 
    lda.z retries
    cmp #3+1
    bcs !__b5+
    jmp __b5
  !__b5:
    // rom_flash::@12
  __b12:
    // flash_errors += flash_errors_sector
    // [1331] rom_flash::flash_errors#1 = rom_flash::flash_errors#10 + rom_flash::flash_errors_sector#10 -- vdum1=vdum1_plus_vwuz2 
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
    // [1332] printf_ulong::uvalue#7 = rom_flash::flash_errors_sector#10 + rom_flash::flash_errors#10 -- vduz1=vwuz2_plus_vdum3 
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
    // [1333] call snprintf_init
    jsr snprintf_init
    // [1334] phi from rom_flash::@7 to rom_flash::@25 [phi:rom_flash::@7->rom_flash::@25]
    // rom_flash::@25
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1335] call printf_str
    // [630] phi from rom_flash::@25 to printf_str [phi:rom_flash::@25->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:rom_flash::@25->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = rom_flash::s2 [phi:rom_flash::@25->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@26
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1336] printf_uchar::uvalue#7 = rom_flash::bram_bank_sector#14 -- vbuz1=vbuz2 
    lda.z bram_bank_sector
    sta.z printf_uchar.uvalue
    // [1337] call printf_uchar
    // [1028] phi from rom_flash::@26 to printf_uchar [phi:rom_flash::@26->printf_uchar]
    // [1028] phi printf_uchar::format_zero_padding#10 = 1 [phi:rom_flash::@26->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1028] phi printf_uchar::format_min_length#10 = 2 [phi:rom_flash::@26->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [1028] phi printf_uchar::putc#10 = &snputc [phi:rom_flash::@26->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1028] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:rom_flash::@26->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [1028] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#7 [phi:rom_flash::@26->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1338] phi from rom_flash::@26 to rom_flash::@27 [phi:rom_flash::@26->rom_flash::@27]
    // rom_flash::@27
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1339] call printf_str
    // [630] phi from rom_flash::@27 to printf_str [phi:rom_flash::@27->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:rom_flash::@27->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = s3 [phi:rom_flash::@27->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@28
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1340] printf_uint::uvalue#12 = (unsigned int)rom_flash::ram_address_sector#11 -- vwuz1=vwuz2 
    lda.z ram_address_sector
    sta.z printf_uint.uvalue
    lda.z ram_address_sector+1
    sta.z printf_uint.uvalue+1
    // [1341] call printf_uint
    // [639] phi from rom_flash::@28 to printf_uint [phi:rom_flash::@28->printf_uint]
    // [639] phi printf_uint::format_zero_padding#16 = 1 [phi:rom_flash::@28->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [639] phi printf_uint::format_min_length#16 = 4 [phi:rom_flash::@28->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [639] phi printf_uint::putc#16 = &snputc [phi:rom_flash::@28->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [639] phi printf_uint::format_radix#16 = HEXADECIMAL [phi:rom_flash::@28->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [639] phi printf_uint::uvalue#16 = printf_uint::uvalue#12 [phi:rom_flash::@28->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1342] phi from rom_flash::@28 to rom_flash::@29 [phi:rom_flash::@28->rom_flash::@29]
    // rom_flash::@29
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1343] call printf_str
    // [630] phi from rom_flash::@29 to printf_str [phi:rom_flash::@29->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:rom_flash::@29->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = rom_flash::s4 [phi:rom_flash::@29->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@30
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1344] printf_ulong::uvalue#6 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z printf_ulong.uvalue
    lda rom_address_sector+1
    sta.z printf_ulong.uvalue+1
    lda rom_address_sector+2
    sta.z printf_ulong.uvalue+2
    lda rom_address_sector+3
    sta.z printf_ulong.uvalue+3
    // [1345] call printf_ulong
    // [1255] phi from rom_flash::@30 to printf_ulong [phi:rom_flash::@30->printf_ulong]
    // [1255] phi printf_ulong::format_zero_padding#11 = 1 [phi:rom_flash::@30->printf_ulong#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_ulong.format_zero_padding
    // [1255] phi printf_ulong::format_min_length#11 = 5 [phi:rom_flash::@30->printf_ulong#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_ulong.format_min_length
    // [1255] phi printf_ulong::putc#11 = &snputc [phi:rom_flash::@30->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1255] phi printf_ulong::format_radix#11 = HEXADECIMAL [phi:rom_flash::@30->printf_ulong#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_ulong.format_radix
    // [1255] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#6 [phi:rom_flash::@30->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1346] phi from rom_flash::@30 to rom_flash::@31 [phi:rom_flash::@30->rom_flash::@31]
    // rom_flash::@31
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1347] call printf_str
    // [630] phi from rom_flash::@31 to printf_str [phi:rom_flash::@31->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:rom_flash::@31->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = rom_flash::s5 [phi:rom_flash::@31->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@32
    // [1348] printf_ulong::uvalue#20 = printf_ulong::uvalue#7 -- vduz1=vduz2 
    lda.z printf_ulong.uvalue_1
    sta.z printf_ulong.uvalue
    lda.z printf_ulong.uvalue_1+1
    sta.z printf_ulong.uvalue+1
    lda.z printf_ulong.uvalue_1+2
    sta.z printf_ulong.uvalue+2
    lda.z printf_ulong.uvalue_1+3
    sta.z printf_ulong.uvalue+3
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1349] call printf_ulong
    // [1255] phi from rom_flash::@32 to printf_ulong [phi:rom_flash::@32->printf_ulong]
    // [1255] phi printf_ulong::format_zero_padding#11 = 0 [phi:rom_flash::@32->printf_ulong#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_ulong.format_zero_padding
    // [1255] phi printf_ulong::format_min_length#11 = 0 [phi:rom_flash::@32->printf_ulong#1] -- vbuz1=vbuc1 
    sta.z printf_ulong.format_min_length
    // [1255] phi printf_ulong::putc#11 = &snputc [phi:rom_flash::@32->printf_ulong#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_ulong.putc
    lda #>snputc
    sta.z printf_ulong.putc+1
    // [1255] phi printf_ulong::format_radix#11 = DECIMAL [phi:rom_flash::@32->printf_ulong#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_ulong.format_radix
    // [1255] phi printf_ulong::uvalue#11 = printf_ulong::uvalue#20 [phi:rom_flash::@32->printf_ulong#4] -- register_copy 
    jsr printf_ulong
    // [1350] phi from rom_flash::@32 to rom_flash::@33 [phi:rom_flash::@32->rom_flash::@33]
    // rom_flash::@33
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1351] call printf_str
    // [630] phi from rom_flash::@33 to printf_str [phi:rom_flash::@33->printf_str]
    // [630] phi printf_str::putc#66 = &snputc [phi:rom_flash::@33->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [630] phi printf_str::s#66 = rom_flash::s6 [phi:rom_flash::@33->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@34
    // sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors)
    // [1352] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1353] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [1355] call info_line
    // [845] phi from rom_flash::@34 to info_line [phi:rom_flash::@34->info_line]
    // [845] phi info_line::info_text#18 = info_text [phi:rom_flash::@34->info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_line.info_text
    lda #>@info_text
    sta.z info_line.info_text+1
    jsr info_line
    // rom_flash::@35
    // unsigned long written_bytes = rom_write(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1356] rom_write::flash_ram_bank#0 = rom_flash::bram_bank_sector#14 -- vbuz1=vbuz2 
    lda.z bram_bank_sector
    sta.z rom_write.flash_ram_bank
    // [1357] rom_write::flash_ram_address#1 = rom_flash::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_write.flash_ram_address
    lda.z ram_address+1
    sta.z rom_write.flash_ram_address+1
    // [1358] rom_write::flash_rom_address#1 = rom_flash::rom_address#11 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_write.flash_rom_address
    lda.z rom_address+1
    sta.z rom_write.flash_rom_address+1
    lda.z rom_address+2
    sta.z rom_write.flash_rom_address+2
    lda.z rom_address+3
    sta.z rom_write.flash_rom_address+3
    // [1359] call rom_write
    jsr rom_write
    // rom_flash::@36
    // rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1360] rom_compare::bank_ram#2 = rom_flash::bram_bank_sector#14 -- vbuz1=vbuz2 
    lda.z bram_bank_sector
    sta.z rom_compare.bank_ram
    // [1361] rom_compare::ptr_ram#3 = rom_flash::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_compare.ptr_ram
    lda.z ram_address+1
    sta.z rom_compare.ptr_ram+1
    // [1362] rom_compare::rom_compare_address#2 = rom_flash::rom_address#11 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_compare.rom_compare_address
    lda.z rom_address+1
    sta.z rom_compare.rom_compare_address+1
    lda.z rom_address+2
    sta.z rom_compare.rom_compare_address+2
    lda.z rom_address+3
    sta.z rom_compare.rom_compare_address+3
    // [1363] call rom_compare
    // [2000] phi from rom_flash::@36 to rom_compare [phi:rom_flash::@36->rom_compare]
    // [2000] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#3 [phi:rom_flash::@36->rom_compare#0] -- register_copy 
    // [2000] phi rom_compare::rom_compare_size#11 = PROGRESS_CELL [phi:rom_flash::@36->rom_compare#1] -- vwuz1=vwuc1 
    lda #<PROGRESS_CELL
    sta.z rom_compare.rom_compare_size
    lda #>PROGRESS_CELL
    sta.z rom_compare.rom_compare_size+1
    // [2000] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#2 [phi:rom_flash::@36->rom_compare#2] -- register_copy 
    // [2000] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#2 [phi:rom_flash::@36->rom_compare#3] -- register_copy 
    jsr rom_compare
    // rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1364] rom_compare::return#4 = rom_compare::equal_bytes#2
    // rom_flash::@37
    // equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL)
    // [1365] rom_flash::equal_bytes#1 = rom_compare::return#4 -- vwuz1=vwuz2 
    lda.z rom_compare.return
    sta.z equal_bytes_1
    lda.z rom_compare.return+1
    sta.z equal_bytes_1+1
    // gotoxy(x, y)
    // [1366] gotoxy::x#28 = rom_flash::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1367] gotoxy::y#28 = rom_flash::y_sector#13 -- vbuz1=vbum2 
    lda y_sector
    sta.z gotoxy.y
    // [1368] call gotoxy
    // [486] phi from rom_flash::@37 to gotoxy [phi:rom_flash::@37->gotoxy]
    // [486] phi gotoxy::y#29 = gotoxy::y#28 [phi:rom_flash::@37->gotoxy#0] -- register_copy 
    // [486] phi gotoxy::x#29 = gotoxy::x#28 [phi:rom_flash::@37->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_flash::@38
    // if (equal_bytes != PROGRESS_CELL)
    // [1369] if(rom_flash::equal_bytes#1!=PROGRESS_CELL) goto rom_flash::@9 -- vwuz1_neq_vwuc1_then_la1 
    lda.z equal_bytes_1+1
    cmp #>PROGRESS_CELL
    bne __b9
    lda.z equal_bytes_1
    cmp #<PROGRESS_CELL
    bne __b9
    // rom_flash::@11
    // cputcxy(x,y,'+')
    // [1370] cputcxy::x#12 = rom_flash::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1371] cputcxy::y#12 = rom_flash::y_sector#13 -- vbuz1=vbum2 
    lda y_sector
    sta.z cputcxy.y
    // [1372] call cputcxy
    // [1595] phi from rom_flash::@11 to cputcxy [phi:rom_flash::@11->cputcxy]
    // [1595] phi cputcxy::c#13 = '+' [phi:rom_flash::@11->cputcxy#0] -- vbuz1=vbuc1 
    lda #'+'
    sta.z cputcxy.c
    // [1595] phi cputcxy::y#13 = cputcxy::y#12 [phi:rom_flash::@11->cputcxy#1] -- register_copy 
    // [1595] phi cputcxy::x#13 = cputcxy::x#12 [phi:rom_flash::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [1373] phi from rom_flash::@11 rom_flash::@39 to rom_flash::@10 [phi:rom_flash::@11/rom_flash::@39->rom_flash::@10]
    // [1373] phi rom_flash::flash_errors_sector#8 = rom_flash::flash_errors_sector#10 [phi:rom_flash::@11/rom_flash::@39->rom_flash::@10#0] -- register_copy 
    // rom_flash::@10
  __b10:
    // ram_address += PROGRESS_CELL
    // [1374] rom_flash::ram_address#1 = rom_flash::ram_address#10 + PROGRESS_CELL -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address
    clc
    adc #<PROGRESS_CELL
    sta.z ram_address
    lda.z ram_address+1
    adc #>PROGRESS_CELL
    sta.z ram_address+1
    // rom_address += PROGRESS_CELL
    // [1375] rom_flash::rom_address#1 = rom_flash::rom_address#11 + PROGRESS_CELL -- vduz1=vduz1_plus_vwuc1 
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
    // [1376] rom_flash::x#1 = ++ rom_flash::x#10 -- vbuz1=_inc_vbuz1 
    inc.z x
    jmp __b6
    // rom_flash::@9
  __b9:
    // cputcxy(x,y,'!')
    // [1377] cputcxy::x#11 = rom_flash::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1378] cputcxy::y#11 = rom_flash::y_sector#13 -- vbuz1=vbum2 
    lda y_sector
    sta.z cputcxy.y
    // [1379] call cputcxy
    // [1595] phi from rom_flash::@9 to cputcxy [phi:rom_flash::@9->cputcxy]
    // [1595] phi cputcxy::c#13 = '!' [phi:rom_flash::@9->cputcxy#0] -- vbuz1=vbuc1 
    lda #'!'
    sta.z cputcxy.c
    // [1595] phi cputcxy::y#13 = cputcxy::y#11 [phi:rom_flash::@9->cputcxy#1] -- register_copy 
    // [1595] phi cputcxy::x#13 = cputcxy::x#11 [phi:rom_flash::@9->cputcxy#2] -- register_copy 
    jsr cputcxy
    // rom_flash::@39
    // flash_errors_sector++;
    // [1380] rom_flash::flash_errors_sector#1 = ++ rom_flash::flash_errors_sector#10 -- vwuz1=_inc_vwuz1 
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
    .label x_sector = frame_maskxy.cpeekcxy1_y
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
    // [1382] strchr::ptr#6 = (char *)strchr::str#2
    // [1383] phi from strchr strchr::@3 to strchr::@1 [phi:strchr/strchr::@3->strchr::@1]
    // [1383] phi strchr::ptr#2 = strchr::ptr#6 [phi:strchr/strchr::@3->strchr::@1#0] -- register_copy 
    // strchr::@1
  __b1:
    // while(*ptr)
    // [1384] if(0!=*strchr::ptr#2) goto strchr::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (ptr),y
    cmp #0
    bne __b2
    // [1385] phi from strchr::@1 to strchr::@return [phi:strchr::@1->strchr::@return]
    // [1385] phi strchr::return#2 = (void *) 0 [phi:strchr::@1->strchr::@return#0] -- pvoz1=pvoc1 
    tya
    sta.z return
    sta.z return+1
    // strchr::@return
    // }
    // [1386] return 
    rts
    // strchr::@2
  __b2:
    // if(*ptr==c)
    // [1387] if(*strchr::ptr#2!=strchr::c#4) goto strchr::@3 -- _deref_pbuz1_neq_vbum2_then_la1 
    ldy #0
    lda (ptr),y
    cmp c
    bne __b3
    // strchr::@4
    // [1388] strchr::return#8 = (void *)strchr::ptr#2
    // [1385] phi from strchr::@4 to strchr::@return [phi:strchr::@4->strchr::@return]
    // [1385] phi strchr::return#2 = strchr::return#8 [phi:strchr::@4->strchr::@return#0] -- register_copy 
    rts
    // strchr::@3
  __b3:
    // ptr++;
    // [1389] strchr::ptr#1 = ++ strchr::ptr#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr
    bne !+
    inc.z ptr+1
  !:
    jmp __b1
  .segment Data
    c: .byte 0
}
.segment Code
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __zp($d8) char mapbase, __zp($d7) char config)
screenlayer: {
    .label screenlayer__1 = $d8
    .label screenlayer__5 = $d7
    .label screenlayer__6 = $d7
    .label mapbase = $d8
    .label config = $d7
    .label y = $d6
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [1390] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [1391] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [1392] *((char *)&__conio+2) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+2
    // mapbase >> 7
    // [1393] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbum1=vbuz2_ror_7 
    lda.z mapbase
    rol
    rol
    and #1
    sta screenlayer__0
    // __conio.mapbase_bank = mapbase >> 7
    // [1394] *((char *)&__conio+5) = screenlayer::$0 -- _deref_pbuc1=vbum1 
    sta __conio+5
    // (mapbase)<<1
    // [1395] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z screenlayer__1
    // MAKEWORD((mapbase)<<1,0)
    // [1396] screenlayer::$2 = screenlayer::$1 w= 0 -- vwum1=vbuz2_word_vbuc1 
    lda #0
    ldy.z screenlayer__1
    sty screenlayer__2+1
    sta screenlayer__2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [1397] *((unsigned int *)&__conio+3) = screenlayer::$2 -- _deref_pwuc1=vwum1 
    sta __conio+3
    tya
    sta __conio+3+1
    // config & VERA_LAYER_WIDTH_MASK
    // [1398] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbum1=vbuz2_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and.z config
    sta screenlayer__7
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [1399] screenlayer::$8 = screenlayer::$7 >> 4 -- vbum1=vbum1_ror_4 
    lda screenlayer__8
    lsr
    lsr
    lsr
    lsr
    sta screenlayer__8
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [1400] *((char *)&__conio+8) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbum1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+8
    // config & VERA_LAYER_HEIGHT_MASK
    // [1401] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbuz1=vbuz1_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and.z screenlayer__5
    sta.z screenlayer__5
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [1402] screenlayer::$6 = screenlayer::$5 >> 6 -- vbuz1=vbuz1_ror_6 
    lda.z screenlayer__6
    rol
    rol
    rol
    and #3
    sta.z screenlayer__6
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [1403] *((char *)&__conio+9) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+9
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [1404] screenlayer::$16 = screenlayer::$8 << 1 -- vbum1=vbum1_rol_1 
    asl screenlayer__16
    // [1405] *((unsigned int *)&__conio+$a) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbum1 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    ldy screenlayer__16
    lda VERA_LAYER_SKIP,y
    sta __conio+$a
    lda VERA_LAYER_SKIP+1,y
    sta __conio+$a+1
    // vera_dc_hscale_temp == 0x80
    // [1406] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vbom1=vbum2_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta screenlayer__9
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [1407] screenlayer::$18 = (char)screenlayer::$9
    // [1408] screenlayer::$10 = $28 << screenlayer::$18 -- vbum1=vbuc1_rol_vbum1 
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
    // [1409] screenlayer::$11 = screenlayer::$10 - 1 -- vbum1=vbum1_minus_1 
    dec screenlayer__11
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [1410] *((char *)&__conio+6) = screenlayer::$11 -- _deref_pbuc1=vbum1 
    lda screenlayer__11
    sta __conio+6
    // vera_dc_vscale_temp == 0x80
    // [1411] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vbom1=vbum2_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta screenlayer__12
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [1412] screenlayer::$19 = (char)screenlayer::$12
    // [1413] screenlayer::$13 = $1e << screenlayer::$19 -- vbum1=vbuc1_rol_vbum1 
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
    // [1414] screenlayer::$14 = screenlayer::$13 - 1 -- vbum1=vbum1_minus_1 
    dec screenlayer__14
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1415] *((char *)&__conio+7) = screenlayer::$14 -- _deref_pbuc1=vbum1 
    lda screenlayer__14
    sta __conio+7
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [1416] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta mapbase_offset
    lda __conio+3+1
    sta mapbase_offset+1
    // [1417] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [1417] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [1417] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [1418] if(screenlayer::y#2<=*((char *)&__conio+7)) goto screenlayer::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+7
    cmp.z y
    bcs __b2
    // screenlayer::@return
    // }
    // [1419] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [1420] screenlayer::$17 = screenlayer::y#2 << 1 -- vbum1=vbuz2_rol_1 
    lda.z y
    asl
    sta screenlayer__17
    // [1421] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbum1=vwum2 
    tay
    lda mapbase_offset
    sta __conio+$15,y
    lda mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [1422] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda mapbase_offset
    adc __conio+$a
    sta mapbase_offset
    lda mapbase_offset+1
    adc __conio+$a+1
    sta mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [1423] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [1417] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [1417] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [1417] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
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
    // [1424] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [1425] if(0!=((char *)&__conio+$f)[*((char *)&__conio+2)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [1426] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // [1427] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [1428] call gotoxy
    // [486] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [486] phi gotoxy::y#29 = 0 [phi:cscroll::@3->gotoxy#0] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.y
    // [486] phi gotoxy::x#29 = 0 [phi:cscroll::@3->gotoxy#1] -- vbuz1=vbuc1 
    sta.z gotoxy.x
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [1429] return 
    rts
    // [1430] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [1431] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [1432] gotoxy::y#3 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
    lda __conio+7
    sta.z gotoxy.y
    // [1433] call gotoxy
    // [486] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [486] phi gotoxy::y#29 = gotoxy::y#3 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [486] phi gotoxy::x#29 = 0 [phi:cscroll::@5->gotoxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.x
    jsr gotoxy
    // [1434] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [1435] call clearline
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
    // [1436] ((char *)&__conio+$f)[*((char *)&__conio+2)] = scroll::onoff#0 -- pbuc1_derefidx_(_deref_pbuc2)=vbuc3 
    lda #onoff
    ldy __conio+2
    sta __conio+$f,y
    // scroll::@return
    // }
    // [1437] return 
    rts
}
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    .label line_text = $6e
    .label ch = $6e
    // unsigned int line_text = __conio.mapbase_offset
    // [1438] clrscr::line_text#0 = *((unsigned int *)&__conio+3) -- vwuz1=_deref_pwuc1 
    lda __conio+3
    sta.z line_text
    lda __conio+3+1
    sta.z line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1439] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [1440] clrscr::$0 = *((char *)&__conio+5) | VERA_INC_1 -- vbum1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta clrscr__0
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1441] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [1442] clrscr::l#0 = *((char *)&__conio+9) -- vbum1=_deref_pbuc1 
    lda __conio+9
    sta l
    // [1443] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [1443] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [1443] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [1444] clrscr::$1 = byte0  clrscr::ch#0 -- vbum1=_byte0_vwuz2 
    lda.z ch
    sta clrscr__1
    // *VERA_ADDRX_L = BYTE0(ch)
    // [1445] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbum1 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [1446] clrscr::$2 = byte1  clrscr::ch#0 -- vbum1=_byte1_vwuz2 
    lda.z ch+1
    sta clrscr__2
    // *VERA_ADDRX_M = BYTE1(ch)
    // [1447] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth+1
    // [1448] clrscr::c#0 = *((char *)&__conio+8) + 1 -- vbum1=_deref_pbuc1_plus_1 
    lda __conio+8
    inc
    sta c
    // [1449] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [1449] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [1450] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1451] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [1452] clrscr::c#1 = -- clrscr::c#2 -- vbum1=_dec_vbum1 
    dec c
    // while(c)
    // [1453] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [1454] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+$a) -- vwuz1=vwuz1_plus__deref_pwuc1 
    clc
    lda.z line_text
    adc __conio+$a
    sta.z line_text
    lda.z line_text+1
    adc __conio+$a+1
    sta.z line_text+1
    // l--;
    // [1455] clrscr::l#1 = -- clrscr::l#4 -- vbum1=_dec_vbum1 
    dec l
    // while(l)
    // [1456] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbum1_then_la1 
    lda l
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [1457] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y = 0
    // [1458] *((char *)&__conio+1) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+1
    // __conio.offset = __conio.mapbase_offset
    // [1459] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+3) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+3
    sta __conio+$13
    lda __conio+3+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [1460] return 
    rts
  .segment Data
    .label clrscr__0 = frame.w
    .label clrscr__1 = frame.h
    .label clrscr__2 = info_clear.y
    .label l = main.check_roms1_check_rom1_main__0
    .label c = main.check_rom1_main__0
}
.segment Code
  // frame
// Draw a line horizontal from a given xy position and a given length.
// The line should calculate the matching characters to draw and glue them.
// So it first needs to peek the characters at the given position.
// And then calculate the resulting characters to draw.
// void frame(char x0, char y0, __zp($d9) char x1, __zp($e4) char y1)
frame: {
    .label x = $d5
    .label y = $66
    .label c = $6c
    .label x_1 = $6d
    .label y_1 = $de
    .label x1 = $d9
    .label y1 = $e4
    // unsigned char w = x1 - x0
    // [1462] frame::w#0 = frame::x1#16 - frame::x#0 -- vbum1=vbuz2_minus_vbuz3 
    lda.z x1
    sec
    sbc.z x
    sta w
    // unsigned char h = y1 - y0
    // [1463] frame::h#0 = frame::y1#16 - frame::y#0 -- vbum1=vbuz2_minus_vbuz3 
    lda.z y1
    sec
    sbc.z y
    sta h
    // unsigned char mask = frame_maskxy(x, y)
    // [1464] frame_maskxy::x#0 = frame::x#0 -- vbum1=vbuz2 
    lda.z x
    sta frame_maskxy.x
    // [1465] frame_maskxy::y#0 = frame::y#0 -- vbum1=vbuz2 
    lda.z y
    sta frame_maskxy.y
    // [1466] call frame_maskxy
    // [2120] phi from frame to frame_maskxy [phi:frame->frame_maskxy]
    // [2120] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#0 [phi:frame->frame_maskxy#0] -- register_copy 
    // [2120] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#0 [phi:frame->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // unsigned char mask = frame_maskxy(x, y)
    // [1467] frame_maskxy::return#13 = frame_maskxy::return#12
    // frame::@13
    // [1468] frame::mask#0 = frame_maskxy::return#13
    // mask |= 0b0110
    // [1469] frame::mask#1 = frame::mask#0 | 6 -- vbum1=vbum1_bor_vbuc1 
    lda #6
    ora mask
    sta mask
    // unsigned char c = frame_char(mask)
    // [1470] frame_char::mask#0 = frame::mask#1
    // [1471] call frame_char
  // Add a corner.
    // [2146] phi from frame::@13 to frame_char [phi:frame::@13->frame_char]
    // [2146] phi frame_char::mask#10 = frame_char::mask#0 [phi:frame::@13->frame_char#0] -- register_copy 
    jsr frame_char
    // unsigned char c = frame_char(mask)
    // [1472] frame_char::return#13 = frame_char::return#12
    // frame::@14
    // [1473] frame::c#0 = frame_char::return#13
    // cputcxy(x, y, c)
    // [1474] cputcxy::x#0 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1475] cputcxy::y#0 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [1476] cputcxy::c#0 = frame::c#0
    // [1477] call cputcxy
    // [1595] phi from frame::@14 to cputcxy [phi:frame::@14->cputcxy]
    // [1595] phi cputcxy::c#13 = cputcxy::c#0 [phi:frame::@14->cputcxy#0] -- register_copy 
    // [1595] phi cputcxy::y#13 = cputcxy::y#0 [phi:frame::@14->cputcxy#1] -- register_copy 
    // [1595] phi cputcxy::x#13 = cputcxy::x#0 [phi:frame::@14->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@15
    // if(w>=2)
    // [1478] if(frame::w#0<2) goto frame::@36 -- vbum1_lt_vbuc1_then_la1 
    lda w
    cmp #2
    bcs !__b36+
    jmp __b36
  !__b36:
    // frame::@2
    // x++;
    // [1479] frame::x#1 = ++ frame::x#0 -- vbuz1=_inc_vbuz2 
    lda.z x
    inc
    sta.z x_1
    // [1480] phi from frame::@2 frame::@21 to frame::@4 [phi:frame::@2/frame::@21->frame::@4]
    // [1480] phi frame::x#10 = frame::x#1 [phi:frame::@2/frame::@21->frame::@4#0] -- register_copy 
    // frame::@4
  __b4:
    // while(x < x1)
    // [1481] if(frame::x#10<frame::x1#16) goto frame::@5 -- vbuz1_lt_vbuz2_then_la1 
    lda.z x_1
    cmp.z x1
    bcs !__b5+
    jmp __b5
  !__b5:
    // [1482] phi from frame::@36 frame::@4 to frame::@1 [phi:frame::@36/frame::@4->frame::@1]
    // [1482] phi frame::x#24 = frame::x#30 [phi:frame::@36/frame::@4->frame::@1#0] -- register_copy 
    // frame::@1
  __b1:
    // frame_maskxy(x, y)
    // [1483] frame_maskxy::x#1 = frame::x#24 -- vbum1=vbuz2 
    lda.z x_1
    sta frame_maskxy.x
    // [1484] frame_maskxy::y#1 = frame::y#0 -- vbum1=vbuz2 
    lda.z y
    sta frame_maskxy.y
    // [1485] call frame_maskxy
    // [2120] phi from frame::@1 to frame_maskxy [phi:frame::@1->frame_maskxy]
    // [2120] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#1 [phi:frame::@1->frame_maskxy#0] -- register_copy 
    // [2120] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#1 [phi:frame::@1->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [1486] frame_maskxy::return#14 = frame_maskxy::return#12
    // frame::@16
    // mask = frame_maskxy(x, y)
    // [1487] frame::mask#2 = frame_maskxy::return#14
    // mask |= 0b0011
    // [1488] frame::mask#3 = frame::mask#2 | 3 -- vbum1=vbum1_bor_vbuc1 
    lda #3
    ora mask
    sta mask
    // frame_char(mask)
    // [1489] frame_char::mask#1 = frame::mask#3
    // [1490] call frame_char
    // [2146] phi from frame::@16 to frame_char [phi:frame::@16->frame_char]
    // [2146] phi frame_char::mask#10 = frame_char::mask#1 [phi:frame::@16->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1491] frame_char::return#14 = frame_char::return#12
    // frame::@17
    // c = frame_char(mask)
    // [1492] frame::c#1 = frame_char::return#14
    // cputcxy(x, y, c)
    // [1493] cputcxy::x#1 = frame::x#24 -- vbuz1=vbuz2 
    lda.z x_1
    sta.z cputcxy.x
    // [1494] cputcxy::y#1 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [1495] cputcxy::c#1 = frame::c#1
    // [1496] call cputcxy
    // [1595] phi from frame::@17 to cputcxy [phi:frame::@17->cputcxy]
    // [1595] phi cputcxy::c#13 = cputcxy::c#1 [phi:frame::@17->cputcxy#0] -- register_copy 
    // [1595] phi cputcxy::y#13 = cputcxy::y#1 [phi:frame::@17->cputcxy#1] -- register_copy 
    // [1595] phi cputcxy::x#13 = cputcxy::x#1 [phi:frame::@17->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@18
    // if(h>=2)
    // [1497] if(frame::h#0<2) goto frame::@return -- vbum1_lt_vbuc1_then_la1 
    lda h
    cmp #2
    bcc __breturn
    // frame::@3
    // y++;
    // [1498] frame::y#1 = ++ frame::y#0 -- vbuz1=_inc_vbuz2 
    lda.z y
    inc
    sta.z y_1
    // [1499] phi from frame::@27 frame::@3 to frame::@6 [phi:frame::@27/frame::@3->frame::@6]
    // [1499] phi frame::y#10 = frame::y#2 [phi:frame::@27/frame::@3->frame::@6#0] -- register_copy 
    // frame::@6
  __b6:
    // while(y < y1)
    // [1500] if(frame::y#10<frame::y1#16) goto frame::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z y_1
    cmp.z y1
    bcc __b7
    // frame::@8
    // frame_maskxy(x, y)
    // [1501] frame_maskxy::x#5 = frame::x#0 -- vbum1=vbuz2 
    lda.z x
    sta frame_maskxy.x
    // [1502] frame_maskxy::y#5 = frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta frame_maskxy.y
    // [1503] call frame_maskxy
    // [2120] phi from frame::@8 to frame_maskxy [phi:frame::@8->frame_maskxy]
    // [2120] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#5 [phi:frame::@8->frame_maskxy#0] -- register_copy 
    // [2120] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#5 [phi:frame::@8->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [1504] frame_maskxy::return#18 = frame_maskxy::return#12
    // frame::@28
    // mask = frame_maskxy(x, y)
    // [1505] frame::mask#10 = frame_maskxy::return#18
    // mask |= 0b1100
    // [1506] frame::mask#11 = frame::mask#10 | $c -- vbum1=vbum1_bor_vbuc1 
    lda #$c
    ora mask
    sta mask
    // frame_char(mask)
    // [1507] frame_char::mask#5 = frame::mask#11
    // [1508] call frame_char
    // [2146] phi from frame::@28 to frame_char [phi:frame::@28->frame_char]
    // [2146] phi frame_char::mask#10 = frame_char::mask#5 [phi:frame::@28->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1509] frame_char::return#18 = frame_char::return#12
    // frame::@29
    // c = frame_char(mask)
    // [1510] frame::c#5 = frame_char::return#18
    // cputcxy(x, y, c)
    // [1511] cputcxy::x#5 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1512] cputcxy::y#5 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1513] cputcxy::c#5 = frame::c#5
    // [1514] call cputcxy
    // [1595] phi from frame::@29 to cputcxy [phi:frame::@29->cputcxy]
    // [1595] phi cputcxy::c#13 = cputcxy::c#5 [phi:frame::@29->cputcxy#0] -- register_copy 
    // [1595] phi cputcxy::y#13 = cputcxy::y#5 [phi:frame::@29->cputcxy#1] -- register_copy 
    // [1595] phi cputcxy::x#13 = cputcxy::x#5 [phi:frame::@29->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@30
    // if(w>=2)
    // [1515] if(frame::w#0<2) goto frame::@10 -- vbum1_lt_vbuc1_then_la1 
    lda w
    cmp #2
    bcc __b10
    // frame::@9
    // x++;
    // [1516] frame::x#4 = ++ frame::x#0 -- vbuz1=_inc_vbuz1 
    inc.z x
    // [1517] phi from frame::@35 frame::@9 to frame::@11 [phi:frame::@35/frame::@9->frame::@11]
    // [1517] phi frame::x#18 = frame::x#5 [phi:frame::@35/frame::@9->frame::@11#0] -- register_copy 
    // frame::@11
  __b11:
    // while(x < x1)
    // [1518] if(frame::x#18<frame::x1#16) goto frame::@12 -- vbuz1_lt_vbuz2_then_la1 
    lda.z x
    cmp.z x1
    bcc __b12
    // [1519] phi from frame::@11 frame::@30 to frame::@10 [phi:frame::@11/frame::@30->frame::@10]
    // [1519] phi frame::x#15 = frame::x#18 [phi:frame::@11/frame::@30->frame::@10#0] -- register_copy 
    // frame::@10
  __b10:
    // frame_maskxy(x, y)
    // [1520] frame_maskxy::x#6 = frame::x#15 -- vbum1=vbuz2 
    lda.z x
    sta frame_maskxy.x
    // [1521] frame_maskxy::y#6 = frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta frame_maskxy.y
    // [1522] call frame_maskxy
    // [2120] phi from frame::@10 to frame_maskxy [phi:frame::@10->frame_maskxy]
    // [2120] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#6 [phi:frame::@10->frame_maskxy#0] -- register_copy 
    // [2120] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#6 [phi:frame::@10->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [1523] frame_maskxy::return#19 = frame_maskxy::return#12
    // frame::@31
    // mask = frame_maskxy(x, y)
    // [1524] frame::mask#12 = frame_maskxy::return#19
    // mask |= 0b1001
    // [1525] frame::mask#13 = frame::mask#12 | 9 -- vbum1=vbum1_bor_vbuc1 
    lda #9
    ora mask
    sta mask
    // frame_char(mask)
    // [1526] frame_char::mask#6 = frame::mask#13
    // [1527] call frame_char
    // [2146] phi from frame::@31 to frame_char [phi:frame::@31->frame_char]
    // [2146] phi frame_char::mask#10 = frame_char::mask#6 [phi:frame::@31->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1528] frame_char::return#19 = frame_char::return#12
    // frame::@32
    // c = frame_char(mask)
    // [1529] frame::c#6 = frame_char::return#19
    // cputcxy(x, y, c)
    // [1530] cputcxy::x#6 = frame::x#15 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1531] cputcxy::y#6 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1532] cputcxy::c#6 = frame::c#6
    // [1533] call cputcxy
    // [1595] phi from frame::@32 to cputcxy [phi:frame::@32->cputcxy]
    // [1595] phi cputcxy::c#13 = cputcxy::c#6 [phi:frame::@32->cputcxy#0] -- register_copy 
    // [1595] phi cputcxy::y#13 = cputcxy::y#6 [phi:frame::@32->cputcxy#1] -- register_copy 
    // [1595] phi cputcxy::x#13 = cputcxy::x#6 [phi:frame::@32->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@return
  __breturn:
    // }
    // [1534] return 
    rts
    // frame::@12
  __b12:
    // frame_maskxy(x, y)
    // [1535] frame_maskxy::x#7 = frame::x#18 -- vbum1=vbuz2 
    lda.z x
    sta frame_maskxy.x
    // [1536] frame_maskxy::y#7 = frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta frame_maskxy.y
    // [1537] call frame_maskxy
    // [2120] phi from frame::@12 to frame_maskxy [phi:frame::@12->frame_maskxy]
    // [2120] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#7 [phi:frame::@12->frame_maskxy#0] -- register_copy 
    // [2120] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#7 [phi:frame::@12->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [1538] frame_maskxy::return#20 = frame_maskxy::return#12
    // frame::@33
    // mask = frame_maskxy(x, y)
    // [1539] frame::mask#14 = frame_maskxy::return#20
    // mask |= 0b0101
    // [1540] frame::mask#15 = frame::mask#14 | 5 -- vbum1=vbum1_bor_vbuc1 
    lda #5
    ora mask
    sta mask
    // frame_char(mask)
    // [1541] frame_char::mask#7 = frame::mask#15
    // [1542] call frame_char
    // [2146] phi from frame::@33 to frame_char [phi:frame::@33->frame_char]
    // [2146] phi frame_char::mask#10 = frame_char::mask#7 [phi:frame::@33->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1543] frame_char::return#20 = frame_char::return#12
    // frame::@34
    // c = frame_char(mask)
    // [1544] frame::c#7 = frame_char::return#20
    // cputcxy(x, y, c)
    // [1545] cputcxy::x#7 = frame::x#18 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1546] cputcxy::y#7 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1547] cputcxy::c#7 = frame::c#7
    // [1548] call cputcxy
    // [1595] phi from frame::@34 to cputcxy [phi:frame::@34->cputcxy]
    // [1595] phi cputcxy::c#13 = cputcxy::c#7 [phi:frame::@34->cputcxy#0] -- register_copy 
    // [1595] phi cputcxy::y#13 = cputcxy::y#7 [phi:frame::@34->cputcxy#1] -- register_copy 
    // [1595] phi cputcxy::x#13 = cputcxy::x#7 [phi:frame::@34->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@35
    // x++;
    // [1549] frame::x#5 = ++ frame::x#18 -- vbuz1=_inc_vbuz1 
    inc.z x
    jmp __b11
    // frame::@7
  __b7:
    // frame_maskxy(x0, y)
    // [1550] frame_maskxy::x#3 = frame::x#0 -- vbum1=vbuz2 
    lda.z x
    sta frame_maskxy.x
    // [1551] frame_maskxy::y#3 = frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta frame_maskxy.y
    // [1552] call frame_maskxy
    // [2120] phi from frame::@7 to frame_maskxy [phi:frame::@7->frame_maskxy]
    // [2120] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#3 [phi:frame::@7->frame_maskxy#0] -- register_copy 
    // [2120] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#3 [phi:frame::@7->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x0, y)
    // [1553] frame_maskxy::return#16 = frame_maskxy::return#12
    // frame::@22
    // mask = frame_maskxy(x0, y)
    // [1554] frame::mask#6 = frame_maskxy::return#16
    // mask |= 0b1010
    // [1555] frame::mask#7 = frame::mask#6 | $a -- vbum1=vbum1_bor_vbuc1 
    lda #$a
    ora mask
    sta mask
    // frame_char(mask)
    // [1556] frame_char::mask#3 = frame::mask#7
    // [1557] call frame_char
    // [2146] phi from frame::@22 to frame_char [phi:frame::@22->frame_char]
    // [2146] phi frame_char::mask#10 = frame_char::mask#3 [phi:frame::@22->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1558] frame_char::return#16 = frame_char::return#12
    // frame::@23
    // c = frame_char(mask)
    // [1559] frame::c#3 = frame_char::return#16
    // cputcxy(x0, y, c)
    // [1560] cputcxy::x#3 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1561] cputcxy::y#3 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1562] cputcxy::c#3 = frame::c#3
    // [1563] call cputcxy
    // [1595] phi from frame::@23 to cputcxy [phi:frame::@23->cputcxy]
    // [1595] phi cputcxy::c#13 = cputcxy::c#3 [phi:frame::@23->cputcxy#0] -- register_copy 
    // [1595] phi cputcxy::y#13 = cputcxy::y#3 [phi:frame::@23->cputcxy#1] -- register_copy 
    // [1595] phi cputcxy::x#13 = cputcxy::x#3 [phi:frame::@23->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@24
    // frame_maskxy(x1, y)
    // [1564] frame_maskxy::x#4 = frame::x1#16 -- vbum1=vbuz2 
    lda.z x1
    sta frame_maskxy.x
    // [1565] frame_maskxy::y#4 = frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta frame_maskxy.y
    // [1566] call frame_maskxy
    // [2120] phi from frame::@24 to frame_maskxy [phi:frame::@24->frame_maskxy]
    // [2120] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#4 [phi:frame::@24->frame_maskxy#0] -- register_copy 
    // [2120] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#4 [phi:frame::@24->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x1, y)
    // [1567] frame_maskxy::return#17 = frame_maskxy::return#12
    // frame::@25
    // mask = frame_maskxy(x1, y)
    // [1568] frame::mask#8 = frame_maskxy::return#17
    // mask |= 0b1010
    // [1569] frame::mask#9 = frame::mask#8 | $a -- vbum1=vbum1_bor_vbuc1 
    lda #$a
    ora mask
    sta mask
    // frame_char(mask)
    // [1570] frame_char::mask#4 = frame::mask#9
    // [1571] call frame_char
    // [2146] phi from frame::@25 to frame_char [phi:frame::@25->frame_char]
    // [2146] phi frame_char::mask#10 = frame_char::mask#4 [phi:frame::@25->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1572] frame_char::return#17 = frame_char::return#12
    // frame::@26
    // c = frame_char(mask)
    // [1573] frame::c#4 = frame_char::return#17
    // cputcxy(x1, y, c)
    // [1574] cputcxy::x#4 = frame::x1#16 -- vbuz1=vbuz2 
    lda.z x1
    sta.z cputcxy.x
    // [1575] cputcxy::y#4 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [1576] cputcxy::c#4 = frame::c#4
    // [1577] call cputcxy
    // [1595] phi from frame::@26 to cputcxy [phi:frame::@26->cputcxy]
    // [1595] phi cputcxy::c#13 = cputcxy::c#4 [phi:frame::@26->cputcxy#0] -- register_copy 
    // [1595] phi cputcxy::y#13 = cputcxy::y#4 [phi:frame::@26->cputcxy#1] -- register_copy 
    // [1595] phi cputcxy::x#13 = cputcxy::x#4 [phi:frame::@26->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@27
    // y++;
    // [1578] frame::y#2 = ++ frame::y#10 -- vbuz1=_inc_vbuz1 
    inc.z y_1
    jmp __b6
    // frame::@5
  __b5:
    // frame_maskxy(x, y)
    // [1579] frame_maskxy::x#2 = frame::x#10 -- vbum1=vbuz2 
    lda.z x_1
    sta frame_maskxy.x
    // [1580] frame_maskxy::y#2 = frame::y#0 -- vbum1=vbuz2 
    lda.z y
    sta frame_maskxy.y
    // [1581] call frame_maskxy
    // [2120] phi from frame::@5 to frame_maskxy [phi:frame::@5->frame_maskxy]
    // [2120] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#2 [phi:frame::@5->frame_maskxy#0] -- register_copy 
    // [2120] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#2 [phi:frame::@5->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [1582] frame_maskxy::return#15 = frame_maskxy::return#12
    // frame::@19
    // mask = frame_maskxy(x, y)
    // [1583] frame::mask#4 = frame_maskxy::return#15
    // mask |= 0b0101
    // [1584] frame::mask#5 = frame::mask#4 | 5 -- vbum1=vbum1_bor_vbuc1 
    lda #5
    ora mask
    sta mask
    // frame_char(mask)
    // [1585] frame_char::mask#2 = frame::mask#5
    // [1586] call frame_char
    // [2146] phi from frame::@19 to frame_char [phi:frame::@19->frame_char]
    // [2146] phi frame_char::mask#10 = frame_char::mask#2 [phi:frame::@19->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1587] frame_char::return#15 = frame_char::return#12
    // frame::@20
    // c = frame_char(mask)
    // [1588] frame::c#2 = frame_char::return#15
    // cputcxy(x, y, c)
    // [1589] cputcxy::x#2 = frame::x#10 -- vbuz1=vbuz2 
    lda.z x_1
    sta.z cputcxy.x
    // [1590] cputcxy::y#2 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [1591] cputcxy::c#2 = frame::c#2
    // [1592] call cputcxy
    // [1595] phi from frame::@20 to cputcxy [phi:frame::@20->cputcxy]
    // [1595] phi cputcxy::c#13 = cputcxy::c#2 [phi:frame::@20->cputcxy#0] -- register_copy 
    // [1595] phi cputcxy::y#13 = cputcxy::y#2 [phi:frame::@20->cputcxy#1] -- register_copy 
    // [1595] phi cputcxy::x#13 = cputcxy::x#2 [phi:frame::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@21
    // x++;
    // [1593] frame::x#2 = ++ frame::x#10 -- vbuz1=_inc_vbuz1 
    inc.z x_1
    jmp __b4
    // frame::@36
  __b36:
    // [1594] frame::x#30 = frame::x#0 -- vbuz1=vbuz2 
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
// void cputcxy(__zp($67) char x, __zp($65) char y, __zp($6c) char c)
cputcxy: {
    .label x = $67
    .label y = $65
    .label c = $6c
    // gotoxy(x, y)
    // [1596] gotoxy::x#0 = cputcxy::x#13 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1597] gotoxy::y#0 = cputcxy::y#13 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1598] call gotoxy
    // [486] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [486] phi gotoxy::y#29 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [486] phi gotoxy::x#29 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [1599] stackpush(char) = cputcxy::c#13 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [1600] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [1602] return 
    rts
}
  // info_clear
// void info_clear(__mem() char l)
info_clear: {
    .const w = $40+1
    .label x = $6b
    .label i = $68
    // unsigned char y = INFO_Y+l
    // [1603] info_clear::y#0 = $11 + info_clear::l#0 -- vbum1=vbuc1_plus_vbum2 
    lda #$11
    clc
    adc l
    sta y
    // [1604] phi from info_clear to info_clear::@1 [phi:info_clear->info_clear::@1]
    // [1604] phi info_clear::x#2 = 2 [phi:info_clear->info_clear::@1#0] -- vbuz1=vbuc1 
    lda #2
    sta.z x
    // [1604] phi info_clear::i#2 = 0 [phi:info_clear->info_clear::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // info_clear::@1
  __b1:
    // for(unsigned char i = 0; i < w-16; i++)
    // [1605] if(info_clear::i#2<info_clear::w-$10) goto info_clear::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z i
    cmp #w-$10
    bcc __b2
    // info_clear::@3
    // gotoxy(INFO_X, y)
    // [1606] gotoxy::y#14 = info_clear::y#0 -- vbuz1=vbum2 
    lda y
    sta.z gotoxy.y
    // [1607] call gotoxy
    // [486] phi from info_clear::@3 to gotoxy [phi:info_clear::@3->gotoxy]
    // [486] phi gotoxy::y#29 = gotoxy::y#14 [phi:info_clear::@3->gotoxy#0] -- register_copy 
    // [486] phi gotoxy::x#29 = 2 [phi:info_clear::@3->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // info_clear::@return
    // }
    // [1608] return 
    rts
    // info_clear::@2
  __b2:
    // cputcxy(x, y, ' ')
    // [1609] cputcxy::x#10 = info_clear::x#2 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1610] cputcxy::y#10 = info_clear::y#0 -- vbuz1=vbum2 
    lda y
    sta.z cputcxy.y
    // [1611] call cputcxy
    // [1595] phi from info_clear::@2 to cputcxy [phi:info_clear::@2->cputcxy]
    // [1595] phi cputcxy::c#13 = ' ' [phi:info_clear::@2->cputcxy#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z cputcxy.c
    // [1595] phi cputcxy::y#13 = cputcxy::y#10 [phi:info_clear::@2->cputcxy#1] -- register_copy 
    // [1595] phi cputcxy::x#13 = cputcxy::x#10 [phi:info_clear::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // info_clear::@4
    // x++;
    // [1612] info_clear::x#1 = ++ info_clear::x#2 -- vbuz1=_inc_vbuz1 
    inc.z x
    // for(unsigned char i = 0; i < w-16; i++)
    // [1613] info_clear::i#1 = ++ info_clear::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1604] phi from info_clear::@4 to info_clear::@1 [phi:info_clear::@4->info_clear::@1]
    // [1604] phi info_clear::x#2 = info_clear::x#1 [phi:info_clear::@4->info_clear::@1#0] -- register_copy 
    // [1604] phi info_clear::i#2 = info_clear::i#1 [phi:info_clear::@4->info_clear::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    y: .byte 0
    .label l = main.check_smc3_main__0
}
.segment Code
  // wherex
// Return the x position of the cursor
wherex: {
    .label return = $24
    .label return_1 = $e2
    // return __conio.cursor_x;
    // [1614] wherex::return#0 = *((char *)&__conio) -- vbuz1=_deref_pbuc1 
    lda __conio
    sta.z return
    // wherex::@return
    // }
    // [1615] return 
    rts
}
  // wherey
// Return the y position of the cursor
wherey: {
    .label return = $df
    .label return_1 = $e0
    // return __conio.cursor_y;
    // [1616] wherey::return#0 = *((char *)&__conio+1) -- vbuz1=_deref_pbuc1 
    lda __conio+1
    sta.z return
    // wherey::@return
    // }
    // [1617] return 
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
    // [1618] cx16_k_i2c_read_byte::result = 0 -- vwum1=vwuc1 
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
    // [1620] cx16_k_i2c_read_byte::return#0 = cx16_k_i2c_read_byte::result -- vwuz1=vwum2 
    sta.z return
    lda result+1
    sta.z return+1
    // cx16_k_i2c_read_byte::@return
    // }
    // [1621] cx16_k_i2c_read_byte::return#1 = cx16_k_i2c_read_byte::return#0
    // [1622] return 
    rts
  .segment Data
    device: .byte 0
    offset: .byte 0
    result: .word 0
}
.segment Code
  // print_smc_led
// void print_smc_led(__zp($4f) char c)
print_smc_led: {
    .label c = $4f
    // print_chip_led(CHIP_SMC_X+1, CHIP_SMC_Y, CHIP_SMC_W, c, BLUE)
    // [1624] print_chip_led::tc#0 = print_smc_led::c#2
    // [1625] call print_chip_led
    // [2161] phi from print_smc_led to print_chip_led [phi:print_smc_led->print_chip_led]
    // [2161] phi print_chip_led::w#5 = 5 [phi:print_smc_led->print_chip_led#0] -- vbuz1=vbuc1 
    lda #5
    sta.z print_chip_led.w
    // [2161] phi print_chip_led::tc#3 = print_chip_led::tc#0 [phi:print_smc_led->print_chip_led#1] -- register_copy 
    // [2161] phi print_chip_led::x#3 = 1+1 [phi:print_smc_led->print_chip_led#2] -- vbuz1=vbuc1 
    lda #1+1
    sta.z print_chip_led.x
    jsr print_chip_led
    // print_smc_led::@return
    // }
    // [1626] return 
    rts
}
  // print_chip
// void print_chip(__zp($b5) char x, char y, __zp($60) char w, __zp($3f) char *text)
print_chip: {
    .label y = 3+1+1+1+1+1+1+1+1+1
    .label text = $3f
    .label text_1 = $54
    .label x = $b5
    .label text_2 = $49
    .label text_6 = $70
    .label w = $60
    // print_chip_line(x, y++, w, *text++)
    // [1628] print_chip_line::x#0 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1629] print_chip_line::w#0 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1630] print_chip_line::c#0 = *print_chip::text#11 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_2),y
    sta.z print_chip_line.c
    // [1631] call print_chip_line
    // [2179] phi from print_chip to print_chip_line [phi:print_chip->print_chip_line]
    // [2179] phi print_chip_line::c#15 = print_chip_line::c#0 [phi:print_chip->print_chip_line#0] -- register_copy 
    // [2179] phi print_chip_line::w#10 = print_chip_line::w#0 [phi:print_chip->print_chip_line#1] -- register_copy 
    // [2179] phi print_chip_line::y#16 = 3+1 [phi:print_chip->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1
    sta.z print_chip_line.y
    // [2179] phi print_chip_line::x#16 = print_chip_line::x#0 [phi:print_chip->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@1
    // print_chip_line(x, y++, w, *text++);
    // [1632] print_chip::text#0 = ++ print_chip::text#11 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_2
    adc #1
    sta.z text
    lda.z text_2+1
    adc #0
    sta.z text+1
    // print_chip_line(x, y++, w, *text++)
    // [1633] print_chip_line::x#1 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1634] print_chip_line::w#1 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1635] print_chip_line::c#1 = *print_chip::text#0 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text),y
    sta.z print_chip_line.c
    // [1636] call print_chip_line
    // [2179] phi from print_chip::@1 to print_chip_line [phi:print_chip::@1->print_chip_line]
    // [2179] phi print_chip_line::c#15 = print_chip_line::c#1 [phi:print_chip::@1->print_chip_line#0] -- register_copy 
    // [2179] phi print_chip_line::w#10 = print_chip_line::w#1 [phi:print_chip::@1->print_chip_line#1] -- register_copy 
    // [2179] phi print_chip_line::y#16 = ++3+1 [phi:print_chip::@1->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1
    sta.z print_chip_line.y
    // [2179] phi print_chip_line::x#16 = print_chip_line::x#1 [phi:print_chip::@1->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@2
    // print_chip_line(x, y++, w, *text++);
    // [1637] print_chip::text#1 = ++ print_chip::text#0 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text
    adc #1
    sta.z text_1
    lda.z text+1
    adc #0
    sta.z text_1+1
    // print_chip_line(x, y++, w, *text++)
    // [1638] print_chip_line::x#2 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1639] print_chip_line::w#2 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1640] print_chip_line::c#2 = *print_chip::text#1 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_1),y
    sta.z print_chip_line.c
    // [1641] call print_chip_line
    // [2179] phi from print_chip::@2 to print_chip_line [phi:print_chip::@2->print_chip_line]
    // [2179] phi print_chip_line::c#15 = print_chip_line::c#2 [phi:print_chip::@2->print_chip_line#0] -- register_copy 
    // [2179] phi print_chip_line::w#10 = print_chip_line::w#2 [phi:print_chip::@2->print_chip_line#1] -- register_copy 
    // [2179] phi print_chip_line::y#16 = ++++3+1 [phi:print_chip::@2->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1
    sta.z print_chip_line.y
    // [2179] phi print_chip_line::x#16 = print_chip_line::x#2 [phi:print_chip::@2->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@3
    // print_chip_line(x, y++, w, *text++);
    // [1642] print_chip::text#15 = ++ print_chip::text#1 -- pbum1=_inc_pbuz2 
    clc
    lda.z text_1
    adc #1
    sta text_3
    lda.z text_1+1
    adc #0
    sta text_3+1
    // print_chip_line(x, y++, w, *text++)
    // [1643] print_chip_line::x#3 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1644] print_chip_line::w#3 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1645] print_chip_line::c#3 = *print_chip::text#15 -- vbuz1=_deref_pbum2 
    ldy text_3
    sty.z $fe
    ldy text_3+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta.z print_chip_line.c
    // [1646] call print_chip_line
    // [2179] phi from print_chip::@3 to print_chip_line [phi:print_chip::@3->print_chip_line]
    // [2179] phi print_chip_line::c#15 = print_chip_line::c#3 [phi:print_chip::@3->print_chip_line#0] -- register_copy 
    // [2179] phi print_chip_line::w#10 = print_chip_line::w#3 [phi:print_chip::@3->print_chip_line#1] -- register_copy 
    // [2179] phi print_chip_line::y#16 = ++++++3+1 [phi:print_chip::@3->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1+1
    sta.z print_chip_line.y
    // [2179] phi print_chip_line::x#16 = print_chip_line::x#3 [phi:print_chip::@3->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@4
    // print_chip_line(x, y++, w, *text++);
    // [1647] print_chip::text#16 = ++ print_chip::text#15 -- pbum1=_inc_pbum2 
    clc
    lda text_3
    adc #1
    sta text_4
    lda text_3+1
    adc #0
    sta text_4+1
    // print_chip_line(x, y++, w, *text++)
    // [1648] print_chip_line::x#4 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1649] print_chip_line::w#4 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1650] print_chip_line::c#4 = *print_chip::text#16 -- vbuz1=_deref_pbum2 
    ldy text_4
    sty.z $fe
    ldy text_4+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta.z print_chip_line.c
    // [1651] call print_chip_line
    // [2179] phi from print_chip::@4 to print_chip_line [phi:print_chip::@4->print_chip_line]
    // [2179] phi print_chip_line::c#15 = print_chip_line::c#4 [phi:print_chip::@4->print_chip_line#0] -- register_copy 
    // [2179] phi print_chip_line::w#10 = print_chip_line::w#4 [phi:print_chip::@4->print_chip_line#1] -- register_copy 
    // [2179] phi print_chip_line::y#16 = ++++++++3+1 [phi:print_chip::@4->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1+1+1
    sta.z print_chip_line.y
    // [2179] phi print_chip_line::x#16 = print_chip_line::x#4 [phi:print_chip::@4->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@5
    // print_chip_line(x, y++, w, *text++);
    // [1652] print_chip::text#17 = ++ print_chip::text#16 -- pbum1=_inc_pbum2 
    clc
    lda text_4
    adc #1
    sta text_5
    lda text_4+1
    adc #0
    sta text_5+1
    // print_chip_line(x, y++, w, *text++)
    // [1653] print_chip_line::x#5 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1654] print_chip_line::w#5 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1655] print_chip_line::c#5 = *print_chip::text#17 -- vbuz1=_deref_pbum2 
    ldy text_5
    sty.z $fe
    ldy text_5+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta.z print_chip_line.c
    // [1656] call print_chip_line
    // [2179] phi from print_chip::@5 to print_chip_line [phi:print_chip::@5->print_chip_line]
    // [2179] phi print_chip_line::c#15 = print_chip_line::c#5 [phi:print_chip::@5->print_chip_line#0] -- register_copy 
    // [2179] phi print_chip_line::w#10 = print_chip_line::w#5 [phi:print_chip::@5->print_chip_line#1] -- register_copy 
    // [2179] phi print_chip_line::y#16 = ++++++++++3+1 [phi:print_chip::@5->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1+1+1+1
    sta.z print_chip_line.y
    // [2179] phi print_chip_line::x#16 = print_chip_line::x#5 [phi:print_chip::@5->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@6
    // print_chip_line(x, y++, w, *text++);
    // [1657] print_chip::text#18 = ++ print_chip::text#17 -- pbuz1=_inc_pbum2 
    clc
    lda text_5
    adc #1
    sta.z text_6
    lda text_5+1
    adc #0
    sta.z text_6+1
    // print_chip_line(x, y++, w, *text++)
    // [1658] print_chip_line::x#6 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1659] print_chip_line::w#6 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1660] print_chip_line::c#6 = *print_chip::text#18 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta.z print_chip_line.c
    // [1661] call print_chip_line
    // [2179] phi from print_chip::@6 to print_chip_line [phi:print_chip::@6->print_chip_line]
    // [2179] phi print_chip_line::c#15 = print_chip_line::c#6 [phi:print_chip::@6->print_chip_line#0] -- register_copy 
    // [2179] phi print_chip_line::w#10 = print_chip_line::w#6 [phi:print_chip::@6->print_chip_line#1] -- register_copy 
    // [2179] phi print_chip_line::y#16 = ++++++++++++3+1 [phi:print_chip::@6->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1+1+1+1+1
    sta.z print_chip_line.y
    // [2179] phi print_chip_line::x#16 = print_chip_line::x#6 [phi:print_chip::@6->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@7
    // print_chip_line(x, y++, w, *text++);
    // [1662] print_chip::text#19 = ++ print_chip::text#18 -- pbuz1=_inc_pbuz1 
    inc.z text_6
    bne !+
    inc.z text_6+1
  !:
    // print_chip_line(x, y++, w, *text++)
    // [1663] print_chip_line::x#7 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1664] print_chip_line::w#7 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1665] print_chip_line::c#7 = *print_chip::text#19 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta.z print_chip_line.c
    // [1666] call print_chip_line
    // [2179] phi from print_chip::@7 to print_chip_line [phi:print_chip::@7->print_chip_line]
    // [2179] phi print_chip_line::c#15 = print_chip_line::c#7 [phi:print_chip::@7->print_chip_line#0] -- register_copy 
    // [2179] phi print_chip_line::w#10 = print_chip_line::w#7 [phi:print_chip::@7->print_chip_line#1] -- register_copy 
    // [2179] phi print_chip_line::y#16 = ++++++++++++++3+1 [phi:print_chip::@7->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1+1+1+1+1+1
    sta.z print_chip_line.y
    // [2179] phi print_chip_line::x#16 = print_chip_line::x#7 [phi:print_chip::@7->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@8
    // print_chip_end(x, y++, w)
    // [1667] print_chip_end::x#0 = print_chip::x#10
    // [1668] print_chip_end::w#0 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_end.w
    // [1669] call print_chip_end
    jsr print_chip_end
    // print_chip::@return
    // }
    // [1670] return 
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
// void utoa(__zp($2a) unsigned int value, __zp($63) char *buffer, __zp($32) char radix)
utoa: {
    .label utoa__4 = $6a
    .label utoa__10 = $67
    .label utoa__11 = $d5
    .label digit_value = $3f
    .label buffer = $63
    .label digit = $66
    .label value = $2a
    .label radix = $32
    .label started = $6d
    .label max_digits = $b4
    .label digit_values = $5e
    // if(radix==DECIMAL)
    // [1671] if(utoa::radix#0==DECIMAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp.z radix
    beq __b2
    // utoa::@2
    // if(radix==HEXADECIMAL)
    // [1672] if(utoa::radix#0==HEXADECIMAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp.z radix
    beq __b3
    // utoa::@3
    // if(radix==OCTAL)
    // [1673] if(utoa::radix#0==OCTAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp.z radix
    beq __b4
    // utoa::@4
    // if(radix==BINARY)
    // [1674] if(utoa::radix#0==BINARY) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp.z radix
    beq __b5
    // utoa::@5
    // *buffer++ = 'e'
    // [1675] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1676] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1677] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1678] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // utoa::@return
    // }
    // [1679] return 
    rts
    // [1680] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
  __b2:
    // [1680] phi utoa::digit_values#8 = RADIX_DECIMAL_VALUES [phi:utoa->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_DECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES
    sta.z digit_values+1
    // [1680] phi utoa::max_digits#7 = 5 [phi:utoa->utoa::@1#1] -- vbuz1=vbuc1 
    lda #5
    sta.z max_digits
    jmp __b1
    // [1680] phi from utoa::@2 to utoa::@1 [phi:utoa::@2->utoa::@1]
  __b3:
    // [1680] phi utoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES [phi:utoa::@2->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_HEXADECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES
    sta.z digit_values+1
    // [1680] phi utoa::max_digits#7 = 4 [phi:utoa::@2->utoa::@1#1] -- vbuz1=vbuc1 
    lda #4
    sta.z max_digits
    jmp __b1
    // [1680] phi from utoa::@3 to utoa::@1 [phi:utoa::@3->utoa::@1]
  __b4:
    // [1680] phi utoa::digit_values#8 = RADIX_OCTAL_VALUES [phi:utoa::@3->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_OCTAL_VALUES
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES
    sta.z digit_values+1
    // [1680] phi utoa::max_digits#7 = 6 [phi:utoa::@3->utoa::@1#1] -- vbuz1=vbuc1 
    lda #6
    sta.z max_digits
    jmp __b1
    // [1680] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
  __b5:
    // [1680] phi utoa::digit_values#8 = RADIX_BINARY_VALUES [phi:utoa::@4->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_BINARY_VALUES
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES
    sta.z digit_values+1
    // [1680] phi utoa::max_digits#7 = $10 [phi:utoa::@4->utoa::@1#1] -- vbuz1=vbuc1 
    lda #$10
    sta.z max_digits
    // utoa::@1
  __b1:
    // [1681] phi from utoa::@1 to utoa::@6 [phi:utoa::@1->utoa::@6]
    // [1681] phi utoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa::@1->utoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1681] phi utoa::started#2 = 0 [phi:utoa::@1->utoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [1681] phi utoa::value#2 = utoa::value#1 [phi:utoa::@1->utoa::@6#2] -- register_copy 
    // [1681] phi utoa::digit#2 = 0 [phi:utoa::@1->utoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // utoa::@6
  __b6:
    // max_digits-1
    // [1682] utoa::$4 = utoa::max_digits#7 - 1 -- vbuz1=vbuz2_minus_1 
    ldx.z max_digits
    dex
    stx.z utoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1683] if(utoa::digit#2<utoa::$4) goto utoa::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z digit
    cmp.z utoa__4
    bcc __b7
    // utoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1684] utoa::$11 = (char)utoa::value#2 -- vbuz1=_byte_vwuz2 
    lda.z value
    sta.z utoa__11
    // [1685] *utoa::buffer#11 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1686] utoa::buffer#3 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1687] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // utoa::@7
  __b7:
    // unsigned int digit_value = digit_values[digit]
    // [1688] utoa::$10 = utoa::digit#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z digit
    asl
    sta.z utoa__10
    // [1689] utoa::digit_value#0 = utoa::digit_values#8[utoa::$10] -- vwuz1=pwuz2_derefidx_vbuz3 
    tay
    lda (digit_values),y
    sta.z digit_value
    iny
    lda (digit_values),y
    sta.z digit_value+1
    // if (started || value >= digit_value)
    // [1690] if(0!=utoa::started#2) goto utoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // utoa::@12
    // [1691] if(utoa::value#2>=utoa::digit_value#0) goto utoa::@10 -- vwuz1_ge_vwuz2_then_la1 
    lda.z digit_value+1
    cmp.z value+1
    bne !+
    lda.z digit_value
    cmp.z value
    beq __b10
  !:
    bcc __b10
    // [1692] phi from utoa::@12 to utoa::@9 [phi:utoa::@12->utoa::@9]
    // [1692] phi utoa::buffer#14 = utoa::buffer#11 [phi:utoa::@12->utoa::@9#0] -- register_copy 
    // [1692] phi utoa::started#4 = utoa::started#2 [phi:utoa::@12->utoa::@9#1] -- register_copy 
    // [1692] phi utoa::value#6 = utoa::value#2 [phi:utoa::@12->utoa::@9#2] -- register_copy 
    // utoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1693] utoa::digit#1 = ++ utoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1681] phi from utoa::@9 to utoa::@6 [phi:utoa::@9->utoa::@6]
    // [1681] phi utoa::buffer#11 = utoa::buffer#14 [phi:utoa::@9->utoa::@6#0] -- register_copy 
    // [1681] phi utoa::started#2 = utoa::started#4 [phi:utoa::@9->utoa::@6#1] -- register_copy 
    // [1681] phi utoa::value#2 = utoa::value#6 [phi:utoa::@9->utoa::@6#2] -- register_copy 
    // [1681] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@9->utoa::@6#3] -- register_copy 
    jmp __b6
    // utoa::@10
  __b10:
    // utoa_append(buffer++, value, digit_value)
    // [1694] utoa_append::buffer#0 = utoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [1695] utoa_append::value#0 = utoa::value#2
    // [1696] utoa_append::sub#0 = utoa::digit_value#0
    // [1697] call utoa_append
    // [2240] phi from utoa::@10 to utoa_append [phi:utoa::@10->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [1698] utoa_append::return#0 = utoa_append::value#2
    // utoa::@11
    // value = utoa_append(buffer++, value, digit_value)
    // [1699] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [1700] utoa::buffer#4 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1692] phi from utoa::@11 to utoa::@9 [phi:utoa::@11->utoa::@9]
    // [1692] phi utoa::buffer#14 = utoa::buffer#4 [phi:utoa::@11->utoa::@9#0] -- register_copy 
    // [1692] phi utoa::started#4 = 1 [phi:utoa::@11->utoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [1692] phi utoa::value#6 = utoa::value#0 [phi:utoa::@11->utoa::@9#2] -- register_copy 
    jmp __b9
}
  // printf_number_buffer
// Print the contents of the number buffer using a specific format.
// This handles minimum length, zero-filling, and left/right justification from the format
// void printf_number_buffer(__zp($4b) void (*putc)(char), __zp($de) char buffer_sign, char *buffer_digits, __zp($dd) char format_min_length, char format_justify_left, char format_sign_always, __zp($dc) char format_zero_padding, char format_upper_case, char format_radix)
printf_number_buffer: {
    .label printf_number_buffer__19 = $54
    .label putc = $4b
    .label buffer_sign = $de
    .label format_min_length = $dd
    .label format_zero_padding = $dc
    .label len = $d5
    .label padding = $d5
    // if(format.min_length)
    // [1702] if(0==printf_number_buffer::format_min_length#3) goto printf_number_buffer::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b5
    // [1703] phi from printf_number_buffer to printf_number_buffer::@5 [phi:printf_number_buffer->printf_number_buffer::@5]
    // printf_number_buffer::@5
    // strlen(buffer.digits)
    // [1704] call strlen
    // [1982] phi from printf_number_buffer::@5 to strlen [phi:printf_number_buffer::@5->strlen]
    // [1982] phi strlen::str#8 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [1705] strlen::return#3 = strlen::len#2
    // printf_number_buffer::@11
    // [1706] printf_number_buffer::$19 = strlen::return#3
    // signed char len = (signed char)strlen(buffer.digits)
    // [1707] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsz1=_sbyte_vwuz2 
    // There is a minimum length - work out the padding
    lda.z printf_number_buffer__19
    sta.z len
    // if(buffer.sign)
    // [1708] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@10 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b10
    // printf_number_buffer::@6
    // len++;
    // [1709] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsz1=_inc_vbsz1 
    inc.z len
    // [1710] phi from printf_number_buffer::@11 printf_number_buffer::@6 to printf_number_buffer::@10 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10]
    // [1710] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10#0] -- register_copy 
    // printf_number_buffer::@10
  __b10:
    // padding = (signed char)format.min_length - len
    // [1711] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#3 - printf_number_buffer::len#2 -- vbsz1=vbsz2_minus_vbsz1 
    lda.z format_min_length
    sec
    sbc.z padding
    sta.z padding
    // if(padding<0)
    // [1712] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@15 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1714] phi from printf_number_buffer printf_number_buffer::@10 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1]
  __b5:
    // [1714] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [1713] phi from printf_number_buffer::@10 to printf_number_buffer::@15 [phi:printf_number_buffer::@10->printf_number_buffer::@15]
    // printf_number_buffer::@15
    // [1714] phi from printf_number_buffer::@15 to printf_number_buffer::@1 [phi:printf_number_buffer::@15->printf_number_buffer::@1]
    // [1714] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@15->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // printf_number_buffer::@13
    // if(!format.justify_left && !format.zero_padding && padding)
    // [1715] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_zero_padding
    bne __b2
    // printf_number_buffer::@12
    // [1716] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@7 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b7
    jmp __b2
    // printf_number_buffer::@7
  __b7:
    // printf_padding(putc, ' ',(char)padding)
    // [1717] printf_padding::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1718] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1719] call printf_padding
    // [1988] phi from printf_number_buffer::@7 to printf_padding [phi:printf_number_buffer::@7->printf_padding]
    // [1988] phi printf_padding::putc#7 = printf_padding::putc#0 [phi:printf_number_buffer::@7->printf_padding#0] -- register_copy 
    // [1988] phi printf_padding::pad#7 = ' ' [phi:printf_number_buffer::@7->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1988] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@7->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [1720] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b3
    // printf_number_buffer::@8
    // putc(buffer.sign)
    // [1721] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbuz1 
    pha
    // [1722] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall30
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [1724] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbuz1_then_la1 
    lda.z format_zero_padding
    beq __b4
    // printf_number_buffer::@14
    // [1725] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@9 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b9
    jmp __b4
    // printf_number_buffer::@9
  __b9:
    // printf_padding(putc, '0',(char)padding)
    // [1726] printf_padding::putc#1 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1727] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1728] call printf_padding
    // [1988] phi from printf_number_buffer::@9 to printf_padding [phi:printf_number_buffer::@9->printf_padding]
    // [1988] phi printf_padding::putc#7 = printf_padding::putc#1 [phi:printf_number_buffer::@9->printf_padding#0] -- register_copy 
    // [1988] phi printf_padding::pad#7 = '0' [phi:printf_number_buffer::@9->printf_padding#1] -- vbuz1=vbuc1 
    lda #'0'
    sta.z printf_padding.pad
    // [1988] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@9->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // printf_str(putc, buffer.digits)
    // [1729] printf_str::putc#0 = printf_number_buffer::putc#10
    // [1730] call printf_str
    // [630] phi from printf_number_buffer::@4 to printf_str [phi:printf_number_buffer::@4->printf_str]
    // [630] phi printf_str::putc#66 = printf_str::putc#0 [phi:printf_number_buffer::@4->printf_str#0] -- register_copy 
    // [630] phi printf_str::s#66 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@return
    // }
    // [1731] return 
    rts
    // Outside Flow
  icall30:
    jmp (putc)
}
  // print_vera_led
// void print_vera_led(__zp($4f) char c)
print_vera_led: {
    .label c = $4f
    // print_chip_led(CHIP_VERA_X+1, CHIP_VERA_Y, CHIP_VERA_W, c, BLUE)
    // [1733] print_chip_led::tc#1 = print_vera_led::c#2
    // [1734] call print_chip_led
    // [2161] phi from print_vera_led to print_chip_led [phi:print_vera_led->print_chip_led]
    // [2161] phi print_chip_led::w#5 = 8 [phi:print_vera_led->print_chip_led#0] -- vbuz1=vbuc1 
    lda #8
    sta.z print_chip_led.w
    // [2161] phi print_chip_led::tc#3 = print_chip_led::tc#1 [phi:print_vera_led->print_chip_led#1] -- register_copy 
    // [2161] phi print_chip_led::x#3 = 9+1 [phi:print_vera_led->print_chip_led#2] -- vbuz1=vbuc1 
    lda #9+1
    sta.z print_chip_led.x
    jsr print_chip_led
    // print_vera_led::@return
    // }
    // [1735] return 
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
// void rom_unlock(__zp($73) unsigned long address, __zp($a9) char unlock_code)
rom_unlock: {
    .label chip_address = $3b
    .label address = $73
    .label unlock_code = $a9
    // unsigned long chip_address = address & ROM_CHIP_MASK
    // [1737] rom_unlock::chip_address#0 = rom_unlock::address#5 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [1738] rom_write_byte::address#0 = rom_unlock::chip_address#0 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [1739] call rom_write_byte
  // This is a very important operation...
    // [2247] phi from rom_unlock to rom_write_byte [phi:rom_unlock->rom_write_byte]
    // [2247] phi rom_write_byte::value#10 = $aa [phi:rom_unlock->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$aa
    sta.z rom_write_byte.value
    // [2247] phi rom_write_byte::address#4 = rom_write_byte::address#0 [phi:rom_unlock->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@1
    // rom_write_byte(chip_address + 0x02AAA, 0x55)
    // [1740] rom_write_byte::address#1 = rom_unlock::chip_address#0 + $2aaa -- vduz1=vduz2_plus_vwuc1 
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
    // [1741] call rom_write_byte
    // [2247] phi from rom_unlock::@1 to rom_write_byte [phi:rom_unlock::@1->rom_write_byte]
    // [2247] phi rom_write_byte::value#10 = $55 [phi:rom_unlock::@1->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$55
    sta.z rom_write_byte.value
    // [2247] phi rom_write_byte::address#4 = rom_write_byte::address#1 [phi:rom_unlock::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@2
    // rom_write_byte(address, unlock_code)
    // [1742] rom_write_byte::address#2 = rom_unlock::address#5 -- vduz1=vduz2 
    lda.z address
    sta.z rom_write_byte.address
    lda.z address+1
    sta.z rom_write_byte.address+1
    lda.z address+2
    sta.z rom_write_byte.address+2
    lda.z address+3
    sta.z rom_write_byte.address+3
    // [1743] rom_write_byte::value#2 = rom_unlock::unlock_code#5 -- vbuz1=vbuz2 
    lda.z unlock_code
    sta.z rom_write_byte.value
    // [1744] call rom_write_byte
    // [2247] phi from rom_unlock::@2 to rom_write_byte [phi:rom_unlock::@2->rom_write_byte]
    // [2247] phi rom_write_byte::value#10 = rom_write_byte::value#2 [phi:rom_unlock::@2->rom_write_byte#0] -- register_copy 
    // [2247] phi rom_write_byte::address#4 = rom_write_byte::address#2 [phi:rom_unlock::@2->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@return
    // }
    // [1745] return 
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
// __zp($df) char rom_read_byte(__zp($bd) unsigned long address)
rom_read_byte: {
    .label rom_bank1_rom_read_byte__0 = $d5
    .label rom_bank1_rom_read_byte__1 = $67
    .label rom_ptr1_rom_read_byte__0 = $f2
    .label rom_ptr1_rom_read_byte__2 = $f2
    .label rom_bank1_return = $a9
    .label rom_ptr1_return = $f2
    .label return = $df
    .label address = $bd
    // rom_read_byte::rom_bank1
    // BYTE2(address)
    // [1747] rom_read_byte::rom_bank1_$0 = byte2  rom_read_byte::address#2 -- vbuz1=_byte2_vduz2 
    lda.z address+2
    sta.z rom_bank1_rom_read_byte__0
    // BYTE1(address)
    // [1748] rom_read_byte::rom_bank1_$1 = byte1  rom_read_byte::address#2 -- vbuz1=_byte1_vduz2 
    lda.z address+1
    sta.z rom_bank1_rom_read_byte__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [1749] rom_read_byte::rom_bank1_$2 = rom_read_byte::rom_bank1_$0 w= rom_read_byte::rom_bank1_$1 -- vwum1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_read_byte__0
    sta rom_bank1_rom_read_byte__2+1
    lda.z rom_bank1_rom_read_byte__1
    sta rom_bank1_rom_read_byte__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [1750] rom_read_byte::rom_bank1_bank_unshifted#0 = rom_read_byte::rom_bank1_$2 << 2 -- vwum1=vwum1_rol_2 
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [1751] rom_read_byte::rom_bank1_return#0 = byte1  rom_read_byte::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwum2 
    lda rom_bank1_bank_unshifted+1
    sta.z rom_bank1_return
    // rom_read_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [1752] rom_read_byte::rom_ptr1_$2 = (unsigned int)rom_read_byte::address#2 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_read_byte__2
    lda.z address+1
    sta.z rom_ptr1_rom_read_byte__2+1
    // [1753] rom_read_byte::rom_ptr1_$0 = rom_read_byte::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_read_byte__0
    and #<$3fff
    sta.z rom_ptr1_rom_read_byte__0
    lda.z rom_ptr1_rom_read_byte__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_read_byte__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [1754] rom_read_byte::rom_ptr1_return#0 = rom_read_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_read_byte::bank_set_brom1
    // BROM = bank
    // [1755] BROM = rom_read_byte::rom_bank1_return#0 -- vbuz1=vbuz2 
    lda.z rom_bank1_return
    sta.z BROM
    // rom_read_byte::@1
    // return *ptr_rom;
    // [1756] rom_read_byte::return#0 = *((char *)rom_read_byte::rom_ptr1_return#0) -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (rom_ptr1_return),y
    sta.z return
    // rom_read_byte::@return
    // }
    // [1757] return 
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
    // [1759] phi from strcpy strcpy::@2 to strcpy::@1 [phi:strcpy/strcpy::@2->strcpy::@1]
    // [1759] phi strcpy::dst#2 = strcpy::dst#0 [phi:strcpy/strcpy::@2->strcpy::@1#0] -- register_copy 
    // [1759] phi strcpy::src#2 = strcpy::src#0 [phi:strcpy/strcpy::@2->strcpy::@1#1] -- register_copy 
    // strcpy::@1
  __b1:
    // while(*src)
    // [1760] if(0!=*strcpy::src#2) goto strcpy::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcpy::@3
    // *dst = 0
    // [1761] *strcpy::dst#2 = 0 -- _deref_pbum1=vbuc1 
    tya
    ldy dst
    sty.z $fe
    ldy dst+1
    sty.z $ff
    tay
    sta ($fe),y
    // strcpy::@return
    // }
    // [1762] return 
    rts
    // strcpy::@2
  __b2:
    // *dst++ = *src++
    // [1763] *strcpy::dst#2 = *strcpy::src#2 -- _deref_pbum1=_deref_pbuz2 
    ldy #0
    lda (src),y
    ldy dst
    sty.z $fe
    ldy dst+1
    sty.z $ff
    ldy #0
    sta ($fe),y
    // *dst++ = *src++;
    // [1764] strcpy::dst#1 = ++ strcpy::dst#2 -- pbum1=_inc_pbum1 
    inc dst
    bne !+
    inc dst+1
  !:
    // [1765] strcpy::src#1 = ++ strcpy::src#2 -- pbuz1=_inc_pbuz1 
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
    .label strcat__0 = $54
    .label dst = $54
    .label src = $38
    .label source = $38
    // strlen(destination)
    // [1767] call strlen
    // [1982] phi from strcat to strlen [phi:strcat->strlen]
    // [1982] phi strlen::str#8 = chip_rom::rom [phi:strcat->strlen#0] -- pbuz1=pbuc1 
    lda #<chip_rom.rom
    sta.z strlen.str
    lda #>chip_rom.rom
    sta.z strlen.str+1
    jsr strlen
    // strlen(destination)
    // [1768] strlen::return#0 = strlen::len#2
    // strcat::@4
    // [1769] strcat::$0 = strlen::return#0
    // char* dst = destination + strlen(destination)
    // [1770] strcat::dst#0 = chip_rom::rom + strcat::$0 -- pbuz1=pbuc1_plus_vwuz1 
    lda.z dst
    clc
    adc #<chip_rom.rom
    sta.z dst
    lda.z dst+1
    adc #>chip_rom.rom
    sta.z dst+1
    // [1771] phi from strcat::@2 strcat::@4 to strcat::@1 [phi:strcat::@2/strcat::@4->strcat::@1]
    // [1771] phi strcat::dst#2 = strcat::dst#1 [phi:strcat::@2/strcat::@4->strcat::@1#0] -- register_copy 
    // [1771] phi strcat::src#2 = strcat::src#1 [phi:strcat::@2/strcat::@4->strcat::@1#1] -- register_copy 
    // strcat::@1
  __b1:
    // while(*src)
    // [1772] if(0!=*strcat::src#2) goto strcat::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcat::@3
    // *dst = 0
    // [1773] *strcat::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcat::@return
    // }
    // [1774] return 
    rts
    // strcat::@2
  __b2:
    // *dst++ = *src++
    // [1775] *strcat::dst#2 = *strcat::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [1776] strcat::dst#1 = ++ strcat::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [1777] strcat::src#1 = ++ strcat::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    jmp __b1
}
  // print_rom_led
// void print_rom_led(__zp($72) char chip, __zp($4f) char c)
print_rom_led: {
    .label print_rom_led__0 = $72
    .label chip = $72
    .label c = $4f
    .label print_rom_led__4 = $a9
    .label print_rom_led__5 = $72
    // chip*6
    // [1779] print_rom_led::$4 = print_rom_led::chip#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z chip
    asl
    sta.z print_rom_led__4
    // [1780] print_rom_led::$5 = print_rom_led::$4 + print_rom_led::chip#2 -- vbuz1=vbuz2_plus_vbuz1 
    lda.z print_rom_led__5
    clc
    adc.z print_rom_led__4
    sta.z print_rom_led__5
    // CHIP_ROM_X+chip*6
    // [1781] print_rom_led::$0 = print_rom_led::$5 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z print_rom_led__0
    // print_chip_led(CHIP_ROM_X+chip*6+1, CHIP_ROM_Y, CHIP_ROM_W, c, BLUE)
    // [1782] print_chip_led::x#2 = print_rom_led::$0 + $14+1 -- vbuz1=vbuz1_plus_vbuc1 
    lda #$14+1
    clc
    adc.z print_chip_led.x
    sta.z print_chip_led.x
    // [1783] print_chip_led::tc#2 = print_rom_led::c#2
    // [1784] call print_chip_led
    // [2161] phi from print_rom_led to print_chip_led [phi:print_rom_led->print_chip_led]
    // [2161] phi print_chip_led::w#5 = 3 [phi:print_rom_led->print_chip_led#0] -- vbuz1=vbuc1 
    lda #3
    sta.z print_chip_led.w
    // [2161] phi print_chip_led::tc#3 = print_chip_led::tc#2 [phi:print_rom_led->print_chip_led#1] -- register_copy 
    // [2161] phi print_chip_led::x#3 = print_chip_led::x#2 [phi:print_rom_led->print_chip_led#2] -- register_copy 
    jsr print_chip_led
    // print_rom_led::@return
    // }
    // [1785] return 
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
// __zp($3f) struct $2 * fopen(__zp($d3) const char *path, const char *mode)
fopen: {
    .label fopen__4 = $68
    .label fopen__9 = $6b
    .label fopen__15 = $4f
    .label fopen__26 = $c1
    .label fopen__30 = $3f
    .label cbm_k_setnam1_fopen__0 = $54
    .label sp = $65
    .label stream = $3f
    .label pathtoken = $d3
    .label pathpos = $6c
    .label pathpos_1 = $51
    .label pathcmp = $b5
    .label path = $d3
    // Parse path
    .label pathstep = $5a
    .label num = $5d
    .label cbm_k_readst1_return = $4f
    .label return = $3f
    // unsigned char sp = __stdio_filecount
    // [1787] fopen::sp#0 = __stdio_filecount -- vbuz1=vbum2 
    lda __stdio_filecount
    sta.z sp
    // (unsigned int)sp | 0x8000
    // [1788] fopen::$30 = (unsigned int)fopen::sp#0 -- vwuz1=_word_vbuz2 
    sta.z fopen__30
    lda #0
    sta.z fopen__30+1
    // [1789] fopen::stream#0 = fopen::$30 | $8000 -- vwuz1=vwuz1_bor_vwuc1 
    lda.z stream
    ora #<$8000
    sta.z stream
    lda.z stream+1
    ora #>$8000
    sta.z stream+1
    // char pathpos = sp * __STDIO_FILECOUNT
    // [1790] fopen::pathpos#0 = fopen::sp#0 << 3 -- vbuz1=vbuz2_rol_3 
    lda.z sp
    asl
    asl
    asl
    sta.z pathpos
    // __logical = 0
    // [1791] ((char *)&__stdio_file+$100)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    ldy.z sp
    sta __stdio_file+$100,y
    // __device = 0
    // [1792] ((char *)&__stdio_file+$108)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$108,y
    // __channel = 0
    // [1793] ((char *)&__stdio_file+$110)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$110,y
    // [1794] fopen::pathtoken#21 = fopen::pathtoken#0 -- pbum1=pbuz2 
    lda.z pathtoken
    sta pathtoken_1
    lda.z pathtoken+1
    sta pathtoken_1+1
    // [1795] fopen::pathpos#21 = fopen::pathpos#0 -- vbuz1=vbuz2 
    lda.z pathpos
    sta.z pathpos_1
    // [1796] phi from fopen to fopen::@8 [phi:fopen->fopen::@8]
    // [1796] phi fopen::num#10 = 0 [phi:fopen->fopen::@8#0] -- vbuz1=vbuc1 
    lda #0
    sta.z num
    // [1796] phi fopen::pathpos#10 = fopen::pathpos#21 [phi:fopen->fopen::@8#1] -- register_copy 
    // [1796] phi fopen::path#10 = fopen::pathtoken#0 [phi:fopen->fopen::@8#2] -- register_copy 
    // [1796] phi fopen::pathstep#10 = 0 [phi:fopen->fopen::@8#3] -- vbuz1=vbuc1 
    sta.z pathstep
    // [1796] phi fopen::pathtoken#10 = fopen::pathtoken#21 [phi:fopen->fopen::@8#4] -- register_copy 
  // Iterate while path is not \0.
    // [1796] phi from fopen::@22 to fopen::@8 [phi:fopen::@22->fopen::@8]
    // [1796] phi fopen::num#10 = fopen::num#13 [phi:fopen::@22->fopen::@8#0] -- register_copy 
    // [1796] phi fopen::pathpos#10 = fopen::pathpos#7 [phi:fopen::@22->fopen::@8#1] -- register_copy 
    // [1796] phi fopen::path#10 = fopen::path#11 [phi:fopen::@22->fopen::@8#2] -- register_copy 
    // [1796] phi fopen::pathstep#10 = fopen::pathstep#11 [phi:fopen::@22->fopen::@8#3] -- register_copy 
    // [1796] phi fopen::pathtoken#10 = fopen::pathtoken#1 [phi:fopen::@22->fopen::@8#4] -- register_copy 
    // fopen::@8
  __b8:
    // if (*pathtoken == ',' || *pathtoken == '\0')
    // [1797] if(*fopen::pathtoken#10==',') goto fopen::@9 -- _deref_pbum1_eq_vbuc1_then_la1 
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
    // [1798] if(*fopen::pathtoken#10=='@') goto fopen::@9 -- _deref_pbum1_eq_vbuc1_then_la1 
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
    // [1799] if(fopen::pathstep#10!=0) goto fopen::@10 -- vbuz1_neq_0_then_la1 
    lda.z pathstep
    bne __b10
    // fopen::@24
    // __stdio_file.filename[pathpos] = *pathtoken
    // [1800] ((char *)&__stdio_file)[fopen::pathpos#10] = *fopen::pathtoken#10 -- pbuc1_derefidx_vbuz1=_deref_pbum2 
    ldy pathtoken_1
    sty.z $fe
    ldy pathtoken_1+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    ldy.z pathpos_1
    sta __stdio_file,y
    // pathpos++;
    // [1801] fopen::pathpos#1 = ++ fopen::pathpos#10 -- vbuz1=_inc_vbuz1 
    inc.z pathpos_1
    // [1802] phi from fopen::@12 fopen::@23 fopen::@24 to fopen::@10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10]
    // [1802] phi fopen::num#13 = fopen::num#15 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#0] -- register_copy 
    // [1802] phi fopen::pathpos#7 = fopen::pathpos#10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#1] -- register_copy 
    // [1802] phi fopen::path#11 = fopen::path#13 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#2] -- register_copy 
    // [1802] phi fopen::pathstep#11 = fopen::pathstep#1 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#3] -- register_copy 
    // fopen::@10
  __b10:
    // pathtoken++;
    // [1803] fopen::pathtoken#1 = ++ fopen::pathtoken#10 -- pbum1=_inc_pbum1 
    inc pathtoken_1
    bne !+
    inc pathtoken_1+1
  !:
    // fopen::@22
    // pathtoken - 1
    // [1804] fopen::$28 = fopen::pathtoken#1 - 1 -- pbum1=pbum2_minus_1 
    lda pathtoken_1
    sec
    sbc #1
    sta fopen__28
    lda pathtoken_1+1
    sbc #0
    sta fopen__28+1
    // while (*(pathtoken - 1))
    // [1805] if(0!=*fopen::$28) goto fopen::@8 -- 0_neq__deref_pbum1_then_la1 
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
    // [1806] ((char *)&__stdio_file+$118)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    tya
    ldy.z sp
    sta __stdio_file+$118,y
    // if(!__logical)
    // [1807] if(0!=((char *)&__stdio_file+$100)[fopen::sp#0]) goto fopen::@1 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$100,y
    cmp #0
    bne __b1
    // fopen::@27
    // __stdio_filecount+1
    // [1808] fopen::$4 = __stdio_filecount + 1 -- vbuz1=vbum2_plus_1 
    lda __stdio_filecount
    inc
    sta.z fopen__4
    // __logical = __stdio_filecount+1
    // [1809] ((char *)&__stdio_file+$100)[fopen::sp#0] = fopen::$4 -- pbuc1_derefidx_vbuz1=vbuz2 
    sta __stdio_file+$100,y
    // fopen::@1
  __b1:
    // if(!__device)
    // [1810] if(0!=((char *)&__stdio_file+$108)[fopen::sp#0]) goto fopen::@2 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    ldy.z sp
    lda __stdio_file+$108,y
    cmp #0
    bne __b2
    // fopen::@5
    // __device = 8
    // [1811] ((char *)&__stdio_file+$108)[fopen::sp#0] = 8 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #8
    sta __stdio_file+$108,y
    // fopen::@2
  __b2:
    // if(!__channel)
    // [1812] if(0!=((char *)&__stdio_file+$110)[fopen::sp#0]) goto fopen::@3 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    ldy.z sp
    lda __stdio_file+$110,y
    cmp #0
    bne __b3
    // fopen::@6
    // __stdio_filecount+2
    // [1813] fopen::$9 = __stdio_filecount + 2 -- vbuz1=vbum2_plus_2 
    lda __stdio_filecount
    clc
    adc #2
    sta.z fopen__9
    // __channel = __stdio_filecount+2
    // [1814] ((char *)&__stdio_file+$110)[fopen::sp#0] = fopen::$9 -- pbuc1_derefidx_vbuz1=vbuz2 
    sta __stdio_file+$110,y
    // fopen::@3
  __b3:
    // __filename
    // [1815] fopen::$11 = (char *)&__stdio_file + fopen::pathpos#0 -- pbum1=pbuc1_plus_vbuz2 
    lda.z pathpos
    clc
    adc #<__stdio_file
    sta fopen__11
    lda #>__stdio_file
    adc #0
    sta fopen__11+1
    // cbm_k_setnam(__filename)
    // [1816] fopen::cbm_k_setnam1_filename = fopen::$11 -- pbum1=pbum2 
    lda fopen__11
    sta cbm_k_setnam1_filename
    lda fopen__11+1
    sta cbm_k_setnam1_filename+1
    // fopen::cbm_k_setnam1
    // strlen(filename)
    // [1817] strlen::str#4 = fopen::cbm_k_setnam1_filename -- pbuz1=pbum2 
    lda cbm_k_setnam1_filename
    sta.z strlen.str
    lda cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [1818] call strlen
    // [1982] phi from fopen::cbm_k_setnam1 to strlen [phi:fopen::cbm_k_setnam1->strlen]
    // [1982] phi strlen::str#8 = strlen::str#4 [phi:fopen::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [1819] strlen::return#11 = strlen::len#2
    // fopen::@31
    // [1820] fopen::cbm_k_setnam1_$0 = strlen::return#11
    // char filename_len = (char)strlen(filename)
    // [1821] fopen::cbm_k_setnam1_filename_len = (char)fopen::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
    lda.z cbm_k_setnam1_fopen__0
    sta cbm_k_setnam1_filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx cbm_k_setnam1_filename
    ldy cbm_k_setnam1_filename+1
    jsr CBM_SETNAM
    // fopen::@28
    // cbm_k_setlfs(__logical, __device, __channel)
    // [1823] cbm_k_setlfs::channel = ((char *)&__stdio_file+$100)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$100,y
    sta cbm_k_setlfs.channel
    // [1824] cbm_k_setlfs::device = ((char *)&__stdio_file+$108)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    lda __stdio_file+$108,y
    sta cbm_k_setlfs.device
    // [1825] cbm_k_setlfs::command = ((char *)&__stdio_file+$110)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    lda __stdio_file+$110,y
    sta cbm_k_setlfs.command
    // [1826] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // fopen::cbm_k_open1
    // asm
    // asm { jsrCBM_OPEN  }
    jsr CBM_OPEN
    // fopen::cbm_k_readst1
    // char status
    // [1828] fopen::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [1830] fopen::cbm_k_readst1_return#0 = fopen::cbm_k_readst1_status -- vbuz1=vbum2 
    sta.z cbm_k_readst1_return
    // fopen::cbm_k_readst1_@return
    // }
    // [1831] fopen::cbm_k_readst1_return#1 = fopen::cbm_k_readst1_return#0
    // fopen::@29
    // cbm_k_readst()
    // [1832] fopen::$15 = fopen::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [1833] ((char *)&__stdio_file+$118)[fopen::sp#0] = fopen::$15 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fopen__15
    ldy.z sp
    sta __stdio_file+$118,y
    // ferror(stream)
    // [1834] ferror::stream#0 = (struct $2 *)fopen::stream#0
    // [1835] call ferror
    jsr ferror
    // [1836] ferror::return#0 = ferror::return#1
    // fopen::@32
    // [1837] fopen::$16 = ferror::return#0
    // if (ferror(stream))
    // [1838] if(0==fopen::$16) goto fopen::@4 -- 0_eq_vwsm1_then_la1 
    lda fopen__16
    ora fopen__16+1
    beq __b4
    // fopen::@7
    // cbm_k_close(__logical)
    // [1839] fopen::cbm_k_close1_channel = ((char *)&__stdio_file+$100)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$100,y
    sta cbm_k_close1_channel
    // fopen::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // [1841] phi from fopen::cbm_k_close1 to fopen::@return [phi:fopen::cbm_k_close1->fopen::@return]
    // [1841] phi fopen::return#2 = 0 [phi:fopen::cbm_k_close1->fopen::@return#0] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [1842] return 
    rts
    // fopen::@4
  __b4:
    // __stdio_filecount++;
    // [1843] __stdio_filecount = ++ __stdio_filecount -- vbum1=_inc_vbum1 
    inc __stdio_filecount
    // [1844] fopen::return#8 = (struct $2 *)fopen::stream#0
    // [1841] phi from fopen::@4 to fopen::@return [phi:fopen::@4->fopen::@return]
    // [1841] phi fopen::return#2 = fopen::return#8 [phi:fopen::@4->fopen::@return#0] -- register_copy 
    rts
    // fopen::@9
  __b9:
    // if (pathstep > 0)
    // [1845] if(fopen::pathstep#10>0) goto fopen::@11 -- vbuz1_gt_0_then_la1 
    lda.z pathstep
    bne __b11
    // fopen::@25
    // __stdio_file.filename[pathpos] = '\0'
    // [1846] ((char *)&__stdio_file)[fopen::pathpos#10] = '@' -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #'@'
    ldy.z pathpos_1
    sta __stdio_file,y
    // path = pathtoken + 1
    // [1847] fopen::path#0 = fopen::pathtoken#10 + 1 -- pbuz1=pbum2_plus_1 
    clc
    lda pathtoken_1
    adc #1
    sta.z path
    lda pathtoken_1+1
    adc #0
    sta.z path+1
    // [1848] phi from fopen::@16 fopen::@17 fopen::@18 fopen::@19 fopen::@25 to fopen::@12 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12]
    // [1848] phi fopen::num#15 = fopen::num#2 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#0] -- register_copy 
    // [1848] phi fopen::path#13 = fopen::path#16 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#1] -- register_copy 
    // fopen::@12
  __b12:
    // pathstep++;
    // [1849] fopen::pathstep#1 = ++ fopen::pathstep#10 -- vbuz1=_inc_vbuz1 
    inc.z pathstep
    jmp __b10
    // fopen::@11
  __b11:
    // char pathcmp = *path
    // [1850] fopen::pathcmp#0 = *fopen::path#10 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (path),y
    sta.z pathcmp
    // case 'D':
    // [1851] if(fopen::pathcmp#0=='D') goto fopen::@13 -- vbuz1_eq_vbuc1_then_la1 
    lda #'D'
    cmp.z pathcmp
    beq __b13
    // fopen::@20
    // case 'L':
    // [1852] if(fopen::pathcmp#0=='L') goto fopen::@13 -- vbuz1_eq_vbuc1_then_la1 
    lda #'L'
    cmp.z pathcmp
    beq __b13
    // fopen::@21
    // case 'C':
    //                     num = (char)atoi(path + 1);
    //                     path = pathtoken + 1;
    // [1853] if(fopen::pathcmp#0=='C') goto fopen::@13 -- vbuz1_eq_vbuc1_then_la1 
    lda #'C'
    cmp.z pathcmp
    beq __b13
    // [1854] phi from fopen::@21 fopen::@30 to fopen::@14 [phi:fopen::@21/fopen::@30->fopen::@14]
    // [1854] phi fopen::path#16 = fopen::path#10 [phi:fopen::@21/fopen::@30->fopen::@14#0] -- register_copy 
    // [1854] phi fopen::num#2 = fopen::num#10 [phi:fopen::@21/fopen::@30->fopen::@14#1] -- register_copy 
    // fopen::@14
  __b14:
    // case 'L':
    //                     __logical = num;
    //                     break;
    // [1855] if(fopen::pathcmp#0=='L') goto fopen::@17 -- vbuz1_eq_vbuc1_then_la1 
    lda #'L'
    cmp.z pathcmp
    beq __b17
    // fopen::@15
    // case 'D':
    //                     __device = num;
    //                     break;
    // [1856] if(fopen::pathcmp#0=='D') goto fopen::@18 -- vbuz1_eq_vbuc1_then_la1 
    lda #'D'
    cmp.z pathcmp
    beq __b18
    // fopen::@16
    // case 'C':
    //                     __channel = num;
    //                     break;
    // [1857] if(fopen::pathcmp#0!='C') goto fopen::@12 -- vbuz1_neq_vbuc1_then_la1 
    lda #'C'
    cmp.z pathcmp
    bne __b12
    // fopen::@19
    // __channel = num
    // [1858] ((char *)&__stdio_file+$110)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z num
    ldy.z sp
    sta __stdio_file+$110,y
    jmp __b12
    // fopen::@18
  __b18:
    // __device = num
    // [1859] ((char *)&__stdio_file+$108)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z num
    ldy.z sp
    sta __stdio_file+$108,y
    jmp __b12
    // fopen::@17
  __b17:
    // __logical = num
    // [1860] ((char *)&__stdio_file+$100)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z num
    ldy.z sp
    sta __stdio_file+$100,y
    jmp __b12
    // fopen::@13
  __b13:
    // atoi(path + 1)
    // [1861] atoi::str#0 = fopen::path#10 + 1 -- pbuz1=pbuz1_plus_1 
    inc.z atoi.str
    bne !+
    inc.z atoi.str+1
  !:
    // [1862] call atoi
    // [2313] phi from fopen::@13 to atoi [phi:fopen::@13->atoi]
    // [2313] phi atoi::str#2 = atoi::str#0 [phi:fopen::@13->atoi#0] -- register_copy 
    jsr atoi
    // atoi(path + 1)
    // [1863] atoi::return#3 = atoi::return#2
    // fopen::@30
    // [1864] fopen::$26 = atoi::return#3
    // num = (char)atoi(path + 1)
    // [1865] fopen::num#1 = (char)fopen::$26 -- vbuz1=_byte_vwsz2 
    lda.z fopen__26
    sta.z num
    // path = pathtoken + 1
    // [1866] fopen::path#1 = fopen::pathtoken#10 + 1 -- pbuz1=pbum2_plus_1 
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
// __zp($aa) unsigned int fgets(__zp($b8) char *ptr, __zp($d1) unsigned int size, __mem() struct $2 *stream)
fgets: {
    .label fgets__1 = $6c
    .label fgets__8 = $68
    .label fgets__9 = $6b
    .label fgets__13 = $4f
    .label cbm_k_chkin1_channel = $f4
    .label cbm_k_chkin1_status = $ee
    .label cbm_k_readst1_status = $ef
    .label cbm_k_readst2_status = $bc
    .label sp = $65
    .label cbm_k_readst1_return = $6c
    .label return = $aa
    .label bytes = $77
    .label cbm_k_readst2_return = $68
    .label read = $aa
    .label ptr = $b8
    .label remaining = $c5
    .label size = $d1
    // unsigned char sp = (unsigned char)stream
    // [1868] fgets::sp#0 = (char)fgets::stream#2 -- vbuz1=_byte_pssm2 
    lda stream
    sta.z sp
    // cbm_k_chkin(__logical)
    // [1869] fgets::cbm_k_chkin1_channel = ((char *)&__stdio_file+$100)[fgets::sp#0] -- vbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda __stdio_file+$100,y
    sta.z cbm_k_chkin1_channel
    // fgets::cbm_k_chkin1
    // char status
    // [1870] fgets::cbm_k_chkin1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fgets::cbm_k_readst1
    // char status
    // [1872] fgets::cbm_k_readst1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [1874] fgets::cbm_k_readst1_return#0 = fgets::cbm_k_readst1_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst1_return
    // fgets::cbm_k_readst1_@return
    // }
    // [1875] fgets::cbm_k_readst1_return#1 = fgets::cbm_k_readst1_return#0
    // fgets::@11
    // cbm_k_readst()
    // [1876] fgets::$1 = fgets::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [1877] ((char *)&__stdio_file+$118)[fgets::sp#0] = fgets::$1 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fgets__1
    ldy.z sp
    sta __stdio_file+$118,y
    // if (__status)
    // [1878] if(0==((char *)&__stdio_file+$118)[fgets::sp#0]) goto fgets::@1 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$118,y
    cmp #0
    beq __b1
    // [1879] phi from fgets::@11 fgets::@12 fgets::@5 to fgets::@return [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return]
  __b8:
    // [1879] phi fgets::return#1 = 0 [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return#0] -- vwuz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fgets::@return
    // }
    // [1880] return 
    rts
    // fgets::@1
  __b1:
    // [1881] fgets::remaining#22 = fgets::size#10 -- vwuz1=vwuz2 
    lda.z size
    sta.z remaining
    lda.z size+1
    sta.z remaining+1
    // [1882] phi from fgets::@1 to fgets::@2 [phi:fgets::@1->fgets::@2]
    // [1882] phi fgets::read#10 = 0 [phi:fgets::@1->fgets::@2#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z read
    sta.z read+1
    // [1882] phi fgets::remaining#11 = fgets::remaining#22 [phi:fgets::@1->fgets::@2#1] -- register_copy 
    // [1882] phi fgets::ptr#10 = fgets::ptr#12 [phi:fgets::@1->fgets::@2#2] -- register_copy 
    // [1882] phi from fgets::@17 fgets::@18 to fgets::@2 [phi:fgets::@17/fgets::@18->fgets::@2]
    // [1882] phi fgets::read#10 = fgets::read#1 [phi:fgets::@17/fgets::@18->fgets::@2#0] -- register_copy 
    // [1882] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@17/fgets::@18->fgets::@2#1] -- register_copy 
    // [1882] phi fgets::ptr#10 = fgets::ptr#13 [phi:fgets::@17/fgets::@18->fgets::@2#2] -- register_copy 
    // fgets::@2
  __b2:
    // if (!size)
    // [1883] if(0==fgets::size#10) goto fgets::@3 -- 0_eq_vwuz1_then_la1 
    lda.z size
    ora.z size+1
    bne !__b3+
    jmp __b3
  !__b3:
    // fgets::@8
    // if (remaining >= 512)
    // [1884] if(fgets::remaining#11>=$200) goto fgets::@4 -- vwuz1_ge_vwuc1_then_la1 
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
    // [1885] cx16_k_macptr::bytes = fgets::remaining#11 -- vbuz1=vwuz2 
    lda.z remaining
    sta.z cx16_k_macptr.bytes
    // [1886] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [1887] call cx16_k_macptr
    jsr cx16_k_macptr
    // [1888] cx16_k_macptr::return#4 = cx16_k_macptr::return#1
    // fgets::@15
  __b15:
    // bytes = cx16_k_macptr(remaining, ptr)
    // [1889] fgets::bytes#3 = cx16_k_macptr::return#4
    // [1890] phi from fgets::@13 fgets::@14 fgets::@15 to fgets::cbm_k_readst2 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2]
    // [1890] phi fgets::bytes#10 = fgets::bytes#1 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2#0] -- register_copy 
    // fgets::cbm_k_readst2
    // char status
    // [1891] fgets::cbm_k_readst2_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [1893] fgets::cbm_k_readst2_return#0 = fgets::cbm_k_readst2_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst2_return
    // fgets::cbm_k_readst2_@return
    // }
    // [1894] fgets::cbm_k_readst2_return#1 = fgets::cbm_k_readst2_return#0
    // fgets::@12
    // cbm_k_readst()
    // [1895] fgets::$8 = fgets::cbm_k_readst2_return#1
    // __status = cbm_k_readst()
    // [1896] ((char *)&__stdio_file+$118)[fgets::sp#0] = fgets::$8 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fgets__8
    ldy.z sp
    sta __stdio_file+$118,y
    // __status & 0xBF
    // [1897] fgets::$9 = ((char *)&__stdio_file+$118)[fgets::sp#0] & $bf -- vbuz1=pbuc1_derefidx_vbuz2_band_vbuc2 
    lda #$bf
    and __stdio_file+$118,y
    sta.z fgets__9
    // if (__status & 0xBF)
    // [1898] if(0==fgets::$9) goto fgets::@5 -- 0_eq_vbuz1_then_la1 
    beq __b5
    jmp __b8
    // fgets::@5
  __b5:
    // if (bytes == 0xFFFF)
    // [1899] if(fgets::bytes#10!=$ffff) goto fgets::@6 -- vwuz1_neq_vwuc1_then_la1 
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
    // [1900] fgets::read#1 = fgets::read#10 + fgets::bytes#10 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z read
    adc.z bytes
    sta.z read
    lda.z read+1
    adc.z bytes+1
    sta.z read+1
    // ptr += bytes
    // [1901] fgets::ptr#0 = fgets::ptr#10 + fgets::bytes#10 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z ptr
    adc.z bytes
    sta.z ptr
    lda.z ptr+1
    adc.z bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [1902] fgets::$13 = byte1  fgets::ptr#0 -- vbuz1=_byte1_pbuz2 
    sta.z fgets__13
    // if (BYTE1(ptr) == 0xC0)
    // [1903] if(fgets::$13!=$c0) goto fgets::@7 -- vbuz1_neq_vbuc1_then_la1 
    lda #$c0
    cmp.z fgets__13
    bne __b7
    // fgets::@10
    // ptr -= 0x2000
    // [1904] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [1905] phi from fgets::@10 fgets::@6 to fgets::@7 [phi:fgets::@10/fgets::@6->fgets::@7]
    // [1905] phi fgets::ptr#13 = fgets::ptr#1 [phi:fgets::@10/fgets::@6->fgets::@7#0] -- register_copy 
    // fgets::@7
  __b7:
    // remaining -= bytes
    // [1906] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#10 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z remaining
    sec
    sbc.z bytes
    sta.z remaining
    lda.z remaining+1
    sbc.z bytes+1
    sta.z remaining+1
    // while ((__status == 0) && ((size && remaining) || !size))
    // [1907] if(((char *)&__stdio_file+$118)[fgets::sp#0]==0) goto fgets::@16 -- pbuc1_derefidx_vbuz1_eq_0_then_la1 
    ldy.z sp
    lda __stdio_file+$118,y
    cmp #0
    beq __b16
    // [1879] phi from fgets::@17 fgets::@7 to fgets::@return [phi:fgets::@17/fgets::@7->fgets::@return]
    // [1879] phi fgets::return#1 = fgets::read#1 [phi:fgets::@17/fgets::@7->fgets::@return#0] -- register_copy 
    rts
    // fgets::@16
  __b16:
    // while ((__status == 0) && ((size && remaining) || !size))
    // [1908] if(0==fgets::size#10) goto fgets::@17 -- 0_eq_vwuz1_then_la1 
    lda.z size
    ora.z size+1
    beq __b17
    // fgets::@18
    // [1909] if(0!=fgets::remaining#1) goto fgets::@2 -- 0_neq_vwuz1_then_la1 
    lda.z remaining
    ora.z remaining+1
    beq !__b2+
    jmp __b2
  !__b2:
    // fgets::@17
  __b17:
    // [1910] if(0==fgets::size#10) goto fgets::@2 -- 0_eq_vwuz1_then_la1 
    lda.z size
    ora.z size+1
    bne !__b2+
    jmp __b2
  !__b2:
    rts
    // fgets::@4
  __b4:
    // cx16_k_macptr(512, ptr)
    // [1911] cx16_k_macptr::bytes = $200 -- vbuz1=vwuc1 
    lda #<$200
    sta.z cx16_k_macptr.bytes
    // [1912] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [1913] call cx16_k_macptr
    jsr cx16_k_macptr
    // [1914] cx16_k_macptr::return#3 = cx16_k_macptr::return#1
    // fgets::@14
    // bytes = cx16_k_macptr(512, ptr)
    // [1915] fgets::bytes#2 = cx16_k_macptr::return#3
    jmp __b15
    // fgets::@3
  __b3:
    // cx16_k_macptr(0, ptr)
    // [1916] cx16_k_macptr::bytes = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cx16_k_macptr.bytes
    // [1917] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [1918] call cx16_k_macptr
    jsr cx16_k_macptr
    // [1919] cx16_k_macptr::return#2 = cx16_k_macptr::return#1
    // fgets::@13
    // bytes = cx16_k_macptr(0, ptr)
    // [1920] fgets::bytes#1 = cx16_k_macptr::return#2
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
    .label fclose__1 = $60
    .label fclose__4 = $3a
    .label fclose__6 = $b5
    .label sp = $b5
    .label cbm_k_readst1_return = $60
    .label cbm_k_readst2_return = $3a
    .label stream = $b6
    // unsigned char sp = (unsigned char)stream
    // [1922] fclose::sp#0 = (char)fclose::stream#2 -- vbuz1=_byte_pssz2 
    lda.z stream
    sta.z sp
    // cbm_k_chkin(__logical)
    // [1923] fclose::cbm_k_chkin1_channel = ((char *)&__stdio_file+$100)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    tay
    lda __stdio_file+$100,y
    sta cbm_k_chkin1_channel
    // fclose::cbm_k_chkin1
    // char status
    // [1924] fclose::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fclose::cbm_k_readst1
    // char status
    // [1926] fclose::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [1928] fclose::cbm_k_readst1_return#0 = fclose::cbm_k_readst1_status -- vbuz1=vbum2 
    sta.z cbm_k_readst1_return
    // fclose::cbm_k_readst1_@return
    // }
    // [1929] fclose::cbm_k_readst1_return#1 = fclose::cbm_k_readst1_return#0
    // fclose::@3
    // cbm_k_readst()
    // [1930] fclose::$1 = fclose::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [1931] ((char *)&__stdio_file+$118)[fclose::sp#0] = fclose::$1 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fclose__1
    ldy.z sp
    sta __stdio_file+$118,y
    // if (__status)
    // [1932] if(0==((char *)&__stdio_file+$118)[fclose::sp#0]) goto fclose::@1 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$118,y
    cmp #0
    beq __b1
    // fclose::@return
    // }
    // [1933] return 
    rts
    // fclose::@1
  __b1:
    // cbm_k_close(__logical)
    // [1934] fclose::cbm_k_close1_channel = ((char *)&__stdio_file+$100)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$100,y
    sta cbm_k_close1_channel
    // fclose::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // fclose::cbm_k_readst2
    // char status
    // [1936] fclose::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [1938] fclose::cbm_k_readst2_return#0 = fclose::cbm_k_readst2_status -- vbuz1=vbum2 
    sta.z cbm_k_readst2_return
    // fclose::cbm_k_readst2_@return
    // }
    // [1939] fclose::cbm_k_readst2_return#1 = fclose::cbm_k_readst2_return#0
    // fclose::@4
    // cbm_k_readst()
    // [1940] fclose::$4 = fclose::cbm_k_readst2_return#1
    // __status = cbm_k_readst()
    // [1941] ((char *)&__stdio_file+$118)[fclose::sp#0] = fclose::$4 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fclose__4
    ldy.z sp
    sta __stdio_file+$118,y
    // if (__status)
    // [1942] if(0==((char *)&__stdio_file+$118)[fclose::sp#0]) goto fclose::@2 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$118,y
    cmp #0
    beq __b2
    rts
    // fclose::@2
  __b2:
    // __logical = 0
    // [1943] ((char *)&__stdio_file+$100)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    ldy.z sp
    sta __stdio_file+$100,y
    // __device = 0
    // [1944] ((char *)&__stdio_file+$108)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$108,y
    // __channel = 0
    // [1945] ((char *)&__stdio_file+$110)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$110,y
    // __filename
    // [1946] fclose::$6 = fclose::sp#0 << 3 -- vbuz1=vbuz1_rol_3 
    lda.z fclose__6
    asl
    asl
    asl
    sta.z fclose__6
    // *__filename = '\0'
    // [1947] ((char *)&__stdio_file)[fclose::$6] = '@' -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #'@'
    ldy.z fclose__6
    sta __stdio_file,y
    // __stdio_filecount--;
    // [1948] __stdio_filecount = -- __stdio_filecount -- vbum1=_dec_vbum1 
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
    .label return = $b4
    // __mem unsigned char ch
    // [1949] cbm_k_getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsrCBM_GETIN stach  }
    jsr CBM_GETIN
    sta ch
    // return ch;
    // [1951] cbm_k_getin::return#0 = cbm_k_getin::ch -- vbuz1=vbum2 
    sta.z return
    // cbm_k_getin::@return
    // }
    // [1952] cbm_k_getin::return#1 = cbm_k_getin::return#0
    // [1953] return 
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
// void uctoa(__zp($25) char value, __zp($38) char *buffer, __zp($db) char radix)
uctoa: {
    .label uctoa__4 = $60
    .label digit_value = $3a
    .label buffer = $38
    .label digit = $65
    .label value = $25
    .label radix = $db
    .label started = $6c
    .label max_digits = $67
    .label digit_values = $b2
    // if(radix==DECIMAL)
    // [1954] if(uctoa::radix#0==DECIMAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp.z radix
    beq __b2
    // uctoa::@2
    // if(radix==HEXADECIMAL)
    // [1955] if(uctoa::radix#0==HEXADECIMAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp.z radix
    beq __b3
    // uctoa::@3
    // if(radix==OCTAL)
    // [1956] if(uctoa::radix#0==OCTAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp.z radix
    beq __b4
    // uctoa::@4
    // if(radix==BINARY)
    // [1957] if(uctoa::radix#0==BINARY) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp.z radix
    beq __b5
    // uctoa::@5
    // *buffer++ = 'e'
    // [1958] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1959] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1960] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1961] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // uctoa::@return
    // }
    // [1962] return 
    rts
    // [1963] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
  __b2:
    // [1963] phi uctoa::digit_values#8 = RADIX_DECIMAL_VALUES_CHAR [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1963] phi uctoa::max_digits#7 = 3 [phi:uctoa->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [1963] phi from uctoa::@2 to uctoa::@1 [phi:uctoa::@2->uctoa::@1]
  __b3:
    // [1963] phi uctoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_CHAR [phi:uctoa::@2->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1963] phi uctoa::max_digits#7 = 2 [phi:uctoa::@2->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #2
    sta.z max_digits
    jmp __b1
    // [1963] phi from uctoa::@3 to uctoa::@1 [phi:uctoa::@3->uctoa::@1]
  __b4:
    // [1963] phi uctoa::digit_values#8 = RADIX_OCTAL_VALUES_CHAR [phi:uctoa::@3->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values+1
    // [1963] phi uctoa::max_digits#7 = 3 [phi:uctoa::@3->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [1963] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
  __b5:
    // [1963] phi uctoa::digit_values#8 = RADIX_BINARY_VALUES_CHAR [phi:uctoa::@4->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_BINARY_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_CHAR
    sta.z digit_values+1
    // [1963] phi uctoa::max_digits#7 = 8 [phi:uctoa::@4->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #8
    sta.z max_digits
    // uctoa::@1
  __b1:
    // [1964] phi from uctoa::@1 to uctoa::@6 [phi:uctoa::@1->uctoa::@6]
    // [1964] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa::@1->uctoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1964] phi uctoa::started#2 = 0 [phi:uctoa::@1->uctoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [1964] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa::@1->uctoa::@6#2] -- register_copy 
    // [1964] phi uctoa::digit#2 = 0 [phi:uctoa::@1->uctoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // uctoa::@6
  __b6:
    // max_digits-1
    // [1965] uctoa::$4 = uctoa::max_digits#7 - 1 -- vbuz1=vbuz2_minus_1 
    ldx.z max_digits
    dex
    stx.z uctoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1966] if(uctoa::digit#2<uctoa::$4) goto uctoa::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z digit
    cmp.z uctoa__4
    bcc __b7
    // uctoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1967] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z value
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1968] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1969] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // uctoa::@7
  __b7:
    // unsigned char digit_value = digit_values[digit]
    // [1970] uctoa::digit_value#0 = uctoa::digit_values#8[uctoa::digit#2] -- vbuz1=pbuz2_derefidx_vbuz3 
    ldy.z digit
    lda (digit_values),y
    sta.z digit_value
    // if (started || value >= digit_value)
    // [1971] if(0!=uctoa::started#2) goto uctoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // uctoa::@12
    // [1972] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@10 -- vbuz1_ge_vbuz2_then_la1 
    lda.z value
    cmp.z digit_value
    bcs __b10
    // [1973] phi from uctoa::@12 to uctoa::@9 [phi:uctoa::@12->uctoa::@9]
    // [1973] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@12->uctoa::@9#0] -- register_copy 
    // [1973] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@12->uctoa::@9#1] -- register_copy 
    // [1973] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@12->uctoa::@9#2] -- register_copy 
    // uctoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1974] uctoa::digit#1 = ++ uctoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1964] phi from uctoa::@9 to uctoa::@6 [phi:uctoa::@9->uctoa::@6]
    // [1964] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@9->uctoa::@6#0] -- register_copy 
    // [1964] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@9->uctoa::@6#1] -- register_copy 
    // [1964] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@9->uctoa::@6#2] -- register_copy 
    // [1964] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@9->uctoa::@6#3] -- register_copy 
    jmp __b6
    // uctoa::@10
  __b10:
    // uctoa_append(buffer++, value, digit_value)
    // [1975] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [1976] uctoa_append::value#0 = uctoa::value#2
    // [1977] uctoa_append::sub#0 = uctoa::digit_value#0
    // [1978] call uctoa_append
    // [2334] phi from uctoa::@10 to uctoa_append [phi:uctoa::@10->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [1979] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@11
    // value = uctoa_append(buffer++, value, digit_value)
    // [1980] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [1981] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1973] phi from uctoa::@11 to uctoa::@9 [phi:uctoa::@11->uctoa::@9]
    // [1973] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@11->uctoa::@9#0] -- register_copy 
    // [1973] phi uctoa::started#4 = 1 [phi:uctoa::@11->uctoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [1973] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@11->uctoa::@9#2] -- register_copy 
    jmp __b9
}
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __zp($54) unsigned int strlen(__zp($4d) char *str)
strlen: {
    .label return = $54
    .label len = $54
    .label str = $4d
    // [1983] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [1983] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z len
    sta.z len+1
    // [1983] phi strlen::str#6 = strlen::str#8 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [1984] if(0!=*strlen::str#6) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [1985] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [1986] strlen::len#1 = ++ strlen::len#2 -- vwuz1=_inc_vwuz1 
    inc.z len
    bne !+
    inc.z len+1
  !:
    // str++;
    // [1987] strlen::str#1 = ++ strlen::str#6 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [1983] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [1983] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [1983] phi strlen::str#6 = strlen::str#1 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
}
  // printf_padding
// Print a padding char a number of times
// void printf_padding(__zp($3f) void (*putc)(char), __zp($6b) char pad, __zp($68) char length)
printf_padding: {
    .label i = $4f
    .label putc = $3f
    .label length = $68
    .label pad = $6b
    // [1989] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [1989] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [1990] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z length
    bcc __b2
    // printf_padding::@return
    // }
    // [1991] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [1992] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbuz1 
    lda.z pad
    pha
    // [1993] callexecute *printf_padding::putc#7  -- call__deref_pprz1 
    jsr icall31
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [1995] printf_padding::i#1 = ++ printf_padding::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1989] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [1989] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
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
    .label rom_address_from_bank__1 = $73
    .label return = $73
    .label rom_bank = $cc
    .label return_1 = $bd
    // ((unsigned long)(rom_bank)) << 14
    // [1997] rom_address_from_bank::$1 = (unsigned long)rom_address_from_bank::rom_bank#3 -- vduz1=_dword_vbuz2 
    lda.z rom_bank
    sta.z rom_address_from_bank__1
    lda #0
    sta.z rom_address_from_bank__1+1
    sta.z rom_address_from_bank__1+2
    sta.z rom_address_from_bank__1+3
    // [1998] rom_address_from_bank::return#0 = rom_address_from_bank::$1 << $e -- vduz1=vduz1_rol_vbuc1 
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
    // [1999] return 
    rts
  .segment Data
    .label return_2 = main.rom_file_modulo
}
.segment Code
  // rom_compare
// __zp($4d) unsigned int rom_compare(__zp($e3) char bank_ram, __zp($aa) char *ptr_ram, __zp($ac) unsigned long rom_compare_address, __zp($c8) unsigned int rom_compare_size)
rom_compare: {
    .label rom_compare__5 = $33
    .label rom_bank1_rom_compare__0 = $30
    .label rom_bank1_rom_compare__1 = $5c
    .label rom_bank1_rom_compare__2 = $6e
    .label rom_ptr1_rom_compare__0 = $54
    .label rom_ptr1_rom_compare__2 = $54
    .label bank_set_bram1_bank = $e3
    .label rom_bank1_bank_unshifted = $6e
    .label rom_bank1_return = $69
    .label rom_ptr1_return = $54
    .label ptr_rom = $54
    .label ptr_ram = $aa
    .label compared_bytes = $7d
    /// Holds the amount of bytes actually verified between the ROM and the RAM.
    .label equal_bytes = $4d
    .label bank_ram = $e3
    .label rom_compare_address = $ac
    .label return = $4d
    .label rom_compare_size = $c8
    // rom_compare::bank_set_bram1
    // BRAM = bank
    // [2001] BRAM = rom_compare::bank_set_bram1_bank#0 -- vbuz1=vbuz2 
    lda.z bank_set_bram1_bank
    sta.z BRAM
    // rom_compare::rom_bank1
    // BYTE2(address)
    // [2002] rom_compare::rom_bank1_$0 = byte2  rom_compare::rom_compare_address#3 -- vbuz1=_byte2_vduz2 
    lda.z rom_compare_address+2
    sta.z rom_bank1_rom_compare__0
    // BYTE1(address)
    // [2003] rom_compare::rom_bank1_$1 = byte1  rom_compare::rom_compare_address#3 -- vbuz1=_byte1_vduz2 
    lda.z rom_compare_address+1
    sta.z rom_bank1_rom_compare__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2004] rom_compare::rom_bank1_$2 = rom_compare::rom_bank1_$0 w= rom_compare::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_compare__0
    sta.z rom_bank1_rom_compare__2+1
    lda.z rom_bank1_rom_compare__1
    sta.z rom_bank1_rom_compare__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2005] rom_compare::rom_bank1_bank_unshifted#0 = rom_compare::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2006] rom_compare::rom_bank1_return#0 = byte1  rom_compare::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwuz2 
    lda.z rom_bank1_bank_unshifted+1
    sta.z rom_bank1_return
    // rom_compare::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2007] rom_compare::rom_ptr1_$2 = (unsigned int)rom_compare::rom_compare_address#3 -- vwuz1=_word_vduz2 
    lda.z rom_compare_address
    sta.z rom_ptr1_rom_compare__2
    lda.z rom_compare_address+1
    sta.z rom_ptr1_rom_compare__2+1
    // [2008] rom_compare::rom_ptr1_$0 = rom_compare::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_compare__0
    and #<$3fff
    sta.z rom_ptr1_rom_compare__0
    lda.z rom_ptr1_rom_compare__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_compare__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2009] rom_compare::rom_ptr1_return#0 = rom_compare::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_compare::bank_set_brom1
    // BROM = bank
    // [2010] BROM = rom_compare::rom_bank1_return#0 -- vbuz1=vbuz2 
    lda.z rom_bank1_return
    sta.z BROM
    // [2011] rom_compare::ptr_rom#9 = (char *)rom_compare::rom_ptr1_return#0
    // [2012] phi from rom_compare::bank_set_brom1 to rom_compare::@1 [phi:rom_compare::bank_set_brom1->rom_compare::@1]
    // [2012] phi rom_compare::equal_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z equal_bytes
    sta.z equal_bytes+1
    // [2012] phi rom_compare::ptr_ram#4 = rom_compare::ptr_ram#10 [phi:rom_compare::bank_set_brom1->rom_compare::@1#1] -- register_copy 
    // [2012] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#9 [phi:rom_compare::bank_set_brom1->rom_compare::@1#2] -- register_copy 
    // [2012] phi rom_compare::compared_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#3] -- vwuz1=vwuc1 
    sta.z compared_bytes
    sta.z compared_bytes+1
    // rom_compare::@1
  __b1:
    // while (compared_bytes < rom_compare_size)
    // [2013] if(rom_compare::compared_bytes#2<rom_compare::rom_compare_size#11) goto rom_compare::@2 -- vwuz1_lt_vwuz2_then_la1 
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
    // [2014] return 
    rts
    // rom_compare::@2
  __b2:
    // rom_byte_compare(ptr_rom, *ptr_ram)
    // [2015] rom_byte_compare::ptr_rom#0 = rom_compare::ptr_rom#2
    // [2016] rom_byte_compare::value#0 = *rom_compare::ptr_ram#4 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (ptr_ram),y
    sta.z rom_byte_compare.value
    // [2017] call rom_byte_compare
    jsr rom_byte_compare
    // [2018] rom_byte_compare::return#2 = rom_byte_compare::return#0
    // rom_compare::@5
    // [2019] rom_compare::$5 = rom_byte_compare::return#2
    // if (rom_byte_compare(ptr_rom, *ptr_ram))
    // [2020] if(0==rom_compare::$5) goto rom_compare::@3 -- 0_eq_vbuz1_then_la1 
    lda.z rom_compare__5
    beq __b3
    // rom_compare::@4
    // equal_bytes++;
    // [2021] rom_compare::equal_bytes#1 = ++ rom_compare::equal_bytes#2 -- vwuz1=_inc_vwuz1 
    inc.z equal_bytes
    bne !+
    inc.z equal_bytes+1
  !:
    // [2022] phi from rom_compare::@4 rom_compare::@5 to rom_compare::@3 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3]
    // [2022] phi rom_compare::equal_bytes#6 = rom_compare::equal_bytes#1 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3#0] -- register_copy 
    // rom_compare::@3
  __b3:
    // ptr_rom++;
    // [2023] rom_compare::ptr_rom#1 = ++ rom_compare::ptr_rom#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr_rom
    bne !+
    inc.z ptr_rom+1
  !:
    // ptr_ram++;
    // [2024] rom_compare::ptr_ram#0 = ++ rom_compare::ptr_ram#4 -- pbuz1=_inc_pbuz1 
    inc.z ptr_ram
    bne !+
    inc.z ptr_ram+1
  !:
    // compared_bytes++;
    // [2025] rom_compare::compared_bytes#1 = ++ rom_compare::compared_bytes#2 -- vwuz1=_inc_vwuz1 
    inc.z compared_bytes
    bne !+
    inc.z compared_bytes+1
  !:
    // [2012] phi from rom_compare::@3 to rom_compare::@1 [phi:rom_compare::@3->rom_compare::@1]
    // [2012] phi rom_compare::equal_bytes#2 = rom_compare::equal_bytes#6 [phi:rom_compare::@3->rom_compare::@1#0] -- register_copy 
    // [2012] phi rom_compare::ptr_ram#4 = rom_compare::ptr_ram#0 [phi:rom_compare::@3->rom_compare::@1#1] -- register_copy 
    // [2012] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#1 [phi:rom_compare::@3->rom_compare::@1#2] -- register_copy 
    // [2012] phi rom_compare::compared_bytes#2 = rom_compare::compared_bytes#1 [phi:rom_compare::@3->rom_compare::@1#3] -- register_copy 
    jmp __b1
}
  // ultoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void ultoa(__zp($26) unsigned long value, __zp($61) char *buffer, __zp($da) char radix)
ultoa: {
    .label ultoa__4 = $30
    .label ultoa__10 = $69
    .label ultoa__11 = $5c
    .label digit_value = $3b
    .label buffer = $61
    .label digit = $60
    .label value = $26
    .label radix = $da
    .label started = $3a
    .label max_digits = $b5
    .label digit_values = $b6
    // if(radix==DECIMAL)
    // [2026] if(ultoa::radix#0==DECIMAL) goto ultoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp.z radix
    beq __b2
    // ultoa::@2
    // if(radix==HEXADECIMAL)
    // [2027] if(ultoa::radix#0==HEXADECIMAL) goto ultoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp.z radix
    beq __b3
    // ultoa::@3
    // if(radix==OCTAL)
    // [2028] if(ultoa::radix#0==OCTAL) goto ultoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp.z radix
    beq __b4
    // ultoa::@4
    // if(radix==BINARY)
    // [2029] if(ultoa::radix#0==BINARY) goto ultoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp.z radix
    beq __b5
    // ultoa::@5
    // *buffer++ = 'e'
    // [2030] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2031] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2032] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2033] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // ultoa::@return
    // }
    // [2034] return 
    rts
    // [2035] phi from ultoa to ultoa::@1 [phi:ultoa->ultoa::@1]
  __b2:
    // [2035] phi ultoa::digit_values#8 = RADIX_DECIMAL_VALUES_LONG [phi:ultoa->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2035] phi ultoa::max_digits#7 = $a [phi:ultoa->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #$a
    sta.z max_digits
    jmp __b1
    // [2035] phi from ultoa::@2 to ultoa::@1 [phi:ultoa::@2->ultoa::@1]
  __b3:
    // [2035] phi ultoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_LONG [phi:ultoa::@2->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2035] phi ultoa::max_digits#7 = 8 [phi:ultoa::@2->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #8
    sta.z max_digits
    jmp __b1
    // [2035] phi from ultoa::@3 to ultoa::@1 [phi:ultoa::@3->ultoa::@1]
  __b4:
    // [2035] phi ultoa::digit_values#8 = RADIX_OCTAL_VALUES_LONG [phi:ultoa::@3->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_OCTAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_LONG
    sta.z digit_values+1
    // [2035] phi ultoa::max_digits#7 = $b [phi:ultoa::@3->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #$b
    sta.z max_digits
    jmp __b1
    // [2035] phi from ultoa::@4 to ultoa::@1 [phi:ultoa::@4->ultoa::@1]
  __b5:
    // [2035] phi ultoa::digit_values#8 = RADIX_BINARY_VALUES_LONG [phi:ultoa::@4->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_BINARY_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_LONG
    sta.z digit_values+1
    // [2035] phi ultoa::max_digits#7 = $20 [phi:ultoa::@4->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #$20
    sta.z max_digits
    // ultoa::@1
  __b1:
    // [2036] phi from ultoa::@1 to ultoa::@6 [phi:ultoa::@1->ultoa::@6]
    // [2036] phi ultoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:ultoa::@1->ultoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2036] phi ultoa::started#2 = 0 [phi:ultoa::@1->ultoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [2036] phi ultoa::value#2 = ultoa::value#1 [phi:ultoa::@1->ultoa::@6#2] -- register_copy 
    // [2036] phi ultoa::digit#2 = 0 [phi:ultoa::@1->ultoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // ultoa::@6
  __b6:
    // max_digits-1
    // [2037] ultoa::$4 = ultoa::max_digits#7 - 1 -- vbuz1=vbuz2_minus_1 
    ldx.z max_digits
    dex
    stx.z ultoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2038] if(ultoa::digit#2<ultoa::$4) goto ultoa::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z digit
    cmp.z ultoa__4
    bcc __b7
    // ultoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2039] ultoa::$11 = (char)ultoa::value#2 -- vbuz1=_byte_vduz2 
    lda.z value
    sta.z ultoa__11
    // [2040] *ultoa::buffer#11 = DIGITS[ultoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2041] ultoa::buffer#3 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2042] *ultoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // ultoa::@7
  __b7:
    // unsigned long digit_value = digit_values[digit]
    // [2043] ultoa::$10 = ultoa::digit#2 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z digit
    asl
    asl
    sta.z ultoa__10
    // [2044] ultoa::digit_value#0 = ultoa::digit_values#8[ultoa::$10] -- vduz1=pduz2_derefidx_vbuz3 
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
    // [2045] if(0!=ultoa::started#2) goto ultoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // ultoa::@12
    // [2046] if(ultoa::value#2>=ultoa::digit_value#0) goto ultoa::@10 -- vduz1_ge_vduz2_then_la1 
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
    // [2047] phi from ultoa::@12 to ultoa::@9 [phi:ultoa::@12->ultoa::@9]
    // [2047] phi ultoa::buffer#14 = ultoa::buffer#11 [phi:ultoa::@12->ultoa::@9#0] -- register_copy 
    // [2047] phi ultoa::started#4 = ultoa::started#2 [phi:ultoa::@12->ultoa::@9#1] -- register_copy 
    // [2047] phi ultoa::value#6 = ultoa::value#2 [phi:ultoa::@12->ultoa::@9#2] -- register_copy 
    // ultoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2048] ultoa::digit#1 = ++ ultoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [2036] phi from ultoa::@9 to ultoa::@6 [phi:ultoa::@9->ultoa::@6]
    // [2036] phi ultoa::buffer#11 = ultoa::buffer#14 [phi:ultoa::@9->ultoa::@6#0] -- register_copy 
    // [2036] phi ultoa::started#2 = ultoa::started#4 [phi:ultoa::@9->ultoa::@6#1] -- register_copy 
    // [2036] phi ultoa::value#2 = ultoa::value#6 [phi:ultoa::@9->ultoa::@6#2] -- register_copy 
    // [2036] phi ultoa::digit#2 = ultoa::digit#1 [phi:ultoa::@9->ultoa::@6#3] -- register_copy 
    jmp __b6
    // ultoa::@10
  __b10:
    // ultoa_append(buffer++, value, digit_value)
    // [2049] ultoa_append::buffer#0 = ultoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z ultoa_append.buffer
    lda.z buffer+1
    sta.z ultoa_append.buffer+1
    // [2050] ultoa_append::value#0 = ultoa::value#2
    // [2051] ultoa_append::sub#0 = ultoa::digit_value#0
    // [2052] call ultoa_append
    // [2345] phi from ultoa::@10 to ultoa_append [phi:ultoa::@10->ultoa_append]
    jsr ultoa_append
    // ultoa_append(buffer++, value, digit_value)
    // [2053] ultoa_append::return#0 = ultoa_append::value#2
    // ultoa::@11
    // value = ultoa_append(buffer++, value, digit_value)
    // [2054] ultoa::value#0 = ultoa_append::return#0
    // value = ultoa_append(buffer++, value, digit_value);
    // [2055] ultoa::buffer#4 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2047] phi from ultoa::@11 to ultoa::@9 [phi:ultoa::@11->ultoa::@9]
    // [2047] phi ultoa::buffer#14 = ultoa::buffer#4 [phi:ultoa::@11->ultoa::@9#0] -- register_copy 
    // [2047] phi ultoa::started#4 = 1 [phi:ultoa::@11->ultoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [2047] phi ultoa::value#6 = ultoa::value#0 [phi:ultoa::@11->ultoa::@9#2] -- register_copy 
    jmp __b9
}
  // cputsxy
// Move cursor and output a NUL-terminated string
// Same as "gotoxy (x, y); puts (s);"
// void cputsxy(__mem() char x, __zp($de) char y, const char *s)
cputsxy: {
    .label y = $de
    // gotoxy(x, y)
    // [2056] gotoxy::x#1 = cputsxy::x#0 -- vbuz1=vbum2 
    lda x
    sta.z gotoxy.x
    // [2057] gotoxy::y#1 = cputsxy::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [2058] call gotoxy
    // [486] phi from cputsxy to gotoxy [phi:cputsxy->gotoxy]
    // [486] phi gotoxy::y#29 = gotoxy::y#1 [phi:cputsxy->gotoxy#0] -- register_copy 
    // [486] phi gotoxy::x#29 = gotoxy::x#1 [phi:cputsxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [2059] phi from cputsxy to cputsxy::@1 [phi:cputsxy->cputsxy::@1]
    // cputsxy::@1
    // cputs(s)
    // [2060] call cputs
    // [2352] phi from cputsxy::@1 to cputs [phi:cputsxy::@1->cputs]
    jsr cputs
    // cputsxy::@return
    // }
    // [2061] return 
    rts
  .segment Data
    .label x = frame_maskxy.cpeekcxy1_y
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
    .label rom_chip_address = $73
    .label address = $f5
    // rom_sector_erase::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2063] rom_sector_erase::rom_ptr1_$2 = (unsigned int)rom_sector_erase::address#0 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_sector_erase__2
    lda.z address+1
    sta.z rom_ptr1_rom_sector_erase__2+1
    // [2064] rom_sector_erase::rom_ptr1_$0 = rom_sector_erase::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_sector_erase__0
    and #<$3fff
    sta.z rom_ptr1_rom_sector_erase__0
    lda.z rom_ptr1_rom_sector_erase__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_sector_erase__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2065] rom_sector_erase::rom_ptr1_return#0 = rom_sector_erase::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_sector_erase::@1
    // unsigned long rom_chip_address = address & ROM_CHIP_MASK
    // [2066] rom_sector_erase::rom_chip_address#0 = rom_sector_erase::address#0 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [2067] rom_unlock::address#0 = rom_sector_erase::rom_chip_address#0 + $5555 -- vduz1=vduz1_plus_vwuc1 
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
    // [2068] call rom_unlock
    // [1736] phi from rom_sector_erase::@1 to rom_unlock [phi:rom_sector_erase::@1->rom_unlock]
    // [1736] phi rom_unlock::unlock_code#5 = $80 [phi:rom_sector_erase::@1->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$80
    sta.z rom_unlock.unlock_code
    // [1736] phi rom_unlock::address#5 = rom_unlock::address#0 [phi:rom_sector_erase::@1->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@2
    // rom_unlock(address, 0x30)
    // [2069] rom_unlock::address#1 = rom_sector_erase::address#0 -- vduz1=vduz2 
    lda.z address
    sta.z rom_unlock.address
    lda.z address+1
    sta.z rom_unlock.address+1
    lda.z address+2
    sta.z rom_unlock.address+2
    lda.z address+3
    sta.z rom_unlock.address+3
    // [2070] call rom_unlock
    // [1736] phi from rom_sector_erase::@2 to rom_unlock [phi:rom_sector_erase::@2->rom_unlock]
    // [1736] phi rom_unlock::unlock_code#5 = $30 [phi:rom_sector_erase::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$30
    sta.z rom_unlock.unlock_code
    // [1736] phi rom_unlock::address#5 = rom_unlock::address#1 [phi:rom_sector_erase::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@3
    // rom_wait(ptr_rom)
    // [2071] rom_wait::ptr_rom#0 = (char *)rom_sector_erase::rom_ptr1_return#0
    // [2072] call rom_wait
    // [2361] phi from rom_sector_erase::@3 to rom_wait [phi:rom_sector_erase::@3->rom_wait]
    // [2361] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#0 [phi:rom_sector_erase::@3->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_sector_erase::@return
    // }
    // [2073] return 
    rts
}
  // rom_write
/* inline */
// unsigned long rom_write(__zp($de) char flash_ram_bank, __zp($61) char *flash_ram_address, __zp($ac) unsigned long flash_rom_address, unsigned int flash_rom_size)
rom_write: {
    .label rom_chip_address = $bd
    .label flash_rom_address = $ac
    .label flash_ram_address = $61
    .label flashed_bytes = $79
    .label flash_ram_bank = $de
    // unsigned long rom_chip_address = flash_rom_address & ROM_CHIP_MASK
    // [2074] rom_write::rom_chip_address#0 = rom_write::flash_rom_address#1 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [2075] BRAM = rom_write::flash_ram_bank#0 -- vbuz1=vbuz2 
    lda.z flash_ram_bank
    sta.z BRAM
    // [2076] phi from rom_write::bank_set_bram1 to rom_write::@1 [phi:rom_write::bank_set_bram1->rom_write::@1]
    // [2076] phi rom_write::flash_ram_address#2 = rom_write::flash_ram_address#1 [phi:rom_write::bank_set_bram1->rom_write::@1#0] -- register_copy 
    // [2076] phi rom_write::flash_rom_address#3 = rom_write::flash_rom_address#1 [phi:rom_write::bank_set_bram1->rom_write::@1#1] -- register_copy 
    // [2076] phi rom_write::flashed_bytes#2 = 0 [phi:rom_write::bank_set_bram1->rom_write::@1#2] -- vduz1=vduc1 
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
    // [2077] if(rom_write::flashed_bytes#2<PROGRESS_CELL) goto rom_write::@2 -- vduz1_lt_vduc1_then_la1 
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
    // [2078] return 
    rts
    // rom_write::@2
  __b2:
    // rom_unlock(rom_chip_address + 0x05555, 0xA0)
    // [2079] rom_unlock::address#4 = rom_write::rom_chip_address#0 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [2080] call rom_unlock
    // [1736] phi from rom_write::@2 to rom_unlock [phi:rom_write::@2->rom_unlock]
    // [1736] phi rom_unlock::unlock_code#5 = $a0 [phi:rom_write::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$a0
    sta.z rom_unlock.unlock_code
    // [1736] phi rom_unlock::address#5 = rom_unlock::address#4 [phi:rom_write::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_write::@3
    // rom_byte_program(flash_rom_address, *flash_ram_address)
    // [2081] rom_byte_program::address#0 = rom_write::flash_rom_address#3 -- vduz1=vduz2 
    lda.z flash_rom_address
    sta.z rom_byte_program.address
    lda.z flash_rom_address+1
    sta.z rom_byte_program.address+1
    lda.z flash_rom_address+2
    sta.z rom_byte_program.address+2
    lda.z flash_rom_address+3
    sta.z rom_byte_program.address+3
    // [2082] rom_byte_program::value#0 = *rom_write::flash_ram_address#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (flash_ram_address),y
    sta.z rom_byte_program.value
    // [2083] call rom_byte_program
    // [2368] phi from rom_write::@3 to rom_byte_program [phi:rom_write::@3->rom_byte_program]
    jsr rom_byte_program
    // rom_write::@4
    // flash_rom_address++;
    // [2084] rom_write::flash_rom_address#0 = ++ rom_write::flash_rom_address#3 -- vduz1=_inc_vduz1 
    inc.z flash_rom_address
    bne !+
    inc.z flash_rom_address+1
    bne !+
    inc.z flash_rom_address+2
    bne !+
    inc.z flash_rom_address+3
  !:
    // flash_ram_address++;
    // [2085] rom_write::flash_ram_address#0 = ++ rom_write::flash_ram_address#2 -- pbuz1=_inc_pbuz1 
    inc.z flash_ram_address
    bne !+
    inc.z flash_ram_address+1
  !:
    // flashed_bytes++;
    // [2086] rom_write::flashed_bytes#1 = ++ rom_write::flashed_bytes#2 -- vduz1=_inc_vduz1 
    inc.z flashed_bytes
    bne !+
    inc.z flashed_bytes+1
    bne !+
    inc.z flashed_bytes+2
    bne !+
    inc.z flashed_bytes+3
  !:
    // [2076] phi from rom_write::@4 to rom_write::@1 [phi:rom_write::@4->rom_write::@1]
    // [2076] phi rom_write::flash_ram_address#2 = rom_write::flash_ram_address#0 [phi:rom_write::@4->rom_write::@1#0] -- register_copy 
    // [2076] phi rom_write::flash_rom_address#3 = rom_write::flash_rom_address#0 [phi:rom_write::@4->rom_write::@1#1] -- register_copy 
    // [2076] phi rom_write::flashed_bytes#2 = rom_write::flashed_bytes#1 [phi:rom_write::@4->rom_write::@1#2] -- register_copy 
    jmp __b1
}
  // insertup
// Insert a new line, and scroll the upper part of the screen up.
// void insertup(char rows)
insertup: {
    .label insertup__0 = $46
    .label insertup__4 = $44
    .label insertup__6 = $45
    .label insertup__7 = $44
    .label width = $46
    .label y = $41
    // __conio.width+1
    // [2087] insertup::$0 = *((char *)&__conio+6) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+6
    inc
    sta.z insertup__0
    // unsigned char width = (__conio.width+1) * 2
    // [2088] insertup::width#0 = insertup::$0 << 1 -- vbuz1=vbuz1_rol_1 
    // {asm{.byte $db}}
    asl.z width
    // [2089] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [2089] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [2090] if(insertup::y#2<*((char *)&__conio+1)) goto insertup::@2 -- vbuz1_lt__deref_pbuc1_then_la1 
    lda.z y
    cmp __conio+1
    bcc __b2
    // [2091] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [2092] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [2093] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [2094] insertup::$4 = insertup::y#2 + 1 -- vbuz1=vbuz2_plus_1 
    lda.z y
    inc
    sta.z insertup__4
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [2095] insertup::$6 = insertup::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z insertup__6
    // [2096] insertup::$7 = insertup::$4 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z insertup__7
    // [2097] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z memcpy8_vram_vram.dbank_vram
    // [2098] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__6
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.doffset_vram+1
    // [2099] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z memcpy8_vram_vram.sbank_vram
    // [2100] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__7
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.soffset_vram+1
    // [2101] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbuz1=vbuz2 
    lda.z width
    sta.z memcpy8_vram_vram.num8_1
    // [2102] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [2103] insertup::y#1 = ++ insertup::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [2089] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [2089] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
    jmp __b1
}
  // clearline
clearline: {
    .label clearline__0 = $2c
    .label clearline__1 = $2e
    .label clearline__2 = $2f
    .label clearline__3 = $2d
    .label addr = $42
    .label c = $22
    // unsigned int addr = __conio.offsets[__conio.cursor_y]
    // [2104] clearline::$3 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z clearline__3
    // [2105] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwuz1=pwuc1_derefidx_vbuz2 
    tay
    lda __conio+$15,y
    sta.z addr
    lda __conio+$15+1,y
    sta.z addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2106] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [2107] clearline::$0 = byte0  clearline::addr#0 -- vbuz1=_byte0_vwuz2 
    lda.z addr
    sta.z clearline__0
    // *VERA_ADDRX_L = BYTE0(addr)
    // [2108] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [2109] clearline::$1 = byte1  clearline::addr#0 -- vbuz1=_byte1_vwuz2 
    lda.z addr+1
    sta.z clearline__1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [2110] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [2111] clearline::$2 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clearline__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [2112] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [2113] clearline::c#0 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z c
    // [2114] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [2114] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [2115] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [2116] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [2117] clearline::c#1 = -- clearline::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [2118] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b1
    // clearline::@return
    // }
    // [2119] return 
    rts
}
  // frame_maskxy
// __mem() char frame_maskxy(__mem() char x, __mem() char y)
frame_maskxy: {
    .label cpeekcxy1_cpeekc1_frame_maskxy__0 = $72
    .label cpeekcxy1_cpeekc1_frame_maskxy__1 = $5a
    .label cpeekcxy1_cpeekc1_frame_maskxy__2 = $51
    .label c = $5d
    // frame_maskxy::cpeekcxy1
    // gotoxy(x,y)
    // [2121] gotoxy::x#5 = frame_maskxy::cpeekcxy1_x#0 -- vbuz1=vbum2 
    lda cpeekcxy1_x
    sta.z gotoxy.x
    // [2122] gotoxy::y#5 = frame_maskxy::cpeekcxy1_y#0 -- vbuz1=vbum2 
    lda cpeekcxy1_y
    sta.z gotoxy.y
    // [2123] call gotoxy
    // [486] phi from frame_maskxy::cpeekcxy1 to gotoxy [phi:frame_maskxy::cpeekcxy1->gotoxy]
    // [486] phi gotoxy::y#29 = gotoxy::y#5 [phi:frame_maskxy::cpeekcxy1->gotoxy#0] -- register_copy 
    // [486] phi gotoxy::x#29 = gotoxy::x#5 [phi:frame_maskxy::cpeekcxy1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // frame_maskxy::cpeekcxy1_cpeekc1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2124] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [2125] frame_maskxy::cpeekcxy1_cpeekc1_$0 = byte0  *((unsigned int *)&__conio+$13) -- vbuz1=_byte0__deref_pwuc1 
    lda __conio+$13
    sta.z cpeekcxy1_cpeekc1_frame_maskxy__0
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [2126] *VERA_ADDRX_L = frame_maskxy::cpeekcxy1_cpeekc1_$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [2127] frame_maskxy::cpeekcxy1_cpeekc1_$1 = byte1  *((unsigned int *)&__conio+$13) -- vbuz1=_byte1__deref_pwuc1 
    lda __conio+$13+1
    sta.z cpeekcxy1_cpeekc1_frame_maskxy__1
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [2128] *VERA_ADDRX_M = frame_maskxy::cpeekcxy1_cpeekc1_$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_0
    // [2129] frame_maskxy::cpeekcxy1_cpeekc1_$2 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z cpeekcxy1_cpeekc1_frame_maskxy__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_0
    // [2130] *VERA_ADDRX_H = frame_maskxy::cpeekcxy1_cpeekc1_$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // return *VERA_DATA0;
    // [2131] frame_maskxy::c#0 = *VERA_DATA0 -- vbuz1=_deref_pbuc1 
    lda VERA_DATA0
    sta.z c
    // frame_maskxy::@12
    // case 0x70: // DR corner.
    //             return 0b0110;
    // [2132] if(frame_maskxy::c#0==$70) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$70
    cmp.z c
    beq __b2
    // frame_maskxy::@1
    // case 0x6E: // DL corner.
    //             return 0b0011;
    // [2133] if(frame_maskxy::c#0==$6e) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6e
    cmp.z c
    beq __b1
    // frame_maskxy::@2
    // case 0x6D: // UR corner.
    //             return 0b1100;
    // [2134] if(frame_maskxy::c#0==$6d) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6d
    cmp.z c
    beq __b3
    // frame_maskxy::@3
    // case 0x7D: // UL corner.
    //             return 0b1001;
    // [2135] if(frame_maskxy::c#0==$7d) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$7d
    cmp.z c
    beq __b4
    // frame_maskxy::@4
    // case 0x40: // HL line.
    //             return 0b0101;
    // [2136] if(frame_maskxy::c#0==$40) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$40
    cmp.z c
    beq __b5
    // frame_maskxy::@5
    // case 0x5D: // VL line.
    //             return 0b1010;
    // [2137] if(frame_maskxy::c#0==$5d) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$5d
    cmp.z c
    beq __b6
    // frame_maskxy::@6
    // case 0x6B: // VR junction.
    //             return 0b1110;
    // [2138] if(frame_maskxy::c#0==$6b) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6b
    cmp.z c
    beq __b7
    // frame_maskxy::@7
    // case 0x73: // VL junction.
    //             return 0b1011;
    // [2139] if(frame_maskxy::c#0==$73) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$73
    cmp.z c
    beq __b8
    // frame_maskxy::@8
    // case 0x72: // HD junction.
    //             return 0b0111;
    // [2140] if(frame_maskxy::c#0==$72) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$72
    cmp.z c
    beq __b9
    // frame_maskxy::@9
    // case 0x71: // HU junction.
    //             return 0b1101;
    // [2141] if(frame_maskxy::c#0==$71) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$71
    cmp.z c
    beq __b10
    // frame_maskxy::@10
    // case 0x5B: // HV junction.
    //             return 0b1111;
    // [2142] if(frame_maskxy::c#0==$5b) goto frame_maskxy::@11 -- vbuz1_eq_vbuc1_then_la1 
    lda #$5b
    cmp.z c
    beq __b11
    // [2144] phi from frame_maskxy::@10 to frame_maskxy::@return [phi:frame_maskxy::@10->frame_maskxy::@return]
    // [2144] phi frame_maskxy::return#12 = 0 [phi:frame_maskxy::@10->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    rts
    // [2143] phi from frame_maskxy::@10 to frame_maskxy::@11 [phi:frame_maskxy::@10->frame_maskxy::@11]
    // frame_maskxy::@11
  __b11:
    // [2144] phi from frame_maskxy::@11 to frame_maskxy::@return [phi:frame_maskxy::@11->frame_maskxy::@return]
    // [2144] phi frame_maskxy::return#12 = $f [phi:frame_maskxy::@11->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$f
    sta return
    rts
    // [2144] phi from frame_maskxy::@1 to frame_maskxy::@return [phi:frame_maskxy::@1->frame_maskxy::@return]
  __b1:
    // [2144] phi frame_maskxy::return#12 = 3 [phi:frame_maskxy::@1->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #3
    sta return
    rts
    // [2144] phi from frame_maskxy::@12 to frame_maskxy::@return [phi:frame_maskxy::@12->frame_maskxy::@return]
  __b2:
    // [2144] phi frame_maskxy::return#12 = 6 [phi:frame_maskxy::@12->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #6
    sta return
    rts
    // [2144] phi from frame_maskxy::@2 to frame_maskxy::@return [phi:frame_maskxy::@2->frame_maskxy::@return]
  __b3:
    // [2144] phi frame_maskxy::return#12 = $c [phi:frame_maskxy::@2->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$c
    sta return
    rts
    // [2144] phi from frame_maskxy::@3 to frame_maskxy::@return [phi:frame_maskxy::@3->frame_maskxy::@return]
  __b4:
    // [2144] phi frame_maskxy::return#12 = 9 [phi:frame_maskxy::@3->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #9
    sta return
    rts
    // [2144] phi from frame_maskxy::@4 to frame_maskxy::@return [phi:frame_maskxy::@4->frame_maskxy::@return]
  __b5:
    // [2144] phi frame_maskxy::return#12 = 5 [phi:frame_maskxy::@4->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #5
    sta return
    rts
    // [2144] phi from frame_maskxy::@5 to frame_maskxy::@return [phi:frame_maskxy::@5->frame_maskxy::@return]
  __b6:
    // [2144] phi frame_maskxy::return#12 = $a [phi:frame_maskxy::@5->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$a
    sta return
    rts
    // [2144] phi from frame_maskxy::@6 to frame_maskxy::@return [phi:frame_maskxy::@6->frame_maskxy::@return]
  __b7:
    // [2144] phi frame_maskxy::return#12 = $e [phi:frame_maskxy::@6->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$e
    sta return
    rts
    // [2144] phi from frame_maskxy::@7 to frame_maskxy::@return [phi:frame_maskxy::@7->frame_maskxy::@return]
  __b8:
    // [2144] phi frame_maskxy::return#12 = $b [phi:frame_maskxy::@7->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$b
    sta return
    rts
    // [2144] phi from frame_maskxy::@8 to frame_maskxy::@return [phi:frame_maskxy::@8->frame_maskxy::@return]
  __b9:
    // [2144] phi frame_maskxy::return#12 = 7 [phi:frame_maskxy::@8->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #7
    sta return
    rts
    // [2144] phi from frame_maskxy::@9 to frame_maskxy::@return [phi:frame_maskxy::@9->frame_maskxy::@return]
  __b10:
    // [2144] phi frame_maskxy::return#12 = $d [phi:frame_maskxy::@9->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$d
    sta return
    // frame_maskxy::@return
    // }
    // [2145] return 
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
// __zp($6c) char frame_char(__mem() char mask)
frame_char: {
    .label return = $6c
    // case 0b0110:
    //             return 0x70;
    // [2147] if(frame_char::mask#10==6) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    lda #6
    cmp mask
    beq __b1
    // frame_char::@1
    // case 0b0011:
    //             return 0x6E;
    // [2148] if(frame_char::mask#10==3) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // DR corner.
    lda #3
    cmp mask
    beq __b2
    // frame_char::@2
    // case 0b1100:
    //             return 0x6D;
    // [2149] if(frame_char::mask#10==$c) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // DL corner.
    lda #$c
    cmp mask
    beq __b3
    // frame_char::@3
    // case 0b1001:
    //             return 0x7D;
    // [2150] if(frame_char::mask#10==9) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // UR corner.
    lda #9
    cmp mask
    beq __b4
    // frame_char::@4
    // case 0b0101:
    //             return 0x40;
    // [2151] if(frame_char::mask#10==5) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // UL corner.
    lda #5
    cmp mask
    beq __b5
    // frame_char::@5
    // case 0b1010:
    //             return 0x5D;
    // [2152] if(frame_char::mask#10==$a) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // HL line.
    lda #$a
    cmp mask
    beq __b6
    // frame_char::@6
    // case 0b1110:
    //             return 0x6B;
    // [2153] if(frame_char::mask#10==$e) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // VL line.
    lda #$e
    cmp mask
    beq __b7
    // frame_char::@7
    // case 0b1011:
    //             return 0x73;
    // [2154] if(frame_char::mask#10==$b) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // VR junction.
    lda #$b
    cmp mask
    beq __b8
    // frame_char::@8
    // case 0b0111:
    //             return 0x72;
    // [2155] if(frame_char::mask#10==7) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // VL junction.
    lda #7
    cmp mask
    beq __b9
    // frame_char::@9
    // case 0b1101:
    //             return 0x71;
    // [2156] if(frame_char::mask#10==$d) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // HD junction.
    lda #$d
    cmp mask
    beq __b10
    // frame_char::@10
    // case 0b1111:
    //             return 0x5B;
    // [2157] if(frame_char::mask#10==$f) goto frame_char::@11 -- vbum1_eq_vbuc1_then_la1 
    // HU junction.
    lda #$f
    cmp mask
    beq __b11
    // [2159] phi from frame_char::@10 to frame_char::@return [phi:frame_char::@10->frame_char::@return]
    // [2159] phi frame_char::return#12 = $20 [phi:frame_char::@10->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$20
    sta.z return
    rts
    // [2158] phi from frame_char::@10 to frame_char::@11 [phi:frame_char::@10->frame_char::@11]
    // frame_char::@11
  __b11:
    // [2159] phi from frame_char::@11 to frame_char::@return [phi:frame_char::@11->frame_char::@return]
    // [2159] phi frame_char::return#12 = $5b [phi:frame_char::@11->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z return
    rts
    // [2159] phi from frame_char to frame_char::@return [phi:frame_char->frame_char::@return]
  __b1:
    // [2159] phi frame_char::return#12 = $70 [phi:frame_char->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$70
    sta.z return
    rts
    // [2159] phi from frame_char::@1 to frame_char::@return [phi:frame_char::@1->frame_char::@return]
  __b2:
    // [2159] phi frame_char::return#12 = $6e [phi:frame_char::@1->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6e
    sta.z return
    rts
    // [2159] phi from frame_char::@2 to frame_char::@return [phi:frame_char::@2->frame_char::@return]
  __b3:
    // [2159] phi frame_char::return#12 = $6d [phi:frame_char::@2->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6d
    sta.z return
    rts
    // [2159] phi from frame_char::@3 to frame_char::@return [phi:frame_char::@3->frame_char::@return]
  __b4:
    // [2159] phi frame_char::return#12 = $7d [phi:frame_char::@3->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$7d
    sta.z return
    rts
    // [2159] phi from frame_char::@4 to frame_char::@return [phi:frame_char::@4->frame_char::@return]
  __b5:
    // [2159] phi frame_char::return#12 = $40 [phi:frame_char::@4->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z return
    rts
    // [2159] phi from frame_char::@5 to frame_char::@return [phi:frame_char::@5->frame_char::@return]
  __b6:
    // [2159] phi frame_char::return#12 = $5d [phi:frame_char::@5->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z return
    rts
    // [2159] phi from frame_char::@6 to frame_char::@return [phi:frame_char::@6->frame_char::@return]
  __b7:
    // [2159] phi frame_char::return#12 = $6b [phi:frame_char::@6->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z return
    rts
    // [2159] phi from frame_char::@7 to frame_char::@return [phi:frame_char::@7->frame_char::@return]
  __b8:
    // [2159] phi frame_char::return#12 = $73 [phi:frame_char::@7->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z return
    rts
    // [2159] phi from frame_char::@8 to frame_char::@return [phi:frame_char::@8->frame_char::@return]
  __b9:
    // [2159] phi frame_char::return#12 = $72 [phi:frame_char::@8->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z return
    rts
    // [2159] phi from frame_char::@9 to frame_char::@return [phi:frame_char::@9->frame_char::@return]
  __b10:
    // [2159] phi frame_char::return#12 = $71 [phi:frame_char::@9->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z return
    // frame_char::@return
    // }
    // [2160] return 
    rts
  .segment Data
    .label mask = frame_maskxy.return
}
.segment Code
  // print_chip_led
// void print_chip_led(__zp($72) char x, char y, __zp($3a) char w, __zp($4f) char tc, char bc)
print_chip_led: {
    .label i = $30
    .label tc = $4f
    .label x = $72
    .label w = $3a
    // gotoxy(x, y)
    // [2162] gotoxy::x#8 = print_chip_led::x#3 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [2163] call gotoxy
    // [486] phi from print_chip_led to gotoxy [phi:print_chip_led->gotoxy]
    // [486] phi gotoxy::y#29 = 3 [phi:print_chip_led->gotoxy#0] -- vbuz1=vbuc1 
    lda #3
    sta.z gotoxy.y
    // [486] phi gotoxy::x#29 = gotoxy::x#8 [phi:print_chip_led->gotoxy#1] -- register_copy 
    jsr gotoxy
    // print_chip_led::@4
    // textcolor(tc)
    // [2164] textcolor::color#10 = print_chip_led::tc#3 -- vbuz1=vbuz2 
    lda.z tc
    sta.z textcolor.color
    // [2165] call textcolor
    // [468] phi from print_chip_led::@4 to textcolor [phi:print_chip_led::@4->textcolor]
    // [468] phi textcolor::color#16 = textcolor::color#10 [phi:print_chip_led::@4->textcolor#0] -- register_copy 
    jsr textcolor
    // [2166] phi from print_chip_led::@4 to print_chip_led::@5 [phi:print_chip_led::@4->print_chip_led::@5]
    // print_chip_led::@5
    // bgcolor(bc)
    // [2167] call bgcolor
    // [473] phi from print_chip_led::@5 to bgcolor [phi:print_chip_led::@5->bgcolor]
    // [473] phi bgcolor::color#14 = BLUE [phi:print_chip_led::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [2168] phi from print_chip_led::@5 to print_chip_led::@1 [phi:print_chip_led::@5->print_chip_led::@1]
    // [2168] phi print_chip_led::i#2 = 0 [phi:print_chip_led::@5->print_chip_led::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // print_chip_led::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [2169] if(print_chip_led::i#2<print_chip_led::w#5) goto print_chip_led::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [2170] phi from print_chip_led::@1 to print_chip_led::@3 [phi:print_chip_led::@1->print_chip_led::@3]
    // print_chip_led::@3
    // textcolor(WHITE)
    // [2171] call textcolor
    // [468] phi from print_chip_led::@3 to textcolor [phi:print_chip_led::@3->textcolor]
    // [468] phi textcolor::color#16 = WHITE [phi:print_chip_led::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [2172] phi from print_chip_led::@3 to print_chip_led::@6 [phi:print_chip_led::@3->print_chip_led::@6]
    // print_chip_led::@6
    // bgcolor(BLUE)
    // [2173] call bgcolor
    // [473] phi from print_chip_led::@6 to bgcolor [phi:print_chip_led::@6->bgcolor]
    // [473] phi bgcolor::color#14 = BLUE [phi:print_chip_led::@6->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_led::@return
    // }
    // [2174] return 
    rts
    // print_chip_led::@2
  __b2:
    // cputc(0xE2)
    // [2175] stackpush(char) = $e2 -- _stackpushbyte_=vbuc1 
    lda #$e2
    pha
    // [2176] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [2178] print_chip_led::i#1 = ++ print_chip_led::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2168] phi from print_chip_led::@2 to print_chip_led::@1 [phi:print_chip_led::@2->print_chip_led::@1]
    // [2168] phi print_chip_led::i#2 = print_chip_led::i#1 [phi:print_chip_led::@2->print_chip_led::@1#0] -- register_copy 
    jmp __b1
}
  // print_chip_line
// void print_chip_line(__zp($67) char x, __zp($65) char y, __zp($5c) char w, __zp($69) char c)
print_chip_line: {
    .label i = $31
    .label x = $67
    .label w = $5c
    .label c = $69
    .label y = $65
    // gotoxy(x, y)
    // [2180] gotoxy::x#6 = print_chip_line::x#16 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [2181] gotoxy::y#6 = print_chip_line::y#16 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [2182] call gotoxy
    // [486] phi from print_chip_line to gotoxy [phi:print_chip_line->gotoxy]
    // [486] phi gotoxy::y#29 = gotoxy::y#6 [phi:print_chip_line->gotoxy#0] -- register_copy 
    // [486] phi gotoxy::x#29 = gotoxy::x#6 [phi:print_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [2183] phi from print_chip_line to print_chip_line::@4 [phi:print_chip_line->print_chip_line::@4]
    // print_chip_line::@4
    // textcolor(GREY)
    // [2184] call textcolor
    // [468] phi from print_chip_line::@4 to textcolor [phi:print_chip_line::@4->textcolor]
    // [468] phi textcolor::color#16 = GREY [phi:print_chip_line::@4->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [2185] phi from print_chip_line::@4 to print_chip_line::@5 [phi:print_chip_line::@4->print_chip_line::@5]
    // print_chip_line::@5
    // bgcolor(BLUE)
    // [2186] call bgcolor
    // [473] phi from print_chip_line::@5 to bgcolor [phi:print_chip_line::@5->bgcolor]
    // [473] phi bgcolor::color#14 = BLUE [phi:print_chip_line::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@6
    // cputc(VERA_CHR_UR)
    // [2187] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [2188] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [2190] call textcolor
    // [468] phi from print_chip_line::@6 to textcolor [phi:print_chip_line::@6->textcolor]
    // [468] phi textcolor::color#16 = WHITE [phi:print_chip_line::@6->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [2191] phi from print_chip_line::@6 to print_chip_line::@7 [phi:print_chip_line::@6->print_chip_line::@7]
    // print_chip_line::@7
    // bgcolor(BLACK)
    // [2192] call bgcolor
    // [473] phi from print_chip_line::@7 to bgcolor [phi:print_chip_line::@7->bgcolor]
    // [473] phi bgcolor::color#14 = BLACK [phi:print_chip_line::@7->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // [2193] phi from print_chip_line::@7 to print_chip_line::@1 [phi:print_chip_line::@7->print_chip_line::@1]
    // [2193] phi print_chip_line::i#2 = 0 [phi:print_chip_line::@7->print_chip_line::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // print_chip_line::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [2194] if(print_chip_line::i#2<print_chip_line::w#10) goto print_chip_line::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [2195] phi from print_chip_line::@1 to print_chip_line::@3 [phi:print_chip_line::@1->print_chip_line::@3]
    // print_chip_line::@3
    // textcolor(GREY)
    // [2196] call textcolor
    // [468] phi from print_chip_line::@3 to textcolor [phi:print_chip_line::@3->textcolor]
    // [468] phi textcolor::color#16 = GREY [phi:print_chip_line::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [2197] phi from print_chip_line::@3 to print_chip_line::@8 [phi:print_chip_line::@3->print_chip_line::@8]
    // print_chip_line::@8
    // bgcolor(BLUE)
    // [2198] call bgcolor
    // [473] phi from print_chip_line::@8 to bgcolor [phi:print_chip_line::@8->bgcolor]
    // [473] phi bgcolor::color#14 = BLUE [phi:print_chip_line::@8->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@9
    // cputc(VERA_CHR_UL)
    // [2199] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [2200] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [2202] call textcolor
    // [468] phi from print_chip_line::@9 to textcolor [phi:print_chip_line::@9->textcolor]
    // [468] phi textcolor::color#16 = WHITE [phi:print_chip_line::@9->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [2203] phi from print_chip_line::@9 to print_chip_line::@10 [phi:print_chip_line::@9->print_chip_line::@10]
    // print_chip_line::@10
    // bgcolor(BLACK)
    // [2204] call bgcolor
    // [473] phi from print_chip_line::@10 to bgcolor [phi:print_chip_line::@10->bgcolor]
    // [473] phi bgcolor::color#14 = BLACK [phi:print_chip_line::@10->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@11
    // cputcxy(x+2, y, c)
    // [2205] cputcxy::x#8 = print_chip_line::x#16 + 2 -- vbuz1=vbuz1_plus_2 
    lda.z cputcxy.x
    clc
    adc #2
    sta.z cputcxy.x
    // [2206] cputcxy::y#8 = print_chip_line::y#16
    // [2207] cputcxy::c#8 = print_chip_line::c#15 -- vbuz1=vbuz2 
    lda.z c
    sta.z cputcxy.c
    // [2208] call cputcxy
    // [1595] phi from print_chip_line::@11 to cputcxy [phi:print_chip_line::@11->cputcxy]
    // [1595] phi cputcxy::c#13 = cputcxy::c#8 [phi:print_chip_line::@11->cputcxy#0] -- register_copy 
    // [1595] phi cputcxy::y#13 = cputcxy::y#8 [phi:print_chip_line::@11->cputcxy#1] -- register_copy 
    // [1595] phi cputcxy::x#13 = cputcxy::x#8 [phi:print_chip_line::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // print_chip_line::@return
    // }
    // [2209] return 
    rts
    // print_chip_line::@2
  __b2:
    // cputc(VERA_CHR_SPACE)
    // [2210] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [2211] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [2213] print_chip_line::i#1 = ++ print_chip_line::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2193] phi from print_chip_line::@2 to print_chip_line::@1 [phi:print_chip_line::@2->print_chip_line::@1]
    // [2193] phi print_chip_line::i#2 = print_chip_line::i#1 [phi:print_chip_line::@2->print_chip_line::@1#0] -- register_copy 
    jmp __b1
}
  // print_chip_end
// void print_chip_end(__zp($b5) char x, char y, __zp($6a) char w)
print_chip_end: {
    .label i = $33
    .label x = $b5
    .label w = $6a
    // gotoxy(x, y)
    // [2214] gotoxy::x#7 = print_chip_end::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [2215] call gotoxy
    // [486] phi from print_chip_end to gotoxy [phi:print_chip_end->gotoxy]
    // [486] phi gotoxy::y#29 = print_chip::y#21 [phi:print_chip_end->gotoxy#0] -- vbuz1=vbuc1 
    lda #print_chip.y
    sta.z gotoxy.y
    // [486] phi gotoxy::x#29 = gotoxy::x#7 [phi:print_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [2216] phi from print_chip_end to print_chip_end::@4 [phi:print_chip_end->print_chip_end::@4]
    // print_chip_end::@4
    // textcolor(GREY)
    // [2217] call textcolor
    // [468] phi from print_chip_end::@4 to textcolor [phi:print_chip_end::@4->textcolor]
    // [468] phi textcolor::color#16 = GREY [phi:print_chip_end::@4->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [2218] phi from print_chip_end::@4 to print_chip_end::@5 [phi:print_chip_end::@4->print_chip_end::@5]
    // print_chip_end::@5
    // bgcolor(BLUE)
    // [2219] call bgcolor
    // [473] phi from print_chip_end::@5 to bgcolor [phi:print_chip_end::@5->bgcolor]
    // [473] phi bgcolor::color#14 = BLUE [phi:print_chip_end::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_end::@6
    // cputc(VERA_CHR_UR)
    // [2220] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [2221] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [2223] call textcolor
    // [468] phi from print_chip_end::@6 to textcolor [phi:print_chip_end::@6->textcolor]
    // [468] phi textcolor::color#16 = BLUE [phi:print_chip_end::@6->textcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z textcolor.color
    jsr textcolor
    // [2224] phi from print_chip_end::@6 to print_chip_end::@7 [phi:print_chip_end::@6->print_chip_end::@7]
    // print_chip_end::@7
    // bgcolor(BLACK)
    // [2225] call bgcolor
    // [473] phi from print_chip_end::@7 to bgcolor [phi:print_chip_end::@7->bgcolor]
    // [473] phi bgcolor::color#14 = BLACK [phi:print_chip_end::@7->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // [2226] phi from print_chip_end::@7 to print_chip_end::@1 [phi:print_chip_end::@7->print_chip_end::@1]
    // [2226] phi print_chip_end::i#2 = 0 [phi:print_chip_end::@7->print_chip_end::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // print_chip_end::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [2227] if(print_chip_end::i#2<print_chip_end::w#0) goto print_chip_end::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [2228] phi from print_chip_end::@1 to print_chip_end::@3 [phi:print_chip_end::@1->print_chip_end::@3]
    // print_chip_end::@3
    // textcolor(GREY)
    // [2229] call textcolor
    // [468] phi from print_chip_end::@3 to textcolor [phi:print_chip_end::@3->textcolor]
    // [468] phi textcolor::color#16 = GREY [phi:print_chip_end::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [2230] phi from print_chip_end::@3 to print_chip_end::@8 [phi:print_chip_end::@3->print_chip_end::@8]
    // print_chip_end::@8
    // bgcolor(BLUE)
    // [2231] call bgcolor
    // [473] phi from print_chip_end::@8 to bgcolor [phi:print_chip_end::@8->bgcolor]
    // [473] phi bgcolor::color#14 = BLUE [phi:print_chip_end::@8->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_end::@9
    // cputc(VERA_CHR_UL)
    // [2232] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [2233] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_end::@return
    // }
    // [2235] return 
    rts
    // print_chip_end::@2
  __b2:
    // cputc(VERA_CHR_HL)
    // [2236] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [2237] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [2239] print_chip_end::i#1 = ++ print_chip_end::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2226] phi from print_chip_end::@2 to print_chip_end::@1 [phi:print_chip_end::@2->print_chip_end::@1]
    // [2226] phi print_chip_end::i#2 = print_chip_end::i#1 [phi:print_chip_end::@2->print_chip_end::@1#0] -- register_copy 
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
// __zp($2a) unsigned int utoa_append(__zp($54) char *buffer, __zp($2a) unsigned int value, __zp($3f) unsigned int sub)
utoa_append: {
    .label buffer = $54
    .label value = $2a
    .label sub = $3f
    .label return = $2a
    .label digit = $30
    // [2241] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [2241] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [2241] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [2242] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwuz1_ge_vwuz2_then_la1 
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
    // [2243] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // utoa_append::@return
    // }
    // [2244] return 
    rts
    // utoa_append::@2
  __b2:
    // digit++;
    // [2245] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [2246] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    lda.z value+1
    sbc.z sub+1
    sta.z value+1
    // [2241] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [2241] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [2241] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
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
// void rom_write_byte(__zp($56) unsigned long address, __zp($5c) char value)
rom_write_byte: {
    .label rom_bank1_rom_write_byte__0 = $5a
    .label rom_bank1_rom_write_byte__1 = $51
    .label rom_bank1_rom_write_byte__2 = $4b
    .label rom_ptr1_rom_write_byte__0 = $49
    .label rom_ptr1_rom_write_byte__2 = $49
    .label rom_bank1_bank_unshifted = $4b
    .label rom_bank1_return = $5d
    .label rom_ptr1_return = $49
    .label address = $56
    .label value = $5c
    // rom_write_byte::rom_bank1
    // BYTE2(address)
    // [2248] rom_write_byte::rom_bank1_$0 = byte2  rom_write_byte::address#4 -- vbuz1=_byte2_vduz2 
    lda.z address+2
    sta.z rom_bank1_rom_write_byte__0
    // BYTE1(address)
    // [2249] rom_write_byte::rom_bank1_$1 = byte1  rom_write_byte::address#4 -- vbuz1=_byte1_vduz2 
    lda.z address+1
    sta.z rom_bank1_rom_write_byte__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2250] rom_write_byte::rom_bank1_$2 = rom_write_byte::rom_bank1_$0 w= rom_write_byte::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_write_byte__0
    sta.z rom_bank1_rom_write_byte__2+1
    lda.z rom_bank1_rom_write_byte__1
    sta.z rom_bank1_rom_write_byte__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2251] rom_write_byte::rom_bank1_bank_unshifted#0 = rom_write_byte::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2252] rom_write_byte::rom_bank1_return#0 = byte1  rom_write_byte::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwuz2 
    lda.z rom_bank1_bank_unshifted+1
    sta.z rom_bank1_return
    // rom_write_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2253] rom_write_byte::rom_ptr1_$2 = (unsigned int)rom_write_byte::address#4 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_write_byte__2
    lda.z address+1
    sta.z rom_ptr1_rom_write_byte__2+1
    // [2254] rom_write_byte::rom_ptr1_$0 = rom_write_byte::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_write_byte__0
    and #<$3fff
    sta.z rom_ptr1_rom_write_byte__0
    lda.z rom_ptr1_rom_write_byte__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_write_byte__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2255] rom_write_byte::rom_ptr1_return#0 = rom_write_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_write_byte::bank_set_brom1
    // BROM = bank
    // [2256] BROM = rom_write_byte::rom_bank1_return#0 -- vbuz1=vbuz2 
    lda.z rom_bank1_return
    sta.z BROM
    // rom_write_byte::@1
    // *ptr_rom = value
    // [2257] *((char *)rom_write_byte::rom_ptr1_return#0) = rom_write_byte::value#10 -- _deref_pbuz1=vbuz2 
    lda.z value
    ldy #0
    sta (rom_ptr1_return),y
    // rom_write_byte::@return
    // }
    // [2258] return 
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
    // [2260] return 
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
// __mem() int ferror(__zp($3f) struct $2 *stream)
ferror: {
    .label ferror__6 = $33
    .label ferror__15 = $e5
    .label cbm_k_setnam1_ferror__0 = $54
    .label cbm_k_readst1_status = $f0
    .label cbm_k_chrin2_ch = $f1
    .label stream = $3f
    .label sp = $31
    .label cbm_k_chrin1_return = $e5
    .label ch = $e5
    .label cbm_k_readst1_return = $33
    .label st = $33
    .label errno_len = $e6
    .label cbm_k_chrin2_return = $e5
    .label errno_parsed = $e9
    // unsigned char sp = (unsigned char)stream
    // [2261] ferror::sp#0 = (char)ferror::stream#0 -- vbuz1=_byte_pssz2 
    lda.z stream
    sta.z sp
    // cbm_k_setlfs(15, 8, 15)
    // [2262] cbm_k_setlfs::channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.channel
    // [2263] cbm_k_setlfs::device = 8 -- vbum1=vbuc1 
    lda #8
    sta cbm_k_setlfs.device
    // [2264] cbm_k_setlfs::command = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.command
    // [2265] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // ferror::@11
    // cbm_k_setnam("")
    // [2266] ferror::cbm_k_setnam1_filename = info_text5 -- pbum1=pbuc1 
    lda #<info_text5
    sta cbm_k_setnam1_filename
    lda #>info_text5
    sta cbm_k_setnam1_filename+1
    // ferror::cbm_k_setnam1
    // strlen(filename)
    // [2267] strlen::str#5 = ferror::cbm_k_setnam1_filename -- pbuz1=pbum2 
    lda cbm_k_setnam1_filename
    sta.z strlen.str
    lda cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [2268] call strlen
    // [1982] phi from ferror::cbm_k_setnam1 to strlen [phi:ferror::cbm_k_setnam1->strlen]
    // [1982] phi strlen::str#8 = strlen::str#5 [phi:ferror::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [2269] strlen::return#12 = strlen::len#2
    // ferror::@12
    // [2270] ferror::cbm_k_setnam1_$0 = strlen::return#12
    // char filename_len = (char)strlen(filename)
    // [2271] ferror::cbm_k_setnam1_filename_len = (char)ferror::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
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
    // [2274] ferror::cbm_k_chkin1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_chkin1_channel
    // ferror::cbm_k_chkin1
    // char status
    // [2275] ferror::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // ferror::cbm_k_chrin1
    // char ch
    // [2277] ferror::cbm_k_chrin1_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin1_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin1_ch
    // return ch;
    // [2279] ferror::cbm_k_chrin1_return#0 = ferror::cbm_k_chrin1_ch -- vbuz1=vbum2 
    sta.z cbm_k_chrin1_return
    // ferror::cbm_k_chrin1_@return
    // }
    // [2280] ferror::cbm_k_chrin1_return#1 = ferror::cbm_k_chrin1_return#0
    // ferror::@7
    // char ch = cbm_k_chrin()
    // [2281] ferror::ch#0 = ferror::cbm_k_chrin1_return#1
    // [2282] phi from ferror::@7 to ferror::cbm_k_readst1 [phi:ferror::@7->ferror::cbm_k_readst1]
    // [2282] phi __errno#175 = __errno#301 [phi:ferror::@7->ferror::cbm_k_readst1#0] -- register_copy 
    // [2282] phi ferror::errno_len#10 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z errno_len
    // [2282] phi ferror::ch#10 = ferror::ch#0 [phi:ferror::@7->ferror::cbm_k_readst1#2] -- register_copy 
    // [2282] phi ferror::errno_parsed#2 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#3] -- vbuz1=vbuc1 
    sta.z errno_parsed
    // ferror::cbm_k_readst1
  cbm_k_readst1:
    // char status
    // [2283] ferror::cbm_k_readst1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2285] ferror::cbm_k_readst1_return#0 = ferror::cbm_k_readst1_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst1_return
    // ferror::cbm_k_readst1_@return
    // }
    // [2286] ferror::cbm_k_readst1_return#1 = ferror::cbm_k_readst1_return#0
    // ferror::@8
    // cbm_k_readst()
    // [2287] ferror::$6 = ferror::cbm_k_readst1_return#1
    // st = cbm_k_readst()
    // [2288] ferror::st#1 = ferror::$6
    // while (!(st = cbm_k_readst()))
    // [2289] if(0==ferror::st#1) goto ferror::@1 -- 0_eq_vbuz1_then_la1 
    lda.z st
    beq __b1
    // ferror::@2
    // __status = st
    // [2290] ((char *)&__stdio_file+$118)[ferror::sp#0] = ferror::st#1 -- pbuc1_derefidx_vbuz1=vbuz2 
    ldy.z sp
    sta __stdio_file+$118,y
    // cbm_k_close(15)
    // [2291] ferror::cbm_k_close1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_close1_channel
    // ferror::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // ferror::@9
    // return __errno;
    // [2293] ferror::return#1 = __errno#175 -- vwsm1=vwsz2 
    lda.z __errno
    sta return
    lda.z __errno+1
    sta return+1
    // ferror::@return
    // }
    // [2294] return 
    rts
    // ferror::@1
  __b1:
    // if (!errno_parsed)
    // [2295] if(0!=ferror::errno_parsed#2) goto ferror::@3 -- 0_neq_vbuz1_then_la1 
    lda.z errno_parsed
    bne __b3
    // ferror::@4
    // if (ch == ',')
    // [2296] if(ferror::ch#10!=',') goto ferror::@3 -- vbuz1_neq_vbuc1_then_la1 
    lda #','
    cmp.z ch
    bne __b3
    // ferror::@5
    // errno_parsed++;
    // [2297] ferror::errno_parsed#1 = ++ ferror::errno_parsed#2 -- vbuz1=_inc_vbuz1 
    inc.z errno_parsed
    // strncpy(temp, __errno_error, errno_len+1)
    // [2298] strncpy::n#0 = ferror::errno_len#10 + 1 -- vwuz1=vbuz2_plus_1 
    lda.z errno_len
    clc
    adc #1
    sta.z strncpy.n
    lda #0
    adc #0
    sta.z strncpy.n+1
    // [2299] call strncpy
    // [2398] phi from ferror::@5 to strncpy [phi:ferror::@5->strncpy]
    jsr strncpy
    // [2300] phi from ferror::@5 to ferror::@13 [phi:ferror::@5->ferror::@13]
    // ferror::@13
    // atoi(temp)
    // [2301] call atoi
    // [2313] phi from ferror::@13 to atoi [phi:ferror::@13->atoi]
    // [2313] phi atoi::str#2 = ferror::temp [phi:ferror::@13->atoi#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z atoi.str
    lda #>temp
    sta.z atoi.str+1
    jsr atoi
    // atoi(temp)
    // [2302] atoi::return#4 = atoi::return#2
    // ferror::@14
    // __errno = atoi(temp)
    // [2303] __errno#2 = atoi::return#4 -- vwsz1=vwsz2 
    lda.z atoi.return
    sta.z __errno
    lda.z atoi.return+1
    sta.z __errno+1
    // [2304] phi from ferror::@1 ferror::@14 ferror::@4 to ferror::@3 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3]
    // [2304] phi __errno#101 = __errno#175 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#0] -- register_copy 
    // [2304] phi ferror::errno_parsed#11 = ferror::errno_parsed#2 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#1] -- register_copy 
    // ferror::@3
  __b3:
    // __errno_error[errno_len] = ch
    // [2305] __errno_error[ferror::errno_len#10] = ferror::ch#10 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z ch
    ldy.z errno_len
    sta __errno_error,y
    // errno_len++;
    // [2306] ferror::errno_len#1 = ++ ferror::errno_len#10 -- vbuz1=_inc_vbuz1 
    inc.z errno_len
    // ferror::cbm_k_chrin2
    // char ch
    // [2307] ferror::cbm_k_chrin2_ch = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chrin2_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin2_ch
    // return ch;
    // [2309] ferror::cbm_k_chrin2_return#0 = ferror::cbm_k_chrin2_ch -- vbuz1=vbuz2 
    sta.z cbm_k_chrin2_return
    // ferror::cbm_k_chrin2_@return
    // }
    // [2310] ferror::cbm_k_chrin2_return#1 = ferror::cbm_k_chrin2_return#0
    // ferror::@10
    // cbm_k_chrin()
    // [2311] ferror::$15 = ferror::cbm_k_chrin2_return#1
    // ch = cbm_k_chrin()
    // [2312] ferror::ch#1 = ferror::$15
    // [2282] phi from ferror::@10 to ferror::cbm_k_readst1 [phi:ferror::@10->ferror::cbm_k_readst1]
    // [2282] phi __errno#175 = __errno#101 [phi:ferror::@10->ferror::cbm_k_readst1#0] -- register_copy 
    // [2282] phi ferror::errno_len#10 = ferror::errno_len#1 [phi:ferror::@10->ferror::cbm_k_readst1#1] -- register_copy 
    // [2282] phi ferror::ch#10 = ferror::ch#1 [phi:ferror::@10->ferror::cbm_k_readst1#2] -- register_copy 
    // [2282] phi ferror::errno_parsed#2 = ferror::errno_parsed#11 [phi:ferror::@10->ferror::cbm_k_readst1#3] -- register_copy 
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
    .label negative = $69
    .label atoi__10 = $49
    .label atoi__11 = $c1
    // if (str[i] == '-')
    // [2314] if(*atoi::str#2!='-') goto atoi::@3 -- _deref_pbuz1_neq_vbuc1_then_la1 
    ldy #0
    lda (str),y
    cmp #'-'
    bne __b2
    // [2315] phi from atoi to atoi::@2 [phi:atoi->atoi::@2]
    // atoi::@2
    // [2316] phi from atoi::@2 to atoi::@3 [phi:atoi::@2->atoi::@3]
    // [2316] phi atoi::negative#2 = 1 [phi:atoi::@2->atoi::@3#0] -- vbuz1=vbuc1 
    lda #1
    sta.z negative
    // [2316] phi atoi::res#2 = 0 [phi:atoi::@2->atoi::@3#1] -- vwsz1=vwsc1 
    tya
    sta.z res
    sta.z res+1
    // [2316] phi atoi::i#4 = 1 [phi:atoi::@2->atoi::@3#2] -- vbuz1=vbuc1 
    lda #1
    sta.z i
    jmp __b3
  // Iterate through all digits and update the result
    // [2316] phi from atoi to atoi::@3 [phi:atoi->atoi::@3]
  __b2:
    // [2316] phi atoi::negative#2 = 0 [phi:atoi->atoi::@3#0] -- vbuz1=vbuc1 
    lda #0
    sta.z negative
    // [2316] phi atoi::res#2 = 0 [phi:atoi->atoi::@3#1] -- vwsz1=vwsc1 
    sta.z res
    sta.z res+1
    // [2316] phi atoi::i#4 = 0 [phi:atoi->atoi::@3#2] -- vbuz1=vbuc1 
    sta.z i
    // atoi::@3
  __b3:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [2317] if(atoi::str#2[atoi::i#4]<'0') goto atoi::@5 -- pbuz1_derefidx_vbuz2_lt_vbuc1_then_la1 
    ldy.z i
    lda (str),y
    cmp #'0'
    bcc __b5
    // atoi::@6
    // [2318] if(atoi::str#2[atoi::i#4]<='9') goto atoi::@4 -- pbuz1_derefidx_vbuz2_le_vbuc1_then_la1 
    lda (str),y
    cmp #'9'
    bcc __b4
    beq __b4
    // atoi::@5
  __b5:
    // if(negative)
    // [2319] if(0!=atoi::negative#2) goto atoi::@1 -- 0_neq_vbuz1_then_la1 
    // Return result with sign
    lda.z negative
    bne __b1
    // [2321] phi from atoi::@1 atoi::@5 to atoi::@return [phi:atoi::@1/atoi::@5->atoi::@return]
    // [2321] phi atoi::return#2 = atoi::return#0 [phi:atoi::@1/atoi::@5->atoi::@return#0] -- register_copy 
    rts
    // atoi::@1
  __b1:
    // return -res;
    // [2320] atoi::return#0 = - atoi::res#2 -- vwsz1=_neg_vwsz1 
    lda #0
    sec
    sbc.z return
    sta.z return
    lda #0
    sbc.z return+1
    sta.z return+1
    // atoi::@return
    // }
    // [2322] return 
    rts
    // atoi::@4
  __b4:
    // res * 10
    // [2323] atoi::$10 = atoi::res#2 << 2 -- vwsz1=vwsz2_rol_2 
    lda.z res
    asl
    sta.z atoi__10
    lda.z res+1
    rol
    sta.z atoi__10+1
    asl.z atoi__10
    rol.z atoi__10+1
    // [2324] atoi::$11 = atoi::$10 + atoi::res#2 -- vwsz1=vwsz2_plus_vwsz1 
    clc
    lda.z atoi__11
    adc.z atoi__10
    sta.z atoi__11
    lda.z atoi__11+1
    adc.z atoi__10+1
    sta.z atoi__11+1
    // [2325] atoi::$6 = atoi::$11 << 1 -- vwsz1=vwsz1_rol_1 
    asl.z atoi__6
    rol.z atoi__6+1
    // res * 10 + str[i]
    // [2326] atoi::$7 = atoi::$6 + atoi::str#2[atoi::i#4] -- vwsz1=vwsz1_plus_pbuz2_derefidx_vbuz3 
    ldy.z i
    lda.z atoi__7
    clc
    adc (str),y
    sta.z atoi__7
    bcc !+
    inc.z atoi__7+1
  !:
    // res = res * 10 + str[i] - '0'
    // [2327] atoi::res#1 = atoi::$7 - '0' -- vwsz1=vwsz1_minus_vbuc1 
    lda.z res
    sec
    sbc #'0'
    sta.z res
    bcs !+
    dec.z res+1
  !:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [2328] atoi::i#2 = ++ atoi::i#4 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2316] phi from atoi::@4 to atoi::@3 [phi:atoi::@4->atoi::@3]
    // [2316] phi atoi::negative#2 = atoi::negative#2 [phi:atoi::@4->atoi::@3#0] -- register_copy 
    // [2316] phi atoi::res#2 = atoi::res#1 [phi:atoi::@4->atoi::@3#1] -- register_copy 
    // [2316] phi atoi::i#4 = atoi::i#2 [phi:atoi::@4->atoi::@3#2] -- register_copy 
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
// __zp($77) unsigned int cx16_k_macptr(__zp($c7) volatile char bytes, __zp($c3) void * volatile buffer)
cx16_k_macptr: {
    .label bytes = $c7
    .label buffer = $c3
    .label bytes_read = $b0
    .label return = $77
    // unsigned int bytes_read
    // [2329] cx16_k_macptr::bytes_read = 0 -- vwuz1=vwuc1 
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
    // [2331] cx16_k_macptr::return#0 = cx16_k_macptr::bytes_read -- vwuz1=vwuz2 
    lda.z bytes_read
    sta.z return
    lda.z bytes_read+1
    sta.z return+1
    // cx16_k_macptr::@return
    // }
    // [2332] cx16_k_macptr::return#1 = cx16_k_macptr::return#0
    // [2333] return 
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
// __zp($25) char uctoa_append(__zp($70) char *buffer, __zp($25) char value, __zp($3a) char sub)
uctoa_append: {
    .label buffer = $70
    .label value = $25
    .label sub = $3a
    .label return = $25
    .label digit = $31
    // [2335] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [2335] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [2335] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [2336] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbuz1_ge_vbuz2_then_la1 
    lda.z value
    cmp.z sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [2337] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [2338] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [2339] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [2340] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbuz1=vbuz1_minus_vbuz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    // [2335] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [2335] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [2335] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
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
// __zp($33) char rom_byte_compare(__zp($54) char *ptr_rom, __zp($72) char value)
rom_byte_compare: {
    .label return = $33
    .label ptr_rom = $54
    .label value = $72
    // if (*ptr_rom != value)
    // [2341] if(*rom_byte_compare::ptr_rom#0==rom_byte_compare::value#0) goto rom_byte_compare::@1 -- _deref_pbuz1_eq_vbuz2_then_la1 
    lda.z value
    ldy #0
    cmp (ptr_rom),y
    beq __b2
    // [2342] phi from rom_byte_compare to rom_byte_compare::@2 [phi:rom_byte_compare->rom_byte_compare::@2]
    // rom_byte_compare::@2
    // [2343] phi from rom_byte_compare::@2 to rom_byte_compare::@1 [phi:rom_byte_compare::@2->rom_byte_compare::@1]
    // [2343] phi rom_byte_compare::return#0 = 0 [phi:rom_byte_compare::@2->rom_byte_compare::@1#0] -- vbuz1=vbuc1 
    tya
    sta.z return
    rts
    // [2343] phi from rom_byte_compare to rom_byte_compare::@1 [phi:rom_byte_compare->rom_byte_compare::@1]
  __b2:
    // [2343] phi rom_byte_compare::return#0 = 1 [phi:rom_byte_compare->rom_byte_compare::@1#0] -- vbuz1=vbuc1 
    lda #1
    sta.z return
    // rom_byte_compare::@1
    // rom_byte_compare::@return
    // }
    // [2344] return 
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
// __zp($26) unsigned long ultoa_append(__zp($6e) char *buffer, __zp($26) unsigned long value, __zp($3b) unsigned long sub)
ultoa_append: {
    .label buffer = $6e
    .label value = $26
    .label sub = $3b
    .label return = $26
    .label digit = $32
    // [2346] phi from ultoa_append to ultoa_append::@1 [phi:ultoa_append->ultoa_append::@1]
    // [2346] phi ultoa_append::digit#2 = 0 [phi:ultoa_append->ultoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [2346] phi ultoa_append::value#2 = ultoa_append::value#0 [phi:ultoa_append->ultoa_append::@1#1] -- register_copy 
    // ultoa_append::@1
  __b1:
    // while (value >= sub)
    // [2347] if(ultoa_append::value#2>=ultoa_append::sub#0) goto ultoa_append::@2 -- vduz1_ge_vduz2_then_la1 
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
    // [2348] *ultoa_append::buffer#0 = DIGITS[ultoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // ultoa_append::@return
    // }
    // [2349] return 
    rts
    // ultoa_append::@2
  __b2:
    // digit++;
    // [2350] ultoa_append::digit#1 = ++ ultoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [2351] ultoa_append::value#1 = ultoa_append::value#2 - ultoa_append::sub#0 -- vduz1=vduz1_minus_vduz2 
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
    // [2346] phi from ultoa_append::@2 to ultoa_append::@1 [phi:ultoa_append::@2->ultoa_append::@1]
    // [2346] phi ultoa_append::digit#2 = ultoa_append::digit#1 [phi:ultoa_append::@2->ultoa_append::@1#0] -- register_copy 
    // [2346] phi ultoa_append::value#2 = ultoa_append::value#1 [phi:ultoa_append::@2->ultoa_append::@1#1] -- register_copy 
    jmp __b1
}
  // cputs
// Output a NUL-terminated string at the current cursor position
// void cputs(__zp($38) const char *s)
cputs: {
    .label c = $31
    .label s = $38
    // [2353] phi from cputs to cputs::@1 [phi:cputs->cputs::@1]
    // [2353] phi cputs::s#2 = rom_flash::s [phi:cputs->cputs::@1#0] -- pbuz1=pbuc1 
    lda #<rom_flash.s
    sta.z s
    lda #>rom_flash.s
    sta.z s+1
    // cputs::@1
  __b1:
    // while(c=*s++)
    // [2354] cputs::c#1 = *cputs::s#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta.z c
    // [2355] cputs::s#0 = ++ cputs::s#2 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [2356] if(0!=cputs::c#1) goto cputs::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // cputs::@return
    // }
    // [2357] return 
    rts
    // cputs::@2
  __b2:
    // cputc(c)
    // [2358] stackpush(char) = cputs::c#1 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [2359] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [2353] phi from cputs::@2 to cputs::@1 [phi:cputs::@2->cputs::@1]
    // [2353] phi cputs::s#2 = cputs::s#0 [phi:cputs::@2->cputs::@1#0] -- register_copy 
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
    // [2362] rom_wait::test1#1 = *rom_wait::ptr_rom#3 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (ptr_rom),y
    sta.z test1
    // test2 = *((brom_ptr_t)ptr_rom)
    // [2363] rom_wait::test2#1 = *rom_wait::ptr_rom#3 -- vbuz1=_deref_pbuz2 
    lda (ptr_rom),y
    sta.z test2
    // test1 & 0x40
    // [2364] rom_wait::$0 = rom_wait::test1#1 & $40 -- vbuz1=vbuz1_band_vbuc1 
    lda #$40
    and.z rom_wait__0
    sta.z rom_wait__0
    // test2 & 0x40
    // [2365] rom_wait::$1 = rom_wait::test2#1 & $40 -- vbuz1=vbuz1_band_vbuc1 
    lda #$40
    and.z rom_wait__1
    sta.z rom_wait__1
    // while ((test1 & 0x40) != (test2 & 0x40))
    // [2366] if(rom_wait::$0!=rom_wait::$1) goto rom_wait::@1 -- vbuz1_neq_vbuz2_then_la1 
    lda.z rom_wait__0
    cmp.z rom_wait__1
    bne __b1
    // rom_wait::@return
    // }
    // [2367] return 
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
// void rom_byte_program(__zp($56) unsigned long address, __zp($5c) char value)
rom_byte_program: {
    .label rom_ptr1_rom_byte_program__0 = $5e
    .label rom_ptr1_rom_byte_program__2 = $5e
    .label rom_ptr1_return = $5e
    .label address = $56
    .label value = $5c
    // rom_byte_program::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2369] rom_byte_program::rom_ptr1_$2 = (unsigned int)rom_byte_program::address#0 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_byte_program__2
    lda.z address+1
    sta.z rom_ptr1_rom_byte_program__2+1
    // [2370] rom_byte_program::rom_ptr1_$0 = rom_byte_program::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_byte_program__0
    and #<$3fff
    sta.z rom_ptr1_rom_byte_program__0
    lda.z rom_ptr1_rom_byte_program__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_byte_program__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2371] rom_byte_program::rom_ptr1_return#0 = rom_byte_program::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_byte_program::@1
    // rom_write_byte(address, value)
    // [2372] rom_write_byte::address#3 = rom_byte_program::address#0
    // [2373] rom_write_byte::value#3 = rom_byte_program::value#0
    // [2374] call rom_write_byte
    // [2247] phi from rom_byte_program::@1 to rom_write_byte [phi:rom_byte_program::@1->rom_write_byte]
    // [2247] phi rom_write_byte::value#10 = rom_write_byte::value#3 [phi:rom_byte_program::@1->rom_write_byte#0] -- register_copy 
    // [2247] phi rom_write_byte::address#4 = rom_write_byte::address#3 [phi:rom_byte_program::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_byte_program::@2
    // rom_wait(ptr_rom)
    // [2375] rom_wait::ptr_rom#1 = (char *)rom_byte_program::rom_ptr1_return#0 -- pbuz1=pbuz2 
    lda.z rom_ptr1_return
    sta.z rom_wait.ptr_rom
    lda.z rom_ptr1_return+1
    sta.z rom_wait.ptr_rom+1
    // [2376] call rom_wait
    // [2361] phi from rom_byte_program::@2 to rom_wait [phi:rom_byte_program::@2->rom_wait]
    // [2361] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#1 [phi:rom_byte_program::@2->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_byte_program::@return
    // }
    // [2377] return 
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
// void memcpy8_vram_vram(__zp($2d) char dbank_vram, __zp($42) unsigned int doffset_vram, __zp($2c) char sbank_vram, __zp($36) unsigned int soffset_vram, __zp($23) char num8)
memcpy8_vram_vram: {
    .label memcpy8_vram_vram__0 = $2e
    .label memcpy8_vram_vram__1 = $2f
    .label memcpy8_vram_vram__2 = $2c
    .label memcpy8_vram_vram__3 = $34
    .label memcpy8_vram_vram__4 = $35
    .label memcpy8_vram_vram__5 = $2d
    .label num8 = $23
    .label dbank_vram = $2d
    .label doffset_vram = $42
    .label sbank_vram = $2c
    .label soffset_vram = $36
    .label num8_1 = $22
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2378] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [2379] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte0_vwuz2 
    lda.z soffset_vram
    sta.z memcpy8_vram_vram__0
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [2380] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [2381] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte1_vwuz2 
    lda.z soffset_vram+1
    sta.z memcpy8_vram_vram__1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [2382] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [2383] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuz1=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z memcpy8_vram_vram__2
    sta.z memcpy8_vram_vram__2
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [2384] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [2385] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [2386] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte0_vwuz2 
    lda.z doffset_vram
    sta.z memcpy8_vram_vram__3
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [2387] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [2388] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte1_vwuz2 
    lda.z doffset_vram+1
    sta.z memcpy8_vram_vram__4
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [2389] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [2390] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuz1=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z memcpy8_vram_vram__5
    sta.z memcpy8_vram_vram__5
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [2391] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // [2392] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [2392] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [2393] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbuz1=_dec_vbuz2 
    ldy.z num8_1
    dey
    sty.z num8
    // [2394] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbuz1_then_la1 
    lda.z num8_1
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [2395] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [2396] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [2397] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbuz1=vbuz2 
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
// char * strncpy(__zp($cf) char *dst, __zp($ca) const char *src, __zp($4b) unsigned int n)
strncpy: {
    .label c = $24
    .label dst = $cf
    .label i = $cd
    .label src = $ca
    .label n = $4b
    // [2399] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [2399] phi strncpy::dst#2 = ferror::temp [phi:strncpy->strncpy::@1#0] -- pbuz1=pbuc1 
    lda #<ferror.temp
    sta.z dst
    lda #>ferror.temp
    sta.z dst+1
    // [2399] phi strncpy::src#2 = __errno_error [phi:strncpy->strncpy::@1#1] -- pbuz1=pbuc1 
    lda #<__errno_error
    sta.z src
    lda #>__errno_error
    sta.z src+1
    // [2399] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwuz1=vwuc1 
    lda #<0
    sta.z i
    sta.z i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [2400] if(strncpy::i#2<strncpy::n#0) goto strncpy::@2 -- vwuz1_lt_vwuz2_then_la1 
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
    // [2401] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [2402] strncpy::c#0 = *strncpy::src#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta.z c
    // if(c)
    // [2403] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbuz1_then_la1 
    beq __b3
    // strncpy::@4
    // src++;
    // [2404] strncpy::src#0 = ++ strncpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [2405] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [2405] phi strncpy::src#6 = strncpy::src#2 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [2406] *strncpy::dst#2 = strncpy::c#0 -- _deref_pbuz1=vbuz2 
    lda.z c
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [2407] strncpy::dst#0 = ++ strncpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [2408] strncpy::i#1 = ++ strncpy::i#2 -- vwuz1=_inc_vwuz1 
    inc.z i
    bne !+
    inc.z i+1
  !:
    // [2399] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [2399] phi strncpy::dst#2 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [2399] phi strncpy::src#2 = strncpy::src#6 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [2399] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
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
