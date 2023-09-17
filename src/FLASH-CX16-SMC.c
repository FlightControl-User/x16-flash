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

#define __DEBUG  {asm{.byte $db}};
// #define __DEBUG_FILE

#define __STDIO_FILECOUNT 8

// These pre-processor directives allow to disable specific ROM flashing functions (for emulator development purposes).
// Normally they should be all activated.
#define __FLASH
#define __SMC_CHIP_PROCESS
#define __ROM_CHIP_PROCESS
// #define __ROM_CHIP_DETECT
// #define __SMC_CHIP_DETECT
#define __SMC_CHIP_CHECK
#define __ROM_CHIP_CHECK
#define __SMC_CHIP_FLASH
#define __ROM_CHIP_FLASH
#define __FLASH_ERROR_DETECT

// #define __DEBUG_FILE

#define FLASH_I2C_SMC_OFFSET 0x8E
#define FLASH_I2C_SMC_BOOTLOADER_RESET 0x8F
#define FLASH_I2C_SMC_UPLOAD 0x80
#define FLASH_I2C_SMC_COMMIT 0x81
#define FLASH_I2C_SMC_REBOOT 0x82
#define FLASH_I2C_SMC_DEVICE 0x42

// Ensures the proper character set is used for the COMMANDER X16.
#pragma encoding(screencode_mixed)

// Uses all parameters to be passed using zero pages (fast).
#pragma var_model(zp)


// Main includes.
#include <6502.h>
#include <cx16.h>
#include <cx16-conio.h>
#include <kernal.h>
#include <printf.h>
#include <sprintf.h>
#include <stdio.h>
#include "cx16-vera.h"
#include "cx16-veralib.h"

// Some addressing constants.
#define RAM_BASE                ((unsigned int)0x6000)
#define RAM_HIGH                ((unsigned int)0x8000)
#define BRAM_LOW                ((unsigned int)0xA000)
#define BRAM_HIGH               ((unsigned int)0xC000)
#define ROM_BASE                ((unsigned int)0xC000)
#define ROM_SIZE                ((unsigned int)0x4000)
#define ROM_PTR_MASK            ((unsigned int)0x003FFF)
#define ROM_BANK_MASK           ((unsigned long)0x3FC000)
#define ROM_CHIP_MASK           ((unsigned long)0x380000)
#define ROM_SECTOR              ((unsigned int)0x1000)

// The different device IDs that can be returned from the manufacturer ID read sequence.
#define SST39SF010A ((unsigned char)0xB5)
#define SST39SF020A ((unsigned char)0xB6)
#define SST39SF040 ((unsigned char)0xB7)
#define UNKNOWN ((unsigned char)0x55)

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

#define PROGRESS_X 2
#define PROGRESS_Y 31
#define PROGRESS_W 64
#define PROGRESS_H 16

#define INFO_X 2
#define INFO_Y 17
#define INFO_W 64
#define INFO_H 10

char file[32];
char info_text[80];

unsigned char rom_device_ids[8] = {0};
unsigned char* rom_device_names[8] = {0};
unsigned char* rom_size_strings[8] = {0};
unsigned char rom_manufacturer_ids[8] = {0};
unsigned long rom_sizes[8] = {0};
unsigned long file_sizes[8] = {0};

__mem unsigned int smc_bootloader;

#define STATUS_DETECTED     0
#define STATUS_NONE         1
#define STATUS_CHECKING     2
#define STATUS_CHECKED      3
#define STATUS_EQUATING     4
#define STATUS_EQUATED      5
#define STATUS_FLASHING     6
#define STATUS_UPDATED      7
#define STATUS_ERROR        8

__mem unsigned char* status_text[9] = {
    "Detected", "None", "Checking", "Checked", 
    "Equating", "Equated", "Flashing", "Flashed", "Error"};

#define STATUS_COLOR_DETECTED     WHITE
#define STATUS_COLOR_NONE         BLACK
#define STATUS_COLOR_CHECKING     CYAN
#define STATUS_COLOR_CHECKED      CYAN
#define STATUS_COLOR_EQUATING     CYAN
#define STATUS_COLOR_EQUATED      CYAN
#define STATUS_COLOR_FLASHING     YELLOW
#define STATUS_COLOR_FLASHED      GREEN
#define STATUS_COLOR_ERROR        RED

__mem unsigned char status_color[9] = {
    STATUS_COLOR_DETECTED, STATUS_COLOR_NONE, STATUS_COLOR_CHECKING, STATUS_COLOR_CHECKED, 
    STATUS_COLOR_EQUATING, STATUS_COLOR_EQUATED, STATUS_COLOR_FLASHING, STATUS_COLOR_FLASHED, 
    STATUS_COLOR_ERROR};


const unsigned int PROGRESS_CELL = 0x200;
const unsigned int PROGRESS_ROW = 0x8000; 

unsigned char wait_key(unsigned char* info_text, unsigned char* filter) {

    info_line(info_text);

    unsigned ch = 0;

    unsigned char bram = bank_get_bram();
    unsigned char brom = bank_get_brom();
    bank_set_bram(0);
    bank_set_brom(0);

    while (true) {
        ch = kbhit();
        // if there is a filter, check the filter, otherwise return ch.
        if (filter) {
            // Check if ch is part of the filter.
            if(strchr(filter, ch) != NULL) {
                break;
            }
        } else {
            if(ch)
                break;
        }
    }

    bank_set_bram(bram);
    bank_set_brom(brom);

    return ch;
}

