#include "cx16-vera.h"
/**
 * @file cx16-vera.c

 * @author MooingLemur (https://github.com/mooinglemur)
 * @author Sven Van de Velde (https://github.com/FlightControl-User)
 * 
 * @brief COMMANDER X16 VERA FIRMWARE UPDATE ROUTINES
 *
 * @version 2.0
 * @date 2023-10-11
 *
 * @copyright Copyright (c) 2023
 *
 */

#include "cx16-defines.h"
#include "cx16-globals.h"

#include "cx16-vera.h"
#include "cx16-spi.h"
#include "cx16-display.h"

#pragma code_seg(CodeVera)
#pragma data_seg(DataVera)

__mem char* const vera_file_name = "VERA.BIN";
__mem unsigned long vera_file_size = 0;
__mem unsigned long const vera_size = (unsigned long)0x20000;


void vera_detect() {

// This conditional compilation ensures that only the detection interpretation happens if it is switched on.
#ifdef __VERA_CHIP_DETECT
    spi_get_jedec();
#else
    spi_manufacturer = 0x01;
    spi_memory_type = 0x02;
    spi_memory_capacity = 0x03;
#endif

    return;
}


void vera_get_device_text(unsigned char* device_text, unsigned char manufacturer, unsigned char memory_type, unsigned char memory_capacity) {

    sprintf(device_text, "%u.%u.%u", manufacturer, memory_type, memory_capacity);
    return;
}

unsigned long vera_read(unsigned char info_status) {

    unsigned char x = PROGRESS_X;
    unsigned char y = PROGRESS_Y;
    unsigned char w = PROGRESS_W;

    // We start for VERA from 0x1:0xA000.
    bram_ptr_t vera_bram_ptr = (bram_ptr_t)BRAM_LOW;
    bram_bank_t vera_bram_bank = 1;
    bank_set_bram(vera_bram_bank);
    unsigned char* vera_action_text;

    if(info_status == STATUS_READING) {
        vera_action_text = "Reading";
    } else {
        vera_action_text = "Checking";
        vera_bram_bank = 0;
    }

    unsigned long vera_address = 0;
    unsigned long vera_file_size = 0; /// Holds the amount of bytes actually read in the memory to be flashed.

    bank_set_brom(0);

    unsigned int progress_row_current = 0;

    display_action_text("Opening VERA.BIN from SD card ...");

    FILE *fp = fopen("VERA.BIN", "r");
    if (fp) {

        gotoxy(x, y);

        while (vera_file_size < vera_size) {

            if(info_status == STATUS_CHECKING) {
                vera_bram_ptr = (bram_ptr_t)0x0400; // When we check the file, we don't read in RAM yet.
            } 
            display_action_text_reading(vera_action_text, "VERA.BIN", vera_file_size, vera_size, vera_bram_bank, vera_bram_ptr);

            // __DEBUG

            bank_set_bram(vera_bram_bank);

            unsigned int vera_package_read = fgets(vera_bram_ptr, VERA_PROGRESS_CELL, fp); // this will load b bytes from the rom.bin file or less if EOF is reached.
            if (!vera_package_read) {
                break;
            }

            if (progress_row_current == VERA_PROGRESS_ROW) {
                gotoxy(x, ++y);
                progress_row_current = 0;
            }

            if(info_status == STATUS_READING)
                cputc('.');

            vera_bram_ptr += vera_package_read;
            vera_address += vera_package_read;
            vera_file_size += vera_package_read;
            progress_row_current += vera_package_read;

            if (vera_bram_ptr == (bram_ptr_t)BRAM_HIGH) {
                vera_bram_ptr = (bram_ptr_t)BRAM_LOW;
                vera_bram_bank++;
            }

            if (vera_bram_ptr == (bram_ptr_t)RAM_HIGH) {
                vera_bram_ptr = (bram_ptr_t)BRAM_LOW;
                vera_bram_bank = 1; // This is required to continue the reading into bram from bank 1.
            }
        }

        fclose(fp);
    }

    return vera_file_size;
}

