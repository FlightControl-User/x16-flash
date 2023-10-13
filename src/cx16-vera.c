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

    unsigned char bram_bank = 0;
    ram_ptr_t ram_address = (ram_ptr_t)RAM_BASE;

    unsigned long vera_address = 0;
    unsigned long vera_file_size = 0; /// Holds the amount of bytes actually read in the memory to be flashed.

    bank_set_bram(bram_bank);
    bank_set_brom(0);

    unsigned int progress_row_current = 0;
    unsigned char* vera_action_text;

    if(info_status == STATUS_READING)
        vera_action_text = "Reading";
    else
        vera_action_text = "Checking";

    display_action_text("Opening VERA.BIN from SD card ...");

    FILE *fp = fopen(file, "r");
    if (fp) {

        gotoxy(x, y);
        while (vera_file_size < vera_size) {

            sprintf(info_text, "%s %s:%05x/%05x -> RAM:%02x:%04p ...", vera_action_text, file, vera_file_size, vera_size, bram_bank, ram_address);
            display_action_text(info_text);

            // __DEBUG

            bank_set_bram(bram_bank);

            unsigned int vera_package_read = fgets(ram_address, VERA_PROGRESS_CELL, fp); // this will load b bytes from the rom.bin file or less if EOF is reached.
            if (!vera_package_read) {
                break;
            }

            if (progress_row_current == ROM_PROGRESS_ROW) {
                gotoxy(x, ++y);
                progress_row_current = 0;
            }

            if(info_status == STATUS_READING)
                cputc('.');

            ram_address += vera_package_read;
            vera_address += vera_package_read;
            vera_file_size += vera_package_read;
            progress_row_current += vera_package_read;

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

    return vera_file_size;
}
