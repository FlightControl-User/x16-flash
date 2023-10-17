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
.segmentdef Data                    [startAfter="Code"]
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
  // #define __VERA_CHIP_PROCESS
  // #define __VERA_FLASH
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
  .const ROM_PROGRESS_CELL = $200
  // A progress frame cell represents about 512 bytes for a ROM update.
  .const ROM_PROGRESS_ROW = $8000
  // A progress frame row represents about 32768 bytes for a ROM update.
  .const SMC_PROGRESS_CELL = 8
  // A progress frame cell represents about 8 bytes for a SMC update.
  .const SMC_PROGRESS_ROW = $200
  .const display_intro_briefing_count = $f
  .const display_intro_colors_count = $10
  .const display_no_valid_smc_bootloader_count = 9
  .const display_smc_rom_issue_count = 8
  .const display_smc_unsupported_rom_count = 7
  .const display_debriefing_count_smc = $e
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
  .const OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS = 1
  .const STACK_BASE = $103
  .const spi_manufacturer = 0
  .const spi_memory_type = 0
  .const spi_memory_capacity = 0
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
  .label BRAM = 0
  .label BROM = 1
  /// Current position in the buffer being filled ( initially *s passed to snprintf()
  /// Used to hold state while printing
  .label __snprintf_buffer = $cf
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
    .label conio_x16_init__5 = $e2
    // screenlayer1()
    // [19] call screenlayer1
    jsr screenlayer1
    // [20] phi from conio_x16_init to conio_x16_init::@1 [phi:conio_x16_init->conio_x16_init::@1]
    // conio_x16_init::@1
    // textcolor(CONIO_TEXTCOLOR_DEFAULT)
    // [21] call textcolor
    // [760] phi from conio_x16_init::@1 to textcolor [phi:conio_x16_init::@1->textcolor]
    // [760] phi textcolor::color#23 = WHITE [phi:conio_x16_init::@1->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [22] phi from conio_x16_init::@1 to conio_x16_init::@2 [phi:conio_x16_init::@1->conio_x16_init::@2]
    // conio_x16_init::@2
    // bgcolor(CONIO_BACKCOLOR_DEFAULT)
    // [23] call bgcolor
    // [765] phi from conio_x16_init::@2 to bgcolor [phi:conio_x16_init::@2->bgcolor]
    // [765] phi bgcolor::color#15 = BLUE [phi:conio_x16_init::@2->bgcolor#0] -- vbum1=vbuc1 
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
    // [29] conio_x16_init::$4 = cbm_k_plot_get::return#2 -- vwum1=vwum2 
    lda cbm_k_plot_get.return
    sta conio_x16_init__4
    lda cbm_k_plot_get.return+1
    sta conio_x16_init__4+1
    // BYTE1(cbm_k_plot_get())
    // [30] conio_x16_init::$5 = byte1  conio_x16_init::$4 -- vbuz1=_byte1_vwum2 
    sta.z conio_x16_init__5
    // __conio.cursor_x = BYTE1(cbm_k_plot_get())
    // [31] *((char *)&__conio) = conio_x16_init::$5 -- _deref_pbuc1=vbuz1 
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
    // [778] phi from conio_x16_init::@6 to gotoxy [phi:conio_x16_init::@6->gotoxy]
    // [778] phi gotoxy::y#33 = gotoxy::y#2 [phi:conio_x16_init::@6->gotoxy#0] -- register_copy 
    // [778] phi gotoxy::x#33 = gotoxy::x#2 [phi:conio_x16_init::@6->gotoxy#1] -- register_copy 
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
    conio_x16_init__6: .word 0
    conio_x16_init__7: .byte 0
}
.segment Code
  // cputc
// Output one character at the current cursor position
// Moves the cursor forward. Scrolls the entire screen if needed
// void cputc(__mem() char c)
cputc: {
    .const OFFSET_STACK_C = 0
    .label cputc__1 = $22
    .label cputc__2 = $68
    .label cputc__3 = $69
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
  .segment Data
    c: .byte 0
}
.segment Code
  // main
main: {
    .const bank_set_brom1_bank = 0
    .const bank_set_brom2_bank = 4
    .const bank_set_brom4_bank = 0
    .const bank_set_brom5_bank = 0
    .const bank_set_brom6_bank = 4
    .label main__74 = $e7
    .label main__96 = $ec
    .label main__98 = $bf
    .label main__100 = $e0
    .label main__125 = $cc
    .label main__191 = $ba
    .label check_status_smc1_main__0 = $f6
    .label check_status_smc2_main__0 = $cb
    .label check_status_cx16_rom4_check_status_rom1_main__0 = $df
    .label check_status_vera2_main__0 = $f7
    .label check_status_vera3_main__0 = $fb
    .label check_status_smc10_main__0 = $e1
    .label check_status_cx16_rom6_check_status_rom1_main__0 = $ca
    .label check_status_cx16_rom7_check_status_rom1_main__0 = $d1
    .label check_status_smc12_main__0 = $a9
    .label check_status_smc13_main__0 = $ac
    .label check_status_smc14_main__0 = $ae
    .label check_status_smc15_main__0 = $ad
    .label check_status_vera5_main__0 = $fa
    .label check_status_smc16_main__0 = $de
    .label check_status_vera7_main__0 = $ef
    .label check_status_smc17_main__0 = $be
    .label check_status_vera8_main__0 = $bd
    .label check_status_smc1_return = $f6
    .label check_status_smc2_return = $cb
    .label rom_file_github_id = $c1
    .label rom_file_release_id = $ec
    .label ch = $c0
    .label ch2 = $6a
    .label ch1 = $c9
    .label check_status_cx16_rom4_check_status_rom1_return = $df
    .label ch3 = $cd
    .label check_status_vera2_return = $f7
    .label check_status_vera3_return = $fb
    .label check_status_smc10_return = $e1
    .label check_status_cx16_rom6_check_status_rom1_return = $ca
    .label check_status_cx16_rom7_check_status_rom1_return = $d1
    .label check_status_smc12_return = $a9
    .label check_status_smc13_return = $ac
    .label rom_differences = $c3
    .label check_status_smc14_return = $ae
    .label check_status_smc15_return = $ad
    .label check_status_vera5_return = $fa
    .label check_status_smc16_return = $de
    .label check_status_vera7_return = $ef
    .label check_status_smc17_return = $be
    .label check_status_vera8_return = $bd
    .label main__360 = $bf
    .label main__361 = $bf
    .label main__362 = $bf
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
    // [799] phi from main to init [phi:main->init]
    jsr init
    // [72] phi from main to main::@93 [phi:main->main::@93]
    // main::@93
    // main_intro()
    // [73] call main_intro
    // [835] phi from main::@93 to main_intro [phi:main::@93->main_intro]
    jsr main_intro
    // [74] phi from main::@93 to main::@94 [phi:main::@93->main::@94]
    // main::@94
    // smc_detect()
    // [75] call smc_detect
    jsr smc_detect
    // [76] smc_detect::return#2 = smc_detect::return#0
    // main::@95
    // smc_bootloader = smc_detect()
    // [77] smc_bootloader#0 = smc_detect::return#2 -- vwum1=vwuz2 
    lda.z smc_detect.return
    sta smc_bootloader
    lda.z smc_detect.return+1
    sta smc_bootloader+1
    // strcpy(smc_version_text, "0.0.0")
    // [78] call strcpy
    // [863] phi from main::@95 to strcpy [phi:main::@95->strcpy]
    // [863] phi strcpy::dst#0 = smc_version_text [phi:main::@95->strcpy#0] -- pbuz1=pbuc1 
    lda #<smc_version_text
    sta.z strcpy.dst
    lda #>smc_version_text
    sta.z strcpy.dst+1
    // [863] phi strcpy::src#0 = main::source [phi:main::@95->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // [79] phi from main::@95 to main::@96 [phi:main::@95->main::@96]
    // main::@96
    // display_chip_smc()
    // [80] call display_chip_smc
    // [871] phi from main::@96 to display_chip_smc [phi:main::@96->display_chip_smc]
    jsr display_chip_smc
    // main::@97
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
    // main::@4
    // if(smc_bootloader == 0x0200)
    // [82] if(smc_bootloader#0==$200) goto main::@17 -- vwum1_eq_vwuc1_then_la1 
    lda smc_bootloader
    cmp #<$200
    bne !+
    lda smc_bootloader+1
    cmp #>$200
    bne !__b17+
    jmp __b17
  !__b17:
  !:
    // main::@5
    // if(smc_bootloader > 0x2)
    // [83] if(smc_bootloader#0>=2+1) goto main::@18 -- vwum1_ge_vbuc1_then_la1 
    lda smc_bootloader+1
    beq !__b18+
    jmp __b18
  !__b18:
    lda smc_bootloader
    cmp #2+1
    bcc !__b18+
    jmp __b18
  !__b18:
  !:
    // main::@6
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
    // main::@104
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
    // main::@105
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
    // main::@106
    // smc_minor = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_MINOR)
    // [98] smc_minor#0 = cx16_k_i2c_read_byte::return#16 -- vbum1=vwum2 
    lda cx16_k_i2c_read_byte.return
    sta smc_minor
    // smc_get_version_text(smc_version_text, smc_release, smc_major, smc_minor)
    // [99] smc_get_version_text::release#0 = smc_release#0 -- vbum1=vbum2 
    lda smc_release
    sta smc_get_version_text.release
    // [100] smc_get_version_text::major#0 = smc_major#0 -- vbuz1=vbum2 
    lda smc_major
    sta.z smc_get_version_text.major
    // [101] smc_get_version_text::minor#0 = smc_minor#0 -- vbum1=vbum2 
    lda smc_minor
    sta smc_get_version_text.minor
    // [102] call smc_get_version_text
    // [881] phi from main::@106 to smc_get_version_text [phi:main::@106->smc_get_version_text]
    // [881] phi smc_get_version_text::minor#2 = smc_get_version_text::minor#0 [phi:main::@106->smc_get_version_text#0] -- register_copy 
    // [881] phi smc_get_version_text::major#2 = smc_get_version_text::major#0 [phi:main::@106->smc_get_version_text#1] -- register_copy 
    // [881] phi smc_get_version_text::release#2 = smc_get_version_text::release#0 [phi:main::@106->smc_get_version_text#2] -- register_copy 
    // [881] phi smc_get_version_text::version_string#2 = smc_version_text [phi:main::@106->smc_get_version_text#3] -- pbuz1=pbuc1 
    lda #<smc_version_text
    sta.z smc_get_version_text.version_string
    lda #>smc_version_text
    sta.z smc_get_version_text.version_string+1
    jsr smc_get_version_text
    // main::@107
    // [103] smc_bootloader#457 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_DETECTED, NULL)
    // [104] call display_info_smc
    // [898] phi from main::@107 to display_info_smc [phi:main::@107->display_info_smc]
    // [898] phi display_info_smc::info_text#21 = 0 [phi:main::@107->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [898] phi smc_bootloader#14 = smc_bootloader#457 [phi:main::@107->display_info_smc#1] -- register_copy 
    // [898] phi display_info_smc::info_status#21 = STATUS_DETECTED [phi:main::@107->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_DETECTED
    sta display_info_smc.info_status
    jsr display_info_smc
    // [105] phi from main::@107 to main::SEI1 [phi:main::@107->main::SEI1]
    // [105] phi smc_minor#391 = smc_minor#0 [phi:main::@107->main::SEI1#0] -- register_copy 
    // [105] phi smc_major#392 = smc_major#0 [phi:main::@107->main::SEI1#1] -- register_copy 
    // [105] phi smc_release#393 = smc_release#0 [phi:main::@107->main::SEI1#2] -- register_copy 
    // main::SEI1
  SEI1:
    // asm
    // asm { sei  }
    sei
    // main::bank_set_brom1
    // BROM = bank
    // [107] BROM = main::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // [108] phi from main::bank_set_brom1 to main::@66 [phi:main::bank_set_brom1->main::@66]
    // main::@66
    // rom_detect()
    // [109] call rom_detect
  // Detecting ROM chips
    // [934] phi from main::@66 to rom_detect [phi:main::@66->rom_detect]
    jsr rom_detect
    // [110] phi from main::@66 to main::@108 [phi:main::@66->main::@108]
    // main::@108
    // display_chip_rom()
    // [111] call display_chip_rom
    // [984] phi from main::@108 to display_chip_rom [phi:main::@108->display_chip_rom]
    jsr display_chip_rom
    // [112] phi from main::@108 to main::@19 [phi:main::@108->main::@19]
    // [112] phi main::rom_chip#10 = 0 [phi:main::@108->main::@19#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // main::@19
  __b19:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [113] if(main::rom_chip#10<8) goto main::@20 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcs !__b20+
    jmp __b20
  !__b20:
    // main::bank_set_brom2
    // BROM = bank
    // [114] BROM = main::bank_set_brom2_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom2_bank
    sta.z BROM
    // main::CLI1
    // asm
    // asm { cli  }
    cli
    // main::check_status_smc1
    // status_smc == status
    // [116] main::check_status_smc1_$0 = status_smc#122 == STATUS_DETECTED -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_DETECTED
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc1_main__0
    // return (unsigned char)(status_smc == status);
    // [117] main::check_status_smc1_return#0 = (char)main::check_status_smc1_$0
    // main::check_status_smc2
    // status_smc == status
    // [118] main::check_status_smc2_$0 = status_smc#122 == STATUS_ISSUE -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc2_main__0
    // return (unsigned char)(status_smc == status);
    // [119] main::check_status_smc2_return#0 = (char)main::check_status_smc2_$0
    // main::@67
    // if(check_status_smc(STATUS_DETECTED) || check_status_smc(STATUS_ISSUE) )
    // [120] if(0!=main::check_status_smc1_return#0) goto main::@23 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc1_return
    beq !__b23+
    jmp __b23
  !__b23:
    // main::@236
    // [121] if(0!=main::check_status_smc2_return#0) goto main::@23 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc2_return
    beq !__b23+
    jmp __b23
  !__b23:
    // [122] phi from main::@236 to main::SEI2 [phi:main::@236->main::SEI2]
    // [122] phi smc_file_minor#316 = 0 [phi:main::@236->main::SEI2#0] -- vbum1=vbuc1 
    lda #0
    sta smc_file_minor
    // [122] phi smc_file_major#316 = 0 [phi:main::@236->main::SEI2#1] -- vbum1=vbuc1 
    sta smc_file_major
    // [122] phi smc_file_release#316 = 0 [phi:main::@236->main::SEI2#2] -- vbum1=vbuc1 
    sta smc_file_release
    // [122] phi __stdio_filecount#259 = 0 [phi:main::@236->main::SEI2#3] -- vbum1=vbuc1 
    sta __stdio_filecount
    // [122] phi __errno#245 = 0 [phi:main::@236->main::SEI2#4] -- vwsm1=vwsc1 
    sta __errno
    sta __errno+1
    // main::SEI2
  SEI2:
    // asm
    // asm { sei  }
    sei
    // [124] phi from main::SEI2 to main::@28 [phi:main::SEI2->main::@28]
    // [124] phi __stdio_filecount#114 = __stdio_filecount#259 [phi:main::SEI2->main::@28#0] -- register_copy 
    // [124] phi __errno#100 = __errno#245 [phi:main::SEI2->main::@28#1] -- register_copy 
    // [124] phi main::rom_chip1#10 = 0 [phi:main::SEI2->main::@28#2] -- vbum1=vbuc1 
    lda #0
    sta rom_chip1
  // We loop all the possible ROM chip slots on the board and on the extension card,
  // and we check the file contents.
  // Any error identified gets reported and this chip will not be flashed.
  // In case of ROM0.BIN in error, no flashing will be done!
    // main::@28
  __b28:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [125] if(main::rom_chip1#10<8) goto main::bank_set_brom4 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip1
    cmp #8
    bcs !bank_set_brom4+
    jmp bank_set_brom4
  !bank_set_brom4:
    // main::check_status_smc3
    // status_smc == status
    // [126] main::check_status_smc3_$0 = status_smc#122 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc3_main__0
    // return (unsigned char)(status_smc == status);
    // [127] main::check_status_smc3_return#0 = (char)main::check_status_smc3_$0
    // [128] phi from main::check_status_smc3 to main::check_status_cx16_rom1 [phi:main::check_status_smc3->main::check_status_cx16_rom1]
    // main::check_status_cx16_rom1
    // main::check_status_cx16_rom1_check_status_rom1
    // status_rom[rom_chip] == status
    // [129] main::check_status_cx16_rom1_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vbom1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_cx16_rom1_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [130] main::check_status_cx16_rom1_check_status_rom1_return#0 = (char)main::check_status_cx16_rom1_check_status_rom1_$0
    // main::@70
    // if(!check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH))
    // [131] if(0!=main::check_status_smc3_return#0) goto main::check_status_smc4 -- 0_neq_vbum1_then_la1 
    lda check_status_smc3_return
    bne check_status_smc4
    // main::@237
    // [132] if(0!=main::check_status_cx16_rom1_check_status_rom1_return#0) goto main::@35 -- 0_neq_vbum1_then_la1 
    lda check_status_cx16_rom1_check_status_rom1_return
    beq !__b35+
    jmp __b35
  !__b35:
    // main::check_status_smc4
  check_status_smc4:
    // status_smc == status
    // [133] main::check_status_smc4_$0 = status_smc#122 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc4_main__0
    // return (unsigned char)(status_smc == status);
    // [134] main::check_status_smc4_return#0 = (char)main::check_status_smc4_$0
    // [135] phi from main::check_status_smc4 to main::check_status_cx16_rom2 [phi:main::check_status_smc4->main::check_status_cx16_rom2]
    // main::check_status_cx16_rom2
    // main::check_status_cx16_rom2_check_status_rom1
    // status_rom[rom_chip] == status
    // [136] main::check_status_cx16_rom2_check_status_rom1_$0 = *status_rom == STATUS_NONE -- vbom1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_NONE
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_cx16_rom2_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [137] main::check_status_cx16_rom2_check_status_rom1_return#0 = (char)main::check_status_cx16_rom2_check_status_rom1_$0
    // main::@71
    // if(check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_NONE))
    // [138] if(0==main::check_status_smc4_return#0) goto main::check_status_smc5 -- 0_eq_vbum1_then_la1 
    // VA3 | SMC.BIN and CX16 ROM not Detected
    lda check_status_smc4_return
    beq check_status_smc5
    // main::@238
    // [139] if(0!=main::check_status_cx16_rom2_check_status_rom1_return#0) goto main::@2 -- 0_neq_vbum1_then_la1 
    lda check_status_cx16_rom2_check_status_rom1_return
    beq !__b2+
    jmp __b2
  !__b2:
    // main::check_status_smc5
  check_status_smc5:
    // status_smc == status
    // [140] main::check_status_smc5_$0 = status_smc#122 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc5_main__0
    // return (unsigned char)(status_smc == status);
    // [141] main::check_status_smc5_return#0 = (char)main::check_status_smc5_$0
    // [142] phi from main::check_status_smc5 to main::check_status_cx16_rom3 [phi:main::check_status_smc5->main::check_status_cx16_rom3]
    // main::check_status_cx16_rom3
    // main::check_status_cx16_rom3_check_status_rom1
    // status_rom[rom_chip] == status
    // [143] main::check_status_cx16_rom3_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vbom1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_cx16_rom3_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [144] main::check_status_cx16_rom3_check_status_rom1_return#0 = (char)main::check_status_cx16_rom3_check_status_rom1_$0
    // main::@72
    // if(check_status_smc(STATUS_FLASH) && !check_status_cx16_rom(STATUS_FLASH))
    // [145] if(0==main::check_status_smc5_return#0) goto main::check_status_smc6 -- 0_eq_vbum1_then_la1 
    lda check_status_smc5_return
    beq check_status_smc6
    // main::@239
    // [146] if(0==main::check_status_cx16_rom3_check_status_rom1_return#0) goto main::@7 -- 0_eq_vbum1_then_la1 
    lda check_status_cx16_rom3_check_status_rom1_return
    bne !__b7+
    jmp __b7
  !__b7:
    // main::check_status_smc6
  check_status_smc6:
    // status_smc == status
    // [147] main::check_status_smc6_$0 = status_smc#122 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc6_main__0
    // return (unsigned char)(status_smc == status);
    // [148] main::check_status_smc6_return#0 = (char)main::check_status_smc6_$0
    // [149] phi from main::check_status_smc6 to main::check_status_cx16_rom4 [phi:main::check_status_smc6->main::check_status_cx16_rom4]
    // main::check_status_cx16_rom4
    // main::check_status_cx16_rom4_check_status_rom1
    // status_rom[rom_chip] == status
    // [150] main::check_status_cx16_rom4_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom4_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [151] main::check_status_cx16_rom4_check_status_rom1_return#0 = (char)main::check_status_cx16_rom4_check_status_rom1_$0
    // main::@73
    // smc_supported_rom(rom_file_release[0])
    // [152] smc_supported_rom::rom_release#0 = *rom_file_release -- vbuz1=_deref_pbuc1 
    lda rom_file_release
    sta.z smc_supported_rom.rom_release
    // [153] call smc_supported_rom
    // [1003] phi from main::@73 to smc_supported_rom [phi:main::@73->smc_supported_rom]
    jsr smc_supported_rom
    // smc_supported_rom(rom_file_release[0])
    // [154] smc_supported_rom::return#3 = smc_supported_rom::return#2
    // main::@158
    // [155] main::$28 = smc_supported_rom::return#3
    // if(check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH) && !smc_supported_rom(rom_file_release[0]))
    // [156] if(0==main::check_status_smc6_return#0) goto main::check_status_smc7 -- 0_eq_vbum1_then_la1 
    lda check_status_smc6_return
    beq check_status_smc7
    // main::@241
    // [157] if(0==main::check_status_cx16_rom4_check_status_rom1_return#0) goto main::check_status_smc7 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_cx16_rom4_check_status_rom1_return
    beq check_status_smc7
    // main::@240
    // [158] if(0==main::$28) goto main::@10 -- 0_eq_vbum1_then_la1 
    lda main__28
    bne !__b10+
    jmp __b10
  !__b10:
    // main::check_status_smc7
  check_status_smc7:
    // status_smc == status
    // [159] main::check_status_smc7_$0 = status_smc#122 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc7_main__0
    // return (unsigned char)(status_smc == status);
    // [160] main::check_status_smc7_return#0 = (char)main::check_status_smc7_$0
    // main::@74
    // if(check_status_smc(STATUS_FLASH) && smc_release == smc_file_release && smc_major == smc_file_major && smc_minor == smc_file_minor)
    // [161] if(0==main::check_status_smc7_return#0) goto main::check_status_cx16_rom5 -- 0_eq_vbum1_then_la1 
    lda check_status_smc7_return
    beq check_status_cx16_rom5
    // main::@244
    // [162] if(smc_release#393==smc_file_release#316) goto main::@243 -- vbum1_eq_vbum2_then_la1 
    lda smc_release
    cmp smc_file_release
    bne !__b243+
    jmp __b243
  !__b243:
    // [163] phi from main::@166 main::@242 main::@243 main::@244 main::@74 to main::check_status_cx16_rom5 [phi:main::@166/main::@242/main::@243/main::@244/main::@74->main::check_status_cx16_rom5]
    // main::check_status_cx16_rom5
  check_status_cx16_rom5:
    // main::check_status_cx16_rom5_check_status_rom1
    // status_rom[rom_chip] == status
    // [164] main::check_status_cx16_rom5_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vbom1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_cx16_rom5_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [165] main::check_status_cx16_rom5_check_status_rom1_return#0 = (char)main::check_status_cx16_rom5_check_status_rom1_$0
    // [166] phi from main::check_status_cx16_rom5_check_status_rom1 to main::@75 [phi:main::check_status_cx16_rom5_check_status_rom1->main::@75]
    // main::@75
    // strncmp(&rom_github[0], &rom_file_github[0], 7)
    // [167] call strncmp
    // [1010] phi from main::@75 to strncmp [phi:main::@75->strncmp]
    jsr strncmp
    // strncmp(&rom_github[0], &rom_file_github[0], 7)
    // [168] strncmp::return#3 = strncmp::return#2
    // main::@164
    // [169] main::$43 = strncmp::return#3 -- vwsm1=vwsm2 
    lda strncmp.return
    sta main__43
    lda strncmp.return+1
    sta main__43+1
    // if(check_status_cx16_rom(STATUS_FLASH) && rom_release[0] == rom_file_release[0] && strncmp(&rom_github[0], &rom_file_github[0], 7) == 0)
    // [170] if(0==main::check_status_cx16_rom5_check_status_rom1_return#0) goto main::check_status_smc8 -- 0_eq_vbum1_then_la1 
    lda check_status_cx16_rom5_check_status_rom1_return
    beq check_status_smc8
    // main::@246
    // [171] if(*rom_release!=*rom_file_release) goto main::check_status_smc8 -- _deref_pbuc1_neq__deref_pbuc2_then_la1 
    lda rom_release
    cmp rom_file_release
    bne check_status_smc8
    // main::@245
    // [172] if(main::$43==0) goto main::@13 -- vwsm1_eq_0_then_la1 
    lda main__43
    ora main__43+1
    bne !__b13+
    jmp __b13
  !__b13:
    // main::check_status_smc8
  check_status_smc8:
    // status_smc == status
    // [173] main::check_status_smc8_$0 = status_smc#122 == STATUS_ISSUE -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc8_main__0
    // return (unsigned char)(status_smc == status);
    // [174] main::check_status_smc8_return#0 = (char)main::check_status_smc8_$0
    // main::check_status_vera1
    // status_vera == status
    // [175] main::check_status_vera1_$0 = status_vera#103 == STATUS_ISSUE -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_vera1_main__0
    // return (unsigned char)(status_vera == status);
    // [176] main::check_status_vera1_return#0 = (char)main::check_status_vera1_$0
    // [177] phi from main::check_status_vera1 to main::@76 [phi:main::check_status_vera1->main::@76]
    // main::@76
    // check_status_roms(STATUS_ISSUE)
    // [178] call check_status_roms
    // [1022] phi from main::@76 to check_status_roms [phi:main::@76->check_status_roms]
    // [1022] phi check_status_roms::status#6 = STATUS_ISSUE [phi:main::@76->check_status_roms#0] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta check_status_roms.status
    jsr check_status_roms
    // check_status_roms(STATUS_ISSUE)
    // [179] check_status_roms::return#3 = check_status_roms::return#2
    // main::@167
    // [180] main::$52 = check_status_roms::return#3 -- vbum1=vbum2 
    lda check_status_roms.return
    sta main__52
    // main::check_status_smc9
    // status_smc == status
    // [181] main::check_status_smc9_$0 = status_smc#122 == STATUS_ERROR -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc9_main__0
    // return (unsigned char)(status_smc == status);
    // [182] main::check_status_smc9_return#0 = (char)main::check_status_smc9_$0
    // main::check_status_vera2
    // status_vera == status
    // [183] main::check_status_vera2_$0 = status_vera#103 == STATUS_ERROR -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera2_main__0
    // return (unsigned char)(status_vera == status);
    // [184] main::check_status_vera2_return#0 = (char)main::check_status_vera2_$0
    // [185] phi from main::check_status_vera2 to main::@77 [phi:main::check_status_vera2->main::@77]
    // main::@77
    // check_status_roms(STATUS_ERROR)
    // [186] call check_status_roms
    // [1022] phi from main::@77 to check_status_roms [phi:main::@77->check_status_roms]
    // [1022] phi check_status_roms::status#6 = STATUS_ERROR [phi:main::@77->check_status_roms#0] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta check_status_roms.status
    jsr check_status_roms
    // check_status_roms(STATUS_ERROR)
    // [187] check_status_roms::return#4 = check_status_roms::return#2
    // main::@168
    // [188] main::$61 = check_status_roms::return#4
    // if(!check_status_smc(STATUS_ISSUE) && !check_status_vera(STATUS_ISSUE) && !check_status_roms(STATUS_ISSUE) &&
    //        !check_status_smc(STATUS_ERROR) && !check_status_vera(STATUS_ERROR) && !check_status_roms(STATUS_ERROR))
    // [189] if(0!=main::check_status_smc8_return#0) goto main::check_status_vera3 -- 0_neq_vbum1_then_la1 
    lda check_status_smc8_return
    bne check_status_vera3
    // main::@251
    // [190] if(0==main::check_status_vera1_return#0) goto main::@250 -- 0_eq_vbum1_then_la1 
    lda check_status_vera1_return
    bne !__b250+
    jmp __b250
  !__b250:
    // main::check_status_vera3
  check_status_vera3:
    // status_vera == status
    // [191] main::check_status_vera3_$0 = status_vera#103 == STATUS_ERROR -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera3_main__0
    // return (unsigned char)(status_vera == status);
    // [192] main::check_status_vera3_return#0 = (char)main::check_status_vera3_$0
    // main::@78
    // if(check_status_vera(STATUS_ERROR))
    // [193] if(0==main::check_status_vera3_return#0) goto main::check_status_smc14 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_vera3_return
    bne !check_status_smc14+
    jmp check_status_smc14
  !check_status_smc14:
    // main::bank_set_brom6
    // BROM = bank
    // [194] BROM = main::bank_set_brom6_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom6_bank
    sta.z BROM
    // main::CLI2
    // asm
    // asm { cli  }
    cli
    // main::vera_display_set_border_color1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [196] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [197] *VERA_DC_BORDER = RED -- _deref_pbuc1=vbuc2 
    lda #RED
    sta VERA_DC_BORDER
    // [198] phi from main::vera_display_set_border_color1 to main::@85 [phi:main::vera_display_set_border_color1->main::@85]
    // main::@85
    // textcolor(WHITE)
    // [199] call textcolor
    // [760] phi from main::@85 to textcolor [phi:main::@85->textcolor]
    // [760] phi textcolor::color#23 = WHITE [phi:main::@85->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [200] phi from main::@85 to main::@203 [phi:main::@85->main::@203]
    // main::@203
    // bgcolor(BLUE)
    // [201] call bgcolor
    // [765] phi from main::@203 to bgcolor [phi:main::@203->bgcolor]
    // [765] phi bgcolor::color#15 = BLUE [phi:main::@203->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [202] phi from main::@203 to main::@204 [phi:main::@203->main::@204]
    // main::@204
    // clrscr()
    // [203] call clrscr
    jsr clrscr
    // [204] phi from main::@204 to main::@205 [phi:main::@204->main::@205]
    // main::@205
    // printf("There was a severe error updating your VERA!")
    // [205] call printf_str
    // [1054] phi from main::@205 to printf_str [phi:main::@205->printf_str]
    // [1054] phi printf_str::putc#75 = &cputc [phi:main::@205->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = main::s13 [phi:main::@205->printf_str#1] -- pbuz1=pbuc1 
    lda #<s13
    sta.z printf_str.s
    lda #>s13
    sta.z printf_str.s+1
    jsr printf_str
    // [206] phi from main::@205 to main::@206 [phi:main::@205->main::@206]
    // main::@206
    // printf("You are back at the READY prompt without resetting your CX16.\n\n")
    // [207] call printf_str
    // [1054] phi from main::@206 to printf_str [phi:main::@206->printf_str]
    // [1054] phi printf_str::putc#75 = &cputc [phi:main::@206->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = main::s14 [phi:main::@206->printf_str#1] -- pbuz1=pbuc1 
    lda #<s14
    sta.z printf_str.s
    lda #>s14
    sta.z printf_str.s+1
    jsr printf_str
    // [208] phi from main::@206 to main::@207 [phi:main::@206->main::@207]
    // main::@207
    // printf("Please don't reset or shut down your VERA until you've\n")
    // [209] call printf_str
    // [1054] phi from main::@207 to printf_str [phi:main::@207->printf_str]
    // [1054] phi printf_str::putc#75 = &cputc [phi:main::@207->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = main::s15 [phi:main::@207->printf_str#1] -- pbuz1=pbuc1 
    lda #<s15
    sta.z printf_str.s
    lda #>s15
    sta.z printf_str.s+1
    jsr printf_str
    // [210] phi from main::@207 to main::@208 [phi:main::@207->main::@208]
    // main::@208
    // printf("managed to either reflash your VERA with the previous firmware ")
    // [211] call printf_str
    // [1054] phi from main::@208 to printf_str [phi:main::@208->printf_str]
    // [1054] phi printf_str::putc#75 = &cputc [phi:main::@208->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = main::s16 [phi:main::@208->printf_str#1] -- pbuz1=pbuc1 
    lda #<s16
    sta.z printf_str.s
    lda #>s16
    sta.z printf_str.s+1
    jsr printf_str
    // [212] phi from main::@208 to main::@209 [phi:main::@208->main::@209]
    // main::@209
    // printf("or have update successs retrying!\n\n")
    // [213] call printf_str
    // [1054] phi from main::@209 to printf_str [phi:main::@209->printf_str]
    // [1054] phi printf_str::putc#75 = &cputc [phi:main::@209->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = main::s17 [phi:main::@209->printf_str#1] -- pbuz1=pbuc1 
    lda #<s17
    sta.z printf_str.s
    lda #>s17
    sta.z printf_str.s+1
    jsr printf_str
    // [214] phi from main::@209 to main::@210 [phi:main::@209->main::@210]
    // main::@210
    // printf("PLEASE REMOVE THE JP1 JUMPER OR YOUR SDCARD WON'T WORK!\n")
    // [215] call printf_str
    // [1054] phi from main::@210 to printf_str [phi:main::@210->printf_str]
    // [1054] phi printf_str::putc#75 = &cputc [phi:main::@210->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = main::s18 [phi:main::@210->printf_str#1] -- pbuz1=pbuc1 
    lda #<s18
    sta.z printf_str.s
    lda #>s18
    sta.z printf_str.s+1
    jsr printf_str
    // [216] phi from main::@210 to main::@211 [phi:main::@210->main::@211]
    // main::@211
    // wait_moment(32)
    // [217] call wait_moment
    // [1063] phi from main::@211 to wait_moment [phi:main::@211->wait_moment]
    // [1063] phi wait_moment::w#7 = $20 [phi:main::@211->wait_moment#0] -- vbum1=vbuc1 
    lda #$20
    sta wait_moment.w
    jsr wait_moment
    // [218] phi from main::@211 to main::@212 [phi:main::@211->main::@212]
    // main::@212
    // system_reset()
    // [219] call system_reset
    // [1071] phi from main::@212 to system_reset [phi:main::@212->system_reset]
    jsr system_reset
    // main::@return
    // }
    // [220] return 
    rts
    // main::check_status_smc14
  check_status_smc14:
    // status_smc == status
    // [221] main::check_status_smc14_$0 = status_smc#122 == STATUS_SKIP -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc14_main__0
    // return (unsigned char)(status_smc == status);
    // [222] main::check_status_smc14_return#0 = (char)main::check_status_smc14_$0
    // main::check_status_smc15
    // status_smc == status
    // [223] main::check_status_smc15_$0 = status_smc#122 == STATUS_NONE -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_NONE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc15_main__0
    // return (unsigned char)(status_smc == status);
    // [224] main::check_status_smc15_return#0 = (char)main::check_status_smc15_$0
    // main::check_status_vera5
    // status_vera == status
    // [225] main::check_status_vera5_$0 = status_vera#103 == STATUS_SKIP -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera5_main__0
    // return (unsigned char)(status_vera == status);
    // [226] main::check_status_vera5_return#0 = (char)main::check_status_vera5_$0
    // main::check_status_vera6
    // status_vera == status
    // [227] main::check_status_vera6_$0 = status_vera#103 == STATUS_NONE -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_NONE
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_vera6_main__0
    // return (unsigned char)(status_vera == status);
    // [228] main::check_status_vera6_return#0 = (char)main::check_status_vera6_$0
    // [229] phi from main::check_status_vera6 to main::@84 [phi:main::check_status_vera6->main::@84]
    // main::@84
    // check_status_roms_less(STATUS_SKIP)
    // [230] call check_status_roms_less
    // [1076] phi from main::@84 to check_status_roms_less [phi:main::@84->check_status_roms_less]
    jsr check_status_roms_less
    // check_status_roms_less(STATUS_SKIP)
    // [231] check_status_roms_less::return#3 = check_status_roms_less::return#2
    // main::@202
    // [232] main::$74 = check_status_roms_less::return#3
    // if((check_status_smc(STATUS_SKIP) || check_status_smc(STATUS_NONE)) && 
    //        (check_status_vera(STATUS_SKIP) || check_status_vera(STATUS_NONE)) && 
    //        (check_status_roms_less(STATUS_SKIP)) )
    // [233] if(0!=main::check_status_smc14_return#0) goto main::@259 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc14_return
    beq !__b259+
    jmp __b259
  !__b259:
    // main::@260
    // [234] if(0!=main::check_status_smc15_return#0) goto main::@259 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc15_return
    beq !__b259+
    jmp __b259
  !__b259:
    // main::check_status_smc16
  check_status_smc16:
    // status_smc == status
    // [235] main::check_status_smc16_$0 = status_smc#122 == STATUS_ERROR -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc16_main__0
    // return (unsigned char)(status_smc == status);
    // [236] main::check_status_smc16_return#0 = (char)main::check_status_smc16_$0
    // main::check_status_vera7
    // status_vera == status
    // [237] main::check_status_vera7_$0 = status_vera#103 == STATUS_ERROR -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ERROR
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera7_main__0
    // return (unsigned char)(status_vera == status);
    // [238] main::check_status_vera7_return#0 = (char)main::check_status_vera7_$0
    // [239] phi from main::check_status_vera7 to main::@87 [phi:main::check_status_vera7->main::@87]
    // main::@87
    // check_status_roms(STATUS_ERROR)
    // [240] call check_status_roms
    // [1022] phi from main::@87 to check_status_roms [phi:main::@87->check_status_roms]
    // [1022] phi check_status_roms::status#6 = STATUS_ERROR [phi:main::@87->check_status_roms#0] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta check_status_roms.status
    jsr check_status_roms
    // check_status_roms(STATUS_ERROR)
    // [241] check_status_roms::return#10 = check_status_roms::return#2
    // main::@213
    // [242] main::$262 = check_status_roms::return#10
    // if(check_status_smc(STATUS_ERROR) || check_status_vera(STATUS_ERROR) || check_status_roms(STATUS_ERROR))
    // [243] if(0!=main::check_status_smc16_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc16_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@262
    // [244] if(0!=main::check_status_vera7_return#0) goto main::vera_display_set_border_color3 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_vera7_return
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::@261
    // [245] if(0!=main::$262) goto main::vera_display_set_border_color3 -- 0_neq_vbum1_then_la1 
    lda main__262
    beq !vera_display_set_border_color3+
    jmp vera_display_set_border_color3
  !vera_display_set_border_color3:
    // main::check_status_smc17
    // status_smc == status
    // [246] main::check_status_smc17_$0 = status_smc#122 == STATUS_ISSUE -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc17_main__0
    // return (unsigned char)(status_smc == status);
    // [247] main::check_status_smc17_return#0 = (char)main::check_status_smc17_$0
    // main::check_status_vera8
    // status_vera == status
    // [248] main::check_status_vera8_$0 = status_vera#103 == STATUS_ISSUE -- vboz1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_ISSUE
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_vera8_main__0
    // return (unsigned char)(status_vera == status);
    // [249] main::check_status_vera8_return#0 = (char)main::check_status_vera8_$0
    // [250] phi from main::check_status_vera8 to main::@89 [phi:main::check_status_vera8->main::@89]
    // main::@89
    // check_status_roms(STATUS_ISSUE)
    // [251] call check_status_roms
    // [1022] phi from main::@89 to check_status_roms [phi:main::@89->check_status_roms]
    // [1022] phi check_status_roms::status#6 = STATUS_ISSUE [phi:main::@89->check_status_roms#0] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta check_status_roms.status
    jsr check_status_roms
    // check_status_roms(STATUS_ISSUE)
    // [252] check_status_roms::return#11 = check_status_roms::return#2
    // main::@215
    // [253] main::$267 = check_status_roms::return#11
    // if(check_status_smc(STATUS_ISSUE) || check_status_vera(STATUS_ISSUE) || check_status_roms(STATUS_ISSUE))
    // [254] if(0!=main::check_status_smc17_return#0) goto main::vera_display_set_border_color4 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc17_return
    beq !vera_display_set_border_color4+
    jmp vera_display_set_border_color4
  !vera_display_set_border_color4:
    // main::@264
    // [255] if(0!=main::check_status_vera8_return#0) goto main::vera_display_set_border_color4 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_vera8_return
    beq !vera_display_set_border_color4+
    jmp vera_display_set_border_color4
  !vera_display_set_border_color4:
    // main::@263
    // [256] if(0!=main::$267) goto main::vera_display_set_border_color4 -- 0_neq_vbum1_then_la1 
    lda main__267
    beq !vera_display_set_border_color4+
    jmp vera_display_set_border_color4
  !vera_display_set_border_color4:
    // main::vera_display_set_border_color5
    // *VERA_CTRL &= ~VERA_DCSEL
    // [257] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [258] *VERA_DC_BORDER = GREEN -- _deref_pbuc1=vbuc2 
    lda #GREEN
    sta VERA_DC_BORDER
    // [259] phi from main::vera_display_set_border_color5 to main::@91 [phi:main::vera_display_set_border_color5->main::@91]
    // main::@91
    // display_action_progress("Your CX16 update is a success!")
    // [260] call display_action_progress
    // [1084] phi from main::@91 to display_action_progress [phi:main::@91->display_action_progress]
    // [1084] phi display_action_progress::info_text#20 = main::info_text44 [phi:main::@91->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text44
    sta.z display_action_progress.info_text
    lda #>info_text44
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::check_status_smc18
    // status_smc == status
    // [261] main::check_status_smc18_$0 = status_smc#122 == STATUS_FLASHED -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASHED
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc18_main__0
    // return (unsigned char)(status_smc == status);
    // [262] main::check_status_smc18_return#0 = (char)main::check_status_smc18_$0
    // main::@92
    // if(check_status_smc(STATUS_FLASHED))
    // [263] if(0!=main::check_status_smc18_return#0) goto main::@55 -- 0_neq_vbum1_then_la1 
    lda check_status_smc18_return
    beq !__b55+
    jmp __b55
  !__b55:
    // [264] phi from main::@92 to main::@16 [phi:main::@92->main::@16]
    // main::@16
    // display_progress_text(display_debriefing_text_rom, display_debriefing_count_rom)
    // [265] call display_progress_text
    // [1098] phi from main::@16 to display_progress_text [phi:main::@16->display_progress_text]
    // [1098] phi display_progress_text::text#12 = display_debriefing_text_rom [phi:main::@16->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_debriefing_text_rom
    sta.z display_progress_text.text
    lda #>display_debriefing_text_rom
    sta.z display_progress_text.text+1
    // [1098] phi display_progress_text::lines#11 = display_debriefing_count_rom [phi:main::@16->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_debriefing_count_rom
    sta display_progress_text.lines
    jsr display_progress_text
    // [266] phi from main::@16 main::@86 main::@90 to main::@3 [phi:main::@16/main::@86/main::@90->main::@3]
    // main::@3
  __b3:
    // textcolor(PINK)
    // [267] call textcolor
  // DE6 | Wait until reset
    // [760] phi from main::@3 to textcolor [phi:main::@3->textcolor]
    // [760] phi textcolor::color#23 = PINK [phi:main::@3->textcolor#0] -- vbum1=vbuc1 
    lda #PINK
    sta textcolor.color
    jsr textcolor
    // [268] phi from main::@3 to main::@228 [phi:main::@3->main::@228]
    // main::@228
    // display_progress_line(2, "DON'T DO ANYTHING UNTIL COUNTDOWN FINISHES!")
    // [269] call display_progress_line
    // [1108] phi from main::@228 to display_progress_line [phi:main::@228->display_progress_line]
    // [1108] phi display_progress_line::text#3 = main::text [phi:main::@228->display_progress_line#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_progress_line.text
    lda #>text
    sta.z display_progress_line.text+1
    // [1108] phi display_progress_line::line#3 = 2 [phi:main::@228->display_progress_line#1] -- vbuz1=vbuc1 
    lda #2
    sta.z display_progress_line.line
    jsr display_progress_line
    // [270] phi from main::@228 to main::@229 [phi:main::@228->main::@229]
    // main::@229
    // textcolor(WHITE)
    // [271] call textcolor
    // [760] phi from main::@229 to textcolor [phi:main::@229->textcolor]
    // [760] phi textcolor::color#23 = WHITE [phi:main::@229->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [272] phi from main::@229 to main::@63 [phi:main::@229->main::@63]
    // [272] phi main::w1#2 = $78 [phi:main::@229->main::@63#0] -- vbum1=vbuc1 
    lda #$78
    sta w1
    // main::@63
  __b63:
    // for (unsigned char w=120; w>0; w--)
    // [273] if(main::w1#2>0) goto main::@64 -- vbum1_gt_0_then_la1 
    lda w1
    bne __b64
    // [274] phi from main::@63 to main::@65 [phi:main::@63->main::@65]
    // main::@65
    // system_reset()
    // [275] call system_reset
    // [1071] phi from main::@65 to system_reset [phi:main::@65->system_reset]
    jsr system_reset
    rts
    // [276] phi from main::@63 to main::@64 [phi:main::@63->main::@64]
    // main::@64
  __b64:
    // wait_moment(1)
    // [277] call wait_moment
    // [1063] phi from main::@64 to wait_moment [phi:main::@64->wait_moment]
    // [1063] phi wait_moment::w#7 = 1 [phi:main::@64->wait_moment#0] -- vbum1=vbuc1 
    lda #1
    sta wait_moment.w
    jsr wait_moment
    // [278] phi from main::@64 to main::@230 [phi:main::@64->main::@230]
    // main::@230
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [279] call snprintf_init
    // [1113] phi from main::@230 to snprintf_init [phi:main::@230->snprintf_init]
    // [1113] phi snprintf_init::s#25 = info_text [phi:main::@230->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [280] phi from main::@230 to main::@231 [phi:main::@230->main::@231]
    // main::@231
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [281] call printf_str
    // [1054] phi from main::@231 to printf_str [phi:main::@231->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:main::@231->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = main::s22 [phi:main::@231->printf_str#1] -- pbuz1=pbuc1 
    lda #<s22
    sta.z printf_str.s
    lda #>s22
    sta.z printf_str.s+1
    jsr printf_str
    // main::@232
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [282] printf_uchar::uvalue#16 = main::w1#2 -- vbum1=vbum2 
    lda w1
    sta printf_uchar.uvalue
    // [283] call printf_uchar
    // [1118] phi from main::@232 to printf_uchar [phi:main::@232->printf_uchar]
    // [1118] phi printf_uchar::format_zero_padding#17 = 0 [phi:main::@232->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1118] phi printf_uchar::format_min_length#17 = 0 [phi:main::@232->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1118] phi printf_uchar::putc#17 = &snputc [phi:main::@232->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1118] phi printf_uchar::format_radix#17 = DECIMAL [phi:main::@232->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1118] phi printf_uchar::uvalue#17 = printf_uchar::uvalue#16 [phi:main::@232->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [284] phi from main::@232 to main::@233 [phi:main::@232->main::@233]
    // main::@233
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [285] call printf_str
    // [1054] phi from main::@233 to printf_str [phi:main::@233->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:main::@233->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = main::s23 [phi:main::@233->printf_str#1] -- pbuz1=pbuc1 
    lda #<s23
    sta.z printf_str.s
    lda #>s23
    sta.z printf_str.s+1
    jsr printf_str
    // main::@234
    // sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w)
    // [286] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [287] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [289] call display_action_text
    // [1129] phi from main::@234 to display_action_text [phi:main::@234->display_action_text]
    // [1129] phi display_action_text::info_text#17 = info_text [phi:main::@234->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@235
    // for (unsigned char w=120; w>0; w--)
    // [290] main::w1#1 = -- main::w1#2 -- vbum1=_dec_vbum1 
    dec w1
    // [272] phi from main::@235 to main::@63 [phi:main::@235->main::@63]
    // [272] phi main::w1#2 = main::w1#1 [phi:main::@235->main::@63#0] -- register_copy 
    jmp __b63
    // main::@55
  __b55:
    // if(smc_bootloader == 1)
    // [291] if(smc_bootloader#0!=1) goto main::@56 -- vwum1_neq_vbuc1_then_la1 
    lda smc_bootloader+1
    bne __b56
    lda smc_bootloader
    cmp #1
    bne __b56
    // [292] phi from main::@55 to main::@61 [phi:main::@55->main::@61]
    // main::@61
    // smc_reset()
    // [293] call smc_reset
    // [1143] phi from main::@61 to smc_reset [phi:main::@61->smc_reset]
    jsr smc_reset
    // [294] phi from main::@55 main::@61 to main::@56 [phi:main::@55/main::@61->main::@56]
    // main::@56
  __b56:
    // display_progress_text(display_debriefing_text_smc, display_debriefing_count_smc)
    // [295] call display_progress_text
    // [1098] phi from main::@56 to display_progress_text [phi:main::@56->display_progress_text]
    // [1098] phi display_progress_text::text#12 = display_debriefing_text_smc [phi:main::@56->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_debriefing_text_smc
    sta.z display_progress_text.text
    lda #>display_debriefing_text_smc
    sta.z display_progress_text.text+1
    // [1098] phi display_progress_text::lines#11 = display_debriefing_count_smc [phi:main::@56->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_debriefing_count_smc
    sta display_progress_text.lines
    jsr display_progress_text
    // [296] phi from main::@56 to main::@216 [phi:main::@56->main::@216]
    // main::@216
    // textcolor(PINK)
    // [297] call textcolor
    // [760] phi from main::@216 to textcolor [phi:main::@216->textcolor]
    // [760] phi textcolor::color#23 = PINK [phi:main::@216->textcolor#0] -- vbum1=vbuc1 
    lda #PINK
    sta textcolor.color
    jsr textcolor
    // [298] phi from main::@216 to main::@217 [phi:main::@216->main::@217]
    // main::@217
    // display_progress_line(2, "DON'T DO ANYTHING UNTIL COUNTDOWN FINISHES!")
    // [299] call display_progress_line
    // [1108] phi from main::@217 to display_progress_line [phi:main::@217->display_progress_line]
    // [1108] phi display_progress_line::text#3 = main::text [phi:main::@217->display_progress_line#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_progress_line.text
    lda #>text
    sta.z display_progress_line.text+1
    // [1108] phi display_progress_line::line#3 = 2 [phi:main::@217->display_progress_line#1] -- vbuz1=vbuc1 
    lda #2
    sta.z display_progress_line.line
    jsr display_progress_line
    // [300] phi from main::@217 to main::@218 [phi:main::@217->main::@218]
    // main::@218
    // textcolor(WHITE)
    // [301] call textcolor
    // [760] phi from main::@218 to textcolor [phi:main::@218->textcolor]
    // [760] phi textcolor::color#23 = WHITE [phi:main::@218->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [302] phi from main::@218 to main::@57 [phi:main::@218->main::@57]
    // [302] phi main::w#2 = $78 [phi:main::@218->main::@57#0] -- vbum1=vbuc1 
    lda #$78
    sta w
    // main::@57
  __b57:
    // for (unsigned char w=120; w>0; w--)
    // [303] if(main::w#2>0) goto main::@58 -- vbum1_gt_0_then_la1 
    lda w
    bne __b58
    // [304] phi from main::@57 to main::@59 [phi:main::@57->main::@59]
    // main::@59
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [305] call snprintf_init
    // [1113] phi from main::@59 to snprintf_init [phi:main::@59->snprintf_init]
    // [1113] phi snprintf_init::s#25 = info_text [phi:main::@59->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [306] phi from main::@59 to main::@225 [phi:main::@59->main::@225]
    // main::@225
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [307] call printf_str
    // [1054] phi from main::@225 to printf_str [phi:main::@225->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:main::@225->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = main::s21 [phi:main::@225->printf_str#1] -- pbuz1=pbuc1 
    lda #<s21
    sta.z printf_str.s
    lda #>s21
    sta.z printf_str.s+1
    jsr printf_str
    // main::@226
    // sprintf(info_text, "Please disconnect your CX16 from power source ...")
    // [308] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [309] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [311] call display_action_text
    // [1129] phi from main::@226 to display_action_text [phi:main::@226->display_action_text]
    // [1129] phi display_action_text::info_text#17 = info_text [phi:main::@226->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [312] phi from main::@226 to main::@227 [phi:main::@226->main::@227]
    // main::@227
    // smc_reset()
    // [313] call smc_reset
  // DE5 | The components correctly updated, SMC bootloader 2
  // When bootloader 1, the CX16 won't shut down automatically and will hang! The user will see the above bootloader 1 action.
  // When bootloader 2, the CX16 will shut down automatically. The user will never see the bootloader 1 action.
    // [1143] phi from main::@227 to smc_reset [phi:main::@227->smc_reset]
    jsr smc_reset
    // [314] phi from main::@227 main::@60 to main::@60 [phi:main::@227/main::@60->main::@60]
  __b4:
  // This call will reboot the SMC, which will reset the CX16 if bootloader R2.
    // main::@60
    jmp __b4
    // [315] phi from main::@57 to main::@58 [phi:main::@57->main::@58]
    // main::@58
  __b58:
    // wait_moment(1)
    // [316] call wait_moment
    // [1063] phi from main::@58 to wait_moment [phi:main::@58->wait_moment]
    // [1063] phi wait_moment::w#7 = 1 [phi:main::@58->wait_moment#0] -- vbum1=vbuc1 
    lda #1
    sta wait_moment.w
    jsr wait_moment
    // [317] phi from main::@58 to main::@219 [phi:main::@58->main::@219]
    // main::@219
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [318] call snprintf_init
    // [1113] phi from main::@219 to snprintf_init [phi:main::@219->snprintf_init]
    // [1113] phi snprintf_init::s#25 = info_text [phi:main::@219->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [319] phi from main::@219 to main::@220 [phi:main::@219->main::@220]
    // main::@220
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [320] call printf_str
    // [1054] phi from main::@220 to printf_str [phi:main::@220->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:main::@220->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = s1 [phi:main::@220->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s1
    sta.z printf_str.s
    lda #>@s1
    sta.z printf_str.s+1
    jsr printf_str
    // main::@221
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [321] printf_uchar::uvalue#15 = main::w#2 -- vbum1=vbum2 
    lda w
    sta printf_uchar.uvalue
    // [322] call printf_uchar
    // [1118] phi from main::@221 to printf_uchar [phi:main::@221->printf_uchar]
    // [1118] phi printf_uchar::format_zero_padding#17 = 1 [phi:main::@221->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1118] phi printf_uchar::format_min_length#17 = 3 [phi:main::@221->printf_uchar#1] -- vbum1=vbuc1 
    lda #3
    sta printf_uchar.format_min_length
    // [1118] phi printf_uchar::putc#17 = &snputc [phi:main::@221->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1118] phi printf_uchar::format_radix#17 = DECIMAL [phi:main::@221->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1118] phi printf_uchar::uvalue#17 = printf_uchar::uvalue#15 [phi:main::@221->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [323] phi from main::@221 to main::@222 [phi:main::@221->main::@222]
    // main::@222
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [324] call printf_str
    // [1054] phi from main::@222 to printf_str [phi:main::@222->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:main::@222->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = main::s20 [phi:main::@222->printf_str#1] -- pbuz1=pbuc1 
    lda #<s20
    sta.z printf_str.s
    lda #>s20
    sta.z printf_str.s+1
    jsr printf_str
    // main::@223
    // sprintf(info_text, "[%03u] Please read carefully the below ...", w)
    // [325] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [326] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [328] call display_action_text
    // [1129] phi from main::@223 to display_action_text [phi:main::@223->display_action_text]
    // [1129] phi display_action_text::info_text#17 = info_text [phi:main::@223->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@224
    // for (unsigned char w=120; w>0; w--)
    // [329] main::w#1 = -- main::w#2 -- vbum1=_dec_vbum1 
    dec w
    // [302] phi from main::@224 to main::@57 [phi:main::@224->main::@57]
    // [302] phi main::w#2 = main::w#1 [phi:main::@224->main::@57#0] -- register_copy 
    jmp __b57
    // main::vera_display_set_border_color4
  vera_display_set_border_color4:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [330] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [331] *VERA_DC_BORDER = YELLOW -- _deref_pbuc1=vbuc2 
    lda #YELLOW
    sta VERA_DC_BORDER
    // [332] phi from main::vera_display_set_border_color4 to main::@90 [phi:main::vera_display_set_border_color4->main::@90]
    // main::@90
    // display_action_progress("Update issues, your CX16 is not updated!")
    // [333] call display_action_progress
    // [1084] phi from main::@90 to display_action_progress [phi:main::@90->display_action_progress]
    // [1084] phi display_action_progress::info_text#20 = main::info_text43 [phi:main::@90->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text43
    sta.z display_action_progress.info_text
    lda #>info_text43
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    jmp __b3
    // main::vera_display_set_border_color3
  vera_display_set_border_color3:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [334] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [335] *VERA_DC_BORDER = RED -- _deref_pbuc1=vbuc2 
    lda #RED
    sta VERA_DC_BORDER
    // [336] phi from main::vera_display_set_border_color3 to main::@88 [phi:main::vera_display_set_border_color3->main::@88]
    // main::@88
    // display_action_progress("Update Failure! Your CX16 may no longer boot!")
    // [337] call display_action_progress
    // [1084] phi from main::@88 to display_action_progress [phi:main::@88->display_action_progress]
    // [1084] phi display_action_progress::info_text#20 = main::info_text41 [phi:main::@88->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text41
    sta.z display_action_progress.info_text
    lda #>info_text41
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [338] phi from main::@88 to main::@214 [phi:main::@88->main::@214]
    // main::@214
    // display_action_text("Take a photo of this screen, shut down power and retry!")
    // [339] call display_action_text
    // [1129] phi from main::@214 to display_action_text [phi:main::@214->display_action_text]
    // [1129] phi display_action_text::info_text#17 = main::info_text42 [phi:main::@214->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text42
    sta.z display_action_text.info_text
    lda #>info_text42
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [340] phi from main::@214 main::@62 to main::@62 [phi:main::@214/main::@62->main::@62]
    // main::@62
  __b62:
    jmp __b62
    // main::@259
  __b259:
    // if((check_status_smc(STATUS_SKIP) || check_status_smc(STATUS_NONE)) && 
    //        (check_status_vera(STATUS_SKIP) || check_status_vera(STATUS_NONE)) && 
    //        (check_status_roms_less(STATUS_SKIP)) )
    // [341] if(0!=main::check_status_vera5_return#0) goto main::@258 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_vera5_return
    bne __b258
    // main::@266
    // [342] if(0==main::check_status_vera6_return#0) goto main::check_status_smc16 -- 0_eq_vbum1_then_la1 
    lda check_status_vera6_return
    bne !check_status_smc16+
    jmp check_status_smc16
  !check_status_smc16:
    // main::@258
  __b258:
    // [343] if(0!=main::$74) goto main::vera_display_set_border_color2 -- 0_neq_vbuz1_then_la1 
    lda.z main__74
    bne vera_display_set_border_color2
    jmp check_status_smc16
    // main::vera_display_set_border_color2
  vera_display_set_border_color2:
    // *VERA_CTRL &= ~VERA_DCSEL
    // [344] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_BORDER = color
    // [345] *VERA_DC_BORDER = BLACK -- _deref_pbuc1=vbuc2 
    lda #BLACK
    sta VERA_DC_BORDER
    // [346] phi from main::vera_display_set_border_color2 to main::@86 [phi:main::vera_display_set_border_color2->main::@86]
    // main::@86
    // display_action_progress("No CX16 component has been updated with new firmware!")
    // [347] call display_action_progress
    // [1084] phi from main::@86 to display_action_progress [phi:main::@86->display_action_progress]
    // [1084] phi display_action_progress::info_text#20 = main::info_text40 [phi:main::@86->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text40
    sta.z display_action_progress.info_text
    lda #>info_text40
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    jmp __b3
    // main::@250
  __b250:
    // if(!check_status_smc(STATUS_ISSUE) && !check_status_vera(STATUS_ISSUE) && !check_status_roms(STATUS_ISSUE) &&
    //        !check_status_smc(STATUS_ERROR) && !check_status_vera(STATUS_ERROR) && !check_status_roms(STATUS_ERROR))
    // [348] if(0!=main::$52) goto main::check_status_vera3 -- 0_neq_vbum1_then_la1 
    lda main__52
    beq !check_status_vera3+
    jmp check_status_vera3
  !check_status_vera3:
    // main::@249
    // [349] if(0==main::check_status_smc9_return#0) goto main::@248 -- 0_eq_vbum1_then_la1 
    lda check_status_smc9_return
    beq __b248
    jmp check_status_vera3
    // main::@248
  __b248:
    // [350] if(0!=main::check_status_vera2_return#0) goto main::check_status_vera3 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_vera2_return
    beq !check_status_vera3+
    jmp check_status_vera3
  !check_status_vera3:
    // main::@247
    // [351] if(0==main::$61) goto main::check_status_vera4 -- 0_eq_vbum1_then_la1 
    lda main__61
    beq check_status_vera4
    jmp check_status_vera3
    // main::check_status_vera4
  check_status_vera4:
    // status_vera == status
    // [352] main::check_status_vera4_$0 = status_vera#103 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_vera
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_vera4_main__0
    // return (unsigned char)(status_vera == status);
    // [353] main::check_status_vera4_return#0 = (char)main::check_status_vera4_$0
    // main::check_status_smc10
    // status_smc == status
    // [354] main::check_status_smc10_$0 = status_smc#122 == STATUS_FLASH -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc10_main__0
    // return (unsigned char)(status_smc == status);
    // [355] main::check_status_smc10_return#0 = (char)main::check_status_smc10_$0
    // [356] phi from main::check_status_smc10 to main::check_status_cx16_rom6 [phi:main::check_status_smc10->main::check_status_cx16_rom6]
    // main::check_status_cx16_rom6
    // main::check_status_cx16_rom6_check_status_rom1
    // status_rom[rom_chip] == status
    // [357] main::check_status_cx16_rom6_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom6_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [358] main::check_status_cx16_rom6_check_status_rom1_return#0 = (char)main::check_status_cx16_rom6_check_status_rom1_$0
    // [359] phi from main::check_status_cx16_rom6_check_status_rom1 to main::@79 [phi:main::check_status_cx16_rom6_check_status_rom1->main::@79]
    // main::@79
    // check_status_card_roms(STATUS_FLASH)
    // [360] call check_status_card_roms
    // [1152] phi from main::@79 to check_status_card_roms [phi:main::@79->check_status_card_roms]
    jsr check_status_card_roms
    // check_status_card_roms(STATUS_FLASH)
    // [361] check_status_card_roms::return#3 = check_status_card_roms::return#2
    // main::@171
    // [362] main::$186 = check_status_card_roms::return#3
    // if(check_status_vera(STATUS_FLASH) || check_status_smc(STATUS_FLASH) || check_status_cx16_rom(STATUS_FLASH) || check_status_card_roms(STATUS_FLASH))
    // [363] if(0!=main::check_status_vera4_return#0) goto main::@14 -- 0_neq_vbum1_then_la1 
    lda check_status_vera4_return
    beq !__b14+
    jmp __b14
  !__b14:
    // main::@254
    // [364] if(0!=main::check_status_smc10_return#0) goto main::@14 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc10_return
    beq !__b14+
    jmp __b14
  !__b14:
    // main::@253
    // [365] if(0!=main::check_status_cx16_rom6_check_status_rom1_return#0) goto main::@14 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_cx16_rom6_check_status_rom1_return
    beq !__b14+
    jmp __b14
  !__b14:
    // main::@252
    // [366] if(0!=main::$186) goto main::@14 -- 0_neq_vbum1_then_la1 
    lda main__186
    beq !__b14+
    jmp __b14
  !__b14:
    // main::check_status_smc11
  check_status_smc11:
    // status_smc == status
    // [367] main::check_status_smc11_$0 = status_smc#122 == STATUS_FLASH -- vbom1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_smc11_main__0
    // return (unsigned char)(status_smc == status);
    // [368] main::check_status_smc11_return#0 = (char)main::check_status_smc11_$0
    // [369] phi from main::check_status_smc11 to main::check_status_cx16_rom7 [phi:main::check_status_smc11->main::check_status_cx16_rom7]
    // main::check_status_cx16_rom7
    // main::check_status_cx16_rom7_check_status_rom1
    // status_rom[rom_chip] == status
    // [370] main::check_status_cx16_rom7_check_status_rom1_$0 = *status_rom == STATUS_FLASH -- vboz1=_deref_pbuc1_eq_vbuc2 
    lda status_rom
    eor #STATUS_FLASH
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_cx16_rom7_check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [371] main::check_status_cx16_rom7_check_status_rom1_return#0 = (char)main::check_status_cx16_rom7_check_status_rom1_$0
    // main::@80
    // if (check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH))
    // [372] if(0==main::check_status_smc11_return#0) goto main::SEI3 -- 0_eq_vbum1_then_la1 
    lda check_status_smc11_return
    beq SEI3
    // main::@255
    // [373] if(0!=main::check_status_cx16_rom7_check_status_rom1_return#0) goto main::@51 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_cx16_rom7_check_status_rom1_return
    beq !__b51+
    jmp __b51
  !__b51:
    // [374] phi from main::@255 to main::SEI3 [phi:main::@255->main::SEI3]
    // [374] phi from main::@179 main::@40 main::@41 main::@54 main::@80 to main::SEI3 [phi:main::@179/main::@40/main::@41/main::@54/main::@80->main::SEI3]
    // [374] phi __stdio_filecount#416 = __stdio_filecount#27 [phi:main::@179/main::@40/main::@41/main::@54/main::@80->main::SEI3#0] -- register_copy 
    // [374] phi __errno#424 = __errno#18 [phi:main::@179/main::@40/main::@41/main::@54/main::@80->main::SEI3#1] -- register_copy 
    // main::SEI3
  SEI3:
    // asm
    // asm { sei  }
    sei
    // [376] phi from main::SEI3 to main::@42 [phi:main::SEI3->main::@42]
    // [376] phi __stdio_filecount#116 = __stdio_filecount#416 [phi:main::SEI3->main::@42#0] -- register_copy 
    // [376] phi __errno#102 = __errno#424 [phi:main::SEI3->main::@42#1] -- register_copy 
    // [376] phi main::rom_chip3#10 = 7 [phi:main::SEI3->main::@42#2] -- vbum1=vbuc1 
    lda #7
    sta rom_chip3
  // Flash the ROM chips. 
  // We loop first all the ROM chips and read the file contents.
  // Then we verify the file contents and flash the ROM only for the differences.
  // If the file contents are the same as the ROM contents, then no flashing is required.
  // IMPORTANT! We start to flash the ROMs on the extension card.
  // The last ROM flashed is the CX16 ROM on the CX16 board!
    // main::@42
  __b42:
    // for(unsigned char rom_chip = 7; rom_chip != 255; rom_chip--)
    // [377] if(main::rom_chip3#10!=$ff) goto main::check_status_rom1 -- vbum1_neq_vbuc1_then_la1 
    lda #$ff
    cmp rom_chip3
    bne check_status_rom1
    // [378] phi from main::@42 to main::@43 [phi:main::@42->main::@43]
    // main::@43
    // display_progress_clear()
    // [379] call display_progress_clear
    // [1161] phi from main::@43 to display_progress_clear [phi:main::@43->display_progress_clear]
    jsr display_progress_clear
    jmp check_status_vera3
    // main::check_status_rom1
  check_status_rom1:
    // status_rom[rom_chip] == status
    // [380] main::check_status_rom1_$0 = status_rom[main::rom_chip3#10] == STATUS_FLASH -- vbom1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_FLASH
    ldy rom_chip3
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta check_status_rom1_main__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [381] main::check_status_rom1_return#0 = (char)main::check_status_rom1_$0
    // main::@81
    // if(check_status_rom(rom_chip, STATUS_FLASH))
    // [382] if(0==main::check_status_rom1_return#0) goto main::@44 -- 0_eq_vbum1_then_la1 
    lda check_status_rom1_return
    beq __b44
    // main::check_status_smc12
    // status_smc == status
    // [383] main::check_status_smc12_$0 = status_smc#122 == STATUS_FLASHED -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_FLASHED
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc12_main__0
    // return (unsigned char)(status_smc == status);
    // [384] main::check_status_smc12_return#0 = (char)main::check_status_smc12_$0
    // main::check_status_smc13
    // status_smc == status
    // [385] main::check_status_smc13_$0 = status_smc#122 == STATUS_SKIP -- vboz1=vbum2_eq_vbuc1 
    lda status_smc
    eor #STATUS_SKIP
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_smc13_main__0
    // return (unsigned char)(status_smc == status);
    // [386] main::check_status_smc13_return#0 = (char)main::check_status_smc13_$0
    // main::@82
    // if((rom_chip == 0 && (check_status_smc(STATUS_FLASHED) || check_status_smc(STATUS_SKIP))) || (rom_chip != 0))
    // [387] if(main::rom_chip3#10==0) goto main::@257 -- vbum1_eq_0_then_la1 
    // IMPORTANT! We only flash the CX16 ROM chip if the SMC got flashed succesfully!
    lda rom_chip3
    bne !__b257+
    jmp __b257
  !__b257:
    // main::@256
  __b256:
    // [388] if(main::rom_chip3#10!=0) goto main::bank_set_brom5 -- vbum1_neq_0_then_la1 
    lda rom_chip3
    bne bank_set_brom5
    // main::@50
    // display_info_rom(rom_chip, STATUS_ISSUE, "SMC Update failed!")
    // [389] display_info_rom::rom_chip#10 = main::rom_chip3#10 -- vbum1=vbum2 
    sta display_info_rom.rom_chip
    // [390] call display_info_rom
    // [1176] phi from main::@50 to display_info_rom [phi:main::@50->display_info_rom]
    // [1176] phi display_info_rom::info_text#16 = main::info_text36 [phi:main::@50->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text36
    sta.z display_info_rom.info_text
    lda #>info_text36
    sta.z display_info_rom.info_text+1
    // [1176] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#10 [phi:main::@50->display_info_rom#1] -- register_copy 
    // [1176] phi display_info_rom::info_status#16 = STATUS_ISSUE [phi:main::@50->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // [391] phi from main::@190 main::@201 main::@45 main::@49 main::@50 main::@81 to main::@44 [phi:main::@190/main::@201/main::@45/main::@49/main::@50/main::@81->main::@44]
    // [391] phi __stdio_filecount#417 = __stdio_filecount#30 [phi:main::@190/main::@201/main::@45/main::@49/main::@50/main::@81->main::@44#0] -- register_copy 
    // [391] phi __errno#425 = __errno#18 [phi:main::@190/main::@201/main::@45/main::@49/main::@50/main::@81->main::@44#1] -- register_copy 
    // main::@44
  __b44:
    // for(unsigned char rom_chip = 7; rom_chip != 255; rom_chip--)
    // [392] main::rom_chip3#1 = -- main::rom_chip3#10 -- vbum1=_dec_vbum1 
    dec rom_chip3
    // [376] phi from main::@44 to main::@42 [phi:main::@44->main::@42]
    // [376] phi __stdio_filecount#116 = __stdio_filecount#417 [phi:main::@44->main::@42#0] -- register_copy 
    // [376] phi __errno#102 = __errno#425 [phi:main::@44->main::@42#1] -- register_copy 
    // [376] phi main::rom_chip3#10 = main::rom_chip3#1 [phi:main::@44->main::@42#2] -- register_copy 
    jmp __b42
    // main::bank_set_brom5
  bank_set_brom5:
    // BROM = bank
    // [393] BROM = main::bank_set_brom5_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom5_bank
    sta.z BROM
    // [394] phi from main::bank_set_brom5 to main::@83 [phi:main::bank_set_brom5->main::@83]
    // main::@83
    // display_progress_clear()
    // [395] call display_progress_clear
    // [1161] phi from main::@83 to display_progress_clear [phi:main::@83->display_progress_clear]
    jsr display_progress_clear
    // main::@183
    // unsigned char rom_bank = rom_chip * 32
    // [396] main::rom_bank1#0 = main::rom_chip3#10 << 5 -- vbum1=vbum2_rol_5 
    lda rom_chip3
    asl
    asl
    asl
    asl
    asl
    sta rom_bank1
    // unsigned char* file = rom_file(rom_chip)
    // [397] rom_file::rom_chip#1 = main::rom_chip3#10 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z rom_file.rom_chip
    // [398] call rom_file
    // [1221] phi from main::@183 to rom_file [phi:main::@183->rom_file]
    // [1221] phi rom_file::rom_chip#2 = rom_file::rom_chip#1 [phi:main::@183->rom_file#0] -- register_copy 
    jsr rom_file
    // unsigned char* file = rom_file(rom_chip)
    // [399] rom_file::return#5 = rom_file::return#2
    // main::@184
    // [400] main::file1#0 = rom_file::return#5
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [401] call snprintf_init
    // [1113] phi from main::@184 to snprintf_init [phi:main::@184->snprintf_init]
    // [1113] phi snprintf_init::s#25 = info_text [phi:main::@184->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [402] phi from main::@184 to main::@185 [phi:main::@184->main::@185]
    // main::@185
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [403] call printf_str
    // [1054] phi from main::@185 to printf_str [phi:main::@185->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:main::@185->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = main::s9 [phi:main::@185->printf_str#1] -- pbuz1=pbuc1 
    lda #<s9
    sta.z printf_str.s
    lda #>s9
    sta.z printf_str.s+1
    jsr printf_str
    // main::@186
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [404] printf_string::str#24 = main::file1#0 -- pbuz1=pbum2 
    lda file1
    sta.z printf_string.str
    lda file1+1
    sta.z printf_string.str+1
    // [405] call printf_string
    // [1227] phi from main::@186 to printf_string [phi:main::@186->printf_string]
    // [1227] phi printf_string::putc#25 = &snputc [phi:main::@186->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1227] phi printf_string::str#25 = printf_string::str#24 [phi:main::@186->printf_string#1] -- register_copy 
    // [1227] phi printf_string::format_justify_left#25 = 0 [phi:main::@186->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1227] phi printf_string::format_min_length#25 = 0 [phi:main::@186->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [406] phi from main::@186 to main::@187 [phi:main::@186->main::@187]
    // main::@187
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [407] call printf_str
    // [1054] phi from main::@187 to printf_str [phi:main::@187->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:main::@187->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = main::s10 [phi:main::@187->printf_str#1] -- pbuz1=pbuc1 
    lda #<s10
    sta.z printf_str.s
    lda #>s10
    sta.z printf_str.s+1
    jsr printf_str
    // main::@188
    // sprintf(info_text, "Reading %s ... (.) data ( ) empty", file)
    // [408] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [409] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_progress(info_text)
    // [411] call display_action_progress
    // [1084] phi from main::@188 to display_action_progress [phi:main::@188->display_action_progress]
    // [1084] phi display_action_progress::info_text#20 = info_text [phi:main::@188->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_progress.info_text
    lda #>@info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@189
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_READING, rom_bank, rom_sizes[rom_chip])
    // [412] main::$305 = main::rom_chip3#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip3
    asl
    asl
    sta main__305
    // [413] rom_read::rom_chip#1 = main::rom_chip3#10 -- vbuz1=vbum2 
    lda rom_chip3
    sta.z rom_read.rom_chip
    // [414] rom_read::file#1 = main::file1#0 -- pbuz1=pbum2 
    lda file1
    sta.z rom_read.file
    lda file1+1
    sta.z rom_read.file+1
    // [415] rom_read::brom_bank_start#2 = main::rom_bank1#0 -- vbuz1=vbum2 
    lda rom_bank1
    sta.z rom_read.brom_bank_start
    // [416] rom_read::rom_size#1 = rom_sizes[main::$305] -- vduz1=pduc1_derefidx_vbum2 
    ldy main__305
    lda rom_sizes,y
    sta.z rom_read.rom_size
    lda rom_sizes+1,y
    sta.z rom_read.rom_size+1
    lda rom_sizes+2,y
    sta.z rom_read.rom_size+2
    lda rom_sizes+3,y
    sta.z rom_read.rom_size+3
    // [417] call rom_read
    // [1252] phi from main::@189 to rom_read [phi:main::@189->rom_read]
    // [1252] phi rom_read::rom_chip#20 = rom_read::rom_chip#1 [phi:main::@189->rom_read#0] -- register_copy 
    // [1252] phi rom_read::rom_size#12 = rom_read::rom_size#1 [phi:main::@189->rom_read#1] -- register_copy 
    // [1252] phi __errno#114 = __errno#102 [phi:main::@189->rom_read#2] -- register_copy 
    // [1252] phi __stdio_filecount#108 = __stdio_filecount#116 [phi:main::@189->rom_read#3] -- register_copy 
    // [1252] phi rom_read::file#10 = rom_read::file#1 [phi:main::@189->rom_read#4] -- register_copy 
    // [1252] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#2 [phi:main::@189->rom_read#5] -- register_copy 
    // [1252] phi rom_read::info_status#11 = STATUS_READING [phi:main::@189->rom_read#6] -- vbuz1=vbuc1 
    lda #STATUS_READING
    sta.z rom_read.info_status
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_READING, rom_bank, rom_sizes[rom_chip])
    // [418] rom_read::return#3 = rom_read::return#0
    // main::@190
    // [419] main::rom_bytes_read1#0 = rom_read::return#3
    // if(rom_bytes_read)
    // [420] if(0==main::rom_bytes_read1#0) goto main::@44 -- 0_eq_vdum1_then_la1 
    lda rom_bytes_read1
    ora rom_bytes_read1+1
    ora rom_bytes_read1+2
    ora rom_bytes_read1+3
    bne !__b44+
    jmp __b44
  !__b44:
    // [421] phi from main::@190 to main::@47 [phi:main::@190->main::@47]
    // main::@47
    // display_action_progress("Comparing ... (.) data, (=) same, (*) different.")
    // [422] call display_action_progress
  // Now we compare the RAM with the actual ROM contents.
    // [1084] phi from main::@47 to display_action_progress [phi:main::@47->display_action_progress]
    // [1084] phi display_action_progress::info_text#20 = main::info_text37 [phi:main::@47->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text37
    sta.z display_action_progress.info_text
    lda #>info_text37
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@191
    // display_info_rom(rom_chip, STATUS_COMPARING, "")
    // [423] display_info_rom::rom_chip#11 = main::rom_chip3#10 -- vbum1=vbum2 
    lda rom_chip3
    sta display_info_rom.rom_chip
    // [424] call display_info_rom
    // [1176] phi from main::@191 to display_info_rom [phi:main::@191->display_info_rom]
    // [1176] phi display_info_rom::info_text#16 = info_text8 [phi:main::@191->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z display_info_rom.info_text
    lda #>info_text8
    sta.z display_info_rom.info_text+1
    // [1176] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#11 [phi:main::@191->display_info_rom#1] -- register_copy 
    // [1176] phi display_info_rom::info_status#16 = STATUS_COMPARING [phi:main::@191->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_COMPARING
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // main::@192
    // unsigned long rom_differences = rom_verify(
    //                             rom_chip, rom_bank, file_sizes[rom_chip])
    // [425] rom_verify::rom_chip#0 = main::rom_chip3#10 -- vbum1=vbum2 
    lda rom_chip3
    sta rom_verify.rom_chip
    // [426] rom_verify::rom_bank_start#0 = main::rom_bank1#0 -- vbum1=vbum2 
    lda rom_bank1
    sta rom_verify.rom_bank_start
    // [427] rom_verify::file_size#0 = file_sizes[main::$305] -- vdum1=pduc1_derefidx_vbum2 
    ldy main__305
    lda file_sizes,y
    sta rom_verify.file_size
    lda file_sizes+1,y
    sta rom_verify.file_size+1
    lda file_sizes+2,y
    sta rom_verify.file_size+2
    lda file_sizes+3,y
    sta rom_verify.file_size+3
    // [428] call rom_verify
  // Verify the ROM...
    // [1332] phi from main::@192 to rom_verify [phi:main::@192->rom_verify]
    jsr rom_verify
    // unsigned long rom_differences = rom_verify(
    //                             rom_chip, rom_bank, file_sizes[rom_chip])
    // [429] rom_verify::return#2 = rom_verify::rom_different_bytes#11
    // main::@193
    // [430] main::rom_differences#0 = rom_verify::return#2 -- vduz1=vduz2 
    lda.z rom_verify.return
    sta.z rom_differences
    lda.z rom_verify.return+1
    sta.z rom_differences+1
    lda.z rom_verify.return+2
    sta.z rom_differences+2
    lda.z rom_verify.return+3
    sta.z rom_differences+3
    // if (!rom_differences)
    // [431] if(0==main::rom_differences#0) goto main::@45 -- 0_eq_vduz1_then_la1 
    lda.z rom_differences
    ora.z rom_differences+1
    ora.z rom_differences+2
    ora.z rom_differences+3
    bne !__b45+
    jmp __b45
  !__b45:
    // [432] phi from main::@193 to main::@48 [phi:main::@193->main::@48]
    // main::@48
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [433] call snprintf_init
    // [1113] phi from main::@48 to snprintf_init [phi:main::@48->snprintf_init]
    // [1113] phi snprintf_init::s#25 = info_text [phi:main::@48->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main::@194
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [434] printf_ulong::uvalue#8 = main::rom_differences#0 -- vdum1=vduz2 
    lda.z rom_differences
    sta printf_ulong.uvalue
    lda.z rom_differences+1
    sta printf_ulong.uvalue+1
    lda.z rom_differences+2
    sta printf_ulong.uvalue+2
    lda.z rom_differences+3
    sta printf_ulong.uvalue+3
    // [435] call printf_ulong
    // [1396] phi from main::@194 to printf_ulong [phi:main::@194->printf_ulong]
    // [1396] phi printf_ulong::format_zero_padding#10 = 1 [phi:main::@194->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1396] phi printf_ulong::format_min_length#10 = 5 [phi:main::@194->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1396] phi printf_ulong::format_radix#10 = HEXADECIMAL [phi:main::@194->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1396] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#8 [phi:main::@194->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [436] phi from main::@194 to main::@195 [phi:main::@194->main::@195]
    // main::@195
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [437] call printf_str
    // [1054] phi from main::@195 to printf_str [phi:main::@195->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:main::@195->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = main::s11 [phi:main::@195->printf_str#1] -- pbuz1=pbuc1 
    lda #<s11
    sta.z printf_str.s
    lda #>s11
    sta.z printf_str.s+1
    jsr printf_str
    // main::@196
    // sprintf(info_text, "%05x differences!", rom_differences)
    // [438] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [439] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASH, info_text)
    // [441] display_info_rom::rom_chip#13 = main::rom_chip3#10 -- vbum1=vbum2 
    lda rom_chip3
    sta display_info_rom.rom_chip
    // [442] call display_info_rom
    // [1176] phi from main::@196 to display_info_rom [phi:main::@196->display_info_rom]
    // [1176] phi display_info_rom::info_text#16 = info_text [phi:main::@196->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1176] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#13 [phi:main::@196->display_info_rom#1] -- register_copy 
    // [1176] phi display_info_rom::info_status#16 = STATUS_FLASH [phi:main::@196->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASH
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // main::@197
    // unsigned long rom_flash_errors = rom_flash(
    //                                 rom_chip, rom_bank, file_sizes[rom_chip])
    // [443] rom_flash::rom_chip#0 = main::rom_chip3#10 -- vbum1=vbum2 
    lda rom_chip3
    sta rom_flash.rom_chip
    // [444] rom_flash::rom_bank_start#0 = main::rom_bank1#0 -- vbum1=vbum2 
    lda rom_bank1
    sta rom_flash.rom_bank_start
    // [445] rom_flash::file_size#0 = file_sizes[main::$305] -- vdum1=pduc1_derefidx_vbum2 
    ldy main__305
    lda file_sizes,y
    sta rom_flash.file_size
    lda file_sizes+1,y
    sta rom_flash.file_size+1
    lda file_sizes+2,y
    sta rom_flash.file_size+2
    lda file_sizes+3,y
    sta rom_flash.file_size+3
    // [446] call rom_flash
    // [1406] phi from main::@197 to rom_flash [phi:main::@197->rom_flash]
    jsr rom_flash
    // unsigned long rom_flash_errors = rom_flash(
    //                                 rom_chip, rom_bank, file_sizes[rom_chip])
    // [447] rom_flash::return#2 = rom_flash::flash_errors#12
    // main::@198
    // [448] main::rom_flash_errors#0 = rom_flash::return#2 -- vdum1=vduz2 
    lda.z rom_flash.return
    sta rom_flash_errors
    lda.z rom_flash.return+1
    sta rom_flash_errors+1
    lda.z rom_flash.return+2
    sta rom_flash_errors+2
    lda.z rom_flash.return+3
    sta rom_flash_errors+3
    // if(rom_flash_errors)
    // [449] if(0!=main::rom_flash_errors#0) goto main::@46 -- 0_neq_vdum1_then_la1 
    lda rom_flash_errors
    ora rom_flash_errors+1
    ora rom_flash_errors+2
    ora rom_flash_errors+3
    bne __b46
    // main::@49
    // display_info_rom(rom_chip, STATUS_FLASHED, NULL)
    // [450] display_info_rom::rom_chip#15 = main::rom_chip3#10 -- vbum1=vbum2 
    lda rom_chip3
    sta display_info_rom.rom_chip
    // [451] call display_info_rom
  // RFL3 | Flash ROM and all ok
    // [1176] phi from main::@49 to display_info_rom [phi:main::@49->display_info_rom]
    // [1176] phi display_info_rom::info_text#16 = 0 [phi:main::@49->display_info_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_rom.info_text
    sta.z display_info_rom.info_text+1
    // [1176] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#15 [phi:main::@49->display_info_rom#1] -- register_copy 
    // [1176] phi display_info_rom::info_status#16 = STATUS_FLASHED [phi:main::@49->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHED
    sta.z display_info_rom.info_status
    jsr display_info_rom
    jmp __b44
    // [452] phi from main::@198 to main::@46 [phi:main::@198->main::@46]
    // main::@46
  __b46:
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [453] call snprintf_init
    // [1113] phi from main::@46 to snprintf_init [phi:main::@46->snprintf_init]
    // [1113] phi snprintf_init::s#25 = info_text [phi:main::@46->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main::@199
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [454] printf_ulong::uvalue#9 = main::rom_flash_errors#0 -- vdum1=vdum2 
    lda rom_flash_errors
    sta printf_ulong.uvalue
    lda rom_flash_errors+1
    sta printf_ulong.uvalue+1
    lda rom_flash_errors+2
    sta printf_ulong.uvalue+2
    lda rom_flash_errors+3
    sta printf_ulong.uvalue+3
    // [455] call printf_ulong
    // [1396] phi from main::@199 to printf_ulong [phi:main::@199->printf_ulong]
    // [1396] phi printf_ulong::format_zero_padding#10 = 0 [phi:main::@199->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1396] phi printf_ulong::format_min_length#10 = 0 [phi:main::@199->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1396] phi printf_ulong::format_radix#10 = DECIMAL [phi:main::@199->printf_ulong#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1396] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#9 [phi:main::@199->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [456] phi from main::@199 to main::@200 [phi:main::@199->main::@200]
    // main::@200
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [457] call printf_str
    // [1054] phi from main::@200 to printf_str [phi:main::@200->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:main::@200->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = main::s12 [phi:main::@200->printf_str#1] -- pbuz1=pbuc1 
    lda #<s12
    sta.z printf_str.s
    lda #>s12
    sta.z printf_str.s+1
    jsr printf_str
    // main::@201
    // sprintf(info_text, "%u flash errors!", rom_flash_errors)
    // [458] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [459] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_ERROR, info_text)
    // [461] display_info_rom::rom_chip#14 = main::rom_chip3#10 -- vbum1=vbum2 
    lda rom_chip3
    sta display_info_rom.rom_chip
    // [462] call display_info_rom
    // [1176] phi from main::@201 to display_info_rom [phi:main::@201->display_info_rom]
    // [1176] phi display_info_rom::info_text#16 = info_text [phi:main::@201->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1176] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#14 [phi:main::@201->display_info_rom#1] -- register_copy 
    // [1176] phi display_info_rom::info_status#16 = STATUS_ERROR [phi:main::@201->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_ERROR
    sta.z display_info_rom.info_status
    jsr display_info_rom
    jmp __b44
    // main::@45
  __b45:
    // display_info_rom(rom_chip, STATUS_SKIP, "No update required")
    // [463] display_info_rom::rom_chip#12 = main::rom_chip3#10 -- vbum1=vbum2 
    lda rom_chip3
    sta display_info_rom.rom_chip
    // [464] call display_info_rom
  // RFL1 | ROM and ROM.BIN equal | Display that there are no differences between the ROM and ROM.BIN. Set ROM to Flashed. | None
    // [1176] phi from main::@45 to display_info_rom [phi:main::@45->display_info_rom]
    // [1176] phi display_info_rom::info_text#16 = main::info_text39 [phi:main::@45->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text39
    sta.z display_info_rom.info_text
    lda #>info_text39
    sta.z display_info_rom.info_text+1
    // [1176] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#12 [phi:main::@45->display_info_rom#1] -- register_copy 
    // [1176] phi display_info_rom::info_status#16 = STATUS_SKIP [phi:main::@45->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_rom.info_status
    jsr display_info_rom
    jmp __b44
    // main::@257
  __b257:
    // if((rom_chip == 0 && (check_status_smc(STATUS_FLASHED) || check_status_smc(STATUS_SKIP))) || (rom_chip != 0))
    // [465] if(0!=main::check_status_smc12_return#0) goto main::bank_set_brom5 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc12_return
    beq !bank_set_brom5+
    jmp bank_set_brom5
  !bank_set_brom5:
    // main::@265
    // [466] if(0!=main::check_status_smc13_return#0) goto main::bank_set_brom5 -- 0_neq_vbuz1_then_la1 
    lda.z check_status_smc13_return
    beq !bank_set_brom5+
    jmp bank_set_brom5
  !bank_set_brom5:
    jmp __b256
    // [467] phi from main::@255 to main::@51 [phi:main::@255->main::@51]
    // main::@51
  __b51:
    // display_action_progress("Reading SMC.BIN ... (.) data, ( ) empty")
    // [468] call display_action_progress
    // [1084] phi from main::@51 to display_action_progress [phi:main::@51->display_action_progress]
    // [1084] phi display_action_progress::info_text#20 = main::info_text30 [phi:main::@51->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text30
    sta.z display_action_progress.info_text
    lda #>info_text30
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [469] phi from main::@51 to main::@177 [phi:main::@51->main::@177]
    // main::@177
    // display_progress_clear()
    // [470] call display_progress_clear
    // [1161] phi from main::@177 to display_progress_clear [phi:main::@177->display_progress_clear]
    jsr display_progress_clear
    // [471] phi from main::@177 to main::@178 [phi:main::@177->main::@178]
    // main::@178
    // smc_read(STATUS_READING)
    // [472] call smc_read
    // [1505] phi from main::@178 to smc_read [phi:main::@178->smc_read]
    // [1505] phi __errno#109 = __errno#100 [phi:main::@178->smc_read#0] -- register_copy 
    // [1505] phi __stdio_filecount#104 = __stdio_filecount#114 [phi:main::@178->smc_read#1] -- register_copy 
    // [1505] phi smc_read::info_status#10 = STATUS_READING [phi:main::@178->smc_read#2] -- vbuz1=vbuc1 
    lda #STATUS_READING
    sta.z smc_read.info_status
    jsr smc_read
    // smc_read(STATUS_READING)
    // [473] smc_read::return#3 = smc_read::return#0
    // main::@179
    // smc_file_size = smc_read(STATUS_READING)
    // [474] smc_file_size#1 = smc_read::return#3 -- vwum1=vwuz2 
    lda.z smc_read.return
    sta smc_file_size_1
    lda.z smc_read.return+1
    sta smc_file_size_1+1
    // if(smc_file_size)
    // [475] if(0==smc_file_size#1) goto main::SEI3 -- 0_eq_vwum1_then_la1 
    lda smc_file_size_1
    ora smc_file_size_1+1
    bne !SEI3+
    jmp SEI3
  !SEI3:
    // [476] phi from main::@179 to main::@52 [phi:main::@179->main::@52]
    // main::@52
    // display_action_text("Press both POWER/RESET buttons on the CX16 board!")
    // [477] call display_action_text
  // Flash the SMC chip.
    // [1129] phi from main::@52 to display_action_text [phi:main::@52->display_action_text]
    // [1129] phi display_action_text::info_text#17 = main::info_text31 [phi:main::@52->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text31
    sta.z display_action_text.info_text
    lda #>info_text31
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // main::@180
    // [478] smc_bootloader#467 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_FLASHING, "Press POWER/RESET!")
    // [479] call display_info_smc
    // [898] phi from main::@180 to display_info_smc [phi:main::@180->display_info_smc]
    // [898] phi display_info_smc::info_text#21 = main::info_text32 [phi:main::@180->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text32
    sta.z display_info_smc.info_text
    lda #>info_text32
    sta.z display_info_smc.info_text+1
    // [898] phi smc_bootloader#14 = smc_bootloader#467 [phi:main::@180->display_info_smc#1] -- register_copy 
    // [898] phi display_info_smc::info_status#21 = STATUS_FLASHING [phi:main::@180->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHING
    sta display_info_smc.info_status
    jsr display_info_smc
    // main::@181
    // unsigned int flashed_bytes = smc_flash(smc_file_size)
    // [480] smc_flash::smc_bytes_total#0 = smc_file_size#1 -- vwum1=vwum2 
    lda smc_file_size_1
    sta smc_flash.smc_bytes_total
    lda smc_file_size_1+1
    sta smc_flash.smc_bytes_total+1
    // [481] call smc_flash
    // [1555] phi from main::@181 to smc_flash [phi:main::@181->smc_flash]
    jsr smc_flash
    // unsigned int flashed_bytes = smc_flash(smc_file_size)
    // [482] smc_flash::return#5 = smc_flash::return#1
    // main::@182
    // [483] main::flashed_bytes#0 = smc_flash::return#5
    // if(flashed_bytes)
    // [484] if(0!=main::flashed_bytes#0) goto main::@40 -- 0_neq_vwum1_then_la1 
    lda flashed_bytes
    ora flashed_bytes+1
    bne __b40
    // main::@53
    // if(flashed_bytes == (unsigned int)0xFFFF)
    // [485] if(main::flashed_bytes#0==$ffff) goto main::@41 -- vwum1_eq_vwuc1_then_la1 
    lda flashed_bytes
    cmp #<$ffff
    bne !+
    lda flashed_bytes+1
    cmp #>$ffff
    beq __b41
  !:
    // main::@54
    // [486] smc_bootloader#474 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ISSUE, "POWER/RESET not pressed!")
    // [487] call display_info_smc
  // SFL2 | no action on POWER/RESET press request
    // [898] phi from main::@54 to display_info_smc [phi:main::@54->display_info_smc]
    // [898] phi display_info_smc::info_text#21 = main::info_text35 [phi:main::@54->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text35
    sta.z display_info_smc.info_text
    lda #>info_text35
    sta.z display_info_smc.info_text+1
    // [898] phi smc_bootloader#14 = smc_bootloader#474 [phi:main::@54->display_info_smc#1] -- register_copy 
    // [898] phi display_info_smc::info_status#21 = STATUS_ISSUE [phi:main::@54->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_smc.info_status
    jsr display_info_smc
    jmp SEI3
    // main::@41
  __b41:
    // [488] smc_bootloader#473 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ERROR, "SMC has errors!")
    // [489] call display_info_smc
  // SFL3 | errors during flash
    // [898] phi from main::@41 to display_info_smc [phi:main::@41->display_info_smc]
    // [898] phi display_info_smc::info_text#21 = main::info_text34 [phi:main::@41->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text34
    sta.z display_info_smc.info_text
    lda #>info_text34
    sta.z display_info_smc.info_text+1
    // [898] phi smc_bootloader#14 = smc_bootloader#473 [phi:main::@41->display_info_smc#1] -- register_copy 
    // [898] phi display_info_smc::info_status#21 = STATUS_ERROR [phi:main::@41->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_smc.info_status
    jsr display_info_smc
    jmp SEI3
    // main::@40
  __b40:
    // [490] smc_bootloader#472 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_FLASHED, "")
    // [491] call display_info_smc
  // SFL1 | and POWER/RESET pressed
    // [898] phi from main::@40 to display_info_smc [phi:main::@40->display_info_smc]
    // [898] phi display_info_smc::info_text#21 = info_text8 [phi:main::@40->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z display_info_smc.info_text
    lda #>info_text8
    sta.z display_info_smc.info_text+1
    // [898] phi smc_bootloader#14 = smc_bootloader#472 [phi:main::@40->display_info_smc#1] -- register_copy 
    // [898] phi display_info_smc::info_status#21 = STATUS_FLASHED [phi:main::@40->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_FLASHED
    sta display_info_smc.info_status
    jsr display_info_smc
    jmp SEI3
    // [492] phi from main::@171 main::@252 main::@253 main::@254 to main::@14 [phi:main::@171/main::@252/main::@253/main::@254->main::@14]
    // main::@14
  __b14:
    // display_action_progress("Chipsets have been detected and update files validated!")
    // [493] call display_action_progress
    // [1084] phi from main::@14 to display_action_progress [phi:main::@14->display_action_progress]
    // [1084] phi display_action_progress::info_text#20 = main::info_text24 [phi:main::@14->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text24
    sta.z display_action_progress.info_text
    lda #>info_text24
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [494] phi from main::@14 to main::@172 [phi:main::@14->main::@172]
    // main::@172
    // unsigned char ch = util_wait_key("Continue with update of highlighted chipsets? [Y/N]", "nyNY")
    // [495] call util_wait_key
    // [1704] phi from main::@172 to util_wait_key [phi:main::@172->util_wait_key]
    // [1704] phi util_wait_key::filter#16 = main::filter4 [phi:main::@172->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter4
    sta.z util_wait_key.filter
    lda #>filter4
    sta.z util_wait_key.filter+1
    // [1704] phi util_wait_key::info_text#6 = main::info_text25 [phi:main::@172->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text25
    sta.z util_wait_key.info_text
    lda #>info_text25
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Continue with update of highlighted chipsets? [Y/N]", "nyNY")
    // [496] util_wait_key::return#13 = util_wait_key::ch#4 -- vbum1=vwum2 
    lda util_wait_key.ch
    sta util_wait_key.return_4
    // main::@173
    // [497] main::ch4#0 = util_wait_key::return#13
    // strchr("nN", ch)
    // [498] strchr::c#1 = main::ch4#0 -- vbum1=vbum2 
    lda ch4
    sta strchr.c
    // [499] call strchr
    // [1729] phi from main::@173 to strchr [phi:main::@173->strchr]
    // [1729] phi strchr::c#4 = strchr::c#1 [phi:main::@173->strchr#0] -- register_copy 
    // [1729] phi strchr::str#2 = (const void *)main::$330 [phi:main::@173->strchr#1] -- pvoz1=pvoc1 
    lda #<main__330
    sta.z strchr.str
    lda #>main__330
    sta.z strchr.str+1
    jsr strchr
    // strchr("nN", ch)
    // [500] strchr::return#4 = strchr::return#2
    // main::@174
    // [501] main::$191 = strchr::return#4
    // if(strchr("nN", ch))
    // [502] if((void *)0==main::$191) goto main::check_status_smc11 -- pvoc1_eq_pvoz1_then_la1 
    lda.z main__191
    cmp #<0
    bne !+
    lda.z main__191+1
    cmp #>0
    bne !check_status_smc11+
    jmp check_status_smc11
  !check_status_smc11:
  !:
    // main::@15
    // [503] smc_bootloader#468 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_SKIP, "Cancelled")
    // [504] call display_info_smc
  // We cancel all updates, the updates are skipped.
    // [898] phi from main::@15 to display_info_smc [phi:main::@15->display_info_smc]
    // [898] phi display_info_smc::info_text#21 = main::info_text26 [phi:main::@15->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text26
    sta.z display_info_smc.info_text
    lda #>info_text26
    sta.z display_info_smc.info_text+1
    // [898] phi smc_bootloader#14 = smc_bootloader#468 [phi:main::@15->display_info_smc#1] -- register_copy 
    // [898] phi display_info_smc::info_status#21 = STATUS_SKIP [phi:main::@15->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    // [505] phi from main::@15 to main::@175 [phi:main::@15->main::@175]
    // main::@175
    // display_info_vera(STATUS_SKIP, "Cancelled")
    // [506] call display_info_vera
    // [1738] phi from main::@175 to display_info_vera [phi:main::@175->display_info_vera]
    // [1738] phi display_info_vera::info_text#10 = main::info_text26 [phi:main::@175->display_info_vera#0] -- pbuz1=pbuc1 
    lda #<info_text26
    sta.z display_info_vera.info_text
    lda #>info_text26
    sta.z display_info_vera.info_text+1
    // [1738] phi display_info_vera::info_status#2 = STATUS_SKIP [phi:main::@175->display_info_vera#1] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_vera.info_status
    jsr display_info_vera
    // [507] phi from main::@175 to main::@37 [phi:main::@175->main::@37]
    // [507] phi main::rom_chip2#2 = 0 [phi:main::@175->main::@37#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip2
    // main::@37
  __b37:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [508] if(main::rom_chip2#2<8) goto main::@38 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip2
    cmp #8
    bcc __b38
    // [509] phi from main::@37 to main::@39 [phi:main::@37->main::@39]
    // main::@39
    // display_action_text("You have selected not to cancel the update ... ")
    // [510] call display_action_text
    // [1129] phi from main::@39 to display_action_text [phi:main::@39->display_action_text]
    // [1129] phi display_action_text::info_text#17 = main::info_text29 [phi:main::@39->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text29
    sta.z display_action_text.info_text
    lda #>info_text29
    sta.z display_action_text.info_text+1
    jsr display_action_text
    jmp check_status_smc11
    // main::@38
  __b38:
    // display_info_rom(rom_chip, STATUS_SKIP, "Cancelled")
    // [511] display_info_rom::rom_chip#9 = main::rom_chip2#2 -- vbum1=vbum2 
    lda rom_chip2
    sta display_info_rom.rom_chip
    // [512] call display_info_rom
    // [1176] phi from main::@38 to display_info_rom [phi:main::@38->display_info_rom]
    // [1176] phi display_info_rom::info_text#16 = main::info_text26 [phi:main::@38->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text26
    sta.z display_info_rom.info_text
    lda #>info_text26
    sta.z display_info_rom.info_text+1
    // [1176] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#9 [phi:main::@38->display_info_rom#1] -- register_copy 
    // [1176] phi display_info_rom::info_status#16 = STATUS_SKIP [phi:main::@38->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // main::@176
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [513] main::rom_chip2#1 = ++ main::rom_chip2#2 -- vbum1=_inc_vbum1 
    inc rom_chip2
    // [507] phi from main::@176 to main::@37 [phi:main::@176->main::@37]
    // [507] phi main::rom_chip2#2 = main::rom_chip2#1 [phi:main::@176->main::@37#0] -- register_copy 
    jmp __b37
    // [514] phi from main::@245 to main::@13 [phi:main::@245->main::@13]
    // main::@13
  __b13:
    // display_action_progress("The CX16 main ROM and ROM.BIN versions are equal, no flash required!")
    // [515] call display_action_progress
    // [1084] phi from main::@13 to display_action_progress [phi:main::@13->display_action_progress]
    // [1084] phi display_action_progress::info_text#20 = main::info_text23 [phi:main::@13->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text23
    sta.z display_action_progress.info_text
    lda #>info_text23
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [516] phi from main::@13 to main::@169 [phi:main::@13->main::@169]
    // main::@169
    // util_wait_space()
    // [517] call util_wait_space
    // [1778] phi from main::@169 to util_wait_space [phi:main::@169->util_wait_space]
    jsr util_wait_space
    // [518] phi from main::@169 to main::@170 [phi:main::@169->main::@170]
    // main::@170
    // display_info_cx16_rom(STATUS_SKIP, NULL)
    // [519] call display_info_cx16_rom
    // [1781] phi from main::@170 to display_info_cx16_rom [phi:main::@170->display_info_cx16_rom]
    // [1781] phi display_info_cx16_rom::info_text#8 = 0 [phi:main::@170->display_info_cx16_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_cx16_rom.info_text
    sta.z display_info_cx16_rom.info_text+1
    // [1781] phi display_info_cx16_rom::info_status#8 = STATUS_SKIP [phi:main::@170->display_info_cx16_rom#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    jmp check_status_smc8
    // main::@243
  __b243:
    // if(check_status_smc(STATUS_FLASH) && smc_release == smc_file_release && smc_major == smc_file_major && smc_minor == smc_file_minor)
    // [520] if(smc_major#392!=smc_file_major#316) goto main::check_status_cx16_rom5 -- vbum1_neq_vbum2_then_la1 
    lda smc_major
    cmp smc_file_major
    beq !check_status_cx16_rom5+
    jmp check_status_cx16_rom5
  !check_status_cx16_rom5:
    // main::@242
    // [521] if(smc_minor#391==smc_file_minor#316) goto main::@12 -- vbum1_eq_vbum2_then_la1 
    lda smc_minor
    cmp smc_file_minor
    beq __b12
    jmp check_status_cx16_rom5
    // [522] phi from main::@242 to main::@12 [phi:main::@242->main::@12]
    // main::@12
  __b12:
    // display_action_progress("The SMC chip and SMC.BIN versions are equal, no flash required!")
    // [523] call display_action_progress
    // [1084] phi from main::@12 to display_action_progress [phi:main::@12->display_action_progress]
    // [1084] phi display_action_progress::info_text#20 = main::info_text22 [phi:main::@12->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text22
    sta.z display_action_progress.info_text
    lda #>info_text22
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [524] phi from main::@12 to main::@165 [phi:main::@12->main::@165]
    // main::@165
    // util_wait_space()
    // [525] call util_wait_space
    // [1778] phi from main::@165 to util_wait_space [phi:main::@165->util_wait_space]
    jsr util_wait_space
    // main::@166
    // [526] smc_bootloader#466 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_SKIP, NULL)
    // [527] call display_info_smc
    // [898] phi from main::@166 to display_info_smc [phi:main::@166->display_info_smc]
    // [898] phi display_info_smc::info_text#21 = 0 [phi:main::@166->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [898] phi smc_bootloader#14 = smc_bootloader#466 [phi:main::@166->display_info_smc#1] -- register_copy 
    // [898] phi display_info_smc::info_status#21 = STATUS_SKIP [phi:main::@166->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    jmp check_status_cx16_rom5
    // [528] phi from main::@240 to main::@10 [phi:main::@240->main::@10]
    // main::@10
  __b10:
    // display_action_progress("Compatibility between ROM.BIN and SMC.BIN can't be assured!")
    // [529] call display_action_progress
    // [1084] phi from main::@10 to display_action_progress [phi:main::@10->display_action_progress]
    // [1084] phi display_action_progress::info_text#20 = main::info_text20 [phi:main::@10->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text20
    sta.z display_action_progress.info_text
    lda #>info_text20
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [530] phi from main::@10 to main::@160 [phi:main::@10->main::@160]
    // main::@160
    // display_progress_text(display_smc_unsupported_rom_text, display_smc_unsupported_rom_count)
    // [531] call display_progress_text
    // [1098] phi from main::@160 to display_progress_text [phi:main::@160->display_progress_text]
    // [1098] phi display_progress_text::text#12 = display_smc_unsupported_rom_text [phi:main::@160->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_unsupported_rom_text
    sta.z display_progress_text.text
    lda #>display_smc_unsupported_rom_text
    sta.z display_progress_text.text+1
    // [1098] phi display_progress_text::lines#11 = display_smc_unsupported_rom_count [phi:main::@160->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_smc_unsupported_rom_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [532] phi from main::@160 to main::@161 [phi:main::@160->main::@161]
    // main::@161
    // unsigned char ch = util_wait_key("Proceed with the update? [Y/N]", "YN")
    // [533] call util_wait_key
    // [1704] phi from main::@161 to util_wait_key [phi:main::@161->util_wait_key]
    // [1704] phi util_wait_key::filter#16 = main::filter [phi:main::@161->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter
    sta.z util_wait_key.filter
    lda #>filter
    sta.z util_wait_key.filter+1
    // [1704] phi util_wait_key::info_text#6 = main::info_text7 [phi:main::@161->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z util_wait_key.info_text
    lda #>info_text7
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Proceed with the update? [Y/N]", "YN")
    // [534] util_wait_key::return#12 = util_wait_key::ch#4 -- vbuz1=vwum2 
    lda util_wait_key.ch
    sta.z util_wait_key.return_3
    // main::@162
    // [535] main::ch3#0 = util_wait_key::return#12
    // if(ch == 'N')
    // [536] if(main::ch3#0!='N') goto main::check_status_smc7 -- vbuz1_neq_vbuc1_then_la1 
    lda #'N'
    cmp.z ch3
    beq !check_status_smc7+
    jmp check_status_smc7
  !check_status_smc7:
    // main::@11
    // [537] smc_bootloader#462 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ISSUE, NULL)
    // [538] call display_info_smc
  // Cancel flash
    // [898] phi from main::@11 to display_info_smc [phi:main::@11->display_info_smc]
    // [898] phi display_info_smc::info_text#21 = 0 [phi:main::@11->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [898] phi smc_bootloader#14 = smc_bootloader#462 [phi:main::@11->display_info_smc#1] -- register_copy 
    // [898] phi display_info_smc::info_status#21 = STATUS_ISSUE [phi:main::@11->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_smc.info_status
    jsr display_info_smc
    // [539] phi from main::@11 to main::@163 [phi:main::@11->main::@163]
    // main::@163
    // display_info_cx16_rom(STATUS_ISSUE, NULL)
    // [540] call display_info_cx16_rom
    // [1781] phi from main::@163 to display_info_cx16_rom [phi:main::@163->display_info_cx16_rom]
    // [1781] phi display_info_cx16_rom::info_text#8 = 0 [phi:main::@163->display_info_cx16_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_cx16_rom.info_text
    sta.z display_info_cx16_rom.info_text+1
    // [1781] phi display_info_cx16_rom::info_status#8 = STATUS_ISSUE [phi:main::@163->display_info_cx16_rom#1] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    jmp check_status_smc7
    // [541] phi from main::@239 to main::@7 [phi:main::@239->main::@7]
    // main::@7
  __b7:
    // display_action_progress("Issue with the CX16 main ROM, check the issue ...")
    // [542] call display_action_progress
    // [1084] phi from main::@7 to display_action_progress [phi:main::@7->display_action_progress]
    // [1084] phi display_action_progress::info_text#20 = main::info_text13 [phi:main::@7->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text13
    sta.z display_action_progress.info_text
    lda #>info_text13
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [543] phi from main::@7 to main::@152 [phi:main::@7->main::@152]
    // main::@152
    // display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count)
    // [544] call display_progress_text
    // [1098] phi from main::@152 to display_progress_text [phi:main::@152->display_progress_text]
    // [1098] phi display_progress_text::text#12 = display_smc_rom_issue_text [phi:main::@152->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_rom_issue_text
    sta.z display_progress_text.text
    lda #>display_smc_rom_issue_text
    sta.z display_progress_text.text+1
    // [1098] phi display_progress_text::lines#11 = display_smc_rom_issue_count [phi:main::@152->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_smc_rom_issue_count
    sta display_progress_text.lines
    jsr display_progress_text
    // main::@153
    // [545] smc_bootloader#465 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_SKIP, "Issue with main CX16 ROM!")
    // [546] call display_info_smc
    // [898] phi from main::@153 to display_info_smc [phi:main::@153->display_info_smc]
    // [898] phi display_info_smc::info_text#21 = main::info_text14 [phi:main::@153->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text14
    sta.z display_info_smc.info_text
    lda #>info_text14
    sta.z display_info_smc.info_text+1
    // [898] phi smc_bootloader#14 = smc_bootloader#465 [phi:main::@153->display_info_smc#1] -- register_copy 
    // [898] phi display_info_smc::info_status#21 = STATUS_SKIP [phi:main::@153->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    // [547] phi from main::@153 to main::@154 [phi:main::@153->main::@154]
    // main::@154
    // display_info_cx16_rom(STATUS_ISSUE, NULL)
    // [548] call display_info_cx16_rom
    // [1781] phi from main::@154 to display_info_cx16_rom [phi:main::@154->display_info_cx16_rom]
    // [1781] phi display_info_cx16_rom::info_text#8 = 0 [phi:main::@154->display_info_cx16_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_cx16_rom.info_text
    sta.z display_info_cx16_rom.info_text+1
    // [1781] phi display_info_cx16_rom::info_status#8 = STATUS_ISSUE [phi:main::@154->display_info_cx16_rom#1] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    // [549] phi from main::@154 to main::@155 [phi:main::@154->main::@155]
    // main::@155
    // unsigned char ch = util_wait_key("Proceed with the update? [Y/N]", "YN")
    // [550] call util_wait_key
    // [1704] phi from main::@155 to util_wait_key [phi:main::@155->util_wait_key]
    // [1704] phi util_wait_key::filter#16 = main::filter [phi:main::@155->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter
    sta.z util_wait_key.filter
    lda #>filter
    sta.z util_wait_key.filter+1
    // [1704] phi util_wait_key::info_text#6 = main::info_text7 [phi:main::@155->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z util_wait_key.info_text
    lda #>info_text7
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Proceed with the update? [Y/N]", "YN")
    // [551] util_wait_key::return#11 = util_wait_key::ch#4 -- vbuz1=vwum2 
    lda util_wait_key.ch
    sta.z util_wait_key.return_2
    // main::@156
    // [552] main::ch1#0 = util_wait_key::return#11
    // if(ch == 'Y')
    // [553] if(main::ch1#0!='Y') goto main::check_status_smc6 -- vbuz1_neq_vbuc1_then_la1 
    lda #'Y'
    cmp.z ch1
    beq !check_status_smc6+
    jmp check_status_smc6
  !check_status_smc6:
    // main::@8
    // [554] smc_bootloader#458 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_FLASH, "")
    // [555] call display_info_smc
    // [898] phi from main::@8 to display_info_smc [phi:main::@8->display_info_smc]
    // [898] phi display_info_smc::info_text#21 = info_text8 [phi:main::@8->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z display_info_smc.info_text
    lda #>info_text8
    sta.z display_info_smc.info_text+1
    // [898] phi smc_bootloader#14 = smc_bootloader#458 [phi:main::@8->display_info_smc#1] -- register_copy 
    // [898] phi display_info_smc::info_status#21 = STATUS_FLASH [phi:main::@8->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_smc.info_status
    jsr display_info_smc
    // [556] phi from main::@8 to main::@157 [phi:main::@8->main::@157]
    // main::@157
    // display_info_cx16_rom(STATUS_SKIP, "")
    // [557] call display_info_cx16_rom
    // [1781] phi from main::@157 to display_info_cx16_rom [phi:main::@157->display_info_cx16_rom]
    // [1781] phi display_info_cx16_rom::info_text#8 = info_text8 [phi:main::@157->display_info_cx16_rom#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z display_info_cx16_rom.info_text
    lda #>info_text8
    sta.z display_info_cx16_rom.info_text+1
    // [1781] phi display_info_cx16_rom::info_status#8 = STATUS_SKIP [phi:main::@157->display_info_cx16_rom#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    jmp check_status_smc6
    // [558] phi from main::@238 to main::@2 [phi:main::@238->main::@2]
    // main::@2
  __b2:
    // display_action_progress("Issue with the CX16 main ROM: not detected ...")
    // [559] call display_action_progress
    // [1084] phi from main::@2 to display_action_progress [phi:main::@2->display_action_progress]
    // [1084] phi display_action_progress::info_text#20 = main::info_text9 [phi:main::@2->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text9
    sta.z display_action_progress.info_text
    lda #>info_text9
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [560] phi from main::@2 to main::@147 [phi:main::@2->main::@147]
    // main::@147
    // display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count)
    // [561] call display_progress_text
    // [1098] phi from main::@147 to display_progress_text [phi:main::@147->display_progress_text]
    // [1098] phi display_progress_text::text#12 = display_smc_rom_issue_text [phi:main::@147->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_rom_issue_text
    sta.z display_progress_text.text
    lda #>display_smc_rom_issue_text
    sta.z display_progress_text.text+1
    // [1098] phi display_progress_text::lines#11 = display_smc_rom_issue_count [phi:main::@147->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_smc_rom_issue_count
    sta display_progress_text.lines
    jsr display_progress_text
    // main::@148
    // [562] smc_bootloader#464 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_SKIP, "Issue with CX16 main ROM!")
    // [563] call display_info_smc
    // [898] phi from main::@148 to display_info_smc [phi:main::@148->display_info_smc]
    // [898] phi display_info_smc::info_text#21 = main::info_text10 [phi:main::@148->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text10
    sta.z display_info_smc.info_text
    lda #>info_text10
    sta.z display_info_smc.info_text+1
    // [898] phi smc_bootloader#14 = smc_bootloader#464 [phi:main::@148->display_info_smc#1] -- register_copy 
    // [898] phi display_info_smc::info_status#21 = STATUS_SKIP [phi:main::@148->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    // [564] phi from main::@148 to main::@149 [phi:main::@148->main::@149]
    // main::@149
    // display_info_cx16_rom(STATUS_ISSUE, "Are J1 jumper pins closed?")
    // [565] call display_info_cx16_rom
    // [1781] phi from main::@149 to display_info_cx16_rom [phi:main::@149->display_info_cx16_rom]
    // [1781] phi display_info_cx16_rom::info_text#8 = main::info_text11 [phi:main::@149->display_info_cx16_rom#0] -- pbuz1=pbuc1 
    lda #<info_text11
    sta.z display_info_cx16_rom.info_text
    lda #>info_text11
    sta.z display_info_cx16_rom.info_text+1
    // [1781] phi display_info_cx16_rom::info_status#8 = STATUS_ISSUE [phi:main::@149->display_info_cx16_rom#1] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    // [566] phi from main::@149 to main::@150 [phi:main::@149->main::@150]
    // main::@150
    // unsigned char ch = util_wait_key("Proceed with the update? [Y/N]", "YN")
    // [567] call util_wait_key
    // [1704] phi from main::@150 to util_wait_key [phi:main::@150->util_wait_key]
    // [1704] phi util_wait_key::filter#16 = main::filter [phi:main::@150->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter
    sta.z util_wait_key.filter
    lda #>filter
    sta.z util_wait_key.filter+1
    // [1704] phi util_wait_key::info_text#6 = main::info_text7 [phi:main::@150->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z util_wait_key.info_text
    lda #>info_text7
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Proceed with the update? [Y/N]", "YN")
    // [568] util_wait_key::return#10 = util_wait_key::ch#4 -- vbuz1=vwum2 
    lda util_wait_key.ch
    sta.z util_wait_key.return_1
    // main::@151
    // [569] main::ch2#0 = util_wait_key::return#10
    // if(ch == 'Y')
    // [570] if(main::ch2#0!='Y') goto main::check_status_smc6 -- vbuz1_neq_vbuc1_then_la1 
    lda #'Y'
    cmp.z ch2
    beq !check_status_smc6+
    jmp check_status_smc6
  !check_status_smc6:
    // main::@9
    // [571] smc_bootloader#460 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_FLASH, "")
    // [572] call display_info_smc
    // [898] phi from main::@9 to display_info_smc [phi:main::@9->display_info_smc]
    // [898] phi display_info_smc::info_text#21 = info_text8 [phi:main::@9->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z display_info_smc.info_text
    lda #>info_text8
    sta.z display_info_smc.info_text+1
    // [898] phi smc_bootloader#14 = smc_bootloader#460 [phi:main::@9->display_info_smc#1] -- register_copy 
    // [898] phi display_info_smc::info_status#21 = STATUS_FLASH [phi:main::@9->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_smc.info_status
    jsr display_info_smc
    // [573] phi from main::@9 to main::@159 [phi:main::@9->main::@159]
    // main::@159
    // display_info_cx16_rom(STATUS_SKIP, "")
    // [574] call display_info_cx16_rom
    // [1781] phi from main::@159 to display_info_cx16_rom [phi:main::@159->display_info_cx16_rom]
    // [1781] phi display_info_cx16_rom::info_text#8 = info_text8 [phi:main::@159->display_info_cx16_rom#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z display_info_cx16_rom.info_text
    lda #>info_text8
    sta.z display_info_cx16_rom.info_text+1
    // [1781] phi display_info_cx16_rom::info_status#8 = STATUS_SKIP [phi:main::@159->display_info_cx16_rom#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    jmp check_status_smc6
    // [575] phi from main::@237 to main::@35 [phi:main::@237->main::@35]
    // main::@35
  __b35:
    // display_action_progress("Issue with the CX16 SMC, check the issue ...")
    // [576] call display_action_progress
    // [1084] phi from main::@35 to display_action_progress [phi:main::@35->display_action_progress]
    // [1084] phi display_action_progress::info_text#20 = main::info_text5 [phi:main::@35->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text5
    sta.z display_action_progress.info_text
    lda #>info_text5
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [577] phi from main::@35 to main::@141 [phi:main::@35->main::@141]
    // main::@141
    // display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count)
    // [578] call display_progress_text
    // [1098] phi from main::@141 to display_progress_text [phi:main::@141->display_progress_text]
    // [1098] phi display_progress_text::text#12 = display_smc_rom_issue_text [phi:main::@141->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_smc_rom_issue_text
    sta.z display_progress_text.text
    lda #>display_smc_rom_issue_text
    sta.z display_progress_text.text+1
    // [1098] phi display_progress_text::lines#11 = display_smc_rom_issue_count [phi:main::@141->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_smc_rom_issue_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [579] phi from main::@141 to main::@142 [phi:main::@141->main::@142]
    // main::@142
    // display_info_cx16_rom(STATUS_SKIP, "Issue with SMC!")
    // [580] call display_info_cx16_rom
    // [1781] phi from main::@142 to display_info_cx16_rom [phi:main::@142->display_info_cx16_rom]
    // [1781] phi display_info_cx16_rom::info_text#8 = main::info_text6 [phi:main::@142->display_info_cx16_rom#0] -- pbuz1=pbuc1 
    lda #<info_text6
    sta.z display_info_cx16_rom.info_text
    lda #>info_text6
    sta.z display_info_cx16_rom.info_text+1
    // [1781] phi display_info_cx16_rom::info_status#8 = STATUS_SKIP [phi:main::@142->display_info_cx16_rom#1] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    // main::@143
    // [581] smc_bootloader#461 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ISSUE, NULL)
    // [582] call display_info_smc
    // [898] phi from main::@143 to display_info_smc [phi:main::@143->display_info_smc]
    // [898] phi display_info_smc::info_text#21 = 0 [phi:main::@143->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [898] phi smc_bootloader#14 = smc_bootloader#461 [phi:main::@143->display_info_smc#1] -- register_copy 
    // [898] phi display_info_smc::info_status#21 = STATUS_ISSUE [phi:main::@143->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_smc.info_status
    jsr display_info_smc
    // [583] phi from main::@143 to main::@144 [phi:main::@143->main::@144]
    // main::@144
    // unsigned char ch = util_wait_key("Proceed with the update? [Y/N]", "YN")
    // [584] call util_wait_key
    // [1704] phi from main::@144 to util_wait_key [phi:main::@144->util_wait_key]
    // [1704] phi util_wait_key::filter#16 = main::filter [phi:main::@144->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<filter
    sta.z util_wait_key.filter
    lda #>filter
    sta.z util_wait_key.filter+1
    // [1704] phi util_wait_key::info_text#6 = main::info_text7 [phi:main::@144->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text7
    sta.z util_wait_key.info_text
    lda #>info_text7
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // unsigned char ch = util_wait_key("Proceed with the update? [Y/N]", "YN")
    // [585] util_wait_key::return#3 = util_wait_key::ch#4 -- vbuz1=vwum2 
    lda util_wait_key.ch
    sta.z util_wait_key.return
    // main::@145
    // [586] main::ch#0 = util_wait_key::return#3
    // if(ch == 'Y')
    // [587] if(main::ch#0!='Y') goto main::check_status_smc4 -- vbuz1_neq_vbuc1_then_la1 
    lda #'Y'
    cmp.z ch
    beq !check_status_smc4+
    jmp check_status_smc4
  !check_status_smc4:
    // [588] phi from main::@145 to main::@36 [phi:main::@145->main::@36]
    // main::@36
    // display_info_cx16_rom(STATUS_FLASH, "")
    // [589] call display_info_cx16_rom
    // [1781] phi from main::@36 to display_info_cx16_rom [phi:main::@36->display_info_cx16_rom]
    // [1781] phi display_info_cx16_rom::info_text#8 = info_text8 [phi:main::@36->display_info_cx16_rom#0] -- pbuz1=pbuc1 
    lda #<info_text8
    sta.z display_info_cx16_rom.info_text
    lda #>info_text8
    sta.z display_info_cx16_rom.info_text+1
    // [1781] phi display_info_cx16_rom::info_status#8 = STATUS_FLASH [phi:main::@36->display_info_cx16_rom#1] -- vbuz1=vbuc1 
    lda #STATUS_FLASH
    sta.z display_info_cx16_rom.info_status
    jsr display_info_cx16_rom
    // main::@146
    // [590] smc_bootloader#463 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_SKIP, NULL)
    // [591] call display_info_smc
    // [898] phi from main::@146 to display_info_smc [phi:main::@146->display_info_smc]
    // [898] phi display_info_smc::info_text#21 = 0 [phi:main::@146->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [898] phi smc_bootloader#14 = smc_bootloader#463 [phi:main::@146->display_info_smc#1] -- register_copy 
    // [898] phi display_info_smc::info_status#21 = STATUS_SKIP [phi:main::@146->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    jmp check_status_smc4
    // main::bank_set_brom4
  bank_set_brom4:
    // BROM = bank
    // [592] BROM = main::bank_set_brom4_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom4_bank
    sta.z BROM
    // main::@69
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [593] if(rom_device_ids[main::rom_chip1#10]==$55) goto main::@29 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    ldy rom_chip1
    lda rom_device_ids,y
    cmp #$55
    bne !__b29+
    jmp __b29
  !__b29:
    // [594] phi from main::@69 to main::@32 [phi:main::@69->main::@32]
    // main::@32
    // display_progress_clear()
    // [595] call display_progress_clear
    // [1161] phi from main::@32 to display_progress_clear [phi:main::@32->display_progress_clear]
    jsr display_progress_clear
    // main::@119
    // unsigned char rom_bank = rom_chip * 32
    // [596] main::rom_bank#0 = main::rom_chip1#10 << 5 -- vbum1=vbum2_rol_5 
    lda rom_chip1
    asl
    asl
    asl
    asl
    asl
    sta rom_bank
    // unsigned char* file = rom_file(rom_chip)
    // [597] rom_file::rom_chip#0 = main::rom_chip1#10 -- vbuz1=vbum2 
    lda rom_chip1
    sta.z rom_file.rom_chip
    // [598] call rom_file
    // [1221] phi from main::@119 to rom_file [phi:main::@119->rom_file]
    // [1221] phi rom_file::rom_chip#2 = rom_file::rom_chip#0 [phi:main::@119->rom_file#0] -- register_copy 
    jsr rom_file
    // unsigned char* file = rom_file(rom_chip)
    // [599] rom_file::return#4 = rom_file::return#2
    // main::@120
    // [600] main::file#0 = rom_file::return#4 -- pbum1=pbum2 
    lda rom_file.return
    sta file
    lda rom_file.return+1
    sta file+1
    // sprintf(info_text, "Checking %s ...", file)
    // [601] call snprintf_init
    // [1113] phi from main::@120 to snprintf_init [phi:main::@120->snprintf_init]
    // [1113] phi snprintf_init::s#25 = info_text [phi:main::@120->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [602] phi from main::@120 to main::@121 [phi:main::@120->main::@121]
    // main::@121
    // sprintf(info_text, "Checking %s ...", file)
    // [603] call printf_str
    // [1054] phi from main::@121 to printf_str [phi:main::@121->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:main::@121->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = main::s3 [phi:main::@121->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // main::@122
    // sprintf(info_text, "Checking %s ...", file)
    // [604] printf_string::str#19 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [605] call printf_string
    // [1227] phi from main::@122 to printf_string [phi:main::@122->printf_string]
    // [1227] phi printf_string::putc#25 = &snputc [phi:main::@122->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1227] phi printf_string::str#25 = printf_string::str#19 [phi:main::@122->printf_string#1] -- register_copy 
    // [1227] phi printf_string::format_justify_left#25 = 0 [phi:main::@122->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1227] phi printf_string::format_min_length#25 = 0 [phi:main::@122->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [606] phi from main::@122 to main::@123 [phi:main::@122->main::@123]
    // main::@123
    // sprintf(info_text, "Checking %s ...", file)
    // [607] call printf_str
    // [1054] phi from main::@123 to printf_str [phi:main::@123->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:main::@123->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = s4 [phi:main::@123->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // main::@124
    // sprintf(info_text, "Checking %s ...", file)
    // [608] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [609] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_progress(info_text)
    // [611] call display_action_progress
    // [1084] phi from main::@124 to display_action_progress [phi:main::@124->display_action_progress]
    // [1084] phi display_action_progress::info_text#20 = info_text [phi:main::@124->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_progress.info_text
    lda #>@info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // main::@125
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_CHECKING, rom_bank, rom_sizes[rom_chip])
    // [612] main::$303 = main::rom_chip1#10 << 2 -- vbum1=vbum2_rol_2 
    lda rom_chip1
    asl
    asl
    sta main__303
    // [613] rom_read::rom_chip#0 = main::rom_chip1#10 -- vbuz1=vbum2 
    lda rom_chip1
    sta.z rom_read.rom_chip
    // [614] rom_read::file#0 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z rom_read.file
    lda file+1
    sta.z rom_read.file+1
    // [615] rom_read::brom_bank_start#1 = main::rom_bank#0 -- vbuz1=vbum2 
    lda rom_bank
    sta.z rom_read.brom_bank_start
    // [616] rom_read::rom_size#0 = rom_sizes[main::$303] -- vduz1=pduc1_derefidx_vbum2 
    ldy main__303
    lda rom_sizes,y
    sta.z rom_read.rom_size
    lda rom_sizes+1,y
    sta.z rom_read.rom_size+1
    lda rom_sizes+2,y
    sta.z rom_read.rom_size+2
    lda rom_sizes+3,y
    sta.z rom_read.rom_size+3
    // [617] call rom_read
  // Read the ROM(n).BIN file.
    // [1252] phi from main::@125 to rom_read [phi:main::@125->rom_read]
    // [1252] phi rom_read::rom_chip#20 = rom_read::rom_chip#0 [phi:main::@125->rom_read#0] -- register_copy 
    // [1252] phi rom_read::rom_size#12 = rom_read::rom_size#0 [phi:main::@125->rom_read#1] -- register_copy 
    // [1252] phi __errno#114 = __errno#100 [phi:main::@125->rom_read#2] -- register_copy 
    // [1252] phi __stdio_filecount#108 = __stdio_filecount#114 [phi:main::@125->rom_read#3] -- register_copy 
    // [1252] phi rom_read::file#10 = rom_read::file#0 [phi:main::@125->rom_read#4] -- register_copy 
    // [1252] phi rom_read::brom_bank_start#10 = rom_read::brom_bank_start#1 [phi:main::@125->rom_read#5] -- register_copy 
    // [1252] phi rom_read::info_status#11 = STATUS_CHECKING [phi:main::@125->rom_read#6] -- vbuz1=vbuc1 
    lda #STATUS_CHECKING
    sta.z rom_read.info_status
    jsr rom_read
    // unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_CHECKING, rom_bank, rom_sizes[rom_chip])
    // [618] rom_read::return#2 = rom_read::return#0
    // main::@126
    // [619] main::rom_bytes_read#0 = rom_read::return#2
    // if (!rom_bytes_read)
    // [620] if(0==main::rom_bytes_read#0) goto main::@30 -- 0_eq_vdum1_then_la1 
    // In case no file was found, set the status to none and skip to the next, else, mention the amount of bytes read.
    lda rom_bytes_read
    ora rom_bytes_read+1
    ora rom_bytes_read+2
    ora rom_bytes_read+3
    bne !__b30+
    jmp __b30
  !__b30:
    // main::@33
    // unsigned long rom_file_modulo = rom_bytes_read % 0x4000
    // [621] main::rom_file_modulo#0 = main::rom_bytes_read#0 & $4000-1 -- vdum1=vdum2_band_vduc1 
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
    // [622] if(0!=main::rom_file_modulo#0) goto main::@31 -- 0_neq_vdum1_then_la1 
    lda rom_file_modulo
    ora rom_file_modulo+1
    ora rom_file_modulo+2
    ora rom_file_modulo+3
    beq !__b31+
    jmp __b31
  !__b31:
    // main::@34
    // file_sizes[rom_chip] = rom_bytes_read
    // [623] file_sizes[main::$303] = main::rom_bytes_read#0 -- pduc1_derefidx_vbum1=vdum2 
    // RF5 | ROM.BIN all ok | Display the ROM.BIN release version and github commit id (if any) and set ROM to Flash | Flash
    // We know the file size, so we indicate it in the status panel.
    ldy main__303
    lda rom_bytes_read
    sta file_sizes,y
    lda rom_bytes_read+1
    sta file_sizes+1,y
    lda rom_bytes_read+2
    sta file_sizes+2,y
    lda rom_bytes_read+3
    sta file_sizes+3,y
    // 8*rom_chip
    // [624] main::$125 = main::rom_chip1#10 << 3 -- vbuz1=vbum2_rol_3 
    lda rom_chip1
    asl
    asl
    asl
    sta.z main__125
    // unsigned char* rom_file_github_id = &rom_file_github[8*rom_chip]
    // [625] main::rom_file_github_id#0 = rom_file_github + main::$125 -- pbuz1=pbuc1_plus_vbuz2 
    // Fill the version data ...
    clc
    adc #<rom_file_github
    sta.z rom_file_github_id
    lda #>rom_file_github
    adc #0
    sta.z rom_file_github_id+1
    // unsigned char rom_file_release_id = rom_get_release(rom_file_release[rom_chip])
    // [626] rom_get_release::release#2 = rom_file_release[main::rom_chip1#10] -- vbuz1=pbuc1_derefidx_vbum2 
    ldy rom_chip1
    lda rom_file_release,y
    sta.z rom_get_release.release
    // [627] call rom_get_release
    // [1786] phi from main::@34 to rom_get_release [phi:main::@34->rom_get_release]
    // [1786] phi rom_get_release::release#3 = rom_get_release::release#2 [phi:main::@34->rom_get_release#0] -- register_copy 
    jsr rom_get_release
    // unsigned char rom_file_release_id = rom_get_release(rom_file_release[rom_chip])
    // [628] rom_get_release::return#3 = rom_get_release::return#0
    // main::@134
    // [629] main::rom_file_release_id#0 = rom_get_release::return#3
    // unsigned char rom_file_prefix_id = rom_get_prefix(rom_file_release[rom_chip])
    // [630] rom_get_prefix::release#1 = rom_file_release[main::rom_chip1#10] -- vbum1=pbuc1_derefidx_vbum2 
    ldy rom_chip1
    lda rom_file_release,y
    sta rom_get_prefix.release
    // [631] call rom_get_prefix
    // [1793] phi from main::@134 to rom_get_prefix [phi:main::@134->rom_get_prefix]
    // [1793] phi rom_get_prefix::release#2 = rom_get_prefix::release#1 [phi:main::@134->rom_get_prefix#0] -- register_copy 
    jsr rom_get_prefix
    // unsigned char rom_file_prefix_id = rom_get_prefix(rom_file_release[rom_chip])
    // [632] rom_get_prefix::return#3 = rom_get_prefix::return#0
    // main::@135
    // [633] main::rom_file_prefix_id#0 = rom_get_prefix::return#3
    // rom_get_version_text(rom_file_release_text, rom_file_prefix_id, rom_file_release_id, rom_file_github_id)
    // [634] rom_get_version_text::prefix#1 = main::rom_file_prefix_id#0
    // [635] rom_get_version_text::release#1 = main::rom_file_release_id#0
    // [636] rom_get_version_text::github#1 = main::rom_file_github_id#0
    // [637] call rom_get_version_text
    // [1802] phi from main::@135 to rom_get_version_text [phi:main::@135->rom_get_version_text]
    // [1802] phi rom_get_version_text::github#2 = rom_get_version_text::github#1 [phi:main::@135->rom_get_version_text#0] -- register_copy 
    // [1802] phi rom_get_version_text::release#2 = rom_get_version_text::release#1 [phi:main::@135->rom_get_version_text#1] -- register_copy 
    // [1802] phi rom_get_version_text::prefix#2 = rom_get_version_text::prefix#1 [phi:main::@135->rom_get_version_text#2] -- register_copy 
    // [1802] phi rom_get_version_text::release_info#2 = main::rom_file_release_text [phi:main::@135->rom_get_version_text#3] -- pbuz1=pbuc1 
    lda #<rom_file_release_text
    sta.z rom_get_version_text.release_info
    lda #>rom_file_release_text
    sta.z rom_get_version_text.release_info+1
    jsr rom_get_version_text
    // [638] phi from main::@135 to main::@136 [phi:main::@135->main::@136]
    // main::@136
    // sprintf(info_text, "%s:%s", file, rom_file_release_text)
    // [639] call snprintf_init
    // [1113] phi from main::@136 to snprintf_init [phi:main::@136->snprintf_init]
    // [1113] phi snprintf_init::s#25 = info_text [phi:main::@136->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // main::@137
    // sprintf(info_text, "%s:%s", file, rom_file_release_text)
    // [640] printf_string::str#22 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [641] call printf_string
    // [1227] phi from main::@137 to printf_string [phi:main::@137->printf_string]
    // [1227] phi printf_string::putc#25 = &snputc [phi:main::@137->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1227] phi printf_string::str#25 = printf_string::str#22 [phi:main::@137->printf_string#1] -- register_copy 
    // [1227] phi printf_string::format_justify_left#25 = 0 [phi:main::@137->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1227] phi printf_string::format_min_length#25 = 0 [phi:main::@137->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [642] phi from main::@137 to main::@138 [phi:main::@137->main::@138]
    // main::@138
    // sprintf(info_text, "%s:%s", file, rom_file_release_text)
    // [643] call printf_str
    // [1054] phi from main::@138 to printf_str [phi:main::@138->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:main::@138->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = s2 [phi:main::@138->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s2
    sta.z printf_str.s
    lda #>@s2
    sta.z printf_str.s+1
    jsr printf_str
    // [644] phi from main::@138 to main::@139 [phi:main::@138->main::@139]
    // main::@139
    // sprintf(info_text, "%s:%s", file, rom_file_release_text)
    // [645] call printf_string
    // [1227] phi from main::@139 to printf_string [phi:main::@139->printf_string]
    // [1227] phi printf_string::putc#25 = &snputc [phi:main::@139->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1227] phi printf_string::str#25 = main::rom_file_release_text [phi:main::@139->printf_string#1] -- pbuz1=pbuc1 
    lda #<rom_file_release_text
    sta.z printf_string.str
    lda #>rom_file_release_text
    sta.z printf_string.str+1
    // [1227] phi printf_string::format_justify_left#25 = 0 [phi:main::@139->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1227] phi printf_string::format_min_length#25 = 0 [phi:main::@139->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // main::@140
    // sprintf(info_text, "%s:%s", file, rom_file_release_text)
    // [646] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [647] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASH, info_text)
    // [649] display_info_rom::rom_chip#8 = main::rom_chip1#10 -- vbum1=vbum2 
    lda rom_chip1
    sta display_info_rom.rom_chip
    // [650] call display_info_rom
    // [1176] phi from main::@140 to display_info_rom [phi:main::@140->display_info_rom]
    // [1176] phi display_info_rom::info_text#16 = info_text [phi:main::@140->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1176] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#8 [phi:main::@140->display_info_rom#1] -- register_copy 
    // [1176] phi display_info_rom::info_status#16 = STATUS_FLASH [phi:main::@140->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASH
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // [651] phi from main::@129 main::@133 main::@140 main::@69 to main::@29 [phi:main::@129/main::@133/main::@140/main::@69->main::@29]
    // [651] phi __stdio_filecount#258 = __stdio_filecount#30 [phi:main::@129/main::@133/main::@140/main::@69->main::@29#0] -- register_copy 
    // [651] phi __errno#244 = __errno#18 [phi:main::@129/main::@133/main::@140/main::@69->main::@29#1] -- register_copy 
    // main::@29
  __b29:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [652] main::rom_chip1#1 = ++ main::rom_chip1#10 -- vbum1=_inc_vbum1 
    inc rom_chip1
    // [124] phi from main::@29 to main::@28 [phi:main::@29->main::@28]
    // [124] phi __stdio_filecount#114 = __stdio_filecount#258 [phi:main::@29->main::@28#0] -- register_copy 
    // [124] phi __errno#100 = __errno#244 [phi:main::@29->main::@28#1] -- register_copy 
    // [124] phi main::rom_chip1#10 = main::rom_chip1#1 [phi:main::@29->main::@28#2] -- register_copy 
    jmp __b28
    // [653] phi from main::@33 to main::@31 [phi:main::@33->main::@31]
    // main::@31
  __b31:
    // sprintf(info_text, "File %s size error!", file)
    // [654] call snprintf_init
    // [1113] phi from main::@31 to snprintf_init [phi:main::@31->snprintf_init]
    // [1113] phi snprintf_init::s#25 = info_text [phi:main::@31->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [655] phi from main::@31 to main::@130 [phi:main::@31->main::@130]
    // main::@130
    // sprintf(info_text, "File %s size error!", file)
    // [656] call printf_str
    // [1054] phi from main::@130 to printf_str [phi:main::@130->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:main::@130->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = main::s6 [phi:main::@130->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // main::@131
    // sprintf(info_text, "File %s size error!", file)
    // [657] printf_string::str#21 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [658] call printf_string
    // [1227] phi from main::@131 to printf_string [phi:main::@131->printf_string]
    // [1227] phi printf_string::putc#25 = &snputc [phi:main::@131->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1227] phi printf_string::str#25 = printf_string::str#21 [phi:main::@131->printf_string#1] -- register_copy 
    // [1227] phi printf_string::format_justify_left#25 = 0 [phi:main::@131->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1227] phi printf_string::format_min_length#25 = 0 [phi:main::@131->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [659] phi from main::@131 to main::@132 [phi:main::@131->main::@132]
    // main::@132
    // sprintf(info_text, "File %s size error!", file)
    // [660] call printf_str
    // [1054] phi from main::@132 to printf_str [phi:main::@132->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:main::@132->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = main::s7 [phi:main::@132->printf_str#1] -- pbuz1=pbuc1 
    lda #<s7
    sta.z printf_str.s
    lda #>s7
    sta.z printf_str.s+1
    jsr printf_str
    // main::@133
    // sprintf(info_text, "File %s size error!", file)
    // [661] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [662] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_ISSUE, info_text)
    // [664] display_info_rom::rom_chip#7 = main::rom_chip1#10 -- vbum1=vbum2 
    lda rom_chip1
    sta display_info_rom.rom_chip
    // [665] call display_info_rom
    // [1176] phi from main::@133 to display_info_rom [phi:main::@133->display_info_rom]
    // [1176] phi display_info_rom::info_text#16 = info_text [phi:main::@133->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1176] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#7 [phi:main::@133->display_info_rom#1] -- register_copy 
    // [1176] phi display_info_rom::info_status#16 = STATUS_ISSUE [phi:main::@133->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_ISSUE
    sta.z display_info_rom.info_status
    jsr display_info_rom
    jmp __b29
    // [666] phi from main::@126 to main::@30 [phi:main::@126->main::@30]
    // main::@30
  __b30:
    // sprintf(info_text, "No %s", file)
    // [667] call snprintf_init
    // [1113] phi from main::@30 to snprintf_init [phi:main::@30->snprintf_init]
    // [1113] phi snprintf_init::s#25 = info_text [phi:main::@30->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [668] phi from main::@30 to main::@127 [phi:main::@30->main::@127]
    // main::@127
    // sprintf(info_text, "No %s", file)
    // [669] call printf_str
    // [1054] phi from main::@127 to printf_str [phi:main::@127->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:main::@127->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = main::s5 [phi:main::@127->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // main::@128
    // sprintf(info_text, "No %s", file)
    // [670] printf_string::str#20 = main::file#0 -- pbuz1=pbum2 
    lda file
    sta.z printf_string.str
    lda file+1
    sta.z printf_string.str+1
    // [671] call printf_string
    // [1227] phi from main::@128 to printf_string [phi:main::@128->printf_string]
    // [1227] phi printf_string::putc#25 = &snputc [phi:main::@128->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1227] phi printf_string::str#25 = printf_string::str#20 [phi:main::@128->printf_string#1] -- register_copy 
    // [1227] phi printf_string::format_justify_left#25 = 0 [phi:main::@128->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1227] phi printf_string::format_min_length#25 = 0 [phi:main::@128->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // main::@129
    // sprintf(info_text, "No %s", file)
    // [672] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [673] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_SKIP, info_text)
    // [675] display_info_rom::rom_chip#6 = main::rom_chip1#10 -- vbum1=vbum2 
    lda rom_chip1
    sta display_info_rom.rom_chip
    // [676] call display_info_rom
    // [1176] phi from main::@129 to display_info_rom [phi:main::@129->display_info_rom]
    // [1176] phi display_info_rom::info_text#16 = info_text [phi:main::@129->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1176] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#6 [phi:main::@129->display_info_rom#1] -- register_copy 
    // [1176] phi display_info_rom::info_status#16 = STATUS_SKIP [phi:main::@129->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_SKIP
    sta.z display_info_rom.info_status
    jsr display_info_rom
    jmp __b29
    // [677] phi from main::@236 main::@67 to main::@23 [phi:main::@236/main::@67->main::@23]
    // main::@23
  __b23:
    // display_action_progress("Checking SMC.BIN ...")
    // [678] call display_action_progress
    // [1084] phi from main::@23 to display_action_progress [phi:main::@23->display_action_progress]
    // [1084] phi display_action_progress::info_text#20 = main::info_text2 [phi:main::@23->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text2
    sta.z display_action_progress.info_text
    lda #>info_text2
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [679] phi from main::@23 to main::@113 [phi:main::@23->main::@113]
    // main::@113
    // smc_read(STATUS_CHECKING)
    // [680] call smc_read
    // [1505] phi from main::@113 to smc_read [phi:main::@113->smc_read]
    // [1505] phi __errno#109 = 0 [phi:main::@113->smc_read#0] -- vwsm1=vwsc1 
    lda #<0
    sta __errno
    sta __errno+1
    // [1505] phi __stdio_filecount#104 = 0 [phi:main::@113->smc_read#1] -- vbum1=vbuc1 
    sta __stdio_filecount
    // [1505] phi smc_read::info_status#10 = STATUS_CHECKING [phi:main::@113->smc_read#2] -- vbuz1=vbuc1 
    lda #STATUS_CHECKING
    sta.z smc_read.info_status
    jsr smc_read
    // smc_read(STATUS_CHECKING)
    // [681] smc_read::return#2 = smc_read::return#0
    // main::@114
    // smc_file_size = smc_read(STATUS_CHECKING)
    // [682] smc_file_size#0 = smc_read::return#2 -- vwum1=vwuz2 
    lda.z smc_read.return
    sta smc_file_size
    lda.z smc_read.return+1
    sta smc_file_size+1
    // if (!smc_file_size)
    // [683] if(0==smc_file_size#0) goto main::@26 -- 0_eq_vwum1_then_la1 
    lda smc_file_size
    ora smc_file_size+1
    bne !__b26+
    jmp __b26
  !__b26:
    // main::@24
    // if(smc_file_size > 0x1E00)
    // [684] if(smc_file_size#0>$1e00) goto main::@27 -- vwum1_gt_vwuc1_then_la1 
    lda #>$1e00
    cmp smc_file_size+1
    bcs !__b27+
    jmp __b27
  !__b27:
    bne !+
    lda #<$1e00
    cmp smc_file_size
    bcs !__b27+
    jmp __b27
  !__b27:
  !:
    // main::@25
    // smc_file_release = smc_file_header[0]
    // [685] smc_file_release#0 = *smc_file_header -- vbum1=_deref_pbuc1 
    // SF4 | SMC.BIN and all ok | Display the SMC.BIN file version and set SMC to Flash. | Flash
    // The first 3 bytes of the smc file header is the version of the SMC file.
    lda smc_file_header
    sta smc_file_release
    // smc_file_major = smc_file_header[1]
    // [686] smc_file_major#0 = *(smc_file_header+1) -- vbum1=_deref_pbuc1 
    lda smc_file_header+1
    sta smc_file_major
    // smc_file_minor = smc_file_header[2]
    // [687] smc_file_minor#0 = *(smc_file_header+2) -- vbum1=_deref_pbuc1 
    lda smc_file_header+2
    sta smc_file_minor
    // smc_get_version_text(smc_file_version_text, smc_file_release, smc_file_major, smc_file_minor)
    // [688] smc_get_version_text::release#1 = smc_file_release#0 -- vbum1=vbum2 
    lda smc_file_release
    sta smc_get_version_text.release
    // [689] smc_get_version_text::major#1 = smc_file_major#0 -- vbuz1=vbum2 
    lda smc_file_major
    sta.z smc_get_version_text.major
    // [690] smc_get_version_text::minor#1 = smc_file_minor#0 -- vbum1=vbum2 
    lda smc_file_minor
    sta smc_get_version_text.minor
    // [691] call smc_get_version_text
    // [881] phi from main::@25 to smc_get_version_text [phi:main::@25->smc_get_version_text]
    // [881] phi smc_get_version_text::minor#2 = smc_get_version_text::minor#1 [phi:main::@25->smc_get_version_text#0] -- register_copy 
    // [881] phi smc_get_version_text::major#2 = smc_get_version_text::major#1 [phi:main::@25->smc_get_version_text#1] -- register_copy 
    // [881] phi smc_get_version_text::release#2 = smc_get_version_text::release#1 [phi:main::@25->smc_get_version_text#2] -- register_copy 
    // [881] phi smc_get_version_text::version_string#2 = main::smc_file_version_text [phi:main::@25->smc_get_version_text#3] -- pbuz1=pbuc1 
    lda #<smc_file_version_text
    sta.z smc_get_version_text.version_string
    lda #>smc_file_version_text
    sta.z smc_get_version_text.version_string+1
    jsr smc_get_version_text
    // [692] phi from main::@25 to main::@115 [phi:main::@25->main::@115]
    // main::@115
    // sprintf(info_text, "SMC.BIN:%s", smc_file_version_text)
    // [693] call snprintf_init
    // [1113] phi from main::@115 to snprintf_init [phi:main::@115->snprintf_init]
    // [1113] phi snprintf_init::s#25 = info_text [phi:main::@115->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [694] phi from main::@115 to main::@116 [phi:main::@115->main::@116]
    // main::@116
    // sprintf(info_text, "SMC.BIN:%s", smc_file_version_text)
    // [695] call printf_str
    // [1054] phi from main::@116 to printf_str [phi:main::@116->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:main::@116->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = main::s2 [phi:main::@116->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // [696] phi from main::@116 to main::@117 [phi:main::@116->main::@117]
    // main::@117
    // sprintf(info_text, "SMC.BIN:%s", smc_file_version_text)
    // [697] call printf_string
    // [1227] phi from main::@117 to printf_string [phi:main::@117->printf_string]
    // [1227] phi printf_string::putc#25 = &snputc [phi:main::@117->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1227] phi printf_string::str#25 = main::smc_file_version_text [phi:main::@117->printf_string#1] -- pbuz1=pbuc1 
    lda #<smc_file_version_text
    sta.z printf_string.str
    lda #>smc_file_version_text
    sta.z printf_string.str+1
    // [1227] phi printf_string::format_justify_left#25 = 0 [phi:main::@117->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1227] phi printf_string::format_min_length#25 = 0 [phi:main::@117->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // main::@118
    // sprintf(info_text, "SMC.BIN:%s", smc_file_version_text)
    // [698] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [699] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [701] smc_bootloader#459 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_FLASH, info_text)
    // [702] call display_info_smc
  // All ok, display file version.
    // [898] phi from main::@118 to display_info_smc [phi:main::@118->display_info_smc]
    // [898] phi display_info_smc::info_text#21 = info_text [phi:main::@118->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_smc.info_text
    lda #>@info_text
    sta.z display_info_smc.info_text+1
    // [898] phi smc_bootloader#14 = smc_bootloader#459 [phi:main::@118->display_info_smc#1] -- register_copy 
    // [898] phi display_info_smc::info_status#21 = STATUS_FLASH [phi:main::@118->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_FLASH
    sta display_info_smc.info_status
    jsr display_info_smc
    // [122] phi from main::@118 to main::SEI2 [phi:main::@118->main::SEI2]
    // [122] phi smc_file_minor#316 = smc_file_minor#0 [phi:main::@118->main::SEI2#0] -- register_copy 
    // [122] phi smc_file_major#316 = smc_file_major#0 [phi:main::@118->main::SEI2#1] -- register_copy 
    // [122] phi smc_file_release#316 = smc_file_release#0 [phi:main::@118->main::SEI2#2] -- register_copy 
    // [122] phi __stdio_filecount#259 = __stdio_filecount#27 [phi:main::@118->main::SEI2#3] -- register_copy 
    // [122] phi __errno#245 = __errno#18 [phi:main::@118->main::SEI2#4] -- register_copy 
    jmp SEI2
    // main::@27
  __b27:
    // [703] smc_bootloader#471 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ISSUE, "SMC.BIN too large!")
    // [704] call display_info_smc
  // SF3 | size SMC.BIN is > 0x1E00 | Display SMC.BIN file size issue and don't flash. Ask the user to place a correct SMC.BIN file onto the SDcard. | Issue
    // [898] phi from main::@27 to display_info_smc [phi:main::@27->display_info_smc]
    // [898] phi display_info_smc::info_text#21 = main::info_text4 [phi:main::@27->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text4
    sta.z display_info_smc.info_text
    lda #>info_text4
    sta.z display_info_smc.info_text+1
    // [898] phi smc_bootloader#14 = smc_bootloader#471 [phi:main::@27->display_info_smc#1] -- register_copy 
    // [898] phi display_info_smc::info_status#21 = STATUS_ISSUE [phi:main::@27->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_smc.info_status
    jsr display_info_smc
    // [122] phi from main::@26 main::@27 to main::SEI2 [phi:main::@26/main::@27->main::SEI2]
  __b5:
    // [122] phi smc_file_minor#316 = 0 [phi:main::@26/main::@27->main::SEI2#0] -- vbum1=vbuc1 
    lda #0
    sta smc_file_minor
    // [122] phi smc_file_major#316 = 0 [phi:main::@26/main::@27->main::SEI2#1] -- vbum1=vbuc1 
    sta smc_file_major
    // [122] phi smc_file_release#316 = 0 [phi:main::@26/main::@27->main::SEI2#2] -- vbum1=vbuc1 
    sta smc_file_release
    // [122] phi __stdio_filecount#259 = __stdio_filecount#27 [phi:main::@26/main::@27->main::SEI2#3] -- register_copy 
    // [122] phi __errno#245 = __errno#18 [phi:main::@26/main::@27->main::SEI2#4] -- register_copy 
    jmp SEI2
    // main::@26
  __b26:
    // [705] smc_bootloader#470 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_SKIP, "No SMC.BIN!")
    // [706] call display_info_smc
  // SF1 | no SMC.BIN | Ask user to place an SMC.BIN file onto the SDcard and don't flash. | Issue
  // SF2 | size SMC.BIN is 0 | Ask user to place an SMC.BIN file onto the SDcard and don't flash. | Issue
    // [898] phi from main::@26 to display_info_smc [phi:main::@26->display_info_smc]
    // [898] phi display_info_smc::info_text#21 = main::info_text3 [phi:main::@26->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text3
    sta.z display_info_smc.info_text
    lda #>info_text3
    sta.z display_info_smc.info_text+1
    // [898] phi smc_bootloader#14 = smc_bootloader#470 [phi:main::@26->display_info_smc#1] -- register_copy 
    // [898] phi display_info_smc::info_status#21 = STATUS_SKIP [phi:main::@26->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_SKIP
    sta display_info_smc.info_status
    jsr display_info_smc
    jmp __b5
    // main::@20
  __b20:
    // if(rom_device_ids[rom_chip] != UNKNOWN)
    // [707] if(rom_device_ids[main::rom_chip#10]!=$55) goto main::@21 -- pbuc1_derefidx_vbum1_neq_vbuc2_then_la1 
    lda #$55
    ldy rom_chip
    cmp rom_device_ids,y
    bne __b21
    // main::@22
  __b22:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [708] main::rom_chip#1 = ++ main::rom_chip#10 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [112] phi from main::@22 to main::@19 [phi:main::@22->main::@19]
    // [112] phi main::rom_chip#10 = main::rom_chip#1 [phi:main::@22->main::@19#0] -- register_copy 
    jmp __b19
    // main::@21
  __b21:
    // bank_set_brom(rom_chip*32)
    // [709] main::bank_set_brom3_bank#0 = main::rom_chip#10 << 5 -- vbum1=vbum2_rol_5 
    lda rom_chip
    asl
    asl
    asl
    asl
    asl
    sta bank_set_brom3_bank
    // main::bank_set_brom3
    // BROM = bank
    // [710] BROM = main::bank_set_brom3_bank#0 -- vbuz1=vbum2 
    sta.z BROM
    // main::@68
    // rom_chip*8
    // [711] main::$100 = main::rom_chip#10 << 3 -- vbuz1=vbum2_rol_3 
    lda rom_chip
    asl
    asl
    asl
    sta.z main__100
    // rom_get_github_commit_id(&rom_github[rom_chip*8], (char*)0xC000)
    // [712] rom_get_github_commit_id::commit_id#1 = rom_github + main::$100 -- pbuz1=pbuc1_plus_vbuz2 
    clc
    adc #<rom_github
    sta.z rom_get_github_commit_id.commit_id
    lda #>rom_github
    adc #0
    sta.z rom_get_github_commit_id.commit_id+1
    // [713] call rom_get_github_commit_id
    // [1818] phi from main::@68 to rom_get_github_commit_id [phi:main::@68->rom_get_github_commit_id]
    // [1818] phi rom_get_github_commit_id::commit_id#6 = rom_get_github_commit_id::commit_id#1 [phi:main::@68->rom_get_github_commit_id#0] -- register_copy 
    // [1818] phi rom_get_github_commit_id::from#6 = (char *) 49152 [phi:main::@68->rom_get_github_commit_id#1] -- pbuz1=pbuc1 
    lda #<$c000
    sta.z rom_get_github_commit_id.from
    lda #>$c000
    sta.z rom_get_github_commit_id.from+1
    jsr rom_get_github_commit_id
    // main::@109
    // rom_get_release(*((char*)0xFF80))
    // [714] rom_get_release::release#1 = *((char *) 65408) -- vbuz1=_deref_pbuc1 
    lda $ff80
    sta.z rom_get_release.release
    // [715] call rom_get_release
    // [1786] phi from main::@109 to rom_get_release [phi:main::@109->rom_get_release]
    // [1786] phi rom_get_release::release#3 = rom_get_release::release#1 [phi:main::@109->rom_get_release#0] -- register_copy 
    jsr rom_get_release
    // rom_get_release(*((char*)0xFF80))
    // [716] rom_get_release::return#2 = rom_get_release::return#0
    // main::@110
    // [717] main::$96 = rom_get_release::return#2
    // rom_release[rom_chip] = rom_get_release(*((char*)0xFF80))
    // [718] rom_release[main::rom_chip#10] = main::$96 -- pbuc1_derefidx_vbum1=vbuz2 
    lda.z main__96
    ldy rom_chip
    sta rom_release,y
    // rom_get_prefix(*((char*)0xFF80))
    // [719] rom_get_prefix::release#0 = *((char *) 65408) -- vbum1=_deref_pbuc1 
    lda $ff80
    sta rom_get_prefix.release
    // [720] call rom_get_prefix
    // [1793] phi from main::@110 to rom_get_prefix [phi:main::@110->rom_get_prefix]
    // [1793] phi rom_get_prefix::release#2 = rom_get_prefix::release#0 [phi:main::@110->rom_get_prefix#0] -- register_copy 
    jsr rom_get_prefix
    // rom_get_prefix(*((char*)0xFF80))
    // [721] rom_get_prefix::return#2 = rom_get_prefix::return#0
    // main::@111
    // [722] main::$97 = rom_get_prefix::return#2
    // rom_prefix[rom_chip] = rom_get_prefix(*((char*)0xFF80))
    // [723] rom_prefix[main::rom_chip#10] = main::$97 -- pbuc1_derefidx_vbum1=vbum2 
    lda main__97
    ldy rom_chip
    sta rom_prefix,y
    // rom_chip*13
    // [724] main::$360 = main::rom_chip#10 << 1 -- vbuz1=vbum2_rol_1 
    tya
    asl
    sta.z main__360
    // [725] main::$361 = main::$360 + main::rom_chip#10 -- vbuz1=vbuz1_plus_vbum2 
    tya
    clc
    adc.z main__361
    sta.z main__361
    // [726] main::$362 = main::$361 << 2 -- vbuz1=vbuz1_rol_2 
    lda.z main__362
    asl
    asl
    sta.z main__362
    // [727] main::$98 = main::$362 + main::rom_chip#10 -- vbuz1=vbuz1_plus_vbum2 
    tya
    clc
    adc.z main__98
    sta.z main__98
    // rom_get_version_text(&rom_release_text[rom_chip*13], rom_prefix[rom_chip], rom_release[rom_chip], &rom_github[rom_chip*8])
    // [728] rom_get_version_text::release_info#0 = rom_release_text + main::$98 -- pbuz1=pbuc1_plus_vbuz2 
    clc
    adc #<rom_release_text
    sta.z rom_get_version_text.release_info
    lda #>rom_release_text
    adc #0
    sta.z rom_get_version_text.release_info+1
    // [729] rom_get_version_text::github#0 = rom_github + main::$100 -- pbuz1=pbuc1_plus_vbuz2 
    lda.z main__100
    clc
    adc #<rom_github
    sta.z rom_get_version_text.github
    lda #>rom_github
    adc #0
    sta.z rom_get_version_text.github+1
    // [730] rom_get_version_text::prefix#0 = rom_prefix[main::rom_chip#10] -- vbum1=pbuc1_derefidx_vbum2 
    lda rom_prefix,y
    sta rom_get_version_text.prefix
    // [731] rom_get_version_text::release#0 = rom_release[main::rom_chip#10] -- vbuz1=pbuc1_derefidx_vbum2 
    lda rom_release,y
    sta.z rom_get_version_text.release
    // [732] call rom_get_version_text
    // [1802] phi from main::@111 to rom_get_version_text [phi:main::@111->rom_get_version_text]
    // [1802] phi rom_get_version_text::github#2 = rom_get_version_text::github#0 [phi:main::@111->rom_get_version_text#0] -- register_copy 
    // [1802] phi rom_get_version_text::release#2 = rom_get_version_text::release#0 [phi:main::@111->rom_get_version_text#1] -- register_copy 
    // [1802] phi rom_get_version_text::prefix#2 = rom_get_version_text::prefix#0 [phi:main::@111->rom_get_version_text#2] -- register_copy 
    // [1802] phi rom_get_version_text::release_info#2 = rom_get_version_text::release_info#0 [phi:main::@111->rom_get_version_text#3] -- register_copy 
    jsr rom_get_version_text
    // main::@112
    // display_info_rom(rom_chip, STATUS_DETECTED, NULL)
    // [733] display_info_rom::rom_chip#5 = main::rom_chip#10 -- vbum1=vbum2 
    lda rom_chip
    sta display_info_rom.rom_chip
    // [734] call display_info_rom
    // [1176] phi from main::@112 to display_info_rom [phi:main::@112->display_info_rom]
    // [1176] phi display_info_rom::info_text#16 = 0 [phi:main::@112->display_info_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_rom.info_text
    sta.z display_info_rom.info_text+1
    // [1176] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#5 [phi:main::@112->display_info_rom#1] -- register_copy 
    // [1176] phi display_info_rom::info_status#16 = STATUS_DETECTED [phi:main::@112->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_DETECTED
    sta.z display_info_rom.info_status
    jsr display_info_rom
    jmp __b22
    // [735] phi from main::@5 to main::@18 [phi:main::@5->main::@18]
    // main::@18
  __b18:
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [736] call snprintf_init
    // [1113] phi from main::@18 to snprintf_init [phi:main::@18->snprintf_init]
    // [1113] phi snprintf_init::s#25 = info_text [phi:main::@18->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [737] phi from main::@18 to main::@99 [phi:main::@18->main::@99]
    // main::@99
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [738] call printf_str
    // [1054] phi from main::@99 to printf_str [phi:main::@99->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:main::@99->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = main::s [phi:main::@99->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // main::@100
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [739] printf_uint::uvalue#6 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta printf_uint.uvalue
    lda smc_bootloader+1
    sta printf_uint.uvalue+1
    // [740] call printf_uint
    // [1835] phi from main::@100 to printf_uint [phi:main::@100->printf_uint]
    // [1835] phi printf_uint::format_zero_padding#10 = 1 [phi:main::@100->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [1835] phi printf_uint::format_min_length#10 = 2 [phi:main::@100->printf_uint#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uint.format_min_length
    // [1835] phi printf_uint::putc#10 = &snputc [phi:main::@100->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [1835] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:main::@100->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [1835] phi printf_uint::uvalue#10 = printf_uint::uvalue#6 [phi:main::@100->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [741] phi from main::@100 to main::@101 [phi:main::@100->main::@101]
    // main::@101
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [742] call printf_str
    // [1054] phi from main::@101 to printf_str [phi:main::@101->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:main::@101->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = main::s1 [phi:main::@101->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // main::@102
    // sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader)
    // [743] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [744] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [746] smc_bootloader#456 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ISSUE, info_text)
    // [747] call display_info_smc
    // [898] phi from main::@102 to display_info_smc [phi:main::@102->display_info_smc]
    // [898] phi display_info_smc::info_text#21 = info_text [phi:main::@102->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_smc.info_text
    lda #>@info_text
    sta.z display_info_smc.info_text+1
    // [898] phi smc_bootloader#14 = smc_bootloader#456 [phi:main::@102->display_info_smc#1] -- register_copy 
    // [898] phi display_info_smc::info_status#21 = STATUS_ISSUE [phi:main::@102->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_smc.info_status
    jsr display_info_smc
    // [748] phi from main::@102 to main::@103 [phi:main::@102->main::@103]
    // main::@103
    // display_progress_text(display_no_valid_smc_bootloader_text, display_no_valid_smc_bootloader_count)
    // [749] call display_progress_text
  // Bootloader is not supported by this utility, but is not error.
    // [1098] phi from main::@103 to display_progress_text [phi:main::@103->display_progress_text]
    // [1098] phi display_progress_text::text#12 = display_no_valid_smc_bootloader_text [phi:main::@103->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_no_valid_smc_bootloader_text
    sta.z display_progress_text.text
    lda #>display_no_valid_smc_bootloader_text
    sta.z display_progress_text.text+1
    // [1098] phi display_progress_text::lines#11 = display_no_valid_smc_bootloader_count [phi:main::@103->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_no_valid_smc_bootloader_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [105] phi from main::@103 main::@17 main::@98 to main::SEI1 [phi:main::@103/main::@17/main::@98->main::SEI1]
  __b6:
    // [105] phi smc_minor#391 = 0 [phi:main::@103/main::@17/main::@98->main::SEI1#0] -- vbum1=vbuc1 
    lda #0
    sta smc_minor
    // [105] phi smc_major#392 = 0 [phi:main::@103/main::@17/main::@98->main::SEI1#1] -- vbum1=vbuc1 
    sta smc_major
    // [105] phi smc_release#393 = 0 [phi:main::@103/main::@17/main::@98->main::SEI1#2] -- vbum1=vbuc1 
    sta smc_release
    jmp SEI1
    // main::@17
  __b17:
    // [750] smc_bootloader#469 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ERROR, "SMC Unreachable!")
    // [751] call display_info_smc
  // SD2 | SMC chip not detected | Display that the SMC chip is not detected and set SMC to Error. | Error
    // [898] phi from main::@17 to display_info_smc [phi:main::@17->display_info_smc]
    // [898] phi display_info_smc::info_text#21 = main::info_text1 [phi:main::@17->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_smc.info_text
    lda #>info_text1
    sta.z display_info_smc.info_text+1
    // [898] phi smc_bootloader#14 = smc_bootloader#469 [phi:main::@17->display_info_smc#1] -- register_copy 
    // [898] phi display_info_smc::info_status#21 = STATUS_ERROR [phi:main::@17->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ERROR
    sta display_info_smc.info_status
    jsr display_info_smc
    jmp __b6
    // main::@1
  __b1:
    // [752] smc_bootloader#455 = smc_bootloader#0 -- vwum1=vwum2 
    lda smc_bootloader
    sta smc_bootloader_1
    lda smc_bootloader+1
    sta smc_bootloader_1+1
    // display_info_smc(STATUS_ISSUE, "No Bootloader!")
    // [753] call display_info_smc
  // SD1 | No Bootloader | Display that there is no bootloader and set SMC to Issue. | Issue
    // [898] phi from main::@1 to display_info_smc [phi:main::@1->display_info_smc]
    // [898] phi display_info_smc::info_text#21 = main::info_text [phi:main::@1->display_info_smc#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_smc.info_text
    lda #>info_text
    sta.z display_info_smc.info_text+1
    // [898] phi smc_bootloader#14 = smc_bootloader#455 [phi:main::@1->display_info_smc#1] -- register_copy 
    // [898] phi display_info_smc::info_status#21 = STATUS_ISSUE [phi:main::@1->display_info_smc#2] -- vbum1=vbuc1 
    lda #STATUS_ISSUE
    sta display_info_smc.info_status
    jsr display_info_smc
    // [754] phi from main::@1 to main::@98 [phi:main::@1->main::@98]
    // main::@98
    // display_progress_text(display_no_valid_smc_bootloader_text, display_no_valid_smc_bootloader_count)
    // [755] call display_progress_text
  // If the CX16 board does not have a bootloader, display info how to flash bootloader.
    // [1098] phi from main::@98 to display_progress_text [phi:main::@98->display_progress_text]
    // [1098] phi display_progress_text::text#12 = display_no_valid_smc_bootloader_text [phi:main::@98->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_no_valid_smc_bootloader_text
    sta.z display_progress_text.text
    lda #>display_no_valid_smc_bootloader_text
    sta.z display_progress_text.text+1
    // [1098] phi display_progress_text::lines#11 = display_no_valid_smc_bootloader_count [phi:main::@98->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_no_valid_smc_bootloader_count
    sta display_progress_text.lines
    jsr display_progress_text
    jmp __b6
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
    info_text9: .text "Issue with the CX16 main ROM: not detected ..."
    .byte 0
    info_text10: .text "Issue with CX16 main ROM!"
    .byte 0
    info_text11: .text "Are J1 jumper pins closed?"
    .byte 0
    info_text13: .text "Issue with the CX16 main ROM, check the issue ..."
    .byte 0
    info_text14: .text "Issue with main CX16 ROM!"
    .byte 0
    info_text20: .text "Compatibility between ROM.BIN and SMC.BIN can't be assured!"
    .byte 0
    info_text22: .text "The SMC chip and SMC.BIN versions are equal, no flash required!"
    .byte 0
    info_text23: .text "The CX16 main ROM and ROM.BIN versions are equal, no flash required!"
    .byte 0
    info_text24: .text "Chipsets have been detected and update files validated!"
    .byte 0
    info_text25: .text "Continue with update of highlighted chipsets? [Y/N]"
    .byte 0
    filter4: .text "nyNY"
    .byte 0
    main__330: .text "nN"
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
    info_text34: .text "SMC has errors!"
    .byte 0
    info_text35: .text "POWER/RESET not pressed!"
    .byte 0
    s9: .text "Reading "
    .byte 0
    s10: .text " ... (.) data ( ) empty"
    .byte 0
    info_text36: .text "SMC Update failed!"
    .byte 0
    info_text37: .text "Comparing ... (.) data, (=) same, (*) different."
    .byte 0
    info_text39: .text "No update required"
    .byte 0
    s11: .text " differences!"
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
    info_text40: .text "No CX16 component has been updated with new firmware!"
    .byte 0
    info_text41: .text "Update Failure! Your CX16 may no longer boot!"
    .byte 0
    info_text42: .text "Take a photo of this screen, shut down power and retry!"
    .byte 0
    info_text43: .text "Update issues, your CX16 is not updated!"
    .byte 0
    info_text44: .text "Your CX16 update is a success!"
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
    .label main__28 = smc_supported_rom.return
    main__43: .word 0
    main__52: .byte 0
    .label main__61 = check_status_roms.return
    .label main__97 = rom_get_prefix.return
    .label main__186 = check_status_card_roms.return
    .label main__262 = check_status_roms.return
    .label main__267 = check_status_roms.return
    main__303: .byte 0
    main__305: .byte 0
    check_status_smc3_main__0: .byte 0
    check_status_cx16_rom1_check_status_rom1_main__0: .byte 0
    check_status_smc4_main__0: .byte 0
    check_status_cx16_rom2_check_status_rom1_main__0: .byte 0
    check_status_smc5_main__0: .byte 0
    check_status_cx16_rom3_check_status_rom1_main__0: .byte 0
    check_status_smc6_main__0: .byte 0
    check_status_smc7_main__0: .byte 0
    check_status_cx16_rom5_check_status_rom1_main__0: .byte 0
    check_status_smc8_main__0: .byte 0
    check_status_vera1_main__0: .byte 0
    check_status_smc9_main__0: .byte 0
    check_status_vera4_main__0: .byte 0
    check_status_smc11_main__0: .byte 0
    check_status_rom1_main__0: .byte 0
    check_status_vera6_main__0: .byte 0
    check_status_smc18_main__0: .byte 0
    bank_set_brom3_bank: .byte 0
    rom_chip: .byte 0
    .label check_status_smc3_return = check_status_smc3_main__0
    .label check_status_cx16_rom1_check_status_rom1_return = check_status_cx16_rom1_check_status_rom1_main__0
    rom_chip1: .byte 0
    rom_bank: .byte 0
    file: .word 0
    .label rom_bytes_read = rom_read.return
    rom_file_modulo: .dword 0
    .label rom_file_prefix_id = rom_get_prefix.return
    .label check_status_smc4_return = check_status_smc4_main__0
    .label check_status_cx16_rom2_check_status_rom1_return = check_status_cx16_rom2_check_status_rom1_main__0
    .label check_status_smc5_return = check_status_smc5_main__0
    .label check_status_cx16_rom3_check_status_rom1_return = check_status_cx16_rom3_check_status_rom1_main__0
    .label check_status_smc6_return = check_status_smc6_main__0
    .label check_status_smc7_return = check_status_smc7_main__0
    .label check_status_cx16_rom5_check_status_rom1_return = check_status_cx16_rom5_check_status_rom1_main__0
    .label check_status_smc8_return = check_status_smc8_main__0
    .label check_status_vera1_return = check_status_vera1_main__0
    .label check_status_smc9_return = check_status_smc9_main__0
    .label check_status_vera4_return = check_status_vera4_main__0
    .label check_status_smc11_return = check_status_smc11_main__0
    .label ch4 = util_wait_key.return_4
    rom_chip2: .byte 0
    .label flashed_bytes = smc_flash.return
    .label check_status_rom1_return = check_status_rom1_main__0
    rom_chip3: .byte 0
    rom_bank1: .byte 0
    .label file1 = rom_file.return
    .label rom_bytes_read1 = rom_read.return
    rom_flash_errors: .dword 0
    .label check_status_vera6_return = check_status_vera6_main__0
    .label check_status_smc18_return = check_status_smc18_main__0
    w: .byte 0
    w1: .byte 0
}
.segment Code
  // screenlayer1
// Set the layer with which the conio will interact.
screenlayer1: {
    // screenlayer(1, *VERA_L1_MAPBASE, *VERA_L1_CONFIG)
    // [756] screenlayer::mapbase#0 = *VERA_L1_MAPBASE -- vbum1=_deref_pbuc1 
    lda VERA_L1_MAPBASE
    sta screenlayer.mapbase
    // [757] screenlayer::config#0 = *VERA_L1_CONFIG -- vbum1=_deref_pbuc1 
    lda VERA_L1_CONFIG
    sta screenlayer.config
    // [758] call screenlayer
    jsr screenlayer
    // screenlayer1::@return
    // }
    // [759] return 
    rts
}
  // textcolor
// Set the front color for text output. The old front text color setting is returned.
// - color: a 4 bit value ( decimal between 0 and 15).
//   This will only work when the VERA is in 16 color mode!
//   Note that on the VERA, the transparent color has value 0.
// char textcolor(__mem() char color)
textcolor: {
    .label textcolor__0 = $b6
    .label textcolor__1 = $b6
    // __conio.color & 0xF0
    // [761] textcolor::$0 = *((char *)&__conio+$d) & $f0 -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f0
    and __conio+$d
    sta.z textcolor__0
    // __conio.color & 0xF0 | color
    // [762] textcolor::$1 = textcolor::$0 | textcolor::color#23 -- vbuz1=vbuz1_bor_vbum2 
    lda color
    ora.z textcolor__1
    sta.z textcolor__1
    // __conio.color = __conio.color & 0xF0 | color
    // [763] *((char *)&__conio+$d) = textcolor::$1 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // textcolor::@return
    // }
    // [764] return 
    rts
  .segment Data
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
    .label bgcolor__0 = $b6
    .label bgcolor__1 = $b7
    .label bgcolor__2 = $b6
    // __conio.color & 0x0F
    // [766] bgcolor::$0 = *((char *)&__conio+$d) & $f -- vbuz1=_deref_pbuc1_band_vbuc2 
    lda #$f
    and __conio+$d
    sta.z bgcolor__0
    // color << 4
    // [767] bgcolor::$1 = bgcolor::color#15 << 4 -- vbuz1=vbum2_rol_4 
    lda color
    asl
    asl
    asl
    asl
    sta.z bgcolor__1
    // __conio.color & 0x0F | color << 4
    // [768] bgcolor::$2 = bgcolor::$0 | bgcolor::$1 -- vbuz1=vbuz1_bor_vbuz2 
    lda.z bgcolor__2
    ora.z bgcolor__1
    sta.z bgcolor__2
    // __conio.color = __conio.color & 0x0F | color << 4
    // [769] *((char *)&__conio+$d) = bgcolor::$2 -- _deref_pbuc1=vbuz1 
    sta __conio+$d
    // bgcolor::@return
    // }
    // [770] return 
    rts
  .segment Data
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
    // [771] *((char *)&__conio+$c) = cursor::onoff#0 -- _deref_pbuc1=vbuc2 
    lda #onoff
    sta __conio+$c
    // cursor::@return
    // }
    // [772] return 
    rts
}
  // cbm_k_plot_get
/**
 * @brief Get current x and y cursor position.
 * @return An unsigned int where the hi byte is the x coordinate and the low byte is the y coordinate of the screen position.
 */
cbm_k_plot_get: {
    // __mem unsigned char x
    // [773] cbm_k_plot_get::x = 0 -- vbum1=vbuc1 
    lda #0
    sta x
    // __mem unsigned char y
    // [774] cbm_k_plot_get::y = 0 -- vbum1=vbuc1 
    sta y
    // kickasm
    // kickasm( uses cbm_k_plot_get::x uses cbm_k_plot_get::y uses CBM_PLOT) {{ sec         jsr CBM_PLOT         stx y         sty x      }}
    sec
        jsr CBM_PLOT
        stx y
        sty x
    
    // MAKEWORD(x,y)
    // [776] cbm_k_plot_get::return#0 = cbm_k_plot_get::x w= cbm_k_plot_get::y -- vwum1=vbum2_word_vbum3 
    lda x
    sta return+1
    lda y
    sta return
    // cbm_k_plot_get::@return
    // }
    // [777] return 
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
    .label gotoxy__2 = $30
    .label gotoxy__3 = $30
    .label gotoxy__6 = $2f
    .label gotoxy__7 = $2f
    .label gotoxy__8 = $37
    .label gotoxy__9 = $34
    .label gotoxy__10 = $33
    .label gotoxy__14 = $2f
    // (x>=__conio.width)?__conio.width:x
    // [779] if(gotoxy::x#33>=*((char *)&__conio+6)) goto gotoxy::@1 -- vbum1_ge__deref_pbuc1_then_la1 
    lda x
    cmp __conio+6
    bcs __b1
    // [781] phi from gotoxy to gotoxy::@2 [phi:gotoxy->gotoxy::@2]
    // [781] phi gotoxy::$3 = gotoxy::x#33 [phi:gotoxy->gotoxy::@2#0] -- vbuz1=vbum2 
    sta.z gotoxy__3
    jmp __b2
    // gotoxy::@1
  __b1:
    // [780] gotoxy::$2 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z gotoxy__2
    // [781] phi from gotoxy::@1 to gotoxy::@2 [phi:gotoxy::@1->gotoxy::@2]
    // [781] phi gotoxy::$3 = gotoxy::$2 [phi:gotoxy::@1->gotoxy::@2#0] -- register_copy 
    // gotoxy::@2
  __b2:
    // __conio.cursor_x = (x>=__conio.width)?__conio.width:x
    // [782] *((char *)&__conio) = gotoxy::$3 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__3
    sta __conio
    // (y>=__conio.height)?__conio.height:y
    // [783] if(gotoxy::y#33>=*((char *)&__conio+7)) goto gotoxy::@3 -- vbum1_ge__deref_pbuc1_then_la1 
    lda y
    cmp __conio+7
    bcs __b3
    // gotoxy::@4
    // [784] gotoxy::$14 = gotoxy::y#33 -- vbuz1=vbum2 
    sta.z gotoxy__14
    // [785] phi from gotoxy::@3 gotoxy::@4 to gotoxy::@5 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5]
    // [785] phi gotoxy::$7 = gotoxy::$6 [phi:gotoxy::@3/gotoxy::@4->gotoxy::@5#0] -- register_copy 
    // gotoxy::@5
  __b5:
    // __conio.cursor_y = (y>=__conio.height)?__conio.height:y
    // [786] *((char *)&__conio+1) = gotoxy::$7 -- _deref_pbuc1=vbuz1 
    lda.z gotoxy__7
    sta __conio+1
    // __conio.cursor_x << 1
    // [787] gotoxy::$8 = *((char *)&__conio) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio
    asl
    sta.z gotoxy__8
    // __conio.offsets[y] + __conio.cursor_x << 1
    // [788] gotoxy::$10 = gotoxy::y#33 << 1 -- vbuz1=vbum2_rol_1 
    lda y
    asl
    sta.z gotoxy__10
    // [789] gotoxy::$9 = ((unsigned int *)&__conio+$15)[gotoxy::$10] + gotoxy::$8 -- vwuz1=pwuc1_derefidx_vbuz2_plus_vbuz3 
    lda.z gotoxy__8
    ldy.z gotoxy__10
    clc
    adc __conio+$15,y
    sta.z gotoxy__9
    lda __conio+$15+1,y
    adc #0
    sta.z gotoxy__9+1
    // __conio.offset = __conio.offsets[y] + __conio.cursor_x << 1
    // [790] *((unsigned int *)&__conio+$13) = gotoxy::$9 -- _deref_pwuc1=vwuz1 
    lda.z gotoxy__9
    sta __conio+$13
    lda.z gotoxy__9+1
    sta __conio+$13+1
    // gotoxy::@return
    // }
    // [791] return 
    rts
    // gotoxy::@3
  __b3:
    // (y>=__conio.height)?__conio.height:y
    // [792] gotoxy::$6 = *((char *)&__conio+7) -- vbuz1=_deref_pbuc1 
    lda __conio+7
    sta.z gotoxy__6
    jmp __b5
  .segment Data
    x: .byte 0
    y: .byte 0
}
.segment Code
  // cputln
// Print a newline
cputln: {
    .label cputln__2 = $50
    // __conio.cursor_x = 0
    // [793] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y++;
    // [794] *((char *)&__conio+1) = ++ *((char *)&__conio+1) -- _deref_pbuc1=_inc__deref_pbuc1 
    inc __conio+1
    // __conio.offset = __conio.offsets[__conio.cursor_y]
    // [795] cputln::$2 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z cputln__2
    // [796] *((unsigned int *)&__conio+$13) = ((unsigned int *)&__conio+$15)[cputln::$2] -- _deref_pwuc1=pwuc2_derefidx_vbuz1 
    tay
    lda __conio+$15,y
    sta __conio+$13
    lda __conio+$15+1,y
    sta __conio+$13+1
    // cscroll()
    // [797] call cscroll
    jsr cscroll
    // cputln::@return
    // }
    // [798] return 
    rts
}
  // init
init: {
    .label init__12 = $4d
    .label init__16 = $4d
    .label init__17 = $4d
    .label init__18 = $4d
    // display_frame_init_64()
    // [800] call display_frame_init_64
    jsr display_frame_init_64
    // [801] phi from init to init::@4 [phi:init->init::@4]
    // init::@4
    // display_frame_draw()
    // [802] call display_frame_draw
  // ST1 | Reset canvas to 64 columns
    // [1920] phi from init::@4 to display_frame_draw [phi:init::@4->display_frame_draw]
    jsr display_frame_draw
    // [803] phi from init::@4 to init::@5 [phi:init::@4->init::@5]
    // init::@5
    // display_frame_title("Commander X16 Update Utility (v2.2.1) ")
    // [804] call display_frame_title
    // [1961] phi from init::@5 to display_frame_title [phi:init::@5->display_frame_title]
    jsr display_frame_title
    // [805] phi from init::@5 to init::display_info_title1 [phi:init::@5->init::display_info_title1]
    // init::display_info_title1
    // cputsxy(INFO_X-2, INFO_Y-2, "# Chip Status    Type   Curr. Release Update Info")
    // [806] call cputsxy
    // [1966] phi from init::display_info_title1 to cputsxy [phi:init::display_info_title1->cputsxy]
    // [1966] phi cputsxy::s#4 = init::s [phi:init::display_info_title1->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [1966] phi cputsxy::y#4 = $11-2 [phi:init::display_info_title1->cputsxy#1] -- vbum1=vbuc1 
    lda #$11-2
    sta cputsxy.y
    // [1966] phi cputsxy::x#4 = 4-2 [phi:init::display_info_title1->cputsxy#2] -- vbum1=vbuc1 
    lda #4-2
    sta cputsxy.x
    jsr cputsxy
    // [807] phi from init::display_info_title1 to init::@6 [phi:init::display_info_title1->init::@6]
    // init::@6
    // cputsxy(INFO_X-2, INFO_Y-1, "- ---- --------- ------ ------------- --------------------------")
    // [808] call cputsxy
    // [1966] phi from init::@6 to cputsxy [phi:init::@6->cputsxy]
    // [1966] phi cputsxy::s#4 = init::s1 [phi:init::@6->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s1
    sta.z cputsxy.s
    lda #>s1
    sta.z cputsxy.s+1
    // [1966] phi cputsxy::y#4 = $11-1 [phi:init::@6->cputsxy#1] -- vbum1=vbuc1 
    lda #$11-1
    sta cputsxy.y
    // [1966] phi cputsxy::x#4 = 4-2 [phi:init::@6->cputsxy#2] -- vbum1=vbuc1 
    lda #4-2
    sta cputsxy.x
    jsr cputsxy
    // [809] phi from init::@6 to init::@3 [phi:init::@6->init::@3]
    // init::@3
    // display_action_progress("Introduction, please read carefully the below!")
    // [810] call display_action_progress
    // [1084] phi from init::@3 to display_action_progress [phi:init::@3->display_action_progress]
    // [1084] phi display_action_progress::info_text#20 = init::info_text [phi:init::@3->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [811] phi from init::@3 to init::@7 [phi:init::@3->init::@7]
    // init::@7
    // display_progress_clear()
    // [812] call display_progress_clear
    // [1161] phi from init::@7 to display_progress_clear [phi:init::@7->display_progress_clear]
    jsr display_progress_clear
    // [813] phi from init::@7 to init::@8 [phi:init::@7->init::@8]
    // init::@8
    // display_chip_smc()
    // [814] call display_chip_smc
    // [871] phi from init::@8 to display_chip_smc [phi:init::@8->display_chip_smc]
    jsr display_chip_smc
    // [815] phi from init::@8 to init::@9 [phi:init::@8->init::@9]
    // init::@9
    // display_chip_vera()
    // [816] call display_chip_vera
    // [1973] phi from init::@9 to display_chip_vera [phi:init::@9->display_chip_vera]
    jsr display_chip_vera
    // [817] phi from init::@9 to init::@10 [phi:init::@9->init::@10]
    // init::@10
    // display_chip_rom()
    // [818] call display_chip_rom
    // [984] phi from init::@10 to display_chip_rom [phi:init::@10->display_chip_rom]
    jsr display_chip_rom
    // [819] phi from init::@10 to init::@11 [phi:init::@10->init::@11]
    // init::@11
    // display_info_smc(STATUS_COLOR_NONE, NULL)
    // [820] call display_info_smc
    // [898] phi from init::@11 to display_info_smc [phi:init::@11->display_info_smc]
    // [898] phi display_info_smc::info_text#21 = 0 [phi:init::@11->display_info_smc#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_smc.info_text
    sta.z display_info_smc.info_text+1
    // [898] phi smc_bootloader#14 = 0 [phi:init::@11->display_info_smc#1] -- vwum1=vwuc1 
    sta smc_bootloader_1
    sta smc_bootloader_1+1
    // [898] phi display_info_smc::info_status#21 = BLACK [phi:init::@11->display_info_smc#2] -- vbum1=vbuc1 
    lda #BLACK
    sta display_info_smc.info_status
    jsr display_info_smc
    // [821] phi from init::@11 to init::@12 [phi:init::@11->init::@12]
    // init::@12
    // display_info_vera(STATUS_NONE, NULL)
    // [822] call display_info_vera
    // [1738] phi from init::@12 to display_info_vera [phi:init::@12->display_info_vera]
    // [1738] phi display_info_vera::info_text#10 = 0 [phi:init::@12->display_info_vera#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_vera.info_text
    sta.z display_info_vera.info_text+1
    // [1738] phi display_info_vera::info_status#2 = STATUS_NONE [phi:init::@12->display_info_vera#1] -- vbum1=vbuc1 
    lda #STATUS_NONE
    sta display_info_vera.info_status
    jsr display_info_vera
    // [823] phi from init::@12 to init::@1 [phi:init::@12->init::@1]
    // [823] phi init::rom_chip#2 = 0 [phi:init::@12->init::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // init::@1
  __b1:
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [824] if(init::rom_chip#2<8) goto init::@2 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcc __b2
    // init::@return
    // }
    // [825] return 
    rts
    // init::@2
  __b2:
    // rom_chip*13
    // [826] init::$16 = init::rom_chip#2 << 1 -- vbuz1=vbum2_rol_1 
    lda rom_chip
    asl
    sta.z init__16
    // [827] init::$17 = init::$16 + init::rom_chip#2 -- vbuz1=vbuz1_plus_vbum2 
    lda rom_chip
    clc
    adc.z init__17
    sta.z init__17
    // [828] init::$18 = init::$17 << 2 -- vbuz1=vbuz1_rol_2 
    lda.z init__18
    asl
    asl
    sta.z init__18
    // [829] init::$12 = init::$18 + init::rom_chip#2 -- vbuz1=vbuz1_plus_vbum2 
    lda rom_chip
    clc
    adc.z init__12
    sta.z init__12
    // strcpy(&rom_release_text[rom_chip*13], "          " )
    // [830] strcpy::destination#0 = rom_release_text + init::$12 -- pbuz1=pbuc1_plus_vbuz2 
    clc
    adc #<rom_release_text
    sta.z strcpy.destination
    lda #>rom_release_text
    adc #0
    sta.z strcpy.destination+1
    // [831] call strcpy
    // [863] phi from init::@2 to strcpy [phi:init::@2->strcpy]
    // [863] phi strcpy::dst#0 = strcpy::destination#0 [phi:init::@2->strcpy#0] -- register_copy 
    // [863] phi strcpy::src#0 = init::source [phi:init::@2->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // init::@13
    // display_info_rom(rom_chip, STATUS_NONE, NULL)
    // [832] display_info_rom::rom_chip#0 = init::rom_chip#2 -- vbum1=vbum2 
    lda rom_chip
    sta display_info_rom.rom_chip
    // [833] call display_info_rom
    // [1176] phi from init::@13 to display_info_rom [phi:init::@13->display_info_rom]
    // [1176] phi display_info_rom::info_text#16 = 0 [phi:init::@13->display_info_rom#0] -- pbuz1=vbuc1 
    lda #<0
    sta.z display_info_rom.info_text
    sta.z display_info_rom.info_text+1
    // [1176] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#0 [phi:init::@13->display_info_rom#1] -- register_copy 
    // [1176] phi display_info_rom::info_status#16 = STATUS_NONE [phi:init::@13->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_NONE
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // init::@14
    // for(unsigned char rom_chip=0; rom_chip<8; rom_chip++)
    // [834] init::rom_chip#1 = ++ init::rom_chip#2 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [823] phi from init::@14 to init::@1 [phi:init::@14->init::@1]
    // [823] phi init::rom_chip#2 = init::rom_chip#1 [phi:init::@14->init::@1#0] -- register_copy 
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
    .label rom_chip = check_status_roms_less.rom_chip
}
.segment CodeIntro
  // main_intro
main_intro: {
    // display_progress_text(display_into_briefing_text, display_intro_briefing_count)
    // [836] call display_progress_text
    // [1098] phi from main_intro to display_progress_text [phi:main_intro->display_progress_text]
    // [1098] phi display_progress_text::text#12 = display_into_briefing_text [phi:main_intro->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_into_briefing_text
    sta.z display_progress_text.text
    lda #>display_into_briefing_text
    sta.z display_progress_text.text+1
    // [1098] phi display_progress_text::lines#11 = display_intro_briefing_count [phi:main_intro->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_intro_briefing_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [837] phi from main_intro to main_intro::@4 [phi:main_intro->main_intro::@4]
    // main_intro::@4
    // util_wait_space()
    // [838] call util_wait_space
    // [1778] phi from main_intro::@4 to util_wait_space [phi:main_intro::@4->util_wait_space]
    jsr util_wait_space
    // [839] phi from main_intro::@4 to main_intro::@5 [phi:main_intro::@4->main_intro::@5]
    // main_intro::@5
    // display_progress_text(display_into_colors_text, display_intro_colors_count)
    // [840] call display_progress_text
    // [1098] phi from main_intro::@5 to display_progress_text [phi:main_intro::@5->display_progress_text]
    // [1098] phi display_progress_text::text#12 = display_into_colors_text [phi:main_intro::@5->display_progress_text#0] -- qbuz1=qbuc1 
    lda #<display_into_colors_text
    sta.z display_progress_text.text
    lda #>display_into_colors_text
    sta.z display_progress_text.text+1
    // [1098] phi display_progress_text::lines#11 = display_intro_colors_count [phi:main_intro::@5->display_progress_text#1] -- vbum1=vbuc1 
    lda #display_intro_colors_count
    sta display_progress_text.lines
    jsr display_progress_text
    // [841] phi from main_intro::@5 to main_intro::@1 [phi:main_intro::@5->main_intro::@1]
    // [841] phi main_intro::intro_status#2 = 0 [phi:main_intro::@5->main_intro::@1#0] -- vbum1=vbuc1 
    lda #0
    sta intro_status
    // main_intro::@1
  __b1:
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [842] if(main_intro::intro_status#2<$b) goto main_intro::@2 -- vbum1_lt_vbuc1_then_la1 
    lda intro_status
    cmp #$b
    bcc __b2
    // [843] phi from main_intro::@1 to main_intro::@3 [phi:main_intro::@1->main_intro::@3]
    // main_intro::@3
    // util_wait_space()
    // [844] call util_wait_space
    // [1778] phi from main_intro::@3 to util_wait_space [phi:main_intro::@3->util_wait_space]
    jsr util_wait_space
    // [845] phi from main_intro::@3 to main_intro::@7 [phi:main_intro::@3->main_intro::@7]
    // main_intro::@7
    // display_progress_clear()
    // [846] call display_progress_clear
    // [1161] phi from main_intro::@7 to display_progress_clear [phi:main_intro::@7->display_progress_clear]
    jsr display_progress_clear
    // main_intro::@return
    // }
    // [847] return 
    rts
    // main_intro::@2
  __b2:
    // display_info_led(PROGRESS_X + 3, PROGRESS_Y + 3 + intro_status, status_color[intro_status], BLUE)
    // [848] display_info_led::y#3 = PROGRESS_Y+3 + main_intro::intro_status#2 -- vbuz1=vbuc1_plus_vbum2 
    lda #PROGRESS_Y+3
    clc
    adc intro_status
    sta.z display_info_led.y
    // [849] display_info_led::tc#3 = status_color[main_intro::intro_status#2] -- vbuz1=pbuc1_derefidx_vbum2 
    ldy intro_status
    lda status_color,y
    sta.z display_info_led.tc
    // [850] call display_info_led
    // [1978] phi from main_intro::@2 to display_info_led [phi:main_intro::@2->display_info_led]
    // [1978] phi display_info_led::y#4 = display_info_led::y#3 [phi:main_intro::@2->display_info_led#0] -- register_copy 
    // [1978] phi display_info_led::x#4 = PROGRESS_X+3 [phi:main_intro::@2->display_info_led#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X+3
    sta.z display_info_led.x
    // [1978] phi display_info_led::tc#4 = display_info_led::tc#3 [phi:main_intro::@2->display_info_led#2] -- register_copy 
    jsr display_info_led
    // main_intro::@6
    // for(unsigned char intro_status=0; intro_status<11; intro_status++)
    // [851] main_intro::intro_status#1 = ++ main_intro::intro_status#2 -- vbum1=_inc_vbum1 
    inc intro_status
    // [841] phi from main_intro::@6 to main_intro::@1 [phi:main_intro::@6->main_intro::@1]
    // [841] phi main_intro::intro_status#2 = main_intro::intro_status#1 [phi:main_intro::@6->main_intro::@1#0] -- register_copy 
    jmp __b1
  .segment DataIntro
    intro_status: .byte 0
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
    .label smc_detect__1 = $4d
    // When the bootloader is not present, 0xFF is returned.
    .label smc_bootloader_version = $c7
    .label return = $c7
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [852] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [853] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [854] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [855] cx16_k_i2c_read_byte::return#10 = cx16_k_i2c_read_byte::return#1
    // smc_detect::@3
    // smc_bootloader_version = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [856] smc_detect::smc_bootloader_version#1 = cx16_k_i2c_read_byte::return#10 -- vwuz1=vwum2 
    lda cx16_k_i2c_read_byte.return
    sta.z smc_bootloader_version
    lda cx16_k_i2c_read_byte.return+1
    sta.z smc_bootloader_version+1
    // BYTE1(smc_bootloader_version)
    // [857] smc_detect::$1 = byte1  smc_detect::smc_bootloader_version#1 -- vbuz1=_byte1_vwuz2 
    sta.z smc_detect__1
    // if(!BYTE1(smc_bootloader_version))
    // [858] if(0==smc_detect::$1) goto smc_detect::@1 -- 0_eq_vbuz1_then_la1 
    beq __b1
    // [861] phi from smc_detect::@3 to smc_detect::@2 [phi:smc_detect::@3->smc_detect::@2]
    // [861] phi smc_detect::return#0 = $200 [phi:smc_detect::@3->smc_detect::@2#0] -- vwuz1=vwuc1 
    lda #<$200
    sta.z return
    lda #>$200
    sta.z return+1
    rts
    // smc_detect::@1
  __b1:
    // if(smc_bootloader_version == 0xFF)
    // [859] if(smc_detect::smc_bootloader_version#1!=$ff) goto smc_detect::@4 -- vwuz1_neq_vbuc1_then_la1 
    lda.z smc_bootloader_version+1
    bne __b2
    lda.z smc_bootloader_version
    cmp #$ff
    bne __b2
    // [861] phi from smc_detect::@1 to smc_detect::@2 [phi:smc_detect::@1->smc_detect::@2]
    // [861] phi smc_detect::return#0 = $100 [phi:smc_detect::@1->smc_detect::@2#0] -- vwuz1=vwuc1 
    lda #<$100
    sta.z return
    lda #>$100
    sta.z return+1
    rts
    // [860] phi from smc_detect::@1 to smc_detect::@4 [phi:smc_detect::@1->smc_detect::@4]
    // smc_detect::@4
    // [861] phi from smc_detect::@4 to smc_detect::@2 [phi:smc_detect::@4->smc_detect::@2]
    // [861] phi smc_detect::return#0 = smc_detect::smc_bootloader_version#1 [phi:smc_detect::@4->smc_detect::@2#0] -- register_copy 
    // smc_detect::@2
  __b2:
    // smc_detect::@return
    // }
    // [862] return 
    rts
}
  // strcpy
// Copies the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcpy(__zp($b8) char *destination, char *source)
strcpy: {
    .label src = $c7
    .label dst = $b8
    .label destination = $b8
    // [864] phi from strcpy strcpy::@2 to strcpy::@1 [phi:strcpy/strcpy::@2->strcpy::@1]
    // [864] phi strcpy::dst#2 = strcpy::dst#0 [phi:strcpy/strcpy::@2->strcpy::@1#0] -- register_copy 
    // [864] phi strcpy::src#2 = strcpy::src#0 [phi:strcpy/strcpy::@2->strcpy::@1#1] -- register_copy 
    // strcpy::@1
  __b1:
    // while(*src)
    // [865] if(0!=*strcpy::src#2) goto strcpy::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcpy::@3
    // *dst = 0
    // [866] *strcpy::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcpy::@return
    // }
    // [867] return 
    rts
    // strcpy::@2
  __b2:
    // *dst++ = *src++
    // [868] *strcpy::dst#2 = *strcpy::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [869] strcpy::dst#1 = ++ strcpy::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [870] strcpy::src#1 = ++ strcpy::src#2 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    jmp __b1
}
  // display_chip_smc
display_chip_smc: {
    // display_smc_led(GREY)
    // [872] call display_smc_led
    // [1989] phi from display_chip_smc to display_smc_led [phi:display_chip_smc->display_smc_led]
    // [1989] phi display_smc_led::c#2 = GREY [phi:display_chip_smc->display_smc_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z display_smc_led.c
    jsr display_smc_led
    // [873] phi from display_chip_smc to display_chip_smc::@1 [phi:display_chip_smc->display_chip_smc::@1]
    // display_chip_smc::@1
    // display_print_chip(CHIP_SMC_X, CHIP_SMC_Y+2, CHIP_SMC_W, "SMC     ")
    // [874] call display_print_chip
    // [1995] phi from display_chip_smc::@1 to display_print_chip [phi:display_chip_smc::@1->display_print_chip]
    // [1995] phi display_print_chip::text#11 = display_chip_smc::text [phi:display_chip_smc::@1->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_print_chip.text_2
    lda #>text
    sta.z display_print_chip.text_2+1
    // [1995] phi display_print_chip::w#10 = 5 [phi:display_chip_smc::@1->display_print_chip#1] -- vbum1=vbuc1 
    lda #5
    sta display_print_chip.w
    // [1995] phi display_print_chip::x#10 = 1 [phi:display_chip_smc::@1->display_print_chip#2] -- vbuz1=vbuc1 
    lda #1
    sta.z display_print_chip.x
    jsr display_print_chip
    // display_chip_smc::@return
    // }
    // [875] return 
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
    // [876] cx16_k_i2c_read_byte::result = 0 -- vwum1=vwuc1 
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
    // [878] cx16_k_i2c_read_byte::return#0 = cx16_k_i2c_read_byte::result -- vwum1=vwum2 
    sta return
    lda result+1
    sta return+1
    // cx16_k_i2c_read_byte::@return
    // }
    // [879] cx16_k_i2c_read_byte::return#1 = cx16_k_i2c_read_byte::return#0
    // [880] return 
    rts
  .segment Data
    device: .byte 0
    offset: .byte 0
    result: .word 0
    return: .word 0
}
.segment Code
  // smc_get_version_text
/**
 * @brief Detect and write the SMC version number into the info_text.
 * 
 * @param version_string The string containing the SMC version filled upon return.
 */
// unsigned long smc_get_version_text(__zp($b8) char *version_string, __mem() char release, __zp($e7) char major, __mem() char minor)
smc_get_version_text: {
    .label major = $e7
    .label version_string = $b8
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [882] snprintf_init::s#3 = smc_get_version_text::version_string#2
    // [883] call snprintf_init
    // [1113] phi from smc_get_version_text to snprintf_init [phi:smc_get_version_text->snprintf_init]
    // [1113] phi snprintf_init::s#25 = snprintf_init::s#3 [phi:smc_get_version_text->snprintf_init#0] -- register_copy 
    jsr snprintf_init
    // smc_get_version_text::@1
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [884] printf_uchar::uvalue#6 = smc_get_version_text::release#2 -- vbum1=vbum2 
    lda release
    sta printf_uchar.uvalue
    // [885] call printf_uchar
    // [1118] phi from smc_get_version_text::@1 to printf_uchar [phi:smc_get_version_text::@1->printf_uchar]
    // [1118] phi printf_uchar::format_zero_padding#17 = 0 [phi:smc_get_version_text::@1->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1118] phi printf_uchar::format_min_length#17 = 0 [phi:smc_get_version_text::@1->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1118] phi printf_uchar::putc#17 = &snputc [phi:smc_get_version_text::@1->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1118] phi printf_uchar::format_radix#17 = DECIMAL [phi:smc_get_version_text::@1->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1118] phi printf_uchar::uvalue#17 = printf_uchar::uvalue#6 [phi:smc_get_version_text::@1->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [886] phi from smc_get_version_text::@1 to smc_get_version_text::@2 [phi:smc_get_version_text::@1->smc_get_version_text::@2]
    // smc_get_version_text::@2
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [887] call printf_str
    // [1054] phi from smc_get_version_text::@2 to printf_str [phi:smc_get_version_text::@2->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:smc_get_version_text::@2->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = smc_get_version_text::s [phi:smc_get_version_text::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_get_version_text::@3
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [888] printf_uchar::uvalue#7 = smc_get_version_text::major#2 -- vbum1=vbuz2 
    lda.z major
    sta printf_uchar.uvalue
    // [889] call printf_uchar
    // [1118] phi from smc_get_version_text::@3 to printf_uchar [phi:smc_get_version_text::@3->printf_uchar]
    // [1118] phi printf_uchar::format_zero_padding#17 = 0 [phi:smc_get_version_text::@3->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1118] phi printf_uchar::format_min_length#17 = 0 [phi:smc_get_version_text::@3->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1118] phi printf_uchar::putc#17 = &snputc [phi:smc_get_version_text::@3->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1118] phi printf_uchar::format_radix#17 = DECIMAL [phi:smc_get_version_text::@3->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1118] phi printf_uchar::uvalue#17 = printf_uchar::uvalue#7 [phi:smc_get_version_text::@3->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [890] phi from smc_get_version_text::@3 to smc_get_version_text::@4 [phi:smc_get_version_text::@3->smc_get_version_text::@4]
    // smc_get_version_text::@4
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [891] call printf_str
    // [1054] phi from smc_get_version_text::@4 to printf_str [phi:smc_get_version_text::@4->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:smc_get_version_text::@4->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = smc_get_version_text::s [phi:smc_get_version_text::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_get_version_text::@5
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [892] printf_uchar::uvalue#8 = smc_get_version_text::minor#2 -- vbum1=vbum2 
    lda minor
    sta printf_uchar.uvalue
    // [893] call printf_uchar
    // [1118] phi from smc_get_version_text::@5 to printf_uchar [phi:smc_get_version_text::@5->printf_uchar]
    // [1118] phi printf_uchar::format_zero_padding#17 = 0 [phi:smc_get_version_text::@5->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1118] phi printf_uchar::format_min_length#17 = 0 [phi:smc_get_version_text::@5->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1118] phi printf_uchar::putc#17 = &snputc [phi:smc_get_version_text::@5->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1118] phi printf_uchar::format_radix#17 = DECIMAL [phi:smc_get_version_text::@5->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1118] phi printf_uchar::uvalue#17 = printf_uchar::uvalue#8 [phi:smc_get_version_text::@5->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // smc_get_version_text::@6
    // sprintf(version_string, "%u.%u.%u", release, major, minor)
    // [894] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [895] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_get_version_text::@return
    // }
    // [897] return 
    rts
  .segment Data
    s: .text "."
    .byte 0
    .label release = check_status_roms_less.rom_chip
    .label minor = smc_supported_rom.return
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
// void display_info_smc(__mem() char info_status, __zp($c7) char *info_text)
display_info_smc: {
    .label y = $ce
    .label info_text = $c7
    // unsigned char x = wherex()
    // [899] call wherex
    jsr wherex
    // [900] wherex::return#10 = wherex::return#0
    // display_info_smc::@3
    // [901] display_info_smc::x#0 = wherex::return#10 -- vbum1=vbum2 
    lda wherex.return
    sta x
    // unsigned char y = wherey()
    // [902] call wherey
    jsr wherey
    // [903] wherey::return#10 = wherey::return#0
    // display_info_smc::@4
    // [904] display_info_smc::y#0 = wherey::return#10 -- vbuz1=vbum2 
    lda wherey.return
    sta.z y
    // status_smc = info_status
    // [905] status_smc#122 = display_info_smc::info_status#21 -- vbum1=vbum2 
    lda info_status
    sta status_smc
    // display_smc_led(status_color[info_status])
    // [906] display_smc_led::c#1 = status_color[display_info_smc::info_status#21] -- vbuz1=pbuc1_derefidx_vbum2 
    ldy info_status
    lda status_color,y
    sta.z display_smc_led.c
    // [907] call display_smc_led
    // [1989] phi from display_info_smc::@4 to display_smc_led [phi:display_info_smc::@4->display_smc_led]
    // [1989] phi display_smc_led::c#2 = display_smc_led::c#1 [phi:display_info_smc::@4->display_smc_led#0] -- register_copy 
    jsr display_smc_led
    // [908] phi from display_info_smc::@4 to display_info_smc::@5 [phi:display_info_smc::@4->display_info_smc::@5]
    // display_info_smc::@5
    // gotoxy(INFO_X, INFO_Y)
    // [909] call gotoxy
    // [778] phi from display_info_smc::@5 to gotoxy [phi:display_info_smc::@5->gotoxy]
    // [778] phi gotoxy::y#33 = $11 [phi:display_info_smc::@5->gotoxy#0] -- vbum1=vbuc1 
    lda #$11
    sta gotoxy.y
    // [778] phi gotoxy::x#33 = 4 [phi:display_info_smc::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // [910] phi from display_info_smc::@5 to display_info_smc::@6 [phi:display_info_smc::@5->display_info_smc::@6]
    // display_info_smc::@6
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [911] call printf_str
    // [1054] phi from display_info_smc::@6 to printf_str [phi:display_info_smc::@6->printf_str]
    // [1054] phi printf_str::putc#75 = &cputc [phi:display_info_smc::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = display_info_smc::s [phi:display_info_smc::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@7
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [912] display_info_smc::$9 = display_info_smc::info_status#21 << 1 -- vbum1=vbum1_rol_1 
    asl display_info_smc__9
    // [913] printf_string::str#3 = status_text[display_info_smc::$9] -- pbuz1=qbuc1_derefidx_vbum2 
    ldy display_info_smc__9
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [914] call printf_string
    // [1227] phi from display_info_smc::@7 to printf_string [phi:display_info_smc::@7->printf_string]
    // [1227] phi printf_string::putc#25 = &cputc [phi:display_info_smc::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1227] phi printf_string::str#25 = printf_string::str#3 [phi:display_info_smc::@7->printf_string#1] -- register_copy 
    // [1227] phi printf_string::format_justify_left#25 = 1 [phi:display_info_smc::@7->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1227] phi printf_string::format_min_length#25 = 9 [phi:display_info_smc::@7->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [915] phi from display_info_smc::@7 to display_info_smc::@8 [phi:display_info_smc::@7->display_info_smc::@8]
    // display_info_smc::@8
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [916] call printf_str
    // [1054] phi from display_info_smc::@8 to printf_str [phi:display_info_smc::@8->printf_str]
    // [1054] phi printf_str::putc#75 = &cputc [phi:display_info_smc::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = display_info_smc::s1 [phi:display_info_smc::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // [917] phi from display_info_smc::@8 to display_info_smc::@9 [phi:display_info_smc::@8->display_info_smc::@9]
    // display_info_smc::@9
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [918] call printf_string
    // [1227] phi from display_info_smc::@9 to printf_string [phi:display_info_smc::@9->printf_string]
    // [1227] phi printf_string::putc#25 = &cputc [phi:display_info_smc::@9->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1227] phi printf_string::str#25 = smc_version_text [phi:display_info_smc::@9->printf_string#1] -- pbuz1=pbuc1 
    lda #<smc_version_text
    sta.z printf_string.str
    lda #>smc_version_text
    sta.z printf_string.str+1
    // [1227] phi printf_string::format_justify_left#25 = 1 [phi:display_info_smc::@9->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1227] phi printf_string::format_min_length#25 = 8 [phi:display_info_smc::@9->printf_string#3] -- vbum1=vbuc1 
    lda #8
    sta printf_string.format_min_length
    jsr printf_string
    // [919] phi from display_info_smc::@9 to display_info_smc::@10 [phi:display_info_smc::@9->display_info_smc::@10]
    // display_info_smc::@10
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [920] call printf_str
    // [1054] phi from display_info_smc::@10 to printf_str [phi:display_info_smc::@10->printf_str]
    // [1054] phi printf_str::putc#75 = &cputc [phi:display_info_smc::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = display_info_smc::s2 [phi:display_info_smc::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@11
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [921] printf_uint::uvalue#0 = smc_bootloader#14 -- vwum1=vwum2 
    lda smc_bootloader_1
    sta printf_uint.uvalue
    lda smc_bootloader_1+1
    sta printf_uint.uvalue+1
    // [922] call printf_uint
    // [1835] phi from display_info_smc::@11 to printf_uint [phi:display_info_smc::@11->printf_uint]
    // [1835] phi printf_uint::format_zero_padding#10 = 0 [phi:display_info_smc::@11->printf_uint#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uint.format_zero_padding
    // [1835] phi printf_uint::format_min_length#10 = 0 [phi:display_info_smc::@11->printf_uint#1] -- vbum1=vbuc1 
    sta printf_uint.format_min_length
    // [1835] phi printf_uint::putc#10 = &cputc [phi:display_info_smc::@11->printf_uint#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uint.putc
    lda #>cputc
    sta.z printf_uint.putc+1
    // [1835] phi printf_uint::format_radix#10 = DECIMAL [phi:display_info_smc::@11->printf_uint#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uint.format_radix
    // [1835] phi printf_uint::uvalue#10 = printf_uint::uvalue#0 [phi:display_info_smc::@11->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [923] phi from display_info_smc::@11 to display_info_smc::@12 [phi:display_info_smc::@11->display_info_smc::@12]
    // display_info_smc::@12
    // printf("SMC  %-9s ATTiny %-8s BL:%u ", status_text[info_status], smc_version_text, smc_bootloader)
    // [924] call printf_str
    // [1054] phi from display_info_smc::@12 to printf_str [phi:display_info_smc::@12->printf_str]
    // [1054] phi printf_str::putc#75 = &cputc [phi:display_info_smc::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = s [phi:display_info_smc::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s
    sta.z printf_str.s
    lda #>@s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_smc::@13
    // if(info_text)
    // [925] if((char *)0==display_info_smc::info_text#21) goto display_info_smc::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // [926] phi from display_info_smc::@13 to display_info_smc::@2 [phi:display_info_smc::@13->display_info_smc::@2]
    // display_info_smc::@2
    // gotoxy(INFO_X+64-28, INFO_Y)
    // [927] call gotoxy
    // [778] phi from display_info_smc::@2 to gotoxy [phi:display_info_smc::@2->gotoxy]
    // [778] phi gotoxy::y#33 = $11 [phi:display_info_smc::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #$11
    sta gotoxy.y
    // [778] phi gotoxy::x#33 = 4+$40-$1c [phi:display_info_smc::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #4+$40-$1c
    sta gotoxy.x
    jsr gotoxy
    // display_info_smc::@14
    // printf("%-25s", info_text)
    // [928] printf_string::str#5 = display_info_smc::info_text#21 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [929] call printf_string
    // [1227] phi from display_info_smc::@14 to printf_string [phi:display_info_smc::@14->printf_string]
    // [1227] phi printf_string::putc#25 = &cputc [phi:display_info_smc::@14->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1227] phi printf_string::str#25 = printf_string::str#5 [phi:display_info_smc::@14->printf_string#1] -- register_copy 
    // [1227] phi printf_string::format_justify_left#25 = 1 [phi:display_info_smc::@14->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1227] phi printf_string::format_min_length#25 = $19 [phi:display_info_smc::@14->printf_string#3] -- vbum1=vbuc1 
    lda #$19
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_smc::@1
  __b1:
    // gotoxy(x, y)
    // [930] gotoxy::x#14 = display_info_smc::x#0 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [931] gotoxy::y#14 = display_info_smc::y#0 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [932] call gotoxy
    // [778] phi from display_info_smc::@1 to gotoxy [phi:display_info_smc::@1->gotoxy]
    // [778] phi gotoxy::y#33 = gotoxy::y#14 [phi:display_info_smc::@1->gotoxy#0] -- register_copy 
    // [778] phi gotoxy::x#33 = gotoxy::x#14 [phi:display_info_smc::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_smc::@return
    // }
    // [933] return 
    rts
  .segment Data
    s: .text "SMC  "
    .byte 0
    s1: .text " ATTiny "
    .byte 0
    s2: .text " BL:"
    .byte 0
    .label display_info_smc__9 = main.check_status_smc18_main__0
    .label x = fclose.fclose__1
    .label info_status = main.check_status_smc18_main__0
}
.segment Code
  // rom_detect
rom_detect: {
    .const bank_set_brom1_bank = 4
    .label rom_detect__9 = $ce
    .label rom_detect__14 = $77
    .label rom_detect__15 = $dc
    .label rom_detect__18 = $29
    .label rom_detect__21 = $dd
    .label rom_detect__24 = $ed
    .label rom_detect_address = $c3
    // [935] phi from rom_detect to rom_detect::@1 [phi:rom_detect->rom_detect::@1]
    // [935] phi rom_detect::rom_chip#10 = 0 [phi:rom_detect->rom_detect::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // [935] phi rom_detect::rom_detect_address#10 = 0 [phi:rom_detect->rom_detect::@1#1] -- vduz1=vduc1 
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
    // [936] if(rom_detect::rom_detect_address#10<8*$80000) goto rom_detect::@2 -- vduz1_lt_vduc1_then_la1 
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
    // [937] return 
    rts
    // rom_detect::@2
  __b2:
    // rom_manufacturer_ids[rom_chip] = 0
    // [938] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_device_ids[rom_chip] = 0
    // [939] rom_device_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta rom_device_ids,y
    // rom_unlock(rom_detect_address + 0x05555, 0x90)
    // [940] rom_unlock::address#2 = rom_detect::rom_detect_address#10 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [941] call rom_unlock
    // [2043] phi from rom_detect::@2 to rom_unlock [phi:rom_detect::@2->rom_unlock]
    // [2043] phi rom_unlock::unlock_code#5 = $90 [phi:rom_detect::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$90
    sta.z rom_unlock.unlock_code
    // [2043] phi rom_unlock::address#5 = rom_unlock::address#2 [phi:rom_detect::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_detect::@12
    // rom_read_byte(rom_detect_address)
    // [942] rom_read_byte::address#0 = rom_detect::rom_detect_address#10 -- vdum1=vduz2 
    lda.z rom_detect_address
    sta rom_read_byte.address
    lda.z rom_detect_address+1
    sta rom_read_byte.address+1
    lda.z rom_detect_address+2
    sta rom_read_byte.address+2
    lda.z rom_detect_address+3
    sta rom_read_byte.address+3
    // [943] call rom_read_byte
    // [2053] phi from rom_detect::@12 to rom_read_byte [phi:rom_detect::@12->rom_read_byte]
    // [2053] phi rom_read_byte::address#2 = rom_read_byte::address#0 [phi:rom_detect::@12->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(rom_detect_address)
    // [944] rom_read_byte::return#2 = rom_read_byte::return#0
    // rom_detect::@13
    // [945] rom_detect::$3 = rom_read_byte::return#2
    // rom_manufacturer_ids[rom_chip] = rom_read_byte(rom_detect_address)
    // [946] rom_manufacturer_ids[rom_detect::rom_chip#10] = rom_detect::$3 -- pbuc1_derefidx_vbum1=vbum2 
    lda rom_detect__3
    ldy rom_chip
    sta rom_manufacturer_ids,y
    // rom_read_byte(rom_detect_address + 1)
    // [947] rom_read_byte::address#1 = rom_detect::rom_detect_address#10 + 1 -- vdum1=vduz2_plus_1 
    lda.z rom_detect_address
    clc
    adc #1
    sta rom_read_byte.address
    lda.z rom_detect_address+1
    adc #0
    sta rom_read_byte.address+1
    lda.z rom_detect_address+2
    adc #0
    sta rom_read_byte.address+2
    lda.z rom_detect_address+3
    adc #0
    sta rom_read_byte.address+3
    // [948] call rom_read_byte
    // [2053] phi from rom_detect::@13 to rom_read_byte [phi:rom_detect::@13->rom_read_byte]
    // [2053] phi rom_read_byte::address#2 = rom_read_byte::address#1 [phi:rom_detect::@13->rom_read_byte#0] -- register_copy 
    jsr rom_read_byte
    // rom_read_byte(rom_detect_address + 1)
    // [949] rom_read_byte::return#3 = rom_read_byte::return#0
    // rom_detect::@14
    // [950] rom_detect::$5 = rom_read_byte::return#3
    // rom_device_ids[rom_chip] = rom_read_byte(rom_detect_address + 1)
    // [951] rom_device_ids[rom_detect::rom_chip#10] = rom_detect::$5 -- pbuc1_derefidx_vbum1=vbum2 
    lda rom_detect__5
    ldy rom_chip
    sta rom_device_ids,y
    // rom_unlock(rom_detect_address + 0x05555, 0xF0)
    // [952] rom_unlock::address#3 = rom_detect::rom_detect_address#10 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [953] call rom_unlock
    // [2043] phi from rom_detect::@14 to rom_unlock [phi:rom_detect::@14->rom_unlock]
    // [2043] phi rom_unlock::unlock_code#5 = $f0 [phi:rom_detect::@14->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$f0
    sta.z rom_unlock.unlock_code
    // [2043] phi rom_unlock::address#5 = rom_unlock::address#3 [phi:rom_detect::@14->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_detect::bank_set_brom1
    // BROM = bank
    // [954] BROM = rom_detect::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // rom_detect::@11
    // rom_chip*3
    // [955] rom_detect::$14 = rom_detect::rom_chip#10 << 1 -- vbuz1=vbum2_rol_1 
    lda rom_chip
    asl
    sta.z rom_detect__14
    // [956] rom_detect::$9 = rom_detect::$14 + rom_detect::rom_chip#10 -- vbuz1=vbuz2_plus_vbum3 
    lda rom_chip
    clc
    adc.z rom_detect__14
    sta.z rom_detect__9
    // gotoxy(rom_chip*3+40, 1)
    // [957] gotoxy::x#26 = rom_detect::$9 + $28 -- vbum1=vbuz2_plus_vbuc1 
    lda #$28
    clc
    adc.z rom_detect__9
    sta gotoxy.x
    // [958] call gotoxy
    // [778] phi from rom_detect::@11 to gotoxy [phi:rom_detect::@11->gotoxy]
    // [778] phi gotoxy::y#33 = 1 [phi:rom_detect::@11->gotoxy#0] -- vbum1=vbuc1 
    lda #1
    sta gotoxy.y
    // [778] phi gotoxy::x#33 = gotoxy::x#26 [phi:rom_detect::@11->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_detect::@15
    // printf("%02x", rom_device_ids[rom_chip])
    // [959] printf_uchar::uvalue#13 = rom_device_ids[rom_detect::rom_chip#10] -- vbum1=pbuc1_derefidx_vbum2 
    ldy rom_chip
    lda rom_device_ids,y
    sta printf_uchar.uvalue
    // [960] call printf_uchar
    // [1118] phi from rom_detect::@15 to printf_uchar [phi:rom_detect::@15->printf_uchar]
    // [1118] phi printf_uchar::format_zero_padding#17 = 1 [phi:rom_detect::@15->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1118] phi printf_uchar::format_min_length#17 = 2 [phi:rom_detect::@15->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1118] phi printf_uchar::putc#17 = &cputc [phi:rom_detect::@15->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1118] phi printf_uchar::format_radix#17 = HEXADECIMAL [phi:rom_detect::@15->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1118] phi printf_uchar::uvalue#17 = printf_uchar::uvalue#13 [phi:rom_detect::@15->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // rom_detect::@16
    // case SST39SF010A:
    //             rom_device_names[rom_chip] = "f010a";
    //             rom_size_strings[rom_chip] = "128";
    //             rom_sizes[rom_chip] = 128 * 1024;
    //             break;
    // [961] if(rom_device_ids[rom_detect::rom_chip#10]==$b5) goto rom_detect::@3 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
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
    // [962] if(rom_device_ids[rom_detect::rom_chip#10]==$b6) goto rom_detect::@4 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
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
    // [963] if(rom_device_ids[rom_detect::rom_chip#10]==$b7) goto rom_detect::@5 -- pbuc1_derefidx_vbum1_eq_vbuc2_then_la1 
    lda rom_device_ids,y
    cmp #$b7
    beq __b5
    // rom_detect::@6
    // rom_manufacturer_ids[rom_chip] = 0
    // [964] rom_manufacturer_ids[rom_detect::rom_chip#10] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    sta rom_manufacturer_ids,y
    // rom_device_names[rom_chip] = "----"
    // [965] rom_device_names[rom_detect::$14] = rom_detect::$31 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__14
    lda #<rom_detect__31
    sta rom_device_names,y
    lda #>rom_detect__31
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "000"
    // [966] rom_size_strings[rom_detect::$14] = rom_detect::$32 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__32
    sta rom_size_strings,y
    lda #>rom_detect__32
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 0
    // [967] rom_detect::$24 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__24
    // [968] rom_sizes[rom_detect::$24] = 0 -- pduc1_derefidx_vbuz1=vbuc2 
    tay
    lda #0
    sta rom_sizes,y
    sta rom_sizes+1,y
    sta rom_sizes+2,y
    sta rom_sizes+3,y
    // rom_device_ids[rom_chip] = UNKNOWN
    // [969] rom_device_ids[rom_detect::rom_chip#10] = $55 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #$55
    ldy rom_chip
    sta rom_device_ids,y
    // rom_detect::@7
  __b7:
    // rom_chip++;
    // [970] rom_detect::rom_chip#1 = ++ rom_detect::rom_chip#10 -- vbum1=_inc_vbum1 
    inc rom_chip
    // rom_detect::@8
    // rom_detect_address += 0x80000
    // [971] rom_detect::rom_detect_address#1 = rom_detect::rom_detect_address#10 + $80000 -- vduz1=vduz1_plus_vduc1 
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
    // [935] phi from rom_detect::@8 to rom_detect::@1 [phi:rom_detect::@8->rom_detect::@1]
    // [935] phi rom_detect::rom_chip#10 = rom_detect::rom_chip#1 [phi:rom_detect::@8->rom_detect::@1#0] -- register_copy 
    // [935] phi rom_detect::rom_detect_address#10 = rom_detect::rom_detect_address#1 [phi:rom_detect::@8->rom_detect::@1#1] -- register_copy 
    jmp __b1
    // rom_detect::@5
  __b5:
    // rom_device_names[rom_chip] = "f040"
    // [972] rom_device_names[rom_detect::$14] = rom_detect::$29 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__14
    lda #<rom_detect__29
    sta rom_device_names,y
    lda #>rom_detect__29
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "512"
    // [973] rom_size_strings[rom_detect::$14] = rom_detect::$30 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__30
    sta rom_size_strings,y
    lda #>rom_detect__30
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 512 * 1024
    // [974] rom_detect::$21 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__21
    // [975] rom_sizes[rom_detect::$21] = (unsigned long)$200*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
    // [976] rom_device_names[rom_detect::$14] = rom_detect::$27 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__14
    lda #<rom_detect__27
    sta rom_device_names,y
    lda #>rom_detect__27
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "256"
    // [977] rom_size_strings[rom_detect::$14] = rom_detect::$28 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__28
    sta rom_size_strings,y
    lda #>rom_detect__28
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 256 * 1024
    // [978] rom_detect::$18 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__18
    // [979] rom_sizes[rom_detect::$18] = (unsigned long)$100*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
    // [980] rom_device_names[rom_detect::$14] = rom_detect::$25 -- qbuc1_derefidx_vbuz1=pbuc2 
    ldy.z rom_detect__14
    lda #<rom_detect__25
    sta rom_device_names,y
    lda #>rom_detect__25
    sta rom_device_names+1,y
    // rom_size_strings[rom_chip] = "128"
    // [981] rom_size_strings[rom_detect::$14] = rom_detect::$26 -- qbuc1_derefidx_vbuz1=pbuc2 
    lda #<rom_detect__26
    sta rom_size_strings,y
    lda #>rom_detect__26
    sta rom_size_strings+1,y
    // rom_sizes[rom_chip] = 128 * 1024
    // [982] rom_detect::$15 = rom_detect::rom_chip#10 << 2 -- vbuz1=vbum2_rol_2 
    lda rom_chip
    asl
    asl
    sta.z rom_detect__15
    // [983] rom_sizes[rom_detect::$15] = (unsigned long)$80*$400 -- pduc1_derefidx_vbuz1=vduc2 
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
    .label rom_detect__3 = fclose.fclose__1
    .label rom_detect__5 = fclose.fclose__1
    .label rom_chip = main.check_status_vera4_main__0
}
.segment Code
  // display_chip_rom
/**
 * @brief Print all ROM chips.
 * 
 */
display_chip_rom: {
    .label display_chip_rom__4 = $77
    .label display_chip_rom__6 = $cc
    .label display_chip_rom__11 = $ed
    .label display_chip_rom__12 = $ed
    // [985] phi from display_chip_rom to display_chip_rom::@1 [phi:display_chip_rom->display_chip_rom::@1]
    // [985] phi display_chip_rom::r#2 = 0 [phi:display_chip_rom->display_chip_rom::@1#0] -- vbum1=vbuc1 
    lda #0
    sta r
    // display_chip_rom::@1
  __b1:
    // for (unsigned char r = 0; r < 8; r++)
    // [986] if(display_chip_rom::r#2<8) goto display_chip_rom::@2 -- vbum1_lt_vbuc1_then_la1 
    lda r
    cmp #8
    bcc __b2
    // display_chip_rom::@return
    // }
    // [987] return 
    rts
    // [988] phi from display_chip_rom::@1 to display_chip_rom::@2 [phi:display_chip_rom::@1->display_chip_rom::@2]
    // display_chip_rom::@2
  __b2:
    // strcpy(rom, "ROM  ")
    // [989] call strcpy
    // [863] phi from display_chip_rom::@2 to strcpy [phi:display_chip_rom::@2->strcpy]
    // [863] phi strcpy::dst#0 = display_chip_rom::rom [phi:display_chip_rom::@2->strcpy#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z strcpy.dst
    lda #>rom
    sta.z strcpy.dst+1
    // [863] phi strcpy::src#0 = display_chip_rom::source [phi:display_chip_rom::@2->strcpy#1] -- pbuz1=pbuc1 
    lda #<source
    sta.z strcpy.src
    lda #>source
    sta.z strcpy.src+1
    jsr strcpy
    // display_chip_rom::@5
    // strcat(rom, rom_size_strings[r])
    // [990] display_chip_rom::$11 = display_chip_rom::r#2 << 1 -- vbuz1=vbum2_rol_1 
    lda r
    asl
    sta.z display_chip_rom__11
    // [991] strcat::source#0 = rom_size_strings[display_chip_rom::$11] -- pbuz1=qbuc1_derefidx_vbuz2 
    tay
    lda rom_size_strings,y
    sta.z strcat.source
    lda rom_size_strings+1,y
    sta.z strcat.source+1
    // [992] call strcat
    // [2065] phi from display_chip_rom::@5 to strcat [phi:display_chip_rom::@5->strcat]
    jsr strcat
    // display_chip_rom::@6
    // if(r)
    // [993] if(0==display_chip_rom::r#2) goto display_chip_rom::@3 -- 0_eq_vbum1_then_la1 
    lda r
    beq __b3
    // display_chip_rom::@4
    // r+'0'
    // [994] display_chip_rom::$4 = display_chip_rom::r#2 + '0' -- vbuz1=vbum2_plus_vbuc1 
    lda #'0'
    clc
    adc r
    sta.z display_chip_rom__4
    // *(rom+3) = r+'0'
    // [995] *(display_chip_rom::rom+3) = display_chip_rom::$4 -- _deref_pbuc1=vbuz1 
    sta rom+3
    // display_chip_rom::@3
  __b3:
    // display_rom_led(r, GREY)
    // [996] display_rom_led::chip#0 = display_chip_rom::r#2 -- vbuz1=vbum2 
    lda r
    sta.z display_rom_led.chip
    // [997] call display_rom_led
    // [2077] phi from display_chip_rom::@3 to display_rom_led [phi:display_chip_rom::@3->display_rom_led]
    // [2077] phi display_rom_led::c#2 = GREY [phi:display_chip_rom::@3->display_rom_led#0] -- vbuz1=vbuc1 
    lda #GREY
    sta.z display_rom_led.c
    // [2077] phi display_rom_led::chip#2 = display_rom_led::chip#0 [phi:display_chip_rom::@3->display_rom_led#1] -- register_copy 
    jsr display_rom_led
    // display_chip_rom::@7
    // r*6
    // [998] display_chip_rom::$12 = display_chip_rom::$11 + display_chip_rom::r#2 -- vbuz1=vbuz1_plus_vbum2 
    lda r
    clc
    adc.z display_chip_rom__12
    sta.z display_chip_rom__12
    // [999] display_chip_rom::$6 = display_chip_rom::$12 << 1 -- vbuz1=vbuz2_rol_1 
    asl
    sta.z display_chip_rom__6
    // display_print_chip(CHIP_ROM_X+r*6, CHIP_ROM_Y+2, CHIP_ROM_W, rom)
    // [1000] display_print_chip::x#2 = $14 + display_chip_rom::$6 -- vbuz1=vbuc1_plus_vbuz1 
    lda #$14
    clc
    adc.z display_print_chip.x
    sta.z display_print_chip.x
    // [1001] call display_print_chip
    // [1995] phi from display_chip_rom::@7 to display_print_chip [phi:display_chip_rom::@7->display_print_chip]
    // [1995] phi display_print_chip::text#11 = display_chip_rom::rom [phi:display_chip_rom::@7->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<rom
    sta.z display_print_chip.text_2
    lda #>rom
    sta.z display_print_chip.text_2+1
    // [1995] phi display_print_chip::w#10 = 3 [phi:display_chip_rom::@7->display_print_chip#1] -- vbum1=vbuc1 
    lda #3
    sta display_print_chip.w
    // [1995] phi display_print_chip::x#10 = display_print_chip::x#2 [phi:display_chip_rom::@7->display_print_chip#2] -- register_copy 
    jsr display_print_chip
    // display_chip_rom::@8
    // for (unsigned char r = 0; r < 8; r++)
    // [1002] display_chip_rom::r#1 = ++ display_chip_rom::r#2 -- vbum1=_inc_vbum1 
    inc r
    // [985] phi from display_chip_rom::@8 to display_chip_rom::@1 [phi:display_chip_rom::@8->display_chip_rom::@1]
    // [985] phi display_chip_rom::r#2 = display_chip_rom::r#1 [phi:display_chip_rom::@8->display_chip_rom::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    rom: .fill $10, 0
    source: .text "ROM  "
    .byte 0
    .label r = check_status_roms.return
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
// __mem() char smc_supported_rom(__zp($38) char rom_release)
smc_supported_rom: {
    .label i = $e7
    .label rom_release = $38
    // [1004] phi from smc_supported_rom to smc_supported_rom::@1 [phi:smc_supported_rom->smc_supported_rom::@1]
    // [1004] phi smc_supported_rom::i#2 = $1f [phi:smc_supported_rom->smc_supported_rom::@1#0] -- vbuz1=vbuc1 
    lda #$1f
    sta.z i
    // smc_supported_rom::@1
  __b1:
    // for(unsigned char i=31; i>3; i--)
    // [1005] if(smc_supported_rom::i#2>=3+1) goto smc_supported_rom::@2 -- vbuz1_ge_vbuc1_then_la1 
    lda.z i
    cmp #3+1
    bcs __b2
    // [1007] phi from smc_supported_rom::@1 to smc_supported_rom::@return [phi:smc_supported_rom::@1->smc_supported_rom::@return]
    // [1007] phi smc_supported_rom::return#2 = 0 [phi:smc_supported_rom::@1->smc_supported_rom::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    rts
    // smc_supported_rom::@2
  __b2:
    // if(smc_file_header[i] == rom_release)
    // [1006] if(smc_file_header[smc_supported_rom::i#2]!=smc_supported_rom::rom_release#0) goto smc_supported_rom::@3 -- pbuc1_derefidx_vbuz1_neq_vbuz2_then_la1 
    lda.z rom_release
    ldy.z i
    cmp smc_file_header,y
    bne __b3
    // [1007] phi from smc_supported_rom::@2 to smc_supported_rom::@return [phi:smc_supported_rom::@2->smc_supported_rom::@return]
    // [1007] phi smc_supported_rom::return#2 = 1 [phi:smc_supported_rom::@2->smc_supported_rom::@return#0] -- vbum1=vbuc1 
    lda #1
    sta return
    // smc_supported_rom::@return
    // }
    // [1008] return 
    rts
    // smc_supported_rom::@3
  __b3:
    // for(unsigned char i=31; i>3; i--)
    // [1009] smc_supported_rom::i#1 = -- smc_supported_rom::i#2 -- vbuz1=_dec_vbuz1 
    dec.z i
    // [1004] phi from smc_supported_rom::@3 to smc_supported_rom::@1 [phi:smc_supported_rom::@3->smc_supported_rom::@1]
    // [1004] phi smc_supported_rom::i#2 = smc_supported_rom::i#1 [phi:smc_supported_rom::@3->smc_supported_rom::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    return: .byte 0
}
.segment Code
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
    .label strncmp__0 = $dd
    .label s1 = $c7
    .label s2 = $aa
    // [1011] phi from strncmp to strncmp::@1 [phi:strncmp->strncmp::@1]
    // [1011] phi strncmp::n#2 = 7 [phi:strncmp->strncmp::@1#0] -- vwum1=vbuc1 
    lda #<7
    sta n
    lda #>7
    sta n+1
    // [1011] phi strncmp::s2#2 = rom_file_github [phi:strncmp->strncmp::@1#1] -- pbuz1=pbuc1 
    lda #<rom_file_github
    sta.z s2
    lda #>rom_file_github
    sta.z s2+1
    // [1011] phi strncmp::s1#2 = rom_github [phi:strncmp->strncmp::@1#2] -- pbuz1=pbuc1 
    lda #<rom_github
    sta.z s1
    lda #>rom_github
    sta.z s1+1
    // strncmp::@1
  __b1:
    // while(*s1==*s2)
    // [1012] if(*strncmp::s1#2==*strncmp::s2#2) goto strncmp::@2 -- _deref_pbuz1_eq__deref_pbuz2_then_la1 
    ldy #0
    lda (s1),y
    cmp (s2),y
    beq __b2
    // strncmp::@3
    // *s1-*s2
    // [1013] strncmp::$0 = *strncmp::s1#2 - *strncmp::s2#2 -- vbuz1=_deref_pbuz2_minus__deref_pbuz3 
    lda (s1),y
    sec
    sbc (s2),y
    sta.z strncmp__0
    // return (int)(signed char)(*s1-*s2);
    // [1014] strncmp::return#0 = (int)(signed char)strncmp::$0 -- vwsm1=_sword_vbsz2 
    sta return
    ora #$7f
    bmi !+
    tya
  !:
    sta return+1
    // [1015] phi from strncmp::@3 to strncmp::@return [phi:strncmp::@3->strncmp::@return]
    // [1015] phi strncmp::return#2 = strncmp::return#0 [phi:strncmp::@3->strncmp::@return#0] -- register_copy 
    rts
    // [1015] phi from strncmp::@2 strncmp::@5 to strncmp::@return [phi:strncmp::@2/strncmp::@5->strncmp::@return]
  __b3:
    // [1015] phi strncmp::return#2 = 0 [phi:strncmp::@2/strncmp::@5->strncmp::@return#0] -- vwsm1=vbsc1 
    lda #<0
    sta return
    sta return+1
    // strncmp::@return
    // }
    // [1016] return 
    rts
    // strncmp::@2
  __b2:
    // n--;
    // [1017] strncmp::n#0 = -- strncmp::n#2 -- vwum1=_dec_vwum1 
    lda n
    bne !+
    dec n+1
  !:
    dec n
    // if(*s1==0 || n==0)
    // [1018] if(*strncmp::s1#2==0) goto strncmp::@return -- _deref_pbuz1_eq_0_then_la1 
    ldy #0
    lda (s1),y
    cmp #0
    beq __b3
    // strncmp::@5
    // [1019] if(strncmp::n#0==0) goto strncmp::@return -- vwum1_eq_0_then_la1 
    lda n
    ora n+1
    beq __b3
    // strncmp::@4
    // s1++;
    // [1020] strncmp::s1#1 = ++ strncmp::s1#2 -- pbuz1=_inc_pbuz1 
    inc.z s1
    bne !+
    inc.z s1+1
  !:
    // s2++;
    // [1021] strncmp::s2#1 = ++ strncmp::s2#2 -- pbuz1=_inc_pbuz1 
    inc.z s2
    bne !+
    inc.z s2+1
  !:
    // [1011] phi from strncmp::@4 to strncmp::@1 [phi:strncmp::@4->strncmp::@1]
    // [1011] phi strncmp::n#2 = strncmp::n#0 [phi:strncmp::@4->strncmp::@1#0] -- register_copy 
    // [1011] phi strncmp::s2#2 = strncmp::s2#1 [phi:strncmp::@4->strncmp::@1#1] -- register_copy 
    // [1011] phi strncmp::s1#2 = strncmp::s1#1 [phi:strncmp::@4->strncmp::@1#2] -- register_copy 
    jmp __b1
  .segment Data
    n: .word 0
    return: .word 0
}
.segment Code
  // check_status_roms
/**
 * @brief Check the status of any of the ROMs.
 * 
 * @param status The status to be checked.
 * @return unsigned char true if one chip is equal to the status.
 */
// __mem() char check_status_roms(__mem() char status)
check_status_roms: {
    .label check_status_rom1_check_status_roms__0 = $29
    .label check_status_rom1_return = $29
    // [1023] phi from check_status_roms to check_status_roms::@1 [phi:check_status_roms->check_status_roms::@1]
    // [1023] phi check_status_roms::rom_chip#2 = 0 [phi:check_status_roms->check_status_roms::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // check_status_roms::@1
  __b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [1024] if(check_status_roms::rom_chip#2<8) goto check_status_roms::check_status_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcc check_status_rom1
    // [1025] phi from check_status_roms::@1 to check_status_roms::@return [phi:check_status_roms::@1->check_status_roms::@return]
    // [1025] phi check_status_roms::return#2 = 0 [phi:check_status_roms::@1->check_status_roms::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    // check_status_roms::@return
    // }
    // [1026] return 
    rts
    // check_status_roms::check_status_rom1
  check_status_rom1:
    // status_rom[rom_chip] == status
    // [1027] check_status_roms::check_status_rom1_$0 = status_rom[check_status_roms::rom_chip#2] == check_status_roms::status#6 -- vboz1=pbuc1_derefidx_vbum2_eq_vbum3 
    lda status
    ldy rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_rom1_check_status_roms__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [1028] check_status_roms::check_status_rom1_return#0 = (char)check_status_roms::check_status_rom1_$0
    // check_status_roms::@3
    // if(check_status_rom(rom_chip, status))
    // [1029] if(0==check_status_roms::check_status_rom1_return#0) goto check_status_roms::@2 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_rom1_return
    beq __b2
    // [1025] phi from check_status_roms::@3 to check_status_roms::@return [phi:check_status_roms::@3->check_status_roms::@return]
    // [1025] phi check_status_roms::return#2 = 1 [phi:check_status_roms::@3->check_status_roms::@return#0] -- vbum1=vbuc1 
    lda #1
    sta return
    rts
    // check_status_roms::@2
  __b2:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [1030] check_status_roms::rom_chip#1 = ++ check_status_roms::rom_chip#2 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [1023] phi from check_status_roms::@2 to check_status_roms::@1 [phi:check_status_roms::@2->check_status_roms::@1]
    // [1023] phi check_status_roms::rom_chip#2 = check_status_roms::rom_chip#1 [phi:check_status_roms::@2->check_status_roms::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    .label rom_chip = main.check_status_vera4_main__0
    return: .byte 0
    .label status = main.check_status_smc18_main__0
}
.segment Code
  // clrscr
// clears the screen and moves the cursor to the upper left-hand corner of the screen.
clrscr: {
    .label clrscr__0 = $dc
    .label clrscr__1 = $38
    .label clrscr__2 = $45
    // unsigned int line_text = __conio.mapbase_offset
    // [1031] clrscr::line_text#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta line_text
    lda __conio+3+1
    sta line_text+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [1032] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // __conio.mapbase_bank | VERA_INC_1
    // [1033] clrscr::$0 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clrscr__0
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [1034] *VERA_ADDRX_H = clrscr::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // unsigned char l = __conio.mapheight
    // [1035] clrscr::l#0 = *((char *)&__conio+9) -- vbum1=_deref_pbuc1 
    lda __conio+9
    sta l
    // [1036] phi from clrscr clrscr::@3 to clrscr::@1 [phi:clrscr/clrscr::@3->clrscr::@1]
    // [1036] phi clrscr::l#4 = clrscr::l#0 [phi:clrscr/clrscr::@3->clrscr::@1#0] -- register_copy 
    // [1036] phi clrscr::ch#0 = clrscr::line_text#0 [phi:clrscr/clrscr::@3->clrscr::@1#1] -- register_copy 
    // clrscr::@1
  __b1:
    // BYTE0(ch)
    // [1037] clrscr::$1 = byte0  clrscr::ch#0 -- vbuz1=_byte0_vwum2 
    lda ch
    sta.z clrscr__1
    // *VERA_ADDRX_L = BYTE0(ch)
    // [1038] *VERA_ADDRX_L = clrscr::$1 -- _deref_pbuc1=vbuz1 
    // Set address
    sta VERA_ADDRX_L
    // BYTE1(ch)
    // [1039] clrscr::$2 = byte1  clrscr::ch#0 -- vbuz1=_byte1_vwum2 
    lda ch+1
    sta.z clrscr__2
    // *VERA_ADDRX_M = BYTE1(ch)
    // [1040] *VERA_ADDRX_M = clrscr::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // unsigned char c = __conio.mapwidth+1
    // [1041] clrscr::c#0 = *((char *)&__conio+8) + 1 -- vbum1=_deref_pbuc1_plus_1 
    lda __conio+8
    inc
    sta c
    // [1042] phi from clrscr::@1 clrscr::@2 to clrscr::@2 [phi:clrscr::@1/clrscr::@2->clrscr::@2]
    // [1042] phi clrscr::c#2 = clrscr::c#0 [phi:clrscr::@1/clrscr::@2->clrscr::@2#0] -- register_copy 
    // clrscr::@2
  __b2:
    // *VERA_DATA0 = ' '
    // [1043] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [1044] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [1045] clrscr::c#1 = -- clrscr::c#2 -- vbum1=_dec_vbum1 
    dec c
    // while(c)
    // [1046] if(0!=clrscr::c#1) goto clrscr::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // clrscr::@3
    // line_text += __conio.rowskip
    // [1047] clrscr::line_text#1 = clrscr::ch#0 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda line_text
    adc __conio+$a
    sta line_text
    lda line_text+1
    adc __conio+$a+1
    sta line_text+1
    // l--;
    // [1048] clrscr::l#1 = -- clrscr::l#4 -- vbum1=_dec_vbum1 
    dec l
    // while(l)
    // [1049] if(0!=clrscr::l#1) goto clrscr::@1 -- 0_neq_vbum1_then_la1 
    lda l
    bne __b1
    // clrscr::@4
    // __conio.cursor_x = 0
    // [1050] *((char *)&__conio) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio
    // __conio.cursor_y = 0
    // [1051] *((char *)&__conio+1) = 0 -- _deref_pbuc1=vbuc2 
    sta __conio+1
    // __conio.offset = __conio.mapbase_offset
    // [1052] *((unsigned int *)&__conio+$13) = *((unsigned int *)&__conio+3) -- _deref_pwuc1=_deref_pwuc2 
    lda __conio+3
    sta __conio+$13
    lda __conio+3+1
    sta __conio+$13+1
    // clrscr::@return
    // }
    // [1053] return 
    rts
  .segment Data
    .label line_text = ch
    l: .byte 0
    ch: .word 0
    c: .byte 0
}
.segment Code
  // printf_str
/// Print a NUL-terminated string
// void printf_str(__zp($aa) void (*putc)(char), __zp($60) const char *s)
printf_str: {
    .label s = $60
    .label putc = $aa
    // [1055] phi from printf_str printf_str::@2 to printf_str::@1 [phi:printf_str/printf_str::@2->printf_str::@1]
    // [1055] phi printf_str::s#74 = printf_str::s#75 [phi:printf_str/printf_str::@2->printf_str::@1#0] -- register_copy 
    // printf_str::@1
  __b1:
    // while(c=*s++)
    // [1056] printf_str::c#1 = *printf_str::s#74 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta c
    // [1057] printf_str::s#0 = ++ printf_str::s#74 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [1058] if(0!=printf_str::c#1) goto printf_str::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // printf_str::@return
    // }
    // [1059] return 
    rts
    // printf_str::@2
  __b2:
    // putc(c)
    // [1060] stackpush(char) = printf_str::c#1 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [1061] callexecute *printf_str::putc#75  -- call__deref_pprz1 
    jsr icall14
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
    // Outside Flow
  icall14:
    jmp (putc)
  .segment Data
    c: .byte 0
}
.segment Code
  // wait_moment
/**
 * @brief 
 * 
 */
// void wait_moment(__mem() char w)
wait_moment: {
    .label i = $60
    .label j = $e7
    // [1064] phi from wait_moment to wait_moment::@1 [phi:wait_moment->wait_moment::@1]
    // [1064] phi wait_moment::j#2 = 0 [phi:wait_moment->wait_moment::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z j
    // wait_moment::@1
  __b1:
    // for(unsigned char j=0; j<w; j++)
    // [1065] if(wait_moment::j#2<wait_moment::w#7) goto wait_moment::@2 -- vbuz1_lt_vbum2_then_la1 
    lda.z j
    cmp w
    bcc __b4
    // wait_moment::@return
    // }
    // [1066] return 
    rts
    // [1067] phi from wait_moment::@1 to wait_moment::@2 [phi:wait_moment::@1->wait_moment::@2]
  __b4:
    // [1067] phi wait_moment::i#2 = $ffff [phi:wait_moment::@1->wait_moment::@2#0] -- vwuz1=vwuc1 
    lda #<$ffff
    sta.z i
    lda #>$ffff
    sta.z i+1
    // wait_moment::@2
  __b2:
    // for(unsigned int i=65535; i>0; i--)
    // [1068] if(wait_moment::i#2>0) goto wait_moment::@3 -- vwuz1_gt_0_then_la1 
    lda.z i+1
    bne __b3
    lda.z i
    bne __b3
  !:
    // wait_moment::@4
    // for(unsigned char j=0; j<w; j++)
    // [1069] wait_moment::j#1 = ++ wait_moment::j#2 -- vbuz1=_inc_vbuz1 
    inc.z j
    // [1064] phi from wait_moment::@4 to wait_moment::@1 [phi:wait_moment::@4->wait_moment::@1]
    // [1064] phi wait_moment::j#2 = wait_moment::j#1 [phi:wait_moment::@4->wait_moment::@1#0] -- register_copy 
    jmp __b1
    // wait_moment::@3
  __b3:
    // for(unsigned int i=65535; i>0; i--)
    // [1070] wait_moment::i#1 = -- wait_moment::i#2 -- vwuz1=_dec_vwuz1 
    lda.z i
    bne !+
    dec.z i+1
  !:
    dec.z i
    // [1067] phi from wait_moment::@3 to wait_moment::@2 [phi:wait_moment::@3->wait_moment::@2]
    // [1067] phi wait_moment::i#2 = wait_moment::i#1 [phi:wait_moment::@3->wait_moment::@2#0] -- register_copy 
    jmp __b2
  .segment Data
    .label w = check_status_roms_less.rom_chip
}
.segment Code
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
    // [1072] BRAM = system_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // system_reset::bank_set_brom1
    // BROM = bank
    // [1073] BROM = system_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // system_reset::@2
    // asm
    // asm { jmp($FFFC)  }
    jmp ($fffc)
    // [1075] phi from system_reset::@1 system_reset::@2 to system_reset::@1 [phi:system_reset::@1/system_reset::@2->system_reset::@1]
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
// __zp($e7) char check_status_roms_less(char status)
check_status_roms_less: {
    .label check_status_roms_less__1 = $38
    .label return = $e7
    // [1077] phi from check_status_roms_less to check_status_roms_less::@1 [phi:check_status_roms_less->check_status_roms_less::@1]
    // [1077] phi check_status_roms_less::rom_chip#2 = 0 [phi:check_status_roms_less->check_status_roms_less::@1#0] -- vbum1=vbuc1 
    lda #0
    sta rom_chip
    // check_status_roms_less::@1
  __b1:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [1078] if(check_status_roms_less::rom_chip#2<8) goto check_status_roms_less::@2 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcc __b2
    // [1081] phi from check_status_roms_less::@1 to check_status_roms_less::@return [phi:check_status_roms_less::@1->check_status_roms_less::@return]
    // [1081] phi check_status_roms_less::return#2 = 1 [phi:check_status_roms_less::@1->check_status_roms_less::@return#0] -- vbuz1=vbuc1 
    lda #1
    sta.z return
    rts
    // check_status_roms_less::@2
  __b2:
    // status_rom[rom_chip] > status
    // [1079] check_status_roms_less::$1 = status_rom[check_status_roms_less::rom_chip#2] > STATUS_SKIP -- vboz1=pbuc1_derefidx_vbum2_gt_vbuc2 
    ldy rom_chip
    lda status_rom,y
    cmp #STATUS_SKIP
    lda #0
    rol
    sta.z check_status_roms_less__1
    // if((unsigned char)(status_rom[rom_chip] > status))
    // [1080] if(0==(char)check_status_roms_less::$1) goto check_status_roms_less::@3 -- 0_eq_vbuz1_then_la1 
    beq __b3
    // [1081] phi from check_status_roms_less::@2 to check_status_roms_less::@return [phi:check_status_roms_less::@2->check_status_roms_less::@return]
    // [1081] phi check_status_roms_less::return#2 = 0 [phi:check_status_roms_less::@2->check_status_roms_less::@return#0] -- vbuz1=vbuc1 
    lda #0
    sta.z return
    // check_status_roms_less::@return
    // }
    // [1082] return 
    rts
    // check_status_roms_less::@3
  __b3:
    // for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++)
    // [1083] check_status_roms_less::rom_chip#1 = ++ check_status_roms_less::rom_chip#2 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [1077] phi from check_status_roms_less::@3 to check_status_roms_less::@1 [phi:check_status_roms_less::@3->check_status_roms_less::@1]
    // [1077] phi check_status_roms_less::rom_chip#2 = check_status_roms_less::rom_chip#1 [phi:check_status_roms_less::@3->check_status_roms_less::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    rom_chip: .byte 0
}
.segment Code
  // display_action_progress
/**
 * @brief Print the progress at the action frame, which is the first line.
 * 
 * @param info_text The progress text to be displayed.
 */
// void display_action_progress(__zp($60) char *info_text)
display_action_progress: {
    .label x = $45
    .label info_text = $60
    // unsigned char x = wherex()
    // [1085] call wherex
    jsr wherex
    // [1086] wherex::return#2 = wherex::return#0
    // display_action_progress::@1
    // [1087] display_action_progress::x#0 = wherex::return#2 -- vbuz1=vbum2 
    lda wherex.return
    sta.z x
    // unsigned char y = wherey()
    // [1088] call wherey
    jsr wherey
    // [1089] wherey::return#2 = wherey::return#0
    // display_action_progress::@2
    // [1090] display_action_progress::y#0 = wherey::return#2 -- vbum1=vbum2 
    lda wherey.return
    sta y
    // gotoxy(2, PROGRESS_Y-4)
    // [1091] call gotoxy
    // [778] phi from display_action_progress::@2 to gotoxy [phi:display_action_progress::@2->gotoxy]
    // [778] phi gotoxy::y#33 = PROGRESS_Y-4 [phi:display_action_progress::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-4
    sta gotoxy.y
    // [778] phi gotoxy::x#33 = 2 [phi:display_action_progress::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // display_action_progress::@3
    // printf("%-65s", info_text)
    // [1092] printf_string::str#1 = display_action_progress::info_text#20
    // [1093] call printf_string
    // [1227] phi from display_action_progress::@3 to printf_string [phi:display_action_progress::@3->printf_string]
    // [1227] phi printf_string::putc#25 = &cputc [phi:display_action_progress::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1227] phi printf_string::str#25 = printf_string::str#1 [phi:display_action_progress::@3->printf_string#1] -- register_copy 
    // [1227] phi printf_string::format_justify_left#25 = 1 [phi:display_action_progress::@3->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1227] phi printf_string::format_min_length#25 = $41 [phi:display_action_progress::@3->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_action_progress::@4
    // gotoxy(x, y)
    // [1094] gotoxy::x#10 = display_action_progress::x#0 -- vbum1=vbuz2 
    lda.z x
    sta gotoxy.x
    // [1095] gotoxy::y#10 = display_action_progress::y#0 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1096] call gotoxy
    // [778] phi from display_action_progress::@4 to gotoxy [phi:display_action_progress::@4->gotoxy]
    // [778] phi gotoxy::y#33 = gotoxy::y#10 [phi:display_action_progress::@4->gotoxy#0] -- register_copy 
    // [778] phi gotoxy::x#33 = gotoxy::x#10 [phi:display_action_progress::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_action_progress::@return
    // }
    // [1097] return 
    rts
  .segment Data
    .label y = fopen.fopen__4
}
.segment Code
  // display_progress_text
/**
 * @brief Print a block of text within the progress frame with a count of lines.
 * 
 * @param text A pointer to an array of strings to be displayed (char**).
 * @param lines The amount of lines to be displayed, starting from the top of the progress frame.
 */
// void display_progress_text(__zp($3d) char **text, __mem() char lines)
display_progress_text: {
    .label text = $3d
    // display_progress_clear()
    // [1099] call display_progress_clear
    // [1161] phi from display_progress_text to display_progress_clear [phi:display_progress_text->display_progress_clear]
    jsr display_progress_clear
    // [1100] phi from display_progress_text to display_progress_text::@1 [phi:display_progress_text->display_progress_text::@1]
    // [1100] phi display_progress_text::l#2 = 0 [phi:display_progress_text->display_progress_text::@1#0] -- vbum1=vbuc1 
    lda #0
    sta l
    // display_progress_text::@1
  __b1:
    // for(unsigned char l=0; l<lines; l++)
    // [1101] if(display_progress_text::l#2<display_progress_text::lines#11) goto display_progress_text::@2 -- vbum1_lt_vbum2_then_la1 
    lda l
    cmp lines
    bcc __b2
    // display_progress_text::@return
    // }
    // [1102] return 
    rts
    // display_progress_text::@2
  __b2:
    // display_progress_line(l, text[l])
    // [1103] display_progress_text::$3 = display_progress_text::l#2 << 1 -- vbum1=vbum2_rol_1 
    lda l
    asl
    sta display_progress_text__3
    // [1104] display_progress_line::line#0 = display_progress_text::l#2 -- vbuz1=vbum2 
    lda l
    sta.z display_progress_line.line
    // [1105] display_progress_line::text#0 = display_progress_text::text#12[display_progress_text::$3] -- pbuz1=qbuz2_derefidx_vbum3 
    ldy display_progress_text__3
    lda (text),y
    sta.z display_progress_line.text
    iny
    lda (text),y
    sta.z display_progress_line.text+1
    // [1106] call display_progress_line
    // [1108] phi from display_progress_text::@2 to display_progress_line [phi:display_progress_text::@2->display_progress_line]
    // [1108] phi display_progress_line::text#3 = display_progress_line::text#0 [phi:display_progress_text::@2->display_progress_line#0] -- register_copy 
    // [1108] phi display_progress_line::line#3 = display_progress_line::line#0 [phi:display_progress_text::@2->display_progress_line#1] -- register_copy 
    jsr display_progress_line
    // display_progress_text::@3
    // for(unsigned char l=0; l<lines; l++)
    // [1107] display_progress_text::l#1 = ++ display_progress_text::l#2 -- vbum1=_inc_vbum1 
    inc l
    // [1100] phi from display_progress_text::@3 to display_progress_text::@1 [phi:display_progress_text::@3->display_progress_text::@1]
    // [1100] phi display_progress_text::l#2 = display_progress_text::l#1 [phi:display_progress_text::@3->display_progress_text::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    .label display_progress_text__3 = fopen.fopen__4
    .label l = check_status_card_roms.return
    .label lines = main.check_status_smc11_main__0
}
.segment Code
  // display_progress_line
/**
 * @brief Print one line of text in the progress frame at a line position.
 * 
 * @param line The start line, counting from 0.
 * @param text The text to be displayed.
 */
// void display_progress_line(__zp($e1) char line, __zp($b8) char *text)
display_progress_line: {
    .label line = $e1
    .label text = $b8
    // cputsxy(PROGRESS_X, PROGRESS_Y+line, text)
    // [1109] cputsxy::y#2 = PROGRESS_Y + display_progress_line::line#3 -- vbum1=vbuc1_plus_vbuz2 
    lda #PROGRESS_Y
    clc
    adc.z line
    sta cputsxy.y
    // [1110] cputsxy::s#2 = display_progress_line::text#3
    // [1111] call cputsxy
    // [1966] phi from display_progress_line to cputsxy [phi:display_progress_line->cputsxy]
    // [1966] phi cputsxy::s#4 = cputsxy::s#2 [phi:display_progress_line->cputsxy#0] -- register_copy 
    // [1966] phi cputsxy::y#4 = cputsxy::y#2 [phi:display_progress_line->cputsxy#1] -- register_copy 
    // [1966] phi cputsxy::x#4 = PROGRESS_X [phi:display_progress_line->cputsxy#2] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta cputsxy.x
    jsr cputsxy
    // display_progress_line::@return
    // }
    // [1112] return 
    rts
}
  // snprintf_init
/// Initialize the snprintf() state
// void snprintf_init(__zp($b8) char *s, unsigned int n)
snprintf_init: {
    .label s = $b8
    // __snprintf_capacity = n
    // [1114] __snprintf_capacity = $ffff -- vwum1=vwuc1 
    lda #<$ffff
    sta __snprintf_capacity
    lda #>$ffff
    sta __snprintf_capacity+1
    // __snprintf_size = 0
    // [1115] __snprintf_size = 0 -- vwum1=vbuc1 
    lda #<0
    sta __snprintf_size
    sta __snprintf_size+1
    // __snprintf_buffer = s
    // [1116] __snprintf_buffer = snprintf_init::s#25 -- pbuz1=pbuz2 
    lda.z s
    sta.z __snprintf_buffer
    lda.z s+1
    sta.z __snprintf_buffer+1
    // snprintf_init::@return
    // }
    // [1117] return 
    rts
}
  // printf_uchar
// Print an unsigned char using a specific format
// void printf_uchar(__zp($aa) void (*putc)(char), __mem() char uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, __mem() char format_radix)
printf_uchar: {
    .label putc = $aa
    // printf_uchar::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1119] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // uctoa(uvalue, printf_buffer.digits, format.radix)
    // [1120] uctoa::value#1 = printf_uchar::uvalue#17
    // [1121] uctoa::radix#0 = printf_uchar::format_radix#17
    // [1122] call uctoa
    // Format number into buffer
    jsr uctoa
    // printf_uchar::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1123] printf_number_buffer::putc#2 = printf_uchar::putc#17
    // [1124] printf_number_buffer::buffer_sign#2 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [1125] printf_number_buffer::format_min_length#2 = printf_uchar::format_min_length#17
    // [1126] printf_number_buffer::format_zero_padding#2 = printf_uchar::format_zero_padding#17
    // [1127] call printf_number_buffer
  // Print using format
    // [2116] phi from printf_uchar::@2 to printf_number_buffer [phi:printf_uchar::@2->printf_number_buffer]
    // [2116] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#2 [phi:printf_uchar::@2->printf_number_buffer#0] -- register_copy 
    // [2116] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#2 [phi:printf_uchar::@2->printf_number_buffer#1] -- register_copy 
    // [2116] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#2 [phi:printf_uchar::@2->printf_number_buffer#2] -- register_copy 
    // [2116] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#2 [phi:printf_uchar::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uchar::@return
    // }
    // [1128] return 
    rts
  .segment Data
    uvalue: .byte 0
    format_radix: .byte 0
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
// void display_action_text(__zp($c1) char *info_text)
display_action_text: {
    .label info_text = $c1
    .label x = $bc
    .label y = $75
    // unsigned char x = wherex()
    // [1130] call wherex
    jsr wherex
    // [1131] wherex::return#3 = wherex::return#0
    // display_action_text::@1
    // [1132] display_action_text::x#0 = wherex::return#3 -- vbuz1=vbum2 
    lda wherex.return
    sta.z x
    // unsigned char y = wherey()
    // [1133] call wherey
    jsr wherey
    // [1134] wherey::return#3 = wherey::return#0
    // display_action_text::@2
    // [1135] display_action_text::y#0 = wherey::return#3 -- vbuz1=vbum2 
    lda wherey.return
    sta.z y
    // gotoxy(2, PROGRESS_Y-3)
    // [1136] call gotoxy
    // [778] phi from display_action_text::@2 to gotoxy [phi:display_action_text::@2->gotoxy]
    // [778] phi gotoxy::y#33 = PROGRESS_Y-3 [phi:display_action_text::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-3
    sta gotoxy.y
    // [778] phi gotoxy::x#33 = 2 [phi:display_action_text::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // display_action_text::@3
    // printf("%-65s", info_text)
    // [1137] printf_string::str#2 = display_action_text::info_text#17 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1138] call printf_string
    // [1227] phi from display_action_text::@3 to printf_string [phi:display_action_text::@3->printf_string]
    // [1227] phi printf_string::putc#25 = &cputc [phi:display_action_text::@3->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1227] phi printf_string::str#25 = printf_string::str#2 [phi:display_action_text::@3->printf_string#1] -- register_copy 
    // [1227] phi printf_string::format_justify_left#25 = 1 [phi:display_action_text::@3->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1227] phi printf_string::format_min_length#25 = $41 [phi:display_action_text::@3->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_action_text::@4
    // gotoxy(x, y)
    // [1139] gotoxy::x#12 = display_action_text::x#0 -- vbum1=vbuz2 
    lda.z x
    sta gotoxy.x
    // [1140] gotoxy::y#12 = display_action_text::y#0 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [1141] call gotoxy
    // [778] phi from display_action_text::@4 to gotoxy [phi:display_action_text::@4->gotoxy]
    // [778] phi gotoxy::y#33 = gotoxy::y#12 [phi:display_action_text::@4->gotoxy#0] -- register_copy 
    // [778] phi gotoxy::x#33 = gotoxy::x#12 [phi:display_action_text::@4->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_action_text::@return
    // }
    // [1142] return 
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
    // [1144] BRAM = smc_reset::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // smc_reset::bank_set_brom1
    // BROM = bank
    // [1145] BROM = smc_reset::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // smc_reset::@1
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [1146] smc_reset::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [1147] smc_reset::cx16_k_i2c_write_byte1_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte1_offset
    // [1148] smc_reset::cx16_k_i2c_write_byte1_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte1_value
    // smc_reset::cx16_k_i2c_write_byte1
    // unsigned char result
    // [1149] smc_reset::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
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
    // [1151] return 
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
// __mem() char check_status_card_roms(char status)
check_status_card_roms: {
    .label check_status_rom1_check_status_card_roms__0 = $bc
    .label check_status_rom1_return = $bc
    // [1153] phi from check_status_card_roms to check_status_card_roms::@1 [phi:check_status_card_roms->check_status_card_roms::@1]
    // [1153] phi check_status_card_roms::rom_chip#2 = 1 [phi:check_status_card_roms->check_status_card_roms::@1#0] -- vbum1=vbuc1 
    lda #1
    sta rom_chip
    // check_status_card_roms::@1
  __b1:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [1154] if(check_status_card_roms::rom_chip#2<8) goto check_status_card_roms::check_status_rom1 -- vbum1_lt_vbuc1_then_la1 
    lda rom_chip
    cmp #8
    bcc check_status_rom1
    // [1155] phi from check_status_card_roms::@1 to check_status_card_roms::@return [phi:check_status_card_roms::@1->check_status_card_roms::@return]
    // [1155] phi check_status_card_roms::return#2 = 0 [phi:check_status_card_roms::@1->check_status_card_roms::@return#0] -- vbum1=vbuc1 
    lda #0
    sta return
    // check_status_card_roms::@return
    // }
    // [1156] return 
    rts
    // check_status_card_roms::check_status_rom1
  check_status_rom1:
    // status_rom[rom_chip] == status
    // [1157] check_status_card_roms::check_status_rom1_$0 = status_rom[check_status_card_roms::rom_chip#2] == STATUS_FLASH -- vboz1=pbuc1_derefidx_vbum2_eq_vbuc2 
    lda #STATUS_FLASH
    ldy rom_chip
    eor status_rom,y
    beq !+
    lda #1
  !:
    eor #1
    sta.z check_status_rom1_check_status_card_roms__0
    // return (unsigned char)(status_rom[rom_chip] == status);
    // [1158] check_status_card_roms::check_status_rom1_return#0 = (char)check_status_card_roms::check_status_rom1_$0
    // check_status_card_roms::@3
    // if(check_status_rom(rom_chip, status))
    // [1159] if(0==check_status_card_roms::check_status_rom1_return#0) goto check_status_card_roms::@2 -- 0_eq_vbuz1_then_la1 
    lda.z check_status_rom1_return
    beq __b2
    // [1155] phi from check_status_card_roms::@3 to check_status_card_roms::@return [phi:check_status_card_roms::@3->check_status_card_roms::@return]
    // [1155] phi check_status_card_roms::return#2 = 1 [phi:check_status_card_roms::@3->check_status_card_roms::@return#0] -- vbum1=vbuc1 
    lda #1
    sta return
    rts
    // check_status_card_roms::@2
  __b2:
    // for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++)
    // [1160] check_status_card_roms::rom_chip#1 = ++ check_status_card_roms::rom_chip#2 -- vbum1=_inc_vbum1 
    inc rom_chip
    // [1153] phi from check_status_card_roms::@2 to check_status_card_roms::@1 [phi:check_status_card_roms::@2->check_status_card_roms::@1]
    // [1153] phi check_status_card_roms::rom_chip#2 = check_status_card_roms::rom_chip#1 [phi:check_status_card_roms::@2->check_status_card_roms::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    .label rom_chip = main.check_status_smc11_main__0
    return: .byte 0
}
.segment Code
  // display_progress_clear
/**
 * @brief Clean the progress area for the flashing.
 */
display_progress_clear: {
    .const h = PROGRESS_Y+PROGRESS_H
    .label x = $d1
    .label i = $ca
    .label y = $e1
    // textcolor(WHITE)
    // [1162] call textcolor
    // [760] phi from display_progress_clear to textcolor [phi:display_progress_clear->textcolor]
    // [760] phi textcolor::color#23 = WHITE [phi:display_progress_clear->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [1163] phi from display_progress_clear to display_progress_clear::@5 [phi:display_progress_clear->display_progress_clear::@5]
    // display_progress_clear::@5
    // bgcolor(BLUE)
    // [1164] call bgcolor
    // [765] phi from display_progress_clear::@5 to bgcolor [phi:display_progress_clear::@5->bgcolor]
    // [765] phi bgcolor::color#15 = BLUE [phi:display_progress_clear::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [1165] phi from display_progress_clear::@5 to display_progress_clear::@1 [phi:display_progress_clear::@5->display_progress_clear::@1]
    // [1165] phi display_progress_clear::y#2 = PROGRESS_Y [phi:display_progress_clear::@5->display_progress_clear::@1#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // display_progress_clear::@1
  __b1:
    // while (y < h)
    // [1166] if(display_progress_clear::y#2<display_progress_clear::h) goto display_progress_clear::@2 -- vbuz1_lt_vbuc1_then_la1 
    lda.z y
    cmp #h
    bcc __b4
    // display_progress_clear::@return
    // }
    // [1167] return 
    rts
    // [1168] phi from display_progress_clear::@1 to display_progress_clear::@2 [phi:display_progress_clear::@1->display_progress_clear::@2]
  __b4:
    // [1168] phi display_progress_clear::x#2 = PROGRESS_X [phi:display_progress_clear::@1->display_progress_clear::@2#0] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z x
    // [1168] phi display_progress_clear::i#2 = 0 [phi:display_progress_clear::@1->display_progress_clear::@2#1] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // display_progress_clear::@2
  __b2:
    // for(unsigned char i = 0; i < w; i++)
    // [1169] if(display_progress_clear::i#2<PROGRESS_W) goto display_progress_clear::@3 -- vbuz1_lt_vbuc1_then_la1 
    lda.z i
    cmp #PROGRESS_W
    bcc __b3
    // display_progress_clear::@4
    // y++;
    // [1170] display_progress_clear::y#1 = ++ display_progress_clear::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [1165] phi from display_progress_clear::@4 to display_progress_clear::@1 [phi:display_progress_clear::@4->display_progress_clear::@1]
    // [1165] phi display_progress_clear::y#2 = display_progress_clear::y#1 [phi:display_progress_clear::@4->display_progress_clear::@1#0] -- register_copy 
    jmp __b1
    // display_progress_clear::@3
  __b3:
    // cputcxy(x, y, ' ')
    // [1171] cputcxy::x#12 = display_progress_clear::x#2 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [1172] cputcxy::y#12 = display_progress_clear::y#2 -- vbum1=vbuz2 
    lda.z y
    sta cputcxy.y
    // [1173] call cputcxy
    // [2147] phi from display_progress_clear::@3 to cputcxy [phi:display_progress_clear::@3->cputcxy]
    // [2147] phi cputcxy::c#15 = ' ' [phi:display_progress_clear::@3->cputcxy#0] -- vbum1=vbuc1 
    lda #' '
    sta cputcxy.c
    // [2147] phi cputcxy::y#15 = cputcxy::y#12 [phi:display_progress_clear::@3->cputcxy#1] -- register_copy 
    // [2147] phi cputcxy::x#15 = cputcxy::x#12 [phi:display_progress_clear::@3->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_progress_clear::@6
    // x++;
    // [1174] display_progress_clear::x#1 = ++ display_progress_clear::x#2 -- vbuz1=_inc_vbuz1 
    inc.z x
    // for(unsigned char i = 0; i < w; i++)
    // [1175] display_progress_clear::i#1 = ++ display_progress_clear::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [1168] phi from display_progress_clear::@6 to display_progress_clear::@2 [phi:display_progress_clear::@6->display_progress_clear::@2]
    // [1168] phi display_progress_clear::x#2 = display_progress_clear::x#1 [phi:display_progress_clear::@6->display_progress_clear::@2#0] -- register_copy 
    // [1168] phi display_progress_clear::i#2 = display_progress_clear::i#1 [phi:display_progress_clear::@6->display_progress_clear::@2#1] -- register_copy 
    jmp __b2
}
  // display_info_rom
/**
 * @brief Display the ROM status of a specific rom chip. 
 * 
 * @param rom_chip The ROM chip, 0 is the main CX16 ROM chip, maximum 7 ROMs.
 * @param info_status The status.
 * @param info_text The status text.
 */
// void display_info_rom(__mem() char rom_chip, __zp($ec) char info_status, __zp($ba) char *info_text)
display_info_rom: {
    .label display_info_rom__6 = $75
    .label display_info_rom__15 = $ec
    .label display_info_rom__16 = $af
    .label x = $2a
    .label y = $76
    .label info_status = $ec
    .label info_text = $ba
    .label display_info_rom__19 = $75
    .label display_info_rom__20 = $75
    // unsigned char x = wherex()
    // [1177] call wherex
    jsr wherex
    // [1178] wherex::return#12 = wherex::return#0
    // display_info_rom::@3
    // [1179] display_info_rom::x#0 = wherex::return#12 -- vbuz1=vbum2 
    lda wherex.return
    sta.z x
    // unsigned char y = wherey()
    // [1180] call wherey
    jsr wherey
    // [1181] wherey::return#12 = wherey::return#0
    // display_info_rom::@4
    // [1182] display_info_rom::y#0 = wherey::return#12 -- vbuz1=vbum2 
    lda wherey.return
    sta.z y
    // status_rom[rom_chip] = info_status
    // [1183] status_rom[display_info_rom::rom_chip#16] = display_info_rom::info_status#16 -- pbuc1_derefidx_vbum1=vbuz2 
    lda.z info_status
    ldy rom_chip
    sta status_rom,y
    // display_rom_led(rom_chip, status_color[info_status])
    // [1184] display_rom_led::chip#1 = display_info_rom::rom_chip#16 -- vbuz1=vbum2 
    tya
    sta.z display_rom_led.chip
    // [1185] display_rom_led::c#1 = status_color[display_info_rom::info_status#16] -- vbuz1=pbuc1_derefidx_vbuz2 
    ldy.z info_status
    lda status_color,y
    sta.z display_rom_led.c
    // [1186] call display_rom_led
    // [2077] phi from display_info_rom::@4 to display_rom_led [phi:display_info_rom::@4->display_rom_led]
    // [2077] phi display_rom_led::c#2 = display_rom_led::c#1 [phi:display_info_rom::@4->display_rom_led#0] -- register_copy 
    // [2077] phi display_rom_led::chip#2 = display_rom_led::chip#1 [phi:display_info_rom::@4->display_rom_led#1] -- register_copy 
    jsr display_rom_led
    // display_info_rom::@5
    // gotoxy(INFO_X, INFO_Y+rom_chip+2)
    // [1187] gotoxy::y#19 = display_info_rom::rom_chip#16 + $11+2 -- vbum1=vbum2_plus_vbuc1 
    lda #$11+2
    clc
    adc rom_chip
    sta gotoxy.y
    // [1188] call gotoxy
    // [778] phi from display_info_rom::@5 to gotoxy [phi:display_info_rom::@5->gotoxy]
    // [778] phi gotoxy::y#33 = gotoxy::y#19 [phi:display_info_rom::@5->gotoxy#0] -- register_copy 
    // [778] phi gotoxy::x#33 = 4 [phi:display_info_rom::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // display_info_rom::@6
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1189] display_info_rom::$16 = display_info_rom::rom_chip#16 << 1 -- vbuz1=vbum2_rol_1 
    lda rom_chip
    asl
    sta.z display_info_rom__16
    // rom_chip*13
    // [1190] display_info_rom::$19 = display_info_rom::$16 + display_info_rom::rom_chip#16 -- vbuz1=vbuz2_plus_vbum3 
    lda rom_chip
    clc
    adc.z display_info_rom__16
    sta.z display_info_rom__19
    // [1191] display_info_rom::$20 = display_info_rom::$19 << 2 -- vbuz1=vbuz1_rol_2 
    lda.z display_info_rom__20
    asl
    asl
    sta.z display_info_rom__20
    // [1192] display_info_rom::$6 = display_info_rom::$20 + display_info_rom::rom_chip#16 -- vbuz1=vbuz1_plus_vbum2 
    lda rom_chip
    clc
    adc.z display_info_rom__6
    sta.z display_info_rom__6
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1193] printf_string::str#10 = rom_release_text + display_info_rom::$6 -- pbum1=pbuc1_plus_vbuz2 
    clc
    adc #<rom_release_text
    sta printf_string.str_1
    lda #>rom_release_text
    adc #0
    sta printf_string.str_1+1
    // [1194] call printf_str
    // [1054] phi from display_info_rom::@6 to printf_str [phi:display_info_rom::@6->printf_str]
    // [1054] phi printf_str::putc#75 = &cputc [phi:display_info_rom::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = chip [phi:display_info_rom::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<chip
    sta.z printf_str.s
    lda #>chip
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@7
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1195] printf_uchar::uvalue#3 = display_info_rom::rom_chip#16 -- vbum1=vbum2 
    lda rom_chip
    sta printf_uchar.uvalue
    // [1196] call printf_uchar
    // [1118] phi from display_info_rom::@7 to printf_uchar [phi:display_info_rom::@7->printf_uchar]
    // [1118] phi printf_uchar::format_zero_padding#17 = 0 [phi:display_info_rom::@7->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1118] phi printf_uchar::format_min_length#17 = 0 [phi:display_info_rom::@7->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1118] phi printf_uchar::putc#17 = &cputc [phi:display_info_rom::@7->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1118] phi printf_uchar::format_radix#17 = DECIMAL [phi:display_info_rom::@7->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1118] phi printf_uchar::uvalue#17 = printf_uchar::uvalue#3 [phi:display_info_rom::@7->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1197] phi from display_info_rom::@7 to display_info_rom::@8 [phi:display_info_rom::@7->display_info_rom::@8]
    // display_info_rom::@8
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1198] call printf_str
    // [1054] phi from display_info_rom::@8 to printf_str [phi:display_info_rom::@8->printf_str]
    // [1054] phi printf_str::putc#75 = &cputc [phi:display_info_rom::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = s [phi:display_info_rom::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@9
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1199] display_info_rom::$15 = display_info_rom::info_status#16 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_info_rom__15
    // [1200] printf_string::str#8 = status_text[display_info_rom::$15] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z display_info_rom__15
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [1201] call printf_string
    // [1227] phi from display_info_rom::@9 to printf_string [phi:display_info_rom::@9->printf_string]
    // [1227] phi printf_string::putc#25 = &cputc [phi:display_info_rom::@9->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1227] phi printf_string::str#25 = printf_string::str#8 [phi:display_info_rom::@9->printf_string#1] -- register_copy 
    // [1227] phi printf_string::format_justify_left#25 = 1 [phi:display_info_rom::@9->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1227] phi printf_string::format_min_length#25 = 9 [phi:display_info_rom::@9->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [1202] phi from display_info_rom::@9 to display_info_rom::@10 [phi:display_info_rom::@9->display_info_rom::@10]
    // display_info_rom::@10
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1203] call printf_str
    // [1054] phi from display_info_rom::@10 to printf_str [phi:display_info_rom::@10->printf_str]
    // [1054] phi printf_str::putc#75 = &cputc [phi:display_info_rom::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = s [phi:display_info_rom::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@11
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1204] printf_string::str#9 = rom_device_names[display_info_rom::$16] -- pbuz1=qbuc1_derefidx_vbuz2 
    ldy.z display_info_rom__16
    lda rom_device_names,y
    sta.z printf_string.str
    lda rom_device_names+1,y
    sta.z printf_string.str+1
    // [1205] call printf_string
    // [1227] phi from display_info_rom::@11 to printf_string [phi:display_info_rom::@11->printf_string]
    // [1227] phi printf_string::putc#25 = &cputc [phi:display_info_rom::@11->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1227] phi printf_string::str#25 = printf_string::str#9 [phi:display_info_rom::@11->printf_string#1] -- register_copy 
    // [1227] phi printf_string::format_justify_left#25 = 1 [phi:display_info_rom::@11->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1227] phi printf_string::format_min_length#25 = 6 [phi:display_info_rom::@11->printf_string#3] -- vbum1=vbuc1 
    lda #6
    sta printf_string.format_min_length
    jsr printf_string
    // [1206] phi from display_info_rom::@11 to display_info_rom::@12 [phi:display_info_rom::@11->display_info_rom::@12]
    // display_info_rom::@12
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1207] call printf_str
    // [1054] phi from display_info_rom::@12 to printf_str [phi:display_info_rom::@12->printf_str]
    // [1054] phi printf_str::putc#75 = &cputc [phi:display_info_rom::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = s [phi:display_info_rom::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@13
    // [1208] printf_string::str#40 = printf_string::str#10 -- pbuz1=pbum2 
    lda printf_string.str_1
    sta.z printf_string.str
    lda printf_string.str_1+1
    sta.z printf_string.str+1
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1209] call printf_string
    // [1227] phi from display_info_rom::@13 to printf_string [phi:display_info_rom::@13->printf_string]
    // [1227] phi printf_string::putc#25 = &cputc [phi:display_info_rom::@13->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1227] phi printf_string::str#25 = printf_string::str#40 [phi:display_info_rom::@13->printf_string#1] -- register_copy 
    // [1227] phi printf_string::format_justify_left#25 = 1 [phi:display_info_rom::@13->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1227] phi printf_string::format_min_length#25 = $d [phi:display_info_rom::@13->printf_string#3] -- vbum1=vbuc1 
    lda #$d
    sta printf_string.format_min_length
    jsr printf_string
    // [1210] phi from display_info_rom::@13 to display_info_rom::@14 [phi:display_info_rom::@13->display_info_rom::@14]
    // display_info_rom::@14
    // printf("ROM%u %-9s %-6s %-13s ", rom_chip, status_text[info_status], rom_device_names[rom_chip], &rom_release_text[rom_chip*13])
    // [1211] call printf_str
    // [1054] phi from display_info_rom::@14 to printf_str [phi:display_info_rom::@14->printf_str]
    // [1054] phi printf_str::putc#75 = &cputc [phi:display_info_rom::@14->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = s [phi:display_info_rom::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_rom::@15
    // if(info_text)
    // [1212] if((char *)0==display_info_rom::info_text#16) goto display_info_rom::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // display_info_rom::@2
    // gotoxy(INFO_X+64-28, INFO_Y+rom_chip+2)
    // [1213] gotoxy::y#21 = display_info_rom::rom_chip#16 + $11+2 -- vbum1=vbum2_plus_vbuc1 
    lda #$11+2
    clc
    adc rom_chip
    sta gotoxy.y
    // [1214] call gotoxy
    // [778] phi from display_info_rom::@2 to gotoxy [phi:display_info_rom::@2->gotoxy]
    // [778] phi gotoxy::y#33 = gotoxy::y#21 [phi:display_info_rom::@2->gotoxy#0] -- register_copy 
    // [778] phi gotoxy::x#33 = 4+$40-$1c [phi:display_info_rom::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #4+$40-$1c
    sta gotoxy.x
    jsr gotoxy
    // display_info_rom::@16
    // printf("%-25s", info_text)
    // [1215] printf_string::str#11 = display_info_rom::info_text#16 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1216] call printf_string
    // [1227] phi from display_info_rom::@16 to printf_string [phi:display_info_rom::@16->printf_string]
    // [1227] phi printf_string::putc#25 = &cputc [phi:display_info_rom::@16->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1227] phi printf_string::str#25 = printf_string::str#11 [phi:display_info_rom::@16->printf_string#1] -- register_copy 
    // [1227] phi printf_string::format_justify_left#25 = 1 [phi:display_info_rom::@16->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1227] phi printf_string::format_min_length#25 = $19 [phi:display_info_rom::@16->printf_string#3] -- vbum1=vbuc1 
    lda #$19
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_rom::@1
  __b1:
    // gotoxy(x,y)
    // [1217] gotoxy::x#20 = display_info_rom::x#0 -- vbum1=vbuz2 
    lda.z x
    sta gotoxy.x
    // [1218] gotoxy::y#20 = display_info_rom::y#0 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [1219] call gotoxy
    // [778] phi from display_info_rom::@1 to gotoxy [phi:display_info_rom::@1->gotoxy]
    // [778] phi gotoxy::y#33 = gotoxy::y#20 [phi:display_info_rom::@1->gotoxy#0] -- register_copy 
    // [778] phi gotoxy::x#33 = gotoxy::x#20 [phi:display_info_rom::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_rom::@return
    // }
    // [1220] return 
    rts
  .segment Data
    .label rom_chip = main.check_status_rom1_main__0
}
.segment Code
  // rom_file
// __mem() char * rom_file(__zp($ca) char rom_chip)
rom_file: {
    .label rom_file__0 = $ca
    .label rom_chip = $ca
    // if(rom_chip)
    // [1222] if(0!=rom_file::rom_chip#2) goto rom_file::@1 -- 0_neq_vbuz1_then_la1 
    lda.z rom_chip
    bne __b1
    // [1225] phi from rom_file to rom_file::@return [phi:rom_file->rom_file::@return]
    // [1225] phi rom_file::return#2 = rom_file::file_rom_cx16 [phi:rom_file->rom_file::@return#0] -- pbum1=pbuc1 
    lda #<file_rom_cx16
    sta return
    lda #>file_rom_cx16
    sta return+1
    rts
    // rom_file::@1
  __b1:
    // '0'+rom_chip
    // [1223] rom_file::$0 = '0' + rom_file::rom_chip#2 -- vbuz1=vbuc1_plus_vbuz1 
    lda #'0'
    clc
    adc.z rom_file__0
    sta.z rom_file__0
    // file_rom_card[3] = '0'+rom_chip
    // [1224] *(rom_file::file_rom_card+3) = rom_file::$0 -- _deref_pbuc1=vbuz1 
    sta file_rom_card+3
    // [1225] phi from rom_file::@1 to rom_file::@return [phi:rom_file::@1->rom_file::@return]
    // [1225] phi rom_file::return#2 = rom_file::file_rom_card [phi:rom_file::@1->rom_file::@return#0] -- pbum1=pbuc1 
    lda #<file_rom_card
    sta return
    lda #>file_rom_card
    sta return+1
    // rom_file::@return
    // }
    // [1226] return 
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
// void printf_string(__zp($3d) void (*putc)(char), __zp($60) char *str, __mem() char format_min_length, __mem() char format_justify_left)
printf_string: {
    .label printf_string__9 = $b4
    .label str = $60
    .label putc = $3d
    // if(format.min_length)
    // [1228] if(0==printf_string::format_min_length#25) goto printf_string::@1 -- 0_eq_vbum1_then_la1 
    lda format_min_length
    beq __b3
    // printf_string::@3
    // strlen(str)
    // [1229] strlen::str#3 = printf_string::str#25 -- pbuz1=pbuz2 
    lda.z str
    sta.z strlen.str
    lda.z str+1
    sta.z strlen.str+1
    // [1230] call strlen
    // [2155] phi from printf_string::@3 to strlen [phi:printf_string::@3->strlen]
    // [2155] phi strlen::str#8 = strlen::str#3 [phi:printf_string::@3->strlen#0] -- register_copy 
    jsr strlen
    // strlen(str)
    // [1231] strlen::return#10 = strlen::len#2
    // printf_string::@6
    // [1232] printf_string::$9 = strlen::return#10 -- vwuz1=vwum2 
    lda strlen.return
    sta.z printf_string__9
    lda strlen.return+1
    sta.z printf_string__9+1
    // signed char len = (signed char)strlen(str)
    // [1233] printf_string::len#0 = (signed char)printf_string::$9 -- vbsm1=_sbyte_vwuz2 
    lda.z printf_string__9
    sta len
    // padding = (signed char)format.min_length  - len
    // [1234] printf_string::padding#1 = (signed char)printf_string::format_min_length#25 - printf_string::len#0 -- vbsm1=vbsm1_minus_vbsm2 
    lda padding
    sec
    sbc len
    sta padding
    // if(padding<0)
    // [1235] if(printf_string::padding#1>=0) goto printf_string::@10 -- vbsm1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [1237] phi from printf_string printf_string::@6 to printf_string::@1 [phi:printf_string/printf_string::@6->printf_string::@1]
  __b3:
    // [1237] phi printf_string::padding#3 = 0 [phi:printf_string/printf_string::@6->printf_string::@1#0] -- vbsm1=vbsc1 
    lda #0
    sta padding
    // [1236] phi from printf_string::@6 to printf_string::@10 [phi:printf_string::@6->printf_string::@10]
    // printf_string::@10
    // [1237] phi from printf_string::@10 to printf_string::@1 [phi:printf_string::@10->printf_string::@1]
    // [1237] phi printf_string::padding#3 = printf_string::padding#1 [phi:printf_string::@10->printf_string::@1#0] -- register_copy 
    // printf_string::@1
  __b1:
    // if(!format.justify_left && padding)
    // [1238] if(0!=printf_string::format_justify_left#25) goto printf_string::@2 -- 0_neq_vbum1_then_la1 
    lda format_justify_left
    bne __b2
    // printf_string::@8
    // [1239] if(0!=printf_string::padding#3) goto printf_string::@4 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b4
    jmp __b2
    // printf_string::@4
  __b4:
    // printf_padding(putc, ' ',(char)padding)
    // [1240] printf_padding::putc#3 = printf_string::putc#25 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1241] printf_padding::length#3 = (char)printf_string::padding#3 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1242] call printf_padding
    // [2161] phi from printf_string::@4 to printf_padding [phi:printf_string::@4->printf_padding]
    // [2161] phi printf_padding::putc#7 = printf_padding::putc#3 [phi:printf_string::@4->printf_padding#0] -- register_copy 
    // [2161] phi printf_padding::pad#7 = ' ' [phi:printf_string::@4->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [2161] phi printf_padding::length#6 = printf_padding::length#3 [phi:printf_string::@4->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@2
  __b2:
    // printf_str(putc, str)
    // [1243] printf_str::putc#1 = printf_string::putc#25 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_str.putc
    lda.z putc+1
    sta.z printf_str.putc+1
    // [1244] printf_str::s#2 = printf_string::str#25
    // [1245] call printf_str
    // [1054] phi from printf_string::@2 to printf_str [phi:printf_string::@2->printf_str]
    // [1054] phi printf_str::putc#75 = printf_str::putc#1 [phi:printf_string::@2->printf_str#0] -- register_copy 
    // [1054] phi printf_str::s#75 = printf_str::s#2 [phi:printf_string::@2->printf_str#1] -- register_copy 
    jsr printf_str
    // printf_string::@7
    // if(format.justify_left && padding)
    // [1246] if(0==printf_string::format_justify_left#25) goto printf_string::@return -- 0_eq_vbum1_then_la1 
    lda format_justify_left
    beq __breturn
    // printf_string::@9
    // [1247] if(0!=printf_string::padding#3) goto printf_string::@5 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b5
    rts
    // printf_string::@5
  __b5:
    // printf_padding(putc, ' ',(char)padding)
    // [1248] printf_padding::putc#4 = printf_string::putc#25 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [1249] printf_padding::length#4 = (char)printf_string::padding#3 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [1250] call printf_padding
    // [2161] phi from printf_string::@5 to printf_padding [phi:printf_string::@5->printf_padding]
    // [2161] phi printf_padding::putc#7 = printf_padding::putc#4 [phi:printf_string::@5->printf_padding#0] -- register_copy 
    // [2161] phi printf_padding::pad#7 = ' ' [phi:printf_string::@5->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [2161] phi printf_padding::length#6 = printf_padding::length#4 [phi:printf_string::@5->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_string::@return
  __breturn:
    // }
    // [1251] return 
    rts
  .segment Data
    len: .byte 0
    .label padding = format_min_length
    .label str_1 = fopen.cbm_k_setnam1_fopen__0
    format_min_length: .byte 0
    format_justify_left: .byte 0
}
.segment Code
  // rom_read
// __mem() unsigned long rom_read(__zp($c9) char rom_chip, __zp($4e) char *file, __zp($cd) char info_status, __zp($bf) char brom_bank_start, __zp($5a) unsigned long rom_size)
rom_read: {
    .const bank_set_brom1_bank = 0
    .label rom_read__13 = $e8
    .label rom_read__24 = $2a
    .label rom_package_read = $da
    .label brom_bank_start = $bf
    .label y = $4d
    .label rom_bram_ptr = $66
    /// Holds the amount of bytes actually read in the memory to be flashed.
    .label rom_row_current = $56
    // We start for ROM from 0x0:0x7800 !!!!
    .label rom_bram_bank = $6a
    .label rom_chip = $c9
    .label file = $4e
    .label rom_size = $5a
    .label info_status = $cd
    .label rom_action_text = $7e
    // rom_read::bank_set_bram1
    // BRAM = bank
    // [1253] BRAM = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z BRAM
    // rom_read::bank_set_brom1
    // BROM = bank
    // [1254] BROM = rom_read::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // rom_read::@23
    // if(info_status == STATUS_READING)
    // [1255] if(rom_read::info_status#11==STATUS_READING) goto rom_read::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #STATUS_READING
    cmp.z info_status
    beq __b1
    // [1257] phi from rom_read::@23 to rom_read::@2 [phi:rom_read::@23->rom_read::@2]
    // [1257] phi rom_read::rom_action_text#10 = smc_action_text#2 [phi:rom_read::@23->rom_read::@2#0] -- pbuz1=pbuc1 
    lda #<smc_action_text_1
    sta.z rom_action_text
    lda #>smc_action_text_1
    sta.z rom_action_text+1
    jmp __b2
    // [1256] phi from rom_read::@23 to rom_read::@1 [phi:rom_read::@23->rom_read::@1]
    // rom_read::@1
  __b1:
    // [1257] phi from rom_read::@1 to rom_read::@2 [phi:rom_read::@1->rom_read::@2]
    // [1257] phi rom_read::rom_action_text#10 = smc_action_text#1 [phi:rom_read::@1->rom_read::@2#0] -- pbuz1=pbuc1 
    lda #<smc_action_text
    sta.z rom_action_text
    lda #>smc_action_text
    sta.z rom_action_text+1
    // rom_read::@2
  __b2:
    // unsigned long rom_address = rom_address_from_bank(brom_bank_start)
    // [1258] rom_address_from_bank::rom_bank#0 = rom_read::brom_bank_start#10 -- vbum1=vbuz2 
    lda.z brom_bank_start
    sta rom_address_from_bank.rom_bank
    // [1259] call rom_address_from_bank
    // [2169] phi from rom_read::@2 to rom_address_from_bank [phi:rom_read::@2->rom_address_from_bank]
    // [2169] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#0 [phi:rom_read::@2->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(brom_bank_start)
    // [1260] rom_address_from_bank::return#2 = rom_address_from_bank::return#0
    // rom_read::@25
    // [1261] rom_read::rom_address#0 = rom_address_from_bank::return#2
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1262] call snprintf_init
    // [1113] phi from rom_read::@25 to snprintf_init [phi:rom_read::@25->snprintf_init]
    // [1113] phi snprintf_init::s#25 = info_text [phi:rom_read::@25->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1263] phi from rom_read::@25 to rom_read::@26 [phi:rom_read::@25->rom_read::@26]
    // rom_read::@26
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1264] call printf_str
    // [1054] phi from rom_read::@26 to printf_str [phi:rom_read::@26->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:rom_read::@26->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = rom_read::s [phi:rom_read::@26->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@27
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1265] printf_string::str#17 = rom_read::file#10 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [1266] call printf_string
    // [1227] phi from rom_read::@27 to printf_string [phi:rom_read::@27->printf_string]
    // [1227] phi printf_string::putc#25 = &snputc [phi:rom_read::@27->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1227] phi printf_string::str#25 = printf_string::str#17 [phi:rom_read::@27->printf_string#1] -- register_copy 
    // [1227] phi printf_string::format_justify_left#25 = 0 [phi:rom_read::@27->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1227] phi printf_string::format_min_length#25 = 0 [phi:rom_read::@27->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [1267] phi from rom_read::@27 to rom_read::@28 [phi:rom_read::@27->rom_read::@28]
    // rom_read::@28
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1268] call printf_str
    // [1054] phi from rom_read::@28 to printf_str [phi:rom_read::@28->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:rom_read::@28->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = rom_read::s1 [phi:rom_read::@28->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_read::@29
    // sprintf(info_text, "Opening %s from SD card ...", file)
    // [1269] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1270] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1272] call display_action_text
    // [1129] phi from rom_read::@29 to display_action_text [phi:rom_read::@29->display_action_text]
    // [1129] phi display_action_text::info_text#17 = info_text [phi:rom_read::@29->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // rom_read::@30
    // FILE *fp = fopen(file, "r")
    // [1273] fopen::path#3 = rom_read::file#10 -- pbuz1=pbuz2 
    lda.z file
    sta.z fopen.path
    lda.z file+1
    sta.z fopen.path+1
    // [1274] call fopen
    // [2173] phi from rom_read::@30 to fopen [phi:rom_read::@30->fopen]
    // [2173] phi __errno#322 = __errno#114 [phi:rom_read::@30->fopen#0] -- register_copy 
    // [2173] phi fopen::pathtoken#0 = fopen::path#3 [phi:rom_read::@30->fopen#1] -- register_copy 
    // [2173] phi __stdio_filecount#18 = __stdio_filecount#108 [phi:rom_read::@30->fopen#2] -- register_copy 
    jsr fopen
    // FILE *fp = fopen(file, "r")
    // [1275] fopen::return#4 = fopen::return#2
    // rom_read::@31
    // [1276] rom_read::fp#0 = fopen::return#4 -- pssm1=pssz2 
    lda.z fopen.return
    sta fp
    lda.z fopen.return+1
    sta fp+1
    // if (fp)
    // [1277] if((struct $2 *)0==rom_read::fp#0) goto rom_read::@3 -- pssc1_eq_pssm1_then_la1 
    lda fp
    cmp #<0
    bne !+
    lda fp+1
    cmp #>0
    beq __b4
  !:
    // [1278] phi from rom_read::@31 to rom_read::@4 [phi:rom_read::@31->rom_read::@4]
    // rom_read::@4
    // gotoxy(x, y)
    // [1279] call gotoxy
    // [778] phi from rom_read::@4 to gotoxy [phi:rom_read::@4->gotoxy]
    // [778] phi gotoxy::y#33 = PROGRESS_Y [phi:rom_read::@4->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [778] phi gotoxy::x#33 = PROGRESS_X [phi:rom_read::@4->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1280] phi from rom_read::@4 to rom_read::@5 [phi:rom_read::@4->rom_read::@5]
    // [1280] phi rom_read::y#11 = PROGRESS_Y [phi:rom_read::@4->rom_read::@5#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // [1280] phi rom_read::rom_row_current#10 = 0 [phi:rom_read::@4->rom_read::@5#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z rom_row_current
    sta.z rom_row_current+1
    // [1280] phi rom_read::brom_bank_start#11 = rom_read::brom_bank_start#10 [phi:rom_read::@4->rom_read::@5#2] -- register_copy 
    // [1280] phi rom_read::rom_address#10 = rom_read::rom_address#0 [phi:rom_read::@4->rom_read::@5#3] -- register_copy 
    // [1280] phi rom_read::rom_bram_ptr#13 = (char *)$7800 [phi:rom_read::@4->rom_read::@5#4] -- pbuz1=pbuc1 
    lda #<$7800
    sta.z rom_bram_ptr
    lda #>$7800
    sta.z rom_bram_ptr+1
    // [1280] phi rom_read::rom_bram_bank#10 = 0 [phi:rom_read::@4->rom_read::@5#5] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_bram_bank
    // [1280] phi rom_read::rom_file_size#13 = 0 [phi:rom_read::@4->rom_read::@5#6] -- vdum1=vduc1 
    sta rom_file_size
    sta rom_file_size+1
    lda #<0>>$10
    sta rom_file_size+2
    lda #>0>>$10
    sta rom_file_size+3
    // rom_read::@5
  __b5:
    // while (rom_file_size < rom_size)
    // [1281] if(rom_read::rom_file_size#13<rom_read::rom_size#12) goto rom_read::@6 -- vdum1_lt_vduz2_then_la1 
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
    // [1282] fclose::stream#1 = rom_read::fp#0
    // [1283] call fclose
    // [2254] phi from rom_read::@10 to fclose [phi:rom_read::@10->fclose]
    // [2254] phi fclose::stream#2 = fclose::stream#1 [phi:rom_read::@10->fclose#0] -- register_copy 
    jsr fclose
    // [1284] phi from rom_read::@10 to rom_read::@3 [phi:rom_read::@10->rom_read::@3]
    // [1284] phi __stdio_filecount#30 = __stdio_filecount#2 [phi:rom_read::@10->rom_read::@3#0] -- register_copy 
    // [1284] phi rom_read::return#0 = rom_read::rom_file_size#13 [phi:rom_read::@10->rom_read::@3#1] -- register_copy 
    rts
    // [1284] phi from rom_read::@31 to rom_read::@3 [phi:rom_read::@31->rom_read::@3]
  __b4:
    // [1284] phi __stdio_filecount#30 = __stdio_filecount#1 [phi:rom_read::@31->rom_read::@3#0] -- register_copy 
    // [1284] phi rom_read::return#0 = 0 [phi:rom_read::@31->rom_read::@3#1] -- vdum1=vduc1 
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
    // [1285] return 
    rts
    // rom_read::@6
  __b6:
    // if(info_status == STATUS_CHECKING)
    // [1286] if(rom_read::info_status#11!=STATUS_CHECKING) goto rom_read::@35 -- vbuz1_neq_vbuc1_then_la1 
    lda #STATUS_CHECKING
    cmp.z info_status
    bne __b7
    // [1288] phi from rom_read::@6 to rom_read::@7 [phi:rom_read::@6->rom_read::@7]
    // [1288] phi rom_read::rom_bram_ptr#10 = (char *) 1024 [phi:rom_read::@6->rom_read::@7#0] -- pbuz1=pbuc1 
    lda #<$400
    sta.z rom_bram_ptr
    lda #>$400
    sta.z rom_bram_ptr+1
    // [1287] phi from rom_read::@6 to rom_read::@35 [phi:rom_read::@6->rom_read::@35]
    // rom_read::@35
    // [1288] phi from rom_read::@35 to rom_read::@7 [phi:rom_read::@35->rom_read::@7]
    // [1288] phi rom_read::rom_bram_ptr#10 = rom_read::rom_bram_ptr#13 [phi:rom_read::@35->rom_read::@7#0] -- register_copy 
    // rom_read::@7
  __b7:
    // display_action_text_reading(rom_action_text, file, rom_file_size, rom_size, rom_bram_bank, rom_bram_ptr)
    // [1289] display_action_text_reading::action#1 = rom_read::rom_action_text#10 -- pbuz1=pbuz2 
    lda.z rom_action_text
    sta.z display_action_text_reading.action
    lda.z rom_action_text+1
    sta.z display_action_text_reading.action+1
    // [1290] display_action_text_reading::file#1 = rom_read::file#10 -- pbuz1=pbuz2 
    lda.z file
    sta.z display_action_text_reading.file
    lda.z file+1
    sta.z display_action_text_reading.file+1
    // [1291] display_action_text_reading::bytes#1 = rom_read::rom_file_size#13 -- vduz1=vdum2 
    lda rom_file_size
    sta.z display_action_text_reading.bytes
    lda rom_file_size+1
    sta.z display_action_text_reading.bytes+1
    lda rom_file_size+2
    sta.z display_action_text_reading.bytes+2
    lda rom_file_size+3
    sta.z display_action_text_reading.bytes+3
    // [1292] display_action_text_reading::size#1 = rom_read::rom_size#12 -- vduz1=vduz2 
    lda.z rom_size
    sta.z display_action_text_reading.size
    lda.z rom_size+1
    sta.z display_action_text_reading.size+1
    lda.z rom_size+2
    sta.z display_action_text_reading.size+2
    lda.z rom_size+3
    sta.z display_action_text_reading.size+3
    // [1293] display_action_text_reading::bram_bank#1 = rom_read::rom_bram_bank#10 -- vbuz1=vbuz2 
    lda.z rom_bram_bank
    sta.z display_action_text_reading.bram_bank
    // [1294] display_action_text_reading::bram_ptr#1 = rom_read::rom_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z rom_bram_ptr
    sta.z display_action_text_reading.bram_ptr
    lda.z rom_bram_ptr+1
    sta.z display_action_text_reading.bram_ptr+1
    // [1295] call display_action_text_reading
    // [2283] phi from rom_read::@7 to display_action_text_reading [phi:rom_read::@7->display_action_text_reading]
    // [2283] phi display_action_text_reading::bram_ptr#10 = display_action_text_reading::bram_ptr#1 [phi:rom_read::@7->display_action_text_reading#0] -- register_copy 
    // [2283] phi display_action_text_reading::bram_bank#10 = display_action_text_reading::bram_bank#1 [phi:rom_read::@7->display_action_text_reading#1] -- register_copy 
    // [2283] phi display_action_text_reading::size#2 = display_action_text_reading::size#1 [phi:rom_read::@7->display_action_text_reading#2] -- register_copy 
    // [2283] phi display_action_text_reading::bytes#2 = display_action_text_reading::bytes#1 [phi:rom_read::@7->display_action_text_reading#3] -- register_copy 
    // [2283] phi display_action_text_reading::file#2 = display_action_text_reading::file#1 [phi:rom_read::@7->display_action_text_reading#4] -- register_copy 
    // [2283] phi display_action_text_reading::action#2 = display_action_text_reading::action#1 [phi:rom_read::@7->display_action_text_reading#5] -- register_copy 
    jsr display_action_text_reading
    // rom_read::@32
    // rom_address % 0x04000
    // [1296] rom_read::$13 = rom_read::rom_address#10 & $4000-1 -- vduz1=vdum2_band_vduc1 
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
    // [1297] if(0!=rom_read::$13) goto rom_read::@8 -- 0_neq_vduz1_then_la1 
    lda.z rom_read__13
    ora.z rom_read__13+1
    ora.z rom_read__13+2
    ora.z rom_read__13+3
    bne __b8
    // rom_read::@17
    // brom_bank_start++;
    // [1298] rom_read::brom_bank_start#0 = ++ rom_read::brom_bank_start#11 -- vbuz1=_inc_vbuz1 
    inc.z brom_bank_start
    // [1299] phi from rom_read::@17 rom_read::@32 to rom_read::@8 [phi:rom_read::@17/rom_read::@32->rom_read::@8]
    // [1299] phi rom_read::brom_bank_start#16 = rom_read::brom_bank_start#0 [phi:rom_read::@17/rom_read::@32->rom_read::@8#0] -- register_copy 
    // rom_read::@8
  __b8:
    // rom_read::bank_set_bram2
    // BRAM = bank
    // [1300] BRAM = rom_read::rom_bram_bank#10 -- vbuz1=vbuz2 
    lda.z rom_bram_bank
    sta.z BRAM
    // rom_read::@24
    // unsigned int rom_package_read = fgets(rom_bram_ptr, ROM_PROGRESS_CELL, fp)
    // [1301] fgets::ptr#4 = rom_read::rom_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z rom_bram_ptr
    sta.z fgets.ptr
    lda.z rom_bram_ptr+1
    sta.z fgets.ptr+1
    // [1302] fgets::stream#2 = rom_read::fp#0 -- pssz1=pssm2 
    lda fp
    sta.z fgets.stream
    lda fp+1
    sta.z fgets.stream+1
    // [1303] call fgets
    // [2314] phi from rom_read::@24 to fgets [phi:rom_read::@24->fgets]
    // [2314] phi fgets::ptr#13 = fgets::ptr#4 [phi:rom_read::@24->fgets#0] -- register_copy 
    // [2314] phi fgets::size#11 = ROM_PROGRESS_CELL [phi:rom_read::@24->fgets#1] -- vwum1=vwuc1 
    lda #<ROM_PROGRESS_CELL
    sta fgets.size
    lda #>ROM_PROGRESS_CELL
    sta fgets.size+1
    // [2314] phi fgets::stream#3 = fgets::stream#2 [phi:rom_read::@24->fgets#2] -- register_copy 
    jsr fgets
    // unsigned int rom_package_read = fgets(rom_bram_ptr, ROM_PROGRESS_CELL, fp)
    // [1304] fgets::return#11 = fgets::return#1
    // rom_read::@33
    // [1305] rom_read::rom_package_read#0 = fgets::return#11 -- vwuz1=vwum2 
    lda fgets.return
    sta.z rom_package_read
    lda fgets.return+1
    sta.z rom_package_read+1
    // if (!rom_package_read)
    // [1306] if(0!=rom_read::rom_package_read#0) goto rom_read::@9 -- 0_neq_vwuz1_then_la1 
    lda.z rom_package_read
    ora.z rom_package_read+1
    bne __b9
    jmp __b10
    // rom_read::@9
  __b9:
    // if(info_status == STATUS_CHECKING)
    // [1307] if(rom_read::info_status#11!=STATUS_CHECKING) goto rom_read::@11 -- vbuz1_neq_vbuc1_then_la1 
    lda #STATUS_CHECKING
    cmp.z info_status
    bne __b11
    // rom_read::@18
    // if(rom_file_size == 0x0)
    // [1308] if(rom_read::rom_file_size#13!=0) goto rom_read::@12 -- vdum1_neq_0_then_la1 
    lda rom_file_size
    ora rom_file_size+1
    ora rom_file_size+2
    ora rom_file_size+3
    bne __b12
    // rom_read::@19
    // rom_chip*8
    // [1309] rom_read::$24 = rom_read::rom_chip#20 << 3 -- vbuz1=vbuz2_rol_3 
    lda.z rom_chip
    asl
    asl
    asl
    sta.z rom_read__24
    // rom_get_github_commit_id(&rom_file_github[rom_chip*8], (char*)0x0400)
    // [1310] rom_get_github_commit_id::commit_id#0 = rom_file_github + rom_read::$24 -- pbuz1=pbuc1_plus_vbuz2 
    clc
    adc #<rom_file_github
    sta.z rom_get_github_commit_id.commit_id
    lda #>rom_file_github
    adc #0
    sta.z rom_get_github_commit_id.commit_id+1
    // [1311] call rom_get_github_commit_id
    // [1818] phi from rom_read::@19 to rom_get_github_commit_id [phi:rom_read::@19->rom_get_github_commit_id]
    // [1818] phi rom_get_github_commit_id::commit_id#6 = rom_get_github_commit_id::commit_id#0 [phi:rom_read::@19->rom_get_github_commit_id#0] -- register_copy 
    // [1818] phi rom_get_github_commit_id::from#6 = (char *) 1024 [phi:rom_read::@19->rom_get_github_commit_id#1] -- pbuz1=pbuc1 
    lda #<$400
    sta.z rom_get_github_commit_id.from
    lda #>$400
    sta.z rom_get_github_commit_id.from+1
    jsr rom_get_github_commit_id
    // rom_read::@12
  __b12:
    // if(rom_file_size == 0x3E00)
    // [1312] if(rom_read::rom_file_size#13!=$3e00) goto rom_read::@11 -- vdum1_neq_vduc1_then_la1 
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
    // [1313] rom_file_release[rom_read::rom_chip#20] = *((char *)$400+$180) -- pbuc1_derefidx_vbuz1=_deref_pbuc2 
    lda $400+$180
    ldy.z rom_chip
    sta rom_file_release,y
    // rom_read::@11
  __b11:
    // if (rom_row_current == ROM_PROGRESS_ROW)
    // [1314] if(rom_read::rom_row_current#10!=ROM_PROGRESS_ROW) goto rom_read::@14 -- vwuz1_neq_vwuc1_then_la1 
    lda.z rom_row_current+1
    cmp #>ROM_PROGRESS_ROW
    bne __b14
    lda.z rom_row_current
    cmp #<ROM_PROGRESS_ROW
    bne __b14
    // rom_read::@20
    // gotoxy(x, ++y);
    // [1315] rom_read::y#1 = ++ rom_read::y#11 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [1316] gotoxy::y#28 = rom_read::y#1 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [1317] call gotoxy
    // [778] phi from rom_read::@20 to gotoxy [phi:rom_read::@20->gotoxy]
    // [778] phi gotoxy::y#33 = gotoxy::y#28 [phi:rom_read::@20->gotoxy#0] -- register_copy 
    // [778] phi gotoxy::x#33 = PROGRESS_X [phi:rom_read::@20->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1318] phi from rom_read::@20 to rom_read::@14 [phi:rom_read::@20->rom_read::@14]
    // [1318] phi rom_read::y#33 = rom_read::y#1 [phi:rom_read::@20->rom_read::@14#0] -- register_copy 
    // [1318] phi rom_read::rom_row_current#4 = 0 [phi:rom_read::@20->rom_read::@14#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z rom_row_current
    sta.z rom_row_current+1
    // [1318] phi from rom_read::@11 to rom_read::@14 [phi:rom_read::@11->rom_read::@14]
    // [1318] phi rom_read::y#33 = rom_read::y#11 [phi:rom_read::@11->rom_read::@14#0] -- register_copy 
    // [1318] phi rom_read::rom_row_current#4 = rom_read::rom_row_current#10 [phi:rom_read::@11->rom_read::@14#1] -- register_copy 
    // rom_read::@14
  __b14:
    // if(info_status == STATUS_READING)
    // [1319] if(rom_read::info_status#11!=STATUS_READING) goto rom_read::@15 -- vbuz1_neq_vbuc1_then_la1 
    lda #STATUS_READING
    cmp.z info_status
    bne __b15
    // rom_read::@21
    // cputc('.')
    // [1320] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [1321] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_read::@15
  __b15:
    // rom_bram_ptr += rom_package_read
    // [1323] rom_read::rom_bram_ptr#2 = rom_read::rom_bram_ptr#10 + rom_read::rom_package_read#0 -- pbuz1=pbuz1_plus_vwuz2 
    clc
    lda.z rom_bram_ptr
    adc.z rom_package_read
    sta.z rom_bram_ptr
    lda.z rom_bram_ptr+1
    adc.z rom_package_read+1
    sta.z rom_bram_ptr+1
    // rom_address += rom_package_read
    // [1324] rom_read::rom_address#1 = rom_read::rom_address#10 + rom_read::rom_package_read#0 -- vdum1=vdum1_plus_vwuz2 
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
    // [1325] rom_read::rom_file_size#1 = rom_read::rom_file_size#13 + rom_read::rom_package_read#0 -- vdum1=vdum1_plus_vwuz2 
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
    // [1326] rom_read::rom_row_current#2 = rom_read::rom_row_current#4 + rom_read::rom_package_read#0 -- vwuz1=vwuz1_plus_vwuz2 
    clc
    lda.z rom_row_current
    adc.z rom_package_read
    sta.z rom_row_current
    lda.z rom_row_current+1
    adc.z rom_package_read+1
    sta.z rom_row_current+1
    // if (rom_bram_ptr == (bram_ptr_t)BRAM_HIGH)
    // [1327] if(rom_read::rom_bram_ptr#2!=(char *)$c000) goto rom_read::@16 -- pbuz1_neq_pbuc1_then_la1 
    lda.z rom_bram_ptr+1
    cmp #>$c000
    bne __b16
    lda.z rom_bram_ptr
    cmp #<$c000
    bne __b16
    // rom_read::@22
    // rom_bram_bank++;
    // [1328] rom_read::rom_bram_bank#1 = ++ rom_read::rom_bram_bank#10 -- vbuz1=_inc_vbuz1 
    inc.z rom_bram_bank
    // [1329] phi from rom_read::@22 to rom_read::@16 [phi:rom_read::@22->rom_read::@16]
    // [1329] phi rom_read::rom_bram_bank#14 = rom_read::rom_bram_bank#1 [phi:rom_read::@22->rom_read::@16#0] -- register_copy 
    // [1329] phi rom_read::rom_bram_ptr#8 = (char *)$a000 [phi:rom_read::@22->rom_read::@16#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z rom_bram_ptr
    lda #>$a000
    sta.z rom_bram_ptr+1
    // [1329] phi from rom_read::@15 to rom_read::@16 [phi:rom_read::@15->rom_read::@16]
    // [1329] phi rom_read::rom_bram_bank#14 = rom_read::rom_bram_bank#10 [phi:rom_read::@15->rom_read::@16#0] -- register_copy 
    // [1329] phi rom_read::rom_bram_ptr#8 = rom_read::rom_bram_ptr#2 [phi:rom_read::@15->rom_read::@16#1] -- register_copy 
    // rom_read::@16
  __b16:
    // if (rom_bram_ptr == (bram_ptr_t)RAM_HIGH)
    // [1330] if(rom_read::rom_bram_ptr#8!=(char *)$9800) goto rom_read::@34 -- pbuz1_neq_pbuc1_then_la1 
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
    // [1280] phi from rom_read::@16 to rom_read::@5 [phi:rom_read::@16->rom_read::@5]
    // [1280] phi rom_read::y#11 = rom_read::y#33 [phi:rom_read::@16->rom_read::@5#0] -- register_copy 
    // [1280] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#2 [phi:rom_read::@16->rom_read::@5#1] -- register_copy 
    // [1280] phi rom_read::brom_bank_start#11 = rom_read::brom_bank_start#16 [phi:rom_read::@16->rom_read::@5#2] -- register_copy 
    // [1280] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@16->rom_read::@5#3] -- register_copy 
    // [1280] phi rom_read::rom_bram_ptr#13 = (char *)$a000 [phi:rom_read::@16->rom_read::@5#4] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z rom_bram_ptr
    lda #>$a000
    sta.z rom_bram_ptr+1
    // [1280] phi rom_read::rom_bram_bank#10 = 1 [phi:rom_read::@16->rom_read::@5#5] -- vbuz1=vbuc1 
    lda #1
    sta.z rom_bram_bank
    // [1280] phi rom_read::rom_file_size#13 = rom_read::rom_file_size#1 [phi:rom_read::@16->rom_read::@5#6] -- register_copy 
    jmp __b5
    // [1331] phi from rom_read::@16 to rom_read::@34 [phi:rom_read::@16->rom_read::@34]
    // rom_read::@34
    // [1280] phi from rom_read::@34 to rom_read::@5 [phi:rom_read::@34->rom_read::@5]
    // [1280] phi rom_read::y#11 = rom_read::y#33 [phi:rom_read::@34->rom_read::@5#0] -- register_copy 
    // [1280] phi rom_read::rom_row_current#10 = rom_read::rom_row_current#2 [phi:rom_read::@34->rom_read::@5#1] -- register_copy 
    // [1280] phi rom_read::brom_bank_start#11 = rom_read::brom_bank_start#16 [phi:rom_read::@34->rom_read::@5#2] -- register_copy 
    // [1280] phi rom_read::rom_address#10 = rom_read::rom_address#1 [phi:rom_read::@34->rom_read::@5#3] -- register_copy 
    // [1280] phi rom_read::rom_bram_ptr#13 = rom_read::rom_bram_ptr#8 [phi:rom_read::@34->rom_read::@5#4] -- register_copy 
    // [1280] phi rom_read::rom_bram_bank#10 = rom_read::rom_bram_bank#14 [phi:rom_read::@34->rom_read::@5#5] -- register_copy 
    // [1280] phi rom_read::rom_file_size#13 = rom_read::rom_file_size#1 [phi:rom_read::@34->rom_read::@5#6] -- register_copy 
  .segment Data
    s: .text "Opening "
    .byte 0
    s1: .text " from SD card ..."
    .byte 0
    .label rom_address = rom_read_byte.address
    .label fp = smc_flash.smc_commit_result
    return: .dword 0
    .label rom_file_size = return
}
.segment Code
  // rom_verify
// __zp($6f) unsigned long rom_verify(__mem() char rom_chip, __mem() char rom_bank_start, __mem() unsigned long file_size)
rom_verify: {
    .label rom_verify__17 = $5e
    .label rom_address = $62
    .label equal_bytes = $5e
    .label y = $a9
    .label rom_bram_ptr = $3b
    // We start for ROM from 0x0:0x7800 !!!!
    .label rom_bram_bank = $ac
    .label rom_different_bytes = $6f
    .label return = $6f
    .label progress_row_current = $39
    // rom_verify::bank_set_bram1
    // BRAM = bank
    // [1333] BRAM = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z BRAM
    // rom_verify::@11
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [1334] rom_address_from_bank::rom_bank#1 = rom_verify::rom_bank_start#0
    // [1335] call rom_address_from_bank
    // [2169] phi from rom_verify::@11 to rom_address_from_bank [phi:rom_verify::@11->rom_address_from_bank]
    // [2169] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#1 [phi:rom_verify::@11->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address = rom_address_from_bank(rom_bank_start)
    // [1336] rom_address_from_bank::return#3 = rom_address_from_bank::return#0 -- vduz1=vdum2 
    lda rom_address_from_bank.return
    sta.z rom_address_from_bank.return_1
    lda rom_address_from_bank.return+1
    sta.z rom_address_from_bank.return_1+1
    lda rom_address_from_bank.return+2
    sta.z rom_address_from_bank.return_1+2
    lda rom_address_from_bank.return+3
    sta.z rom_address_from_bank.return_1+3
    // rom_verify::@12
    // [1337] rom_verify::rom_address#0 = rom_address_from_bank::return#3
    // unsigned long rom_boundary = rom_address + file_size
    // [1338] rom_verify::rom_boundary#0 = rom_verify::rom_address#0 + rom_verify::file_size#0 -- vdum1=vduz2_plus_vdum1 
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
    // display_info_rom(rom_chip, STATUS_COMPARING, "Comparing ...")
    // [1339] display_info_rom::rom_chip#2 = rom_verify::rom_chip#0
    // [1340] call display_info_rom
    // [1176] phi from rom_verify::@12 to display_info_rom [phi:rom_verify::@12->display_info_rom]
    // [1176] phi display_info_rom::info_text#16 = rom_verify::info_text [phi:rom_verify::@12->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_info_rom.info_text
    lda #>info_text
    sta.z display_info_rom.info_text+1
    // [1176] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#2 [phi:rom_verify::@12->display_info_rom#1] -- register_copy 
    // [1176] phi display_info_rom::info_status#16 = STATUS_COMPARING [phi:rom_verify::@12->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_COMPARING
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // [1341] phi from rom_verify::@12 to rom_verify::@13 [phi:rom_verify::@12->rom_verify::@13]
    // rom_verify::@13
    // gotoxy(x, y)
    // [1342] call gotoxy
    // [778] phi from rom_verify::@13 to gotoxy [phi:rom_verify::@13->gotoxy]
    // [778] phi gotoxy::y#33 = PROGRESS_Y [phi:rom_verify::@13->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [778] phi gotoxy::x#33 = PROGRESS_X [phi:rom_verify::@13->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1343] phi from rom_verify::@13 to rom_verify::@1 [phi:rom_verify::@13->rom_verify::@1]
    // [1343] phi rom_verify::y#3 = PROGRESS_Y [phi:rom_verify::@13->rom_verify::@1#0] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y
    // [1343] phi rom_verify::progress_row_current#3 = 0 [phi:rom_verify::@13->rom_verify::@1#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z progress_row_current
    sta.z progress_row_current+1
    // [1343] phi rom_verify::rom_different_bytes#11 = 0 [phi:rom_verify::@13->rom_verify::@1#2] -- vduz1=vduc1 
    sta.z rom_different_bytes
    sta.z rom_different_bytes+1
    lda #<0>>$10
    sta.z rom_different_bytes+2
    lda #>0>>$10
    sta.z rom_different_bytes+3
    // [1343] phi rom_verify::rom_bram_ptr#10 = (char *)$7800 [phi:rom_verify::@13->rom_verify::@1#3] -- pbuz1=pbuc1 
    lda #<$7800
    sta.z rom_bram_ptr
    lda #>$7800
    sta.z rom_bram_ptr+1
    // [1343] phi rom_verify::rom_bram_bank#11 = 0 [phi:rom_verify::@13->rom_verify::@1#4] -- vbuz1=vbuc1 
    lda #0
    sta.z rom_bram_bank
    // [1343] phi rom_verify::rom_address#12 = rom_verify::rom_address#0 [phi:rom_verify::@13->rom_verify::@1#5] -- register_copy 
    // rom_verify::@1
  __b1:
    // while (rom_address < rom_boundary)
    // [1344] if(rom_verify::rom_address#12<rom_verify::rom_boundary#0) goto rom_verify::@2 -- vduz1_lt_vdum2_then_la1 
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
    // [1345] return 
    rts
    // rom_verify::@2
  __b2:
    // unsigned int equal_bytes = rom_compare(rom_bram_bank, (bram_ptr_t)rom_bram_ptr, rom_address, ROM_PROGRESS_CELL)
    // [1346] rom_compare::bank_ram#0 = rom_verify::rom_bram_bank#11
    // [1347] rom_compare::ptr_ram#1 = rom_verify::rom_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z rom_bram_ptr
    sta.z rom_compare.ptr_ram
    lda.z rom_bram_ptr+1
    sta.z rom_compare.ptr_ram+1
    // [1348] rom_compare::rom_compare_address#0 = rom_verify::rom_address#12 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_compare.rom_compare_address
    lda.z rom_address+1
    sta.z rom_compare.rom_compare_address+1
    lda.z rom_address+2
    sta.z rom_compare.rom_compare_address+2
    lda.z rom_address+3
    sta.z rom_compare.rom_compare_address+3
    // [1349] call rom_compare
  // {asm{.byte $db}}
    // [2368] phi from rom_verify::@2 to rom_compare [phi:rom_verify::@2->rom_compare]
    // [2368] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#1 [phi:rom_verify::@2->rom_compare#0] -- register_copy 
    // [2368] phi rom_compare::rom_compare_size#11 = ROM_PROGRESS_CELL [phi:rom_verify::@2->rom_compare#1] -- vwuz1=vwuc1 
    lda #<ROM_PROGRESS_CELL
    sta.z rom_compare.rom_compare_size
    lda #>ROM_PROGRESS_CELL
    sta.z rom_compare.rom_compare_size+1
    // [2368] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#0 [phi:rom_verify::@2->rom_compare#2] -- register_copy 
    // [2368] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#0 [phi:rom_verify::@2->rom_compare#3] -- vbum1=vbuz2 
    lda.z rom_compare.bank_ram
    sta rom_compare.bank_set_bram1_bank
    jsr rom_compare
    // unsigned int equal_bytes = rom_compare(rom_bram_bank, (bram_ptr_t)rom_bram_ptr, rom_address, ROM_PROGRESS_CELL)
    // [1350] rom_compare::return#2 = rom_compare::equal_bytes#2
    // rom_verify::@14
    // [1351] rom_verify::equal_bytes#0 = rom_compare::return#2
    // if (progress_row_current == ROM_PROGRESS_ROW)
    // [1352] if(rom_verify::progress_row_current#3!=ROM_PROGRESS_ROW) goto rom_verify::@3 -- vwuz1_neq_vwuc1_then_la1 
    lda.z progress_row_current+1
    cmp #>ROM_PROGRESS_ROW
    bne __b3
    lda.z progress_row_current
    cmp #<ROM_PROGRESS_ROW
    bne __b3
    // rom_verify::@8
    // gotoxy(x, ++y);
    // [1353] rom_verify::y#1 = ++ rom_verify::y#3 -- vbuz1=_inc_vbuz1 
    inc.z y
    // gotoxy(x, ++y)
    // [1354] gotoxy::y#30 = rom_verify::y#1 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [1355] call gotoxy
    // [778] phi from rom_verify::@8 to gotoxy [phi:rom_verify::@8->gotoxy]
    // [778] phi gotoxy::y#33 = gotoxy::y#30 [phi:rom_verify::@8->gotoxy#0] -- register_copy 
    // [778] phi gotoxy::x#33 = PROGRESS_X [phi:rom_verify::@8->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1356] phi from rom_verify::@8 to rom_verify::@3 [phi:rom_verify::@8->rom_verify::@3]
    // [1356] phi rom_verify::y#11 = rom_verify::y#1 [phi:rom_verify::@8->rom_verify::@3#0] -- register_copy 
    // [1356] phi rom_verify::progress_row_current#4 = 0 [phi:rom_verify::@8->rom_verify::@3#1] -- vwuz1=vbuc1 
    lda #<0
    sta.z progress_row_current
    sta.z progress_row_current+1
    // [1356] phi from rom_verify::@14 to rom_verify::@3 [phi:rom_verify::@14->rom_verify::@3]
    // [1356] phi rom_verify::y#11 = rom_verify::y#3 [phi:rom_verify::@14->rom_verify::@3#0] -- register_copy 
    // [1356] phi rom_verify::progress_row_current#4 = rom_verify::progress_row_current#3 [phi:rom_verify::@14->rom_verify::@3#1] -- register_copy 
    // rom_verify::@3
  __b3:
    // if (equal_bytes != ROM_PROGRESS_CELL)
    // [1357] if(rom_verify::equal_bytes#0!=ROM_PROGRESS_CELL) goto rom_verify::@4 -- vwuz1_neq_vwuc1_then_la1 
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
    // [1358] stackpush(char) = '=' -- _stackpushbyte_=vbuc1 
    lda #'='
    pha
    // [1359] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_verify::@5
  __b5:
    // rom_bram_ptr += ROM_PROGRESS_CELL
    // [1361] rom_verify::rom_bram_ptr#1 = rom_verify::rom_bram_ptr#10 + ROM_PROGRESS_CELL -- pbuz1=pbuz1_plus_vwuc1 
    lda.z rom_bram_ptr
    clc
    adc #<ROM_PROGRESS_CELL
    sta.z rom_bram_ptr
    lda.z rom_bram_ptr+1
    adc #>ROM_PROGRESS_CELL
    sta.z rom_bram_ptr+1
    // rom_address += ROM_PROGRESS_CELL
    // [1362] rom_verify::rom_address#1 = rom_verify::rom_address#12 + ROM_PROGRESS_CELL -- vduz1=vduz1_plus_vwuc1 
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
    // [1363] rom_verify::progress_row_current#11 = rom_verify::progress_row_current#4 + ROM_PROGRESS_CELL -- vwuz1=vwuz1_plus_vwuc1 
    lda.z progress_row_current
    clc
    adc #<ROM_PROGRESS_CELL
    sta.z progress_row_current
    lda.z progress_row_current+1
    adc #>ROM_PROGRESS_CELL
    sta.z progress_row_current+1
    // if (rom_bram_ptr == BRAM_HIGH)
    // [1364] if(rom_verify::rom_bram_ptr#1!=$c000) goto rom_verify::@6 -- pbuz1_neq_vwuc1_then_la1 
    lda.z rom_bram_ptr+1
    cmp #>$c000
    bne __b6
    lda.z rom_bram_ptr
    cmp #<$c000
    bne __b6
    // rom_verify::@10
    // rom_bram_bank++;
    // [1365] rom_verify::rom_bram_bank#1 = ++ rom_verify::rom_bram_bank#11 -- vbuz1=_inc_vbuz1 
    inc.z rom_bram_bank
    // [1366] phi from rom_verify::@10 to rom_verify::@6 [phi:rom_verify::@10->rom_verify::@6]
    // [1366] phi rom_verify::rom_bram_bank#25 = rom_verify::rom_bram_bank#1 [phi:rom_verify::@10->rom_verify::@6#0] -- register_copy 
    // [1366] phi rom_verify::rom_bram_ptr#6 = (char *)$a000 [phi:rom_verify::@10->rom_verify::@6#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z rom_bram_ptr
    lda #>$a000
    sta.z rom_bram_ptr+1
    // [1366] phi from rom_verify::@5 to rom_verify::@6 [phi:rom_verify::@5->rom_verify::@6]
    // [1366] phi rom_verify::rom_bram_bank#25 = rom_verify::rom_bram_bank#11 [phi:rom_verify::@5->rom_verify::@6#0] -- register_copy 
    // [1366] phi rom_verify::rom_bram_ptr#6 = rom_verify::rom_bram_ptr#1 [phi:rom_verify::@5->rom_verify::@6#1] -- register_copy 
    // rom_verify::@6
  __b6:
    // if (rom_bram_ptr == RAM_HIGH)
    // [1367] if(rom_verify::rom_bram_ptr#6!=$9800) goto rom_verify::@24 -- pbuz1_neq_vwuc1_then_la1 
    lda.z rom_bram_ptr+1
    cmp #>$9800
    bne __b7
    lda.z rom_bram_ptr
    cmp #<$9800
    bne __b7
    // [1369] phi from rom_verify::@6 to rom_verify::@7 [phi:rom_verify::@6->rom_verify::@7]
    // [1369] phi rom_verify::rom_bram_ptr#11 = (char *)$a000 [phi:rom_verify::@6->rom_verify::@7#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z rom_bram_ptr
    lda #>$a000
    sta.z rom_bram_ptr+1
    // [1369] phi rom_verify::rom_bram_bank#10 = 1 [phi:rom_verify::@6->rom_verify::@7#1] -- vbuz1=vbuc1 
    lda #1
    sta.z rom_bram_bank
    // [1368] phi from rom_verify::@6 to rom_verify::@24 [phi:rom_verify::@6->rom_verify::@24]
    // rom_verify::@24
    // [1369] phi from rom_verify::@24 to rom_verify::@7 [phi:rom_verify::@24->rom_verify::@7]
    // [1369] phi rom_verify::rom_bram_ptr#11 = rom_verify::rom_bram_ptr#6 [phi:rom_verify::@24->rom_verify::@7#0] -- register_copy 
    // [1369] phi rom_verify::rom_bram_bank#10 = rom_verify::rom_bram_bank#25 [phi:rom_verify::@24->rom_verify::@7#1] -- register_copy 
    // rom_verify::@7
  __b7:
    // ROM_PROGRESS_CELL - equal_bytes
    // [1370] rom_verify::$17 = ROM_PROGRESS_CELL - rom_verify::equal_bytes#0 -- vwuz1=vwuc1_minus_vwuz1 
    lda #<ROM_PROGRESS_CELL
    sec
    sbc.z rom_verify__17
    sta.z rom_verify__17
    lda #>ROM_PROGRESS_CELL
    sbc.z rom_verify__17+1
    sta.z rom_verify__17+1
    // rom_different_bytes += (ROM_PROGRESS_CELL - equal_bytes)
    // [1371] rom_verify::rom_different_bytes#1 = rom_verify::rom_different_bytes#11 + rom_verify::$17 -- vduz1=vduz1_plus_vwuz2 
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
    // [1372] call snprintf_init
    // [1113] phi from rom_verify::@7 to snprintf_init [phi:rom_verify::@7->snprintf_init]
    // [1113] phi snprintf_init::s#25 = info_text [phi:rom_verify::@7->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1373] phi from rom_verify::@7 to rom_verify::@15 [phi:rom_verify::@7->rom_verify::@15]
    // rom_verify::@15
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1374] call printf_str
    // [1054] phi from rom_verify::@15 to printf_str [phi:rom_verify::@15->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:rom_verify::@15->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = rom_verify::s [phi:rom_verify::@15->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@16
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1375] printf_ulong::uvalue#5 = rom_verify::rom_different_bytes#1 -- vdum1=vduz2 
    lda.z rom_different_bytes
    sta printf_ulong.uvalue
    lda.z rom_different_bytes+1
    sta printf_ulong.uvalue+1
    lda.z rom_different_bytes+2
    sta printf_ulong.uvalue+2
    lda.z rom_different_bytes+3
    sta printf_ulong.uvalue+3
    // [1376] call printf_ulong
    // [1396] phi from rom_verify::@16 to printf_ulong [phi:rom_verify::@16->printf_ulong]
    // [1396] phi printf_ulong::format_zero_padding#10 = 1 [phi:rom_verify::@16->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1396] phi printf_ulong::format_min_length#10 = 5 [phi:rom_verify::@16->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1396] phi printf_ulong::format_radix#10 = HEXADECIMAL [phi:rom_verify::@16->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1396] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#5 [phi:rom_verify::@16->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1377] phi from rom_verify::@16 to rom_verify::@17 [phi:rom_verify::@16->rom_verify::@17]
    // rom_verify::@17
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1378] call printf_str
    // [1054] phi from rom_verify::@17 to printf_str [phi:rom_verify::@17->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:rom_verify::@17->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = rom_verify::s1 [phi:rom_verify::@17->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@18
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1379] printf_uchar::uvalue#14 = rom_verify::rom_bram_bank#10 -- vbum1=vbuz2 
    lda.z rom_bram_bank
    sta printf_uchar.uvalue
    // [1380] call printf_uchar
    // [1118] phi from rom_verify::@18 to printf_uchar [phi:rom_verify::@18->printf_uchar]
    // [1118] phi printf_uchar::format_zero_padding#17 = 1 [phi:rom_verify::@18->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1118] phi printf_uchar::format_min_length#17 = 2 [phi:rom_verify::@18->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1118] phi printf_uchar::putc#17 = &snputc [phi:rom_verify::@18->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1118] phi printf_uchar::format_radix#17 = HEXADECIMAL [phi:rom_verify::@18->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1118] phi printf_uchar::uvalue#17 = printf_uchar::uvalue#14 [phi:rom_verify::@18->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1381] phi from rom_verify::@18 to rom_verify::@19 [phi:rom_verify::@18->rom_verify::@19]
    // rom_verify::@19
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1382] call printf_str
    // [1054] phi from rom_verify::@19 to printf_str [phi:rom_verify::@19->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:rom_verify::@19->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = s2 [phi:rom_verify::@19->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@20
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1383] printf_uint::uvalue#5 = (unsigned int)rom_verify::rom_bram_ptr#11 -- vwum1=vwuz2 
    lda.z rom_bram_ptr
    sta printf_uint.uvalue
    lda.z rom_bram_ptr+1
    sta printf_uint.uvalue+1
    // [1384] call printf_uint
    // [1835] phi from rom_verify::@20 to printf_uint [phi:rom_verify::@20->printf_uint]
    // [1835] phi printf_uint::format_zero_padding#10 = 1 [phi:rom_verify::@20->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [1835] phi printf_uint::format_min_length#10 = 4 [phi:rom_verify::@20->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [1835] phi printf_uint::putc#10 = &snputc [phi:rom_verify::@20->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [1835] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:rom_verify::@20->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [1835] phi printf_uint::uvalue#10 = printf_uint::uvalue#5 [phi:rom_verify::@20->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [1385] phi from rom_verify::@20 to rom_verify::@21 [phi:rom_verify::@20->rom_verify::@21]
    // rom_verify::@21
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1386] call printf_str
    // [1054] phi from rom_verify::@21 to printf_str [phi:rom_verify::@21->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:rom_verify::@21->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = rom_verify::s3 [phi:rom_verify::@21->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // rom_verify::@22
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1387] printf_ulong::uvalue#6 = rom_verify::rom_address#1 -- vdum1=vduz2 
    lda.z rom_address
    sta printf_ulong.uvalue
    lda.z rom_address+1
    sta printf_ulong.uvalue+1
    lda.z rom_address+2
    sta printf_ulong.uvalue+2
    lda.z rom_address+3
    sta printf_ulong.uvalue+3
    // [1388] call printf_ulong
    // [1396] phi from rom_verify::@22 to printf_ulong [phi:rom_verify::@22->printf_ulong]
    // [1396] phi printf_ulong::format_zero_padding#10 = 1 [phi:rom_verify::@22->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1396] phi printf_ulong::format_min_length#10 = 5 [phi:rom_verify::@22->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1396] phi printf_ulong::format_radix#10 = HEXADECIMAL [phi:rom_verify::@22->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1396] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#6 [phi:rom_verify::@22->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // rom_verify::@23
    // sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, rom_bram_bank, rom_bram_ptr, rom_address)
    // [1389] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1390] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1392] call display_action_text
    // [1129] phi from rom_verify::@23 to display_action_text [phi:rom_verify::@23->display_action_text]
    // [1129] phi display_action_text::info_text#17 = info_text [phi:rom_verify::@23->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1343] phi from rom_verify::@23 to rom_verify::@1 [phi:rom_verify::@23->rom_verify::@1]
    // [1343] phi rom_verify::y#3 = rom_verify::y#11 [phi:rom_verify::@23->rom_verify::@1#0] -- register_copy 
    // [1343] phi rom_verify::progress_row_current#3 = rom_verify::progress_row_current#11 [phi:rom_verify::@23->rom_verify::@1#1] -- register_copy 
    // [1343] phi rom_verify::rom_different_bytes#11 = rom_verify::rom_different_bytes#1 [phi:rom_verify::@23->rom_verify::@1#2] -- register_copy 
    // [1343] phi rom_verify::rom_bram_ptr#10 = rom_verify::rom_bram_ptr#11 [phi:rom_verify::@23->rom_verify::@1#3] -- register_copy 
    // [1343] phi rom_verify::rom_bram_bank#11 = rom_verify::rom_bram_bank#10 [phi:rom_verify::@23->rom_verify::@1#4] -- register_copy 
    // [1343] phi rom_verify::rom_address#12 = rom_verify::rom_address#1 [phi:rom_verify::@23->rom_verify::@1#5] -- register_copy 
    jmp __b1
    // rom_verify::@4
  __b4:
    // cputc('*')
    // [1393] stackpush(char) = '*' -- _stackpushbyte_=vbuc1 
    lda #'*'
    pha
    // [1394] callexecute cputc  -- call_vprc1 
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
    .label rom_boundary = file_size
    .label rom_chip = main.check_status_rom1_main__0
    .label rom_bank_start = main.check_status_smc7_main__0
    file_size: .dword 0
}
.segment Code
  // printf_ulong
// Print an unsigned int using a specific format
// void printf_ulong(void (*putc)(char), __mem() unsigned long uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, __mem() char format_radix)
printf_ulong: {
    // printf_ulong::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1397] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // ultoa(uvalue, printf_buffer.digits, format.radix)
    // [1398] ultoa::value#1 = printf_ulong::uvalue#10
    // [1399] ultoa::radix#0 = printf_ulong::format_radix#10
    // [1400] call ultoa
    // Format number into buffer
    jsr ultoa
    // printf_ulong::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1401] printf_number_buffer::buffer_sign#0 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [1402] printf_number_buffer::format_min_length#0 = printf_ulong::format_min_length#10
    // [1403] printf_number_buffer::format_zero_padding#0 = printf_ulong::format_zero_padding#10
    // [1404] call printf_number_buffer
  // Print using format
    // [2116] phi from printf_ulong::@2 to printf_number_buffer [phi:printf_ulong::@2->printf_number_buffer]
    // [2116] phi printf_number_buffer::putc#10 = &snputc [phi:printf_ulong::@2->printf_number_buffer#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_number_buffer.putc
    lda #>snputc
    sta.z printf_number_buffer.putc+1
    // [2116] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#0 [phi:printf_ulong::@2->printf_number_buffer#1] -- register_copy 
    // [2116] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#0 [phi:printf_ulong::@2->printf_number_buffer#2] -- register_copy 
    // [2116] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#0 [phi:printf_ulong::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_ulong::@return
    // }
    // [1405] return 
    rts
  .segment Data
    uvalue: .dword 0
    format_radix: .byte 0
    .label format_min_length = printf_uchar.format_min_length
    .label format_zero_padding = printf_uchar.format_zero_padding
}
.segment Code
  // rom_flash
// __zp($e8) unsigned long rom_flash(__mem() char rom_chip, __mem() char rom_bank_start, __mem() unsigned long file_size)
rom_flash: {
    .label rom_flash__29 = $f2
    .label equal_bytes = $5e
    .label ram_address_sector = $f0
    .label equal_bytes_1 = $d8
    .label retries = $f6
    .label flash_errors_sector = $b0
    .label ram_address = $d6
    .label rom_address = $d2
    .label x = $cb
    .label flash_errors = $e8
    // We start for ROM from 0x0:0x7800 !!!!
    .label bram_bank_sector = $dc
    .label x_sector = $dd
    .label y_sector = $e0
    .label return = $e8
    // rom_flash::bank_set_bram1
    // BRAM = bank
    // [1407] BRAM = 0 -- vbuz1=vbuc1 
    lda #0
    sta.z BRAM
    // [1408] phi from rom_flash::bank_set_bram1 to rom_flash::@19 [phi:rom_flash::bank_set_bram1->rom_flash::@19]
    // rom_flash::@19
    // display_action_progress("Flashing ... (-) equal, (+) flashed, (!) error.")
    // [1409] call display_action_progress
  // Now we compare the RAM with the actual ROM contents.
    // [1084] phi from rom_flash::@19 to display_action_progress [phi:rom_flash::@19->display_action_progress]
    // [1084] phi display_action_progress::info_text#20 = rom_flash::info_text [phi:rom_flash::@19->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // rom_flash::@20
    // unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start)
    // [1410] rom_address_from_bank::rom_bank#2 = rom_flash::rom_bank_start#0
    // [1411] call rom_address_from_bank
    // [2169] phi from rom_flash::@20 to rom_address_from_bank [phi:rom_flash::@20->rom_address_from_bank]
    // [2169] phi rom_address_from_bank::rom_bank#3 = rom_address_from_bank::rom_bank#2 [phi:rom_flash::@20->rom_address_from_bank#0] -- register_copy 
    jsr rom_address_from_bank
    // unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start)
    // [1412] rom_address_from_bank::return#4 = rom_address_from_bank::return#0 -- vdum1=vdum2 
    lda rom_address_from_bank.return
    sta rom_address_from_bank.return_2
    lda rom_address_from_bank.return+1
    sta rom_address_from_bank.return_2+1
    lda rom_address_from_bank.return+2
    sta rom_address_from_bank.return_2+2
    lda rom_address_from_bank.return+3
    sta rom_address_from_bank.return_2+3
    // rom_flash::@21
    // [1413] rom_flash::rom_address_sector#0 = rom_address_from_bank::return#4
    // unsigned long rom_boundary = rom_address_sector + file_size
    // [1414] rom_flash::rom_boundary#0 = rom_flash::rom_address_sector#0 + rom_flash::file_size#0 -- vdum1=vdum2_plus_vdum3 
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
    // display_info_rom(rom_chip, STATUS_FLASHING, "Flashing ...")
    // [1415] display_info_rom::rom_chip#3 = rom_flash::rom_chip#0 -- vbum1=vbum2 
    lda rom_chip
    sta display_info_rom.rom_chip
    // [1416] call display_info_rom
    // [1176] phi from rom_flash::@21 to display_info_rom [phi:rom_flash::@21->display_info_rom]
    // [1176] phi display_info_rom::info_text#16 = rom_flash::info_text1 [phi:rom_flash::@21->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_info_rom.info_text
    lda #>info_text1
    sta.z display_info_rom.info_text+1
    // [1176] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#3 [phi:rom_flash::@21->display_info_rom#1] -- register_copy 
    // [1176] phi display_info_rom::info_status#16 = STATUS_FLASHING [phi:rom_flash::@21->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHING
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // [1417] phi from rom_flash::@21 to rom_flash::@1 [phi:rom_flash::@21->rom_flash::@1]
    // [1417] phi rom_flash::flash_errors#12 = 0 [phi:rom_flash::@21->rom_flash::@1#0] -- vduz1=vduc1 
    lda #<0
    sta.z flash_errors
    sta.z flash_errors+1
    lda #<0>>$10
    sta.z flash_errors+2
    lda #>0>>$10
    sta.z flash_errors+3
    // [1417] phi rom_flash::y_sector#13 = PROGRESS_Y [phi:rom_flash::@21->rom_flash::@1#1] -- vbuz1=vbuc1 
    lda #PROGRESS_Y
    sta.z y_sector
    // [1417] phi rom_flash::x_sector#10 = PROGRESS_X [phi:rom_flash::@21->rom_flash::@1#2] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z x_sector
    // [1417] phi rom_flash::ram_address_sector#11 = (char *)$7800 [phi:rom_flash::@21->rom_flash::@1#3] -- pbuz1=pbuc1 
    lda #<$7800
    sta.z ram_address_sector
    lda #>$7800
    sta.z ram_address_sector+1
    // [1417] phi rom_flash::bram_bank_sector#14 = 0 [phi:rom_flash::@21->rom_flash::@1#4] -- vbuz1=vbuc1 
    lda #0
    sta.z bram_bank_sector
    // [1417] phi rom_flash::rom_address_sector#13 = rom_flash::rom_address_sector#0 [phi:rom_flash::@21->rom_flash::@1#5] -- register_copy 
    // rom_flash::@1
  __b1:
    // while (rom_address_sector < rom_boundary)
    // [1418] if(rom_flash::rom_address_sector#13<rom_flash::rom_boundary#0) goto rom_flash::@2 -- vdum1_lt_vdum2_then_la1 
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
    // [1419] display_action_text_flashed::bytes#1 = rom_flash::rom_address_sector#13 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z display_action_text_flashed.bytes
    lda rom_address_sector+1
    sta.z display_action_text_flashed.bytes+1
    lda rom_address_sector+2
    sta.z display_action_text_flashed.bytes+2
    lda rom_address_sector+3
    sta.z display_action_text_flashed.bytes+3
    // [1420] call display_action_text_flashed
    // [2424] phi from rom_flash::@3 to display_action_text_flashed [phi:rom_flash::@3->display_action_text_flashed]
    // [2424] phi display_action_text_flashed::chip#2 = chip [phi:rom_flash::@3->display_action_text_flashed#0] -- pbuz1=pbuc1 
    lda #<chip
    sta.z display_action_text_flashed.chip
    lda #>chip
    sta.z display_action_text_flashed.chip+1
    // [2424] phi display_action_text_flashed::bytes#2 = display_action_text_flashed::bytes#1 [phi:rom_flash::@3->display_action_text_flashed#1] -- register_copy 
    jsr display_action_text_flashed
    // [1421] phi from rom_flash::@3 to rom_flash::@23 [phi:rom_flash::@3->rom_flash::@23]
    // rom_flash::@23
    // wait_moment(32)
    // [1422] call wait_moment
    // [1063] phi from rom_flash::@23 to wait_moment [phi:rom_flash::@23->wait_moment]
    // [1063] phi wait_moment::w#7 = $20 [phi:rom_flash::@23->wait_moment#0] -- vbum1=vbuc1 
    lda #$20
    sta wait_moment.w
    jsr wait_moment
    // rom_flash::@return
    // }
    // [1423] return 
    rts
    // rom_flash::@2
  __b2:
    // unsigned int equal_bytes = rom_compare(bram_bank_sector, (bram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR)
    // [1424] rom_compare::bank_ram#1 = rom_flash::bram_bank_sector#14
    // [1425] rom_compare::ptr_ram#2 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z rom_compare.ptr_ram
    lda.z ram_address_sector+1
    sta.z rom_compare.ptr_ram+1
    // [1426] rom_compare::rom_compare_address#1 = rom_flash::rom_address_sector#13 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_compare.rom_compare_address
    lda rom_address_sector+1
    sta.z rom_compare.rom_compare_address+1
    lda rom_address_sector+2
    sta.z rom_compare.rom_compare_address+2
    lda rom_address_sector+3
    sta.z rom_compare.rom_compare_address+3
    // [1427] call rom_compare
  // {asm{.byte $db}}
    // [2368] phi from rom_flash::@2 to rom_compare [phi:rom_flash::@2->rom_compare]
    // [2368] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#2 [phi:rom_flash::@2->rom_compare#0] -- register_copy 
    // [2368] phi rom_compare::rom_compare_size#11 = $1000 [phi:rom_flash::@2->rom_compare#1] -- vwuz1=vwuc1 
    lda #<$1000
    sta.z rom_compare.rom_compare_size
    lda #>$1000
    sta.z rom_compare.rom_compare_size+1
    // [2368] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#1 [phi:rom_flash::@2->rom_compare#2] -- register_copy 
    // [2368] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#1 [phi:rom_flash::@2->rom_compare#3] -- vbum1=vbuz2 
    lda.z rom_compare.bank_ram_1
    sta rom_compare.bank_set_bram1_bank
    jsr rom_compare
    // unsigned int equal_bytes = rom_compare(bram_bank_sector, (bram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR)
    // [1428] rom_compare::return#3 = rom_compare::equal_bytes#2
    // rom_flash::@22
    // [1429] rom_flash::equal_bytes#0 = rom_compare::return#3
    // if (equal_bytes != ROM_SECTOR)
    // [1430] if(rom_flash::equal_bytes#0!=$1000) goto rom_flash::@5 -- vwuz1_neq_vwuc1_then_la1 
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
    // [1431] cputsxy::x#3 = rom_flash::x_sector#10 -- vbum1=vbuz2 
    lda.z x_sector
    sta cputsxy.x
    // [1432] cputsxy::y#3 = rom_flash::y_sector#13 -- vbum1=vbuz2 
    lda.z y_sector
    sta cputsxy.y
    // [1433] call cputsxy
    // [1966] phi from rom_flash::@16 to cputsxy [phi:rom_flash::@16->cputsxy]
    // [1966] phi cputsxy::s#4 = rom_flash::s [phi:rom_flash::@16->cputsxy#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z cputsxy.s
    lda #>s
    sta.z cputsxy.s+1
    // [1966] phi cputsxy::y#4 = cputsxy::y#3 [phi:rom_flash::@16->cputsxy#1] -- register_copy 
    // [1966] phi cputsxy::x#4 = cputsxy::x#3 [phi:rom_flash::@16->cputsxy#2] -- register_copy 
    jsr cputsxy
    // [1434] phi from rom_flash::@12 rom_flash::@16 to rom_flash::@4 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4]
    // [1434] phi rom_flash::flash_errors#10 = rom_flash::flash_errors#1 [phi:rom_flash::@12/rom_flash::@16->rom_flash::@4#0] -- register_copy 
    // rom_flash::@4
  __b4:
    // ram_address_sector += ROM_SECTOR
    // [1435] rom_flash::ram_address_sector#1 = rom_flash::ram_address_sector#11 + $1000 -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address_sector
    clc
    adc #<$1000
    sta.z ram_address_sector
    lda.z ram_address_sector+1
    adc #>$1000
    sta.z ram_address_sector+1
    // rom_address_sector += ROM_SECTOR
    // [1436] rom_flash::rom_address_sector#1 = rom_flash::rom_address_sector#13 + $1000 -- vdum1=vdum1_plus_vwuc1 
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
    // [1437] if(rom_flash::ram_address_sector#1!=$c000) goto rom_flash::@13 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address_sector+1
    cmp #>$c000
    bne __b13
    lda.z ram_address_sector
    cmp #<$c000
    bne __b13
    // rom_flash::@17
    // bram_bank_sector++;
    // [1438] rom_flash::bram_bank_sector#1 = ++ rom_flash::bram_bank_sector#14 -- vbuz1=_inc_vbuz1 
    inc.z bram_bank_sector
    // [1439] phi from rom_flash::@17 to rom_flash::@13 [phi:rom_flash::@17->rom_flash::@13]
    // [1439] phi rom_flash::bram_bank_sector#40 = rom_flash::bram_bank_sector#1 [phi:rom_flash::@17->rom_flash::@13#0] -- register_copy 
    // [1439] phi rom_flash::ram_address_sector#8 = (char *)$a000 [phi:rom_flash::@17->rom_flash::@13#1] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address_sector
    lda #>$a000
    sta.z ram_address_sector+1
    // [1439] phi from rom_flash::@4 to rom_flash::@13 [phi:rom_flash::@4->rom_flash::@13]
    // [1439] phi rom_flash::bram_bank_sector#40 = rom_flash::bram_bank_sector#14 [phi:rom_flash::@4->rom_flash::@13#0] -- register_copy 
    // [1439] phi rom_flash::ram_address_sector#8 = rom_flash::ram_address_sector#1 [phi:rom_flash::@4->rom_flash::@13#1] -- register_copy 
    // rom_flash::@13
  __b13:
    // if (ram_address_sector == RAM_HIGH)
    // [1440] if(rom_flash::ram_address_sector#8!=$9800) goto rom_flash::@36 -- pbuz1_neq_vwuc1_then_la1 
    lda.z ram_address_sector+1
    cmp #>$9800
    bne __b14
    lda.z ram_address_sector
    cmp #<$9800
    bne __b14
    // [1442] phi from rom_flash::@13 to rom_flash::@14 [phi:rom_flash::@13->rom_flash::@14]
    // [1442] phi rom_flash::ram_address_sector#15 = (char *)$a000 [phi:rom_flash::@13->rom_flash::@14#0] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z ram_address_sector
    lda #>$a000
    sta.z ram_address_sector+1
    // [1442] phi rom_flash::bram_bank_sector#12 = 1 [phi:rom_flash::@13->rom_flash::@14#1] -- vbuz1=vbuc1 
    lda #1
    sta.z bram_bank_sector
    // [1441] phi from rom_flash::@13 to rom_flash::@36 [phi:rom_flash::@13->rom_flash::@36]
    // rom_flash::@36
    // [1442] phi from rom_flash::@36 to rom_flash::@14 [phi:rom_flash::@36->rom_flash::@14]
    // [1442] phi rom_flash::ram_address_sector#15 = rom_flash::ram_address_sector#8 [phi:rom_flash::@36->rom_flash::@14#0] -- register_copy 
    // [1442] phi rom_flash::bram_bank_sector#12 = rom_flash::bram_bank_sector#40 [phi:rom_flash::@36->rom_flash::@14#1] -- register_copy 
    // rom_flash::@14
  __b14:
    // x_sector += 8
    // [1443] rom_flash::x_sector#1 = rom_flash::x_sector#10 + 8 -- vbuz1=vbuz1_plus_vbuc1 
    lda #8
    clc
    adc.z x_sector
    sta.z x_sector
    // rom_address_sector % ROM_PROGRESS_ROW
    // [1444] rom_flash::$29 = rom_flash::rom_address_sector#1 & ROM_PROGRESS_ROW-1 -- vduz1=vdum2_band_vduc1 
    lda rom_address_sector
    and #<ROM_PROGRESS_ROW-1
    sta.z rom_flash__29
    lda rom_address_sector+1
    and #>ROM_PROGRESS_ROW-1
    sta.z rom_flash__29+1
    lda rom_address_sector+2
    and #<ROM_PROGRESS_ROW-1>>$10
    sta.z rom_flash__29+2
    lda rom_address_sector+3
    and #>ROM_PROGRESS_ROW-1>>$10
    sta.z rom_flash__29+3
    // if (!(rom_address_sector % ROM_PROGRESS_ROW))
    // [1445] if(0!=rom_flash::$29) goto rom_flash::@15 -- 0_neq_vduz1_then_la1 
    lda.z rom_flash__29
    ora.z rom_flash__29+1
    ora.z rom_flash__29+2
    ora.z rom_flash__29+3
    bne __b15
    // rom_flash::@18
    // y_sector++;
    // [1446] rom_flash::y_sector#1 = ++ rom_flash::y_sector#13 -- vbuz1=_inc_vbuz1 
    inc.z y_sector
    // [1447] phi from rom_flash::@18 to rom_flash::@15 [phi:rom_flash::@18->rom_flash::@15]
    // [1447] phi rom_flash::y_sector#18 = rom_flash::y_sector#1 [phi:rom_flash::@18->rom_flash::@15#0] -- register_copy 
    // [1447] phi rom_flash::x_sector#20 = PROGRESS_X [phi:rom_flash::@18->rom_flash::@15#1] -- vbuz1=vbuc1 
    lda #PROGRESS_X
    sta.z x_sector
    // [1447] phi from rom_flash::@14 to rom_flash::@15 [phi:rom_flash::@14->rom_flash::@15]
    // [1447] phi rom_flash::y_sector#18 = rom_flash::y_sector#13 [phi:rom_flash::@14->rom_flash::@15#0] -- register_copy 
    // [1447] phi rom_flash::x_sector#20 = rom_flash::x_sector#1 [phi:rom_flash::@14->rom_flash::@15#1] -- register_copy 
    // rom_flash::@15
  __b15:
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1448] call snprintf_init
    // [1113] phi from rom_flash::@15 to snprintf_init [phi:rom_flash::@15->snprintf_init]
    // [1113] phi snprintf_init::s#25 = info_text [phi:rom_flash::@15->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // rom_flash::@32
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1449] printf_ulong::uvalue#7 = rom_flash::flash_errors#10 -- vdum1=vduz2 
    lda.z flash_errors
    sta printf_ulong.uvalue
    lda.z flash_errors+1
    sta printf_ulong.uvalue+1
    lda.z flash_errors+2
    sta printf_ulong.uvalue+2
    lda.z flash_errors+3
    sta printf_ulong.uvalue+3
    // [1450] call printf_ulong
    // [1396] phi from rom_flash::@32 to printf_ulong [phi:rom_flash::@32->printf_ulong]
    // [1396] phi printf_ulong::format_zero_padding#10 = 0 [phi:rom_flash::@32->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1396] phi printf_ulong::format_min_length#10 = 0 [phi:rom_flash::@32->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1396] phi printf_ulong::format_radix#10 = DECIMAL [phi:rom_flash::@32->printf_ulong#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1396] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#7 [phi:rom_flash::@32->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [1451] phi from rom_flash::@32 to rom_flash::@33 [phi:rom_flash::@32->rom_flash::@33]
    // rom_flash::@33
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1452] call printf_str
    // [1054] phi from rom_flash::@33 to printf_str [phi:rom_flash::@33->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:rom_flash::@33->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = rom_flash::s2 [phi:rom_flash::@33->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@34
    // sprintf(info_text, "%u flash errors ...", flash_errors)
    // [1453] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1454] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_info_rom(rom_chip, STATUS_FLASHING, info_text)
    // [1456] display_info_rom::rom_chip#4 = rom_flash::rom_chip#0 -- vbum1=vbum2 
    lda rom_chip
    sta display_info_rom.rom_chip
    // [1457] call display_info_rom
    // [1176] phi from rom_flash::@34 to display_info_rom [phi:rom_flash::@34->display_info_rom]
    // [1176] phi display_info_rom::info_text#16 = info_text [phi:rom_flash::@34->display_info_rom#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_info_rom.info_text
    lda #>@info_text
    sta.z display_info_rom.info_text+1
    // [1176] phi display_info_rom::rom_chip#16 = display_info_rom::rom_chip#4 [phi:rom_flash::@34->display_info_rom#1] -- register_copy 
    // [1176] phi display_info_rom::info_status#16 = STATUS_FLASHING [phi:rom_flash::@34->display_info_rom#2] -- vbuz1=vbuc1 
    lda #STATUS_FLASHING
    sta.z display_info_rom.info_status
    jsr display_info_rom
    // [1417] phi from rom_flash::@34 to rom_flash::@1 [phi:rom_flash::@34->rom_flash::@1]
    // [1417] phi rom_flash::flash_errors#12 = rom_flash::flash_errors#10 [phi:rom_flash::@34->rom_flash::@1#0] -- register_copy 
    // [1417] phi rom_flash::y_sector#13 = rom_flash::y_sector#18 [phi:rom_flash::@34->rom_flash::@1#1] -- register_copy 
    // [1417] phi rom_flash::x_sector#10 = rom_flash::x_sector#20 [phi:rom_flash::@34->rom_flash::@1#2] -- register_copy 
    // [1417] phi rom_flash::ram_address_sector#11 = rom_flash::ram_address_sector#15 [phi:rom_flash::@34->rom_flash::@1#3] -- register_copy 
    // [1417] phi rom_flash::bram_bank_sector#14 = rom_flash::bram_bank_sector#12 [phi:rom_flash::@34->rom_flash::@1#4] -- register_copy 
    // [1417] phi rom_flash::rom_address_sector#13 = rom_flash::rom_address_sector#1 [phi:rom_flash::@34->rom_flash::@1#5] -- register_copy 
    jmp __b1
    // [1458] phi from rom_flash::@22 to rom_flash::@5 [phi:rom_flash::@22->rom_flash::@5]
  __b3:
    // [1458] phi rom_flash::flash_errors_sector#10 = 0 [phi:rom_flash::@22->rom_flash::@5#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z flash_errors_sector
    sta.z flash_errors_sector+1
    // [1458] phi rom_flash::retries#12 = 0 [phi:rom_flash::@22->rom_flash::@5#1] -- vbuz1=vbuc1 
    sta.z retries
    // [1458] phi from rom_flash::@35 to rom_flash::@5 [phi:rom_flash::@35->rom_flash::@5]
    // [1458] phi rom_flash::flash_errors_sector#10 = rom_flash::flash_errors_sector#11 [phi:rom_flash::@35->rom_flash::@5#0] -- register_copy 
    // [1458] phi rom_flash::retries#12 = rom_flash::retries#1 [phi:rom_flash::@35->rom_flash::@5#1] -- register_copy 
    // rom_flash::@5
  __b5:
    // rom_sector_erase(rom_address_sector)
    // [1459] rom_sector_erase::address#0 = rom_flash::rom_address_sector#13 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_sector_erase.address
    lda rom_address_sector+1
    sta.z rom_sector_erase.address+1
    lda rom_address_sector+2
    sta.z rom_sector_erase.address+2
    lda rom_address_sector+3
    sta.z rom_sector_erase.address+3
    // [1460] call rom_sector_erase
    // [2441] phi from rom_flash::@5 to rom_sector_erase [phi:rom_flash::@5->rom_sector_erase]
    jsr rom_sector_erase
    // rom_flash::@24
    // unsigned long rom_sector_boundary = rom_address_sector + ROM_SECTOR
    // [1461] rom_flash::rom_sector_boundary#0 = rom_flash::rom_address_sector#13 + $1000 -- vdum1=vdum2_plus_vwuc1 
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
    // [1462] gotoxy::x#31 = rom_flash::x_sector#10 -- vbum1=vbuz2 
    lda.z x_sector
    sta gotoxy.x
    // [1463] gotoxy::y#31 = rom_flash::y_sector#13 -- vbum1=vbuz2 
    lda.z y_sector
    sta gotoxy.y
    // [1464] call gotoxy
    // [778] phi from rom_flash::@24 to gotoxy [phi:rom_flash::@24->gotoxy]
    // [778] phi gotoxy::y#33 = gotoxy::y#31 [phi:rom_flash::@24->gotoxy#0] -- register_copy 
    // [778] phi gotoxy::x#33 = gotoxy::x#31 [phi:rom_flash::@24->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [1465] phi from rom_flash::@24 to rom_flash::@25 [phi:rom_flash::@24->rom_flash::@25]
    // rom_flash::@25
    // printf("........")
    // [1466] call printf_str
    // [1054] phi from rom_flash::@25 to printf_str [phi:rom_flash::@25->printf_str]
    // [1054] phi printf_str::putc#75 = &cputc [phi:rom_flash::@25->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = rom_flash::s1 [phi:rom_flash::@25->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // rom_flash::@26
    // [1467] rom_flash::rom_address#16 = rom_flash::rom_address_sector#13 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z rom_address
    lda rom_address_sector+1
    sta.z rom_address+1
    lda rom_address_sector+2
    sta.z rom_address+2
    lda rom_address_sector+3
    sta.z rom_address+3
    // [1468] rom_flash::ram_address#16 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z ram_address
    lda.z ram_address_sector+1
    sta.z ram_address+1
    // [1469] rom_flash::x#16 = rom_flash::x_sector#10 -- vbuz1=vbuz2 
    lda.z x_sector
    sta.z x
    // [1470] phi from rom_flash::@10 rom_flash::@26 to rom_flash::@6 [phi:rom_flash::@10/rom_flash::@26->rom_flash::@6]
    // [1470] phi rom_flash::x#10 = rom_flash::x#1 [phi:rom_flash::@10/rom_flash::@26->rom_flash::@6#0] -- register_copy 
    // [1470] phi rom_flash::ram_address#10 = rom_flash::ram_address#1 [phi:rom_flash::@10/rom_flash::@26->rom_flash::@6#1] -- register_copy 
    // [1470] phi rom_flash::flash_errors_sector#11 = rom_flash::flash_errors_sector#7 [phi:rom_flash::@10/rom_flash::@26->rom_flash::@6#2] -- register_copy 
    // [1470] phi rom_flash::rom_address#11 = rom_flash::rom_address#1 [phi:rom_flash::@10/rom_flash::@26->rom_flash::@6#3] -- register_copy 
    // rom_flash::@6
  __b6:
    // while (rom_address < rom_sector_boundary)
    // [1471] if(rom_flash::rom_address#11<rom_flash::rom_sector_boundary#0) goto rom_flash::@7 -- vduz1_lt_vdum2_then_la1 
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
    // [1472] rom_flash::retries#1 = ++ rom_flash::retries#12 -- vbuz1=_inc_vbuz1 
    inc.z retries
    // while (flash_errors_sector && retries <= 3)
    // [1473] if(0==rom_flash::flash_errors_sector#11) goto rom_flash::@12 -- 0_eq_vwuz1_then_la1 
    lda.z flash_errors_sector
    ora.z flash_errors_sector+1
    beq __b12
    // rom_flash::@35
    // [1474] if(rom_flash::retries#1<3+1) goto rom_flash::@5 -- vbuz1_lt_vbuc1_then_la1 
    lda.z retries
    cmp #3+1
    bcs !__b5+
    jmp __b5
  !__b5:
    // rom_flash::@12
  __b12:
    // flash_errors += flash_errors_sector
    // [1475] rom_flash::flash_errors#1 = rom_flash::flash_errors#12 + rom_flash::flash_errors_sector#11 -- vduz1=vduz1_plus_vwuz2 
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
    jmp __b4
    // rom_flash::@7
  __b7:
    // display_action_text_flashing( ROM_SECTOR, "ROM", bram_bank_sector, ram_address_sector, rom_address_sector)
    // [1476] display_action_text_flashing::bram_bank#1 = rom_flash::bram_bank_sector#14 -- vbuz1=vbuz2 
    lda.z bram_bank_sector
    sta.z display_action_text_flashing.bram_bank
    // [1477] display_action_text_flashing::bram_ptr#1 = rom_flash::ram_address_sector#11 -- pbuz1=pbuz2 
    lda.z ram_address_sector
    sta.z display_action_text_flashing.bram_ptr
    lda.z ram_address_sector+1
    sta.z display_action_text_flashing.bram_ptr+1
    // [1478] display_action_text_flashing::address#1 = rom_flash::rom_address_sector#13 -- vduz1=vdum2 
    lda rom_address_sector
    sta.z display_action_text_flashing.address
    lda rom_address_sector+1
    sta.z display_action_text_flashing.address+1
    lda rom_address_sector+2
    sta.z display_action_text_flashing.address+2
    lda rom_address_sector+3
    sta.z display_action_text_flashing.address+3
    // [1479] call display_action_text_flashing
    // [2453] phi from rom_flash::@7 to display_action_text_flashing [phi:rom_flash::@7->display_action_text_flashing]
    // [2453] phi display_action_text_flashing::address#10 = display_action_text_flashing::address#1 [phi:rom_flash::@7->display_action_text_flashing#0] -- register_copy 
    // [2453] phi display_action_text_flashing::chip#10 = chip [phi:rom_flash::@7->display_action_text_flashing#1] -- pbuz1=pbuc1 
    lda #<chip
    sta.z display_action_text_flashing.chip
    lda #>chip
    sta.z display_action_text_flashing.chip+1
    // [2453] phi display_action_text_flashing::bram_ptr#2 = display_action_text_flashing::bram_ptr#1 [phi:rom_flash::@7->display_action_text_flashing#2] -- register_copy 
    // [2453] phi display_action_text_flashing::bram_bank#2 = display_action_text_flashing::bram_bank#1 [phi:rom_flash::@7->display_action_text_flashing#3] -- register_copy 
    // [2453] phi display_action_text_flashing::bytes#2 = $1000 [phi:rom_flash::@7->display_action_text_flashing#4] -- vduz1=vduc1 
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
    // [1480] rom_write::flash_ram_bank#0 = rom_flash::bram_bank_sector#14 -- vbuz1=vbuz2 
    lda.z bram_bank_sector
    sta.z rom_write.flash_ram_bank
    // [1481] rom_write::flash_ram_address#1 = rom_flash::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_write.flash_ram_address
    lda.z ram_address+1
    sta.z rom_write.flash_ram_address+1
    // [1482] rom_write::flash_rom_address#1 = rom_flash::rom_address#11 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_write.flash_rom_address
    lda.z rom_address+1
    sta.z rom_write.flash_rom_address+1
    lda.z rom_address+2
    sta.z rom_write.flash_rom_address+2
    lda.z rom_address+3
    sta.z rom_write.flash_rom_address+3
    // [1483] call rom_write
    jsr rom_write
    // rom_flash::@28
    // rom_compare(bram_bank, (bram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1484] rom_compare::bank_ram#2 = rom_flash::bram_bank_sector#14
    // [1485] rom_compare::ptr_ram#3 = rom_flash::ram_address#10 -- pbuz1=pbuz2 
    lda.z ram_address
    sta.z rom_compare.ptr_ram
    lda.z ram_address+1
    sta.z rom_compare.ptr_ram+1
    // [1486] rom_compare::rom_compare_address#2 = rom_flash::rom_address#11 -- vduz1=vduz2 
    lda.z rom_address
    sta.z rom_compare.rom_compare_address
    lda.z rom_address+1
    sta.z rom_compare.rom_compare_address+1
    lda.z rom_address+2
    sta.z rom_compare.rom_compare_address+2
    lda.z rom_address+3
    sta.z rom_compare.rom_compare_address+3
    // [1487] call rom_compare
    // [2368] phi from rom_flash::@28 to rom_compare [phi:rom_flash::@28->rom_compare]
    // [2368] phi rom_compare::ptr_ram#10 = rom_compare::ptr_ram#3 [phi:rom_flash::@28->rom_compare#0] -- register_copy 
    // [2368] phi rom_compare::rom_compare_size#11 = ROM_PROGRESS_CELL [phi:rom_flash::@28->rom_compare#1] -- vwuz1=vwuc1 
    lda #<ROM_PROGRESS_CELL
    sta.z rom_compare.rom_compare_size
    lda #>ROM_PROGRESS_CELL
    sta.z rom_compare.rom_compare_size+1
    // [2368] phi rom_compare::rom_compare_address#3 = rom_compare::rom_compare_address#2 [phi:rom_flash::@28->rom_compare#2] -- register_copy 
    // [2368] phi rom_compare::bank_set_bram1_bank#0 = rom_compare::bank_ram#2 [phi:rom_flash::@28->rom_compare#3] -- vbum1=vbuz2 
    lda.z rom_compare.bank_ram_1
    sta rom_compare.bank_set_bram1_bank
    jsr rom_compare
    // rom_compare(bram_bank, (bram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1488] rom_compare::return#4 = rom_compare::equal_bytes#2
    // rom_flash::@29
    // equal_bytes = rom_compare(bram_bank, (bram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL)
    // [1489] rom_flash::equal_bytes#1 = rom_compare::return#4 -- vwuz1=vwuz2 
    lda.z rom_compare.return
    sta.z equal_bytes_1
    lda.z rom_compare.return+1
    sta.z equal_bytes_1+1
    // gotoxy(x, y)
    // [1490] gotoxy::x#32 = rom_flash::x#10 -- vbum1=vbuz2 
    lda.z x
    sta gotoxy.x
    // [1491] gotoxy::y#32 = rom_flash::y_sector#13 -- vbum1=vbuz2 
    lda.z y_sector
    sta gotoxy.y
    // [1492] call gotoxy
    // [778] phi from rom_flash::@29 to gotoxy [phi:rom_flash::@29->gotoxy]
    // [778] phi gotoxy::y#33 = gotoxy::y#32 [phi:rom_flash::@29->gotoxy#0] -- register_copy 
    // [778] phi gotoxy::x#33 = gotoxy::x#32 [phi:rom_flash::@29->gotoxy#1] -- register_copy 
    jsr gotoxy
    // rom_flash::@30
    // if (equal_bytes != ROM_PROGRESS_CELL)
    // [1493] if(rom_flash::equal_bytes#1!=ROM_PROGRESS_CELL) goto rom_flash::@9 -- vwuz1_neq_vwuc1_then_la1 
    lda.z equal_bytes_1+1
    cmp #>ROM_PROGRESS_CELL
    bne __b9
    lda.z equal_bytes_1
    cmp #<ROM_PROGRESS_CELL
    bne __b9
    // rom_flash::@11
    // cputcxy(x,y,'+')
    // [1494] cputcxy::x#14 = rom_flash::x#10 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [1495] cputcxy::y#14 = rom_flash::y_sector#13 -- vbum1=vbuz2 
    lda.z y_sector
    sta cputcxy.y
    // [1496] call cputcxy
    // [2147] phi from rom_flash::@11 to cputcxy [phi:rom_flash::@11->cputcxy]
    // [2147] phi cputcxy::c#15 = '+' [phi:rom_flash::@11->cputcxy#0] -- vbum1=vbuc1 
    lda #'+'
    sta cputcxy.c
    // [2147] phi cputcxy::y#15 = cputcxy::y#14 [phi:rom_flash::@11->cputcxy#1] -- register_copy 
    // [2147] phi cputcxy::x#15 = cputcxy::x#14 [phi:rom_flash::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [1497] phi from rom_flash::@11 rom_flash::@31 to rom_flash::@10 [phi:rom_flash::@11/rom_flash::@31->rom_flash::@10]
    // [1497] phi rom_flash::flash_errors_sector#7 = rom_flash::flash_errors_sector#11 [phi:rom_flash::@11/rom_flash::@31->rom_flash::@10#0] -- register_copy 
    // rom_flash::@10
  __b10:
    // ram_address += ROM_PROGRESS_CELL
    // [1498] rom_flash::ram_address#1 = rom_flash::ram_address#10 + ROM_PROGRESS_CELL -- pbuz1=pbuz1_plus_vwuc1 
    lda.z ram_address
    clc
    adc #<ROM_PROGRESS_CELL
    sta.z ram_address
    lda.z ram_address+1
    adc #>ROM_PROGRESS_CELL
    sta.z ram_address+1
    // rom_address += ROM_PROGRESS_CELL
    // [1499] rom_flash::rom_address#1 = rom_flash::rom_address#11 + ROM_PROGRESS_CELL -- vduz1=vduz1_plus_vwuc1 
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
    // x++;
    // [1500] rom_flash::x#1 = ++ rom_flash::x#10 -- vbuz1=_inc_vbuz1 
    inc.z x
    jmp __b6
    // rom_flash::@9
  __b9:
    // cputcxy(x,y,'!')
    // [1501] cputcxy::x#13 = rom_flash::x#10 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [1502] cputcxy::y#13 = rom_flash::y_sector#13 -- vbum1=vbuz2 
    lda.z y_sector
    sta cputcxy.y
    // [1503] call cputcxy
    // [2147] phi from rom_flash::@9 to cputcxy [phi:rom_flash::@9->cputcxy]
    // [2147] phi cputcxy::c#15 = '!' [phi:rom_flash::@9->cputcxy#0] -- vbum1=vbuc1 
    lda #'!'
    sta cputcxy.c
    // [2147] phi cputcxy::y#15 = cputcxy::y#13 [phi:rom_flash::@9->cputcxy#1] -- register_copy 
    // [2147] phi cputcxy::x#15 = cputcxy::x#13 [phi:rom_flash::@9->cputcxy#2] -- register_copy 
    jsr cputcxy
    // rom_flash::@31
    // flash_errors_sector++;
    // [1504] rom_flash::flash_errors_sector#1 = ++ rom_flash::flash_errors_sector#11 -- vwuz1=_inc_vwuz1 
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
    s: .text "--------"
    .byte 0
    s1: .text "........"
    .byte 0
    s2: .text " flash errors ..."
    .byte 0
    .label rom_address_sector = main.rom_file_modulo
    rom_boundary: .dword 0
    rom_sector_boundary: .dword 0
    .label rom_chip = util_wait_key.return_4
    .label rom_bank_start = main.check_status_smc7_main__0
    .label file_size = main.rom_flash_errors
}
.segment Code
  // smc_read
/**
 * @brief Read the SMC.BIN file into RAM_BASE.
 * The maximum size of SMC.BIN data that should be in the file is 0x1E00.
 * 
 * @return unsigned int The amount of bytes read from SMC.BIN to be flashed.
 */
// __zp($2d) unsigned int smc_read(__zp($29) char info_status)
smc_read: {
    .const smc_bram_bank = 1
    .label return = $2d
    .label smc_bram_ptr = $6b
    .label smc_file_size = $2d
    .label info_status = $29
    .label smc_action_text = $6d
    // if(info_status == STATUS_READING)
    // [1506] if(smc_read::info_status#10==STATUS_READING) goto smc_read::@1 -- vbuz1_eq_vbuc1_then_la1 
    lda #STATUS_READING
    cmp.z info_status
    beq __b1
    // [1508] phi from smc_read to smc_read::@2 [phi:smc_read->smc_read::@2]
    // [1508] phi smc_read::smc_action_text#12 = smc_action_text#2 [phi:smc_read->smc_read::@2#0] -- pbuz1=pbuc1 
    lda #<smc_action_text_1
    sta.z smc_action_text
    lda #>smc_action_text_1
    sta.z smc_action_text+1
    jmp __b2
    // [1507] phi from smc_read to smc_read::@1 [phi:smc_read->smc_read::@1]
    // smc_read::@1
  __b1:
    // [1508] phi from smc_read::@1 to smc_read::@2 [phi:smc_read::@1->smc_read::@2]
    // [1508] phi smc_read::smc_action_text#12 = smc_action_text#1 [phi:smc_read::@1->smc_read::@2#0] -- pbuz1=pbuc1 
    lda #<smc_action_text
    sta.z smc_action_text
    lda #>smc_action_text
    sta.z smc_action_text+1
    // smc_read::@2
  __b2:
    // smc_read::bank_set_bram1
    // BRAM = bank
    // [1509] BRAM = smc_read::smc_bram_bank -- vbuz1=vbuc1 
    lda #smc_bram_bank
    sta.z BRAM
    // [1510] phi from smc_read::bank_set_bram1 to smc_read::@16 [phi:smc_read::bank_set_bram1->smc_read::@16]
    // smc_read::@16
    // textcolor(WHITE)
    // [1511] call textcolor
    // [760] phi from smc_read::@16 to textcolor [phi:smc_read::@16->textcolor]
    // [760] phi textcolor::color#23 = WHITE [phi:smc_read::@16->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [1512] phi from smc_read::@16 to smc_read::@17 [phi:smc_read::@16->smc_read::@17]
    // smc_read::@17
    // gotoxy(x, y)
    // [1513] call gotoxy
    // [778] phi from smc_read::@17 to gotoxy [phi:smc_read::@17->gotoxy]
    // [778] phi gotoxy::y#33 = PROGRESS_Y [phi:smc_read::@17->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [778] phi gotoxy::x#33 = PROGRESS_X [phi:smc_read::@17->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1514] phi from smc_read::@17 to smc_read::@18 [phi:smc_read::@17->smc_read::@18]
    // smc_read::@18
    // FILE *fp = fopen("SMC.BIN", "r")
    // [1515] call fopen
    // [2173] phi from smc_read::@18 to fopen [phi:smc_read::@18->fopen]
    // [2173] phi __errno#322 = __errno#109 [phi:smc_read::@18->fopen#0] -- register_copy 
    // [2173] phi fopen::pathtoken#0 = smc_read::path [phi:smc_read::@18->fopen#1] -- pbuz1=pbuc1 
    lda #<path
    sta.z fopen.pathtoken
    lda #>path
    sta.z fopen.pathtoken+1
    // [2173] phi __stdio_filecount#18 = __stdio_filecount#104 [phi:smc_read::@18->fopen#2] -- register_copy 
    jsr fopen
    // FILE *fp = fopen("SMC.BIN", "r")
    // [1516] fopen::return#3 = fopen::return#2
    // smc_read::@19
    // [1517] smc_read::fp#0 = fopen::return#3 -- pssm1=pssz2 
    lda.z fopen.return
    sta fp
    lda.z fopen.return+1
    sta fp+1
    // if (fp)
    // [1518] if((struct $2 *)0==smc_read::fp#0) goto smc_read::@3 -- pssc1_eq_pssm1_then_la1 
    lda fp
    cmp #<0
    bne !+
    lda fp+1
    cmp #>0
    bne !__b5+
    jmp __b5
  !__b5:
  !:
    // smc_read::@4
    // fgets(smc_file_header, 32, fp)
    // [1519] fgets::stream#0 = smc_read::fp#0 -- pssz1=pssm2 
    lda fp
    sta.z fgets.stream
    lda fp+1
    sta.z fgets.stream+1
    // [1520] call fgets
    // [2314] phi from smc_read::@4 to fgets [phi:smc_read::@4->fgets]
    // [2314] phi fgets::ptr#13 = smc_file_header [phi:smc_read::@4->fgets#0] -- pbuz1=pbuc1 
    lda #<smc_file_header
    sta.z fgets.ptr
    lda #>smc_file_header
    sta.z fgets.ptr+1
    // [2314] phi fgets::size#11 = $20 [phi:smc_read::@4->fgets#1] -- vwum1=vbuc1 
    lda #<$20
    sta fgets.size
    lda #>$20
    sta fgets.size+1
    // [2314] phi fgets::stream#3 = fgets::stream#0 [phi:smc_read::@4->fgets#2] -- register_copy 
    jsr fgets
    // fgets(smc_file_header, 32, fp)
    // [1521] fgets::return#5 = fgets::return#1
    // smc_read::@20
    // smc_file_read = fgets(smc_file_header, 32, fp)
    // [1522] smc_read::smc_file_read#1 = fgets::return#5 -- vwum1=vwum2 
    lda fgets.return
    sta smc_file_read
    lda fgets.return+1
    sta smc_file_read+1
    // if(smc_file_read)
    // [1523] if(0==smc_read::smc_file_read#1) goto smc_read::@3 -- 0_eq_vwum1_then_la1 
    lda smc_file_read
    ora smc_file_read+1
    beq __b5
    // smc_read::@5
    // if(info_status == STATUS_CHECKING)
    // [1524] if(smc_read::info_status#10!=STATUS_CHECKING) goto smc_read::@7 -- vbuz1_neq_vbuc1_then_la1 
    lda #STATUS_CHECKING
    cmp.z info_status
    bne __b4
    // [1525] phi from smc_read::@5 to smc_read::@6 [phi:smc_read::@5->smc_read::@6]
    // smc_read::@6
    // [1526] phi from smc_read::@6 to smc_read::@7 [phi:smc_read::@6->smc_read::@7]
    // [1526] phi smc_read::y#12 = PROGRESS_Y [phi:smc_read::@6->smc_read::@7#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1526] phi smc_read::progress_row_bytes#10 = 0 [phi:smc_read::@6->smc_read::@7#1] -- vwum1=vwuc1 
    lda #<0
    sta progress_row_bytes
    sta progress_row_bytes+1
    // [1526] phi smc_read::smc_file_size#10 = 0 [phi:smc_read::@6->smc_read::@7#2] -- vwuz1=vwuc1 
    sta.z smc_file_size
    sta.z smc_file_size+1
    // [1526] phi smc_read::smc_bram_ptr#10 = (char *) 1024 [phi:smc_read::@6->smc_read::@7#3] -- pbuz1=pbuc1 
    lda #<$400
    sta.z smc_bram_ptr
    lda #>$400
    sta.z smc_bram_ptr+1
    jmp __b7
  // We read block_size bytes at a time, and each block_size bytes we plot a dot.
  // Every r bytes we move to the next line.
    // [1526] phi from smc_read::@5 to smc_read::@7 [phi:smc_read::@5->smc_read::@7]
  __b4:
    // [1526] phi smc_read::y#12 = PROGRESS_Y [phi:smc_read::@5->smc_read::@7#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1526] phi smc_read::progress_row_bytes#10 = 0 [phi:smc_read::@5->smc_read::@7#1] -- vwum1=vwuc1 
    lda #<0
    sta progress_row_bytes
    sta progress_row_bytes+1
    // [1526] phi smc_read::smc_file_size#10 = 0 [phi:smc_read::@5->smc_read::@7#2] -- vwuz1=vwuc1 
    sta.z smc_file_size
    sta.z smc_file_size+1
    // [1526] phi smc_read::smc_bram_ptr#10 = (char *)$a000 [phi:smc_read::@5->smc_read::@7#3] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z smc_bram_ptr
    lda #>$a000
    sta.z smc_bram_ptr+1
    // smc_read::@7
  __b7:
    // fgets(smc_bram_ptr, SMC_PROGRESS_CELL, fp)
    // [1527] fgets::ptr#3 = smc_read::smc_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z smc_bram_ptr
    sta.z fgets.ptr
    lda.z smc_bram_ptr+1
    sta.z fgets.ptr+1
    // [1528] fgets::stream#1 = smc_read::fp#0 -- pssz1=pssm2 
    lda fp
    sta.z fgets.stream
    lda fp+1
    sta.z fgets.stream+1
    // [1529] call fgets
    // [2314] phi from smc_read::@7 to fgets [phi:smc_read::@7->fgets]
    // [2314] phi fgets::ptr#13 = fgets::ptr#3 [phi:smc_read::@7->fgets#0] -- register_copy 
    // [2314] phi fgets::size#11 = SMC_PROGRESS_CELL [phi:smc_read::@7->fgets#1] -- vwum1=vbuc1 
    lda #<SMC_PROGRESS_CELL
    sta fgets.size
    lda #>SMC_PROGRESS_CELL
    sta fgets.size+1
    // [2314] phi fgets::stream#3 = fgets::stream#1 [phi:smc_read::@7->fgets#2] -- register_copy 
    jsr fgets
    // fgets(smc_bram_ptr, SMC_PROGRESS_CELL, fp)
    // [1530] fgets::return#10 = fgets::return#1
    // smc_read::@21
    // smc_file_read = fgets(smc_bram_ptr, SMC_PROGRESS_CELL, fp)
    // [1531] smc_read::smc_file_read#10 = fgets::return#10 -- vwum1=vwum2 
    lda fgets.return
    sta smc_file_read_1
    lda fgets.return+1
    sta smc_file_read_1+1
    // while (smc_file_read = fgets(smc_bram_ptr, SMC_PROGRESS_CELL, fp))
    // [1532] if(0!=smc_read::smc_file_read#10) goto smc_read::@8 -- 0_neq_vwum1_then_la1 
    lda smc_file_read_1
    ora smc_file_read_1+1
    bne __b8
    // smc_read::@9
    // fclose(fp)
    // [1533] fclose::stream#0 = smc_read::fp#0 -- pssm1=pssm2 
    lda fp
    sta fclose.stream
    lda fp+1
    sta fclose.stream+1
    // [1534] call fclose
    // [2254] phi from smc_read::@9 to fclose [phi:smc_read::@9->fclose]
    // [2254] phi fclose::stream#2 = fclose::stream#0 [phi:smc_read::@9->fclose#0] -- register_copy 
    jsr fclose
    // [1535] phi from smc_read::@9 to smc_read::@3 [phi:smc_read::@9->smc_read::@3]
    // [1535] phi __stdio_filecount#27 = __stdio_filecount#2 [phi:smc_read::@9->smc_read::@3#0] -- register_copy 
    // [1535] phi smc_read::return#0 = smc_read::smc_file_size#10 [phi:smc_read::@9->smc_read::@3#1] -- register_copy 
    rts
    // [1535] phi from smc_read::@19 smc_read::@20 to smc_read::@3 [phi:smc_read::@19/smc_read::@20->smc_read::@3]
  __b5:
    // [1535] phi __stdio_filecount#27 = __stdio_filecount#1 [phi:smc_read::@19/smc_read::@20->smc_read::@3#0] -- register_copy 
    // [1535] phi smc_read::return#0 = 0 [phi:smc_read::@19/smc_read::@20->smc_read::@3#1] -- vwuz1=vwuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // smc_read::@3
    // smc_read::@return
    // }
    // [1536] return 
    rts
    // smc_read::@8
  __b8:
    // display_action_text_reading(smc_action_text, "SMC.BIN", smc_file_size, SMC_CHIP_SIZE, smc_bram_bank, smc_bram_ptr)
    // [1537] display_action_text_reading::action#0 = smc_read::smc_action_text#12 -- pbuz1=pbuz2 
    lda.z smc_action_text
    sta.z display_action_text_reading.action
    lda.z smc_action_text+1
    sta.z display_action_text_reading.action+1
    // [1538] display_action_text_reading::bytes#0 = smc_read::smc_file_size#10 -- vduz1=vwuz2 
    lda.z smc_file_size
    sta.z display_action_text_reading.bytes
    lda.z smc_file_size+1
    sta.z display_action_text_reading.bytes+1
    lda #0
    sta.z display_action_text_reading.bytes+2
    sta.z display_action_text_reading.bytes+3
    // [1539] display_action_text_reading::bram_ptr#0 = smc_read::smc_bram_ptr#10 -- pbuz1=pbuz2 
    lda.z smc_bram_ptr
    sta.z display_action_text_reading.bram_ptr
    lda.z smc_bram_ptr+1
    sta.z display_action_text_reading.bram_ptr+1
    // [1540] call display_action_text_reading
    // [2283] phi from smc_read::@8 to display_action_text_reading [phi:smc_read::@8->display_action_text_reading]
    // [2283] phi display_action_text_reading::bram_ptr#10 = display_action_text_reading::bram_ptr#0 [phi:smc_read::@8->display_action_text_reading#0] -- register_copy 
    // [2283] phi display_action_text_reading::bram_bank#10 = smc_read::smc_bram_bank [phi:smc_read::@8->display_action_text_reading#1] -- vbuz1=vbuc1 
    lda #smc_bram_bank
    sta.z display_action_text_reading.bram_bank
    // [2283] phi display_action_text_reading::size#2 = SMC_CHIP_SIZE [phi:smc_read::@8->display_action_text_reading#2] -- vduz1=vduc1 
    lda #<SMC_CHIP_SIZE
    sta.z display_action_text_reading.size
    lda #>SMC_CHIP_SIZE
    sta.z display_action_text_reading.size+1
    lda #<SMC_CHIP_SIZE>>$10
    sta.z display_action_text_reading.size+2
    lda #>SMC_CHIP_SIZE>>$10
    sta.z display_action_text_reading.size+3
    // [2283] phi display_action_text_reading::bytes#2 = display_action_text_reading::bytes#0 [phi:smc_read::@8->display_action_text_reading#3] -- register_copy 
    // [2283] phi display_action_text_reading::file#2 = smc_read::path [phi:smc_read::@8->display_action_text_reading#4] -- pbuz1=pbuc1 
    lda #<path
    sta.z display_action_text_reading.file
    lda #>path
    sta.z display_action_text_reading.file+1
    // [2283] phi display_action_text_reading::action#2 = display_action_text_reading::action#0 [phi:smc_read::@8->display_action_text_reading#5] -- register_copy 
    jsr display_action_text_reading
    // smc_read::@22
    // if (progress_row_bytes == SMC_PROGRESS_ROW)
    // [1541] if(smc_read::progress_row_bytes#10!=SMC_PROGRESS_ROW) goto smc_read::@10 -- vwum1_neq_vwuc1_then_la1 
    lda progress_row_bytes+1
    cmp #>SMC_PROGRESS_ROW
    bne __b10
    lda progress_row_bytes
    cmp #<SMC_PROGRESS_ROW
    bne __b10
    // smc_read::@13
    // gotoxy(x, ++y);
    // [1542] smc_read::y#1 = ++ smc_read::y#12 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1543] gotoxy::y#23 = smc_read::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1544] call gotoxy
    // [778] phi from smc_read::@13 to gotoxy [phi:smc_read::@13->gotoxy]
    // [778] phi gotoxy::y#33 = gotoxy::y#23 [phi:smc_read::@13->gotoxy#0] -- register_copy 
    // [778] phi gotoxy::x#33 = PROGRESS_X [phi:smc_read::@13->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1545] phi from smc_read::@13 to smc_read::@10 [phi:smc_read::@13->smc_read::@10]
    // [1545] phi smc_read::y#13 = smc_read::y#1 [phi:smc_read::@13->smc_read::@10#0] -- register_copy 
    // [1545] phi smc_read::progress_row_bytes#11 = 0 [phi:smc_read::@13->smc_read::@10#1] -- vwum1=vbuc1 
    lda #<0
    sta progress_row_bytes
    sta progress_row_bytes+1
    // [1545] phi from smc_read::@22 to smc_read::@10 [phi:smc_read::@22->smc_read::@10]
    // [1545] phi smc_read::y#13 = smc_read::y#12 [phi:smc_read::@22->smc_read::@10#0] -- register_copy 
    // [1545] phi smc_read::progress_row_bytes#11 = smc_read::progress_row_bytes#10 [phi:smc_read::@22->smc_read::@10#1] -- register_copy 
    // smc_read::@10
  __b10:
    // if(info_status == STATUS_READING)
    // [1546] if(smc_read::info_status#10!=STATUS_READING) goto smc_read::@11 -- vbuz1_neq_vbuc1_then_la1 
    lda #STATUS_READING
    cmp.z info_status
    bne __b11
    // smc_read::@14
    // cputc('.')
    // [1547] stackpush(char) = '.' -- _stackpushbyte_=vbuc1 
    lda #'.'
    pha
    // [1548] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_read::@11
  __b11:
    // if(info_status == STATUS_CHECKING)
    // [1550] if(smc_read::info_status#10==STATUS_CHECKING) goto smc_read::@12 -- vbuz1_eq_vbuc1_then_la1 
    lda #STATUS_CHECKING
    cmp.z info_status
    beq __b6
    // smc_read::@15
    // smc_bram_ptr += smc_file_read
    // [1551] smc_read::smc_bram_ptr#3 = smc_read::smc_bram_ptr#10 + smc_read::smc_file_read#10 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z smc_bram_ptr
    adc smc_file_read_1
    sta.z smc_bram_ptr
    lda.z smc_bram_ptr+1
    adc smc_file_read_1+1
    sta.z smc_bram_ptr+1
    // [1552] phi from smc_read::@15 to smc_read::@12 [phi:smc_read::@15->smc_read::@12]
    // [1552] phi smc_read::smc_bram_ptr#7 = smc_read::smc_bram_ptr#3 [phi:smc_read::@15->smc_read::@12#0] -- register_copy 
    jmp __b12
    // [1552] phi from smc_read::@11 to smc_read::@12 [phi:smc_read::@11->smc_read::@12]
  __b6:
    // [1552] phi smc_read::smc_bram_ptr#7 = (char *) 1024 [phi:smc_read::@11->smc_read::@12#0] -- pbuz1=pbuc1 
    lda #<$400
    sta.z smc_bram_ptr
    lda #>$400
    sta.z smc_bram_ptr+1
    // smc_read::@12
  __b12:
    // smc_file_size += smc_file_read
    // [1553] smc_read::smc_file_size#1 = smc_read::smc_file_size#10 + smc_read::smc_file_read#10 -- vwuz1=vwuz1_plus_vwum2 
    clc
    lda.z smc_file_size
    adc smc_file_read_1
    sta.z smc_file_size
    lda.z smc_file_size+1
    adc smc_file_read_1+1
    sta.z smc_file_size+1
    // progress_row_bytes += smc_file_read
    // [1554] smc_read::progress_row_bytes#2 = smc_read::progress_row_bytes#11 + smc_read::smc_file_read#10 -- vwum1=vwum1_plus_vwum2 
    clc
    lda progress_row_bytes
    adc smc_file_read_1
    sta progress_row_bytes
    lda progress_row_bytes+1
    adc smc_file_read_1+1
    sta progress_row_bytes+1
    // [1526] phi from smc_read::@12 to smc_read::@7 [phi:smc_read::@12->smc_read::@7]
    // [1526] phi smc_read::y#12 = smc_read::y#13 [phi:smc_read::@12->smc_read::@7#0] -- register_copy 
    // [1526] phi smc_read::progress_row_bytes#10 = smc_read::progress_row_bytes#2 [phi:smc_read::@12->smc_read::@7#1] -- register_copy 
    // [1526] phi smc_read::smc_file_size#10 = smc_read::smc_file_size#1 [phi:smc_read::@12->smc_read::@7#2] -- register_copy 
    // [1526] phi smc_read::smc_bram_ptr#10 = smc_read::smc_bram_ptr#7 [phi:smc_read::@12->smc_read::@7#3] -- register_copy 
    jmp __b7
  .segment Data
    path: .text "SMC.BIN"
    .byte 0
    .label fp = rom_read_byte.rom_bank1_rom_read_byte__2
    smc_file_read: .word 0
    .label y = main.check_status_smc3_main__0
    /// Holds the amount of bytes actually read in the memory to be flashed.
    .label progress_row_bytes = main.main__43
    .label smc_file_read_1 = rom_read_byte.rom_ptr1_rom_read_byte__2
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
    .label smc_flash__29 = $d1
    .label smc_flash__30 = $d1
    .label smc_bootloader_start = $ed
    .label smc_bootloader_not_activated = $b4
    .label smc_byte_upload = $af
    .label smc_bram_ptr = $73
    .label smc_bytes_checksum = $d1
    .label smc_package_flashed = $b8
    // smc_flash::bank_set_bram1
    // BRAM = bank
    // [1556] BRAM = smc_flash::smc_bram_bank -- vbuz1=vbuc1 
    lda #smc_bram_bank
    sta.z BRAM
    // [1557] phi from smc_flash::bank_set_bram1 to smc_flash::@24 [phi:smc_flash::bank_set_bram1->smc_flash::@24]
    // smc_flash::@24
    // display_action_progress("To start the SMC update, do the following ...")
    // [1558] call display_action_progress
    // [1084] phi from smc_flash::@24 to display_action_progress [phi:smc_flash::@24->display_action_progress]
    // [1084] phi display_action_progress::info_text#20 = smc_flash::info_text [phi:smc_flash::@24->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_progress.info_text
    lda #>info_text
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // smc_flash::@28
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [1559] smc_flash::cx16_k_i2c_write_byte1_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte1_device
    // [1560] smc_flash::cx16_k_i2c_write_byte1_offset = $8f -- vbum1=vbuc1 
    lda #$8f
    sta cx16_k_i2c_write_byte1_offset
    // [1561] smc_flash::cx16_k_i2c_write_byte1_value = $31 -- vbum1=vbuc1 
    lda #$31
    sta cx16_k_i2c_write_byte1_value
    // smc_flash::cx16_k_i2c_write_byte1
    // unsigned char result
    // [1562] smc_flash::cx16_k_i2c_write_byte1_result = 0 -- vbum1=vbuc1 
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
    // [1564] smc_flash::cx16_k_i2c_write_byte1_return#0 = smc_flash::cx16_k_i2c_write_byte1_result -- vbum1=vbum2 
    lda cx16_k_i2c_write_byte1_result
    sta cx16_k_i2c_write_byte1_return
    // smc_flash::cx16_k_i2c_write_byte1_@return
    // }
    // [1565] smc_flash::cx16_k_i2c_write_byte1_return#1 = smc_flash::cx16_k_i2c_write_byte1_return#0
    // smc_flash::@25
    // unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31)
    // [1566] smc_flash::smc_bootloader_start#0 = smc_flash::cx16_k_i2c_write_byte1_return#1 -- vbuz1=vbum2 
    sta.z smc_bootloader_start
    // if(smc_bootloader_start)
    // [1567] if(0==smc_flash::smc_bootloader_start#0) goto smc_flash::@3 -- 0_eq_vbuz1_then_la1 
    beq __b6
    // [1568] phi from smc_flash::@25 to smc_flash::@2 [phi:smc_flash::@25->smc_flash::@2]
    // smc_flash::@2
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1569] call snprintf_init
    // [1113] phi from smc_flash::@2 to snprintf_init [phi:smc_flash::@2->snprintf_init]
    // [1113] phi snprintf_init::s#25 = info_text [phi:smc_flash::@2->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1570] phi from smc_flash::@2 to smc_flash::@29 [phi:smc_flash::@2->smc_flash::@29]
    // smc_flash::@29
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1571] call printf_str
    // [1054] phi from smc_flash::@29 to printf_str [phi:smc_flash::@29->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:smc_flash::@29->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = smc_flash::s [phi:smc_flash::@29->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@30
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1572] printf_uchar::uvalue#9 = smc_flash::smc_bootloader_start#0 -- vbum1=vbuz2 
    lda.z smc_bootloader_start
    sta printf_uchar.uvalue
    // [1573] call printf_uchar
    // [1118] phi from smc_flash::@30 to printf_uchar [phi:smc_flash::@30->printf_uchar]
    // [1118] phi printf_uchar::format_zero_padding#17 = 0 [phi:smc_flash::@30->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1118] phi printf_uchar::format_min_length#17 = 0 [phi:smc_flash::@30->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1118] phi printf_uchar::putc#17 = &snputc [phi:smc_flash::@30->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1118] phi printf_uchar::format_radix#17 = HEXADECIMAL [phi:smc_flash::@30->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1118] phi printf_uchar::uvalue#17 = printf_uchar::uvalue#9 [phi:smc_flash::@30->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // smc_flash::@31
    // sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start)
    // [1574] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1575] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1577] call display_action_text
    // [1129] phi from smc_flash::@31 to display_action_text [phi:smc_flash::@31->display_action_text]
    // [1129] phi display_action_text::info_text#17 = info_text [phi:smc_flash::@31->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_flash::@32
    // cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0)
    // [1578] smc_flash::cx16_k_i2c_write_byte2_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte2_device
    // [1579] smc_flash::cx16_k_i2c_write_byte2_offset = $82 -- vbum1=vbuc1 
    lda #$82
    sta cx16_k_i2c_write_byte2_offset
    // [1580] smc_flash::cx16_k_i2c_write_byte2_value = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_i2c_write_byte2_value
    // smc_flash::cx16_k_i2c_write_byte2
    // unsigned char result
    // [1581] smc_flash::cx16_k_i2c_write_byte2_result = 0 -- vbum1=vbuc1 
    sta cx16_k_i2c_write_byte2_result
    // asm
    // asm { ldxdevice ldyoffset ldavalue stzresult jsrCX16_I2C_WRITE_BYTE rolresult  }
    ldx cx16_k_i2c_write_byte2_device
    ldy cx16_k_i2c_write_byte2_offset
    lda cx16_k_i2c_write_byte2_value
    stz cx16_k_i2c_write_byte2_result
    jsr CX16_I2C_WRITE_BYTE
    rol cx16_k_i2c_write_byte2_result
    // [1583] phi from smc_flash::@50 smc_flash::cx16_k_i2c_write_byte2 to smc_flash::@return [phi:smc_flash::@50/smc_flash::cx16_k_i2c_write_byte2->smc_flash::@return]
  __b2:
    // [1583] phi smc_flash::return#1 = 0 [phi:smc_flash::@50/smc_flash::cx16_k_i2c_write_byte2->smc_flash::@return#0] -- vwum1=vbuc1 
    lda #<0
    sta return
    sta return+1
    // smc_flash::@return
    // }
    // [1584] return 
    rts
    // [1585] phi from smc_flash::@25 to smc_flash::@3 [phi:smc_flash::@25->smc_flash::@3]
  __b6:
    // [1585] phi smc_flash::smc_bootloader_activation_countdown#10 = $80 [phi:smc_flash::@25->smc_flash::@3#0] -- vbum1=vbuc1 
    lda #$80
    sta smc_bootloader_activation_countdown
    // smc_flash::@3
  __b3:
    // while(smc_bootloader_activation_countdown)
    // [1586] if(0!=smc_flash::smc_bootloader_activation_countdown#10) goto smc_flash::@4 -- 0_neq_vbum1_then_la1 
    lda smc_bootloader_activation_countdown
    beq !__b4+
    jmp __b4
  !__b4:
    // [1587] phi from smc_flash::@3 smc_flash::@33 to smc_flash::@7 [phi:smc_flash::@3/smc_flash::@33->smc_flash::@7]
  __b9:
    // [1587] phi smc_flash::smc_bootloader_activation_countdown#12 = $a [phi:smc_flash::@3/smc_flash::@33->smc_flash::@7#0] -- vbum1=vbuc1 
    lda #$a
    sta smc_bootloader_activation_countdown_1
    // smc_flash::@7
  __b7:
    // while(smc_bootloader_activation_countdown)
    // [1588] if(0!=smc_flash::smc_bootloader_activation_countdown#12) goto smc_flash::@8 -- 0_neq_vbum1_then_la1 
    lda smc_bootloader_activation_countdown_1
    beq !__b8+
    jmp __b8
  !__b8:
    // smc_flash::@9
    // cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1589] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1590] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [1591] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [1592] cx16_k_i2c_read_byte::return#12 = cx16_k_i2c_read_byte::return#1
    // smc_flash::@45
    // smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1593] smc_flash::smc_bootloader_not_activated#1 = cx16_k_i2c_read_byte::return#12 -- vwuz1=vwum2 
    lda cx16_k_i2c_read_byte.return
    sta.z smc_bootloader_not_activated
    lda cx16_k_i2c_read_byte.return+1
    sta.z smc_bootloader_not_activated+1
    // if(smc_bootloader_not_activated)
    // [1594] if(0==smc_flash::smc_bootloader_not_activated#1) goto smc_flash::@1 -- 0_eq_vwuz1_then_la1 
    lda.z smc_bootloader_not_activated
    ora.z smc_bootloader_not_activated+1
    beq __b1
    // [1595] phi from smc_flash::@45 to smc_flash::@10 [phi:smc_flash::@45->smc_flash::@10]
    // smc_flash::@10
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1596] call snprintf_init
    // [1113] phi from smc_flash::@10 to snprintf_init [phi:smc_flash::@10->snprintf_init]
    // [1113] phi snprintf_init::s#25 = info_text [phi:smc_flash::@10->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1597] phi from smc_flash::@10 to smc_flash::@48 [phi:smc_flash::@10->smc_flash::@48]
    // smc_flash::@48
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1598] call printf_str
    // [1054] phi from smc_flash::@48 to printf_str [phi:smc_flash::@48->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:smc_flash::@48->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = smc_flash::s5 [phi:smc_flash::@48->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@49
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1599] printf_uint::uvalue#3 = smc_flash::smc_bootloader_not_activated#1 -- vwum1=vwuz2 
    lda.z smc_bootloader_not_activated
    sta printf_uint.uvalue
    lda.z smc_bootloader_not_activated+1
    sta printf_uint.uvalue+1
    // [1600] call printf_uint
    // [1835] phi from smc_flash::@49 to printf_uint [phi:smc_flash::@49->printf_uint]
    // [1835] phi printf_uint::format_zero_padding#10 = 0 [phi:smc_flash::@49->printf_uint#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uint.format_zero_padding
    // [1835] phi printf_uint::format_min_length#10 = 0 [phi:smc_flash::@49->printf_uint#1] -- vbum1=vbuc1 
    sta printf_uint.format_min_length
    // [1835] phi printf_uint::putc#10 = &snputc [phi:smc_flash::@49->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [1835] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:smc_flash::@49->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [1835] phi printf_uint::uvalue#10 = printf_uint::uvalue#3 [phi:smc_flash::@49->printf_uint#4] -- register_copy 
    jsr printf_uint
    // smc_flash::@50
    // sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated)
    // [1601] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1602] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1604] call display_action_text
    // [1129] phi from smc_flash::@50 to display_action_text [phi:smc_flash::@50->display_action_text]
    // [1129] phi display_action_text::info_text#17 = info_text [phi:smc_flash::@50->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    jmp __b2
    // [1605] phi from smc_flash::@45 to smc_flash::@1 [phi:smc_flash::@45->smc_flash::@1]
    // smc_flash::@1
  __b1:
    // display_action_progress("Updating SMC firmware ... (+) Updated")
    // [1606] call display_action_progress
    // [1084] phi from smc_flash::@1 to display_action_progress [phi:smc_flash::@1->display_action_progress]
    // [1084] phi display_action_progress::info_text#20 = smc_flash::info_text1 [phi:smc_flash::@1->display_action_progress#0] -- pbuz1=pbuc1 
    lda #<info_text1
    sta.z display_action_progress.info_text
    lda #>info_text1
    sta.z display_action_progress.info_text+1
    jsr display_action_progress
    // [1607] phi from smc_flash::@1 to smc_flash::@46 [phi:smc_flash::@1->smc_flash::@46]
    // smc_flash::@46
    // textcolor(WHITE)
    // [1608] call textcolor
    // [760] phi from smc_flash::@46 to textcolor [phi:smc_flash::@46->textcolor]
    // [760] phi textcolor::color#23 = WHITE [phi:smc_flash::@46->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [1609] phi from smc_flash::@46 to smc_flash::@47 [phi:smc_flash::@46->smc_flash::@47]
    // smc_flash::@47
    // gotoxy(x, y)
    // [1610] call gotoxy
    // [778] phi from smc_flash::@47 to gotoxy [phi:smc_flash::@47->gotoxy]
    // [778] phi gotoxy::y#33 = PROGRESS_Y [phi:smc_flash::@47->gotoxy#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta gotoxy.y
    // [778] phi gotoxy::x#33 = PROGRESS_X [phi:smc_flash::@47->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1611] phi from smc_flash::@47 to smc_flash::@11 [phi:smc_flash::@47->smc_flash::@11]
    // [1611] phi smc_flash::y#36 = PROGRESS_Y [phi:smc_flash::@47->smc_flash::@11#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y
    sta y
    // [1611] phi smc_flash::smc_row_bytes#16 = 0 [phi:smc_flash::@47->smc_flash::@11#1] -- vwum1=vwuc1 
    lda #<0
    sta smc_row_bytes
    sta smc_row_bytes+1
    // [1611] phi smc_flash::smc_bram_ptr#14 = (char *)$a000 [phi:smc_flash::@47->smc_flash::@11#2] -- pbuz1=pbuc1 
    lda #<$a000
    sta.z smc_bram_ptr
    lda #>$a000
    sta.z smc_bram_ptr+1
    // [1611] phi smc_flash::smc_bytes_flashed#13 = 0 [phi:smc_flash::@47->smc_flash::@11#3] -- vwum1=vwuc1 
    lda #<0
    sta smc_bytes_flashed
    sta smc_bytes_flashed+1
    // [1611] phi from smc_flash::@15 to smc_flash::@11 [phi:smc_flash::@15->smc_flash::@11]
    // [1611] phi smc_flash::y#36 = smc_flash::y#21 [phi:smc_flash::@15->smc_flash::@11#0] -- register_copy 
    // [1611] phi smc_flash::smc_row_bytes#16 = smc_flash::smc_row_bytes#11 [phi:smc_flash::@15->smc_flash::@11#1] -- register_copy 
    // [1611] phi smc_flash::smc_bram_ptr#14 = smc_flash::smc_bram_ptr#12 [phi:smc_flash::@15->smc_flash::@11#2] -- register_copy 
    // [1611] phi smc_flash::smc_bytes_flashed#13 = smc_flash::smc_bytes_flashed#12 [phi:smc_flash::@15->smc_flash::@11#3] -- register_copy 
    // smc_flash::@11
  __b11:
    // while(smc_bytes_flashed < smc_bytes_total)
    // [1612] if(smc_flash::smc_bytes_flashed#13<smc_flash::smc_bytes_total#0) goto smc_flash::@13 -- vwum1_lt_vwum2_then_la1 
    lda smc_bytes_flashed+1
    cmp smc_bytes_total+1
    bcc __b10
    bne !+
    lda smc_bytes_flashed
    cmp smc_bytes_total
    bcc __b10
  !:
    // smc_flash::@12
    // display_action_text_flashed(smc_bytes_flashed, "SMC")
    // [1613] display_action_text_flashed::bytes#0 = smc_flash::smc_bytes_flashed#13 -- vduz1=vwum2 
    lda smc_bytes_flashed
    sta.z display_action_text_flashed.bytes
    lda smc_bytes_flashed+1
    sta.z display_action_text_flashed.bytes+1
    lda #0
    sta.z display_action_text_flashed.bytes+2
    sta.z display_action_text_flashed.bytes+3
    // [1614] call display_action_text_flashed
    // [2424] phi from smc_flash::@12 to display_action_text_flashed [phi:smc_flash::@12->display_action_text_flashed]
    // [2424] phi display_action_text_flashed::chip#2 = smc_flash::chip [phi:smc_flash::@12->display_action_text_flashed#0] -- pbuz1=pbuc1 
    lda #<chip
    sta.z display_action_text_flashed.chip
    lda #>chip
    sta.z display_action_text_flashed.chip+1
    // [2424] phi display_action_text_flashed::bytes#2 = display_action_text_flashed::bytes#0 [phi:smc_flash::@12->display_action_text_flashed#1] -- register_copy 
    jsr display_action_text_flashed
    // [1583] phi from smc_flash::@12 to smc_flash::@return [phi:smc_flash::@12->smc_flash::@return]
    // [1583] phi smc_flash::return#1 = smc_flash::smc_bytes_flashed#13 [phi:smc_flash::@12->smc_flash::@return#0] -- register_copy 
    rts
    // [1615] phi from smc_flash::@11 to smc_flash::@13 [phi:smc_flash::@11->smc_flash::@13]
  __b10:
    // [1615] phi smc_flash::y#21 = smc_flash::y#36 [phi:smc_flash::@11->smc_flash::@13#0] -- register_copy 
    // [1615] phi smc_flash::smc_row_bytes#11 = smc_flash::smc_row_bytes#16 [phi:smc_flash::@11->smc_flash::@13#1] -- register_copy 
    // [1615] phi smc_flash::smc_bytes_flashed#12 = smc_flash::smc_bytes_flashed#13 [phi:smc_flash::@11->smc_flash::@13#2] -- register_copy 
    // [1615] phi smc_flash::smc_bram_ptr#12 = smc_flash::smc_bram_ptr#14 [phi:smc_flash::@11->smc_flash::@13#3] -- register_copy 
    // [1615] phi smc_flash::smc_attempts_flashed#15 = 0 [phi:smc_flash::@11->smc_flash::@13#4] -- vbum1=vbuc1 
    lda #0
    sta smc_attempts_flashed
    // [1615] phi smc_flash::smc_package_committed#10 = 0 [phi:smc_flash::@11->smc_flash::@13#5] -- vbum1=vbuc1 
    sta smc_package_committed
    // smc_flash::@13
  __b13:
    // while(!smc_package_committed && smc_attempts_flashed < 10)
    // [1616] if(0!=smc_flash::smc_package_committed#10) goto smc_flash::@15 -- 0_neq_vbum1_then_la1 
    lda smc_package_committed
    bne __b15
    // smc_flash::@55
    // [1617] if(smc_flash::smc_attempts_flashed#15<$a) goto smc_flash::@14 -- vbum1_lt_vbuc1_then_la1 
    lda smc_attempts_flashed
    cmp #$a
    bcc __b14
    // smc_flash::@15
  __b15:
    // if(smc_attempts_flashed >= 10)
    // [1618] if(smc_flash::smc_attempts_flashed#15<$a) goto smc_flash::@11 -- vbum1_lt_vbuc1_then_la1 
    lda smc_attempts_flashed
    cmp #$a
    bcc __b11
    // [1619] phi from smc_flash::@15 to smc_flash::@23 [phi:smc_flash::@15->smc_flash::@23]
    // smc_flash::@23
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1620] call snprintf_init
    // [1113] phi from smc_flash::@23 to snprintf_init [phi:smc_flash::@23->snprintf_init]
    // [1113] phi snprintf_init::s#25 = info_text [phi:smc_flash::@23->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1621] phi from smc_flash::@23 to smc_flash::@52 [phi:smc_flash::@23->smc_flash::@52]
    // smc_flash::@52
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1622] call printf_str
    // [1054] phi from smc_flash::@52 to printf_str [phi:smc_flash::@52->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:smc_flash::@52->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = smc_flash::s6 [phi:smc_flash::@52->printf_str#1] -- pbuz1=pbuc1 
    lda #<s6
    sta.z printf_str.s
    lda #>s6
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@53
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1623] printf_uint::uvalue#4 = smc_flash::smc_bytes_flashed#12 -- vwum1=vwum2 
    lda smc_bytes_flashed
    sta printf_uint.uvalue
    lda smc_bytes_flashed+1
    sta printf_uint.uvalue+1
    // [1624] call printf_uint
    // [1835] phi from smc_flash::@53 to printf_uint [phi:smc_flash::@53->printf_uint]
    // [1835] phi printf_uint::format_zero_padding#10 = 1 [phi:smc_flash::@53->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [1835] phi printf_uint::format_min_length#10 = 4 [phi:smc_flash::@53->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [1835] phi printf_uint::putc#10 = &snputc [phi:smc_flash::@53->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [1835] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:smc_flash::@53->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [1835] phi printf_uint::uvalue#10 = printf_uint::uvalue#4 [phi:smc_flash::@53->printf_uint#4] -- register_copy 
    jsr printf_uint
    // smc_flash::@54
    // sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed)
    // [1625] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1626] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1628] call display_action_text
    // [1129] phi from smc_flash::@54 to display_action_text [phi:smc_flash::@54->display_action_text]
    // [1129] phi display_action_text::info_text#17 = info_text [phi:smc_flash::@54->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // [1583] phi from smc_flash::@54 to smc_flash::@return [phi:smc_flash::@54->smc_flash::@return]
    // [1583] phi smc_flash::return#1 = $ffff [phi:smc_flash::@54->smc_flash::@return#0] -- vwum1=vwuc1 
    lda #<$ffff
    sta return
    lda #>$ffff
    sta return+1
    rts
    // smc_flash::@14
  __b14:
    // display_action_text_flashing(8, "SMC", smc_bram_bank, smc_bram_ptr, smc_bytes_flashed)
    // [1629] display_action_text_flashing::bram_ptr#0 = smc_flash::smc_bram_ptr#12 -- pbuz1=pbuz2 
    lda.z smc_bram_ptr
    sta.z display_action_text_flashing.bram_ptr
    lda.z smc_bram_ptr+1
    sta.z display_action_text_flashing.bram_ptr+1
    // [1630] display_action_text_flashing::address#0 = smc_flash::smc_bytes_flashed#12 -- vduz1=vwum2 
    lda smc_bytes_flashed
    sta.z display_action_text_flashing.address
    lda smc_bytes_flashed+1
    sta.z display_action_text_flashing.address+1
    lda #0
    sta.z display_action_text_flashing.address+2
    sta.z display_action_text_flashing.address+3
    // [1631] call display_action_text_flashing
    // [2453] phi from smc_flash::@14 to display_action_text_flashing [phi:smc_flash::@14->display_action_text_flashing]
    // [2453] phi display_action_text_flashing::address#10 = display_action_text_flashing::address#0 [phi:smc_flash::@14->display_action_text_flashing#0] -- register_copy 
    // [2453] phi display_action_text_flashing::chip#10 = smc_flash::chip [phi:smc_flash::@14->display_action_text_flashing#1] -- pbuz1=pbuc1 
    lda #<chip
    sta.z display_action_text_flashing.chip
    lda #>chip
    sta.z display_action_text_flashing.chip+1
    // [2453] phi display_action_text_flashing::bram_ptr#2 = display_action_text_flashing::bram_ptr#0 [phi:smc_flash::@14->display_action_text_flashing#2] -- register_copy 
    // [2453] phi display_action_text_flashing::bram_bank#2 = smc_flash::smc_bram_bank [phi:smc_flash::@14->display_action_text_flashing#3] -- vbuz1=vbuc1 
    lda #smc_bram_bank
    sta.z display_action_text_flashing.bram_bank
    // [2453] phi display_action_text_flashing::bytes#2 = 8 [phi:smc_flash::@14->display_action_text_flashing#4] -- vduz1=vbuc1 
    lda #8
    sta.z display_action_text_flashing.bytes
    lda #0
    sta.z display_action_text_flashing.bytes+1
    sta.z display_action_text_flashing.bytes+2
    sta.z display_action_text_flashing.bytes+3
    jsr display_action_text_flashing
    // [1632] phi from smc_flash::@14 to smc_flash::@16 [phi:smc_flash::@14->smc_flash::@16]
    // [1632] phi smc_flash::smc_bytes_checksum#2 = 0 [phi:smc_flash::@14->smc_flash::@16#0] -- vbuz1=vbuc1 
    lda #0
    sta.z smc_bytes_checksum
    // [1632] phi smc_flash::smc_bram_ptr#10 = smc_flash::smc_bram_ptr#12 [phi:smc_flash::@14->smc_flash::@16#1] -- register_copy 
    // [1632] phi smc_flash::smc_package_flashed#2 = 0 [phi:smc_flash::@14->smc_flash::@16#2] -- vwuz1=vwuc1 
    sta.z smc_package_flashed
    sta.z smc_package_flashed+1
    // smc_flash::@16
  __b16:
    // while(smc_package_flashed < SMC_PROGRESS_CELL)
    // [1633] if(smc_flash::smc_package_flashed#2<SMC_PROGRESS_CELL) goto smc_flash::@17 -- vwuz1_lt_vbuc1_then_la1 
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
    // [1634] smc_flash::$29 = smc_flash::smc_bytes_checksum#2 ^ $ff -- vbuz1=vbuz1_bxor_vbuc1 
    lda #$ff
    eor.z smc_flash__29
    sta.z smc_flash__29
    // (smc_bytes_checksum ^ 0xFF)+1
    // [1635] smc_flash::$30 = smc_flash::$29 + 1 -- vbuz1=vbuz1_plus_1 
    inc.z smc_flash__30
    // unsigned char smc_checksum_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, (smc_bytes_checksum ^ 0xFF)+1)
    // [1636] smc_flash::cx16_k_i2c_write_byte4_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte4_device
    // [1637] smc_flash::cx16_k_i2c_write_byte4_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte4_offset
    // [1638] smc_flash::cx16_k_i2c_write_byte4_value = smc_flash::$30 -- vbum1=vbuz2 
    lda.z smc_flash__30
    sta cx16_k_i2c_write_byte4_value
    // smc_flash::cx16_k_i2c_write_byte4
    // unsigned char result
    // [1639] smc_flash::cx16_k_i2c_write_byte4_result = 0 -- vbum1=vbuc1 
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
    // smc_flash::@27
    // unsigned int smc_commit_result = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_COMMIT)
    // [1641] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1642] cx16_k_i2c_read_byte::offset = $81 -- vbum1=vbuc1 
    lda #$81
    sta cx16_k_i2c_read_byte.offset
    // [1643] call cx16_k_i2c_read_byte
    // Now send the commit command.
    jsr cx16_k_i2c_read_byte
    // [1644] cx16_k_i2c_read_byte::return#13 = cx16_k_i2c_read_byte::return#1
    // smc_flash::@51
    // [1645] smc_flash::smc_commit_result#0 = cx16_k_i2c_read_byte::return#13 -- vwum1=vwum2 
    lda cx16_k_i2c_read_byte.return
    sta smc_commit_result
    lda cx16_k_i2c_read_byte.return+1
    sta smc_commit_result+1
    // if(smc_commit_result == 1)
    // [1646] if(smc_flash::smc_commit_result#0==1) goto smc_flash::@20 -- vwum1_eq_vbuc1_then_la1 
    bne !+
    lda smc_commit_result
    cmp #1
    beq __b20
  !:
    // smc_flash::@19
    // smc_bram_ptr -= SMC_PROGRESS_CELL
    // [1647] smc_flash::smc_bram_ptr#2 = smc_flash::smc_bram_ptr#10 - SMC_PROGRESS_CELL -- pbuz1=pbuz1_minus_vbuc1 
    sec
    lda.z smc_bram_ptr
    sbc #SMC_PROGRESS_CELL
    sta.z smc_bram_ptr
    lda.z smc_bram_ptr+1
    sbc #0
    sta.z smc_bram_ptr+1
    // smc_attempts_flashed++;
    // [1648] smc_flash::smc_attempts_flashed#1 = ++ smc_flash::smc_attempts_flashed#15 -- vbum1=_inc_vbum1 
    inc smc_attempts_flashed
    // [1615] phi from smc_flash::@19 to smc_flash::@13 [phi:smc_flash::@19->smc_flash::@13]
    // [1615] phi smc_flash::y#21 = smc_flash::y#21 [phi:smc_flash::@19->smc_flash::@13#0] -- register_copy 
    // [1615] phi smc_flash::smc_row_bytes#11 = smc_flash::smc_row_bytes#11 [phi:smc_flash::@19->smc_flash::@13#1] -- register_copy 
    // [1615] phi smc_flash::smc_bytes_flashed#12 = smc_flash::smc_bytes_flashed#12 [phi:smc_flash::@19->smc_flash::@13#2] -- register_copy 
    // [1615] phi smc_flash::smc_bram_ptr#12 = smc_flash::smc_bram_ptr#2 [phi:smc_flash::@19->smc_flash::@13#3] -- register_copy 
    // [1615] phi smc_flash::smc_attempts_flashed#15 = smc_flash::smc_attempts_flashed#1 [phi:smc_flash::@19->smc_flash::@13#4] -- register_copy 
    // [1615] phi smc_flash::smc_package_committed#10 = smc_flash::smc_package_committed#10 [phi:smc_flash::@19->smc_flash::@13#5] -- register_copy 
    jmp __b13
    // smc_flash::@20
  __b20:
    // if (smc_row_bytes == SMC_PROGRESS_ROW)
    // [1649] if(smc_flash::smc_row_bytes#11!=SMC_PROGRESS_ROW) goto smc_flash::@21 -- vwum1_neq_vwuc1_then_la1 
    lda smc_row_bytes+1
    cmp #>SMC_PROGRESS_ROW
    bne __b21
    lda smc_row_bytes
    cmp #<SMC_PROGRESS_ROW
    bne __b21
    // smc_flash::@22
    // gotoxy(x, ++y);
    // [1650] smc_flash::y#1 = ++ smc_flash::y#21 -- vbum1=_inc_vbum1 
    inc y
    // gotoxy(x, ++y)
    // [1651] gotoxy::y#25 = smc_flash::y#1 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1652] call gotoxy
    // [778] phi from smc_flash::@22 to gotoxy [phi:smc_flash::@22->gotoxy]
    // [778] phi gotoxy::y#33 = gotoxy::y#25 [phi:smc_flash::@22->gotoxy#0] -- register_copy 
    // [778] phi gotoxy::x#33 = PROGRESS_X [phi:smc_flash::@22->gotoxy#1] -- vbum1=vbuc1 
    lda #PROGRESS_X
    sta gotoxy.x
    jsr gotoxy
    // [1653] phi from smc_flash::@22 to smc_flash::@21 [phi:smc_flash::@22->smc_flash::@21]
    // [1653] phi smc_flash::y#38 = smc_flash::y#1 [phi:smc_flash::@22->smc_flash::@21#0] -- register_copy 
    // [1653] phi smc_flash::smc_row_bytes#4 = 0 [phi:smc_flash::@22->smc_flash::@21#1] -- vwum1=vbuc1 
    lda #<0
    sta smc_row_bytes
    sta smc_row_bytes+1
    // [1653] phi from smc_flash::@20 to smc_flash::@21 [phi:smc_flash::@20->smc_flash::@21]
    // [1653] phi smc_flash::y#38 = smc_flash::y#21 [phi:smc_flash::@20->smc_flash::@21#0] -- register_copy 
    // [1653] phi smc_flash::smc_row_bytes#4 = smc_flash::smc_row_bytes#11 [phi:smc_flash::@20->smc_flash::@21#1] -- register_copy 
    // smc_flash::@21
  __b21:
    // cputc('+')
    // [1654] stackpush(char) = '+' -- _stackpushbyte_=vbuc1 
    lda #'+'
    pha
    // [1655] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // smc_bytes_flashed += SMC_PROGRESS_CELL
    // [1657] smc_flash::smc_bytes_flashed#1 = smc_flash::smc_bytes_flashed#12 + SMC_PROGRESS_CELL -- vwum1=vwum1_plus_vbuc1 
    lda #SMC_PROGRESS_CELL
    clc
    adc smc_bytes_flashed
    sta smc_bytes_flashed
    bcc !+
    inc smc_bytes_flashed+1
  !:
    // smc_row_bytes += SMC_PROGRESS_CELL
    // [1658] smc_flash::smc_row_bytes#1 = smc_flash::smc_row_bytes#4 + SMC_PROGRESS_CELL -- vwum1=vwum1_plus_vbuc1 
    lda #SMC_PROGRESS_CELL
    clc
    adc smc_row_bytes
    sta smc_row_bytes
    bcc !+
    inc smc_row_bytes+1
  !:
    // [1615] phi from smc_flash::@21 to smc_flash::@13 [phi:smc_flash::@21->smc_flash::@13]
    // [1615] phi smc_flash::y#21 = smc_flash::y#38 [phi:smc_flash::@21->smc_flash::@13#0] -- register_copy 
    // [1615] phi smc_flash::smc_row_bytes#11 = smc_flash::smc_row_bytes#1 [phi:smc_flash::@21->smc_flash::@13#1] -- register_copy 
    // [1615] phi smc_flash::smc_bytes_flashed#12 = smc_flash::smc_bytes_flashed#1 [phi:smc_flash::@21->smc_flash::@13#2] -- register_copy 
    // [1615] phi smc_flash::smc_bram_ptr#12 = smc_flash::smc_bram_ptr#10 [phi:smc_flash::@21->smc_flash::@13#3] -- register_copy 
    // [1615] phi smc_flash::smc_attempts_flashed#15 = smc_flash::smc_attempts_flashed#15 [phi:smc_flash::@21->smc_flash::@13#4] -- register_copy 
    // [1615] phi smc_flash::smc_package_committed#10 = 1 [phi:smc_flash::@21->smc_flash::@13#5] -- vbum1=vbuc1 
    lda #1
    sta smc_package_committed
    jmp __b13
    // smc_flash::@17
  __b17:
    // unsigned char smc_byte_upload = *smc_bram_ptr
    // [1659] smc_flash::smc_byte_upload#0 = *smc_flash::smc_bram_ptr#10 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (smc_bram_ptr),y
    sta.z smc_byte_upload
    // smc_bram_ptr++;
    // [1660] smc_flash::smc_bram_ptr#1 = ++ smc_flash::smc_bram_ptr#10 -- pbuz1=_inc_pbuz1 
    inc.z smc_bram_ptr
    bne !+
    inc.z smc_bram_ptr+1
  !:
    // smc_bytes_checksum += smc_byte_upload
    // [1661] smc_flash::smc_bytes_checksum#1 = smc_flash::smc_bytes_checksum#2 + smc_flash::smc_byte_upload#0 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z smc_bytes_checksum
    clc
    adc.z smc_byte_upload
    sta.z smc_bytes_checksum
    // unsigned char smc_upload_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, smc_byte_upload)
    // [1662] smc_flash::cx16_k_i2c_write_byte3_device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_write_byte3_device
    // [1663] smc_flash::cx16_k_i2c_write_byte3_offset = $80 -- vbum1=vbuc1 
    lda #$80
    sta cx16_k_i2c_write_byte3_offset
    // [1664] smc_flash::cx16_k_i2c_write_byte3_value = smc_flash::smc_byte_upload#0 -- vbum1=vbuz2 
    lda.z smc_byte_upload
    sta cx16_k_i2c_write_byte3_value
    // smc_flash::cx16_k_i2c_write_byte3
    // unsigned char result
    // [1665] smc_flash::cx16_k_i2c_write_byte3_result = 0 -- vbum1=vbuc1 
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
    // smc_flash::@26
    // smc_package_flashed++;
    // [1667] smc_flash::smc_package_flashed#1 = ++ smc_flash::smc_package_flashed#2 -- vwuz1=_inc_vwuz1 
    inc.z smc_package_flashed
    bne !+
    inc.z smc_package_flashed+1
  !:
    // [1632] phi from smc_flash::@26 to smc_flash::@16 [phi:smc_flash::@26->smc_flash::@16]
    // [1632] phi smc_flash::smc_bytes_checksum#2 = smc_flash::smc_bytes_checksum#1 [phi:smc_flash::@26->smc_flash::@16#0] -- register_copy 
    // [1632] phi smc_flash::smc_bram_ptr#10 = smc_flash::smc_bram_ptr#1 [phi:smc_flash::@26->smc_flash::@16#1] -- register_copy 
    // [1632] phi smc_flash::smc_package_flashed#2 = smc_flash::smc_package_flashed#1 [phi:smc_flash::@26->smc_flash::@16#2] -- register_copy 
    jmp __b16
    // [1668] phi from smc_flash::@7 to smc_flash::@8 [phi:smc_flash::@7->smc_flash::@8]
    // smc_flash::@8
  __b8:
    // wait_moment(1)
    // [1669] call wait_moment
    // [1063] phi from smc_flash::@8 to wait_moment [phi:smc_flash::@8->wait_moment]
    // [1063] phi wait_moment::w#7 = 1 [phi:smc_flash::@8->wait_moment#0] -- vbum1=vbuc1 
    lda #1
    sta wait_moment.w
    jsr wait_moment
    // [1670] phi from smc_flash::@8 to smc_flash::@39 [phi:smc_flash::@8->smc_flash::@39]
    // smc_flash::@39
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1671] call snprintf_init
    // [1113] phi from smc_flash::@39 to snprintf_init [phi:smc_flash::@39->snprintf_init]
    // [1113] phi snprintf_init::s#25 = info_text [phi:smc_flash::@39->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1672] phi from smc_flash::@39 to smc_flash::@40 [phi:smc_flash::@39->smc_flash::@40]
    // smc_flash::@40
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1673] call printf_str
    // [1054] phi from smc_flash::@40 to printf_str [phi:smc_flash::@40->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:smc_flash::@40->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = smc_flash::s3 [phi:smc_flash::@40->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@41
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1674] printf_uchar::uvalue#11 = smc_flash::smc_bootloader_activation_countdown#12 -- vbum1=vbum2 
    lda smc_bootloader_activation_countdown_1
    sta printf_uchar.uvalue
    // [1675] call printf_uchar
    // [1118] phi from smc_flash::@41 to printf_uchar [phi:smc_flash::@41->printf_uchar]
    // [1118] phi printf_uchar::format_zero_padding#17 = 0 [phi:smc_flash::@41->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1118] phi printf_uchar::format_min_length#17 = 0 [phi:smc_flash::@41->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1118] phi printf_uchar::putc#17 = &snputc [phi:smc_flash::@41->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1118] phi printf_uchar::format_radix#17 = DECIMAL [phi:smc_flash::@41->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1118] phi printf_uchar::uvalue#17 = printf_uchar::uvalue#11 [phi:smc_flash::@41->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1676] phi from smc_flash::@41 to smc_flash::@42 [phi:smc_flash::@41->smc_flash::@42]
    // smc_flash::@42
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1677] call printf_str
    // [1054] phi from smc_flash::@42 to printf_str [phi:smc_flash::@42->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:smc_flash::@42->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = s4 [phi:smc_flash::@42->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@43
    // sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown)
    // [1678] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1679] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1681] call display_action_text
    // [1129] phi from smc_flash::@43 to display_action_text [phi:smc_flash::@43->display_action_text]
    // [1129] phi display_action_text::info_text#17 = info_text [phi:smc_flash::@43->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_flash::@44
    // smc_bootloader_activation_countdown--;
    // [1682] smc_flash::smc_bootloader_activation_countdown#3 = -- smc_flash::smc_bootloader_activation_countdown#12 -- vbum1=_dec_vbum1 
    dec smc_bootloader_activation_countdown_1
    // [1587] phi from smc_flash::@44 to smc_flash::@7 [phi:smc_flash::@44->smc_flash::@7]
    // [1587] phi smc_flash::smc_bootloader_activation_countdown#12 = smc_flash::smc_bootloader_activation_countdown#3 [phi:smc_flash::@44->smc_flash::@7#0] -- register_copy 
    jmp __b7
    // smc_flash::@4
  __b4:
    // unsigned int smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET)
    // [1683] cx16_k_i2c_read_byte::device = $42 -- vbum1=vbuc1 
    lda #$42
    sta cx16_k_i2c_read_byte.device
    // [1684] cx16_k_i2c_read_byte::offset = $8e -- vbum1=vbuc1 
    lda #$8e
    sta cx16_k_i2c_read_byte.offset
    // [1685] call cx16_k_i2c_read_byte
    jsr cx16_k_i2c_read_byte
    // [1686] cx16_k_i2c_read_byte::return#11 = cx16_k_i2c_read_byte::return#1
    // smc_flash::@33
    // [1687] smc_flash::smc_bootloader_not_activated1#0 = cx16_k_i2c_read_byte::return#11 -- vwum1=vwum2 
    lda cx16_k_i2c_read_byte.return
    sta smc_bootloader_not_activated1
    lda cx16_k_i2c_read_byte.return+1
    sta smc_bootloader_not_activated1+1
    // if(smc_bootloader_not_activated)
    // [1688] if(0!=smc_flash::smc_bootloader_not_activated1#0) goto smc_flash::@5 -- 0_neq_vwum1_then_la1 
    lda smc_bootloader_not_activated1
    ora smc_bootloader_not_activated1+1
    bne __b5
    jmp __b9
    // [1689] phi from smc_flash::@33 to smc_flash::@5 [phi:smc_flash::@33->smc_flash::@5]
    // smc_flash::@5
  __b5:
    // wait_moment(1)
    // [1690] call wait_moment
    // [1063] phi from smc_flash::@5 to wait_moment [phi:smc_flash::@5->wait_moment]
    // [1063] phi wait_moment::w#7 = 1 [phi:smc_flash::@5->wait_moment#0] -- vbum1=vbuc1 
    lda #1
    sta wait_moment.w
    jsr wait_moment
    // [1691] phi from smc_flash::@5 to smc_flash::@34 [phi:smc_flash::@5->smc_flash::@34]
    // smc_flash::@34
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1692] call snprintf_init
    // [1113] phi from smc_flash::@34 to snprintf_init [phi:smc_flash::@34->snprintf_init]
    // [1113] phi snprintf_init::s#25 = info_text [phi:smc_flash::@34->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z snprintf_init.s
    lda #>@info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [1693] phi from smc_flash::@34 to smc_flash::@35 [phi:smc_flash::@34->smc_flash::@35]
    // smc_flash::@35
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1694] call printf_str
    // [1054] phi from smc_flash::@35 to printf_str [phi:smc_flash::@35->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:smc_flash::@35->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = s1 [phi:smc_flash::@35->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@36
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1695] printf_uchar::uvalue#10 = smc_flash::smc_bootloader_activation_countdown#10 -- vbum1=vbum2 
    lda smc_bootloader_activation_countdown
    sta printf_uchar.uvalue
    // [1696] call printf_uchar
    // [1118] phi from smc_flash::@36 to printf_uchar [phi:smc_flash::@36->printf_uchar]
    // [1118] phi printf_uchar::format_zero_padding#17 = 1 [phi:smc_flash::@36->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1118] phi printf_uchar::format_min_length#17 = 3 [phi:smc_flash::@36->printf_uchar#1] -- vbum1=vbuc1 
    lda #3
    sta printf_uchar.format_min_length
    // [1118] phi printf_uchar::putc#17 = &snputc [phi:smc_flash::@36->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1118] phi printf_uchar::format_radix#17 = DECIMAL [phi:smc_flash::@36->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1118] phi printf_uchar::uvalue#17 = printf_uchar::uvalue#10 [phi:smc_flash::@36->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1697] phi from smc_flash::@36 to smc_flash::@37 [phi:smc_flash::@36->smc_flash::@37]
    // smc_flash::@37
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1698] call printf_str
    // [1054] phi from smc_flash::@37 to printf_str [phi:smc_flash::@37->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:smc_flash::@37->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = smc_flash::s2 [phi:smc_flash::@37->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // smc_flash::@38
    // sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown)
    // [1699] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1700] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [1702] call display_action_text
    // [1129] phi from smc_flash::@38 to display_action_text [phi:smc_flash::@38->display_action_text]
    // [1129] phi display_action_text::info_text#17 = info_text [phi:smc_flash::@38->display_action_text#0] -- pbuz1=pbuc1 
    lda #<@info_text
    sta.z display_action_text.info_text
    lda #>@info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // smc_flash::@6
    // smc_bootloader_activation_countdown--;
    // [1703] smc_flash::smc_bootloader_activation_countdown#2 = -- smc_flash::smc_bootloader_activation_countdown#10 -- vbum1=_dec_vbum1 
    dec smc_bootloader_activation_countdown
    // [1585] phi from smc_flash::@6 to smc_flash::@3 [phi:smc_flash::@6->smc_flash::@3]
    // [1585] phi smc_flash::smc_bootloader_activation_countdown#10 = smc_flash::smc_bootloader_activation_countdown#2 [phi:smc_flash::@6->smc_flash::@3#0] -- register_copy 
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
    cx16_k_i2c_write_byte1_return: .byte 0
    return: .word 0
    .label smc_bootloader_not_activated1 = fopen.cbm_k_setnam1_fopen__0
    // Waiting a bit to ensure the bootloader is activated.
    .label smc_bootloader_activation_countdown = main.check_status_cx16_rom1_check_status_rom1_main__0
    // Waiting a bit to ensure the bootloader is activated.
    .label smc_bootloader_activation_countdown_1 = main.check_status_smc4_main__0
    smc_commit_result: .word 0
    .label smc_attempts_flashed = main.check_status_cx16_rom3_check_status_rom1_main__0
    .label smc_bytes_flashed = return
    .label smc_row_bytes = smc_read.smc_file_read
    .label y = main.check_status_cx16_rom2_check_status_rom1_main__0
    .label smc_bytes_total = util_wait_key.ch
    .label smc_package_committed = main.check_status_smc5_main__0
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
// __mem() char util_wait_key(__zp($c1) char *info_text, __zp($41) char *filter)
util_wait_key: {
    .const bank_set_bram1_bank = 0
    .const bank_set_brom1_bank = 4
    .label util_wait_key__10 = $ba
    .label bram = $ed
    .label brom = $44
    .label return = $c0
    .label info_text = $c1
    .label return_1 = $6a
    .label return_2 = $c9
    .label return_3 = $cd
    .label filter = $41
    // display_action_text(info_text)
    // [1705] display_action_text::info_text#0 = util_wait_key::info_text#6
    // [1706] call display_action_text
    // [1129] phi from util_wait_key to display_action_text [phi:util_wait_key->display_action_text]
    // [1129] phi display_action_text::info_text#17 = display_action_text::info_text#0 [phi:util_wait_key->display_action_text#0] -- register_copy 
    jsr display_action_text
    // util_wait_key::bank_get_bram1
    // return BRAM;
    // [1707] util_wait_key::bram#0 = BRAM -- vbuz1=vbuz2 
    lda.z BRAM
    sta.z bram
    // util_wait_key::bank_get_brom1
    // return BROM;
    // [1708] util_wait_key::brom#0 = BROM -- vbuz1=vbuz2 
    lda.z BROM
    sta.z brom
    // util_wait_key::bank_set_bram1
    // BRAM = bank
    // [1709] BRAM = util_wait_key::bank_set_bram1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_bram1_bank
    sta.z BRAM
    // util_wait_key::bank_set_brom1
    // BROM = bank
    // [1710] BROM = util_wait_key::bank_set_brom1_bank#0 -- vbuz1=vbuc1 
    lda #bank_set_brom1_bank
    sta.z BROM
    // util_wait_key::CLI1
    // asm
    // asm { cli  }
    cli
    // [1712] phi from util_wait_key::@2 util_wait_key::@5 util_wait_key::CLI1 to util_wait_key::kbhit1 [phi:util_wait_key::@2/util_wait_key::@5/util_wait_key::CLI1->util_wait_key::kbhit1]
    // util_wait_key::kbhit1
  kbhit1:
    // util_wait_key::kbhit1_cbm_k_clrchn1
    // asm
    // asm { jsrCBM_CLRCHN  }
    jsr CBM_CLRCHN
    // [1714] phi from util_wait_key::kbhit1_cbm_k_clrchn1 to util_wait_key::kbhit1_@2 [phi:util_wait_key::kbhit1_cbm_k_clrchn1->util_wait_key::kbhit1_@2]
    // util_wait_key::kbhit1_@2
    // cbm_k_getin()
    // [1715] call cbm_k_getin
    jsr cbm_k_getin
    // [1716] cbm_k_getin::return#2 = cbm_k_getin::return#1
    // util_wait_key::@4
    // [1717] util_wait_key::ch#4 = cbm_k_getin::return#2 -- vwum1=vbum2 
    lda cbm_k_getin.return
    sta ch
    lda #0
    sta ch+1
    // util_wait_key::@3
    // if (filter)
    // [1718] if((char *)0!=util_wait_key::filter#16) goto util_wait_key::@1 -- pbuc1_neq_pbuz1_then_la1 
    // if there is a filter, check the filter, otherwise return ch.
    lda.z filter+1
    cmp #>0
    bne __b1
    lda.z filter
    cmp #<0
    bne __b1
    // util_wait_key::@2
    // if(ch)
    // [1719] if(0!=util_wait_key::ch#4) goto util_wait_key::bank_set_bram2 -- 0_neq_vwum1_then_la1 
    lda ch
    ora ch+1
    bne bank_set_bram2
    jmp kbhit1
    // util_wait_key::bank_set_bram2
  bank_set_bram2:
    // BRAM = bank
    // [1720] BRAM = util_wait_key::bram#0 -- vbuz1=vbuz2 
    lda.z bram
    sta.z BRAM
    // util_wait_key::bank_set_brom2
    // BROM = bank
    // [1721] BROM = util_wait_key::brom#0 -- vbuz1=vbuz2 
    lda.z brom
    sta.z BROM
    // util_wait_key::@return
    // }
    // [1722] return 
    rts
    // util_wait_key::@1
  __b1:
    // strchr(filter, ch)
    // [1723] strchr::str#0 = (const void *)util_wait_key::filter#16 -- pvoz1=pvoz2 
    lda.z filter
    sta.z strchr.str
    lda.z filter+1
    sta.z strchr.str+1
    // [1724] strchr::c#0 = util_wait_key::ch#4 -- vbum1=vwum2 
    lda ch
    sta strchr.c
    // [1725] call strchr
    // [1729] phi from util_wait_key::@1 to strchr [phi:util_wait_key::@1->strchr]
    // [1729] phi strchr::c#4 = strchr::c#0 [phi:util_wait_key::@1->strchr#0] -- register_copy 
    // [1729] phi strchr::str#2 = strchr::str#0 [phi:util_wait_key::@1->strchr#1] -- register_copy 
    jsr strchr
    // strchr(filter, ch)
    // [1726] strchr::return#3 = strchr::return#2
    // util_wait_key::@5
    // [1727] util_wait_key::$10 = strchr::return#3
    // if(strchr(filter, ch) != NULL)
    // [1728] if(util_wait_key::$10!=0) goto util_wait_key::bank_set_bram2 -- pvoz1_neq_0_then_la1 
    lda.z util_wait_key__10
    ora.z util_wait_key__10+1
    bne bank_set_bram2
    jmp kbhit1
  .segment Data
    ch: .word 0
    return_4: .byte 0
}
.segment Code
  // strchr
// Searches for the first occurrence of the character c (an unsigned char) in the string pointed to, by the argument str.
// - str: The memory to search
// - c: A character to search for
// Return: A pointer to the matching byte or NULL if the character does not occur in the given memory area.
// __zp($ba) void * strchr(__zp($ba) const void *str, __mem() char c)
strchr: {
    .label ptr = $ba
    .label return = $ba
    .label str = $ba
    // [1730] strchr::ptr#6 = (char *)strchr::str#2
    // [1731] phi from strchr strchr::@3 to strchr::@1 [phi:strchr/strchr::@3->strchr::@1]
    // [1731] phi strchr::ptr#2 = strchr::ptr#6 [phi:strchr/strchr::@3->strchr::@1#0] -- register_copy 
    // strchr::@1
  __b1:
    // while(*ptr)
    // [1732] if(0!=*strchr::ptr#2) goto strchr::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (ptr),y
    cmp #0
    bne __b2
    // [1733] phi from strchr::@1 to strchr::@return [phi:strchr::@1->strchr::@return]
    // [1733] phi strchr::return#2 = (void *) 0 [phi:strchr::@1->strchr::@return#0] -- pvoz1=pvoc1 
    tya
    sta.z return
    sta.z return+1
    // strchr::@return
    // }
    // [1734] return 
    rts
    // strchr::@2
  __b2:
    // if(*ptr==c)
    // [1735] if(*strchr::ptr#2!=strchr::c#4) goto strchr::@3 -- _deref_pbuz1_neq_vbum2_then_la1 
    ldy #0
    lda (ptr),y
    cmp c
    bne __b3
    // strchr::@4
    // [1736] strchr::return#8 = (void *)strchr::ptr#2
    // [1733] phi from strchr::@4 to strchr::@return [phi:strchr::@4->strchr::@return]
    // [1733] phi strchr::return#2 = strchr::return#8 [phi:strchr::@4->strchr::@return#0] -- register_copy 
    rts
    // strchr::@3
  __b3:
    // ptr++;
    // [1737] strchr::ptr#1 = ++ strchr::ptr#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr
    bne !+
    inc.z ptr+1
  !:
    jmp __b1
  .segment Data
    c: .byte 0
}
.segment Code
  // display_info_vera
/**
 * @brief Display the VERA status at the info frame.
 * 
 * @param info_status The STATUS_ 
 */
// void display_info_vera(__mem() char info_status, __zp($58) char *info_text)
display_info_vera: {
    .label x = $44
    .label y = $51
    .label info_text = $58
    // unsigned char x = wherex()
    // [1739] call wherex
    jsr wherex
    // [1740] wherex::return#11 = wherex::return#0
    // display_info_vera::@3
    // [1741] display_info_vera::x#0 = wherex::return#11 -- vbuz1=vbum2 
    lda wherex.return
    sta.z x
    // unsigned char y = wherey()
    // [1742] call wherey
    jsr wherey
    // [1743] wherey::return#11 = wherey::return#0
    // display_info_vera::@4
    // [1744] display_info_vera::y#0 = wherey::return#11 -- vbuz1=vbum2 
    lda wherey.return
    sta.z y
    // status_vera = info_status
    // [1745] status_vera#103 = display_info_vera::info_status#2 -- vbum1=vbum2 
    lda info_status
    sta status_vera
    // display_vera_led(status_color[info_status])
    // [1746] display_vera_led::c#1 = status_color[display_info_vera::info_status#2] -- vbum1=pbuc1_derefidx_vbum2 
    ldy info_status
    lda status_color,y
    sta display_vera_led.c
    // [1747] call display_vera_led
    // [2500] phi from display_info_vera::@4 to display_vera_led [phi:display_info_vera::@4->display_vera_led]
    // [2500] phi display_vera_led::c#2 = display_vera_led::c#1 [phi:display_info_vera::@4->display_vera_led#0] -- register_copy 
    jsr display_vera_led
    // [1748] phi from display_info_vera::@4 to display_info_vera::@5 [phi:display_info_vera::@4->display_info_vera::@5]
    // display_info_vera::@5
    // gotoxy(INFO_X, INFO_Y+1)
    // [1749] call gotoxy
    // [778] phi from display_info_vera::@5 to gotoxy [phi:display_info_vera::@5->gotoxy]
    // [778] phi gotoxy::y#33 = $11+1 [phi:display_info_vera::@5->gotoxy#0] -- vbum1=vbuc1 
    lda #$11+1
    sta gotoxy.y
    // [778] phi gotoxy::x#33 = 4 [phi:display_info_vera::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #4
    sta gotoxy.x
    jsr gotoxy
    // [1750] phi from display_info_vera::@5 to display_info_vera::@6 [phi:display_info_vera::@5->display_info_vera::@6]
    // display_info_vera::@6
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [1751] call printf_str
    // [1054] phi from display_info_vera::@6 to printf_str [phi:display_info_vera::@6->printf_str]
    // [1054] phi printf_str::putc#75 = &cputc [phi:display_info_vera::@6->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = display_info_vera::s [phi:display_info_vera::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@7
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [1752] display_info_vera::$9 = display_info_vera::info_status#2 << 1 -- vbum1=vbum1_rol_1 
    asl display_info_vera__9
    // [1753] printf_string::str#6 = status_text[display_info_vera::$9] -- pbuz1=qbuc1_derefidx_vbum2 
    ldy display_info_vera__9
    lda status_text,y
    sta.z printf_string.str
    lda status_text+1,y
    sta.z printf_string.str+1
    // [1754] call printf_string
    // [1227] phi from display_info_vera::@7 to printf_string [phi:display_info_vera::@7->printf_string]
    // [1227] phi printf_string::putc#25 = &cputc [phi:display_info_vera::@7->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1227] phi printf_string::str#25 = printf_string::str#6 [phi:display_info_vera::@7->printf_string#1] -- register_copy 
    // [1227] phi printf_string::format_justify_left#25 = 1 [phi:display_info_vera::@7->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1227] phi printf_string::format_min_length#25 = 9 [phi:display_info_vera::@7->printf_string#3] -- vbum1=vbuc1 
    lda #9
    sta printf_string.format_min_length
    jsr printf_string
    // [1755] phi from display_info_vera::@7 to display_info_vera::@8 [phi:display_info_vera::@7->display_info_vera::@8]
    // display_info_vera::@8
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [1756] call printf_str
    // [1054] phi from display_info_vera::@8 to printf_str [phi:display_info_vera::@8->printf_str]
    // [1054] phi printf_str::putc#75 = &cputc [phi:display_info_vera::@8->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = display_info_vera::s1 [phi:display_info_vera::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // [1757] phi from display_info_vera::@8 to display_info_vera::@9 [phi:display_info_vera::@8->display_info_vera::@9]
    // display_info_vera::@9
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [1758] call printf_uchar
    // [1118] phi from display_info_vera::@9 to printf_uchar [phi:display_info_vera::@9->printf_uchar]
    // [1118] phi printf_uchar::format_zero_padding#17 = 1 [phi:display_info_vera::@9->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1118] phi printf_uchar::format_min_length#17 = 0 [phi:display_info_vera::@9->printf_uchar#1] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_min_length
    // [1118] phi printf_uchar::putc#17 = &cputc [phi:display_info_vera::@9->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1118] phi printf_uchar::format_radix#17 = HEXADECIMAL [phi:display_info_vera::@9->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1118] phi printf_uchar::uvalue#17 = spi_manufacturer#0 [phi:display_info_vera::@9->printf_uchar#4] -- vbum1=vbuc1 
    lda #spi_manufacturer
    sta printf_uchar.uvalue
    jsr printf_uchar
    // [1759] phi from display_info_vera::@9 to display_info_vera::@10 [phi:display_info_vera::@9->display_info_vera::@10]
    // display_info_vera::@10
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [1760] call printf_str
    // [1054] phi from display_info_vera::@10 to printf_str [phi:display_info_vera::@10->printf_str]
    // [1054] phi printf_str::putc#75 = &cputc [phi:display_info_vera::@10->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = s [phi:display_info_vera::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s
    sta.z printf_str.s
    lda #>@s
    sta.z printf_str.s+1
    jsr printf_str
    // [1761] phi from display_info_vera::@10 to display_info_vera::@11 [phi:display_info_vera::@10->display_info_vera::@11]
    // display_info_vera::@11
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [1762] call printf_uchar
    // [1118] phi from display_info_vera::@11 to printf_uchar [phi:display_info_vera::@11->printf_uchar]
    // [1118] phi printf_uchar::format_zero_padding#17 = 1 [phi:display_info_vera::@11->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1118] phi printf_uchar::format_min_length#17 = 0 [phi:display_info_vera::@11->printf_uchar#1] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_min_length
    // [1118] phi printf_uchar::putc#17 = &cputc [phi:display_info_vera::@11->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1118] phi printf_uchar::format_radix#17 = HEXADECIMAL [phi:display_info_vera::@11->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1118] phi printf_uchar::uvalue#17 = spi_memory_type#0 [phi:display_info_vera::@11->printf_uchar#4] -- vbum1=vbuc1 
    lda #spi_memory_type
    sta printf_uchar.uvalue
    jsr printf_uchar
    // [1763] phi from display_info_vera::@11 to display_info_vera::@12 [phi:display_info_vera::@11->display_info_vera::@12]
    // display_info_vera::@12
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [1764] call printf_str
    // [1054] phi from display_info_vera::@12 to printf_str [phi:display_info_vera::@12->printf_str]
    // [1054] phi printf_str::putc#75 = &cputc [phi:display_info_vera::@12->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = s [phi:display_info_vera::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s
    sta.z printf_str.s
    lda #>@s
    sta.z printf_str.s+1
    jsr printf_str
    // [1765] phi from display_info_vera::@12 to display_info_vera::@13 [phi:display_info_vera::@12->display_info_vera::@13]
    // display_info_vera::@13
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [1766] call printf_uchar
    // [1118] phi from display_info_vera::@13 to printf_uchar [phi:display_info_vera::@13->printf_uchar]
    // [1118] phi printf_uchar::format_zero_padding#17 = 1 [phi:display_info_vera::@13->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1118] phi printf_uchar::format_min_length#17 = 0 [phi:display_info_vera::@13->printf_uchar#1] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_min_length
    // [1118] phi printf_uchar::putc#17 = &cputc [phi:display_info_vera::@13->printf_uchar#2] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_uchar.putc
    lda #>cputc
    sta.z printf_uchar.putc+1
    // [1118] phi printf_uchar::format_radix#17 = HEXADECIMAL [phi:display_info_vera::@13->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1118] phi printf_uchar::uvalue#17 = spi_memory_capacity#0 [phi:display_info_vera::@13->printf_uchar#4] -- vbum1=vbuc1 
    lda #spi_memory_capacity
    sta printf_uchar.uvalue
    jsr printf_uchar
    // [1767] phi from display_info_vera::@13 to display_info_vera::@14 [phi:display_info_vera::@13->display_info_vera::@14]
    // display_info_vera::@14
    // printf("VERA %-9s SPI %0x %0x %0x              ", status_text[info_status], spi_manufacturer, spi_memory_type, spi_memory_capacity)
    // [1768] call printf_str
    // [1054] phi from display_info_vera::@14 to printf_str [phi:display_info_vera::@14->printf_str]
    // [1054] phi printf_str::putc#75 = &cputc [phi:display_info_vera::@14->printf_str#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_str.putc
    lda #>cputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = display_info_vera::s4 [phi:display_info_vera::@14->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // display_info_vera::@15
    // if(info_text)
    // [1769] if((char *)0==display_info_vera::info_text#10) goto display_info_vera::@1 -- pbuc1_eq_pbuz1_then_la1 
    lda.z info_text
    cmp #<0
    bne !+
    lda.z info_text+1
    cmp #>0
    beq __b1
  !:
    // [1770] phi from display_info_vera::@15 to display_info_vera::@2 [phi:display_info_vera::@15->display_info_vera::@2]
    // display_info_vera::@2
    // gotoxy(INFO_X+64-28, INFO_Y+1)
    // [1771] call gotoxy
    // [778] phi from display_info_vera::@2 to gotoxy [phi:display_info_vera::@2->gotoxy]
    // [778] phi gotoxy::y#33 = $11+1 [phi:display_info_vera::@2->gotoxy#0] -- vbum1=vbuc1 
    lda #$11+1
    sta gotoxy.y
    // [778] phi gotoxy::x#33 = 4+$40-$1c [phi:display_info_vera::@2->gotoxy#1] -- vbum1=vbuc1 
    lda #4+$40-$1c
    sta gotoxy.x
    jsr gotoxy
    // display_info_vera::@16
    // printf("%-25s", info_text)
    // [1772] printf_string::str#7 = display_info_vera::info_text#10 -- pbuz1=pbuz2 
    lda.z info_text
    sta.z printf_string.str
    lda.z info_text+1
    sta.z printf_string.str+1
    // [1773] call printf_string
    // [1227] phi from display_info_vera::@16 to printf_string [phi:display_info_vera::@16->printf_string]
    // [1227] phi printf_string::putc#25 = &cputc [phi:display_info_vera::@16->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1227] phi printf_string::str#25 = printf_string::str#7 [phi:display_info_vera::@16->printf_string#1] -- register_copy 
    // [1227] phi printf_string::format_justify_left#25 = 1 [phi:display_info_vera::@16->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1227] phi printf_string::format_min_length#25 = $19 [phi:display_info_vera::@16->printf_string#3] -- vbum1=vbuc1 
    lda #$19
    sta printf_string.format_min_length
    jsr printf_string
    // display_info_vera::@1
  __b1:
    // gotoxy(x, y)
    // [1774] gotoxy::x#17 = display_info_vera::x#0 -- vbum1=vbuz2 
    lda.z x
    sta gotoxy.x
    // [1775] gotoxy::y#17 = display_info_vera::y#0 -- vbum1=vbuz2 
    lda.z y
    sta gotoxy.y
    // [1776] call gotoxy
    // [778] phi from display_info_vera::@1 to gotoxy [phi:display_info_vera::@1->gotoxy]
    // [778] phi gotoxy::y#33 = gotoxy::y#17 [phi:display_info_vera::@1->gotoxy#0] -- register_copy 
    // [778] phi gotoxy::x#33 = gotoxy::x#17 [phi:display_info_vera::@1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_info_vera::@return
    // }
    // [1777] return 
    rts
  .segment Data
    s: .text "VERA "
    .byte 0
    s1: .text " SPI "
    .byte 0
    s4: .text "              "
    .byte 0
    .label display_info_vera__9 = rom_get_prefix.return
    .label info_status = rom_get_prefix.return
}
.segment Code
  // util_wait_space
util_wait_space: {
    // util_wait_key("Press [SPACE] to continue ...", " ")
    // [1779] call util_wait_key
    // [1704] phi from util_wait_space to util_wait_key [phi:util_wait_space->util_wait_key]
    // [1704] phi util_wait_key::filter#16 = s [phi:util_wait_space->util_wait_key#0] -- pbuz1=pbuc1 
    lda #<s
    sta.z util_wait_key.filter
    lda #>s
    sta.z util_wait_key.filter+1
    // [1704] phi util_wait_key::info_text#6 = util_wait_space::info_text [phi:util_wait_space->util_wait_key#1] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z util_wait_key.info_text
    lda #>info_text
    sta.z util_wait_key.info_text+1
    jsr util_wait_key
    // util_wait_space::@return
    // }
    // [1780] return 
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
// void display_info_cx16_rom(__zp($ec) char info_status, __zp($ba) char *info_text)
display_info_cx16_rom: {
    .label info_status = $ec
    .label info_text = $ba
    // display_info_rom(0, info_status, info_text)
    // [1782] display_info_rom::info_status#1 = display_info_cx16_rom::info_status#8
    // [1783] display_info_rom::info_text#1 = display_info_cx16_rom::info_text#8
    // [1784] call display_info_rom
    // [1176] phi from display_info_cx16_rom to display_info_rom [phi:display_info_cx16_rom->display_info_rom]
    // [1176] phi display_info_rom::info_text#16 = display_info_rom::info_text#1 [phi:display_info_cx16_rom->display_info_rom#0] -- register_copy 
    // [1176] phi display_info_rom::rom_chip#16 = 0 [phi:display_info_cx16_rom->display_info_rom#1] -- vbum1=vbuc1 
    lda #0
    sta display_info_rom.rom_chip
    // [1176] phi display_info_rom::info_status#16 = display_info_rom::info_status#1 [phi:display_info_cx16_rom->display_info_rom#2] -- register_copy 
    jsr display_info_rom
    // display_info_cx16_rom::@return
    // }
    // [1785] return 
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
// __zp($ec) char rom_get_release(__zp($ec) char release)
rom_get_release: {
    .label rom_get_release__0 = $51
    .label rom_get_release__2 = $ec
    .label return = $ec
    .label release = $ec
    // release & 0x80
    // [1787] rom_get_release::$0 = rom_get_release::release#3 & $80 -- vbuz1=vbuz2_band_vbuc1 
    lda #$80
    and.z release
    sta.z rom_get_release__0
    // if(release & 0x80)
    // [1788] if(0==rom_get_release::$0) goto rom_get_release::@1 -- 0_eq_vbuz1_then_la1 
    beq __b1
    // rom_get_release::@2
    // ~release
    // [1789] rom_get_release::$2 = ~ rom_get_release::release#3 -- vbuz1=_bnot_vbuz1 
    lda.z rom_get_release__2
    eor #$ff
    sta.z rom_get_release__2
    // release = ~release + 1
    // [1790] rom_get_release::release#0 = rom_get_release::$2 + 1 -- vbuz1=vbuz1_plus_1 
    inc.z release
    // [1791] phi from rom_get_release rom_get_release::@2 to rom_get_release::@1 [phi:rom_get_release/rom_get_release::@2->rom_get_release::@1]
    // [1791] phi rom_get_release::return#0 = rom_get_release::release#3 [phi:rom_get_release/rom_get_release::@2->rom_get_release::@1#0] -- register_copy 
    // rom_get_release::@1
  __b1:
    // rom_get_release::@return
    // }
    // [1792] return 
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
// __mem() char rom_get_prefix(__mem() char release)
rom_get_prefix: {
    // if(release == 0xFF)
    // [1794] if(rom_get_prefix::release#2!=$ff) goto rom_get_prefix::@1 -- vbum1_neq_vbuc1_then_la1 
    lda #$ff
    cmp release
    bne __b3
    // [1795] phi from rom_get_prefix to rom_get_prefix::@3 [phi:rom_get_prefix->rom_get_prefix::@3]
    // rom_get_prefix::@3
    // [1796] phi from rom_get_prefix::@3 to rom_get_prefix::@1 [phi:rom_get_prefix::@3->rom_get_prefix::@1]
    // [1796] phi rom_get_prefix::prefix#4 = 'p' [phi:rom_get_prefix::@3->rom_get_prefix::@1#0] -- vbum1=vbuc1 
    lda #'p'
    sta prefix
    jmp __b1
    // [1796] phi from rom_get_prefix to rom_get_prefix::@1 [phi:rom_get_prefix->rom_get_prefix::@1]
  __b3:
    // [1796] phi rom_get_prefix::prefix#4 = 'r' [phi:rom_get_prefix->rom_get_prefix::@1#0] -- vbum1=vbuc1 
    lda #'r'
    sta prefix
    // rom_get_prefix::@1
  __b1:
    // release & 0x80
    // [1797] rom_get_prefix::$2 = rom_get_prefix::release#2 & $80 -- vbum1=vbum1_band_vbuc1 
    lda #$80
    and rom_get_prefix__2
    sta rom_get_prefix__2
    // if(release & 0x80)
    // [1798] if(0==rom_get_prefix::$2) goto rom_get_prefix::@4 -- 0_eq_vbum1_then_la1 
    beq __b2
    // [1800] phi from rom_get_prefix::@1 to rom_get_prefix::@2 [phi:rom_get_prefix::@1->rom_get_prefix::@2]
    // [1800] phi rom_get_prefix::return#0 = 'p' [phi:rom_get_prefix::@1->rom_get_prefix::@2#0] -- vbum1=vbuc1 
    lda #'p'
    sta return
    rts
    // [1799] phi from rom_get_prefix::@1 to rom_get_prefix::@4 [phi:rom_get_prefix::@1->rom_get_prefix::@4]
    // rom_get_prefix::@4
    // [1800] phi from rom_get_prefix::@4 to rom_get_prefix::@2 [phi:rom_get_prefix::@4->rom_get_prefix::@2]
    // [1800] phi rom_get_prefix::return#0 = rom_get_prefix::prefix#4 [phi:rom_get_prefix::@4->rom_get_prefix::@2#0] -- register_copy 
    // rom_get_prefix::@2
  __b2:
    // rom_get_prefix::@return
    // }
    // [1801] return 
    rts
  .segment Data
    .label rom_get_prefix__2 = main.check_status_rom1_main__0
    return: .byte 0
    .label release = main.check_status_rom1_main__0
    // If the release is 0xFF, then the release is a preview.
    // If bit 7 of the release is set, then the release is a preview.
    .label prefix = return
}
.segment Code
  // rom_get_version_text
// void rom_get_version_text(__zp($b8) char *release_info, __mem() char prefix, __zp($ec) char release, __zp($c1) char *github)
rom_get_version_text: {
    .label release_info = $b8
    .label release = $ec
    .label github = $c1
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [1803] snprintf_init::s#9 = rom_get_version_text::release_info#2
    // [1804] call snprintf_init
    // [1113] phi from rom_get_version_text to snprintf_init [phi:rom_get_version_text->snprintf_init]
    // [1113] phi snprintf_init::s#25 = snprintf_init::s#9 [phi:rom_get_version_text->snprintf_init#0] -- register_copy 
    jsr snprintf_init
    // rom_get_version_text::@1
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [1805] stackpush(char) = rom_get_version_text::prefix#2 -- _stackpushbyte_=vbum1 
    lda prefix
    pha
    // [1806] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // [1808] printf_uchar::uvalue#12 = rom_get_version_text::release#2 -- vbum1=vbuz2 
    lda.z release
    sta printf_uchar.uvalue
    // [1809] call printf_uchar
    // [1118] phi from rom_get_version_text::@1 to printf_uchar [phi:rom_get_version_text::@1->printf_uchar]
    // [1118] phi printf_uchar::format_zero_padding#17 = 0 [phi:rom_get_version_text::@1->printf_uchar#0] -- vbum1=vbuc1 
    lda #0
    sta printf_uchar.format_zero_padding
    // [1118] phi printf_uchar::format_min_length#17 = 0 [phi:rom_get_version_text::@1->printf_uchar#1] -- vbum1=vbuc1 
    sta printf_uchar.format_min_length
    // [1118] phi printf_uchar::putc#17 = &snputc [phi:rom_get_version_text::@1->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1118] phi printf_uchar::format_radix#17 = DECIMAL [phi:rom_get_version_text::@1->printf_uchar#3] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_uchar.format_radix
    // [1118] phi printf_uchar::uvalue#17 = printf_uchar::uvalue#12 [phi:rom_get_version_text::@1->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [1810] phi from rom_get_version_text::@1 to rom_get_version_text::@2 [phi:rom_get_version_text::@1->rom_get_version_text::@2]
    // rom_get_version_text::@2
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [1811] call printf_str
    // [1054] phi from rom_get_version_text::@2 to printf_str [phi:rom_get_version_text::@2->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:rom_get_version_text::@2->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = s [phi:rom_get_version_text::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // rom_get_version_text::@3
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [1812] printf_string::str#16 = rom_get_version_text::github#2 -- pbuz1=pbuz2 
    lda.z github
    sta.z printf_string.str
    lda.z github+1
    sta.z printf_string.str+1
    // [1813] call printf_string
    // [1227] phi from rom_get_version_text::@3 to printf_string [phi:rom_get_version_text::@3->printf_string]
    // [1227] phi printf_string::putc#25 = &snputc [phi:rom_get_version_text::@3->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1227] phi printf_string::str#25 = printf_string::str#16 [phi:rom_get_version_text::@3->printf_string#1] -- register_copy 
    // [1227] phi printf_string::format_justify_left#25 = 0 [phi:rom_get_version_text::@3->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1227] phi printf_string::format_min_length#25 = 0 [phi:rom_get_version_text::@3->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // rom_get_version_text::@4
    // sprintf(release_info, "%c%u %s", prefix, release, github)
    // [1814] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [1815] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // rom_get_version_text::@return
    // }
    // [1817] return 
    rts
  .segment Data
    .label prefix = rom_get_prefix.return
}
.segment Code
  // rom_get_github_commit_id
/**
 * @brief Copy the github commit_id only if the commit_id contains hexadecimal characters. 
 * 
 * @param commit_id The target commit_id.
 * @param from The source ptr in ROM or RAM.
 */
// void rom_get_github_commit_id(__zp($39) char *commit_id, __zp($3b) char *from)
rom_get_github_commit_id: {
    .label ch = $af
    .label c = $a9
    .label commit_id = $39
    .label commit_id_ok = $ac
    .label from = $3b
    // [1819] phi from rom_get_github_commit_id to rom_get_github_commit_id::@2 [phi:rom_get_github_commit_id->rom_get_github_commit_id::@2]
    // [1819] phi rom_get_github_commit_id::commit_id_ok#2 = true [phi:rom_get_github_commit_id->rom_get_github_commit_id::@2#0] -- vboz1=vboc1 
    lda #1
    sta.z commit_id_ok
    // [1819] phi rom_get_github_commit_id::c#2 = 0 [phi:rom_get_github_commit_id->rom_get_github_commit_id::@2#1] -- vbuz1=vbuc1 
    lda #0
    sta.z c
    // rom_get_github_commit_id::@2
  __b2:
    // for(unsigned char c=0; c<7; c++)
    // [1820] if(rom_get_github_commit_id::c#2<7) goto rom_get_github_commit_id::@3 -- vbuz1_lt_vbuc1_then_la1 
    lda.z c
    cmp #7
    bcc __b3
    // rom_get_github_commit_id::@4
    // if(commit_id_ok)
    // [1821] if(rom_get_github_commit_id::commit_id_ok#2) goto rom_get_github_commit_id::@1 -- vboz1_then_la1 
    lda.z commit_id_ok
    cmp #0
    bne __b1
    // rom_get_github_commit_id::@6
    // *commit_id = '\0'
    // [1822] *rom_get_github_commit_id::commit_id#6 = '@' -- _deref_pbuz1=vbuc1 
    lda #'@'
    ldy #0
    sta (commit_id),y
    // rom_get_github_commit_id::@return
    // }
    // [1823] return 
    rts
    // rom_get_github_commit_id::@1
  __b1:
    // strncpy(commit_id, from, 7)
    // [1824] strncpy::dst#2 = rom_get_github_commit_id::commit_id#6
    // [1825] strncpy::src#2 = rom_get_github_commit_id::from#6
    // [1826] call strncpy
    // [2506] phi from rom_get_github_commit_id::@1 to strncpy [phi:rom_get_github_commit_id::@1->strncpy]
    // [2506] phi strncpy::dst#8 = strncpy::dst#2 [phi:rom_get_github_commit_id::@1->strncpy#0] -- register_copy 
    // [2506] phi strncpy::src#6 = strncpy::src#2 [phi:rom_get_github_commit_id::@1->strncpy#1] -- register_copy 
    // [2506] phi strncpy::n#3 = 7 [phi:rom_get_github_commit_id::@1->strncpy#2] -- vwum1=vbuc1 
    lda #<7
    sta strncpy.n
    lda #>7
    sta strncpy.n+1
    jsr strncpy
    rts
    // rom_get_github_commit_id::@3
  __b3:
    // unsigned char ch = from[c]
    // [1827] rom_get_github_commit_id::ch#0 = rom_get_github_commit_id::from#6[rom_get_github_commit_id::c#2] -- vbuz1=pbuz2_derefidx_vbuz3 
    ldy.z c
    lda (from),y
    sta.z ch
    // if(!(ch >= 48 && ch <= 48+9 || ch >= 65 && ch <= 65+26))
    // [1828] if(rom_get_github_commit_id::ch#0<$30) goto rom_get_github_commit_id::@7 -- vbuz1_lt_vbuc1_then_la1 
    cmp #$30
    bcc __b7
    // rom_get_github_commit_id::@8
    // [1829] if(rom_get_github_commit_id::ch#0<$30+9+1) goto rom_get_github_commit_id::@5 -- vbuz1_lt_vbuc1_then_la1 
    cmp #$30+9+1
    bcc __b5
    // rom_get_github_commit_id::@7
  __b7:
    // [1830] if(rom_get_github_commit_id::ch#0<$41) goto rom_get_github_commit_id::@5 -- vbuz1_lt_vbuc1_then_la1 
    lda.z ch
    cmp #$41
    bcc __b4
    // rom_get_github_commit_id::@9
    // [1831] if(rom_get_github_commit_id::ch#0<$41+$1a+1) goto rom_get_github_commit_id::@10 -- vbuz1_lt_vbuc1_then_la1 
    cmp #$41+$1a+1
    bcc __b5
    // [1833] phi from rom_get_github_commit_id::@7 rom_get_github_commit_id::@9 to rom_get_github_commit_id::@5 [phi:rom_get_github_commit_id::@7/rom_get_github_commit_id::@9->rom_get_github_commit_id::@5]
  __b4:
    // [1833] phi rom_get_github_commit_id::commit_id_ok#4 = false [phi:rom_get_github_commit_id::@7/rom_get_github_commit_id::@9->rom_get_github_commit_id::@5#0] -- vboz1=vboc1 
    lda #0
    sta.z commit_id_ok
    // [1832] phi from rom_get_github_commit_id::@9 to rom_get_github_commit_id::@10 [phi:rom_get_github_commit_id::@9->rom_get_github_commit_id::@10]
    // rom_get_github_commit_id::@10
    // [1833] phi from rom_get_github_commit_id::@10 rom_get_github_commit_id::@8 to rom_get_github_commit_id::@5 [phi:rom_get_github_commit_id::@10/rom_get_github_commit_id::@8->rom_get_github_commit_id::@5]
    // [1833] phi rom_get_github_commit_id::commit_id_ok#4 = rom_get_github_commit_id::commit_id_ok#2 [phi:rom_get_github_commit_id::@10/rom_get_github_commit_id::@8->rom_get_github_commit_id::@5#0] -- register_copy 
    // rom_get_github_commit_id::@5
  __b5:
    // for(unsigned char c=0; c<7; c++)
    // [1834] rom_get_github_commit_id::c#1 = ++ rom_get_github_commit_id::c#2 -- vbuz1=_inc_vbuz1 
    inc.z c
    // [1819] phi from rom_get_github_commit_id::@5 to rom_get_github_commit_id::@2 [phi:rom_get_github_commit_id::@5->rom_get_github_commit_id::@2]
    // [1819] phi rom_get_github_commit_id::commit_id_ok#2 = rom_get_github_commit_id::commit_id_ok#4 [phi:rom_get_github_commit_id::@5->rom_get_github_commit_id::@2#0] -- register_copy 
    // [1819] phi rom_get_github_commit_id::c#2 = rom_get_github_commit_id::c#1 [phi:rom_get_github_commit_id::@5->rom_get_github_commit_id::@2#1] -- register_copy 
    jmp __b2
}
  // printf_uint
// Print an unsigned int using a specific format
// void printf_uint(__zp($aa) void (*putc)(char), __mem() unsigned int uvalue, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, __mem() char format_radix)
printf_uint: {
    .label putc = $aa
    // printf_uint::@1
    // printf_buffer.sign = format.sign_always?'+':0
    // [1836] *((char *)&printf_buffer) = 0 -- _deref_pbuc1=vbuc2 
    // Handle any sign
    lda #0
    sta printf_buffer
    // utoa(uvalue, printf_buffer.digits, format.radix)
    // [1837] utoa::value#1 = printf_uint::uvalue#10
    // [1838] utoa::radix#0 = printf_uint::format_radix#10
    // [1839] call utoa
    // Format number into buffer
    jsr utoa
    // printf_uint::@2
    // printf_number_buffer(putc, printf_buffer, format)
    // [1840] printf_number_buffer::putc#1 = printf_uint::putc#10
    // [1841] printf_number_buffer::buffer_sign#1 = *((char *)&printf_buffer) -- vbum1=_deref_pbuc1 
    lda printf_buffer
    sta printf_number_buffer.buffer_sign
    // [1842] printf_number_buffer::format_min_length#1 = printf_uint::format_min_length#10
    // [1843] printf_number_buffer::format_zero_padding#1 = printf_uint::format_zero_padding#10
    // [1844] call printf_number_buffer
  // Print using format
    // [2116] phi from printf_uint::@2 to printf_number_buffer [phi:printf_uint::@2->printf_number_buffer]
    // [2116] phi printf_number_buffer::putc#10 = printf_number_buffer::putc#1 [phi:printf_uint::@2->printf_number_buffer#0] -- register_copy 
    // [2116] phi printf_number_buffer::buffer_sign#10 = printf_number_buffer::buffer_sign#1 [phi:printf_uint::@2->printf_number_buffer#1] -- register_copy 
    // [2116] phi printf_number_buffer::format_zero_padding#10 = printf_number_buffer::format_zero_padding#1 [phi:printf_uint::@2->printf_number_buffer#2] -- register_copy 
    // [2116] phi printf_number_buffer::format_min_length#3 = printf_number_buffer::format_min_length#1 [phi:printf_uint::@2->printf_number_buffer#3] -- register_copy 
    jsr printf_number_buffer
    // printf_uint::@return
    // }
    // [1845] return 
    rts
  .segment Data
    uvalue: .word 0
    format_radix: .byte 0
    .label format_min_length = printf_uchar.format_min_length
    .label format_zero_padding = printf_uchar.format_zero_padding
}
.segment Code
  // screenlayer
// --- layer management in VERA ---
// void screenlayer(char layer, __mem() char mapbase, __mem() char config)
screenlayer: {
    .label screenlayer__0 = $b7
    .label screenlayer__1 = $b6
    .label screenlayer__9 = $f8
    .label screenlayer__10 = $f8
    .label screenlayer__11 = $f8
    .label screenlayer__12 = $f9
    .label screenlayer__13 = $f9
    .label screenlayer__14 = $f9
    .label screenlayer__17 = $ee
    .label screenlayer__18 = $f8
    .label screenlayer__19 = $f9
    .label y = $e2
    // __mem char vera_dc_hscale_temp = *VERA_DC_HSCALE
    // [1846] screenlayer::vera_dc_hscale_temp#0 = *VERA_DC_HSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_HSCALE
    sta vera_dc_hscale_temp
    // __mem char vera_dc_vscale_temp = *VERA_DC_VSCALE
    // [1847] screenlayer::vera_dc_vscale_temp#0 = *VERA_DC_VSCALE -- vbum1=_deref_pbuc1 
    lda VERA_DC_VSCALE
    sta vera_dc_vscale_temp
    // __conio.layer = 0
    // [1848] *((char *)&__conio+2) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta __conio+2
    // mapbase >> 7
    // [1849] screenlayer::$0 = screenlayer::mapbase#0 >> 7 -- vbuz1=vbum2_ror_7 
    lda mapbase
    rol
    rol
    and #1
    sta.z screenlayer__0
    // __conio.mapbase_bank = mapbase >> 7
    // [1850] *((char *)&__conio+5) = screenlayer::$0 -- _deref_pbuc1=vbuz1 
    sta __conio+5
    // (mapbase)<<1
    // [1851] screenlayer::$1 = screenlayer::mapbase#0 << 1 -- vbuz1=vbum2_rol_1 
    lda mapbase
    asl
    sta.z screenlayer__1
    // MAKEWORD((mapbase)<<1,0)
    // [1852] screenlayer::$2 = screenlayer::$1 w= 0 -- vwum1=vbuz2_word_vbuc1 
    lda #0
    ldy.z screenlayer__1
    sty screenlayer__2+1
    sta screenlayer__2
    // __conio.mapbase_offset = MAKEWORD((mapbase)<<1,0)
    // [1853] *((unsigned int *)&__conio+3) = screenlayer::$2 -- _deref_pwuc1=vwum1 
    sta __conio+3
    tya
    sta __conio+3+1
    // config & VERA_LAYER_WIDTH_MASK
    // [1854] screenlayer::$7 = screenlayer::config#0 & VERA_LAYER_WIDTH_MASK -- vbum1=vbum2_band_vbuc1 
    lda #VERA_LAYER_WIDTH_MASK
    and config
    sta screenlayer__7
    // (config & VERA_LAYER_WIDTH_MASK) >> 4
    // [1855] screenlayer::$8 = screenlayer::$7 >> 4 -- vbum1=vbum1_ror_4 
    lda screenlayer__8
    lsr
    lsr
    lsr
    lsr
    sta screenlayer__8
    // __conio.mapwidth = VERA_LAYER_DIM[ (config & VERA_LAYER_WIDTH_MASK) >> 4]
    // [1856] *((char *)&__conio+8) = screenlayer::VERA_LAYER_DIM[screenlayer::$8] -- _deref_pbuc1=pbuc2_derefidx_vbum1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+8
    // config & VERA_LAYER_HEIGHT_MASK
    // [1857] screenlayer::$5 = screenlayer::config#0 & VERA_LAYER_HEIGHT_MASK -- vbum1=vbum2_band_vbuc1 
    lda #VERA_LAYER_HEIGHT_MASK
    and config
    sta screenlayer__5
    // (config & VERA_LAYER_HEIGHT_MASK) >> 6
    // [1858] screenlayer::$6 = screenlayer::$5 >> 6 -- vbum1=vbum1_ror_6 
    lda screenlayer__6
    rol
    rol
    rol
    and #3
    sta screenlayer__6
    // __conio.mapheight = VERA_LAYER_DIM[ (config & VERA_LAYER_HEIGHT_MASK) >> 6]
    // [1859] *((char *)&__conio+9) = screenlayer::VERA_LAYER_DIM[screenlayer::$6] -- _deref_pbuc1=pbuc2_derefidx_vbum1 
    tay
    lda VERA_LAYER_DIM,y
    sta __conio+9
    // __conio.rowskip = VERA_LAYER_SKIP[(config & VERA_LAYER_WIDTH_MASK)>>4]
    // [1860] screenlayer::$16 = screenlayer::$8 << 1 -- vbum1=vbum1_rol_1 
    asl screenlayer__16
    // [1861] *((unsigned int *)&__conio+$a) = screenlayer::VERA_LAYER_SKIP[screenlayer::$16] -- _deref_pwuc1=pwuc2_derefidx_vbum1 
    // __conio.rowshift = ((config & VERA_LAYER_WIDTH_MASK)>>4)+6;
    ldy screenlayer__16
    lda VERA_LAYER_SKIP,y
    sta __conio+$a
    lda VERA_LAYER_SKIP+1,y
    sta __conio+$a+1
    // vera_dc_hscale_temp == 0x80
    // [1862] screenlayer::$9 = screenlayer::vera_dc_hscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_hscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z screenlayer__9
    // 40 << (char)(vera_dc_hscale_temp == 0x80)
    // [1863] screenlayer::$18 = (char)screenlayer::$9
    // [1864] screenlayer::$10 = $28 << screenlayer::$18 -- vbuz1=vbuc1_rol_vbuz1 
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
    // [1865] screenlayer::$11 = screenlayer::$10 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z screenlayer__11
    // __conio.width = (40 << (char)(vera_dc_hscale_temp == 0x80))-1
    // [1866] *((char *)&__conio+6) = screenlayer::$11 -- _deref_pbuc1=vbuz1 
    lda.z screenlayer__11
    sta __conio+6
    // vera_dc_vscale_temp == 0x80
    // [1867] screenlayer::$12 = screenlayer::vera_dc_vscale_temp#0 == $80 -- vboz1=vbum2_eq_vbuc1 
    lda vera_dc_vscale_temp
    eor #$80
    beq !+
    lda #1
  !:
    eor #1
    sta.z screenlayer__12
    // 30 << (char)(vera_dc_vscale_temp == 0x80)
    // [1868] screenlayer::$19 = (char)screenlayer::$12
    // [1869] screenlayer::$13 = $1e << screenlayer::$19 -- vbuz1=vbuc1_rol_vbuz1 
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
    // [1870] screenlayer::$14 = screenlayer::$13 - 1 -- vbuz1=vbuz1_minus_1 
    dec.z screenlayer__14
    // __conio.height = (30 << (char)(vera_dc_vscale_temp == 0x80))-1
    // [1871] *((char *)&__conio+7) = screenlayer::$14 -- _deref_pbuc1=vbuz1 
    lda.z screenlayer__14
    sta __conio+7
    // unsigned int mapbase_offset = __conio.mapbase_offset
    // [1872] screenlayer::mapbase_offset#0 = *((unsigned int *)&__conio+3) -- vwum1=_deref_pwuc1 
    lda __conio+3
    sta mapbase_offset
    lda __conio+3+1
    sta mapbase_offset+1
    // [1873] phi from screenlayer to screenlayer::@1 [phi:screenlayer->screenlayer::@1]
    // [1873] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#0 [phi:screenlayer->screenlayer::@1#0] -- register_copy 
    // [1873] phi screenlayer::y#2 = 0 [phi:screenlayer->screenlayer::@1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z y
    // screenlayer::@1
  __b1:
    // for(register char y=0; y<=__conio.height; y++)
    // [1874] if(screenlayer::y#2<=*((char *)&__conio+7)) goto screenlayer::@2 -- vbuz1_le__deref_pbuc1_then_la1 
    lda __conio+7
    cmp.z y
    bcs __b2
    // screenlayer::@return
    // }
    // [1875] return 
    rts
    // screenlayer::@2
  __b2:
    // __conio.offsets[y] = mapbase_offset
    // [1876] screenlayer::$17 = screenlayer::y#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z y
    asl
    sta.z screenlayer__17
    // [1877] ((unsigned int *)&__conio+$15)[screenlayer::$17] = screenlayer::mapbase_offset#2 -- pwuc1_derefidx_vbuz1=vwum2 
    tay
    lda mapbase_offset
    sta __conio+$15,y
    lda mapbase_offset+1
    sta __conio+$15+1,y
    // mapbase_offset += __conio.rowskip
    // [1878] screenlayer::mapbase_offset#1 = screenlayer::mapbase_offset#2 + *((unsigned int *)&__conio+$a) -- vwum1=vwum1_plus__deref_pwuc1 
    clc
    lda mapbase_offset
    adc __conio+$a
    sta mapbase_offset
    lda mapbase_offset+1
    adc __conio+$a+1
    sta mapbase_offset+1
    // for(register char y=0; y<=__conio.height; y++)
    // [1879] screenlayer::y#1 = ++ screenlayer::y#2 -- vbuz1=_inc_vbuz1 
    inc.z y
    // [1873] phi from screenlayer::@2 to screenlayer::@1 [phi:screenlayer::@2->screenlayer::@1]
    // [1873] phi screenlayer::mapbase_offset#2 = screenlayer::mapbase_offset#1 [phi:screenlayer::@2->screenlayer::@1#0] -- register_copy 
    // [1873] phi screenlayer::y#2 = screenlayer::y#1 [phi:screenlayer::@2->screenlayer::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    VERA_LAYER_DIM: .byte $1f, $3f, $7f, $ff
    VERA_LAYER_SKIP: .word $40, $80, $100, $200
    screenlayer__2: .word 0
    screenlayer__5: .byte 0
    .label screenlayer__6 = screenlayer__5
    screenlayer__7: .byte 0
    .label screenlayer__8 = screenlayer__7
    .label screenlayer__16 = screenlayer__7
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
    // [1880] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // cscroll::@1
    // if(__conio.scroll[__conio.layer])
    // [1881] if(0!=((char *)&__conio+$f)[*((char *)&__conio+2)]) goto cscroll::@4 -- 0_neq_pbuc1_derefidx_(_deref_pbuc2)_then_la1 
    ldy __conio+2
    lda __conio+$f,y
    cmp #0
    bne __b4
    // cscroll::@2
    // if(__conio.cursor_y>__conio.height)
    // [1882] if(*((char *)&__conio+1)<=*((char *)&__conio+7)) goto cscroll::@return -- _deref_pbuc1_le__deref_pbuc2_then_la1 
    lda __conio+7
    cmp __conio+1
    bcs __breturn
    // [1883] phi from cscroll::@2 to cscroll::@3 [phi:cscroll::@2->cscroll::@3]
    // cscroll::@3
    // gotoxy(0,0)
    // [1884] call gotoxy
    // [778] phi from cscroll::@3 to gotoxy [phi:cscroll::@3->gotoxy]
    // [778] phi gotoxy::y#33 = 0 [phi:cscroll::@3->gotoxy#0] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.y
    // [778] phi gotoxy::x#33 = 0 [phi:cscroll::@3->gotoxy#1] -- vbum1=vbuc1 
    sta gotoxy.x
    jsr gotoxy
    // cscroll::@return
  __breturn:
    // }
    // [1885] return 
    rts
    // [1886] phi from cscroll::@1 to cscroll::@4 [phi:cscroll::@1->cscroll::@4]
    // cscroll::@4
  __b4:
    // insertup(1)
    // [1887] call insertup
    jsr insertup
    // cscroll::@5
    // gotoxy( 0, __conio.height)
    // [1888] gotoxy::y#3 = *((char *)&__conio+7) -- vbum1=_deref_pbuc1 
    lda __conio+7
    sta gotoxy.y
    // [1889] call gotoxy
    // [778] phi from cscroll::@5 to gotoxy [phi:cscroll::@5->gotoxy]
    // [778] phi gotoxy::y#33 = gotoxy::y#3 [phi:cscroll::@5->gotoxy#0] -- register_copy 
    // [778] phi gotoxy::x#33 = 0 [phi:cscroll::@5->gotoxy#1] -- vbum1=vbuc1 
    lda #0
    sta gotoxy.x
    jsr gotoxy
    // [1890] phi from cscroll::@5 to cscroll::@6 [phi:cscroll::@5->cscroll::@6]
    // cscroll::@6
    // clearline()
    // [1891] call clearline
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
    // [1892] cx16_k_screen_set_mode::mode = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_screen_set_mode.mode
    // [1893] call cx16_k_screen_set_mode
    jsr cx16_k_screen_set_mode
    // [1894] phi from display_frame_init_64 to display_frame_init_64::@2 [phi:display_frame_init_64->display_frame_init_64::@2]
    // display_frame_init_64::@2
    // screenlayer1()
    // [1895] call screenlayer1
    // Default 80 columns mode.
    jsr screenlayer1
    // display_frame_init_64::@3
    // cx16_k_screen_set_charset(3, (char *)0)
    // [1896] display_frame_init_64::cx16_k_screen_set_charset1_charset = 3 -- vbum1=vbuc1 
    lda #3
    sta cx16_k_screen_set_charset1_charset
    // [1897] display_frame_init_64::cx16_k_screen_set_charset1_offset = (char *) 0 -- pbum1=pbuc1 
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
    // [1899] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTART = start
    // [1900] *VERA_DC_HSTART = display_frame_init_64::vera_display_set_hstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstart1_start
    sta VERA_DC_HSTART
    // display_frame_init_64::vera_display_set_hstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [1901] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_HSTOP = stop
    // [1902] *VERA_DC_HSTOP = display_frame_init_64::vera_display_set_hstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_hstop1_stop
    sta VERA_DC_HSTOP
    // display_frame_init_64::vera_display_set_vstart1
    // *VERA_CTRL |= VERA_DCSEL
    // [1903] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTART = start
    // [1904] *VERA_DC_VSTART = display_frame_init_64::vera_display_set_vstart1_start#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstart1_start
    sta VERA_DC_VSTART
    // display_frame_init_64::vera_display_set_vstop1
    // *VERA_CTRL |= VERA_DCSEL
    // [1905] *VERA_CTRL = *VERA_CTRL | VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_DCSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VSTOP = stop
    // [1906] *VERA_DC_VSTOP = display_frame_init_64::vera_display_set_vstop1_stop#0 -- _deref_pbuc1=vbuc2 
    lda #vera_display_set_vstop1_stop
    sta VERA_DC_VSTOP
    // display_frame_init_64::vera_sprites_hide1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [1907] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VIDEO &= ~VERA_SPRITES_ENABLE
    // [1908] *VERA_DC_VIDEO = *VERA_DC_VIDEO & ~VERA_SPRITES_ENABLE -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_SPRITES_ENABLE^$ff
    and VERA_DC_VIDEO
    sta VERA_DC_VIDEO
    // display_frame_init_64::vera_layer0_hide1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [1909] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VIDEO &= ~VERA_LAYER0_ENABLE
    // [1910] *VERA_DC_VIDEO = *VERA_DC_VIDEO & ~VERA_LAYER0_ENABLE -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_LAYER0_ENABLE^$ff
    and VERA_DC_VIDEO
    sta VERA_DC_VIDEO
    // display_frame_init_64::vera_layer1_show1
    // *VERA_CTRL &= ~VERA_DCSEL
    // [1911] *VERA_CTRL = *VERA_CTRL & ~VERA_DCSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_DCSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // *VERA_DC_VIDEO |= VERA_LAYER1_ENABLE
    // [1912] *VERA_DC_VIDEO = *VERA_DC_VIDEO | VERA_LAYER1_ENABLE -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_LAYER1_ENABLE
    ora VERA_DC_VIDEO
    sta VERA_DC_VIDEO
    // [1913] phi from display_frame_init_64::vera_layer1_show1 to display_frame_init_64::@1 [phi:display_frame_init_64::vera_layer1_show1->display_frame_init_64::@1]
    // display_frame_init_64::@1
    // textcolor(WHITE)
    // [1914] call textcolor
  // Layer 1 is the current text canvas.
    // [760] phi from display_frame_init_64::@1 to textcolor [phi:display_frame_init_64::@1->textcolor]
    // [760] phi textcolor::color#23 = WHITE [phi:display_frame_init_64::@1->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [1915] phi from display_frame_init_64::@1 to display_frame_init_64::@4 [phi:display_frame_init_64::@1->display_frame_init_64::@4]
    // display_frame_init_64::@4
    // bgcolor(BLUE)
    // [1916] call bgcolor
  // Default text color is white.
    // [765] phi from display_frame_init_64::@4 to bgcolor [phi:display_frame_init_64::@4->bgcolor]
    // [765] phi bgcolor::color#15 = BLUE [phi:display_frame_init_64::@4->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [1917] phi from display_frame_init_64::@4 to display_frame_init_64::@5 [phi:display_frame_init_64::@4->display_frame_init_64::@5]
    // display_frame_init_64::@5
    // clrscr()
    // [1918] call clrscr
    // With a blue background.
    // cx16-conio.c won't compile scrolling code for this program with the underlying define, resulting in less code overhead!
    jsr clrscr
    // display_frame_init_64::@return
    // }
    // [1919] return 
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
    // [1921] call textcolor
    // [760] phi from display_frame_draw to textcolor [phi:display_frame_draw->textcolor]
    // [760] phi textcolor::color#23 = LIGHT_BLUE [phi:display_frame_draw->textcolor#0] -- vbum1=vbuc1 
    lda #LIGHT_BLUE
    sta textcolor.color
    jsr textcolor
    // [1922] phi from display_frame_draw to display_frame_draw::@1 [phi:display_frame_draw->display_frame_draw::@1]
    // display_frame_draw::@1
    // bgcolor(BLUE)
    // [1923] call bgcolor
    // [765] phi from display_frame_draw::@1 to bgcolor [phi:display_frame_draw::@1->bgcolor]
    // [765] phi bgcolor::color#15 = BLUE [phi:display_frame_draw::@1->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [1924] phi from display_frame_draw::@1 to display_frame_draw::@2 [phi:display_frame_draw::@1->display_frame_draw::@2]
    // display_frame_draw::@2
    // clrscr()
    // [1925] call clrscr
    jsr clrscr
    // [1926] phi from display_frame_draw::@2 to display_frame_draw::@3 [phi:display_frame_draw::@2->display_frame_draw::@3]
    // display_frame_draw::@3
    // display_frame(0, 0, 67, 14)
    // [1927] call display_frame
    // [2583] phi from display_frame_draw::@3 to display_frame [phi:display_frame_draw::@3->display_frame]
    // [2583] phi display_frame::y#0 = 0 [phi:display_frame_draw::@3->display_frame#0] -- vbum1=vbuc1 
    lda #0
    sta display_frame.y
    // [2583] phi display_frame::y1#16 = $e [phi:display_frame_draw::@3->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2583] phi display_frame::x#0 = 0 [phi:display_frame_draw::@3->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [2583] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@3->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [1928] phi from display_frame_draw::@3 to display_frame_draw::@4 [phi:display_frame_draw::@3->display_frame_draw::@4]
    // display_frame_draw::@4
    // display_frame(0, 0, 67, 2)
    // [1929] call display_frame
    // [2583] phi from display_frame_draw::@4 to display_frame [phi:display_frame_draw::@4->display_frame]
    // [2583] phi display_frame::y#0 = 0 [phi:display_frame_draw::@4->display_frame#0] -- vbum1=vbuc1 
    lda #0
    sta display_frame.y
    // [2583] phi display_frame::y1#16 = 2 [phi:display_frame_draw::@4->display_frame#1] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y1
    // [2583] phi display_frame::x#0 = 0 [phi:display_frame_draw::@4->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [2583] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@4->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [1930] phi from display_frame_draw::@4 to display_frame_draw::@5 [phi:display_frame_draw::@4->display_frame_draw::@5]
    // display_frame_draw::@5
    // display_frame(0, 2, 67, 14)
    // [1931] call display_frame
    // [2583] phi from display_frame_draw::@5 to display_frame [phi:display_frame_draw::@5->display_frame]
    // [2583] phi display_frame::y#0 = 2 [phi:display_frame_draw::@5->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2583] phi display_frame::y1#16 = $e [phi:display_frame_draw::@5->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2583] phi display_frame::x#0 = 0 [phi:display_frame_draw::@5->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [2583] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@5->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [1932] phi from display_frame_draw::@5 to display_frame_draw::@6 [phi:display_frame_draw::@5->display_frame_draw::@6]
    // display_frame_draw::@6
    // display_frame(0, 2, 8, 14)
    // [1933] call display_frame
  // Chipset areas
    // [2583] phi from display_frame_draw::@6 to display_frame [phi:display_frame_draw::@6->display_frame]
    // [2583] phi display_frame::y#0 = 2 [phi:display_frame_draw::@6->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2583] phi display_frame::y1#16 = $e [phi:display_frame_draw::@6->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2583] phi display_frame::x#0 = 0 [phi:display_frame_draw::@6->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [2583] phi display_frame::x1#16 = 8 [phi:display_frame_draw::@6->display_frame#3] -- vbum1=vbuc1 
    lda #8
    sta display_frame.x1
    jsr display_frame
    // [1934] phi from display_frame_draw::@6 to display_frame_draw::@7 [phi:display_frame_draw::@6->display_frame_draw::@7]
    // display_frame_draw::@7
    // display_frame(8, 2, 19, 14)
    // [1935] call display_frame
    // [2583] phi from display_frame_draw::@7 to display_frame [phi:display_frame_draw::@7->display_frame]
    // [2583] phi display_frame::y#0 = 2 [phi:display_frame_draw::@7->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2583] phi display_frame::y1#16 = $e [phi:display_frame_draw::@7->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2583] phi display_frame::x#0 = 8 [phi:display_frame_draw::@7->display_frame#2] -- vbuz1=vbuc1 
    lda #8
    sta.z display_frame.x
    // [2583] phi display_frame::x1#16 = $13 [phi:display_frame_draw::@7->display_frame#3] -- vbum1=vbuc1 
    lda #$13
    sta display_frame.x1
    jsr display_frame
    // [1936] phi from display_frame_draw::@7 to display_frame_draw::@8 [phi:display_frame_draw::@7->display_frame_draw::@8]
    // display_frame_draw::@8
    // display_frame(19, 2, 25, 14)
    // [1937] call display_frame
    // [2583] phi from display_frame_draw::@8 to display_frame [phi:display_frame_draw::@8->display_frame]
    // [2583] phi display_frame::y#0 = 2 [phi:display_frame_draw::@8->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2583] phi display_frame::y1#16 = $e [phi:display_frame_draw::@8->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2583] phi display_frame::x#0 = $13 [phi:display_frame_draw::@8->display_frame#2] -- vbuz1=vbuc1 
    lda #$13
    sta.z display_frame.x
    // [2583] phi display_frame::x1#16 = $19 [phi:display_frame_draw::@8->display_frame#3] -- vbum1=vbuc1 
    lda #$19
    sta display_frame.x1
    jsr display_frame
    // [1938] phi from display_frame_draw::@8 to display_frame_draw::@9 [phi:display_frame_draw::@8->display_frame_draw::@9]
    // display_frame_draw::@9
    // display_frame(25, 2, 31, 14)
    // [1939] call display_frame
    // [2583] phi from display_frame_draw::@9 to display_frame [phi:display_frame_draw::@9->display_frame]
    // [2583] phi display_frame::y#0 = 2 [phi:display_frame_draw::@9->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2583] phi display_frame::y1#16 = $e [phi:display_frame_draw::@9->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2583] phi display_frame::x#0 = $19 [phi:display_frame_draw::@9->display_frame#2] -- vbuz1=vbuc1 
    lda #$19
    sta.z display_frame.x
    // [2583] phi display_frame::x1#16 = $1f [phi:display_frame_draw::@9->display_frame#3] -- vbum1=vbuc1 
    lda #$1f
    sta display_frame.x1
    jsr display_frame
    // [1940] phi from display_frame_draw::@9 to display_frame_draw::@10 [phi:display_frame_draw::@9->display_frame_draw::@10]
    // display_frame_draw::@10
    // display_frame(31, 2, 37, 14)
    // [1941] call display_frame
    // [2583] phi from display_frame_draw::@10 to display_frame [phi:display_frame_draw::@10->display_frame]
    // [2583] phi display_frame::y#0 = 2 [phi:display_frame_draw::@10->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2583] phi display_frame::y1#16 = $e [phi:display_frame_draw::@10->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2583] phi display_frame::x#0 = $1f [phi:display_frame_draw::@10->display_frame#2] -- vbuz1=vbuc1 
    lda #$1f
    sta.z display_frame.x
    // [2583] phi display_frame::x1#16 = $25 [phi:display_frame_draw::@10->display_frame#3] -- vbum1=vbuc1 
    lda #$25
    sta display_frame.x1
    jsr display_frame
    // [1942] phi from display_frame_draw::@10 to display_frame_draw::@11 [phi:display_frame_draw::@10->display_frame_draw::@11]
    // display_frame_draw::@11
    // display_frame(37, 2, 43, 14)
    // [1943] call display_frame
    // [2583] phi from display_frame_draw::@11 to display_frame [phi:display_frame_draw::@11->display_frame]
    // [2583] phi display_frame::y#0 = 2 [phi:display_frame_draw::@11->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2583] phi display_frame::y1#16 = $e [phi:display_frame_draw::@11->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2583] phi display_frame::x#0 = $25 [phi:display_frame_draw::@11->display_frame#2] -- vbuz1=vbuc1 
    lda #$25
    sta.z display_frame.x
    // [2583] phi display_frame::x1#16 = $2b [phi:display_frame_draw::@11->display_frame#3] -- vbum1=vbuc1 
    lda #$2b
    sta display_frame.x1
    jsr display_frame
    // [1944] phi from display_frame_draw::@11 to display_frame_draw::@12 [phi:display_frame_draw::@11->display_frame_draw::@12]
    // display_frame_draw::@12
    // display_frame(43, 2, 49, 14)
    // [1945] call display_frame
    // [2583] phi from display_frame_draw::@12 to display_frame [phi:display_frame_draw::@12->display_frame]
    // [2583] phi display_frame::y#0 = 2 [phi:display_frame_draw::@12->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2583] phi display_frame::y1#16 = $e [phi:display_frame_draw::@12->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2583] phi display_frame::x#0 = $2b [phi:display_frame_draw::@12->display_frame#2] -- vbuz1=vbuc1 
    lda #$2b
    sta.z display_frame.x
    // [2583] phi display_frame::x1#16 = $31 [phi:display_frame_draw::@12->display_frame#3] -- vbum1=vbuc1 
    lda #$31
    sta display_frame.x1
    jsr display_frame
    // [1946] phi from display_frame_draw::@12 to display_frame_draw::@13 [phi:display_frame_draw::@12->display_frame_draw::@13]
    // display_frame_draw::@13
    // display_frame(49, 2, 55, 14)
    // [1947] call display_frame
    // [2583] phi from display_frame_draw::@13 to display_frame [phi:display_frame_draw::@13->display_frame]
    // [2583] phi display_frame::y#0 = 2 [phi:display_frame_draw::@13->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2583] phi display_frame::y1#16 = $e [phi:display_frame_draw::@13->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2583] phi display_frame::x#0 = $31 [phi:display_frame_draw::@13->display_frame#2] -- vbuz1=vbuc1 
    lda #$31
    sta.z display_frame.x
    // [2583] phi display_frame::x1#16 = $37 [phi:display_frame_draw::@13->display_frame#3] -- vbum1=vbuc1 
    lda #$37
    sta display_frame.x1
    jsr display_frame
    // [1948] phi from display_frame_draw::@13 to display_frame_draw::@14 [phi:display_frame_draw::@13->display_frame_draw::@14]
    // display_frame_draw::@14
    // display_frame(55, 2, 61, 14)
    // [1949] call display_frame
    // [2583] phi from display_frame_draw::@14 to display_frame [phi:display_frame_draw::@14->display_frame]
    // [2583] phi display_frame::y#0 = 2 [phi:display_frame_draw::@14->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2583] phi display_frame::y1#16 = $e [phi:display_frame_draw::@14->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2583] phi display_frame::x#0 = $37 [phi:display_frame_draw::@14->display_frame#2] -- vbuz1=vbuc1 
    lda #$37
    sta.z display_frame.x
    // [2583] phi display_frame::x1#16 = $3d [phi:display_frame_draw::@14->display_frame#3] -- vbum1=vbuc1 
    lda #$3d
    sta display_frame.x1
    jsr display_frame
    // [1950] phi from display_frame_draw::@14 to display_frame_draw::@15 [phi:display_frame_draw::@14->display_frame_draw::@15]
    // display_frame_draw::@15
    // display_frame(61, 2, 67, 14)
    // [1951] call display_frame
    // [2583] phi from display_frame_draw::@15 to display_frame [phi:display_frame_draw::@15->display_frame]
    // [2583] phi display_frame::y#0 = 2 [phi:display_frame_draw::@15->display_frame#0] -- vbum1=vbuc1 
    lda #2
    sta display_frame.y
    // [2583] phi display_frame::y1#16 = $e [phi:display_frame_draw::@15->display_frame#1] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y1
    // [2583] phi display_frame::x#0 = $3d [phi:display_frame_draw::@15->display_frame#2] -- vbuz1=vbuc1 
    lda #$3d
    sta.z display_frame.x
    // [2583] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@15->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [1952] phi from display_frame_draw::@15 to display_frame_draw::@16 [phi:display_frame_draw::@15->display_frame_draw::@16]
    // display_frame_draw::@16
    // display_frame(0, 14, 67, PROGRESS_Y-5)
    // [1953] call display_frame
  // Progress area
    // [2583] phi from display_frame_draw::@16 to display_frame [phi:display_frame_draw::@16->display_frame]
    // [2583] phi display_frame::y#0 = $e [phi:display_frame_draw::@16->display_frame#0] -- vbum1=vbuc1 
    lda #$e
    sta display_frame.y
    // [2583] phi display_frame::y1#16 = PROGRESS_Y-5 [phi:display_frame_draw::@16->display_frame#1] -- vbum1=vbuc1 
    lda #PROGRESS_Y-5
    sta display_frame.y1
    // [2583] phi display_frame::x#0 = 0 [phi:display_frame_draw::@16->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [2583] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@16->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [1954] phi from display_frame_draw::@16 to display_frame_draw::@17 [phi:display_frame_draw::@16->display_frame_draw::@17]
    // display_frame_draw::@17
    // display_frame(0, PROGRESS_Y-5, 67, PROGRESS_Y-2)
    // [1955] call display_frame
    // [2583] phi from display_frame_draw::@17 to display_frame [phi:display_frame_draw::@17->display_frame]
    // [2583] phi display_frame::y#0 = PROGRESS_Y-5 [phi:display_frame_draw::@17->display_frame#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-5
    sta display_frame.y
    // [2583] phi display_frame::y1#16 = PROGRESS_Y-2 [phi:display_frame_draw::@17->display_frame#1] -- vbum1=vbuc1 
    lda #PROGRESS_Y-2
    sta display_frame.y1
    // [2583] phi display_frame::x#0 = 0 [phi:display_frame_draw::@17->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [2583] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@17->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [1956] phi from display_frame_draw::@17 to display_frame_draw::@18 [phi:display_frame_draw::@17->display_frame_draw::@18]
    // display_frame_draw::@18
    // display_frame(0, PROGRESS_Y-2, 67, 49)
    // [1957] call display_frame
    // [2583] phi from display_frame_draw::@18 to display_frame [phi:display_frame_draw::@18->display_frame]
    // [2583] phi display_frame::y#0 = PROGRESS_Y-2 [phi:display_frame_draw::@18->display_frame#0] -- vbum1=vbuc1 
    lda #PROGRESS_Y-2
    sta display_frame.y
    // [2583] phi display_frame::y1#16 = $31 [phi:display_frame_draw::@18->display_frame#1] -- vbum1=vbuc1 
    lda #$31
    sta display_frame.y1
    // [2583] phi display_frame::x#0 = 0 [phi:display_frame_draw::@18->display_frame#2] -- vbuz1=vbuc1 
    lda #0
    sta.z display_frame.x
    // [2583] phi display_frame::x1#16 = $43 [phi:display_frame_draw::@18->display_frame#3] -- vbum1=vbuc1 
    lda #$43
    sta display_frame.x1
    jsr display_frame
    // [1958] phi from display_frame_draw::@18 to display_frame_draw::@19 [phi:display_frame_draw::@18->display_frame_draw::@19]
    // display_frame_draw::@19
    // textcolor(WHITE)
    // [1959] call textcolor
    // [760] phi from display_frame_draw::@19 to textcolor [phi:display_frame_draw::@19->textcolor]
    // [760] phi textcolor::color#23 = WHITE [phi:display_frame_draw::@19->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // display_frame_draw::@return
    // }
    // [1960] return 
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
    // [1962] call gotoxy
    // [778] phi from display_frame_title to gotoxy [phi:display_frame_title->gotoxy]
    // [778] phi gotoxy::y#33 = 1 [phi:display_frame_title->gotoxy#0] -- vbum1=vbuc1 
    lda #1
    sta gotoxy.y
    // [778] phi gotoxy::x#33 = 2 [phi:display_frame_title->gotoxy#1] -- vbum1=vbuc1 
    lda #2
    sta gotoxy.x
    jsr gotoxy
    // [1963] phi from display_frame_title to display_frame_title::@1 [phi:display_frame_title->display_frame_title::@1]
    // display_frame_title::@1
    // printf("%-65s", title_text)
    // [1964] call printf_string
    // [1227] phi from display_frame_title::@1 to printf_string [phi:display_frame_title::@1->printf_string]
    // [1227] phi printf_string::putc#25 = &cputc [phi:display_frame_title::@1->printf_string#0] -- pprz1=pprc1 
    lda #<cputc
    sta.z printf_string.putc
    lda #>cputc
    sta.z printf_string.putc+1
    // [1227] phi printf_string::str#25 = init::title_text [phi:display_frame_title::@1->printf_string#1] -- pbuz1=pbuc1 
    lda #<init.title_text
    sta.z printf_string.str
    lda #>init.title_text
    sta.z printf_string.str+1
    // [1227] phi printf_string::format_justify_left#25 = 1 [phi:display_frame_title::@1->printf_string#2] -- vbum1=vbuc1 
    lda #1
    sta printf_string.format_justify_left
    // [1227] phi printf_string::format_min_length#25 = $41 [phi:display_frame_title::@1->printf_string#3] -- vbum1=vbuc1 
    lda #$41
    sta printf_string.format_min_length
    jsr printf_string
    // display_frame_title::@return
    // }
    // [1965] return 
    rts
}
  // cputsxy
// Move cursor and output a NUL-terminated string
// Same as "gotoxy (x, y); puts (s);"
// void cputsxy(__mem() char x, __mem() char y, __zp($b8) const char *s)
cputsxy: {
    .label s = $b8
    // gotoxy(x, y)
    // [1967] gotoxy::x#1 = cputsxy::x#4 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [1968] gotoxy::y#1 = cputsxy::y#4 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [1969] call gotoxy
    // [778] phi from cputsxy to gotoxy [phi:cputsxy->gotoxy]
    // [778] phi gotoxy::y#33 = gotoxy::y#1 [phi:cputsxy->gotoxy#0] -- register_copy 
    // [778] phi gotoxy::x#33 = gotoxy::x#1 [phi:cputsxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputsxy::@1
    // cputs(s)
    // [1970] cputs::s#1 = cputsxy::s#4 -- pbuz1=pbuz2 
    lda.z s
    sta.z cputs.s
    lda.z s+1
    sta.z cputs.s+1
    // [1971] call cputs
    // [2717] phi from cputsxy::@1 to cputs [phi:cputsxy::@1->cputs]
    jsr cputs
    // cputsxy::@return
    // }
    // [1972] return 
    rts
  .segment Data
    y: .byte 0
    x: .byte 0
}
.segment Code
  // display_chip_vera
display_chip_vera: {
    // display_vera_led(GREY)
    // [1974] call display_vera_led
    // [2500] phi from display_chip_vera to display_vera_led [phi:display_chip_vera->display_vera_led]
    // [2500] phi display_vera_led::c#2 = GREY [phi:display_chip_vera->display_vera_led#0] -- vbum1=vbuc1 
    lda #GREY
    sta display_vera_led.c
    jsr display_vera_led
    // [1975] phi from display_chip_vera to display_chip_vera::@1 [phi:display_chip_vera->display_chip_vera::@1]
    // display_chip_vera::@1
    // display_print_chip(CHIP_VERA_X, CHIP_VERA_Y+2, CHIP_VERA_W, "VERA     ")
    // [1976] call display_print_chip
    // [1995] phi from display_chip_vera::@1 to display_print_chip [phi:display_chip_vera::@1->display_print_chip]
    // [1995] phi display_print_chip::text#11 = display_chip_vera::text [phi:display_chip_vera::@1->display_print_chip#0] -- pbuz1=pbuc1 
    lda #<text
    sta.z display_print_chip.text_2
    lda #>text
    sta.z display_print_chip.text_2+1
    // [1995] phi display_print_chip::w#10 = 8 [phi:display_chip_vera::@1->display_print_chip#1] -- vbum1=vbuc1 
    lda #8
    sta display_print_chip.w
    // [1995] phi display_print_chip::x#10 = 9 [phi:display_chip_vera::@1->display_print_chip#2] -- vbuz1=vbuc1 
    lda #9
    sta.z display_print_chip.x
    jsr display_print_chip
    // display_chip_vera::@return
    // }
    // [1977] return 
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
// void display_info_led(__zp($cd) char x, __zp($c9) char y, __zp($c0) char tc, char bc)
display_info_led: {
    .label tc = $c0
    .label y = $c9
    .label x = $cd
    // textcolor(tc)
    // [1979] textcolor::color#13 = display_info_led::tc#4 -- vbum1=vbuz2 
    lda.z tc
    sta textcolor.color
    // [1980] call textcolor
    // [760] phi from display_info_led to textcolor [phi:display_info_led->textcolor]
    // [760] phi textcolor::color#23 = textcolor::color#13 [phi:display_info_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [1981] phi from display_info_led to display_info_led::@1 [phi:display_info_led->display_info_led::@1]
    // display_info_led::@1
    // bgcolor(bc)
    // [1982] call bgcolor
    // [765] phi from display_info_led::@1 to bgcolor [phi:display_info_led::@1->bgcolor]
    // [765] phi bgcolor::color#15 = BLUE [phi:display_info_led::@1->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_info_led::@2
    // cputcxy(x, y, VERA_CHR_UR)
    // [1983] cputcxy::x#11 = display_info_led::x#4 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [1984] cputcxy::y#11 = display_info_led::y#4 -- vbum1=vbuz2 
    lda.z y
    sta cputcxy.y
    // [1985] call cputcxy
    // [2147] phi from display_info_led::@2 to cputcxy [phi:display_info_led::@2->cputcxy]
    // [2147] phi cputcxy::c#15 = $7c [phi:display_info_led::@2->cputcxy#0] -- vbum1=vbuc1 
    lda #$7c
    sta cputcxy.c
    // [2147] phi cputcxy::y#15 = cputcxy::y#11 [phi:display_info_led::@2->cputcxy#1] -- register_copy 
    // [2147] phi cputcxy::x#15 = cputcxy::x#11 [phi:display_info_led::@2->cputcxy#2] -- register_copy 
    jsr cputcxy
    // [1986] phi from display_info_led::@2 to display_info_led::@3 [phi:display_info_led::@2->display_info_led::@3]
    // display_info_led::@3
    // textcolor(WHITE)
    // [1987] call textcolor
    // [760] phi from display_info_led::@3 to textcolor [phi:display_info_led::@3->textcolor]
    // [760] phi textcolor::color#23 = WHITE [phi:display_info_led::@3->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // display_info_led::@return
    // }
    // [1988] return 
    rts
}
  // display_smc_led
/**
 * @brief Print SMC led above the SMC chip.
 * 
 * @param c Led color
 */
// void display_smc_led(__zp($c0) char c)
display_smc_led: {
    .label c = $c0
    // display_chip_led(CHIP_SMC_X+1, CHIP_SMC_Y, CHIP_SMC_W, c, BLUE)
    // [1990] display_chip_led::tc#0 = display_smc_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_chip_led.tc
    // [1991] call display_chip_led
    // [2726] phi from display_smc_led to display_chip_led [phi:display_smc_led->display_chip_led]
    // [2726] phi display_chip_led::w#7 = 5 [phi:display_smc_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #5
    sta.z display_chip_led.w
    // [2726] phi display_chip_led::x#7 = 1+1 [phi:display_smc_led->display_chip_led#1] -- vbuz1=vbuc1 
    lda #1+1
    sta.z display_chip_led.x
    // [2726] phi display_chip_led::tc#3 = display_chip_led::tc#0 [phi:display_smc_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_smc_led::@1
    // display_info_led(INFO_X-2, INFO_Y, c, BLUE)
    // [1992] display_info_led::tc#0 = display_smc_led::c#2
    // [1993] call display_info_led
    // [1978] phi from display_smc_led::@1 to display_info_led [phi:display_smc_led::@1->display_info_led]
    // [1978] phi display_info_led::y#4 = $11 [phi:display_smc_led::@1->display_info_led#0] -- vbuz1=vbuc1 
    lda #$11
    sta.z display_info_led.y
    // [1978] phi display_info_led::x#4 = 4-2 [phi:display_smc_led::@1->display_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z display_info_led.x
    // [1978] phi display_info_led::tc#4 = display_info_led::tc#0 [phi:display_smc_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_smc_led::@return
    // }
    // [1994] return 
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
// void display_print_chip(__zp($cc) char x, char y, __mem() char w, __zp($47) char *text)
display_print_chip: {
    .label y = 3+2+1+1+1+1+1+1+1+1
    .label text = $47
    .label text_1 = $31
    .label x = $cc
    .label text_2 = $b4
    .label text_3 = $aa
    .label text_4 = $3f
    // display_chip_line(x, y++, w, *text++)
    // [1996] display_chip_line::x#0 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [1997] display_chip_line::w#0 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_line.w
    // [1998] display_chip_line::c#0 = *display_print_chip::text#11 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_2),y
    sta.z display_chip_line.c
    // [1999] call display_chip_line
    // [2744] phi from display_print_chip to display_chip_line [phi:display_print_chip->display_chip_line]
    // [2744] phi display_chip_line::c#15 = display_chip_line::c#0 [phi:display_print_chip->display_chip_line#0] -- register_copy 
    // [2744] phi display_chip_line::w#10 = display_chip_line::w#0 [phi:display_print_chip->display_chip_line#1] -- register_copy 
    // [2744] phi display_chip_line::y#16 = 3+2 [phi:display_print_chip->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2
    sta display_chip_line.y
    // [2744] phi display_chip_line::x#16 = display_chip_line::x#0 [phi:display_print_chip->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@1
    // display_chip_line(x, y++, w, *text++);
    // [2000] display_print_chip::text#0 = ++ display_print_chip::text#11 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_2
    adc #1
    sta.z text
    lda.z text_2+1
    adc #0
    sta.z text+1
    // display_chip_line(x, y++, w, *text++)
    // [2001] display_chip_line::x#1 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [2002] display_chip_line::w#1 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_line.w
    // [2003] display_chip_line::c#1 = *display_print_chip::text#0 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text),y
    sta.z display_chip_line.c
    // [2004] call display_chip_line
    // [2744] phi from display_print_chip::@1 to display_chip_line [phi:display_print_chip::@1->display_chip_line]
    // [2744] phi display_chip_line::c#15 = display_chip_line::c#1 [phi:display_print_chip::@1->display_chip_line#0] -- register_copy 
    // [2744] phi display_chip_line::w#10 = display_chip_line::w#1 [phi:display_print_chip::@1->display_chip_line#1] -- register_copy 
    // [2744] phi display_chip_line::y#16 = ++3+2 [phi:display_print_chip::@1->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1
    sta display_chip_line.y
    // [2744] phi display_chip_line::x#16 = display_chip_line::x#1 [phi:display_print_chip::@1->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@2
    // display_chip_line(x, y++, w, *text++);
    // [2005] display_print_chip::text#1 = ++ display_print_chip::text#0 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text
    adc #1
    sta.z text_1
    lda.z text+1
    adc #0
    sta.z text_1+1
    // display_chip_line(x, y++, w, *text++)
    // [2006] display_chip_line::x#2 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [2007] display_chip_line::w#2 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_line.w
    // [2008] display_chip_line::c#2 = *display_print_chip::text#1 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_1),y
    sta.z display_chip_line.c
    // [2009] call display_chip_line
    // [2744] phi from display_print_chip::@2 to display_chip_line [phi:display_print_chip::@2->display_chip_line]
    // [2744] phi display_chip_line::c#15 = display_chip_line::c#2 [phi:display_print_chip::@2->display_chip_line#0] -- register_copy 
    // [2744] phi display_chip_line::w#10 = display_chip_line::w#2 [phi:display_print_chip::@2->display_chip_line#1] -- register_copy 
    // [2744] phi display_chip_line::y#16 = ++++3+2 [phi:display_print_chip::@2->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1
    sta display_chip_line.y
    // [2744] phi display_chip_line::x#16 = display_chip_line::x#2 [phi:display_print_chip::@2->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@3
    // display_chip_line(x, y++, w, *text++);
    // [2010] display_print_chip::text#15 = ++ display_print_chip::text#1 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_1
    adc #1
    sta.z text_3
    lda.z text_1+1
    adc #0
    sta.z text_3+1
    // display_chip_line(x, y++, w, *text++)
    // [2011] display_chip_line::x#3 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [2012] display_chip_line::w#3 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_line.w
    // [2013] display_chip_line::c#3 = *display_print_chip::text#15 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_3),y
    sta.z display_chip_line.c
    // [2014] call display_chip_line
    // [2744] phi from display_print_chip::@3 to display_chip_line [phi:display_print_chip::@3->display_chip_line]
    // [2744] phi display_chip_line::c#15 = display_chip_line::c#3 [phi:display_print_chip::@3->display_chip_line#0] -- register_copy 
    // [2744] phi display_chip_line::w#10 = display_chip_line::w#3 [phi:display_print_chip::@3->display_chip_line#1] -- register_copy 
    // [2744] phi display_chip_line::y#16 = ++++++3+2 [phi:display_print_chip::@3->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1
    sta display_chip_line.y
    // [2744] phi display_chip_line::x#16 = display_chip_line::x#3 [phi:display_print_chip::@3->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@4
    // display_chip_line(x, y++, w, *text++);
    // [2015] display_print_chip::text#16 = ++ display_print_chip::text#15 -- pbuz1=_inc_pbuz2 
    clc
    lda.z text_3
    adc #1
    sta.z text_4
    lda.z text_3+1
    adc #0
    sta.z text_4+1
    // display_chip_line(x, y++, w, *text++)
    // [2016] display_chip_line::x#4 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [2017] display_chip_line::w#4 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_line.w
    // [2018] display_chip_line::c#4 = *display_print_chip::text#16 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (text_4),y
    sta.z display_chip_line.c
    // [2019] call display_chip_line
    // [2744] phi from display_print_chip::@4 to display_chip_line [phi:display_print_chip::@4->display_chip_line]
    // [2744] phi display_chip_line::c#15 = display_chip_line::c#4 [phi:display_print_chip::@4->display_chip_line#0] -- register_copy 
    // [2744] phi display_chip_line::w#10 = display_chip_line::w#4 [phi:display_print_chip::@4->display_chip_line#1] -- register_copy 
    // [2744] phi display_chip_line::y#16 = ++++++++3+2 [phi:display_print_chip::@4->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1
    sta display_chip_line.y
    // [2744] phi display_chip_line::x#16 = display_chip_line::x#4 [phi:display_print_chip::@4->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@5
    // display_chip_line(x, y++, w, *text++);
    // [2020] display_print_chip::text#17 = ++ display_print_chip::text#16 -- pbum1=_inc_pbuz2 
    clc
    lda.z text_4
    adc #1
    sta text_5
    lda.z text_4+1
    adc #0
    sta text_5+1
    // display_chip_line(x, y++, w, *text++)
    // [2021] display_chip_line::x#5 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [2022] display_chip_line::w#5 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_line.w
    // [2023] display_chip_line::c#5 = *display_print_chip::text#17 -- vbuz1=_deref_pbum2 
    ldy text_5
    sty.z $fe
    ldy text_5+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta.z display_chip_line.c
    // [2024] call display_chip_line
    // [2744] phi from display_print_chip::@5 to display_chip_line [phi:display_print_chip::@5->display_chip_line]
    // [2744] phi display_chip_line::c#15 = display_chip_line::c#5 [phi:display_print_chip::@5->display_chip_line#0] -- register_copy 
    // [2744] phi display_chip_line::w#10 = display_chip_line::w#5 [phi:display_print_chip::@5->display_chip_line#1] -- register_copy 
    // [2744] phi display_chip_line::y#16 = ++++++++++3+2 [phi:display_print_chip::@5->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1+1
    sta display_chip_line.y
    // [2744] phi display_chip_line::x#16 = display_chip_line::x#5 [phi:display_print_chip::@5->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@6
    // display_chip_line(x, y++, w, *text++);
    // [2025] display_print_chip::text#18 = ++ display_print_chip::text#17 -- pbum1=_inc_pbum2 
    clc
    lda text_5
    adc #1
    sta text_6
    lda text_5+1
    adc #0
    sta text_6+1
    // display_chip_line(x, y++, w, *text++)
    // [2026] display_chip_line::x#6 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [2027] display_chip_line::w#6 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_line.w
    // [2028] display_chip_line::c#6 = *display_print_chip::text#18 -- vbuz1=_deref_pbum2 
    ldy text_6
    sty.z $fe
    ldy text_6+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta.z display_chip_line.c
    // [2029] call display_chip_line
    // [2744] phi from display_print_chip::@6 to display_chip_line [phi:display_print_chip::@6->display_chip_line]
    // [2744] phi display_chip_line::c#15 = display_chip_line::c#6 [phi:display_print_chip::@6->display_chip_line#0] -- register_copy 
    // [2744] phi display_chip_line::w#10 = display_chip_line::w#6 [phi:display_print_chip::@6->display_chip_line#1] -- register_copy 
    // [2744] phi display_chip_line::y#16 = ++++++++++++3+2 [phi:display_print_chip::@6->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1+1+1
    sta display_chip_line.y
    // [2744] phi display_chip_line::x#16 = display_chip_line::x#6 [phi:display_print_chip::@6->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@7
    // display_chip_line(x, y++, w, *text++);
    // [2030] display_print_chip::text#19 = ++ display_print_chip::text#18 -- pbum1=_inc_pbum1 
    inc text_6
    bne !+
    inc text_6+1
  !:
    // display_chip_line(x, y++, w, *text++)
    // [2031] display_chip_line::x#7 = display_print_chip::x#10 -- vbuz1=vbuz2 
    lda.z x
    sta.z display_chip_line.x
    // [2032] display_chip_line::w#7 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_line.w
    // [2033] display_chip_line::c#7 = *display_print_chip::text#19 -- vbuz1=_deref_pbum2 
    ldy text_6
    sty.z $fe
    ldy text_6+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta.z display_chip_line.c
    // [2034] call display_chip_line
    // [2744] phi from display_print_chip::@7 to display_chip_line [phi:display_print_chip::@7->display_chip_line]
    // [2744] phi display_chip_line::c#15 = display_chip_line::c#7 [phi:display_print_chip::@7->display_chip_line#0] -- register_copy 
    // [2744] phi display_chip_line::w#10 = display_chip_line::w#7 [phi:display_print_chip::@7->display_chip_line#1] -- register_copy 
    // [2744] phi display_chip_line::y#16 = ++++++++++++++3+2 [phi:display_print_chip::@7->display_chip_line#2] -- vbum1=vbuc1 
    lda #3+2+1+1+1+1+1+1+1
    sta display_chip_line.y
    // [2744] phi display_chip_line::x#16 = display_chip_line::x#7 [phi:display_print_chip::@7->display_chip_line#3] -- register_copy 
    jsr display_chip_line
    // display_print_chip::@8
    // display_chip_end(x, y++, w)
    // [2035] display_chip_end::x#0 = display_print_chip::x#10
    // [2036] display_chip_end::w#0 = display_print_chip::w#10 -- vbuz1=vbum2 
    lda w
    sta.z display_chip_end.w
    // [2037] call display_chip_end
    jsr display_chip_end
    // display_print_chip::@return
    // }
    // [2038] return 
    rts
  .segment Data
    .label text_5 = fopen.cbm_k_setnam1_fopen__0
    .label text_6 = fopen.fopen__16
    .label w = main.check_status_smc6_main__0
}
.segment Code
  // wherex
// Return the x position of the cursor
wherex: {
    // return __conio.cursor_x;
    // [2039] wherex::return#0 = *((char *)&__conio) -- vbum1=_deref_pbuc1 
    lda __conio
    sta return
    // wherex::@return
    // }
    // [2040] return 
    rts
  .segment Data
    return: .byte 0
}
.segment Code
  // wherey
// Return the y position of the cursor
wherey: {
    // return __conio.cursor_y;
    // [2041] wherey::return#0 = *((char *)&__conio+1) -- vbum1=_deref_pbuc1 
    lda __conio+1
    sta return
    // wherey::@return
    // }
    // [2042] return 
    rts
  .segment Data
    return: .byte 0
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
// void rom_unlock(__zp($5a) unsigned long address, __zp($6a) char unlock_code)
rom_unlock: {
    .label chip_address = $52
    .label address = $5a
    .label unlock_code = $6a
    // unsigned long chip_address = address & ROM_CHIP_MASK
    // [2044] rom_unlock::chip_address#0 = rom_unlock::address#5 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [2045] rom_write_byte::address#0 = rom_unlock::chip_address#0 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [2046] call rom_write_byte
  // This is a very important operation...
    // [2805] phi from rom_unlock to rom_write_byte [phi:rom_unlock->rom_write_byte]
    // [2805] phi rom_write_byte::value#10 = $aa [phi:rom_unlock->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$aa
    sta.z rom_write_byte.value
    // [2805] phi rom_write_byte::address#4 = rom_write_byte::address#0 [phi:rom_unlock->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@1
    // rom_write_byte(chip_address + 0x02AAA, 0x55)
    // [2047] rom_write_byte::address#1 = rom_unlock::chip_address#0 + $2aaa -- vduz1=vduz2_plus_vwuc1 
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
    // [2048] call rom_write_byte
    // [2805] phi from rom_unlock::@1 to rom_write_byte [phi:rom_unlock::@1->rom_write_byte]
    // [2805] phi rom_write_byte::value#10 = $55 [phi:rom_unlock::@1->rom_write_byte#0] -- vbuz1=vbuc1 
    lda #$55
    sta.z rom_write_byte.value
    // [2805] phi rom_write_byte::address#4 = rom_write_byte::address#1 [phi:rom_unlock::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@2
    // rom_write_byte(address, unlock_code)
    // [2049] rom_write_byte::address#2 = rom_unlock::address#5 -- vduz1=vduz2 
    lda.z address
    sta.z rom_write_byte.address
    lda.z address+1
    sta.z rom_write_byte.address+1
    lda.z address+2
    sta.z rom_write_byte.address+2
    lda.z address+3
    sta.z rom_write_byte.address+3
    // [2050] rom_write_byte::value#2 = rom_unlock::unlock_code#5 -- vbuz1=vbuz2 
    lda.z unlock_code
    sta.z rom_write_byte.value
    // [2051] call rom_write_byte
    // [2805] phi from rom_unlock::@2 to rom_write_byte [phi:rom_unlock::@2->rom_write_byte]
    // [2805] phi rom_write_byte::value#10 = rom_write_byte::value#2 [phi:rom_unlock::@2->rom_write_byte#0] -- register_copy 
    // [2805] phi rom_write_byte::address#4 = rom_write_byte::address#2 [phi:rom_unlock::@2->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_unlock::@return
    // }
    // [2052] return 
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
// __mem() char rom_read_byte(__mem() unsigned long address)
rom_read_byte: {
    .label rom_bank1_rom_read_byte__0 = $45
    .label rom_bank1_return = $bc
    // rom_read_byte::rom_bank1
    // BYTE2(address)
    // [2054] rom_read_byte::rom_bank1_$0 = byte2  rom_read_byte::address#2 -- vbuz1=_byte2_vdum2 
    lda address+2
    sta.z rom_bank1_rom_read_byte__0
    // BYTE1(address)
    // [2055] rom_read_byte::rom_bank1_$1 = byte1  rom_read_byte::address#2 -- vbum1=_byte1_vdum2 
    lda address+1
    sta rom_bank1_rom_read_byte__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2056] rom_read_byte::rom_bank1_$2 = rom_read_byte::rom_bank1_$0 w= rom_read_byte::rom_bank1_$1 -- vwum1=vbuz2_word_vbum3 
    lda.z rom_bank1_rom_read_byte__0
    sta rom_bank1_rom_read_byte__2+1
    lda rom_bank1_rom_read_byte__1
    sta rom_bank1_rom_read_byte__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2057] rom_read_byte::rom_bank1_bank_unshifted#0 = rom_read_byte::rom_bank1_$2 << 2 -- vwum1=vwum1_rol_2 
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    asl rom_bank1_bank_unshifted
    rol rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2058] rom_read_byte::rom_bank1_return#0 = byte1  rom_read_byte::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwum2 
    lda rom_bank1_bank_unshifted+1
    sta.z rom_bank1_return
    // rom_read_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2059] rom_read_byte::rom_ptr1_$2 = (unsigned int)rom_read_byte::address#2 -- vwum1=_word_vdum2 
    lda address
    sta rom_ptr1_rom_read_byte__2
    lda address+1
    sta rom_ptr1_rom_read_byte__2+1
    // [2060] rom_read_byte::rom_ptr1_$0 = rom_read_byte::rom_ptr1_$2 & $3fff -- vwum1=vwum1_band_vwuc1 
    lda rom_ptr1_rom_read_byte__0
    and #<$3fff
    sta rom_ptr1_rom_read_byte__0
    lda rom_ptr1_rom_read_byte__0+1
    and #>$3fff
    sta rom_ptr1_rom_read_byte__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2061] rom_read_byte::rom_ptr1_return#0 = rom_read_byte::rom_ptr1_$0 + $c000 -- vwum1=vwum1_plus_vwuc1 
    lda rom_ptr1_return
    clc
    adc #<$c000
    sta rom_ptr1_return
    lda rom_ptr1_return+1
    adc #>$c000
    sta rom_ptr1_return+1
    // rom_read_byte::bank_set_brom1
    // BROM = bank
    // [2062] BROM = rom_read_byte::rom_bank1_return#0 -- vbuz1=vbuz2 
    lda.z rom_bank1_return
    sta.z BROM
    // rom_read_byte::@1
    // return *ptr_rom;
    // [2063] rom_read_byte::return#0 = *((char *)rom_read_byte::rom_ptr1_return#0) -- vbum1=_deref_pbum2 
    ldy rom_ptr1_return
    sty.z $fe
    ldy rom_ptr1_return+1
    sty.z $ff
    ldy #0
    lda ($fe),y
    sta return
    // rom_read_byte::@return
    // }
    // [2064] return 
    rts
  .segment Data
    .label rom_bank1_rom_read_byte__1 = fopen.fopen__4
    rom_bank1_rom_read_byte__2: .word 0
    .label rom_ptr1_rom_read_byte__0 = rom_ptr1_rom_read_byte__2
    rom_ptr1_rom_read_byte__2: .word 0
    .label rom_bank1_bank_unshifted = rom_bank1_rom_read_byte__2
    .label rom_ptr1_return = rom_ptr1_rom_read_byte__2
    .label return = fclose.fclose__1
    address: .dword 0
}
.segment Code
  // strcat
// Concatenates the C string pointed by source into the array pointed by destination, including the terminating null character (and stopping at that point).
// char * strcat(char *destination, __zp($b4) char *source)
strcat: {
    .label strcat__0 = $4e
    .label dst = $4e
    .label src = $b4
    .label source = $b4
    // strlen(destination)
    // [2066] call strlen
    // [2155] phi from strcat to strlen [phi:strcat->strlen]
    // [2155] phi strlen::str#8 = display_chip_rom::rom [phi:strcat->strlen#0] -- pbuz1=pbuc1 
    lda #<display_chip_rom.rom
    sta.z strlen.str
    lda #>display_chip_rom.rom
    sta.z strlen.str+1
    jsr strlen
    // strlen(destination)
    // [2067] strlen::return#0 = strlen::len#2
    // strcat::@4
    // [2068] strcat::$0 = strlen::return#0 -- vwuz1=vwum2 
    lda strlen.return
    sta.z strcat__0
    lda strlen.return+1
    sta.z strcat__0+1
    // char* dst = destination + strlen(destination)
    // [2069] strcat::dst#0 = display_chip_rom::rom + strcat::$0 -- pbuz1=pbuc1_plus_vwuz1 
    lda.z dst
    clc
    adc #<display_chip_rom.rom
    sta.z dst
    lda.z dst+1
    adc #>display_chip_rom.rom
    sta.z dst+1
    // [2070] phi from strcat::@2 strcat::@4 to strcat::@1 [phi:strcat::@2/strcat::@4->strcat::@1]
    // [2070] phi strcat::dst#2 = strcat::dst#1 [phi:strcat::@2/strcat::@4->strcat::@1#0] -- register_copy 
    // [2070] phi strcat::src#2 = strcat::src#1 [phi:strcat::@2/strcat::@4->strcat::@1#1] -- register_copy 
    // strcat::@1
  __b1:
    // while(*src)
    // [2071] if(0!=*strcat::src#2) goto strcat::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (src),y
    cmp #0
    bne __b2
    // strcat::@3
    // *dst = 0
    // [2072] *strcat::dst#2 = 0 -- _deref_pbuz1=vbuc1 
    tya
    tay
    sta (dst),y
    // strcat::@return
    // }
    // [2073] return 
    rts
    // strcat::@2
  __b2:
    // *dst++ = *src++
    // [2074] *strcat::dst#2 = *strcat::src#2 -- _deref_pbuz1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta (dst),y
    // *dst++ = *src++;
    // [2075] strcat::dst#1 = ++ strcat::dst#2 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // [2076] strcat::src#1 = ++ strcat::src#2 -- pbuz1=_inc_pbuz1 
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
// void display_rom_led(__zp($df) char chip, __zp($38) char c)
display_rom_led: {
    .label display_rom_led__0 = $ae
    .label chip = $df
    .label c = $38
    .label display_rom_led__7 = $ae
    .label display_rom_led__8 = $ae
    // chip*6
    // [2078] display_rom_led::$7 = display_rom_led::chip#2 << 1 -- vbuz1=vbuz2_rol_1 
    lda.z chip
    asl
    sta.z display_rom_led__7
    // [2079] display_rom_led::$8 = display_rom_led::$7 + display_rom_led::chip#2 -- vbuz1=vbuz1_plus_vbuz2 
    lda.z display_rom_led__8
    clc
    adc.z chip
    sta.z display_rom_led__8
    // CHIP_ROM_X+chip*6
    // [2080] display_rom_led::$0 = display_rom_led::$8 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z display_rom_led__0
    // display_chip_led(CHIP_ROM_X+chip*6+1, CHIP_ROM_Y, CHIP_ROM_W, c, BLUE)
    // [2081] display_chip_led::x#3 = display_rom_led::$0 + $14+1 -- vbuz1=vbuz1_plus_vbuc1 
    lda #$14+1
    clc
    adc.z display_chip_led.x
    sta.z display_chip_led.x
    // [2082] display_chip_led::tc#2 = display_rom_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_chip_led.tc
    // [2083] call display_chip_led
    // [2726] phi from display_rom_led to display_chip_led [phi:display_rom_led->display_chip_led]
    // [2726] phi display_chip_led::w#7 = 3 [phi:display_rom_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #3
    sta.z display_chip_led.w
    // [2726] phi display_chip_led::x#7 = display_chip_led::x#3 [phi:display_rom_led->display_chip_led#1] -- register_copy 
    // [2726] phi display_chip_led::tc#3 = display_chip_led::tc#2 [phi:display_rom_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_rom_led::@1
    // display_info_led(INFO_X-2, INFO_Y+chip+2, c, BLUE)
    // [2084] display_info_led::y#2 = display_rom_led::chip#2 + $11+2 -- vbuz1=vbuz2_plus_vbuc1 
    lda #$11+2
    clc
    adc.z chip
    sta.z display_info_led.y
    // [2085] display_info_led::tc#2 = display_rom_led::c#2 -- vbuz1=vbuz2 
    lda.z c
    sta.z display_info_led.tc
    // [2086] call display_info_led
    // [1978] phi from display_rom_led::@1 to display_info_led [phi:display_rom_led::@1->display_info_led]
    // [1978] phi display_info_led::y#4 = display_info_led::y#2 [phi:display_rom_led::@1->display_info_led#0] -- register_copy 
    // [1978] phi display_info_led::x#4 = 4-2 [phi:display_rom_led::@1->display_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z display_info_led.x
    // [1978] phi display_info_led::tc#4 = display_info_led::tc#2 [phi:display_rom_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_rom_led::@return
    // }
    // [2087] return 
    rts
}
  // uctoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void uctoa(__mem() char value, __zp($31) char *buffer, __mem() char radix)
uctoa: {
    .label uctoa__4 = $45
    .label buffer = $31
    .label digit_values = $41
    // if(radix==DECIMAL)
    // [2088] if(uctoa::radix#0==DECIMAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // uctoa::@2
    // if(radix==HEXADECIMAL)
    // [2089] if(uctoa::radix#0==HEXADECIMAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // uctoa::@3
    // if(radix==OCTAL)
    // [2090] if(uctoa::radix#0==OCTAL) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // uctoa::@4
    // if(radix==BINARY)
    // [2091] if(uctoa::radix#0==BINARY) goto uctoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // uctoa::@5
    // *buffer++ = 'e'
    // [2092] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2093] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2094] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2095] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // uctoa::@return
    // }
    // [2096] return 
    rts
    // [2097] phi from uctoa to uctoa::@1 [phi:uctoa->uctoa::@1]
  __b2:
    // [2097] phi uctoa::digit_values#8 = RADIX_DECIMAL_VALUES_CHAR [phi:uctoa->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [2097] phi uctoa::max_digits#7 = 3 [phi:uctoa->uctoa::@1#1] -- vbum1=vbuc1 
    lda #3
    sta max_digits
    jmp __b1
    // [2097] phi from uctoa::@2 to uctoa::@1 [phi:uctoa::@2->uctoa::@1]
  __b3:
    // [2097] phi uctoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_CHAR [phi:uctoa::@2->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_CHAR
    sta.z digit_values+1
    // [2097] phi uctoa::max_digits#7 = 2 [phi:uctoa::@2->uctoa::@1#1] -- vbum1=vbuc1 
    lda #2
    sta max_digits
    jmp __b1
    // [2097] phi from uctoa::@3 to uctoa::@1 [phi:uctoa::@3->uctoa::@1]
  __b4:
    // [2097] phi uctoa::digit_values#8 = RADIX_OCTAL_VALUES_CHAR [phi:uctoa::@3->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_CHAR
    sta.z digit_values+1
    // [2097] phi uctoa::max_digits#7 = 3 [phi:uctoa::@3->uctoa::@1#1] -- vbum1=vbuc1 
    lda #3
    sta max_digits
    jmp __b1
    // [2097] phi from uctoa::@4 to uctoa::@1 [phi:uctoa::@4->uctoa::@1]
  __b5:
    // [2097] phi uctoa::digit_values#8 = RADIX_BINARY_VALUES_CHAR [phi:uctoa::@4->uctoa::@1#0] -- pbuz1=pbuc1 
    lda #<RADIX_BINARY_VALUES_CHAR
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_CHAR
    sta.z digit_values+1
    // [2097] phi uctoa::max_digits#7 = 8 [phi:uctoa::@4->uctoa::@1#1] -- vbum1=vbuc1 
    lda #8
    sta max_digits
    // uctoa::@1
  __b1:
    // [2098] phi from uctoa::@1 to uctoa::@6 [phi:uctoa::@1->uctoa::@6]
    // [2098] phi uctoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:uctoa::@1->uctoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2098] phi uctoa::started#2 = 0 [phi:uctoa::@1->uctoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [2098] phi uctoa::value#2 = uctoa::value#1 [phi:uctoa::@1->uctoa::@6#2] -- register_copy 
    // [2098] phi uctoa::digit#2 = 0 [phi:uctoa::@1->uctoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // uctoa::@6
  __b6:
    // max_digits-1
    // [2099] uctoa::$4 = uctoa::max_digits#7 - 1 -- vbuz1=vbum2_minus_1 
    ldx max_digits
    dex
    stx.z uctoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2100] if(uctoa::digit#2<uctoa::$4) goto uctoa::@7 -- vbum1_lt_vbuz2_then_la1 
    lda digit
    cmp.z uctoa__4
    bcc __b7
    // uctoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2101] *uctoa::buffer#11 = DIGITS[uctoa::value#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy value
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2102] uctoa::buffer#3 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2103] *uctoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // uctoa::@7
  __b7:
    // unsigned char digit_value = digit_values[digit]
    // [2104] uctoa::digit_value#0 = uctoa::digit_values#8[uctoa::digit#2] -- vbum1=pbuz2_derefidx_vbum3 
    ldy digit
    lda (digit_values),y
    sta digit_value
    // if (started || value >= digit_value)
    // [2105] if(0!=uctoa::started#2) goto uctoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // uctoa::@12
    // [2106] if(uctoa::value#2>=uctoa::digit_value#0) goto uctoa::@10 -- vbum1_ge_vbum2_then_la1 
    lda value
    cmp digit_value
    bcs __b10
    // [2107] phi from uctoa::@12 to uctoa::@9 [phi:uctoa::@12->uctoa::@9]
    // [2107] phi uctoa::buffer#14 = uctoa::buffer#11 [phi:uctoa::@12->uctoa::@9#0] -- register_copy 
    // [2107] phi uctoa::started#4 = uctoa::started#2 [phi:uctoa::@12->uctoa::@9#1] -- register_copy 
    // [2107] phi uctoa::value#6 = uctoa::value#2 [phi:uctoa::@12->uctoa::@9#2] -- register_copy 
    // uctoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2108] uctoa::digit#1 = ++ uctoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [2098] phi from uctoa::@9 to uctoa::@6 [phi:uctoa::@9->uctoa::@6]
    // [2098] phi uctoa::buffer#11 = uctoa::buffer#14 [phi:uctoa::@9->uctoa::@6#0] -- register_copy 
    // [2098] phi uctoa::started#2 = uctoa::started#4 [phi:uctoa::@9->uctoa::@6#1] -- register_copy 
    // [2098] phi uctoa::value#2 = uctoa::value#6 [phi:uctoa::@9->uctoa::@6#2] -- register_copy 
    // [2098] phi uctoa::digit#2 = uctoa::digit#1 [phi:uctoa::@9->uctoa::@6#3] -- register_copy 
    jmp __b6
    // uctoa::@10
  __b10:
    // uctoa_append(buffer++, value, digit_value)
    // [2109] uctoa_append::buffer#0 = uctoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z uctoa_append.buffer
    lda.z buffer+1
    sta.z uctoa_append.buffer+1
    // [2110] uctoa_append::value#0 = uctoa::value#2
    // [2111] uctoa_append::sub#0 = uctoa::digit_value#0
    // [2112] call uctoa_append
    // [2817] phi from uctoa::@10 to uctoa_append [phi:uctoa::@10->uctoa_append]
    jsr uctoa_append
    // uctoa_append(buffer++, value, digit_value)
    // [2113] uctoa_append::return#0 = uctoa_append::value#2
    // uctoa::@11
    // value = uctoa_append(buffer++, value, digit_value)
    // [2114] uctoa::value#0 = uctoa_append::return#0
    // value = uctoa_append(buffer++, value, digit_value);
    // [2115] uctoa::buffer#4 = ++ uctoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2107] phi from uctoa::@11 to uctoa::@9 [phi:uctoa::@11->uctoa::@9]
    // [2107] phi uctoa::buffer#14 = uctoa::buffer#4 [phi:uctoa::@11->uctoa::@9#0] -- register_copy 
    // [2107] phi uctoa::started#4 = 1 [phi:uctoa::@11->uctoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [2107] phi uctoa::value#6 = uctoa::value#0 [phi:uctoa::@11->uctoa::@9#2] -- register_copy 
    jmp __b9
  .segment Data
    digit_value: .byte 0
    digit: .byte 0
    .label value = printf_uchar.uvalue
    .label radix = printf_uchar.format_radix
    started: .byte 0
    max_digits: .byte 0
}
.segment Code
  // printf_number_buffer
// Print the contents of the number buffer using a specific format.
// This handles minimum length, zero-filling, and left/right justification from the format
// void printf_number_buffer(__zp($aa) void (*putc)(char), __mem() char buffer_sign, char *buffer_digits, __mem() char format_min_length, char format_justify_left, char format_sign_always, __mem() char format_zero_padding, char format_upper_case, char format_radix)
printf_number_buffer: {
    .label printf_number_buffer__19 = $31
    .label putc = $aa
    // if(format.min_length)
    // [2117] if(0==printf_number_buffer::format_min_length#3) goto printf_number_buffer::@1 -- 0_eq_vbum1_then_la1 
    lda format_min_length
    beq __b5
    // [2118] phi from printf_number_buffer to printf_number_buffer::@5 [phi:printf_number_buffer->printf_number_buffer::@5]
    // printf_number_buffer::@5
    // strlen(buffer.digits)
    // [2119] call strlen
    // [2155] phi from printf_number_buffer::@5 to strlen [phi:printf_number_buffer::@5->strlen]
    // [2155] phi strlen::str#8 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@5->strlen#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z strlen.str+1
    jsr strlen
    // strlen(buffer.digits)
    // [2120] strlen::return#3 = strlen::len#2
    // printf_number_buffer::@11
    // [2121] printf_number_buffer::$19 = strlen::return#3 -- vwuz1=vwum2 
    lda strlen.return
    sta.z printf_number_buffer__19
    lda strlen.return+1
    sta.z printf_number_buffer__19+1
    // signed char len = (signed char)strlen(buffer.digits)
    // [2122] printf_number_buffer::len#0 = (signed char)printf_number_buffer::$19 -- vbsm1=_sbyte_vwuz2 
    // There is a minimum length - work out the padding
    lda.z printf_number_buffer__19
    sta len
    // if(buffer.sign)
    // [2123] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@10 -- 0_eq_vbum1_then_la1 
    lda buffer_sign
    beq __b10
    // printf_number_buffer::@6
    // len++;
    // [2124] printf_number_buffer::len#1 = ++ printf_number_buffer::len#0 -- vbsm1=_inc_vbsm1 
    inc len
    // [2125] phi from printf_number_buffer::@11 printf_number_buffer::@6 to printf_number_buffer::@10 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10]
    // [2125] phi printf_number_buffer::len#2 = printf_number_buffer::len#0 [phi:printf_number_buffer::@11/printf_number_buffer::@6->printf_number_buffer::@10#0] -- register_copy 
    // printf_number_buffer::@10
  __b10:
    // padding = (signed char)format.min_length - len
    // [2126] printf_number_buffer::padding#1 = (signed char)printf_number_buffer::format_min_length#3 - printf_number_buffer::len#2 -- vbsm1=vbsm2_minus_vbsm1 
    lda format_min_length
    sec
    sbc padding
    sta padding
    // if(padding<0)
    // [2127] if(printf_number_buffer::padding#1>=0) goto printf_number_buffer::@15 -- vbsm1_ge_0_then_la1 
    cmp #0
    bpl __b1
    // [2129] phi from printf_number_buffer printf_number_buffer::@10 to printf_number_buffer::@1 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1]
  __b5:
    // [2129] phi printf_number_buffer::padding#10 = 0 [phi:printf_number_buffer/printf_number_buffer::@10->printf_number_buffer::@1#0] -- vbsm1=vbsc1 
    lda #0
    sta padding
    // [2128] phi from printf_number_buffer::@10 to printf_number_buffer::@15 [phi:printf_number_buffer::@10->printf_number_buffer::@15]
    // printf_number_buffer::@15
    // [2129] phi from printf_number_buffer::@15 to printf_number_buffer::@1 [phi:printf_number_buffer::@15->printf_number_buffer::@1]
    // [2129] phi printf_number_buffer::padding#10 = printf_number_buffer::padding#1 [phi:printf_number_buffer::@15->printf_number_buffer::@1#0] -- register_copy 
    // printf_number_buffer::@1
  __b1:
    // printf_number_buffer::@13
    // if(!format.justify_left && !format.zero_padding && padding)
    // [2130] if(0!=printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@2 -- 0_neq_vbum1_then_la1 
    lda format_zero_padding
    bne __b2
    // printf_number_buffer::@12
    // [2131] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@7 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b7
    jmp __b2
    // printf_number_buffer::@7
  __b7:
    // printf_padding(putc, ' ',(char)padding)
    // [2132] printf_padding::putc#0 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [2133] printf_padding::length#0 = (char)printf_number_buffer::padding#10 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [2134] call printf_padding
    // [2161] phi from printf_number_buffer::@7 to printf_padding [phi:printf_number_buffer::@7->printf_padding]
    // [2161] phi printf_padding::putc#7 = printf_padding::putc#0 [phi:printf_number_buffer::@7->printf_padding#0] -- register_copy 
    // [2161] phi printf_padding::pad#7 = ' ' [phi:printf_number_buffer::@7->printf_padding#1] -- vbum1=vbuc1 
    lda #' '
    sta printf_padding.pad
    // [2161] phi printf_padding::length#6 = printf_padding::length#0 [phi:printf_number_buffer::@7->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@2
  __b2:
    // if(buffer.sign)
    // [2135] if(0==printf_number_buffer::buffer_sign#10) goto printf_number_buffer::@3 -- 0_eq_vbum1_then_la1 
    lda buffer_sign
    beq __b3
    // printf_number_buffer::@8
    // putc(buffer.sign)
    // [2136] stackpush(char) = printf_number_buffer::buffer_sign#10 -- _stackpushbyte_=vbum1 
    pha
    // [2137] callexecute *printf_number_buffer::putc#10  -- call__deref_pprz1 
    jsr icall30
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_number_buffer::@3
  __b3:
    // if(format.zero_padding && padding)
    // [2139] if(0==printf_number_buffer::format_zero_padding#10) goto printf_number_buffer::@4 -- 0_eq_vbum1_then_la1 
    lda format_zero_padding
    beq __b4
    // printf_number_buffer::@14
    // [2140] if(0!=printf_number_buffer::padding#10) goto printf_number_buffer::@9 -- 0_neq_vbsm1_then_la1 
    lda padding
    cmp #0
    bne __b9
    jmp __b4
    // printf_number_buffer::@9
  __b9:
    // printf_padding(putc, '0',(char)padding)
    // [2141] printf_padding::putc#1 = printf_number_buffer::putc#10 -- pprz1=pprz2 
    lda.z putc
    sta.z printf_padding.putc
    lda.z putc+1
    sta.z printf_padding.putc+1
    // [2142] printf_padding::length#1 = (char)printf_number_buffer::padding#10 -- vbum1=vbum2 
    lda padding
    sta printf_padding.length
    // [2143] call printf_padding
    // [2161] phi from printf_number_buffer::@9 to printf_padding [phi:printf_number_buffer::@9->printf_padding]
    // [2161] phi printf_padding::putc#7 = printf_padding::putc#1 [phi:printf_number_buffer::@9->printf_padding#0] -- register_copy 
    // [2161] phi printf_padding::pad#7 = '0' [phi:printf_number_buffer::@9->printf_padding#1] -- vbum1=vbuc1 
    lda #'0'
    sta printf_padding.pad
    // [2161] phi printf_padding::length#6 = printf_padding::length#1 [phi:printf_number_buffer::@9->printf_padding#2] -- register_copy 
    jsr printf_padding
    // printf_number_buffer::@4
  __b4:
    // printf_str(putc, buffer.digits)
    // [2144] printf_str::putc#0 = printf_number_buffer::putc#10
    // [2145] call printf_str
    // [1054] phi from printf_number_buffer::@4 to printf_str [phi:printf_number_buffer::@4->printf_str]
    // [1054] phi printf_str::putc#75 = printf_str::putc#0 [phi:printf_number_buffer::@4->printf_str#0] -- register_copy 
    // [1054] phi printf_str::s#75 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:printf_number_buffer::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z printf_str.s+1
    jsr printf_str
    // printf_number_buffer::@return
    // }
    // [2146] return 
    rts
    // Outside Flow
  icall30:
    jmp (putc)
  .segment Data
    buffer_sign: .byte 0
    .label format_min_length = printf_uchar.format_min_length
    .label format_zero_padding = printf_uchar.format_zero_padding
    len: .byte 0
    .label padding = len
}
.segment Code
  // cputcxy
// Move cursor and output one character
// Same as "gotoxy (x, y); cputc (c);"
// void cputcxy(__mem() char x, __mem() char y, __mem() char c)
cputcxy: {
    // gotoxy(x, y)
    // [2148] gotoxy::x#0 = cputcxy::x#15 -- vbum1=vbum2 
    lda x
    sta gotoxy.x
    // [2149] gotoxy::y#0 = cputcxy::y#15 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [2150] call gotoxy
    // [778] phi from cputcxy to gotoxy [phi:cputcxy->gotoxy]
    // [778] phi gotoxy::y#33 = gotoxy::y#0 [phi:cputcxy->gotoxy#0] -- register_copy 
    // [778] phi gotoxy::x#33 = gotoxy::x#0 [phi:cputcxy->gotoxy#1] -- register_copy 
    jsr gotoxy
    // cputcxy::@1
    // cputc(c)
    // [2151] stackpush(char) = cputcxy::c#15 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [2152] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // cputcxy::@return
    // }
    // [2154] return 
    rts
  .segment Data
    x: .byte 0
    y: .byte 0
    c: .byte 0
}
.segment Code
  // strlen
// Computes the length of the string str up to but not including the terminating null character.
// __mem() unsigned int strlen(__zp($31) char *str)
strlen: {
    .label str = $31
    // [2156] phi from strlen to strlen::@1 [phi:strlen->strlen::@1]
    // [2156] phi strlen::len#2 = 0 [phi:strlen->strlen::@1#0] -- vwum1=vwuc1 
    lda #<0
    sta len
    sta len+1
    // [2156] phi strlen::str#6 = strlen::str#8 [phi:strlen->strlen::@1#1] -- register_copy 
    // strlen::@1
  __b1:
    // while(*str)
    // [2157] if(0!=*strlen::str#6) goto strlen::@2 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (str),y
    cmp #0
    bne __b2
    // strlen::@return
    // }
    // [2158] return 
    rts
    // strlen::@2
  __b2:
    // len++;
    // [2159] strlen::len#1 = ++ strlen::len#2 -- vwum1=_inc_vwum1 
    inc len
    bne !+
    inc len+1
  !:
    // str++;
    // [2160] strlen::str#1 = ++ strlen::str#6 -- pbuz1=_inc_pbuz1 
    inc.z str
    bne !+
    inc.z str+1
  !:
    // [2156] phi from strlen::@2 to strlen::@1 [phi:strlen::@2->strlen::@1]
    // [2156] phi strlen::len#2 = strlen::len#1 [phi:strlen::@2->strlen::@1#0] -- register_copy 
    // [2156] phi strlen::str#6 = strlen::str#1 [phi:strlen::@2->strlen::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label return = len
    len: .word 0
}
.segment Code
  // printf_padding
// Print a padding char a number of times
// void printf_padding(__zp($47) void (*putc)(char), __mem() char pad, __mem() char length)
printf_padding: {
    .label putc = $47
    // [2162] phi from printf_padding to printf_padding::@1 [phi:printf_padding->printf_padding::@1]
    // [2162] phi printf_padding::i#2 = 0 [phi:printf_padding->printf_padding::@1#0] -- vbum1=vbuc1 
    lda #0
    sta i
    // printf_padding::@1
  __b1:
    // for(char i=0;i<length; i++)
    // [2163] if(printf_padding::i#2<printf_padding::length#6) goto printf_padding::@2 -- vbum1_lt_vbum2_then_la1 
    lda i
    cmp length
    bcc __b2
    // printf_padding::@return
    // }
    // [2164] return 
    rts
    // printf_padding::@2
  __b2:
    // putc(pad)
    // [2165] stackpush(char) = printf_padding::pad#7 -- _stackpushbyte_=vbum1 
    lda pad
    pha
    // [2166] callexecute *printf_padding::putc#7  -- call__deref_pprz1 
    jsr icall32
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // printf_padding::@3
    // for(char i=0;i<length; i++)
    // [2168] printf_padding::i#1 = ++ printf_padding::i#2 -- vbum1=_inc_vbum1 
    inc i
    // [2162] phi from printf_padding::@3 to printf_padding::@1 [phi:printf_padding::@3->printf_padding::@1]
    // [2162] phi printf_padding::i#2 = printf_padding::i#1 [phi:printf_padding::@3->printf_padding::@1#0] -- register_copy 
    jmp __b1
    // Outside Flow
  icall32:
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
// __mem() unsigned long rom_address_from_bank(__mem() char rom_bank)
rom_address_from_bank: {
    .label return_1 = $62
    // ((unsigned long)(rom_bank)) << 14
    // [2170] rom_address_from_bank::$1 = (unsigned long)rom_address_from_bank::rom_bank#3 -- vdum1=_dword_vbum2 
    lda rom_bank
    sta rom_address_from_bank__1
    lda #0
    sta rom_address_from_bank__1+1
    sta rom_address_from_bank__1+2
    sta rom_address_from_bank__1+3
    // [2171] rom_address_from_bank::return#0 = rom_address_from_bank::$1 << $e -- vdum1=vdum1_rol_vbuc1 
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
    // [2172] return 
    rts
  .segment Data
    .label rom_address_from_bank__1 = rom_read_byte.address
    .label return = rom_read_byte.address
    .label rom_bank = main.check_status_smc7_main__0
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
// __zp($47) struct $2 * fopen(__zp($b0) const char *path, const char *mode)
fopen: {
    .label fopen__9 = $bc
    .label fopen__11 = $3f
    .label fopen__26 = $60
    .label fopen__28 = $aa
    .label fopen__30 = $47
    .label stream = $47
    .label pathtoken = $b0
    .label pathtoken_1 = $f0
    .label path = $b0
    .label return = $47
    // unsigned char sp = __stdio_filecount
    // [2174] fopen::sp#0 = __stdio_filecount#18 -- vbum1=vbum2 
    lda __stdio_filecount
    sta sp
    // (unsigned int)sp | 0x8000
    // [2175] fopen::$30 = (unsigned int)fopen::sp#0 -- vwuz1=_word_vbum2 
    sta.z fopen__30
    lda #0
    sta.z fopen__30+1
    // [2176] fopen::stream#0 = fopen::$30 | $8000 -- vwuz1=vwuz1_bor_vwuc1 
    lda.z stream
    ora #<$8000
    sta.z stream
    lda.z stream+1
    ora #>$8000
    sta.z stream+1
    // char pathpos = sp * __STDIO_FILECOUNT
    // [2177] fopen::pathpos#0 = fopen::sp#0 << 1 -- vbum1=vbum2_rol_1 
    lda sp
    asl
    sta pathpos
    // __logical = 0
    // [2178] ((char *)&__stdio_file+$40)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy sp
    sta __stdio_file+$40,y
    // __device = 0
    // [2179] ((char *)&__stdio_file+$42)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [2180] ((char *)&__stdio_file+$44)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$44,y
    // [2181] fopen::pathtoken#22 = fopen::pathtoken#0 -- pbuz1=pbuz2 
    lda.z pathtoken
    sta.z pathtoken_1
    lda.z pathtoken+1
    sta.z pathtoken_1+1
    // [2182] fopen::pathpos#21 = fopen::pathpos#0 -- vbum1=vbum2 
    lda pathpos
    sta pathpos_1
    // [2183] phi from fopen to fopen::@8 [phi:fopen->fopen::@8]
    // [2183] phi fopen::num#10 = 0 [phi:fopen->fopen::@8#0] -- vbum1=vbuc1 
    lda #0
    sta num
    // [2183] phi fopen::pathpos#10 = fopen::pathpos#21 [phi:fopen->fopen::@8#1] -- register_copy 
    // [2183] phi fopen::path#10 = fopen::pathtoken#0 [phi:fopen->fopen::@8#2] -- register_copy 
    // [2183] phi fopen::pathstep#10 = 0 [phi:fopen->fopen::@8#3] -- vbum1=vbuc1 
    sta pathstep
    // [2183] phi fopen::pathtoken#10 = fopen::pathtoken#22 [phi:fopen->fopen::@8#4] -- register_copy 
  // Iterate while path is not \0.
    // [2183] phi from fopen::@22 to fopen::@8 [phi:fopen::@22->fopen::@8]
    // [2183] phi fopen::num#10 = fopen::num#13 [phi:fopen::@22->fopen::@8#0] -- register_copy 
    // [2183] phi fopen::pathpos#10 = fopen::pathpos#7 [phi:fopen::@22->fopen::@8#1] -- register_copy 
    // [2183] phi fopen::path#10 = fopen::path#11 [phi:fopen::@22->fopen::@8#2] -- register_copy 
    // [2183] phi fopen::pathstep#10 = fopen::pathstep#11 [phi:fopen::@22->fopen::@8#3] -- register_copy 
    // [2183] phi fopen::pathtoken#10 = fopen::pathtoken#1 [phi:fopen::@22->fopen::@8#4] -- register_copy 
    // fopen::@8
  __b8:
    // if (*pathtoken == ',' || *pathtoken == '\0')
    // [2184] if(*fopen::pathtoken#10==',') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #','
    ldy #0
    cmp (pathtoken_1),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@33
    // [2185] if(*fopen::pathtoken#10=='@') goto fopen::@9 -- _deref_pbuz1_eq_vbuc1_then_la1 
    lda #'@'
    cmp (pathtoken_1),y
    bne !__b9+
    jmp __b9
  !__b9:
    // fopen::@23
    // if (pathstep == 0)
    // [2186] if(fopen::pathstep#10!=0) goto fopen::@10 -- vbum1_neq_0_then_la1 
    lda pathstep
    bne __b10
    // fopen::@24
    // __stdio_file.filename[pathpos] = *pathtoken
    // [2187] ((char *)&__stdio_file)[fopen::pathpos#10] = *fopen::pathtoken#10 -- pbuc1_derefidx_vbum1=_deref_pbuz2 
    lda (pathtoken_1),y
    ldy pathpos_1
    sta __stdio_file,y
    // pathpos++;
    // [2188] fopen::pathpos#1 = ++ fopen::pathpos#10 -- vbum1=_inc_vbum1 
    inc pathpos_1
    // [2189] phi from fopen::@12 fopen::@23 fopen::@24 to fopen::@10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10]
    // [2189] phi fopen::num#13 = fopen::num#15 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#0] -- register_copy 
    // [2189] phi fopen::pathpos#7 = fopen::pathpos#10 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#1] -- register_copy 
    // [2189] phi fopen::path#11 = fopen::path#13 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#2] -- register_copy 
    // [2189] phi fopen::pathstep#11 = fopen::pathstep#1 [phi:fopen::@12/fopen::@23/fopen::@24->fopen::@10#3] -- register_copy 
    // fopen::@10
  __b10:
    // pathtoken++;
    // [2190] fopen::pathtoken#1 = ++ fopen::pathtoken#10 -- pbuz1=_inc_pbuz1 
    inc.z pathtoken_1
    bne !+
    inc.z pathtoken_1+1
  !:
    // fopen::@22
    // pathtoken - 1
    // [2191] fopen::$28 = fopen::pathtoken#1 - 1 -- pbuz1=pbuz2_minus_1 
    lda.z pathtoken_1
    sec
    sbc #1
    sta.z fopen__28
    lda.z pathtoken_1+1
    sbc #0
    sta.z fopen__28+1
    // while (*(pathtoken - 1))
    // [2192] if(0!=*fopen::$28) goto fopen::@8 -- 0_neq__deref_pbuz1_then_la1 
    ldy #0
    lda (fopen__28),y
    cmp #0
    bne __b8
    // fopen::@26
    // __status = 0
    // [2193] ((char *)&__stdio_file+$46)[fopen::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    tya
    ldy sp
    sta __stdio_file+$46,y
    // if(!__logical)
    // [2194] if(0!=((char *)&__stdio_file+$40)[fopen::sp#0]) goto fopen::@1 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$40,y
    cmp #0
    bne __b1
    // fopen::@27
    // __stdio_filecount+1
    // [2195] fopen::$4 = __stdio_filecount#18 + 1 -- vbum1=vbum2_plus_1 
    lda __stdio_filecount
    inc
    sta fopen__4
    // __logical = __stdio_filecount+1
    // [2196] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::$4 -- pbuc1_derefidx_vbum1=vbum2 
    sta __stdio_file+$40,y
    // fopen::@1
  __b1:
    // if(!__device)
    // [2197] if(0!=((char *)&__stdio_file+$42)[fopen::sp#0]) goto fopen::@2 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    ldy sp
    lda __stdio_file+$42,y
    cmp #0
    bne __b2
    // fopen::@5
    // __device = 8
    // [2198] ((char *)&__stdio_file+$42)[fopen::sp#0] = 8 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #8
    sta __stdio_file+$42,y
    // fopen::@2
  __b2:
    // if(!__channel)
    // [2199] if(0!=((char *)&__stdio_file+$44)[fopen::sp#0]) goto fopen::@3 -- 0_neq_pbuc1_derefidx_vbum1_then_la1 
    ldy sp
    lda __stdio_file+$44,y
    cmp #0
    bne __b3
    // fopen::@6
    // __stdio_filecount+2
    // [2200] fopen::$9 = __stdio_filecount#18 + 2 -- vbuz1=vbum2_plus_2 
    lda __stdio_filecount
    clc
    adc #2
    sta.z fopen__9
    // __channel = __stdio_filecount+2
    // [2201] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::$9 -- pbuc1_derefidx_vbum1=vbuz2 
    sta __stdio_file+$44,y
    // fopen::@3
  __b3:
    // __filename
    // [2202] fopen::$11 = (char *)&__stdio_file + fopen::pathpos#0 -- pbuz1=pbuc1_plus_vbum2 
    lda pathpos
    clc
    adc #<__stdio_file
    sta.z fopen__11
    lda #>__stdio_file
    adc #0
    sta.z fopen__11+1
    // cbm_k_setnam(__filename)
    // [2203] fopen::cbm_k_setnam1_filename = fopen::$11 -- pbum1=pbuz2 
    lda.z fopen__11
    sta cbm_k_setnam1_filename
    lda.z fopen__11+1
    sta cbm_k_setnam1_filename+1
    // fopen::cbm_k_setnam1
    // strlen(filename)
    // [2204] strlen::str#4 = fopen::cbm_k_setnam1_filename -- pbuz1=pbum2 
    lda cbm_k_setnam1_filename
    sta.z strlen.str
    lda cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [2205] call strlen
    // [2155] phi from fopen::cbm_k_setnam1 to strlen [phi:fopen::cbm_k_setnam1->strlen]
    // [2155] phi strlen::str#8 = strlen::str#4 [phi:fopen::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [2206] strlen::return#11 = strlen::len#2
    // fopen::@31
    // [2207] fopen::cbm_k_setnam1_$0 = strlen::return#11 -- vwum1=vwum2 
    lda strlen.return
    sta cbm_k_setnam1_fopen__0
    lda strlen.return+1
    sta cbm_k_setnam1_fopen__0+1
    // char filename_len = (char)strlen(filename)
    // [2208] fopen::cbm_k_setnam1_filename_len = (char)fopen::cbm_k_setnam1_$0 -- vbum1=_byte_vwum2 
    lda cbm_k_setnam1_fopen__0
    sta cbm_k_setnam1_filename_len
    // asm
    // asm { ldafilename_len ldxfilename ldyfilename+1 jsrCBM_SETNAM  }
    ldx cbm_k_setnam1_filename
    ldy cbm_k_setnam1_filename+1
    jsr CBM_SETNAM
    // fopen::@28
    // cbm_k_setlfs(__logical, __device, __channel)
    // [2210] cbm_k_setlfs::channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$40,y
    sta cbm_k_setlfs.channel
    // [2211] cbm_k_setlfs::device = ((char *)&__stdio_file+$42)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    lda __stdio_file+$42,y
    sta cbm_k_setlfs.device
    // [2212] cbm_k_setlfs::command = ((char *)&__stdio_file+$44)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    lda __stdio_file+$44,y
    sta cbm_k_setlfs.command
    // [2213] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // fopen::cbm_k_open1
    // asm
    // asm { jsrCBM_OPEN  }
    jsr CBM_OPEN
    // fopen::cbm_k_readst1
    // char status
    // [2215] fopen::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2217] fopen::cbm_k_readst1_return#0 = fopen::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fopen::cbm_k_readst1_@return
    // }
    // [2218] fopen::cbm_k_readst1_return#1 = fopen::cbm_k_readst1_return#0
    // fopen::@29
    // cbm_k_readst()
    // [2219] fopen::$15 = fopen::cbm_k_readst1_return#1 -- vbum1=vbum2 
    sta fopen__15
    // __status = cbm_k_readst()
    // [2220] ((char *)&__stdio_file+$46)[fopen::sp#0] = fopen::$15 -- pbuc1_derefidx_vbum1=vbum2 
    ldy sp
    sta __stdio_file+$46,y
    // ferror(stream)
    // [2221] ferror::stream#0 = (struct $2 *)fopen::stream#0
    // [2222] call ferror
    jsr ferror
    // [2223] ferror::return#0 = ferror::return#1
    // fopen::@32
    // [2224] fopen::$16 = ferror::return#0 -- vwsm1=vwsm2 
    lda ferror.return
    sta fopen__16
    lda ferror.return+1
    sta fopen__16+1
    // if (ferror(stream))
    // [2225] if(0==fopen::$16) goto fopen::@4 -- 0_eq_vwsm1_then_la1 
    lda fopen__16
    ora fopen__16+1
    beq __b4
    // fopen::@7
    // cbm_k_close(__logical)
    // [2226] fopen::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fopen::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$40,y
    sta cbm_k_close1_channel
    // fopen::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // [2228] phi from fopen::cbm_k_close1 to fopen::@return [phi:fopen::cbm_k_close1->fopen::@return]
    // [2228] phi __stdio_filecount#1 = __stdio_filecount#18 [phi:fopen::cbm_k_close1->fopen::@return#0] -- register_copy 
    // [2228] phi fopen::return#2 = 0 [phi:fopen::cbm_k_close1->fopen::@return#1] -- pssz1=vbuc1 
    lda #<0
    sta.z return
    sta.z return+1
    // fopen::@return
    // }
    // [2229] return 
    rts
    // fopen::@4
  __b4:
    // __stdio_filecount++;
    // [2230] __stdio_filecount#0 = ++ __stdio_filecount#18 -- vbum1=_inc_vbum1 
    inc __stdio_filecount
    // [2231] fopen::return#8 = (struct $2 *)fopen::stream#0
    // [2228] phi from fopen::@4 to fopen::@return [phi:fopen::@4->fopen::@return]
    // [2228] phi __stdio_filecount#1 = __stdio_filecount#0 [phi:fopen::@4->fopen::@return#0] -- register_copy 
    // [2228] phi fopen::return#2 = fopen::return#8 [phi:fopen::@4->fopen::@return#1] -- register_copy 
    rts
    // fopen::@9
  __b9:
    // if (pathstep > 0)
    // [2232] if(fopen::pathstep#10>0) goto fopen::@11 -- vbum1_gt_0_then_la1 
    lda pathstep
    bne __b11
    // fopen::@25
    // __stdio_file.filename[pathpos] = '\0'
    // [2233] ((char *)&__stdio_file)[fopen::pathpos#10] = '@' -- pbuc1_derefidx_vbum1=vbuc2 
    lda #'@'
    ldy pathpos_1
    sta __stdio_file,y
    // path = pathtoken + 1
    // [2234] fopen::path#0 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
    clc
    lda.z pathtoken_1
    adc #1
    sta.z path
    lda.z pathtoken_1+1
    adc #0
    sta.z path+1
    // [2235] phi from fopen::@16 fopen::@17 fopen::@18 fopen::@19 fopen::@25 to fopen::@12 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12]
    // [2235] phi fopen::num#15 = fopen::num#2 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#0] -- register_copy 
    // [2235] phi fopen::path#13 = fopen::path#16 [phi:fopen::@16/fopen::@17/fopen::@18/fopen::@19/fopen::@25->fopen::@12#1] -- register_copy 
    // fopen::@12
  __b12:
    // pathstep++;
    // [2236] fopen::pathstep#1 = ++ fopen::pathstep#10 -- vbum1=_inc_vbum1 
    inc pathstep
    jmp __b10
    // fopen::@11
  __b11:
    // char pathcmp = *path
    // [2237] fopen::pathcmp#0 = *fopen::path#10 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (path),y
    sta pathcmp
    // case 'D':
    // [2238] if(fopen::pathcmp#0=='D') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'D'
    cmp pathcmp
    beq __b13
    // fopen::@20
    // case 'L':
    // [2239] if(fopen::pathcmp#0=='L') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'L'
    cmp pathcmp
    beq __b13
    // fopen::@21
    // case 'C':
    //                     num = (char)atoi(path + 1);
    //                     path = pathtoken + 1;
    // [2240] if(fopen::pathcmp#0=='C') goto fopen::@13 -- vbum1_eq_vbuc1_then_la1 
    lda #'C'
    cmp pathcmp
    beq __b13
    // [2241] phi from fopen::@21 fopen::@30 to fopen::@14 [phi:fopen::@21/fopen::@30->fopen::@14]
    // [2241] phi fopen::path#16 = fopen::path#10 [phi:fopen::@21/fopen::@30->fopen::@14#0] -- register_copy 
    // [2241] phi fopen::num#2 = fopen::num#10 [phi:fopen::@21/fopen::@30->fopen::@14#1] -- register_copy 
    // fopen::@14
  __b14:
    // case 'L':
    //                     __logical = num;
    //                     break;
    // [2242] if(fopen::pathcmp#0=='L') goto fopen::@17 -- vbum1_eq_vbuc1_then_la1 
    lda #'L'
    cmp pathcmp
    beq __b17
    // fopen::@15
    // case 'D':
    //                     __device = num;
    //                     break;
    // [2243] if(fopen::pathcmp#0=='D') goto fopen::@18 -- vbum1_eq_vbuc1_then_la1 
    lda #'D'
    cmp pathcmp
    beq __b18
    // fopen::@16
    // case 'C':
    //                     __channel = num;
    //                     break;
    // [2244] if(fopen::pathcmp#0!='C') goto fopen::@12 -- vbum1_neq_vbuc1_then_la1 
    lda #'C'
    cmp pathcmp
    bne __b12
    // fopen::@19
    // __channel = num
    // [2245] ((char *)&__stdio_file+$44)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$44,y
    jmp __b12
    // fopen::@18
  __b18:
    // __device = num
    // [2246] ((char *)&__stdio_file+$42)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$42,y
    jmp __b12
    // fopen::@17
  __b17:
    // __logical = num
    // [2247] ((char *)&__stdio_file+$40)[fopen::sp#0] = fopen::num#2 -- pbuc1_derefidx_vbum1=vbum2 
    lda num
    ldy sp
    sta __stdio_file+$40,y
    jmp __b12
    // fopen::@13
  __b13:
    // atoi(path + 1)
    // [2248] atoi::str#0 = fopen::path#10 + 1 -- pbuz1=pbuz1_plus_1 
    inc.z atoi.str
    bne !+
    inc.z atoi.str+1
  !:
    // [2249] call atoi
    // [2878] phi from fopen::@13 to atoi [phi:fopen::@13->atoi]
    // [2878] phi atoi::str#2 = atoi::str#0 [phi:fopen::@13->atoi#0] -- register_copy 
    jsr atoi
    // atoi(path + 1)
    // [2250] atoi::return#3 = atoi::return#2
    // fopen::@30
    // [2251] fopen::$26 = atoi::return#3 -- vwsz1=vwsm2 
    lda atoi.return
    sta.z fopen__26
    lda atoi.return+1
    sta.z fopen__26+1
    // num = (char)atoi(path + 1)
    // [2252] fopen::num#1 = (char)fopen::$26 -- vbum1=_byte_vwsz2 
    lda.z fopen__26
    sta num
    // path = pathtoken + 1
    // [2253] fopen::path#1 = fopen::pathtoken#10 + 1 -- pbuz1=pbuz2_plus_1 
    clc
    lda.z pathtoken_1
    adc #1
    sta.z path
    lda.z pathtoken_1+1
    adc #0
    sta.z path+1
    jmp __b14
  .segment Data
    fopen__4: .byte 0
    .label fopen__15 = fclose.fclose__1
    fopen__16: .word 0
    cbm_k_setnam1_filename: .word 0
    cbm_k_setnam1_filename_len: .byte 0
    cbm_k_setnam1_fopen__0: .word 0
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
  // fclose
/**
 * @brief Close a file.
 *
 * @param fp The FILE pointer.
 * @return
 *  - 0x0000: Something is wrong! Kernal Error Code (https://commodore.ca/manuals/pdfs/commodore_error_messages.pdf)
 *  - other: OK! The last pointer between 0xA000 and 0xBFFF is returned. Note that the last pointer is indicating the first free byte.
 */
// int fclose(__mem() struct $2 *stream)
fclose: {
    .label fclose__4 = $ce
    .label fclose__6 = $77
    // unsigned char sp = (unsigned char)stream
    // [2255] fclose::sp#0 = (char)fclose::stream#2 -- vbum1=_byte_pssm2 
    lda stream
    sta sp
    // cbm_k_chkin(__logical)
    // [2256] fclose::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    tay
    lda __stdio_file+$40,y
    sta cbm_k_chkin1_channel
    // fclose::cbm_k_chkin1
    // char status
    // [2257] fclose::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fclose::cbm_k_readst1
    // char status
    // [2259] fclose::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2261] fclose::cbm_k_readst1_return#0 = fclose::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fclose::cbm_k_readst1_@return
    // }
    // [2262] fclose::cbm_k_readst1_return#1 = fclose::cbm_k_readst1_return#0
    // fclose::@3
    // cbm_k_readst()
    // [2263] fclose::$1 = fclose::cbm_k_readst1_return#1 -- vbum1=vbum2 
    sta fclose__1
    // __status = cbm_k_readst()
    // [2264] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$1 -- pbuc1_derefidx_vbum1=vbum2 
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2265] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@1 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b1
    // [2266] phi from fclose::@2 fclose::@3 fclose::@4 to fclose::@return [phi:fclose::@2/fclose::@3/fclose::@4->fclose::@return]
    // [2266] phi __stdio_filecount#2 = __stdio_filecount#3 [phi:fclose::@2/fclose::@3/fclose::@4->fclose::@return#0] -- register_copy 
    // fclose::@return
    // }
    // [2267] return 
    rts
    // fclose::@1
  __b1:
    // cbm_k_close(__logical)
    // [2268] fclose::cbm_k_close1_channel = ((char *)&__stdio_file+$40)[fclose::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    ldy sp
    lda __stdio_file+$40,y
    sta cbm_k_close1_channel
    // fclose::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // fclose::cbm_k_readst2
    // char status
    // [2270] fclose::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [2272] fclose::cbm_k_readst2_return#0 = fclose::cbm_k_readst2_status -- vbum1=vbum2 
    sta cbm_k_readst2_return
    // fclose::cbm_k_readst2_@return
    // }
    // [2273] fclose::cbm_k_readst2_return#1 = fclose::cbm_k_readst2_return#0
    // fclose::@4
    // cbm_k_readst()
    // [2274] fclose::$4 = fclose::cbm_k_readst2_return#1 -- vbuz1=vbum2 
    sta.z fclose__4
    // __status = cbm_k_readst()
    // [2275] ((char *)&__stdio_file+$46)[fclose::sp#0] = fclose::$4 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2276] if(0==((char *)&__stdio_file+$46)[fclose::sp#0]) goto fclose::@2 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b2
    rts
    // fclose::@2
  __b2:
    // __logical = 0
    // [2277] ((char *)&__stdio_file+$40)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    lda #0
    ldy sp
    sta __stdio_file+$40,y
    // __device = 0
    // [2278] ((char *)&__stdio_file+$42)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$42,y
    // __channel = 0
    // [2279] ((char *)&__stdio_file+$44)[fclose::sp#0] = 0 -- pbuc1_derefidx_vbum1=vbuc2 
    sta __stdio_file+$44,y
    // __filename
    // [2280] fclose::$6 = fclose::sp#0 << 1 -- vbuz1=vbum2_rol_1 
    tya
    asl
    sta.z fclose__6
    // *__filename = '\0'
    // [2281] ((char *)&__stdio_file)[fclose::$6] = '@' -- pbuc1_derefidx_vbuz1=vbuc2 
    lda #'@'
    ldy.z fclose__6
    sta __stdio_file,y
    // __stdio_filecount--;
    // [2282] __stdio_filecount#3 = -- __stdio_filecount#1 -- vbum1=_dec_vbum1 
    dec __stdio_filecount
    rts
  .segment Data
    fclose__1: .byte 0
    cbm_k_chkin1_channel: .byte 0
    cbm_k_chkin1_status: .byte 0
    cbm_k_readst1_status: .byte 0
    cbm_k_close1_channel: .byte 0
    cbm_k_readst2_status: .byte 0
    sp: .byte 0
    cbm_k_readst1_return: .byte 0
    cbm_k_readst2_return: .byte 0
    .label stream = smc_flash.smc_commit_result
}
.segment Code
  // display_action_text_reading
// void display_action_text_reading(__zp($60) char *action, __zp($5e) char *file, __zp($49) unsigned long bytes, __zp($f2) unsigned long size, __zp($c0) char bram_bank, __zp($b2) char *bram_ptr)
display_action_text_reading: {
    .label action = $60
    .label bytes = $49
    .label bram_ptr = $b2
    .label file = $5e
    .label size = $f2
    .label bram_bank = $c0
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2284] call snprintf_init
    // [1113] phi from display_action_text_reading to snprintf_init [phi:display_action_text_reading->snprintf_init]
    // [1113] phi snprintf_init::s#25 = info_text [phi:display_action_text_reading->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // display_action_text_reading::@1
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2285] printf_string::str#14 = display_action_text_reading::action#2
    // [2286] call printf_string
    // [1227] phi from display_action_text_reading::@1 to printf_string [phi:display_action_text_reading::@1->printf_string]
    // [1227] phi printf_string::putc#25 = &snputc [phi:display_action_text_reading::@1->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1227] phi printf_string::str#25 = printf_string::str#14 [phi:display_action_text_reading::@1->printf_string#1] -- register_copy 
    // [1227] phi printf_string::format_justify_left#25 = 0 [phi:display_action_text_reading::@1->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1227] phi printf_string::format_min_length#25 = 0 [phi:display_action_text_reading::@1->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [2287] phi from display_action_text_reading::@1 to display_action_text_reading::@2 [phi:display_action_text_reading::@1->display_action_text_reading::@2]
    // display_action_text_reading::@2
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2288] call printf_str
    // [1054] phi from display_action_text_reading::@2 to printf_str [phi:display_action_text_reading::@2->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:display_action_text_reading::@2->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = s [phi:display_action_text_reading::@2->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@3
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2289] printf_string::str#15 = display_action_text_reading::file#2 -- pbuz1=pbuz2 
    lda.z file
    sta.z printf_string.str
    lda.z file+1
    sta.z printf_string.str+1
    // [2290] call printf_string
    // [1227] phi from display_action_text_reading::@3 to printf_string [phi:display_action_text_reading::@3->printf_string]
    // [1227] phi printf_string::putc#25 = &snputc [phi:display_action_text_reading::@3->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1227] phi printf_string::str#25 = printf_string::str#15 [phi:display_action_text_reading::@3->printf_string#1] -- register_copy 
    // [1227] phi printf_string::format_justify_left#25 = 0 [phi:display_action_text_reading::@3->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1227] phi printf_string::format_min_length#25 = 0 [phi:display_action_text_reading::@3->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [2291] phi from display_action_text_reading::@3 to display_action_text_reading::@4 [phi:display_action_text_reading::@3->display_action_text_reading::@4]
    // display_action_text_reading::@4
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2292] call printf_str
    // [1054] phi from display_action_text_reading::@4 to printf_str [phi:display_action_text_reading::@4->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:display_action_text_reading::@4->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = s2 [phi:display_action_text_reading::@4->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s2
    sta.z printf_str.s
    lda #>@s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@5
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2293] printf_ulong::uvalue#3 = display_action_text_reading::bytes#2 -- vdum1=vduz2 
    lda.z bytes
    sta printf_ulong.uvalue
    lda.z bytes+1
    sta printf_ulong.uvalue+1
    lda.z bytes+2
    sta printf_ulong.uvalue+2
    lda.z bytes+3
    sta printf_ulong.uvalue+3
    // [2294] call printf_ulong
    // [1396] phi from display_action_text_reading::@5 to printf_ulong [phi:display_action_text_reading::@5->printf_ulong]
    // [1396] phi printf_ulong::format_zero_padding#10 = 1 [phi:display_action_text_reading::@5->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1396] phi printf_ulong::format_min_length#10 = 5 [phi:display_action_text_reading::@5->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1396] phi printf_ulong::format_radix#10 = HEXADECIMAL [phi:display_action_text_reading::@5->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1396] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#3 [phi:display_action_text_reading::@5->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2295] phi from display_action_text_reading::@5 to display_action_text_reading::@6 [phi:display_action_text_reading::@5->display_action_text_reading::@6]
    // display_action_text_reading::@6
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2296] call printf_str
    // [1054] phi from display_action_text_reading::@6 to printf_str [phi:display_action_text_reading::@6->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:display_action_text_reading::@6->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = display_action_text_reading::s2 [phi:display_action_text_reading::@6->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@7
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2297] printf_ulong::uvalue#4 = display_action_text_reading::size#2 -- vdum1=vduz2 
    lda.z size
    sta printf_ulong.uvalue
    lda.z size+1
    sta printf_ulong.uvalue+1
    lda.z size+2
    sta printf_ulong.uvalue+2
    lda.z size+3
    sta printf_ulong.uvalue+3
    // [2298] call printf_ulong
    // [1396] phi from display_action_text_reading::@7 to printf_ulong [phi:display_action_text_reading::@7->printf_ulong]
    // [1396] phi printf_ulong::format_zero_padding#10 = 1 [phi:display_action_text_reading::@7->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1396] phi printf_ulong::format_min_length#10 = 5 [phi:display_action_text_reading::@7->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1396] phi printf_ulong::format_radix#10 = HEXADECIMAL [phi:display_action_text_reading::@7->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1396] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#4 [phi:display_action_text_reading::@7->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2299] phi from display_action_text_reading::@7 to display_action_text_reading::@8 [phi:display_action_text_reading::@7->display_action_text_reading::@8]
    // display_action_text_reading::@8
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2300] call printf_str
    // [1054] phi from display_action_text_reading::@8 to printf_str [phi:display_action_text_reading::@8->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:display_action_text_reading::@8->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = display_action_text_reading::s3 [phi:display_action_text_reading::@8->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@9
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2301] printf_uchar::uvalue#5 = display_action_text_reading::bram_bank#10 -- vbum1=vbuz2 
    lda.z bram_bank
    sta printf_uchar.uvalue
    // [2302] call printf_uchar
    // [1118] phi from display_action_text_reading::@9 to printf_uchar [phi:display_action_text_reading::@9->printf_uchar]
    // [1118] phi printf_uchar::format_zero_padding#17 = 1 [phi:display_action_text_reading::@9->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1118] phi printf_uchar::format_min_length#17 = 2 [phi:display_action_text_reading::@9->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1118] phi printf_uchar::putc#17 = &snputc [phi:display_action_text_reading::@9->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1118] phi printf_uchar::format_radix#17 = HEXADECIMAL [phi:display_action_text_reading::@9->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1118] phi printf_uchar::uvalue#17 = printf_uchar::uvalue#5 [phi:display_action_text_reading::@9->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [2303] phi from display_action_text_reading::@9 to display_action_text_reading::@10 [phi:display_action_text_reading::@9->display_action_text_reading::@10]
    // display_action_text_reading::@10
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2304] call printf_str
    // [1054] phi from display_action_text_reading::@10 to printf_str [phi:display_action_text_reading::@10->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:display_action_text_reading::@10->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = s2 [phi:display_action_text_reading::@10->printf_str#1] -- pbuz1=pbuc1 
    lda #<@s2
    sta.z printf_str.s
    lda #>@s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@11
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2305] printf_uint::uvalue#2 = (unsigned int)display_action_text_reading::bram_ptr#10 -- vwum1=vwuz2 
    lda.z bram_ptr
    sta printf_uint.uvalue
    lda.z bram_ptr+1
    sta printf_uint.uvalue+1
    // [2306] call printf_uint
    // [1835] phi from display_action_text_reading::@11 to printf_uint [phi:display_action_text_reading::@11->printf_uint]
    // [1835] phi printf_uint::format_zero_padding#10 = 1 [phi:display_action_text_reading::@11->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [1835] phi printf_uint::format_min_length#10 = 4 [phi:display_action_text_reading::@11->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [1835] phi printf_uint::putc#10 = &snputc [phi:display_action_text_reading::@11->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [1835] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:display_action_text_reading::@11->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [1835] phi printf_uint::uvalue#10 = printf_uint::uvalue#2 [phi:display_action_text_reading::@11->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [2307] phi from display_action_text_reading::@11 to display_action_text_reading::@12 [phi:display_action_text_reading::@11->display_action_text_reading::@12]
    // display_action_text_reading::@12
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2308] call printf_str
    // [1054] phi from display_action_text_reading::@12 to printf_str [phi:display_action_text_reading::@12->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:display_action_text_reading::@12->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = s4 [phi:display_action_text_reading::@12->printf_str#1] -- pbuz1=pbuc1 
    lda #<s4
    sta.z printf_str.s
    lda #>s4
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_reading::@13
    // sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", action, file, bytes, size, bram_bank, bram_ptr)
    // [2309] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [2310] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [2312] call display_action_text
    // [1129] phi from display_action_text_reading::@13 to display_action_text [phi:display_action_text_reading::@13->display_action_text]
    // [1129] phi display_action_text::info_text#17 = info_text [phi:display_action_text_reading::@13->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // display_action_text_reading::@return
    // }
    // [2313] return 
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
// __mem() unsigned int fgets(__zp($73) char *ptr, __mem() unsigned int size, __zp($d6) struct $2 *stream)
fgets: {
    .label fgets__1 = $ce
    .label fgets__8 = $77
    .label fgets__9 = $75
    .label fgets__13 = $76
    .label ptr = $73
    .label stream = $d6
    // unsigned char sp = (unsigned char)stream
    // [2315] fgets::sp#0 = (char)fgets::stream#3 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_chkin(__logical)
    // [2316] fgets::cbm_k_chkin1_channel = ((char *)&__stdio_file+$40)[fgets::sp#0] -- vbum1=pbuc1_derefidx_vbum2 
    tay
    lda __stdio_file+$40,y
    sta cbm_k_chkin1_channel
    // fgets::cbm_k_chkin1
    // char status
    // [2317] fgets::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // fgets::cbm_k_readst1
    // char status
    // [2319] fgets::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2321] fgets::cbm_k_readst1_return#0 = fgets::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // fgets::cbm_k_readst1_@return
    // }
    // [2322] fgets::cbm_k_readst1_return#1 = fgets::cbm_k_readst1_return#0
    // fgets::@11
    // cbm_k_readst()
    // [2323] fgets::$1 = fgets::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z fgets__1
    // __status = cbm_k_readst()
    // [2324] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$1 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // if (__status)
    // [2325] if(0==((char *)&__stdio_file+$46)[fgets::sp#0]) goto fgets::@1 -- 0_eq_pbuc1_derefidx_vbum1_then_la1 
    lda __stdio_file+$46,y
    cmp #0
    beq __b1
    // [2326] phi from fgets::@11 fgets::@12 fgets::@5 to fgets::@return [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return]
  __b8:
    // [2326] phi fgets::return#1 = 0 [phi:fgets::@11/fgets::@12/fgets::@5->fgets::@return#0] -- vwum1=vbuc1 
    lda #<0
    sta return
    sta return+1
    // fgets::@return
    // }
    // [2327] return 
    rts
    // fgets::@1
  __b1:
    // [2328] fgets::remaining#22 = fgets::size#11 -- vwum1=vwum2 
    lda size
    sta remaining
    lda size+1
    sta remaining+1
    // [2329] phi from fgets::@1 to fgets::@2 [phi:fgets::@1->fgets::@2]
    // [2329] phi fgets::read#10 = 0 [phi:fgets::@1->fgets::@2#0] -- vwum1=vwuc1 
    lda #<0
    sta read
    sta read+1
    // [2329] phi fgets::remaining#11 = fgets::remaining#22 [phi:fgets::@1->fgets::@2#1] -- register_copy 
    // [2329] phi fgets::ptr#10 = fgets::ptr#13 [phi:fgets::@1->fgets::@2#2] -- register_copy 
    // [2329] phi from fgets::@17 fgets::@18 to fgets::@2 [phi:fgets::@17/fgets::@18->fgets::@2]
    // [2329] phi fgets::read#10 = fgets::read#1 [phi:fgets::@17/fgets::@18->fgets::@2#0] -- register_copy 
    // [2329] phi fgets::remaining#11 = fgets::remaining#1 [phi:fgets::@17/fgets::@18->fgets::@2#1] -- register_copy 
    // [2329] phi fgets::ptr#10 = fgets::ptr#14 [phi:fgets::@17/fgets::@18->fgets::@2#2] -- register_copy 
    // fgets::@2
  __b2:
    // if (!size)
    // [2330] if(0==fgets::size#11) goto fgets::@3 -- 0_eq_vwum1_then_la1 
    lda size
    ora size+1
    bne !__b3+
    jmp __b3
  !__b3:
    // fgets::@8
    // if (remaining >= 512)
    // [2331] if(fgets::remaining#11>=$200) goto fgets::@4 -- vwum1_ge_vwuc1_then_la1 
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
    // [2332] cx16_k_macptr::bytes = fgets::remaining#11 -- vbum1=vwum2 
    lda remaining
    sta cx16_k_macptr.bytes
    // [2333] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2334] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2335] cx16_k_macptr::return#4 = cx16_k_macptr::return#1
    // fgets::@15
  __b15:
    // bytes = cx16_k_macptr(remaining, ptr)
    // [2336] fgets::bytes#3 = cx16_k_macptr::return#4
    // [2337] phi from fgets::@13 fgets::@14 fgets::@15 to fgets::cbm_k_readst2 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2]
    // [2337] phi fgets::bytes#10 = fgets::bytes#1 [phi:fgets::@13/fgets::@14/fgets::@15->fgets::cbm_k_readst2#0] -- register_copy 
    // fgets::cbm_k_readst2
    // char status
    // [2338] fgets::cbm_k_readst2_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst2_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst2_status
    // return status;
    // [2340] fgets::cbm_k_readst2_return#0 = fgets::cbm_k_readst2_status -- vbum1=vbum2 
    sta cbm_k_readst2_return
    // fgets::cbm_k_readst2_@return
    // }
    // [2341] fgets::cbm_k_readst2_return#1 = fgets::cbm_k_readst2_return#0
    // fgets::@12
    // cbm_k_readst()
    // [2342] fgets::$8 = fgets::cbm_k_readst2_return#1 -- vbuz1=vbum2 
    sta.z fgets__8
    // __status = cbm_k_readst()
    // [2343] ((char *)&__stdio_file+$46)[fgets::sp#0] = fgets::$8 -- pbuc1_derefidx_vbum1=vbuz2 
    ldy sp
    sta __stdio_file+$46,y
    // __status & 0xBF
    // [2344] fgets::$9 = ((char *)&__stdio_file+$46)[fgets::sp#0] & $bf -- vbuz1=pbuc1_derefidx_vbum2_band_vbuc2 
    lda #$bf
    and __stdio_file+$46,y
    sta.z fgets__9
    // if (__status & 0xBF)
    // [2345] if(0==fgets::$9) goto fgets::@5 -- 0_eq_vbuz1_then_la1 
    beq __b5
    jmp __b8
    // fgets::@5
  __b5:
    // if (bytes == 0xFFFF)
    // [2346] if(fgets::bytes#10!=$ffff) goto fgets::@6 -- vwum1_neq_vwuc1_then_la1 
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
    // [2347] fgets::read#1 = fgets::read#10 + fgets::bytes#10 -- vwum1=vwum1_plus_vwum2 
    clc
    lda read
    adc bytes
    sta read
    lda read+1
    adc bytes+1
    sta read+1
    // ptr += bytes
    // [2348] fgets::ptr#0 = fgets::ptr#10 + fgets::bytes#10 -- pbuz1=pbuz1_plus_vwum2 
    clc
    lda.z ptr
    adc bytes
    sta.z ptr
    lda.z ptr+1
    adc bytes+1
    sta.z ptr+1
    // BYTE1(ptr)
    // [2349] fgets::$13 = byte1  fgets::ptr#0 -- vbuz1=_byte1_pbuz2 
    sta.z fgets__13
    // if (BYTE1(ptr) == 0xC0)
    // [2350] if(fgets::$13!=$c0) goto fgets::@7 -- vbuz1_neq_vbuc1_then_la1 
    lda #$c0
    cmp.z fgets__13
    bne __b7
    // fgets::@10
    // ptr -= 0x2000
    // [2351] fgets::ptr#1 = fgets::ptr#0 - $2000 -- pbuz1=pbuz1_minus_vwuc1 
    lda.z ptr
    sec
    sbc #<$2000
    sta.z ptr
    lda.z ptr+1
    sbc #>$2000
    sta.z ptr+1
    // [2352] phi from fgets::@10 fgets::@6 to fgets::@7 [phi:fgets::@10/fgets::@6->fgets::@7]
    // [2352] phi fgets::ptr#14 = fgets::ptr#1 [phi:fgets::@10/fgets::@6->fgets::@7#0] -- register_copy 
    // fgets::@7
  __b7:
    // remaining -= bytes
    // [2353] fgets::remaining#1 = fgets::remaining#11 - fgets::bytes#10 -- vwum1=vwum1_minus_vwum2 
    lda remaining
    sec
    sbc bytes
    sta remaining
    lda remaining+1
    sbc bytes+1
    sta remaining+1
    // while ((__status == 0) && ((size && remaining) || !size))
    // [2354] if(((char *)&__stdio_file+$46)[fgets::sp#0]==0) goto fgets::@16 -- pbuc1_derefidx_vbum1_eq_0_then_la1 
    ldy sp
    lda __stdio_file+$46,y
    cmp #0
    beq __b16
    // [2326] phi from fgets::@17 fgets::@7 to fgets::@return [phi:fgets::@17/fgets::@7->fgets::@return]
    // [2326] phi fgets::return#1 = fgets::read#1 [phi:fgets::@17/fgets::@7->fgets::@return#0] -- register_copy 
    rts
    // fgets::@16
  __b16:
    // while ((__status == 0) && ((size && remaining) || !size))
    // [2355] if(0==fgets::size#11) goto fgets::@17 -- 0_eq_vwum1_then_la1 
    lda size
    ora size+1
    beq __b17
    // fgets::@18
    // [2356] if(0!=fgets::remaining#1) goto fgets::@2 -- 0_neq_vwum1_then_la1 
    lda remaining
    ora remaining+1
    beq !__b2+
    jmp __b2
  !__b2:
    // fgets::@17
  __b17:
    // [2357] if(0==fgets::size#11) goto fgets::@2 -- 0_eq_vwum1_then_la1 
    lda size
    ora size+1
    bne !__b2+
    jmp __b2
  !__b2:
    rts
    // fgets::@4
  __b4:
    // cx16_k_macptr(512, ptr)
    // [2358] cx16_k_macptr::bytes = $200 -- vbum1=vwuc1 
    lda #<$200
    sta cx16_k_macptr.bytes
    // [2359] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2360] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2361] cx16_k_macptr::return#3 = cx16_k_macptr::return#1
    // fgets::@14
    // bytes = cx16_k_macptr(512, ptr)
    // [2362] fgets::bytes#2 = cx16_k_macptr::return#3
    jmp __b15
    // fgets::@3
  __b3:
    // cx16_k_macptr(0, ptr)
    // [2363] cx16_k_macptr::bytes = 0 -- vbum1=vbuc1 
    lda #0
    sta cx16_k_macptr.bytes
    // [2364] cx16_k_macptr::buffer = (void *)fgets::ptr#10 -- pvoz1=pvoz2 
    lda.z ptr
    sta.z cx16_k_macptr.buffer
    lda.z ptr+1
    sta.z cx16_k_macptr.buffer+1
    // [2365] call cx16_k_macptr
    jsr cx16_k_macptr
    // [2366] cx16_k_macptr::return#2 = cx16_k_macptr::return#1
    // fgets::@13
    // bytes = cx16_k_macptr(0, ptr)
    // [2367] fgets::bytes#1 = cx16_k_macptr::return#2
    jmp __b15
  .segment Data
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
    size: .word 0
}
.segment Code
  // rom_compare
// __zp($5e) unsigned int rom_compare(__zp($ac) char bank_ram, __zp($6d) char *ptr_ram, __zp($c3) unsigned long rom_compare_address, __zp($7e) unsigned int rom_compare_size)
rom_compare: {
    .label rom_compare__5 = $29
    .label rom_bank1_rom_compare__0 = $75
    .label rom_bank1_rom_compare__1 = $76
    .label rom_bank1_rom_compare__2 = $60
    .label rom_ptr1_rom_compare__0 = $56
    .label rom_ptr1_rom_compare__2 = $56
    .label rom_bank1_bank_unshifted = $60
    .label rom_bank1_return = $44
    .label rom_ptr1_return = $56
    .label ptr_rom = $56
    .label ptr_ram = $6d
    .label compared_bytes = $66
    /// Holds the amount of bytes actually verified between the ROM and the RAM.
    .label equal_bytes = $5e
    .label bank_ram = $ac
    .label rom_compare_address = $c3
    .label return = $5e
    .label bank_ram_1 = $dc
    .label rom_compare_size = $7e
    // rom_compare::bank_set_bram1
    // BRAM = bank
    // [2369] BRAM = rom_compare::bank_set_bram1_bank#0 -- vbuz1=vbum2 
    lda bank_set_bram1_bank
    sta.z BRAM
    // rom_compare::rom_bank1
    // BYTE2(address)
    // [2370] rom_compare::rom_bank1_$0 = byte2  rom_compare::rom_compare_address#3 -- vbuz1=_byte2_vduz2 
    lda.z rom_compare_address+2
    sta.z rom_bank1_rom_compare__0
    // BYTE1(address)
    // [2371] rom_compare::rom_bank1_$1 = byte1  rom_compare::rom_compare_address#3 -- vbuz1=_byte1_vduz2 
    lda.z rom_compare_address+1
    sta.z rom_bank1_rom_compare__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2372] rom_compare::rom_bank1_$2 = rom_compare::rom_bank1_$0 w= rom_compare::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_compare__0
    sta.z rom_bank1_rom_compare__2+1
    lda.z rom_bank1_rom_compare__1
    sta.z rom_bank1_rom_compare__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2373] rom_compare::rom_bank1_bank_unshifted#0 = rom_compare::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2374] rom_compare::rom_bank1_return#0 = byte1  rom_compare::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwuz2 
    lda.z rom_bank1_bank_unshifted+1
    sta.z rom_bank1_return
    // rom_compare::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2375] rom_compare::rom_ptr1_$2 = (unsigned int)rom_compare::rom_compare_address#3 -- vwuz1=_word_vduz2 
    lda.z rom_compare_address
    sta.z rom_ptr1_rom_compare__2
    lda.z rom_compare_address+1
    sta.z rom_ptr1_rom_compare__2+1
    // [2376] rom_compare::rom_ptr1_$0 = rom_compare::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_compare__0
    and #<$3fff
    sta.z rom_ptr1_rom_compare__0
    lda.z rom_ptr1_rom_compare__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_compare__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2377] rom_compare::rom_ptr1_return#0 = rom_compare::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_compare::bank_set_brom1
    // BROM = bank
    // [2378] BROM = rom_compare::rom_bank1_return#0 -- vbuz1=vbuz2 
    lda.z rom_bank1_return
    sta.z BROM
    // [2379] rom_compare::ptr_rom#9 = (char *)rom_compare::rom_ptr1_return#0
    // [2380] phi from rom_compare::bank_set_brom1 to rom_compare::@1 [phi:rom_compare::bank_set_brom1->rom_compare::@1]
    // [2380] phi rom_compare::equal_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#0] -- vwuz1=vwuc1 
    lda #<0
    sta.z equal_bytes
    sta.z equal_bytes+1
    // [2380] phi rom_compare::ptr_ram#4 = rom_compare::ptr_ram#10 [phi:rom_compare::bank_set_brom1->rom_compare::@1#1] -- register_copy 
    // [2380] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#9 [phi:rom_compare::bank_set_brom1->rom_compare::@1#2] -- register_copy 
    // [2380] phi rom_compare::compared_bytes#2 = 0 [phi:rom_compare::bank_set_brom1->rom_compare::@1#3] -- vwuz1=vwuc1 
    sta.z compared_bytes
    sta.z compared_bytes+1
    // rom_compare::@1
  __b1:
    // while (compared_bytes < rom_compare_size)
    // [2381] if(rom_compare::compared_bytes#2<rom_compare::rom_compare_size#11) goto rom_compare::@2 -- vwuz1_lt_vwuz2_then_la1 
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
    // [2382] return 
    rts
    // rom_compare::@2
  __b2:
    // rom_byte_compare(ptr_rom, *ptr_ram)
    // [2383] rom_byte_compare::ptr_rom#0 = rom_compare::ptr_rom#2
    // [2384] rom_byte_compare::value#0 = *rom_compare::ptr_ram#4 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (ptr_ram),y
    sta.z rom_byte_compare.value
    // [2385] call rom_byte_compare
    jsr rom_byte_compare
    // [2386] rom_byte_compare::return#2 = rom_byte_compare::return#0
    // rom_compare::@5
    // [2387] rom_compare::$5 = rom_byte_compare::return#2
    // if (rom_byte_compare(ptr_rom, *ptr_ram))
    // [2388] if(0==rom_compare::$5) goto rom_compare::@3 -- 0_eq_vbuz1_then_la1 
    lda.z rom_compare__5
    beq __b3
    // rom_compare::@4
    // equal_bytes++;
    // [2389] rom_compare::equal_bytes#1 = ++ rom_compare::equal_bytes#2 -- vwuz1=_inc_vwuz1 
    inc.z equal_bytes
    bne !+
    inc.z equal_bytes+1
  !:
    // [2390] phi from rom_compare::@4 rom_compare::@5 to rom_compare::@3 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3]
    // [2390] phi rom_compare::equal_bytes#6 = rom_compare::equal_bytes#1 [phi:rom_compare::@4/rom_compare::@5->rom_compare::@3#0] -- register_copy 
    // rom_compare::@3
  __b3:
    // ptr_rom++;
    // [2391] rom_compare::ptr_rom#1 = ++ rom_compare::ptr_rom#2 -- pbuz1=_inc_pbuz1 
    inc.z ptr_rom
    bne !+
    inc.z ptr_rom+1
  !:
    // ptr_ram++;
    // [2392] rom_compare::ptr_ram#0 = ++ rom_compare::ptr_ram#4 -- pbuz1=_inc_pbuz1 
    inc.z ptr_ram
    bne !+
    inc.z ptr_ram+1
  !:
    // compared_bytes++;
    // [2393] rom_compare::compared_bytes#1 = ++ rom_compare::compared_bytes#2 -- vwuz1=_inc_vwuz1 
    inc.z compared_bytes
    bne !+
    inc.z compared_bytes+1
  !:
    // [2380] phi from rom_compare::@3 to rom_compare::@1 [phi:rom_compare::@3->rom_compare::@1]
    // [2380] phi rom_compare::equal_bytes#2 = rom_compare::equal_bytes#6 [phi:rom_compare::@3->rom_compare::@1#0] -- register_copy 
    // [2380] phi rom_compare::ptr_ram#4 = rom_compare::ptr_ram#0 [phi:rom_compare::@3->rom_compare::@1#1] -- register_copy 
    // [2380] phi rom_compare::ptr_rom#2 = rom_compare::ptr_rom#1 [phi:rom_compare::@3->rom_compare::@1#2] -- register_copy 
    // [2380] phi rom_compare::compared_bytes#2 = rom_compare::compared_bytes#1 [phi:rom_compare::@3->rom_compare::@1#3] -- register_copy 
    jmp __b1
  .segment Data
    bank_set_bram1_bank: .byte 0
}
.segment Code
  // ultoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void ultoa(__mem() unsigned long value, __zp($3d) char *buffer, __mem() char radix)
ultoa: {
    .label ultoa__4 = $44
    .label ultoa__10 = $38
    .label ultoa__11 = $51
    .label buffer = $3d
    .label digit_values = $58
    // if(radix==DECIMAL)
    // [2394] if(ultoa::radix#0==DECIMAL) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // ultoa::@2
    // if(radix==HEXADECIMAL)
    // [2395] if(ultoa::radix#0==HEXADECIMAL) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // ultoa::@3
    // if(radix==OCTAL)
    // [2396] if(ultoa::radix#0==OCTAL) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // ultoa::@4
    // if(radix==BINARY)
    // [2397] if(ultoa::radix#0==BINARY) goto ultoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // ultoa::@5
    // *buffer++ = 'e'
    // [2398] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2399] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2400] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2401] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // ultoa::@return
    // }
    // [2402] return 
    rts
    // [2403] phi from ultoa to ultoa::@1 [phi:ultoa->ultoa::@1]
  __b2:
    // [2403] phi ultoa::digit_values#8 = RADIX_DECIMAL_VALUES_LONG [phi:ultoa->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2403] phi ultoa::max_digits#7 = $a [phi:ultoa->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$a
    sta max_digits
    jmp __b1
    // [2403] phi from ultoa::@2 to ultoa::@1 [phi:ultoa::@2->ultoa::@1]
  __b3:
    // [2403] phi ultoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES_LONG [phi:ultoa::@2->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES_LONG
    sta.z digit_values+1
    // [2403] phi ultoa::max_digits#7 = 8 [phi:ultoa::@2->ultoa::@1#1] -- vbum1=vbuc1 
    lda #8
    sta max_digits
    jmp __b1
    // [2403] phi from ultoa::@3 to ultoa::@1 [phi:ultoa::@3->ultoa::@1]
  __b4:
    // [2403] phi ultoa::digit_values#8 = RADIX_OCTAL_VALUES_LONG [phi:ultoa::@3->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_OCTAL_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES_LONG
    sta.z digit_values+1
    // [2403] phi ultoa::max_digits#7 = $b [phi:ultoa::@3->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$b
    sta max_digits
    jmp __b1
    // [2403] phi from ultoa::@4 to ultoa::@1 [phi:ultoa::@4->ultoa::@1]
  __b5:
    // [2403] phi ultoa::digit_values#8 = RADIX_BINARY_VALUES_LONG [phi:ultoa::@4->ultoa::@1#0] -- pduz1=pduc1 
    lda #<RADIX_BINARY_VALUES_LONG
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES_LONG
    sta.z digit_values+1
    // [2403] phi ultoa::max_digits#7 = $20 [phi:ultoa::@4->ultoa::@1#1] -- vbum1=vbuc1 
    lda #$20
    sta max_digits
    // ultoa::@1
  __b1:
    // [2404] phi from ultoa::@1 to ultoa::@6 [phi:ultoa::@1->ultoa::@6]
    // [2404] phi ultoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:ultoa::@1->ultoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2404] phi ultoa::started#2 = 0 [phi:ultoa::@1->ultoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [2404] phi ultoa::value#2 = ultoa::value#1 [phi:ultoa::@1->ultoa::@6#2] -- register_copy 
    // [2404] phi ultoa::digit#2 = 0 [phi:ultoa::@1->ultoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // ultoa::@6
  __b6:
    // max_digits-1
    // [2405] ultoa::$4 = ultoa::max_digits#7 - 1 -- vbuz1=vbum2_minus_1 
    ldx max_digits
    dex
    stx.z ultoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2406] if(ultoa::digit#2<ultoa::$4) goto ultoa::@7 -- vbum1_lt_vbuz2_then_la1 
    lda digit
    cmp.z ultoa__4
    bcc __b7
    // ultoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2407] ultoa::$11 = (char)ultoa::value#2 -- vbuz1=_byte_vdum2 
    lda value
    sta.z ultoa__11
    // [2408] *ultoa::buffer#11 = DIGITS[ultoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2409] ultoa::buffer#3 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2410] *ultoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // ultoa::@7
  __b7:
    // unsigned long digit_value = digit_values[digit]
    // [2411] ultoa::$10 = ultoa::digit#2 << 2 -- vbuz1=vbum2_rol_2 
    lda digit
    asl
    asl
    sta.z ultoa__10
    // [2412] ultoa::digit_value#0 = ultoa::digit_values#8[ultoa::$10] -- vdum1=pduz2_derefidx_vbuz3 
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
    // [2413] if(0!=ultoa::started#2) goto ultoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // ultoa::@12
    // [2414] if(ultoa::value#2>=ultoa::digit_value#0) goto ultoa::@10 -- vdum1_ge_vdum2_then_la1 
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
    // [2415] phi from ultoa::@12 to ultoa::@9 [phi:ultoa::@12->ultoa::@9]
    // [2415] phi ultoa::buffer#14 = ultoa::buffer#11 [phi:ultoa::@12->ultoa::@9#0] -- register_copy 
    // [2415] phi ultoa::started#4 = ultoa::started#2 [phi:ultoa::@12->ultoa::@9#1] -- register_copy 
    // [2415] phi ultoa::value#6 = ultoa::value#2 [phi:ultoa::@12->ultoa::@9#2] -- register_copy 
    // ultoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2416] ultoa::digit#1 = ++ ultoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [2404] phi from ultoa::@9 to ultoa::@6 [phi:ultoa::@9->ultoa::@6]
    // [2404] phi ultoa::buffer#11 = ultoa::buffer#14 [phi:ultoa::@9->ultoa::@6#0] -- register_copy 
    // [2404] phi ultoa::started#2 = ultoa::started#4 [phi:ultoa::@9->ultoa::@6#1] -- register_copy 
    // [2404] phi ultoa::value#2 = ultoa::value#6 [phi:ultoa::@9->ultoa::@6#2] -- register_copy 
    // [2404] phi ultoa::digit#2 = ultoa::digit#1 [phi:ultoa::@9->ultoa::@6#3] -- register_copy 
    jmp __b6
    // ultoa::@10
  __b10:
    // ultoa_append(buffer++, value, digit_value)
    // [2417] ultoa_append::buffer#0 = ultoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z ultoa_append.buffer
    lda.z buffer+1
    sta.z ultoa_append.buffer+1
    // [2418] ultoa_append::value#0 = ultoa::value#2
    // [2419] ultoa_append::sub#0 = ultoa::digit_value#0
    // [2420] call ultoa_append
    // [2903] phi from ultoa::@10 to ultoa_append [phi:ultoa::@10->ultoa_append]
    jsr ultoa_append
    // ultoa_append(buffer++, value, digit_value)
    // [2421] ultoa_append::return#0 = ultoa_append::value#2
    // ultoa::@11
    // value = ultoa_append(buffer++, value, digit_value)
    // [2422] ultoa::value#0 = ultoa_append::return#0
    // value = ultoa_append(buffer++, value, digit_value);
    // [2423] ultoa::buffer#4 = ++ ultoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2415] phi from ultoa::@11 to ultoa::@9 [phi:ultoa::@11->ultoa::@9]
    // [2415] phi ultoa::buffer#14 = ultoa::buffer#4 [phi:ultoa::@11->ultoa::@9#0] -- register_copy 
    // [2415] phi ultoa::started#4 = 1 [phi:ultoa::@11->ultoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [2415] phi ultoa::value#6 = ultoa::value#0 [phi:ultoa::@11->ultoa::@9#2] -- register_copy 
    jmp __b9
  .segment Data
    digit_value: .dword 0
    digit: .byte 0
    .label value = printf_ulong.uvalue
    .label radix = printf_ulong.format_radix
    started: .byte 0
    max_digits: .byte 0
}
.segment Code
  // display_action_text_flashed
// void display_action_text_flashed(__zp($e3) unsigned long bytes, __zp($3f) char *chip)
display_action_text_flashed: {
    .label bytes = $e3
    .label chip = $3f
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2425] call snprintf_init
    // [1113] phi from display_action_text_flashed to snprintf_init [phi:display_action_text_flashed->snprintf_init]
    // [1113] phi snprintf_init::s#25 = info_text [phi:display_action_text_flashed->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [2426] phi from display_action_text_flashed to display_action_text_flashed::@1 [phi:display_action_text_flashed->display_action_text_flashed::@1]
    // display_action_text_flashed::@1
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2427] call printf_str
    // [1054] phi from display_action_text_flashed::@1 to printf_str [phi:display_action_text_flashed::@1->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:display_action_text_flashed::@1->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = display_action_text_flashed::s [phi:display_action_text_flashed::@1->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashed::@2
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2428] printf_ulong::uvalue#2 = display_action_text_flashed::bytes#2 -- vdum1=vduz2 
    lda.z bytes
    sta printf_ulong.uvalue
    lda.z bytes+1
    sta printf_ulong.uvalue+1
    lda.z bytes+2
    sta printf_ulong.uvalue+2
    lda.z bytes+3
    sta printf_ulong.uvalue+3
    // [2429] call printf_ulong
    // [1396] phi from display_action_text_flashed::@2 to printf_ulong [phi:display_action_text_flashed::@2->printf_ulong]
    // [1396] phi printf_ulong::format_zero_padding#10 = 0 [phi:display_action_text_flashed::@2->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1396] phi printf_ulong::format_min_length#10 = 0 [phi:display_action_text_flashed::@2->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1396] phi printf_ulong::format_radix#10 = DECIMAL [phi:display_action_text_flashed::@2->printf_ulong#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1396] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#2 [phi:display_action_text_flashed::@2->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2430] phi from display_action_text_flashed::@2 to display_action_text_flashed::@3 [phi:display_action_text_flashed::@2->display_action_text_flashed::@3]
    // display_action_text_flashed::@3
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2431] call printf_str
    // [1054] phi from display_action_text_flashed::@3 to printf_str [phi:display_action_text_flashed::@3->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:display_action_text_flashed::@3->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = display_action_text_flashed::s1 [phi:display_action_text_flashed::@3->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashed::@4
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2432] printf_string::str#13 = display_action_text_flashed::chip#2 -- pbuz1=pbuz2 
    lda.z chip
    sta.z printf_string.str
    lda.z chip+1
    sta.z printf_string.str+1
    // [2433] call printf_string
    // [1227] phi from display_action_text_flashed::@4 to printf_string [phi:display_action_text_flashed::@4->printf_string]
    // [1227] phi printf_string::putc#25 = &snputc [phi:display_action_text_flashed::@4->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1227] phi printf_string::str#25 = printf_string::str#13 [phi:display_action_text_flashed::@4->printf_string#1] -- register_copy 
    // [1227] phi printf_string::format_justify_left#25 = 0 [phi:display_action_text_flashed::@4->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1227] phi printf_string::format_min_length#25 = 0 [phi:display_action_text_flashed::@4->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [2434] phi from display_action_text_flashed::@4 to display_action_text_flashed::@5 [phi:display_action_text_flashed::@4->display_action_text_flashed::@5]
    // display_action_text_flashed::@5
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2435] call printf_str
    // [1054] phi from display_action_text_flashed::@5 to printf_str [phi:display_action_text_flashed::@5->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:display_action_text_flashed::@5->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = s5 [phi:display_action_text_flashed::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashed::@6
    // sprintf(info_text, "Flashed %u bytes from RAM -> %s ... ", bytes, chip)
    // [2436] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [2437] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [2439] call display_action_text
    // [1129] phi from display_action_text_flashed::@6 to display_action_text [phi:display_action_text_flashed::@6->display_action_text]
    // [1129] phi display_action_text::info_text#17 = info_text [phi:display_action_text_flashed::@6->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // display_action_text_flashed::@return
    // }
    // [2440] return 
    rts
  .segment Data
    s: .text "Flashed "
    .byte 0
    s1: .text " bytes from RAM -> "
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
// void rom_sector_erase(__zp($e3) unsigned long address)
rom_sector_erase: {
    .label rom_ptr1_rom_sector_erase__0 = $2d
    .label rom_ptr1_rom_sector_erase__2 = $2d
    .label rom_ptr1_return = $2d
    .label rom_chip_address = $5a
    .label address = $e3
    // rom_sector_erase::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2442] rom_sector_erase::rom_ptr1_$2 = (unsigned int)rom_sector_erase::address#0 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_sector_erase__2
    lda.z address+1
    sta.z rom_ptr1_rom_sector_erase__2+1
    // [2443] rom_sector_erase::rom_ptr1_$0 = rom_sector_erase::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_sector_erase__0
    and #<$3fff
    sta.z rom_ptr1_rom_sector_erase__0
    lda.z rom_ptr1_rom_sector_erase__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_sector_erase__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2444] rom_sector_erase::rom_ptr1_return#0 = rom_sector_erase::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_sector_erase::@1
    // unsigned long rom_chip_address = address & ROM_CHIP_MASK
    // [2445] rom_sector_erase::rom_chip_address#0 = rom_sector_erase::address#0 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [2446] rom_unlock::address#0 = rom_sector_erase::rom_chip_address#0 + $5555 -- vduz1=vduz1_plus_vwuc1 
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
    // [2447] call rom_unlock
    // [2043] phi from rom_sector_erase::@1 to rom_unlock [phi:rom_sector_erase::@1->rom_unlock]
    // [2043] phi rom_unlock::unlock_code#5 = $80 [phi:rom_sector_erase::@1->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$80
    sta.z rom_unlock.unlock_code
    // [2043] phi rom_unlock::address#5 = rom_unlock::address#0 [phi:rom_sector_erase::@1->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@2
    // rom_unlock(address, 0x30)
    // [2448] rom_unlock::address#1 = rom_sector_erase::address#0 -- vduz1=vduz2 
    lda.z address
    sta.z rom_unlock.address
    lda.z address+1
    sta.z rom_unlock.address+1
    lda.z address+2
    sta.z rom_unlock.address+2
    lda.z address+3
    sta.z rom_unlock.address+3
    // [2449] call rom_unlock
    // [2043] phi from rom_sector_erase::@2 to rom_unlock [phi:rom_sector_erase::@2->rom_unlock]
    // [2043] phi rom_unlock::unlock_code#5 = $30 [phi:rom_sector_erase::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$30
    sta.z rom_unlock.unlock_code
    // [2043] phi rom_unlock::address#5 = rom_unlock::address#1 [phi:rom_sector_erase::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_sector_erase::@3
    // rom_wait(ptr_rom)
    // [2450] rom_wait::ptr_rom#0 = (char *)rom_sector_erase::rom_ptr1_return#0
    // [2451] call rom_wait
    // [2910] phi from rom_sector_erase::@3 to rom_wait [phi:rom_sector_erase::@3->rom_wait]
    // [2910] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#0 [phi:rom_sector_erase::@3->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_sector_erase::@return
    // }
    // [2452] return 
    rts
}
  // display_action_text_flashing
// void display_action_text_flashing(__zp($52) unsigned long bytes, __zp($d8) char *chip, __zp($cc) char bram_bank, __zp($da) char *bram_ptr, __zp($78) unsigned long address)
display_action_text_flashing: {
    .label bram_ptr = $da
    .label address = $78
    .label bram_bank = $cc
    .label bytes = $52
    .label chip = $d8
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2454] call snprintf_init
    // [1113] phi from display_action_text_flashing to snprintf_init [phi:display_action_text_flashing->snprintf_init]
    // [1113] phi snprintf_init::s#25 = info_text [phi:display_action_text_flashing->snprintf_init#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z snprintf_init.s
    lda #>info_text
    sta.z snprintf_init.s+1
    jsr snprintf_init
    // [2455] phi from display_action_text_flashing to display_action_text_flashing::@1 [phi:display_action_text_flashing->display_action_text_flashing::@1]
    // display_action_text_flashing::@1
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2456] call printf_str
    // [1054] phi from display_action_text_flashing::@1 to printf_str [phi:display_action_text_flashing::@1->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:display_action_text_flashing::@1->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = display_action_text_flashing::s [phi:display_action_text_flashing::@1->printf_str#1] -- pbuz1=pbuc1 
    lda #<s
    sta.z printf_str.s
    lda #>s
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@2
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2457] printf_ulong::uvalue#0 = display_action_text_flashing::bytes#2 -- vdum1=vduz2 
    lda.z bytes
    sta printf_ulong.uvalue
    lda.z bytes+1
    sta printf_ulong.uvalue+1
    lda.z bytes+2
    sta printf_ulong.uvalue+2
    lda.z bytes+3
    sta printf_ulong.uvalue+3
    // [2458] call printf_ulong
    // [1396] phi from display_action_text_flashing::@2 to printf_ulong [phi:display_action_text_flashing::@2->printf_ulong]
    // [1396] phi printf_ulong::format_zero_padding#10 = 0 [phi:display_action_text_flashing::@2->printf_ulong#0] -- vbum1=vbuc1 
    lda #0
    sta printf_ulong.format_zero_padding
    // [1396] phi printf_ulong::format_min_length#10 = 0 [phi:display_action_text_flashing::@2->printf_ulong#1] -- vbum1=vbuc1 
    sta printf_ulong.format_min_length
    // [1396] phi printf_ulong::format_radix#10 = DECIMAL [phi:display_action_text_flashing::@2->printf_ulong#2] -- vbum1=vbuc1 
    lda #DECIMAL
    sta printf_ulong.format_radix
    // [1396] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#0 [phi:display_action_text_flashing::@2->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2459] phi from display_action_text_flashing::@2 to display_action_text_flashing::@3 [phi:display_action_text_flashing::@2->display_action_text_flashing::@3]
    // display_action_text_flashing::@3
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2460] call printf_str
    // [1054] phi from display_action_text_flashing::@3 to printf_str [phi:display_action_text_flashing::@3->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:display_action_text_flashing::@3->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = display_action_text_flashing::s1 [phi:display_action_text_flashing::@3->printf_str#1] -- pbuz1=pbuc1 
    lda #<s1
    sta.z printf_str.s
    lda #>s1
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@4
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2461] printf_uchar::uvalue#4 = display_action_text_flashing::bram_bank#2 -- vbum1=vbuz2 
    lda.z bram_bank
    sta printf_uchar.uvalue
    // [2462] call printf_uchar
    // [1118] phi from display_action_text_flashing::@4 to printf_uchar [phi:display_action_text_flashing::@4->printf_uchar]
    // [1118] phi printf_uchar::format_zero_padding#17 = 1 [phi:display_action_text_flashing::@4->printf_uchar#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uchar.format_zero_padding
    // [1118] phi printf_uchar::format_min_length#17 = 2 [phi:display_action_text_flashing::@4->printf_uchar#1] -- vbum1=vbuc1 
    lda #2
    sta printf_uchar.format_min_length
    // [1118] phi printf_uchar::putc#17 = &snputc [phi:display_action_text_flashing::@4->printf_uchar#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uchar.putc
    lda #>snputc
    sta.z printf_uchar.putc+1
    // [1118] phi printf_uchar::format_radix#17 = HEXADECIMAL [phi:display_action_text_flashing::@4->printf_uchar#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uchar.format_radix
    // [1118] phi printf_uchar::uvalue#17 = printf_uchar::uvalue#4 [phi:display_action_text_flashing::@4->printf_uchar#4] -- register_copy 
    jsr printf_uchar
    // [2463] phi from display_action_text_flashing::@4 to display_action_text_flashing::@5 [phi:display_action_text_flashing::@4->display_action_text_flashing::@5]
    // display_action_text_flashing::@5
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2464] call printf_str
    // [1054] phi from display_action_text_flashing::@5 to printf_str [phi:display_action_text_flashing::@5->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:display_action_text_flashing::@5->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = s2 [phi:display_action_text_flashing::@5->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@6
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2465] printf_uint::uvalue#1 = (unsigned int)display_action_text_flashing::bram_ptr#2 -- vwum1=vwuz2 
    lda.z bram_ptr
    sta printf_uint.uvalue
    lda.z bram_ptr+1
    sta printf_uint.uvalue+1
    // [2466] call printf_uint
    // [1835] phi from display_action_text_flashing::@6 to printf_uint [phi:display_action_text_flashing::@6->printf_uint]
    // [1835] phi printf_uint::format_zero_padding#10 = 1 [phi:display_action_text_flashing::@6->printf_uint#0] -- vbum1=vbuc1 
    lda #1
    sta printf_uint.format_zero_padding
    // [1835] phi printf_uint::format_min_length#10 = 4 [phi:display_action_text_flashing::@6->printf_uint#1] -- vbum1=vbuc1 
    lda #4
    sta printf_uint.format_min_length
    // [1835] phi printf_uint::putc#10 = &snputc [phi:display_action_text_flashing::@6->printf_uint#2] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_uint.putc
    lda #>snputc
    sta.z printf_uint.putc+1
    // [1835] phi printf_uint::format_radix#10 = HEXADECIMAL [phi:display_action_text_flashing::@6->printf_uint#3] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_uint.format_radix
    // [1835] phi printf_uint::uvalue#10 = printf_uint::uvalue#1 [phi:display_action_text_flashing::@6->printf_uint#4] -- register_copy 
    jsr printf_uint
    // [2467] phi from display_action_text_flashing::@6 to display_action_text_flashing::@7 [phi:display_action_text_flashing::@6->display_action_text_flashing::@7]
    // display_action_text_flashing::@7
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2468] call printf_str
    // [1054] phi from display_action_text_flashing::@7 to printf_str [phi:display_action_text_flashing::@7->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:display_action_text_flashing::@7->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = display_action_text_flashing::s3 [phi:display_action_text_flashing::@7->printf_str#1] -- pbuz1=pbuc1 
    lda #<s3
    sta.z printf_str.s
    lda #>s3
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@8
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2469] printf_string::str#12 = display_action_text_flashing::chip#10 -- pbuz1=pbuz2 
    lda.z chip
    sta.z printf_string.str
    lda.z chip+1
    sta.z printf_string.str+1
    // [2470] call printf_string
    // [1227] phi from display_action_text_flashing::@8 to printf_string [phi:display_action_text_flashing::@8->printf_string]
    // [1227] phi printf_string::putc#25 = &snputc [phi:display_action_text_flashing::@8->printf_string#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_string.putc
    lda #>snputc
    sta.z printf_string.putc+1
    // [1227] phi printf_string::str#25 = printf_string::str#12 [phi:display_action_text_flashing::@8->printf_string#1] -- register_copy 
    // [1227] phi printf_string::format_justify_left#25 = 0 [phi:display_action_text_flashing::@8->printf_string#2] -- vbum1=vbuc1 
    lda #0
    sta printf_string.format_justify_left
    // [1227] phi printf_string::format_min_length#25 = 0 [phi:display_action_text_flashing::@8->printf_string#3] -- vbum1=vbuc1 
    sta printf_string.format_min_length
    jsr printf_string
    // [2471] phi from display_action_text_flashing::@8 to display_action_text_flashing::@9 [phi:display_action_text_flashing::@8->display_action_text_flashing::@9]
    // display_action_text_flashing::@9
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2472] call printf_str
    // [1054] phi from display_action_text_flashing::@9 to printf_str [phi:display_action_text_flashing::@9->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:display_action_text_flashing::@9->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = s2 [phi:display_action_text_flashing::@9->printf_str#1] -- pbuz1=pbuc1 
    lda #<s2
    sta.z printf_str.s
    lda #>s2
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@10
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2473] printf_ulong::uvalue#1 = display_action_text_flashing::address#10 -- vdum1=vduz2 
    lda.z address
    sta printf_ulong.uvalue
    lda.z address+1
    sta printf_ulong.uvalue+1
    lda.z address+2
    sta printf_ulong.uvalue+2
    lda.z address+3
    sta printf_ulong.uvalue+3
    // [2474] call printf_ulong
    // [1396] phi from display_action_text_flashing::@10 to printf_ulong [phi:display_action_text_flashing::@10->printf_ulong]
    // [1396] phi printf_ulong::format_zero_padding#10 = 1 [phi:display_action_text_flashing::@10->printf_ulong#0] -- vbum1=vbuc1 
    lda #1
    sta printf_ulong.format_zero_padding
    // [1396] phi printf_ulong::format_min_length#10 = 5 [phi:display_action_text_flashing::@10->printf_ulong#1] -- vbum1=vbuc1 
    lda #5
    sta printf_ulong.format_min_length
    // [1396] phi printf_ulong::format_radix#10 = HEXADECIMAL [phi:display_action_text_flashing::@10->printf_ulong#2] -- vbum1=vbuc1 
    lda #HEXADECIMAL
    sta printf_ulong.format_radix
    // [1396] phi printf_ulong::uvalue#10 = printf_ulong::uvalue#1 [phi:display_action_text_flashing::@10->printf_ulong#3] -- register_copy 
    jsr printf_ulong
    // [2475] phi from display_action_text_flashing::@10 to display_action_text_flashing::@11 [phi:display_action_text_flashing::@10->display_action_text_flashing::@11]
    // display_action_text_flashing::@11
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2476] call printf_str
    // [1054] phi from display_action_text_flashing::@11 to printf_str [phi:display_action_text_flashing::@11->printf_str]
    // [1054] phi printf_str::putc#75 = &snputc [phi:display_action_text_flashing::@11->printf_str#0] -- pprz1=pprc1 
    lda #<snputc
    sta.z printf_str.putc
    lda #>snputc
    sta.z printf_str.putc+1
    // [1054] phi printf_str::s#75 = s5 [phi:display_action_text_flashing::@11->printf_str#1] -- pbuz1=pbuc1 
    lda #<s5
    sta.z printf_str.s
    lda #>s5
    sta.z printf_str.s+1
    jsr printf_str
    // display_action_text_flashing::@12
    // sprintf(info_text, "Flashing %u bytes from RAM:%02x:%04p -> %s:%05x ... ", bytes, bram_bank, bram_ptr, chip, address)
    // [2477] stackpush(char) = 0 -- _stackpushbyte_=vbuc1 
    lda #0
    pha
    // [2478] callexecute snputc  -- call_vprc1 
    jsr snputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_action_text(info_text)
    // [2480] call display_action_text
    // [1129] phi from display_action_text_flashing::@12 to display_action_text [phi:display_action_text_flashing::@12->display_action_text]
    // [1129] phi display_action_text::info_text#17 = info_text [phi:display_action_text_flashing::@12->display_action_text#0] -- pbuz1=pbuc1 
    lda #<info_text
    sta.z display_action_text.info_text
    lda #>info_text
    sta.z display_action_text.info_text+1
    jsr display_action_text
    // display_action_text_flashing::@return
    // }
    // [2481] return 
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
// unsigned long rom_write(__zp($76) char flash_ram_bank, __zp($6b) char *flash_ram_address, __zp($6f) unsigned long flash_rom_address, unsigned int flash_rom_size)
rom_write: {
    .label rom_chip_address = $78
    .label flash_rom_address = $6f
    .label flash_ram_address = $6b
    .label flashed_bytes = $62
    .label flash_ram_bank = $76
    // unsigned long rom_chip_address = flash_rom_address & ROM_CHIP_MASK
    // [2482] rom_write::rom_chip_address#0 = rom_write::flash_rom_address#1 & $380000 -- vduz1=vduz2_band_vduc1 
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
    // [2483] BRAM = rom_write::flash_ram_bank#0 -- vbuz1=vbuz2 
    lda.z flash_ram_bank
    sta.z BRAM
    // [2484] phi from rom_write::bank_set_bram1 to rom_write::@1 [phi:rom_write::bank_set_bram1->rom_write::@1]
    // [2484] phi rom_write::flash_ram_address#2 = rom_write::flash_ram_address#1 [phi:rom_write::bank_set_bram1->rom_write::@1#0] -- register_copy 
    // [2484] phi rom_write::flash_rom_address#3 = rom_write::flash_rom_address#1 [phi:rom_write::bank_set_bram1->rom_write::@1#1] -- register_copy 
    // [2484] phi rom_write::flashed_bytes#2 = 0 [phi:rom_write::bank_set_bram1->rom_write::@1#2] -- vduz1=vduc1 
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
    // [2485] if(rom_write::flashed_bytes#2<ROM_PROGRESS_CELL) goto rom_write::@2 -- vduz1_lt_vduc1_then_la1 
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
    // [2486] return 
    rts
    // rom_write::@2
  __b2:
    // rom_unlock(rom_chip_address + 0x05555, 0xA0)
    // [2487] rom_unlock::address#4 = rom_write::rom_chip_address#0 + $5555 -- vduz1=vduz2_plus_vwuc1 
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
    // [2488] call rom_unlock
    // [2043] phi from rom_write::@2 to rom_unlock [phi:rom_write::@2->rom_unlock]
    // [2043] phi rom_unlock::unlock_code#5 = $a0 [phi:rom_write::@2->rom_unlock#0] -- vbuz1=vbuc1 
    lda #$a0
    sta.z rom_unlock.unlock_code
    // [2043] phi rom_unlock::address#5 = rom_unlock::address#4 [phi:rom_write::@2->rom_unlock#1] -- register_copy 
    jsr rom_unlock
    // rom_write::@3
    // rom_byte_program(flash_rom_address, *flash_ram_address)
    // [2489] rom_byte_program::address#0 = rom_write::flash_rom_address#3 -- vduz1=vduz2 
    lda.z flash_rom_address
    sta.z rom_byte_program.address
    lda.z flash_rom_address+1
    sta.z rom_byte_program.address+1
    lda.z flash_rom_address+2
    sta.z rom_byte_program.address+2
    lda.z flash_rom_address+3
    sta.z rom_byte_program.address+3
    // [2490] rom_byte_program::value#0 = *rom_write::flash_ram_address#2 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (flash_ram_address),y
    sta.z rom_byte_program.value
    // [2491] call rom_byte_program
    // [2917] phi from rom_write::@3 to rom_byte_program [phi:rom_write::@3->rom_byte_program]
    jsr rom_byte_program
    // rom_write::@4
    // flash_rom_address++;
    // [2492] rom_write::flash_rom_address#0 = ++ rom_write::flash_rom_address#3 -- vduz1=_inc_vduz1 
    inc.z flash_rom_address
    bne !+
    inc.z flash_rom_address+1
    bne !+
    inc.z flash_rom_address+2
    bne !+
    inc.z flash_rom_address+3
  !:
    // flash_ram_address++;
    // [2493] rom_write::flash_ram_address#0 = ++ rom_write::flash_ram_address#2 -- pbuz1=_inc_pbuz1 
    inc.z flash_ram_address
    bne !+
    inc.z flash_ram_address+1
  !:
    // flashed_bytes++;
    // [2494] rom_write::flashed_bytes#1 = ++ rom_write::flashed_bytes#2 -- vduz1=_inc_vduz1 
    inc.z flashed_bytes
    bne !+
    inc.z flashed_bytes+1
    bne !+
    inc.z flashed_bytes+2
    bne !+
    inc.z flashed_bytes+3
  !:
    // [2484] phi from rom_write::@4 to rom_write::@1 [phi:rom_write::@4->rom_write::@1]
    // [2484] phi rom_write::flash_ram_address#2 = rom_write::flash_ram_address#0 [phi:rom_write::@4->rom_write::@1#0] -- register_copy 
    // [2484] phi rom_write::flash_rom_address#3 = rom_write::flash_rom_address#0 [phi:rom_write::@4->rom_write::@1#1] -- register_copy 
    // [2484] phi rom_write::flashed_bytes#2 = rom_write::flashed_bytes#1 [phi:rom_write::@4->rom_write::@1#2] -- register_copy 
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
    // [2495] cbm_k_getin::ch = 0 -- vbum1=vbuc1 
    lda #0
    sta ch
    // asm
    // asm { jsrCBM_GETIN stach  }
    jsr CBM_GETIN
    sta ch
    // return ch;
    // [2497] cbm_k_getin::return#0 = cbm_k_getin::ch -- vbum1=vbum2 
    sta return
    // cbm_k_getin::@return
    // }
    // [2498] cbm_k_getin::return#1 = cbm_k_getin::return#0
    // [2499] return 
    rts
  .segment Data
    ch: .byte 0
    return: .byte 0
}
.segment Code
  // display_vera_led
/**
 * @brief Print VERA led above the VERA chip.
 * 
 * @param c Led color
 */
// void display_vera_led(__mem() char c)
display_vera_led: {
    // display_chip_led(CHIP_VERA_X+1, CHIP_VERA_Y, CHIP_VERA_W, c, BLUE)
    // [2501] display_chip_led::tc#1 = display_vera_led::c#2 -- vbuz1=vbum2 
    lda c
    sta.z display_chip_led.tc
    // [2502] call display_chip_led
    // [2726] phi from display_vera_led to display_chip_led [phi:display_vera_led->display_chip_led]
    // [2726] phi display_chip_led::w#7 = 8 [phi:display_vera_led->display_chip_led#0] -- vbuz1=vbuc1 
    lda #8
    sta.z display_chip_led.w
    // [2726] phi display_chip_led::x#7 = 9+1 [phi:display_vera_led->display_chip_led#1] -- vbuz1=vbuc1 
    lda #9+1
    sta.z display_chip_led.x
    // [2726] phi display_chip_led::tc#3 = display_chip_led::tc#1 [phi:display_vera_led->display_chip_led#2] -- register_copy 
    jsr display_chip_led
    // display_vera_led::@1
    // display_info_led(INFO_X-2, INFO_Y+1, c, BLUE)
    // [2503] display_info_led::tc#1 = display_vera_led::c#2 -- vbuz1=vbum2 
    lda c
    sta.z display_info_led.tc
    // [2504] call display_info_led
    // [1978] phi from display_vera_led::@1 to display_info_led [phi:display_vera_led::@1->display_info_led]
    // [1978] phi display_info_led::y#4 = $11+1 [phi:display_vera_led::@1->display_info_led#0] -- vbuz1=vbuc1 
    lda #$11+1
    sta.z display_info_led.y
    // [1978] phi display_info_led::x#4 = 4-2 [phi:display_vera_led::@1->display_info_led#1] -- vbuz1=vbuc1 
    lda #4-2
    sta.z display_info_led.x
    // [1978] phi display_info_led::tc#4 = display_info_led::tc#1 [phi:display_vera_led::@1->display_info_led#2] -- register_copy 
    jsr display_info_led
    // display_vera_led::@return
    // }
    // [2505] return 
    rts
  .segment Data
    .label c = main.check_status_cx16_rom5_check_status_rom1_main__0
}
.segment Code
  // strncpy
/// Copies up to n characters from the string pointed to, by src to dst.
/// In a case where the length of src is less than that of n, the remainder of dst will be padded with null bytes.
/// @param dst ? This is the pointer to the destination array where the content is to be copied.
/// @param src ? This is the string to be copied.
/// @param n ? The number of characters to be copied from source.
/// @return The destination
// char * strncpy(__zp($39) char *dst, __zp($3b) const char *src, __mem() unsigned int n)
strncpy: {
    .label dst = $39
    .label src = $3b
    // [2507] phi from strncpy to strncpy::@1 [phi:strncpy->strncpy::@1]
    // [2507] phi strncpy::dst#3 = strncpy::dst#8 [phi:strncpy->strncpy::@1#0] -- register_copy 
    // [2507] phi strncpy::src#3 = strncpy::src#6 [phi:strncpy->strncpy::@1#1] -- register_copy 
    // [2507] phi strncpy::i#2 = 0 [phi:strncpy->strncpy::@1#2] -- vwum1=vwuc1 
    lda #<0
    sta i
    sta i+1
    // strncpy::@1
  __b1:
    // for(size_t i = 0;i<n;i++)
    // [2508] if(strncpy::i#2<strncpy::n#3) goto strncpy::@2 -- vwum1_lt_vwum2_then_la1 
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
    // [2509] return 
    rts
    // strncpy::@2
  __b2:
    // char c = *src
    // [2510] strncpy::c#0 = *strncpy::src#3 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (src),y
    sta c
    // if(c)
    // [2511] if(0==strncpy::c#0) goto strncpy::@3 -- 0_eq_vbum1_then_la1 
    beq __b3
    // strncpy::@4
    // src++;
    // [2512] strncpy::src#0 = ++ strncpy::src#3 -- pbuz1=_inc_pbuz1 
    inc.z src
    bne !+
    inc.z src+1
  !:
    // [2513] phi from strncpy::@2 strncpy::@4 to strncpy::@3 [phi:strncpy::@2/strncpy::@4->strncpy::@3]
    // [2513] phi strncpy::src#7 = strncpy::src#3 [phi:strncpy::@2/strncpy::@4->strncpy::@3#0] -- register_copy 
    // strncpy::@3
  __b3:
    // *dst++ = c
    // [2514] *strncpy::dst#3 = strncpy::c#0 -- _deref_pbuz1=vbum2 
    lda c
    ldy #0
    sta (dst),y
    // *dst++ = c;
    // [2515] strncpy::dst#0 = ++ strncpy::dst#3 -- pbuz1=_inc_pbuz1 
    inc.z dst
    bne !+
    inc.z dst+1
  !:
    // for(size_t i = 0;i<n;i++)
    // [2516] strncpy::i#1 = ++ strncpy::i#2 -- vwum1=_inc_vwum1 
    inc i
    bne !+
    inc i+1
  !:
    // [2507] phi from strncpy::@3 to strncpy::@1 [phi:strncpy::@3->strncpy::@1]
    // [2507] phi strncpy::dst#3 = strncpy::dst#0 [phi:strncpy::@3->strncpy::@1#0] -- register_copy 
    // [2507] phi strncpy::src#3 = strncpy::src#7 [phi:strncpy::@3->strncpy::@1#1] -- register_copy 
    // [2507] phi strncpy::i#2 = strncpy::i#1 [phi:strncpy::@3->strncpy::@1#2] -- register_copy 
    jmp __b1
  .segment Data
    c: .byte 0
    i: .word 0
    n: .word 0
}
.segment Code
  // utoa
// Converts unsigned number value to a string representing it in RADIX format.
// If the leading digits are zero they are not included in the string.
// - value : The number to be converted to RADIX
// - buffer : receives the string representing the number and zero-termination.
// - radix : The radix to convert the number to (from the enum RADIX)
// void utoa(__mem() unsigned int value, __zp($3f) char *buffer, __mem() char radix)
utoa: {
    .label utoa__4 = $38
    .label utoa__10 = $46
    .label utoa__11 = $43
    .label buffer = $3f
    .label digit_values = $3d
    // if(radix==DECIMAL)
    // [2517] if(utoa::radix#0==DECIMAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #DECIMAL
    cmp radix
    beq __b2
    // utoa::@2
    // if(radix==HEXADECIMAL)
    // [2518] if(utoa::radix#0==HEXADECIMAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #HEXADECIMAL
    cmp radix
    beq __b3
    // utoa::@3
    // if(radix==OCTAL)
    // [2519] if(utoa::radix#0==OCTAL) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #OCTAL
    cmp radix
    beq __b4
    // utoa::@4
    // if(radix==BINARY)
    // [2520] if(utoa::radix#0==BINARY) goto utoa::@1 -- vbum1_eq_vbuc1_then_la1 
    lda #BINARY
    cmp radix
    beq __b5
    // utoa::@5
    // *buffer++ = 'e'
    // [2521] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS) = 'e' -- _deref_pbuc1=vbuc2 
    // Unknown radix
    lda #'e'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    // *buffer++ = 'r'
    // [2522] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1) = 'r' -- _deref_pbuc1=vbuc2 
    lda #'r'
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+1
    // [2523] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2) = 'r' -- _deref_pbuc1=vbuc2 
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+2
    // *buffer = 0
    // [2524] *((char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3) = 0 -- _deref_pbuc1=vbuc2 
    lda #0
    sta printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS+3
    // utoa::@return
    // }
    // [2525] return 
    rts
    // [2526] phi from utoa to utoa::@1 [phi:utoa->utoa::@1]
  __b2:
    // [2526] phi utoa::digit_values#8 = RADIX_DECIMAL_VALUES [phi:utoa->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_DECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_DECIMAL_VALUES
    sta.z digit_values+1
    // [2526] phi utoa::max_digits#7 = 5 [phi:utoa->utoa::@1#1] -- vbum1=vbuc1 
    lda #5
    sta max_digits
    jmp __b1
    // [2526] phi from utoa::@2 to utoa::@1 [phi:utoa::@2->utoa::@1]
  __b3:
    // [2526] phi utoa::digit_values#8 = RADIX_HEXADECIMAL_VALUES [phi:utoa::@2->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_HEXADECIMAL_VALUES
    sta.z digit_values
    lda #>RADIX_HEXADECIMAL_VALUES
    sta.z digit_values+1
    // [2526] phi utoa::max_digits#7 = 4 [phi:utoa::@2->utoa::@1#1] -- vbum1=vbuc1 
    lda #4
    sta max_digits
    jmp __b1
    // [2526] phi from utoa::@3 to utoa::@1 [phi:utoa::@3->utoa::@1]
  __b4:
    // [2526] phi utoa::digit_values#8 = RADIX_OCTAL_VALUES [phi:utoa::@3->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_OCTAL_VALUES
    sta.z digit_values
    lda #>RADIX_OCTAL_VALUES
    sta.z digit_values+1
    // [2526] phi utoa::max_digits#7 = 6 [phi:utoa::@3->utoa::@1#1] -- vbum1=vbuc1 
    lda #6
    sta max_digits
    jmp __b1
    // [2526] phi from utoa::@4 to utoa::@1 [phi:utoa::@4->utoa::@1]
  __b5:
    // [2526] phi utoa::digit_values#8 = RADIX_BINARY_VALUES [phi:utoa::@4->utoa::@1#0] -- pwuz1=pwuc1 
    lda #<RADIX_BINARY_VALUES
    sta.z digit_values
    lda #>RADIX_BINARY_VALUES
    sta.z digit_values+1
    // [2526] phi utoa::max_digits#7 = $10 [phi:utoa::@4->utoa::@1#1] -- vbum1=vbuc1 
    lda #$10
    sta max_digits
    // utoa::@1
  __b1:
    // [2527] phi from utoa::@1 to utoa::@6 [phi:utoa::@1->utoa::@6]
    // [2527] phi utoa::buffer#11 = (char *)&printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS [phi:utoa::@1->utoa::@6#0] -- pbuz1=pbuc1 
    lda #<printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer
    lda #>printf_buffer+OFFSET_STRUCT_PRINTF_BUFFER_NUMBER_DIGITS
    sta.z buffer+1
    // [2527] phi utoa::started#2 = 0 [phi:utoa::@1->utoa::@6#1] -- vbum1=vbuc1 
    lda #0
    sta started
    // [2527] phi utoa::value#2 = utoa::value#1 [phi:utoa::@1->utoa::@6#2] -- register_copy 
    // [2527] phi utoa::digit#2 = 0 [phi:utoa::@1->utoa::@6#3] -- vbum1=vbuc1 
    sta digit
    // utoa::@6
  __b6:
    // max_digits-1
    // [2528] utoa::$4 = utoa::max_digits#7 - 1 -- vbuz1=vbum2_minus_1 
    ldx max_digits
    dex
    stx.z utoa__4
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2529] if(utoa::digit#2<utoa::$4) goto utoa::@7 -- vbum1_lt_vbuz2_then_la1 
    lda digit
    cmp.z utoa__4
    bcc __b7
    // utoa::@8
    // *buffer++ = DIGITS[(char)value]
    // [2530] utoa::$11 = (char)utoa::value#2 -- vbuz1=_byte_vwum2 
    lda value
    sta.z utoa__11
    // [2531] *utoa::buffer#11 = DIGITS[utoa::$11] -- _deref_pbuz1=pbuc1_derefidx_vbuz2 
    tay
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // *buffer++ = DIGITS[(char)value];
    // [2532] utoa::buffer#3 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // *buffer = 0
    // [2533] *utoa::buffer#3 = 0 -- _deref_pbuz1=vbuc1 
    lda #0
    tay
    sta (buffer),y
    rts
    // utoa::@7
  __b7:
    // unsigned int digit_value = digit_values[digit]
    // [2534] utoa::$10 = utoa::digit#2 << 1 -- vbuz1=vbum2_rol_1 
    lda digit
    asl
    sta.z utoa__10
    // [2535] utoa::digit_value#0 = utoa::digit_values#8[utoa::$10] -- vwum1=pwuz2_derefidx_vbuz3 
    tay
    lda (digit_values),y
    sta digit_value
    iny
    lda (digit_values),y
    sta digit_value+1
    // if (started || value >= digit_value)
    // [2536] if(0!=utoa::started#2) goto utoa::@10 -- 0_neq_vbum1_then_la1 
    lda started
    bne __b10
    // utoa::@12
    // [2537] if(utoa::value#2>=utoa::digit_value#0) goto utoa::@10 -- vwum1_ge_vwum2_then_la1 
    lda digit_value+1
    cmp value+1
    bne !+
    lda digit_value
    cmp value
    beq __b10
  !:
    bcc __b10
    // [2538] phi from utoa::@12 to utoa::@9 [phi:utoa::@12->utoa::@9]
    // [2538] phi utoa::buffer#14 = utoa::buffer#11 [phi:utoa::@12->utoa::@9#0] -- register_copy 
    // [2538] phi utoa::started#4 = utoa::started#2 [phi:utoa::@12->utoa::@9#1] -- register_copy 
    // [2538] phi utoa::value#6 = utoa::value#2 [phi:utoa::@12->utoa::@9#2] -- register_copy 
    // utoa::@9
  __b9:
    // for( char digit=0; digit<max_digits-1; digit++ )
    // [2539] utoa::digit#1 = ++ utoa::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // [2527] phi from utoa::@9 to utoa::@6 [phi:utoa::@9->utoa::@6]
    // [2527] phi utoa::buffer#11 = utoa::buffer#14 [phi:utoa::@9->utoa::@6#0] -- register_copy 
    // [2527] phi utoa::started#2 = utoa::started#4 [phi:utoa::@9->utoa::@6#1] -- register_copy 
    // [2527] phi utoa::value#2 = utoa::value#6 [phi:utoa::@9->utoa::@6#2] -- register_copy 
    // [2527] phi utoa::digit#2 = utoa::digit#1 [phi:utoa::@9->utoa::@6#3] -- register_copy 
    jmp __b6
    // utoa::@10
  __b10:
    // utoa_append(buffer++, value, digit_value)
    // [2540] utoa_append::buffer#0 = utoa::buffer#11 -- pbuz1=pbuz2 
    lda.z buffer
    sta.z utoa_append.buffer
    lda.z buffer+1
    sta.z utoa_append.buffer+1
    // [2541] utoa_append::value#0 = utoa::value#2
    // [2542] utoa_append::sub#0 = utoa::digit_value#0
    // [2543] call utoa_append
    // [2927] phi from utoa::@10 to utoa_append [phi:utoa::@10->utoa_append]
    jsr utoa_append
    // utoa_append(buffer++, value, digit_value)
    // [2544] utoa_append::return#0 = utoa_append::value#2
    // utoa::@11
    // value = utoa_append(buffer++, value, digit_value)
    // [2545] utoa::value#0 = utoa_append::return#0
    // value = utoa_append(buffer++, value, digit_value);
    // [2546] utoa::buffer#4 = ++ utoa::buffer#11 -- pbuz1=_inc_pbuz1 
    inc.z buffer
    bne !+
    inc.z buffer+1
  !:
    // [2538] phi from utoa::@11 to utoa::@9 [phi:utoa::@11->utoa::@9]
    // [2538] phi utoa::buffer#14 = utoa::buffer#4 [phi:utoa::@11->utoa::@9#0] -- register_copy 
    // [2538] phi utoa::started#4 = 1 [phi:utoa::@11->utoa::@9#1] -- vbum1=vbuc1 
    lda #1
    sta started
    // [2538] phi utoa::value#6 = utoa::value#0 [phi:utoa::@11->utoa::@9#2] -- register_copy 
    jmp __b9
  .segment Data
    digit_value: .word 0
    digit: .byte 0
    .label value = printf_uint.uvalue
    .label radix = printf_uint.format_radix
    started: .byte 0
    max_digits: .byte 0
}
.segment Code
  // insertup
// Insert a new line, and scroll the upper part of the screen up.
// void insertup(char rows)
insertup: {
    .label insertup__0 = $36
    .label insertup__4 = $2b
    .label insertup__6 = $2c
    .label insertup__7 = $2b
    // __conio.width+1
    // [2547] insertup::$0 = *((char *)&__conio+6) + 1 -- vbuz1=_deref_pbuc1_plus_1 
    lda __conio+6
    inc
    sta.z insertup__0
    // unsigned char width = (__conio.width+1) * 2
    // [2548] insertup::width#0 = insertup::$0 << 1 -- vbum1=vbuz2_rol_1 
    // {asm{.byte $db}}
    asl
    sta width
    // [2549] phi from insertup to insertup::@1 [phi:insertup->insertup::@1]
    // [2549] phi insertup::y#2 = 0 [phi:insertup->insertup::@1#0] -- vbum1=vbuc1 
    lda #0
    sta y
    // insertup::@1
  __b1:
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [2550] if(insertup::y#2<*((char *)&__conio+1)) goto insertup::@2 -- vbum1_lt__deref_pbuc1_then_la1 
    lda y
    cmp __conio+1
    bcc __b2
    // [2551] phi from insertup::@1 to insertup::@3 [phi:insertup::@1->insertup::@3]
    // insertup::@3
    // clearline()
    // [2552] call clearline
    jsr clearline
    // insertup::@return
    // }
    // [2553] return 
    rts
    // insertup::@2
  __b2:
    // y+1
    // [2554] insertup::$4 = insertup::y#2 + 1 -- vbuz1=vbum2_plus_1 
    lda y
    inc
    sta.z insertup__4
    // memcpy8_vram_vram(__conio.mapbase_bank, __conio.offsets[y], __conio.mapbase_bank, __conio.offsets[y+1], width)
    // [2555] insertup::$6 = insertup::y#2 << 1 -- vbuz1=vbum2_rol_1 
    lda y
    asl
    sta.z insertup__6
    // [2556] insertup::$7 = insertup::$4 << 1 -- vbuz1=vbuz1_rol_1 
    asl.z insertup__7
    // [2557] memcpy8_vram_vram::dbank_vram#0 = *((char *)&__conio+5) -- vbum1=_deref_pbuc1 
    lda __conio+5
    sta memcpy8_vram_vram.dbank_vram
    // [2558] memcpy8_vram_vram::doffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$6] -- vwum1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__6
    lda __conio+$15,y
    sta memcpy8_vram_vram.doffset_vram
    lda __conio+$15+1,y
    sta memcpy8_vram_vram.doffset_vram+1
    // [2559] memcpy8_vram_vram::sbank_vram#0 = *((char *)&__conio+5) -- vbum1=_deref_pbuc1 
    lda __conio+5
    sta memcpy8_vram_vram.sbank_vram
    // [2560] memcpy8_vram_vram::soffset_vram#0 = ((unsigned int *)&__conio+$15)[insertup::$7] -- vwum1=pwuc1_derefidx_vbuz2 
    ldy.z insertup__7
    lda __conio+$15,y
    sta memcpy8_vram_vram.soffset_vram
    lda __conio+$15+1,y
    sta memcpy8_vram_vram.soffset_vram+1
    // [2561] memcpy8_vram_vram::num8#1 = insertup::width#0 -- vbum1=vbum2 
    lda width
    sta memcpy8_vram_vram.num8_1
    // [2562] call memcpy8_vram_vram
    jsr memcpy8_vram_vram
    // insertup::@4
    // for(unsigned char y=0; y<__conio.cursor_y; y++)
    // [2563] insertup::y#1 = ++ insertup::y#2 -- vbum1=_inc_vbum1 
    inc y
    // [2549] phi from insertup::@4 to insertup::@1 [phi:insertup::@4->insertup::@1]
    // [2549] phi insertup::y#2 = insertup::y#1 [phi:insertup::@4->insertup::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    width: .byte 0
    y: .byte 0
}
.segment Code
  // clearline
clearline: {
    .label clearline__0 = $24
    .label clearline__1 = $25
    .label clearline__2 = $26
    .label clearline__3 = $23
    .label c = $22
    // unsigned int addr = __conio.offsets[__conio.cursor_y]
    // [2564] clearline::$3 = *((char *)&__conio+1) << 1 -- vbuz1=_deref_pbuc1_rol_1 
    lda __conio+1
    asl
    sta.z clearline__3
    // [2565] clearline::addr#0 = ((unsigned int *)&__conio+$15)[clearline::$3] -- vwum1=pwuc1_derefidx_vbuz2 
    tay
    lda __conio+$15,y
    sta addr
    lda __conio+$15+1,y
    sta addr+1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2566] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(addr)
    // [2567] clearline::$0 = byte0  clearline::addr#0 -- vbuz1=_byte0_vwum2 
    lda addr
    sta.z clearline__0
    // *VERA_ADDRX_L = BYTE0(addr)
    // [2568] *VERA_ADDRX_L = clearline::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(addr)
    // [2569] clearline::$1 = byte1  clearline::addr#0 -- vbuz1=_byte1_vwum2 
    lda addr+1
    sta.z clearline__1
    // *VERA_ADDRX_M = BYTE1(addr)
    // [2570] *VERA_ADDRX_M = clearline::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_1
    // [2571] clearline::$2 = *((char *)&__conio+5) | VERA_INC_1 -- vbuz1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_INC_1
    ora __conio+5
    sta.z clearline__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_1
    // [2572] *VERA_ADDRX_H = clearline::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // register unsigned char c=__conio.width
    // [2573] clearline::c#0 = *((char *)&__conio+6) -- vbuz1=_deref_pbuc1 
    lda __conio+6
    sta.z c
    // [2574] phi from clearline clearline::@1 to clearline::@1 [phi:clearline/clearline::@1->clearline::@1]
    // [2574] phi clearline::c#2 = clearline::c#0 [phi:clearline/clearline::@1->clearline::@1#0] -- register_copy 
    // clearline::@1
  __b1:
    // *VERA_DATA0 = ' '
    // [2575] *VERA_DATA0 = ' ' -- _deref_pbuc1=vbuc2 
    lda #' '
    sta VERA_DATA0
    // *VERA_DATA0 = __conio.color
    // [2576] *VERA_DATA0 = *((char *)&__conio+$d) -- _deref_pbuc1=_deref_pbuc2 
    lda __conio+$d
    sta VERA_DATA0
    // c--;
    // [2577] clearline::c#1 = -- clearline::c#2 -- vbuz1=_dec_vbuz1 
    dec.z c
    // while(c)
    // [2578] if(0!=clearline::c#1) goto clearline::@1 -- 0_neq_vbuz1_then_la1 
    lda.z c
    bne __b1
    // clearline::@return
    // }
    // [2579] return 
    rts
  .segment Data
    addr: .word 0
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
    // [2580] cx16_k_screen_set_mode::error = 0 -- vbum1=vbuc1 
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
    // [2582] return 
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
    .label w = $43
    .label h = $46
    .label x = $fb
    .label mask = $e0
    .label c = $dc
    .label y_1 = $f7
    // unsigned char w = x1 - x0
    // [2584] display_frame::w#0 = display_frame::x1#16 - display_frame::x#0 -- vbuz1=vbum2_minus_vbuz3 
    lda x1
    sec
    sbc.z x
    sta.z w
    // unsigned char h = y1 - y0
    // [2585] display_frame::h#0 = display_frame::y1#16 - display_frame::y#0 -- vbuz1=vbum2_minus_vbum3 
    lda y1
    sec
    sbc y
    sta.z h
    // unsigned char mask = display_frame_maskxy(x, y)
    // [2586] display_frame_maskxy::x#0 = display_frame::x#0
    // [2587] display_frame_maskxy::y#0 = display_frame::y#0
    // [2588] call display_frame_maskxy
    // [2954] phi from display_frame to display_frame_maskxy [phi:display_frame->display_frame_maskxy]
    // [2954] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#0 [phi:display_frame->display_frame_maskxy#0] -- vbum1=vbum2 
    lda display_frame_maskxy.y
    sta display_frame_maskxy.cpeekcxy1_y
    // [2954] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#0 [phi:display_frame->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // unsigned char mask = display_frame_maskxy(x, y)
    // [2589] display_frame_maskxy::return#13 = display_frame_maskxy::return#12
    // display_frame::@13
    // [2590] display_frame::mask#0 = display_frame_maskxy::return#13
    // mask |= 0b0110
    // [2591] display_frame::mask#1 = display_frame::mask#0 | 6 -- vbuz1=vbuz1_bor_vbuc1 
    lda #6
    ora.z mask
    sta.z mask
    // unsigned char c = display_frame_char(mask)
    // [2592] display_frame_char::mask#0 = display_frame::mask#1
    // [2593] call display_frame_char
  // Add a corner.
    // [2980] phi from display_frame::@13 to display_frame_char [phi:display_frame::@13->display_frame_char]
    // [2980] phi display_frame_char::mask#10 = display_frame_char::mask#0 [phi:display_frame::@13->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // unsigned char c = display_frame_char(mask)
    // [2594] display_frame_char::return#13 = display_frame_char::return#12
    // display_frame::@14
    // [2595] display_frame::c#0 = display_frame_char::return#13
    // cputcxy(x, y, c)
    // [2596] cputcxy::x#0 = display_frame::x#0 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [2597] cputcxy::y#0 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [2598] cputcxy::c#0 = display_frame::c#0 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [2599] call cputcxy
    // [2147] phi from display_frame::@14 to cputcxy [phi:display_frame::@14->cputcxy]
    // [2147] phi cputcxy::c#15 = cputcxy::c#0 [phi:display_frame::@14->cputcxy#0] -- register_copy 
    // [2147] phi cputcxy::y#15 = cputcxy::y#0 [phi:display_frame::@14->cputcxy#1] -- register_copy 
    // [2147] phi cputcxy::x#15 = cputcxy::x#0 [phi:display_frame::@14->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@15
    // if(w>=2)
    // [2600] if(display_frame::w#0<2) goto display_frame::@36 -- vbuz1_lt_vbuc1_then_la1 
    lda.z w
    cmp #2
    bcs !__b36+
    jmp __b36
  !__b36:
    // display_frame::@2
    // x++;
    // [2601] display_frame::x#1 = ++ display_frame::x#0 -- vbum1=_inc_vbuz2 
    lda.z x
    inc
    sta x_1
    // [2602] phi from display_frame::@2 display_frame::@21 to display_frame::@4 [phi:display_frame::@2/display_frame::@21->display_frame::@4]
    // [2602] phi display_frame::x#10 = display_frame::x#1 [phi:display_frame::@2/display_frame::@21->display_frame::@4#0] -- register_copy 
    // display_frame::@4
  __b4:
    // while(x < x1)
    // [2603] if(display_frame::x#10<display_frame::x1#16) goto display_frame::@5 -- vbum1_lt_vbum2_then_la1 
    lda x_1
    cmp x1
    bcs !__b5+
    jmp __b5
  !__b5:
    // [2604] phi from display_frame::@36 display_frame::@4 to display_frame::@1 [phi:display_frame::@36/display_frame::@4->display_frame::@1]
    // [2604] phi display_frame::x#24 = display_frame::x#30 [phi:display_frame::@36/display_frame::@4->display_frame::@1#0] -- register_copy 
    // display_frame::@1
  __b1:
    // display_frame_maskxy(x, y)
    // [2605] display_frame_maskxy::x#1 = display_frame::x#24
    // [2606] display_frame_maskxy::y#1 = display_frame::y#0
    // [2607] call display_frame_maskxy
    // [2954] phi from display_frame::@1 to display_frame_maskxy [phi:display_frame::@1->display_frame_maskxy]
    // [2954] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#1 [phi:display_frame::@1->display_frame_maskxy#0] -- vbum1=vbum2 
    lda display_frame_maskxy.y
    sta display_frame_maskxy.cpeekcxy1_y
    // [2954] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#1 [phi:display_frame::@1->display_frame_maskxy#1] -- vbum1=vbum2 
    lda display_frame_maskxy.x_1
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [2608] display_frame_maskxy::return#14 = display_frame_maskxy::return#12
    // display_frame::@16
    // mask = display_frame_maskxy(x, y)
    // [2609] display_frame::mask#2 = display_frame_maskxy::return#14
    // mask |= 0b0011
    // [2610] display_frame::mask#3 = display_frame::mask#2 | 3 -- vbuz1=vbuz1_bor_vbuc1 
    lda #3
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [2611] display_frame_char::mask#1 = display_frame::mask#3
    // [2612] call display_frame_char
    // [2980] phi from display_frame::@16 to display_frame_char [phi:display_frame::@16->display_frame_char]
    // [2980] phi display_frame_char::mask#10 = display_frame_char::mask#1 [phi:display_frame::@16->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [2613] display_frame_char::return#14 = display_frame_char::return#12
    // display_frame::@17
    // c = display_frame_char(mask)
    // [2614] display_frame::c#1 = display_frame_char::return#14
    // cputcxy(x, y, c)
    // [2615] cputcxy::x#1 = display_frame::x#24 -- vbum1=vbum2 
    lda x_1
    sta cputcxy.x
    // [2616] cputcxy::y#1 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [2617] cputcxy::c#1 = display_frame::c#1 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [2618] call cputcxy
    // [2147] phi from display_frame::@17 to cputcxy [phi:display_frame::@17->cputcxy]
    // [2147] phi cputcxy::c#15 = cputcxy::c#1 [phi:display_frame::@17->cputcxy#0] -- register_copy 
    // [2147] phi cputcxy::y#15 = cputcxy::y#1 [phi:display_frame::@17->cputcxy#1] -- register_copy 
    // [2147] phi cputcxy::x#15 = cputcxy::x#1 [phi:display_frame::@17->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@18
    // if(h>=2)
    // [2619] if(display_frame::h#0<2) goto display_frame::@return -- vbuz1_lt_vbuc1_then_la1 
    lda.z h
    cmp #2
    bcc __breturn
    // display_frame::@3
    // y++;
    // [2620] display_frame::y#1 = ++ display_frame::y#0 -- vbuz1=_inc_vbum2 
    lda y
    inc
    sta.z y_1
    // [2621] phi from display_frame::@27 display_frame::@3 to display_frame::@6 [phi:display_frame::@27/display_frame::@3->display_frame::@6]
    // [2621] phi display_frame::y#10 = display_frame::y#2 [phi:display_frame::@27/display_frame::@3->display_frame::@6#0] -- register_copy 
    // display_frame::@6
  __b6:
    // while(y < y1)
    // [2622] if(display_frame::y#10<display_frame::y1#16) goto display_frame::@7 -- vbuz1_lt_vbum2_then_la1 
    lda.z y_1
    cmp y1
    bcs !__b7+
    jmp __b7
  !__b7:
    // display_frame::@8
    // display_frame_maskxy(x, y)
    // [2623] display_frame_maskxy::x#5 = display_frame::x#0
    // [2624] display_frame_maskxy::y#5 = display_frame::y#10
    // [2625] call display_frame_maskxy
    // [2954] phi from display_frame::@8 to display_frame_maskxy [phi:display_frame::@8->display_frame_maskxy]
    // [2954] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#5 [phi:display_frame::@8->display_frame_maskxy#0] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.y_1
    sta display_frame_maskxy.cpeekcxy1_y
    // [2954] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#5 [phi:display_frame::@8->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [2626] display_frame_maskxy::return#18 = display_frame_maskxy::return#12
    // display_frame::@28
    // mask = display_frame_maskxy(x, y)
    // [2627] display_frame::mask#10 = display_frame_maskxy::return#18
    // mask |= 0b1100
    // [2628] display_frame::mask#11 = display_frame::mask#10 | $c -- vbuz1=vbuz1_bor_vbuc1 
    lda #$c
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [2629] display_frame_char::mask#5 = display_frame::mask#11
    // [2630] call display_frame_char
    // [2980] phi from display_frame::@28 to display_frame_char [phi:display_frame::@28->display_frame_char]
    // [2980] phi display_frame_char::mask#10 = display_frame_char::mask#5 [phi:display_frame::@28->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [2631] display_frame_char::return#18 = display_frame_char::return#12
    // display_frame::@29
    // c = display_frame_char(mask)
    // [2632] display_frame::c#5 = display_frame_char::return#18
    // cputcxy(x, y, c)
    // [2633] cputcxy::x#5 = display_frame::x#0 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [2634] cputcxy::y#5 = display_frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta cputcxy.y
    // [2635] cputcxy::c#5 = display_frame::c#5 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [2636] call cputcxy
    // [2147] phi from display_frame::@29 to cputcxy [phi:display_frame::@29->cputcxy]
    // [2147] phi cputcxy::c#15 = cputcxy::c#5 [phi:display_frame::@29->cputcxy#0] -- register_copy 
    // [2147] phi cputcxy::y#15 = cputcxy::y#5 [phi:display_frame::@29->cputcxy#1] -- register_copy 
    // [2147] phi cputcxy::x#15 = cputcxy::x#5 [phi:display_frame::@29->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@30
    // if(w>=2)
    // [2637] if(display_frame::w#0<2) goto display_frame::@10 -- vbuz1_lt_vbuc1_then_la1 
    lda.z w
    cmp #2
    bcc __b10
    // display_frame::@9
    // x++;
    // [2638] display_frame::x#4 = ++ display_frame::x#0 -- vbuz1=_inc_vbuz1 
    inc.z x
    // [2639] phi from display_frame::@35 display_frame::@9 to display_frame::@11 [phi:display_frame::@35/display_frame::@9->display_frame::@11]
    // [2639] phi display_frame::x#18 = display_frame::x#5 [phi:display_frame::@35/display_frame::@9->display_frame::@11#0] -- register_copy 
    // display_frame::@11
  __b11:
    // while(x < x1)
    // [2640] if(display_frame::x#18<display_frame::x1#16) goto display_frame::@12 -- vbuz1_lt_vbum2_then_la1 
    lda.z x
    cmp x1
    bcc __b12
    // [2641] phi from display_frame::@11 display_frame::@30 to display_frame::@10 [phi:display_frame::@11/display_frame::@30->display_frame::@10]
    // [2641] phi display_frame::x#15 = display_frame::x#18 [phi:display_frame::@11/display_frame::@30->display_frame::@10#0] -- register_copy 
    // display_frame::@10
  __b10:
    // display_frame_maskxy(x, y)
    // [2642] display_frame_maskxy::x#6 = display_frame::x#15
    // [2643] display_frame_maskxy::y#6 = display_frame::y#10
    // [2644] call display_frame_maskxy
    // [2954] phi from display_frame::@10 to display_frame_maskxy [phi:display_frame::@10->display_frame_maskxy]
    // [2954] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#6 [phi:display_frame::@10->display_frame_maskxy#0] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.y_1
    sta display_frame_maskxy.cpeekcxy1_y
    // [2954] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#6 [phi:display_frame::@10->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [2645] display_frame_maskxy::return#19 = display_frame_maskxy::return#12
    // display_frame::@31
    // mask = display_frame_maskxy(x, y)
    // [2646] display_frame::mask#12 = display_frame_maskxy::return#19
    // mask |= 0b1001
    // [2647] display_frame::mask#13 = display_frame::mask#12 | 9 -- vbuz1=vbuz1_bor_vbuc1 
    lda #9
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [2648] display_frame_char::mask#6 = display_frame::mask#13
    // [2649] call display_frame_char
    // [2980] phi from display_frame::@31 to display_frame_char [phi:display_frame::@31->display_frame_char]
    // [2980] phi display_frame_char::mask#10 = display_frame_char::mask#6 [phi:display_frame::@31->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [2650] display_frame_char::return#19 = display_frame_char::return#12
    // display_frame::@32
    // c = display_frame_char(mask)
    // [2651] display_frame::c#6 = display_frame_char::return#19
    // cputcxy(x, y, c)
    // [2652] cputcxy::x#6 = display_frame::x#15 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [2653] cputcxy::y#6 = display_frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta cputcxy.y
    // [2654] cputcxy::c#6 = display_frame::c#6 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [2655] call cputcxy
    // [2147] phi from display_frame::@32 to cputcxy [phi:display_frame::@32->cputcxy]
    // [2147] phi cputcxy::c#15 = cputcxy::c#6 [phi:display_frame::@32->cputcxy#0] -- register_copy 
    // [2147] phi cputcxy::y#15 = cputcxy::y#6 [phi:display_frame::@32->cputcxy#1] -- register_copy 
    // [2147] phi cputcxy::x#15 = cputcxy::x#6 [phi:display_frame::@32->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@return
  __breturn:
    // }
    // [2656] return 
    rts
    // display_frame::@12
  __b12:
    // display_frame_maskxy(x, y)
    // [2657] display_frame_maskxy::x#7 = display_frame::x#18
    // [2658] display_frame_maskxy::y#7 = display_frame::y#10
    // [2659] call display_frame_maskxy
    // [2954] phi from display_frame::@12 to display_frame_maskxy [phi:display_frame::@12->display_frame_maskxy]
    // [2954] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#7 [phi:display_frame::@12->display_frame_maskxy#0] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.y_1
    sta display_frame_maskxy.cpeekcxy1_y
    // [2954] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#7 [phi:display_frame::@12->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [2660] display_frame_maskxy::return#20 = display_frame_maskxy::return#12
    // display_frame::@33
    // mask = display_frame_maskxy(x, y)
    // [2661] display_frame::mask#14 = display_frame_maskxy::return#20
    // mask |= 0b0101
    // [2662] display_frame::mask#15 = display_frame::mask#14 | 5 -- vbuz1=vbuz1_bor_vbuc1 
    lda #5
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [2663] display_frame_char::mask#7 = display_frame::mask#15
    // [2664] call display_frame_char
    // [2980] phi from display_frame::@33 to display_frame_char [phi:display_frame::@33->display_frame_char]
    // [2980] phi display_frame_char::mask#10 = display_frame_char::mask#7 [phi:display_frame::@33->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [2665] display_frame_char::return#20 = display_frame_char::return#12
    // display_frame::@34
    // c = display_frame_char(mask)
    // [2666] display_frame::c#7 = display_frame_char::return#20
    // cputcxy(x, y, c)
    // [2667] cputcxy::x#7 = display_frame::x#18 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [2668] cputcxy::y#7 = display_frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta cputcxy.y
    // [2669] cputcxy::c#7 = display_frame::c#7 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [2670] call cputcxy
    // [2147] phi from display_frame::@34 to cputcxy [phi:display_frame::@34->cputcxy]
    // [2147] phi cputcxy::c#15 = cputcxy::c#7 [phi:display_frame::@34->cputcxy#0] -- register_copy 
    // [2147] phi cputcxy::y#15 = cputcxy::y#7 [phi:display_frame::@34->cputcxy#1] -- register_copy 
    // [2147] phi cputcxy::x#15 = cputcxy::x#7 [phi:display_frame::@34->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@35
    // x++;
    // [2671] display_frame::x#5 = ++ display_frame::x#18 -- vbuz1=_inc_vbuz1 
    inc.z x
    jmp __b11
    // display_frame::@7
  __b7:
    // display_frame_maskxy(x0, y)
    // [2672] display_frame_maskxy::x#3 = display_frame::x#0
    // [2673] display_frame_maskxy::y#3 = display_frame::y#10
    // [2674] call display_frame_maskxy
    // [2954] phi from display_frame::@7 to display_frame_maskxy [phi:display_frame::@7->display_frame_maskxy]
    // [2954] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#3 [phi:display_frame::@7->display_frame_maskxy#0] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.y_1
    sta display_frame_maskxy.cpeekcxy1_y
    // [2954] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#3 [phi:display_frame::@7->display_frame_maskxy#1] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.x
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x0, y)
    // [2675] display_frame_maskxy::return#16 = display_frame_maskxy::return#12
    // display_frame::@22
    // mask = display_frame_maskxy(x0, y)
    // [2676] display_frame::mask#6 = display_frame_maskxy::return#16
    // mask |= 0b1010
    // [2677] display_frame::mask#7 = display_frame::mask#6 | $a -- vbuz1=vbuz1_bor_vbuc1 
    lda #$a
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [2678] display_frame_char::mask#3 = display_frame::mask#7
    // [2679] call display_frame_char
    // [2980] phi from display_frame::@22 to display_frame_char [phi:display_frame::@22->display_frame_char]
    // [2980] phi display_frame_char::mask#10 = display_frame_char::mask#3 [phi:display_frame::@22->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [2680] display_frame_char::return#16 = display_frame_char::return#12
    // display_frame::@23
    // c = display_frame_char(mask)
    // [2681] display_frame::c#3 = display_frame_char::return#16
    // cputcxy(x0, y, c)
    // [2682] cputcxy::x#3 = display_frame::x#0 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [2683] cputcxy::y#3 = display_frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta cputcxy.y
    // [2684] cputcxy::c#3 = display_frame::c#3 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [2685] call cputcxy
    // [2147] phi from display_frame::@23 to cputcxy [phi:display_frame::@23->cputcxy]
    // [2147] phi cputcxy::c#15 = cputcxy::c#3 [phi:display_frame::@23->cputcxy#0] -- register_copy 
    // [2147] phi cputcxy::y#15 = cputcxy::y#3 [phi:display_frame::@23->cputcxy#1] -- register_copy 
    // [2147] phi cputcxy::x#15 = cputcxy::x#3 [phi:display_frame::@23->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@24
    // display_frame_maskxy(x1, y)
    // [2686] display_frame_maskxy::x#4 = display_frame::x1#16
    // [2687] display_frame_maskxy::y#4 = display_frame::y#10
    // [2688] call display_frame_maskxy
    // [2954] phi from display_frame::@24 to display_frame_maskxy [phi:display_frame::@24->display_frame_maskxy]
    // [2954] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#4 [phi:display_frame::@24->display_frame_maskxy#0] -- vbum1=vbuz2 
    lda.z display_frame_maskxy.y_1
    sta display_frame_maskxy.cpeekcxy1_y
    // [2954] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#4 [phi:display_frame::@24->display_frame_maskxy#1] -- vbum1=vbum2 
    lda display_frame_maskxy.x_2
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x1, y)
    // [2689] display_frame_maskxy::return#17 = display_frame_maskxy::return#12
    // display_frame::@25
    // mask = display_frame_maskxy(x1, y)
    // [2690] display_frame::mask#8 = display_frame_maskxy::return#17
    // mask |= 0b1010
    // [2691] display_frame::mask#9 = display_frame::mask#8 | $a -- vbuz1=vbuz1_bor_vbuc1 
    lda #$a
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [2692] display_frame_char::mask#4 = display_frame::mask#9
    // [2693] call display_frame_char
    // [2980] phi from display_frame::@25 to display_frame_char [phi:display_frame::@25->display_frame_char]
    // [2980] phi display_frame_char::mask#10 = display_frame_char::mask#4 [phi:display_frame::@25->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [2694] display_frame_char::return#17 = display_frame_char::return#12
    // display_frame::@26
    // c = display_frame_char(mask)
    // [2695] display_frame::c#4 = display_frame_char::return#17
    // cputcxy(x1, y, c)
    // [2696] cputcxy::x#4 = display_frame::x1#16 -- vbum1=vbum2 
    lda x1
    sta cputcxy.x
    // [2697] cputcxy::y#4 = display_frame::y#10 -- vbum1=vbuz2 
    lda.z y_1
    sta cputcxy.y
    // [2698] cputcxy::c#4 = display_frame::c#4 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [2699] call cputcxy
    // [2147] phi from display_frame::@26 to cputcxy [phi:display_frame::@26->cputcxy]
    // [2147] phi cputcxy::c#15 = cputcxy::c#4 [phi:display_frame::@26->cputcxy#0] -- register_copy 
    // [2147] phi cputcxy::y#15 = cputcxy::y#4 [phi:display_frame::@26->cputcxy#1] -- register_copy 
    // [2147] phi cputcxy::x#15 = cputcxy::x#4 [phi:display_frame::@26->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@27
    // y++;
    // [2700] display_frame::y#2 = ++ display_frame::y#10 -- vbuz1=_inc_vbuz1 
    inc.z y_1
    jmp __b6
    // display_frame::@5
  __b5:
    // display_frame_maskxy(x, y)
    // [2701] display_frame_maskxy::x#2 = display_frame::x#10
    // [2702] display_frame_maskxy::y#2 = display_frame::y#0
    // [2703] call display_frame_maskxy
    // [2954] phi from display_frame::@5 to display_frame_maskxy [phi:display_frame::@5->display_frame_maskxy]
    // [2954] phi display_frame_maskxy::cpeekcxy1_y#0 = display_frame_maskxy::y#2 [phi:display_frame::@5->display_frame_maskxy#0] -- vbum1=vbum2 
    lda display_frame_maskxy.y
    sta display_frame_maskxy.cpeekcxy1_y
    // [2954] phi display_frame_maskxy::cpeekcxy1_x#0 = display_frame_maskxy::x#2 [phi:display_frame::@5->display_frame_maskxy#1] -- vbum1=vbum2 
    lda display_frame_maskxy.x_1
    sta display_frame_maskxy.cpeekcxy1_x
    jsr display_frame_maskxy
    // display_frame_maskxy(x, y)
    // [2704] display_frame_maskxy::return#15 = display_frame_maskxy::return#12
    // display_frame::@19
    // mask = display_frame_maskxy(x, y)
    // [2705] display_frame::mask#4 = display_frame_maskxy::return#15
    // mask |= 0b0101
    // [2706] display_frame::mask#5 = display_frame::mask#4 | 5 -- vbuz1=vbuz1_bor_vbuc1 
    lda #5
    ora.z mask
    sta.z mask
    // display_frame_char(mask)
    // [2707] display_frame_char::mask#2 = display_frame::mask#5
    // [2708] call display_frame_char
    // [2980] phi from display_frame::@19 to display_frame_char [phi:display_frame::@19->display_frame_char]
    // [2980] phi display_frame_char::mask#10 = display_frame_char::mask#2 [phi:display_frame::@19->display_frame_char#0] -- register_copy 
    jsr display_frame_char
    // display_frame_char(mask)
    // [2709] display_frame_char::return#15 = display_frame_char::return#12
    // display_frame::@20
    // c = display_frame_char(mask)
    // [2710] display_frame::c#2 = display_frame_char::return#15
    // cputcxy(x, y, c)
    // [2711] cputcxy::x#2 = display_frame::x#10 -- vbum1=vbum2 
    lda x_1
    sta cputcxy.x
    // [2712] cputcxy::y#2 = display_frame::y#0 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [2713] cputcxy::c#2 = display_frame::c#2 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [2714] call cputcxy
    // [2147] phi from display_frame::@20 to cputcxy [phi:display_frame::@20->cputcxy]
    // [2147] phi cputcxy::c#15 = cputcxy::c#2 [phi:display_frame::@20->cputcxy#0] -- register_copy 
    // [2147] phi cputcxy::y#15 = cputcxy::y#2 [phi:display_frame::@20->cputcxy#1] -- register_copy 
    // [2147] phi cputcxy::x#15 = cputcxy::x#2 [phi:display_frame::@20->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_frame::@21
    // x++;
    // [2715] display_frame::x#2 = ++ display_frame::x#10 -- vbum1=_inc_vbum1 
    inc x_1
    jmp __b4
    // display_frame::@36
  __b36:
    // [2716] display_frame::x#30 = display_frame::x#0 -- vbum1=vbuz2 
    lda.z x
    sta x_1
    jmp __b1
  .segment Data
    .label y = main.main__52
    .label x_1 = main.check_status_smc9_main__0
    .label x1 = main.check_status_smc8_main__0
    .label y1 = main.check_status_vera1_main__0
}
.segment Code
  // cputs
// Output a NUL-terminated string at the current cursor position
// void cputs(__zp($b2) const char *s)
cputs: {
    .label s = $b2
    // [2718] phi from cputs cputs::@2 to cputs::@1 [phi:cputs/cputs::@2->cputs::@1]
    // [2718] phi cputs::s#2 = cputs::s#1 [phi:cputs/cputs::@2->cputs::@1#0] -- register_copy 
    // cputs::@1
  __b1:
    // while(c=*s++)
    // [2719] cputs::c#1 = *cputs::s#2 -- vbum1=_deref_pbuz2 
    ldy #0
    lda (s),y
    sta c
    // [2720] cputs::s#0 = ++ cputs::s#2 -- pbuz1=_inc_pbuz1 
    inc.z s
    bne !+
    inc.z s+1
  !:
    // [2721] if(0!=cputs::c#1) goto cputs::@2 -- 0_neq_vbum1_then_la1 
    lda c
    bne __b2
    // cputs::@return
    // }
    // [2722] return 
    rts
    // cputs::@2
  __b2:
    // cputc(c)
    // [2723] stackpush(char) = cputs::c#1 -- _stackpushbyte_=vbum1 
    lda c
    pha
    // [2724] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    jmp __b1
  .segment Data
    c: .byte 0
}
.segment Code
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
// void display_chip_led(__zp($ae) char x, char y, __zp($ad) char w, __zp($bf) char tc, char bc)
display_chip_led: {
    .label x = $ae
    .label w = $ad
    .label tc = $bf
    // textcolor(tc)
    // [2727] textcolor::color#11 = display_chip_led::tc#3 -- vbum1=vbuz2 
    lda.z tc
    sta textcolor.color
    // [2728] call textcolor
    // [760] phi from display_chip_led to textcolor [phi:display_chip_led->textcolor]
    // [760] phi textcolor::color#23 = textcolor::color#11 [phi:display_chip_led->textcolor#0] -- register_copy 
    jsr textcolor
    // [2729] phi from display_chip_led to display_chip_led::@3 [phi:display_chip_led->display_chip_led::@3]
    // display_chip_led::@3
    // bgcolor(bc)
    // [2730] call bgcolor
    // [765] phi from display_chip_led::@3 to bgcolor [phi:display_chip_led::@3->bgcolor]
    // [765] phi bgcolor::color#15 = BLUE [phi:display_chip_led::@3->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // [2731] phi from display_chip_led::@3 display_chip_led::@5 to display_chip_led::@1 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1]
    // [2731] phi display_chip_led::w#4 = display_chip_led::w#7 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1#0] -- register_copy 
    // [2731] phi display_chip_led::x#4 = display_chip_led::x#7 [phi:display_chip_led::@3/display_chip_led::@5->display_chip_led::@1#1] -- register_copy 
    // display_chip_led::@1
  __b1:
    // cputcxy(x, y, 0x6F)
    // [2732] cputcxy::x#9 = display_chip_led::x#4 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [2733] call cputcxy
    // [2147] phi from display_chip_led::@1 to cputcxy [phi:display_chip_led::@1->cputcxy]
    // [2147] phi cputcxy::c#15 = $6f [phi:display_chip_led::@1->cputcxy#0] -- vbum1=vbuc1 
    lda #$6f
    sta cputcxy.c
    // [2147] phi cputcxy::y#15 = 3 [phi:display_chip_led::@1->cputcxy#1] -- vbum1=vbuc1 
    lda #3
    sta cputcxy.y
    // [2147] phi cputcxy::x#15 = cputcxy::x#9 [phi:display_chip_led::@1->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_led::@4
    // cputcxy(x, y+1, 0x77)
    // [2734] cputcxy::x#10 = display_chip_led::x#4 -- vbum1=vbuz2 
    lda.z x
    sta cputcxy.x
    // [2735] call cputcxy
    // [2147] phi from display_chip_led::@4 to cputcxy [phi:display_chip_led::@4->cputcxy]
    // [2147] phi cputcxy::c#15 = $77 [phi:display_chip_led::@4->cputcxy#0] -- vbum1=vbuc1 
    lda #$77
    sta cputcxy.c
    // [2147] phi cputcxy::y#15 = 3+1 [phi:display_chip_led::@4->cputcxy#1] -- vbum1=vbuc1 
    lda #3+1
    sta cputcxy.y
    // [2147] phi cputcxy::x#15 = cputcxy::x#10 [phi:display_chip_led::@4->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_led::@5
    // x++;
    // [2736] display_chip_led::x#0 = ++ display_chip_led::x#4 -- vbuz1=_inc_vbuz1 
    inc.z x
    // while(--w)
    // [2737] display_chip_led::w#0 = -- display_chip_led::w#4 -- vbuz1=_dec_vbuz1 
    dec.z w
    // [2738] if(0!=display_chip_led::w#0) goto display_chip_led::@1 -- 0_neq_vbuz1_then_la1 
    lda.z w
    bne __b1
    // [2739] phi from display_chip_led::@5 to display_chip_led::@2 [phi:display_chip_led::@5->display_chip_led::@2]
    // display_chip_led::@2
    // textcolor(WHITE)
    // [2740] call textcolor
    // [760] phi from display_chip_led::@2 to textcolor [phi:display_chip_led::@2->textcolor]
    // [760] phi textcolor::color#23 = WHITE [phi:display_chip_led::@2->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [2741] phi from display_chip_led::@2 to display_chip_led::@6 [phi:display_chip_led::@2->display_chip_led::@6]
    // display_chip_led::@6
    // bgcolor(BLUE)
    // [2742] call bgcolor
    // [765] phi from display_chip_led::@6 to bgcolor [phi:display_chip_led::@6->bgcolor]
    // [765] phi bgcolor::color#15 = BLUE [phi:display_chip_led::@6->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_led::@return
    // }
    // [2743] return 
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
// void display_chip_line(__zp($fa) char x, __mem() char y, __zp($de) char w, __zp($ef) char c)
display_chip_line: {
    .label i = $be
    .label x = $fa
    .label w = $de
    .label c = $ef
    // gotoxy(x, y)
    // [2745] gotoxy::x#7 = display_chip_line::x#16 -- vbum1=vbuz2 
    lda.z x
    sta gotoxy.x
    // [2746] gotoxy::y#7 = display_chip_line::y#16 -- vbum1=vbum2 
    lda y
    sta gotoxy.y
    // [2747] call gotoxy
    // [778] phi from display_chip_line to gotoxy [phi:display_chip_line->gotoxy]
    // [778] phi gotoxy::y#33 = gotoxy::y#7 [phi:display_chip_line->gotoxy#0] -- register_copy 
    // [778] phi gotoxy::x#33 = gotoxy::x#7 [phi:display_chip_line->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [2748] phi from display_chip_line to display_chip_line::@4 [phi:display_chip_line->display_chip_line::@4]
    // display_chip_line::@4
    // textcolor(GREY)
    // [2749] call textcolor
    // [760] phi from display_chip_line::@4 to textcolor [phi:display_chip_line::@4->textcolor]
    // [760] phi textcolor::color#23 = GREY [phi:display_chip_line::@4->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [2750] phi from display_chip_line::@4 to display_chip_line::@5 [phi:display_chip_line::@4->display_chip_line::@5]
    // display_chip_line::@5
    // bgcolor(BLUE)
    // [2751] call bgcolor
    // [765] phi from display_chip_line::@5 to bgcolor [phi:display_chip_line::@5->bgcolor]
    // [765] phi bgcolor::color#15 = BLUE [phi:display_chip_line::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_line::@6
    // cputc(VERA_CHR_UR)
    // [2752] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [2753] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [2755] call textcolor
    // [760] phi from display_chip_line::@6 to textcolor [phi:display_chip_line::@6->textcolor]
    // [760] phi textcolor::color#23 = WHITE [phi:display_chip_line::@6->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [2756] phi from display_chip_line::@6 to display_chip_line::@7 [phi:display_chip_line::@6->display_chip_line::@7]
    // display_chip_line::@7
    // bgcolor(BLACK)
    // [2757] call bgcolor
    // [765] phi from display_chip_line::@7 to bgcolor [phi:display_chip_line::@7->bgcolor]
    // [765] phi bgcolor::color#15 = BLACK [phi:display_chip_line::@7->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // [2758] phi from display_chip_line::@7 to display_chip_line::@1 [phi:display_chip_line::@7->display_chip_line::@1]
    // [2758] phi display_chip_line::i#2 = 0 [phi:display_chip_line::@7->display_chip_line::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // display_chip_line::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [2759] if(display_chip_line::i#2<display_chip_line::w#10) goto display_chip_line::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [2760] phi from display_chip_line::@1 to display_chip_line::@3 [phi:display_chip_line::@1->display_chip_line::@3]
    // display_chip_line::@3
    // textcolor(GREY)
    // [2761] call textcolor
    // [760] phi from display_chip_line::@3 to textcolor [phi:display_chip_line::@3->textcolor]
    // [760] phi textcolor::color#23 = GREY [phi:display_chip_line::@3->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [2762] phi from display_chip_line::@3 to display_chip_line::@8 [phi:display_chip_line::@3->display_chip_line::@8]
    // display_chip_line::@8
    // bgcolor(BLUE)
    // [2763] call bgcolor
    // [765] phi from display_chip_line::@8 to bgcolor [phi:display_chip_line::@8->bgcolor]
    // [765] phi bgcolor::color#15 = BLUE [phi:display_chip_line::@8->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_line::@9
    // cputc(VERA_CHR_UL)
    // [2764] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [2765] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(WHITE)
    // [2767] call textcolor
    // [760] phi from display_chip_line::@9 to textcolor [phi:display_chip_line::@9->textcolor]
    // [760] phi textcolor::color#23 = WHITE [phi:display_chip_line::@9->textcolor#0] -- vbum1=vbuc1 
    lda #WHITE
    sta textcolor.color
    jsr textcolor
    // [2768] phi from display_chip_line::@9 to display_chip_line::@10 [phi:display_chip_line::@9->display_chip_line::@10]
    // display_chip_line::@10
    // bgcolor(BLACK)
    // [2769] call bgcolor
    // [765] phi from display_chip_line::@10 to bgcolor [phi:display_chip_line::@10->bgcolor]
    // [765] phi bgcolor::color#15 = BLACK [phi:display_chip_line::@10->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // display_chip_line::@11
    // cputcxy(x+2, y, c)
    // [2770] cputcxy::x#8 = display_chip_line::x#16 + 2 -- vbum1=vbuz2_plus_2 
    lda.z x
    clc
    adc #2
    sta cputcxy.x
    // [2771] cputcxy::y#8 = display_chip_line::y#16 -- vbum1=vbum2 
    lda y
    sta cputcxy.y
    // [2772] cputcxy::c#8 = display_chip_line::c#15 -- vbum1=vbuz2 
    lda.z c
    sta cputcxy.c
    // [2773] call cputcxy
    // [2147] phi from display_chip_line::@11 to cputcxy [phi:display_chip_line::@11->cputcxy]
    // [2147] phi cputcxy::c#15 = cputcxy::c#8 [phi:display_chip_line::@11->cputcxy#0] -- register_copy 
    // [2147] phi cputcxy::y#15 = cputcxy::y#8 [phi:display_chip_line::@11->cputcxy#1] -- register_copy 
    // [2147] phi cputcxy::x#15 = cputcxy::x#8 [phi:display_chip_line::@11->cputcxy#2] -- register_copy 
    jsr cputcxy
    // display_chip_line::@return
    // }
    // [2774] return 
    rts
    // display_chip_line::@2
  __b2:
    // cputc(VERA_CHR_SPACE)
    // [2775] stackpush(char) = $20 -- _stackpushbyte_=vbuc1 
    lda #$20
    pha
    // [2776] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [2778] display_chip_line::i#1 = ++ display_chip_line::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2758] phi from display_chip_line::@2 to display_chip_line::@1 [phi:display_chip_line::@2->display_chip_line::@1]
    // [2758] phi display_chip_line::i#2 = display_chip_line::i#1 [phi:display_chip_line::@2->display_chip_line::@1#0] -- register_copy 
    jmp __b1
  .segment Data
    .label y = main.check_status_vera6_main__0
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
// void display_chip_end(__zp($cc) char x, char y, __zp($af) char w)
display_chip_end: {
    .label i = $bd
    .label x = $cc
    .label w = $af
    // gotoxy(x, y)
    // [2779] gotoxy::x#8 = display_chip_end::x#0 -- vbum1=vbuz2 
    lda.z x
    sta gotoxy.x
    // [2780] call gotoxy
    // [778] phi from display_chip_end to gotoxy [phi:display_chip_end->gotoxy]
    // [778] phi gotoxy::y#33 = display_print_chip::y#21 [phi:display_chip_end->gotoxy#0] -- vbum1=vbuc1 
    lda #display_print_chip.y
    sta gotoxy.y
    // [778] phi gotoxy::x#33 = gotoxy::x#8 [phi:display_chip_end->gotoxy#1] -- register_copy 
    jsr gotoxy
    // [2781] phi from display_chip_end to display_chip_end::@4 [phi:display_chip_end->display_chip_end::@4]
    // display_chip_end::@4
    // textcolor(GREY)
    // [2782] call textcolor
    // [760] phi from display_chip_end::@4 to textcolor [phi:display_chip_end::@4->textcolor]
    // [760] phi textcolor::color#23 = GREY [phi:display_chip_end::@4->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [2783] phi from display_chip_end::@4 to display_chip_end::@5 [phi:display_chip_end::@4->display_chip_end::@5]
    // display_chip_end::@5
    // bgcolor(BLUE)
    // [2784] call bgcolor
    // [765] phi from display_chip_end::@5 to bgcolor [phi:display_chip_end::@5->bgcolor]
    // [765] phi bgcolor::color#15 = BLUE [phi:display_chip_end::@5->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_end::@6
    // cputc(VERA_CHR_UR)
    // [2785] stackpush(char) = $7c -- _stackpushbyte_=vbuc1 
    lda #$7c
    pha
    // [2786] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // textcolor(BLUE)
    // [2788] call textcolor
    // [760] phi from display_chip_end::@6 to textcolor [phi:display_chip_end::@6->textcolor]
    // [760] phi textcolor::color#23 = BLUE [phi:display_chip_end::@6->textcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta textcolor.color
    jsr textcolor
    // [2789] phi from display_chip_end::@6 to display_chip_end::@7 [phi:display_chip_end::@6->display_chip_end::@7]
    // display_chip_end::@7
    // bgcolor(BLACK)
    // [2790] call bgcolor
    // [765] phi from display_chip_end::@7 to bgcolor [phi:display_chip_end::@7->bgcolor]
    // [765] phi bgcolor::color#15 = BLACK [phi:display_chip_end::@7->bgcolor#0] -- vbum1=vbuc1 
    lda #BLACK
    sta bgcolor.color
    jsr bgcolor
    // [2791] phi from display_chip_end::@7 to display_chip_end::@1 [phi:display_chip_end::@7->display_chip_end::@1]
    // [2791] phi display_chip_end::i#2 = 0 [phi:display_chip_end::@7->display_chip_end::@1#0] -- vbuz1=vbuc1 
    lda #0
    sta.z i
    // display_chip_end::@1
  __b1:
    // for(char i=0; i<w; i++)
    // [2792] if(display_chip_end::i#2<display_chip_end::w#0) goto display_chip_end::@2 -- vbuz1_lt_vbuz2_then_la1 
    lda.z i
    cmp.z w
    bcc __b2
    // [2793] phi from display_chip_end::@1 to display_chip_end::@3 [phi:display_chip_end::@1->display_chip_end::@3]
    // display_chip_end::@3
    // textcolor(GREY)
    // [2794] call textcolor
    // [760] phi from display_chip_end::@3 to textcolor [phi:display_chip_end::@3->textcolor]
    // [760] phi textcolor::color#23 = GREY [phi:display_chip_end::@3->textcolor#0] -- vbum1=vbuc1 
    lda #GREY
    sta textcolor.color
    jsr textcolor
    // [2795] phi from display_chip_end::@3 to display_chip_end::@8 [phi:display_chip_end::@3->display_chip_end::@8]
    // display_chip_end::@8
    // bgcolor(BLUE)
    // [2796] call bgcolor
    // [765] phi from display_chip_end::@8 to bgcolor [phi:display_chip_end::@8->bgcolor]
    // [765] phi bgcolor::color#15 = BLUE [phi:display_chip_end::@8->bgcolor#0] -- vbum1=vbuc1 
    lda #BLUE
    sta bgcolor.color
    jsr bgcolor
    // display_chip_end::@9
    // cputc(VERA_CHR_UL)
    // [2797] stackpush(char) = $7e -- _stackpushbyte_=vbuc1 
    lda #$7e
    pha
    // [2798] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // display_chip_end::@return
    // }
    // [2800] return 
    rts
    // display_chip_end::@2
  __b2:
    // cputc(VERA_CHR_HL)
    // [2801] stackpush(char) = $62 -- _stackpushbyte_=vbuc1 
    lda #$62
    pha
    // [2802] callexecute cputc  -- call_vprc1 
    jsr cputc
    // sideeffect stackpullpadding(1) -- _stackpullpadding_1 
    pla
    // for(char i=0; i<w; i++)
    // [2804] display_chip_end::i#1 = ++ display_chip_end::i#2 -- vbuz1=_inc_vbuz1 
    inc.z i
    // [2791] phi from display_chip_end::@2 to display_chip_end::@1 [phi:display_chip_end::@2->display_chip_end::@1]
    // [2791] phi display_chip_end::i#2 = display_chip_end::i#1 [phi:display_chip_end::@2->display_chip_end::@1#0] -- register_copy 
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
// void rom_write_byte(__zp($49) unsigned long address, __zp($4d) char value)
rom_write_byte: {
    .label rom_bank1_rom_write_byte__0 = $38
    .label rom_bank1_rom_write_byte__1 = $43
    .label rom_bank1_rom_write_byte__2 = $3b
    .label rom_ptr1_rom_write_byte__0 = $39
    .label rom_ptr1_rom_write_byte__2 = $39
    .label rom_bank1_bank_unshifted = $3b
    .label rom_bank1_return = $2a
    .label rom_ptr1_return = $39
    .label address = $49
    .label value = $4d
    // rom_write_byte::rom_bank1
    // BYTE2(address)
    // [2806] rom_write_byte::rom_bank1_$0 = byte2  rom_write_byte::address#4 -- vbuz1=_byte2_vduz2 
    lda.z address+2
    sta.z rom_bank1_rom_write_byte__0
    // BYTE1(address)
    // [2807] rom_write_byte::rom_bank1_$1 = byte1  rom_write_byte::address#4 -- vbuz1=_byte1_vduz2 
    lda.z address+1
    sta.z rom_bank1_rom_write_byte__1
    // MAKEWORD(BYTE2(address),BYTE1(address))
    // [2808] rom_write_byte::rom_bank1_$2 = rom_write_byte::rom_bank1_$0 w= rom_write_byte::rom_bank1_$1 -- vwuz1=vbuz2_word_vbuz3 
    lda.z rom_bank1_rom_write_byte__0
    sta.z rom_bank1_rom_write_byte__2+1
    lda.z rom_bank1_rom_write_byte__1
    sta.z rom_bank1_rom_write_byte__2
    // unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2
    // [2809] rom_write_byte::rom_bank1_bank_unshifted#0 = rom_write_byte::rom_bank1_$2 << 2 -- vwuz1=vwuz1_rol_2 
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    asl.z rom_bank1_bank_unshifted
    rol.z rom_bank1_bank_unshifted+1
    // unsigned char bank = BYTE1(bank_unshifted)
    // [2810] rom_write_byte::rom_bank1_return#0 = byte1  rom_write_byte::rom_bank1_bank_unshifted#0 -- vbuz1=_byte1_vwuz2 
    lda.z rom_bank1_bank_unshifted+1
    sta.z rom_bank1_return
    // rom_write_byte::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2811] rom_write_byte::rom_ptr1_$2 = (unsigned int)rom_write_byte::address#4 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_write_byte__2
    lda.z address+1
    sta.z rom_ptr1_rom_write_byte__2+1
    // [2812] rom_write_byte::rom_ptr1_$0 = rom_write_byte::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_write_byte__0
    and #<$3fff
    sta.z rom_ptr1_rom_write_byte__0
    lda.z rom_ptr1_rom_write_byte__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_write_byte__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2813] rom_write_byte::rom_ptr1_return#0 = rom_write_byte::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_write_byte::bank_set_brom1
    // BROM = bank
    // [2814] BROM = rom_write_byte::rom_bank1_return#0 -- vbuz1=vbuz2 
    lda.z rom_bank1_return
    sta.z BROM
    // rom_write_byte::@1
    // *ptr_rom = value
    // [2815] *((char *)rom_write_byte::rom_ptr1_return#0) = rom_write_byte::value#10 -- _deref_pbuz1=vbuz2 
    lda.z value
    ldy #0
    sta (rom_ptr1_return),y
    // rom_write_byte::@return
    // }
    // [2816] return 
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
// __mem() char uctoa_append(__zp($47) char *buffer, __mem() char value, __mem() char sub)
uctoa_append: {
    .label buffer = $47
    // [2818] phi from uctoa_append to uctoa_append::@1 [phi:uctoa_append->uctoa_append::@1]
    // [2818] phi uctoa_append::digit#2 = 0 [phi:uctoa_append->uctoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [2818] phi uctoa_append::value#2 = uctoa_append::value#0 [phi:uctoa_append->uctoa_append::@1#1] -- register_copy 
    // uctoa_append::@1
  __b1:
    // while (value >= sub)
    // [2819] if(uctoa_append::value#2>=uctoa_append::sub#0) goto uctoa_append::@2 -- vbum1_ge_vbum2_then_la1 
    lda value
    cmp sub
    bcs __b2
    // uctoa_append::@3
    // *buffer = DIGITS[digit]
    // [2820] *uctoa_append::buffer#0 = DIGITS[uctoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // uctoa_append::@return
    // }
    // [2821] return 
    rts
    // uctoa_append::@2
  __b2:
    // digit++;
    // [2822] uctoa_append::digit#1 = ++ uctoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [2823] uctoa_append::value#1 = uctoa_append::value#2 - uctoa_append::sub#0 -- vbum1=vbum1_minus_vbum2 
    lda value
    sec
    sbc sub
    sta value
    // [2818] phi from uctoa_append::@2 to uctoa_append::@1 [phi:uctoa_append::@2->uctoa_append::@1]
    // [2818] phi uctoa_append::digit#2 = uctoa_append::digit#1 [phi:uctoa_append::@2->uctoa_append::@1#0] -- register_copy 
    // [2818] phi uctoa_append::value#2 = uctoa_append::value#1 [phi:uctoa_append::@2->uctoa_append::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label value = printf_uchar.uvalue
    .label sub = uctoa.digit_value
    .label return = printf_uchar.uvalue
    digit: .byte 0
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
    // [2825] return 
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
// __mem() int ferror(__zp($47) struct $2 *stream)
ferror: {
    .label ferror__6 = $38
    .label ferror__15 = $43
    .label cbm_k_setnam1_ferror__0 = $3b
    .label stream = $47
    .label errno_len = $dd
    // unsigned char sp = (unsigned char)stream
    // [2826] ferror::sp#0 = (char)ferror::stream#0 -- vbum1=_byte_pssz2 
    lda.z stream
    sta sp
    // cbm_k_setlfs(15, 8, 15)
    // [2827] cbm_k_setlfs::channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.channel
    // [2828] cbm_k_setlfs::device = 8 -- vbum1=vbuc1 
    lda #8
    sta cbm_k_setlfs.device
    // [2829] cbm_k_setlfs::command = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_setlfs.command
    // [2830] call cbm_k_setlfs
    jsr cbm_k_setlfs
    // ferror::@11
    // cbm_k_setnam("")
    // [2831] ferror::cbm_k_setnam1_filename = info_text8 -- pbum1=pbuc1 
    lda #<info_text8
    sta cbm_k_setnam1_filename
    lda #>info_text8
    sta cbm_k_setnam1_filename+1
    // ferror::cbm_k_setnam1
    // strlen(filename)
    // [2832] strlen::str#5 = ferror::cbm_k_setnam1_filename -- pbuz1=pbum2 
    lda cbm_k_setnam1_filename
    sta.z strlen.str
    lda cbm_k_setnam1_filename+1
    sta.z strlen.str+1
    // [2833] call strlen
    // [2155] phi from ferror::cbm_k_setnam1 to strlen [phi:ferror::cbm_k_setnam1->strlen]
    // [2155] phi strlen::str#8 = strlen::str#5 [phi:ferror::cbm_k_setnam1->strlen#0] -- register_copy 
    jsr strlen
    // strlen(filename)
    // [2834] strlen::return#12 = strlen::len#2
    // ferror::@12
    // [2835] ferror::cbm_k_setnam1_$0 = strlen::return#12 -- vwuz1=vwum2 
    lda strlen.return
    sta.z cbm_k_setnam1_ferror__0
    lda strlen.return+1
    sta.z cbm_k_setnam1_ferror__0+1
    // char filename_len = (char)strlen(filename)
    // [2836] ferror::cbm_k_setnam1_filename_len = (char)ferror::cbm_k_setnam1_$0 -- vbum1=_byte_vwuz2 
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
    // [2839] ferror::cbm_k_chkin1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_chkin1_channel
    // ferror::cbm_k_chkin1
    // char status
    // [2840] ferror::cbm_k_chkin1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chkin1_status
    // asm
    // asm { ldxchannel jsrCBM_CHKIN stastatus  }
    ldx cbm_k_chkin1_channel
    jsr CBM_CHKIN
    sta cbm_k_chkin1_status
    // ferror::cbm_k_chrin1
    // char ch
    // [2842] ferror::cbm_k_chrin1_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin1_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin1_ch
    // return ch;
    // [2844] ferror::cbm_k_chrin1_return#0 = ferror::cbm_k_chrin1_ch -- vbum1=vbum2 
    sta cbm_k_chrin1_return
    // ferror::cbm_k_chrin1_@return
    // }
    // [2845] ferror::cbm_k_chrin1_return#1 = ferror::cbm_k_chrin1_return#0
    // ferror::@7
    // char ch = cbm_k_chrin()
    // [2846] ferror::ch#0 = ferror::cbm_k_chrin1_return#1
    // [2847] phi from ferror::@7 to ferror::cbm_k_readst1 [phi:ferror::@7->ferror::cbm_k_readst1]
    // [2847] phi __errno#18 = __errno#322 [phi:ferror::@7->ferror::cbm_k_readst1#0] -- register_copy 
    // [2847] phi ferror::errno_len#10 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#1] -- vbuz1=vbuc1 
    lda #0
    sta.z errno_len
    // [2847] phi ferror::ch#10 = ferror::ch#0 [phi:ferror::@7->ferror::cbm_k_readst1#2] -- register_copy 
    // [2847] phi ferror::errno_parsed#2 = 0 [phi:ferror::@7->ferror::cbm_k_readst1#3] -- vbum1=vbuc1 
    sta errno_parsed
    // ferror::cbm_k_readst1
  cbm_k_readst1:
    // char status
    // [2848] ferror::cbm_k_readst1_status = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_readst1_status
    // asm
    // asm { jsrCBM_READST stastatus  }
    jsr CBM_READST
    sta cbm_k_readst1_status
    // return status;
    // [2850] ferror::cbm_k_readst1_return#0 = ferror::cbm_k_readst1_status -- vbum1=vbum2 
    sta cbm_k_readst1_return
    // ferror::cbm_k_readst1_@return
    // }
    // [2851] ferror::cbm_k_readst1_return#1 = ferror::cbm_k_readst1_return#0
    // ferror::@8
    // cbm_k_readst()
    // [2852] ferror::$6 = ferror::cbm_k_readst1_return#1 -- vbuz1=vbum2 
    sta.z ferror__6
    // st = cbm_k_readst()
    // [2853] ferror::st#1 = ferror::$6 -- vbum1=vbuz2 
    sta st
    // while (!(st = cbm_k_readst()))
    // [2854] if(0==ferror::st#1) goto ferror::@1 -- 0_eq_vbum1_then_la1 
    beq __b1
    // ferror::@2
    // __status = st
    // [2855] ((char *)&__stdio_file+$46)[ferror::sp#0] = ferror::st#1 -- pbuc1_derefidx_vbum1=vbum2 
    ldy sp
    sta __stdio_file+$46,y
    // cbm_k_close(15)
    // [2856] ferror::cbm_k_close1_channel = $f -- vbum1=vbuc1 
    lda #$f
    sta cbm_k_close1_channel
    // ferror::cbm_k_close1
    // asm
    // asm { ldachannel jsrCBM_CLOSE  }
    jsr CBM_CLOSE
    // ferror::@9
    // return __errno;
    // [2858] ferror::return#1 = __errno#18 -- vwsm1=vwsm2 
    lda __errno
    sta return
    lda __errno+1
    sta return+1
    // ferror::@return
    // }
    // [2859] return 
    rts
    // ferror::@1
  __b1:
    // if (!errno_parsed)
    // [2860] if(0!=ferror::errno_parsed#2) goto ferror::@3 -- 0_neq_vbum1_then_la1 
    lda errno_parsed
    bne __b3
    // ferror::@4
    // if (ch == ',')
    // [2861] if(ferror::ch#10!=',') goto ferror::@3 -- vbum1_neq_vbuc1_then_la1 
    lda #','
    cmp ch
    bne __b3
    // ferror::@5
    // errno_parsed++;
    // [2862] ferror::errno_parsed#1 = ++ ferror::errno_parsed#2 -- vbum1=_inc_vbum1 
    inc errno_parsed
    // strncpy(temp, __errno_error, errno_len+1)
    // [2863] strncpy::n#0 = ferror::errno_len#10 + 1 -- vwum1=vbuz2_plus_1 
    lda.z errno_len
    clc
    adc #1
    sta strncpy.n
    lda #0
    adc #0
    sta strncpy.n+1
    // [2864] call strncpy
    // [2506] phi from ferror::@5 to strncpy [phi:ferror::@5->strncpy]
    // [2506] phi strncpy::dst#8 = ferror::temp [phi:ferror::@5->strncpy#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z strncpy.dst
    lda #>temp
    sta.z strncpy.dst+1
    // [2506] phi strncpy::src#6 = __errno_error [phi:ferror::@5->strncpy#1] -- pbuz1=pbuc1 
    lda #<__errno_error
    sta.z strncpy.src
    lda #>__errno_error
    sta.z strncpy.src+1
    // [2506] phi strncpy::n#3 = strncpy::n#0 [phi:ferror::@5->strncpy#2] -- register_copy 
    jsr strncpy
    // [2865] phi from ferror::@5 to ferror::@13 [phi:ferror::@5->ferror::@13]
    // ferror::@13
    // atoi(temp)
    // [2866] call atoi
    // [2878] phi from ferror::@13 to atoi [phi:ferror::@13->atoi]
    // [2878] phi atoi::str#2 = ferror::temp [phi:ferror::@13->atoi#0] -- pbuz1=pbuc1 
    lda #<temp
    sta.z atoi.str
    lda #>temp
    sta.z atoi.str+1
    jsr atoi
    // atoi(temp)
    // [2867] atoi::return#4 = atoi::return#2
    // ferror::@14
    // __errno = atoi(temp)
    // [2868] __errno#2 = atoi::return#4 -- vwsm1=vwsm2 
    lda atoi.return
    sta __errno
    lda atoi.return+1
    sta __errno+1
    // [2869] phi from ferror::@1 ferror::@14 ferror::@4 to ferror::@3 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3]
    // [2869] phi __errno#107 = __errno#18 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#0] -- register_copy 
    // [2869] phi ferror::errno_parsed#11 = ferror::errno_parsed#2 [phi:ferror::@1/ferror::@14/ferror::@4->ferror::@3#1] -- register_copy 
    // ferror::@3
  __b3:
    // __errno_error[errno_len] = ch
    // [2870] __errno_error[ferror::errno_len#10] = ferror::ch#10 -- pbuc1_derefidx_vbuz1=vbum2 
    lda ch
    ldy.z errno_len
    sta __errno_error,y
    // errno_len++;
    // [2871] ferror::errno_len#1 = ++ ferror::errno_len#10 -- vbuz1=_inc_vbuz1 
    inc.z errno_len
    // ferror::cbm_k_chrin2
    // char ch
    // [2872] ferror::cbm_k_chrin2_ch = 0 -- vbum1=vbuc1 
    lda #0
    sta cbm_k_chrin2_ch
    // asm
    // asm { jsrCBM_CHRIN stach  }
    jsr CBM_CHRIN
    sta cbm_k_chrin2_ch
    // return ch;
    // [2874] ferror::cbm_k_chrin2_return#0 = ferror::cbm_k_chrin2_ch -- vbum1=vbum2 
    sta cbm_k_chrin2_return
    // ferror::cbm_k_chrin2_@return
    // }
    // [2875] ferror::cbm_k_chrin2_return#1 = ferror::cbm_k_chrin2_return#0
    // ferror::@10
    // cbm_k_chrin()
    // [2876] ferror::$15 = ferror::cbm_k_chrin2_return#1 -- vbuz1=vbum2 
    sta.z ferror__15
    // ch = cbm_k_chrin()
    // [2877] ferror::ch#1 = ferror::$15 -- vbum1=vbuz2 
    sta ch
    // [2847] phi from ferror::@10 to ferror::cbm_k_readst1 [phi:ferror::@10->ferror::cbm_k_readst1]
    // [2847] phi __errno#18 = __errno#107 [phi:ferror::@10->ferror::cbm_k_readst1#0] -- register_copy 
    // [2847] phi ferror::errno_len#10 = ferror::errno_len#1 [phi:ferror::@10->ferror::cbm_k_readst1#1] -- register_copy 
    // [2847] phi ferror::ch#10 = ferror::ch#1 [phi:ferror::@10->ferror::cbm_k_readst1#2] -- register_copy 
    // [2847] phi ferror::errno_parsed#2 = ferror::errno_parsed#11 [phi:ferror::@10->ferror::cbm_k_readst1#3] -- register_copy 
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
    return: .word 0
    sp: .byte 0
    .label cbm_k_chrin1_return = ch
    ch: .byte 0
    cbm_k_readst1_return: .byte 0
    st: .byte 0
    cbm_k_chrin2_return: .byte 0
    errno_parsed: .byte 0
}
.segment Code
  // atoi
// Converts the string argument str to an integer.
// __mem() int atoi(__zp($b0) const char *str)
atoi: {
    .label atoi__6 = $39
    .label atoi__7 = $39
    .label str = $b0
    .label atoi__10 = $39
    .label atoi__11 = $39
    // if (str[i] == '-')
    // [2879] if(*atoi::str#2!='-') goto atoi::@3 -- _deref_pbuz1_neq_vbuc1_then_la1 
    ldy #0
    lda (str),y
    cmp #'-'
    bne __b2
    // [2880] phi from atoi to atoi::@2 [phi:atoi->atoi::@2]
    // atoi::@2
    // [2881] phi from atoi::@2 to atoi::@3 [phi:atoi::@2->atoi::@3]
    // [2881] phi atoi::negative#2 = 1 [phi:atoi::@2->atoi::@3#0] -- vbum1=vbuc1 
    lda #1
    sta negative
    // [2881] phi atoi::res#2 = 0 [phi:atoi::@2->atoi::@3#1] -- vwsm1=vwsc1 
    tya
    sta res
    sta res+1
    // [2881] phi atoi::i#4 = 1 [phi:atoi::@2->atoi::@3#2] -- vbum1=vbuc1 
    lda #1
    sta i
    jmp __b3
  // Iterate through all digits and update the result
    // [2881] phi from atoi to atoi::@3 [phi:atoi->atoi::@3]
  __b2:
    // [2881] phi atoi::negative#2 = 0 [phi:atoi->atoi::@3#0] -- vbum1=vbuc1 
    lda #0
    sta negative
    // [2881] phi atoi::res#2 = 0 [phi:atoi->atoi::@3#1] -- vwsm1=vwsc1 
    sta res
    sta res+1
    // [2881] phi atoi::i#4 = 0 [phi:atoi->atoi::@3#2] -- vbum1=vbuc1 
    sta i
    // atoi::@3
  __b3:
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [2882] if(atoi::str#2[atoi::i#4]<'0') goto atoi::@5 -- pbuz1_derefidx_vbum2_lt_vbuc1_then_la1 
    ldy i
    lda (str),y
    cmp #'0'
    bcc __b5
    // atoi::@6
    // [2883] if(atoi::str#2[atoi::i#4]<='9') goto atoi::@4 -- pbuz1_derefidx_vbum2_le_vbuc1_then_la1 
    lda (str),y
    cmp #'9'
    bcc __b4
    beq __b4
    // atoi::@5
  __b5:
    // if(negative)
    // [2884] if(0!=atoi::negative#2) goto atoi::@1 -- 0_neq_vbum1_then_la1 
    // Return result with sign
    lda negative
    bne __b1
    // [2886] phi from atoi::@1 atoi::@5 to atoi::@return [phi:atoi::@1/atoi::@5->atoi::@return]
    // [2886] phi atoi::return#2 = atoi::return#0 [phi:atoi::@1/atoi::@5->atoi::@return#0] -- register_copy 
    rts
    // atoi::@1
  __b1:
    // return -res;
    // [2885] atoi::return#0 = - atoi::res#2 -- vwsm1=_neg_vwsm1 
    lda #0
    sec
    sbc return
    sta return
    lda #0
    sbc return+1
    sta return+1
    // atoi::@return
    // }
    // [2887] return 
    rts
    // atoi::@4
  __b4:
    // res * 10
    // [2888] atoi::$10 = atoi::res#2 << 2 -- vwsz1=vwsm2_rol_2 
    lda res
    asl
    sta.z atoi__10
    lda res+1
    rol
    sta.z atoi__10+1
    asl.z atoi__10
    rol.z atoi__10+1
    // [2889] atoi::$11 = atoi::$10 + atoi::res#2 -- vwsz1=vwsz1_plus_vwsm2 
    clc
    lda.z atoi__11
    adc res
    sta.z atoi__11
    lda.z atoi__11+1
    adc res+1
    sta.z atoi__11+1
    // [2890] atoi::$6 = atoi::$11 << 1 -- vwsz1=vwsz1_rol_1 
    asl.z atoi__6
    rol.z atoi__6+1
    // res * 10 + str[i]
    // [2891] atoi::$7 = atoi::$6 + atoi::str#2[atoi::i#4] -- vwsz1=vwsz1_plus_pbuz2_derefidx_vbum3 
    ldy i
    lda.z atoi__7
    clc
    adc (str),y
    sta.z atoi__7
    bcc !+
    inc.z atoi__7+1
  !:
    // res = res * 10 + str[i] - '0'
    // [2892] atoi::res#1 = atoi::$7 - '0' -- vwsm1=vwsz2_minus_vbuc1 
    lda.z atoi__7
    sec
    sbc #'0'
    sta res
    lda.z atoi__7+1
    sbc #0
    sta res+1
    // for (; str[i]>='0' && str[i]<='9'; ++i)
    // [2893] atoi::i#2 = ++ atoi::i#4 -- vbum1=_inc_vbum1 
    inc i
    // [2881] phi from atoi::@4 to atoi::@3 [phi:atoi::@4->atoi::@3]
    // [2881] phi atoi::negative#2 = atoi::negative#2 [phi:atoi::@4->atoi::@3#0] -- register_copy 
    // [2881] phi atoi::res#2 = atoi::res#1 [phi:atoi::@4->atoi::@3#1] -- register_copy 
    // [2881] phi atoi::i#4 = atoi::i#2 [phi:atoi::@4->atoi::@3#2] -- register_copy 
    jmp __b3
  .segment Data
    .label res = return
    // Initialize sign as positive
    i: .byte 0
    return: .word 0
    // Initialize result
    negative: .byte 0
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
// __mem() unsigned int cx16_k_macptr(__mem() volatile char bytes, __zp($7c) void * volatile buffer)
cx16_k_macptr: {
    .label buffer = $7c
    // unsigned int bytes_read
    // [2894] cx16_k_macptr::bytes_read = 0 -- vwum1=vwuc1 
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
    // [2896] cx16_k_macptr::return#0 = cx16_k_macptr::bytes_read -- vwum1=vwum2 
    lda bytes_read
    sta return
    lda bytes_read+1
    sta return+1
    // cx16_k_macptr::@return
    // }
    // [2897] cx16_k_macptr::return#1 = cx16_k_macptr::return#0
    // [2898] return 
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
// __zp($29) char rom_byte_compare(__zp($56) char *ptr_rom, __zp($51) char value)
rom_byte_compare: {
    .label return = $29
    .label ptr_rom = $56
    .label value = $51
    // if (*ptr_rom != value)
    // [2899] if(*rom_byte_compare::ptr_rom#0==rom_byte_compare::value#0) goto rom_byte_compare::@1 -- _deref_pbuz1_eq_vbuz2_then_la1 
    lda.z value
    ldy #0
    cmp (ptr_rom),y
    beq __b2
    // [2900] phi from rom_byte_compare to rom_byte_compare::@2 [phi:rom_byte_compare->rom_byte_compare::@2]
    // rom_byte_compare::@2
    // [2901] phi from rom_byte_compare::@2 to rom_byte_compare::@1 [phi:rom_byte_compare::@2->rom_byte_compare::@1]
    // [2901] phi rom_byte_compare::return#0 = 0 [phi:rom_byte_compare::@2->rom_byte_compare::@1#0] -- vbuz1=vbuc1 
    tya
    sta.z return
    rts
    // [2901] phi from rom_byte_compare to rom_byte_compare::@1 [phi:rom_byte_compare->rom_byte_compare::@1]
  __b2:
    // [2901] phi rom_byte_compare::return#0 = 1 [phi:rom_byte_compare->rom_byte_compare::@1#0] -- vbuz1=vbuc1 
    lda #1
    sta.z return
    // rom_byte_compare::@1
    // rom_byte_compare::@return
    // }
    // [2902] return 
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
// __mem() unsigned long ultoa_append(__zp($41) char *buffer, __mem() unsigned long value, __mem() unsigned long sub)
ultoa_append: {
    .label buffer = $41
    // [2904] phi from ultoa_append to ultoa_append::@1 [phi:ultoa_append->ultoa_append::@1]
    // [2904] phi ultoa_append::digit#2 = 0 [phi:ultoa_append->ultoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [2904] phi ultoa_append::value#2 = ultoa_append::value#0 [phi:ultoa_append->ultoa_append::@1#1] -- register_copy 
    // ultoa_append::@1
  __b1:
    // while (value >= sub)
    // [2905] if(ultoa_append::value#2>=ultoa_append::sub#0) goto ultoa_append::@2 -- vdum1_ge_vdum2_then_la1 
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
    // [2906] *ultoa_append::buffer#0 = DIGITS[ultoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // ultoa_append::@return
    // }
    // [2907] return 
    rts
    // ultoa_append::@2
  __b2:
    // digit++;
    // [2908] ultoa_append::digit#1 = ++ ultoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [2909] ultoa_append::value#1 = ultoa_append::value#2 - ultoa_append::sub#0 -- vdum1=vdum1_minus_vdum2 
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
    // [2904] phi from ultoa_append::@2 to ultoa_append::@1 [phi:ultoa_append::@2->ultoa_append::@1]
    // [2904] phi ultoa_append::digit#2 = ultoa_append::digit#1 [phi:ultoa_append::@2->ultoa_append::@1#0] -- register_copy 
    // [2904] phi ultoa_append::value#2 = ultoa_append::value#1 [phi:ultoa_append::@2->ultoa_append::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label value = printf_ulong.uvalue
    .label sub = ultoa.digit_value
    .label return = printf_ulong.uvalue
    digit: .byte 0
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
// void rom_wait(__zp($2d) char *ptr_rom)
rom_wait: {
    .label rom_wait__0 = $2a
    .label rom_wait__1 = $29
    .label test1 = $2a
    .label test2 = $29
    .label ptr_rom = $2d
    // rom_wait::@1
  __b1:
    // test1 = *((brom_ptr_t)ptr_rom)
    // [2911] rom_wait::test1#1 = *rom_wait::ptr_rom#3 -- vbuz1=_deref_pbuz2 
    ldy #0
    lda (ptr_rom),y
    sta.z test1
    // test2 = *((brom_ptr_t)ptr_rom)
    // [2912] rom_wait::test2#1 = *rom_wait::ptr_rom#3 -- vbuz1=_deref_pbuz2 
    lda (ptr_rom),y
    sta.z test2
    // test1 & 0x40
    // [2913] rom_wait::$0 = rom_wait::test1#1 & $40 -- vbuz1=vbuz1_band_vbuc1 
    lda #$40
    and.z rom_wait__0
    sta.z rom_wait__0
    // test2 & 0x40
    // [2914] rom_wait::$1 = rom_wait::test2#1 & $40 -- vbuz1=vbuz1_band_vbuc1 
    lda #$40
    and.z rom_wait__1
    sta.z rom_wait__1
    // while ((test1 & 0x40) != (test2 & 0x40))
    // [2915] if(rom_wait::$0!=rom_wait::$1) goto rom_wait::@1 -- vbuz1_neq_vbuz2_then_la1 
    lda.z rom_wait__0
    cmp.z rom_wait__1
    bne __b1
    // rom_wait::@return
    // }
    // [2916] return 
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
// void rom_byte_program(__zp($49) unsigned long address, __zp($4d) char value)
rom_byte_program: {
    .label rom_ptr1_rom_byte_program__0 = $4e
    .label rom_ptr1_rom_byte_program__2 = $4e
    .label rom_ptr1_return = $4e
    .label address = $49
    .label value = $4d
    // rom_byte_program::rom_ptr1
    // (unsigned int)(address) & ROM_PTR_MASK
    // [2918] rom_byte_program::rom_ptr1_$2 = (unsigned int)rom_byte_program::address#0 -- vwuz1=_word_vduz2 
    lda.z address
    sta.z rom_ptr1_rom_byte_program__2
    lda.z address+1
    sta.z rom_ptr1_rom_byte_program__2+1
    // [2919] rom_byte_program::rom_ptr1_$0 = rom_byte_program::rom_ptr1_$2 & $3fff -- vwuz1=vwuz1_band_vwuc1 
    lda.z rom_ptr1_rom_byte_program__0
    and #<$3fff
    sta.z rom_ptr1_rom_byte_program__0
    lda.z rom_ptr1_rom_byte_program__0+1
    and #>$3fff
    sta.z rom_ptr1_rom_byte_program__0+1
    // ((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE
    // [2920] rom_byte_program::rom_ptr1_return#0 = rom_byte_program::rom_ptr1_$0 + $c000 -- vwuz1=vwuz1_plus_vwuc1 
    lda.z rom_ptr1_return
    clc
    adc #<$c000
    sta.z rom_ptr1_return
    lda.z rom_ptr1_return+1
    adc #>$c000
    sta.z rom_ptr1_return+1
    // rom_byte_program::@1
    // rom_write_byte(address, value)
    // [2921] rom_write_byte::address#3 = rom_byte_program::address#0
    // [2922] rom_write_byte::value#3 = rom_byte_program::value#0
    // [2923] call rom_write_byte
    // [2805] phi from rom_byte_program::@1 to rom_write_byte [phi:rom_byte_program::@1->rom_write_byte]
    // [2805] phi rom_write_byte::value#10 = rom_write_byte::value#3 [phi:rom_byte_program::@1->rom_write_byte#0] -- register_copy 
    // [2805] phi rom_write_byte::address#4 = rom_write_byte::address#3 [phi:rom_byte_program::@1->rom_write_byte#1] -- register_copy 
    jsr rom_write_byte
    // rom_byte_program::@2
    // rom_wait(ptr_rom)
    // [2924] rom_wait::ptr_rom#1 = (char *)rom_byte_program::rom_ptr1_return#0 -- pbuz1=pbuz2 
    lda.z rom_ptr1_return
    sta.z rom_wait.ptr_rom
    lda.z rom_ptr1_return+1
    sta.z rom_wait.ptr_rom+1
    // [2925] call rom_wait
    // [2910] phi from rom_byte_program::@2 to rom_wait [phi:rom_byte_program::@2->rom_wait]
    // [2910] phi rom_wait::ptr_rom#3 = rom_wait::ptr_rom#1 [phi:rom_byte_program::@2->rom_wait#0] -- register_copy 
    jsr rom_wait
    // rom_byte_program::@return
    // }
    // [2926] return 
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
// __mem() unsigned int utoa_append(__zp($41) char *buffer, __mem() unsigned int value, __mem() unsigned int sub)
utoa_append: {
    .label buffer = $41
    // [2928] phi from utoa_append to utoa_append::@1 [phi:utoa_append->utoa_append::@1]
    // [2928] phi utoa_append::digit#2 = 0 [phi:utoa_append->utoa_append::@1#0] -- vbum1=vbuc1 
    lda #0
    sta digit
    // [2928] phi utoa_append::value#2 = utoa_append::value#0 [phi:utoa_append->utoa_append::@1#1] -- register_copy 
    // utoa_append::@1
  __b1:
    // while (value >= sub)
    // [2929] if(utoa_append::value#2>=utoa_append::sub#0) goto utoa_append::@2 -- vwum1_ge_vwum2_then_la1 
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
    // [2930] *utoa_append::buffer#0 = DIGITS[utoa_append::digit#2] -- _deref_pbuz1=pbuc1_derefidx_vbum2 
    ldy digit
    lda DIGITS,y
    ldy #0
    sta (buffer),y
    // utoa_append::@return
    // }
    // [2931] return 
    rts
    // utoa_append::@2
  __b2:
    // digit++;
    // [2932] utoa_append::digit#1 = ++ utoa_append::digit#2 -- vbum1=_inc_vbum1 
    inc digit
    // value -= sub
    // [2933] utoa_append::value#1 = utoa_append::value#2 - utoa_append::sub#0 -- vwum1=vwum1_minus_vwum2 
    lda value
    sec
    sbc sub
    sta value
    lda value+1
    sbc sub+1
    sta value+1
    // [2928] phi from utoa_append::@2 to utoa_append::@1 [phi:utoa_append::@2->utoa_append::@1]
    // [2928] phi utoa_append::digit#2 = utoa_append::digit#1 [phi:utoa_append::@2->utoa_append::@1#0] -- register_copy 
    // [2928] phi utoa_append::value#2 = utoa_append::value#1 [phi:utoa_append::@2->utoa_append::@1#1] -- register_copy 
    jmp __b1
  .segment Data
    .label value = printf_uint.uvalue
    .label sub = utoa.digit_value
    .label return = printf_uint.uvalue
    digit: .byte 0
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
    .label memcpy8_vram_vram__0 = $23
    .label memcpy8_vram_vram__1 = $24
    .label memcpy8_vram_vram__2 = $25
    .label memcpy8_vram_vram__3 = $26
    .label memcpy8_vram_vram__4 = $27
    .label memcpy8_vram_vram__5 = $28
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2934] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(soffset_vram)
    // [2935] memcpy8_vram_vram::$0 = byte0  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte0_vwum2 
    lda soffset_vram
    sta.z memcpy8_vram_vram__0
    // *VERA_ADDRX_L = BYTE0(soffset_vram)
    // [2936] *VERA_ADDRX_L = memcpy8_vram_vram::$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(soffset_vram)
    // [2937] memcpy8_vram_vram::$1 = byte1  memcpy8_vram_vram::soffset_vram#0 -- vbuz1=_byte1_vwum2 
    lda soffset_vram+1
    sta.z memcpy8_vram_vram__1
    // *VERA_ADDRX_M = BYTE1(soffset_vram)
    // [2938] *VERA_ADDRX_M = memcpy8_vram_vram::$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // sbank_vram | VERA_INC_1
    // [2939] memcpy8_vram_vram::$2 = memcpy8_vram_vram::sbank_vram#0 | VERA_INC_1 -- vbuz1=vbum2_bor_vbuc1 
    lda #VERA_INC_1
    ora sbank_vram
    sta.z memcpy8_vram_vram__2
    // *VERA_ADDRX_H = sbank_vram | VERA_INC_1
    // [2940] *VERA_ADDRX_H = memcpy8_vram_vram::$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // *VERA_CTRL |= VERA_ADDRSEL
    // [2941] *VERA_CTRL = *VERA_CTRL | VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_bor_vbuc2 
    lda #VERA_ADDRSEL
    ora VERA_CTRL
    sta VERA_CTRL
    // BYTE0(doffset_vram)
    // [2942] memcpy8_vram_vram::$3 = byte0  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte0_vwum2 
    lda doffset_vram
    sta.z memcpy8_vram_vram__3
    // *VERA_ADDRX_L = BYTE0(doffset_vram)
    // [2943] *VERA_ADDRX_L = memcpy8_vram_vram::$3 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(doffset_vram)
    // [2944] memcpy8_vram_vram::$4 = byte1  memcpy8_vram_vram::doffset_vram#0 -- vbuz1=_byte1_vwum2 
    lda doffset_vram+1
    sta.z memcpy8_vram_vram__4
    // *VERA_ADDRX_M = BYTE1(doffset_vram)
    // [2945] *VERA_ADDRX_M = memcpy8_vram_vram::$4 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // dbank_vram | VERA_INC_1
    // [2946] memcpy8_vram_vram::$5 = memcpy8_vram_vram::dbank_vram#0 | VERA_INC_1 -- vbuz1=vbum2_bor_vbuc1 
    lda #VERA_INC_1
    ora dbank_vram
    sta.z memcpy8_vram_vram__5
    // *VERA_ADDRX_H = dbank_vram | VERA_INC_1
    // [2947] *VERA_ADDRX_H = memcpy8_vram_vram::$5 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // [2948] phi from memcpy8_vram_vram memcpy8_vram_vram::@2 to memcpy8_vram_vram::@1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1]
  __b1:
    // [2948] phi memcpy8_vram_vram::num8#2 = memcpy8_vram_vram::num8#1 [phi:memcpy8_vram_vram/memcpy8_vram_vram::@2->memcpy8_vram_vram::@1#0] -- register_copy 
  // the size is only a byte, this is the fastest loop!
    // memcpy8_vram_vram::@1
    // while (num8--)
    // [2949] memcpy8_vram_vram::num8#0 = -- memcpy8_vram_vram::num8#2 -- vbum1=_dec_vbum2 
    ldy num8_1
    dey
    sty num8
    // [2950] if(0!=memcpy8_vram_vram::num8#2) goto memcpy8_vram_vram::@2 -- 0_neq_vbum1_then_la1 
    lda num8_1
    bne __b2
    // memcpy8_vram_vram::@return
    // }
    // [2951] return 
    rts
    // memcpy8_vram_vram::@2
  __b2:
    // *VERA_DATA1 = *VERA_DATA0
    // [2952] *VERA_DATA1 = *VERA_DATA0 -- _deref_pbuc1=_deref_pbuc2 
    lda VERA_DATA0
    sta VERA_DATA1
    // [2953] memcpy8_vram_vram::num8#6 = memcpy8_vram_vram::num8#0 -- vbum1=vbum2 
    lda num8
    sta num8_1
    jmp __b1
  .segment Data
    num8: .byte 0
    dbank_vram: .byte 0
    doffset_vram: .word 0
    sbank_vram: .byte 0
    soffset_vram: .word 0
    num8_1: .byte 0
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
// __zp($e0) char display_frame_maskxy(__zp($fb) char x, __mem() char y)
display_frame_maskxy: {
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__0 = $29
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__1 = $dd
    .label cpeekcxy1_cpeekc1_display_frame_maskxy__2 = $ed
    .label c = $af
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
    .label return = $e0
    .label x = $fb
    .label y_1 = $f7
    // display_frame_maskxy::cpeekcxy1
    // gotoxy(x,y)
    // [2955] gotoxy::x#5 = display_frame_maskxy::cpeekcxy1_x#0 -- vbum1=vbum2 
    lda cpeekcxy1_x
    sta gotoxy.x
    // [2956] gotoxy::y#5 = display_frame_maskxy::cpeekcxy1_y#0 -- vbum1=vbum2 
    lda cpeekcxy1_y
    sta gotoxy.y
    // [2957] call gotoxy
    // [778] phi from display_frame_maskxy::cpeekcxy1 to gotoxy [phi:display_frame_maskxy::cpeekcxy1->gotoxy]
    // [778] phi gotoxy::y#33 = gotoxy::y#5 [phi:display_frame_maskxy::cpeekcxy1->gotoxy#0] -- register_copy 
    // [778] phi gotoxy::x#33 = gotoxy::x#5 [phi:display_frame_maskxy::cpeekcxy1->gotoxy#1] -- register_copy 
    jsr gotoxy
    // display_frame_maskxy::cpeekcxy1_cpeekc1
    // *VERA_CTRL &= ~VERA_ADDRSEL
    // [2958] *VERA_CTRL = *VERA_CTRL & ~VERA_ADDRSEL -- _deref_pbuc1=_deref_pbuc1_band_vbuc2 
    lda #VERA_ADDRSEL^$ff
    and VERA_CTRL
    sta VERA_CTRL
    // BYTE0(__conio.offset)
    // [2959] display_frame_maskxy::cpeekcxy1_cpeekc1_$0 = byte0  *((unsigned int *)&__conio+$13) -- vbuz1=_byte0__deref_pwuc1 
    lda __conio+$13
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__0
    // *VERA_ADDRX_L = BYTE0(__conio.offset)
    // [2960] *VERA_ADDRX_L = display_frame_maskxy::cpeekcxy1_cpeekc1_$0 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_L
    // BYTE1(__conio.offset)
    // [2961] display_frame_maskxy::cpeekcxy1_cpeekc1_$1 = byte1  *((unsigned int *)&__conio+$13) -- vbuz1=_byte1__deref_pwuc1 
    lda __conio+$13+1
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__1
    // *VERA_ADDRX_M = BYTE1(__conio.offset)
    // [2962] *VERA_ADDRX_M = display_frame_maskxy::cpeekcxy1_cpeekc1_$1 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_M
    // __conio.mapbase_bank | VERA_INC_0
    // [2963] display_frame_maskxy::cpeekcxy1_cpeekc1_$2 = *((char *)&__conio+5) -- vbuz1=_deref_pbuc1 
    lda __conio+5
    sta.z cpeekcxy1_cpeekc1_display_frame_maskxy__2
    // *VERA_ADDRX_H = __conio.mapbase_bank | VERA_INC_0
    // [2964] *VERA_ADDRX_H = display_frame_maskxy::cpeekcxy1_cpeekc1_$2 -- _deref_pbuc1=vbuz1 
    sta VERA_ADDRX_H
    // return *VERA_DATA0;
    // [2965] display_frame_maskxy::c#0 = *VERA_DATA0 -- vbuz1=_deref_pbuc1 
    lda VERA_DATA0
    sta.z c
    // display_frame_maskxy::@12
    // case 0x70: // DR corner.
    //             return 0b0110;
    // [2966] if(display_frame_maskxy::c#0==$70) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$70
    cmp.z c
    beq __b2
    // display_frame_maskxy::@1
    // case 0x6E: // DL corner.
    //             return 0b0011;
    // [2967] if(display_frame_maskxy::c#0==$6e) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6e
    cmp.z c
    beq __b1
    // display_frame_maskxy::@2
    // case 0x6D: // UR corner.
    //             return 0b1100;
    // [2968] if(display_frame_maskxy::c#0==$6d) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6d
    cmp.z c
    beq __b3
    // display_frame_maskxy::@3
    // case 0x7D: // UL corner.
    //             return 0b1001;
    // [2969] if(display_frame_maskxy::c#0==$7d) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$7d
    cmp.z c
    beq __b4
    // display_frame_maskxy::@4
    // case 0x40: // HL line.
    //             return 0b0101;
    // [2970] if(display_frame_maskxy::c#0==$40) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$40
    cmp.z c
    beq __b5
    // display_frame_maskxy::@5
    // case 0x5D: // VL line.
    //             return 0b1010;
    // [2971] if(display_frame_maskxy::c#0==$5d) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$5d
    cmp.z c
    beq __b6
    // display_frame_maskxy::@6
    // case 0x6B: // VR junction.
    //             return 0b1110;
    // [2972] if(display_frame_maskxy::c#0==$6b) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$6b
    cmp.z c
    beq __b7
    // display_frame_maskxy::@7
    // case 0x73: // VL junction.
    //             return 0b1011;
    // [2973] if(display_frame_maskxy::c#0==$73) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$73
    cmp.z c
    beq __b8
    // display_frame_maskxy::@8
    // case 0x72: // HD junction.
    //             return 0b0111;
    // [2974] if(display_frame_maskxy::c#0==$72) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$72
    cmp.z c
    beq __b9
    // display_frame_maskxy::@9
    // case 0x71: // HU junction.
    //             return 0b1101;
    // [2975] if(display_frame_maskxy::c#0==$71) goto display_frame_maskxy::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #$71
    cmp.z c
    beq __b10
    // display_frame_maskxy::@10
    // case 0x5B: // HV junction.
    //             return 0b1111;
    // [2976] if(display_frame_maskxy::c#0==$5b) goto display_frame_maskxy::@11 -- vbuz1_eq_vbuc1_then_la1 
    lda #$5b
    cmp.z c
    beq __b11
    // [2978] phi from display_frame_maskxy::@10 to display_frame_maskxy::@return [phi:display_frame_maskxy::@10->display_frame_maskxy::@return]
    // [2978] phi display_frame_maskxy::return#12 = 0 [phi:display_frame_maskxy::@10->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #0
    sta.z return
    rts
    // [2977] phi from display_frame_maskxy::@10 to display_frame_maskxy::@11 [phi:display_frame_maskxy::@10->display_frame_maskxy::@11]
    // display_frame_maskxy::@11
  __b11:
    // [2978] phi from display_frame_maskxy::@11 to display_frame_maskxy::@return [phi:display_frame_maskxy::@11->display_frame_maskxy::@return]
    // [2978] phi display_frame_maskxy::return#12 = $f [phi:display_frame_maskxy::@11->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$f
    sta.z return
    rts
    // [2978] phi from display_frame_maskxy::@1 to display_frame_maskxy::@return [phi:display_frame_maskxy::@1->display_frame_maskxy::@return]
  __b1:
    // [2978] phi display_frame_maskxy::return#12 = 3 [phi:display_frame_maskxy::@1->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #3
    sta.z return
    rts
    // [2978] phi from display_frame_maskxy::@12 to display_frame_maskxy::@return [phi:display_frame_maskxy::@12->display_frame_maskxy::@return]
  __b2:
    // [2978] phi display_frame_maskxy::return#12 = 6 [phi:display_frame_maskxy::@12->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #6
    sta.z return
    rts
    // [2978] phi from display_frame_maskxy::@2 to display_frame_maskxy::@return [phi:display_frame_maskxy::@2->display_frame_maskxy::@return]
  __b3:
    // [2978] phi display_frame_maskxy::return#12 = $c [phi:display_frame_maskxy::@2->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$c
    sta.z return
    rts
    // [2978] phi from display_frame_maskxy::@3 to display_frame_maskxy::@return [phi:display_frame_maskxy::@3->display_frame_maskxy::@return]
  __b4:
    // [2978] phi display_frame_maskxy::return#12 = 9 [phi:display_frame_maskxy::@3->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #9
    sta.z return
    rts
    // [2978] phi from display_frame_maskxy::@4 to display_frame_maskxy::@return [phi:display_frame_maskxy::@4->display_frame_maskxy::@return]
  __b5:
    // [2978] phi display_frame_maskxy::return#12 = 5 [phi:display_frame_maskxy::@4->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #5
    sta.z return
    rts
    // [2978] phi from display_frame_maskxy::@5 to display_frame_maskxy::@return [phi:display_frame_maskxy::@5->display_frame_maskxy::@return]
  __b6:
    // [2978] phi display_frame_maskxy::return#12 = $a [phi:display_frame_maskxy::@5->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$a
    sta.z return
    rts
    // [2978] phi from display_frame_maskxy::@6 to display_frame_maskxy::@return [phi:display_frame_maskxy::@6->display_frame_maskxy::@return]
  __b7:
    // [2978] phi display_frame_maskxy::return#12 = $e [phi:display_frame_maskxy::@6->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$e
    sta.z return
    rts
    // [2978] phi from display_frame_maskxy::@7 to display_frame_maskxy::@return [phi:display_frame_maskxy::@7->display_frame_maskxy::@return]
  __b8:
    // [2978] phi display_frame_maskxy::return#12 = $b [phi:display_frame_maskxy::@7->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$b
    sta.z return
    rts
    // [2978] phi from display_frame_maskxy::@8 to display_frame_maskxy::@return [phi:display_frame_maskxy::@8->display_frame_maskxy::@return]
  __b9:
    // [2978] phi display_frame_maskxy::return#12 = 7 [phi:display_frame_maskxy::@8->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #7
    sta.z return
    rts
    // [2978] phi from display_frame_maskxy::@9 to display_frame_maskxy::@return [phi:display_frame_maskxy::@9->display_frame_maskxy::@return]
  __b10:
    // [2978] phi display_frame_maskxy::return#12 = $d [phi:display_frame_maskxy::@9->display_frame_maskxy::@return#0] -- vbuz1=vbuc1 
    lda #$d
    sta.z return
    // display_frame_maskxy::@return
    // }
    // [2979] return 
    rts
  .segment Data
    cpeekcxy1_x: .byte 0
    cpeekcxy1_y: .byte 0
    .label y = main.main__52
    .label x_1 = main.check_status_smc9_main__0
    .label x_2 = main.check_status_smc8_main__0
}
.segment Code
  // display_frame_char
/**
 * @brief 
 * 
 * @param mask 
 * @return unsigned char 
 */
// __zp($dc) char display_frame_char(__zp($e0) char mask)
display_frame_char: {
    .label return = $dc
    .label mask = $e0
    // case 0b0110:
    //             return 0x70;
    // [2981] if(display_frame_char::mask#10==6) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    lda #6
    cmp.z mask
    beq __b1
    // display_frame_char::@1
    // case 0b0011:
    //             return 0x6E;
    // [2982] if(display_frame_char::mask#10==3) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // DR corner.
    lda #3
    cmp.z mask
    beq __b2
    // display_frame_char::@2
    // case 0b1100:
    //             return 0x6D;
    // [2983] if(display_frame_char::mask#10==$c) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // DL corner.
    lda #$c
    cmp.z mask
    beq __b3
    // display_frame_char::@3
    // case 0b1001:
    //             return 0x7D;
    // [2984] if(display_frame_char::mask#10==9) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // UR corner.
    lda #9
    cmp.z mask
    beq __b4
    // display_frame_char::@4
    // case 0b0101:
    //             return 0x40;
    // [2985] if(display_frame_char::mask#10==5) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // UL corner.
    lda #5
    cmp.z mask
    beq __b5
    // display_frame_char::@5
    // case 0b1010:
    //             return 0x5D;
    // [2986] if(display_frame_char::mask#10==$a) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // HL line.
    lda #$a
    cmp.z mask
    beq __b6
    // display_frame_char::@6
    // case 0b1110:
    //             return 0x6B;
    // [2987] if(display_frame_char::mask#10==$e) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VL line.
    lda #$e
    cmp.z mask
    beq __b7
    // display_frame_char::@7
    // case 0b1011:
    //             return 0x73;
    // [2988] if(display_frame_char::mask#10==$b) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VR junction.
    lda #$b
    cmp.z mask
    beq __b8
    // display_frame_char::@8
    // case 0b0111:
    //             return 0x72;
    // [2989] if(display_frame_char::mask#10==7) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // VL junction.
    lda #7
    cmp.z mask
    beq __b9
    // display_frame_char::@9
    // case 0b1101:
    //             return 0x71;
    // [2990] if(display_frame_char::mask#10==$d) goto display_frame_char::@return -- vbuz1_eq_vbuc1_then_la1 
    // HD junction.
    lda #$d
    cmp.z mask
    beq __b10
    // display_frame_char::@10
    // case 0b1111:
    //             return 0x5B;
    // [2991] if(display_frame_char::mask#10==$f) goto display_frame_char::@11 -- vbuz1_eq_vbuc1_then_la1 
    // HU junction.
    lda #$f
    cmp.z mask
    beq __b11
    // [2993] phi from display_frame_char::@10 to display_frame_char::@return [phi:display_frame_char::@10->display_frame_char::@return]
    // [2993] phi display_frame_char::return#12 = $20 [phi:display_frame_char::@10->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$20
    sta.z return
    rts
    // [2992] phi from display_frame_char::@10 to display_frame_char::@11 [phi:display_frame_char::@10->display_frame_char::@11]
    // display_frame_char::@11
  __b11:
    // [2993] phi from display_frame_char::@11 to display_frame_char::@return [phi:display_frame_char::@11->display_frame_char::@return]
    // [2993] phi display_frame_char::return#12 = $5b [phi:display_frame_char::@11->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$5b
    sta.z return
    rts
    // [2993] phi from display_frame_char to display_frame_char::@return [phi:display_frame_char->display_frame_char::@return]
  __b1:
    // [2993] phi display_frame_char::return#12 = $70 [phi:display_frame_char->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$70
    sta.z return
    rts
    // [2993] phi from display_frame_char::@1 to display_frame_char::@return [phi:display_frame_char::@1->display_frame_char::@return]
  __b2:
    // [2993] phi display_frame_char::return#12 = $6e [phi:display_frame_char::@1->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6e
    sta.z return
    rts
    // [2993] phi from display_frame_char::@2 to display_frame_char::@return [phi:display_frame_char::@2->display_frame_char::@return]
  __b3:
    // [2993] phi display_frame_char::return#12 = $6d [phi:display_frame_char::@2->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6d
    sta.z return
    rts
    // [2993] phi from display_frame_char::@3 to display_frame_char::@return [phi:display_frame_char::@3->display_frame_char::@return]
  __b4:
    // [2993] phi display_frame_char::return#12 = $7d [phi:display_frame_char::@3->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$7d
    sta.z return
    rts
    // [2993] phi from display_frame_char::@4 to display_frame_char::@return [phi:display_frame_char::@4->display_frame_char::@return]
  __b5:
    // [2993] phi display_frame_char::return#12 = $40 [phi:display_frame_char::@4->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$40
    sta.z return
    rts
    // [2993] phi from display_frame_char::@5 to display_frame_char::@return [phi:display_frame_char::@5->display_frame_char::@return]
  __b6:
    // [2993] phi display_frame_char::return#12 = $5d [phi:display_frame_char::@5->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$5d
    sta.z return
    rts
    // [2993] phi from display_frame_char::@6 to display_frame_char::@return [phi:display_frame_char::@6->display_frame_char::@return]
  __b7:
    // [2993] phi display_frame_char::return#12 = $6b [phi:display_frame_char::@6->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$6b
    sta.z return
    rts
    // [2993] phi from display_frame_char::@7 to display_frame_char::@return [phi:display_frame_char::@7->display_frame_char::@return]
  __b8:
    // [2993] phi display_frame_char::return#12 = $73 [phi:display_frame_char::@7->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$73
    sta.z return
    rts
    // [2993] phi from display_frame_char::@8 to display_frame_char::@return [phi:display_frame_char::@8->display_frame_char::@return]
  __b9:
    // [2993] phi display_frame_char::return#12 = $72 [phi:display_frame_char::@8->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$72
    sta.z return
    rts
    // [2993] phi from display_frame_char::@9 to display_frame_char::@return [phi:display_frame_char::@9->display_frame_char::@return]
  __b10:
    // [2993] phi display_frame_char::return#12 = $71 [phi:display_frame_char::@9->display_frame_char::@return#0] -- vbuz1=vbuc1 
    lda #$71
    sta.z return
    // display_frame_char::@return
    // }
    // [2994] return 
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
  info_text: .fill $100, 0
  status_text: .word __3, __4, __5, smc_action_text_1, smc_action_text, __8, __9, __10, __11, __12, __13, __14
  status_color: .byte BLACK, GREY, WHITE, CYAN, PURPLE, CYAN, PURPLE, PURPLE, GREEN, YELLOW, RED, PINK
  status_rom: .byte 0
  .fill 7, 0
.segment DataIntro
  display_into_briefing_text: .word __15, __16, info_text8, __18, __19, __20, __21, __22, __23, info_text8, __25, __26, info_text8, __28, __29
  display_into_colors_text: .word __30, __31, info_text8, __33, __34, __35, __36, __37, __38, __39, __40, __41, __42, __43, info_text8, __45
.segment Data
  display_no_valid_smc_bootloader_text: .word __46, info_text8, __48, __49, info_text8, __51, __52, __53, __54
  display_smc_rom_issue_text: .word __55, info_text8, __65, __58, info_text8, __60, __61, __62
  display_smc_unsupported_rom_text: .word __63, info_text8, __65, __66, info_text8, __68, __69
  display_debriefing_text_smc: .word __84, info_text8, main.text, info_text8, __74, __75, __76, info_text8, __78, info_text8, __80, __81, __82, __83
  display_debriefing_text_rom: .word __84, info_text8, info_text8, info_text8, __88, __89
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
  __46: .text "The SMC chip in your CX16 doesn't have a valid bootloader."
  .byte 0
  __48: .text "A valid bootloader is needed to update the SMC chip."
  .byte 0
  __49: .text "Unfortunately, your SMC chip cannot be updated using this tool!"
  .byte 0
  __51: .text "A bootloader can be installed onto the SMC chip using an"
  .byte 0
  __52: .text "an Arduino or an AVR ISP device."
  .byte 0
  __53: .text "Alternatively a new SMC chip with a valid bootloader can be"
  .byte 0
  __54: .text "ordered from TexElec."
  .byte 0
  __55: .text "There is an issue with the CX16 SMC or ROM flash readiness."
  .byte 0
  __58: .text "to avoid possible conflicts of firmware, bricking your CX16."
  .byte 0
  __60: .text "Therefore, ensure you have the correct SMC.BIN and ROM.BIN"
  .byte 0
  __61: .text "files placed on your SDcard. Also ensure that the"
  .byte 0
  __62: .text "J1 jumper pins on the CX16 board are closed."
  .byte 0
  __63: .text "There is an issue with the CX16 SMC or ROM flash versions."
  .byte 0
  __65: .text "Both the SMC and the main ROM must be updated together,"
  .byte 0
  __66: .text "to avoid possible conflicts, risking bricking your CX16."
  .byte 0
  __68: .text "The SMC.BIN and ROM.BIN found on your SDCard may not be"
  .byte 0
  __69: .text "mutually compatible. Update the CX16 at your own risk!"
  .byte 0
  __74: .text "Because your SMC chipset has been updated,"
  .byte 0
  __75: .text "the restart process differs, depending on the"
  .byte 0
  __76: .text "SMC boootloader version installed on your CX16 board:"
  .byte 0
  __78: .text "- SMC bootloader v2.0: your CX16 will automatically shut down."
  .byte 0
  __80: .text "- SMC bootloader v1.0: you need to "
  .byte 0
  __81: .text "  COMPLETELY DISCONNECT your CX16 from the power source!"
  .byte 0
  __82: .text "  The power-off button won't work!"
  .byte 0
  __83: .text "  Then, reconnect and start the CX16 normally."
  .byte 0
  __84: .text "Your CX16 system has been successfully updated!"
  .byte 0
  __88: .text "Since your CX16 system SMC chip has not been updated"
  .byte 0
  __89: .text "your CX16 will just reset automatically after count down."
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
  smc_action_text: .text "Reading"
  .byte 0
  smc_action_text_1: .text "Checking"
  .byte 0
  info_text8: .text ""
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
  // Globals (to save zeropage and code overhead with parameter passing.)
  smc_bootloader: .word 0
  smc_release: .byte 0
  smc_major: .byte 0
  smc_minor: .byte 0
  smc_file_size: .word 0
  smc_file_release: .byte 0
  smc_file_major: .byte 0
  smc_file_minor: .byte 0
  smc_file_size_1: .word 0
  // Globals (to save zeropage and code overhead with parameter passing.)
  smc_bootloader_1: .word 0
  // Globals
  status_smc: .byte 0
  status_vera: .byte 0