void system_reset() {

    bank_set_bram(0);
    bank_set_brom(0);

    asm {
        jmp ($FFFC)
    }
}

unsigned char frame_maskxy(unsigned char x, unsigned char y) {
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

unsigned char frame_char(unsigned char mask) {
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
void frame(unsigned char x0, unsigned char y0, unsigned char x1, unsigned char y1) {
    unsigned char w = x1 - x0;
    unsigned char h = y1 - y0;
    unsigned char x = x0, y = y0;
    unsigned char mask = frame_maskxy(x, y);
    mask |= 0b0110; // Add a corner.
    unsigned char c = frame_char(mask);
    cputcxy(x, y, c);
    if(w>=2) {
        x++;
        while(x < x1) {
            mask = frame_maskxy(x, y);
            mask |= 0b0101; // Add a full line.
            c = frame_char(mask);
            cputcxy(x, y, c);
            x++;
        }
    }
    mask = frame_maskxy(x, y);
    mask |= 0b0011; // Add a corner.
    c = frame_char(mask);
    cputcxy(x, y, c);

    if(h>=2) {
        y++;
        while(y < y1) {
            mask = frame_maskxy(x0, y);
            mask |= 0b1010; // Add a full line.
            c = frame_char(mask);
            cputcxy(x0, y, c);
            mask = frame_maskxy(x1, y);
            mask |= 0b1010; // Add a full line.
            c = frame_char(mask);
            cputcxy(x1, y, c);
            y++;
        }
        x = x0;
        mask = frame_maskxy(x, y);
        mask |= 0b1100; // Add a corner.
        c = frame_char(mask);
        cputcxy(x, y, c);
        if(w>=2) {
            x++;
            while(x < x1) {
                mask = frame_maskxy(x, y);
                mask |= 0b0101; // Add a full line.
                c = frame_char(mask);
                cputcxy(x, y, c);
                x++;
            }
        }
        mask = frame_maskxy(x, y);
        mask |= 0b1001; // Add a corner.
        c = frame_char(mask);
        cputcxy(x, y, c);
    }
}

void frame_draw() {
    textcolor(WHITE);
    bgcolor(BLUE);

    clrscr();
    frame(0, 0, 67, 15);
    frame(0, 0, 67, 2);
    frame(0, 2, 67, 13);
    frame(0, 13, 67, 15);
    frame(0, 2, 8, 13);
    frame(8, 2, 19, 13);
    frame(19, 2, 25, 13);
    frame(25, 2, 31, 13);
    frame(31, 2, 37, 13);
    frame(37, 2, 43, 13);
    frame(43, 2, 49, 13);
    frame(49, 2, 55, 13);
    frame(55, 2, 61, 13);
    frame(61, 2, 67, 13);
    frame(0, 13, 67, 29);
    frame(0, 29, 67, 49);

    // cputsxy(2, 3, "led colors");
    // cputsxy(2, 5, "    no chip"); print_chip_led(2, 5, DARK_GREY, BLUE);
    // cputsxy(2, 6, "    update"); print_chip_led(2, 6, CYAN, BLUE);
    // cputsxy(2, 7, "    ok"); print_chip_led(2, 7, WHITE, BLUE);
    // cputsxy(2, 8, "    todo"); print_chip_led(2, 8, PURPLE, BLUE);
    // cputsxy(2, 9, "    error"); print_chip_led(2, 9, RED, BLUE);
    // cputsxy(2, 10, "    no file"); print_chip_led(2, 10, GREY, BLUE);

    cputsxy(2, 14, "status");
}

void frame_init() {
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


void print_chip_line(char x, char y, char w, char c) {

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

void print_chip_end(char x, char y, char w) {

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

void print_chip_led(char x, char y, char w, char tc, char bc) {

    gotoxy(x, y);

    textcolor(tc);
    bgcolor(bc);
    for(char i=0; i<w; i++) {
        cputc(0xE2);
    }

    textcolor(WHITE);
    bgcolor(BLUE);
}

void print_chip(unsigned char x, unsigned char y, unsigned char w, unsigned char* text) {

    print_chip_line(x, y++, w, *text++);
    print_chip_line(x, y++, w, *text++);
    print_chip_line(x, y++, w, *text++);
    print_chip_line(x, y++, w, *text++);
    print_chip_line(x, y++, w, *text++);
    print_chip_line(x, y++, w, *text++);
    print_chip_line(x, y++, w, *text++);
    print_chip_line(x, y++, w, *text++);
    print_chip_end(x, y++, w);
}

void print_smc_led(unsigned char c) {
    print_chip_led(CHIP_SMC_X+1, CHIP_SMC_Y, CHIP_SMC_W, c, BLUE);
}

void chip_smc() {
    print_smc_led(GREY);
    print_chip(CHIP_SMC_X, CHIP_SMC_Y+1, CHIP_SMC_W, "smc     ");
}

void print_vera_led(unsigned char c) {
    print_chip_led(CHIP_VERA_X+1, CHIP_VERA_Y, CHIP_VERA_W, c, BLUE);
}

void chip_vera() {
    print_vera_led(GREY);
    print_chip(CHIP_VERA_X, CHIP_VERA_Y+1, CHIP_VERA_W, "vera     ");
}

void print_rom_led(unsigned char chip, unsigned char c) {
    print_chip_led(CHIP_ROM_X+chip*6+1, CHIP_ROM_Y, CHIP_ROM_W, c, BLUE);
}

void chip_rom() {

    char rom[16];
    for (unsigned char r = 0; r < 8; r++) {
        strcpy(rom, "rom0 ");
        strcat(rom, rom_size_strings[r]);

        *(rom+3) = r+'0';
        print_rom_led(r, GREY);
        print_chip(CHIP_ROM_X+r*6, CHIP_ROM_Y+1, CHIP_ROM_W, rom);
    }
}

void print_chip_KB(unsigned char rom_chip, unsigned char* kb) {
    print_chip_line(3 + rom_chip * 10, 51, 3, kb[0]);
    print_chip_line(3 + rom_chip * 10, 52, 3, kb[1]);
    print_chip_line(3 + rom_chip * 10, 53, 3, kb[2]);
}

void print_i2c_address(bram_bank_t bram_bank, bram_ptr_t bram_ptr, unsigned int i2c_address) {

    textcolor(WHITE);
    gotoxy(43, 1);
    printf("ram = %2x/%4p, i2c = %4x", bram_bank, bram_ptr, i2c_address);
}


/**
 * @brief Clean the progress area for the flashing.
 */
void progress_clear() {

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

void info_line(unsigned char* info_text) {
    unsigned char x = wherex();
    unsigned char y = wherey();
    gotoxy(2, 14);
    printf("%-60s", info_text);
    gotoxy(x, y);
}

void info_title(unsigned char* info_text) {
    gotoxy(2, 1);
    printf("%-60s", info_text);
}

void info_clear(char l) {
    unsigned char h = INFO_Y + INFO_H;
    unsigned char y = INFO_Y+l;
    unsigned char w = INFO_W;
    unsigned char x = PROGRESS_X;
    for(unsigned char i = 0; i < w; i++) {
        cputcxy(x, y, ' ');
        x++;
    }

    gotoxy(PROGRESS_X, y);
}

/**
 * @brief Clean the information area.
 * 
 */
void info_clear_all() {

    textcolor(WHITE);
    bgcolor(BLUE);

    unsigned char l = 0;
    while (l < INFO_H) {
        info_clear(l);
        l++;
    }
}



/**
 * @brief Print the SMC status.
 * 
 * @param status The STATUS_ 
 * 
 * @remark The smc_booloader is a global variable. 
 */
void info_smc(unsigned char info_status, unsigned char* info_text) {
    print_smc_led(status_color[info_status]);
    info_clear(0); printf("SMC  - %-8s - %s", status_text[info_status], info_text);
}

/**
 * @brief Print the VERA status.
 * 
 * @param info_status The STATUS_ 
 */
void info_vera(unsigned char info_status, unsigned char* info_text) {
    print_vera_led(status_color[info_status]);
    info_clear(1); printf("VERA - %-8s - %s", status_text[info_status], info_text);
}

void info_rom(unsigned char rom_chip, unsigned char info_status, unsigned char* info_text) {
    print_rom_led(rom_chip, status_color[info_status]);
    info_clear(2+rom_chip); printf("ROM%u - %-8s - %-5s - %-3s - %s", rom_chip, status_text[info_status], rom_device_names[rom_chip], rom_size_strings[rom_chip], info_text );
}

/**
 * @brief Calcuates the 16 bit ROM pointer from the ROM using the 22 bit address.
 * The 16 bit ROM pointer is calculated by masking the lower 14 bits (bit 13-0), and then adding $C000 to it.
 * The 16 bit ROM pointer is returned as a char* (brom_ptr_t).
 * @param address The 22 bit ROM address.
 * @return brom_ptr_t The 16 bit ROM pointer for the main CPU addressing.
 */
inline brom_ptr_t rom_ptr(unsigned long address) { 
    return (brom_ptr_t)(((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE); 
}


/**
 * @brief Calculates the 8 bit ROM bank from the 22 bit ROM address.
 * The ROM bank number is calcuated by taking the upper 8 bits (bit 18-14) and shifing those 14 bits to the right.
 *
 * @param address The 22 bit ROM address.
 * @return unsigned char The ROM bank number for usage in ZP $01.
 */
inline unsigned char rom_bank(unsigned long address) { 

    // address = address & ROM_BANK_MASK; // not needed.s

    unsigned int bank_unshifted = MAKEWORD(BYTE2(address),BYTE1(address)) << 2;
    unsigned char bank = BYTE1(bank_unshifted); 
    return bank; 
    
}


/**
 * @brief Read a byte from the ROM using the 22 bit address.
 * The lower 14 bits of the 22 bit ROM address are transformed into the **ptr_rom** 16 bit ROM address.
 * The higher 8 bits of the 22 bit ROM address are transformed into the **bank_rom** 8 bit bank number.
 * **bank_ptr* is used to set the bank using ZP $01.  **ptr_rom** is used to read the byte.
 *
 * @param address The 22 bit ROM address.
 * @return unsigned char The byte read from the ROM.
 */
unsigned char rom_read_byte(unsigned long address) {
    brom_bank_t bank_rom = rom_bank((unsigned long)address);
    brom_ptr_t ptr_rom = rom_ptr((unsigned long)address);

    bank_set_brom(bank_rom);
    return *ptr_rom;
}


/**
 * @brief Write a byte to the ROM using the 22 bit address.
 * The lower 14 bits of the 22 bit ROM address are transformed into the **ptr_rom** 16 bit ROM address.
 * The higher 8 bits of the 22 bit ROM address are transformed into the **bank_rom** 8 bit bank number.
 * **bank_ptr* is used to set the bank using ZP $01.  **ptr_rom** is used to write the byte into the ROM.
 *
 * @param address The 22 bit ROM address.
 * @param value The byte value to be written.
 */
void rom_write_byte(unsigned long address, unsigned char value) {
    brom_bank_t bank_rom = rom_bank((unsigned long)address);
    brom_ptr_t ptr_rom = rom_ptr((unsigned long)address);

    bank_set_brom(bank_rom);
    *ptr_rom = value;
}

/**
 * @brief Verify a byte with the flashed ROM using the 22 bit rom address.
 * The lower 14 bits of the 22 bit ROM address are transformed into the **ptr_rom** 16 bit ROM address.
 * The higher 8 bits of the 22 bit ROM address are transformed into the **bank_rom** 8 bit bank number.
 * **bank_ptr* is used to set the bank using ZP $01.  **ptr_rom** is used to write the byte into the ROM.
 *
 * @param address The 22 bit ROM address.
 * @param value The byte value to be written.
 */
unsigned char rom_byte_compare(brom_ptr_t ptr_rom, unsigned char value) {

    unsigned char equal = 1;
    if (*ptr_rom != value) {
        equal = 0;
    }
    return equal;
}

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
/* inline */ void rom_wait(brom_ptr_t ptr_rom) {
    unsigned char test1;
    unsigned char test2;

    do {
        test1 = *((brom_ptr_t)ptr_rom);
        test2 = *((brom_ptr_t)ptr_rom);
    } while ((test1 & 0x40) != (test2 & 0x40));
}


/**
 * @brief Unlock a byte location for flashing using the 22 bit address.
 * This is a various purpose routine to unlock the ROM for flashing a byte.
 * The 3rd byte can be variable, depending on the write sequence used, so this byte is a parameter into the routine.
 *
 * @param address The 3rd write to model the specific unlock sequence.
 * @param unlock_code The 3rd write to model the specific unlock sequence.
 */
/* inline */ void rom_unlock(unsigned long address, unsigned char unlock_code) {
    unsigned long chip_address = address & ROM_CHIP_MASK; // This is a very important operation...
    rom_write_byte(chip_address + 0x05555, 0xAA);
    rom_write_byte(chip_address + 0x02AAA, 0x55);
    rom_write_byte(address, unlock_code);
}

unsigned int smc_read(unsigned char x, unsigned char y, unsigned char w, unsigned char b, unsigned int progress_row_size, ram_ptr_t flash_ram_address) {

    unsigned int smc_file_size = 0; /// Holds the amount of bytes actually read in the memory to be flashed.
    unsigned int progress_row_bytes = 0;

    info_line("Reading SMC.BIN flash file into CX16 RAM ...");

    textcolor(WHITE);
    gotoxy(x, y);

    unsigned int smc_file_read = 0;

    unsigned int smc_bytes_total = 0;
    FILE *fp = fopen("SMC.BIN", "r");
    if (fp) {

        // We read b bytes at a time, and each b bytes we plot a dot.
        // Every r bytes we move to the next line.
        while (smc_file_read = fgets(flash_ram_address, b, fp)) {

            if (progress_row_bytes == progress_row_size) {
                gotoxy(x, ++y);
                progress_row_bytes = 0;
            }

            cputc('+');

            flash_ram_address += smc_file_read;
            smc_file_size += smc_file_read;
            progress_row_bytes += smc_file_read;
        }

        fclose(fp);
    }

    // We return the amount of bytes read.
    return smc_file_size;
}

unsigned int flash_smc(unsigned char x, unsigned char y, unsigned char w, unsigned int smc_bytes_total, unsigned char b, unsigned int smc_row_total, ram_ptr_t smc_ram_ptr) {

    unsigned int flash_address = 0;
    unsigned int smc_row_bytes = 0;
    unsigned long flash_bytes = 0;



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

    unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31);
    if(smc_bootloader_start) {
        sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start);
        info_line(info_text);
        // Reboot the SMC.
        cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0);
        return 0;
    }

    unsigned char smc_bootloader_activation_countdown = 20;
    unsigned int smc_bootloader_not_activated = 0xFF;
    while(smc_bootloader_activation_countdown) {
        unsigned int smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET);
        if(smc_bootloader_not_activated) {
            for(unsigned long x=65536*6; x>0; x--);
            sprintf(info_text, "Press POWER and RESET on the CX16 within %u seconds!", smc_bootloader_activation_countdown);
            info_line(info_text);
        } else {
            break;
        }
        smc_bootloader_activation_countdown--;
    }

    // Wait an other 5 seconds to ensure the bootloader is activated.
    smc_bootloader_activation_countdown = 5;
    while(smc_bootloader_activation_countdown) {
        for(unsigned long x=65536*1; x>0; x--);
        sprintf(info_text, "Waiting an other %u seconds before flashing the SMC!", smc_bootloader_activation_countdown);
        info_line(info_text);
        smc_bootloader_activation_countdown--;
    }

    smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET);
    if(smc_bootloader_not_activated) {
        sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated);
        info_line(info_text);
        return 0;
    }


    textcolor(WHITE);
    gotoxy(x, y);

    unsigned int smc_bytes_flashed = 0;
    unsigned int smc_attempts_total = 0;

    while(smc_bytes_flashed < smc_bytes_total) {
        unsigned char smc_attempts_flashed = 0;
        unsigned char smc_package_committed = 0;
        while(!smc_package_committed && smc_attempts_flashed < 10) {
            unsigned char smc_bytes_checksum = 0;
            unsigned int smc_package_flashed = 0;
            while(smc_package_flashed < 8) {
                unsigned char smc_byte_upload = *smc_ram_ptr;
                smc_ram_ptr++;
                smc_bytes_checksum += smc_byte_upload;
                // Upload byte
                unsigned char smc_upload_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, smc_byte_upload);
                smc_package_flashed++;
            }
            // 8 bytes have been uploaded, now send the checksum byte, in 1 complement.
            unsigned char smc_checksum_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, (smc_bytes_checksum ^ 0xFF)+1);

            // Now send the commit command.
            unsigned int smc_commit_result = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_COMMIT);
            if(smc_commit_result == 1) {
                if (smc_row_bytes == smc_row_total) {
                    gotoxy(x, ++y);
                    smc_row_bytes = 0;
                }

                cputc('*');

                smc_bytes_flashed += 8;
                smc_row_bytes += 8;
                smc_attempts_total += smc_attempts_flashed;

                sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total);
                info_line(info_text);

                smc_package_committed = 1;
            } else {
                smc_ram_ptr -= 8;
                smc_attempts_flashed++; // We retry uploading the package ...
            }
        }
        if(smc_attempts_flashed >= 10) {
            sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed);
            info_line(info_text);
            return 0;
        }
    }

    // Reboot the SMC.
    cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0);
    

    return smc_bytes_flashed;
}

