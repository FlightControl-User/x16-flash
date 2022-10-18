/**
 * @file cx16-rom-flash.c
 * @author Sven Van de Velde (sven.van.de.velde@telenet.be)
 * @brief COMMANDER X16 ROM FLASH UTILITY
 * 
 * This flash utility can be used to flash a new ROM.BIN into ROM banks of the COMMANDER X16.  
 * Because the ROM.BIN is a significantly large binary, ROM flashing will only be possible using the SD CARD.
 * Therefore, this utility follows a simple and lean upload and flashing design, keeping it as simple as possible.
 * The utility program is to be place onto a folder of the SD card, together with the ROM.BIN.
 * The user can then simply load the program and run it from the SD card folder to flash the ROM.
 * 
 * Embedded in the source code is the technical documentation how the ROM flash works.
 * The main principles of ROM flashing is to **unlock the ROM** for flashing following pre-defined read/write sequences  
 * defined by the manufacturer of the chip. Once these sequences have been correctly initiated, a byte can be written
 * at the specified ROM address. And this is where it gets tricky and interesting concerning the COMMANDER X16  
 * address bus and architecture.  
 * 
 * # ROM Adressing
 * 
 * The address bus of the ROM chips follow 19 bit wide addressing mode.  
 * As you know, the COMMANDER X16 has 32 banks ROM of 16KB each.  
 * The COMMANDER X16 implements a banking solution to address these 19 bits, 
 * where the most significant 5 bits of the 19 bit address are configured through zero page $01, configuring one of the 32 ROM banks, 
 * while the main address bus is used to addresses the remaining 14 bits of the 19 bit ROM address. 
 * 
 * This results in the following architecture, where this flashing program uses a combination of setting the ROM bank
 * and the main address bus to select the 19 bit ROM address.
 * 
 * 
 *                              +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+  
 *                              | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
 *                              | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
 *                              +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+  
 *                              | BANK (ZP $01)     | MAIN ADDRESS BUS (+ $C000)                            |
 *                              +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+  
 * ROM_BANK_MASK  0x7C000       | 1 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
 *                              +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+  
 * ROM_PTR_MASK   0x03FFF       | 0 | 0 | 0 | 0 | 0 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
 *                              +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+  
 *
 * There is also one important caveat to keep in mind at all times ... What does the 6502 CPU see?  
 * So, the CPU uses zero page $01 to set the banks, but the lower 14 bit ROM address for the CPU
 * starts at $C000 and ends at $FFFF (16KB), as the CPU has a 16 bit address bus.
 * So the lower 14 bits of the ROM address requires to be added with $C000.
 * 
 * # Flasing the ROM
 * 
 * ROM flashing is done by executing specific write sequences at specific addresses with specific bytes into the ROM.
 * Depending on the write sequence, a specific ROM flashing function is selected.  
 * 
 * This utility uses the following ROM flashing sequences:
 * 
 *   - Reading the ROM manufacturer and device ID information.
 *   - Clearing a ROM sector (filling with FF). Each ROM sector is 1KB wide.
 *   - Flashing the cleared ROM sector with the new ROM bytes.
 * 
 * That's it. However, there is more to that ...
 * 
 * # ROM flashing approach
 * 
 * The ROM flashing requires a specific approach, as you need to keep in mind that while flashing ROM, there is **no ROM available**!
 * This utility flashes the ROM in four steps:
 * 
 *   1. Read the complete ROM.BIN file from the SD card into (banked) RAM.
 *   2. Flash the ROM from (banked) RAM.
 *   3. Verify that the ROM has been correctly flashed (still TODO).
 *   4. Reset and reboot the COMMANDER X16 using the new ROM state.
 * 
 * During and after ROM flash (from step 2), there cannot be any user interaction anymore and all interrupts must be disabled!
 * The screen writing that you see during flashing is executed directly from the program into the VERA, as no ROM screen IO functions can be used anymore.
 * 
 * 
 * 
 * 
 * @version 0.1
 * @date 2022-10-16
 * 
 * @copyright Copyright (c) 2022
 * 
 */


