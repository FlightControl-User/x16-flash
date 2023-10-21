/**
 * @file cx16-w25q16.c
 * 
 * @author Wavicle from CX16 community (https://gist.github.com/jburks) -- Advice and outline of the ROM update logic & overall support and test assistance of this program.
 * @author MooingLemur from CX16 community (https://github.com/mooinglemur) -- Advice and outline of the main SPI and W25Q16 update logic, and supply of new VERA firmware.
 * @author Stefan Jakobsson from CX16 community (https://github.com/stefan-b-jakobsson) -- Advice and outline of the SMC update logic, SMC firmware and bootloader and creation of SMC firmware.
 * @author Sven Van de Velde from CX16 community (https://github.com/FlightControl-User) -- Creation of this program, under the strong expertise by the people above.
 * 
 * @brief COMMANDER X16 UPDATE VERA ROUTINES
 *
 * @version 3.0
 * @date 2023-10-15
 *
 * @copyright Copyright (c) 2023
 *
 */



#include "cx16-defines.h"
#include "cx16-globals.h"

#include "cx16-w25q16.h"
#include "cx16-spi.h"
#include "cx16-display.h"
#include "cx16-utils.h"
#include "cx16-display-text.h"

#pragma code_seg(CodeOverwrite)
#pragma data_seg(DataOverwrite)

__mem char* const vera_file_name = "VERA.BIN";
__mem unsigned long vera_file_size = 0;
__mem unsigned long const vera_size = (unsigned long)0x20000;

__mem unsigned char vera_file_header[32];

__mem unsigned char vera_release;
__mem unsigned char vera_major;
__mem unsigned char vera_minor;

__mem unsigned char vera_file_release;
__mem unsigned char vera_file_major;
__mem unsigned char vera_file_minor;

__mem unsigned char vera_version_text[16];


void w25q16_detect() {

// This conditional compilation ensures that only the detection interpretation happens if it is switched on.
#ifdef __VERA_CHIP_DETECT
    spi_get_jedec();
#else
    spi_manufacturer = 0x01;
    spi_memory_type = 0x02;
    spi_memory_capacity = 0x03;
#endif

    spi_deselect();
    return;
}


void vera_get_device_text(unsigned char* device_text, unsigned char manufacturer, unsigned char memory_type, unsigned char memory_capacity) {

    sprintf(device_text, "%u.%u.%u", manufacturer, memory_type, memory_capacity);
    return;
}


/**
 * @brief Search in the VERA.BIN header for supported ROM.BIN releases.
 * The first 3 bytes of the VERA.BIN header contain the VERA.BIN version, major and minor numbers.
 * 
 * @param rom_release The ROM release to search for.
 * @return unsigned char true if found.
 */
unsigned char vera_supported_rom(unsigned char rom_release) {
    for(unsigned char i=31; i>3; i--) {
        if(vera_file_header[i] == rom_release)
            return 1;
    }
    return 0;
}


/**
 * @brief Open the VERA.BIN file.
 * If there is a header, read the header in vera_file_header.
 * Otherwise blank the vera_file_header.
 * If the file is of size 0, close the FP and return NULL;
 * 
 * @param file_name The name of the file.
 * @return FILE* The opened file handle. NULL is returned if there is an error.
 */
FILE* fopen_vera_bin(unsigned char* file_name) {
    
    FILE *fp = fopen(file_name, "r");
    if (fp) {

        // Check if there is a header.
        unsigned char vera_file_has_header = 0;

        // Read the version and the compatible ROM releases from the VERA.BIN header first.
        unsigned int vera_file_read = fgets(vera_file_header, 32, fp);
        // Has the header been read, all ok, otherwise the file size is wrong!
        if(vera_file_read) {
            // Now we validate if the header was present.
            // If it wasn't, then 0xFF would have been read as the first byte.
            if(*((char*)0x0400) == 0xFF) {
                memset_fast(vera_file_header, 0x00, 32);
                // Now we must close the file, and open it again!
                fclose(fp);
                fp = fopen(file_name, "r");
            }
        } else {
            // The file size is zero, must exit ...
            vera_file_size = 0;
            fclose(fp);
            fp = NULL;
        }
    }
    return fp;
}

/**
 * @brief Read or check the vera file. Check if there is a header present.
 * Read the whole file and set the global variable vera_file_size.
 *  
 * @param info_status STATUS_CHECKING if checking the file, STATUS_READ if reading the file into RAM.
 * @return unsigned long The size of the file read.
 */
