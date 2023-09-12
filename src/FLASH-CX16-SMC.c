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

// #define __DEBUG_FILE
#define __STDIO_FILECOUNT 2

// These pre-processor directives allow to disable specific ROM flashing functions (for emulator development purposes).
// Normally they should be all activated.
#define __FLASH
#define __ROM_CHIP_DETECT
#define __SMC_CHIP_DETECT
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
#define ROM_BASE ((unsigned int)0xC000)
#define ROM_SIZE ((unsigned int)0x4000)
#define ROM_PTR_MASK ((unsigned int)0x003FFF)
#define ROM_BANK_MASK ((unsigned long)0x3FC000)
#define ROM_CHIP_MASK ((unsigned long)0x380000)
#define ROM_SECTOR ((unsigned int)0x1000)

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

unsigned char rom_device_ids[8] = {0};
unsigned char* rom_device_names[8] = {0};
unsigned char* rom_size_strings[8] = {0};
unsigned char rom_manufacturer_ids[8] = {0};
unsigned long rom_sizes[8] = {0};

__mem unsigned int smc_bootloader;

#define STATUS_DETECTED     0
#define STATUS_NONE         1
#define STATUS_CHECKING     2
#define STATUS_FLASHING     3
#define STATUS_UPDATED      4
#define STATUS_ERROR        5

__mem unsigned char* status_text[6] = {"Detected", "None", "Checking", "Flashing", "Updated", "Error"};

#define STATUS_COLOR_DETECTED     WHITE
#define STATUS_COLOR_NONE         BLACK
#define STATUS_COLOR_CHECKING     CYAN
#define STATUS_COLOR_FLASHING     YELLOW
#define STATUS_COLOR_UPDATED      GREEN
#define STATUS_COLOR_ERROR        RED

__mem unsigned char status_color[6] = {STATUS_COLOR_DETECTED, STATUS_COLOR_NONE, STATUS_COLOR_CHECKING, STATUS_COLOR_FLASHING, STATUS_COLOR_UPDATED, STATUS_COLOR_ERROR};




