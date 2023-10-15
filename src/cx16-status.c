/**
 * @file cx16-status.c
 * 
 * @author Wavicle from CX16 community (https://gist.github.com/jburks) -- Main ROM update logic & overall support and test assistance.
 * @author MooingLemur from CX16 community (https://github.com/mooinglemur) -- Main SPI and VERA update logic, VERA firmware.
 * @author Stefan Jakobsson from CX16 community (https://github.com/stefan-b-jakobsson) -- Main SMC update logic, SMC firmware and bootloader.
 * @author Sven Van de Velde from CX16 community (https://github.com/FlightControl-User) -- Creation of this program, under the strong expertise by the people above.
 * 
 * @brief COMMANDER X16 UPDATE TOOL STATUS ROUTINES
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
 * @brief Check the status of any of the ROMs.
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
 * @brief Check the status of all the ROMs.
 * 
 * @param status The status to be checked.
 * @return unsigned char true if all chips are equal to the status.
 */
unsigned char check_status_roms_less(unsigned char status) {
    for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++) {
        if((unsigned char)(status_rom[rom_chip] > status)) {
            return 0;
        }        
    }
    return 1;
}