unsigned int smc_detect() {

    unsigned int smc_bootloader_version = 0;

// This conditional compilation ensures that only the detection interpretation happens if it is switched on.
#ifdef __SMC_CHIP_DETECT
    smc_bootloader_version = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET);
    if(!BYTE1(smc_bootloader_version)) {
        if(smc_bootloader_version == 0xFF) { // When the bootloader is not present, 0xFF is returned.
            smc_bootloader_version = 0x0100;
        }
    } else {
        smc_bootloader_version = 0x0200;
    }
#else
    smc_bootloader_version = 0x01;
#endif

    return smc_bootloader_version;
}

unsigned int smc_flash(ram_ptr_t flash_ram_address, unsigned char b) {
    unsigned char smc_checksum = 0;
    for(unsigned char i = 0; i<b; i++) {
        unsigned char smc_write = *flash_ram_address;
        unsigned int smc_byte = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, 0x80, smc_write);
        if(smc_byte < 256) {
            smc_checksum += BYTE0(smc_byte);
        } else {
            return 0xFFFF;
        }
        flash_ram_address++;
    }
    return smc_checksum;
}

void rom_detect() {

    unsigned char rom_chip = 0;

    // Ensure the ROM is set to BASIC.
    // bank_set_brom(4);


    for (unsigned long rom_detect_address = 0; rom_detect_address < 8 * 0x80000; rom_detect_address += 0x80000) {

        rom_manufacturer_ids[rom_chip] = 0;
        rom_device_ids[rom_chip] = 0;

#ifdef __ROM_CHIP_DETECT
        rom_unlock(rom_detect_address + 0x05555, 0x90);
        rom_manufacturer_ids[rom_chip] = rom_read_byte(rom_detect_address);
        rom_device_ids[rom_chip] = rom_read_byte(rom_detect_address + 1);
        rom_unlock(rom_detect_address + 0x05555, 0xF0);
#else
        // Simulate that there is one chip onboard and 2 chips on the isa card.
        if (rom_detect_address == 0x0) {
            rom_manufacturer_ids[rom_chip] = 0x9f;
            rom_device_ids[rom_chip] = SST39SF040;
        }
        if (rom_detect_address == 0x80000) {
            rom_manufacturer_ids[rom_chip] = 0x9f;
            rom_device_ids[rom_chip] = SST39SF040;
        }
        if (rom_detect_address == 0x100000) {
            rom_manufacturer_ids[rom_chip] = 0x9f;
            rom_device_ids[rom_chip] = SST39SF020A;
        }
        if (rom_detect_address == 0x180000) {
            rom_manufacturer_ids[rom_chip] = 0x9f;
            rom_device_ids[rom_chip] = SST39SF010A;
        }
        if (rom_detect_address == 0x200000) {
            rom_manufacturer_ids[rom_chip] = 0x9f;
            rom_device_ids[rom_chip] = SST39SF040;
        }
        if (rom_detect_address == 0x280000) {
            rom_manufacturer_ids[rom_chip] = 0x9f;
            rom_device_ids[rom_chip] = SST39SF040;
        }
#endif

        // Ensure the ROM is set to BASIC.
        bank_set_brom(4);

        switch (rom_device_ids[rom_chip]) {
        case SST39SF010A:
            rom_device_names[rom_chip] = "f010a";
            rom_size_strings[rom_chip] = "128";
            rom_sizes[rom_chip] = 128 * 1024;
            break;
        case SST39SF020A:
            rom_device_names[rom_chip] = "f020a";
            rom_size_strings[rom_chip] = "256";
            rom_sizes[rom_chip] = 256 * 1024;
            break;
        case SST39SF040:
            rom_device_names[rom_chip] = "f040";
            rom_size_strings[rom_chip] = "512";
            rom_sizes[rom_chip] = 512 * 1024;
            break;
        default:
            rom_manufacturer_ids[rom_chip] = 0;
            rom_device_names[rom_chip] = "----";
            rom_size_strings[rom_chip] = "000";
            rom_sizes[rom_chip] = 0;
            rom_device_ids[rom_chip] = UNKNOWN;
            break;
        }

        gotoxy(rom_chip*3+40, 1);
        printf("%02x", rom_device_ids[rom_chip]);

        rom_chip++;
    }

}