unsigned int vera_compare(bram_bank_t bank_ram, bram_ptr_t bram_ptr, unsigned int vera_compare_size) {

    unsigned int compared_bytes = 0; /// Holds the amount of bytes actually verified between the VERA and the RAM.
    unsigned int equal_bytes = 0; /// Holds the amount of correct and verified bytes flashed in the VERA.

    bank_set_bram(bank_ram);

    while (compared_bytes < vera_compare_size) {

        unsigned char vera_byte = spi_read();
        if (vera_byte == *bram_ptr) {
            equal_bytes++;
        }
        bram_ptr++;
        compared_bytes++;
    }

    return equal_bytes;
}

unsigned char vera_preamable_RAM() {

    unsigned char x = PROGRESS_X;
    unsigned char y = PROGRESS_Y;
    unsigned char w = PROGRESS_W;

    bram_bank_t vera_bram_bank = 1;
    bram_ptr_t vera_bram_ptr = (bram_ptr_t)BRAM_LOW;
    bank_set_bram(vera_bram_bank);

    unsigned long vera_address = 0;

    unsigned int progress_row_current = 0;
    unsigned long vera_different_bytes = 0;

    gotoxy(x, y);

    // Display the header until the preamable has been found.

    unsigned char* ram_preamable_byte = (bram_ptr_t)BRAM_LOW; 

    unsigned char vera_file_preamable_pos = 0;
    unsigned int ram_pos = 0;
    unsigned char vera_file_preamable[4] = {0x7E, 0xAA, 0x99, 0x7E};

    if(*ram_preamable_byte == 0xFF) {
        // sprintf(info_text, "Premable byte %p: %x", ram_preamable_byte, *ram_preamable_byte);
        // display_action_text(info_text);
        while(vera_address <= vera_file_size) {
            ram_preamable_byte++;
            ram_pos++;
            vera_address++;
            // sprintf(info_text, "Premable byte %02p: %02x(%01u)",  ram_preamable_byte, *ram_preamable_byte, vera_file_preamable_pos);
            // display_action_text(info_text);
            if(vera_file_preamable_pos < 4 && *ram_preamable_byte == vera_file_preamable[vera_file_preamable_pos]) {
                if(vera_file_preamable_pos == 3) { 
                    break; // The preamable has been found ...
                } else {
                    vera_file_preamable_pos++;
                }
            } else {
                vera_file_preamable_pos = 0;
                if(*ram_preamable_byte == vera_file_preamable[vera_file_preamable_pos]) {
                    vera_file_preamable_pos++;
                }
            }
            if(*ram_preamable_byte) {
                if(*ram_preamable_byte >= 20 && *ram_preamable_byte <= 0x7F)
                    // cputcxy(x, y, *ram_preamable_byte);
                    x++;
            } else {
                y++;
                x = PROGRESS_X;
            }
        }
    } else {
        return 0; // No pre-fix byte 0xff
    }

    return 1;

}


unsigned char vera_preamable_SPI() {

    unsigned char x = PROGRESS_X;
    unsigned char y = PROGRESS_Y;
    unsigned char w = PROGRESS_W;


    return 1;
}

unsigned long vera_verify() {

    unsigned char x = PROGRESS_X;
    unsigned char y = PROGRESS_Y;
    unsigned char w = PROGRESS_W;

    bram_bank_t vera_bram_bank = 0;
    bram_ptr_t vera_bram_address = (bram_ptr_t)BRAM_LOW;
    bank_set_bram(vera_bram_bank);

    unsigned long vera_address = 0;
    unsigned long vera_boundary = vera_file_size;

    unsigned int progress_row_current = 0;
    unsigned long vera_different_bytes = 0;

    display_info_vera(STATUS_COMPARING, "Comparing VERA ...");

    gotoxy(x, y);

    spi_read_flash(0UL);

    while (vera_address < vera_boundary) {

        // {asm{.byte $db}}

        unsigned int equal_bytes = vera_compare(vera_bram_bank, (bram_ptr_t)vera_bram_address, VERA_PROGRESS_CELL);

        if (progress_row_current == VERA_PROGRESS_ROW) {
            gotoxy(x, ++y);
            progress_row_current = 0;
        }

        if (equal_bytes != VERA_PROGRESS_CELL) {
            cputc('*');
        } else {
            cputc('=');
        }

        vera_bram_address += VERA_PROGRESS_CELL;
        vera_address += VERA_PROGRESS_CELL;
        progress_row_current += VERA_PROGRESS_CELL;

        if (vera_bram_address == BRAM_HIGH) {
            vera_bram_address = (bram_ptr_t)BRAM_LOW;
            vera_bram_bank++;
            // {asm{.byte $db}}
        }

        if (vera_bram_address == RAM_HIGH) {
            vera_bram_address = (bram_ptr_t)BRAM_LOW;
            vera_bram_bank = 1;
        }

        vera_different_bytes += (VERA_PROGRESS_CELL - equal_bytes);

        sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", vera_different_bytes, vera_bram_bank, vera_bram_address, vera_address);
        display_action_text(info_text);
    }

    return vera_different_bytes;
}


