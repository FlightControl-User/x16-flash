/**
 * @file cx16-smc.c
 * 
 * @author Wavicle from CX16 forums (https://www.commanderx16.com/forum/index.php?/profile/1585-wavicle/)
 * @author Stefan Jakobsson from CX16 forums (
 * @author Sven Van de Velde (https://www.commanderx16.com/forum/index.php?/profile/1249-svenvandevelde/)
 * 
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
#include "cx16-utils.h"
#include "cx16-display.h"
#include "cx16-smc.h"

// Globals (to save zeropage and code overhead with parameter passing.)
__mem unsigned int smc_bootloader = 0;
__mem unsigned int smc_file_size = 0;
__mem unsigned char smc_version_string[16];



/**
 * @brief Detect the SMC chip on the CX16 board, and the bootloader version contained in it.
 * 
 * @return unsigned int bootloader version in the SMC chip, if all is OK.
 * @return unsigned int 0x0100 if there is no bootloader in the SMC chip.
 * @return unsigned int 0x0200 if there is a technical error reading or detecting the SMC chip. 
 */
unsigned int smc_detect() {

    unsigned int smc_bootloader_version = 0;

// This conditional compilation ensures that only the detection interpretation happens if it is switched on.
#ifdef __SMC_CHIP_DETECT
    smc_bootloader_version = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET);
    if(!BYTE1(smc_bootloader_version)) {
        if(smc_bootloader_version == 0xFF) { // When the bootloader is not present, 0xFF is returned.
            smc_bootloader_version = 0x0100;
        }
    } else {
        smc_bootloader_version = 0x0200;
    }
#else
    smc_bootloader_version = 0x01;
#endif

    return smc_bootloader_version;
}

/**
 * @brief Detect and write the SMC version number into the info_text.
 * 
 * @param version_string The string containing the SMC version filled upon return.
 */
unsigned long smc_version(unsigned char* version_string) {
    unsigned int version = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_VERSION);
    unsigned int major = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_MAJOR);
    unsigned int minor = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_MINOR);

    sprintf(version_string, "%u.%u.%u", version, major, minor);
    return MAKELONG(MAKEWORD(minor, major), MAKEWORD(0, version));
}


/**
 * @brief Shut down the CX16 through an SMC reboot.
 * The CX16 can be restarted using the POWER button on the CX16 board.
 * But this function can only be called once the SMC has flashed.
 * Otherwise, the SMC will get corrupted.
 * 
 */
void smc_reset() {

    bank_set_bram(0);
    bank_set_brom(0);

    // Reboot the SMC.
    cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0);

    while(1); // Wait until CX16 shuts down.
}

/**
 * @brief Flash a block of SMC_PROGRESS_CELL bytes into the SMC chip on the CX16 board from a RAM address.
 * 
 * @param ram_ptr The RAM pointer from where the bytes are read to be flashed sequentially.
 * @return unsigned int The checksum of the bytes successfully flashed, if all OK.
 * @return unsigned int 0xFFFF If there was an error during the flashing of the bytes.
 */
unsigned int smc_flash_block(ram_ptr_t ram_ptr) {
    unsigned char smc_checksum = 0;
    for(unsigned char i=0; i<SMC_PROGRESS_CELL; i++) {
        unsigned char smc_write = *ram_ptr;
        unsigned int smc_byte = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, 0x80, smc_write);
        if(smc_byte < 256) {
            smc_checksum += BYTE0(smc_byte);
        } else {
            return 0xFFFF;
        }
        ram_ptr++;
    }
    return smc_checksum;
}


/**
 * @brief Read the SMC.BIN file into RAM_BASE.
 * The maximum size of SMC.BIN data that should be in the file is 0x1E00.
 * 
 * @return unsigned int The amount of bytes read from SMC.BIN to be flashed.
 */
unsigned int smc_read(unsigned char display_progress) {

    unsigned int smc_file_size = 0; /// Holds the amount of bytes actually read in the memory to be flashed.
    unsigned int progress_row_bytes = 0;

    unsigned char x = PROGRESS_X;
    unsigned char y = PROGRESS_Y;
    unsigned char w = PROGRESS_W; 

    ram_ptr_t ram_ptr = (ram_ptr_t)RAM_BASE;  // It is assume that one RAM bank is 0X2000 bytes.

    display_action_progress("Reading SMC.BIN ... (.) data, ( ) empty");

    textcolor(WHITE);
    gotoxy(x, y);

    unsigned int smc_file_read = 0;

    unsigned int smc_bytes_total = 0;
    FILE *fp = fopen("SMC.BIN", "r");
    if (fp) {

        // We read block_size bytes at a time, and each block_size bytes we plot a dot.
        // Every r bytes we move to the next line.
        while (smc_file_read = fgets(ram_ptr, SMC_PROGRESS_CELL, fp)) {

            sprintf(info_text, "Reading SMC.BIN:%05x/%05x -> RAM:%02x:%04p ...", smc_file_read, smc_file_size, 0, ram_ptr);
            display_action_text(info_text);

            if (progress_row_bytes == SMC_PROGRESS_ROW) {
                gotoxy(x, ++y);
                progress_row_bytes = 0;
            }

            if(display_progress)
                cputc('.');

            ram_ptr += smc_file_read;
            smc_file_size += smc_file_read;
            progress_row_bytes += smc_file_read;
        }

        fclose(fp);
    }

    // We return the amount of bytes read.
    return smc_file_size;
}

