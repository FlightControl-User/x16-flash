/**
 * @file cx16-display.c
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
#include "cx16-display-text.h"

/**
 * @brief 
 * 
 * @param x 
 * @param y 
 * @return unsigned char 
 */
unsigned char display_frame_maskxy(unsigned char x, unsigned char y) {
    unsigned char c = cpeekcxy(x, y);
    switch(c) {
        case 0x70: // DR corner.
            return 0b0110;
        case 0x6E: // DL corner.
            return 0b0011;
        case 0x6D: // UR corner.
            return 0b1100;
        case 0x7D: // UL corner.
            return 0b1001;
        case 0x40: // HL line.
            return 0b0101;
        case 0x5D: // VL line.
            return 0b1010;
        case 0x6B: // VR junction.
            return 0b1110;
        case 0x73: // VL junction.
            return 0b1011;
        case 0x72: // HD junction.
            return 0b0111;
        case 0x71: // HU junction.
            return 0b1101;
        case 0x5B: // HV junction.
            return 0b1111;
        default:
            return 0b0000;
    }
}

/**
 * @brief 
 * 
 * @param mask 
 * @return unsigned char 
 */
unsigned char display_frame_char(unsigned char mask) {
    switch(mask) {
        case 0b0110:
            return 0x70; // DR corner.
        case 0b0011:
            return 0x6E; // DL corner.
        case 0b1100:
            return 0x6D; // UR corner.
        case 0b1001:
            return 0x7D; // UL corner.
        case 0b0101:
            return 0x40; // HL line.
        case 0b1010:
            return 0x5D; // VL line.
        case 0b1110:
            return 0x6B; // VR junction.
        case 0b1011:
            return 0x73; // VL junction.
        case 0b0111:
            return 0x72; // HD junction.
        case 0b1101:
            return 0x71; // HU junction.
        case 0b1111:
            return 0x5B; // HV junction.
        default:
            return 0x20; // Space.
    }
}

// Draw a line horizontal from a given xy position and a given length.
// The line should calculate the matching characters to draw and glue them.
// So it first needs to peek the characters at the given position.
// And then calculate the resulting characters to draw.
/**
 * @brief 
 * 
 * @param x0 
 * @param y0 
 * @param x1 
 * @param y1 
 */
void display_frame(unsigned char x0, unsigned char y0, unsigned char x1, unsigned char y1) {
    unsigned char w = x1 - x0;
    unsigned char h = y1 - y0;
    unsigned char x = x0, y = y0;
    unsigned char mask = display_frame_maskxy(x, y);
    mask |= 0b0110; // Add a corner.
    unsigned char c = display_frame_char(mask);
    cputcxy(x, y, c);
    if(w>=2) {
        x++;
        while(x < x1) {
            mask = display_frame_maskxy(x, y);
            mask |= 0b0101; // Add a full line.
            c = display_frame_char(mask);
            cputcxy(x, y, c);
            x++;
        }
    }
    mask = display_frame_maskxy(x, y);
    mask |= 0b0011; // Add a corner.
    c = display_frame_char(mask);
    cputcxy(x, y, c);

    if(h>=2) {
        y++;
        while(y < y1) {
            mask = display_frame_maskxy(x0, y);
            mask |= 0b1010; // Add a full line.
            c = display_frame_char(mask);
            cputcxy(x0, y, c);
            mask = display_frame_maskxy(x1, y);
            mask |= 0b1010; // Add a full line.
            c = display_frame_char(mask);
            cputcxy(x1, y, c);
            y++;
        }
        x = x0;
        mask = display_frame_maskxy(x, y);
        mask |= 0b1100; // Add a corner.
        c = display_frame_char(mask);
        cputcxy(x, y, c);
        if(w>=2) {
            x++;
            while(x < x1) {
                mask = display_frame_maskxy(x, y);
                mask |= 0b0101; // Add a full line.
                c = display_frame_char(mask);
                cputcxy(x, y, c);
                x++;
            }
        }
        mask = display_frame_maskxy(x, y);
        mask |= 0b1001; // Add a corner.
        c = display_frame_char(mask);
        cputcxy(x, y, c);
    }
}

/**
 * @brief 
 * 
 */
