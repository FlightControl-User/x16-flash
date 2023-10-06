/**
 * @file cx16-rom.c
 * 
 * @author Wavicle from CX16 forums (https://www.commanderx16.com/forum/index.php?/profile/1585-wavicle/)
 * @author Stefan Jakobsson from CX16 forums (
 * @author Sven Van de Velde (https://www.commanderx16.com/forum/index.php?/profile/1249-svenvandevelde/)

 * @brief COMMANDER X16 ROM FIRMWARE UPDATE ROUTINES
 *
 * @version 2.0
 * @date 2023-09-21
 *
 * @copyright Copyright (c) 2023
 *
 */


#include "cx16-defines.h"
#include "cx16-globals.h"
#include "cx16-utils.h"
#include "cx16-display.h"
#include "cx16-rom.h"

/**
 * @brief Calcuates the 16 bit ROM pointer from the ROM using the 22 bit address.
 * The 16 bit ROM pointer is calculated by masking the lower 14 bits (bit 13-0), and then adding $C000 to it.
 * The 16 bit ROM pointer is returned as a char* (brom_ptr_t).
 * @param address The 22 bit ROM address.
 * @return brom_ptr_t The 16 bit ROM pointer for the main CPU addressing.
 */
brom_ptr_t rom_ptr(unsigned long address) { 
    return (brom_ptr_t)(((unsigned int)(address) & ROM_PTR_MASK) + ROM_BASE); 
}


/**
 * @brief Calculates the 8 bit ROM bank from the 22 bit ROM address.
 * The ROM bank number is calcuated by taking the upper 8 bits (bit 18-14) and shifing those 14 bits to the right.
 *
 * @param address The 22 bit ROM address.
 * @return unsigned char The ROM bank number for usage in ZP $01.
 */