unsigned char wait_key() {

    unsigned ch = 0;
    bank_set_bram(0);
    bank_set_brom(0);

    while (!(ch = kbhit()))
        ;

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
            cputcxy(x, y, '.');
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
void info_smc(unsigned char info_status) {
    print_smc_led(status_color[info_status]);
    info_clear(0); printf("SMC  - CX16 - %-8s - Bootloader version %u.", status_text[info_status], smc_bootloader);
}

/**
 * @brief Print the VERA status.
 * 
 * @param info_status The STATUS_ 
 */
void info_vera(unsigned char info_status) {
    print_vera_led(status_color[info_status]);
    info_clear(1); printf("VERA - CX16 - %-8s", status_text[info_status]);
}

void info_rom(unsigned char info_rom, unsigned char info_status) {
    char rom_name[16];
    char rom_detected[16];

    if(info_rom) {
        sprintf(rom_name, "ROM%u - CARD", info_rom);
    } else {
        sprintf(rom_name, "ROM%u - CX16", info_rom);
    }
    strcpy(rom_detected, status_text[info_status]);
    print_rom_led(info_rom, status_color[info_status]);
    info_clear(2+info_rom); printf("%s - %-8s - %02x - %-8s - %-4s", rom_name, rom_detected, rom_device_ids[info_rom], rom_device_names[info_rom], rom_size_strings[info_rom] );
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

unsigned long flash_read(unsigned char x, unsigned char y, unsigned char w, unsigned char b, unsigned int r, FILE *fp, ram_ptr_t flash_ram_address) {

    unsigned int flash_address = 0;
    unsigned long flash_bytes = 0; /// Holds the amount of bytes actually read in the memory to be flashed.
    unsigned int flash_row_total = 0;

    textcolor(WHITE);
    gotoxy(x, y);

    unsigned int read_bytes = 0;

    // We read b bytes at a time, and each b bytes we plot a dot.
    // Every r bytes we move to the next line.
    while (read_bytes = fgets(flash_ram_address, b, fp)) {

        if (flash_row_total == r) {
            gotoxy(x, ++y);
            flash_row_total = 0;
        }

        cputc('+');

        flash_ram_address += read_bytes;
        flash_address += read_bytes;
        flash_bytes += read_bytes;
        flash_row_total += read_bytes;
    }

    // We return the amount of bytes read.
    return flash_bytes;
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

    unsigned char info_text[80];

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

    unsigned int smc_bootloader_version = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET);
    if(!BYTE1(smc_bootloader_version)) {
        if(smc_bootloader_version == 0xFF) { // When the bootloader is not present, 0xFF is returned.
            return 0x0100;
        }
    } else {
        return 0x0200;
    }
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

void main() {

    unsigned int bytes = 0;

    SEI();
    bank_set_bram(1);
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


    // Detect the SMC bootloader and turn the SMC chip led WHITE if there is a bootloader present.
    // Otherwise, stop flashing and exit after explaining next steps.
    smc_bootloader = smc_detect();

// This conditional compiler ensures that only the compilation of the detection interpretation happens if it is switched on.
#ifdef __SMC_CHIP_DETECT
    if(smc_bootloader == 0x0100) {
        // TODO: explain next steps ...
        info_line("There is no SMC bootloader on this CX16 board. Press a key to exit ...");
        wait_key();
        return;
    }

    if(smc_bootloader == 0x0200) {
        // TODO: explain next steps ...
        info_line("The SMC chip seems to be unreachable! Press a key to exit ...");
        wait_key();
        return;
    }

    if(smc_bootloader != 0x1) {
        // TODO: explain next steps ...
        info_line("The current SMC bootloader version is not supported! Press a key to exit ...");
        wait_key();
        return;
    }
#endif

    // Detecting ROM chips
    rom_detect();

    chip_smc();
    chip_vera();
    chip_rom();

    info_smc(STATUS_DETECTED); // Set the info for the SMC to Detected.
    info_vera(STATUS_DETECTED); // Set the info for the VERA to Detected.
    for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++) {
        if(rom_device_ids[rom_chip] != UNKNOWN) {
            info_rom(rom_chip, STATUS_DETECTED); // Set the info for the ROMs to Detected.
        } else {
            info_rom(rom_chip, STATUS_NONE); // Set the info for the ROMs to None.
        }
    }

    bank_set_brom(4);
    CLI();

    info_smc(STATUS_CHECKING);
    info_line("Opening SMC flash file from SD card ...");

    wait_key();

    strcpy(file, "SMC.BIN");
    // Read the smc file content.
    FILE *fp = fopen(file,"r");
    if (fp) {

        info_line("Reading SMC flash file smc.bin into CX16 RAM ...");

        unsigned long size = 0x4000;
        unsigned int flash_bytes = (unsigned int)flash_read(PROGRESS_X, PROGRESS_Y, PROGRESS_W, 8, 512, fp, (ram_ptr_t)0x4000);
        if (flash_bytes == 0) {
            printf("error reading file.");
            return;
        }

        fclose(fp);

        // SEI();
        unsigned long flashed_bytes = flash_smc(PROGRESS_X, PROGRESS_Y, PROGRESS_W, flash_bytes, 8, 512, (ram_ptr_t)0x4000);
        // CLI();
/*
        {
            unsigned long flash_i2c_address = flash_rom_address_sector;
            ram_ptr_t read_ram_address = (ram_ptr_t)read_ram_address_sector;
            bram_bank_t read_ram_bank = read_ram_bank_sector;

            unsigned char x_sector = 14;
            unsigned char y_sector = 4;

            char *pattern;

            unsigned char x = x_sector;
            unsigned char y = y_sector;
            gotoxy(x, y);

            // gotoxy(50,1);
            // printf("ram = %2x, %4p, rom = %6x", read_ram_bank, read_ram_address, flash_rom_address);

            SEI();

            while (flash_i2c_address < flash_rom_address_boundary) {


                unsigned int equal_bytes = flash_smc_verify(read_ram_bank, (ram_ptr_t)read_ram_address, flash_i2c_address, 0x0100);
                // unsigned long equal_bytes = 0x100;

                if (equal_bytes != 0x0100) {
                    pattern = "*";
                }
                else {
                    pattern = ".";
                }
                read_ram_address += 0x0100;
                flash_i2c_address += 0x0100;

                print_address(read_ram_bank, read_ram_address, flash_i2c_address);

                textcolor(WHITE);
                gotoxy(x_sector, y_sector);
                printf("%s", pattern);
                x_sector++;

                if (read_ram_address == 0x8000) {
                    read_ram_address = (ram_ptr_t)0xA000;
                    read_ram_bank = 1;
                }

                if (read_ram_address == 0xC000) {
                    read_ram_address = (ram_ptr_t)0xA000;
                    read_ram_bank++;
                }

                if (!(flash_i2c_address % 0x4000)) {
                    x_sector = 14;
                    y_sector++;
                }
            }

            print_clear();
            printf("verified rom%u ... (.) same, (*) different. press a key to flash ...", flash_chip);
        }

        bank_set_brom(4);

        CLI();
        wait_key();

        // OK, so the flash file has been loaded into the 512 KBC memory.
        // We now reflash the rom banks.
        SEI();

        flash_rom_address_sector = rom_address(flash_rom_bank);
        read_ram_address_sector = (ram_ptr_t)0x4000;
        read_ram_bank_sector = 0;

        textcolor(WHITE);

        unsigned char x_sector = 14;
        unsigned char y_sector = 4;

        print_chip_led(flash_chip, PURPLE, BLUE);
        print_clear();
        printf("flashing rom%u from ram ... (-) unchanged, (+) flashed, (!) error.", flash_chip);

        char *pattern;

        unsigned int flash_errors_sector = 0;

        while (flash_rom_address_sector < flash_rom_address_boundary) {

            // rom_sector_erase(flash_rom_address_sector);

            unsigned int equal_bytes = flash_smc_verify(read_ram_bank_sector, (ram_ptr_t)read_ram_address_sector, flash_rom_address_sector, ROM_SECTOR);
            if (equal_bytes != ROM_SECTOR) {

                unsigned char flash_errors = 0;
                unsigned char retries = 0;

                do {

                    rom_sector_erase(flash_rom_address_sector);

                    unsigned long flash_rom_address_boundary = flash_rom_address_sector + ROM_SECTOR;
                    unsigned long flash_rom_address = flash_rom_address_sector;
                    ram_ptr_t read_ram_address = (ram_ptr_t)read_ram_address_sector;
                    bram_bank_t read_ram_bank = read_ram_bank_sector;

                    unsigned char x = x_sector;
                    unsigned char y = y_sector;
                    gotoxy(x, y);
                    printf("................");

                    print_address(read_ram_bank, read_ram_address, flash_rom_address);

                    while (flash_rom_address < flash_rom_address_boundary) {

                        print_address(read_ram_bank, read_ram_address, flash_rom_address);

                        unsigned long written_bytes = flash_write(read_ram_bank, (ram_ptr_t)read_ram_address, flash_rom_address);

                        equal_bytes = flash_smc_verify(read_ram_bank, (ram_ptr_t)read_ram_address, flash_rom_address, 0x0100);

#ifdef __FLASH_ERROR_DETECT
                        if (equal_bytes != 0x0100)
#else
                        if (0)
#endif
                        {
                            pattern = "!";
                            flash_errors++;
                        } else {
                            pattern = "+";
                        }
                        read_ram_address += 0x0100;
                        flash_rom_address += 0x0100;

                        textcolor(WHITE);
                        gotoxy(x, y);
                        printf("%s", pattern);
                        x++; // This should never exceed the 64 char boundary.
                    }

                    retries++;

                } while (flash_errors && retries <= 3);

                flash_errors_sector += flash_errors;

            } else {
                pattern = "----------------";

                textcolor(WHITE);
                gotoxy(x_sector, y_sector);
                printf("%s", pattern);
            }

            read_ram_address_sector += ROM_SECTOR;
            flash_rom_address_sector += ROM_SECTOR;

            if (read_ram_address_sector == 0x8000) {
                read_ram_address_sector = (ram_ptr_t)0xA000;
                read_ram_bank_sector = 1;
            }

            if (read_ram_address_sector == 0xC000) {
                read_ram_address_sector = (ram_ptr_t)0xA000;
                read_ram_bank_sector++;
            }

            x_sector += 16;
            if (!(flash_rom_address_sector % 0x4000)) {
                x_sector = 14;
                y_sector++;
            }
        }

        bank_set_bram(1);
        bank_set_brom(4);

        if (!flash_errors_sector) {
            textcolor(GREEN);
            print_chip_led(flash_chip, GREEN, BLUE);
            print_clear();
            printf("the flashing of rom%u went perfectly ok. press a key ...", flash_chip);
        } else {
            textcolor(RED);
            print_chip_led(flash_chip, RED, BLUE);
            print_clear();
            printf("the flashing of rom%u went wrong, %u errors. press a key ...", flash_chip, flash_errors_sector);
        }
    */
    } else {
        info_line("There is no SMC flash file smc.bin on the SD card. press a key to exit ...");
    }


    bank_set_brom(4);
    CLI();
    wait_key();

    system_reset();

    return;
}
