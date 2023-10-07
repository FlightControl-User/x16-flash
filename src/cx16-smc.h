/**
 * @file cx16-smc.h
 * 
 * @author Wavicle from CX16 forums (https://www.commanderx16.com/forum/index.php?/profile/1585-wavicle/)
 * @author Stefan Jakobsson from CX16 forums (
 * @author Sven Van de Velde (https://www.commanderx16.com/forum/index.php?/profile/1249-svenvandevelde/)

 * @brief COMMANDER X16 SMC FIRMWARE UPDATE ROUTINES
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

extern unsigned int smc_bootloader;
extern unsigned char smc_version_string[16];
extern unsigned int smc_file_size;

unsigned int smc_detect();
unsigned long smc_get_version_text(unsigned char* version_string, unsigned char release, unsigned char major, unsigned char minor);
void smc_reset();
unsigned int smc_flash_block(ram_ptr_t ram_ptr);
unsigned int smc_read(unsigned char display_progress);
unsigned int smc_flash(unsigned int smc_bytes_total);