unsigned long w25q16_read(unsigned char info_status) {

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

    // Now we read the file for real.
    FILE *fp = fopen_vera_bin("VERA.BIN");
    if (fp) {

        gotoxy(x, y);

        while (vera_file_size < vera_size) {

            if(info_status == STATUS_CHECKING) {
                vera_bram_ptr = (bram_ptr_t)0x0400; // When we check the file, we don't read in RAM yet.
            } 

            display_action_text_reading(vera_action_text, "VERA.BIN", vera_file_size, vera_size, vera_bram_bank, vera_bram_ptr);
            bank_set_bram(vera_bram_bank);

            unsigned int vera_file_read = fgets(vera_bram_ptr, VERA_PROGRESS_CELL, fp); // this will load b bytes from the rom.bin file or less if EOF is reached.
            if (!vera_file_read) {
                break;
            }

            if (progress_row_current == VERA_PROGRESS_ROW) {
                gotoxy(x, ++y);
                progress_row_current = 0;
            }

            if(info_status == STATUS_READING)
                cputc('.');

            vera_bram_ptr += vera_file_read;
            vera_address += vera_file_read;
            vera_file_size += vera_file_read;
            progress_row_current += vera_file_read;

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


inline unsigned char w25q16_compare(bram_bank_t bank_ram, bram_ptr_t bram_ptr, unsigned char vera_compare_size)
{

    unsigned char compared_bytes = 0; /// Holds the amount of bytes actually verified between the VERA and the RAM.
    unsigned char equal_bytes = 0; /// Holds the amount of correct and verified bytes flashed in the VERA.

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


/**
 * @brief Verify the w25q16 flash memory contents with the VERA.BIN file contents loaded from RAM $01:A000.
 * 
 * @return unsigned long The total different bytes identified.
 */
unsigned long w25q16_verify(unsigned char verify) {

    unsigned char x = PROGRESS_X;
    unsigned char y = PROGRESS_Y;
    unsigned char w = PROGRESS_W;

    bram_bank_t bram_bank = 1;
    bram_ptr_t bram_ptr = (bram_ptr_t)BRAM_LOW;
    bank_set_bram(bram_bank);

    unsigned int progress_row_current = 0;

    unsigned char different_char = '*';

    if(verify) {
        display_action_progress("Verifying VERA with RAM after update ... (=) same, (!) error.");
        different_char = '!';
    } else {
        display_action_progress("Comparing VERA with RAM ... (.) data, (=) same, (*) different.");
    }

    unsigned long w25q16_address = 0;
    unsigned long w25q16_different_bytes = 0;

    gotoxy(x, y);

    wait_moment(16);
    spi_wait_non_busy();
    spi_read_flash(0UL); // Start the w26q16 flash memory read cycle from 0x0 using the spi interface

    while (w25q16_address < vera_file_size) {

        // WARNING: if VERA_PROGRESS_CELL every needs to be a value larger than 128 then the char scalar widtg needs to be extended to an int.
        unsigned char w25q16_equal_bytes = 0; /// Holds the amount of correct and verified bytes flashed in the VERA.
        unsigned char w25q16_compared_bytes = 0; /// Holds the amount of bytes actually verified between the VERA and the RAM.
        unsigned char w25q16_compare_size = VERA_PROGRESS_CELL;

        if(w25q16_address + VERA_PROGRESS_CELL > vera_file_size) {
            w25q16_compare_size = BYTE0(vera_file_size - w25q16_address);
        }
        bank_set_bram(bram_bank);

        do {
            unsigned char w25q16_byte = spi_read(); // read the w26q16 flash memory using the spi interface
            if (w25q16_byte == *bram_ptr) {
                w25q16_equal_bytes++;
            }
            bram_ptr++;
        } while(w25q16_compared_bytes++ != w25q16_compare_size-1);

        if (progress_row_current == VERA_PROGRESS_ROW) {
            gotoxy(x, ++y);
            progress_row_current = 0;
        }

        if (w25q16_equal_bytes != w25q16_compare_size) {
            cputc(different_char);
        } else {
            cputc('=');
        }

        // vera_bram_ptr += VERA_PROGRESS_CELL;
        w25q16_address += VERA_PROGRESS_CELL;
        progress_row_current += VERA_PROGRESS_CELL;

        if (bram_ptr == BRAM_HIGH) {
            bram_ptr = (bram_ptr_t)BRAM_LOW;
            bram_bank++;
            // {asm{.byte $db}}
        }

        if (bram_ptr == RAM_HIGH) {
            bram_ptr = (bram_ptr_t)BRAM_LOW;
            bram_bank = 1;
        }

        w25q16_different_bytes += (w25q16_compare_size - w25q16_equal_bytes);

        sprintf(info_text, "%05x different RAM:%02x:%04p <-> VERA:%05x", w25q16_different_bytes, bram_bank, bram_ptr, w25q16_address);
        display_action_text(info_text);
    }

    wait_moment(16);
    return w25q16_different_bytes;
}


unsigned char w25q16_erase() {

    unsigned long vera_address = 0;
    unsigned long vera_boundary = vera_file_size;

    unsigned char vera_total_64k_blocks = BYTE2(vera_file_size)+1;
    unsigned char vera_current_64k_block = 0;

    spi_select();

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

unsigned long w25q16_flash() {

    unsigned char x_sector = PROGRESS_X;
    unsigned char y_sector = PROGRESS_Y;
    unsigned char w_sector = PROGRESS_W;

    unsigned long vera_address_page = 0;

    bram_bank_t vera_bram_bank = 1;
    bram_ptr_t vera_bram_ptr = (bram_ptr_t)BRAM_LOW;

    display_action_progress(TEXT_PROGRESS_FLASHING);

    unsigned int progress_row_current = 0;

    unsigned long vera_flashed_bytes = 0;

    while (vera_address_page < vera_file_size) {

        // {asm{.byte $db}}

        unsigned long vera_page_boundary = vera_address_page + VERA_PROGRESS_PAGE;
        unsigned long vera_address = vera_address_page;

        unsigned char x = x_sector;
        unsigned char y = y_sector;
        cputcxy(x,y,'.');
        cputc('.');

#ifdef __VERA_FLASH
        if(!spi_wait_non_busy())
#else
        if(1)
#endif
        {
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
                vera_flashed_bytes += VERA_PROGRESS_PAGE;
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
        display_info_vera(STATUS_FLASHING, get_info_text_flashing(vera_flashed_bytes));
    }

    display_action_text_flashed(vera_address_page, "VERA");
    wait_moment(16);

    return vera_address_page;
}

#pragma code_seg(Code)
#pragma data_seg(Data)
