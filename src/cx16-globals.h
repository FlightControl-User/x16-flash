/**
 * @file cx16-globals.h
 * 
 * @author Wavicle from CX16 community (https://gist.github.com/jburks) -- Advice and outline of the ROM update logic & overall support and test assistance of this program.
 * @author MooingLemur from CX16 community (https://github.com/mooinglemur) -- Advice and outline of the main SPI and W25Q16 update logic, and supply of new VERA firmware.
 * @author Stefan Jakobsson from CX16 community (https://github.com/stefan-b-jakobsson) -- Advice and outline of the SMC update logic, SMC firmware and bootloader and creation of SMC firmware.
 * @author Sven Van de Velde from CX16 community (https://github.com/FlightControl-User) -- Creation of this program, under the strong expertise by the people above.
 * 
 * @brief COMMANDER X16 UPDATE TOOL GLOBAL DEFINES AND VARIABLES
 *
 * @version 3.0
 * @date 2023-10-15
 *
 * @copyright Copyright (c) 2023
 *
 */

#include <6502.h>
#include <cx16.h>
#include <cx16-conio.h>
#include <kernal.h>
#include <printf.h>
#include <sprintf.h>
#include <stdio.h>
#include "cx16-vera.h"
#include "cx16-veralib.h"


cx16_k_screen_mode_t screen_mode;

char file[32];
char info_text[80];


const char STATUS_NONE  = 0;
const char STATUS_SKIP  = 1;
const char STATUS_DETECTED  = 2;
const char STATUS_CHECKING  = 3;
const char STATUS_READING  = 4;
const char STATUS_COMPARING  = 5;
const char STATUS_FLASH  = 6;
const char STATUS_FLASHING  = 7;
const char STATUS_FLASHED  = 8;
const char STATUS_ISSUE  = 9;
const char STATUS_ERROR  = 10;
const char STATUS_WAITING  = 11;

__mem unsigned char* status_text[12] = {
    "None", "Skip", "Detected", "Checking", "Reading", "Comparing", 
    "Update", "Updating", "Updated", "Issue", "Error", "Waiting"};

const unsigned char STATUS_COLOR_NONE           = BLACK;
const unsigned char STATUS_COLOR_SKIP           = GREY;
const unsigned char STATUS_COLOR_DETECTED       = WHITE;
const unsigned char STATUS_COLOR_CHECKING       = CYAN;
const unsigned char STATUS_COLOR_READING        = PURPLE;
const unsigned char STATUS_COLOR_COMPARING      = CYAN;
const unsigned char STATUS_COLOR_FLASH          = PURPLE;
const unsigned char STATUS_COLOR_FLASHING       = PURPLE;
const unsigned char STATUS_COLOR_FLASHED        = GREEN;
const unsigned char STATUS_COLOR_ISSUE          = YELLOW;
const unsigned char STATUS_COLOR_ERROR          = RED;
const unsigned char STATUS_COLOR_WAITING        = PINK;

__mem unsigned char status_color[12] = {
    STATUS_COLOR_NONE, STATUS_COLOR_SKIP, STATUS_COLOR_DETECTED, STATUS_COLOR_CHECKING, STATUS_COLOR_READING, STATUS_COLOR_COMPARING, 
    STATUS_COLOR_FLASH, STATUS_COLOR_FLASHING, STATUS_COLOR_FLASHED, STATUS_COLOR_ISSUE, STATUS_COLOR_ERROR, STATUS_COLOR_WAITING};


const unsigned int ROM_PROGRESS_CELL = 0x200;  // A progress frame cell represents about 512 bytes for a ROM update.
const unsigned int ROM_PROGRESS_ROW = 0x8000;  // A progress frame row represents about 32768 bytes for a ROM update.

const unsigned char SMC_PROGRESS_CELL = 0x8;  // A progress frame cell represents about 8 bytes for a SMC update.
const unsigned int SMC_PROGRESS_ROW = 0x200;  // A progress frame row represents about 512 bytes for a SMC update.

const unsigned char VERA_PROGRESS_CELL = 0x80;  // A progress frame cell represents about 128 bytes for a VERA compare.
const unsigned int VERA_PROGRESS_PAGE = 0x100;  // A progress frame cell represents about 256 bytes for a VERA flash.
const unsigned int VERA_PROGRESS_ROW = 0x2000;  // A progress frame row represents about 8192 bytes for a VERA update.


