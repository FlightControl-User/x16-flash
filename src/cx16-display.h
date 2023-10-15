/**
 * @file cx16-display.h
 * @author your name (you@domain.com)
 * @brief 
 * @version 0.1
 * @date 2023-10-05
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
