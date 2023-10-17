/**
 * @file cx16-display.h
 * 
 * @author Wavicle from CX16 community (https://gist.github.com/jburks) -- Advice and outline of the ROM update logic & overall support and test assistance of this program.
 * @author MooingLemur from CX16 community (https://github.com/mooinglemur) -- Advice and outline of the main SPI and W25Q16 update logic, and supply of new VERA firmware.
 * @author Stefan Jakobsson from CX16 community (https://github.com/stefan-b-jakobsson) -- Advice and outline of the SMC update logic, SMC firmware and bootloader and creation of SMC firmware.
 * @author Sven Van de Velde from CX16 community (https://github.com/FlightControl-User) -- Creation of this program, under the strong expertise by the people above.
 * 
 * @brief COMMANDER X16 UPDATE TOOL DISPLAY FUNCTIONS
 *
 * @version 3.0
 * @date 2023-10-15
 *
 * @copyright Copyright (c) 2023
 *
 */


#include "cx16-defines.h"
#include "cx16-globals.h"

unsigned char display_frame_maskxy(unsigned char x, unsigned char y);
unsigned char display_frame_char(unsigned char mask);
void display_frame(unsigned char x0, unsigned char y0, unsigned char x1, unsigned char y1);
void display_frame_draw();
void display_frame_init_64();

void display_frame_title(unsigned char* title_text);
void display_chip_line(char x, char y, char w, char c);
void display_chip_end(char x, char y, char w);
void display_chip_led(char x, char y, char w, char tc, char bc);
void display_info_led(char x, char y, char tc, char bc);
void display_print_chip(unsigned char x, unsigned char y, unsigned char w, unsigned char* text);
void display_smc_led(unsigned char c);
void display_chip_smc();
void display_vera_led(unsigned char c);
void display_chip_vera();
void display_rom_led(unsigned char chip, unsigned char c);
void display_chip_rom();
void print_i2c_address(bram_bank_t bram_bank, bram_ptr_t bram_ptr, unsigned int i2c_address);
void display_progress_clear();
void display_progress_line(unsigned char line, unsigned char* text);
void display_progress_text(unsigned char** text, unsigned char lines);
void display_action_progress(unsigned char* info_text);
void display_action_text(unsigned char* info_text);
inline void display_info_title();

void display_info_smc(unsigned char info_status, unsigned char* info_text);
void display_info_vera(unsigned char info_status, unsigned char* info_text);
void display_info_rom(unsigned char rom_chip, unsigned char info_status, unsigned char* info_text);
void display_info_cx16_rom(unsigned char info_status, unsigned char* info_text);

void display_action_text_flashing(unsigned long bytes, unsigned char* chip, bram_bank_t bram_bank, bram_ptr_t bram_ptr, unsigned long address);
void display_action_text_flashed(unsigned long bytes, unsigned char* chip);
void display_action_text_reading(unsigned char* action, unsigned char* file, unsigned long bytes, unsigned long size, bram_bank_t bram_bank, bram_ptr_t bram_ptr);
