/**
 * @file cx16-rom.h
 * 
 * @author Wavicle from CX16 community (https://gist.github.com/jburks) -- Main ROM update logic & overall support and test assistance.
 * @author MooingLemur from CX16 community (https://github.com/mooinglemur) -- Main SPI and VERA update logic, VERA firmware.
 * @author Stefan Jakobsson from CX16 community (https://github.com/stefan-b-jakobsson) -- Main SMC update logic, SMC firmware and bootloader.
 * @author Sven Van de Velde from CX16 community (https://github.com/FlightControl-User) -- Creation of this program, under the strong expertise by the people above.
 * 
 * @brief COMMANDER X16 UPDATE TOOL ROM FIRMWARE UPDATE ROUTINES
 *
 * @version 2.0
 * @date 2023-09-21
 *
 * @copyright Copyright (c) 2023
 *
 */

#include "cx16-defines.h"
#include "cx16-globals.h"

// Globals
extern unsigned char rom_device_ids[8];
extern unsigned char* rom_device_names[8];
extern unsigned char* rom_size_strings[8];
extern unsigned char rom_release_text[8*13];
extern unsigned char rom_release[8];
extern unsigned char rom_prefix[8];
extern unsigned char rom_github[8*8];
extern unsigned char rom_manufacturer_ids[8];
extern unsigned long rom_sizes[8];
extern unsigned long file_sizes[8];


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

unsigned char rom_get_release(unsigned char release);
unsigned char rom_get_prefix(unsigned char release);
void rom_get_github_commit_id(unsigned char* commit_id, unsigned char* from);
void rom_get_version_text(unsigned char* rom_release_info, unsigned char rom_prefix, unsigned char rom_release, unsigned char* rom_github);


inline brom_ptr_t rom_ptr(unsigned long address);
inline unsigned char rom_bank(unsigned long address);
unsigned char rom_read_byte(unsigned long address);
void rom_write_byte(unsigned long address, unsigned char value);
unsigned char rom_byte_compare(brom_ptr_t ptr_rom, unsigned char value);
/* inline */ void rom_wait(brom_ptr_t ptr_rom);
/* inline */ void rom_unlock(unsigned long address, unsigned char unlock_code);
/* inline */ void rom_sector_erase(unsigned long address);
void rom_detect();
unsigned long rom_size(unsigned char rom_banks);
/* inline */ unsigned long rom_address_from_bank(unsigned char rom_bank);
unsigned char* rom_file(unsigned char rom_chip);
unsigned long rom_read(unsigned char rom_chip, unsigned char* file, unsigned char info_status, unsigned char brom_bank_start, unsigned long rom_size);
unsigned int rom_compare(bram_bank_t bank_ram, bram_ptr_t ptr_ram, unsigned long rom_compare_address, unsigned int rom_compare_size);
unsigned long rom_verify( unsigned char rom_chip, unsigned char rom_bank_start, unsigned long file_size);
/* inline */ void rom_byte_program(unsigned long address, unsigned char value);
/* inline */ unsigned long rom_write(unsigned char flash_ram_bank, bram_ptr_t flash_ram_address, unsigned long flash_rom_address, unsigned int flash_rom_size);
unsigned long rom_flash( unsigned char rom_chip, unsigned char rom_bank_start, unsigned long file_size);
