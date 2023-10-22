/**
 * @file cx16-checksum.c
 * 
 * @author Sven Van de Velde from CX16 community (https://github.com/FlightControl-User) -- Creation of this program.
 * 
 * @brief COMMANDER X16 UPDATE TOOL CHECKSUM VALIDATOR
 *
 * @version 3.0
 * @date 2023-10-15
 *
 * @copyright Copyright (c) 2023
 *
 */

// Ensures the proper character set is used for the COMMANDER X16.
#pragma encoding(screencode_mixed)

// Uses all parameters to be passed using zero pages (fast).
#pragma var_model(zp)


#include <6502.h>
#include <cx16.h>
#include <cx16-conio.h>
#include <kernal.h>
#include <printf.h>
#include <sprintf.h>
#include <stdio.h>
#include "cx16-vera.h"
#include "cx16-veralib.h"

__mem unsigned long rom_file_checksum = 0;
__mem unsigned long rom_file_size = 0;
__mem unsigned long rom_checksum = 0;




unsigned char* rom_file(unsigned char rom_chip) {
    static char* file_rom_cx16 = "ROM.BIN";
    static char* file_rom_card = "ROMn.BIN";
    if(rom_chip) {
        file_rom_card[3] = '0'+rom_chip;
        return file_rom_card;
    } else {
        return file_rom_cx16;
    }
    return NULL;
}

void rom_calc_file_checksum(unsigned char rom_chip) {

    // We start for ROM from 0x0:0x7800 !!!!
    bram_bank_t rom_bram_bank = 0;
    bram_ptr_t rom_bram_ptr = (bram_ptr_t)0x0400;
    bank_set_bram(rom_bram_bank);

    unsigned long rom_address = 0;

    unsigned int rom_row_current = 0;
    unsigned char rom_release;
    unsigned char rom_github[6];

    rom_file_size = 0;
    rom_file_checksum = 0;

    unsigned char* file = "ROM-R45.BIN";
    printf("Opening %s from SD card ...\n", file);


    FILE *fp = fopen(file, "r");
    if (fp) {

        while (rom_file_size < 0x800000) {

            rom_bram_ptr = (char*)0x400;
            unsigned int rom_package_read = fgets(rom_bram_ptr, 128, fp); // this will load b bytes from the rom.bin file or less if EOF is reached.
            if (!rom_package_read) {
                break;
            }

            for(unsigned int b=0; b<rom_package_read; b++) {
                rom_file_checksum += rom_bram_ptr[b];
            }
            rom_file_size += rom_package_read;

        }
        fclose(fp);
    }

    cbm_k_clrchn();

    return;
}

void rom_calc_rom_checksum() {

    SEI();
    unsigned char bank_brom = 0;
    unsigned char* byte_brom = (char*)0xC000;
    unsigned long rom_addr = 0;

    while(rom_addr < rom_file_size) {

        bank_set_brom(bank_brom);
        rom_checksum += *byte_brom;
        rom_addr++;
        byte_brom++;

        if(byte_brom == 0x0) {
            byte_brom = (char*)0xC000;
            bank_brom++;
        }
    }

    bank_set_brom(4);
    CLI();

    return;
}

void main() {

    cx16_k_screen_set_mode(0);  // Default 80 columns mode.
    screenlayer1(); // Reset the screen layer values for conio.
    cx16_k_screen_set_charset(3, (char *)0);  // Lower case characters.
    vera_display_set_hstart(11);  // Set border.
    vera_display_set_hstop(147);  // Set border.
    vera_display_set_vstart(19);  // Set border.
    vera_display_set_vstop(219);  // Set border.
    vera_sprites_hide();  // Hide sprites.
    vera_layer0_hide();  // Layer 0 deactivated.
    vera_layer1_show();  // Layer 1 is the current text canvas.
    textcolor(DISPLAY_FG_COLOR);  // Default text color is white.
    bgcolor(DISPLAY_BG_COLOR);  // With a blue background.
    clrscr(); 

    printf("\n\n\n\nCommander X16 checksum calculator and validator of .BIN files.\n\n");

    rom_calc_file_checksum(1);

    printf("ROM-R45.BIN size    : %x\n", rom_file_size);
    printf("\nROM-R45.BIN checksum: %x\n", rom_file_checksum);

    rom_calc_rom_checksum();

    printf("ROM         checksum: %x\n", rom_checksum);


    bank_set_bram(0);
    bank_set_brom(4);

}