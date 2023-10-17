/**
 * @file cx16-defines.h
 * 
 * @author Wavicle from CX16 community (https://gist.github.com/jburks) -- Main ROM update logic & overall support and test assistance.
 * @author MooingLemur from CX16 community (https://github.com/mooinglemur) -- Main SPI and VERA update logic, VERA firmware.
 * @author Stefan Jakobsson from CX16 community (https://github.com/stefan-b-jakobsson) -- Main SMC update logic, SMC firmware and bootloader.
 * @author Sven Van de Velde from CX16 community (https://github.com/FlightControl-User) -- Creation of this program, under the strong expertise by the people above.
 * 
 * @brief COMMANDER X16 GLOBAL DEFINES AND CONDITIONAL COMPILE
 *
 * @version 3.0
 * @date 2023-10-15
 *
 * @copyright Copyright (c) 2023
 *
 */

#define __DEBUG  {asm{.byte $db}};
// #define __DEBUG_FILE

#define __STDIO_FILECOUNT 2

// Some addressing constants.
#define RAM_BASE                ((unsigned int)0x7800)
#define RAM_HIGH                ((unsigned int)0x9800)
#define BRAM_LOW                ((unsigned int)0xA000)
#define BRAM_HIGH               ((unsigned int)0xC000)

// These pre-processor directives allow to disable specific ROM flashing functions (for emulator development purposes).
// Normally they should be all activated.
#define __COLS_40
#define __COLS_80

#define __INTRO

// #define __VERA_CHIP_PROCESS
#define __SMC_CHIP_PROCESS
#define __ROM_CHIP_PROCESS


#define __VERA_JP1_DETECT
// #define __VERA_FLASH
#define __SMC_FLASH
#define __ROM_FLASH

#define __VERA_CHIP_DETECT
#define __SMC_CHIP_DETECT
#define __ROM_CHIP_DETECT

#define __VERA_CHIP_CHECK
#define __SMC_CHIP_CHECK
#define __ROM_CHIP_CHECK

#define __VERA_CHIP_FLASH
#define __SMC_CHIP_FLASH
#define __ROM_CHIP_FLASH

#define __FLASH_ERROR_DETECT

#define CHIP_640_Y ((unsigned char)34)

// To print the graphics on the vera.
#define VERA_CHR_SPACE 0x20
#define VERA_CHR_UL 0x7E
#define VERA_CHR_UR 0x7C
#define VERA_CHR_BL 0x7B
#define VERA_CHR_BR 0x6C
#define VERA_CHR_HL 0x62
#define VERA_CHR_VL 0x61

#define VERA_REV_SPACE 0xA0
#define VERA_REV_UL 0xFE
#define VERA_REV_UR 0xFC
#define VERA_REV_BL 0xFB
#define VERA_REV_BR 0xEC
#define VERA_REV_HL 0xE2
#define VERA_REV_VL 0xE1

#define CHIP_SMC_X 1
#define CHIP_SMC_Y 3
#define CHIP_SMC_W 5
#define CHIP_VERA_X 9
#define CHIP_VERA_Y 3
#define CHIP_VERA_W 8
#define CHIP_ROM_X 20
#define CHIP_ROM_Y 3
#define CHIP_ROM_W 3

const char PROGRESS_X = 2;
const char PROGRESS_Y = 32;
const char PROGRESS_W = 64;
const char PROGRESS_H = 16;

#define INFO_X 4
#define INFO_Y 17
#define INFO_W 64
#define INFO_H 10