/**
 * @brief Calculates the 22 bit ROM size from the 8 bit ROM banks.
 * The ROM size is calcuated by taking the 8 bits and shifing those 14 bits to the left (bit 21-14).
 *
 * @param rom_bank The 8 bit ROM banks.
 * @return unsigned long The resulting 22 bit ROM address.
 */
unsigned long rom_size(unsigned char rom_banks) { return ((unsigned long)(rom_banks)) << 14; }

/**
 * @brief Calculates the 22 bit ROM address from the 8 bit ROM bank.
 * The ROM bank number is calcuated by taking the 8 bits and shifing those 14 bits to the left (bit 21-14).
 *
 * @param rom_bank The 8 bit ROM address.
 * @return unsigned long The 22 bit ROM address.
 */
/* inline */ unsigned long rom_address_from_bank(unsigned char rom_bank) { return ((unsigned long)(rom_bank)) << 14; }


unsigned long rom_read(
        unsigned char rom_bank_start, unsigned long rom_size) {

    unsigned char x = PROGRESS_X;
    unsigned char y = PROGRESS_Y;
    unsigned char w = PROGRESS_W;

    gotoxy(x, y);

    unsigned char bram_bank = 0;
    ram_ptr_t ram_address = (ram_ptr_t)RAM_BASE;

    unsigned long rom_address = rom_address_from_bank(rom_bank_start);
    unsigned long rom_file_read = 0; /// Holds the amount of bytes actually read in the memory to be flashed.

    unsigned int rom_row_current = 0;

    FILE *fp = fopen(file, "r");
    if (fp) {
        while (rom_file_read < rom_size) {

            sprintf(info_text, "Reading %s ROM %05x of %05x in RAM %02x:%04p ...", fp->filename, rom_file_read, rom_size, bram_bank, ram_address);
            info_line(info_text);

            if (!(rom_address % 0x04000)) {
                rom_bank_start++;
            }

            // __DEBUG

            bank_set_bram(bram_bank);


            unsigned int rom_package_read = fgets(ram_address, PROGRESS_CELL, fp); // this will load b bytes from the rom.bin file or less if EOF is reached.
            if (!rom_package_read) {
                break;
            }

            if (rom_row_current == PROGRESS_ROW) {
                gotoxy(x, ++y);
                rom_row_current = 0;
            }

            cputc('.');

            ram_address += rom_package_read;
            rom_address += rom_package_read;
            rom_file_read += rom_package_read;
            rom_row_current += rom_package_read;

            if (ram_address == (ram_ptr_t)BRAM_HIGH) {
                ram_address = (ram_ptr_t)BRAM_LOW;
                bram_bank++;
            }

            if (ram_address == (ram_ptr_t)RAM_HIGH) {
                ram_address = (ram_ptr_t)BRAM_LOW;
                bram_bank = 1; // This is required to continue the reading into bram from bank 1.
            }
        }
        fclose(fp);
    }

    return rom_file_read;
}

