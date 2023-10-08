/**
 * @file cx16-status.c
 * @author your name (you@domain.com)
 * @brief 
 * @version 0.1
 * @date 2023-10-05
 * 
 * @copyright Copyright (c) 2023
 * 
 */

#include "cx16-defines.h"
#include "cx16-globals.h"

// Globals
__mem unsigned char status_smc = 0;
__mem unsigned char status_vera = 0;
__mem unsigned char status_rom[8] = {0};


/**
 * @brief Check the status of the SMC chip.
 * 
 * @param status The status to be checked.
 * @return unsigned char true if the status is equal.
 */
unsigned char check_status_smc(unsigned char status) {
    return (unsigned char)(status_smc == status);
}

/**
 * @brief Check the status of the VERA chip.
 * 
 * @param status The status to be checked.
 * @return unsigned char true if the status is equal.
 */
unsigned char check_status_vera(unsigned char status) {
    return (unsigned char)(status_vera == status);
}

/**
 * @brief Check the status of a ROM chip.
 * 
 * @param rom_chip The ROM chip number, starting from 0, maximum 7.
 * @param status The status to be checked.
 * @return unsigned char true if the status is equal.
 */
unsigned char check_status_rom(unsigned char rom_chip, unsigned char status) {
    return (unsigned char)(status_rom[rom_chip] == status);
}

/**
 * @brief Check the status of the CX16 ROM chip.
 * 
 * @param status The status to be checked.
 * @return unsigned char true if the status is equal.
 */
inline unsigned char check_status_cx16_rom(unsigned char status) {
    return check_status_rom(0, status);
}

/**
 * @brief Check the status of all card ROMs. 
 * 
 * @param status The status to be checked.
 * @return unsigned char true if one chip is equal to the status.
 */
unsigned char check_status_card_roms(unsigned char status) {
    for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++) {
        if(check_status_rom(rom_chip, status)) {
            return 1;
        }        
    }
    return 0;
}

/**
 * @brief Check the status of all the ROMs.
 * 
 * @param status The status to be checked.
 * @return unsigned char true if one chip is equal to the status.
 */
unsigned char check_status_roms(unsigned char status) {
    for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++) {
        if(check_status_rom(rom_chip, status)) {
            return 1;
        }        
    }
    return 0;
}

/**
 * @brief Check the status of all the ROMs mutually.
 * 
 * @param status The status to be checked.
 * @return unsigned char true if all chips are equal to the status.
 */
unsigned char check_status_roms_all(unsigned char status) {
    for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++) {
        if(check_status_rom(rom_chip, status) != status) {
            return 0;
        }        
    }
    return 1;
}

