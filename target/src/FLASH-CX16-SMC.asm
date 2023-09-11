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
  .const CYAN = 3
  .const BLUE = 6
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
  .const VERA_INC_1 = $10
  .const VERA_DCSEL = 2
  .const VERA_ADDRSEL = 1
  .const VERA_LAYER_WIDTH_MASK = $30
  .const VERA_LAYER_HEIGHT_MASK = $c0
  .const SIZEOF_POINTER = 2
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
  .label __snprintf_buffer = $3d
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
    // [183] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [183] phi textcolor::color#17 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [22] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [23] call bgcolor
    // [188] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [188] phi bgcolor::color#14 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbum1=vbuc1 
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
    // [29] conio_x16_init::$4 = cbm_k_plot_get::return#2
    // BYTE1(cbm_k_plot_get())
    // [30] conio_x16_init::$5 = byte1  conio_x16_init::$4 -- vbum1=_byte1_vwum2 
    lda conio_x16_init__4+1
    sta conio_x16_init__5
    // __conio.cursor_x = BYTE1(cbm_k_plot_get())
    // [31] *((char *)&__conio) = conio_x16_init::$5 -- _deref_pbuc1=vbum1 
    sta __conio
    // cbm_k_plot_get()
    // [32] call cbm_k_plot_get
    jsr cbm_k_plot_get
    // [33] cbm_k_plot_get::return#3 = cbm_k_plot_get::return#0
    // conio_x16_init::@6
    // [34] conio_x16_init::$6 = cbm_k_plot_get::return#3
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
    // [201] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [201] phi gotoxy::y#17 = gotoxy::y#2 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [201] phi gotoxy::x#17 = gotoxy::x#2 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
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
    .label conio_x16_init__4 = cbm_k_plot_get.return
    conio_x16_init__5: .byte 0
    .label conio_x16_init__6 = cbm_k_plot_get.return
    conio_x16_init__7: .byte 0
}
.segment Code
  // cputc
// Output one character at the current cursor position
// Moves the cursor forward. Scrolls the entire screen if needed
// void cputc(__mem() char c)
cputc: {
    .const OFFSET_STACK_C = 0
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
    // [46] cputc::$1 = byte0  *((unsigned int *)&__conio+$13) -- vbum1=_byte0__deref_pwuc1 
    lda __conio+$13
    sta cputc__1
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [47] *VERA_ADDRX_L = cputc::$1 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [48] cputc::$2 = byte1  *((unsigned int *)&__conio+$13) -- vbum1=_byte1__deref_pwuc1 
    lda __conio+$13+1
    sta cputc__2
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [49] *VERA_ADDRX_M = cputc::$2 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [50] cputc::$3 = *((char *)&__conio+5) | VERA_INC_1 -- vbum1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta cputc__3
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [51] *VERA_ADDRX_H = cputc::$3 -- _deref_pbuc1=vbum1 
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
    cputc__1: .byte 0
    cputc__2: .byte 0
    cputc__3: .byte 0
    c: .byte 0
}
.segment Code
  // main
/*
unsigned long flash_smc_verify(unsigned char y, unsigned char w, unsigned char b, unsigned int r, ram_ptr_t flash_ram_address, unsigned int flash_size) {

    unsigned long flash_smc_difference = 0; /// Holds the amount of bytes that are different.
    unsigned int flash_row_total = 0;

    textcolor(WHITE);
    gotoxy(0, y);

    unsigned int smc_difference = 0;

    // We compare b bytes at a time, and each b bytes we plot a dot.
    // Every r bytes we move to the next line.
    while (smc_difference = smc_compare(flash_ram_address, b)) {

        if (flash_row_total == r) {
            gotoxy(0, ++y);
            flash_row_total = 0;
        }

        if(smc_difference)
            cputc('*');
        else
            cputc('.');

        flash_ram_address += b;
        flash_smc_difference += smc_difference;
        flash_row_total += b;
        smc_difference = 0;
    }

    // We return the total smc difference.
    return smc_difference;
}

*/
main: {
    .const bank_set_bram1_bank = 1
    .const bank_set_brom1_bank = 0
    .const bank_set_brom2_bank = 4
    .label cx16_k_screen_set_charset1_offset = $47
    .label fp = $45
    // main::CLI1
    // asm
    // asm { cli  }
    cli
    // main::@8
    // cx16_k_screen_set_charset(3, (char *)0)
    // [72] main::cx16_k_screen_set_charset1_charset = 3 -- vbum1=vbuc1 
    lda #3
    sta cx16_k_screen_set_charset1_charset
    // [73] main::cx16_k_screen_set_charset1_offset = (char *) 0 -- pbuz1=pbuc1 
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
    // [75] phi from main::cx16_k_screen_set_charset1 to main::@9 [phi:main::cx16_k_screen_set_charset1->main::@9]
    // main::@9
    // status_init()
    // [76] call status_init
    jsr status_init
    // [77] phi from main::@9 to main::@12 [phi:main::@9->main::@12]
    // main::@12
    // frame_init()
    // [78] call frame_init
    // [229] phi from main::@12 to frame_init [phi:main::@12->frame_init]
    jsr frame_init
    // [79] phi from main::@12 to main::@13 [phi:main::@12->main::@13]
    // main::@13
    // frame_draw()
    // [80] call frame_draw
    // [249] phi from main::@13 to frame_draw [phi:main::@13->frame_draw]
    jsr frame_draw
    // [81] phi from main::@13 to main::@14 [phi:main::@13->main::@14]
    // main::@14
    // gotoxy(2, 1)
    // [82] call gotoxy
    // [201] phi from main::@14 to gotoxy [phi:main::@14->gotoxy]
    // [201] phi gotoxy::y#17 = 1 [phi:main::@14->gotoxy#0] -- vbum1=vbuc1 
    lda #1
    sta gotoxy.y
    // [201] phi gotoxy::x#17 = 2 [phi:main::@14->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // [83] phi from main::@14 to main::@15 [phi:main::@14->main::@15]
    // main::@15
    // printf("commander x16 flash utility")
    // [84] call printf_str
    // [290] phi from main::@15 to printf_str [phi:main::@15->printf_str]
    // [290] phi printf_str::putc#24 = &cputc [phi:main::@15->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [290] phi printf_str::s#24 = main::s [phi:main::@15->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // [85] phi from main::@15 to main::@16 [phi:main::@15->main::@16]
    // main::@16
    // progress_clear()
    // [86] call progress_clear
    // [299] phi from main::@16 to progress_clear [phi:main::@16->progress_clear]
    jsr progress_clear
    // [87] phi from main::@16 to main::@17 [phi:main::@16->main::@17]
    // main::@17
    // info_clear_all()
    // [88] call info_clear_all
    // [314] phi from main::@17 to info_clear_all [phi:main::@17->info_clear_all]
    jsr info_clear_all
    // [89] phi from main::@17 to main::@18 [phi:main::@17->main::@18]
    // main::@18
    // print_clear()
    // [90] call print_clear
    // [324] phi from main::@18 to print_clear [phi:main::@18->print_clear]
    jsr print_clear
    // [91] phi from main::@18 to main::@19 [phi:main::@18->main::@19]
    // main::@19
    // printf("%s", "Detecting rom chipset and bootloader presence.")
    // [92] call printf_string
    // [333] phi from main::@19 to printf_string [phi:main::@19->printf_string]
    // [333] phi printf_string::str#10 = main::str [phi:main::@19->printf_string#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z printf_string.str
    lda #>str
    sta.z printf_string.str+1
    // [333] phi printf_string::format_justify_left#10 = 0 [phi:main::@19->printf_string#1] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [333] phi printf_string::format_min_length#10 = 0 [phi:main::@19->printf_string#2] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [93] phi from main::@19 to main::@20 [phi:main::@19->main::@20]
    // main::@20
    // gotoxy(0, 2)
    // [94] call gotoxy
  // info_print(0, "The SMC chip on the X16 board controls the power on/off, keyboard and mouse pheripherals.");
  // info_print(1, "It is essential that the SMC chip gets updated together with the latest ROM on the X16 board.");
  // info_print(2, "On the X16 board, near the SMC chip are two jumpers");
    // [201] phi from main::@20 to gotoxy [phi:main::@20->gotoxy]
    // [201] phi gotoxy::y#17 = 2 [phi:main::@20->gotoxy#0] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.y
    // [201] phi gotoxy::x#17 = 0 [phi:main::@20->gotoxy#1] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.x
    jsr gotoxy
    // main::bank_set_bram1
    // BRAM = bank
    // [95] BRAM = main::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // main::bank_set_brom1
    // BROM = bank
    // [96] BROM = main::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [97] phi from main::bank_set_brom1 to main::@10 [phi:main::bank_set_brom1->main::@10]
    // main::@10
    // flash_smc_detect()
    // [98] call flash_smc_detect
    jsr flash_smc_detect
    // [99] flash_smc_detect::return#4 = flash_smc_detect::return#1
    // main::@21
    // smc_bootloader = flash_smc_detect()
    // [100] smc_bootloader#0 = flash_smc_detect::return#4 -- vwum1=vwum2 
    lda flash_smc_detect.return
    sta smc_bootloader
    lda flash_smc_detect.return+1
    sta smc_bootloader+1
    // print_smc_led(WHITE)
    // [101] call print_smc_led
  // if(smc_bootloader == 0x0200) {
  //     print_clear(); printf("there was an error reading the i2c api. exiting ...");
  //     wait_key();
  //     return;
  // }
    // [366] phi from main::@21 to print_smc_led [phi:main::@21->print_smc_led]
    // [366] phi print_smc_led::c#3 = WHITE [phi:main::@21->print_smc_led#0] -- vbum1=vbuc1 
    lda #WHITE
    sta print_smc_led.c
    jsr print_smc_led
    // [102] phi from main::@21 to main::@22 [phi:main::@21->main::@22]
    // main::@22
    // rom_detect()
    // [103] call rom_detect
  // Detecting ROM chips
    // [370] phi from main::@22 to rom_detect [phi:main::@22->rom_detect]
    jsr rom_detect
    // [104] phi from main::@22 to main::@23 [phi:main::@22->main::@23]
    // main::@23
    // print_smc_chip()
    // [105] call print_smc_chip
    // [416] phi from main::@23 to print_smc_chip [phi:main::@23->print_smc_chip]
    jsr print_smc_chip
    // [106] phi from main::@23 to main::@24 [phi:main::@23->main::@24]
    // main::@24
    // print_vera_chip()
    // [107] call print_vera_chip
    // [421] phi from main::@24 to print_vera_chip [phi:main::@24->print_vera_chip]
    jsr print_vera_chip
    // [108] phi from main::@24 to main::@25 [phi:main::@24->main::@25]
    // main::@25
    // print_rom_chips()
    // [109] call print_rom_chips
    // [426] phi from main::@25 to print_rom_chips [phi:main::@25->print_rom_chips]
    jsr print_rom_chips
    // [110] phi from main::@25 to main::@26 [phi:main::@25->main::@26]
    // main::@26
    // print_clear()
    // [111] call print_clear
    // [324] phi from main::@26 to print_clear [phi:main::@26->print_clear]
    jsr print_clear
    // [112] phi from main::@26 to main::@27 [phi:main::@26->main::@27]
    // main::@27
    // printf("This x16 board has an SMC chip bootloader, version %u", smc_bootloader)
    // [113] call printf_str
    // [290] phi from main::@27 to printf_str [phi:main::@27->printf_str]
    // [290] phi printf_str::putc#24 = &cputc [phi:main::@27->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [290] phi printf_str::s#24 = main::s1 [phi:main::@27->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // main::@28
    // printf("This x16 board has an SMC chip bootloader, version %u", smc_bootloader)
    // [114] printf_uint::uvalue#1 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta printf_uint.uvalue
    lda smc_bootloader+1
    sta printf_uint.uvalue+1
    // [115] call printf_uint
    // [444] phi from main::@28 to printf_uint [phi:main::@28->printf_uint]
    // [444] phi printf_uint::uvalue#2 = printf_uint::uvalue#1 [phi:main::@28->printf_uint#0] -- register_copy 
    jsr printf_uint
    // [116] phi from main::@28 to main::@29 [phi:main::@28->main::@29]
    // main::@29
    // info_smc(STATUS_DETECTED)
    // [117] call info_smc
    // [451] phi from main::@29 to info_smc [phi:main::@29->info_smc]
    jsr info_smc
    // [118] phi from main::@29 to main::@30 [phi:main::@29->main::@30]
    // main::@30
    // info_vera(STATUS_DETECTED)
    // [119] call info_vera
  // Set the info for the SMC to Detected.
    // [464] phi from main::@30 to info_vera [phi:main::@30->info_vera]
    jsr info_vera
    // [120] phi from main::@30 to main::@3 [phi:main::@30->main::@3]
    // [120] phi main::rom_chip#2 = 0 [phi:main::@30->main::@3#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
  // Set the info for the VERA to Detected.
    // main::@3
  __b3:
    // for(char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [121] if(main::rom_chip#2<8) goto main::@4 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcs !__b4+
    jmp __b4
  !__b4:
    // [122] phi from main::@3 to main::@5 [phi:main::@3->main::@5]
    // main::@5
    // wait_key()
    // [123] call wait_key
    // [471] phi from main::@5 to wait_key [phi:main::@5->wait_key]
    jsr wait_key
    // [124] phi from main::@5 to main::@32 [phi:main::@5->main::@32]
    // main::@32
    // print_clear()
    // [125] call print_clear
    // [324] phi from main::@32 to print_clear [phi:main::@32->print_clear]
    jsr print_clear
    // [126] phi from main::@32 to main::@33 [phi:main::@32->main::@33]
    // main::@33
    // printf("opening %s.", file)
    // [127] call printf_str
    // [290] phi from main::@33 to printf_str [phi:main::@33->printf_str]
    // [290] phi printf_str::putc#24 = &cputc [phi:main::@33->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [290] phi printf_str::s#24 = main::s2 [phi:main::@33->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // [128] phi from main::@33 to main::@34 [phi:main::@33->main::@34]
    // main::@34
    // printf("opening %s.", file)
    // [129] call printf_string
    // [333] phi from main::@34 to printf_string [phi:main::@34->printf_string]
    // [333] phi printf_string::str#10 = file [phi:main::@34->printf_string#0] -- pbuz1=pbuc1 
    lda #<file
    sta.z printf_string.str
    lda #>file
    sta.z printf_string.str+1
    // [333] phi printf_string::format_justify_left#10 = 0 [phi:main::@34->printf_string#1] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [333] phi printf_string::format_min_length#10 = 0 [phi:main::@34->printf_string#2] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [130] phi from main::@34 to main::@35 [phi:main::@34->main::@35]
    // main::@35
    // printf("opening %s.", file)
    // [131] call printf_str
    // [290] phi from main::@35 to printf_str [phi:main::@35->printf_str]
    // [290] phi printf_str::putc#24 = &cputc [phi:main::@35->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [290] phi printf_str::s#24 = s2 [phi:main::@35->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s2
    sta.z printf_str.s
    lda #>@s2
    sta.z printf_str.s+1
    jsr printf_str
    // [132] phi from main::@35 to main::@36 [phi:main::@35->main::@36]
    // main::@36
    // strcpy(file, "smc.bin")
    // [133] call strcpy
    // [482] phi from main::@36 to strcpy [phi:main::@36->strcpy]
    // [482] phi strcpy::dst#0 = file [phi:main::@36->strcpy#0] -- pbuz1=pbuc1 
    lda #<file
    sta.z strcpy.dst
    lda #>file
    sta.z strcpy.dst+1
    // [482] phi strcpy::src#0 = main::source [phi:main::@36->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // [134] phi from main::@36 to main::@37 [phi:main::@36->main::@37]
    // main::@37
    // FILE *fp = fopen(file,"r")
    // [135] call fopen
    // Read the smc file content.
    jsr fopen
    // [136] fopen::return#3 = fopen::return#2
    // main::@38
    // [137] main::fp#0 = fopen::return#3 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [138] if((struct $2 *)0!=main::fp#0) goto main::@1 -- pssc1_neq_pssz1_then_la1 
    cmp #>0
    bne __b1
    lda.z fp
    cmp #<0
    bne __b1
    // [139] phi from main::@38 to main::@6 [phi:main::@38->main::@6]
    // main::@6
    // print_clear()
    // [140] call print_clear
    // [324] phi from main::@6 to print_clear [phi:main::@6->print_clear]
    jsr print_clear
    // [141] phi from main::@6 to main::@45 [phi:main::@6->main::@45]
    // main::@45
    // printf("there is no smc.bin file on the sdcard to flash the smc chip. press a key ...")
    // [142] call printf_str
    // [290] phi from main::@45 to printf_str [phi:main::@45->printf_str]
    // [290] phi printf_str::putc#24 = &cputc [phi:main::@45->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [290] phi printf_str::s#24 = main::s5 [phi:main::@45->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // [143] phi from main::@45 to main::@46 [phi:main::@45->main::@46]
    // main::@46
    // gotoxy(2, 58)
    // [144] call gotoxy
    // [201] phi from main::@46 to gotoxy [phi:main::@46->gotoxy]
    // [201] phi gotoxy::y#17 = $3a [phi:main::@46->gotoxy#0] -- vbum1=vbuc1 
    lda #$3a
    sta gotoxy.y
    // [201] phi gotoxy::x#17 = 2 [phi:main::@46->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // [145] phi from main::@46 to main::@47 [phi:main::@46->main::@47]
    // main::@47
    // printf("no file")
    // [146] call printf_str
    // [290] phi from main::@47 to printf_str [phi:main::@47->printf_str]
    // [290] phi printf_str::putc#24 = &cputc [phi:main::@47->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [290] phi printf_str::s#24 = main::s6 [phi:main::@47->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // main::bank_set_brom2
  bank_set_brom2:
    // BROM = bank
    // [147] BROM = main::bank_set_brom2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom2_bank
    sta.z BROM
    // main::CLI2
    // asm
    // asm { cli  }
    cli
    // [149] phi from main::CLI2 to main::@11 [phi:main::CLI2->main::@11]
    // main::@11
    // wait_key()
    // [150] call wait_key
    // [471] phi from main::@11 to wait_key [phi:main::@11->wait_key]
    jsr wait_key
    // main::SEI1
    // asm
    // asm { sei  }
    sei
    // main::@return
    // }
    // [152] return 
    rts
    // [153] phi from main::@38 to main::@1 [phi:main::@38->main::@1]
    // main::@1
  __b1:
    // progress_clear()
    // [154] call progress_clear
    // [299] phi from main::@1 to progress_clear [phi:main::@1->progress_clear]
    jsr progress_clear
    // [155] phi from main::@1 to main::@39 [phi:main::@1->main::@39]
    // main::@39
    // textcolor(WHITE)
    // [156] call textcolor
    // [183] phi from main::@39 to textcolor [phi:main::@39->textcolor]
    // [183] phi textcolor::color#17 = WHITE [phi:main::@39->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [157] phi from main::@39 to main::@40 [phi:main::@39->main::@40]
    // main::@40
    // print_smc_led(CYAN)
    // [158] call print_smc_led
  // We first detect if there is a bootloader routine present on the SMC.
  // In the case there isn't a bootloader, the X16 board update process cannot continue
  // and a manual update process needs to be conducted. 
    // [366] phi from main::@40 to print_smc_led [phi:main::@40->print_smc_led]
    // [366] phi print_smc_led::c#3 = CYAN [phi:main::@40->print_smc_led#0] -- vbum1=vbuc1 
    lda #CYAN
    sta print_smc_led.c
    jsr print_smc_led
    // [159] phi from main::@40 to main::@41 [phi:main::@40->main::@41]
    // main::@41
    // print_clear()
    // [160] call print_clear
    // [324] phi from main::@41 to print_clear [phi:main::@41->print_clear]
    jsr print_clear
    // [161] phi from main::@41 to main::@42 [phi:main::@41->main::@42]
    // main::@42
    // printf("reading data for smc update in ram ...")
    // [162] call printf_str
    // [290] phi from main::@42 to printf_str [phi:main::@42->printf_str]
    // [290] phi printf_str::putc#24 = &cputc [phi:main::@42->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [290] phi printf_str::s#24 = main::s4 [phi:main::@42->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // main::@43
    // unsigned long flash_bytes = flash_read(17, 64, 4, 256, fp, (ram_ptr_t)0x4000)
    // [163] flash_read::fp#0 = main::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z flash_read.fp
    lda.z fp+1
    sta.z flash_read.fp+1
    // [164] call flash_read
    // [569] phi from main::@43 to flash_read [phi:main::@43->flash_read]
    jsr flash_read
    // unsigned long flash_bytes = flash_read(17, 64, 4, 256, fp, (ram_ptr_t)0x4000)
    // [165] flash_read::return#2 = flash_read::flash_bytes#2
    // main::@44
    // [166] main::flash_bytes#0 = flash_read::return#2
    // if (flash_bytes == 0)
    // [167] if(main::flash_bytes#0!=0) goto main::@7 -- vdum1_neq_0_then_la1 
    lda flash_bytes
    ora flash_bytes+1
    ora flash_bytes+2
    ora flash_bytes+3
    bne __b7
    // [168] phi from main::@44 to main::@2 [phi:main::@44->main::@2]
    // main::@2
    // printf("error reading file.")
    // [169] call printf_str
    // [290] phi from main::@2 to printf_str [phi:main::@2->printf_str]
    // [290] phi printf_str::putc#24 = &cputc [phi:main::@2->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [290] phi printf_str::s#24 = main::s8 [phi:main::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    rts
    // main::@7
  __b7:
    // fclose(fp)
    // [170] fclose::stream#0 = main::fp#0
    // [171] call fclose
    jsr fclose
    // [172] phi from main::@7 to main::@48 [phi:main::@7->main::@48]
    // main::@48
    // print_clear()
    // [173] call print_clear
  // Now we compare the smc update data with the actual smc contents before flashing.
  // If everything is the same, we don't flash.
    // [324] phi from main::@48 to print_clear [phi:main::@48->print_clear]
    jsr print_clear
    // [174] phi from main::@48 to main::@49 [phi:main::@48->main::@49]
    // main::@49
    // printf("comparing smc with update ... (.) same, (*) different.")
    // [175] call printf_str
    // [290] phi from main::@49 to printf_str [phi:main::@49->printf_str]
    // [290] phi printf_str::putc#24 = &cputc [phi:main::@49->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [290] phi printf_str::s#24 = main::s7 [phi:main::@49->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    jmp bank_set_brom2
    // main::@4
  __b4:
    // info_rom(rom_chip, STATUS_DETECTED)
    // [176] info_rom::info_rom#0 = main::rom_chip#2 -- vbum1=vbum2 
    lda rom_chip
    sta info_rom.info_rom
    // [177] call info_rom
    jsr info_rom
    // main::@31
    // for(char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [178] main::rom_chip#1 = ++ main::rom_chip#2 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [120] phi from main::@31 to main::@3 [phi:main::@31->main::@3]
    // [120] phi main::rom_chip#2 = main::rom_chip#1 [phi:main::@31->main::@3#0] -- register_copy 
    jmp __b3
  .segment Data
    s: .text "commander x16 flash utility"
    .byte 0
    str: .text "Detecting rom chipset and bootloader presence."
    .byte 0
    s1: .text "This x16 board has an SMC chip bootloader, version "
    .byte 0
    s2: .text "opening "
    .byte 0
    source: .text "smc.bin"
    .byte 0
    s4: .text "reading data for smc update in ram ..."
    .byte 0
    s5: .text "there is no smc.bin file on the sdcard to flash the smc chip. press a key ..."
    .byte 0
    s6: .text "no file"
    .byte 0
    s7: .text "comparing smc with update ... (.) same, (*) different."
    .byte 0
    s8: .text "error reading file."
    .byte 0
    cx16_k_screen_set_charset1_charset: .byte 0
    rom_chip: .byte 0
    .label flash_bytes = flash_read.flash_bytes
}
.segment Code
  // screenlayer1
// Set the layer with which the conio will interact.
screenlayer1: {
    // screenlayer(1, *VERA_L1_MAPBASE, *VERA_L1_CONFIG)
    // [179] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbum1=_deref_pbuc1 
    lda VERA_L1_MAPBASE
    sta screenlayer.mapbase
    // [180] screenlayer::config#0 = *VERA_L1_CONFIG -- vbum1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta screenlayer.config
    // [181] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [182] return 
    rts
}
  // textcolor
// Set the front color for text output. The old front text color setting is returned.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char textcolor(__mem() char color)
textcolor: {
    // __conio.color & 0xF0
    // [184] textcolor::$0 = *((char *)&__conio+$d) & $f0 -- vbum1=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$d
    sta textcolor__0
    // __conio.color & 0xF0 | color
    // [185] textcolor::$1 = textcolor::$0 | textcolor::color#17 -- vbum1=vbum2_bor_vbum1 
    lda textcolor__1
    ora textcolor__0
    sta textcolor__1
    // __conio.color = __conio.color & 0xF0 | color
    // [186] *((char *)&__conio+$d) = textcolor::$1 -- _deref_pbuc1=vbum1 
    sta __conio+$d
    // textcolor::@return
    // }
    // [187] return 
    rts
  .segment Data
    textcolor__0: .byte 0
    .label textcolor__1 = color
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
    // __conio.color & 0x0F
    // [189] bgcolor::$0 = *((char *)&__conio+$d) & $f -- vbum1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$d
    sta bgcolor__0
    // color << 4
    // [190] bgcolor::$1 = bgcolor::color#14 << 4 -- vbum1=vbum1_rol_4 
    lda bgcolor__1
    asl
    asl
    asl
    asl
    sta bgcolor__1
    // __conio.color & 0x0F | color << 4
    // [191] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbum1=vbum1_bor_vbum2 
    lda bgcolor__2
    ora bgcolor__1
    sta bgcolor__2
    // __conio.color = __conio.color & 0x0F | color << 4
    // [192] *((char *)&__conio+$d) = bgcolor::$2 -- _deref_pbuc1=vbum1 
    sta __conio+$d
    // bgcolor::@return
    // }
    // [193] return 
    rts
  .segment Data
    bgcolor__0: .byte 0
    .label bgcolor__1 = color
    .label bgcolor__2 = bgcolor__0
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
    // [194] *((char *)&__conio+$c) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$c
    // cursor::@return
    // }
    // [195] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    // __mem unsigned char x
    // [196] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [197] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [199] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwum1=vbum2_word_vbum3 
    lda x
    sta return+1
    lda y
    sta return
    // cbm_k_plot_get::@return
    // }
    // [200] return 
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
    // (x>=__conio.width)?__conio.width:x
    // [202] if(gotoxy::x#17>=*((char *)&__conio+6)) goto gotoxy::@1 -- vbum1_ge__deref_pbuc1_then_la1 
    lda x
    cmp __conio+6
    bcs __b1
    // [204] phi from gotoxy gotoxy::@1 to gotoxy::@2 [phi:gotoxy/gotoxy::@1->gotoxy::@2]
    // [204] phi gotoxy::$3 = gotoxy::x#17 [phi:gotoxy/gotoxy::@1->gotoxy::@2#0] -- register_copy 
    jmp __b2
    // gotoxy::@1
  __b1:
    // [203] gotoxy::$2 = *((char *)&__conio+6) -- vbum1=_deref_pbuc1 
    lda __conio+6
    sta gotoxy__2
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [205] *((char *)&__conio) = gotoxy::$3 -- _deref_pbuc1=vbum1 
    lda gotoxy__3
    sta __conio
    // (y>=__conio.height)?__conio.height:y
    // [206] if(gotoxy::y#17>=*((char *)&__conio+7)) goto gotoxy::@3 -- vbum1_ge__deref_pbuc1_then_la1 
    lda y
    cmp __conio+7
    bcs __b3
    // gotoxy::@4
    // [207] gotoxy::$14 = gotoxy::y#17 -- vbum1=vbum2 
    sta gotoxy__14
    // [208] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [208] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [209] *((char *)&__conio+1) = gotoxy::$7 -- _deref_pbuc1=vbum1 
    lda gotoxy__7
    sta __conio+1
    // __conio.cursor_x << 1
    // [210] gotoxy::$8 = *((char *)&__conio) << 1 -- vbum1=_deref_pbuc1_rol_1 
    lda __conio
    asl
    sta gotoxy__8
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [211] gotoxy::$10 = gotoxy::y#17 << 1 -- vbum1=vbum1_rol_1 
    asl gotoxy__10
    // [212] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwum1=pwuc1_derefidx_vbum2_plus_vbum3 
    ldy gotoxy__10
    clc
    adc __conio+$15,y
    sta gotoxy__9
    lda __conio+$15+1,y
    adc #0
    sta gotoxy__9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [213] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwum1 
    lda gotoxy__9
    sta __conio+$13
    lda gotoxy__9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [214] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [215] gotoxy::$6 = *((char *)&__conio+7) -- vbum1=_deref_pbuc1 
    lda __conio+7
    sta gotoxy__6
    jmp __b5
  .segment Data
    .label gotoxy__2 = gotoxy__3
    gotoxy__3: .byte 0
    .label gotoxy__6 = gotoxy__7
    gotoxy__7: .byte 0
    gotoxy__8: .byte 0
    gotoxy__9: .word 0
    .label gotoxy__10 = y
    .label x = gotoxy__3
    y: .byte 0
    .label gotoxy__14 = gotoxy__7
}
.segment Code
  // cputln
// Print a newline
cputln: {
    // __conio.cursor_x = 0
    // [216] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y++;
    // [217] *((char *)&__conio+1) = ++ *((char *)&__conio+1) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+1
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [218] cputln::$2 = *((char *)&__conio+1) << 1 -- vbum1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta cputln__2
    // [219] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbum1 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [220] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [221] return 
    rts
  .segment Data
    cputln__2: .byte 0
}
.segment Code
  // status_init
status_init: {
    // status_text[STATUS_DETECTED] = "Detected"
    // [222] *status_text = status_init::$6 -- _deref_qbuc1=pbuc2 
    lda #<status_init__6
    sta status_text
    lda #>status_init__6
    sta status_text+1
    // status_text[STATUS_NONE] = "None"
    // [223] *(status_text+1*SIZEOF_POINTER) = status_init::$7 -- _deref_qbuc1=pbuc2 
    lda #<status_init__7
    sta status_text+1*SIZEOF_POINTER
    lda #>status_init__7
    sta status_text+1*SIZEOF_POINTER+1
    // status_text[STATUS_CHECKING] = "Checking"
    // [224] *(status_text+2*SIZEOF_POINTER) = status_init::$8 -- _deref_qbuc1=pbuc2 
    lda #<status_init__8
    sta status_text+2*SIZEOF_POINTER
    lda #>status_init__8
    sta status_text+2*SIZEOF_POINTER+1
    // status_text[STATUS_FLASHING] = "Flashing"
    // [225] *(status_text+3*SIZEOF_POINTER) = status_init::$9 -- _deref_qbuc1=pbuc2 
    lda #<status_init__9
    sta status_text+3*SIZEOF_POINTER
    lda #>status_init__9
    sta status_text+3*SIZEOF_POINTER+1
    // status_text[STATUS_UPDATED] = "Updated"
    // [226] *(status_text+4*SIZEOF_POINTER) = status_init::$10 -- _deref_qbuc1=pbuc2 
    lda #<status_init__10
    sta status_text+4*SIZEOF_POINTER
    lda #>status_init__10
    sta status_text+4*SIZEOF_POINTER+1
    // status_text[STATUS_ERROR] = "Error"
    // [227] *(status_text+5*SIZEOF_POINTER) = status_init::$11 -- _deref_qbuc1=pbuc2 
    lda #<status_init__11
    sta status_text+5*SIZEOF_POINTER
    lda #>status_init__11
    sta status_text+5*SIZEOF_POINTER+1
    // status_init::@return
    // }
    // [228] return 
    rts
  .segment Data
    status_init__6: .text "Detected"
    .byte 0
    status_init__7: .text "None"
    .byte 0
    status_init__8: .text "Checking"
    .byte 0
    status_init__9: .text "Flashing"
    .byte 0
    status_init__10: .text "Updated"
    .byte 0
    status_init__11: .text "Error"
    .byte 0
}
.segment Code
  // frame_init
frame_init: {
    .const vera_display_set_hstart1_start = $b
    .const vera_display_set_hstop1_stop = $93
    .const vera_display_set_vstart1_start = $13
    .const vera_display_set_vstop1_stop = $db
    .label cx16_k_screen_set_charset1_offset = $41
    // textcolor(WHITE)
    // [230] call textcolor
  // Set the charset to lower case.
  // screenlayer1();
    // [183] phi from frame_init to textcolor [phi:frame_init->textcolor]
    // [183] phi textcolor::color#17 = WHITE [phi:frame_init->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [231] phi from frame_init to frame_init::@2 [phi:frame_init->frame_init::@2]
    // frame_init::@2
    // bgcolor(BLUE)
    // [232] call bgcolor
    // [188] phi from frame_init::@2 to bgcolor [phi:frame_init::@2->bgcolor]
    // [188] phi bgcolor::color#14 = BLUE [phi:frame_init::@2->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [233] phi from frame_init::@2 to frame_init::@3 [phi:frame_init::@2->frame_init::@3]
    // frame_init::@3
    // scroll(0)
    // [234] call scroll
    jsr scroll
    // [235] phi from frame_init::@3 to frame_init::@4 [phi:frame_init::@3->frame_init::@4]
    // frame_init::@4
    // clrscr()
    // [236] call clrscr
    jsr clrscr
    // frame_init::vera_display_set_hstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [237] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTART = start
    // [238] *VERA_DC_HSTART = frame_init::vera_display_set_hstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstart1_start
    sta VERA_DC_HSTART
    // frame_init::vera_display_set_hstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [239] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTOP = stop
    // [240] *VERA_DC_HSTOP = frame_init::vera_display_set_hstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstop1_stop
    sta VERA_DC_HSTOP
    // frame_init::vera_display_set_vstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [241] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTART = start
    // [242] *VERA_DC_VSTART = frame_init::vera_display_set_vstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstart1_start
    sta VERA_DC_VSTART
    // frame_init::vera_display_set_vstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [243] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTOP = stop
    // [244] *VERA_DC_VSTOP = frame_init::vera_display_set_vstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstop1_stop
    sta VERA_DC_VSTOP
    // frame_init::@1
    // cx16_k_screen_set_charset(3, (char *)0)
    // [245] frame_init::cx16_k_screen_set_charset1_charset = 3 -- vbum1=vbuc1 
    lda #3
    sta cx16_k_screen_set_charset1_charset
    // [246] frame_init::cx16_k_screen_set_charset1_offset = (char *) 0 -- pbuz1=pbuc1 
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
    // [248] return 
    rts
  .segment Data
    cx16_k_screen_set_charset1_charset: .byte 0
}
.segment Code
  // frame_draw