void display_frame_draw() {
    textcolor(LIGHT_BLUE);
    bgcolor(BLUE);

    clrscr();
    display_frame(0, 0, 67, 14);
    display_frame(0, 0, 67, 2);
    display_frame(0, 2, 67, 14);

    // Chipset areas
    display_frame(0, 2, 8, 14);
    display_frame(8, 2, 19, 14);
    display_frame(19, 2, 25, 14);
    display_frame(25, 2, 31, 14);
    display_frame(31, 2, 37, 14);
    display_frame(37, 2, 43, 14);
    display_frame(43, 2, 49, 14);
    display_frame(49, 2, 55, 14);
    display_frame(55, 2, 61, 14);
    display_frame(61, 2, 67, 14);

    // Progress area
    display_frame(0, 14, 67, PROGRESS_Y-5);
    display_frame(0, PROGRESS_Y-5, 67, PROGRESS_Y-2);
    display_frame(0, PROGRESS_Y-2, 67, 49);

    textcolor(WHITE);
}

/**
 * @brief 
 * 
 */
void display_frame_init() {
    // Set the charset to lower case.
    // screenlayer1();
    textcolor(WHITE);
    bgcolor(BLUE);
    scroll(0);
    clrscr();
    vera_display_set_hstart(11);
    vera_display_set_hstop(147);
    vera_display_set_vstart(19);
    vera_display_set_vstop(219);
    cx16_k_screen_set_charset(3, (char *)0);
}

void display_print_title(unsigned char* title_text) {
    gotoxy(2, 1);
    printf("%-65s", title_text);
}

void display_print_chip_line(char x, char y, char w, char c) {

    gotoxy(x, y);

    textcolor(GREY);
    bgcolor(BLUE);
    cputc(VERA_CHR_UR);

    textcolor(WHITE);
    bgcolor(BLACK);
    for(char i=0; i<w; i++) {
        cputc(VERA_CHR_SPACE);
    }

    textcolor(GREY);
    bgcolor(BLUE);
    cputc(VERA_CHR_UL);

    textcolor(WHITE);
    bgcolor(BLACK);
    cputcxy(x+2, y, c);
}

void display_print_chip_end(char x, char y, char w) {

    gotoxy(x, y);

    textcolor(GREY);
    bgcolor(BLUE);
    cputc(VERA_CHR_UR);

    textcolor(BLUE);
    bgcolor(BLACK);
    for(char i=0; i<w; i++) {
        cputc(VERA_CHR_HL);
    }

    textcolor(GREY);
    bgcolor(BLUE);
    cputc(VERA_CHR_UL);
}

void display_print_chip_led(char x, char y, char w, char tc, char bc) {

    textcolor(tc);
    bgcolor(bc);

    do {
        cputcxy(x, y, 0x6F);
        cputcxy(x, y+1, 0x77);
        x++;
    } while(--w);

    textcolor(WHITE);
    bgcolor(BLUE);
}

void display_print_info_led(char x, char y, char tc, char bc) {
    textcolor(tc); bgcolor(bc);
    cputcxy(x, y, VERA_CHR_UR);
    textcolor(WHITE);
}

void display_print_chip(unsigned char x, unsigned char y, unsigned char w, unsigned char* text) {
    display_print_chip_line(x, y++, w, *text++);
    display_print_chip_line(x, y++, w, *text++);
    display_print_chip_line(x, y++, w, *text++);
    display_print_chip_line(x, y++, w, *text++);
    display_print_chip_line(x, y++, w, *text++);
    display_print_chip_line(x, y++, w, *text++);
    display_print_chip_line(x, y++, w, *text++);
    display_print_chip_line(x, y++, w, *text++);
    display_print_chip_end(x, y++, w);
}

void display_print_smc_led(unsigned char c) {
    display_print_chip_led(CHIP_SMC_X+1, CHIP_SMC_Y, CHIP_SMC_W, c, BLUE);
    display_print_info_led(INFO_X-2, INFO_Y, c, BLUE);
}

void display_chip_smc() {
    display_print_smc_led(GREY);
    display_print_chip(CHIP_SMC_X, CHIP_SMC_Y+2, CHIP_SMC_W, "SMC     ");
}

void display_print_vera_led(unsigned char c) {
    display_print_chip_led(CHIP_VERA_X+1, CHIP_VERA_Y, CHIP_VERA_W, c, BLUE);
    display_print_info_led(INFO_X-2, INFO_Y+1, c, BLUE);
}

void display_chip_vera() {
    display_print_vera_led(GREY);
    display_print_chip(CHIP_VERA_X, CHIP_VERA_Y+2, CHIP_VERA_W, "VERA     ");
}

void display_print_rom_led(unsigned char chip, unsigned char c) {
    display_print_chip_led(CHIP_ROM_X+chip*6+1, CHIP_ROM_Y, CHIP_ROM_W, c, BLUE);
    display_print_info_led(INFO_X-2, INFO_Y+chip+2, c, BLUE);
}