/**
 * @brief Flash the SMC using the new firmware stored in RAM.
 * The bootloader starts from address 0x1E00 in the SMC, and should never be overwritten!
 * The flashing starts by pressing the POWER and RESET button on the CX16 board simultaneously.
 * 
 * @param smc_bytes_total Total bytes to flash the SMC from RAM.
 * @return unsigned int Total bytes flashed, 0 if there is an error.
 */
unsigned int smc_flash(unsigned int smc_bytes_total) {

    unsigned char x = PROGRESS_X;
    unsigned char y = PROGRESS_Y;
    unsigned char w = PROGRESS_W; 

    ram_ptr_t smc_ram_ptr = (ram_ptr_t)RAM_BASE;

    unsigned int flash_address = 0;
    unsigned int smc_row_bytes = 0;
    unsigned long flash_bytes = 0;

    display_action_progress("To start the SMC update, do the below action ...");

    unsigned char smc_bootloader_start = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_BOOTLOADER_RESET, 0x31);
    if(smc_bootloader_start) {
        sprintf(info_text, "There was a problem starting the SMC bootloader: %x", smc_bootloader_start);
        display_action_text(info_text);
        // Reboot the SMC.
        cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_REBOOT, 0);
        return 0;
    }

    unsigned char smc_bootloader_activation_countdown = 128;
    unsigned int smc_bootloader_not_activated = 0xFF;
    while(smc_bootloader_activation_countdown) {
        unsigned int smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET);
        if(smc_bootloader_not_activated) {
            wait_moment();
            sprintf(info_text, "[%03u] Press POWER and RESET on the CX16 to start the SMC update!", smc_bootloader_activation_countdown);
            display_action_text(info_text);
        } else {
            break;
        }
        smc_bootloader_activation_countdown--;
    }

    // Waiting a bit to ensure the bootloader is activated.
    smc_bootloader_activation_countdown = 10;
    while(smc_bootloader_activation_countdown) {
        wait_moment();
        sprintf(info_text, "Updating SMC in %u ...", smc_bootloader_activation_countdown);
        display_action_text(info_text);
        smc_bootloader_activation_countdown--;
    }

    smc_bootloader_not_activated = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_OFFSET);
    if(smc_bootloader_not_activated) {
        sprintf(info_text, "There was a problem activating the SMC bootloader: %x", smc_bootloader_not_activated);
        display_action_text(info_text);
        return 0;
    }

    display_action_progress("Updating SMC firmware ... (+) Updated");

    textcolor(WHITE);
    gotoxy(x, y);

    unsigned int smc_bytes_flashed = 0;
    unsigned int smc_attempts_total = 0;

    while(smc_bytes_flashed < smc_bytes_total) {
        unsigned char smc_attempts_flashed = 0;
        unsigned char smc_package_committed = 0;
        while(!smc_package_committed && smc_attempts_flashed < 10) {
            unsigned char smc_bytes_checksum = 0;
            unsigned int smc_package_flashed = 0;
            while(smc_package_flashed < SMC_PROGRESS_CELL) {
                unsigned char smc_byte_upload = *smc_ram_ptr;
                smc_ram_ptr++;
                smc_bytes_checksum += smc_byte_upload;
                // Upload byte
                unsigned char smc_upload_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, smc_byte_upload);
                smc_package_flashed++;
            }
            // 8 bytes have been uploaded, now send the checksum byte, in 1 complement.
            unsigned char smc_checksum_result = cx16_k_i2c_write_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_UPLOAD, (smc_bytes_checksum ^ 0xFF)+1);

            // Now send the commit command.
            unsigned int smc_commit_result = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_COMMIT);
            if(smc_commit_result == 1) {
                if (smc_row_bytes == SMC_PROGRESS_ROW) {
                    gotoxy(x, ++y);
                    smc_row_bytes = 0;
                }

                cputc('+');

                smc_bytes_flashed += SMC_PROGRESS_CELL;
                smc_row_bytes += SMC_PROGRESS_CELL;
                smc_attempts_total += smc_attempts_flashed;

                sprintf(info_text, "Flashed %05u of %05u bytes in the SMC, with %02u retries ...", smc_bytes_flashed, smc_bytes_total, smc_attempts_total);
                display_action_text(info_text);

                smc_package_committed = 1;
            } else {
                smc_ram_ptr -= SMC_PROGRESS_CELL;
                smc_attempts_flashed++; // We retry uploading the package ...
            }
        }
        if(smc_attempts_flashed >= 10) {
            sprintf(info_text, "There were too many attempts trying to flash the SMC at location %04x", smc_bytes_flashed);
            display_action_text(info_text);
            return 0;
        }
    }

    return smc_bytes_flashed;
}