unsigned int rom_compare(bram_bank_t bank_ram, ram_ptr_t ptr_ram, unsigned long rom_compare_address, unsigned int rom_compare_size) {

    unsigned int compared_bytes = 0; /// Holds the amount of bytes actually verified between the ROM and the RAM.
    unsigned int difference_bytes = 0; /// Holds the amount of correct and verified bytes flashed in the ROM.

    bank_set_bram(bank_ram);

    brom_bank_t bank_rom = rom_bank((unsigned long)rom_compare_address);
    brom_ptr_t ptr_rom = rom_ptr((unsigned long)rom_compare_address);

    bank_set_brom(bank_rom);

    while (compared_bytes < rom_compare_size) {

        if (!rom_byte_compare(ptr_rom, *ptr_ram)) {
            difference_bytes++;
        }
        ptr_rom++;
        ptr_ram++;
        compared_bytes++;
    }

    return difference_bytes;
}


unsigned long rom_verify(
        unsigned char rom_chip, 
        unsigned char rom_bank_start, unsigned long file_size) {

    unsigned char x = PROGRESS_X;
    unsigned char y = PROGRESS_Y;
    unsigned char w = PROGRESS_W;

    bram_bank_t bram_bank = 0;
    ram_ptr_t ram_address = (ram_ptr_t)RAM_BASE;

    // Now we compare the RAM with the actual ROM contents.
    info_line("Comparing with existing ROM ... (.) same, (*) different.");

    unsigned long rom_address = rom_address_from_bank(rom_bank_start);
    unsigned long rom_boundary = rom_address + file_size;

    unsigned int progress_row_current = 0;
    unsigned long rom_difference_bytes = 0;

    info_rom(rom_chip, STATUS_EQUATING, "Comparing ...");

    gotoxy(x, y);

    while (rom_address < rom_boundary) {

        // {asm{.byte $db}}

        unsigned int difference_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, PROGRESS_CELL);

        if (progress_row_current == PROGRESS_ROW) {
            gotoxy(x, ++y);
            progress_row_current = 0;
        }

        if (difference_bytes) {
            cputc('*');
        } else {
            cputc('=');
        }

        ram_address += PROGRESS_CELL;
        rom_address += PROGRESS_CELL;
        progress_row_current += PROGRESS_CELL;

        if (ram_address == BRAM_HIGH) {
            ram_address = (ram_ptr_t)BRAM_LOW;
            bram_bank++;
            // {asm{.byte $db}}
        }

        if (ram_address == RAM_HIGH) {
            ram_address = (ram_ptr_t)BRAM_LOW;
            bram_bank = 1;
        }

        rom_difference_bytes += difference_bytes;

        sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_difference_bytes, bram_bank, ram_address, rom_address);
        info_line(info_text);
    }

    info_rom(rom_chip, STATUS_EQUATED, "Compared.");

    return rom_difference_bytes;
}

