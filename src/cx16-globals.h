/**
 * @file cx16-globals.h
 * @author your name (you@domain.com)
 * @brief 
 * @version 0.1
 * @date 2023-10-05
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

unsigned char rom_device_ids[8] = {0};
unsigned char* rom_device_names[8] = {0};
unsigned char* rom_size_strings[8] = {0};
unsigned char rom_github[8][8];
unsigned char rom_release[8];
unsigned char rom_manufacturer_ids[8] = {0};
unsigned long rom_sizes[8] = {0};
unsigned long file_sizes[8] = {0};

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

__mem unsigned char* status_text[11] = {
    "None", "Skip", "Detected", "Checking", "Reading", "Comparing", 
    "Update", "Updating", "Updated", "Issue", "Error"};

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

__mem unsigned char status_color[11] = {
    STATUS_COLOR_NONE, STATUS_COLOR_SKIP, STATUS_COLOR_DETECTED, STATUS_COLOR_CHECKING, STATUS_COLOR_READING, STATUS_COLOR_COMPARING, 
    STATUS_COLOR_FLASH, STATUS_COLOR_FLASHING, STATUS_COLOR_FLASHED, STATUS_COLOR_ISSUE, STATUS_COLOR_ERROR};


const unsigned int PROGRESS_CELL = 0x200;
const unsigned int PROGRESS_ROW = 0x8000; 


__mem unsigned int smc_bootloader = 0;
__mem unsigned int smc_file_size = 0;