frame_draw: {
    // textcolor(WHITE)
    // [250] call textcolor
    // [183] phi from frame_draw to textcolor [phi:frame_draw->textcolor]
    // [183] phi textcolor::color#17 = WHITE [phi:frame_draw->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [251] phi from frame_draw to frame_draw::@1 [phi:frame_draw->frame_draw::@1]
    // frame_draw::@1
    // bgcolor(BLUE)
    // [252] call bgcolor
    // [188] phi from frame_draw::@1 to bgcolor [phi:frame_draw::@1->bgcolor]
    // [188] phi bgcolor::color#14 = BLUE [phi:frame_draw::@1->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [253] phi from frame_draw::@1 to frame_draw::@2 [phi:frame_draw::@1->frame_draw::@2]
    // frame_draw::@2
    // clrscr()
    // [254] call clrscr
    jsr clrscr
    // [255] phi from frame_draw::@2 to frame_draw::@3 [phi:frame_draw::@2->frame_draw::@3]
    // frame_draw::@3
    // frame(0, 0, 67, 15)
    // [256] call frame
    // [740] phi from frame_draw::@3 to frame [phi:frame_draw::@3->frame]
    // [740] phi frame::y#0 = 0 [phi:frame_draw::@3->frame#0] -- vbum1=vbuc1 
    lda #0
    sta frame.y
    // [740] phi frame::y1#16 = $f [phi:frame_draw::@3->frame#1] -- vbum1=vbuc1 
    lda #$f
    sta frame.y1
    // [740] phi frame::x#0 = 0 [phi:frame_draw::@3->frame#2] -- vbum1=vbuc1 
    lda #0
    sta frame.x
    // [740] phi frame::x1#16 = $43 [phi:frame_draw::@3->frame#3] -- vbum1=vbuc1 
    lda #$43
    sta frame.x1
    jsr frame
    // [257] phi from frame_draw::@3 to frame_draw::@4 [phi:frame_draw::@3->frame_draw::@4]
    // frame_draw::@4
    // frame(0, 0, 67, 2)
    // [258] call frame
    // [740] phi from frame_draw::@4 to frame [phi:frame_draw::@4->frame]
    // [740] phi frame::y#0 = 0 [phi:frame_draw::@4->frame#0] -- vbum1=vbuc1 
    lda #0
    sta frame.y
    // [740] phi frame::y1#16 = 2 [phi:frame_draw::@4->frame#1] -- vbum1=vbuc1 
    lda #2
    sta frame.y1
    // [740] phi frame::x#0 = 0 [phi:frame_draw::@4->frame#2] -- vbum1=vbuc1 
    lda #0
    sta frame.x
    // [740] phi frame::x1#16 = $43 [phi:frame_draw::@4->frame#3] -- vbum1=vbuc1 
    lda #$43
    sta frame.x1
    jsr frame
    // [259] phi from frame_draw::@4 to frame_draw::@5 [phi:frame_draw::@4->frame_draw::@5]
    // frame_draw::@5
    // frame(0, 2, 67, 13)
    // [260] call frame
    // [740] phi from frame_draw::@5 to frame [phi:frame_draw::@5->frame]
    // [740] phi frame::y#0 = 2 [phi:frame_draw::@5->frame#0] -- vbum1=vbuc1 
    lda #2
    sta frame.y
    // [740] phi frame::y1#16 = $d [phi:frame_draw::@5->frame#1] -- vbum1=vbuc1 
    lda #$d
    sta frame.y1
    // [740] phi frame::x#0 = 0 [phi:frame_draw::@5->frame#2] -- vbum1=vbuc1 
    lda #0
    sta frame.x
    // [740] phi frame::x1#16 = $43 [phi:frame_draw::@5->frame#3] -- vbum1=vbuc1 
    lda #$43
    sta frame.x1
    jsr frame
    // [261] phi from frame_draw::@5 to frame_draw::@6 [phi:frame_draw::@5->frame_draw::@6]
    // frame_draw::@6
    // frame(0, 13, 67, 15)
    // [262] call frame
    // [740] phi from frame_draw::@6 to frame [phi:frame_draw::@6->frame]
    // [740] phi frame::y#0 = $d [phi:frame_draw::@6->frame#0] -- vbum1=vbuc1 
    lda #$d
    sta frame.y
    // [740] phi frame::y1#16 = $f [phi:frame_draw::@6->frame#1] -- vbum1=vbuc1 
    lda #$f
    sta frame.y1
    // [740] phi frame::x#0 = 0 [phi:frame_draw::@6->frame#2] -- vbum1=vbuc1 
    lda #0
    sta frame.x
    // [740] phi frame::x1#16 = $43 [phi:frame_draw::@6->frame#3] -- vbum1=vbuc1 
    lda #$43
    sta frame.x1
    jsr frame
    // [263] phi from frame_draw::@6 to frame_draw::@7 [phi:frame_draw::@6->frame_draw::@7]
    // frame_draw::@7
    // frame(0, 2, 8, 13)
    // [264] call frame
    // [740] phi from frame_draw::@7 to frame [phi:frame_draw::@7->frame]
    // [740] phi frame::y#0 = 2 [phi:frame_draw::@7->frame#0] -- vbum1=vbuc1 
    lda #2
    sta frame.y
    // [740] phi frame::y1#16 = $d [phi:frame_draw::@7->frame#1] -- vbum1=vbuc1 
    lda #$d
    sta frame.y1
    // [740] phi frame::x#0 = 0 [phi:frame_draw::@7->frame#2] -- vbum1=vbuc1 
    lda #0
    sta frame.x
    // [740] phi frame::x1#16 = 8 [phi:frame_draw::@7->frame#3] -- vbum1=vbuc1 
    lda #8
    sta frame.x1
    jsr frame
    // [265] phi from frame_draw::@7 to frame_draw::@8 [phi:frame_draw::@7->frame_draw::@8]
    // frame_draw::@8
    // frame(8, 2, 19, 13)
    // [266] call frame
    // [740] phi from frame_draw::@8 to frame [phi:frame_draw::@8->frame]
    // [740] phi frame::y#0 = 2 [phi:frame_draw::@8->frame#0] -- vbum1=vbuc1 
    lda #2
    sta frame.y
    // [740] phi frame::y1#16 = $d [phi:frame_draw::@8->frame#1] -- vbum1=vbuc1 
    lda #$d
    sta frame.y1
    // [740] phi frame::x#0 = 8 [phi:frame_draw::@8->frame#2] -- vbum1=vbuc1 
    lda #8
    sta frame.x
    // [740] phi frame::x1#16 = $13 [phi:frame_draw::@8->frame#3] -- vbum1=vbuc1 
    lda #$13
    sta frame.x1
    jsr frame
    // [267] phi from frame_draw::@8 to frame_draw::@9 [phi:frame_draw::@8->frame_draw::@9]
    // frame_draw::@9
    // frame(19, 2, 25, 13)
    // [268] call frame
    // [740] phi from frame_draw::@9 to frame [phi:frame_draw::@9->frame]
    // [740] phi frame::y#0 = 2 [phi:frame_draw::@9->frame#0] -- vbum1=vbuc1 
    lda #2
    sta frame.y
    // [740] phi frame::y1#16 = $d [phi:frame_draw::@9->frame#1] -- vbum1=vbuc1 
    lda #$d
    sta frame.y1
    // [740] phi frame::x#0 = $13 [phi:frame_draw::@9->frame#2] -- vbum1=vbuc1 
    lda #$13
    sta frame.x
    // [740] phi frame::x1#16 = $19 [phi:frame_draw::@9->frame#3] -- vbum1=vbuc1 
    lda #$19
    sta frame.x1
    jsr frame
    // [269] phi from frame_draw::@9 to frame_draw::@10 [phi:frame_draw::@9->frame_draw::@10]
    // frame_draw::@10
    // frame(25, 2, 31, 13)
    // [270] call frame
    // [740] phi from frame_draw::@10 to frame [phi:frame_draw::@10->frame]
    // [740] phi frame::y#0 = 2 [phi:frame_draw::@10->frame#0] -- vbum1=vbuc1 
    lda #2
    sta frame.y
    // [740] phi frame::y1#16 = $d [phi:frame_draw::@10->frame#1] -- vbum1=vbuc1 
    lda #$d
    sta frame.y1
    // [740] phi frame::x#0 = $19 [phi:frame_draw::@10->frame#2] -- vbum1=vbuc1 
    lda #$19
    sta frame.x
    // [740] phi frame::x1#16 = $1f [phi:frame_draw::@10->frame#3] -- vbum1=vbuc1 
    lda #$1f
    sta frame.x1
    jsr frame
    // [271] phi from frame_draw::@10 to frame_draw::@11 [phi:frame_draw::@10->frame_draw::@11]
    // frame_draw::@11
    // frame(31, 2, 37, 13)
    // [272] call frame
    // [740] phi from frame_draw::@11 to frame [phi:frame_draw::@11->frame]
    // [740] phi frame::y#0 = 2 [phi:frame_draw::@11->frame#0] -- vbum1=vbuc1 
    lda #2
    sta frame.y
    // [740] phi frame::y1#16 = $d [phi:frame_draw::@11->frame#1] -- vbum1=vbuc1 
    lda #$d
    sta frame.y1
    // [740] phi frame::x#0 = $1f [phi:frame_draw::@11->frame#2] -- vbum1=vbuc1 
    lda #$1f
    sta frame.x
    // [740] phi frame::x1#16 = $25 [phi:frame_draw::@11->frame#3] -- vbum1=vbuc1 
    lda #$25
    sta frame.x1
    jsr frame
    // [273] phi from frame_draw::@11 to frame_draw::@12 [phi:frame_draw::@11->frame_draw::@12]
    // frame_draw::@12
    // frame(37, 2, 43, 13)
    // [274] call frame
    // [740] phi from frame_draw::@12 to frame [phi:frame_draw::@12->frame]
    // [740] phi frame::y#0 = 2 [phi:frame_draw::@12->frame#0] -- vbum1=vbuc1 
    lda #2
    sta frame.y
    // [740] phi frame::y1#16 = $d [phi:frame_draw::@12->frame#1] -- vbum1=vbuc1 
    lda #$d
    sta frame.y1
    // [740] phi frame::x#0 = $25 [phi:frame_draw::@12->frame#2] -- vbum1=vbuc1 
    lda #$25
    sta frame.x
    // [740] phi frame::x1#16 = $2b [phi:frame_draw::@12->frame#3] -- vbum1=vbuc1 
    lda #$2b
    sta frame.x1
    jsr frame
    // [275] phi from frame_draw::@12 to frame_draw::@13 [phi:frame_draw::@12->frame_draw::@13]
    // frame_draw::@13
    // frame(43, 2, 49, 13)
    // [276] call frame
    // [740] phi from frame_draw::@13 to frame [phi:frame_draw::@13->frame]
    // [740] phi frame::y#0 = 2 [phi:frame_draw::@13->frame#0] -- vbum1=vbuc1 
    lda #2
    sta frame.y
    // [740] phi frame::y1#16 = $d [phi:frame_draw::@13->frame#1] -- vbum1=vbuc1 
    lda #$d
    sta frame.y1
    // [740] phi frame::x#0 = $2b [phi:frame_draw::@13->frame#2] -- vbum1=vbuc1 
    lda #$2b
    sta frame.x
    // [740] phi frame::x1#16 = $31 [phi:frame_draw::@13->frame#3] -- vbum1=vbuc1 
    lda #$31
    sta frame.x1
    jsr frame
    // [277] phi from frame_draw::@13 to frame_draw::@14 [phi:frame_draw::@13->frame_draw::@14]
    // frame_draw::@14
    // frame(49, 2, 55, 13)
    // [278] call frame
    // [740] phi from frame_draw::@14 to frame [phi:frame_draw::@14->frame]
    // [740] phi frame::y#0 = 2 [phi:frame_draw::@14->frame#0] -- vbum1=vbuc1 
    lda #2
    sta frame.y
    // [740] phi frame::y1#16 = $d [phi:frame_draw::@14->frame#1] -- vbum1=vbuc1 
    lda #$d
    sta frame.y1
    // [740] phi frame::x#0 = $31 [phi:frame_draw::@14->frame#2] -- vbum1=vbuc1 
    lda #$31
    sta frame.x
    // [740] phi frame::x1#16 = $37 [phi:frame_draw::@14->frame#3] -- vbum1=vbuc1 
    lda #$37
    sta frame.x1
    jsr frame
    // [279] phi from frame_draw::@14 to frame_draw::@15 [phi:frame_draw::@14->frame_draw::@15]
    // frame_draw::@15
    // frame(55, 2, 61, 13)
    // [280] call frame
    // [740] phi from frame_draw::@15 to frame [phi:frame_draw::@15->frame]
    // [740] phi frame::y#0 = 2 [phi:frame_draw::@15->frame#0] -- vbum1=vbuc1 
    lda #2
    sta frame.y
    // [740] phi frame::y1#16 = $d [phi:frame_draw::@15->frame#1] -- vbum1=vbuc1 
    lda #$d
    sta frame.y1
    // [740] phi frame::x#0 = $37 [phi:frame_draw::@15->frame#2] -- vbum1=vbuc1 
    lda #$37
    sta frame.x
    // [740] phi frame::x1#16 = $3d [phi:frame_draw::@15->frame#3] -- vbum1=vbuc1 
    lda #$3d
    sta frame.x1
    jsr frame
    // [281] phi from frame_draw::@15 to frame_draw::@16 [phi:frame_draw::@15->frame_draw::@16]
    // frame_draw::@16
    // frame(61, 2, 67, 13)
    // [282] call frame
    // [740] phi from frame_draw::@16 to frame [phi:frame_draw::@16->frame]
    // [740] phi frame::y#0 = 2 [phi:frame_draw::@16->frame#0] -- vbum1=vbuc1 
    lda #2
    sta frame.y
    // [740] phi frame::y1#16 = $d [phi:frame_draw::@16->frame#1] -- vbum1=vbuc1 
    lda #$d
    sta frame.y1
    // [740] phi frame::x#0 = $3d [phi:frame_draw::@16->frame#2] -- vbum1=vbuc1 
    lda #$3d
    sta frame.x
    // [740] phi frame::x1#16 = $43 [phi:frame_draw::@16->frame#3] -- vbum1=vbuc1 
    lda #$43
    sta frame.x1
    jsr frame
    // [283] phi from frame_draw::@16 to frame_draw::@17 [phi:frame_draw::@16->frame_draw::@17]
    // frame_draw::@17
    // frame(0, 13, 67, 29)
    // [284] call frame
    // [740] phi from frame_draw::@17 to frame [phi:frame_draw::@17->frame]
    // [740] phi frame::y#0 = $d [phi:frame_draw::@17->frame#0] -- vbum1=vbuc1 
    lda #$d
    sta frame.y
    // [740] phi frame::y1#16 = $1d [phi:frame_draw::@17->frame#1] -- vbum1=vbuc1 
    lda #$1d
    sta frame.y1
    // [740] phi frame::x#0 = 0 [phi:frame_draw::@17->frame#2] -- vbum1=vbuc1 
    lda #0
    sta frame.x
    // [740] phi frame::x1#16 = $43 [phi:frame_draw::@17->frame#3] -- vbum1=vbuc1 
    lda #$43
    sta frame.x1
    jsr frame
    // [285] phi from frame_draw::@17 to frame_draw::@18 [phi:frame_draw::@17->frame_draw::@18]
    // frame_draw::@18
    // frame(0, 29, 67, 49)
    // [286] call frame
    // [740] phi from frame_draw::@18 to frame [phi:frame_draw::@18->frame]
    // [740] phi frame::y#0 = $1d [phi:frame_draw::@18->frame#0] -- vbum1=vbuc1 
    lda #$1d
    sta frame.y
    // [740] phi frame::y1#16 = $31 [phi:frame_draw::@18->frame#1] -- vbum1=vbuc1 
    lda #$31
    sta frame.y1
    // [740] phi frame::x#0 = 0 [phi:frame_draw::@18->frame#2] -- vbum1=vbuc1 
    lda #0
    sta frame.x
    // [740] phi frame::x1#16 = $43 [phi:frame_draw::@18->frame#3] -- vbum1=vbuc1 
    lda #$43
    sta frame.x1
    jsr frame
    // [287] phi from frame_draw::@18 to frame_draw::@19 [phi:frame_draw::@18->frame_draw::@19]
    // frame_draw::@19
    // cputsxy(2, 14, "status")
    // [288] call cputsxy
  // cputsxy(2, 3, "led colors");
  // cputsxy(2, 5, "    no chip"); print_chip_led(2, 5, DARK_GREY, BLUE);
  // cputsxy(2, 6, "    update"); print_chip_led(2, 6, CYAN, BLUE);
  // cputsxy(2, 7, "    ok"); print_chip_led(2, 7, WHITE, BLUE);
  // cputsxy(2, 8, "    todo"); print_chip_led(2, 8, PURPLE, BLUE);
  // cputsxy(2, 9, "    error"); print_chip_led(2, 9, RED, BLUE);
  // cputsxy(2, 10, "    no file"); print_chip_led(2, 10, GREY, BLUE);
    // [874] phi from frame_draw::@19 to cputsxy [phi:frame_draw::@19->cputsxy]
    jsr cputsxy
    // frame_draw::@return
    // }
    // [289] return 
    rts
  .segment Data
    s: .text "status"
    .byte 0
}
.segment Code
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($2b) void (*putc)(char), __zp($23) const char *s)
printf_str: {
    .label s = $23
    .label putc = $2b
    // [291] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [291] phi printf_str::s#23 = printf_str::s#24 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [292] printf_str::c#1 = *printf_str::s#23 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta c
    // [293] printf_str::s#0 = ++ printf_str::s#23 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [294] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // printf_str::@return
    // }
    // [295] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [296] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [297] callexecute *printf_str::putc#24  -- call__deref_pprz1 
    jsr icall1
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
    // Outside Flow
  icall1:
    jmp (putc)
  .segment Data
    c: .byte 0
}
.segment Code
  // progress_clear
/**
 * @brief Clean the progress area for the flashing.
 */
progress_clear: {
    .const h = $1f+$10
    .const w = $40
    // textcolor(WHITE)
    // [300] call textcolor
    // [183] phi from progress_clear to textcolor [phi:progress_clear->textcolor]
    // [183] phi textcolor::color#17 = WHITE [phi:progress_clear->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [301] phi from progress_clear to progress_clear::@5 [phi:progress_clear->progress_clear::@5]
    // progress_clear::@5
    // bgcolor(BLUE)
    // [302] call bgcolor
    // [188] phi from progress_clear::@5 to bgcolor [phi:progress_clear::@5->bgcolor]
    // [188] phi bgcolor::color#14 = BLUE [phi:progress_clear::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [303] phi from progress_clear::@5 to progress_clear::@1 [phi:progress_clear::@5->progress_clear::@1]
    // [303] phi progress_clear::y#2 = $1f [phi:progress_clear::@5->progress_clear::@1#0] -- vbum1=vbuc1 
    lda #$1f
    sta y
    // progress_clear::@1
  __b1:
    // while (y < h)
    // [304] if(progress_clear::y#2<progress_clear::h) goto progress_clear::@2 -- vbum1_lt_vbuc1_then_la1 
    lda y
    cmp #h
    bcc __b4
    // progress_clear::@return
    // }
    // [305] return 
    rts
    // [306] phi from progress_clear::@1 to progress_clear::@2 [phi:progress_clear::@1->progress_clear::@2]
  __b4:
    // [306] phi progress_clear::x#2 = 2 [phi:progress_clear::@1->progress_clear::@2#0] -- vbum1=vbuc1 
    lda #2
    sta x
    // [306] phi progress_clear::i#2 = 0 [phi:progress_clear::@1->progress_clear::@2#1] -- vbum1=vbuc1 
    lda #0
    sta i
    // progress_clear::@2
  __b2:
    // for(unsigned char i = 0; i < w; i++)
    // [307] if(progress_clear::i#2<progress_clear::w) goto progress_clear::@3 -- vbum1_lt_vbuc1_then_la1 
    lda i
    cmp #w
    bcc __b3
    // progress_clear::@4
    // y++;
    // [308] progress_clear::y#1 = ++ progress_clear::y#2 -- vbum1=_inc_vbum1 
    inc y
    // [303] phi from progress_clear::@4 to progress_clear::@1 [phi:progress_clear::@4->progress_clear::@1]
    // [303] phi progress_clear::y#2 = progress_clear::y#1 [phi:progress_clear::@4->progress_clear::@1#0] -- register_copy 
    jmp __b1
    // progress_clear::@3
  __b3:
    // cputcxy(x, y, '.')
    // [309] cputcxy::x#9 = progress_clear::x#2 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [310] cputcxy::y#9 = progress_clear::y#2 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [311] call cputcxy
    // [879] phi from progress_clear::@3 to cputcxy [phi:progress_clear::@3->cputcxy]
    // [879] phi cputcxy::c#11 = '.' [phi:progress_clear::@3->cputcxy#0] -- vbum1=vbuc1 
    lda #'.'
    sta cputcxy.c
    // [879] phi cputcxy::y#11 = cputcxy::y#9 [phi:progress_clear::@3->cputcxy#1] -- register_copy 
    // [879] phi cputcxy::x#11 = cputcxy::x#9 [phi:progress_clear::@3->cputcxy#2] -- register_copy 
    jsr cputcxy
    // progress_clear::@6
    // x++;
    // [312] progress_clear::x#1 = ++ progress_clear::x#2 -- vbum1=_inc_vbum1 
    inc x
    // for(unsigned char i = 0; i < w; i++)
    // [313] progress_clear::i#1 = ++ progress_clear::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [306] phi from progress_clear::@6 to progress_clear::@2 [phi:progress_clear::@6->progress_clear::@2]
    // [306] phi progress_clear::x#2 = progress_clear::x#1 [phi:progress_clear::@6->progress_clear::@2#0] -- register_copy 
    // [306] phi progress_clear::i#2 = progress_clear::i#1 [phi:progress_clear::@6->progress_clear::@2#1] -- register_copy 
    jmp __b2
  .segment Data
    x: .byte 0
    i: .byte 0
    y: .byte 0
}
.segment Code
  // info_clear_all
/**
 * @brief Clean the information area.
 * 
 */
info_clear_all: {
    // textcolor(WHITE)
    // [315] call textcolor
    // [183] phi from info_clear_all to textcolor [phi:info_clear_all->textcolor]
    // [183] phi textcolor::color#17 = WHITE [phi:info_clear_all->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [316] phi from info_clear_all to info_clear_all::@3 [phi:info_clear_all->info_clear_all::@3]
    // info_clear_all::@3
    // bgcolor(BLUE)
    // [317] call bgcolor
    // [188] phi from info_clear_all::@3 to bgcolor [phi:info_clear_all::@3->bgcolor]
    // [188] phi bgcolor::color#14 = BLUE [phi:info_clear_all::@3->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [318] phi from info_clear_all::@3 to info_clear_all::@1 [phi:info_clear_all::@3->info_clear_all::@1]
    // [318] phi info_clear_all::l#2 = 0 [phi:info_clear_all::@3->info_clear_all::@1#0] -- vbum1=vbuc1 
    lda #0
    sta l
    // info_clear_all::@1
  __b1:
    // while (l < INFO_H)
    // [319] if(info_clear_all::l#2<$a) goto info_clear_all::@2 -- vbum1_lt_vbuc1_then_la1 
    lda l
    cmp #$a
    bcc __b2
    // info_clear_all::@return
    // }
    // [320] return 
    rts
    // info_clear_all::@2
  __b2:
    // info_clear(l)
    // [321] info_clear::l#0 = info_clear_all::l#2 -- vbum1=vbum2 
    lda l
    sta info_clear.l
    // [322] call info_clear
    // [887] phi from info_clear_all::@2 to info_clear [phi:info_clear_all::@2->info_clear]
    // [887] phi info_clear::l#4 = info_clear::l#0 [phi:info_clear_all::@2->info_clear#0] -- register_copy 
    jsr info_clear
    // info_clear_all::@4
    // l++;
    // [323] info_clear_all::l#1 = ++ info_clear_all::l#2 -- vbum1=_inc_vbum1 
    inc l
    // [318] phi from info_clear_all::@4 to info_clear_all::@1 [phi:info_clear_all::@4->info_clear_all::@1]
    // [318] phi info_clear_all::l#2 = info_clear_all::l#1 [phi:info_clear_all::@4->info_clear_all::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    l: .byte 0
}
.segment Code
  // print_clear
print_clear: {
    // textcolor(WHITE)
    // [325] call textcolor
    // [183] phi from print_clear to textcolor [phi:print_clear->textcolor]
    // [183] phi textcolor::color#17 = WHITE [phi:print_clear->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [326] phi from print_clear to print_clear::@1 [phi:print_clear->print_clear::@1]
    // print_clear::@1
    // gotoxy(2, 14)
    // [327] call gotoxy
    // [201] phi from print_clear::@1 to gotoxy [phi:print_clear::@1->gotoxy]
    // [201] phi gotoxy::y#17 = $e [phi:print_clear::@1->gotoxy#0] -- vbum1=vbuc1 
    lda #$e
    sta gotoxy.y
    // [201] phi gotoxy::x#17 = 2 [phi:print_clear::@1->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // [328] phi from print_clear::@1 to print_clear::@2 [phi:print_clear::@1->print_clear::@2]
    // print_clear::@2
    // printf("%60s", " ")
    // [329] call printf_string
    // [333] phi from print_clear::@2 to printf_string [phi:print_clear::@2->printf_string]
    // [333] phi printf_string::str#10 = print_clear::str [phi:print_clear::@2->printf_string#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z printf_string.str
    lda #>str
    sta.z printf_string.str+1
    // [333] phi printf_string::format_justify_left#10 = 0 [phi:print_clear::@2->printf_string#1] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [333] phi printf_string::format_min_length#10 = $3c [phi:print_clear::@2->printf_string#2] -- vbum1=vbuc1 
    lda #$3c
    sta printf_string.format_min_length
    jsr printf_string
    // [330] phi from print_clear::@2 to print_clear::@3 [phi:print_clear::@2->print_clear::@3]
    // print_clear::@3
    // gotoxy(2, 14)
    // [331] call gotoxy
    // [201] phi from print_clear::@3 to gotoxy [phi:print_clear::@3->gotoxy]
    // [201] phi gotoxy::y#17 = $e [phi:print_clear::@3->gotoxy#0] -- vbum1=vbuc1 
    lda #$e
    sta gotoxy.y
    // [201] phi gotoxy::x#17 = 2 [phi:print_clear::@3->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // print_clear::@return
    // }
    // [332] return 
    rts
  .segment Data
    str: .text " "
    .byte 0
}
.segment Code
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(void (*putc)(char), __zp($23) char *str, __mem() char format_min_length, __mem() char format_justify_left)
printf_string: {
    .label str = $23
    // if(format.min_length)
    // [334] if(0==printf_string::format_min_length#10) goto printf_string::@1 -- 0_eq_vbum1_then_la1 
    lda format_min_length
    beq __b3
    // printf_string::@3
    // strlen(str)
    // [335] strlen::str#3 = printf_string::str#10 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [336] call strlen
    // [899] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [899] phi strlen::str#8 = strlen::str#3 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [337] strlen::return#10 = strlen::len#2
    // printf_string::@6
    // [338] printf_string::$9 = strlen::return#10
    // signed char len = (signed char)strlen(str)
    // [339] printf_string::len#0 = (signed char)printf_string::$9 -- vbsm1=_sbyte_vwum2 
    lda printf_string__9
    sta len
    // padding = (signed char)format.min_length  - len
    // [340] printf_string::padding#1 = (signed char)printf_string::format_min_length#10 - printf_string::len#0 -- vbsm1=vbsm1_minus_vbsm2 
    lda padding
    sec
    sbc len
    sta padding
    // if(padding<0)
    // [341] if(printf_string::padding#1>=0) goto printf_string::@10 -- vbsm1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [343] phi from printf_string printf_string::@6 to printf_string::@1 [phi:printf_string/printf_string::@6->printf_string::@1]
  __b3:
    // [343] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@6->printf_string::@1#0] -- vbsm1=vbsc1 
    lda #0
    sta padding
    // [342] phi from printf_string::@6 to printf_string::@10 [phi:printf_string::@6->printf_string::@10]
    // printf_string::@10
    // [343] phi from printf_string::@10 to printf_string::@1 [phi:printf_string::@10->printf_string::@1]
    // [343] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@10->printf_string::@1#0] -- register_copy 
    // printf_string::@1
  __b1:
    // if(!format.justify_left && padding)
    // [344] if(0!=printf_string::format_justify_left#10) goto printf_string::@2 -- 0_neq_vbum1_then_la1 
    lda format_justify_left
    bne __b2
    // printf_string::@8
    // [345] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b4
    jmp __b2
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [346] printf_padding::length#3 = (char)printf_string::padding#3 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [347] call printf_padding
    // [905] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [905] phi printf_padding::pad#7 = ' ' [phi:printf_string::@4->printf_padding#0] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [905] phi printf_padding::length#6 = printf_padding::length#3 [phi:printf_string::@4->printf_padding#1] -- register_copy 
    jsr printf_padding
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [348] printf_str::s#2 = printf_string::str#10
    // [349] call printf_str
    // [290] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [290] phi printf_str::putc#24 = &cputc [phi:printf_string::@2->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [290] phi printf_str::s#24 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@7
    // if(format.justify_left && padding)
    // [350] if(0==printf_string::format_justify_left#10) goto printf_string::@return -- 0_eq_vbum1_then_la1 
    lda format_justify_left
    beq __breturn
    // printf_string::@9
    // [351] if(0!=printf_string::padding#3) goto printf_string::@5 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b5
    rts
    // printf_string::@5
  __b5:
    // printf_padding(putc, ' ',(char)padding)
    // [352] printf_padding::length#4 = (char)printf_string::padding#3 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [353] call printf_padding
    // [905] phi from printf_string::@5 to printf_padding [phi:printf_string::@5->printf_padding]
    // [905] phi printf_padding::pad#7 = ' ' [phi:printf_string::@5->printf_padding#0] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [905] phi printf_padding::length#6 = printf_padding::length#4 [phi:printf_string::@5->printf_padding#1] -- register_copy 
    jsr printf_padding
    // printf_string::@return
  __breturn:
    // }
    // [354] return 
    rts
  .segment Data
    .label printf_string__9 = strlen.len
    len: .byte 0
    .label padding = format_min_length
    format_min_length: .byte 0
    format_justify_left: .byte 0
}
.segment Code
  // flash_smc_detect
flash_smc_detect: {
    // unsigned int smc_bootloader_version = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [355] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [356] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [357] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [358] cx16_k_i2c_read_byte::return#2 = cx16_k_i2c_read_byte::return#1
    // flash_smc_detect::@3
    // [359] flash_smc_detect::smc_bootloader_version#0 = cx16_k_i2c_read_byte::return#2
    // BYTE1(smc_bootloader_version)
    // [360] flash_smc_detect::$1 = byte1  flash_smc_detect::smc_bootloader_version#0 -- vbum1=_byte1_vwum2 
    lda smc_bootloader_version+1
    sta flash_smc_detect__1
    // if(!BYTE1(smc_bootloader_version))
    // [361] if(0==flash_smc_detect::$1) goto flash_smc_detect::@1 -- 0_eq_vbum1_then_la1 
    beq __b1
    // [364] phi from flash_smc_detect::@3 to flash_smc_detect::@return [phi:flash_smc_detect::@3->flash_smc_detect::@return]
    // [364] phi flash_smc_detect::return#1 = $200 [phi:flash_smc_detect::@3->flash_smc_detect::@return#0] -- vwum1=vwuc1 
    lda #<$200
    sta return
    lda #>$200
    sta return+1
    rts
    // flash_smc_detect::@1
  __b1:
    // if(smc_bootloader_version == 0xFF)
    // [362] if(flash_smc_detect::smc_bootloader_version#0!=$ff) goto flash_smc_detect::@2 -- vwum1_neq_vbuc1_then_la1 
    lda smc_bootloader_version+1
    bne __b2
    lda smc_bootloader_version
    cmp #$ff
    bne __b2
    // [364] phi from flash_smc_detect::@1 to flash_smc_detect::@return [phi:flash_smc_detect::@1->flash_smc_detect::@return]
    // [364] phi flash_smc_detect::return#1 = $100 [phi:flash_smc_detect::@1->flash_smc_detect::@return#0] -- vwum1=vwuc1 
    lda #<$100
    sta return
    lda #>$100
    sta return+1
    rts
    // [363] phi from flash_smc_detect::@1 to flash_smc_detect::@2 [phi:flash_smc_detect::@1->flash_smc_detect::@2]
    // flash_smc_detect::@2
  __b2:
    // [364] phi from flash_smc_detect::@2 to flash_smc_detect::@return [phi:flash_smc_detect::@2->flash_smc_detect::@return]
    // [364] phi flash_smc_detect::return#1 = flash_smc_detect::smc_bootloader_version#0 [phi:flash_smc_detect::@2->flash_smc_detect::@return#0] -- register_copy 
    // flash_smc_detect::@return
    // }
    // [365] return 
    rts
  .segment Data
    flash_smc_detect__1: .byte 0
    .label smc_bootloader_version = return
    // When the bootloader is not present, 0xFF is returned.
    return: .word 0
}
.segment Code
  // print_smc_led
