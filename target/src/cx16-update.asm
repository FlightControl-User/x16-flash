  // File Comments
/**
 * @file cx16-w25q16.c
 * 
 * @author Wavicle from CX16 community (https://gist.github.com/jburks) -- Advice and outline of the ROM update logic & overall support and test assistance of this program.
 * @author MooingLemur from CX16 community (https://github.com/mooinglemur) -- Advice and outline of the main SPI and W25Q16 update logic, and supply of new VERA firmware.
 * @author Stefan Jakobsson from CX16 community (https://github.com/stefan-b-jakobsson) -- Advice and outline of the SMC update logic, SMC firmware and bootloader and creation of SMC firmware.
 * @author Sven Van de Velde from CX16 community (https://github.com/FlightControl-User) -- Creation of this program, under the strong expertise by the people above.
 * 
 * @brief COMMANDER X16 UPDATE TOOL MAIN LOGIC FLOW
 *
 * @version 3.0
 * @date 2023-10-15
 *
 * @copyright Copyright (c) 2023
 *
 */
  // Upstart
.cpu _65c02
  .file                               [name="cx16-update.prg", type="prg", segments="Program"]
.segmentdef Program                 [segments="Basic, Code, Data" + 
                                     ", CodeIntro" +
                                     ", CodeVera" +
                                     ", DataIntro" +
                                     ", DataVera"
                                     ]
.segmentdef Basic                   [start=$0801]
.segmentdef Code                    [start=$80d]
.segmentdef Data                    [startAfter="Code",max=$7800]
.segmentdef CodeIntro               [startAfter="Data"] 
.segmentdef CodeVera                [startAfter="CodeIntro"] 
.segmentdef DataIntro               [startAfter="CodeVera"] 
.segmentdef DataVera                [startAfter="DataIntro"] 



.segment Basic
:BasicUpstart(__start)
.segment Code
.segment Data


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
  .const PINK = $a
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
  .const CX16_SCREEN_MODE = $ff5f
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
  .const VERA_SPRITES_ENABLE = $40
  .const VERA_LAYER1_ENABLE = $20
  .const VERA_LAYER0_ENABLE = $10
  .const VERA_LAYER_WIDTH_MASK = $30
  .const VERA_LAYER_HEIGHT_MASK = $c0
  .const STATUS_NONE = 0
  .const STATUS_SKIP = 1
  .const STATUS_DETECTED = 2
  .const STATUS_CHECKING = 3
  .const STATUS_READING = 4
  .const STATUS_COMPARING = 5
  .const STATUS_FLASH = 6
  .const STATUS_FLASHING = 7
  .const STATUS_FLASHED = 8
  .const STATUS_ISSUE = 9
  .const STATUS_ERROR = $a
  .const STATUS_WAITING = $b
  .const ROM_PROGRESS_CELL = $200
  // A progress frame cell represents about 512 bytes for a ROM update.
  .const ROM_PROGRESS_ROW = $8000
  // A progress frame row represents about 32768 bytes for a ROM update.
  .const SMC_PROGRESS_CELL = 8
  // A progress frame cell represents about 8 bytes for a SMC update.
  .const SMC_PROGRESS_ROW = $200
  // A progress frame row represents about 512 bytes for a SMC update.
  .const VERA_PROGRESS_CELL = $80
  // A progress frame cell represents about 128 bytes for a VERA compare.
  .const VERA_PROGRESS_PAGE = $100
  // A progress frame cell represents about 256 bytes for a VERA flash.
  .const VERA_PROGRESS_ROW = $2000
  .const display_intro_briefing_count = $f
  .const display_intro_colors_count = $10
  .const display_jp1_spi_vera_count = $10
  .const display_no_valid_smc_bootloader_count = 9
  .const display_smc_rom_issue_count = 8
  .const display_smc_unsupported_rom_count = 7
  .const display_debriefing_smc_count = $e
  .const display_debriefing_count_rom = 6
  /**
 * @file cx16-smc.h
 * 
 * @author Wavicle from CX16 community (https://gist.github.com/jburks) -- Advice and outline of the ROM update logic & overall support and test assistance of this program.
 * @author MooingLemur from CX16 community (https://github.com/mooinglemur) -- Advice and outline of the main SPI and W25Q16 update logic, and supply of new VERA firmware.
 * @author Stefan Jakobsson from CX16 community (https://github.com/stefan-b-jakobsson) -- Advice and outline of the SMC update logic, SMC firmware and bootloader and creation of SMC firmware.
 * @author Sven Van de Velde from CX16 community (https://github.com/FlightControl-User) -- Creation of this program, under the strong expertise by the people above.
 * 
 * @brief COMMANDER X16 UPDATE TOOL SMC FIRMWARE UPDATE ROUTINES
 *
 * @version 2.0
 * @date 2023-09-21
 *
 * @copyright Copyright (c) 2023
 *
 */
  .const SMC_CHIP_SIZE = $2000
  .const vera_size = $20000
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
  /// $9F29	DC_VIDEO (DCSEL=0)
  /// Bit 7: Current Field     Read-only bit which reflects the active interlaced field in composite and RGB modes. (0: even, 1: odd)
  /// Bit 6: Sprites Enable	Enable output from the Sprites renderer
  /// Bit 5: Layer1 Enable	    Enable output from the Layer1 renderer
  /// Bit 4: Layer0 Enable	    Enable output from the Layer0 renderer
  /// Bit 2: Chroma Disable    Setting 'Chroma Disable' disables output of chroma in NTSC composite mode and will give a better picture on a monochrome display. (Setting this bit will also disable the chroma output on the S-video output.)
  /// Bit 0-1: Output Mode     0: Video disabled, 1: VGA output, 2: NTSC composite, 3: RGB interlaced, composite sync (via VGA connector)
  .label VERA_DC_VIDEO = $9f29
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
  .label vera_reg_SPIData = $9f3e
  .label vera_reg_SPICtrl = $9f3f
  .label BRAM = 0
  .label BROM = 1
  /// Current position in the buffer being filled ( initially *s passed to snprintf()
  /// Used to hold state while printing
  .label __snprintf_buffer = $c0
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
// void snputc(__register(X) char c)
snputc: {
    .const OFFSET_STACK_C = 0
    // [9] snputc::c#0 = stackidx(char,snputc::OFFSET_STACK_C) -- vbuxx=_stackidxbyte_vbuc1 
    tsx
    lda STACK_BASE+OFFSET_STACK_C,x
    tax
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
    // [15] phi snputc::c#2 = 0 [phi:snputc::@1->snputc::@2#0] -- vbuxx=vbuc1 
    ldx #0
    // [14] phi from snputc::@1 to snputc::@3 [phi:snputc::@1->snputc::@3]
    // snputc::@3
    // [15] phi from snputc::@3 to snputc::@2 [phi:snputc::@3->snputc::@2]
    // [15] phi snputc::c#2 = snputc::c#0 [phi:snputc::@3->snputc::@2#0] -- register_copy 
    // snputc::@2
  __b2:
    // *(__snprintf_buffer++) = c
    // [16] *__snprintf_buffer = snputc::c#2 -- _deref_pbuz1=vbuxx 
    // Append char
    txa
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
    // screenlayer1()
    // [19] call screenlayer1
    jsr screenlayer1
    // [20] phi from conio_x16_init to conio_x16_init::@1 [phi:conio_x16_init->conio_x16_init::@1]
    // conio_x16_init::@1
    // textcolor(CONIO_TEXTCOLOR_DEFAULT)
    // [21] call textcolor
    // [787] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [787] phi textcolor::color#23 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [22] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [23] call bgcolor
    // [792] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [792] phi bgcolor::color#15 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
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
    // [29] conio_x16_init::$4 = cbm_k_plot_get::return#2 -- vwum1=vwum2 
    lda cbm_k_plot_get.return
    sta conio_x16_init__4
    lda cbm_k_plot_get.return+1
    sta conio_x16_init__4+1
    // BYTE1(cbm_k_plot_get())
    // [30] conio_x16_init::$5 = byte1  conio_x16_init::$4 -- vbuaa=_byte1_vwum1 
    // __conio.cursor_x = BYTE1(cbm_k_plot_get())
    // [31] *((char *)&__conio) = conio_x16_init::$5 -- _deref_pbuc1=vbuaa 
    sta __conio
    // cbm_k_plot_get()
    // [32] call cbm_k_plot_get
    jsr cbm_k_plot_get
    // [33] cbm_k_plot_get::return#3 = cbm_k_plot_get::return#0
    // conio_x16_init::@6
    // [34] conio_x16_init::$6 = cbm_k_plot_get::return#3 -- vwum1=vwum2 
    lda cbm_k_plot_get.return
    sta conio_x16_init__6
    lda cbm_k_plot_get.return+1
    sta conio_x16_init__6+1
    // BYTE0(cbm_k_plot_get())
    // [35] conio_x16_init::$7 = byte0  conio_x16_init::$6 -- vbuaa=_byte0_vwum1 
    lda conio_x16_init__6
    // __conio.cursor_y = BYTE0(cbm_k_plot_get())
    // [36] *((char *)&__conio+1) = conio_x16_init::$7 -- _deref_pbuc1=vbuaa 
    sta __conio+1
    // gotoxy(__conio.cursor_x, __conio.cursor_y)
    // [37] gotoxy::x#2 = *((char *)&__conio) -- vbuyy=_deref_pbuc1 
    ldy __conio
    // [38] gotoxy::y#2 = *((char *)&__conio+1) -- vbum1=_deref_pbuc1 
    sta gotoxy.y
    // [39] call gotoxy
    // [805] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [805] phi gotoxy::y#37 = gotoxy::y#2 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [805] phi gotoxy::x#37 = gotoxy::x#2 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
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
    conio_x16_init__4: .word 0
    .label conio_x16_init__6 = conio_x16_init__4
}
.segment Code
  // cputc
// Output one character at the current cursor position
// Moves the cursor forward. Scrolls the entire screen if needed
// void cputc(__register(X) char c)
cputc: {
    .const OFFSET_STACK_C = 0
    // [43] cputc::c#0 = stackidx(char,cputc::OFFSET_STACK_C) -- vbuxx=_stackidxbyte_vbuc1 
    tsx
    lda STACK_BASE+OFFSET_STACK_C,x
    tax
    // if(c=='\n')
    // [44] if(cputc::c#0==' ') goto cputc::@1 -- vbuxx_eq_vbuc1_then_la1 
    cpx #'\n'
    beq __b1
    // cputc::@2
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [45] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [46] cputc::$1 = byte0  *((unsigned int *)&__conio+$13) -- vbuaa=_byte0__deref_pwuc1 
    lda __conio+$13
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [47] *VERA_ADDRX_L = cputc::$1 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [48] cputc::$2 = byte1  *((unsigned int *)&__conio+$13) -- vbuaa=_byte1__deref_pwuc1 
    lda __conio+$13+1
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [49] *VERA_ADDRX_M = cputc::$2 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [50] cputc::$3 = *((char *)&__conio+5) | VERA_INC_1 -- vbuaa=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [51] *VERA_ADDRX_H = cputc::$3 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_H
    // *VERA_DATA0 = c
    // [52] *VERA_DATA0 = cputc::c#0 -- _deref_pbuc1=vbuxx 
    stx VERA_DATA0
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
    rts
    // cputc::@5
  __b5:
    // if(__conio.cursor_x >= __conio.width)
    // [62] if(*((char *)&__conio)>=*((char *)&__conio+6)) goto cputc::@7 -- _deref_pbuc1_ge__deref_pbuc2_then_la1 
    lda __conio
    cmp __conio+6
    bcs __b7
    // cputc::@8
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
    // [66] phi from cputc::@5 to cputc::@7 [phi:cputc::@5->cputc::@7]
    // cputc::@7
  __b7:
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
    .const bank_set_brom1_bank = 0
    .const bank_set_brom2_bank = 4
    .const bank_set_brom4_bank = 4
    .const bank_set_brom5_bank = 0
    .const bank_set_brom6_bank = 0
    .const bank_set_brom7_bank = 4
    .const bank_set_brom8_bank = 0
    .const bank_set_brom9_bank = 0
    .const bank_set_brom10_bank = 4
    .label main__198 = $78
    .label rom_file_github_id = $7e
    .label rom_file_release_id = $bd
    .label check_status_cx16_rom4_check_status_rom1_return = $da
    .label check_status_smc8_return = $dd
    .label check_status_vera1_return = $f2
    .label check_status_vera2_return = $fa
    .label check_status_smc14_return = $f5
    .label check_status_smc15_return = $f3
    .label check_status_vera8_return = $b9
    // init()
    // [71] call init
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
    // [826] phi from main to init [phi:main->init]
    jsr init
    // [72] phi from main to main::@100 [phi:main->main::@100]
    // main::@100
    // main_intro()
    // [73] call main_intro
    // [862] phi from main::@100 to main_intro [phi:main::@100->main_intro]
    jsr main_intro
    // [74] phi from main::@100 to main::@101 [phi:main::@100->main::@101]
    // main::@101
    // smc_detect()
    // [75] call smc_detect
    jsr smc_detect
    // [76] smc_detect::return#2 = smc_detect::return#0
    // main::@102
    // smc_bootloader = smc_detect()
    // [77] smc_bootloader#0 = smc_detect::return#2 -- vwum1=vwuz2 
    lda.z smc_detect.return
    sta smc_bootloader
    lda.z smc_detect.return+1
    sta smc_bootloader+1
    // strcpy(smc_version_text, "0.0.0")
    // [78] call strcpy
    // [890] phi from main::@102 to strcpy [phi:main::@102->strcpy]
    // [890] phi strcpy::dst#0 = smc_version_text [phi:main::@102->strcpy#0] -- pbuz1=pbuc1 
    lda #<smc_version_text
    sta.z strcpy.dst
    lda #>smc_version_text
    sta.z strcpy.dst+1
    // [890] phi strcpy::src#0 = main::source [phi:main::@102->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // [79] phi from main::@102 to main::@103 [phi:main::@102->main::@103]
    // main::@103
    // display_chip_smc()
    // [80] call display_chip_smc
    // [898] phi from main::@103 to display_chip_smc [phi:main::@103->display_chip_smc]
    jsr display_chip_smc
    // main::@104
    // if(smc_bootloader == 0x0100)
    // [81] if(smc_bootloader#0==$100) goto main::@1 -- vwum1_eq_vwuc1_then_la1 
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
    // [82] if(smc_bootloader#0==$200) goto main::@19 -- vwum1_eq_vwuc1_then_la1 
    lda smc_bootloader
    cmp #<$200
    bne !+
    lda smc_bootloader+1
    cmp #>$200
    bne !__b19+
    jmp __b19
  !__b19:
  !:
    // main::@7
    // if(smc_bootloader > 0x2)
    // [83] if(smc_bootloader#0>=2+1) goto main::@20 -- vwum1_ge_vbuc1_then_la1 
    lda smc_bootloader+1
    beq !__b20+
    jmp __b20
  !__b20:
    lda smc_bootloader
    cmp #2+1
    bcc !__b20+
    jmp __b20
  !__b20:
  !:
    // main::@8
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_VERSION)
    // [84] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [85] cx16_k_i2c_read_byte::offset = $30 -- vbum1=vbuc1 
    lda #$30
    sta cx16_k_i2c_read_byte.offset
    // [86] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [87] cx16_k_i2c_read_byte::return#14 = cx16_k_i2c_read_byte::return#1
    // main::@111
    // smc_release = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_VERSION)
    // [88] smc_release#0 = cx16_k_i2c_read_byte::return#14 -- vbum1=vwum2 
    lda cx16_k_i2c_read_byte.return
    sta smc_release
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_MAJOR)
    // [89] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [90] cx16_k_i2c_read_byte::offset = $31 -- vbum1=vbuc1 
    lda #$31
    sta cx16_k_i2c_read_byte.offset
    // [91] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [92] cx16_k_i2c_read_byte::return#15 = cx16_k_i2c_read_byte::return#1
    // main::@112
    // smc_major = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_MAJOR)
    // [93] smc_major#0 = cx16_k_i2c_read_byte::return#15 -- vbum1=vwum2 
    lda cx16_k_i2c_read_byte.return
    sta smc_major
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_MINOR)
    // [94] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [95] cx16_k_i2c_read_byte::offset = $32 -- vbum1=vbuc1 
    lda #$32
    sta cx16_k_i2c_read_byte.offset
    // [96] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [97] cx16_k_i2c_read_byte::return#16 = cx16_k_i2c_read_byte::return#1
    // main::@113
    // smc_minor = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_MINOR)
    // [98] smc_minor#0 = cx16_k_i2c_read_byte::return#16 -- vbum1=vwum2 
    lda cx16_k_i2c_read_byte.return
    sta smc_minor
    // smc_get_version_text(smc_version_text, smc_release, smc_major, smc_minor)
    // [99] smc_get_version_text::release#0 = smc_release#0 -- vbuyy=vbum1 
    ldy smc_release
    // [100] smc_get_version_text::major#0 = smc_major#0 -- vbum1=vbum2 
    lda smc_major
    sta smc_get_version_text.major
    // [101] smc_get_version_text::minor#0 = smc_minor#0 -- vbuz1=vbum2 
    lda smc_minor
    sta.z smc_get_version_text.minor
    // [102] call smc_get_version_text
    // [908] phi from main::@113 to smc_get_version_text [phi:main::@113->smc_get_version_text]
    // [908] phi smc_get_version_text::minor#2 = smc_get_version_text::minor#0 [phi:main::@113->smc_get_version_text#0] -- register_copy 
    // [908] phi smc_get_version_text::major#2 = smc_get_version_text::major#0 [phi:main::@113->smc_get_version_text#1] -- register_copy 
    // [908] phi smc_get_version_text::release#2 = smc_get_version_text::release#0 [phi:main::@113->smc_get_version_text#2] -- register_copy 
    // [908] phi smc_get_version_text::version_string#2 = smc_version_text [phi:main::@113->smc_get_version_text#3] -- pbuz1=pbuc1 
    lda #<smc_version_text
    sta.z smc_get_version_text.version_string
    lda #>smc_version_text
    sta.z smc_get_version_text.version_string+1
    jsr smc_get_version_text
    // main::@114
    // [103] smc_bootloader#580 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_DETECTED, NULL)
    // [104] call display_info_smc
    // [925] phi from main::@114 to display_info_smc [phi:main::@114->display_info_smc]
    // [925] phi display_info_smc::info_text#24 = 0 [phi:main::@114->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [925] phi smc_bootloader#14 = smc_bootloader#580 [phi:main::@114->display_info_smc#1] -- register_copy 
    // [925] phi display_info_smc::info_status#24 = STATUS_DETECTED [phi:main::@114->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_DETECTED
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [105] phi from main::@114 to main::@2 [phi:main::@114->main::@2]
    // [105] phi smc_minor#418 = smc_minor#0 [phi:main::@114->main::@2#0] -- register_copy 
    // [105] phi smc_major#419 = smc_major#0 [phi:main::@114->main::@2#1] -- register_copy 
    // [105] phi smc_release#420 = smc_release#0 [phi:main::@114->main::@2#2] -- register_copy 
    // main::@2
  __b2:
    // main_vera_detect()
    // [106] call main_vera_detect
    // [961] phi from main::@2 to main_vera_detect [phi:main::@2->main_vera_detect]
    jsr main_vera_detect
    // main::SEI1
    // asm
    // asm { sei  }
    sei
    // main::bank_set_brom1
    // BROM = bank
    // [108] BROM = main::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [109] phi from main::bank_set_brom1 to main::@69 [phi:main::bank_set_brom1->main::@69]
    // main::@69
    // rom_detect()
    // [110] call rom_detect
  // Detecting ROM chips
    // [968] phi from main::@69 to rom_detect [phi:main::@69->rom_detect]
    jsr rom_detect
    // [111] phi from main::@69 to main::@115 [phi:main::@69->main::@115]
    // main::@115
    // display_chip_rom()
    // [112] call display_chip_rom
    // [1018] phi from main::@115 to display_chip_rom [phi:main::@115->display_chip_rom]
    jsr display_chip_rom
    // [113] phi from main::@115 to main::@21 [phi:main::@115->main::@21]
    // [113] phi main::rom_chip#10 = 0 [phi:main::@115->main::@21#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // main::@21
  __b21:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [114] if(main::rom_chip#10<8) goto main::@22 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcs !__b22+
    jmp __b22
  !__b22:
    // main::bank_set_brom2
    // BROM = bank
    // [115] BROM = main::bank_set_brom2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom2_bank
    sta.z BROM
    // main::CLI1
    // asm
    // asm { cli  }
    cli
    // main::check_status_smc1
    // status_smc == status
    // [117] main::check_status_smc1_$0 = status_smc#147 == STATUS_DETECTED -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_DETECTED
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [118] main::check_status_smc1_return#0 = (char)main::check_status_smc1_$0 -- vbuyy=vbuaa 
    tay
    // main::check_status_smc2
    // status_smc == status
    // [119] main::check_status_smc2_$0 = status_smc#147 == STATUS_ISSUE -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [120] main::check_status_smc2_return#0 = (char)main::check_status_smc2_$0 -- vbuxx=vbuaa 
    tax
    // main::@70
    // if(check_status_smc(STATUS_DETECTED) || check_status_smc(STATUS_ISSUE) )
    // [121] if(0!=main::check_status_smc1_return#0) goto main::@25 -- 0_neq_vbuyy_then_la1 
    cpy #0
    beq !__b25+
    jmp __b25
  !__b25:
    // main::@246
    // [122] if(0!=main::check_status_smc2_return#0) goto main::@25 -- 0_neq_vbuxx_then_la1 
    cpx #0
    beq !__b25+
    jmp __b25
  !__b25:
    // [123] phi from main::@246 to main::@3 [phi:main::@246->main::@3]
    // [123] phi smc_file_minor#310 = 0 [phi:main::@246->main::@3#0] -- vbum1=vbuc1 
    lda #0
    sta smc_file_minor
    // [123] phi smc_file_major#310 = 0 [phi:main::@246->main::@3#1] -- vbum1=vbuc1 
    sta smc_file_major
    // [123] phi smc_file_release#310 = 0 [phi:main::@246->main::@3#2] -- vbum1=vbuc1 
    sta smc_file_release
    // [123] phi __stdio_filecount#109 = 0 [phi:main::@246->main::@3#3] -- vbum1=vbuc1 
    sta __stdio_filecount
    // [123] phi __errno#113 = 0 [phi:main::@246->main::@3#4] -- vwsm1=vwsc1 
    sta __errno
    sta __errno+1
    // main::@3
  __b3:
    // main::bank_set_brom4
    // BROM = bank
    // [124] BROM = main::bank_set_brom4_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom4_bank
    sta.z BROM
    // main::CLI2
    // asm
    // asm { cli  }
    cli
    // [126] phi from main::CLI2 to main::@72 [phi:main::CLI2->main::@72]
    // main::@72
    // display_progress_clear()
    // [127] call display_progress_clear
    // [1037] phi from main::@72 to display_progress_clear [phi:main::@72->display_progress_clear]
    jsr display_progress_clear
    // [128] phi from main::@72 to main::@120 [phi:main::@72->main::@120]
    // main::@120
    // main_vera_check()
    // [129] call main_vera_check
    // [1052] phi from main::@120 to main_vera_check [phi:main::@120->main_vera_check]
    jsr main_vera_check
    // main::SEI2
    // asm
    // asm { sei  }
    sei
    // main::bank_set_brom5
    // BROM = bank
    // [131] BROM = main::bank_set_brom5_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom5_bank
    sta.z BROM
    // main::SEI3
    // asm
    // asm { sei  }
    sei
    // [133] phi from main::SEI3 to main::@30 [phi:main::SEI3->main::@30]
    // [133] phi __stdio_filecount#111 = __stdio_filecount#12 [phi:main::SEI3->main::@30#0] -- register_copy 
    // [133] phi __errno#115 = __errno#123 [phi:main::SEI3->main::@30#1] -- register_copy 
    // [133] phi main::rom_chip1#10 = 0 [phi:main::SEI3->main::@30#2] -- vbum1=vbuc1 
    lda #0
    sta rom_chip1
  // We loop all the possible ROM chip slots on the board and on the extension card,
  // and we check the file contents.
  // Any error identified gets reported and this chip will not be flashed.
  // In case of ROM0.BIN in error, no flashing will be done!
    // main::@30
  __b30:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [134] if(main::rom_chip1#10<8) goto main::bank_set_brom6 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip1
    cmp #8
    bcs !bank_set_brom6+
    jmp bank_set_brom6
  !bank_set_brom6:
    // main::check_status_smc3
    // status_smc == status
    // [135] main::check_status_smc3_$0 = status_smc#147 == STATUS_FLASH -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [136] main::check_status_smc3_return#0 = (char)main::check_status_smc3_$0 -- vbuyy=vbuaa 
    tay
    // [137] phi from main::check_status_smc3 to main::check_status_cx16_rom1 [phi:main::check_status_smc3->main::check_status_cx16_rom1]
    // main::check_status_cx16_rom1
    // main::check_status_cx16_rom1_check_status_rom1
    // status_rom[rom_chip] == status
    // [138] main::check_status_cx16_rom1_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboaa=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [139] main::check_status_cx16_rom1_check_status_rom1_return#0 = (char)main::check_status_cx16_rom1_check_status_rom1_$0 -- vbuxx=vbuaa 
    tax
    // main::@74
    // if(!check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH))
    // [140] if(0!=main::check_status_smc3_return#0) goto main::check_status_smc4 -- 0_neq_vbuyy_then_la1 
    cpy #0
    bne check_status_smc4
    // main::@247
    // [141] if(0!=main::check_status_cx16_rom1_check_status_rom1_return#0) goto main::@37 -- 0_neq_vbuxx_then_la1 
    cpx #0
    beq !__b37+
    jmp __b37
  !__b37:
    // main::check_status_smc4
  check_status_smc4:
    // status_smc == status
    // [142] main::check_status_smc4_$0 = status_smc#147 == STATUS_FLASH -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [143] main::check_status_smc4_return#0 = (char)main::check_status_smc4_$0 -- vbuyy=vbuaa 
    tay
    // [144] phi from main::check_status_smc4 to main::check_status_cx16_rom2 [phi:main::check_status_smc4->main::check_status_cx16_rom2]
    // main::check_status_cx16_rom2
    // main::check_status_cx16_rom2_check_status_rom1
    // status_rom[rom_chip] == status
    // [145] main::check_status_cx16_rom2_check_status_rom1_$0 = *status_rom == STATUS_NONE -- vboaa=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_NONE
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [146] main::check_status_cx16_rom2_check_status_rom1_return#0 = (char)main::check_status_cx16_rom2_check_status_rom1_$0 -- vbuxx=vbuaa 
    tax
    // main::@75
    // if(check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_NONE))
    // [147] if(0==main::check_status_smc4_return#0) goto main::check_status_smc5 -- 0_eq_vbuyy_then_la1 
    // VA3 | SMC.BIN and CX16 ROM not Detected
    cpy #0
    beq check_status_smc5
    // main::@248
    // [148] if(0!=main::check_status_cx16_rom2_check_status_rom1_return#0) goto main::@4 -- 0_neq_vbuxx_then_la1 
    cpx #0
    beq !__b4+
    jmp __b4
  !__b4:
    // main::check_status_smc5
  check_status_smc5:
    // status_smc == status
    // [149] main::check_status_smc5_$0 = status_smc#147 == STATUS_FLASH -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [150] main::check_status_smc5_return#0 = (char)main::check_status_smc5_$0 -- vbuyy=vbuaa 
    tay
    // [151] phi from main::check_status_smc5 to main::check_status_cx16_rom3 [phi:main::check_status_smc5->main::check_status_cx16_rom3]
    // main::check_status_cx16_rom3
    // main::check_status_cx16_rom3_check_status_rom1
    // status_rom[rom_chip] == status
    // [152] main::check_status_cx16_rom3_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboaa=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [153] main::check_status_cx16_rom3_check_status_rom1_return#0 = (char)main::check_status_cx16_rom3_check_status_rom1_$0 -- vbuxx=vbuaa 
    tax
    // main::@76
    // if(check_status_smc(STATUS_FLASH) && !check_status_cx16_rom(STATUS_FLASH))
    // [154] if(0==main::check_status_smc5_return#0) goto main::check_status_smc6 -- 0_eq_vbuyy_then_la1 
    cpy #0
    beq check_status_smc6
    // main::@249
    // [155] if(0==main::check_status_cx16_rom3_check_status_rom1_return#0) goto main::@9 -- 0_eq_vbuxx_then_la1 
    cpx #0
    bne !__b9+
    jmp __b9
  !__b9:
    // main::check_status_smc6
  check_status_smc6:
    // status_smc == status
    // [156] main::check_status_smc6_$0 = status_smc#147 == STATUS_FLASH -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [157] main::check_status_smc6_return#0 = (char)main::check_status_smc6_$0 -- vbum1=vbuaa 
    sta check_status_smc6_return
    // [158] phi from main::check_status_smc6 to main::check_status_cx16_rom4 [phi:main::check_status_smc6->main::check_status_cx16_rom4]
    // main::check_status_cx16_rom4
    // main::check_status_cx16_rom4_check_status_rom1
    // status_rom[rom_chip] == status
    // [159] main::check_status_cx16_rom4_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboaa=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [160] main::check_status_cx16_rom4_check_status_rom1_return#0 = (char)main::check_status_cx16_rom4_check_status_rom1_$0 -- vbuz1=vbuaa 
    sta.z check_status_cx16_rom4_check_status_rom1_return
    // main::@77
    // smc_supported_rom(rom_file_release[0])
    // [161] smc_supported_rom::rom_release#0 = *rom_file_release -- vbuaa=_deref_pbuc1 
    lda rom_file_release
    // [162] call smc_supported_rom
    // [1074] phi from main::@77 to smc_supported_rom [phi:main::@77->smc_supported_rom]
    jsr smc_supported_rom
    // smc_supported_rom(rom_file_release[0])
    // [163] smc_supported_rom::return#3 = smc_supported_rom::return#2
    // main::@166
    // [164] main::$35 = smc_supported_rom::return#3 -- vbuxx=vbuaa 
    tax
    // if(check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH) && !smc_supported_rom(rom_file_release[0]))
    // [165] if(0==main::check_status_smc6_return#0) goto main::check_status_smc7 -- 0_eq_vbum1_then_la1 
    lda check_status_smc6_return
    beq check_status_smc7
    // main::@251
    // [166] if(0==main::check_status_cx16_rom4_check_status_rom1_return#0) goto main::check_status_smc7 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_cx16_rom4_check_status_rom1_return
    beq check_status_smc7
    // main::@250
    // [167] if(0==main::$35) goto main::@12 -- 0_eq_vbuxx_then_la1 
    cpx #0
    bne !__b12+
    jmp __b12
  !__b12:
    // main::check_status_smc7
  check_status_smc7:
    // status_smc == status
    // [168] main::check_status_smc7_$0 = status_smc#147 == STATUS_FLASH -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [169] main::check_status_smc7_return#0 = (char)main::check_status_smc7_$0
    // main::@78
    // if(check_status_smc(STATUS_FLASH) && smc_release == smc_file_release && smc_major == smc_file_major && smc_minor == smc_file_minor)
    // [170] if(0==main::check_status_smc7_return#0) goto main::check_status_cx16_rom5 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq check_status_cx16_rom5
    // main::@254
    // [171] if(smc_release#420==smc_file_release#310) goto main::@253 -- vbum1_eq_vbum2_then_la1 
    lda smc_release
    cmp smc_file_release
    bne !__b253+
    jmp __b253
  !__b253:
    // [172] phi from main::@174 main::@252 main::@253 main::@254 main::@78 to main::check_status_cx16_rom5 [phi:main::@174/main::@252/main::@253/main::@254/main::@78->main::check_status_cx16_rom5]
    // main::check_status_cx16_rom5
  check_status_cx16_rom5:
    // main::check_status_cx16_rom5_check_status_rom1
    // status_rom[rom_chip] == status
    // [173] main::check_status_cx16_rom5_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboaa=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [174] main::check_status_cx16_rom5_check_status_rom1_return#0 = (char)main::check_status_cx16_rom5_check_status_rom1_$0 -- vbuxx=vbuaa 
    tax
    // [175] phi from main::check_status_cx16_rom5_check_status_rom1 to main::@79 [phi:main::check_status_cx16_rom5_check_status_rom1->main::@79]
    // main::@79
    // strncmp(&rom_github[0], &rom_file_github[0], 7)
    // [176] call strncmp
    // [1081] phi from main::@79 to strncmp [phi:main::@79->strncmp]
    jsr strncmp
    // strncmp(&rom_github[0], &rom_file_github[0], 7)
    // [177] strncmp::return#3 = strncmp::return#2
    // main::@172
    // [178] main::$50 = strncmp::return#3 -- vwsm1=vwsm2 
    lda strncmp.return
    sta main__50
    lda strncmp.return+1
    sta main__50+1
    // if(check_status_cx16_rom(STATUS_FLASH) && rom_release[0] == rom_file_release[0] && strncmp(&rom_github[0], &rom_file_github[0], 7) == 0)
    // [179] if(0==main::check_status_cx16_rom5_check_status_rom1_return#0) goto main::check_status_smc8 -- 0_eq_vbuxx_then_la1 
    cpx #0
    beq check_status_smc8
    // main::@256
    // [180] if(*rom_release!=*rom_file_release) goto main::check_status_smc8 -- _deref_pbuc1_neq__deref_pbuc2_then_la1 
    lda rom_release
    cmp rom_file_release
    bne check_status_smc8
    // main::@255
    // [181] if(main::$50==0) goto main::@15 -- vwsm1_eq_0_then_la1 
    lda main__50
    ora main__50+1
    bne !__b15+
    jmp __b15
  !__b15:
    // main::check_status_smc8
  check_status_smc8:
    // status_smc == status
    // [182] main::check_status_smc8_$0 = status_smc#147 == STATUS_ISSUE -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [183] main::check_status_smc8_return#0 = (char)main::check_status_smc8_$0 -- vbuz1=vbuaa 
    sta.z check_status_smc8_return
    // main::check_status_vera1
    // status_vera == status
    // [184] main::check_status_vera1_$0 = status_vera#115 == STATUS_ISSUE -- vboaa=vbum1_eq_vbuc1 
    lda status_vera
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_vera == status);
    // [185] main::check_status_vera1_return#0 = (char)main::check_status_vera1_$0 -- vbuz1=vbuaa 
    sta.z check_status_vera1_return
    // [186] phi from main::check_status_vera1 to main::@80 [phi:main::check_status_vera1->main::@80]
    // main::@80
    // check_status_roms(STATUS_ISSUE)
    // [187] call check_status_roms
    // [1093] phi from main::@80 to check_status_roms [phi:main::@80->check_status_roms]
    // [1093] phi check_status_roms::status#6 = STATUS_ISSUE [phi:main::@80->check_status_roms#0] -- vbuxx=vbuc1 
    ldx #STATUS_ISSUE
    jsr check_status_roms
    // check_status_roms(STATUS_ISSUE)
    // [188] check_status_roms::return#3 = check_status_roms::return#2
    // main::@175
    // [189] main::$59 = check_status_roms::return#3 -- vbum1=vbuaa 
    sta main__59
    // main::check_status_smc9
    // status_smc == status
    // [190] main::check_status_smc9_$0 = status_smc#147 == STATUS_ERROR -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [191] main::check_status_smc9_return#0 = (char)main::check_status_smc9_$0 -- vbum1=vbuaa 
    sta check_status_smc9_return
    // main::check_status_vera2
    // status_vera == status
    // [192] main::check_status_vera2_$0 = status_vera#115 == STATUS_ERROR -- vboaa=vbum1_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_vera == status);
    // [193] main::check_status_vera2_return#0 = (char)main::check_status_vera2_$0 -- vbuz1=vbuaa 
    sta.z check_status_vera2_return
    // [194] phi from main::check_status_vera2 to main::@81 [phi:main::check_status_vera2->main::@81]
    // main::@81
    // check_status_roms(STATUS_ERROR)
    // [195] call check_status_roms
    // [1093] phi from main::@81 to check_status_roms [phi:main::@81->check_status_roms]
    // [1093] phi check_status_roms::status#6 = STATUS_ERROR [phi:main::@81->check_status_roms#0] -- vbuxx=vbuc1 
    ldx #STATUS_ERROR
    jsr check_status_roms
    // check_status_roms(STATUS_ERROR)
    // [196] check_status_roms::return#4 = check_status_roms::return#2
    // main::@176
    // [197] main::$68 = check_status_roms::return#4 -- vbuxx=vbuaa 
    tax
    // if(!check_status_smc(STATUS_ISSUE) && !check_status_vera(STATUS_ISSUE) && !check_status_roms(STATUS_ISSUE) &&
    //        !check_status_smc(STATUS_ERROR) && !check_status_vera(STATUS_ERROR) && !check_status_roms(STATUS_ERROR))
    // [198] if(0!=main::check_status_smc8_return#0) goto main::check_status_vera3 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc8_return
    bne check_status_vera3
    // main::@261
    // [199] if(0==main::check_status_vera1_return#0) goto main::@260 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_vera1_return
    bne !__b260+
    jmp __b260
  !__b260:
    // main::check_status_vera3
  check_status_vera3:
    // status_vera == status
    // [200] main::check_status_vera3_$0 = status_vera#115 == STATUS_ERROR -- vboaa=vbum1_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_vera == status);
    // [201] main::check_status_vera3_return#0 = (char)main::check_status_vera3_$0
    // main::@82
    // if(check_status_vera(STATUS_ERROR))
    // [202] if(0==main::check_status_vera3_return#0) goto main::check_status_smc14 -- 0_eq_vbuaa_then_la1 
    cmp #0
    bne !check_status_smc14+
    jmp check_status_smc14
  !check_status_smc14:
    // main::bank_set_brom10
    // BROM = bank
    // [203] BROM = main::bank_set_brom10_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom10_bank
    sta.z BROM
    // main::CLI4
    // asm
    // asm { cli  }
    cli
    // main::vera_display_set_border_color1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [205] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [206] *VERA_DC_BORDER = RED -- _deref_pbuc1=vbuc2 
    lda #RED
    sta VERA_DC_BORDER
    // [207] phi from main::vera_display_set_border_color1 to main::@92 [phi:main::vera_display_set_border_color1->main::@92]
    // main::@92
    // textcolor(WHITE)
    // [208] call textcolor
    // [787] phi from main::@92 to textcolor [phi:main::@92->textcolor]
    // [787] phi textcolor::color#23 = WHITE [phi:main::@92->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [209] phi from main::@92 to main::@211 [phi:main::@92->main::@211]
    // main::@211
    // bgcolor(BLUE)
    // [210] call bgcolor
    // [792] phi from main::@211 to bgcolor [phi:main::@211->bgcolor]
    // [792] phi bgcolor::color#15 = BLUE [phi:main::@211->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // [211] phi from main::@211 to main::@212 [phi:main::@211->main::@212]
    // main::@212
    // clrscr()
    // [212] call clrscr
    jsr clrscr
    // [213] phi from main::@212 to main::@213 [phi:main::@212->main::@213]
    // main::@213
    // printf("There was a severe error updating your VERA!")
    // [214] call printf_str
    // [1125] phi from main::@213 to printf_str [phi:main::@213->printf_str]
    // [1125] phi printf_str::putc#79 = &cputc [phi:main::@213->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = main::s13 [phi:main::@213->printf_str#1] -- pbuz1=pbuc1 
    lda #<s13
    sta.z printf_str.s
    lda #>s13
    sta.z printf_str.s+1
    jsr printf_str
    // [215] phi from main::@213 to main::@214 [phi:main::@213->main::@214]
    // main::@214
    // printf("You are back at the READY prompt without resetting your CX16.\n\n")
    // [216] call printf_str
    // [1125] phi from main::@214 to printf_str [phi:main::@214->printf_str]
    // [1125] phi printf_str::putc#79 = &cputc [phi:main::@214->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = main::s14 [phi:main::@214->printf_str#1] -- pbuz1=pbuc1 
    lda #<s14
    sta.z printf_str.s
    lda #>s14
    sta.z printf_str.s+1
    jsr printf_str
    // [217] phi from main::@214 to main::@215 [phi:main::@214->main::@215]
    // main::@215
    // printf("Please don't reset or shut down your VERA until you've\n")
    // [218] call printf_str
    // [1125] phi from main::@215 to printf_str [phi:main::@215->printf_str]
    // [1125] phi printf_str::putc#79 = &cputc [phi:main::@215->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = main::s15 [phi:main::@215->printf_str#1] -- pbuz1=pbuc1 
    lda #<s15
    sta.z printf_str.s
    lda #>s15
    sta.z printf_str.s+1
    jsr printf_str
    // [219] phi from main::@215 to main::@216 [phi:main::@215->main::@216]
    // main::@216
    // printf("managed to either reflash your VERA with the previous firmware ")
    // [220] call printf_str
    // [1125] phi from main::@216 to printf_str [phi:main::@216->printf_str]
    // [1125] phi printf_str::putc#79 = &cputc [phi:main::@216->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = main::s16 [phi:main::@216->printf_str#1] -- pbuz1=pbuc1 
    lda #<s16
    sta.z printf_str.s
    lda #>s16
    sta.z printf_str.s+1
    jsr printf_str
    // [221] phi from main::@216 to main::@217 [phi:main::@216->main::@217]
    // main::@217
    // printf("or have update successs retrying!\n\n")
    // [222] call printf_str
    // [1125] phi from main::@217 to printf_str [phi:main::@217->printf_str]
    // [1125] phi printf_str::putc#79 = &cputc [phi:main::@217->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = main::s17 [phi:main::@217->printf_str#1] -- pbuz1=pbuc1 
    lda #<s17
    sta.z printf_str.s
    lda #>s17
    sta.z printf_str.s+1
    jsr printf_str
    // [223] phi from main::@217 to main::@218 [phi:main::@217->main::@218]
    // main::@218
    // printf("PLEASE REMOVE THE JP1 JUMPER OR YOUR SDCARD WON'T WORK!\n")
    // [224] call printf_str
    // [1125] phi from main::@218 to printf_str [phi:main::@218->printf_str]
    // [1125] phi printf_str::putc#79 = &cputc [phi:main::@218->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = main::s18 [phi:main::@218->printf_str#1] -- pbuz1=pbuc1 
    lda #<s18
    sta.z printf_str.s
    lda #>s18
    sta.z printf_str.s+1
    jsr printf_str
    // [225] phi from main::@218 to main::@219 [phi:main::@218->main::@219]
    // main::@219
    // wait_moment(32)
    // [226] call wait_moment
    // [1134] phi from main::@219 to wait_moment [phi:main::@219->wait_moment]
    // [1134] phi wait_moment::w#17 = $20 [phi:main::@219->wait_moment#0] -- vbuz1=vbuc1 
    lda #$20
    sta.z wait_moment.w
    jsr wait_moment
    // [227] phi from main::@219 to main::@220 [phi:main::@219->main::@220]
    // main::@220
    // system_reset()
    // [228] call system_reset
    // [1142] phi from main::@220 to system_reset [phi:main::@220->system_reset]
    jsr system_reset
    // main::@return
    // }
    // [229] return 
    rts
    // main::check_status_smc14
  check_status_smc14:
    // status_smc == status
    // [230] main::check_status_smc14_$0 = status_smc#147 == STATUS_SKIP -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [231] main::check_status_smc14_return#0 = (char)main::check_status_smc14_$0 -- vbuz1=vbuaa 
    sta.z check_status_smc14_return
    // main::check_status_smc15
    // status_smc == status
    // [232] main::check_status_smc15_$0 = status_smc#147 == STATUS_NONE -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_NONE
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [233] main::check_status_smc15_return#0 = (char)main::check_status_smc15_$0 -- vbuz1=vbuaa 
    sta.z check_status_smc15_return
    // main::check_status_vera8
    // status_vera == status
    // [234] main::check_status_vera8_$0 = status_vera#115 == STATUS_SKIP -- vboaa=vbum1_eq_vbuc1 
    lda status_vera
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_vera == status);
    // [235] main::check_status_vera8_return#0 = (char)main::check_status_vera8_$0 -- vbuz1=vbuaa 
    sta.z check_status_vera8_return
    // main::check_status_vera9
    // status_vera == status
    // [236] main::check_status_vera9_$0 = status_vera#115 == STATUS_NONE -- vboaa=vbum1_eq_vbuc1 
    lda status_vera
    eor #STATUS_NONE
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_vera == status);
    // [237] main::check_status_vera9_return#0 = (char)main::check_status_vera9_$0 -- vbuyy=vbuaa 
    tay
    // [238] phi from main::check_status_vera9 to main::@91 [phi:main::check_status_vera9->main::@91]
    // main::@91
    // check_status_roms_less(STATUS_SKIP)
    // [239] call check_status_roms_less
    // [1147] phi from main::@91 to check_status_roms_less [phi:main::@91->check_status_roms_less]
    jsr check_status_roms_less
    // check_status_roms_less(STATUS_SKIP)
    // [240] check_status_roms_less::return#3 = check_status_roms_less::return#2
    // main::@210
    // [241] main::$81 = check_status_roms_less::return#3 -- vbuxx=vbuaa 
    tax
    // if((check_status_smc(STATUS_SKIP) || check_status_smc(STATUS_NONE)) && 
    //        (check_status_vera(STATUS_SKIP) || check_status_vera(STATUS_NONE)) && 
    //        (check_status_roms_less(STATUS_SKIP)) )
    // [242] if(0!=main::check_status_smc14_return#0) goto main::@269 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc14_return
    beq !__b269+
    jmp __b269
  !__b269:
    // main::@270
    // [243] if(0!=main::check_status_smc15_return#0) goto main::@269 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc15_return
    beq !__b269+
    jmp __b269
  !__b269:
    // main::check_status_smc16
  check_status_smc16:
    // status_smc == status
    // [244] main::check_status_smc16_$0 = status_smc#147 == STATUS_ERROR -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [245] main::check_status_smc16_return#0 = (char)main::check_status_smc16_$0 -- vbum1=vbuaa 
    sta check_status_smc16_return
    // main::check_status_vera10
    // status_vera == status
    // [246] main::check_status_vera10_$0 = status_vera#115 == STATUS_ERROR -- vboaa=vbum1_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_vera == status);
    // [247] main::check_status_vera10_return#0 = (char)main::check_status_vera10_$0 -- vbum1=vbuaa 
    sta check_status_vera10_return
    // [248] phi from main::check_status_vera10 to main::@94 [phi:main::check_status_vera10->main::@94]
    // main::@94
    // check_status_roms(STATUS_ERROR)
    // [249] call check_status_roms
    // [1093] phi from main::@94 to check_status_roms [phi:main::@94->check_status_roms]
    // [1093] phi check_status_roms::status#6 = STATUS_ERROR [phi:main::@94->check_status_roms#0] -- vbuxx=vbuc1 
    ldx #STATUS_ERROR
    jsr check_status_roms
    // check_status_roms(STATUS_ERROR)
    // [250] check_status_roms::return#10 = check_status_roms::return#2
    // main::@221
    // [251] main::$281 = check_status_roms::return#10 -- vbuxx=vbuaa 
    tax
    // if(check_status_smc(STATUS_ERROR) || check_status_vera(STATUS_ERROR) || check_status_roms(STATUS_ERROR))
    // [252] if(0!=main::check_status_smc16_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbum1_then_la1 
    lda check_status_smc16_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@272
    // [253] if(0!=main::check_status_vera10_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbum1_then_la1 
    lda check_status_vera10_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@271
    // [254] if(0!=main::$281) goto main::vera_display_set_border_color3 -- 0_neq_vbuxx_then_la1 
    cpx #0
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::check_status_smc17
    // status_smc == status
    // [255] main::check_status_smc17_$0 = status_smc#147 == STATUS_ISSUE -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [256] main::check_status_smc17_return#0 = (char)main::check_status_smc17_$0 -- vbum1=vbuaa 
    sta check_status_smc17_return
    // main::check_status_vera11
    // status_vera == status
    // [257] main::check_status_vera11_$0 = status_vera#115 == STATUS_ISSUE -- vboaa=vbum1_eq_vbuc1 
    lda status_vera
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_vera == status);
    // [258] main::check_status_vera11_return#0 = (char)main::check_status_vera11_$0 -- vbum1=vbuaa 
    sta check_status_vera11_return
    // [259] phi from main::check_status_vera11 to main::@96 [phi:main::check_status_vera11->main::@96]
    // main::@96
    // check_status_roms(STATUS_ISSUE)
    // [260] call check_status_roms
    // [1093] phi from main::@96 to check_status_roms [phi:main::@96->check_status_roms]
    // [1093] phi check_status_roms::status#6 = STATUS_ISSUE [phi:main::@96->check_status_roms#0] -- vbuxx=vbuc1 
    ldx #STATUS_ISSUE
    jsr check_status_roms
    // check_status_roms(STATUS_ISSUE)
    // [261] check_status_roms::return#11 = check_status_roms::return#2
    // main::@225
    // [262] main::$286 = check_status_roms::return#11 -- vbuxx=vbuaa 
    tax
    // if(check_status_smc(STATUS_ISSUE) || check_status_vera(STATUS_ISSUE) || check_status_roms(STATUS_ISSUE))
    // [263] if(0!=main::check_status_smc17_return#0) goto main::vera_display_set_border_color4 -- 0_neq_vbum1_then_la1 
    lda check_status_smc17_return
    beq !vera_display_set_border_color4+
    jmp vera_display_set_border_color4
  !vera_display_set_border_color4:
    // main::@274
    // [264] if(0!=main::check_status_vera11_return#0) goto main::vera_display_set_border_color4 -- 0_neq_vbum1_then_la1 
    lda check_status_vera11_return
    beq !vera_display_set_border_color4+
    jmp vera_display_set_border_color4
  !vera_display_set_border_color4:
    // main::@273
    // [265] if(0!=main::$286) goto main::vera_display_set_border_color4 -- 0_neq_vbuxx_then_la1 
    cpx #0
    beq !vera_display_set_border_color4+
    jmp vera_display_set_border_color4
  !vera_display_set_border_color4:
    // main::vera_display_set_border_color5
    // *VERA_CTRL &= ~VERA_DCSEL
    // [266] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [267] *VERA_DC_BORDER = GREEN -- _deref_pbuc1=vbuc2 
    lda #GREEN
    sta VERA_DC_BORDER
    // [268] phi from main::vera_display_set_border_color5 to main::@98 [phi:main::vera_display_set_border_color5->main::@98]
    // main::@98
    // display_action_progress("Your CX16 update is a success!")
    // [269] call display_action_progress
    // [1155] phi from main::@98 to display_action_progress [phi:main::@98->display_action_progress]
    // [1155] phi display_action_progress::info_text#30 = main::info_text43 [phi:main::@98->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text43
    sta.z display_action_progress.info_text
    lda #>info_text43
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::check_status_smc18
    // status_smc == status
    // [270] main::check_status_smc18_$0 = status_smc#147 == STATUS_FLASHED -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASHED
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [271] main::check_status_smc18_return#0 = (char)main::check_status_smc18_$0
    // main::@99
    // if(check_status_smc(STATUS_FLASHED))
    // [272] if(0!=main::check_status_smc18_return#0) goto main::@58 -- 0_neq_vbuaa_then_la1 
    cmp #0
    beq !__b58+
    jmp __b58
  !__b58:
    // [273] phi from main::@99 to main::@18 [phi:main::@99->main::@18]
    // main::@18
    // display_progress_text(display_debriefing_text_rom, display_debriefing_count_rom)
    // [274] call display_progress_text
    // [1169] phi from main::@18 to display_progress_text [phi:main::@18->display_progress_text]
    // [1169] phi display_progress_text::text#13 = display_debriefing_text_rom [phi:main::@18->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_debriefing_text_rom
    sta.z display_progress_text.text
    lda #>display_debriefing_text_rom
    sta.z display_progress_text.text+1
    // [1169] phi display_progress_text::lines#12 = display_debriefing_count_rom [phi:main::@18->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_debriefing_count_rom
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [275] phi from main::@18 main::@93 main::@97 to main::@5 [phi:main::@18/main::@93/main::@97->main::@5]
    // main::@5
  __b5:
    // textcolor(PINK)
    // [276] call textcolor
  // DE6 | Wait until reset
    // [787] phi from main::@5 to textcolor [phi:main::@5->textcolor]
    // [787] phi textcolor::color#23 = PINK [phi:main::@5->textcolor#0] -- vbuxx=vbuc1 
    ldx #PINK
    jsr textcolor
    // [277] phi from main::@5 to main::@238 [phi:main::@5->main::@238]
    // main::@238
    // display_progress_line(2, "DON'T DO ANYTHING UNTIL COUNTDOWN FINISHES!")
    // [278] call display_progress_line
    // [1179] phi from main::@238 to display_progress_line [phi:main::@238->display_progress_line]
    // [1179] phi display_progress_line::text#3 = main::text [phi:main::@238->display_progress_line#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_progress_line.text
    lda #>text
    sta.z display_progress_line.text+1
    // [1179] phi display_progress_line::line#3 = 2 [phi:main::@238->display_progress_line#1] -- vbuxx=vbuc1 
    ldx #2
    jsr display_progress_line
    // [279] phi from main::@238 to main::@239 [phi:main::@238->main::@239]
    // main::@239
    // textcolor(WHITE)
    // [280] call textcolor
    // [787] phi from main::@239 to textcolor [phi:main::@239->textcolor]
    // [787] phi textcolor::color#23 = WHITE [phi:main::@239->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [281] phi from main::@239 to main::@66 [phi:main::@239->main::@66]
    // [281] phi main::w1#2 = $78 [phi:main::@239->main::@66#0] -- vbum1=vbuc1 
    lda #$78
    sta w1
    // main::@66
  __b66:
    // for (unsigned char w=120; w>0; w--)
    // [282] if(main::w1#2>0) goto main::@67 -- vbum1_gt_0_then_la1 
    lda w1
    bne __b67
    // [283] phi from main::@66 to main::@68 [phi:main::@66->main::@68]
    // main::@68
    // system_reset()
    // [284] call system_reset
    // [1142] phi from main::@68 to system_reset [phi:main::@68->system_reset]
    jsr system_reset
    rts
    // [285] phi from main::@66 to main::@67 [phi:main::@66->main::@67]
    // main::@67
  __b67:
    // wait_moment(1)
    // [286] call wait_moment
    // [1134] phi from main::@67 to wait_moment [phi:main::@67->wait_moment]
    // [1134] phi wait_moment::w#17 = 1 [phi:main::@67->wait_moment#0] -- vbuz1=vbuc1 
    lda #1
    sta.z wait_moment.w
    jsr wait_moment
    // [287] phi from main::@67 to main::@240 [phi:main::@67->main::@240]
    // main::@240
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [288] call snprintf_init
    // [1184] phi from main::@240 to snprintf_init [phi:main::@240->snprintf_init]
    // [1184] phi snprintf_init::s#30 = info_text [phi:main::@240->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [289] phi from main::@240 to main::@241 [phi:main::@240->main::@241]
    // main::@241
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [290] call printf_str
    // [1125] phi from main::@241 to printf_str [phi:main::@241->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:main::@241->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = main::s22 [phi:main::@241->printf_str#1] -- pbuz1=pbuc1 
    lda #<s22
    sta.z printf_str.s
    lda #>s22
    sta.z printf_str.s+1
    jsr printf_str
    // main::@242
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [291] printf_uchar::uvalue#14 = main::w1#2 -- vbuxx=vbum1 
    ldx w1
    // [292] call printf_uchar
    // [1189] phi from main::@242 to printf_uchar [phi:main::@242->printf_uchar]
    // [1189] phi printf_uchar::format_zero_padding#15 = 0 [phi:main::@242->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1189] phi printf_uchar::format_min_length#15 = 0 [phi:main::@242->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1189] phi printf_uchar::putc#15 = &snputc [phi:main::@242->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1189] phi printf_uchar::format_radix#15 = DECIMAL [phi:main::@242->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [1189] phi printf_uchar::uvalue#15 = printf_uchar::uvalue#14 [phi:main::@242->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [293] phi from main::@242 to main::@243 [phi:main::@242->main::@243]
    // main::@243
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [294] call printf_str
    // [1125] phi from main::@243 to printf_str [phi:main::@243->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:main::@243->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = main::s23 [phi:main::@243->printf_str#1] -- pbuz1=pbuc1 
    lda #<s23
    sta.z printf_str.s
    lda #>s23
    sta.z printf_str.s+1
    jsr printf_str
    // main::@244
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [295] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [296] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [298] call display_action_text
    // [1200] phi from main::@244 to display_action_text [phi:main::@244->display_action_text]
    // [1200] phi display_action_text::info_text#25 = info_text [phi:main::@244->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@245
    // for (unsigned char w=120; w>0; w--)
    // [299] main::w1#1 = -- main::w1#2 -- vbum1=_dec_vbum1 
    dec w1
    // [281] phi from main::@245 to main::@66 [phi:main::@245->main::@66]
    // [281] phi main::w1#2 = main::w1#1 [phi:main::@245->main::@66#0] -- register_copy 
    jmp __b66
    // main::@58
  __b58:
    // if(smc_bootloader == 1)
    // [300] if(smc_bootloader#0!=1) goto main::@59 -- vwum1_neq_vbuc1_then_la1 
    lda smc_bootloader+1
    bne __b59
    lda smc_bootloader
    cmp #1
    bne __b59
    // [301] phi from main::@58 to main::@64 [phi:main::@58->main::@64]
    // main::@64
    // smc_reset()
    // [302] call smc_reset
    // [1214] phi from main::@64 to smc_reset [phi:main::@64->smc_reset]
    jsr smc_reset
    // [303] phi from main::@58 main::@64 to main::@59 [phi:main::@58/main::@64->main::@59]
    // main::@59
  __b59:
    // display_progress_text(display_debriefing_smc_text, display_debriefing_smc_count)
    // [304] call display_progress_text
    // [1169] phi from main::@59 to display_progress_text [phi:main::@59->display_progress_text]
    // [1169] phi display_progress_text::text#13 = display_debriefing_smc_text [phi:main::@59->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_debriefing_smc_text
    sta.z display_progress_text.text
    lda #>display_debriefing_smc_text
    sta.z display_progress_text.text+1
    // [1169] phi display_progress_text::lines#12 = display_debriefing_smc_count [phi:main::@59->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_debriefing_smc_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [305] phi from main::@59 to main::@226 [phi:main::@59->main::@226]
    // main::@226
    // textcolor(PINK)
    // [306] call textcolor
    // [787] phi from main::@226 to textcolor [phi:main::@226->textcolor]
    // [787] phi textcolor::color#23 = PINK [phi:main::@226->textcolor#0] -- vbuxx=vbuc1 
    ldx #PINK
    jsr textcolor
    // [307] phi from main::@226 to main::@227 [phi:main::@226->main::@227]
    // main::@227
    // display_progress_line(2, "DON'T DO ANYTHING UNTIL COUNTDOWN FINISHES!")
    // [308] call display_progress_line
    // [1179] phi from main::@227 to display_progress_line [phi:main::@227->display_progress_line]
    // [1179] phi display_progress_line::text#3 = main::text [phi:main::@227->display_progress_line#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_progress_line.text
    lda #>text
    sta.z display_progress_line.text+1
    // [1179] phi display_progress_line::line#3 = 2 [phi:main::@227->display_progress_line#1] -- vbuxx=vbuc1 
    ldx #2
    jsr display_progress_line
    // [309] phi from main::@227 to main::@228 [phi:main::@227->main::@228]
    // main::@228
    // textcolor(WHITE)
    // [310] call textcolor
    // [787] phi from main::@228 to textcolor [phi:main::@228->textcolor]
    // [787] phi textcolor::color#23 = WHITE [phi:main::@228->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [311] phi from main::@228 to main::@60 [phi:main::@228->main::@60]
    // [311] phi main::w#2 = $78 [phi:main::@228->main::@60#0] -- vbum1=vbuc1 
    lda #$78
    sta w
    // main::@60
  __b60:
    // for (unsigned char w=120; w>0; w--)
    // [312] if(main::w#2>0) goto main::@61 -- vbum1_gt_0_then_la1 
    lda w
    bne __b61
    // [313] phi from main::@60 to main::@62 [phi:main::@60->main::@62]
    // main::@62
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [314] call snprintf_init
    // [1184] phi from main::@62 to snprintf_init [phi:main::@62->snprintf_init]
    // [1184] phi snprintf_init::s#30 = info_text [phi:main::@62->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [315] phi from main::@62 to main::@235 [phi:main::@62->main::@235]
    // main::@235
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [316] call printf_str
    // [1125] phi from main::@235 to printf_str [phi:main::@235->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:main::@235->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = main::s21 [phi:main::@235->printf_str#1] -- pbuz1=pbuc1 
    lda #<s21
    sta.z printf_str.s
    lda #>s21
    sta.z printf_str.s+1
    jsr printf_str
    // main::@236
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [317] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [318] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [320] call display_action_text
    // [1200] phi from main::@236 to display_action_text [phi:main::@236->display_action_text]
    // [1200] phi display_action_text::info_text#25 = info_text [phi:main::@236->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [321] phi from main::@236 to main::@237 [phi:main::@236->main::@237]
    // main::@237
    // smc_reset()
    // [322] call smc_reset
  // DE5 | The components correctly updated, SMC bootloader 2
  // When bootloader 1, the CX16 won't shut down automatically and will hang! The user will see the above bootloader 1 action.
  // When bootloader 2, the CX16 will shut down automatically. The user will never see the bootloader 1 action.
    // [1214] phi from main::@237 to smc_reset [phi:main::@237->smc_reset]
    jsr smc_reset
    // [323] phi from main::@237 main::@63 to main::@63 [phi:main::@237/main::@63->main::@63]
  __b6:
  // This call will reboot the SMC, which will reset the CX16 if bootloader R2.
    // main::@63
    jmp __b6
    // [324] phi from main::@60 to main::@61 [phi:main::@60->main::@61]
    // main::@61
  __b61:
    // wait_moment(1)
    // [325] call wait_moment
    // [1134] phi from main::@61 to wait_moment [phi:main::@61->wait_moment]
    // [1134] phi wait_moment::w#17 = 1 [phi:main::@61->wait_moment#0] -- vbuz1=vbuc1 
    lda #1
    sta.z wait_moment.w
    jsr wait_moment
    // [326] phi from main::@61 to main::@229 [phi:main::@61->main::@229]
    // main::@229
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [327] call snprintf_init
    // [1184] phi from main::@229 to snprintf_init [phi:main::@229->snprintf_init]
    // [1184] phi snprintf_init::s#30 = info_text [phi:main::@229->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [328] phi from main::@229 to main::@230 [phi:main::@229->main::@230]
    // main::@230
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [329] call printf_str
    // [1125] phi from main::@230 to printf_str [phi:main::@230->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:main::@230->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = s1 [phi:main::@230->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s1
    sta.z printf_str.s
    lda #>@s1
    sta.z printf_str.s+1
    jsr printf_str
    // main::@231
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [330] printf_uchar::uvalue#13 = main::w#2 -- vbuxx=vbum1 
    ldx w
    // [331] call printf_uchar
    // [1189] phi from main::@231 to printf_uchar [phi:main::@231->printf_uchar]
    // [1189] phi printf_uchar::format_zero_padding#15 = 1 [phi:main::@231->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1189] phi printf_uchar::format_min_length#15 = 3 [phi:main::@231->printf_uchar#1] -- vbum1=vbuc1 
    lda #3
    sta printf_uchar.format_min_length
    // [1189] phi printf_uchar::putc#15 = &snputc [phi:main::@231->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1189] phi printf_uchar::format_radix#15 = DECIMAL [phi:main::@231->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [1189] phi printf_uchar::uvalue#15 = printf_uchar::uvalue#13 [phi:main::@231->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [332] phi from main::@231 to main::@232 [phi:main::@231->main::@232]
    // main::@232
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [333] call printf_str
    // [1125] phi from main::@232 to printf_str [phi:main::@232->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:main::@232->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = main::s20 [phi:main::@232->printf_str#1] -- pbuz1=pbuc1 
    lda #<s20
    sta.z printf_str.s
    lda #>s20
    sta.z printf_str.s+1
    jsr printf_str
    // main::@233
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [334] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [335] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [337] call display_action_text
    // [1200] phi from main::@233 to display_action_text [phi:main::@233->display_action_text]
    // [1200] phi display_action_text::info_text#25 = info_text [phi:main::@233->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@234
    // for (unsigned char w=120; w>0; w--)
    // [338] main::w#1 = -- main::w#2 -- vbum1=_dec_vbum1 
    dec w
    // [311] phi from main::@234 to main::@60 [phi:main::@234->main::@60]
    // [311] phi main::w#2 = main::w#1 [phi:main::@234->main::@60#0] -- register_copy 
    jmp __b60
    // main::vera_display_set_border_color4
  vera_display_set_border_color4:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [339] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [340] *VERA_DC_BORDER = YELLOW -- _deref_pbuc1=vbuc2 
    lda #YELLOW
    sta VERA_DC_BORDER
    // [341] phi from main::vera_display_set_border_color4 to main::@97 [phi:main::vera_display_set_border_color4->main::@97]
    // main::@97
    // display_action_progress("Update issues, your CX16 is not updated!")
    // [342] call display_action_progress
    // [1155] phi from main::@97 to display_action_progress [phi:main::@97->display_action_progress]
    // [1155] phi display_action_progress::info_text#30 = main::info_text42 [phi:main::@97->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text42
    sta.z display_action_progress.info_text
    lda #>info_text42
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    jmp __b5
    // main::vera_display_set_border_color3
  vera_display_set_border_color3:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [343] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [344] *VERA_DC_BORDER = RED -- _deref_pbuc1=vbuc2 
    lda #RED
    sta VERA_DC_BORDER
    // [345] phi from main::vera_display_set_border_color3 to main::@95 [phi:main::vera_display_set_border_color3->main::@95]
    // main::@95
    // display_action_progress("Update Failure! Your CX16 may no longer boot!")
    // [346] call display_action_progress
    // [1155] phi from main::@95 to display_action_progress [phi:main::@95->display_action_progress]
    // [1155] phi display_action_progress::info_text#30 = main::info_text40 [phi:main::@95->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text40
    sta.z display_action_progress.info_text
    lda #>info_text40
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [347] phi from main::@95 to main::@222 [phi:main::@95->main::@222]
    // main::@222
    // display_action_text("Take a photo of this screen and wait at leaast 60 seconds.")
    // [348] call display_action_text
    // [1200] phi from main::@222 to display_action_text [phi:main::@222->display_action_text]
    // [1200] phi display_action_text::info_text#25 = main::info_text41 [phi:main::@222->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text41
    sta.z display_action_text.info_text
    lda #>info_text41
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [349] phi from main::@222 to main::@223 [phi:main::@222->main::@223]
    // main::@223
    // wait_moment(250)
    // [350] call wait_moment
    // [1134] phi from main::@223 to wait_moment [phi:main::@223->wait_moment]
    // [1134] phi wait_moment::w#17 = $fa [phi:main::@223->wait_moment#0] -- vbuz1=vbuc1 
    lda #$fa
    sta.z wait_moment.w
    jsr wait_moment
    // [351] phi from main::@223 to main::@224 [phi:main::@223->main::@224]
    // main::@224
    // smc_reset()
    // [352] call smc_reset
    // [1214] phi from main::@224 to smc_reset [phi:main::@224->smc_reset]
    jsr smc_reset
    // [353] phi from main::@224 main::@65 to main::@65 [phi:main::@224/main::@65->main::@65]
    // main::@65
  __b65:
    jmp __b65
    // main::@269
  __b269:
    // if((check_status_smc(STATUS_SKIP) || check_status_smc(STATUS_NONE)) && 
    //        (check_status_vera(STATUS_SKIP) || check_status_vera(STATUS_NONE)) && 
    //        (check_status_roms_less(STATUS_SKIP)) )
    // [354] if(0!=main::check_status_vera8_return#0) goto main::@268 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_vera8_return
    bne __b268
    // main::@276
    // [355] if(0==main::check_status_vera9_return#0) goto main::check_status_smc16 -- 0_eq_vbuyy_then_la1 
    cpy #0
    bne !check_status_smc16+
    jmp check_status_smc16
  !check_status_smc16:
    // main::@268
  __b268:
    // [356] if(0!=main::$81) goto main::vera_display_set_border_color2 -- 0_neq_vbuxx_then_la1 
    cpx #0
    bne vera_display_set_border_color2
    jmp check_status_smc16
    // main::vera_display_set_border_color2
  vera_display_set_border_color2:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [357] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [358] *VERA_DC_BORDER = BLACK -- _deref_pbuc1=vbuc2 
    lda #BLACK
    sta VERA_DC_BORDER
    // [359] phi from main::vera_display_set_border_color2 to main::@93 [phi:main::vera_display_set_border_color2->main::@93]
    // main::@93
    // display_action_progress("No CX16 component has been updated with new firmware!")
    // [360] call display_action_progress
    // [1155] phi from main::@93 to display_action_progress [phi:main::@93->display_action_progress]
    // [1155] phi display_action_progress::info_text#30 = main::info_text39 [phi:main::@93->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text39
    sta.z display_action_progress.info_text
    lda #>info_text39
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    jmp __b5
    // main::@260
  __b260:
    // if(!check_status_smc(STATUS_ISSUE) && !check_status_vera(STATUS_ISSUE) && !check_status_roms(STATUS_ISSUE) &&
    //        !check_status_smc(STATUS_ERROR) && !check_status_vera(STATUS_ERROR) && !check_status_roms(STATUS_ERROR))
    // [361] if(0!=main::$59) goto main::check_status_vera3 -- 0_neq_vbum1_then_la1 
    lda main__59
    beq !check_status_vera3+
    jmp check_status_vera3
  !check_status_vera3:
    // main::@259
    // [362] if(0==main::check_status_smc9_return#0) goto main::@258 -- 0_eq_vbum1_then_la1 
    lda check_status_smc9_return
    beq __b258
    jmp check_status_vera3
    // main::@258
  __b258:
    // [363] if(0!=main::check_status_vera2_return#0) goto main::check_status_vera3 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_vera2_return
    beq !check_status_vera3+
    jmp check_status_vera3
  !check_status_vera3:
    // main::@257
    // [364] if(0==main::$68) goto main::check_status_vera4 -- 0_eq_vbuxx_then_la1 
    cpx #0
    beq check_status_vera4
    jmp check_status_vera3
    // main::check_status_vera4
  check_status_vera4:
    // status_vera == status
    // [365] main::check_status_vera4_$0 = status_vera#115 == STATUS_FLASH -- vboaa=vbum1_eq_vbuc1 
    lda status_vera
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_vera == status);
    // [366] main::check_status_vera4_return#0 = (char)main::check_status_vera4_$0 -- vbum1=vbuaa 
    sta check_status_vera4_return
    // main::check_status_smc10
    // status_smc == status
    // [367] main::check_status_smc10_$0 = status_smc#147 == STATUS_FLASH -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [368] main::check_status_smc10_return#0 = (char)main::check_status_smc10_$0 -- vbum1=vbuaa 
    sta check_status_smc10_return
    // [369] phi from main::check_status_smc10 to main::check_status_cx16_rom6 [phi:main::check_status_smc10->main::check_status_cx16_rom6]
    // main::check_status_cx16_rom6
    // main::check_status_cx16_rom6_check_status_rom1
    // status_rom[rom_chip] == status
    // [370] main::check_status_cx16_rom6_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboaa=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [371] main::check_status_cx16_rom6_check_status_rom1_return#0 = (char)main::check_status_cx16_rom6_check_status_rom1_$0 -- vbuyy=vbuaa 
    tay
    // [372] phi from main::check_status_cx16_rom6_check_status_rom1 to main::@83 [phi:main::check_status_cx16_rom6_check_status_rom1->main::@83]
    // main::@83
    // check_status_card_roms(STATUS_FLASH)
    // [373] call check_status_card_roms
    // [1223] phi from main::@83 to check_status_card_roms [phi:main::@83->check_status_card_roms]
    jsr check_status_card_roms
    // check_status_card_roms(STATUS_FLASH)
    // [374] check_status_card_roms::return#3 = check_status_card_roms::return#2
    // main::@179
    // [375] main::$193 = check_status_card_roms::return#3 -- vbuxx=vbuaa 
    tax
    // if(check_status_vera(STATUS_FLASH) || check_status_smc(STATUS_FLASH) || check_status_cx16_rom(STATUS_FLASH) || check_status_card_roms(STATUS_FLASH))
    // [376] if(0!=main::check_status_vera4_return#0) goto main::@16 -- 0_neq_vbum1_then_la1 
    lda check_status_vera4_return
    beq !__b16+
    jmp __b16
  !__b16:
    // main::@264
    // [377] if(0!=main::check_status_smc10_return#0) goto main::@16 -- 0_neq_vbum1_then_la1 
    lda check_status_smc10_return
    beq !__b16+
    jmp __b16
  !__b16:
    // main::@263
    // [378] if(0!=main::check_status_cx16_rom6_check_status_rom1_return#0) goto main::@16 -- 0_neq_vbuyy_then_la1 
    cpy #0
    beq !__b16+
    jmp __b16
  !__b16:
    // main::@262
    // [379] if(0!=main::$193) goto main::@16 -- 0_neq_vbuxx_then_la1 
    cpx #0
    beq !__b16+
    jmp __b16
  !__b16:
    // main::bank_set_brom7
  bank_set_brom7:
    // BROM = bank
    // [380] BROM = main::bank_set_brom7_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom7_bank
    sta.z BROM
    // main::CLI3
    // asm
    // asm { cli  }
    cli
    // main::check_status_vera5
    // status_vera == status
    // [382] main::check_status_vera5_$0 = status_vera#115 == STATUS_FLASH -- vboaa=vbum1_eq_vbuc1 
    lda status_vera
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_vera == status);
    // [383] main::check_status_vera5_return#0 = (char)main::check_status_vera5_$0
    // main::@84
    // if(check_status_vera(STATUS_FLASH))
    // [384] if(0==main::check_status_vera5_return#0) goto main::SEI4 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq SEI4
    // [385] phi from main::@84 to main::@53 [phi:main::@84->main::@53]
    // main::@53
    // main_vera_flash()
    // [386] call main_vera_flash
    // [1232] phi from main::@53 to main_vera_flash [phi:main::@53->main_vera_flash]
    jsr main_vera_flash
    // [387] phi from main::@53 main::@84 to main::SEI4 [phi:main::@53/main::@84->main::SEI4]
    // [387] phi __stdio_filecount#113 = __stdio_filecount#12 [phi:main::@53/main::@84->main::SEI4#0] -- register_copy 
    // [387] phi __errno#117 = __errno#123 [phi:main::@53/main::@84->main::SEI4#1] -- register_copy 
    // main::SEI4
  SEI4:
    // asm
    // asm { sei  }
    sei
    // main::bank_set_brom8
    // BROM = bank
    // [389] BROM = main::bank_set_brom8_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom8_bank
    sta.z BROM
    // [390] phi from main::bank_set_brom8 to main::@85 [phi:main::bank_set_brom8->main::@85]
    // main::@85
    // display_progress_clear()
    // [391] call display_progress_clear
    // [1037] phi from main::@85 to display_progress_clear [phi:main::@85->display_progress_clear]
    jsr display_progress_clear
    // main::check_status_smc11
    // status_smc == status
    // [392] main::check_status_smc11_$0 = status_smc#147 == STATUS_FLASH -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [393] main::check_status_smc11_return#0 = (char)main::check_status_smc11_$0 -- vbuyy=vbuaa 
    tay
    // main::check_status_vera6
    // status_vera == status
    // [394] main::check_status_vera6_$0 = status_vera#115 == STATUS_ERROR -- vboaa=vbum1_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_vera == status);
    // [395] main::check_status_vera6_return#0 = (char)main::check_status_vera6_$0 -- vbuxx=vbuaa 
    tax
    // main::@86
    // if (check_status_smc(STATUS_FLASH) && !check_status_vera(STATUS_ERROR))
    // [396] if(0==main::check_status_smc11_return#0) goto main::SEI5 -- 0_eq_vbuyy_then_la1 
    cpy #0
    beq SEI5
    // main::@265
    // [397] if(0==main::check_status_vera6_return#0) goto main::@54 -- 0_eq_vbuxx_then_la1 
    cpx #0
    bne !__b54+
    jmp __b54
  !__b54:
    // [398] phi from main::@265 to main::SEI5 [phi:main::@265->main::SEI5]
    // [398] phi from main::@187 main::@42 main::@43 main::@57 main::@86 to main::SEI5 [phi:main::@187/main::@42/main::@43/main::@57/main::@86->main::SEI5]
    // [398] phi __stdio_filecount#566 = __stdio_filecount#36 [phi:main::@187/main::@42/main::@43/main::@57/main::@86->main::SEI5#0] -- register_copy 
    // [398] phi __errno#573 = __errno#123 [phi:main::@187/main::@42/main::@43/main::@57/main::@86->main::SEI5#1] -- register_copy 
    // main::SEI5
  SEI5:
    // asm
    // asm { sei  }
    sei
    // main::check_status_vera7
    // status_vera == status
    // [400] main::check_status_vera7_$0 = status_vera#115 == STATUS_ERROR -- vboaa=vbum1_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_vera == status);
    // [401] main::check_status_vera7_return#0 = (char)main::check_status_vera7_$0
    // main::@87
    // if(!check_status_vera(STATUS_ERROR))
    // [402] if(0!=main::check_status_vera7_return#0) goto main::@44 -- 0_neq_vbuaa_then_la1 
    cmp #0
    bne __b44
    // [403] phi from main::@87 to main::@45 [phi:main::@87->main::@45]
    // [403] phi __stdio_filecount#114 = __stdio_filecount#566 [phi:main::@87->main::@45#0] -- register_copy 
    // [403] phi __errno#118 = __errno#573 [phi:main::@87->main::@45#1] -- register_copy 
    // [403] phi main::rom_chip3#10 = 7 [phi:main::@87->main::@45#2] -- vbum1=vbuc1 
    lda #7
    sta rom_chip3
  // Flash the ROM chips. 
  // We loop first all the ROM chips and read the file contents.
  // Then we verify the file contents and flash the ROM only for the differences.
  // If the file contents are the same as the ROM contents, then no flashing is required.
  // IMPORTANT! We start to flash the ROMs on the extension card.
  // The last ROM flashed is the CX16 ROM on the CX16 board!
    // main::@45
  __b45:
    // for(unsigned char rom_chip = 7; rom_chip != 255; rom_chip--)
    // [404] if(main::rom_chip3#10!=$ff) goto main::check_status_rom1 -- vbum1_neq_vbuc1_then_la1 
    lda #$ff
    cmp rom_chip3
    bne check_status_rom1
    // [405] phi from main::@45 main::@87 to main::@44 [phi:main::@45/main::@87->main::@44]
    // main::@44
  __b44:
    // display_progress_clear()
    // [406] call display_progress_clear
    // [1037] phi from main::@44 to display_progress_clear [phi:main::@44->display_progress_clear]
    jsr display_progress_clear
    jmp check_status_vera3
    // main::check_status_rom1
  check_status_rom1:
    // status_rom[rom_chip] == status
    // [407] main::check_status_rom1_$0 = status_rom[main::rom_chip3#10] == STATUS_FLASH -- vboaa=pbuc1_derefidx_vbum1_eq_vbuc2 
    lda #STATUS_FLASH
    ldy rom_chip3
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [408] main::check_status_rom1_return#0 = (char)main::check_status_rom1_$0
    // main::@88
    // if(check_status_rom(rom_chip, STATUS_FLASH))
    // [409] if(0==main::check_status_rom1_return#0) goto main::@46 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b46
    // main::check_status_smc12
    // status_smc == status
    // [410] main::check_status_smc12_$0 = status_smc#147 == STATUS_FLASHED -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASHED
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [411] main::check_status_smc12_return#0 = (char)main::check_status_smc12_$0 -- vbuyy=vbuaa 
    tay
    // main::check_status_smc13
    // status_smc == status
    // [412] main::check_status_smc13_$0 = status_smc#147 == STATUS_SKIP -- vboaa=vbum1_eq_vbuc1 
    lda status_smc
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_smc == status);
    // [413] main::check_status_smc13_return#0 = (char)main::check_status_smc13_$0 -- vbuxx=vbuaa 
    tax
    // main::@89
    // if((rom_chip == 0 && (check_status_smc(STATUS_FLASHED) || check_status_smc(STATUS_SKIP))) || (rom_chip != 0))
    // [414] if(main::rom_chip3#10==0) goto main::@267 -- vbum1_eq_0_then_la1 
    // IMPORTANT! We only flash the CX16 ROM chip if the SMC got flashed succesfully!
    lda rom_chip3
    bne !__b267+
    jmp __b267
  !__b267:
    // main::@266
  __b266:
    // [415] if(main::rom_chip3#10!=0) goto main::bank_set_brom9 -- vbum1_neq_0_then_la1 
    lda rom_chip3
    bne bank_set_brom9
    // main::@52
    // display_info_rom(rom_chip, STATUS_ISSUE, "SMC Update failed!")
    // [416] display_info_rom::rom_chip#10 = main::rom_chip3#10 -- vbum1=vbum2 
    sta display_info_rom.rom_chip
    // [417] call display_info_rom
    // [1368] phi from main::@52 to display_info_rom [phi:main::@52->display_info_rom]
    // [1368] phi display_info_rom::info_text#16 = main::info_text35 [phi:main::@52->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text35
    sta.z display_info_rom.info_text
    lda #>info_text35
    sta.z display_info_rom.info_text+1
    // [1368] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#10 [phi:main::@52->display_info_rom#1] -- register_copy 
    // [1368] phi display_info_rom::info_status#16 = STATUS_ISSUE [phi:main::@52->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_rom.info_status
    jsr display_info_rom
    // [418] phi from main::@198 main::@209 main::@47 main::@51 main::@52 main::@88 to main::@46 [phi:main::@198/main::@209/main::@47/main::@51/main::@52/main::@88->main::@46]
    // [418] phi __stdio_filecount#565 = __stdio_filecount#39 [phi:main::@198/main::@209/main::@47/main::@51/main::@52/main::@88->main::@46#0] -- register_copy 
    // [418] phi __errno#572 = __errno#123 [phi:main::@198/main::@209/main::@47/main::@51/main::@52/main::@88->main::@46#1] -- register_copy 
    // main::@46
  __b46:
    // for(unsigned char rom_chip = 7; rom_chip != 255; rom_chip--)
    // [419] main::rom_chip3#1 = -- main::rom_chip3#10 -- vbum1=_dec_vbum1 
    dec rom_chip3
    // [403] phi from main::@46 to main::@45 [phi:main::@46->main::@45]
    // [403] phi __stdio_filecount#114 = __stdio_filecount#565 [phi:main::@46->main::@45#0] -- register_copy 
    // [403] phi __errno#118 = __errno#572 [phi:main::@46->main::@45#1] -- register_copy 
    // [403] phi main::rom_chip3#10 = main::rom_chip3#1 [phi:main::@46->main::@45#2] -- register_copy 
    jmp __b45
    // main::bank_set_brom9
  bank_set_brom9:
    // BROM = bank
    // [420] BROM = main::bank_set_brom9_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom9_bank
    sta.z BROM
    // [421] phi from main::bank_set_brom9 to main::@90 [phi:main::bank_set_brom9->main::@90]
    // main::@90
    // display_progress_clear()
    // [422] call display_progress_clear
    // [1037] phi from main::@90 to display_progress_clear [phi:main::@90->display_progress_clear]
    jsr display_progress_clear
    // main::@191
    // unsigned char rom_bank = rom_chip * 32
    // [423] main::rom_bank1#0 = main::rom_chip3#10 << 5 -- vbum1=vbum2_rol_5 
    lda rom_chip3
    asl
    asl
    asl
    asl
    asl
    sta rom_bank1
    // unsigned char* file = rom_file(rom_chip)
    // [424] rom_file::rom_chip#1 = main::rom_chip3#10 -- vbuaa=vbum1 
    lda rom_chip3
    // [425] call rom_file
    // [1413] phi from main::@191 to rom_file [phi:main::@191->rom_file]
    // [1413] phi rom_file::rom_chip#2 = rom_file::rom_chip#1 [phi:main::@191->rom_file#0] -- register_copy 
    jsr rom_file
    // unsigned char* file = rom_file(rom_chip)
    // [426] rom_file::return#5 = rom_file::return#2
    // main::@192
    // [427] main::file1#0 = rom_file::return#5
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [428] call snprintf_init
    // [1184] phi from main::@192 to snprintf_init [phi:main::@192->snprintf_init]
    // [1184] phi snprintf_init::s#30 = info_text [phi:main::@192->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [429] phi from main::@192 to main::@193 [phi:main::@192->main::@193]
    // main::@193
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [430] call printf_str
    // [1125] phi from main::@193 to printf_str [phi:main::@193->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:main::@193->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = main::s9 [phi:main::@193->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // main::@194
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [431] printf_string::str#25 = main::file1#0 -- pbuz1=pbum2 
    lda file1
    sta.z printf_string.str
    lda file1+1
    sta.z printf_string.str+1
    // [432] call printf_string
    // [1419] phi from main::@194 to printf_string [phi:main::@194->printf_string]
    // [1419] phi printf_string::putc#26 = &snputc [phi:main::@194->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1419] phi printf_string::str#26 = printf_string::str#25 [phi:main::@194->printf_string#1] -- register_copy 
    // [1419] phi printf_string::format_justify_left#26 = 0 [phi:main::@194->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1419] phi printf_string::format_min_length#26 = 0 [phi:main::@194->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [433] phi from main::@194 to main::@195 [phi:main::@194->main::@195]
    // main::@195
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [434] call printf_str
    // [1125] phi from main::@195 to printf_str [phi:main::@195->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:main::@195->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = main::s10 [phi:main::@195->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // main::@196
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [435] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [436] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_progress(info_text)
    // [438] call display_action_progress
    // [1155] phi from main::@196 to display_action_progress [phi:main::@196->display_action_progress]
    // [1155] phi display_action_progress::info_text#30 = info_text [phi:main::@196->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_progress.info_text
    lda #>@info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@197
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_READING, rom_bank, rom_sizes[rom_chip])
    // [439] main::$326 = main::rom_chip3#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip3
    asl
    asl
    sta main__326
    // [440] rom_read::rom_chip#1 = main::rom_chip3#10 -- vbum1=vbum2 
    lda rom_chip3
    sta rom_read.rom_chip
    // [441] rom_read::file#1 = main::file1#0 -- pbuz1=pbum2 
    lda file1
    sta.z rom_read.file
    lda file1+1
    sta.z rom_read.file+1
    // [442] rom_read::brom_bank_start#2 = main::rom_bank1#0 -- vbuz1=vbum2 
    lda rom_bank1
    sta.z rom_read.brom_bank_start
    // [443] rom_read::rom_size#1 = rom_sizes[main::$326] -- vduz1=pduc1_derefidx_vbum2 
    ldy main__326
    lda rom_sizes,y
    sta.z rom_read.rom_size
    lda rom_sizes+1,y
    sta.z rom_read.rom_size+1
    lda rom_sizes+2,y
    sta.z rom_read.rom_size+2
    lda rom_sizes+3,y
    sta.z rom_read.rom_size+3
    // [444] call rom_read
    // [1444] phi from main::@197 to rom_read [phi:main::@197->rom_read]
    // [1444] phi rom_read::rom_chip#20 = rom_read::rom_chip#1 [phi:main::@197->rom_read#0] -- register_copy 
    // [1444] phi rom_read::rom_size#12 = rom_read::rom_size#1 [phi:main::@197->rom_read#1] -- register_copy 
    // [1444] phi __errno#103 = __errno#118 [phi:main::@197->rom_read#2] -- register_copy 
    // [1444] phi __stdio_filecount#126 = __stdio_filecount#114 [phi:main::@197->rom_read#3] -- register_copy 
    // [1444] phi rom_read::file#10 = rom_read::file#1 [phi:main::@197->rom_read#4] -- register_copy 
    // [1444] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#2 [phi:main::@197->rom_read#5] -- register_copy 
    // [1444] phi rom_read::info_status#11 = STATUS_READING [phi:main::@197->rom_read#6] -- vbuz1=vbuc1 
    lda #STATUS_READING
    sta.z rom_read.info_status
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_READING, rom_bank, rom_sizes[rom_chip])
    // [445] rom_read::return#3 = rom_read::return#0
    // main::@198
    // [446] main::rom_bytes_read1#0 = rom_read::return#3
    // if(rom_bytes_read)
    // [447] if(0==main::rom_bytes_read1#0) goto main::@46 -- 0_eq_vdum1_then_la1 
    lda rom_bytes_read1
    ora rom_bytes_read1+1
    ora rom_bytes_read1+2
    ora rom_bytes_read1+3
    bne !__b46+
    jmp __b46
  !__b46:
    // [448] phi from main::@198 to main::@49 [phi:main::@198->main::@49]
    // main::@49
    // display_action_progress("Comparing ... (.) data, (=) same, (*) different.")
    // [449] call display_action_progress
  // Now we compare the RAM with the actual ROM contents.
    // [1155] phi from main::@49 to display_action_progress [phi:main::@49->display_action_progress]
    // [1155] phi display_action_progress::info_text#30 = main::info_text36 [phi:main::@49->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text36
    sta.z display_action_progress.info_text
    lda #>info_text36
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@199
    // display_info_rom(rom_chip, STATUS_COMPARING, "")
    // [450] display_info_rom::rom_chip#11 = main::rom_chip3#10 -- vbum1=vbum2 
    lda rom_chip3
    sta display_info_rom.rom_chip
    // [451] call display_info_rom
    // [1368] phi from main::@199 to display_info_rom [phi:main::@199->display_info_rom]
    // [1368] phi display_info_rom::info_text#16 = str [phi:main::@199->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z display_info_rom.info_text
    lda #>str
    sta.z display_info_rom.info_text+1
    // [1368] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#11 [phi:main::@199->display_info_rom#1] -- register_copy 
    // [1368] phi display_info_rom::info_status#16 = STATUS_COMPARING [phi:main::@199->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_COMPARING
    sta display_info_rom.info_status
    jsr display_info_rom
    // main::@200
    // unsigned long rom_differences = rom_verify(
    //                                 rom_chip, rom_bank, file_sizes[rom_chip])
    // [452] rom_verify::rom_chip#0 = main::rom_chip3#10 -- vbum1=vbum2 
    lda rom_chip3
    sta rom_verify.rom_chip
    // [453] rom_verify::rom_bank_start#0 = main::rom_bank1#0 -- vbuxx=vbum1 
    ldx rom_bank1
    // [454] rom_verify::file_size#0 = file_sizes[main::$326] -- vdum1=pduc1_derefidx_vbum2 
    ldy main__326
    lda file_sizes,y
    sta rom_verify.file_size
    lda file_sizes+1,y
    sta rom_verify.file_size+1
    lda file_sizes+2,y
    sta rom_verify.file_size+2
    lda file_sizes+3,y
    sta rom_verify.file_size+3
    // [455] call rom_verify
  // Verify the ROM...
    // [1524] phi from main::@200 to rom_verify [phi:main::@200->rom_verify]
    jsr rom_verify
    // unsigned long rom_differences = rom_verify(
    //                                 rom_chip, rom_bank, file_sizes[rom_chip])
    // [456] rom_verify::return#2 = rom_verify::rom_different_bytes#11
    // main::@201
    // [457] main::rom_differences#0 = rom_verify::return#2 -- vdum1=vduz2 
    lda.z rom_verify.return
    sta rom_differences
    lda.z rom_verify.return+1
    sta rom_differences+1
    lda.z rom_verify.return+2
    sta rom_differences+2
    lda.z rom_verify.return+3
    sta rom_differences+3
    // if (!rom_differences)
    // [458] if(0==main::rom_differences#0) goto main::@47 -- 0_eq_vdum1_then_la1 
    lda rom_differences
    ora rom_differences+1
    ora rom_differences+2
    ora rom_differences+3
    bne !__b47+
    jmp __b47
  !__b47:
    // [459] phi from main::@201 to main::@50 [phi:main::@201->main::@50]
    // main::@50
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [460] call snprintf_init
    // [1184] phi from main::@50 to snprintf_init [phi:main::@50->snprintf_init]
    // [1184] phi snprintf_init::s#30 = info_text [phi:main::@50->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main::@202
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [461] printf_ulong::uvalue#12 = main::rom_differences#0 -- vdum1=vdum2 
    lda rom_differences
    sta printf_ulong.uvalue
    lda rom_differences+1
    sta printf_ulong.uvalue+1
    lda rom_differences+2
    sta printf_ulong.uvalue+2
    lda rom_differences+3
    sta printf_ulong.uvalue+3
    // [462] call printf_ulong
    // [1588] phi from main::@202 to printf_ulong [phi:main::@202->printf_ulong]
    // [1588] phi printf_ulong::format_zero_padding#14 = 1 [phi:main::@202->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1588] phi printf_ulong::format_min_length#14 = 5 [phi:main::@202->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1588] phi printf_ulong::format_radix#14 = HEXADECIMAL [phi:main::@202->printf_ulong#2] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [1588] phi printf_ulong::uvalue#14 = printf_ulong::uvalue#12 [phi:main::@202->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [463] phi from main::@202 to main::@203 [phi:main::@202->main::@203]
    // main::@203
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [464] call printf_str
    // [1125] phi from main::@203 to printf_str [phi:main::@203->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:main::@203->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = s11 [phi:main::@203->printf_str#1] -- pbuz1=pbuc1 
    lda #<s11
    sta.z printf_str.s
    lda #>s11
    sta.z printf_str.s+1
    jsr printf_str
    // main::@204
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [465] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [466] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASH, info_text)
    // [468] display_info_rom::rom_chip#13 = main::rom_chip3#10 -- vbum1=vbum2 
    lda rom_chip3
    sta display_info_rom.rom_chip
    // [469] call display_info_rom
    // [1368] phi from main::@204 to display_info_rom [phi:main::@204->display_info_rom]
    // [1368] phi display_info_rom::info_text#16 = info_text [phi:main::@204->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1368] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#13 [phi:main::@204->display_info_rom#1] -- register_copy 
    // [1368] phi display_info_rom::info_status#16 = STATUS_FLASH [phi:main::@204->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_rom.info_status
    jsr display_info_rom
    // main::@205
    // unsigned long rom_flash_errors = rom_flash(
    //                                     rom_chip, rom_bank, file_sizes[rom_chip])
    // [470] rom_flash::rom_chip#0 = main::rom_chip3#10 -- vbum1=vbum2 
    lda rom_chip3
    sta rom_flash.rom_chip
    // [471] rom_flash::rom_bank_start#0 = main::rom_bank1#0 -- vbum1=vbum2 
    lda rom_bank1
    sta rom_flash.rom_bank_start
    // [472] rom_flash::file_size#0 = file_sizes[main::$326] -- vduz1=pduc1_derefidx_vbum2 
    ldy main__326
    lda file_sizes,y
    sta.z rom_flash.file_size
    lda file_sizes+1,y
    sta.z rom_flash.file_size+1
    lda file_sizes+2,y
    sta.z rom_flash.file_size+2
    lda file_sizes+3,y
    sta.z rom_flash.file_size+3
    // [473] call rom_flash
    // [1598] phi from main::@205 to rom_flash [phi:main::@205->rom_flash]
    jsr rom_flash
    // unsigned long rom_flash_errors = rom_flash(
    //                                     rom_chip, rom_bank, file_sizes[rom_chip])
    // [474] rom_flash::return#2 = rom_flash::flash_errors#2
    // main::@206
    // [475] main::rom_flash_errors#0 = rom_flash::return#2 -- vdum1=vduz2 
    lda.z rom_flash.return
    sta rom_flash_errors
    lda.z rom_flash.return+1
    sta rom_flash_errors+1
    lda.z rom_flash.return+2
    sta rom_flash_errors+2
    lda.z rom_flash.return+3
    sta rom_flash_errors+3
    // if(rom_flash_errors)
    // [476] if(0!=main::rom_flash_errors#0) goto main::@48 -- 0_neq_vdum1_then_la1 
    lda rom_flash_errors
    ora rom_flash_errors+1
    ora rom_flash_errors+2
    ora rom_flash_errors+3
    bne __b48
    // main::@51
    // display_info_rom(rom_chip, STATUS_FLASHED, NULL)
    // [477] display_info_rom::rom_chip#15 = main::rom_chip3#10 -- vbum1=vbum2 
    lda rom_chip3
    sta display_info_rom.rom_chip
    // [478] call display_info_rom
  // RFL3 | Flash ROM and all ok
    // [1368] phi from main::@51 to display_info_rom [phi:main::@51->display_info_rom]
    // [1368] phi display_info_rom::info_text#16 = 0 [phi:main::@51->display_info_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_rom.info_text
    sta.z display_info_rom.info_text+1
    // [1368] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#15 [phi:main::@51->display_info_rom#1] -- register_copy 
    // [1368] phi display_info_rom::info_status#16 = STATUS_FLASHED [phi:main::@51->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHED
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b46
    // [479] phi from main::@206 to main::@48 [phi:main::@206->main::@48]
    // main::@48
  __b48:
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [480] call snprintf_init
    // [1184] phi from main::@48 to snprintf_init [phi:main::@48->snprintf_init]
    // [1184] phi snprintf_init::s#30 = info_text [phi:main::@48->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main::@207
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [481] printf_ulong::uvalue#13 = main::rom_flash_errors#0 -- vdum1=vdum2 
    lda rom_flash_errors
    sta printf_ulong.uvalue
    lda rom_flash_errors+1
    sta printf_ulong.uvalue+1
    lda rom_flash_errors+2
    sta printf_ulong.uvalue+2
    lda rom_flash_errors+3
    sta printf_ulong.uvalue+3
    // [482] call printf_ulong
    // [1588] phi from main::@207 to printf_ulong [phi:main::@207->printf_ulong]
    // [1588] phi printf_ulong::format_zero_padding#14 = 0 [phi:main::@207->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1588] phi printf_ulong::format_min_length#14 = 0 [phi:main::@207->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1588] phi printf_ulong::format_radix#14 = DECIMAL [phi:main::@207->printf_ulong#2] -- vbuxx=vbuc1 
    ldx #DECIMAL
    // [1588] phi printf_ulong::uvalue#14 = printf_ulong::uvalue#13 [phi:main::@207->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [483] phi from main::@207 to main::@208 [phi:main::@207->main::@208]
    // main::@208
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [484] call printf_str
    // [1125] phi from main::@208 to printf_str [phi:main::@208->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:main::@208->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = main::s12 [phi:main::@208->printf_str#1] -- pbuz1=pbuc1 
    lda #<s12
    sta.z printf_str.s
    lda #>s12
    sta.z printf_str.s+1
    jsr printf_str
    // main::@209
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [485] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [486] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_ERROR, info_text)
    // [488] display_info_rom::rom_chip#14 = main::rom_chip3#10 -- vbum1=vbum2 
    lda rom_chip3
    sta display_info_rom.rom_chip
    // [489] call display_info_rom
    // [1368] phi from main::@209 to display_info_rom [phi:main::@209->display_info_rom]
    // [1368] phi display_info_rom::info_text#16 = info_text [phi:main::@209->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1368] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#14 [phi:main::@209->display_info_rom#1] -- register_copy 
    // [1368] phi display_info_rom::info_status#16 = STATUS_ERROR [phi:main::@209->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b46
    // main::@47
  __b47:
    // display_info_rom(rom_chip, STATUS_SKIP, "No update required")
    // [490] display_info_rom::rom_chip#12 = main::rom_chip3#10 -- vbum1=vbum2 
    lda rom_chip3
    sta display_info_rom.rom_chip
    // [491] call display_info_rom
  // RFL1 | ROM and ROM.BIN equal | Display that there are no differences between the ROM and ROM.BIN. Set ROM to Flashed. | None
    // [1368] phi from main::@47 to display_info_rom [phi:main::@47->display_info_rom]
    // [1368] phi display_info_rom::info_text#16 = info_text6 [phi:main::@47->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text6
    sta.z display_info_rom.info_text
    lda #>@info_text6
    sta.z display_info_rom.info_text+1
    // [1368] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#12 [phi:main::@47->display_info_rom#1] -- register_copy 
    // [1368] phi display_info_rom::info_status#16 = STATUS_SKIP [phi:main::@47->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b46
    // main::@267
  __b267:
    // if((rom_chip == 0 && (check_status_smc(STATUS_FLASHED) || check_status_smc(STATUS_SKIP))) || (rom_chip != 0))
    // [492] if(0!=main::check_status_smc12_return#0) goto main::bank_set_brom9 -- 0_neq_vbuyy_then_la1 
    cpy #0
    beq !bank_set_brom9+
    jmp bank_set_brom9
  !bank_set_brom9:
    // main::@275
    // [493] if(0!=main::check_status_smc13_return#0) goto main::bank_set_brom9 -- 0_neq_vbuxx_then_la1 
    cpx #0
    beq !bank_set_brom9+
    jmp bank_set_brom9
  !bank_set_brom9:
    jmp __b266
    // [494] phi from main::@265 to main::@54 [phi:main::@265->main::@54]
    // main::@54
  __b54:
    // display_action_progress("Reading SMC.BIN ... (.) data, ( ) empty")
    // [495] call display_action_progress
    // [1155] phi from main::@54 to display_action_progress [phi:main::@54->display_action_progress]
    // [1155] phi display_action_progress::info_text#30 = main::info_text30 [phi:main::@54->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text30
    sta.z display_action_progress.info_text
    lda #>info_text30
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [496] phi from main::@54 to main::@185 [phi:main::@54->main::@185]
    // main::@185
    // display_progress_clear()
    // [497] call display_progress_clear
    // [1037] phi from main::@185 to display_progress_clear [phi:main::@185->display_progress_clear]
    jsr display_progress_clear
    // [498] phi from main::@185 to main::@186 [phi:main::@185->main::@186]
    // main::@186
    // smc_read(STATUS_READING)
    // [499] call smc_read
    // [1691] phi from main::@186 to smc_read [phi:main::@186->smc_read]
    // [1691] phi __errno#100 = __errno#117 [phi:main::@186->smc_read#0] -- register_copy 
    // [1691] phi __stdio_filecount#123 = __stdio_filecount#113 [phi:main::@186->smc_read#1] -- register_copy 
    // [1691] phi smc_read::info_status#10 = STATUS_READING [phi:main::@186->smc_read#2] -- vbum1=vbuc1 
    lda #STATUS_READING
    sta smc_read.info_status
    jsr smc_read
    // smc_read(STATUS_READING)
    // [500] smc_read::return#3 = smc_read::return#0
    // main::@187
    // smc_file_size = smc_read(STATUS_READING)
    // [501] smc_file_size#1 = smc_read::return#3 -- vwum1=vwuz2 
    lda.z smc_read.return
    sta smc_file_size_1
    lda.z smc_read.return+1
    sta smc_file_size_1+1
    // if(smc_file_size)
    // [502] if(0==smc_file_size#1) goto main::SEI5 -- 0_eq_vwum1_then_la1 
    lda smc_file_size_1
    ora smc_file_size_1+1
    bne !SEI5+
    jmp SEI5
  !SEI5:
    // [503] phi from main::@187 to main::@55 [phi:main::@187->main::@55]
    // main::@55
    // display_action_text("Press both POWER/RESET buttons on the CX16 board!")
    // [504] call display_action_text
  // Flash the SMC chip.
    // [1200] phi from main::@55 to display_action_text [phi:main::@55->display_action_text]
    // [1200] phi display_action_text::info_text#25 = main::info_text31 [phi:main::@55->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text31
    sta.z display_action_text.info_text
    lda #>info_text31
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@188
    // [505] smc_bootloader#590 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_FLASHING, "Press POWER/RESET!")
    // [506] call display_info_smc
    // [925] phi from main::@188 to display_info_smc [phi:main::@188->display_info_smc]
    // [925] phi display_info_smc::info_text#24 = main::info_text32 [phi:main::@188->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text32
    sta.z display_info_smc.info_text
    lda #>info_text32
    sta.z display_info_smc.info_text+1
    // [925] phi smc_bootloader#14 = smc_bootloader#590 [phi:main::@188->display_info_smc#1] -- register_copy 
    // [925] phi display_info_smc::info_status#24 = STATUS_FLASHING [phi:main::@188->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHING
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // main::@189
    // unsigned int flashed_bytes = smc_flash(smc_file_size)
    // [507] smc_flash::smc_bytes_total#0 = smc_file_size#1 -- vwum1=vwum2 
    lda smc_file_size_1
    sta smc_flash.smc_bytes_total
    lda smc_file_size_1+1
    sta smc_flash.smc_bytes_total+1
    // [508] call smc_flash
    // [1741] phi from main::@189 to smc_flash [phi:main::@189->smc_flash]
    jsr smc_flash
    // unsigned int flashed_bytes = smc_flash(smc_file_size)
    // [509] smc_flash::return#5 = smc_flash::return#1
    // main::@190
    // [510] main::flashed_bytes#0 = smc_flash::return#5
    // if(flashed_bytes)
    // [511] if(0!=main::flashed_bytes#0) goto main::@42 -- 0_neq_vwum1_then_la1 
    lda flashed_bytes
    ora flashed_bytes+1
    bne __b42
    // main::@56
    // if(flashed_bytes == (unsigned int)0xFFFF)
    // [512] if(main::flashed_bytes#0==$ffff) goto main::@43 -- vwum1_eq_vwuc1_then_la1 
    lda flashed_bytes
    cmp #<$ffff
    bne !+
    lda flashed_bytes+1
    cmp #>$ffff
    beq __b43
  !:
    // main::@57
    // [513] smc_bootloader#597 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ISSUE, "POWER/RESET not pressed!")
    // [514] call display_info_smc
  // SFL2 | no action on POWER/RESET press request
    // [925] phi from main::@57 to display_info_smc [phi:main::@57->display_info_smc]
    // [925] phi display_info_smc::info_text#24 = main::info_text34 [phi:main::@57->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text34
    sta.z display_info_smc.info_text
    lda #>info_text34
    sta.z display_info_smc.info_text+1
    // [925] phi smc_bootloader#14 = smc_bootloader#597 [phi:main::@57->display_info_smc#1] -- register_copy 
    // [925] phi display_info_smc::info_status#24 = STATUS_ISSUE [phi:main::@57->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp SEI5
    // main::@43
  __b43:
    // [515] smc_bootloader#596 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ERROR, "SMC has errors!")
    // [516] call display_info_smc
  // SFL3 | errors during flash
    // [925] phi from main::@43 to display_info_smc [phi:main::@43->display_info_smc]
    // [925] phi display_info_smc::info_text#24 = main::info_text33 [phi:main::@43->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text33
    sta.z display_info_smc.info_text
    lda #>info_text33
    sta.z display_info_smc.info_text+1
    // [925] phi smc_bootloader#14 = smc_bootloader#596 [phi:main::@43->display_info_smc#1] -- register_copy 
    // [925] phi display_info_smc::info_status#24 = STATUS_ERROR [phi:main::@43->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp SEI5
    // main::@42
  __b42:
    // [517] smc_bootloader#595 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_FLASHED, NULL)
    // [518] call display_info_smc
  // SFL1 | and POWER/RESET pressed
    // [925] phi from main::@42 to display_info_smc [phi:main::@42->display_info_smc]
    // [925] phi display_info_smc::info_text#24 = 0 [phi:main::@42->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [925] phi smc_bootloader#14 = smc_bootloader#595 [phi:main::@42->display_info_smc#1] -- register_copy 
    // [925] phi display_info_smc::info_status#24 = STATUS_FLASHED [phi:main::@42->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHED
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp SEI5
    // [519] phi from main::@179 main::@262 main::@263 main::@264 to main::@16 [phi:main::@179/main::@262/main::@263/main::@264->main::@16]
    // main::@16
  __b16:
    // display_action_progress("Chipsets have been detected and update files validated!")
    // [520] call display_action_progress
    // [1155] phi from main::@16 to display_action_progress [phi:main::@16->display_action_progress]
    // [1155] phi display_action_progress::info_text#30 = main::info_text24 [phi:main::@16->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text24
    sta.z display_action_progress.info_text
    lda #>info_text24
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [521] phi from main::@16 to main::@180 [phi:main::@16->main::@180]
    // main::@180
    // unsigned char ch = util_wait_key("Continue with update of highlighted chipsets? [Y/N]", "nyNY")
    // [522] call util_wait_key
    // [1896] phi from main::@180 to util_wait_key [phi:main::@180->util_wait_key]
    // [1896] phi util_wait_key::filter#16 = main::filter4 [phi:main::@180->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter4
    sta.z util_wait_key.filter
    lda #>filter4
    sta.z util_wait_key.filter+1
    // [1896] phi util_wait_key::info_text#6 = main::info_text25 [phi:main::@180->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text25
    sta.z util_wait_key.info_text
    lda #>info_text25
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Continue with update of highlighted chipsets? [Y/N]", "nyNY")
    // [523] util_wait_key::return#13 = util_wait_key::ch#4 -- vbuaa=vwum1 
    lda util_wait_key.ch
    // main::@181
    // [524] main::ch4#0 = util_wait_key::return#13
    // strchr("nN", ch)
    // [525] strchr::c#1 = main::ch4#0 -- vbum1=vbuaa 
    sta strchr.c
    // [526] call strchr
    // [1921] phi from main::@181 to strchr [phi:main::@181->strchr]
    // [1921] phi strchr::c#4 = strchr::c#1 [phi:main::@181->strchr#0] -- register_copy 
    // [1921] phi strchr::str#2 = (const void *)main::$354 [phi:main::@181->strchr#1] -- pvoz1=pvoc1 
    lda #<main__354
    sta.z strchr.str
    lda #>main__354
    sta.z strchr.str+1
    jsr strchr
    // strchr("nN", ch)
    // [527] strchr::return#4 = strchr::return#2
    // main::@182
    // [528] main::$198 = strchr::return#4
    // if(strchr("nN", ch))
    // [529] if((void *)0==main::$198) goto main::bank_set_brom7 -- pvoc1_eq_pvoz1_then_la1 
    lda.z main__198
    cmp #<0
    bne !+
    lda.z main__198+1
    cmp #>0
    bne !bank_set_brom7+
    jmp bank_set_brom7
  !bank_set_brom7:
  !:
    // main::@17
    // [530] smc_bootloader#591 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_SKIP, "Cancelled")
    // [531] call display_info_smc
  // We cancel all updates, the updates are skipped.
    // [925] phi from main::@17 to display_info_smc [phi:main::@17->display_info_smc]
    // [925] phi display_info_smc::info_text#24 = main::info_text26 [phi:main::@17->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text26
    sta.z display_info_smc.info_text
    lda #>info_text26
    sta.z display_info_smc.info_text+1
    // [925] phi smc_bootloader#14 = smc_bootloader#591 [phi:main::@17->display_info_smc#1] -- register_copy 
    // [925] phi display_info_smc::info_status#24 = STATUS_SKIP [phi:main::@17->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [532] phi from main::@17 to main::@183 [phi:main::@17->main::@183]
    // main::@183
    // display_info_vera(STATUS_SKIP, "Cancelled")
    // [533] call display_info_vera
    // [1930] phi from main::@183 to display_info_vera [phi:main::@183->display_info_vera]
    // [1930] phi display_info_vera::info_text#15 = main::info_text26 [phi:main::@183->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text26
    sta.z display_info_vera.info_text
    lda #>info_text26
    sta.z display_info_vera.info_text+1
    // [1930] phi display_info_vera::info_status#15 = STATUS_SKIP [phi:main::@183->display_info_vera#1] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_vera.info_status
    jsr display_info_vera
    // [534] phi from main::@183 to main::@39 [phi:main::@183->main::@39]
    // [534] phi main::rom_chip2#2 = 0 [phi:main::@183->main::@39#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip2
    // main::@39
  __b39:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [535] if(main::rom_chip2#2<8) goto main::@40 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip2
    cmp #8
    bcc __b40
    // [536] phi from main::@39 to main::@41 [phi:main::@39->main::@41]
    // main::@41
    // display_action_text("You have selected not to cancel the update ... ")
    // [537] call display_action_text
    // [1200] phi from main::@41 to display_action_text [phi:main::@41->display_action_text]
    // [1200] phi display_action_text::info_text#25 = main::info_text29 [phi:main::@41->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text29
    sta.z display_action_text.info_text
    lda #>info_text29
    sta.z display_action_text.info_text+1
    jsr display_action_text
    jmp bank_set_brom7
    // main::@40
  __b40:
    // display_info_rom(rom_chip, STATUS_SKIP, "Cancelled")
    // [538] display_info_rom::rom_chip#9 = main::rom_chip2#2 -- vbum1=vbum2 
    lda rom_chip2
    sta display_info_rom.rom_chip
    // [539] call display_info_rom
    // [1368] phi from main::@40 to display_info_rom [phi:main::@40->display_info_rom]
    // [1368] phi display_info_rom::info_text#16 = main::info_text26 [phi:main::@40->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text26
    sta.z display_info_rom.info_text
    lda #>info_text26
    sta.z display_info_rom.info_text+1
    // [1368] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#9 [phi:main::@40->display_info_rom#1] -- register_copy 
    // [1368] phi display_info_rom::info_status#16 = STATUS_SKIP [phi:main::@40->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_rom.info_status
    jsr display_info_rom
    // main::@184
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [540] main::rom_chip2#1 = ++ main::rom_chip2#2 -- vbum1=_inc_vbum1 
    inc rom_chip2
    // [534] phi from main::@184 to main::@39 [phi:main::@184->main::@39]
    // [534] phi main::rom_chip2#2 = main::rom_chip2#1 [phi:main::@184->main::@39#0] -- register_copy 
    jmp __b39
    // [541] phi from main::@255 to main::@15 [phi:main::@255->main::@15]
    // main::@15
  __b15:
    // display_action_progress("The CX16 ROM and ROM.BIN versions are equal, no flash required!")
    // [542] call display_action_progress
    // [1155] phi from main::@15 to display_action_progress [phi:main::@15->display_action_progress]
    // [1155] phi display_action_progress::info_text#30 = main::info_text23 [phi:main::@15->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text23
    sta.z display_action_progress.info_text
    lda #>info_text23
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [543] phi from main::@15 to main::@177 [phi:main::@15->main::@177]
    // main::@177
    // util_wait_space()
    // [544] call util_wait_space
    // [1958] phi from main::@177 to util_wait_space [phi:main::@177->util_wait_space]
    jsr util_wait_space
    // [545] phi from main::@177 to main::@178 [phi:main::@177->main::@178]
    // main::@178
    // display_info_cx16_rom(STATUS_SKIP, NULL)
    // [546] call display_info_cx16_rom
    // [1961] phi from main::@178 to display_info_cx16_rom [phi:main::@178->display_info_cx16_rom]
    // [1961] phi display_info_cx16_rom::info_text#8 = 0 [phi:main::@178->display_info_cx16_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_cx16_rom.info_text
    sta.z display_info_cx16_rom.info_text+1
    // [1961] phi display_info_cx16_rom::info_status#8 = STATUS_SKIP [phi:main::@178->display_info_cx16_rom#1] -- vbuxx=vbuc1 
    ldx #STATUS_SKIP
    jsr display_info_cx16_rom
    jmp check_status_smc8
    // main::@253
  __b253:
    // if(check_status_smc(STATUS_FLASH) && smc_release == smc_file_release && smc_major == smc_file_major && smc_minor == smc_file_minor)
    // [547] if(smc_major#419!=smc_file_major#310) goto main::check_status_cx16_rom5 -- vbum1_neq_vbum2_then_la1 
    lda smc_major
    cmp smc_file_major
    beq !check_status_cx16_rom5+
    jmp check_status_cx16_rom5
  !check_status_cx16_rom5:
    // main::@252
    // [548] if(smc_minor#418==smc_file_minor#310) goto main::@14 -- vbum1_eq_vbum2_then_la1 
    lda smc_minor
    cmp smc_file_minor
    beq __b14
    jmp check_status_cx16_rom5
    // [549] phi from main::@252 to main::@14 [phi:main::@252->main::@14]
    // main::@14
  __b14:
    // display_action_progress("The CX16 SMC and SMC.BIN versions are equal, no flash required!")
    // [550] call display_action_progress
    // [1155] phi from main::@14 to display_action_progress [phi:main::@14->display_action_progress]
    // [1155] phi display_action_progress::info_text#30 = main::info_text22 [phi:main::@14->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text22
    sta.z display_action_progress.info_text
    lda #>info_text22
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [551] phi from main::@14 to main::@173 [phi:main::@14->main::@173]
    // main::@173
    // util_wait_space()
    // [552] call util_wait_space
    // [1958] phi from main::@173 to util_wait_space [phi:main::@173->util_wait_space]
    jsr util_wait_space
    // main::@174
    // [553] smc_bootloader#589 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_SKIP, NULL)
    // [554] call display_info_smc
    // [925] phi from main::@174 to display_info_smc [phi:main::@174->display_info_smc]
    // [925] phi display_info_smc::info_text#24 = 0 [phi:main::@174->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [925] phi smc_bootloader#14 = smc_bootloader#589 [phi:main::@174->display_info_smc#1] -- register_copy 
    // [925] phi display_info_smc::info_status#24 = STATUS_SKIP [phi:main::@174->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp check_status_cx16_rom5
    // [555] phi from main::@250 to main::@12 [phi:main::@250->main::@12]
    // main::@12
  __b12:
    // display_action_progress("Compatibility between ROM.BIN and SMC.BIN can't be assured!")
    // [556] call display_action_progress
    // [1155] phi from main::@12 to display_action_progress [phi:main::@12->display_action_progress]
    // [1155] phi display_action_progress::info_text#30 = main::info_text20 [phi:main::@12->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text20
    sta.z display_action_progress.info_text
    lda #>info_text20
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [557] phi from main::@12 to main::@168 [phi:main::@12->main::@168]
    // main::@168
    // display_progress_text(display_smc_unsupported_rom_text, display_smc_unsupported_rom_count)
    // [558] call display_progress_text
    // [1169] phi from main::@168 to display_progress_text [phi:main::@168->display_progress_text]
    // [1169] phi display_progress_text::text#13 = display_smc_unsupported_rom_text [phi:main::@168->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_unsupported_rom_text
    sta.z display_progress_text.text
    lda #>display_smc_unsupported_rom_text
    sta.z display_progress_text.text+1
    // [1169] phi display_progress_text::lines#12 = display_smc_unsupported_rom_count [phi:main::@168->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_smc_unsupported_rom_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [559] phi from main::@168 to main::@169 [phi:main::@168->main::@169]
    // main::@169
    // unsigned char ch = util_wait_key("Proceed with the update? [Y/N]", "YN")
    // [560] call util_wait_key
    // [1896] phi from main::@169 to util_wait_key [phi:main::@169->util_wait_key]
    // [1896] phi util_wait_key::filter#16 = main::filter [phi:main::@169->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter
    sta.z util_wait_key.filter
    lda #>filter
    sta.z util_wait_key.filter+1
    // [1896] phi util_wait_key::info_text#6 = main::info_text7 [phi:main::@169->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z util_wait_key.info_text
    lda #>info_text7
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Proceed with the update? [Y/N]", "YN")
    // [561] util_wait_key::return#12 = util_wait_key::ch#4 -- vbuaa=vwum1 
    lda util_wait_key.ch
    // main::@170
    // [562] main::ch3#0 = util_wait_key::return#12
    // if(ch == 'N')
    // [563] if(main::ch3#0!='N') goto main::check_status_smc7 -- vbuaa_neq_vbuc1_then_la1 
    cmp #'N'
    beq !check_status_smc7+
    jmp check_status_smc7
  !check_status_smc7:
    // main::@13
    // [564] smc_bootloader#587 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ISSUE, NULL)
    // [565] call display_info_smc
  // Cancel flash
    // [925] phi from main::@13 to display_info_smc [phi:main::@13->display_info_smc]
    // [925] phi display_info_smc::info_text#24 = 0 [phi:main::@13->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [925] phi smc_bootloader#14 = smc_bootloader#587 [phi:main::@13->display_info_smc#1] -- register_copy 
    // [925] phi display_info_smc::info_status#24 = STATUS_ISSUE [phi:main::@13->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [566] phi from main::@13 to main::@171 [phi:main::@13->main::@171]
    // main::@171
    // display_info_cx16_rom(STATUS_ISSUE, NULL)
    // [567] call display_info_cx16_rom
    // [1961] phi from main::@171 to display_info_cx16_rom [phi:main::@171->display_info_cx16_rom]
    // [1961] phi display_info_cx16_rom::info_text#8 = 0 [phi:main::@171->display_info_cx16_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_cx16_rom.info_text
    sta.z display_info_cx16_rom.info_text+1
    // [1961] phi display_info_cx16_rom::info_status#8 = STATUS_ISSUE [phi:main::@171->display_info_cx16_rom#1] -- vbuxx=vbuc1 
    ldx #STATUS_ISSUE
    jsr display_info_cx16_rom
    jmp check_status_smc7
    // [568] phi from main::@249 to main::@9 [phi:main::@249->main::@9]
    // main::@9
  __b9:
    // display_action_progress("Issue with the CX16 ROM, check the issue ...")
    // [569] call display_action_progress
    // [1155] phi from main::@9 to display_action_progress [phi:main::@9->display_action_progress]
    // [1155] phi display_action_progress::info_text#30 = main::info_text13 [phi:main::@9->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text13
    sta.z display_action_progress.info_text
    lda #>info_text13
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [570] phi from main::@9 to main::@160 [phi:main::@9->main::@160]
    // main::@160
    // display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count)
    // [571] call display_progress_text
    // [1169] phi from main::@160 to display_progress_text [phi:main::@160->display_progress_text]
    // [1169] phi display_progress_text::text#13 = display_smc_rom_issue_text [phi:main::@160->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_rom_issue_text
    sta.z display_progress_text.text
    lda #>display_smc_rom_issue_text
    sta.z display_progress_text.text+1
    // [1169] phi display_progress_text::lines#12 = display_smc_rom_issue_count [phi:main::@160->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_smc_rom_issue_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // main::@161
    // [572] smc_bootloader#588 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_SKIP, "Issue with main CX16 ROM!")
    // [573] call display_info_smc
    // [925] phi from main::@161 to display_info_smc [phi:main::@161->display_info_smc]
    // [925] phi display_info_smc::info_text#24 = main::info_text14 [phi:main::@161->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text14
    sta.z display_info_smc.info_text
    lda #>info_text14
    sta.z display_info_smc.info_text+1
    // [925] phi smc_bootloader#14 = smc_bootloader#588 [phi:main::@161->display_info_smc#1] -- register_copy 
    // [925] phi display_info_smc::info_status#24 = STATUS_SKIP [phi:main::@161->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [574] phi from main::@161 to main::@162 [phi:main::@161->main::@162]
    // main::@162
    // display_info_cx16_rom(STATUS_ISSUE, NULL)
    // [575] call display_info_cx16_rom
    // [1961] phi from main::@162 to display_info_cx16_rom [phi:main::@162->display_info_cx16_rom]
    // [1961] phi display_info_cx16_rom::info_text#8 = 0 [phi:main::@162->display_info_cx16_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_cx16_rom.info_text
    sta.z display_info_cx16_rom.info_text+1
    // [1961] phi display_info_cx16_rom::info_status#8 = STATUS_ISSUE [phi:main::@162->display_info_cx16_rom#1] -- vbuxx=vbuc1 
    ldx #STATUS_ISSUE
    jsr display_info_cx16_rom
    // [576] phi from main::@162 to main::@163 [phi:main::@162->main::@163]
    // main::@163
    // unsigned char ch = util_wait_key("Proceed with the update? [Y/N]", "YN")
    // [577] call util_wait_key
    // [1896] phi from main::@163 to util_wait_key [phi:main::@163->util_wait_key]
    // [1896] phi util_wait_key::filter#16 = main::filter [phi:main::@163->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter
    sta.z util_wait_key.filter
    lda #>filter
    sta.z util_wait_key.filter+1
    // [1896] phi util_wait_key::info_text#6 = main::info_text7 [phi:main::@163->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z util_wait_key.info_text
    lda #>info_text7
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Proceed with the update? [Y/N]", "YN")
    // [578] util_wait_key::return#11 = util_wait_key::ch#4 -- vbuaa=vwum1 
    lda util_wait_key.ch
    // main::@164
    // [579] main::ch1#0 = util_wait_key::return#11
    // if(ch == 'Y')
    // [580] if(main::ch1#0!='Y') goto main::check_status_smc6 -- vbuaa_neq_vbuc1_then_la1 
    cmp #'Y'
    beq !check_status_smc6+
    jmp check_status_smc6
  !check_status_smc6:
    // main::@10
    // [581] smc_bootloader#582 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_FLASH, "")
    // [582] call display_info_smc
    // [925] phi from main::@10 to display_info_smc [phi:main::@10->display_info_smc]
    // [925] phi display_info_smc::info_text#24 = str [phi:main::@10->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z display_info_smc.info_text
    lda #>str
    sta.z display_info_smc.info_text+1
    // [925] phi smc_bootloader#14 = smc_bootloader#582 [phi:main::@10->display_info_smc#1] -- register_copy 
    // [925] phi display_info_smc::info_status#24 = STATUS_FLASH [phi:main::@10->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASH
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [583] phi from main::@10 to main::@165 [phi:main::@10->main::@165]
    // main::@165
    // display_info_cx16_rom(STATUS_SKIP, "")
    // [584] call display_info_cx16_rom
    // [1961] phi from main::@165 to display_info_cx16_rom [phi:main::@165->display_info_cx16_rom]
    // [1961] phi display_info_cx16_rom::info_text#8 = str [phi:main::@165->display_info_cx16_rom#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z display_info_cx16_rom.info_text
    lda #>str
    sta.z display_info_cx16_rom.info_text+1
    // [1961] phi display_info_cx16_rom::info_status#8 = STATUS_SKIP [phi:main::@165->display_info_cx16_rom#1] -- vbuxx=vbuc1 
    ldx #STATUS_SKIP
    jsr display_info_cx16_rom
    jmp check_status_smc6
    // [585] phi from main::@248 to main::@4 [phi:main::@248->main::@4]
    // main::@4
  __b4:
    // display_action_progress("Issue with the CX16 ROM: not detected! ...")
    // [586] call display_action_progress
    // [1155] phi from main::@4 to display_action_progress [phi:main::@4->display_action_progress]
    // [1155] phi display_action_progress::info_text#30 = main::info_text9 [phi:main::@4->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text9
    sta.z display_action_progress.info_text
    lda #>info_text9
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [587] phi from main::@4 to main::@155 [phi:main::@4->main::@155]
    // main::@155
    // display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count)
    // [588] call display_progress_text
    // [1169] phi from main::@155 to display_progress_text [phi:main::@155->display_progress_text]
    // [1169] phi display_progress_text::text#13 = display_smc_rom_issue_text [phi:main::@155->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_rom_issue_text
    sta.z display_progress_text.text
    lda #>display_smc_rom_issue_text
    sta.z display_progress_text.text+1
    // [1169] phi display_progress_text::lines#12 = display_smc_rom_issue_count [phi:main::@155->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_smc_rom_issue_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // main::@156
    // [589] smc_bootloader#586 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_SKIP, "Issue with CX16 ROM!")
    // [590] call display_info_smc
    // [925] phi from main::@156 to display_info_smc [phi:main::@156->display_info_smc]
    // [925] phi display_info_smc::info_text#24 = main::info_text10 [phi:main::@156->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text10
    sta.z display_info_smc.info_text
    lda #>info_text10
    sta.z display_info_smc.info_text+1
    // [925] phi smc_bootloader#14 = smc_bootloader#586 [phi:main::@156->display_info_smc#1] -- register_copy 
    // [925] phi display_info_smc::info_status#24 = STATUS_SKIP [phi:main::@156->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [591] phi from main::@156 to main::@157 [phi:main::@156->main::@157]
    // main::@157
    // display_info_cx16_rom(STATUS_ISSUE, "Are J1 jumper pins closed?")
    // [592] call display_info_cx16_rom
    // [1961] phi from main::@157 to display_info_cx16_rom [phi:main::@157->display_info_cx16_rom]
    // [1961] phi display_info_cx16_rom::info_text#8 = main::info_text11 [phi:main::@157->display_info_cx16_rom#0] -- pbuz1=pbuc1 
    lda #<info_text11
    sta.z display_info_cx16_rom.info_text
    lda #>info_text11
    sta.z display_info_cx16_rom.info_text+1
    // [1961] phi display_info_cx16_rom::info_status#8 = STATUS_ISSUE [phi:main::@157->display_info_cx16_rom#1] -- vbuxx=vbuc1 
    ldx #STATUS_ISSUE
    jsr display_info_cx16_rom
    // [593] phi from main::@157 to main::@158 [phi:main::@157->main::@158]
    // main::@158
    // unsigned char ch = util_wait_key("Proceed with the update? [Y/N]", "YN")
    // [594] call util_wait_key
    // [1896] phi from main::@158 to util_wait_key [phi:main::@158->util_wait_key]
    // [1896] phi util_wait_key::filter#16 = main::filter [phi:main::@158->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter
    sta.z util_wait_key.filter
    lda #>filter
    sta.z util_wait_key.filter+1
    // [1896] phi util_wait_key::info_text#6 = main::info_text7 [phi:main::@158->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z util_wait_key.info_text
    lda #>info_text7
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Proceed with the update? [Y/N]", "YN")
    // [595] util_wait_key::return#10 = util_wait_key::ch#4 -- vbuaa=vwum1 
    lda util_wait_key.ch
    // main::@159
    // [596] main::ch2#0 = util_wait_key::return#10
    // if(ch == 'Y')
    // [597] if(main::ch2#0!='Y') goto main::check_status_smc6 -- vbuaa_neq_vbuc1_then_la1 
    cmp #'Y'
    beq !check_status_smc6+
    jmp check_status_smc6
  !check_status_smc6:
    // main::@11
    // [598] smc_bootloader#583 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_FLASH, "")
    // [599] call display_info_smc
    // [925] phi from main::@11 to display_info_smc [phi:main::@11->display_info_smc]
    // [925] phi display_info_smc::info_text#24 = str [phi:main::@11->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z display_info_smc.info_text
    lda #>str
    sta.z display_info_smc.info_text+1
    // [925] phi smc_bootloader#14 = smc_bootloader#583 [phi:main::@11->display_info_smc#1] -- register_copy 
    // [925] phi display_info_smc::info_status#24 = STATUS_FLASH [phi:main::@11->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASH
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [600] phi from main::@11 to main::@167 [phi:main::@11->main::@167]
    // main::@167
    // display_info_cx16_rom(STATUS_SKIP, "")
    // [601] call display_info_cx16_rom
    // [1961] phi from main::@167 to display_info_cx16_rom [phi:main::@167->display_info_cx16_rom]
    // [1961] phi display_info_cx16_rom::info_text#8 = str [phi:main::@167->display_info_cx16_rom#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z display_info_cx16_rom.info_text
    lda #>str
    sta.z display_info_cx16_rom.info_text+1
    // [1961] phi display_info_cx16_rom::info_status#8 = STATUS_SKIP [phi:main::@167->display_info_cx16_rom#1] -- vbuxx=vbuc1 
    ldx #STATUS_SKIP
    jsr display_info_cx16_rom
    jmp check_status_smc6
    // [602] phi from main::@247 to main::@37 [phi:main::@247->main::@37]
    // main::@37
  __b37:
    // display_action_progress("Issue with the CX16 SMC, check the issue ...")
    // [603] call display_action_progress
    // [1155] phi from main::@37 to display_action_progress [phi:main::@37->display_action_progress]
    // [1155] phi display_action_progress::info_text#30 = main::info_text5 [phi:main::@37->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z display_action_progress.info_text
    lda #>info_text5
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [604] phi from main::@37 to main::@149 [phi:main::@37->main::@149]
    // main::@149
    // display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count)
    // [605] call display_progress_text
    // [1169] phi from main::@149 to display_progress_text [phi:main::@149->display_progress_text]
    // [1169] phi display_progress_text::text#13 = display_smc_rom_issue_text [phi:main::@149->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_rom_issue_text
    sta.z display_progress_text.text
    lda #>display_smc_rom_issue_text
    sta.z display_progress_text.text+1
    // [1169] phi display_progress_text::lines#12 = display_smc_rom_issue_count [phi:main::@149->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_smc_rom_issue_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [606] phi from main::@149 to main::@150 [phi:main::@149->main::@150]
    // main::@150
    // display_info_cx16_rom(STATUS_SKIP, "Issue with SMC!")
    // [607] call display_info_cx16_rom
    // [1961] phi from main::@150 to display_info_cx16_rom [phi:main::@150->display_info_cx16_rom]
    // [1961] phi display_info_cx16_rom::info_text#8 = main::info_text6 [phi:main::@150->display_info_cx16_rom#0] -- pbuz1=pbuc1 
    lda #<info_text6
    sta.z display_info_cx16_rom.info_text
    lda #>info_text6
    sta.z display_info_cx16_rom.info_text+1
    // [1961] phi display_info_cx16_rom::info_status#8 = STATUS_SKIP [phi:main::@150->display_info_cx16_rom#1] -- vbuxx=vbuc1 
    ldx #STATUS_SKIP
    jsr display_info_cx16_rom
    // main::@151
    // [608] smc_bootloader#584 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ISSUE, NULL)
    // [609] call display_info_smc
    // [925] phi from main::@151 to display_info_smc [phi:main::@151->display_info_smc]
    // [925] phi display_info_smc::info_text#24 = 0 [phi:main::@151->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [925] phi smc_bootloader#14 = smc_bootloader#584 [phi:main::@151->display_info_smc#1] -- register_copy 
    // [925] phi display_info_smc::info_status#24 = STATUS_ISSUE [phi:main::@151->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [610] phi from main::@151 to main::@152 [phi:main::@151->main::@152]
    // main::@152
    // unsigned char ch = util_wait_key("Proceed with the update? [Y/N]", "YN")
    // [611] call util_wait_key
    // [1896] phi from main::@152 to util_wait_key [phi:main::@152->util_wait_key]
    // [1896] phi util_wait_key::filter#16 = main::filter [phi:main::@152->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter
    sta.z util_wait_key.filter
    lda #>filter
    sta.z util_wait_key.filter+1
    // [1896] phi util_wait_key::info_text#6 = main::info_text7 [phi:main::@152->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z util_wait_key.info_text
    lda #>info_text7
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Proceed with the update? [Y/N]", "YN")
    // [612] util_wait_key::return#3 = util_wait_key::ch#4 -- vbuaa=vwum1 
    lda util_wait_key.ch
    // main::@153
    // [613] main::ch#0 = util_wait_key::return#3
    // if(ch == 'Y')
    // [614] if(main::ch#0!='Y') goto main::check_status_smc4 -- vbuaa_neq_vbuc1_then_la1 
    cmp #'Y'
    beq !check_status_smc4+
    jmp check_status_smc4
  !check_status_smc4:
    // [615] phi from main::@153 to main::@38 [phi:main::@153->main::@38]
    // main::@38
    // display_info_cx16_rom(STATUS_FLASH, "")
    // [616] call display_info_cx16_rom
    // [1961] phi from main::@38 to display_info_cx16_rom [phi:main::@38->display_info_cx16_rom]
    // [1961] phi display_info_cx16_rom::info_text#8 = str [phi:main::@38->display_info_cx16_rom#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z display_info_cx16_rom.info_text
    lda #>str
    sta.z display_info_cx16_rom.info_text+1
    // [1961] phi display_info_cx16_rom::info_status#8 = STATUS_FLASH [phi:main::@38->display_info_cx16_rom#1] -- vbuxx=vbuc1 
    ldx #STATUS_FLASH
    jsr display_info_cx16_rom
    // main::@154
    // [617] smc_bootloader#585 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_SKIP, NULL)
    // [618] call display_info_smc
    // [925] phi from main::@154 to display_info_smc [phi:main::@154->display_info_smc]
    // [925] phi display_info_smc::info_text#24 = 0 [phi:main::@154->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [925] phi smc_bootloader#14 = smc_bootloader#585 [phi:main::@154->display_info_smc#1] -- register_copy 
    // [925] phi display_info_smc::info_status#24 = STATUS_SKIP [phi:main::@154->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp check_status_smc4
    // main::bank_set_brom6
  bank_set_brom6:
    // BROM = bank
    // [619] BROM = main::bank_set_brom6_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom6_bank
    sta.z BROM
    // main::@73
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [620] if(rom_device_ids[main::rom_chip1#10]==$55) goto main::@31 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    ldy rom_chip1
    lda rom_device_ids,y
    cmp #$55
    bne !__b31+
    jmp __b31
  !__b31:
    // [621] phi from main::@73 to main::@34 [phi:main::@73->main::@34]
    // main::@34
    // display_progress_clear()
    // [622] call display_progress_clear
    // [1037] phi from main::@34 to display_progress_clear [phi:main::@34->display_progress_clear]
    jsr display_progress_clear
    // main::@127
    // unsigned char rom_bank = rom_chip * 32
    // [623] main::rom_bank#0 = main::rom_chip1#10 << 5 -- vbum1=vbum2_rol_5 
    lda rom_chip1
    asl
    asl
    asl
    asl
    asl
    sta rom_bank
    // unsigned char* file = rom_file(rom_chip)
    // [624] rom_file::rom_chip#0 = main::rom_chip1#10 -- vbuaa=vbum1 
    lda rom_chip1
    // [625] call rom_file
    // [1413] phi from main::@127 to rom_file [phi:main::@127->rom_file]
    // [1413] phi rom_file::rom_chip#2 = rom_file::rom_chip#0 [phi:main::@127->rom_file#0] -- register_copy 
    jsr rom_file
    // unsigned char* file = rom_file(rom_chip)
    // [626] rom_file::return#4 = rom_file::return#2
    // main::@128
    // [627] main::file#0 = rom_file::return#4 -- pbum1=pbum2 
    lda rom_file.return
    sta file
    lda rom_file.return+1
    sta file+1
    // sprintf(info_text, "Checking %s ...", file)
    // [628] call snprintf_init
    // [1184] phi from main::@128 to snprintf_init [phi:main::@128->snprintf_init]
    // [1184] phi snprintf_init::s#30 = info_text [phi:main::@128->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [629] phi from main::@128 to main::@129 [phi:main::@128->main::@129]
    // main::@129
    // sprintf(info_text, "Checking %s ...", file)
    // [630] call printf_str
    // [1125] phi from main::@129 to printf_str [phi:main::@129->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:main::@129->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = main::s3 [phi:main::@129->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // main::@130
    // sprintf(info_text, "Checking %s ...", file)
    // [631] printf_string::str#20 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [632] call printf_string
    // [1419] phi from main::@130 to printf_string [phi:main::@130->printf_string]
    // [1419] phi printf_string::putc#26 = &snputc [phi:main::@130->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1419] phi printf_string::str#26 = printf_string::str#20 [phi:main::@130->printf_string#1] -- register_copy 
    // [1419] phi printf_string::format_justify_left#26 = 0 [phi:main::@130->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1419] phi printf_string::format_min_length#26 = 0 [phi:main::@130->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [633] phi from main::@130 to main::@131 [phi:main::@130->main::@131]
    // main::@131
    // sprintf(info_text, "Checking %s ...", file)
    // [634] call printf_str
    // [1125] phi from main::@131 to printf_str [phi:main::@131->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:main::@131->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = s4 [phi:main::@131->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // main::@132
    // sprintf(info_text, "Checking %s ...", file)
    // [635] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [636] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_progress(info_text)
    // [638] call display_action_progress
    // [1155] phi from main::@132 to display_action_progress [phi:main::@132->display_action_progress]
    // [1155] phi display_action_progress::info_text#30 = info_text [phi:main::@132->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_progress.info_text
    lda #>@info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@133
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_CHECKING, rom_bank, rom_sizes[rom_chip])
    // [639] main::$324 = main::rom_chip1#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip1
    asl
    asl
    sta main__324
    // [640] rom_read::rom_chip#0 = main::rom_chip1#10 -- vbum1=vbum2 
    lda rom_chip1
    sta rom_read.rom_chip
    // [641] rom_read::file#0 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z rom_read.file
    lda file+1
    sta.z rom_read.file+1
    // [642] rom_read::brom_bank_start#1 = main::rom_bank#0 -- vbuz1=vbum2 
    lda rom_bank
    sta.z rom_read.brom_bank_start
    // [643] rom_read::rom_size#0 = rom_sizes[main::$324] -- vduz1=pduc1_derefidx_vbum2 
    ldy main__324
    lda rom_sizes,y
    sta.z rom_read.rom_size
    lda rom_sizes+1,y
    sta.z rom_read.rom_size+1
    lda rom_sizes+2,y
    sta.z rom_read.rom_size+2
    lda rom_sizes+3,y
    sta.z rom_read.rom_size+3
    // [644] call rom_read
  // Read the ROM(n).BIN file.
    // [1444] phi from main::@133 to rom_read [phi:main::@133->rom_read]
    // [1444] phi rom_read::rom_chip#20 = rom_read::rom_chip#0 [phi:main::@133->rom_read#0] -- register_copy 
    // [1444] phi rom_read::rom_size#12 = rom_read::rom_size#0 [phi:main::@133->rom_read#1] -- register_copy 
    // [1444] phi __errno#103 = __errno#115 [phi:main::@133->rom_read#2] -- register_copy 
    // [1444] phi __stdio_filecount#126 = __stdio_filecount#111 [phi:main::@133->rom_read#3] -- register_copy 
    // [1444] phi rom_read::file#10 = rom_read::file#0 [phi:main::@133->rom_read#4] -- register_copy 
    // [1444] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#1 [phi:main::@133->rom_read#5] -- register_copy 
    // [1444] phi rom_read::info_status#11 = STATUS_CHECKING [phi:main::@133->rom_read#6] -- vbuz1=vbuc1 
    lda #STATUS_CHECKING
    sta.z rom_read.info_status
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_CHECKING, rom_bank, rom_sizes[rom_chip])
    // [645] rom_read::return#2 = rom_read::return#0
    // main::@134
    // [646] main::rom_bytes_read#0 = rom_read::return#2
    // if (!rom_bytes_read)
    // [647] if(0==main::rom_bytes_read#0) goto main::@32 -- 0_eq_vdum1_then_la1 
    // In case no file was found, set the status to none and skip to the next, else, mention the amount of bytes read.
    lda rom_bytes_read
    ora rom_bytes_read+1
    ora rom_bytes_read+2
    ora rom_bytes_read+3
    bne !__b32+
    jmp __b32
  !__b32:
    // main::@35
    // unsigned long rom_file_modulo = rom_bytes_read % 0x4000
    // [648] main::rom_file_modulo#0 = main::rom_bytes_read#0 & $4000-1 -- vdum1=vdum2_band_vduc1 
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
    // [649] if(0!=main::rom_file_modulo#0) goto main::@33 -- 0_neq_vdum1_then_la1 
    lda rom_file_modulo
    ora rom_file_modulo+1
    ora rom_file_modulo+2
    ora rom_file_modulo+3
    beq !__b33+
    jmp __b33
  !__b33:
    // main::@36
    // file_sizes[rom_chip] = rom_bytes_read
    // [650] file_sizes[main::$324] = main::rom_bytes_read#0 -- pduc1_derefidx_vbum1=vdum2 
    // RF5 | ROM.BIN all ok | Display the ROM.BIN release version and github commit id (if any) and set ROM to Flash | Flash
    // We know the file size, so we indicate it in the status panel.
    ldy main__324
    lda rom_bytes_read
    sta file_sizes,y
    lda rom_bytes_read+1
    sta file_sizes+1,y
    lda rom_bytes_read+2
    sta file_sizes+2,y
    lda rom_bytes_read+3
    sta file_sizes+3,y
    // 8*rom_chip
    // [651] main::$132 = main::rom_chip1#10 << 3 -- vbuaa=vbum1_rol_3 
    lda rom_chip1
    asl
    asl
    asl
    // unsigned char* rom_file_github_id = &rom_file_github[8*rom_chip]
    // [652] main::rom_file_github_id#0 = rom_file_github + main::$132 -- pbuz1=pbuc1_plus_vbuaa 
    // Fill the version data ...
    clc
    adc #<rom_file_github
    sta.z rom_file_github_id
    lda #>rom_file_github
    adc #0
    sta.z rom_file_github_id+1
    // unsigned char rom_file_release_id = rom_get_release(rom_file_release[rom_chip])
    // [653] rom_get_release::release#2 = rom_file_release[main::rom_chip1#10] -- vbuxx=pbuc1_derefidx_vbum1 
    ldy rom_chip1
    ldx rom_file_release,y
    // [654] call rom_get_release
    // [1966] phi from main::@36 to rom_get_release [phi:main::@36->rom_get_release]
    // [1966] phi rom_get_release::release#3 = rom_get_release::release#2 [phi:main::@36->rom_get_release#0] -- register_copy 
    jsr rom_get_release
    // unsigned char rom_file_release_id = rom_get_release(rom_file_release[rom_chip])
    // [655] rom_get_release::return#3 = rom_get_release::return#0
    // main::@142
    // [656] main::rom_file_release_id#0 = rom_get_release::return#3 -- vbuz1=vbuxx 
    stx.z rom_file_release_id
    // unsigned char rom_file_prefix_id = rom_get_prefix(rom_file_release[rom_chip])
    // [657] rom_get_prefix::release#1 = rom_file_release[main::rom_chip1#10] -- vbuaa=pbuc1_derefidx_vbum1 
    ldy rom_chip1
    lda rom_file_release,y
    // [658] call rom_get_prefix
    // [1973] phi from main::@142 to rom_get_prefix [phi:main::@142->rom_get_prefix]
    // [1973] phi rom_get_prefix::release#2 = rom_get_prefix::release#1 [phi:main::@142->rom_get_prefix#0] -- register_copy 
    jsr rom_get_prefix
    // unsigned char rom_file_prefix_id = rom_get_prefix(rom_file_release[rom_chip])
    // [659] rom_get_prefix::return#3 = rom_get_prefix::return#0 -- vbuaa=vbuxx 
    txa
    // main::@143
    // [660] main::rom_file_prefix_id#0 = rom_get_prefix::return#3
    // rom_get_version_text(rom_file_release_text, rom_file_prefix_id, rom_file_release_id, rom_file_github_id)
    // [661] rom_get_version_text::prefix#1 = main::rom_file_prefix_id#0 -- vbuxx=vbuaa 
    tax
    // [662] rom_get_version_text::release#1 = main::rom_file_release_id#0
    // [663] rom_get_version_text::github#1 = main::rom_file_github_id#0
    // [664] call rom_get_version_text
    // [1982] phi from main::@143 to rom_get_version_text [phi:main::@143->rom_get_version_text]
    // [1982] phi rom_get_version_text::github#2 = rom_get_version_text::github#1 [phi:main::@143->rom_get_version_text#0] -- register_copy 
    // [1982] phi rom_get_version_text::release#2 = rom_get_version_text::release#1 [phi:main::@143->rom_get_version_text#1] -- register_copy 
    // [1982] phi rom_get_version_text::prefix#2 = rom_get_version_text::prefix#1 [phi:main::@143->rom_get_version_text#2] -- register_copy 
    // [1982] phi rom_get_version_text::release_info#2 = main::rom_file_release_text [phi:main::@143->rom_get_version_text#3] -- pbuz1=pbuc1 
    lda #<rom_file_release_text
    sta.z rom_get_version_text.release_info
    lda #>rom_file_release_text
    sta.z rom_get_version_text.release_info+1
    jsr rom_get_version_text
    // [665] phi from main::@143 to main::@144 [phi:main::@143->main::@144]
    // main::@144
    // sprintf(info_text, "%s:%s", file, rom_file_release_text)
    // [666] call snprintf_init
    // [1184] phi from main::@144 to snprintf_init [phi:main::@144->snprintf_init]
    // [1184] phi snprintf_init::s#30 = info_text [phi:main::@144->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main::@145
    // sprintf(info_text, "%s:%s", file, rom_file_release_text)
    // [667] printf_string::str#23 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [668] call printf_string
    // [1419] phi from main::@145 to printf_string [phi:main::@145->printf_string]
    // [1419] phi printf_string::putc#26 = &snputc [phi:main::@145->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1419] phi printf_string::str#26 = printf_string::str#23 [phi:main::@145->printf_string#1] -- register_copy 
    // [1419] phi printf_string::format_justify_left#26 = 0 [phi:main::@145->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1419] phi printf_string::format_min_length#26 = 0 [phi:main::@145->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [669] phi from main::@145 to main::@146 [phi:main::@145->main::@146]
    // main::@146
    // sprintf(info_text, "%s:%s", file, rom_file_release_text)
    // [670] call printf_str
    // [1125] phi from main::@146 to printf_str [phi:main::@146->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:main::@146->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = s2 [phi:main::@146->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s2
    sta.z printf_str.s
    lda #>@s2
    sta.z printf_str.s+1
    jsr printf_str
    // [671] phi from main::@146 to main::@147 [phi:main::@146->main::@147]
    // main::@147
    // sprintf(info_text, "%s:%s", file, rom_file_release_text)
    // [672] call printf_string
    // [1419] phi from main::@147 to printf_string [phi:main::@147->printf_string]
    // [1419] phi printf_string::putc#26 = &snputc [phi:main::@147->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1419] phi printf_string::str#26 = main::rom_file_release_text [phi:main::@147->printf_string#1] -- pbuz1=pbuc1 
    lda #<rom_file_release_text
    sta.z printf_string.str
    lda #>rom_file_release_text
    sta.z printf_string.str+1
    // [1419] phi printf_string::format_justify_left#26 = 0 [phi:main::@147->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1419] phi printf_string::format_min_length#26 = 0 [phi:main::@147->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // main::@148
    // sprintf(info_text, "%s:%s", file, rom_file_release_text)
    // [673] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [674] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASH, info_text)
    // [676] display_info_rom::rom_chip#8 = main::rom_chip1#10 -- vbum1=vbum2 
    lda rom_chip1
    sta display_info_rom.rom_chip
    // [677] call display_info_rom
    // [1368] phi from main::@148 to display_info_rom [phi:main::@148->display_info_rom]
    // [1368] phi display_info_rom::info_text#16 = info_text [phi:main::@148->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1368] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#8 [phi:main::@148->display_info_rom#1] -- register_copy 
    // [1368] phi display_info_rom::info_status#16 = STATUS_FLASH [phi:main::@148->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_rom.info_status
    jsr display_info_rom
    // [678] phi from main::@137 main::@141 main::@148 main::@73 to main::@31 [phi:main::@137/main::@141/main::@148/main::@73->main::@31]
    // [678] phi __stdio_filecount#412 = __stdio_filecount#39 [phi:main::@137/main::@141/main::@148/main::@73->main::@31#0] -- register_copy 
    // [678] phi __errno#397 = __errno#123 [phi:main::@137/main::@141/main::@148/main::@73->main::@31#1] -- register_copy 
    // main::@31
  __b31:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [679] main::rom_chip1#1 = ++ main::rom_chip1#10 -- vbum1=_inc_vbum1 
    inc rom_chip1
    // [133] phi from main::@31 to main::@30 [phi:main::@31->main::@30]
    // [133] phi __stdio_filecount#111 = __stdio_filecount#412 [phi:main::@31->main::@30#0] -- register_copy 
    // [133] phi __errno#115 = __errno#397 [phi:main::@31->main::@30#1] -- register_copy 
    // [133] phi main::rom_chip1#10 = main::rom_chip1#1 [phi:main::@31->main::@30#2] -- register_copy 
    jmp __b30
    // [680] phi from main::@35 to main::@33 [phi:main::@35->main::@33]
    // main::@33
  __b33:
    // sprintf(info_text, "File %s size error!", file)
    // [681] call snprintf_init
    // [1184] phi from main::@33 to snprintf_init [phi:main::@33->snprintf_init]
    // [1184] phi snprintf_init::s#30 = info_text [phi:main::@33->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [682] phi from main::@33 to main::@138 [phi:main::@33->main::@138]
    // main::@138
    // sprintf(info_text, "File %s size error!", file)
    // [683] call printf_str
    // [1125] phi from main::@138 to printf_str [phi:main::@138->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:main::@138->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = main::s6 [phi:main::@138->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // main::@139
    // sprintf(info_text, "File %s size error!", file)
    // [684] printf_string::str#22 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [685] call printf_string
    // [1419] phi from main::@139 to printf_string [phi:main::@139->printf_string]
    // [1419] phi printf_string::putc#26 = &snputc [phi:main::@139->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1419] phi printf_string::str#26 = printf_string::str#22 [phi:main::@139->printf_string#1] -- register_copy 
    // [1419] phi printf_string::format_justify_left#26 = 0 [phi:main::@139->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1419] phi printf_string::format_min_length#26 = 0 [phi:main::@139->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [686] phi from main::@139 to main::@140 [phi:main::@139->main::@140]
    // main::@140
    // sprintf(info_text, "File %s size error!", file)
    // [687] call printf_str
    // [1125] phi from main::@140 to printf_str [phi:main::@140->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:main::@140->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = main::s7 [phi:main::@140->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@141
    // sprintf(info_text, "File %s size error!", file)
    // [688] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [689] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_ISSUE, info_text)
    // [691] display_info_rom::rom_chip#7 = main::rom_chip1#10 -- vbum1=vbum2 
    lda rom_chip1
    sta display_info_rom.rom_chip
    // [692] call display_info_rom
    // [1368] phi from main::@141 to display_info_rom [phi:main::@141->display_info_rom]
    // [1368] phi display_info_rom::info_text#16 = info_text [phi:main::@141->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1368] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#7 [phi:main::@141->display_info_rom#1] -- register_copy 
    // [1368] phi display_info_rom::info_status#16 = STATUS_ISSUE [phi:main::@141->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b31
    // [693] phi from main::@134 to main::@32 [phi:main::@134->main::@32]
    // main::@32
  __b32:
    // sprintf(info_text, "No %s", file)
    // [694] call snprintf_init
    // [1184] phi from main::@32 to snprintf_init [phi:main::@32->snprintf_init]
    // [1184] phi snprintf_init::s#30 = info_text [phi:main::@32->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [695] phi from main::@32 to main::@135 [phi:main::@32->main::@135]
    // main::@135
    // sprintf(info_text, "No %s", file)
    // [696] call printf_str
    // [1125] phi from main::@135 to printf_str [phi:main::@135->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:main::@135->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = main::s5 [phi:main::@135->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // main::@136
    // sprintf(info_text, "No %s", file)
    // [697] printf_string::str#21 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [698] call printf_string
    // [1419] phi from main::@136 to printf_string [phi:main::@136->printf_string]
    // [1419] phi printf_string::putc#26 = &snputc [phi:main::@136->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1419] phi printf_string::str#26 = printf_string::str#21 [phi:main::@136->printf_string#1] -- register_copy 
    // [1419] phi printf_string::format_justify_left#26 = 0 [phi:main::@136->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1419] phi printf_string::format_min_length#26 = 0 [phi:main::@136->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // main::@137
    // sprintf(info_text, "No %s", file)
    // [699] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [700] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_SKIP, info_text)
    // [702] display_info_rom::rom_chip#6 = main::rom_chip1#10 -- vbum1=vbum2 
    lda rom_chip1
    sta display_info_rom.rom_chip
    // [703] call display_info_rom
    // [1368] phi from main::@137 to display_info_rom [phi:main::@137->display_info_rom]
    // [1368] phi display_info_rom::info_text#16 = info_text [phi:main::@137->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1368] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#6 [phi:main::@137->display_info_rom#1] -- register_copy 
    // [1368] phi display_info_rom::info_status#16 = STATUS_SKIP [phi:main::@137->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b31
    // [704] phi from main::@246 main::@70 to main::@25 [phi:main::@246/main::@70->main::@25]
    // main::@25
  __b25:
    // display_action_progress("Checking SMC.BIN ...")
    // [705] call display_action_progress
    // [1155] phi from main::@25 to display_action_progress [phi:main::@25->display_action_progress]
    // [1155] phi display_action_progress::info_text#30 = main::info_text2 [phi:main::@25->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z display_action_progress.info_text
    lda #>info_text2
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [706] phi from main::@25 to main::@121 [phi:main::@25->main::@121]
    // main::@121
    // smc_read(STATUS_CHECKING)
    // [707] call smc_read
    // [1691] phi from main::@121 to smc_read [phi:main::@121->smc_read]
    // [1691] phi __errno#100 = 0 [phi:main::@121->smc_read#0] -- vwsm1=vwsc1 
    lda #<0
    sta __errno
    sta __errno+1
    // [1691] phi __stdio_filecount#123 = 0 [phi:main::@121->smc_read#1] -- vbum1=vbuc1 
    sta __stdio_filecount
    // [1691] phi smc_read::info_status#10 = STATUS_CHECKING [phi:main::@121->smc_read#2] -- vbum1=vbuc1 
    lda #STATUS_CHECKING
    sta smc_read.info_status
    jsr smc_read
    // smc_read(STATUS_CHECKING)
    // [708] smc_read::return#2 = smc_read::return#0
    // main::@122
    // smc_file_size = smc_read(STATUS_CHECKING)
    // [709] smc_file_size#0 = smc_read::return#2 -- vwum1=vwuz2 
    lda.z smc_read.return
    sta smc_file_size
    lda.z smc_read.return+1
    sta smc_file_size+1
    // if (!smc_file_size)
    // [710] if(0==smc_file_size#0) goto main::@28 -- 0_eq_vwum1_then_la1 
    lda smc_file_size
    ora smc_file_size+1
    bne !__b28+
    jmp __b28
  !__b28:
    // main::@26
    // if(smc_file_size > 0x1E00)
    // [711] if(smc_file_size#0>$1e00) goto main::@29 -- vwum1_gt_vwuc1_then_la1 
    lda #>$1e00
    cmp smc_file_size+1
    bcs !__b29+
    jmp __b29
  !__b29:
    bne !+
    lda #<$1e00
    cmp smc_file_size
    bcs !__b29+
    jmp __b29
  !__b29:
  !:
    // main::@27
    // smc_file_release = smc_file_header[0]
    // [712] smc_file_release#0 = *smc_file_header -- vbum1=_deref_pbuc1 
    // SF4 | SMC.BIN and all ok | Display the SMC.BIN file version and set SMC to Flash. | Flash
    // The first 3 bytes of the smc file header is the version of the SMC file.
    lda smc_file_header
    sta smc_file_release
    // smc_file_major = smc_file_header[1]
    // [713] smc_file_major#0 = *(smc_file_header+1) -- vbum1=_deref_pbuc1 
    lda smc_file_header+1
    sta smc_file_major
    // smc_file_minor = smc_file_header[2]
    // [714] smc_file_minor#0 = *(smc_file_header+2) -- vbum1=_deref_pbuc1 
    lda smc_file_header+2
    sta smc_file_minor
    // smc_get_version_text(smc_file_version_text, smc_file_release, smc_file_major, smc_file_minor)
    // [715] smc_get_version_text::release#1 = smc_file_release#0 -- vbuyy=vbum1 
    ldy smc_file_release
    // [716] smc_get_version_text::major#1 = smc_file_major#0 -- vbum1=vbum2 
    lda smc_file_major
    sta smc_get_version_text.major
    // [717] smc_get_version_text::minor#1 = smc_file_minor#0 -- vbuz1=vbum2 
    lda smc_file_minor
    sta.z smc_get_version_text.minor
    // [718] call smc_get_version_text
    // [908] phi from main::@27 to smc_get_version_text [phi:main::@27->smc_get_version_text]
    // [908] phi smc_get_version_text::minor#2 = smc_get_version_text::minor#1 [phi:main::@27->smc_get_version_text#0] -- register_copy 
    // [908] phi smc_get_version_text::major#2 = smc_get_version_text::major#1 [phi:main::@27->smc_get_version_text#1] -- register_copy 
    // [908] phi smc_get_version_text::release#2 = smc_get_version_text::release#1 [phi:main::@27->smc_get_version_text#2] -- register_copy 
    // [908] phi smc_get_version_text::version_string#2 = main::smc_file_version_text [phi:main::@27->smc_get_version_text#3] -- pbuz1=pbuc1 
    lda #<smc_file_version_text
    sta.z smc_get_version_text.version_string
    lda #>smc_file_version_text
    sta.z smc_get_version_text.version_string+1
    jsr smc_get_version_text
    // [719] phi from main::@27 to main::@123 [phi:main::@27->main::@123]
    // main::@123
    // sprintf(info_text, "SMC.BIN:%s", smc_file_version_text)
    // [720] call snprintf_init
    // [1184] phi from main::@123 to snprintf_init [phi:main::@123->snprintf_init]
    // [1184] phi snprintf_init::s#30 = info_text [phi:main::@123->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [721] phi from main::@123 to main::@124 [phi:main::@123->main::@124]
    // main::@124
    // sprintf(info_text, "SMC.BIN:%s", smc_file_version_text)
    // [722] call printf_str
    // [1125] phi from main::@124 to printf_str [phi:main::@124->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:main::@124->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = main::s2 [phi:main::@124->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // [723] phi from main::@124 to main::@125 [phi:main::@124->main::@125]
    // main::@125
    // sprintf(info_text, "SMC.BIN:%s", smc_file_version_text)
    // [724] call printf_string
    // [1419] phi from main::@125 to printf_string [phi:main::@125->printf_string]
    // [1419] phi printf_string::putc#26 = &snputc [phi:main::@125->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1419] phi printf_string::str#26 = main::smc_file_version_text [phi:main::@125->printf_string#1] -- pbuz1=pbuc1 
    lda #<smc_file_version_text
    sta.z printf_string.str
    lda #>smc_file_version_text
    sta.z printf_string.str+1
    // [1419] phi printf_string::format_justify_left#26 = 0 [phi:main::@125->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1419] phi printf_string::format_min_length#26 = 0 [phi:main::@125->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // main::@126
    // sprintf(info_text, "SMC.BIN:%s", smc_file_version_text)
    // [725] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [726] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [728] smc_bootloader#581 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_FLASH, info_text)
    // [729] call display_info_smc
  // All ok, display file version.
    // [925] phi from main::@126 to display_info_smc [phi:main::@126->display_info_smc]
    // [925] phi display_info_smc::info_text#24 = info_text [phi:main::@126->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_smc.info_text
    lda #>@info_text
    sta.z display_info_smc.info_text+1
    // [925] phi smc_bootloader#14 = smc_bootloader#581 [phi:main::@126->display_info_smc#1] -- register_copy 
    // [925] phi display_info_smc::info_status#24 = STATUS_FLASH [phi:main::@126->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASH
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [123] phi from main::@126 to main::@3 [phi:main::@126->main::@3]
    // [123] phi smc_file_minor#310 = smc_file_minor#0 [phi:main::@126->main::@3#0] -- register_copy 
    // [123] phi smc_file_major#310 = smc_file_major#0 [phi:main::@126->main::@3#1] -- register_copy 
    // [123] phi smc_file_release#310 = smc_file_release#0 [phi:main::@126->main::@3#2] -- register_copy 
    // [123] phi __stdio_filecount#109 = __stdio_filecount#36 [phi:main::@126->main::@3#3] -- register_copy 
    // [123] phi __errno#113 = __errno#123 [phi:main::@126->main::@3#4] -- register_copy 
    jmp __b3
    // main::@29
  __b29:
    // [730] smc_bootloader#594 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ISSUE, "SMC.BIN too large!")
    // [731] call display_info_smc
  // SF3 | size SMC.BIN is > 0x1E00 | Display SMC.BIN file size issue and don't flash. Ask the user to place a correct SMC.BIN file onto the SDcard. | Issue
    // [925] phi from main::@29 to display_info_smc [phi:main::@29->display_info_smc]
    // [925] phi display_info_smc::info_text#24 = main::info_text4 [phi:main::@29->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_info_smc.info_text
    lda #>info_text4
    sta.z display_info_smc.info_text+1
    // [925] phi smc_bootloader#14 = smc_bootloader#594 [phi:main::@29->display_info_smc#1] -- register_copy 
    // [925] phi display_info_smc::info_status#24 = STATUS_ISSUE [phi:main::@29->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [123] phi from main::@28 main::@29 to main::@3 [phi:main::@28/main::@29->main::@3]
  __b7:
    // [123] phi smc_file_minor#310 = 0 [phi:main::@28/main::@29->main::@3#0] -- vbum1=vbuc1 
    lda #0
    sta smc_file_minor
    // [123] phi smc_file_major#310 = 0 [phi:main::@28/main::@29->main::@3#1] -- vbum1=vbuc1 
    sta smc_file_major
    // [123] phi smc_file_release#310 = 0 [phi:main::@28/main::@29->main::@3#2] -- vbum1=vbuc1 
    sta smc_file_release
    // [123] phi __stdio_filecount#109 = __stdio_filecount#36 [phi:main::@28/main::@29->main::@3#3] -- register_copy 
    // [123] phi __errno#113 = __errno#123 [phi:main::@28/main::@29->main::@3#4] -- register_copy 
    jmp __b3
    // main::@28
  __b28:
    // [732] smc_bootloader#593 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_SKIP, "No SMC.BIN!")
    // [733] call display_info_smc
  // SF1 | no SMC.BIN | Ask user to place an SMC.BIN file onto the SDcard and don't flash. | Issue
  // SF2 | size SMC.BIN is 0 | Ask user to place an SMC.BIN file onto the SDcard and don't flash. | Issue
    // [925] phi from main::@28 to display_info_smc [phi:main::@28->display_info_smc]
    // [925] phi display_info_smc::info_text#24 = main::info_text3 [phi:main::@28->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text3
    sta.z display_info_smc.info_text
    lda #>info_text3
    sta.z display_info_smc.info_text+1
    // [925] phi smc_bootloader#14 = smc_bootloader#593 [phi:main::@28->display_info_smc#1] -- register_copy 
    // [925] phi display_info_smc::info_status#24 = STATUS_SKIP [phi:main::@28->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp __b7
    // main::@22
  __b22:
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [734] if(rom_device_ids[main::rom_chip#10]!=$55) goto main::@23 -- pbuc1_derefidx_vbum1_neq_vbuc2_then_la1 
    lda #$55
    ldy rom_chip
    cmp rom_device_ids,y
    bne __b23
    // main::@24
  __b24:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [735] main::rom_chip#1 = ++ main::rom_chip#10 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [113] phi from main::@24 to main::@21 [phi:main::@24->main::@21]
    // [113] phi main::rom_chip#10 = main::rom_chip#1 [phi:main::@24->main::@21#0] -- register_copy 
    jmp __b21
    // main::@23
  __b23:
    // bank_set_brom(rom_chip*32)
    // [736] main::bank_set_brom3_bank#0 = main::rom_chip#10 << 5 -- vbuaa=vbum1_rol_5 
    lda rom_chip
    asl
    asl
    asl
    asl
    asl
    // main::bank_set_brom3
    // BROM = bank
    // [737] BROM = main::bank_set_brom3_bank#0 -- vbuz1=vbuaa 
    sta.z BROM
    // main::@71
    // rom_chip*8
    // [738] main::$107 = main::rom_chip#10 << 3 -- vbum1=vbum2_rol_3 
    lda rom_chip
    asl
    asl
    asl
    sta main__107
    // rom_get_github_commit_id(&rom_github[rom_chip*8], (char*)0xC000)
    // [739] rom_get_github_commit_id::commit_id#1 = rom_github + main::$107 -- pbuz1=pbuc1_plus_vbum2 
    clc
    adc #<rom_github
    sta.z rom_get_github_commit_id.commit_id
    lda #>rom_github
    adc #0
    sta.z rom_get_github_commit_id.commit_id+1
    // [740] call rom_get_github_commit_id
    // [1998] phi from main::@71 to rom_get_github_commit_id [phi:main::@71->rom_get_github_commit_id]
    // [1998] phi rom_get_github_commit_id::commit_id#6 = rom_get_github_commit_id::commit_id#1 [phi:main::@71->rom_get_github_commit_id#0] -- register_copy 
    // [1998] phi rom_get_github_commit_id::from#6 = (char *) 49152 [phi:main::@71->rom_get_github_commit_id#1] -- pbuz1=pbuc1 
    lda #<$c000
    sta.z rom_get_github_commit_id.from
    lda #>$c000
    sta.z rom_get_github_commit_id.from+1
    jsr rom_get_github_commit_id
    // main::@116
    // rom_get_release(*((char*)0xFF80))
    // [741] rom_get_release::release#1 = *((char *) 65408) -- vbuxx=_deref_pbuc1 
    ldx $ff80
    // [742] call rom_get_release
    // [1966] phi from main::@116 to rom_get_release [phi:main::@116->rom_get_release]
    // [1966] phi rom_get_release::release#3 = rom_get_release::release#1 [phi:main::@116->rom_get_release#0] -- register_copy 
    jsr rom_get_release
    // rom_get_release(*((char*)0xFF80))
    // [743] rom_get_release::return#2 = rom_get_release::return#0
    // main::@117
    // [744] main::$103 = rom_get_release::return#2 -- vbuaa=vbuxx 
    txa
    // rom_release[rom_chip] = rom_get_release(*((char*)0xFF80))
    // [745] rom_release[main::rom_chip#10] = main::$103 -- pbuc1_derefidx_vbum1=vbuaa 
    ldy rom_chip
    sta rom_release,y
    // rom_get_prefix(*((char*)0xFF80))
    // [746] rom_get_prefix::release#0 = *((char *) 65408) -- vbuaa=_deref_pbuc1 
    lda $ff80
    // [747] call rom_get_prefix
    // [1973] phi from main::@117 to rom_get_prefix [phi:main::@117->rom_get_prefix]
    // [1973] phi rom_get_prefix::release#2 = rom_get_prefix::release#0 [phi:main::@117->rom_get_prefix#0] -- register_copy 
    jsr rom_get_prefix
    // rom_get_prefix(*((char*)0xFF80))
    // [748] rom_get_prefix::return#2 = rom_get_prefix::return#0
    // main::@118
    // [749] main::$104 = rom_get_prefix::return#2 -- vbuaa=vbuxx 
    txa
    // rom_prefix[rom_chip] = rom_get_prefix(*((char*)0xFF80))
    // [750] rom_prefix[main::rom_chip#10] = main::$104 -- pbuc1_derefidx_vbum1=vbuaa 
    ldy rom_chip
    sta rom_prefix,y
    // rom_chip*13
    // [751] main::$383 = main::rom_chip#10 << 1 -- vbuaa=vbum1_rol_1 
    tya
    asl
    // [752] main::$384 = main::$383 + main::rom_chip#10 -- vbuaa=vbuaa_plus_vbum1 
    clc
    adc rom_chip
    // [753] main::$385 = main::$384 << 2 -- vbuaa=vbuaa_rol_2 
    asl
    asl
    // [754] main::$105 = main::$385 + main::rom_chip#10 -- vbuaa=vbuaa_plus_vbum1 
    clc
    adc rom_chip
    // rom_get_version_text(&rom_release_text[rom_chip*13], rom_prefix[rom_chip], rom_release[rom_chip], &rom_github[rom_chip*8])
    // [755] rom_get_version_text::release_info#0 = rom_release_text + main::$105 -- pbuz1=pbuc1_plus_vbuaa 
    clc
    adc #<rom_release_text
    sta.z rom_get_version_text.release_info
    lda #>rom_release_text
    adc #0
    sta.z rom_get_version_text.release_info+1
    // [756] rom_get_version_text::github#0 = rom_github + main::$107 -- pbuz1=pbuc1_plus_vbum2 
    lda main__107
    clc
    adc #<rom_github
    sta.z rom_get_version_text.github
    lda #>rom_github
    adc #0
    sta.z rom_get_version_text.github+1
    // [757] rom_get_version_text::prefix#0 = rom_prefix[main::rom_chip#10] -- vbuxx=pbuc1_derefidx_vbum1 
    ldx rom_prefix,y
    // [758] rom_get_version_text::release#0 = rom_release[main::rom_chip#10] -- vbuz1=pbuc1_derefidx_vbum2 
    lda rom_release,y
    sta.z rom_get_version_text.release
    // [759] call rom_get_version_text
    // [1982] phi from main::@118 to rom_get_version_text [phi:main::@118->rom_get_version_text]
    // [1982] phi rom_get_version_text::github#2 = rom_get_version_text::github#0 [phi:main::@118->rom_get_version_text#0] -- register_copy 
    // [1982] phi rom_get_version_text::release#2 = rom_get_version_text::release#0 [phi:main::@118->rom_get_version_text#1] -- register_copy 
    // [1982] phi rom_get_version_text::prefix#2 = rom_get_version_text::prefix#0 [phi:main::@118->rom_get_version_text#2] -- register_copy 
    // [1982] phi rom_get_version_text::release_info#2 = rom_get_version_text::release_info#0 [phi:main::@118->rom_get_version_text#3] -- register_copy 
    jsr rom_get_version_text
    // main::@119
    // display_info_rom(rom_chip, STATUS_DETECTED, NULL)
    // [760] display_info_rom::rom_chip#5 = main::rom_chip#10 -- vbum1=vbum2 
    lda rom_chip
    sta display_info_rom.rom_chip
    // [761] call display_info_rom
    // [1368] phi from main::@119 to display_info_rom [phi:main::@119->display_info_rom]
    // [1368] phi display_info_rom::info_text#16 = 0 [phi:main::@119->display_info_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_rom.info_text
    sta.z display_info_rom.info_text+1
    // [1368] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#5 [phi:main::@119->display_info_rom#1] -- register_copy 
    // [1368] phi display_info_rom::info_status#16 = STATUS_DETECTED [phi:main::@119->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_DETECTED
    sta display_info_rom.info_status
    jsr display_info_rom
    jmp __b24
    // [762] phi from main::@7 to main::@20 [phi:main::@7->main::@20]
    // main::@20
  __b20:
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [763] call snprintf_init
    // [1184] phi from main::@20 to snprintf_init [phi:main::@20->snprintf_init]
    // [1184] phi snprintf_init::s#30 = info_text [phi:main::@20->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [764] phi from main::@20 to main::@106 [phi:main::@20->main::@106]
    // main::@106
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [765] call printf_str
    // [1125] phi from main::@106 to printf_str [phi:main::@106->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:main::@106->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = main::s [phi:main::@106->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // main::@107
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [766] printf_uint::uvalue#7 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta printf_uint.uvalue
    lda smc_bootloader+1
    sta printf_uint.uvalue+1
    // [767] call printf_uint
    // [2015] phi from main::@107 to printf_uint [phi:main::@107->printf_uint]
    // [2015] phi printf_uint::format_zero_padding#10 = 1 [phi:main::@107->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [2015] phi printf_uint::format_min_length#10 = 2 [phi:main::@107->printf_uint#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uint.format_min_length
    // [2015] phi printf_uint::putc#10 = &snputc [phi:main::@107->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [2015] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:main::@107->printf_uint#3] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [2015] phi printf_uint::uvalue#10 = printf_uint::uvalue#7 [phi:main::@107->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [768] phi from main::@107 to main::@108 [phi:main::@107->main::@108]
    // main::@108
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [769] call printf_str
    // [1125] phi from main::@108 to printf_str [phi:main::@108->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:main::@108->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = main::s1 [phi:main::@108->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // main::@109
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [770] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [771] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [773] smc_bootloader#579 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ISSUE, info_text)
    // [774] call display_info_smc
    // [925] phi from main::@109 to display_info_smc [phi:main::@109->display_info_smc]
    // [925] phi display_info_smc::info_text#24 = info_text [phi:main::@109->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_smc.info_text
    lda #>@info_text
    sta.z display_info_smc.info_text+1
    // [925] phi smc_bootloader#14 = smc_bootloader#579 [phi:main::@109->display_info_smc#1] -- register_copy 
    // [925] phi display_info_smc::info_status#24 = STATUS_ISSUE [phi:main::@109->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [775] phi from main::@109 to main::@110 [phi:main::@109->main::@110]
    // main::@110
    // display_progress_text(display_no_valid_smc_bootloader_text, display_no_valid_smc_bootloader_count)
    // [776] call display_progress_text
  // Bootloader is not supported by this utility, but is not error.
    // [1169] phi from main::@110 to display_progress_text [phi:main::@110->display_progress_text]
    // [1169] phi display_progress_text::text#13 = display_no_valid_smc_bootloader_text [phi:main::@110->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_no_valid_smc_bootloader_text
    sta.z display_progress_text.text
    lda #>display_no_valid_smc_bootloader_text
    sta.z display_progress_text.text+1
    // [1169] phi display_progress_text::lines#12 = display_no_valid_smc_bootloader_count [phi:main::@110->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_no_valid_smc_bootloader_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [105] phi from main::@105 main::@110 main::@19 to main::@2 [phi:main::@105/main::@110/main::@19->main::@2]
  __b8:
    // [105] phi smc_minor#418 = 0 [phi:main::@105/main::@110/main::@19->main::@2#0] -- vbum1=vbuc1 
    lda #0
    sta smc_minor
    // [105] phi smc_major#419 = 0 [phi:main::@105/main::@110/main::@19->main::@2#1] -- vbum1=vbuc1 
    sta smc_major
    // [105] phi smc_release#420 = 0 [phi:main::@105/main::@110/main::@19->main::@2#2] -- vbum1=vbuc1 
    sta smc_release
    jmp __b2
    // main::@19
  __b19:
    // [777] smc_bootloader#592 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ERROR, "SMC Unreachable!")
    // [778] call display_info_smc
  // SD2 | SMC chip not detected | Display that the SMC chip is not detected and set SMC to Error. | Error
    // [925] phi from main::@19 to display_info_smc [phi:main::@19->display_info_smc]
    // [925] phi display_info_smc::info_text#24 = main::info_text1 [phi:main::@19->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_smc.info_text
    lda #>info_text1
    sta.z display_info_smc.info_text+1
    // [925] phi smc_bootloader#14 = smc_bootloader#592 [phi:main::@19->display_info_smc#1] -- register_copy 
    // [925] phi display_info_smc::info_status#24 = STATUS_ERROR [phi:main::@19->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_smc.info_status
    jsr display_info_smc
    jmp __b8
    // main::@1
  __b1:
    // [779] smc_bootloader#578 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ISSUE, "No Bootloader!")
    // [780] call display_info_smc
  // SD1 | No Bootloader | Display that there is no bootloader and set SMC to Issue. | Issue
    // [925] phi from main::@1 to display_info_smc [phi:main::@1->display_info_smc]
    // [925] phi display_info_smc::info_text#24 = main::info_text [phi:main::@1->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_smc.info_text
    lda #>info_text
    sta.z display_info_smc.info_text+1
    // [925] phi smc_bootloader#14 = smc_bootloader#578 [phi:main::@1->display_info_smc#1] -- register_copy 
    // [925] phi display_info_smc::info_status#24 = STATUS_ISSUE [phi:main::@1->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [781] phi from main::@1 to main::@105 [phi:main::@1->main::@105]
    // main::@105
    // display_progress_text(display_no_valid_smc_bootloader_text, display_no_valid_smc_bootloader_count)
    // [782] call display_progress_text
  // If the CX16 board does not have a bootloader, display info how to flash bootloader.
    // [1169] phi from main::@105 to display_progress_text [phi:main::@105->display_progress_text]
    // [1169] phi display_progress_text::text#13 = display_no_valid_smc_bootloader_text [phi:main::@105->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_no_valid_smc_bootloader_text
    sta.z display_progress_text.text
    lda #>display_no_valid_smc_bootloader_text
    sta.z display_progress_text.text+1
    // [1169] phi display_progress_text::lines#12 = display_no_valid_smc_bootloader_count [phi:main::@105->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_no_valid_smc_bootloader_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    jmp __b8
  .segment Data
    smc_file_version_text: .fill $d, 0
    rom_file_release_text: .fill $d, 0
    source: .text "0.0.0"
    .byte 0
    info_text: .text "No Bootloader!"
    .byte 0
    info_text1: .text "SMC Unreachable!"
    .byte 0
    s: .text "Bootloader v"
    .byte 0
    s1: .text " invalid! !"
    .byte 0
    info_text2: .text "Checking SMC.BIN ..."
    .byte 0
    info_text3: .text "No SMC.BIN!"
    .byte 0
    info_text4: .text "SMC.BIN too large!"
    .byte 0
    s2: .text "SMC.BIN:"
    .byte 0
    s3: .text "Checking "
    .byte 0
    s5: .text "No "
    .byte 0
    s6: .text "File "
    .byte 0
    s7: .text " size error!"
    .byte 0
    info_text5: .text "Issue with the CX16 SMC, check the issue ..."
    .byte 0
    info_text6: .text "Issue with SMC!"
    .byte 0
    info_text7: .text "Proceed with the update? [Y/N]"
    .byte 0
    filter: .text "YN"
    .byte 0
    info_text9: .text "Issue with the CX16 ROM: not detected! ..."
    .byte 0
    info_text10: .text "Issue with CX16 ROM!"
    .byte 0
    info_text11: .text "Are J1 jumper pins closed?"
    .byte 0
    info_text13: .text "Issue with the CX16 ROM, check the issue ..."
    .byte 0
    info_text14: .text "Issue with main CX16 ROM!"
    .byte 0
    info_text20: .text "Compatibility between ROM.BIN and SMC.BIN can't be assured!"
    .byte 0
    info_text22: .text "The CX16 SMC and SMC.BIN versions are equal, no flash required!"
    .byte 0
    info_text23: .text "The CX16 ROM and ROM.BIN versions are equal, no flash required!"
    .byte 0
    info_text24: .text "Chipsets have been detected and update files validated!"
    .byte 0
    info_text25: .text "Continue with update of highlighted chipsets? [Y/N]"
    .byte 0
    filter4: .text "nyNY"
    .byte 0
    main__354: .text "nN"
    .byte 0
    info_text26: .text "Cancelled"
    .byte 0
    info_text29: .text "You have selected not to cancel the update ... "
    .byte 0
    info_text30: .text "Reading SMC.BIN ... (.) data, ( ) empty"
    .byte 0
    info_text31: .text "Press both POWER/RESET buttons on the CX16 board!"
    .byte 0
    info_text32: .text "Press POWER/RESET!"
    .byte 0
    info_text33: .text "SMC has errors!"
    .byte 0
    info_text34: .text "POWER/RESET not pressed!"
    .byte 0
    s9: .text "Reading "
    .byte 0
    s10: .text " ... (.) data ( ) empty"
    .byte 0
    info_text35: .text "SMC Update failed!"
    .byte 0
    info_text36: .text "Comparing ... (.) data, (=) same, (*) different."
    .byte 0
    s12: .text " flash errors!"
    .byte 0
    s13: .text "There was a severe error updating your VERA!"
    .byte 0
    s14: .text @"You are back at the READY prompt without resetting your CX16.\n\n"
    .byte 0
    s15: .text @"Please don't reset or shut down your VERA until you've\n"
    .byte 0
    s16: .text "managed to either reflash your VERA with the previous firmware "
    .byte 0
    s17: .text @"or have update successs retrying!\n\n"
    .byte 0
    s18: .text @"PLEASE REMOVE THE JP1 JUMPER OR YOUR SDCARD WON'T WORK!\n"
    .byte 0
    info_text39: .text "No CX16 component has been updated with new firmware!"
    .byte 0
    info_text40: .text "Update Failure! Your CX16 may no longer boot!"
    .byte 0
    info_text41: .text "Take a photo of this screen and wait at leaast 60 seconds."
    .byte 0
    info_text42: .text "Update issues, your CX16 is not updated!"
    .byte 0
    info_text43: .text "Your CX16 update is a success!"
    .byte 0
    text: .text "DON'T DO ANYTHING UNTIL COUNTDOWN FINISHES!"
    .byte 0
    s20: .text "] Please read carefully the below ..."
    .byte 0
    s21: .text "Please disconnect your CX16 from power source ..."
    .byte 0
    s22: .text "("
    .byte 0
    s23: .text ") Your CX16 will reset after countdown ..."
    .byte 0
    main__50: .word 0
    main__59: .byte 0
    main__107: .byte 0
    main__324: .byte 0
    main__326: .byte 0
    rom_chip: .byte 0
    rom_chip1: .byte 0
    rom_bank: .byte 0
    file: .word 0
    .label rom_bytes_read = rom_read.return
    rom_file_modulo: .dword 0
    check_status_smc6_return: .byte 0
    check_status_smc9_return: .byte 0
    check_status_vera4_return: .byte 0
    check_status_smc10_return: .byte 0
    rom_chip2: .byte 0
    .label flashed_bytes = smc_flash.return
    rom_chip3: .byte 0
    rom_bank1: .byte 0
    .label file1 = rom_file.return
    .label rom_bytes_read1 = rom_read.return
    rom_differences: .dword 0
    rom_flash_errors: .dword 0
    check_status_smc16_return: .byte 0
    check_status_vera10_return: .byte 0
    check_status_smc17_return: .byte 0
    check_status_vera11_return: .byte 0
    w: .byte 0
    w1: .byte 0
}
.segment Code
  // screenlayer1
// Set the layer with which the conio will interact.
screenlayer1: {
    // screenlayer(1, *VERA_L1_MAPBASE, *VERA_L1_CONFIG)
    // [783] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbuxx=_deref_pbuc1 
    ldx VERA_L1_MAPBASE
    // [784] screenlayer::config#0 = *VERA_L1_CONFIG -- vbum1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta screenlayer.config
    // [785] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [786] return 
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
    // [788] textcolor::$0 = *((char *)&__conio+$d) & $f0 -- vbuaa=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$d
    // __conio.color & 0xF0 | color
    // [789] textcolor::$1 = textcolor::$0 | textcolor::color#23 -- vbuaa=vbuaa_bor_vbuxx 
    stx.z $ff
    ora.z $ff
    // __conio.color = __conio.color & 0xF0 | color
    // [790] *((char *)&__conio+$d) = textcolor::$1 -- _deref_pbuc1=vbuaa 
    sta __conio+$d
    // textcolor::@return
    // }
    // [791] return 
    rts
}
  // bgcolor
// Set the back color for text output.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char bgcolor(__register(X) char color)
bgcolor: {
    .label bgcolor__0 = $72
    // __conio.color & 0x0F
    // [793] bgcolor::$0 = *((char *)&__conio+$d) & $f -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$d
    sta.z bgcolor__0
    // color << 4
    // [794] bgcolor::$1 = bgcolor::color#15 << 4 -- vbuaa=vbuxx_rol_4 
    txa
    asl
    asl
    asl
    asl
    // __conio.color & 0x0F | color << 4
    // [795] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbuaa=vbuz1_bor_vbuaa 
    ora.z bgcolor__0
    // __conio.color = __conio.color & 0x0F | color << 4
    // [796] *((char *)&__conio+$d) = bgcolor::$2 -- _deref_pbuc1=vbuaa 
    sta __conio+$d
    // bgcolor::@return
    // }
    // [797] return 
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
    // [798] *((char *)&__conio+$c) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$c
    // cursor::@return
    // }
    // [799] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    // __mem unsigned char x
    // [800] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [801] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [803] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwum1=vbum2_word_vbum3 
    lda x
    sta return+1
    lda y
    sta return
    // cbm_k_plot_get::@return
    // }
    // [804] return 
    rts
  .segment Data
    x: .byte 0
    y: .byte 0
    .label return = screenlayer.mapbase_offset
}
.segment Code
  // gotoxy
// Set the cursor to the specified position
// void gotoxy(__register(Y) char x, __mem() char y)
gotoxy: {
    .label gotoxy__8 = $29
    .label gotoxy__9 = $27
    // (x>=__conio.width)?__conio.width:x
    // [806] if(gotoxy::x#37>=*((char *)&__conio+6)) goto gotoxy::@1 -- vbuyy_ge__deref_pbuc1_then_la1 
    cpy __conio+6
    bcs __b1
    // [808] phi from gotoxy to gotoxy::@2 [phi:gotoxy->gotoxy::@2]
    // [808] phi gotoxy::$3 = gotoxy::x#37 [phi:gotoxy->gotoxy::@2#0] -- vbuaa=vbuyy 
    tya
    jmp __b2
    // gotoxy::@1
  __b1:
    // [807] gotoxy::$2 = *((char *)&__conio+6) -- vbuaa=_deref_pbuc1 
    lda __conio+6
    // [808] phi from gotoxy::@1 to gotoxy::@2 [phi:gotoxy::@1->gotoxy::@2]
    // [808] phi gotoxy::$3 = gotoxy::$2 [phi:gotoxy::@1->gotoxy::@2#0] -- register_copy 
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [809] *((char *)&__conio) = gotoxy::$3 -- _deref_pbuc1=vbuaa 
    sta __conio
    // (y>=__conio.height)?__conio.height:y
    // [810] if(gotoxy::y#37>=*((char *)&__conio+7)) goto gotoxy::@3 -- vbum1_ge__deref_pbuc1_then_la1 
    lda y
    cmp __conio+7
    bcs __b3
    // gotoxy::@4
    // [811] gotoxy::$14 = gotoxy::y#37 -- vbuaa=vbum1 
    // [812] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [812] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [813] *((char *)&__conio+1) = gotoxy::$7 -- _deref_pbuc1=vbuaa 
    sta __conio+1
    // __conio.cursor_x << 1
    // [814] gotoxy::$8 = *((char *)&__conio) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio
    asl
    sta.z gotoxy__8
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [815] gotoxy::$10 = gotoxy::y#37 << 1 -- vbuaa=vbum1_rol_1 
    lda y
    asl
    // [816] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwuz1=pwuc1_derefidx_vbuaa_plus_vbuz2 
    tay
    lda.z gotoxy__8
    clc
    adc __conio+$15,y
    sta.z gotoxy__9
    lda __conio+$15+1,y
    adc #0
    sta.z gotoxy__9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [817] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwuz1 
    lda.z gotoxy__9
    sta __conio+$13
    lda.z gotoxy__9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [818] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [819] gotoxy::$6 = *((char *)&__conio+7) -- vbuaa=_deref_pbuc1 
    lda __conio+7
    jmp __b5
  .segment Data
    y: .byte 0
}
.segment Code
  // cputln
// Print a newline
cputln: {
    // __conio.cursor_x = 0
    // [820] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y++;
    // [821] *((char *)&__conio+1) = ++ *((char *)&__conio+1) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+1
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [822] cputln::$2 = *((char *)&__conio+1) << 1 -- vbuaa=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    // [823] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuaa 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [824] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [825] return 
    rts
}
.segment CodeIntro
  // init
init: {
    .label rom_chip = $7d
    // display_frame_init_64()
    // [827] call display_frame_init_64
    jsr display_frame_init_64
    // [828] phi from init to init::@4 [phi:init->init::@4]
    // init::@4
    // display_frame_draw()
    // [829] call display_frame_draw
  // ST1 | Reset canvas to 64 columns
    // [2100] phi from init::@4 to display_frame_draw [phi:init::@4->display_frame_draw]
    jsr display_frame_draw
    // [830] phi from init::@4 to init::@5 [phi:init::@4->init::@5]
    // init::@5
    // display_frame_title("Commander X16 Update Utility (v2.2.1) ")
    // [831] call display_frame_title
    // [2141] phi from init::@5 to display_frame_title [phi:init::@5->display_frame_title]
    jsr display_frame_title
    // [832] phi from init::@5 to init::display_info_title1 [phi:init::@5->init::display_info_title1]
    // init::display_info_title1
    // cputsxy(INFO_X-2, INFO_Y-2, "# Chip Status    Type   Curr. Release Update Info")
    // [833] call cputsxy
    // [2146] phi from init::display_info_title1 to cputsxy [phi:init::display_info_title1->cputsxy]
    // [2146] phi cputsxy::s#4 = init::s [phi:init::display_info_title1->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [2146] phi cputsxy::y#4 = $11-2 [phi:init::display_info_title1->cputsxy#1] -- vbuxx=vbuc1 
    ldx #$11-2
    // [2146] phi cputsxy::x#4 = 4-2 [phi:init::display_info_title1->cputsxy#2] -- vbuyy=vbuc1 
    ldy #4-2
    jsr cputsxy
    // [834] phi from init::display_info_title1 to init::@6 [phi:init::display_info_title1->init::@6]
    // init::@6
    // cputsxy(INFO_X-2, INFO_Y-1, "- ---- --------- ------ ------------- --------------------------")
    // [835] call cputsxy
    // [2146] phi from init::@6 to cputsxy [phi:init::@6->cputsxy]
    // [2146] phi cputsxy::s#4 = init::s1 [phi:init::@6->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s1
    sta.z cputsxy.s
    lda #>s1
    sta.z cputsxy.s+1
    // [2146] phi cputsxy::y#4 = $11-1 [phi:init::@6->cputsxy#1] -- vbuxx=vbuc1 
    ldx #$11-1
    // [2146] phi cputsxy::x#4 = 4-2 [phi:init::@6->cputsxy#2] -- vbuyy=vbuc1 
    ldy #4-2
    jsr cputsxy
    // [836] phi from init::@6 to init::@3 [phi:init::@6->init::@3]
    // init::@3
    // display_action_progress("Introduction, please read carefully the below!")
    // [837] call display_action_progress
    // [1155] phi from init::@3 to display_action_progress [phi:init::@3->display_action_progress]
    // [1155] phi display_action_progress::info_text#30 = init::info_text [phi:init::@3->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [838] phi from init::@3 to init::@7 [phi:init::@3->init::@7]
    // init::@7
    // display_progress_clear()
    // [839] call display_progress_clear
    // [1037] phi from init::@7 to display_progress_clear [phi:init::@7->display_progress_clear]
    jsr display_progress_clear
    // [840] phi from init::@7 to init::@8 [phi:init::@7->init::@8]
    // init::@8
    // display_chip_smc()
    // [841] call display_chip_smc
    // [898] phi from init::@8 to display_chip_smc [phi:init::@8->display_chip_smc]
    jsr display_chip_smc
    // [842] phi from init::@8 to init::@9 [phi:init::@8->init::@9]
    // init::@9
    // display_chip_vera()
    // [843] call display_chip_vera
    // [2153] phi from init::@9 to display_chip_vera [phi:init::@9->display_chip_vera]
    jsr display_chip_vera
    // [844] phi from init::@9 to init::@10 [phi:init::@9->init::@10]
    // init::@10
    // display_chip_rom()
    // [845] call display_chip_rom
    // [1018] phi from init::@10 to display_chip_rom [phi:init::@10->display_chip_rom]
    jsr display_chip_rom
    // [846] phi from init::@10 to init::@11 [phi:init::@10->init::@11]
    // init::@11
    // display_info_smc(STATUS_COLOR_NONE, NULL)
    // [847] call display_info_smc
    // [925] phi from init::@11 to display_info_smc [phi:init::@11->display_info_smc]
    // [925] phi display_info_smc::info_text#24 = 0 [phi:init::@11->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [925] phi smc_bootloader#14 = 0 [phi:init::@11->display_info_smc#1] -- vwum1=vwuc1 
    sta smc_bootloader_1
    sta smc_bootloader_1+1
    // [925] phi display_info_smc::info_status#24 = BLACK [phi:init::@11->display_info_smc#2] -- vbuz1=vbuc1 
    lda #BLACK
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [848] phi from init::@11 to init::@12 [phi:init::@11->init::@12]
    // init::@12
    // display_info_vera(STATUS_NONE, NULL)
    // [849] call display_info_vera
    // [1930] phi from init::@12 to display_info_vera [phi:init::@12->display_info_vera]
    // [1930] phi display_info_vera::info_text#15 = 0 [phi:init::@12->display_info_vera#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_vera.info_text
    sta.z display_info_vera.info_text+1
    // [1930] phi display_info_vera::info_status#15 = STATUS_NONE [phi:init::@12->display_info_vera#1] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta display_info_vera.info_status
    jsr display_info_vera
    // [850] phi from init::@12 to init::@1 [phi:init::@12->init::@1]
    // [850] phi init::rom_chip#2 = 0 [phi:init::@12->init::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_chip
    // init::@1
  __b1:
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [851] if(init::rom_chip#2<8) goto init::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z rom_chip
    cmp #8
    bcc __b2
    // init::@return
    // }
    // [852] return 
    rts
    // init::@2
  __b2:
    // rom_chip*13
    // [853] init::$16 = init::rom_chip#2 << 1 -- vbuaa=vbuz1_rol_1 
    lda.z rom_chip
    asl
    // [854] init::$17 = init::$16 + init::rom_chip#2 -- vbuaa=vbuaa_plus_vbuz1 
    clc
    adc.z rom_chip
    // [855] init::$18 = init::$17 << 2 -- vbuaa=vbuaa_rol_2 
    asl
    asl
    // [856] init::$12 = init::$18 + init::rom_chip#2 -- vbuaa=vbuaa_plus_vbuz1 
    clc
    adc.z rom_chip
    // strcpy(&rom_release_text[rom_chip*13], "          " )
    // [857] strcpy::destination#0 = rom_release_text + init::$12 -- pbuz1=pbuc1_plus_vbuaa 
    clc
    adc #<rom_release_text
    sta.z strcpy.destination
    lda #>rom_release_text
    adc #0
    sta.z strcpy.destination+1
    // [858] call strcpy
    // [890] phi from init::@2 to strcpy [phi:init::@2->strcpy]
    // [890] phi strcpy::dst#0 = strcpy::destination#0 [phi:init::@2->strcpy#0] -- register_copy 
    // [890] phi strcpy::src#0 = init::source [phi:init::@2->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // init::@13
    // display_info_rom(rom_chip, STATUS_NONE, NULL)
    // [859] display_info_rom::rom_chip#0 = init::rom_chip#2 -- vbum1=vbuz2 
    lda.z rom_chip
    sta display_info_rom.rom_chip
    // [860] call display_info_rom
    // [1368] phi from init::@13 to display_info_rom [phi:init::@13->display_info_rom]
    // [1368] phi display_info_rom::info_text#16 = 0 [phi:init::@13->display_info_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_rom.info_text
    sta.z display_info_rom.info_text+1
    // [1368] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#0 [phi:init::@13->display_info_rom#1] -- register_copy 
    // [1368] phi display_info_rom::info_status#16 = STATUS_NONE [phi:init::@13->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta display_info_rom.info_status
    jsr display_info_rom
    // init::@14
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [861] init::rom_chip#1 = ++ init::rom_chip#2 -- vbuz1=_inc_vbuz1 
    inc.z rom_chip
    // [850] phi from init::@14 to init::@1 [phi:init::@14->init::@1]
    // [850] phi init::rom_chip#2 = init::rom_chip#1 [phi:init::@14->init::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    title_text: .text "Commander X16 Update Utility (v2.2.1) "
    .byte 0
    s: .text "# Chip Status    Type   Curr. Release Update Info"
    .byte 0
    s1: .text "- ---- --------- ------ ------------- --------------------------"
    .byte 0
    info_text: .text "Introduction, please read carefully the below!"
    .byte 0
    source: .text "          "
    .byte 0
}
.segment CodeIntro
  // main_intro
main_intro: {
    // display_progress_text(display_into_briefing_text, display_intro_briefing_count)
    // [863] call display_progress_text
    // [1169] phi from main_intro to display_progress_text [phi:main_intro->display_progress_text]
    // [1169] phi display_progress_text::text#13 = display_into_briefing_text [phi:main_intro->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_into_briefing_text
    sta.z display_progress_text.text
    lda #>display_into_briefing_text
    sta.z display_progress_text.text+1
    // [1169] phi display_progress_text::lines#12 = display_intro_briefing_count [phi:main_intro->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_intro_briefing_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [864] phi from main_intro to main_intro::@4 [phi:main_intro->main_intro::@4]
    // main_intro::@4
    // util_wait_space()
    // [865] call util_wait_space
    // [1958] phi from main_intro::@4 to util_wait_space [phi:main_intro::@4->util_wait_space]
    jsr util_wait_space
    // [866] phi from main_intro::@4 to main_intro::@5 [phi:main_intro::@4->main_intro::@5]
    // main_intro::@5
    // display_progress_text(display_into_colors_text, display_intro_colors_count)
    // [867] call display_progress_text
    // [1169] phi from main_intro::@5 to display_progress_text [phi:main_intro::@5->display_progress_text]
    // [1169] phi display_progress_text::text#13 = display_into_colors_text [phi:main_intro::@5->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_into_colors_text
    sta.z display_progress_text.text
    lda #>display_into_colors_text
    sta.z display_progress_text.text+1
    // [1169] phi display_progress_text::lines#12 = display_intro_colors_count [phi:main_intro::@5->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_intro_colors_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [868] phi from main_intro::@5 to main_intro::@1 [phi:main_intro::@5->main_intro::@1]
    // [868] phi main_intro::intro_status#2 = 0 [phi:main_intro::@5->main_intro::@1#0] -- vbum1=vbuc1 
    lda #0
    sta intro_status
    // main_intro::@1
  __b1:
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [869] if(main_intro::intro_status#2<$b) goto main_intro::@2 -- vbum1_lt_vbuc1_then_la1 
    lda intro_status
    cmp #$b
    bcc __b2
    // [870] phi from main_intro::@1 to main_intro::@3 [phi:main_intro::@1->main_intro::@3]
    // main_intro::@3
    // util_wait_space()
    // [871] call util_wait_space
    // [1958] phi from main_intro::@3 to util_wait_space [phi:main_intro::@3->util_wait_space]
    jsr util_wait_space
    // [872] phi from main_intro::@3 to main_intro::@7 [phi:main_intro::@3->main_intro::@7]
    // main_intro::@7
    // display_progress_clear()
    // [873] call display_progress_clear
    // [1037] phi from main_intro::@7 to display_progress_clear [phi:main_intro::@7->display_progress_clear]
    jsr display_progress_clear
    // main_intro::@return
    // }
    // [874] return 
    rts
    // main_intro::@2
  __b2:
    // display_info_led(PROGRESS_X + 3, PROGRESS_Y + 3 + intro_status, status_color[intro_status], BLUE)
    // [875] display_info_led::y#3 = PROGRESS_Y+3 + main_intro::intro_status#2 -- vbuz1=vbuc1_plus_vbum2 
    lda #PROGRESS_Y+3
    clc
    adc intro_status
    sta.z display_info_led.y
    // [876] display_info_led::tc#3 = status_color[main_intro::intro_status#2] -- vbuxx=pbuc1_derefidx_vbum1 
    ldy intro_status
    ldx status_color,y
    // [877] call display_info_led
    // [2158] phi from main_intro::@2 to display_info_led [phi:main_intro::@2->display_info_led]
    // [2158] phi display_info_led::y#4 = display_info_led::y#3 [phi:main_intro::@2->display_info_led#0] -- register_copy 
    // [2158] phi display_info_led::x#4 = PROGRESS_X+3 [phi:main_intro::@2->display_info_led#1] -- vbuyy=vbuc1 
    ldy #PROGRESS_X+3
    // [2158] phi display_info_led::tc#4 = display_info_led::tc#3 [phi:main_intro::@2->display_info_led#2] -- register_copy 
    jsr display_info_led
    // main_intro::@6
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [878] main_intro::intro_status#1 = ++ main_intro::intro_status#2 -- vbum1=_inc_vbum1 
    inc intro_status
    // [868] phi from main_intro::@6 to main_intro::@1 [phi:main_intro::@6->main_intro::@1]
    // [868] phi main_intro::intro_status#2 = main_intro::intro_status#1 [phi:main_intro::@6->main_intro::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    .label intro_status = smc_get_version_text.major
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
    .label smc_bootloader_version = $ad
    .label return = $ad
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [879] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [880] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [881] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [882] cx16_k_i2c_read_byte::return#10 = cx16_k_i2c_read_byte::return#1
    // smc_detect::@3
    // smc_bootloader_version = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [883] smc_detect::smc_bootloader_version#1 = cx16_k_i2c_read_byte::return#10 -- vwuz1=vwum2 
    lda cx16_k_i2c_read_byte.return
    sta.z smc_bootloader_version
    lda cx16_k_i2c_read_byte.return+1
    sta.z smc_bootloader_version+1
    // BYTE1(smc_bootloader_version)
    // [884] smc_detect::$1 = byte1  smc_detect::smc_bootloader_version#1 -- vbuaa=_byte1_vwuz1 
    // if(!BYTE1(smc_bootloader_version))
    // [885] if(0==smc_detect::$1) goto smc_detect::@1 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b1
    // [888] phi from smc_detect::@3 to smc_detect::@2 [phi:smc_detect::@3->smc_detect::@2]
    // [888] phi smc_detect::return#0 = $200 [phi:smc_detect::@3->smc_detect::@2#0] -- vwuz1=vwuc1 
    lda #<$200
    sta.z return
    lda #>$200
    sta.z return+1
    rts
    // smc_detect::@1
  __b1:
    // if(smc_bootloader_version == 0xFF)
    // [886] if(smc_detect::smc_bootloader_version#1!=$ff) goto smc_detect::@4 -- vwuz1_neq_vbuc1_then_la1 
    lda.z smc_bootloader_version+1
    bne __b2
    lda.z smc_bootloader_version
    cmp #$ff
    bne __b2
    // [888] phi from smc_detect::@1 to smc_detect::@2 [phi:smc_detect::@1->smc_detect::@2]
    // [888] phi smc_detect::return#0 = $100 [phi:smc_detect::@1->smc_detect::@2#0] -- vwuz1=vwuc1 
    lda #<$100
    sta.z return
    lda #>$100
    sta.z return+1
    rts
    // [887] phi from smc_detect::@1 to smc_detect::@4 [phi:smc_detect::@1->smc_detect::@4]
    // smc_detect::@4
    // [888] phi from smc_detect::@4 to smc_detect::@2 [phi:smc_detect::@4->smc_detect::@2]
    // [888] phi smc_detect::return#0 = smc_detect::smc_bootloader_version#1 [phi:smc_detect::@4->smc_detect::@2#0] -- register_copy 
    // smc_detect::@2
  __b2:
    // smc_detect::@return
    // }
    // [889] return 
    rts
}
  // strcpy
// Copies the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcpy(__zp($76) char *destination, char *source)
strcpy: {
    .label src = $ad
    .label dst = $76
    .label destination = $76
    // [891] phi from strcpy strcpy::@2 to strcpy::@1 [phi:strcpy/strcpy::@2->strcpy::@1]
    // [891] phi strcpy::dst#2 = strcpy::dst#0 [phi:strcpy/strcpy::@2->strcpy::@1#0] -- register_copy 
    // [891] phi strcpy::src#2 = strcpy::src#0 [phi:strcpy/strcpy::@2->strcpy::@1#1] -- register_copy 
    // strcpy::@1
  __b1:
    // while(*src)
    // [892] if(0!=*strcpy::src#2) goto strcpy::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcpy::@3
    // *dst = 0
    // [893] *strcpy::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcpy::@return
    // }
    // [894] return 
    rts
    // strcpy::@2
  __b2:
    // *dst++ = *src++
    // [895] *strcpy::dst#2 = *strcpy::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [896] strcpy::dst#1 = ++ strcpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [897] strcpy::src#1 = ++ strcpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    jmp __b1
}
  // display_chip_smc
display_chip_smc: {
    // display_smc_led(GREY)
    // [899] call display_smc_led
    // [2169] phi from display_chip_smc to display_smc_led [phi:display_chip_smc->display_smc_led]
    // [2169] phi display_smc_led::c#2 = GREY [phi:display_chip_smc->display_smc_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z display_smc_led.c
    jsr display_smc_led
    // [900] phi from display_chip_smc to display_chip_smc::@1 [phi:display_chip_smc->display_chip_smc::@1]
    // display_chip_smc::@1
    // display_print_chip(CHIP_SMC_X, CHIP_SMC_Y+2, CHIP_SMC_W, "SMC     ")
    // [901] call display_print_chip
    // [2175] phi from display_chip_smc::@1 to display_print_chip [phi:display_chip_smc::@1->display_print_chip]
    // [2175] phi display_print_chip::text#11 = display_chip_smc::text [phi:display_chip_smc::@1->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_print_chip.text_2
    lda #>text
    sta.z display_print_chip.text_2+1
    // [2175] phi display_print_chip::w#10 = 5 [phi:display_chip_smc::@1->display_print_chip#1] -- vbum1=vbuc1 
    lda #5
    sta display_print_chip.w
    // [2175] phi display_print_chip::x#10 = 1 [phi:display_chip_smc::@1->display_print_chip#2] -- vbuz1=vbuc1 
    lda #1
    sta.z display_print_chip.x
    jsr display_print_chip
    // display_chip_smc::@return
    // }
    // [902] return 
    rts
  .segment Data
    text: .text "SMC     "
    .byte 0
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
    // [903] cx16_k_i2c_read_byte::result = 0 -- vwum1=vwuc1 
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
    // [905] cx16_k_i2c_read_byte::return#0 = cx16_k_i2c_read_byte::result -- vwum1=vwum2 
    sta return
    lda result+1
    sta return+1
    // cx16_k_i2c_read_byte::@return
    // }
    // [906] cx16_k_i2c_read_byte::return#1 = cx16_k_i2c_read_byte::return#0
    // [907] return 
    rts
  .segment Data
    device: .byte 0
    offset: .byte 0
    result: .word 0
    .label return = strncmp.n
}
.segment Code
  // smc_get_version_text
/**
 * @brief Detect and write the SMC version number into the info_text.
 * 
 * @param version_string The string containing the SMC version filled upon return.
 */
// unsigned long smc_get_version_text(__zp($76) char *version_string, __register(Y) char release, __mem() char major, __zp($d3) char minor)
smc_get_version_text: {
    .label minor = $d3
    .label version_string = $76
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [909] snprintf_init::s#4 = smc_get_version_text::version_string#2
    // [910] call snprintf_init
    // [1184] phi from smc_get_version_text to snprintf_init [phi:smc_get_version_text->snprintf_init]
    // [1184] phi snprintf_init::s#30 = snprintf_init::s#4 [phi:smc_get_version_text->snprintf_init#0] -- register_copy 
    jsr snprintf_init
    // smc_get_version_text::@1
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [911] printf_uchar::uvalue#3 = smc_get_version_text::release#2 -- vbuxx=vbuyy 
    tya
    tax
    // [912] call printf_uchar
    // [1189] phi from smc_get_version_text::@1 to printf_uchar [phi:smc_get_version_text::@1->printf_uchar]
    // [1189] phi printf_uchar::format_zero_padding#15 = 0 [phi:smc_get_version_text::@1->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1189] phi printf_uchar::format_min_length#15 = 0 [phi:smc_get_version_text::@1->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1189] phi printf_uchar::putc#15 = &snputc [phi:smc_get_version_text::@1->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1189] phi printf_uchar::format_radix#15 = DECIMAL [phi:smc_get_version_text::@1->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [1189] phi printf_uchar::uvalue#15 = printf_uchar::uvalue#3 [phi:smc_get_version_text::@1->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [913] phi from smc_get_version_text::@1 to smc_get_version_text::@2 [phi:smc_get_version_text::@1->smc_get_version_text::@2]
    // smc_get_version_text::@2
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [914] call printf_str
    // [1125] phi from smc_get_version_text::@2 to printf_str [phi:smc_get_version_text::@2->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:smc_get_version_text::@2->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = smc_get_version_text::s [phi:smc_get_version_text::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_get_version_text::@3
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [915] printf_uchar::uvalue#4 = smc_get_version_text::major#2 -- vbuxx=vbum1 
    ldx major
    // [916] call printf_uchar
    // [1189] phi from smc_get_version_text::@3 to printf_uchar [phi:smc_get_version_text::@3->printf_uchar]
    // [1189] phi printf_uchar::format_zero_padding#15 = 0 [phi:smc_get_version_text::@3->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1189] phi printf_uchar::format_min_length#15 = 0 [phi:smc_get_version_text::@3->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1189] phi printf_uchar::putc#15 = &snputc [phi:smc_get_version_text::@3->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1189] phi printf_uchar::format_radix#15 = DECIMAL [phi:smc_get_version_text::@3->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [1189] phi printf_uchar::uvalue#15 = printf_uchar::uvalue#4 [phi:smc_get_version_text::@3->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [917] phi from smc_get_version_text::@3 to smc_get_version_text::@4 [phi:smc_get_version_text::@3->smc_get_version_text::@4]
    // smc_get_version_text::@4
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [918] call printf_str
    // [1125] phi from smc_get_version_text::@4 to printf_str [phi:smc_get_version_text::@4->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:smc_get_version_text::@4->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = smc_get_version_text::s [phi:smc_get_version_text::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_get_version_text::@5
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [919] printf_uchar::uvalue#5 = smc_get_version_text::minor#2 -- vbuxx=vbuz1 
    ldx.z minor
    // [920] call printf_uchar
    // [1189] phi from smc_get_version_text::@5 to printf_uchar [phi:smc_get_version_text::@5->printf_uchar]
    // [1189] phi printf_uchar::format_zero_padding#15 = 0 [phi:smc_get_version_text::@5->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1189] phi printf_uchar::format_min_length#15 = 0 [phi:smc_get_version_text::@5->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1189] phi printf_uchar::putc#15 = &snputc [phi:smc_get_version_text::@5->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1189] phi printf_uchar::format_radix#15 = DECIMAL [phi:smc_get_version_text::@5->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [1189] phi printf_uchar::uvalue#15 = printf_uchar::uvalue#5 [phi:smc_get_version_text::@5->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // smc_get_version_text::@6
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [921] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [922] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_get_version_text::@return
    // }
    // [924] return 
    rts
  .segment Data
    s: .text "."
    .byte 0
    major: .byte 0
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
// void display_info_smc(__zp($71) char info_status, __zp($ad) char *info_text)
display_info_smc: {
    .label info_status = $71
    .label info_text = $ad
    // unsigned char x = wherex()
    // [926] call wherex
    jsr wherex
    // [927] wherex::return#10 = wherex::return#0
    // display_info_smc::@3
    // [928] display_info_smc::x#0 = wherex::return#10 -- vbum1=vbuaa 
    sta x
    // unsigned char y = wherey()
    // [929] call wherey
    jsr wherey
    // [930] wherey::return#10 = wherey::return#0
    // display_info_smc::@4
    // [931] display_info_smc::y#0 = wherey::return#10 -- vbum1=vbuaa 
    sta y
    // status_smc = info_status
    // [932] status_smc#147 = display_info_smc::info_status#24 -- vbum1=vbuz2 
    lda.z info_status
    sta status_smc
    // display_smc_led(status_color[info_status])
    // [933] display_smc_led::c#1 = status_color[display_info_smc::info_status#24] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z display_smc_led.c
    // [934] call display_smc_led
    // [2169] phi from display_info_smc::@4 to display_smc_led [phi:display_info_smc::@4->display_smc_led]
    // [2169] phi display_smc_led::c#2 = display_smc_led::c#1 [phi:display_info_smc::@4->display_smc_led#0] -- register_copy 
    jsr display_smc_led
    // [935] phi from display_info_smc::@4 to display_info_smc::@5 [phi:display_info_smc::@4->display_info_smc::@5]
    // display_info_smc::@5
    // gotoxy(INFO_X, INFO_Y)
    // [936] call gotoxy
    // [805] phi from display_info_smc::@5 to gotoxy [phi:display_info_smc::@5->gotoxy]
    // [805] phi gotoxy::y#37 = $11 [phi:display_info_smc::@5->gotoxy#0] -- vbum1=vbuc1 
    lda #$11
    sta gotoxy.y
    // [805] phi gotoxy::x#37 = 4 [phi:display_info_smc::@5->gotoxy#1] -- vbuyy=vbuc1 
    ldy #4
    jsr gotoxy
    // [937] phi from display_info_smc::@5 to display_info_smc::@6 [phi:display_info_smc::@5->display_info_smc::@6]
    // display_info_smc::@6
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [938] call printf_str
    // [1125] phi from display_info_smc::@6 to printf_str [phi:display_info_smc::@6->printf_str]
    // [1125] phi printf_str::putc#79 = &cputc [phi:display_info_smc::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = display_info_smc::s [phi:display_info_smc::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@7
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [939] display_info_smc::$9 = display_info_smc::info_status#24 << 1 -- vbuaa=vbuz1_rol_1 
    lda.z info_status
    asl
    // [940] printf_string::str#3 = status_text[display_info_smc::$9] -- pbuz1=qbuc1_derefidx_vbuaa 
    tay
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [941] call printf_string
    // [1419] phi from display_info_smc::@7 to printf_string [phi:display_info_smc::@7->printf_string]
    // [1419] phi printf_string::putc#26 = &cputc [phi:display_info_smc::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1419] phi printf_string::str#26 = printf_string::str#3 [phi:display_info_smc::@7->printf_string#1] -- register_copy 
    // [1419] phi printf_string::format_justify_left#26 = 1 [phi:display_info_smc::@7->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1419] phi printf_string::format_min_length#26 = 9 [phi:display_info_smc::@7->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [942] phi from display_info_smc::@7 to display_info_smc::@8 [phi:display_info_smc::@7->display_info_smc::@8]
    // display_info_smc::@8
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [943] call printf_str
    // [1125] phi from display_info_smc::@8 to printf_str [phi:display_info_smc::@8->printf_str]
    // [1125] phi printf_str::putc#79 = &cputc [phi:display_info_smc::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = display_info_smc::s1 [phi:display_info_smc::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // [944] phi from display_info_smc::@8 to display_info_smc::@9 [phi:display_info_smc::@8->display_info_smc::@9]
    // display_info_smc::@9
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [945] call printf_string
    // [1419] phi from display_info_smc::@9 to printf_string [phi:display_info_smc::@9->printf_string]
    // [1419] phi printf_string::putc#26 = &cputc [phi:display_info_smc::@9->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1419] phi printf_string::str#26 = smc_version_text [phi:display_info_smc::@9->printf_string#1] -- pbuz1=pbuc1 
    lda #<smc_version_text
    sta.z printf_string.str
    lda #>smc_version_text
    sta.z printf_string.str+1
    // [1419] phi printf_string::format_justify_left#26 = 1 [phi:display_info_smc::@9->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1419] phi printf_string::format_min_length#26 = 8 [phi:display_info_smc::@9->printf_string#3] -- vbum1=vbuc1 
    lda #8
    sta printf_string.format_min_length
    jsr printf_string
    // [946] phi from display_info_smc::@9 to display_info_smc::@10 [phi:display_info_smc::@9->display_info_smc::@10]
    // display_info_smc::@10
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [947] call printf_str
    // [1125] phi from display_info_smc::@10 to printf_str [phi:display_info_smc::@10->printf_str]
    // [1125] phi printf_str::putc#79 = &cputc [phi:display_info_smc::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = display_info_smc::s2 [phi:display_info_smc::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@11
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [948] printf_uint::uvalue#0 = smc_bootloader#14 -- vwum1=vwum2 
    lda smc_bootloader_1
    sta printf_uint.uvalue
    lda smc_bootloader_1+1
    sta printf_uint.uvalue+1
    // [949] call printf_uint
    // [2015] phi from display_info_smc::@11 to printf_uint [phi:display_info_smc::@11->printf_uint]
    // [2015] phi printf_uint::format_zero_padding#10 = 0 [phi:display_info_smc::@11->printf_uint#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uint.format_zero_padding
    // [2015] phi printf_uint::format_min_length#10 = 0 [phi:display_info_smc::@11->printf_uint#1] -- vbum1=vbuc1 
    sta printf_uint.format_min_length
    // [2015] phi printf_uint::putc#10 = &cputc [phi:display_info_smc::@11->printf_uint#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uint.putc
    lda #>cputc
    sta.z printf_uint.putc+1
    // [2015] phi printf_uint::format_radix#10 = DECIMAL [phi:display_info_smc::@11->printf_uint#3] -- vbuxx=vbuc1 
    ldx #DECIMAL
    // [2015] phi printf_uint::uvalue#10 = printf_uint::uvalue#0 [phi:display_info_smc::@11->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [950] phi from display_info_smc::@11 to display_info_smc::@12 [phi:display_info_smc::@11->display_info_smc::@12]
    // display_info_smc::@12
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [951] call printf_str
    // [1125] phi from display_info_smc::@12 to printf_str [phi:display_info_smc::@12->printf_str]
    // [1125] phi printf_str::putc#79 = &cputc [phi:display_info_smc::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = s [phi:display_info_smc::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s
    sta.z printf_str.s
    lda #>@s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@13
    // if(info_text)
    // [952] if((char *)0==display_info_smc::info_text#24) goto display_info_smc::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // [953] phi from display_info_smc::@13 to display_info_smc::@2 [phi:display_info_smc::@13->display_info_smc::@2]
    // display_info_smc::@2
    // gotoxy(INFO_X+64-28, INFO_Y)
    // [954] call gotoxy
    // [805] phi from display_info_smc::@2 to gotoxy [phi:display_info_smc::@2->gotoxy]
    // [805] phi gotoxy::y#37 = $11 [phi:display_info_smc::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #$11
    sta gotoxy.y
    // [805] phi gotoxy::x#37 = 4+$40-$1c [phi:display_info_smc::@2->gotoxy#1] -- vbuyy=vbuc1 
    ldy #4+$40-$1c
    jsr gotoxy
    // display_info_smc::@14
    // printf("%-25s", info_text)
    // [955] printf_string::str#5 = display_info_smc::info_text#24 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [956] call printf_string
    // [1419] phi from display_info_smc::@14 to printf_string [phi:display_info_smc::@14->printf_string]
    // [1419] phi printf_string::putc#26 = &cputc [phi:display_info_smc::@14->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1419] phi printf_string::str#26 = printf_string::str#5 [phi:display_info_smc::@14->printf_string#1] -- register_copy 
    // [1419] phi printf_string::format_justify_left#26 = 1 [phi:display_info_smc::@14->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1419] phi printf_string::format_min_length#26 = $19 [phi:display_info_smc::@14->printf_string#3] -- vbum1=vbuc1 
    lda #$19
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_smc::@1
  __b1:
    // gotoxy(x, y)
    // [957] gotoxy::x#14 = display_info_smc::x#0 -- vbuyy=vbum1 
    ldy x
    // [958] gotoxy::y#14 = display_info_smc::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [959] call gotoxy
    // [805] phi from display_info_smc::@1 to gotoxy [phi:display_info_smc::@1->gotoxy]
    // [805] phi gotoxy::y#37 = gotoxy::y#14 [phi:display_info_smc::@1->gotoxy#0] -- register_copy 
    // [805] phi gotoxy::x#37 = gotoxy::x#14 [phi:display_info_smc::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_smc::@return
    // }
    // [960] return 
    rts
  .segment Data
    s: .text "SMC  "
    .byte 0
    s1: .text " ATTiny "
    .byte 0
    s2: .text " BL:"
    .byte 0
    x: .byte 0
    y: .byte 0
}
.segment CodeVera
  // main_vera_detect
//#pragma data_seg(DataVera)
main_vera_detect: {
    // w25q16_detect()
    // [962] call w25q16_detect
    // [2223] phi from main_vera_detect to w25q16_detect [phi:main_vera_detect->w25q16_detect]
    jsr w25q16_detect
    // [963] phi from main_vera_detect to main_vera_detect::@1 [phi:main_vera_detect->main_vera_detect::@1]
    // main_vera_detect::@1
    // display_chip_vera()
    // [964] call display_chip_vera
    // [2153] phi from main_vera_detect::@1 to display_chip_vera [phi:main_vera_detect::@1->display_chip_vera]
    jsr display_chip_vera
    // [965] phi from main_vera_detect::@1 to main_vera_detect::@2 [phi:main_vera_detect::@1->main_vera_detect::@2]
    // main_vera_detect::@2
    // display_info_vera(STATUS_DETECTED, NULL)
    // [966] call display_info_vera
    // [1930] phi from main_vera_detect::@2 to display_info_vera [phi:main_vera_detect::@2->display_info_vera]
    // [1930] phi display_info_vera::info_text#15 = 0 [phi:main_vera_detect::@2->display_info_vera#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_vera.info_text
    sta.z display_info_vera.info_text+1
    // [1930] phi display_info_vera::info_status#15 = STATUS_DETECTED [phi:main_vera_detect::@2->display_info_vera#1] -- vbum1=vbuc1 
    lda #STATUS_DETECTED
    sta display_info_vera.info_status
    jsr display_info_vera
    // main_vera_detect::@return
    // }
    // [967] return 
    rts
}
.segment Code
  // rom_detect
rom_detect: {
    .const bank_set_brom1_bank = 4
    // [969] phi from rom_detect to rom_detect::@1 [phi:rom_detect->rom_detect::@1]
    // [969] phi rom_detect::rom_chip#10 = 0 [phi:rom_detect->rom_detect::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // [969] phi rom_detect::rom_detect_address#10 = 0 [phi:rom_detect->rom_detect::@1#1] -- vdum1=vduc1 
    sta rom_detect_address
    sta rom_detect_address+1
    lda #<0>>$10
    sta rom_detect_address+2
    lda #>0>>$10
    sta rom_detect_address+3
  // Ensure the ROM is set to BASIC.
  // bank_set_brom(4);
    // rom_detect::@1
  __b1:
    // for (unsigned long rom_detect_address = 0; rom_detect_address < 8 * 0x80000; rom_detect_address += 0x80000)
    // [970] if(rom_detect::rom_detect_address#10<8*$80000) goto rom_detect::@2 -- vdum1_lt_vduc1_then_la1 
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
    // [971] return 
    rts
    // rom_detect::@2
  __b2:
    // rom_manufacturer_ids[rom_chip] = 0
    // [972] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = 0
    // [973] rom_device_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta rom_device_ids,y
    // rom_unlock(rom_detect_address + 0x05555, 0x90)
    // [974] rom_unlock::address#2 = rom_detect::rom_detect_address#10 + $5555 -- vduz1=vdum2_plus_vwuc1 
    clc
    lda rom_detect_address
    adc #<$5555
    sta.z rom_unlock.address
    lda rom_detect_address+1
    adc #>$5555
    sta.z rom_unlock.address+1
    lda rom_detect_address+2
    adc #0
    sta.z rom_unlock.address+2
    lda rom_detect_address+3
    adc #0
    sta.z rom_unlock.address+3
    // [975] call rom_unlock
    // [2228] phi from rom_detect::@2 to rom_unlock [phi:rom_detect::@2->rom_unlock]
    // [2228] phi rom_unlock::unlock_code#5 = $90 [phi:rom_detect::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$90
    sta.z rom_unlock.unlock_code
    // [2228] phi rom_unlock::address#5 = rom_unlock::address#2 [phi:rom_detect::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_detect::@12
    // rom_read_byte(rom_detect_address)
    // [976] rom_read_byte::address#0 = rom_detect::rom_detect_address#10 -- vdum1=vdum2 
    lda rom_detect_address
    sta rom_read_byte.address
    lda rom_detect_address+1
    sta rom_read_byte.address+1
    lda rom_detect_address+2
    sta rom_read_byte.address+2
    lda rom_detect_address+3
    sta rom_read_byte.address+3
    // [977] call rom_read_byte
    // [2238] phi from rom_detect::@12 to rom_read_byte [phi:rom_detect::@12->rom_read_byte]
    // [2238] phi rom_read_byte::address#2 = rom_read_byte::address#0 [phi:rom_detect::@12->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(rom_detect_address)
    // [978] rom_read_byte::return#2 = rom_read_byte::return#0
    // rom_detect::@13
    // [979] rom_detect::$3 = rom_read_byte::return#2
    // rom_manufacturer_ids[rom_chip] = rom_read_byte(rom_detect_address)
    // [980] rom_manufacturer_ids[rom_detect::rom_chip#10] = rom_detect::$3 -- pbuc1_derefidx_vbum1=vbuaa 
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_read_byte(rom_detect_address + 1)
    // [981] rom_read_byte::address#1 = rom_detect::rom_detect_address#10 + 1 -- vdum1=vdum2_plus_1 
    lda rom_detect_address
    clc
    adc #1
    sta rom_read_byte.address
    lda rom_detect_address+1
    adc #0
    sta rom_read_byte.address+1
    lda rom_detect_address+2
    adc #0
    sta rom_read_byte.address+2
    lda rom_detect_address+3
    adc #0
    sta rom_read_byte.address+3
    // [982] call rom_read_byte
    // [2238] phi from rom_detect::@13 to rom_read_byte [phi:rom_detect::@13->rom_read_byte]
    // [2238] phi rom_read_byte::address#2 = rom_read_byte::address#1 [phi:rom_detect::@13->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(rom_detect_address + 1)
    // [983] rom_read_byte::return#3 = rom_read_byte::return#0
    // rom_detect::@14
    // [984] rom_detect::$5 = rom_read_byte::return#3
    // rom_device_ids[rom_chip] = rom_read_byte(rom_detect_address + 1)
    // [985] rom_device_ids[rom_detect::rom_chip#10] = rom_detect::$5 -- pbuc1_derefidx_vbum1=vbuaa 
    ldy rom_chip
    sta rom_device_ids,y
    // rom_unlock(rom_detect_address + 0x05555, 0xF0)
    // [986] rom_unlock::address#3 = rom_detect::rom_detect_address#10 + $5555 -- vduz1=vdum2_plus_vwuc1 
    clc
    lda rom_detect_address
    adc #<$5555
    sta.z rom_unlock.address
    lda rom_detect_address+1
    adc #>$5555
    sta.z rom_unlock.address+1
    lda rom_detect_address+2
    adc #0
    sta.z rom_unlock.address+2
    lda rom_detect_address+3
    adc #0
    sta.z rom_unlock.address+3
    // [987] call rom_unlock
    // [2228] phi from rom_detect::@14 to rom_unlock [phi:rom_detect::@14->rom_unlock]
    // [2228] phi rom_unlock::unlock_code#5 = $f0 [phi:rom_detect::@14->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$f0
    sta.z rom_unlock.unlock_code
    // [2228] phi rom_unlock::address#5 = rom_unlock::address#3 [phi:rom_detect::@14->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_detect::bank_set_brom1
    // BROM = bank
    // [988] BROM = rom_detect::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // rom_detect::@11
    // rom_chip*3
    // [989] rom_detect::$14 = rom_detect::rom_chip#10 << 1 -- vbum1=vbum2_rol_1 
    lda rom_chip
    asl
    sta rom_detect__14
    // [990] rom_detect::$9 = rom_detect::$14 + rom_detect::rom_chip#10 -- vbuaa=vbum1_plus_vbum2 
    clc
    adc rom_chip
    // gotoxy(rom_chip*3+40, 1)
    // [991] gotoxy::x#26 = rom_detect::$9 + $28 -- vbuyy=vbuaa_plus_vbuc1 
    clc
    adc #$28
    tay
    // [992] call gotoxy
    // [805] phi from rom_detect::@11 to gotoxy [phi:rom_detect::@11->gotoxy]
    // [805] phi gotoxy::y#37 = 1 [phi:rom_detect::@11->gotoxy#0] -- vbum1=vbuc1 
    lda #1
    sta gotoxy.y
    // [805] phi gotoxy::x#37 = gotoxy::x#26 [phi:rom_detect::@11->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_detect::@15
    // printf("%02x", rom_device_ids[rom_chip])
    // [993] printf_uchar::uvalue#10 = rom_device_ids[rom_detect::rom_chip#10] -- vbuxx=pbuc1_derefidx_vbum1 
    ldy rom_chip
    ldx rom_device_ids,y
    // [994] call printf_uchar
    // [1189] phi from rom_detect::@15 to printf_uchar [phi:rom_detect::@15->printf_uchar]
    // [1189] phi printf_uchar::format_zero_padding#15 = 1 [phi:rom_detect::@15->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1189] phi printf_uchar::format_min_length#15 = 2 [phi:rom_detect::@15->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1189] phi printf_uchar::putc#15 = &cputc [phi:rom_detect::@15->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1189] phi printf_uchar::format_radix#15 = HEXADECIMAL [phi:rom_detect::@15->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #HEXADECIMAL
    // [1189] phi printf_uchar::uvalue#15 = printf_uchar::uvalue#10 [phi:rom_detect::@15->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // rom_detect::@16
    // case SST39SF010A:
    //             rom_device_names[rom_chip] = "f010a";
    //             rom_size_strings[rom_chip] = "128";
    //             rom_sizes[rom_chip] = 128 * 1024;
    //             break;
    // [995] if(rom_device_ids[rom_detect::rom_chip#10]==$b5) goto rom_detect::@3 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
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
    // [996] if(rom_device_ids[rom_detect::rom_chip#10]==$b6) goto rom_detect::@4 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
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
    // [997] if(rom_device_ids[rom_detect::rom_chip#10]==$b7) goto rom_detect::@5 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b7
    beq __b5
    // rom_detect::@6
    // rom_manufacturer_ids[rom_chip] = 0
    // [998] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    sta rom_manufacturer_ids,y
    // rom_device_names[rom_chip] = "----"
    // [999] rom_device_names[rom_detect::$14] = rom_detect::$31 -- qbuc1_derefidx_vbum1=pbuc2 
    ldy rom_detect__14
    lda #<rom_detect__31
    sta rom_device_names,y
    lda #>rom_detect__31
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "000"
    // [1000] rom_size_strings[rom_detect::$14] = rom_detect::$32 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__32
    sta rom_size_strings,y
    lda #>rom_detect__32
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 0
    // [1001] rom_detect::$24 = rom_detect::rom_chip#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta rom_detect__24
    // [1002] rom_sizes[rom_detect::$24] = 0 -- pduc1_derefidx_vbum1=vbuc2 
    tay
    lda #0
    sta rom_sizes,y
    sta rom_sizes+1,y
    sta rom_sizes+2,y
    sta rom_sizes+3,y
    // rom_device_ids[rom_chip] = UNKNOWN
    // [1003] rom_device_ids[rom_detect::rom_chip#10] = $55 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$55
    ldy rom_chip
    sta rom_device_ids,y
    // rom_detect::@7
  __b7:
    // rom_chip++;
    // [1004] rom_detect::rom_chip#1 = ++ rom_detect::rom_chip#10 -- vbum1=_inc_vbum1 
    inc rom_chip
    // rom_detect::@8
    // rom_detect_address += 0x80000
    // [1005] rom_detect::rom_detect_address#1 = rom_detect::rom_detect_address#10 + $80000 -- vdum1=vdum1_plus_vduc1 
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
    // [969] phi from rom_detect::@8 to rom_detect::@1 [phi:rom_detect::@8->rom_detect::@1]
    // [969] phi rom_detect::rom_chip#10 = rom_detect::rom_chip#1 [phi:rom_detect::@8->rom_detect::@1#0] -- register_copy 
    // [969] phi rom_detect::rom_detect_address#10 = rom_detect::rom_detect_address#1 [phi:rom_detect::@8->rom_detect::@1#1] -- register_copy 
    jmp __b1
    // rom_detect::@5
  __b5:
    // rom_device_names[rom_chip] = "f040"
    // [1006] rom_device_names[rom_detect::$14] = rom_detect::$29 -- qbuc1_derefidx_vbum1=pbuc2 
    ldy rom_detect__14
    lda #<rom_detect__29
    sta rom_device_names,y
    lda #>rom_detect__29
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "512"
    // [1007] rom_size_strings[rom_detect::$14] = rom_detect::$30 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__30
    sta rom_size_strings,y
    lda #>rom_detect__30
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 512 * 1024
    // [1008] rom_detect::$21 = rom_detect::rom_chip#10 << 2 -- vbuaa=vbum1_rol_2 
    lda rom_chip
    asl
    asl
    // [1009] rom_sizes[rom_detect::$21] = (unsigned long)$200*$400 -- pduc1_derefidx_vbuaa=vduc2 
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
    // [1010] rom_device_names[rom_detect::$14] = rom_detect::$27 -- qbuc1_derefidx_vbum1=pbuc2 
    ldy rom_detect__14
    lda #<rom_detect__27
    sta rom_device_names,y
    lda #>rom_detect__27
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "256"
    // [1011] rom_size_strings[rom_detect::$14] = rom_detect::$28 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__28
    sta rom_size_strings,y
    lda #>rom_detect__28
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 256 * 1024
    // [1012] rom_detect::$18 = rom_detect::rom_chip#10 << 2 -- vbuaa=vbum1_rol_2 
    lda rom_chip
    asl
    asl
    // [1013] rom_sizes[rom_detect::$18] = (unsigned long)$100*$400 -- pduc1_derefidx_vbuaa=vduc2 
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
    // [1014] rom_device_names[rom_detect::$14] = rom_detect::$25 -- qbuc1_derefidx_vbum1=pbuc2 
    ldy rom_detect__14
    lda #<rom_detect__25
    sta rom_device_names,y
    lda #>rom_detect__25
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "128"
    // [1015] rom_size_strings[rom_detect::$14] = rom_detect::$26 -- qbuc1_derefidx_vbum1=pbuc2 
    lda #<rom_detect__26
    sta rom_size_strings,y
    lda #>rom_detect__26
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 128 * 1024
    // [1016] rom_detect::$15 = rom_detect::rom_chip#10 << 2 -- vbuaa=vbum1_rol_2 
    lda rom_chip
    asl
    asl
    // [1017] rom_sizes[rom_detect::$15] = (unsigned long)$80*$400 -- pduc1_derefidx_vbuaa=vduc2 
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
    rom_detect__24: .byte 0
    .label rom_chip = main_vera_flash.spi_ensure_detect
    .label rom_detect_address = main.rom_differences
}
.segment Code
  // display_chip_rom
/**
 * @brief Print all ROM chips.
 * 
 */
display_chip_rom: {
    // [1019] phi from display_chip_rom to display_chip_rom::@1 [phi:display_chip_rom->display_chip_rom::@1]
    // [1019] phi display_chip_rom::r#2 = 0 [phi:display_chip_rom->display_chip_rom::@1#0] -- vbum1=vbuc1 
    lda #0
    sta r
    // display_chip_rom::@1
  __b1:
    // for (unsigned char r = 0; r < 8; r++)
    // [1020] if(display_chip_rom::r#2<8) goto display_chip_rom::@2 -- vbum1_lt_vbuc1_then_la1 
    lda r
    cmp #8
    bcc __b2
    // display_chip_rom::@return
    // }
    // [1021] return 
    rts
    // [1022] phi from display_chip_rom::@1 to display_chip_rom::@2 [phi:display_chip_rom::@1->display_chip_rom::@2]
    // display_chip_rom::@2
  __b2:
    // strcpy(rom, "ROM  ")
    // [1023] call strcpy
    // [890] phi from display_chip_rom::@2 to strcpy [phi:display_chip_rom::@2->strcpy]
    // [890] phi strcpy::dst#0 = display_chip_rom::rom [phi:display_chip_rom::@2->strcpy#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z strcpy.dst
    lda #>rom
    sta.z strcpy.dst+1
    // [890] phi strcpy::src#0 = display_chip_rom::source [phi:display_chip_rom::@2->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // display_chip_rom::@5
    // strcat(rom, rom_size_strings[r])
    // [1024] display_chip_rom::$11 = display_chip_rom::r#2 << 1 -- vbum1=vbum2_rol_1 
    lda r
    asl
    sta display_chip_rom__11
    // [1025] strcat::source#0 = rom_size_strings[display_chip_rom::$11] -- pbuz1=qbuc1_derefidx_vbum2 
    tay
    lda rom_size_strings,y
    sta.z strcat.source
    lda rom_size_strings+1,y
    sta.z strcat.source+1
    // [1026] call strcat
    // [2250] phi from display_chip_rom::@5 to strcat [phi:display_chip_rom::@5->strcat]
    jsr strcat
    // display_chip_rom::@6
    // if(r)
    // [1027] if(0==display_chip_rom::r#2) goto display_chip_rom::@3 -- 0_eq_vbum1_then_la1 
    lda r
    beq __b3
    // display_chip_rom::@4
    // r+'0'
    // [1028] display_chip_rom::$4 = display_chip_rom::r#2 + '0' -- vbuaa=vbum1_plus_vbuc1 
    lda #'0'
    clc
    adc r
    // *(rom+3) = r+'0'
    // [1029] *(display_chip_rom::rom+3) = display_chip_rom::$4 -- _deref_pbuc1=vbuaa 
    sta rom+3
    // display_chip_rom::@3
  __b3:
    // display_rom_led(r, GREY)
    // [1030] display_rom_led::chip#0 = display_chip_rom::r#2 -- vbuz1=vbum2 
    lda r
    sta.z display_rom_led.chip
    // [1031] call display_rom_led
    // [2262] phi from display_chip_rom::@3 to display_rom_led [phi:display_chip_rom::@3->display_rom_led]
    // [2262] phi display_rom_led::c#2 = GREY [phi:display_chip_rom::@3->display_rom_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z display_rom_led.c
    // [2262] phi display_rom_led::chip#2 = display_rom_led::chip#0 [phi:display_chip_rom::@3->display_rom_led#1] -- register_copy 
    jsr display_rom_led
    // display_chip_rom::@7
    // r*6
    // [1032] display_chip_rom::$12 = display_chip_rom::$11 + display_chip_rom::r#2 -- vbuaa=vbum1_plus_vbum2 
    lda display_chip_rom__11
    clc
    adc r
    // [1033] display_chip_rom::$6 = display_chip_rom::$12 << 1 -- vbuaa=vbuaa_rol_1 
    asl
    // display_print_chip(CHIP_ROM_X+r*6, CHIP_ROM_Y+2, CHIP_ROM_W, rom)
    // [1034] display_print_chip::x#2 = $14 + display_chip_rom::$6 -- vbuz1=vbuc1_plus_vbuaa 
    clc
    adc #$14
    sta.z display_print_chip.x
    // [1035] call display_print_chip
    // [2175] phi from display_chip_rom::@7 to display_print_chip [phi:display_chip_rom::@7->display_print_chip]
    // [2175] phi display_print_chip::text#11 = display_chip_rom::rom [phi:display_chip_rom::@7->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z display_print_chip.text_2
    lda #>rom
    sta.z display_print_chip.text_2+1
    // [2175] phi display_print_chip::w#10 = 3 [phi:display_chip_rom::@7->display_print_chip#1] -- vbum1=vbuc1 
    lda #3
    sta display_print_chip.w
    // [2175] phi display_print_chip::x#10 = display_print_chip::x#2 [phi:display_chip_rom::@7->display_print_chip#2] -- register_copy 
    jsr display_print_chip
    // display_chip_rom::@8
    // for (unsigned char r = 0; r < 8; r++)
    // [1036] display_chip_rom::r#1 = ++ display_chip_rom::r#2 -- vbum1=_inc_vbum1 
    inc r
    // [1019] phi from display_chip_rom::@8 to display_chip_rom::@1 [phi:display_chip_rom::@8->display_chip_rom::@1]
    // [1019] phi display_chip_rom::r#2 = display_chip_rom::r#1 [phi:display_chip_rom::@8->display_chip_rom::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    rom: .fill $10, 0
    source: .text "ROM  "
    .byte 0
    .label r = main_vera_flash.spi_ensure_detect_1
    display_chip_rom__11: .byte 0
}
.segment Code
  // display_progress_clear
/**
 * @brief Clean the progress area for the flashing.
 */
display_progress_clear: {
    .const h = PROGRESS_Y+PROGRESS_H
    .label x = $bd
    .label i = $b4
    .label y = $d3
    // textcolor(WHITE)
    // [1038] call textcolor
    // [787] phi from display_progress_clear to textcolor [phi:display_progress_clear->textcolor]
    // [787] phi textcolor::color#23 = WHITE [phi:display_progress_clear->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [1039] phi from display_progress_clear to display_progress_clear::@5 [phi:display_progress_clear->display_progress_clear::@5]
    // display_progress_clear::@5
    // bgcolor(BLUE)
    // [1040] call bgcolor
    // [792] phi from display_progress_clear::@5 to bgcolor [phi:display_progress_clear::@5->bgcolor]
    // [792] phi bgcolor::color#15 = BLUE [phi:display_progress_clear::@5->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // [1041] phi from display_progress_clear::@5 to display_progress_clear::@1 [phi:display_progress_clear::@5->display_progress_clear::@1]
    // [1041] phi display_progress_clear::y#2 = PROGRESS_Y [phi:display_progress_clear::@5->display_progress_clear::@1#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // display_progress_clear::@1
  __b1:
    // while (y < h)
    // [1042] if(display_progress_clear::y#2<display_progress_clear::h) goto display_progress_clear::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y
    cmp #h
    bcc __b4
    // display_progress_clear::@return
    // }
    // [1043] return 
    rts
    // [1044] phi from display_progress_clear::@1 to display_progress_clear::@2 [phi:display_progress_clear::@1->display_progress_clear::@2]
  __b4:
    // [1044] phi display_progress_clear::x#2 = PROGRESS_X [phi:display_progress_clear::@1->display_progress_clear::@2#0] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z x
    // [1044] phi display_progress_clear::i#2 = 0 [phi:display_progress_clear::@1->display_progress_clear::@2#1] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // display_progress_clear::@2
  __b2:
    // for(unsigned char i = 0; i < w; i++)
    // [1045] if(display_progress_clear::i#2<PROGRESS_W) goto display_progress_clear::@3 -- vbuz1_lt_vbuc1_then_la1 
    lda.z i
    cmp #PROGRESS_W
    bcc __b3
    // display_progress_clear::@4
    // y++;
    // [1046] display_progress_clear::y#1 = ++ display_progress_clear::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [1041] phi from display_progress_clear::@4 to display_progress_clear::@1 [phi:display_progress_clear::@4->display_progress_clear::@1]
    // [1041] phi display_progress_clear::y#2 = display_progress_clear::y#1 [phi:display_progress_clear::@4->display_progress_clear::@1#0] -- register_copy 
    jmp __b1
    // display_progress_clear::@3
  __b3:
    // cputcxy(x, y, ' ')
    // [1047] cputcxy::x#12 = display_progress_clear::x#2 -- vbuyy=vbuz1 
    ldy.z x
    // [1048] cputcxy::y#12 = display_progress_clear::y#2 -- vbuaa=vbuz1 
    lda.z y
    // [1049] call cputcxy
    // [2273] phi from display_progress_clear::@3 to cputcxy [phi:display_progress_clear::@3->cputcxy]
    // [2273] phi cputcxy::c#17 = ' ' [phi:display_progress_clear::@3->cputcxy#0] -- vbuxx=vbuc1 
    ldx #' '
    // [2273] phi cputcxy::y#17 = cputcxy::y#12 [phi:display_progress_clear::@3->cputcxy#1] -- register_copy 
    // [2273] phi cputcxy::x#17 = cputcxy::x#12 [phi:display_progress_clear::@3->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_progress_clear::@6
    // x++;
    // [1050] display_progress_clear::x#1 = ++ display_progress_clear::x#2 -- vbuz1=_inc_vbuz1 
    inc.z x
    // for(unsigned char i = 0; i < w; i++)
    // [1051] display_progress_clear::i#1 = ++ display_progress_clear::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1044] phi from display_progress_clear::@6 to display_progress_clear::@2 [phi:display_progress_clear::@6->display_progress_clear::@2]
    // [1044] phi display_progress_clear::x#2 = display_progress_clear::x#1 [phi:display_progress_clear::@6->display_progress_clear::@2#0] -- register_copy 
    // [1044] phi display_progress_clear::i#2 = display_progress_clear::i#1 [phi:display_progress_clear::@6->display_progress_clear::@2#1] -- register_copy 
    jmp __b2
}
.segment CodeVera
  // main_vera_check
main_vera_check: {
    .label vera_bytes_read = $a9
    // display_action_progress("Checking VERA.BIN ...")
    // [1053] call display_action_progress
    // [1155] phi from main_vera_check to display_action_progress [phi:main_vera_check->display_action_progress]
    // [1155] phi display_action_progress::info_text#30 = main_vera_check::info_text [phi:main_vera_check->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1054] phi from main_vera_check to main_vera_check::@4 [phi:main_vera_check->main_vera_check::@4]
    // main_vera_check::@4
    // unsigned long vera_bytes_read = w25q16_read(STATUS_CHECKING)
    // [1055] call w25q16_read
  // Read the VERA.BIN file.
    // [2281] phi from main_vera_check::@4 to w25q16_read [phi:main_vera_check::@4->w25q16_read]
    // [2281] phi __errno#105 = __errno#113 [phi:main_vera_check::@4->w25q16_read#0] -- register_copy 
    // [2281] phi __stdio_filecount#100 = __stdio_filecount#109 [phi:main_vera_check::@4->w25q16_read#1] -- register_copy 
    // [2281] phi w25q16_read::info_status#12 = STATUS_CHECKING [phi:main_vera_check::@4->w25q16_read#2] -- vbum1=vbuc1 
    lda #STATUS_CHECKING
    sta w25q16_read.info_status
    jsr w25q16_read
    // unsigned long vera_bytes_read = w25q16_read(STATUS_CHECKING)
    // [1056] w25q16_read::return#2 = w25q16_read::return#0
    // main_vera_check::@5
    // [1057] main_vera_check::vera_bytes_read#0 = w25q16_read::return#2
    // wait_moment(10)
    // [1058] call wait_moment
    // [1134] phi from main_vera_check::@5 to wait_moment [phi:main_vera_check::@5->wait_moment]
    // [1134] phi wait_moment::w#17 = $a [phi:main_vera_check::@5->wait_moment#0] -- vbuz1=vbuc1 
    lda #$a
    sta.z wait_moment.w
    jsr wait_moment
    // main_vera_check::@6
    // if (!vera_bytes_read)
    // [1059] if(0==main_vera_check::vera_bytes_read#0) goto main_vera_check::@1 -- 0_eq_vduz1_then_la1 
    // In case no file was found, set the status to none and skip to the next, else, mention the amount of bytes read.
    lda.z vera_bytes_read
    ora.z vera_bytes_read+1
    ora.z vera_bytes_read+2
    ora.z vera_bytes_read+3
    beq __b1
    // main_vera_check::@3
    // vera_file_size = vera_bytes_read
    // [1060] vera_file_size#0 = main_vera_check::vera_bytes_read#0 -- vdum1=vduz2 
    // VF5 | VERA.BIN all ok | Display the VERA.BIN release version and github commit id (if any) and set VERA to Flash | Flash
    // We know the file size, so we indicate it in the status panel.
    lda.z vera_bytes_read
    sta vera_file_size
    lda.z vera_bytes_read+1
    sta vera_file_size+1
    lda.z vera_bytes_read+2
    sta vera_file_size+2
    lda.z vera_bytes_read+3
    sta vera_file_size+3
    // sprintf(info_text, "VERA.BIN:%s", "")
    // [1061] call snprintf_init
    // [1184] phi from main_vera_check::@3 to snprintf_init [phi:main_vera_check::@3->snprintf_init]
    // [1184] phi snprintf_init::s#30 = info_text [phi:main_vera_check::@3->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1062] phi from main_vera_check::@3 to main_vera_check::@7 [phi:main_vera_check::@3->main_vera_check::@7]
    // main_vera_check::@7
    // sprintf(info_text, "VERA.BIN:%s", "")
    // [1063] call printf_str
    // [1125] phi from main_vera_check::@7 to printf_str [phi:main_vera_check::@7->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:main_vera_check::@7->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = main_vera_check::s [phi:main_vera_check::@7->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // [1064] phi from main_vera_check::@7 to main_vera_check::@8 [phi:main_vera_check::@7->main_vera_check::@8]
    // main_vera_check::@8
    // sprintf(info_text, "VERA.BIN:%s", "")
    // [1065] call printf_string
    // [1419] phi from main_vera_check::@8 to printf_string [phi:main_vera_check::@8->printf_string]
    // [1419] phi printf_string::putc#26 = &snputc [phi:main_vera_check::@8->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1419] phi printf_string::str#26 = str [phi:main_vera_check::@8->printf_string#1] -- pbuz1=pbuc1 
    lda #<str
    sta.z printf_string.str
    lda #>str
    sta.z printf_string.str+1
    // [1419] phi printf_string::format_justify_left#26 = 0 [phi:main_vera_check::@8->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1419] phi printf_string::format_min_length#26 = 0 [phi:main_vera_check::@8->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // main_vera_check::@9
    // sprintf(info_text, "VERA.BIN:%s", "")
    // [1066] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1067] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_vera(STATUS_FLASH, info_text)
    // [1069] call display_info_vera
    // [1930] phi from main_vera_check::@9 to display_info_vera [phi:main_vera_check::@9->display_info_vera]
    // [1930] phi display_info_vera::info_text#15 = info_text [phi:main_vera_check::@9->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_vera.info_text
    lda #>@info_text
    sta.z display_info_vera.info_text+1
    // [1930] phi display_info_vera::info_status#15 = STATUS_FLASH [phi:main_vera_check::@9->display_info_vera#1] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_vera.info_status
    jsr display_info_vera
    // [1070] phi from main_vera_check::@9 to main_vera_check::@2 [phi:main_vera_check::@9->main_vera_check::@2]
    // [1070] phi vera_file_size#1 = vera_file_size#0 [phi:main_vera_check::@9->main_vera_check::@2#0] -- register_copy 
    // main_vera_check::@2
    // main_vera_check::@return
    // }
    // [1071] return 
    rts
    // [1072] phi from main_vera_check::@6 to main_vera_check::@1 [phi:main_vera_check::@6->main_vera_check::@1]
    // main_vera_check::@1
  __b1:
    // display_info_vera(STATUS_SKIP, "No VERA.BIN")
    // [1073] call display_info_vera
  // VF1 | no VERA.BIN  | Ask the user to place the VERA.BIN file onto the SDcard. Set VERA to Issue. | Issue
  // VF2 | VERA.BIN size 0 | Ask the user to place a correct VERA.BIN file onto the SDcard. Set VERA to Issue. | Issue
  // TODO: VF4 | ROM.BIN size over 0x20000 | Ask the user to place a correct VERA.BIN file onto the SDcard. Set VERA to Issue. | Issue
    // [1930] phi from main_vera_check::@1 to display_info_vera [phi:main_vera_check::@1->display_info_vera]
    // [1930] phi display_info_vera::info_text#15 = main_vera_check::info_text1 [phi:main_vera_check::@1->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_vera.info_text
    lda #>info_text1
    sta.z display_info_vera.info_text+1
    // [1930] phi display_info_vera::info_status#15 = STATUS_SKIP [phi:main_vera_check::@1->display_info_vera#1] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_vera.info_status
    jsr display_info_vera
    // [1070] phi from main_vera_check::@1 to main_vera_check::@2 [phi:main_vera_check::@1->main_vera_check::@2]
    // [1070] phi vera_file_size#1 = 0 [phi:main_vera_check::@1->main_vera_check::@2#0] -- vdum1=vduc1 
    lda #<0
    sta vera_file_size
    sta vera_file_size+1
    lda #<0>>$10
    sta vera_file_size+2
    lda #>0>>$10
    sta vera_file_size+3
    rts
  .segment Data
    info_text: .text "Checking VERA.BIN ..."
    .byte 0
    info_text1: .text "No VERA.BIN"
    .byte 0
    s: .text "VERA.BIN:"
    .byte 0
}
.segment Code
  // smc_supported_rom
/**
 * @brief Search in the smc file header for supported ROM.BIN releases.
 * The first 3 bytes of the smc file header contain the SMC.BIN version, major and minor numbers.
 * 
 * @param rom_release The ROM release to search for.
 * @return unsigned char true if found.
 */
// __register(A) char smc_supported_rom(__register(A) char rom_release)
smc_supported_rom: {
    // [1075] phi from smc_supported_rom to smc_supported_rom::@1 [phi:smc_supported_rom->smc_supported_rom::@1]
    // [1075] phi smc_supported_rom::i#2 = $1f [phi:smc_supported_rom->smc_supported_rom::@1#0] -- vbuyy=vbuc1 
    ldy #$1f
    // smc_supported_rom::@1
  __b1:
    // for(unsigned char i=31; i>3; i--)
    // [1076] if(smc_supported_rom::i#2>=3+1) goto smc_supported_rom::@2 -- vbuyy_ge_vbuc1_then_la1 
    cpy #3+1
    bcs __b2
    // [1078] phi from smc_supported_rom::@1 to smc_supported_rom::@return [phi:smc_supported_rom::@1->smc_supported_rom::@return]
    // [1078] phi smc_supported_rom::return#2 = 0 [phi:smc_supported_rom::@1->smc_supported_rom::@return#0] -- vbuaa=vbuc1 
    lda #0
    rts
    // smc_supported_rom::@2
  __b2:
    // if(smc_file_header[i] == rom_release)
    // [1077] if(smc_file_header[smc_supported_rom::i#2]!=smc_supported_rom::rom_release#0) goto smc_supported_rom::@3 -- pbuc1_derefidx_vbuyy_neq_vbuaa_then_la1 
    cmp smc_file_header,y
    bne __b3
    // [1078] phi from smc_supported_rom::@2 to smc_supported_rom::@return [phi:smc_supported_rom::@2->smc_supported_rom::@return]
    // [1078] phi smc_supported_rom::return#2 = 1 [phi:smc_supported_rom::@2->smc_supported_rom::@return#0] -- vbuaa=vbuc1 
    lda #1
    // smc_supported_rom::@return
    // }
    // [1079] return 
    rts
    // smc_supported_rom::@3
  __b3:
    // for(unsigned char i=31; i>3; i--)
    // [1080] smc_supported_rom::i#1 = -- smc_supported_rom::i#2 -- vbuyy=_dec_vbuyy 
    dey
    // [1075] phi from smc_supported_rom::@3 to smc_supported_rom::@1 [phi:smc_supported_rom::@3->smc_supported_rom::@1]
    // [1075] phi smc_supported_rom::i#2 = smc_supported_rom::i#1 [phi:smc_supported_rom::@3->smc_supported_rom::@1#0] -- register_copy 
    jmp __b1
}
  // strncmp
/// Compares at most the first n bytes of str1 and str2.
/// @param str1 This is the first string to be compared.
/// @param str2 This is the second string to be compared.
/// @param The maximum number of characters to be compared.
/// @return if Return value < 0 then it indicates str1 is less than str2.
///         if Return value > 0 then it indicates str2 is less than str1.
///         if Return value = 0 then it indicates str1 is equal to str2.
// __mem() int strncmp(const char *str1, const char *str2, __mem() unsigned int n)
strncmp: {
    .label s1 = $ad
    .label s2 = $67
    // [1082] phi from strncmp to strncmp::@1 [phi:strncmp->strncmp::@1]
    // [1082] phi strncmp::n#2 = 7 [phi:strncmp->strncmp::@1#0] -- vwum1=vbuc1 
    lda #<7
    sta n
    lda #>7
    sta n+1
    // [1082] phi strncmp::s2#2 = rom_file_github [phi:strncmp->strncmp::@1#1] -- pbuz1=pbuc1 
    lda #<rom_file_github
    sta.z s2
    lda #>rom_file_github
    sta.z s2+1
    // [1082] phi strncmp::s1#2 = rom_github [phi:strncmp->strncmp::@1#2] -- pbuz1=pbuc1 
    lda #<rom_github
    sta.z s1
    lda #>rom_github
    sta.z s1+1
    // strncmp::@1
  __b1:
    // while(*s1==*s2)
    // [1083] if(*strncmp::s1#2==*strncmp::s2#2) goto strncmp::@2 -- _deref_pbuz1_eq__deref_pbuz2_then_la1 
    ldy #0
    lda (s1),y
    cmp (s2),y
    beq __b2
    // strncmp::@3
    // *s1-*s2
    // [1084] strncmp::$0 = *strncmp::s1#2 - *strncmp::s2#2 -- vbuaa=_deref_pbuz1_minus__deref_pbuz2 
    lda (s1),y
    sec
    sbc (s2),y
    // return (int)(signed char)(*s1-*s2);
    // [1085] strncmp::return#0 = (int)(signed char)strncmp::$0 -- vwsm1=_sword_vbsaa 
    sta return
    ora #$7f
    bmi !+
    tya
  !:
    sta return+1
    // [1086] phi from strncmp::@3 to strncmp::@return [phi:strncmp::@3->strncmp::@return]
    // [1086] phi strncmp::return#2 = strncmp::return#0 [phi:strncmp::@3->strncmp::@return#0] -- register_copy 
    rts
    // [1086] phi from strncmp::@2 strncmp::@5 to strncmp::@return [phi:strncmp::@2/strncmp::@5->strncmp::@return]
  __b3:
    // [1086] phi strncmp::return#2 = 0 [phi:strncmp::@2/strncmp::@5->strncmp::@return#0] -- vwsm1=vbsc1 
    lda #<0
    sta return
    sta return+1
    // strncmp::@return
    // }
    // [1087] return 
    rts
    // strncmp::@2
  __b2:
    // n--;
    // [1088] strncmp::n#0 = -- strncmp::n#2 -- vwum1=_dec_vwum1 
    lda n
    bne !+
    dec n+1
  !:
    dec n
    // if(*s1==0 || n==0)
    // [1089] if(*strncmp::s1#2==0) goto strncmp::@return -- _deref_pbuz1_eq_0_then_la1 
    ldy #0
    lda (s1),y
    cmp #0
    beq __b3
    // strncmp::@5
    // [1090] if(strncmp::n#0==0) goto strncmp::@return -- vwum1_eq_0_then_la1 
    lda n
    ora n+1
    beq __b3
    // strncmp::@4
    // s1++;
    // [1091] strncmp::s1#1 = ++ strncmp::s1#2 -- pbuz1=_inc_pbuz1 
    inc.z s1
    bne !+
    inc.z s1+1
  !:
    // s2++;
    // [1092] strncmp::s2#1 = ++ strncmp::s2#2 -- pbuz1=_inc_pbuz1 
    inc.z s2
    bne !+
    inc.z s2+1
  !:
    // [1082] phi from strncmp::@4 to strncmp::@1 [phi:strncmp::@4->strncmp::@1]
    // [1082] phi strncmp::n#2 = strncmp::n#0 [phi:strncmp::@4->strncmp::@1#0] -- register_copy 
    // [1082] phi strncmp::s2#2 = strncmp::s2#1 [phi:strncmp::@4->strncmp::@1#1] -- register_copy 
    // [1082] phi strncmp::s1#2 = strncmp::s1#1 [phi:strncmp::@4->strncmp::@1#2] -- register_copy 
    jmp __b1
  .segment Data
    n: .word 0
    .label return = n
}
.segment Code
  // check_status_roms
/**
 * @brief Check the status of any of the ROMs.
 * 
 * @param status The status to be checked.
 * @return unsigned char true if one chip is equal to the status.
 */
// __register(A) char check_status_roms(__register(X) char status)
check_status_roms: {
    // [1094] phi from check_status_roms to check_status_roms::@1 [phi:check_status_roms->check_status_roms::@1]
    // [1094] phi check_status_roms::rom_chip#2 = 0 [phi:check_status_roms->check_status_roms::@1#0] -- vbuyy=vbuc1 
    ldy #0
    // check_status_roms::@1
  __b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [1095] if(check_status_roms::rom_chip#2<8) goto check_status_roms::check_status_rom1 -- vbuyy_lt_vbuc1_then_la1 
    cpy #8
    bcc check_status_rom1
    // [1096] phi from check_status_roms::@1 to check_status_roms::@return [phi:check_status_roms::@1->check_status_roms::@return]
    // [1096] phi check_status_roms::return#2 = 0 [phi:check_status_roms::@1->check_status_roms::@return#0] -- vbuaa=vbuc1 
    lda #0
    // check_status_roms::@return
    // }
    // [1097] return 
    rts
    // check_status_roms::check_status_rom1
  check_status_rom1:
    // status_rom[rom_chip] == status
    // [1098] check_status_roms::check_status_rom1_$0 = status_rom[check_status_roms::rom_chip#2] == check_status_roms::status#6 -- vboaa=pbuc1_derefidx_vbuyy_eq_vbuxx 
    txa
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [1099] check_status_roms::check_status_rom1_return#0 = (char)check_status_roms::check_status_rom1_$0
    // check_status_roms::@3
    // if(check_status_rom(rom_chip, status))
    // [1100] if(0==check_status_roms::check_status_rom1_return#0) goto check_status_roms::@2 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b2
    // [1096] phi from check_status_roms::@3 to check_status_roms::@return [phi:check_status_roms::@3->check_status_roms::@return]
    // [1096] phi check_status_roms::return#2 = 1 [phi:check_status_roms::@3->check_status_roms::@return#0] -- vbuaa=vbuc1 
    lda #1
    rts
    // check_status_roms::@2
  __b2:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [1101] check_status_roms::rom_chip#1 = ++ check_status_roms::rom_chip#2 -- vbuyy=_inc_vbuyy 
    iny
    // [1094] phi from check_status_roms::@2 to check_status_roms::@1 [phi:check_status_roms::@2->check_status_roms::@1]
    // [1094] phi check_status_roms::rom_chip#2 = check_status_roms::rom_chip#1 [phi:check_status_roms::@2->check_status_roms::@1#0] -- register_copy 
    jmp __b1
}
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    // unsigned int line_text = __conio.mapbase_offset
    // [1102] clrscr::line_text#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta line_text
    lda __conio+3+1
    sta line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1103] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [1104] clrscr::$0 = *((char *)&__conio+5) | VERA_INC_1 -- vbuaa=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1105] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [1106] clrscr::l#0 = *((char *)&__conio+9) -- vbuxx=_deref_pbuc1 
    ldx __conio+9
    // [1107] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [1107] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [1107] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [1108] clrscr::$1 = byte0  clrscr::ch#0 -- vbuaa=_byte0_vwum1 
    lda ch
    // *VERA_ADDRX_L = BYTE0(ch)
    // [1109] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbuaa 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [1110] clrscr::$2 = byte1  clrscr::ch#0 -- vbuaa=_byte1_vwum1 
    lda ch+1
    // *VERA_ADDRX_M = BYTE1(ch)
    // [1111] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth+1
    // [1112] clrscr::c#0 = *((char *)&__conio+8) + 1 -- vbuyy=_deref_pbuc1_plus_1 
    ldy __conio+8
    iny
    // [1113] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [1113] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [1114] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1115] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [1116] clrscr::c#1 = -- clrscr::c#2 -- vbuyy=_dec_vbuyy 
    dey
    // while(c)
    // [1117] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbuyy_then_la1 
    cpy #0
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [1118] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda line_text
    adc __conio+$a
    sta line_text
    lda line_text+1
    adc __conio+$a+1
    sta line_text+1
    // l--;
    // [1119] clrscr::l#1 = -- clrscr::l#4 -- vbuxx=_dec_vbuxx 
    dex
    // while(l)
    // [1120] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbuxx_then_la1 
    cpx #0
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [1121] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y = 0
    // [1122] *((char *)&__conio+1) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+1
    // __conio.offset = __conio.mapbase_offset
    // [1123] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+3) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+3
    sta __conio+$13
    lda __conio+3+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [1124] return 
    rts
  .segment Data
    .label line_text = strncmp.n
    .label ch = strncmp.n
}
.segment Code
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($67) void (*putc)(char), __zp($48) const char *s)
printf_str: {
    .label s = $48
    .label putc = $67
    // [1126] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [1126] phi printf_str::s#78 = printf_str::s#79 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [1127] printf_str::c#1 = *printf_str::s#78 -- vbuaa=_deref_pbuz1 
    ldy #0
    lda (s),y
    // [1128] printf_str::s#0 = ++ printf_str::s#78 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [1129] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbuaa_then_la1 
    cmp #0
    bne __b2
    // printf_str::@return
    // }
    // [1130] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [1131] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbuaa 
    pha
    // [1132] callexecute *printf_str::putc#79  -- call__deref_pprz1 
    jsr icall15
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
    // Outside Flow
  icall15:
    jmp (putc)
}
  // wait_moment
/**
 * @brief 
 * 
 */
// void wait_moment(__zp($7d) char w)
wait_moment: {
    .label i = $48
    .label j = $71
    .label w = $7d
    // [1135] phi from wait_moment to wait_moment::@1 [phi:wait_moment->wait_moment::@1]
    // [1135] phi wait_moment::j#2 = 0 [phi:wait_moment->wait_moment::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z j
    // wait_moment::@1
  __b1:
    // for(unsigned char j=0; j<w; j++)
    // [1136] if(wait_moment::j#2<wait_moment::w#17) goto wait_moment::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z j
    cmp.z w
    bcc __b4
    // wait_moment::@return
    // }
    // [1137] return 
    rts
    // [1138] phi from wait_moment::@1 to wait_moment::@2 [phi:wait_moment::@1->wait_moment::@2]
  __b4:
    // [1138] phi wait_moment::i#2 = $ffff [phi:wait_moment::@1->wait_moment::@2#0] -- vwuz1=vwuc1 
    lda #<$ffff
    sta.z i
    lda #>$ffff
    sta.z i+1
    // wait_moment::@2
  __b2:
    // for(unsigned int i=65535; i>0; i--)
    // [1139] if(wait_moment::i#2>0) goto wait_moment::@3 -- vwuz1_gt_0_then_la1 
    lda.z i+1
    bne __b3
    lda.z i
    bne __b3
  !:
    // wait_moment::@4
    // for(unsigned char j=0; j<w; j++)
    // [1140] wait_moment::j#1 = ++ wait_moment::j#2 -- vbuz1=_inc_vbuz1 
    inc.z j
    // [1135] phi from wait_moment::@4 to wait_moment::@1 [phi:wait_moment::@4->wait_moment::@1]
    // [1135] phi wait_moment::j#2 = wait_moment::j#1 [phi:wait_moment::@4->wait_moment::@1#0] -- register_copy 
    jmp __b1
    // wait_moment::@3
  __b3:
    // for(unsigned int i=65535; i>0; i--)
    // [1141] wait_moment::i#1 = -- wait_moment::i#2 -- vwuz1=_dec_vwuz1 
    lda.z i
    bne !+
    dec.z i+1
  !:
    dec.z i
    // [1138] phi from wait_moment::@3 to wait_moment::@2 [phi:wait_moment::@3->wait_moment::@2]
    // [1138] phi wait_moment::i#2 = wait_moment::i#1 [phi:wait_moment::@3->wait_moment::@2#0] -- register_copy 
    jmp __b2
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
    // [1143] BRAM = system_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // system_reset::bank_set_brom1
    // BROM = bank
    // [1144] BROM = system_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // system_reset::@2
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // [1146] phi from system_reset::@1 system_reset::@2 to system_reset::@1 [phi:system_reset::@1/system_reset::@2->system_reset::@1]
    // system_reset::@1
  __b1:
    jmp __b1
}
  // check_status_roms_less
/**
 * @brief Check the status of all the ROMs.
 * 
 * @param status The status to be checked.
 * @return unsigned char true if all chips are equal to the status.
 */
// __register(A) char check_status_roms_less(char status)
check_status_roms_less: {
    // [1148] phi from check_status_roms_less to check_status_roms_less::@1 [phi:check_status_roms_less->check_status_roms_less::@1]
    // [1148] phi check_status_roms_less::rom_chip#2 = 0 [phi:check_status_roms_less->check_status_roms_less::@1#0] -- vbuxx=vbuc1 
    ldx #0
    // check_status_roms_less::@1
  __b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [1149] if(check_status_roms_less::rom_chip#2<8) goto check_status_roms_less::@2 -- vbuxx_lt_vbuc1_then_la1 
    cpx #8
    bcc __b2
    // [1152] phi from check_status_roms_less::@1 to check_status_roms_less::@return [phi:check_status_roms_less::@1->check_status_roms_less::@return]
    // [1152] phi check_status_roms_less::return#2 = 1 [phi:check_status_roms_less::@1->check_status_roms_less::@return#0] -- vbuaa=vbuc1 
    lda #1
    rts
    // check_status_roms_less::@2
  __b2:
    // status_rom[rom_chip] > status
    // [1150] check_status_roms_less::$1 = status_rom[check_status_roms_less::rom_chip#2] > STATUS_SKIP -- vboaa=pbuc1_derefidx_vbuxx_gt_vbuc2 
    lda status_rom,x
    cmp #STATUS_SKIP
    lda #0
    rol
    // if((unsigned char)(status_rom[rom_chip] > status))
    // [1151] if(0==(char)check_status_roms_less::$1) goto check_status_roms_less::@3 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b3
    // [1152] phi from check_status_roms_less::@2 to check_status_roms_less::@return [phi:check_status_roms_less::@2->check_status_roms_less::@return]
    // [1152] phi check_status_roms_less::return#2 = 0 [phi:check_status_roms_less::@2->check_status_roms_less::@return#0] -- vbuaa=vbuc1 
    lda #0
    // check_status_roms_less::@return
    // }
    // [1153] return 
    rts
    // check_status_roms_less::@3
  __b3:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [1154] check_status_roms_less::rom_chip#1 = ++ check_status_roms_less::rom_chip#2 -- vbuxx=_inc_vbuxx 
    inx
    // [1148] phi from check_status_roms_less::@3 to check_status_roms_less::@1 [phi:check_status_roms_less::@3->check_status_roms_less::@1]
    // [1148] phi check_status_roms_less::rom_chip#2 = check_status_roms_less::rom_chip#1 [phi:check_status_roms_less::@3->check_status_roms_less::@1#0] -- register_copy 
    jmp __b1
}
  // display_action_progress
/**
 * @brief Print the progress at the action frame, which is the first line.
 * 
 * @param info_text The progress text to be displayed.
 */
// void display_action_progress(__zp($48) char *info_text)
display_action_progress: {
    .label info_text = $48
    // unsigned char x = wherex()
    // [1156] call wherex
    jsr wherex
    // [1157] wherex::return#2 = wherex::return#0
    // display_action_progress::@1
    // [1158] display_action_progress::x#0 = wherex::return#2 -- vbum1=vbuaa 
    sta x
    // unsigned char y = wherey()
    // [1159] call wherey
    jsr wherey
    // [1160] wherey::return#2 = wherey::return#0
    // display_action_progress::@2
    // [1161] display_action_progress::y#0 = wherey::return#2 -- vbum1=vbuaa 
    sta y
    // gotoxy(2, PROGRESS_Y-4)
    // [1162] call gotoxy
    // [805] phi from display_action_progress::@2 to gotoxy [phi:display_action_progress::@2->gotoxy]
    // [805] phi gotoxy::y#37 = PROGRESS_Y-4 [phi:display_action_progress::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-4
    sta gotoxy.y
    // [805] phi gotoxy::x#37 = 2 [phi:display_action_progress::@2->gotoxy#1] -- vbuyy=vbuc1 
    ldy #2
    jsr gotoxy
    // display_action_progress::@3
    // printf("%-65s", info_text)
    // [1163] printf_string::str#1 = display_action_progress::info_text#30
    // [1164] call printf_string
    // [1419] phi from display_action_progress::@3 to printf_string [phi:display_action_progress::@3->printf_string]
    // [1419] phi printf_string::putc#26 = &cputc [phi:display_action_progress::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1419] phi printf_string::str#26 = printf_string::str#1 [phi:display_action_progress::@3->printf_string#1] -- register_copy 
    // [1419] phi printf_string::format_justify_left#26 = 1 [phi:display_action_progress::@3->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1419] phi printf_string::format_min_length#26 = $41 [phi:display_action_progress::@3->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_action_progress::@4
    // gotoxy(x, y)
    // [1165] gotoxy::x#10 = display_action_progress::x#0 -- vbuyy=vbum1 
    ldy x
    // [1166] gotoxy::y#10 = display_action_progress::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1167] call gotoxy
    // [805] phi from display_action_progress::@4 to gotoxy [phi:display_action_progress::@4->gotoxy]
    // [805] phi gotoxy::y#37 = gotoxy::y#10 [phi:display_action_progress::@4->gotoxy#0] -- register_copy 
    // [805] phi gotoxy::x#37 = gotoxy::x#10 [phi:display_action_progress::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_action_progress::@return
    // }
    // [1168] return 
    rts
  .segment Data
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
// void display_progress_text(__zp($3a) char **text, __zp($50) char lines)
display_progress_text: {
    .label l = $af
    .label lines = $50
    .label text = $3a
    // display_progress_clear()
    // [1170] call display_progress_clear
    // [1037] phi from display_progress_text to display_progress_clear [phi:display_progress_text->display_progress_clear]
    jsr display_progress_clear
    // [1171] phi from display_progress_text to display_progress_text::@1 [phi:display_progress_text->display_progress_text::@1]
    // [1171] phi display_progress_text::l#2 = 0 [phi:display_progress_text->display_progress_text::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z l
    // display_progress_text::@1
  __b1:
    // for(unsigned char l=0; l<lines; l++)
    // [1172] if(display_progress_text::l#2<display_progress_text::lines#12) goto display_progress_text::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z l
    cmp.z lines
    bcc __b2
    // display_progress_text::@return
    // }
    // [1173] return 
    rts
    // display_progress_text::@2
  __b2:
    // display_progress_line(l, text[l])
    // [1174] display_progress_text::$3 = display_progress_text::l#2 << 1 -- vbuaa=vbuz1_rol_1 
    lda.z l
    asl
    // [1175] display_progress_line::line#0 = display_progress_text::l#2 -- vbuxx=vbuz1 
    ldx.z l
    // [1176] display_progress_line::text#0 = display_progress_text::text#13[display_progress_text::$3] -- pbuz1=qbuz2_derefidx_vbuaa 
    tay
    lda (text),y
    sta.z display_progress_line.text
    iny
    lda (text),y
    sta.z display_progress_line.text+1
    // [1177] call display_progress_line
    // [1179] phi from display_progress_text::@2 to display_progress_line [phi:display_progress_text::@2->display_progress_line]
    // [1179] phi display_progress_line::text#3 = display_progress_line::text#0 [phi:display_progress_text::@2->display_progress_line#0] -- register_copy 
    // [1179] phi display_progress_line::line#3 = display_progress_line::line#0 [phi:display_progress_text::@2->display_progress_line#1] -- register_copy 
    jsr display_progress_line
    // display_progress_text::@3
    // for(unsigned char l=0; l<lines; l++)
    // [1178] display_progress_text::l#1 = ++ display_progress_text::l#2 -- vbuz1=_inc_vbuz1 
    inc.z l
    // [1171] phi from display_progress_text::@3 to display_progress_text::@1 [phi:display_progress_text::@3->display_progress_text::@1]
    // [1171] phi display_progress_text::l#2 = display_progress_text::l#1 [phi:display_progress_text::@3->display_progress_text::@1#0] -- register_copy 
    jmp __b1
}
  // display_progress_line
/**
 * @brief Print one line of text in the progress frame at a line position.
 * 
 * @param line The start line, counting from 0.
 * @param text The text to be displayed.
 */
// void display_progress_line(__register(X) char line, __zp($76) char *text)
display_progress_line: {
    .label text = $76
    // cputsxy(PROGRESS_X, PROGRESS_Y+line, text)
    // [1180] cputsxy::y#2 = PROGRESS_Y + display_progress_line::line#3 -- vbuxx=vbuc1_plus_vbuxx 
    txa
    clc
    adc #PROGRESS_Y
    tax
    // [1181] cputsxy::s#2 = display_progress_line::text#3
    // [1182] call cputsxy
    // [2146] phi from display_progress_line to cputsxy [phi:display_progress_line->cputsxy]
    // [2146] phi cputsxy::s#4 = cputsxy::s#2 [phi:display_progress_line->cputsxy#0] -- register_copy 
    // [2146] phi cputsxy::y#4 = cputsxy::y#2 [phi:display_progress_line->cputsxy#1] -- register_copy 
    // [2146] phi cputsxy::x#4 = PROGRESS_X [phi:display_progress_line->cputsxy#2] -- vbuyy=vbuc1 
    ldy #PROGRESS_X
    jsr cputsxy
    // display_progress_line::@return
    // }
    // [1183] return 
    rts
}
  // snprintf_init
/// Initialize the snprintf() state
// void snprintf_init(__zp($76) char *s, unsigned int n)
snprintf_init: {
    .label s = $76
    // __snprintf_capacity = n
    // [1185] __snprintf_capacity = $ffff -- vwum1=vwuc1 
    lda #<$ffff
    sta __snprintf_capacity
    lda #>$ffff
    sta __snprintf_capacity+1
    // __snprintf_size = 0
    // [1186] __snprintf_size = 0 -- vwum1=vbuc1 
    lda #<0
    sta __snprintf_size
    sta __snprintf_size+1
    // __snprintf_buffer = s
    // [1187] __snprintf_buffer = snprintf_init::s#30 -- pbuz1=pbuz2 
    lda.z s
    sta.z __snprintf_buffer
    lda.z s+1
    sta.z __snprintf_buffer+1
    // snprintf_init::@return
    // }
    // [1188] return 
    rts
}
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(__zp($67) void (*putc)(char), __register(X) char uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, __register(Y) char format_radix)
printf_uchar: {
    .label putc = $67
    // printf_uchar::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1190] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [1191] uctoa::value#1 = printf_uchar::uvalue#15
    // [1192] uctoa::radix#0 = printf_uchar::format_radix#15
    // [1193] call uctoa
    // Format number into buffer
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1194] printf_number_buffer::putc#2 = printf_uchar::putc#15
    // [1195] printf_number_buffer::buffer_sign#2 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [1196] printf_number_buffer::format_min_length#2 = printf_uchar::format_min_length#15 -- vbuxx=vbum1 
    ldx format_min_length
    // [1197] printf_number_buffer::format_zero_padding#2 = printf_uchar::format_zero_padding#15
    // [1198] call printf_number_buffer
  // Print using format
    // [2362] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [2362] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#2 [phi:printf_uchar::@2->printf_number_buffer#0] -- register_copy 
    // [2362] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#2 [phi:printf_uchar::@2->printf_number_buffer#1] -- register_copy 
    // [2362] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#2 [phi:printf_uchar::@2->printf_number_buffer#2] -- register_copy 
    // [2362] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#2 [phi:printf_uchar::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [1199] return 
    rts
  .segment Data
    format_min_length: .byte 0
    format_zero_padding: .byte 0
}
.segment Code
  // display_action_text
/**
 * @brief Print an info line at the action frame, which is the second line.
 * 
 * @param info_text The info text to be displayed.
 */
// void display_action_text(__zp($7e) char *info_text)
display_action_text: {
    .label info_text = $7e
    .label x = $7a
    .label y = $75
    // unsigned char x = wherex()
    // [1201] call wherex
    jsr wherex
    // [1202] wherex::return#3 = wherex::return#0
    // display_action_text::@1
    // [1203] display_action_text::x#0 = wherex::return#3 -- vbuz1=vbuaa 
    sta.z x
    // unsigned char y = wherey()
    // [1204] call wherey
    jsr wherey
    // [1205] wherey::return#3 = wherey::return#0
    // display_action_text::@2
    // [1206] display_action_text::y#0 = wherey::return#3 -- vbuz1=vbuaa 
    sta.z y
    // gotoxy(2, PROGRESS_Y-3)
    // [1207] call gotoxy
    // [805] phi from display_action_text::@2 to gotoxy [phi:display_action_text::@2->gotoxy]
    // [805] phi gotoxy::y#37 = PROGRESS_Y-3 [phi:display_action_text::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-3
    sta gotoxy.y
    // [805] phi gotoxy::x#37 = 2 [phi:display_action_text::@2->gotoxy#1] -- vbuyy=vbuc1 
    ldy #2
    jsr gotoxy
    // display_action_text::@3
    // printf("%-65s", info_text)
    // [1208] printf_string::str#2 = display_action_text::info_text#25 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1209] call printf_string
    // [1419] phi from display_action_text::@3 to printf_string [phi:display_action_text::@3->printf_string]
    // [1419] phi printf_string::putc#26 = &cputc [phi:display_action_text::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1419] phi printf_string::str#26 = printf_string::str#2 [phi:display_action_text::@3->printf_string#1] -- register_copy 
    // [1419] phi printf_string::format_justify_left#26 = 1 [phi:display_action_text::@3->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1419] phi printf_string::format_min_length#26 = $41 [phi:display_action_text::@3->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_action_text::@4
    // gotoxy(x, y)
    // [1210] gotoxy::x#12 = display_action_text::x#0 -- vbuyy=vbuz1 
    ldy.z x
    // [1211] gotoxy::y#12 = display_action_text::y#0 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [1212] call gotoxy
    // [805] phi from display_action_text::@4 to gotoxy [phi:display_action_text::@4->gotoxy]
    // [805] phi gotoxy::y#37 = gotoxy::y#12 [phi:display_action_text::@4->gotoxy#0] -- register_copy 
    // [805] phi gotoxy::x#37 = gotoxy::x#12 [phi:display_action_text::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_action_text::@return
    // }
    // [1213] return 
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
    // [1215] BRAM = smc_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // smc_reset::bank_set_brom1
    // BROM = bank
    // [1216] BROM = smc_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // smc_reset::@1
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [1217] smc_reset::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [1218] smc_reset::cx16_k_i2c_write_byte1_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte1_offset
    // [1219] smc_reset::cx16_k_i2c_write_byte1_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte1_value
    // smc_reset::cx16_k_i2c_write_byte1
    // unsigned char result
    // [1220] smc_reset::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
    sta cx16_k_i2c_write_byte1_result
    // asm
    // asm { ldxdevice ldyoffset ldavalue stzresult jsrCX16_I2C_WRITE_BYTE rolresult  }
    ldx cx16_k_i2c_write_byte1_device
    ldy cx16_k_i2c_write_byte1_offset
    lda cx16_k_i2c_write_byte1_value
    stz cx16_k_i2c_write_byte1_result
    jsr CX16_I2C_WRITE_BYTE
    rol cx16_k_i2c_write_byte1_result
    // smc_reset::@return
    // }
    // [1222] return 
    rts
  .segment Data
    cx16_k_i2c_write_byte1_device: .byte 0
    cx16_k_i2c_write_byte1_offset: .byte 0
    cx16_k_i2c_write_byte1_value: .byte 0
    cx16_k_i2c_write_byte1_result: .byte 0
}
.segment Code
  // check_status_card_roms
/**
 * @brief Check the status of all card ROMs. 
 * 
 * @param status The status to be checked.
 * @return unsigned char true if one chip is equal to the status.
 */
// __register(A) char check_status_card_roms(char status)
check_status_card_roms: {
    // [1224] phi from check_status_card_roms to check_status_card_roms::@1 [phi:check_status_card_roms->check_status_card_roms::@1]
    // [1224] phi check_status_card_roms::rom_chip#2 = 1 [phi:check_status_card_roms->check_status_card_roms::@1#0] -- vbuxx=vbuc1 
    ldx #1
    // check_status_card_roms::@1
  __b1:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [1225] if(check_status_card_roms::rom_chip#2<8) goto check_status_card_roms::check_status_rom1 -- vbuxx_lt_vbuc1_then_la1 
    cpx #8
    bcc check_status_rom1
    // [1226] phi from check_status_card_roms::@1 to check_status_card_roms::@return [phi:check_status_card_roms::@1->check_status_card_roms::@return]
    // [1226] phi check_status_card_roms::return#2 = 0 [phi:check_status_card_roms::@1->check_status_card_roms::@return#0] -- vbuaa=vbuc1 
    lda #0
    // check_status_card_roms::@return
    // }
    // [1227] return 
    rts
    // check_status_card_roms::check_status_rom1
  check_status_rom1:
    // status_rom[rom_chip] == status
    // [1228] check_status_card_roms::check_status_rom1_$0 = status_rom[check_status_card_roms::rom_chip#2] == STATUS_FLASH -- vboaa=pbuc1_derefidx_vbuxx_eq_vbuc2 
    lda #STATUS_FLASH
    eor status_rom,x
    beq !+
    lda #1
  !:
    eor #1
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [1229] check_status_card_roms::check_status_rom1_return#0 = (char)check_status_card_roms::check_status_rom1_$0
    // check_status_card_roms::@3
    // if(check_status_rom(rom_chip, status))
    // [1230] if(0==check_status_card_roms::check_status_rom1_return#0) goto check_status_card_roms::@2 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b2
    // [1226] phi from check_status_card_roms::@3 to check_status_card_roms::@return [phi:check_status_card_roms::@3->check_status_card_roms::@return]
    // [1226] phi check_status_card_roms::return#2 = 1 [phi:check_status_card_roms::@3->check_status_card_roms::@return#0] -- vbuaa=vbuc1 
    lda #1
    rts
    // check_status_card_roms::@2
  __b2:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [1231] check_status_card_roms::rom_chip#1 = ++ check_status_card_roms::rom_chip#2 -- vbuxx=_inc_vbuxx 
    inx
    // [1224] phi from check_status_card_roms::@2 to check_status_card_roms::@1 [phi:check_status_card_roms::@2->check_status_card_roms::@1]
    // [1224] phi check_status_card_roms::rom_chip#2 = check_status_card_roms::rom_chip#1 [phi:check_status_card_roms::@2->check_status_card_roms::@1#0] -- register_copy 
    jmp __b1
}
.segment CodeVera
  // main_vera_flash
main_vera_flash: {
    .label vera_bytes_read = $a9
    // display_progress_text(display_jp1_spi_vera_text, display_jp1_spi_vera_count)
    // [1233] call display_progress_text
    // [1169] phi from main_vera_flash to display_progress_text [phi:main_vera_flash->display_progress_text]
    // [1169] phi display_progress_text::text#13 = display_jp1_spi_vera_text [phi:main_vera_flash->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_jp1_spi_vera_text
    sta.z display_progress_text.text
    lda #>display_jp1_spi_vera_text
    sta.z display_progress_text.text+1
    // [1169] phi display_progress_text::lines#12 = display_jp1_spi_vera_count [phi:main_vera_flash->display_progress_text#1] -- vbuz1=vbuc1 
    lda #display_jp1_spi_vera_count
    sta.z display_progress_text.lines
    jsr display_progress_text
    // [1234] phi from main_vera_flash to main_vera_flash::@20 [phi:main_vera_flash->main_vera_flash::@20]
    // main_vera_flash::@20
    // util_wait_space()
    // [1235] call util_wait_space
    // [1958] phi from main_vera_flash::@20 to util_wait_space [phi:main_vera_flash::@20->util_wait_space]
    jsr util_wait_space
    // [1236] phi from main_vera_flash::@20 to main_vera_flash::@21 [phi:main_vera_flash::@20->main_vera_flash::@21]
    // main_vera_flash::@21
    // display_progress_clear()
    // [1237] call display_progress_clear
    // [1037] phi from main_vera_flash::@21 to display_progress_clear [phi:main_vera_flash::@21->display_progress_clear]
    jsr display_progress_clear
    // [1238] phi from main_vera_flash::@21 to main_vera_flash::@22 [phi:main_vera_flash::@21->main_vera_flash::@22]
    // main_vera_flash::@22
    // sprintf(info_text, "Reading VERA.BIN ... (.) data ( ) empty")
    // [1239] call snprintf_init
    // [1184] phi from main_vera_flash::@22 to snprintf_init [phi:main_vera_flash::@22->snprintf_init]
    // [1184] phi snprintf_init::s#30 = info_text [phi:main_vera_flash::@22->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1240] phi from main_vera_flash::@22 to main_vera_flash::@23 [phi:main_vera_flash::@22->main_vera_flash::@23]
    // main_vera_flash::@23
    // sprintf(info_text, "Reading VERA.BIN ... (.) data ( ) empty")
    // [1241] call printf_str
    // [1125] phi from main_vera_flash::@23 to printf_str [phi:main_vera_flash::@23->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:main_vera_flash::@23->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = main_vera_flash::s [phi:main_vera_flash::@23->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // main_vera_flash::@24
    // sprintf(info_text, "Reading VERA.BIN ... (.) data ( ) empty")
    // [1242] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1243] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_progress(info_text)
    // [1245] call display_action_progress
    // [1155] phi from main_vera_flash::@24 to display_action_progress [phi:main_vera_flash::@24->display_action_progress]
    // [1155] phi display_action_progress::info_text#30 = info_text [phi:main_vera_flash::@24->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_progress.info_text
    lda #>@info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1246] phi from main_vera_flash::@24 to main_vera_flash::@25 [phi:main_vera_flash::@24->main_vera_flash::@25]
    // main_vera_flash::@25
    // unsigned long vera_bytes_read = w25q16_read(STATUS_READING)
    // [1247] call w25q16_read
    // [2281] phi from main_vera_flash::@25 to w25q16_read [phi:main_vera_flash::@25->w25q16_read]
    // [2281] phi __errno#105 = __errno#115 [phi:main_vera_flash::@25->w25q16_read#0] -- register_copy 
    // [2281] phi __stdio_filecount#100 = __stdio_filecount#111 [phi:main_vera_flash::@25->w25q16_read#1] -- register_copy 
    // [2281] phi w25q16_read::info_status#12 = STATUS_READING [phi:main_vera_flash::@25->w25q16_read#2] -- vbum1=vbuc1 
    lda #STATUS_READING
    sta w25q16_read.info_status
    jsr w25q16_read
    // unsigned long vera_bytes_read = w25q16_read(STATUS_READING)
    // [1248] w25q16_read::return#3 = w25q16_read::return#0
    // main_vera_flash::@26
    // [1249] main_vera_flash::vera_bytes_read#0 = w25q16_read::return#3
    // if(vera_bytes_read)
    // [1250] if(0==main_vera_flash::vera_bytes_read#0) goto main_vera_flash::@1 -- 0_eq_vduz1_then_la1 
    lda.z vera_bytes_read
    ora.z vera_bytes_read+1
    ora.z vera_bytes_read+2
    ora.z vera_bytes_read+3
    bne !__b1+
    jmp __b1
  !__b1:
    // [1251] phi from main_vera_flash::@26 to main_vera_flash::@2 [phi:main_vera_flash::@26->main_vera_flash::@2]
    // main_vera_flash::@2
    // display_action_progress("VERA SPI activation ...")
    // [1252] call display_action_progress
  // Now we loop until jumper JP1 has been placed!
    // [1155] phi from main_vera_flash::@2 to display_action_progress [phi:main_vera_flash::@2->display_action_progress]
    // [1155] phi display_action_progress::info_text#30 = main_vera_flash::info_text [phi:main_vera_flash::@2->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1253] phi from main_vera_flash::@2 to main_vera_flash::@28 [phi:main_vera_flash::@2->main_vera_flash::@28]
    // main_vera_flash::@28
    // display_action_text("Please close the jumper JP1 on the VERA board!")
    // [1254] call display_action_text
    // [1200] phi from main_vera_flash::@28 to display_action_text [phi:main_vera_flash::@28->display_action_text]
    // [1200] phi display_action_text::info_text#25 = main_vera_flash::info_text1 [phi:main_vera_flash::@28->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_action_text.info_text
    lda #>info_text1
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1255] phi from main_vera_flash::@28 main_vera_flash::@7 to main_vera_flash::@3 [phi:main_vera_flash::@28/main_vera_flash::@7->main_vera_flash::@3]
  __b2:
    // [1255] phi main_vera_flash::spi_ensure_detect#11 = 0 [phi:main_vera_flash::@28/main_vera_flash::@7->main_vera_flash::@3#0] -- vbum1=vbuc1 
    lda #0
    sta spi_ensure_detect
    // main_vera_flash::@3
  __b3:
    // while(spi_ensure_detect < 16)
    // [1256] if(main_vera_flash::spi_ensure_detect#11<$10) goto main_vera_flash::@4 -- vbum1_lt_vbuc1_then_la1 
    lda spi_ensure_detect
    cmp #$10
    bcs !__b4+
    jmp __b4
  !__b4:
    // [1257] phi from main_vera_flash::@3 to main_vera_flash::@5 [phi:main_vera_flash::@3->main_vera_flash::@5]
    // main_vera_flash::@5
    // display_action_text("The jumper JP1 has been closed on the VERA!")
    // [1258] call display_action_text
    // [1200] phi from main_vera_flash::@5 to display_action_text [phi:main_vera_flash::@5->display_action_text]
    // [1200] phi display_action_text::info_text#25 = main_vera_flash::info_text2 [phi:main_vera_flash::@5->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z display_action_text.info_text
    lda #>info_text2
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1259] phi from main_vera_flash::@5 to main_vera_flash::@31 [phi:main_vera_flash::@5->main_vera_flash::@31]
    // main_vera_flash::@31
    // display_action_progress("Comparing VERA ... (.) data, (=) same, (*) different.")
    // [1260] call display_action_progress
  // Now we compare the RAM with the actual VERA contents.
    // [1155] phi from main_vera_flash::@31 to display_action_progress [phi:main_vera_flash::@31->display_action_progress]
    // [1155] phi display_action_progress::info_text#30 = main_vera_flash::info_text3 [phi:main_vera_flash::@31->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text3
    sta.z display_action_progress.info_text
    lda #>info_text3
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1261] phi from main_vera_flash::@31 to main_vera_flash::@32 [phi:main_vera_flash::@31->main_vera_flash::@32]
    // main_vera_flash::@32
    // display_info_vera(STATUS_COMPARING, "")
    // [1262] call display_info_vera
    // [1930] phi from main_vera_flash::@32 to display_info_vera [phi:main_vera_flash::@32->display_info_vera]
    // [1930] phi display_info_vera::info_text#15 = str [phi:main_vera_flash::@32->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z display_info_vera.info_text
    lda #>str
    sta.z display_info_vera.info_text+1
    // [1930] phi display_info_vera::info_status#15 = STATUS_COMPARING [phi:main_vera_flash::@32->display_info_vera#1] -- vbum1=vbuc1 
    lda #STATUS_COMPARING
    sta display_info_vera.info_status
    jsr display_info_vera
    // [1263] phi from main_vera_flash::@32 to main_vera_flash::@33 [phi:main_vera_flash::@32->main_vera_flash::@33]
    // main_vera_flash::@33
    // unsigned long vera_differences = w25q16_verify(0)
    // [1264] call w25q16_verify
  // Verify VERA ...
    // [2393] phi from main_vera_flash::@33 to w25q16_verify [phi:main_vera_flash::@33->w25q16_verify]
    // [2393] phi w25q16_verify::verify#2 = 0 [phi:main_vera_flash::@33->w25q16_verify#0] -- vbuxx=vbuc1 
    ldx #0
    jsr w25q16_verify
    // unsigned long vera_differences = w25q16_verify(0)
    // [1265] w25q16_verify::return#2 = w25q16_verify::w25q16_different_bytes#2
    // main_vera_flash::@34
    // [1266] main_vera_flash::vera_differences#0 = w25q16_verify::return#2 -- vdum1=vdum2 
    lda w25q16_verify.return
    sta vera_differences
    lda w25q16_verify.return+1
    sta vera_differences+1
    lda w25q16_verify.return+2
    sta vera_differences+2
    lda w25q16_verify.return+3
    sta vera_differences+3
    // if (!vera_differences)
    // [1267] if(0==main_vera_flash::vera_differences#0) goto main_vera_flash::@10 -- 0_eq_vdum1_then_la1 
    lda vera_differences
    ora vera_differences+1
    ora vera_differences+2
    ora vera_differences+3
    bne !__b10+
    jmp __b10
  !__b10:
    // [1268] phi from main_vera_flash::@34 to main_vera_flash::@8 [phi:main_vera_flash::@34->main_vera_flash::@8]
    // main_vera_flash::@8
    // sprintf(info_text, "%u differences!", vera_differences)
    // [1269] call snprintf_init
    // [1184] phi from main_vera_flash::@8 to snprintf_init [phi:main_vera_flash::@8->snprintf_init]
    // [1184] phi snprintf_init::s#30 = info_text [phi:main_vera_flash::@8->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main_vera_flash::@35
    // sprintf(info_text, "%u differences!", vera_differences)
    // [1270] printf_ulong::uvalue#10 = main_vera_flash::vera_differences#0 -- vdum1=vdum2 
    lda vera_differences
    sta printf_ulong.uvalue
    lda vera_differences+1
    sta printf_ulong.uvalue+1
    lda vera_differences+2
    sta printf_ulong.uvalue+2
    lda vera_differences+3
    sta printf_ulong.uvalue+3
    // [1271] call printf_ulong
    // [1588] phi from main_vera_flash::@35 to printf_ulong [phi:main_vera_flash::@35->printf_ulong]
    // [1588] phi printf_ulong::format_zero_padding#14 = 0 [phi:main_vera_flash::@35->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1588] phi printf_ulong::format_min_length#14 = 0 [phi:main_vera_flash::@35->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1588] phi printf_ulong::format_radix#14 = DECIMAL [phi:main_vera_flash::@35->printf_ulong#2] -- vbuxx=vbuc1 
    ldx #DECIMAL
    // [1588] phi printf_ulong::uvalue#14 = printf_ulong::uvalue#10 [phi:main_vera_flash::@35->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1272] phi from main_vera_flash::@35 to main_vera_flash::@36 [phi:main_vera_flash::@35->main_vera_flash::@36]
    // main_vera_flash::@36
    // sprintf(info_text, "%u differences!", vera_differences)
    // [1273] call printf_str
    // [1125] phi from main_vera_flash::@36 to printf_str [phi:main_vera_flash::@36->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:main_vera_flash::@36->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = s11 [phi:main_vera_flash::@36->printf_str#1] -- pbuz1=pbuc1 
    lda #<s11
    sta.z printf_str.s
    lda #>s11
    sta.z printf_str.s+1
    jsr printf_str
    // main_vera_flash::@37
    // sprintf(info_text, "%u differences!", vera_differences)
    // [1274] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1275] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_vera(STATUS_FLASH, info_text)
    // [1277] call display_info_vera
    // [1930] phi from main_vera_flash::@37 to display_info_vera [phi:main_vera_flash::@37->display_info_vera]
    // [1930] phi display_info_vera::info_text#15 = info_text [phi:main_vera_flash::@37->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_vera.info_text
    lda #>@info_text
    sta.z display_info_vera.info_text+1
    // [1930] phi display_info_vera::info_status#15 = STATUS_FLASH [phi:main_vera_flash::@37->display_info_vera#1] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_vera.info_status
    jsr display_info_vera
    // [1278] phi from main_vera_flash::@37 to main_vera_flash::@38 [phi:main_vera_flash::@37->main_vera_flash::@38]
    // main_vera_flash::@38
    // unsigned char vera_erase_error = w25q16_erase()
    // [1279] call w25q16_erase
    jsr w25q16_erase
    // [1280] w25q16_erase::return#3 = w25q16_erase::return#2
    // main_vera_flash::@39
    // [1281] main_vera_flash::vera_erase_error#0 = w25q16_erase::return#3
    // if(vera_erase_error)
    // [1282] if(0==main_vera_flash::vera_erase_error#0) goto main_vera_flash::@11 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b11
    // [1283] phi from main_vera_flash::@39 to main_vera_flash::@9 [phi:main_vera_flash::@39->main_vera_flash::@9]
    // main_vera_flash::@9
    // display_action_progress("There was an error cleaning your VERA flash memory!")
    // [1284] call display_action_progress
    // [1155] phi from main_vera_flash::@9 to display_action_progress [phi:main_vera_flash::@9->display_action_progress]
    // [1155] phi display_action_progress::info_text#30 = main_vera_flash::info_text7 [phi:main_vera_flash::@9->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z display_action_progress.info_text
    lda #>info_text7
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1285] phi from main_vera_flash::@9 to main_vera_flash::@41 [phi:main_vera_flash::@9->main_vera_flash::@41]
    // main_vera_flash::@41
    // display_action_text("DO NOT RESET or REBOOT YOUR CX16 AND WAIT!")
    // [1286] call display_action_text
    // [1200] phi from main_vera_flash::@41 to display_action_text [phi:main_vera_flash::@41->display_action_text]
    // [1200] phi display_action_text::info_text#25 = main_vera_flash::info_text8 [phi:main_vera_flash::@41->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z display_action_text.info_text
    lda #>info_text8
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1287] phi from main_vera_flash::@41 to main_vera_flash::@42 [phi:main_vera_flash::@41->main_vera_flash::@42]
    // main_vera_flash::@42
    // display_info_vera(STATUS_ERROR, "ERASE ERROR!")
    // [1288] call display_info_vera
    // [1930] phi from main_vera_flash::@42 to display_info_vera [phi:main_vera_flash::@42->display_info_vera]
    // [1930] phi display_info_vera::info_text#15 = main_vera_flash::info_text9 [phi:main_vera_flash::@42->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text9
    sta.z display_info_vera.info_text
    lda #>info_text9
    sta.z display_info_vera.info_text+1
    // [1930] phi display_info_vera::info_status#15 = STATUS_ERROR [phi:main_vera_flash::@42->display_info_vera#1] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_vera.info_status
    jsr display_info_vera
    // main_vera_flash::@43
    // [1289] smc_bootloader#598 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ERROR, NULL)
    // [1290] call display_info_smc
    // [925] phi from main_vera_flash::@43 to display_info_smc [phi:main_vera_flash::@43->display_info_smc]
    // [925] phi display_info_smc::info_text#24 = 0 [phi:main_vera_flash::@43->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [925] phi smc_bootloader#14 = smc_bootloader#598 [phi:main_vera_flash::@43->display_info_smc#1] -- register_copy 
    // [925] phi display_info_smc::info_status#24 = STATUS_ERROR [phi:main_vera_flash::@43->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [1291] phi from main_vera_flash::@43 to main_vera_flash::@44 [phi:main_vera_flash::@43->main_vera_flash::@44]
    // main_vera_flash::@44
    // display_info_roms(STATUS_ERROR, NULL)
    // [1292] call display_info_roms
    // [2483] phi from main_vera_flash::@44 to display_info_roms [phi:main_vera_flash::@44->display_info_roms]
    jsr display_info_roms
    // [1293] phi from main_vera_flash::@44 to main_vera_flash::@45 [phi:main_vera_flash::@44->main_vera_flash::@45]
    // main_vera_flash::@45
    // wait_moment(32)
    // [1294] call wait_moment
    // [1134] phi from main_vera_flash::@45 to wait_moment [phi:main_vera_flash::@45->wait_moment]
    // [1134] phi wait_moment::w#17 = $20 [phi:main_vera_flash::@45->wait_moment#0] -- vbuz1=vbuc1 
    lda #$20
    sta.z wait_moment.w
    jsr wait_moment
    // [1295] phi from main_vera_flash::@45 to main_vera_flash::@46 [phi:main_vera_flash::@45->main_vera_flash::@46]
    // main_vera_flash::@46
    // spi_deselect()
    // [1296] call spi_deselect
    jsr spi_deselect
    // main_vera_flash::@return
    // }
    // [1297] return 
    rts
    // [1298] phi from main_vera_flash::@39 to main_vera_flash::@11 [phi:main_vera_flash::@39->main_vera_flash::@11]
    // main_vera_flash::@11
  __b11:
    // __mem unsigned long vera_flashed = w25q16_flash()
    // [1299] call w25q16_flash
    // [2493] phi from main_vera_flash::@11 to w25q16_flash [phi:main_vera_flash::@11->w25q16_flash]
    jsr w25q16_flash
    // __mem unsigned long vera_flashed = w25q16_flash()
    // [1300] w25q16_flash::return#3 = w25q16_flash::return#2
    // main_vera_flash::@40
    // [1301] main_vera_flash::vera_flashed#0 = w25q16_flash::return#3 -- vdum1=vduz2 
    lda.z w25q16_flash.return
    sta vera_flashed
    lda.z w25q16_flash.return+1
    sta vera_flashed+1
    lda.z w25q16_flash.return+2
    sta vera_flashed+2
    lda.z w25q16_flash.return+3
    sta vera_flashed+3
    // if (vera_flashed)
    // [1302] if(0!=main_vera_flash::vera_flashed#0) goto main_vera_flash::@12 -- 0_neq_vdum1_then_la1 
    lda vera_flashed
    ora vera_flashed+1
    ora vera_flashed+2
    ora vera_flashed+3
    bne __b12
    // [1303] phi from main_vera_flash::@40 to main_vera_flash::@13 [phi:main_vera_flash::@40->main_vera_flash::@13]
    // main_vera_flash::@13
    // display_info_vera(STATUS_ERROR, info_text)
    // [1304] call display_info_vera
  // VFL2 | Flash VERA resulting in errors
    // [1930] phi from main_vera_flash::@13 to display_info_vera [phi:main_vera_flash::@13->display_info_vera]
    // [1930] phi display_info_vera::info_text#15 = info_text [phi:main_vera_flash::@13->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_vera.info_text
    lda #>@info_text
    sta.z display_info_vera.info_text+1
    // [1930] phi display_info_vera::info_status#15 = STATUS_ERROR [phi:main_vera_flash::@13->display_info_vera#1] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_vera.info_status
    jsr display_info_vera
    // [1305] phi from main_vera_flash::@13 to main_vera_flash::@49 [phi:main_vera_flash::@13->main_vera_flash::@49]
    // main_vera_flash::@49
    // display_action_progress("There was an error updating your VERA flash memory!")
    // [1306] call display_action_progress
    // [1155] phi from main_vera_flash::@49 to display_action_progress [phi:main_vera_flash::@49->display_action_progress]
    // [1155] phi display_action_progress::info_text#30 = main_vera_flash::info_text10 [phi:main_vera_flash::@49->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text10
    sta.z display_action_progress.info_text
    lda #>info_text10
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1307] phi from main_vera_flash::@49 to main_vera_flash::@50 [phi:main_vera_flash::@49->main_vera_flash::@50]
    // main_vera_flash::@50
    // display_action_text("DO NOT RESET or REBOOT YOUR CX16 AND WAIT!")
    // [1308] call display_action_text
    // [1200] phi from main_vera_flash::@50 to display_action_text [phi:main_vera_flash::@50->display_action_text]
    // [1200] phi display_action_text::info_text#25 = main_vera_flash::info_text8 [phi:main_vera_flash::@50->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z display_action_text.info_text
    lda #>info_text8
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1309] phi from main_vera_flash::@50 to main_vera_flash::@51 [phi:main_vera_flash::@50->main_vera_flash::@51]
    // main_vera_flash::@51
    // display_info_vera(STATUS_ERROR, "FLASH ERROR!")
    // [1310] call display_info_vera
    // [1930] phi from main_vera_flash::@51 to display_info_vera [phi:main_vera_flash::@51->display_info_vera]
    // [1930] phi display_info_vera::info_text#15 = main_vera_flash::info_text12 [phi:main_vera_flash::@51->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text12
    sta.z display_info_vera.info_text
    lda #>info_text12
    sta.z display_info_vera.info_text+1
    // [1930] phi display_info_vera::info_status#15 = STATUS_ERROR [phi:main_vera_flash::@51->display_info_vera#1] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_vera.info_status
    jsr display_info_vera
    // main_vera_flash::@52
    // [1311] smc_bootloader#599 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ERROR, NULL)
    // [1312] call display_info_smc
    // [925] phi from main_vera_flash::@52 to display_info_smc [phi:main_vera_flash::@52->display_info_smc]
    // [925] phi display_info_smc::info_text#24 = 0 [phi:main_vera_flash::@52->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [925] phi smc_bootloader#14 = smc_bootloader#599 [phi:main_vera_flash::@52->display_info_smc#1] -- register_copy 
    // [925] phi display_info_smc::info_status#24 = STATUS_ERROR [phi:main_vera_flash::@52->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [1313] phi from main_vera_flash::@52 to main_vera_flash::@53 [phi:main_vera_flash::@52->main_vera_flash::@53]
    // main_vera_flash::@53
    // display_info_roms(STATUS_ERROR, NULL)
    // [1314] call display_info_roms
    // [2483] phi from main_vera_flash::@53 to display_info_roms [phi:main_vera_flash::@53->display_info_roms]
    jsr display_info_roms
    // [1315] phi from main_vera_flash::@53 to main_vera_flash::@54 [phi:main_vera_flash::@53->main_vera_flash::@54]
    // main_vera_flash::@54
    // wait_moment(32)
    // [1316] call wait_moment
    // [1134] phi from main_vera_flash::@54 to wait_moment [phi:main_vera_flash::@54->wait_moment]
    // [1134] phi wait_moment::w#17 = $20 [phi:main_vera_flash::@54->wait_moment#0] -- vbuz1=vbuc1 
    lda #$20
    sta.z wait_moment.w
    jsr wait_moment
    // [1317] phi from main_vera_flash::@54 to main_vera_flash::@55 [phi:main_vera_flash::@54->main_vera_flash::@55]
    // main_vera_flash::@55
    // spi_deselect()
    // [1318] call spi_deselect
    jsr spi_deselect
    rts
    // [1319] phi from main_vera_flash::@40 to main_vera_flash::@12 [phi:main_vera_flash::@40->main_vera_flash::@12]
    // main_vera_flash::@12
  __b12:
    // display_info_vera(STATUS_FLASHED, NULL)
    // [1320] call display_info_vera
  // VFL3 | Flash VERA and all ok
    // [1930] phi from main_vera_flash::@12 to display_info_vera [phi:main_vera_flash::@12->display_info_vera]
    // [1930] phi display_info_vera::info_text#15 = 0 [phi:main_vera_flash::@12->display_info_vera#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_vera.info_text
    sta.z display_info_vera.info_text+1
    // [1930] phi display_info_vera::info_status#15 = STATUS_FLASHED [phi:main_vera_flash::@12->display_info_vera#1] -- vbum1=vbuc1 
    lda #STATUS_FLASHED
    sta display_info_vera.info_status
    jsr display_info_vera
    // [1321] phi from main_vera_flash::@12 to main_vera_flash::@47 [phi:main_vera_flash::@12->main_vera_flash::@47]
    // main_vera_flash::@47
    // __mem unsigned long vera_differences = w25q16_verify(1)
    // [1322] call w25q16_verify
    // [2393] phi from main_vera_flash::@47 to w25q16_verify [phi:main_vera_flash::@47->w25q16_verify]
    // [2393] phi w25q16_verify::verify#2 = 1 [phi:main_vera_flash::@47->w25q16_verify#0] -- vbuxx=vbuc1 
    ldx #1
    jsr w25q16_verify
    // __mem unsigned long vera_differences = w25q16_verify(1)
    // [1323] w25q16_verify::return#3 = w25q16_verify::w25q16_different_bytes#2
    // main_vera_flash::@48
    // [1324] main_vera_flash::vera_differences1#0 = w25q16_verify::return#3 -- vdum1=vdum2 
    lda w25q16_verify.return
    sta vera_differences1
    lda w25q16_verify.return+1
    sta vera_differences1+1
    lda w25q16_verify.return+2
    sta vera_differences1+2
    lda w25q16_verify.return+3
    sta vera_differences1+3
    // if (vera_differences)
    // [1325] if(0==main_vera_flash::vera_differences1#0) goto main_vera_flash::@15 -- 0_eq_vdum1_then_la1 
    lda vera_differences1
    ora vera_differences1+1
    ora vera_differences1+2
    ora vera_differences1+3
    beq __b15
    // [1326] phi from main_vera_flash::@48 to main_vera_flash::@14 [phi:main_vera_flash::@48->main_vera_flash::@14]
    // main_vera_flash::@14
    // sprintf(info_text, "%u differences!", vera_differences)
    // [1327] call snprintf_init
    // [1184] phi from main_vera_flash::@14 to snprintf_init [phi:main_vera_flash::@14->snprintf_init]
    // [1184] phi snprintf_init::s#30 = info_text [phi:main_vera_flash::@14->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main_vera_flash::@56
    // sprintf(info_text, "%u differences!", vera_differences)
    // [1328] printf_ulong::uvalue#11 = main_vera_flash::vera_differences1#0
    // [1329] call printf_ulong
    // [1588] phi from main_vera_flash::@56 to printf_ulong [phi:main_vera_flash::@56->printf_ulong]
    // [1588] phi printf_ulong::format_zero_padding#14 = 0 [phi:main_vera_flash::@56->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1588] phi printf_ulong::format_min_length#14 = 0 [phi:main_vera_flash::@56->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1588] phi printf_ulong::format_radix#14 = DECIMAL [phi:main_vera_flash::@56->printf_ulong#2] -- vbuxx=vbuc1 
    ldx #DECIMAL
    // [1588] phi printf_ulong::uvalue#14 = printf_ulong::uvalue#11 [phi:main_vera_flash::@56->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1330] phi from main_vera_flash::@56 to main_vera_flash::@57 [phi:main_vera_flash::@56->main_vera_flash::@57]
    // main_vera_flash::@57
    // sprintf(info_text, "%u differences!", vera_differences)
    // [1331] call printf_str
    // [1125] phi from main_vera_flash::@57 to printf_str [phi:main_vera_flash::@57->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:main_vera_flash::@57->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = s11 [phi:main_vera_flash::@57->printf_str#1] -- pbuz1=pbuc1 
    lda #<s11
    sta.z printf_str.s
    lda #>s11
    sta.z printf_str.s+1
    jsr printf_str
    // main_vera_flash::@58
    // sprintf(info_text, "%u differences!", vera_differences)
    // [1332] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1333] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_vera(STATUS_ERROR, info_text)
    // [1335] call display_info_vera
    // [1930] phi from main_vera_flash::@58 to display_info_vera [phi:main_vera_flash::@58->display_info_vera]
    // [1930] phi display_info_vera::info_text#15 = info_text [phi:main_vera_flash::@58->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_vera.info_text
    lda #>@info_text
    sta.z display_info_vera.info_text+1
    // [1930] phi display_info_vera::info_status#15 = STATUS_ERROR [phi:main_vera_flash::@58->display_info_vera#1] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_vera.info_status
    jsr display_info_vera
    // [1336] phi from main_vera_flash::@10 main_vera_flash::@48 main_vera_flash::@58 to main_vera_flash::@15 [phi:main_vera_flash::@10/main_vera_flash::@48/main_vera_flash::@58->main_vera_flash::@15]
    // main_vera_flash::@15
  __b15:
    // display_action_progress("VERA SPI de-activation ...")
    // [1337] call display_action_progress
  // Now we loop until jumper JP1 is open again!
    // [1155] phi from main_vera_flash::@15 to display_action_progress [phi:main_vera_flash::@15->display_action_progress]
    // [1155] phi display_action_progress::info_text#30 = main_vera_flash::info_text13 [phi:main_vera_flash::@15->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text13
    sta.z display_action_progress.info_text
    lda #>info_text13
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1338] phi from main_vera_flash::@15 to main_vera_flash::@59 [phi:main_vera_flash::@15->main_vera_flash::@59]
    // main_vera_flash::@59
    // display_action_text("Please OPEN the jumper JP1 on the VERA board!")
    // [1339] call display_action_text
    // [1200] phi from main_vera_flash::@59 to display_action_text [phi:main_vera_flash::@59->display_action_text]
    // [1200] phi display_action_text::info_text#25 = main_vera_flash::info_text14 [phi:main_vera_flash::@59->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text14
    sta.z display_action_text.info_text
    lda #>info_text14
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1340] phi from main_vera_flash::@59 main_vera_flash::@61 main_vera_flash::@64 main_vera_flash::@65 to main_vera_flash::@16 [phi:main_vera_flash::@59/main_vera_flash::@61/main_vera_flash::@64/main_vera_flash::@65->main_vera_flash::@16]
  __b5:
    // [1340] phi main_vera_flash::spi_ensure_detect#12 = 0 [phi:main_vera_flash::@59/main_vera_flash::@61/main_vera_flash::@64/main_vera_flash::@65->main_vera_flash::@16#0] -- vbum1=vbuc1 
    lda #0
    sta spi_ensure_detect_1
    // main_vera_flash::@16
  __b16:
    // while(spi_ensure_detect < 16)
    // [1341] if(main_vera_flash::spi_ensure_detect#12<$10) goto main_vera_flash::@17 -- vbum1_lt_vbuc1_then_la1 
    lda spi_ensure_detect_1
    cmp #$10
    bcc __b17
    // [1342] phi from main_vera_flash::@16 to main_vera_flash::@18 [phi:main_vera_flash::@16->main_vera_flash::@18]
    // main_vera_flash::@18
    // display_action_text("The jumper JP1 has been opened on the VERA!")
    // [1343] call display_action_text
    // [1200] phi from main_vera_flash::@18 to display_action_text [phi:main_vera_flash::@18->display_action_text]
    // [1200] phi display_action_text::info_text#25 = main_vera_flash::info_text15 [phi:main_vera_flash::@18->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text15
    sta.z display_action_text.info_text
    lda #>info_text15
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1344] phi from main_vera_flash::@18 main_vera_flash::@26 to main_vera_flash::@1 [phi:main_vera_flash::@18/main_vera_flash::@26->main_vera_flash::@1]
    // main_vera_flash::@1
  __b1:
    // spi_deselect()
    // [1345] call spi_deselect
    jsr spi_deselect
    // [1346] phi from main_vera_flash::@1 to main_vera_flash::@27 [phi:main_vera_flash::@1->main_vera_flash::@27]
    // main_vera_flash::@27
    // wait_moment(16)
    // [1347] call wait_moment
    // [1134] phi from main_vera_flash::@27 to wait_moment [phi:main_vera_flash::@27->wait_moment]
    // [1134] phi wait_moment::w#17 = $10 [phi:main_vera_flash::@27->wait_moment#0] -- vbuz1=vbuc1 
    lda #$10
    sta.z wait_moment.w
    jsr wait_moment
    rts
    // [1348] phi from main_vera_flash::@16 to main_vera_flash::@17 [phi:main_vera_flash::@16->main_vera_flash::@17]
    // main_vera_flash::@17
  __b17:
    // w25q16_detect()
    // [1349] call w25q16_detect
    // [2223] phi from main_vera_flash::@17 to w25q16_detect [phi:main_vera_flash::@17->w25q16_detect]
    jsr w25q16_detect
    // [1350] phi from main_vera_flash::@17 to main_vera_flash::@60 [phi:main_vera_flash::@17->main_vera_flash::@60]
    // main_vera_flash::@60
    // wait_moment(1)
    // [1351] call wait_moment
    // [1134] phi from main_vera_flash::@60 to wait_moment [phi:main_vera_flash::@60->wait_moment]
    // [1134] phi wait_moment::w#17 = 1 [phi:main_vera_flash::@60->wait_moment#0] -- vbuz1=vbuc1 
    lda #1
    sta.z wait_moment.w
    jsr wait_moment
    // main_vera_flash::@61
    // if(spi_manufacturer != 0xEF && spi_memory_type != 0x40 && spi_memory_capacity != 0x15)
    // [1352] if(spi_manufacturer#0==$ef) goto main_vera_flash::@16 -- vbuxx_eq_vbuc1_then_la1 
    cpx #$ef
    beq __b5
    // main_vera_flash::@65
    // [1353] if(spi_memory_type#0==$40) goto main_vera_flash::@16 -- vbuyy_eq_vbuc1_then_la1 
    cpy #$40
    beq __b5
    // main_vera_flash::@64
    // [1354] if(spi_memory_capacity#0!=$15) goto main_vera_flash::@19 -- vbum1_neq_vbuc1_then_la1 
    lda #$15
    cmp spi_memory_capacity
    bne __b19
    jmp __b5
    // main_vera_flash::@19
  __b19:
    // spi_ensure_detect++;
    // [1355] main_vera_flash::spi_ensure_detect#4 = ++ main_vera_flash::spi_ensure_detect#12 -- vbum1=_inc_vbum1 
    inc spi_ensure_detect_1
    // [1340] phi from main_vera_flash::@19 to main_vera_flash::@16 [phi:main_vera_flash::@19->main_vera_flash::@16]
    // [1340] phi main_vera_flash::spi_ensure_detect#12 = main_vera_flash::spi_ensure_detect#4 [phi:main_vera_flash::@19->main_vera_flash::@16#0] -- register_copy 
    jmp __b16
    // [1356] phi from main_vera_flash::@34 to main_vera_flash::@10 [phi:main_vera_flash::@34->main_vera_flash::@10]
    // main_vera_flash::@10
  __b10:
    // display_info_vera(STATUS_SKIP, "No update required")
    // [1357] call display_info_vera
  // VFL1 | VERA and VERA.BIN equal | Display that there are no differences between the VERA and VERA.BIN. Set VERA to Flashed. | None
    // [1930] phi from main_vera_flash::@10 to display_info_vera [phi:main_vera_flash::@10->display_info_vera]
    // [1930] phi display_info_vera::info_text#15 = info_text6 [phi:main_vera_flash::@10->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text6
    sta.z display_info_vera.info_text
    lda #>info_text6
    sta.z display_info_vera.info_text+1
    // [1930] phi display_info_vera::info_status#15 = STATUS_SKIP [phi:main_vera_flash::@10->display_info_vera#1] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_vera.info_status
    jsr display_info_vera
    jmp __b15
    // [1358] phi from main_vera_flash::@3 to main_vera_flash::@4 [phi:main_vera_flash::@3->main_vera_flash::@4]
    // main_vera_flash::@4
  __b4:
    // w25q16_detect()
    // [1359] call w25q16_detect
    // [2223] phi from main_vera_flash::@4 to w25q16_detect [phi:main_vera_flash::@4->w25q16_detect]
    jsr w25q16_detect
    // [1360] phi from main_vera_flash::@4 to main_vera_flash::@29 [phi:main_vera_flash::@4->main_vera_flash::@29]
    // main_vera_flash::@29
    // wait_moment(1)
    // [1361] call wait_moment
    // [1134] phi from main_vera_flash::@29 to wait_moment [phi:main_vera_flash::@29->wait_moment]
    // [1134] phi wait_moment::w#17 = 1 [phi:main_vera_flash::@29->wait_moment#0] -- vbuz1=vbuc1 
    lda #1
    sta.z wait_moment.w
    jsr wait_moment
    // main_vera_flash::@30
    // if(spi_manufacturer == 0xEF && spi_memory_type == 0x40 && spi_memory_capacity == 0x15)
    // [1362] if(spi_manufacturer#0!=$ef) goto main_vera_flash::@7 -- vbuxx_neq_vbuc1_then_la1 
    cpx #$ef
    bne __b7
    // main_vera_flash::@63
    // [1363] if(spi_memory_type#0!=$40) goto main_vera_flash::@7 -- vbuyy_neq_vbuc1_then_la1 
    cpy #$40
    bne __b7
    // main_vera_flash::@62
    // [1364] if(spi_memory_capacity#0==$15) goto main_vera_flash::@6 -- vbum1_eq_vbuc1_then_la1 
    lda #$15
    cmp spi_memory_capacity
    beq __b6
    // [1365] phi from main_vera_flash::@30 main_vera_flash::@62 main_vera_flash::@63 to main_vera_flash::@7 [phi:main_vera_flash::@30/main_vera_flash::@62/main_vera_flash::@63->main_vera_flash::@7]
    // main_vera_flash::@7
  __b7:
    // display_info_vera(STATUS_WAITING, "Close JP1 jumper pins!")
    // [1366] call display_info_vera
    // [1930] phi from main_vera_flash::@7 to display_info_vera [phi:main_vera_flash::@7->display_info_vera]
    // [1930] phi display_info_vera::info_text#15 = main_vera_flash::info_text5 [phi:main_vera_flash::@7->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z display_info_vera.info_text
    lda #>info_text5
    sta.z display_info_vera.info_text+1
    // [1930] phi display_info_vera::info_status#15 = STATUS_WAITING [phi:main_vera_flash::@7->display_info_vera#1] -- vbum1=vbuc1 
    lda #STATUS_WAITING
    sta display_info_vera.info_status
    jsr display_info_vera
    jmp __b2
    // main_vera_flash::@6
  __b6:
    // spi_ensure_detect++;
    // [1367] main_vera_flash::spi_ensure_detect#1 = ++ main_vera_flash::spi_ensure_detect#11 -- vbum1=_inc_vbum1 
    inc spi_ensure_detect
    // [1255] phi from main_vera_flash::@6 to main_vera_flash::@3 [phi:main_vera_flash::@6->main_vera_flash::@3]
    // [1255] phi main_vera_flash::spi_ensure_detect#11 = main_vera_flash::spi_ensure_detect#1 [phi:main_vera_flash::@6->main_vera_flash::@3#0] -- register_copy 
    jmp __b3
  .segment Data
    s: .text "Reading VERA.BIN ... (.) data ( ) empty"
    .byte 0
    info_text: .text "VERA SPI activation ..."
    .byte 0
    info_text1: .text "Please close the jumper JP1 on the VERA board!"
    .byte 0
    info_text2: .text "The jumper JP1 has been closed on the VERA!"
    .byte 0
    info_text3: .text "Comparing VERA ... (.) data, (=) same, (*) different."
    .byte 0
    info_text5: .text "Close JP1 jumper pins!"
    .byte 0
    info_text7: .text "There was an error cleaning your VERA flash memory!"
    .byte 0
    info_text8: .text "DO NOT RESET or REBOOT YOUR CX16 AND WAIT!"
    .byte 0
    info_text9: .text "ERASE ERROR!"
    .byte 0
    info_text10: .text "There was an error updating your VERA flash memory!"
    .byte 0
    info_text12: .text "FLASH ERROR!"
    .byte 0
    info_text13: .text "VERA SPI de-activation ..."
    .byte 0
    info_text14: .text "Please OPEN the jumper JP1 on the VERA board!"
    .byte 0
    info_text15: .text "The jumper JP1 has been opened on the VERA!"
    .byte 0
    vera_differences: .dword 0
    spi_ensure_detect: .byte 0
    .label vera_flashed = printf_ulong.uvalue
    .label vera_differences1 = printf_ulong.uvalue
    spi_ensure_detect_1: .byte 0
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
// void display_info_rom(__mem() char rom_chip, __mem() char info_status, __zp($78) char *info_text)
display_info_rom: {
    .label info_text = $78
    // unsigned char x = wherex()
    // [1369] call wherex
    jsr wherex
    // [1370] wherex::return#12 = wherex::return#0
    // display_info_rom::@3
    // [1371] display_info_rom::x#0 = wherex::return#12 -- vbum1=vbuaa 
    sta x
    // unsigned char y = wherey()
    // [1372] call wherey
    jsr wherey
    // [1373] wherey::return#12 = wherey::return#0
    // display_info_rom::@4
    // [1374] display_info_rom::y#0 = wherey::return#12 -- vbum1=vbuaa 
    sta y
    // status_rom[rom_chip] = info_status
    // [1375] status_rom[display_info_rom::rom_chip#16] = display_info_rom::info_status#16 -- pbuc1_derefidx_vbum1=vbum2 
    lda info_status
    ldy rom_chip
    sta status_rom,y
    // display_rom_led(rom_chip, status_color[info_status])
    // [1376] display_rom_led::chip#1 = display_info_rom::rom_chip#16 -- vbuz1=vbum2 
    tya
    sta.z display_rom_led.chip
    // [1377] display_rom_led::c#1 = status_color[display_info_rom::info_status#16] -- vbuz1=pbuc1_derefidx_vbum2 
    ldy info_status
    lda status_color,y
    sta.z display_rom_led.c
    // [1378] call display_rom_led
    // [2262] phi from display_info_rom::@4 to display_rom_led [phi:display_info_rom::@4->display_rom_led]
    // [2262] phi display_rom_led::c#2 = display_rom_led::c#1 [phi:display_info_rom::@4->display_rom_led#0] -- register_copy 
    // [2262] phi display_rom_led::chip#2 = display_rom_led::chip#1 [phi:display_info_rom::@4->display_rom_led#1] -- register_copy 
    jsr display_rom_led
    // display_info_rom::@5
    // gotoxy(INFO_X, INFO_Y+rom_chip+2)
    // [1379] gotoxy::y#19 = display_info_rom::rom_chip#16 + $11+2 -- vbum1=vbum2_plus_vbuc1 
    lda #$11+2
    clc
    adc rom_chip
    sta gotoxy.y
    // [1380] call gotoxy
    // [805] phi from display_info_rom::@5 to gotoxy [phi:display_info_rom::@5->gotoxy]
    // [805] phi gotoxy::y#37 = gotoxy::y#19 [phi:display_info_rom::@5->gotoxy#0] -- register_copy 
    // [805] phi gotoxy::x#37 = 4 [phi:display_info_rom::@5->gotoxy#1] -- vbuyy=vbuc1 
    ldy #4
    jsr gotoxy
    // display_info_rom::@6
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1381] display_info_rom::$16 = display_info_rom::rom_chip#16 << 1 -- vbum1=vbum2_rol_1 
    lda rom_chip
    asl
    sta display_info_rom__16
    // rom_chip*13
    // [1382] display_info_rom::$19 = display_info_rom::$16 + display_info_rom::rom_chip#16 -- vbuaa=vbum1_plus_vbum2 
    clc
    adc rom_chip
    // [1383] display_info_rom::$20 = display_info_rom::$19 << 2 -- vbuaa=vbuaa_rol_2 
    asl
    asl
    // [1384] display_info_rom::$6 = display_info_rom::$20 + display_info_rom::rom_chip#16 -- vbuaa=vbuaa_plus_vbum1 
    clc
    adc rom_chip
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1385] printf_string::str#10 = rom_release_text + display_info_rom::$6 -- pbum1=pbuc1_plus_vbuaa 
    clc
    adc #<rom_release_text
    sta printf_string.str_1
    lda #>rom_release_text
    adc #0
    sta printf_string.str_1+1
    // [1386] call printf_str
    // [1125] phi from display_info_rom::@6 to printf_str [phi:display_info_rom::@6->printf_str]
    // [1125] phi printf_str::putc#79 = &cputc [phi:display_info_rom::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = chip [phi:display_info_rom::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<chip
    sta.z printf_str.s
    lda #>chip
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@7
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1387] printf_uchar::uvalue#0 = display_info_rom::rom_chip#16 -- vbuxx=vbum1 
    ldx rom_chip
    // [1388] call printf_uchar
    // [1189] phi from display_info_rom::@7 to printf_uchar [phi:display_info_rom::@7->printf_uchar]
    // [1189] phi printf_uchar::format_zero_padding#15 = 0 [phi:display_info_rom::@7->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1189] phi printf_uchar::format_min_length#15 = 0 [phi:display_info_rom::@7->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1189] phi printf_uchar::putc#15 = &cputc [phi:display_info_rom::@7->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1189] phi printf_uchar::format_radix#15 = DECIMAL [phi:display_info_rom::@7->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [1189] phi printf_uchar::uvalue#15 = printf_uchar::uvalue#0 [phi:display_info_rom::@7->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1389] phi from display_info_rom::@7 to display_info_rom::@8 [phi:display_info_rom::@7->display_info_rom::@8]
    // display_info_rom::@8
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1390] call printf_str
    // [1125] phi from display_info_rom::@8 to printf_str [phi:display_info_rom::@8->printf_str]
    // [1125] phi printf_str::putc#79 = &cputc [phi:display_info_rom::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = s [phi:display_info_rom::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@9
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1391] display_info_rom::$15 = display_info_rom::info_status#16 << 1 -- vbuaa=vbum1_rol_1 
    lda info_status
    asl
    // [1392] printf_string::str#8 = status_text[display_info_rom::$15] -- pbuz1=qbuc1_derefidx_vbuaa 
    tay
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [1393] call printf_string
    // [1419] phi from display_info_rom::@9 to printf_string [phi:display_info_rom::@9->printf_string]
    // [1419] phi printf_string::putc#26 = &cputc [phi:display_info_rom::@9->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1419] phi printf_string::str#26 = printf_string::str#8 [phi:display_info_rom::@9->printf_string#1] -- register_copy 
    // [1419] phi printf_string::format_justify_left#26 = 1 [phi:display_info_rom::@9->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1419] phi printf_string::format_min_length#26 = 9 [phi:display_info_rom::@9->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [1394] phi from display_info_rom::@9 to display_info_rom::@10 [phi:display_info_rom::@9->display_info_rom::@10]
    // display_info_rom::@10
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1395] call printf_str
    // [1125] phi from display_info_rom::@10 to printf_str [phi:display_info_rom::@10->printf_str]
    // [1125] phi printf_str::putc#79 = &cputc [phi:display_info_rom::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = s [phi:display_info_rom::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@11
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1396] printf_string::str#9 = rom_device_names[display_info_rom::$16] -- pbuz1=qbuc1_derefidx_vbum2 
    ldy display_info_rom__16
    lda rom_device_names,y
    sta.z printf_string.str
    lda rom_device_names+1,y
    sta.z printf_string.str+1
    // [1397] call printf_string
    // [1419] phi from display_info_rom::@11 to printf_string [phi:display_info_rom::@11->printf_string]
    // [1419] phi printf_string::putc#26 = &cputc [phi:display_info_rom::@11->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1419] phi printf_string::str#26 = printf_string::str#9 [phi:display_info_rom::@11->printf_string#1] -- register_copy 
    // [1419] phi printf_string::format_justify_left#26 = 1 [phi:display_info_rom::@11->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1419] phi printf_string::format_min_length#26 = 6 [phi:display_info_rom::@11->printf_string#3] -- vbum1=vbuc1 
    lda #6
    sta printf_string.format_min_length
    jsr printf_string
    // [1398] phi from display_info_rom::@11 to display_info_rom::@12 [phi:display_info_rom::@11->display_info_rom::@12]
    // display_info_rom::@12
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1399] call printf_str
    // [1125] phi from display_info_rom::@12 to printf_str [phi:display_info_rom::@12->printf_str]
    // [1125] phi printf_str::putc#79 = &cputc [phi:display_info_rom::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = s [phi:display_info_rom::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@13
    // [1400] printf_string::str#41 = printf_string::str#10 -- pbuz1=pbum2 
    lda printf_string.str_1
    sta.z printf_string.str
    lda printf_string.str_1+1
    sta.z printf_string.str+1
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1401] call printf_string
    // [1419] phi from display_info_rom::@13 to printf_string [phi:display_info_rom::@13->printf_string]
    // [1419] phi printf_string::putc#26 = &cputc [phi:display_info_rom::@13->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1419] phi printf_string::str#26 = printf_string::str#41 [phi:display_info_rom::@13->printf_string#1] -- register_copy 
    // [1419] phi printf_string::format_justify_left#26 = 1 [phi:display_info_rom::@13->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1419] phi printf_string::format_min_length#26 = $d [phi:display_info_rom::@13->printf_string#3] -- vbum1=vbuc1 
    lda #$d
    sta printf_string.format_min_length
    jsr printf_string
    // [1402] phi from display_info_rom::@13 to display_info_rom::@14 [phi:display_info_rom::@13->display_info_rom::@14]
    // display_info_rom::@14
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1403] call printf_str
    // [1125] phi from display_info_rom::@14 to printf_str [phi:display_info_rom::@14->printf_str]
    // [1125] phi printf_str::putc#79 = &cputc [phi:display_info_rom::@14->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = s [phi:display_info_rom::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@15
    // if(info_text)
    // [1404] if((char *)0==display_info_rom::info_text#16) goto display_info_rom::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_rom::@2
    // gotoxy(INFO_X+64-28, INFO_Y+rom_chip+2)
    // [1405] gotoxy::y#21 = display_info_rom::rom_chip#16 + $11+2 -- vbum1=vbum2_plus_vbuc1 
    lda #$11+2
    clc
    adc rom_chip
    sta gotoxy.y
    // [1406] call gotoxy
    // [805] phi from display_info_rom::@2 to gotoxy [phi:display_info_rom::@2->gotoxy]
    // [805] phi gotoxy::y#37 = gotoxy::y#21 [phi:display_info_rom::@2->gotoxy#0] -- register_copy 
    // [805] phi gotoxy::x#37 = 4+$40-$1c [phi:display_info_rom::@2->gotoxy#1] -- vbuyy=vbuc1 
    ldy #4+$40-$1c
    jsr gotoxy
    // display_info_rom::@16
    // printf("%-25s", info_text)
    // [1407] printf_string::str#11 = display_info_rom::info_text#16 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1408] call printf_string
    // [1419] phi from display_info_rom::@16 to printf_string [phi:display_info_rom::@16->printf_string]
    // [1419] phi printf_string::putc#26 = &cputc [phi:display_info_rom::@16->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1419] phi printf_string::str#26 = printf_string::str#11 [phi:display_info_rom::@16->printf_string#1] -- register_copy 
    // [1419] phi printf_string::format_justify_left#26 = 1 [phi:display_info_rom::@16->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1419] phi printf_string::format_min_length#26 = $19 [phi:display_info_rom::@16->printf_string#3] -- vbum1=vbuc1 
    lda #$19
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_rom::@1
  __b1:
    // gotoxy(x,y)
    // [1409] gotoxy::x#20 = display_info_rom::x#0 -- vbuyy=vbum1 
    ldy x
    // [1410] gotoxy::y#20 = display_info_rom::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1411] call gotoxy
    // [805] phi from display_info_rom::@1 to gotoxy [phi:display_info_rom::@1->gotoxy]
    // [805] phi gotoxy::y#37 = gotoxy::y#20 [phi:display_info_rom::@1->gotoxy#0] -- register_copy 
    // [805] phi gotoxy::x#37 = gotoxy::x#20 [phi:display_info_rom::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_rom::@return
    // }
    // [1412] return 
    rts
  .segment Data
    display_info_rom__16: .byte 0
    .label rom_chip = w25q16_erase.vera_current_64k_block
    x: .byte 0
    y: .byte 0
    .label info_status = w25q16_verify.w25q16_compared_bytes
}
.segment Code
  // rom_file
// __mem() char * rom_file(__register(A) char rom_chip)
rom_file: {
    // if(rom_chip)
    // [1414] if(0!=rom_file::rom_chip#2) goto rom_file::@1 -- 0_neq_vbuaa_then_la1 
    cmp #0
    bne __b1
    // [1417] phi from rom_file to rom_file::@return [phi:rom_file->rom_file::@return]
    // [1417] phi rom_file::return#2 = rom_file::file_rom_cx16 [phi:rom_file->rom_file::@return#0] -- pbum1=pbuc1 
    lda #<file_rom_cx16
    sta return
    lda #>file_rom_cx16
    sta return+1
    rts
    // rom_file::@1
  __b1:
    // '0'+rom_chip
    // [1415] rom_file::$0 = '0' + rom_file::rom_chip#2 -- vbuaa=vbuc1_plus_vbuaa 
    clc
    adc #'0'
    // file_rom_card[3] = '0'+rom_chip
    // [1416] *(rom_file::file_rom_card+3) = rom_file::$0 -- _deref_pbuc1=vbuaa 
    sta file_rom_card+3
    // [1417] phi from rom_file::@1 to rom_file::@return [phi:rom_file::@1->rom_file::@return]
    // [1417] phi rom_file::return#2 = rom_file::file_rom_card [phi:rom_file::@1->rom_file::@return#0] -- pbum1=pbuc1 
    lda #<file_rom_card
    sta return
    lda #>file_rom_card
    sta return+1
    // rom_file::@return
    // }
    // [1418] return 
    rts
  .segment Data
    file_rom_cx16: .text "ROM.BIN"
    .byte 0
    file_rom_card: .text "ROMn.BIN"
    .byte 0
    return: .word 0
}
.segment Code
  // printf_string
// Print a string value using a specific format
// Handles justification and min length 
// void printf_string(__zp($3a) void (*putc)(char), __zp($48) char *str, __mem() char format_min_length, __mem() char format_justify_left)
printf_string: {
    .label printf_string__9 = $25
    .label str = $48
    .label putc = $3a
    // if(format.min_length)
    // [1420] if(0==printf_string::format_min_length#26) goto printf_string::@1 -- 0_eq_vbum1_then_la1 
    lda format_min_length
    beq __b3
    // printf_string::@3
    // strlen(str)
    // [1421] strlen::str#3 = printf_string::str#26 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [1422] call strlen
    // [2555] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [2555] phi strlen::str#8 = strlen::str#3 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [1423] strlen::return#10 = strlen::len#2
    // printf_string::@6
    // [1424] printf_string::$9 = strlen::return#10 -- vwuz1=vwum2 
    lda strlen.return
    sta.z printf_string__9
    lda strlen.return+1
    sta.z printf_string__9+1
    // signed char len = (signed char)strlen(str)
    // [1425] printf_string::len#0 = (signed char)printf_string::$9 -- vbsaa=_sbyte_vwuz1 
    lda.z printf_string__9
    // padding = (signed char)format.min_length  - len
    // [1426] printf_string::padding#1 = (signed char)printf_string::format_min_length#26 - printf_string::len#0 -- vbsm1=vbsm1_minus_vbsaa 
    eor #$ff
    sec
    adc padding
    sta padding
    // if(padding<0)
    // [1427] if(printf_string::padding#1>=0) goto printf_string::@10 -- vbsm1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1429] phi from printf_string printf_string::@6 to printf_string::@1 [phi:printf_string/printf_string::@6->printf_string::@1]
  __b3:
    // [1429] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@6->printf_string::@1#0] -- vbsm1=vbsc1 
    lda #0
    sta padding
    // [1428] phi from printf_string::@6 to printf_string::@10 [phi:printf_string::@6->printf_string::@10]
    // printf_string::@10
    // [1429] phi from printf_string::@10 to printf_string::@1 [phi:printf_string::@10->printf_string::@1]
    // [1429] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@10->printf_string::@1#0] -- register_copy 
    // printf_string::@1
  __b1:
    // if(!format.justify_left && padding)
    // [1430] if(0!=printf_string::format_justify_left#26) goto printf_string::@2 -- 0_neq_vbum1_then_la1 
    lda format_justify_left
    bne __b2
    // printf_string::@8
    // [1431] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b4
    jmp __b2
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [1432] printf_padding::putc#3 = printf_string::putc#26 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1433] printf_padding::length#3 = (char)printf_string::padding#3 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1434] call printf_padding
    // [2561] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [2561] phi printf_padding::putc#7 = printf_padding::putc#3 [phi:printf_string::@4->printf_padding#0] -- register_copy 
    // [2561] phi printf_padding::pad#7 = ' ' [phi:printf_string::@4->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [2561] phi printf_padding::length#6 = printf_padding::length#3 [phi:printf_string::@4->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [1435] printf_str::putc#1 = printf_string::putc#26 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_str.putc
    lda.z putc+1
    sta.z printf_str.putc+1
    // [1436] printf_str::s#2 = printf_string::str#26
    // [1437] call printf_str
    // [1125] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [1125] phi printf_str::putc#79 = printf_str::putc#1 [phi:printf_string::@2->printf_str#0] -- register_copy 
    // [1125] phi printf_str::s#79 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@7
    // if(format.justify_left && padding)
    // [1438] if(0==printf_string::format_justify_left#26) goto printf_string::@return -- 0_eq_vbum1_then_la1 
    lda format_justify_left
    beq __breturn
    // printf_string::@9
    // [1439] if(0!=printf_string::padding#3) goto printf_string::@5 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b5
    rts
    // printf_string::@5
  __b5:
    // printf_padding(putc, ' ',(char)padding)
    // [1440] printf_padding::putc#4 = printf_string::putc#26 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1441] printf_padding::length#4 = (char)printf_string::padding#3 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1442] call printf_padding
    // [2561] phi from printf_string::@5 to printf_padding [phi:printf_string::@5->printf_padding]
    // [2561] phi printf_padding::putc#7 = printf_padding::putc#4 [phi:printf_string::@5->printf_padding#0] -- register_copy 
    // [2561] phi printf_padding::pad#7 = ' ' [phi:printf_string::@5->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [2561] phi printf_padding::length#6 = printf_padding::length#4 [phi:printf_string::@5->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@return
  __breturn:
    // }
    // [1443] return 
    rts
  .segment Data
    .label padding = printf_uchar.format_min_length
    .label str_1 = display_print_chip.text_3
    .label format_min_length = printf_uchar.format_min_length
    format_justify_left: .byte 0
}
.segment Code
  // rom_read
// __mem() unsigned long rom_read(__mem() char rom_chip, __zp($bb) char *file, __zp($c2) char info_status, __zp($dd) char brom_bank_start, __zp($42) unsigned long rom_size)
rom_read: {
    .const bank_set_brom1_bank = 0
    .label rom_read__13 = $e0
    .label fp = $e4
    .label rom_package_read = $db
    .label brom_bank_start = $dd
    .label y = $f2
    .label rom_bram_ptr = $65
    /// Holds the amount of bytes actually read in the memory to be flashed.
    .label rom_row_current = $4e
    // We start for ROM from 0x0:0x7800 !!!!
    .label rom_bram_bank = $da
    .label file = $bb
    .label rom_size = $42
    .label info_status = $c2
    .label rom_action_text = $d8
    // rom_read::bank_set_bram1
    // BRAM = bank
    // [1445] BRAM = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z BRAM
    // rom_read::bank_set_brom1
    // BROM = bank
    // [1446] BROM = rom_read::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // rom_read::@23
    // if(info_status == STATUS_READING)
    // [1447] if(rom_read::info_status#11==STATUS_READING) goto rom_read::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #STATUS_READING
    cmp.z info_status
    beq __b1
    // [1449] phi from rom_read::@23 to rom_read::@2 [phi:rom_read::@23->rom_read::@2]
    // [1449] phi rom_read::rom_action_text#10 = smc_action_text#2 [phi:rom_read::@23->rom_read::@2#0] -- pbuz1=pbuc1 
    lda #<smc_action_text_1
    sta.z rom_action_text
    lda #>smc_action_text_1
    sta.z rom_action_text+1
    jmp __b2
    // [1448] phi from rom_read::@23 to rom_read::@1 [phi:rom_read::@23->rom_read::@1]
    // rom_read::@1
  __b1:
    // [1449] phi from rom_read::@1 to rom_read::@2 [phi:rom_read::@1->rom_read::@2]
    // [1449] phi rom_read::rom_action_text#10 = smc_action_text#1 [phi:rom_read::@1->rom_read::@2#0] -- pbuz1=pbuc1 
    lda #<smc_action_text
    sta.z rom_action_text
    lda #>smc_action_text
    sta.z rom_action_text+1
    // rom_read::@2
  __b2:
    // unsigned long rom_address = rom_address_from_bank(brom_bank_start)
    // [1450] rom_address_from_bank::rom_bank#0 = rom_read::brom_bank_start#10 -- vbuaa=vbuz1 
    lda.z brom_bank_start
    // [1451] call rom_address_from_bank
    // [2569] phi from rom_read::@2 to rom_address_from_bank [phi:rom_read::@2->rom_address_from_bank]
    // [2569] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#0 [phi:rom_read::@2->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(brom_bank_start)
    // [1452] rom_address_from_bank::return#2 = rom_address_from_bank::return#0
    // rom_read::@25
    // [1453] rom_read::rom_address#0 = rom_address_from_bank::return#2
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1454] call snprintf_init
    // [1184] phi from rom_read::@25 to snprintf_init [phi:rom_read::@25->snprintf_init]
    // [1184] phi snprintf_init::s#30 = info_text [phi:rom_read::@25->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1455] phi from rom_read::@25 to rom_read::@26 [phi:rom_read::@25->rom_read::@26]
    // rom_read::@26
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1456] call printf_str
    // [1125] phi from rom_read::@26 to printf_str [phi:rom_read::@26->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:rom_read::@26->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = rom_read::s [phi:rom_read::@26->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@27
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1457] printf_string::str#17 = rom_read::file#10 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [1458] call printf_string
    // [1419] phi from rom_read::@27 to printf_string [phi:rom_read::@27->printf_string]
    // [1419] phi printf_string::putc#26 = &snputc [phi:rom_read::@27->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1419] phi printf_string::str#26 = printf_string::str#17 [phi:rom_read::@27->printf_string#1] -- register_copy 
    // [1419] phi printf_string::format_justify_left#26 = 0 [phi:rom_read::@27->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1419] phi printf_string::format_min_length#26 = 0 [phi:rom_read::@27->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [1459] phi from rom_read::@27 to rom_read::@28 [phi:rom_read::@27->rom_read::@28]
    // rom_read::@28
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1460] call printf_str
    // [1125] phi from rom_read::@28 to printf_str [phi:rom_read::@28->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:rom_read::@28->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = rom_read::s1 [phi:rom_read::@28->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@29
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1461] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1462] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1464] call display_action_text
    // [1200] phi from rom_read::@29 to display_action_text [phi:rom_read::@29->display_action_text]
    // [1200] phi display_action_text::info_text#25 = info_text [phi:rom_read::@29->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // rom_read::@30
    // FILE *fp = fopen(file, "r")
    // [1465] fopen::path#3 = rom_read::file#10 -- pbuz1=pbuz2 
    lda.z file
    sta.z fopen.path
    lda.z file+1
    sta.z fopen.path+1
    // [1466] call fopen
    // [2573] phi from rom_read::@30 to fopen [phi:rom_read::@30->fopen]
    // [2573] phi __errno#474 = __errno#103 [phi:rom_read::@30->fopen#0] -- register_copy 
    // [2573] phi fopen::pathtoken#0 = fopen::path#3 [phi:rom_read::@30->fopen#1] -- register_copy 
    // [2573] phi __stdio_filecount#27 = __stdio_filecount#126 [phi:rom_read::@30->fopen#2] -- register_copy 
    jsr fopen
    // FILE *fp = fopen(file, "r")
    // [1467] fopen::return#4 = fopen::return#2
    // rom_read::@31
    // [1468] rom_read::fp#0 = fopen::return#4 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [1469] if((struct $2 *)0==rom_read::fp#0) goto rom_read::@3 -- pssc1_eq_pssz1_then_la1 
    lda.z fp
    cmp #<0
    bne !+
    lda.z fp+1
    cmp #>0
    beq __b4
  !:
    // [1470] phi from rom_read::@31 to rom_read::@4 [phi:rom_read::@31->rom_read::@4]
    // rom_read::@4
    // gotoxy(x, y)
    // [1471] call gotoxy
    // [805] phi from rom_read::@4 to gotoxy [phi:rom_read::@4->gotoxy]
    // [805] phi gotoxy::y#37 = PROGRESS_Y [phi:rom_read::@4->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [805] phi gotoxy::x#37 = PROGRESS_X [phi:rom_read::@4->gotoxy#1] -- vbuyy=vbuc1 
    ldy #PROGRESS_X
    jsr gotoxy
    // [1472] phi from rom_read::@4 to rom_read::@5 [phi:rom_read::@4->rom_read::@5]
    // [1472] phi rom_read::y#11 = PROGRESS_Y [phi:rom_read::@4->rom_read::@5#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // [1472] phi rom_read::rom_row_current#10 = 0 [phi:rom_read::@4->rom_read::@5#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z rom_row_current
    sta.z rom_row_current+1
    // [1472] phi rom_read::brom_bank_start#11 = rom_read::brom_bank_start#10 [phi:rom_read::@4->rom_read::@5#2] -- register_copy 
    // [1472] phi rom_read::rom_address#10 = rom_read::rom_address#0 [phi:rom_read::@4->rom_read::@5#3] -- register_copy 
    // [1472] phi rom_read::rom_bram_ptr#13 = (char *)$7800 [phi:rom_read::@4->rom_read::@5#4] -- pbuz1=pbuc1 
    lda #<$7800
    sta.z rom_bram_ptr
    lda #>$7800
    sta.z rom_bram_ptr+1
    // [1472] phi rom_read::rom_bram_bank#10 = 0 [phi:rom_read::@4->rom_read::@5#5] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_bram_bank
    // [1472] phi rom_read::rom_file_size#13 = 0 [phi:rom_read::@4->rom_read::@5#6] -- vdum1=vduc1 
    sta rom_file_size
    sta rom_file_size+1
    lda #<0>>$10
    sta rom_file_size+2
    lda #>0>>$10
    sta rom_file_size+3
    // rom_read::@5
  __b5:
    // while (rom_file_size < rom_size)
    // [1473] if(rom_read::rom_file_size#13<rom_read::rom_size#12) goto rom_read::@6 -- vdum1_lt_vduz2_then_la1 
    lda rom_file_size+3
    cmp.z rom_size+3
    bcc __b6
    bne !+
    lda rom_file_size+2
    cmp.z rom_size+2
    bcc __b6
    bne !+
    lda rom_file_size+1
    cmp.z rom_size+1
    bcc __b6
    bne !+
    lda rom_file_size
    cmp.z rom_size
    bcc __b6
  !:
    // rom_read::@10
  __b10:
    // fclose(fp)
    // [1474] fclose::stream#1 = rom_read::fp#0
    // [1475] call fclose
    // [2654] phi from rom_read::@10 to fclose [phi:rom_read::@10->fclose]
    // [2654] phi fclose::stream#3 = fclose::stream#1 [phi:rom_read::@10->fclose#0] -- register_copy 
    jsr fclose
    // [1476] phi from rom_read::@10 to rom_read::@3 [phi:rom_read::@10->rom_read::@3]
    // [1476] phi __stdio_filecount#39 = __stdio_filecount#2 [phi:rom_read::@10->rom_read::@3#0] -- register_copy 
    // [1476] phi rom_read::return#0 = rom_read::rom_file_size#13 [phi:rom_read::@10->rom_read::@3#1] -- register_copy 
    rts
    // [1476] phi from rom_read::@31 to rom_read::@3 [phi:rom_read::@31->rom_read::@3]
  __b4:
    // [1476] phi __stdio_filecount#39 = __stdio_filecount#1 [phi:rom_read::@31->rom_read::@3#0] -- register_copy 
    // [1476] phi rom_read::return#0 = 0 [phi:rom_read::@31->rom_read::@3#1] -- vdum1=vduc1 
    lda #<0
    sta return
    sta return+1
    lda #<0>>$10
    sta return+2
    lda #>0>>$10
    sta return+3
    // rom_read::@3
    // rom_read::@return
    // }
    // [1477] return 
    rts
    // rom_read::@6
  __b6:
    // if(info_status == STATUS_CHECKING)
    // [1478] if(rom_read::info_status#11!=STATUS_CHECKING) goto rom_read::@35 -- vbuz1_neq_vbuc1_then_la1 
    lda #STATUS_CHECKING
    cmp.z info_status
    bne __b7
    // [1480] phi from rom_read::@6 to rom_read::@7 [phi:rom_read::@6->rom_read::@7]
    // [1480] phi rom_read::rom_bram_ptr#10 = (char *) 1024 [phi:rom_read::@6->rom_read::@7#0] -- pbuz1=pbuc1 
    lda #<$400
    sta.z rom_bram_ptr
    lda #>$400
    sta.z rom_bram_ptr+1
    // [1479] phi from rom_read::@6 to rom_read::@35 [phi:rom_read::@6->rom_read::@35]
    // rom_read::@35
    // [1480] phi from rom_read::@35 to rom_read::@7 [phi:rom_read::@35->rom_read::@7]
    // [1480] phi rom_read::rom_bram_ptr#10 = rom_read::rom_bram_ptr#13 [phi:rom_read::@35->rom_read::@7#0] -- register_copy 
    // rom_read::@7
  __b7:
    // display_action_text_reading(rom_action_text, file, rom_file_size, rom_size, rom_bram_bank, rom_bram_ptr)
    // [1481] display_action_text_reading::action#1 = rom_read::rom_action_text#10 -- pbuz1=pbuz2 
    lda.z rom_action_text
    sta.z display_action_text_reading.action
    lda.z rom_action_text+1
    sta.z display_action_text_reading.action+1
    // [1482] display_action_text_reading::file#1 = rom_read::file#10 -- pbuz1=pbuz2 
    lda.z file
    sta.z display_action_text_reading.file
    lda.z file+1
    sta.z display_action_text_reading.file+1
    // [1483] display_action_text_reading::bytes#1 = rom_read::rom_file_size#13 -- vduz1=vdum2 
    lda rom_file_size
    sta.z display_action_text_reading.bytes
    lda rom_file_size+1
    sta.z display_action_text_reading.bytes+1
    lda rom_file_size+2
    sta.z display_action_text_reading.bytes+2
    lda rom_file_size+3
    sta.z display_action_text_reading.bytes+3
    // [1484] display_action_text_reading::size#1 = rom_read::rom_size#12 -- vduz1=vduz2 
    lda.z rom_size
    sta.z display_action_text_reading.size
    lda.z rom_size+1
    sta.z display_action_text_reading.size+1
    lda.z rom_size+2
    sta.z display_action_text_reading.size+2
    lda.z rom_size+3
    sta.z display_action_text_reading.size+3
    // [1485] display_action_text_reading::bram_bank#1 = rom_read::rom_bram_bank#10 -- vbuz1=vbuz2 
    lda.z rom_bram_bank
    sta.z display_action_text_reading.bram_bank
    // [1486] display_action_text_reading::bram_ptr#1 = rom_read::rom_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z rom_bram_ptr
    sta.z display_action_text_reading.bram_ptr
    lda.z rom_bram_ptr+1
    sta.z display_action_text_reading.bram_ptr+1
    // [1487] call display_action_text_reading
    // [2683] phi from rom_read::@7 to display_action_text_reading [phi:rom_read::@7->display_action_text_reading]
    // [2683] phi display_action_text_reading::bram_ptr#10 = display_action_text_reading::bram_ptr#1 [phi:rom_read::@7->display_action_text_reading#0] -- register_copy 
    // [2683] phi display_action_text_reading::bram_bank#10 = display_action_text_reading::bram_bank#1 [phi:rom_read::@7->display_action_text_reading#1] -- register_copy 
    // [2683] phi display_action_text_reading::size#10 = display_action_text_reading::size#1 [phi:rom_read::@7->display_action_text_reading#2] -- register_copy 
    // [2683] phi display_action_text_reading::bytes#3 = display_action_text_reading::bytes#1 [phi:rom_read::@7->display_action_text_reading#3] -- register_copy 
    // [2683] phi display_action_text_reading::file#3 = display_action_text_reading::file#1 [phi:rom_read::@7->display_action_text_reading#4] -- register_copy 
    // [2683] phi display_action_text_reading::action#3 = display_action_text_reading::action#1 [phi:rom_read::@7->display_action_text_reading#5] -- register_copy 
    jsr display_action_text_reading
    // rom_read::@32
    // rom_address % 0x04000
    // [1488] rom_read::$13 = rom_read::rom_address#10 & $4000-1 -- vduz1=vdum2_band_vduc1 
    lda rom_address
    and #<$4000-1
    sta.z rom_read__13
    lda rom_address+1
    and #>$4000-1
    sta.z rom_read__13+1
    lda rom_address+2
    and #<$4000-1>>$10
    sta.z rom_read__13+2
    lda rom_address+3
    and #>$4000-1>>$10
    sta.z rom_read__13+3
    // if (!(rom_address % 0x04000))
    // [1489] if(0!=rom_read::$13) goto rom_read::@8 -- 0_neq_vduz1_then_la1 
    lda.z rom_read__13
    ora.z rom_read__13+1
    ora.z rom_read__13+2
    ora.z rom_read__13+3
    bne __b8
    // rom_read::@17
    // brom_bank_start++;
    // [1490] rom_read::brom_bank_start#0 = ++ rom_read::brom_bank_start#11 -- vbuz1=_inc_vbuz1 
    inc.z brom_bank_start
    // [1491] phi from rom_read::@17 rom_read::@32 to rom_read::@8 [phi:rom_read::@17/rom_read::@32->rom_read::@8]
    // [1491] phi rom_read::brom_bank_start#16 = rom_read::brom_bank_start#0 [phi:rom_read::@17/rom_read::@32->rom_read::@8#0] -- register_copy 
    // rom_read::@8
  __b8:
    // rom_read::bank_set_bram2
    // BRAM = bank
    // [1492] BRAM = rom_read::rom_bram_bank#10 -- vbuz1=vbuz2 
    lda.z rom_bram_bank
    sta.z BRAM
    // rom_read::@24
    // unsigned int rom_package_read = fgets(rom_bram_ptr, ROM_PROGRESS_CELL, fp)
    // [1493] fgets::ptr#4 = rom_read::rom_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z rom_bram_ptr
    sta.z fgets.ptr
    lda.z rom_bram_ptr+1
    sta.z fgets.ptr+1
    // [1494] fgets::stream#2 = rom_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.stream
    lda.z fp+1
    sta.z fgets.stream+1
    // [1495] call fgets
    // [2714] phi from rom_read::@24 to fgets [phi:rom_read::@24->fgets]
    // [2714] phi fgets::ptr#14 = fgets::ptr#4 [phi:rom_read::@24->fgets#0] -- register_copy 
    // [2714] phi fgets::size#10 = ROM_PROGRESS_CELL [phi:rom_read::@24->fgets#1] -- vwum1=vwuc1 
    lda #<ROM_PROGRESS_CELL
    sta fgets.size
    lda #>ROM_PROGRESS_CELL
    sta fgets.size+1
    // [2714] phi fgets::stream#4 = fgets::stream#2 [phi:rom_read::@24->fgets#2] -- register_copy 
    jsr fgets
    // unsigned int rom_package_read = fgets(rom_bram_ptr, ROM_PROGRESS_CELL, fp)
    // [1496] fgets::return#12 = fgets::return#1
    // rom_read::@33
    // [1497] rom_read::rom_package_read#0 = fgets::return#12 -- vwuz1=vwum2 
    lda fgets.return
    sta.z rom_package_read
    lda fgets.return+1
    sta.z rom_package_read+1
    // if (!rom_package_read)
    // [1498] if(0!=rom_read::rom_package_read#0) goto rom_read::@9 -- 0_neq_vwuz1_then_la1 
    lda.z rom_package_read
    ora.z rom_package_read+1
    bne __b9
    jmp __b10
    // rom_read::@9
  __b9:
    // if(info_status == STATUS_CHECKING)
    // [1499] if(rom_read::info_status#11!=STATUS_CHECKING) goto rom_read::@11 -- vbuz1_neq_vbuc1_then_la1 
    lda #STATUS_CHECKING
    cmp.z info_status
    bne __b11
    // rom_read::@18
    // if(rom_file_size == 0x0)
    // [1500] if(rom_read::rom_file_size#13!=0) goto rom_read::@12 -- vdum1_neq_0_then_la1 
    lda rom_file_size
    ora rom_file_size+1
    ora rom_file_size+2
    ora rom_file_size+3
    bne __b12
    // rom_read::@19
    // rom_chip*8
    // [1501] rom_read::$24 = rom_read::rom_chip#20 << 3 -- vbuaa=vbum1_rol_3 
    lda rom_chip
    asl
    asl
    asl
    // rom_get_github_commit_id(&rom_file_github[rom_chip*8], (char*)0x0400)
    // [1502] rom_get_github_commit_id::commit_id#0 = rom_file_github + rom_read::$24 -- pbuz1=pbuc1_plus_vbuaa 
    clc
    adc #<rom_file_github
    sta.z rom_get_github_commit_id.commit_id
    lda #>rom_file_github
    adc #0
    sta.z rom_get_github_commit_id.commit_id+1
    // [1503] call rom_get_github_commit_id
    // [1998] phi from rom_read::@19 to rom_get_github_commit_id [phi:rom_read::@19->rom_get_github_commit_id]
    // [1998] phi rom_get_github_commit_id::commit_id#6 = rom_get_github_commit_id::commit_id#0 [phi:rom_read::@19->rom_get_github_commit_id#0] -- register_copy 
    // [1998] phi rom_get_github_commit_id::from#6 = (char *) 1024 [phi:rom_read::@19->rom_get_github_commit_id#1] -- pbuz1=pbuc1 
    lda #<$400
    sta.z rom_get_github_commit_id.from
    lda #>$400
    sta.z rom_get_github_commit_id.from+1
    jsr rom_get_github_commit_id
    // rom_read::@12
  __b12:
    // if(rom_file_size == 0x3E00)
    // [1504] if(rom_read::rom_file_size#13!=$3e00) goto rom_read::@11 -- vdum1_neq_vduc1_then_la1 
    lda rom_file_size+3
    cmp #>$3e00>>$10
    bne __b11
    lda rom_file_size+2
    cmp #<$3e00>>$10
    bne __b11
    lda rom_file_size+1
    cmp #>$3e00
    bne __b11
    lda rom_file_size
    cmp #<$3e00
    bne __b11
    // rom_read::@13
    // rom_file_release[rom_chip] = *((char*)(0x0400+0x0180))
    // [1505] rom_file_release[rom_read::rom_chip#20] = *((char *)$400+$180) -- pbuc1_derefidx_vbum1=_deref_pbuc2 
    lda $400+$180
    ldy rom_chip
    sta rom_file_release,y
    // rom_read::@11
  __b11:
    // if (rom_row_current == ROM_PROGRESS_ROW)
    // [1506] if(rom_read::rom_row_current#10!=ROM_PROGRESS_ROW) goto rom_read::@14 -- vwuz1_neq_vwuc1_then_la1 
    lda.z rom_row_current+1
    cmp #>ROM_PROGRESS_ROW
    bne __b14
    lda.z rom_row_current
    cmp #<ROM_PROGRESS_ROW
    bne __b14
    // rom_read::@20
    // gotoxy(x, ++y);
    // [1507] rom_read::y#1 = ++ rom_read::y#11 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [1508] gotoxy::y#28 = rom_read::y#1 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [1509] call gotoxy
    // [805] phi from rom_read::@20 to gotoxy [phi:rom_read::@20->gotoxy]
    // [805] phi gotoxy::y#37 = gotoxy::y#28 [phi:rom_read::@20->gotoxy#0] -- register_copy 
    // [805] phi gotoxy::x#37 = PROGRESS_X [phi:rom_read::@20->gotoxy#1] -- vbuyy=vbuc1 
    ldy #PROGRESS_X
    jsr gotoxy
    // [1510] phi from rom_read::@20 to rom_read::@14 [phi:rom_read::@20->rom_read::@14]
    // [1510] phi rom_read::y#33 = rom_read::y#1 [phi:rom_read::@20->rom_read::@14#0] -- register_copy 
    // [1510] phi rom_read::rom_row_current#4 = 0 [phi:rom_read::@20->rom_read::@14#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z rom_row_current
    sta.z rom_row_current+1
    // [1510] phi from rom_read::@11 to rom_read::@14 [phi:rom_read::@11->rom_read::@14]
    // [1510] phi rom_read::y#33 = rom_read::y#11 [phi:rom_read::@11->rom_read::@14#0] -- register_copy 
    // [1510] phi rom_read::rom_row_current#4 = rom_read::rom_row_current#10 [phi:rom_read::@11->rom_read::@14#1] -- register_copy 
    // rom_read::@14
  __b14:
    // if(info_status == STATUS_READING)
    // [1511] if(rom_read::info_status#11!=STATUS_READING) goto rom_read::@15 -- vbuz1_neq_vbuc1_then_la1 
    lda #STATUS_READING
    cmp.z info_status
    bne __b15
    // rom_read::@21
    // cputc('.')
    // [1512] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [1513] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_read::@15
  __b15:
    // rom_bram_ptr += rom_package_read
    // [1515] rom_read::rom_bram_ptr#2 = rom_read::rom_bram_ptr#10 + rom_read::rom_package_read#0 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z rom_bram_ptr
    adc.z rom_package_read
    sta.z rom_bram_ptr
    lda.z rom_bram_ptr+1
    adc.z rom_package_read+1
    sta.z rom_bram_ptr+1
    // rom_address += rom_package_read
    // [1516] rom_read::rom_address#1 = rom_read::rom_address#10 + rom_read::rom_package_read#0 -- vdum1=vdum1_plus_vwuz2 
    lda rom_address
    clc
    adc.z rom_package_read
    sta rom_address
    lda rom_address+1
    adc.z rom_package_read+1
    sta rom_address+1
    lda rom_address+2
    adc #0
    sta rom_address+2
    lda rom_address+3
    adc #0
    sta rom_address+3
    // rom_file_size += rom_package_read
    // [1517] rom_read::rom_file_size#1 = rom_read::rom_file_size#13 + rom_read::rom_package_read#0 -- vdum1=vdum1_plus_vwuz2 
    lda rom_file_size
    clc
    adc.z rom_package_read
    sta rom_file_size
    lda rom_file_size+1
    adc.z rom_package_read+1
    sta rom_file_size+1
    lda rom_file_size+2
    adc #0
    sta rom_file_size+2
    lda rom_file_size+3
    adc #0
    sta rom_file_size+3
    // rom_row_current += rom_package_read
    // [1518] rom_read::rom_row_current#2 = rom_read::rom_row_current#4 + rom_read::rom_package_read#0 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z rom_row_current
    adc.z rom_package_read
    sta.z rom_row_current
    lda.z rom_row_current+1
    adc.z rom_package_read+1
    sta.z rom_row_current+1
    // if (rom_bram_ptr == (bram_ptr_t)BRAM_HIGH)
    // [1519] if(rom_read::rom_bram_ptr#2!=(char *)$c000) goto rom_read::@16 -- pbuz1_neq_pbuc1_then_la1 
    lda.z rom_bram_ptr+1
    cmp #>$c000
    bne __b16
    lda.z rom_bram_ptr
    cmp #<$c000
    bne __b16
    // rom_read::@22
    // rom_bram_bank++;
    // [1520] rom_read::rom_bram_bank#1 = ++ rom_read::rom_bram_bank#10 -- vbuz1=_inc_vbuz1 
    inc.z rom_bram_bank
    // [1521] phi from rom_read::@22 to rom_read::@16 [phi:rom_read::@22->rom_read::@16]
    // [1521] phi rom_read::rom_bram_bank#14 = rom_read::rom_bram_bank#1 [phi:rom_read::@22->rom_read::@16#0] -- register_copy 
    // [1521] phi rom_read::rom_bram_ptr#8 = (char *)$a000 [phi:rom_read::@22->rom_read::@16#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z rom_bram_ptr
    lda #>$a000
    sta.z rom_bram_ptr+1
    // [1521] phi from rom_read::@15 to rom_read::@16 [phi:rom_read::@15->rom_read::@16]
    // [1521] phi rom_read::rom_bram_bank#14 = rom_read::rom_bram_bank#10 [phi:rom_read::@15->rom_read::@16#0] -- register_copy 
    // [1521] phi rom_read::rom_bram_ptr#8 = rom_read::rom_bram_ptr#2 [phi:rom_read::@15->rom_read::@16#1] -- register_copy 
    // rom_read::@16
  __b16:
    // if (rom_bram_ptr == (bram_ptr_t)RAM_HIGH)
    // [1522] if(rom_read::rom_bram_ptr#8!=(char *)$9800) goto rom_read::@34 -- pbuz1_neq_pbuc1_then_la1 
    lda.z rom_bram_ptr+1
    cmp #>$9800
    beq !__b5+
    jmp __b5
  !__b5:
    lda.z rom_bram_ptr
    cmp #<$9800
    beq !__b5+
    jmp __b5
  !__b5:
    // [1472] phi from rom_read::@16 to rom_read::@5 [phi:rom_read::@16->rom_read::@5]
    // [1472] phi rom_read::y#11 = rom_read::y#33 [phi:rom_read::@16->rom_read::@5#0] -- register_copy 
    // [1472] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#2 [phi:rom_read::@16->rom_read::@5#1] -- register_copy 
    // [1472] phi rom_read::brom_bank_start#11 = rom_read::brom_bank_start#16 [phi:rom_read::@16->rom_read::@5#2] -- register_copy 
    // [1472] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@16->rom_read::@5#3] -- register_copy 
    // [1472] phi rom_read::rom_bram_ptr#13 = (char *)$a000 [phi:rom_read::@16->rom_read::@5#4] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z rom_bram_ptr
    lda #>$a000
    sta.z rom_bram_ptr+1
    // [1472] phi rom_read::rom_bram_bank#10 = 1 [phi:rom_read::@16->rom_read::@5#5] -- vbuz1=vbuc1 
    lda #1
    sta.z rom_bram_bank
    // [1472] phi rom_read::rom_file_size#13 = rom_read::rom_file_size#1 [phi:rom_read::@16->rom_read::@5#6] -- register_copy 
    jmp __b5
    // [1523] phi from rom_read::@16 to rom_read::@34 [phi:rom_read::@16->rom_read::@34]
    // rom_read::@34
    // [1472] phi from rom_read::@34 to rom_read::@5 [phi:rom_read::@34->rom_read::@5]
    // [1472] phi rom_read::y#11 = rom_read::y#33 [phi:rom_read::@34->rom_read::@5#0] -- register_copy 
    // [1472] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#2 [phi:rom_read::@34->rom_read::@5#1] -- register_copy 
    // [1472] phi rom_read::brom_bank_start#11 = rom_read::brom_bank_start#16 [phi:rom_read::@34->rom_read::@5#2] -- register_copy 
    // [1472] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@34->rom_read::@5#3] -- register_copy 
    // [1472] phi rom_read::rom_bram_ptr#13 = rom_read::rom_bram_ptr#8 [phi:rom_read::@34->rom_read::@5#4] -- register_copy 
    // [1472] phi rom_read::rom_bram_bank#10 = rom_read::rom_bram_bank#14 [phi:rom_read::@34->rom_read::@5#5] -- register_copy 
    // [1472] phi rom_read::rom_file_size#13 = rom_read::rom_file_size#1 [phi:rom_read::@34->rom_read::@5#6] -- register_copy 
  .segment Data
    s: .text "Opening "
    .byte 0
    s1: .text " from SD card ..."
    .byte 0
    .label rom_address = rom_read_byte.address
    return: .dword 0
    .label rom_file_size = return
    .label rom_chip = main.check_status_smc6_return
}
.segment Code
  // rom_verify
// __zp($55) unsigned long rom_verify(__mem() char rom_chip, __register(X) char rom_bank_start, __mem() unsigned long file_size)
rom_verify: {
    .label rom_verify__17 = $46
    .label rom_address = $4a
    .label equal_bytes = $46
    .label y = $cf
    .label rom_bram_ptr = $59
    .label rom_different_bytes = $55
    .label return = $55
    .label progress_row_current = $5d
    // rom_verify::bank_set_bram1
    // BRAM = bank
    // [1525] BRAM = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z BRAM
    // rom_verify::@11
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [1526] rom_address_from_bank::rom_bank#1 = rom_verify::rom_bank_start#0 -- vbuaa=vbuxx 
    txa
    // [1527] call rom_address_from_bank
    // [2569] phi from rom_verify::@11 to rom_address_from_bank [phi:rom_verify::@11->rom_address_from_bank]
    // [2569] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#1 [phi:rom_verify::@11->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [1528] rom_address_from_bank::return#3 = rom_address_from_bank::return#0 -- vduz1=vdum2 
    lda rom_address_from_bank.return
    sta.z rom_address_from_bank.return_1
    lda rom_address_from_bank.return+1
    sta.z rom_address_from_bank.return_1+1
    lda rom_address_from_bank.return+2
    sta.z rom_address_from_bank.return_1+2
    lda rom_address_from_bank.return+3
    sta.z rom_address_from_bank.return_1+3
    // rom_verify::@12
    // [1529] rom_verify::rom_address#0 = rom_address_from_bank::return#3
    // unsigned long rom_boundary = rom_address + file_size
    // [1530] rom_verify::rom_boundary#0 = rom_verify::rom_address#0 + rom_verify::file_size#0 -- vdum1=vduz2_plus_vdum1 
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
    // display_info_rom(rom_chip, STATUS_COMPARING, "")
    // [1531] display_info_rom::rom_chip#2 = rom_verify::rom_chip#0
    // [1532] call display_info_rom
    // [1368] phi from rom_verify::@12 to display_info_rom [phi:rom_verify::@12->display_info_rom]
    // [1368] phi display_info_rom::info_text#16 = str [phi:rom_verify::@12->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<str
    sta.z display_info_rom.info_text
    lda #>str
    sta.z display_info_rom.info_text+1
    // [1368] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#2 [phi:rom_verify::@12->display_info_rom#1] -- register_copy 
    // [1368] phi display_info_rom::info_status#16 = STATUS_COMPARING [phi:rom_verify::@12->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_COMPARING
    sta display_info_rom.info_status
    jsr display_info_rom
    // [1533] phi from rom_verify::@12 to rom_verify::@13 [phi:rom_verify::@12->rom_verify::@13]
    // rom_verify::@13
    // gotoxy(x, y)
    // [1534] call gotoxy
    // [805] phi from rom_verify::@13 to gotoxy [phi:rom_verify::@13->gotoxy]
    // [805] phi gotoxy::y#37 = PROGRESS_Y [phi:rom_verify::@13->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [805] phi gotoxy::x#37 = PROGRESS_X [phi:rom_verify::@13->gotoxy#1] -- vbuyy=vbuc1 
    ldy #PROGRESS_X
    jsr gotoxy
    // [1535] phi from rom_verify::@13 to rom_verify::@1 [phi:rom_verify::@13->rom_verify::@1]
    // [1535] phi rom_verify::y#3 = PROGRESS_Y [phi:rom_verify::@13->rom_verify::@1#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // [1535] phi rom_verify::progress_row_current#3 = 0 [phi:rom_verify::@13->rom_verify::@1#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z progress_row_current
    sta.z progress_row_current+1
    // [1535] phi rom_verify::rom_different_bytes#11 = 0 [phi:rom_verify::@13->rom_verify::@1#2] -- vduz1=vduc1 
    sta.z rom_different_bytes
    sta.z rom_different_bytes+1
    lda #<0>>$10
    sta.z rom_different_bytes+2
    lda #>0>>$10
    sta.z rom_different_bytes+3
    // [1535] phi rom_verify::rom_bram_ptr#10 = (char *)$7800 [phi:rom_verify::@13->rom_verify::@1#3] -- pbuz1=pbuc1 
    lda #<$7800
    sta.z rom_bram_ptr
    lda #>$7800
    sta.z rom_bram_ptr+1
    // [1535] phi rom_verify::rom_bram_bank#11 = 0 [phi:rom_verify::@13->rom_verify::@1#4] -- vbum1=vbuc1 
    lda #0
    sta rom_bram_bank
    // [1535] phi rom_verify::rom_address#12 = rom_verify::rom_address#0 [phi:rom_verify::@13->rom_verify::@1#5] -- register_copy 
    // rom_verify::@1
  __b1:
    // while (rom_address < rom_boundary)
    // [1536] if(rom_verify::rom_address#12<rom_verify::rom_boundary#0) goto rom_verify::@2 -- vduz1_lt_vdum2_then_la1 
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
    // [1537] return 
    rts
    // rom_verify::@2
  __b2:
    // unsigned int equal_bytes = rom_compare(rom_bram_bank, (bram_ptr_t)rom_bram_ptr, rom_address, ROM_PROGRESS_CELL)
    // [1538] rom_compare::bank_ram#0 = rom_verify::rom_bram_bank#11 -- vbuxx=vbum1 
    ldx rom_bram_bank
    // [1539] rom_compare::ptr_ram#1 = rom_verify::rom_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z rom_bram_ptr
    sta.z rom_compare.ptr_ram
    lda.z rom_bram_ptr+1
    sta.z rom_compare.ptr_ram+1
    // [1540] rom_compare::rom_compare_address#0 = rom_verify::rom_address#12 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_compare.rom_compare_address
    lda.z rom_address+1
    sta.z rom_compare.rom_compare_address+1
    lda.z rom_address+2
    sta.z rom_compare.rom_compare_address+2
    lda.z rom_address+3
    sta.z rom_compare.rom_compare_address+3
    // [1541] call rom_compare
  // {asm{.byte $db}}
    // [2768] phi from rom_verify::@2 to rom_compare [phi:rom_verify::@2->rom_compare]
    // [2768] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#1 [phi:rom_verify::@2->rom_compare#0] -- register_copy 
    // [2768] phi rom_compare::rom_compare_size#11 = ROM_PROGRESS_CELL [phi:rom_verify::@2->rom_compare#1] -- vwuz1=vwuc1 
    lda #<ROM_PROGRESS_CELL
    sta.z rom_compare.rom_compare_size
    lda #>ROM_PROGRESS_CELL
    sta.z rom_compare.rom_compare_size+1
    // [2768] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#0 [phi:rom_verify::@2->rom_compare#2] -- register_copy 
    // [2768] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#0 [phi:rom_verify::@2->rom_compare#3] -- register_copy 
    jsr rom_compare
    // unsigned int equal_bytes = rom_compare(rom_bram_bank, (bram_ptr_t)rom_bram_ptr, rom_address, ROM_PROGRESS_CELL)
    // [1542] rom_compare::return#2 = rom_compare::equal_bytes#2
    // rom_verify::@14
    // [1543] rom_verify::equal_bytes#0 = rom_compare::return#2
    // if (progress_row_current == ROM_PROGRESS_ROW)
    // [1544] if(rom_verify::progress_row_current#3!=ROM_PROGRESS_ROW) goto rom_verify::@3 -- vwuz1_neq_vwuc1_then_la1 
    lda.z progress_row_current+1
    cmp #>ROM_PROGRESS_ROW
    bne __b3
    lda.z progress_row_current
    cmp #<ROM_PROGRESS_ROW
    bne __b3
    // rom_verify::@8
    // gotoxy(x, ++y);
    // [1545] rom_verify::y#1 = ++ rom_verify::y#3 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [1546] gotoxy::y#30 = rom_verify::y#1 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [1547] call gotoxy
    // [805] phi from rom_verify::@8 to gotoxy [phi:rom_verify::@8->gotoxy]
    // [805] phi gotoxy::y#37 = gotoxy::y#30 [phi:rom_verify::@8->gotoxy#0] -- register_copy 
    // [805] phi gotoxy::x#37 = PROGRESS_X [phi:rom_verify::@8->gotoxy#1] -- vbuyy=vbuc1 
    ldy #PROGRESS_X
    jsr gotoxy
    // [1548] phi from rom_verify::@8 to rom_verify::@3 [phi:rom_verify::@8->rom_verify::@3]
    // [1548] phi rom_verify::y#11 = rom_verify::y#1 [phi:rom_verify::@8->rom_verify::@3#0] -- register_copy 
    // [1548] phi rom_verify::progress_row_current#4 = 0 [phi:rom_verify::@8->rom_verify::@3#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z progress_row_current
    sta.z progress_row_current+1
    // [1548] phi from rom_verify::@14 to rom_verify::@3 [phi:rom_verify::@14->rom_verify::@3]
    // [1548] phi rom_verify::y#11 = rom_verify::y#3 [phi:rom_verify::@14->rom_verify::@3#0] -- register_copy 
    // [1548] phi rom_verify::progress_row_current#4 = rom_verify::progress_row_current#3 [phi:rom_verify::@14->rom_verify::@3#1] -- register_copy 
    // rom_verify::@3
  __b3:
    // if (equal_bytes != ROM_PROGRESS_CELL)
    // [1549] if(rom_verify::equal_bytes#0!=ROM_PROGRESS_CELL) goto rom_verify::@4 -- vwuz1_neq_vwuc1_then_la1 
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
    // [1550] stackpush(char) = '=' -- _stackpushbyte_=vbuc1 
    lda #'='
    pha
    // [1551] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_verify::@5
  __b5:
    // rom_bram_ptr += ROM_PROGRESS_CELL
    // [1553] rom_verify::rom_bram_ptr#1 = rom_verify::rom_bram_ptr#10 + ROM_PROGRESS_CELL -- pbuz1=pbuz1_plus_vwuc1 
    lda.z rom_bram_ptr
    clc
    adc #<ROM_PROGRESS_CELL
    sta.z rom_bram_ptr
    lda.z rom_bram_ptr+1
    adc #>ROM_PROGRESS_CELL
    sta.z rom_bram_ptr+1
    // rom_address += ROM_PROGRESS_CELL
    // [1554] rom_verify::rom_address#1 = rom_verify::rom_address#12 + ROM_PROGRESS_CELL -- vduz1=vduz1_plus_vwuc1 
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
    // [1555] rom_verify::progress_row_current#11 = rom_verify::progress_row_current#4 + ROM_PROGRESS_CELL -- vwuz1=vwuz1_plus_vwuc1 
    lda.z progress_row_current
    clc
    adc #<ROM_PROGRESS_CELL
    sta.z progress_row_current
    lda.z progress_row_current+1
    adc #>ROM_PROGRESS_CELL
    sta.z progress_row_current+1
    // if (rom_bram_ptr == BRAM_HIGH)
    // [1556] if(rom_verify::rom_bram_ptr#1!=$c000) goto rom_verify::@6 -- pbuz1_neq_vwuc1_then_la1 
    lda.z rom_bram_ptr+1
    cmp #>$c000
    bne __b6
    lda.z rom_bram_ptr
    cmp #<$c000
    bne __b6
    // rom_verify::@10
    // rom_bram_bank++;
    // [1557] rom_verify::rom_bram_bank#1 = ++ rom_verify::rom_bram_bank#11 -- vbum1=_inc_vbum1 
    inc rom_bram_bank
    // [1558] phi from rom_verify::@10 to rom_verify::@6 [phi:rom_verify::@10->rom_verify::@6]
    // [1558] phi rom_verify::rom_bram_bank#25 = rom_verify::rom_bram_bank#1 [phi:rom_verify::@10->rom_verify::@6#0] -- register_copy 
    // [1558] phi rom_verify::rom_bram_ptr#6 = (char *)$a000 [phi:rom_verify::@10->rom_verify::@6#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z rom_bram_ptr
    lda #>$a000
    sta.z rom_bram_ptr+1
    // [1558] phi from rom_verify::@5 to rom_verify::@6 [phi:rom_verify::@5->rom_verify::@6]
    // [1558] phi rom_verify::rom_bram_bank#25 = rom_verify::rom_bram_bank#11 [phi:rom_verify::@5->rom_verify::@6#0] -- register_copy 
    // [1558] phi rom_verify::rom_bram_ptr#6 = rom_verify::rom_bram_ptr#1 [phi:rom_verify::@5->rom_verify::@6#1] -- register_copy 
    // rom_verify::@6
  __b6:
    // if (rom_bram_ptr == RAM_HIGH)
    // [1559] if(rom_verify::rom_bram_ptr#6!=$9800) goto rom_verify::@24 -- pbuz1_neq_vwuc1_then_la1 
    lda.z rom_bram_ptr+1
    cmp #>$9800
    bne __b7
    lda.z rom_bram_ptr
    cmp #<$9800
    bne __b7
    // [1561] phi from rom_verify::@6 to rom_verify::@7 [phi:rom_verify::@6->rom_verify::@7]
    // [1561] phi rom_verify::rom_bram_ptr#11 = (char *)$a000 [phi:rom_verify::@6->rom_verify::@7#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z rom_bram_ptr
    lda #>$a000
    sta.z rom_bram_ptr+1
    // [1561] phi rom_verify::rom_bram_bank#10 = 1 [phi:rom_verify::@6->rom_verify::@7#1] -- vbum1=vbuc1 
    lda #1
    sta rom_bram_bank
    // [1560] phi from rom_verify::@6 to rom_verify::@24 [phi:rom_verify::@6->rom_verify::@24]
    // rom_verify::@24
    // [1561] phi from rom_verify::@24 to rom_verify::@7 [phi:rom_verify::@24->rom_verify::@7]
    // [1561] phi rom_verify::rom_bram_ptr#11 = rom_verify::rom_bram_ptr#6 [phi:rom_verify::@24->rom_verify::@7#0] -- register_copy 
    // [1561] phi rom_verify::rom_bram_bank#10 = rom_verify::rom_bram_bank#25 [phi:rom_verify::@24->rom_verify::@7#1] -- register_copy 
    // rom_verify::@7
  __b7:
    // ROM_PROGRESS_CELL - equal_bytes
    // [1562] rom_verify::$17 = ROM_PROGRESS_CELL - rom_verify::equal_bytes#0 -- vwuz1=vwuc1_minus_vwuz1 
    lda #<ROM_PROGRESS_CELL
    sec
    sbc.z rom_verify__17
    sta.z rom_verify__17
    lda #>ROM_PROGRESS_CELL
    sbc.z rom_verify__17+1
    sta.z rom_verify__17+1
    // rom_different_bytes += (ROM_PROGRESS_CELL - equal_bytes)
    // [1563] rom_verify::rom_different_bytes#1 = rom_verify::rom_different_bytes#11 + rom_verify::$17 -- vduz1=vduz1_plus_vwuz2 
    lda.z rom_different_bytes
    clc
    adc.z rom_verify__17
    sta.z rom_different_bytes
    lda.z rom_different_bytes+1
    adc.z rom_verify__17+1
    sta.z rom_different_bytes+1
    lda.z rom_different_bytes+2
    adc #0
    sta.z rom_different_bytes+2
    lda.z rom_different_bytes+3
    adc #0
    sta.z rom_different_bytes+3
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1564] call snprintf_init
    // [1184] phi from rom_verify::@7 to snprintf_init [phi:rom_verify::@7->snprintf_init]
    // [1184] phi snprintf_init::s#30 = info_text [phi:rom_verify::@7->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1565] phi from rom_verify::@7 to rom_verify::@15 [phi:rom_verify::@7->rom_verify::@15]
    // rom_verify::@15
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1566] call printf_str
    // [1125] phi from rom_verify::@15 to printf_str [phi:rom_verify::@15->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:rom_verify::@15->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = rom_verify::s [phi:rom_verify::@15->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@16
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1567] printf_ulong::uvalue#6 = rom_verify::rom_different_bytes#1 -- vdum1=vduz2 
    lda.z rom_different_bytes
    sta printf_ulong.uvalue
    lda.z rom_different_bytes+1
    sta printf_ulong.uvalue+1
    lda.z rom_different_bytes+2
    sta printf_ulong.uvalue+2
    lda.z rom_different_bytes+3
    sta printf_ulong.uvalue+3
    // [1568] call printf_ulong
    // [1588] phi from rom_verify::@16 to printf_ulong [phi:rom_verify::@16->printf_ulong]
    // [1588] phi printf_ulong::format_zero_padding#14 = 1 [phi:rom_verify::@16->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1588] phi printf_ulong::format_min_length#14 = 5 [phi:rom_verify::@16->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1588] phi printf_ulong::format_radix#14 = HEXADECIMAL [phi:rom_verify::@16->printf_ulong#2] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [1588] phi printf_ulong::uvalue#14 = printf_ulong::uvalue#6 [phi:rom_verify::@16->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1569] phi from rom_verify::@16 to rom_verify::@17 [phi:rom_verify::@16->rom_verify::@17]
    // rom_verify::@17
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1570] call printf_str
    // [1125] phi from rom_verify::@17 to printf_str [phi:rom_verify::@17->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:rom_verify::@17->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = rom_verify::s1 [phi:rom_verify::@17->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@18
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1571] printf_uchar::uvalue#11 = rom_verify::rom_bram_bank#10 -- vbuxx=vbum1 
    ldx rom_bram_bank
    // [1572] call printf_uchar
    // [1189] phi from rom_verify::@18 to printf_uchar [phi:rom_verify::@18->printf_uchar]
    // [1189] phi printf_uchar::format_zero_padding#15 = 1 [phi:rom_verify::@18->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1189] phi printf_uchar::format_min_length#15 = 2 [phi:rom_verify::@18->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1189] phi printf_uchar::putc#15 = &snputc [phi:rom_verify::@18->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1189] phi printf_uchar::format_radix#15 = HEXADECIMAL [phi:rom_verify::@18->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #HEXADECIMAL
    // [1189] phi printf_uchar::uvalue#15 = printf_uchar::uvalue#11 [phi:rom_verify::@18->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1573] phi from rom_verify::@18 to rom_verify::@19 [phi:rom_verify::@18->rom_verify::@19]
    // rom_verify::@19
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1574] call printf_str
    // [1125] phi from rom_verify::@19 to printf_str [phi:rom_verify::@19->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:rom_verify::@19->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = s2 [phi:rom_verify::@19->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@20
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1575] printf_uint::uvalue#5 = (unsigned int)rom_verify::rom_bram_ptr#11 -- vwum1=vwuz2 
    lda.z rom_bram_ptr
    sta printf_uint.uvalue
    lda.z rom_bram_ptr+1
    sta printf_uint.uvalue+1
    // [1576] call printf_uint
    // [2015] phi from rom_verify::@20 to printf_uint [phi:rom_verify::@20->printf_uint]
    // [2015] phi printf_uint::format_zero_padding#10 = 1 [phi:rom_verify::@20->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [2015] phi printf_uint::format_min_length#10 = 4 [phi:rom_verify::@20->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [2015] phi printf_uint::putc#10 = &snputc [phi:rom_verify::@20->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [2015] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:rom_verify::@20->printf_uint#3] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [2015] phi printf_uint::uvalue#10 = printf_uint::uvalue#5 [phi:rom_verify::@20->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1577] phi from rom_verify::@20 to rom_verify::@21 [phi:rom_verify::@20->rom_verify::@21]
    // rom_verify::@21
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1578] call printf_str
    // [1125] phi from rom_verify::@21 to printf_str [phi:rom_verify::@21->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:rom_verify::@21->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = rom_verify::s3 [phi:rom_verify::@21->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@22
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1579] printf_ulong::uvalue#7 = rom_verify::rom_address#1 -- vdum1=vduz2 
    lda.z rom_address
    sta printf_ulong.uvalue
    lda.z rom_address+1
    sta printf_ulong.uvalue+1
    lda.z rom_address+2
    sta printf_ulong.uvalue+2
    lda.z rom_address+3
    sta printf_ulong.uvalue+3
    // [1580] call printf_ulong
    // [1588] phi from rom_verify::@22 to printf_ulong [phi:rom_verify::@22->printf_ulong]
    // [1588] phi printf_ulong::format_zero_padding#14 = 1 [phi:rom_verify::@22->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1588] phi printf_ulong::format_min_length#14 = 5 [phi:rom_verify::@22->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1588] phi printf_ulong::format_radix#14 = HEXADECIMAL [phi:rom_verify::@22->printf_ulong#2] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [1588] phi printf_ulong::uvalue#14 = printf_ulong::uvalue#7 [phi:rom_verify::@22->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // rom_verify::@23
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1581] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1582] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1584] call display_action_text
    // [1200] phi from rom_verify::@23 to display_action_text [phi:rom_verify::@23->display_action_text]
    // [1200] phi display_action_text::info_text#25 = info_text [phi:rom_verify::@23->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1535] phi from rom_verify::@23 to rom_verify::@1 [phi:rom_verify::@23->rom_verify::@1]
    // [1535] phi rom_verify::y#3 = rom_verify::y#11 [phi:rom_verify::@23->rom_verify::@1#0] -- register_copy 
    // [1535] phi rom_verify::progress_row_current#3 = rom_verify::progress_row_current#11 [phi:rom_verify::@23->rom_verify::@1#1] -- register_copy 
    // [1535] phi rom_verify::rom_different_bytes#11 = rom_verify::rom_different_bytes#1 [phi:rom_verify::@23->rom_verify::@1#2] -- register_copy 
    // [1535] phi rom_verify::rom_bram_ptr#10 = rom_verify::rom_bram_ptr#11 [phi:rom_verify::@23->rom_verify::@1#3] -- register_copy 
    // [1535] phi rom_verify::rom_bram_bank#11 = rom_verify::rom_bram_bank#10 [phi:rom_verify::@23->rom_verify::@1#4] -- register_copy 
    // [1535] phi rom_verify::rom_address#12 = rom_verify::rom_address#1 [phi:rom_verify::@23->rom_verify::@1#5] -- register_copy 
    jmp __b1
    // rom_verify::@4
  __b4:
    // cputc('*')
    // [1585] stackpush(char) = '*' -- _stackpushbyte_=vbuc1 
    lda #'*'
    pha
    // [1586] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b5
  .segment Data
    s: .text "Comparing: "
    .byte 0
    s1: .text " differences between RAM:"
    .byte 0
    s3: .text " <-> ROM:"
    .byte 0
    .label rom_boundary = file_size
    // We start for ROM from 0x0:0x7800 !!!!
    .label rom_bram_bank = main.main__59
    .label rom_chip = w25q16_erase.vera_current_64k_block
    file_size: .dword 0
}
.segment Code
  // printf_ulong
// Print an unsigned int using a specific format
// void printf_ulong(void (*putc)(char), __mem() unsigned long uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, __register(X) char format_radix)
printf_ulong: {
    // printf_ulong::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1589] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // ultoa(uvalue, printf_buffer.digits, format.radix)
    // [1590] ultoa::value#1 = printf_ulong::uvalue#14
    // [1591] ultoa::radix#0 = printf_ulong::format_radix#14
    // [1592] call ultoa
    // Format number into buffer
    jsr ultoa
    // printf_ulong::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1593] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [1594] printf_number_buffer::format_min_length#0 = printf_ulong::format_min_length#14 -- vbuxx=vbum1 
    ldx format_min_length
    // [1595] printf_number_buffer::format_zero_padding#0 = printf_ulong::format_zero_padding#14
    // [1596] call printf_number_buffer
  // Print using format
    // [2362] phi from printf_ulong::@2 to printf_number_buffer [phi:printf_ulong::@2->printf_number_buffer]
    // [2362] phi printf_number_buffer::putc#10 = &snputc [phi:printf_ulong::@2->printf_number_buffer#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_number_buffer.putc
    lda #>snputc
    sta.z printf_number_buffer.putc+1
    // [2362] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_ulong::@2->printf_number_buffer#1] -- register_copy 
    // [2362] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#0 [phi:printf_ulong::@2->printf_number_buffer#2] -- register_copy 
    // [2362] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#0 [phi:printf_ulong::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_ulong::@return
    // }
    // [1597] return 
    rts
  .segment Data
    uvalue: .dword 0
    .label format_min_length = printf_uchar.format_min_length
    .label format_zero_padding = printf_uchar.format_zero_padding
}
.segment Code
  // rom_flash
// __zp($e0) unsigned long rom_flash(__mem() char rom_chip, __mem() char rom_bank_start, __zp($f6) unsigned long file_size)
rom_flash: {
    .label equal_bytes = $46
    .label ram_address_sector = $ec
    .label equal_bytes_1 = $d0
    .label retries = $f3
    .label flash_errors_sector = $6b
    .label ram_address = $5b
    .label rom_address = $c5
    .label flash_bytes_sector = $be
    .label x = $b9
    .label flash_errors = $e0
    // We start for ROM from 0x0:0x7800 !!!!
    .label bram_bank_sector = $f5
    .label y_sector = $fa
    .label file_size = $f6
    .label return = $e0
    // rom_flash::bank_set_bram1
    // BRAM = bank
    // [1599] BRAM = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z BRAM
    // [1600] phi from rom_flash::bank_set_bram1 to rom_flash::@19 [phi:rom_flash::bank_set_bram1->rom_flash::@19]
    // rom_flash::@19
    // display_action_progress(TEXT_PROGRESS_FLASHING)
    // [1601] call display_action_progress
  // Now we compare the RAM with the actual ROM contents.
    // [1155] phi from rom_flash::@19 to display_action_progress [phi:rom_flash::@19->display_action_progress]
    // [1155] phi display_action_progress::info_text#30 = TEXT_PROGRESS_FLASHING [phi:rom_flash::@19->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<TEXT_PROGRESS_FLASHING
    sta.z display_action_progress.info_text
    lda #>TEXT_PROGRESS_FLASHING
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // rom_flash::@20
    // unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start)
    // [1602] rom_address_from_bank::rom_bank#2 = rom_flash::rom_bank_start#0 -- vbuaa=vbum1 
    lda rom_bank_start
    // [1603] call rom_address_from_bank
    // [2569] phi from rom_flash::@20 to rom_address_from_bank [phi:rom_flash::@20->rom_address_from_bank]
    // [2569] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#2 [phi:rom_flash::@20->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start)
    // [1604] rom_address_from_bank::return#4 = rom_address_from_bank::return#0 -- vdum1=vdum2 
    lda rom_address_from_bank.return
    sta rom_address_from_bank.return_2
    lda rom_address_from_bank.return+1
    sta rom_address_from_bank.return_2+1
    lda rom_address_from_bank.return+2
    sta rom_address_from_bank.return_2+2
    lda rom_address_from_bank.return+3
    sta rom_address_from_bank.return_2+3
    // rom_flash::@21
    // [1605] rom_flash::rom_address_sector#0 = rom_address_from_bank::return#4
    // unsigned long rom_boundary = rom_address_sector + file_size
    // [1606] rom_flash::rom_boundary#0 = rom_flash::rom_address_sector#0 + rom_flash::file_size#0 -- vdum1=vdum2_plus_vduz3 
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
    // [1607] phi from rom_flash::@21 to rom_flash::@1 [phi:rom_flash::@21->rom_flash::@1]
    // [1607] phi rom_flash::flash_bytes#14 = 0 [phi:rom_flash::@21->rom_flash::@1#0] -- vdum1=vduc1 
    lda #<0
    sta flash_bytes
    sta flash_bytes+1
    lda #<0>>$10
    sta flash_bytes+2
    lda #>0>>$10
    sta flash_bytes+3
    // [1607] phi rom_flash::flash_errors#2 = 0 [phi:rom_flash::@21->rom_flash::@1#1] -- vduz1=vduc1 
    lda #<0
    sta.z flash_errors
    sta.z flash_errors+1
    lda #<0>>$10
    sta.z flash_errors+2
    lda #>0>>$10
    sta.z flash_errors+3
    // [1607] phi rom_flash::y_sector#13 = PROGRESS_Y [phi:rom_flash::@21->rom_flash::@1#2] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y_sector
    // [1607] phi rom_flash::x_sector#10 = PROGRESS_X [phi:rom_flash::@21->rom_flash::@1#3] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [1607] phi rom_flash::ram_address_sector#11 = (char *)$7800 [phi:rom_flash::@21->rom_flash::@1#4] -- pbuz1=pbuc1 
    lda #<$7800
    sta.z ram_address_sector
    lda #>$7800
    sta.z ram_address_sector+1
    // [1607] phi rom_flash::bram_bank_sector#14 = 0 [phi:rom_flash::@21->rom_flash::@1#5] -- vbuz1=vbuc1 
    lda #0
    sta.z bram_bank_sector
    // [1607] phi rom_flash::rom_address_sector#12 = rom_flash::rom_address_sector#0 [phi:rom_flash::@21->rom_flash::@1#6] -- register_copy 
    // rom_flash::@1
  __b1:
    // while (rom_address_sector < rom_boundary)
    // [1608] if(rom_flash::rom_address_sector#12<rom_flash::rom_boundary#0) goto rom_flash::@2 -- vdum1_lt_vdum2_then_la1 
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
    // rom_flash::@3
    // display_action_text_flashed(rom_address_sector, "ROM")
    // [1609] display_action_text_flashed::bytes#1 = rom_flash::rom_address_sector#12 -- vdum1=vdum2 
    lda rom_address_sector
    sta display_action_text_flashed.bytes
    lda rom_address_sector+1
    sta display_action_text_flashed.bytes+1
    lda rom_address_sector+2
    sta display_action_text_flashed.bytes+2
    lda rom_address_sector+3
    sta display_action_text_flashed.bytes+3
    // [1610] call display_action_text_flashed
    // [2824] phi from rom_flash::@3 to display_action_text_flashed [phi:rom_flash::@3->display_action_text_flashed]
    // [2824] phi display_action_text_flashed::chip#3 = chip [phi:rom_flash::@3->display_action_text_flashed#0] -- pbuz1=pbuc1 
    lda #<chip
    sta.z display_action_text_flashed.chip
    lda #>chip
    sta.z display_action_text_flashed.chip+1
    // [2824] phi display_action_text_flashed::bytes#3 = display_action_text_flashed::bytes#1 [phi:rom_flash::@3->display_action_text_flashed#1] -- register_copy 
    jsr display_action_text_flashed
    // [1611] phi from rom_flash::@3 to rom_flash::@23 [phi:rom_flash::@3->rom_flash::@23]
    // rom_flash::@23
    // wait_moment(16)
    // [1612] call wait_moment
    // [1134] phi from rom_flash::@23 to wait_moment [phi:rom_flash::@23->wait_moment]
    // [1134] phi wait_moment::w#17 = $10 [phi:rom_flash::@23->wait_moment#0] -- vbuz1=vbuc1 
    lda #$10
    sta.z wait_moment.w
    jsr wait_moment
    // rom_flash::@return
    // }
    // [1613] return 
    rts
    // rom_flash::@2
  __b2:
    // unsigned int equal_bytes = rom_compare(bram_bank_sector, (bram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR)
    // [1614] rom_compare::bank_ram#1 = rom_flash::bram_bank_sector#14 -- vbuxx=vbuz1 
    ldx.z bram_bank_sector
    // [1615] rom_compare::ptr_ram#2 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z rom_compare.ptr_ram
    lda.z ram_address_sector+1
    sta.z rom_compare.ptr_ram+1
    // [1616] rom_compare::rom_compare_address#1 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_compare.rom_compare_address
    lda rom_address_sector+1
    sta.z rom_compare.rom_compare_address+1
    lda rom_address_sector+2
    sta.z rom_compare.rom_compare_address+2
    lda rom_address_sector+3
    sta.z rom_compare.rom_compare_address+3
    // [1617] call rom_compare
  // {asm{.byte $db}}
    // [2768] phi from rom_flash::@2 to rom_compare [phi:rom_flash::@2->rom_compare]
    // [2768] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#2 [phi:rom_flash::@2->rom_compare#0] -- register_copy 
    // [2768] phi rom_compare::rom_compare_size#11 = $1000 [phi:rom_flash::@2->rom_compare#1] -- vwuz1=vwuc1 
    lda #<$1000
    sta.z rom_compare.rom_compare_size
    lda #>$1000
    sta.z rom_compare.rom_compare_size+1
    // [2768] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#1 [phi:rom_flash::@2->rom_compare#2] -- register_copy 
    // [2768] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#1 [phi:rom_flash::@2->rom_compare#3] -- register_copy 
    jsr rom_compare
    // unsigned int equal_bytes = rom_compare(bram_bank_sector, (bram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR)
    // [1618] rom_compare::return#3 = rom_compare::equal_bytes#2
    // rom_flash::@22
    // [1619] rom_flash::equal_bytes#0 = rom_compare::return#3
    // if (equal_bytes != ROM_SECTOR)
    // [1620] if(rom_flash::equal_bytes#0!=$1000) goto rom_flash::@5 -- vwuz1_neq_vwuc1_then_la1 
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
    // [1621] cputsxy::x#3 = rom_flash::x_sector#10 -- vbuyy=vbum1 
    ldy x_sector
    // [1622] cputsxy::y#3 = rom_flash::y_sector#13 -- vbuxx=vbuz1 
    ldx.z y_sector
    // [1623] call cputsxy
    // [2146] phi from rom_flash::@16 to cputsxy [phi:rom_flash::@16->cputsxy]
    // [2146] phi cputsxy::s#4 = rom_flash::s [phi:rom_flash::@16->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [2146] phi cputsxy::y#4 = cputsxy::y#3 [phi:rom_flash::@16->cputsxy#1] -- register_copy 
    // [2146] phi cputsxy::x#4 = cputsxy::x#3 [phi:rom_flash::@16->cputsxy#2] -- register_copy 
    jsr cputsxy
    // [1624] phi from rom_flash::@12 rom_flash::@16 to rom_flash::@4 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4]
    // [1624] phi rom_flash::flash_errors#11 = rom_flash::flash_errors#1 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4#0] -- register_copy 
    // [1624] phi rom_flash::flash_bytes#12 = rom_flash::flash_bytes#1 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4#1] -- register_copy 
    // rom_flash::@4
  __b4:
    // ram_address_sector += ROM_SECTOR
    // [1625] rom_flash::ram_address_sector#1 = rom_flash::ram_address_sector#11 + $1000 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address_sector
    clc
    adc #<$1000
    sta.z ram_address_sector
    lda.z ram_address_sector+1
    adc #>$1000
    sta.z ram_address_sector+1
    // rom_address_sector += ROM_SECTOR
    // [1626] rom_flash::rom_address_sector#1 = rom_flash::rom_address_sector#12 + $1000 -- vdum1=vdum1_plus_vwuc1 
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
    // [1627] if(rom_flash::ram_address_sector#1!=$c000) goto rom_flash::@13 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address_sector+1
    cmp #>$c000
    bne __b13
    lda.z ram_address_sector
    cmp #<$c000
    bne __b13
    // rom_flash::@17
    // bram_bank_sector++;
    // [1628] rom_flash::bram_bank_sector#1 = ++ rom_flash::bram_bank_sector#14 -- vbuz1=_inc_vbuz1 
    inc.z bram_bank_sector
    // [1629] phi from rom_flash::@17 to rom_flash::@13 [phi:rom_flash::@17->rom_flash::@13]
    // [1629] phi rom_flash::bram_bank_sector#35 = rom_flash::bram_bank_sector#1 [phi:rom_flash::@17->rom_flash::@13#0] -- register_copy 
    // [1629] phi rom_flash::ram_address_sector#8 = (char *)$a000 [phi:rom_flash::@17->rom_flash::@13#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address_sector
    lda #>$a000
    sta.z ram_address_sector+1
    // [1629] phi from rom_flash::@4 to rom_flash::@13 [phi:rom_flash::@4->rom_flash::@13]
    // [1629] phi rom_flash::bram_bank_sector#35 = rom_flash::bram_bank_sector#14 [phi:rom_flash::@4->rom_flash::@13#0] -- register_copy 
    // [1629] phi rom_flash::ram_address_sector#8 = rom_flash::ram_address_sector#1 [phi:rom_flash::@4->rom_flash::@13#1] -- register_copy 
    // rom_flash::@13
  __b13:
    // if (ram_address_sector == RAM_HIGH)
    // [1630] if(rom_flash::ram_address_sector#8!=$9800) goto rom_flash::@34 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address_sector+1
    cmp #>$9800
    bne __b14
    lda.z ram_address_sector
    cmp #<$9800
    bne __b14
    // [1632] phi from rom_flash::@13 to rom_flash::@14 [phi:rom_flash::@13->rom_flash::@14]
    // [1632] phi rom_flash::ram_address_sector#15 = (char *)$a000 [phi:rom_flash::@13->rom_flash::@14#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address_sector
    lda #>$a000
    sta.z ram_address_sector+1
    // [1632] phi rom_flash::bram_bank_sector#12 = 1 [phi:rom_flash::@13->rom_flash::@14#1] -- vbuz1=vbuc1 
    lda #1
    sta.z bram_bank_sector
    // [1631] phi from rom_flash::@13 to rom_flash::@34 [phi:rom_flash::@13->rom_flash::@34]
    // rom_flash::@34
    // [1632] phi from rom_flash::@34 to rom_flash::@14 [phi:rom_flash::@34->rom_flash::@14]
    // [1632] phi rom_flash::ram_address_sector#15 = rom_flash::ram_address_sector#8 [phi:rom_flash::@34->rom_flash::@14#0] -- register_copy 
    // [1632] phi rom_flash::bram_bank_sector#12 = rom_flash::bram_bank_sector#35 [phi:rom_flash::@34->rom_flash::@14#1] -- register_copy 
    // rom_flash::@14
  __b14:
    // x_sector += 8
    // [1633] rom_flash::x_sector#1 = rom_flash::x_sector#10 + 8 -- vbum1=vbum1_plus_vbuc1 
    lda #8
    clc
    adc x_sector
    sta x_sector
    // rom_address_sector % ROM_PROGRESS_ROW
    // [1634] rom_flash::$28 = rom_flash::rom_address_sector#1 & ROM_PROGRESS_ROW-1 -- vdum1=vdum2_band_vduc1 
    lda rom_address_sector
    and #<ROM_PROGRESS_ROW-1
    sta rom_flash__28
    lda rom_address_sector+1
    and #>ROM_PROGRESS_ROW-1
    sta rom_flash__28+1
    lda rom_address_sector+2
    and #<ROM_PROGRESS_ROW-1>>$10
    sta rom_flash__28+2
    lda rom_address_sector+3
    and #>ROM_PROGRESS_ROW-1>>$10
    sta rom_flash__28+3
    // if (!(rom_address_sector % ROM_PROGRESS_ROW))
    // [1635] if(0!=rom_flash::$28) goto rom_flash::@15 -- 0_neq_vdum1_then_la1 
    lda rom_flash__28
    ora rom_flash__28+1
    ora rom_flash__28+2
    ora rom_flash__28+3
    bne __b15
    // rom_flash::@18
    // y_sector++;
    // [1636] rom_flash::y_sector#1 = ++ rom_flash::y_sector#13 -- vbuz1=_inc_vbuz1 
    inc.z y_sector
    // [1637] phi from rom_flash::@18 to rom_flash::@15 [phi:rom_flash::@18->rom_flash::@15]
    // [1637] phi rom_flash::y_sector#18 = rom_flash::y_sector#1 [phi:rom_flash::@18->rom_flash::@15#0] -- register_copy 
    // [1637] phi rom_flash::x_sector#20 = PROGRESS_X [phi:rom_flash::@18->rom_flash::@15#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [1637] phi from rom_flash::@14 to rom_flash::@15 [phi:rom_flash::@14->rom_flash::@15]
    // [1637] phi rom_flash::y_sector#18 = rom_flash::y_sector#13 [phi:rom_flash::@14->rom_flash::@15#0] -- register_copy 
    // [1637] phi rom_flash::x_sector#20 = rom_flash::x_sector#1 [phi:rom_flash::@14->rom_flash::@15#1] -- register_copy 
    // rom_flash::@15
  __b15:
    // get_info_text_flashing(flash_bytes)
    // [1638] get_info_text_flashing::flash_bytes#1 = rom_flash::flash_bytes#12 -- vduz1=vdum2 
    lda flash_bytes
    sta.z get_info_text_flashing.flash_bytes
    lda flash_bytes+1
    sta.z get_info_text_flashing.flash_bytes+1
    lda flash_bytes+2
    sta.z get_info_text_flashing.flash_bytes+2
    lda flash_bytes+3
    sta.z get_info_text_flashing.flash_bytes+3
    // [1639] call get_info_text_flashing
    // [2841] phi from rom_flash::@15 to get_info_text_flashing [phi:rom_flash::@15->get_info_text_flashing]
    // [2841] phi get_info_text_flashing::flash_bytes#3 = get_info_text_flashing::flash_bytes#1 [phi:rom_flash::@15->get_info_text_flashing#0] -- register_copy 
    jsr get_info_text_flashing
    // rom_flash::@32
    // display_info_rom(rom_chip, STATUS_FLASHING, get_info_text_flashing(flash_bytes))
    // [1640] display_info_rom::rom_chip#3 = rom_flash::rom_chip#0 -- vbum1=vbum2 
    lda rom_chip
    sta display_info_rom.rom_chip
    // [1641] call display_info_rom
    // [1368] phi from rom_flash::@32 to display_info_rom [phi:rom_flash::@32->display_info_rom]
    // [1368] phi display_info_rom::info_text#16 = info_text [phi:rom_flash::@32->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_rom.info_text
    lda #>info_text
    sta.z display_info_rom.info_text+1
    // [1368] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#3 [phi:rom_flash::@32->display_info_rom#1] -- register_copy 
    // [1368] phi display_info_rom::info_status#16 = STATUS_FLASHING [phi:rom_flash::@32->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHING
    sta display_info_rom.info_status
    jsr display_info_rom
    // [1607] phi from rom_flash::@32 to rom_flash::@1 [phi:rom_flash::@32->rom_flash::@1]
    // [1607] phi rom_flash::flash_bytes#14 = rom_flash::flash_bytes#12 [phi:rom_flash::@32->rom_flash::@1#0] -- register_copy 
    // [1607] phi rom_flash::flash_errors#2 = rom_flash::flash_errors#11 [phi:rom_flash::@32->rom_flash::@1#1] -- register_copy 
    // [1607] phi rom_flash::y_sector#13 = rom_flash::y_sector#18 [phi:rom_flash::@32->rom_flash::@1#2] -- register_copy 
    // [1607] phi rom_flash::x_sector#10 = rom_flash::x_sector#20 [phi:rom_flash::@32->rom_flash::@1#3] -- register_copy 
    // [1607] phi rom_flash::ram_address_sector#11 = rom_flash::ram_address_sector#15 [phi:rom_flash::@32->rom_flash::@1#4] -- register_copy 
    // [1607] phi rom_flash::bram_bank_sector#14 = rom_flash::bram_bank_sector#12 [phi:rom_flash::@32->rom_flash::@1#5] -- register_copy 
    // [1607] phi rom_flash::rom_address_sector#12 = rom_flash::rom_address_sector#1 [phi:rom_flash::@32->rom_flash::@1#6] -- register_copy 
    jmp __b1
    // [1642] phi from rom_flash::@22 to rom_flash::@5 [phi:rom_flash::@22->rom_flash::@5]
  __b3:
    // [1642] phi rom_flash::flash_bytes_sector#10 = 0 [phi:rom_flash::@22->rom_flash::@5#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z flash_bytes_sector
    sta.z flash_bytes_sector+1
    // [1642] phi rom_flash::flash_errors_sector#10 = 0 [phi:rom_flash::@22->rom_flash::@5#1] -- vwuz1=vwuc1 
    sta.z flash_errors_sector
    sta.z flash_errors_sector+1
    // [1642] phi rom_flash::retries#12 = 0 [phi:rom_flash::@22->rom_flash::@5#2] -- vbuz1=vbuc1 
    sta.z retries
    // [1642] phi from rom_flash::@33 to rom_flash::@5 [phi:rom_flash::@33->rom_flash::@5]
    // [1642] phi rom_flash::flash_bytes_sector#10 = rom_flash::flash_bytes_sector#11 [phi:rom_flash::@33->rom_flash::@5#0] -- register_copy 
    // [1642] phi rom_flash::flash_errors_sector#10 = rom_flash::flash_errors_sector#11 [phi:rom_flash::@33->rom_flash::@5#1] -- register_copy 
    // [1642] phi rom_flash::retries#12 = rom_flash::retries#1 [phi:rom_flash::@33->rom_flash::@5#2] -- register_copy 
    // rom_flash::@5
  __b5:
    // rom_sector_erase(rom_address_sector)
    // [1643] rom_sector_erase::address#0 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_sector_erase.address
    lda rom_address_sector+1
    sta.z rom_sector_erase.address+1
    lda rom_address_sector+2
    sta.z rom_sector_erase.address+2
    lda rom_address_sector+3
    sta.z rom_sector_erase.address+3
    // [1644] call rom_sector_erase
    // [2851] phi from rom_flash::@5 to rom_sector_erase [phi:rom_flash::@5->rom_sector_erase]
    jsr rom_sector_erase
    // rom_flash::@24
    // unsigned long rom_sector_boundary = rom_address_sector + ROM_SECTOR
    // [1645] rom_flash::rom_sector_boundary#0 = rom_flash::rom_address_sector#12 + $1000 -- vdum1=vdum2_plus_vwuc1 
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
    // [1646] gotoxy::x#31 = rom_flash::x_sector#10 -- vbuyy=vbum1 
    ldy x_sector
    // [1647] gotoxy::y#31 = rom_flash::y_sector#13 -- vbum1=vbuz2 
    lda.z y_sector
    sta gotoxy.y
    // [1648] call gotoxy
    // [805] phi from rom_flash::@24 to gotoxy [phi:rom_flash::@24->gotoxy]
    // [805] phi gotoxy::y#37 = gotoxy::y#31 [phi:rom_flash::@24->gotoxy#0] -- register_copy 
    // [805] phi gotoxy::x#37 = gotoxy::x#31 [phi:rom_flash::@24->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1649] phi from rom_flash::@24 to rom_flash::@25 [phi:rom_flash::@24->rom_flash::@25]
    // rom_flash::@25
    // printf("........")
    // [1650] call printf_str
    // [1125] phi from rom_flash::@25 to printf_str [phi:rom_flash::@25->printf_str]
    // [1125] phi printf_str::putc#79 = &cputc [phi:rom_flash::@25->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = rom_flash::s1 [phi:rom_flash::@25->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@26
    // [1651] rom_flash::rom_address#16 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_address
    lda rom_address_sector+1
    sta.z rom_address+1
    lda rom_address_sector+2
    sta.z rom_address+2
    lda rom_address_sector+3
    sta.z rom_address+3
    // [1652] rom_flash::ram_address#16 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z ram_address
    lda.z ram_address_sector+1
    sta.z ram_address+1
    // [1653] rom_flash::x#16 = rom_flash::x_sector#10 -- vbuz1=vbum2 
    lda x_sector
    sta.z x
    // [1654] phi from rom_flash::@10 rom_flash::@26 to rom_flash::@6 [phi:rom_flash::@10/rom_flash::@26->rom_flash::@6]
    // [1654] phi rom_flash::x#10 = rom_flash::x#1 [phi:rom_flash::@10/rom_flash::@26->rom_flash::@6#0] -- register_copy 
    // [1654] phi rom_flash::flash_bytes_sector#11 = rom_flash::flash_bytes_sector#1 [phi:rom_flash::@10/rom_flash::@26->rom_flash::@6#1] -- register_copy 
    // [1654] phi rom_flash::ram_address#10 = rom_flash::ram_address#1 [phi:rom_flash::@10/rom_flash::@26->rom_flash::@6#2] -- register_copy 
    // [1654] phi rom_flash::flash_errors_sector#11 = rom_flash::flash_errors_sector#7 [phi:rom_flash::@10/rom_flash::@26->rom_flash::@6#3] -- register_copy 
    // [1654] phi rom_flash::rom_address#11 = rom_flash::rom_address#1 [phi:rom_flash::@10/rom_flash::@26->rom_flash::@6#4] -- register_copy 
    // rom_flash::@6
  __b6:
    // while (rom_address < rom_sector_boundary)
    // [1655] if(rom_flash::rom_address#11<rom_flash::rom_sector_boundary#0) goto rom_flash::@7 -- vduz1_lt_vdum2_then_la1 
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
    // [1656] rom_flash::retries#1 = ++ rom_flash::retries#12 -- vbuz1=_inc_vbuz1 
    inc.z retries
    // while (flash_errors_sector && retries <= 3)
    // [1657] if(0==rom_flash::flash_errors_sector#11) goto rom_flash::@12 -- 0_eq_vwuz1_then_la1 
    lda.z flash_errors_sector
    ora.z flash_errors_sector+1
    beq __b12
    // rom_flash::@33
    // [1658] if(rom_flash::retries#1<3+1) goto rom_flash::@5 -- vbuz1_lt_vbuc1_then_la1 
    lda.z retries
    cmp #3+1
    bcs !__b5+
    jmp __b5
  !__b5:
    // rom_flash::@12
  __b12:
    // flash_errors += flash_errors_sector
    // [1659] rom_flash::flash_errors#1 = rom_flash::flash_errors#2 + rom_flash::flash_errors_sector#11 -- vduz1=vduz1_plus_vwuz2 
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
    // flash_bytes += flash_bytes_sector
    // [1660] rom_flash::flash_bytes#1 = rom_flash::flash_bytes#14 + rom_flash::flash_bytes_sector#11 -- vdum1=vdum1_plus_vwuz2 
    lda flash_bytes
    clc
    adc.z flash_bytes_sector
    sta flash_bytes
    lda flash_bytes+1
    adc.z flash_bytes_sector+1
    sta flash_bytes+1
    lda flash_bytes+2
    adc #0
    sta flash_bytes+2
    lda flash_bytes+3
    adc #0
    sta flash_bytes+3
    jmp __b4
    // rom_flash::@7
  __b7:
    // display_action_text_flashing( ROM_SECTOR, "ROM", bram_bank_sector, ram_address_sector, rom_address_sector)
    // [1661] display_action_text_flashing::bram_bank#1 = rom_flash::bram_bank_sector#14 -- vbuz1=vbuz2 
    lda.z bram_bank_sector
    sta.z display_action_text_flashing.bram_bank
    // [1662] display_action_text_flashing::bram_ptr#1 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z display_action_text_flashing.bram_ptr
    lda.z ram_address_sector+1
    sta.z display_action_text_flashing.bram_ptr+1
    // [1663] display_action_text_flashing::address#1 = rom_flash::rom_address_sector#12 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z display_action_text_flashing.address
    lda rom_address_sector+1
    sta.z display_action_text_flashing.address+1
    lda rom_address_sector+2
    sta.z display_action_text_flashing.address+2
    lda rom_address_sector+3
    sta.z display_action_text_flashing.address+3
    // [1664] call display_action_text_flashing
    // [2863] phi from rom_flash::@7 to display_action_text_flashing [phi:rom_flash::@7->display_action_text_flashing]
    // [2863] phi display_action_text_flashing::address#10 = display_action_text_flashing::address#1 [phi:rom_flash::@7->display_action_text_flashing#0] -- register_copy 
    // [2863] phi display_action_text_flashing::chip#10 = chip [phi:rom_flash::@7->display_action_text_flashing#1] -- pbuz1=pbuc1 
    lda #<chip
    sta.z display_action_text_flashing.chip
    lda #>chip
    sta.z display_action_text_flashing.chip+1
    // [2863] phi display_action_text_flashing::bram_ptr#3 = display_action_text_flashing::bram_ptr#1 [phi:rom_flash::@7->display_action_text_flashing#2] -- register_copy 
    // [2863] phi display_action_text_flashing::bram_bank#3 = display_action_text_flashing::bram_bank#1 [phi:rom_flash::@7->display_action_text_flashing#3] -- register_copy 
    // [2863] phi display_action_text_flashing::bytes#3 = $1000 [phi:rom_flash::@7->display_action_text_flashing#4] -- vduz1=vduc1 
    lda #<$1000
    sta.z display_action_text_flashing.bytes
    lda #>$1000
    sta.z display_action_text_flashing.bytes+1
    lda #<$1000>>$10
    sta.z display_action_text_flashing.bytes+2
    lda #>$1000>>$10
    sta.z display_action_text_flashing.bytes+3
    jsr display_action_text_flashing
    // rom_flash::@27
    // unsigned long written_bytes = rom_write(bram_bank, (bram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1665] rom_write::flash_ram_bank#0 = rom_flash::bram_bank_sector#14 -- vbuxx=vbuz1 
    ldx.z bram_bank_sector
    // [1666] rom_write::flash_ram_address#1 = rom_flash::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_write.flash_ram_address
    lda.z ram_address+1
    sta.z rom_write.flash_ram_address+1
    // [1667] rom_write::flash_rom_address#1 = rom_flash::rom_address#11 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_write.flash_rom_address
    lda.z rom_address+1
    sta.z rom_write.flash_rom_address+1
    lda.z rom_address+2
    sta.z rom_write.flash_rom_address+2
    lda.z rom_address+3
    sta.z rom_write.flash_rom_address+3
    // [1668] call rom_write
    jsr rom_write
    // rom_flash::@28
    // rom_compare(bram_bank, (bram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1669] rom_compare::bank_ram#2 = rom_flash::bram_bank_sector#14 -- vbuxx=vbuz1 
    ldx.z bram_bank_sector
    // [1670] rom_compare::ptr_ram#3 = rom_flash::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_compare.ptr_ram
    lda.z ram_address+1
    sta.z rom_compare.ptr_ram+1
    // [1671] rom_compare::rom_compare_address#2 = rom_flash::rom_address#11 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_compare.rom_compare_address
    lda.z rom_address+1
    sta.z rom_compare.rom_compare_address+1
    lda.z rom_address+2
    sta.z rom_compare.rom_compare_address+2
    lda.z rom_address+3
    sta.z rom_compare.rom_compare_address+3
    // [1672] call rom_compare
    // [2768] phi from rom_flash::@28 to rom_compare [phi:rom_flash::@28->rom_compare]
    // [2768] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#3 [phi:rom_flash::@28->rom_compare#0] -- register_copy 
    // [2768] phi rom_compare::rom_compare_size#11 = ROM_PROGRESS_CELL [phi:rom_flash::@28->rom_compare#1] -- vwuz1=vwuc1 
    lda #<ROM_PROGRESS_CELL
    sta.z rom_compare.rom_compare_size
    lda #>ROM_PROGRESS_CELL
    sta.z rom_compare.rom_compare_size+1
    // [2768] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#2 [phi:rom_flash::@28->rom_compare#2] -- register_copy 
    // [2768] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#2 [phi:rom_flash::@28->rom_compare#3] -- register_copy 
    jsr rom_compare
    // rom_compare(bram_bank, (bram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1673] rom_compare::return#4 = rom_compare::equal_bytes#2
    // rom_flash::@29
    // equal_bytes = rom_compare(bram_bank, (bram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1674] rom_flash::equal_bytes#1 = rom_compare::return#4 -- vwuz1=vwuz2 
    lda.z rom_compare.return
    sta.z equal_bytes_1
    lda.z rom_compare.return+1
    sta.z equal_bytes_1+1
    // gotoxy(x, y)
    // [1675] gotoxy::x#32 = rom_flash::x#10 -- vbuyy=vbuz1 
    ldy.z x
    // [1676] gotoxy::y#32 = rom_flash::y_sector#13 -- vbum1=vbuz2 
    lda.z y_sector
    sta gotoxy.y
    // [1677] call gotoxy
    // [805] phi from rom_flash::@29 to gotoxy [phi:rom_flash::@29->gotoxy]
    // [805] phi gotoxy::y#37 = gotoxy::y#32 [phi:rom_flash::@29->gotoxy#0] -- register_copy 
    // [805] phi gotoxy::x#37 = gotoxy::x#32 [phi:rom_flash::@29->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_flash::@30
    // if (equal_bytes != ROM_PROGRESS_CELL)
    // [1678] if(rom_flash::equal_bytes#1!=ROM_PROGRESS_CELL) goto rom_flash::@9 -- vwuz1_neq_vwuc1_then_la1 
    lda.z equal_bytes_1+1
    cmp #>ROM_PROGRESS_CELL
    bne __b9
    lda.z equal_bytes_1
    cmp #<ROM_PROGRESS_CELL
    bne __b9
    // rom_flash::@11
    // cputcxy(x,y,'+')
    // [1679] cputcxy::x#14 = rom_flash::x#10 -- vbuyy=vbuz1 
    ldy.z x
    // [1680] cputcxy::y#14 = rom_flash::y_sector#13 -- vbuaa=vbuz1 
    lda.z y_sector
    // [1681] call cputcxy
    // [2273] phi from rom_flash::@11 to cputcxy [phi:rom_flash::@11->cputcxy]
    // [2273] phi cputcxy::c#17 = '+' [phi:rom_flash::@11->cputcxy#0] -- vbuxx=vbuc1 
    ldx #'+'
    // [2273] phi cputcxy::y#17 = cputcxy::y#14 [phi:rom_flash::@11->cputcxy#1] -- register_copy 
    // [2273] phi cputcxy::x#17 = cputcxy::x#14 [phi:rom_flash::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [1682] phi from rom_flash::@11 rom_flash::@31 to rom_flash::@10 [phi:rom_flash::@11/rom_flash::@31->rom_flash::@10]
    // [1682] phi rom_flash::flash_errors_sector#7 = rom_flash::flash_errors_sector#11 [phi:rom_flash::@11/rom_flash::@31->rom_flash::@10#0] -- register_copy 
    // rom_flash::@10
  __b10:
    // ram_address += ROM_PROGRESS_CELL
    // [1683] rom_flash::ram_address#1 = rom_flash::ram_address#10 + ROM_PROGRESS_CELL -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address
    clc
    adc #<ROM_PROGRESS_CELL
    sta.z ram_address
    lda.z ram_address+1
    adc #>ROM_PROGRESS_CELL
    sta.z ram_address+1
    // rom_address += ROM_PROGRESS_CELL
    // [1684] rom_flash::rom_address#1 = rom_flash::rom_address#11 + ROM_PROGRESS_CELL -- vduz1=vduz1_plus_vwuc1 
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
    // flash_bytes_sector += ROM_PROGRESS_CELL
    // [1685] rom_flash::flash_bytes_sector#1 = rom_flash::flash_bytes_sector#11 + ROM_PROGRESS_CELL -- vwuz1=vwuz1_plus_vwuc1 
    lda.z flash_bytes_sector
    clc
    adc #<ROM_PROGRESS_CELL
    sta.z flash_bytes_sector
    lda.z flash_bytes_sector+1
    adc #>ROM_PROGRESS_CELL
    sta.z flash_bytes_sector+1
    // x++;
    // [1686] rom_flash::x#1 = ++ rom_flash::x#10 -- vbuz1=_inc_vbuz1 
    inc.z x
    jmp __b6
    // rom_flash::@9
  __b9:
    // cputcxy(x,y,'!')
    // [1687] cputcxy::x#13 = rom_flash::x#10 -- vbuyy=vbuz1 
    ldy.z x
    // [1688] cputcxy::y#13 = rom_flash::y_sector#13 -- vbuaa=vbuz1 
    lda.z y_sector
    // [1689] call cputcxy
    // [2273] phi from rom_flash::@9 to cputcxy [phi:rom_flash::@9->cputcxy]
    // [2273] phi cputcxy::c#17 = '!' [phi:rom_flash::@9->cputcxy#0] -- vbuxx=vbuc1 
    ldx #'!'
    // [2273] phi cputcxy::y#17 = cputcxy::y#13 [phi:rom_flash::@9->cputcxy#1] -- register_copy 
    // [2273] phi cputcxy::x#17 = cputcxy::x#13 [phi:rom_flash::@9->cputcxy#2] -- register_copy 
    jsr cputcxy
    // rom_flash::@31
    // flash_errors_sector++;
    // [1690] rom_flash::flash_errors_sector#1 = ++ rom_flash::flash_errors_sector#11 -- vwuz1=_inc_vwuz1 
    inc.z flash_errors_sector
    bne !+
    inc.z flash_errors_sector+1
  !:
    jmp __b10
  .segment Data
    s: .text "--------"
    .byte 0
    s1: .text "........"
    .byte 0
    rom_flash__28: .dword 0
    .label rom_address_sector = main.rom_file_modulo
    rom_boundary: .dword 0
    rom_sector_boundary: .dword 0
    .label flash_bytes = w25q16_verify.w25q16_verify__7
    .label x_sector = main.check_status_smc9_return
    rom_chip: .byte 0
    rom_bank_start: .byte 0
}
.segment Code
  // smc_read
/**
 * @brief Read the SMC.BIN file into RAM_BASE.
 * The maximum size of SMC.BIN data that should be in the file is 0x1E00.
 * 
 * @return unsigned int The amount of bytes read from SMC.BIN to be flashed.
 */
// __zp($51) unsigned int smc_read(__mem() char info_status)
smc_read: {
    .const smc_bram_bank = 1
    .label fp = $73
    .label return = $51
    .label smc_bram_ptr = $53
    .label smc_file_size = $51
    /// Holds the amount of bytes actually read in the memory to be flashed.
    .label progress_row_bytes = $23
    .label smc_file_read_1 = $30
    .label smc_action_text = $40
    // if(info_status == STATUS_READING)
    // [1692] if(smc_read::info_status#10==STATUS_READING) goto smc_read::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #STATUS_READING
    cmp info_status
    beq __b1
    // [1694] phi from smc_read to smc_read::@2 [phi:smc_read->smc_read::@2]
    // [1694] phi smc_read::smc_action_text#12 = smc_action_text#2 [phi:smc_read->smc_read::@2#0] -- pbuz1=pbuc1 
    lda #<smc_action_text_1
    sta.z smc_action_text
    lda #>smc_action_text_1
    sta.z smc_action_text+1
    jmp __b2
    // [1693] phi from smc_read to smc_read::@1 [phi:smc_read->smc_read::@1]
    // smc_read::@1
  __b1:
    // [1694] phi from smc_read::@1 to smc_read::@2 [phi:smc_read::@1->smc_read::@2]
    // [1694] phi smc_read::smc_action_text#12 = smc_action_text#1 [phi:smc_read::@1->smc_read::@2#0] -- pbuz1=pbuc1 
    lda #<smc_action_text
    sta.z smc_action_text
    lda #>smc_action_text
    sta.z smc_action_text+1
    // smc_read::@2
  __b2:
    // smc_read::bank_set_bram1
    // BRAM = bank
    // [1695] BRAM = smc_read::smc_bram_bank -- vbuz1=vbuc1 
    lda #smc_bram_bank
    sta.z BRAM
    // [1696] phi from smc_read::bank_set_bram1 to smc_read::@16 [phi:smc_read::bank_set_bram1->smc_read::@16]
    // smc_read::@16
    // textcolor(WHITE)
    // [1697] call textcolor
    // [787] phi from smc_read::@16 to textcolor [phi:smc_read::@16->textcolor]
    // [787] phi textcolor::color#23 = WHITE [phi:smc_read::@16->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [1698] phi from smc_read::@16 to smc_read::@17 [phi:smc_read::@16->smc_read::@17]
    // smc_read::@17
    // gotoxy(x, y)
    // [1699] call gotoxy
    // [805] phi from smc_read::@17 to gotoxy [phi:smc_read::@17->gotoxy]
    // [805] phi gotoxy::y#37 = PROGRESS_Y [phi:smc_read::@17->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [805] phi gotoxy::x#37 = PROGRESS_X [phi:smc_read::@17->gotoxy#1] -- vbuyy=vbuc1 
    ldy #PROGRESS_X
    jsr gotoxy
    // [1700] phi from smc_read::@17 to smc_read::@18 [phi:smc_read::@17->smc_read::@18]
    // smc_read::@18
    // FILE *fp = fopen("SMC.BIN", "r")
    // [1701] call fopen
    // [2573] phi from smc_read::@18 to fopen [phi:smc_read::@18->fopen]
    // [2573] phi __errno#474 = __errno#100 [phi:smc_read::@18->fopen#0] -- register_copy 
    // [2573] phi fopen::pathtoken#0 = smc_read::path [phi:smc_read::@18->fopen#1] -- pbuz1=pbuc1 
    lda #<path
    sta.z fopen.pathtoken
    lda #>path
    sta.z fopen.pathtoken+1
    // [2573] phi __stdio_filecount#27 = __stdio_filecount#123 [phi:smc_read::@18->fopen#2] -- register_copy 
    jsr fopen
    // FILE *fp = fopen("SMC.BIN", "r")
    // [1702] fopen::return#3 = fopen::return#2
    // smc_read::@19
    // [1703] smc_read::fp#0 = fopen::return#3 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [1704] if((struct $2 *)0==smc_read::fp#0) goto smc_read::@3 -- pssc1_eq_pssz1_then_la1 
    lda.z fp
    cmp #<0
    bne !+
    lda.z fp+1
    cmp #>0
    bne !__b5+
    jmp __b5
  !__b5:
  !:
    // smc_read::@4
    // fgets(smc_file_header, 32, fp)
    // [1705] fgets::stream#0 = smc_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.stream
    lda.z fp+1
    sta.z fgets.stream+1
    // [1706] call fgets
    // [2714] phi from smc_read::@4 to fgets [phi:smc_read::@4->fgets]
    // [2714] phi fgets::ptr#14 = smc_file_header [phi:smc_read::@4->fgets#0] -- pbuz1=pbuc1 
    lda #<smc_file_header
    sta.z fgets.ptr
    lda #>smc_file_header
    sta.z fgets.ptr+1
    // [2714] phi fgets::size#10 = $20 [phi:smc_read::@4->fgets#1] -- vwum1=vbuc1 
    lda #<$20
    sta fgets.size
    lda #>$20
    sta fgets.size+1
    // [2714] phi fgets::stream#4 = fgets::stream#0 [phi:smc_read::@4->fgets#2] -- register_copy 
    jsr fgets
    // fgets(smc_file_header, 32, fp)
    // [1707] fgets::return#10 = fgets::return#1
    // smc_read::@20
    // smc_file_read = fgets(smc_file_header, 32, fp)
    // [1708] smc_read::smc_file_read#1 = fgets::return#10 -- vwum1=vwum2 
    lda fgets.return
    sta smc_file_read
    lda fgets.return+1
    sta smc_file_read+1
    // if(smc_file_read)
    // [1709] if(0==smc_read::smc_file_read#1) goto smc_read::@3 -- 0_eq_vwum1_then_la1 
    lda smc_file_read
    ora smc_file_read+1
    beq __b5
    // smc_read::@5
    // if(info_status == STATUS_CHECKING)
    // [1710] if(smc_read::info_status#10!=STATUS_CHECKING) goto smc_read::@7 -- vbum1_neq_vbuc1_then_la1 
    lda #STATUS_CHECKING
    cmp info_status
    bne __b4
    // [1711] phi from smc_read::@5 to smc_read::@6 [phi:smc_read::@5->smc_read::@6]
    // smc_read::@6
    // [1712] phi from smc_read::@6 to smc_read::@7 [phi:smc_read::@6->smc_read::@7]
    // [1712] phi smc_read::y#12 = PROGRESS_Y [phi:smc_read::@6->smc_read::@7#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1712] phi smc_read::progress_row_bytes#10 = 0 [phi:smc_read::@6->smc_read::@7#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z progress_row_bytes
    sta.z progress_row_bytes+1
    // [1712] phi smc_read::smc_file_size#10 = 0 [phi:smc_read::@6->smc_read::@7#2] -- vwuz1=vwuc1 
    sta.z smc_file_size
    sta.z smc_file_size+1
    // [1712] phi smc_read::smc_bram_ptr#10 = (char *) 1024 [phi:smc_read::@6->smc_read::@7#3] -- pbuz1=pbuc1 
    lda #<$400
    sta.z smc_bram_ptr
    lda #>$400
    sta.z smc_bram_ptr+1
    jmp __b7
  // We read block_size bytes at a time, and each block_size bytes we plot a dot.
  // Every r bytes we move to the next line.
    // [1712] phi from smc_read::@5 to smc_read::@7 [phi:smc_read::@5->smc_read::@7]
  __b4:
    // [1712] phi smc_read::y#12 = PROGRESS_Y [phi:smc_read::@5->smc_read::@7#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1712] phi smc_read::progress_row_bytes#10 = 0 [phi:smc_read::@5->smc_read::@7#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z progress_row_bytes
    sta.z progress_row_bytes+1
    // [1712] phi smc_read::smc_file_size#10 = 0 [phi:smc_read::@5->smc_read::@7#2] -- vwuz1=vwuc1 
    sta.z smc_file_size
    sta.z smc_file_size+1
    // [1712] phi smc_read::smc_bram_ptr#10 = (char *)$a000 [phi:smc_read::@5->smc_read::@7#3] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z smc_bram_ptr
    lda #>$a000
    sta.z smc_bram_ptr+1
    // smc_read::@7
  __b7:
    // fgets(smc_bram_ptr, SMC_PROGRESS_CELL, fp)
    // [1713] fgets::ptr#3 = smc_read::smc_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z smc_bram_ptr
    sta.z fgets.ptr
    lda.z smc_bram_ptr+1
    sta.z fgets.ptr+1
    // [1714] fgets::stream#1 = smc_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.stream
    lda.z fp+1
    sta.z fgets.stream+1
    // [1715] call fgets
    // [2714] phi from smc_read::@7 to fgets [phi:smc_read::@7->fgets]
    // [2714] phi fgets::ptr#14 = fgets::ptr#3 [phi:smc_read::@7->fgets#0] -- register_copy 
    // [2714] phi fgets::size#10 = SMC_PROGRESS_CELL [phi:smc_read::@7->fgets#1] -- vwum1=vbuc1 
    lda #<SMC_PROGRESS_CELL
    sta fgets.size
    lda #>SMC_PROGRESS_CELL
    sta fgets.size+1
    // [2714] phi fgets::stream#4 = fgets::stream#1 [phi:smc_read::@7->fgets#2] -- register_copy 
    jsr fgets
    // fgets(smc_bram_ptr, SMC_PROGRESS_CELL, fp)
    // [1716] fgets::return#11 = fgets::return#1
    // smc_read::@21
    // smc_file_read = fgets(smc_bram_ptr, SMC_PROGRESS_CELL, fp)
    // [1717] smc_read::smc_file_read#10 = fgets::return#11 -- vwuz1=vwum2 
    lda fgets.return
    sta.z smc_file_read_1
    lda fgets.return+1
    sta.z smc_file_read_1+1
    // while (smc_file_read = fgets(smc_bram_ptr, SMC_PROGRESS_CELL, fp))
    // [1718] if(0!=smc_read::smc_file_read#10) goto smc_read::@8 -- 0_neq_vwuz1_then_la1 
    lda.z smc_file_read_1
    ora.z smc_file_read_1+1
    bne __b8
    // smc_read::@9
    // fclose(fp)
    // [1719] fclose::stream#0 = smc_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fclose.stream
    lda.z fp+1
    sta.z fclose.stream+1
    // [1720] call fclose
    // [2654] phi from smc_read::@9 to fclose [phi:smc_read::@9->fclose]
    // [2654] phi fclose::stream#3 = fclose::stream#0 [phi:smc_read::@9->fclose#0] -- register_copy 
    jsr fclose
    // [1721] phi from smc_read::@9 to smc_read::@3 [phi:smc_read::@9->smc_read::@3]
    // [1721] phi __stdio_filecount#36 = __stdio_filecount#2 [phi:smc_read::@9->smc_read::@3#0] -- register_copy 
    // [1721] phi smc_read::return#0 = smc_read::smc_file_size#10 [phi:smc_read::@9->smc_read::@3#1] -- register_copy 
    rts
    // [1721] phi from smc_read::@19 smc_read::@20 to smc_read::@3 [phi:smc_read::@19/smc_read::@20->smc_read::@3]
  __b5:
    // [1721] phi __stdio_filecount#36 = __stdio_filecount#1 [phi:smc_read::@19/smc_read::@20->smc_read::@3#0] -- register_copy 
    // [1721] phi smc_read::return#0 = 0 [phi:smc_read::@19/smc_read::@20->smc_read::@3#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // smc_read::@3
    // smc_read::@return
    // }
    // [1722] return 
    rts
    // smc_read::@8
  __b8:
    // display_action_text_reading(smc_action_text, "SMC.BIN", smc_file_size, SMC_CHIP_SIZE, smc_bram_bank, smc_bram_ptr)
    // [1723] display_action_text_reading::action#0 = smc_read::smc_action_text#12 -- pbuz1=pbuz2 
    lda.z smc_action_text
    sta.z display_action_text_reading.action
    lda.z smc_action_text+1
    sta.z display_action_text_reading.action+1
    // [1724] display_action_text_reading::bytes#0 = smc_read::smc_file_size#10 -- vduz1=vwuz2 
    lda.z smc_file_size
    sta.z display_action_text_reading.bytes
    lda.z smc_file_size+1
    sta.z display_action_text_reading.bytes+1
    lda #0
    sta.z display_action_text_reading.bytes+2
    sta.z display_action_text_reading.bytes+3
    // [1725] display_action_text_reading::bram_ptr#0 = smc_read::smc_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z smc_bram_ptr
    sta.z display_action_text_reading.bram_ptr
    lda.z smc_bram_ptr+1
    sta.z display_action_text_reading.bram_ptr+1
    // [1726] call display_action_text_reading
    // [2683] phi from smc_read::@8 to display_action_text_reading [phi:smc_read::@8->display_action_text_reading]
    // [2683] phi display_action_text_reading::bram_ptr#10 = display_action_text_reading::bram_ptr#0 [phi:smc_read::@8->display_action_text_reading#0] -- register_copy 
    // [2683] phi display_action_text_reading::bram_bank#10 = smc_read::smc_bram_bank [phi:smc_read::@8->display_action_text_reading#1] -- vbuz1=vbuc1 
    lda #smc_bram_bank
    sta.z display_action_text_reading.bram_bank
    // [2683] phi display_action_text_reading::size#10 = SMC_CHIP_SIZE [phi:smc_read::@8->display_action_text_reading#2] -- vduz1=vduc1 
    lda #<SMC_CHIP_SIZE
    sta.z display_action_text_reading.size
    lda #>SMC_CHIP_SIZE
    sta.z display_action_text_reading.size+1
    lda #<SMC_CHIP_SIZE>>$10
    sta.z display_action_text_reading.size+2
    lda #>SMC_CHIP_SIZE>>$10
    sta.z display_action_text_reading.size+3
    // [2683] phi display_action_text_reading::bytes#3 = display_action_text_reading::bytes#0 [phi:smc_read::@8->display_action_text_reading#3] -- register_copy 
    // [2683] phi display_action_text_reading::file#3 = smc_read::path [phi:smc_read::@8->display_action_text_reading#4] -- pbuz1=pbuc1 
    lda #<path
    sta.z display_action_text_reading.file
    lda #>path
    sta.z display_action_text_reading.file+1
    // [2683] phi display_action_text_reading::action#3 = display_action_text_reading::action#0 [phi:smc_read::@8->display_action_text_reading#5] -- register_copy 
    jsr display_action_text_reading
    // smc_read::@22
    // if (progress_row_bytes == SMC_PROGRESS_ROW)
    // [1727] if(smc_read::progress_row_bytes#10!=SMC_PROGRESS_ROW) goto smc_read::@10 -- vwuz1_neq_vwuc1_then_la1 
    lda.z progress_row_bytes+1
    cmp #>SMC_PROGRESS_ROW
    bne __b10
    lda.z progress_row_bytes
    cmp #<SMC_PROGRESS_ROW
    bne __b10
    // smc_read::@13
    // gotoxy(x, ++y);
    // [1728] smc_read::y#1 = ++ smc_read::y#12 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1729] gotoxy::y#23 = smc_read::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1730] call gotoxy
    // [805] phi from smc_read::@13 to gotoxy [phi:smc_read::@13->gotoxy]
    // [805] phi gotoxy::y#37 = gotoxy::y#23 [phi:smc_read::@13->gotoxy#0] -- register_copy 
    // [805] phi gotoxy::x#37 = PROGRESS_X [phi:smc_read::@13->gotoxy#1] -- vbuyy=vbuc1 
    ldy #PROGRESS_X
    jsr gotoxy
    // [1731] phi from smc_read::@13 to smc_read::@10 [phi:smc_read::@13->smc_read::@10]
    // [1731] phi smc_read::y#13 = smc_read::y#1 [phi:smc_read::@13->smc_read::@10#0] -- register_copy 
    // [1731] phi smc_read::progress_row_bytes#11 = 0 [phi:smc_read::@13->smc_read::@10#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z progress_row_bytes
    sta.z progress_row_bytes+1
    // [1731] phi from smc_read::@22 to smc_read::@10 [phi:smc_read::@22->smc_read::@10]
    // [1731] phi smc_read::y#13 = smc_read::y#12 [phi:smc_read::@22->smc_read::@10#0] -- register_copy 
    // [1731] phi smc_read::progress_row_bytes#11 = smc_read::progress_row_bytes#10 [phi:smc_read::@22->smc_read::@10#1] -- register_copy 
    // smc_read::@10
  __b10:
    // if(info_status == STATUS_READING)
    // [1732] if(smc_read::info_status#10!=STATUS_READING) goto smc_read::@11 -- vbum1_neq_vbuc1_then_la1 
    lda #STATUS_READING
    cmp info_status
    bne __b11
    // smc_read::@14
    // cputc('.')
    // [1733] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [1734] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_read::@11
  __b11:
    // if(info_status == STATUS_CHECKING)
    // [1736] if(smc_read::info_status#10==STATUS_CHECKING) goto smc_read::@12 -- vbum1_eq_vbuc1_then_la1 
    lda #STATUS_CHECKING
    cmp info_status
    beq __b6
    // smc_read::@15
    // smc_bram_ptr += smc_file_read
    // [1737] smc_read::smc_bram_ptr#3 = smc_read::smc_bram_ptr#10 + smc_read::smc_file_read#10 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z smc_bram_ptr
    adc.z smc_file_read_1
    sta.z smc_bram_ptr
    lda.z smc_bram_ptr+1
    adc.z smc_file_read_1+1
    sta.z smc_bram_ptr+1
    // [1738] phi from smc_read::@15 to smc_read::@12 [phi:smc_read::@15->smc_read::@12]
    // [1738] phi smc_read::smc_bram_ptr#7 = smc_read::smc_bram_ptr#3 [phi:smc_read::@15->smc_read::@12#0] -- register_copy 
    jmp __b12
    // [1738] phi from smc_read::@11 to smc_read::@12 [phi:smc_read::@11->smc_read::@12]
  __b6:
    // [1738] phi smc_read::smc_bram_ptr#7 = (char *) 1024 [phi:smc_read::@11->smc_read::@12#0] -- pbuz1=pbuc1 
    lda #<$400
    sta.z smc_bram_ptr
    lda #>$400
    sta.z smc_bram_ptr+1
    // smc_read::@12
  __b12:
    // smc_file_size += smc_file_read
    // [1739] smc_read::smc_file_size#1 = smc_read::smc_file_size#10 + smc_read::smc_file_read#10 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z smc_file_size
    adc.z smc_file_read_1
    sta.z smc_file_size
    lda.z smc_file_size+1
    adc.z smc_file_read_1+1
    sta.z smc_file_size+1
    // progress_row_bytes += smc_file_read
    // [1740] smc_read::progress_row_bytes#2 = smc_read::progress_row_bytes#11 + smc_read::smc_file_read#10 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z progress_row_bytes
    adc.z smc_file_read_1
    sta.z progress_row_bytes
    lda.z progress_row_bytes+1
    adc.z smc_file_read_1+1
    sta.z progress_row_bytes+1
    // [1712] phi from smc_read::@12 to smc_read::@7 [phi:smc_read::@12->smc_read::@7]
    // [1712] phi smc_read::y#12 = smc_read::y#13 [phi:smc_read::@12->smc_read::@7#0] -- register_copy 
    // [1712] phi smc_read::progress_row_bytes#10 = smc_read::progress_row_bytes#2 [phi:smc_read::@12->smc_read::@7#1] -- register_copy 
    // [1712] phi smc_read::smc_file_size#10 = smc_read::smc_file_size#1 [phi:smc_read::@12->smc_read::@7#2] -- register_copy 
    // [1712] phi smc_read::smc_bram_ptr#10 = smc_read::smc_bram_ptr#7 [phi:smc_read::@12->smc_read::@7#3] -- register_copy 
    jmp __b7
  .segment Data
    path: .text "SMC.BIN"
    .byte 0
    smc_file_read: .word 0
    .label y = main.check_status_vera10_return
    .label info_status = main.check_status_smc16_return
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
// __mem() unsigned int smc_flash(__mem() unsigned int smc_bytes_total)
smc_flash: {
    .const smc_bram_bank = 1
    .label smc_bootloader_start = $cd
    .label smc_bootloader_not_activated = $25
    .label smc_bytes_checksum = $b4
    .label smc_package_flashed = $76
    // smc_flash::bank_set_bram1
    // BRAM = bank
    // [1742] BRAM = smc_flash::smc_bram_bank -- vbuz1=vbuc1 
    lda #smc_bram_bank
    sta.z BRAM
    // [1743] phi from smc_flash::bank_set_bram1 to smc_flash::@25 [phi:smc_flash::bank_set_bram1->smc_flash::@25]
    // smc_flash::@25
    // display_action_progress("To start the SMC update, do the following ...")
    // [1744] call display_action_progress
    // [1155] phi from smc_flash::@25 to display_action_progress [phi:smc_flash::@25->display_action_progress]
    // [1155] phi display_action_progress::info_text#30 = smc_flash::info_text [phi:smc_flash::@25->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // smc_flash::@29
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [1745] smc_flash::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [1746] smc_flash::cx16_k_i2c_write_byte1_offset = $8f -- vbum1=vbuc1 
    lda #$8f
    sta cx16_k_i2c_write_byte1_offset
    // [1747] smc_flash::cx16_k_i2c_write_byte1_value = $31 -- vbum1=vbuc1 
    lda #$31
    sta cx16_k_i2c_write_byte1_value
    // smc_flash::cx16_k_i2c_write_byte1
    // unsigned char result
    // [1748] smc_flash::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
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
    // [1750] smc_flash::cx16_k_i2c_write_byte1_return#0 = smc_flash::cx16_k_i2c_write_byte1_result -- vbuaa=vbum1 
    lda cx16_k_i2c_write_byte1_result
    // smc_flash::cx16_k_i2c_write_byte1_@return
    // }
    // [1751] smc_flash::cx16_k_i2c_write_byte1_return#1 = smc_flash::cx16_k_i2c_write_byte1_return#0
    // smc_flash::@26
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [1752] smc_flash::smc_bootloader_start#0 = smc_flash::cx16_k_i2c_write_byte1_return#1 -- vbuz1=vbuaa 
    sta.z smc_bootloader_start
    // if(smc_bootloader_start)
    // [1753] if(0==smc_flash::smc_bootloader_start#0) goto smc_flash::@3 -- 0_eq_vbuz1_then_la1 
    beq __b6
    // [1754] phi from smc_flash::@26 to smc_flash::@2 [phi:smc_flash::@26->smc_flash::@2]
    // smc_flash::@2
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1755] call snprintf_init
    // [1184] phi from smc_flash::@2 to snprintf_init [phi:smc_flash::@2->snprintf_init]
    // [1184] phi snprintf_init::s#30 = info_text [phi:smc_flash::@2->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1756] phi from smc_flash::@2 to smc_flash::@30 [phi:smc_flash::@2->smc_flash::@30]
    // smc_flash::@30
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1757] call printf_str
    // [1125] phi from smc_flash::@30 to printf_str [phi:smc_flash::@30->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:smc_flash::@30->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = smc_flash::s [phi:smc_flash::@30->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@31
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1758] printf_uchar::uvalue#6 = smc_flash::smc_bootloader_start#0 -- vbuxx=vbuz1 
    ldx.z smc_bootloader_start
    // [1759] call printf_uchar
    // [1189] phi from smc_flash::@31 to printf_uchar [phi:smc_flash::@31->printf_uchar]
    // [1189] phi printf_uchar::format_zero_padding#15 = 0 [phi:smc_flash::@31->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1189] phi printf_uchar::format_min_length#15 = 0 [phi:smc_flash::@31->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1189] phi printf_uchar::putc#15 = &snputc [phi:smc_flash::@31->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1189] phi printf_uchar::format_radix#15 = HEXADECIMAL [phi:smc_flash::@31->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #HEXADECIMAL
    // [1189] phi printf_uchar::uvalue#15 = printf_uchar::uvalue#6 [phi:smc_flash::@31->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // smc_flash::@32
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1760] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1761] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1763] call display_action_text
    // [1200] phi from smc_flash::@32 to display_action_text [phi:smc_flash::@32->display_action_text]
    // [1200] phi display_action_text::info_text#25 = info_text [phi:smc_flash::@32->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_flash::@33
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [1764] smc_flash::cx16_k_i2c_write_byte2_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte2_device
    // [1765] smc_flash::cx16_k_i2c_write_byte2_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte2_offset
    // [1766] smc_flash::cx16_k_i2c_write_byte2_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte2_value
    // smc_flash::cx16_k_i2c_write_byte2
    // unsigned char result
    // [1767] smc_flash::cx16_k_i2c_write_byte2_result = 0 -- vbum1=vbuc1 
    sta cx16_k_i2c_write_byte2_result
    // asm
    // asm { ldxdevice ldyoffset ldavalue stzresult jsrCX16_I2C_WRITE_BYTE rolresult  }
    ldx cx16_k_i2c_write_byte2_device
    ldy cx16_k_i2c_write_byte2_offset
    lda cx16_k_i2c_write_byte2_value
    stz cx16_k_i2c_write_byte2_result
    jsr CX16_I2C_WRITE_BYTE
    rol cx16_k_i2c_write_byte2_result
    // [1769] phi from smc_flash::@51 smc_flash::cx16_k_i2c_write_byte2 to smc_flash::@return [phi:smc_flash::@51/smc_flash::cx16_k_i2c_write_byte2->smc_flash::@return]
  __b2:
    // [1769] phi smc_flash::return#1 = 0 [phi:smc_flash::@51/smc_flash::cx16_k_i2c_write_byte2->smc_flash::@return#0] -- vwum1=vbuc1 
    lda #<0
    sta return
    sta return+1
    // smc_flash::@return
    // }
    // [1770] return 
    rts
    // [1771] phi from smc_flash::@26 to smc_flash::@3 [phi:smc_flash::@26->smc_flash::@3]
  __b6:
    // [1771] phi smc_flash::smc_bootloader_activation_countdown#10 = $80 [phi:smc_flash::@26->smc_flash::@3#0] -- vbum1=vbuc1 
    lda #$80
    sta smc_bootloader_activation_countdown
    // smc_flash::@3
  __b3:
    // while(smc_bootloader_activation_countdown)
    // [1772] if(0!=smc_flash::smc_bootloader_activation_countdown#10) goto smc_flash::@4 -- 0_neq_vbum1_then_la1 
    lda smc_bootloader_activation_countdown
    beq !__b4+
    jmp __b4
  !__b4:
    // [1773] phi from smc_flash::@3 smc_flash::@34 to smc_flash::@7 [phi:smc_flash::@3/smc_flash::@34->smc_flash::@7]
  __b9:
    // [1773] phi smc_flash::smc_bootloader_activation_countdown#12 = $a [phi:smc_flash::@3/smc_flash::@34->smc_flash::@7#0] -- vbum1=vbuc1 
    lda #$a
    sta smc_bootloader_activation_countdown_1
    // smc_flash::@7
  __b7:
    // while(smc_bootloader_activation_countdown)
    // [1774] if(0!=smc_flash::smc_bootloader_activation_countdown#12) goto smc_flash::@8 -- 0_neq_vbum1_then_la1 
    lda smc_bootloader_activation_countdown_1
    beq !__b8+
    jmp __b8
  !__b8:
    // smc_flash::@9
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1775] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1776] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [1777] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [1778] cx16_k_i2c_read_byte::return#12 = cx16_k_i2c_read_byte::return#1
    // smc_flash::@46
    // smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1779] smc_flash::smc_bootloader_not_activated#1 = cx16_k_i2c_read_byte::return#12 -- vwuz1=vwum2 
    lda cx16_k_i2c_read_byte.return
    sta.z smc_bootloader_not_activated
    lda cx16_k_i2c_read_byte.return+1
    sta.z smc_bootloader_not_activated+1
    // if(smc_bootloader_not_activated)
    // [1780] if(0==smc_flash::smc_bootloader_not_activated#1) goto smc_flash::@1 -- 0_eq_vwuz1_then_la1 
    lda.z smc_bootloader_not_activated
    ora.z smc_bootloader_not_activated+1
    beq __b1
    // [1781] phi from smc_flash::@46 to smc_flash::@10 [phi:smc_flash::@46->smc_flash::@10]
    // smc_flash::@10
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1782] call snprintf_init
    // [1184] phi from smc_flash::@10 to snprintf_init [phi:smc_flash::@10->snprintf_init]
    // [1184] phi snprintf_init::s#30 = info_text [phi:smc_flash::@10->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1783] phi from smc_flash::@10 to smc_flash::@49 [phi:smc_flash::@10->smc_flash::@49]
    // smc_flash::@49
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1784] call printf_str
    // [1125] phi from smc_flash::@49 to printf_str [phi:smc_flash::@49->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:smc_flash::@49->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = smc_flash::s5 [phi:smc_flash::@49->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@50
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1785] printf_uint::uvalue#3 = smc_flash::smc_bootloader_not_activated#1 -- vwum1=vwuz2 
    lda.z smc_bootloader_not_activated
    sta printf_uint.uvalue
    lda.z smc_bootloader_not_activated+1
    sta printf_uint.uvalue+1
    // [1786] call printf_uint
    // [2015] phi from smc_flash::@50 to printf_uint [phi:smc_flash::@50->printf_uint]
    // [2015] phi printf_uint::format_zero_padding#10 = 0 [phi:smc_flash::@50->printf_uint#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uint.format_zero_padding
    // [2015] phi printf_uint::format_min_length#10 = 0 [phi:smc_flash::@50->printf_uint#1] -- vbum1=vbuc1 
    sta printf_uint.format_min_length
    // [2015] phi printf_uint::putc#10 = &snputc [phi:smc_flash::@50->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [2015] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:smc_flash::@50->printf_uint#3] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [2015] phi printf_uint::uvalue#10 = printf_uint::uvalue#3 [phi:smc_flash::@50->printf_uint#4] -- register_copy 
    jsr printf_uint
    // smc_flash::@51
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1787] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1788] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1790] call display_action_text
    // [1200] phi from smc_flash::@51 to display_action_text [phi:smc_flash::@51->display_action_text]
    // [1200] phi display_action_text::info_text#25 = info_text [phi:smc_flash::@51->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    jmp __b2
    // [1791] phi from smc_flash::@46 to smc_flash::@1 [phi:smc_flash::@46->smc_flash::@1]
    // smc_flash::@1
  __b1:
    // display_action_progress("Updating SMC firmware ... (+) Updated")
    // [1792] call display_action_progress
    // [1155] phi from smc_flash::@1 to display_action_progress [phi:smc_flash::@1->display_action_progress]
    // [1155] phi display_action_progress::info_text#30 = smc_flash::info_text1 [phi:smc_flash::@1->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_action_progress.info_text
    lda #>info_text1
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1793] phi from smc_flash::@1 to smc_flash::@47 [phi:smc_flash::@1->smc_flash::@47]
    // smc_flash::@47
    // textcolor(WHITE)
    // [1794] call textcolor
    // [787] phi from smc_flash::@47 to textcolor [phi:smc_flash::@47->textcolor]
    // [787] phi textcolor::color#23 = WHITE [phi:smc_flash::@47->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [1795] phi from smc_flash::@47 to smc_flash::@48 [phi:smc_flash::@47->smc_flash::@48]
    // smc_flash::@48
    // gotoxy(x, y)
    // [1796] call gotoxy
    // [805] phi from smc_flash::@48 to gotoxy [phi:smc_flash::@48->gotoxy]
    // [805] phi gotoxy::y#37 = PROGRESS_Y [phi:smc_flash::@48->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [805] phi gotoxy::x#37 = PROGRESS_X [phi:smc_flash::@48->gotoxy#1] -- vbuyy=vbuc1 
    ldy #PROGRESS_X
    jsr gotoxy
    // [1797] phi from smc_flash::@48 to smc_flash::@11 [phi:smc_flash::@48->smc_flash::@11]
    // [1797] phi smc_flash::y#36 = PROGRESS_Y [phi:smc_flash::@48->smc_flash::@11#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1797] phi smc_flash::smc_row_bytes#16 = 0 [phi:smc_flash::@48->smc_flash::@11#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_row_bytes
    sta smc_row_bytes+1
    // [1797] phi smc_flash::smc_bram_ptr#14 = (char *)$a000 [phi:smc_flash::@48->smc_flash::@11#2] -- pbum1=pbuc1 
    lda #<$a000
    sta smc_bram_ptr
    lda #>$a000
    sta smc_bram_ptr+1
    // [1797] phi smc_flash::smc_flashed_bytes#10 = 0 [phi:smc_flash::@48->smc_flash::@11#3] -- vwum1=vwuc1 
    lda #<0
    sta smc_flashed_bytes
    sta smc_flashed_bytes+1
    // smc_flash::@11
  __b11:
    // while(smc_flashed_bytes < smc_bytes_total)
    // [1798] if(smc_flash::smc_flashed_bytes#10<smc_flash::smc_bytes_total#0) goto smc_flash::@13 -- vwum1_lt_vwum2_then_la1 
    lda smc_flashed_bytes+1
    cmp smc_bytes_total+1
    bcc __b10
    bne !+
    lda smc_flashed_bytes
    cmp smc_bytes_total
    bcc __b10
  !:
    // smc_flash::@12
    // display_action_text_flashed(smc_flashed_bytes, "SMC")
    // [1799] display_action_text_flashed::bytes#0 = smc_flash::smc_flashed_bytes#10 -- vdum1=vwum2 
    lda smc_flashed_bytes
    sta display_action_text_flashed.bytes
    lda smc_flashed_bytes+1
    sta display_action_text_flashed.bytes+1
    lda #0
    sta display_action_text_flashed.bytes+2
    sta display_action_text_flashed.bytes+3
    // [1800] call display_action_text_flashed
    // [2824] phi from smc_flash::@12 to display_action_text_flashed [phi:smc_flash::@12->display_action_text_flashed]
    // [2824] phi display_action_text_flashed::chip#3 = smc_flash::chip [phi:smc_flash::@12->display_action_text_flashed#0] -- pbuz1=pbuc1 
    lda #<chip
    sta.z display_action_text_flashed.chip
    lda #>chip
    sta.z display_action_text_flashed.chip+1
    // [2824] phi display_action_text_flashed::bytes#3 = display_action_text_flashed::bytes#0 [phi:smc_flash::@12->display_action_text_flashed#1] -- register_copy 
    jsr display_action_text_flashed
    // [1801] phi from smc_flash::@12 to smc_flash::@52 [phi:smc_flash::@12->smc_flash::@52]
    // smc_flash::@52
    // wait_moment(16)
    // [1802] call wait_moment
    // [1134] phi from smc_flash::@52 to wait_moment [phi:smc_flash::@52->wait_moment]
    // [1134] phi wait_moment::w#17 = $10 [phi:smc_flash::@52->wait_moment#0] -- vbuz1=vbuc1 
    lda #$10
    sta.z wait_moment.w
    jsr wait_moment
    // [1769] phi from smc_flash::@52 to smc_flash::@return [phi:smc_flash::@52->smc_flash::@return]
    // [1769] phi smc_flash::return#1 = smc_flash::smc_flashed_bytes#10 [phi:smc_flash::@52->smc_flash::@return#0] -- register_copy 
    rts
    // [1803] phi from smc_flash::@11 to smc_flash::@13 [phi:smc_flash::@11->smc_flash::@13]
  __b10:
    // [1803] phi smc_flash::y#21 = smc_flash::y#36 [phi:smc_flash::@11->smc_flash::@13#0] -- register_copy 
    // [1803] phi smc_flash::smc_row_bytes#11 = smc_flash::smc_row_bytes#16 [phi:smc_flash::@11->smc_flash::@13#1] -- register_copy 
    // [1803] phi smc_flash::smc_flashed_bytes#11 = smc_flash::smc_flashed_bytes#10 [phi:smc_flash::@11->smc_flash::@13#2] -- register_copy 
    // [1803] phi smc_flash::smc_bram_ptr#12 = smc_flash::smc_bram_ptr#14 [phi:smc_flash::@11->smc_flash::@13#3] -- register_copy 
    // [1803] phi smc_flash::smc_attempts_flashed#15 = 0 [phi:smc_flash::@11->smc_flash::@13#4] -- vbum1=vbuc1 
    lda #0
    sta smc_attempts_flashed
    // [1803] phi smc_flash::smc_package_committed#10 = 0 [phi:smc_flash::@11->smc_flash::@13#5] -- vbum1=vbuc1 
    sta smc_package_committed
    // smc_flash::@13
  __b13:
    // while(!smc_package_committed && smc_attempts_flashed < 10)
    // [1804] if(0!=smc_flash::smc_package_committed#10) goto smc_flash::@15 -- 0_neq_vbum1_then_la1 
    lda smc_package_committed
    bne __b15
    // smc_flash::@58
    // [1805] if(smc_flash::smc_attempts_flashed#15<$a) goto smc_flash::@14 -- vbum1_lt_vbuc1_then_la1 
    lda smc_attempts_flashed
    cmp #$a
    bcs !__b14+
    jmp __b14
  !__b14:
    // smc_flash::@15
  __b15:
    // if(smc_attempts_flashed >= 10)
    // [1806] if(smc_flash::smc_attempts_flashed#15<$a) goto smc_flash::@24 -- vbum1_lt_vbuc1_then_la1 
    lda smc_attempts_flashed
    cmp #$a
    bcc __b24
    // [1807] phi from smc_flash::@15 to smc_flash::@23 [phi:smc_flash::@15->smc_flash::@23]
    // smc_flash::@23
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_flashed_bytes)
    // [1808] call snprintf_init
    // [1184] phi from smc_flash::@23 to snprintf_init [phi:smc_flash::@23->snprintf_init]
    // [1184] phi snprintf_init::s#30 = info_text [phi:smc_flash::@23->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1809] phi from smc_flash::@23 to smc_flash::@55 [phi:smc_flash::@23->smc_flash::@55]
    // smc_flash::@55
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_flashed_bytes)
    // [1810] call printf_str
    // [1125] phi from smc_flash::@55 to printf_str [phi:smc_flash::@55->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:smc_flash::@55->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = smc_flash::s6 [phi:smc_flash::@55->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@56
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_flashed_bytes)
    // [1811] printf_uint::uvalue#4 = smc_flash::smc_flashed_bytes#11 -- vwum1=vwum2 
    lda smc_flashed_bytes
    sta printf_uint.uvalue
    lda smc_flashed_bytes+1
    sta printf_uint.uvalue+1
    // [1812] call printf_uint
    // [2015] phi from smc_flash::@56 to printf_uint [phi:smc_flash::@56->printf_uint]
    // [2015] phi printf_uint::format_zero_padding#10 = 1 [phi:smc_flash::@56->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [2015] phi printf_uint::format_min_length#10 = 4 [phi:smc_flash::@56->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [2015] phi printf_uint::putc#10 = &snputc [phi:smc_flash::@56->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [2015] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:smc_flash::@56->printf_uint#3] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [2015] phi printf_uint::uvalue#10 = printf_uint::uvalue#4 [phi:smc_flash::@56->printf_uint#4] -- register_copy 
    jsr printf_uint
    // smc_flash::@57
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_flashed_bytes)
    // [1813] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1814] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1816] call display_action_text
    // [1200] phi from smc_flash::@57 to display_action_text [phi:smc_flash::@57->display_action_text]
    // [1200] phi display_action_text::info_text#25 = info_text [phi:smc_flash::@57->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1769] phi from smc_flash::@57 to smc_flash::@return [phi:smc_flash::@57->smc_flash::@return]
    // [1769] phi smc_flash::return#1 = $ffff [phi:smc_flash::@57->smc_flash::@return#0] -- vwum1=vwuc1 
    lda #<$ffff
    sta return
    lda #>$ffff
    sta return+1
    rts
    // smc_flash::@24
  __b24:
    // get_info_text_flashing(smc_flashed_bytes)
    // [1817] get_info_text_flashing::flash_bytes#0 = smc_flash::smc_flashed_bytes#11 -- vduz1=vwum2 
    lda smc_flashed_bytes
    sta.z get_info_text_flashing.flash_bytes
    lda smc_flashed_bytes+1
    sta.z get_info_text_flashing.flash_bytes+1
    lda #0
    sta.z get_info_text_flashing.flash_bytes+2
    sta.z get_info_text_flashing.flash_bytes+3
    // [1818] call get_info_text_flashing
    // [2841] phi from smc_flash::@24 to get_info_text_flashing [phi:smc_flash::@24->get_info_text_flashing]
    // [2841] phi get_info_text_flashing::flash_bytes#3 = get_info_text_flashing::flash_bytes#0 [phi:smc_flash::@24->get_info_text_flashing#0] -- register_copy 
    jsr get_info_text_flashing
    // smc_flash::@54
    // [1819] smc_bootloader#600 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_FLASHING, get_info_text_flashing(smc_flashed_bytes))
    // [1820] call display_info_smc
    // [925] phi from smc_flash::@54 to display_info_smc [phi:smc_flash::@54->display_info_smc]
    // [925] phi display_info_smc::info_text#24 = info_text [phi:smc_flash::@54->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_smc.info_text
    lda #>@info_text
    sta.z display_info_smc.info_text+1
    // [925] phi smc_bootloader#14 = smc_bootloader#600 [phi:smc_flash::@54->display_info_smc#1] -- register_copy 
    // [925] phi display_info_smc::info_status#24 = STATUS_FLASHING [phi:smc_flash::@54->display_info_smc#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHING
    sta.z display_info_smc.info_status
    jsr display_info_smc
    // [1797] phi from smc_flash::@54 to smc_flash::@11 [phi:smc_flash::@54->smc_flash::@11]
    // [1797] phi smc_flash::y#36 = smc_flash::y#21 [phi:smc_flash::@54->smc_flash::@11#0] -- register_copy 
    // [1797] phi smc_flash::smc_row_bytes#16 = smc_flash::smc_row_bytes#11 [phi:smc_flash::@54->smc_flash::@11#1] -- register_copy 
    // [1797] phi smc_flash::smc_bram_ptr#14 = smc_flash::smc_bram_ptr#12 [phi:smc_flash::@54->smc_flash::@11#2] -- register_copy 
    // [1797] phi smc_flash::smc_flashed_bytes#10 = smc_flash::smc_flashed_bytes#11 [phi:smc_flash::@54->smc_flash::@11#3] -- register_copy 
    jmp __b11
    // smc_flash::@14
  __b14:
    // display_action_text_flashing(8, "SMC", smc_bram_bank, smc_bram_ptr, smc_flashed_bytes)
    // [1821] display_action_text_flashing::bram_ptr#0 = smc_flash::smc_bram_ptr#12 -- pbuz1=pbum2 
    lda smc_bram_ptr
    sta.z display_action_text_flashing.bram_ptr
    lda smc_bram_ptr+1
    sta.z display_action_text_flashing.bram_ptr+1
    // [1822] display_action_text_flashing::address#0 = smc_flash::smc_flashed_bytes#11 -- vduz1=vwum2 
    lda smc_flashed_bytes
    sta.z display_action_text_flashing.address
    lda smc_flashed_bytes+1
    sta.z display_action_text_flashing.address+1
    lda #0
    sta.z display_action_text_flashing.address+2
    sta.z display_action_text_flashing.address+3
    // [1823] call display_action_text_flashing
    // [2863] phi from smc_flash::@14 to display_action_text_flashing [phi:smc_flash::@14->display_action_text_flashing]
    // [2863] phi display_action_text_flashing::address#10 = display_action_text_flashing::address#0 [phi:smc_flash::@14->display_action_text_flashing#0] -- register_copy 
    // [2863] phi display_action_text_flashing::chip#10 = smc_flash::chip [phi:smc_flash::@14->display_action_text_flashing#1] -- pbuz1=pbuc1 
    lda #<chip
    sta.z display_action_text_flashing.chip
    lda #>chip
    sta.z display_action_text_flashing.chip+1
    // [2863] phi display_action_text_flashing::bram_ptr#3 = display_action_text_flashing::bram_ptr#0 [phi:smc_flash::@14->display_action_text_flashing#2] -- register_copy 
    // [2863] phi display_action_text_flashing::bram_bank#3 = smc_flash::smc_bram_bank [phi:smc_flash::@14->display_action_text_flashing#3] -- vbuz1=vbuc1 
    lda #smc_bram_bank
    sta.z display_action_text_flashing.bram_bank
    // [2863] phi display_action_text_flashing::bytes#3 = 8 [phi:smc_flash::@14->display_action_text_flashing#4] -- vduz1=vbuc1 
    lda #8
    sta.z display_action_text_flashing.bytes
    lda #0
    sta.z display_action_text_flashing.bytes+1
    sta.z display_action_text_flashing.bytes+2
    sta.z display_action_text_flashing.bytes+3
    jsr display_action_text_flashing
    // [1824] phi from smc_flash::@14 to smc_flash::@16 [phi:smc_flash::@14->smc_flash::@16]
    // [1824] phi smc_flash::smc_bytes_checksum#2 = 0 [phi:smc_flash::@14->smc_flash::@16#0] -- vbuz1=vbuc1 
    lda #0
    sta.z smc_bytes_checksum
    // [1824] phi smc_flash::smc_bram_ptr#10 = smc_flash::smc_bram_ptr#12 [phi:smc_flash::@14->smc_flash::@16#1] -- register_copy 
    // [1824] phi smc_flash::smc_package_flashed#2 = 0 [phi:smc_flash::@14->smc_flash::@16#2] -- vwuz1=vwuc1 
    sta.z smc_package_flashed
    sta.z smc_package_flashed+1
    // smc_flash::@16
  __b16:
    // while(smc_package_flashed < SMC_PROGRESS_CELL)
    // [1825] if(smc_flash::smc_package_flashed#2<SMC_PROGRESS_CELL) goto smc_flash::@17 -- vwuz1_lt_vbuc1_then_la1 
    lda.z smc_package_flashed+1
    bne !+
    lda.z smc_package_flashed
    cmp #SMC_PROGRESS_CELL
    bcs !__b17+
    jmp __b17
  !__b17:
  !:
    // smc_flash::@18
    // smc_bytes_checksum ^ 0xFF
    // [1826] smc_flash::$30 = smc_flash::smc_bytes_checksum#2 ^ $ff -- vbuaa=vbuz1_bxor_vbuc1 
    lda #$ff
    eor.z smc_bytes_checksum
    // (smc_bytes_checksum ^ 0xFF)+1
    // [1827] smc_flash::$31 = smc_flash::$30 + 1 -- vbuxx=vbuaa_plus_1 
    tax
    inx
    // unsigned char smc_checksum_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, (smc_bytes_checksum ^ 0xFF)+1)
    // [1828] smc_flash::cx16_k_i2c_write_byte4_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte4_device
    // [1829] smc_flash::cx16_k_i2c_write_byte4_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte4_offset
    // [1830] smc_flash::cx16_k_i2c_write_byte4_value = smc_flash::$31 -- vbum1=vbuxx 
    stx cx16_k_i2c_write_byte4_value
    // smc_flash::cx16_k_i2c_write_byte4
    // unsigned char result
    // [1831] smc_flash::cx16_k_i2c_write_byte4_result = 0 -- vbum1=vbuc1 
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
    // smc_flash::@28
    // unsigned int smc_commit_result = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_COMMIT)
    // [1833] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1834] cx16_k_i2c_read_byte::offset = $81 -- vbum1=vbuc1 
    lda #$81
    sta cx16_k_i2c_read_byte.offset
    // [1835] call cx16_k_i2c_read_byte
    // Now send the commit command.
    jsr cx16_k_i2c_read_byte
    // [1836] cx16_k_i2c_read_byte::return#13 = cx16_k_i2c_read_byte::return#1
    // smc_flash::@53
    // [1837] smc_flash::smc_commit_result#0 = cx16_k_i2c_read_byte::return#13 -- vwum1=vwum2 
    lda cx16_k_i2c_read_byte.return
    sta smc_commit_result
    lda cx16_k_i2c_read_byte.return+1
    sta smc_commit_result+1
    // if(smc_commit_result == 1)
    // [1838] if(smc_flash::smc_commit_result#0==1) goto smc_flash::@20 -- vwum1_eq_vbuc1_then_la1 
    bne !+
    lda smc_commit_result
    cmp #1
    beq __b20
  !:
    // smc_flash::@19
    // smc_bram_ptr -= SMC_PROGRESS_CELL
    // [1839] smc_flash::smc_bram_ptr#2 = smc_flash::smc_bram_ptr#10 - SMC_PROGRESS_CELL -- pbum1=pbum1_minus_vbuc1 
    sec
    lda smc_bram_ptr
    sbc #SMC_PROGRESS_CELL
    sta smc_bram_ptr
    lda smc_bram_ptr+1
    sbc #0
    sta smc_bram_ptr+1
    // smc_attempts_flashed++;
    // [1840] smc_flash::smc_attempts_flashed#1 = ++ smc_flash::smc_attempts_flashed#15 -- vbum1=_inc_vbum1 
    inc smc_attempts_flashed
    // [1803] phi from smc_flash::@19 to smc_flash::@13 [phi:smc_flash::@19->smc_flash::@13]
    // [1803] phi smc_flash::y#21 = smc_flash::y#21 [phi:smc_flash::@19->smc_flash::@13#0] -- register_copy 
    // [1803] phi smc_flash::smc_row_bytes#11 = smc_flash::smc_row_bytes#11 [phi:smc_flash::@19->smc_flash::@13#1] -- register_copy 
    // [1803] phi smc_flash::smc_flashed_bytes#11 = smc_flash::smc_flashed_bytes#11 [phi:smc_flash::@19->smc_flash::@13#2] -- register_copy 
    // [1803] phi smc_flash::smc_bram_ptr#12 = smc_flash::smc_bram_ptr#2 [phi:smc_flash::@19->smc_flash::@13#3] -- register_copy 
    // [1803] phi smc_flash::smc_attempts_flashed#15 = smc_flash::smc_attempts_flashed#1 [phi:smc_flash::@19->smc_flash::@13#4] -- register_copy 
    // [1803] phi smc_flash::smc_package_committed#10 = smc_flash::smc_package_committed#10 [phi:smc_flash::@19->smc_flash::@13#5] -- register_copy 
    jmp __b13
    // smc_flash::@20
  __b20:
    // if (smc_row_bytes == SMC_PROGRESS_ROW)
    // [1841] if(smc_flash::smc_row_bytes#11!=SMC_PROGRESS_ROW) goto smc_flash::@21 -- vwum1_neq_vwuc1_then_la1 
    lda smc_row_bytes+1
    cmp #>SMC_PROGRESS_ROW
    bne __b21
    lda smc_row_bytes
    cmp #<SMC_PROGRESS_ROW
    bne __b21
    // smc_flash::@22
    // gotoxy(x, ++y);
    // [1842] smc_flash::y#1 = ++ smc_flash::y#21 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1843] gotoxy::y#25 = smc_flash::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1844] call gotoxy
    // [805] phi from smc_flash::@22 to gotoxy [phi:smc_flash::@22->gotoxy]
    // [805] phi gotoxy::y#37 = gotoxy::y#25 [phi:smc_flash::@22->gotoxy#0] -- register_copy 
    // [805] phi gotoxy::x#37 = PROGRESS_X [phi:smc_flash::@22->gotoxy#1] -- vbuyy=vbuc1 
    ldy #PROGRESS_X
    jsr gotoxy
    // [1845] phi from smc_flash::@22 to smc_flash::@21 [phi:smc_flash::@22->smc_flash::@21]
    // [1845] phi smc_flash::y#38 = smc_flash::y#1 [phi:smc_flash::@22->smc_flash::@21#0] -- register_copy 
    // [1845] phi smc_flash::smc_row_bytes#4 = 0 [phi:smc_flash::@22->smc_flash::@21#1] -- vwum1=vbuc1 
    lda #<0
    sta smc_row_bytes
    sta smc_row_bytes+1
    // [1845] phi from smc_flash::@20 to smc_flash::@21 [phi:smc_flash::@20->smc_flash::@21]
    // [1845] phi smc_flash::y#38 = smc_flash::y#21 [phi:smc_flash::@20->smc_flash::@21#0] -- register_copy 
    // [1845] phi smc_flash::smc_row_bytes#4 = smc_flash::smc_row_bytes#11 [phi:smc_flash::@20->smc_flash::@21#1] -- register_copy 
    // smc_flash::@21
  __b21:
    // cputc('+')
    // [1846] stackpush(char) = '+' -- _stackpushbyte_=vbuc1 
    lda #'+'
    pha
    // [1847] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_flashed_bytes += SMC_PROGRESS_CELL
    // [1849] smc_flash::smc_flashed_bytes#1 = smc_flash::smc_flashed_bytes#11 + SMC_PROGRESS_CELL -- vwum1=vwum1_plus_vbuc1 
    lda #SMC_PROGRESS_CELL
    clc
    adc smc_flashed_bytes
    sta smc_flashed_bytes
    bcc !+
    inc smc_flashed_bytes+1
  !:
    // smc_row_bytes += SMC_PROGRESS_CELL
    // [1850] smc_flash::smc_row_bytes#1 = smc_flash::smc_row_bytes#4 + SMC_PROGRESS_CELL -- vwum1=vwum1_plus_vbuc1 
    lda #SMC_PROGRESS_CELL
    clc
    adc smc_row_bytes
    sta smc_row_bytes
    bcc !+
    inc smc_row_bytes+1
  !:
    // [1803] phi from smc_flash::@21 to smc_flash::@13 [phi:smc_flash::@21->smc_flash::@13]
    // [1803] phi smc_flash::y#21 = smc_flash::y#38 [phi:smc_flash::@21->smc_flash::@13#0] -- register_copy 
    // [1803] phi smc_flash::smc_row_bytes#11 = smc_flash::smc_row_bytes#1 [phi:smc_flash::@21->smc_flash::@13#1] -- register_copy 
    // [1803] phi smc_flash::smc_flashed_bytes#11 = smc_flash::smc_flashed_bytes#1 [phi:smc_flash::@21->smc_flash::@13#2] -- register_copy 
    // [1803] phi smc_flash::smc_bram_ptr#12 = smc_flash::smc_bram_ptr#10 [phi:smc_flash::@21->smc_flash::@13#3] -- register_copy 
    // [1803] phi smc_flash::smc_attempts_flashed#15 = smc_flash::smc_attempts_flashed#15 [phi:smc_flash::@21->smc_flash::@13#4] -- register_copy 
    // [1803] phi smc_flash::smc_package_committed#10 = 1 [phi:smc_flash::@21->smc_flash::@13#5] -- vbum1=vbuc1 
    lda #1
    sta smc_package_committed
    jmp __b13
    // smc_flash::@17
  __b17:
    // unsigned char smc_byte_upload = *smc_bram_ptr
    // [1851] smc_flash::smc_byte_upload#0 = *smc_flash::smc_bram_ptr#10 -- vbuxx=_deref_pbum1 
    ldy smc_bram_ptr
    sty.z $fe
    ldy smc_bram_ptr+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    tax
    // smc_bram_ptr++;
    // [1852] smc_flash::smc_bram_ptr#1 = ++ smc_flash::smc_bram_ptr#10 -- pbum1=_inc_pbum1 
    inc smc_bram_ptr
    bne !+
    inc smc_bram_ptr+1
  !:
    // smc_bytes_checksum += smc_byte_upload
    // [1853] smc_flash::smc_bytes_checksum#1 = smc_flash::smc_bytes_checksum#2 + smc_flash::smc_byte_upload#0 -- vbuz1=vbuz1_plus_vbuxx 
    txa
    clc
    adc.z smc_bytes_checksum
    sta.z smc_bytes_checksum
    // unsigned char smc_upload_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, smc_byte_upload)
    // [1854] smc_flash::cx16_k_i2c_write_byte3_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte3_device
    // [1855] smc_flash::cx16_k_i2c_write_byte3_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte3_offset
    // [1856] smc_flash::cx16_k_i2c_write_byte3_value = smc_flash::smc_byte_upload#0 -- vbum1=vbuxx 
    stx cx16_k_i2c_write_byte3_value
    // smc_flash::cx16_k_i2c_write_byte3
    // unsigned char result
    // [1857] smc_flash::cx16_k_i2c_write_byte3_result = 0 -- vbum1=vbuc1 
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
    // smc_flash::@27
    // smc_package_flashed++;
    // [1859] smc_flash::smc_package_flashed#1 = ++ smc_flash::smc_package_flashed#2 -- vwuz1=_inc_vwuz1 
    inc.z smc_package_flashed
    bne !+
    inc.z smc_package_flashed+1
  !:
    // [1824] phi from smc_flash::@27 to smc_flash::@16 [phi:smc_flash::@27->smc_flash::@16]
    // [1824] phi smc_flash::smc_bytes_checksum#2 = smc_flash::smc_bytes_checksum#1 [phi:smc_flash::@27->smc_flash::@16#0] -- register_copy 
    // [1824] phi smc_flash::smc_bram_ptr#10 = smc_flash::smc_bram_ptr#1 [phi:smc_flash::@27->smc_flash::@16#1] -- register_copy 
    // [1824] phi smc_flash::smc_package_flashed#2 = smc_flash::smc_package_flashed#1 [phi:smc_flash::@27->smc_flash::@16#2] -- register_copy 
    jmp __b16
    // [1860] phi from smc_flash::@7 to smc_flash::@8 [phi:smc_flash::@7->smc_flash::@8]
    // smc_flash::@8
  __b8:
    // wait_moment(1)
    // [1861] call wait_moment
    // [1134] phi from smc_flash::@8 to wait_moment [phi:smc_flash::@8->wait_moment]
    // [1134] phi wait_moment::w#17 = 1 [phi:smc_flash::@8->wait_moment#0] -- vbuz1=vbuc1 
    lda #1
    sta.z wait_moment.w
    jsr wait_moment
    // [1862] phi from smc_flash::@8 to smc_flash::@40 [phi:smc_flash::@8->smc_flash::@40]
    // smc_flash::@40
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1863] call snprintf_init
    // [1184] phi from smc_flash::@40 to snprintf_init [phi:smc_flash::@40->snprintf_init]
    // [1184] phi snprintf_init::s#30 = info_text [phi:smc_flash::@40->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1864] phi from smc_flash::@40 to smc_flash::@41 [phi:smc_flash::@40->smc_flash::@41]
    // smc_flash::@41
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1865] call printf_str
    // [1125] phi from smc_flash::@41 to printf_str [phi:smc_flash::@41->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:smc_flash::@41->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = smc_flash::s3 [phi:smc_flash::@41->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@42
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1866] printf_uchar::uvalue#8 = smc_flash::smc_bootloader_activation_countdown#12 -- vbuxx=vbum1 
    ldx smc_bootloader_activation_countdown_1
    // [1867] call printf_uchar
    // [1189] phi from smc_flash::@42 to printf_uchar [phi:smc_flash::@42->printf_uchar]
    // [1189] phi printf_uchar::format_zero_padding#15 = 0 [phi:smc_flash::@42->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1189] phi printf_uchar::format_min_length#15 = 0 [phi:smc_flash::@42->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1189] phi printf_uchar::putc#15 = &snputc [phi:smc_flash::@42->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1189] phi printf_uchar::format_radix#15 = DECIMAL [phi:smc_flash::@42->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [1189] phi printf_uchar::uvalue#15 = printf_uchar::uvalue#8 [phi:smc_flash::@42->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1868] phi from smc_flash::@42 to smc_flash::@43 [phi:smc_flash::@42->smc_flash::@43]
    // smc_flash::@43
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1869] call printf_str
    // [1125] phi from smc_flash::@43 to printf_str [phi:smc_flash::@43->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:smc_flash::@43->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = s4 [phi:smc_flash::@43->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@44
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1870] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1871] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1873] call display_action_text
    // [1200] phi from smc_flash::@44 to display_action_text [phi:smc_flash::@44->display_action_text]
    // [1200] phi display_action_text::info_text#25 = info_text [phi:smc_flash::@44->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_flash::@45
    // smc_bootloader_activation_countdown--;
    // [1874] smc_flash::smc_bootloader_activation_countdown#3 = -- smc_flash::smc_bootloader_activation_countdown#12 -- vbum1=_dec_vbum1 
    dec smc_bootloader_activation_countdown_1
    // [1773] phi from smc_flash::@45 to smc_flash::@7 [phi:smc_flash::@45->smc_flash::@7]
    // [1773] phi smc_flash::smc_bootloader_activation_countdown#12 = smc_flash::smc_bootloader_activation_countdown#3 [phi:smc_flash::@45->smc_flash::@7#0] -- register_copy 
    jmp __b7
    // smc_flash::@4
  __b4:
    // unsigned int smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1875] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1876] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [1877] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [1878] cx16_k_i2c_read_byte::return#11 = cx16_k_i2c_read_byte::return#1
    // smc_flash::@34
    // [1879] smc_flash::smc_bootloader_not_activated1#0 = cx16_k_i2c_read_byte::return#11 -- vwum1=vwum2 
    lda cx16_k_i2c_read_byte.return
    sta smc_bootloader_not_activated1
    lda cx16_k_i2c_read_byte.return+1
    sta smc_bootloader_not_activated1+1
    // if(smc_bootloader_not_activated)
    // [1880] if(0!=smc_flash::smc_bootloader_not_activated1#0) goto smc_flash::@5 -- 0_neq_vwum1_then_la1 
    lda smc_bootloader_not_activated1
    ora smc_bootloader_not_activated1+1
    bne __b5
    jmp __b9
    // [1881] phi from smc_flash::@34 to smc_flash::@5 [phi:smc_flash::@34->smc_flash::@5]
    // smc_flash::@5
  __b5:
    // wait_moment(1)
    // [1882] call wait_moment
    // [1134] phi from smc_flash::@5 to wait_moment [phi:smc_flash::@5->wait_moment]
    // [1134] phi wait_moment::w#17 = 1 [phi:smc_flash::@5->wait_moment#0] -- vbuz1=vbuc1 
    lda #1
    sta.z wait_moment.w
    jsr wait_moment
    // [1883] phi from smc_flash::@5 to smc_flash::@35 [phi:smc_flash::@5->smc_flash::@35]
    // smc_flash::@35
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1884] call snprintf_init
    // [1184] phi from smc_flash::@35 to snprintf_init [phi:smc_flash::@35->snprintf_init]
    // [1184] phi snprintf_init::s#30 = info_text [phi:smc_flash::@35->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1885] phi from smc_flash::@35 to smc_flash::@36 [phi:smc_flash::@35->smc_flash::@36]
    // smc_flash::@36
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1886] call printf_str
    // [1125] phi from smc_flash::@36 to printf_str [phi:smc_flash::@36->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:smc_flash::@36->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = s1 [phi:smc_flash::@36->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@37
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1887] printf_uchar::uvalue#7 = smc_flash::smc_bootloader_activation_countdown#10 -- vbuxx=vbum1 
    ldx smc_bootloader_activation_countdown
    // [1888] call printf_uchar
    // [1189] phi from smc_flash::@37 to printf_uchar [phi:smc_flash::@37->printf_uchar]
    // [1189] phi printf_uchar::format_zero_padding#15 = 1 [phi:smc_flash::@37->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1189] phi printf_uchar::format_min_length#15 = 3 [phi:smc_flash::@37->printf_uchar#1] -- vbum1=vbuc1 
    lda #3
    sta printf_uchar.format_min_length
    // [1189] phi printf_uchar::putc#15 = &snputc [phi:smc_flash::@37->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1189] phi printf_uchar::format_radix#15 = DECIMAL [phi:smc_flash::@37->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [1189] phi printf_uchar::uvalue#15 = printf_uchar::uvalue#7 [phi:smc_flash::@37->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1889] phi from smc_flash::@37 to smc_flash::@38 [phi:smc_flash::@37->smc_flash::@38]
    // smc_flash::@38
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1890] call printf_str
    // [1125] phi from smc_flash::@38 to printf_str [phi:smc_flash::@38->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:smc_flash::@38->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = smc_flash::s2 [phi:smc_flash::@38->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@39
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1891] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1892] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1894] call display_action_text
    // [1200] phi from smc_flash::@39 to display_action_text [phi:smc_flash::@39->display_action_text]
    // [1200] phi display_action_text::info_text#25 = info_text [phi:smc_flash::@39->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_flash::@6
    // smc_bootloader_activation_countdown--;
    // [1895] smc_flash::smc_bootloader_activation_countdown#2 = -- smc_flash::smc_bootloader_activation_countdown#10 -- vbum1=_dec_vbum1 
    dec smc_bootloader_activation_countdown
    // [1771] phi from smc_flash::@6 to smc_flash::@3 [phi:smc_flash::@6->smc_flash::@3]
    // [1771] phi smc_flash::smc_bootloader_activation_countdown#10 = smc_flash::smc_bootloader_activation_countdown#2 [phi:smc_flash::@6->smc_flash::@3#0] -- register_copy 
    jmp __b3
  .segment Data
    info_text: .text "To start the SMC update, do the following ..."
    .byte 0
    s: .text "There was a problem starting the SMC bootloader: "
    .byte 0
    s2: .text "] Press POWER and RESET on the CX16 to start the SMC update!"
    .byte 0
    s3: .text "Updating SMC in "
    .byte 0
    info_text1: .text "Updating SMC firmware ... (+) Updated"
    .byte 0
    s5: .text "There was a problem activating the SMC bootloader: "
    .byte 0
    chip: .text "SMC"
    .byte 0
    s6: .text "There were too many attempts trying to flash the SMC at location "
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
    return: .word 0
    smc_bootloader_not_activated1: .word 0
    // Waiting a bit to ensure the bootloader is activated.
    .label smc_bootloader_activation_countdown = main.check_status_smc17_return
    // Waiting a bit to ensure the bootloader is activated.
    .label smc_bootloader_activation_countdown_1 = main.check_status_vera11_return
    .label smc_bram_ptr = main.main__50
    smc_commit_result: .word 0
    .label smc_attempts_flashed = main.main__107
    .label smc_flashed_bytes = return
    .label smc_row_bytes = smc_read.smc_file_read
    .label y = main.check_status_vera4_return
    .label smc_bytes_total = fopen.fopen__11
    .label smc_package_committed = main.check_status_smc10_return
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
// __register(A) char util_wait_key(__zp($7e) char *info_text, __zp($32) char *filter)
util_wait_key: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 4
    .label util_wait_key__10 = $78
    .label bram = $d2
    .label info_text = $7e
    .label filter = $32
    // display_action_text(info_text)
    // [1897] display_action_text::info_text#0 = util_wait_key::info_text#6
    // [1898] call display_action_text
    // [1200] phi from util_wait_key to display_action_text [phi:util_wait_key->display_action_text]
    // [1200] phi display_action_text::info_text#25 = display_action_text::info_text#0 [phi:util_wait_key->display_action_text#0] -- register_copy 
    jsr display_action_text
    // util_wait_key::bank_get_bram1
    // return BRAM;
    // [1899] util_wait_key::bram#0 = BRAM -- vbuz1=vbuz2 
    lda.z BRAM
    sta.z bram
    // util_wait_key::bank_get_brom1
    // return BROM;
    // [1900] util_wait_key::brom#0 = BROM -- vbum1=vbuz2 
    lda.z BROM
    sta brom
    // util_wait_key::bank_set_bram1
    // BRAM = bank
    // [1901] BRAM = util_wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // util_wait_key::bank_set_brom1
    // BROM = bank
    // [1902] BROM = util_wait_key::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // util_wait_key::CLI1
    // asm
    // asm { cli  }
    cli
    // [1904] phi from util_wait_key::@2 util_wait_key::@5 util_wait_key::CLI1 to util_wait_key::kbhit1 [phi:util_wait_key::@2/util_wait_key::@5/util_wait_key::CLI1->util_wait_key::kbhit1]
    // util_wait_key::kbhit1
  kbhit1:
    // util_wait_key::kbhit1_cbm_k_clrchn1
    // asm
    // asm { jsrCBM_CLRCHN  }
    jsr CBM_CLRCHN
    // [1906] phi from util_wait_key::kbhit1_cbm_k_clrchn1 to util_wait_key::kbhit1_@2 [phi:util_wait_key::kbhit1_cbm_k_clrchn1->util_wait_key::kbhit1_@2]
    // util_wait_key::kbhit1_@2
    // cbm_k_getin()
    // [1907] call cbm_k_getin
    jsr cbm_k_getin
    // [1908] cbm_k_getin::return#2 = cbm_k_getin::return#1
    // util_wait_key::@4
    // [1909] util_wait_key::ch#4 = cbm_k_getin::return#2 -- vwum1=vbuaa 
    sta ch
    lda #0
    sta ch+1
    // util_wait_key::@3
    // if (filter)
    // [1910] if((char *)0!=util_wait_key::filter#16) goto util_wait_key::@1 -- pbuc1_neq_pbuz1_then_la1 
    // if there is a filter, check the filter, otherwise return ch.
    lda.z filter+1
    cmp #>0
    bne __b1
    lda.z filter
    cmp #<0
    bne __b1
    // util_wait_key::@2
    // if(ch)
    // [1911] if(0!=util_wait_key::ch#4) goto util_wait_key::bank_set_bram2 -- 0_neq_vwum1_then_la1 
    lda ch
    ora ch+1
    bne bank_set_bram2
    jmp kbhit1
    // util_wait_key::bank_set_bram2
  bank_set_bram2:
    // BRAM = bank
    // [1912] BRAM = util_wait_key::bram#0 -- vbuz1=vbuz2 
    lda.z bram
    sta.z BRAM
    // util_wait_key::bank_set_brom2
    // BROM = bank
    // [1913] BROM = util_wait_key::brom#0 -- vbuz1=vbum2 
    lda brom
    sta.z BROM
    // util_wait_key::@return
    // }
    // [1914] return 
    rts
    // util_wait_key::@1
  __b1:
    // strchr(filter, ch)
    // [1915] strchr::str#0 = (const void *)util_wait_key::filter#16 -- pvoz1=pvoz2 
    lda.z filter
    sta.z strchr.str
    lda.z filter+1
    sta.z strchr.str+1
    // [1916] strchr::c#0 = util_wait_key::ch#4 -- vbum1=vwum2 
    lda ch
    sta strchr.c
    // [1917] call strchr
    // [1921] phi from util_wait_key::@1 to strchr [phi:util_wait_key::@1->strchr]
    // [1921] phi strchr::c#4 = strchr::c#0 [phi:util_wait_key::@1->strchr#0] -- register_copy 
    // [1921] phi strchr::str#2 = strchr::str#0 [phi:util_wait_key::@1->strchr#1] -- register_copy 
    jsr strchr
    // strchr(filter, ch)
    // [1918] strchr::return#3 = strchr::return#2
    // util_wait_key::@5
    // [1919] util_wait_key::$10 = strchr::return#3
    // if(strchr(filter, ch) != NULL)
    // [1920] if(util_wait_key::$10!=0) goto util_wait_key::bank_set_bram2 -- pvoz1_neq_0_then_la1 
    lda.z util_wait_key__10
    ora.z util_wait_key__10+1
    bne bank_set_bram2
    jmp kbhit1
  .segment Data
    brom: .byte 0
    ch: .word 0
}
.segment Code
  // strchr
// Searches for the first occurrence of the character c (an unsigned char) in the string pointed to, by the argument str.
// - str: The memory to search
// - c: A character to search for
// Return: A pointer to the matching byte or NULL if the character does not occur in the given memory area.
// __zp($78) void * strchr(__zp($78) const void *str, __mem() char c)
strchr: {
    .label ptr = $78
    .label return = $78
    .label str = $78
    // [1922] strchr::ptr#6 = (char *)strchr::str#2
    // [1923] phi from strchr strchr::@3 to strchr::@1 [phi:strchr/strchr::@3->strchr::@1]
    // [1923] phi strchr::ptr#2 = strchr::ptr#6 [phi:strchr/strchr::@3->strchr::@1#0] -- register_copy 
    // strchr::@1
  __b1:
    // while(*ptr)
    // [1924] if(0!=*strchr::ptr#2) goto strchr::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (ptr),y
    cmp #0
    bne __b2
    // [1925] phi from strchr::@1 to strchr::@return [phi:strchr::@1->strchr::@return]
    // [1925] phi strchr::return#2 = (void *) 0 [phi:strchr::@1->strchr::@return#0] -- pvoz1=pvoc1 
    tya
    sta.z return
    sta.z return+1
    // strchr::@return
    // }
    // [1926] return 
    rts
    // strchr::@2
  __b2:
    // if(*ptr==c)
    // [1927] if(*strchr::ptr#2!=strchr::c#4) goto strchr::@3 -- _deref_pbuz1_neq_vbum2_then_la1 
    ldy #0
    lda (ptr),y
    cmp c
    bne __b3
    // strchr::@4
    // [1928] strchr::return#8 = (void *)strchr::ptr#2
    // [1925] phi from strchr::@4 to strchr::@return [phi:strchr::@4->strchr::@return]
    // [1925] phi strchr::return#2 = strchr::return#8 [phi:strchr::@4->strchr::@return#0] -- register_copy 
    rts
    // strchr::@3
  __b3:
    // ptr++;
    // [1929] strchr::ptr#1 = ++ strchr::ptr#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr
    bne !+
    inc.z ptr+1
  !:
    jmp __b1
  .segment Data
    .label c = printf_uchar.format_min_length
}
.segment Code
  // display_info_vera
/**
 * @brief Display the VERA status at the info frame.
 * 
 * @param info_status The STATUS_ 
 */
// void display_info_vera(__mem() char info_status, __zp($2c) char *info_text)
display_info_vera: {
    .label info_text = $2c
    // unsigned char x = wherex()
    // [1931] call wherex
    jsr wherex
    // [1932] wherex::return#11 = wherex::return#0
    // display_info_vera::@3
    // [1933] display_info_vera::x#0 = wherex::return#11 -- vbum1=vbuaa 
    sta x
    // unsigned char y = wherey()
    // [1934] call wherey
    jsr wherey
    // [1935] wherey::return#11 = wherey::return#0
    // display_info_vera::@4
    // [1936] display_info_vera::y#0 = wherey::return#11 -- vbum1=vbuaa 
    sta y
    // status_vera = info_status
    // [1937] status_vera#115 = display_info_vera::info_status#15 -- vbum1=vbum2 
    lda info_status
    sta status_vera
    // display_vera_led(status_color[info_status])
    // [1938] display_vera_led::c#1 = status_color[display_info_vera::info_status#15] -- vbuz1=pbuc1_derefidx_vbum2 
    ldy info_status
    lda status_color,y
    sta.z display_vera_led.c
    // [1939] call display_vera_led
    // [2910] phi from display_info_vera::@4 to display_vera_led [phi:display_info_vera::@4->display_vera_led]
    // [2910] phi display_vera_led::c#2 = display_vera_led::c#1 [phi:display_info_vera::@4->display_vera_led#0] -- register_copy 
    jsr display_vera_led
    // [1940] phi from display_info_vera::@4 to display_info_vera::@5 [phi:display_info_vera::@4->display_info_vera::@5]
    // display_info_vera::@5
    // gotoxy(INFO_X, INFO_Y+1)
    // [1941] call gotoxy
    // [805] phi from display_info_vera::@5 to gotoxy [phi:display_info_vera::@5->gotoxy]
    // [805] phi gotoxy::y#37 = $11+1 [phi:display_info_vera::@5->gotoxy#0] -- vbum1=vbuc1 
    lda #$11+1
    sta gotoxy.y
    // [805] phi gotoxy::x#37 = 4 [phi:display_info_vera::@5->gotoxy#1] -- vbuyy=vbuc1 
    ldy #4
    jsr gotoxy
    // [1942] phi from display_info_vera::@5 to display_info_vera::@6 [phi:display_info_vera::@5->display_info_vera::@6]
    // display_info_vera::@6
    // printf("VERA %-9s W25Q16", status_text[info_status])
    // [1943] call printf_str
    // [1125] phi from display_info_vera::@6 to printf_str [phi:display_info_vera::@6->printf_str]
    // [1125] phi printf_str::putc#79 = &cputc [phi:display_info_vera::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = display_info_vera::s [phi:display_info_vera::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@7
    // printf("VERA %-9s W25Q16", status_text[info_status])
    // [1944] display_info_vera::$9 = display_info_vera::info_status#15 << 1 -- vbuaa=vbum1_rol_1 
    lda info_status
    asl
    // [1945] printf_string::str#6 = status_text[display_info_vera::$9] -- pbuz1=qbuc1_derefidx_vbuaa 
    tay
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [1946] call printf_string
    // [1419] phi from display_info_vera::@7 to printf_string [phi:display_info_vera::@7->printf_string]
    // [1419] phi printf_string::putc#26 = &cputc [phi:display_info_vera::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1419] phi printf_string::str#26 = printf_string::str#6 [phi:display_info_vera::@7->printf_string#1] -- register_copy 
    // [1419] phi printf_string::format_justify_left#26 = 1 [phi:display_info_vera::@7->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1419] phi printf_string::format_min_length#26 = 9 [phi:display_info_vera::@7->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [1947] phi from display_info_vera::@7 to display_info_vera::@8 [phi:display_info_vera::@7->display_info_vera::@8]
    // display_info_vera::@8
    // printf("VERA %-9s W25Q16", status_text[info_status])
    // [1948] call printf_str
    // [1125] phi from display_info_vera::@8 to printf_str [phi:display_info_vera::@8->printf_str]
    // [1125] phi printf_str::putc#79 = &cputc [phi:display_info_vera::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = display_info_vera::s1 [phi:display_info_vera::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@9
    // if(info_text)
    // [1949] if((char *)0==display_info_vera::info_text#15) goto display_info_vera::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // [1950] phi from display_info_vera::@9 to display_info_vera::@2 [phi:display_info_vera::@9->display_info_vera::@2]
    // display_info_vera::@2
    // gotoxy(INFO_X+64-28, INFO_Y+1)
    // [1951] call gotoxy
    // [805] phi from display_info_vera::@2 to gotoxy [phi:display_info_vera::@2->gotoxy]
    // [805] phi gotoxy::y#37 = $11+1 [phi:display_info_vera::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #$11+1
    sta gotoxy.y
    // [805] phi gotoxy::x#37 = 4+$40-$1c [phi:display_info_vera::@2->gotoxy#1] -- vbuyy=vbuc1 
    ldy #4+$40-$1c
    jsr gotoxy
    // display_info_vera::@10
    // printf("%-25s", info_text)
    // [1952] printf_string::str#7 = display_info_vera::info_text#15 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1953] call printf_string
    // [1419] phi from display_info_vera::@10 to printf_string [phi:display_info_vera::@10->printf_string]
    // [1419] phi printf_string::putc#26 = &cputc [phi:display_info_vera::@10->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1419] phi printf_string::str#26 = printf_string::str#7 [phi:display_info_vera::@10->printf_string#1] -- register_copy 
    // [1419] phi printf_string::format_justify_left#26 = 1 [phi:display_info_vera::@10->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1419] phi printf_string::format_min_length#26 = $19 [phi:display_info_vera::@10->printf_string#3] -- vbum1=vbuc1 
    lda #$19
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_vera::@1
  __b1:
    // gotoxy(x, y)
    // [1954] gotoxy::x#17 = display_info_vera::x#0 -- vbuyy=vbum1 
    ldy x
    // [1955] gotoxy::y#17 = display_info_vera::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1956] call gotoxy
    // [805] phi from display_info_vera::@1 to gotoxy [phi:display_info_vera::@1->gotoxy]
    // [805] phi gotoxy::y#37 = gotoxy::y#17 [phi:display_info_vera::@1->gotoxy#0] -- register_copy 
    // [805] phi gotoxy::x#37 = gotoxy::x#17 [phi:display_info_vera::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_vera::@return
    // }
    // [1957] return 
    rts
  .segment Data
    s: .text "VERA "
    .byte 0
    s1: .text " W25Q16"
    .byte 0
    x: .byte 0
    y: .byte 0
    .label info_status = rom_detect.rom_detect__24
}
.segment Code
  // util_wait_space
util_wait_space: {
    // util_wait_key("Press [SPACE] to continue ...", " ")
    // [1959] call util_wait_key
    // [1896] phi from util_wait_space to util_wait_key [phi:util_wait_space->util_wait_key]
    // [1896] phi util_wait_key::filter#16 = s [phi:util_wait_space->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z util_wait_key.filter
    lda #>s
    sta.z util_wait_key.filter+1
    // [1896] phi util_wait_key::info_text#6 = util_wait_space::info_text [phi:util_wait_space->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z util_wait_key.info_text
    lda #>info_text
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // util_wait_space::@return
    // }
    // [1960] return 
    rts
  .segment Data
    info_text: .text "Press [SPACE] to continue ..."
    .byte 0
}
.segment Code
  // display_info_cx16_rom
/**
 * @brief Display the ROM status of the main CX16 ROM chip.
 * 
 * @param info_status The status.
 * @param info_text The status text.
 */
// void display_info_cx16_rom(__register(X) char info_status, __zp($78) char *info_text)
display_info_cx16_rom: {
    .label info_text = $78
    // display_info_rom(0, info_status, info_text)
    // [1962] display_info_rom::info_status#1 = display_info_cx16_rom::info_status#8 -- vbum1=vbuxx 
    stx display_info_rom.info_status
    // [1963] display_info_rom::info_text#1 = display_info_cx16_rom::info_text#8
    // [1964] call display_info_rom
    // [1368] phi from display_info_cx16_rom to display_info_rom [phi:display_info_cx16_rom->display_info_rom]
    // [1368] phi display_info_rom::info_text#16 = display_info_rom::info_text#1 [phi:display_info_cx16_rom->display_info_rom#0] -- register_copy 
    // [1368] phi display_info_rom::rom_chip#16 = 0 [phi:display_info_cx16_rom->display_info_rom#1] -- vbum1=vbuc1 
    lda #0
    sta display_info_rom.rom_chip
    // [1368] phi display_info_rom::info_status#16 = display_info_rom::info_status#1 [phi:display_info_cx16_rom->display_info_rom#2] -- register_copy 
    jsr display_info_rom
    // display_info_cx16_rom::@return
    // }
    // [1965] return 
    rts
}
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
    // [1967] rom_get_release::$0 = rom_get_release::release#3 & $80 -- vbuaa=vbuxx_band_vbuc1 
    txa
    and #$80
    // if(release & 0x80)
    // [1968] if(0==rom_get_release::$0) goto rom_get_release::@1 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b1
    // rom_get_release::@2
    // ~release
    // [1969] rom_get_release::$2 = ~ rom_get_release::release#3 -- vbuaa=_bnot_vbuxx 
    txa
    eor #$ff
    // release = ~release + 1
    // [1970] rom_get_release::release#0 = rom_get_release::$2 + 1 -- vbuxx=vbuaa_plus_1 
    tax
    inx
    // [1971] phi from rom_get_release rom_get_release::@2 to rom_get_release::@1 [phi:rom_get_release/rom_get_release::@2->rom_get_release::@1]
    // [1971] phi rom_get_release::return#0 = rom_get_release::release#3 [phi:rom_get_release/rom_get_release::@2->rom_get_release::@1#0] -- register_copy 
    // rom_get_release::@1
  __b1:
    // rom_get_release::@return
    // }
    // [1972] return 
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
    // [1974] if(rom_get_prefix::release#2!=$ff) goto rom_get_prefix::@1 -- vbuaa_neq_vbuc1_then_la1 
    cmp #$ff
    bne __b3
    // [1975] phi from rom_get_prefix to rom_get_prefix::@3 [phi:rom_get_prefix->rom_get_prefix::@3]
    // rom_get_prefix::@3
    // [1976] phi from rom_get_prefix::@3 to rom_get_prefix::@1 [phi:rom_get_prefix::@3->rom_get_prefix::@1]
    // [1976] phi rom_get_prefix::prefix#4 = 'p' [phi:rom_get_prefix::@3->rom_get_prefix::@1#0] -- vbuxx=vbuc1 
    ldx #'p'
    jmp __b1
    // [1976] phi from rom_get_prefix to rom_get_prefix::@1 [phi:rom_get_prefix->rom_get_prefix::@1]
  __b3:
    // [1976] phi rom_get_prefix::prefix#4 = 'r' [phi:rom_get_prefix->rom_get_prefix::@1#0] -- vbuxx=vbuc1 
    ldx #'r'
    // rom_get_prefix::@1
  __b1:
    // release & 0x80
    // [1977] rom_get_prefix::$2 = rom_get_prefix::release#2 & $80 -- vbuaa=vbuaa_band_vbuc1 
    and #$80
    // if(release & 0x80)
    // [1978] if(0==rom_get_prefix::$2) goto rom_get_prefix::@4 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b2
    // [1980] phi from rom_get_prefix::@1 to rom_get_prefix::@2 [phi:rom_get_prefix::@1->rom_get_prefix::@2]
    // [1980] phi rom_get_prefix::return#0 = 'p' [phi:rom_get_prefix::@1->rom_get_prefix::@2#0] -- vbuxx=vbuc1 
    ldx #'p'
    rts
    // [1979] phi from rom_get_prefix::@1 to rom_get_prefix::@4 [phi:rom_get_prefix::@1->rom_get_prefix::@4]
    // rom_get_prefix::@4
    // [1980] phi from rom_get_prefix::@4 to rom_get_prefix::@2 [phi:rom_get_prefix::@4->rom_get_prefix::@2]
    // [1980] phi rom_get_prefix::return#0 = rom_get_prefix::prefix#4 [phi:rom_get_prefix::@4->rom_get_prefix::@2#0] -- register_copy 
    // rom_get_prefix::@2
  __b2:
    // rom_get_prefix::@return
    // }
    // [1981] return 
    rts
}
  // rom_get_version_text
// void rom_get_version_text(__zp($76) char *release_info, __register(X) char prefix, __zp($bd) char release, __zp($7e) char *github)
rom_get_version_text: {
    .label release_info = $76
    .label release = $bd
    .label github = $7e
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [1983] snprintf_init::s#10 = rom_get_version_text::release_info#2
    // [1984] call snprintf_init
    // [1184] phi from rom_get_version_text to snprintf_init [phi:rom_get_version_text->snprintf_init]
    // [1184] phi snprintf_init::s#30 = snprintf_init::s#10 [phi:rom_get_version_text->snprintf_init#0] -- register_copy 
    jsr snprintf_init
    // rom_get_version_text::@1
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [1985] stackpush(char) = rom_get_version_text::prefix#2 -- _stackpushbyte_=vbuxx 
    txa
    pha
    // [1986] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [1988] printf_uchar::uvalue#9 = rom_get_version_text::release#2 -- vbuxx=vbuz1 
    ldx.z release
    // [1989] call printf_uchar
    // [1189] phi from rom_get_version_text::@1 to printf_uchar [phi:rom_get_version_text::@1->printf_uchar]
    // [1189] phi printf_uchar::format_zero_padding#15 = 0 [phi:rom_get_version_text::@1->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1189] phi printf_uchar::format_min_length#15 = 0 [phi:rom_get_version_text::@1->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1189] phi printf_uchar::putc#15 = &snputc [phi:rom_get_version_text::@1->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1189] phi printf_uchar::format_radix#15 = DECIMAL [phi:rom_get_version_text::@1->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #DECIMAL
    // [1189] phi printf_uchar::uvalue#15 = printf_uchar::uvalue#9 [phi:rom_get_version_text::@1->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1990] phi from rom_get_version_text::@1 to rom_get_version_text::@2 [phi:rom_get_version_text::@1->rom_get_version_text::@2]
    // rom_get_version_text::@2
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [1991] call printf_str
    // [1125] phi from rom_get_version_text::@2 to printf_str [phi:rom_get_version_text::@2->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:rom_get_version_text::@2->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = s [phi:rom_get_version_text::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_get_version_text::@3
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [1992] printf_string::str#16 = rom_get_version_text::github#2 -- pbuz1=pbuz2 
    lda.z github
    sta.z printf_string.str
    lda.z github+1
    sta.z printf_string.str+1
    // [1993] call printf_string
    // [1419] phi from rom_get_version_text::@3 to printf_string [phi:rom_get_version_text::@3->printf_string]
    // [1419] phi printf_string::putc#26 = &snputc [phi:rom_get_version_text::@3->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1419] phi printf_string::str#26 = printf_string::str#16 [phi:rom_get_version_text::@3->printf_string#1] -- register_copy 
    // [1419] phi printf_string::format_justify_left#26 = 0 [phi:rom_get_version_text::@3->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1419] phi printf_string::format_min_length#26 = 0 [phi:rom_get_version_text::@3->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // rom_get_version_text::@4
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [1994] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1995] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_get_version_text::@return
    // }
    // [1997] return 
    rts
}
  // rom_get_github_commit_id
/**
 * @brief Copy the github commit_id only if the commit_id contains hexadecimal characters. 
 * 
 * @param commit_id The target commit_id.
 * @param from The source ptr in ROM or RAM.
 */
// void rom_get_github_commit_id(__zp($5d) char *commit_id, __zp($59) char *from)
rom_get_github_commit_id: {
    .label commit_id = $5d
    .label from = $59
    // [1999] phi from rom_get_github_commit_id to rom_get_github_commit_id::@2 [phi:rom_get_github_commit_id->rom_get_github_commit_id::@2]
    // [1999] phi rom_get_github_commit_id::commit_id_ok#2 = true [phi:rom_get_github_commit_id->rom_get_github_commit_id::@2#0] -- vboxx=vboc1 
    lda #1
    tax
    // [1999] phi rom_get_github_commit_id::c#2 = 0 [phi:rom_get_github_commit_id->rom_get_github_commit_id::@2#1] -- vbuyy=vbuc1 
    ldy #0
    // rom_get_github_commit_id::@2
  __b2:
    // for(unsigned char c=0; c<7; c++)
    // [2000] if(rom_get_github_commit_id::c#2<7) goto rom_get_github_commit_id::@3 -- vbuyy_lt_vbuc1_then_la1 
    cpy #7
    bcc __b3
    // rom_get_github_commit_id::@4
    // if(commit_id_ok)
    // [2001] if(rom_get_github_commit_id::commit_id_ok#2) goto rom_get_github_commit_id::@1 -- vboxx_then_la1 
    cpx #0
    bne __b1
    // rom_get_github_commit_id::@6
    // *commit_id = '\0'
    // [2002] *rom_get_github_commit_id::commit_id#6 = '@' -- _deref_pbuz1=vbuc1 
    lda #'@'
    ldy #0
    sta (commit_id),y
    // rom_get_github_commit_id::@return
    // }
    // [2003] return 
    rts
    // rom_get_github_commit_id::@1
  __b1:
    // strncpy(commit_id, from, 7)
    // [2004] strncpy::dst#2 = rom_get_github_commit_id::commit_id#6
    // [2005] strncpy::src#2 = rom_get_github_commit_id::from#6
    // [2006] call strncpy
    // [2916] phi from rom_get_github_commit_id::@1 to strncpy [phi:rom_get_github_commit_id::@1->strncpy]
    // [2916] phi strncpy::dst#8 = strncpy::dst#2 [phi:rom_get_github_commit_id::@1->strncpy#0] -- register_copy 
    // [2916] phi strncpy::src#6 = strncpy::src#2 [phi:rom_get_github_commit_id::@1->strncpy#1] -- register_copy 
    // [2916] phi strncpy::n#3 = 7 [phi:rom_get_github_commit_id::@1->strncpy#2] -- vwum1=vbuc1 
    lda #<7
    sta strncpy.n
    lda #>7
    sta strncpy.n+1
    jsr strncpy
    rts
    // rom_get_github_commit_id::@3
  __b3:
    // unsigned char ch = from[c]
    // [2007] rom_get_github_commit_id::ch#0 = rom_get_github_commit_id::from#6[rom_get_github_commit_id::c#2] -- vbuaa=pbuz1_derefidx_vbuyy 
    lda (from),y
    // if(!(ch >= 48 && ch <= 48+9 || ch >= 65 && ch <= 65+26))
    // [2008] if(rom_get_github_commit_id::ch#0<$30) goto rom_get_github_commit_id::@7 -- vbuaa_lt_vbuc1_then_la1 
    cmp #$30
    bcc __b7
    // rom_get_github_commit_id::@8
    // [2009] if(rom_get_github_commit_id::ch#0<$30+9+1) goto rom_get_github_commit_id::@5 -- vbuaa_lt_vbuc1_then_la1 
    cmp #$30+9+1
    bcc __b5
    // rom_get_github_commit_id::@7
  __b7:
    // [2010] if(rom_get_github_commit_id::ch#0<$41) goto rom_get_github_commit_id::@5 -- vbuaa_lt_vbuc1_then_la1 
    cmp #$41
    bcc __b4
    // rom_get_github_commit_id::@9
    // [2011] if(rom_get_github_commit_id::ch#0<$41+$1a+1) goto rom_get_github_commit_id::@10 -- vbuaa_lt_vbuc1_then_la1 
    cmp #$41+$1a+1
    bcc __b5
    // [2013] phi from rom_get_github_commit_id::@7 rom_get_github_commit_id::@9 to rom_get_github_commit_id::@5 [phi:rom_get_github_commit_id::@7/rom_get_github_commit_id::@9->rom_get_github_commit_id::@5]
  __b4:
    // [2013] phi rom_get_github_commit_id::commit_id_ok#4 = false [phi:rom_get_github_commit_id::@7/rom_get_github_commit_id::@9->rom_get_github_commit_id::@5#0] -- vboxx=vboc1 
    lda #0
    tax
    // [2012] phi from rom_get_github_commit_id::@9 to rom_get_github_commit_id::@10 [phi:rom_get_github_commit_id::@9->rom_get_github_commit_id::@10]
    // rom_get_github_commit_id::@10
    // [2013] phi from rom_get_github_commit_id::@10 rom_get_github_commit_id::@8 to rom_get_github_commit_id::@5 [phi:rom_get_github_commit_id::@10/rom_get_github_commit_id::@8->rom_get_github_commit_id::@5]
    // [2013] phi rom_get_github_commit_id::commit_id_ok#4 = rom_get_github_commit_id::commit_id_ok#2 [phi:rom_get_github_commit_id::@10/rom_get_github_commit_id::@8->rom_get_github_commit_id::@5#0] -- register_copy 
    // rom_get_github_commit_id::@5
  __b5:
    // for(unsigned char c=0; c<7; c++)
    // [2014] rom_get_github_commit_id::c#1 = ++ rom_get_github_commit_id::c#2 -- vbuyy=_inc_vbuyy 
    iny
    // [1999] phi from rom_get_github_commit_id::@5 to rom_get_github_commit_id::@2 [phi:rom_get_github_commit_id::@5->rom_get_github_commit_id::@2]
    // [1999] phi rom_get_github_commit_id::commit_id_ok#2 = rom_get_github_commit_id::commit_id_ok#4 [phi:rom_get_github_commit_id::@5->rom_get_github_commit_id::@2#0] -- register_copy 
    // [1999] phi rom_get_github_commit_id::c#2 = rom_get_github_commit_id::c#1 [phi:rom_get_github_commit_id::@5->rom_get_github_commit_id::@2#1] -- register_copy 
    jmp __b2
}
  // printf_uint
// Print an unsigned int using a specific format
// void printf_uint(__zp($67) void (*putc)(char), __mem() unsigned int uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, __register(X) char format_radix)
printf_uint: {
    .label putc = $67
    // printf_uint::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [2016] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [2017] utoa::value#1 = printf_uint::uvalue#10
    // [2018] utoa::radix#0 = printf_uint::format_radix#10
    // [2019] call utoa
    // Format number into buffer
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [2020] printf_number_buffer::putc#1 = printf_uint::putc#10
    // [2021] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [2022] printf_number_buffer::format_min_length#1 = printf_uint::format_min_length#10 -- vbuxx=vbum1 
    ldx format_min_length
    // [2023] printf_number_buffer::format_zero_padding#1 = printf_uint::format_zero_padding#10
    // [2024] call printf_number_buffer
  // Print using format
    // [2362] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    // [2362] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#1 [phi:printf_uint::@2->printf_number_buffer#0] -- register_copy 
    // [2362] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_uint::@2->printf_number_buffer#1] -- register_copy 
    // [2362] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#1 [phi:printf_uint::@2->printf_number_buffer#2] -- register_copy 
    // [2362] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#1 [phi:printf_uint::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [2025] return 
    rts
  .segment Data
    .label uvalue = strncmp.n
    .label format_min_length = printf_uchar.format_min_length
    .label format_zero_padding = printf_uchar.format_zero_padding
}
.segment Code
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __register(X) char mapbase, __mem() char config)
screenlayer: {
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [2026] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [2027] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [2028] *((char *)&__conio+2) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+2
    // mapbase >> 7
    // [2029] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbuaa=vbuxx_ror_7 
    txa
    rol
    rol
    and #1
    // __conio.mapbase_bank = mapbase >> 7
    // [2030] *((char *)&__conio+5) = screenlayer::$0 -- _deref_pbuc1=vbuaa 
    sta __conio+5
    // (mapbase)<<1
    // [2031] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuaa=vbuxx_rol_1 
    txa
    asl
    // MAKEWORD((mapbase)<<1,0)
    // [2032] screenlayer::$2 = screenlayer::$1 w= 0 -- vwum1=vbuaa_word_vbuc1 
    ldy #0
    sta screenlayer__2+1
    sty screenlayer__2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [2033] *((unsigned int *)&__conio+3) = screenlayer::$2 -- _deref_pwuc1=vwum1 
    tya
    sta __conio+3
    lda screenlayer__2+1
    sta __conio+3+1
    // config & VERA_LAYER_WIDTH_MASK
    // [2034] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbuaa=vbum1_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and config
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [2035] screenlayer::$8 = screenlayer::$7 >> 4 -- vbuxx=vbuaa_ror_4 
    lsr
    lsr
    lsr
    lsr
    tax
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [2036] *((char *)&__conio+8) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbuxx 
    lda VERA_LAYER_DIM,x
    sta __conio+8
    // config & VERA_LAYER_HEIGHT_MASK
    // [2037] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbuaa=vbum1_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and config
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [2038] screenlayer::$6 = screenlayer::$5 >> 6 -- vbuaa=vbuaa_ror_6 
    rol
    rol
    rol
    and #3
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [2039] *((char *)&__conio+9) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbuaa 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+9
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [2040] screenlayer::$16 = screenlayer::$8 << 1 -- vbuaa=vbuxx_rol_1 
    txa
    asl
    // [2041] *((unsigned int *)&__conio+$a) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbuaa 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    tay
    lda VERA_LAYER_SKIP,y
    sta __conio+$a
    lda VERA_LAYER_SKIP+1,y
    sta __conio+$a+1
    // vera_dc_hscale_temp == 0x80
    // [2042] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vboaa=vbum1_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [2043] screenlayer::$18 = (char)screenlayer::$9 -- vbuxx=vbuaa 
    tax
    // [2044] screenlayer::$10 = $28 << screenlayer::$18 -- vbuaa=vbuc1_rol_vbuxx 
    lda #$28
    cpx #0
    beq !e+
  !:
    asl
    dex
    bne !-
  !e:
    // (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [2045] screenlayer::$11 = screenlayer::$10 - 1 -- vbuaa=vbuaa_minus_1 
    sec
    sbc #1
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [2046] *((char *)&__conio+6) = screenlayer::$11 -- _deref_pbuc1=vbuaa 
    sta __conio+6
    // vera_dc_vscale_temp == 0x80
    // [2047] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vboaa=vbum1_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [2048] screenlayer::$19 = (char)screenlayer::$12 -- vbuxx=vbuaa 
    tax
    // [2049] screenlayer::$13 = $1e << screenlayer::$19 -- vbuaa=vbuc1_rol_vbuxx 
    lda #$1e
    cpx #0
    beq !e+
  !:
    asl
    dex
    bne !-
  !e:
    // (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [2050] screenlayer::$14 = screenlayer::$13 - 1 -- vbuaa=vbuaa_minus_1 
    sec
    sbc #1
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [2051] *((char *)&__conio+7) = screenlayer::$14 -- _deref_pbuc1=vbuaa 
    sta __conio+7
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [2052] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta mapbase_offset
    lda __conio+3+1
    sta mapbase_offset+1
    // [2053] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [2053] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [2053] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuxx=vbuc1 
    ldx #0
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [2054] if(screenlayer::y#2<=*((char *)&__conio+7)) goto screenlayer::@2 -- vbuxx_le__deref_pbuc1_then_la1 
    lda __conio+7
    stx.z $ff
    cmp.z $ff
    bcs __b2
    // screenlayer::@return
    // }
    // [2055] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [2056] screenlayer::$17 = screenlayer::y#2 << 1 -- vbuaa=vbuxx_rol_1 
    txa
    asl
    // [2057] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbuaa=vwum1 
    tay
    lda mapbase_offset
    sta __conio+$15,y
    lda mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [2058] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda mapbase_offset
    adc __conio+$a
    sta mapbase_offset
    lda mapbase_offset+1
    adc __conio+$a+1
    sta mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [2059] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuxx=_inc_vbuxx 
    inx
    // [2053] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [2053] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [2053] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    VERA_LAYER_DIM: .byte $1f, $3f, $7f, $ff
    VERA_LAYER_SKIP: .word $40, $80, $100, $200
    .label screenlayer__2 = conio_x16_init.conio_x16_init__4
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
    // [2060] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [2061] if(0!=((char *)&__conio+$f)[*((char *)&__conio+2)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [2062] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // [2063] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [2064] call gotoxy
    // [805] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [805] phi gotoxy::y#37 = 0 [phi:cscroll::@3->gotoxy#0] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.y
    // [805] phi gotoxy::x#37 = 0 [phi:cscroll::@3->gotoxy#1] -- vbuyy=vbuc1 
    tay
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [2065] return 
    rts
    // [2066] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [2067] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [2068] gotoxy::y#3 = *((char *)&__conio+7) -- vbum1=_deref_pbuc1 
    lda __conio+7
    sta gotoxy.y
    // [2069] call gotoxy
    // [805] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [805] phi gotoxy::y#37 = gotoxy::y#3 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [805] phi gotoxy::x#37 = 0 [phi:cscroll::@5->gotoxy#1] -- vbuyy=vbuc1 
    ldy #0
    jsr gotoxy
    // [2070] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [2071] call clearline
    jsr clearline
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
    // cx16_k_screen_set_mode(0)
    // [2072] cx16_k_screen_set_mode::mode = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_screen_set_mode.mode
    // [2073] call cx16_k_screen_set_mode
    jsr cx16_k_screen_set_mode
    // [2074] phi from display_frame_init_64 to display_frame_init_64::@2 [phi:display_frame_init_64->display_frame_init_64::@2]
    // display_frame_init_64::@2
    // screenlayer1()
    // [2075] call screenlayer1
    // Default 80 columns mode.
    jsr screenlayer1
    // display_frame_init_64::@3
    // cx16_k_screen_set_charset(3, (char *)0)
    // [2076] display_frame_init_64::cx16_k_screen_set_charset1_charset = 3 -- vbum1=vbuc1 
    lda #3
    sta cx16_k_screen_set_charset1_charset
    // [2077] display_frame_init_64::cx16_k_screen_set_charset1_offset = (char *) 0 -- pbum1=pbuc1 
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
    // display_frame_init_64::vera_display_set_hstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [2079] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTART = start
    // [2080] *VERA_DC_HSTART = display_frame_init_64::vera_display_set_hstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstart1_start
    sta VERA_DC_HSTART
    // display_frame_init_64::vera_display_set_hstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [2081] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTOP = stop
    // [2082] *VERA_DC_HSTOP = display_frame_init_64::vera_display_set_hstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstop1_stop
    sta VERA_DC_HSTOP
    // display_frame_init_64::vera_display_set_vstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [2083] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTART = start
    // [2084] *VERA_DC_VSTART = display_frame_init_64::vera_display_set_vstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstart1_start
    sta VERA_DC_VSTART
    // display_frame_init_64::vera_display_set_vstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [2085] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTOP = stop
    // [2086] *VERA_DC_VSTOP = display_frame_init_64::vera_display_set_vstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstop1_stop
    sta VERA_DC_VSTOP
    // display_frame_init_64::vera_sprites_hide1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [2087] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VIDEO &= ~VERA_SPRITES_ENABLE
    // [2088] *VERA_DC_VIDEO = *VERA_DC_VIDEO & ~VERA_SPRITES_ENABLE -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_SPRITES_ENABLE^$ff
    and VERA_DC_VIDEO
    sta VERA_DC_VIDEO
    // display_frame_init_64::vera_layer0_hide1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [2089] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VIDEO &= ~VERA_LAYER0_ENABLE
    // [2090] *VERA_DC_VIDEO = *VERA_DC_VIDEO & ~VERA_LAYER0_ENABLE -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_LAYER0_ENABLE^$ff
    and VERA_DC_VIDEO
    sta VERA_DC_VIDEO
    // display_frame_init_64::vera_layer1_show1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [2091] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VIDEO |= VERA_LAYER1_ENABLE
    // [2092] *VERA_DC_VIDEO = *VERA_DC_VIDEO | VERA_LAYER1_ENABLE -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_LAYER1_ENABLE
    ora VERA_DC_VIDEO
    sta VERA_DC_VIDEO
    // [2093] phi from display_frame_init_64::vera_layer1_show1 to display_frame_init_64::@1 [phi:display_frame_init_64::vera_layer1_show1->display_frame_init_64::@1]
    // display_frame_init_64::@1
    // textcolor(WHITE)
    // [2094] call textcolor
  // Layer 1 is the current text canvas.
    // [787] phi from display_frame_init_64::@1 to textcolor [phi:display_frame_init_64::@1->textcolor]
    // [787] phi textcolor::color#23 = WHITE [phi:display_frame_init_64::@1->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [2095] phi from display_frame_init_64::@1 to display_frame_init_64::@4 [phi:display_frame_init_64::@1->display_frame_init_64::@4]
    // display_frame_init_64::@4
    // bgcolor(BLUE)
    // [2096] call bgcolor
  // Default text color is white.
    // [792] phi from display_frame_init_64::@4 to bgcolor [phi:display_frame_init_64::@4->bgcolor]
    // [792] phi bgcolor::color#15 = BLUE [phi:display_frame_init_64::@4->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // [2097] phi from display_frame_init_64::@4 to display_frame_init_64::@5 [phi:display_frame_init_64::@4->display_frame_init_64::@5]
    // display_frame_init_64::@5
    // clrscr()
    // [2098] call clrscr
    // With a blue background.
    // cx16-conio.c won't compile scrolling code for this program with the underlying define, resulting in less code overhead!
    jsr clrscr
    // display_frame_init_64::@return
    // }
    // [2099] return 
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
    // [2101] call textcolor
    // [787] phi from display_frame_draw to textcolor [phi:display_frame_draw->textcolor]
    // [787] phi textcolor::color#23 = LIGHT_BLUE [phi:display_frame_draw->textcolor#0] -- vbuxx=vbuc1 
    ldx #LIGHT_BLUE
    jsr textcolor
    // [2102] phi from display_frame_draw to display_frame_draw::@1 [phi:display_frame_draw->display_frame_draw::@1]
    // display_frame_draw::@1
    // bgcolor(BLUE)
    // [2103] call bgcolor
    // [792] phi from display_frame_draw::@1 to bgcolor [phi:display_frame_draw::@1->bgcolor]
    // [792] phi bgcolor::color#15 = BLUE [phi:display_frame_draw::@1->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // [2104] phi from display_frame_draw::@1 to display_frame_draw::@2 [phi:display_frame_draw::@1->display_frame_draw::@2]
    // display_frame_draw::@2
    // clrscr()
    // [2105] call clrscr
    jsr clrscr
    // [2106] phi from display_frame_draw::@2 to display_frame_draw::@3 [phi:display_frame_draw::@2->display_frame_draw::@3]
    // display_frame_draw::@3
    // display_frame(0, 0, 67, 14)
    // [2107] call display_frame
    // [2993] phi from display_frame_draw::@3 to display_frame [phi:display_frame_draw::@3->display_frame]
    // [2993] phi display_frame::y#0 = 0 [phi:display_frame_draw::@3->display_frame#0] -- vbum1=vbuc1 
    lda #0
    sta display_frame.y
    // [2993] phi display_frame::y1#16 = $e [phi:display_frame_draw::@3->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2993] phi display_frame::x#0 = 0 [phi:display_frame_draw::@3->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [2993] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@3->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [2108] phi from display_frame_draw::@3 to display_frame_draw::@4 [phi:display_frame_draw::@3->display_frame_draw::@4]
    // display_frame_draw::@4
    // display_frame(0, 0, 67, 2)
    // [2109] call display_frame
    // [2993] phi from display_frame_draw::@4 to display_frame [phi:display_frame_draw::@4->display_frame]
    // [2993] phi display_frame::y#0 = 0 [phi:display_frame_draw::@4->display_frame#0] -- vbum1=vbuc1 
    lda #0
    sta display_frame.y
    // [2993] phi display_frame::y1#16 = 2 [phi:display_frame_draw::@4->display_frame#1] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y1
    // [2993] phi display_frame::x#0 = 0 [phi:display_frame_draw::@4->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [2993] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@4->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [2110] phi from display_frame_draw::@4 to display_frame_draw::@5 [phi:display_frame_draw::@4->display_frame_draw::@5]
    // display_frame_draw::@5
    // display_frame(0, 2, 67, 14)
    // [2111] call display_frame
    // [2993] phi from display_frame_draw::@5 to display_frame [phi:display_frame_draw::@5->display_frame]
    // [2993] phi display_frame::y#0 = 2 [phi:display_frame_draw::@5->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2993] phi display_frame::y1#16 = $e [phi:display_frame_draw::@5->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2993] phi display_frame::x#0 = 0 [phi:display_frame_draw::@5->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [2993] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@5->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [2112] phi from display_frame_draw::@5 to display_frame_draw::@6 [phi:display_frame_draw::@5->display_frame_draw::@6]
    // display_frame_draw::@6
    // display_frame(0, 2, 8, 14)
    // [2113] call display_frame
  // Chipset areas
    // [2993] phi from display_frame_draw::@6 to display_frame [phi:display_frame_draw::@6->display_frame]
    // [2993] phi display_frame::y#0 = 2 [phi:display_frame_draw::@6->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2993] phi display_frame::y1#16 = $e [phi:display_frame_draw::@6->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2993] phi display_frame::x#0 = 0 [phi:display_frame_draw::@6->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [2993] phi display_frame::x1#16 = 8 [phi:display_frame_draw::@6->display_frame#3] -- vbum1=vbuc1 
    lda #8
    sta display_frame.x1
    jsr display_frame
    // [2114] phi from display_frame_draw::@6 to display_frame_draw::@7 [phi:display_frame_draw::@6->display_frame_draw::@7]
    // display_frame_draw::@7
    // display_frame(8, 2, 19, 14)
    // [2115] call display_frame
    // [2993] phi from display_frame_draw::@7 to display_frame [phi:display_frame_draw::@7->display_frame]
    // [2993] phi display_frame::y#0 = 2 [phi:display_frame_draw::@7->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2993] phi display_frame::y1#16 = $e [phi:display_frame_draw::@7->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2993] phi display_frame::x#0 = 8 [phi:display_frame_draw::@7->display_frame#2] -- vbum1=vbuc1 
    lda #8
    sta display_frame.x
    // [2993] phi display_frame::x1#16 = $13 [phi:display_frame_draw::@7->display_frame#3] -- vbum1=vbuc1 
    lda #$13
    sta display_frame.x1
    jsr display_frame
    // [2116] phi from display_frame_draw::@7 to display_frame_draw::@8 [phi:display_frame_draw::@7->display_frame_draw::@8]
    // display_frame_draw::@8
    // display_frame(19, 2, 25, 14)
    // [2117] call display_frame
    // [2993] phi from display_frame_draw::@8 to display_frame [phi:display_frame_draw::@8->display_frame]
    // [2993] phi display_frame::y#0 = 2 [phi:display_frame_draw::@8->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2993] phi display_frame::y1#16 = $e [phi:display_frame_draw::@8->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2993] phi display_frame::x#0 = $13 [phi:display_frame_draw::@8->display_frame#2] -- vbum1=vbuc1 
    lda #$13
    sta display_frame.x
    // [2993] phi display_frame::x1#16 = $19 [phi:display_frame_draw::@8->display_frame#3] -- vbum1=vbuc1 
    lda #$19
    sta display_frame.x1
    jsr display_frame
    // [2118] phi from display_frame_draw::@8 to display_frame_draw::@9 [phi:display_frame_draw::@8->display_frame_draw::@9]
    // display_frame_draw::@9
    // display_frame(25, 2, 31, 14)
    // [2119] call display_frame
    // [2993] phi from display_frame_draw::@9 to display_frame [phi:display_frame_draw::@9->display_frame]
    // [2993] phi display_frame::y#0 = 2 [phi:display_frame_draw::@9->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2993] phi display_frame::y1#16 = $e [phi:display_frame_draw::@9->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2993] phi display_frame::x#0 = $19 [phi:display_frame_draw::@9->display_frame#2] -- vbum1=vbuc1 
    lda #$19
    sta display_frame.x
    // [2993] phi display_frame::x1#16 = $1f [phi:display_frame_draw::@9->display_frame#3] -- vbum1=vbuc1 
    lda #$1f
    sta display_frame.x1
    jsr display_frame
    // [2120] phi from display_frame_draw::@9 to display_frame_draw::@10 [phi:display_frame_draw::@9->display_frame_draw::@10]
    // display_frame_draw::@10
    // display_frame(31, 2, 37, 14)
    // [2121] call display_frame
    // [2993] phi from display_frame_draw::@10 to display_frame [phi:display_frame_draw::@10->display_frame]
    // [2993] phi display_frame::y#0 = 2 [phi:display_frame_draw::@10->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2993] phi display_frame::y1#16 = $e [phi:display_frame_draw::@10->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2993] phi display_frame::x#0 = $1f [phi:display_frame_draw::@10->display_frame#2] -- vbum1=vbuc1 
    lda #$1f
    sta display_frame.x
    // [2993] phi display_frame::x1#16 = $25 [phi:display_frame_draw::@10->display_frame#3] -- vbum1=vbuc1 
    lda #$25
    sta display_frame.x1
    jsr display_frame
    // [2122] phi from display_frame_draw::@10 to display_frame_draw::@11 [phi:display_frame_draw::@10->display_frame_draw::@11]
    // display_frame_draw::@11
    // display_frame(37, 2, 43, 14)
    // [2123] call display_frame
    // [2993] phi from display_frame_draw::@11 to display_frame [phi:display_frame_draw::@11->display_frame]
    // [2993] phi display_frame::y#0 = 2 [phi:display_frame_draw::@11->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2993] phi display_frame::y1#16 = $e [phi:display_frame_draw::@11->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2993] phi display_frame::x#0 = $25 [phi:display_frame_draw::@11->display_frame#2] -- vbum1=vbuc1 
    lda #$25
    sta display_frame.x
    // [2993] phi display_frame::x1#16 = $2b [phi:display_frame_draw::@11->display_frame#3] -- vbum1=vbuc1 
    lda #$2b
    sta display_frame.x1
    jsr display_frame
    // [2124] phi from display_frame_draw::@11 to display_frame_draw::@12 [phi:display_frame_draw::@11->display_frame_draw::@12]
    // display_frame_draw::@12
    // display_frame(43, 2, 49, 14)
    // [2125] call display_frame
    // [2993] phi from display_frame_draw::@12 to display_frame [phi:display_frame_draw::@12->display_frame]
    // [2993] phi display_frame::y#0 = 2 [phi:display_frame_draw::@12->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2993] phi display_frame::y1#16 = $e [phi:display_frame_draw::@12->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2993] phi display_frame::x#0 = $2b [phi:display_frame_draw::@12->display_frame#2] -- vbum1=vbuc1 
    lda #$2b
    sta display_frame.x
    // [2993] phi display_frame::x1#16 = $31 [phi:display_frame_draw::@12->display_frame#3] -- vbum1=vbuc1 
    lda #$31
    sta display_frame.x1
    jsr display_frame
    // [2126] phi from display_frame_draw::@12 to display_frame_draw::@13 [phi:display_frame_draw::@12->display_frame_draw::@13]
    // display_frame_draw::@13
    // display_frame(49, 2, 55, 14)
    // [2127] call display_frame
    // [2993] phi from display_frame_draw::@13 to display_frame [phi:display_frame_draw::@13->display_frame]
    // [2993] phi display_frame::y#0 = 2 [phi:display_frame_draw::@13->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2993] phi display_frame::y1#16 = $e [phi:display_frame_draw::@13->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2993] phi display_frame::x#0 = $31 [phi:display_frame_draw::@13->display_frame#2] -- vbum1=vbuc1 
    lda #$31
    sta display_frame.x
    // [2993] phi display_frame::x1#16 = $37 [phi:display_frame_draw::@13->display_frame#3] -- vbum1=vbuc1 
    lda #$37
    sta display_frame.x1
    jsr display_frame
    // [2128] phi from display_frame_draw::@13 to display_frame_draw::@14 [phi:display_frame_draw::@13->display_frame_draw::@14]
    // display_frame_draw::@14
    // display_frame(55, 2, 61, 14)
    // [2129] call display_frame
    // [2993] phi from display_frame_draw::@14 to display_frame [phi:display_frame_draw::@14->display_frame]
    // [2993] phi display_frame::y#0 = 2 [phi:display_frame_draw::@14->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2993] phi display_frame::y1#16 = $e [phi:display_frame_draw::@14->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2993] phi display_frame::x#0 = $37 [phi:display_frame_draw::@14->display_frame#2] -- vbum1=vbuc1 
    lda #$37
    sta display_frame.x
    // [2993] phi display_frame::x1#16 = $3d [phi:display_frame_draw::@14->display_frame#3] -- vbum1=vbuc1 
    lda #$3d
    sta display_frame.x1
    jsr display_frame
    // [2130] phi from display_frame_draw::@14 to display_frame_draw::@15 [phi:display_frame_draw::@14->display_frame_draw::@15]
    // display_frame_draw::@15
    // display_frame(61, 2, 67, 14)
    // [2131] call display_frame
    // [2993] phi from display_frame_draw::@15 to display_frame [phi:display_frame_draw::@15->display_frame]
    // [2993] phi display_frame::y#0 = 2 [phi:display_frame_draw::@15->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2993] phi display_frame::y1#16 = $e [phi:display_frame_draw::@15->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2993] phi display_frame::x#0 = $3d [phi:display_frame_draw::@15->display_frame#2] -- vbum1=vbuc1 
    lda #$3d
    sta display_frame.x
    // [2993] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@15->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [2132] phi from display_frame_draw::@15 to display_frame_draw::@16 [phi:display_frame_draw::@15->display_frame_draw::@16]
    // display_frame_draw::@16
    // display_frame(0, 14, 67, PROGRESS_Y-5)
    // [2133] call display_frame
  // Progress area
    // [2993] phi from display_frame_draw::@16 to display_frame [phi:display_frame_draw::@16->display_frame]
    // [2993] phi display_frame::y#0 = $e [phi:display_frame_draw::@16->display_frame#0] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y
    // [2993] phi display_frame::y1#16 = PROGRESS_Y-5 [phi:display_frame_draw::@16->display_frame#1] -- vbum1=vbuc1 
    lda #PROGRESS_Y-5
    sta display_frame.y1
    // [2993] phi display_frame::x#0 = 0 [phi:display_frame_draw::@16->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [2993] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@16->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [2134] phi from display_frame_draw::@16 to display_frame_draw::@17 [phi:display_frame_draw::@16->display_frame_draw::@17]
    // display_frame_draw::@17
    // display_frame(0, PROGRESS_Y-5, 67, PROGRESS_Y-2)
    // [2135] call display_frame
    // [2993] phi from display_frame_draw::@17 to display_frame [phi:display_frame_draw::@17->display_frame]
    // [2993] phi display_frame::y#0 = PROGRESS_Y-5 [phi:display_frame_draw::@17->display_frame#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-5
    sta display_frame.y
    // [2993] phi display_frame::y1#16 = PROGRESS_Y-2 [phi:display_frame_draw::@17->display_frame#1] -- vbum1=vbuc1 
    lda #PROGRESS_Y-2
    sta display_frame.y1
    // [2993] phi display_frame::x#0 = 0 [phi:display_frame_draw::@17->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [2993] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@17->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [2136] phi from display_frame_draw::@17 to display_frame_draw::@18 [phi:display_frame_draw::@17->display_frame_draw::@18]
    // display_frame_draw::@18
    // display_frame(0, PROGRESS_Y-2, 67, 49)
    // [2137] call display_frame
    // [2993] phi from display_frame_draw::@18 to display_frame [phi:display_frame_draw::@18->display_frame]
    // [2993] phi display_frame::y#0 = PROGRESS_Y-2 [phi:display_frame_draw::@18->display_frame#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-2
    sta display_frame.y
    // [2993] phi display_frame::y1#16 = $31 [phi:display_frame_draw::@18->display_frame#1] -- vbum1=vbuc1 
    lda #$31
    sta display_frame.y1
    // [2993] phi display_frame::x#0 = 0 [phi:display_frame_draw::@18->display_frame#2] -- vbum1=vbuc1 
    lda #0
    sta display_frame.x
    // [2993] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@18->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [2138] phi from display_frame_draw::@18 to display_frame_draw::@19 [phi:display_frame_draw::@18->display_frame_draw::@19]
    // display_frame_draw::@19
    // textcolor(WHITE)
    // [2139] call textcolor
    // [787] phi from display_frame_draw::@19 to textcolor [phi:display_frame_draw::@19->textcolor]
    // [787] phi textcolor::color#23 = WHITE [phi:display_frame_draw::@19->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // display_frame_draw::@return
    // }
    // [2140] return 
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
    // [2142] call gotoxy
    // [805] phi from display_frame_title to gotoxy [phi:display_frame_title->gotoxy]
    // [805] phi gotoxy::y#37 = 1 [phi:display_frame_title->gotoxy#0] -- vbum1=vbuc1 
    lda #1
    sta gotoxy.y
    // [805] phi gotoxy::x#37 = 2 [phi:display_frame_title->gotoxy#1] -- vbuyy=vbuc1 
    ldy #2
    jsr gotoxy
    // [2143] phi from display_frame_title to display_frame_title::@1 [phi:display_frame_title->display_frame_title::@1]
    // display_frame_title::@1
    // printf("%-65s", title_text)
    // [2144] call printf_string
    // [1419] phi from display_frame_title::@1 to printf_string [phi:display_frame_title::@1->printf_string]
    // [1419] phi printf_string::putc#26 = &cputc [phi:display_frame_title::@1->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1419] phi printf_string::str#26 = init::title_text [phi:display_frame_title::@1->printf_string#1] -- pbuz1=pbuc1 
    lda #<init.title_text
    sta.z printf_string.str
    lda #>init.title_text
    sta.z printf_string.str+1
    // [1419] phi printf_string::format_justify_left#26 = 1 [phi:display_frame_title::@1->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1419] phi printf_string::format_min_length#26 = $41 [phi:display_frame_title::@1->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_frame_title::@return
    // }
    // [2145] return 
    rts
}
  // cputsxy
// Move cursor and output a NUL-terminated string
// Same as "gotoxy (x, y); puts (s);"
// void cputsxy(__register(Y) char x, __register(X) char y, __zp($76) const char *s)
cputsxy: {
    .label s = $76
    // gotoxy(x, y)
    // [2147] gotoxy::x#1 = cputsxy::x#4
    // [2148] gotoxy::y#1 = cputsxy::y#4 -- vbum1=vbuxx 
    stx gotoxy.y
    // [2149] call gotoxy
    // [805] phi from cputsxy to gotoxy [phi:cputsxy->gotoxy]
    // [805] phi gotoxy::y#37 = gotoxy::y#1 [phi:cputsxy->gotoxy#0] -- register_copy 
    // [805] phi gotoxy::x#37 = gotoxy::x#1 [phi:cputsxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputsxy::@1
    // cputs(s)
    // [2150] cputs::s#1 = cputsxy::s#4 -- pbuz1=pbuz2 
    lda.z s
    sta.z cputs.s
    lda.z s+1
    sta.z cputs.s+1
    // [2151] call cputs
    // [3127] phi from cputsxy::@1 to cputs [phi:cputsxy::@1->cputs]
    jsr cputs
    // cputsxy::@return
    // }
    // [2152] return 
    rts
}
  // display_chip_vera
display_chip_vera: {
    // display_vera_led(GREY)
    // [2154] call display_vera_led
    // [2910] phi from display_chip_vera to display_vera_led [phi:display_chip_vera->display_vera_led]
    // [2910] phi display_vera_led::c#2 = GREY [phi:display_chip_vera->display_vera_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z display_vera_led.c
    jsr display_vera_led
    // [2155] phi from display_chip_vera to display_chip_vera::@1 [phi:display_chip_vera->display_chip_vera::@1]
    // display_chip_vera::@1
    // display_print_chip(CHIP_VERA_X, CHIP_VERA_Y+2, CHIP_VERA_W, "VERA     ")
    // [2156] call display_print_chip
    // [2175] phi from display_chip_vera::@1 to display_print_chip [phi:display_chip_vera::@1->display_print_chip]
    // [2175] phi display_print_chip::text#11 = display_chip_vera::text [phi:display_chip_vera::@1->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_print_chip.text_2
    lda #>text
    sta.z display_print_chip.text_2+1
    // [2175] phi display_print_chip::w#10 = 8 [phi:display_chip_vera::@1->display_print_chip#1] -- vbum1=vbuc1 
    lda #8
    sta display_print_chip.w
    // [2175] phi display_print_chip::x#10 = 9 [phi:display_chip_vera::@1->display_print_chip#2] -- vbuz1=vbuc1 
    lda #9
    sta.z display_print_chip.x
    jsr display_print_chip
    // display_chip_vera::@return
    // }
    // [2157] return 
    rts
  .segment Data
    text: .text "VERA     "
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
// void display_info_led(__register(Y) char x, __zp($af) char y, __register(X) char tc, char bc)
display_info_led: {
    .label y = $af
    // textcolor(tc)
    // [2159] textcolor::color#13 = display_info_led::tc#4
    // [2160] call textcolor
    // [787] phi from display_info_led to textcolor [phi:display_info_led->textcolor]
    // [787] phi textcolor::color#23 = textcolor::color#13 [phi:display_info_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [2161] phi from display_info_led to display_info_led::@1 [phi:display_info_led->display_info_led::@1]
    // display_info_led::@1
    // bgcolor(bc)
    // [2162] call bgcolor
    // [792] phi from display_info_led::@1 to bgcolor [phi:display_info_led::@1->bgcolor]
    // [792] phi bgcolor::color#15 = BLUE [phi:display_info_led::@1->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // display_info_led::@2
    // cputcxy(x, y, VERA_CHR_UR)
    // [2163] cputcxy::x#11 = display_info_led::x#4
    // [2164] cputcxy::y#11 = display_info_led::y#4 -- vbuaa=vbuz1 
    lda.z y
    // [2165] call cputcxy
    // [2273] phi from display_info_led::@2 to cputcxy [phi:display_info_led::@2->cputcxy]
    // [2273] phi cputcxy::c#17 = $7c [phi:display_info_led::@2->cputcxy#0] -- vbuxx=vbuc1 
    ldx #$7c
    // [2273] phi cputcxy::y#17 = cputcxy::y#11 [phi:display_info_led::@2->cputcxy#1] -- register_copy 
    // [2273] phi cputcxy::x#17 = cputcxy::x#11 [phi:display_info_led::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [2166] phi from display_info_led::@2 to display_info_led::@3 [phi:display_info_led::@2->display_info_led::@3]
    // display_info_led::@3
    // textcolor(WHITE)
    // [2167] call textcolor
    // [787] phi from display_info_led::@3 to textcolor [phi:display_info_led::@3->textcolor]
    // [787] phi textcolor::color#23 = WHITE [phi:display_info_led::@3->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // display_info_led::@return
    // }
    // [2168] return 
    rts
}
  // display_smc_led
/**
 * @brief Print SMC led above the SMC chip.
 * 
 * @param c Led color
 */
// void display_smc_led(__zp($e6) char c)
display_smc_led: {
    .label c = $e6
    // display_chip_led(CHIP_SMC_X+1, CHIP_SMC_Y, CHIP_SMC_W, c, BLUE)
    // [2170] display_chip_led::tc#0 = display_smc_led::c#2 -- vbuxx=vbuz1 
    ldx.z c
    // [2171] call display_chip_led
    // [3136] phi from display_smc_led to display_chip_led [phi:display_smc_led->display_chip_led]
    // [3136] phi display_chip_led::w#7 = 5 [phi:display_smc_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #5
    sta.z display_chip_led.w
    // [3136] phi display_chip_led::x#7 = 1+1 [phi:display_smc_led->display_chip_led#1] -- vbuz1=vbuc1 
    lda #1+1
    sta.z display_chip_led.x
    // [3136] phi display_chip_led::tc#3 = display_chip_led::tc#0 [phi:display_smc_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_smc_led::@1
    // display_info_led(INFO_X-2, INFO_Y, c, BLUE)
    // [2172] display_info_led::tc#0 = display_smc_led::c#2 -- vbuxx=vbuz1 
    ldx.z c
    // [2173] call display_info_led
    // [2158] phi from display_smc_led::@1 to display_info_led [phi:display_smc_led::@1->display_info_led]
    // [2158] phi display_info_led::y#4 = $11 [phi:display_smc_led::@1->display_info_led#0] -- vbuz1=vbuc1 
    lda #$11
    sta.z display_info_led.y
    // [2158] phi display_info_led::x#4 = 4-2 [phi:display_smc_led::@1->display_info_led#1] -- vbuyy=vbuc1 
    ldy #4-2
    // [2158] phi display_info_led::tc#4 = display_info_led::tc#0 [phi:display_smc_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_smc_led::@return
    // }
    // [2174] return 
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
// void display_print_chip(__zp($ba) char x, char y, __mem() char w, __zp($c3) char *text)
display_print_chip: {
    .label y = 3+2+1+1+1+1+1+1+1+1
    .label text = $c3
    .label text_1 = $ca
    .label x = $ba
    .label text_2 = $2a
    .label text_4 = $34
    .label text_5 = $6f
    .label text_6 = $67
    // display_chip_line(x, y++, w, *text++)
    // [2176] display_chip_line::x#0 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [2177] display_chip_line::w#0 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_line.w
    // [2178] display_chip_line::c#0 = *display_print_chip::text#11 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_2),y
    sta.z display_chip_line.c
    // [2179] call display_chip_line
    // [3154] phi from display_print_chip to display_chip_line [phi:display_print_chip->display_chip_line]
    // [3154] phi display_chip_line::c#15 = display_chip_line::c#0 [phi:display_print_chip->display_chip_line#0] -- register_copy 
    // [3154] phi display_chip_line::w#10 = display_chip_line::w#0 [phi:display_print_chip->display_chip_line#1] -- register_copy 
    // [3154] phi display_chip_line::y#16 = 3+2 [phi:display_print_chip->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2
    sta display_chip_line.y
    // [3154] phi display_chip_line::x#16 = display_chip_line::x#0 [phi:display_print_chip->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@1
    // display_chip_line(x, y++, w, *text++);
    // [2180] display_print_chip::text#0 = ++ display_print_chip::text#11 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_2
    adc #1
    sta.z text
    lda.z text_2+1
    adc #0
    sta.z text+1
    // display_chip_line(x, y++, w, *text++)
    // [2181] display_chip_line::x#1 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [2182] display_chip_line::w#1 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_line.w
    // [2183] display_chip_line::c#1 = *display_print_chip::text#0 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text),y
    sta.z display_chip_line.c
    // [2184] call display_chip_line
    // [3154] phi from display_print_chip::@1 to display_chip_line [phi:display_print_chip::@1->display_chip_line]
    // [3154] phi display_chip_line::c#15 = display_chip_line::c#1 [phi:display_print_chip::@1->display_chip_line#0] -- register_copy 
    // [3154] phi display_chip_line::w#10 = display_chip_line::w#1 [phi:display_print_chip::@1->display_chip_line#1] -- register_copy 
    // [3154] phi display_chip_line::y#16 = ++3+2 [phi:display_print_chip::@1->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1
    sta display_chip_line.y
    // [3154] phi display_chip_line::x#16 = display_chip_line::x#1 [phi:display_print_chip::@1->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@2
    // display_chip_line(x, y++, w, *text++);
    // [2185] display_print_chip::text#1 = ++ display_print_chip::text#0 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text
    adc #1
    sta.z text_1
    lda.z text+1
    adc #0
    sta.z text_1+1
    // display_chip_line(x, y++, w, *text++)
    // [2186] display_chip_line::x#2 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [2187] display_chip_line::w#2 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_line.w
    // [2188] display_chip_line::c#2 = *display_print_chip::text#1 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_1),y
    sta.z display_chip_line.c
    // [2189] call display_chip_line
    // [3154] phi from display_print_chip::@2 to display_chip_line [phi:display_print_chip::@2->display_chip_line]
    // [3154] phi display_chip_line::c#15 = display_chip_line::c#2 [phi:display_print_chip::@2->display_chip_line#0] -- register_copy 
    // [3154] phi display_chip_line::w#10 = display_chip_line::w#2 [phi:display_print_chip::@2->display_chip_line#1] -- register_copy 
    // [3154] phi display_chip_line::y#16 = ++++3+2 [phi:display_print_chip::@2->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1
    sta display_chip_line.y
    // [3154] phi display_chip_line::x#16 = display_chip_line::x#2 [phi:display_print_chip::@2->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@3
    // display_chip_line(x, y++, w, *text++);
    // [2190] display_print_chip::text#15 = ++ display_print_chip::text#1 -- pbum1=_inc_pbuz2 
    clc
    lda.z text_1
    adc #1
    sta text_3
    lda.z text_1+1
    adc #0
    sta text_3+1
    // display_chip_line(x, y++, w, *text++)
    // [2191] display_chip_line::x#3 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [2192] display_chip_line::w#3 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_line.w
    // [2193] display_chip_line::c#3 = *display_print_chip::text#15 -- vbuz1=_deref_pbum2 
    ldy text_3
    sty.z $fe
    ldy text_3+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta.z display_chip_line.c
    // [2194] call display_chip_line
    // [3154] phi from display_print_chip::@3 to display_chip_line [phi:display_print_chip::@3->display_chip_line]
    // [3154] phi display_chip_line::c#15 = display_chip_line::c#3 [phi:display_print_chip::@3->display_chip_line#0] -- register_copy 
    // [3154] phi display_chip_line::w#10 = display_chip_line::w#3 [phi:display_print_chip::@3->display_chip_line#1] -- register_copy 
    // [3154] phi display_chip_line::y#16 = ++++++3+2 [phi:display_print_chip::@3->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1
    sta display_chip_line.y
    // [3154] phi display_chip_line::x#16 = display_chip_line::x#3 [phi:display_print_chip::@3->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@4
    // display_chip_line(x, y++, w, *text++);
    // [2195] display_print_chip::text#16 = ++ display_print_chip::text#15 -- pbuz1=_inc_pbum2 
    clc
    lda text_3
    adc #1
    sta.z text_4
    lda text_3+1
    adc #0
    sta.z text_4+1
    // display_chip_line(x, y++, w, *text++)
    // [2196] display_chip_line::x#4 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [2197] display_chip_line::w#4 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_line.w
    // [2198] display_chip_line::c#4 = *display_print_chip::text#16 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_4),y
    sta.z display_chip_line.c
    // [2199] call display_chip_line
    // [3154] phi from display_print_chip::@4 to display_chip_line [phi:display_print_chip::@4->display_chip_line]
    // [3154] phi display_chip_line::c#15 = display_chip_line::c#4 [phi:display_print_chip::@4->display_chip_line#0] -- register_copy 
    // [3154] phi display_chip_line::w#10 = display_chip_line::w#4 [phi:display_print_chip::@4->display_chip_line#1] -- register_copy 
    // [3154] phi display_chip_line::y#16 = ++++++++3+2 [phi:display_print_chip::@4->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1
    sta display_chip_line.y
    // [3154] phi display_chip_line::x#16 = display_chip_line::x#4 [phi:display_print_chip::@4->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@5
    // display_chip_line(x, y++, w, *text++);
    // [2200] display_print_chip::text#17 = ++ display_print_chip::text#16 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_4
    adc #1
    sta.z text_5
    lda.z text_4+1
    adc #0
    sta.z text_5+1
    // display_chip_line(x, y++, w, *text++)
    // [2201] display_chip_line::x#5 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [2202] display_chip_line::w#5 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_line.w
    // [2203] display_chip_line::c#5 = *display_print_chip::text#17 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_5),y
    sta.z display_chip_line.c
    // [2204] call display_chip_line
    // [3154] phi from display_print_chip::@5 to display_chip_line [phi:display_print_chip::@5->display_chip_line]
    // [3154] phi display_chip_line::c#15 = display_chip_line::c#5 [phi:display_print_chip::@5->display_chip_line#0] -- register_copy 
    // [3154] phi display_chip_line::w#10 = display_chip_line::w#5 [phi:display_print_chip::@5->display_chip_line#1] -- register_copy 
    // [3154] phi display_chip_line::y#16 = ++++++++++3+2 [phi:display_print_chip::@5->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1+1
    sta display_chip_line.y
    // [3154] phi display_chip_line::x#16 = display_chip_line::x#5 [phi:display_print_chip::@5->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@6
    // display_chip_line(x, y++, w, *text++);
    // [2205] display_print_chip::text#18 = ++ display_print_chip::text#17 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_5
    adc #1
    sta.z text_6
    lda.z text_5+1
    adc #0
    sta.z text_6+1
    // display_chip_line(x, y++, w, *text++)
    // [2206] display_chip_line::x#6 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [2207] display_chip_line::w#6 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_line.w
    // [2208] display_chip_line::c#6 = *display_print_chip::text#18 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta.z display_chip_line.c
    // [2209] call display_chip_line
    // [3154] phi from display_print_chip::@6 to display_chip_line [phi:display_print_chip::@6->display_chip_line]
    // [3154] phi display_chip_line::c#15 = display_chip_line::c#6 [phi:display_print_chip::@6->display_chip_line#0] -- register_copy 
    // [3154] phi display_chip_line::w#10 = display_chip_line::w#6 [phi:display_print_chip::@6->display_chip_line#1] -- register_copy 
    // [3154] phi display_chip_line::y#16 = ++++++++++++3+2 [phi:display_print_chip::@6->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1+1+1
    sta display_chip_line.y
    // [3154] phi display_chip_line::x#16 = display_chip_line::x#6 [phi:display_print_chip::@6->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@7
    // display_chip_line(x, y++, w, *text++);
    // [2210] display_print_chip::text#19 = ++ display_print_chip::text#18 -- pbuz1=_inc_pbuz1 
    inc.z text_6
    bne !+
    inc.z text_6+1
  !:
    // display_chip_line(x, y++, w, *text++)
    // [2211] display_chip_line::x#7 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [2212] display_chip_line::w#7 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_line.w
    // [2213] display_chip_line::c#7 = *display_print_chip::text#19 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_6),y
    sta.z display_chip_line.c
    // [2214] call display_chip_line
    // [3154] phi from display_print_chip::@7 to display_chip_line [phi:display_print_chip::@7->display_chip_line]
    // [3154] phi display_chip_line::c#15 = display_chip_line::c#7 [phi:display_print_chip::@7->display_chip_line#0] -- register_copy 
    // [3154] phi display_chip_line::w#10 = display_chip_line::w#7 [phi:display_print_chip::@7->display_chip_line#1] -- register_copy 
    // [3154] phi display_chip_line::y#16 = ++++++++++++++3+2 [phi:display_print_chip::@7->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1+1+1+1
    sta display_chip_line.y
    // [3154] phi display_chip_line::x#16 = display_chip_line::x#7 [phi:display_print_chip::@7->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@8
    // display_chip_end(x, y++, w)
    // [2215] display_chip_end::x#0 = display_print_chip::x#10 -- vbuxx=vbuz1 
    ldx.z x
    // [2216] display_chip_end::w#0 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_end.w
    // [2217] call display_chip_end
    jsr display_chip_end
    // display_print_chip::@return
    // }
    // [2218] return 
    rts
  .segment Data
    text_3: .word 0
    .label w = display_info_rom.display_info_rom__16
}
.segment Code
  // wherex
// Return the x position of the cursor
wherex: {
    // return __conio.cursor_x;
    // [2219] wherex::return#0 = *((char *)&__conio) -- vbuaa=_deref_pbuc1 
    lda __conio
    // wherex::@return
    // }
    // [2220] return 
    rts
}
  // wherey
// Return the y position of the cursor
wherey: {
    // return __conio.cursor_y;
    // [2221] wherey::return#0 = *((char *)&__conio+1) -- vbuaa=_deref_pbuc1 
    lda __conio+1
    // wherey::@return
    // }
    // [2222] return 
    rts
}
.segment CodeVera
  // w25q16_detect
w25q16_detect: {
    // spi_get_jedec()
    // [2224] call spi_get_jedec
  // This conditional compilation ensures that only the detection interpretation happens if it is switched on.
    // [3215] phi from w25q16_detect to spi_get_jedec [phi:w25q16_detect->spi_get_jedec]
    jsr spi_get_jedec
    // [2225] phi from w25q16_detect to w25q16_detect::@1 [phi:w25q16_detect->w25q16_detect::@1]
    // w25q16_detect::@1
    // spi_deselect()
    // [2226] call spi_deselect
    jsr spi_deselect
    // w25q16_detect::@return
    // }
    // [2227] return 
    rts
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
// void rom_unlock(__zp($42) unsigned long address, __zp($50) char unlock_code)
rom_unlock: {
    .label chip_address = $3c
    .label address = $42
    .label unlock_code = $50
    // unsigned long chip_address = address & ROM_CHIP_MASK
    // [2229] rom_unlock::chip_address#0 = rom_unlock::address#5 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [2230] rom_write_byte::address#0 = rom_unlock::chip_address#0 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [2231] call rom_write_byte
  // This is a very important operation...
    // [3232] phi from rom_unlock to rom_write_byte [phi:rom_unlock->rom_write_byte]
    // [3232] phi rom_write_byte::value#10 = $aa [phi:rom_unlock->rom_write_byte#0] -- vbuyy=vbuc1 
    ldy #$aa
    // [3232] phi rom_write_byte::address#4 = rom_write_byte::address#0 [phi:rom_unlock->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@1
    // rom_write_byte(chip_address + 0x02AAA, 0x55)
    // [2232] rom_write_byte::address#1 = rom_unlock::chip_address#0 + $2aaa -- vduz1=vduz2_plus_vwuc1 
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
    // [2233] call rom_write_byte
    // [3232] phi from rom_unlock::@1 to rom_write_byte [phi:rom_unlock::@1->rom_write_byte]
    // [3232] phi rom_write_byte::value#10 = $55 [phi:rom_unlock::@1->rom_write_byte#0] -- vbuyy=vbuc1 
    ldy #$55
    // [3232] phi rom_write_byte::address#4 = rom_write_byte::address#1 [phi:rom_unlock::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@2
    // rom_write_byte(address, unlock_code)
    // [2234] rom_write_byte::address#2 = rom_unlock::address#5 -- vduz1=vduz2 
    lda.z address
    sta.z rom_write_byte.address
    lda.z address+1
    sta.z rom_write_byte.address+1
    lda.z address+2
    sta.z rom_write_byte.address+2
    lda.z address+3
    sta.z rom_write_byte.address+3
    // [2235] rom_write_byte::value#2 = rom_unlock::unlock_code#5 -- vbuyy=vbuz1 
    ldy.z unlock_code
    // [2236] call rom_write_byte
    // [3232] phi from rom_unlock::@2 to rom_write_byte [phi:rom_unlock::@2->rom_write_byte]
    // [3232] phi rom_write_byte::value#10 = rom_write_byte::value#2 [phi:rom_unlock::@2->rom_write_byte#0] -- register_copy 
    // [3232] phi rom_write_byte::address#4 = rom_write_byte::address#2 [phi:rom_unlock::@2->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@return
    // }
    // [2237] return 
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
// __register(A) char rom_read_byte(__mem() unsigned long address)
rom_read_byte: {
    // rom_read_byte::rom_bank1
    // BYTE2(address)
    // [2239] rom_read_byte::rom_bank1_$0 = byte2  rom_read_byte::address#2 -- vbuaa=_byte2_vdum1 
    lda address+2
    // BYTE1(address)
    // [2240] rom_read_byte::rom_bank1_$1 = byte1  rom_read_byte::address#2 -- vbuxx=_byte1_vdum1 
    ldx address+1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2241] rom_read_byte::rom_bank1_$2 = rom_read_byte::rom_bank1_$0 w= rom_read_byte::rom_bank1_$1 -- vwum1=vbuaa_word_vbuxx 
    sta rom_bank1_rom_read_byte__2+1
    stx rom_bank1_rom_read_byte__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2242] rom_read_byte::rom_bank1_bank_unshifted#0 = rom_read_byte::rom_bank1_$2 << 2 -- vwum1=vwum1_rol_2 
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2243] rom_read_byte::rom_bank1_return#0 = byte1  rom_read_byte::rom_bank1_bank_unshifted#0 -- vbuxx=_byte1_vwum1 
    ldx rom_bank1_bank_unshifted+1
    // rom_read_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2244] rom_read_byte::rom_ptr1_$2 = (unsigned int)rom_read_byte::address#2 -- vwum1=_word_vdum2 
    lda address
    sta rom_ptr1_rom_read_byte__2
    lda address+1
    sta rom_ptr1_rom_read_byte__2+1
    // [2245] rom_read_byte::rom_ptr1_$0 = rom_read_byte::rom_ptr1_$2 & $3fff -- vwum1=vwum1_band_vwuc1 
    lda rom_ptr1_rom_read_byte__0
    and #<$3fff
    sta rom_ptr1_rom_read_byte__0
    lda rom_ptr1_rom_read_byte__0+1
    and #>$3fff
    sta rom_ptr1_rom_read_byte__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2246] rom_read_byte::rom_ptr1_return#0 = rom_read_byte::rom_ptr1_$0 + $c000 -- vwum1=vwum1_plus_vwuc1 
    lda rom_ptr1_return
    clc
    adc #<$c000
    sta rom_ptr1_return
    lda rom_ptr1_return+1
    adc #>$c000
    sta rom_ptr1_return+1
    // rom_read_byte::bank_set_brom1
    // BROM = bank
    // [2247] BROM = rom_read_byte::rom_bank1_return#0 -- vbuz1=vbuxx 
    stx.z BROM
    // rom_read_byte::@1
    // return *ptr_rom;
    // [2248] rom_read_byte::return#0 = *((char *)rom_read_byte::rom_ptr1_return#0) -- vbuaa=_deref_pbum1 
    ldy rom_ptr1_return
    sty.z $fe
    tay
    sty.z $ff
    ldy #0
    lda ($fe),y
    // rom_read_byte::@return
    // }
    // [2249] return 
    rts
  .segment Data
    rom_bank1_rom_read_byte__2: .word 0
    .label rom_ptr1_rom_read_byte__0 = rom_ptr1_rom_read_byte__2
    rom_ptr1_rom_read_byte__2: .word 0
    .label rom_bank1_bank_unshifted = rom_bank1_rom_read_byte__2
    .label rom_ptr1_return = rom_ptr1_rom_read_byte__2
    address: .dword 0
}
.segment Code
  // strcat
// Concatenates the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcat(char *destination, __zp($2a) char *source)
strcat: {
    .label strcat__0 = $bb
    .label dst = $bb
    .label src = $2a
    .label source = $2a
    // strlen(destination)
    // [2251] call strlen
    // [2555] phi from strcat to strlen [phi:strcat->strlen]
    // [2555] phi strlen::str#8 = display_chip_rom::rom [phi:strcat->strlen#0] -- pbuz1=pbuc1 
    lda #<display_chip_rom.rom
    sta.z strlen.str
    lda #>display_chip_rom.rom
    sta.z strlen.str+1
    jsr strlen
    // strlen(destination)
    // [2252] strlen::return#0 = strlen::len#2
    // strcat::@4
    // [2253] strcat::$0 = strlen::return#0 -- vwuz1=vwum2 
    lda strlen.return
    sta.z strcat__0
    lda strlen.return+1
    sta.z strcat__0+1
    // char* dst = destination + strlen(destination)
    // [2254] strcat::dst#0 = display_chip_rom::rom + strcat::$0 -- pbuz1=pbuc1_plus_vwuz1 
    lda.z dst
    clc
    adc #<display_chip_rom.rom
    sta.z dst
    lda.z dst+1
    adc #>display_chip_rom.rom
    sta.z dst+1
    // [2255] phi from strcat::@2 strcat::@4 to strcat::@1 [phi:strcat::@2/strcat::@4->strcat::@1]
    // [2255] phi strcat::dst#2 = strcat::dst#1 [phi:strcat::@2/strcat::@4->strcat::@1#0] -- register_copy 
    // [2255] phi strcat::src#2 = strcat::src#1 [phi:strcat::@2/strcat::@4->strcat::@1#1] -- register_copy 
    // strcat::@1
  __b1:
    // while(*src)
    // [2256] if(0!=*strcat::src#2) goto strcat::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcat::@3
    // *dst = 0
    // [2257] *strcat::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcat::@return
    // }
    // [2258] return 
    rts
    // strcat::@2
  __b2:
    // *dst++ = *src++
    // [2259] *strcat::dst#2 = *strcat::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [2260] strcat::dst#1 = ++ strcat::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [2261] strcat::src#1 = ++ strcat::src#2 -- pbuz1=_inc_pbuz1 
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
// void display_rom_led(__zp($cd) char chip, __zp($d2) char c)
display_rom_led: {
    .label chip = $cd
    .label c = $d2
    // chip*6
    // [2263] display_rom_led::$7 = display_rom_led::chip#2 << 1 -- vbuaa=vbuz1_rol_1 
    lda.z chip
    asl
    // [2264] display_rom_led::$8 = display_rom_led::$7 + display_rom_led::chip#2 -- vbuaa=vbuaa_plus_vbuz1 
    clc
    adc.z chip
    // CHIP_ROM_X+chip*6
    // [2265] display_rom_led::$0 = display_rom_led::$8 << 1 -- vbuaa=vbuaa_rol_1 
    asl
    // display_chip_led(CHIP_ROM_X+chip*6+1, CHIP_ROM_Y, CHIP_ROM_W, c, BLUE)
    // [2266] display_chip_led::x#3 = display_rom_led::$0 + $14+1 -- vbuz1=vbuaa_plus_vbuc1 
    clc
    adc #$14+1
    sta.z display_chip_led.x
    // [2267] display_chip_led::tc#2 = display_rom_led::c#2 -- vbuxx=vbuz1 
    ldx.z c
    // [2268] call display_chip_led
    // [3136] phi from display_rom_led to display_chip_led [phi:display_rom_led->display_chip_led]
    // [3136] phi display_chip_led::w#7 = 3 [phi:display_rom_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #3
    sta.z display_chip_led.w
    // [3136] phi display_chip_led::x#7 = display_chip_led::x#3 [phi:display_rom_led->display_chip_led#1] -- register_copy 
    // [3136] phi display_chip_led::tc#3 = display_chip_led::tc#2 [phi:display_rom_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_rom_led::@1
    // display_info_led(INFO_X-2, INFO_Y+chip+2, c, BLUE)
    // [2269] display_info_led::y#2 = display_rom_led::chip#2 + $11+2 -- vbuz1=vbuz2_plus_vbuc1 
    lda #$11+2
    clc
    adc.z chip
    sta.z display_info_led.y
    // [2270] display_info_led::tc#2 = display_rom_led::c#2 -- vbuxx=vbuz1 
    ldx.z c
    // [2271] call display_info_led
    // [2158] phi from display_rom_led::@1 to display_info_led [phi:display_rom_led::@1->display_info_led]
    // [2158] phi display_info_led::y#4 = display_info_led::y#2 [phi:display_rom_led::@1->display_info_led#0] -- register_copy 
    // [2158] phi display_info_led::x#4 = 4-2 [phi:display_rom_led::@1->display_info_led#1] -- vbuyy=vbuc1 
    ldy #4-2
    // [2158] phi display_info_led::tc#4 = display_info_led::tc#2 [phi:display_rom_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_rom_led::@return
    // }
    // [2272] return 
    rts
}
  // cputcxy
// Move cursor and output one character
// Same as "gotoxy (x, y); cputc (c);"
// void cputcxy(__register(Y) char x, __register(A) char y, __register(X) char c)
cputcxy: {
    // gotoxy(x, y)
    // [2274] gotoxy::x#0 = cputcxy::x#17
    // [2275] gotoxy::y#0 = cputcxy::y#17 -- vbum1=vbuaa 
    sta gotoxy.y
    // [2276] call gotoxy
    // [805] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [805] phi gotoxy::y#37 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [805] phi gotoxy::x#37 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [2277] stackpush(char) = cputcxy::c#17 -- _stackpushbyte_=vbuxx 
    txa
    pha
    // [2278] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [2280] return 
    rts
}
.segment CodeVera
  // w25q16_read
// __zp($a9) unsigned long w25q16_read(__mem() char info_status)
w25q16_read: {
    .const bank_set_brom1_bank = 0
    .label fp = $2e
    .label return = $a9
    .label vera_package_read = $25
    .label vera_file_size = $a9
    // w25q16_read::bank_set_bram1
    // BRAM = bank
    // [2282] BRAM = 1 -- vbuz1=vbuc1 
    lda #1
    sta.z BRAM
    // w25q16_read::@16
    // if(info_status == STATUS_READING)
    // [2283] if(w25q16_read::info_status#12==STATUS_READING) goto w25q16_read::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #STATUS_READING
    cmp info_status
    beq __b1
    // [2285] phi from w25q16_read::@16 to w25q16_read::@2 [phi:w25q16_read::@16->w25q16_read::@2]
    // [2285] phi w25q16_read::vera_bram_bank#14 = 0 [phi:w25q16_read::@16->w25q16_read::@2#0] -- vbum1=vbuc1 
    lda #0
    sta vera_bram_bank
    // [2285] phi w25q16_read::vera_action_text#10 = smc_action_text#2 [phi:w25q16_read::@16->w25q16_read::@2#1] -- pbum1=pbuc1 
    lda #<smc_action_text_1
    sta vera_action_text
    lda #>smc_action_text_1
    sta vera_action_text+1
    jmp __b2
    // [2284] phi from w25q16_read::@16 to w25q16_read::@1 [phi:w25q16_read::@16->w25q16_read::@1]
    // w25q16_read::@1
  __b1:
    // [2285] phi from w25q16_read::@1 to w25q16_read::@2 [phi:w25q16_read::@1->w25q16_read::@2]
    // [2285] phi w25q16_read::vera_bram_bank#14 = 1 [phi:w25q16_read::@1->w25q16_read::@2#0] -- vbum1=vbuc1 
    lda #1
    sta vera_bram_bank
    // [2285] phi w25q16_read::vera_action_text#10 = smc_action_text#1 [phi:w25q16_read::@1->w25q16_read::@2#1] -- pbum1=pbuc1 
    lda #<smc_action_text
    sta vera_action_text
    lda #>smc_action_text
    sta vera_action_text+1
    // w25q16_read::@2
  __b2:
    // w25q16_read::bank_set_brom1
    // BROM = bank
    // [2286] BROM = w25q16_read::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [2287] phi from w25q16_read::bank_set_brom1 to w25q16_read::@17 [phi:w25q16_read::bank_set_brom1->w25q16_read::@17]
    // w25q16_read::@17
    // display_action_text("Opening VERA.BIN from SD card ...")
    // [2288] call display_action_text
    // [1200] phi from w25q16_read::@17 to display_action_text [phi:w25q16_read::@17->display_action_text]
    // [1200] phi display_action_text::info_text#25 = w25q16_read::info_text [phi:w25q16_read::@17->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [2289] phi from w25q16_read::@17 to w25q16_read::@19 [phi:w25q16_read::@17->w25q16_read::@19]
    // w25q16_read::@19
    // FILE *fp = fopen("VERA.BIN", "r")
    // [2290] call fopen
    // [2573] phi from w25q16_read::@19 to fopen [phi:w25q16_read::@19->fopen]
    // [2573] phi __errno#474 = __errno#105 [phi:w25q16_read::@19->fopen#0] -- register_copy 
    // [2573] phi fopen::pathtoken#0 = w25q16_read::path [phi:w25q16_read::@19->fopen#1] -- pbuz1=pbuc1 
    lda #<path
    sta.z fopen.pathtoken
    lda #>path
    sta.z fopen.pathtoken+1
    // [2573] phi __stdio_filecount#27 = __stdio_filecount#100 [phi:w25q16_read::@19->fopen#2] -- register_copy 
    jsr fopen
    // FILE *fp = fopen("VERA.BIN", "r")
    // [2291] fopen::return#5 = fopen::return#2
    // w25q16_read::@20
    // [2292] w25q16_read::fp#0 = fopen::return#5 -- pssz1=pssz2 
    lda.z fopen.return
    sta.z fp
    lda.z fopen.return+1
    sta.z fp+1
    // if (fp)
    // [2293] if((struct $2 *)0==w25q16_read::fp#0) goto w25q16_read::@3 -- pssc1_eq_pssz1_then_la1 
    lda.z fp
    cmp #<0
    bne !+
    lda.z fp+1
    cmp #>0
    beq __b4
  !:
    // [2294] phi from w25q16_read::@20 to w25q16_read::@4 [phi:w25q16_read::@20->w25q16_read::@4]
    // w25q16_read::@4
    // gotoxy(x, y)
    // [2295] call gotoxy
    // [805] phi from w25q16_read::@4 to gotoxy [phi:w25q16_read::@4->gotoxy]
    // [805] phi gotoxy::y#37 = PROGRESS_Y [phi:w25q16_read::@4->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [805] phi gotoxy::x#37 = PROGRESS_X [phi:w25q16_read::@4->gotoxy#1] -- vbuyy=vbuc1 
    ldy #PROGRESS_X
    jsr gotoxy
    // [2296] phi from w25q16_read::@4 to w25q16_read::@5 [phi:w25q16_read::@4->w25q16_read::@5]
    // [2296] phi w25q16_read::y#11 = PROGRESS_Y [phi:w25q16_read::@4->w25q16_read::@5#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [2296] phi w25q16_read::progress_row_current#10 = 0 [phi:w25q16_read::@4->w25q16_read::@5#1] -- vwum1=vwuc1 
    lda #<0
    sta progress_row_current
    sta progress_row_current+1
    // [2296] phi w25q16_read::vera_bram_ptr#13 = (char *)$a000 [phi:w25q16_read::@4->w25q16_read::@5#2] -- pbum1=pbuc1 
    lda #<$a000
    sta vera_bram_ptr
    lda #>$a000
    sta vera_bram_ptr+1
    // [2296] phi w25q16_read::vera_bram_bank#10 = w25q16_read::vera_bram_bank#14 [phi:w25q16_read::@4->w25q16_read::@5#3] -- register_copy 
    // [2296] phi w25q16_read::vera_file_size#11 = 0 [phi:w25q16_read::@4->w25q16_read::@5#4] -- vduz1=vduc1 
    lda #<0
    sta.z vera_file_size
    sta.z vera_file_size+1
    lda #<0>>$10
    sta.z vera_file_size+2
    lda #>0>>$10
    sta.z vera_file_size+3
    // w25q16_read::@5
  __b5:
    // while (vera_file_size < vera_size)
    // [2297] if(w25q16_read::vera_file_size#11<vera_size) goto w25q16_read::@6 -- vduz1_lt_vduc1_then_la1 
    lda.z vera_file_size+3
    cmp #>vera_size>>$10
    bcc __b6
    bne !+
    lda.z vera_file_size+2
    cmp #<vera_size>>$10
    bcc __b6
    bne !+
    lda.z vera_file_size+1
    cmp #>vera_size
    bcc __b6
    bne !+
    lda.z vera_file_size
    cmp #<vera_size
    bcc __b6
  !:
    // w25q16_read::@9
  __b9:
    // fclose(fp)
    // [2298] fclose::stream#2 = w25q16_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fclose.stream
    lda.z fp+1
    sta.z fclose.stream+1
    // [2299] call fclose
    // [2654] phi from w25q16_read::@9 to fclose [phi:w25q16_read::@9->fclose]
    // [2654] phi fclose::stream#3 = fclose::stream#2 [phi:w25q16_read::@9->fclose#0] -- register_copy 
    jsr fclose
    // [2300] phi from w25q16_read::@9 to w25q16_read::@3 [phi:w25q16_read::@9->w25q16_read::@3]
    // [2300] phi __stdio_filecount#12 = __stdio_filecount#2 [phi:w25q16_read::@9->w25q16_read::@3#0] -- register_copy 
    // [2300] phi w25q16_read::return#0 = w25q16_read::vera_file_size#11 [phi:w25q16_read::@9->w25q16_read::@3#1] -- register_copy 
    rts
    // [2300] phi from w25q16_read::@20 to w25q16_read::@3 [phi:w25q16_read::@20->w25q16_read::@3]
  __b4:
    // [2300] phi __stdio_filecount#12 = __stdio_filecount#1 [phi:w25q16_read::@20->w25q16_read::@3#0] -- register_copy 
    // [2300] phi w25q16_read::return#0 = 0 [phi:w25q16_read::@20->w25q16_read::@3#1] -- vduz1=vduc1 
    lda #<0
    sta.z return
    sta.z return+1
    lda #<0>>$10
    sta.z return+2
    lda #>0>>$10
    sta.z return+3
    // w25q16_read::@3
    // w25q16_read::@return
    // }
    // [2301] return 
    rts
    // w25q16_read::@6
  __b6:
    // if(info_status == STATUS_CHECKING)
    // [2302] if(w25q16_read::info_status#12!=STATUS_CHECKING) goto w25q16_read::@23 -- vbum1_neq_vbuc1_then_la1 
    lda #STATUS_CHECKING
    cmp info_status
    bne __b7
    // [2304] phi from w25q16_read::@6 to w25q16_read::@7 [phi:w25q16_read::@6->w25q16_read::@7]
    // [2304] phi w25q16_read::vera_bram_ptr#10 = (char *) 1024 [phi:w25q16_read::@6->w25q16_read::@7#0] -- pbum1=pbuc1 
    lda #<$400
    sta vera_bram_ptr
    lda #>$400
    sta vera_bram_ptr+1
    // [2303] phi from w25q16_read::@6 to w25q16_read::@23 [phi:w25q16_read::@6->w25q16_read::@23]
    // w25q16_read::@23
    // [2304] phi from w25q16_read::@23 to w25q16_read::@7 [phi:w25q16_read::@23->w25q16_read::@7]
    // [2304] phi w25q16_read::vera_bram_ptr#10 = w25q16_read::vera_bram_ptr#13 [phi:w25q16_read::@23->w25q16_read::@7#0] -- register_copy 
    // w25q16_read::@7
  __b7:
    // display_action_text_reading(vera_action_text, "VERA.BIN", vera_file_size, vera_size, vera_bram_bank, vera_bram_ptr)
    // [2305] display_action_text_reading::action#2 = w25q16_read::vera_action_text#10 -- pbuz1=pbum2 
    lda vera_action_text
    sta.z display_action_text_reading.action
    lda vera_action_text+1
    sta.z display_action_text_reading.action+1
    // [2306] display_action_text_reading::bytes#2 = w25q16_read::vera_file_size#11 -- vduz1=vduz2 
    lda.z vera_file_size
    sta.z display_action_text_reading.bytes
    lda.z vera_file_size+1
    sta.z display_action_text_reading.bytes+1
    lda.z vera_file_size+2
    sta.z display_action_text_reading.bytes+2
    lda.z vera_file_size+3
    sta.z display_action_text_reading.bytes+3
    // [2307] display_action_text_reading::bram_bank#2 = w25q16_read::vera_bram_bank#10 -- vbuz1=vbum2 
    lda vera_bram_bank
    sta.z display_action_text_reading.bram_bank
    // [2308] display_action_text_reading::bram_ptr#2 = w25q16_read::vera_bram_ptr#10 -- pbuz1=pbum2 
    lda vera_bram_ptr
    sta.z display_action_text_reading.bram_ptr
    lda vera_bram_ptr+1
    sta.z display_action_text_reading.bram_ptr+1
    // [2309] call display_action_text_reading
    // [2683] phi from w25q16_read::@7 to display_action_text_reading [phi:w25q16_read::@7->display_action_text_reading]
    // [2683] phi display_action_text_reading::bram_ptr#10 = display_action_text_reading::bram_ptr#2 [phi:w25q16_read::@7->display_action_text_reading#0] -- register_copy 
    // [2683] phi display_action_text_reading::bram_bank#10 = display_action_text_reading::bram_bank#2 [phi:w25q16_read::@7->display_action_text_reading#1] -- register_copy 
    // [2683] phi display_action_text_reading::size#10 = vera_size [phi:w25q16_read::@7->display_action_text_reading#2] -- vduz1=vduc1 
    lda #<vera_size
    sta.z display_action_text_reading.size
    lda #>vera_size
    sta.z display_action_text_reading.size+1
    lda #<vera_size>>$10
    sta.z display_action_text_reading.size+2
    lda #>vera_size>>$10
    sta.z display_action_text_reading.size+3
    // [2683] phi display_action_text_reading::bytes#3 = display_action_text_reading::bytes#2 [phi:w25q16_read::@7->display_action_text_reading#3] -- register_copy 
    // [2683] phi display_action_text_reading::file#3 = w25q16_read::path [phi:w25q16_read::@7->display_action_text_reading#4] -- pbuz1=pbuc1 
    lda #<path
    sta.z display_action_text_reading.file
    lda #>path
    sta.z display_action_text_reading.file+1
    // [2683] phi display_action_text_reading::action#3 = display_action_text_reading::action#2 [phi:w25q16_read::@7->display_action_text_reading#5] -- register_copy 
    jsr display_action_text_reading
    // w25q16_read::bank_set_bram2
    // BRAM = bank
    // [2310] BRAM = w25q16_read::vera_bram_bank#10 -- vbuz1=vbum2 
    lda vera_bram_bank
    sta.z BRAM
    // w25q16_read::@18
    // unsigned int vera_package_read = fgets(vera_bram_ptr, VERA_PROGRESS_CELL, fp)
    // [2311] fgets::ptr#5 = w25q16_read::vera_bram_ptr#10 -- pbuz1=pbum2 
    lda vera_bram_ptr
    sta.z fgets.ptr
    lda vera_bram_ptr+1
    sta.z fgets.ptr+1
    // [2312] fgets::stream#3 = w25q16_read::fp#0 -- pssz1=pssz2 
    lda.z fp
    sta.z fgets.stream
    lda.z fp+1
    sta.z fgets.stream+1
    // [2313] call fgets
    // [2714] phi from w25q16_read::@18 to fgets [phi:w25q16_read::@18->fgets]
    // [2714] phi fgets::ptr#14 = fgets::ptr#5 [phi:w25q16_read::@18->fgets#0] -- register_copy 
    // [2714] phi fgets::size#10 = VERA_PROGRESS_CELL [phi:w25q16_read::@18->fgets#1] -- vwum1=vbuc1 
    lda #<VERA_PROGRESS_CELL
    sta fgets.size
    lda #>VERA_PROGRESS_CELL
    sta fgets.size+1
    // [2714] phi fgets::stream#4 = fgets::stream#3 [phi:w25q16_read::@18->fgets#2] -- register_copy 
    jsr fgets
    // unsigned int vera_package_read = fgets(vera_bram_ptr, VERA_PROGRESS_CELL, fp)
    // [2314] fgets::return#13 = fgets::return#1
    // w25q16_read::@21
    // [2315] w25q16_read::vera_package_read#0 = fgets::return#13 -- vwuz1=vwum2 
    lda fgets.return
    sta.z vera_package_read
    lda fgets.return+1
    sta.z vera_package_read+1
    // if (!vera_package_read)
    // [2316] if(0!=w25q16_read::vera_package_read#0) goto w25q16_read::@8 -- 0_neq_vwuz1_then_la1 
    lda.z vera_package_read
    ora.z vera_package_read+1
    bne __b8
    jmp __b9
    // w25q16_read::@8
  __b8:
    // if (progress_row_current == VERA_PROGRESS_ROW)
    // [2317] if(w25q16_read::progress_row_current#10!=VERA_PROGRESS_ROW) goto w25q16_read::@10 -- vwum1_neq_vwuc1_then_la1 
    lda progress_row_current+1
    cmp #>VERA_PROGRESS_ROW
    bne __b10
    lda progress_row_current
    cmp #<VERA_PROGRESS_ROW
    bne __b10
    // w25q16_read::@13
    // gotoxy(x, ++y);
    // [2318] w25q16_read::y#1 = ++ w25q16_read::y#11 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [2319] gotoxy::y#34 = w25q16_read::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [2320] call gotoxy
    // [805] phi from w25q16_read::@13 to gotoxy [phi:w25q16_read::@13->gotoxy]
    // [805] phi gotoxy::y#37 = gotoxy::y#34 [phi:w25q16_read::@13->gotoxy#0] -- register_copy 
    // [805] phi gotoxy::x#37 = PROGRESS_X [phi:w25q16_read::@13->gotoxy#1] -- vbuyy=vbuc1 
    ldy #PROGRESS_X
    jsr gotoxy
    // [2321] phi from w25q16_read::@13 to w25q16_read::@10 [phi:w25q16_read::@13->w25q16_read::@10]
    // [2321] phi w25q16_read::y#22 = w25q16_read::y#1 [phi:w25q16_read::@13->w25q16_read::@10#0] -- register_copy 
    // [2321] phi w25q16_read::progress_row_current#4 = 0 [phi:w25q16_read::@13->w25q16_read::@10#1] -- vwum1=vbuc1 
    lda #<0
    sta progress_row_current
    sta progress_row_current+1
    // [2321] phi from w25q16_read::@8 to w25q16_read::@10 [phi:w25q16_read::@8->w25q16_read::@10]
    // [2321] phi w25q16_read::y#22 = w25q16_read::y#11 [phi:w25q16_read::@8->w25q16_read::@10#0] -- register_copy 
    // [2321] phi w25q16_read::progress_row_current#4 = w25q16_read::progress_row_current#10 [phi:w25q16_read::@8->w25q16_read::@10#1] -- register_copy 
    // w25q16_read::@10
  __b10:
    // if(info_status == STATUS_READING)
    // [2322] if(w25q16_read::info_status#12!=STATUS_READING) goto w25q16_read::@11 -- vbum1_neq_vbuc1_then_la1 
    lda #STATUS_READING
    cmp info_status
    bne __b11
    // w25q16_read::@14
    // cputc('.')
    // [2323] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [2324] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // w25q16_read::@11
  __b11:
    // vera_bram_ptr += vera_package_read
    // [2326] w25q16_read::vera_bram_ptr#2 = w25q16_read::vera_bram_ptr#10 + w25q16_read::vera_package_read#0 -- pbum1=pbum1_plus_vwuz2 
    clc
    lda vera_bram_ptr
    adc.z vera_package_read
    sta vera_bram_ptr
    lda vera_bram_ptr+1
    adc.z vera_package_read+1
    sta vera_bram_ptr+1
    // vera_file_size += vera_package_read
    // [2327] w25q16_read::vera_file_size#1 = w25q16_read::vera_file_size#11 + w25q16_read::vera_package_read#0 -- vduz1=vduz1_plus_vwuz2 
    lda.z vera_file_size
    clc
    adc.z vera_package_read
    sta.z vera_file_size
    lda.z vera_file_size+1
    adc.z vera_package_read+1
    sta.z vera_file_size+1
    lda.z vera_file_size+2
    adc #0
    sta.z vera_file_size+2
    lda.z vera_file_size+3
    adc #0
    sta.z vera_file_size+3
    // progress_row_current += vera_package_read
    // [2328] w25q16_read::progress_row_current#15 = w25q16_read::progress_row_current#4 + w25q16_read::vera_package_read#0 -- vwum1=vwum1_plus_vwuz2 
    clc
    lda progress_row_current
    adc.z vera_package_read
    sta progress_row_current
    lda progress_row_current+1
    adc.z vera_package_read+1
    sta progress_row_current+1
    // if (vera_bram_ptr == (bram_ptr_t)BRAM_HIGH)
    // [2329] if(w25q16_read::vera_bram_ptr#2!=(char *)$c000) goto w25q16_read::@12 -- pbum1_neq_pbuc1_then_la1 
    lda vera_bram_ptr+1
    cmp #>$c000
    bne __b12
    lda vera_bram_ptr
    cmp #<$c000
    bne __b12
    // w25q16_read::@15
    // vera_bram_bank++;
    // [2330] w25q16_read::vera_bram_bank#2 = ++ w25q16_read::vera_bram_bank#10 -- vbum1=_inc_vbum1 
    inc vera_bram_bank
    // [2331] phi from w25q16_read::@15 to w25q16_read::@12 [phi:w25q16_read::@15->w25q16_read::@12]
    // [2331] phi w25q16_read::vera_bram_bank#13 = w25q16_read::vera_bram_bank#2 [phi:w25q16_read::@15->w25q16_read::@12#0] -- register_copy 
    // [2331] phi w25q16_read::vera_bram_ptr#8 = (char *)$a000 [phi:w25q16_read::@15->w25q16_read::@12#1] -- pbum1=pbuc1 
    lda #<$a000
    sta vera_bram_ptr
    lda #>$a000
    sta vera_bram_ptr+1
    // [2331] phi from w25q16_read::@11 to w25q16_read::@12 [phi:w25q16_read::@11->w25q16_read::@12]
    // [2331] phi w25q16_read::vera_bram_bank#13 = w25q16_read::vera_bram_bank#10 [phi:w25q16_read::@11->w25q16_read::@12#0] -- register_copy 
    // [2331] phi w25q16_read::vera_bram_ptr#8 = w25q16_read::vera_bram_ptr#2 [phi:w25q16_read::@11->w25q16_read::@12#1] -- register_copy 
    // w25q16_read::@12
  __b12:
    // if (vera_bram_ptr == (bram_ptr_t)RAM_HIGH)
    // [2332] if(w25q16_read::vera_bram_ptr#8!=(char *)$9800) goto w25q16_read::@22 -- pbum1_neq_pbuc1_then_la1 
    lda vera_bram_ptr+1
    cmp #>$9800
    beq !__b5+
    jmp __b5
  !__b5:
    lda vera_bram_ptr
    cmp #<$9800
    beq !__b5+
    jmp __b5
  !__b5:
    // [2296] phi from w25q16_read::@12 to w25q16_read::@5 [phi:w25q16_read::@12->w25q16_read::@5]
    // [2296] phi w25q16_read::y#11 = w25q16_read::y#22 [phi:w25q16_read::@12->w25q16_read::@5#0] -- register_copy 
    // [2296] phi w25q16_read::progress_row_current#10 = w25q16_read::progress_row_current#15 [phi:w25q16_read::@12->w25q16_read::@5#1] -- register_copy 
    // [2296] phi w25q16_read::vera_bram_ptr#13 = (char *)$a000 [phi:w25q16_read::@12->w25q16_read::@5#2] -- pbum1=pbuc1 
    lda #<$a000
    sta vera_bram_ptr
    lda #>$a000
    sta vera_bram_ptr+1
    // [2296] phi w25q16_read::vera_bram_bank#10 = 1 [phi:w25q16_read::@12->w25q16_read::@5#3] -- vbum1=vbuc1 
    lda #1
    sta vera_bram_bank
    // [2296] phi w25q16_read::vera_file_size#11 = w25q16_read::vera_file_size#1 [phi:w25q16_read::@12->w25q16_read::@5#4] -- register_copy 
    jmp __b5
    // [2333] phi from w25q16_read::@12 to w25q16_read::@22 [phi:w25q16_read::@12->w25q16_read::@22]
    // w25q16_read::@22
    // [2296] phi from w25q16_read::@22 to w25q16_read::@5 [phi:w25q16_read::@22->w25q16_read::@5]
    // [2296] phi w25q16_read::y#11 = w25q16_read::y#22 [phi:w25q16_read::@22->w25q16_read::@5#0] -- register_copy 
    // [2296] phi w25q16_read::progress_row_current#10 = w25q16_read::progress_row_current#15 [phi:w25q16_read::@22->w25q16_read::@5#1] -- register_copy 
    // [2296] phi w25q16_read::vera_bram_ptr#13 = w25q16_read::vera_bram_ptr#8 [phi:w25q16_read::@22->w25q16_read::@5#2] -- register_copy 
    // [2296] phi w25q16_read::vera_bram_bank#10 = w25q16_read::vera_bram_bank#13 [phi:w25q16_read::@22->w25q16_read::@5#3] -- register_copy 
    // [2296] phi w25q16_read::vera_file_size#11 = w25q16_read::vera_file_size#1 [phi:w25q16_read::@22->w25q16_read::@5#4] -- register_copy 
  .segment Data
    info_text: .text "Opening VERA.BIN from SD card ..."
    .byte 0
    path: .text "VERA.BIN"
    .byte 0
    .label y = w25q16_erase.vera_total_64k_blocks
    // We start for VERA from 0x1:0xA000.
    .label vera_bram_ptr = smc_flash.smc_bootloader_not_activated1
    .label vera_bram_bank = w25q16_verify.w25q16_byte
    .label progress_row_current = util_wait_key.ch
    .label info_status = util_wait_key.brom
    .label vera_action_text = smc_flash.smc_commit_result
}
.segment Code
  // uctoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void uctoa(__register(X) char value, __zp($2c) char *buffer, __register(Y) char radix)
uctoa: {
    .label buffer = $2c
    .label digit_values = $32
    // if(radix==DECIMAL)
    // [2334] if(uctoa::radix#0==DECIMAL) goto uctoa::@1 -- vbuyy_eq_vbuc1_then_la1 
    cpy #DECIMAL
    beq __b2
    // uctoa::@2
    // if(radix==HEXADECIMAL)
    // [2335] if(uctoa::radix#0==HEXADECIMAL) goto uctoa::@1 -- vbuyy_eq_vbuc1_then_la1 
    cpy #HEXADECIMAL
    beq __b3
    // uctoa::@3
    // if(radix==OCTAL)
    // [2336] if(uctoa::radix#0==OCTAL) goto uctoa::@1 -- vbuyy_eq_vbuc1_then_la1 
    cpy #OCTAL
    beq __b4
    // uctoa::@4
    // if(radix==BINARY)
    // [2337] if(uctoa::radix#0==BINARY) goto uctoa::@1 -- vbuyy_eq_vbuc1_then_la1 
    cpy #BINARY
    beq __b5
    // uctoa::@5
    // *buffer++ = 'e'
    // [2338] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2339] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2340] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2341] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // uctoa::@return
    // }
    // [2342] return 
    rts
    // [2343] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
  __b2:
    // [2343] phi uctoa::digit_values#8 = RADIX_DECIMAL_VALUES_CHAR [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [2343] phi uctoa::max_digits#7 = 3 [phi:uctoa->uctoa::@1#1] -- vbum1=vbuc1 
    lda #3
    sta max_digits
    jmp __b1
    // [2343] phi from uctoa::@2 to uctoa::@1 [phi:uctoa::@2->uctoa::@1]
  __b3:
    // [2343] phi uctoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_CHAR [phi:uctoa::@2->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [2343] phi uctoa::max_digits#7 = 2 [phi:uctoa::@2->uctoa::@1#1] -- vbum1=vbuc1 
    lda #2
    sta max_digits
    jmp __b1
    // [2343] phi from uctoa::@3 to uctoa::@1 [phi:uctoa::@3->uctoa::@1]
  __b4:
    // [2343] phi uctoa::digit_values#8 = RADIX_OCTAL_VALUES_CHAR [phi:uctoa::@3->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values+1
    // [2343] phi uctoa::max_digits#7 = 3 [phi:uctoa::@3->uctoa::@1#1] -- vbum1=vbuc1 
    lda #3
    sta max_digits
    jmp __b1
    // [2343] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
  __b5:
    // [2343] phi uctoa::digit_values#8 = RADIX_BINARY_VALUES_CHAR [phi:uctoa::@4->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_BINARY_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_CHAR
    sta.z digit_values+1
    // [2343] phi uctoa::max_digits#7 = 8 [phi:uctoa::@4->uctoa::@1#1] -- vbum1=vbuc1 
    lda #8
    sta max_digits
    // uctoa::@1
  __b1:
    // [2344] phi from uctoa::@1 to uctoa::@6 [phi:uctoa::@1->uctoa::@6]
    // [2344] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa::@1->uctoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2344] phi uctoa::started#2 = 0 [phi:uctoa::@1->uctoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [2344] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa::@1->uctoa::@6#2] -- register_copy 
    // [2344] phi uctoa::digit#2 = 0 [phi:uctoa::@1->uctoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // uctoa::@6
  __b6:
    // max_digits-1
    // [2345] uctoa::$4 = uctoa::max_digits#7 - 1 -- vbuaa=vbum1_minus_1 
    lda max_digits
    sec
    sbc #1
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2346] if(uctoa::digit#2<uctoa::$4) goto uctoa::@7 -- vbum1_lt_vbuaa_then_la1 
    cmp digit
    beq !+
    bcs __b7
  !:
    // uctoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2347] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbuxx 
    lda DIGITS,x
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2348] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2349] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // uctoa::@7
  __b7:
    // unsigned char digit_value = digit_values[digit]
    // [2350] uctoa::digit_value#0 = uctoa::digit_values#8[uctoa::digit#2] -- vbuyy=pbuz1_derefidx_vbum2 
    ldy digit
    lda (digit_values),y
    tay
    // if (started || value >= digit_value)
    // [2351] if(0!=uctoa::started#2) goto uctoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // uctoa::@12
    // [2352] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@10 -- vbuxx_ge_vbuyy_then_la1 
    sty.z $ff
    cpx.z $ff
    bcs __b10
    // [2353] phi from uctoa::@12 to uctoa::@9 [phi:uctoa::@12->uctoa::@9]
    // [2353] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@12->uctoa::@9#0] -- register_copy 
    // [2353] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@12->uctoa::@9#1] -- register_copy 
    // [2353] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@12->uctoa::@9#2] -- register_copy 
    // uctoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2354] uctoa::digit#1 = ++ uctoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [2344] phi from uctoa::@9 to uctoa::@6 [phi:uctoa::@9->uctoa::@6]
    // [2344] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@9->uctoa::@6#0] -- register_copy 
    // [2344] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@9->uctoa::@6#1] -- register_copy 
    // [2344] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@9->uctoa::@6#2] -- register_copy 
    // [2344] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@9->uctoa::@6#3] -- register_copy 
    jmp __b6
    // uctoa::@10
  __b10:
    // uctoa_append(buffer++, value, digit_value)
    // [2355] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [2356] uctoa_append::value#0 = uctoa::value#2
    // [2357] uctoa_append::sub#0 = uctoa::digit_value#0 -- vbum1=vbuyy 
    sty uctoa_append.sub
    // [2358] call uctoa_append
    // [3244] phi from uctoa::@10 to uctoa_append [phi:uctoa::@10->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [2359] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@11
    // value = uctoa_append(buffer++, value, digit_value)
    // [2360] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [2361] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2353] phi from uctoa::@11 to uctoa::@9 [phi:uctoa::@11->uctoa::@9]
    // [2353] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@11->uctoa::@9#0] -- register_copy 
    // [2353] phi uctoa::started#4 = 1 [phi:uctoa::@11->uctoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [2353] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@11->uctoa::@9#2] -- register_copy 
    jmp __b9
  .segment Data
    digit: .byte 0
    started: .byte 0
    .label max_digits = printf_string.format_justify_left
}
.segment Code
  // printf_number_buffer
// Print the contents of the number buffer using a specific format.
// This handles minimum length, zero-filling, and left/right justification from the format
// void printf_number_buffer(__zp($67) void (*putc)(char), __mem() char buffer_sign, char *buffer_digits, __register(X) char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, char format_radix)
printf_number_buffer: {
    .label printf_number_buffer__19 = $6f
    .label putc = $67
    // if(format.min_length)
    // [2363] if(0==printf_number_buffer::format_min_length#3) goto printf_number_buffer::@1 -- 0_eq_vbuxx_then_la1 
    cpx #0
    beq __b5
    // [2364] phi from printf_number_buffer to printf_number_buffer::@5 [phi:printf_number_buffer->printf_number_buffer::@5]
    // printf_number_buffer::@5
    // strlen(buffer.digits)
    // [2365] call strlen
    // [2555] phi from printf_number_buffer::@5 to strlen [phi:printf_number_buffer::@5->strlen]
    // [2555] phi strlen::str#8 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [2366] strlen::return#3 = strlen::len#2
    // printf_number_buffer::@11
    // [2367] printf_number_buffer::$19 = strlen::return#3 -- vwuz1=vwum2 
    lda strlen.return
    sta.z printf_number_buffer__19
    lda strlen.return+1
    sta.z printf_number_buffer__19+1
    // signed char len = (signed char)strlen(buffer.digits)
    // [2368] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsyy=_sbyte_vwuz1 
    // There is a minimum length - work out the padding
    ldy.z printf_number_buffer__19
    // if(buffer.sign)
    // [2369] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@10 -- 0_eq_vbum1_then_la1 
    lda buffer_sign
    beq __b10
    // printf_number_buffer::@6
    // len++;
    // [2370] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsyy=_inc_vbsyy 
    iny
    // [2371] phi from printf_number_buffer::@11 printf_number_buffer::@6 to printf_number_buffer::@10 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10]
    // [2371] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10#0] -- register_copy 
    // printf_number_buffer::@10
  __b10:
    // padding = (signed char)format.min_length - len
    // [2372] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#3 - printf_number_buffer::len#2 -- vbsm1=vbsxx_minus_vbsyy 
    txa
    sty.z $ff
    sec
    sbc.z $ff
    sta padding
    // if(padding<0)
    // [2373] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@15 -- vbsm1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [2375] phi from printf_number_buffer printf_number_buffer::@10 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1]
  __b5:
    // [2375] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1#0] -- vbsm1=vbsc1 
    lda #0
    sta padding
    // [2374] phi from printf_number_buffer::@10 to printf_number_buffer::@15 [phi:printf_number_buffer::@10->printf_number_buffer::@15]
    // printf_number_buffer::@15
    // [2375] phi from printf_number_buffer::@15 to printf_number_buffer::@1 [phi:printf_number_buffer::@15->printf_number_buffer::@1]
    // [2375] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@15->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // printf_number_buffer::@13
    // if(!format.justify_left && !format.zero_padding && padding)
    // [2376] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbum1_then_la1 
    lda format_zero_padding
    bne __b2
    // printf_number_buffer::@12
    // [2377] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@7 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b7
    jmp __b2
    // printf_number_buffer::@7
  __b7:
    // printf_padding(putc, ' ',(char)padding)
    // [2378] printf_padding::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [2379] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [2380] call printf_padding
    // [2561] phi from printf_number_buffer::@7 to printf_padding [phi:printf_number_buffer::@7->printf_padding]
    // [2561] phi printf_padding::putc#7 = printf_padding::putc#0 [phi:printf_number_buffer::@7->printf_padding#0] -- register_copy 
    // [2561] phi printf_padding::pad#7 = ' ' [phi:printf_number_buffer::@7->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [2561] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@7->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [2381] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbum1_then_la1 
    lda buffer_sign
    beq __b3
    // printf_number_buffer::@8
    // putc(buffer.sign)
    // [2382] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbum1 
    pha
    // [2383] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall35
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [2385] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbum1_then_la1 
    lda format_zero_padding
    beq __b4
    // printf_number_buffer::@14
    // [2386] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@9 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b9
    jmp __b4
    // printf_number_buffer::@9
  __b9:
    // printf_padding(putc, '0',(char)padding)
    // [2387] printf_padding::putc#1 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [2388] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [2389] call printf_padding
    // [2561] phi from printf_number_buffer::@9 to printf_padding [phi:printf_number_buffer::@9->printf_padding]
    // [2561] phi printf_padding::putc#7 = printf_padding::putc#1 [phi:printf_number_buffer::@9->printf_padding#0] -- register_copy 
    // [2561] phi printf_padding::pad#7 = '0' [phi:printf_number_buffer::@9->printf_padding#1] -- vbum1=vbuc1 
    lda #'0'
    sta printf_padding.pad
    // [2561] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@9->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // printf_str(putc, buffer.digits)
    // [2390] printf_str::putc#0 = printf_number_buffer::putc#10
    // [2391] call printf_str
    // [1125] phi from printf_number_buffer::@4 to printf_str [phi:printf_number_buffer::@4->printf_str]
    // [1125] phi printf_str::putc#79 = printf_str::putc#0 [phi:printf_number_buffer::@4->printf_str#0] -- register_copy 
    // [1125] phi printf_str::s#79 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@return
    // }
    // [2392] return 
    rts
    // Outside Flow
  icall35:
    jmp (putc)
  .segment Data
    .label buffer_sign = uctoa.digit
    .label format_zero_padding = printf_uchar.format_zero_padding
    .label padding = uctoa.started
}
.segment CodeVera
  // w25q16_verify
/**
 * @brief Verify the w25q16 flash memory contents with the VERA.BIN file contents loaded from RAM $01:A000.
 * 
 * @return unsigned long The total different bytes identified.
 */
// __mem() unsigned long w25q16_verify(__register(X) char verify)
w25q16_verify: {
    .label w25q16_verify__10 = $c5
    .label w25q16_address = $36
    .label different_char = $22
    // w25q16_verify::bank_set_bram1
    // BRAM = bank
    // [2394] BRAM = 1 -- vbuz1=vbuc1 
    lda #1
    sta.z BRAM
    // w25q16_verify::@21
    // if(verify)
    // [2395] if(0!=w25q16_verify::verify#2) goto w25q16_verify::@1 -- 0_neq_vbuxx_then_la1 
    cpx #0
    beq !__b1+
    jmp __b1
  !__b1:
    // [2396] phi from w25q16_verify::@21 to w25q16_verify::@3 [phi:w25q16_verify::@21->w25q16_verify::@3]
    // w25q16_verify::@3
    // display_action_progress("Comparing VERA with VERA.BIN ... (.) data, (=) same, (*) different.")
    // [2397] call display_action_progress
    // [1155] phi from w25q16_verify::@3 to display_action_progress [phi:w25q16_verify::@3->display_action_progress]
    // [1155] phi display_action_progress::info_text#30 = w25q16_verify::info_text1 [phi:w25q16_verify::@3->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_action_progress.info_text
    lda #>info_text1
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [2398] phi from w25q16_verify::@3 to w25q16_verify::@2 [phi:w25q16_verify::@3->w25q16_verify::@2]
    // [2398] phi w25q16_verify::different_char#16 = '*' [phi:w25q16_verify::@3->w25q16_verify::@2#0] -- vbuz1=vbuc1 
    lda #'*'
    sta.z different_char
    // w25q16_verify::@2
  __b2:
    // gotoxy(x, y)
    // [2399] call gotoxy
    // [805] phi from w25q16_verify::@2 to gotoxy [phi:w25q16_verify::@2->gotoxy]
    // [805] phi gotoxy::y#37 = PROGRESS_Y [phi:w25q16_verify::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [805] phi gotoxy::x#37 = PROGRESS_X [phi:w25q16_verify::@2->gotoxy#1] -- vbuyy=vbuc1 
    ldy #PROGRESS_X
    jsr gotoxy
    // [2400] phi from w25q16_verify::@2 to w25q16_verify::@22 [phi:w25q16_verify::@2->w25q16_verify::@22]
    // w25q16_verify::@22
    // spi_read_flash(0UL)
    // [2401] call spi_read_flash
    // [3251] phi from w25q16_verify::@22 to spi_read_flash [phi:w25q16_verify::@22->spi_read_flash]
    jsr spi_read_flash
    // [2402] phi from w25q16_verify::@22 to w25q16_verify::@4 [phi:w25q16_verify::@22->w25q16_verify::@4]
    // [2402] phi w25q16_verify::y#15 = PROGRESS_Y [phi:w25q16_verify::@22->w25q16_verify::@4#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [2402] phi w25q16_verify::progress_row_current#12 = 0 [phi:w25q16_verify::@22->w25q16_verify::@4#1] -- vwum1=vwuc1 
    lda #<0
    sta progress_row_current
    sta progress_row_current+1
    // [2402] phi w25q16_verify::bram_ptr#14 = (char *)$a000 [phi:w25q16_verify::@22->w25q16_verify::@4#2] -- pbum1=pbuc1 
    lda #<$a000
    sta bram_ptr
    lda #>$a000
    sta bram_ptr+1
    // [2402] phi w25q16_verify::w25q16_different_bytes#2 = 0 [phi:w25q16_verify::@22->w25q16_verify::@4#3] -- vdum1=vduc1 
    lda #<0
    sta w25q16_different_bytes
    sta w25q16_different_bytes+1
    lda #<0>>$10
    sta w25q16_different_bytes+2
    lda #>0>>$10
    sta w25q16_different_bytes+3
    // [2402] phi w25q16_verify::bank_set_bram2_bank#0 = 1 [phi:w25q16_verify::@22->w25q16_verify::@4#4] -- vbum1=vbuc1 
    lda #1
    sta bank_set_bram2_bank
    // [2402] phi w25q16_verify::w25q16_address#2 = 0 [phi:w25q16_verify::@22->w25q16_verify::@4#5] -- vduz1=vduc1 
    lda #<0
    sta.z w25q16_address
    sta.z w25q16_address+1
    lda #<0>>$10
    sta.z w25q16_address+2
    lda #>0>>$10
    sta.z w25q16_address+3
  // Start the w26q16 flash memory read cycle from 0x0 using the spi interface
    // w25q16_verify::@4
  __b4:
    // while (w25q16_address < vera_file_size)
    // [2403] if(w25q16_verify::w25q16_address#2<vera_file_size#1) goto w25q16_verify::@5 -- vduz1_lt_vdum2_then_la1 
    lda.z w25q16_address+3
    cmp vera_file_size+3
    bcc __b5
    bne !+
    lda.z w25q16_address+2
    cmp vera_file_size+2
    bcc __b5
    bne !+
    lda.z w25q16_address+1
    cmp vera_file_size+1
    bcc __b5
    bne !+
    lda.z w25q16_address
    cmp vera_file_size
    bcc __b5
  !:
    // [2404] phi from w25q16_verify::@4 to w25q16_verify::@6 [phi:w25q16_verify::@4->w25q16_verify::@6]
    // w25q16_verify::@6
    // wait_moment(16)
    // [2405] call wait_moment
    // [1134] phi from w25q16_verify::@6 to wait_moment [phi:w25q16_verify::@6->wait_moment]
    // [1134] phi wait_moment::w#17 = $10 [phi:w25q16_verify::@6->wait_moment#0] -- vbuz1=vbuc1 
    lda #$10
    sta.z wait_moment.w
    jsr wait_moment
    // w25q16_verify::@return
    // }
    // [2406] return 
    rts
    // w25q16_verify::@5
  __b5:
    // w25q16_address + VERA_PROGRESS_CELL
    // [2407] w25q16_verify::$7 = w25q16_verify::w25q16_address#2 + VERA_PROGRESS_CELL -- vdum1=vduz2_plus_vbuc1 
    lda #VERA_PROGRESS_CELL
    clc
    adc.z w25q16_address
    sta w25q16_verify__7
    lda.z w25q16_address+1
    adc #0
    sta w25q16_verify__7+1
    lda.z w25q16_address+2
    adc #0
    sta w25q16_verify__7+2
    lda.z w25q16_address+3
    adc #0
    sta w25q16_verify__7+3
    // if(w25q16_address + VERA_PROGRESS_CELL > vera_file_size)
    // [2408] if(w25q16_verify::$7<=vera_file_size#1) goto w25q16_verify::@7 -- vdum1_le_vdum2_then_la1 
    lda vera_file_size+3
    cmp w25q16_verify__7+3
    bcc !+
    bne __b3
    lda vera_file_size+2
    cmp w25q16_verify__7+2
    bcc !+
    bne __b3
    lda vera_file_size+1
    cmp w25q16_verify__7+1
    bcc !+
    bne __b3
    lda vera_file_size
    cmp w25q16_verify__7
    bcs __b3
  !:
    // w25q16_verify::@18
    // vera_file_size - w25q16_address
    // [2409] w25q16_verify::$10 = vera_file_size#1 - w25q16_verify::w25q16_address#2 -- vduz1=vdum2_minus_vduz3 
    lda vera_file_size
    sec
    sbc.z w25q16_address
    sta.z w25q16_verify__10
    lda vera_file_size+1
    sbc.z w25q16_address+1
    sta.z w25q16_verify__10+1
    lda vera_file_size+2
    sbc.z w25q16_address+2
    sta.z w25q16_verify__10+2
    lda vera_file_size+3
    sbc.z w25q16_address+3
    sta.z w25q16_verify__10+3
    // w25q16_compare_size = BYTE0(vera_file_size - w25q16_address)
    // [2410] w25q16_verify::w25q16_compare_size#1 = byte0  w25q16_verify::$10 -- vbum1=_byte0_vduz2 
    lda.z w25q16_verify__10
    sta w25q16_compare_size
    // [2411] phi from w25q16_verify::@18 to w25q16_verify::@7 [phi:w25q16_verify::@18->w25q16_verify::@7]
    // [2411] phi w25q16_verify::w25q16_compare_size#15 = w25q16_verify::w25q16_compare_size#1 [phi:w25q16_verify::@18->w25q16_verify::@7#0] -- register_copy 
    jmp __b7
    // [2411] phi from w25q16_verify::@5 to w25q16_verify::@7 [phi:w25q16_verify::@5->w25q16_verify::@7]
  __b3:
    // [2411] phi w25q16_verify::w25q16_compare_size#15 = VERA_PROGRESS_CELL [phi:w25q16_verify::@5->w25q16_verify::@7#0] -- vbum1=vbuc1 
    lda #VERA_PROGRESS_CELL
    sta w25q16_compare_size
    // w25q16_verify::@7
  __b7:
    // w25q16_verify::bank_set_bram2
    // BRAM = bank
    // [2412] BRAM = w25q16_verify::bank_set_bram2_bank#0 -- vbuz1=vbum2 
    lda bank_set_bram2_bank
    sta.z BRAM
    // [2413] phi from w25q16_verify::bank_set_bram2 to w25q16_verify::@8 [phi:w25q16_verify::bank_set_bram2->w25q16_verify::@8]
    // [2413] phi w25q16_verify::w25q16_equal_bytes#10 = 0 [phi:w25q16_verify::bank_set_bram2->w25q16_verify::@8#0] -- vbum1=vbuc1 
    lda #0
    sta w25q16_equal_bytes
    // [2413] phi w25q16_verify::w25q16_compared_bytes#2 = 0 [phi:w25q16_verify::bank_set_bram2->w25q16_verify::@8#1] -- vbum1=vbuc1 
    sta w25q16_compared_bytes
    // [2413] phi w25q16_verify::bram_ptr#10 = w25q16_verify::bram_ptr#14 [phi:w25q16_verify::bank_set_bram2->w25q16_verify::@8#2] -- register_copy 
    // w25q16_verify::@8
  __b8:
    // unsigned char w25q16_byte = spi_read()
    // [2414] call spi_read
    jsr spi_read
    // [2415] spi_read::return#14 = spi_read::return#12
    // w25q16_verify::@23
    // [2416] w25q16_verify::w25q16_byte#0 = spi_read::return#14 -- vbum1=vbuaa 
    sta w25q16_byte
    // if (w25q16_byte == *bram_ptr)
    // [2417] if(w25q16_verify::w25q16_byte#0!=*w25q16_verify::bram_ptr#10) goto w25q16_verify::@9 -- vbum1_neq__deref_pbum2_then_la1 
    ldy bram_ptr
    sty.z $fe
    ldy bram_ptr+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    cmp w25q16_byte
    bne __b9
    // w25q16_verify::@10
    // w25q16_equal_bytes++;
    // [2418] w25q16_verify::w25q16_equal_bytes#1 = ++ w25q16_verify::w25q16_equal_bytes#10 -- vbum1=_inc_vbum1 
    inc w25q16_equal_bytes
    // [2419] phi from w25q16_verify::@10 w25q16_verify::@23 to w25q16_verify::@9 [phi:w25q16_verify::@10/w25q16_verify::@23->w25q16_verify::@9]
    // [2419] phi w25q16_verify::w25q16_equal_bytes#11 = w25q16_verify::w25q16_equal_bytes#1 [phi:w25q16_verify::@10/w25q16_verify::@23->w25q16_verify::@9#0] -- register_copy 
    // w25q16_verify::@9
  __b9:
    // bram_ptr++;
    // [2420] w25q16_verify::bram_ptr#1 = ++ w25q16_verify::bram_ptr#10 -- pbum1=_inc_pbum1 
    inc bram_ptr
    bne !+
    inc bram_ptr+1
  !:
    // w25q16_compare_size-1
    // [2421] w25q16_verify::$16 = w25q16_verify::w25q16_compare_size#15 - 1 -- vbuxx=vbum1_minus_1 
    ldx w25q16_compare_size
    dex
    // while(w25q16_compared_bytes++ != w25q16_compare_size-1)
    // [2422] w25q16_verify::w25q16_compared_bytes#1 = ++ w25q16_verify::w25q16_compared_bytes#2 -- vbuaa=_inc_vbum1 
    lda w25q16_compared_bytes
    inc
    // [2423] if(w25q16_verify::w25q16_compared_bytes#2!=w25q16_verify::$16) goto w25q16_verify::@32 -- vbum1_neq_vbuxx_then_la1 
    cpx w25q16_compared_bytes
    beq !__b32+
    jmp __b32
  !__b32:
    // w25q16_verify::@11
    // if (progress_row_current == VERA_PROGRESS_ROW)
    // [2424] if(w25q16_verify::progress_row_current#12!=VERA_PROGRESS_ROW) goto w25q16_verify::@13 -- vwum1_neq_vwuc1_then_la1 
    lda progress_row_current+1
    cmp #>VERA_PROGRESS_ROW
    bne __b13
    lda progress_row_current
    cmp #<VERA_PROGRESS_ROW
    bne __b13
    // w25q16_verify::@12
    // gotoxy(x, ++y);
    // [2425] w25q16_verify::y#1 = ++ w25q16_verify::y#15 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [2426] gotoxy::y#36 = w25q16_verify::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [2427] call gotoxy
    // [805] phi from w25q16_verify::@12 to gotoxy [phi:w25q16_verify::@12->gotoxy]
    // [805] phi gotoxy::y#37 = gotoxy::y#36 [phi:w25q16_verify::@12->gotoxy#0] -- register_copy 
    // [805] phi gotoxy::x#37 = PROGRESS_X [phi:w25q16_verify::@12->gotoxy#1] -- vbuyy=vbuc1 
    ldy #PROGRESS_X
    jsr gotoxy
    // [2428] phi from w25q16_verify::@12 to w25q16_verify::@13 [phi:w25q16_verify::@12->w25q16_verify::@13]
    // [2428] phi w25q16_verify::y#21 = w25q16_verify::y#1 [phi:w25q16_verify::@12->w25q16_verify::@13#0] -- register_copy 
    // [2428] phi w25q16_verify::progress_row_current#10 = 0 [phi:w25q16_verify::@12->w25q16_verify::@13#1] -- vwum1=vbuc1 
    lda #<0
    sta progress_row_current
    sta progress_row_current+1
    // [2428] phi from w25q16_verify::@11 to w25q16_verify::@13 [phi:w25q16_verify::@11->w25q16_verify::@13]
    // [2428] phi w25q16_verify::y#21 = w25q16_verify::y#15 [phi:w25q16_verify::@11->w25q16_verify::@13#0] -- register_copy 
    // [2428] phi w25q16_verify::progress_row_current#10 = w25q16_verify::progress_row_current#12 [phi:w25q16_verify::@11->w25q16_verify::@13#1] -- register_copy 
    // w25q16_verify::@13
  __b13:
    // if (w25q16_equal_bytes != w25q16_compare_size)
    // [2429] if(w25q16_verify::w25q16_equal_bytes#11!=w25q16_verify::w25q16_compare_size#15) goto w25q16_verify::@14 -- vbum1_neq_vbum2_then_la1 
    lda w25q16_equal_bytes
    cmp w25q16_compare_size
    beq !__b14+
    jmp __b14
  !__b14:
    // w25q16_verify::@19
    // cputc('=')
    // [2430] stackpush(char) = '=' -- _stackpushbyte_=vbuc1 
    lda #'='
    pha
    // [2431] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // w25q16_verify::@15
  __b15:
    // w25q16_address += VERA_PROGRESS_CELL
    // [2433] w25q16_verify::w25q16_address#1 = w25q16_verify::w25q16_address#2 + VERA_PROGRESS_CELL -- vduz1=vduz1_plus_vbuc1 
    // vera_bram_ptr += VERA_PROGRESS_CELL;
    lda.z w25q16_address
    clc
    adc #VERA_PROGRESS_CELL
    sta.z w25q16_address
    bcc !+
    inc.z w25q16_address+1
    bne !+
    inc.z w25q16_address+2
    bne !+
    inc.z w25q16_address+3
  !:
    // progress_row_current += VERA_PROGRESS_CELL
    // [2434] w25q16_verify::progress_row_current#18 = w25q16_verify::progress_row_current#10 + VERA_PROGRESS_CELL -- vwum1=vwum1_plus_vbuc1 
    lda #VERA_PROGRESS_CELL
    clc
    adc progress_row_current
    sta progress_row_current
    bcc !+
    inc progress_row_current+1
  !:
    // if (bram_ptr == BRAM_HIGH)
    // [2435] if(w25q16_verify::bram_ptr#1!=$c000) goto w25q16_verify::@16 -- pbum1_neq_vwuc1_then_la1 
    lda bram_ptr+1
    cmp #>$c000
    bne __b6
    lda bram_ptr
    cmp #<$c000
    bne __b6
    // w25q16_verify::@20
    // bram_bank++;
    // [2436] w25q16_verify::bram_bank#1 = ++ w25q16_verify::bank_set_bram2_bank#0 -- vbum1=_inc_vbum2 
    lda bank_set_bram2_bank
    inc
    sta bram_bank
    // [2437] phi from w25q16_verify::@20 to w25q16_verify::@16 [phi:w25q16_verify::@20->w25q16_verify::@16]
    // [2437] phi w25q16_verify::bram_bank#21 = w25q16_verify::bram_bank#1 [phi:w25q16_verify::@20->w25q16_verify::@16#0] -- register_copy 
    // [2437] phi w25q16_verify::bram_ptr#7 = (char *)$a000 [phi:w25q16_verify::@20->w25q16_verify::@16#1] -- pbum1=pbuc1 
    lda #<$a000
    sta bram_ptr
    lda #>$a000
    sta bram_ptr+1
    jmp __b16
    // [2437] phi from w25q16_verify::@15 to w25q16_verify::@16 [phi:w25q16_verify::@15->w25q16_verify::@16]
  __b6:
    // [2437] phi w25q16_verify::bram_bank#21 = w25q16_verify::bank_set_bram2_bank#0 [phi:w25q16_verify::@15->w25q16_verify::@16#0] -- vbum1=vbum2 
    lda bank_set_bram2_bank
    sta bram_bank
    // [2437] phi w25q16_verify::bram_ptr#7 = w25q16_verify::bram_ptr#1 [phi:w25q16_verify::@15->w25q16_verify::@16#1] -- register_copy 
    // w25q16_verify::@16
  __b16:
    // if (bram_ptr == RAM_HIGH)
    // [2438] if(w25q16_verify::bram_ptr#7!=$9800) goto w25q16_verify::@33 -- pbum1_neq_vwuc1_then_la1 
    lda bram_ptr+1
    cmp #>$9800
    bne __b17
    lda bram_ptr
    cmp #<$9800
    bne __b17
    // [2440] phi from w25q16_verify::@16 to w25q16_verify::@17 [phi:w25q16_verify::@16->w25q16_verify::@17]
    // [2440] phi w25q16_verify::bram_ptr#13 = (char *)$a000 [phi:w25q16_verify::@16->w25q16_verify::@17#0] -- pbum1=pbuc1 
    lda #<$a000
    sta bram_ptr
    lda #>$a000
    sta bram_ptr+1
    // [2440] phi w25q16_verify::bram_bank#13 = 1 [phi:w25q16_verify::@16->w25q16_verify::@17#1] -- vbum1=vbuc1 
    lda #1
    sta bram_bank
    // [2439] phi from w25q16_verify::@16 to w25q16_verify::@33 [phi:w25q16_verify::@16->w25q16_verify::@33]
    // w25q16_verify::@33
    // [2440] phi from w25q16_verify::@33 to w25q16_verify::@17 [phi:w25q16_verify::@33->w25q16_verify::@17]
    // [2440] phi w25q16_verify::bram_ptr#13 = w25q16_verify::bram_ptr#7 [phi:w25q16_verify::@33->w25q16_verify::@17#0] -- register_copy 
    // [2440] phi w25q16_verify::bram_bank#13 = w25q16_verify::bram_bank#21 [phi:w25q16_verify::@33->w25q16_verify::@17#1] -- register_copy 
    // w25q16_verify::@17
  __b17:
    // w25q16_compare_size - w25q16_equal_bytes
    // [2441] w25q16_verify::$28 = w25q16_verify::w25q16_compare_size#15 - w25q16_verify::w25q16_equal_bytes#11 -- vbuaa=vbum1_minus_vbum2 
    lda w25q16_compare_size
    sec
    sbc w25q16_equal_bytes
    // w25q16_different_bytes += (w25q16_compare_size - w25q16_equal_bytes)
    // [2442] w25q16_verify::w25q16_different_bytes#1 = w25q16_verify::w25q16_different_bytes#2 + w25q16_verify::$28 -- vdum1=vdum1_plus_vbuaa 
    clc
    adc w25q16_different_bytes
    sta w25q16_different_bytes
    lda w25q16_different_bytes+1
    adc #0
    sta w25q16_different_bytes+1
    lda w25q16_different_bytes+2
    adc #0
    sta w25q16_different_bytes+2
    lda w25q16_different_bytes+3
    adc #0
    sta w25q16_different_bytes+3
    // sprintf(info_text, "%05x different RAM:%02x:%04p <-> VERA:%05x", w25q16_different_bytes, bram_bank, bram_ptr, w25q16_address)
    // [2443] call snprintf_init
    // [1184] phi from w25q16_verify::@17 to snprintf_init [phi:w25q16_verify::@17->snprintf_init]
    // [1184] phi snprintf_init::s#30 = info_text [phi:w25q16_verify::@17->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // w25q16_verify::@24
    // sprintf(info_text, "%05x different RAM:%02x:%04p <-> VERA:%05x", w25q16_different_bytes, bram_bank, bram_ptr, w25q16_address)
    // [2444] printf_ulong::uvalue#8 = w25q16_verify::w25q16_different_bytes#1 -- vdum1=vdum2 
    lda w25q16_different_bytes
    sta printf_ulong.uvalue
    lda w25q16_different_bytes+1
    sta printf_ulong.uvalue+1
    lda w25q16_different_bytes+2
    sta printf_ulong.uvalue+2
    lda w25q16_different_bytes+3
    sta printf_ulong.uvalue+3
    // [2445] call printf_ulong
    // [1588] phi from w25q16_verify::@24 to printf_ulong [phi:w25q16_verify::@24->printf_ulong]
    // [1588] phi printf_ulong::format_zero_padding#14 = 1 [phi:w25q16_verify::@24->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1588] phi printf_ulong::format_min_length#14 = 5 [phi:w25q16_verify::@24->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1588] phi printf_ulong::format_radix#14 = HEXADECIMAL [phi:w25q16_verify::@24->printf_ulong#2] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [1588] phi printf_ulong::uvalue#14 = printf_ulong::uvalue#8 [phi:w25q16_verify::@24->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2446] phi from w25q16_verify::@24 to w25q16_verify::@25 [phi:w25q16_verify::@24->w25q16_verify::@25]
    // w25q16_verify::@25
    // sprintf(info_text, "%05x different RAM:%02x:%04p <-> VERA:%05x", w25q16_different_bytes, bram_bank, bram_ptr, w25q16_address)
    // [2447] call printf_str
    // [1125] phi from w25q16_verify::@25 to printf_str [phi:w25q16_verify::@25->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:w25q16_verify::@25->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = w25q16_verify::s [phi:w25q16_verify::@25->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // w25q16_verify::@26
    // sprintf(info_text, "%05x different RAM:%02x:%04p <-> VERA:%05x", w25q16_different_bytes, bram_bank, bram_ptr, w25q16_address)
    // [2448] printf_uchar::uvalue#12 = w25q16_verify::bram_bank#13 -- vbuxx=vbum1 
    ldx bram_bank
    // [2449] call printf_uchar
    // [1189] phi from w25q16_verify::@26 to printf_uchar [phi:w25q16_verify::@26->printf_uchar]
    // [1189] phi printf_uchar::format_zero_padding#15 = 1 [phi:w25q16_verify::@26->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1189] phi printf_uchar::format_min_length#15 = 2 [phi:w25q16_verify::@26->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1189] phi printf_uchar::putc#15 = &snputc [phi:w25q16_verify::@26->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1189] phi printf_uchar::format_radix#15 = HEXADECIMAL [phi:w25q16_verify::@26->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #HEXADECIMAL
    // [1189] phi printf_uchar::uvalue#15 = printf_uchar::uvalue#12 [phi:w25q16_verify::@26->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [2450] phi from w25q16_verify::@26 to w25q16_verify::@27 [phi:w25q16_verify::@26->w25q16_verify::@27]
    // w25q16_verify::@27
    // sprintf(info_text, "%05x different RAM:%02x:%04p <-> VERA:%05x", w25q16_different_bytes, bram_bank, bram_ptr, w25q16_address)
    // [2451] call printf_str
    // [1125] phi from w25q16_verify::@27 to printf_str [phi:w25q16_verify::@27->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:w25q16_verify::@27->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = s2 [phi:w25q16_verify::@27->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s2
    sta.z printf_str.s
    lda #>@s2
    sta.z printf_str.s+1
    jsr printf_str
    // w25q16_verify::@28
    // sprintf(info_text, "%05x different RAM:%02x:%04p <-> VERA:%05x", w25q16_different_bytes, bram_bank, bram_ptr, w25q16_address)
    // [2452] printf_uint::uvalue#6 = (unsigned int)w25q16_verify::bram_ptr#13 -- vwum1=vwum2 
    lda bram_ptr
    sta printf_uint.uvalue
    lda bram_ptr+1
    sta printf_uint.uvalue+1
    // [2453] call printf_uint
    // [2015] phi from w25q16_verify::@28 to printf_uint [phi:w25q16_verify::@28->printf_uint]
    // [2015] phi printf_uint::format_zero_padding#10 = 1 [phi:w25q16_verify::@28->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [2015] phi printf_uint::format_min_length#10 = 4 [phi:w25q16_verify::@28->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [2015] phi printf_uint::putc#10 = &snputc [phi:w25q16_verify::@28->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [2015] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:w25q16_verify::@28->printf_uint#3] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [2015] phi printf_uint::uvalue#10 = printf_uint::uvalue#6 [phi:w25q16_verify::@28->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [2454] phi from w25q16_verify::@28 to w25q16_verify::@29 [phi:w25q16_verify::@28->w25q16_verify::@29]
    // w25q16_verify::@29
    // sprintf(info_text, "%05x different RAM:%02x:%04p <-> VERA:%05x", w25q16_different_bytes, bram_bank, bram_ptr, w25q16_address)
    // [2455] call printf_str
    // [1125] phi from w25q16_verify::@29 to printf_str [phi:w25q16_verify::@29->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:w25q16_verify::@29->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = w25q16_verify::s2 [phi:w25q16_verify::@29->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // w25q16_verify::@30
    // sprintf(info_text, "%05x different RAM:%02x:%04p <-> VERA:%05x", w25q16_different_bytes, bram_bank, bram_ptr, w25q16_address)
    // [2456] printf_ulong::uvalue#9 = w25q16_verify::w25q16_address#1 -- vdum1=vduz2 
    lda.z w25q16_address
    sta printf_ulong.uvalue
    lda.z w25q16_address+1
    sta printf_ulong.uvalue+1
    lda.z w25q16_address+2
    sta printf_ulong.uvalue+2
    lda.z w25q16_address+3
    sta printf_ulong.uvalue+3
    // [2457] call printf_ulong
    // [1588] phi from w25q16_verify::@30 to printf_ulong [phi:w25q16_verify::@30->printf_ulong]
    // [1588] phi printf_ulong::format_zero_padding#14 = 1 [phi:w25q16_verify::@30->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1588] phi printf_ulong::format_min_length#14 = 5 [phi:w25q16_verify::@30->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1588] phi printf_ulong::format_radix#14 = HEXADECIMAL [phi:w25q16_verify::@30->printf_ulong#2] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [1588] phi printf_ulong::uvalue#14 = printf_ulong::uvalue#9 [phi:w25q16_verify::@30->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // w25q16_verify::@31
    // sprintf(info_text, "%05x different RAM:%02x:%04p <-> VERA:%05x", w25q16_different_bytes, bram_bank, bram_ptr, w25q16_address)
    // [2458] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [2459] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [2461] call display_action_text
    // [1200] phi from w25q16_verify::@31 to display_action_text [phi:w25q16_verify::@31->display_action_text]
    // [1200] phi display_action_text::info_text#25 = info_text [phi:w25q16_verify::@31->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [2402] phi from w25q16_verify::@31 to w25q16_verify::@4 [phi:w25q16_verify::@31->w25q16_verify::@4]
    // [2402] phi w25q16_verify::y#15 = w25q16_verify::y#21 [phi:w25q16_verify::@31->w25q16_verify::@4#0] -- register_copy 
    // [2402] phi w25q16_verify::progress_row_current#12 = w25q16_verify::progress_row_current#18 [phi:w25q16_verify::@31->w25q16_verify::@4#1] -- register_copy 
    // [2402] phi w25q16_verify::bram_ptr#14 = w25q16_verify::bram_ptr#13 [phi:w25q16_verify::@31->w25q16_verify::@4#2] -- register_copy 
    // [2402] phi w25q16_verify::w25q16_different_bytes#2 = w25q16_verify::w25q16_different_bytes#1 [phi:w25q16_verify::@31->w25q16_verify::@4#3] -- register_copy 
    // [2402] phi w25q16_verify::bank_set_bram2_bank#0 = w25q16_verify::bram_bank#13 [phi:w25q16_verify::@31->w25q16_verify::@4#4] -- vbum1=vbum2 
    lda bram_bank
    sta bank_set_bram2_bank
    // [2402] phi w25q16_verify::w25q16_address#2 = w25q16_verify::w25q16_address#1 [phi:w25q16_verify::@31->w25q16_verify::@4#5] -- register_copy 
    jmp __b4
    // w25q16_verify::@14
  __b14:
    // cputc(different_char)
    // [2462] stackpush(char) = w25q16_verify::different_char#16 -- _stackpushbyte_=vbuz1 
    lda.z different_char
    pha
    // [2463] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b15
    // w25q16_verify::@32
  __b32:
    // [2465] w25q16_verify::w25q16_compared_bytes#9 = w25q16_verify::w25q16_compared_bytes#1 -- vbum1=vbuaa 
    sta w25q16_compared_bytes
    // [2413] phi from w25q16_verify::@32 to w25q16_verify::@8 [phi:w25q16_verify::@32->w25q16_verify::@8]
    // [2413] phi w25q16_verify::w25q16_equal_bytes#10 = w25q16_verify::w25q16_equal_bytes#11 [phi:w25q16_verify::@32->w25q16_verify::@8#0] -- register_copy 
    // [2413] phi w25q16_verify::w25q16_compared_bytes#2 = w25q16_verify::w25q16_compared_bytes#9 [phi:w25q16_verify::@32->w25q16_verify::@8#1] -- register_copy 
    // [2413] phi w25q16_verify::bram_ptr#10 = w25q16_verify::bram_ptr#1 [phi:w25q16_verify::@32->w25q16_verify::@8#2] -- register_copy 
    jmp __b8
    // [2466] phi from w25q16_verify::@21 to w25q16_verify::@1 [phi:w25q16_verify::@21->w25q16_verify::@1]
    // w25q16_verify::@1
  __b1:
    // display_action_progress("Verifying VERA after VERA.BIN update ... (=) same, (!) error.")
    // [2467] call display_action_progress
    // [1155] phi from w25q16_verify::@1 to display_action_progress [phi:w25q16_verify::@1->display_action_progress]
    // [1155] phi display_action_progress::info_text#30 = w25q16_verify::info_text [phi:w25q16_verify::@1->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [2398] phi from w25q16_verify::@1 to w25q16_verify::@2 [phi:w25q16_verify::@1->w25q16_verify::@2]
    // [2398] phi w25q16_verify::different_char#16 = '!' [phi:w25q16_verify::@1->w25q16_verify::@2#0] -- vbuz1=vbuc1 
    lda #'!'
    sta.z different_char
    jmp __b2
  .segment Data
    info_text: .text "Verifying VERA after VERA.BIN update ... (=) same, (!) error."
    .byte 0
    info_text1: .text "Comparing VERA with VERA.BIN ... (.) data, (=) same, (*) different."
    .byte 0
    s: .text " different RAM:"
    .byte 0
    s2: .text " <-> VERA:"
    .byte 0
    w25q16_verify__7: .dword 0
    .label bank_set_bram2_bank = printf_uchar.format_min_length
    /// Holds the amount of bytes actually verified between the VERA and the RAM.
    w25q16_compare_size: .byte 0
    w25q16_byte: .byte 0
    .label bram_ptr = rom_read_byte.rom_ptr1_rom_read_byte__2
    // WARNING: if VERA_PROGRESS_CELL every needs to be a value larger than 128 then the char scalar widtg needs to be extended to an int.
    w25q16_equal_bytes: .byte 0
    y: .byte 0
    bram_bank: .byte 0
    .label w25q16_different_bytes = rom_flash.rom_flash__28
    .label return = rom_flash.rom_flash__28
    /// Holds the amount of correct and verified bytes flashed in the VERA.
    w25q16_compared_bytes: .byte 0
    .label progress_row_current = rom_read_byte.rom_bank1_rom_read_byte__2
}
.segment CodeVera
  // w25q16_erase
w25q16_erase: {
    // BYTE2(vera_file_size)
    // [2468] w25q16_erase::$0 = byte2  vera_file_size#1 -- vbuaa=_byte2_vdum1 
    lda vera_file_size+2
    // unsigned char vera_total_64k_blocks = BYTE2(vera_file_size)+1
    // [2469] w25q16_erase::vera_total_64k_blocks#0 = w25q16_erase::$0 + 1 -- vbum1=vbuaa_plus_1 
    inc
    sta vera_total_64k_blocks
    // [2470] phi from w25q16_erase to w25q16_erase::@1 [phi:w25q16_erase->w25q16_erase::@1]
    // [2470] phi w25q16_erase::vera_address#2 = 0 [phi:w25q16_erase->w25q16_erase::@1#0] -- vdum1=vduc1 
    lda #<0
    sta vera_address
    sta vera_address+1
    lda #<0>>$10
    sta vera_address+2
    lda #>0>>$10
    sta vera_address+3
    // [2470] phi w25q16_erase::vera_current_64k_block#2 = 0 [phi:w25q16_erase->w25q16_erase::@1#1] -- vbum1=vbuc1 
    lda #0
    sta vera_current_64k_block
    // w25q16_erase::@1
  __b1:
    // while(vera_current_64k_block < vera_total_64k_blocks)
    // [2471] if(w25q16_erase::vera_current_64k_block#2<w25q16_erase::vera_total_64k_blocks#0) goto w25q16_erase::@2 -- vbum1_lt_vbum2_then_la1 
    lda vera_current_64k_block
    cmp vera_total_64k_blocks
    bcc __b2
    // [2472] phi from w25q16_erase::@1 to w25q16_erase::@return [phi:w25q16_erase::@1->w25q16_erase::@return]
    // [2472] phi w25q16_erase::return#2 = 0 [phi:w25q16_erase::@1->w25q16_erase::@return#0] -- vbuaa=vbuc1 
    lda #0
    // w25q16_erase::@return
    // }
    // [2473] return 
    rts
    // [2474] phi from w25q16_erase::@1 to w25q16_erase::@2 [phi:w25q16_erase::@1->w25q16_erase::@2]
    // w25q16_erase::@2
  __b2:
    // spi_wait_non_busy()
    // [2475] call spi_wait_non_busy
    // [3265] phi from w25q16_erase::@2 to spi_wait_non_busy [phi:w25q16_erase::@2->spi_wait_non_busy]
    jsr spi_wait_non_busy
    // spi_wait_non_busy()
    // [2476] spi_wait_non_busy::return#4 = spi_wait_non_busy::return#3
    // w25q16_erase::@4
    // [2477] w25q16_erase::$3 = spi_wait_non_busy::return#4
    // if(!spi_wait_non_busy())
    // [2478] if(0==w25q16_erase::$3) goto w25q16_erase::@3 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b3
    // [2472] phi from w25q16_erase::@4 to w25q16_erase::@return [phi:w25q16_erase::@4->w25q16_erase::@return]
    // [2472] phi w25q16_erase::return#2 = 1 [phi:w25q16_erase::@4->w25q16_erase::@return#0] -- vbuaa=vbuc1 
    lda #1
    rts
    // w25q16_erase::@3
  __b3:
    // spi_block_erase(vera_address)
    // [2479] spi_block_erase::data#0 = w25q16_erase::vera_address#2 -- vduz1=vdum2 
    lda vera_address
    sta.z spi_block_erase.data
    lda vera_address+1
    sta.z spi_block_erase.data+1
    lda vera_address+2
    sta.z spi_block_erase.data+2
    lda vera_address+3
    sta.z spi_block_erase.data+3
    // [2480] call spi_block_erase
    // [3282] phi from w25q16_erase::@3 to spi_block_erase [phi:w25q16_erase::@3->spi_block_erase]
    jsr spi_block_erase
    // w25q16_erase::@5
    // vera_address += 0x10000
    // [2481] w25q16_erase::vera_address#1 = w25q16_erase::vera_address#2 + $10000 -- vdum1=vdum1_plus_vduc1 
    clc
    lda vera_address
    adc #<$10000
    sta vera_address
    lda vera_address+1
    adc #>$10000
    sta vera_address+1
    lda vera_address+2
    adc #<$10000>>$10
    sta vera_address+2
    lda vera_address+3
    adc #>$10000>>$10
    sta vera_address+3
    // vera_current_64k_block++;
    // [2482] w25q16_erase::vera_current_64k_block#1 = ++ w25q16_erase::vera_current_64k_block#2 -- vbum1=_inc_vbum1 
    inc vera_current_64k_block
    // [2470] phi from w25q16_erase::@5 to w25q16_erase::@1 [phi:w25q16_erase::@5->w25q16_erase::@1]
    // [2470] phi w25q16_erase::vera_address#2 = w25q16_erase::vera_address#1 [phi:w25q16_erase::@5->w25q16_erase::@1#0] -- register_copy 
    // [2470] phi w25q16_erase::vera_current_64k_block#2 = w25q16_erase::vera_current_64k_block#1 [phi:w25q16_erase::@5->w25q16_erase::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    vera_total_64k_blocks: .byte 0
    .label vera_address = main.rom_differences
    vera_current_64k_block: .byte 0
}
.segment Code
  // display_info_roms
/**
 * @brief Display all the ROM statuses.
 * 
 * @param info_status The status.
 * @param info_text The status text.
 */
// void display_info_roms(char info_status, char *info_text)
display_info_roms: {
    // [2484] phi from display_info_roms to display_info_roms::@1 [phi:display_info_roms->display_info_roms::@1]
    // [2484] phi display_info_roms::rom_chip#2 = 0 [phi:display_info_roms->display_info_roms::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // display_info_roms::@1
  __b1:
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [2485] if(display_info_roms::rom_chip#2<8) goto display_info_roms::@2 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcc __b2
    // display_info_roms::@return
    // }
    // [2486] return 
    rts
    // display_info_roms::@2
  __b2:
    // display_info_rom(rom_chip, info_status, info_text)
    // [2487] display_info_rom::rom_chip#4 = display_info_roms::rom_chip#2 -- vbum1=vbum2 
    lda rom_chip
    sta display_info_rom.rom_chip
    // [2488] call display_info_rom
    // [1368] phi from display_info_roms::@2 to display_info_rom [phi:display_info_roms::@2->display_info_rom]
    // [1368] phi display_info_rom::info_text#16 = 0 [phi:display_info_roms::@2->display_info_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_rom.info_text
    sta.z display_info_rom.info_text+1
    // [1368] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#4 [phi:display_info_roms::@2->display_info_rom#1] -- register_copy 
    // [1368] phi display_info_rom::info_status#16 = STATUS_ERROR [phi:display_info_roms::@2->display_info_rom#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_rom.info_status
    jsr display_info_rom
    // display_info_roms::@3
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [2489] display_info_roms::rom_chip#1 = ++ display_info_roms::rom_chip#2 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [2484] phi from display_info_roms::@3 to display_info_roms::@1 [phi:display_info_roms::@3->display_info_roms::@1]
    // [2484] phi display_info_roms::rom_chip#2 = display_info_roms::rom_chip#1 [phi:display_info_roms::@3->display_info_roms::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    rom_chip: .byte 0
}
.segment CodeVera
  // spi_deselect
spi_deselect: {
    // *vera_reg_SPICtrl &= 0xfe
    // [2490] *vera_reg_SPICtrl = *vera_reg_SPICtrl & $fe -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    /*
.proc spi_deselect
    lda Vera::Reg::SPICtrl
    and #$fe
    sta Vera::Reg::SPICtrl
    jsr spi_read
	rts
.endproc
*/
    lda #$fe
    and vera_reg_SPICtrl
    sta vera_reg_SPICtrl
    // unsigned char value = spi_read()
    // [2491] call spi_read
    jsr spi_read
    // spi_deselect::@return
    // }
    // [2492] return 
    rts
}
  // w25q16_flash
w25q16_flash: {
    // TODO: ERROR!!!
    .label return = $3c
    .label i = $d8
    .label vera_bram_ptr = $de
    .label vera_address = $5f
    .label vera_address_page = $3c
    .label vera_flashed_bytes = $d4
    .label w25q16_flash__28 = $e4
    // display_action_progress(TEXT_PROGRESS_FLASHING)
    // [2494] call display_action_progress
    // [1155] phi from w25q16_flash to display_action_progress [phi:w25q16_flash->display_action_progress]
    // [1155] phi display_action_progress::info_text#30 = TEXT_PROGRESS_FLASHING [phi:w25q16_flash->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<TEXT_PROGRESS_FLASHING
    sta.z display_action_progress.info_text
    lda #>TEXT_PROGRESS_FLASHING
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [2495] phi from w25q16_flash to w25q16_flash::@1 [phi:w25q16_flash->w25q16_flash::@1]
    // [2495] phi w25q16_flash::vera_flashed_bytes#17 = 0 [phi:w25q16_flash->w25q16_flash::@1#0] -- vduz1=vduc1 
    lda #<0
    sta.z vera_flashed_bytes
    sta.z vera_flashed_bytes+1
    lda #<0>>$10
    sta.z vera_flashed_bytes+2
    lda #>0>>$10
    sta.z vera_flashed_bytes+3
    // [2495] phi w25q16_flash::vera_bram_ptr#12 = (char *)$a000 [phi:w25q16_flash->w25q16_flash::@1#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [2495] phi w25q16_flash::vera_bram_bank#10 = 1 [phi:w25q16_flash->w25q16_flash::@1#2] -- vbum1=vbuc1 
    lda #1
    sta vera_bram_bank
    // [2495] phi w25q16_flash::y_sector#15 = PROGRESS_Y [phi:w25q16_flash->w25q16_flash::@1#3] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y_sector
    // [2495] phi w25q16_flash::x_sector#14 = PROGRESS_X [phi:w25q16_flash->w25q16_flash::@1#4] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [2495] phi w25q16_flash::vera_address_page#11 = 0 [phi:w25q16_flash->w25q16_flash::@1#5] -- vduz1=vduc1 
    lda #<0
    sta.z vera_address_page
    sta.z vera_address_page+1
    lda #<0>>$10
    sta.z vera_address_page+2
    lda #>0>>$10
    sta.z vera_address_page+3
    // w25q16_flash::@1
  __b1:
    // while (vera_address_page < vera_file_size)
    // [2496] if(w25q16_flash::vera_address_page#11<vera_file_size#1) goto w25q16_flash::@2 -- vduz1_lt_vdum2_then_la1 
    lda.z vera_address_page+3
    cmp vera_file_size+3
    bcc __b2
    bne !+
    lda.z vera_address_page+2
    cmp vera_file_size+2
    bcc __b2
    bne !+
    lda.z vera_address_page+1
    cmp vera_file_size+1
    bcc __b2
    bne !+
    lda.z vera_address_page
    cmp vera_file_size
    bcc __b2
  !:
    // w25q16_flash::@3
    // display_action_text_flashed(vera_address_page, "VERA")
    // [2497] display_action_text_flashed::bytes#2 = w25q16_flash::vera_address_page#11 -- vdum1=vduz2 
    lda.z vera_address_page
    sta display_action_text_flashed.bytes
    lda.z vera_address_page+1
    sta display_action_text_flashed.bytes+1
    lda.z vera_address_page+2
    sta display_action_text_flashed.bytes+2
    lda.z vera_address_page+3
    sta display_action_text_flashed.bytes+3
    // [2498] call display_action_text_flashed
    // [2824] phi from w25q16_flash::@3 to display_action_text_flashed [phi:w25q16_flash::@3->display_action_text_flashed]
    // [2824] phi display_action_text_flashed::chip#3 = w25q16_flash::chip [phi:w25q16_flash::@3->display_action_text_flashed#0] -- pbuz1=pbuc1 
    lda #<chip
    sta.z display_action_text_flashed.chip
    lda #>chip
    sta.z display_action_text_flashed.chip+1
    // [2824] phi display_action_text_flashed::bytes#3 = display_action_text_flashed::bytes#2 [phi:w25q16_flash::@3->display_action_text_flashed#1] -- register_copy 
    jsr display_action_text_flashed
    // [2499] phi from w25q16_flash::@3 to w25q16_flash::@18 [phi:w25q16_flash::@3->w25q16_flash::@18]
    // w25q16_flash::@18
    // wait_moment(16)
    // [2500] call wait_moment
    // [1134] phi from w25q16_flash::@18 to wait_moment [phi:w25q16_flash::@18->wait_moment]
    // [1134] phi wait_moment::w#17 = $10 [phi:w25q16_flash::@18->wait_moment#0] -- vbuz1=vbuc1 
    lda #$10
    sta.z wait_moment.w
    jsr wait_moment
    // [2501] phi from w25q16_flash::@18 to w25q16_flash::@return [phi:w25q16_flash::@18->w25q16_flash::@return]
    // [2501] phi w25q16_flash::return#2 = w25q16_flash::vera_address_page#11 [phi:w25q16_flash::@18->w25q16_flash::@return#0] -- register_copy 
    // w25q16_flash::@return
    // }
    // [2502] return 
    rts
    // w25q16_flash::@2
  __b2:
    // unsigned long vera_page_boundary = vera_address_page + VERA_PROGRESS_PAGE
    // [2503] w25q16_flash::vera_page_boundary#0 = w25q16_flash::vera_address_page#11 + VERA_PROGRESS_PAGE -- vdum1=vduz2_plus_vwuc1 
    // {asm{.byte $db}}
    clc
    lda.z vera_address_page
    adc #<VERA_PROGRESS_PAGE
    sta vera_page_boundary
    lda.z vera_address_page+1
    adc #>VERA_PROGRESS_PAGE
    sta vera_page_boundary+1
    lda.z vera_address_page+2
    adc #0
    sta vera_page_boundary+2
    lda.z vera_address_page+3
    adc #0
    sta vera_page_boundary+3
    // cputcxy(x,y,'.')
    // [2504] cputcxy::x#15 = w25q16_flash::x_sector#14 -- vbuyy=vbum1 
    ldy x_sector
    // [2505] cputcxy::y#15 = w25q16_flash::y_sector#15 -- vbuaa=vbum1 
    lda y_sector
    // [2506] call cputcxy
    // [2273] phi from w25q16_flash::@2 to cputcxy [phi:w25q16_flash::@2->cputcxy]
    // [2273] phi cputcxy::c#17 = '.' [phi:w25q16_flash::@2->cputcxy#0] -- vbuxx=vbuc1 
    ldx #'.'
    // [2273] phi cputcxy::y#17 = cputcxy::y#15 [phi:w25q16_flash::@2->cputcxy#1] -- register_copy 
    // [2273] phi cputcxy::x#17 = cputcxy::x#15 [phi:w25q16_flash::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // w25q16_flash::@16
    // cputc('.')
    // [2507] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [2508] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // spi_wait_non_busy()
    // [2510] call spi_wait_non_busy
    // [3265] phi from w25q16_flash::@16 to spi_wait_non_busy [phi:w25q16_flash::@16->spi_wait_non_busy]
    jsr spi_wait_non_busy
    // spi_wait_non_busy()
    // [2511] spi_wait_non_busy::return#5 = spi_wait_non_busy::return#3
    // w25q16_flash::@17
    // [2512] w25q16_flash::$7 = spi_wait_non_busy::return#5
    // if(!spi_wait_non_busy())
    // [2513] if(0==w25q16_flash::$7) goto w25q16_flash::bank_set_bram1 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq bank_set_bram1
    // [2501] phi from w25q16_flash::@17 to w25q16_flash::@return [phi:w25q16_flash::@17->w25q16_flash::@return]
    // [2501] phi w25q16_flash::return#2 = 0 [phi:w25q16_flash::@17->w25q16_flash::@return#0] -- vduz1=vbuc1 
    lda #0
    sta.z return
    sta.z return+1
    sta.z return+2
    sta.z return+3
    rts
    // w25q16_flash::bank_set_bram1
  bank_set_bram1:
    // BRAM = bank
    // [2514] BRAM = w25q16_flash::vera_bram_bank#10 -- vbuz1=vbum2 
    lda vera_bram_bank
    sta.z BRAM
    // w25q16_flash::@15
    // spi_write_page_begin(vera_address_page)
    // [2515] spi_write_page_begin::data#0 = w25q16_flash::vera_address_page#11 -- vduz1=vduz2 
    lda.z vera_address_page
    sta.z spi_write_page_begin.data
    lda.z vera_address_page+1
    sta.z spi_write_page_begin.data+1
    lda.z vera_address_page+2
    sta.z spi_write_page_begin.data+2
    lda.z vera_address_page+3
    sta.z spi_write_page_begin.data+3
    // [2516] call spi_write_page_begin
    // [3302] phi from w25q16_flash::@15 to spi_write_page_begin [phi:w25q16_flash::@15->spi_write_page_begin]
    jsr spi_write_page_begin
    // w25q16_flash::@19
    // [2517] w25q16_flash::vera_address#16 = w25q16_flash::vera_address_page#11 -- vduz1=vduz2 
    lda.z vera_address_page
    sta.z vera_address
    lda.z vera_address_page+1
    sta.z vera_address+1
    lda.z vera_address_page+2
    sta.z vera_address+2
    lda.z vera_address_page+3
    sta.z vera_address+3
    // [2518] phi from w25q16_flash::@19 w25q16_flash::@21 to w25q16_flash::@5 [phi:w25q16_flash::@19/w25q16_flash::@21->w25q16_flash::@5]
    // [2518] phi w25q16_flash::vera_flashed_bytes#10 = w25q16_flash::vera_flashed_bytes#17 [phi:w25q16_flash::@19/w25q16_flash::@21->w25q16_flash::@5#0] -- register_copy 
    // [2518] phi w25q16_flash::vera_address_page#10 = w25q16_flash::vera_address_page#11 [phi:w25q16_flash::@19/w25q16_flash::@21->w25q16_flash::@5#1] -- register_copy 
    // [2518] phi w25q16_flash::vera_bram_ptr#13 = w25q16_flash::vera_bram_ptr#12 [phi:w25q16_flash::@19/w25q16_flash::@21->w25q16_flash::@5#2] -- register_copy 
    // [2518] phi w25q16_flash::vera_address#10 = w25q16_flash::vera_address#16 [phi:w25q16_flash::@19/w25q16_flash::@21->w25q16_flash::@5#3] -- register_copy 
    // w25q16_flash::@5
  __b5:
    // while (vera_address < vera_page_boundary)
    // [2519] if(w25q16_flash::vera_address#10<w25q16_flash::vera_page_boundary#0) goto w25q16_flash::@6 -- vduz1_lt_vdum2_then_la1 
    lda.z vera_address+3
    cmp vera_page_boundary+3
    bcs !__b6+
    jmp __b6
  !__b6:
    bne !+
    lda.z vera_address+2
    cmp vera_page_boundary+2
    bcs !__b6+
    jmp __b6
  !__b6:
    bne !+
    lda.z vera_address+1
    cmp vera_page_boundary+1
    bcs !__b6+
    jmp __b6
  !__b6:
    bne !+
    lda.z vera_address
    cmp vera_page_boundary
    bcs !__b6+
    jmp __b6
  !__b6:
  !:
    // w25q16_flash::@4
    // if (vera_bram_ptr == BRAM_HIGH)
    // [2520] if(w25q16_flash::vera_bram_ptr#13!=$c000) goto w25q16_flash::@10 -- pbuz1_neq_vwuc1_then_la1 
    lda.z vera_bram_ptr+1
    cmp #>$c000
    bne __b10
    lda.z vera_bram_ptr
    cmp #<$c000
    bne __b10
    // w25q16_flash::@13
    // vera_bram_bank++;
    // [2521] w25q16_flash::vera_bram_bank#1 = ++ w25q16_flash::vera_bram_bank#10 -- vbum1=_inc_vbum1 
    inc vera_bram_bank
    // [2522] phi from w25q16_flash::@13 to w25q16_flash::@10 [phi:w25q16_flash::@13->w25q16_flash::@10]
    // [2522] phi w25q16_flash::vera_bram_bank#27 = w25q16_flash::vera_bram_bank#1 [phi:w25q16_flash::@13->w25q16_flash::@10#0] -- register_copy 
    // [2522] phi w25q16_flash::vera_bram_ptr#8 = (char *)$a000 [phi:w25q16_flash::@13->w25q16_flash::@10#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [2522] phi from w25q16_flash::@4 to w25q16_flash::@10 [phi:w25q16_flash::@4->w25q16_flash::@10]
    // [2522] phi w25q16_flash::vera_bram_bank#27 = w25q16_flash::vera_bram_bank#10 [phi:w25q16_flash::@4->w25q16_flash::@10#0] -- register_copy 
    // [2522] phi w25q16_flash::vera_bram_ptr#8 = w25q16_flash::vera_bram_ptr#13 [phi:w25q16_flash::@4->w25q16_flash::@10#1] -- register_copy 
    // w25q16_flash::@10
  __b10:
    // if (vera_bram_ptr == RAM_HIGH)
    // [2523] if(w25q16_flash::vera_bram_ptr#8!=$9800) goto w25q16_flash::@23 -- pbuz1_neq_vwuc1_then_la1 
    lda.z vera_bram_ptr+1
    cmp #>$9800
    bne __b11
    lda.z vera_bram_ptr
    cmp #<$9800
    bne __b11
    // [2525] phi from w25q16_flash::@10 to w25q16_flash::@11 [phi:w25q16_flash::@10->w25q16_flash::@11]
    // [2525] phi w25q16_flash::vera_bram_ptr#23 = (char *)$a000 [phi:w25q16_flash::@10->w25q16_flash::@11#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z vera_bram_ptr
    lda #>$a000
    sta.z vera_bram_ptr+1
    // [2525] phi w25q16_flash::vera_bram_bank#19 = 1 [phi:w25q16_flash::@10->w25q16_flash::@11#1] -- vbum1=vbuc1 
    lda #1
    sta vera_bram_bank
    // [2524] phi from w25q16_flash::@10 to w25q16_flash::@23 [phi:w25q16_flash::@10->w25q16_flash::@23]
    // w25q16_flash::@23
    // [2525] phi from w25q16_flash::@23 to w25q16_flash::@11 [phi:w25q16_flash::@23->w25q16_flash::@11]
    // [2525] phi w25q16_flash::vera_bram_ptr#23 = w25q16_flash::vera_bram_ptr#8 [phi:w25q16_flash::@23->w25q16_flash::@11#0] -- register_copy 
    // [2525] phi w25q16_flash::vera_bram_bank#19 = w25q16_flash::vera_bram_bank#27 [phi:w25q16_flash::@23->w25q16_flash::@11#1] -- register_copy 
    // w25q16_flash::@11
  __b11:
    // x_sector += 2
    // [2526] w25q16_flash::x_sector#1 = w25q16_flash::x_sector#14 + 2 -- vbum1=vbum1_plus_2 
    lda x_sector
    clc
    adc #2
    sta x_sector
    // vera_address_page % VERA_PROGRESS_ROW
    // [2527] w25q16_flash::$21 = w25q16_flash::vera_address_page#10 & VERA_PROGRESS_ROW-1 -- vdum1=vduz2_band_vduc1 
    lda.z vera_address_page
    and #<VERA_PROGRESS_ROW-1
    sta w25q16_flash__21
    lda.z vera_address_page+1
    and #>VERA_PROGRESS_ROW-1
    sta w25q16_flash__21+1
    lda.z vera_address_page+2
    and #<VERA_PROGRESS_ROW-1>>$10
    sta w25q16_flash__21+2
    lda.z vera_address_page+3
    and #>VERA_PROGRESS_ROW-1>>$10
    sta w25q16_flash__21+3
    // if (!(vera_address_page % VERA_PROGRESS_ROW))
    // [2528] if(0!=w25q16_flash::$21) goto w25q16_flash::@12 -- 0_neq_vdum1_then_la1 
    lda w25q16_flash__21
    ora w25q16_flash__21+1
    ora w25q16_flash__21+2
    ora w25q16_flash__21+3
    bne __b12
    // w25q16_flash::@14
    // y_sector++;
    // [2529] w25q16_flash::y_sector#1 = ++ w25q16_flash::y_sector#15 -- vbum1=_inc_vbum1 
    inc y_sector
    // [2530] phi from w25q16_flash::@14 to w25q16_flash::@12 [phi:w25q16_flash::@14->w25q16_flash::@12]
    // [2530] phi w25q16_flash::y_sector#12 = w25q16_flash::y_sector#1 [phi:w25q16_flash::@14->w25q16_flash::@12#0] -- register_copy 
    // [2530] phi w25q16_flash::x_sector#13 = PROGRESS_X [phi:w25q16_flash::@14->w25q16_flash::@12#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta x_sector
    // [2530] phi from w25q16_flash::@11 to w25q16_flash::@12 [phi:w25q16_flash::@11->w25q16_flash::@12]
    // [2530] phi w25q16_flash::y_sector#12 = w25q16_flash::y_sector#15 [phi:w25q16_flash::@11->w25q16_flash::@12#0] -- register_copy 
    // [2530] phi w25q16_flash::x_sector#13 = w25q16_flash::x_sector#1 [phi:w25q16_flash::@11->w25q16_flash::@12#1] -- register_copy 
    // w25q16_flash::@12
  __b12:
    // get_info_text_flashing(vera_flashed_bytes)
    // [2531] get_info_text_flashing::flash_bytes#2 = w25q16_flash::vera_flashed_bytes#10 -- vduz1=vduz2 
    lda.z vera_flashed_bytes
    sta.z get_info_text_flashing.flash_bytes
    lda.z vera_flashed_bytes+1
    sta.z get_info_text_flashing.flash_bytes+1
    lda.z vera_flashed_bytes+2
    sta.z get_info_text_flashing.flash_bytes+2
    lda.z vera_flashed_bytes+3
    sta.z get_info_text_flashing.flash_bytes+3
    // [2532] call get_info_text_flashing
    // [2841] phi from w25q16_flash::@12 to get_info_text_flashing [phi:w25q16_flash::@12->get_info_text_flashing]
    // [2841] phi get_info_text_flashing::flash_bytes#3 = get_info_text_flashing::flash_bytes#2 [phi:w25q16_flash::@12->get_info_text_flashing#0] -- register_copy 
    jsr get_info_text_flashing
    // [2533] phi from w25q16_flash::@12 to w25q16_flash::@22 [phi:w25q16_flash::@12->w25q16_flash::@22]
    // w25q16_flash::@22
    // display_info_vera(STATUS_FLASHING, get_info_text_flashing(vera_flashed_bytes))
    // [2534] call display_info_vera
    // [1930] phi from w25q16_flash::@22 to display_info_vera [phi:w25q16_flash::@22->display_info_vera]
    // [1930] phi display_info_vera::info_text#15 = info_text [phi:w25q16_flash::@22->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_vera.info_text
    lda #>info_text
    sta.z display_info_vera.info_text+1
    // [1930] phi display_info_vera::info_status#15 = STATUS_FLASHING [phi:w25q16_flash::@22->display_info_vera#1] -- vbum1=vbuc1 
    lda #STATUS_FLASHING
    sta display_info_vera.info_status
    jsr display_info_vera
    // [2495] phi from w25q16_flash::@22 to w25q16_flash::@1 [phi:w25q16_flash::@22->w25q16_flash::@1]
    // [2495] phi w25q16_flash::vera_flashed_bytes#17 = w25q16_flash::vera_flashed_bytes#10 [phi:w25q16_flash::@22->w25q16_flash::@1#0] -- register_copy 
    // [2495] phi w25q16_flash::vera_bram_ptr#12 = w25q16_flash::vera_bram_ptr#23 [phi:w25q16_flash::@22->w25q16_flash::@1#1] -- register_copy 
    // [2495] phi w25q16_flash::vera_bram_bank#10 = w25q16_flash::vera_bram_bank#19 [phi:w25q16_flash::@22->w25q16_flash::@1#2] -- register_copy 
    // [2495] phi w25q16_flash::y_sector#15 = w25q16_flash::y_sector#12 [phi:w25q16_flash::@22->w25q16_flash::@1#3] -- register_copy 
    // [2495] phi w25q16_flash::x_sector#14 = w25q16_flash::x_sector#13 [phi:w25q16_flash::@22->w25q16_flash::@1#4] -- register_copy 
    // [2495] phi w25q16_flash::vera_address_page#11 = w25q16_flash::vera_address_page#10 [phi:w25q16_flash::@22->w25q16_flash::@1#5] -- register_copy 
    jmp __b1
    // w25q16_flash::@6
  __b6:
    // display_action_text_flashing(VERA_PROGRESS_PAGE, "VERA", vera_bram_bank, vera_bram_ptr, vera_address)
    // [2535] display_action_text_flashing::bram_bank#2 = w25q16_flash::vera_bram_bank#10 -- vbuz1=vbum2 
    lda vera_bram_bank
    sta.z display_action_text_flashing.bram_bank
    // [2536] display_action_text_flashing::bram_ptr#2 = w25q16_flash::vera_bram_ptr#13 -- pbuz1=pbuz2 
    lda.z vera_bram_ptr
    sta.z display_action_text_flashing.bram_ptr
    lda.z vera_bram_ptr+1
    sta.z display_action_text_flashing.bram_ptr+1
    // [2537] display_action_text_flashing::address#2 = w25q16_flash::vera_address#10 -- vduz1=vduz2 
    lda.z vera_address
    sta.z display_action_text_flashing.address
    lda.z vera_address+1
    sta.z display_action_text_flashing.address+1
    lda.z vera_address+2
    sta.z display_action_text_flashing.address+2
    lda.z vera_address+3
    sta.z display_action_text_flashing.address+3
    // [2538] call display_action_text_flashing
    // [2863] phi from w25q16_flash::@6 to display_action_text_flashing [phi:w25q16_flash::@6->display_action_text_flashing]
    // [2863] phi display_action_text_flashing::address#10 = display_action_text_flashing::address#2 [phi:w25q16_flash::@6->display_action_text_flashing#0] -- register_copy 
    // [2863] phi display_action_text_flashing::chip#10 = w25q16_flash::chip [phi:w25q16_flash::@6->display_action_text_flashing#1] -- pbuz1=pbuc1 
    lda #<chip
    sta.z display_action_text_flashing.chip
    lda #>chip
    sta.z display_action_text_flashing.chip+1
    // [2863] phi display_action_text_flashing::bram_ptr#3 = display_action_text_flashing::bram_ptr#2 [phi:w25q16_flash::@6->display_action_text_flashing#2] -- register_copy 
    // [2863] phi display_action_text_flashing::bram_bank#3 = display_action_text_flashing::bram_bank#2 [phi:w25q16_flash::@6->display_action_text_flashing#3] -- register_copy 
    // [2863] phi display_action_text_flashing::bytes#3 = VERA_PROGRESS_PAGE [phi:w25q16_flash::@6->display_action_text_flashing#4] -- vduz1=vduc1 
    lda #<VERA_PROGRESS_PAGE
    sta.z display_action_text_flashing.bytes
    lda #>VERA_PROGRESS_PAGE
    sta.z display_action_text_flashing.bytes+1
    lda #<VERA_PROGRESS_PAGE>>$10
    sta.z display_action_text_flashing.bytes+2
    lda #>VERA_PROGRESS_PAGE>>$10
    sta.z display_action_text_flashing.bytes+3
    jsr display_action_text_flashing
    // [2539] phi from w25q16_flash::@6 to w25q16_flash::@7 [phi:w25q16_flash::@6->w25q16_flash::@7]
    // [2539] phi w25q16_flash::i#2 = 0 [phi:w25q16_flash::@6->w25q16_flash::@7#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z i
    sta.z i+1
    // w25q16_flash::@7
  __b7:
    // for(unsigned int i=0; i<=255; i++)
    // [2540] if(w25q16_flash::i#2<=$ff) goto w25q16_flash::@8 -- vwuz1_le_vbuc1_then_la1 
    lda #$ff
    cmp.z i
    bcc !+
    lda.z i+1
    beq __b8
  !:
    // w25q16_flash::@9
    // cputcxy(x,y,'+')
    // [2541] cputcxy::x#16 = w25q16_flash::x_sector#14 -- vbuyy=vbum1 
    ldy x_sector
    // [2542] cputcxy::y#16 = w25q16_flash::y_sector#15 -- vbuaa=vbum1 
    lda y_sector
    // [2543] call cputcxy
    // [2273] phi from w25q16_flash::@9 to cputcxy [phi:w25q16_flash::@9->cputcxy]
    // [2273] phi cputcxy::c#17 = '+' [phi:w25q16_flash::@9->cputcxy#0] -- vbuxx=vbuc1 
    ldx #'+'
    // [2273] phi cputcxy::y#17 = cputcxy::y#16 [phi:w25q16_flash::@9->cputcxy#1] -- register_copy 
    // [2273] phi cputcxy::x#17 = cputcxy::x#16 [phi:w25q16_flash::@9->cputcxy#2] -- register_copy 
    jsr cputcxy
    // w25q16_flash::@21
    // cputc('+')
    // [2544] stackpush(char) = '+' -- _stackpushbyte_=vbuc1 
    lda #'+'
    pha
    // [2545] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // vera_bram_ptr += VERA_PROGRESS_PAGE
    // [2547] w25q16_flash::vera_bram_ptr#1 = w25q16_flash::vera_bram_ptr#13 + VERA_PROGRESS_PAGE -- pbuz1=pbuz1_plus_vwuc1 
    lda.z vera_bram_ptr
    clc
    adc #<VERA_PROGRESS_PAGE
    sta.z vera_bram_ptr
    lda.z vera_bram_ptr+1
    adc #>VERA_PROGRESS_PAGE
    sta.z vera_bram_ptr+1
    // vera_address += VERA_PROGRESS_PAGE
    // [2548] w25q16_flash::vera_address#1 = w25q16_flash::vera_address#10 + VERA_PROGRESS_PAGE -- vduz1=vduz1_plus_vwuc1 
    clc
    lda.z vera_address
    adc #<VERA_PROGRESS_PAGE
    sta.z vera_address
    lda.z vera_address+1
    adc #>VERA_PROGRESS_PAGE
    sta.z vera_address+1
    lda.z vera_address+2
    adc #0
    sta.z vera_address+2
    lda.z vera_address+3
    adc #0
    sta.z vera_address+3
    // vera_address_page += VERA_PROGRESS_PAGE
    // [2549] w25q16_flash::vera_address_page#1 = w25q16_flash::vera_address_page#10 + VERA_PROGRESS_PAGE -- vduz1=vduz1_plus_vwuc1 
    clc
    lda.z vera_address_page
    adc #<VERA_PROGRESS_PAGE
    sta.z vera_address_page
    lda.z vera_address_page+1
    adc #>VERA_PROGRESS_PAGE
    sta.z vera_address_page+1
    lda.z vera_address_page+2
    adc #0
    sta.z vera_address_page+2
    lda.z vera_address_page+3
    adc #0
    sta.z vera_address_page+3
    // vera_flashed_bytes += VERA_PROGRESS_PAGE
    // [2550] w25q16_flash::vera_flashed_bytes#1 = w25q16_flash::vera_flashed_bytes#10 + VERA_PROGRESS_PAGE -- vduz1=vduz1_plus_vwuc1 
    clc
    lda.z vera_flashed_bytes
    adc #<VERA_PROGRESS_PAGE
    sta.z vera_flashed_bytes
    lda.z vera_flashed_bytes+1
    adc #>VERA_PROGRESS_PAGE
    sta.z vera_flashed_bytes+1
    lda.z vera_flashed_bytes+2
    adc #0
    sta.z vera_flashed_bytes+2
    lda.z vera_flashed_bytes+3
    adc #0
    sta.z vera_flashed_bytes+3
    jmp __b5
    // w25q16_flash::@8
  __b8:
    // spi_write(vera_bram_ptr[i])
    // [2551] w25q16_flash::$28 = w25q16_flash::vera_bram_ptr#13 + w25q16_flash::i#2 -- pbuz1=pbuz2_plus_vwuz3 
    lda.z vera_bram_ptr
    clc
    adc.z i
    sta.z w25q16_flash__28
    lda.z vera_bram_ptr+1
    adc.z i+1
    sta.z w25q16_flash__28+1
    // [2552] spi_write::data = *w25q16_flash::$28 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (w25q16_flash__28),y
    sta.z spi_write.data
    // [2553] call spi_write
    jsr spi_write
    // w25q16_flash::@20
    // for(unsigned int i=0; i<=255; i++)
    // [2554] w25q16_flash::i#1 = ++ w25q16_flash::i#2 -- vwuz1=_inc_vwuz1 
    inc.z i
    bne !+
    inc.z i+1
  !:
    // [2539] phi from w25q16_flash::@20 to w25q16_flash::@7 [phi:w25q16_flash::@20->w25q16_flash::@7]
    // [2539] phi w25q16_flash::i#2 = w25q16_flash::i#1 [phi:w25q16_flash::@20->w25q16_flash::@7#0] -- register_copy 
    jmp __b7
  .segment Data
    chip: .text "VERA"
    .byte 0
    w25q16_flash__21: .dword 0
    vera_page_boundary: .dword 0
    vera_bram_bank: .byte 0
    x_sector: .byte 0
    y_sector: .byte 0
}
.segment Code
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __mem() unsigned int strlen(__zp($25) char *str)
strlen: {
    .label str = $25
    // [2556] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [2556] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta len
    sta len+1
    // [2556] phi strlen::str#6 = strlen::str#8 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [2557] if(0!=*strlen::str#6) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [2558] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [2559] strlen::len#1 = ++ strlen::len#2 -- vwum1=_inc_vwum1 
    inc len
    bne !+
    inc len+1
  !:
    // str++;
    // [2560] strlen::str#1 = ++ strlen::str#6 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [2556] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [2556] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [2556] phi strlen::str#6 = strlen::str#1 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label return = strncmp.n
    .label len = strncmp.n
}
.segment Code
  // printf_padding
// Print a padding char a number of times
// void printf_padding(__zp($25) void (*putc)(char), __mem() char pad, __mem() char length)
printf_padding: {
    .label putc = $25
    // [2562] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [2562] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbum1=vbuc1 
    lda #0
    sta i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [2563] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbum1_lt_vbum2_then_la1 
    lda i
    cmp length
    bcc __b2
    // printf_padding::@return
    // }
    // [2564] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [2565] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbum1 
    lda pad
    pha
    // [2566] callexecute *printf_padding::putc#7  -- call__deref_pprz1 
    jsr icall41
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [2568] printf_padding::i#1 = ++ printf_padding::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [2562] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [2562] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
    jmp __b1
    // Outside Flow
  icall41:
    jmp (putc)
  .segment Data
    i: .byte 0
    length: .byte 0
    pad: .byte 0
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
// __mem() unsigned long rom_address_from_bank(__register(A) char rom_bank)
rom_address_from_bank: {
    .label return_1 = $4a
    // ((unsigned long)(rom_bank)) << 14
    // [2570] rom_address_from_bank::$1 = (unsigned long)rom_address_from_bank::rom_bank#3 -- vdum1=_dword_vbuaa 
    sta rom_address_from_bank__1
    lda #0
    sta rom_address_from_bank__1+1
    sta rom_address_from_bank__1+2
    sta rom_address_from_bank__1+3
    // [2571] rom_address_from_bank::return#0 = rom_address_from_bank::$1 << $e -- vdum1=vdum1_rol_vbuc1 
    ldx #$e
    cpx #0
    beq !e+
  !:
    asl return
    rol return+1
    rol return+2
    rol return+3
    dex
    bne !-
  !e:
    // rom_address_from_bank::@return
    // }
    // [2572] return 
    rts
  .segment Data
    .label rom_address_from_bank__1 = rom_read_byte.address
    .label return = rom_read_byte.address
    .label return_2 = main.rom_file_modulo
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
// __zp($46) struct $2 * fopen(__zp($6b) const char *path, const char *mode)
fopen: {
    .label fopen__16 = $32
    .label fopen__26 = $2c
    .label fopen__28 = $de
    .label fopen__30 = $46
    .label cbm_k_setnam1_fopen__0 = $67
    .label stream = $46
    .label pathtoken = $6b
    .label pathtoken_1 = $ec
    .label path = $6b
    .label return = $46
    // unsigned char sp = __stdio_filecount
    // [2574] fopen::sp#0 = __stdio_filecount#27 -- vbum1=vbum2 
    lda __stdio_filecount
    sta sp
    // (unsigned int)sp | 0x8000
    // [2575] fopen::$30 = (unsigned int)fopen::sp#0 -- vwuz1=_word_vbum2 
    sta.z fopen__30
    lda #0
    sta.z fopen__30+1
    // [2576] fopen::stream#0 = fopen::$30 | $8000 -- vwuz1=vwuz1_bor_vwuc1 
    lda.z stream
    ora #<$8000
    sta.z stream
    lda.z stream+1
    ora #>$8000
    sta.z stream+1
    // char pathpos = sp * __STDIO_FILECOUNT
    // [2577] fopen::pathpos#0 = fopen::sp#0 << 1 -- vbum1=vbum2_rol_1 
    lda sp
    asl
    sta pathpos
    // __logical = 0
    // [2578] ((char *)&__stdio_file+$40)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy sp
    sta __stdio_file+$40,y
    // __device = 0
    // [2579] ((char *)&__stdio_file+$42)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [2580] ((char *)&__stdio_file+$44)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$44,y
    // [2581] fopen::pathtoken#22 = fopen::pathtoken#0 -- pbuz1=pbuz2 
    lda.z pathtoken
    sta.z pathtoken_1
    lda.z pathtoken+1
    sta.z pathtoken_1+1
    // [2582] fopen::pathpos#21 = fopen::pathpos#0 -- vbum1=vbum2 
    lda pathpos
    sta pathpos_1
    // [2583] phi from fopen to fopen::@8 [phi:fopen->fopen::@8]
    // [2583] phi fopen::num#10 = 0 [phi:fopen->fopen::@8#0] -- vbuxx=vbuc1 
    ldx #0
    // [2583] phi fopen::pathpos#10 = fopen::pathpos#21 [phi:fopen->fopen::@8#1] -- register_copy 
    // [2583] phi fopen::path#10 = fopen::pathtoken#0 [phi:fopen->fopen::@8#2] -- register_copy 
    // [2583] phi fopen::pathstep#10 = 0 [phi:fopen->fopen::@8#3] -- vbum1=vbuc1 
    txa
    sta pathstep
    // [2583] phi fopen::pathtoken#10 = fopen::pathtoken#22 [phi:fopen->fopen::@8#4] -- register_copy 
  // Iterate while path is not \0.
    // [2583] phi from fopen::@22 to fopen::@8 [phi:fopen::@22->fopen::@8]
    // [2583] phi fopen::num#10 = fopen::num#13 [phi:fopen::@22->fopen::@8#0] -- register_copy 
    // [2583] phi fopen::pathpos#10 = fopen::pathpos#7 [phi:fopen::@22->fopen::@8#1] -- register_copy 
    // [2583] phi fopen::path#10 = fopen::path#12 [phi:fopen::@22->fopen::@8#2] -- register_copy 
    // [2583] phi fopen::pathstep#10 = fopen::pathstep#11 [phi:fopen::@22->fopen::@8#3] -- register_copy 
    // [2583] phi fopen::pathtoken#10 = fopen::pathtoken#1 [phi:fopen::@22->fopen::@8#4] -- register_copy 
    // fopen::@8
  __b8:
    // if (*pathtoken == ',' || *pathtoken == '\0')
    // [2584] if(*fopen::pathtoken#10==',') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #','
    ldy #0
    cmp (pathtoken_1),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@33
    // [2585] if(*fopen::pathtoken#10=='@') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #'@'
    cmp (pathtoken_1),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@23
    // if (pathstep == 0)
    // [2586] if(fopen::pathstep#10!=0) goto fopen::@10 -- vbum1_neq_0_then_la1 
    lda pathstep
    bne __b10
    // fopen::@24
    // __stdio_file.filename[pathpos] = *pathtoken
    // [2587] ((char *)&__stdio_file)[fopen::pathpos#10] = *fopen::pathtoken#10 -- pbuc1_derefidx_vbum1=_deref_pbuz2 
    lda (pathtoken_1),y
    ldy pathpos_1
    sta __stdio_file,y
    // pathpos++;
    // [2588] fopen::pathpos#1 = ++ fopen::pathpos#10 -- vbum1=_inc_vbum1 
    inc pathpos_1
    // [2589] phi from fopen::@12 fopen::@23 fopen::@24 to fopen::@10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10]
    // [2589] phi fopen::num#13 = fopen::num#15 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#0] -- register_copy 
    // [2589] phi fopen::pathpos#7 = fopen::pathpos#10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#1] -- register_copy 
    // [2589] phi fopen::path#12 = fopen::path#14 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#2] -- register_copy 
    // [2589] phi fopen::pathstep#11 = fopen::pathstep#1 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#3] -- register_copy 
    // fopen::@10
  __b10:
    // pathtoken++;
    // [2590] fopen::pathtoken#1 = ++ fopen::pathtoken#10 -- pbuz1=_inc_pbuz1 
    inc.z pathtoken_1
    bne !+
    inc.z pathtoken_1+1
  !:
    // fopen::@22
    // pathtoken - 1
    // [2591] fopen::$28 = fopen::pathtoken#1 - 1 -- pbuz1=pbuz2_minus_1 
    lda.z pathtoken_1
    sec
    sbc #1
    sta.z fopen__28
    lda.z pathtoken_1+1
    sbc #0
    sta.z fopen__28+1
    // while (*(pathtoken - 1))
    // [2592] if(0!=*fopen::$28) goto fopen::@8 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (fopen__28),y
    cmp #0
    bne __b8
    // fopen::@26
    // __status = 0
    // [2593] ((char *)&__stdio_file+$46)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    tya
    ldy sp
    sta __stdio_file+$46,y
    // if(!__logical)
    // [2594] if(0!=((char *)&__stdio_file+$40)[fopen::sp#0]) goto fopen::@1 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$40,y
    cmp #0
    bne __b1
    // fopen::@27
    // __stdio_filecount+1
    // [2595] fopen::$4 = __stdio_filecount#27 + 1 -- vbuaa=vbum1_plus_1 
    lda __stdio_filecount
    inc
    // __logical = __stdio_filecount+1
    // [2596] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::$4 -- pbuc1_derefidx_vbum1=vbuaa 
    sta __stdio_file+$40,y
    // fopen::@1
  __b1:
    // if(!__device)
    // [2597] if(0!=((char *)&__stdio_file+$42)[fopen::sp#0]) goto fopen::@2 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    ldy sp
    lda __stdio_file+$42,y
    cmp #0
    bne __b2
    // fopen::@5
    // __device = 8
    // [2598] ((char *)&__stdio_file+$42)[fopen::sp#0] = 8 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #8
    sta __stdio_file+$42,y
    // fopen::@2
  __b2:
    // if(!__channel)
    // [2599] if(0!=((char *)&__stdio_file+$44)[fopen::sp#0]) goto fopen::@3 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    ldy sp
    lda __stdio_file+$44,y
    cmp #0
    bne __b3
    // fopen::@6
    // __stdio_filecount+2
    // [2600] fopen::$9 = __stdio_filecount#27 + 2 -- vbuaa=vbum1_plus_2 
    lda __stdio_filecount
    clc
    adc #2
    // __channel = __stdio_filecount+2
    // [2601] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::$9 -- pbuc1_derefidx_vbum1=vbuaa 
    sta __stdio_file+$44,y
    // fopen::@3
  __b3:
    // __filename
    // [2602] fopen::$11 = (char *)&__stdio_file + fopen::pathpos#0 -- pbum1=pbuc1_plus_vbum2 
    lda pathpos
    clc
    adc #<__stdio_file
    sta fopen__11
    lda #>__stdio_file
    adc #0
    sta fopen__11+1
    // cbm_k_setnam(__filename)
    // [2603] fopen::cbm_k_setnam1_filename = fopen::$11 -- pbum1=pbum2 
    lda fopen__11
    sta cbm_k_setnam1_filename
    lda fopen__11+1
    sta cbm_k_setnam1_filename+1
    // fopen::cbm_k_setnam1
    // strlen(filename)
    // [2604] strlen::str#4 = fopen::cbm_k_setnam1_filename -- pbuz1=pbum2 
    lda cbm_k_setnam1_filename
    sta.z strlen.str
    lda cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [2605] call strlen
    // [2555] phi from fopen::cbm_k_setnam1 to strlen [phi:fopen::cbm_k_setnam1->strlen]
    // [2555] phi strlen::str#8 = strlen::str#4 [phi:fopen::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [2606] strlen::return#11 = strlen::len#2
    // fopen::@31
    // [2607] fopen::cbm_k_setnam1_$0 = strlen::return#11 -- vwuz1=vwum2 
    lda strlen.return
    sta.z cbm_k_setnam1_fopen__0
    lda strlen.return+1
    sta.z cbm_k_setnam1_fopen__0+1
    // char filename_len = (char)strlen(filename)
    // [2608] fopen::cbm_k_setnam1_filename_len = (char)fopen::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
    lda.z cbm_k_setnam1_fopen__0
    sta cbm_k_setnam1_filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx cbm_k_setnam1_filename
    ldy cbm_k_setnam1_filename+1
    jsr CBM_SETNAM
    // fopen::@28
    // cbm_k_setlfs(__logical, __device, __channel)
    // [2610] cbm_k_setlfs::channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$40,y
    sta cbm_k_setlfs.channel
    // [2611] cbm_k_setlfs::device = ((char *)&__stdio_file+$42)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    lda __stdio_file+$42,y
    sta cbm_k_setlfs.device
    // [2612] cbm_k_setlfs::command = ((char *)&__stdio_file+$44)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    lda __stdio_file+$44,y
    sta cbm_k_setlfs.command
    // [2613] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // fopen::cbm_k_open1
    // asm
    // asm { jsrCBM_OPEN  }
    jsr CBM_OPEN
    // fopen::cbm_k_readst1
    // char status
    // [2615] fopen::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2617] fopen::cbm_k_readst1_return#0 = fopen::cbm_k_readst1_status -- vbuaa=vbum1 
    // fopen::cbm_k_readst1_@return
    // }
    // [2618] fopen::cbm_k_readst1_return#1 = fopen::cbm_k_readst1_return#0
    // fopen::@29
    // cbm_k_readst()
    // [2619] fopen::$15 = fopen::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [2620] ((char *)&__stdio_file+$46)[fopen::sp#0] = fopen::$15 -- pbuc1_derefidx_vbum1=vbuaa 
    ldy sp
    sta __stdio_file+$46,y
    // ferror(stream)
    // [2621] ferror::stream#0 = (struct $2 *)fopen::stream#0
    // [2622] call ferror
    jsr ferror
    // [2623] ferror::return#0 = ferror::return#1
    // fopen::@32
    // [2624] fopen::$16 = ferror::return#0 -- vwsz1=vwsm2 
    lda ferror.return
    sta.z fopen__16
    lda ferror.return+1
    sta.z fopen__16+1
    // if (ferror(stream))
    // [2625] if(0==fopen::$16) goto fopen::@4 -- 0_eq_vwsz1_then_la1 
    lda.z fopen__16
    ora.z fopen__16+1
    beq __b4
    // fopen::@7
    // cbm_k_close(__logical)
    // [2626] fopen::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$40,y
    sta cbm_k_close1_channel
    // fopen::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // [2628] phi from fopen::cbm_k_close1 to fopen::@return [phi:fopen::cbm_k_close1->fopen::@return]
    // [2628] phi __stdio_filecount#1 = __stdio_filecount#27 [phi:fopen::cbm_k_close1->fopen::@return#0] -- register_copy 
    // [2628] phi fopen::return#2 = 0 [phi:fopen::cbm_k_close1->fopen::@return#1] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [2629] return 
    rts
    // fopen::@4
  __b4:
    // __stdio_filecount++;
    // [2630] __stdio_filecount#0 = ++ __stdio_filecount#27 -- vbum1=_inc_vbum1 
    inc __stdio_filecount
    // [2631] fopen::return#10 = (struct $2 *)fopen::stream#0
    // [2628] phi from fopen::@4 to fopen::@return [phi:fopen::@4->fopen::@return]
    // [2628] phi __stdio_filecount#1 = __stdio_filecount#0 [phi:fopen::@4->fopen::@return#0] -- register_copy 
    // [2628] phi fopen::return#2 = fopen::return#10 [phi:fopen::@4->fopen::@return#1] -- register_copy 
    rts
    // fopen::@9
  __b9:
    // if (pathstep > 0)
    // [2632] if(fopen::pathstep#10>0) goto fopen::@11 -- vbum1_gt_0_then_la1 
    lda pathstep
    bne __b11
    // fopen::@25
    // __stdio_file.filename[pathpos] = '\0'
    // [2633] ((char *)&__stdio_file)[fopen::pathpos#10] = '@' -- pbuc1_derefidx_vbum1=vbuc2 
    lda #'@'
    ldy pathpos_1
    sta __stdio_file,y
    // path = pathtoken + 1
    // [2634] fopen::path#0 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
    clc
    lda.z pathtoken_1
    adc #1
    sta.z path
    lda.z pathtoken_1+1
    adc #0
    sta.z path+1
    // [2635] phi from fopen::@16 fopen::@17 fopen::@18 fopen::@19 fopen::@25 to fopen::@12 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12]
    // [2635] phi fopen::num#15 = fopen::num#2 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#0] -- register_copy 
    // [2635] phi fopen::path#14 = fopen::path#17 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#1] -- register_copy 
    // fopen::@12
  __b12:
    // pathstep++;
    // [2636] fopen::pathstep#1 = ++ fopen::pathstep#10 -- vbum1=_inc_vbum1 
    inc pathstep
    jmp __b10
    // fopen::@11
  __b11:
    // char pathcmp = *path
    // [2637] fopen::pathcmp#0 = *fopen::path#10 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (path),y
    sta pathcmp
    // case 'D':
    // [2638] if(fopen::pathcmp#0=='D') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'D'
    cmp pathcmp
    beq __b13
    // fopen::@20
    // case 'L':
    // [2639] if(fopen::pathcmp#0=='L') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'L'
    cmp pathcmp
    beq __b13
    // fopen::@21
    // case 'C':
    //                     num = (char)atoi(path + 1);
    //                     path = pathtoken + 1;
    // [2640] if(fopen::pathcmp#0=='C') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'C'
    cmp pathcmp
    beq __b13
    // [2641] phi from fopen::@21 fopen::@30 to fopen::@14 [phi:fopen::@21/fopen::@30->fopen::@14]
    // [2641] phi fopen::path#17 = fopen::path#10 [phi:fopen::@21/fopen::@30->fopen::@14#0] -- register_copy 
    // [2641] phi fopen::num#2 = fopen::num#10 [phi:fopen::@21/fopen::@30->fopen::@14#1] -- register_copy 
    // fopen::@14
  __b14:
    // case 'L':
    //                     __logical = num;
    //                     break;
    // [2642] if(fopen::pathcmp#0=='L') goto fopen::@17 -- vbum1_eq_vbuc1_then_la1 
    lda #'L'
    cmp pathcmp
    beq __b17
    // fopen::@15
    // case 'D':
    //                     __device = num;
    //                     break;
    // [2643] if(fopen::pathcmp#0=='D') goto fopen::@18 -- vbum1_eq_vbuc1_then_la1 
    lda #'D'
    cmp pathcmp
    beq __b18
    // fopen::@16
    // case 'C':
    //                     __channel = num;
    //                     break;
    // [2644] if(fopen::pathcmp#0!='C') goto fopen::@12 -- vbum1_neq_vbuc1_then_la1 
    lda #'C'
    cmp pathcmp
    bne __b12
    // fopen::@19
    // __channel = num
    // [2645] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbuxx 
    ldy sp
    txa
    sta __stdio_file+$44,y
    jmp __b12
    // fopen::@18
  __b18:
    // __device = num
    // [2646] ((char *)&__stdio_file+$42)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbuxx 
    ldy sp
    txa
    sta __stdio_file+$42,y
    jmp __b12
    // fopen::@17
  __b17:
    // __logical = num
    // [2647] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbuxx 
    ldy sp
    txa
    sta __stdio_file+$40,y
    jmp __b12
    // fopen::@13
  __b13:
    // atoi(path + 1)
    // [2648] atoi::str#0 = fopen::path#10 + 1 -- pbuz1=pbuz1_plus_1 
    inc.z atoi.str
    bne !+
    inc.z atoi.str+1
  !:
    // [2649] call atoi
    // [3376] phi from fopen::@13 to atoi [phi:fopen::@13->atoi]
    // [3376] phi atoi::str#2 = atoi::str#0 [phi:fopen::@13->atoi#0] -- register_copy 
    jsr atoi
    // atoi(path + 1)
    // [2650] atoi::return#3 = atoi::return#2
    // fopen::@30
    // [2651] fopen::$26 = atoi::return#3 -- vwsz1=vwsm2 
    lda atoi.return
    sta.z fopen__26
    lda atoi.return+1
    sta.z fopen__26+1
    // num = (char)atoi(path + 1)
    // [2652] fopen::num#1 = (char)fopen::$26 -- vbuxx=_byte_vwsz1 
    lda.z fopen__26
    tax
    // path = pathtoken + 1
    // [2653] fopen::path#1 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
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
    .label sp = uctoa.started
    .label pathpos = printf_padding.length
    .label pathpos_1 = printf_uchar.format_zero_padding
    .label pathcmp = printf_padding.pad
    // Parse path
    .label pathstep = printf_uchar.format_min_length
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
// int fclose(__zp($e4) struct $2 *stream)
fclose: {
    .label stream = $e4
    // unsigned char sp = (unsigned char)stream
    // [2655] fclose::sp#0 = (char)fclose::stream#3 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_chkin(__logical)
    // [2656] fclose::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    tay
    lda __stdio_file+$40,y
    sta cbm_k_chkin1_channel
    // fclose::cbm_k_chkin1
    // char status
    // [2657] fclose::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fclose::cbm_k_readst1
    // char status
    // [2659] fclose::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2661] fclose::cbm_k_readst1_return#0 = fclose::cbm_k_readst1_status -- vbuaa=vbum1 
    // fclose::cbm_k_readst1_@return
    // }
    // [2662] fclose::cbm_k_readst1_return#1 = fclose::cbm_k_readst1_return#0
    // fclose::@3
    // cbm_k_readst()
    // [2663] fclose::$1 = fclose::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [2664] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$1 -- pbuc1_derefidx_vbum1=vbuaa 
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2665] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@1 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b1
    // [2666] phi from fclose::@2 fclose::@3 fclose::@4 to fclose::@return [phi:fclose::@2/fclose::@3/fclose::@4->fclose::@return]
    // [2666] phi __stdio_filecount#2 = __stdio_filecount#3 [phi:fclose::@2/fclose::@3/fclose::@4->fclose::@return#0] -- register_copy 
    // fclose::@return
    // }
    // [2667] return 
    rts
    // fclose::@1
  __b1:
    // cbm_k_close(__logical)
    // [2668] fclose::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$40,y
    sta cbm_k_close1_channel
    // fclose::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // fclose::cbm_k_readst2
    // char status
    // [2670] fclose::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [2672] fclose::cbm_k_readst2_return#0 = fclose::cbm_k_readst2_status -- vbuaa=vbum1 
    // fclose::cbm_k_readst2_@return
    // }
    // [2673] fclose::cbm_k_readst2_return#1 = fclose::cbm_k_readst2_return#0
    // fclose::@4
    // cbm_k_readst()
    // [2674] fclose::$4 = fclose::cbm_k_readst2_return#1
    // __status = cbm_k_readst()
    // [2675] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$4 -- pbuc1_derefidx_vbum1=vbuaa 
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2676] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@2 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b2
    rts
    // fclose::@2
  __b2:
    // __logical = 0
    // [2677] ((char *)&__stdio_file+$40)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy sp
    sta __stdio_file+$40,y
    // __device = 0
    // [2678] ((char *)&__stdio_file+$42)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [2679] ((char *)&__stdio_file+$44)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$44,y
    // __filename
    // [2680] fclose::$6 = fclose::sp#0 << 1 -- vbuaa=vbum1_rol_1 
    tya
    asl
    // *__filename = '\0'
    // [2681] ((char *)&__stdio_file)[fclose::$6] = '@' -- pbuc1_derefidx_vbuaa=vbuc2 
    tay
    lda #'@'
    sta __stdio_file,y
    // __stdio_filecount--;
    // [2682] __stdio_filecount#3 = -- __stdio_filecount#1 -- vbum1=_dec_vbum1 
    dec __stdio_filecount
    rts
  .segment Data
    cbm_k_chkin1_channel: .byte 0
    cbm_k_chkin1_status: .byte 0
    cbm_k_readst1_status: .byte 0
    cbm_k_close1_channel: .byte 0
    cbm_k_readst2_status: .byte 0
    .label sp = printf_uchar.format_min_length
}
.segment Code
  // display_action_text_reading
// void display_action_text_reading(__zp($48) char *action, __zp($6d) char *file, __zp($e7) unsigned long bytes, __zp($ee) unsigned long size, __zp($e6) char bram_bank, __zp($db) char *bram_ptr)
display_action_text_reading: {
    .label action = $48
    .label bytes = $e7
    .label bram_ptr = $db
    .label file = $6d
    .label size = $ee
    .label bram_bank = $e6
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2684] call snprintf_init
    // [1184] phi from display_action_text_reading to snprintf_init [phi:display_action_text_reading->snprintf_init]
    // [1184] phi snprintf_init::s#30 = info_text [phi:display_action_text_reading->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // display_action_text_reading::@1
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2685] printf_string::str#14 = display_action_text_reading::action#3
    // [2686] call printf_string
    // [1419] phi from display_action_text_reading::@1 to printf_string [phi:display_action_text_reading::@1->printf_string]
    // [1419] phi printf_string::putc#26 = &snputc [phi:display_action_text_reading::@1->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1419] phi printf_string::str#26 = printf_string::str#14 [phi:display_action_text_reading::@1->printf_string#1] -- register_copy 
    // [1419] phi printf_string::format_justify_left#26 = 0 [phi:display_action_text_reading::@1->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1419] phi printf_string::format_min_length#26 = 0 [phi:display_action_text_reading::@1->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [2687] phi from display_action_text_reading::@1 to display_action_text_reading::@2 [phi:display_action_text_reading::@1->display_action_text_reading::@2]
    // display_action_text_reading::@2
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2688] call printf_str
    // [1125] phi from display_action_text_reading::@2 to printf_str [phi:display_action_text_reading::@2->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:display_action_text_reading::@2->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = s [phi:display_action_text_reading::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@3
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2689] printf_string::str#15 = display_action_text_reading::file#3 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [2690] call printf_string
    // [1419] phi from display_action_text_reading::@3 to printf_string [phi:display_action_text_reading::@3->printf_string]
    // [1419] phi printf_string::putc#26 = &snputc [phi:display_action_text_reading::@3->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1419] phi printf_string::str#26 = printf_string::str#15 [phi:display_action_text_reading::@3->printf_string#1] -- register_copy 
    // [1419] phi printf_string::format_justify_left#26 = 0 [phi:display_action_text_reading::@3->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1419] phi printf_string::format_min_length#26 = 0 [phi:display_action_text_reading::@3->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [2691] phi from display_action_text_reading::@3 to display_action_text_reading::@4 [phi:display_action_text_reading::@3->display_action_text_reading::@4]
    // display_action_text_reading::@4
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2692] call printf_str
    // [1125] phi from display_action_text_reading::@4 to printf_str [phi:display_action_text_reading::@4->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:display_action_text_reading::@4->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = s2 [phi:display_action_text_reading::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s2
    sta.z printf_str.s
    lda #>@s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@5
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2693] printf_ulong::uvalue#3 = display_action_text_reading::bytes#3 -- vdum1=vduz2 
    lda.z bytes
    sta printf_ulong.uvalue
    lda.z bytes+1
    sta printf_ulong.uvalue+1
    lda.z bytes+2
    sta printf_ulong.uvalue+2
    lda.z bytes+3
    sta printf_ulong.uvalue+3
    // [2694] call printf_ulong
    // [1588] phi from display_action_text_reading::@5 to printf_ulong [phi:display_action_text_reading::@5->printf_ulong]
    // [1588] phi printf_ulong::format_zero_padding#14 = 1 [phi:display_action_text_reading::@5->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1588] phi printf_ulong::format_min_length#14 = 5 [phi:display_action_text_reading::@5->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1588] phi printf_ulong::format_radix#14 = HEXADECIMAL [phi:display_action_text_reading::@5->printf_ulong#2] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [1588] phi printf_ulong::uvalue#14 = printf_ulong::uvalue#3 [phi:display_action_text_reading::@5->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2695] phi from display_action_text_reading::@5 to display_action_text_reading::@6 [phi:display_action_text_reading::@5->display_action_text_reading::@6]
    // display_action_text_reading::@6
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2696] call printf_str
    // [1125] phi from display_action_text_reading::@6 to printf_str [phi:display_action_text_reading::@6->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:display_action_text_reading::@6->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = display_action_text_reading::s2 [phi:display_action_text_reading::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@7
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2697] printf_ulong::uvalue#4 = display_action_text_reading::size#10 -- vdum1=vduz2 
    lda.z size
    sta printf_ulong.uvalue
    lda.z size+1
    sta printf_ulong.uvalue+1
    lda.z size+2
    sta printf_ulong.uvalue+2
    lda.z size+3
    sta printf_ulong.uvalue+3
    // [2698] call printf_ulong
    // [1588] phi from display_action_text_reading::@7 to printf_ulong [phi:display_action_text_reading::@7->printf_ulong]
    // [1588] phi printf_ulong::format_zero_padding#14 = 1 [phi:display_action_text_reading::@7->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1588] phi printf_ulong::format_min_length#14 = 5 [phi:display_action_text_reading::@7->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1588] phi printf_ulong::format_radix#14 = HEXADECIMAL [phi:display_action_text_reading::@7->printf_ulong#2] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [1588] phi printf_ulong::uvalue#14 = printf_ulong::uvalue#4 [phi:display_action_text_reading::@7->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2699] phi from display_action_text_reading::@7 to display_action_text_reading::@8 [phi:display_action_text_reading::@7->display_action_text_reading::@8]
    // display_action_text_reading::@8
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2700] call printf_str
    // [1125] phi from display_action_text_reading::@8 to printf_str [phi:display_action_text_reading::@8->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:display_action_text_reading::@8->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = display_action_text_reading::s3 [phi:display_action_text_reading::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@9
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2701] printf_uchar::uvalue#2 = display_action_text_reading::bram_bank#10 -- vbuxx=vbuz1 
    ldx.z bram_bank
    // [2702] call printf_uchar
    // [1189] phi from display_action_text_reading::@9 to printf_uchar [phi:display_action_text_reading::@9->printf_uchar]
    // [1189] phi printf_uchar::format_zero_padding#15 = 1 [phi:display_action_text_reading::@9->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1189] phi printf_uchar::format_min_length#15 = 2 [phi:display_action_text_reading::@9->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1189] phi printf_uchar::putc#15 = &snputc [phi:display_action_text_reading::@9->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1189] phi printf_uchar::format_radix#15 = HEXADECIMAL [phi:display_action_text_reading::@9->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #HEXADECIMAL
    // [1189] phi printf_uchar::uvalue#15 = printf_uchar::uvalue#2 [phi:display_action_text_reading::@9->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [2703] phi from display_action_text_reading::@9 to display_action_text_reading::@10 [phi:display_action_text_reading::@9->display_action_text_reading::@10]
    // display_action_text_reading::@10
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2704] call printf_str
    // [1125] phi from display_action_text_reading::@10 to printf_str [phi:display_action_text_reading::@10->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:display_action_text_reading::@10->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = s2 [phi:display_action_text_reading::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s2
    sta.z printf_str.s
    lda #>@s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@11
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2705] printf_uint::uvalue#2 = (unsigned int)display_action_text_reading::bram_ptr#10 -- vwum1=vwuz2 
    lda.z bram_ptr
    sta printf_uint.uvalue
    lda.z bram_ptr+1
    sta printf_uint.uvalue+1
    // [2706] call printf_uint
    // [2015] phi from display_action_text_reading::@11 to printf_uint [phi:display_action_text_reading::@11->printf_uint]
    // [2015] phi printf_uint::format_zero_padding#10 = 1 [phi:display_action_text_reading::@11->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [2015] phi printf_uint::format_min_length#10 = 4 [phi:display_action_text_reading::@11->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [2015] phi printf_uint::putc#10 = &snputc [phi:display_action_text_reading::@11->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [2015] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:display_action_text_reading::@11->printf_uint#3] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [2015] phi printf_uint::uvalue#10 = printf_uint::uvalue#2 [phi:display_action_text_reading::@11->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [2707] phi from display_action_text_reading::@11 to display_action_text_reading::@12 [phi:display_action_text_reading::@11->display_action_text_reading::@12]
    // display_action_text_reading::@12
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2708] call printf_str
    // [1125] phi from display_action_text_reading::@12 to printf_str [phi:display_action_text_reading::@12->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:display_action_text_reading::@12->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = s4 [phi:display_action_text_reading::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@13
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2709] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [2710] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [2712] call display_action_text
    // [1200] phi from display_action_text_reading::@13 to display_action_text [phi:display_action_text_reading::@13->display_action_text]
    // [1200] phi display_action_text::info_text#25 = info_text [phi:display_action_text_reading::@13->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // display_action_text_reading::@return
    // }
    // [2713] return 
    rts
  .segment Data
    s2: .text "/"
    .byte 0
    s3: .text " -> RAM:"
    .byte 0
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
// __mem() unsigned int fgets(__zp($5b) char *ptr, __mem() unsigned int size, __zp($be) struct $2 *stream)
fgets: {
    .label ptr = $5b
    .label stream = $be
    // unsigned char sp = (unsigned char)stream
    // [2715] fgets::sp#0 = (char)fgets::stream#4 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_chkin(__logical)
    // [2716] fgets::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fgets::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    tay
    lda __stdio_file+$40,y
    sta cbm_k_chkin1_channel
    // fgets::cbm_k_chkin1
    // char status
    // [2717] fgets::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fgets::cbm_k_readst1
    // char status
    // [2719] fgets::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2721] fgets::cbm_k_readst1_return#0 = fgets::cbm_k_readst1_status -- vbuaa=vbum1 
    // fgets::cbm_k_readst1_@return
    // }
    // [2722] fgets::cbm_k_readst1_return#1 = fgets::cbm_k_readst1_return#0
    // fgets::@11
    // cbm_k_readst()
    // [2723] fgets::$1 = fgets::cbm_k_readst1_return#1
    // __status = cbm_k_readst()
    // [2724] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$1 -- pbuc1_derefidx_vbum1=vbuaa 
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2725] if(0==((char *)&__stdio_file+$46)[fgets::sp#0]) goto fgets::@1 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b1
    // [2726] phi from fgets::@11 fgets::@12 fgets::@5 to fgets::@return [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return]
  __b8:
    // [2726] phi fgets::return#1 = 0 [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return#0] -- vwum1=vbuc1 
    lda #<0
    sta return
    sta return+1
    // fgets::@return
    // }
    // [2727] return 
    rts
    // fgets::@1
  __b1:
    // [2728] fgets::remaining#22 = fgets::size#10 -- vwum1=vwum2 
    lda size
    sta remaining
    lda size+1
    sta remaining+1
    // [2729] phi from fgets::@1 to fgets::@2 [phi:fgets::@1->fgets::@2]
    // [2729] phi fgets::read#10 = 0 [phi:fgets::@1->fgets::@2#0] -- vwum1=vwuc1 
    lda #<0
    sta read
    sta read+1
    // [2729] phi fgets::remaining#11 = fgets::remaining#22 [phi:fgets::@1->fgets::@2#1] -- register_copy 
    // [2729] phi fgets::ptr#11 = fgets::ptr#14 [phi:fgets::@1->fgets::@2#2] -- register_copy 
    // [2729] phi from fgets::@17 fgets::@18 to fgets::@2 [phi:fgets::@17/fgets::@18->fgets::@2]
    // [2729] phi fgets::read#10 = fgets::read#1 [phi:fgets::@17/fgets::@18->fgets::@2#0] -- register_copy 
    // [2729] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@17/fgets::@18->fgets::@2#1] -- register_copy 
    // [2729] phi fgets::ptr#11 = fgets::ptr#15 [phi:fgets::@17/fgets::@18->fgets::@2#2] -- register_copy 
    // fgets::@2
  __b2:
    // if (!size)
    // [2730] if(0==fgets::size#10) goto fgets::@3 -- 0_eq_vwum1_then_la1 
    lda size
    ora size+1
    bne !__b3+
    jmp __b3
  !__b3:
    // fgets::@8
    // if (remaining >= 512)
    // [2731] if(fgets::remaining#11>=$200) goto fgets::@4 -- vwum1_ge_vwuc1_then_la1 
    lda remaining+1
    cmp #>$200
    bcc !+
    beq !__b4+
    jmp __b4
  !__b4:
    lda remaining
    cmp #<$200
    bcc !__b4+
    jmp __b4
  !__b4:
  !:
    // fgets::@9
    // cx16_k_macptr(remaining, ptr)
    // [2732] cx16_k_macptr::bytes = fgets::remaining#11 -- vbum1=vwum2 
    lda remaining
    sta cx16_k_macptr.bytes
    // [2733] cx16_k_macptr::buffer = (void *)fgets::ptr#11 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2734] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2735] cx16_k_macptr::return#4 = cx16_k_macptr::return#1
    // fgets::@15
  __b15:
    // bytes = cx16_k_macptr(remaining, ptr)
    // [2736] fgets::bytes#3 = cx16_k_macptr::return#4
    // [2737] phi from fgets::@13 fgets::@14 fgets::@15 to fgets::cbm_k_readst2 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2]
    // [2737] phi fgets::bytes#10 = fgets::bytes#1 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2#0] -- register_copy 
    // fgets::cbm_k_readst2
    // char status
    // [2738] fgets::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [2740] fgets::cbm_k_readst2_return#0 = fgets::cbm_k_readst2_status -- vbuaa=vbum1 
    // fgets::cbm_k_readst2_@return
    // }
    // [2741] fgets::cbm_k_readst2_return#1 = fgets::cbm_k_readst2_return#0
    // fgets::@12
    // cbm_k_readst()
    // [2742] fgets::$8 = fgets::cbm_k_readst2_return#1
    // __status = cbm_k_readst()
    // [2743] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$8 -- pbuc1_derefidx_vbum1=vbuaa 
    ldy sp
    sta __stdio_file+$46,y
    // __status & 0xBF
    // [2744] fgets::$9 = ((char *)&__stdio_file+$46)[fgets::sp#0] & $bf -- vbuaa=pbuc1_derefidx_vbum1_band_vbuc2 
    lda #$bf
    and __stdio_file+$46,y
    // if (__status & 0xBF)
    // [2745] if(0==fgets::$9) goto fgets::@5 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b5
    jmp __b8
    // fgets::@5
  __b5:
    // if (bytes == 0xFFFF)
    // [2746] if(fgets::bytes#10!=$ffff) goto fgets::@6 -- vwum1_neq_vwuc1_then_la1 
    lda bytes+1
    cmp #>$ffff
    bne __b6
    lda bytes
    cmp #<$ffff
    bne __b6
    jmp __b8
    // fgets::@6
  __b6:
    // read += bytes
    // [2747] fgets::read#1 = fgets::read#10 + fgets::bytes#10 -- vwum1=vwum1_plus_vwum2 
    clc
    lda read
    adc bytes
    sta read
    lda read+1
    adc bytes+1
    sta read+1
    // ptr += bytes
    // [2748] fgets::ptr#0 = fgets::ptr#11 + fgets::bytes#10 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z ptr
    adc bytes
    sta.z ptr
    lda.z ptr+1
    adc bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [2749] fgets::$13 = byte1  fgets::ptr#0 -- vbuaa=_byte1_pbuz1 
    // if (BYTE1(ptr) == 0xC0)
    // [2750] if(fgets::$13!=$c0) goto fgets::@7 -- vbuaa_neq_vbuc1_then_la1 
    cmp #$c0
    bne __b7
    // fgets::@10
    // ptr -= 0x2000
    // [2751] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [2752] phi from fgets::@10 fgets::@6 to fgets::@7 [phi:fgets::@10/fgets::@6->fgets::@7]
    // [2752] phi fgets::ptr#15 = fgets::ptr#1 [phi:fgets::@10/fgets::@6->fgets::@7#0] -- register_copy 
    // fgets::@7
  __b7:
    // remaining -= bytes
    // [2753] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#10 -- vwum1=vwum1_minus_vwum2 
    lda remaining
    sec
    sbc bytes
    sta remaining
    lda remaining+1
    sbc bytes+1
    sta remaining+1
    // while ((__status == 0) && ((size && remaining) || !size))
    // [2754] if(((char *)&__stdio_file+$46)[fgets::sp#0]==0) goto fgets::@16 -- pbuc1_derefidx_vbum1_eq_0_then_la1 
    ldy sp
    lda __stdio_file+$46,y
    cmp #0
    beq __b16
    // [2726] phi from fgets::@17 fgets::@7 to fgets::@return [phi:fgets::@17/fgets::@7->fgets::@return]
    // [2726] phi fgets::return#1 = fgets::read#1 [phi:fgets::@17/fgets::@7->fgets::@return#0] -- register_copy 
    rts
    // fgets::@16
  __b16:
    // while ((__status == 0) && ((size && remaining) || !size))
    // [2755] if(0==fgets::size#10) goto fgets::@17 -- 0_eq_vwum1_then_la1 
    lda size
    ora size+1
    beq __b17
    // fgets::@18
    // [2756] if(0!=fgets::remaining#1) goto fgets::@2 -- 0_neq_vwum1_then_la1 
    lda remaining
    ora remaining+1
    beq !__b2+
    jmp __b2
  !__b2:
    // fgets::@17
  __b17:
    // [2757] if(0==fgets::size#10) goto fgets::@2 -- 0_eq_vwum1_then_la1 
    lda size
    ora size+1
    bne !__b2+
    jmp __b2
  !__b2:
    rts
    // fgets::@4
  __b4:
    // cx16_k_macptr(512, ptr)
    // [2758] cx16_k_macptr::bytes = $200 -- vbum1=vwuc1 
    lda #<$200
    sta cx16_k_macptr.bytes
    // [2759] cx16_k_macptr::buffer = (void *)fgets::ptr#11 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2760] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2761] cx16_k_macptr::return#3 = cx16_k_macptr::return#1
    // fgets::@14
    // bytes = cx16_k_macptr(512, ptr)
    // [2762] fgets::bytes#2 = cx16_k_macptr::return#3
    jmp __b15
    // fgets::@3
  __b3:
    // cx16_k_macptr(0, ptr)
    // [2763] cx16_k_macptr::bytes = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_macptr.bytes
    // [2764] cx16_k_macptr::buffer = (void *)fgets::ptr#11 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2765] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2766] cx16_k_macptr::return#2 = cx16_k_macptr::return#1
    // fgets::@13
    // bytes = cx16_k_macptr(0, ptr)
    // [2767] fgets::bytes#1 = cx16_k_macptr::return#2
    jmp __b15
  .segment Data
    cbm_k_chkin1_channel: .byte 0
    cbm_k_chkin1_status: .byte 0
    cbm_k_readst1_status: .byte 0
    cbm_k_readst2_status: .byte 0
    .label sp = printf_uchar.format_min_length
    .label return = read
    bytes: .word 0
    read: .word 0
    remaining: .word 0
    .label size = strncmp.n
}
.segment Code
  // rom_compare
// __zp($46) unsigned int rom_compare(__register(X) char bank_ram, __zp($53) char *ptr_ram, __zp($a9) unsigned long rom_compare_address, __zp($65) unsigned int rom_compare_size)
rom_compare: {
    .label rom_bank1_rom_compare__2 = $73
    .label rom_ptr1_rom_compare__0 = $40
    .label rom_ptr1_rom_compare__2 = $40
    .label rom_bank1_bank_unshifted = $73
    .label rom_ptr1_return = $40
    .label ptr_rom = $40
    .label ptr_ram = $53
    .label compared_bytes = $4e
    /// Holds the amount of bytes actually verified between the ROM and the RAM.
    .label equal_bytes = $46
    .label rom_compare_address = $a9
    .label return = $46
    .label rom_compare_size = $65
    // rom_compare::bank_set_bram1
    // BRAM = bank
    // [2769] BRAM = rom_compare::bank_set_bram1_bank#0 -- vbuz1=vbuxx 
    stx.z BRAM
    // rom_compare::rom_bank1
    // BYTE2(address)
    // [2770] rom_compare::rom_bank1_$0 = byte2  rom_compare::rom_compare_address#3 -- vbuxx=_byte2_vduz1 
    ldx.z rom_compare_address+2
    // BYTE1(address)
    // [2771] rom_compare::rom_bank1_$1 = byte1  rom_compare::rom_compare_address#3 -- vbuaa=_byte1_vduz1 
    lda.z rom_compare_address+1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2772] rom_compare::rom_bank1_$2 = rom_compare::rom_bank1_$0 w= rom_compare::rom_bank1_$1 -- vwuz1=vbuxx_word_vbuaa 
    stx.z rom_bank1_rom_compare__2+1
    sta.z rom_bank1_rom_compare__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2773] rom_compare::rom_bank1_bank_unshifted#0 = rom_compare::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2774] rom_compare::rom_bank1_return#0 = byte1  rom_compare::rom_bank1_bank_unshifted#0 -- vbuxx=_byte1_vwuz1 
    ldx.z rom_bank1_bank_unshifted+1
    // rom_compare::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2775] rom_compare::rom_ptr1_$2 = (unsigned int)rom_compare::rom_compare_address#3 -- vwuz1=_word_vduz2 
    lda.z rom_compare_address
    sta.z rom_ptr1_rom_compare__2
    lda.z rom_compare_address+1
    sta.z rom_ptr1_rom_compare__2+1
    // [2776] rom_compare::rom_ptr1_$0 = rom_compare::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_compare__0
    and #<$3fff
    sta.z rom_ptr1_rom_compare__0
    lda.z rom_ptr1_rom_compare__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_compare__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2777] rom_compare::rom_ptr1_return#0 = rom_compare::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_compare::bank_set_brom1
    // BROM = bank
    // [2778] BROM = rom_compare::rom_bank1_return#0 -- vbuz1=vbuxx 
    stx.z BROM
    // [2779] rom_compare::ptr_rom#9 = (char *)rom_compare::rom_ptr1_return#0
    // [2780] phi from rom_compare::bank_set_brom1 to rom_compare::@1 [phi:rom_compare::bank_set_brom1->rom_compare::@1]
    // [2780] phi rom_compare::equal_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z equal_bytes
    sta.z equal_bytes+1
    // [2780] phi rom_compare::ptr_ram#4 = rom_compare::ptr_ram#10 [phi:rom_compare::bank_set_brom1->rom_compare::@1#1] -- register_copy 
    // [2780] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#9 [phi:rom_compare::bank_set_brom1->rom_compare::@1#2] -- register_copy 
    // [2780] phi rom_compare::compared_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#3] -- vwuz1=vwuc1 
    sta.z compared_bytes
    sta.z compared_bytes+1
    // rom_compare::@1
  __b1:
    // while (compared_bytes < rom_compare_size)
    // [2781] if(rom_compare::compared_bytes#2<rom_compare::rom_compare_size#11) goto rom_compare::@2 -- vwuz1_lt_vwuz2_then_la1 
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
    // [2782] return 
    rts
    // rom_compare::@2
  __b2:
    // rom_byte_compare(ptr_rom, *ptr_ram)
    // [2783] rom_byte_compare::ptr_rom#0 = rom_compare::ptr_rom#2
    // [2784] rom_byte_compare::value#0 = *rom_compare::ptr_ram#4 -- vbuaa=_deref_pbuz1 
    ldy #0
    lda (ptr_ram),y
    // [2785] call rom_byte_compare
    jsr rom_byte_compare
    // [2786] rom_byte_compare::return#2 = rom_byte_compare::return#0
    // rom_compare::@5
    // [2787] rom_compare::$5 = rom_byte_compare::return#2
    // if (rom_byte_compare(ptr_rom, *ptr_ram))
    // [2788] if(0==rom_compare::$5) goto rom_compare::@3 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b3
    // rom_compare::@4
    // equal_bytes++;
    // [2789] rom_compare::equal_bytes#1 = ++ rom_compare::equal_bytes#2 -- vwuz1=_inc_vwuz1 
    inc.z equal_bytes
    bne !+
    inc.z equal_bytes+1
  !:
    // [2790] phi from rom_compare::@4 rom_compare::@5 to rom_compare::@3 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3]
    // [2790] phi rom_compare::equal_bytes#6 = rom_compare::equal_bytes#1 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3#0] -- register_copy 
    // rom_compare::@3
  __b3:
    // ptr_rom++;
    // [2791] rom_compare::ptr_rom#1 = ++ rom_compare::ptr_rom#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr_rom
    bne !+
    inc.z ptr_rom+1
  !:
    // ptr_ram++;
    // [2792] rom_compare::ptr_ram#0 = ++ rom_compare::ptr_ram#4 -- pbuz1=_inc_pbuz1 
    inc.z ptr_ram
    bne !+
    inc.z ptr_ram+1
  !:
    // compared_bytes++;
    // [2793] rom_compare::compared_bytes#1 = ++ rom_compare::compared_bytes#2 -- vwuz1=_inc_vwuz1 
    inc.z compared_bytes
    bne !+
    inc.z compared_bytes+1
  !:
    // [2780] phi from rom_compare::@3 to rom_compare::@1 [phi:rom_compare::@3->rom_compare::@1]
    // [2780] phi rom_compare::equal_bytes#2 = rom_compare::equal_bytes#6 [phi:rom_compare::@3->rom_compare::@1#0] -- register_copy 
    // [2780] phi rom_compare::ptr_ram#4 = rom_compare::ptr_ram#0 [phi:rom_compare::@3->rom_compare::@1#1] -- register_copy 
    // [2780] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#1 [phi:rom_compare::@3->rom_compare::@1#2] -- register_copy 
    // [2780] phi rom_compare::compared_bytes#2 = rom_compare::compared_bytes#1 [phi:rom_compare::@3->rom_compare::@1#3] -- register_copy 
    jmp __b1
}
  // ultoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void ultoa(__mem() unsigned long value, __zp($2a) char *buffer, __register(X) char radix)
ultoa: {
    .label buffer = $2a
    .label digit_values = $3a
    // if(radix==DECIMAL)
    // [2794] if(ultoa::radix#0==DECIMAL) goto ultoa::@1 -- vbuxx_eq_vbuc1_then_la1 
    cpx #DECIMAL
    beq __b2
    // ultoa::@2
    // if(radix==HEXADECIMAL)
    // [2795] if(ultoa::radix#0==HEXADECIMAL) goto ultoa::@1 -- vbuxx_eq_vbuc1_then_la1 
    cpx #HEXADECIMAL
    beq __b3
    // ultoa::@3
    // if(radix==OCTAL)
    // [2796] if(ultoa::radix#0==OCTAL) goto ultoa::@1 -- vbuxx_eq_vbuc1_then_la1 
    cpx #OCTAL
    beq __b4
    // ultoa::@4
    // if(radix==BINARY)
    // [2797] if(ultoa::radix#0==BINARY) goto ultoa::@1 -- vbuxx_eq_vbuc1_then_la1 
    cpx #BINARY
    beq __b5
    // ultoa::@5
    // *buffer++ = 'e'
    // [2798] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2799] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2800] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2801] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // ultoa::@return
    // }
    // [2802] return 
    rts
    // [2803] phi from ultoa to ultoa::@1 [phi:ultoa->ultoa::@1]
  __b2:
    // [2803] phi ultoa::digit_values#8 = RADIX_DECIMAL_VALUES_LONG [phi:ultoa->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2803] phi ultoa::max_digits#7 = $a [phi:ultoa->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$a
    sta max_digits
    jmp __b1
    // [2803] phi from ultoa::@2 to ultoa::@1 [phi:ultoa::@2->ultoa::@1]
  __b3:
    // [2803] phi ultoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_LONG [phi:ultoa::@2->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2803] phi ultoa::max_digits#7 = 8 [phi:ultoa::@2->ultoa::@1#1] -- vbum1=vbuc1 
    lda #8
    sta max_digits
    jmp __b1
    // [2803] phi from ultoa::@3 to ultoa::@1 [phi:ultoa::@3->ultoa::@1]
  __b4:
    // [2803] phi ultoa::digit_values#8 = RADIX_OCTAL_VALUES_LONG [phi:ultoa::@3->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_OCTAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_LONG
    sta.z digit_values+1
    // [2803] phi ultoa::max_digits#7 = $b [phi:ultoa::@3->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$b
    sta max_digits
    jmp __b1
    // [2803] phi from ultoa::@4 to ultoa::@1 [phi:ultoa::@4->ultoa::@1]
  __b5:
    // [2803] phi ultoa::digit_values#8 = RADIX_BINARY_VALUES_LONG [phi:ultoa::@4->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_BINARY_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_LONG
    sta.z digit_values+1
    // [2803] phi ultoa::max_digits#7 = $20 [phi:ultoa::@4->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$20
    sta max_digits
    // ultoa::@1
  __b1:
    // [2804] phi from ultoa::@1 to ultoa::@6 [phi:ultoa::@1->ultoa::@6]
    // [2804] phi ultoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:ultoa::@1->ultoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2804] phi ultoa::started#2 = 0 [phi:ultoa::@1->ultoa::@6#1] -- vbuxx=vbuc1 
    ldx #0
    // [2804] phi ultoa::value#2 = ultoa::value#1 [phi:ultoa::@1->ultoa::@6#2] -- register_copy 
    // [2804] phi ultoa::digit#2 = 0 [phi:ultoa::@1->ultoa::@6#3] -- vbum1=vbuc1 
    txa
    sta digit
    // ultoa::@6
  __b6:
    // max_digits-1
    // [2805] ultoa::$4 = ultoa::max_digits#7 - 1 -- vbuaa=vbum1_minus_1 
    lda max_digits
    sec
    sbc #1
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2806] if(ultoa::digit#2<ultoa::$4) goto ultoa::@7 -- vbum1_lt_vbuaa_then_la1 
    cmp digit
    beq !+
    bcs __b7
  !:
    // ultoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2807] ultoa::$11 = (char)ultoa::value#2 -- vbuaa=_byte_vdum1 
    lda value
    // [2808] *ultoa::buffer#11 = DIGITS[ultoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuaa 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2809] ultoa::buffer#3 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2810] *ultoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // ultoa::@7
  __b7:
    // unsigned long digit_value = digit_values[digit]
    // [2811] ultoa::$10 = ultoa::digit#2 << 2 -- vbuaa=vbum1_rol_2 
    lda digit
    asl
    asl
    // [2812] ultoa::digit_value#0 = ultoa::digit_values#8[ultoa::$10] -- vdum1=pduz2_derefidx_vbuaa 
    tay
    lda (digit_values),y
    sta digit_value
    iny
    lda (digit_values),y
    sta digit_value+1
    iny
    lda (digit_values),y
    sta digit_value+2
    iny
    lda (digit_values),y
    sta digit_value+3
    // if (started || value >= digit_value)
    // [2813] if(0!=ultoa::started#2) goto ultoa::@10 -- 0_neq_vbuxx_then_la1 
    cpx #0
    bne __b10
    // ultoa::@12
    // [2814] if(ultoa::value#2>=ultoa::digit_value#0) goto ultoa::@10 -- vdum1_ge_vdum2_then_la1 
    lda value+3
    cmp digit_value+3
    bcc !+
    bne __b10
    lda value+2
    cmp digit_value+2
    bcc !+
    bne __b10
    lda value+1
    cmp digit_value+1
    bcc !+
    bne __b10
    lda value
    cmp digit_value
    bcs __b10
  !:
    // [2815] phi from ultoa::@12 to ultoa::@9 [phi:ultoa::@12->ultoa::@9]
    // [2815] phi ultoa::buffer#14 = ultoa::buffer#11 [phi:ultoa::@12->ultoa::@9#0] -- register_copy 
    // [2815] phi ultoa::started#4 = ultoa::started#2 [phi:ultoa::@12->ultoa::@9#1] -- register_copy 
    // [2815] phi ultoa::value#6 = ultoa::value#2 [phi:ultoa::@12->ultoa::@9#2] -- register_copy 
    // ultoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2816] ultoa::digit#1 = ++ ultoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [2804] phi from ultoa::@9 to ultoa::@6 [phi:ultoa::@9->ultoa::@6]
    // [2804] phi ultoa::buffer#11 = ultoa::buffer#14 [phi:ultoa::@9->ultoa::@6#0] -- register_copy 
    // [2804] phi ultoa::started#2 = ultoa::started#4 [phi:ultoa::@9->ultoa::@6#1] -- register_copy 
    // [2804] phi ultoa::value#2 = ultoa::value#6 [phi:ultoa::@9->ultoa::@6#2] -- register_copy 
    // [2804] phi ultoa::digit#2 = ultoa::digit#1 [phi:ultoa::@9->ultoa::@6#3] -- register_copy 
    jmp __b6
    // ultoa::@10
  __b10:
    // ultoa_append(buffer++, value, digit_value)
    // [2817] ultoa_append::buffer#0 = ultoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z ultoa_append.buffer
    lda.z buffer+1
    sta.z ultoa_append.buffer+1
    // [2818] ultoa_append::value#0 = ultoa::value#2
    // [2819] ultoa_append::sub#0 = ultoa::digit_value#0
    // [2820] call ultoa_append
    // [3401] phi from ultoa::@10 to ultoa_append [phi:ultoa::@10->ultoa_append]
    jsr ultoa_append
    // ultoa_append(buffer++, value, digit_value)
    // [2821] ultoa_append::return#0 = ultoa_append::value#2
    // ultoa::@11
    // value = ultoa_append(buffer++, value, digit_value)
    // [2822] ultoa::value#0 = ultoa_append::return#0
    // value = ultoa_append(buffer++, value, digit_value);
    // [2823] ultoa::buffer#4 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2815] phi from ultoa::@11 to ultoa::@9 [phi:ultoa::@11->ultoa::@9]
    // [2815] phi ultoa::buffer#14 = ultoa::buffer#4 [phi:ultoa::@11->ultoa::@9#0] -- register_copy 
    // [2815] phi ultoa::started#4 = 1 [phi:ultoa::@11->ultoa::@9#1] -- vbuxx=vbuc1 
    ldx #1
    // [2815] phi ultoa::value#6 = ultoa::value#0 [phi:ultoa::@11->ultoa::@9#2] -- register_copy 
    jmp __b9
  .segment Data
    digit_value: .dword 0
    .label digit = uctoa.digit
    .label value = printf_ulong.uvalue
    .label max_digits = printf_string.format_justify_left
}
.segment Code
  // display_action_text_flashed
// void display_action_text_flashed(__mem() unsigned long bytes, __zp($d0) char *chip)
display_action_text_flashed: {
    .label chip = $d0
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2825] call snprintf_init
    // [1184] phi from display_action_text_flashed to snprintf_init [phi:display_action_text_flashed->snprintf_init]
    // [1184] phi snprintf_init::s#30 = info_text [phi:display_action_text_flashed->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [2826] phi from display_action_text_flashed to display_action_text_flashed::@1 [phi:display_action_text_flashed->display_action_text_flashed::@1]
    // display_action_text_flashed::@1
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2827] call printf_str
    // [1125] phi from display_action_text_flashed::@1 to printf_str [phi:display_action_text_flashed::@1->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:display_action_text_flashed::@1->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = display_action_text_flashed::s [phi:display_action_text_flashed::@1->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashed::@2
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2828] printf_ulong::uvalue#2 = display_action_text_flashed::bytes#3 -- vdum1=vdum2 
    lda bytes
    sta printf_ulong.uvalue
    lda bytes+1
    sta printf_ulong.uvalue+1
    lda bytes+2
    sta printf_ulong.uvalue+2
    lda bytes+3
    sta printf_ulong.uvalue+3
    // [2829] call printf_ulong
    // [1588] phi from display_action_text_flashed::@2 to printf_ulong [phi:display_action_text_flashed::@2->printf_ulong]
    // [1588] phi printf_ulong::format_zero_padding#14 = 0 [phi:display_action_text_flashed::@2->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1588] phi printf_ulong::format_min_length#14 = 0 [phi:display_action_text_flashed::@2->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1588] phi printf_ulong::format_radix#14 = DECIMAL [phi:display_action_text_flashed::@2->printf_ulong#2] -- vbuxx=vbuc1 
    ldx #DECIMAL
    // [1588] phi printf_ulong::uvalue#14 = printf_ulong::uvalue#2 [phi:display_action_text_flashed::@2->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2830] phi from display_action_text_flashed::@2 to display_action_text_flashed::@3 [phi:display_action_text_flashed::@2->display_action_text_flashed::@3]
    // display_action_text_flashed::@3
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2831] call printf_str
    // [1125] phi from display_action_text_flashed::@3 to printf_str [phi:display_action_text_flashed::@3->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:display_action_text_flashed::@3->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = display_action_text_flashed::s1 [phi:display_action_text_flashed::@3->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashed::@4
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2832] printf_string::str#13 = display_action_text_flashed::chip#3 -- pbuz1=pbuz2 
    lda.z chip
    sta.z printf_string.str
    lda.z chip+1
    sta.z printf_string.str+1
    // [2833] call printf_string
    // [1419] phi from display_action_text_flashed::@4 to printf_string [phi:display_action_text_flashed::@4->printf_string]
    // [1419] phi printf_string::putc#26 = &snputc [phi:display_action_text_flashed::@4->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1419] phi printf_string::str#26 = printf_string::str#13 [phi:display_action_text_flashed::@4->printf_string#1] -- register_copy 
    // [1419] phi printf_string::format_justify_left#26 = 0 [phi:display_action_text_flashed::@4->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1419] phi printf_string::format_min_length#26 = 0 [phi:display_action_text_flashed::@4->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [2834] phi from display_action_text_flashed::@4 to display_action_text_flashed::@5 [phi:display_action_text_flashed::@4->display_action_text_flashed::@5]
    // display_action_text_flashed::@5
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2835] call printf_str
    // [1125] phi from display_action_text_flashed::@5 to printf_str [phi:display_action_text_flashed::@5->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:display_action_text_flashed::@5->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = s5 [phi:display_action_text_flashed::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashed::@6
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2836] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [2837] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [2839] call display_action_text
    // [1200] phi from display_action_text_flashed::@6 to display_action_text [phi:display_action_text_flashed::@6->display_action_text]
    // [1200] phi display_action_text::info_text#25 = info_text [phi:display_action_text_flashed::@6->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // display_action_text_flashed::@return
    // }
    // [2840] return 
    rts
  .segment Data
    s: .text "Flashed "
    .byte 0
    s1: .text " bytes from RAM -> "
    .byte 0
    .label bytes = w25q16_flash.w25q16_flash__21
}
.segment Code
  // get_info_text_flashing
// char * get_info_text_flashing(__zp($f6) unsigned long flash_bytes)
get_info_text_flashing: {
    .label flash_bytes = $f6
    // sprintf(info_text, "%u bytes flashed", flash_bytes)
    // [2842] call snprintf_init
    // [1184] phi from get_info_text_flashing to snprintf_init [phi:get_info_text_flashing->snprintf_init]
    // [1184] phi snprintf_init::s#30 = info_text [phi:get_info_text_flashing->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // get_info_text_flashing::@1
    // sprintf(info_text, "%u bytes flashed", flash_bytes)
    // [2843] printf_ulong::uvalue#5 = get_info_text_flashing::flash_bytes#3 -- vdum1=vduz2 
    lda.z flash_bytes
    sta printf_ulong.uvalue
    lda.z flash_bytes+1
    sta printf_ulong.uvalue+1
    lda.z flash_bytes+2
    sta printf_ulong.uvalue+2
    lda.z flash_bytes+3
    sta printf_ulong.uvalue+3
    // [2844] call printf_ulong
    // [1588] phi from get_info_text_flashing::@1 to printf_ulong [phi:get_info_text_flashing::@1->printf_ulong]
    // [1588] phi printf_ulong::format_zero_padding#14 = 0 [phi:get_info_text_flashing::@1->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1588] phi printf_ulong::format_min_length#14 = 0 [phi:get_info_text_flashing::@1->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1588] phi printf_ulong::format_radix#14 = DECIMAL [phi:get_info_text_flashing::@1->printf_ulong#2] -- vbuxx=vbuc1 
    ldx #DECIMAL
    // [1588] phi printf_ulong::uvalue#14 = printf_ulong::uvalue#5 [phi:get_info_text_flashing::@1->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2845] phi from get_info_text_flashing::@1 to get_info_text_flashing::@2 [phi:get_info_text_flashing::@1->get_info_text_flashing::@2]
    // get_info_text_flashing::@2
    // sprintf(info_text, "%u bytes flashed", flash_bytes)
    // [2846] call printf_str
    // [1125] phi from get_info_text_flashing::@2 to printf_str [phi:get_info_text_flashing::@2->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:get_info_text_flashing::@2->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = get_info_text_flashing::s [phi:get_info_text_flashing::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // get_info_text_flashing::@3
    // sprintf(info_text, "%u bytes flashed", flash_bytes)
    // [2847] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [2848] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // get_info_text_flashing::@return
    // }
    // [2850] return 
    rts
  .segment Data
    s: .text " bytes flashed"
    .byte 0
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
// void rom_sector_erase(__zp($d4) unsigned long address)
rom_sector_erase: {
    .label rom_ptr1_rom_sector_erase__0 = $23
    .label rom_ptr1_rom_sector_erase__2 = $23
    .label rom_ptr1_return = $23
    .label rom_chip_address = $42
    .label address = $d4
    // rom_sector_erase::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2852] rom_sector_erase::rom_ptr1_$2 = (unsigned int)rom_sector_erase::address#0 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_sector_erase__2
    lda.z address+1
    sta.z rom_ptr1_rom_sector_erase__2+1
    // [2853] rom_sector_erase::rom_ptr1_$0 = rom_sector_erase::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_sector_erase__0
    and #<$3fff
    sta.z rom_ptr1_rom_sector_erase__0
    lda.z rom_ptr1_rom_sector_erase__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_sector_erase__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2854] rom_sector_erase::rom_ptr1_return#0 = rom_sector_erase::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_sector_erase::@1
    // unsigned long rom_chip_address = address & ROM_CHIP_MASK
    // [2855] rom_sector_erase::rom_chip_address#0 = rom_sector_erase::address#0 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [2856] rom_unlock::address#0 = rom_sector_erase::rom_chip_address#0 + $5555 -- vduz1=vduz1_plus_vwuc1 
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
    // [2857] call rom_unlock
    // [2228] phi from rom_sector_erase::@1 to rom_unlock [phi:rom_sector_erase::@1->rom_unlock]
    // [2228] phi rom_unlock::unlock_code#5 = $80 [phi:rom_sector_erase::@1->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$80
    sta.z rom_unlock.unlock_code
    // [2228] phi rom_unlock::address#5 = rom_unlock::address#0 [phi:rom_sector_erase::@1->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@2
    // rom_unlock(address, 0x30)
    // [2858] rom_unlock::address#1 = rom_sector_erase::address#0 -- vduz1=vduz2 
    lda.z address
    sta.z rom_unlock.address
    lda.z address+1
    sta.z rom_unlock.address+1
    lda.z address+2
    sta.z rom_unlock.address+2
    lda.z address+3
    sta.z rom_unlock.address+3
    // [2859] call rom_unlock
    // [2228] phi from rom_sector_erase::@2 to rom_unlock [phi:rom_sector_erase::@2->rom_unlock]
    // [2228] phi rom_unlock::unlock_code#5 = $30 [phi:rom_sector_erase::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$30
    sta.z rom_unlock.unlock_code
    // [2228] phi rom_unlock::address#5 = rom_unlock::address#1 [phi:rom_sector_erase::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@3
    // rom_wait(ptr_rom)
    // [2860] rom_wait::ptr_rom#0 = (char *)rom_sector_erase::rom_ptr1_return#0
    // [2861] call rom_wait
    // [3408] phi from rom_sector_erase::@3 to rom_wait [phi:rom_sector_erase::@3->rom_wait]
    // [3408] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#0 [phi:rom_sector_erase::@3->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_sector_erase::@return
    // }
    // [2862] return 
    rts
}
  // display_action_text_flashing
// void display_action_text_flashing(__zp($b5) unsigned long bytes, __zp($ca) char *chip, __zp($ba) char bram_bank, __zp($c3) char *bram_ptr, __zp($b0) unsigned long address)
display_action_text_flashing: {
    .label bram_ptr = $c3
    .label address = $b0
    .label bram_bank = $ba
    .label bytes = $b5
    .label chip = $ca
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2864] call snprintf_init
    // [1184] phi from display_action_text_flashing to snprintf_init [phi:display_action_text_flashing->snprintf_init]
    // [1184] phi snprintf_init::s#30 = info_text [phi:display_action_text_flashing->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [2865] phi from display_action_text_flashing to display_action_text_flashing::@1 [phi:display_action_text_flashing->display_action_text_flashing::@1]
    // display_action_text_flashing::@1
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2866] call printf_str
    // [1125] phi from display_action_text_flashing::@1 to printf_str [phi:display_action_text_flashing::@1->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:display_action_text_flashing::@1->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = display_action_text_flashing::s [phi:display_action_text_flashing::@1->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@2
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2867] printf_ulong::uvalue#0 = display_action_text_flashing::bytes#3 -- vdum1=vduz2 
    lda.z bytes
    sta printf_ulong.uvalue
    lda.z bytes+1
    sta printf_ulong.uvalue+1
    lda.z bytes+2
    sta printf_ulong.uvalue+2
    lda.z bytes+3
    sta printf_ulong.uvalue+3
    // [2868] call printf_ulong
    // [1588] phi from display_action_text_flashing::@2 to printf_ulong [phi:display_action_text_flashing::@2->printf_ulong]
    // [1588] phi printf_ulong::format_zero_padding#14 = 0 [phi:display_action_text_flashing::@2->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1588] phi printf_ulong::format_min_length#14 = 0 [phi:display_action_text_flashing::@2->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1588] phi printf_ulong::format_radix#14 = DECIMAL [phi:display_action_text_flashing::@2->printf_ulong#2] -- vbuxx=vbuc1 
    ldx #DECIMAL
    // [1588] phi printf_ulong::uvalue#14 = printf_ulong::uvalue#0 [phi:display_action_text_flashing::@2->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2869] phi from display_action_text_flashing::@2 to display_action_text_flashing::@3 [phi:display_action_text_flashing::@2->display_action_text_flashing::@3]
    // display_action_text_flashing::@3
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2870] call printf_str
    // [1125] phi from display_action_text_flashing::@3 to printf_str [phi:display_action_text_flashing::@3->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:display_action_text_flashing::@3->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = display_action_text_flashing::s1 [phi:display_action_text_flashing::@3->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@4
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2871] printf_uchar::uvalue#1 = display_action_text_flashing::bram_bank#3 -- vbuxx=vbuz1 
    ldx.z bram_bank
    // [2872] call printf_uchar
    // [1189] phi from display_action_text_flashing::@4 to printf_uchar [phi:display_action_text_flashing::@4->printf_uchar]
    // [1189] phi printf_uchar::format_zero_padding#15 = 1 [phi:display_action_text_flashing::@4->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1189] phi printf_uchar::format_min_length#15 = 2 [phi:display_action_text_flashing::@4->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1189] phi printf_uchar::putc#15 = &snputc [phi:display_action_text_flashing::@4->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1189] phi printf_uchar::format_radix#15 = HEXADECIMAL [phi:display_action_text_flashing::@4->printf_uchar#3] -- vbuyy=vbuc1 
    ldy #HEXADECIMAL
    // [1189] phi printf_uchar::uvalue#15 = printf_uchar::uvalue#1 [phi:display_action_text_flashing::@4->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [2873] phi from display_action_text_flashing::@4 to display_action_text_flashing::@5 [phi:display_action_text_flashing::@4->display_action_text_flashing::@5]
    // display_action_text_flashing::@5
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2874] call printf_str
    // [1125] phi from display_action_text_flashing::@5 to printf_str [phi:display_action_text_flashing::@5->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:display_action_text_flashing::@5->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = s2 [phi:display_action_text_flashing::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@6
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2875] printf_uint::uvalue#1 = (unsigned int)display_action_text_flashing::bram_ptr#3 -- vwum1=vwuz2 
    lda.z bram_ptr
    sta printf_uint.uvalue
    lda.z bram_ptr+1
    sta printf_uint.uvalue+1
    // [2876] call printf_uint
    // [2015] phi from display_action_text_flashing::@6 to printf_uint [phi:display_action_text_flashing::@6->printf_uint]
    // [2015] phi printf_uint::format_zero_padding#10 = 1 [phi:display_action_text_flashing::@6->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [2015] phi printf_uint::format_min_length#10 = 4 [phi:display_action_text_flashing::@6->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [2015] phi printf_uint::putc#10 = &snputc [phi:display_action_text_flashing::@6->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [2015] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:display_action_text_flashing::@6->printf_uint#3] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [2015] phi printf_uint::uvalue#10 = printf_uint::uvalue#1 [phi:display_action_text_flashing::@6->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [2877] phi from display_action_text_flashing::@6 to display_action_text_flashing::@7 [phi:display_action_text_flashing::@6->display_action_text_flashing::@7]
    // display_action_text_flashing::@7
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2878] call printf_str
    // [1125] phi from display_action_text_flashing::@7 to printf_str [phi:display_action_text_flashing::@7->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:display_action_text_flashing::@7->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = display_action_text_flashing::s3 [phi:display_action_text_flashing::@7->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@8
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2879] printf_string::str#12 = display_action_text_flashing::chip#10 -- pbuz1=pbuz2 
    lda.z chip
    sta.z printf_string.str
    lda.z chip+1
    sta.z printf_string.str+1
    // [2880] call printf_string
    // [1419] phi from display_action_text_flashing::@8 to printf_string [phi:display_action_text_flashing::@8->printf_string]
    // [1419] phi printf_string::putc#26 = &snputc [phi:display_action_text_flashing::@8->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1419] phi printf_string::str#26 = printf_string::str#12 [phi:display_action_text_flashing::@8->printf_string#1] -- register_copy 
    // [1419] phi printf_string::format_justify_left#26 = 0 [phi:display_action_text_flashing::@8->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1419] phi printf_string::format_min_length#26 = 0 [phi:display_action_text_flashing::@8->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [2881] phi from display_action_text_flashing::@8 to display_action_text_flashing::@9 [phi:display_action_text_flashing::@8->display_action_text_flashing::@9]
    // display_action_text_flashing::@9
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2882] call printf_str
    // [1125] phi from display_action_text_flashing::@9 to printf_str [phi:display_action_text_flashing::@9->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:display_action_text_flashing::@9->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = s2 [phi:display_action_text_flashing::@9->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@10
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2883] printf_ulong::uvalue#1 = display_action_text_flashing::address#10 -- vdum1=vduz2 
    lda.z address
    sta printf_ulong.uvalue
    lda.z address+1
    sta printf_ulong.uvalue+1
    lda.z address+2
    sta printf_ulong.uvalue+2
    lda.z address+3
    sta printf_ulong.uvalue+3
    // [2884] call printf_ulong
    // [1588] phi from display_action_text_flashing::@10 to printf_ulong [phi:display_action_text_flashing::@10->printf_ulong]
    // [1588] phi printf_ulong::format_zero_padding#14 = 1 [phi:display_action_text_flashing::@10->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1588] phi printf_ulong::format_min_length#14 = 5 [phi:display_action_text_flashing::@10->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1588] phi printf_ulong::format_radix#14 = HEXADECIMAL [phi:display_action_text_flashing::@10->printf_ulong#2] -- vbuxx=vbuc1 
    ldx #HEXADECIMAL
    // [1588] phi printf_ulong::uvalue#14 = printf_ulong::uvalue#1 [phi:display_action_text_flashing::@10->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2885] phi from display_action_text_flashing::@10 to display_action_text_flashing::@11 [phi:display_action_text_flashing::@10->display_action_text_flashing::@11]
    // display_action_text_flashing::@11
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2886] call printf_str
    // [1125] phi from display_action_text_flashing::@11 to printf_str [phi:display_action_text_flashing::@11->printf_str]
    // [1125] phi printf_str::putc#79 = &snputc [phi:display_action_text_flashing::@11->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1125] phi printf_str::s#79 = s5 [phi:display_action_text_flashing::@11->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@12
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2887] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [2888] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [2890] call display_action_text
    // [1200] phi from display_action_text_flashing::@12 to display_action_text [phi:display_action_text_flashing::@12->display_action_text]
    // [1200] phi display_action_text::info_text#25 = info_text [phi:display_action_text_flashing::@12->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // display_action_text_flashing::@return
    // }
    // [2891] return 
    rts
  .segment Data
    s: .text "Flashing "
    .byte 0
    s1: .text " bytes from RAM:"
    .byte 0
    s3: .text " -> "
    .byte 0
}
.segment Code
  // rom_write
/* inline */
// unsigned long rom_write(__register(X) char flash_ram_bank, __zp($51) char *flash_ram_address, __zp($55) unsigned long flash_rom_address, unsigned int flash_rom_size)
rom_write: {
    .label rom_chip_address = $5f
    .label flash_rom_address = $55
    .label flash_ram_address = $51
    .label flashed_bytes = $4a
    // unsigned long rom_chip_address = flash_rom_address & ROM_CHIP_MASK
    // [2892] rom_write::rom_chip_address#0 = rom_write::flash_rom_address#1 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [2893] BRAM = rom_write::flash_ram_bank#0 -- vbuz1=vbuxx 
    stx.z BRAM
    // [2894] phi from rom_write::bank_set_bram1 to rom_write::@1 [phi:rom_write::bank_set_bram1->rom_write::@1]
    // [2894] phi rom_write::flash_ram_address#2 = rom_write::flash_ram_address#1 [phi:rom_write::bank_set_bram1->rom_write::@1#0] -- register_copy 
    // [2894] phi rom_write::flash_rom_address#3 = rom_write::flash_rom_address#1 [phi:rom_write::bank_set_bram1->rom_write::@1#1] -- register_copy 
    // [2894] phi rom_write::flashed_bytes#2 = 0 [phi:rom_write::bank_set_bram1->rom_write::@1#2] -- vduz1=vduc1 
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
    // [2895] if(rom_write::flashed_bytes#2<ROM_PROGRESS_CELL) goto rom_write::@2 -- vduz1_lt_vduc1_then_la1 
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
    // [2896] return 
    rts
    // rom_write::@2
  __b2:
    // rom_unlock(rom_chip_address + 0x05555, 0xA0)
    // [2897] rom_unlock::address#4 = rom_write::rom_chip_address#0 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [2898] call rom_unlock
    // [2228] phi from rom_write::@2 to rom_unlock [phi:rom_write::@2->rom_unlock]
    // [2228] phi rom_unlock::unlock_code#5 = $a0 [phi:rom_write::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$a0
    sta.z rom_unlock.unlock_code
    // [2228] phi rom_unlock::address#5 = rom_unlock::address#4 [phi:rom_write::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_write::@3
    // rom_byte_program(flash_rom_address, *flash_ram_address)
    // [2899] rom_byte_program::address#0 = rom_write::flash_rom_address#3 -- vduz1=vduz2 
    lda.z flash_rom_address
    sta.z rom_byte_program.address
    lda.z flash_rom_address+1
    sta.z rom_byte_program.address+1
    lda.z flash_rom_address+2
    sta.z rom_byte_program.address+2
    lda.z flash_rom_address+3
    sta.z rom_byte_program.address+3
    // [2900] rom_byte_program::value#0 = *rom_write::flash_ram_address#2 -- vbuyy=_deref_pbuz1 
    ldy #0
    lda (flash_ram_address),y
    tay
    // [2901] call rom_byte_program
    // [3415] phi from rom_write::@3 to rom_byte_program [phi:rom_write::@3->rom_byte_program]
    jsr rom_byte_program
    // rom_write::@4
    // flash_rom_address++;
    // [2902] rom_write::flash_rom_address#0 = ++ rom_write::flash_rom_address#3 -- vduz1=_inc_vduz1 
    inc.z flash_rom_address
    bne !+
    inc.z flash_rom_address+1
    bne !+
    inc.z flash_rom_address+2
    bne !+
    inc.z flash_rom_address+3
  !:
    // flash_ram_address++;
    // [2903] rom_write::flash_ram_address#0 = ++ rom_write::flash_ram_address#2 -- pbuz1=_inc_pbuz1 
    inc.z flash_ram_address
    bne !+
    inc.z flash_ram_address+1
  !:
    // flashed_bytes++;
    // [2904] rom_write::flashed_bytes#1 = ++ rom_write::flashed_bytes#2 -- vduz1=_inc_vduz1 
    inc.z flashed_bytes
    bne !+
    inc.z flashed_bytes+1
    bne !+
    inc.z flashed_bytes+2
    bne !+
    inc.z flashed_bytes+3
  !:
    // [2894] phi from rom_write::@4 to rom_write::@1 [phi:rom_write::@4->rom_write::@1]
    // [2894] phi rom_write::flash_ram_address#2 = rom_write::flash_ram_address#0 [phi:rom_write::@4->rom_write::@1#0] -- register_copy 
    // [2894] phi rom_write::flash_rom_address#3 = rom_write::flash_rom_address#0 [phi:rom_write::@4->rom_write::@1#1] -- register_copy 
    // [2894] phi rom_write::flashed_bytes#2 = rom_write::flashed_bytes#1 [phi:rom_write::@4->rom_write::@1#2] -- register_copy 
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
    // [2905] cbm_k_getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsrCBM_GETIN stach  }
    jsr CBM_GETIN
    sta ch
    // return ch;
    // [2907] cbm_k_getin::return#0 = cbm_k_getin::ch -- vbuaa=vbum1 
    // cbm_k_getin::@return
    // }
    // [2908] cbm_k_getin::return#1 = cbm_k_getin::return#0
    // [2909] return 
    rts
  .segment Data
    ch: .byte 0
}
.segment Code
  // display_vera_led
/**
 * @brief Print VERA led above the VERA chip.
 * 
 * @param c Led color
 */
// void display_vera_led(__zp($f4) char c)
display_vera_led: {
    .label c = $f4
    // display_chip_led(CHIP_VERA_X+1, CHIP_VERA_Y, CHIP_VERA_W, c, BLUE)
    // [2911] display_chip_led::tc#1 = display_vera_led::c#2 -- vbuxx=vbuz1 
    ldx.z c
    // [2912] call display_chip_led
    // [3136] phi from display_vera_led to display_chip_led [phi:display_vera_led->display_chip_led]
    // [3136] phi display_chip_led::w#7 = 8 [phi:display_vera_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #8
    sta.z display_chip_led.w
    // [3136] phi display_chip_led::x#7 = 9+1 [phi:display_vera_led->display_chip_led#1] -- vbuz1=vbuc1 
    lda #9+1
    sta.z display_chip_led.x
    // [3136] phi display_chip_led::tc#3 = display_chip_led::tc#1 [phi:display_vera_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_vera_led::@1
    // display_info_led(INFO_X-2, INFO_Y+1, c, BLUE)
    // [2913] display_info_led::tc#1 = display_vera_led::c#2 -- vbuxx=vbuz1 
    ldx.z c
    // [2914] call display_info_led
    // [2158] phi from display_vera_led::@1 to display_info_led [phi:display_vera_led::@1->display_info_led]
    // [2158] phi display_info_led::y#4 = $11+1 [phi:display_vera_led::@1->display_info_led#0] -- vbuz1=vbuc1 
    lda #$11+1
    sta.z display_info_led.y
    // [2158] phi display_info_led::x#4 = 4-2 [phi:display_vera_led::@1->display_info_led#1] -- vbuyy=vbuc1 
    ldy #4-2
    // [2158] phi display_info_led::tc#4 = display_info_led::tc#1 [phi:display_vera_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_vera_led::@return
    // }
    // [2915] return 
    rts
}
  // strncpy
/// Copies up to n characters from the string pointed to, by src to dst.
/// In a case where the length of src is less than that of n, the remainder of dst will be padded with null bytes.
/// @param dst ? This is the pointer to the destination array where the content is to be copied.
/// @param src ? This is the string to be copied.
/// @param n ? The number of characters to be copied from source.
/// @return The destination
// char * strncpy(__zp($5d) char *dst, __zp($59) const char *src, __mem() unsigned int n)
strncpy: {
    .label dst = $5d
    .label src = $59
    // [2917] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [2917] phi strncpy::dst#3 = strncpy::dst#8 [phi:strncpy->strncpy::@1#0] -- register_copy 
    // [2917] phi strncpy::src#3 = strncpy::src#6 [phi:strncpy->strncpy::@1#1] -- register_copy 
    // [2917] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwum1=vwuc1 
    lda #<0
    sta i
    sta i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [2918] if(strncpy::i#2<strncpy::n#3) goto strncpy::@2 -- vwum1_lt_vwum2_then_la1 
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
    // [2919] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [2920] strncpy::c#0 = *strncpy::src#3 -- vbuaa=_deref_pbuz1 
    ldy #0
    lda (src),y
    // if(c)
    // [2921] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b3
    // strncpy::@4
    // src++;
    // [2922] strncpy::src#0 = ++ strncpy::src#3 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [2923] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [2923] phi strncpy::src#7 = strncpy::src#3 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [2924] *strncpy::dst#3 = strncpy::c#0 -- _deref_pbuz1=vbuaa 
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [2925] strncpy::dst#0 = ++ strncpy::dst#3 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [2926] strncpy::i#1 = ++ strncpy::i#2 -- vwum1=_inc_vwum1 
    inc i
    bne !+
    inc i+1
  !:
    // [2917] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [2917] phi strncpy::dst#3 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [2917] phi strncpy::src#3 = strncpy::src#7 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [2917] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
    jmp __b1
  .segment Data
    .label i = fgets.remaining
    .label n = strncmp.n
}
.segment Code
  // utoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void utoa(__mem() unsigned int value, __zp($2a) char *buffer, __register(X) char radix)
utoa: {
    .label buffer = $2a
    .label digit_values = $3a
    // if(radix==DECIMAL)
    // [2927] if(utoa::radix#0==DECIMAL) goto utoa::@1 -- vbuxx_eq_vbuc1_then_la1 
    cpx #DECIMAL
    beq __b2
    // utoa::@2
    // if(radix==HEXADECIMAL)
    // [2928] if(utoa::radix#0==HEXADECIMAL) goto utoa::@1 -- vbuxx_eq_vbuc1_then_la1 
    cpx #HEXADECIMAL
    beq __b3
    // utoa::@3
    // if(radix==OCTAL)
    // [2929] if(utoa::radix#0==OCTAL) goto utoa::@1 -- vbuxx_eq_vbuc1_then_la1 
    cpx #OCTAL
    beq __b4
    // utoa::@4
    // if(radix==BINARY)
    // [2930] if(utoa::radix#0==BINARY) goto utoa::@1 -- vbuxx_eq_vbuc1_then_la1 
    cpx #BINARY
    beq __b5
    // utoa::@5
    // *buffer++ = 'e'
    // [2931] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2932] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2933] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2934] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // utoa::@return
    // }
    // [2935] return 
    rts
    // [2936] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
  __b2:
    // [2936] phi utoa::digit_values#8 = RADIX_DECIMAL_VALUES [phi:utoa->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_DECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES
    sta.z digit_values+1
    // [2936] phi utoa::max_digits#7 = 5 [phi:utoa->utoa::@1#1] -- vbum1=vbuc1 
    lda #5
    sta max_digits
    jmp __b1
    // [2936] phi from utoa::@2 to utoa::@1 [phi:utoa::@2->utoa::@1]
  __b3:
    // [2936] phi utoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES [phi:utoa::@2->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_HEXADECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES
    sta.z digit_values+1
    // [2936] phi utoa::max_digits#7 = 4 [phi:utoa::@2->utoa::@1#1] -- vbum1=vbuc1 
    lda #4
    sta max_digits
    jmp __b1
    // [2936] phi from utoa::@3 to utoa::@1 [phi:utoa::@3->utoa::@1]
  __b4:
    // [2936] phi utoa::digit_values#8 = RADIX_OCTAL_VALUES [phi:utoa::@3->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_OCTAL_VALUES
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES
    sta.z digit_values+1
    // [2936] phi utoa::max_digits#7 = 6 [phi:utoa::@3->utoa::@1#1] -- vbum1=vbuc1 
    lda #6
    sta max_digits
    jmp __b1
    // [2936] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
  __b5:
    // [2936] phi utoa::digit_values#8 = RADIX_BINARY_VALUES [phi:utoa::@4->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_BINARY_VALUES
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES
    sta.z digit_values+1
    // [2936] phi utoa::max_digits#7 = $10 [phi:utoa::@4->utoa::@1#1] -- vbum1=vbuc1 
    lda #$10
    sta max_digits
    // utoa::@1
  __b1:
    // [2937] phi from utoa::@1 to utoa::@6 [phi:utoa::@1->utoa::@6]
    // [2937] phi utoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa::@1->utoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2937] phi utoa::started#2 = 0 [phi:utoa::@1->utoa::@6#1] -- vbuxx=vbuc1 
    ldx #0
    // [2937] phi utoa::value#2 = utoa::value#1 [phi:utoa::@1->utoa::@6#2] -- register_copy 
    // [2937] phi utoa::digit#2 = 0 [phi:utoa::@1->utoa::@6#3] -- vbum1=vbuc1 
    txa
    sta digit
    // utoa::@6
  __b6:
    // max_digits-1
    // [2938] utoa::$4 = utoa::max_digits#7 - 1 -- vbuaa=vbum1_minus_1 
    lda max_digits
    sec
    sbc #1
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2939] if(utoa::digit#2<utoa::$4) goto utoa::@7 -- vbum1_lt_vbuaa_then_la1 
    cmp digit
    beq !+
    bcs __b7
  !:
    // utoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2940] utoa::$11 = (char)utoa::value#2 -- vbuxx=_byte_vwum1 
    ldx value
    // [2941] *utoa::buffer#11 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuxx 
    lda DIGITS,x
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2942] utoa::buffer#3 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2943] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // utoa::@7
  __b7:
    // unsigned int digit_value = digit_values[digit]
    // [2944] utoa::$10 = utoa::digit#2 << 1 -- vbuaa=vbum1_rol_1 
    lda digit
    asl
    // [2945] utoa::digit_value#0 = utoa::digit_values#8[utoa::$10] -- vwum1=pwuz2_derefidx_vbuaa 
    tay
    lda (digit_values),y
    sta digit_value
    iny
    lda (digit_values),y
    sta digit_value+1
    // if (started || value >= digit_value)
    // [2946] if(0!=utoa::started#2) goto utoa::@10 -- 0_neq_vbuxx_then_la1 
    cpx #0
    bne __b10
    // utoa::@12
    // [2947] if(utoa::value#2>=utoa::digit_value#0) goto utoa::@10 -- vwum1_ge_vwum2_then_la1 
    cmp value+1
    bne !+
    lda digit_value
    cmp value
    beq __b10
  !:
    bcc __b10
    // [2948] phi from utoa::@12 to utoa::@9 [phi:utoa::@12->utoa::@9]
    // [2948] phi utoa::buffer#14 = utoa::buffer#11 [phi:utoa::@12->utoa::@9#0] -- register_copy 
    // [2948] phi utoa::started#4 = utoa::started#2 [phi:utoa::@12->utoa::@9#1] -- register_copy 
    // [2948] phi utoa::value#6 = utoa::value#2 [phi:utoa::@12->utoa::@9#2] -- register_copy 
    // utoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2949] utoa::digit#1 = ++ utoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [2937] phi from utoa::@9 to utoa::@6 [phi:utoa::@9->utoa::@6]
    // [2937] phi utoa::buffer#11 = utoa::buffer#14 [phi:utoa::@9->utoa::@6#0] -- register_copy 
    // [2937] phi utoa::started#2 = utoa::started#4 [phi:utoa::@9->utoa::@6#1] -- register_copy 
    // [2937] phi utoa::value#2 = utoa::value#6 [phi:utoa::@9->utoa::@6#2] -- register_copy 
    // [2937] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@9->utoa::@6#3] -- register_copy 
    jmp __b6
    // utoa::@10
  __b10:
    // utoa_append(buffer++, value, digit_value)
    // [2950] utoa_append::buffer#0 = utoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [2951] utoa_append::value#0 = utoa::value#2
    // [2952] utoa_append::sub#0 = utoa::digit_value#0
    // [2953] call utoa_append
    // [3425] phi from utoa::@10 to utoa_append [phi:utoa::@10->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [2954] utoa_append::return#0 = utoa_append::value#2
    // utoa::@11
    // value = utoa_append(buffer++, value, digit_value)
    // [2955] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [2956] utoa::buffer#4 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2948] phi from utoa::@11 to utoa::@9 [phi:utoa::@11->utoa::@9]
    // [2948] phi utoa::buffer#14 = utoa::buffer#4 [phi:utoa::@11->utoa::@9#0] -- register_copy 
    // [2948] phi utoa::started#4 = 1 [phi:utoa::@11->utoa::@9#1] -- vbuxx=vbuc1 
    ldx #1
    // [2948] phi utoa::value#6 = utoa::value#0 [phi:utoa::@11->utoa::@9#2] -- register_copy 
    jmp __b9
  .segment Data
    .label digit_value = fgets.remaining
    .label digit = uctoa.digit
    .label value = strncmp.n
    .label max_digits = printf_string.format_justify_left
}
.segment Code
  // insertup
// Insert a new line, and scroll the upper part of the screen up.
// void insertup(char rows)
insertup: {
    // __conio.width+1
    // [2957] insertup::$0 = *((char *)&__conio+6) + 1 -- vbuaa=_deref_pbuc1_plus_1 
    lda __conio+6
    inc
    // unsigned char width = (__conio.width+1) * 2
    // [2958] insertup::width#0 = insertup::$0 << 1 -- vbum1=vbuaa_rol_1 
    // {asm{.byte $db}}
    asl
    sta width
    // [2959] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [2959] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbum1=vbuc1 
    lda #0
    sta y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [2960] if(insertup::y#2<*((char *)&__conio+1)) goto insertup::@2 -- vbum1_lt__deref_pbuc1_then_la1 
    lda y
    cmp __conio+1
    bcc __b2
    // [2961] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [2962] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [2963] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [2964] insertup::$4 = insertup::y#2 + 1 -- vbuxx=vbum1_plus_1 
    ldx y
    inx
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [2965] insertup::$6 = insertup::y#2 << 1 -- vbuyy=vbum1_rol_1 
    lda y
    asl
    tay
    // [2966] insertup::$7 = insertup::$4 << 1 -- vbuxx=vbuxx_rol_1 
    txa
    asl
    tax
    // [2967] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+5) -- vbum1=_deref_pbuc1 
    lda __conio+5
    sta memcpy8_vram_vram.dbank_vram
    // [2968] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwum1=pwuc1_derefidx_vbuyy 
    lda __conio+$15,y
    sta memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta memcpy8_vram_vram.doffset_vram+1
    // [2969] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+5) -- vbum1=_deref_pbuc1 
    lda __conio+5
    sta memcpy8_vram_vram.sbank_vram
    // [2970] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwum1=pwuc1_derefidx_vbuxx 
    lda __conio+$15,x
    sta memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,x
    sta memcpy8_vram_vram.soffset_vram+1
    // [2971] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbuyy=vbum1 
    ldy width
    // [2972] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [2973] insertup::y#1 = ++ insertup::y#2 -- vbum1=_inc_vbum1 
    inc y
    // [2959] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [2959] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    width: .byte 0
    y: .byte 0
}
.segment Code
  // clearline
clearline: {
    // unsigned int addr = __conio.offsets[__conio.cursor_y]
    // [2974] clearline::$3 = *((char *)&__conio+1) << 1 -- vbuaa=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    // [2975] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwum1=pwuc1_derefidx_vbuaa 
    tay
    lda __conio+$15,y
    sta addr
    lda __conio+$15+1,y
    sta addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2976] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [2977] clearline::$0 = byte0  clearline::addr#0 -- vbuaa=_byte0_vwum1 
    lda addr
    // *VERA_ADDRX_L = BYTE0(addr)
    // [2978] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [2979] clearline::$1 = byte1  clearline::addr#0 -- vbuaa=_byte1_vwum1 
    lda addr+1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [2980] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [2981] clearline::$2 = *((char *)&__conio+5) | VERA_INC_1 -- vbuaa=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [2982] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [2983] clearline::c#0 = *((char *)&__conio+6) -- vbuxx=_deref_pbuc1 
    ldx __conio+6
    // [2984] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [2984] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [2985] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [2986] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [2987] clearline::c#1 = -- clearline::c#2 -- vbuxx=_dec_vbuxx 
    dex
    // while(c)
    // [2988] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuxx_then_la1 
    cpx #0
    bne __b1
    // clearline::@return
    // }
    // [2989] return 
    rts
  .segment Data
    .label addr = memcpy8_vram_vram.doffset_vram
}
.segment Code
  // cx16_k_screen_set_mode
/**
 * @brief Sets the screen mode.
 *
 * @return cx16_k_screen_mode_error_t Contains 1 if there is an error.
 */
// char cx16_k_screen_set_mode(__mem() volatile char mode)
cx16_k_screen_set_mode: {
    // cx16_k_screen_mode_error_t error = 0
    // [2990] cx16_k_screen_set_mode::error = 0 -- vbum1=vbuc1 
    lda #0
    sta error
    // asm
    // asm { clc ldamode jsrCX16_SCREEN_MODE rolerror  }
    clc
    lda mode
    jsr CX16_SCREEN_MODE
    rol error
    // cx16_k_screen_set_mode::@return
    // }
    // [2992] return 
    rts
  .segment Data
    mode: .byte 0
    error: .byte 0
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
// void display_frame(char x0, char y0, __mem() char x1, __mem() char y1)
display_frame: {
    // unsigned char w = x1 - x0
    // [2994] display_frame::w#0 = display_frame::x1#16 - display_frame::x#0 -- vbum1=vbum2_minus_vbum3 
    lda x1
    sec
    sbc x
    sta w
    // unsigned char h = y1 - y0
    // [2995] display_frame::h#0 = display_frame::y1#16 - display_frame::y#0 -- vbum1=vbum2_minus_vbum3 
    lda y1
    sec
    sbc y
    sta h
    // unsigned char mask = display_frame_maskxy(x, y)
    // [2996] display_frame_maskxy::x#0 = display_frame::x#0 -- vbuyy=vbum1 
    ldy x
    // [2997] display_frame_maskxy::y#0 = display_frame::y#0 -- vbuaa=vbum1 
    lda y
    // [2998] call display_frame_maskxy
    // [3452] phi from display_frame to display_frame_maskxy [phi:display_frame->display_frame_maskxy]
    // [3452] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#0 [phi:display_frame->display_frame_maskxy#0] -- register_copy 
    // [3452] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#0 [phi:display_frame->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // unsigned char mask = display_frame_maskxy(x, y)
    // [2999] display_frame_maskxy::return#13 = display_frame_maskxy::return#12
    // display_frame::@13
    // [3000] display_frame::mask#0 = display_frame_maskxy::return#13
    // mask |= 0b0110
    // [3001] display_frame::mask#1 = display_frame::mask#0 | 6 -- vbuaa=vbuaa_bor_vbuc1 
    ora #6
    // unsigned char c = display_frame_char(mask)
    // [3002] display_frame_char::mask#0 = display_frame::mask#1
    // [3003] call display_frame_char
  // Add a corner.
    // [3478] phi from display_frame::@13 to display_frame_char [phi:display_frame::@13->display_frame_char]
    // [3478] phi display_frame_char::mask#10 = display_frame_char::mask#0 [phi:display_frame::@13->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // unsigned char c = display_frame_char(mask)
    // [3004] display_frame_char::return#13 = display_frame_char::return#12
    // display_frame::@14
    // [3005] display_frame::c#0 = display_frame_char::return#13 -- vbuxx=vbuaa 
    tax
    // cputcxy(x, y, c)
    // [3006] cputcxy::x#0 = display_frame::x#0 -- vbuyy=vbum1 
    ldy x
    // [3007] cputcxy::y#0 = display_frame::y#0 -- vbuaa=vbum1 
    lda y
    // [3008] cputcxy::c#0 = display_frame::c#0
    // [3009] call cputcxy
    // [2273] phi from display_frame::@14 to cputcxy [phi:display_frame::@14->cputcxy]
    // [2273] phi cputcxy::c#17 = cputcxy::c#0 [phi:display_frame::@14->cputcxy#0] -- register_copy 
    // [2273] phi cputcxy::y#17 = cputcxy::y#0 [phi:display_frame::@14->cputcxy#1] -- register_copy 
    // [2273] phi cputcxy::x#17 = cputcxy::x#0 [phi:display_frame::@14->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@15
    // if(w>=2)
    // [3010] if(display_frame::w#0<2) goto display_frame::@36 -- vbum1_lt_vbuc1_then_la1 
    lda w
    cmp #2
    bcs !__b36+
    jmp __b36
  !__b36:
    // display_frame::@2
    // x++;
    // [3011] display_frame::x#1 = ++ display_frame::x#0 -- vbum1=_inc_vbum2 
    lda x
    inc
    sta x_1
    // [3012] phi from display_frame::@2 display_frame::@21 to display_frame::@4 [phi:display_frame::@2/display_frame::@21->display_frame::@4]
    // [3012] phi display_frame::x#10 = display_frame::x#1 [phi:display_frame::@2/display_frame::@21->display_frame::@4#0] -- register_copy 
    // display_frame::@4
  __b4:
    // while(x < x1)
    // [3013] if(display_frame::x#10<display_frame::x1#16) goto display_frame::@5 -- vbum1_lt_vbum2_then_la1 
    lda x_1
    cmp x1
    bcs !__b5+
    jmp __b5
  !__b5:
    // [3014] phi from display_frame::@36 display_frame::@4 to display_frame::@1 [phi:display_frame::@36/display_frame::@4->display_frame::@1]
    // [3014] phi display_frame::x#24 = display_frame::x#30 [phi:display_frame::@36/display_frame::@4->display_frame::@1#0] -- register_copy 
    // display_frame::@1
  __b1:
    // display_frame_maskxy(x, y)
    // [3015] display_frame_maskxy::x#1 = display_frame::x#24 -- vbuyy=vbum1 
    ldy x_1
    // [3016] display_frame_maskxy::y#1 = display_frame::y#0 -- vbuaa=vbum1 
    lda y
    // [3017] call display_frame_maskxy
    // [3452] phi from display_frame::@1 to display_frame_maskxy [phi:display_frame::@1->display_frame_maskxy]
    // [3452] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#1 [phi:display_frame::@1->display_frame_maskxy#0] -- register_copy 
    // [3452] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#1 [phi:display_frame::@1->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [3018] display_frame_maskxy::return#14 = display_frame_maskxy::return#12
    // display_frame::@16
    // mask = display_frame_maskxy(x, y)
    // [3019] display_frame::mask#2 = display_frame_maskxy::return#14
    // mask |= 0b0011
    // [3020] display_frame::mask#3 = display_frame::mask#2 | 3 -- vbuaa=vbuaa_bor_vbuc1 
    ora #3
    // display_frame_char(mask)
    // [3021] display_frame_char::mask#1 = display_frame::mask#3
    // [3022] call display_frame_char
    // [3478] phi from display_frame::@16 to display_frame_char [phi:display_frame::@16->display_frame_char]
    // [3478] phi display_frame_char::mask#10 = display_frame_char::mask#1 [phi:display_frame::@16->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [3023] display_frame_char::return#14 = display_frame_char::return#12
    // display_frame::@17
    // c = display_frame_char(mask)
    // [3024] display_frame::c#1 = display_frame_char::return#14 -- vbuxx=vbuaa 
    tax
    // cputcxy(x, y, c)
    // [3025] cputcxy::x#1 = display_frame::x#24 -- vbuyy=vbum1 
    ldy x_1
    // [3026] cputcxy::y#1 = display_frame::y#0 -- vbuaa=vbum1 
    lda y
    // [3027] cputcxy::c#1 = display_frame::c#1
    // [3028] call cputcxy
    // [2273] phi from display_frame::@17 to cputcxy [phi:display_frame::@17->cputcxy]
    // [2273] phi cputcxy::c#17 = cputcxy::c#1 [phi:display_frame::@17->cputcxy#0] -- register_copy 
    // [2273] phi cputcxy::y#17 = cputcxy::y#1 [phi:display_frame::@17->cputcxy#1] -- register_copy 
    // [2273] phi cputcxy::x#17 = cputcxy::x#1 [phi:display_frame::@17->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@18
    // if(h>=2)
    // [3029] if(display_frame::h#0<2) goto display_frame::@return -- vbum1_lt_vbuc1_then_la1 
    lda h
    cmp #2
    bcc __breturn
    // display_frame::@3
    // y++;
    // [3030] display_frame::y#1 = ++ display_frame::y#0 -- vbum1=_inc_vbum2 
    lda y
    inc
    sta y_1
    // [3031] phi from display_frame::@27 display_frame::@3 to display_frame::@6 [phi:display_frame::@27/display_frame::@3->display_frame::@6]
    // [3031] phi display_frame::y#10 = display_frame::y#2 [phi:display_frame::@27/display_frame::@3->display_frame::@6#0] -- register_copy 
    // display_frame::@6
  __b6:
    // while(y < y1)
    // [3032] if(display_frame::y#10<display_frame::y1#16) goto display_frame::@7 -- vbum1_lt_vbum2_then_la1 
    lda y_1
    cmp y1
    bcc __b7
    // display_frame::@8
    // display_frame_maskxy(x, y)
    // [3033] display_frame_maskxy::x#5 = display_frame::x#0 -- vbuyy=vbum1 
    ldy x
    // [3034] display_frame_maskxy::y#5 = display_frame::y#10 -- vbuaa=vbum1 
    // [3035] call display_frame_maskxy
    // [3452] phi from display_frame::@8 to display_frame_maskxy [phi:display_frame::@8->display_frame_maskxy]
    // [3452] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#5 [phi:display_frame::@8->display_frame_maskxy#0] -- register_copy 
    // [3452] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#5 [phi:display_frame::@8->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [3036] display_frame_maskxy::return#18 = display_frame_maskxy::return#12
    // display_frame::@28
    // mask = display_frame_maskxy(x, y)
    // [3037] display_frame::mask#10 = display_frame_maskxy::return#18
    // mask |= 0b1100
    // [3038] display_frame::mask#11 = display_frame::mask#10 | $c -- vbuaa=vbuaa_bor_vbuc1 
    ora #$c
    // display_frame_char(mask)
    // [3039] display_frame_char::mask#5 = display_frame::mask#11
    // [3040] call display_frame_char
    // [3478] phi from display_frame::@28 to display_frame_char [phi:display_frame::@28->display_frame_char]
    // [3478] phi display_frame_char::mask#10 = display_frame_char::mask#5 [phi:display_frame::@28->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [3041] display_frame_char::return#18 = display_frame_char::return#12
    // display_frame::@29
    // c = display_frame_char(mask)
    // [3042] display_frame::c#5 = display_frame_char::return#18 -- vbuxx=vbuaa 
    tax
    // cputcxy(x, y, c)
    // [3043] cputcxy::x#5 = display_frame::x#0 -- vbuyy=vbum1 
    ldy x
    // [3044] cputcxy::y#5 = display_frame::y#10 -- vbuaa=vbum1 
    lda y_1
    // [3045] cputcxy::c#5 = display_frame::c#5
    // [3046] call cputcxy
    // [2273] phi from display_frame::@29 to cputcxy [phi:display_frame::@29->cputcxy]
    // [2273] phi cputcxy::c#17 = cputcxy::c#5 [phi:display_frame::@29->cputcxy#0] -- register_copy 
    // [2273] phi cputcxy::y#17 = cputcxy::y#5 [phi:display_frame::@29->cputcxy#1] -- register_copy 
    // [2273] phi cputcxy::x#17 = cputcxy::x#5 [phi:display_frame::@29->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@30
    // if(w>=2)
    // [3047] if(display_frame::w#0<2) goto display_frame::@10 -- vbum1_lt_vbuc1_then_la1 
    lda w
    cmp #2
    bcc __b10
    // display_frame::@9
    // x++;
    // [3048] display_frame::x#4 = ++ display_frame::x#0 -- vbum1=_inc_vbum1 
    inc x
    // [3049] phi from display_frame::@35 display_frame::@9 to display_frame::@11 [phi:display_frame::@35/display_frame::@9->display_frame::@11]
    // [3049] phi display_frame::x#18 = display_frame::x#5 [phi:display_frame::@35/display_frame::@9->display_frame::@11#0] -- register_copy 
    // display_frame::@11
  __b11:
    // while(x < x1)
    // [3050] if(display_frame::x#18<display_frame::x1#16) goto display_frame::@12 -- vbum1_lt_vbum2_then_la1 
    lda x
    cmp x1
    bcc __b12
    // [3051] phi from display_frame::@11 display_frame::@30 to display_frame::@10 [phi:display_frame::@11/display_frame::@30->display_frame::@10]
    // [3051] phi display_frame::x#15 = display_frame::x#18 [phi:display_frame::@11/display_frame::@30->display_frame::@10#0] -- register_copy 
    // display_frame::@10
  __b10:
    // display_frame_maskxy(x, y)
    // [3052] display_frame_maskxy::x#6 = display_frame::x#15 -- vbuyy=vbum1 
    ldy x
    // [3053] display_frame_maskxy::y#6 = display_frame::y#10 -- vbuaa=vbum1 
    lda y_1
    // [3054] call display_frame_maskxy
    // [3452] phi from display_frame::@10 to display_frame_maskxy [phi:display_frame::@10->display_frame_maskxy]
    // [3452] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#6 [phi:display_frame::@10->display_frame_maskxy#0] -- register_copy 
    // [3452] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#6 [phi:display_frame::@10->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [3055] display_frame_maskxy::return#19 = display_frame_maskxy::return#12
    // display_frame::@31
    // mask = display_frame_maskxy(x, y)
    // [3056] display_frame::mask#12 = display_frame_maskxy::return#19
    // mask |= 0b1001
    // [3057] display_frame::mask#13 = display_frame::mask#12 | 9 -- vbuaa=vbuaa_bor_vbuc1 
    ora #9
    // display_frame_char(mask)
    // [3058] display_frame_char::mask#6 = display_frame::mask#13
    // [3059] call display_frame_char
    // [3478] phi from display_frame::@31 to display_frame_char [phi:display_frame::@31->display_frame_char]
    // [3478] phi display_frame_char::mask#10 = display_frame_char::mask#6 [phi:display_frame::@31->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [3060] display_frame_char::return#19 = display_frame_char::return#12
    // display_frame::@32
    // c = display_frame_char(mask)
    // [3061] display_frame::c#6 = display_frame_char::return#19 -- vbuxx=vbuaa 
    tax
    // cputcxy(x, y, c)
    // [3062] cputcxy::x#6 = display_frame::x#15 -- vbuyy=vbum1 
    ldy x
    // [3063] cputcxy::y#6 = display_frame::y#10 -- vbuaa=vbum1 
    lda y_1
    // [3064] cputcxy::c#6 = display_frame::c#6
    // [3065] call cputcxy
    // [2273] phi from display_frame::@32 to cputcxy [phi:display_frame::@32->cputcxy]
    // [2273] phi cputcxy::c#17 = cputcxy::c#6 [phi:display_frame::@32->cputcxy#0] -- register_copy 
    // [2273] phi cputcxy::y#17 = cputcxy::y#6 [phi:display_frame::@32->cputcxy#1] -- register_copy 
    // [2273] phi cputcxy::x#17 = cputcxy::x#6 [phi:display_frame::@32->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@return
  __breturn:
    // }
    // [3066] return 
    rts
    // display_frame::@12
  __b12:
    // display_frame_maskxy(x, y)
    // [3067] display_frame_maskxy::x#7 = display_frame::x#18 -- vbuyy=vbum1 
    ldy x
    // [3068] display_frame_maskxy::y#7 = display_frame::y#10 -- vbuaa=vbum1 
    lda y_1
    // [3069] call display_frame_maskxy
    // [3452] phi from display_frame::@12 to display_frame_maskxy [phi:display_frame::@12->display_frame_maskxy]
    // [3452] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#7 [phi:display_frame::@12->display_frame_maskxy#0] -- register_copy 
    // [3452] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#7 [phi:display_frame::@12->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [3070] display_frame_maskxy::return#20 = display_frame_maskxy::return#12
    // display_frame::@33
    // mask = display_frame_maskxy(x, y)
    // [3071] display_frame::mask#14 = display_frame_maskxy::return#20
    // mask |= 0b0101
    // [3072] display_frame::mask#15 = display_frame::mask#14 | 5 -- vbuaa=vbuaa_bor_vbuc1 
    ora #5
    // display_frame_char(mask)
    // [3073] display_frame_char::mask#7 = display_frame::mask#15
    // [3074] call display_frame_char
    // [3478] phi from display_frame::@33 to display_frame_char [phi:display_frame::@33->display_frame_char]
    // [3478] phi display_frame_char::mask#10 = display_frame_char::mask#7 [phi:display_frame::@33->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [3075] display_frame_char::return#20 = display_frame_char::return#12
    // display_frame::@34
    // c = display_frame_char(mask)
    // [3076] display_frame::c#7 = display_frame_char::return#20 -- vbuxx=vbuaa 
    tax
    // cputcxy(x, y, c)
    // [3077] cputcxy::x#7 = display_frame::x#18 -- vbuyy=vbum1 
    ldy x
    // [3078] cputcxy::y#7 = display_frame::y#10 -- vbuaa=vbum1 
    lda y_1
    // [3079] cputcxy::c#7 = display_frame::c#7
    // [3080] call cputcxy
    // [2273] phi from display_frame::@34 to cputcxy [phi:display_frame::@34->cputcxy]
    // [2273] phi cputcxy::c#17 = cputcxy::c#7 [phi:display_frame::@34->cputcxy#0] -- register_copy 
    // [2273] phi cputcxy::y#17 = cputcxy::y#7 [phi:display_frame::@34->cputcxy#1] -- register_copy 
    // [2273] phi cputcxy::x#17 = cputcxy::x#7 [phi:display_frame::@34->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@35
    // x++;
    // [3081] display_frame::x#5 = ++ display_frame::x#18 -- vbum1=_inc_vbum1 
    inc x
    jmp __b11
    // display_frame::@7
  __b7:
    // display_frame_maskxy(x0, y)
    // [3082] display_frame_maskxy::x#3 = display_frame::x#0 -- vbuyy=vbum1 
    ldy x
    // [3083] display_frame_maskxy::y#3 = display_frame::y#10 -- vbuaa=vbum1 
    lda y_1
    // [3084] call display_frame_maskxy
    // [3452] phi from display_frame::@7 to display_frame_maskxy [phi:display_frame::@7->display_frame_maskxy]
    // [3452] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#3 [phi:display_frame::@7->display_frame_maskxy#0] -- register_copy 
    // [3452] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#3 [phi:display_frame::@7->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x0, y)
    // [3085] display_frame_maskxy::return#16 = display_frame_maskxy::return#12
    // display_frame::@22
    // mask = display_frame_maskxy(x0, y)
    // [3086] display_frame::mask#6 = display_frame_maskxy::return#16
    // mask |= 0b1010
    // [3087] display_frame::mask#7 = display_frame::mask#6 | $a -- vbuaa=vbuaa_bor_vbuc1 
    ora #$a
    // display_frame_char(mask)
    // [3088] display_frame_char::mask#3 = display_frame::mask#7
    // [3089] call display_frame_char
    // [3478] phi from display_frame::@22 to display_frame_char [phi:display_frame::@22->display_frame_char]
    // [3478] phi display_frame_char::mask#10 = display_frame_char::mask#3 [phi:display_frame::@22->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [3090] display_frame_char::return#16 = display_frame_char::return#12
    // display_frame::@23
    // c = display_frame_char(mask)
    // [3091] display_frame::c#3 = display_frame_char::return#16 -- vbuxx=vbuaa 
    tax
    // cputcxy(x0, y, c)
    // [3092] cputcxy::x#3 = display_frame::x#0 -- vbuyy=vbum1 
    ldy x
    // [3093] cputcxy::y#3 = display_frame::y#10 -- vbuaa=vbum1 
    lda y_1
    // [3094] cputcxy::c#3 = display_frame::c#3
    // [3095] call cputcxy
    // [2273] phi from display_frame::@23 to cputcxy [phi:display_frame::@23->cputcxy]
    // [2273] phi cputcxy::c#17 = cputcxy::c#3 [phi:display_frame::@23->cputcxy#0] -- register_copy 
    // [2273] phi cputcxy::y#17 = cputcxy::y#3 [phi:display_frame::@23->cputcxy#1] -- register_copy 
    // [2273] phi cputcxy::x#17 = cputcxy::x#3 [phi:display_frame::@23->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@24
    // display_frame_maskxy(x1, y)
    // [3096] display_frame_maskxy::x#4 = display_frame::x1#16 -- vbuyy=vbum1 
    ldy x1
    // [3097] display_frame_maskxy::y#4 = display_frame::y#10 -- vbuaa=vbum1 
    lda y_1
    // [3098] call display_frame_maskxy
    // [3452] phi from display_frame::@24 to display_frame_maskxy [phi:display_frame::@24->display_frame_maskxy]
    // [3452] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#4 [phi:display_frame::@24->display_frame_maskxy#0] -- register_copy 
    // [3452] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#4 [phi:display_frame::@24->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x1, y)
    // [3099] display_frame_maskxy::return#17 = display_frame_maskxy::return#12
    // display_frame::@25
    // mask = display_frame_maskxy(x1, y)
    // [3100] display_frame::mask#8 = display_frame_maskxy::return#17
    // mask |= 0b1010
    // [3101] display_frame::mask#9 = display_frame::mask#8 | $a -- vbuaa=vbuaa_bor_vbuc1 
    ora #$a
    // display_frame_char(mask)
    // [3102] display_frame_char::mask#4 = display_frame::mask#9
    // [3103] call display_frame_char
    // [3478] phi from display_frame::@25 to display_frame_char [phi:display_frame::@25->display_frame_char]
    // [3478] phi display_frame_char::mask#10 = display_frame_char::mask#4 [phi:display_frame::@25->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [3104] display_frame_char::return#17 = display_frame_char::return#12
    // display_frame::@26
    // c = display_frame_char(mask)
    // [3105] display_frame::c#4 = display_frame_char::return#17 -- vbuxx=vbuaa 
    tax
    // cputcxy(x1, y, c)
    // [3106] cputcxy::x#4 = display_frame::x1#16 -- vbuyy=vbum1 
    ldy x1
    // [3107] cputcxy::y#4 = display_frame::y#10 -- vbuaa=vbum1 
    lda y_1
    // [3108] cputcxy::c#4 = display_frame::c#4
    // [3109] call cputcxy
    // [2273] phi from display_frame::@26 to cputcxy [phi:display_frame::@26->cputcxy]
    // [2273] phi cputcxy::c#17 = cputcxy::c#4 [phi:display_frame::@26->cputcxy#0] -- register_copy 
    // [2273] phi cputcxy::y#17 = cputcxy::y#4 [phi:display_frame::@26->cputcxy#1] -- register_copy 
    // [2273] phi cputcxy::x#17 = cputcxy::x#4 [phi:display_frame::@26->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@27
    // y++;
    // [3110] display_frame::y#2 = ++ display_frame::y#10 -- vbum1=_inc_vbum1 
    inc y_1
    jmp __b6
    // display_frame::@5
  __b5:
    // display_frame_maskxy(x, y)
    // [3111] display_frame_maskxy::x#2 = display_frame::x#10 -- vbuyy=vbum1 
    ldy x_1
    // [3112] display_frame_maskxy::y#2 = display_frame::y#0 -- vbuaa=vbum1 
    lda y
    // [3113] call display_frame_maskxy
    // [3452] phi from display_frame::@5 to display_frame_maskxy [phi:display_frame::@5->display_frame_maskxy]
    // [3452] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#2 [phi:display_frame::@5->display_frame_maskxy#0] -- register_copy 
    // [3452] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#2 [phi:display_frame::@5->display_frame_maskxy#1] -- register_copy 
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [3114] display_frame_maskxy::return#15 = display_frame_maskxy::return#12
    // display_frame::@19
    // mask = display_frame_maskxy(x, y)
    // [3115] display_frame::mask#4 = display_frame_maskxy::return#15
    // mask |= 0b0101
    // [3116] display_frame::mask#5 = display_frame::mask#4 | 5 -- vbuaa=vbuaa_bor_vbuc1 
    ora #5
    // display_frame_char(mask)
    // [3117] display_frame_char::mask#2 = display_frame::mask#5
    // [3118] call display_frame_char
    // [3478] phi from display_frame::@19 to display_frame_char [phi:display_frame::@19->display_frame_char]
    // [3478] phi display_frame_char::mask#10 = display_frame_char::mask#2 [phi:display_frame::@19->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [3119] display_frame_char::return#15 = display_frame_char::return#12
    // display_frame::@20
    // c = display_frame_char(mask)
    // [3120] display_frame::c#2 = display_frame_char::return#15 -- vbuxx=vbuaa 
    tax
    // cputcxy(x, y, c)
    // [3121] cputcxy::x#2 = display_frame::x#10 -- vbuyy=vbum1 
    ldy x_1
    // [3122] cputcxy::y#2 = display_frame::y#0 -- vbuaa=vbum1 
    lda y
    // [3123] cputcxy::c#2 = display_frame::c#2
    // [3124] call cputcxy
    // [2273] phi from display_frame::@20 to cputcxy [phi:display_frame::@20->cputcxy]
    // [2273] phi cputcxy::c#17 = cputcxy::c#2 [phi:display_frame::@20->cputcxy#0] -- register_copy 
    // [2273] phi cputcxy::y#17 = cputcxy::y#2 [phi:display_frame::@20->cputcxy#1] -- register_copy 
    // [2273] phi cputcxy::x#17 = cputcxy::x#2 [phi:display_frame::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@21
    // x++;
    // [3125] display_frame::x#2 = ++ display_frame::x#10 -- vbum1=_inc_vbum1 
    inc x_1
    jmp __b4
    // display_frame::@36
  __b36:
    // [3126] display_frame::x#30 = display_frame::x#0 -- vbum1=vbum2 
    lda x
    sta x_1
    jmp __b1
  .segment Data
    w: .byte 0
    h: .byte 0
    x: .byte 0
    y: .byte 0
    x_1: .byte 0
    y_1: .byte 0
    x1: .byte 0
    y1: .byte 0
}
.segment Code
  // cputs
// Output a NUL-terminated string at the current cursor position
// void cputs(__zp($6d) const char *s)
cputs: {
    .label s = $6d
    // [3128] phi from cputs cputs::@2 to cputs::@1 [phi:cputs/cputs::@2->cputs::@1]
    // [3128] phi cputs::s#2 = cputs::s#1 [phi:cputs/cputs::@2->cputs::@1#0] -- register_copy 
    // cputs::@1
  __b1:
    // while(c=*s++)
    // [3129] cputs::c#1 = *cputs::s#2 -- vbuaa=_deref_pbuz1 
    ldy #0
    lda (s),y
    // [3130] cputs::s#0 = ++ cputs::s#2 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [3131] if(0!=cputs::c#1) goto cputs::@2 -- 0_neq_vbuaa_then_la1 
    cmp #0
    bne __b2
    // cputs::@return
    // }
    // [3132] return 
    rts
    // cputs::@2
  __b2:
    // cputc(c)
    // [3133] stackpush(char) = cputs::c#1 -- _stackpushbyte_=vbuaa 
    pha
    // [3134] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
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
// void display_chip_led(__zp($6a) char x, char y, __zp($69) char w, __register(X) char tc, char bc)
display_chip_led: {
    .label x = $6a
    .label w = $69
    // textcolor(tc)
    // [3137] textcolor::color#11 = display_chip_led::tc#3
    // [3138] call textcolor
    // [787] phi from display_chip_led to textcolor [phi:display_chip_led->textcolor]
    // [787] phi textcolor::color#23 = textcolor::color#11 [phi:display_chip_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [3139] phi from display_chip_led to display_chip_led::@3 [phi:display_chip_led->display_chip_led::@3]
    // display_chip_led::@3
    // bgcolor(bc)
    // [3140] call bgcolor
    // [792] phi from display_chip_led::@3 to bgcolor [phi:display_chip_led::@3->bgcolor]
    // [792] phi bgcolor::color#15 = BLUE [phi:display_chip_led::@3->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // [3141] phi from display_chip_led::@3 display_chip_led::@5 to display_chip_led::@1 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1]
    // [3141] phi display_chip_led::w#4 = display_chip_led::w#7 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1#0] -- register_copy 
    // [3141] phi display_chip_led::x#4 = display_chip_led::x#7 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1#1] -- register_copy 
    // display_chip_led::@1
  __b1:
    // cputcxy(x, y, 0x6F)
    // [3142] cputcxy::x#9 = display_chip_led::x#4 -- vbuyy=vbuz1 
    ldy.z x
    // [3143] call cputcxy
    // [2273] phi from display_chip_led::@1 to cputcxy [phi:display_chip_led::@1->cputcxy]
    // [2273] phi cputcxy::c#17 = $6f [phi:display_chip_led::@1->cputcxy#0] -- vbuxx=vbuc1 
    ldx #$6f
    // [2273] phi cputcxy::y#17 = 3 [phi:display_chip_led::@1->cputcxy#1] -- vbuaa=vbuc1 
    lda #3
    // [2273] phi cputcxy::x#17 = cputcxy::x#9 [phi:display_chip_led::@1->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_led::@4
    // cputcxy(x, y+1, 0x77)
    // [3144] cputcxy::x#10 = display_chip_led::x#4 -- vbuyy=vbuz1 
    ldy.z x
    // [3145] call cputcxy
    // [2273] phi from display_chip_led::@4 to cputcxy [phi:display_chip_led::@4->cputcxy]
    // [2273] phi cputcxy::c#17 = $77 [phi:display_chip_led::@4->cputcxy#0] -- vbuxx=vbuc1 
    ldx #$77
    // [2273] phi cputcxy::y#17 = 3+1 [phi:display_chip_led::@4->cputcxy#1] -- vbuaa=vbuc1 
    lda #3+1
    // [2273] phi cputcxy::x#17 = cputcxy::x#10 [phi:display_chip_led::@4->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_led::@5
    // x++;
    // [3146] display_chip_led::x#0 = ++ display_chip_led::x#4 -- vbuz1=_inc_vbuz1 
    inc.z x
    // while(--w)
    // [3147] display_chip_led::w#0 = -- display_chip_led::w#4 -- vbuz1=_dec_vbuz1 
    dec.z w
    // [3148] if(0!=display_chip_led::w#0) goto display_chip_led::@1 -- 0_neq_vbuz1_then_la1 
    lda.z w
    bne __b1
    // [3149] phi from display_chip_led::@5 to display_chip_led::@2 [phi:display_chip_led::@5->display_chip_led::@2]
    // display_chip_led::@2
    // textcolor(WHITE)
    // [3150] call textcolor
    // [787] phi from display_chip_led::@2 to textcolor [phi:display_chip_led::@2->textcolor]
    // [787] phi textcolor::color#23 = WHITE [phi:display_chip_led::@2->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [3151] phi from display_chip_led::@2 to display_chip_led::@6 [phi:display_chip_led::@2->display_chip_led::@6]
    // display_chip_led::@6
    // bgcolor(BLUE)
    // [3152] call bgcolor
    // [792] phi from display_chip_led::@6 to bgcolor [phi:display_chip_led::@6->bgcolor]
    // [792] phi bgcolor::color#15 = BLUE [phi:display_chip_led::@6->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // display_chip_led::@return
    // }
    // [3153] return 
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
// void display_chip_line(__zp($fb) char x, __mem() char y, __zp($cc) char w, __zp($eb) char c)
display_chip_line: {
    .label i = $7b
    .label x = $fb
    .label w = $cc
    .label c = $eb
    // gotoxy(x, y)
    // [3155] gotoxy::x#7 = display_chip_line::x#16 -- vbuyy=vbuz1 
    ldy.z x
    // [3156] gotoxy::y#7 = display_chip_line::y#16 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [3157] call gotoxy
    // [805] phi from display_chip_line to gotoxy [phi:display_chip_line->gotoxy]
    // [805] phi gotoxy::y#37 = gotoxy::y#7 [phi:display_chip_line->gotoxy#0] -- register_copy 
    // [805] phi gotoxy::x#37 = gotoxy::x#7 [phi:display_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [3158] phi from display_chip_line to display_chip_line::@4 [phi:display_chip_line->display_chip_line::@4]
    // display_chip_line::@4
    // textcolor(GREY)
    // [3159] call textcolor
    // [787] phi from display_chip_line::@4 to textcolor [phi:display_chip_line::@4->textcolor]
    // [787] phi textcolor::color#23 = GREY [phi:display_chip_line::@4->textcolor#0] -- vbuxx=vbuc1 
    ldx #GREY
    jsr textcolor
    // [3160] phi from display_chip_line::@4 to display_chip_line::@5 [phi:display_chip_line::@4->display_chip_line::@5]
    // display_chip_line::@5
    // bgcolor(BLUE)
    // [3161] call bgcolor
    // [792] phi from display_chip_line::@5 to bgcolor [phi:display_chip_line::@5->bgcolor]
    // [792] phi bgcolor::color#15 = BLUE [phi:display_chip_line::@5->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // display_chip_line::@6
    // cputc(VERA_CHR_UR)
    // [3162] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [3163] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [3165] call textcolor
    // [787] phi from display_chip_line::@6 to textcolor [phi:display_chip_line::@6->textcolor]
    // [787] phi textcolor::color#23 = WHITE [phi:display_chip_line::@6->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [3166] phi from display_chip_line::@6 to display_chip_line::@7 [phi:display_chip_line::@6->display_chip_line::@7]
    // display_chip_line::@7
    // bgcolor(BLACK)
    // [3167] call bgcolor
    // [792] phi from display_chip_line::@7 to bgcolor [phi:display_chip_line::@7->bgcolor]
    // [792] phi bgcolor::color#15 = BLACK [phi:display_chip_line::@7->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLACK
    jsr bgcolor
    // [3168] phi from display_chip_line::@7 to display_chip_line::@1 [phi:display_chip_line::@7->display_chip_line::@1]
    // [3168] phi display_chip_line::i#2 = 0 [phi:display_chip_line::@7->display_chip_line::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // display_chip_line::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [3169] if(display_chip_line::i#2<display_chip_line::w#10) goto display_chip_line::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [3170] phi from display_chip_line::@1 to display_chip_line::@3 [phi:display_chip_line::@1->display_chip_line::@3]
    // display_chip_line::@3
    // textcolor(GREY)
    // [3171] call textcolor
    // [787] phi from display_chip_line::@3 to textcolor [phi:display_chip_line::@3->textcolor]
    // [787] phi textcolor::color#23 = GREY [phi:display_chip_line::@3->textcolor#0] -- vbuxx=vbuc1 
    ldx #GREY
    jsr textcolor
    // [3172] phi from display_chip_line::@3 to display_chip_line::@8 [phi:display_chip_line::@3->display_chip_line::@8]
    // display_chip_line::@8
    // bgcolor(BLUE)
    // [3173] call bgcolor
    // [792] phi from display_chip_line::@8 to bgcolor [phi:display_chip_line::@8->bgcolor]
    // [792] phi bgcolor::color#15 = BLUE [phi:display_chip_line::@8->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // display_chip_line::@9
    // cputc(VERA_CHR_UL)
    // [3174] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [3175] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [3177] call textcolor
    // [787] phi from display_chip_line::@9 to textcolor [phi:display_chip_line::@9->textcolor]
    // [787] phi textcolor::color#23 = WHITE [phi:display_chip_line::@9->textcolor#0] -- vbuxx=vbuc1 
    ldx #WHITE
    jsr textcolor
    // [3178] phi from display_chip_line::@9 to display_chip_line::@10 [phi:display_chip_line::@9->display_chip_line::@10]
    // display_chip_line::@10
    // bgcolor(BLACK)
    // [3179] call bgcolor
    // [792] phi from display_chip_line::@10 to bgcolor [phi:display_chip_line::@10->bgcolor]
    // [792] phi bgcolor::color#15 = BLACK [phi:display_chip_line::@10->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLACK
    jsr bgcolor
    // display_chip_line::@11
    // cputcxy(x+2, y, c)
    // [3180] cputcxy::x#8 = display_chip_line::x#16 + 2 -- vbuyy=vbuz1_plus_2 
    ldy.z x
    iny
    iny
    // [3181] cputcxy::y#8 = display_chip_line::y#16 -- vbuaa=vbum1 
    lda y
    // [3182] cputcxy::c#8 = display_chip_line::c#15 -- vbuxx=vbuz1 
    ldx.z c
    // [3183] call cputcxy
    // [2273] phi from display_chip_line::@11 to cputcxy [phi:display_chip_line::@11->cputcxy]
    // [2273] phi cputcxy::c#17 = cputcxy::c#8 [phi:display_chip_line::@11->cputcxy#0] -- register_copy 
    // [2273] phi cputcxy::y#17 = cputcxy::y#8 [phi:display_chip_line::@11->cputcxy#1] -- register_copy 
    // [2273] phi cputcxy::x#17 = cputcxy::x#8 [phi:display_chip_line::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_line::@return
    // }
    // [3184] return 
    rts
    // display_chip_line::@2
  __b2:
    // cputc(VERA_CHR_SPACE)
    // [3185] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [3186] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [3188] display_chip_line::i#1 = ++ display_chip_line::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [3168] phi from display_chip_line::@2 to display_chip_line::@1 [phi:display_chip_line::@2->display_chip_line::@1]
    // [3168] phi display_chip_line::i#2 = display_chip_line::i#1 [phi:display_chip_line::@2->display_chip_line::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    y: .byte 0
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
// void display_chip_end(__register(X) char x, char y, __zp($ce) char w)
display_chip_end: {
    .label i = $7c
    .label w = $ce
    // gotoxy(x, y)
    // [3189] gotoxy::x#8 = display_chip_end::x#0 -- vbuyy=vbuxx 
    txa
    tay
    // [3190] call gotoxy
    // [805] phi from display_chip_end to gotoxy [phi:display_chip_end->gotoxy]
    // [805] phi gotoxy::y#37 = display_print_chip::y#21 [phi:display_chip_end->gotoxy#0] -- vbum1=vbuc1 
    lda #display_print_chip.y
    sta gotoxy.y
    // [805] phi gotoxy::x#37 = gotoxy::x#8 [phi:display_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [3191] phi from display_chip_end to display_chip_end::@4 [phi:display_chip_end->display_chip_end::@4]
    // display_chip_end::@4
    // textcolor(GREY)
    // [3192] call textcolor
    // [787] phi from display_chip_end::@4 to textcolor [phi:display_chip_end::@4->textcolor]
    // [787] phi textcolor::color#23 = GREY [phi:display_chip_end::@4->textcolor#0] -- vbuxx=vbuc1 
    ldx #GREY
    jsr textcolor
    // [3193] phi from display_chip_end::@4 to display_chip_end::@5 [phi:display_chip_end::@4->display_chip_end::@5]
    // display_chip_end::@5
    // bgcolor(BLUE)
    // [3194] call bgcolor
    // [792] phi from display_chip_end::@5 to bgcolor [phi:display_chip_end::@5->bgcolor]
    // [792] phi bgcolor::color#15 = BLUE [phi:display_chip_end::@5->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // display_chip_end::@6
    // cputc(VERA_CHR_UR)
    // [3195] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [3196] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [3198] call textcolor
    // [787] phi from display_chip_end::@6 to textcolor [phi:display_chip_end::@6->textcolor]
    // [787] phi textcolor::color#23 = BLUE [phi:display_chip_end::@6->textcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr textcolor
    // [3199] phi from display_chip_end::@6 to display_chip_end::@7 [phi:display_chip_end::@6->display_chip_end::@7]
    // display_chip_end::@7
    // bgcolor(BLACK)
    // [3200] call bgcolor
    // [792] phi from display_chip_end::@7 to bgcolor [phi:display_chip_end::@7->bgcolor]
    // [792] phi bgcolor::color#15 = BLACK [phi:display_chip_end::@7->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLACK
    jsr bgcolor
    // [3201] phi from display_chip_end::@7 to display_chip_end::@1 [phi:display_chip_end::@7->display_chip_end::@1]
    // [3201] phi display_chip_end::i#2 = 0 [phi:display_chip_end::@7->display_chip_end::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // display_chip_end::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [3202] if(display_chip_end::i#2<display_chip_end::w#0) goto display_chip_end::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [3203] phi from display_chip_end::@1 to display_chip_end::@3 [phi:display_chip_end::@1->display_chip_end::@3]
    // display_chip_end::@3
    // textcolor(GREY)
    // [3204] call textcolor
    // [787] phi from display_chip_end::@3 to textcolor [phi:display_chip_end::@3->textcolor]
    // [787] phi textcolor::color#23 = GREY [phi:display_chip_end::@3->textcolor#0] -- vbuxx=vbuc1 
    ldx #GREY
    jsr textcolor
    // [3205] phi from display_chip_end::@3 to display_chip_end::@8 [phi:display_chip_end::@3->display_chip_end::@8]
    // display_chip_end::@8
    // bgcolor(BLUE)
    // [3206] call bgcolor
    // [792] phi from display_chip_end::@8 to bgcolor [phi:display_chip_end::@8->bgcolor]
    // [792] phi bgcolor::color#15 = BLUE [phi:display_chip_end::@8->bgcolor#0] -- vbuxx=vbuc1 
    ldx #BLUE
    jsr bgcolor
    // display_chip_end::@9
    // cputc(VERA_CHR_UL)
    // [3207] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [3208] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_chip_end::@return
    // }
    // [3210] return 
    rts
    // display_chip_end::@2
  __b2:
    // cputc(VERA_CHR_HL)
    // [3211] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [3212] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [3214] display_chip_end::i#1 = ++ display_chip_end::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [3201] phi from display_chip_end::@2 to display_chip_end::@1 [phi:display_chip_end::@2->display_chip_end::@1]
    // [3201] phi display_chip_end::i#2 = display_chip_end::i#1 [phi:display_chip_end::@2->display_chip_end::@1#0] -- register_copy 
    jmp __b1
}
.segment CodeVera
  // spi_get_jedec
spi_get_jedec: {
    // spi_fast()
    // [3216] call spi_fast
    /* 
; Returns
; .X = Vendor ID
; .Y = Memory Type
; .A = Memory Capacity
.proc spi_get_jedec
    jsr spi_fast

    jsr spi_select
    lda #$9F
    jsr spi_write
    jsr spi_read
    tax
    jsr spi_read
    tay
    jsr spi_read
    rts
.endproc
 */
    jsr spi_fast
    // [3217] phi from spi_get_jedec to spi_get_jedec::@1 [phi:spi_get_jedec->spi_get_jedec::@1]
    // spi_get_jedec::@1
    // spi_select()
    // [3218] call spi_select
    // [3495] phi from spi_get_jedec::@1 to spi_select [phi:spi_get_jedec::@1->spi_select]
    jsr spi_select
    // spi_get_jedec::@2
    // spi_write(0x9F)
    // [3219] spi_write::data = $9f -- vbuz1=vbuc1 
    lda #$9f
    sta.z spi_write.data
    // [3220] call spi_write
    jsr spi_write
    // [3221] phi from spi_get_jedec::@2 to spi_get_jedec::@3 [phi:spi_get_jedec::@2->spi_get_jedec::@3]
    // spi_get_jedec::@3
    // spi_read()
    // [3222] call spi_read
    jsr spi_read
    // [3223] spi_read::return#0 = spi_read::return#12
    // spi_get_jedec::@4
    // [3224] spi_manufacturer#0 = spi_read::return#0 -- vbuxx=vbuaa 
    tax
    // [3225] call spi_read
    jsr spi_read
    // [3226] spi_read::return#1 = spi_read::return#12
    // spi_get_jedec::@5
    // [3227] spi_memory_type#0 = spi_read::return#1 -- vbuyy=vbuaa 
    tay
    // [3228] call spi_read
    jsr spi_read
    // [3229] spi_read::return#10 = spi_read::return#12
    // spi_get_jedec::@6
    // [3230] spi_memory_capacity#0 = spi_read::return#10 -- vbum1=vbuaa 
    sta spi_memory_capacity
    // spi_get_jedec::@return
    // }
    // [3231] return 
    rts
}
.segment Code
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
// void rom_write_byte(__zp($36) unsigned long address, __register(Y) char value)
rom_write_byte: {
    .label rom_bank1_rom_write_byte__2 = $30
    .label rom_ptr1_rom_write_byte__0 = $2e
    .label rom_ptr1_rom_write_byte__2 = $2e
    .label rom_bank1_bank_unshifted = $30
    .label rom_ptr1_return = $2e
    .label address = $36
    // rom_write_byte::rom_bank1
    // BYTE2(address)
    // [3233] rom_write_byte::rom_bank1_$0 = byte2  rom_write_byte::address#4 -- vbuaa=_byte2_vduz1 
    lda.z address+2
    // BYTE1(address)
    // [3234] rom_write_byte::rom_bank1_$1 = byte1  rom_write_byte::address#4 -- vbuxx=_byte1_vduz1 
    ldx.z address+1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [3235] rom_write_byte::rom_bank1_$2 = rom_write_byte::rom_bank1_$0 w= rom_write_byte::rom_bank1_$1 -- vwuz1=vbuaa_word_vbuxx 
    sta.z rom_bank1_rom_write_byte__2+1
    stx.z rom_bank1_rom_write_byte__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [3236] rom_write_byte::rom_bank1_bank_unshifted#0 = rom_write_byte::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [3237] rom_write_byte::rom_bank1_return#0 = byte1  rom_write_byte::rom_bank1_bank_unshifted#0 -- vbuxx=_byte1_vwuz1 
    ldx.z rom_bank1_bank_unshifted+1
    // rom_write_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [3238] rom_write_byte::rom_ptr1_$2 = (unsigned int)rom_write_byte::address#4 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_write_byte__2
    lda.z address+1
    sta.z rom_ptr1_rom_write_byte__2+1
    // [3239] rom_write_byte::rom_ptr1_$0 = rom_write_byte::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_write_byte__0
    and #<$3fff
    sta.z rom_ptr1_rom_write_byte__0
    lda.z rom_ptr1_rom_write_byte__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_write_byte__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [3240] rom_write_byte::rom_ptr1_return#0 = rom_write_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_write_byte::bank_set_brom1
    // BROM = bank
    // [3241] BROM = rom_write_byte::rom_bank1_return#0 -- vbuz1=vbuxx 
    stx.z BROM
    // rom_write_byte::@1
    // *ptr_rom = value
    // [3242] *((char *)rom_write_byte::rom_ptr1_return#0) = rom_write_byte::value#10 -- _deref_pbuz1=vbuyy 
    tya
    ldy #0
    sta (rom_ptr1_return),y
    // rom_write_byte::@return
    // }
    // [3243] return 
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
// __register(X) char uctoa_append(__zp($34) char *buffer, __register(X) char value, __mem() char sub)
uctoa_append: {
    .label buffer = $34
    // [3245] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [3245] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbuyy=vbuc1 
    ldy #0
    // [3245] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [3246] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbuxx_ge_vbum1_then_la1 
    cpx sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [3247] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuyy 
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [3248] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [3249] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbuyy=_inc_vbuyy 
    iny
    // value -= sub
    // [3250] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbuxx=vbuxx_minus_vbum1 
    txa
    sec
    sbc sub
    tax
    // [3245] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [3245] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [3245] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label sub = uctoa.started
}
.segment CodeVera
  // spi_read_flash
// void spi_read_flash(unsigned long spi_data)
spi_read_flash: {
    // spi_select()
    // [3252] call spi_select
  /* 
; .X [7:0]
; .Y [15:8]
; .A [23:16]
.proc spi_read_flash
    pha

    jsr spi_select
    lda #$03
    jsr spi_write
    pla
    jsr spi_write
    tya
    jsr spi_write
    txa
    jsr spi_write

    rts
.endproc
 */
    // [3495] phi from spi_read_flash to spi_select [phi:spi_read_flash->spi_select]
    jsr spi_select
    // spi_read_flash::@1
    // spi_write(0x03)
    // [3253] spi_write::data = 3 -- vbuz1=vbuc1 
    lda #3
    sta.z spi_write.data
    // [3254] call spi_write
    jsr spi_write
    // spi_read_flash::@2
    // spi_write(BYTE2(spi_data))
    // [3255] spi_write::data = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z spi_write.data
    // [3256] call spi_write
    jsr spi_write
    // spi_read_flash::@3
    // spi_write(BYTE1(spi_data))
    // [3257] spi_write::data = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z spi_write.data
    // [3258] call spi_write
    jsr spi_write
    // spi_read_flash::@4
    // spi_write(BYTE0(spi_data))
    // [3259] spi_write::data = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z spi_write.data
    // [3260] call spi_write
    jsr spi_write
    // spi_read_flash::@return
    // }
    // [3261] return 
    rts
}
  // spi_read
spi_read: {
    // asm
    // asm { stzvera_reg_SPIData !: bitvera_reg_SPICtrl bmi!-  }
    /*
    .proc spi_read
	stz Vera::Reg::SPIData
@1:	bit Vera::Reg::SPICtrl
	bmi @1
    lda Vera::Reg::SPIData
	rts
.endproc
*/
    stz vera_reg_SPIData
  !:
    bit vera_reg_SPICtrl
    bmi !-
    // return *vera_reg_SPIData;
    // [3263] spi_read::return#12 = *vera_reg_SPIData -- vbuaa=_deref_pbuc1 
    lda vera_reg_SPIData
    // spi_read::@return
    // }
    // [3264] return 
    rts
}
  // spi_wait_non_busy
spi_wait_non_busy: {
    /** 
.proc spi_wait_non_busy
    ldy #0
top:
    jsr spi_select
    lda #$05
    jsr spi_write

    jsr spi_read
    and #1
    bne wait_restart
    clc
    rts
fail:
    sec
    rts
wait_restart:
    iny
    beq fail
    wai    
    bra top
.endproc
 */
    .label y = $c2
    // [3266] phi from spi_wait_non_busy to spi_wait_non_busy::@1 [phi:spi_wait_non_busy->spi_wait_non_busy::@1]
    // [3266] phi spi_wait_non_busy::y#2 = 0 [phi:spi_wait_non_busy->spi_wait_non_busy::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // spi_wait_non_busy::@1
    // [3267] phi from spi_wait_non_busy::@1 to spi_wait_non_busy::@2 [phi:spi_wait_non_busy::@1->spi_wait_non_busy::@2]
    // spi_wait_non_busy::@2
  __b2:
    // spi_select()
    // [3268] call spi_select
    // [3495] phi from spi_wait_non_busy::@2 to spi_select [phi:spi_wait_non_busy::@2->spi_select]
    jsr spi_select
    // spi_wait_non_busy::@5
    // spi_write(0x05)
    // [3269] spi_write::data = 5 -- vbuz1=vbuc1 
    lda #5
    sta.z spi_write.data
    // [3270] call spi_write
    jsr spi_write
    // [3271] phi from spi_wait_non_busy::@5 to spi_wait_non_busy::@6 [phi:spi_wait_non_busy::@5->spi_wait_non_busy::@6]
    // spi_wait_non_busy::@6
    // unsigned char w = spi_read()
    // [3272] call spi_read
    jsr spi_read
    // [3273] spi_read::return#11 = spi_read::return#12
    // spi_wait_non_busy::@7
    // [3274] spi_wait_non_busy::w#0 = spi_read::return#11
    // w &= 1
    // [3275] spi_wait_non_busy::w#1 = spi_wait_non_busy::w#0 & 1 -- vbuaa=vbuaa_band_vbuc1 
    and #1
    // if(w == 0)
    // [3276] if(spi_wait_non_busy::w#1==0) goto spi_wait_non_busy::@return -- vbuaa_eq_0_then_la1 
    cmp #0
    beq __b1
    // spi_wait_non_busy::@4
    // y++;
    // [3277] spi_wait_non_busy::y#1 = ++ spi_wait_non_busy::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // if(y == 0)
    // [3278] if(spi_wait_non_busy::y#1!=0) goto spi_wait_non_busy::@3 -- vbuz1_neq_0_then_la1 
    lda.z y
    bne __b3
    // [3279] phi from spi_wait_non_busy::@4 to spi_wait_non_busy::@return [phi:spi_wait_non_busy::@4->spi_wait_non_busy::@return]
    // [3279] phi spi_wait_non_busy::return#3 = 1 [phi:spi_wait_non_busy::@4->spi_wait_non_busy::@return#0] -- vbuaa=vbuc1 
    lda #1
    rts
    // [3279] phi from spi_wait_non_busy::@7 to spi_wait_non_busy::@return [phi:spi_wait_non_busy::@7->spi_wait_non_busy::@return]
  __b1:
    // [3279] phi spi_wait_non_busy::return#3 = 0 [phi:spi_wait_non_busy::@7->spi_wait_non_busy::@return#0] -- vbuaa=vbuc1 
    lda #0
    // spi_wait_non_busy::@return
    // }
    // [3280] return 
    rts
    // spi_wait_non_busy::@3
  __b3:
    // asm
    // asm { .byte$CB  }
    // WAI
    .byte $cb
    // [3266] phi from spi_wait_non_busy::@3 to spi_wait_non_busy::@1 [phi:spi_wait_non_busy::@3->spi_wait_non_busy::@1]
    // [3266] phi spi_wait_non_busy::y#2 = spi_wait_non_busy::y#1 [phi:spi_wait_non_busy::@3->spi_wait_non_busy::@1#0] -- register_copy 
    jmp __b2
}
  // spi_block_erase
// void spi_block_erase(__zp($e7) unsigned long data)
spi_block_erase: {
    .label data = $e7
    // spi_select()
    // [3283] call spi_select
  /** 
; .X [7:0]
; .Y [15:8]
; .A [23:16]
.proc spi_block_erase ; 64k
    pha

    ; write enable
    jsr spi_select
    lda #$06
    jsr spi_write

    jsr spi_select
    lda #$d8
    jsr spi_write

    pla
    jsr spi_write
    tya
    jsr spi_write
    txa
    jsr spi_write

    jsr spi_deselect

    rts
.endproc
 */
    // [3495] phi from spi_block_erase to spi_select [phi:spi_block_erase->spi_select]
    jsr spi_select
    // spi_block_erase::@1
    // spi_write(0x06)
    // [3284] spi_write::data = 6 -- vbuz1=vbuc1 
    lda #6
    sta.z spi_write.data
    // [3285] call spi_write
    jsr spi_write
    // [3286] phi from spi_block_erase::@1 to spi_block_erase::@2 [phi:spi_block_erase::@1->spi_block_erase::@2]
    // spi_block_erase::@2
    // spi_select()
    // [3287] call spi_select
    // [3495] phi from spi_block_erase::@2 to spi_select [phi:spi_block_erase::@2->spi_select]
    jsr spi_select
    // spi_block_erase::@3
    // spi_write(0xD8)
    // [3288] spi_write::data = $d8 -- vbuz1=vbuc1 
    lda #$d8
    sta.z spi_write.data
    // [3289] call spi_write
    jsr spi_write
    // spi_block_erase::@4
    // BYTE2(data)
    // [3290] spi_block_erase::$4 = byte2  spi_block_erase::data#0 -- vbuaa=_byte2_vduz1 
    lda.z data+2
    // spi_write(BYTE2(data))
    // [3291] spi_write::data = spi_block_erase::$4 -- vbuz1=vbuaa 
    sta.z spi_write.data
    // [3292] call spi_write
    jsr spi_write
    // spi_block_erase::@5
    // BYTE1(data)
    // [3293] spi_block_erase::$6 = byte1  spi_block_erase::data#0 -- vbuaa=_byte1_vduz1 
    lda.z data+1
    // spi_write(BYTE1(data))
    // [3294] spi_write::data = spi_block_erase::$6 -- vbuz1=vbuaa 
    sta.z spi_write.data
    // [3295] call spi_write
    jsr spi_write
    // spi_block_erase::@6
    // BYTE0(data)
    // [3296] spi_block_erase::$8 = byte0  spi_block_erase::data#0 -- vbuaa=_byte0_vduz1 
    lda.z data
    // spi_write(BYTE0(data))
    // [3297] spi_write::data = spi_block_erase::$8 -- vbuz1=vbuaa 
    sta.z spi_write.data
    // [3298] call spi_write
    jsr spi_write
    // [3299] phi from spi_block_erase::@6 to spi_block_erase::@7 [phi:spi_block_erase::@6->spi_block_erase::@7]
    // spi_block_erase::@7
    // spi_deselect()
    // [3300] call spi_deselect
    jsr spi_deselect
    // spi_block_erase::@return
    // }
    // [3301] return 
    rts
}
  // spi_write_page_begin
// void spi_write_page_begin(__zp($ee) unsigned long data)
spi_write_page_begin: {
    .label data = $ee
    // spi_select()
    // [3303] call spi_select
  /** 
; .X [7:0]
; .Y [15:8]
; .A [23:16]
.proc spi_write_page_begin
    pha

    ; write enable
    jsr spi_select
    lda #$06
    jsr spi_write

    jsr spi_select
    lda #$02
    jsr spi_write
    pla
    jsr spi_write
    tya
    jsr spi_write
    txa
    jsr spi_write

    rts
.endproc
 */
    // [3495] phi from spi_write_page_begin to spi_select [phi:spi_write_page_begin->spi_select]
    jsr spi_select
    // spi_write_page_begin::@1
    // spi_write(0x06)
    // [3304] spi_write::data = 6 -- vbuz1=vbuc1 
    lda #6
    sta.z spi_write.data
    // [3305] call spi_write
    jsr spi_write
    // [3306] phi from spi_write_page_begin::@1 to spi_write_page_begin::@2 [phi:spi_write_page_begin::@1->spi_write_page_begin::@2]
    // spi_write_page_begin::@2
    // spi_select()
    // [3307] call spi_select
    // [3495] phi from spi_write_page_begin::@2 to spi_select [phi:spi_write_page_begin::@2->spi_select]
    jsr spi_select
    // spi_write_page_begin::@3
    // spi_write(0x02)
    // [3308] spi_write::data = 2 -- vbuz1=vbuc1 
    lda #2
    sta.z spi_write.data
    // [3309] call spi_write
    jsr spi_write
    // spi_write_page_begin::@4
    // BYTE2(data)
    // [3310] spi_write_page_begin::$4 = byte2  spi_write_page_begin::data#0 -- vbuaa=_byte2_vduz1 
    lda.z data+2
    // spi_write(BYTE2(data))
    // [3311] spi_write::data = spi_write_page_begin::$4 -- vbuz1=vbuaa 
    sta.z spi_write.data
    // [3312] call spi_write
    jsr spi_write
    // spi_write_page_begin::@5
    // BYTE1(data)
    // [3313] spi_write_page_begin::$6 = byte1  spi_write_page_begin::data#0 -- vbuaa=_byte1_vduz1 
    lda.z data+1
    // spi_write(BYTE1(data))
    // [3314] spi_write::data = spi_write_page_begin::$6 -- vbuz1=vbuaa 
    sta.z spi_write.data
    // [3315] call spi_write
    jsr spi_write
    // spi_write_page_begin::@6
    // BYTE0(data)
    // [3316] spi_write_page_begin::$8 = byte0  spi_write_page_begin::data#0 -- vbuaa=_byte0_vduz1 
    lda.z data
    // spi_write(BYTE0(data))
    // [3317] spi_write::data = spi_write_page_begin::$8 -- vbuz1=vbuaa 
    sta.z spi_write.data
    // [3318] call spi_write
    jsr spi_write
    // spi_write_page_begin::@return
    // }
    // [3319] return 
    rts
}
  // spi_write
/**
 * @brief 
 * 
 * 
 */
// void spi_write(__zp($c9) volatile char data)
spi_write: {
    .label data = $c9
    // asm
    // asm { ldadata stavera_reg_SPIData !: bitvera_reg_SPICtrl bmi!-  }
    /*
.proc spi_write
	sta Vera::Reg::SPIData
@1:	bit Vera::Reg::SPICtrl
	bmi @1
	rts
.endproc
*/
    lda data
    sta vera_reg_SPIData
  !:
    bit vera_reg_SPICtrl
    bmi !-
    // spi_write::@return
    // }
    // [3321] return 
    rts
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
    // [3323] return 
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
// __mem() int ferror(__zp($46) struct $2 *stream)
ferror: {
    .label cbm_k_setnam1_ferror__0 = $48
    .label stream = $46
    .label errno_len = $cf
    // unsigned char sp = (unsigned char)stream
    // [3324] ferror::sp#0 = (char)ferror::stream#0 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_setlfs(15, 8, 15)
    // [3325] cbm_k_setlfs::channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.channel
    // [3326] cbm_k_setlfs::device = 8 -- vbum1=vbuc1 
    lda #8
    sta cbm_k_setlfs.device
    // [3327] cbm_k_setlfs::command = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.command
    // [3328] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // ferror::@11
    // cbm_k_setnam("")
    // [3329] ferror::cbm_k_setnam1_filename = str -- pbum1=pbuc1 
    lda #<str
    sta cbm_k_setnam1_filename
    lda #>str
    sta cbm_k_setnam1_filename+1
    // ferror::cbm_k_setnam1
    // strlen(filename)
    // [3330] strlen::str#5 = ferror::cbm_k_setnam1_filename -- pbuz1=pbum2 
    lda cbm_k_setnam1_filename
    sta.z strlen.str
    lda cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [3331] call strlen
    // [2555] phi from ferror::cbm_k_setnam1 to strlen [phi:ferror::cbm_k_setnam1->strlen]
    // [2555] phi strlen::str#8 = strlen::str#5 [phi:ferror::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [3332] strlen::return#12 = strlen::len#2
    // ferror::@12
    // [3333] ferror::cbm_k_setnam1_$0 = strlen::return#12 -- vwuz1=vwum2 
    lda strlen.return
    sta.z cbm_k_setnam1_ferror__0
    lda strlen.return+1
    sta.z cbm_k_setnam1_ferror__0+1
    // char filename_len = (char)strlen(filename)
    // [3334] ferror::cbm_k_setnam1_filename_len = (char)ferror::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
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
    // [3337] ferror::cbm_k_chkin1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_chkin1_channel
    // ferror::cbm_k_chkin1
    // char status
    // [3338] ferror::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // ferror::cbm_k_chrin1
    // char ch
    // [3340] ferror::cbm_k_chrin1_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin1_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin1_ch
    // return ch;
    // [3342] ferror::cbm_k_chrin1_return#0 = ferror::cbm_k_chrin1_ch -- vbuaa=vbum1 
    // ferror::cbm_k_chrin1_@return
    // }
    // [3343] ferror::cbm_k_chrin1_return#1 = ferror::cbm_k_chrin1_return#0
    // ferror::@7
    // char ch = cbm_k_chrin()
    // [3344] ferror::ch#0 = ferror::cbm_k_chrin1_return#1 -- vbum1=vbuaa 
    sta ch
    // [3345] phi from ferror::@7 to ferror::cbm_k_readst1 [phi:ferror::@7->ferror::cbm_k_readst1]
    // [3345] phi __errno#123 = __errno#474 [phi:ferror::@7->ferror::cbm_k_readst1#0] -- register_copy 
    // [3345] phi ferror::errno_len#10 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z errno_len
    // [3345] phi ferror::ch#10 = ferror::ch#0 [phi:ferror::@7->ferror::cbm_k_readst1#2] -- register_copy 
    // [3345] phi ferror::errno_parsed#2 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#3] -- vbum1=vbuc1 
    sta errno_parsed
    // ferror::cbm_k_readst1
  cbm_k_readst1:
    // char status
    // [3346] ferror::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [3348] ferror::cbm_k_readst1_return#0 = ferror::cbm_k_readst1_status -- vbuaa=vbum1 
    // ferror::cbm_k_readst1_@return
    // }
    // [3349] ferror::cbm_k_readst1_return#1 = ferror::cbm_k_readst1_return#0
    // ferror::@8
    // cbm_k_readst()
    // [3350] ferror::$6 = ferror::cbm_k_readst1_return#1
    // st = cbm_k_readst()
    // [3351] ferror::st#1 = ferror::$6
    // while (!(st = cbm_k_readst()))
    // [3352] if(0==ferror::st#1) goto ferror::@1 -- 0_eq_vbuaa_then_la1 
    cmp #0
    beq __b1
    // ferror::@2
    // __status = st
    // [3353] ((char *)&__stdio_file+$46)[ferror::sp#0] = ferror::st#1 -- pbuc1_derefidx_vbum1=vbuaa 
    ldy sp
    sta __stdio_file+$46,y
    // cbm_k_close(15)
    // [3354] ferror::cbm_k_close1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_close1_channel
    // ferror::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // ferror::@9
    // return __errno;
    // [3356] ferror::return#1 = __errno#123 -- vwsm1=vwsm2 
    lda __errno
    sta return
    lda __errno+1
    sta return+1
    // ferror::@return
    // }
    // [3357] return 
    rts
    // ferror::@1
  __b1:
    // if (!errno_parsed)
    // [3358] if(0!=ferror::errno_parsed#2) goto ferror::@3 -- 0_neq_vbum1_then_la1 
    lda errno_parsed
    bne __b3
    // ferror::@4
    // if (ch == ',')
    // [3359] if(ferror::ch#10!=',') goto ferror::@3 -- vbum1_neq_vbuc1_then_la1 
    lda #','
    cmp ch
    bne __b3
    // ferror::@5
    // errno_parsed++;
    // [3360] ferror::errno_parsed#1 = ++ ferror::errno_parsed#2 -- vbum1=_inc_vbum1 
    inc errno_parsed
    // strncpy(temp, __errno_error, errno_len+1)
    // [3361] strncpy::n#0 = ferror::errno_len#10 + 1 -- vwum1=vbuz2_plus_1 
    lda.z errno_len
    clc
    adc #1
    sta strncpy.n
    lda #0
    adc #0
    sta strncpy.n+1
    // [3362] call strncpy
    // [2916] phi from ferror::@5 to strncpy [phi:ferror::@5->strncpy]
    // [2916] phi strncpy::dst#8 = ferror::temp [phi:ferror::@5->strncpy#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z strncpy.dst
    lda #>temp
    sta.z strncpy.dst+1
    // [2916] phi strncpy::src#6 = __errno_error [phi:ferror::@5->strncpy#1] -- pbuz1=pbuc1 
    lda #<__errno_error
    sta.z strncpy.src
    lda #>__errno_error
    sta.z strncpy.src+1
    // [2916] phi strncpy::n#3 = strncpy::n#0 [phi:ferror::@5->strncpy#2] -- register_copy 
    jsr strncpy
    // [3363] phi from ferror::@5 to ferror::@13 [phi:ferror::@5->ferror::@13]
    // ferror::@13
    // atoi(temp)
    // [3364] call atoi
    // [3376] phi from ferror::@13 to atoi [phi:ferror::@13->atoi]
    // [3376] phi atoi::str#2 = ferror::temp [phi:ferror::@13->atoi#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z atoi.str
    lda #>temp
    sta.z atoi.str+1
    jsr atoi
    // atoi(temp)
    // [3365] atoi::return#4 = atoi::return#2
    // ferror::@14
    // __errno = atoi(temp)
    // [3366] __errno#2 = atoi::return#4 -- vwsm1=vwsm2 
    lda atoi.return
    sta __errno
    lda atoi.return+1
    sta __errno+1
    // [3367] phi from ferror::@1 ferror::@14 ferror::@4 to ferror::@3 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3]
    // [3367] phi __errno#178 = __errno#123 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#0] -- register_copy 
    // [3367] phi ferror::errno_parsed#11 = ferror::errno_parsed#2 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#1] -- register_copy 
    // ferror::@3
  __b3:
    // __errno_error[errno_len] = ch
    // [3368] __errno_error[ferror::errno_len#10] = ferror::ch#10 -- pbuc1_derefidx_vbuz1=vbum2 
    lda ch
    ldy.z errno_len
    sta __errno_error,y
    // errno_len++;
    // [3369] ferror::errno_len#1 = ++ ferror::errno_len#10 -- vbuz1=_inc_vbuz1 
    inc.z errno_len
    // ferror::cbm_k_chrin2
    // char ch
    // [3370] ferror::cbm_k_chrin2_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin2_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin2_ch
    // return ch;
    // [3372] ferror::cbm_k_chrin2_return#0 = ferror::cbm_k_chrin2_ch -- vbuaa=vbum1 
    // ferror::cbm_k_chrin2_@return
    // }
    // [3373] ferror::cbm_k_chrin2_return#1 = ferror::cbm_k_chrin2_return#0
    // ferror::@10
    // cbm_k_chrin()
    // [3374] ferror::$15 = ferror::cbm_k_chrin2_return#1
    // ch = cbm_k_chrin()
    // [3375] ferror::ch#1 = ferror::$15 -- vbum1=vbuaa 
    sta ch
    // [3345] phi from ferror::@10 to ferror::cbm_k_readst1 [phi:ferror::@10->ferror::cbm_k_readst1]
    // [3345] phi __errno#123 = __errno#178 [phi:ferror::@10->ferror::cbm_k_readst1#0] -- register_copy 
    // [3345] phi ferror::errno_len#10 = ferror::errno_len#1 [phi:ferror::@10->ferror::cbm_k_readst1#1] -- register_copy 
    // [3345] phi ferror::ch#10 = ferror::ch#1 [phi:ferror::@10->ferror::cbm_k_readst1#2] -- register_copy 
    // [3345] phi ferror::errno_parsed#2 = ferror::errno_parsed#11 [phi:ferror::@10->ferror::cbm_k_readst1#3] -- register_copy 
    jmp cbm_k_readst1
  .segment Data
    temp: .fill 4, 0
    cbm_k_setnam1_filename: .word 0
    cbm_k_setnam1_filename_len: .byte 0
    cbm_k_chkin1_channel: .byte 0
    cbm_k_chkin1_status: .byte 0
    cbm_k_chrin1_ch: .byte 0
    cbm_k_readst1_status: .byte 0
    cbm_k_close1_channel: .byte 0
    cbm_k_chrin2_ch: .byte 0
    .label return = strncmp.n
    .label sp = printf_padding.i
    .label ch = uctoa.digit
    .label errno_parsed = printf_string.format_justify_left
}
.segment Code
  // atoi
// Converts the string argument str to an integer.
// __mem() int atoi(__zp($6b) const char *str)
atoi: {
    .label atoi__6 = $59
    .label atoi__7 = $59
    .label str = $6b
    .label atoi__10 = $59
    .label atoi__11 = $59
    // if (str[i] == '-')
    // [3377] if(*atoi::str#2!='-') goto atoi::@3 -- _deref_pbuz1_neq_vbuc1_then_la1 
    ldy #0
    lda (str),y
    cmp #'-'
    bne __b2
    // [3378] phi from atoi to atoi::@2 [phi:atoi->atoi::@2]
    // atoi::@2
    // [3379] phi from atoi::@2 to atoi::@3 [phi:atoi::@2->atoi::@3]
    // [3379] phi atoi::negative#2 = 1 [phi:atoi::@2->atoi::@3#0] -- vbuxx=vbuc1 
    ldx #1
    // [3379] phi atoi::res#2 = 0 [phi:atoi::@2->atoi::@3#1] -- vwsm1=vwsc1 
    tya
    sta res
    sta res+1
    // [3379] phi atoi::i#4 = 1 [phi:atoi::@2->atoi::@3#2] -- vbuyy=vbuc1 
    ldy #1
    jmp __b3
  // Iterate through all digits and update the result
    // [3379] phi from atoi to atoi::@3 [phi:atoi->atoi::@3]
  __b2:
    // [3379] phi atoi::negative#2 = 0 [phi:atoi->atoi::@3#0] -- vbuxx=vbuc1 
    ldx #0
    // [3379] phi atoi::res#2 = 0 [phi:atoi->atoi::@3#1] -- vwsm1=vwsc1 
    txa
    sta res
    sta res+1
    // [3379] phi atoi::i#4 = 0 [phi:atoi->atoi::@3#2] -- vbuyy=vbuc1 
    tay
    // atoi::@3
  __b3:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [3380] if(atoi::str#2[atoi::i#4]<'0') goto atoi::@5 -- pbuz1_derefidx_vbuyy_lt_vbuc1_then_la1 
    lda (str),y
    cmp #'0'
    bcc __b5
    // atoi::@6
    // [3381] if(atoi::str#2[atoi::i#4]<='9') goto atoi::@4 -- pbuz1_derefidx_vbuyy_le_vbuc1_then_la1 
    lda (str),y
    cmp #'9'
    bcc __b4
    beq __b4
    // atoi::@5
  __b5:
    // if(negative)
    // [3382] if(0!=atoi::negative#2) goto atoi::@1 -- 0_neq_vbuxx_then_la1 
    // Return result with sign
    cpx #0
    bne __b1
    // [3384] phi from atoi::@1 atoi::@5 to atoi::@return [phi:atoi::@1/atoi::@5->atoi::@return]
    // [3384] phi atoi::return#2 = atoi::return#0 [phi:atoi::@1/atoi::@5->atoi::@return#0] -- register_copy 
    rts
    // atoi::@1
  __b1:
    // return -res;
    // [3383] atoi::return#0 = - atoi::res#2 -- vwsm1=_neg_vwsm1 
    lda #0
    sec
    sbc return
    sta return
    lda #0
    sbc return+1
    sta return+1
    // atoi::@return
    // }
    // [3385] return 
    rts
    // atoi::@4
  __b4:
    // res * 10
    // [3386] atoi::$10 = atoi::res#2 << 2 -- vwsz1=vwsm2_rol_2 
    lda res
    asl
    sta.z atoi__10
    lda res+1
    rol
    sta.z atoi__10+1
    asl.z atoi__10
    rol.z atoi__10+1
    // [3387] atoi::$11 = atoi::$10 + atoi::res#2 -- vwsz1=vwsz1_plus_vwsm2 
    clc
    lda.z atoi__11
    adc res
    sta.z atoi__11
    lda.z atoi__11+1
    adc res+1
    sta.z atoi__11+1
    // [3388] atoi::$6 = atoi::$11 << 1 -- vwsz1=vwsz1_rol_1 
    asl.z atoi__6
    rol.z atoi__6+1
    // res * 10 + str[i]
    // [3389] atoi::$7 = atoi::$6 + atoi::str#2[atoi::i#4] -- vwsz1=vwsz1_plus_pbuz2_derefidx_vbuyy 
    lda.z atoi__7
    clc
    adc (str),y
    sta.z atoi__7
    bcc !+
    inc.z atoi__7+1
  !:
    // res = res * 10 + str[i] - '0'
    // [3390] atoi::res#1 = atoi::$7 - '0' -- vwsm1=vwsz2_minus_vbuc1 
    lda.z atoi__7
    sec
    sbc #'0'
    sta res
    lda.z atoi__7+1
    sbc #0
    sta res+1
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [3391] atoi::i#2 = ++ atoi::i#4 -- vbuyy=_inc_vbuyy 
    iny
    // [3379] phi from atoi::@4 to atoi::@3 [phi:atoi::@4->atoi::@3]
    // [3379] phi atoi::negative#2 = atoi::negative#2 [phi:atoi::@4->atoi::@3#0] -- register_copy 
    // [3379] phi atoi::res#2 = atoi::res#1 [phi:atoi::@4->atoi::@3#1] -- register_copy 
    // [3379] phi atoi::i#4 = atoi::i#2 [phi:atoi::@4->atoi::@3#2] -- register_copy 
    jmp __b3
  .segment Data
    .label res = strncmp.n
    .label return = strncmp.n
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
// __mem() unsigned int cx16_k_macptr(__mem() volatile char bytes, __zp($63) void * volatile buffer)
cx16_k_macptr: {
    .label buffer = $63
    // unsigned int bytes_read
    // [3392] cx16_k_macptr::bytes_read = 0 -- vwum1=vwuc1 
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
    // [3394] cx16_k_macptr::return#0 = cx16_k_macptr::bytes_read -- vwum1=vwum2 
    lda bytes_read
    sta return
    lda bytes_read+1
    sta return+1
    // cx16_k_macptr::@return
    // }
    // [3395] cx16_k_macptr::return#1 = cx16_k_macptr::return#0
    // [3396] return 
    rts
  .segment Data
    bytes: .byte 0
    bytes_read: .word 0
    .label return = fgets.bytes
}
.segment Code
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
// __register(A) char rom_byte_compare(__zp($40) char *ptr_rom, __register(A) char value)
rom_byte_compare: {
    .label ptr_rom = $40
    // if (*ptr_rom != value)
    // [3397] if(*rom_byte_compare::ptr_rom#0==rom_byte_compare::value#0) goto rom_byte_compare::@1 -- _deref_pbuz1_eq_vbuaa_then_la1 
    ldy #0
    cmp (ptr_rom),y
    beq __b2
    // [3398] phi from rom_byte_compare to rom_byte_compare::@2 [phi:rom_byte_compare->rom_byte_compare::@2]
    // rom_byte_compare::@2
    // [3399] phi from rom_byte_compare::@2 to rom_byte_compare::@1 [phi:rom_byte_compare::@2->rom_byte_compare::@1]
    // [3399] phi rom_byte_compare::return#0 = 0 [phi:rom_byte_compare::@2->rom_byte_compare::@1#0] -- vbuaa=vbuc1 
    tya
    rts
    // [3399] phi from rom_byte_compare to rom_byte_compare::@1 [phi:rom_byte_compare->rom_byte_compare::@1]
  __b2:
    // [3399] phi rom_byte_compare::return#0 = 1 [phi:rom_byte_compare->rom_byte_compare::@1#0] -- vbuaa=vbuc1 
    lda #1
    // rom_byte_compare::@1
    // rom_byte_compare::@return
    // }
    // [3400] return 
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
// __mem() unsigned long ultoa_append(__zp($32) char *buffer, __mem() unsigned long value, __mem() unsigned long sub)
ultoa_append: {
    .label buffer = $32
    // [3402] phi from ultoa_append to ultoa_append::@1 [phi:ultoa_append->ultoa_append::@1]
    // [3402] phi ultoa_append::digit#2 = 0 [phi:ultoa_append->ultoa_append::@1#0] -- vbuxx=vbuc1 
    ldx #0
    // [3402] phi ultoa_append::value#2 = ultoa_append::value#0 [phi:ultoa_append->ultoa_append::@1#1] -- register_copy 
    // ultoa_append::@1
  __b1:
    // while (value >= sub)
    // [3403] if(ultoa_append::value#2>=ultoa_append::sub#0) goto ultoa_append::@2 -- vdum1_ge_vdum2_then_la1 
    lda value+3
    cmp sub+3
    bcc !+
    bne __b2
    lda value+2
    cmp sub+2
    bcc !+
    bne __b2
    lda value+1
    cmp sub+1
    bcc !+
    bne __b2
    lda value
    cmp sub
    bcs __b2
  !:
    // ultoa_append::@3
    // *buffer = DIGITS[digit]
    // [3404] *ultoa_append::buffer#0 = DIGITS[ultoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuxx 
    lda DIGITS,x
    ldy #0
    sta (buffer),y
    // ultoa_append::@return
    // }
    // [3405] return 
    rts
    // ultoa_append::@2
  __b2:
    // digit++;
    // [3406] ultoa_append::digit#1 = ++ ultoa_append::digit#2 -- vbuxx=_inc_vbuxx 
    inx
    // value -= sub
    // [3407] ultoa_append::value#1 = ultoa_append::value#2 - ultoa_append::sub#0 -- vdum1=vdum1_minus_vdum2 
    lda value
    sec
    sbc sub
    sta value
    lda value+1
    sbc sub+1
    sta value+1
    lda value+2
    sbc sub+2
    sta value+2
    lda value+3
    sbc sub+3
    sta value+3
    // [3402] phi from ultoa_append::@2 to ultoa_append::@1 [phi:ultoa_append::@2->ultoa_append::@1]
    // [3402] phi ultoa_append::digit#2 = ultoa_append::digit#1 [phi:ultoa_append::@2->ultoa_append::@1#0] -- register_copy 
    // [3402] phi ultoa_append::value#2 = ultoa_append::value#1 [phi:ultoa_append::@2->ultoa_append::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label value = printf_ulong.uvalue
    .label sub = ultoa.digit_value
    .label return = printf_ulong.uvalue
}
.segment Code
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
// void rom_wait(__zp($23) char *ptr_rom)
rom_wait: {
    .label rom_wait__0 = $22
    .label ptr_rom = $23
    // rom_wait::@1
  __b1:
    // test1 = *((brom_ptr_t)ptr_rom)
    // [3409] rom_wait::test1#1 = *rom_wait::ptr_rom#3 -- vbuxx=_deref_pbuz1 
    ldy #0
    lda (ptr_rom),y
    tax
    // test2 = *((brom_ptr_t)ptr_rom)
    // [3410] rom_wait::test2#1 = *rom_wait::ptr_rom#3 -- vbuyy=_deref_pbuz1 
    lda (ptr_rom),y
    tay
    // test1 & 0x40
    // [3411] rom_wait::$0 = rom_wait::test1#1 & $40 -- vbuz1=vbuxx_band_vbuc1 
    txa
    and #$40
    sta.z rom_wait__0
    // test2 & 0x40
    // [3412] rom_wait::$1 = rom_wait::test2#1 & $40 -- vbuaa=vbuyy_band_vbuc1 
    tya
    and #$40
    // while ((test1 & 0x40) != (test2 & 0x40))
    // [3413] if(rom_wait::$0!=rom_wait::$1) goto rom_wait::@1 -- vbuz1_neq_vbuaa_then_la1 
    cmp.z rom_wait__0
    bne __b1
    // rom_wait::@return
    // }
    // [3414] return 
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
// void rom_byte_program(__zp($36) unsigned long address, __register(Y) char value)
rom_byte_program: {
    .label rom_ptr1_rom_byte_program__0 = $25
    .label rom_ptr1_rom_byte_program__2 = $25
    .label rom_ptr1_return = $25
    .label address = $36
    // rom_byte_program::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [3416] rom_byte_program::rom_ptr1_$2 = (unsigned int)rom_byte_program::address#0 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_byte_program__2
    lda.z address+1
    sta.z rom_ptr1_rom_byte_program__2+1
    // [3417] rom_byte_program::rom_ptr1_$0 = rom_byte_program::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_byte_program__0
    and #<$3fff
    sta.z rom_ptr1_rom_byte_program__0
    lda.z rom_ptr1_rom_byte_program__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_byte_program__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [3418] rom_byte_program::rom_ptr1_return#0 = rom_byte_program::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_byte_program::@1
    // rom_write_byte(address, value)
    // [3419] rom_write_byte::address#3 = rom_byte_program::address#0
    // [3420] rom_write_byte::value#3 = rom_byte_program::value#0
    // [3421] call rom_write_byte
    // [3232] phi from rom_byte_program::@1 to rom_write_byte [phi:rom_byte_program::@1->rom_write_byte]
    // [3232] phi rom_write_byte::value#10 = rom_write_byte::value#3 [phi:rom_byte_program::@1->rom_write_byte#0] -- register_copy 
    // [3232] phi rom_write_byte::address#4 = rom_write_byte::address#3 [phi:rom_byte_program::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_byte_program::@2
    // rom_wait(ptr_rom)
    // [3422] rom_wait::ptr_rom#1 = (char *)rom_byte_program::rom_ptr1_return#0 -- pbuz1=pbuz2 
    lda.z rom_ptr1_return
    sta.z rom_wait.ptr_rom
    lda.z rom_ptr1_return+1
    sta.z rom_wait.ptr_rom+1
    // [3423] call rom_wait
    // [3408] phi from rom_byte_program::@2 to rom_wait [phi:rom_byte_program::@2->rom_wait]
    // [3408] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#1 [phi:rom_byte_program::@2->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_byte_program::@return
    // }
    // [3424] return 
    rts
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
// __mem() unsigned int utoa_append(__zp($2c) char *buffer, __mem() unsigned int value, __mem() unsigned int sub)
utoa_append: {
    .label buffer = $2c
    // [3426] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [3426] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbuxx=vbuc1 
    ldx #0
    // [3426] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [3427] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwum1_ge_vwum2_then_la1 
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
    // [3428] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbuxx 
    lda DIGITS,x
    ldy #0
    sta (buffer),y
    // utoa_append::@return
    // }
    // [3429] return 
    rts
    // utoa_append::@2
  __b2:
    // digit++;
    // [3430] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbuxx=_inc_vbuxx 
    inx
    // value -= sub
    // [3431] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwum1=vwum1_minus_vwum2 
    lda value
    sec
    sbc sub
    sta value
    lda value+1
    sbc sub+1
    sta value+1
    // [3426] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [3426] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [3426] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label value = strncmp.n
    .label sub = fgets.remaining
    .label return = strncmp.n
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
// void memcpy8_vram_vram(__mem() char dbank_vram, __mem() unsigned int doffset_vram, __mem() char sbank_vram, __mem() unsigned int soffset_vram, __register(X) char num8)
memcpy8_vram_vram: {
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [3432] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [3433] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuaa=_byte0_vwum1 
    lda soffset_vram
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [3434] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [3435] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuaa=_byte1_vwum1 
    lda soffset_vram+1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [3436] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [3437] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuaa=vbum1_bor_vbuc1 
    lda #VERA_INC_1
    ora sbank_vram
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [3438] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [3439] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [3440] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuaa=_byte0_vwum1 
    lda doffset_vram
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [3441] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [3442] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuaa=_byte1_vwum1 
    lda doffset_vram+1
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [3443] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [3444] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuaa=vbum1_bor_vbuc1 
    lda #VERA_INC_1
    ora dbank_vram
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [3445] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_H
    // [3446] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [3446] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [3447] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbuxx=_dec_vbuyy 
    tya
    tax
    dex
    // [3448] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbuyy_then_la1 
    cpy #0
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [3449] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [3450] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [3451] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbuyy=vbuxx 
    txa
    tay
    jmp __b1
  .segment Data
    dbank_vram: .byte 0
    doffset_vram: .word 0
    sbank_vram: .byte 0
    soffset_vram: .word 0
}
.segment Code
  // display_frame_maskxy
/**
 * @brief 
 * 
 * @param x 
 * @param y 
 * @return unsigned char 
 */
// __register(A) char display_frame_maskxy(__register(Y) char x, __register(A) char y)
display_frame_maskxy: {
    // display_frame_maskxy::cpeekcxy1
    // gotoxy(x,y)
    // [3453] gotoxy::x#5 = display_frame_maskxy::cpeekcxy1_x#0
    // [3454] gotoxy::y#5 = display_frame_maskxy::cpeekcxy1_y#0 -- vbum1=vbuaa 
    sta gotoxy.y
    // [3455] call gotoxy
    // [805] phi from display_frame_maskxy::cpeekcxy1 to gotoxy [phi:display_frame_maskxy::cpeekcxy1->gotoxy]
    // [805] phi gotoxy::y#37 = gotoxy::y#5 [phi:display_frame_maskxy::cpeekcxy1->gotoxy#0] -- register_copy 
    // [805] phi gotoxy::x#37 = gotoxy::x#5 [phi:display_frame_maskxy::cpeekcxy1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_frame_maskxy::cpeekcxy1_cpeekc1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [3456] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [3457] display_frame_maskxy::cpeekcxy1_cpeekc1_$0 = byte0  *((unsigned int *)&__conio+$13) -- vbuaa=_byte0__deref_pwuc1 
    lda __conio+$13
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [3458] *VERA_ADDRX_L = display_frame_maskxy::cpeekcxy1_cpeekc1_$0 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [3459] display_frame_maskxy::cpeekcxy1_cpeekc1_$1 = byte1  *((unsigned int *)&__conio+$13) -- vbuaa=_byte1__deref_pwuc1 
    lda __conio+$13+1
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [3460] *VERA_ADDRX_M = display_frame_maskxy::cpeekcxy1_cpeekc1_$1 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_0
    // [3461] display_frame_maskxy::cpeekcxy1_cpeekc1_$2 = *((char *)&__conio+5) -- vbuaa=_deref_pbuc1 
    lda __conio+5
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_0
    // [3462] *VERA_ADDRX_H = display_frame_maskxy::cpeekcxy1_cpeekc1_$2 -- _deref_pbuc1=vbuaa 
    sta VERA_ADDRX_H
    // return *VERA_DATA0;
    // [3463] display_frame_maskxy::c#0 = *VERA_DATA0 -- vbuaa=_deref_pbuc1 
    lda VERA_DATA0
    // display_frame_maskxy::@12
    // case 0x70: // DR corner.
    //             return 0b0110;
    // [3464] if(display_frame_maskxy::c#0==$70) goto display_frame_maskxy::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #$70
    beq __b2
    // display_frame_maskxy::@1
    // case 0x6E: // DL corner.
    //             return 0b0011;
    // [3465] if(display_frame_maskxy::c#0==$6e) goto display_frame_maskxy::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #$6e
    beq __b1
    // display_frame_maskxy::@2
    // case 0x6D: // UR corner.
    //             return 0b1100;
    // [3466] if(display_frame_maskxy::c#0==$6d) goto display_frame_maskxy::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #$6d
    beq __b3
    // display_frame_maskxy::@3
    // case 0x7D: // UL corner.
    //             return 0b1001;
    // [3467] if(display_frame_maskxy::c#0==$7d) goto display_frame_maskxy::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #$7d
    beq __b4
    // display_frame_maskxy::@4
    // case 0x40: // HL line.
    //             return 0b0101;
    // [3468] if(display_frame_maskxy::c#0==$40) goto display_frame_maskxy::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #$40
    beq __b5
    // display_frame_maskxy::@5
    // case 0x5D: // VL line.
    //             return 0b1010;
    // [3469] if(display_frame_maskxy::c#0==$5d) goto display_frame_maskxy::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #$5d
    beq __b6
    // display_frame_maskxy::@6
    // case 0x6B: // VR junction.
    //             return 0b1110;
    // [3470] if(display_frame_maskxy::c#0==$6b) goto display_frame_maskxy::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #$6b
    beq __b7
    // display_frame_maskxy::@7
    // case 0x73: // VL junction.
    //             return 0b1011;
    // [3471] if(display_frame_maskxy::c#0==$73) goto display_frame_maskxy::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #$73
    beq __b8
    // display_frame_maskxy::@8
    // case 0x72: // HD junction.
    //             return 0b0111;
    // [3472] if(display_frame_maskxy::c#0==$72) goto display_frame_maskxy::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #$72
    beq __b9
    // display_frame_maskxy::@9
    // case 0x71: // HU junction.
    //             return 0b1101;
    // [3473] if(display_frame_maskxy::c#0==$71) goto display_frame_maskxy::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #$71
    beq __b10
    // display_frame_maskxy::@10
    // case 0x5B: // HV junction.
    //             return 0b1111;
    // [3474] if(display_frame_maskxy::c#0==$5b) goto display_frame_maskxy::@11 -- vbuaa_eq_vbuc1_then_la1 
    cmp #$5b
    beq __b11
    // [3476] phi from display_frame_maskxy::@10 to display_frame_maskxy::@return [phi:display_frame_maskxy::@10->display_frame_maskxy::@return]
    // [3476] phi display_frame_maskxy::return#12 = 0 [phi:display_frame_maskxy::@10->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #0
    rts
    // [3475] phi from display_frame_maskxy::@10 to display_frame_maskxy::@11 [phi:display_frame_maskxy::@10->display_frame_maskxy::@11]
    // display_frame_maskxy::@11
  __b11:
    // [3476] phi from display_frame_maskxy::@11 to display_frame_maskxy::@return [phi:display_frame_maskxy::@11->display_frame_maskxy::@return]
    // [3476] phi display_frame_maskxy::return#12 = $f [phi:display_frame_maskxy::@11->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #$f
    rts
    // [3476] phi from display_frame_maskxy::@1 to display_frame_maskxy::@return [phi:display_frame_maskxy::@1->display_frame_maskxy::@return]
  __b1:
    // [3476] phi display_frame_maskxy::return#12 = 3 [phi:display_frame_maskxy::@1->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #3
    rts
    // [3476] phi from display_frame_maskxy::@12 to display_frame_maskxy::@return [phi:display_frame_maskxy::@12->display_frame_maskxy::@return]
  __b2:
    // [3476] phi display_frame_maskxy::return#12 = 6 [phi:display_frame_maskxy::@12->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #6
    rts
    // [3476] phi from display_frame_maskxy::@2 to display_frame_maskxy::@return [phi:display_frame_maskxy::@2->display_frame_maskxy::@return]
  __b3:
    // [3476] phi display_frame_maskxy::return#12 = $c [phi:display_frame_maskxy::@2->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #$c
    rts
    // [3476] phi from display_frame_maskxy::@3 to display_frame_maskxy::@return [phi:display_frame_maskxy::@3->display_frame_maskxy::@return]
  __b4:
    // [3476] phi display_frame_maskxy::return#12 = 9 [phi:display_frame_maskxy::@3->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #9
    rts
    // [3476] phi from display_frame_maskxy::@4 to display_frame_maskxy::@return [phi:display_frame_maskxy::@4->display_frame_maskxy::@return]
  __b5:
    // [3476] phi display_frame_maskxy::return#12 = 5 [phi:display_frame_maskxy::@4->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #5
    rts
    // [3476] phi from display_frame_maskxy::@5 to display_frame_maskxy::@return [phi:display_frame_maskxy::@5->display_frame_maskxy::@return]
  __b6:
    // [3476] phi display_frame_maskxy::return#12 = $a [phi:display_frame_maskxy::@5->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #$a
    rts
    // [3476] phi from display_frame_maskxy::@6 to display_frame_maskxy::@return [phi:display_frame_maskxy::@6->display_frame_maskxy::@return]
  __b7:
    // [3476] phi display_frame_maskxy::return#12 = $e [phi:display_frame_maskxy::@6->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #$e
    rts
    // [3476] phi from display_frame_maskxy::@7 to display_frame_maskxy::@return [phi:display_frame_maskxy::@7->display_frame_maskxy::@return]
  __b8:
    // [3476] phi display_frame_maskxy::return#12 = $b [phi:display_frame_maskxy::@7->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #$b
    rts
    // [3476] phi from display_frame_maskxy::@8 to display_frame_maskxy::@return [phi:display_frame_maskxy::@8->display_frame_maskxy::@return]
  __b9:
    // [3476] phi display_frame_maskxy::return#12 = 7 [phi:display_frame_maskxy::@8->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #7
    rts
    // [3476] phi from display_frame_maskxy::@9 to display_frame_maskxy::@return [phi:display_frame_maskxy::@9->display_frame_maskxy::@return]
  __b10:
    // [3476] phi display_frame_maskxy::return#12 = $d [phi:display_frame_maskxy::@9->display_frame_maskxy::@return#0] -- vbuaa=vbuc1 
    lda #$d
    // display_frame_maskxy::@return
    // }
    // [3477] return 
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
    // [3479] if(display_frame_char::mask#10==6) goto display_frame_char::@return -- vbuaa_eq_vbuc1_then_la1 
    cmp #6
    beq __b1
    // display_frame_char::@1
    // case 0b0011:
    //             return 0x6E;
    // [3480] if(display_frame_char::mask#10==3) goto display_frame_char::@return -- vbuaa_eq_vbuc1_then_la1 
    // DR corner.
    cmp #3
    beq __b2
    // display_frame_char::@2
    // case 0b1100:
    //             return 0x6D;
    // [3481] if(display_frame_char::mask#10==$c) goto display_frame_char::@return -- vbuaa_eq_vbuc1_then_la1 
    // DL corner.
    cmp #$c
    beq __b3
    // display_frame_char::@3
    // case 0b1001:
    //             return 0x7D;
    // [3482] if(display_frame_char::mask#10==9) goto display_frame_char::@return -- vbuaa_eq_vbuc1_then_la1 
    // UR corner.
    cmp #9
    beq __b4
    // display_frame_char::@4
    // case 0b0101:
    //             return 0x40;
    // [3483] if(display_frame_char::mask#10==5) goto display_frame_char::@return -- vbuaa_eq_vbuc1_then_la1 
    // UL corner.
    cmp #5
    beq __b5
    // display_frame_char::@5
    // case 0b1010:
    //             return 0x5D;
    // [3484] if(display_frame_char::mask#10==$a) goto display_frame_char::@return -- vbuaa_eq_vbuc1_then_la1 
    // HL line.
    cmp #$a
    beq __b6
    // display_frame_char::@6
    // case 0b1110:
    //             return 0x6B;
    // [3485] if(display_frame_char::mask#10==$e) goto display_frame_char::@return -- vbuaa_eq_vbuc1_then_la1 
    // VL line.
    cmp #$e
    beq __b7
    // display_frame_char::@7
    // case 0b1011:
    //             return 0x73;
    // [3486] if(display_frame_char::mask#10==$b) goto display_frame_char::@return -- vbuaa_eq_vbuc1_then_la1 
    // VR junction.
    cmp #$b
    beq __b8
    // display_frame_char::@8
    // case 0b0111:
    //             return 0x72;
    // [3487] if(display_frame_char::mask#10==7) goto display_frame_char::@return -- vbuaa_eq_vbuc1_then_la1 
    // VL junction.
    cmp #7
    beq __b9
    // display_frame_char::@9
    // case 0b1101:
    //             return 0x71;
    // [3488] if(display_frame_char::mask#10==$d) goto display_frame_char::@return -- vbuaa_eq_vbuc1_then_la1 
    // HD junction.
    cmp #$d
    beq __b10
    // display_frame_char::@10
    // case 0b1111:
    //             return 0x5B;
    // [3489] if(display_frame_char::mask#10==$f) goto display_frame_char::@11 -- vbuaa_eq_vbuc1_then_la1 
    // HU junction.
    cmp #$f
    beq __b11
    // [3491] phi from display_frame_char::@10 to display_frame_char::@return [phi:display_frame_char::@10->display_frame_char::@return]
    // [3491] phi display_frame_char::return#12 = $20 [phi:display_frame_char::@10->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$20
    rts
    // [3490] phi from display_frame_char::@10 to display_frame_char::@11 [phi:display_frame_char::@10->display_frame_char::@11]
    // display_frame_char::@11
  __b11:
    // [3491] phi from display_frame_char::@11 to display_frame_char::@return [phi:display_frame_char::@11->display_frame_char::@return]
    // [3491] phi display_frame_char::return#12 = $5b [phi:display_frame_char::@11->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$5b
    rts
    // [3491] phi from display_frame_char to display_frame_char::@return [phi:display_frame_char->display_frame_char::@return]
  __b1:
    // [3491] phi display_frame_char::return#12 = $70 [phi:display_frame_char->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$70
    rts
    // [3491] phi from display_frame_char::@1 to display_frame_char::@return [phi:display_frame_char::@1->display_frame_char::@return]
  __b2:
    // [3491] phi display_frame_char::return#12 = $6e [phi:display_frame_char::@1->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$6e
    rts
    // [3491] phi from display_frame_char::@2 to display_frame_char::@return [phi:display_frame_char::@2->display_frame_char::@return]
  __b3:
    // [3491] phi display_frame_char::return#12 = $6d [phi:display_frame_char::@2->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$6d
    rts
    // [3491] phi from display_frame_char::@3 to display_frame_char::@return [phi:display_frame_char::@3->display_frame_char::@return]
  __b4:
    // [3491] phi display_frame_char::return#12 = $7d [phi:display_frame_char::@3->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$7d
    rts
    // [3491] phi from display_frame_char::@4 to display_frame_char::@return [phi:display_frame_char::@4->display_frame_char::@return]
  __b5:
    // [3491] phi display_frame_char::return#12 = $40 [phi:display_frame_char::@4->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$40
    rts
    // [3491] phi from display_frame_char::@5 to display_frame_char::@return [phi:display_frame_char::@5->display_frame_char::@return]
  __b6:
    // [3491] phi display_frame_char::return#12 = $5d [phi:display_frame_char::@5->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$5d
    rts
    // [3491] phi from display_frame_char::@6 to display_frame_char::@return [phi:display_frame_char::@6->display_frame_char::@return]
  __b7:
    // [3491] phi display_frame_char::return#12 = $6b [phi:display_frame_char::@6->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$6b
    rts
    // [3491] phi from display_frame_char::@7 to display_frame_char::@return [phi:display_frame_char::@7->display_frame_char::@return]
  __b8:
    // [3491] phi display_frame_char::return#12 = $73 [phi:display_frame_char::@7->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$73
    rts
    // [3491] phi from display_frame_char::@8 to display_frame_char::@return [phi:display_frame_char::@8->display_frame_char::@return]
  __b9:
    // [3491] phi display_frame_char::return#12 = $72 [phi:display_frame_char::@8->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$72
    rts
    // [3491] phi from display_frame_char::@9 to display_frame_char::@return [phi:display_frame_char::@9->display_frame_char::@return]
  __b10:
    // [3491] phi display_frame_char::return#12 = $71 [phi:display_frame_char::@9->display_frame_char::@return#0] -- vbuaa=vbuc1 
    lda #$71
    // display_frame_char::@return
    // }
    // [3492] return 
    rts
}
.segment CodeVera
  // spi_fast
spi_fast: {
    // asm
    // asm { ldavera_reg_SPICtrl and#%11111101 stavera_reg_SPICtrl  }
    /*
.proc spi_fast
    lda Vera::Reg::SPICtrl
    and #%11111101
    sta Vera::Reg::SPICtrl
	rts
.endproc
*/
    lda vera_reg_SPICtrl
    and #$fd
    sta vera_reg_SPICtrl
    // spi_fast::@return
    // }
    // [3494] return 
    rts
}
  // spi_select
spi_select: {
    // spi_deselect()
    // [3496] call spi_deselect
    /*
.proc spi_select
    jsr spi_deselect

    lda Vera::Reg::SPICtrl
    ora #$01
    sta Vera::Reg::SPICtrl
	rts
.endproc
*/
    jsr spi_deselect
    // spi_select::@1
    // *vera_reg_SPICtrl |= 1
    // [3497] *vera_reg_SPICtrl = *vera_reg_SPICtrl | 1 -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #1
    ora vera_reg_SPICtrl
    sta vera_reg_SPICtrl
    // spi_select::@return
    // }
    // [3498] return 
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
  // Values of binary digits
  RADIX_BINARY_VALUES_LONG: .dword $80000000, $40000000, $20000000, $10000000, $8000000, $4000000, $2000000, $1000000, $800000, $400000, $200000, $100000, $80000, $40000, $20000, $10000, $8000, $4000, $2000, $1000, $800, $400, $200, $100, $80, $40, $20, $10, 8, 4, 2
  // Values of octal digits
  RADIX_OCTAL_VALUES_LONG: .dword $40000000, $8000000, $1000000, $200000, $40000, $8000, $1000, $200, $40, 8
  // Values of decimal digits
  RADIX_DECIMAL_VALUES_LONG: .dword $3b9aca00, $5f5e100, $989680, $f4240, $186a0, $2710, $3e8, $64, $a
  // Values of hexadecimal digits
  RADIX_HEXADECIMAL_VALUES_LONG: .dword $10000000, $1000000, $100000, $10000, $1000, $100, $10
  info_text: .fill $50, 0
  status_text: .word __3, __4, __5, smc_action_text_1, smc_action_text, __8, __9, __10, __11, __12, __13, __14
  status_color: .byte BLACK, GREY, WHITE, CYAN, PURPLE, CYAN, PURPLE, PURPLE, GREEN, YELLOW, RED, PINK
  status_rom: .byte 0
  .fill 7, 0
.segment DataIntro
  display_into_briefing_text: .word __15, __16, str, __18, __19, __20, __21, __22, __23, str, __25, __26, str, __28, __29
  display_into_colors_text: .word __30, __31, str, __33, __34, __35, __36, __37, __38, __39, __40, __41, __42, __43, str, __45
.segment DataVera
  display_jp1_spi_vera_text: .word __46, str, __48, __49, __50, __51, __52, str, __54, __55, str, __57, __58, __59, str, __61
  display_no_valid_smc_bootloader_text: .word __62, str, __64, __65, str, __67, __68, __69, __70
  display_smc_rom_issue_text: .word __71, str, __81, __74, str, __76, __77, __78
  display_smc_unsupported_rom_text: .word __79, str, __81, __82, str, __84, __85
.segment Data
  display_debriefing_smc_text: .word __100, str, main.text, str, __90, __91, __92, str, __94, str, __96, __97, __98, __99
  display_debriefing_text_rom: .word __100, str, str, str, __104, __105
  smc_file_header: .fill $20, 0
  smc_version_text: .fill $10, 0
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
  rom_file_github: .fill 8*8, 0
  rom_file_release: .fill 8, 0
  TEXT_PROGRESS_FLASHING: .text "Flashing ... (-) equal, (+) flashed, (!) error."
  .byte 0
  __3: .text "None"
  .byte 0
  __4: .text "Skip"
  .byte 0
  __5: .text "Detected"
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
  __14: .text "Waiting"
  .byte 0
  __15: .text "Welcome to the CX16 update tool! This program updates the"
  .byte 0
  __16: .text "chipsets on your CX16 and ROM expansion boards."
  .byte 0
  __18: .text "Depending on the files found on the SDCard, various"
  .byte 0
  __19: .text "components will be updated:"
  .byte 0
  __20: .text "- Mandatory: SMC.BIN for the SMC firmware."
  .byte 0
  __21: .text "- Mandatory: ROM.BIN for the main ROM."
  .byte 0
  __22: .text "- Optional: VERA.BIN for the VERA firmware."
  .byte 0
  __23: .text "- Optional: ROMn.BIN for a ROM expansion board or cartridge."
  .byte 0
  __25: .text "  Important: Ensure J1 write-enable jumper is closed"
  .byte 0
  __26: .text "  on both the main board and any ROM expansion board."
  .byte 0
  __28: .text "Please carefully read the step-by-step instructions at "
  .byte 0
  __29: .text "https://flightcontrol-user.github.io/x16-flash"
  .byte 0
  __30: .text "The panels above indicate the update progress,"
  .byte 0
  __31: .text "using status indicators and colors as specified below:"
  .byte 0
  __33: .text " -   None       Not detected, no action."
  .byte 0
  __34: .text " -   Skipped    Detected, but no action, eg. no file."
  .byte 0
  __35: .text " -   Detected   Detected, verification pending."
  .byte 0
  __36: .text " -   Checking   Verifying size of the update file."
  .byte 0
  __37: .text " -   Reading    Reading the update file into RAM."
  .byte 0
  __38: .text " -   Comparing  Comparing the RAM with the ROM."
  .byte 0
  __39: .text " -   Update     Ready to update the firmware."
  .byte 0
  __40: .text " -   Updating   Updating the firmware."
  .byte 0
  __41: .text " -   Updated    Updated the firmware succesfully."
  .byte 0
  __42: .text " -   Issue      Problem identified during update."
  .byte 0
  __43: .text " -   Error      Error found during update."
  .byte 0
  __45: .text "Errors can indicate J1 jumpers are not closed!"
  .byte 0
  __46: .text "The following steps are IMPORTANT to update the VERA:"
  .byte 0
  __48: .text "1. In the next step you will be asked to close the JP1 jumper"
  .byte 0
  __49: .text "   pins on the VERA board."
  .byte 0
  __50: .text "   The closure of the JP1 jumper pins is required"
  .byte 0
  __51: .text "   to allow the program to access VERA flash memory"
  .byte 0
  __52: .text "   instead of the SDCard!"
  .byte 0
  __54: .text "2. Once the VERA has been updated, you will be asked to open"
  .byte 0
  __55: .text "   the JP1 jumper pins!"
  .byte 0
  __57: .text "Reminder:"
  .byte 0
  __58: .text " - DON'T CLOSE THE JP1 JUMPER PINS BEFORE BEING ASKED!"
  .byte 0
  __59: .text " - DON'T OPEN THE JP1 JUMPER PINS WHILE VERA IS BEING UPDATED!"
  .byte 0
  __61: .text "The program continues once the JP1 pins are opened/closed."
  .byte 0
  __62: .text "The SMC chip in your CX16 doesn't have a valid bootloader."
  .byte 0
  __64: .text "A valid bootloader is needed to update the SMC chip."
  .byte 0
  __65: .text "Unfortunately, your SMC chip cannot be updated using this tool!"
  .byte 0
  __67: .text "A bootloader can be installed onto the SMC chip using an"
  .byte 0
  __68: .text "an Arduino or an AVR ISP device."
  .byte 0
  __69: .text "Alternatively a new SMC chip with a valid bootloader can be"
  .byte 0
  __70: .text "ordered from TexElec."
  .byte 0
  __71: .text "There is an issue with the CX16 SMC or ROM flash readiness."
  .byte 0
  __74: .text "to avoid possible conflicts of firmware, bricking your CX16."
  .byte 0
  __76: .text "Therefore, ensure you have the correct SMC.BIN and ROM.BIN"
  .byte 0
  __77: .text "files placed on your SDcard. Also ensure that the"
  .byte 0
  __78: .text "J1 jumper pins on the CX16 board are closed."
  .byte 0
  __79: .text "There is an issue with the CX16 SMC or ROM flash versions."
  .byte 0
  __81: .text "Both the SMC and the main ROM must be updated together,"
  .byte 0
  __82: .text "to avoid possible conflicts, risking bricking your CX16."
  .byte 0
  __84: .text "The SMC.BIN and ROM.BIN found on your SDCard may not be"
  .byte 0
  __85: .text "mutually compatible. Update the CX16 at your own risk!"
  .byte 0
  __90: .text "Because your SMC chipset has been updated,"
  .byte 0
  __91: .text "the restart process differs, depending on the"
  .byte 0
  __92: .text "SMC boootloader version installed on your CX16 board:"
  .byte 0
  __94: .text "- SMC bootloader v2.0: your CX16 will automatically shut down."
  .byte 0
  __96: .text "- SMC bootloader v1.0: you need to "
  .byte 0
  __97: .text "  COMPLETELY DISCONNECT your CX16 from the power source!"
  .byte 0
  __98: .text "  The power-off button won't work!"
  .byte 0
  __99: .text "  Then, reconnect and start the CX16 normally."
  .byte 0
  __100: .text "Your CX16 system has been successfully updated!"
  .byte 0
  __104: .text "Since your CX16 system SMC chip has not been updated"
  .byte 0
  __105: .text "your CX16 will just reset automatically after count down."
  .byte 0
  s: .text " "
  .byte 0
  chip: .text "ROM"
  .byte 0
  s2: .text ":"
  .byte 0
  s5: .text " ... "
  .byte 0
  s4: .text " ..."
  .byte 0
  s1: .text "["
  .byte 0
  info_text6: .text "No update required"
  .byte 0
  s11: .text " differences!"
  .byte 0
  smc_action_text: .text "Reading"
  .byte 0
  smc_action_text_1: .text "Checking"
  .byte 0
  str: .text ""
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
  spi_memory_capacity: .byte 0
  vera_file_size: .dword 0
  // Globals (to save zeropage and code overhead with parameter passing.)
  smc_bootloader: .word 0
  smc_release: .byte 0
  smc_major: .byte 0
  smc_minor: .byte 0
  .label smc_file_size = smc_bootloader_1
  smc_file_release: .byte 0
  smc_file_major: .byte 0
  smc_file_minor: .byte 0
  smc_file_size_1: .word 0
  // Globals (to save zeropage and code overhead with parameter passing.)
  smc_bootloader_1: .word 0
  // Globals
  status_smc: .byte 0
  status_vera: .byte 0