void main() {

    unsigned int bytes = 0;
    unsigned char smc_error = 0;
    unsigned char rom_error = 0;
    unsigned char vera_error = 0;
    unsigned char flash_error = 0;

    bank_set_bram(0);
    bank_set_brom(0);

    cx16_k_screen_set_charset(3, (char *)0);

    frame_init();
    frame_draw();

    info_title("Commander X16 Flash Utility!");

    progress_clear();
    info_clear_all();

    // info_print(0, "The SMC chip on the X16 board controls the power on/off, keyboard and mouse pheripherals.");
    // info_print(1, "It is essential that the SMC chip gets updated together with the latest ROM on the X16 board.");
    // info_print(2, "On the X16 board, near the SMC chip are two jumpers");

    info_line("Detecting SMC, VERA and ROM chipsets ...");


#ifdef __SMC_CHIP_PROCESS

    SEI();

    // Detect the SMC bootloader and turn the SMC chip led WHITE if there is a bootloader present.
    // Otherwise, stop flashing and exit after explaining next steps.
    smc_bootloader = smc_detect();

    chip_smc();

    if(smc_bootloader == 0x0100) {
        // TODO: explain next steps ...
        info_smc(STATUS_ERROR, "SMC bootloader not found!");
        smc_error = 1;
    } else {
        if(smc_bootloader == 0x0200) {
            // TODO: explain next steps ...
            info_smc(STATUS_ERROR, "SMC seems to be unreachable!");
            smc_error = 1;
        } else {
            if(smc_bootloader != 0x1) {
                // TODO: explain next steps ...
                sprintf(info_text, "SMC bootloader not supported: v%02x", smc_bootloader);
                info_smc(STATUS_ERROR, info_text);
                smc_error = 1;
            } else {
                // Set the info for the SMC to Detected and show the bootloader version.
                sprintf(info_text, "SMC installed, bootloader v%02x", smc_bootloader);
                info_smc(STATUS_DETECTED, info_text);
            }

        }
    } 

    CLI();

#endif

    // Detecting VERA FPGA.
    chip_vera();
    info_vera(STATUS_DETECTED, "VERA installed, OK"); // Set the info for the VERA to Detected.

#ifdef __ROM_CHIP_PROCESS

    SEI();

    // Detecting ROM chips
    rom_detect();
    chip_rom();

    for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++) {
        if(rom_device_ids[rom_chip] != UNKNOWN) {
            if(rom_chip != 0) {
                info_rom(rom_chip, STATUS_DETECTED, "CARD ROM installed, OK!"); // Set the info for the ROMs to Detected.
            } else {
                info_rom(rom_chip, STATUS_DETECTED, "CX16 ROM installed, OK!"); // Set the info for the ROMs to Detected.
            }
        } else {
            if(rom_chip != 0) {
                info_rom(rom_chip, STATUS_NONE, "CARD ROM not installed!"); // Set the info for the ROMs to None.
            } else {
                info_rom(rom_chip, STATUS_ERROR, "CX16 ROM not installed!"); // The ROM chip on the CX16 should be installed!
                rom_error = 1;
            }
        }
    }

    CLI();

