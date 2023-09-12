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
  .label __snprintf_buffer = $de
  .label __errno = $c4
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
// void snputc(__zp($ad) char c)
snputc: {
    .const OFFSET_STACK_C = 0
    .label c = $ad
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
    .label conio_x16_init__4 = $cc
    .label conio_x16_init__5 = $68
    .label conio_x16_init__6 = $cc
    // screenlayer1()
    // [20] call screenlayer1
    jsr screenlayer1
    // [21] phi from conio_x16_init to conio_x16_init::@1 [phi:conio_x16_init->conio_x16_init::@1]
    // conio_x16_init::@1
    // textcolor(CONIO_TEXTCOLOR_DEFAULT)
    // [22] call textcolor
    // [171] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [171] phi textcolor::color#16 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [23] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [24] call bgcolor
    // [176] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [176] phi bgcolor::color#14 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbuz1=vbuc1 
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
    // [31] conio_x16_init::$5 = byte1  conio_x16_init::$4 -- vbuz1=_byte1_vwuz2 
    lda.z conio_x16_init__4+1
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
    // [36] conio_x16_init::$7 = byte0  conio_x16_init::$6 -- vbum1=_byte0_vwuz2 
    lda.z conio_x16_init__6
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
    // [189] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [189] phi gotoxy::y#18 = gotoxy::y#2 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [189] phi gotoxy::x#18 = gotoxy::x#2 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
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
    conio_x16_init__7: .byte 0
}
.segment Code
  // cputc
// Output one character at the current cursor position
// Moves the cursor forward. Scrolls the entire screen if needed
// void cputc(__zp($2e) char c)
cputc: {
    .const OFFSET_STACK_C = 0
    .label cputc__1 = $22
    .label cputc__2 = $4f
    .label cputc__3 = $50
    .label c = $2e
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
    .const bank_set_brom3_bank = 4
    .label main__46 = $ea
    .label fp = $57
    .label rom_chip = $f6
    .label flash_bytes = $60
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
    // main::@16
    // cx16_k_screen_set_charset(3, (char *)0)
    // [75] main::cx16_k_screen_set_charset1_charset = 3 -- vbum1=vbuc1 
    lda #3
    sta cx16_k_screen_set_charset1_charset
    // [76] main::cx16_k_screen_set_charset1_offset = (char *) 0 -- pbum1=pbuc1 
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
    // [78] phi from main::cx16_k_screen_set_charset1 to main::@17 [phi:main::cx16_k_screen_set_charset1->main::@17]
    // main::@17
    // frame_init()
    // [79] call frame_init
    // [210] phi from main::@17 to frame_init [phi:main::@17->frame_init]
    jsr frame_init
    // [80] phi from main::@17 to main::@20 [phi:main::@17->main::@20]
    // main::@20
    // frame_draw()
    // [81] call frame_draw
    // [230] phi from main::@20 to frame_draw [phi:main::@20->frame_draw]
    jsr frame_draw
    // [82] phi from main::@20 to main::@21 [phi:main::@20->main::@21]
    // main::@21
    // info_title("Commander X16 Flash Utility!")
    // [83] call info_title
    // [271] phi from main::@21 to info_title [phi:main::@21->info_title]
    jsr info_title
    // [84] phi from main::@21 to main::@22 [phi:main::@21->main::@22]
    // main::@22
    // progress_clear()
    // [85] call progress_clear
    // [276] phi from main::@22 to progress_clear [phi:main::@22->progress_clear]
    jsr progress_clear
    // [86] phi from main::@22 to main::@23 [phi:main::@22->main::@23]
    // main::@23
    // info_clear_all()
    // [87] call info_clear_all
    // [291] phi from main::@23 to info_clear_all [phi:main::@23->info_clear_all]
    jsr info_clear_all
    // [88] phi from main::@23 to main::@24 [phi:main::@23->main::@24]
    // main::@24
    // info_line("Detecting SMC, VERA and ROM chipsets ...")
    // [89] call info_line
  // info_print(0, "The SMC chip on the X16 board controls the power on/off, keyboard and mouse pheripherals.");
  // info_print(1, "It is essential that the SMC chip gets updated together with the latest ROM on the X16 board.");
  // info_print(2, "On the X16 board, near the SMC chip are two jumpers");
    // [301] phi from main::@24 to info_line [phi:main::@24->info_line]
    // [301] phi info_line::info_text#13 = main::info_text1 [phi:main::@24->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z info_line.info_text
    lda #>info_text1
    sta.z info_line.info_text+1
    jsr info_line
    // [90] phi from main::@24 to main::@25 [phi:main::@24->main::@25]
    // main::@25
    // smc_detect()
    // [91] call smc_detect
    jsr smc_detect
    // [92] smc_detect::return#4 = smc_detect::return#1
    // main::@26
    // smc_bootloader = smc_detect()
    // [93] smc_bootloader#0 = smc_detect::return#4 -- vwum1=vwuz2 
    lda.z smc_detect.return
    sta smc_bootloader
    lda.z smc_detect.return+1
    sta smc_bootloader+1
    // if(smc_bootloader == 0x0100)
    // [94] if(smc_bootloader#0!=$100) goto main::@1 -- vwum1_neq_vwuc1_then_la1 
    cmp #>$100
    bne __b1
    lda smc_bootloader
    cmp #<$100
    bne __b1
    // [95] phi from main::@26 to main::@5 [phi:main::@26->main::@5]
    // main::@5
    // info_line("There is no SMC bootloader on this CX16 board. Press a key to exit ...")
    // [96] call info_line
  // TODO: explain next steps ...
    // [301] phi from main::@5 to info_line [phi:main::@5->info_line]
    // [301] phi info_line::info_text#13 = main::info_text2 [phi:main::@5->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z info_line.info_text
    lda #>info_text2
    sta.z info_line.info_text+1
    jsr info_line
    // [97] phi from main::@5 to main::@27 [phi:main::@5->main::@27]
    // main::@27
    // wait_key()
    // [98] call wait_key
    // [326] phi from main::@27 to wait_key [phi:main::@27->wait_key]
    jsr wait_key
    // main::@return
    // }
    // [99] return 
    rts
    // main::@1
  __b1:
    // if(smc_bootloader == 0x0200)
    // [100] if(smc_bootloader#0!=$200) goto main::@2 -- vwum1_neq_vwuc1_then_la1 
    lda smc_bootloader+1
    cmp #>$200
    bne __b2
    lda smc_bootloader
    cmp #<$200
    bne __b2
    // [101] phi from main::@1 to main::@6 [phi:main::@1->main::@6]
    // main::@6
    // info_line("The SMC chip seems to be unreachable! Press a key to exit ...")
    // [102] call info_line
  // TODO: explain next steps ...
    // [301] phi from main::@6 to info_line [phi:main::@6->info_line]
    // [301] phi info_line::info_text#13 = main::info_text3 [phi:main::@6->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text3
    sta.z info_line.info_text
    lda #>info_text3
    sta.z info_line.info_text+1
    jsr info_line
    // [103] phi from main::@6 to main::@28 [phi:main::@6->main::@28]
    // main::@28
    // wait_key()
    // [104] call wait_key
    // [326] phi from main::@28 to wait_key [phi:main::@28->wait_key]
    jsr wait_key
    rts
    // main::@2
  __b2:
    // if(smc_bootloader != 0x1)
    // [105] if(smc_bootloader#0==1) goto main::@3 -- vwum1_eq_vbuc1_then_la1 
    lda smc_bootloader+1
    bne !+
    lda smc_bootloader
    cmp #1
    beq __b3
  !:
    // [106] phi from main::@2 to main::@7 [phi:main::@2->main::@7]
    // main::@7
    // info_line("The current SMC bootloader version is not supported! Press a key to exit ...")
    // [107] call info_line
  // TODO: explain next steps ...
    // [301] phi from main::@7 to info_line [phi:main::@7->info_line]
    // [301] phi info_line::info_text#13 = main::info_text4 [phi:main::@7->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z info_line.info_text
    lda #>info_text4
    sta.z info_line.info_text+1
    jsr info_line
    // [108] phi from main::@7 to main::@34 [phi:main::@7->main::@34]
    // main::@34
    // wait_key()
    // [109] call wait_key
    // [326] phi from main::@34 to wait_key [phi:main::@34->wait_key]
    jsr wait_key
    rts
    // [110] phi from main::@2 to main::@3 [phi:main::@2->main::@3]
    // main::@3
  __b3:
    // rom_detect()
    // [111] call rom_detect
  // Detecting ROM chips
    // [337] phi from main::@3 to rom_detect [phi:main::@3->rom_detect]
    jsr rom_detect
    // [112] phi from main::@3 to main::@29 [phi:main::@3->main::@29]
    // main::@29
    // chip_smc()
    // [113] call chip_smc
    // [391] phi from main::@29 to chip_smc [phi:main::@29->chip_smc]
    jsr chip_smc
    // [114] phi from main::@29 to main::@30 [phi:main::@29->main::@30]
    // main::@30
    // chip_vera()
    // [115] call chip_vera
    // [396] phi from main::@30 to chip_vera [phi:main::@30->chip_vera]
    jsr chip_vera
    // [116] phi from main::@30 to main::@31 [phi:main::@30->main::@31]
    // main::@31
    // chip_rom()
    // [117] call chip_rom
    // [401] phi from main::@31 to chip_rom [phi:main::@31->chip_rom]
    jsr chip_rom
    // [118] phi from main::@31 to main::@32 [phi:main::@31->main::@32]
    // main::@32
    // info_smc(STATUS_DETECTED)
    // [119] call info_smc
    // [419] phi from main::@32 to info_smc [phi:main::@32->info_smc]
    // [419] phi info_smc::info_status#2 = 0 [phi:main::@32->info_smc#0] -- vbuz1=vbuc1 
    lda #0
    sta.z info_smc.info_status
    jsr info_smc
    // [120] phi from main::@32 to main::@33 [phi:main::@32->main::@33]
    // main::@33
    // info_vera(STATUS_DETECTED)
    // [121] call info_vera
    // Set the info for the SMC to Detected.
    jsr info_vera
    // [122] phi from main::@33 to main::@9 [phi:main::@33->main::@9]
    // [122] phi main::rom_chip#2 = 0 [phi:main::@33->main::@9#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip
  // Set the info for the VERA to Detected.
    // main::@9
  __b9:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [123] if(main::rom_chip#2<8) goto main::@10 -- vbuz1_lt_vbuc1_then_la1 
    lda.z rom_chip
    cmp #8
    bcs !__b10+
    jmp __b10
  !__b10:
    // main::bank_set_brom2
    // BROM = bank
    // [124] BROM = main::bank_set_brom2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom2_bank
    sta.z BROM
    // main::CLI1
    // asm
    // asm { cli  }
    cli
    // [126] phi from main::CLI1 to main::@18 [phi:main::CLI1->main::@18]
    // main::@18
    // info_smc(STATUS_CHECKING)
    // [127] call info_smc
    // [419] phi from main::@18 to info_smc [phi:main::@18->info_smc]
    // [419] phi info_smc::info_status#2 = 2 [phi:main::@18->info_smc#0] -- vbuz1=vbuc1 
    lda #2
    sta.z info_smc.info_status
    jsr info_smc
    // [128] phi from main::@18 to main::@35 [phi:main::@18->main::@35]
    // main::@35
    // info_line("Opening SMC flash file from SD card ...")
    // [129] call info_line
    // [301] phi from main::@35 to info_line [phi:main::@35->info_line]
    // [301] phi info_line::info_text#13 = main::info_text5 [phi:main::@35->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z info_line.info_text
    lda #>info_text5
    sta.z info_line.info_text+1
    jsr info_line
    // [130] phi from main::@35 to main::@36 [phi:main::@35->main::@36]
    // main::@36
    // wait_key()
    // [131] call wait_key
    // [326] phi from main::@36 to wait_key [phi:main::@36->wait_key]
    jsr wait_key
    // [132] phi from main::@36 to main::@37 [phi:main::@36->main::@37]
    // main::@37
    // strcpy(file, "SMC.BIN")
    // [133] call strcpy
    // [445] phi from main::@37 to strcpy [phi:main::@37->strcpy]
    // [445] phi strcpy::dst#0 = file [phi:main::@37->strcpy#0] -- pbuz1=pbuc1 
    lda #<file
    sta.z strcpy.dst
    lda #>file
    sta.z strcpy.dst+1
    // [445] phi strcpy::src#0 = main::source [phi:main::@37->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // [134] phi from main::@37 to main::@38 [phi:main::@37->main::@38]
    // main::@38
    // FILE *fp = fopen(file,"r")
    // [135] call fopen
    // Read the smc file content.
    jsr fopen
    // [136] fopen::return#3 = fopen::return#2
    // main::@39
    // [137] main::fp#0 = fopen::return#3 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [138] if((struct $2 *)0!=main::fp#0) goto main::@4 -- pssc1_neq_pssz1_then_la1 
    cmp #>0
    bne __b4
    lda.z fp
    cmp #<0
    bne __b4
    // [139] phi from main::@39 to main::@14 [phi:main::@39->main::@14]
    // main::@14
    // info_line("There is no SMC flash file smc.bin on the SD card. press a key to exit ...")
    // [140] call info_line
    // [301] phi from main::@14 to info_line [phi:main::@14->info_line]
    // [301] phi info_line::info_text#13 = main::info_text7 [phi:main::@14->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z info_line.info_text
    lda #>info_text7
    sta.z info_line.info_text+1
    jsr info_line
    // main::bank_set_brom3
  bank_set_brom3:
    // BROM = bank
    // [141] BROM = main::bank_set_brom3_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom3_bank
    sta.z BROM
    // main::CLI2
    // asm
    // asm { cli  }
    cli
    // [143] phi from main::CLI2 to main::@19 [phi:main::CLI2->main::@19]
    // main::@19
    // wait_key()
    // [144] call wait_key
    // [326] phi from main::@19 to wait_key [phi:main::@19->wait_key]
    jsr wait_key
    // [145] phi from main::@19 to main::@42 [phi:main::@19->main::@42]
    // main::@42
    // system_reset()
    // [146] call system_reset
    // [532] phi from main::@42 to system_reset [phi:main::@42->system_reset]
    jsr system_reset
    rts
    // [147] phi from main::@39 to main::@4 [phi:main::@39->main::@4]
    // main::@4
  __b4:
    // info_line("Reading SMC flash file smc.bin into CX16 RAM ...")
    // [148] call info_line
    // [301] phi from main::@4 to info_line [phi:main::@4->info_line]
    // [301] phi info_line::info_text#13 = main::info_text6 [phi:main::@4->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text6
    sta.z info_line.info_text
    lda #>info_text6
    sta.z info_line.info_text+1
    jsr info_line
    // main::@40
    // flash_read(PROGRESS_X, PROGRESS_Y, PROGRESS_W, 8, 512, fp, (ram_ptr_t)0x4000)
    // [149] flash_read::fp#0 = main::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z flash_read.fp
    lda.z fp+1
    sta.z flash_read.fp+1
    // [150] call flash_read
    // [537] phi from main::@40 to flash_read [phi:main::@40->flash_read]
    jsr flash_read
    // flash_read(PROGRESS_X, PROGRESS_Y, PROGRESS_W, 8, 512, fp, (ram_ptr_t)0x4000)
    // [151] flash_read::return#2 = flash_read::flash_bytes#2
    // main::@41
    // [152] main::$46 = flash_read::return#2
    // unsigned int flash_bytes = (unsigned int)flash_read(PROGRESS_X, PROGRESS_Y, PROGRESS_W, 8, 512, fp, (ram_ptr_t)0x4000)
    // [153] main::flash_bytes#0 = (unsigned int)main::$46 -- vwuz1=_word_vduz2 
    lda.z main__46
    sta.z flash_bytes
    lda.z main__46+1
    sta.z flash_bytes+1
    // if (flash_bytes == 0)
    // [154] if(main::flash_bytes#0!=0) goto main::@15 -- vwuz1_neq_0_then_la1 
    lda.z flash_bytes
    ora.z flash_bytes+1
    bne __b15
    // [155] phi from main::@41 to main::@8 [phi:main::@41->main::@8]
    // main::@8
    // printf("error reading file.")
    // [156] call printf_str
    // [560] phi from main::@8 to printf_str [phi:main::@8->printf_str]
    // [560] phi printf_str::putc#28 = &cputc [phi:main::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [560] phi printf_str::s#28 = main::s [phi:main::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    rts
    // main::@15
  __b15:
    // fclose(fp)
    // [157] fclose::stream#0 = main::fp#0
    // [158] call fclose
    jsr fclose
    // main::@43
    // unsigned long flashed_bytes = flash_smc(PROGRESS_X, PROGRESS_Y, PROGRESS_W, flash_bytes, 8, 512, (ram_ptr_t)0x4000)
    // [159] flash_smc::smc_bytes_total#0 = main::flash_bytes#0
    // [160] call flash_smc
    // SEI();
    jsr flash_smc
    jmp bank_set_brom3
    // main::@10
  __b10:
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [161] if(rom_device_ids[main::rom_chip#2]!=$55) goto main::@11 -- pbuc1_derefidx_vbuz1_neq_vbuc2_then_la1 
    lda #$55
    ldy.z rom_chip
    cmp rom_device_ids,y
    bne __b11
    // main::@13
    // info_rom(rom_chip, STATUS_NONE)
    // [162] info_rom::info_rom#1 = main::rom_chip#2 -- vbuz1=vbuz2 
    tya
    sta.z info_rom.info_rom
    // [163] call info_rom
    // [760] phi from main::@13 to info_rom [phi:main::@13->info_rom]
    // [760] phi info_rom::info_status#10 = 1 [phi:main::@13->info_rom#0] -- vbuz1=vbuc1 
    lda #1
    sta.z info_rom.info_status
    // [760] phi info_rom::info_rom#10 = info_rom::info_rom#1 [phi:main::@13->info_rom#1] -- register_copy 
    jsr info_rom
    // main::@12
  __b12:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [164] main::rom_chip#1 = ++ main::rom_chip#2 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip
    // [122] phi from main::@12 to main::@9 [phi:main::@12->main::@9]
    // [122] phi main::rom_chip#2 = main::rom_chip#1 [phi:main::@12->main::@9#0] -- register_copy 
    jmp __b9
    // main::@11
  __b11:
    // info_rom(rom_chip, STATUS_DETECTED)
    // [165] info_rom::info_rom#0 = main::rom_chip#2 -- vbuz1=vbuz2 
    lda.z rom_chip
    sta.z info_rom.info_rom
    // [166] call info_rom
    // [760] phi from main::@11 to info_rom [phi:main::@11->info_rom]
    // [760] phi info_rom::info_status#10 = 0 [phi:main::@11->info_rom#0] -- vbuz1=vbuc1 
    lda #0
    sta.z info_rom.info_status
    // [760] phi info_rom::info_rom#10 = info_rom::info_rom#0 [phi:main::@11->info_rom#1] -- register_copy 
    jsr info_rom
    jmp __b12
  .segment Data
    info_text: .text "Commander X16 Flash Utility!"
    .byte 0
    info_text1: .text "Detecting SMC, VERA and ROM chipsets ..."
    .byte 0
    info_text2: .text "There is no SMC bootloader on this CX16 board. Press a key to exit ..."
    .byte 0
    info_text3: .text "The SMC chip seems to be unreachable! Press a key to exit ..."
    .byte 0
    info_text4: .text "The current SMC bootloader version is not supported! Press a key to exit ..."
    .byte 0
    info_text5: .text "Opening SMC flash file from SD card ..."
    .byte 0
    source: .text "SMC.BIN"
    .byte 0
    info_text6: .text "Reading SMC flash file smc.bin into CX16 RAM ..."
    .byte 0
    info_text7: .text "There is no SMC flash file smc.bin on the SD card. press a key to exit ..."
    .byte 0
    s: .text "error reading file."
    .byte 0
    cx16_k_screen_set_charset1_charset: .byte 0
    cx16_k_screen_set_charset1_offset: .word 0
}
.segment Code
  // screenlayer1
// Set the layer with which the conio will interact.
screenlayer1: {
    // screenlayer(1, *VERA_L1_MAPBASE, *VERA_L1_CONFIG)
    // [167] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbuz1=_deref_pbuc1 
    lda VERA_L1_MAPBASE
    sta.z screenlayer.mapbase
    // [168] screenlayer::config#0 = *VERA_L1_CONFIG -- vbuz1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta.z screenlayer.config
    // [169] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [170] return 
    rts
}
  // textcolor
// Set the front color for text output. The old front text color setting is returned.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char textcolor(__zp($68) char color)
textcolor: {
    .label textcolor__0 = $6f
    .label textcolor__1 = $68
    .label color = $68
    // __conio.color & 0xF0
    // [172] textcolor::$0 = *((char *)&__conio+$d) & $f0 -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$d
    sta.z textcolor__0
    // __conio.color & 0xF0 | color
    // [173] textcolor::$1 = textcolor::$0 | textcolor::color#16 -- vbuz1=vbuz2_bor_vbuz1 
    lda.z textcolor__1
    ora.z textcolor__0
    sta.z textcolor__1
    // __conio.color = __conio.color & 0xF0 | color
    // [174] *((char *)&__conio+$d) = textcolor::$1 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // textcolor::@return
    // }
    // [175] return 
    rts
}
  // bgcolor
// Set the back color for text output.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char bgcolor(__zp($68) char color)
bgcolor: {
    .label bgcolor__0 = $6c
    .label bgcolor__1 = $68
    .label bgcolor__2 = $6c
    .label color = $68
    // __conio.color & 0x0F
    // [177] bgcolor::$0 = *((char *)&__conio+$d) & $f -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$d
    sta.z bgcolor__0
    // color << 4
    // [178] bgcolor::$1 = bgcolor::color#14 << 4 -- vbuz1=vbuz1_rol_4 
    lda.z bgcolor__1
    asl
    asl
    asl
    asl
    sta.z bgcolor__1
    // __conio.color & 0x0F | color << 4
    // [179] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbuz1=vbuz1_bor_vbuz2 
    lda.z bgcolor__2
    ora.z bgcolor__1
    sta.z bgcolor__2
    // __conio.color = __conio.color & 0x0F | color << 4
    // [180] *((char *)&__conio+$d) = bgcolor::$2 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // bgcolor::@return
    // }
    // [181] return 
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
    // [182] *((char *)&__conio+$c) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$c
    // cursor::@return
    // }
    // [183] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    .label return = $cc
    // __mem unsigned char x
    // [184] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [185] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [187] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwuz1=vbum2_word_vbum3 
    lda x
    sta.z return+1
    lda y
    sta.z return
    // cbm_k_plot_get::@return
    // }
    // [188] return 
    rts
  .segment Data
    x: .byte 0
    y: .byte 0
}
.segment Code
  // gotoxy
// Set the cursor to the specified position
// void gotoxy(__zp($38) char x, __zp($3a) char y)
gotoxy: {
    .label gotoxy__2 = $38
    .label gotoxy__3 = $38
    .label gotoxy__6 = $37
    .label gotoxy__7 = $37
    .label gotoxy__8 = $3e
    .label gotoxy__9 = $3c
    .label gotoxy__10 = $3a
    .label x = $38
    .label y = $3a
    .label gotoxy__14 = $37
    // (x>=__conio.width)?__conio.width:x
    // [190] if(gotoxy::x#18>=*((char *)&__conio+6)) goto gotoxy::@1 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z x
    cmp __conio+6
    bcs __b1
    // [192] phi from gotoxy gotoxy::@1 to gotoxy::@2 [phi:gotoxy/gotoxy::@1->gotoxy::@2]
    // [192] phi gotoxy::$3 = gotoxy::x#18 [phi:gotoxy/gotoxy::@1->gotoxy::@2#0] -- register_copy 
    jmp __b2
    // gotoxy::@1
  __b1:
    // [191] gotoxy::$2 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z gotoxy__2
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [193] *((char *)&__conio) = gotoxy::$3 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__3
    sta __conio
    // (y>=__conio.height)?__conio.height:y
    // [194] if(gotoxy::y#18>=*((char *)&__conio+7)) goto gotoxy::@3 -- vbuz1_ge__deref_pbuc1_then_la1 
    lda.z y
    cmp __conio+7
    bcs __b3
    // gotoxy::@4
    // [195] gotoxy::$14 = gotoxy::y#18 -- vbuz1=vbuz2 
    sta.z gotoxy__14
    // [196] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [196] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [197] *((char *)&__conio+1) = gotoxy::$7 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__7
    sta __conio+1
    // __conio.cursor_x << 1
    // [198] gotoxy::$8 = *((char *)&__conio) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio
    asl
    sta.z gotoxy__8
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [199] gotoxy::$10 = gotoxy::y#18 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z gotoxy__10
    // [200] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwuz1=pwuc1_derefidx_vbuz2_plus_vbuz3 
    ldy.z gotoxy__10
    clc
    adc __conio+$15,y
    sta.z gotoxy__9
    lda __conio+$15+1,y
    adc #0
    sta.z gotoxy__9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [201] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwuz1 
    lda.z gotoxy__9
    sta __conio+$13
    lda.z gotoxy__9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [202] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [203] gotoxy::$6 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
    lda __conio+7
    sta.z gotoxy__6
    jmp __b5
}
  // cputln
// Print a newline
cputln: {
    .label cputln__2 = $4a
    // __conio.cursor_x = 0
    // [204] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y++;
    // [205] *((char *)&__conio+1) = ++ *((char *)&__conio+1) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+1
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [206] cputln::$2 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z cputln__2
    // [207] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [208] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [209] return 
    rts
}
  // frame_init
frame_init: {
    .const vera_display_set_hstart1_start = $b
    .const vera_display_set_hstop1_stop = $93
    .const vera_display_set_vstart1_start = $13
    .const vera_display_set_vstop1_stop = $db
    .label cx16_k_screen_set_charset1_offset = $f9
    // textcolor(WHITE)
    // [211] call textcolor
  // Set the charset to lower case.
  // screenlayer1();
    // [171] phi from frame_init to textcolor [phi:frame_init->textcolor]
    // [171] phi textcolor::color#16 = WHITE [phi:frame_init->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [212] phi from frame_init to frame_init::@2 [phi:frame_init->frame_init::@2]
    // frame_init::@2
    // bgcolor(BLUE)
    // [213] call bgcolor
    // [176] phi from frame_init::@2 to bgcolor [phi:frame_init::@2->bgcolor]
    // [176] phi bgcolor::color#14 = BLUE [phi:frame_init::@2->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [214] phi from frame_init::@2 to frame_init::@3 [phi:frame_init::@2->frame_init::@3]
    // frame_init::@3
    // scroll(0)
    // [215] call scroll
    jsr scroll
    // [216] phi from frame_init::@3 to frame_init::@4 [phi:frame_init::@3->frame_init::@4]
    // frame_init::@4
    // clrscr()
    // [217] call clrscr
    jsr clrscr
    // frame_init::vera_display_set_hstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [218] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTART = start
    // [219] *VERA_DC_HSTART = frame_init::vera_display_set_hstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstart1_start
    sta VERA_DC_HSTART
    // frame_init::vera_display_set_hstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [220] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTOP = stop
    // [221] *VERA_DC_HSTOP = frame_init::vera_display_set_hstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstop1_stop
    sta VERA_DC_HSTOP
    // frame_init::vera_display_set_vstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [222] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTART = start
    // [223] *VERA_DC_VSTART = frame_init::vera_display_set_vstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstart1_start
    sta VERA_DC_VSTART
    // frame_init::vera_display_set_vstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [224] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTOP = stop
    // [225] *VERA_DC_VSTOP = frame_init::vera_display_set_vstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstop1_stop
    sta VERA_DC_VSTOP
    // frame_init::@1
    // cx16_k_screen_set_charset(3, (char *)0)
    // [226] frame_init::cx16_k_screen_set_charset1_charset = 3 -- vbum1=vbuc1 
    lda #3
    sta cx16_k_screen_set_charset1_charset
    // [227] frame_init::cx16_k_screen_set_charset1_offset = (char *) 0 -- pbuz1=pbuc1 
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
    // [229] return 
    rts
  .segment Data
    cx16_k_screen_set_charset1_charset: .byte 0
}
.segment Code
  // frame_draw
frame_draw: {
    // textcolor(WHITE)
    // [231] call textcolor
    // [171] phi from frame_draw to textcolor [phi:frame_draw->textcolor]
    // [171] phi textcolor::color#16 = WHITE [phi:frame_draw->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [232] phi from frame_draw to frame_draw::@1 [phi:frame_draw->frame_draw::@1]
    // frame_draw::@1
    // bgcolor(BLUE)
    // [233] call bgcolor
    // [176] phi from frame_draw::@1 to bgcolor [phi:frame_draw::@1->bgcolor]
    // [176] phi bgcolor::color#14 = BLUE [phi:frame_draw::@1->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [234] phi from frame_draw::@1 to frame_draw::@2 [phi:frame_draw::@1->frame_draw::@2]
    // frame_draw::@2
    // clrscr()
    // [235] call clrscr
    jsr clrscr
    // [236] phi from frame_draw::@2 to frame_draw::@3 [phi:frame_draw::@2->frame_draw::@3]
    // frame_draw::@3
    // frame(0, 0, 67, 15)
    // [237] call frame
    // [883] phi from frame_draw::@3 to frame [phi:frame_draw::@3->frame]
    // [883] phi frame::y#0 = 0 [phi:frame_draw::@3->frame#0] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.y
    // [883] phi frame::y1#16 = $f [phi:frame_draw::@3->frame#1] -- vbuz1=vbuc1 
    lda #$f
    sta.z frame.y1
    // [883] phi frame::x#0 = 0 [phi:frame_draw::@3->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [883] phi frame::x1#16 = $43 [phi:frame_draw::@3->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [238] phi from frame_draw::@3 to frame_draw::@4 [phi:frame_draw::@3->frame_draw::@4]
    // frame_draw::@4
    // frame(0, 0, 67, 2)
    // [239] call frame
    // [883] phi from frame_draw::@4 to frame [phi:frame_draw::@4->frame]
    // [883] phi frame::y#0 = 0 [phi:frame_draw::@4->frame#0] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.y
    // [883] phi frame::y1#16 = 2 [phi:frame_draw::@4->frame#1] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y1
    // [883] phi frame::x#0 = 0 [phi:frame_draw::@4->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [883] phi frame::x1#16 = $43 [phi:frame_draw::@4->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [240] phi from frame_draw::@4 to frame_draw::@5 [phi:frame_draw::@4->frame_draw::@5]
    // frame_draw::@5
    // frame(0, 2, 67, 13)
    // [241] call frame
    // [883] phi from frame_draw::@5 to frame [phi:frame_draw::@5->frame]
    // [883] phi frame::y#0 = 2 [phi:frame_draw::@5->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [883] phi frame::y1#16 = $d [phi:frame_draw::@5->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [883] phi frame::x#0 = 0 [phi:frame_draw::@5->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [883] phi frame::x1#16 = $43 [phi:frame_draw::@5->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [242] phi from frame_draw::@5 to frame_draw::@6 [phi:frame_draw::@5->frame_draw::@6]
    // frame_draw::@6
    // frame(0, 13, 67, 15)
    // [243] call frame
    // [883] phi from frame_draw::@6 to frame [phi:frame_draw::@6->frame]
    // [883] phi frame::y#0 = $d [phi:frame_draw::@6->frame#0] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y
    // [883] phi frame::y1#16 = $f [phi:frame_draw::@6->frame#1] -- vbuz1=vbuc1 
    lda #$f
    sta.z frame.y1
    // [883] phi frame::x#0 = 0 [phi:frame_draw::@6->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [883] phi frame::x1#16 = $43 [phi:frame_draw::@6->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [244] phi from frame_draw::@6 to frame_draw::@7 [phi:frame_draw::@6->frame_draw::@7]
    // frame_draw::@7
    // frame(0, 2, 8, 13)
    // [245] call frame
    // [883] phi from frame_draw::@7 to frame [phi:frame_draw::@7->frame]
    // [883] phi frame::y#0 = 2 [phi:frame_draw::@7->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [883] phi frame::y1#16 = $d [phi:frame_draw::@7->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [883] phi frame::x#0 = 0 [phi:frame_draw::@7->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [883] phi frame::x1#16 = 8 [phi:frame_draw::@7->frame#3] -- vbuz1=vbuc1 
    lda #8
    sta.z frame.x1
    jsr frame
    // [246] phi from frame_draw::@7 to frame_draw::@8 [phi:frame_draw::@7->frame_draw::@8]
    // frame_draw::@8
    // frame(8, 2, 19, 13)
    // [247] call frame
    // [883] phi from frame_draw::@8 to frame [phi:frame_draw::@8->frame]
    // [883] phi frame::y#0 = 2 [phi:frame_draw::@8->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [883] phi frame::y1#16 = $d [phi:frame_draw::@8->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [883] phi frame::x#0 = 8 [phi:frame_draw::@8->frame#2] -- vbuz1=vbuc1 
    lda #8
    sta.z frame.x
    // [883] phi frame::x1#16 = $13 [phi:frame_draw::@8->frame#3] -- vbuz1=vbuc1 
    lda #$13
    sta.z frame.x1
    jsr frame
    // [248] phi from frame_draw::@8 to frame_draw::@9 [phi:frame_draw::@8->frame_draw::@9]
    // frame_draw::@9
    // frame(19, 2, 25, 13)
    // [249] call frame
    // [883] phi from frame_draw::@9 to frame [phi:frame_draw::@9->frame]
    // [883] phi frame::y#0 = 2 [phi:frame_draw::@9->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [883] phi frame::y1#16 = $d [phi:frame_draw::@9->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [883] phi frame::x#0 = $13 [phi:frame_draw::@9->frame#2] -- vbuz1=vbuc1 
    lda #$13
    sta.z frame.x
    // [883] phi frame::x1#16 = $19 [phi:frame_draw::@9->frame#3] -- vbuz1=vbuc1 
    lda #$19
    sta.z frame.x1
    jsr frame
    // [250] phi from frame_draw::@9 to frame_draw::@10 [phi:frame_draw::@9->frame_draw::@10]
    // frame_draw::@10
    // frame(25, 2, 31, 13)
    // [251] call frame
    // [883] phi from frame_draw::@10 to frame [phi:frame_draw::@10->frame]
    // [883] phi frame::y#0 = 2 [phi:frame_draw::@10->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [883] phi frame::y1#16 = $d [phi:frame_draw::@10->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [883] phi frame::x#0 = $19 [phi:frame_draw::@10->frame#2] -- vbuz1=vbuc1 
    lda #$19
    sta.z frame.x
    // [883] phi frame::x1#16 = $1f [phi:frame_draw::@10->frame#3] -- vbuz1=vbuc1 
    lda #$1f
    sta.z frame.x1
    jsr frame
    // [252] phi from frame_draw::@10 to frame_draw::@11 [phi:frame_draw::@10->frame_draw::@11]
    // frame_draw::@11
    // frame(31, 2, 37, 13)
    // [253] call frame
    // [883] phi from frame_draw::@11 to frame [phi:frame_draw::@11->frame]
    // [883] phi frame::y#0 = 2 [phi:frame_draw::@11->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [883] phi frame::y1#16 = $d [phi:frame_draw::@11->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [883] phi frame::x#0 = $1f [phi:frame_draw::@11->frame#2] -- vbuz1=vbuc1 
    lda #$1f
    sta.z frame.x
    // [883] phi frame::x1#16 = $25 [phi:frame_draw::@11->frame#3] -- vbuz1=vbuc1 
    lda #$25
    sta.z frame.x1
    jsr frame
    // [254] phi from frame_draw::@11 to frame_draw::@12 [phi:frame_draw::@11->frame_draw::@12]
    // frame_draw::@12
    // frame(37, 2, 43, 13)
    // [255] call frame
    // [883] phi from frame_draw::@12 to frame [phi:frame_draw::@12->frame]
    // [883] phi frame::y#0 = 2 [phi:frame_draw::@12->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [883] phi frame::y1#16 = $d [phi:frame_draw::@12->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [883] phi frame::x#0 = $25 [phi:frame_draw::@12->frame#2] -- vbuz1=vbuc1 
    lda #$25
    sta.z frame.x
    // [883] phi frame::x1#16 = $2b [phi:frame_draw::@12->frame#3] -- vbuz1=vbuc1 
    lda #$2b
    sta.z frame.x1
    jsr frame
    // [256] phi from frame_draw::@12 to frame_draw::@13 [phi:frame_draw::@12->frame_draw::@13]
    // frame_draw::@13
    // frame(43, 2, 49, 13)
    // [257] call frame
    // [883] phi from frame_draw::@13 to frame [phi:frame_draw::@13->frame]
    // [883] phi frame::y#0 = 2 [phi:frame_draw::@13->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [883] phi frame::y1#16 = $d [phi:frame_draw::@13->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [883] phi frame::x#0 = $2b [phi:frame_draw::@13->frame#2] -- vbuz1=vbuc1 
    lda #$2b
    sta.z frame.x
    // [883] phi frame::x1#16 = $31 [phi:frame_draw::@13->frame#3] -- vbuz1=vbuc1 
    lda #$31
    sta.z frame.x1
    jsr frame
    // [258] phi from frame_draw::@13 to frame_draw::@14 [phi:frame_draw::@13->frame_draw::@14]
    // frame_draw::@14
    // frame(49, 2, 55, 13)
    // [259] call frame
    // [883] phi from frame_draw::@14 to frame [phi:frame_draw::@14->frame]
    // [883] phi frame::y#0 = 2 [phi:frame_draw::@14->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [883] phi frame::y1#16 = $d [phi:frame_draw::@14->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [883] phi frame::x#0 = $31 [phi:frame_draw::@14->frame#2] -- vbuz1=vbuc1 
    lda #$31
    sta.z frame.x
    // [883] phi frame::x1#16 = $37 [phi:frame_draw::@14->frame#3] -- vbuz1=vbuc1 
    lda #$37
    sta.z frame.x1
    jsr frame
    // [260] phi from frame_draw::@14 to frame_draw::@15 [phi:frame_draw::@14->frame_draw::@15]
    // frame_draw::@15
    // frame(55, 2, 61, 13)
    // [261] call frame
    // [883] phi from frame_draw::@15 to frame [phi:frame_draw::@15->frame]
    // [883] phi frame::y#0 = 2 [phi:frame_draw::@15->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [883] phi frame::y1#16 = $d [phi:frame_draw::@15->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [883] phi frame::x#0 = $37 [phi:frame_draw::@15->frame#2] -- vbuz1=vbuc1 
    lda #$37
    sta.z frame.x
    // [883] phi frame::x1#16 = $3d [phi:frame_draw::@15->frame#3] -- vbuz1=vbuc1 
    lda #$3d
    sta.z frame.x1
    jsr frame
    // [262] phi from frame_draw::@15 to frame_draw::@16 [phi:frame_draw::@15->frame_draw::@16]
    // frame_draw::@16
    // frame(61, 2, 67, 13)
    // [263] call frame
    // [883] phi from frame_draw::@16 to frame [phi:frame_draw::@16->frame]
    // [883] phi frame::y#0 = 2 [phi:frame_draw::@16->frame#0] -- vbuz1=vbuc1 
    lda #2
    sta.z frame.y
    // [883] phi frame::y1#16 = $d [phi:frame_draw::@16->frame#1] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y1
    // [883] phi frame::x#0 = $3d [phi:frame_draw::@16->frame#2] -- vbuz1=vbuc1 
    lda #$3d
    sta.z frame.x
    // [883] phi frame::x1#16 = $43 [phi:frame_draw::@16->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [264] phi from frame_draw::@16 to frame_draw::@17 [phi:frame_draw::@16->frame_draw::@17]
    // frame_draw::@17
    // frame(0, 13, 67, 29)
    // [265] call frame
    // [883] phi from frame_draw::@17 to frame [phi:frame_draw::@17->frame]
    // [883] phi frame::y#0 = $d [phi:frame_draw::@17->frame#0] -- vbuz1=vbuc1 
    lda #$d
    sta.z frame.y
    // [883] phi frame::y1#16 = $1d [phi:frame_draw::@17->frame#1] -- vbuz1=vbuc1 
    lda #$1d
    sta.z frame.y1
    // [883] phi frame::x#0 = 0 [phi:frame_draw::@17->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [883] phi frame::x1#16 = $43 [phi:frame_draw::@17->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [266] phi from frame_draw::@17 to frame_draw::@18 [phi:frame_draw::@17->frame_draw::@18]
    // frame_draw::@18
    // frame(0, 29, 67, 49)
    // [267] call frame
    // [883] phi from frame_draw::@18 to frame [phi:frame_draw::@18->frame]
    // [883] phi frame::y#0 = $1d [phi:frame_draw::@18->frame#0] -- vbuz1=vbuc1 
    lda #$1d
    sta.z frame.y
    // [883] phi frame::y1#16 = $31 [phi:frame_draw::@18->frame#1] -- vbuz1=vbuc1 
    lda #$31
    sta.z frame.y1
    // [883] phi frame::x#0 = 0 [phi:frame_draw::@18->frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z frame.x
    // [883] phi frame::x1#16 = $43 [phi:frame_draw::@18->frame#3] -- vbuz1=vbuc1 
    lda #$43
    sta.z frame.x1
    jsr frame
    // [268] phi from frame_draw::@18 to frame_draw::@19 [phi:frame_draw::@18->frame_draw::@19]
    // frame_draw::@19
    // cputsxy(2, 14, "status")
    // [269] call cputsxy
  // cputsxy(2, 3, "led colors");
  // cputsxy(2, 5, "    no chip"); print_chip_led(2, 5, DARK_GREY, BLUE);
  // cputsxy(2, 6, "    update"); print_chip_led(2, 6, CYAN, BLUE);
  // cputsxy(2, 7, "    ok"); print_chip_led(2, 7, WHITE, BLUE);
  // cputsxy(2, 8, "    todo"); print_chip_led(2, 8, PURPLE, BLUE);
  // cputsxy(2, 9, "    error"); print_chip_led(2, 9, RED, BLUE);
  // cputsxy(2, 10, "    no file"); print_chip_led(2, 10, GREY, BLUE);
    // [1017] phi from frame_draw::@19 to cputsxy [phi:frame_draw::@19->cputsxy]
    jsr cputsxy
    // frame_draw::@return
    // }
    // [270] return 
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
    // [272] call gotoxy
    // [189] phi from info_title to gotoxy [phi:info_title->gotoxy]
    // [189] phi gotoxy::y#18 = 1 [phi:info_title->gotoxy#0] -- vbuz1=vbuc1 
    lda #1
    sta.z gotoxy.y
    // [189] phi gotoxy::x#18 = 2 [phi:info_title->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // [273] phi from info_title to info_title::@1 [phi:info_title->info_title::@1]
    // info_title::@1
    // printf("%-60s", info_text)
    // [274] call printf_string
    // [1022] phi from info_title::@1 to printf_string [phi:info_title::@1->printf_string]
    // [1022] phi printf_string::str#10 = main::info_text [phi:info_title::@1->printf_string#0] -- pbuz1=pbuc1 
    lda #<main.info_text
    sta.z printf_string.str
    lda #>main.info_text
    sta.z printf_string.str+1
    // [1022] phi printf_string::format_justify_left#10 = 1 [phi:info_title::@1->printf_string#1] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1022] phi printf_string::format_min_length#10 = $3c [phi:info_title::@1->printf_string#2] -- vbuz1=vbuc1 
    lda #$3c
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_title::@return
    // }
    // [275] return 
    rts
}
  // progress_clear
/**
 * @brief Clean the progress area for the flashing.
 */
progress_clear: {
    .const h = $1f+$10
    .const w = $40
    .label x = $c6
    .label i = $56
    .label y = $76
    // textcolor(WHITE)
    // [277] call textcolor
    // [171] phi from progress_clear to textcolor [phi:progress_clear->textcolor]
    // [171] phi textcolor::color#16 = WHITE [phi:progress_clear->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [278] phi from progress_clear to progress_clear::@5 [phi:progress_clear->progress_clear::@5]
    // progress_clear::@5
    // bgcolor(BLUE)
    // [279] call bgcolor
    // [176] phi from progress_clear::@5 to bgcolor [phi:progress_clear::@5->bgcolor]
    // [176] phi bgcolor::color#14 = BLUE [phi:progress_clear::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [280] phi from progress_clear::@5 to progress_clear::@1 [phi:progress_clear::@5->progress_clear::@1]
    // [280] phi progress_clear::y#2 = $1f [phi:progress_clear::@5->progress_clear::@1#0] -- vbuz1=vbuc1 
    lda #$1f
    sta.z y
    // progress_clear::@1
  __b1:
    // while (y < h)
    // [281] if(progress_clear::y#2<progress_clear::h) goto progress_clear::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y
    cmp #h
    bcc __b4
    // progress_clear::@return
    // }
    // [282] return 
    rts
    // [283] phi from progress_clear::@1 to progress_clear::@2 [phi:progress_clear::@1->progress_clear::@2]
  __b4:
    // [283] phi progress_clear::x#2 = 2 [phi:progress_clear::@1->progress_clear::@2#0] -- vbuz1=vbuc1 
    lda #2
    sta.z x
    // [283] phi progress_clear::i#2 = 0 [phi:progress_clear::@1->progress_clear::@2#1] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // progress_clear::@2
  __b2:
    // for(unsigned char i = 0; i < w; i++)
    // [284] if(progress_clear::i#2<progress_clear::w) goto progress_clear::@3 -- vbuz1_lt_vbuc1_then_la1 
    lda.z i
    cmp #w
    bcc __b3
    // progress_clear::@4
    // y++;
    // [285] progress_clear::y#1 = ++ progress_clear::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [280] phi from progress_clear::@4 to progress_clear::@1 [phi:progress_clear::@4->progress_clear::@1]
    // [280] phi progress_clear::y#2 = progress_clear::y#1 [phi:progress_clear::@4->progress_clear::@1#0] -- register_copy 
    jmp __b1
    // progress_clear::@3
  __b3:
    // cputcxy(x, y, '.')
    // [286] cputcxy::x#9 = progress_clear::x#2 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [287] cputcxy::y#9 = progress_clear::y#2 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [288] call cputcxy
    // [1044] phi from progress_clear::@3 to cputcxy [phi:progress_clear::@3->cputcxy]
    // [1044] phi cputcxy::c#11 = '.' [phi:progress_clear::@3->cputcxy#0] -- vbuz1=vbuc1 
    lda #'.'
    sta.z cputcxy.c
    // [1044] phi cputcxy::y#11 = cputcxy::y#9 [phi:progress_clear::@3->cputcxy#1] -- register_copy 
    // [1044] phi cputcxy::x#11 = cputcxy::x#9 [phi:progress_clear::@3->cputcxy#2] -- register_copy 
    jsr cputcxy
    // progress_clear::@6
    // x++;
    // [289] progress_clear::x#1 = ++ progress_clear::x#2 -- vbuz1=_inc_vbuz1 
    inc.z x
    // for(unsigned char i = 0; i < w; i++)
    // [290] progress_clear::i#1 = ++ progress_clear::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [283] phi from progress_clear::@6 to progress_clear::@2 [phi:progress_clear::@6->progress_clear::@2]
    // [283] phi progress_clear::x#2 = progress_clear::x#1 [phi:progress_clear::@6->progress_clear::@2#0] -- register_copy 
    // [283] phi progress_clear::i#2 = progress_clear::i#1 [phi:progress_clear::@6->progress_clear::@2#1] -- register_copy 
    jmp __b2
}
  // info_clear_all
/**
 * @brief Clean the information area.
 * 
 */
info_clear_all: {
    .label l = $dd
    // textcolor(WHITE)
    // [292] call textcolor
    // [171] phi from info_clear_all to textcolor [phi:info_clear_all->textcolor]
    // [171] phi textcolor::color#16 = WHITE [phi:info_clear_all->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [293] phi from info_clear_all to info_clear_all::@3 [phi:info_clear_all->info_clear_all::@3]
    // info_clear_all::@3
    // bgcolor(BLUE)
    // [294] call bgcolor
    // [176] phi from info_clear_all::@3 to bgcolor [phi:info_clear_all::@3->bgcolor]
    // [176] phi bgcolor::color#14 = BLUE [phi:info_clear_all::@3->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [295] phi from info_clear_all::@3 to info_clear_all::@1 [phi:info_clear_all::@3->info_clear_all::@1]
    // [295] phi info_clear_all::l#2 = 0 [phi:info_clear_all::@3->info_clear_all::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z l
    // info_clear_all::@1
  __b1:
    // while (l < INFO_H)
    // [296] if(info_clear_all::l#2<$a) goto info_clear_all::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z l
    cmp #$a
    bcc __b2
    // info_clear_all::@return
    // }
    // [297] return 
    rts
    // info_clear_all::@2
  __b2:
    // info_clear(l)
    // [298] info_clear::l#0 = info_clear_all::l#2 -- vbuz1=vbuz2 
    lda.z l
    sta.z info_clear.l
    // [299] call info_clear
    // [1052] phi from info_clear_all::@2 to info_clear [phi:info_clear_all::@2->info_clear]
    // [1052] phi info_clear::l#4 = info_clear::l#0 [phi:info_clear_all::@2->info_clear#0] -- register_copy 
    jsr info_clear
    // info_clear_all::@4
    // l++;
    // [300] info_clear_all::l#1 = ++ info_clear_all::l#2 -- vbuz1=_inc_vbuz1 
    inc.z l
    // [295] phi from info_clear_all::@4 to info_clear_all::@1 [phi:info_clear_all::@4->info_clear_all::@1]
    // [295] phi info_clear_all::l#2 = info_clear_all::l#1 [phi:info_clear_all::@4->info_clear_all::@1#0] -- register_copy 
    jmp __b1
}
  // info_line
// void info_line(__zp($47) char *info_text)
info_line: {
    .label x = $7c
    .label y = $7b
    .label info_text = $47
    // unsigned char x = wherex()
    // [302] call wherex
    jsr wherex
    // [303] wherex::return#2 = wherex::return#0
    // info_line::@1
    // [304] info_line::x#0 = wherex::return#2
    // unsigned char y = wherey()
    // [305] call wherey
    jsr wherey
    // [306] wherey::return#2 = wherey::return#0
    // info_line::@2
    // [307] info_line::y#0 = wherey::return#2
    // gotoxy(2, 14)
    // [308] call gotoxy
    // [189] phi from info_line::@2 to gotoxy [phi:info_line::@2->gotoxy]
    // [189] phi gotoxy::y#18 = $e [phi:info_line::@2->gotoxy#0] -- vbuz1=vbuc1 
    lda #$e
    sta.z gotoxy.y
    // [189] phi gotoxy::x#18 = 2 [phi:info_line::@2->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // info_line::@3
    // printf("%-60s", info_text)
    // [309] printf_string::str#0 = info_line::info_text#13
    // [310] call printf_string
    // [1022] phi from info_line::@3 to printf_string [phi:info_line::@3->printf_string]
    // [1022] phi printf_string::str#10 = printf_string::str#0 [phi:info_line::@3->printf_string#0] -- register_copy 
    // [1022] phi printf_string::format_justify_left#10 = 1 [phi:info_line::@3->printf_string#1] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1022] phi printf_string::format_min_length#10 = $3c [phi:info_line::@3->printf_string#2] -- vbuz1=vbuc1 
    lda #$3c
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_line::@4
    // gotoxy(x, y)
    // [311] gotoxy::x#10 = info_line::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [312] gotoxy::y#10 = info_line::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [313] call gotoxy
    // [189] phi from info_line::@4 to gotoxy [phi:info_line::@4->gotoxy]
    // [189] phi gotoxy::y#18 = gotoxy::y#10 [phi:info_line::@4->gotoxy#0] -- register_copy 
    // [189] phi gotoxy::x#18 = gotoxy::x#10 [phi:info_line::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // info_line::@return
    // }
    // [314] return 
    rts
}
  // smc_detect
smc_detect: {
    .label smc_detect__1 = $7c
    .label smc_bootloader_version = $2c
    // When the bootloader is not present, 0xFF is returned.
    .label return = $2c
    // unsigned int smc_bootloader_version = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [315] cx16_k_i2c_read_byte::device = $42 -- vbuz1=vbuc1 
    lda #$42
    sta.z cx16_k_i2c_read_byte.device
    // [316] cx16_k_i2c_read_byte::offset = $8e -- vbuz1=vbuc1 
    lda #$8e
    sta.z cx16_k_i2c_read_byte.offset
    // [317] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [318] cx16_k_i2c_read_byte::return#10 = cx16_k_i2c_read_byte::return#1
    // smc_detect::@3
    // [319] smc_detect::smc_bootloader_version#0 = cx16_k_i2c_read_byte::return#10
    // BYTE1(smc_bootloader_version)
    // [320] smc_detect::$1 = byte1  smc_detect::smc_bootloader_version#0 -- vbuz1=_byte1_vwuz2 
    lda.z smc_bootloader_version+1
    sta.z smc_detect__1
    // if(!BYTE1(smc_bootloader_version))
    // [321] if(0==smc_detect::$1) goto smc_detect::@1 -- 0_eq_vbuz1_then_la1 
    beq __b1
    // [324] phi from smc_detect::@3 to smc_detect::@return [phi:smc_detect::@3->smc_detect::@return]
    // [324] phi smc_detect::return#1 = $200 [phi:smc_detect::@3->smc_detect::@return#0] -- vwuz1=vwuc1 
    lda #<$200
    sta.z return
    lda #>$200
    sta.z return+1
    rts
    // smc_detect::@1
  __b1:
    // if(smc_bootloader_version == 0xFF)
    // [322] if(smc_detect::smc_bootloader_version#0!=$ff) goto smc_detect::@2 -- vwuz1_neq_vbuc1_then_la1 
    lda.z smc_bootloader_version+1
    bne __b2
    lda.z smc_bootloader_version
    cmp #$ff
    bne __b2
    // [324] phi from smc_detect::@1 to smc_detect::@return [phi:smc_detect::@1->smc_detect::@return]
    // [324] phi smc_detect::return#1 = $100 [phi:smc_detect::@1->smc_detect::@return#0] -- vwuz1=vwuc1 
    lda #<$100
    sta.z return
    lda #>$100
    sta.z return+1
    rts
    // [323] phi from smc_detect::@1 to smc_detect::@2 [phi:smc_detect::@1->smc_detect::@2]
    // smc_detect::@2
  __b2:
    // [324] phi from smc_detect::@2 to smc_detect::@return [phi:smc_detect::@2->smc_detect::@return]
    // [324] phi smc_detect::return#1 = smc_detect::smc_bootloader_version#0 [phi:smc_detect::@2->smc_detect::@return#0] -- register_copy 
    // smc_detect::@return
    // }
    // [325] return 
    rts
}
  // wait_key
wait_key: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    .label kbhit1_return = $7b
    // wait_key::bank_set_bram1
    // BRAM = bank
    // [327] BRAM = wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // wait_key::bank_set_brom1
    // BROM = bank
    // [328] BROM = wait_key::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [329] phi from wait_key::@1 wait_key::bank_set_brom1 to wait_key::kbhit1 [phi:wait_key::@1/wait_key::bank_set_brom1->wait_key::kbhit1]
    // wait_key::kbhit1
  kbhit1:
    // wait_key::kbhit1_cbm_k_clrchn1
    // asm
    // asm { jsrCBM_CLRCHN  }
    jsr CBM_CLRCHN
    // [331] phi from wait_key::kbhit1_cbm_k_clrchn1 to wait_key::kbhit1_@2 [phi:wait_key::kbhit1_cbm_k_clrchn1->wait_key::kbhit1_@2]
    // wait_key::kbhit1_@2
    // cbm_k_getin()
    // [332] call cbm_k_getin
    jsr cbm_k_getin
    // [333] cbm_k_getin::return#2 = cbm_k_getin::return#1
    // wait_key::@2
    // [334] wait_key::kbhit1_return#0 = cbm_k_getin::return#2
    // wait_key::@1
    // while (!(ch = kbhit()))
    // [335] if(0==wait_key::kbhit1_return#0) goto wait_key::kbhit1 -- 0_eq_vbuz1_then_la1 
    lda.z kbhit1_return
    beq kbhit1
    // wait_key::@return
    // }
    // [336] return 
    rts
}
  // rom_detect
rom_detect: {
    .const bank_set_brom1_bank = 4
    .label rom_detect__3 = $ce
    .label rom_detect__5 = $ce
    .label rom_detect__9 = $c7
    .label rom_detect__14 = $39
    .label rom_detect__15 = $b0
    .label rom_detect__17 = $af
    .label rom_detect__18 = $dc
    .label rom_detect__20 = $ac
    .label rom_detect__21 = $70
    .label rom_detect__23 = $c6
    .label rom_detect__24 = $dd
    .label rom_chip = $ae
    .label rom_detect_address = $be
    .label rom_detect__33 = $c7
    // [338] phi from rom_detect to rom_detect::@1 [phi:rom_detect->rom_detect::@1]
    // [338] phi rom_detect::rom_chip#10 = 0 [phi:rom_detect->rom_detect::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip
    // [338] phi rom_detect::rom_detect_address#10 = 0 [phi:rom_detect->rom_detect::@1#1] -- vduz1=vduc1 
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
    // [339] if(rom_detect::rom_detect_address#10<8*$80000) goto rom_detect::@2 -- vduz1_lt_vduc1_then_la1 
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
    // [340] return 
    rts
    // rom_detect::@2
  __b2:
    // rom_manufacturer_ids[rom_chip] = 0
    // [341] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    ldy.z rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = 0
    // [342] rom_device_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta rom_device_ids,y
    // rom_unlock(rom_detect_address + 0x05555, 0x90)
    // [343] rom_unlock::address#0 = rom_detect::rom_detect_address#10 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [344] call rom_unlock
    // [1078] phi from rom_detect::@2 to rom_unlock [phi:rom_detect::@2->rom_unlock]
    // [1078] phi rom_unlock::unlock_code#2 = $90 [phi:rom_detect::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$90
    sta.z rom_unlock.unlock_code
    // [1078] phi rom_unlock::address#2 = rom_unlock::address#0 [phi:rom_detect::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_detect::@12
    // rom_read_byte(rom_detect_address)
    // [345] rom_read_byte::address#0 = rom_detect::rom_detect_address#10 -- vduz1=vduz2 
    lda.z rom_detect_address
    sta.z rom_read_byte.address
    lda.z rom_detect_address+1
    sta.z rom_read_byte.address+1
    lda.z rom_detect_address+2
    sta.z rom_read_byte.address+2
    lda.z rom_detect_address+3
    sta.z rom_read_byte.address+3
    // [346] call rom_read_byte
    // [1088] phi from rom_detect::@12 to rom_read_byte [phi:rom_detect::@12->rom_read_byte]
    // [1088] phi rom_read_byte::address#2 = rom_read_byte::address#0 [phi:rom_detect::@12->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(rom_detect_address)
    // [347] rom_read_byte::return#2 = rom_read_byte::return#0
    // rom_detect::@13
    // [348] rom_detect::$3 = rom_read_byte::return#2
    // rom_manufacturer_ids[rom_chip] = rom_read_byte(rom_detect_address)
    // [349] rom_manufacturer_ids[rom_detect::rom_chip#10] = rom_detect::$3 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z rom_detect__3
    ldy.z rom_chip
    sta rom_manufacturer_ids,y
    // rom_read_byte(rom_detect_address + 1)
    // [350] rom_read_byte::address#1 = rom_detect::rom_detect_address#10 + 1 -- vduz1=vduz2_plus_1 
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
    // [351] call rom_read_byte
    // [1088] phi from rom_detect::@13 to rom_read_byte [phi:rom_detect::@13->rom_read_byte]
    // [1088] phi rom_read_byte::address#2 = rom_read_byte::address#1 [phi:rom_detect::@13->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(rom_detect_address + 1)
    // [352] rom_read_byte::return#3 = rom_read_byte::return#0
    // rom_detect::@14
    // [353] rom_detect::$5 = rom_read_byte::return#3
    // rom_device_ids[rom_chip] = rom_read_byte(rom_detect_address + 1)
    // [354] rom_device_ids[rom_detect::rom_chip#10] = rom_detect::$5 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z rom_detect__5
    ldy.z rom_chip
    sta rom_device_ids,y
    // rom_unlock(rom_detect_address + 0x05555, 0xF0)
    // [355] rom_unlock::address#1 = rom_detect::rom_detect_address#10 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [356] call rom_unlock
    // [1078] phi from rom_detect::@14 to rom_unlock [phi:rom_detect::@14->rom_unlock]
    // [1078] phi rom_unlock::unlock_code#2 = $f0 [phi:rom_detect::@14->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$f0
    sta.z rom_unlock.unlock_code
    // [1078] phi rom_unlock::address#2 = rom_unlock::address#1 [phi:rom_detect::@14->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_detect::bank_set_brom1
    // BROM = bank
    // [357] BROM = rom_detect::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // rom_detect::@11
    // case SST39SF010A:
    //             rom_device_names[rom_chip] = "f010a";
    //             rom_size_strings[rom_chip] = "128";
    //             rom_sizes[rom_chip] = 128 * 1024;
    //             break;
    // [358] if(rom_device_ids[rom_detect::rom_chip#10]==$b5) goto rom_detect::@3 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
    ldy.z rom_chip
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
    // [359] if(rom_device_ids[rom_detect::rom_chip#10]==$b6) goto rom_detect::@4 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
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
    // [360] if(rom_device_ids[rom_detect::rom_chip#10]==$b7) goto rom_detect::@5 -- pbuc1_derefidx_vbuz1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b7
    bne !__b5+
    jmp __b5
  !__b5:
    // rom_detect::@6
    // rom_manufacturer_ids[rom_chip] = 0
    // [361] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    sta rom_manufacturer_ids,y
    // rom_device_names[rom_chip] = "----"
    // [362] rom_detect::$23 = rom_detect::rom_chip#10 << 1 -- vbuz1=vbuz2_rol_1 
    tya
    asl
    sta.z rom_detect__23
    // [363] rom_device_names[rom_detect::$23] = rom_detect::$31 -- qbuc1_derefidx_vbuz1=pbuc2 
    tay
    lda #<rom_detect__31
    sta rom_device_names,y
    lda #>rom_detect__31
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "000"
    // [364] rom_size_strings[rom_detect::$23] = rom_detect::$32 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__32
    sta rom_size_strings,y
    lda #>rom_detect__32
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 0
    // [365] rom_detect::$24 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta.z rom_detect__24
    // [366] rom_sizes[rom_detect::$24] = 0 -- pduc1_derefidx_vbuz1=vbuc2 
    tay
    lda #0
    sta rom_sizes,y
    sta rom_sizes+1,y
    sta rom_sizes+2,y
    sta rom_sizes+3,y
    // rom_device_ids[rom_chip] = UNKNOWN
    // [367] rom_device_ids[rom_detect::rom_chip#10] = $55 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #$55
    ldy.z rom_chip
    sta rom_device_ids,y
    // rom_detect::@7
  __b7:
    // rom_chip*3
    // [368] rom_detect::$33 = rom_detect::rom_chip#10 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta.z rom_detect__33
    // [369] rom_detect::$9 = rom_detect::$33 + rom_detect::rom_chip#10 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z rom_detect__9
    clc
    adc.z rom_chip
    sta.z rom_detect__9
    // gotoxy(rom_chip*3+40, 1)
    // [370] gotoxy::x#17 = rom_detect::$9 + $28 -- vbuz1=vbuz2_plus_vbuc1 
    lda #$28
    clc
    adc.z rom_detect__9
    sta.z gotoxy.x
    // [371] call gotoxy
    // [189] phi from rom_detect::@7 to gotoxy [phi:rom_detect::@7->gotoxy]
    // [189] phi gotoxy::y#18 = 1 [phi:rom_detect::@7->gotoxy#0] -- vbuz1=vbuc1 
    lda #1
    sta.z gotoxy.y
    // [189] phi gotoxy::x#18 = gotoxy::x#17 [phi:rom_detect::@7->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_detect::@15
    // printf("%02x", rom_device_ids[rom_chip])
    // [372] printf_uchar::uvalue#6 = rom_device_ids[rom_detect::rom_chip#10] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z rom_chip
    lda rom_device_ids,y
    sta.z printf_uchar.uvalue
    // [373] call printf_uchar
    // [1100] phi from rom_detect::@15 to printf_uchar [phi:rom_detect::@15->printf_uchar]
    // [1100] phi printf_uchar::format_zero_padding#10 = 1 [phi:rom_detect::@15->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1100] phi printf_uchar::format_min_length#10 = 2 [phi:rom_detect::@15->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [1100] phi printf_uchar::putc#10 = &cputc [phi:rom_detect::@15->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1100] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:rom_detect::@15->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [1100] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#6 [phi:rom_detect::@15->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // rom_detect::@16
    // rom_chip++;
    // [374] rom_detect::rom_chip#1 = ++ rom_detect::rom_chip#10 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip
    // rom_detect::@8
    // rom_detect_address += 0x80000
    // [375] rom_detect::rom_detect_address#1 = rom_detect::rom_detect_address#10 + $80000 -- vduz1=vduz1_plus_vduc1 
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
    // [338] phi from rom_detect::@8 to rom_detect::@1 [phi:rom_detect::@8->rom_detect::@1]
    // [338] phi rom_detect::rom_chip#10 = rom_detect::rom_chip#1 [phi:rom_detect::@8->rom_detect::@1#0] -- register_copy 
    // [338] phi rom_detect::rom_detect_address#10 = rom_detect::rom_detect_address#1 [phi:rom_detect::@8->rom_detect::@1#1] -- register_copy 
    jmp __b1
    // rom_detect::@5
  __b5:
    // rom_device_names[rom_chip] = "f040"
    // [376] rom_detect::$20 = rom_detect::rom_chip#10 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta.z rom_detect__20
    // [377] rom_device_names[rom_detect::$20] = rom_detect::$29 -- qbuc1_derefidx_vbuz1=pbuc2 
    tay
    lda #<rom_detect__29
    sta rom_device_names,y
    lda #>rom_detect__29
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "512"
    // [378] rom_size_strings[rom_detect::$20] = rom_detect::$30 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__30
    sta rom_size_strings,y
    lda #>rom_detect__30
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 512 * 1024
    // [379] rom_detect::$21 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta.z rom_detect__21
    // [380] rom_sizes[rom_detect::$21] = (unsigned long)$200*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
    // [381] rom_detect::$17 = rom_detect::rom_chip#10 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta.z rom_detect__17
    // [382] rom_device_names[rom_detect::$17] = rom_detect::$27 -- qbuc1_derefidx_vbuz1=pbuc2 
    tay
    lda #<rom_detect__27
    sta rom_device_names,y
    lda #>rom_detect__27
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "256"
    // [383] rom_size_strings[rom_detect::$17] = rom_detect::$28 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__28
    sta rom_size_strings,y
    lda #>rom_detect__28
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 256 * 1024
    // [384] rom_detect::$18 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta.z rom_detect__18
    // [385] rom_sizes[rom_detect::$18] = (unsigned long)$100*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
    // [386] rom_detect::$14 = rom_detect::rom_chip#10 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z rom_chip
    asl
    sta.z rom_detect__14
    // [387] rom_device_names[rom_detect::$14] = rom_detect::$25 -- qbuc1_derefidx_vbuz1=pbuc2 
    tay
    lda #<rom_detect__25
    sta rom_device_names,y
    lda #>rom_detect__25
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "128"
    // [388] rom_size_strings[rom_detect::$14] = rom_detect::$26 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__26
    sta rom_size_strings,y
    lda #>rom_detect__26
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 128 * 1024
    // [389] rom_detect::$15 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbuz2_rol_2 
    lda.z rom_chip
    asl
    asl
    sta.z rom_detect__15
    // [390] rom_sizes[rom_detect::$15] = (unsigned long)$80*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
}
.segment Code
  // chip_smc
chip_smc: {
    // print_smc_led(GREY)
    // [392] call print_smc_led
    // [1111] phi from chip_smc to print_smc_led [phi:chip_smc->print_smc_led]
    // [1111] phi print_smc_led::c#2 = GREY [phi:chip_smc->print_smc_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z print_smc_led.c
    jsr print_smc_led
    // [393] phi from chip_smc to chip_smc::@1 [phi:chip_smc->chip_smc::@1]
    // chip_smc::@1
    // print_chip(CHIP_SMC_X, CHIP_SMC_Y+1, CHIP_SMC_W, "smc     ")
    // [394] call print_chip
    // [1115] phi from chip_smc::@1 to print_chip [phi:chip_smc::@1->print_chip]
    // [1115] phi print_chip::text#11 = chip_smc::text [phi:chip_smc::@1->print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z print_chip.text_2
    lda #>text
    sta.z print_chip.text_2+1
    // [1115] phi print_chip::w#10 = 5 [phi:chip_smc::@1->print_chip#1] -- vbuz1=vbuc1 
    lda #5
    sta.z print_chip.w
    // [1115] phi print_chip::x#10 = 1 [phi:chip_smc::@1->print_chip#2] -- vbuz1=vbuc1 
    lda #1
    sta.z print_chip.x
    jsr print_chip
    // chip_smc::@return
    // }
    // [395] return 
    rts
  .segment Data
    text: .text "smc     "
    .byte 0
}
.segment Code
  // chip_vera
chip_vera: {
    // print_vera_led(GREY)
    // [397] call print_vera_led
    // [1159] phi from chip_vera to print_vera_led [phi:chip_vera->print_vera_led]
    // [1159] phi print_vera_led::c#2 = GREY [phi:chip_vera->print_vera_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z print_vera_led.c
    jsr print_vera_led
    // [398] phi from chip_vera to chip_vera::@1 [phi:chip_vera->chip_vera::@1]
    // chip_vera::@1
    // print_chip(CHIP_VERA_X, CHIP_VERA_Y+1, CHIP_VERA_W, "vera     ")
    // [399] call print_chip
    // [1115] phi from chip_vera::@1 to print_chip [phi:chip_vera::@1->print_chip]
    // [1115] phi print_chip::text#11 = chip_vera::text [phi:chip_vera::@1->print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z print_chip.text_2
    lda #>text
    sta.z print_chip.text_2+1
    // [1115] phi print_chip::w#10 = 8 [phi:chip_vera::@1->print_chip#1] -- vbuz1=vbuc1 
    lda #8
    sta.z print_chip.w
    // [1115] phi print_chip::x#10 = 9 [phi:chip_vera::@1->print_chip#2] -- vbuz1=vbuc1 
    lda #9
    sta.z print_chip.x
    jsr print_chip
    // chip_vera::@return
    // }
    // [400] return 
    rts
  .segment Data
    text: .text "vera     "
    .byte 0
}
.segment Code
  // chip_rom
chip_rom: {
    .label chip_rom__3 = $c6
    .label chip_rom__5 = $42
    .label r = $c7
    .label chip_rom__9 = $ce
    .label chip_rom__10 = $ce
    // [402] phi from chip_rom to chip_rom::@1 [phi:chip_rom->chip_rom::@1]
    // [402] phi chip_rom::r#2 = 0 [phi:chip_rom->chip_rom::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z r
    // chip_rom::@1
  __b1:
    // for (unsigned char r = 0; r < 8; r++)
    // [403] if(chip_rom::r#2<8) goto chip_rom::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z r
    cmp #8
    bcc __b2
    // chip_rom::@return
    // }
    // [404] return 
    rts
    // [405] phi from chip_rom::@1 to chip_rom::@2 [phi:chip_rom::@1->chip_rom::@2]
    // chip_rom::@2
  __b2:
    // strcpy(rom, "rom0 ")
    // [406] call strcpy
    // [445] phi from chip_rom::@2 to strcpy [phi:chip_rom::@2->strcpy]
    // [445] phi strcpy::dst#0 = chip_rom::rom [phi:chip_rom::@2->strcpy#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z strcpy.dst
    lda #>rom
    sta.z strcpy.dst+1
    // [445] phi strcpy::src#0 = chip_rom::source [phi:chip_rom::@2->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // chip_rom::@3
    // strcat(rom, rom_size_strings[r])
    // [407] chip_rom::$9 = chip_rom::r#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z r
    asl
    sta.z chip_rom__9
    // [408] strcat::source#0 = rom_size_strings[chip_rom::$9] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda rom_size_strings,y
    sta.z strcat.source
    lda rom_size_strings+1,y
    sta.z strcat.source+1
    // [409] call strcat
    // [1163] phi from chip_rom::@3 to strcat [phi:chip_rom::@3->strcat]
    jsr strcat
    // chip_rom::@4
    // r+'0'
    // [410] chip_rom::$3 = chip_rom::r#2 + '0' -- vbuz1=vbuz2_plus_vbuc1 
    lda #'0'
    clc
    adc.z r
    sta.z chip_rom__3
    // *(rom+3) = r+'0'
    // [411] *(chip_rom::rom+3) = chip_rom::$3 -- _deref_pbuc1=vbuz1 
    sta rom+3
    // print_rom_led(r, GREY)
    // [412] print_rom_led::chip#0 = chip_rom::r#2 -- vbuz1=vbuz2 
    lda.z r
    sta.z print_rom_led.chip
    // [413] call print_rom_led
    // [1175] phi from chip_rom::@4 to print_rom_led [phi:chip_rom::@4->print_rom_led]
    // [1175] phi print_rom_led::c#2 = GREY [phi:chip_rom::@4->print_rom_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z print_rom_led.c
    // [1175] phi print_rom_led::chip#2 = print_rom_led::chip#0 [phi:chip_rom::@4->print_rom_led#1] -- register_copy 
    jsr print_rom_led
    // chip_rom::@5
    // r*6
    // [414] chip_rom::$10 = chip_rom::$9 + chip_rom::r#2 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z chip_rom__10
    clc
    adc.z r
    sta.z chip_rom__10
    // [415] chip_rom::$5 = chip_rom::$10 << 1 -- vbuz1=vbuz2_rol_1 
    asl
    sta.z chip_rom__5
    // print_chip(CHIP_ROM_X+r*6, CHIP_ROM_Y+1, CHIP_ROM_W, rom)
    // [416] print_chip::x#2 = $14 + chip_rom::$5 -- vbuz1=vbuc1_plus_vbuz1 
    lda #$14
    clc
    adc.z print_chip.x
    sta.z print_chip.x
    // [417] call print_chip
    // [1115] phi from chip_rom::@5 to print_chip [phi:chip_rom::@5->print_chip]
    // [1115] phi print_chip::text#11 = chip_rom::rom [phi:chip_rom::@5->print_chip#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z print_chip.text_2
    lda #>rom
    sta.z print_chip.text_2+1
    // [1115] phi print_chip::w#10 = 3 [phi:chip_rom::@5->print_chip#1] -- vbuz1=vbuc1 
    lda #3
    sta.z print_chip.w
    // [1115] phi print_chip::x#10 = print_chip::x#2 [phi:chip_rom::@5->print_chip#2] -- register_copy 
    jsr print_chip
    // chip_rom::@6
    // for (unsigned char r = 0; r < 8; r++)
    // [418] chip_rom::r#1 = ++ chip_rom::r#2 -- vbuz1=_inc_vbuz1 
    inc.z r
    // [402] phi from chip_rom::@6 to chip_rom::@1 [phi:chip_rom::@6->chip_rom::@1]
    // [402] phi chip_rom::r#2 = chip_rom::r#1 [phi:chip_rom::@6->chip_rom::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    rom: .fill $10, 0
    source: .text "rom0 "
    .byte 0
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
// void info_smc(__zp($ac) char info_status)
info_smc: {
    .label info_smc__3 = $ac
    .label info_status = $ac
    // print_smc_led(status_color[info_status])
    // [420] print_smc_led::c#1 = status_color[info_smc::info_status#2] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z print_smc_led.c
    // [421] call print_smc_led
    // [1111] phi from info_smc to print_smc_led [phi:info_smc->print_smc_led]
    // [1111] phi print_smc_led::c#2 = print_smc_led::c#1 [phi:info_smc->print_smc_led#0] -- register_copy 
    jsr print_smc_led
    // [422] phi from info_smc to info_smc::@1 [phi:info_smc->info_smc::@1]
    // info_smc::@1
    // info_clear(0)
    // [423] call info_clear
    // [1052] phi from info_smc::@1 to info_clear [phi:info_smc::@1->info_clear]
    // [1052] phi info_clear::l#4 = 0 [phi:info_smc::@1->info_clear#0] -- vbuz1=vbuc1 
    lda #0
    sta.z info_clear.l
    jsr info_clear
    // [424] phi from info_smc::@1 to info_smc::@2 [phi:info_smc::@1->info_smc::@2]
    // info_smc::@2
    // printf("SMC  - CX16 - %-8s - Bootloader version %u.", status_text[info_status], smc_bootloader)
    // [425] call printf_str
    // [560] phi from info_smc::@2 to printf_str [phi:info_smc::@2->printf_str]
    // [560] phi printf_str::putc#28 = &cputc [phi:info_smc::@2->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [560] phi printf_str::s#28 = info_smc::s [phi:info_smc::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // info_smc::@3
    // printf("SMC  - CX16 - %-8s - Bootloader version %u.", status_text[info_status], smc_bootloader)
    // [426] info_smc::$3 = info_smc::info_status#2 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z info_smc__3
    // [427] printf_string::str#2 = status_text[info_smc::$3] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z info_smc__3
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [428] call printf_string
    // [1022] phi from info_smc::@3 to printf_string [phi:info_smc::@3->printf_string]
    // [1022] phi printf_string::str#10 = printf_string::str#2 [phi:info_smc::@3->printf_string#0] -- register_copy 
    // [1022] phi printf_string::format_justify_left#10 = 1 [phi:info_smc::@3->printf_string#1] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1022] phi printf_string::format_min_length#10 = 8 [phi:info_smc::@3->printf_string#2] -- vbuz1=vbuc1 
    lda #8
    sta.z printf_string.format_min_length
    jsr printf_string
    // [429] phi from info_smc::@3 to info_smc::@4 [phi:info_smc::@3->info_smc::@4]
    // info_smc::@4
    // printf("SMC  - CX16 - %-8s - Bootloader version %u.", status_text[info_status], smc_bootloader)
    // [430] call printf_str
    // [560] phi from info_smc::@4 to printf_str [phi:info_smc::@4->printf_str]
    // [560] phi printf_str::putc#28 = &cputc [phi:info_smc::@4->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [560] phi printf_str::s#28 = info_smc::s1 [phi:info_smc::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_smc::@5
    // printf("SMC  - CX16 - %-8s - Bootloader version %u.", status_text[info_status], smc_bootloader)
    // [431] printf_uint::uvalue#0 = smc_bootloader#0 -- vwuz1=vwum2 
    lda smc_bootloader
    sta.z printf_uint.uvalue
    lda smc_bootloader+1
    sta.z printf_uint.uvalue+1
    // [432] call printf_uint
    // [1183] phi from info_smc::@5 to printf_uint [phi:info_smc::@5->printf_uint]
    // [1183] phi printf_uint::format_zero_padding#10 = 0 [phi:info_smc::@5->printf_uint#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uint.format_zero_padding
    // [1183] phi printf_uint::format_min_length#10 = 0 [phi:info_smc::@5->printf_uint#1] -- vbuz1=vbuc1 
    sta.z printf_uint.format_min_length
    // [1183] phi printf_uint::putc#10 = &cputc [phi:info_smc::@5->printf_uint#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uint.putc
    lda #>cputc
    sta.z printf_uint.putc+1
    // [1183] phi printf_uint::format_radix#10 = DECIMAL [phi:info_smc::@5->printf_uint#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [1183] phi printf_uint::uvalue#6 = printf_uint::uvalue#0 [phi:info_smc::@5->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [433] phi from info_smc::@5 to info_smc::@6 [phi:info_smc::@5->info_smc::@6]
    // info_smc::@6
    // printf("SMC  - CX16 - %-8s - Bootloader version %u.", status_text[info_status], smc_bootloader)
    // [434] call printf_str
    // [560] phi from info_smc::@6 to printf_str [phi:info_smc::@6->printf_str]
    // [560] phi printf_str::putc#28 = &cputc [phi:info_smc::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [560] phi printf_str::s#28 = info_smc::s2 [phi:info_smc::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // info_smc::@return
    // }
    // [435] return 
    rts
  .segment Data
    s: .text "SMC  - CX16 - "
    .byte 0
    s1: .text " - Bootloader version "
    .byte 0
    s2: .text "."
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
    // print_vera_led(status_color[info_status])
    // [436] print_vera_led::c#1 = *status_color -- vbuz1=_deref_pbuc1 
    lda status_color
    sta.z print_vera_led.c
    // [437] call print_vera_led
    // [1159] phi from info_vera to print_vera_led [phi:info_vera->print_vera_led]
    // [1159] phi print_vera_led::c#2 = print_vera_led::c#1 [phi:info_vera->print_vera_led#0] -- register_copy 
    jsr print_vera_led
    // [438] phi from info_vera to info_vera::@1 [phi:info_vera->info_vera::@1]
    // info_vera::@1
    // info_clear(1)
    // [439] call info_clear
    // [1052] phi from info_vera::@1 to info_clear [phi:info_vera::@1->info_clear]
    // [1052] phi info_clear::l#4 = 1 [phi:info_vera::@1->info_clear#0] -- vbuz1=vbuc1 
    lda #1
    sta.z info_clear.l
    jsr info_clear
    // [440] phi from info_vera::@1 to info_vera::@2 [phi:info_vera::@1->info_vera::@2]
    // info_vera::@2
    // printf("VERA - CX16 - %-8s", status_text[info_status])
    // [441] call printf_str
    // [560] phi from info_vera::@2 to printf_str [phi:info_vera::@2->printf_str]
    // [560] phi printf_str::putc#28 = &cputc [phi:info_vera::@2->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [560] phi printf_str::s#28 = info_vera::s [phi:info_vera::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // info_vera::@3
    // printf("VERA - CX16 - %-8s", status_text[info_status])
    // [442] printf_string::str#3 = *status_text -- pbuz1=_deref_qbuc1 
    lda status_text
    sta.z printf_string.str
    lda status_text+1
    sta.z printf_string.str+1
    // [443] call printf_string
    // [1022] phi from info_vera::@3 to printf_string [phi:info_vera::@3->printf_string]
    // [1022] phi printf_string::str#10 = printf_string::str#3 [phi:info_vera::@3->printf_string#0] -- register_copy 
    // [1022] phi printf_string::format_justify_left#10 = 1 [phi:info_vera::@3->printf_string#1] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1022] phi printf_string::format_min_length#10 = 8 [phi:info_vera::@3->printf_string#2] -- vbuz1=vbuc1 
    lda #8
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_vera::@return
    // }
    // [444] return 
    rts
  .segment Data
    s: .text "VERA - CX16 - "
    .byte 0
}
.segment Code
  // strcpy
// Copies the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcpy(char *destination, __zp($47) char *source)
strcpy: {
    .label src = $47
    .label dst = $2c
    .label source = $47
    // [446] phi from strcpy strcpy::@2 to strcpy::@1 [phi:strcpy/strcpy::@2->strcpy::@1]
    // [446] phi strcpy::dst#2 = strcpy::dst#0 [phi:strcpy/strcpy::@2->strcpy::@1#0] -- register_copy 
    // [446] phi strcpy::src#2 = strcpy::src#0 [phi:strcpy/strcpy::@2->strcpy::@1#1] -- register_copy 
    // strcpy::@1
  __b1:
    // while(*src)
    // [447] if(0!=*strcpy::src#2) goto strcpy::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcpy::@3
    // *dst = 0
    // [448] *strcpy::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcpy::@return
    // }
    // [449] return 
    rts
    // strcpy::@2
  __b2:
    // *dst++ = *src++
    // [450] *strcpy::dst#2 = *strcpy::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [451] strcpy::dst#1 = ++ strcpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [452] strcpy::src#1 = ++ strcpy::src#2 -- pbuz1=_inc_pbuz1 
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
// __zp($79) struct $2 * fopen(__zp($5d) const char *path, const char *mode)
fopen: {
    .label fopen__4 = $ac
    .label fopen__9 = $70
    .label fopen__11 = $71
    .label fopen__15 = $af
    .label fopen__16 = $da
    .label fopen__26 = $52
    .label fopen__28 = $69
    .label fopen__30 = $79
    .label cbm_k_setnam1_filename_len = $fb
    .label cbm_k_setnam1_fopen__0 = $34
    .label sp = $dd
    .label stream = $79
    .label pathpos = $c7
    .label pathpos_1 = $56
    .label pathtoken = $2c
    .label pathcmp = $dc
    .label path = $5d
    // Parse path
    .label pathstep = $76
    .label num = $c6
    .label cbm_k_readst1_return = $af
    .label return = $79
    // unsigned char sp = __stdio_filecount
    // [453] fopen::sp#0 = __stdio_filecount -- vbuz1=vbum2 
    lda __stdio_filecount
    sta.z sp
    // (unsigned int)sp | 0x8000
    // [454] fopen::$30 = (unsigned int)fopen::sp#0 -- vwuz1=_word_vbuz2 
    sta.z fopen__30
    lda #0
    sta.z fopen__30+1
    // [455] fopen::stream#0 = fopen::$30 | $8000 -- vwuz1=vwuz1_bor_vwuc1 
    lda.z stream
    ora #<$8000
    sta.z stream
    lda.z stream+1
    ora #>$8000
    sta.z stream+1
    // char pathpos = sp * __STDIO_FILECOUNT
    // [456] fopen::pathpos#0 = fopen::sp#0 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z sp
    asl
    sta.z pathpos
    // __logical = 0
    // [457] ((char *)&__stdio_file+$40)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    ldy.z sp
    sta __stdio_file+$40,y
    // __device = 0
    // [458] ((char *)&__stdio_file+$42)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [459] ((char *)&__stdio_file+$44)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$44,y
    // [460] fopen::pathpos#21 = fopen::pathpos#0 -- vbuz1=vbuz2 
    lda.z pathpos
    sta.z pathpos_1
    // [461] phi from fopen to fopen::@8 [phi:fopen->fopen::@8]
    // [461] phi fopen::num#10 = 0 [phi:fopen->fopen::@8#0] -- vbuz1=vbuc1 
    lda #0
    sta.z num
    // [461] phi fopen::pathpos#10 = fopen::pathpos#21 [phi:fopen->fopen::@8#1] -- register_copy 
    // [461] phi fopen::path#13 = file [phi:fopen->fopen::@8#2] -- pbuz1=pbuc1 
    lda #<file
    sta.z path
    lda #>file
    sta.z path+1
    // [461] phi fopen::pathstep#10 = 0 [phi:fopen->fopen::@8#3] -- vbuz1=vbuc1 
    lda #0
    sta.z pathstep
    // [461] phi fopen::pathtoken#10 = file [phi:fopen->fopen::@8#4] -- pbuz1=pbuc1 
    lda #<file
    sta.z pathtoken
    lda #>file
    sta.z pathtoken+1
  // Iterate while path is not \0.
    // [461] phi from fopen::@22 to fopen::@8 [phi:fopen::@22->fopen::@8]
    // [461] phi fopen::num#10 = fopen::num#13 [phi:fopen::@22->fopen::@8#0] -- register_copy 
    // [461] phi fopen::pathpos#10 = fopen::pathpos#7 [phi:fopen::@22->fopen::@8#1] -- register_copy 
    // [461] phi fopen::path#13 = fopen::path#10 [phi:fopen::@22->fopen::@8#2] -- register_copy 
    // [461] phi fopen::pathstep#10 = fopen::pathstep#11 [phi:fopen::@22->fopen::@8#3] -- register_copy 
    // [461] phi fopen::pathtoken#10 = fopen::pathtoken#1 [phi:fopen::@22->fopen::@8#4] -- register_copy 
    // fopen::@8
  __b8:
    // if (*pathtoken == ',' || *pathtoken == '\0')
    // [462] if(*fopen::pathtoken#10==',') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #','
    ldy #0
    cmp (pathtoken),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@33
    // [463] if(*fopen::pathtoken#10=='@') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #'@'
    cmp (pathtoken),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@23
    // if (pathstep == 0)
    // [464] if(fopen::pathstep#10!=0) goto fopen::@10 -- vbuz1_neq_0_then_la1 
    lda.z pathstep
    bne __b10
    // fopen::@24
    // __stdio_file.filename[pathpos] = *pathtoken
    // [465] ((char *)&__stdio_file)[fopen::pathpos#10] = *fopen::pathtoken#10 -- pbuc1_derefidx_vbuz1=_deref_pbuz2 
    lda (pathtoken),y
    ldy.z pathpos_1
    sta __stdio_file,y
    // pathpos++;
    // [466] fopen::pathpos#1 = ++ fopen::pathpos#10 -- vbuz1=_inc_vbuz1 
    inc.z pathpos_1
    // [467] phi from fopen::@12 fopen::@23 fopen::@24 to fopen::@10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10]
    // [467] phi fopen::num#13 = fopen::num#15 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#0] -- register_copy 
    // [467] phi fopen::pathpos#7 = fopen::pathpos#10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#1] -- register_copy 
    // [467] phi fopen::path#10 = fopen::path#12 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#2] -- register_copy 
    // [467] phi fopen::pathstep#11 = fopen::pathstep#1 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#3] -- register_copy 
    // fopen::@10
  __b10:
    // pathtoken++;
    // [468] fopen::pathtoken#1 = ++ fopen::pathtoken#10 -- pbuz1=_inc_pbuz1 
    inc.z pathtoken
    bne !+
    inc.z pathtoken+1
  !:
    // fopen::@22
    // pathtoken - 1
    // [469] fopen::$28 = fopen::pathtoken#1 - 1 -- pbuz1=pbuz2_minus_1 
    lda.z pathtoken
    sec
    sbc #1
    sta.z fopen__28
    lda.z pathtoken+1
    sbc #0
    sta.z fopen__28+1
    // while (*(pathtoken - 1))
    // [470] if(0!=*fopen::$28) goto fopen::@8 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (fopen__28),y
    cmp #0
    bne __b8
    // fopen::@26
    // __status = 0
    // [471] ((char *)&__stdio_file+$46)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    tya
    ldy.z sp
    sta __stdio_file+$46,y
    // if(!__logical)
    // [472] if(0!=((char *)&__stdio_file+$40)[fopen::sp#0]) goto fopen::@1 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$40,y
    cmp #0
    bne __b1
    // fopen::@27
    // __stdio_filecount+1
    // [473] fopen::$4 = __stdio_filecount + 1 -- vbuz1=vbum2_plus_1 
    lda __stdio_filecount
    inc
    sta.z fopen__4
    // __logical = __stdio_filecount+1
    // [474] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::$4 -- pbuc1_derefidx_vbuz1=vbuz2 
    sta __stdio_file+$40,y
    // fopen::@1
  __b1:
    // if(!__device)
    // [475] if(0!=((char *)&__stdio_file+$42)[fopen::sp#0]) goto fopen::@2 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    ldy.z sp
    lda __stdio_file+$42,y
    cmp #0
    bne __b2
    // fopen::@5
    // __device = 8
    // [476] ((char *)&__stdio_file+$42)[fopen::sp#0] = 8 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #8
    sta __stdio_file+$42,y
    // fopen::@2
  __b2:
    // if(!__channel)
    // [477] if(0!=((char *)&__stdio_file+$44)[fopen::sp#0]) goto fopen::@3 -- 0_neq_pbuc1_derefidx_vbuz1_then_la1 
    ldy.z sp
    lda __stdio_file+$44,y
    cmp #0
    bne __b3
    // fopen::@6
    // __stdio_filecount+2
    // [478] fopen::$9 = __stdio_filecount + 2 -- vbuz1=vbum2_plus_2 
    lda __stdio_filecount
    clc
    adc #2
    sta.z fopen__9
    // __channel = __stdio_filecount+2
    // [479] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::$9 -- pbuc1_derefidx_vbuz1=vbuz2 
    sta __stdio_file+$44,y
    // fopen::@3
  __b3:
    // __filename
    // [480] fopen::$11 = (char *)&__stdio_file + fopen::pathpos#0 -- pbuz1=pbuc1_plus_vbuz2 
    lda.z pathpos
    clc
    adc #<__stdio_file
    sta.z fopen__11
    lda #>__stdio_file
    adc #0
    sta.z fopen__11+1
    // cbm_k_setnam(__filename)
    // [481] fopen::cbm_k_setnam1_filename = fopen::$11 -- pbum1=pbuz2 
    lda.z fopen__11
    sta cbm_k_setnam1_filename
    lda.z fopen__11+1
    sta cbm_k_setnam1_filename+1
    // fopen::cbm_k_setnam1
    // strlen(filename)
    // [482] strlen::str#4 = fopen::cbm_k_setnam1_filename -- pbuz1=pbum2 
    lda cbm_k_setnam1_filename
    sta.z strlen.str
    lda cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [483] call strlen
    // [1194] phi from fopen::cbm_k_setnam1 to strlen [phi:fopen::cbm_k_setnam1->strlen]
    // [1194] phi strlen::str#8 = strlen::str#4 [phi:fopen::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [484] strlen::return#11 = strlen::len#2
    // fopen::@31
    // [485] fopen::cbm_k_setnam1_$0 = strlen::return#11
    // char filename_len = (char)strlen(filename)
    // [486] fopen::cbm_k_setnam1_filename_len = (char)fopen::cbm_k_setnam1_$0 -- vbuz1=_byte_vwuz2 
    lda.z cbm_k_setnam1_fopen__0
    sta.z cbm_k_setnam1_filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx cbm_k_setnam1_filename
    ldy cbm_k_setnam1_filename+1
    jsr CBM_SETNAM
    // fopen::@28
    // cbm_k_setlfs(__logical, __device, __channel)
    // [488] cbm_k_setlfs::channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$40,y
    sta.z cbm_k_setlfs.channel
    // [489] cbm_k_setlfs::device = ((char *)&__stdio_file+$42)[fopen::sp#0] -- vbuz1=pbuc1_derefidx_vbuz2 
    lda __stdio_file+$42,y
    sta.z cbm_k_setlfs.device
    // [490] cbm_k_setlfs::command = ((char *)&__stdio_file+$44)[fopen::sp#0] -- vbuz1=pbuc1_derefidx_vbuz2 
    lda __stdio_file+$44,y
    sta.z cbm_k_setlfs.command
    // [491] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // fopen::cbm_k_open1
    // asm
    // asm { jsrCBM_OPEN  }
    jsr CBM_OPEN
    // fopen::cbm_k_readst1
    // char status
    // [493] fopen::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [495] fopen::cbm_k_readst1_return#0 = fopen::cbm_k_readst1_status -- vbuz1=vbum2 
    sta.z cbm_k_readst1_return
    // fopen::cbm_k_readst1_@return
    // }
    // [496] fopen::cbm_k_readst1_return#1 = fopen::cbm_k_readst1_return#0
    // fopen::@29
    // cbm_k_readst()
    // [497] fopen::$15 = fopen::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [498] ((char *)&__stdio_file+$46)[fopen::sp#0] = fopen::$15 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fopen__15
    ldy.z sp
    sta __stdio_file+$46,y
    // ferror(stream)
    // [499] ferror::stream#0 = (struct $2 *)fopen::stream#0
    // [500] call ferror
    jsr ferror
    // [501] ferror::return#0 = ferror::return#1
    // fopen::@32
    // [502] fopen::$16 = ferror::return#0
    // if (ferror(stream))
    // [503] if(0==fopen::$16) goto fopen::@4 -- 0_eq_vwsz1_then_la1 
    lda.z fopen__16
    ora.z fopen__16+1
    beq __b4
    // fopen::@7
    // cbm_k_close(__logical)
    // [504] fopen::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$40,y
    sta cbm_k_close1_channel
    // fopen::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // [506] phi from fopen::cbm_k_close1 to fopen::@return [phi:fopen::cbm_k_close1->fopen::@return]
    // [506] phi fopen::return#2 = 0 [phi:fopen::cbm_k_close1->fopen::@return#0] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [507] return 
    rts
    // fopen::@4
  __b4:
    // __stdio_filecount++;
    // [508] __stdio_filecount = ++ __stdio_filecount -- vbum1=_inc_vbum1 
    inc __stdio_filecount
    // [509] fopen::return#6 = (struct $2 *)fopen::stream#0
    // [506] phi from fopen::@4 to fopen::@return [phi:fopen::@4->fopen::@return]
    // [506] phi fopen::return#2 = fopen::return#6 [phi:fopen::@4->fopen::@return#0] -- register_copy 
    rts
    // fopen::@9
  __b9:
    // if (pathstep > 0)
    // [510] if(fopen::pathstep#10>0) goto fopen::@11 -- vbuz1_gt_0_then_la1 
    lda.z pathstep
    bne __b11
    // fopen::@25
    // __stdio_file.filename[pathpos] = '\0'
    // [511] ((char *)&__stdio_file)[fopen::pathpos#10] = '@' -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #'@'
    ldy.z pathpos_1
    sta __stdio_file,y
    // path = pathtoken + 1
    // [512] fopen::path#0 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
    clc
    lda.z pathtoken
    adc #1
    sta.z path
    lda.z pathtoken+1
    adc #0
    sta.z path+1
    // [513] phi from fopen::@16 fopen::@17 fopen::@18 fopen::@19 fopen::@25 to fopen::@12 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12]
    // [513] phi fopen::num#15 = fopen::num#2 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#0] -- register_copy 
    // [513] phi fopen::path#12 = fopen::path#15 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#1] -- register_copy 
    // fopen::@12
  __b12:
    // pathstep++;
    // [514] fopen::pathstep#1 = ++ fopen::pathstep#10 -- vbuz1=_inc_vbuz1 
    inc.z pathstep
    jmp __b10
    // fopen::@11
  __b11:
    // char pathcmp = *path
    // [515] fopen::pathcmp#0 = *fopen::path#13 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (path),y
    sta.z pathcmp
    // case 'D':
    // [516] if(fopen::pathcmp#0=='D') goto fopen::@13 -- vbuz1_eq_vbuc1_then_la1 
    lda #'D'
    cmp.z pathcmp
    beq __b13
    // fopen::@20
    // case 'L':
    // [517] if(fopen::pathcmp#0=='L') goto fopen::@13 -- vbuz1_eq_vbuc1_then_la1 
    lda #'L'
    cmp.z pathcmp
    beq __b13
    // fopen::@21
    // case 'C':
    //                     num = (char)atoi(path + 1);
    //                     path = pathtoken + 1;
    // [518] if(fopen::pathcmp#0=='C') goto fopen::@13 -- vbuz1_eq_vbuc1_then_la1 
    lda #'C'
    cmp.z pathcmp
    beq __b13
    // [519] phi from fopen::@21 fopen::@30 to fopen::@14 [phi:fopen::@21/fopen::@30->fopen::@14]
    // [519] phi fopen::path#15 = fopen::path#13 [phi:fopen::@21/fopen::@30->fopen::@14#0] -- register_copy 
    // [519] phi fopen::num#2 = fopen::num#10 [phi:fopen::@21/fopen::@30->fopen::@14#1] -- register_copy 
    // fopen::@14
  __b14:
    // case 'L':
    //                     __logical = num;
    //                     break;
    // [520] if(fopen::pathcmp#0=='L') goto fopen::@17 -- vbuz1_eq_vbuc1_then_la1 
    lda #'L'
    cmp.z pathcmp
    beq __b17
    // fopen::@15
    // case 'D':
    //                     __device = num;
    //                     break;
    // [521] if(fopen::pathcmp#0=='D') goto fopen::@18 -- vbuz1_eq_vbuc1_then_la1 
    lda #'D'
    cmp.z pathcmp
    beq __b18
    // fopen::@16
    // case 'C':
    //                     __channel = num;
    //                     break;
    // [522] if(fopen::pathcmp#0!='C') goto fopen::@12 -- vbuz1_neq_vbuc1_then_la1 
    lda #'C'
    cmp.z pathcmp
    bne __b12
    // fopen::@19
    // __channel = num
    // [523] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z num
    ldy.z sp
    sta __stdio_file+$44,y
    jmp __b12
    // fopen::@18
  __b18:
    // __device = num
    // [524] ((char *)&__stdio_file+$42)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z num
    ldy.z sp
    sta __stdio_file+$42,y
    jmp __b12
    // fopen::@17
  __b17:
    // __logical = num
    // [525] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z num
    ldy.z sp
    sta __stdio_file+$40,y
    jmp __b12
    // fopen::@13
  __b13:
    // atoi(path + 1)
    // [526] atoi::str#0 = fopen::path#13 + 1 -- pbuz1=pbuz1_plus_1 
    inc.z atoi.str
    bne !+
    inc.z atoi.str+1
  !:
    // [527] call atoi
    // [1254] phi from fopen::@13 to atoi [phi:fopen::@13->atoi]
    // [1254] phi atoi::str#2 = atoi::str#0 [phi:fopen::@13->atoi#0] -- register_copy 
    jsr atoi
    // atoi(path + 1)
    // [528] atoi::return#3 = atoi::return#2
    // fopen::@30
    // [529] fopen::$26 = atoi::return#3
    // num = (char)atoi(path + 1)
    // [530] fopen::num#1 = (char)fopen::$26 -- vbuz1=_byte_vwsz2 
    lda.z fopen__26
    sta.z num
    // path = pathtoken + 1
    // [531] fopen::path#1 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
    clc
    lda.z pathtoken
    adc #1
    sta.z path
    lda.z pathtoken+1
    adc #0
    sta.z path+1
    jmp __b14
  .segment Data
    cbm_k_setnam1_filename: .word 0
    cbm_k_readst1_status: .byte 0
    cbm_k_close1_channel: .byte 0
}
.segment Code
  // system_reset
system_reset: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 0
    // system_reset::bank_set_bram1
    // BRAM = bank
    // [533] BRAM = system_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // system_reset::bank_set_brom1
    // BROM = bank
    // [534] BROM = system_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // system_reset::@1
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // system_reset::@return
    // }
    // [536] return 
}
  // flash_read
// __zp($ea) unsigned long flash_read(char x, __zp($70) char y, char w, char b, unsigned int r, __zp($4c) struct $2 *fp, __zp($2c) char *flash_ram_address)
flash_read: {
    .const x = 2
    .const r = $200
    .label b = 8
    .label read_bytes = $34
    .label flash_ram_address = $2c
    .label flash_bytes = $ea
    /// Holds the amount of bytes actually read in the memory to be flashed.
    .label flash_row_total = $5d
    .label y = $70
    .label fp = $4c
    .label return = $ea
    // textcolor(WHITE)
    // [538] call textcolor
    // [171] phi from flash_read to textcolor [phi:flash_read->textcolor]
    // [171] phi textcolor::color#16 = WHITE [phi:flash_read->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [539] phi from flash_read to flash_read::@5 [phi:flash_read->flash_read::@5]
    // flash_read::@5
    // gotoxy(x, y)
    // [540] call gotoxy
    // [189] phi from flash_read::@5 to gotoxy [phi:flash_read::@5->gotoxy]
    // [189] phi gotoxy::y#18 = $1f [phi:flash_read::@5->gotoxy#0] -- vbuz1=vbuc1 
    lda #$1f
    sta.z gotoxy.y
    // [189] phi gotoxy::x#18 = flash_read::x#0 [phi:flash_read::@5->gotoxy#1] -- vbuz1=vbuc1 
    lda #x
    sta.z gotoxy.x
    jsr gotoxy
    // [541] phi from flash_read::@5 to flash_read::@1 [phi:flash_read::@5->flash_read::@1]
    // [541] phi flash_read::y#3 = $1f [phi:flash_read::@5->flash_read::@1#0] -- vbuz1=vbuc1 
    lda #$1f
    sta.z y
    // [541] phi flash_read::flash_bytes#2 = 0 [phi:flash_read::@5->flash_read::@1#1] -- vduz1=vduc1 
    lda #<0
    sta.z flash_bytes
    sta.z flash_bytes+1
    lda #<0>>$10
    sta.z flash_bytes+2
    lda #>0>>$10
    sta.z flash_bytes+3
    // [541] phi flash_read::flash_row_total#3 = 0 [phi:flash_read::@5->flash_read::@1#2] -- vwuz1=vwuc1 
    lda #<0
    sta.z flash_row_total
    sta.z flash_row_total+1
    // [541] phi flash_read::flash_ram_address#2 = (char *) 16384 [phi:flash_read::@5->flash_read::@1#3] -- pbuz1=pbuc1 
    lda #<$4000
    sta.z flash_ram_address
    lda #>$4000
    sta.z flash_ram_address+1
  // We read b bytes at a time, and each b bytes we plot a dot.
  // Every r bytes we move to the next line.
    // flash_read::@1
  __b1:
    // fgets(flash_ram_address, b, fp)
    // [542] fgets::ptr#2 = flash_read::flash_ram_address#2 -- pbuz1=pbuz2 
    lda.z flash_ram_address
    sta.z fgets.ptr
    lda.z flash_ram_address+1
    sta.z fgets.ptr+1
    // [543] fgets::stream#0 = flash_read::fp#0
    // [544] call fgets
    jsr fgets
    // [545] fgets::return#5 = fgets::return#1
    // flash_read::@6
    // read_bytes = fgets(flash_ram_address, b, fp)
    // [546] flash_read::read_bytes#1 = fgets::return#5
    // while (read_bytes = fgets(flash_ram_address, b, fp))
    // [547] if(0!=flash_read::read_bytes#1) goto flash_read::@2 -- 0_neq_vwuz1_then_la1 
    lda.z read_bytes
    ora.z read_bytes+1
    bne __b2
    // flash_read::@return
    // }
    // [548] return 
    rts
    // flash_read::@2
  __b2:
    // if (flash_row_total == r)
    // [549] if(flash_read::flash_row_total#3!=flash_read::r#0) goto flash_read::@3 -- vwuz1_neq_vwuc1_then_la1 
    lda.z flash_row_total+1
    cmp #>r
    bne __b3
    lda.z flash_row_total
    cmp #<r
    bne __b3
    // flash_read::@4
    // gotoxy(x, ++y);
    // [550] flash_read::y#0 = ++ flash_read::y#3 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [551] gotoxy::y#14 = flash_read::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [552] call gotoxy
    // [189] phi from flash_read::@4 to gotoxy [phi:flash_read::@4->gotoxy]
    // [189] phi gotoxy::y#18 = gotoxy::y#14 [phi:flash_read::@4->gotoxy#0] -- register_copy 
    // [189] phi gotoxy::x#18 = flash_read::x#0 [phi:flash_read::@4->gotoxy#1] -- vbuz1=vbuc1 
    lda #x
    sta.z gotoxy.x
    jsr gotoxy
    // [553] phi from flash_read::@4 to flash_read::@3 [phi:flash_read::@4->flash_read::@3]
    // [553] phi flash_read::y#8 = flash_read::y#0 [phi:flash_read::@4->flash_read::@3#0] -- register_copy 
    // [553] phi flash_read::flash_row_total#4 = 0 [phi:flash_read::@4->flash_read::@3#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z flash_row_total
    sta.z flash_row_total+1
    // [553] phi from flash_read::@2 to flash_read::@3 [phi:flash_read::@2->flash_read::@3]
    // [553] phi flash_read::y#8 = flash_read::y#3 [phi:flash_read::@2->flash_read::@3#0] -- register_copy 
    // [553] phi flash_read::flash_row_total#4 = flash_read::flash_row_total#3 [phi:flash_read::@2->flash_read::@3#1] -- register_copy 
    // flash_read::@3
  __b3:
    // cputc('+')
    // [554] stackpush(char) = '+' -- _stackpushbyte_=vbuc1 
    lda #'+'
    pha
    // [555] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // flash_ram_address += read_bytes
    // [557] flash_read::flash_ram_address#0 = flash_read::flash_ram_address#2 + flash_read::read_bytes#1 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z flash_ram_address
    adc.z read_bytes
    sta.z flash_ram_address
    lda.z flash_ram_address+1
    adc.z read_bytes+1
    sta.z flash_ram_address+1
    // flash_bytes += read_bytes
    // [558] flash_read::flash_bytes#1 = flash_read::flash_bytes#2 + flash_read::read_bytes#1 -- vduz1=vduz1_plus_vwuz2 
    lda.z flash_bytes
    clc
    adc.z read_bytes
    sta.z flash_bytes
    lda.z flash_bytes+1
    adc.z read_bytes+1
    sta.z flash_bytes+1
    lda.z flash_bytes+2
    adc #0
    sta.z flash_bytes+2
    lda.z flash_bytes+3
    adc #0
    sta.z flash_bytes+3
    // flash_row_total += read_bytes
    // [559] flash_read::flash_row_total#1 = flash_read::flash_row_total#4 + flash_read::read_bytes#1 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z flash_row_total
    adc.z read_bytes
    sta.z flash_row_total
    lda.z flash_row_total+1
    adc.z read_bytes+1
    sta.z flash_row_total+1
    // [541] phi from flash_read::@3 to flash_read::@1 [phi:flash_read::@3->flash_read::@1]
    // [541] phi flash_read::y#3 = flash_read::y#8 [phi:flash_read::@3->flash_read::@1#0] -- register_copy 
    // [541] phi flash_read::flash_bytes#2 = flash_read::flash_bytes#1 [phi:flash_read::@3->flash_read::@1#1] -- register_copy 
    // [541] phi flash_read::flash_row_total#3 = flash_read::flash_row_total#1 [phi:flash_read::@3->flash_read::@1#2] -- register_copy 
    // [541] phi flash_read::flash_ram_address#2 = flash_read::flash_ram_address#0 [phi:flash_read::@3->flash_read::@1#3] -- register_copy 
    jmp __b1
}
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($5d) void (*putc)(char), __zp($47) const char *s)
printf_str: {
    .label c = $4e
    .label s = $47
    .label putc = $5d
    // [561] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [561] phi printf_str::s#27 = printf_str::s#28 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [562] printf_str::c#1 = *printf_str::s#27 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta.z c
    // [563] printf_str::s#0 = ++ printf_str::s#27 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [564] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // printf_str::@return
    // }
    // [565] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [566] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [567] callexecute *printf_str::putc#28  -- call__deref_pprz1 
    jsr icall2
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
    // Outside Flow
  icall2:
    jmp (putc)
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
// int fclose(__zp($57) struct $2 *stream)
fclose: {
    .label fclose__1 = $b0
    .label fclose__4 = $4e
    .label fclose__6 = $39
    .label sp = $39
    .label cbm_k_readst1_return = $b0
    .label cbm_k_readst2_return = $4e
    .label stream = $57
    // unsigned char sp = (unsigned char)stream
    // [569] fclose::sp#0 = (char)fclose::stream#0 -- vbuz1=_byte_pssz2 
    lda.z stream
    sta.z sp
    // cbm_k_chkin(__logical)
    // [570] fclose::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    tay
    lda __stdio_file+$40,y
    sta cbm_k_chkin1_channel
    // fclose::cbm_k_chkin1
    // char status
    // [571] fclose::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fclose::cbm_k_readst1
    // char status
    // [573] fclose::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [575] fclose::cbm_k_readst1_return#0 = fclose::cbm_k_readst1_status -- vbuz1=vbum2 
    sta.z cbm_k_readst1_return
    // fclose::cbm_k_readst1_@return
    // }
    // [576] fclose::cbm_k_readst1_return#1 = fclose::cbm_k_readst1_return#0
    // fclose::@3
    // cbm_k_readst()
    // [577] fclose::$1 = fclose::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [578] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$1 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fclose__1
    ldy.z sp
    sta __stdio_file+$46,y
    // if (__status)
    // [579] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@1 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b1
    // fclose::@return
    // }
    // [580] return 
    rts
    // fclose::@1
  __b1:
    // cbm_k_close(__logical)
    // [581] fclose::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbuz2 
    ldy.z sp
    lda __stdio_file+$40,y
    sta cbm_k_close1_channel
    // fclose::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // fclose::cbm_k_readst2
    // char status
    // [583] fclose::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [585] fclose::cbm_k_readst2_return#0 = fclose::cbm_k_readst2_status -- vbuz1=vbum2 
    sta.z cbm_k_readst2_return
    // fclose::cbm_k_readst2_@return
    // }
    // [586] fclose::cbm_k_readst2_return#1 = fclose::cbm_k_readst2_return#0
    // fclose::@4
    // cbm_k_readst()
    // [587] fclose::$4 = fclose::cbm_k_readst2_return#1
    // __status = cbm_k_readst()
    // [588] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$4 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fclose__4
    ldy.z sp
    sta __stdio_file+$46,y
    // if (__status)
    // [589] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@2 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b2
    rts
    // fclose::@2
  __b2:
    // __logical = 0
    // [590] ((char *)&__stdio_file+$40)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #0
    ldy.z sp
    sta __stdio_file+$40,y
    // __device = 0
    // [591] ((char *)&__stdio_file+$42)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [592] ((char *)&__stdio_file+$44)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbuz1=vbuc2 
    sta __stdio_file+$44,y
    // __filename
    // [593] fclose::$6 = fclose::sp#0 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z fclose__6
    // *__filename = '\0'
    // [594] ((char *)&__stdio_file)[fclose::$6] = '@' -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #'@'
    ldy.z fclose__6
    sta __stdio_file,y
    // __stdio_filecount--;
    // [595] __stdio_filecount = -- __stdio_filecount -- vbum1=_dec_vbum1 
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
  // flash_smc
// unsigned int flash_smc(char x, __zp($b8) char y, char w, __zp($60) unsigned int smc_bytes_total, char b, unsigned int smc_row_total, __zp($69) char *smc_ram_ptr)
flash_smc: {
    .const x = 2
    .const smc_row_total = $200
    .label flash_smc__25 = $ae
    .label flash_smc__26 = $ae
    .label cx16_k_i2c_write_byte4_device = $c8
    .label cx16_k_i2c_write_byte4_offset = $c2
    .label cx16_k_i2c_write_byte4_value = $b9
    .label cx16_k_i2c_write_byte4_result = $b1
    .label cx16_k_i2c_write_byte5_device = $e4
    .label cx16_k_i2c_write_byte5_offset = $e3
    .label cx16_k_i2c_write_byte5_value = $e0
    .label cx16_k_i2c_write_byte5_result = $cf
    .label cx16_k_i2c_write_byte1_return = $39
    .label smc_bootloader_start = $39
    .label smc_bootloader_not_activated1 = $2c
    // Wait an other 5 seconds to ensure the bootloader is activated.
    .label smc_bootloader_activation_countdown = $dc
    .label x1 = $ba
    .label smc_bootloader_not_activated = $2c
    .label x2 = $be
    // Wait an other 5 seconds to ensure the bootloader is activated.
    .label smc_bootloader_activation_countdown_1 = $67
    .label smc_byte_upload = $aa
    .label smc_ram_ptr = $69
    .label smc_bytes_checksum = $ae
    .label smc_package_flashed = $79
    .label smc_commit_result = $2c
    .label smc_attempts_flashed = $6e
    .label smc_bytes_flashed = $52
    .label smc_row_bytes = $54
    .label smc_attempts_total = $71
    .label y = $b8
    .label smc_bytes_total = $60
    .label smc_package_committed = $dd
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [596] flash_smc::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [597] flash_smc::cx16_k_i2c_write_byte1_offset = $8f -- vbum1=vbuc1 
    lda #$8f
    sta cx16_k_i2c_write_byte1_offset
    // [598] flash_smc::cx16_k_i2c_write_byte1_value = $31 -- vbum1=vbuc1 
    lda #$31
    sta cx16_k_i2c_write_byte1_value
    // flash_smc::cx16_k_i2c_write_byte1
    // unsigned char result
    // [599] flash_smc::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
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
    // [601] flash_smc::cx16_k_i2c_write_byte1_return#0 = flash_smc::cx16_k_i2c_write_byte1_result -- vbuz1=vbum2 
    lda cx16_k_i2c_write_byte1_result
    sta.z cx16_k_i2c_write_byte1_return
    // flash_smc::cx16_k_i2c_write_byte1_@return
    // }
    // [602] flash_smc::cx16_k_i2c_write_byte1_return#1 = flash_smc::cx16_k_i2c_write_byte1_return#0
    // flash_smc::@27
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [603] flash_smc::smc_bootloader_start#0 = flash_smc::cx16_k_i2c_write_byte1_return#1
    // if(smc_bootloader_start)
    // [604] if(0==flash_smc::smc_bootloader_start#0) goto flash_smc::@3 -- 0_eq_vbuz1_then_la1 
    lda.z smc_bootloader_start
    beq __b2
    // [605] phi from flash_smc::@27 to flash_smc::@2 [phi:flash_smc::@27->flash_smc::@2]
    // flash_smc::@2
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [606] call snprintf_init
    // [1314] phi from flash_smc::@2 to snprintf_init [phi:flash_smc::@2->snprintf_init]
    // [1314] phi snprintf_init::s#8 = flash_smc::info_text [phi:flash_smc::@2->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [607] phi from flash_smc::@2 to flash_smc::@30 [phi:flash_smc::@2->flash_smc::@30]
    // flash_smc::@30
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [608] call printf_str
    // [560] phi from flash_smc::@30 to printf_str [phi:flash_smc::@30->printf_str]
    // [560] phi printf_str::putc#28 = &snputc [phi:flash_smc::@30->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [560] phi printf_str::s#28 = flash_smc::s [phi:flash_smc::@30->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@31
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [609] printf_uchar::uvalue#3 = flash_smc::smc_bootloader_start#0
    // [610] call printf_uchar
    // [1100] phi from flash_smc::@31 to printf_uchar [phi:flash_smc::@31->printf_uchar]
    // [1100] phi printf_uchar::format_zero_padding#10 = 0 [phi:flash_smc::@31->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1100] phi printf_uchar::format_min_length#10 = 0 [phi:flash_smc::@31->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1100] phi printf_uchar::putc#10 = &snputc [phi:flash_smc::@31->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1100] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:flash_smc::@31->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [1100] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#3 [phi:flash_smc::@31->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // flash_smc::@32
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [611] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [612] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [614] call info_line
    // [301] phi from flash_smc::@32 to info_line [phi:flash_smc::@32->info_line]
    // [301] phi info_line::info_text#13 = flash_smc::info_text [phi:flash_smc::@32->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    // flash_smc::@33
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [615] flash_smc::cx16_k_i2c_write_byte2_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte2_device
    // [616] flash_smc::cx16_k_i2c_write_byte2_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte2_offset
    // [617] flash_smc::cx16_k_i2c_write_byte2_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte2_value
    // flash_smc::cx16_k_i2c_write_byte2
    // unsigned char result
    // [618] flash_smc::cx16_k_i2c_write_byte2_result = 0 -- vbum1=vbuc1 
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
    // [620] return 
    rts
    // [621] phi from flash_smc::@27 to flash_smc::@3 [phi:flash_smc::@27->flash_smc::@3]
  __b2:
    // [621] phi flash_smc::smc_bootloader_activation_countdown#22 = $14 [phi:flash_smc::@27->flash_smc::@3#0] -- vbuz1=vbuc1 
    lda #$14
    sta.z smc_bootloader_activation_countdown
    // flash_smc::@3
  __b3:
    // while(smc_bootloader_activation_countdown)
    // [622] if(0!=flash_smc::smc_bootloader_activation_countdown#22) goto flash_smc::@4 -- 0_neq_vbuz1_then_la1 
    lda.z smc_bootloader_activation_countdown
    beq !__b4+
    jmp __b4
  !__b4:
    // [623] phi from flash_smc::@3 flash_smc::@34 to flash_smc::@9 [phi:flash_smc::@3/flash_smc::@34->flash_smc::@9]
  __b5:
    // [623] phi flash_smc::smc_bootloader_activation_countdown#23 = 5 [phi:flash_smc::@3/flash_smc::@34->flash_smc::@9#0] -- vbuz1=vbuc1 
    lda #5
    sta.z smc_bootloader_activation_countdown_1
    // flash_smc::@9
  __b9:
    // while(smc_bootloader_activation_countdown)
    // [624] if(0!=flash_smc::smc_bootloader_activation_countdown#23) goto flash_smc::@11 -- 0_neq_vbuz1_then_la1 
    lda.z smc_bootloader_activation_countdown_1
    beq !__b13+
    jmp __b13
  !__b13:
    // flash_smc::@10
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [625] cx16_k_i2c_read_byte::device = $42 -- vbuz1=vbuc1 
    lda #$42
    sta.z cx16_k_i2c_read_byte.device
    // [626] cx16_k_i2c_read_byte::offset = $8e -- vbuz1=vbuc1 
    lda #$8e
    sta.z cx16_k_i2c_read_byte.offset
    // [627] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [628] cx16_k_i2c_read_byte::return#3 = cx16_k_i2c_read_byte::return#1
    // flash_smc::@39
    // smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [629] flash_smc::smc_bootloader_not_activated#1 = cx16_k_i2c_read_byte::return#3
    // if(smc_bootloader_not_activated)
    // [630] if(0==flash_smc::smc_bootloader_not_activated#1) goto flash_smc::@1 -- 0_eq_vwuz1_then_la1 
    lda.z smc_bootloader_not_activated
    ora.z smc_bootloader_not_activated+1
    beq __b1
    // [631] phi from flash_smc::@39 to flash_smc::@14 [phi:flash_smc::@39->flash_smc::@14]
    // flash_smc::@14
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [632] call snprintf_init
    // [1314] phi from flash_smc::@14 to snprintf_init [phi:flash_smc::@14->snprintf_init]
    // [1314] phi snprintf_init::s#8 = flash_smc::info_text [phi:flash_smc::@14->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [633] phi from flash_smc::@14 to flash_smc::@46 [phi:flash_smc::@14->flash_smc::@46]
    // flash_smc::@46
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [634] call printf_str
    // [560] phi from flash_smc::@46 to printf_str [phi:flash_smc::@46->printf_str]
    // [560] phi printf_str::putc#28 = &snputc [phi:flash_smc::@46->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [560] phi printf_str::s#28 = flash_smc::s5 [phi:flash_smc::@46->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@47
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [635] printf_uint::uvalue#1 = flash_smc::smc_bootloader_not_activated#1
    // [636] call printf_uint
    // [1183] phi from flash_smc::@47 to printf_uint [phi:flash_smc::@47->printf_uint]
    // [1183] phi printf_uint::format_zero_padding#10 = 0 [phi:flash_smc::@47->printf_uint#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uint.format_zero_padding
    // [1183] phi printf_uint::format_min_length#10 = 0 [phi:flash_smc::@47->printf_uint#1] -- vbuz1=vbuc1 
    sta.z printf_uint.format_min_length
    // [1183] phi printf_uint::putc#10 = &snputc [phi:flash_smc::@47->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [1183] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:flash_smc::@47->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [1183] phi printf_uint::uvalue#6 = printf_uint::uvalue#1 [phi:flash_smc::@47->printf_uint#4] -- register_copy 
    jsr printf_uint
    // flash_smc::@48
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [637] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [638] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [640] call info_line
    // [301] phi from flash_smc::@48 to info_line [phi:flash_smc::@48->info_line]
    // [301] phi info_line::info_text#13 = flash_smc::info_text [phi:flash_smc::@48->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    rts
    // [641] phi from flash_smc::@39 to flash_smc::@1 [phi:flash_smc::@39->flash_smc::@1]
    // flash_smc::@1
  __b1:
    // textcolor(WHITE)
    // [642] call textcolor
    // [171] phi from flash_smc::@1 to textcolor [phi:flash_smc::@1->textcolor]
    // [171] phi textcolor::color#16 = WHITE [phi:flash_smc::@1->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [643] phi from flash_smc::@1 to flash_smc::@45 [phi:flash_smc::@1->flash_smc::@45]
    // flash_smc::@45
    // gotoxy(x, y)
    // [644] call gotoxy
    // [189] phi from flash_smc::@45 to gotoxy [phi:flash_smc::@45->gotoxy]
    // [189] phi gotoxy::y#18 = $1f [phi:flash_smc::@45->gotoxy#0] -- vbuz1=vbuc1 
    lda #$1f
    sta.z gotoxy.y
    // [189] phi gotoxy::x#18 = flash_smc::x#0 [phi:flash_smc::@45->gotoxy#1] -- vbuz1=vbuc1 
    lda #x
    sta.z gotoxy.x
    jsr gotoxy
    // [645] phi from flash_smc::@45 to flash_smc::@15 [phi:flash_smc::@45->flash_smc::@15]
    // [645] phi flash_smc::y#33 = $1f [phi:flash_smc::@45->flash_smc::@15#0] -- vbuz1=vbuc1 
    lda #$1f
    sta.z y
    // [645] phi flash_smc::smc_attempts_total#21 = 0 [phi:flash_smc::@45->flash_smc::@15#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z smc_attempts_total
    sta.z smc_attempts_total+1
    // [645] phi flash_smc::smc_row_bytes#14 = 0 [phi:flash_smc::@45->flash_smc::@15#2] -- vwuz1=vwuc1 
    sta.z smc_row_bytes
    sta.z smc_row_bytes+1
    // [645] phi flash_smc::smc_ram_ptr#13 = (char *) 16384 [phi:flash_smc::@45->flash_smc::@15#3] -- pbuz1=pbuc1 
    lda #<$4000
    sta.z smc_ram_ptr
    lda #>$4000
    sta.z smc_ram_ptr+1
    // [645] phi flash_smc::smc_bytes_flashed#13 = 0 [phi:flash_smc::@45->flash_smc::@15#4] -- vwuz1=vwuc1 
    lda #<0
    sta.z smc_bytes_flashed
    sta.z smc_bytes_flashed+1
    // [645] phi from flash_smc::@18 to flash_smc::@15 [phi:flash_smc::@18->flash_smc::@15]
    // [645] phi flash_smc::y#33 = flash_smc::y#23 [phi:flash_smc::@18->flash_smc::@15#0] -- register_copy 
    // [645] phi flash_smc::smc_attempts_total#21 = flash_smc::smc_attempts_total#17 [phi:flash_smc::@18->flash_smc::@15#1] -- register_copy 
    // [645] phi flash_smc::smc_row_bytes#14 = flash_smc::smc_row_bytes#10 [phi:flash_smc::@18->flash_smc::@15#2] -- register_copy 
    // [645] phi flash_smc::smc_ram_ptr#13 = flash_smc::smc_ram_ptr#10 [phi:flash_smc::@18->flash_smc::@15#3] -- register_copy 
    // [645] phi flash_smc::smc_bytes_flashed#13 = flash_smc::smc_bytes_flashed#12 [phi:flash_smc::@18->flash_smc::@15#4] -- register_copy 
    // flash_smc::@15
  __b15:
    // while(smc_bytes_flashed < smc_bytes_total)
    // [646] if(flash_smc::smc_bytes_flashed#13<flash_smc::smc_bytes_total#0) goto flash_smc::@17 -- vwuz1_lt_vwuz2_then_la1 
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
    // [647] flash_smc::cx16_k_i2c_write_byte3_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte3_device
    // [648] flash_smc::cx16_k_i2c_write_byte3_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte3_offset
    // [649] flash_smc::cx16_k_i2c_write_byte3_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte3_value
    // flash_smc::cx16_k_i2c_write_byte3
    // unsigned char result
    // [650] flash_smc::cx16_k_i2c_write_byte3_result = 0 -- vbum1=vbuc1 
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
    // [652] phi from flash_smc::@15 to flash_smc::@17 [phi:flash_smc::@15->flash_smc::@17]
  __b8:
    // [652] phi flash_smc::y#23 = flash_smc::y#33 [phi:flash_smc::@15->flash_smc::@17#0] -- register_copy 
    // [652] phi flash_smc::smc_attempts_total#17 = flash_smc::smc_attempts_total#21 [phi:flash_smc::@15->flash_smc::@17#1] -- register_copy 
    // [652] phi flash_smc::smc_row_bytes#10 = flash_smc::smc_row_bytes#14 [phi:flash_smc::@15->flash_smc::@17#2] -- register_copy 
    // [652] phi flash_smc::smc_ram_ptr#10 = flash_smc::smc_ram_ptr#13 [phi:flash_smc::@15->flash_smc::@17#3] -- register_copy 
    // [652] phi flash_smc::smc_bytes_flashed#12 = flash_smc::smc_bytes_flashed#13 [phi:flash_smc::@15->flash_smc::@17#4] -- register_copy 
    // [652] phi flash_smc::smc_attempts_flashed#19 = 0 [phi:flash_smc::@15->flash_smc::@17#5] -- vbuz1=vbuc1 
    lda #0
    sta.z smc_attempts_flashed
    // [652] phi flash_smc::smc_package_committed#2 = 0 [phi:flash_smc::@15->flash_smc::@17#6] -- vbuz1=vbuc1 
    sta.z smc_package_committed
    // flash_smc::@17
  __b17:
    // while(!smc_package_committed && smc_attempts_flashed < 10)
    // [653] if(0!=flash_smc::smc_package_committed#2) goto flash_smc::@18 -- 0_neq_vbuz1_then_la1 
    lda.z smc_package_committed
    bne __b18
    // flash_smc::@61
    // [654] if(flash_smc::smc_attempts_flashed#19<$a) goto flash_smc::@19 -- vbuz1_lt_vbuc1_then_la1 
    lda.z smc_attempts_flashed
    cmp #$a
    bcc __b10
    // flash_smc::@18
  __b18:
    // if(smc_attempts_flashed >= 10)
    // [655] if(flash_smc::smc_attempts_flashed#19<$a) goto flash_smc::@15 -- vbuz1_lt_vbuc1_then_la1 
    lda.z smc_attempts_flashed
    cmp #$a
    bcc __b15
    // [656] phi from flash_smc::@18 to flash_smc::@26 [phi:flash_smc::@18->flash_smc::@26]
    // flash_smc::@26
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [657] call snprintf_init
    // [1314] phi from flash_smc::@26 to snprintf_init [phi:flash_smc::@26->snprintf_init]
    // [1314] phi snprintf_init::s#8 = flash_smc::info_text [phi:flash_smc::@26->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [658] phi from flash_smc::@26 to flash_smc::@58 [phi:flash_smc::@26->flash_smc::@58]
    // flash_smc::@58
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [659] call printf_str
    // [560] phi from flash_smc::@58 to printf_str [phi:flash_smc::@58->printf_str]
    // [560] phi printf_str::putc#28 = &snputc [phi:flash_smc::@58->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [560] phi printf_str::s#28 = flash_smc::s10 [phi:flash_smc::@58->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@59
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [660] printf_uint::uvalue#5 = flash_smc::smc_bytes_flashed#12 -- vwuz1=vwuz2 
    lda.z smc_bytes_flashed
    sta.z printf_uint.uvalue
    lda.z smc_bytes_flashed+1
    sta.z printf_uint.uvalue+1
    // [661] call printf_uint
    // [1183] phi from flash_smc::@59 to printf_uint [phi:flash_smc::@59->printf_uint]
    // [1183] phi printf_uint::format_zero_padding#10 = 1 [phi:flash_smc::@59->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [1183] phi printf_uint::format_min_length#10 = 4 [phi:flash_smc::@59->printf_uint#1] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_uint.format_min_length
    // [1183] phi printf_uint::putc#10 = &snputc [phi:flash_smc::@59->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [1183] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:flash_smc::@59->printf_uint#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uint.format_radix
    // [1183] phi printf_uint::uvalue#6 = printf_uint::uvalue#5 [phi:flash_smc::@59->printf_uint#4] -- register_copy 
    jsr printf_uint
    // flash_smc::@60
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [662] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [663] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [665] call info_line
    // [301] phi from flash_smc::@60 to info_line [phi:flash_smc::@60->info_line]
    // [301] phi info_line::info_text#13 = flash_smc::info_text [phi:flash_smc::@60->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    rts
    // [666] phi from flash_smc::@61 to flash_smc::@19 [phi:flash_smc::@61->flash_smc::@19]
  __b10:
    // [666] phi flash_smc::smc_bytes_checksum#2 = 0 [phi:flash_smc::@61->flash_smc::@19#0] -- vbuz1=vbuc1 
    lda #0
    sta.z smc_bytes_checksum
    // [666] phi flash_smc::smc_ram_ptr#12 = flash_smc::smc_ram_ptr#10 [phi:flash_smc::@61->flash_smc::@19#1] -- register_copy 
    // [666] phi flash_smc::smc_package_flashed#2 = 0 [phi:flash_smc::@61->flash_smc::@19#2] -- vwuz1=vwuc1 
    sta.z smc_package_flashed
    sta.z smc_package_flashed+1
    // flash_smc::@19
  __b19:
    // while(smc_package_flashed < 8)
    // [667] if(flash_smc::smc_package_flashed#2<8) goto flash_smc::@20 -- vwuz1_lt_vbuc1_then_la1 
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
    // [668] flash_smc::$25 = flash_smc::smc_bytes_checksum#2 ^ $ff -- vbuz1=vbuz1_bxor_vbuc1 
    lda #$ff
    eor.z flash_smc__25
    sta.z flash_smc__25
    // (smc_bytes_checksum ^ 0xFF)+1
    // [669] flash_smc::$26 = flash_smc::$25 + 1 -- vbuz1=vbuz1_plus_1 
    inc.z flash_smc__26
    // unsigned char smc_checksum_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, (smc_bytes_checksum ^ 0xFF)+1)
    // [670] flash_smc::cx16_k_i2c_write_byte5_device = $42 -- vbuz1=vbuc1 
    lda #$42
    sta.z cx16_k_i2c_write_byte5_device
    // [671] flash_smc::cx16_k_i2c_write_byte5_offset = $80 -- vbuz1=vbuc1 
    lda #$80
    sta.z cx16_k_i2c_write_byte5_offset
    // [672] flash_smc::cx16_k_i2c_write_byte5_value = flash_smc::$26 -- vbuz1=vbuz2 
    lda.z flash_smc__26
    sta.z cx16_k_i2c_write_byte5_value
    // flash_smc::cx16_k_i2c_write_byte5
    // unsigned char result
    // [673] flash_smc::cx16_k_i2c_write_byte5_result = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cx16_k_i2c_write_byte5_result
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
    // [675] cx16_k_i2c_read_byte::device = $42 -- vbuz1=vbuc1 
    lda #$42
    sta.z cx16_k_i2c_read_byte.device
    // [676] cx16_k_i2c_read_byte::offset = $81 -- vbuz1=vbuc1 
    lda #$81
    sta.z cx16_k_i2c_read_byte.offset
    // [677] call cx16_k_i2c_read_byte
    // Now send the commit command.
    jsr cx16_k_i2c_read_byte
    // [678] cx16_k_i2c_read_byte::return#4 = cx16_k_i2c_read_byte::return#1
    // flash_smc::@49
    // [679] flash_smc::smc_commit_result#0 = cx16_k_i2c_read_byte::return#4
    // if(smc_commit_result == 1)
    // [680] if(flash_smc::smc_commit_result#0==1) goto flash_smc::@23 -- vwuz1_eq_vbuc1_then_la1 
    lda.z smc_commit_result+1
    bne !+
    lda.z smc_commit_result
    cmp #1
    beq __b23
  !:
    // flash_smc::@22
    // smc_ram_ptr -= 8
    // [681] flash_smc::smc_ram_ptr#1 = flash_smc::smc_ram_ptr#12 - 8 -- pbuz1=pbuz1_minus_vbuc1 
    sec
    lda.z smc_ram_ptr
    sbc #8
    sta.z smc_ram_ptr
    lda.z smc_ram_ptr+1
    sbc #0
    sta.z smc_ram_ptr+1
    // smc_attempts_flashed++;
    // [682] flash_smc::smc_attempts_flashed#1 = ++ flash_smc::smc_attempts_flashed#19 -- vbuz1=_inc_vbuz1 
    inc.z smc_attempts_flashed
    // [652] phi from flash_smc::@22 to flash_smc::@17 [phi:flash_smc::@22->flash_smc::@17]
    // [652] phi flash_smc::y#23 = flash_smc::y#23 [phi:flash_smc::@22->flash_smc::@17#0] -- register_copy 
    // [652] phi flash_smc::smc_attempts_total#17 = flash_smc::smc_attempts_total#17 [phi:flash_smc::@22->flash_smc::@17#1] -- register_copy 
    // [652] phi flash_smc::smc_row_bytes#10 = flash_smc::smc_row_bytes#10 [phi:flash_smc::@22->flash_smc::@17#2] -- register_copy 
    // [652] phi flash_smc::smc_ram_ptr#10 = flash_smc::smc_ram_ptr#1 [phi:flash_smc::@22->flash_smc::@17#3] -- register_copy 
    // [652] phi flash_smc::smc_bytes_flashed#12 = flash_smc::smc_bytes_flashed#12 [phi:flash_smc::@22->flash_smc::@17#4] -- register_copy 
    // [652] phi flash_smc::smc_attempts_flashed#19 = flash_smc::smc_attempts_flashed#1 [phi:flash_smc::@22->flash_smc::@17#5] -- register_copy 
    // [652] phi flash_smc::smc_package_committed#2 = flash_smc::smc_package_committed#2 [phi:flash_smc::@22->flash_smc::@17#6] -- register_copy 
    jmp __b17
    // flash_smc::@23
  __b23:
    // if (smc_row_bytes == smc_row_total)
    // [683] if(flash_smc::smc_row_bytes#10!=flash_smc::smc_row_total#0) goto flash_smc::@24 -- vwuz1_neq_vwuc1_then_la1 
    lda.z smc_row_bytes+1
    cmp #>smc_row_total
    bne __b24
    lda.z smc_row_bytes
    cmp #<smc_row_total
    bne __b24
    // flash_smc::@25
    // gotoxy(x, ++y);
    // [684] flash_smc::y#0 = ++ flash_smc::y#23 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [685] gotoxy::y#16 = flash_smc::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [686] call gotoxy
    // [189] phi from flash_smc::@25 to gotoxy [phi:flash_smc::@25->gotoxy]
    // [189] phi gotoxy::y#18 = gotoxy::y#16 [phi:flash_smc::@25->gotoxy#0] -- register_copy 
    // [189] phi gotoxy::x#18 = flash_smc::x#0 [phi:flash_smc::@25->gotoxy#1] -- vbuz1=vbuc1 
    lda #x
    sta.z gotoxy.x
    jsr gotoxy
    // [687] phi from flash_smc::@25 to flash_smc::@24 [phi:flash_smc::@25->flash_smc::@24]
    // [687] phi flash_smc::y#35 = flash_smc::y#0 [phi:flash_smc::@25->flash_smc::@24#0] -- register_copy 
    // [687] phi flash_smc::smc_row_bytes#4 = 0 [phi:flash_smc::@25->flash_smc::@24#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z smc_row_bytes
    sta.z smc_row_bytes+1
    // [687] phi from flash_smc::@23 to flash_smc::@24 [phi:flash_smc::@23->flash_smc::@24]
    // [687] phi flash_smc::y#35 = flash_smc::y#23 [phi:flash_smc::@23->flash_smc::@24#0] -- register_copy 
    // [687] phi flash_smc::smc_row_bytes#4 = flash_smc::smc_row_bytes#10 [phi:flash_smc::@23->flash_smc::@24#1] -- register_copy 
    // flash_smc::@24
  __b24:
    // cputc('*')
    // [688] stackpush(char) = '*' -- _stackpushbyte_=vbuc1 
    lda #'*'
    pha
    // [689] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_bytes_flashed += 8
    // [691] flash_smc::smc_bytes_flashed#1 = flash_smc::smc_bytes_flashed#12 + 8 -- vwuz1=vwuz1_plus_vbuc1 
    lda #8
    clc
    adc.z smc_bytes_flashed
    sta.z smc_bytes_flashed
    bcc !+
    inc.z smc_bytes_flashed+1
  !:
    // smc_row_bytes += 8
    // [692] flash_smc::smc_row_bytes#1 = flash_smc::smc_row_bytes#4 + 8 -- vwuz1=vwuz1_plus_vbuc1 
    lda #8
    clc
    adc.z smc_row_bytes
    sta.z smc_row_bytes
    bcc !+
    inc.z smc_row_bytes+1
  !:
    // smc_attempts_total += smc_attempts_flashed
    // [693] flash_smc::smc_attempts_total#1 = flash_smc::smc_attempts_total#17 + flash_smc::smc_attempts_flashed#19 -- vwuz1=vwuz1_plus_vbuz2 
    lda.z smc_attempts_flashed
    clc
    adc.z smc_attempts_total
    sta.z smc_attempts_total
    bcc !+
    inc.z smc_attempts_total+1
  !:
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [694] call snprintf_init
    // [1314] phi from flash_smc::@24 to snprintf_init [phi:flash_smc::@24->snprintf_init]
    // [1314] phi snprintf_init::s#8 = flash_smc::info_text [phi:flash_smc::@24->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [695] phi from flash_smc::@24 to flash_smc::@50 [phi:flash_smc::@24->flash_smc::@50]
    // flash_smc::@50
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [696] call printf_str
    // [560] phi from flash_smc::@50 to printf_str [phi:flash_smc::@50->printf_str]
    // [560] phi printf_str::putc#28 = &snputc [phi:flash_smc::@50->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [560] phi printf_str::s#28 = flash_smc::s6 [phi:flash_smc::@50->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@51
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [697] printf_uint::uvalue#2 = flash_smc::smc_bytes_flashed#1 -- vwuz1=vwuz2 
    lda.z smc_bytes_flashed
    sta.z printf_uint.uvalue
    lda.z smc_bytes_flashed+1
    sta.z printf_uint.uvalue+1
    // [698] call printf_uint
    // [1183] phi from flash_smc::@51 to printf_uint [phi:flash_smc::@51->printf_uint]
    // [1183] phi printf_uint::format_zero_padding#10 = 1 [phi:flash_smc::@51->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [1183] phi printf_uint::format_min_length#10 = 5 [phi:flash_smc::@51->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [1183] phi printf_uint::putc#10 = &snputc [phi:flash_smc::@51->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [1183] phi printf_uint::format_radix#10 = DECIMAL [phi:flash_smc::@51->printf_uint#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [1183] phi printf_uint::uvalue#6 = printf_uint::uvalue#2 [phi:flash_smc::@51->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [699] phi from flash_smc::@51 to flash_smc::@52 [phi:flash_smc::@51->flash_smc::@52]
    // flash_smc::@52
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [700] call printf_str
    // [560] phi from flash_smc::@52 to printf_str [phi:flash_smc::@52->printf_str]
    // [560] phi printf_str::putc#28 = &snputc [phi:flash_smc::@52->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [560] phi printf_str::s#28 = flash_smc::s7 [phi:flash_smc::@52->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@53
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [701] printf_uint::uvalue#3 = flash_smc::smc_bytes_total#0 -- vwuz1=vwuz2 
    lda.z smc_bytes_total
    sta.z printf_uint.uvalue
    lda.z smc_bytes_total+1
    sta.z printf_uint.uvalue+1
    // [702] call printf_uint
    // [1183] phi from flash_smc::@53 to printf_uint [phi:flash_smc::@53->printf_uint]
    // [1183] phi printf_uint::format_zero_padding#10 = 1 [phi:flash_smc::@53->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [1183] phi printf_uint::format_min_length#10 = 5 [phi:flash_smc::@53->printf_uint#1] -- vbuz1=vbuc1 
    lda #5
    sta.z printf_uint.format_min_length
    // [1183] phi printf_uint::putc#10 = &snputc [phi:flash_smc::@53->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [1183] phi printf_uint::format_radix#10 = DECIMAL [phi:flash_smc::@53->printf_uint#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [1183] phi printf_uint::uvalue#6 = printf_uint::uvalue#3 [phi:flash_smc::@53->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [703] phi from flash_smc::@53 to flash_smc::@54 [phi:flash_smc::@53->flash_smc::@54]
    // flash_smc::@54
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [704] call printf_str
    // [560] phi from flash_smc::@54 to printf_str [phi:flash_smc::@54->printf_str]
    // [560] phi printf_str::putc#28 = &snputc [phi:flash_smc::@54->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [560] phi printf_str::s#28 = flash_smc::s8 [phi:flash_smc::@54->printf_str#1] -- pbuz1=pbuc1 
    lda #<s8
    sta.z printf_str.s
    lda #>s8
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@55
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [705] printf_uint::uvalue#4 = flash_smc::smc_attempts_total#1 -- vwuz1=vwuz2 
    lda.z smc_attempts_total
    sta.z printf_uint.uvalue
    lda.z smc_attempts_total+1
    sta.z printf_uint.uvalue+1
    // [706] call printf_uint
    // [1183] phi from flash_smc::@55 to printf_uint [phi:flash_smc::@55->printf_uint]
    // [1183] phi printf_uint::format_zero_padding#10 = 1 [phi:flash_smc::@55->printf_uint#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uint.format_zero_padding
    // [1183] phi printf_uint::format_min_length#10 = 2 [phi:flash_smc::@55->printf_uint#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uint.format_min_length
    // [1183] phi printf_uint::putc#10 = &snputc [phi:flash_smc::@55->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [1183] phi printf_uint::format_radix#10 = DECIMAL [phi:flash_smc::@55->printf_uint#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uint.format_radix
    // [1183] phi printf_uint::uvalue#6 = printf_uint::uvalue#4 [phi:flash_smc::@55->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [707] phi from flash_smc::@55 to flash_smc::@56 [phi:flash_smc::@55->flash_smc::@56]
    // flash_smc::@56
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [708] call printf_str
    // [560] phi from flash_smc::@56 to printf_str [phi:flash_smc::@56->printf_str]
    // [560] phi printf_str::putc#28 = &snputc [phi:flash_smc::@56->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [560] phi printf_str::s#28 = flash_smc::s9 [phi:flash_smc::@56->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@57
    // sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total)
    // [709] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [710] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [712] call info_line
    // [301] phi from flash_smc::@57 to info_line [phi:flash_smc::@57->info_line]
    // [301] phi info_line::info_text#13 = flash_smc::info_text [phi:flash_smc::@57->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    // [652] phi from flash_smc::@57 to flash_smc::@17 [phi:flash_smc::@57->flash_smc::@17]
    // [652] phi flash_smc::y#23 = flash_smc::y#35 [phi:flash_smc::@57->flash_smc::@17#0] -- register_copy 
    // [652] phi flash_smc::smc_attempts_total#17 = flash_smc::smc_attempts_total#1 [phi:flash_smc::@57->flash_smc::@17#1] -- register_copy 
    // [652] phi flash_smc::smc_row_bytes#10 = flash_smc::smc_row_bytes#1 [phi:flash_smc::@57->flash_smc::@17#2] -- register_copy 
    // [652] phi flash_smc::smc_ram_ptr#10 = flash_smc::smc_ram_ptr#12 [phi:flash_smc::@57->flash_smc::@17#3] -- register_copy 
    // [652] phi flash_smc::smc_bytes_flashed#12 = flash_smc::smc_bytes_flashed#1 [phi:flash_smc::@57->flash_smc::@17#4] -- register_copy 
    // [652] phi flash_smc::smc_attempts_flashed#19 = flash_smc::smc_attempts_flashed#19 [phi:flash_smc::@57->flash_smc::@17#5] -- register_copy 
    // [652] phi flash_smc::smc_package_committed#2 = 1 [phi:flash_smc::@57->flash_smc::@17#6] -- vbuz1=vbuc1 
    lda #1
    sta.z smc_package_committed
    jmp __b17
    // flash_smc::@20
  __b20:
    // unsigned char smc_byte_upload = *smc_ram_ptr
    // [713] flash_smc::smc_byte_upload#0 = *flash_smc::smc_ram_ptr#12 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (smc_ram_ptr),y
    sta.z smc_byte_upload
    // smc_ram_ptr++;
    // [714] flash_smc::smc_ram_ptr#0 = ++ flash_smc::smc_ram_ptr#12 -- pbuz1=_inc_pbuz1 
    inc.z smc_ram_ptr
    bne !+
    inc.z smc_ram_ptr+1
  !:
    // smc_bytes_checksum += smc_byte_upload
    // [715] flash_smc::smc_bytes_checksum#1 = flash_smc::smc_bytes_checksum#2 + flash_smc::smc_byte_upload#0 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z smc_bytes_checksum
    clc
    adc.z smc_byte_upload
    sta.z smc_bytes_checksum
    // unsigned char smc_upload_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, smc_byte_upload)
    // [716] flash_smc::cx16_k_i2c_write_byte4_device = $42 -- vbuz1=vbuc1 
    lda #$42
    sta.z cx16_k_i2c_write_byte4_device
    // [717] flash_smc::cx16_k_i2c_write_byte4_offset = $80 -- vbuz1=vbuc1 
    lda #$80
    sta.z cx16_k_i2c_write_byte4_offset
    // [718] flash_smc::cx16_k_i2c_write_byte4_value = flash_smc::smc_byte_upload#0 -- vbuz1=vbuz2 
    lda.z smc_byte_upload
    sta.z cx16_k_i2c_write_byte4_value
    // flash_smc::cx16_k_i2c_write_byte4
    // unsigned char result
    // [719] flash_smc::cx16_k_i2c_write_byte4_result = 0 -- vbuz1=vbuc1 
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
    // [721] flash_smc::smc_package_flashed#1 = ++ flash_smc::smc_package_flashed#2 -- vwuz1=_inc_vwuz1 
    inc.z smc_package_flashed
    bne !+
    inc.z smc_package_flashed+1
  !:
    // [666] phi from flash_smc::@28 to flash_smc::@19 [phi:flash_smc::@28->flash_smc::@19]
    // [666] phi flash_smc::smc_bytes_checksum#2 = flash_smc::smc_bytes_checksum#1 [phi:flash_smc::@28->flash_smc::@19#0] -- register_copy 
    // [666] phi flash_smc::smc_ram_ptr#12 = flash_smc::smc_ram_ptr#0 [phi:flash_smc::@28->flash_smc::@19#1] -- register_copy 
    // [666] phi flash_smc::smc_package_flashed#2 = flash_smc::smc_package_flashed#1 [phi:flash_smc::@28->flash_smc::@19#2] -- register_copy 
    jmp __b19
    // [722] phi from flash_smc::@9 to flash_smc::@11 [phi:flash_smc::@9->flash_smc::@11]
  __b13:
    // [722] phi flash_smc::x2#2 = $10000*1 [phi:flash_smc::@9->flash_smc::@11#0] -- vduz1=vduc1 
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
    // [723] if(flash_smc::x2#2>0) goto flash_smc::@12 -- vduz1_gt_0_then_la1 
    lda.z x2+3
    bne __b12
    lda.z x2+2
    bne __b12
    lda.z x2+1
    bne __b12
    lda.z x2
    bne __b12
  !:
    // [724] phi from flash_smc::@11 to flash_smc::@13 [phi:flash_smc::@11->flash_smc::@13]
    // flash_smc::@13
    // sprintf(info_text, "Waiting an other %u seconds before flashing the SMC!", smc_bootloader_activation_countdown)
    // [725] call snprintf_init
    // [1314] phi from flash_smc::@13 to snprintf_init [phi:flash_smc::@13->snprintf_init]
    // [1314] phi snprintf_init::s#8 = flash_smc::info_text [phi:flash_smc::@13->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [726] phi from flash_smc::@13 to flash_smc::@40 [phi:flash_smc::@13->flash_smc::@40]
    // flash_smc::@40
    // sprintf(info_text, "Waiting an other %u seconds before flashing the SMC!", smc_bootloader_activation_countdown)
    // [727] call printf_str
    // [560] phi from flash_smc::@40 to printf_str [phi:flash_smc::@40->printf_str]
    // [560] phi printf_str::putc#28 = &snputc [phi:flash_smc::@40->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [560] phi printf_str::s#28 = flash_smc::s3 [phi:flash_smc::@40->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@41
    // sprintf(info_text, "Waiting an other %u seconds before flashing the SMC!", smc_bootloader_activation_countdown)
    // [728] printf_uchar::uvalue#5 = flash_smc::smc_bootloader_activation_countdown#23 -- vbuz1=vbuz2 
    lda.z smc_bootloader_activation_countdown_1
    sta.z printf_uchar.uvalue
    // [729] call printf_uchar
    // [1100] phi from flash_smc::@41 to printf_uchar [phi:flash_smc::@41->printf_uchar]
    // [1100] phi printf_uchar::format_zero_padding#10 = 0 [phi:flash_smc::@41->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1100] phi printf_uchar::format_min_length#10 = 0 [phi:flash_smc::@41->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1100] phi printf_uchar::putc#10 = &snputc [phi:flash_smc::@41->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1100] phi printf_uchar::format_radix#10 = DECIMAL [phi:flash_smc::@41->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1100] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#5 [phi:flash_smc::@41->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [730] phi from flash_smc::@41 to flash_smc::@42 [phi:flash_smc::@41->flash_smc::@42]
    // flash_smc::@42
    // sprintf(info_text, "Waiting an other %u seconds before flashing the SMC!", smc_bootloader_activation_countdown)
    // [731] call printf_str
    // [560] phi from flash_smc::@42 to printf_str [phi:flash_smc::@42->printf_str]
    // [560] phi printf_str::putc#28 = &snputc [phi:flash_smc::@42->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [560] phi printf_str::s#28 = flash_smc::s4 [phi:flash_smc::@42->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@43
    // sprintf(info_text, "Waiting an other %u seconds before flashing the SMC!", smc_bootloader_activation_countdown)
    // [732] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [733] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [735] call info_line
    // [301] phi from flash_smc::@43 to info_line [phi:flash_smc::@43->info_line]
    // [301] phi info_line::info_text#13 = flash_smc::info_text [phi:flash_smc::@43->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    // flash_smc::@44
    // smc_bootloader_activation_countdown--;
    // [736] flash_smc::smc_bootloader_activation_countdown#3 = -- flash_smc::smc_bootloader_activation_countdown#23 -- vbuz1=_dec_vbuz1 
    dec.z smc_bootloader_activation_countdown_1
    // [623] phi from flash_smc::@44 to flash_smc::@9 [phi:flash_smc::@44->flash_smc::@9]
    // [623] phi flash_smc::smc_bootloader_activation_countdown#23 = flash_smc::smc_bootloader_activation_countdown#3 [phi:flash_smc::@44->flash_smc::@9#0] -- register_copy 
    jmp __b9
    // flash_smc::@12
  __b12:
    // for(unsigned long x=65536*1; x>0; x--)
    // [737] flash_smc::x2#1 = -- flash_smc::x2#2 -- vduz1=_dec_vduz1 
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
    // [722] phi from flash_smc::@12 to flash_smc::@11 [phi:flash_smc::@12->flash_smc::@11]
    // [722] phi flash_smc::x2#2 = flash_smc::x2#1 [phi:flash_smc::@12->flash_smc::@11#0] -- register_copy 
    jmp __b11
    // flash_smc::@4
  __b4:
    // unsigned int smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [738] cx16_k_i2c_read_byte::device = $42 -- vbuz1=vbuc1 
    lda #$42
    sta.z cx16_k_i2c_read_byte.device
    // [739] cx16_k_i2c_read_byte::offset = $8e -- vbuz1=vbuc1 
    lda #$8e
    sta.z cx16_k_i2c_read_byte.offset
    // [740] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [741] cx16_k_i2c_read_byte::return#2 = cx16_k_i2c_read_byte::return#1
    // flash_smc::@34
    // [742] flash_smc::smc_bootloader_not_activated1#0 = cx16_k_i2c_read_byte::return#2
    // if(smc_bootloader_not_activated)
    // [743] if(0!=flash_smc::smc_bootloader_not_activated1#0) goto flash_smc::@6 -- 0_neq_vwuz1_then_la1 
    lda.z smc_bootloader_not_activated1
    ora.z smc_bootloader_not_activated1+1
    bne __b14
    jmp __b5
    // [744] phi from flash_smc::@34 to flash_smc::@6 [phi:flash_smc::@34->flash_smc::@6]
  __b14:
    // [744] phi flash_smc::x1#2 = $10000*6 [phi:flash_smc::@34->flash_smc::@6#0] -- vduz1=vduc1 
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
    // [745] if(flash_smc::x1#2>0) goto flash_smc::@7 -- vduz1_gt_0_then_la1 
    lda.z x1+3
    bne __b7
    lda.z x1+2
    bne __b7
    lda.z x1+1
    bne __b7
    lda.z x1
    bne __b7
  !:
    // [746] phi from flash_smc::@6 to flash_smc::@8 [phi:flash_smc::@6->flash_smc::@8]
    // flash_smc::@8
    // sprintf(info_text, "Press POWER and RESET on the CX16 within %u seconds!", smc_bootloader_activation_countdown)
    // [747] call snprintf_init
    // [1314] phi from flash_smc::@8 to snprintf_init [phi:flash_smc::@8->snprintf_init]
    // [1314] phi snprintf_init::s#8 = flash_smc::info_text [phi:flash_smc::@8->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [748] phi from flash_smc::@8 to flash_smc::@35 [phi:flash_smc::@8->flash_smc::@35]
    // flash_smc::@35
    // sprintf(info_text, "Press POWER and RESET on the CX16 within %u seconds!", smc_bootloader_activation_countdown)
    // [749] call printf_str
    // [560] phi from flash_smc::@35 to printf_str [phi:flash_smc::@35->printf_str]
    // [560] phi printf_str::putc#28 = &snputc [phi:flash_smc::@35->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [560] phi printf_str::s#28 = flash_smc::s1 [phi:flash_smc::@35->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@36
    // sprintf(info_text, "Press POWER and RESET on the CX16 within %u seconds!", smc_bootloader_activation_countdown)
    // [750] printf_uchar::uvalue#4 = flash_smc::smc_bootloader_activation_countdown#22 -- vbuz1=vbuz2 
    lda.z smc_bootloader_activation_countdown
    sta.z printf_uchar.uvalue
    // [751] call printf_uchar
    // [1100] phi from flash_smc::@36 to printf_uchar [phi:flash_smc::@36->printf_uchar]
    // [1100] phi printf_uchar::format_zero_padding#10 = 0 [phi:flash_smc::@36->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1100] phi printf_uchar::format_min_length#10 = 0 [phi:flash_smc::@36->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1100] phi printf_uchar::putc#10 = &snputc [phi:flash_smc::@36->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1100] phi printf_uchar::format_radix#10 = DECIMAL [phi:flash_smc::@36->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1100] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#4 [phi:flash_smc::@36->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [752] phi from flash_smc::@36 to flash_smc::@37 [phi:flash_smc::@36->flash_smc::@37]
    // flash_smc::@37
    // sprintf(info_text, "Press POWER and RESET on the CX16 within %u seconds!", smc_bootloader_activation_countdown)
    // [753] call printf_str
    // [560] phi from flash_smc::@37 to printf_str [phi:flash_smc::@37->printf_str]
    // [560] phi printf_str::putc#28 = &snputc [phi:flash_smc::@37->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [560] phi printf_str::s#28 = flash_smc::s2 [phi:flash_smc::@37->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // flash_smc::@38
    // sprintf(info_text, "Press POWER and RESET on the CX16 within %u seconds!", smc_bootloader_activation_countdown)
    // [754] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [755] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_line(info_text)
    // [757] call info_line
    // [301] phi from flash_smc::@38 to info_line [phi:flash_smc::@38->info_line]
    // [301] phi info_line::info_text#13 = flash_smc::info_text [phi:flash_smc::@38->info_line#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z info_line.info_text
    lda #>info_text
    sta.z info_line.info_text+1
    jsr info_line
    // flash_smc::@5
    // smc_bootloader_activation_countdown--;
    // [758] flash_smc::smc_bootloader_activation_countdown#2 = -- flash_smc::smc_bootloader_activation_countdown#22 -- vbuz1=_dec_vbuz1 
    dec.z smc_bootloader_activation_countdown
    // [621] phi from flash_smc::@5 to flash_smc::@3 [phi:flash_smc::@5->flash_smc::@3]
    // [621] phi flash_smc::smc_bootloader_activation_countdown#22 = flash_smc::smc_bootloader_activation_countdown#2 [phi:flash_smc::@5->flash_smc::@3#0] -- register_copy 
    jmp __b3
    // flash_smc::@7
  __b7:
    // for(unsigned long x=65536*6; x>0; x--)
    // [759] flash_smc::x1#1 = -- flash_smc::x1#2 -- vduz1=_dec_vduz1 
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
    // [744] phi from flash_smc::@7 to flash_smc::@6 [phi:flash_smc::@7->flash_smc::@6]
    // [744] phi flash_smc::x1#2 = flash_smc::x1#1 [phi:flash_smc::@7->flash_smc::@6#0] -- register_copy 
    jmp __b6
  .segment Data
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
    info_text: .fill $50, 0
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
}
.segment Code
  // info_rom
// void info_rom(__zp($6b) char info_rom, __zp($ab) char info_status)
info_rom: {
    .label info_rom__7 = $aa
    .label info_rom__9 = $5f
    .label info_rom = $6b
    .label info_status = $ab
    // if(info_rom)
    // [761] if(0!=info_rom::info_rom#10) goto info_rom::@1 -- 0_neq_vbuz1_then_la1 
    lda.z info_rom
    beq !__b1+
    jmp __b1
  !__b1:
    // [762] phi from info_rom to info_rom::@3 [phi:info_rom->info_rom::@3]
    // info_rom::@3
    // sprintf(rom_name, "ROM%u - CX16", info_rom)
    // [763] call snprintf_init
    // [1314] phi from info_rom::@3 to snprintf_init [phi:info_rom::@3->snprintf_init]
    // [1314] phi snprintf_init::s#8 = info_rom::rom_name [phi:info_rom::@3->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<rom_name
    sta.z snprintf_init.s
    lda #>rom_name
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [764] phi from info_rom::@3 to info_rom::@8 [phi:info_rom::@3->info_rom::@8]
    // info_rom::@8
    // sprintf(rom_name, "ROM%u - CX16", info_rom)
    // [765] call printf_str
    // [560] phi from info_rom::@8 to printf_str [phi:info_rom::@8->printf_str]
    // [560] phi printf_str::putc#28 = &snputc [phi:info_rom::@8->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [560] phi printf_str::s#28 = info_rom::s [phi:info_rom::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@9
    // sprintf(rom_name, "ROM%u - CX16", info_rom)
    // [766] printf_uchar::uvalue#1 = info_rom::info_rom#10 -- vbuz1=vbuz2 
    lda.z info_rom
    sta.z printf_uchar.uvalue
    // [767] call printf_uchar
    // [1100] phi from info_rom::@9 to printf_uchar [phi:info_rom::@9->printf_uchar]
    // [1100] phi printf_uchar::format_zero_padding#10 = 0 [phi:info_rom::@9->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1100] phi printf_uchar::format_min_length#10 = 0 [phi:info_rom::@9->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1100] phi printf_uchar::putc#10 = &snputc [phi:info_rom::@9->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1100] phi printf_uchar::format_radix#10 = DECIMAL [phi:info_rom::@9->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1100] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#1 [phi:info_rom::@9->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [768] phi from info_rom::@9 to info_rom::@10 [phi:info_rom::@9->info_rom::@10]
    // info_rom::@10
    // sprintf(rom_name, "ROM%u - CX16", info_rom)
    // [769] call printf_str
    // [560] phi from info_rom::@10 to printf_str [phi:info_rom::@10->printf_str]
    // [560] phi printf_str::putc#28 = &snputc [phi:info_rom::@10->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [560] phi printf_str::s#28 = info_rom::s3 [phi:info_rom::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@11
    // sprintf(rom_name, "ROM%u - CX16", info_rom)
    // [770] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [771] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // info_rom::@2
  __b2:
    // strcpy(rom_detected, status_text[info_status])
    // [773] info_rom::$7 = info_rom::info_status#10 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z info_status
    asl
    sta.z info_rom__7
    // [774] strcpy::source#1 = status_text[info_rom::$7] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda status_text,y
    sta.z strcpy.source
    lda status_text+1,y
    sta.z strcpy.source+1
    // [775] call strcpy
    // [445] phi from info_rom::@2 to strcpy [phi:info_rom::@2->strcpy]
    // [445] phi strcpy::dst#0 = info_rom::rom_detected [phi:info_rom::@2->strcpy#0] -- pbuz1=pbuc1 
    lda #<rom_detected
    sta.z strcpy.dst
    lda #>rom_detected
    sta.z strcpy.dst+1
    // [445] phi strcpy::src#0 = strcpy::source#1 [phi:info_rom::@2->strcpy#1] -- register_copy 
    jsr strcpy
    // info_rom::@12
    // print_rom_led(info_rom, status_color[info_status])
    // [776] print_rom_led::chip#1 = info_rom::info_rom#10 -- vbuz1=vbuz2 
    lda.z info_rom
    sta.z print_rom_led.chip
    // [777] print_rom_led::c#1 = status_color[info_rom::info_status#10] -- vbuz1=pbuc1_derefidx_vbuz1 
    ldy.z print_rom_led.c
    lda status_color,y
    sta.z print_rom_led.c
    // [778] call print_rom_led
    // [1175] phi from info_rom::@12 to print_rom_led [phi:info_rom::@12->print_rom_led]
    // [1175] phi print_rom_led::c#2 = print_rom_led::c#1 [phi:info_rom::@12->print_rom_led#0] -- register_copy 
    // [1175] phi print_rom_led::chip#2 = print_rom_led::chip#1 [phi:info_rom::@12->print_rom_led#1] -- register_copy 
    jsr print_rom_led
    // info_rom::@13
    // info_clear(2+info_rom)
    // [779] info_clear::l#3 = 2 + info_rom::info_rom#10 -- vbuz1=vbuc1_plus_vbuz2 
    lda #2
    clc
    adc.z info_rom
    sta.z info_clear.l
    // [780] call info_clear
    // [1052] phi from info_rom::@13 to info_clear [phi:info_rom::@13->info_clear]
    // [1052] phi info_clear::l#4 = info_clear::l#3 [phi:info_rom::@13->info_clear#0] -- register_copy 
    jsr info_clear
    // [781] phi from info_rom::@13 to info_rom::@14 [phi:info_rom::@13->info_rom::@14]
    // info_rom::@14
    // printf("%s - %-8s - %02x - %-8s - %-4s", rom_name, rom_detected, rom_device_ids[info_rom], rom_device_names[info_rom], rom_size_strings[info_rom] )
    // [782] call printf_string
    // [1022] phi from info_rom::@14 to printf_string [phi:info_rom::@14->printf_string]
    // [1022] phi printf_string::str#10 = info_rom::rom_name [phi:info_rom::@14->printf_string#0] -- pbuz1=pbuc1 
    lda #<rom_name
    sta.z printf_string.str
    lda #>rom_name
    sta.z printf_string.str+1
    // [1022] phi printf_string::format_justify_left#10 = 0 [phi:info_rom::@14->printf_string#1] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_string.format_justify_left
    // [1022] phi printf_string::format_min_length#10 = 0 [phi:info_rom::@14->printf_string#2] -- vbuz1=vbuc1 
    sta.z printf_string.format_min_length
    jsr printf_string
    // [783] phi from info_rom::@14 to info_rom::@15 [phi:info_rom::@14->info_rom::@15]
    // info_rom::@15
    // printf("%s - %-8s - %02x - %-8s - %-4s", rom_name, rom_detected, rom_device_ids[info_rom], rom_device_names[info_rom], rom_size_strings[info_rom] )
    // [784] call printf_str
    // [560] phi from info_rom::@15 to printf_str [phi:info_rom::@15->printf_str]
    // [560] phi printf_str::putc#28 = &cputc [phi:info_rom::@15->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [560] phi printf_str::s#28 = info_rom::s4 [phi:info_rom::@15->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // [785] phi from info_rom::@15 to info_rom::@16 [phi:info_rom::@15->info_rom::@16]
    // info_rom::@16
    // printf("%s - %-8s - %02x - %-8s - %-4s", rom_name, rom_detected, rom_device_ids[info_rom], rom_device_names[info_rom], rom_size_strings[info_rom] )
    // [786] call printf_string
    // [1022] phi from info_rom::@16 to printf_string [phi:info_rom::@16->printf_string]
    // [1022] phi printf_string::str#10 = info_rom::rom_detected [phi:info_rom::@16->printf_string#0] -- pbuz1=pbuc1 
    lda #<rom_detected
    sta.z printf_string.str
    lda #>rom_detected
    sta.z printf_string.str+1
    // [1022] phi printf_string::format_justify_left#10 = 1 [phi:info_rom::@16->printf_string#1] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1022] phi printf_string::format_min_length#10 = 8 [phi:info_rom::@16->printf_string#2] -- vbuz1=vbuc1 
    lda #8
    sta.z printf_string.format_min_length
    jsr printf_string
    // [787] phi from info_rom::@16 to info_rom::@17 [phi:info_rom::@16->info_rom::@17]
    // info_rom::@17
    // printf("%s - %-8s - %02x - %-8s - %-4s", rom_name, rom_detected, rom_device_ids[info_rom], rom_device_names[info_rom], rom_size_strings[info_rom] )
    // [788] call printf_str
    // [560] phi from info_rom::@17 to printf_str [phi:info_rom::@17->printf_str]
    // [560] phi printf_str::putc#28 = &cputc [phi:info_rom::@17->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [560] phi printf_str::s#28 = info_rom::s4 [phi:info_rom::@17->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@18
    // printf("%s - %-8s - %02x - %-8s - %-4s", rom_name, rom_detected, rom_device_ids[info_rom], rom_device_names[info_rom], rom_size_strings[info_rom] )
    // [789] printf_uchar::uvalue#2 = rom_device_ids[info_rom::info_rom#10] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_rom
    lda rom_device_ids,y
    sta.z printf_uchar.uvalue
    // [790] call printf_uchar
    // [1100] phi from info_rom::@18 to printf_uchar [phi:info_rom::@18->printf_uchar]
    // [1100] phi printf_uchar::format_zero_padding#10 = 1 [phi:info_rom::@18->printf_uchar#0] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_uchar.format_zero_padding
    // [1100] phi printf_uchar::format_min_length#10 = 2 [phi:info_rom::@18->printf_uchar#1] -- vbuz1=vbuc1 
    lda #2
    sta.z printf_uchar.format_min_length
    // [1100] phi printf_uchar::putc#10 = &cputc [phi:info_rom::@18->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1100] phi printf_uchar::format_radix#10 = HEXADECIMAL [phi:info_rom::@18->printf_uchar#3] -- vbuz1=vbuc1 
    lda #HEXADECIMAL
    sta.z printf_uchar.format_radix
    // [1100] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#2 [phi:info_rom::@18->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [791] phi from info_rom::@18 to info_rom::@19 [phi:info_rom::@18->info_rom::@19]
    // info_rom::@19
    // printf("%s - %-8s - %02x - %-8s - %-4s", rom_name, rom_detected, rom_device_ids[info_rom], rom_device_names[info_rom], rom_size_strings[info_rom] )
    // [792] call printf_str
    // [560] phi from info_rom::@19 to printf_str [phi:info_rom::@19->printf_str]
    // [560] phi printf_str::putc#28 = &cputc [phi:info_rom::@19->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [560] phi printf_str::s#28 = info_rom::s4 [phi:info_rom::@19->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@20
    // printf("%s - %-8s - %02x - %-8s - %-4s", rom_name, rom_detected, rom_device_ids[info_rom], rom_device_names[info_rom], rom_size_strings[info_rom] )
    // [793] info_rom::$9 = info_rom::info_rom#10 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z info_rom
    asl
    sta.z info_rom__9
    // [794] printf_string::str#6 = rom_device_names[info_rom::$9] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda rom_device_names,y
    sta.z printf_string.str
    lda rom_device_names+1,y
    sta.z printf_string.str+1
    // [795] call printf_string
    // [1022] phi from info_rom::@20 to printf_string [phi:info_rom::@20->printf_string]
    // [1022] phi printf_string::str#10 = printf_string::str#6 [phi:info_rom::@20->printf_string#0] -- register_copy 
    // [1022] phi printf_string::format_justify_left#10 = 1 [phi:info_rom::@20->printf_string#1] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1022] phi printf_string::format_min_length#10 = 8 [phi:info_rom::@20->printf_string#2] -- vbuz1=vbuc1 
    lda #8
    sta.z printf_string.format_min_length
    jsr printf_string
    // [796] phi from info_rom::@20 to info_rom::@21 [phi:info_rom::@20->info_rom::@21]
    // info_rom::@21
    // printf("%s - %-8s - %02x - %-8s - %-4s", rom_name, rom_detected, rom_device_ids[info_rom], rom_device_names[info_rom], rom_size_strings[info_rom] )
    // [797] call printf_str
    // [560] phi from info_rom::@21 to printf_str [phi:info_rom::@21->printf_str]
    // [560] phi printf_str::putc#28 = &cputc [phi:info_rom::@21->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [560] phi printf_str::s#28 = info_rom::s4 [phi:info_rom::@21->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@22
    // printf("%s - %-8s - %02x - %-8s - %-4s", rom_name, rom_detected, rom_device_ids[info_rom], rom_device_names[info_rom], rom_size_strings[info_rom] )
    // [798] printf_string::str#7 = rom_size_strings[info_rom::$9] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z info_rom__9
    lda rom_size_strings,y
    sta.z printf_string.str
    lda rom_size_strings+1,y
    sta.z printf_string.str+1
    // [799] call printf_string
    // [1022] phi from info_rom::@22 to printf_string [phi:info_rom::@22->printf_string]
    // [1022] phi printf_string::str#10 = printf_string::str#7 [phi:info_rom::@22->printf_string#0] -- register_copy 
    // [1022] phi printf_string::format_justify_left#10 = 1 [phi:info_rom::@22->printf_string#1] -- vbuz1=vbuc1 
    lda #1
    sta.z printf_string.format_justify_left
    // [1022] phi printf_string::format_min_length#10 = 4 [phi:info_rom::@22->printf_string#2] -- vbuz1=vbuc1 
    lda #4
    sta.z printf_string.format_min_length
    jsr printf_string
    // info_rom::@return
    // }
    // [800] return 
    rts
    // [801] phi from info_rom to info_rom::@1 [phi:info_rom->info_rom::@1]
    // info_rom::@1
  __b1:
    // sprintf(rom_name, "ROM%u - CARD", info_rom)
    // [802] call snprintf_init
    // [1314] phi from info_rom::@1 to snprintf_init [phi:info_rom::@1->snprintf_init]
    // [1314] phi snprintf_init::s#8 = info_rom::rom_name [phi:info_rom::@1->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<rom_name
    sta.z snprintf_init.s
    lda #>rom_name
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [803] phi from info_rom::@1 to info_rom::@4 [phi:info_rom::@1->info_rom::@4]
    // info_rom::@4
    // sprintf(rom_name, "ROM%u - CARD", info_rom)
    // [804] call printf_str
    // [560] phi from info_rom::@4 to printf_str [phi:info_rom::@4->printf_str]
    // [560] phi printf_str::putc#28 = &snputc [phi:info_rom::@4->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [560] phi printf_str::s#28 = info_rom::s [phi:info_rom::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@5
    // sprintf(rom_name, "ROM%u - CARD", info_rom)
    // [805] printf_uchar::uvalue#0 = info_rom::info_rom#10 -- vbuz1=vbuz2 
    lda.z info_rom
    sta.z printf_uchar.uvalue
    // [806] call printf_uchar
    // [1100] phi from info_rom::@5 to printf_uchar [phi:info_rom::@5->printf_uchar]
    // [1100] phi printf_uchar::format_zero_padding#10 = 0 [phi:info_rom::@5->printf_uchar#0] -- vbuz1=vbuc1 
    lda #0
    sta.z printf_uchar.format_zero_padding
    // [1100] phi printf_uchar::format_min_length#10 = 0 [phi:info_rom::@5->printf_uchar#1] -- vbuz1=vbuc1 
    sta.z printf_uchar.format_min_length
    // [1100] phi printf_uchar::putc#10 = &snputc [phi:info_rom::@5->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1100] phi printf_uchar::format_radix#10 = DECIMAL [phi:info_rom::@5->printf_uchar#3] -- vbuz1=vbuc1 
    lda #DECIMAL
    sta.z printf_uchar.format_radix
    // [1100] phi printf_uchar::uvalue#10 = printf_uchar::uvalue#0 [phi:info_rom::@5->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [807] phi from info_rom::@5 to info_rom::@6 [phi:info_rom::@5->info_rom::@6]
    // info_rom::@6
    // sprintf(rom_name, "ROM%u - CARD", info_rom)
    // [808] call printf_str
    // [560] phi from info_rom::@6 to printf_str [phi:info_rom::@6->printf_str]
    // [560] phi printf_str::putc#28 = &snputc [phi:info_rom::@6->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [560] phi printf_str::s#28 = info_rom::s1 [phi:info_rom::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // info_rom::@7
    // sprintf(rom_name, "ROM%u - CARD", info_rom)
    // [809] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [810] callexecute snputc  -- call_vprc1 
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
}
.segment Code
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __zp($6f) char mapbase, __zp($6c) char config)
screenlayer: {
    .label screenlayer__0 = $e6
    .label screenlayer__1 = $6f
    .label screenlayer__2 = $e7
    .label screenlayer__5 = $6c
    .label screenlayer__6 = $6c
    .label screenlayer__7 = $e2
    .label screenlayer__8 = $e2
    .label screenlayer__9 = $d8
    .label screenlayer__10 = $d8
    .label screenlayer__11 = $d8
    .label screenlayer__12 = $d9
    .label screenlayer__13 = $d9
    .label screenlayer__14 = $d9
    .label screenlayer__16 = $e2
    .label screenlayer__17 = $cb
    .label screenlayer__18 = $d8
    .label screenlayer__19 = $d9
    .label mapbase = $6f
    .label config = $6c
    .label mapbase_offset = $cc
    .label y = $68
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [812] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [813] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [814] *((char *)&__conio+2) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+2
    // mapbase >> 7
    // [815] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbuz1=vbuz2_ror_7 
    lda.z mapbase
    rol
    rol
    and #1
    sta.z screenlayer__0
    // __conio.mapbase_bank = mapbase >> 7
    // [816] *((char *)&__conio+5) = screenlayer::$0 -- _deref_pbuc1=vbuz1 
    sta __conio+5
    // (mapbase)<<1
    // [817] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z screenlayer__1
    // MAKEWORD((mapbase)<<1,0)
    // [818] screenlayer::$2 = screenlayer::$1 w= 0 -- vwuz1=vbuz2_word_vbuc1 
    lda #0
    ldy.z screenlayer__1
    sty.z screenlayer__2+1
    sta.z screenlayer__2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [819] *((unsigned int *)&__conio+3) = screenlayer::$2 -- _deref_pwuc1=vwuz1 
    sta __conio+3
    tya
    sta __conio+3+1
    // config & VERA_LAYER_WIDTH_MASK
    // [820] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbuz1=vbuz2_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and.z config
    sta.z screenlayer__7
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [821] screenlayer::$8 = screenlayer::$7 >> 4 -- vbuz1=vbuz1_ror_4 
    lda.z screenlayer__8
    lsr
    lsr
    lsr
    lsr
    sta.z screenlayer__8
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [822] *((char *)&__conio+8) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+8
    // config & VERA_LAYER_HEIGHT_MASK
    // [823] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbuz1=vbuz1_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and.z screenlayer__5
    sta.z screenlayer__5
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [824] screenlayer::$6 = screenlayer::$5 >> 6 -- vbuz1=vbuz1_ror_6 
    lda.z screenlayer__6
    rol
    rol
    rol
    and #3
    sta.z screenlayer__6
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [825] *((char *)&__conio+9) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbuz1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+9
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [826] screenlayer::$16 = screenlayer::$8 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z screenlayer__16
    // [827] *((unsigned int *)&__conio+$a) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    ldy.z screenlayer__16
    lda VERA_LAYER_SKIP,y
    sta __conio+$a
    lda VERA_LAYER_SKIP+1,y
    sta __conio+$a+1
    // vera_dc_hscale_temp == 0x80
    // [828] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z screenlayer__9
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [829] screenlayer::$18 = (char)screenlayer::$9
    // [830] screenlayer::$10 = $28 << screenlayer::$18 -- vbuz1=vbuc1_rol_vbuz1 
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
    // [831] screenlayer::$11 = screenlayer::$10 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z screenlayer__11
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [832] *((char *)&__conio+6) = screenlayer::$11 -- _deref_pbuc1=vbuz1 
    lda.z screenlayer__11
    sta __conio+6
    // vera_dc_vscale_temp == 0x80
    // [833] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z screenlayer__12
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [834] screenlayer::$19 = (char)screenlayer::$12
    // [835] screenlayer::$13 = $1e << screenlayer::$19 -- vbuz1=vbuc1_rol_vbuz1 
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
    // [836] screenlayer::$14 = screenlayer::$13 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z screenlayer__14
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [837] *((char *)&__conio+7) = screenlayer::$14 -- _deref_pbuc1=vbuz1 
    lda.z screenlayer__14
    sta __conio+7
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [838] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+3) -- vwuz1=_deref_pwuc1 
    lda __conio+3
    sta.z mapbase_offset
    lda __conio+3+1
    sta.z mapbase_offset+1
    // [839] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [839] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [839] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [840] if(screenlayer::y#2<=*((char *)&__conio+7)) goto screenlayer::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+7
    cmp.z y
    bcs __b2
    // screenlayer::@return
    // }
    // [841] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [842] screenlayer::$17 = screenlayer::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z screenlayer__17
    // [843] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbuz1=vwuz2 
    tay
    lda.z mapbase_offset
    sta __conio+$15,y
    lda.z mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [844] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+$a) -- vwuz1=vwuz1_plus__deref_pwuc1 
    clc
    lda.z mapbase_offset
    adc __conio+$a
    sta.z mapbase_offset
    lda.z mapbase_offset+1
    adc __conio+$a+1
    sta.z mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [845] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [839] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [839] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [839] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
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
    // [846] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [847] if(0!=((char *)&__conio+$f)[*((char *)&__conio+2)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [848] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // [849] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [850] call gotoxy
    // [189] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [189] phi gotoxy::y#18 = 0 [phi:cscroll::@3->gotoxy#0] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.y
    // [189] phi gotoxy::x#18 = 0 [phi:cscroll::@3->gotoxy#1] -- vbuz1=vbuc1 
    sta.z gotoxy.x
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [851] return 
    rts
    // [852] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [853] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [854] gotoxy::y#3 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
    lda __conio+7
    sta.z gotoxy.y
    // [855] call gotoxy
    // [189] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [189] phi gotoxy::y#18 = gotoxy::y#3 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [189] phi gotoxy::x#18 = 0 [phi:cscroll::@5->gotoxy#1] -- vbuz1=vbuc1 
    lda #0
    sta.z gotoxy.x
    jsr gotoxy
    // [856] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [857] call clearline
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
    // [858] ((char *)&__conio+$f)[*((char *)&__conio+2)] = scroll::onoff#0 -- pbuc1_derefidx_(_deref_pbuc2)=vbuc3 
    lda #onoff
    ldy __conio+2
    sta __conio+$f,y
    // scroll::@return
    // }
    // [859] return 
    rts
}
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    .label clrscr__0 = $5f
    .label clrscr__1 = $ca
    .label clrscr__2 = $c9
    .label line_text = $5d
    .label l = $c7
    .label ch = $5d
    .label c = $ac
    // unsigned int line_text = __conio.mapbase_offset
    // [860] clrscr::line_text#0 = *((unsigned int *)&__conio+3) -- vwuz1=_deref_pwuc1 
    lda __conio+3
    sta.z line_text
    lda __conio+3+1
    sta.z line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [861] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [862] clrscr::$0 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clrscr__0
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [863] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [864] clrscr::l#0 = *((char *)&__conio+9) -- vbuz1=_deref_pbuc1 
    lda __conio+9
    sta.z l
    // [865] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [865] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [865] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [866] clrscr::$1 = byte0  clrscr::ch#0 -- vbuz1=_byte0_vwuz2 
    lda.z ch
    sta.z clrscr__1
    // *VERA_ADDRX_L = BYTE0(ch)
    // [867] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbuz1 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [868] clrscr::$2 = byte1  clrscr::ch#0 -- vbuz1=_byte1_vwuz2 
    lda.z ch+1
    sta.z clrscr__2
    // *VERA_ADDRX_M = BYTE1(ch)
    // [869] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth+1
    // [870] clrscr::c#0 = *((char *)&__conio+8) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+8
    inc
    sta.z c
    // [871] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [871] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [872] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [873] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [874] clrscr::c#1 = -- clrscr::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [875] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [876] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+$a) -- vwuz1=vwuz1_plus__deref_pwuc1 
    clc
    lda.z line_text
    adc __conio+$a
    sta.z line_text
    lda.z line_text+1
    adc __conio+$a+1
    sta.z line_text+1
    // l--;
    // [877] clrscr::l#1 = -- clrscr::l#4 -- vbuz1=_dec_vbuz1 
    dec.z l
    // while(l)
    // [878] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbuz1_then_la1 
    lda.z l
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [879] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y = 0
    // [880] *((char *)&__conio+1) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+1
    // __conio.offset = __conio.mapbase_offset
    // [881] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+3) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+3
    sta __conio+$13
    lda __conio+3+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [882] return 
    rts
}
  // frame
// Draw a line horizontal from a given xy position and a given length.
// The line should calculate the matching characters to draw and glue them.
// So it first needs to peek the characters at the given position.
// And then calculate the resulting characters to draw.
// void frame(char x0, char y0, __zp($af) char x1, __zp($39) char y1)
frame: {
    .label w = $ca
    .label h = $c9
    .label x = $4e
    .label y = $b0
    .label mask = $3f
    .label c = $43
    .label x_1 = $aa
    .label y_1 = $6d
    .label x1 = $af
    .label y1 = $39
    // unsigned char w = x1 - x0
    // [884] frame::w#0 = frame::x1#16 - frame::x#0 -- vbuz1=vbuz2_minus_vbuz3 
    lda.z x1
    sec
    sbc.z x
    sta.z w
    // unsigned char h = y1 - y0
    // [885] frame::h#0 = frame::y1#16 - frame::y#0 -- vbuz1=vbuz2_minus_vbuz3 
    lda.z y1
    sec
    sbc.z y
    sta.z h
    // unsigned char mask = frame_maskxy(x, y)
    // [886] frame_maskxy::x#0 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z frame_maskxy.x
    // [887] frame_maskxy::y#0 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z frame_maskxy.y
    // [888] call frame_maskxy
    // [1352] phi from frame to frame_maskxy [phi:frame->frame_maskxy]
    // [1352] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#0 [phi:frame->frame_maskxy#0] -- register_copy 
    // [1352] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#0 [phi:frame->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // unsigned char mask = frame_maskxy(x, y)
    // [889] frame_maskxy::return#13 = frame_maskxy::return#12
    // frame::@13
    // [890] frame::mask#0 = frame_maskxy::return#13
    // mask |= 0b0110
    // [891] frame::mask#1 = frame::mask#0 | 6 -- vbuz1=vbuz1_bor_vbuc1 
    lda #6
    ora.z mask
    sta.z mask
    // unsigned char c = frame_char(mask)
    // [892] frame_char::mask#0 = frame::mask#1
    // [893] call frame_char
  // Add a corner.
    // [1378] phi from frame::@13 to frame_char [phi:frame::@13->frame_char]
    // [1378] phi frame_char::mask#10 = frame_char::mask#0 [phi:frame::@13->frame_char#0] -- register_copy 
    jsr frame_char
    // unsigned char c = frame_char(mask)
    // [894] frame_char::return#13 = frame_char::return#12
    // frame::@14
    // [895] frame::c#0 = frame_char::return#13
    // cputcxy(x, y, c)
    // [896] cputcxy::x#0 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [897] cputcxy::y#0 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [898] cputcxy::c#0 = frame::c#0
    // [899] call cputcxy
    // [1044] phi from frame::@14 to cputcxy [phi:frame::@14->cputcxy]
    // [1044] phi cputcxy::c#11 = cputcxy::c#0 [phi:frame::@14->cputcxy#0] -- register_copy 
    // [1044] phi cputcxy::y#11 = cputcxy::y#0 [phi:frame::@14->cputcxy#1] -- register_copy 
    // [1044] phi cputcxy::x#11 = cputcxy::x#0 [phi:frame::@14->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@15
    // if(w>=2)
    // [900] if(frame::w#0<2) goto frame::@36 -- vbuz1_lt_vbuc1_then_la1 
    lda.z w
    cmp #2
    bcs !__b36+
    jmp __b36
  !__b36:
    // frame::@2
    // x++;
    // [901] frame::x#1 = ++ frame::x#0 -- vbuz1=_inc_vbuz2 
    lda.z x
    inc
    sta.z x_1
    // [902] phi from frame::@2 frame::@21 to frame::@4 [phi:frame::@2/frame::@21->frame::@4]
    // [902] phi frame::x#10 = frame::x#1 [phi:frame::@2/frame::@21->frame::@4#0] -- register_copy 
    // frame::@4
  __b4:
    // while(x < x1)
    // [903] if(frame::x#10<frame::x1#16) goto frame::@5 -- vbuz1_lt_vbuz2_then_la1 
    lda.z x_1
    cmp.z x1
    bcs !__b5+
    jmp __b5
  !__b5:
    // [904] phi from frame::@36 frame::@4 to frame::@1 [phi:frame::@36/frame::@4->frame::@1]
    // [904] phi frame::x#24 = frame::x#30 [phi:frame::@36/frame::@4->frame::@1#0] -- register_copy 
    // frame::@1
  __b1:
    // frame_maskxy(x, y)
    // [905] frame_maskxy::x#1 = frame::x#24 -- vbuz1=vbuz2 
    lda.z x_1
    sta.z frame_maskxy.x
    // [906] frame_maskxy::y#1 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z frame_maskxy.y
    // [907] call frame_maskxy
    // [1352] phi from frame::@1 to frame_maskxy [phi:frame::@1->frame_maskxy]
    // [1352] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#1 [phi:frame::@1->frame_maskxy#0] -- register_copy 
    // [1352] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#1 [phi:frame::@1->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [908] frame_maskxy::return#14 = frame_maskxy::return#12
    // frame::@16
    // mask = frame_maskxy(x, y)
    // [909] frame::mask#2 = frame_maskxy::return#14
    // mask |= 0b0011
    // [910] frame::mask#3 = frame::mask#2 | 3 -- vbuz1=vbuz1_bor_vbuc1 
    lda #3
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [911] frame_char::mask#1 = frame::mask#3
    // [912] call frame_char
    // [1378] phi from frame::@16 to frame_char [phi:frame::@16->frame_char]
    // [1378] phi frame_char::mask#10 = frame_char::mask#1 [phi:frame::@16->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [913] frame_char::return#14 = frame_char::return#12
    // frame::@17
    // c = frame_char(mask)
    // [914] frame::c#1 = frame_char::return#14
    // cputcxy(x, y, c)
    // [915] cputcxy::x#1 = frame::x#24 -- vbuz1=vbuz2 
    lda.z x_1
    sta.z cputcxy.x
    // [916] cputcxy::y#1 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [917] cputcxy::c#1 = frame::c#1
    // [918] call cputcxy
    // [1044] phi from frame::@17 to cputcxy [phi:frame::@17->cputcxy]
    // [1044] phi cputcxy::c#11 = cputcxy::c#1 [phi:frame::@17->cputcxy#0] -- register_copy 
    // [1044] phi cputcxy::y#11 = cputcxy::y#1 [phi:frame::@17->cputcxy#1] -- register_copy 
    // [1044] phi cputcxy::x#11 = cputcxy::x#1 [phi:frame::@17->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@18
    // if(h>=2)
    // [919] if(frame::h#0<2) goto frame::@return -- vbuz1_lt_vbuc1_then_la1 
    lda.z h
    cmp #2
    bcc __breturn
    // frame::@3
    // y++;
    // [920] frame::y#1 = ++ frame::y#0 -- vbuz1=_inc_vbuz2 
    lda.z y
    inc
    sta.z y_1
    // [921] phi from frame::@27 frame::@3 to frame::@6 [phi:frame::@27/frame::@3->frame::@6]
    // [921] phi frame::y#10 = frame::y#2 [phi:frame::@27/frame::@3->frame::@6#0] -- register_copy 
    // frame::@6
  __b6:
    // while(y < y1)
    // [922] if(frame::y#10<frame::y1#16) goto frame::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z y_1
    cmp.z y1
    bcc __b7
    // frame::@8
    // frame_maskxy(x, y)
    // [923] frame_maskxy::x#5 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z frame_maskxy.x
    // [924] frame_maskxy::y#5 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z frame_maskxy.y
    // [925] call frame_maskxy
    // [1352] phi from frame::@8 to frame_maskxy [phi:frame::@8->frame_maskxy]
    // [1352] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#5 [phi:frame::@8->frame_maskxy#0] -- register_copy 
    // [1352] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#5 [phi:frame::@8->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [926] frame_maskxy::return#18 = frame_maskxy::return#12
    // frame::@28
    // mask = frame_maskxy(x, y)
    // [927] frame::mask#10 = frame_maskxy::return#18
    // mask |= 0b1100
    // [928] frame::mask#11 = frame::mask#10 | $c -- vbuz1=vbuz1_bor_vbuc1 
    lda #$c
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [929] frame_char::mask#5 = frame::mask#11
    // [930] call frame_char
    // [1378] phi from frame::@28 to frame_char [phi:frame::@28->frame_char]
    // [1378] phi frame_char::mask#10 = frame_char::mask#5 [phi:frame::@28->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [931] frame_char::return#18 = frame_char::return#12
    // frame::@29
    // c = frame_char(mask)
    // [932] frame::c#5 = frame_char::return#18
    // cputcxy(x, y, c)
    // [933] cputcxy::x#5 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [934] cputcxy::y#5 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [935] cputcxy::c#5 = frame::c#5
    // [936] call cputcxy
    // [1044] phi from frame::@29 to cputcxy [phi:frame::@29->cputcxy]
    // [1044] phi cputcxy::c#11 = cputcxy::c#5 [phi:frame::@29->cputcxy#0] -- register_copy 
    // [1044] phi cputcxy::y#11 = cputcxy::y#5 [phi:frame::@29->cputcxy#1] -- register_copy 
    // [1044] phi cputcxy::x#11 = cputcxy::x#5 [phi:frame::@29->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@30
    // if(w>=2)
    // [937] if(frame::w#0<2) goto frame::@10 -- vbuz1_lt_vbuc1_then_la1 
    lda.z w
    cmp #2
    bcc __b10
    // frame::@9
    // x++;
    // [938] frame::x#4 = ++ frame::x#0 -- vbuz1=_inc_vbuz1 
    inc.z x
    // [939] phi from frame::@35 frame::@9 to frame::@11 [phi:frame::@35/frame::@9->frame::@11]
    // [939] phi frame::x#18 = frame::x#5 [phi:frame::@35/frame::@9->frame::@11#0] -- register_copy 
    // frame::@11
  __b11:
    // while(x < x1)
    // [940] if(frame::x#18<frame::x1#16) goto frame::@12 -- vbuz1_lt_vbuz2_then_la1 
    lda.z x
    cmp.z x1
    bcc __b12
    // [941] phi from frame::@11 frame::@30 to frame::@10 [phi:frame::@11/frame::@30->frame::@10]
    // [941] phi frame::x#15 = frame::x#18 [phi:frame::@11/frame::@30->frame::@10#0] -- register_copy 
    // frame::@10
  __b10:
    // frame_maskxy(x, y)
    // [942] frame_maskxy::x#6 = frame::x#15 -- vbuz1=vbuz2 
    lda.z x
    sta.z frame_maskxy.x
    // [943] frame_maskxy::y#6 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z frame_maskxy.y
    // [944] call frame_maskxy
    // [1352] phi from frame::@10 to frame_maskxy [phi:frame::@10->frame_maskxy]
    // [1352] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#6 [phi:frame::@10->frame_maskxy#0] -- register_copy 
    // [1352] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#6 [phi:frame::@10->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [945] frame_maskxy::return#19 = frame_maskxy::return#12
    // frame::@31
    // mask = frame_maskxy(x, y)
    // [946] frame::mask#12 = frame_maskxy::return#19
    // mask |= 0b1001
    // [947] frame::mask#13 = frame::mask#12 | 9 -- vbuz1=vbuz1_bor_vbuc1 
    lda #9
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [948] frame_char::mask#6 = frame::mask#13
    // [949] call frame_char
    // [1378] phi from frame::@31 to frame_char [phi:frame::@31->frame_char]
    // [1378] phi frame_char::mask#10 = frame_char::mask#6 [phi:frame::@31->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [950] frame_char::return#19 = frame_char::return#12
    // frame::@32
    // c = frame_char(mask)
    // [951] frame::c#6 = frame_char::return#19
    // cputcxy(x, y, c)
    // [952] cputcxy::x#6 = frame::x#15 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [953] cputcxy::y#6 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [954] cputcxy::c#6 = frame::c#6
    // [955] call cputcxy
    // [1044] phi from frame::@32 to cputcxy [phi:frame::@32->cputcxy]
    // [1044] phi cputcxy::c#11 = cputcxy::c#6 [phi:frame::@32->cputcxy#0] -- register_copy 
    // [1044] phi cputcxy::y#11 = cputcxy::y#6 [phi:frame::@32->cputcxy#1] -- register_copy 
    // [1044] phi cputcxy::x#11 = cputcxy::x#6 [phi:frame::@32->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@return
  __breturn:
    // }
    // [956] return 
    rts
    // frame::@12
  __b12:
    // frame_maskxy(x, y)
    // [957] frame_maskxy::x#7 = frame::x#18 -- vbuz1=vbuz2 
    lda.z x
    sta.z frame_maskxy.x
    // [958] frame_maskxy::y#7 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z frame_maskxy.y
    // [959] call frame_maskxy
    // [1352] phi from frame::@12 to frame_maskxy [phi:frame::@12->frame_maskxy]
    // [1352] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#7 [phi:frame::@12->frame_maskxy#0] -- register_copy 
    // [1352] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#7 [phi:frame::@12->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [960] frame_maskxy::return#20 = frame_maskxy::return#12
    // frame::@33
    // mask = frame_maskxy(x, y)
    // [961] frame::mask#14 = frame_maskxy::return#20
    // mask |= 0b0101
    // [962] frame::mask#15 = frame::mask#14 | 5 -- vbuz1=vbuz1_bor_vbuc1 
    lda #5
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [963] frame_char::mask#7 = frame::mask#15
    // [964] call frame_char
    // [1378] phi from frame::@33 to frame_char [phi:frame::@33->frame_char]
    // [1378] phi frame_char::mask#10 = frame_char::mask#7 [phi:frame::@33->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [965] frame_char::return#20 = frame_char::return#12
    // frame::@34
    // c = frame_char(mask)
    // [966] frame::c#7 = frame_char::return#20
    // cputcxy(x, y, c)
    // [967] cputcxy::x#7 = frame::x#18 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [968] cputcxy::y#7 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [969] cputcxy::c#7 = frame::c#7
    // [970] call cputcxy
    // [1044] phi from frame::@34 to cputcxy [phi:frame::@34->cputcxy]
    // [1044] phi cputcxy::c#11 = cputcxy::c#7 [phi:frame::@34->cputcxy#0] -- register_copy 
    // [1044] phi cputcxy::y#11 = cputcxy::y#7 [phi:frame::@34->cputcxy#1] -- register_copy 
    // [1044] phi cputcxy::x#11 = cputcxy::x#7 [phi:frame::@34->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@35
    // x++;
    // [971] frame::x#5 = ++ frame::x#18 -- vbuz1=_inc_vbuz1 
    inc.z x
    jmp __b11
    // frame::@7
  __b7:
    // frame_maskxy(x0, y)
    // [972] frame_maskxy::x#3 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z frame_maskxy.x
    // [973] frame_maskxy::y#3 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z frame_maskxy.y
    // [974] call frame_maskxy
    // [1352] phi from frame::@7 to frame_maskxy [phi:frame::@7->frame_maskxy]
    // [1352] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#3 [phi:frame::@7->frame_maskxy#0] -- register_copy 
    // [1352] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#3 [phi:frame::@7->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x0, y)
    // [975] frame_maskxy::return#16 = frame_maskxy::return#12
    // frame::@22
    // mask = frame_maskxy(x0, y)
    // [976] frame::mask#6 = frame_maskxy::return#16
    // mask |= 0b1010
    // [977] frame::mask#7 = frame::mask#6 | $a -- vbuz1=vbuz1_bor_vbuc1 
    lda #$a
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [978] frame_char::mask#3 = frame::mask#7
    // [979] call frame_char
    // [1378] phi from frame::@22 to frame_char [phi:frame::@22->frame_char]
    // [1378] phi frame_char::mask#10 = frame_char::mask#3 [phi:frame::@22->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [980] frame_char::return#16 = frame_char::return#12
    // frame::@23
    // c = frame_char(mask)
    // [981] frame::c#3 = frame_char::return#16
    // cputcxy(x0, y, c)
    // [982] cputcxy::x#3 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [983] cputcxy::y#3 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [984] cputcxy::c#3 = frame::c#3
    // [985] call cputcxy
    // [1044] phi from frame::@23 to cputcxy [phi:frame::@23->cputcxy]
    // [1044] phi cputcxy::c#11 = cputcxy::c#3 [phi:frame::@23->cputcxy#0] -- register_copy 
    // [1044] phi cputcxy::y#11 = cputcxy::y#3 [phi:frame::@23->cputcxy#1] -- register_copy 
    // [1044] phi cputcxy::x#11 = cputcxy::x#3 [phi:frame::@23->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@24
    // frame_maskxy(x1, y)
    // [986] frame_maskxy::x#4 = frame::x1#16 -- vbuz1=vbuz2 
    lda.z x1
    sta.z frame_maskxy.x
    // [987] frame_maskxy::y#4 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z frame_maskxy.y
    // [988] call frame_maskxy
    // [1352] phi from frame::@24 to frame_maskxy [phi:frame::@24->frame_maskxy]
    // [1352] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#4 [phi:frame::@24->frame_maskxy#0] -- register_copy 
    // [1352] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#4 [phi:frame::@24->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x1, y)
    // [989] frame_maskxy::return#17 = frame_maskxy::return#12
    // frame::@25
    // mask = frame_maskxy(x1, y)
    // [990] frame::mask#8 = frame_maskxy::return#17
    // mask |= 0b1010
    // [991] frame::mask#9 = frame::mask#8 | $a -- vbuz1=vbuz1_bor_vbuc1 
    lda #$a
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [992] frame_char::mask#4 = frame::mask#9
    // [993] call frame_char
    // [1378] phi from frame::@25 to frame_char [phi:frame::@25->frame_char]
    // [1378] phi frame_char::mask#10 = frame_char::mask#4 [phi:frame::@25->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [994] frame_char::return#17 = frame_char::return#12
    // frame::@26
    // c = frame_char(mask)
    // [995] frame::c#4 = frame_char::return#17
    // cputcxy(x1, y, c)
    // [996] cputcxy::x#4 = frame::x1#16 -- vbuz1=vbuz2 
    lda.z x1
    sta.z cputcxy.x
    // [997] cputcxy::y#4 = frame::y#10 -- vbuz1=vbuz2 
    lda.z y_1
    sta.z cputcxy.y
    // [998] cputcxy::c#4 = frame::c#4
    // [999] call cputcxy
    // [1044] phi from frame::@26 to cputcxy [phi:frame::@26->cputcxy]
    // [1044] phi cputcxy::c#11 = cputcxy::c#4 [phi:frame::@26->cputcxy#0] -- register_copy 
    // [1044] phi cputcxy::y#11 = cputcxy::y#4 [phi:frame::@26->cputcxy#1] -- register_copy 
    // [1044] phi cputcxy::x#11 = cputcxy::x#4 [phi:frame::@26->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@27
    // y++;
    // [1000] frame::y#2 = ++ frame::y#10 -- vbuz1=_inc_vbuz1 
    inc.z y_1
    jmp __b6
    // frame::@5
  __b5:
    // frame_maskxy(x, y)
    // [1001] frame_maskxy::x#2 = frame::x#10 -- vbuz1=vbuz2 
    lda.z x_1
    sta.z frame_maskxy.x
    // [1002] frame_maskxy::y#2 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z frame_maskxy.y
    // [1003] call frame_maskxy
    // [1352] phi from frame::@5 to frame_maskxy [phi:frame::@5->frame_maskxy]
    // [1352] phi frame_maskxy::cpeekcxy1_y#0 = frame_maskxy::y#2 [phi:frame::@5->frame_maskxy#0] -- register_copy 
    // [1352] phi frame_maskxy::cpeekcxy1_x#0 = frame_maskxy::x#2 [phi:frame::@5->frame_maskxy#1] -- register_copy 
    jsr frame_maskxy
    // frame_maskxy(x, y)
    // [1004] frame_maskxy::return#15 = frame_maskxy::return#12
    // frame::@19
    // mask = frame_maskxy(x, y)
    // [1005] frame::mask#4 = frame_maskxy::return#15
    // mask |= 0b0101
    // [1006] frame::mask#5 = frame::mask#4 | 5 -- vbuz1=vbuz1_bor_vbuc1 
    lda #5
    ora.z mask
    sta.z mask
    // frame_char(mask)
    // [1007] frame_char::mask#2 = frame::mask#5
    // [1008] call frame_char
    // [1378] phi from frame::@19 to frame_char [phi:frame::@19->frame_char]
    // [1378] phi frame_char::mask#10 = frame_char::mask#2 [phi:frame::@19->frame_char#0] -- register_copy 
    jsr frame_char
    // frame_char(mask)
    // [1009] frame_char::return#15 = frame_char::return#12
    // frame::@20
    // c = frame_char(mask)
    // [1010] frame::c#2 = frame_char::return#15
    // cputcxy(x, y, c)
    // [1011] cputcxy::x#2 = frame::x#10 -- vbuz1=vbuz2 
    lda.z x_1
    sta.z cputcxy.x
    // [1012] cputcxy::y#2 = frame::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [1013] cputcxy::c#2 = frame::c#2
    // [1014] call cputcxy
    // [1044] phi from frame::@20 to cputcxy [phi:frame::@20->cputcxy]
    // [1044] phi cputcxy::c#11 = cputcxy::c#2 [phi:frame::@20->cputcxy#0] -- register_copy 
    // [1044] phi cputcxy::y#11 = cputcxy::y#2 [phi:frame::@20->cputcxy#1] -- register_copy 
    // [1044] phi cputcxy::x#11 = cputcxy::x#2 [phi:frame::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // frame::@21
    // x++;
    // [1015] frame::x#2 = ++ frame::x#10 -- vbuz1=_inc_vbuz1 
    inc.z x_1
    jmp __b4
    // frame::@36
  __b36:
    // [1016] frame::x#30 = frame::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z x_1
    jmp __b1
}
  // cputsxy
// Move cursor and output a NUL-terminated string
// Same as "gotoxy (x, y); puts (s);"
// void cputsxy(char x, char y, const char *s)
cputsxy: {
    .const x = 2
    .const y = $e
    // gotoxy(x, y)
    // [1018] call gotoxy
    // [189] phi from cputsxy to gotoxy [phi:cputsxy->gotoxy]
    // [189] phi gotoxy::y#18 = cputsxy::y#0 [phi:cputsxy->gotoxy#0] -- vbuz1=vbuc1 
    lda #y
    sta.z gotoxy.y
    // [189] phi gotoxy::x#18 = cputsxy::x#0 [phi:cputsxy->gotoxy#1] -- vbuz1=vbuc1 
    lda #x
    sta.z gotoxy.x
    jsr gotoxy
    // [1019] phi from cputsxy to cputsxy::@1 [phi:cputsxy->cputsxy::@1]
    // cputsxy::@1
    // cputs(s)
    // [1020] call cputs
    // [1393] phi from cputsxy::@1 to cputs [phi:cputsxy::@1->cputs]
    jsr cputs
    // cputsxy::@return
    // }
    // [1021] return 
    rts
}
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(void (*putc)(char), __zp($47) char *str, __zp($70) char format_min_length, __zp($af) char format_justify_left)
printf_string: {
    .label printf_string__9 = $34
    .label len = $6d
    .label padding = $70
    .label str = $47
    .label format_justify_left = $af
    .label format_min_length = $70
    // if(format.min_length)
    // [1023] if(0==printf_string::format_min_length#10) goto printf_string::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b3
    // printf_string::@3
    // strlen(str)
    // [1024] strlen::str#3 = printf_string::str#10 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [1025] call strlen
    // [1194] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [1194] phi strlen::str#8 = strlen::str#3 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [1026] strlen::return#10 = strlen::len#2
    // printf_string::@6
    // [1027] printf_string::$9 = strlen::return#10
    // signed char len = (signed char)strlen(str)
    // [1028] printf_string::len#0 = (signed char)printf_string::$9 -- vbsz1=_sbyte_vwuz2 
    lda.z printf_string__9
    sta.z len
    // padding = (signed char)format.min_length  - len
    // [1029] printf_string::padding#1 = (signed char)printf_string::format_min_length#10 - printf_string::len#0 -- vbsz1=vbsz1_minus_vbsz2 
    lda.z padding
    sec
    sbc.z len
    sta.z padding
    // if(padding<0)
    // [1030] if(printf_string::padding#1>=0) goto printf_string::@10 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1032] phi from printf_string printf_string::@6 to printf_string::@1 [phi:printf_string/printf_string::@6->printf_string::@1]
  __b3:
    // [1032] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@6->printf_string::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [1031] phi from printf_string::@6 to printf_string::@10 [phi:printf_string::@6->printf_string::@10]
    // printf_string::@10
    // [1032] phi from printf_string::@10 to printf_string::@1 [phi:printf_string::@10->printf_string::@1]
    // [1032] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@10->printf_string::@1#0] -- register_copy 
    // printf_string::@1
  __b1:
    // if(!format.justify_left && padding)
    // [1033] if(0!=printf_string::format_justify_left#10) goto printf_string::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_justify_left
    bne __b2
    // printf_string::@8
    // [1034] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b4
    jmp __b2
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [1035] printf_padding::length#3 = (char)printf_string::padding#3 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1036] call printf_padding
    // [1402] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [1402] phi printf_padding::putc#7 = &cputc [phi:printf_string::@4->printf_padding#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_padding.putc
    lda #>cputc
    sta.z printf_padding.putc+1
    // [1402] phi printf_padding::pad#7 = ' ' [phi:printf_string::@4->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1402] phi printf_padding::length#6 = printf_padding::length#3 [phi:printf_string::@4->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [1037] printf_str::s#2 = printf_string::str#10
    // [1038] call printf_str
    // [560] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [560] phi printf_str::putc#28 = &cputc [phi:printf_string::@2->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [560] phi printf_str::s#28 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@7
    // if(format.justify_left && padding)
    // [1039] if(0==printf_string::format_justify_left#10) goto printf_string::@return -- 0_eq_vbuz1_then_la1 
    lda.z format_justify_left
    beq __breturn
    // printf_string::@9
    // [1040] if(0!=printf_string::padding#3) goto printf_string::@5 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b5
    rts
    // printf_string::@5
  __b5:
    // printf_padding(putc, ' ',(char)padding)
    // [1041] printf_padding::length#4 = (char)printf_string::padding#3 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1042] call printf_padding
    // [1402] phi from printf_string::@5 to printf_padding [phi:printf_string::@5->printf_padding]
    // [1402] phi printf_padding::putc#7 = &cputc [phi:printf_string::@5->printf_padding#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_padding.putc
    lda #>cputc
    sta.z printf_padding.putc+1
    // [1402] phi printf_padding::pad#7 = ' ' [phi:printf_string::@5->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1402] phi printf_padding::length#6 = printf_padding::length#4 [phi:printf_string::@5->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@return
  __breturn:
    // }
    // [1043] return 
    rts
}
  // cputcxy
// Move cursor and output one character
// Same as "gotoxy (x, y); cputc (c);"
// void cputcxy(__zp($5f) char x, __zp($66) char y, __zp($43) char c)
cputcxy: {
    .label x = $5f
    .label y = $66
    .label c = $43
    // gotoxy(x, y)
    // [1045] gotoxy::x#0 = cputcxy::x#11 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1046] gotoxy::y#0 = cputcxy::y#11 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1047] call gotoxy
    // [189] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [189] phi gotoxy::y#18 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [189] phi gotoxy::x#18 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [1048] stackpush(char) = cputcxy::c#11 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [1049] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [1051] return 
    rts
}
  // info_clear
// void info_clear(__zp($59) char l)
info_clear: {
    .const w = $40
    .label y = $59
    .label x = $46
    .label i = $3f
    .label l = $59
    // unsigned char y = INFO_Y+l
    // [1053] info_clear::y#0 = $11 + info_clear::l#4 -- vbuz1=vbuc1_plus_vbuz1 
    lda #$11
    clc
    adc.z y
    sta.z y
    // [1054] phi from info_clear to info_clear::@1 [phi:info_clear->info_clear::@1]
    // [1054] phi info_clear::x#2 = 2 [phi:info_clear->info_clear::@1#0] -- vbuz1=vbuc1 
    lda #2
    sta.z x
    // [1054] phi info_clear::i#2 = 0 [phi:info_clear->info_clear::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // info_clear::@1
  __b1:
    // for(unsigned char i = 0; i < w; i++)
    // [1055] if(info_clear::i#2<info_clear::w) goto info_clear::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z i
    cmp #w
    bcc __b2
    // info_clear::@3
    // gotoxy(PROGRESS_X, y)
    // [1056] gotoxy::y#12 = info_clear::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1057] call gotoxy
    // [189] phi from info_clear::@3 to gotoxy [phi:info_clear::@3->gotoxy]
    // [189] phi gotoxy::y#18 = gotoxy::y#12 [phi:info_clear::@3->gotoxy#0] -- register_copy 
    // [189] phi gotoxy::x#18 = 2 [phi:info_clear::@3->gotoxy#1] -- vbuz1=vbuc1 
    lda #2
    sta.z gotoxy.x
    jsr gotoxy
    // info_clear::@return
    // }
    // [1058] return 
    rts
    // info_clear::@2
  __b2:
    // cputcxy(x, y, ' ')
    // [1059] cputcxy::x#10 = info_clear::x#2 -- vbuz1=vbuz2 
    lda.z x
    sta.z cputcxy.x
    // [1060] cputcxy::y#10 = info_clear::y#0 -- vbuz1=vbuz2 
    lda.z y
    sta.z cputcxy.y
    // [1061] call cputcxy
    // [1044] phi from info_clear::@2 to cputcxy [phi:info_clear::@2->cputcxy]
    // [1044] phi cputcxy::c#11 = ' ' [phi:info_clear::@2->cputcxy#0] -- vbuz1=vbuc1 
    lda #' '
    sta.z cputcxy.c
    // [1044] phi cputcxy::y#11 = cputcxy::y#10 [phi:info_clear::@2->cputcxy#1] -- register_copy 
    // [1044] phi cputcxy::x#11 = cputcxy::x#10 [phi:info_clear::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // info_clear::@4
    // x++;
    // [1062] info_clear::x#1 = ++ info_clear::x#2 -- vbuz1=_inc_vbuz1 
    inc.z x
    // for(unsigned char i = 0; i < w; i++)
    // [1063] info_clear::i#1 = ++ info_clear::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1054] phi from info_clear::@4 to info_clear::@1 [phi:info_clear::@4->info_clear::@1]
    // [1054] phi info_clear::x#2 = info_clear::x#1 [phi:info_clear::@4->info_clear::@1#0] -- register_copy 
    // [1054] phi info_clear::i#2 = info_clear::i#1 [phi:info_clear::@4->info_clear::@1#1] -- register_copy 
    jmp __b1
}
  // wherex
// Return the x position of the cursor
wherex: {
    .label return = $7c
    // return __conio.cursor_x;
    // [1064] wherex::return#0 = *((char *)&__conio) -- vbuz1=_deref_pbuc1 
    lda __conio
    sta.z return
    // wherex::@return
    // }
    // [1065] return 
    rts
}
  // wherey
// Return the y position of the cursor
wherey: {
    .label return = $7b
    // return __conio.cursor_y;
    // [1066] wherey::return#0 = *((char *)&__conio+1) -- vbuz1=_deref_pbuc1 
    lda __conio+1
    sta.z return
    // wherey::@return
    // }
    // [1067] return 
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
// __zp($2c) unsigned int cx16_k_i2c_read_byte(__zp($e9) volatile char device, __zp($e5) volatile char offset)
cx16_k_i2c_read_byte: {
    .label device = $e9
    .label offset = $e5
    .label result = $b2
    .label return = $2c
    // unsigned int result
    // [1068] cx16_k_i2c_read_byte::result = 0 -- vwuz1=vwuc1 
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
    // [1070] cx16_k_i2c_read_byte::return#0 = cx16_k_i2c_read_byte::result -- vwuz1=vwuz2 
    sta.z return
    lda.z result+1
    sta.z return+1
    // cx16_k_i2c_read_byte::@return
    // }
    // [1071] cx16_k_i2c_read_byte::return#1 = cx16_k_i2c_read_byte::return#0
    // [1072] return 
    rts
}
  // cbm_k_getin
/**
 * @brief Scan a character from keyboard without pressing enter.
 * 
 * @return char The character read.
 */
cbm_k_getin: {
    .label return = $7b
    // __mem unsigned char ch
    // [1073] cbm_k_getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsrCBM_GETIN stach  }
    jsr CBM_GETIN
    sta ch
    // return ch;
    // [1075] cbm_k_getin::return#0 = cbm_k_getin::ch -- vbuz1=vbum2 
    sta.z return
    // cbm_k_getin::@return
    // }
    // [1076] cbm_k_getin::return#1 = cbm_k_getin::return#0
    // [1077] return 
    rts
  .segment Data
    ch: .byte 0
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
// void rom_unlock(__zp($ba) unsigned long address, __zp($dc) char unlock_code)
rom_unlock: {
    .label chip_address = $d0
    .label address = $ba
    .label unlock_code = $dc
    // unsigned long chip_address = address & ROM_CHIP_MASK
    // [1079] rom_unlock::chip_address#0 = rom_unlock::address#2 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [1080] rom_write_byte::address#0 = rom_unlock::chip_address#0 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [1081] call rom_write_byte
  // This is a very important operation...
    // [1410] phi from rom_unlock to rom_write_byte [phi:rom_unlock->rom_write_byte]
    // [1410] phi rom_write_byte::value#10 = $aa [phi:rom_unlock->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$aa
    sta.z rom_write_byte.value
    // [1410] phi rom_write_byte::address#3 = rom_write_byte::address#0 [phi:rom_unlock->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@1
    // rom_write_byte(chip_address + 0x02AAA, 0x55)
    // [1082] rom_write_byte::address#1 = rom_unlock::chip_address#0 + $2aaa -- vduz1=vduz2_plus_vwuc1 
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
    // [1083] call rom_write_byte
    // [1410] phi from rom_unlock::@1 to rom_write_byte [phi:rom_unlock::@1->rom_write_byte]
    // [1410] phi rom_write_byte::value#10 = $55 [phi:rom_unlock::@1->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$55
    sta.z rom_write_byte.value
    // [1410] phi rom_write_byte::address#3 = rom_write_byte::address#1 [phi:rom_unlock::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@2
    // rom_write_byte(address, unlock_code)
    // [1084] rom_write_byte::address#2 = rom_unlock::address#2 -- vduz1=vduz2 
    lda.z address
    sta.z rom_write_byte.address
    lda.z address+1
    sta.z rom_write_byte.address+1
    lda.z address+2
    sta.z rom_write_byte.address+2
    lda.z address+3
    sta.z rom_write_byte.address+3
    // [1085] rom_write_byte::value#2 = rom_unlock::unlock_code#2 -- vbuz1=vbuz2 
    lda.z unlock_code
    sta.z rom_write_byte.value
    // [1086] call rom_write_byte
    // [1410] phi from rom_unlock::@2 to rom_write_byte [phi:rom_unlock::@2->rom_write_byte]
    // [1410] phi rom_write_byte::value#10 = rom_write_byte::value#2 [phi:rom_unlock::@2->rom_write_byte#0] -- register_copy 
    // [1410] phi rom_write_byte::address#3 = rom_write_byte::address#2 [phi:rom_unlock::@2->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@return
    // }
    // [1087] return 
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
// __zp($ce) char rom_read_byte(__zp($b4) unsigned long address)
rom_read_byte: {
    .label rom_bank1_rom_read_byte__0 = $6d
    .label rom_bank1_rom_read_byte__1 = $7d
    .label rom_bank1_rom_read_byte__2 = $69
    .label rom_ptr1_rom_read_byte__0 = $71
    .label rom_ptr1_rom_read_byte__2 = $71
    .label rom_bank1_bank_unshifted = $69
    .label rom_bank1_return = $b8
    .label rom_ptr1_return = $71
    .label return = $ce
    .label address = $b4
    // rom_read_byte::rom_bank1
    // BYTE2(address)
    // [1089] rom_read_byte::rom_bank1_$0 = byte2  rom_read_byte::address#2 -- vbuz1=_byte2_vduz2 
    lda.z address+2
    sta.z rom_bank1_rom_read_byte__0
    // BYTE1(address)
    // [1090] rom_read_byte::rom_bank1_$1 = byte1  rom_read_byte::address#2 -- vbuz1=_byte1_vduz2 
    lda.z address+1
    sta.z rom_bank1_rom_read_byte__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [1091] rom_read_byte::rom_bank1_$2 = rom_read_byte::rom_bank1_$0 w= rom_read_byte::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_read_byte__0
    sta.z rom_bank1_rom_read_byte__2+1
    lda.z rom_bank1_rom_read_byte__1
    sta.z rom_bank1_rom_read_byte__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [1092] rom_read_byte::rom_bank1_bank_unshifted#0 = rom_read_byte::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [1093] rom_read_byte::rom_bank1_return#0 = byte1  rom_read_byte::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwuz2 
    lda.z rom_bank1_bank_unshifted+1
    sta.z rom_bank1_return
    // rom_read_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [1094] rom_read_byte::rom_ptr1_$2 = (unsigned int)rom_read_byte::address#2 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_read_byte__2
    lda.z address+1
    sta.z rom_ptr1_rom_read_byte__2+1
    // [1095] rom_read_byte::rom_ptr1_$0 = rom_read_byte::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_read_byte__0
    and #<$3fff
    sta.z rom_ptr1_rom_read_byte__0
    lda.z rom_ptr1_rom_read_byte__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_read_byte__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [1096] rom_read_byte::rom_ptr1_return#0 = rom_read_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_read_byte::bank_set_brom1
    // BROM = bank
    // [1097] BROM = rom_read_byte::rom_bank1_return#0 -- vbuz1=vbuz2 
    lda.z rom_bank1_return
    sta.z BROM
    // rom_read_byte::@1
    // return *ptr_rom;
    // [1098] rom_read_byte::return#0 = *((char *)rom_read_byte::rom_ptr1_return#0) -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (rom_ptr1_return),y
    sta.z return
    // rom_read_byte::@return
    // }
    // [1099] return 
    rts
}
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(__zp($5d) void (*putc)(char), __zp($39) char uvalue, __zp($aa) char format_min_length, char format_justify_left, char format_sign_always, __zp($6d) char format_zero_padding, char format_upper_case, __zp($b0) char format_radix)
printf_uchar: {
    .label uvalue = $39
    .label format_radix = $b0
    .label putc = $5d
    .label format_min_length = $aa
    .label format_zero_padding = $6d
    // printf_uchar::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1101] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [1102] uctoa::value#1 = printf_uchar::uvalue#10
    // [1103] uctoa::radix#0 = printf_uchar::format_radix#10
    // [1104] call uctoa
    // Format number into buffer
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1105] printf_number_buffer::putc#1 = printf_uchar::putc#10
    // [1106] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [1107] printf_number_buffer::format_min_length#1 = printf_uchar::format_min_length#10
    // [1108] printf_number_buffer::format_zero_padding#1 = printf_uchar::format_zero_padding#10
    // [1109] call printf_number_buffer
  // Print using format
    // [1450] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [1450] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#1 [phi:printf_uchar::@2->printf_number_buffer#0] -- register_copy 
    // [1450] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_uchar::@2->printf_number_buffer#1] -- register_copy 
    // [1450] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#1 [phi:printf_uchar::@2->printf_number_buffer#2] -- register_copy 
    // [1450] phi printf_number_buffer::format_min_length#2 = printf_number_buffer::format_min_length#1 [phi:printf_uchar::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [1110] return 
    rts
}
  // print_smc_led
// void print_smc_led(__zp($ab) char c)
print_smc_led: {
    .label c = $ab
    // print_chip_led(CHIP_SMC_X+1, CHIP_SMC_Y, CHIP_SMC_W, c, BLUE)
    // [1112] print_chip_led::tc#0 = print_smc_led::c#2
    // [1113] call print_chip_led
    // [1481] phi from print_smc_led to print_chip_led [phi:print_smc_led->print_chip_led]
    // [1481] phi print_chip_led::w#5 = 5 [phi:print_smc_led->print_chip_led#0] -- vbuz1=vbuc1 
    lda #5
    sta.z print_chip_led.w
    // [1481] phi print_chip_led::tc#3 = print_chip_led::tc#0 [phi:print_smc_led->print_chip_led#1] -- register_copy 
    // [1481] phi print_chip_led::x#3 = 1+1 [phi:print_smc_led->print_chip_led#2] -- vbuz1=vbuc1 
    lda #1+1
    sta.z print_chip_led.x
    jsr print_chip_led
    // print_smc_led::@return
    // }
    // [1114] return 
    rts
}
  // print_chip
// void print_chip(__zp($42) char x, char y, __zp($c3) char w, __zp($da) char *text)
print_chip: {
    .label y = 3+1+1+1+1+1+1+1+1+1
    .label text = $da
    .label text_1 = $74
    .label x = $42
    .label text_2 = $44
    .label text_3 = $5a
    .label text_4 = $79
    .label text_5 = $7e
    .label text_6 = $62
    .label w = $c3
    // print_chip_line(x, y++, w, *text++)
    // [1116] print_chip_line::x#0 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1117] print_chip_line::w#0 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1118] print_chip_line::c#0 = *print_chip::text#11 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_2),y
    sta.z print_chip_line.c
    // [1119] call print_chip_line
    // [1499] phi from print_chip to print_chip_line [phi:print_chip->print_chip_line]
    // [1499] phi print_chip_line::c#15 = print_chip_line::c#0 [phi:print_chip->print_chip_line#0] -- register_copy 
    // [1499] phi print_chip_line::w#10 = print_chip_line::w#0 [phi:print_chip->print_chip_line#1] -- register_copy 
    // [1499] phi print_chip_line::y#16 = 3+1 [phi:print_chip->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1
    sta.z print_chip_line.y
    // [1499] phi print_chip_line::x#16 = print_chip_line::x#0 [phi:print_chip->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@1
    // print_chip_line(x, y++, w, *text++);
    // [1120] print_chip::text#0 = ++ print_chip::text#11 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_2
    adc #1
    sta.z text
    lda.z text_2+1
    adc #0
    sta.z text+1
    // print_chip_line(x, y++, w, *text++)
    // [1121] print_chip_line::x#1 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1122] print_chip_line::w#1 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1123] print_chip_line::c#1 = *print_chip::text#0 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text),y
    sta.z print_chip_line.c
    // [1124] call print_chip_line
    // [1499] phi from print_chip::@1 to print_chip_line [phi:print_chip::@1->print_chip_line]
    // [1499] phi print_chip_line::c#15 = print_chip_line::c#1 [phi:print_chip::@1->print_chip_line#0] -- register_copy 
    // [1499] phi print_chip_line::w#10 = print_chip_line::w#1 [phi:print_chip::@1->print_chip_line#1] -- register_copy 
    // [1499] phi print_chip_line::y#16 = ++3+1 [phi:print_chip::@1->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1
    sta.z print_chip_line.y
    // [1499] phi print_chip_line::x#16 = print_chip_line::x#1 [phi:print_chip::@1->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@2
    // print_chip_line(x, y++, w, *text++);
    // [1125] print_chip::text#1 = ++ print_chip::text#0 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text
    adc #1
    sta.z text_1
    lda.z text+1
    adc #0
    sta.z text_1+1
    // print_chip_line(x, y++, w, *text++)
    // [1126] print_chip_line::x#2 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1127] print_chip_line::w#2 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1128] print_chip_line::c#2 = *print_chip::text#1 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_1),y
    sta.z print_chip_line.c
    // [1129] call print_chip_line
    // [1499] phi from print_chip::@2 to print_chip_line [phi:print_chip::@2->print_chip_line]
    // [1499] phi print_chip_line::c#15 = print_chip_line::c#2 [phi:print_chip::@2->print_chip_line#0] -- register_copy 
    // [1499] phi print_chip_line::w#10 = print_chip_line::w#2 [phi:print_chip::@2->print_chip_line#1] -- register_copy 
    // [1499] phi print_chip_line::y#16 = ++++3+1 [phi:print_chip::@2->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1
    sta.z print_chip_line.y
    // [1499] phi print_chip_line::x#16 = print_chip_line::x#2 [phi:print_chip::@2->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@3
    // print_chip_line(x, y++, w, *text++);
    // [1130] print_chip::text#15 = ++ print_chip::text#1 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_1
    adc #1
    sta.z text_3
    lda.z text_1+1
    adc #0
    sta.z text_3+1
    // print_chip_line(x, y++, w, *text++)
    // [1131] print_chip_line::x#3 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1132] print_chip_line::w#3 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1133] print_chip_line::c#3 = *print_chip::text#15 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_3),y
    sta.z print_chip_line.c
    // [1134] call print_chip_line
    // [1499] phi from print_chip::@3 to print_chip_line [phi:print_chip::@3->print_chip_line]
    // [1499] phi print_chip_line::c#15 = print_chip_line::c#3 [phi:print_chip::@3->print_chip_line#0] -- register_copy 
    // [1499] phi print_chip_line::w#10 = print_chip_line::w#3 [phi:print_chip::@3->print_chip_line#1] -- register_copy 
    // [1499] phi print_chip_line::y#16 = ++++++3+1 [phi:print_chip::@3->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1+1
    sta.z print_chip_line.y
    // [1499] phi print_chip_line::x#16 = print_chip_line::x#3 [phi:print_chip::@3->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@4
    // print_chip_line(x, y++, w, *text++);
    // [1135] print_chip::text#16 = ++ print_chip::text#15 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_3
    adc #1
    sta.z text_4
    lda.z text_3+1
    adc #0
    sta.z text_4+1
    // print_chip_line(x, y++, w, *text++)
    // [1136] print_chip_line::x#4 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1137] print_chip_line::w#4 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1138] print_chip_line::c#4 = *print_chip::text#16 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_4),y
    sta.z print_chip_line.c
    // [1139] call print_chip_line
    // [1499] phi from print_chip::@4 to print_chip_line [phi:print_chip::@4->print_chip_line]
    // [1499] phi print_chip_line::c#15 = print_chip_line::c#4 [phi:print_chip::@4->print_chip_line#0] -- register_copy 
    // [1499] phi print_chip_line::w#10 = print_chip_line::w#4 [phi:print_chip::@4->print_chip_line#1] -- register_copy 
    // [1499] phi print_chip_line::y#16 = ++++++++3+1 [phi:print_chip::@4->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1+1+1
    sta.z print_chip_line.y
    // [1499] phi print_chip_line::x#16 = print_chip_line::x#4 [phi:print_chip::@4->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@5
    // print_chip_line(x, y++, w, *text++);
    // [1140] print_chip::text#17 = ++ print_chip::text#16 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_4
    adc #1
    sta.z text_5
    lda.z text_4+1
    adc #0
    sta.z text_5+1
    // print_chip_line(x, y++, w, *text++)
    // [1141] print_chip_line::x#5 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1142] print_chip_line::w#5 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1143] print_chip_line::c#5 = *print_chip::text#17 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_5),y
    sta.z print_chip_line.c
    // [1144] call print_chip_line
    // [1499] phi from print_chip::@5 to print_chip_line [phi:print_chip::@5->print_chip_line]
    // [1499] phi print_chip_line::c#15 = print_chip_line::c#5 [phi:print_chip::@5->print_chip_line#0] -- register_copy 
    // [1499] phi print_chip_line::w#10 = print_chip_line::w#5 [phi:print_chip::@5->print_chip_line#1] -- register_copy 
    // [1499] phi print_chip_line::y#16 = ++++++++++3+1 [phi:print_chip::@5->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1+1+1+1
    sta.z print_chip_line.y
    // [1499] phi print_chip_line::x#16 = print_chip_line::x#5 [phi:print_chip::@5->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@6
    // print_chip_line(x, y++, w, *text++);
    // [1145] print_chip::text#18 = ++ print_chip::text#17 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_5
    adc #1
    sta.z text_6
    lda.z text_5+1
    adc #0
    sta.z text_6+1
    // print_chip_line(x, y++, w, *text++)
    // [1146] print_chip_line::x#6 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1147] print_chip_line::w#6 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1148] print_chip_line::c#6 = *print_chip::text#18 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta.z print_chip_line.c
    // [1149] call print_chip_line
    // [1499] phi from print_chip::@6 to print_chip_line [phi:print_chip::@6->print_chip_line]
    // [1499] phi print_chip_line::c#15 = print_chip_line::c#6 [phi:print_chip::@6->print_chip_line#0] -- register_copy 
    // [1499] phi print_chip_line::w#10 = print_chip_line::w#6 [phi:print_chip::@6->print_chip_line#1] -- register_copy 
    // [1499] phi print_chip_line::y#16 = ++++++++++++3+1 [phi:print_chip::@6->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1+1+1+1+1
    sta.z print_chip_line.y
    // [1499] phi print_chip_line::x#16 = print_chip_line::x#6 [phi:print_chip::@6->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@7
    // print_chip_line(x, y++, w, *text++);
    // [1150] print_chip::text#19 = ++ print_chip::text#18 -- pbuz1=_inc_pbuz1 
    inc.z text_6
    bne !+
    inc.z text_6+1
  !:
    // print_chip_line(x, y++, w, *text++)
    // [1151] print_chip_line::x#7 = print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z print_chip_line.x
    // [1152] print_chip_line::w#7 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_line.w
    // [1153] print_chip_line::c#7 = *print_chip::text#19 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta.z print_chip_line.c
    // [1154] call print_chip_line
    // [1499] phi from print_chip::@7 to print_chip_line [phi:print_chip::@7->print_chip_line]
    // [1499] phi print_chip_line::c#15 = print_chip_line::c#7 [phi:print_chip::@7->print_chip_line#0] -- register_copy 
    // [1499] phi print_chip_line::w#10 = print_chip_line::w#7 [phi:print_chip::@7->print_chip_line#1] -- register_copy 
    // [1499] phi print_chip_line::y#16 = ++++++++++++++3+1 [phi:print_chip::@7->print_chip_line#2] -- vbuz1=vbuc1 
    lda #3+1+1+1+1+1+1+1+1
    sta.z print_chip_line.y
    // [1499] phi print_chip_line::x#16 = print_chip_line::x#7 [phi:print_chip::@7->print_chip_line#3] -- register_copy 
    jsr print_chip_line
    // print_chip::@8
    // print_chip_end(x, y++, w)
    // [1155] print_chip_end::x#0 = print_chip::x#10
    // [1156] print_chip_end::w#0 = print_chip::w#10 -- vbuz1=vbuz2 
    lda.z w
    sta.z print_chip_end.w
    // [1157] call print_chip_end
    jsr print_chip_end
    // print_chip::@return
    // }
    // [1158] return 
    rts
}
  // print_vera_led
// void print_vera_led(__zp($ab) char c)
print_vera_led: {
    .label c = $ab
    // print_chip_led(CHIP_VERA_X+1, CHIP_VERA_Y, CHIP_VERA_W, c, BLUE)
    // [1160] print_chip_led::tc#1 = print_vera_led::c#2
    // [1161] call print_chip_led
    // [1481] phi from print_vera_led to print_chip_led [phi:print_vera_led->print_chip_led]
    // [1481] phi print_chip_led::w#5 = 8 [phi:print_vera_led->print_chip_led#0] -- vbuz1=vbuc1 
    lda #8
    sta.z print_chip_led.w
    // [1481] phi print_chip_led::tc#3 = print_chip_led::tc#1 [phi:print_vera_led->print_chip_led#1] -- register_copy 
    // [1481] phi print_chip_led::x#3 = 9+1 [phi:print_vera_led->print_chip_led#2] -- vbuz1=vbuc1 
    lda #9+1
    sta.z print_chip_led.x
    jsr print_chip_led
    // print_vera_led::@return
    // }
    // [1162] return 
    rts
}
  // strcat
// Concatenates the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcat(char *destination, __zp($44) char *source)
strcat: {
    .label strcat__0 = $34
    .label dst = $34
    .label src = $44
    .label source = $44
    // strlen(destination)
    // [1164] call strlen
    // [1194] phi from strcat to strlen [phi:strcat->strlen]
    // [1194] phi strlen::str#8 = chip_rom::rom [phi:strcat->strlen#0] -- pbuz1=pbuc1 
    lda #<chip_rom.rom
    sta.z strlen.str
    lda #>chip_rom.rom
    sta.z strlen.str+1
    jsr strlen
    // strlen(destination)
    // [1165] strlen::return#0 = strlen::len#2
    // strcat::@4
    // [1166] strcat::$0 = strlen::return#0
    // char* dst = destination + strlen(destination)
    // [1167] strcat::dst#0 = chip_rom::rom + strcat::$0 -- pbuz1=pbuc1_plus_vwuz1 
    lda.z dst
    clc
    adc #<chip_rom.rom
    sta.z dst
    lda.z dst+1
    adc #>chip_rom.rom
    sta.z dst+1
    // [1168] phi from strcat::@2 strcat::@4 to strcat::@1 [phi:strcat::@2/strcat::@4->strcat::@1]
    // [1168] phi strcat::dst#2 = strcat::dst#1 [phi:strcat::@2/strcat::@4->strcat::@1#0] -- register_copy 
    // [1168] phi strcat::src#2 = strcat::src#1 [phi:strcat::@2/strcat::@4->strcat::@1#1] -- register_copy 
    // strcat::@1
  __b1:
    // while(*src)
    // [1169] if(0!=*strcat::src#2) goto strcat::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcat::@3
    // *dst = 0
    // [1170] *strcat::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcat::@return
    // }
    // [1171] return 
    rts
    // strcat::@2
  __b2:
    // *dst++ = *src++
    // [1172] *strcat::dst#2 = *strcat::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [1173] strcat::dst#1 = ++ strcat::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [1174] strcat::src#1 = ++ strcat::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    jmp __b1
}
  // print_rom_led
// void print_rom_led(__zp($67) char chip, __zp($ab) char c)
print_rom_led: {
    .label print_rom_led__0 = $67
    .label chip = $67
    .label c = $ab
    .label print_rom_led__4 = $b8
    .label print_rom_led__5 = $67
    // chip*6
    // [1176] print_rom_led::$4 = print_rom_led::chip#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z chip
    asl
    sta.z print_rom_led__4
    // [1177] print_rom_led::$5 = print_rom_led::$4 + print_rom_led::chip#2 -- vbuz1=vbuz2_plus_vbuz1 
    lda.z print_rom_led__5
    clc
    adc.z print_rom_led__4
    sta.z print_rom_led__5
    // CHIP_ROM_X+chip*6
    // [1178] print_rom_led::$0 = print_rom_led::$5 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z print_rom_led__0
    // print_chip_led(CHIP_ROM_X+chip*6+1, CHIP_ROM_Y, CHIP_ROM_W, c, BLUE)
    // [1179] print_chip_led::x#2 = print_rom_led::$0 + $14+1 -- vbuz1=vbuz1_plus_vbuc1 
    lda #$14+1
    clc
    adc.z print_chip_led.x
    sta.z print_chip_led.x
    // [1180] print_chip_led::tc#2 = print_rom_led::c#2
    // [1181] call print_chip_led
    // [1481] phi from print_rom_led to print_chip_led [phi:print_rom_led->print_chip_led]
    // [1481] phi print_chip_led::w#5 = 3 [phi:print_rom_led->print_chip_led#0] -- vbuz1=vbuc1 
    lda #3
    sta.z print_chip_led.w
    // [1481] phi print_chip_led::tc#3 = print_chip_led::tc#2 [phi:print_rom_led->print_chip_led#1] -- register_copy 
    // [1481] phi print_chip_led::x#3 = print_chip_led::x#2 [phi:print_rom_led->print_chip_led#2] -- register_copy 
    jsr print_chip_led
    // print_rom_led::@return
    // }
    // [1182] return 
    rts
}
  // printf_uint
// Print an unsigned int using a specific format
// void printf_uint(__zp($5d) void (*putc)(char), __zp($2c) unsigned int uvalue, __zp($aa) char format_min_length, char format_justify_left, char format_sign_always, __zp($6d) char format_zero_padding, char format_upper_case, __zp($6b) char format_radix)
printf_uint: {
    .label uvalue = $2c
    .label format_radix = $6b
    .label putc = $5d
    .label format_min_length = $aa
    .label format_zero_padding = $6d
    // printf_uint::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1184] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [1185] utoa::value#1 = printf_uint::uvalue#6
    // [1186] utoa::radix#0 = printf_uint::format_radix#10
    // [1187] call utoa
    // Format number into buffer
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1188] printf_number_buffer::putc#0 = printf_uint::putc#10
    // [1189] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbuz1=_deref_pbuc1 
    lda printf_buffer
    sta.z printf_number_buffer.buffer_sign
    // [1190] printf_number_buffer::format_min_length#0 = printf_uint::format_min_length#10
    // [1191] printf_number_buffer::format_zero_padding#0 = printf_uint::format_zero_padding#10
    // [1192] call printf_number_buffer
  // Print using format
    // [1450] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    // [1450] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#0 [phi:printf_uint::@2->printf_number_buffer#0] -- register_copy 
    // [1450] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_uint::@2->printf_number_buffer#1] -- register_copy 
    // [1450] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#0 [phi:printf_uint::@2->printf_number_buffer#2] -- register_copy 
    // [1450] phi printf_number_buffer::format_min_length#2 = printf_number_buffer::format_min_length#0 [phi:printf_uint::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [1193] return 
    rts
}
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __zp($34) unsigned int strlen(__zp($40) char *str)
strlen: {
    .label return = $34
    .label len = $34
    .label str = $40
    // [1195] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [1195] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z len
    sta.z len+1
    // [1195] phi strlen::str#6 = strlen::str#8 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [1196] if(0!=*strlen::str#6) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [1197] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [1198] strlen::len#1 = ++ strlen::len#2 -- vwuz1=_inc_vwuz1 
    inc.z len
    bne !+
    inc.z len+1
  !:
    // str++;
    // [1199] strlen::str#1 = ++ strlen::str#6 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [1195] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [1195] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [1195] phi strlen::str#6 = strlen::str#1 [phi:strlen::@2->strlen::@1#1] -- register_copy 
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
// void cbm_k_setlfs(__zp($f8) volatile char channel, __zp($f7) volatile char device, __zp($f2) volatile char command)
cbm_k_setlfs: {
    .label channel = $f8
    .label device = $f7
    .label command = $f2
    // asm
    // asm { ldxdevice ldachannel ldycommand jsrCBM_SETLFS  }
    ldx device
    lda channel
    ldy command
    jsr CBM_SETLFS
    // cbm_k_setlfs::@return
    // }
    // [1201] return 
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
// __zp($da) int ferror(__zp($79) struct $2 *stream)
ferror: {
    .label ferror__6 = $ae
    .label ferror__15 = $6e
    .label cbm_k_setnam1_filename = $f4
    .label cbm_k_setnam1_filename_len = $ee
    .label cbm_k_setnam1_ferror__0 = $34
    .label cbm_k_chkin1_channel = $f3
    .label cbm_k_chkin1_status = $ef
    .label cbm_k_chrin1_ch = $f0
    .label cbm_k_readst1_status = $d4
    .label cbm_k_close1_channel = $f1
    .label cbm_k_chrin2_ch = $d5
    .label stream = $79
    .label return = $da
    .label sp = $66
    .label cbm_k_chrin1_return = $6e
    .label ch = $6e
    .label cbm_k_readst1_return = $ae
    .label st = $ae
    .label errno_len = $ab
    .label cbm_k_chrin2_return = $6e
    .label errno_parsed = $b8
    // unsigned char sp = (unsigned char)stream
    // [1202] ferror::sp#0 = (char)ferror::stream#0 -- vbuz1=_byte_pssz2 
    lda.z stream
    sta.z sp
    // cbm_k_setlfs(15, 8, 15)
    // [1203] cbm_k_setlfs::channel = $f -- vbuz1=vbuc1 
    lda #$f
    sta.z cbm_k_setlfs.channel
    // [1204] cbm_k_setlfs::device = 8 -- vbuz1=vbuc1 
    lda #8
    sta.z cbm_k_setlfs.device
    // [1205] cbm_k_setlfs::command = $f -- vbuz1=vbuc1 
    lda #$f
    sta.z cbm_k_setlfs.command
    // [1206] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // ferror::@11
    // cbm_k_setnam("")
    // [1207] ferror::cbm_k_setnam1_filename = ferror::$18 -- pbuz1=pbuc1 
    lda #<ferror__18
    sta.z cbm_k_setnam1_filename
    lda #>ferror__18
    sta.z cbm_k_setnam1_filename+1
    // ferror::cbm_k_setnam1
    // strlen(filename)
    // [1208] strlen::str#5 = ferror::cbm_k_setnam1_filename -- pbuz1=pbuz2 
    lda.z cbm_k_setnam1_filename
    sta.z strlen.str
    lda.z cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [1209] call strlen
    // [1194] phi from ferror::cbm_k_setnam1 to strlen [phi:ferror::cbm_k_setnam1->strlen]
    // [1194] phi strlen::str#8 = strlen::str#5 [phi:ferror::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [1210] strlen::return#12 = strlen::len#2
    // ferror::@12
    // [1211] ferror::cbm_k_setnam1_$0 = strlen::return#12
    // char filename_len = (char)strlen(filename)
    // [1212] ferror::cbm_k_setnam1_filename_len = (char)ferror::cbm_k_setnam1_$0 -- vbuz1=_byte_vwuz2 
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
    // [1215] ferror::cbm_k_chkin1_channel = $f -- vbuz1=vbuc1 
    lda #$f
    sta.z cbm_k_chkin1_channel
    // ferror::cbm_k_chkin1
    // char status
    // [1216] ferror::cbm_k_chkin1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // ferror::cbm_k_chrin1
    // char ch
    // [1218] ferror::cbm_k_chrin1_ch = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chrin1_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin1_ch
    // return ch;
    // [1220] ferror::cbm_k_chrin1_return#0 = ferror::cbm_k_chrin1_ch -- vbuz1=vbuz2 
    sta.z cbm_k_chrin1_return
    // ferror::cbm_k_chrin1_@return
    // }
    // [1221] ferror::cbm_k_chrin1_return#1 = ferror::cbm_k_chrin1_return#0
    // ferror::@7
    // char ch = cbm_k_chrin()
    // [1222] ferror::ch#0 = ferror::cbm_k_chrin1_return#1
    // [1223] phi from ferror::@7 to ferror::cbm_k_readst1 [phi:ferror::@7->ferror::cbm_k_readst1]
    // [1223] phi __errno#11 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#0] -- vwsz1=vwsc1 
    lda #<0
    sta.z __errno
    sta.z __errno+1
    // [1223] phi ferror::errno_len#10 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#1] -- vbuz1=vbuc1 
    sta.z errno_len
    // [1223] phi ferror::ch#10 = ferror::ch#0 [phi:ferror::@7->ferror::cbm_k_readst1#2] -- register_copy 
    // [1223] phi ferror::errno_parsed#2 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#3] -- vbuz1=vbuc1 
    sta.z errno_parsed
    // ferror::cbm_k_readst1
  cbm_k_readst1:
    // char status
    // [1224] ferror::cbm_k_readst1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [1226] ferror::cbm_k_readst1_return#0 = ferror::cbm_k_readst1_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst1_return
    // ferror::cbm_k_readst1_@return
    // }
    // [1227] ferror::cbm_k_readst1_return#1 = ferror::cbm_k_readst1_return#0
    // ferror::@8
    // cbm_k_readst()
    // [1228] ferror::$6 = ferror::cbm_k_readst1_return#1
    // st = cbm_k_readst()
    // [1229] ferror::st#1 = ferror::$6
    // while (!(st = cbm_k_readst()))
    // [1230] if(0==ferror::st#1) goto ferror::@1 -- 0_eq_vbuz1_then_la1 
    lda.z st
    beq __b1
    // ferror::@2
    // __status = st
    // [1231] ((char *)&__stdio_file+$46)[ferror::sp#0] = ferror::st#1 -- pbuc1_derefidx_vbuz1=vbuz2 
    ldy.z sp
    sta __stdio_file+$46,y
    // cbm_k_close(15)
    // [1232] ferror::cbm_k_close1_channel = $f -- vbuz1=vbuc1 
    lda #$f
    sta.z cbm_k_close1_channel
    // ferror::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // ferror::@9
    // return __errno;
    // [1234] ferror::return#1 = __errno#11 -- vwsz1=vwsz2 
    lda.z __errno
    sta.z return
    lda.z __errno+1
    sta.z return+1
    // ferror::@return
    // }
    // [1235] return 
    rts
    // ferror::@1
  __b1:
    // if (!errno_parsed)
    // [1236] if(0!=ferror::errno_parsed#2) goto ferror::@3 -- 0_neq_vbuz1_then_la1 
    lda.z errno_parsed
    bne __b3
    // ferror::@4
    // if (ch == ',')
    // [1237] if(ferror::ch#10!=',') goto ferror::@3 -- vbuz1_neq_vbuc1_then_la1 
    lda #','
    cmp.z ch
    bne __b3
    // ferror::@5
    // errno_parsed++;
    // [1238] ferror::errno_parsed#1 = ++ ferror::errno_parsed#2 -- vbuz1=_inc_vbuz1 
    inc.z errno_parsed
    // strncpy(temp, __errno_error, errno_len+1)
    // [1239] strncpy::n#0 = ferror::errno_len#10 + 1 -- vwuz1=vbuz2_plus_1 
    lda.z errno_len
    clc
    adc #1
    sta.z strncpy.n
    lda #0
    adc #0
    sta.z strncpy.n+1
    // [1240] call strncpy
    // [1590] phi from ferror::@5 to strncpy [phi:ferror::@5->strncpy]
    jsr strncpy
    // [1241] phi from ferror::@5 to ferror::@13 [phi:ferror::@5->ferror::@13]
    // ferror::@13
    // atoi(temp)
    // [1242] call atoi
    // [1254] phi from ferror::@13 to atoi [phi:ferror::@13->atoi]
    // [1254] phi atoi::str#2 = ferror::temp [phi:ferror::@13->atoi#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z atoi.str
    lda #>temp
    sta.z atoi.str+1
    jsr atoi
    // atoi(temp)
    // [1243] atoi::return#4 = atoi::return#2
    // ferror::@14
    // __errno = atoi(temp)
    // [1244] __errno#2 = atoi::return#4 -- vwsz1=vwsz2 
    lda.z atoi.return
    sta.z __errno
    lda.z atoi.return+1
    sta.z __errno+1
    // [1245] phi from ferror::@1 ferror::@14 ferror::@4 to ferror::@3 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3]
    // [1245] phi __errno#63 = __errno#11 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#0] -- register_copy 
    // [1245] phi ferror::errno_parsed#11 = ferror::errno_parsed#2 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#1] -- register_copy 
    // ferror::@3
  __b3:
    // __errno_error[errno_len] = ch
    // [1246] __errno_error[ferror::errno_len#10] = ferror::ch#10 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z ch
    ldy.z errno_len
    sta __errno_error,y
    // errno_len++;
    // [1247] ferror::errno_len#1 = ++ ferror::errno_len#10 -- vbuz1=_inc_vbuz1 
    inc.z errno_len
    // ferror::cbm_k_chrin2
    // char ch
    // [1248] ferror::cbm_k_chrin2_ch = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chrin2_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin2_ch
    // return ch;
    // [1250] ferror::cbm_k_chrin2_return#0 = ferror::cbm_k_chrin2_ch -- vbuz1=vbuz2 
    sta.z cbm_k_chrin2_return
    // ferror::cbm_k_chrin2_@return
    // }
    // [1251] ferror::cbm_k_chrin2_return#1 = ferror::cbm_k_chrin2_return#0
    // ferror::@10
    // cbm_k_chrin()
    // [1252] ferror::$15 = ferror::cbm_k_chrin2_return#1
    // ch = cbm_k_chrin()
    // [1253] ferror::ch#1 = ferror::$15
    // [1223] phi from ferror::@10 to ferror::cbm_k_readst1 [phi:ferror::@10->ferror::cbm_k_readst1]
    // [1223] phi __errno#11 = __errno#63 [phi:ferror::@10->ferror::cbm_k_readst1#0] -- register_copy 
    // [1223] phi ferror::errno_len#10 = ferror::errno_len#1 [phi:ferror::@10->ferror::cbm_k_readst1#1] -- register_copy 
    // [1223] phi ferror::ch#10 = ferror::ch#1 [phi:ferror::@10->ferror::cbm_k_readst1#2] -- register_copy 
    // [1223] phi ferror::errno_parsed#2 = ferror::errno_parsed#11 [phi:ferror::@10->ferror::cbm_k_readst1#3] -- register_copy 
    jmp cbm_k_readst1
  .segment Data
    temp: .fill 4, 0
    ferror__18: .text ""
    .byte 0
}
.segment Code
  // atoi
// Converts the string argument str to an integer.
// __zp($52) int atoi(__zp($5d) const char *str)
atoi: {
    .label atoi__6 = $52
    .label atoi__7 = $52
    .label res = $52
    // Initialize sign as positive
    .label i = $4e
    .label return = $52
    .label str = $5d
    // Initialize result
    .label negative = $5f
    .label atoi__10 = $5a
    .label atoi__11 = $52
    // if (str[i] == '-')
    // [1255] if(*atoi::str#2!='-') goto atoi::@3 -- _deref_pbuz1_neq_vbuc1_then_la1 
    ldy #0
    lda (str),y
    cmp #'-'
    bne __b2
    // [1256] phi from atoi to atoi::@2 [phi:atoi->atoi::@2]
    // atoi::@2
    // [1257] phi from atoi::@2 to atoi::@3 [phi:atoi::@2->atoi::@3]
    // [1257] phi atoi::negative#2 = 1 [phi:atoi::@2->atoi::@3#0] -- vbuz1=vbuc1 
    lda #1
    sta.z negative
    // [1257] phi atoi::res#2 = 0 [phi:atoi::@2->atoi::@3#1] -- vwsz1=vwsc1 
    tya
    sta.z res
    sta.z res+1
    // [1257] phi atoi::i#4 = 1 [phi:atoi::@2->atoi::@3#2] -- vbuz1=vbuc1 
    lda #1
    sta.z i
    jmp __b3
  // Iterate through all digits and update the result
    // [1257] phi from atoi to atoi::@3 [phi:atoi->atoi::@3]
  __b2:
    // [1257] phi atoi::negative#2 = 0 [phi:atoi->atoi::@3#0] -- vbuz1=vbuc1 
    lda #0
    sta.z negative
    // [1257] phi atoi::res#2 = 0 [phi:atoi->atoi::@3#1] -- vwsz1=vwsc1 
    sta.z res
    sta.z res+1
    // [1257] phi atoi::i#4 = 0 [phi:atoi->atoi::@3#2] -- vbuz1=vbuc1 
    sta.z i
    // atoi::@3
  __b3:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [1258] if(atoi::str#2[atoi::i#4]<'0') goto atoi::@5 -- pbuz1_derefidx_vbuz2_lt_vbuc1_then_la1 
    ldy.z i
    lda (str),y
    cmp #'0'
    bcc __b5
    // atoi::@6
    // [1259] if(atoi::str#2[atoi::i#4]<='9') goto atoi::@4 -- pbuz1_derefidx_vbuz2_le_vbuc1_then_la1 
    lda (str),y
    cmp #'9'
    bcc __b4
    beq __b4
    // atoi::@5
  __b5:
    // if(negative)
    // [1260] if(0!=atoi::negative#2) goto atoi::@1 -- 0_neq_vbuz1_then_la1 
    // Return result with sign
    lda.z negative
    bne __b1
    // [1262] phi from atoi::@1 atoi::@5 to atoi::@return [phi:atoi::@1/atoi::@5->atoi::@return]
    // [1262] phi atoi::return#2 = atoi::return#0 [phi:atoi::@1/atoi::@5->atoi::@return#0] -- register_copy 
    rts
    // atoi::@1
  __b1:
    // return -res;
    // [1261] atoi::return#0 = - atoi::res#2 -- vwsz1=_neg_vwsz1 
    lda #0
    sec
    sbc.z return
    sta.z return
    lda #0
    sbc.z return+1
    sta.z return+1
    // atoi::@return
    // }
    // [1263] return 
    rts
    // atoi::@4
  __b4:
    // res * 10
    // [1264] atoi::$10 = atoi::res#2 << 2 -- vwsz1=vwsz2_rol_2 
    lda.z res
    asl
    sta.z atoi__10
    lda.z res+1
    rol
    sta.z atoi__10+1
    asl.z atoi__10
    rol.z atoi__10+1
    // [1265] atoi::$11 = atoi::$10 + atoi::res#2 -- vwsz1=vwsz2_plus_vwsz1 
    clc
    lda.z atoi__11
    adc.z atoi__10
    sta.z atoi__11
    lda.z atoi__11+1
    adc.z atoi__10+1
    sta.z atoi__11+1
    // [1266] atoi::$6 = atoi::$11 << 1 -- vwsz1=vwsz1_rol_1 
    asl.z atoi__6
    rol.z atoi__6+1
    // res * 10 + str[i]
    // [1267] atoi::$7 = atoi::$6 + atoi::str#2[atoi::i#4] -- vwsz1=vwsz1_plus_pbuz2_derefidx_vbuz3 
    ldy.z i
    lda.z atoi__7
    clc
    adc (str),y
    sta.z atoi__7
    bcc !+
    inc.z atoi__7+1
  !:
    // res = res * 10 + str[i] - '0'
    // [1268] atoi::res#1 = atoi::$7 - '0' -- vwsz1=vwsz1_minus_vbuc1 
    lda.z res
    sec
    sbc #'0'
    sta.z res
    bcs !+
    dec.z res+1
  !:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [1269] atoi::i#2 = ++ atoi::i#4 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1257] phi from atoi::@4 to atoi::@3 [phi:atoi::@4->atoi::@3]
    // [1257] phi atoi::negative#2 = atoi::negative#2 [phi:atoi::@4->atoi::@3#0] -- register_copy 
    // [1257] phi atoi::res#2 = atoi::res#1 [phi:atoi::@4->atoi::@3#1] -- register_copy 
    // [1257] phi atoi::i#4 = atoi::i#2 [phi:atoi::@4->atoi::@3#2] -- register_copy 
    jmp __b3
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
// __zp($34) unsigned int fgets(__zp($69) char *ptr, unsigned int size, __zp($4c) struct $2 *stream)
fgets: {
    .label fgets__1 = $ae
    .label fgets__8 = $67
    .label fgets__9 = $6b
    .label fgets__13 = $6e
    .label cbm_k_chkin1_channel = $e1
    .label cbm_k_chkin1_status = $d6
    .label cbm_k_readst1_status = $d7
    .label cbm_k_readst2_status = $73
    .label sp = $66
    .label cbm_k_readst1_return = $ae
    .label return = $34
    .label bytes = $54
    .label cbm_k_readst2_return = $67
    .label read = $34
    .label ptr = $69
    .label remaining = $71
    .label stream = $4c
    // unsigned char sp = (unsigned char)stream
    // [1270] fgets::sp#0 = (char)fgets::stream#0 -- vbuz1=_byte_pssz2 
    lda.z stream
    sta.z sp
    // cbm_k_chkin(__logical)
    // [1271] fgets::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fgets::sp#0] -- vbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda __stdio_file+$40,y
    sta.z cbm_k_chkin1_channel
    // fgets::cbm_k_chkin1
    // char status
    // [1272] fgets::cbm_k_chkin1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fgets::cbm_k_readst1
    // char status
    // [1274] fgets::cbm_k_readst1_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [1276] fgets::cbm_k_readst1_return#0 = fgets::cbm_k_readst1_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst1_return
    // fgets::cbm_k_readst1_@return
    // }
    // [1277] fgets::cbm_k_readst1_return#1 = fgets::cbm_k_readst1_return#0
    // fgets::@9
    // cbm_k_readst()
    // [1278] fgets::$1 = fgets::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [1279] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$1 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fgets__1
    ldy.z sp
    sta __stdio_file+$46,y
    // if (__status)
    // [1280] if(0==((char *)&__stdio_file+$46)[fgets::sp#0]) goto fgets::@1 -- 0_eq_pbuc1_derefidx_vbuz1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b8
    // [1281] phi from fgets::@10 fgets::@3 fgets::@9 to fgets::@return [phi:fgets::@10/fgets::@3/fgets::@9->fgets::@return]
  __b1:
    // [1281] phi fgets::return#1 = 0 [phi:fgets::@10/fgets::@3/fgets::@9->fgets::@return#0] -- vwuz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fgets::@return
    // }
    // [1282] return 
    rts
    // [1283] phi from fgets::@13 to fgets::@1 [phi:fgets::@13->fgets::@1]
    // [1283] phi fgets::read#10 = fgets::read#1 [phi:fgets::@13->fgets::@1#0] -- register_copy 
    // [1283] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@13->fgets::@1#1] -- register_copy 
    // [1283] phi fgets::ptr#10 = fgets::ptr#12 [phi:fgets::@13->fgets::@1#2] -- register_copy 
    // [1283] phi from fgets::@9 to fgets::@1 [phi:fgets::@9->fgets::@1]
  __b8:
    // [1283] phi fgets::read#10 = 0 [phi:fgets::@9->fgets::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z read
    sta.z read+1
    // [1283] phi fgets::remaining#11 = flash_read::b#0 [phi:fgets::@9->fgets::@1#1] -- vwuz1=vbuc1 
    lda #<flash_read.b
    sta.z remaining
    lda #>flash_read.b
    sta.z remaining+1
    // [1283] phi fgets::ptr#10 = fgets::ptr#2 [phi:fgets::@9->fgets::@1#2] -- register_copy 
    // fgets::@1
    // fgets::@6
  __b6:
    // if (remaining >= 512)
    // [1284] if(fgets::remaining#11>=$200) goto fgets::@2 -- vwuz1_ge_vwuc1_then_la1 
    lda.z remaining+1
    cmp #>$200
    bcc !+
    beq !__b2+
    jmp __b2
  !__b2:
    lda.z remaining
    cmp #<$200
    bcc !__b2+
    jmp __b2
  !__b2:
  !:
    // fgets::@7
    // cx16_k_macptr(remaining, ptr)
    // [1285] cx16_k_macptr::bytes = fgets::remaining#11 -- vbuz1=vwuz2 
    lda.z remaining
    sta.z cx16_k_macptr.bytes
    // [1286] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [1287] call cx16_k_macptr
    jsr cx16_k_macptr
    // [1288] cx16_k_macptr::return#4 = cx16_k_macptr::return#1
    // fgets::@12
  __b12:
    // bytes = cx16_k_macptr(remaining, ptr)
    // [1289] fgets::bytes#3 = cx16_k_macptr::return#4
    // [1290] phi from fgets::@11 fgets::@12 to fgets::cbm_k_readst2 [phi:fgets::@11/fgets::@12->fgets::cbm_k_readst2]
    // [1290] phi fgets::bytes#10 = fgets::bytes#2 [phi:fgets::@11/fgets::@12->fgets::cbm_k_readst2#0] -- register_copy 
    // fgets::cbm_k_readst2
    // char status
    // [1291] fgets::cbm_k_readst2_status = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [1293] fgets::cbm_k_readst2_return#0 = fgets::cbm_k_readst2_status -- vbuz1=vbuz2 
    sta.z cbm_k_readst2_return
    // fgets::cbm_k_readst2_@return
    // }
    // [1294] fgets::cbm_k_readst2_return#1 = fgets::cbm_k_readst2_return#0
    // fgets::@10
    // cbm_k_readst()
    // [1295] fgets::$8 = fgets::cbm_k_readst2_return#1
    // __status = cbm_k_readst()
    // [1296] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$8 -- pbuc1_derefidx_vbuz1=vbuz2 
    lda.z fgets__8
    ldy.z sp
    sta __stdio_file+$46,y
    // __status & 0xBF
    // [1297] fgets::$9 = ((char *)&__stdio_file+$46)[fgets::sp#0] & $bf -- vbuz1=pbuc1_derefidx_vbuz2_band_vbuc2 
    lda #$bf
    and __stdio_file+$46,y
    sta.z fgets__9
    // if (__status & 0xBF)
    // [1298] if(0==fgets::$9) goto fgets::@3 -- 0_eq_vbuz1_then_la1 
    beq __b3
    jmp __b1
    // fgets::@3
  __b3:
    // if (bytes == 0xFFFF)
    // [1299] if(fgets::bytes#10!=$ffff) goto fgets::@4 -- vwuz1_neq_vwuc1_then_la1 
    lda.z bytes+1
    cmp #>$ffff
    bne __b4
    lda.z bytes
    cmp #<$ffff
    bne __b4
    jmp __b1
    // fgets::@4
  __b4:
    // read += bytes
    // [1300] fgets::read#1 = fgets::read#10 + fgets::bytes#10 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z read
    adc.z bytes
    sta.z read
    lda.z read+1
    adc.z bytes+1
    sta.z read+1
    // ptr += bytes
    // [1301] fgets::ptr#0 = fgets::ptr#10 + fgets::bytes#10 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z ptr
    adc.z bytes
    sta.z ptr
    lda.z ptr+1
    adc.z bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [1302] fgets::$13 = byte1  fgets::ptr#0 -- vbuz1=_byte1_pbuz2 
    sta.z fgets__13
    // if (BYTE1(ptr) == 0xC0)
    // [1303] if(fgets::$13!=$c0) goto fgets::@5 -- vbuz1_neq_vbuc1_then_la1 
    lda #$c0
    cmp.z fgets__13
    bne __b5
    // fgets::@8
    // ptr -= 0x2000
    // [1304] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [1305] phi from fgets::@4 fgets::@8 to fgets::@5 [phi:fgets::@4/fgets::@8->fgets::@5]
    // [1305] phi fgets::ptr#12 = fgets::ptr#0 [phi:fgets::@4/fgets::@8->fgets::@5#0] -- register_copy 
    // fgets::@5
  __b5:
    // remaining -= bytes
    // [1306] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#10 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z remaining
    sec
    sbc.z bytes
    sta.z remaining
    lda.z remaining+1
    sbc.z bytes+1
    sta.z remaining+1
    // while ((__status == 0) && ((size && remaining) || !size))
    // [1307] if(((char *)&__stdio_file+$46)[fgets::sp#0]==0) goto fgets::@13 -- pbuc1_derefidx_vbuz1_eq_0_then_la1 
    ldy.z sp
    lda __stdio_file+$46,y
    cmp #0
    beq __b13
    // [1281] phi from fgets::@13 fgets::@5 to fgets::@return [phi:fgets::@13/fgets::@5->fgets::@return]
    // [1281] phi fgets::return#1 = fgets::read#1 [phi:fgets::@13/fgets::@5->fgets::@return#0] -- register_copy 
    rts
    // fgets::@13
  __b13:
    // while ((__status == 0) && ((size && remaining) || !size))
    // [1308] if(0!=fgets::remaining#1) goto fgets::@1 -- 0_neq_vwuz1_then_la1 
    lda.z remaining
    ora.z remaining+1
    beq !__b6+
    jmp __b6
  !__b6:
    rts
    // fgets::@2
  __b2:
    // cx16_k_macptr(512, ptr)
    // [1309] cx16_k_macptr::bytes = $200 -- vbuz1=vwuc1 
    lda #<$200
    sta.z cx16_k_macptr.bytes
    // [1310] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [1311] call cx16_k_macptr
    jsr cx16_k_macptr
    // [1312] cx16_k_macptr::return#3 = cx16_k_macptr::return#1
    // fgets::@11
    // bytes = cx16_k_macptr(512, ptr)
    // [1313] fgets::bytes#2 = cx16_k_macptr::return#3
    jmp __b12
}
  // snprintf_init
/// Initialize the snprintf() state
// void snprintf_init(__zp($40) char *s, unsigned int n)
snprintf_init: {
    .label s = $40
    // __snprintf_capacity = n
    // [1315] __snprintf_capacity = $ffff -- vwum1=vwuc1 
    lda #<$ffff
    sta __snprintf_capacity
    lda #>$ffff
    sta __snprintf_capacity+1
    // __snprintf_size = 0
    // [1316] __snprintf_size = 0 -- vwum1=vbuc1 
    lda #<0
    sta __snprintf_size
    sta __snprintf_size+1
    // __snprintf_buffer = s
    // [1317] __snprintf_buffer = snprintf_init::s#8 -- pbuz1=pbuz2 
    lda.z s
    sta.z __snprintf_buffer
    lda.z s+1
    sta.z __snprintf_buffer+1
    // snprintf_init::@return
    // }
    // [1318] return 
    rts
}
  // insertup
// Insert a new line, and scroll the upper part of the screen up.
// void insertup(char rows)
insertup: {
    .label insertup__0 = $36
    .label insertup__4 = $32
    .label insertup__6 = $33
    .label insertup__7 = $32
    .label width = $36
    .label y = $2e
    // __conio.width+1
    // [1319] insertup::$0 = *((char *)&__conio+6) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+6
    inc
    sta.z insertup__0
    // unsigned char width = (__conio.width+1) * 2
    // [1320] insertup::width#0 = insertup::$0 << 1 -- vbuz1=vbuz1_rol_1 
    // {asm{.byte $db}}
    asl.z width
    // [1321] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [1321] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [1322] if(insertup::y#2<*((char *)&__conio+1)) goto insertup::@2 -- vbuz1_lt__deref_pbuc1_then_la1 
    lda.z y
    cmp __conio+1
    bcc __b2
    // [1323] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [1324] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [1325] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [1326] insertup::$4 = insertup::y#2 + 1 -- vbuz1=vbuz2_plus_1 
    lda.z y
    inc
    sta.z insertup__4
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [1327] insertup::$6 = insertup::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z insertup__6
    // [1328] insertup::$7 = insertup::$4 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z insertup__7
    // [1329] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z memcpy8_vram_vram.dbank_vram
    // [1330] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__6
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.doffset_vram+1
    // [1331] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z memcpy8_vram_vram.sbank_vram
    // [1332] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwuz1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__7
    lda __conio+$15,y
    sta.z memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta.z memcpy8_vram_vram.soffset_vram+1
    // [1333] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbuz1=vbuz2 
    lda.z width
    sta.z memcpy8_vram_vram.num8_1
    // [1334] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [1335] insertup::y#1 = ++ insertup::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [1321] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [1321] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
    jmp __b1
}
  // clearline
clearline: {
    .label clearline__0 = $24
    .label clearline__1 = $26
    .label clearline__2 = $27
    .label clearline__3 = $25
    .label addr = $30
    .label c = $22
    // unsigned int addr = __conio.offsets[__conio.cursor_y]
    // [1336] clearline::$3 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z clearline__3
    // [1337] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwuz1=pwuc1_derefidx_vbuz2 
    tay
    lda __conio+$15,y
    sta.z addr
    lda __conio+$15+1,y
    sta.z addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1338] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [1339] clearline::$0 = byte0  clearline::addr#0 -- vbuz1=_byte0_vwuz2 
    lda.z addr
    sta.z clearline__0
    // *VERA_ADDRX_L = BYTE0(addr)
    // [1340] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [1341] clearline::$1 = byte1  clearline::addr#0 -- vbuz1=_byte1_vwuz2 
    lda.z addr+1
    sta.z clearline__1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [1342] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [1343] clearline::$2 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clearline__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1344] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [1345] clearline::c#0 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z c
    // [1346] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [1346] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [1347] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1348] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [1349] clearline::c#1 = -- clearline::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [1350] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b1
    // clearline::@return
    // }
    // [1351] return 
    rts
}
  // frame_maskxy
// __zp($3f) char frame_maskxy(__zp($66) char x, __zp($59) char y)
frame_maskxy: {
    .label cpeekcxy1_cpeekc1_frame_maskxy__0 = $67
    .label cpeekcxy1_cpeekc1_frame_maskxy__1 = $6b
    .label cpeekcxy1_cpeekc1_frame_maskxy__2 = $6e
    .label cpeekcxy1_x = $66
    .label cpeekcxy1_y = $59
    .label c = $ab
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
    .label return = $3f
    .label x = $66
    .label y = $59
    // frame_maskxy::cpeekcxy1
    // gotoxy(x,y)
    // [1353] gotoxy::x#5 = frame_maskxy::cpeekcxy1_x#0 -- vbuz1=vbuz2 
    lda.z cpeekcxy1_x
    sta.z gotoxy.x
    // [1354] gotoxy::y#5 = frame_maskxy::cpeekcxy1_y#0 -- vbuz1=vbuz2 
    lda.z cpeekcxy1_y
    sta.z gotoxy.y
    // [1355] call gotoxy
    // [189] phi from frame_maskxy::cpeekcxy1 to gotoxy [phi:frame_maskxy::cpeekcxy1->gotoxy]
    // [189] phi gotoxy::y#18 = gotoxy::y#5 [phi:frame_maskxy::cpeekcxy1->gotoxy#0] -- register_copy 
    // [189] phi gotoxy::x#18 = gotoxy::x#5 [phi:frame_maskxy::cpeekcxy1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // frame_maskxy::cpeekcxy1_cpeekc1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1356] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [1357] frame_maskxy::cpeekcxy1_cpeekc1_$0 = byte0  *((unsigned int *)&__conio+$13) -- vbuz1=_byte0__deref_pwuc1 
    lda __conio+$13
    sta.z cpeekcxy1_cpeekc1_frame_maskxy__0
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [1358] *VERA_ADDRX_L = frame_maskxy::cpeekcxy1_cpeekc1_$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [1359] frame_maskxy::cpeekcxy1_cpeekc1_$1 = byte1  *((unsigned int *)&__conio+$13) -- vbuz1=_byte1__deref_pwuc1 
    lda __conio+$13+1
    sta.z cpeekcxy1_cpeekc1_frame_maskxy__1
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [1360] *VERA_ADDRX_M = frame_maskxy::cpeekcxy1_cpeekc1_$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_0
    // [1361] frame_maskxy::cpeekcxy1_cpeekc1_$2 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z cpeekcxy1_cpeekc1_frame_maskxy__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_0
    // [1362] *VERA_ADDRX_H = frame_maskxy::cpeekcxy1_cpeekc1_$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // return *VERA_DATA0;
    // [1363] frame_maskxy::c#0 = *VERA_DATA0 -- vbuz1=_deref_pbuc1 
    lda VERA_DATA0
    sta.z c
    // frame_maskxy::@12
    // case 0x70: // DR corner.
    //             return 0b0110;
    // [1364] if(frame_maskxy::c#0==$70) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$70
    cmp.z c
    beq __b2
    // frame_maskxy::@1
    // case 0x6E: // DL corner.
    //             return 0b0011;
    // [1365] if(frame_maskxy::c#0==$6e) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6e
    cmp.z c
    beq __b1
    // frame_maskxy::@2
    // case 0x6D: // UR corner.
    //             return 0b1100;
    // [1366] if(frame_maskxy::c#0==$6d) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6d
    cmp.z c
    beq __b3
    // frame_maskxy::@3
    // case 0x7D: // UL corner.
    //             return 0b1001;
    // [1367] if(frame_maskxy::c#0==$7d) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$7d
    cmp.z c
    beq __b4
    // frame_maskxy::@4
    // case 0x40: // HL line.
    //             return 0b0101;
    // [1368] if(frame_maskxy::c#0==$40) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$40
    cmp.z c
    beq __b5
    // frame_maskxy::@5
    // case 0x5D: // VL line.
    //             return 0b1010;
    // [1369] if(frame_maskxy::c#0==$5d) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$5d
    cmp.z c
    beq __b6
    // frame_maskxy::@6
    // case 0x6B: // VR junction.
    //             return 0b1110;
    // [1370] if(frame_maskxy::c#0==$6b) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6b
    cmp.z c
    beq __b7
    // frame_maskxy::@7
    // case 0x73: // VL junction.
    //             return 0b1011;
    // [1371] if(frame_maskxy::c#0==$73) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$73
    cmp.z c
    beq __b8
    // frame_maskxy::@8
    // case 0x72: // HD junction.
    //             return 0b0111;
    // [1372] if(frame_maskxy::c#0==$72) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$72
    cmp.z c
    beq __b9
    // frame_maskxy::@9
    // case 0x71: // HU junction.
    //             return 0b1101;
    // [1373] if(frame_maskxy::c#0==$71) goto frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$71
    cmp.z c
    beq __b10
    // frame_maskxy::@10
    // case 0x5B: // HV junction.
    //             return 0b1111;
    // [1374] if(frame_maskxy::c#0==$5b) goto frame_maskxy::@11 -- vbuz1_eq_vbuc1_then_la1 
    lda #$5b
    cmp.z c
    beq __b11
    // [1376] phi from frame_maskxy::@10 to frame_maskxy::@return [phi:frame_maskxy::@10->frame_maskxy::@return]
    // [1376] phi frame_maskxy::return#12 = 0 [phi:frame_maskxy::@10->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #0
    sta.z return
    rts
    // [1375] phi from frame_maskxy::@10 to frame_maskxy::@11 [phi:frame_maskxy::@10->frame_maskxy::@11]
    // frame_maskxy::@11
  __b11:
    // [1376] phi from frame_maskxy::@11 to frame_maskxy::@return [phi:frame_maskxy::@11->frame_maskxy::@return]
    // [1376] phi frame_maskxy::return#12 = $f [phi:frame_maskxy::@11->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$f
    sta.z return
    rts
    // [1376] phi from frame_maskxy::@1 to frame_maskxy::@return [phi:frame_maskxy::@1->frame_maskxy::@return]
  __b1:
    // [1376] phi frame_maskxy::return#12 = 3 [phi:frame_maskxy::@1->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #3
    sta.z return
    rts
    // [1376] phi from frame_maskxy::@12 to frame_maskxy::@return [phi:frame_maskxy::@12->frame_maskxy::@return]
  __b2:
    // [1376] phi frame_maskxy::return#12 = 6 [phi:frame_maskxy::@12->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #6
    sta.z return
    rts
    // [1376] phi from frame_maskxy::@2 to frame_maskxy::@return [phi:frame_maskxy::@2->frame_maskxy::@return]
  __b3:
    // [1376] phi frame_maskxy::return#12 = $c [phi:frame_maskxy::@2->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$c
    sta.z return
    rts
    // [1376] phi from frame_maskxy::@3 to frame_maskxy::@return [phi:frame_maskxy::@3->frame_maskxy::@return]
  __b4:
    // [1376] phi frame_maskxy::return#12 = 9 [phi:frame_maskxy::@3->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #9
    sta.z return
    rts
    // [1376] phi from frame_maskxy::@4 to frame_maskxy::@return [phi:frame_maskxy::@4->frame_maskxy::@return]
  __b5:
    // [1376] phi frame_maskxy::return#12 = 5 [phi:frame_maskxy::@4->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #5
    sta.z return
    rts
    // [1376] phi from frame_maskxy::@5 to frame_maskxy::@return [phi:frame_maskxy::@5->frame_maskxy::@return]
  __b6:
    // [1376] phi frame_maskxy::return#12 = $a [phi:frame_maskxy::@5->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$a
    sta.z return
    rts
    // [1376] phi from frame_maskxy::@6 to frame_maskxy::@return [phi:frame_maskxy::@6->frame_maskxy::@return]
  __b7:
    // [1376] phi frame_maskxy::return#12 = $e [phi:frame_maskxy::@6->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$e
    sta.z return
    rts
    // [1376] phi from frame_maskxy::@7 to frame_maskxy::@return [phi:frame_maskxy::@7->frame_maskxy::@return]
  __b8:
    // [1376] phi frame_maskxy::return#12 = $b [phi:frame_maskxy::@7->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$b
    sta.z return
    rts
    // [1376] phi from frame_maskxy::@8 to frame_maskxy::@return [phi:frame_maskxy::@8->frame_maskxy::@return]
  __b9:
    // [1376] phi frame_maskxy::return#12 = 7 [phi:frame_maskxy::@8->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #7
    sta.z return
    rts
    // [1376] phi from frame_maskxy::@9 to frame_maskxy::@return [phi:frame_maskxy::@9->frame_maskxy::@return]
  __b10:
    // [1376] phi frame_maskxy::return#12 = $d [phi:frame_maskxy::@9->frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$d
    sta.z return
    // frame_maskxy::@return
    // }
    // [1377] return 
    rts
}
  // frame_char
// __zp($43) char frame_char(__zp($3f) char mask)
frame_char: {
    .label return = $43
    .label mask = $3f
    // case 0b0110:
    //             return 0x70;
    // [1379] if(frame_char::mask#10==6) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #6
    cmp.z mask
    beq __b1
    // frame_char::@1
    // case 0b0011:
    //             return 0x6E;
    // [1380] if(frame_char::mask#10==3) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // DR corner.
    lda #3
    cmp.z mask
    beq __b2
    // frame_char::@2
    // case 0b1100:
    //             return 0x6D;
    // [1381] if(frame_char::mask#10==$c) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // DL corner.
    lda #$c
    cmp.z mask
    beq __b3
    // frame_char::@3
    // case 0b1001:
    //             return 0x7D;
    // [1382] if(frame_char::mask#10==9) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // UR corner.
    lda #9
    cmp.z mask
    beq __b4
    // frame_char::@4
    // case 0b0101:
    //             return 0x40;
    // [1383] if(frame_char::mask#10==5) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // UL corner.
    lda #5
    cmp.z mask
    beq __b5
    // frame_char::@5
    // case 0b1010:
    //             return 0x5D;
    // [1384] if(frame_char::mask#10==$a) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // HL line.
    lda #$a
    cmp.z mask
    beq __b6
    // frame_char::@6
    // case 0b1110:
    //             return 0x6B;
    // [1385] if(frame_char::mask#10==$e) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VL line.
    lda #$e
    cmp.z mask
    beq __b7
    // frame_char::@7
    // case 0b1011:
    //             return 0x73;
    // [1386] if(frame_char::mask#10==$b) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VR junction.
    lda #$b
    cmp.z mask
    beq __b8
    // frame_char::@8
    // case 0b0111:
    //             return 0x72;
    // [1387] if(frame_char::mask#10==7) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VL junction.
    lda #7
    cmp.z mask
    beq __b9
    // frame_char::@9
    // case 0b1101:
    //             return 0x71;
    // [1388] if(frame_char::mask#10==$d) goto frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // HD junction.
    lda #$d
    cmp.z mask
    beq __b10
    // frame_char::@10
    // case 0b1111:
    //             return 0x5B;
    // [1389] if(frame_char::mask#10==$f) goto frame_char::@11 -- vbuz1_eq_vbuc1_then_la1 
    // HU junction.
    lda #$f
    cmp.z mask
    beq __b11
    // [1391] phi from frame_char::@10 to frame_char::@return [phi:frame_char::@10->frame_char::@return]
    // [1391] phi frame_char::return#12 = $20 [phi:frame_char::@10->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$20
    sta.z return
    rts
    // [1390] phi from frame_char::@10 to frame_char::@11 [phi:frame_char::@10->frame_char::@11]
    // frame_char::@11
  __b11:
    // [1391] phi from frame_char::@11 to frame_char::@return [phi:frame_char::@11->frame_char::@return]
    // [1391] phi frame_char::return#12 = $5b [phi:frame_char::@11->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z return
    rts
    // [1391] phi from frame_char to frame_char::@return [phi:frame_char->frame_char::@return]
  __b1:
    // [1391] phi frame_char::return#12 = $70 [phi:frame_char->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$70
    sta.z return
    rts
    // [1391] phi from frame_char::@1 to frame_char::@return [phi:frame_char::@1->frame_char::@return]
  __b2:
    // [1391] phi frame_char::return#12 = $6e [phi:frame_char::@1->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6e
    sta.z return
    rts
    // [1391] phi from frame_char::@2 to frame_char::@return [phi:frame_char::@2->frame_char::@return]
  __b3:
    // [1391] phi frame_char::return#12 = $6d [phi:frame_char::@2->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6d
    sta.z return
    rts
    // [1391] phi from frame_char::@3 to frame_char::@return [phi:frame_char::@3->frame_char::@return]
  __b4:
    // [1391] phi frame_char::return#12 = $7d [phi:frame_char::@3->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$7d
    sta.z return
    rts
    // [1391] phi from frame_char::@4 to frame_char::@return [phi:frame_char::@4->frame_char::@return]
  __b5:
    // [1391] phi frame_char::return#12 = $40 [phi:frame_char::@4->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z return
    rts
    // [1391] phi from frame_char::@5 to frame_char::@return [phi:frame_char::@5->frame_char::@return]
  __b6:
    // [1391] phi frame_char::return#12 = $5d [phi:frame_char::@5->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z return
    rts
    // [1391] phi from frame_char::@6 to frame_char::@return [phi:frame_char::@6->frame_char::@return]
  __b7:
    // [1391] phi frame_char::return#12 = $6b [phi:frame_char::@6->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z return
    rts
    // [1391] phi from frame_char::@7 to frame_char::@return [phi:frame_char::@7->frame_char::@return]
  __b8:
    // [1391] phi frame_char::return#12 = $73 [phi:frame_char::@7->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z return
    rts
    // [1391] phi from frame_char::@8 to frame_char::@return [phi:frame_char::@8->frame_char::@return]
  __b9:
    // [1391] phi frame_char::return#12 = $72 [phi:frame_char::@8->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z return
    rts
    // [1391] phi from frame_char::@9 to frame_char::@return [phi:frame_char::@9->frame_char::@return]
  __b10:
    // [1391] phi frame_char::return#12 = $71 [phi:frame_char::@9->frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z return
    // frame_char::@return
    // }
    // [1392] return 
    rts
}
  // cputs
// Output a NUL-terminated string at the current cursor position
// void cputs(__zp($40) const char *s)
cputs: {
    .label c = $ab
    .label s = $40
    // [1394] phi from cputs to cputs::@1 [phi:cputs->cputs::@1]
    // [1394] phi cputs::s#2 = frame_draw::s [phi:cputs->cputs::@1#0] -- pbuz1=pbuc1 
    lda #<frame_draw.s
    sta.z s
    lda #>frame_draw.s
    sta.z s+1
    // cputs::@1
  __b1:
    // while(c=*s++)
    // [1395] cputs::c#1 = *cputs::s#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta.z c
    // [1396] cputs::s#0 = ++ cputs::s#2 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [1397] if(0!=cputs::c#1) goto cputs::@2 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b2
    // cputs::@return
    // }
    // [1398] return 
    rts
    // cputs::@2
  __b2:
    // cputc(c)
    // [1399] stackpush(char) = cputs::c#1 -- _stackpushbyte_=vbuz1 
    lda.z c
    pha
    // [1400] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [1394] phi from cputs::@2 to cputs::@1 [phi:cputs::@2->cputs::@1]
    // [1394] phi cputs::s#2 = cputs::s#0 [phi:cputs::@2->cputs::@1#0] -- register_copy 
    jmp __b1
}
  // printf_padding
// Print a padding char a number of times
// void printf_padding(__zp($40) void (*putc)(char), __zp($46) char pad, __zp($43) char length)
printf_padding: {
    .label i = $42
    .label putc = $40
    .label length = $43
    .label pad = $46
    // [1403] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [1403] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [1404] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z length
    bcc __b2
    // printf_padding::@return
    // }
    // [1405] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [1406] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbuz1 
    lda.z pad
    pha
    // [1407] callexecute *printf_padding::putc#7  -- call__deref_pprz1 
    jsr icall14
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [1409] printf_padding::i#1 = ++ printf_padding::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1403] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [1403] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
    jmp __b1
    // Outside Flow
  icall14:
    jmp (putc)
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
// void rom_write_byte(__zp($b4) unsigned long address, __zp($c3) char value)
rom_write_byte: {
    .label rom_bank1_rom_write_byte__0 = $59
    .label rom_bank1_rom_write_byte__1 = $3f
    .label rom_bank1_rom_write_byte__2 = $79
    .label rom_ptr1_rom_write_byte__0 = $7e
    .label rom_ptr1_rom_write_byte__2 = $7e
    .label rom_bank1_bank_unshifted = $79
    .label rom_bank1_return = $43
    .label rom_ptr1_return = $7e
    .label address = $b4
    .label value = $c3
    // rom_write_byte::rom_bank1
    // BYTE2(address)
    // [1411] rom_write_byte::rom_bank1_$0 = byte2  rom_write_byte::address#3 -- vbuz1=_byte2_vduz2 
    lda.z address+2
    sta.z rom_bank1_rom_write_byte__0
    // BYTE1(address)
    // [1412] rom_write_byte::rom_bank1_$1 = byte1  rom_write_byte::address#3 -- vbuz1=_byte1_vduz2 
    lda.z address+1
    sta.z rom_bank1_rom_write_byte__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [1413] rom_write_byte::rom_bank1_$2 = rom_write_byte::rom_bank1_$0 w= rom_write_byte::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_write_byte__0
    sta.z rom_bank1_rom_write_byte__2+1
    lda.z rom_bank1_rom_write_byte__1
    sta.z rom_bank1_rom_write_byte__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [1414] rom_write_byte::rom_bank1_bank_unshifted#0 = rom_write_byte::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [1415] rom_write_byte::rom_bank1_return#0 = byte1  rom_write_byte::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwuz2 
    lda.z rom_bank1_bank_unshifted+1
    sta.z rom_bank1_return
    // rom_write_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [1416] rom_write_byte::rom_ptr1_$2 = (unsigned int)rom_write_byte::address#3 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_write_byte__2
    lda.z address+1
    sta.z rom_ptr1_rom_write_byte__2+1
    // [1417] rom_write_byte::rom_ptr1_$0 = rom_write_byte::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_write_byte__0
    and #<$3fff
    sta.z rom_ptr1_rom_write_byte__0
    lda.z rom_ptr1_rom_write_byte__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_write_byte__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [1418] rom_write_byte::rom_ptr1_return#0 = rom_write_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_write_byte::bank_set_brom1
    // BROM = bank
    // [1419] BROM = rom_write_byte::rom_bank1_return#0 -- vbuz1=vbuz2 
    lda.z rom_bank1_return
    sta.z BROM
    // rom_write_byte::@1
    // *ptr_rom = value
    // [1420] *((char *)rom_write_byte::rom_ptr1_return#0) = rom_write_byte::value#10 -- _deref_pbuz1=vbuz2 
    lda.z value
    ldy #0
    sta (rom_ptr1_return),y
    // rom_write_byte::@return
    // }
    // [1421] return 
    rts
}
  // uctoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void uctoa(__zp($39) char value, __zp($44) char *buffer, __zp($b0) char radix)
uctoa: {
    .label uctoa__4 = $59
    .label digit_value = $3f
    .label buffer = $44
    .label digit = $56
    .label value = $39
    .label radix = $b0
    .label started = $5c
    .label max_digits = $76
    .label digit_values = $47
    // if(radix==DECIMAL)
    // [1422] if(uctoa::radix#0==DECIMAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp.z radix
    beq __b2
    // uctoa::@2
    // if(radix==HEXADECIMAL)
    // [1423] if(uctoa::radix#0==HEXADECIMAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp.z radix
    beq __b3
    // uctoa::@3
    // if(radix==OCTAL)
    // [1424] if(uctoa::radix#0==OCTAL) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp.z radix
    beq __b4
    // uctoa::@4
    // if(radix==BINARY)
    // [1425] if(uctoa::radix#0==BINARY) goto uctoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp.z radix
    beq __b5
    // uctoa::@5
    // *buffer++ = 'e'
    // [1426] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1427] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1428] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1429] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // uctoa::@return
    // }
    // [1430] return 
    rts
    // [1431] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
  __b2:
    // [1431] phi uctoa::digit_values#8 = RADIX_DECIMAL_VALUES_CHAR [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1431] phi uctoa::max_digits#7 = 3 [phi:uctoa->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [1431] phi from uctoa::@2 to uctoa::@1 [phi:uctoa::@2->uctoa::@1]
  __b3:
    // [1431] phi uctoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_CHAR [phi:uctoa::@2->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [1431] phi uctoa::max_digits#7 = 2 [phi:uctoa::@2->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #2
    sta.z max_digits
    jmp __b1
    // [1431] phi from uctoa::@3 to uctoa::@1 [phi:uctoa::@3->uctoa::@1]
  __b4:
    // [1431] phi uctoa::digit_values#8 = RADIX_OCTAL_VALUES_CHAR [phi:uctoa::@3->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values+1
    // [1431] phi uctoa::max_digits#7 = 3 [phi:uctoa::@3->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #3
    sta.z max_digits
    jmp __b1
    // [1431] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
  __b5:
    // [1431] phi uctoa::digit_values#8 = RADIX_BINARY_VALUES_CHAR [phi:uctoa::@4->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_BINARY_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_CHAR
    sta.z digit_values+1
    // [1431] phi uctoa::max_digits#7 = 8 [phi:uctoa::@4->uctoa::@1#1] -- vbuz1=vbuc1 
    lda #8
    sta.z max_digits
    // uctoa::@1
  __b1:
    // [1432] phi from uctoa::@1 to uctoa::@6 [phi:uctoa::@1->uctoa::@6]
    // [1432] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa::@1->uctoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1432] phi uctoa::started#2 = 0 [phi:uctoa::@1->uctoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [1432] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa::@1->uctoa::@6#2] -- register_copy 
    // [1432] phi uctoa::digit#2 = 0 [phi:uctoa::@1->uctoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // uctoa::@6
  __b6:
    // max_digits-1
    // [1433] uctoa::$4 = uctoa::max_digits#7 - 1 -- vbuz1=vbuz2_minus_1 
    ldx.z max_digits
    dex
    stx.z uctoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1434] if(uctoa::digit#2<uctoa::$4) goto uctoa::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z digit
    cmp.z uctoa__4
    bcc __b7
    // uctoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1435] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z value
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1436] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1437] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // uctoa::@7
  __b7:
    // unsigned char digit_value = digit_values[digit]
    // [1438] uctoa::digit_value#0 = uctoa::digit_values#8[uctoa::digit#2] -- vbuz1=pbuz2_derefidx_vbuz3 
    ldy.z digit
    lda (digit_values),y
    sta.z digit_value
    // if (started || value >= digit_value)
    // [1439] if(0!=uctoa::started#2) goto uctoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // uctoa::@12
    // [1440] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@10 -- vbuz1_ge_vbuz2_then_la1 
    lda.z value
    cmp.z digit_value
    bcs __b10
    // [1441] phi from uctoa::@12 to uctoa::@9 [phi:uctoa::@12->uctoa::@9]
    // [1441] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@12->uctoa::@9#0] -- register_copy 
    // [1441] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@12->uctoa::@9#1] -- register_copy 
    // [1441] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@12->uctoa::@9#2] -- register_copy 
    // uctoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1442] uctoa::digit#1 = ++ uctoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1432] phi from uctoa::@9 to uctoa::@6 [phi:uctoa::@9->uctoa::@6]
    // [1432] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@9->uctoa::@6#0] -- register_copy 
    // [1432] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@9->uctoa::@6#1] -- register_copy 
    // [1432] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@9->uctoa::@6#2] -- register_copy 
    // [1432] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@9->uctoa::@6#3] -- register_copy 
    jmp __b6
    // uctoa::@10
  __b10:
    // uctoa_append(buffer++, value, digit_value)
    // [1443] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [1444] uctoa_append::value#0 = uctoa::value#2
    // [1445] uctoa_append::sub#0 = uctoa::digit_value#0
    // [1446] call uctoa_append
    // [1626] phi from uctoa::@10 to uctoa_append [phi:uctoa::@10->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [1447] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@11
    // value = uctoa_append(buffer++, value, digit_value)
    // [1448] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [1449] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1441] phi from uctoa::@11 to uctoa::@9 [phi:uctoa::@11->uctoa::@9]
    // [1441] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@11->uctoa::@9#0] -- register_copy 
    // [1441] phi uctoa::started#4 = 1 [phi:uctoa::@11->uctoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [1441] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@11->uctoa::@9#2] -- register_copy 
    jmp __b9
}
  // printf_number_buffer
// Print the contents of the number buffer using a specific format.
// This handles minimum length, zero-filling, and left/right justification from the format
// void printf_number_buffer(__zp($5d) void (*putc)(char), __zp($76) char buffer_sign, char *buffer_digits, __zp($aa) char format_min_length, char format_justify_left, char format_sign_always, __zp($6d) char format_zero_padding, char format_upper_case, char format_radix)
printf_number_buffer: {
    .label printf_number_buffer__19 = $34
    .label putc = $5d
    .label buffer_sign = $76
    .label format_min_length = $aa
    .label format_zero_padding = $6d
    .label len = $56
    .label padding = $56
    // if(format.min_length)
    // [1451] if(0==printf_number_buffer::format_min_length#2) goto printf_number_buffer::@1 -- 0_eq_vbuz1_then_la1 
    lda.z format_min_length
    beq __b5
    // [1452] phi from printf_number_buffer to printf_number_buffer::@5 [phi:printf_number_buffer->printf_number_buffer::@5]
    // printf_number_buffer::@5
    // strlen(buffer.digits)
    // [1453] call strlen
    // [1194] phi from printf_number_buffer::@5 to strlen [phi:printf_number_buffer::@5->strlen]
    // [1194] phi strlen::str#8 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [1454] strlen::return#3 = strlen::len#2
    // printf_number_buffer::@11
    // [1455] printf_number_buffer::$19 = strlen::return#3
    // signed char len = (signed char)strlen(buffer.digits)
    // [1456] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsz1=_sbyte_vwuz2 
    // There is a minimum length - work out the padding
    lda.z printf_number_buffer__19
    sta.z len
    // if(buffer.sign)
    // [1457] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@10 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b10
    // printf_number_buffer::@6
    // len++;
    // [1458] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsz1=_inc_vbsz1 
    inc.z len
    // [1459] phi from printf_number_buffer::@11 printf_number_buffer::@6 to printf_number_buffer::@10 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10]
    // [1459] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10#0] -- register_copy 
    // printf_number_buffer::@10
  __b10:
    // padding = (signed char)format.min_length - len
    // [1460] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#2 - printf_number_buffer::len#2 -- vbsz1=vbsz2_minus_vbsz1 
    lda.z format_min_length
    sec
    sbc.z padding
    sta.z padding
    // if(padding<0)
    // [1461] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@15 -- vbsz1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1463] phi from printf_number_buffer printf_number_buffer::@10 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1]
  __b5:
    // [1463] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1#0] -- vbsz1=vbsc1 
    lda #0
    sta.z padding
    // [1462] phi from printf_number_buffer::@10 to printf_number_buffer::@15 [phi:printf_number_buffer::@10->printf_number_buffer::@15]
    // printf_number_buffer::@15
    // [1463] phi from printf_number_buffer::@15 to printf_number_buffer::@1 [phi:printf_number_buffer::@15->printf_number_buffer::@1]
    // [1463] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@15->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // printf_number_buffer::@13
    // if(!format.justify_left && !format.zero_padding && padding)
    // [1464] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbuz1_then_la1 
    lda.z format_zero_padding
    bne __b2
    // printf_number_buffer::@12
    // [1465] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@7 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b7
    jmp __b2
    // printf_number_buffer::@7
  __b7:
    // printf_padding(putc, ' ',(char)padding)
    // [1466] printf_padding::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1467] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1468] call printf_padding
    // [1402] phi from printf_number_buffer::@7 to printf_padding [phi:printf_number_buffer::@7->printf_padding]
    // [1402] phi printf_padding::putc#7 = printf_padding::putc#0 [phi:printf_number_buffer::@7->printf_padding#0] -- register_copy 
    // [1402] phi printf_padding::pad#7 = ' ' [phi:printf_number_buffer::@7->printf_padding#1] -- vbuz1=vbuc1 
    lda #' '
    sta.z printf_padding.pad
    // [1402] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@7->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [1469] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbuz1_then_la1 
    lda.z buffer_sign
    beq __b3
    // printf_number_buffer::@8
    // putc(buffer.sign)
    // [1470] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbuz1 
    pha
    // [1471] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall15
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [1473] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbuz1_then_la1 
    lda.z format_zero_padding
    beq __b4
    // printf_number_buffer::@14
    // [1474] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@9 -- 0_neq_vbsz1_then_la1 
    lda.z padding
    cmp #0
    bne __b9
    jmp __b4
    // printf_number_buffer::@9
  __b9:
    // printf_padding(putc, '0',(char)padding)
    // [1475] printf_padding::putc#1 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1476] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbuz1=vbuz2 
    lda.z padding
    sta.z printf_padding.length
    // [1477] call printf_padding
    // [1402] phi from printf_number_buffer::@9 to printf_padding [phi:printf_number_buffer::@9->printf_padding]
    // [1402] phi printf_padding::putc#7 = printf_padding::putc#1 [phi:printf_number_buffer::@9->printf_padding#0] -- register_copy 
    // [1402] phi printf_padding::pad#7 = '0' [phi:printf_number_buffer::@9->printf_padding#1] -- vbuz1=vbuc1 
    lda #'0'
    sta.z printf_padding.pad
    // [1402] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@9->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // printf_str(putc, buffer.digits)
    // [1478] printf_str::putc#0 = printf_number_buffer::putc#10
    // [1479] call printf_str
    // [560] phi from printf_number_buffer::@4 to printf_str [phi:printf_number_buffer::@4->printf_str]
    // [560] phi printf_str::putc#28 = printf_str::putc#0 [phi:printf_number_buffer::@4->printf_str#0] -- register_copy 
    // [560] phi printf_str::s#28 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@return
    // }
    // [1480] return 
    rts
    // Outside Flow
  icall15:
    jmp (putc)
}
  // print_chip_led
// void print_chip_led(__zp($67) char x, char y, __zp($5c) char w, __zp($ab) char tc, char bc)
print_chip_led: {
    .label i = $51
    .label tc = $ab
    .label x = $67
    .label w = $5c
    // gotoxy(x, y)
    // [1482] gotoxy::x#8 = print_chip_led::x#3 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1483] call gotoxy
    // [189] phi from print_chip_led to gotoxy [phi:print_chip_led->gotoxy]
    // [189] phi gotoxy::y#18 = 3 [phi:print_chip_led->gotoxy#0] -- vbuz1=vbuc1 
    lda #3
    sta.z gotoxy.y
    // [189] phi gotoxy::x#18 = gotoxy::x#8 [phi:print_chip_led->gotoxy#1] -- register_copy 
    jsr gotoxy
    // print_chip_led::@4
    // textcolor(tc)
    // [1484] textcolor::color#10 = print_chip_led::tc#3 -- vbuz1=vbuz2 
    lda.z tc
    sta.z textcolor.color
    // [1485] call textcolor
    // [171] phi from print_chip_led::@4 to textcolor [phi:print_chip_led::@4->textcolor]
    // [171] phi textcolor::color#16 = textcolor::color#10 [phi:print_chip_led::@4->textcolor#0] -- register_copy 
    jsr textcolor
    // [1486] phi from print_chip_led::@4 to print_chip_led::@5 [phi:print_chip_led::@4->print_chip_led::@5]
    // print_chip_led::@5
    // bgcolor(bc)
    // [1487] call bgcolor
    // [176] phi from print_chip_led::@5 to bgcolor [phi:print_chip_led::@5->bgcolor]
    // [176] phi bgcolor::color#14 = BLUE [phi:print_chip_led::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // [1488] phi from print_chip_led::@5 to print_chip_led::@1 [phi:print_chip_led::@5->print_chip_led::@1]
    // [1488] phi print_chip_led::i#2 = 0 [phi:print_chip_led::@5->print_chip_led::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // print_chip_led::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [1489] if(print_chip_led::i#2<print_chip_led::w#5) goto print_chip_led::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [1490] phi from print_chip_led::@1 to print_chip_led::@3 [phi:print_chip_led::@1->print_chip_led::@3]
    // print_chip_led::@3
    // textcolor(WHITE)
    // [1491] call textcolor
    // [171] phi from print_chip_led::@3 to textcolor [phi:print_chip_led::@3->textcolor]
    // [171] phi textcolor::color#16 = WHITE [phi:print_chip_led::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [1492] phi from print_chip_led::@3 to print_chip_led::@6 [phi:print_chip_led::@3->print_chip_led::@6]
    // print_chip_led::@6
    // bgcolor(BLUE)
    // [1493] call bgcolor
    // [176] phi from print_chip_led::@6 to bgcolor [phi:print_chip_led::@6->bgcolor]
    // [176] phi bgcolor::color#14 = BLUE [phi:print_chip_led::@6->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_led::@return
    // }
    // [1494] return 
    rts
    // print_chip_led::@2
  __b2:
    // cputc(0xE2)
    // [1495] stackpush(char) = $e2 -- _stackpushbyte_=vbuc1 
    lda #$e2
    pha
    // [1496] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [1498] print_chip_led::i#1 = ++ print_chip_led::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1488] phi from print_chip_led::@2 to print_chip_led::@1 [phi:print_chip_led::@2->print_chip_led::@1]
    // [1488] phi print_chip_led::i#2 = print_chip_led::i#1 [phi:print_chip_led::@2->print_chip_led::@1#0] -- register_copy 
    jmp __b1
}
  // print_chip_line
// void print_chip_line(__zp($5f) char x, __zp($66) char y, __zp($49) char w, __zp($4b) char c)
print_chip_line: {
    .label i = $3b
    .label x = $5f
    .label w = $49
    .label c = $4b
    .label y = $66
    // gotoxy(x, y)
    // [1500] gotoxy::x#6 = print_chip_line::x#16 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1501] gotoxy::y#6 = print_chip_line::y#16 -- vbuz1=vbuz2 
    lda.z y
    sta.z gotoxy.y
    // [1502] call gotoxy
    // [189] phi from print_chip_line to gotoxy [phi:print_chip_line->gotoxy]
    // [189] phi gotoxy::y#18 = gotoxy::y#6 [phi:print_chip_line->gotoxy#0] -- register_copy 
    // [189] phi gotoxy::x#18 = gotoxy::x#6 [phi:print_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1503] phi from print_chip_line to print_chip_line::@4 [phi:print_chip_line->print_chip_line::@4]
    // print_chip_line::@4
    // textcolor(GREY)
    // [1504] call textcolor
    // [171] phi from print_chip_line::@4 to textcolor [phi:print_chip_line::@4->textcolor]
    // [171] phi textcolor::color#16 = GREY [phi:print_chip_line::@4->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [1505] phi from print_chip_line::@4 to print_chip_line::@5 [phi:print_chip_line::@4->print_chip_line::@5]
    // print_chip_line::@5
    // bgcolor(BLUE)
    // [1506] call bgcolor
    // [176] phi from print_chip_line::@5 to bgcolor [phi:print_chip_line::@5->bgcolor]
    // [176] phi bgcolor::color#14 = BLUE [phi:print_chip_line::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@6
    // cputc(VERA_CHR_UR)
    // [1507] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [1508] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [1510] call textcolor
    // [171] phi from print_chip_line::@6 to textcolor [phi:print_chip_line::@6->textcolor]
    // [171] phi textcolor::color#16 = WHITE [phi:print_chip_line::@6->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [1511] phi from print_chip_line::@6 to print_chip_line::@7 [phi:print_chip_line::@6->print_chip_line::@7]
    // print_chip_line::@7
    // bgcolor(BLACK)
    // [1512] call bgcolor
    // [176] phi from print_chip_line::@7 to bgcolor [phi:print_chip_line::@7->bgcolor]
    // [176] phi bgcolor::color#14 = BLACK [phi:print_chip_line::@7->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // [1513] phi from print_chip_line::@7 to print_chip_line::@1 [phi:print_chip_line::@7->print_chip_line::@1]
    // [1513] phi print_chip_line::i#2 = 0 [phi:print_chip_line::@7->print_chip_line::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // print_chip_line::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [1514] if(print_chip_line::i#2<print_chip_line::w#10) goto print_chip_line::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [1515] phi from print_chip_line::@1 to print_chip_line::@3 [phi:print_chip_line::@1->print_chip_line::@3]
    // print_chip_line::@3
    // textcolor(GREY)
    // [1516] call textcolor
    // [171] phi from print_chip_line::@3 to textcolor [phi:print_chip_line::@3->textcolor]
    // [171] phi textcolor::color#16 = GREY [phi:print_chip_line::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [1517] phi from print_chip_line::@3 to print_chip_line::@8 [phi:print_chip_line::@3->print_chip_line::@8]
    // print_chip_line::@8
    // bgcolor(BLUE)
    // [1518] call bgcolor
    // [176] phi from print_chip_line::@8 to bgcolor [phi:print_chip_line::@8->bgcolor]
    // [176] phi bgcolor::color#14 = BLUE [phi:print_chip_line::@8->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@9
    // cputc(VERA_CHR_UL)
    // [1519] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [1520] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [1522] call textcolor
    // [171] phi from print_chip_line::@9 to textcolor [phi:print_chip_line::@9->textcolor]
    // [171] phi textcolor::color#16 = WHITE [phi:print_chip_line::@9->textcolor#0] -- vbuz1=vbuc1 
    lda #WHITE
    sta.z textcolor.color
    jsr textcolor
    // [1523] phi from print_chip_line::@9 to print_chip_line::@10 [phi:print_chip_line::@9->print_chip_line::@10]
    // print_chip_line::@10
    // bgcolor(BLACK)
    // [1524] call bgcolor
    // [176] phi from print_chip_line::@10 to bgcolor [phi:print_chip_line::@10->bgcolor]
    // [176] phi bgcolor::color#14 = BLACK [phi:print_chip_line::@10->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_line::@11
    // cputcxy(x+2, y, c)
    // [1525] cputcxy::x#8 = print_chip_line::x#16 + 2 -- vbuz1=vbuz1_plus_2 
    lda.z cputcxy.x
    clc
    adc #2
    sta.z cputcxy.x
    // [1526] cputcxy::y#8 = print_chip_line::y#16
    // [1527] cputcxy::c#8 = print_chip_line::c#15 -- vbuz1=vbuz2 
    lda.z c
    sta.z cputcxy.c
    // [1528] call cputcxy
    // [1044] phi from print_chip_line::@11 to cputcxy [phi:print_chip_line::@11->cputcxy]
    // [1044] phi cputcxy::c#11 = cputcxy::c#8 [phi:print_chip_line::@11->cputcxy#0] -- register_copy 
    // [1044] phi cputcxy::y#11 = cputcxy::y#8 [phi:print_chip_line::@11->cputcxy#1] -- register_copy 
    // [1044] phi cputcxy::x#11 = cputcxy::x#8 [phi:print_chip_line::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // print_chip_line::@return
    // }
    // [1529] return 
    rts
    // print_chip_line::@2
  __b2:
    // cputc(VERA_CHR_SPACE)
    // [1530] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [1531] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [1533] print_chip_line::i#1 = ++ print_chip_line::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1513] phi from print_chip_line::@2 to print_chip_line::@1 [phi:print_chip_line::@2->print_chip_line::@1]
    // [1513] phi print_chip_line::i#2 = print_chip_line::i#1 [phi:print_chip_line::@2->print_chip_line::@1#0] -- register_copy 
    jmp __b1
}
  // print_chip_end
// void print_chip_end(__zp($42) char x, char y, __zp($7d) char w)
print_chip_end: {
    .label i = $2f
    .label x = $42
    .label w = $7d
    // gotoxy(x, y)
    // [1534] gotoxy::x#7 = print_chip_end::x#0 -- vbuz1=vbuz2 
    lda.z x
    sta.z gotoxy.x
    // [1535] call gotoxy
    // [189] phi from print_chip_end to gotoxy [phi:print_chip_end->gotoxy]
    // [189] phi gotoxy::y#18 = print_chip::y#21 [phi:print_chip_end->gotoxy#0] -- vbuz1=vbuc1 
    lda #print_chip.y
    sta.z gotoxy.y
    // [189] phi gotoxy::x#18 = gotoxy::x#7 [phi:print_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1536] phi from print_chip_end to print_chip_end::@4 [phi:print_chip_end->print_chip_end::@4]
    // print_chip_end::@4
    // textcolor(GREY)
    // [1537] call textcolor
    // [171] phi from print_chip_end::@4 to textcolor [phi:print_chip_end::@4->textcolor]
    // [171] phi textcolor::color#16 = GREY [phi:print_chip_end::@4->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [1538] phi from print_chip_end::@4 to print_chip_end::@5 [phi:print_chip_end::@4->print_chip_end::@5]
    // print_chip_end::@5
    // bgcolor(BLUE)
    // [1539] call bgcolor
    // [176] phi from print_chip_end::@5 to bgcolor [phi:print_chip_end::@5->bgcolor]
    // [176] phi bgcolor::color#14 = BLUE [phi:print_chip_end::@5->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_end::@6
    // cputc(VERA_CHR_UR)
    // [1540] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [1541] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [1543] call textcolor
    // [171] phi from print_chip_end::@6 to textcolor [phi:print_chip_end::@6->textcolor]
    // [171] phi textcolor::color#16 = BLUE [phi:print_chip_end::@6->textcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z textcolor.color
    jsr textcolor
    // [1544] phi from print_chip_end::@6 to print_chip_end::@7 [phi:print_chip_end::@6->print_chip_end::@7]
    // print_chip_end::@7
    // bgcolor(BLACK)
    // [1545] call bgcolor
    // [176] phi from print_chip_end::@7 to bgcolor [phi:print_chip_end::@7->bgcolor]
    // [176] phi bgcolor::color#14 = BLACK [phi:print_chip_end::@7->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z bgcolor.color
    jsr bgcolor
    // [1546] phi from print_chip_end::@7 to print_chip_end::@1 [phi:print_chip_end::@7->print_chip_end::@1]
    // [1546] phi print_chip_end::i#2 = 0 [phi:print_chip_end::@7->print_chip_end::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // print_chip_end::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [1547] if(print_chip_end::i#2<print_chip_end::w#0) goto print_chip_end::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [1548] phi from print_chip_end::@1 to print_chip_end::@3 [phi:print_chip_end::@1->print_chip_end::@3]
    // print_chip_end::@3
    // textcolor(GREY)
    // [1549] call textcolor
    // [171] phi from print_chip_end::@3 to textcolor [phi:print_chip_end::@3->textcolor]
    // [171] phi textcolor::color#16 = GREY [phi:print_chip_end::@3->textcolor#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z textcolor.color
    jsr textcolor
    // [1550] phi from print_chip_end::@3 to print_chip_end::@8 [phi:print_chip_end::@3->print_chip_end::@8]
    // print_chip_end::@8
    // bgcolor(BLUE)
    // [1551] call bgcolor
    // [176] phi from print_chip_end::@8 to bgcolor [phi:print_chip_end::@8->bgcolor]
    // [176] phi bgcolor::color#14 = BLUE [phi:print_chip_end::@8->bgcolor#0] -- vbuz1=vbuc1 
    lda #BLUE
    sta.z bgcolor.color
    jsr bgcolor
    // print_chip_end::@9
    // cputc(VERA_CHR_UL)
    // [1552] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [1553] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // print_chip_end::@return
    // }
    // [1555] return 
    rts
    // print_chip_end::@2
  __b2:
    // cputc(VERA_CHR_HL)
    // [1556] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [1557] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [1559] print_chip_end::i#1 = ++ print_chip_end::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1546] phi from print_chip_end::@2 to print_chip_end::@1 [phi:print_chip_end::@2->print_chip_end::@1]
    // [1546] phi print_chip_end::i#2 = print_chip_end::i#1 [phi:print_chip_end::@2->print_chip_end::@1#0] -- register_copy 
    jmp __b1
}
  // utoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void utoa(__zp($2c) unsigned int value, __zp($44) char *buffer, __zp($6b) char radix)
utoa: {
    .label utoa__4 = $43
    .label utoa__10 = $46
    .label utoa__11 = $42
    .label digit_value = $34
    .label buffer = $44
    .label digit = $49
    .label value = $2c
    .label radix = $6b
    .label started = $4b
    .label max_digits = $51
    .label digit_values = $47
    // if(radix==DECIMAL)
    // [1560] if(utoa::radix#0==DECIMAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp.z radix
    beq __b2
    // utoa::@2
    // if(radix==HEXADECIMAL)
    // [1561] if(utoa::radix#0==HEXADECIMAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp.z radix
    beq __b3
    // utoa::@3
    // if(radix==OCTAL)
    // [1562] if(utoa::radix#0==OCTAL) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp.z radix
    beq __b4
    // utoa::@4
    // if(radix==BINARY)
    // [1563] if(utoa::radix#0==BINARY) goto utoa::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp.z radix
    beq __b5
    // utoa::@5
    // *buffer++ = 'e'
    // [1564] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [1565] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [1566] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [1567] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // utoa::@return
    // }
    // [1568] return 
    rts
    // [1569] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
  __b2:
    // [1569] phi utoa::digit_values#8 = RADIX_DECIMAL_VALUES [phi:utoa->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_DECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES
    sta.z digit_values+1
    // [1569] phi utoa::max_digits#7 = 5 [phi:utoa->utoa::@1#1] -- vbuz1=vbuc1 
    lda #5
    sta.z max_digits
    jmp __b1
    // [1569] phi from utoa::@2 to utoa::@1 [phi:utoa::@2->utoa::@1]
  __b3:
    // [1569] phi utoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES [phi:utoa::@2->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_HEXADECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES
    sta.z digit_values+1
    // [1569] phi utoa::max_digits#7 = 4 [phi:utoa::@2->utoa::@1#1] -- vbuz1=vbuc1 
    lda #4
    sta.z max_digits
    jmp __b1
    // [1569] phi from utoa::@3 to utoa::@1 [phi:utoa::@3->utoa::@1]
  __b4:
    // [1569] phi utoa::digit_values#8 = RADIX_OCTAL_VALUES [phi:utoa::@3->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_OCTAL_VALUES
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES
    sta.z digit_values+1
    // [1569] phi utoa::max_digits#7 = 6 [phi:utoa::@3->utoa::@1#1] -- vbuz1=vbuc1 
    lda #6
    sta.z max_digits
    jmp __b1
    // [1569] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
  __b5:
    // [1569] phi utoa::digit_values#8 = RADIX_BINARY_VALUES [phi:utoa::@4->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_BINARY_VALUES
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES
    sta.z digit_values+1
    // [1569] phi utoa::max_digits#7 = $10 [phi:utoa::@4->utoa::@1#1] -- vbuz1=vbuc1 
    lda #$10
    sta.z max_digits
    // utoa::@1
  __b1:
    // [1570] phi from utoa::@1 to utoa::@6 [phi:utoa::@1->utoa::@6]
    // [1570] phi utoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa::@1->utoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [1570] phi utoa::started#2 = 0 [phi:utoa::@1->utoa::@6#1] -- vbuz1=vbuc1 
    lda #0
    sta.z started
    // [1570] phi utoa::value#2 = utoa::value#1 [phi:utoa::@1->utoa::@6#2] -- register_copy 
    // [1570] phi utoa::digit#2 = 0 [phi:utoa::@1->utoa::@6#3] -- vbuz1=vbuc1 
    sta.z digit
    // utoa::@6
  __b6:
    // max_digits-1
    // [1571] utoa::$4 = utoa::max_digits#7 - 1 -- vbuz1=vbuz2_minus_1 
    ldx.z max_digits
    dex
    stx.z utoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1572] if(utoa::digit#2<utoa::$4) goto utoa::@7 -- vbuz1_lt_vbuz2_then_la1 
    lda.z digit
    cmp.z utoa__4
    bcc __b7
    // utoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [1573] utoa::$11 = (char)utoa::value#2 -- vbuz1=_byte_vwuz2 
    lda.z value
    sta.z utoa__11
    // [1574] *utoa::buffer#11 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [1575] utoa::buffer#3 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [1576] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // utoa::@7
  __b7:
    // unsigned int digit_value = digit_values[digit]
    // [1577] utoa::$10 = utoa::digit#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z digit
    asl
    sta.z utoa__10
    // [1578] utoa::digit_value#0 = utoa::digit_values#8[utoa::$10] -- vwuz1=pwuz2_derefidx_vbuz3 
    tay
    lda (digit_values),y
    sta.z digit_value
    iny
    lda (digit_values),y
    sta.z digit_value+1
    // if (started || value >= digit_value)
    // [1579] if(0!=utoa::started#2) goto utoa::@10 -- 0_neq_vbuz1_then_la1 
    lda.z started
    bne __b10
    // utoa::@12
    // [1580] if(utoa::value#2>=utoa::digit_value#0) goto utoa::@10 -- vwuz1_ge_vwuz2_then_la1 
    lda.z digit_value+1
    cmp.z value+1
    bne !+
    lda.z digit_value
    cmp.z value
    beq __b10
  !:
    bcc __b10
    // [1581] phi from utoa::@12 to utoa::@9 [phi:utoa::@12->utoa::@9]
    // [1581] phi utoa::buffer#14 = utoa::buffer#11 [phi:utoa::@12->utoa::@9#0] -- register_copy 
    // [1581] phi utoa::started#4 = utoa::started#2 [phi:utoa::@12->utoa::@9#1] -- register_copy 
    // [1581] phi utoa::value#6 = utoa::value#2 [phi:utoa::@12->utoa::@9#2] -- register_copy 
    // utoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [1582] utoa::digit#1 = ++ utoa::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // [1570] phi from utoa::@9 to utoa::@6 [phi:utoa::@9->utoa::@6]
    // [1570] phi utoa::buffer#11 = utoa::buffer#14 [phi:utoa::@9->utoa::@6#0] -- register_copy 
    // [1570] phi utoa::started#2 = utoa::started#4 [phi:utoa::@9->utoa::@6#1] -- register_copy 
    // [1570] phi utoa::value#2 = utoa::value#6 [phi:utoa::@9->utoa::@6#2] -- register_copy 
    // [1570] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@9->utoa::@6#3] -- register_copy 
    jmp __b6
    // utoa::@10
  __b10:
    // utoa_append(buffer++, value, digit_value)
    // [1583] utoa_append::buffer#0 = utoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [1584] utoa_append::value#0 = utoa::value#2
    // [1585] utoa_append::sub#0 = utoa::digit_value#0
    // [1586] call utoa_append
    // [1633] phi from utoa::@10 to utoa_append [phi:utoa::@10->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [1587] utoa_append::return#0 = utoa_append::value#2
    // utoa::@11
    // value = utoa_append(buffer++, value, digit_value)
    // [1588] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [1589] utoa::buffer#4 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [1581] phi from utoa::@11 to utoa::@9 [phi:utoa::@11->utoa::@9]
    // [1581] phi utoa::buffer#14 = utoa::buffer#4 [phi:utoa::@11->utoa::@9#0] -- register_copy 
    // [1581] phi utoa::started#4 = 1 [phi:utoa::@11->utoa::@9#1] -- vbuz1=vbuc1 
    lda #1
    sta.z started
    // [1581] phi utoa::value#6 = utoa::value#0 [phi:utoa::@11->utoa::@9#2] -- register_copy 
    jmp __b9
}
  // strncpy
/// Copies up to n characters from the string pointed to, by src to dst.
/// In a case where the length of src is less than that of n, the remainder of dst will be padded with null bytes.
/// @param dst ? This is the pointer to the destination array where the content is to be copied.
/// @param src ? This is the string to be copied.
/// @param n ? The number of characters to be copied from source.
/// @return The destination
// char * strncpy(__zp($60) char *dst, __zp($4c) const char *src, __zp($74) unsigned int n)
strncpy: {
    .label c = $42
    .label dst = $60
    .label i = $57
    .label src = $4c
    .label n = $74
    // [1591] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [1591] phi strncpy::dst#2 = ferror::temp [phi:strncpy->strncpy::@1#0] -- pbuz1=pbuc1 
    lda #<ferror.temp
    sta.z dst
    lda #>ferror.temp
    sta.z dst+1
    // [1591] phi strncpy::src#2 = __errno_error [phi:strncpy->strncpy::@1#1] -- pbuz1=pbuc1 
    lda #<__errno_error
    sta.z src
    lda #>__errno_error
    sta.z src+1
    // [1591] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwuz1=vwuc1 
    lda #<0
    sta.z i
    sta.z i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [1592] if(strncpy::i#2<strncpy::n#0) goto strncpy::@2 -- vwuz1_lt_vwuz2_then_la1 
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
    // [1593] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [1594] strncpy::c#0 = *strncpy::src#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta.z c
    // if(c)
    // [1595] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbuz1_then_la1 
    beq __b3
    // strncpy::@4
    // src++;
    // [1596] strncpy::src#0 = ++ strncpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [1597] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [1597] phi strncpy::src#6 = strncpy::src#2 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [1598] *strncpy::dst#2 = strncpy::c#0 -- _deref_pbuz1=vbuz2 
    lda.z c
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [1599] strncpy::dst#0 = ++ strncpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [1600] strncpy::i#1 = ++ strncpy::i#2 -- vwuz1=_inc_vwuz1 
    inc.z i
    bne !+
    inc.z i+1
  !:
    // [1591] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [1591] phi strncpy::dst#2 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [1591] phi strncpy::src#2 = strncpy::src#6 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [1591] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
    jmp __b1
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
// __zp($54) unsigned int cx16_k_macptr(__zp($a9) volatile char bytes, __zp($77) void * volatile buffer)
cx16_k_macptr: {
    .label bytes = $a9
    .label buffer = $77
    .label bytes_read = $64
    .label return = $54
    // unsigned int bytes_read
    // [1601] cx16_k_macptr::bytes_read = 0 -- vwuz1=vwuc1 
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
    // [1603] cx16_k_macptr::return#0 = cx16_k_macptr::bytes_read -- vwuz1=vwuz2 
    lda.z bytes_read
    sta.z return
    lda.z bytes_read+1
    sta.z return+1
    // cx16_k_macptr::@return
    // }
    // [1604] cx16_k_macptr::return#1 = cx16_k_macptr::return#0
    // [1605] return 
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
// void memcpy8_vram_vram(__zp($25) char dbank_vram, __zp($30) unsigned int doffset_vram, __zp($24) char sbank_vram, __zp($2a) unsigned int soffset_vram, __zp($23) char num8)
memcpy8_vram_vram: {
    .label memcpy8_vram_vram__0 = $26
    .label memcpy8_vram_vram__1 = $27
    .label memcpy8_vram_vram__2 = $24
    .label memcpy8_vram_vram__3 = $28
    .label memcpy8_vram_vram__4 = $29
    .label memcpy8_vram_vram__5 = $25
    .label num8 = $23
    .label dbank_vram = $25
    .label doffset_vram = $30
    .label sbank_vram = $24
    .label soffset_vram = $2a
    .label num8_1 = $22
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1606] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [1607] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte0_vwuz2 
    lda.z soffset_vram
    sta.z memcpy8_vram_vram__0
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [1608] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [1609] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte1_vwuz2 
    lda.z soffset_vram+1
    sta.z memcpy8_vram_vram__1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [1610] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [1611] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuz1=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z memcpy8_vram_vram__2
    sta.z memcpy8_vram_vram__2
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [1612] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [1613] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [1614] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte0_vwuz2 
    lda.z doffset_vram
    sta.z memcpy8_vram_vram__3
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [1615] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [1616] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte1_vwuz2 
    lda.z doffset_vram+1
    sta.z memcpy8_vram_vram__4
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [1617] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [1618] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuz1=vbuz1_bor_vbuc1 
    lda #VERA_INC_1
    ora.z memcpy8_vram_vram__5
    sta.z memcpy8_vram_vram__5
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [1619] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // [1620] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [1620] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [1621] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbuz1=_dec_vbuz2 
    ldy.z num8_1
    dey
    sty.z num8
    // [1622] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbuz1_then_la1 
    lda.z num8_1
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [1623] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [1624] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [1625] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbuz1=vbuz2 
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
// __zp($39) char uctoa_append(__zp($62) char *buffer, __zp($39) char value, __zp($3f) char sub)
uctoa_append: {
    .label buffer = $62
    .label value = $39
    .label sub = $3f
    .label return = $39
    .label digit = $3b
    // [1627] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [1627] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [1627] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [1628] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbuz1_ge_vbuz2_then_la1 
    lda.z value
    cmp.z sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [1629] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [1630] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [1631] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [1632] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbuz1=vbuz1_minus_vbuz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    // [1627] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [1627] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [1627] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
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
// __zp($2c) unsigned int utoa_append(__zp($4c) char *buffer, __zp($2c) unsigned int value, __zp($34) unsigned int sub)
utoa_append: {
    .label buffer = $4c
    .label value = $2c
    .label sub = $34
    .label return = $2c
    .label digit = $2f
    // [1634] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [1634] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z digit
    // [1634] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [1635] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwuz1_ge_vwuz2_then_la1 
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
    // [1636] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    ldy.z digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // utoa_append::@return
    // }
    // [1637] return 
    rts
    // utoa_append::@2
  __b2:
    // digit++;
    // [1638] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbuz1=_inc_vbuz1 
    inc.z digit
    // value -= sub
    // [1639] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwuz1=vwuz1_minus_vwuz2 
    lda.z value
    sec
    sbc.z sub
    sta.z value
    lda.z value+1
    sbc.z sub+1
    sta.z value+1
    // [1634] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [1634] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [1634] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
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
  status_text: .word __3, __4, __5, __6, __7, __8
  status_color: .byte WHITE, BLACK, CYAN, YELLOW, GREEN, RED
  __3: .text "Detected"
  .byte 0
  __4: .text "None"
  .byte 0
  __5: .text "Checking"
  .byte 0
  __6: .text "Flashing"
  .byte 0
  __7: .text "Updated"
  .byte 0
  __8: .text "Error"
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
  smc_bootloader: .word 0