unsigned char vera_erase() {

    unsigned long vera_address = 0;
    unsigned long vera_boundary = vera_file_size;

    unsigned char vera_total_64k_blocks = BYTE2(vera_file_size)+1;
    unsigned char vera_current_64k_block = 0;

    while(vera_current_64k_block < vera_total_64k_blocks) {
#ifdef __VERA_FLASH
        if(!spi_wait_non_busy()) {
            spi_block_erase(vera_address);
#else
        if(1) {
#endif
            vera_address += 0x10000;
            vera_current_64k_block++;
        } else {
            // There is an error. We must exit properly back to a prompt, no CX16 reset may happen!
            return 1;
        }
    }

    return 0;

}

unsigned long vera_flash() {

    unsigned char x_sector = PROGRESS_X;
    unsigned char y_sector = PROGRESS_Y;
    unsigned char w_sector = PROGRESS_W;

    unsigned long vera_address_page = 0;

    bram_bank_t vera_bram_bank = 1;
    bram_ptr_t vera_bram_ptr = (bram_ptr_t)BRAM_LOW;

    // Now we compare the RAM with the actual ROM contents.
    display_action_progress("Flashing ... (-) equal, (+) flashed, (!) error.");

    unsigned int progress_row_current = 0;

    display_info_vera(STATUS_FLASHING, "Flashing ...");

    while (vera_address_page < vera_file_size) {

        // {asm{.byte $db}}

        unsigned long vera_page_boundary = vera_address_page + VERA_PROGRESS_PAGE;
        unsigned long vera_address = vera_address_page;

        unsigned char x = x_sector;
        unsigned char y = y_sector;
        cputcxy(x,y,'.');
        cputc('.');

#ifdef __VERA_FLASH
        if(!spi_wait_non_busy()) {
#else
        if(1) {
#endif

            bank_set_bram(vera_bram_bank);

#ifdef __VERA_FLASH
            spi_write_page_begin(vera_address_page);
#endif
            while (vera_address < vera_page_boundary) {

                display_action_text_flashing(VERA_PROGRESS_PAGE, "VERA", vera_bram_bank, vera_bram_ptr, vera_address);
                
                for(unsigned int i=0; i<=255; i++) {
#ifdef __VERA_FLASH
                    spi_write(vera_bram_ptr[i]);
#endif
                }

                cputcxy(x,y,'+');
                cputc('+');

                vera_bram_ptr += VERA_PROGRESS_PAGE;
                vera_address += VERA_PROGRESS_PAGE;
                vera_address_page += VERA_PROGRESS_PAGE;
            }
        } else {
            // TODO: ERROR!!!
            return 0;
        }


        if (vera_bram_ptr == BRAM_HIGH) {
            vera_bram_ptr = (bram_ptr_t)BRAM_LOW;
            vera_bram_bank++;
            // {asm{.byte $db}}
        }

        if (vera_bram_ptr == RAM_HIGH) {
            vera_bram_ptr = (bram_ptr_t)BRAM_LOW;
            vera_bram_bank = 1;
        }

        x_sector += 2;
        if (!(vera_address_page % VERA_PROGRESS_ROW)) {
            x_sector = PROGRESS_X;
            y_sector++;
        }

    }

    display_action_text_flashed(vera_address_page, "VERA");
    wait_moment(32);

    return vera_address_page;
}

#pragma code_seg(Code)
#pragma data_seg(Data)
