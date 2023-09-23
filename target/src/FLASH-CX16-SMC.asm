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
  ///< Read a character from the current channel for input.
  .const CBM_GETIN = $ffe4
  ///< Close a logical file.
  .const CBM_CLRCHN = $ffcc
  ///< Load a logical file.
  .const CBM_PLOT = $fff0
  ///< CX16 Set/Get screen mode.
  .const CX16_SCREEN_SET_CHARSET = $ff62
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
  .const STATUS_FLASH = 6
  .const STATUS_ISSUE = 9
  .const STATUS_ERROR = $a
  .const OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS = 1
  .const smc_file_size = 0
  .const STACK_BASE = $103
  .const SIZEOF_STRUCT___1 = $8f
  .const SIZEOF_STRUCT_PRINTF_BUFFER_NUMBER = $c
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
  .label __snprintf_buffer = $b5
  //     unsigned char l = 0;
  //     while (l < INFO_H) {
  //         info_clear(l);
  //         l++;
  //     }
  // }
  .label status_smc = $c3
  .label status_vera = $c4
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
// void snputc(__zp($7e) char c)
snputc: {
    .const OFFSET_STACK_C = 0
    .label c = $7e
    // [9] snputc::c#0 = stackidx(char,snputc::OFFSET_STACK_C) -- vbuz1=_stackidxbyte_vbuc1 
    tsx
    lda STACK_BASE+OFFSET_STACK_C,x
    sta.z c
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
    // [15] phi snputc::c#2 = 0 [phi:snputc::@1->snputc::@2#0] -- vbuz1=vbuc1 
    lda #0
    sta.z c
    // [14] phi from snputc::@1 to snputc::@3 [phi:snputc::@1->snputc::@3]
    // snputc::@3
    // [15] phi from snputc::@3 to snputc::@2 [phi:snputc::@3->snputc::@2]
    // [15] phi snputc::c#2 = snputc::c#0 [phi:snputc::@3->snputc::@2#0] -- register_copy 
    // snputc::@2
  __b2:
    // *(__snprintf_buffer++) = c
    // [16] *__snprintf_buffer = snputc::c#2 -- _deref_pbuz1=vbuz2 
    // Append char
    lda.z c
    ldy #0
    sta (__snprintf_buffer),y
    // *(__snprintf_buffer++) = c;
    // [17] __snprintf_buffer = ++ __snprintf_buffer -- pbuz1=_inc_pbuz1 
    inc.z __snprintf_buffer
    bne !+
    inc.z __snprintf_buffer+1
  !:
    rts
}
  // conio_x16_init
/// Set initial screen values.
conio_x16_init: {
    .label conio_x16_init__4 = $75
    .label conio_x16_init__5 = $61
    .label conio_x16_init__6 = $75
    .label conio_x16_init__7 = $bb
    // screenlayer1()
    // [19] call screenlayer1
    jsr screenlayer1
    // [20] phi from conio_x16_init to conio_x16_init::@1 [phi:conio_x16_init->conio_x16_init::@1]
    // conio_x16_init::@1
    // textcolor(CONIO_TEXTCOLOR_DEFAULT)
    // [21] call textcolor
    // [268] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [268] phi textcolor::color#16 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [22] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [23] call bgcolor
    // [273] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [273] phi bgcolor::color#14 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
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
    // [29] conio_x16_init::$4 = cbm_k_plot_get::return#2
    // BYTE1(cbm_k_plot_get())
    // [30] conio_x16_init::$5 = byte1  conio_x16_init::$4 -- vbuz1=_byte1_vwuz2 
    lda.z conio_x16_init__4+1
    sta.z conio_x16_init__5
    // __conio.cursor_x = BYTE1(cbm_k_plot_get())
    // [31] *((char *)&__conio) = conio_x16_init::$5 -- _deref_pbuc1=vbuz1 
    sta __conio
    // cbm_k_plot_get()
    // [32] call cbm_k_plot_get
    jsr cbm_k_plot_get
    // [33] cbm_k_plot_get::return#3 = cbm_k_plot_get::return#0
    // conio_x16_init::@6
    // [34] conio_x16_init::$6 = cbm_k_plot_get::return#3
    // BYTE0(cbm_k_plot_get())
    // [35] conio_x16_init::$7 = byte0  conio_x16_init::$6 -- vbuz1=_byte0_vwuz2 
    lda.z conio_x16_init__6
    sta.z conio_x16_init__7
    // __conio.cursor_y = BYTE0(cbm_k_plot_get())
    // [36] *((char *)&__conio+1) = conio_x16_init::$7 -- _deref_pbuc1=vbuz1 
    sta __conio+1
    // gotoxy(__conio.cursor_x, __conio.cursor_y)
    // [37] gotoxy::x#2 = *((char *)&__conio) -- vbuz1=_deref_pbuc1 
    lda __conio
    sta.z gotoxy.x
    // [38] gotoxy::y#2 = *((char *)&__conio+1) -- vbuz1=_deref_pbuc1 
    lda __conio+1
    sta.z gotoxy.y
    // [39] call gotoxy
    // [286] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [286] phi gotoxy::y#19 = gotoxy::y#2 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [286] phi gotoxy::x#19 = gotoxy::x#2 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
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
}
  // cputc
// Output one character at the current cursor position
// Moves the cursor forward. Scrolls the entire screen if needed
// void cputc(__zp($2c) char c)
cputc: {
    .const OFFSET_STACK_C = 0
    .label cputc__1 = $22
    .label cputc__2 = $45
    .label cputc__3 = $46
    .label c = $2c
    // [43] cputc::c#0 = stackidx(char,cputc::OFFSET_STACK_C) -- vbuz1=_stackidxbyte_vbuc1 
    tsx
    lda STACK_BASE+OFFSET_STACK_C,x
    sta.z c
    // if(c=='\n')
    // [44] if(cputc::c#0==' ') goto cputc::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #'\n'
    cmp.z c
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
    // [52] *VERA_DATA0 = cputc::c#0 -- _deref_pbuc1=vbuz1 
    lda.z c
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
}
  // main