unsigned char rom_bank(unsigned long address) { 

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

/**
 * @brief Erases a 1KB sector of the ROM using the 22 bit address.
 * This is required before any new bytes can be flashed into the ROM.
 * Erasing a sector of the ROM requires an erase sector sequence to be initiated, which has the following steps:
 *
 *   1. Write byte $AA into ROM address $005555.
 *   2. Write byte $55 into ROM address $002AAA.
 *   3. Write byte $80 into ROM address $005555.
 *   4. Write byte $AA into ROM address $005555.
 *   5. Write byte $55 into ROM address $002AAA.
 *
 * Once this write sequence is finished, the ROM sector is erased by writing byte $30 into the 22 bit ROM sector address.
 * Then it waits until the chip has correctly flashed the ROM erasure.
 *
 * Note that a ROM sector is 1KB (not 4KB), so the most 7 significant bits (18-12) are used.
 * The remainder 12 low bits are ignored.
 *
 *                                   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 *                                   | 2 | 2 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
 *                                   | 1 | 0 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
 *                                   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 *      SECTOR          0x37F000     | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
 *                                   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 *      IGNORED         0x000FFF     | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
 *                                   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 *
 * @param address The 22 bit ROM address.
 */
/* inline */ void rom_sector_erase(unsigned long address) {
    brom_ptr_t ptr_rom = rom_ptr((unsigned long)address);
    unsigned long rom_chip_address = address & ROM_CHIP_MASK;

#ifdef __FLASH
    rom_unlock(rom_chip_address + 0x05555, 0x80);
    rom_unlock(address, 0x30);

    rom_wait(ptr_rom);
#endif
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
        // if (rom_detect_address == 0x80000) {
        //     rom_manufacturer_ids[rom_chip] = 0x9f;
        //     rom_device_ids[rom_chip] = SST39SF040;
        // }
        // if (rom_detect_address == 0x100000) {
        //     rom_manufacturer_ids[rom_chip] = 0x9f;
        //     rom_device_ids[rom_chip] = SST39SF020A;
        // }
        // if (rom_detect_address == 0x180000) {
        //     rom_manufacturer_ids[rom_chip] = 0x9f;
        //     rom_device_ids[rom_chip] = SST39SF010A;
        // }
        // if (rom_detect_address == 0x200000) {
        //     rom_manufacturer_ids[rom_chip] = 0x9f;
        //     rom_device_ids[rom_chip] = SST39SF040;
        // }
        // if (rom_detect_address == 0x280000) {
        //     rom_manufacturer_ids[rom_chip] = 0x9f;
        //     rom_device_ids[rom_chip] = SST39SF040;
        // }
#endif

        // Ensure the ROM is set to BASIC.
        bank_set_brom(4);

        gotoxy(rom_chip*3+40, 1);
        printf("%02x", rom_device_ids[rom_chip]);

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

unsigned long rom_read(
        unsigned char display_progress,
        unsigned char rom_chip, unsigned char* file,
        unsigned char info_status,
        unsigned char brom_bank_start, unsigned long rom_size) {

    unsigned char x = PROGRESS_X;
    unsigned char y = PROGRESS_Y;
    unsigned char w = PROGRESS_W;

    unsigned char bram_bank = 0;
    ram_ptr_t ram_address = (ram_ptr_t)RAM_BASE;

    unsigned long rom_address = rom_address_from_bank(brom_bank_start);
    unsigned long rom_file_size = 0; /// Holds the amount of bytes actually read in the memory to be flashed.

    bank_set_bram(bram_bank);
    bank_set_brom(0);

    unsigned int rom_row_current = 0;
    unsigned char rom_release;
    unsigned char rom_github[6];

    sprintf(info_text, "Opening %s from SD card ...", file);
    display_action_text(info_text);

    FILE *fp = fopen(file, "r");
    if (fp) {

        gotoxy(x, y);
        while (rom_file_size < rom_size) {

            sprintf(info_text, "Reading %s:%05x/%05x -> RAM:%02x:%04p ...", file, rom_file_size, rom_size, bram_bank, ram_address);
            display_action_text(info_text);

            if (!(rom_address % 0x04000)) {
                brom_bank_start++;
            }

            // __DEBUG

            bank_set_bram(bram_bank);

            unsigned int rom_package_read = fgets(ram_address, ROM_PROGRESS_CELL, fp); // this will load b bytes from the rom.bin file or less if EOF is reached.
            if (!rom_package_read) {
                break;
            }

            if (rom_row_current == ROM_PROGRESS_ROW) {
                gotoxy(x, ++y);
                rom_row_current = 0;
            }

            if(display_progress)
                cputc('.');

            ram_address += rom_package_read;
            rom_address += rom_package_read;
            rom_file_size += rom_package_read;
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

    return rom_file_size;
}

unsigned int rom_compare(bram_bank_t bank_ram, ram_ptr_t ptr_ram, unsigned long rom_compare_address, unsigned int rom_compare_size) {

    unsigned int compared_bytes = 0; /// Holds the amount of bytes actually verified between the ROM and the RAM.
    unsigned int equal_bytes = 0; /// Holds the amount of correct and verified bytes flashed in the ROM.

    bank_set_bram(bank_ram);

    brom_bank_t bank_rom = rom_bank((unsigned long)rom_compare_address);
    brom_ptr_t ptr_rom = rom_ptr((unsigned long)rom_compare_address);

    bank_set_brom(bank_rom);

    while (compared_bytes < rom_compare_size) {

        if (rom_byte_compare(ptr_rom, *ptr_ram)) {
            equal_bytes++;
        }
        ptr_rom++;
        ptr_ram++;
        compared_bytes++;
    }

    return equal_bytes;
}


unsigned long rom_verify(
        unsigned char rom_chip, 
        unsigned char rom_bank_start, unsigned long file_size) {

    unsigned char x = PROGRESS_X;
    unsigned char y = PROGRESS_Y;
    unsigned char w = PROGRESS_W;

    bram_bank_t bram_bank = 0;
    ram_ptr_t ram_address = (ram_ptr_t)RAM_BASE;

    unsigned long rom_address = rom_address_from_bank(rom_bank_start);
    unsigned long rom_boundary = rom_address + file_size;

    unsigned int progress_row_current = 0;
    unsigned long rom_different_bytes = 0;

    display_info_rom(rom_chip, STATUS_COMPARING, "Comparing ...");

    gotoxy(x, y);

    while (rom_address < rom_boundary) {

        // {asm{.byte $db}}

        unsigned int equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL);

        if (progress_row_current == ROM_PROGRESS_ROW) {
            gotoxy(x, ++y);
            progress_row_current = 0;
        }

        if (equal_bytes != ROM_PROGRESS_CELL) {
            cputc('*');
        } else {
            cputc('=');
        }

        ram_address += ROM_PROGRESS_CELL;
        rom_address += ROM_PROGRESS_CELL;
        progress_row_current += ROM_PROGRESS_CELL;

        if (ram_address == BRAM_HIGH) {
            ram_address = (ram_ptr_t)BRAM_LOW;
            bram_bank++;
            // {asm{.byte $db}}
        }

        if (ram_address == RAM_HIGH) {
            ram_address = (ram_ptr_t)BRAM_LOW;
            bram_bank = 1;
        }

        rom_different_bytes += (ROM_PROGRESS_CELL - equal_bytes);

        sprintf(info_text, "Comparing: %05x differences between RAM:%02x:%04p <-> ROM:%05x", rom_different_bytes, bram_bank, ram_address, rom_address);
        display_action_text(info_text);
    }

    return rom_different_bytes;
}

/**
 * @brief Write a byte and wait until the byte has been successfully flashed into the ROM.
 *
 * @param address The 22 bit ROM address.
 * @param value The byte value to be written.
 */
/* inline */ void rom_byte_program(unsigned long address, unsigned char value) {
    brom_ptr_t ptr_rom = rom_ptr((unsigned long)address);

    rom_write_byte(address, value);
    rom_wait(ptr_rom);
}


/* inline */ unsigned long rom_write(unsigned char flash_ram_bank, ram_ptr_t flash_ram_address, unsigned long flash_rom_address, unsigned int flash_rom_size) {

    unsigned long flashed_bytes = 0; /// Holds the amount of bytes actually flashed in the ROM.

    unsigned long rom_chip_address = flash_rom_address & ROM_CHIP_MASK;

    bank_set_bram(flash_ram_bank);

    while (flashed_bytes < flash_rom_size) {
#ifdef __FLASH
        rom_unlock(rom_chip_address + 0x05555, 0xA0);
        rom_byte_program(flash_rom_address, *flash_ram_address);
#endif
        flash_rom_address++;
        flash_ram_address++;
        flashed_bytes++;
    }

    return flashed_bytes;
}

unsigned long rom_flash(
        unsigned char rom_chip, 
        unsigned char rom_bank_start, unsigned long file_size) {

    unsigned char x_sector = PROGRESS_X;
    unsigned char y_sector = PROGRESS_Y;
    unsigned char w_sector = PROGRESS_W;

    bram_bank_t bram_bank_sector = 0;
    ram_ptr_t ram_address_sector = (ram_ptr_t)RAM_BASE;

    // Now we compare the RAM with the actual ROM contents.
    display_action_progress("Flashing ... (-) equal, (+) flashed, (!) error.");

    unsigned long rom_address_sector = rom_address_from_bank(rom_bank_start);
    unsigned long rom_boundary = rom_address_sector + file_size;

    unsigned int progress_row_current = 0;
    unsigned long rom_flash_errors = 0;

    display_info_rom(rom_chip, STATUS_FLASHING, "Flashing ...");

    unsigned long flash_errors = 0;

    while (rom_address_sector < rom_boundary) {

        // {asm{.byte $db}}

        unsigned int equal_bytes = rom_compare(bram_bank_sector, (ram_ptr_t)ram_address_sector, rom_address_sector, ROM_SECTOR);

        if (equal_bytes != ROM_SECTOR) {

            unsigned int flash_errors_sector = 0;
            unsigned char retries = 0;

            do {

                rom_sector_erase(rom_address_sector);

                unsigned long rom_sector_boundary = rom_address_sector + ROM_SECTOR;
                unsigned long rom_address = rom_address_sector;
                ram_ptr_t ram_address = (ram_ptr_t)ram_address_sector;
                bram_bank_t bram_bank = bram_bank_sector;

                unsigned char x = x_sector;
                unsigned char y = y_sector;
                gotoxy(x, y);
                printf("........");

                while (rom_address < rom_sector_boundary) {

                    sprintf(info_text, "Flashing ... RAM:%02x:%04p -> ROM:%05x ... %u flash errors ...", bram_bank_sector, ram_address_sector, rom_address_sector, flash_errors_sector + flash_errors);
                    display_action_text(info_text);

                    unsigned long written_bytes = rom_write(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL);

                    equal_bytes = rom_compare(bram_bank, (ram_ptr_t)ram_address, rom_address, ROM_PROGRESS_CELL);

                    gotoxy(x, y);

#ifdef __FLASH_ERROR_DETECT
                    if (equal_bytes != ROM_PROGRESS_CELL)
#else
                    if (0)
#endif
                    {
                        cputcxy(x,y,'!');
                        flash_errors_sector++;
                    } else {
                        cputcxy(x,y,'+');
                    }
                    ram_address += ROM_PROGRESS_CELL;
                    rom_address += ROM_PROGRESS_CELL;

                    x++; // This should never exceed the 64 char boundary.
                }

                retries++;

            } while (flash_errors_sector && retries <= 3);

            flash_errors += flash_errors_sector;

        } else {
            cputsxy(x_sector, y_sector, "--------");
        }

        ram_address_sector += ROM_SECTOR;
        rom_address_sector += ROM_SECTOR;

        if (ram_address_sector == BRAM_HIGH) {
            ram_address_sector = (ram_ptr_t)BRAM_LOW;
            bram_bank_sector++;
            // {asm{.byte $db}}
        }

        if (ram_address_sector == RAM_HIGH) {
            ram_address_sector = (ram_ptr_t)BRAM_LOW;
            bram_bank_sector = 1;
        }

        x_sector += 8;
        if (!(rom_address_sector % ROM_PROGRESS_ROW)) {
            x_sector = PROGRESS_X;
            y_sector++;
        }

        sprintf(info_text, "%u flash errors ...", flash_errors);
        display_info_rom(rom_chip, STATUS_FLASHING, info_text);
    }

    display_action_text("Flashed ...");

    return flash_errors;
}