// Comment this pre-processor directive to disable ROM flashing routines (for emulator development purposes). 
#define __FLASH

// Ensures the proper character set is used for the COMMANDER X16.
#pragma encoding(petscii_mixed)

// Main includes.
#include <cx16.h>
#include <cx16-file.h>
#include <conio.h>
#include <printf.h>
#include <6502.h>
#include <kernal.h>

// Uses all parameters to be passed using zero pages (fast).
#pragma var_model(zp)

// Some addressing constants.
#define ROM_BASE            ((unsigned int)0xC000)
#define ROM_SIZE            ((unsigned int)0x4000)
#define ROM_PTR_MASK        ((unsigned long)0x03FFF)
#define ROM_BANK_MASK       ((unsigned long)0x7C000)

// The different device IDs that can be returned from the manufacturer ID read sequence.
#define SST39SF010A         ((unsigned char)0xB5)
#define SST39SF020A         ((unsigned char)0xB6)
#define SST39SF040          ((unsigned char)0xB7)


/**
 * @brief Calculates the 5 bit ROM bank from the ROM 19 bit address.
 * The ROM bank number is calcuated by taking the upper 5 bits (bit 18-14) and shifing those 14 bits to the right.
 * 
 * @param address The 19 bit ROM address.
 * @return unsigned char The ROM bank number for usage in ZP $01.
 */
unsigned char rom_bank(unsigned long address) {
    return (char)((unsigned long)(address & ROM_BANK_MASK) >> 14);
}


/**
 * @brief Calcuates the 16 bit ROM pointer from the ROM using the 19 bit address.
 * The 16 bit ROM pointer is calculated by masking the lower 14 bits (bit 13-0), and then adding $C000 to it.
 * The 16 bit ROM pointer is returned as a char* (brom_ptr_t).
 * @param address The 19 bit ROM address.
 * @return brom_ptr_t The 16 bit ROM pointer for the main CPU addressing.
 */
brom_ptr_t rom_ptr(unsigned long address) {
    return (brom_ptr_t)((unsigned int)(address & ROM_PTR_MASK) + ROM_BASE);
}

/**
 * @brief Read a byte from the ROM using the 19 bit address.
 * The lower 14 bits of the 19 bit ROM address are transformed into the **ptr_rom** 16 bit ROM address.
 * The higher 5 bits of the 19 bit ROM address are transformed into the **bank_rom** 5 bit bank number.
 * **bank_ptr* is used to set the bank using ZP $01.  **ptr_rom** is used to read the byte.
 * 
 * @param address The 19 bit ROM address.
 * @return unsigned char The byte read from the ROM.
 */
unsigned char rom_read_byte(unsigned long address)
{
    brom_bank_t bank_rom = rom_bank((unsigned long)address);
    brom_ptr_t  ptr_rom  = rom_ptr((unsigned long)address);

    bank_set_brom(bank_rom);
    return *ptr_rom;
}

/**
 * @brief Write a byte to the ROM using the 19 bit address.
 * The lower 14 bits of the 19 bit ROM address are transformed into the **ptr_rom** 16 bit ROM address.
 * The higher 5 bits of the 19 bit ROM address are transformed into the **bank_rom** 5 bit bank number.
 * **bank_ptr* is used to set the bank using ZP $01.  **ptr_rom** is used to write the byte into the ROM.
 * 
 * @param address The 19 bit ROM address.
 * @param value The byte value to be written.
 */
