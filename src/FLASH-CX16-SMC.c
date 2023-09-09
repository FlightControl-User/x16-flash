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
// #define __FLASH_CHIP_DETECT
// #define __FLASH_ERROR_DETECT

// #define __DEBUG_FILE

#define FLASH_I2C_SMC_OFFSET 0x8E
#define FLASH_I2C_SMC_DEVICE 0x42

// Ensures the proper character set is used for the COMMANDER X16.
#pragma encoding(petscii_mixed)

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
#define CHIP_VERA_W 7
#define CHIP_ROM_X 20
#define CHIP_ROM_Y 3
#define CHIP_ROM_W 3


char file[32];

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
    screenlayer1();
    // Set the charset to lower case.
    cx16_k_screen_set_charset(3, (char *)0);
    textcolor(WHITE);
    bgcolor(BLUE);
    scroll(0);
    clrscr();
    vera_display_set_hstart(11);
    vera_display_set_hstop(147);
    vera_display_set_vstart(19);
    vera_display_set_vstop(219);
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

void print_smc_chip() {
    print_smc_led(GREY);
    print_chip(CHIP_SMC_X, CHIP_SMC_Y+1, CHIP_SMC_W, "smc     ");
}

void print_vera_led(unsigned char c) {
    print_chip_led(CHIP_VERA_X+1, CHIP_VERA_Y, CHIP_VERA_W, c, BLUE);
}

void print_vera_chip() {
    print_vera_led(GREY);
    print_chip(CHIP_VERA_X, CHIP_VERA_Y+1, CHIP_VERA_W, "vera     ");
}

void print_rom_led(unsigned char chip, unsigned char c) {
    print_chip_led(CHIP_ROM_X+chip*6+1, CHIP_ROM_Y, CHIP_ROM_W, c, BLUE);
}

void print_rom_chips() {

    char rom[9] = "rom0 000";
    for (unsigned char r = 0; r < 8; r++) {
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

void print_clear() {
    textcolor(WHITE);
    gotoxy(2, 14);
    printf("%60s", " ");
    gotoxy(2, 14);
}

/**
 * @brief Clean the progress area for the flashing.
 * 
 * @param y y start position
 * @param w width of the progress area
 * @param h height of the progress area
 */
void progress_chip_clear(unsigned char y, unsigned char w, unsigned char h) {

    textcolor(WHITE);
    bgcolor(BLUE);

    h += y;
    while (y < h) {
        gotoxy(0, y);
        for(unsigned char i = 0; i < w; i++) {
            cputc('.');
        }
        y++;
    }
}

unsigned long flash_read(unsigned char y, unsigned char w, unsigned char b, unsigned int r, FILE *fp, ram_ptr_t flash_ram_address) {

    unsigned int flash_address = 0;
    unsigned long flash_bytes = 0; /// Holds the amount of bytes actually read in the memory to be flashed.
    unsigned int flash_row_total = 0;

    textcolor(WHITE);
    gotoxy(0, y);

    unsigned int read_bytes = 0;

    // We read b bytes at a time, and each b bytes we plot a dot.
    // Every r bytes we move to the next line.
    while (read_bytes = fgets(flash_ram_address, b, fp)) {

        if (flash_row_total == r) {
            gotoxy(0, ++y);
            flash_row_total = 0;
        }

        cputc('.');

        flash_ram_address += read_bytes;
        flash_address += read_bytes;
        flash_bytes += read_bytes;
        flash_row_total += read_bytes;
    }

    // We return the amount of bytes read.
    return flash_bytes;
}

unsigned int flash_smc_detect() {

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

    CLI();

    frame_init();
    frame_draw();

    // wait_key();

    gotoxy(2, 1);
    printf("commander x16 flash utility");

    CLI();
    print_smc_chip();
    print_vera_chip();
    print_rom_chips();
    progress_chip_clear(17, 64, 32);
    print_clear(); printf("%s", "Detecting rom chipset and bootloader presence.");

    gotoxy(0, 2);
    bank_set_bram(1);
    bank_set_brom(0);

    // Detect the SMC bootloader and turn the SMC chip GREY if there is a bootloader present.
    // Otherwise, stop flashing and display next steps.
    unsigned int smc_bootloader = flash_smc_detect();
    if(smc_bootloader == 0x0100) {
        print_clear(); printf("there is no smc bootloader on this x16 board. exiting ...");
        wait_key();
        return;
    }

    if(smc_bootloader == 0x0200) {
        print_clear(); printf("there was an error reading the i2c api. exiting ...");
        wait_key();
        return;
    }

    print_clear(); printf("this x16 board has an smc bootloader version %u", smc_bootloader);

    print_clear(); printf("opening %s.", file);

    strcpy(file, "smc.bin");
    // Read the smc file content.
    FILE *fp = fopen(file,"r");
    if (fp) {

        progress_chip_clear(17, 64, 32);

        textcolor(WHITE);

        // We first detect if there is a bootloader routine present on the SMC.
        // In the case there isn't a bootloader, the X16 board update process cannot continue
        // and a manual update process needs to be conducted. 
        




        print_smc_led(CYAN);

        print_clear(); printf("reading data for smc update in ram ...");

        unsigned long size = 0x4000;
        unsigned long flash_bytes = flash_read(17, 64, 4, 256, fp, (ram_ptr_t)0x4000);
        if (flash_bytes == 0) {
            printf("error reading file.");
            return;
        }

        fclose(fp);

        // Now we compare the smc update data with the actual smc contents before flashing.
        // If everything is the same, we don't flash.

        print_clear(); printf("comparing smc with update ... (.) same, (*) different.");

/*
        unsigned long flash_bytes_different = flash_smc_verify(17, 64, 4, 256, (ram_ptr_t)0x4000, flash_bytes);
        if (flash_bytes_different == 0) {
            print_clear(); printf("the smc does not need to be flashed.");
            return;
        }
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
        print_clear();
        printf("there is no smc.bin file on the sdcard to flash the smc chip. press a key ...");
        gotoxy(2, 58);
        printf("no file");
    }


    bank_set_brom(4);
    CLI();
    wait_key();
    SEI();

    return;
}