// void print_smc_led(__mem() char c)
print_smc_led: {
    // print_chip_led(CHIP_SMC_X+1, CHIP_SMC_Y, CHIP_SMC_W, c, BLUE)
    // [367] print_chip_led::tc#0 = print_smc_led::c#3
    // [368] call print_chip_led
    // [918] phi from print_smc_led to print_chip_led [phi:print_smc_led->print_chip_led]
    // [918] phi print_chip_led::w#5 = 5 [phi:print_smc_led->print_chip_led#0] -- vbum1=vbuc1 
    lda #5
    sta print_chip_led.w
    // [918] phi print_chip_led::tc#3 = print_chip_led::tc#0 [phi:print_smc_led->print_chip_led#1] -- register_copy 
    // [918] phi print_chip_led::x#3 = 1+1 [phi:print_smc_led->print_chip_led#2] -- vbum1=vbuc1 
    lda #1+1
    sta print_chip_led.x
    jsr print_chip_led
    // print_smc_led::@return
    // }
    // [369] return 
    rts
  .segment Data
    c: .byte 0
}
.segment Code
  // rom_detect
rom_detect: {
    .const bank_set_brom1_bank = 4
    // [371] phi from rom_detect to rom_detect::@1 [phi:rom_detect->rom_detect::@1]
    // [371] phi rom_detect::rom_chip#10 = 0 [phi:rom_detect->rom_detect::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // [371] phi rom_detect::rom_detect_address#10 = 0 [phi:rom_detect->rom_detect::@1#1] -- vdum1=vduc1 
    sta rom_detect_address
    sta rom_detect_address+1
    lda #<0>>$10
    sta rom_detect_address+2
    lda #>0>>$10
    sta rom_detect_address+3
    // rom_detect::@1
  __b1:
    // for (unsigned long rom_detect_address = 0; rom_detect_address < 8 * 0x80000; rom_detect_address += 0x80000)
    // [372] if(rom_detect::rom_detect_address#10<8*$80000) goto rom_detect::@2 -- vdum1_lt_vduc1_then_la1 
    lda rom_detect_address+3
    cmp #>8*$80000>>$10
    bcc __b2
    bne !+
    lda rom_detect_address+2
    cmp #<8*$80000>>$10
    bcc __b2
    bne !+
    lda rom_detect_address+1
    cmp #>8*$80000
    bcc __b2
    bne !+
    lda rom_detect_address
    cmp #<8*$80000
    bcc __b2
  !:
    // rom_detect::@return
    // }
    // [373] return 
    rts
    // rom_detect::@2
  __b2:
    // rom_manufacturer_ids[rom_chip] = 0
    // [374] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = 0
    // [375] rom_device_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta rom_device_ids,y
    // rom_sizes[rom_chip] = 0
    // [376] rom_detect::$19 = rom_detect::rom_chip#10 << 2 -- vbum1=vbum2_rol_2 
    tya
    asl
    asl
    sta rom_detect__19
    // [377] rom_sizes[rom_detect::$19] = 0 -- pduc1_derefidx_vbum1=vbuc2 
    tay
    lda #0
    sta rom_sizes,y
    sta rom_sizes+1,y
    sta rom_sizes+2,y
    sta rom_sizes+3,y
    // if (rom_detect_address == 0x0)
    // [378] if(rom_detect::rom_detect_address#10!=0) goto rom_detect::@3 -- vdum1_neq_0_then_la1 
    lda rom_detect_address
    ora rom_detect_address+1
    ora rom_detect_address+2
    ora rom_detect_address+3
    bne __b3
    // rom_detect::@13
    // rom_manufacturer_ids[rom_chip] = 0x9f
    // [379] rom_manufacturer_ids[rom_detect::rom_chip#10] = $9f -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$9f
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF040
    // [380] rom_device_ids[rom_detect::rom_chip#10] = $b7 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$b7
    sta rom_device_ids,y
    // rom_detect::@3
  __b3:
    // if (rom_detect_address == 0x80000)
    // [381] if(rom_detect::rom_detect_address#10!=$80000) goto rom_detect::@4 -- vdum1_neq_vduc1_then_la1 
    lda rom_detect_address+3
    cmp #>$80000>>$10
    bne __b4
    lda rom_detect_address+2
    cmp #<$80000>>$10
    bne __b4
    lda rom_detect_address+1
    cmp #>$80000
    bne __b4
    lda rom_detect_address
    cmp #<$80000
    bne __b4
    // rom_detect::@14
    // rom_manufacturer_ids[rom_chip] = 0x9f
    // [382] rom_manufacturer_ids[rom_detect::rom_chip#10] = $9f -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$9f
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF040
    // [383] rom_device_ids[rom_detect::rom_chip#10] = $b7 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$b7
    sta rom_device_ids,y
    // rom_detect::@4
  __b4:
    // if (rom_detect_address == 0x100000)
    // [384] if(rom_detect::rom_detect_address#10!=$100000) goto rom_detect::@5 -- vdum1_neq_vduc1_then_la1 
    lda rom_detect_address+3
    cmp #>$100000>>$10
    bne __b5
    lda rom_detect_address+2
    cmp #<$100000>>$10
    bne __b5
    lda rom_detect_address+1
    cmp #>$100000
    bne __b5
    lda rom_detect_address
    cmp #<$100000
    bne __b5
    // rom_detect::@15
    // rom_manufacturer_ids[rom_chip] = 0x9f
    // [385] rom_manufacturer_ids[rom_detect::rom_chip#10] = $9f -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$9f
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF020A
    // [386] rom_device_ids[rom_detect::rom_chip#10] = $b6 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$b6
    sta rom_device_ids,y
    // rom_detect::@5
  __b5:
    // if (rom_detect_address == 0x180000)
    // [387] if(rom_detect::rom_detect_address#10!=$180000) goto rom_detect::@6 -- vdum1_neq_vduc1_then_la1 
    lda rom_detect_address+3
    cmp #>$180000>>$10
    bne __b6
    lda rom_detect_address+2
    cmp #<$180000>>$10
    bne __b6
    lda rom_detect_address+1
    cmp #>$180000
    bne __b6
    lda rom_detect_address
    cmp #<$180000
    bne __b6
    // rom_detect::@16
    // rom_manufacturer_ids[rom_chip] = 0x9f
    // [388] rom_manufacturer_ids[rom_detect::rom_chip#10] = $9f -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$9f
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF010A
    // [389] rom_device_ids[rom_detect::rom_chip#10] = $b5 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$b5
    sta rom_device_ids,y
    // rom_detect::@6
  __b6:
    // if (rom_detect_address == 0x200000)
    // [390] if(rom_detect::rom_detect_address#10!=$200000) goto rom_detect::bank_set_brom1 -- vdum1_neq_vduc1_then_la1 
    lda rom_detect_address+3
    cmp #>$200000>>$10
    bne bank_set_brom1
    lda rom_detect_address+2
    cmp #<$200000>>$10
    bne bank_set_brom1
    lda rom_detect_address+1
    cmp #>$200000
    bne bank_set_brom1
    lda rom_detect_address
    cmp #<$200000
    bne bank_set_brom1
    // rom_detect::@17
    // rom_manufacturer_ids[rom_chip] = 0x9f
    // [391] rom_manufacturer_ids[rom_detect::rom_chip#10] = $9f -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$9f
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = SST39SF040
    // [392] rom_device_ids[rom_detect::rom_chip#10] = $b7 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$b7
    sta rom_device_ids,y
    // rom_detect::bank_set_brom1
  bank_set_brom1:
    // BROM = bank
    // [393] BROM = rom_detect::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // rom_detect::@20
    // case SST39SF010A:
    //             rom_device_names[rom_chip] = "f010a";
    //             rom_size_strings[rom_chip] = "128";
    //             rom_sizes[rom_chip] = 128 * 1024;
    //             break;
    // [394] if(rom_device_ids[rom_detect::rom_chip#10]==$b5) goto rom_detect::@7 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    ldy rom_chip
    lda rom_device_ids,y
    cmp #$b5
    bne !__b7+
    jmp __b7
  !__b7:
    // rom_detect::@18
    // case SST39SF020A:
    //             rom_device_names[rom_chip] = "f020a";
    //             rom_size_strings[rom_chip] = "256";
    //             rom_sizes[rom_chip] = 256 * 1024;
    //             break;
    // [395] if(rom_device_ids[rom_detect::rom_chip#10]==$b6) goto rom_detect::@8 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b6
    bne !__b8+
    jmp __b8
  !__b8:
    // rom_detect::@19
    // case SST39SF040:
    //             rom_device_names[rom_chip] = "f040";
    //             rom_size_strings[rom_chip] = "512";
    //             rom_sizes[rom_chip] = 512 * 1024;
    //             break;
    // [396] if(rom_device_ids[rom_detect::rom_chip#10]==$b7) goto rom_detect::@9 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b7
    beq __b9
    // rom_detect::@10
    // rom_device_names[rom_chip] = "----"
    // [397] rom_detect::$27 = rom_detect::rom_chip#10 << 1 -- vbum1=vbum2_rol_1 
    tya
    asl
    sta rom_detect__27
    // [398] rom_device_names[rom_detect::$27] = rom_detect::$35 -- qbuc1_derefidx_vbum1=pbuc2 
    tay
    lda #<rom_detect__35
    sta rom_device_names,y
    lda #>rom_detect__35
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "000"
    // [399] rom_size_strings[rom_detect::$27] = rom_detect::$36 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__36
    sta rom_size_strings,y
    lda #>rom_detect__36
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 0
    // [400] rom_sizes[rom_detect::$19] = 0 -- pduc1_derefidx_vbum1=vbuc2 
    ldy rom_detect__19
    lda #0
    sta rom_sizes,y
    sta rom_sizes+1,y
    sta rom_sizes+2,y
    sta rom_sizes+3,y
    // rom_device_ids[rom_chip] = UNKNOWN
    // [401] rom_device_ids[rom_detect::rom_chip#10] = $55 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$55
    ldy rom_chip
    sta rom_device_ids,y
    // rom_detect::@11
  __b11:
    // rom_chip++;
    // [402] rom_detect::rom_chip#1 = ++ rom_detect::rom_chip#10 -- vbum1=_inc_vbum1 
    inc rom_chip
    // rom_detect::@12
    // rom_detect_address += 0x80000
    // [403] rom_detect::rom_detect_address#1 = rom_detect::rom_detect_address#10 + $80000 -- vdum1=vdum1_plus_vduc1 
    clc
    lda rom_detect_address
    adc #<$80000
    sta rom_detect_address
    lda rom_detect_address+1
    adc #>$80000
    sta rom_detect_address+1
    lda rom_detect_address+2
    adc #<$80000>>$10
    sta rom_detect_address+2
    lda rom_detect_address+3
    adc #>$80000>>$10
    sta rom_detect_address+3
    // [371] phi from rom_detect::@12 to rom_detect::@1 [phi:rom_detect::@12->rom_detect::@1]
    // [371] phi rom_detect::rom_chip#10 = rom_detect::rom_chip#1 [phi:rom_detect::@12->rom_detect::@1#0] -- register_copy 
    // [371] phi rom_detect::rom_detect_address#10 = rom_detect::rom_detect_address#1 [phi:rom_detect::@12->rom_detect::@1#1] -- register_copy 
    jmp __b1
    // rom_detect::@9
  __b9:
    // rom_device_names[rom_chip] = "f040"
    // [404] rom_detect::$24 = rom_detect::rom_chip#10 << 1 -- vbum1=vbum2_rol_1 
    lda rom_chip
    asl
    sta rom_detect__24
    // [405] rom_device_names[rom_detect::$24] = rom_detect::$33 -- qbuc1_derefidx_vbum1=pbuc2 
    tay
    lda #<rom_detect__33
    sta rom_device_names,y
    lda #>rom_detect__33
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "512"
    // [406] rom_size_strings[rom_detect::$24] = rom_detect::$34 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__34
    sta rom_size_strings,y
    lda #>rom_detect__34
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 512 * 1024
    // [407] rom_sizes[rom_detect::$19] = (unsigned long)$200*$400 -- pduc1_derefidx_vbum1=vduc2 
    ldy rom_detect__19
    lda #<$200*$400
    sta rom_sizes,y
    lda #>$200*$400
    sta rom_sizes+1,y
    lda #<$200*$400>>$10
    sta rom_sizes+2,y
    lda #>$200*$400>>$10
    sta rom_sizes+3,y
    jmp __b11
    // rom_detect::@8
  __b8:
    // rom_device_names[rom_chip] = "f020a"
    // [408] rom_detect::$21 = rom_detect::rom_chip#10 << 1 -- vbum1=vbum2_rol_1 
    lda rom_chip
    asl
    sta rom_detect__21
    // [409] rom_device_names[rom_detect::$21] = rom_detect::$31 -- qbuc1_derefidx_vbum1=pbuc2 
    tay
    lda #<rom_detect__31
    sta rom_device_names,y
    lda #>rom_detect__31
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "256"
    // [410] rom_size_strings[rom_detect::$21] = rom_detect::$32 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__32
    sta rom_size_strings,y
    lda #>rom_detect__32
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 256 * 1024
    // [411] rom_sizes[rom_detect::$19] = (unsigned long)$100*$400 -- pduc1_derefidx_vbum1=vduc2 
    ldy rom_detect__19
    lda #<$100*$400
    sta rom_sizes,y
    lda #>$100*$400
    sta rom_sizes+1,y
    lda #<$100*$400>>$10
    sta rom_sizes+2,y
    lda #>$100*$400>>$10
    sta rom_sizes+3,y
    jmp __b11
    // rom_detect::@7
  __b7:
    // rom_device_names[rom_chip] = "f010a"
    // [412] rom_detect::$18 = rom_detect::rom_chip#10 << 1 -- vbum1=vbum2_rol_1 
    lda rom_chip
    asl
    sta rom_detect__18
    // [413] rom_device_names[rom_detect::$18] = rom_detect::$29 -- qbuc1_derefidx_vbum1=pbuc2 
    tay
    lda #<rom_detect__29
    sta rom_device_names,y
    lda #>rom_detect__29
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "128"
    // [414] rom_size_strings[rom_detect::$18] = rom_detect::$30 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__30
    sta rom_size_strings,y
    lda #>rom_detect__30
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 128 * 1024
    // [415] rom_sizes[rom_detect::$19] = (unsigned long)$80*$400 -- pduc1_derefidx_vbum1=vduc2 
    ldy rom_detect__19
    lda #<$80*$400
    sta rom_sizes,y
    lda #>$80*$400
    sta rom_sizes+1,y
    lda #<$80*$400>>$10
    sta rom_sizes+2,y
    lda #>$80*$400>>$10
    sta rom_sizes+3,y
    jmp __b11
  .segment Data
    rom_detect__29: .text "f010a"
    .byte 0
    rom_detect__30: .text "128"
    .byte 0
    rom_detect__31: .text "f020a"
    .byte 0
    rom_detect__32: .text "256"
    .byte 0
    rom_detect__33: .text "f040"
    .byte 0
    rom_detect__34: .text "512"
    .byte 0
    rom_detect__35: .text "----"
    .byte 0
    rom_detect__36: .text "000"
    .byte 0
    rom_detect__18: .byte 0
    rom_detect__19: .byte 0
    rom_detect__21: .byte 0
    rom_detect__24: .byte 0
    rom_detect__27: .byte 0
    rom_chip: .byte 0
    rom_detect_address: .dword 0
}
.segment Code
  // print_smc_chip
print_smc_chip: {
    // print_smc_led(GREY)
    // [417] call print_smc_led
    // [366] phi from print_smc_chip to print_smc_led [phi:print_smc_chip->print_smc_led]
    // [366] phi print_smc_led::c#3 = GREY [phi:print_smc_chip->print_smc_led#0] -- vbum1=vbuc1 
    lda #GREY
    sta print_smc_led.c
    jsr print_smc_led
    // [418] phi from print_smc_chip to print_smc_chip::@1 [phi:print_smc_chip->print_smc_chip::@1]
    // print_smc_chip::@1
    // print_chip(CHIP_SMC_X, CHIP_SMC_Y+1, CHIP_SMC_W, "smc     ")
    // [419] call print_chip
    // [936] phi from print_smc_chip::@1 to print_chip [phi:print_smc_chip::@1->print_chip]
    // [936] phi print_chip::text#11 = print_smc_chip::text [phi:print_smc_chip::@1->print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z print_chip.text_2
    lda #>text
    sta.z print_chip.text_2+1
    // [936] phi print_chip::w#10 = 5 [phi:print_smc_chip::@1->print_chip#1] -- vbum1=vbuc1 
    lda #5
    sta print_chip.w
    // [936] phi print_chip::x#10 = 1 [phi:print_smc_chip::@1->print_chip#2] -- vbum1=vbuc1 
    lda #1
    sta print_chip.x
    jsr print_chip
    // print_smc_chip::@return
    // }
    // [420] return 
    rts
  .segment Data
    text: .text "smc     "
    .byte 0
}
.segment Code
  // print_vera_chip
print_vera_chip: {
    // print_vera_led(GREY)
    // [422] call print_vera_led
    // [980] phi from print_vera_chip to print_vera_led [phi:print_vera_chip->print_vera_led]
    jsr print_vera_led
    // [423] phi from print_vera_chip to print_vera_chip::@1 [phi:print_vera_chip->print_vera_chip::@1]
    // print_vera_chip::@1
    // print_chip(CHIP_VERA_X, CHIP_VERA_Y+1, CHIP_VERA_W, "vera     ")
    // [424] call print_chip
    // [936] phi from print_vera_chip::@1 to print_chip [phi:print_vera_chip::@1->print_chip]
    // [936] phi print_chip::text#11 = print_vera_chip::text [phi:print_vera_chip::@1->print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z print_chip.text_2
    lda #>text
    sta.z print_chip.text_2+1
    // [936] phi print_chip::w#10 = 8 [phi:print_vera_chip::@1->print_chip#1] -- vbum1=vbuc1 
    lda #8
    sta print_chip.w
    // [936] phi print_chip::x#10 = 9 [phi:print_vera_chip::@1->print_chip#2] -- vbum1=vbuc1 
    lda #9
    sta print_chip.x
    jsr print_chip
    // print_vera_chip::@return
    // }
    // [425] return 
    rts
  .segment Data
    text: .text "vera     "
    .byte 0
}
.segment Code
  // print_rom_chips
print_rom_chips: {
    // [427] phi from print_rom_chips to print_rom_chips::@1 [phi:print_rom_chips->print_rom_chips::@1]
    // [427] phi print_rom_chips::r#2 = 0 [phi:print_rom_chips->print_rom_chips::@1#0] -- vbum1=vbuc1 
    lda #0
    sta r
    // print_rom_chips::@1
  __b1:
    // for (unsigned char r = 0; r < 8; r++)
    // [428] if(print_rom_chips::r#2<8) goto print_rom_chips::@2 -- vbum1_lt_vbuc1_then_la1 
    lda r
    cmp #8
    bcc __b2
    // print_rom_chips::@return
    // }
    // [429] return 
    rts
    // [430] phi from print_rom_chips::@1 to print_rom_chips::@2 [phi:print_rom_chips::@1->print_rom_chips::@2]
    // print_rom_chips::@2
  __b2:
    // strcpy(rom, "rom0 ")
    // [431] call strcpy
    // [482] phi from print_rom_chips::@2 to strcpy [phi:print_rom_chips::@2->strcpy]
    // [482] phi strcpy::dst#0 = print_rom_chips::rom [phi:print_rom_chips::@2->strcpy#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z strcpy.dst
    lda #>rom
    sta.z strcpy.dst+1
    // [482] phi strcpy::src#0 = print_rom_chips::source [phi:print_rom_chips::@2->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // print_rom_chips::@3
    // strcat(rom, rom_size_strings[r])
    // [432] print_rom_chips::$9 = print_rom_chips::r#2 << 1 -- vbum1=vbum2_rol_1 
    lda r
    asl
    sta print_rom_chips__9
    // [433] strcat::source#0 = rom_size_strings[print_rom_chips::$9] -- pbuz1=qbuc1_derefidx_vbum2 
    tay
    lda rom_size_strings,y
    sta.z strcat.source
    lda rom_size_strings+1,y
    sta.z strcat.source+1
    // [434] call strcat
    // [983] phi from print_rom_chips::@3 to strcat [phi:print_rom_chips::@3->strcat]
    jsr strcat
    // print_rom_chips::@4
    // r+'0'
    // [435] print_rom_chips::$3 = print_rom_chips::r#2 + '0' -- vbum1=vbum2_plus_vbuc1 
    lda #'0'
    clc
    adc r
    sta print_rom_chips__3
    // *(rom+3) = r+'0'
    // [436] *(print_rom_chips::rom+3) = print_rom_chips::$3 -- _deref_pbuc1=vbum1 
    sta rom+3
    // print_rom_led(r, GREY)
    // [437] print_rom_led::chip#0 = print_rom_chips::r#2 -- vbum1=vbum2 
    lda r
    sta print_rom_led.chip
    // [438] call print_rom_led
    // [995] phi from print_rom_chips::@4 to print_rom_led [phi:print_rom_chips::@4->print_rom_led]
    // [995] phi print_rom_led::c#3 = GREY [phi:print_rom_chips::@4->print_rom_led#0] -- vbum1=vbuc1 
    lda #GREY
    sta print_rom_led.c
    // [995] phi print_rom_led::chip#3 = print_rom_led::chip#0 [phi:print_rom_chips::@4->print_rom_led#1] -- register_copy 
    jsr print_rom_led
    // print_rom_chips::@5
    // r*6
    // [439] print_rom_chips::$10 = print_rom_chips::$9 + print_rom_chips::r#2 -- vbum1=vbum1_plus_vbum2 
    lda print_rom_chips__10
    clc
    adc r
    sta print_rom_chips__10
    // [440] print_rom_chips::$5 = print_rom_chips::$10 << 1 -- vbum1=vbum2_rol_1 
    asl
    sta print_rom_chips__5
    // print_chip(CHIP_ROM_X+r*6, CHIP_ROM_Y+1, CHIP_ROM_W, rom)
    // [441] print_chip::x#2 = $14 + print_rom_chips::$5 -- vbum1=vbuc1_plus_vbum1 
    lda #$14
    clc
    adc print_chip.x
    sta print_chip.x
    // [442] call print_chip
    // [936] phi from print_rom_chips::@5 to print_chip [phi:print_rom_chips::@5->print_chip]
    // [936] phi print_chip::text#11 = print_rom_chips::rom [phi:print_rom_chips::@5->print_chip#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z print_chip.text_2
    lda #>rom
    sta.z print_chip.text_2+1
    // [936] phi print_chip::w#10 = 3 [phi:print_rom_chips::@5->print_chip#1] -- vbum1=vbuc1 
    lda #3
    sta print_chip.w
    // [936] phi print_chip::x#10 = print_chip::x#2 [phi:print_rom_chips::@5->print_chip#2] -- register_copy 
    jsr print_chip
    // print_rom_chips::@6
    // for (unsigned char r = 0; r < 8; r++)
    // [443] print_rom_chips::r#1 = ++ print_rom_chips::r#2 -- vbum1=_inc_vbum1 
    inc r
    // [427] phi from print_rom_chips::@6 to print_rom_chips::@1 [phi:print_rom_chips::@6->print_rom_chips::@1]
    // [427] phi print_rom_chips::r#2 = print_rom_chips::r#1 [phi:print_rom_chips::@6->print_rom_chips::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    rom: .fill $10, 0
    source: .text "rom0 "
    .byte 0
    print_rom_chips__3: .byte 0
    .label print_rom_chips__5 = print_chip.x
    r: .byte 0
    print_rom_chips__9: .byte 0
    .label print_rom_chips__10 = print_rom_chips__9
}
.segment Code
  // printf_uint
// Print an unsigned int using a specific format
// void printf_uint(void (*putc)(char), __mem() unsigned int uvalue, char format_min_length, char format_justify_left, char format_sign_always, char format_zero_padding, char format_upper_case, char format_radix)
printf_uint: {
    // printf_uint::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [445] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [446] utoa::value#1 = printf_uint::uvalue#2
    // [447] call utoa
  // Format number into buffer
    // [1003] phi from printf_uint::@1 to utoa [phi:printf_uint::@1->utoa]
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [448] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [449] call printf_number_buffer
  // Print using format
    // [1024] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    // [1024] phi printf_number_buffer::putc#10 = &cputc [phi:printf_uint::@2->printf_number_buffer#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_number_buffer.putc
    lda #>cputc
    sta.z printf_number_buffer.putc+1
    // [1024] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_uint::@2->printf_number_buffer#1] -- register_copy 
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [450] return 
    rts
  .segment Data
    uvalue: .word 0
}
.segment Code
  // info_smc
/**
 * @brief Print the SMC status.
 * 
 * @param status The STATUS_ 
 * 
 * @remark The smc_booloader is a global variable. 
 */
// void info_smc(char info_status)
info_smc: {
    // info_clear(0)
    // [452] call info_clear
    // [887] phi from info_smc to info_clear [phi:info_smc->info_clear]
    // [887] phi info_clear::l#4 = 0 [phi:info_smc->info_clear#0] -- vbum1=vbuc1 
    lda #0
    sta info_clear.l
    jsr info_clear
    // [453] phi from info_smc to info_smc::@1 [phi:info_smc->info_smc::@1]
    // info_smc::@1
    // printf("SMC  - CX16 - %-8s - Bootloader version %u.", status_text[info_status], smc_bootloader)
    // [454] call printf_str
    // [290] phi from info_smc::@1 to printf_str [phi:info_smc::@1->printf_str]
    // [290] phi printf_str::putc#24 = &cputc [phi:info_smc::@1->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [290] phi printf_str::s#24 = info_smc::s [phi:info_smc::@1->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // info_smc::@2
    // printf("SMC  - CX16 - %-8s - Bootloader version %u.", status_text[info_status], smc_bootloader)
    // [455] printf_string::str#1 = *status_text -- pbuz1=_deref_qbuc1 
    lda status_text
    sta.z printf_string.str
    lda status_text+1
    sta.z printf_string.str+1
    // [456] call printf_string
    // [333] phi from info_smc::@2 to printf_string [phi:info_smc::@2->printf_string]
    // [333] phi printf_string::str#10 = printf_string::str#1 [phi:info_smc::@2->printf_string#0] -- register_copy 
    // [333] phi printf_string::format_justify_left#10 = 1 [phi:info_smc::@2->printf_string#1] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [333] phi printf_string::format_min_length#10 = 8 [phi:info_smc::@2->printf_string#2] -- vbum1=vbuc1 
    lda #8
    sta printf_string.format_min_length
    jsr printf_string
    // [457] phi from info_smc::@2 to info_smc::@3 [phi:info_smc::@2->info_smc::@3]
    // info_smc::@3
    // printf("SMC  - CX16 - %-8s - Bootloader version %u.", status_text[info_status], smc_bootloader)
    // [458] call printf_str
    // [290] phi from info_smc::@3 to printf_str [phi:info_smc::@3->printf_str]
    // [290] phi printf_str::putc#24 = &cputc [phi:info_smc::@3->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [290] phi printf_str::s#24 = info_smc::s1 [phi:info_smc::@3->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_smc::@4
    // printf("SMC  - CX16 - %-8s - Bootloader version %u.", status_text[info_status], smc_bootloader)
    // [459] printf_uint::uvalue#0 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta printf_uint.uvalue
    lda smc_bootloader+1
    sta printf_uint.uvalue+1
    // [460] call printf_uint
    // [444] phi from info_smc::@4 to printf_uint [phi:info_smc::@4->printf_uint]
    // [444] phi printf_uint::uvalue#2 = printf_uint::uvalue#0 [phi:info_smc::@4->printf_uint#0] -- register_copy 
    jsr printf_uint
    // [461] phi from info_smc::@4 to info_smc::@5 [phi:info_smc::@4->info_smc::@5]
    // info_smc::@5
    // printf("SMC  - CX16 - %-8s - Bootloader version %u.", status_text[info_status], smc_bootloader)
    // [462] call printf_str
    // [290] phi from info_smc::@5 to printf_str [phi:info_smc::@5->printf_str]
    // [290] phi printf_str::putc#24 = &cputc [phi:info_smc::@5->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [290] phi printf_str::s#24 = s2 [phi:info_smc::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // info_smc::@return
    // }
    // [463] return 
    rts
  .segment Data
    s: .text "SMC  - CX16 - "
    .byte 0
    s1: .text " - Bootloader version "
    .byte 0
}
.segment Code
  // info_vera
/**
 * @brief Print the VERA status.
 * 
 * @param info_status The STATUS_ 
 */
// void info_vera(char info_status)
info_vera: {
    // info_clear(1)
    // [465] call info_clear
    // [887] phi from info_vera to info_clear [phi:info_vera->info_clear]
    // [887] phi info_clear::l#4 = 1 [phi:info_vera->info_clear#0] -- vbum1=vbuc1 
    lda #1
    sta info_clear.l
    jsr info_clear
    // [466] phi from info_vera to info_vera::@1 [phi:info_vera->info_vera::@1]
    // info_vera::@1
    // printf("VERA - CX16 - %-8s", status_text[info_status])
    // [467] call printf_str
    // [290] phi from info_vera::@1 to printf_str [phi:info_vera::@1->printf_str]
    // [290] phi printf_str::putc#24 = &cputc [phi:info_vera::@1->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [290] phi printf_str::s#24 = info_vera::s [phi:info_vera::@1->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // info_vera::@2
    // printf("VERA - CX16 - %-8s", status_text[info_status])
    // [468] printf_string::str#2 = *status_text -- pbuz1=_deref_qbuc1 
    lda status_text
    sta.z printf_string.str
    lda status_text+1
    sta.z printf_string.str+1
    // [469] call printf_string
    // [333] phi from info_vera::@2 to printf_string [phi:info_vera::@2->printf_string]
    // [333] phi printf_string::str#10 = printf_string::str#2 [phi:info_vera::@2->printf_string#0] -- register_copy 
    // [333] phi printf_string::format_justify_left#10 = 1 [phi:info_vera::@2->printf_string#1] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [333] phi printf_string::format_min_length#10 = 8 [phi:info_vera::@2->printf_string#2] -- vbum1=vbuc1 
    lda #8
    sta printf_string.format_min_length
    jsr printf_string
    // info_vera::@return
    // }
    // [470] return 
    rts
  .segment Data
    s: .text "VERA - CX16 - "
    .byte 0
}
.segment Code
  // wait_key
wait_key: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    // wait_key::bank_set_bram1
    // BRAM = bank
    // [472] BRAM = wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // wait_key::bank_set_brom1
    // BROM = bank
    // [473] BROM = wait_key::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [474] phi from wait_key::@1 wait_key::bank_set_brom1 to wait_key::kbhit1 [phi:wait_key::@1/wait_key::bank_set_brom1->wait_key::kbhit1]
    // wait_key::kbhit1
  kbhit1:
    // wait_key::kbhit1_cbm_k_clrchn1
    // asm
    // asm { jsrCBM_CLRCHN  }
    jsr CBM_CLRCHN
    // [476] phi from wait_key::kbhit1_cbm_k_clrchn1 to wait_key::kbhit1_@2 [phi:wait_key::kbhit1_cbm_k_clrchn1->wait_key::kbhit1_@2]
    // wait_key::kbhit1_@2
    // cbm_k_getin()
    // [477] call cbm_k_getin
    jsr cbm_k_getin
    // [478] cbm_k_getin::return#2 = cbm_k_getin::return#1
    // wait_key::@2
    // [479] wait_key::kbhit1_return#0 = cbm_k_getin::return#2
    // wait_key::@1
    // while (!(ch = kbhit()))
    // [480] if(0==wait_key::kbhit1_return#0) goto wait_key::kbhit1 -- 0_eq_vbum1_then_la1 
    lda kbhit1_return
    beq kbhit1
    // wait_key::@return
    // }
    // [481] return 
    rts
  .segment Data
    .label kbhit1_return = cbm_k_getin.return
}
.segment Code
  // strcpy