#endif

    bank_set_brom(4);

    if (smc_error || rom_error || vera_error) {
        wait_key("Mandatory chipsets not detected! Press [SPACE] to exit!", " ");
        system_reset();
    }


    info_line("Checking update files SMC.BIN, VERA.BIN, ROM(x).BIN ...");

#ifdef __SMC_CHIP_PROCESS
#ifdef __SMC_CHIP_CHECK

    SEI();

    // Read the smc file content.
    info_smc(STATUS_CHECKING, "Checking SMC.BIN file contents ...");

    unsigned int smc_file_size = smc_read(PROGRESS_X, PROGRESS_Y, PROGRESS_W, 8, 512, (ram_ptr_t)RAM_BASE);

    // In case no file was found, set the status to error and skip to the next, else, mention the amount of bytes read.
    if (!smc_file_size) {
        info_smc(STATUS_ERROR, "SMC.BIN empty or not found!");
        smc_error = 1;
    } else {
        // If the smc.bin file size is larger than 0x1E00 then there is an error!
        if(smc_file_size > 0x1E00) {
            sprintf(info_text, "SMC.BIN size %04x, too large!", smc_file_size);
            info_smc(STATUS_ERROR, info_text);
            smc_error = 1;
        } else {
            sprintf(info_text, "SMC.BIN size %04x, OK!", smc_file_size);
            info_smc(STATUS_CHECKED, info_text);
        }
    }

    CLI();

