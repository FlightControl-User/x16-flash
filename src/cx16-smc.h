/**
 * @file cx16-smc.h
 * 
 * @author Wavicle from CX16 community (https://gist.github.com/jburks) -- Advice and outline of the ROM update logic & overall support and test assistance of this program.
 * @author MooingLemur from CX16 community (https://github.com/mooinglemur) -- Advice and outline of the main SPI and W25Q16 update logic, and supply of new VERA firmware.
 * @author Stefan Jakobsson from CX16 community (https://github.com/stefan-b-jakobsson) -- Advice and outline of the SMC update logic, SMC firmware and bootloader.
 * @author Sven Van de Velde from CX16 community (https://github.com/FlightControl-User) -- Creation of this program, under the strong expertise by the people above.
 * 
 * @brief COMMANDER X16 UPDATE TOOL SMC FIRMWARE UPDATE ROUTINES
 *
 * @version 2.0
 * @date 2023-09-21
 *
 * @copyright Copyright (c) 2023
 *
 */


#include "cx16-defines.h"
#include "cx16-globals.h"

#define FLASH_I2C_SMC_OFFSET 0x8E
#define FLASH_I2C_SMC_BOOTLOADER_RESET 0x8F
#define FLASH_I2C_SMC_UPLOAD 0x80
#define FLASH_I2C_SMC_COMMIT 0x81
#define FLASH_I2C_SMC_REBOOT 0x82
#define FLASH_I2C_SMC_VERSION 0x30
#define FLASH_I2C_SMC_MAJOR 0x31
#define FLASH_I2C_SMC_MINOR 0x32

#define FLASH_I2C_SMC_DEVICE 0x42

const unsigned int SMC_CHIP_SIZE = 0x2000;

extern unsigned int smc_bootloader;
extern unsigned char smc_version_text[16];
extern unsigned int smc_file_size;

extern unsigned char smc_file_header[32];

extern unsigned char smc_release;
extern unsigned char smc_major;
extern unsigned char smc_minor;

extern unsigned char smc_file_release;
extern unsigned char smc_file_major;
extern unsigned char smc_file_minor;


unsigned int smc_detect();
unsigned long smc_get_version_text(unsigned char* version_string, unsigned char release, unsigned char major, unsigned char minor);
void smc_reset();
unsigned int smc_flash_block(bram_ptr_t ram_ptr);
unsigned int smc_read(unsigned char info_status);
unsigned int smc_flash(unsigned int smc_bytes_total);
unsigned char smc_supported_rom(unsigned char rom_release);