// Copies the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcpy(char *destination, __zp($2b) char *source)
strcpy: {
    .label src = $2b
    .label dst = $23
    .label source = $2b
    // [483] phi from strcpy strcpy::@2 to strcpy::@1 [phi:strcpy/strcpy::@2->strcpy::@1]
    // [483] phi strcpy::dst#2 = strcpy::dst#0 [phi:strcpy/strcpy::@2->strcpy::@1#0] -- register_copy 
    // [483] phi strcpy::src#2 = strcpy::src#0 [phi:strcpy/strcpy::@2->strcpy::@1#1] -- register_copy 
    // strcpy::@1
  __b1:
    // while(*src)
    // [484] if(0!=*strcpy::src#2) goto strcpy::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcpy::@3
    // *dst = 0
    // [485] *strcpy::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcpy::@return
    // }
    // [486] return 
    rts
    // strcpy::@2
  __b2:
    // *dst++ = *src++
    // [487] *strcpy::dst#2 = *strcpy::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [488] strcpy::dst#1 = ++ strcpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [489] strcpy::src#1 = ++ strcpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    jmp __b1
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
// __zp($2d) struct $2 * fopen(__zp($29) const char *path, const char *mode)
fopen: {
    .label fopen__11 = $36
    .label fopen__28 = $3b
    .label cbm_k_setnam1_filename = $43
    .label stream = $2d
    .label pathtoken = $2b
    .label path = $29
    .label return = $2d
    // unsigned char sp = __stdio_filecount
    // [490] fopen::sp#0 = __stdio_filecount -- vbum1=vbum2 
    lda __stdio_filecount
    sta sp
    // (unsigned int)sp | 0x8000
    // [491] fopen::$30 = (unsigned int)fopen::sp#0 -- vwum1=_word_vbum2 
    sta fopen__30
    lda #0
    sta fopen__30+1
    // [492] fopen::stream#0 = fopen::$30 | $8000 -- vwuz1=vwum2_bor_vwuc1 
    lda fopen__30
    ora #<$8000
    sta.z stream
    lda fopen__30+1
    ora #>$8000
    sta.z stream+1
    // char pathpos = sp * __STDIO_FILECOUNT
    // [493] fopen::pathpos#0 = fopen::sp#0 << 1 -- vbum1=vbum2_rol_1 
    lda sp
    asl
    sta pathpos
    // __logical = 0
    // [494] ((char *)&__stdio_file+$40)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy sp
    sta __stdio_file+$40,y
    // __device = 0
    // [495] ((char *)&__stdio_file+$42)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [496] ((char *)&__stdio_file+$44)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$44,y
    // [497] fopen::pathpos#21 = fopen::pathpos#0 -- vbum1=vbum2 
    lda pathpos
    sta pathpos_1
    // [498] phi from fopen to fopen::@8 [phi:fopen->fopen::@8]
    // [498] phi fopen::num#10 = 0 [phi:fopen->fopen::@8#0] -- vbum1=vbuc1 
    lda #0
    sta num
    // [498] phi fopen::pathpos#10 = fopen::pathpos#21 [phi:fopen->fopen::@8#1] -- register_copy 
    // [498] phi fopen::path#13 = file [phi:fopen->fopen::@8#2] -- pbuz1=pbuc1 
    lda #<file
    sta.z path
    lda #>file
    sta.z path+1
    // [498] phi fopen::pathstep#10 = 0 [phi:fopen->fopen::@8#3] -- vbum1=vbuc1 
    lda #0
    sta pathstep
    // [498] phi fopen::pathtoken#10 = file [phi:fopen->fopen::@8#4] -- pbuz1=pbuc1 
    lda #<file
    sta.z pathtoken
    lda #>file
    sta.z pathtoken+1
  // Iterate while path is not \0.
    // [498] phi from fopen::@22 to fopen::@8 [phi:fopen::@22->fopen::@8]
    // [498] phi fopen::num#10 = fopen::num#13 [phi:fopen::@22->fopen::@8#0] -- register_copy 
    // [498] phi fopen::pathpos#10 = fopen::pathpos#7 [phi:fopen::@22->fopen::@8#1] -- register_copy 
    // [498] phi fopen::path#13 = fopen::path#10 [phi:fopen::@22->fopen::@8#2] -- register_copy 
    // [498] phi fopen::pathstep#10 = fopen::pathstep#11 [phi:fopen::@22->fopen::@8#3] -- register_copy 
    // [498] phi fopen::pathtoken#10 = fopen::pathtoken#1 [phi:fopen::@22->fopen::@8#4] -- register_copy 
    // fopen::@8
  __b8:
    // if (*pathtoken == ',' || *pathtoken == '\0')
    // [499] if(*fopen::pathtoken#10==',') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #','
    ldy #0
    cmp (pathtoken),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@33
    // [500] if(*fopen::pathtoken#10=='@') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #'@'
    cmp (pathtoken),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@23
    // if (pathstep == 0)
    // [501] if(fopen::pathstep#10!=0) goto fopen::@10 -- vbum1_neq_0_then_la1 
    lda pathstep
    bne __b10
    // fopen::@24
    // __stdio_file.filename[pathpos] = *pathtoken
    // [502] ((char *)&__stdio_file)[fopen::pathpos#10] = *fopen::pathtoken#10 -- pbuc1_derefidx_vbum1=_deref_pbuz2 
    lda (pathtoken),y
    ldy pathpos_1
    sta __stdio_file,y
    // pathpos++;
    // [503] fopen::pathpos#1 = ++ fopen::pathpos#10 -- vbum1=_inc_vbum1 
    inc pathpos_1
    // [504] phi from fopen::@12 fopen::@23 fopen::@24 to fopen::@10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10]
    // [504] phi fopen::num#13 = fopen::num#15 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#0] -- register_copy 
    // [504] phi fopen::pathpos#7 = fopen::pathpos#10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#1] -- register_copy 
    // [504] phi fopen::path#10 = fopen::path#12 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#2] -- register_copy 
    // [504] phi fopen::pathstep#11 = fopen::pathstep#1 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#3] -- register_copy 
    // fopen::@10
  __b10:
    // pathtoken++;
    // [505] fopen::pathtoken#1 = ++ fopen::pathtoken#10 -- pbuz1=_inc_pbuz1 
    inc.z pathtoken
    bne !+
    inc.z pathtoken+1
  !:
    // fopen::@22
    // pathtoken - 1
    // [506] fopen::$28 = fopen::pathtoken#1 - 1 -- pbuz1=pbuz2_minus_1 
    lda.z pathtoken
    sec
    sbc #1
    sta.z fopen__28
    lda.z pathtoken+1
    sbc #0
    sta.z fopen__28+1
    // while (*(pathtoken - 1))
    // [507] if(0!=*fopen::$28) goto fopen::@8 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (fopen__28),y
    cmp #0
    bne __b8
    // fopen::@26
    // __status = 0
    // [508] ((char *)&__stdio_file+$46)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    tya
    ldy sp
    sta __stdio_file+$46,y
    // if(!__logical)
    // [509] if(0!=((char *)&__stdio_file+$40)[fopen::sp#0]) goto fopen::@1 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$40,y
    cmp #0
    bne __b1
    // fopen::@27
    // __stdio_filecount+1
    // [510] fopen::$4 = __stdio_filecount + 1 -- vbum1=vbum2_plus_1 
    lda __stdio_filecount
    inc
    sta fopen__4
    // __logical = __stdio_filecount+1
    // [511] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::$4 -- pbuc1_derefidx_vbum1=vbum2 
    sta __stdio_file+$40,y
    // fopen::@1
  __b1:
    // if(!__device)
    // [512] if(0!=((char *)&__stdio_file+$42)[fopen::sp#0]) goto fopen::@2 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    ldy sp
    lda __stdio_file+$42,y
    cmp #0
    bne __b2
    // fopen::@5
    // __device = 8
    // [513] ((char *)&__stdio_file+$42)[fopen::sp#0] = 8 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #8
    sta __stdio_file+$42,y
    // fopen::@2
  __b2:
    // if(!__channel)
    // [514] if(0!=((char *)&__stdio_file+$44)[fopen::sp#0]) goto fopen::@3 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    ldy sp
    lda __stdio_file+$44,y
    cmp #0
    bne __b3
    // fopen::@6
    // __stdio_filecount+2
    // [515] fopen::$9 = __stdio_filecount + 2 -- vbum1=vbum2_plus_2 
    lda __stdio_filecount
    clc
    adc #2
    sta fopen__9
    // __channel = __stdio_filecount+2
    // [516] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::$9 -- pbuc1_derefidx_vbum1=vbum2 
    sta __stdio_file+$44,y
    // fopen::@3
  __b3:
    // __filename
    // [517] fopen::$11 = (char *)&__stdio_file + fopen::pathpos#0 -- pbuz1=pbuc1_plus_vbum2 
    lda pathpos
    clc
    adc #<__stdio_file
    sta.z fopen__11
    lda #>__stdio_file
    adc #0
    sta.z fopen__11+1
    // cbm_k_setnam(__filename)
    // [518] fopen::cbm_k_setnam1_filename = fopen::$11 -- pbuz1=pbuz2 
    lda.z fopen__11
    sta.z cbm_k_setnam1_filename
    lda.z fopen__11+1
    sta.z cbm_k_setnam1_filename+1
    // fopen::cbm_k_setnam1
    // strlen(filename)
    // [519] strlen::str#4 = fopen::cbm_k_setnam1_filename -- pbuz1=pbuz2 
    lda.z cbm_k_setnam1_filename
    sta.z strlen.str
    lda.z cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [520] call strlen
    // [899] phi from fopen::cbm_k_setnam1 to strlen [phi:fopen::cbm_k_setnam1->strlen]
    // [899] phi strlen::str#8 = strlen::str#4 [phi:fopen::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [521] strlen::return#11 = strlen::len#2
    // fopen::@31
    // [522] fopen::cbm_k_setnam1_$0 = strlen::return#11
    // char filename_len = (char)strlen(filename)
    // [523] fopen::cbm_k_setnam1_filename_len = (char)fopen::cbm_k_setnam1_$0 -- vbum1=_byte_vwum2 
    lda cbm_k_setnam1_fopen__0
    sta cbm_k_setnam1_filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx cbm_k_setnam1_filename
    ldy cbm_k_setnam1_filename+1
    jsr CBM_SETNAM
    // fopen::@28
    // cbm_k_setlfs(__logical, __device, __channel)
    // [525] cbm_k_setlfs::channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$40,y
    sta cbm_k_setlfs.channel
    // [526] cbm_k_setlfs::device = ((char *)&__stdio_file+$42)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    lda __stdio_file+$42,y
    sta cbm_k_setlfs.device
    // [527] cbm_k_setlfs::command = ((char *)&__stdio_file+$44)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    lda __stdio_file+$44,y
    sta cbm_k_setlfs.command
    // [528] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // fopen::cbm_k_open1
    // asm
    // asm { jsrCBM_OPEN  }
    jsr CBM_OPEN
    // fopen::cbm_k_readst1
    // char status
    // [530] fopen::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [532] fopen::cbm_k_readst1_return#0 = fopen::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fopen::cbm_k_readst1_@return
    // }
    // [533] fopen::cbm_k_readst1_return#1 = fopen::cbm_k_readst1_return#0
    // fopen::@29
    // cbm_k_readst()
    // [534] fopen::$15 = fopen::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [535] ((char *)&__stdio_file+$46)[fopen::sp#0] = fopen::$15 -- pbuc1_derefidx_vbum1=vbum2 
    lda fopen__15
    ldy sp
    sta __stdio_file+$46,y
    // ferror(stream)
    // [536] ferror::stream#0 = (struct $2 *)fopen::stream#0
    // [537] call ferror
    jsr ferror
    // [538] ferror::return#0 = ferror::return#1
    // fopen::@32
    // [539] fopen::$16 = ferror::return#0
    // if (ferror(stream))
    // [540] if(0==fopen::$16) goto fopen::@4 -- 0_eq_vwsm1_then_la1 
    lda fopen__16
    ora fopen__16+1
    beq __b4
    // fopen::@7
    // cbm_k_close(__logical)
    // [541] fopen::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$40,y
    sta cbm_k_close1_channel
    // fopen::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // [543] phi from fopen::cbm_k_close1 to fopen::@return [phi:fopen::cbm_k_close1->fopen::@return]
    // [543] phi fopen::return#2 = 0 [phi:fopen::cbm_k_close1->fopen::@return#0] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [544] return 
    rts
    // fopen::@4
  __b4:
    // __stdio_filecount++;
    // [545] __stdio_filecount = ++ __stdio_filecount -- vbum1=_inc_vbum1 
    inc __stdio_filecount
    // [546] fopen::return#6 = (struct $2 *)fopen::stream#0
    // [543] phi from fopen::@4 to fopen::@return [phi:fopen::@4->fopen::@return]
    // [543] phi fopen::return#2 = fopen::return#6 [phi:fopen::@4->fopen::@return#0] -- register_copy 
    rts
    // fopen::@9
  __b9:
    // if (pathstep > 0)
    // [547] if(fopen::pathstep#10>0) goto fopen::@11 -- vbum1_gt_0_then_la1 
    lda pathstep
    bne __b11
    // fopen::@25
    // __stdio_file.filename[pathpos] = '\0'
    // [548] ((char *)&__stdio_file)[fopen::pathpos#10] = '@' -- pbuc1_derefidx_vbum1=vbuc2 
    lda #'@'
    ldy pathpos_1
    sta __stdio_file,y
    // path = pathtoken + 1
    // [549] fopen::path#0 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
    clc
    lda.z pathtoken
    adc #1
    sta.z path
    lda.z pathtoken+1
    adc #0
    sta.z path+1
    // [550] phi from fopen::@16 fopen::@17 fopen::@18 fopen::@19 fopen::@25 to fopen::@12 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12]
    // [550] phi fopen::num#15 = fopen::num#2 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#0] -- register_copy 
    // [550] phi fopen::path#12 = fopen::path#15 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#1] -- register_copy 
    // fopen::@12
  __b12:
    // pathstep++;
    // [551] fopen::pathstep#1 = ++ fopen::pathstep#10 -- vbum1=_inc_vbum1 
    inc pathstep
    jmp __b10
    // fopen::@11
  __b11:
    // char pathcmp = *path
    // [552] fopen::pathcmp#0 = *fopen::path#13 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (path),y
    sta pathcmp
    // case 'D':
    // [553] if(fopen::pathcmp#0=='D') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'D'
    cmp pathcmp
    beq __b13
    // fopen::@20
    // case 'L':
    // [554] if(fopen::pathcmp#0=='L') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'L'
    cmp pathcmp
    beq __b13
    // fopen::@21
    // case 'C':
    //                     num = (char)atoi(path + 1);
    //                     path = pathtoken + 1;
    // [555] if(fopen::pathcmp#0=='C') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'C'
    cmp pathcmp
    beq __b13
    // [556] phi from fopen::@21 fopen::@30 to fopen::@14 [phi:fopen::@21/fopen::@30->fopen::@14]
    // [556] phi fopen::path#15 = fopen::path#13 [phi:fopen::@21/fopen::@30->fopen::@14#0] -- register_copy 
    // [556] phi fopen::num#2 = fopen::num#10 [phi:fopen::@21/fopen::@30->fopen::@14#1] -- register_copy 
    // fopen::@14
  __b14:
    // case 'L':
    //                     __logical = num;
    //                     break;
    // [557] if(fopen::pathcmp#0=='L') goto fopen::@17 -- vbum1_eq_vbuc1_then_la1 
    lda #'L'
    cmp pathcmp
    beq __b17
    // fopen::@15
    // case 'D':
    //                     __device = num;
    //                     break;
    // [558] if(fopen::pathcmp#0=='D') goto fopen::@18 -- vbum1_eq_vbuc1_then_la1 
    lda #'D'
    cmp pathcmp
    beq __b18
    // fopen::@16
    // case 'C':
    //                     __channel = num;
    //                     break;
    // [559] if(fopen::pathcmp#0!='C') goto fopen::@12 -- vbum1_neq_vbuc1_then_la1 
    lda #'C'
    cmp pathcmp
    bne __b12
    // fopen::@19
    // __channel = num
    // [560] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$44,y
    jmp __b12
    // fopen::@18
  __b18:
    // __device = num
    // [561] ((char *)&__stdio_file+$42)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$42,y
    jmp __b12
    // fopen::@17
  __b17:
    // __logical = num
    // [562] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$40,y
    jmp __b12
    // fopen::@13
  __b13:
    // atoi(path + 1)
    // [563] atoi::str#0 = fopen::path#13 + 1 -- pbuz1=pbuz1_plus_1 
    inc.z atoi.str
    bne !+
    inc.z atoi.str+1
  !:
    // [564] call atoi
    // [1091] phi from fopen::@13 to atoi [phi:fopen::@13->atoi]
    // [1091] phi atoi::str#2 = atoi::str#0 [phi:fopen::@13->atoi#0] -- register_copy 
    jsr atoi
    // atoi(path + 1)
    // [565] atoi::return#3 = atoi::return#2
    // fopen::@30
    // [566] fopen::$26 = atoi::return#3
    // num = (char)atoi(path + 1)
    // [567] fopen::num#1 = (char)fopen::$26 -- vbum1=_byte_vwsm2 
    lda fopen__26
    sta num
    // path = pathtoken + 1
    // [568] fopen::path#1 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
    clc
    lda.z pathtoken
    adc #1
    sta.z path
    lda.z pathtoken+1
    adc #0
    sta.z path+1
    jmp __b14
  .segment Data
    fopen__4: .byte 0
    fopen__9: .byte 0
    .label fopen__15 = cbm_k_readst1_return
    .label fopen__16 = ferror.return
    .label fopen__26 = atoi.return
    fopen__30: .word 0
    cbm_k_setnam1_filename_len: .byte 0
    .label cbm_k_setnam1_fopen__0 = strlen.len
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
  // flash_read
// __mem() unsigned long flash_read(__mem() char y, char w, char b, unsigned int r, __zp($3b) struct $2 *fp, __zp($2b) char *flash_ram_address)
flash_read: {
    .const r = $100
    .label b = 4
    .label flash_ram_address = $2b
    .label fp = $3b
    // textcolor(WHITE)
    // [570] call textcolor
    // [183] phi from flash_read to textcolor [phi:flash_read->textcolor]
    // [183] phi textcolor::color#17 = WHITE [phi:flash_read->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [571] phi from flash_read to flash_read::@5 [phi:flash_read->flash_read::@5]
    // flash_read::@5
    // gotoxy(0, y)
    // [572] call gotoxy
    // [201] phi from flash_read::@5 to gotoxy [phi:flash_read::@5->gotoxy]
    // [201] phi gotoxy::y#17 = $11 [phi:flash_read::@5->gotoxy#0] -- vbum1=vbuc1 
    lda #$11
    sta gotoxy.y
    // [201] phi gotoxy::x#17 = 0 [phi:flash_read::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.x
    jsr gotoxy
    // [573] phi from flash_read::@5 to flash_read::@1 [phi:flash_read::@5->flash_read::@1]
    // [573] phi flash_read::y#3 = $11 [phi:flash_read::@5->flash_read::@1#0] -- vbum1=vbuc1 
    lda #$11
    sta y
    // [573] phi flash_read::flash_bytes#2 = 0 [phi:flash_read::@5->flash_read::@1#1] -- vdum1=vduc1 
    lda #<0
    sta flash_bytes
    sta flash_bytes+1
    lda #<0>>$10
    sta flash_bytes+2
    lda #>0>>$10
    sta flash_bytes+3
    // [573] phi flash_read::flash_row_total#3 = 0 [phi:flash_read::@5->flash_read::@1#2] -- vwum1=vwuc1 
    lda #<0
    sta flash_row_total
    sta flash_row_total+1
    // [573] phi flash_read::flash_ram_address#2 = (char *) 16384 [phi:flash_read::@5->flash_read::@1#3] -- pbuz1=pbuc1 
    lda #<$4000
    sta.z flash_ram_address
    lda #>$4000
    sta.z flash_ram_address+1
  // We read b bytes at a time, and each b bytes we plot a dot.
  // Every r bytes we move to the next line.
    // flash_read::@1
  __b1:
    // fgets(flash_ram_address, b, fp)
    // [574] fgets::ptr#2 = flash_read::flash_ram_address#2 -- pbuz1=pbuz2 
    lda.z flash_ram_address
    sta.z fgets.ptr
    lda.z flash_ram_address+1
    sta.z fgets.ptr+1
    // [575] fgets::stream#0 = flash_read::fp#0
    // [576] call fgets
    jsr fgets
    // [577] fgets::return#5 = fgets::return#1
    // flash_read::@6
    // read_bytes = fgets(flash_ram_address, b, fp)
    // [578] flash_read::read_bytes#1 = fgets::return#5
    // while (read_bytes = fgets(flash_ram_address, b, fp))
    // [579] if(0!=flash_read::read_bytes#1) goto flash_read::@2 -- 0_neq_vwum1_then_la1 
    lda read_bytes
    ora read_bytes+1
    bne __b2
    // flash_read::@return
    // }
    // [580] return 
    rts
    // flash_read::@2
  __b2:
    // if (flash_row_total == r)
    // [581] if(flash_read::flash_row_total#3!=flash_read::r#0) goto flash_read::@3 -- vwum1_neq_vwuc1_then_la1 
    lda flash_row_total+1
    cmp #>r
    bne __b3
    lda flash_row_total
    cmp #<r
    bne __b3
    // flash_read::@4
    // gotoxy(0, ++y);
    // [582] flash_read::y#0 = ++ flash_read::y#3 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(0, ++y)
    // [583] gotoxy::y#13 = flash_read::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [584] call gotoxy
    // [201] phi from flash_read::@4 to gotoxy [phi:flash_read::@4->gotoxy]
    // [201] phi gotoxy::y#17 = gotoxy::y#13 [phi:flash_read::@4->gotoxy#0] -- register_copy 
    // [201] phi gotoxy::x#17 = 0 [phi:flash_read::@4->gotoxy#1] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.x
    jsr gotoxy
    // [585] phi from flash_read::@4 to flash_read::@3 [phi:flash_read::@4->flash_read::@3]
    // [585] phi flash_read::y#8 = flash_read::y#0 [phi:flash_read::@4->flash_read::@3#0] -- register_copy 
    // [585] phi flash_read::flash_row_total#4 = 0 [phi:flash_read::@4->flash_read::@3#1] -- vwum1=vbuc1 
    lda #<0
    sta flash_row_total
    sta flash_row_total+1
    // [585] phi from flash_read::@2 to flash_read::@3 [phi:flash_read::@2->flash_read::@3]
    // [585] phi flash_read::y#8 = flash_read::y#3 [phi:flash_read::@2->flash_read::@3#0] -- register_copy 
    // [585] phi flash_read::flash_row_total#4 = flash_read::flash_row_total#3 [phi:flash_read::@2->flash_read::@3#1] -- register_copy 
    // flash_read::@3
  __b3:
    // cputc('.')
    // [586] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [587] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // flash_ram_address += read_bytes
    // [589] flash_read::flash_ram_address#0 = flash_read::flash_ram_address#2 + flash_read::read_bytes#1 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z flash_ram_address
    adc read_bytes
    sta.z flash_ram_address
    lda.z flash_ram_address+1
    adc read_bytes+1
    sta.z flash_ram_address+1
    // flash_bytes += read_bytes
    // [590] flash_read::flash_bytes#1 = flash_read::flash_bytes#2 + flash_read::read_bytes#1 -- vdum1=vdum1_plus_vwum2 
    lda flash_bytes
    clc
    adc read_bytes
    sta flash_bytes
    lda flash_bytes+1
    adc read_bytes+1
    sta flash_bytes+1
    lda flash_bytes+2
    adc #0
    sta flash_bytes+2
    lda flash_bytes+3
    adc #0
    sta flash_bytes+3
    // flash_row_total += read_bytes
    // [591] flash_read::flash_row_total#1 = flash_read::flash_row_total#4 + flash_read::read_bytes#1 -- vwum1=vwum1_plus_vwum2 
    clc
    lda flash_row_total
    adc read_bytes
    sta flash_row_total
    lda flash_row_total+1
    adc read_bytes+1
    sta flash_row_total+1
    // [573] phi from flash_read::@3 to flash_read::@1 [phi:flash_read::@3->flash_read::@1]
    // [573] phi flash_read::y#3 = flash_read::y#8 [phi:flash_read::@3->flash_read::@1#0] -- register_copy 
    // [573] phi flash_read::flash_bytes#2 = flash_read::flash_bytes#1 [phi:flash_read::@3->flash_read::@1#1] -- register_copy 
    // [573] phi flash_read::flash_row_total#3 = flash_read::flash_row_total#1 [phi:flash_read::@3->flash_read::@1#2] -- register_copy 
    // [573] phi flash_read::flash_ram_address#2 = flash_read::flash_ram_address#0 [phi:flash_read::@3->flash_read::@1#3] -- register_copy 
    jmp __b1
  .segment Data
    .label read_bytes = fgets.read
    flash_bytes: .dword 0
    /// Holds the amount of bytes actually read in the memory to be flashed.
    flash_row_total: .word 0
    y: .byte 0
    .label return = flash_bytes
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
// int fclose(__zp($45) struct $2 *stream)
fclose: {
    .label stream = $45
    // unsigned char sp = (unsigned char)stream
    // [592] fclose::sp#0 = (char)fclose::stream#0 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_chkin(__logical)
    // [593] fclose::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    tay
    lda __stdio_file+$40,y
    sta cbm_k_chkin1_channel
    // fclose::cbm_k_chkin1
    // char status
    // [594] fclose::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fclose::cbm_k_readst1
    // char status
    // [596] fclose::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [598] fclose::cbm_k_readst1_return#0 = fclose::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fclose::cbm_k_readst1_@return
    // }
    // [599] fclose::cbm_k_readst1_return#1 = fclose::cbm_k_readst1_return#0
    // fclose::@3
    // cbm_k_readst()
    // [600] fclose::$1 = fclose::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [601] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$1 -- pbuc1_derefidx_vbum1=vbum2 
    lda fclose__1
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [602] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@1 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b1
    // fclose::@return
    // }
    // [603] return 
    rts
    // fclose::@1
  __b1:
    // cbm_k_close(__logical)
    // [604] fclose::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$40,y
    sta cbm_k_close1_channel
    // fclose::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // fclose::cbm_k_readst2
    // char status
    // [606] fclose::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [608] fclose::cbm_k_readst2_return#0 = fclose::cbm_k_readst2_status -- vbum1=vbum2 
    sta cbm_k_readst2_return
    // fclose::cbm_k_readst2_@return
    // }
    // [609] fclose::cbm_k_readst2_return#1 = fclose::cbm_k_readst2_return#0
    // fclose::@4
    // cbm_k_readst()
    // [610] fclose::$4 = fclose::cbm_k_readst2_return#1
    // __status = cbm_k_readst()
    // [611] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$4 -- pbuc1_derefidx_vbum1=vbum2 
    lda fclose__4
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [612] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@2 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b2
    rts
    // fclose::@2
  __b2:
    // __logical = 0
    // [613] ((char *)&__stdio_file+$40)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy sp
    sta __stdio_file+$40,y
    // __device = 0
    // [614] ((char *)&__stdio_file+$42)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [615] ((char *)&__stdio_file+$44)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$44,y
    // __filename
    // [616] fclose::$6 = fclose::sp#0 << 1 -- vbum1=vbum1_rol_1 
    asl fclose__6
    // *__filename = '\0'
    // [617] ((char *)&__stdio_file)[fclose::$6] = '@' -- pbuc1_derefidx_vbum1=vbuc2 
    lda #'@'
    ldy fclose__6
    sta __stdio_file,y
    // __stdio_filecount--;
    // [618] __stdio_filecount = -- __stdio_filecount -- vbum1=_dec_vbum1 
    dec __stdio_filecount
    rts
  .segment Data
    .label fclose__1 = cbm_k_readst1_return
    .label fclose__4 = cbm_k_readst2_return
    .label fclose__6 = sp
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
  // info_rom
// void info_rom(__mem() char info_rom, char info_status)
info_rom: {
    // if(info_rom)
    // [619] if(0!=info_rom::info_rom#0) goto info_rom::@1 -- 0_neq_vbum1_then_la1 
    lda info_rom
    beq !__b1+
    jmp __b1
  !__b1:
    // [620] phi from info_rom to info_rom::@5 [phi:info_rom->info_rom::@5]
    // info_rom::@5
    // sprintf(rom_name, "ROM%u - CX16", info_rom)
    // [621] call snprintf_init
    jsr snprintf_init
    // [622] phi from info_rom::@5 to info_rom::@11 [phi:info_rom::@5->info_rom::@11]
    // info_rom::@11
    // sprintf(rom_name, "ROM%u - CX16", info_rom)
    // [623] call printf_str
    // [290] phi from info_rom::@11 to printf_str [phi:info_rom::@11->printf_str]
    // [290] phi printf_str::putc#24 = &snputc [phi:info_rom::@11->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [290] phi printf_str::s#24 = info_rom::s [phi:info_rom::@11->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@12
    // sprintf(rom_name, "ROM%u - CX16", info_rom)
    // [624] printf_uchar::uvalue#1 = info_rom::info_rom#0 -- vbum1=vbum2 
    lda info_rom
    sta printf_uchar.uvalue
    // [625] call printf_uchar
    // [1155] phi from info_rom::@12 to printf_uchar [phi:info_rom::@12->printf_uchar]
    // [1155] phi printf_uchar::uvalue#2 = printf_uchar::uvalue#1 [phi:info_rom::@12->printf_uchar#0] -- register_copy 
    jsr printf_uchar
    // [626] phi from info_rom::@12 to info_rom::@13 [phi:info_rom::@12->info_rom::@13]
    // info_rom::@13
    // sprintf(rom_name, "ROM%u - CX16", info_rom)
    // [627] call printf_str
    // [290] phi from info_rom::@13 to printf_str [phi:info_rom::@13->printf_str]
    // [290] phi printf_str::putc#24 = &snputc [phi:info_rom::@13->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [290] phi printf_str::s#24 = info_rom::s3 [phi:info_rom::@13->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@14
    // sprintf(rom_name, "ROM%u - CX16", info_rom)
    // [628] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [629] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom::@2
  __b2:
    // if(rom_manufacturer_ids[info_rom])
    // [631] if(0!=rom_manufacturer_ids[info_rom::info_rom#0]) goto info_rom::@3 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    ldy info_rom
    lda rom_manufacturer_ids,y
    cmp #0
    beq !__b3+
    jmp __b3
  !__b3:
    // info_rom::@6
    // strcpy(rom_detected, status_text[STATUS_NONE])
    // [632] strcpy::source#2 = *(status_text+1*SIZEOF_POINTER) -- pbuz1=_deref_qbuc1 
    lda status_text+1*SIZEOF_POINTER
    sta.z strcpy.source
    lda status_text+1*SIZEOF_POINTER+1
    sta.z strcpy.source+1
    // [633] call strcpy
    // [482] phi from info_rom::@6 to strcpy [phi:info_rom::@6->strcpy]
    // [482] phi strcpy::dst#0 = info_rom::rom_detected [phi:info_rom::@6->strcpy#0] -- pbuz1=pbuc1 
    lda #<rom_detected
    sta.z strcpy.dst
    lda #>rom_detected
    sta.z strcpy.dst+1
    // [482] phi strcpy::src#0 = strcpy::source#2 [phi:info_rom::@6->strcpy#1] -- register_copy 
    jsr strcpy
    // info_rom::@16
    // print_rom_led(info_rom, BLACK)
    // [634] print_rom_led::chip#2 = info_rom::info_rom#0 -- vbum1=vbum2 
    lda info_rom
    sta print_rom_led.chip
    // [635] call print_rom_led
    // [995] phi from info_rom::@16 to print_rom_led [phi:info_rom::@16->print_rom_led]
    // [995] phi print_rom_led::c#3 = BLACK [phi:info_rom::@16->print_rom_led#0] -- vbum1=vbuc1 
    lda #BLACK
    sta print_rom_led.c
    // [995] phi print_rom_led::chip#3 = print_rom_led::chip#2 [phi:info_rom::@16->print_rom_led#1] -- register_copy 
    jsr print_rom_led
    // info_rom::@4
  __b4:
    // info_clear(2+info_rom)
    // [636] info_clear::l#3 = 2 + info_rom::info_rom#0 -- vbum1=vbuc1_plus_vbum2 
    lda #2
    clc
    adc info_rom
    sta info_clear.l
    // [637] call info_clear
    // [887] phi from info_rom::@4 to info_clear [phi:info_rom::@4->info_clear]
    // [887] phi info_clear::l#4 = info_clear::l#3 [phi:info_rom::@4->info_clear#0] -- register_copy 
    jsr info_clear
    // [638] phi from info_rom::@4 to info_rom::@17 [phi:info_rom::@4->info_rom::@17]
    // info_rom::@17
    // printf("%s - %-8s - %-8s - %-4s", rom_name, rom_detected, rom_device_names[info_rom], rom_size_strings[info_rom] )
    // [639] call printf_string
    // [333] phi from info_rom::@17 to printf_string [phi:info_rom::@17->printf_string]
    // [333] phi printf_string::str#10 = info_rom::rom_name [phi:info_rom::@17->printf_string#0] -- pbuz1=pbuc1 
    lda #<rom_name
    sta.z printf_string.str
    lda #>rom_name
    sta.z printf_string.str+1
    // [333] phi printf_string::format_justify_left#10 = 0 [phi:info_rom::@17->printf_string#1] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [333] phi printf_string::format_min_length#10 = 0 [phi:info_rom::@17->printf_string#2] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [640] phi from info_rom::@17 to info_rom::@18 [phi:info_rom::@17->info_rom::@18]
    // info_rom::@18
    // printf("%s - %-8s - %-8s - %-4s", rom_name, rom_detected, rom_device_names[info_rom], rom_size_strings[info_rom] )
    // [641] call printf_str
    // [290] phi from info_rom::@18 to printf_str [phi:info_rom::@18->printf_str]
    // [290] phi printf_str::putc#24 = &cputc [phi:info_rom::@18->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [290] phi printf_str::s#24 = info_rom::s4 [phi:info_rom::@18->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // [642] phi from info_rom::@18 to info_rom::@19 [phi:info_rom::@18->info_rom::@19]
    // info_rom::@19
    // printf("%s - %-8s - %-8s - %-4s", rom_name, rom_detected, rom_device_names[info_rom], rom_size_strings[info_rom] )
    // [643] call printf_string
    // [333] phi from info_rom::@19 to printf_string [phi:info_rom::@19->printf_string]
    // [333] phi printf_string::str#10 = info_rom::rom_detected [phi:info_rom::@19->printf_string#0] -- pbuz1=pbuc1 
    lda #<rom_detected
    sta.z printf_string.str
    lda #>rom_detected
    sta.z printf_string.str+1
    // [333] phi printf_string::format_justify_left#10 = 1 [phi:info_rom::@19->printf_string#1] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [333] phi printf_string::format_min_length#10 = 8 [phi:info_rom::@19->printf_string#2] -- vbum1=vbuc1 
    lda #8
    sta printf_string.format_min_length
    jsr printf_string
    // [644] phi from info_rom::@19 to info_rom::@20 [phi:info_rom::@19->info_rom::@20]
    // info_rom::@20
    // printf("%s - %-8s - %-8s - %-4s", rom_name, rom_detected, rom_device_names[info_rom], rom_size_strings[info_rom] )
    // [645] call printf_str
    // [290] phi from info_rom::@20 to printf_str [phi:info_rom::@20->printf_str]
    // [290] phi printf_str::putc#24 = &cputc [phi:info_rom::@20->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [290] phi printf_str::s#24 = info_rom::s4 [phi:info_rom::@20->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@21
    // printf("%s - %-8s - %-8s - %-4s", rom_name, rom_detected, rom_device_names[info_rom], rom_size_strings[info_rom] )
    // [646] info_rom::$12 = info_rom::info_rom#0 << 1 -- vbum1=vbum2_rol_1 
    lda info_rom
    asl
    sta info_rom__12
    // [647] printf_string::str#5 = rom_device_names[info_rom::$12] -- pbuz1=qbuc1_derefidx_vbum2 
    tay
    lda rom_device_names,y
    sta.z printf_string.str
    lda rom_device_names+1,y
    sta.z printf_string.str+1
    // [648] call printf_string
    // [333] phi from info_rom::@21 to printf_string [phi:info_rom::@21->printf_string]
    // [333] phi printf_string::str#10 = printf_string::str#5 [phi:info_rom::@21->printf_string#0] -- register_copy 
    // [333] phi printf_string::format_justify_left#10 = 1 [phi:info_rom::@21->printf_string#1] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [333] phi printf_string::format_min_length#10 = 8 [phi:info_rom::@21->printf_string#2] -- vbum1=vbuc1 
    lda #8
    sta printf_string.format_min_length
    jsr printf_string
    // [649] phi from info_rom::@21 to info_rom::@22 [phi:info_rom::@21->info_rom::@22]
    // info_rom::@22
    // printf("%s - %-8s - %-8s - %-4s", rom_name, rom_detected, rom_device_names[info_rom], rom_size_strings[info_rom] )
    // [650] call printf_str
    // [290] phi from info_rom::@22 to printf_str [phi:info_rom::@22->printf_str]
    // [290] phi printf_str::putc#24 = &cputc [phi:info_rom::@22->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [290] phi printf_str::s#24 = info_rom::s4 [phi:info_rom::@22->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@23
    // printf("%s - %-8s - %-8s - %-4s", rom_name, rom_detected, rom_device_names[info_rom], rom_size_strings[info_rom] )
    // [651] printf_string::str#6 = rom_size_strings[info_rom::$12] -- pbuz1=qbuc1_derefidx_vbum2 
    ldy info_rom__12
    lda rom_size_strings,y
    sta.z printf_string.str
    lda rom_size_strings+1,y
    sta.z printf_string.str+1
    // [652] call printf_string
    // [333] phi from info_rom::@23 to printf_string [phi:info_rom::@23->printf_string]
    // [333] phi printf_string::str#10 = printf_string::str#6 [phi:info_rom::@23->printf_string#0] -- register_copy 
    // [333] phi printf_string::format_justify_left#10 = 1 [phi:info_rom::@23->printf_string#1] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [333] phi printf_string::format_min_length#10 = 4 [phi:info_rom::@23->printf_string#2] -- vbum1=vbuc1 
    lda #4
    sta printf_string.format_min_length
    jsr printf_string
    // info_rom::@return
    // }
    // [653] return 
    rts
    // info_rom::@3
  __b3:
    // strcpy(rom_detected, status_text[info_status])
    // [654] strcpy::source#1 = *status_text -- pbuz1=_deref_qbuc1 
    lda status_text
    sta.z strcpy.source
    lda status_text+1
    sta.z strcpy.source+1
    // [655] call strcpy
    // [482] phi from info_rom::@3 to strcpy [phi:info_rom::@3->strcpy]
    // [482] phi strcpy::dst#0 = info_rom::rom_detected [phi:info_rom::@3->strcpy#0] -- pbuz1=pbuc1 
    lda #<rom_detected
    sta.z strcpy.dst
    lda #>rom_detected
    sta.z strcpy.dst+1
    // [482] phi strcpy::src#0 = strcpy::source#1 [phi:info_rom::@3->strcpy#1] -- register_copy 
    jsr strcpy
    // info_rom::@15
    // print_rom_led(info_rom, WHITE)
    // [656] print_rom_led::chip#1 = info_rom::info_rom#0 -- vbum1=vbum2 
    lda info_rom
    sta print_rom_led.chip
    // [657] call print_rom_led
    // [995] phi from info_rom::@15 to print_rom_led [phi:info_rom::@15->print_rom_led]
    // [995] phi print_rom_led::c#3 = WHITE [phi:info_rom::@15->print_rom_led#0] -- vbum1=vbuc1 
    lda #WHITE
    sta print_rom_led.c
    // [995] phi print_rom_led::chip#3 = print_rom_led::chip#1 [phi:info_rom::@15->print_rom_led#1] -- register_copy 
    jsr print_rom_led
    jmp __b4
    // [658] phi from info_rom to info_rom::@1 [phi:info_rom->info_rom::@1]
    // info_rom::@1
  __b1:
    // sprintf(rom_name, "ROM%u - CARD", info_rom)
    // [659] call snprintf_init
    jsr snprintf_init
    // [660] phi from info_rom::@1 to info_rom::@7 [phi:info_rom::@1->info_rom::@7]
    // info_rom::@7
    // sprintf(rom_name, "ROM%u - CARD", info_rom)
    // [661] call printf_str
    // [290] phi from info_rom::@7 to printf_str [phi:info_rom::@7->printf_str]
    // [290] phi printf_str::putc#24 = &snputc [phi:info_rom::@7->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [290] phi printf_str::s#24 = info_rom::s [phi:info_rom::@7->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@8
    // sprintf(rom_name, "ROM%u - CARD", info_rom)
    // [662] printf_uchar::uvalue#0 = info_rom::info_rom#0 -- vbum1=vbum2 
    lda info_rom
    sta printf_uchar.uvalue
    // [663] call printf_uchar
    // [1155] phi from info_rom::@8 to printf_uchar [phi:info_rom::@8->printf_uchar]
    // [1155] phi printf_uchar::uvalue#2 = printf_uchar::uvalue#0 [phi:info_rom::@8->printf_uchar#0] -- register_copy 
    jsr printf_uchar
    // [664] phi from info_rom::@8 to info_rom::@9 [phi:info_rom::@8->info_rom::@9]
    // info_rom::@9
    // sprintf(rom_name, "ROM%u - CARD", info_rom)
    // [665] call printf_str
    // [290] phi from info_rom::@9 to printf_str [phi:info_rom::@9->printf_str]
    // [290] phi printf_str::putc#24 = &snputc [phi:info_rom::@9->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [290] phi printf_str::s#24 = info_rom::s1 [phi:info_rom::@9->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@10
    // sprintf(rom_name, "ROM%u - CARD", info_rom)
    // [666] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [667] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b2
  .segment Data
    rom_name: .fill $10, 0
    rom_detected: .fill $10, 0
    s: .text "ROM"
    .byte 0
    s1: .text " - CARD"
    .byte 0
    s3: .text " - CX16"
    .byte 0
    s4: .text " - "
    .byte 0
    info_rom__12: .byte 0
    info_rom: .byte 0
}
.segment Code
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __mem() char mapbase, __mem() char config)
screenlayer: {
    .label y = $33
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [669] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [670] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [671] *((char *)&__conio+2) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+2
    // mapbase >> 7
    // [672] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbum1=vbum2_ror_7 
    lda mapbase
    rol
    rol
    and #1
    sta screenlayer__0
    // __conio.mapbase_bank = mapbase >> 7
    // [673] *((char *)&__conio+5) = screenlayer::$0 -- _deref_pbuc1=vbum1 
    sta __conio+5
    // (mapbase)<<1
    // [674] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbum1=vbum1_rol_1 
    asl screenlayer__1
    // MAKEWORD((mapbase)<<1,0)
    // [675] screenlayer::$2 = screenlayer::$1 w= 0 -- vwum1=vbum2_word_vbuc1 
    lda #0
    ldy screenlayer__1
    sty screenlayer__2+1
    sta screenlayer__2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [676] *((unsigned int *)&__conio+3) = screenlayer::$2 -- _deref_pwuc1=vwum1 
    sta __conio+3
    tya
    sta __conio+3+1
    // config & VERA_LAYER_WIDTH_MASK
    // [677] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbum1=vbum2_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and config
    sta screenlayer__7
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [678] screenlayer::$8 = screenlayer::$7 >> 4 -- vbum1=vbum1_ror_4 
    lda screenlayer__8
    lsr
    lsr
    lsr
    lsr
    sta screenlayer__8
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [679] *((char *)&__conio+8) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbum1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+8
    // config & VERA_LAYER_HEIGHT_MASK
    // [680] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbum1=vbum1_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and screenlayer__5
    sta screenlayer__5
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [681] screenlayer::$6 = screenlayer::$5 >> 6 -- vbum1=vbum1_ror_6 
    lda screenlayer__6
    rol
    rol
    rol
    and #3
    sta screenlayer__6
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [682] *((char *)&__conio+9) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbum1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+9
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [683] screenlayer::$16 = screenlayer::$8 << 1 -- vbum1=vbum1_rol_1 
    asl screenlayer__16
    // [684] *((unsigned int *)&__conio+$a) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbum1 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    ldy screenlayer__16
    lda VERA_LAYER_SKIP,y
    sta __conio+$a
    lda VERA_LAYER_SKIP+1,y
    sta __conio+$a+1
    // vera_dc_hscale_temp == 0x80
    // [685] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vbom1=vbum1_eq_vbuc1 
    lda screenlayer__9
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta screenlayer__9
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [686] screenlayer::$18 = (char)screenlayer::$9
    // [687] screenlayer::$10 = $28 << screenlayer::$18 -- vbum1=vbuc1_rol_vbum1 
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
    // [688] screenlayer::$11 = screenlayer::$10 - 1 -- vbum1=vbum1_minus_1 
    dec screenlayer__11
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [689] *((char *)&__conio+6) = screenlayer::$11 -- _deref_pbuc1=vbum1 
    lda screenlayer__11
    sta __conio+6
    // vera_dc_vscale_temp == 0x80
    // [690] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vbom1=vbum1_eq_vbuc1 
    lda screenlayer__12
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta screenlayer__12
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [691] screenlayer::$19 = (char)screenlayer::$12
    // [692] screenlayer::$13 = $1e << screenlayer::$19 -- vbum1=vbuc1_rol_vbum1 
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
    // [693] screenlayer::$14 = screenlayer::$13 - 1 -- vbum1=vbum1_minus_1 
    dec screenlayer__14
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [694] *((char *)&__conio+7) = screenlayer::$14 -- _deref_pbuc1=vbum1 
    lda screenlayer__14
    sta __conio+7
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [695] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta mapbase_offset
    lda __conio+3+1
    sta mapbase_offset+1
    // [696] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [696] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [696] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [697] if(screenlayer::y#2<=*((char *)&__conio+7)) goto screenlayer::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+7
    cmp.z y
    bcs __b2
    // screenlayer::@return
    // }
    // [698] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [699] screenlayer::$17 = screenlayer::y#2 << 1 -- vbum1=vbuz2_rol_1 
    lda.z y
    asl
    sta screenlayer__17
    // [700] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbum1=vwum2 
    tay
    lda mapbase_offset
    sta __conio+$15,y
    lda mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [701] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda mapbase_offset
    adc __conio+$a
    sta mapbase_offset
    lda mapbase_offset+1
    adc __conio+$a+1
    sta mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [702] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [696] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [696] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [696] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    VERA_LAYER_DIM: .byte $1f, $3f, $7f, $ff
    VERA_LAYER_SKIP: .word $40, $80, $100, $200
    screenlayer__0: .byte 0
    .label screenlayer__1 = mapbase
    screenlayer__2: .word 0
    .label screenlayer__5 = config
    .label screenlayer__6 = config
    screenlayer__7: .byte 0
    .label screenlayer__8 = screenlayer__7
    .label screenlayer__9 = vera_dc_hscale_temp
    .label screenlayer__10 = vera_dc_hscale_temp
    .label screenlayer__11 = vera_dc_hscale_temp
    .label screenlayer__12 = vera_dc_vscale_temp
    .label screenlayer__13 = vera_dc_vscale_temp
    .label screenlayer__14 = vera_dc_vscale_temp
    .label screenlayer__16 = screenlayer__7
    screenlayer__17: .byte 0
    .label screenlayer__18 = vera_dc_hscale_temp
    .label screenlayer__19 = vera_dc_vscale_temp
    mapbase: .byte 0
    config: .byte 0
    vera_dc_hscale_temp: .byte 0
    vera_dc_vscale_temp: .byte 0
    mapbase_offset: .word 0
}
.segment Code
  // cscroll
// Scroll the entire screen if the cursor is beyond the last line
cscroll: {
    // if(__conio.cursor_y>__conio.height)
    // [703] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [704] if(0!=((char *)&__conio+$f)[*((char *)&__conio+2)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [705] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // [706] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [707] call gotoxy
    // [201] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [201] phi gotoxy::y#17 = 0 [phi:cscroll::@3->gotoxy#0] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.y
    // [201] phi gotoxy::x#17 = 0 [phi:cscroll::@3->gotoxy#1] -- vbum1=vbuc1 
    sta gotoxy.x
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [708] return 
    rts
    // [709] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [710] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [711] gotoxy::y#3 = *((char *)&__conio+7) -- vbum1=_deref_pbuc1 
    lda __conio+7
    sta gotoxy.y
    // [712] call gotoxy
    // [201] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [201] phi gotoxy::y#17 = gotoxy::y#3 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [201] phi gotoxy::x#17 = 0 [phi:cscroll::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.x
    jsr gotoxy
    // [713] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [714] call clearline
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
    // [715] ((char *)&__conio+$f)[*((char *)&__conio+2)] = scroll::onoff#0 -- pbuc1_derefidx_(_deref_pbuc2)=vbuc3 
    lda #onoff
    ldy __conio+2
    sta __conio+$f,y
    // scroll::@return
    // }
    // [716] return 
    rts
}
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    // unsigned int line_text = __conio.mapbase_offset
    // [717] clrscr::line_text#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta line_text
    lda __conio+3+1
    sta line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [718] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [719] clrscr::$0 = *((char *)&__conio+5) | VERA_INC_1 -- vbum1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta clrscr__0
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [720] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [721] clrscr::l#0 = *((char *)&__conio+9) -- vbum1=_deref_pbuc1 
    lda __conio+9
    sta l
    // [722] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [722] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [722] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [723] clrscr::$1 = byte0  clrscr::ch#0 -- vbum1=_byte0_vwum2 
    lda ch
    sta clrscr__1
    // *VERA_ADDRX_L = BYTE0(ch)
    // [724] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbum1 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [725] clrscr::$2 = byte1  clrscr::ch#0 -- vbum1=_byte1_vwum2 
    lda ch+1
    sta clrscr__2
    // *VERA_ADDRX_M = BYTE1(ch)
    // [726] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth+1
    // [727] clrscr::c#0 = *((char *)&__conio+8) + 1 -- vbum1=_deref_pbuc1_plus_1 
    lda __conio+8
    inc
    sta c
    // [728] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [728] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [729] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [730] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [731] clrscr::c#1 = -- clrscr::c#2 -- vbum1=_dec_vbum1 
    dec c
    // while(c)
    // [732] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [733] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda line_text
    adc __conio+$a
    sta line_text
    lda line_text+1
    adc __conio+$a+1
    sta line_text+1
    // l--;
    // [734] clrscr::l#1 = -- clrscr::l#4 -- vbum1=_dec_vbum1 
    dec l
    // while(l)
    // [735] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbum1_then_la1 
    lda l
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [736] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y = 0
    // [737] *((char *)&__conio+1) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+1
    // __conio.offset = __conio.mapbase_offset
    // [738] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+3) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+3
    sta __conio+$13
    lda __conio+3+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [739] return 
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
  // frame
// Draw a line horizontal from a given xy position and a given length.
// The line should calculate the matching characters to draw and glue them.
// So it first needs to peek the characters at the given position.
// And then calculate the resulting characters to draw.
// void frame(char x0, char y0, __mem() char x1, __mem() char y1)
frame: {
    // unsigned char w = x1 - x0
    // [741] frame::w#0 = frame::x1#16 - frame::x#0 -- vbum1=vbum2_minus_vbum3 
    lda x1
    sec
    sbc x
    sta w
    // unsigned char h = y1 - y0
    // [742] frame::h#0 = frame::y1#16 - frame::y#0 -- vbum1=vbum2_minus_vbum3 
    lda y1
    sec
    sbc y
    sta h
    // unsigned char mask = frame_maskxy(x, y)
    // [743] frame_maskxy::x#0 = frame::x#0 -- vbum1=vbum2 
    lda x
    sta frame_maskxy.x
    // [744] frame_maskxy::y#0 = frame::y#0 -- vbum1=vbum2 
    lda y
    sta frame_maskxy.y
    // [745] call frame_maskxy
    // [1195] phi from frame to frame_maskxy [phi:frame->frame_maskxy]
    // [1195] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#0 [phi:frame->frame_maskxy#0] -- register_copy 
    // [1195] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#0 [phi:frame->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // unsigned char mask = frame_maskxy(x, y)
    // [746] frame_maskxy::return#13 = frame_maskxy::return#12
    // frame::@13
    // [747] frame::mask#0 = frame_maskxy::return#13
    // mask |= 0b0110
    // [748] frame::mask#1 = frame::mask#0 | 6 -- vbum1=vbum1_bor_vbuc1 
    lda #6
    ora mask
    sta mask
    // unsigned char c = frame_char(mask)
    // [749] frame_char::mask#0 = frame::mask#1
    // [750] call frame_char
  // Add a corner.
    // [1221] phi from frame::@13 to frame_char [phi:frame::@13->frame_char]
    // [1221] phi frame_char::mask#10 = frame_char::mask#0 [phi:frame::@13->frame_char#0] -- register_copy 
    jsr frame_char
    // unsigned char c = frame_char(mask)
    // [751] frame_char::return#13 = frame_char::return#12
    // frame::@14
    // [752] frame::c#0 = frame_char::return#13
    // cputcxy(x, y, c)
    // [753] cputcxy::x#0 = frame::x#0 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [754] cputcxy::y#0 = frame::y#0 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [755] cputcxy::c#0 = frame::c#0
    // [756] call cputcxy
    // [879] phi from frame::@14 to cputcxy [phi:frame::@14->cputcxy]
    // [879] phi cputcxy::c#11 = cputcxy::c#0 [phi:frame::@14->cputcxy#0] -- register_copy 
    // [879] phi cputcxy::y#11 = cputcxy::y#0 [phi:frame::@14->cputcxy#1] -- register_copy 
    // [879] phi cputcxy::x#11 = cputcxy::x#0 [phi:frame::@14->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@15
    // if(w>=2)
    // [757] if(frame::w#0<2) goto frame::@36 -- vbum1_lt_vbuc1_then_la1 
    lda w
    cmp #2
    bcs !__b36+
    jmp __b36
  !__b36:
    // frame::@2
    // x++;
    // [758] frame::x#1 = ++ frame::x#0 -- vbum1=_inc_vbum2 
    lda x
    inc
    sta x_1
    // [759] phi from frame::@2 frame::@21 to frame::@4 [phi:frame::@2/frame::@21->frame::@4]
    // [759] phi frame::x#10 = frame::x#1 [phi:frame::@2/frame::@21->frame::@4#0] -- register_copy 
    // frame::@4
  __b4:
    // while(x < x1)
    // [760] if(frame::x#10<frame::x1#16) goto frame::@5 -- vbum1_lt_vbum2_then_la1 
    lda x_1
    cmp x1
    bcs !__b5+
    jmp __b5
  !__b5:
    // [761] phi from frame::@36 frame::@4 to frame::@1 [phi:frame::@36/frame::@4->frame::@1]
    // [761] phi frame::x#24 = frame::x#30 [phi:frame::@36/frame::@4->frame::@1#0] -- register_copy 
    // frame::@1
  __b1:
    // frame_maskxy(x, y)
    // [762] frame_maskxy::x#1 = frame::x#24 -- vbum1=vbum2 
    lda x_1
    sta frame_maskxy.x
    // [763] frame_maskxy::y#1 = frame::y#0 -- vbum1=vbum2 
    lda y
    sta frame_maskxy.y
    // [764] call frame_maskxy
    // [1195] phi from frame::@1 to frame_maskxy [phi:frame::@1->frame_maskxy]
    // [1195] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#1 [phi:frame::@1->frame_maskxy#0] -- register_copy 
    // [1195] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#1 [phi:frame::@1->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [765] frame_maskxy::return#14 = frame_maskxy::return#12
    // frame::@16
    // mask = frame_maskxy(x, y)
    // [766] frame::mask#2 = frame_maskxy::return#14
    // mask |= 0b0011
    // [767] frame::mask#3 = frame::mask#2 | 3 -- vbum1=vbum1_bor_vbuc1 
    lda #3
    ora mask
    sta mask
    // frame_char(mask)
    // [768] frame_char::mask#1 = frame::mask#3
    // [769] call frame_char
    // [1221] phi from frame::@16 to frame_char [phi:frame::@16->frame_char]
    // [1221] phi frame_char::mask#10 = frame_char::mask#1 [phi:frame::@16->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [770] frame_char::return#14 = frame_char::return#12
    // frame::@17
    // c = frame_char(mask)
    // [771] frame::c#1 = frame_char::return#14
    // cputcxy(x, y, c)
    // [772] cputcxy::x#1 = frame::x#24 -- vbum1=vbum2 
    lda x_1
    sta cputcxy.x
    // [773] cputcxy::y#1 = frame::y#0 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [774] cputcxy::c#1 = frame::c#1
    // [775] call cputcxy
    // [879] phi from frame::@17 to cputcxy [phi:frame::@17->cputcxy]
    // [879] phi cputcxy::c#11 = cputcxy::c#1 [phi:frame::@17->cputcxy#0] -- register_copy 
    // [879] phi cputcxy::y#11 = cputcxy::y#1 [phi:frame::@17->cputcxy#1] -- register_copy 
    // [879] phi cputcxy::x#11 = cputcxy::x#1 [phi:frame::@17->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@18
    // if(h>=2)
    // [776] if(frame::h#0<2) goto frame::@return -- vbum1_lt_vbuc1_then_la1 
    lda h
    cmp #2
    bcc __breturn
    // frame::@3
    // y++;
    // [777] frame::y#1 = ++ frame::y#0 -- vbum1=_inc_vbum2 
    lda y
    inc
    sta y_1
    // [778] phi from frame::@27 frame::@3 to frame::@6 [phi:frame::@27/frame::@3->frame::@6]
    // [778] phi frame::y#10 = frame::y#2 [phi:frame::@27/frame::@3->frame::@6#0] -- register_copy 
    // frame::@6
  __b6:
    // while(y < y1)
    // [779] if(frame::y#10<frame::y1#16) goto frame::@7 -- vbum1_lt_vbum2_then_la1 
    lda y_1
    cmp y1
    bcs !__b7+
    jmp __b7
  !__b7:
    // frame::@8
    // frame_maskxy(x, y)
    // [780] frame_maskxy::x#5 = frame::x#0 -- vbum1=vbum2 
    lda x
    sta frame_maskxy.x
    // [781] frame_maskxy::y#5 = frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta frame_maskxy.y
    // [782] call frame_maskxy
    // [1195] phi from frame::@8 to frame_maskxy [phi:frame::@8->frame_maskxy]
    // [1195] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#5 [phi:frame::@8->frame_maskxy#0] -- register_copy 
    // [1195] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#5 [phi:frame::@8->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [783] frame_maskxy::return#18 = frame_maskxy::return#12
    // frame::@28
    // mask = frame_maskxy(x, y)
    // [784] frame::mask#10 = frame_maskxy::return#18
    // mask |= 0b1100
    // [785] frame::mask#11 = frame::mask#10 | $c -- vbum1=vbum1_bor_vbuc1 
    lda #$c
    ora mask
    sta mask
    // frame_char(mask)
    // [786] frame_char::mask#5 = frame::mask#11
    // [787] call frame_char
    // [1221] phi from frame::@28 to frame_char [phi:frame::@28->frame_char]
    // [1221] phi frame_char::mask#10 = frame_char::mask#5 [phi:frame::@28->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [788] frame_char::return#18 = frame_char::return#12
    // frame::@29
    // c = frame_char(mask)
    // [789] frame::c#5 = frame_char::return#18
    // cputcxy(x, y, c)
    // [790] cputcxy::x#5 = frame::x#0 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [791] cputcxy::y#5 = frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [792] cputcxy::c#5 = frame::c#5
    // [793] call cputcxy
    // [879] phi from frame::@29 to cputcxy [phi:frame::@29->cputcxy]
    // [879] phi cputcxy::c#11 = cputcxy::c#5 [phi:frame::@29->cputcxy#0] -- register_copy 
    // [879] phi cputcxy::y#11 = cputcxy::y#5 [phi:frame::@29->cputcxy#1] -- register_copy 
    // [879] phi cputcxy::x#11 = cputcxy::x#5 [phi:frame::@29->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@30
    // if(w>=2)
    // [794] if(frame::w#0<2) goto frame::@10 -- vbum1_lt_vbuc1_then_la1 
    lda w
    cmp #2
    bcc __b10
    // frame::@9
    // x++;
    // [795] frame::x#4 = ++ frame::x#0 -- vbum1=_inc_vbum1 
    inc x
    // [796] phi from frame::@35 frame::@9 to frame::@11 [phi:frame::@35/frame::@9->frame::@11]
    // [796] phi frame::x#18 = frame::x#5 [phi:frame::@35/frame::@9->frame::@11#0] -- register_copy 
    // frame::@11
  __b11:
    // while(x < x1)
    // [797] if(frame::x#18<frame::x1#16) goto frame::@12 -- vbum1_lt_vbum2_then_la1 
    lda x
    cmp x1
    bcc __b12
    // [798] phi from frame::@11 frame::@30 to frame::@10 [phi:frame::@11/frame::@30->frame::@10]
    // [798] phi frame::x#15 = frame::x#18 [phi:frame::@11/frame::@30->frame::@10#0] -- register_copy 
    // frame::@10
  __b10:
    // frame_maskxy(x, y)
    // [799] frame_maskxy::x#6 = frame::x#15 -- vbum1=vbum2 
    lda x
    sta frame_maskxy.x
    // [800] frame_maskxy::y#6 = frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta frame_maskxy.y
    // [801] call frame_maskxy
    // [1195] phi from frame::@10 to frame_maskxy [phi:frame::@10->frame_maskxy]
    // [1195] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#6 [phi:frame::@10->frame_maskxy#0] -- register_copy 
    // [1195] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#6 [phi:frame::@10->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [802] frame_maskxy::return#19 = frame_maskxy::return#12
    // frame::@31
    // mask = frame_maskxy(x, y)
    // [803] frame::mask#12 = frame_maskxy::return#19
    // mask |= 0b1001
    // [804] frame::mask#13 = frame::mask#12 | 9 -- vbum1=vbum1_bor_vbuc1 
    lda #9
    ora mask
    sta mask
    // frame_char(mask)
    // [805] frame_char::mask#6 = frame::mask#13
    // [806] call frame_char
    // [1221] phi from frame::@31 to frame_char [phi:frame::@31->frame_char]
    // [1221] phi frame_char::mask#10 = frame_char::mask#6 [phi:frame::@31->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [807] frame_char::return#19 = frame_char::return#12
    // frame::@32
    // c = frame_char(mask)
    // [808] frame::c#6 = frame_char::return#19
    // cputcxy(x, y, c)
    // [809] cputcxy::x#6 = frame::x#15 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [810] cputcxy::y#6 = frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [811] cputcxy::c#6 = frame::c#6
    // [812] call cputcxy
    // [879] phi from frame::@32 to cputcxy [phi:frame::@32->cputcxy]
    // [879] phi cputcxy::c#11 = cputcxy::c#6 [phi:frame::@32->cputcxy#0] -- register_copy 
    // [879] phi cputcxy::y#11 = cputcxy::y#6 [phi:frame::@32->cputcxy#1] -- register_copy 
    // [879] phi cputcxy::x#11 = cputcxy::x#6 [phi:frame::@32->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@return
  __breturn:
    // }
    // [813] return 
    rts
    // frame::@12
  __b12:
    // frame_maskxy(x, y)
    // [814] frame_maskxy::x#7 = frame::x#18 -- vbum1=vbum2 
    lda x
    sta frame_maskxy.x
    // [815] frame_maskxy::y#7 = frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta frame_maskxy.y
    // [816] call frame_maskxy
    // [1195] phi from frame::@12 to frame_maskxy [phi:frame::@12->frame_maskxy]
    // [1195] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#7 [phi:frame::@12->frame_maskxy#0] -- register_copy 
    // [1195] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#7 [phi:frame::@12->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [817] frame_maskxy::return#20 = frame_maskxy::return#12
    // frame::@33
    // mask = frame_maskxy(x, y)
    // [818] frame::mask#14 = frame_maskxy::return#20
    // mask |= 0b0101
    // [819] frame::mask#15 = frame::mask#14 | 5 -- vbum1=vbum1_bor_vbuc1 
    lda #5
    ora mask
    sta mask
    // frame_char(mask)
    // [820] frame_char::mask#7 = frame::mask#15
    // [821] call frame_char
    // [1221] phi from frame::@33 to frame_char [phi:frame::@33->frame_char]
    // [1221] phi frame_char::mask#10 = frame_char::mask#7 [phi:frame::@33->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [822] frame_char::return#20 = frame_char::return#12
    // frame::@34
    // c = frame_char(mask)
    // [823] frame::c#7 = frame_char::return#20
    // cputcxy(x, y, c)
    // [824] cputcxy::x#7 = frame::x#18 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [825] cputcxy::y#7 = frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [826] cputcxy::c#7 = frame::c#7
    // [827] call cputcxy
    // [879] phi from frame::@34 to cputcxy [phi:frame::@34->cputcxy]
    // [879] phi cputcxy::c#11 = cputcxy::c#7 [phi:frame::@34->cputcxy#0] -- register_copy 
    // [879] phi cputcxy::y#11 = cputcxy::y#7 [phi:frame::@34->cputcxy#1] -- register_copy 
    // [879] phi cputcxy::x#11 = cputcxy::x#7 [phi:frame::@34->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@35
    // x++;
    // [828] frame::x#5 = ++ frame::x#18 -- vbum1=_inc_vbum1 
    inc x
    jmp __b11
    // frame::@7
  __b7:
    // frame_maskxy(x0, y)
    // [829] frame_maskxy::x#3 = frame::x#0 -- vbum1=vbum2 
    lda x
    sta frame_maskxy.x
    // [830] frame_maskxy::y#3 = frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta frame_maskxy.y
    // [831] call frame_maskxy
    // [1195] phi from frame::@7 to frame_maskxy [phi:frame::@7->frame_maskxy]
    // [1195] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#3 [phi:frame::@7->frame_maskxy#0] -- register_copy 
    // [1195] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#3 [phi:frame::@7->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x0, y)
    // [832] frame_maskxy::return#16 = frame_maskxy::return#12
    // frame::@22
    // mask = frame_maskxy(x0, y)
    // [833] frame::mask#6 = frame_maskxy::return#16
    // mask |= 0b1010
    // [834] frame::mask#7 = frame::mask#6 | $a -- vbum1=vbum1_bor_vbuc1 
    lda #$a
    ora mask
    sta mask
    // frame_char(mask)
    // [835] frame_char::mask#3 = frame::mask#7
    // [836] call frame_char
    // [1221] phi from frame::@22 to frame_char [phi:frame::@22->frame_char]
    // [1221] phi frame_char::mask#10 = frame_char::mask#3 [phi:frame::@22->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [837] frame_char::return#16 = frame_char::return#12
    // frame::@23
    // c = frame_char(mask)
    // [838] frame::c#3 = frame_char::return#16
    // cputcxy(x0, y, c)
    // [839] cputcxy::x#3 = frame::x#0 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [840] cputcxy::y#3 = frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [841] cputcxy::c#3 = frame::c#3
    // [842] call cputcxy
    // [879] phi from frame::@23 to cputcxy [phi:frame::@23->cputcxy]
    // [879] phi cputcxy::c#11 = cputcxy::c#3 [phi:frame::@23->cputcxy#0] -- register_copy 
    // [879] phi cputcxy::y#11 = cputcxy::y#3 [phi:frame::@23->cputcxy#1] -- register_copy 
    // [879] phi cputcxy::x#11 = cputcxy::x#3 [phi:frame::@23->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@24
    // frame_maskxy(x1, y)
    // [843] frame_maskxy::x#4 = frame::x1#16 -- vbum1=vbum2 
    lda x1
    sta frame_maskxy.x
    // [844] frame_maskxy::y#4 = frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta frame_maskxy.y
    // [845] call frame_maskxy
    // [1195] phi from frame::@24 to frame_maskxy [phi:frame::@24->frame_maskxy]
    // [1195] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#4 [phi:frame::@24->frame_maskxy#0] -- register_copy 
    // [1195] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#4 [phi:frame::@24->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x1, y)
    // [846] frame_maskxy::return#17 = frame_maskxy::return#12
    // frame::@25
    // mask = frame_maskxy(x1, y)
    // [847] frame::mask#8 = frame_maskxy::return#17
    // mask |= 0b1010
    // [848] frame::mask#9 = frame::mask#8 | $a -- vbum1=vbum1_bor_vbuc1 
    lda #$a
    ora mask
    sta mask
    // frame_char(mask)
    // [849] frame_char::mask#4 = frame::mask#9
    // [850] call frame_char
    // [1221] phi from frame::@25 to frame_char [phi:frame::@25->frame_char]
    // [1221] phi frame_char::mask#10 = frame_char::mask#4 [phi:frame::@25->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [851] frame_char::return#17 = frame_char::return#12
    // frame::@26
    // c = frame_char(mask)
    // [852] frame::c#4 = frame_char::return#17
    // cputcxy(x1, y, c)
    // [853] cputcxy::x#4 = frame::x1#16 -- vbum1=vbum2 
    lda x1
    sta cputcxy.x
    // [854] cputcxy::y#4 = frame::y#10 -- vbum1=vbum2 
    lda y_1
    sta cputcxy.y
    // [855] cputcxy::c#4 = frame::c#4
    // [856] call cputcxy
    // [879] phi from frame::@26 to cputcxy [phi:frame::@26->cputcxy]
    // [879] phi cputcxy::c#11 = cputcxy::c#4 [phi:frame::@26->cputcxy#0] -- register_copy 
    // [879] phi cputcxy::y#11 = cputcxy::y#4 [phi:frame::@26->cputcxy#1] -- register_copy 
    // [879] phi cputcxy::x#11 = cputcxy::x#4 [phi:frame::@26->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@27
    // y++;
    // [857] frame::y#2 = ++ frame::y#10 -- vbum1=_inc_vbum1 
    inc y_1
    jmp __b6
    // frame::@5
  __b5:
    // frame_maskxy(x, y)
    // [858] frame_maskxy::x#2 = frame::x#10 -- vbum1=vbum2 
    lda x_1
    sta frame_maskxy.x
    // [859] frame_maskxy::y#2 = frame::y#0 -- vbum1=vbum2 
    lda y
    sta frame_maskxy.y
    // [860] call frame_maskxy
    // [1195] phi from frame::@5 to frame_maskxy [phi:frame::@5->frame_maskxy]
    // [1195] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#2 [phi:frame::@5->frame_maskxy#0] -- register_copy 
    // [1195] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#2 [phi:frame::@5->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [861] frame_maskxy::return#15 = frame_maskxy::return#12
    // frame::@19
    // mask = frame_maskxy(x, y)
    // [862] frame::mask#4 = frame_maskxy::return#15
    // mask |= 0b0101
    // [863] frame::mask#5 = frame::mask#4 | 5 -- vbum1=vbum1_bor_vbuc1 
    lda #5
    ora mask
    sta mask
    // frame_char(mask)
    // [864] frame_char::mask#2 = frame::mask#5
    // [865] call frame_char
    // [1221] phi from frame::@19 to frame_char [phi:frame::@19->frame_char]
    // [1221] phi frame_char::mask#10 = frame_char::mask#2 [phi:frame::@19->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [866] frame_char::return#15 = frame_char::return#12
    // frame::@20
    // c = frame_char(mask)
    // [867] frame::c#2 = frame_char::return#15
    // cputcxy(x, y, c)
    // [868] cputcxy::x#2 = frame::x#10 -- vbum1=vbum2 
    lda x_1
    sta cputcxy.x
    // [869] cputcxy::y#2 = frame::y#0 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [870] cputcxy::c#2 = frame::c#2
    // [871] call cputcxy
    // [879] phi from frame::@20 to cputcxy [phi:frame::@20->cputcxy]
    // [879] phi cputcxy::c#11 = cputcxy::c#2 [phi:frame::@20->cputcxy#0] -- register_copy 
    // [879] phi cputcxy::y#11 = cputcxy::y#2 [phi:frame::@20->cputcxy#1] -- register_copy 
    // [879] phi cputcxy::x#11 = cputcxy::x#2 [phi:frame::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@21
    // x++;
    // [872] frame::x#2 = ++ frame::x#10 -- vbum1=_inc_vbum1 
    inc x_1
    jmp __b4
    // frame::@36
  __b36:
    // [873] frame::x#30 = frame::x#0 -- vbum1=vbum2 
    lda x
    sta x_1
    jmp __b1
  .segment Data
    w: .byte 0
    h: .byte 0
    x: .byte 0
    y: .byte 0
    .label mask = frame_maskxy.return
    .label c = cputcxy.c
    x_1: .byte 0
    y_1: .byte 0
    x1: .byte 0
    y1: .byte 0
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
    // [875] call gotoxy
    // [201] phi from cputsxy to gotoxy [phi:cputsxy->gotoxy]
    // [201] phi gotoxy::y#17 = cputsxy::y#0 [phi:cputsxy->gotoxy#0] -- vbum1=vbuc1 
    lda #y
    sta gotoxy.y
    // [201] phi gotoxy::x#17 = cputsxy::x#0 [phi:cputsxy->gotoxy#1] -- vbum1=vbuc1 
    lda #x
    sta gotoxy.x
    jsr gotoxy
    // [876] phi from cputsxy to cputsxy::@1 [phi:cputsxy->cputsxy::@1]
    // cputsxy::@1
    // cputs(s)
    // [877] call cputs
    // [1236] phi from cputsxy::@1 to cputs [phi:cputsxy::@1->cputs]
    jsr cputs
    // cputsxy::@return
    // }
    // [878] return 
    rts
}
  // cputcxy
// Move cursor and output one character
// Same as "gotoxy (x, y); cputc (c);"
// void cputcxy(__mem() char x, __mem() char y, __mem() char c)
cputcxy: {
    // gotoxy(x, y)
    // [880] gotoxy::x#0 = cputcxy::x#11 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [881] gotoxy::y#0 = cputcxy::y#11 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [882] call gotoxy
    // [201] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [201] phi gotoxy::y#17 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [201] phi gotoxy::x#17 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [883] stackpush(char) = cputcxy::c#11 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [884] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [886] return 
    rts
  .segment Data
    x: .byte 0
    y: .byte 0
    c: .byte 0
}
.segment Code
  // info_clear
// void info_clear(__mem() char l)
info_clear: {
    .const w = $40
    // unsigned char y = INFO_Y+l
    // [888] info_clear::y#0 = $11 + info_clear::l#4 -- vbum1=vbuc1_plus_vbum1 
    lda #$11
    clc
    adc y
    sta y
    // [889] phi from info_clear to info_clear::@1 [phi:info_clear->info_clear::@1]
    // [889] phi info_clear::x#2 = 2 [phi:info_clear->info_clear::@1#0] -- vbum1=vbuc1 
    lda #2
    sta x
    // [889] phi info_clear::i#2 = 0 [phi:info_clear->info_clear::@1#1] -- vbum1=vbuc1 
    lda #0
    sta i
    // info_clear::@1
  __b1:
    // for(unsigned char i = 0; i < w; i++)
    // [890] if(info_clear::i#2<info_clear::w) goto info_clear::@2 -- vbum1_lt_vbuc1_then_la1 
    lda i
    cmp #w
    bcc __b2
    // info_clear::@3
    // gotoxy(PROGRESS_X, y)
    // [891] gotoxy::y#11 = info_clear::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [892] call gotoxy
    // [201] phi from info_clear::@3 to gotoxy [phi:info_clear::@3->gotoxy]
    // [201] phi gotoxy::y#17 = gotoxy::y#11 [phi:info_clear::@3->gotoxy#0] -- register_copy 
    // [201] phi gotoxy::x#17 = 2 [phi:info_clear::@3->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // info_clear::@return
    // }
    // [893] return 
    rts
    // info_clear::@2
  __b2:
    // cputcxy(x, y, ' ')
    // [894] cputcxy::x#10 = info_clear::x#2 -- vbum1=vbum2 
    lda x
    sta cputcxy.x
    // [895] cputcxy::y#10 = info_clear::y#0 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [896] call cputcxy
    // [879] phi from info_clear::@2 to cputcxy [phi:info_clear::@2->cputcxy]
    // [879] phi cputcxy::c#11 = ' ' [phi:info_clear::@2->cputcxy#0] -- vbum1=vbuc1 
    lda #' '
    sta cputcxy.c
    // [879] phi cputcxy::y#11 = cputcxy::y#10 [phi:info_clear::@2->cputcxy#1] -- register_copy 
    // [879] phi cputcxy::x#11 = cputcxy::x#10 [phi:info_clear::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // info_clear::@4
    // x++;
    // [897] info_clear::x#1 = ++ info_clear::x#2 -- vbum1=_inc_vbum1 
    inc x
    // for(unsigned char i = 0; i < w; i++)
    // [898] info_clear::i#1 = ++ info_clear::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [889] phi from info_clear::@4 to info_clear::@1 [phi:info_clear::@4->info_clear::@1]
    // [889] phi info_clear::x#2 = info_clear::x#1 [phi:info_clear::@4->info_clear::@1#0] -- register_copy 
    // [889] phi info_clear::i#2 = info_clear::i#1 [phi:info_clear::@4->info_clear::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label y = l
    x: .byte 0
    i: .byte 0
    l: .byte 0
}
.segment Code
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __mem() unsigned int strlen(__zp($25) char *str)
strlen: {
    .label str = $25
    // [900] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [900] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta len
    sta len+1
    // [900] phi strlen::str#6 = strlen::str#8 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [901] if(0!=*strlen::str#6) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [902] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [903] strlen::len#1 = ++ strlen::len#2 -- vwum1=_inc_vwum1 
    inc len
    bne !+
    inc len+1
  !:
    // str++;
    // [904] strlen::str#1 = ++ strlen::str#6 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [900] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [900] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [900] phi strlen::str#6 = strlen::str#1 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label return = len
    len: .word 0
}
.segment Code
  // printf_padding
// Print a padding char a number of times
// void printf_padding(void (*putc)(char), __mem() char pad, __mem() char length)
printf_padding: {
    // [906] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [906] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbum1=vbuc1 
    lda #0
    sta i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [907] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbum1_lt_vbum2_then_la1 
    lda i
    cmp length
    bcc __b2
    // printf_padding::@return
    // }
    // [908] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [909] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbum1 
    lda pad
    pha
    // [910] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [912] printf_padding::i#1 = ++ printf_padding::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [906] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [906] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    i: .byte 0
    length: .byte 0
    pad: .byte 0
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
// __mem() unsigned int cx16_k_i2c_read_byte(__mem() volatile char device, __mem() volatile char offset)
cx16_k_i2c_read_byte: {
    // unsigned int result
    // [913] cx16_k_i2c_read_byte::result = 0 -- vwum1=vwuc1 
    lda #<0
    sta result
    sta result+1
    // asm
    // asm { ldxdevice ldyoffset lda#0 staresult staresult+1 jsrCX16_I2C_READ_BYTE staresult rolresult+1  }
    ldx device
    ldy offset
    sta result
    sta result+1
    jsr CX16_I2C_READ_BYTE
    sta result
    rol result+1
    // return result;
    // [915] cx16_k_i2c_read_byte::return#0 = cx16_k_i2c_read_byte::result -- vwum1=vwum2 
    sta return
    lda result+1
    sta return+1
    // cx16_k_i2c_read_byte::@return
    // }
    // [916] cx16_k_i2c_read_byte::return#1 = cx16_k_i2c_read_byte::return#0
    // [917] return 
    rts
  .segment Data
    device: .byte 0
    offset: .byte 0
    result: .word 0
    .label return = flash_smc_detect.return
}
.segment Code
  // print_chip_led
// void print_chip_led(__mem() char x, char y, __mem() char w, __mem() char tc, char bc)
print_chip_led: {
    // gotoxy(x, y)
    // [919] gotoxy::x#8 = print_chip_led::x#3 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [920] call gotoxy
    // [201] phi from print_chip_led to gotoxy [phi:print_chip_led->gotoxy]
    // [201] phi gotoxy::y#17 = 3 [phi:print_chip_led->gotoxy#0] -- vbum1=vbuc1 
    lda #3
    sta gotoxy.y
    // [201] phi gotoxy::x#17 = gotoxy::x#8 [phi:print_chip_led->gotoxy#1] -- register_copy 
    jsr gotoxy
    // print_chip_led::@4
    // textcolor(tc)
    // [921] textcolor::color#10 = print_chip_led::tc#3 -- vbum1=vbum2 
    lda tc
    sta textcolor.color
    // [922] call textcolor
    // [183] phi from print_chip_led::@4 to textcolor [phi:print_chip_led::@4->textcolor]
    // [183] phi textcolor::color#17 = textcolor::color#10 [phi:print_chip_led::@4->textcolor#0] -- register_copy 
    jsr textcolor
    // [923] phi from print_chip_led::@4 to print_chip_led::@5 [phi:print_chip_led::@4->print_chip_led::@5]
    // print_chip_led::@5
    // bgcolor(bc)
    // [924] call bgcolor
    // [188] phi from print_chip_led::@5 to bgcolor [phi:print_chip_led::@5->bgcolor]
    // [188] phi bgcolor::color#14 = BLUE [phi:print_chip_led::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [925] phi from print_chip_led::@5 to print_chip_led::@1 [phi:print_chip_led::@5->print_chip_led::@1]
    // [925] phi print_chip_led::i#2 = 0 [phi:print_chip_led::@5->print_chip_led::@1#0] -- vbum1=vbuc1 
    lda #0
    sta i
    // print_chip_led::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [926] if(print_chip_led::i#2<print_chip_led::w#5) goto print_chip_led::@2 -- vbum1_lt_vbum2_then_la1 
    lda i
    cmp w
    bcc __b2
    // [927] phi from print_chip_led::@1 to print_chip_led::@3 [phi:print_chip_led::@1->print_chip_led::@3]
    // print_chip_led::@3
    // textcolor(WHITE)
    // [928] call textcolor
    // [183] phi from print_chip_led::@3 to textcolor [phi:print_chip_led::@3->textcolor]
    // [183] phi textcolor::color#17 = WHITE [phi:print_chip_led::@3->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [929] phi from print_chip_led::@3 to print_chip_led::@6 [phi:print_chip_led::@3->print_chip_led::@6]
    // print_chip_led::@6
    // bgcolor(BLUE)
    // [930] call bgcolor
    // [188] phi from print_chip_led::@6 to bgcolor [phi:print_chip_led::@6->bgcolor]
    // [188] phi bgcolor::color#14 = BLUE [phi:print_chip_led::@6->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // print_chip_led::@return
    // }
    // [931] return 
    rts
    // print_chip_led::@2
  __b2:
    // cputc(0xE2)
    // [932] stackpush(char) = $e2 -- _stackpushbyte_=vbuc1 
    lda #$e2
    pha
    // [933] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [935] print_chip_led::i#1 = ++ print_chip_led::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [925] phi from print_chip_led::@2 to print_chip_led::@1 [phi:print_chip_led::@2->print_chip_led::@1]
    // [925] phi print_chip_led::i#2 = print_chip_led::i#1 [phi:print_chip_led::@2->print_chip_led::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    i: .byte 0
    .label tc = print_smc_led.c
    x: .byte 0
    w: .byte 0
}
.segment Code
  // print_chip
// void print_chip(__mem() char x, char y, __mem() char w, __zp($36) char *text)
print_chip: {
    .label y = 3+1+1+1+1+1+1+1+1+1
    .label text = $36
    .label text_1 = $31
    .label text_2 = $29
    .label text_3 = $27
    .label text_4 = $2d
    .label text_5 = $38
    .label text_6 = $34
    // print_chip_line(x, y++, w, *text++)
    // [937] print_chip_line::x#0 = print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta print_chip_line.x
    // [938] print_chip_line::w#0 = print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta print_chip_line.w
    // [939] print_chip_line::c#0 = *print_chip::text#11 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_2),y
    sta print_chip_line.c
    // [940] call print_chip_line
    // [1245] phi from print_chip to print_chip_line [phi:print_chip->print_chip_line]
    // [1245] phi print_chip_line::c#15 = print_chip_line::c#0 [phi:print_chip->print_chip_line#0] -- register_copy 
    // [1245] phi print_chip_line::w#10 = print_chip_line::w#0 [phi:print_chip->print_chip_line#1] -- register_copy 
    // [1245] phi print_chip_line::y#16 = 3+1 [phi:print_chip->print_chip_line#2] -- vbum1=vbuc1 
    lda #3+1
    sta print_chip_line.y
    // [1245] phi print_chip_line::x#16 = print_chip_line::x#0 [phi:print_chip->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@1
    // print_chip_line(x, y++, w, *text++);
    // [941] print_chip::text#0 = ++ print_chip::text#11 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_2
    adc #1
    sta.z text
    lda.z text_2+1
    adc #0
    sta.z text+1
    // print_chip_line(x, y++, w, *text++)
    // [942] print_chip_line::x#1 = print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta print_chip_line.x
    // [943] print_chip_line::w#1 = print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta print_chip_line.w
    // [944] print_chip_line::c#1 = *print_chip::text#0 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text),y
    sta print_chip_line.c
    // [945] call print_chip_line
    // [1245] phi from print_chip::@1 to print_chip_line [phi:print_chip::@1->print_chip_line]
    // [1245] phi print_chip_line::c#15 = print_chip_line::c#1 [phi:print_chip::@1->print_chip_line#0] -- register_copy 
    // [1245] phi print_chip_line::w#10 = print_chip_line::w#1 [phi:print_chip::@1->print_chip_line#1] -- register_copy 
    // [1245] phi print_chip_line::y#16 = ++3+1 [phi:print_chip::@1->print_chip_line#2] -- vbum1=vbuc1 
    lda #3+1+1
    sta print_chip_line.y
    // [1245] phi print_chip_line::x#16 = print_chip_line::x#1 [phi:print_chip::@1->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@2
    // print_chip_line(x, y++, w, *text++);
    // [946] print_chip::text#1 = ++ print_chip::text#0 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text
    adc #1
    sta.z text_1
    lda.z text+1
    adc #0
    sta.z text_1+1
    // print_chip_line(x, y++, w, *text++)
    // [947] print_chip_line::x#2 = print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta print_chip_line.x
    // [948] print_chip_line::w#2 = print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta print_chip_line.w
    // [949] print_chip_line::c#2 = *print_chip::text#1 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_1),y
    sta print_chip_line.c
    // [950] call print_chip_line
    // [1245] phi from print_chip::@2 to print_chip_line [phi:print_chip::@2->print_chip_line]
    // [1245] phi print_chip_line::c#15 = print_chip_line::c#2 [phi:print_chip::@2->print_chip_line#0] -- register_copy 
    // [1245] phi print_chip_line::w#10 = print_chip_line::w#2 [phi:print_chip::@2->print_chip_line#1] -- register_copy 
    // [1245] phi print_chip_line::y#16 = ++++3+1 [phi:print_chip::@2->print_chip_line#2] -- vbum1=vbuc1 
    lda #3+1+1+1
    sta print_chip_line.y
    // [1245] phi print_chip_line::x#16 = print_chip_line::x#2 [phi:print_chip::@2->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@3
    // print_chip_line(x, y++, w, *text++);
    // [951] print_chip::text#15 = ++ print_chip::text#1 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_1
    adc #1
    sta.z text_3
    lda.z text_1+1
    adc #0
    sta.z text_3+1
    // print_chip_line(x, y++, w, *text++)
    // [952] print_chip_line::x#3 = print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta print_chip_line.x
    // [953] print_chip_line::w#3 = print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta print_chip_line.w
    // [954] print_chip_line::c#3 = *print_chip::text#15 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_3),y
    sta print_chip_line.c
    // [955] call print_chip_line
    // [1245] phi from print_chip::@3 to print_chip_line [phi:print_chip::@3->print_chip_line]
    // [1245] phi print_chip_line::c#15 = print_chip_line::c#3 [phi:print_chip::@3->print_chip_line#0] -- register_copy 
    // [1245] phi print_chip_line::w#10 = print_chip_line::w#3 [phi:print_chip::@3->print_chip_line#1] -- register_copy 
    // [1245] phi print_chip_line::y#16 = ++++++3+1 [phi:print_chip::@3->print_chip_line#2] -- vbum1=vbuc1 
    lda #3+1+1+1+1
    sta print_chip_line.y
    // [1245] phi print_chip_line::x#16 = print_chip_line::x#3 [phi:print_chip::@3->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@4
    // print_chip_line(x, y++, w, *text++);
    // [956] print_chip::text#16 = ++ print_chip::text#15 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_3
    adc #1
    sta.z text_4
    lda.z text_3+1
    adc #0
    sta.z text_4+1
    // print_chip_line(x, y++, w, *text++)
    // [957] print_chip_line::x#4 = print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta print_chip_line.x
    // [958] print_chip_line::w#4 = print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta print_chip_line.w
    // [959] print_chip_line::c#4 = *print_chip::text#16 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_4),y
    sta print_chip_line.c
    // [960] call print_chip_line
    // [1245] phi from print_chip::@4 to print_chip_line [phi:print_chip::@4->print_chip_line]
    // [1245] phi print_chip_line::c#15 = print_chip_line::c#4 [phi:print_chip::@4->print_chip_line#0] -- register_copy 
    // [1245] phi print_chip_line::w#10 = print_chip_line::w#4 [phi:print_chip::@4->print_chip_line#1] -- register_copy 
    // [1245] phi print_chip_line::y#16 = ++++++++3+1 [phi:print_chip::@4->print_chip_line#2] -- vbum1=vbuc1 
    lda #3+1+1+1+1+1
    sta print_chip_line.y
    // [1245] phi print_chip_line::x#16 = print_chip_line::x#4 [phi:print_chip::@4->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@5
    // print_chip_line(x, y++, w, *text++);
    // [961] print_chip::text#17 = ++ print_chip::text#16 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_4
    adc #1
    sta.z text_5
    lda.z text_4+1
    adc #0
    sta.z text_5+1
    // print_chip_line(x, y++, w, *text++)
    // [962] print_chip_line::x#5 = print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta print_chip_line.x
    // [963] print_chip_line::w#5 = print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta print_chip_line.w
    // [964] print_chip_line::c#5 = *print_chip::text#17 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_5),y
    sta print_chip_line.c
    // [965] call print_chip_line
    // [1245] phi from print_chip::@5 to print_chip_line [phi:print_chip::@5->print_chip_line]
    // [1245] phi print_chip_line::c#15 = print_chip_line::c#5 [phi:print_chip::@5->print_chip_line#0] -- register_copy 
    // [1245] phi print_chip_line::w#10 = print_chip_line::w#5 [phi:print_chip::@5->print_chip_line#1] -- register_copy 
    // [1245] phi print_chip_line::y#16 = ++++++++++3+1 [phi:print_chip::@5->print_chip_line#2] -- vbum1=vbuc1 
    lda #3+1+1+1+1+1+1
    sta print_chip_line.y
    // [1245] phi print_chip_line::x#16 = print_chip_line::x#5 [phi:print_chip::@5->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@6
    // print_chip_line(x, y++, w, *text++);
    // [966] print_chip::text#18 = ++ print_chip::text#17 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_5
    adc #1
    sta.z text_6
    lda.z text_5+1
    adc #0
    sta.z text_6+1
    // print_chip_line(x, y++, w, *text++)
    // [967] print_chip_line::x#6 = print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta print_chip_line.x
    // [968] print_chip_line::w#6 = print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta print_chip_line.w
    // [969] print_chip_line::c#6 = *print_chip::text#18 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta print_chip_line.c
    // [970] call print_chip_line
    // [1245] phi from print_chip::@6 to print_chip_line [phi:print_chip::@6->print_chip_line]
    // [1245] phi print_chip_line::c#15 = print_chip_line::c#6 [phi:print_chip::@6->print_chip_line#0] -- register_copy 
    // [1245] phi print_chip_line::w#10 = print_chip_line::w#6 [phi:print_chip::@6->print_chip_line#1] -- register_copy 
    // [1245] phi print_chip_line::y#16 = ++++++++++++3+1 [phi:print_chip::@6->print_chip_line#2] -- vbum1=vbuc1 
    lda #3+1+1+1+1+1+1+1
    sta print_chip_line.y
    // [1245] phi print_chip_line::x#16 = print_chip_line::x#6 [phi:print_chip::@6->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@7
    // print_chip_line(x, y++, w, *text++);
    // [971] print_chip::text#19 = ++ print_chip::text#18 -- pbuz1=_inc_pbuz1 
    inc.z text_6
    bne !+
    inc.z text_6+1
  !:
    // print_chip_line(x, y++, w, *text++)
    // [972] print_chip_line::x#7 = print_chip::x#10 -- vbum1=vbum2 
    lda x
    sta print_chip_line.x
    // [973] print_chip_line::w#7 = print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta print_chip_line.w
    // [974] print_chip_line::c#7 = *print_chip::text#19 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta print_chip_line.c
    // [975] call print_chip_line
    // [1245] phi from print_chip::@7 to print_chip_line [phi:print_chip::@7->print_chip_line]
    // [1245] phi print_chip_line::c#15 = print_chip_line::c#7 [phi:print_chip::@7->print_chip_line#0] -- register_copy 
    // [1245] phi print_chip_line::w#10 = print_chip_line::w#7 [phi:print_chip::@7->print_chip_line#1] -- register_copy 
    // [1245] phi print_chip_line::y#16 = ++++++++++++++3+1 [phi:print_chip::@7->print_chip_line#2] -- vbum1=vbuc1 
    lda #3+1+1+1+1+1+1+1+1
    sta print_chip_line.y
    // [1245] phi print_chip_line::x#16 = print_chip_line::x#7 [phi:print_chip::@7->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@8
    // print_chip_end(x, y++, w)
    // [976] print_chip_end::x#0 = print_chip::x#10
    // [977] print_chip_end::w#0 = print_chip::w#10 -- vbum1=vbum2 
    lda w
    sta print_chip_end.w
    // [978] call print_chip_end
    jsr print_chip_end
    // print_chip::@return
    // }
    // [979] return 
    rts
  .segment Data
    x: .byte 0
    w: .byte 0
}
.segment Code
  // print_vera_led
// void print_vera_led(char c)
print_vera_led: {
    // print_chip_led(CHIP_VERA_X+1, CHIP_VERA_Y, CHIP_VERA_W, c, BLUE)
    // [981] call print_chip_led
    // [918] phi from print_vera_led to print_chip_led [phi:print_vera_led->print_chip_led]
    // [918] phi print_chip_led::w#5 = 8 [phi:print_vera_led->print_chip_led#0] -- vbum1=vbuc1 
    lda #8
    sta print_chip_led.w
    // [918] phi print_chip_led::tc#3 = GREY [phi:print_vera_led->print_chip_led#1] -- vbum1=vbuc1 
    lda #GREY
    sta print_chip_led.tc
    // [918] phi print_chip_led::x#3 = 9+1 [phi:print_vera_led->print_chip_led#2] -- vbum1=vbuc1 
    lda #9+1
    sta print_chip_led.x
    jsr print_chip_led
    // print_vera_led::@return
    // }
    // [982] return 
    rts
}
  // strcat
// Concatenates the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcat(char *destination, __zp($29) char *source)
strcat: {
    .label dst = $2d
    .label src = $29
    .label source = $29
    // strlen(destination)
    // [984] call strlen
    // [899] phi from strcat to strlen [phi:strcat->strlen]
    // [899] phi strlen::str#8 = print_rom_chips::rom [phi:strcat->strlen#0] -- pbuz1=pbuc1 
    lda #<print_rom_chips.rom
    sta.z strlen.str
    lda #>print_rom_chips.rom
    sta.z strlen.str+1
    jsr strlen
    // strlen(destination)
    // [985] strlen::return#0 = strlen::len#2
    // strcat::@4
    // [986] strcat::$0 = strlen::return#0
    // char* dst = destination + strlen(destination)
    // [987] strcat::dst#0 = print_rom_chips::rom + strcat::$0 -- pbuz1=pbuc1_plus_vwum2 
    lda strcat__0
    clc
    adc #<print_rom_chips.rom
    sta.z dst
    lda strcat__0+1
    adc #>print_rom_chips.rom
    sta.z dst+1
    // [988] phi from strcat::@2 strcat::@4 to strcat::@1 [phi:strcat::@2/strcat::@4->strcat::@1]
    // [988] phi strcat::dst#2 = strcat::dst#1 [phi:strcat::@2/strcat::@4->strcat::@1#0] -- register_copy 
    // [988] phi strcat::src#2 = strcat::src#1 [phi:strcat::@2/strcat::@4->strcat::@1#1] -- register_copy 
    // strcat::@1
  __b1:
    // while(*src)
    // [989] if(0!=*strcat::src#2) goto strcat::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcat::@3
    // *dst = 0
    // [990] *strcat::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcat::@return
    // }
    // [991] return 
    rts
    // strcat::@2
  __b2:
    // *dst++ = *src++
    // [992] *strcat::dst#2 = *strcat::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [993] strcat::dst#1 = ++ strcat::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [994] strcat::src#1 = ++ strcat::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    jmp __b1
  .segment Data
    .label strcat__0 = strlen.len
}
.segment Code
  // print_rom_led
// void print_rom_led(__mem() char chip, __mem() char c)
print_rom_led: {
    // chip*6
    // [996] print_rom_led::$4 = print_rom_led::chip#3 << 1 -- vbum1=vbum2_rol_1 
    lda chip
    asl
    sta print_rom_led__4
    // [997] print_rom_led::$5 = print_rom_led::$4 + print_rom_led::chip#3 -- vbum1=vbum2_plus_vbum1 
    lda print_rom_led__5
    clc
    adc print_rom_led__4
    sta print_rom_led__5
    // CHIP_ROM_X+chip*6
    // [998] print_rom_led::$0 = print_rom_led::$5 << 1 -- vbum1=vbum1_rol_1 
    asl print_rom_led__0
    // print_chip_led(CHIP_ROM_X+chip*6+1, CHIP_ROM_Y, CHIP_ROM_W, c, BLUE)
    // [999] print_chip_led::x#2 = print_rom_led::$0 + $14+1 -- vbum1=vbum1_plus_vbuc1 
    lda #$14+1
    clc
    adc print_chip_led.x
    sta print_chip_led.x
    // [1000] print_chip_led::tc#2 = print_rom_led::c#3
    // [1001] call print_chip_led
    // [918] phi from print_rom_led to print_chip_led [phi:print_rom_led->print_chip_led]
    // [918] phi print_chip_led::w#5 = 3 [phi:print_rom_led->print_chip_led#0] -- vbum1=vbuc1 
    lda #3
    sta print_chip_led.w
    // [918] phi print_chip_led::tc#3 = print_chip_led::tc#2 [phi:print_rom_led->print_chip_led#1] -- register_copy 
    // [918] phi print_chip_led::x#3 = print_chip_led::x#2 [phi:print_rom_led->print_chip_led#2] -- register_copy 
    jsr print_chip_led
    // print_rom_led::@return
    // }
    // [1002] return 
    rts
  .segment Data
    .label print_rom_led__0 = print_chip_led.x
    .label chip = print_chip_led.x
    .label c = print_smc_led.c
    print_rom_led__4: .byte 0
    .label print_rom_led__5 = print_chip_led.x
}
.segment Code
  // utoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void utoa(__mem() unsigned int value, __zp($25) char *buffer, char radix)
utoa: {
    .label buffer = $25
    // [1004] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
    // [1004] phi utoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa->utoa::@1#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1004] phi utoa::started#2 = 0 [phi:utoa->utoa::@1#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [1004] phi utoa::value#2 = utoa::value#1 [phi:utoa->utoa::@1#2] -- register_copy 
    // [1004] phi utoa::digit#2 = 0 [phi:utoa->utoa::@1#3] -- vbum1=vbuc1 
    sta digit
    // utoa::@1
  __b1:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1005] if(utoa::digit#2<5-1) goto utoa::@2 -- vbum1_lt_vbuc1_then_la1 
    lda digit
    cmp #5-1
    bcc __b2
    // utoa::@3
    // *buffer++ = DIGITS[(char)value]
    // [1006] utoa::$11 = (char)utoa::value#2 -- vbum1=_byte_vwum2 
    lda value
    sta utoa__11
    // [1007] *utoa::buffer#11 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1008] utoa::buffer#3 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1009] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    // utoa::@return
    // }
    // [1010] return 
    rts
    // utoa::@2
  __b2:
    // unsigned int digit_value = digit_values[digit]
    // [1011] utoa::$10 = utoa::digit#2 << 1 -- vbum1=vbum2_rol_1 
    lda digit
    asl
    sta utoa__10
    // [1012] utoa::digit_value#0 = RADIX_DECIMAL_VALUES[utoa::$10] -- vwum1=pwuc1_derefidx_vbum2 
    tay
    lda RADIX_DECIMAL_VALUES,y
    sta digit_value
    lda RADIX_DECIMAL_VALUES+1,y
    sta digit_value+1
    // if (started || value >= digit_value)
    // [1013] if(0!=utoa::started#2) goto utoa::@5 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b5
    // utoa::@7
    // [1014] if(utoa::value#2>=utoa::digit_value#0) goto utoa::@5 -- vwum1_ge_vwum2_then_la1 
    lda digit_value+1
    cmp value+1
    bne !+
    lda digit_value
    cmp value
    beq __b5
  !:
    bcc __b5
    // [1015] phi from utoa::@7 to utoa::@4 [phi:utoa::@7->utoa::@4]
    // [1015] phi utoa::buffer#14 = utoa::buffer#11 [phi:utoa::@7->utoa::@4#0] -- register_copy 
    // [1015] phi utoa::started#4 = utoa::started#2 [phi:utoa::@7->utoa::@4#1] -- register_copy 
    // [1015] phi utoa::value#6 = utoa::value#2 [phi:utoa::@7->utoa::@4#2] -- register_copy 
    // utoa::@4
  __b4:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1016] utoa::digit#1 = ++ utoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [1004] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
    // [1004] phi utoa::buffer#11 = utoa::buffer#14 [phi:utoa::@4->utoa::@1#0] -- register_copy 
    // [1004] phi utoa::started#2 = utoa::started#4 [phi:utoa::@4->utoa::@1#1] -- register_copy 
    // [1004] phi utoa::value#2 = utoa::value#6 [phi:utoa::@4->utoa::@1#2] -- register_copy 
    // [1004] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@4->utoa::@1#3] -- register_copy 
    jmp __b1
    // utoa::@5
  __b5:
    // utoa_append(buffer++, value, digit_value)
    // [1017] utoa_append::buffer#0 = utoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [1018] utoa_append::value#0 = utoa::value#2
    // [1019] utoa_append::sub#0 = utoa::digit_value#0
    // [1020] call utoa_append
    // [1306] phi from utoa::@5 to utoa_append [phi:utoa::@5->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [1021] utoa_append::return#0 = utoa_append::value#2
    // utoa::@6
    // value = utoa_append(buffer++, value, digit_value)
    // [1022] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [1023] utoa::buffer#4 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1015] phi from utoa::@6 to utoa::@4 [phi:utoa::@6->utoa::@4]
    // [1015] phi utoa::buffer#14 = utoa::buffer#4 [phi:utoa::@6->utoa::@4#0] -- register_copy 
    // [1015] phi utoa::started#4 = 1 [phi:utoa::@6->utoa::@4#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [1015] phi utoa::value#6 = utoa::value#0 [phi:utoa::@6->utoa::@4#2] -- register_copy 
    jmp __b4
  .segment Data
    utoa__10: .byte 0
    utoa__11: .byte 0
    digit_value: .word 0
    digit: .byte 0
    .label value = printf_uint.uvalue
    started: .byte 0
}
.segment Code
  // printf_number_buffer
// Print the contents of the number buffer using a specific format.
// This handles minimum length, zero-filling, and left/right justification from the format
// void printf_number_buffer(__zp($2b) void (*putc)(char), __mem() char buffer_sign, char *buffer_digits, char format_min_length, char format_justify_left, char format_sign_always, char format_zero_padding, char format_upper_case, char format_radix)
printf_number_buffer: {
    .label putc = $2b
    // printf_number_buffer::@1
    // if(buffer.sign)
    // [1025] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@2 -- 0_eq_vbum1_then_la1 
    lda buffer_sign
    beq __b2
    // printf_number_buffer::@3
    // putc(buffer.sign)
    // [1026] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbum1 
    pha
    // [1027] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall8
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@2
  __b2:
    // printf_str(putc, buffer.digits)
    // [1029] printf_str::putc#0 = printf_number_buffer::putc#10
    // [1030] call printf_str
    // [290] phi from printf_number_buffer::@2 to printf_str [phi:printf_number_buffer::@2->printf_str]
    // [290] phi printf_str::putc#24 = printf_str::putc#0 [phi:printf_number_buffer::@2->printf_str#0] -- register_copy 
    // [290] phi printf_str::s#24 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@return
    // }
    // [1031] return 
    rts
    // Outside Flow
  icall8:
    jmp (putc)
  .segment Data
    buffer_sign: .byte 0
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
    // [1032] cbm_k_getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsrCBM_GETIN stach  }
    jsr CBM_GETIN
    sta ch
    // return ch;
    // [1034] cbm_k_getin::return#0 = cbm_k_getin::ch -- vbum1=vbum2 
    sta return
    // cbm_k_getin::@return
    // }
    // [1035] cbm_k_getin::return#1 = cbm_k_getin::return#0
    // [1036] return 
    rts
  .segment Data
    ch: .byte 0
    return: .byte 0
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
    // [1038] return 
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
// __mem() int ferror(__zp($2d) struct $2 *stream)
ferror: {
    .label cbm_k_setnam1_filename = $3f
    .label stream = $2d
    .label errno_len = $3a
    // unsigned char sp = (unsigned char)stream
    // [1039] ferror::sp#0 = (char)ferror::stream#0 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_setlfs(15, 8, 15)
    // [1040] cbm_k_setlfs::channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.channel
    // [1041] cbm_k_setlfs::device = 8 -- vbum1=vbuc1 
    lda #8
    sta cbm_k_setlfs.device
    // [1042] cbm_k_setlfs::command = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.command
    // [1043] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // ferror::@11
    // cbm_k_setnam("")
    // [1044] ferror::cbm_k_setnam1_filename = ferror::$18 -- pbuz1=pbuc1 
    lda #<ferror__18
    sta.z cbm_k_setnam1_filename
    lda #>ferror__18
    sta.z cbm_k_setnam1_filename+1
    // ferror::cbm_k_setnam1
    // strlen(filename)
    // [1045] strlen::str#5 = ferror::cbm_k_setnam1_filename -- pbuz1=pbuz2 
    lda.z cbm_k_setnam1_filename
    sta.z strlen.str
    lda.z cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [1046] call strlen
    // [899] phi from ferror::cbm_k_setnam1 to strlen [phi:ferror::cbm_k_setnam1->strlen]
    // [899] phi strlen::str#8 = strlen::str#5 [phi:ferror::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [1047] strlen::return#12 = strlen::len#2
    // ferror::@12
    // [1048] ferror::cbm_k_setnam1_$0 = strlen::return#12
    // char filename_len = (char)strlen(filename)
    // [1049] ferror::cbm_k_setnam1_filename_len = (char)ferror::cbm_k_setnam1_$0 -- vbum1=_byte_vwum2 
    lda cbm_k_setnam1_ferror__0
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
    // [1052] ferror::cbm_k_chkin1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_chkin1_channel
    // ferror::cbm_k_chkin1
    // char status
    // [1053] ferror::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // ferror::cbm_k_chrin1
    // char ch
    // [1055] ferror::cbm_k_chrin1_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin1_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin1_ch
    // return ch;
    // [1057] ferror::cbm_k_chrin1_return#0 = ferror::cbm_k_chrin1_ch -- vbum1=vbum2 
    sta cbm_k_chrin1_return
    // ferror::cbm_k_chrin1_@return
    // }
    // [1058] ferror::cbm_k_chrin1_return#1 = ferror::cbm_k_chrin1_return#0
    // ferror::@7
    // char ch = cbm_k_chrin()
    // [1059] ferror::ch#0 = ferror::cbm_k_chrin1_return#1
    // [1060] phi from ferror::@7 to ferror::cbm_k_readst1 [phi:ferror::@7->ferror::cbm_k_readst1]
    // [1060] phi __errno#11 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#0] -- vwsm1=vwsc1 
    lda #<0
    sta __errno
    sta __errno+1
    // [1060] phi ferror::errno_len#10 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#1] -- vbuz1=vbuc1 
    sta.z errno_len
    // [1060] phi ferror::ch#10 = ferror::ch#0 [phi:ferror::@7->ferror::cbm_k_readst1#2] -- register_copy 
    // [1060] phi ferror::errno_parsed#2 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#3] -- vbum1=vbuc1 
    sta errno_parsed
    // ferror::cbm_k_readst1
  cbm_k_readst1:
    // char status
    // [1061] ferror::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [1063] ferror::cbm_k_readst1_return#0 = ferror::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // ferror::cbm_k_readst1_@return
    // }
    // [1064] ferror::cbm_k_readst1_return#1 = ferror::cbm_k_readst1_return#0
    // ferror::@8
    // cbm_k_readst()
    // [1065] ferror::$6 = ferror::cbm_k_readst1_return#1
    // st = cbm_k_readst()
    // [1066] ferror::st#1 = ferror::$6
    // while (!(st = cbm_k_readst()))
    // [1067] if(0==ferror::st#1) goto ferror::@1 -- 0_eq_vbum1_then_la1 
    lda st
    beq __b1
    // ferror::@2
    // __status = st
    // [1068] ((char *)&__stdio_file+$46)[ferror::sp#0] = ferror::st#1 -- pbuc1_derefidx_vbum1=vbum2 
    ldy sp
    sta __stdio_file+$46,y
    // cbm_k_close(15)
    // [1069] ferror::cbm_k_close1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_close1_channel
    // ferror::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // ferror::@9
    // return __errno;
    // [1071] ferror::return#1 = __errno#11 -- vwsm1=vwsm2 
    lda __errno
    sta return
    lda __errno+1
    sta return+1
    // ferror::@return
    // }
    // [1072] return 
    rts
    // ferror::@1
  __b1:
    // if (!errno_parsed)
    // [1073] if(0!=ferror::errno_parsed#2) goto ferror::@3 -- 0_neq_vbum1_then_la1 
    lda errno_parsed
    bne __b3
    // ferror::@4
    // if (ch == ',')
    // [1074] if(ferror::ch#10!=',') goto ferror::@3 -- vbum1_neq_vbuc1_then_la1 
    lda #','
    cmp ch
    bne __b3
    // ferror::@5
    // errno_parsed++;
    // [1075] ferror::errno_parsed#1 = ++ ferror::errno_parsed#2 -- vbum1=_inc_vbum1 
    inc errno_parsed
    // strncpy(temp, __errno_error, errno_len+1)
    // [1076] strncpy::n#0 = ferror::errno_len#10 + 1 -- vwum1=vbuz2_plus_1 
    lda.z errno_len
    clc
    adc #1
    sta strncpy.n
    lda #0
    adc #0
    sta strncpy.n+1
    // [1077] call strncpy
    // [1313] phi from ferror::@5 to strncpy [phi:ferror::@5->strncpy]
    jsr strncpy
    // [1078] phi from ferror::@5 to ferror::@13 [phi:ferror::@5->ferror::@13]
    // ferror::@13
    // atoi(temp)
    // [1079] call atoi
    // [1091] phi from ferror::@13 to atoi [phi:ferror::@13->atoi]
    // [1091] phi atoi::str#2 = ferror::temp [phi:ferror::@13->atoi#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z atoi.str
    lda #>temp
    sta.z atoi.str+1
    jsr atoi
    // atoi(temp)
    // [1080] atoi::return#4 = atoi::return#2
    // ferror::@14
    // __errno = atoi(temp)
    // [1081] __errno#2 = atoi::return#4 -- vwsm1=vwsm2 
    lda atoi.return
    sta __errno
    lda atoi.return+1
    sta __errno+1
    // [1082] phi from ferror::@1 ferror::@14 ferror::@4 to ferror::@3 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3]
    // [1082] phi __errno#50 = __errno#11 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#0] -- register_copy 
    // [1082] phi ferror::errno_parsed#11 = ferror::errno_parsed#2 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#1] -- register_copy 
    // ferror::@3
  __b3:
    // __errno_error[errno_len] = ch
    // [1083] __errno_error[ferror::errno_len#10] = ferror::ch#10 -- pbuc1_derefidx_vbuz1=vbum2 
    lda ch
    ldy.z errno_len
    sta __errno_error,y
    // errno_len++;
    // [1084] ferror::errno_len#1 = ++ ferror::errno_len#10 -- vbuz1=_inc_vbuz1 
    inc.z errno_len
    // ferror::cbm_k_chrin2
    // char ch
    // [1085] ferror::cbm_k_chrin2_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin2_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin2_ch
    // return ch;
    // [1087] ferror::cbm_k_chrin2_return#0 = ferror::cbm_k_chrin2_ch -- vbum1=vbum2 
    sta cbm_k_chrin2_return
    // ferror::cbm_k_chrin2_@return
    // }
    // [1088] ferror::cbm_k_chrin2_return#1 = ferror::cbm_k_chrin2_return#0
    // ferror::@10
    // cbm_k_chrin()
    // [1089] ferror::$15 = ferror::cbm_k_chrin2_return#1
    // ch = cbm_k_chrin()
    // [1090] ferror::ch#1 = ferror::$15
    // [1060] phi from ferror::@10 to ferror::cbm_k_readst1 [phi:ferror::@10->ferror::cbm_k_readst1]
    // [1060] phi __errno#11 = __errno#50 [phi:ferror::@10->ferror::cbm_k_readst1#0] -- register_copy 
    // [1060] phi ferror::errno_len#10 = ferror::errno_len#1 [phi:ferror::@10->ferror::cbm_k_readst1#1] -- register_copy 
    // [1060] phi ferror::ch#10 = ferror::ch#1 [phi:ferror::@10->ferror::cbm_k_readst1#2] -- register_copy 
    // [1060] phi ferror::errno_parsed#2 = ferror::errno_parsed#11 [phi:ferror::@10->ferror::cbm_k_readst1#3] -- register_copy 
    jmp cbm_k_readst1
  .segment Data
    temp: .fill 4, 0
    ferror__18: .text ""
    .byte 0
    .label ferror__6 = cbm_k_readst1_return
    .label ferror__15 = ch
    cbm_k_setnam1_filename_len: .byte 0
    .label cbm_k_setnam1_ferror__0 = strlen.len
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
    .label st = cbm_k_readst1_return
    .label cbm_k_chrin2_return = ch
    errno_parsed: .byte 0
}
.segment Code
  // atoi
// Converts the string argument str to an integer.
// __mem() int atoi(__zp($29) const char *str)
atoi: {
    .label str = $29
    // if (str[i] == '-')
    // [1092] if(*atoi::str#2!='-') goto atoi::@3 -- _deref_pbuz1_neq_vbuc1_then_la1 
    ldy #0
    lda (str),y
    cmp #'-'
    bne __b2
    // [1093] phi from atoi to atoi::@2 [phi:atoi->atoi::@2]
    // atoi::@2
    // [1094] phi from atoi::@2 to atoi::@3 [phi:atoi::@2->atoi::@3]
    // [1094] phi atoi::negative#2 = 1 [phi:atoi::@2->atoi::@3#0] -- vbum1=vbuc1 
    lda #1
    sta negative
    // [1094] phi atoi::res#2 = 0 [phi:atoi::@2->atoi::@3#1] -- vwsm1=vwsc1 
    tya
    sta res
    sta res+1
    // [1094] phi atoi::i#4 = 1 [phi:atoi::@2->atoi::@3#2] -- vbum1=vbuc1 
    lda #1
    sta i
    jmp __b3
  // Iterate through all digits and update the result
    // [1094] phi from atoi to atoi::@3 [phi:atoi->atoi::@3]
  __b2:
    // [1094] phi atoi::negative#2 = 0 [phi:atoi->atoi::@3#0] -- vbum1=vbuc1 
    lda #0
    sta negative
    // [1094] phi atoi::res#2 = 0 [phi:atoi->atoi::@3#1] -- vwsm1=vwsc1 
    sta res
    sta res+1
    // [1094] phi atoi::i#4 = 0 [phi:atoi->atoi::@3#2] -- vbum1=vbuc1 
    sta i
    // atoi::@3
  __b3:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [1095] if(atoi::str#2[atoi::i#4]<'0') goto atoi::@5 -- pbuz1_derefidx_vbum2_lt_vbuc1_then_la1 
    ldy i
    lda (str),y
    cmp #'0'
    bcc __b5
    // atoi::@6
    // [1096] if(atoi::str#2[atoi::i#4]<='9') goto atoi::@4 -- pbuz1_derefidx_vbum2_le_vbuc1_then_la1 
    lda (str),y
    cmp #'9'
    bcc __b4
    beq __b4
    // atoi::@5
  __b5:
    // if(negative)
    // [1097] if(0!=atoi::negative#2) goto atoi::@1 -- 0_neq_vbum1_then_la1 
    // Return result with sign
    lda negative
    bne __b1
    // [1099] phi from atoi::@1 atoi::@5 to atoi::@return [phi:atoi::@1/atoi::@5->atoi::@return]
    // [1099] phi atoi::return#2 = atoi::return#0 [phi:atoi::@1/atoi::@5->atoi::@return#0] -- register_copy 
    rts
    // atoi::@1
  __b1:
    // return -res;
    // [1098] atoi::return#0 = - atoi::res#2 -- vwsm1=_neg_vwsm1 
    lda #0
    sec
    sbc return
    sta return
    lda #0
    sbc return+1
    sta return+1
    // atoi::@return
    // }
    // [1100] return 
    rts
    // atoi::@4
  __b4:
    // res * 10
    // [1101] atoi::$10 = atoi::res#2 << 2 -- vwsm1=vwsm2_rol_2 
    lda res
    asl
    sta atoi__10
    lda res+1
    rol
    sta atoi__10+1
    asl atoi__10
    rol atoi__10+1
    // [1102] atoi::$11 = atoi::$10 + atoi::res#2 -- vwsm1=vwsm2_plus_vwsm1 
    clc
    lda atoi__11
    adc atoi__10
    sta atoi__11
    lda atoi__11+1
    adc atoi__10+1
    sta atoi__11+1
    // [1103] atoi::$6 = atoi::$11 << 1 -- vwsm1=vwsm1_rol_1 
    asl atoi__6
    rol atoi__6+1
    // res * 10 + str[i]
    // [1104] atoi::$7 = atoi::$6 + atoi::str#2[atoi::i#4] -- vwsm1=vwsm1_plus_pbuz2_derefidx_vbum3 
    ldy i
    lda atoi__7
    clc
    adc (str),y
    sta atoi__7
    bcc !+
    inc atoi__7+1
  !:
    // res = res * 10 + str[i] - '0'
    // [1105] atoi::res#1 = atoi::$7 - '0' -- vwsm1=vwsm1_minus_vbuc1 
    lda res
    sec
    sbc #'0'
    sta res
    bcs !+
    dec res+1
  !:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [1106] atoi::i#2 = ++ atoi::i#4 -- vbum1=_inc_vbum1 
    inc i
    // [1094] phi from atoi::@4 to atoi::@3 [phi:atoi::@4->atoi::@3]
    // [1094] phi atoi::negative#2 = atoi::negative#2 [phi:atoi::@4->atoi::@3#0] -- register_copy 
    // [1094] phi atoi::res#2 = atoi::res#1 [phi:atoi::@4->atoi::@3#1] -- register_copy 
    // [1094] phi atoi::i#4 = atoi::i#2 [phi:atoi::@4->atoi::@3#2] -- register_copy 
    jmp __b3
  .segment Data
    .label atoi__6 = return
    .label atoi__7 = return
    .label res = return
    // Initialize sign as positive
    i: .byte 0
    return: .word 0
    // Initialize result
    negative: .byte 0
    atoi__10: .word 0
    .label atoi__11 = return
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
// __mem() unsigned int fgets(__zp($29) char *ptr, unsigned int size, __zp($3b) struct $2 *stream)
fgets: {
    .label ptr = $29
    .label stream = $3b
    // unsigned char sp = (unsigned char)stream
    // [1107] fgets::sp#0 = (char)fgets::stream#0 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_chkin(__logical)
    // [1108] fgets::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fgets::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    tay
    lda __stdio_file+$40,y
    sta cbm_k_chkin1_channel
    // fgets::cbm_k_chkin1
    // char status
    // [1109] fgets::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fgets::cbm_k_readst1
    // char status
    // [1111] fgets::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [1113] fgets::cbm_k_readst1_return#0 = fgets::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fgets::cbm_k_readst1_@return
    // }
    // [1114] fgets::cbm_k_readst1_return#1 = fgets::cbm_k_readst1_return#0
    // fgets::@9
    // cbm_k_readst()
    // [1115] fgets::$1 = fgets::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [1116] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$1 -- pbuc1_derefidx_vbum1=vbum2 
    lda fgets__1
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [1117] if(0==((char *)&__stdio_file+$46)[fgets::sp#0]) goto fgets::@1 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b8
    // [1118] phi from fgets::@10 fgets::@3 fgets::@9 to fgets::@return [phi:fgets::@10/fgets::@3/fgets::@9->fgets::@return]
  __b1:
    // [1118] phi fgets::return#1 = 0 [phi:fgets::@10/fgets::@3/fgets::@9->fgets::@return#0] -- vwum1=vbuc1 
    lda #<0
    sta return
    sta return+1
    // fgets::@return
    // }
    // [1119] return 
    rts
    // [1120] phi from fgets::@13 to fgets::@1 [phi:fgets::@13->fgets::@1]
    // [1120] phi fgets::read#10 = fgets::read#1 [phi:fgets::@13->fgets::@1#0] -- register_copy 
    // [1120] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@13->fgets::@1#1] -- register_copy 
    // [1120] phi fgets::ptr#10 = fgets::ptr#12 [phi:fgets::@13->fgets::@1#2] -- register_copy 
    // [1120] phi from fgets::@9 to fgets::@1 [phi:fgets::@9->fgets::@1]
  __b8:
    // [1120] phi fgets::read#10 = 0 [phi:fgets::@9->fgets::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta read
    sta read+1
    // [1120] phi fgets::remaining#11 = flash_read::b#0 [phi:fgets::@9->fgets::@1#1] -- vwum1=vbuc1 
    lda #<flash_read.b
    sta remaining
    lda #>flash_read.b
    sta remaining+1
    // [1120] phi fgets::ptr#10 = fgets::ptr#2 [phi:fgets::@9->fgets::@1#2] -- register_copy 
    // fgets::@1
    // fgets::@6
  __b6:
    // if (remaining >= 512)
    // [1121] if(fgets::remaining#11>=$200) goto fgets::@2 -- vwum1_ge_vwuc1_then_la1 
    lda remaining+1
    cmp #>$200
    bcc !+
    beq !__b2+
    jmp __b2
  !__b2:
    lda remaining
    cmp #<$200
    bcc !__b2+
    jmp __b2
  !__b2:
  !:
    // fgets::@7
    // cx16_k_macptr(remaining, ptr)
    // [1122] cx16_k_macptr::bytes = fgets::remaining#11 -- vbum1=vwum2 
    lda remaining
    sta cx16_k_macptr.bytes
    // [1123] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [1124] call cx16_k_macptr
    jsr cx16_k_macptr
    // [1125] cx16_k_macptr::return#4 = cx16_k_macptr::return#1
    // fgets::@12
  __b12:
    // bytes = cx16_k_macptr(remaining, ptr)
    // [1126] fgets::bytes#3 = cx16_k_macptr::return#4
    // [1127] phi from fgets::@11 fgets::@12 to fgets::cbm_k_readst2 [phi:fgets::@11/fgets::@12->fgets::cbm_k_readst2]
    // [1127] phi fgets::bytes#10 = fgets::bytes#2 [phi:fgets::@11/fgets::@12->fgets::cbm_k_readst2#0] -- register_copy 
    // fgets::cbm_k_readst2
    // char status
    // [1128] fgets::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [1130] fgets::cbm_k_readst2_return#0 = fgets::cbm_k_readst2_status -- vbum1=vbum2 
    sta cbm_k_readst2_return
    // fgets::cbm_k_readst2_@return
    // }
    // [1131] fgets::cbm_k_readst2_return#1 = fgets::cbm_k_readst2_return#0
    // fgets::@10
    // cbm_k_readst()
    // [1132] fgets::$8 = fgets::cbm_k_readst2_return#1
    // __status = cbm_k_readst()
    // [1133] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$8 -- pbuc1_derefidx_vbum1=vbum2 
    lda fgets__8
    ldy sp
    sta __stdio_file+$46,y
    // __status & 0xBF
    // [1134] fgets::$9 = ((char *)&__stdio_file+$46)[fgets::sp#0] & $bf -- vbum1=pbuc1_derefidx_vbum2_band_vbuc2 
    lda #$bf
    and __stdio_file+$46,y
    sta fgets__9
    // if (__status & 0xBF)
    // [1135] if(0==fgets::$9) goto fgets::@3 -- 0_eq_vbum1_then_la1 
    beq __b3
    jmp __b1
    // fgets::@3
  __b3:
    // if (bytes == 0xFFFF)
    // [1136] if(fgets::bytes#10!=$ffff) goto fgets::@4 -- vwum1_neq_vwuc1_then_la1 
    lda bytes+1
    cmp #>$ffff
    bne __b4
    lda bytes
    cmp #<$ffff
    bne __b4
    jmp __b1
    // fgets::@4
  __b4:
    // read += bytes
    // [1137] fgets::read#1 = fgets::read#10 + fgets::bytes#10 -- vwum1=vwum1_plus_vwum2 
    clc
    lda read
    adc bytes
    sta read
    lda read+1
    adc bytes+1
    sta read+1
    // ptr += bytes
    // [1138] fgets::ptr#0 = fgets::ptr#10 + fgets::bytes#10 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z ptr
    adc bytes
    sta.z ptr
    lda.z ptr+1
    adc bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [1139] fgets::$13 = byte1  fgets::ptr#0 -- vbum1=_byte1_pbuz2 
    sta fgets__13
    // if (BYTE1(ptr) == 0xC0)
    // [1140] if(fgets::$13!=$c0) goto fgets::@5 -- vbum1_neq_vbuc1_then_la1 
    lda #$c0
    cmp fgets__13
    bne __b5
    // fgets::@8
    // ptr -= 0x2000
    // [1141] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [1142] phi from fgets::@4 fgets::@8 to fgets::@5 [phi:fgets::@4/fgets::@8->fgets::@5]
    // [1142] phi fgets::ptr#12 = fgets::ptr#0 [phi:fgets::@4/fgets::@8->fgets::@5#0] -- register_copy 
    // fgets::@5
  __b5:
    // remaining -= bytes
    // [1143] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#10 -- vwum1=vwum1_minus_vwum2 
    lda remaining
    sec
    sbc bytes
    sta remaining
    lda remaining+1
    sbc bytes+1
    sta remaining+1
    // while ((__status == 0) && ((size && remaining) || !size))
    // [1144] if(((char *)&__stdio_file+$46)[fgets::sp#0]==0) goto fgets::@13 -- pbuc1_derefidx_vbum1_eq_0_then_la1 
    ldy sp
    lda __stdio_file+$46,y
    cmp #0
    beq __b13
    // [1118] phi from fgets::@13 fgets::@5 to fgets::@return [phi:fgets::@13/fgets::@5->fgets::@return]
    // [1118] phi fgets::return#1 = fgets::read#1 [phi:fgets::@13/fgets::@5->fgets::@return#0] -- register_copy 
    rts
    // fgets::@13
  __b13:
    // while ((__status == 0) && ((size && remaining) || !size))
    // [1145] if(0!=fgets::remaining#1) goto fgets::@1 -- 0_neq_vwum1_then_la1 
    lda remaining
    ora remaining+1
    beq !__b6+
    jmp __b6
  !__b6:
    rts
    // fgets::@2
  __b2:
    // cx16_k_macptr(512, ptr)
    // [1146] cx16_k_macptr::bytes = $200 -- vbum1=vwuc1 
    lda #<$200
    sta cx16_k_macptr.bytes
    // [1147] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [1148] call cx16_k_macptr
    jsr cx16_k_macptr
    // [1149] cx16_k_macptr::return#3 = cx16_k_macptr::return#1
    // fgets::@11
    // bytes = cx16_k_macptr(512, ptr)
    // [1150] fgets::bytes#2 = cx16_k_macptr::return#3
    jmp __b12
  .segment Data
    .label fgets__1 = cbm_k_readst1_return
    .label fgets__8 = cbm_k_readst2_return
    fgets__9: .byte 0
    fgets__13: .byte 0
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
}
.segment Code
  // snprintf_init
/// Initialize the snprintf() state
// void snprintf_init(char *s, unsigned int n)
snprintf_init: {
    // __snprintf_capacity = n
    // [1151] __snprintf_capacity = $ffff -- vwum1=vwuc1 
    lda #<$ffff
    sta __snprintf_capacity
    lda #>$ffff
    sta __snprintf_capacity+1
    // __snprintf_size = 0
    // [1152] __snprintf_size = 0 -- vwum1=vbuc1 
    lda #<0
    sta __snprintf_size
    sta __snprintf_size+1
    // __snprintf_buffer = s
    // [1153] __snprintf_buffer = info_rom::rom_name -- pbuz1=pbuc1 
    lda #<info_rom.rom_name
    sta.z __snprintf_buffer
    lda #>info_rom.rom_name
    sta.z __snprintf_buffer+1
    // snprintf_init::@return
    // }
    // [1154] return 
    rts
}
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(void (*putc)(char), __mem() char uvalue, char format_min_length, char format_justify_left, char format_sign_always, char format_zero_padding, char format_upper_case, char format_radix)
printf_uchar: {
    // printf_uchar::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1156] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [1157] uctoa::value#1 = printf_uchar::uvalue#2
    // [1158] call uctoa
  // Format number into buffer
    // [1329] phi from printf_uchar::@1 to uctoa [phi:printf_uchar::@1->uctoa]
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1159] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [1160] call printf_number_buffer
  // Print using format
    // [1024] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [1024] phi printf_number_buffer::putc#10 = &snputc [phi:printf_uchar::@2->printf_number_buffer#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_number_buffer.putc
    lda #>snputc
    sta.z printf_number_buffer.putc+1
    // [1024] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_uchar::@2->printf_number_buffer#1] -- register_copy 
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [1161] return 
    rts
  .segment Data
    uvalue: .byte 0
}
.segment Code
  // insertup
// Insert a new line, and scroll the upper part of the screen up.
// void insertup(char rows)
insertup: {
    // __conio.width+1
    // [1162] insertup::$0 = *((char *)&__conio+6) + 1 -- vbum1=_deref_pbuc1_plus_1 
    lda __conio+6
    inc
    sta insertup__0
    // unsigned char width = (__conio.width+1) * 2
    // [1163] insertup::width#0 = insertup::$0 << 1 -- vbum1=vbum1_rol_1 
    // {asm{.byte $db}}
    asl width
    // [1164] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [1164] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbum1=vbuc1 
    lda #0
    sta y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [1165] if(insertup::y#2<*((char *)&__conio+1)) goto insertup::@2 -- vbum1_lt__deref_pbuc1_then_la1 
    lda y
    cmp __conio+1
    bcc __b2
    // [1166] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [1167] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [1168] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [1169] insertup::$4 = insertup::y#2 + 1 -- vbum1=vbum2_plus_1 
    lda y
    inc
    sta insertup__4
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [1170] insertup::$6 = insertup::y#2 << 1 -- vbum1=vbum2_rol_1 
    lda y
    asl
    sta insertup__6
    // [1171] insertup::$7 = insertup::$4 << 1 -- vbum1=vbum1_rol_1 
    asl insertup__7
    // [1172] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+5) -- vbum1=_deref_pbuc1 
    lda __conio+5
    sta memcpy8_vram_vram.dbank_vram
    // [1173] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwum1=pwuc1_derefidx_vbum2 
    ldy insertup__6
    lda __conio+$15,y
    sta memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta memcpy8_vram_vram.doffset_vram+1
    // [1174] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+5) -- vbum1=_deref_pbuc1 
    lda __conio+5
    sta memcpy8_vram_vram.sbank_vram
    // [1175] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwum1=pwuc1_derefidx_vbum2 
    ldy insertup__7
    lda __conio+$15,y
    sta memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta memcpy8_vram_vram.soffset_vram+1
    // [1176] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbum1=vbum2 
    lda width
    sta memcpy8_vram_vram.num8_1
    // [1177] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [1178] insertup::y#1 = ++ insertup::y#2 -- vbum1=_inc_vbum1 
    inc y
    // [1164] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [1164] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    insertup__0: .byte 0
    insertup__4: .byte 0
    insertup__6: .byte 0
    .label insertup__7 = insertup__4
    .label width = insertup__0
    y: .byte 0
}
.segment Code
  // clearline
clearline: {
    .label c = $22
    // unsigned int addr = __conio.offsets[__conio.cursor_y]
    // [1179] clearline::$3 = *((char *)&__conio+1) << 1 -- vbum1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta clearline__3
    // [1180] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwum1=pwuc1_derefidx_vbum2 
    tay
    lda __conio+$15,y
    sta addr
    lda __conio+$15+1,y
    sta addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1181] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [1182] clearline::$0 = byte0  clearline::addr#0 -- vbum1=_byte0_vwum2 
    lda addr
    sta clearline__0
    // *VERA_ADDRX_L = BYTE0(addr)
    // [1183] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [1184] clearline::$1 = byte1  clearline::addr#0 -- vbum1=_byte1_vwum2 
    lda addr+1
    sta clearline__1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [1185] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [1186] clearline::$2 = *((char *)&__conio+5) | VERA_INC_1 -- vbum1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta clearline__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1187] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [1188] clearline::c#0 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z c
    // [1189] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [1189] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [1190] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1191] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [1192] clearline::c#1 = -- clearline::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [1193] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b1
    // clearline::@return
    // }
    // [1194] return 
    rts
  .segment Data
    clearline__0: .byte 0
    clearline__1: .byte 0
    clearline__2: .byte 0
    clearline__3: .byte 0
    addr: .word 0
}
.segment Code
  // frame_maskxy
// __mem() char frame_maskxy(__mem() char x, __mem() char y)
frame_maskxy: {
    // frame_maskxy::cpeekcxy1
    // gotoxy(x,y)
    // [1196] gotoxy::x#5 = frame_maskxy::cpeekcxy1_x#0 -- vbum1=vbum2 
    lda cpeekcxy1_x
    sta gotoxy.x
    // [1197] gotoxy::y#5 = frame_maskxy::cpeekcxy1_y#0 -- vbum1=vbum2 
    lda cpeekcxy1_y
    sta gotoxy.y
    // [1198] call gotoxy
    // [201] phi from frame_maskxy::cpeekcxy1 to gotoxy [phi:frame_maskxy::cpeekcxy1->gotoxy]
    // [201] phi gotoxy::y#17 = gotoxy::y#5 [phi:frame_maskxy::cpeekcxy1->gotoxy#0] -- register_copy 
    // [201] phi gotoxy::x#17 = gotoxy::x#5 [phi:frame_maskxy::cpeekcxy1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // frame_maskxy::cpeekcxy1_cpeekc1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1199] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [1200] frame_maskxy::cpeekcxy1_cpeekc1_$0 = byte0  *((unsigned int *)&__conio+$13) -- vbum1=_byte0__deref_pwuc1 
    lda __conio+$13
    sta cpeekcxy1_cpeekc1_frame_maskxy__0
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [1201] *VERA_ADDRX_L = frame_maskxy::cpeekcxy1_cpeekc1_$0 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [1202] frame_maskxy::cpeekcxy1_cpeekc1_$1 = byte1  *((unsigned int *)&__conio+$13) -- vbum1=_byte1__deref_pwuc1 
    lda __conio+$13+1
    sta cpeekcxy1_cpeekc1_frame_maskxy__1
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [1203] *VERA_ADDRX_M = frame_maskxy::cpeekcxy1_cpeekc1_$1 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_0
    // [1204] frame_maskxy::cpeekcxy1_cpeekc1_$2 = *((char *)&__conio+5) -- vbum1=_deref_pbuc1 
    lda __conio+5
    sta cpeekcxy1_cpeekc1_frame_maskxy__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_0
    // [1205] *VERA_ADDRX_H = frame_maskxy::cpeekcxy1_cpeekc1_$2 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_H
    // return *VERA_DATA0;
    // [1206] frame_maskxy::c#0 = *VERA_DATA0 -- vbum1=_deref_pbuc1 
    lda VERA_DATA0
    sta c
    // frame_maskxy::@12
    // case 0x70: // DR corner.
    //             return 0b0110;
    // [1207] if(frame_maskxy::c#0==$70) goto frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$70
    cmp c
    beq __b2
    // frame_maskxy::@1
    // case 0x6E: // DL corner.
    //             return 0b0011;
    // [1208] if(frame_maskxy::c#0==$6e) goto frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$6e
    cmp c
    beq __b1
    // frame_maskxy::@2
    // case 0x6D: // UR corner.
    //             return 0b1100;
    // [1209] if(frame_maskxy::c#0==$6d) goto frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$6d
    cmp c
    beq __b3
    // frame_maskxy::@3
    // case 0x7D: // UL corner.
    //             return 0b1001;
    // [1210] if(frame_maskxy::c#0==$7d) goto frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$7d
    cmp c
    beq __b4
    // frame_maskxy::@4
    // case 0x40: // HL line.
    //             return 0b0101;
    // [1211] if(frame_maskxy::c#0==$40) goto frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$40
    cmp c
    beq __b5
    // frame_maskxy::@5
    // case 0x5D: // VL line.
    //             return 0b1010;
    // [1212] if(frame_maskxy::c#0==$5d) goto frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$5d
    cmp c
    beq __b6
    // frame_maskxy::@6
    // case 0x6B: // VR junction.
    //             return 0b1110;
    // [1213] if(frame_maskxy::c#0==$6b) goto frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$6b
    cmp c
    beq __b7
    // frame_maskxy::@7
    // case 0x73: // VL junction.
    //             return 0b1011;
    // [1214] if(frame_maskxy::c#0==$73) goto frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$73
    cmp c
    beq __b8
    // frame_maskxy::@8
    // case 0x72: // HD junction.
    //             return 0b0111;
    // [1215] if(frame_maskxy::c#0==$72) goto frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$72
    cmp c
    beq __b9
    // frame_maskxy::@9
    // case 0x71: // HU junction.
    //             return 0b1101;
    // [1216] if(frame_maskxy::c#0==$71) goto frame_maskxy::@return -- vbum1_eq_vbuc1_then_la1 
    lda #$71
    cmp c
    beq __b10
    // frame_maskxy::@10
    // case 0x5B: // HV junction.
    //             return 0b1111;
    // [1217] if(frame_maskxy::c#0==$5b) goto frame_maskxy::@11 -- vbum1_eq_vbuc1_then_la1 
    lda #$5b
    cmp c
    beq __b11
    // [1219] phi from frame_maskxy::@10 to frame_maskxy::@return [phi:frame_maskxy::@10->frame_maskxy::@return]
    // [1219] phi frame_maskxy::return#12 = 0 [phi:frame_maskxy::@10->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    rts
    // [1218] phi from frame_maskxy::@10 to frame_maskxy::@11 [phi:frame_maskxy::@10->frame_maskxy::@11]
    // frame_maskxy::@11
  __b11:
    // [1219] phi from frame_maskxy::@11 to frame_maskxy::@return [phi:frame_maskxy::@11->frame_maskxy::@return]
    // [1219] phi frame_maskxy::return#12 = $f [phi:frame_maskxy::@11->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$f
    sta return
    rts
    // [1219] phi from frame_maskxy::@1 to frame_maskxy::@return [phi:frame_maskxy::@1->frame_maskxy::@return]
  __b1:
    // [1219] phi frame_maskxy::return#12 = 3 [phi:frame_maskxy::@1->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #3
    sta return
    rts
    // [1219] phi from frame_maskxy::@12 to frame_maskxy::@return [phi:frame_maskxy::@12->frame_maskxy::@return]
  __b2:
    // [1219] phi frame_maskxy::return#12 = 6 [phi:frame_maskxy::@12->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #6
    sta return
    rts
    // [1219] phi from frame_maskxy::@2 to frame_maskxy::@return [phi:frame_maskxy::@2->frame_maskxy::@return]
  __b3:
    // [1219] phi frame_maskxy::return#12 = $c [phi:frame_maskxy::@2->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$c
    sta return
    rts
    // [1219] phi from frame_maskxy::@3 to frame_maskxy::@return [phi:frame_maskxy::@3->frame_maskxy::@return]
  __b4:
    // [1219] phi frame_maskxy::return#12 = 9 [phi:frame_maskxy::@3->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #9
    sta return
    rts
    // [1219] phi from frame_maskxy::@4 to frame_maskxy::@return [phi:frame_maskxy::@4->frame_maskxy::@return]
  __b5:
    // [1219] phi frame_maskxy::return#12 = 5 [phi:frame_maskxy::@4->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #5
    sta return
    rts
    // [1219] phi from frame_maskxy::@5 to frame_maskxy::@return [phi:frame_maskxy::@5->frame_maskxy::@return]
  __b6:
    // [1219] phi frame_maskxy::return#12 = $a [phi:frame_maskxy::@5->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$a
    sta return
    rts
    // [1219] phi from frame_maskxy::@6 to frame_maskxy::@return [phi:frame_maskxy::@6->frame_maskxy::@return]
  __b7:
    // [1219] phi frame_maskxy::return#12 = $e [phi:frame_maskxy::@6->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$e
    sta return
    rts
    // [1219] phi from frame_maskxy::@7 to frame_maskxy::@return [phi:frame_maskxy::@7->frame_maskxy::@return]
  __b8:
    // [1219] phi frame_maskxy::return#12 = $b [phi:frame_maskxy::@7->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$b
    sta return
    rts
    // [1219] phi from frame_maskxy::@8 to frame_maskxy::@return [phi:frame_maskxy::@8->frame_maskxy::@return]
  __b9:
    // [1219] phi frame_maskxy::return#12 = 7 [phi:frame_maskxy::@8->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #7
    sta return
    rts
    // [1219] phi from frame_maskxy::@9 to frame_maskxy::@return [phi:frame_maskxy::@9->frame_maskxy::@return]
  __b10:
    // [1219] phi frame_maskxy::return#12 = $d [phi:frame_maskxy::@9->frame_maskxy::@return#0] -- vbum1=vbuc1 
    lda #$d
    sta return
    // frame_maskxy::@return
    // }
    // [1220] return 
    rts
  .segment Data
    cpeekcxy1_cpeekc1_frame_maskxy__0: .byte 0
    cpeekcxy1_cpeekc1_frame_maskxy__1: .byte 0
    cpeekcxy1_cpeekc1_frame_maskxy__2: .byte 0
    cpeekcxy1_x: .byte 0
    cpeekcxy1_y: .byte 0
    c: .byte 0
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
// __mem() char frame_char(__mem() char mask)
frame_char: {
    // case 0b0110:
    //             return 0x70;
    // [1222] if(frame_char::mask#10==6) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    lda #6
    cmp mask
    beq __b1
    // frame_char::@1
    // case 0b0011:
    //             return 0x6E;
    // [1223] if(frame_char::mask#10==3) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // DR corner.
    lda #3
    cmp mask
    beq __b2
    // frame_char::@2
    // case 0b1100:
    //             return 0x6D;
    // [1224] if(frame_char::mask#10==$c) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // DL corner.
    lda #$c
    cmp mask
    beq __b3
    // frame_char::@3
    // case 0b1001:
    //             return 0x7D;
    // [1225] if(frame_char::mask#10==9) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // UR corner.
    lda #9
    cmp mask
    beq __b4
    // frame_char::@4
    // case 0b0101:
    //             return 0x40;
    // [1226] if(frame_char::mask#10==5) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // UL corner.
    lda #5
    cmp mask
    beq __b5
    // frame_char::@5
    // case 0b1010:
    //             return 0x5D;
    // [1227] if(frame_char::mask#10==$a) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // HL line.
    lda #$a
    cmp mask
    beq __b6
    // frame_char::@6
    // case 0b1110:
    //             return 0x6B;
    // [1228] if(frame_char::mask#10==$e) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // VL line.
    lda #$e
    cmp mask
    beq __b7
    // frame_char::@7
    // case 0b1011:
    //             return 0x73;
    // [1229] if(frame_char::mask#10==$b) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // VR junction.
    lda #$b
    cmp mask
    beq __b8
    // frame_char::@8
    // case 0b0111:
    //             return 0x72;
    // [1230] if(frame_char::mask#10==7) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // VL junction.
    lda #7
    cmp mask
    beq __b9
    // frame_char::@9
    // case 0b1101:
    //             return 0x71;
    // [1231] if(frame_char::mask#10==$d) goto frame_char::@return -- vbum1_eq_vbuc1_then_la1 
    // HD junction.
    lda #$d
    cmp mask
    beq __b10
    // frame_char::@10
    // case 0b1111:
    //             return 0x5B;
    // [1232] if(frame_char::mask#10==$f) goto frame_char::@11 -- vbum1_eq_vbuc1_then_la1 
    // HU junction.
    lda #$f
    cmp mask
    beq __b11
    // [1234] phi from frame_char::@10 to frame_char::@return [phi:frame_char::@10->frame_char::@return]
    // [1234] phi frame_char::return#12 = $20 [phi:frame_char::@10->frame_char::@return#0] -- vbum1=vbuc1 
    lda #$20
    sta return
    rts
    // [1233] phi from frame_char::@10 to frame_char::@11 [phi:frame_char::@10->frame_char::@11]
    // frame_char::@11
  __b11:
    // [1234] phi from frame_char::@11 to frame_char::@return [phi:frame_char::@11->frame_char::@return]
    // [1234] phi frame_char::return#12 = $5b [phi:frame_char::@11->frame_char::@return#0] -- vbum1=vbuc1 
    lda #$5b
    sta return
    rts
    // [1234] phi from frame_char to frame_char::@return [phi:frame_char->frame_char::@return]
  __b1:
    // [1234] phi frame_char::return#12 = $70 [phi:frame_char->frame_char::@return#0] -- vbum1=vbuc1 
    lda #$70
    sta return
    rts
    // [1234] phi from frame_char::@1 to frame_char::@return [phi:frame_char::@1->frame_char::@return]
  __b2:
    // [1234] phi frame_char::return#12 = $6e [phi:frame_char::@1->frame_char::@return#0] -- vbum1=vbuc1 
    lda #$6e
    sta return
    rts
    // [1234] phi from frame_char::@2 to frame_char::@return [phi:frame_char::@2->frame_char::@return]
  __b3:
    // [1234] phi frame_char::return#12 = $6d [phi:frame_char::@2->frame_char::@return#0] -- vbum1=vbuc1 
    lda #$6d
    sta return
    rts
    // [1234] phi from frame_char::@3 to frame_char::@return [phi:frame_char::@3->frame_char::@return]
  __b4:
    // [1234] phi frame_char::return#12 = $7d [phi:frame_char::@3->frame_char::@return#0] -- vbum1=vbuc1 
    lda #$7d
    sta return
    rts
    // [1234] phi from frame_char::@4 to frame_char::@return [phi:frame_char::@4->frame_char::@return]
  __b5:
    // [1234] phi frame_char::return#12 = $40 [phi:frame_char::@4->frame_char::@return#0] -- vbum1=vbuc1 
    lda #$40
    sta return
    rts
    // [1234] phi from frame_char::@5 to frame_char::@return [phi:frame_char::@5->frame_char::@return]
  __b6:
    // [1234] phi frame_char::return#12 = $5d [phi:frame_char::@5->frame_char::@return#0] -- vbum1=vbuc1 
    lda #$5d
    sta return
    rts
    // [1234] phi from frame_char::@6 to frame_char::@return [phi:frame_char::@6->frame_char::@return]
  __b7:
    // [1234] phi frame_char::return#12 = $6b [phi:frame_char::@6->frame_char::@return#0] -- vbum1=vbuc1 
    lda #$6b
    sta return
    rts
    // [1234] phi from frame_char::@7 to frame_char::@return [phi:frame_char::@7->frame_char::@return]
  __b8:
    // [1234] phi frame_char::return#12 = $73 [phi:frame_char::@7->frame_char::@return#0] -- vbum1=vbuc1 
    lda #$73
    sta return
    rts
    // [1234] phi from frame_char::@8 to frame_char::@return [phi:frame_char::@8->frame_char::@return]
  __b9:
    // [1234] phi frame_char::return#12 = $72 [phi:frame_char::@8->frame_char::@return#0] -- vbum1=vbuc1 
    lda #$72
    sta return
    rts
    // [1234] phi from frame_char::@9 to frame_char::@return [phi:frame_char::@9->frame_char::@return]
  __b10:
    // [1234] phi frame_char::return#12 = $71 [phi:frame_char::@9->frame_char::@return#0] -- vbum1=vbuc1 
    lda #$71
    sta return
    // frame_char::@return
    // }
    // [1235] return 
    rts
  .segment Data
    .label return = cputcxy.c
    .label mask = frame_maskxy.return
}
.segment Code
  // cputs
// Output a NUL-terminated string at the current cursor position
// void cputs(__zp($25) const char *s)
cputs: {
    .label s = $25
    // [1237] phi from cputs to cputs::@1 [phi:cputs->cputs::@1]
    // [1237] phi cputs::s#2 = frame_draw::s [phi:cputs->cputs::@1#0] -- pbuz1=pbuc1 
    lda #<frame_draw.s
    sta.z s
    lda #>frame_draw.s
    sta.z s+1
    // cputs::@1
  __b1:
    // while(c=*s++)
    // [1238] cputs::c#1 = *cputs::s#2 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta c
    // [1239] cputs::s#0 = ++ cputs::s#2 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [1240] if(0!=cputs::c#1) goto cputs::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // cputs::@return
    // }
    // [1241] return 
    rts
    // cputs::@2
  __b2:
    // cputc(c)
    // [1242] stackpush(char) = cputs::c#1 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [1243] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [1237] phi from cputs::@2 to cputs::@1 [phi:cputs::@2->cputs::@1]
    // [1237] phi cputs::s#2 = cputs::s#0 [phi:cputs::@2->cputs::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    c: .byte 0
}
.segment Code
  // print_chip_line
// void print_chip_line(__mem() char x, __mem() char y, __mem() char w, __mem() char c)
print_chip_line: {
    // gotoxy(x, y)
    // [1246] gotoxy::x#6 = print_chip_line::x#16 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1247] gotoxy::y#6 = print_chip_line::y#16 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1248] call gotoxy
    // [201] phi from print_chip_line to gotoxy [phi:print_chip_line->gotoxy]
    // [201] phi gotoxy::y#17 = gotoxy::y#6 [phi:print_chip_line->gotoxy#0] -- register_copy 
    // [201] phi gotoxy::x#17 = gotoxy::x#6 [phi:print_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1249] phi from print_chip_line to print_chip_line::@4 [phi:print_chip_line->print_chip_line::@4]
    // print_chip_line::@4
    // textcolor(GREY)
    // [1250] call textcolor
    // [183] phi from print_chip_line::@4 to textcolor [phi:print_chip_line::@4->textcolor]
    // [183] phi textcolor::color#17 = GREY [phi:print_chip_line::@4->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [1251] phi from print_chip_line::@4 to print_chip_line::@5 [phi:print_chip_line::@4->print_chip_line::@5]
    // print_chip_line::@5
    // bgcolor(BLUE)
    // [1252] call bgcolor
    // [188] phi from print_chip_line::@5 to bgcolor [phi:print_chip_line::@5->bgcolor]
    // [188] phi bgcolor::color#14 = BLUE [phi:print_chip_line::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // print_chip_line::@6
    // cputc(VERA_CHR_UR)
    // [1253] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [1254] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [1256] call textcolor
    // [183] phi from print_chip_line::@6 to textcolor [phi:print_chip_line::@6->textcolor]
    // [183] phi textcolor::color#17 = WHITE [phi:print_chip_line::@6->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [1257] phi from print_chip_line::@6 to print_chip_line::@7 [phi:print_chip_line::@6->print_chip_line::@7]
    // print_chip_line::@7
    // bgcolor(BLACK)
    // [1258] call bgcolor
    // [188] phi from print_chip_line::@7 to bgcolor [phi:print_chip_line::@7->bgcolor]
    // [188] phi bgcolor::color#14 = BLACK [phi:print_chip_line::@7->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // [1259] phi from print_chip_line::@7 to print_chip_line::@1 [phi:print_chip_line::@7->print_chip_line::@1]
    // [1259] phi print_chip_line::i#2 = 0 [phi:print_chip_line::@7->print_chip_line::@1#0] -- vbum1=vbuc1 
    lda #0
    sta i
    // print_chip_line::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [1260] if(print_chip_line::i#2<print_chip_line::w#10) goto print_chip_line::@2 -- vbum1_lt_vbum2_then_la1 
    lda i
    cmp w
    bcc __b2
    // [1261] phi from print_chip_line::@1 to print_chip_line::@3 [phi:print_chip_line::@1->print_chip_line::@3]
    // print_chip_line::@3
    // textcolor(GREY)
    // [1262] call textcolor
    // [183] phi from print_chip_line::@3 to textcolor [phi:print_chip_line::@3->textcolor]
    // [183] phi textcolor::color#17 = GREY [phi:print_chip_line::@3->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [1263] phi from print_chip_line::@3 to print_chip_line::@8 [phi:print_chip_line::@3->print_chip_line::@8]
    // print_chip_line::@8
    // bgcolor(BLUE)
    // [1264] call bgcolor
    // [188] phi from print_chip_line::@8 to bgcolor [phi:print_chip_line::@8->bgcolor]
    // [188] phi bgcolor::color#14 = BLUE [phi:print_chip_line::@8->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // print_chip_line::@9
    // cputc(VERA_CHR_UL)
    // [1265] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [1266] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [1268] call textcolor
    // [183] phi from print_chip_line::@9 to textcolor [phi:print_chip_line::@9->textcolor]
    // [183] phi textcolor::color#17 = WHITE [phi:print_chip_line::@9->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [1269] phi from print_chip_line::@9 to print_chip_line::@10 [phi:print_chip_line::@9->print_chip_line::@10]
    // print_chip_line::@10
    // bgcolor(BLACK)
    // [1270] call bgcolor
    // [188] phi from print_chip_line::@10 to bgcolor [phi:print_chip_line::@10->bgcolor]
    // [188] phi bgcolor::color#14 = BLACK [phi:print_chip_line::@10->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // print_chip_line::@11
    // cputcxy(x+2, y, c)
    // [1271] cputcxy::x#8 = print_chip_line::x#16 + 2 -- vbum1=vbum1_plus_2 
    lda cputcxy.x
    clc
    adc #2
    sta cputcxy.x
    // [1272] cputcxy::y#8 = print_chip_line::y#16
    // [1273] cputcxy::c#8 = print_chip_line::c#15 -- vbum1=vbum2 
    lda c
    sta cputcxy.c
    // [1274] call cputcxy
    // [879] phi from print_chip_line::@11 to cputcxy [phi:print_chip_line::@11->cputcxy]
    // [879] phi cputcxy::c#11 = cputcxy::c#8 [phi:print_chip_line::@11->cputcxy#0] -- register_copy 
    // [879] phi cputcxy::y#11 = cputcxy::y#8 [phi:print_chip_line::@11->cputcxy#1] -- register_copy 
    // [879] phi cputcxy::x#11 = cputcxy::x#8 [phi:print_chip_line::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // print_chip_line::@return
    // }
    // [1275] return 
    rts
    // print_chip_line::@2
  __b2:
    // cputc(VERA_CHR_SPACE)
    // [1276] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [1277] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [1279] print_chip_line::i#1 = ++ print_chip_line::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [1259] phi from print_chip_line::@2 to print_chip_line::@1 [phi:print_chip_line::@2->print_chip_line::@1]
    // [1259] phi print_chip_line::i#2 = print_chip_line::i#1 [phi:print_chip_line::@2->print_chip_line::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    i: .byte 0
    .label x = cputcxy.x
    w: .byte 0
    c: .byte 0
    .label y = cputcxy.y
}
.segment Code
  // print_chip_end
// void print_chip_end(__mem() char x, char y, __mem() char w)
print_chip_end: {
    // gotoxy(x, y)
    // [1280] gotoxy::x#7 = print_chip_end::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1281] call gotoxy
    // [201] phi from print_chip_end to gotoxy [phi:print_chip_end->gotoxy]
    // [201] phi gotoxy::y#17 = print_chip::y#21 [phi:print_chip_end->gotoxy#0] -- vbum1=vbuc1 
    lda #print_chip.y
    sta gotoxy.y
    // [201] phi gotoxy::x#17 = gotoxy::x#7 [phi:print_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1282] phi from print_chip_end to print_chip_end::@4 [phi:print_chip_end->print_chip_end::@4]
    // print_chip_end::@4
    // textcolor(GREY)
    // [1283] call textcolor
    // [183] phi from print_chip_end::@4 to textcolor [phi:print_chip_end::@4->textcolor]
    // [183] phi textcolor::color#17 = GREY [phi:print_chip_end::@4->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [1284] phi from print_chip_end::@4 to print_chip_end::@5 [phi:print_chip_end::@4->print_chip_end::@5]
    // print_chip_end::@5
    // bgcolor(BLUE)
    // [1285] call bgcolor
    // [188] phi from print_chip_end::@5 to bgcolor [phi:print_chip_end::@5->bgcolor]
    // [188] phi bgcolor::color#14 = BLUE [phi:print_chip_end::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // print_chip_end::@6
    // cputc(VERA_CHR_UR)
    // [1286] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [1287] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [1289] call textcolor
    // [183] phi from print_chip_end::@6 to textcolor [phi:print_chip_end::@6->textcolor]
    // [183] phi textcolor::color#17 = BLUE [phi:print_chip_end::@6->textcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta textcolor.color
    jsr textcolor
    // [1290] phi from print_chip_end::@6 to print_chip_end::@7 [phi:print_chip_end::@6->print_chip_end::@7]
    // print_chip_end::@7
    // bgcolor(BLACK)
    // [1291] call bgcolor
    // [188] phi from print_chip_end::@7 to bgcolor [phi:print_chip_end::@7->bgcolor]
    // [188] phi bgcolor::color#14 = BLACK [phi:print_chip_end::@7->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // [1292] phi from print_chip_end::@7 to print_chip_end::@1 [phi:print_chip_end::@7->print_chip_end::@1]
    // [1292] phi print_chip_end::i#2 = 0 [phi:print_chip_end::@7->print_chip_end::@1#0] -- vbum1=vbuc1 
    lda #0
    sta i
    // print_chip_end::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [1293] if(print_chip_end::i#2<print_chip_end::w#0) goto print_chip_end::@2 -- vbum1_lt_vbum2_then_la1 
    lda i
    cmp w
    bcc __b2
    // [1294] phi from print_chip_end::@1 to print_chip_end::@3 [phi:print_chip_end::@1->print_chip_end::@3]
    // print_chip_end::@3
    // textcolor(GREY)
    // [1295] call textcolor
    // [183] phi from print_chip_end::@3 to textcolor [phi:print_chip_end::@3->textcolor]
    // [183] phi textcolor::color#17 = GREY [phi:print_chip_end::@3->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [1296] phi from print_chip_end::@3 to print_chip_end::@8 [phi:print_chip_end::@3->print_chip_end::@8]
    // print_chip_end::@8
    // bgcolor(BLUE)
    // [1297] call bgcolor
    // [188] phi from print_chip_end::@8 to bgcolor [phi:print_chip_end::@8->bgcolor]
    // [188] phi bgcolor::color#14 = BLUE [phi:print_chip_end::@8->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // print_chip_end::@9
    // cputc(VERA_CHR_UL)
    // [1298] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [1299] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_end::@return
    // }
    // [1301] return 
    rts
    // print_chip_end::@2
  __b2:
    // cputc(VERA_CHR_HL)
    // [1302] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [1303] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [1305] print_chip_end::i#1 = ++ print_chip_end::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [1292] phi from print_chip_end::@2 to print_chip_end::@1 [phi:print_chip_end::@2->print_chip_end::@1]
    // [1292] phi print_chip_end::i#2 = print_chip_end::i#1 [phi:print_chip_end::@2->print_chip_end::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    i: .byte 0
    .label x = print_chip.x
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
// __mem() unsigned int utoa_append(__zp($31) char *buffer, __mem() unsigned int value, __mem() unsigned int sub)
utoa_append: {
    .label buffer = $31
    // [1307] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [1307] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [1307] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [1308] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwum1_ge_vwum2_then_la1 
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
    // [1309] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // utoa_append::@return
    // }
    // [1310] return 
    rts
    // utoa_append::@2
  __b2:
    // digit++;
    // [1311] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [1312] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwum1=vwum1_minus_vwum2 
    lda value
    sec
    sbc sub
    sta value
    lda value+1
    sbc sub+1
    sta value+1
    // [1307] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [1307] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [1307] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label value = printf_uint.uvalue
    .label sub = utoa.digit_value
    .label return = printf_uint.uvalue
    digit: .byte 0
}
.segment Code
  // strncpy
/// Copies up to n characters from the string pointed to, by src to dst.
/// In a case where the length of src is less than that of n, the remainder of dst will be padded with null bytes.
/// @param dst ? This is the pointer to the destination array where the content is to be copied.
/// @param src ? This is the string to be copied.
/// @param n ? The number of characters to be copied from source.
/// @return The destination
// char * strncpy(__zp($23) char *dst, __zp($25) const char *src, __mem() unsigned int n)
strncpy: {
    .label dst = $23
    .label src = $25
    // [1314] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [1314] phi strncpy::dst#2 = ferror::temp [phi:strncpy->strncpy::@1#0] -- pbuz1=pbuc1 
    lda #<ferror.temp
    sta.z dst
    lda #>ferror.temp
    sta.z dst+1
    // [1314] phi strncpy::src#2 = __errno_error [phi:strncpy->strncpy::@1#1] -- pbuz1=pbuc1 
    lda #<__errno_error
    sta.z src
    lda #>__errno_error
    sta.z src+1
    // [1314] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwum1=vwuc1 
    lda #<0
    sta i
    sta i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [1315] if(strncpy::i#2<strncpy::n#0) goto strncpy::@2 -- vwum1_lt_vwum2_then_la1 
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
    // [1316] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [1317] strncpy::c#0 = *strncpy::src#2 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta c
    // if(c)
    // [1318] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbum1_then_la1 
    beq __b3
    // strncpy::@4
    // src++;
    // [1319] strncpy::src#0 = ++ strncpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1320] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [1320] phi strncpy::src#6 = strncpy::src#2 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [1321] *strncpy::dst#2 = strncpy::c#0 -- _deref_pbuz1=vbum2 
    lda c
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [1322] strncpy::dst#0 = ++ strncpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [1323] strncpy::i#1 = ++ strncpy::i#2 -- vwum1=_inc_vwum1 
    inc i
    bne !+
    inc i+1
  !:
    // [1314] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [1314] phi strncpy::dst#2 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [1314] phi strncpy::src#2 = strncpy::src#6 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [1314] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
    jmp __b1
  .segment Data
    c: .byte 0
    i: .word 0
    n: .word 0
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
// __mem() unsigned int cx16_k_macptr(__mem() volatile char bytes, __zp($2f) void * volatile buffer)
cx16_k_macptr: {
    .label buffer = $2f
    // unsigned int bytes_read
    // [1324] cx16_k_macptr::bytes_read = 0 -- vwum1=vwuc1 
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
    // [1326] cx16_k_macptr::return#0 = cx16_k_macptr::bytes_read -- vwum1=vwum2 
    lda bytes_read
    sta return
    lda bytes_read+1
    sta return+1
    // cx16_k_macptr::@return
    // }
    // [1327] cx16_k_macptr::return#1 = cx16_k_macptr::return#0
    // [1328] return 
    rts
  .segment Data
    bytes: .byte 0
    bytes_read: .word 0
    .label return = fgets.bytes
}
.segment Code
  // uctoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void uctoa(__mem() char value, __zp($23) char *buffer, char radix)
uctoa: {
    .label buffer = $23
    // [1330] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
    // [1330] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1330] phi uctoa::started#2 = 0 [phi:uctoa->uctoa::@1#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [1330] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa->uctoa::@1#2] -- register_copy 
    // [1330] phi uctoa::digit#2 = 0 [phi:uctoa->uctoa::@1#3] -- vbum1=vbuc1 
    sta digit
    // uctoa::@1
  __b1:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1331] if(uctoa::digit#2<3-1) goto uctoa::@2 -- vbum1_lt_vbuc1_then_la1 
    lda digit
    cmp #3-1
    bcc __b2
    // uctoa::@3
    // *buffer++ = DIGITS[(char)value]
    // [1332] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy value
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1333] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1334] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    // uctoa::@return
    // }
    // [1335] return 
    rts
    // uctoa::@2
  __b2:
    // unsigned char digit_value = digit_values[digit]
    // [1336] uctoa::digit_value#0 = RADIX_DECIMAL_VALUES_CHAR[uctoa::digit#2] -- vbum1=pbuc1_derefidx_vbum2 
    ldy digit
    lda RADIX_DECIMAL_VALUES_CHAR,y
    sta digit_value
    // if (started || value >= digit_value)
    // [1337] if(0!=uctoa::started#2) goto uctoa::@5 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b5
    // uctoa::@7
    // [1338] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@5 -- vbum1_ge_vbum2_then_la1 
    lda value
    cmp digit_value
    bcs __b5
    // [1339] phi from uctoa::@7 to uctoa::@4 [phi:uctoa::@7->uctoa::@4]
    // [1339] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@7->uctoa::@4#0] -- register_copy 
    // [1339] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@7->uctoa::@4#1] -- register_copy 
    // [1339] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@7->uctoa::@4#2] -- register_copy 
    // uctoa::@4
  __b4:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1340] uctoa::digit#1 = ++ uctoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [1330] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
    // [1330] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@4->uctoa::@1#0] -- register_copy 
    // [1330] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@4->uctoa::@1#1] -- register_copy 
    // [1330] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@4->uctoa::@1#2] -- register_copy 
    // [1330] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@4->uctoa::@1#3] -- register_copy 
    jmp __b1
    // uctoa::@5
  __b5:
    // uctoa_append(buffer++, value, digit_value)
    // [1341] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [1342] uctoa_append::value#0 = uctoa::value#2
    // [1343] uctoa_append::sub#0 = uctoa::digit_value#0
    // [1344] call uctoa_append
    // [1368] phi from uctoa::@5 to uctoa_append [phi:uctoa::@5->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [1345] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@6
    // value = uctoa_append(buffer++, value, digit_value)
    // [1346] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [1347] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1339] phi from uctoa::@6 to uctoa::@4 [phi:uctoa::@6->uctoa::@4]
    // [1339] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@6->uctoa::@4#0] -- register_copy 
    // [1339] phi uctoa::started#4 = 1 [phi:uctoa::@6->uctoa::@4#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [1339] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@6->uctoa::@4#2] -- register_copy 
    jmp __b4
  .segment Data
    digit_value: .byte 0
    digit: .byte 0
    .label value = printf_uchar.uvalue
    started: .byte 0
}
.segment Code
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
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1348] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [1349] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbum1=_byte0_vwum2 
    lda soffset_vram
    sta memcpy8_vram_vram__0
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [1350] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [1351] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbum1=_byte1_vwum2 
    lda soffset_vram+1
    sta memcpy8_vram_vram__1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [1352] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [1353] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbum1=vbum1_bor_vbuc1 
    lda #VERA_INC_1
    ora memcpy8_vram_vram__2
    sta memcpy8_vram_vram__2
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [1354] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [1355] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [1356] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbum1=_byte0_vwum2 
    lda doffset_vram
    sta memcpy8_vram_vram__3
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [1357] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [1358] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbum1=_byte1_vwum2 
    lda doffset_vram+1
    sta memcpy8_vram_vram__4
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [1359] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [1360] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbum1=vbum1_bor_vbuc1 
    lda #VERA_INC_1
    ora memcpy8_vram_vram__5
    sta memcpy8_vram_vram__5
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [1361] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbum1 
    sta VERA_ADDRX_H
    // [1362] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [1362] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [1363] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbum1=_dec_vbum2 
    ldy num8_1
    dey
    sty num8
    // [1364] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbum1_then_la1 
    lda num8_1
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [1365] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [1366] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [1367] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbum1=vbum2 
    lda num8
    sta num8_1
    jmp __b1
  .segment Data
    memcpy8_vram_vram__0: .byte 0
    memcpy8_vram_vram__1: .byte 0
    .label memcpy8_vram_vram__2 = sbank_vram
    memcpy8_vram_vram__3: .byte 0
    memcpy8_vram_vram__4: .byte 0
    .label memcpy8_vram_vram__5 = dbank_vram
    num8: .byte 0
    dbank_vram: .byte 0
    doffset_vram: .word 0
    sbank_vram: .byte 0
    soffset_vram: .word 0
    num8_1: .byte 0
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
// __mem() char uctoa_append(__zp($27) char *buffer, __mem() char value, __mem() char sub)
uctoa_append: {
    .label buffer = $27
    // [1369] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [1369] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [1369] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [1370] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbum1_ge_vbum2_then_la1 
    lda value
    cmp sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [1371] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [1372] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [1373] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [1374] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbum1=vbum1_minus_vbum2 
    lda value
    sec
    sbc sub
    sta value
    // [1369] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [1369] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [1369] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label value = printf_uchar.uvalue
    .label sub = uctoa.digit_value
    .label return = printf_uchar.uvalue
    digit: .byte 0
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
  // Values of decimal digits
  RADIX_DECIMAL_VALUES_CHAR: .byte $64, $a
  // Values of decimal digits
  RADIX_DECIMAL_VALUES: .word $2710, $3e8, $64, $a
  // Some addressing constants.
  // The different device IDs that can be returned from the manufacturer ID read sequence.
  // To print the graphics on the vera.
  file: .fill $20, 0
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
  status_text: .fill 2*6, 0
  s2: .text "."
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
  smc_bootloader: .word 0