main: {
    // Set the info for the VERA to Detected.
    .const intro_briefing_count = $10
    .const intro_colors_count = $10
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    .const bank_set_brom2_bank = 0
    .const bank_set_brom3_bank = 4
    .label main__54 = $4d
    .label main__83 = $5a
    .label main__84 = $3e
    .label cx16_k_screen_set_charset1_charset = $be
    .label cx16_k_screen_set_charset1_offset = $bc
    .label check_smc2_main__0 = $38
    .label check_cx16_rom2_check_rom1_main__0 = $77
    .label check_card_roms1_check_rom1_main__0 = $5c
    .label check_smc3_main__0 = $68
    .label check_smc4_main__0 = $6d
    .label check_vera1_main__0 = $7b
    .label check_roms_all1_check_rom1_main__0 = $5d
    .label check_smc5_main__0 = $78
    .label check_vera2_main__0 = $6e
    .label check_roms1_check_rom1_main__0 = $55
    .label check_smc6_main__0 = $6f
    .label check_vera3_main__0 = $64
    .label check_roms2_check_rom1_main__0 = $6b
    .label intro_line = $af
    .label intro_line1 = $b0
    .label intro_status = $ad
    .label check_smc2_return = $38
    .label check_cx16_rom2_check_rom1_return = $77
    .label check_card_roms1_check_rom1_return = $5c
    .label check_card_roms1_rom_chip = $b1
    .label check_card_roms1_return = $bf
    .label check_smc3_return = $68
    .label ch = $6c
    .label rom_chip = $ae
    .label check_smc4_return = $6d
    .label check_vera1_return = $7b
    .label check_roms_all1_check_rom1_return = $5d
    .label check_roms_all1_rom_chip = $b2
    .label check_roms_all1_return = $c0
    .label check_smc5_return = $78
    .label check_vera2_return = $6e
    .label check_roms1_check_rom1_return = $55
    .label check_roms1_rom_chip = $b3
    .label check_roms1_return = $c1
    .label check_smc6_return = $6f
    .label check_vera3_return = $64
    .label check_roms2_check_rom1_return = $6b
    .label check_roms2_rom_chip = $b4
    .label check_roms2_return = $c2
    .label flash_reset = $b7
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
    // main::@20
    // cx16_k_screen_set_charset(3, (char *)0)
    // [73] main::cx16_k_screen_set_charset1_charset = 3 -- vbuz1=vbuc1 
    lda #3
    sta.z cx16_k_screen_set_charset1_charset
    // [74] main::cx16_k_screen_set_charset1_offset = (char *) 0 -- pbuz1=pbuc1 
    lda #<0
    sta.z cx16_k_screen_set_charset1_offset
    sta.z cx16_k_screen_set_charset1_offset+1
    // main::cx16_k_screen_set_charset1
    // asm
    // asm { ldacharset ldx<offset ldy>offset jsrCX16_SCREEN_SET_CHARSET  }
    lda cx16_k_screen_set_charset1_charset
    ldx.z <cx16_k_screen_set_charset1_offset
    ldy.z >cx16_k_screen_set_charset1_offset
    jsr CX16_SCREEN_SET_CHARSET
    // [76] phi from main::cx16_k_screen_set_charset1 to main::@21 [phi:main::cx16_k_screen_set_charset1->main::@21]
    // main::@21
    // frame_init()
    // [77] call frame_init
    // [307] phi from main::@21 to frame_init [phi:main::@21->frame_init]
    jsr frame_init
    // [78] phi from main::@21 to main::@32 [phi:main::@21->main::@32]
    // main::@32
    // frame_draw()
    // [79] call frame_draw
    // [327] phi from main::@32 to frame_draw [phi:main::@32->frame_draw]
    jsr frame_draw
    // [80] phi from main::@32 to main::@33 [phi:main::@32->main::@33]
    // main::@33
    // print_title("Commander X16 Flash Utility!")
    // [81] call print_title
    // [368] phi from main::@33 to print_title [phi:main::@33->print_title]
    jsr print_title
    // [82] phi from main::@33 to main::print_info_title1 [phi:main::@33->main::print_info_title1]
    // main::print_info_title1
    // cputsxy(INFO_X-2, INFO_Y-2, "# Chip Status    Type   File  / Total Information")
    // [83] call cputsxy
    // [373] phi from main::print_info_title1 to cputsxy [phi:main::print_info_title1->cputsxy]
    // [373] phi cputsxy::s#3 = main::s [phi:main::print_info_title1->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [373] phi cputsxy::y#3 = $11-2 [phi:main::print_info_title1->cputsxy#1] -- vbuz1=vbuc1 
    lda #$11-2
    sta.z cputsxy.y
    // [373] phi cputsxy::x#3 = 4-2 [phi:main::print_info_title1->cputsxy#2] -- vbuz1=vbuc1 
    lda #4-2
    sta.z cputsxy.x
    jsr cputsxy
    // [84] phi from main::print_info_title1 to main::@34 [phi:main::print_info_title1->main::@34]
    // main::@34
    // cputsxy(INFO_X-2, INFO_Y-1, "- ---- --------- ------ ----- / ----- --------------------")
    // [85] call cputsxy
    // [373] phi from main::@34 to cputsxy [phi:main::@34->cputsxy]
    // [373] phi cputsxy::s#3 = main::s1 [phi:main::@34->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s1
    sta.z cputsxy.s
    lda #>s1
    sta.z cputsxy.s+1
    // [373] phi cputsxy::y#3 = $11-1 [phi:main::@34->cputsxy#1] -- vbuz1=vbuc1 
    lda #$11-1
    sta.z cputsxy.y
    // [373] phi cputsxy::x#3 = 4-2 [phi:main::@34->cputsxy#2] -- vbuz1=vbuc1 
    lda #4-2
    sta.z cputsxy.x
    jsr cputsxy
    // [86] phi from main::@34 to main::@22 [phi:main::@34->main::@22]
    // main::@22
    // progress_clear()
    // [87] call progress_clear
    // [380] phi from main::@22 to progress_clear [phi:main::@22->progress_clear]
    jsr progress_clear
    // [88] phi from main::@22 to main::@35 [phi:main::@22->main::@35]
    // main::@35
    // info_progress("Detecting SMC, VERA and ROM chipsets ...")
    // [89] call info_progress
  // info_print(0, "The SMC chip on the X16 board controls the power on/off, keyboard and mouse pheripherals.");
  // info_print(1, "It is essential that the SMC chip gets updated together with the latest ROM on the X16 board.");
  // info_print(2, "On the X16 board, near the SMC chip are two jumpers");
    // [395] phi from main::@35 to info_progress [phi:main::@35->info_progress]
    // [395] phi info_progress::info_text#10 = main::info_text [phi:main::@35->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_progress.info_text
    lda #>info_text
    sta.z info_progress.info_text+1
    jsr info_progress
    // [90] phi from main::@35 to main::@36 [phi:main::@35->main::@36]
    // main::@36
    // chip_vera()
    // [91] call chip_vera
  // Detecting VERA FPGA.
    // [409] phi from main::@36 to chip_vera [phi:main::@36->chip_vera]
    jsr chip_vera
    // [92] phi from main::@36 to main::@37 [phi:main::@36->main::@37]
    // main::@37
    // info_vera(STATUS_DETECTED, "VERA installed, OK")
    // [93] call info_vera
    // [414] phi from main::@37 to info_vera [phi:main::@37->info_vera]
    // [414] phi info_vera::info_text#10 = main::info_text1 [phi:main::@37->info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z info_vera.info_text
    lda #>info_text1
    sta.z info_vera.info_text+1
    // [414] phi info_vera::info_status#2 = STATUS_DETECTED [phi:main::@37->info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_DETECTED
    sta.z info_vera.info_status
    jsr info_vera
    // [94] phi from main::@37 to main::@4 [phi:main::@37->main::@4]
    // [94] phi main::intro_line#2 = 0 [phi:main::@37->main::@4#0] -- vbuz1=vbuc1 
    lda #0
    sta.z intro_line
    // main::@4
  __b4:
    // for(unsigned char intro_line=0; intro_line<intro_briefing_count; intro_line++)
    // [95] if(main::intro_line#2<main::intro_briefing_count) goto main::@5 -- vbuz1_lt_vbuc1_then_la1 
    lda.z intro_line
    cmp #intro_briefing_count
    bcs !__b5+
    jmp __b5
  !__b5:
    // [96] phi from main::@4 to main::@6 [phi:main::@4->main::@6]
    // main::@6
    // wait_key("Please read carefully the below, and press [SPACE] ...", " ")
    // [97] call wait_key
    // [440] phi from main::@6 to wait_key [phi:main::@6->wait_key]
    // [440] phi wait_key::filter#14 = s1 [phi:main::@6->wait_key#0] -- pbuz1=pbuc1 
    lda #<@s1
    sta.z wait_key.filter
    lda #>@s1
    sta.z wait_key.filter+1
    // [440] phi wait_key::info_text#4 = main::info_text2 [phi:main::@6->wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z wait_key.info_text
    lda #>info_text2
    sta.z wait_key.info_text+1
    jsr wait_key
    // [98] phi from main::@6 to main::@39 [phi:main::@6->main::@39]
    // main::@39
    // progress_clear()
    // [99] call progress_clear
    // [380] phi from main::@39 to progress_clear [phi:main::@39->progress_clear]
    jsr progress_clear
    // [100] phi from main::@39 to main::@7 [phi:main::@39->main::@7]
    // [100] phi main::intro_line1#2 = 0 [phi:main::@39->main::@7#0] -- vbuz1=vbuc1 
    lda #0
    sta.z intro_line1
    // main::@7
  __b7:
    // for(unsigned char intro_line=0; intro_line<intro_colors_count; intro_line++)
    // [101] if(main::intro_line1#2<main::intro_colors_count) goto main::@8 -- vbuz1_lt_vbuc1_then_la1 
    lda.z intro_line1
    cmp #intro_colors_count
    bcs !__b8+
    jmp __b8
  !__b8:
    // [102] phi from main::@7 to main::@9 [phi:main::@7->main::@9]
    // [102] phi main::intro_status#2 = 0 [phi:main::@7->main::@9#0] -- vbuz1=vbuc1 
    lda #0
    sta.z intro_status
    // main::@9
  __b9:
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [103] if(main::intro_status#2<$b) goto main::@10 -- vbuz1_lt_vbuc1_then_la1 
    lda.z intro_status
    cmp #$b
    bcs !__b10+
    jmp __b10
  !__b10:
    // [104] phi from main::@9 to main::@11 [phi:main::@9->main::@11]
    // main::@11
    // wait_key("If understood, press [SPACE] to start the update ...", " ")
    // [105] call wait_key
    // [440] phi from main::@11 to wait_key [phi:main::@11->wait_key]
    // [440] phi wait_key::filter#14 = s1 [phi:main::@11->wait_key#0] -- pbuz1=pbuc1 
    lda #<@s1
    sta.z wait_key.filter
    lda #>@s1
    sta.z wait_key.filter+1
    // [440] phi wait_key::info_text#4 = main::info_text3 [phi:main::@11->wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text3
    sta.z wait_key.info_text
    lda #>info_text3
    sta.z wait_key.info_text+1
    jsr wait_key
    // [106] phi from main::@11 to main::@42 [phi:main::@11->main::@42]
    // main::@42
    // progress_clear()
    // [107] call progress_clear
    // [380] phi from main::@42 to progress_clear [phi:main::@42->progress_clear]
    jsr progress_clear
    // main::bank_set_brom2
    // BROM = bank
    // [108] BROM = main::bank_set_brom2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom2_bank
    sta.z BROM
    // main::CLI1
    // asm
    // asm { cli  }
    cli
    // [110] phi from main::CLI1 to main::check_smc1 [phi:main::CLI1->main::check_smc1]
    // main::check_smc1
    // [111] phi from main::check_smc1 to main::check_cx16_rom1 [phi:main::check_smc1->main::check_cx16_rom1]
    // main::check_cx16_rom1
    // [112] phi from main::check_cx16_rom1 to main::check_cx16_rom1_check_rom1 [phi:main::check_cx16_rom1->main::check_cx16_rom1_check_rom1]
    // main::check_cx16_rom1_check_rom1
    // [113] phi from main::check_cx16_rom1_check_rom1 to main::@12 [phi:main::check_cx16_rom1_check_rom1->main::@12]
    // main::@12
    // info_smc(STATUS_ISSUE, NULL)
    // [114] call info_smc
    // [464] phi from main::@12 to info_smc [phi:main::@12->info_smc]
    // [464] phi info_smc::info_text#10 = 0 [phi:main::@12->info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z info_smc.info_text
    sta.z info_smc.info_text+1
    // [464] phi info_smc::info_status#2 = STATUS_ISSUE [phi:main::@12->info_smc#1] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z info_smc.info_status
    jsr info_smc
    // [115] phi from main::@12 to main::@43 [phi:main::@12->main::@43]
    // main::@43
    // info_cx16_rom(STATUS_ISSUE, NULL)
    // [116] call info_cx16_rom
    // [494] phi from main::@43 to info_cx16_rom [phi:main::@43->info_cx16_rom]
    jsr info_cx16_rom
    // [117] phi from main::@43 to main::@44 [phi:main::@43->main::@44]
    // main::@44
    // info_progress("There is an issue with either the SMC or the CX16 main ROM!")
    // [118] call info_progress
    // [395] phi from main::@44 to info_progress [phi:main::@44->info_progress]
    // [395] phi info_progress::info_text#10 = main::info_text4 [phi:main::@44->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z info_progress.info_text
    lda #>info_text4
    sta.z info_progress.info_text+1
    jsr info_progress
    // [119] phi from main::@44 to main::@45 [phi:main::@44->main::@45]
    // main::@45
    // wait_key("Press [SPACE] to continue [ ]", " ")
    // [120] call wait_key
    // [440] phi from main::@45 to wait_key [phi:main::@45->wait_key]
    // [440] phi wait_key::filter#14 = s1 [phi:main::@45->wait_key#0] -- pbuz1=pbuc1 
    lda #<@s1
    sta.z wait_key.filter
    lda #>@s1
    sta.z wait_key.filter+1
    // [440] phi wait_key::info_text#4 = main::info_text5 [phi:main::@45->wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z wait_key.info_text
    lda #>info_text5
    sta.z wait_key.info_text+1
    jsr wait_key
    // main::check_smc2
    // status_smc == status
    // [121] main::check_smc2_$0 = status_smc#0 == STATUS_FLASH -- vboz1=vbuz2_eq_vbuc1 
    lda.z status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_smc2_main__0
    // return (unsigned char)(status_smc == status);
    // [122] main::check_smc2_return#0 = (char)main::check_smc2_$0
    // [123] phi from main::check_smc2 to main::check_cx16_rom2 [phi:main::check_smc2->main::check_cx16_rom2]
    // main::check_cx16_rom2
    // main::check_cx16_rom2_check_rom1
    // status_rom[rom_chip] == status
    // [124] main::check_cx16_rom2_check_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_cx16_rom2_check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [125] main::check_cx16_rom2_check_rom1_return#0 = (char)main::check_cx16_rom2_check_rom1_$0
    // [126] phi from main::check_cx16_rom2_check_rom1 to main::check_card_roms1 [phi:main::check_cx16_rom2_check_rom1->main::check_card_roms1]
    // main::check_card_roms1
    // [127] phi from main::check_card_roms1 to main::check_card_roms1_@1 [phi:main::check_card_roms1->main::check_card_roms1_@1]
    // [127] phi main::check_card_roms1_rom_chip#2 = 1 [phi:main::check_card_roms1->main::check_card_roms1_@1#0] -- vbuz1=vbuc1 
    lda #1
    sta.z check_card_roms1_rom_chip
    // main::check_card_roms1_@1
  check_card_roms1___b1:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [128] if(main::check_card_roms1_rom_chip#2<8) goto main::check_card_roms1_check_rom1 -- vbuz1_lt_vbuc1_then_la1 
    lda.z check_card_roms1_rom_chip
    cmp #8
    bcs !check_card_roms1_check_rom1+
    jmp check_card_roms1_check_rom1
  !check_card_roms1_check_rom1:
    // [129] phi from main::check_card_roms1_@1 to main::check_card_roms1_@return [phi:main::check_card_roms1_@1->main::check_card_roms1_@return]
    // [129] phi main::check_card_roms1_return#2 = STATUS_NONE [phi:main::check_card_roms1_@1->main::check_card_roms1_@return#0] -- vbuz1=vbuc1 
    lda #STATUS_NONE
    sta.z check_card_roms1_return
    // main::check_card_roms1_@return
    // main::@23
  __b23:
    // if(check_smc(STATUS_FLASH) && check_cx16_rom(STATUS_FLASH) || check_card_roms(STATUS_FLASH))
    // [130] if(0==main::check_smc2_return#0) goto main::@58 -- 0_eq_vbuz1_then_la1 
    lda.z check_smc2_return
    beq __b58
    // main::@59
    // [131] if(0!=main::check_cx16_rom2_check_rom1_return#0) goto main::@1 -- 0_neq_vbuz1_then_la1 
    lda.z check_cx16_rom2_check_rom1_return
    beq !__b1+
    jmp __b1
  !__b1:
    // main::@58
  __b58:
    // [132] if(0!=main::check_card_roms1_return#2) goto main::@1 -- 0_neq_vbuz1_then_la1 
    lda.z check_card_roms1_return
    beq !__b1+
    jmp __b1
  !__b1:
    // main::SEI1
  SEI1:
    // asm
    // asm { sei  }
    sei
    // main::check_smc3
    // status_smc == status
    // [134] main::check_smc3_$0 = status_smc#0 == STATUS_FLASH -- vboz1=vbuz2_eq_vbuc1 
    lda.z status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_smc3_main__0
    // return (unsigned char)(status_smc == status);
    // [135] main::check_smc3_return#0 = (char)main::check_smc3_$0
    // main::@24
    // if (check_smc(STATUS_FLASH))
    // [136] if(0==main::check_smc3_return#0) goto main::bank_set_brom3 -- 0_eq_vbuz1_then_la1 
    lda.z check_smc3_return
    // [137] phi from main::@24 to main::@3 [phi:main::@24->main::@3]
    // main::@3
    // main::bank_set_brom3
    // BROM = bank
    // [138] BROM = main::bank_set_brom3_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom3_bank
    sta.z BROM
    // main::CLI2
    // asm
    // asm { cli  }
    cli
    // [140] phi from main::CLI2 to main::@25 [phi:main::CLI2->main::@25]
    // main::@25
    // info_progress("Update finished ...")
    // [141] call info_progress
    // [395] phi from main::@25 to info_progress [phi:main::@25->info_progress]
    // [395] phi info_progress::info_text#10 = main::info_text12 [phi:main::@25->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text12
    sta.z info_progress.info_text
    lda #>info_text12
    sta.z info_progress.info_text+1
    jsr info_progress
    // main::check_smc4
    // status_smc == status
    // [142] main::check_smc4_$0 = status_smc#0 == STATUS_SKIP -- vboz1=vbuz2_eq_vbuc1 
    lda.z status_smc
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_smc4_main__0
    // return (unsigned char)(status_smc == status);
    // [143] main::check_smc4_return#0 = (char)main::check_smc4_$0
    // main::check_vera1
    // status_vera == status
    // [144] main::check_vera1_$0 = status_vera#0 == STATUS_SKIP -- vboz1=vbuz2_eq_vbuc1 
    lda.z status_vera
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_vera1_main__0
    // return (unsigned char)(status_vera == status);
    // [145] main::check_vera1_return#0 = (char)main::check_vera1_$0
    // [146] phi from main::check_vera1 to main::check_roms_all1 [phi:main::check_vera1->main::check_roms_all1]
    // main::check_roms_all1
    // [147] phi from main::check_roms_all1 to main::check_roms_all1_@1 [phi:main::check_roms_all1->main::check_roms_all1_@1]
    // [147] phi main::check_roms_all1_rom_chip#2 = 0 [phi:main::check_roms_all1->main::check_roms_all1_@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z check_roms_all1_rom_chip
    // main::check_roms_all1_@1
  check_roms_all1___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [148] if(main::check_roms_all1_rom_chip#2<8) goto main::check_roms_all1_check_rom1 -- vbuz1_lt_vbuc1_then_la1 
    lda.z check_roms_all1_rom_chip
    cmp #8
    bcs !check_roms_all1_check_rom1+
    jmp check_roms_all1_check_rom1
  !check_roms_all1_check_rom1:
    // [149] phi from main::check_roms_all1_@1 to main::check_roms_all1_@return [phi:main::check_roms_all1_@1->main::check_roms_all1_@return]
    // [149] phi main::check_roms_all1_return#2 = 1 [phi:main::check_roms_all1_@1->main::check_roms_all1_@return#0] -- vbuz1=vbuc1 
    lda #1
    sta.z check_roms_all1_return
    // main::check_roms_all1_@return
    // main::@26
  __b26:
    // if(check_smc(STATUS_SKIP) && check_vera(STATUS_SKIP) && check_roms_all(STATUS_SKIP))
    // [150] if(0==main::check_smc4_return#0) goto main::check_smc5 -- 0_eq_vbuz1_then_la1 
    lda.z check_smc4_return
    beq check_smc5
    // main::@61
    // [151] if(0==main::check_vera1_return#0) goto main::check_smc5 -- 0_eq_vbuz1_then_la1 
    lda.z check_vera1_return
    beq check_smc5
    // main::@60
    // [152] if(0!=main::check_roms_all1_return#2) goto main::vera_display_set_border_color1 -- 0_neq_vbuz1_then_la1 
    lda.z check_roms_all1_return
    beq !vera_display_set_border_color1+
    jmp vera_display_set_border_color1
  !vera_display_set_border_color1:
    // main::check_smc5
  check_smc5:
    // status_smc == status
    // [153] main::check_smc5_$0 = status_smc#0 == STATUS_ERROR -- vboz1=vbuz2_eq_vbuc1 
    lda.z status_smc
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_smc5_main__0
    // return (unsigned char)(status_smc == status);
    // [154] main::check_smc5_return#0 = (char)main::check_smc5_$0
    // main::check_vera2
    // status_vera == status
    // [155] main::check_vera2_$0 = status_vera#0 == STATUS_ERROR -- vboz1=vbuz2_eq_vbuc1 
    lda.z status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_vera2_main__0
    // return (unsigned char)(status_vera == status);
    // [156] main::check_vera2_return#0 = (char)main::check_vera2_$0
    // [157] phi from main::check_vera2 to main::check_roms1 [phi:main::check_vera2->main::check_roms1]
    // main::check_roms1
    // [158] phi from main::check_roms1 to main::check_roms1_@1 [phi:main::check_roms1->main::check_roms1_@1]
    // [158] phi main::check_roms1_rom_chip#2 = 0 [phi:main::check_roms1->main::check_roms1_@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z check_roms1_rom_chip
    // main::check_roms1_@1
  check_roms1___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [159] if(main::check_roms1_rom_chip#2<8) goto main::check_roms1_check_rom1 -- vbuz1_lt_vbuc1_then_la1 
    lda.z check_roms1_rom_chip
    cmp #8
    bcs !check_roms1_check_rom1+
    jmp check_roms1_check_rom1
  !check_roms1_check_rom1:
    // [160] phi from main::check_roms1_@1 to main::check_roms1_@return [phi:main::check_roms1_@1->main::check_roms1_@return]
    // [160] phi main::check_roms1_return#2 = STATUS_NONE [phi:main::check_roms1_@1->main::check_roms1_@return#0] -- vbuz1=vbuc1 
    lda #STATUS_NONE
    sta.z check_roms1_return
    // main::check_roms1_@return
    // main::@28
  __b28:
    // if(check_smc(STATUS_ERROR) || check_vera(STATUS_ERROR) || check_roms(STATUS_ERROR))
    // [161] if(0!=main::check_smc5_return#0) goto main::vera_display_set_border_color2 -- 0_neq_vbuz1_then_la1 
    lda.z check_smc5_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::@63
    // [162] if(0!=main::check_vera2_return#0) goto main::vera_display_set_border_color2 -- 0_neq_vbuz1_then_la1 
    lda.z check_vera2_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::@62
    // [163] if(0!=main::check_roms1_return#2) goto main::vera_display_set_border_color2 -- 0_neq_vbuz1_then_la1 
    lda.z check_roms1_return
    beq !vera_display_set_border_color2+
    jmp vera_display_set_border_color2
  !vera_display_set_border_color2:
    // main::check_smc6
    // status_smc == status
    // [164] main::check_smc6_$0 = status_smc#0 == STATUS_ISSUE -- vboz1=vbuz2_eq_vbuc1 
    lda.z status_smc
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_smc6_main__0
    // return (unsigned char)(status_smc == status);
    // [165] main::check_smc6_return#0 = (char)main::check_smc6_$0
    // main::check_vera3
    // status_vera == status
    // [166] main::check_vera3_$0 = status_vera#0 == STATUS_ISSUE -- vboz1=vbuz2_eq_vbuc1 
    lda.z status_vera
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_vera3_main__0
    // return (unsigned char)(status_vera == status);
    // [167] main::check_vera3_return#0 = (char)main::check_vera3_$0
    // [168] phi from main::check_vera3 to main::check_roms2 [phi:main::check_vera3->main::check_roms2]
    // main::check_roms2
    // [169] phi from main::check_roms2 to main::check_roms2_@1 [phi:main::check_roms2->main::check_roms2_@1]
    // [169] phi main::check_roms2_rom_chip#2 = 0 [phi:main::check_roms2->main::check_roms2_@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z check_roms2_rom_chip
    // main::check_roms2_@1
  check_roms2___b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [170] if(main::check_roms2_rom_chip#2<8) goto main::check_roms2_check_rom1 -- vbuz1_lt_vbuc1_then_la1 
    lda.z check_roms2_rom_chip
    cmp #8
    bcs !check_roms2_check_rom1+
    jmp check_roms2_check_rom1
  !check_roms2_check_rom1:
    // [171] phi from main::check_roms2_@1 to main::check_roms2_@return [phi:main::check_roms2_@1->main::check_roms2_@return]
    // [171] phi main::check_roms2_return#2 = STATUS_NONE [phi:main::check_roms2_@1->main::check_roms2_@return#0] -- vbuz1=vbuc1 
    lda #STATUS_NONE
    sta.z check_roms2_return
    // main::check_roms2_@return
    // main::@30
  __b30:
    // if(check_smc(STATUS_ISSUE) || check_vera(STATUS_ISSUE) || check_roms(STATUS_ISSUE))
    // [172] if(0!=main::check_smc6_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbuz1_then_la1 
    lda.z check_smc6_return
    bne vera_display_set_border_color3
    // main::@65
    // [173] if(0!=main::check_vera3_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbuz1_then_la1 
    lda.z check_vera3_return
    bne vera_display_set_border_color3
    // main::@64
    // [174] if(0!=main::check_roms2_return#2) goto main::vera_display_set_border_color3 -- 0_neq_vbuz1_then_la1 
    lda.z check_roms2_return
    bne vera_display_set_border_color3
    // main::vera_display_set_border_color4
    // *VERA_CTRL &= ~VERA_DCSEL
    // [175] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [176] *VERA_DC_BORDER = GREEN -- _deref_pbuc1=vbuc2 
    lda #GREEN
    sta VERA_DC_BORDER
    // [177] phi from main::@27 main::@31 main::vera_display_set_border_color4 to main::@17 [phi:main::@27/main::@31/main::vera_display_set_border_color4->main::@17]
  __b2:
    // [177] phi main::flash_reset#2 = $f0 [phi:main::@27/main::@31/main::vera_display_set_border_color4->main::@17#0] -- vbuz1=vbuc1 
    lda #$f0
    sta.z flash_reset
    // main::@17
  __b17:
    // for(unsigned char flash_reset=240; flash_reset>0; flash_reset--)
    // [178] if(main::flash_reset#2>0) goto main::@18 -- vbuz1_gt_0_then_la1 
    lda.z flash_reset
    bne __b18
    // [179] phi from main::@17 to main::@19 [phi:main::@17->main::@19]
    // main::@19
    // system_reset()
    // [180] call system_reset
    // [497] phi from main::@19 to system_reset [phi:main::@19->system_reset]
    jsr system_reset
    // main::@return
    // }
    // [181] return 
    rts
    // [182] phi from main::@17 to main::@18 [phi:main::@17->main::@18]
    // main::@18
  __b18:
    // wait_moment()
    // [183] call wait_moment
    // [502] phi from main::@18 to wait_moment [phi:main::@18->wait_moment]
    jsr wait_moment
    // [184] phi from main::@18 to main::@52 [phi:main::@18->main::@52]
    // main::@52
    // sprintf(info_text, "Resetting your CX16 in %u ...", flash_reset)
    // [185] call snprintf_init
    jsr snprintf_init
    // [186] phi from main::@52 to main::@53 [phi:main::@52->main::@53]
    // main::@53
    // sprintf(info_text, "Resetting your CX16 in %u ...", flash_reset)
    // [187] call printf_str
    // [511] phi from main::@53 to printf_str [phi:main::@53->printf_str]
    // [511] phi printf_str::putc#17 = &snputc [phi:main::@53->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [511] phi printf_str::s#17 = main::s2 [phi:main::@53->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // main::@54
    // sprintf(info_text, "Resetting your CX16 in %u ...", flash_reset)
    // [188] printf_uchar::uvalue#1 = main::flash_reset#2 -- vbuz1=vbuz2 
    lda.z flash_reset
    sta.z printf_uchar.uvalue
    // [189] call printf_uchar
    // [520] phi from main::@54 to printf_uchar [phi:main::@54->printf_uchar]
    // [520] phi printf_uchar::putc#2 = &snputc [phi:main::@54->printf_uchar#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [520] phi printf_uchar::uvalue#2 = printf_uchar::uvalue#1 [phi:main::@54->printf_uchar#1] -- register_copy 
    jsr printf_uchar
    // [190] phi from main::@54 to main::@55 [phi:main::@54->main::@55]
    // main::@55
    // sprintf(info_text, "Resetting your CX16 in %u ...", flash_reset)
    // [191] call printf_str
    // [511] phi from main::@55 to printf_str [phi:main::@55->printf_str]
    // [511] phi printf_str::putc#17 = &snputc [phi:main::@55->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [511] phi printf_str::s#17 = main::s3 [phi:main::@55->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // main::@56
    // sprintf(info_text, "Resetting your CX16 in %u ...", flash_reset)
    // [192] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [193] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [195] call info_line
    // [528] phi from main::@56 to info_line [phi:main::@56->info_line]
    // [528] phi info_line::info_text#4 = info_text [phi:main::@56->info_line#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z info_line.info_text
    lda #>@info_text
    sta.z info_line.info_text+1
    jsr info_line
    // main::@57
    // for(unsigned char flash_reset=240; flash_reset>0; flash_reset--)
    // [196] main::flash_reset#1 = -- main::flash_reset#2 -- vbuz1=_dec_vbuz1 
    dec.z flash_reset
    // [177] phi from main::@57 to main::@17 [phi:main::@57->main::@17]
    // [177] phi main::flash_reset#2 = main::flash_reset#1 [phi:main::@57->main::@17#0] -- register_copy 
    jmp __b17
    // main::vera_display_set_border_color3
  vera_display_set_border_color3:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [197] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [198] *VERA_DC_BORDER = YELLOW -- _deref_pbuc1=vbuc2 
    lda #YELLOW
    sta VERA_DC_BORDER
    // [199] phi from main::vera_display_set_border_color3 to main::@31 [phi:main::vera_display_set_border_color3->main::@31]
    // main::@31
    // info_progress("Update issues, your CX16 is not updated!")
    // [200] call info_progress
    // [395] phi from main::@31 to info_progress [phi:main::@31->info_progress]
    // [395] phi info_progress::info_text#10 = main::info_text16 [phi:main::@31->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text16
    sta.z info_progress.info_text
    lda #>info_text16
    sta.z info_progress.info_text+1
    jsr info_progress
    jmp __b2
    // main::check_roms2_check_rom1
  check_roms2_check_rom1:
    // status_rom[rom_chip] == status
    // [201] main::check_roms2_check_rom1_$0 = status_rom[main::check_roms2_rom_chip#2] == STATUS_ISSUE -- vboz1=pbuc1_derefidx_vbuz2_eq_vbuc2 
    lda #STATUS_ISSUE
    ldy.z check_roms2_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_roms2_check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [202] main::check_roms2_check_rom1_return#0 = (char)main::check_roms2_check_rom1_$0
    // main::check_roms2_@11
    // if(check_rom(rom_chip, status) == status)
    // [203] if(main::check_roms2_check_rom1_return#0!=STATUS_ISSUE) goto main::check_roms2_@4 -- vbuz1_neq_vbuc1_then_la1 
    lda #STATUS_ISSUE
    cmp.z check_roms2_check_rom1_return
    bne check_roms2___b4
    // [171] phi from main::check_roms2_@11 to main::check_roms2_@return [phi:main::check_roms2_@11->main::check_roms2_@return]
    // [171] phi main::check_roms2_return#2 = STATUS_ISSUE [phi:main::check_roms2_@11->main::check_roms2_@return#0] -- vbuz1=vbuc1 
    sta.z check_roms2_return
    jmp __b30
    // main::check_roms2_@4
  check_roms2___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [204] main::check_roms2_rom_chip#1 = ++ main::check_roms2_rom_chip#2 -- vbuz1=_inc_vbuz1 
    inc.z check_roms2_rom_chip
    // [169] phi from main::check_roms2_@4 to main::check_roms2_@1 [phi:main::check_roms2_@4->main::check_roms2_@1]
    // [169] phi main::check_roms2_rom_chip#2 = main::check_roms2_rom_chip#1 [phi:main::check_roms2_@4->main::check_roms2_@1#0] -- register_copy 
    jmp check_roms2___b1
    // main::vera_display_set_border_color2
  vera_display_set_border_color2:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [205] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [206] *VERA_DC_BORDER = RED -- _deref_pbuc1=vbuc2 
    lda #RED
    sta VERA_DC_BORDER
    // [207] phi from main::vera_display_set_border_color2 to main::@29 [phi:main::vera_display_set_border_color2->main::@29]
    // main::@29
    // info_progress("Update Failure! Your CX16 may be bricked!")
    // [208] call info_progress
    // [395] phi from main::@29 to info_progress [phi:main::@29->info_progress]
    // [395] phi info_progress::info_text#10 = main::info_text14 [phi:main::@29->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text14
    sta.z info_progress.info_text
    lda #>info_text14
    sta.z info_progress.info_text+1
    jsr info_progress
    // [209] phi from main::@29 to main::@51 [phi:main::@29->main::@51]
    // main::@51
    // info_line("Take a foto of this screen. And shut down power ...")
    // [210] call info_line
    // [528] phi from main::@51 to info_line [phi:main::@51->info_line]
    // [528] phi info_line::info_text#4 = main::info_text15 [phi:main::@51->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text15
    sta.z info_line.info_text
    lda #>info_text15
    sta.z info_line.info_text+1
    jsr info_line
    // [211] phi from main::@16 main::@51 to main::@16 [phi:main::@16/main::@51->main::@16]
    // main::@16
  __b16:
    jmp __b16
    // main::check_roms1_check_rom1
  check_roms1_check_rom1:
    // status_rom[rom_chip] == status
    // [212] main::check_roms1_check_rom1_$0 = status_rom[main::check_roms1_rom_chip#2] == STATUS_ERROR -- vboz1=pbuc1_derefidx_vbuz2_eq_vbuc2 
    lda #STATUS_ERROR
    ldy.z check_roms1_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_roms1_check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [213] main::check_roms1_check_rom1_return#0 = (char)main::check_roms1_check_rom1_$0
    // main::check_roms1_@11
    // if(check_rom(rom_chip, status) == status)
    // [214] if(main::check_roms1_check_rom1_return#0!=STATUS_ERROR) goto main::check_roms1_@4 -- vbuz1_neq_vbuc1_then_la1 
    lda #STATUS_ERROR
    cmp.z check_roms1_check_rom1_return
    bne check_roms1___b4
    // [160] phi from main::check_roms1_@11 to main::check_roms1_@return [phi:main::check_roms1_@11->main::check_roms1_@return]
    // [160] phi main::check_roms1_return#2 = STATUS_ERROR [phi:main::check_roms1_@11->main::check_roms1_@return#0] -- vbuz1=vbuc1 
    sta.z check_roms1_return
    jmp __b28
    // main::check_roms1_@4
  check_roms1___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [215] main::check_roms1_rom_chip#1 = ++ main::check_roms1_rom_chip#2 -- vbuz1=_inc_vbuz1 
    inc.z check_roms1_rom_chip
    // [158] phi from main::check_roms1_@4 to main::check_roms1_@1 [phi:main::check_roms1_@4->main::check_roms1_@1]
    // [158] phi main::check_roms1_rom_chip#2 = main::check_roms1_rom_chip#1 [phi:main::check_roms1_@4->main::check_roms1_@1#0] -- register_copy 
    jmp check_roms1___b1
    // main::vera_display_set_border_color1
  vera_display_set_border_color1:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [216] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [217] *VERA_DC_BORDER = BLACK -- _deref_pbuc1=vbuc2 
    lda #BLACK
    sta VERA_DC_BORDER
    // [218] phi from main::vera_display_set_border_color1 to main::@27 [phi:main::vera_display_set_border_color1->main::@27]
    // main::@27
    // info_progress("The update has been cancelled!")
    // [219] call info_progress
    // [395] phi from main::@27 to info_progress [phi:main::@27->info_progress]
    // [395] phi info_progress::info_text#10 = main::info_text13 [phi:main::@27->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text13
    sta.z info_progress.info_text
    lda #>info_text13
    sta.z info_progress.info_text+1
    jsr info_progress
    jmp __b2
    // main::check_roms_all1_check_rom1
  check_roms_all1_check_rom1:
    // status_rom[rom_chip] == status
    // [220] main::check_roms_all1_check_rom1_$0 = status_rom[main::check_roms_all1_rom_chip#2] == STATUS_SKIP -- vboz1=pbuc1_derefidx_vbuz2_eq_vbuc2 
    lda #STATUS_SKIP
    ldy.z check_roms_all1_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_roms_all1_check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [221] main::check_roms_all1_check_rom1_return#0 = (char)main::check_roms_all1_check_rom1_$0
    // main::check_roms_all1_@11
    // if(check_rom(rom_chip, status) != status)
    // [222] if(main::check_roms_all1_check_rom1_return#0==STATUS_SKIP) goto main::check_roms_all1_@4 -- vbuz1_eq_vbuc1_then_la1 
    lda #STATUS_SKIP
    cmp.z check_roms_all1_check_rom1_return
    beq check_roms_all1___b4
    // [149] phi from main::check_roms_all1_@11 to main::check_roms_all1_@return [phi:main::check_roms_all1_@11->main::check_roms_all1_@return]
    // [149] phi main::check_roms_all1_return#2 = 0 [phi:main::check_roms_all1_@11->main::check_roms_all1_@return#0] -- vbuz1=vbuc1 
    lda #0
    sta.z check_roms_all1_return
    jmp __b26
    // main::check_roms_all1_@4
  check_roms_all1___b4:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [223] main::check_roms_all1_rom_chip#1 = ++ main::check_roms_all1_rom_chip#2 -- vbuz1=_inc_vbuz1 
    inc.z check_roms_all1_rom_chip
    // [147] phi from main::check_roms_all1_@4 to main::check_roms_all1_@1 [phi:main::check_roms_all1_@4->main::check_roms_all1_@1]
    // [147] phi main::check_roms_all1_rom_chip#2 = main::check_roms_all1_rom_chip#1 [phi:main::check_roms_all1_@4->main::check_roms_all1_@1#0] -- register_copy 
    jmp check_roms_all1___b1
    // [224] phi from main::@58 main::@59 to main::@1 [phi:main::@58/main::@59->main::@1]
    // main::@1
  __b1:
    // info_progress("Chipsets have been detected and update files validated!")
    // [225] call info_progress
    // [395] phi from main::@1 to info_progress [phi:main::@1->info_progress]
    // [395] phi info_progress::info_text#10 = main::info_text6 [phi:main::@1->info_progress#0] -- pbuz1=pbuc1 
    lda #<info_text6
    sta.z info_progress.info_text
    lda #>info_text6
    sta.z info_progress.info_text+1
    jsr info_progress
    // [226] phi from main::@1 to main::@46 [phi:main::@1->main::@46]
    // main::@46
    // unsigned char ch = wait_key("Continue with update? [Y/N]", "nyNY")
    // [227] call wait_key
    // [440] phi from main::@46 to wait_key [phi:main::@46->wait_key]
    // [440] phi wait_key::filter#14 = main::filter3 [phi:main::@46->wait_key#0] -- pbuz1=pbuc1 
    lda #<filter3
    sta.z wait_key.filter
    lda #>filter3
    sta.z wait_key.filter+1
    // [440] phi wait_key::info_text#4 = main::info_text7 [phi:main::@46->wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z wait_key.info_text
    lda #>info_text7
    sta.z wait_key.info_text+1
    jsr wait_key
    // unsigned char ch = wait_key("Continue with update? [Y/N]", "nyNY")
    // [228] wait_key::return#5 = wait_key::ch#4 -- vbuz1=vwuz2 
    lda.z wait_key.ch
    sta.z wait_key.return
    // main::@47
    // [229] main::ch#0 = wait_key::return#5
    // strchr("nN", ch)
    // [230] strchr::c#1 = main::ch#0
    // [231] call strchr
    // [542] phi from main::@47 to strchr [phi:main::@47->strchr]
    // [542] phi strchr::c#4 = strchr::c#1 [phi:main::@47->strchr#0] -- register_copy 
    // [542] phi strchr::str#2 = (const void *)main::$90 [phi:main::@47->strchr#1] -- pvoz1=pvoc1 
    lda #<main__90
    sta.z strchr.str
    lda #>main__90
    sta.z strchr.str+1
    jsr strchr
    // strchr("nN", ch)
    // [232] strchr::return#4 = strchr::return#2
    // main::@48
    // [233] main::$54 = strchr::return#4
    // if(strchr("nN", ch))
    // [234] if((void *)0==main::$54) goto main::SEI1 -- pvoc1_eq_pvoz1_then_la1 
    lda.z main__54
    cmp #<0
    bne !+
    lda.z main__54+1
    cmp #>0
    bne !SEI1+
    jmp SEI1
  !SEI1:
  !:
    // [235] phi from main::@48 to main::@2 [phi:main::@48->main::@2]
    // main::@2
    // info_smc(STATUS_SKIP, "Cancelled")
    // [236] call info_smc
  // We cancel all updates, the updates are skipped.
    // [464] phi from main::@2 to info_smc [phi:main::@2->info_smc]
    // [464] phi info_smc::info_text#10 = main::info_text8 [phi:main::@2->info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z info_smc.info_text
    lda #>info_text8
    sta.z info_smc.info_text+1
    // [464] phi info_smc::info_status#2 = STATUS_SKIP [phi:main::@2->info_smc#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z info_smc.info_status
    jsr info_smc
    // [237] phi from main::@2 to main::@49 [phi:main::@2->main::@49]
    // main::@49
    // info_vera(STATUS_SKIP, "Cancelled")
    // [238] call info_vera
    // [414] phi from main::@49 to info_vera [phi:main::@49->info_vera]
    // [414] phi info_vera::info_text#10 = main::info_text8 [phi:main::@49->info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z info_vera.info_text
    lda #>info_text8
    sta.z info_vera.info_text+1
    // [414] phi info_vera::info_status#2 = STATUS_SKIP [phi:main::@49->info_vera#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z info_vera.info_status
    jsr info_vera
    // [239] phi from main::@49 to main::@13 [phi:main::@49->main::@13]
    // [239] phi main::rom_chip#2 = 0 [phi:main::@49->main::@13#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip
    // main::@13
  __b13:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [240] if(main::rom_chip#2<8) goto main::@14 -- vbuz1_lt_vbuc1_then_la1 
    lda.z rom_chip
    cmp #8
    bcc __b14
    // [241] phi from main::@13 to main::@15 [phi:main::@13->main::@15]
    // main::@15
    // info_line("You have selected not to cancel the update ... ")
    // [242] call info_line
    // [528] phi from main::@15 to info_line [phi:main::@15->info_line]
    // [528] phi info_line::info_text#4 = main::info_text11 [phi:main::@15->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text11
    sta.z info_line.info_text
    lda #>info_text11
    sta.z info_line.info_text+1
    jsr info_line
    jmp SEI1
    // main::@14
  __b14:
    // info_rom(rom_chip, STATUS_SKIP, "Cancelled")
    // [243] info_rom::rom_chip#1 = main::rom_chip#2 -- vbuz1=vbuz2 
    lda.z rom_chip
    sta.z info_rom.rom_chip
    // [244] call info_rom
    // [551] phi from main::@14 to info_rom [phi:main::@14->info_rom]
    // [551] phi info_rom::info_text#10 = main::info_text8 [phi:main::@14->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z info_rom.info_text
    lda #>info_text8
    sta.z info_rom.info_text+1
    // [551] phi info_rom::rom_chip#10 = info_rom::rom_chip#1 [phi:main::@14->info_rom#1] -- register_copy 
    // [551] phi info_rom::info_status#2 = STATUS_SKIP [phi:main::@14->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z info_rom.info_status
    jsr info_rom
    // main::@50
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [245] main::rom_chip#1 = ++ main::rom_chip#2 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip
    // [239] phi from main::@50 to main::@13 [phi:main::@50->main::@13]
    // [239] phi main::rom_chip#2 = main::rom_chip#1 [phi:main::@50->main::@13#0] -- register_copy 
    jmp __b13
    // main::check_card_roms1_check_rom1
  check_card_roms1_check_rom1:
    // status_rom[rom_chip] == status
    // [246] main::check_card_roms1_check_rom1_$0 = status_rom[main::check_card_roms1_rom_chip#2] == STATUS_FLASH -- vboz1=pbuc1_derefidx_vbuz2_eq_vbuc2 
    lda #STATUS_FLASH
    ldy.z check_card_roms1_rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_card_roms1_check_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [247] main::check_card_roms1_check_rom1_return#0 = (char)main::check_card_roms1_check_rom1_$0
    // main::check_card_roms1_@11
    // if(check_rom(rom_chip, status))
    // [248] if(0==main::check_card_roms1_check_rom1_return#0) goto main::check_card_roms1_@4 -- 0_eq_vbuz1_then_la1 
    lda.z check_card_roms1_check_rom1_return
    beq check_card_roms1___b4
    // [129] phi from main::check_card_roms1_@11 to main::check_card_roms1_@return [phi:main::check_card_roms1_@11->main::check_card_roms1_@return]
    // [129] phi main::check_card_roms1_return#2 = STATUS_FLASH [phi:main::check_card_roms1_@11->main::check_card_roms1_@return#0] -- vbuz1=vbuc1 
    lda #STATUS_FLASH
    sta.z check_card_roms1_return
    jmp __b23
    // main::check_card_roms1_@4
  check_card_roms1___b4:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [249] main::check_card_roms1_rom_chip#1 = ++ main::check_card_roms1_rom_chip#2 -- vbuz1=_inc_vbuz1 
    inc.z check_card_roms1_rom_chip
    // [127] phi from main::check_card_roms1_@4 to main::check_card_roms1_@1 [phi:main::check_card_roms1_@4->main::check_card_roms1_@1]
    // [127] phi main::check_card_roms1_rom_chip#2 = main::check_card_roms1_rom_chip#1 [phi:main::check_card_roms1_@4->main::check_card_roms1_@1#0] -- register_copy 
    jmp check_card_roms1___b1
    // main::@10
  __b10:
    // print_info_led(PROGRESS_X + 3, PROGRESS_Y + 3 + intro_status, status_color[intro_status], BLUE)
    // [250] print_info_led::y#3 = PROGRESS_Y+3 + main::intro_status#2 -- vbuz1=vbuc1_plus_vbuz2 
    lda #PROGRESS_Y+3
    clc
    adc.z intro_status
    sta.z print_info_led.y
    // [251] print_info_led::tc#3 = status_color[main::intro_status#2] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z intro_status
    lda status_color,y
    sta.z print_info_led.tc
    // [252] call print_info_led
    // [596] phi from main::@10 to print_info_led [phi:main::@10->print_info_led]
    // [596] phi print_info_led::y#4 = print_info_led::y#3 [phi:main::@10->print_info_led#0] -- register_copy 
    // [596] phi print_info_led::x#4 = PROGRESS_X+3 [phi:main::@10->print_info_led#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X+3
    sta.z print_info_led.x
    // [596] phi print_info_led::tc#4 = print_info_led::tc#3 [phi:main::@10->print_info_led#2] -- register_copy 
    jsr print_info_led
    // main::@41
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [253] main::intro_status#1 = ++ main::intro_status#2 -- vbuz1=_inc_vbuz1 
    inc.z intro_status
    // [102] phi from main::@41 to main::@9 [phi:main::@41->main::@9]
    // [102] phi main::intro_status#2 = main::intro_status#1 [phi:main::@41->main::@9#0] -- register_copy 
    jmp __b9
    // main::@8
  __b8:
    // progress_text(intro_line, into_colors_text[intro_line])
    // [254] main::$84 = main::intro_line1#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z intro_line1
    asl
    sta.z main__84
    // [255] progress_text::line#1 = main::intro_line1#2 -- vbuz1=vbuz2 
    lda.z intro_line1
    sta.z progress_text.line
    // [256] progress_text::text#1 = main::into_colors_text[main::$84] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z main__84
    lda into_colors_text,y
    sta.z progress_text.text
    lda into_colors_text+1,y
    sta.z progress_text.text+1
    // [257] call progress_text
    // [607] phi from main::@8 to progress_text [phi:main::@8->progress_text]
    // [607] phi progress_text::text#2 = progress_text::text#1 [phi:main::@8->progress_text#0] -- register_copy 
    // [607] phi progress_text::line#2 = progress_text::line#1 [phi:main::@8->progress_text#1] -- register_copy 
    jsr progress_text
    // main::@40
    // for(unsigned char intro_line=0; intro_line<intro_colors_count; intro_line++)
    // [258] main::intro_line1#1 = ++ main::intro_line1#2 -- vbuz1=_inc_vbuz1 
    inc.z intro_line1
    // [100] phi from main::@40 to main::@7 [phi:main::@40->main::@7]
    // [100] phi main::intro_line1#2 = main::intro_line1#1 [phi:main::@40->main::@7#0] -- register_copy 
    jmp __b7
    // main::@5
  __b5:
    // progress_text(intro_line, into_briefing_text[intro_line])
    // [259] main::$83 = main::intro_line#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z intro_line
    asl
    sta.z main__83
    // [260] progress_text::line#0 = main::intro_line#2 -- vbuz1=vbuz2 
    lda.z intro_line
    sta.z progress_text.line
    // [261] progress_text::text#0 = main::into_briefing_text[main::$83] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z main__83
    lda into_briefing_text,y
    sta.z progress_text.text
    lda into_briefing_text+1,y
    sta.z progress_text.text+1
    // [262] call progress_text
    // [607] phi from main::@5 to progress_text [phi:main::@5->progress_text]
    // [607] phi progress_text::text#2 = progress_text::text#0 [phi:main::@5->progress_text#0] -- register_copy 
    // [607] phi progress_text::line#2 = progress_text::line#0 [phi:main::@5->progress_text#1] -- register_copy 
    jsr progress_text
    // main::@38
    // for(unsigned char intro_line=0; intro_line<intro_briefing_count; intro_line++)
    // [263] main::intro_line#1 = ++ main::intro_line#2 -- vbuz1=_inc_vbuz1 
    inc.z intro_line
    // [94] phi from main::@38 to main::@4 [phi:main::@38->main::@4]
    // [94] phi main::intro_line#2 = main::intro_line#1 [phi:main::@38->main::@4#0] -- register_copy 
    jmp __b4
  .segment Data
    into_briefing_text: .word __14, __15, __42, __17, __18, __19, __20, __21, __22, __23, __24, __42, __26, __27
    .fill 2*2, 0
    into_colors_text: .word __28, __29, __42, __31, __32, __33, __34, __35, __36, __37, __38, __39, __40, __41, __42, __43
    title_text: .text "Commander X16 Flash Utility!"
    .byte 0
    s: .text "# Chip Status    Type   File  / Total Information"
    .byte 0
    s1: .text "- ---- --------- ------ ----- / ----- --------------------"
    .byte 0
    info_text: .text "Detecting SMC, VERA and ROM chipsets ..."
    .byte 0
    info_text1: .text "VERA installed, OK"
    .byte 0
    info_text2: .text "Please read carefully the below, and press [SPACE] ..."
    .byte 0
    info_text3: .text "If understood, press [SPACE] to start the update ..."
    .byte 0
    info_text4: .text "There is an issue with either the SMC or the CX16 main ROM!"
    .byte 0
    info_text5: .text "Press [SPACE] to continue [ ]"
    .byte 0
    info_text6: .text "Chipsets have been detected and update files validated!"
    .byte 0
    info_text7: .text "Continue with update? [Y/N]"
    .byte 0
    filter3: .text "nyNY"
    .byte 0
    main__90: .text "nN"
    .byte 0
    info_text8: .text "Cancelled"
    .byte 0
    info_text11: .text "You have selected not to cancel the update ... "
    .byte 0
    info_text12: .text "Update finished ..."
    .byte 0
    info_text13: .text "The update has been cancelled!"
    .byte 0
    info_text14: .text "Update Failure! Your CX16 may be bricked!"
    .byte 0
    info_text15: .text "Take a foto of this screen. And shut down power ..."
    .byte 0
    info_text16: .text "Update issues, your CX16 is not updated!"
    .byte 0
    s2: .text "Resetting your CX16 in "
    .byte 0
    s3: .text " ..."
    .byte 0
}
.segment Code
  // screenlayer1
// Set the layer with which the conio will interact.
screenlayer1: {
    // screenlayer(1, *VERA_L1_MAPBASE, *VERA_L1_CONFIG)
    // [264] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbuz1=_deref_pbuc1 
    lda VERA_L1_MAPBASE
    sta.z screenlayer.mapbase
    // [265] screenlayer::config#0 = *VERA_L1_CONFIG -- vbuz1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta.z screenlayer.config
    // [266] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [267] return 
    rts
}
  // textcolor
// Set the front color for text output. The old front text color setting is returned.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char textcolor(__zp($61) char color)
textcolor: {
    .label textcolor__0 = $63
    .label textcolor__1 = $61
    .label color = $61
    // __conio.color & 0xF0
    // [269] textcolor::$0 = *((char *)&__conio+$d) & $f0 -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$d
    sta.z textcolor__0
    // __conio.color & 0xF0 | color
    // [270] textcolor::$1 = textcolor::$0 | textcolor::color#16 -- vbuz1=vbuz2_bor_vbuz1 
    lda.z textcolor__1
    ora.z textcolor__0
    sta.z textcolor__1
    // __conio.color = __conio.color & 0xF0 | color
    // [271] *((char *)&__conio+$d) = textcolor::$1 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // textcolor::@return
    // }
    // [272] return 
    rts
}
  // bgcolor
// Set the back color for text output.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char bgcolor(__zp($61) char color)
bgcolor: {
    .label bgcolor__0 = $62
    .label bgcolor__1 = $61
    .label bgcolor__2 = $62
    .label color = $61
    // __conio.color & 0x0F
    // [274] bgcolor::$0 = *((char *)&__conio+$d) & $f -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$d
    sta.z bgcolor__0
    // color << 4
    // [275] bgcolor::$1 = bgcolor::color#14 << 4 -- vbuz1=vbuz1_rol_4 
    lda.z bgcolor__1
    asl
    asl
    asl
    asl
    sta.z bgcolor__1
    // __conio.color & 0x0F | color << 4
    // [276] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbuz1=vbuz1_bor_vbuz2 
    lda.z bgcolor__2
    ora.z bgcolor__1
    sta.z bgcolor__2
    // __conio.color = __conio.color & 0x0F | color << 4
    // [277] *((char *)&__conio+$d) = bgcolor::$2 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // bgcolor::@return
    // }
    // [278] return 
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
    // [279] *((char *)&__conio+$c) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$c
    // cursor::@return
    // }
    // [280] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    .label return = $75
    // __mem unsigned char x
    // [281] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [282] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [284] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwuz1=vbum2_word_vbum3 
    lda x
    sta.z return+1
    lda y
    sta.z return
    // cbm_k_plot_get::@return
    // }
    // [285] return 
    rts
  .segment Data
    x: .byte 0
    y: .byte 0
}
.segment Code
  // gotoxy
// Set the cursor to the specified position
// void gotoxy(__zp($33) char x, __zp($34) char y)
gotoxy: {
    .label gotoxy__2 = $33
    .label gotoxy__3 = $33
    .label gotoxy__6 = $32
    .label gotoxy__7 = $32
    .label gotoxy__8 = $37
    .label gotoxy__9 = $35
    .label gotoxy__10 = $34
    .label x = $33
    .label y = $34
    .label gotoxy__14 = $32
    // (x>=__conio.width)?__conio.width:x
    // [287] if(gotoxy::x#19>=*((char *)&__conio+6)) goto gotoxy::@1 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z x
    cmp __conio+6
    bcs __b1
    // [289] phi from gotoxy gotoxy::@1 to gotoxy::@2 [phi:gotoxy/gotoxy::@1->gotoxy::@2]
    // [289] phi gotoxy::$3 = gotoxy::x#19 [phi:gotoxy/gotoxy::@1->gotoxy::@2#0] -- register_copy 
    jmp __b2
    // gotoxy::@1
  __b1:
    // [288] gotoxy::$2 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z gotoxy__2
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [290] *((char *)&__conio) = gotoxy::$3 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__3
    sta __conio
    // (y>=__conio.height)?__conio.height:y
    // [291] if(gotoxy::y#19>=*((char *)&__conio+7)) goto gotoxy::@3 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z y
    cmp __conio+7
    bcs __b3
    // gotoxy::@4
    // [292] gotoxy::$14 = gotoxy::y#19 -- vbuz1=vbuz2 
    sta.z gotoxy__14
    // [293] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [293] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [294] *((char *)&__conio+1) = gotoxy::$7 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__7
    sta __conio+1
    // __conio.cursor_x << 1
    // [295] gotoxy::$8 = *((char *)&__conio) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio
    asl
    sta.z gotoxy__8
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [296] gotoxy::$10 = gotoxy::y#19 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z gotoxy__10
    // [297] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwuz1=pwuc1_derefidx_vbuz2_plus_vbuz3 
    ldy.z gotoxy__10
    clc
    adc __conio+$15,y
    sta.z gotoxy__9
    lda __conio+$15+1,y
    adc #0
    sta.z gotoxy__9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [298] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwuz1 
    lda.z gotoxy__9
    sta __conio+$13
    lda.z gotoxy__9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [299] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [300] gotoxy::$6 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
    lda __conio+7
    sta.z gotoxy__6
    jmp __b5
}
  // cputln
// Print a newline
cputln: {
    .label cputln__2 = $44
    // __conio.cursor_x = 0
    // [301] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y++;
    // [302] *((char *)&__conio+1) = ++ *((char *)&__conio+1) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+1
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [303] cputln::$2 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z cputln__2
    // [304] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [305] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [306] return 
    rts
}
  // frame_init
frame_init: {
    .const vera_display_set_hstart1_start = $b
    .const vera_display_set_hstop1_stop = $93
    .const vera_display_set_vstart1_start = $13
    .const vera_display_set_vstop1_stop = $db
    .label cx16_k_screen_set_charset1_charset = $ba
    .label cx16_k_screen_set_charset1_offset = $b8
    // textcolor(WHITE)
    // [308] call textcolor
  // Set the charset to lower case.
  // screenlayer1();
    // [268] phi from frame_init to textcolor [phi:frame_init->textcolor]
    // [268] phi textcolor::color#16 = WHITE [phi:frame_init->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [309] phi from frame_init to frame_init::@2 [phi:frame_init->frame_init::@2]
    // frame_init::@2
    // bgcolor(BLUE)
    // [310] call bgcolor
    // [273] phi from frame_init::@2 to bgcolor [phi:frame_init::@2->bgcolor]
    // [273] phi bgcolor::color#14 = BLUE [phi:frame_init::@2->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [311] phi from frame_init::@2 to frame_init::@3 [phi:frame_init::@2->frame_init::@3]
    // frame_init::@3
    // scroll(0)
    // [312] call scroll
    jsr scroll
    // [313] phi from frame_init::@3 to frame_init::@4 [phi:frame_init::@3->frame_init::@4]
    // frame_init::@4
    // clrscr()
    // [314] call clrscr
    jsr clrscr
    // frame_init::vera_display_set_hstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [315] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTART = start
    // [316] *VERA_DC_HSTART = frame_init::vera_display_set_hstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstart1_start
    sta VERA_DC_HSTART
    // frame_init::vera_display_set_hstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [317] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTOP = stop
    // [318] *VERA_DC_HSTOP = frame_init::vera_display_set_hstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstop1_stop
    sta VERA_DC_HSTOP
    // frame_init::vera_display_set_vstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [319] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTART = start
    // [320] *VERA_DC_VSTART = frame_init::vera_display_set_vstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstart1_start
    sta VERA_DC_VSTART
    // frame_init::vera_display_set_vstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [321] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTOP = stop
    // [322] *VERA_DC_VSTOP = frame_init::vera_display_set_vstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstop1_stop
    sta VERA_DC_VSTOP
    // frame_init::@1
    // cx16_k_screen_set_charset(3, (char *)0)
    // [323] frame_init::cx16_k_screen_set_charset1_charset = 3 -- vbuz1=vbuc1 
    lda #3
    sta.z cx16_k_screen_set_charset1_charset
    // [324] frame_init::cx16_k_screen_set_charset1_offset = (char *) 0 -- pbuz1=pbuc1 
    lda #<0
    sta.z cx16_k_screen_set_charset1_offset
    sta.z cx16_k_screen_set_charset1_offset+1
    // frame_init::cx16_k_screen_set_charset1
    // asm
    // asm { ldacharset ldx<offset ldy>offset jsrCX16_SCREEN_SET_CHARSET  }
    lda cx16_k_screen_set_charset1_charset
    ldx.z <cx16_k_screen_set_charset1_offset
    ldy.z >cx16_k_screen_set_charset1_offset
    jsr CX16_SCREEN_SET_CHARSET
    // frame_init::@return
    // }
    // [326] return 
    rts
}
  // frame_draw
frame_draw: {
    // textcolor(LIGHT_BLUE)
    // [328] call textcolor
    // [268] phi from frame_draw to textcolor [phi:frame_draw->textcolor]
    // [268] phi textcolor::color#16 = LIGHT_BLUE [phi:frame_draw->textcolor#0] -- vbuz1=vbuc1 
    lda #LIGHT_BLUE
    sta.z textcolor.color
    jsr textcolor
    // [329] phi from frame_draw to frame_draw::@1 [phi:frame_draw->frame_draw::@1]
    // frame_draw::@1
    // bgcolor(BLUE)
    // [330] call bgcolor
    // [273] phi from frame_draw::@1 to bgcolor [phi:frame_draw::@1->bgcolor]
    // [273] phi bgcolor::color#14 = BLUE [phi:frame_draw::@1->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [331] phi from frame_draw::@1 to frame_draw::@2 [phi:frame_draw::@1->frame_draw::@2]
    // frame_draw::@2
    // clrscr()
    // [332] call clrscr
    jsr clrscr
    // [333] phi from frame_draw::@2 to frame_draw::@3 [phi:frame_draw::@2->frame_draw::@3]
    // frame_draw::@3
    // frame(0, 0, 67, 14)
    // [334] call frame
    // [683] phi from frame_draw::@3 to frame [phi:frame_draw::@3->frame]
    // [683] phi frame::y#0 = 0 [phi:frame_draw::@3->frame#0] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.y
    // [683] phi frame::y1#16 = $e [phi:frame_draw::@3->frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z frame.y1
    // [683] phi frame::x#0 = 0 [phi:frame_draw::@3->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [683] phi frame::x1#16 = $43 [phi:frame_draw::@3->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [335] phi from frame_draw::@3 to frame_draw::@4 [phi:frame_draw::@3->frame_draw::@4]
    // frame_draw::@4
    // frame(0, 0, 67, 2)
    // [336] call frame
    // [683] phi from frame_draw::@4 to frame [phi:frame_draw::@4->frame]
    // [683] phi frame::y#0 = 0 [phi:frame_draw::@4->frame#0] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.y
    // [683] phi frame::y1#16 = 2 [phi:frame_draw::@4->frame#1] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y1
    // [683] phi frame::x#0 = 0 [phi:frame_draw::@4->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [683] phi frame::x1#16 = $43 [phi:frame_draw::@4->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [337] phi from frame_draw::@4 to frame_draw::@5 [phi:frame_draw::@4->frame_draw::@5]
    // frame_draw::@5
    // frame(0, 2, 67, 14)
    // [338] call frame
    // [683] phi from frame_draw::@5 to frame [phi:frame_draw::@5->frame]
    // [683] phi frame::y#0 = 2 [phi:frame_draw::@5->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [683] phi frame::y1#16 = $e [phi:frame_draw::@5->frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z frame.y1
    // [683] phi frame::x#0 = 0 [phi:frame_draw::@5->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [683] phi frame::x1#16 = $43 [phi:frame_draw::@5->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [339] phi from frame_draw::@5 to frame_draw::@6 [phi:frame_draw::@5->frame_draw::@6]
    // frame_draw::@6
    // frame(0, 2, 8, 14)
    // [340] call frame
  // Chipset areas
    // [683] phi from frame_draw::@6 to frame [phi:frame_draw::@6->frame]
    // [683] phi frame::y#0 = 2 [phi:frame_draw::@6->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [683] phi frame::y1#16 = $e [phi:frame_draw::@6->frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z frame.y1
    // [683] phi frame::x#0 = 0 [phi:frame_draw::@6->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [683] phi frame::x1#16 = 8 [phi:frame_draw::@6->frame#3] -- vbuz1=vbuc1 
    lda #8
    sta.z frame.x1
    jsr frame
    // [341] phi from frame_draw::@6 to frame_draw::@7 [phi:frame_draw::@6->frame_draw::@7]
    // frame_draw::@7
    // frame(8, 2, 19, 14)
    // [342] call frame
    // [683] phi from frame_draw::@7 to frame [phi:frame_draw::@7->frame]
    // [683] phi frame::y#0 = 2 [phi:frame_draw::@7->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [683] phi frame::y1#16 = $e [phi:frame_draw::@7->frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z frame.y1
    // [683] phi frame::x#0 = 8 [phi:frame_draw::@7->frame#2] -- vbuz1=vbuc1 
    lda #8
    sta.z frame.x
    // [683] phi frame::x1#16 = $13 [phi:frame_draw::@7->frame#3] -- vbuz1=vbuc1 
    lda #$13
    sta.z frame.x1
    jsr frame
    // [343] phi from frame_draw::@7 to frame_draw::@8 [phi:frame_draw::@7->frame_draw::@8]
    // frame_draw::@8
    // frame(19, 2, 25, 14)
    // [344] call frame
    // [683] phi from frame_draw::@8 to frame [phi:frame_draw::@8->frame]
    // [683] phi frame::y#0 = 2 [phi:frame_draw::@8->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [683] phi frame::y1#16 = $e [phi:frame_draw::@8->frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z frame.y1
    // [683] phi frame::x#0 = $13 [phi:frame_draw::@8->frame#2] -- vbuz1=vbuc1 
    lda #$13
    sta.z frame.x
    // [683] phi frame::x1#16 = $19 [phi:frame_draw::@8->frame#3] -- vbuz1=vbuc1 
    lda #$19
    sta.z frame.x1
    jsr frame
    // [345] phi from frame_draw::@8 to frame_draw::@9 [phi:frame_draw::@8->frame_draw::@9]
    // frame_draw::@9
    // frame(25, 2, 31, 14)
    // [346] call frame
    // [683] phi from frame_draw::@9 to frame [phi:frame_draw::@9->frame]
    // [683] phi frame::y#0 = 2 [phi:frame_draw::@9->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [683] phi frame::y1#16 = $e [phi:frame_draw::@9->frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z frame.y1
    // [683] phi frame::x#0 = $19 [phi:frame_draw::@9->frame#2] -- vbuz1=vbuc1 
    lda #$19
    sta.z frame.x
    // [683] phi frame::x1#16 = $1f [phi:frame_draw::@9->frame#3] -- vbuz1=vbuc1 
    lda #$1f
    sta.z frame.x1
    jsr frame
    // [347] phi from frame_draw::@9 to frame_draw::@10 [phi:frame_draw::@9->frame_draw::@10]
    // frame_draw::@10
    // frame(31, 2, 37, 14)
    // [348] call frame
    // [683] phi from frame_draw::@10 to frame [phi:frame_draw::@10->frame]
    // [683] phi frame::y#0 = 2 [phi:frame_draw::@10->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [683] phi frame::y1#16 = $e [phi:frame_draw::@10->frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z frame.y1
    // [683] phi frame::x#0 = $1f [phi:frame_draw::@10->frame#2] -- vbuz1=vbuc1 
    lda #$1f
    sta.z frame.x
    // [683] phi frame::x1#16 = $25 [phi:frame_draw::@10->frame#3] -- vbuz1=vbuc1 
    lda #$25
    sta.z frame.x1
    jsr frame
    // [349] phi from frame_draw::@10 to frame_draw::@11 [phi:frame_draw::@10->frame_draw::@11]
    // frame_draw::@11
    // frame(37, 2, 43, 14)
    // [350] call frame
    // [683] phi from frame_draw::@11 to frame [phi:frame_draw::@11->frame]
    // [683] phi frame::y#0 = 2 [phi:frame_draw::@11->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [683] phi frame::y1#16 = $e [phi:frame_draw::@11->frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z frame.y1
    // [683] phi frame::x#0 = $25 [phi:frame_draw::@11->frame#2] -- vbuz1=vbuc1 
    lda #$25
    sta.z frame.x
    // [683] phi frame::x1#16 = $2b [phi:frame_draw::@11->frame#3] -- vbuz1=vbuc1 
    lda #$2b
    sta.z frame.x1
    jsr frame
    // [351] phi from frame_draw::@11 to frame_draw::@12 [phi:frame_draw::@11->frame_draw::@12]
    // frame_draw::@12
    // frame(43, 2, 49, 14)
    // [352] call frame
    // [683] phi from frame_draw::@12 to frame [phi:frame_draw::@12->frame]
    // [683] phi frame::y#0 = 2 [phi:frame_draw::@12->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [683] phi frame::y1#16 = $e [phi:frame_draw::@12->frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z frame.y1
    // [683] phi frame::x#0 = $2b [phi:frame_draw::@12->frame#2] -- vbuz1=vbuc1 
    lda #$2b
    sta.z frame.x
    // [683] phi frame::x1#16 = $31 [phi:frame_draw::@12->frame#3] -- vbuz1=vbuc1 
    lda #$31
    sta.z frame.x1
    jsr frame
    // [353] phi from frame_draw::@12 to frame_draw::@13 [phi:frame_draw::@12->frame_draw::@13]
    // frame_draw::@13
    // frame(49, 2, 55, 14)
    // [354] call frame
    // [683] phi from frame_draw::@13 to frame [phi:frame_draw::@13->frame]
    // [683] phi frame::y#0 = 2 [phi:frame_draw::@13->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [683] phi frame::y1#16 = $e [phi:frame_draw::@13->frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z frame.y1
    // [683] phi frame::x#0 = $31 [phi:frame_draw::@13->frame#2] -- vbuz1=vbuc1 
    lda #$31
    sta.z frame.x
    // [683] phi frame::x1#16 = $37 [phi:frame_draw::@13->frame#3] -- vbuz1=vbuc1 
    lda #$37
    sta.z frame.x1
    jsr frame
    // [355] phi from frame_draw::@13 to frame_draw::@14 [phi:frame_draw::@13->frame_draw::@14]
    // frame_draw::@14
    // frame(55, 2, 61, 14)
    // [356] call frame
    // [683] phi from frame_draw::@14 to frame [phi:frame_draw::@14->frame]
    // [683] phi frame::y#0 = 2 [phi:frame_draw::@14->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [683] phi frame::y1#16 = $e [phi:frame_draw::@14->frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z frame.y1
    // [683] phi frame::x#0 = $37 [phi:frame_draw::@14->frame#2] -- vbuz1=vbuc1 
    lda #$37
    sta.z frame.x
    // [683] phi frame::x1#16 = $3d [phi:frame_draw::@14->frame#3] -- vbuz1=vbuc1 
    lda #$3d
    sta.z frame.x1
    jsr frame
    // [357] phi from frame_draw::@14 to frame_draw::@15 [phi:frame_draw::@14->frame_draw::@15]
    // frame_draw::@15
    // frame(61, 2, 67, 14)
    // [358] call frame
    // [683] phi from frame_draw::@15 to frame [phi:frame_draw::@15->frame]
    // [683] phi frame::y#0 = 2 [phi:frame_draw::@15->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [683] phi frame::y1#16 = $e [phi:frame_draw::@15->frame#1] -- vbuz1=vbuc1 
    lda #$e
    sta.z frame.y1
    // [683] phi frame::x#0 = $3d [phi:frame_draw::@15->frame#2] -- vbuz1=vbuc1 
    lda #$3d
    sta.z frame.x
    // [683] phi frame::x1#16 = $43 [phi:frame_draw::@15->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [359] phi from frame_draw::@15 to frame_draw::@16 [phi:frame_draw::@15->frame_draw::@16]
    // frame_draw::@16
    // frame(0, 14, 67, PROGRESS_Y-5)
    // [360] call frame
  // Progress area
    // [683] phi from frame_draw::@16 to frame [phi:frame_draw::@16->frame]
    // [683] phi frame::y#0 = $e [phi:frame_draw::@16->frame#0] -- vbuz1=vbuc1 
    lda #$e
    sta.z frame.y
    // [683] phi frame::y1#16 = PROGRESS_Y-5 [phi:frame_draw::@16->frame#1] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-5
    sta.z frame.y1
    // [683] phi frame::x#0 = 0 [phi:frame_draw::@16->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [683] phi frame::x1#16 = $43 [phi:frame_draw::@16->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [361] phi from frame_draw::@16 to frame_draw::@17 [phi:frame_draw::@16->frame_draw::@17]
    // frame_draw::@17
    // frame(0, PROGRESS_Y-5, 67, PROGRESS_Y-2)
    // [362] call frame
    // [683] phi from frame_draw::@17 to frame [phi:frame_draw::@17->frame]
    // [683] phi frame::y#0 = PROGRESS_Y-5 [phi:frame_draw::@17->frame#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-5
    sta.z frame.y
    // [683] phi frame::y1#16 = PROGRESS_Y-2 [phi:frame_draw::@17->frame#1] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-2
    sta.z frame.y1
    // [683] phi frame::x#0 = 0 [phi:frame_draw::@17->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [683] phi frame::x1#16 = $43 [phi:frame_draw::@17->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [363] phi from frame_draw::@17 to frame_draw::@18 [phi:frame_draw::@17->frame_draw::@18]
    // frame_draw::@18
    // frame(0, PROGRESS_Y-2, 67, 49)
    // [364] call frame
    // [683] phi from frame_draw::@18 to frame [phi:frame_draw::@18->frame]
    // [683] phi frame::y#0 = PROGRESS_Y-2 [phi:frame_draw::@18->frame#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-2
    sta.z frame.y
    // [683] phi frame::y1#16 = $31 [phi:frame_draw::@18->frame#1] -- vbuz1=vbuc1 
    lda #$31
    sta.z frame.y1
    // [683] phi frame::x#0 = 0 [phi:frame_draw::@18->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [683] phi frame::x1#16 = $43 [phi:frame_draw::@18->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [365] phi from frame_draw::@18 to frame_draw::@19 [phi:frame_draw::@18->frame_draw::@19]
    // frame_draw::@19
    // textcolor(WHITE)
    // [366] call textcolor
    // [268] phi from frame_draw::@19 to textcolor [phi:frame_draw::@19->textcolor]
    // [268] phi textcolor::color#16 = WHITE [phi:frame_draw::@19->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // frame_draw::@return
    // }
    // [367] return 
    rts
}
  // print_title
// void print_title(char *title_text)
print_title: {
    // gotoxy(2, 1)
    // [369] call gotoxy
    // [286] phi from print_title to gotoxy [phi:print_title->gotoxy]
    // [286] phi gotoxy::y#19 = 1 [phi:print_title->gotoxy#0] -- vbuz1=vbuc1 
    lda #1
    sta.z gotoxy.y
    // [286] phi gotoxy::x#19 = 2 [phi:print_title->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // [370] phi from print_title to print_title::@1 [phi:print_title->print_title::@1]
    // print_title::@1
    // printf("%-65s", title_text)
    // [371] call printf_string
    // [817] phi from print_title::@1 to printf_string [phi:print_title::@1->printf_string]
    // [817] phi printf_string::str#10 = main::title_text [phi:print_title::@1->printf_string#0] -- pbuz1=pbuc1 
    lda #<main.title_text
    sta.z printf_string.str
    lda #>main.title_text
    sta.z printf_string.str+1
    // [817] phi printf_string::format_min_length#10 = $41 [phi:print_title::@1->printf_string#1] -- vbuz1=vbuc1 
    lda #$41
    sta.z printf_string.format_min_length
    jsr printf_string
    // print_title::@return
    // }
    // [372] return 
    rts
}
  // cputsxy
// Move cursor and output a NUL-terminated string
// Same as "gotoxy (x, y); puts (s);"
// void cputsxy(__zp($49) char x, __zp($65) char y, __zp($47) const char *s)
cputsxy: {
    .label y = $65
    .label s = $47
    .label x = $49
    // gotoxy(x, y)
    // [374] gotoxy::x#1 = cputsxy::x#3 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [375] gotoxy::y#1 = cputsxy::y#3 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [376] call gotoxy
    // [286] phi from cputsxy to gotoxy [phi:cputsxy->gotoxy]
    // [286] phi gotoxy::y#19 = gotoxy::y#1 [phi:cputsxy->gotoxy#0] -- register_copy 
    // [286] phi gotoxy::x#19 = gotoxy::x#1 [phi:cputsxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputsxy::@1
    // cputs(s)
    // [377] cputs::s#1 = cputsxy::s#3 -- pbuz1=pbuz2 
    lda.z s
    sta.z cputs.s
    lda.z s+1
    sta.z cputs.s+1
    // [378] call cputs
    // [834] phi from cputsxy::@1 to cputs [phi:cputsxy::@1->cputs]
    jsr cputs
    // cputsxy::@return
    // }
    // [379] return 
    rts
}
  // progress_clear
/**
 * @brief Clean the progress area for the flashing.
 */
progress_clear: {
    .const h = PROGRESS_Y+PROGRESS_H
    .label x = $38
    .label i = $65
    .label y = $49
    // textcolor(WHITE)
    // [381] call textcolor
    // [268] phi from progress_clear to textcolor [phi:progress_clear->textcolor]
    // [268] phi textcolor::color#16 = WHITE [phi:progress_clear->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [382] phi from progress_clear to progress_clear::@5 [phi:progress_clear->progress_clear::@5]
    // progress_clear::@5
    // bgcolor(BLUE)
    // [383] call bgcolor
    // [273] phi from progress_clear::@5 to bgcolor [phi:progress_clear::@5->bgcolor]
    // [273] phi bgcolor::color#14 = BLUE [phi:progress_clear::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [384] phi from progress_clear::@5 to progress_clear::@1 [phi:progress_clear::@5->progress_clear::@1]
    // [384] phi progress_clear::y#2 = PROGRESS_Y [phi:progress_clear::@5->progress_clear::@1#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // progress_clear::@1
  __b1:
    // while (y < h)
    // [385] if(progress_clear::y#2<progress_clear::h) goto progress_clear::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y
    cmp #h
    bcc __b4
    // progress_clear::@return
    // }
    // [386] return 
    rts
    // [387] phi from progress_clear::@1 to progress_clear::@2 [phi:progress_clear::@1->progress_clear::@2]
  __b4:
    // [387] phi progress_clear::x#2 = PROGRESS_X [phi:progress_clear::@1->progress_clear::@2#0] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z x
    // [387] phi progress_clear::i#2 = 0 [phi:progress_clear::@1->progress_clear::@2#1] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // progress_clear::@2
  __b2:
    // for(unsigned char i = 0; i < w; i++)
    // [388] if(progress_clear::i#2<PROGRESS_W) goto progress_clear::@3 -- vbuz1_lt_vbuc1_then_la1 
    lda.z i
    cmp #PROGRESS_W
    bcc __b3
    // progress_clear::@4
    // y++;
    // [389] progress_clear::y#1 = ++ progress_clear::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [384] phi from progress_clear::@4 to progress_clear::@1 [phi:progress_clear::@4->progress_clear::@1]
    // [384] phi progress_clear::y#2 = progress_clear::y#1 [phi:progress_clear::@4->progress_clear::@1#0] -- register_copy 
    jmp __b1
    // progress_clear::@3
  __b3:
    // cputcxy(x, y, ' ')
    // [390] cputcxy::x#12 = progress_clear::x#2 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [391] cputcxy::y#12 = progress_clear::y#2 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [392] call cputcxy
    // [843] phi from progress_clear::@3 to cputcxy [phi:progress_clear::@3->cputcxy]
    // [843] phi cputcxy::c#13 = ' ' [phi:progress_clear::@3->cputcxy#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z cputcxy.c
    // [843] phi cputcxy::y#13 = cputcxy::y#12 [phi:progress_clear::@3->cputcxy#1] -- register_copy 
    // [843] phi cputcxy::x#13 = cputcxy::x#12 [phi:progress_clear::@3->cputcxy#2] -- register_copy 
    jsr cputcxy
    // progress_clear::@6
    // x++;
    // [393] progress_clear::x#1 = ++ progress_clear::x#2 -- vbuz1=_inc_vbuz1 
    inc.z x
    // for(unsigned char i = 0; i < w; i++)
    // [394] progress_clear::i#1 = ++ progress_clear::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [387] phi from progress_clear::@6 to progress_clear::@2 [phi:progress_clear::@6->progress_clear::@2]
    // [387] phi progress_clear::x#2 = progress_clear::x#1 [phi:progress_clear::@6->progress_clear::@2#0] -- register_copy 
    // [387] phi progress_clear::i#2 = progress_clear::i#1 [phi:progress_clear::@6->progress_clear::@2#1] -- register_copy 
    jmp __b2
}
  // info_progress
// void info_progress(__zp($4d) char *info_text)
info_progress: {
    .label x = $66
    .label y = $67
    .label info_text = $4d
    // unsigned char x = wherex()
    // [396] call wherex
    jsr wherex
    // [397] wherex::return#2 = wherex::return#0
    // info_progress::@1
    // [398] info_progress::x#0 = wherex::return#2
    // unsigned char y = wherey()
    // [399] call wherey
    jsr wherey
    // [400] wherey::return#2 = wherey::return#0
    // info_progress::@2
    // [401] info_progress::y#0 = wherey::return#2
    // gotoxy(2, PROGRESS_Y-4)
    // [402] call gotoxy
    // [286] phi from info_progress::@2 to gotoxy [phi:info_progress::@2->gotoxy]
    // [286] phi gotoxy::y#19 = PROGRESS_Y-4 [phi:info_progress::@2->gotoxy#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-4
    sta.z gotoxy.y
    // [286] phi gotoxy::x#19 = 2 [phi:info_progress::@2->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // info_progress::@3
    // printf("%-65s", info_text)
    // [403] printf_string::str#1 = info_progress::info_text#10
    // [404] call printf_string
    // [817] phi from info_progress::@3 to printf_string [phi:info_progress::@3->printf_string]
    // [817] phi printf_string::str#10 = printf_string::str#1 [phi:info_progress::@3->printf_string#0] -- register_copy 
    // [817] phi printf_string::format_min_length#10 = $41 [phi:info_progress::@3->printf_string#1] -- vbuz1=vbuc1 
    lda #$41
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_progress::@4
    // gotoxy(x, y)
    // [405] gotoxy::x#10 = info_progress::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [406] gotoxy::y#10 = info_progress::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [407] call gotoxy
    // [286] phi from info_progress::@4 to gotoxy [phi:info_progress::@4->gotoxy]
    // [286] phi gotoxy::y#19 = gotoxy::y#10 [phi:info_progress::@4->gotoxy#0] -- register_copy 
    // [286] phi gotoxy::x#19 = gotoxy::x#10 [phi:info_progress::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // info_progress::@return
    // }
    // [408] return 
    rts
}
  // chip_vera
chip_vera: {
    // print_vera_led(GREY)
    // [410] call print_vera_led
    // [855] phi from chip_vera to print_vera_led [phi:chip_vera->print_vera_led]
    // [855] phi print_vera_led::c#2 = GREY [phi:chip_vera->print_vera_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z print_vera_led.c
    jsr print_vera_led
    // [411] phi from chip_vera to chip_vera::@1 [phi:chip_vera->chip_vera::@1]
    // chip_vera::@1
    // print_chip(CHIP_VERA_X, CHIP_VERA_Y+2, CHIP_VERA_W, "VERA     ")
    // [412] call print_chip
    jsr print_chip
    // chip_vera::@return
    // }
    // [413] return 
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
// void info_vera(__zp($6c) char info_status, __zp($4a) char *info_text)
info_vera: {
    .label info_vera__8 = $6c
    .label x = $5b
    .label y = $7f
    .label info_status = $6c
    .label info_text = $4a
    // unsigned char x = wherex()
    // [415] call wherex
    jsr wherex
    // [416] wherex::return#11 = wherex::return#0 -- vbuz1=vbuz2 
    lda.z wherex.return
    sta.z wherex.return_3
    // info_vera::@3
    // [417] info_vera::x#0 = wherex::return#11
    // unsigned char y = wherey()
    // [418] call wherey
    jsr wherey
    // [419] wherey::return#11 = wherey::return#0 -- vbuz1=vbuz2 
    lda.z wherey.return
    sta.z wherey.return_3
    // info_vera::@4
    // [420] info_vera::y#0 = wherey::return#11
    // status_vera = info_status
    // [421] status_vera#0 = info_vera::info_status#2 -- vbuz1=vbuz2 
    lda.z info_status
    sta.z status_vera
    // print_vera_led(status_color[info_status])
    // [422] print_vera_led::c#1 = status_color[info_vera::info_status#2] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z print_vera_led.c
    // [423] call print_vera_led
    // [855] phi from info_vera::@4 to print_vera_led [phi:info_vera::@4->print_vera_led]
    // [855] phi print_vera_led::c#2 = print_vera_led::c#1 [phi:info_vera::@4->print_vera_led#0] -- register_copy 
    jsr print_vera_led
    // [424] phi from info_vera::@4 to info_vera::@5 [phi:info_vera::@4->info_vera::@5]
    // info_vera::@5
    // gotoxy(INFO_X, INFO_Y+1)
    // [425] call gotoxy
    // [286] phi from info_vera::@5 to gotoxy [phi:info_vera::@5->gotoxy]
    // [286] phi gotoxy::y#19 = $11+1 [phi:info_vera::@5->gotoxy#0] -- vbuz1=vbuc1 
    lda #$11+1
    sta.z gotoxy.y
    // [286] phi gotoxy::x#19 = 4 [phi:info_vera::@5->gotoxy#1] -- vbuz1=vbuc1 
    lda #4
    sta.z gotoxy.x
    jsr gotoxy
    // [426] phi from info_vera::@5 to info_vera::@6 [phi:info_vera::@5->info_vera::@6]
    // info_vera::@6
    // printf("VERA %-9s FPGA   1a000 / 1a000 ", status_text[info_status])
    // [427] call printf_str
    // [511] phi from info_vera::@6 to printf_str [phi:info_vera::@6->printf_str]
    // [511] phi printf_str::putc#17 = &cputc [phi:info_vera::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [511] phi printf_str::s#17 = info_vera::s [phi:info_vera::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // info_vera::@7
    // printf("VERA %-9s FPGA   1a000 / 1a000 ", status_text[info_status])
    // [428] info_vera::$8 = info_vera::info_status#2 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z info_vera__8
    // [429] printf_string::str#5 = status_text[info_vera::$8] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z info_vera__8
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [430] call printf_string
    // [817] phi from info_vera::@7 to printf_string [phi:info_vera::@7->printf_string]
    // [817] phi printf_string::str#10 = printf_string::str#5 [phi:info_vera::@7->printf_string#0] -- register_copy 
    // [817] phi printf_string::format_min_length#10 = 9 [phi:info_vera::@7->printf_string#1] -- vbuz1=vbuc1 
    lda #9
    sta.z printf_string.format_min_length
    jsr printf_string
    // [431] phi from info_vera::@7 to info_vera::@8 [phi:info_vera::@7->info_vera::@8]
    // info_vera::@8
    // printf("VERA %-9s FPGA   1a000 / 1a000 ", status_text[info_status])
    // [432] call printf_str
    // [511] phi from info_vera::@8 to printf_str [phi:info_vera::@8->printf_str]
    // [511] phi printf_str::putc#17 = &cputc [phi:info_vera::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [511] phi printf_str::s#17 = info_vera::s1 [phi:info_vera::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_vera::@9
    // if(info_text)
    // [433] if((char *)0==info_vera::info_text#10) goto info_vera::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // info_vera::@2
    // printf("%-20s", info_text)
    // [434] printf_string::str#6 = info_vera::info_text#10 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [435] call printf_string
    // [817] phi from info_vera::@2 to printf_string [phi:info_vera::@2->printf_string]
    // [817] phi printf_string::str#10 = printf_string::str#6 [phi:info_vera::@2->printf_string#0] -- register_copy 
    // [817] phi printf_string::format_min_length#10 = $14 [phi:info_vera::@2->printf_string#1] -- vbuz1=vbuc1 
    lda #$14
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_vera::@1
  __b1:
    // gotoxy(x, y)
    // [436] gotoxy::x#16 = info_vera::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [437] gotoxy::y#16 = info_vera::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [438] call gotoxy
    // [286] phi from info_vera::@1 to gotoxy [phi:info_vera::@1->gotoxy]
    // [286] phi gotoxy::y#19 = gotoxy::y#16 [phi:info_vera::@1->gotoxy#0] -- register_copy 
    // [286] phi gotoxy::x#19 = gotoxy::x#16 [phi:info_vera::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // info_vera::@return
    // }
    // [439] return 
    rts
  .segment Data
    s: .text "VERA "
    .byte 0
    s1: .text " FPGA   1a000 / 1a000 "
    .byte 0
}
.segment Code
  // wait_key
// __zp($6c) char wait_key(__zp($5e) char *info_text, __zp($56) char *filter)
wait_key: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    .label wait_key__9 = $4d
    .label bram = $66
    .label bank_get_brom1_return = $67
    .label return = $6c
    .label info_text = $5e
    .label ch = $4a
    .label filter = $56
    // info_line(info_text)
    // [441] info_line::info_text#0 = wait_key::info_text#4
    // [442] call info_line
    // [528] phi from wait_key to info_line [phi:wait_key->info_line]
    // [528] phi info_line::info_text#4 = info_line::info_text#0 [phi:wait_key->info_line#0] -- register_copy 
    jsr info_line
    // wait_key::bank_get_bram1
    // return BRAM;
    // [443] wait_key::bram#0 = BRAM -- vbuz1=vbuz2 
    lda.z BRAM
    sta.z bram
    // wait_key::bank_get_brom1
    // return BROM;
    // [444] wait_key::bank_get_brom1_return#0 = BROM -- vbuz1=vbuz2 
    lda.z BROM
    sta.z bank_get_brom1_return
    // wait_key::bank_set_bram1
    // BRAM = bank
    // [445] BRAM = wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // wait_key::bank_set_brom1
    // BROM = bank
    // [446] BROM = wait_key::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [447] phi from wait_key::@2 wait_key::@5 wait_key::bank_set_brom1 to wait_key::kbhit1 [phi:wait_key::@2/wait_key::@5/wait_key::bank_set_brom1->wait_key::kbhit1]
    // wait_key::kbhit1
  kbhit1:
    // wait_key::kbhit1_cbm_k_clrchn1
    // asm
    // asm { jsrCBM_CLRCHN  }
    jsr CBM_CLRCHN
    // [449] phi from wait_key::kbhit1_cbm_k_clrchn1 to wait_key::kbhit1_@2 [phi:wait_key::kbhit1_cbm_k_clrchn1->wait_key::kbhit1_@2]
    // wait_key::kbhit1_@2
    // cbm_k_getin()
    // [450] call cbm_k_getin
    jsr cbm_k_getin
    // [451] cbm_k_getin::return#2 = cbm_k_getin::return#1
    // wait_key::@4
    // [452] wait_key::ch#4 = cbm_k_getin::return#2 -- vwuz1=vbuz2 
    lda.z cbm_k_getin.return
    sta.z ch
    lda #0
    sta.z ch+1
    // wait_key::@3
    // if (filter)
    // [453] if((char *)0!=wait_key::filter#14) goto wait_key::@1 -- pbuc1_neq_pbuz1_then_la1 
    // if there is a filter, check the filter, otherwise return ch.
    lda.z filter+1
    cmp #>0
    bne __b1
    lda.z filter
    cmp #<0
    bne __b1
    // wait_key::@2
    // if(ch)
    // [454] if(0!=wait_key::ch#4) goto wait_key::bank_set_bram2 -- 0_neq_vwuz1_then_la1 
    lda.z ch
    ora.z ch+1
    bne bank_set_bram2
    jmp kbhit1
    // wait_key::bank_set_bram2
  bank_set_bram2:
    // BRAM = bank
    // [455] BRAM = wait_key::bram#0 -- vbuz1=vbuz2 
    lda.z bram
    sta.z BRAM
    // wait_key::bank_set_brom2
    // BROM = bank
    // [456] BROM = wait_key::bank_get_brom1_return#0 -- vbuz1=vbuz2 
    lda.z bank_get_brom1_return
    sta.z BROM
    // wait_key::@return
    // }
    // [457] return 
    rts
    // wait_key::@1
  __b1:
    // strchr(filter, ch)
    // [458] strchr::str#0 = (const void *)wait_key::filter#14 -- pvoz1=pvoz2 
    lda.z filter
    sta.z strchr.str
    lda.z filter+1
    sta.z strchr.str+1
    // [459] strchr::c#0 = wait_key::ch#4 -- vbuz1=vwuz2 
    lda.z ch
    sta.z strchr.c
    // [460] call strchr
    // [542] phi from wait_key::@1 to strchr [phi:wait_key::@1->strchr]
    // [542] phi strchr::c#4 = strchr::c#0 [phi:wait_key::@1->strchr#0] -- register_copy 
    // [542] phi strchr::str#2 = strchr::str#0 [phi:wait_key::@1->strchr#1] -- register_copy 
    jsr strchr
    // strchr(filter, ch)
    // [461] strchr::return#3 = strchr::return#2
    // wait_key::@5
    // [462] wait_key::$9 = strchr::return#3
    // if(strchr(filter, ch) != NULL)
    // [463] if(wait_key::$9!=0) goto wait_key::bank_set_bram2 -- pvoz1_neq_0_then_la1 
    lda.z wait_key__9
    ora.z wait_key__9+1
    bne bank_set_bram2
    jmp kbhit1
}
  // info_smc
/**
 * @brief Print the SMC status.
 * 
 * @param status The STATUS_ 
 * 
 * @remark The smc_booloader is a global variable. 
 */
// void info_smc(__zp($77) char info_status, __zp($58) char *info_text)
info_smc: {
    .label info_smc__8 = $77
    .label x = $a9
    .label y = $72
    .label info_status = $77
    .label info_text = $58
    // unsigned char x = wherex()
    // [465] call wherex
    jsr wherex
    // [466] wherex::return#10 = wherex::return#0 -- vbuz1=vbuz2 
    lda.z wherex.return
    sta.z wherex.return_2
    // info_smc::@3
    // [467] info_smc::x#0 = wherex::return#10
    // unsigned char y = wherey()
    // [468] call wherey
    jsr wherey
    // [469] wherey::return#10 = wherey::return#0 -- vbuz1=vbuz2 
    lda.z wherey.return
    sta.z wherey.return_2
    // info_smc::@4
    // [470] info_smc::y#0 = wherey::return#10
    // status_smc = info_status
    // [471] status_smc#0 = info_smc::info_status#2 -- vbuz1=vbuz2 
    lda.z info_status
    sta.z status_smc
    // print_smc_led(status_color[info_status])
    // [472] print_smc_led::c#0 = status_color[info_smc::info_status#2] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z print_smc_led.c
    // [473] call print_smc_led
    jsr print_smc_led
    // [474] phi from info_smc::@4 to info_smc::@5 [phi:info_smc::@4->info_smc::@5]
    // info_smc::@5
    // gotoxy(INFO_X, INFO_Y)
    // [475] call gotoxy
    // [286] phi from info_smc::@5 to gotoxy [phi:info_smc::@5->gotoxy]
    // [286] phi gotoxy::y#19 = $11 [phi:info_smc::@5->gotoxy#0] -- vbuz1=vbuc1 
    lda #$11
    sta.z gotoxy.y
    // [286] phi gotoxy::x#19 = 4 [phi:info_smc::@5->gotoxy#1] -- vbuz1=vbuc1 
    lda #4
    sta.z gotoxy.x
    jsr gotoxy
    // [476] phi from info_smc::@5 to info_smc::@6 [phi:info_smc::@5->info_smc::@6]
    // info_smc::@6
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [477] call printf_str
    // [511] phi from info_smc::@6 to printf_str [phi:info_smc::@6->printf_str]
    // [511] phi printf_str::putc#17 = &cputc [phi:info_smc::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [511] phi printf_str::s#17 = info_smc::s [phi:info_smc::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // info_smc::@7
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [478] info_smc::$8 = info_smc::info_status#2 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z info_smc__8
    // [479] printf_string::str#3 = status_text[info_smc::$8] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z info_smc__8
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [480] call printf_string
    // [817] phi from info_smc::@7 to printf_string [phi:info_smc::@7->printf_string]
    // [817] phi printf_string::str#10 = printf_string::str#3 [phi:info_smc::@7->printf_string#0] -- register_copy 
    // [817] phi printf_string::format_min_length#10 = 9 [phi:info_smc::@7->printf_string#1] -- vbuz1=vbuc1 
    lda #9
    sta.z printf_string.format_min_length
    jsr printf_string
    // [481] phi from info_smc::@7 to info_smc::@8 [phi:info_smc::@7->info_smc::@8]
    // info_smc::@8
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [482] call printf_str
    // [511] phi from info_smc::@8 to printf_str [phi:info_smc::@8->printf_str]
    // [511] phi printf_str::putc#17 = &cputc [phi:info_smc::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [511] phi printf_str::s#17 = info_smc::s1 [phi:info_smc::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // [483] phi from info_smc::@8 to info_smc::@9 [phi:info_smc::@8->info_smc::@9]
    // info_smc::@9
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [484] call printf_uint
    // [890] phi from info_smc::@9 to printf_uint [phi:info_smc::@9->printf_uint]
    jsr printf_uint
    // [485] phi from info_smc::@9 to info_smc::@10 [phi:info_smc::@9->info_smc::@10]
    // info_smc::@10
    // printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size)
    // [486] call printf_str
    // [511] phi from info_smc::@10 to printf_str [phi:info_smc::@10->printf_str]
    // [511] phi printf_str::putc#17 = &cputc [phi:info_smc::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [511] phi printf_str::s#17 = info_smc::s2 [phi:info_smc::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // info_smc::@11
    // if(info_text)
    // [487] if((char *)0==info_smc::info_text#10) goto info_smc::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // info_smc::@2
    // printf("%-20s", info_text)
    // [488] printf_string::str#4 = info_smc::info_text#10 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [489] call printf_string
    // [817] phi from info_smc::@2 to printf_string [phi:info_smc::@2->printf_string]
    // [817] phi printf_string::str#10 = printf_string::str#4 [phi:info_smc::@2->printf_string#0] -- register_copy 
    // [817] phi printf_string::format_min_length#10 = $14 [phi:info_smc::@2->printf_string#1] -- vbuz1=vbuc1 
    lda #$14
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_smc::@1
  __b1:
    // gotoxy(x, y)
    // [490] gotoxy::x#14 = info_smc::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [491] gotoxy::y#14 = info_smc::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [492] call gotoxy
    // [286] phi from info_smc::@1 to gotoxy [phi:info_smc::@1->gotoxy]
    // [286] phi gotoxy::y#19 = gotoxy::y#14 [phi:info_smc::@1->gotoxy#0] -- register_copy 
    // [286] phi gotoxy::x#19 = gotoxy::x#14 [phi:info_smc::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // info_smc::@return
    // }
    // [493] return 
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
  // info_cx16_rom
// void info_cx16_rom(char info_status, char *info_text)
info_cx16_rom: {
    .label info_text = 0
    // info_rom(0, info_status, info_text)
    // [495] call info_rom
    // [551] phi from info_cx16_rom to info_rom [phi:info_cx16_rom->info_rom]
    // [551] phi info_rom::info_text#10 = info_cx16_rom::info_text#0 [phi:info_cx16_rom->info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_rom.info_text
    lda #>info_text
    sta.z info_rom.info_text+1
    // [551] phi info_rom::rom_chip#10 = 0 [phi:info_cx16_rom->info_rom#1] -- vbuz1=vbuc1 
    lda #0
    sta.z info_rom.rom_chip
    // [551] phi info_rom::info_status#2 = STATUS_ISSUE [phi:info_cx16_rom->info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z info_rom.info_status
    jsr info_rom
    // info_cx16_rom::@return
    // }
    // [496] return 
    rts
}
  // system_reset
system_reset: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    // system_reset::bank_set_bram1
    // BRAM = bank
    // [498] BRAM = system_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // system_reset::bank_set_brom1
    // BROM = bank
    // [499] BROM = system_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // system_reset::@1
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // system_reset::@return
    // }
    // [501] return 
}
  // wait_moment
wait_moment: {
    .label i = $47
    // [503] phi from wait_moment to wait_moment::@1 [phi:wait_moment->wait_moment::@1]
    // [503] phi wait_moment::i#2 = $ffff [phi:wait_moment->wait_moment::@1#0] -- vwuz1=vwuc1 
    lda #<$ffff
    sta.z i
    lda #>$ffff
    sta.z i+1
    // wait_moment::@1
  __b1:
    // for(unsigned int i=65535; i>0; i--)
    // [504] if(wait_moment::i#2>0) goto wait_moment::@2 -- vwuz1_gt_0_then_la1 
    lda.z i+1
    bne __b2
    lda.z i
    bne __b2
  !:
    // wait_moment::@return
    // }
    // [505] return 
    rts
    // wait_moment::@2
  __b2:
    // for(unsigned int i=65535; i>0; i--)
    // [506] wait_moment::i#1 = -- wait_moment::i#2 -- vwuz1=_dec_vwuz1 
    lda.z i
    bne !+
    dec.z i+1
  !:
    dec.z i
    // [503] phi from wait_moment::@2 to wait_moment::@1 [phi:wait_moment::@2->wait_moment::@1]
    // [503] phi wait_moment::i#2 = wait_moment::i#1 [phi:wait_moment::@2->wait_moment::@1#0] -- register_copy 
    jmp __b1
}
  // snprintf_init
/// Initialize the snprintf() state
// void snprintf_init(char *s, unsigned int n)
snprintf_init: {
    .const n = $ffff
    // __snprintf_capacity = n
    // [507] __snprintf_capacity = snprintf_init::n#0 -- vwum1=vwuc1 
    lda #<n
    sta __snprintf_capacity
    lda #>n
    sta __snprintf_capacity+1
    // __snprintf_size = 0
    // [508] __snprintf_size = 0 -- vwum1=vbuc1 
    lda #<0
    sta __snprintf_size
    sta __snprintf_size+1
    // __snprintf_buffer = s
    // [509] __snprintf_buffer = info_text -- pbuz1=pbuc1 
    lda #<info_text
    sta.z __snprintf_buffer
    lda #>info_text
    sta.z __snprintf_buffer+1
    // snprintf_init::@return
    // }
    // [510] return 
    rts
}
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($52) void (*putc)(char), __zp($4d) const char *s)
printf_str: {
    .label c = $54
    .label s = $4d
    .label putc = $52
    // [512] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [512] phi printf_str::s#16 = printf_str::s#17 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [513] printf_str::c#1 = *printf_str::s#16 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta.z c
    // [514] printf_str::s#0 = ++ printf_str::s#16 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [515] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // printf_str::@return
    // }
    // [516] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [517] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [518] callexecute *printf_str::putc#17  -- call__deref_pprz1 
    jsr icall2
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
    // Outside Flow
  icall2:
    jmp (putc)
}
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(__zp($5e) void (*putc)(char), __zp($38) char uvalue, char format_min_length, char format_justify_left, char format_sign_always, char format_zero_padding, char format_upper_case, char format_radix)
printf_uchar: {
    .label uvalue = $38
    .label putc = $5e
    // printf_uchar::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [521] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [522] uctoa::value#1 = printf_uchar::uvalue#2
    // [523] call uctoa
  // Format number into buffer
    // [896] phi from printf_uchar::@1 to uctoa [phi:printf_uchar::@1->uctoa]
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [524] printf_number_buffer::putc#2 = printf_uchar::putc#2
    // [525] printf_number_buffer::buffer_sign#2 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [526] call printf_number_buffer
  // Print using format
    // [915] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [915] phi printf_number_buffer::format_upper_case#10 = 0 [phi:printf_uchar::@2->printf_number_buffer#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_number_buffer.format_upper_case
    // [915] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#2 [phi:printf_uchar::@2->printf_number_buffer#1] -- register_copy 
    // [915] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#2 [phi:printf_uchar::@2->printf_number_buffer#2] -- register_copy 
    // [915] phi printf_number_buffer::format_zero_padding#10 = 0 [phi:printf_uchar::@2->printf_number_buffer#3] -- vbuz1=vbuc1 
    sta.z printf_number_buffer.format_zero_padding
    // [915] phi printf_number_buffer::format_justify_left#10 = 0 [phi:printf_uchar::@2->printf_number_buffer#4] -- vbuz1=vbuc1 
    sta.z printf_number_buffer.format_justify_left
    // [915] phi printf_number_buffer::format_min_length#3 = 0 [phi:printf_uchar::@2->printf_number_buffer#5] -- vbuz1=vbuc1 
    sta.z printf_number_buffer.format_min_length
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [527] return 
    rts
}
  // info_line
// void info_line(__zp($5e) char *info_text)
info_line: {
    .label info_text = $5e
    .label x = $71
    .label y = $60
    // unsigned char x = wherex()
    // [529] call wherex
    jsr wherex
    // [530] wherex::return#3 = wherex::return#0 -- vbuz1=vbuz2 
    lda.z wherex.return
    sta.z wherex.return_1
    // info_line::@1
    // [531] info_line::x#0 = wherex::return#3
    // unsigned char y = wherey()
    // [532] call wherey
    jsr wherey
    // [533] wherey::return#3 = wherey::return#0 -- vbuz1=vbuz2 
    lda.z wherey.return
    sta.z wherey.return_1
    // info_line::@2
    // [534] info_line::y#0 = wherey::return#3
    // gotoxy(2, PROGRESS_Y-3)
    // [535] call gotoxy
    // [286] phi from info_line::@2 to gotoxy [phi:info_line::@2->gotoxy]
    // [286] phi gotoxy::y#19 = PROGRESS_Y-3 [phi:info_line::@2->gotoxy#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y-3
    sta.z gotoxy.y
    // [286] phi gotoxy::x#19 = 2 [phi:info_line::@2->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // info_line::@3
    // printf("%-65s", info_text)
    // [536] printf_string::str#2 = info_line::info_text#4 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [537] call printf_string
    // [817] phi from info_line::@3 to printf_string [phi:info_line::@3->printf_string]
    // [817] phi printf_string::str#10 = printf_string::str#2 [phi:info_line::@3->printf_string#0] -- register_copy 
    // [817] phi printf_string::format_min_length#10 = $41 [phi:info_line::@3->printf_string#1] -- vbuz1=vbuc1 
    lda #$41
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_line::@4
    // gotoxy(x, y)
    // [538] gotoxy::x#12 = info_line::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [539] gotoxy::y#12 = info_line::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [540] call gotoxy
    // [286] phi from info_line::@4 to gotoxy [phi:info_line::@4->gotoxy]
    // [286] phi gotoxy::y#19 = gotoxy::y#12 [phi:info_line::@4->gotoxy#0] -- register_copy 
    // [286] phi gotoxy::x#19 = gotoxy::x#12 [phi:info_line::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // info_line::@return
    // }
    // [541] return 
    rts
}
  // strchr
// Searches for the first occurrence of the character c (an unsigned char) in the string pointed to, by the argument str.
// - str: The memory to search
// - c: A character to search for
// Return: A pointer to the matching byte or NULL if the character does not occur in the given memory area.
// __zp($4d) void * strchr(__zp($4d) const void *str, __zp($6c) char c)
strchr: {
    .label ptr = $4d
    .label return = $4d
    .label str = $4d
    .label c = $6c
    // [543] strchr::ptr#6 = (char *)strchr::str#2
    // [544] phi from strchr strchr::@3 to strchr::@1 [phi:strchr/strchr::@3->strchr::@1]
    // [544] phi strchr::ptr#2 = strchr::ptr#6 [phi:strchr/strchr::@3->strchr::@1#0] -- register_copy 
    // strchr::@1
  __b1:
    // while(*ptr)
    // [545] if(0!=*strchr::ptr#2) goto strchr::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (ptr),y
    cmp #0
    bne __b2
    // [546] phi from strchr::@1 to strchr::@return [phi:strchr::@1->strchr::@return]
    // [546] phi strchr::return#2 = (void *) 0 [phi:strchr::@1->strchr::@return#0] -- pvoz1=pvoc1 
    tya
    sta.z return
    sta.z return+1
    // strchr::@return
    // }
    // [547] return 
    rts
    // strchr::@2
  __b2:
    // if(*ptr==c)
    // [548] if(*strchr::ptr#2!=strchr::c#4) goto strchr::@3 -- _deref_pbuz1_neq_vbuz2_then_la1 
    ldy #0
    lda (ptr),y
    cmp.z c
    bne __b3
    // strchr::@4
    // [549] strchr::return#8 = (void *)strchr::ptr#2
    // [546] phi from strchr::@4 to strchr::@return [phi:strchr::@4->strchr::@return]
    // [546] phi strchr::return#2 = strchr::return#8 [phi:strchr::@4->strchr::@return#0] -- register_copy 
    rts
    // strchr::@3
  __b3:
    // ptr++;
    // [550] strchr::ptr#1 = ++ strchr::ptr#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr
    bne !+
    inc.z ptr+1
  !:
    jmp __b1
}
  // info_rom
// void info_rom(__zp($6b) char rom_chip, __zp($68) char info_status, __zp($4f) char *info_text)
info_rom: {
    .label info_rom__10 = $68
    .label info_rom__11 = $7f
    .label info_rom__13 = $7d
    .label x = $6a
    .label y = $69
    .label rom_chip = $6b
    .label info_status = $68
    .label info_text = $4f
    // unsigned char x = wherex()
    // [552] call wherex
    jsr wherex
    // [553] wherex::return#12 = wherex::return#0 -- vbuz1=vbuz2 
    lda.z wherex.return
    sta.z wherex.return_4
    // info_rom::@3
    // [554] info_rom::x#0 = wherex::return#12
    // unsigned char y = wherey()
    // [555] call wherey
    jsr wherey
    // [556] wherey::return#12 = wherey::return#0 -- vbuz1=vbuz2 
    lda.z wherey.return
    sta.z wherey.return_4
    // info_rom::@4
    // [557] info_rom::y#0 = wherey::return#12
    // status_rom[rom_chip] = info_status
    // [558] status_rom[info_rom::rom_chip#10] = info_rom::info_status#2 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z info_status
    ldy.z rom_chip
    sta status_rom,y
    // print_rom_led(rom_chip, status_color[info_status])
    // [559] print_rom_led::chip#0 = info_rom::rom_chip#10 -- vbuz1=vbuz2 
    tya
    sta.z print_rom_led.chip
    // [560] print_rom_led::c#0 = status_color[info_rom::info_status#2] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z print_rom_led.c
    // [561] call print_rom_led
    jsr print_rom_led
    // info_rom::@5
    // gotoxy(INFO_X, INFO_Y+rom_chip+2)
    // [562] gotoxy::y#17 = info_rom::rom_chip#10 + $11+2 -- vbuz1=vbuz2_plus_vbuc1 
    lda #$11+2
    clc
    adc.z rom_chip
    sta.z gotoxy.y
    // [563] call gotoxy
    // [286] phi from info_rom::@5 to gotoxy [phi:info_rom::@5->gotoxy]
    // [286] phi gotoxy::y#19 = gotoxy::y#17 [phi:info_rom::@5->gotoxy#0] -- register_copy 
    // [286] phi gotoxy::x#19 = 4 [phi:info_rom::@5->gotoxy#1] -- vbuz1=vbuc1 
    lda #4
    sta.z gotoxy.x
    jsr gotoxy
    // [564] phi from info_rom::@5 to info_rom::@6 [phi:info_rom::@5->info_rom::@6]
    // info_rom::@6
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [565] call printf_str
    // [511] phi from info_rom::@6 to printf_str [phi:info_rom::@6->printf_str]
    // [511] phi printf_str::putc#17 = &cputc [phi:info_rom::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [511] phi printf_str::s#17 = info_rom::s [phi:info_rom::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@7
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [566] printf_uchar::uvalue#0 = info_rom::rom_chip#10 -- vbuz1=vbuz2 
    lda.z rom_chip
    sta.z printf_uchar.uvalue
    // [567] call printf_uchar
    // [520] phi from info_rom::@7 to printf_uchar [phi:info_rom::@7->printf_uchar]
    // [520] phi printf_uchar::putc#2 = &cputc [phi:info_rom::@7->printf_uchar#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [520] phi printf_uchar::uvalue#2 = printf_uchar::uvalue#0 [phi:info_rom::@7->printf_uchar#1] -- register_copy 
    jsr printf_uchar
    // [568] phi from info_rom::@7 to info_rom::@8 [phi:info_rom::@7->info_rom::@8]
    // info_rom::@8
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [569] call printf_str
    // [511] phi from info_rom::@8 to printf_str [phi:info_rom::@8->printf_str]
    // [511] phi printf_str::putc#17 = &cputc [phi:info_rom::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [511] phi printf_str::s#17 = s1 [phi:info_rom::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@9
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [570] info_rom::$10 = info_rom::info_status#2 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z info_rom__10
    // [571] printf_string::str#7 = status_text[info_rom::$10] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z info_rom__10
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [572] call printf_string
    // [817] phi from info_rom::@9 to printf_string [phi:info_rom::@9->printf_string]
    // [817] phi printf_string::str#10 = printf_string::str#7 [phi:info_rom::@9->printf_string#0] -- register_copy 
    // [817] phi printf_string::format_min_length#10 = 9 [phi:info_rom::@9->printf_string#1] -- vbuz1=vbuc1 
    lda #9
    sta.z printf_string.format_min_length
    jsr printf_string
    // [573] phi from info_rom::@9 to info_rom::@10 [phi:info_rom::@9->info_rom::@10]
    // info_rom::@10
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [574] call printf_str
    // [511] phi from info_rom::@10 to printf_str [phi:info_rom::@10->printf_str]
    // [511] phi printf_str::putc#17 = &cputc [phi:info_rom::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [511] phi printf_str::s#17 = s1 [phi:info_rom::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@11
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [575] info_rom::$11 = info_rom::rom_chip#10 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta.z info_rom__11
    // [576] printf_string::str#8 = rom_device_names[info_rom::$11] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda rom_device_names,y
    sta.z printf_string.str
    lda rom_device_names+1,y
    sta.z printf_string.str+1
    // [577] call printf_string
    // [817] phi from info_rom::@11 to printf_string [phi:info_rom::@11->printf_string]
    // [817] phi printf_string::str#10 = printf_string::str#8 [phi:info_rom::@11->printf_string#0] -- register_copy 
    // [817] phi printf_string::format_min_length#10 = 6 [phi:info_rom::@11->printf_string#1] -- vbuz1=vbuc1 
    lda #6
    sta.z printf_string.format_min_length
    jsr printf_string
    // [578] phi from info_rom::@11 to info_rom::@12 [phi:info_rom::@11->info_rom::@12]
    // info_rom::@12
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [579] call printf_str
    // [511] phi from info_rom::@12 to printf_str [phi:info_rom::@12->printf_str]
    // [511] phi printf_str::putc#17 = &cputc [phi:info_rom::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [511] phi printf_str::s#17 = s1 [phi:info_rom::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@13
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [580] info_rom::$13 = info_rom::rom_chip#10 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta.z info_rom__13
    // [581] printf_ulong::uvalue#0 = file_sizes[info_rom::$13] -- vduz1=pduc1_derefidx_vbuz2 
    tay
    lda file_sizes,y
    sta.z printf_ulong.uvalue
    lda file_sizes+1,y
    sta.z printf_ulong.uvalue+1
    lda file_sizes+2,y
    sta.z printf_ulong.uvalue+2
    lda file_sizes+3,y
    sta.z printf_ulong.uvalue+3
    // [582] call printf_ulong
    // [967] phi from info_rom::@13 to printf_ulong [phi:info_rom::@13->printf_ulong]
    // [967] phi printf_ulong::uvalue#2 = printf_ulong::uvalue#0 [phi:info_rom::@13->printf_ulong#0] -- register_copy 
    jsr printf_ulong
    // [583] phi from info_rom::@13 to info_rom::@14 [phi:info_rom::@13->info_rom::@14]
    // info_rom::@14
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [584] call printf_str
    // [511] phi from info_rom::@14 to printf_str [phi:info_rom::@14->printf_str]
    // [511] phi printf_str::putc#17 = &cputc [phi:info_rom::@14->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [511] phi printf_str::s#17 = info_rom::s4 [phi:info_rom::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@15
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [585] printf_ulong::uvalue#1 = rom_sizes[info_rom::$13] -- vduz1=pduc1_derefidx_vbuz2 
    ldy.z info_rom__13
    lda rom_sizes,y
    sta.z printf_ulong.uvalue
    lda rom_sizes+1,y
    sta.z printf_ulong.uvalue+1
    lda rom_sizes+2,y
    sta.z printf_ulong.uvalue+2
    lda rom_sizes+3,y
    sta.z printf_ulong.uvalue+3
    // [586] call printf_ulong
    // [967] phi from info_rom::@15 to printf_ulong [phi:info_rom::@15->printf_ulong]
    // [967] phi printf_ulong::uvalue#2 = printf_ulong::uvalue#1 [phi:info_rom::@15->printf_ulong#0] -- register_copy 
    jsr printf_ulong
    // [587] phi from info_rom::@15 to info_rom::@16 [phi:info_rom::@15->info_rom::@16]
    // info_rom::@16
    // printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip])
    // [588] call printf_str
    // [511] phi from info_rom::@16 to printf_str [phi:info_rom::@16->printf_str]
    // [511] phi printf_str::putc#17 = &cputc [phi:info_rom::@16->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [511] phi printf_str::s#17 = s1 [phi:info_rom::@16->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@17
    // if(info_text)
    // [589] if((char *)0==info_rom::info_text#10) goto info_rom::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // info_rom::@2
    // printf("%-20s", info_text)
    // [590] printf_string::str#9 = info_rom::info_text#10 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [591] call printf_string
    // [817] phi from info_rom::@2 to printf_string [phi:info_rom::@2->printf_string]
    // [817] phi printf_string::str#10 = printf_string::str#9 [phi:info_rom::@2->printf_string#0] -- register_copy 
    // [817] phi printf_string::format_min_length#10 = $14 [phi:info_rom::@2->printf_string#1] -- vbuz1=vbuc1 
    lda #$14
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_rom::@1
  __b1:
    // gotoxy(x,y)
    // [592] gotoxy::x#18 = info_rom::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [593] gotoxy::y#18 = info_rom::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [594] call gotoxy
    // [286] phi from info_rom::@1 to gotoxy [phi:info_rom::@1->gotoxy]
    // [286] phi gotoxy::y#19 = gotoxy::y#18 [phi:info_rom::@1->gotoxy#0] -- register_copy 
    // [286] phi gotoxy::x#19 = gotoxy::x#18 [phi:info_rom::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // info_rom::@return
    // }
    // [595] return 
    rts
  .segment Data
    s: .text "ROM"
    .byte 0
    s4: .text " / "
    .byte 0
}
.segment Code
  // print_info_led
// void print_info_led(__zp($51) char x, __zp($4c) char y, __zp($3d) char tc, char bc)
print_info_led: {
    .label tc = $3d
    .label y = $4c
    .label x = $51
    // textcolor(tc)
    // [597] textcolor::color#13 = print_info_led::tc#4 -- vbuz1=vbuz2 
    lda.z tc
    sta.z textcolor.color
    // [598] call textcolor
    // [268] phi from print_info_led to textcolor [phi:print_info_led->textcolor]
    // [268] phi textcolor::color#16 = textcolor::color#13 [phi:print_info_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [599] phi from print_info_led to print_info_led::@1 [phi:print_info_led->print_info_led::@1]
    // print_info_led::@1
    // bgcolor(bc)
    // [600] call bgcolor
    // [273] phi from print_info_led::@1 to bgcolor [phi:print_info_led::@1->bgcolor]
    // [273] phi bgcolor::color#14 = BLUE [phi:print_info_led::@1->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_info_led::@2
    // cputcxy(x, y, VERA_CHR_UR)
    // [601] cputcxy::x#11 = print_info_led::x#4
    // [602] cputcxy::y#11 = print_info_led::y#4
    // [603] call cputcxy
    // [843] phi from print_info_led::@2 to cputcxy [phi:print_info_led::@2->cputcxy]
    // [843] phi cputcxy::c#13 = $7c [phi:print_info_led::@2->cputcxy#0] -- vbuz1=vbuc1 
    lda #$7c
    sta.z cputcxy.c
    // [843] phi cputcxy::y#13 = cputcxy::y#11 [phi:print_info_led::@2->cputcxy#1] -- register_copy 
    // [843] phi cputcxy::x#13 = cputcxy::x#11 [phi:print_info_led::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [604] phi from print_info_led::@2 to print_info_led::@3 [phi:print_info_led::@2->print_info_led::@3]
    // print_info_led::@3
    // textcolor(WHITE)
    // [605] call textcolor
    // [268] phi from print_info_led::@3 to textcolor [phi:print_info_led::@3->textcolor]
    // [268] phi textcolor::color#16 = WHITE [phi:print_info_led::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // print_info_led::@return
    // }
    // [606] return 
    rts
}
  // progress_text
// void progress_text(__zp($65) char line, __zp($47) char *text)
progress_text: {
    .label line = $65
    .label text = $47
    // cputsxy(PROGRESS_X, PROGRESS_Y+line, text)
    // [608] cputsxy::y#0 = PROGRESS_Y + progress_text::line#2 -- vbuz1=vbuc1_plus_vbuz1 
    lda #PROGRESS_Y
    clc
    adc.z cputsxy.y
    sta.z cputsxy.y
    // [609] cputsxy::s#0 = progress_text::text#2
    // [610] call cputsxy
    // [373] phi from progress_text to cputsxy [phi:progress_text->cputsxy]
    // [373] phi cputsxy::s#3 = cputsxy::s#0 [phi:progress_text->cputsxy#0] -- register_copy 
    // [373] phi cputsxy::y#3 = cputsxy::y#0 [phi:progress_text->cputsxy#1] -- register_copy 
    // [373] phi cputsxy::x#3 = PROGRESS_X [phi:progress_text->cputsxy#2] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z cputsxy.x
    jsr cputsxy
    // progress_text::@return
    // }
    // [611] return 
    rts
}
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __zp($63) char mapbase, __zp($62) char config)
screenlayer: {
    .label screenlayer__0 = $aa
    .label screenlayer__1 = $63
    .label screenlayer__2 = $ab
    .label screenlayer__5 = $62
    .label screenlayer__6 = $62
    .label screenlayer__7 = $7c
    .label screenlayer__8 = $7c
    .label screenlayer__9 = $79
    .label screenlayer__10 = $79
    .label screenlayer__11 = $79
    .label screenlayer__12 = $7a
    .label screenlayer__13 = $7a
    .label screenlayer__14 = $7a
    .label screenlayer__16 = $7c
    .label screenlayer__17 = $74
    .label screenlayer__18 = $79
    .label screenlayer__19 = $7a
    .label mapbase = $63
    .label config = $62
    .label mapbase_offset = $75
    .label y = $61
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [612] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [613] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [614] *((char *)&__conio+2) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+2
    // mapbase >> 7
    // [615] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbuz1=vbuz2_ror_7 
    lda.z mapbase
    rol
    rol
    and #1
    sta.z screenlayer__0
    // __conio.mapbase_bank = mapbase >> 7
    // [616] *((char *)&__conio+5) = screenlayer::$0 -- _deref_pbuc1=vbuz1 
    sta __conio+5
    // (mapbase)<<1
    // [617] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z screenlayer__1
    // MAKEWORD((mapbase)<<1,0)
    // [618] screenlayer::$2 = screenlayer::$1 w= 0 -- vwuz1=vbuz2_word_vbuc1 
    lda #0
    ldy.z screenlayer__1
    sty.z screenlayer__2+1
    sta.z screenlayer__2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [619] *((unsigned int *)&__conio+3) = screenlayer::$2 -- _deref_pwuc1=vwuz1 
    sta __conio+3
    tya
    sta __conio+3+1
    // config & VERA_LAYER_WIDTH_MASK
    // [620] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbuz1=vbuz2_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and.z config
    sta.z screenlayer__7
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [621] screenlayer::$8 = screenlayer::$7 >> 4 -- vbuz1=vbuz1_ror_4 
    lda.z screenlayer__8
    lsr
    lsr
    lsr
    lsr
    sta.z screenlayer__8
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [622] *((char *)&__conio+8) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+8
    // config & VERA_LAYER_HEIGHT_MASK
    // [623] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbuz1=vbuz1_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and.z screenlayer__5
    sta.z screenlayer__5
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [624] screenlayer::$6 = screenlayer::$5 >> 6 -- vbuz1=vbuz1_ror_6 
    lda.z screenlayer__6
    rol
    rol
    rol
    and #3
    sta.z screenlayer__6
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [625] *((char *)&__conio+9) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+9
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [626] screenlayer::$16 = screenlayer::$8 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z screenlayer__16
    // [627] *((unsigned int *)&__conio+$a) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    ldy.z screenlayer__16
    lda VERA_LAYER_SKIP,y
    sta __conio+$a
    lda VERA_LAYER_SKIP+1,y
    sta __conio+$a+1
    // vera_dc_hscale_temp == 0x80
    // [628] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z screenlayer__9
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [629] screenlayer::$18 = (char)screenlayer::$9
    // [630] screenlayer::$10 = $28 << screenlayer::$18 -- vbuz1=vbuc1_rol_vbuz1 
    lda #$28
    ldy.z screenlayer__10
    cpy #0
    beq !e+
  !:
    asl
    dey
    bne !-
  !e:
    sta.z screenlayer__10
    // (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [631] screenlayer::$11 = screenlayer::$10 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z screenlayer__11
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [632] *((char *)&__conio+6) = screenlayer::$11 -- _deref_pbuc1=vbuz1 
    lda.z screenlayer__11
    sta __conio+6
    // vera_dc_vscale_temp == 0x80
    // [633] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z screenlayer__12
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [634] screenlayer::$19 = (char)screenlayer::$12
    // [635] screenlayer::$13 = $1e << screenlayer::$19 -- vbuz1=vbuc1_rol_vbuz1 
    lda #$1e
    ldy.z screenlayer__13
    cpy #0
    beq !e+
  !:
    asl
    dey
    bne !-
  !e:
    sta.z screenlayer__13
    // (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [636] screenlayer::$14 = screenlayer::$13 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z screenlayer__14
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [637] *((char *)&__conio+7) = screenlayer::$14 -- _deref_pbuc1=vbuz1 
    lda.z screenlayer__14
    sta __conio+7
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [638] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+3) -- vwuz1=_deref_pwuc1 
    lda __conio+3
    sta.z mapbase_offset
    lda __conio+3+1
    sta.z mapbase_offset+1
    // [639] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [639] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [639] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [640] if(screenlayer::y#2<=*((char *)&__conio+7)) goto screenlayer::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+7
    cmp.z y
    bcs __b2
    // screenlayer::@return
    // }
    // [641] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [642] screenlayer::$17 = screenlayer::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z screenlayer__17
    // [643] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbuz1=vwuz2 
    tay
    lda.z mapbase_offset
    sta __conio+$15,y
    lda.z mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [644] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+$a) -- vwuz1=vwuz1_plus__deref_pwuc1 
    clc
    lda.z mapbase_offset
    adc __conio+$a
    sta.z mapbase_offset
    lda.z mapbase_offset+1
    adc __conio+$a+1
    sta.z mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [645] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [639] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [639] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [639] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
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
    // [646] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [647] if(0!=((char *)&__conio+$f)[*((char *)&__conio+2)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [648] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // [649] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [650] call gotoxy
    // [286] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [286] phi gotoxy::y#19 = 0 [phi:cscroll::@3->gotoxy#0] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.y
    // [286] phi gotoxy::x#19 = 0 [phi:cscroll::@3->gotoxy#1] -- vbuz1=vbuc1 
    sta.z gotoxy.x
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [651] return 
    rts
    // [652] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [653] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [654] gotoxy::y#3 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
    lda __conio+7
    sta.z gotoxy.y
    // [655] call gotoxy
    // [286] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [286] phi gotoxy::y#19 = gotoxy::y#3 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [286] phi gotoxy::x#19 = 0 [phi:cscroll::@5->gotoxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.x
    jsr gotoxy
    // [656] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [657] call clearline
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
    // [658] ((char *)&__conio+$f)[*((char *)&__conio+2)] = scroll::onoff#0 -- pbuc1_derefidx_(_deref_pbuc2)=vbuc3 
    lda #onoff
    ldy __conio+2
    sta __conio+$f,y
    // scroll::@return
    // }
    // [659] return 
    rts
}
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    .label clrscr__0 = $a9
    .label clrscr__1 = $72
    .label clrscr__2 = $71
    .label line_text = $4a
    .label l = $77
    .label ch = $4a
    .label c = $68
    // unsigned int line_text = __conio.mapbase_offset
    // [660] clrscr::line_text#0 = *((unsigned int *)&__conio+3) -- vwuz1=_deref_pwuc1 
    lda __conio+3
    sta.z line_text
    lda __conio+3+1
    sta.z line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [661] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [662] clrscr::$0 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clrscr__0
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [663] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [664] clrscr::l#0 = *((char *)&__conio+9) -- vbuz1=_deref_pbuc1 
    lda __conio+9
    sta.z l
    // [665] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [665] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [665] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [666] clrscr::$1 = byte0  clrscr::ch#0 -- vbuz1=_byte0_vwuz2 
    lda.z ch
    sta.z clrscr__1
    // *VERA_ADDRX_L = BYTE0(ch)
    // [667] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbuz1 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [668] clrscr::$2 = byte1  clrscr::ch#0 -- vbuz1=_byte1_vwuz2 
    lda.z ch+1
    sta.z clrscr__2
    // *VERA_ADDRX_M = BYTE1(ch)
    // [669] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth+1
    // [670] clrscr::c#0 = *((char *)&__conio+8) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+8
    inc
    sta.z c
    // [671] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [671] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [672] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [673] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [674] clrscr::c#1 = -- clrscr::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [675] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [676] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+$a) -- vwuz1=vwuz1_plus__deref_pwuc1 
    clc
    lda.z line_text
    adc __conio+$a
    sta.z line_text
    lda.z line_text+1
    adc __conio+$a+1
    sta.z line_text+1
    // l--;
    // [677] clrscr::l#1 = -- clrscr::l#4 -- vbuz1=_dec_vbuz1 
    dec.z l
    // while(l)
    // [678] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbuz1_then_la1 
    lda.z l
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [679] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y = 0
    // [680] *((char *)&__conio+1) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+1
    // __conio.offset = __conio.mapbase_offset
    // [681] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+3) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+3
    sta __conio+$13
    lda __conio+3+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [682] return 
    rts
}
  // frame
// Draw a line horizontal from a given xy position and a given length.
// The line should calculate the matching characters to draw and glue them.
// So it first needs to peek the characters at the given position.
// And then calculate the resulting characters to draw.
// void frame(char x0, char y0, __zp($6d) char x1, __zp($7b) char y1)
frame: {
    .label w = $3f
    .label h = $73
    .label x = $64
    .label y = $78
    .label mask = $65
    .label c = $55
    .label x_1 = $6e
    .label y_1 = $6f
    .label x1 = $6d
    .label y1 = $7b
    // unsigned char w = x1 - x0
    // [684] frame::w#0 = frame::x1#16 - frame::x#0 -- vbuz1=vbuz2_minus_vbuz3 
    lda.z x1
    sec
    sbc.z x
    sta.z w
    // unsigned char h = y1 - y0
    // [685] frame::h#0 = frame::y1#16 - frame::y#0 -- vbuz1=vbuz2_minus_vbuz3 
    lda.z y1
    sec
    sbc.z y
    sta.z h
    // unsigned char mask = frame_maskxy(x, y)
    // [686] frame_maskxy::x#0 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z frame_maskxy.x
    // [687] frame_maskxy::y#0 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z frame_maskxy.y
    // [688] call frame_maskxy
    // [1007] phi from frame to frame_maskxy [phi:frame->frame_maskxy]
    // [1007] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#0 [phi:frame->frame_maskxy#0] -- register_copy 
    // [1007] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#0 [phi:frame->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // unsigned char mask = frame_maskxy(x, y)
    // [689] frame_maskxy::return#13 = frame_maskxy::return#12
    // frame::@13
    // [690] frame::mask#0 = frame_maskxy::return#13
    // mask |= 0b0110
    // [691] frame::mask#1 = frame::mask#0 | 6 -- vbuz1=vbuz1_bor_vbuc1 
    lda #6
    ora.z mask
    sta.z mask
    // unsigned char c = frame_char(mask)
    // [692] frame_char::mask#0 = frame::mask#1
    // [693] call frame_char
  // Add a corner.
    // [1033] phi from frame::@13 to frame_char [phi:frame::@13->frame_char]
    // [1033] phi frame_char::mask#10 = frame_char::mask#0 [phi:frame::@13->frame_char#0] -- register_copy 
    jsr frame_char
    // unsigned char c = frame_char(mask)
    // [694] frame_char::return#13 = frame_char::return#12
    // frame::@14
    // [695] frame::c#0 = frame_char::return#13
    // cputcxy(x, y, c)
    // [696] cputcxy::x#0 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [697] cputcxy::y#0 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [698] cputcxy::c#0 = frame::c#0
    // [699] call cputcxy
    // [843] phi from frame::@14 to cputcxy [phi:frame::@14->cputcxy]
    // [843] phi cputcxy::c#13 = cputcxy::c#0 [phi:frame::@14->cputcxy#0] -- register_copy 
    // [843] phi cputcxy::y#13 = cputcxy::y#0 [phi:frame::@14->cputcxy#1] -- register_copy 
    // [843] phi cputcxy::x#13 = cputcxy::x#0 [phi:frame::@14->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@15
    // if(w>=2)
    // [700] if(frame::w#0<2) goto frame::@36 -- vbuz1_lt_vbuc1_then_la1 
    lda.z w
    cmp #2
    bcs !__b36+
    jmp __b36
  !__b36:
    // frame::@2
    // x++;
    // [701] frame::x#1 = ++ frame::x#0 -- vbuz1=_inc_vbuz2 
    lda.z x
    inc
    sta.z x_1
    // [702] phi from frame::@2 frame::@21 to frame::@4 [phi:frame::@2/frame::@21->frame::@4]
    // [702] phi frame::x#10 = frame::x#1 [phi:frame::@2/frame::@21->frame::@4#0] -- register_copy 
    // frame::@4
  __b4:
    // while(x < x1)
    // [703] if(frame::x#10<frame::x1#16) goto frame::@5 -- vbuz1_lt_vbuz2_then_la1 
    lda.z x_1
    cmp.z x1
    bcs !__b5+
    jmp __b5
  !__b5:
    // [704] phi from frame::@36 frame::@4 to frame::@1 [phi:frame::@36/frame::@4->frame::@1]
    // [704] phi frame::x#24 = frame::x#30 [phi:frame::@36/frame::@4->frame::@1#0] -- register_copy 
    // frame::@1
  __b1:
    // frame_maskxy(x, y)
    // [705] frame_maskxy::x#1 = frame::x#24 -- vbuz1=vbuz2 
    lda.z x_1
    sta.z frame_maskxy.x
    // [706] frame_maskxy::y#1 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z frame_maskxy.y
    // [707] call frame_maskxy
    // [1007] phi from frame::@1 to frame_maskxy [phi:frame::@1->frame_maskxy]
    // [1007] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#1 [phi:frame::@1->frame_maskxy#0] -- register_copy 
    // [1007] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#1 [phi:frame::@1->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [708] frame_maskxy::return#14 = frame_maskxy::return#12
    // frame::@16
    // mask = frame_maskxy(x, y)
    // [709] frame::mask#2 = frame_maskxy::return#14
    // mask |= 0b0011
    // [710] frame::mask#3 = frame::mask#2 | 3 -- vbuz1=vbuz1_bor_vbuc1 
    lda #3
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [711] frame_char::mask#1 = frame::mask#3
    // [712] call frame_char
    // [1033] phi from frame::@16 to frame_char [phi:frame::@16->frame_char]
    // [1033] phi frame_char::mask#10 = frame_char::mask#1 [phi:frame::@16->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [713] frame_char::return#14 = frame_char::return#12
    // frame::@17
    // c = frame_char(mask)
    // [714] frame::c#1 = frame_char::return#14
    // cputcxy(x, y, c)
    // [715] cputcxy::x#1 = frame::x#24 -- vbuz1=vbuz2 
    lda.z x_1
    sta.z cputcxy.x
    // [716] cputcxy::y#1 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [717] cputcxy::c#1 = frame::c#1
    // [718] call cputcxy
    // [843] phi from frame::@17 to cputcxy [phi:frame::@17->cputcxy]
    // [843] phi cputcxy::c#13 = cputcxy::c#1 [phi:frame::@17->cputcxy#0] -- register_copy 
    // [843] phi cputcxy::y#13 = cputcxy::y#1 [phi:frame::@17->cputcxy#1] -- register_copy 
    // [843] phi cputcxy::x#13 = cputcxy::x#1 [phi:frame::@17->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@18
    // if(h>=2)
    // [719] if(frame::h#0<2) goto frame::@return -- vbuz1_lt_vbuc1_then_la1 
    lda.z h
    cmp #2
    bcc __breturn
    // frame::@3
    // y++;
    // [720] frame::y#1 = ++ frame::y#0 -- vbuz1=_inc_vbuz2 
    lda.z y
    inc
    sta.z y_1
    // [721] phi from frame::@27 frame::@3 to frame::@6 [phi:frame::@27/frame::@3->frame::@6]
    // [721] phi frame::y#10 = frame::y#2 [phi:frame::@27/frame::@3->frame::@6#0] -- register_copy 
    // frame::@6
  __b6:
    // while(y < y1)
    // [722] if(frame::y#10<frame::y1#16) goto frame::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z y_1
    cmp.z y1
    bcc __b7
    // frame::@8
    // frame_maskxy(x, y)
    // [723] frame_maskxy::x#5 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z frame_maskxy.x
    // [724] frame_maskxy::y#5 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z frame_maskxy.y
    // [725] call frame_maskxy
    // [1007] phi from frame::@8 to frame_maskxy [phi:frame::@8->frame_maskxy]
    // [1007] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#5 [phi:frame::@8->frame_maskxy#0] -- register_copy 
    // [1007] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#5 [phi:frame::@8->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [726] frame_maskxy::return#18 = frame_maskxy::return#12
    // frame::@28
    // mask = frame_maskxy(x, y)
    // [727] frame::mask#10 = frame_maskxy::return#18
    // mask |= 0b1100
    // [728] frame::mask#11 = frame::mask#10 | $c -- vbuz1=vbuz1_bor_vbuc1 
    lda #$c
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [729] frame_char::mask#5 = frame::mask#11
    // [730] call frame_char
    // [1033] phi from frame::@28 to frame_char [phi:frame::@28->frame_char]
    // [1033] phi frame_char::mask#10 = frame_char::mask#5 [phi:frame::@28->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [731] frame_char::return#18 = frame_char::return#12
    // frame::@29
    // c = frame_char(mask)
    // [732] frame::c#5 = frame_char::return#18
    // cputcxy(x, y, c)
    // [733] cputcxy::x#5 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [734] cputcxy::y#5 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [735] cputcxy::c#5 = frame::c#5
    // [736] call cputcxy
    // [843] phi from frame::@29 to cputcxy [phi:frame::@29->cputcxy]
    // [843] phi cputcxy::c#13 = cputcxy::c#5 [phi:frame::@29->cputcxy#0] -- register_copy 
    // [843] phi cputcxy::y#13 = cputcxy::y#5 [phi:frame::@29->cputcxy#1] -- register_copy 
    // [843] phi cputcxy::x#13 = cputcxy::x#5 [phi:frame::@29->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@30
    // if(w>=2)
    // [737] if(frame::w#0<2) goto frame::@10 -- vbuz1_lt_vbuc1_then_la1 
    lda.z w
    cmp #2
    bcc __b10
    // frame::@9
    // x++;
    // [738] frame::x#4 = ++ frame::x#0 -- vbuz1=_inc_vbuz1 
    inc.z x
    // [739] phi from frame::@35 frame::@9 to frame::@11 [phi:frame::@35/frame::@9->frame::@11]
    // [739] phi frame::x#18 = frame::x#5 [phi:frame::@35/frame::@9->frame::@11#0] -- register_copy 
    // frame::@11
  __b11:
    // while(x < x1)
    // [740] if(frame::x#18<frame::x1#16) goto frame::@12 -- vbuz1_lt_vbuz2_then_la1 
    lda.z x
    cmp.z x1
    bcc __b12
    // [741] phi from frame::@11 frame::@30 to frame::@10 [phi:frame::@11/frame::@30->frame::@10]
    // [741] phi frame::x#15 = frame::x#18 [phi:frame::@11/frame::@30->frame::@10#0] -- register_copy 
    // frame::@10
  __b10:
    // frame_maskxy(x, y)
    // [742] frame_maskxy::x#6 = frame::x#15 -- vbuz1=vbuz2 
    lda.z x
    sta.z frame_maskxy.x
    // [743] frame_maskxy::y#6 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z frame_maskxy.y
    // [744] call frame_maskxy
    // [1007] phi from frame::@10 to frame_maskxy [phi:frame::@10->frame_maskxy]
    // [1007] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#6 [phi:frame::@10->frame_maskxy#0] -- register_copy 
    // [1007] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#6 [phi:frame::@10->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [745] frame_maskxy::return#19 = frame_maskxy::return#12
    // frame::@31
    // mask = frame_maskxy(x, y)
    // [746] frame::mask#12 = frame_maskxy::return#19
    // mask |= 0b1001
    // [747] frame::mask#13 = frame::mask#12 | 9 -- vbuz1=vbuz1_bor_vbuc1 
    lda #9
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [748] frame_char::mask#6 = frame::mask#13
    // [749] call frame_char
    // [1033] phi from frame::@31 to frame_char [phi:frame::@31->frame_char]
    // [1033] phi frame_char::mask#10 = frame_char::mask#6 [phi:frame::@31->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [750] frame_char::return#19 = frame_char::return#12
    // frame::@32
    // c = frame_char(mask)
    // [751] frame::c#6 = frame_char::return#19
    // cputcxy(x, y, c)
    // [752] cputcxy::x#6 = frame::x#15 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [753] cputcxy::y#6 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [754] cputcxy::c#6 = frame::c#6
    // [755] call cputcxy
    // [843] phi from frame::@32 to cputcxy [phi:frame::@32->cputcxy]
    // [843] phi cputcxy::c#13 = cputcxy::c#6 [phi:frame::@32->cputcxy#0] -- register_copy 
    // [843] phi cputcxy::y#13 = cputcxy::y#6 [phi:frame::@32->cputcxy#1] -- register_copy 
    // [843] phi cputcxy::x#13 = cputcxy::x#6 [phi:frame::@32->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@return
  __breturn:
    // }
    // [756] return 
    rts
    // frame::@12
  __b12:
    // frame_maskxy(x, y)
    // [757] frame_maskxy::x#7 = frame::x#18 -- vbuz1=vbuz2 
    lda.z x
    sta.z frame_maskxy.x
    // [758] frame_maskxy::y#7 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z frame_maskxy.y
    // [759] call frame_maskxy
    // [1007] phi from frame::@12 to frame_maskxy [phi:frame::@12->frame_maskxy]
    // [1007] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#7 [phi:frame::@12->frame_maskxy#0] -- register_copy 
    // [1007] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#7 [phi:frame::@12->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [760] frame_maskxy::return#20 = frame_maskxy::return#12
    // frame::@33
    // mask = frame_maskxy(x, y)
    // [761] frame::mask#14 = frame_maskxy::return#20
    // mask |= 0b0101
    // [762] frame::mask#15 = frame::mask#14 | 5 -- vbuz1=vbuz1_bor_vbuc1 
    lda #5
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [763] frame_char::mask#7 = frame::mask#15
    // [764] call frame_char
    // [1033] phi from frame::@33 to frame_char [phi:frame::@33->frame_char]
    // [1033] phi frame_char::mask#10 = frame_char::mask#7 [phi:frame::@33->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [765] frame_char::return#20 = frame_char::return#12
    // frame::@34
    // c = frame_char(mask)
    // [766] frame::c#7 = frame_char::return#20
    // cputcxy(x, y, c)
    // [767] cputcxy::x#7 = frame::x#18 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [768] cputcxy::y#7 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [769] cputcxy::c#7 = frame::c#7
    // [770] call cputcxy
    // [843] phi from frame::@34 to cputcxy [phi:frame::@34->cputcxy]
    // [843] phi cputcxy::c#13 = cputcxy::c#7 [phi:frame::@34->cputcxy#0] -- register_copy 
    // [843] phi cputcxy::y#13 = cputcxy::y#7 [phi:frame::@34->cputcxy#1] -- register_copy 
    // [843] phi cputcxy::x#13 = cputcxy::x#7 [phi:frame::@34->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@35
    // x++;
    // [771] frame::x#5 = ++ frame::x#18 -- vbuz1=_inc_vbuz1 
    inc.z x
    jmp __b11
    // frame::@7
  __b7:
    // frame_maskxy(x0, y)
    // [772] frame_maskxy::x#3 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z frame_maskxy.x
    // [773] frame_maskxy::y#3 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z frame_maskxy.y
    // [774] call frame_maskxy
    // [1007] phi from frame::@7 to frame_maskxy [phi:frame::@7->frame_maskxy]
    // [1007] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#3 [phi:frame::@7->frame_maskxy#0] -- register_copy 
    // [1007] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#3 [phi:frame::@7->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x0, y)
    // [775] frame_maskxy::return#16 = frame_maskxy::return#12
    // frame::@22
    // mask = frame_maskxy(x0, y)
    // [776] frame::mask#6 = frame_maskxy::return#16
    // mask |= 0b1010
    // [777] frame::mask#7 = frame::mask#6 | $a -- vbuz1=vbuz1_bor_vbuc1 
    lda #$a
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [778] frame_char::mask#3 = frame::mask#7
    // [779] call frame_char
    // [1033] phi from frame::@22 to frame_char [phi:frame::@22->frame_char]
    // [1033] phi frame_char::mask#10 = frame_char::mask#3 [phi:frame::@22->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [780] frame_char::return#16 = frame_char::return#12
    // frame::@23
    // c = frame_char(mask)
    // [781] frame::c#3 = frame_char::return#16
    // cputcxy(x0, y, c)
    // [782] cputcxy::x#3 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [783] cputcxy::y#3 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [784] cputcxy::c#3 = frame::c#3
    // [785] call cputcxy
    // [843] phi from frame::@23 to cputcxy [phi:frame::@23->cputcxy]
    // [843] phi cputcxy::c#13 = cputcxy::c#3 [phi:frame::@23->cputcxy#0] -- register_copy 
    // [843] phi cputcxy::y#13 = cputcxy::y#3 [phi:frame::@23->cputcxy#1] -- register_copy 
    // [843] phi cputcxy::x#13 = cputcxy::x#3 [phi:frame::@23->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@24
    // frame_maskxy(x1, y)
    // [786] frame_maskxy::x#4 = frame::x1#16 -- vbuz1=vbuz2 
    lda.z x1
    sta.z frame_maskxy.x
    // [787] frame_maskxy::y#4 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z frame_maskxy.y
    // [788] call frame_maskxy
    // [1007] phi from frame::@24 to frame_maskxy [phi:frame::@24->frame_maskxy]
    // [1007] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#4 [phi:frame::@24->frame_maskxy#0] -- register_copy 
    // [1007] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#4 [phi:frame::@24->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x1, y)
    // [789] frame_maskxy::return#17 = frame_maskxy::return#12
    // frame::@25
    // mask = frame_maskxy(x1, y)
    // [790] frame::mask#8 = frame_maskxy::return#17
    // mask |= 0b1010
    // [791] frame::mask#9 = frame::mask#8 | $a -- vbuz1=vbuz1_bor_vbuc1 
    lda #$a
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [792] frame_char::mask#4 = frame::mask#9
    // [793] call frame_char
    // [1033] phi from frame::@25 to frame_char [phi:frame::@25->frame_char]
    // [1033] phi frame_char::mask#10 = frame_char::mask#4 [phi:frame::@25->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [794] frame_char::return#17 = frame_char::return#12
    // frame::@26
    // c = frame_char(mask)
    // [795] frame::c#4 = frame_char::return#17
    // cputcxy(x1, y, c)
    // [796] cputcxy::x#4 = frame::x1#16 -- vbuz1=vbuz2 
    lda.z x1
    sta.z cputcxy.x
    // [797] cputcxy::y#4 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [798] cputcxy::c#4 = frame::c#4
    // [799] call cputcxy
    // [843] phi from frame::@26 to cputcxy [phi:frame::@26->cputcxy]
    // [843] phi cputcxy::c#13 = cputcxy::c#4 [phi:frame::@26->cputcxy#0] -- register_copy 
    // [843] phi cputcxy::y#13 = cputcxy::y#4 [phi:frame::@26->cputcxy#1] -- register_copy 
    // [843] phi cputcxy::x#13 = cputcxy::x#4 [phi:frame::@26->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@27
    // y++;
    // [800] frame::y#2 = ++ frame::y#10 -- vbuz1=_inc_vbuz1 
    inc.z y_1
    jmp __b6
    // frame::@5
  __b5:
    // frame_maskxy(x, y)
    // [801] frame_maskxy::x#2 = frame::x#10 -- vbuz1=vbuz2 
    lda.z x_1
    sta.z frame_maskxy.x
    // [802] frame_maskxy::y#2 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z frame_maskxy.y
    // [803] call frame_maskxy
    // [1007] phi from frame::@5 to frame_maskxy [phi:frame::@5->frame_maskxy]
    // [1007] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#2 [phi:frame::@5->frame_maskxy#0] -- register_copy 
    // [1007] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#2 [phi:frame::@5->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [804] frame_maskxy::return#15 = frame_maskxy::return#12
    // frame::@19
    // mask = frame_maskxy(x, y)
    // [805] frame::mask#4 = frame_maskxy::return#15
    // mask |= 0b0101
    // [806] frame::mask#5 = frame::mask#4 | 5 -- vbuz1=vbuz1_bor_vbuc1 
    lda #5
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [807] frame_char::mask#2 = frame::mask#5
    // [808] call frame_char
    // [1033] phi from frame::@19 to frame_char [phi:frame::@19->frame_char]
    // [1033] phi frame_char::mask#10 = frame_char::mask#2 [phi:frame::@19->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [809] frame_char::return#15 = frame_char::return#12
    // frame::@20
    // c = frame_char(mask)
    // [810] frame::c#2 = frame_char::return#15
    // cputcxy(x, y, c)
    // [811] cputcxy::x#2 = frame::x#10 -- vbuz1=vbuz2 
    lda.z x_1
    sta.z cputcxy.x
    // [812] cputcxy::y#2 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [813] cputcxy::c#2 = frame::c#2
    // [814] call cputcxy
    // [843] phi from frame::@20 to cputcxy [phi:frame::@20->cputcxy]
    // [843] phi cputcxy::c#13 = cputcxy::c#2 [phi:frame::@20->cputcxy#0] -- register_copy 
    // [843] phi cputcxy::y#13 = cputcxy::y#2 [phi:frame::@20->cputcxy#1] -- register_copy 
    // [843] phi cputcxy::x#13 = cputcxy::x#2 [phi:frame::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@21
    // x++;
    // [815] frame::x#2 = ++ frame::x#10 -- vbuz1=_inc_vbuz1 
    inc.z x_1
    jmp __b4
    // frame::@36
  __b36:
    // [816] frame::x#30 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z x_1
    jmp __b1
}
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(void (*putc)(char), __zp($4d) char *str, __zp($3d) char format_min_length, char format_justify_left)
printf_string: {
    .label printf_string__9 = $52
    .label len = $70
    .label padding = $3d
    .label str = $4d
    .label format_min_length = $3d
    // if(format.min_length)
    // [818] if(0==printf_string::format_min_length#10) goto printf_string::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b1
    // printf_string::@3
    // strlen(str)
    // [819] strlen::str#2 = printf_string::str#10 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [820] call strlen
    // [1048] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [1048] phi strlen::str#5 = strlen::str#2 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [821] strlen::return#3 = strlen::len#2
    // printf_string::@5
    // [822] printf_string::$9 = strlen::return#3
    // signed char len = (signed char)strlen(str)
    // [823] printf_string::len#0 = (signed char)printf_string::$9 -- vbsz1=_sbyte_vwuz2 
    lda.z printf_string__9
    sta.z len
    // padding = (signed char)format.min_length  - len
    // [824] printf_string::padding#1 = (signed char)printf_string::format_min_length#10 - printf_string::len#0 -- vbsz1=vbsz1_minus_vbsz2 
    lda.z padding
    sec
    sbc.z len
    sta.z padding
    // if(padding<0)
    // [825] if(printf_string::padding#1>=0) goto printf_string::@7 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b2
    // [827] phi from printf_string printf_string::@5 to printf_string::@1 [phi:printf_string/printf_string::@5->printf_string::@1]
  __b1:
    // [827] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@5->printf_string::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [826] phi from printf_string::@5 to printf_string::@7 [phi:printf_string::@5->printf_string::@7]
    // printf_string::@7
    // [827] phi from printf_string::@7 to printf_string::@1 [phi:printf_string::@7->printf_string::@1]
    // [827] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@7->printf_string::@1#0] -- register_copy 
    // printf_string::@1
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [828] printf_str::s#2 = printf_string::str#10
    // [829] call printf_str
    // [511] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [511] phi printf_str::putc#17 = &cputc [phi:printf_string::@2->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [511] phi printf_str::s#17 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@6
    // if(format.justify_left && padding)
    // [830] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b4
    rts
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [831] printf_padding::length#4 = (char)printf_string::padding#3
    // [832] call printf_padding
    // [1054] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [1054] phi printf_padding::putc#7 = &cputc [phi:printf_string::@4->printf_padding#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_padding.putc
    lda #>cputc
    sta.z printf_padding.putc+1
    // [1054] phi printf_padding::pad#7 = ' ' [phi:printf_string::@4->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1054] phi printf_padding::length#6 = printf_padding::length#4 [phi:printf_string::@4->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@return
    // }
    // [833] return 
    rts
}
  // cputs
// Output a NUL-terminated string at the current cursor position
// void cputs(__zp($52) const char *s)
cputs: {
    .label c = $60
    .label s = $52
    // [835] phi from cputs cputs::@2 to cputs::@1 [phi:cputs/cputs::@2->cputs::@1]
    // [835] phi cputs::s#2 = cputs::s#1 [phi:cputs/cputs::@2->cputs::@1#0] -- register_copy 
    // cputs::@1
  __b1:
    // while(c=*s++)
    // [836] cputs::c#1 = *cputs::s#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta.z c
    // [837] cputs::s#0 = ++ cputs::s#2 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [838] if(0!=cputs::c#1) goto cputs::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // cputs::@return
    // }
    // [839] return 
    rts
    // cputs::@2
  __b2:
    // cputc(c)
    // [840] stackpush(char) = cputs::c#1 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [841] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
}
  // cputcxy
// Move cursor and output one character
// Same as "gotoxy (x, y); cputc (c);"
// void cputcxy(__zp($51) char x, __zp($4c) char y, __zp($55) char c)
cputcxy: {
    .label x = $51
    .label y = $4c
    .label c = $55
    // gotoxy(x, y)
    // [844] gotoxy::x#0 = cputcxy::x#13 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [845] gotoxy::y#0 = cputcxy::y#13 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [846] call gotoxy
    // [286] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [286] phi gotoxy::y#19 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [286] phi gotoxy::x#19 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [847] stackpush(char) = cputcxy::c#13 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [848] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [850] return 
    rts
}
  // wherex
// Return the x position of the cursor
wherex: {
    .label return = $66
    .label return_1 = $71
    .label return_2 = $a9
    .label return_3 = $5b
    .label return_4 = $6a
    // return __conio.cursor_x;
    // [851] wherex::return#0 = *((char *)&__conio) -- vbuz1=_deref_pbuc1 
    lda __conio
    sta.z return
    // wherex::@return
    // }
    // [852] return 
    rts
}
  // wherey
// Return the y position of the cursor
wherey: {
    .label return = $67
    .label return_1 = $60
    .label return_2 = $72
    .label return_3 = $7f
    .label return_4 = $69
    // return __conio.cursor_y;
    // [853] wherey::return#0 = *((char *)&__conio+1) -- vbuz1=_deref_pbuc1 
    lda __conio+1
    sta.z return
    // wherey::@return
    // }
    // [854] return 
    rts
}
  // print_vera_led
// void print_vera_led(__zp($3d) char c)
print_vera_led: {
    .label c = $3d
    // print_chip_led(CHIP_VERA_X+1, CHIP_VERA_Y, CHIP_VERA_W, c, BLUE)
    // [856] print_chip_led::tc#1 = print_vera_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z print_chip_led.tc
    // [857] call print_chip_led
    // [1062] phi from print_vera_led to print_chip_led [phi:print_vera_led->print_chip_led]
    // [1062] phi print_chip_led::w#7 = 8 [phi:print_vera_led->print_chip_led#0] -- vbuz1=vbuc1 
    lda #8
    sta.z print_chip_led.w
    // [1062] phi print_chip_led::x#7 = 9+1 [phi:print_vera_led->print_chip_led#1] -- vbuz1=vbuc1 
    lda #9+1
    sta.z print_chip_led.x
    // [1062] phi print_chip_led::tc#3 = print_chip_led::tc#1 [phi:print_vera_led->print_chip_led#2] -- register_copy 
    jsr print_chip_led
    // print_vera_led::@1
    // print_info_led(INFO_X-2, INFO_Y+1, c, BLUE)
    // [858] print_info_led::tc#1 = print_vera_led::c#2
    // [859] call print_info_led
    // [596] phi from print_vera_led::@1 to print_info_led [phi:print_vera_led::@1->print_info_led]
    // [596] phi print_info_led::y#4 = $11+1 [phi:print_vera_led::@1->print_info_led#0] -- vbuz1=vbuc1 
    lda #$11+1
    sta.z print_info_led.y
    // [596] phi print_info_led::x#4 = 4-2 [phi:print_vera_led::@1->print_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z print_info_led.x
    // [596] phi print_info_led::tc#4 = print_info_led::tc#1 [phi:print_vera_led::@1->print_info_led#2] -- register_copy 
    jsr print_info_led
    // print_vera_led::@return
    // }
    // [860] return 
    rts
}
  // print_chip
// void print_chip(char x, char y, char w, char *text)
print_chip: {
    .label x = 9
    .label w = 8
    // print_chip_line(x, y++, w, *text++)
    // [861] print_chip_line::c#0 = *chip_vera::text -- vbuz1=_deref_pbuc1 
    lda chip_vera.text
    sta.z print_chip_line.c
    // [862] call print_chip_line
    // [1080] phi from print_chip to print_chip_line [phi:print_chip->print_chip_line]
    // [1080] phi print_chip_line::c#15 = print_chip_line::c#0 [phi:print_chip->print_chip_line#0] -- register_copy 
    // [1080] phi print_chip_line::y#16 = 3+2 [phi:print_chip->print_chip_line#1] -- vbuz1=vbuc1 
    lda #3+2
    sta.z print_chip_line.y
    jsr print_chip_line
    // print_chip::@1
    // print_chip_line(x, y++, w, *text++)
    // [863] print_chip_line::c#1 = *(++chip_vera::text) -- vbuz1=_deref_pbuc1 
    lda chip_vera.text+1
    sta.z print_chip_line.c
    // [864] call print_chip_line
    // [1080] phi from print_chip::@1 to print_chip_line [phi:print_chip::@1->print_chip_line]
    // [1080] phi print_chip_line::c#15 = print_chip_line::c#1 [phi:print_chip::@1->print_chip_line#0] -- register_copy 
    // [1080] phi print_chip_line::y#16 = ++3+2 [phi:print_chip::@1->print_chip_line#1] -- vbuz1=vbuc1 
    lda #3+2+1
    sta.z print_chip_line.y
    jsr print_chip_line
    // print_chip::@2
    // print_chip_line(x, y++, w, *text++)
    // [865] print_chip_line::c#2 = *(++++chip_vera::text) -- vbuz1=_deref_pbuc1 
    lda chip_vera.text+1+1
    sta.z print_chip_line.c
    // [866] call print_chip_line
    // [1080] phi from print_chip::@2 to print_chip_line [phi:print_chip::@2->print_chip_line]
    // [1080] phi print_chip_line::c#15 = print_chip_line::c#2 [phi:print_chip::@2->print_chip_line#0] -- register_copy 
    // [1080] phi print_chip_line::y#16 = ++++3+2 [phi:print_chip::@2->print_chip_line#1] -- vbuz1=vbuc1 
    lda #3+2+1+1
    sta.z print_chip_line.y
    jsr print_chip_line
    // print_chip::@3
    // print_chip_line(x, y++, w, *text++)
    // [867] print_chip_line::c#3 = *(++++++chip_vera::text) -- vbuz1=_deref_pbuc1 
    lda chip_vera.text+1+1+1
    sta.z print_chip_line.c
    // [868] call print_chip_line
    // [1080] phi from print_chip::@3 to print_chip_line [phi:print_chip::@3->print_chip_line]
    // [1080] phi print_chip_line::c#15 = print_chip_line::c#3 [phi:print_chip::@3->print_chip_line#0] -- register_copy 
    // [1080] phi print_chip_line::y#16 = ++++++3+2 [phi:print_chip::@3->print_chip_line#1] -- vbuz1=vbuc1 
    lda #3+2+1+1+1
    sta.z print_chip_line.y
    jsr print_chip_line
    // print_chip::@4
    // print_chip_line(x, y++, w, *text++)
    // [869] print_chip_line::c#4 = *(++++++++chip_vera::text) -- vbuz1=_deref_pbuc1 
    lda chip_vera.text+1+1+1+1
    sta.z print_chip_line.c
    // [870] call print_chip_line
    // [1080] phi from print_chip::@4 to print_chip_line [phi:print_chip::@4->print_chip_line]
    // [1080] phi print_chip_line::c#15 = print_chip_line::c#4 [phi:print_chip::@4->print_chip_line#0] -- register_copy 
    // [1080] phi print_chip_line::y#16 = ++++++++3+2 [phi:print_chip::@4->print_chip_line#1] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1
    sta.z print_chip_line.y
    jsr print_chip_line
    // print_chip::@5
    // print_chip_line(x, y++, w, *text++)
    // [871] print_chip_line::c#5 = *(++++++++++chip_vera::text) -- vbuz1=_deref_pbuc1 
    lda chip_vera.text+1+1+1+1+1
    sta.z print_chip_line.c
    // [872] call print_chip_line
    // [1080] phi from print_chip::@5 to print_chip_line [phi:print_chip::@5->print_chip_line]
    // [1080] phi print_chip_line::c#15 = print_chip_line::c#5 [phi:print_chip::@5->print_chip_line#0] -- register_copy 
    // [1080] phi print_chip_line::y#16 = ++++++++++3+2 [phi:print_chip::@5->print_chip_line#1] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1+1
    sta.z print_chip_line.y
    jsr print_chip_line
    // print_chip::@6
    // print_chip_line(x, y++, w, *text++)
    // [873] print_chip_line::c#6 = *(++++++++++++chip_vera::text) -- vbuz1=_deref_pbuc1 
    lda chip_vera.text+1+1+1+1+1+1
    sta.z print_chip_line.c
    // [874] call print_chip_line
    // [1080] phi from print_chip::@6 to print_chip_line [phi:print_chip::@6->print_chip_line]
    // [1080] phi print_chip_line::c#15 = print_chip_line::c#6 [phi:print_chip::@6->print_chip_line#0] -- register_copy 
    // [1080] phi print_chip_line::y#16 = ++++++++++++3+2 [phi:print_chip::@6->print_chip_line#1] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1+1+1
    sta.z print_chip_line.y
    jsr print_chip_line
    // print_chip::@7
    // print_chip_line(x, y++, w, *text++)
    // [875] print_chip_line::c#7 = *(++++++++++++++chip_vera::text) -- vbuz1=_deref_pbuc1 
    lda chip_vera.text+1+1+1+1+1+1+1
    sta.z print_chip_line.c
    // [876] call print_chip_line
    // [1080] phi from print_chip::@7 to print_chip_line [phi:print_chip::@7->print_chip_line]
    // [1080] phi print_chip_line::c#15 = print_chip_line::c#7 [phi:print_chip::@7->print_chip_line#0] -- register_copy 
    // [1080] phi print_chip_line::y#16 = ++++++++++++++3+2 [phi:print_chip::@7->print_chip_line#1] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1+1+1+1
    sta.z print_chip_line.y
    jsr print_chip_line
    // [877] phi from print_chip::@7 to print_chip::@8 [phi:print_chip::@7->print_chip::@8]
    // print_chip::@8
    // print_chip_end(x, y++, w)
    // [878] call print_chip_end
    // [1113] phi from print_chip::@8 to print_chip_end [phi:print_chip::@8->print_chip_end]
    jsr print_chip_end
    // print_chip::@return
    // }
    // [879] return 
    rts
}
  // cbm_k_getin
/**
 * @brief Scan a character from keyboard without pressing enter.
 * 
 * @return char The character read.
 */
cbm_k_getin: {
    .label return = $5b
    // __mem unsigned char ch
    // [880] cbm_k_getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsrCBM_GETIN stach  }
    jsr CBM_GETIN
    sta ch
    // return ch;
    // [882] cbm_k_getin::return#0 = cbm_k_getin::ch -- vbuz1=vbum2 
    sta.z return
    // cbm_k_getin::@return
    // }
    // [883] cbm_k_getin::return#1 = cbm_k_getin::return#0
    // [884] return 
    rts
  .segment Data
    ch: .byte 0
}
.segment Code
  // print_smc_led
// void print_smc_led(__zp($54) char c)
print_smc_led: {
    .label c = $54
    // print_chip_led(CHIP_SMC_X+1, CHIP_SMC_Y, CHIP_SMC_W, c, BLUE)
    // [885] print_chip_led::tc#0 = print_smc_led::c#0 -- vbuz1=vbuz2 
    lda.z c
    sta.z print_chip_led.tc
    // [886] call print_chip_led
    // [1062] phi from print_smc_led to print_chip_led [phi:print_smc_led->print_chip_led]
    // [1062] phi print_chip_led::w#7 = 5 [phi:print_smc_led->print_chip_led#0] -- vbuz1=vbuc1 
    lda #5
    sta.z print_chip_led.w
    // [1062] phi print_chip_led::x#7 = 1+1 [phi:print_smc_led->print_chip_led#1] -- vbuz1=vbuc1 
    lda #1+1
    sta.z print_chip_led.x
    // [1062] phi print_chip_led::tc#3 = print_chip_led::tc#0 [phi:print_smc_led->print_chip_led#2] -- register_copy 
    jsr print_chip_led
    // print_smc_led::@1
    // print_info_led(INFO_X-2, INFO_Y, c, BLUE)
    // [887] print_info_led::tc#0 = print_smc_led::c#0 -- vbuz1=vbuz2 
    lda.z c
    sta.z print_info_led.tc
    // [888] call print_info_led
    // [596] phi from print_smc_led::@1 to print_info_led [phi:print_smc_led::@1->print_info_led]
    // [596] phi print_info_led::y#4 = $11 [phi:print_smc_led::@1->print_info_led#0] -- vbuz1=vbuc1 
    lda #$11
    sta.z print_info_led.y
    // [596] phi print_info_led::x#4 = 4-2 [phi:print_smc_led::@1->print_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z print_info_led.x
    // [596] phi print_info_led::tc#4 = print_info_led::tc#0 [phi:print_smc_led::@1->print_info_led#2] -- register_copy 
    jsr print_info_led
    // print_smc_led::@return
    // }
    // [889] return 
    rts
}
  // printf_uint
// Print an unsigned int using a specific format
// void printf_uint(void (*putc)(char), unsigned int uvalue, char format_min_length, char format_justify_left, char format_sign_always, char format_zero_padding, char format_upper_case, char format_radix)
printf_uint: {
    .const format_min_length = 5
    .const format_justify_left = 0
    .const format_zero_padding = 1
    .const format_upper_case = 0
    .label putc = cputc
    // printf_uint::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [891] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [892] call utoa
  // Format number into buffer
    // [1139] phi from printf_uint::@1 to utoa [phi:printf_uint::@1->utoa]
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [893] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [894] call printf_number_buffer
  // Print using format
    // [915] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    // [915] phi printf_number_buffer::format_upper_case#10 = printf_uint::format_upper_case#0 [phi:printf_uint::@2->printf_number_buffer#0] -- vbuz1=vbuc1 
    lda #format_upper_case
    sta.z printf_number_buffer.format_upper_case
    // [915] phi printf_number_buffer::putc#10 = printf_uint::putc#0 [phi:printf_uint::@2->printf_number_buffer#1] -- pprz1=pprc1 
    lda #<putc
    sta.z printf_number_buffer.putc
    lda #>putc
    sta.z printf_number_buffer.putc+1
    // [915] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_uint::@2->printf_number_buffer#2] -- register_copy 
    // [915] phi printf_number_buffer::format_zero_padding#10 = printf_uint::format_zero_padding#0 [phi:printf_uint::@2->printf_number_buffer#3] -- vbuz1=vbuc1 
    lda #format_zero_padding
    sta.z printf_number_buffer.format_zero_padding
    // [915] phi printf_number_buffer::format_justify_left#10 = printf_uint::format_justify_left#0 [phi:printf_uint::@2->printf_number_buffer#4] -- vbuz1=vbuc1 
    lda #format_justify_left
    sta.z printf_number_buffer.format_justify_left
    // [915] phi printf_number_buffer::format_min_length#3 = printf_uint::format_min_length#0 [phi:printf_uint::@2->printf_number_buffer#5] -- vbuz1=vbuc1 
    lda #format_min_length
    sta.z printf_number_buffer.format_min_length
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [895] return 
    rts
}
  // uctoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void uctoa(__zp($38) char value, __zp($56) char *buffer, char radix)
uctoa: {
    .label digit_value = $3f
    .label buffer = $56
    .label digit = $51
    .label value = $38
    .label started = $4c
    // [897] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
    // [897] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [897] phi uctoa::started#2 = 0 [phi:uctoa->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [897] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa->uctoa::@1#2] -- register_copy 
    // [897] phi uctoa::digit#2 = 0 [phi:uctoa->uctoa::@1#3] -- vbuz1=vbuc1 
    sta.z digit
    // uctoa::@1
  __b1:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [898] if(uctoa::digit#2<3-1) goto uctoa::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z digit
    cmp #3-1
    bcc __b2
    // uctoa::@3
    // *buffer++ = DIGITS[(char)value]
    // [899] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z value
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [900] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [901] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    // uctoa::@return
    // }
    // [902] return 
    rts
    // uctoa::@2
  __b2:
    // unsigned char digit_value = digit_values[digit]
    // [903] uctoa::digit_value#0 = RADIX_DECIMAL_VALUES_CHAR[uctoa::digit#2] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda RADIX_DECIMAL_VALUES_CHAR,y
    sta.z digit_value
    // if (started || value >= digit_value)
    // [904] if(0!=uctoa::started#2) goto uctoa::@5 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b5
    // uctoa::@7
    // [905] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@5 -- vbuz1_ge_vbuz2_then_la1 
    lda.z value
    cmp.z digit_value
    bcs __b5
    // [906] phi from uctoa::@7 to uctoa::@4 [phi:uctoa::@7->uctoa::@4]
    // [906] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@7->uctoa::@4#0] -- register_copy 
    // [906] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@7->uctoa::@4#1] -- register_copy 
    // [906] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@7->uctoa::@4#2] -- register_copy 
    // uctoa::@4
  __b4:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [907] uctoa::digit#1 = ++ uctoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [897] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
    // [897] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@4->uctoa::@1#0] -- register_copy 
    // [897] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@4->uctoa::@1#1] -- register_copy 
    // [897] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@4->uctoa::@1#2] -- register_copy 
    // [897] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@4->uctoa::@1#3] -- register_copy 
    jmp __b1
    // uctoa::@5
  __b5:
    // uctoa_append(buffer++, value, digit_value)
    // [908] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [909] uctoa_append::value#0 = uctoa::value#2
    // [910] uctoa_append::sub#0 = uctoa::digit_value#0
    // [911] call uctoa_append
    // [1160] phi from uctoa::@5 to uctoa_append [phi:uctoa::@5->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [912] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@6
    // value = uctoa_append(buffer++, value, digit_value)
    // [913] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [914] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [906] phi from uctoa::@6 to uctoa::@4 [phi:uctoa::@6->uctoa::@4]
    // [906] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@6->uctoa::@4#0] -- register_copy 
    // [906] phi uctoa::started#4 = 1 [phi:uctoa::@6->uctoa::@4#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [906] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@6->uctoa::@4#2] -- register_copy 
    jmp __b4
}
  // printf_number_buffer
// Print the contents of the number buffer using a specific format.
// This handles minimum length, zero-filling, and left/right justification from the format
// void printf_number_buffer(__zp($5e) void (*putc)(char), __zp($6e) char buffer_sign, char *buffer_digits, __zp($6d) char format_min_length, __zp($7b) char format_justify_left, char format_sign_always, __zp($78) char format_zero_padding, __zp($6f) char format_upper_case, char format_radix)
printf_number_buffer: {
    .label printf_number_buffer__19 = $52
    .label buffer_sign = $6e
    .label putc = $5e
    .label len = $64
    .label padding = $6d
    .label format_min_length = $6d
    .label format_zero_padding = $78
    .label format_justify_left = $7b
    .label format_upper_case = $6f
    // if(format.min_length)
    // [916] if(0==printf_number_buffer::format_min_length#3) goto printf_number_buffer::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b6
    // [917] phi from printf_number_buffer to printf_number_buffer::@6 [phi:printf_number_buffer->printf_number_buffer::@6]
    // printf_number_buffer::@6
    // strlen(buffer.digits)
    // [918] call strlen
    // [1048] phi from printf_number_buffer::@6 to strlen [phi:printf_number_buffer::@6->strlen]
    // [1048] phi strlen::str#5 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@6->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [919] strlen::return#2 = strlen::len#2
    // printf_number_buffer::@14
    // [920] printf_number_buffer::$19 = strlen::return#2
    // signed char len = (signed char)strlen(buffer.digits)
    // [921] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsz1=_sbyte_vwuz2 
    // There is a minimum length - work out the padding
    lda.z printf_number_buffer__19
    sta.z len
    // if(buffer.sign)
    // [922] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@13 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b13
    // printf_number_buffer::@7
    // len++;
    // [923] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsz1=_inc_vbsz1 
    inc.z len
    // [924] phi from printf_number_buffer::@14 printf_number_buffer::@7 to printf_number_buffer::@13 [phi:printf_number_buffer::@14/printf_number_buffer::@7->printf_number_buffer::@13]
    // [924] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@14/printf_number_buffer::@7->printf_number_buffer::@13#0] -- register_copy 
    // printf_number_buffer::@13
  __b13:
    // padding = (signed char)format.min_length - len
    // [925] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#3 - printf_number_buffer::len#2 -- vbsz1=vbsz1_minus_vbsz2 
    lda.z padding
    sec
    sbc.z len
    sta.z padding
    // if(padding<0)
    // [926] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@21 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [928] phi from printf_number_buffer printf_number_buffer::@13 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@13->printf_number_buffer::@1]
  __b6:
    // [928] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@13->printf_number_buffer::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [927] phi from printf_number_buffer::@13 to printf_number_buffer::@21 [phi:printf_number_buffer::@13->printf_number_buffer::@21]
    // printf_number_buffer::@21
    // [928] phi from printf_number_buffer::@21 to printf_number_buffer::@1 [phi:printf_number_buffer::@21->printf_number_buffer::@1]
    // [928] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@21->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // if(!format.justify_left && !format.zero_padding && padding)
    // [929] if(0!=printf_number_buffer::format_justify_left#10) goto printf_number_buffer::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_justify_left
    bne __b2
    // printf_number_buffer::@17
    // [930] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_zero_padding
    bne __b2
    // printf_number_buffer::@16
    // [931] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@8 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b8
    jmp __b2
    // printf_number_buffer::@8
  __b8:
    // printf_padding(putc, ' ',(char)padding)
    // [932] printf_padding::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [933] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [934] call printf_padding
    // [1054] phi from printf_number_buffer::@8 to printf_padding [phi:printf_number_buffer::@8->printf_padding]
    // [1054] phi printf_padding::putc#7 = printf_padding::putc#0 [phi:printf_number_buffer::@8->printf_padding#0] -- register_copy 
    // [1054] phi printf_padding::pad#7 = ' ' [phi:printf_number_buffer::@8->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1054] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@8->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [935] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b3
    // printf_number_buffer::@9
    // putc(buffer.sign)
    // [936] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbuz1 
    pha
    // [937] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall5
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [939] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbuz1_then_la1 
    lda.z format_zero_padding
    beq __b4
    // printf_number_buffer::@18
    // [940] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@10 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b10
    jmp __b4
    // printf_number_buffer::@10
  __b10:
    // printf_padding(putc, '0',(char)padding)
    // [941] printf_padding::putc#1 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [942] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [943] call printf_padding
    // [1054] phi from printf_number_buffer::@10 to printf_padding [phi:printf_number_buffer::@10->printf_padding]
    // [1054] phi printf_padding::putc#7 = printf_padding::putc#1 [phi:printf_number_buffer::@10->printf_padding#0] -- register_copy 
    // [1054] phi printf_padding::pad#7 = '0' [phi:printf_number_buffer::@10->printf_padding#1] -- vbuz1=vbuc1 
    lda #'0'
    sta.z printf_padding.pad
    // [1054] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@10->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // if(format.upper_case)
    // [944] if(0==printf_number_buffer::format_upper_case#10) goto printf_number_buffer::@5 -- 0_eq_vbuz1_then_la1 
    lda.z format_upper_case
    beq __b5
    // [945] phi from printf_number_buffer::@4 to printf_number_buffer::@11 [phi:printf_number_buffer::@4->printf_number_buffer::@11]
    // printf_number_buffer::@11
    // strupr(buffer.digits)
    // [946] call strupr
    // [1167] phi from printf_number_buffer::@11 to strupr [phi:printf_number_buffer::@11->strupr]
    jsr strupr
    // printf_number_buffer::@5
  __b5:
    // printf_str(putc, buffer.digits)
    // [947] printf_str::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_str.putc
    lda.z putc+1
    sta.z printf_str.putc+1
    // [948] call printf_str
    // [511] phi from printf_number_buffer::@5 to printf_str [phi:printf_number_buffer::@5->printf_str]
    // [511] phi printf_str::putc#17 = printf_str::putc#0 [phi:printf_number_buffer::@5->printf_str#0] -- register_copy 
    // [511] phi printf_str::s#17 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@15
    // if(format.justify_left && !format.zero_padding && padding)
    // [949] if(0==printf_number_buffer::format_justify_left#10) goto printf_number_buffer::@return -- 0_eq_vbuz1_then_la1 
    lda.z format_justify_left
    beq __breturn
    // printf_number_buffer::@20
    // [950] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@return -- 0_neq_vbuz1_then_la1 
    lda.z format_zero_padding
    bne __breturn
    // printf_number_buffer::@19
    // [951] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@12 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b12
    rts
    // printf_number_buffer::@12
  __b12:
    // printf_padding(putc, ' ',(char)padding)
    // [952] printf_padding::putc#2 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [953] printf_padding::length#2 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [954] call printf_padding
    // [1054] phi from printf_number_buffer::@12 to printf_padding [phi:printf_number_buffer::@12->printf_padding]
    // [1054] phi printf_padding::putc#7 = printf_padding::putc#2 [phi:printf_number_buffer::@12->printf_padding#0] -- register_copy 
    // [1054] phi printf_padding::pad#7 = ' ' [phi:printf_number_buffer::@12->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1054] phi printf_padding::length#6 = printf_padding::length#2 [phi:printf_number_buffer::@12->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@return
  __breturn:
    // }
    // [955] return 
    rts
    // Outside Flow
  icall5:
    jmp (putc)
}
  // print_rom_led
// void print_rom_led(__zp($7d) char chip, __zp($70) char c)
print_rom_led: {
    .label print_rom_led__0 = $5d
    .label print_rom_led__4 = $4c
    .label chip = $7d
    .label c = $70
    .label print_rom_led__7 = $5d
    .label print_rom_led__8 = $5d
    // chip*6
    // [956] print_rom_led::$7 = print_rom_led::chip#0 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z chip
    asl
    sta.z print_rom_led__7
    // [957] print_rom_led::$8 = print_rom_led::$7 + print_rom_led::chip#0 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z print_rom_led__8
    clc
    adc.z chip
    sta.z print_rom_led__8
    // CHIP_ROM_X+chip*6
    // [958] print_rom_led::$0 = print_rom_led::$8 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z print_rom_led__0
    // print_chip_led(CHIP_ROM_X+chip*6+1, CHIP_ROM_Y, CHIP_ROM_W, c, BLUE)
    // [959] print_chip_led::x#3 = print_rom_led::$0 + $14+1 -- vbuz1=vbuz1_plus_vbuc1 
    lda #$14+1
    clc
    adc.z print_chip_led.x
    sta.z print_chip_led.x
    // [960] print_chip_led::tc#2 = print_rom_led::c#0 -- vbuz1=vbuz2 
    lda.z c
    sta.z print_chip_led.tc
    // [961] call print_chip_led
    // [1062] phi from print_rom_led to print_chip_led [phi:print_rom_led->print_chip_led]
    // [1062] phi print_chip_led::w#7 = 3 [phi:print_rom_led->print_chip_led#0] -- vbuz1=vbuc1 
    lda #3
    sta.z print_chip_led.w
    // [1062] phi print_chip_led::x#7 = print_chip_led::x#3 [phi:print_rom_led->print_chip_led#1] -- register_copy 
    // [1062] phi print_chip_led::tc#3 = print_chip_led::tc#2 [phi:print_rom_led->print_chip_led#2] -- register_copy 
    jsr print_chip_led
    // print_rom_led::@1
    // INFO_Y+chip
    // [962] print_rom_led::$4 = print_rom_led::chip#0 -- vbuz1=vbuz2 
    lda.z chip
    sta.z print_rom_led__4
    // print_info_led(INFO_X-2, INFO_Y+chip+2, c, BLUE)
    // [963] print_info_led::y#2 = print_rom_led::$4 + $11+2 -- vbuz1=vbuz1_plus_vbuc1 
    lda #$11+2
    clc
    adc.z print_info_led.y
    sta.z print_info_led.y
    // [964] print_info_led::tc#2 = print_rom_led::c#0 -- vbuz1=vbuz2 
    lda.z c
    sta.z print_info_led.tc
    // [965] call print_info_led
    // [596] phi from print_rom_led::@1 to print_info_led [phi:print_rom_led::@1->print_info_led]
    // [596] phi print_info_led::y#4 = print_info_led::y#2 [phi:print_rom_led::@1->print_info_led#0] -- register_copy 
    // [596] phi print_info_led::x#4 = 4-2 [phi:print_rom_led::@1->print_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z print_info_led.x
    // [596] phi print_info_led::tc#4 = print_info_led::tc#2 [phi:print_rom_led::@1->print_info_led#2] -- register_copy 
    jsr print_info_led
    // print_rom_led::@return
    // }
    // [966] return 
    rts
}
  // printf_ulong
// Print an unsigned int using a specific format
// void printf_ulong(void (*putc)(char), __zp($39) unsigned long uvalue, char format_min_length, char format_justify_left, char format_sign_always, char format_zero_padding, char format_upper_case, char format_radix)
printf_ulong: {
    .label uvalue = $39
    // printf_ulong::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [968] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // ultoa(uvalue, printf_buffer.digits, format.radix)
    // [969] ultoa::value#1 = printf_ulong::uvalue#2
    // [970] call ultoa
  // Format number into buffer
    // [1177] phi from printf_ulong::@1 to ultoa [phi:printf_ulong::@1->ultoa]
    jsr ultoa
    // printf_ulong::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [971] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [972] call printf_number_buffer
  // Print using format
    // [915] phi from printf_ulong::@2 to printf_number_buffer [phi:printf_ulong::@2->printf_number_buffer]
    // [915] phi printf_number_buffer::format_upper_case#10 = 0 [phi:printf_ulong::@2->printf_number_buffer#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_number_buffer.format_upper_case
    // [915] phi printf_number_buffer::putc#10 = &cputc [phi:printf_ulong::@2->printf_number_buffer#1] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_number_buffer.putc
    lda #>cputc
    sta.z printf_number_buffer.putc+1
    // [915] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_ulong::@2->printf_number_buffer#2] -- register_copy 
    // [915] phi printf_number_buffer::format_zero_padding#10 = 1 [phi:printf_ulong::@2->printf_number_buffer#3] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_number_buffer.format_zero_padding
    // [915] phi printf_number_buffer::format_justify_left#10 = 0 [phi:printf_ulong::@2->printf_number_buffer#4] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_number_buffer.format_justify_left
    // [915] phi printf_number_buffer::format_min_length#3 = 5 [phi:printf_ulong::@2->printf_number_buffer#5] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_number_buffer.format_min_length
    jsr printf_number_buffer
    // printf_ulong::@return
    // }
    // [973] return 
    rts
}
  // insertup
// Insert a new line, and scroll the upper part of the screen up.
// void insertup(char rows)
insertup: {
    .label insertup__0 = $31
    .label insertup__4 = $2f
    .label insertup__6 = $30
    .label insertup__7 = $2f
    .label width = $31
    .label y = $2c
    // __conio.width+1
    // [974] insertup::$0 = *((char *)&__conio+6) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+6
    inc
    sta.z insertup__0
    // unsigned char width = (__conio.width+1) * 2
    // [975] insertup::width#0 = insertup::$0 << 1 -- vbuz1=vbuz1_rol_1 
    // {asm{.byte $db}}
    asl.z width
    // [976] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [976] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [977] if(insertup::y#2<*((char *)&__conio+1)) goto insertup::@2 -- vbuz1_lt__deref_pbuc1_then_la1 
    lda.z y
    cmp __conio+1
    bcc __b2
    // [978] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [979] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [980] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [981] insertup::$4 = insertup::y#2 + 1 -- vbuz1=vbuz2_plus_1 
    lda.z y
    inc
    sta.z insertup__4
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [982] insertup::$6 = insertup::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z insertup__6
    // [983] insertup::$7 = insertup::$4 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z insertup__7
    // [984] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z memcpy8_vram_vram.dbank_vram
    // [985] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__6
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.doffset_vram+1
    // [986] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z memcpy8_vram_vram.sbank_vram
    // [987] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__7
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.soffset_vram+1
    // [988] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbuz1=vbuz2 
    lda.z width
    sta.z memcpy8_vram_vram.num8_1
    // [989] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [990] insertup::y#1 = ++ insertup::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [976] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [976] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
    jmp __b1
}
  // clearline
clearline: {
    .label clearline__0 = $24
    .label clearline__1 = $26
    .label clearline__2 = $27
    .label clearline__3 = $25
    .label addr = $2d
    .label c = $22
    // unsigned int addr = __conio.offsets[__conio.cursor_y]
    // [991] clearline::$3 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z clearline__3
    // [992] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwuz1=pwuc1_derefidx_vbuz2 
    tay
    lda __conio+$15,y
    sta.z addr
    lda __conio+$15+1,y
    sta.z addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [993] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [994] clearline::$0 = byte0  clearline::addr#0 -- vbuz1=_byte0_vwuz2 
    lda.z addr
    sta.z clearline__0
    // *VERA_ADDRX_L = BYTE0(addr)
    // [995] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [996] clearline::$1 = byte1  clearline::addr#0 -- vbuz1=_byte1_vwuz2 
    lda.z addr+1
    sta.z clearline__1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [997] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [998] clearline::$2 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clearline__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [999] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [1000] clearline::c#0 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z c
    // [1001] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [1001] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [1002] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1003] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [1004] clearline::c#1 = -- clearline::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [1005] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b1
    // clearline::@return
    // }
    // [1006] return 
    rts
}
  // frame_maskxy
// __zp($65) char frame_maskxy(__zp($6b) char x, __zp($49) char y)
frame_maskxy: {
    .label cpeekcxy1_cpeekc1_frame_maskxy__0 = $6a
    .label cpeekcxy1_cpeekc1_frame_maskxy__1 = $69
    .label cpeekcxy1_cpeekc1_frame_maskxy__2 = $66
    .label cpeekcxy1_x = $6b
    .label cpeekcxy1_y = $49
    .label c = $67
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
    .label return = $65
    .label x = $6b
    .label y = $49
    // frame_maskxy::cpeekcxy1
    // gotoxy(x,y)
    // [1008] gotoxy::x#5 = frame_maskxy::cpeekcxy1_x#0 -- vbuz1=vbuz2 
    lda.z cpeekcxy1_x
    sta.z gotoxy.x
    // [1009] gotoxy::y#5 = frame_maskxy::cpeekcxy1_y#0 -- vbuz1=vbuz2 
    lda.z cpeekcxy1_y
    sta.z gotoxy.y
    // [1010] call gotoxy
    // [286] phi from frame_maskxy::cpeekcxy1 to gotoxy [phi:frame_maskxy::cpeekcxy1->gotoxy]
    // [286] phi gotoxy::y#19 = gotoxy::y#5 [phi:frame_maskxy::cpeekcxy1->gotoxy#0] -- register_copy 
    // [286] phi gotoxy::x#19 = gotoxy::x#5 [phi:frame_maskxy::cpeekcxy1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // frame_maskxy::cpeekcxy1_cpeekc1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1011] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [1012] frame_maskxy::cpeekcxy1_cpeekc1_$0 = byte0  *((unsigned int *)&__conio+$13) -- vbuz1=_byte0__deref_pwuc1 
    lda __conio+$13
    sta.z cpeekcxy1_cpeekc1_frame_maskxy__0
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [1013] *VERA_ADDRX_L = frame_maskxy::cpeekcxy1_cpeekc1_$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [1014] frame_maskxy::cpeekcxy1_cpeekc1_$1 = byte1  *((unsigned int *)&__conio+$13) -- vbuz1=_byte1__deref_pwuc1 
    lda __conio+$13+1
    sta.z cpeekcxy1_cpeekc1_frame_maskxy__1
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [1015] *VERA_ADDRX_M = frame_maskxy::cpeekcxy1_cpeekc1_$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_0
    // [1016] frame_maskxy::cpeekcxy1_cpeekc1_$2 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z cpeekcxy1_cpeekc1_frame_maskxy__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_0
    // [1017] *VERA_ADDRX_H = frame_maskxy::cpeekcxy1_cpeekc1_$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // return *VERA_DATA0;
    // [1018] frame_maskxy::c#0 = *VERA_DATA0 -- vbuz1=_deref_pbuc1 
    lda VERA_DATA0
    sta.z c
    // frame_maskxy::@12
    // case 0x70: // DR corner.
    //             return 0b0110;
    // [1019] if(frame_maskxy::c#0==$70) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$70
    cmp.z c
    beq __b2
    // frame_maskxy::@1
    // case 0x6E: // DL corner.
    //             return 0b0011;
    // [1020] if(frame_maskxy::c#0==$6e) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6e
    cmp.z c
    beq __b1
    // frame_maskxy::@2
    // case 0x6D: // UR corner.
    //             return 0b1100;
    // [1021] if(frame_maskxy::c#0==$6d) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6d
    cmp.z c
    beq __b3
    // frame_maskxy::@3
    // case 0x7D: // UL corner.
    //             return 0b1001;
    // [1022] if(frame_maskxy::c#0==$7d) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$7d
    cmp.z c
    beq __b4
    // frame_maskxy::@4
    // case 0x40: // HL line.
    //             return 0b0101;
    // [1023] if(frame_maskxy::c#0==$40) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$40
    cmp.z c
    beq __b5
    // frame_maskxy::@5
    // case 0x5D: // VL line.
    //             return 0b1010;
    // [1024] if(frame_maskxy::c#0==$5d) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$5d
    cmp.z c
    beq __b6
    // frame_maskxy::@6
    // case 0x6B: // VR junction.
    //             return 0b1110;
    // [1025] if(frame_maskxy::c#0==$6b) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6b
    cmp.z c
    beq __b7
    // frame_maskxy::@7
    // case 0x73: // VL junction.
    //             return 0b1011;
    // [1026] if(frame_maskxy::c#0==$73) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$73
    cmp.z c
    beq __b8
    // frame_maskxy::@8
    // case 0x72: // HD junction.
    //             return 0b0111;
    // [1027] if(frame_maskxy::c#0==$72) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$72
    cmp.z c
    beq __b9
    // frame_maskxy::@9
    // case 0x71: // HU junction.
    //             return 0b1101;
    // [1028] if(frame_maskxy::c#0==$71) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$71
    cmp.z c
    beq __b10
    // frame_maskxy::@10
    // case 0x5B: // HV junction.
    //             return 0b1111;
    // [1029] if(frame_maskxy::c#0==$5b) goto frame_maskxy::@11 -- vbuz1_eq_vbuc1_then_la1 
    lda #$5b
    cmp.z c
    beq __b11
    // [1031] phi from frame_maskxy::@10 to frame_maskxy::@return [phi:frame_maskxy::@10->frame_maskxy::@return]
    // [1031] phi frame_maskxy::return#12 = 0 [phi:frame_maskxy::@10->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #0
    sta.z return
    rts
    // [1030] phi from frame_maskxy::@10 to frame_maskxy::@11 [phi:frame_maskxy::@10->frame_maskxy::@11]
    // frame_maskxy::@11
  __b11:
    // [1031] phi from frame_maskxy::@11 to frame_maskxy::@return [phi:frame_maskxy::@11->frame_maskxy::@return]
    // [1031] phi frame_maskxy::return#12 = $f [phi:frame_maskxy::@11->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$f
    sta.z return
    rts
    // [1031] phi from frame_maskxy::@1 to frame_maskxy::@return [phi:frame_maskxy::@1->frame_maskxy::@return]
  __b1:
    // [1031] phi frame_maskxy::return#12 = 3 [phi:frame_maskxy::@1->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #3
    sta.z return
    rts
    // [1031] phi from frame_maskxy::@12 to frame_maskxy::@return [phi:frame_maskxy::@12->frame_maskxy::@return]
  __b2:
    // [1031] phi frame_maskxy::return#12 = 6 [phi:frame_maskxy::@12->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #6
    sta.z return
    rts
    // [1031] phi from frame_maskxy::@2 to frame_maskxy::@return [phi:frame_maskxy::@2->frame_maskxy::@return]
  __b3:
    // [1031] phi frame_maskxy::return#12 = $c [phi:frame_maskxy::@2->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$c
    sta.z return
    rts
    // [1031] phi from frame_maskxy::@3 to frame_maskxy::@return [phi:frame_maskxy::@3->frame_maskxy::@return]
  __b4:
    // [1031] phi frame_maskxy::return#12 = 9 [phi:frame_maskxy::@3->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #9
    sta.z return
    rts
    // [1031] phi from frame_maskxy::@4 to frame_maskxy::@return [phi:frame_maskxy::@4->frame_maskxy::@return]
  __b5:
    // [1031] phi frame_maskxy::return#12 = 5 [phi:frame_maskxy::@4->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #5
    sta.z return
    rts
    // [1031] phi from frame_maskxy::@5 to frame_maskxy::@return [phi:frame_maskxy::@5->frame_maskxy::@return]
  __b6:
    // [1031] phi frame_maskxy::return#12 = $a [phi:frame_maskxy::@5->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$a
    sta.z return
    rts
    // [1031] phi from frame_maskxy::@6 to frame_maskxy::@return [phi:frame_maskxy::@6->frame_maskxy::@return]
  __b7:
    // [1031] phi frame_maskxy::return#12 = $e [phi:frame_maskxy::@6->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$e
    sta.z return
    rts
    // [1031] phi from frame_maskxy::@7 to frame_maskxy::@return [phi:frame_maskxy::@7->frame_maskxy::@return]
  __b8:
    // [1031] phi frame_maskxy::return#12 = $b [phi:frame_maskxy::@7->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$b
    sta.z return
    rts
    // [1031] phi from frame_maskxy::@8 to frame_maskxy::@return [phi:frame_maskxy::@8->frame_maskxy::@return]
  __b9:
    // [1031] phi frame_maskxy::return#12 = 7 [phi:frame_maskxy::@8->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #7
    sta.z return
    rts
    // [1031] phi from frame_maskxy::@9 to frame_maskxy::@return [phi:frame_maskxy::@9->frame_maskxy::@return]
  __b10:
    // [1031] phi frame_maskxy::return#12 = $d [phi:frame_maskxy::@9->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$d
    sta.z return
    // frame_maskxy::@return
    // }
    // [1032] return 
    rts
}
  // frame_char
// __zp($55) char frame_char(__zp($65) char mask)
frame_char: {
    .label return = $55
    .label mask = $65
    // case 0b0110:
    //             return 0x70;
    // [1034] if(frame_char::mask#10==6) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #6
    cmp.z mask
    beq __b1
    // frame_char::@1
    // case 0b0011:
    //             return 0x6E;
    // [1035] if(frame_char::mask#10==3) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // DR corner.
    lda #3
    cmp.z mask
    beq __b2
    // frame_char::@2
    // case 0b1100:
    //             return 0x6D;
    // [1036] if(frame_char::mask#10==$c) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // DL corner.
    lda #$c
    cmp.z mask
    beq __b3
    // frame_char::@3
    // case 0b1001:
    //             return 0x7D;
    // [1037] if(frame_char::mask#10==9) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // UR corner.
    lda #9
    cmp.z mask
    beq __b4
    // frame_char::@4
    // case 0b0101:
    //             return 0x40;
    // [1038] if(frame_char::mask#10==5) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // UL corner.
    lda #5
    cmp.z mask
    beq __b5
    // frame_char::@5
    // case 0b1010:
    //             return 0x5D;
    // [1039] if(frame_char::mask#10==$a) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // HL line.
    lda #$a
    cmp.z mask
    beq __b6
    // frame_char::@6
    // case 0b1110:
    //             return 0x6B;
    // [1040] if(frame_char::mask#10==$e) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VL line.
    lda #$e
    cmp.z mask
    beq __b7
    // frame_char::@7
    // case 0b1011:
    //             return 0x73;
    // [1041] if(frame_char::mask#10==$b) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VR junction.
    lda #$b
    cmp.z mask
    beq __b8
    // frame_char::@8
    // case 0b0111:
    //             return 0x72;
    // [1042] if(frame_char::mask#10==7) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VL junction.
    lda #7
    cmp.z mask
    beq __b9
    // frame_char::@9
    // case 0b1101:
    //             return 0x71;
    // [1043] if(frame_char::mask#10==$d) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // HD junction.
    lda #$d
    cmp.z mask
    beq __b10
    // frame_char::@10
    // case 0b1111:
    //             return 0x5B;
    // [1044] if(frame_char::mask#10==$f) goto frame_char::@11 -- vbuz1_eq_vbuc1_then_la1 
    // HU junction.
    lda #$f
    cmp.z mask
    beq __b11
    // [1046] phi from frame_char::@10 to frame_char::@return [phi:frame_char::@10->frame_char::@return]
    // [1046] phi frame_char::return#12 = $20 [phi:frame_char::@10->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$20
    sta.z return
    rts
    // [1045] phi from frame_char::@10 to frame_char::@11 [phi:frame_char::@10->frame_char::@11]
    // frame_char::@11
  __b11:
    // [1046] phi from frame_char::@11 to frame_char::@return [phi:frame_char::@11->frame_char::@return]
    // [1046] phi frame_char::return#12 = $5b [phi:frame_char::@11->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z return
    rts
    // [1046] phi from frame_char to frame_char::@return [phi:frame_char->frame_char::@return]
  __b1:
    // [1046] phi frame_char::return#12 = $70 [phi:frame_char->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$70
    sta.z return
    rts
    // [1046] phi from frame_char::@1 to frame_char::@return [phi:frame_char::@1->frame_char::@return]
  __b2:
    // [1046] phi frame_char::return#12 = $6e [phi:frame_char::@1->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6e
    sta.z return
    rts
    // [1046] phi from frame_char::@2 to frame_char::@return [phi:frame_char::@2->frame_char::@return]
  __b3:
    // [1046] phi frame_char::return#12 = $6d [phi:frame_char::@2->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6d
    sta.z return
    rts
    // [1046] phi from frame_char::@3 to frame_char::@return [phi:frame_char::@3->frame_char::@return]
  __b4:
    // [1046] phi frame_char::return#12 = $7d [phi:frame_char::@3->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$7d
    sta.z return
    rts
    // [1046] phi from frame_char::@4 to frame_char::@return [phi:frame_char::@4->frame_char::@return]
  __b5:
    // [1046] phi frame_char::return#12 = $40 [phi:frame_char::@4->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z return
    rts
    // [1046] phi from frame_char::@5 to frame_char::@return [phi:frame_char::@5->frame_char::@return]
  __b6:
    // [1046] phi frame_char::return#12 = $5d [phi:frame_char::@5->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z return
    rts
    // [1046] phi from frame_char::@6 to frame_char::@return [phi:frame_char::@6->frame_char::@return]
  __b7:
    // [1046] phi frame_char::return#12 = $6b [phi:frame_char::@6->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z return
    rts
    // [1046] phi from frame_char::@7 to frame_char::@return [phi:frame_char::@7->frame_char::@return]
  __b8:
    // [1046] phi frame_char::return#12 = $73 [phi:frame_char::@7->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z return
    rts
    // [1046] phi from frame_char::@8 to frame_char::@return [phi:frame_char::@8->frame_char::@return]
  __b9:
    // [1046] phi frame_char::return#12 = $72 [phi:frame_char::@8->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z return
    rts
    // [1046] phi from frame_char::@9 to frame_char::@return [phi:frame_char::@9->frame_char::@return]
  __b10:
    // [1046] phi frame_char::return#12 = $71 [phi:frame_char::@9->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z return
    // frame_char::@return
    // }
    // [1047] return 
    rts
}
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __zp($52) unsigned int strlen(__zp($47) char *str)
strlen: {
    .label len = $52
    .label str = $47
    .label return = $52
    // [1049] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [1049] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z len
    sta.z len+1
    // [1049] phi strlen::str#3 = strlen::str#5 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [1050] if(0!=*strlen::str#3) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [1051] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [1052] strlen::len#1 = ++ strlen::len#2 -- vwuz1=_inc_vwuz1 
    inc.z len
    bne !+
    inc.z len+1
  !:
    // str++;
    // [1053] strlen::str#0 = ++ strlen::str#3 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [1049] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [1049] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [1049] phi strlen::str#3 = strlen::str#0 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
}
  // printf_padding
// Print a padding char a number of times
// void printf_padding(__zp($47) void (*putc)(char), __zp($55) char pad, __zp($3d) char length)
printf_padding: {
    .label i = $49
    .label putc = $47
    .label length = $3d
    .label pad = $55
    // [1055] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [1055] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [1056] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z length
    bcc __b2
    // printf_padding::@return
    // }
    // [1057] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [1058] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbuz1 
    lda.z pad
    pha
    // [1059] callexecute *printf_padding::putc#7  -- call__deref_pprz1 
    jsr icall6
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [1061] printf_padding::i#1 = ++ printf_padding::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1055] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [1055] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
    jmp __b1
    // Outside Flow
  icall6:
    jmp (putc)
}
  // print_chip_led
// void print_chip_led(__zp($5d) char x, char y, __zp($5c) char w, __zp($65) char tc, char bc)
print_chip_led: {
    .label x = $5d
    .label w = $5c
    .label tc = $65
    // textcolor(tc)
    // [1063] textcolor::color#11 = print_chip_led::tc#3 -- vbuz1=vbuz2 
    lda.z tc
    sta.z textcolor.color
    // [1064] call textcolor
    // [268] phi from print_chip_led to textcolor [phi:print_chip_led->textcolor]
    // [268] phi textcolor::color#16 = textcolor::color#11 [phi:print_chip_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [1065] phi from print_chip_led to print_chip_led::@3 [phi:print_chip_led->print_chip_led::@3]
    // print_chip_led::@3
    // bgcolor(bc)
    // [1066] call bgcolor
    // [273] phi from print_chip_led::@3 to bgcolor [phi:print_chip_led::@3->bgcolor]
    // [273] phi bgcolor::color#14 = BLUE [phi:print_chip_led::@3->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [1067] phi from print_chip_led::@3 print_chip_led::@5 to print_chip_led::@1 [phi:print_chip_led::@3/print_chip_led::@5->print_chip_led::@1]
    // [1067] phi print_chip_led::w#4 = print_chip_led::w#7 [phi:print_chip_led::@3/print_chip_led::@5->print_chip_led::@1#0] -- register_copy 
    // [1067] phi print_chip_led::x#4 = print_chip_led::x#7 [phi:print_chip_led::@3/print_chip_led::@5->print_chip_led::@1#1] -- register_copy 
    // print_chip_led::@1
  __b1:
    // cputcxy(x, y, 0x6F)
    // [1068] cputcxy::x#9 = print_chip_led::x#4 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1069] call cputcxy
    // [843] phi from print_chip_led::@1 to cputcxy [phi:print_chip_led::@1->cputcxy]
    // [843] phi cputcxy::c#13 = $6f [phi:print_chip_led::@1->cputcxy#0] -- vbuz1=vbuc1 
    lda #$6f
    sta.z cputcxy.c
    // [843] phi cputcxy::y#13 = 3 [phi:print_chip_led::@1->cputcxy#1] -- vbuz1=vbuc1 
    lda #3
    sta.z cputcxy.y
    // [843] phi cputcxy::x#13 = cputcxy::x#9 [phi:print_chip_led::@1->cputcxy#2] -- register_copy 
    jsr cputcxy
    // print_chip_led::@4
    // cputcxy(x, y+1, 0x77)
    // [1070] cputcxy::x#10 = print_chip_led::x#4 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1071] call cputcxy
    // [843] phi from print_chip_led::@4 to cputcxy [phi:print_chip_led::@4->cputcxy]
    // [843] phi cputcxy::c#13 = $77 [phi:print_chip_led::@4->cputcxy#0] -- vbuz1=vbuc1 
    lda #$77
    sta.z cputcxy.c
    // [843] phi cputcxy::y#13 = 3+1 [phi:print_chip_led::@4->cputcxy#1] -- vbuz1=vbuc1 
    lda #3+1
    sta.z cputcxy.y
    // [843] phi cputcxy::x#13 = cputcxy::x#10 [phi:print_chip_led::@4->cputcxy#2] -- register_copy 
    jsr cputcxy
    // print_chip_led::@5
    // x++;
    // [1072] print_chip_led::x#0 = ++ print_chip_led::x#4 -- vbuz1=_inc_vbuz1 
    inc.z x
    // while(--w)
    // [1073] print_chip_led::w#0 = -- print_chip_led::w#4 -- vbuz1=_dec_vbuz1 
    dec.z w
    // [1074] if(0!=print_chip_led::w#0) goto print_chip_led::@1 -- 0_neq_vbuz1_then_la1 
    lda.z w
    bne __b1
    // [1075] phi from print_chip_led::@5 to print_chip_led::@2 [phi:print_chip_led::@5->print_chip_led::@2]
    // print_chip_led::@2
    // textcolor(WHITE)
    // [1076] call textcolor
    // [268] phi from print_chip_led::@2 to textcolor [phi:print_chip_led::@2->textcolor]
    // [268] phi textcolor::color#16 = WHITE [phi:print_chip_led::@2->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [1077] phi from print_chip_led::@2 to print_chip_led::@6 [phi:print_chip_led::@2->print_chip_led::@6]
    // print_chip_led::@6
    // bgcolor(BLUE)
    // [1078] call bgcolor
    // [273] phi from print_chip_led::@6 to bgcolor [phi:print_chip_led::@6->bgcolor]
    // [273] phi bgcolor::color#14 = BLUE [phi:print_chip_led::@6->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_led::@return
    // }
    // [1079] return 
    rts
}
  // print_chip_line
// void print_chip_line(char x, __zp($3e) char y, char w, __zp($5a) char c)
print_chip_line: {
    .label i = $51
    .label c = $5a
    .label y = $3e
    // gotoxy(x, y)
    // [1081] gotoxy::y#7 = print_chip_line::y#16 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1082] call gotoxy
    // [286] phi from print_chip_line to gotoxy [phi:print_chip_line->gotoxy]
    // [286] phi gotoxy::y#19 = gotoxy::y#7 [phi:print_chip_line->gotoxy#0] -- register_copy 
    // [286] phi gotoxy::x#19 = print_chip::x#0 [phi:print_chip_line->gotoxy#1] -- vbuz1=vbuc1 
    lda #print_chip.x
    sta.z gotoxy.x
    jsr gotoxy
    // [1083] phi from print_chip_line to print_chip_line::@4 [phi:print_chip_line->print_chip_line::@4]
    // print_chip_line::@4
    // textcolor(GREY)
    // [1084] call textcolor
    // [268] phi from print_chip_line::@4 to textcolor [phi:print_chip_line::@4->textcolor]
    // [268] phi textcolor::color#16 = GREY [phi:print_chip_line::@4->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [1085] phi from print_chip_line::@4 to print_chip_line::@5 [phi:print_chip_line::@4->print_chip_line::@5]
    // print_chip_line::@5
    // bgcolor(BLUE)
    // [1086] call bgcolor
    // [273] phi from print_chip_line::@5 to bgcolor [phi:print_chip_line::@5->bgcolor]
    // [273] phi bgcolor::color#14 = BLUE [phi:print_chip_line::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@6
    // cputc(VERA_CHR_UR)
    // [1087] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [1088] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [1090] call textcolor
    // [268] phi from print_chip_line::@6 to textcolor [phi:print_chip_line::@6->textcolor]
    // [268] phi textcolor::color#16 = WHITE [phi:print_chip_line::@6->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [1091] phi from print_chip_line::@6 to print_chip_line::@7 [phi:print_chip_line::@6->print_chip_line::@7]
    // print_chip_line::@7
    // bgcolor(BLACK)
    // [1092] call bgcolor
    // [273] phi from print_chip_line::@7 to bgcolor [phi:print_chip_line::@7->bgcolor]
    // [273] phi bgcolor::color#14 = BLACK [phi:print_chip_line::@7->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // [1093] phi from print_chip_line::@7 to print_chip_line::@1 [phi:print_chip_line::@7->print_chip_line::@1]
    // [1093] phi print_chip_line::i#2 = 0 [phi:print_chip_line::@7->print_chip_line::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // print_chip_line::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [1094] if(print_chip_line::i#2<print_chip::w#0) goto print_chip_line::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z i
    cmp #print_chip.w
    bcc __b2
    // [1095] phi from print_chip_line::@1 to print_chip_line::@3 [phi:print_chip_line::@1->print_chip_line::@3]
    // print_chip_line::@3
    // textcolor(GREY)
    // [1096] call textcolor
    // [268] phi from print_chip_line::@3 to textcolor [phi:print_chip_line::@3->textcolor]
    // [268] phi textcolor::color#16 = GREY [phi:print_chip_line::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [1097] phi from print_chip_line::@3 to print_chip_line::@8 [phi:print_chip_line::@3->print_chip_line::@8]
    // print_chip_line::@8
    // bgcolor(BLUE)
    // [1098] call bgcolor
    // [273] phi from print_chip_line::@8 to bgcolor [phi:print_chip_line::@8->bgcolor]
    // [273] phi bgcolor::color#14 = BLUE [phi:print_chip_line::@8->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@9
    // cputc(VERA_CHR_UL)
    // [1099] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [1100] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [1102] call textcolor
    // [268] phi from print_chip_line::@9 to textcolor [phi:print_chip_line::@9->textcolor]
    // [268] phi textcolor::color#16 = WHITE [phi:print_chip_line::@9->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [1103] phi from print_chip_line::@9 to print_chip_line::@10 [phi:print_chip_line::@9->print_chip_line::@10]
    // print_chip_line::@10
    // bgcolor(BLACK)
    // [1104] call bgcolor
    // [273] phi from print_chip_line::@10 to bgcolor [phi:print_chip_line::@10->bgcolor]
    // [273] phi bgcolor::color#14 = BLACK [phi:print_chip_line::@10->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@11
    // cputcxy(x+2, y, c)
    // [1105] cputcxy::y#8 = print_chip_line::y#16 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [1106] cputcxy::c#8 = print_chip_line::c#15 -- vbuz1=vbuz2 
    lda.z c
    sta.z cputcxy.c
    // [1107] call cputcxy
    // [843] phi from print_chip_line::@11 to cputcxy [phi:print_chip_line::@11->cputcxy]
    // [843] phi cputcxy::c#13 = cputcxy::c#8 [phi:print_chip_line::@11->cputcxy#0] -- register_copy 
    // [843] phi cputcxy::y#13 = cputcxy::y#8 [phi:print_chip_line::@11->cputcxy#1] -- register_copy 
    // [843] phi cputcxy::x#13 = print_chip::x#0+2 [phi:print_chip_line::@11->cputcxy#2] -- vbuz1=vbuc1 
    lda #print_chip.x+2
    sta.z cputcxy.x
    jsr cputcxy
    // print_chip_line::@return
    // }
    // [1108] return 
    rts
    // print_chip_line::@2
  __b2:
    // cputc(VERA_CHR_SPACE)
    // [1109] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [1110] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [1112] print_chip_line::i#1 = ++ print_chip_line::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1093] phi from print_chip_line::@2 to print_chip_line::@1 [phi:print_chip_line::@2->print_chip_line::@1]
    // [1093] phi print_chip_line::i#2 = print_chip_line::i#1 [phi:print_chip_line::@2->print_chip_line::@1#0] -- register_copy 
    jmp __b1
}
  // print_chip_end
// void print_chip_end(char x, char y, char w)
print_chip_end: {
    .label i = $4c
    // gotoxy(x, y)
    // [1114] call gotoxy
    // [286] phi from print_chip_end to gotoxy [phi:print_chip_end->gotoxy]
    // [286] phi gotoxy::y#19 = ++++++++++++++++3+2 [phi:print_chip_end->gotoxy#0] -- vbuz1=vbuc1 
    lda #3+2+1+1+1+1+1+1+1+1
    sta.z gotoxy.y
    // [286] phi gotoxy::x#19 = print_chip::x#0 [phi:print_chip_end->gotoxy#1] -- vbuz1=vbuc1 
    lda #print_chip.x
    sta.z gotoxy.x
    jsr gotoxy
    // [1115] phi from print_chip_end to print_chip_end::@4 [phi:print_chip_end->print_chip_end::@4]
    // print_chip_end::@4
    // textcolor(GREY)
    // [1116] call textcolor
    // [268] phi from print_chip_end::@4 to textcolor [phi:print_chip_end::@4->textcolor]
    // [268] phi textcolor::color#16 = GREY [phi:print_chip_end::@4->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [1117] phi from print_chip_end::@4 to print_chip_end::@5 [phi:print_chip_end::@4->print_chip_end::@5]
    // print_chip_end::@5
    // bgcolor(BLUE)
    // [1118] call bgcolor
    // [273] phi from print_chip_end::@5 to bgcolor [phi:print_chip_end::@5->bgcolor]
    // [273] phi bgcolor::color#14 = BLUE [phi:print_chip_end::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_end::@6
    // cputc(VERA_CHR_UR)
    // [1119] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [1120] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [1122] call textcolor
    // [268] phi from print_chip_end::@6 to textcolor [phi:print_chip_end::@6->textcolor]
    // [268] phi textcolor::color#16 = BLUE [phi:print_chip_end::@6->textcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z textcolor.color
    jsr textcolor
    // [1123] phi from print_chip_end::@6 to print_chip_end::@7 [phi:print_chip_end::@6->print_chip_end::@7]
    // print_chip_end::@7
    // bgcolor(BLACK)
    // [1124] call bgcolor
    // [273] phi from print_chip_end::@7 to bgcolor [phi:print_chip_end::@7->bgcolor]
    // [273] phi bgcolor::color#14 = BLACK [phi:print_chip_end::@7->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // [1125] phi from print_chip_end::@7 to print_chip_end::@1 [phi:print_chip_end::@7->print_chip_end::@1]
    // [1125] phi print_chip_end::i#2 = 0 [phi:print_chip_end::@7->print_chip_end::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // print_chip_end::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [1126] if(print_chip_end::i#2<print_chip::w#0) goto print_chip_end::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z i
    cmp #print_chip.w
    bcc __b2
    // [1127] phi from print_chip_end::@1 to print_chip_end::@3 [phi:print_chip_end::@1->print_chip_end::@3]
    // print_chip_end::@3
    // textcolor(GREY)
    // [1128] call textcolor
    // [268] phi from print_chip_end::@3 to textcolor [phi:print_chip_end::@3->textcolor]
    // [268] phi textcolor::color#16 = GREY [phi:print_chip_end::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [1129] phi from print_chip_end::@3 to print_chip_end::@8 [phi:print_chip_end::@3->print_chip_end::@8]
    // print_chip_end::@8
    // bgcolor(BLUE)
    // [1130] call bgcolor
    // [273] phi from print_chip_end::@8 to bgcolor [phi:print_chip_end::@8->bgcolor]
    // [273] phi bgcolor::color#14 = BLUE [phi:print_chip_end::@8->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_end::@9
    // cputc(VERA_CHR_UL)
    // [1131] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [1132] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_end::@return
    // }
    // [1134] return 
    rts
    // print_chip_end::@2
  __b2:
    // cputc(VERA_CHR_HL)
    // [1135] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [1136] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [1138] print_chip_end::i#1 = ++ print_chip_end::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1125] phi from print_chip_end::@2 to print_chip_end::@1 [phi:print_chip_end::@2->print_chip_end::@1]
    // [1125] phi print_chip_end::i#2 = print_chip_end::i#1 [phi:print_chip_end::@2->print_chip_end::@1#0] -- register_copy 
    jmp __b1
}
  // utoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void utoa(__zp($4f) unsigned int value, __zp($52) char *buffer, char radix)
utoa: {
    .const max_digits = 4
    .label utoa__10 = $66
    .label utoa__11 = $73
    .label digit_value = $47
    .label buffer = $52
    .label digit = $5d
    .label value = $4f
    .label started = $5c
    // [1140] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
    // [1140] phi utoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa->utoa::@1#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1140] phi utoa::started#2 = 0 [phi:utoa->utoa::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [1140] phi utoa::value#2 = smc_file_size [phi:utoa->utoa::@1#2] -- vwuz1=vwuc1 
    lda #<smc_file_size
    sta.z value
    lda #>smc_file_size
    sta.z value+1
    // [1140] phi utoa::digit#2 = 0 [phi:utoa->utoa::@1#3] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // utoa::@1
  __b1:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1141] if(utoa::digit#2<utoa::max_digits#2-1) goto utoa::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z digit
    cmp #max_digits-1
    bcc __b2
    // utoa::@3
    // *buffer++ = DIGITS[(char)value]
    // [1142] utoa::$11 = (char)utoa::value#2 -- vbuz1=_byte_vwuz2 
    lda.z value
    sta.z utoa__11
    // [1143] *utoa::buffer#11 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1144] utoa::buffer#3 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1145] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    // utoa::@return
    // }
    // [1146] return 
    rts
    // utoa::@2
  __b2:
    // unsigned int digit_value = digit_values[digit]
    // [1147] utoa::$10 = utoa::digit#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z digit
    asl
    sta.z utoa__10
    // [1148] utoa::digit_value#0 = RADIX_HEXADECIMAL_VALUES[utoa::$10] -- vwuz1=pwuc1_derefidx_vbuz2 
    tay
    lda RADIX_HEXADECIMAL_VALUES,y
    sta.z digit_value
    lda RADIX_HEXADECIMAL_VALUES+1,y
    sta.z digit_value+1
    // if (started || value >= digit_value)
    // [1149] if(0!=utoa::started#2) goto utoa::@5 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b5
    // utoa::@7
    // [1150] if(utoa::value#2>=utoa::digit_value#0) goto utoa::@5 -- vwuz1_ge_vwuz2_then_la1 
    lda.z digit_value+1
    cmp.z value+1
    bne !+
    lda.z digit_value
    cmp.z value
    beq __b5
  !:
    bcc __b5
    // [1151] phi from utoa::@7 to utoa::@4 [phi:utoa::@7->utoa::@4]
    // [1151] phi utoa::buffer#14 = utoa::buffer#11 [phi:utoa::@7->utoa::@4#0] -- register_copy 
    // [1151] phi utoa::started#4 = utoa::started#2 [phi:utoa::@7->utoa::@4#1] -- register_copy 
    // [1151] phi utoa::value#6 = utoa::value#2 [phi:utoa::@7->utoa::@4#2] -- register_copy 
    // utoa::@4
  __b4:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1152] utoa::digit#1 = ++ utoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1140] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
    // [1140] phi utoa::buffer#11 = utoa::buffer#14 [phi:utoa::@4->utoa::@1#0] -- register_copy 
    // [1140] phi utoa::started#2 = utoa::started#4 [phi:utoa::@4->utoa::@1#1] -- register_copy 
    // [1140] phi utoa::value#2 = utoa::value#6 [phi:utoa::@4->utoa::@1#2] -- register_copy 
    // [1140] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@4->utoa::@1#3] -- register_copy 
    jmp __b1
    // utoa::@5
  __b5:
    // utoa_append(buffer++, value, digit_value)
    // [1153] utoa_append::buffer#0 = utoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [1154] utoa_append::value#0 = utoa::value#2
    // [1155] utoa_append::sub#0 = utoa::digit_value#0
    // [1156] call utoa_append
    // [1218] phi from utoa::@5 to utoa_append [phi:utoa::@5->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [1157] utoa_append::return#0 = utoa_append::value#2
    // utoa::@6
    // value = utoa_append(buffer++, value, digit_value)
    // [1158] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [1159] utoa::buffer#4 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1151] phi from utoa::@6 to utoa::@4 [phi:utoa::@6->utoa::@4]
    // [1151] phi utoa::buffer#14 = utoa::buffer#4 [phi:utoa::@6->utoa::@4#0] -- register_copy 
    // [1151] phi utoa::started#4 = 1 [phi:utoa::@6->utoa::@4#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [1151] phi utoa::value#6 = utoa::value#0 [phi:utoa::@6->utoa::@4#2] -- register_copy 
    jmp __b4
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
// __zp($38) char uctoa_append(__zp($47) char *buffer, __zp($38) char value, __zp($3f) char sub)
uctoa_append: {
    .label buffer = $47
    .label value = $38
    .label sub = $3f
    .label return = $38
    .label digit = $3e
    // [1161] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [1161] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [1161] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [1162] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbuz1_ge_vbuz2_then_la1 
    lda.z value
    cmp.z sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [1163] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [1164] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [1165] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [1166] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbuz1=vbuz1_minus_vbuz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    // [1161] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [1161] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [1161] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
    jmp __b1
}
  // strupr
// Converts a string to uppercase.
// char * strupr(char *str)
strupr: {
    .label str = printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    .label strupr__0 = $3d
    .label src = $4a
    // [1168] phi from strupr to strupr::@1 [phi:strupr->strupr::@1]
    // [1168] phi strupr::src#2 = strupr::str#0 [phi:strupr->strupr::@1#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z src
    lda #>str
    sta.z src+1
    // strupr::@1
  __b1:
    // while(*src)
    // [1169] if(0!=*strupr::src#2) goto strupr::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strupr::@return
    // }
    // [1170] return 
    rts
    // strupr::@2
  __b2:
    // toupper(*src)
    // [1171] toupper::ch#0 = *strupr::src#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta.z toupper.ch
    // [1172] call toupper
    jsr toupper
    // [1173] toupper::return#3 = toupper::return#2
    // strupr::@3
    // [1174] strupr::$0 = toupper::return#3
    // *src = toupper(*src)
    // [1175] *strupr::src#2 = strupr::$0 -- _deref_pbuz1=vbuz2 
    lda.z strupr__0
    ldy #0
    sta (src),y
    // src++;
    // [1176] strupr::src#1 = ++ strupr::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1168] phi from strupr::@3 to strupr::@1 [phi:strupr::@3->strupr::@1]
    // [1168] phi strupr::src#2 = strupr::src#1 [phi:strupr::@3->strupr::@1#0] -- register_copy 
    jmp __b1
}
  // ultoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void ultoa(__zp($39) unsigned long value, __zp($58) char *buffer, char radix)
ultoa: {
    .label ultoa__10 = $5b
    .label ultoa__11 = $67
    .label digit_value = $40
    .label buffer = $58
    .label digit = $5a
    .label value = $39
    .label started = $51
    // [1178] phi from ultoa to ultoa::@1 [phi:ultoa->ultoa::@1]
    // [1178] phi ultoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:ultoa->ultoa::@1#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1178] phi ultoa::started#2 = 0 [phi:ultoa->ultoa::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [1178] phi ultoa::value#2 = ultoa::value#1 [phi:ultoa->ultoa::@1#2] -- register_copy 
    // [1178] phi ultoa::digit#2 = 0 [phi:ultoa->ultoa::@1#3] -- vbuz1=vbuc1 
    sta.z digit
    // ultoa::@1
  __b1:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1179] if(ultoa::digit#2<8-1) goto ultoa::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z digit
    cmp #8-1
    bcc __b2
    // ultoa::@3
    // *buffer++ = DIGITS[(char)value]
    // [1180] ultoa::$11 = (char)ultoa::value#2 -- vbuz1=_byte_vduz2 
    lda.z value
    sta.z ultoa__11
    // [1181] *ultoa::buffer#11 = DIGITS[ultoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1182] ultoa::buffer#3 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1183] *ultoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    // ultoa::@return
    // }
    // [1184] return 
    rts
    // ultoa::@2
  __b2:
    // unsigned long digit_value = digit_values[digit]
    // [1185] ultoa::$10 = ultoa::digit#2 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z digit
    asl
    asl
    sta.z ultoa__10
    // [1186] ultoa::digit_value#0 = RADIX_HEXADECIMAL_VALUES_LONG[ultoa::$10] -- vduz1=pduc1_derefidx_vbuz2 
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
    // [1187] if(0!=ultoa::started#2) goto ultoa::@5 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b5
    // ultoa::@7
    // [1188] if(ultoa::value#2>=ultoa::digit_value#0) goto ultoa::@5 -- vduz1_ge_vduz2_then_la1 
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
    // [1189] phi from ultoa::@7 to ultoa::@4 [phi:ultoa::@7->ultoa::@4]
    // [1189] phi ultoa::buffer#14 = ultoa::buffer#11 [phi:ultoa::@7->ultoa::@4#0] -- register_copy 
    // [1189] phi ultoa::started#4 = ultoa::started#2 [phi:ultoa::@7->ultoa::@4#1] -- register_copy 
    // [1189] phi ultoa::value#6 = ultoa::value#2 [phi:ultoa::@7->ultoa::@4#2] -- register_copy 
    // ultoa::@4
  __b4:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1190] ultoa::digit#1 = ++ ultoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1178] phi from ultoa::@4 to ultoa::@1 [phi:ultoa::@4->ultoa::@1]
    // [1178] phi ultoa::buffer#11 = ultoa::buffer#14 [phi:ultoa::@4->ultoa::@1#0] -- register_copy 
    // [1178] phi ultoa::started#2 = ultoa::started#4 [phi:ultoa::@4->ultoa::@1#1] -- register_copy 
    // [1178] phi ultoa::value#2 = ultoa::value#6 [phi:ultoa::@4->ultoa::@1#2] -- register_copy 
    // [1178] phi ultoa::digit#2 = ultoa::digit#1 [phi:ultoa::@4->ultoa::@1#3] -- register_copy 
    jmp __b1
    // ultoa::@5
  __b5:
    // ultoa_append(buffer++, value, digit_value)
    // [1191] ultoa_append::buffer#0 = ultoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z ultoa_append.buffer
    lda.z buffer+1
    sta.z ultoa_append.buffer+1
    // [1192] ultoa_append::value#0 = ultoa::value#2
    // [1193] ultoa_append::sub#0 = ultoa::digit_value#0
    // [1194] call ultoa_append
    // [1230] phi from ultoa::@5 to ultoa_append [phi:ultoa::@5->ultoa_append]
    jsr ultoa_append
    // ultoa_append(buffer++, value, digit_value)
    // [1195] ultoa_append::return#0 = ultoa_append::value#2
    // ultoa::@6
    // value = ultoa_append(buffer++, value, digit_value)
    // [1196] ultoa::value#0 = ultoa_append::return#0
    // value = ultoa_append(buffer++, value, digit_value);
    // [1197] ultoa::buffer#4 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1189] phi from ultoa::@6 to ultoa::@4 [phi:ultoa::@6->ultoa::@4]
    // [1189] phi ultoa::buffer#14 = ultoa::buffer#4 [phi:ultoa::@6->ultoa::@4#0] -- register_copy 
    // [1189] phi ultoa::started#4 = 1 [phi:ultoa::@6->ultoa::@4#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [1189] phi ultoa::value#6 = ultoa::value#0 [phi:ultoa::@6->ultoa::@4#2] -- register_copy 
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
// void memcpy8_vram_vram(__zp($25) char dbank_vram, __zp($2d) unsigned int doffset_vram, __zp($24) char sbank_vram, __zp($2a) unsigned int soffset_vram, __zp($23) char num8)
memcpy8_vram_vram: {
    .label memcpy8_vram_vram__0 = $26
    .label memcpy8_vram_vram__1 = $27
    .label memcpy8_vram_vram__2 = $24
    .label memcpy8_vram_vram__3 = $28
    .label memcpy8_vram_vram__4 = $29
    .label memcpy8_vram_vram__5 = $25
    .label num8 = $23
    .label dbank_vram = $25
    .label doffset_vram = $2d
    .label sbank_vram = $24
    .label soffset_vram = $2a
    .label num8_1 = $22
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1198] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [1199] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte0_vwuz2 
    lda.z soffset_vram
    sta.z memcpy8_vram_vram__0
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [1200] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [1201] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte1_vwuz2 
    lda.z soffset_vram+1
    sta.z memcpy8_vram_vram__1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [1202] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [1203] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuz1=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z memcpy8_vram_vram__2
    sta.z memcpy8_vram_vram__2
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [1204] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [1205] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [1206] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte0_vwuz2 
    lda.z doffset_vram
    sta.z memcpy8_vram_vram__3
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [1207] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [1208] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte1_vwuz2 
    lda.z doffset_vram+1
    sta.z memcpy8_vram_vram__4
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [1209] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [1210] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuz1=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z memcpy8_vram_vram__5
    sta.z memcpy8_vram_vram__5
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [1211] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // [1212] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [1212] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [1213] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbuz1=_dec_vbuz2 
    ldy.z num8_1
    dey
    sty.z num8
    // [1214] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbuz1_then_la1 
    lda.z num8_1
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [1215] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [1216] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [1217] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbuz1=vbuz2 
    lda.z num8
    sta.z num8_1
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
// __zp($4f) unsigned int utoa_append(__zp($5e) char *buffer, __zp($4f) unsigned int value, __zp($47) unsigned int sub)
utoa_append: {
    .label buffer = $5e
    .label value = $4f
    .label sub = $47
    .label return = $4f
    .label digit = $4c
    // [1219] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [1219] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [1219] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [1220] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwuz1_ge_vwuz2_then_la1 
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
    // [1221] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // utoa_append::@return
    // }
    // [1222] return 
    rts
    // utoa_append::@2
  __b2:
    // digit++;
    // [1223] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [1224] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    lda.z value+1
    sbc.z sub+1
    sta.z value+1
    // [1219] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [1219] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [1219] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
    jmp __b1
}
  // toupper
// Convert lowercase alphabet to uppercase
// Returns uppercase equivalent to c, if such value exists, else c remains unchanged
// __zp($3d) char toupper(__zp($3d) char ch)
toupper: {
    .label return = $3d
    .label ch = $3d
    // if(ch>='a' && ch<='z')
    // [1225] if(toupper::ch#0<'a') goto toupper::@return -- vbuz1_lt_vbuc1_then_la1 
    lda.z ch
    cmp #'a'
    bcc __breturn
    // toupper::@2
    // [1226] if(toupper::ch#0<='z') goto toupper::@1 -- vbuz1_le_vbuc1_then_la1 
    lda #'z'
    cmp.z ch
    bcs __b1
    // [1228] phi from toupper toupper::@1 toupper::@2 to toupper::@return [phi:toupper/toupper::@1/toupper::@2->toupper::@return]
    // [1228] phi toupper::return#2 = toupper::ch#0 [phi:toupper/toupper::@1/toupper::@2->toupper::@return#0] -- register_copy 
    rts
    // toupper::@1
  __b1:
    // return ch + ('A'-'a');
    // [1227] toupper::return#0 = toupper::ch#0 + 'A'-'a' -- vbuz1=vbuz1_plus_vbuc1 
    lda #'A'-'a'
    clc
    adc.z return
    sta.z return
    // toupper::@return
  __breturn:
    // }
    // [1229] return 
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
// __zp($39) unsigned long ultoa_append(__zp($5e) char *buffer, __zp($39) unsigned long value, __zp($40) unsigned long sub)
ultoa_append: {
    .label buffer = $5e
    .label value = $39
    .label sub = $40
    .label return = $39
    .label digit = $3d
    // [1231] phi from ultoa_append to ultoa_append::@1 [phi:ultoa_append->ultoa_append::@1]
    // [1231] phi ultoa_append::digit#2 = 0 [phi:ultoa_append->ultoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [1231] phi ultoa_append::value#2 = ultoa_append::value#0 [phi:ultoa_append->ultoa_append::@1#1] -- register_copy 
    // ultoa_append::@1
  __b1:
    // while (value >= sub)
    // [1232] if(ultoa_append::value#2>=ultoa_append::sub#0) goto ultoa_append::@2 -- vduz1_ge_vduz2_then_la1 
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
    // [1233] *ultoa_append::buffer#0 = DIGITS[ultoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // ultoa_append::@return
    // }
    // [1234] return 
    rts
    // ultoa_append::@2
  __b2:
    // digit++;
    // [1235] ultoa_append::digit#1 = ++ ultoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [1236] ultoa_append::value#1 = ultoa_append::value#2 - ultoa_append::sub#0 -- vduz1=vduz1_minus_vduz2 
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
    // [1231] phi from ultoa_append::@2 to ultoa_append::@1 [phi:ultoa_append::@2->ultoa_append::@1]
    // [1231] phi ultoa_append::digit#2 = ultoa_append::digit#1 [phi:ultoa_append::@2->ultoa_append::@1#0] -- register_copy 
    // [1231] phi ultoa_append::value#2 = ultoa_append::value#1 [phi:ultoa_append::@2->ultoa_append::@1#1] -- register_copy 
    jmp __b1
}
  // File Data
.segment Data
  // The digits used for numbers
  DIGITS: .text "0123456789abcdef"
  // Values of decimal digits
  RADIX_DECIMAL_VALUES_CHAR: .byte $64, $a
  // Values of hexadecimal digits
  RADIX_HEXADECIMAL_VALUES: .word $1000, $100, $10
  // Values of hexadecimal digits
  RADIX_HEXADECIMAL_VALUES_LONG: .dword $10000000, $1000000, $100000, $10000, $1000, $100, $10
  info_text: .fill $50, 0
  rom_device_names: .word 0
  .fill 2*7, 0
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
  __42: .text ""
  .byte 0
  __43: .text "Errors indicate your J1 jumpers are not properly set!"
  .byte 0
  s1: .text " "
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