#endif
#endif

#ifdef __ROM_CHIP_PROCESS
#ifdef __ROM_CHIP_CHECK

    SEI();

    // For checking, we loop first all the ROM chips and check the file contents.
    // Any error identified gets reported and this chip will not be flashed.
    // In case of ROM0.BIN in error, no flashing will be done!
    for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++) {
        if(rom_device_ids[rom_chip] != UNKNOWN) {

            // Read the smc file content.
            info_rom(rom_chip, STATUS_CHECKING, ""); // Set the info for the ROMs to Checking.

            progress_clear();

            bank_set_brom(0);
            strcpy(file, "ROM .BIN");
            file[3] = 48+rom_chip;

            sprintf(info_text, "Opening %s flash file from SD card ...", file);
            info_line(info_text);

            unsigned char rom_bank = rom_chip * 32;
            unsigned long rom_bytes_read = rom_read(rom_bank, rom_sizes[rom_chip]);

            // In case no file was found, set the status to none and skip to the next, else, mention the amount of bytes read.
            if (!rom_bytes_read) {
                sprintf(info_text, "File %s empty or not found!", file);
                info_rom(rom_chip, STATUS_NONE, info_text);
            } else {
                // If the rom size is not a factor or 0x4000 bytes, then there is an error.
                unsigned long rom_file_modulo = rom_bytes_read % 0x4000;
                if(rom_file_modulo) {
                    sprintf(info_text, "File %s size %05x, %05x off!", file, rom_bytes_read, 0x4000UL - rom_file_modulo);
                    info_rom(rom_chip, STATUS_ERROR, info_text);
                    rom_error = 1;
                } else {
                    sprintf(info_text, "File %s size %05x, OK!", file, rom_bytes_read);
                    info_rom(rom_chip, STATUS_CHECKED, info_text);

                    file_sizes[rom_chip] = rom_bytes_read;

                    // Verify the ROM...
                    unsigned long rom_differences = rom_verify(
                        rom_chip, rom_bank, file_sizes[rom_chip]);
                    
                    if (rom_differences) {
                        sprintf(info_text, "%05x differences found!", rom_differences);
                        info_rom(rom_chip, STATUS_EQUATED, info_text);
                    } else {
                        info_rom(rom_chip, STATUS_NONE, "No flashing required!");
                    }
                }
            }
        }
    }

#endif
#endif

    bank_set_brom(0);
    CLI();
    unsigned char ch = wait_key("Continue with flashing? [Y/N]", "nyNY");        

    if(strchr("nN", ch)) {
        info_line("The checked chipset does not match the flash requirements, exiting ... ");
        flash_error = 1;
        return;
    }

    // If all detection, checks and verifications are done, the flashing can commence!
    if (!smc_error && !rom_error && !flash_error && !vera_error) {

    SEI();

#ifdef __SMC_CHIP_PROCESS
#ifdef __SMC_CHIP_FLASH

        info_line("Flashing SMC chip ...");
        if (!smc_file_size) {    
            info_smc(STATUS_FLASHING, "Press POWER/RESET on CX16 board!");
            unsigned long flashed_bytes = flash_smc(PROGRESS_X, PROGRESS_Y, PROGRESS_W, smc_file_size, 8, 512, (ram_ptr_t)RAM_BASE);
            info_smc(STATUS_UPDATED, "OK");
        }

#endif
#endif

    }

    bank_set_brom(4);
    CLI();
    wait_key("Press any key ...", NULL);

    // system_reset();

    return;
}