void display_chip_rom() {

    char rom[16];
    for (unsigned char r = 0; r < 8; r++) {
        strcpy(rom, "ROM  ");
        strcat(rom, rom_size_strings[r]);
        if(r) {
            *(rom+3) = r+'0';
        }
        display_print_rom_led(r, GREY);
        display_print_chip(CHIP_ROM_X+r*6, CHIP_ROM_Y+2, CHIP_ROM_W, rom);
    }
}

void print_chip_KB(unsigned char rom_chip, unsigned char* kb) {
    display_print_chip_line(3 + rom_chip * 10, 51, 3, kb[0]);
    display_print_chip_line(3 + rom_chip * 10, 52, 3, kb[1]);
    display_print_chip_line(3 + rom_chip * 10, 53, 3, kb[2]);
}

void print_i2c_address(bram_bank_t bram_bank, bram_ptr_t bram_ptr, unsigned int i2c_address) {

    textcolor(WHITE);
    gotoxy(43, 1);
    printf("ram = %2x/%4p, i2c = %4x", bram_bank, bram_ptr, i2c_address);
}

/**
 * @brief Clean the progress area for the flashing.
 */
void display_progress_clear() {

    textcolor(WHITE);
    bgcolor(BLUE);

    unsigned char h = PROGRESS_Y + PROGRESS_H;
    unsigned char y = PROGRESS_Y;
    unsigned char w = PROGRESS_W;
    while (y < h) {
        unsigned char x = PROGRESS_X;
        for(unsigned char i = 0; i < w; i++) {
            cputcxy(x, y, ' ');
            x++;
        }
        y++;
    }
}

void display_progress_line(unsigned char line, unsigned char* text) {
    cputsxy(PROGRESS_X, PROGRESS_Y+line, text);
}

void display_progress_text(unsigned char** text, unsigned char lines) {
    for(unsigned char l=0; l<lines; l++) {
        display_progress_line(l, text[l]);
    }
}

void display_info_progress(unsigned char* info_text) {
    unsigned char x = wherex();
    unsigned char y = wherey();
    gotoxy(2, PROGRESS_Y-4);
    printf("%-65s", info_text);
    gotoxy(x, y);
}

void display_info_line(unsigned char* info_text) {
    unsigned char x = wherex();
    unsigned char y = wherey();
    gotoxy(2, PROGRESS_Y-3);
    printf("%-65s", info_text);
    gotoxy(x, y);
}


void display_print_info_title() {
    cputsxy(INFO_X-2, INFO_Y-2, "# Chip Status    Type   File  / Total Information");
    cputsxy(INFO_X-2, INFO_Y-1, "- ---- --------- ------ ----- / ----- --------------------");
}

/**
 * @brief Print the SMC status.
 * 
 * @param status The STATUS_ 
 * 
 * @remark The smc_booloader is a global variable. 
 */
void display_info_smc(unsigned char info_status, unsigned char* info_text) {
    unsigned char x = wherex(); unsigned char y = wherey();
    status_smc = info_status;
    display_print_smc_led(status_color[info_status]);
    gotoxy(INFO_X, INFO_Y);
    printf("SMC  %-9s ATTiny %05x / 01E00 ", status_text[info_status], smc_file_size);
    if(info_text) {
        printf("%-20s", info_text);
    }
    gotoxy(x, y);
}

/**
 * @brief Print the VERA status.
 * 
 * @param info_status The STATUS_ 
 */
void display_info_vera(unsigned char info_status, unsigned char* info_text) {
    unsigned char x = wherex(); unsigned char y = wherey();
    status_vera = info_status;
    display_print_vera_led(status_color[info_status]);
    gotoxy(INFO_X, INFO_Y+1);
    printf("VERA %-9s FPGA   1a000 / 1a000 ", status_text[info_status]);
    if(info_text) {
        printf("%-20s", info_text);
    }
    gotoxy(x, y);
}

/**
 * @brief 
 * 
 * @param rom_chip 
 * @param info_status 
 * @param info_text 
 */
void display_info_rom(unsigned char rom_chip, unsigned char info_status, unsigned char* info_text) {
    unsigned char x = wherex(); unsigned char y = wherey();
    status_rom[rom_chip] = info_status;
    display_print_rom_led(rom_chip, status_color[info_status]);
    gotoxy(INFO_X, INFO_Y+rom_chip+2);
    printf("ROM%u %-9s %-6s %05x / %05x ", rom_chip, status_text[info_status], rom_device_names[rom_chip], file_sizes[rom_chip], rom_sizes[rom_chip]);
    if(info_text) {
        printf("%-20s", info_text);
    }
    gotoxy(x,y);
}

/**
 * @brief 
 * 
 * @param info_status 
 * @param info_text 
 */
void display_info_cx16_rom(unsigned char info_status, unsigned char* info_text) {
    display_info_rom(0, info_status, info_text);
}