void rom_write_byte(unsigned long address, unsigned char value)
{
    brom_bank_t bank_rom = rom_bank((unsigned long)address);
    brom_ptr_t  ptr_rom  = rom_ptr((unsigned long)address);

    bank_set_brom(bank_rom);
    *ptr_rom = value;

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
void rom_wait(brom_ptr_t ptr_rom)
{
    unsigned char test1;
    unsigned char test2;

    do {
        test1 = *((brom_ptr_t)ptr_rom);
        test2 = *((brom_ptr_t)ptr_rom);
    } while((test1 & 0x40) != (test2 & 0x40));
}

/**
 * @brief Unlock a byte location for flashing using the 19 bit address.
 * This is a various purpose routine to unlock the ROM for flashing a byte.
 * The 3rd byte can be variable, depending on the write sequence used, so this byte is a parameter into the routine.
 * 
 * @param address The 3rd write to model the specific unlock sequence.
 * @param unlock_code The 3rd write to model the specific unlock sequence.
 */
void rom_unlock(unsigned long address, unsigned char unlock_code)
{
    rom_write_byte(0x05555, 0xAA);
    rom_write_byte(0x02AAA, 0x55);
    rom_write_byte(address, unlock_code);
}


/**
 * @brief Write a byte and wait until the byte has been successfully flashed into the ROM.
 * 
 * @param address The 19 bit ROM address.
 * @param value The byte value to be written.
 */
void rom_byte_program(unsigned long address, unsigned char value)
{
    brom_ptr_t  ptr_rom  = rom_ptr((unsigned long)address);

    rom_write_byte(address, value);
    rom_wait(ptr_rom);    
}


/**
 * @brief Erases a 1KB sector of the ROM using the 19 bit address.
 * This is required before any new bytes can be flashed into the ROM.
 * Erasing a sector of the ROM requires an erase sector sequence to be initiated, which has the following steps:
 * 
 *   1. Write byte $AA into ROM address $005555.
 *   2. Write byte $55 into ROM address $002AAA.
 *   3. Write byte $80 into ROM address $005555.
 *   4. Write byte $AA into ROM address $005555.
 *   5. Write byte $55 into ROM address $002AAA.
 * 
 * Once this write sequence is finished, the ROM sector is erased by writing byte $30 into the 19 bit ROM sector address.
 * Then it waits until the chip has correctly flashed the ROM erasure.
 * 
 * Note that a ROM sector is 1KB (not 4KB), so the most 7 significant bits (18-12) are used. 
 * The remainder 12 low bits are ignored.
 * 
 *                              +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+  
 *                              | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
 *                              | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
 *                              +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+  
 * SECTOR              0x7F000  | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
 *                              +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+  
 * IGNORED             0x00FFF  | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
 *                              +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+  
 * 
 * @param address The 19 bit ROM address.
 */
void rom_sector_erase(unsigned long address) 
{
    brom_ptr_t ptr_rom  = rom_ptr((unsigned long)address);

    rom_unlock(0x05555, 0x80);
    rom_unlock(address, 0x30);

    rom_wait(ptr_rom);
}


void main() {

    unsigned int bytes = 0;

    SEI();

    clrscr();

    printf("rom flash utility\n");

    printf("\nrom chipset device determination:\n\n");

    unsigned char rom_manufacturer_id = 0;
    unsigned char rom_device_id = 0;

    #ifdef __FLASH
    rom_unlock(0x05555, 0x90);
    rom_manufacturer_id = rom_read_byte(0x00000);
    rom_device_id = rom_read_byte(0x00001);
    rom_unlock(0x05555, 0xF0);

    rom_unlock(0x05555, 0x90);
    rom_manufacturer_id = rom_read_byte(0x00000);
    rom_device_id = rom_read_byte(0x00001);
    rom_unlock(0x05555, 0xF0);
    #endif


    bank_set_brom(4);

    printf("manufacturer id = %x\n", rom_manufacturer_id);
    
    char* rom_device = NULL;
    switch(rom_device_id) {
        case SST39SF010A:
            rom_device = "sst39sf010a";
            break;
        case SST39SF020A:
            rom_device = "sst39sf020a";
            break;
        case SST39SF040:
            rom_device = "sst39sf040";
            break;
        default:
            rom_device = "unknown";
            break;
    }
    printf("device id = %s (%x)\n", rom_device, rom_device_id );

    CLI();

    bank_set_bram(1);
    bank_set_brom(4);

    printf("\nopening file rom.bin from the sd card ...\n");
    unsigned int status = file_open(1, 8, 2, "rom.bin");
    if (status) {
        printf("cannot open file rom.bin from sd card!\n");
        return;
    }

    printf("opening of file rom.bin from sd card succesful ...\n");

    printf("\nloading kernal rom in main memory ...\n");

    ram_ptr_t ram_addr = (ram_ptr_t)0x4000;
    unsigned long rom_addr = 0x00000;

    while(rom_addr < 0x4000) {
        bytes = file_load_size(1, 8, 2, ram_addr, 128); // this will load 128 bytes from the rom.bin file or less if EOF is reached.
        if(bytes) {

            if (!(rom_addr % 0x02000)) {
                printf("\n%06x : ", rom_addr);
            }

            cputc('.');

            ram_addr += bytes;
            rom_addr += bytes;

        } else {
            printf("error: rom.bin is incomplete!");
            return;
        }
    }

    printf("\n\nloading remaining rom in banked memory ...\n");

    bank_set_bram(1); // read from bank 1 in bram.
    ram_addr = (ram_ptr_t)0xA000;

    bytes = file_load_size(1, 8, 2, ram_addr, 128); // this will load 128 bytes from the rom.bin file or less if EOF is reached.

    while(bytes && rom_addr < 0x28000) {

        if (!(rom_addr % 0x2000)) {
            printf("\n%06x : ", rom_addr);
        }

        cputc('.'); // show the user something has been read.
        ram_addr += bytes;
        rom_addr += bytes;
        if(ram_addr >= 0xC000) {
            ram_addr = ram_addr - 0x2000;
        }
        bytes = file_load_size(1, 8, 2, ram_addr, 128); // this will load 128 bytes from the rom.bin file or less if EOF is reached.
    }

    unsigned long rom_total = rom_addr; 
    printf("\n\na total of %06x rom bytes to be upgraded from rom.bin ...", rom_total);

    printf("\npress any key to upgrade to the new rom ...\n");

    while(!getin());
    clrscr();

    SEI();

    printf("\nupgrading kernal rom from main memory ...\n");

    ram_addr = (ram_ptr_t)0x4000;
    rom_addr = 0x00000;

    while(rom_addr < 0x4000) {
        
        if (!(rom_addr % 0x2000)) {
            printf("\n%06x : ", rom_addr);
        }

        if (!(rom_addr % 0x80))
            cputc('.');

        if (!(rom_addr % 0x1000)) {
            #ifdef __FLASH
            rom_sector_erase(rom_addr); // clearing rom sector
            #endif
        }

        for(unsigned char b=0; b<128; b++) {
            #ifdef __FLASH
            rom_unlock(0x05555, 0xA0);
            rom_byte_program(rom_addr, *ram_addr);
            #endif
            rom_addr++;
            ram_addr++;
        }
    }

    printf("\n\nflashing remaining rom from banked memory ...\n");

    unsigned char bank = 1;
    bank_set_bram(bank); // read from bank 1 in bram.
    ram_addr = (ram_ptr_t)0xA000;

    while(rom_addr < rom_total) {
        
        if (!(rom_addr % 0x2000)) {
            printf("\n%06x : ", rom_addr);
        }

        if (!(rom_addr % 0x80))
            cputc('.');

        if (!(rom_addr % 0x1000)) {
            #ifdef __FLASH
            rom_sector_erase(rom_addr); // clearing rom sector
            #endif
        }

        for(unsigned char b=0; b<128; b++) {
            #ifdef __FLASH
            rom_unlock(0x05555, 0xA0);
            rom_byte_program(rom_addr, *ram_addr);
            #endif
            rom_addr++;
            ram_addr++;

            if(ram_addr >= 0xC000) {
                ram_addr = ram_addr - 0x2000;
                bank++;
            }
            bank_set_bram(bank); // read from bank 1 in bram.
        }
    }

    printf("\n\nflashing of new rom successful ... resetting commander x16 to new rom...\n");

    for(unsigned int w=0; w<64; w++) {
        for(unsigned int v=0; v<256*64; v++) {
        } 
        cputc('.');
    }

    bank_set_bram(0);
    bank_set_brom(0);

    asm {
        jmp ($FFFC)
    }

}
