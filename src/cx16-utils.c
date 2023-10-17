/**
 * @file cx16-utils.c
 * 
 * @author Wavicle from CX16 community (https://gist.github.com/jburks) -- Advice and outline of the ROM update logic & overall support and test assistance of this program.
 * @author MooingLemur from CX16 community (https://github.com/mooinglemur) -- Advice and outline of the main SPI and W25Q16 update logic, and supply of new VERA firmware.
 * @author Stefan Jakobsson from CX16 community (https://github.com/stefan-b-jakobsson) -- Advice and outline of the SMC update logic, SMC firmware and bootloader and creation of SMC firmware.
 * @author Sven Van de Velde from CX16 community (https://github.com/FlightControl-User) -- Creation of this program, under the strong expertise by the people above.
 * 
 * @brief COMMANDER X16 UPDATE TOOL UTILITY ROUTINES
 *
 * @version 3.0
 * @date 2023-10-15
 *
 * @copyright Copyright (c) 2023
 *
 */

#include "cx16-defines.h"
#include "cx16-globals.h"

/**
 * @brief 
 * 
 */
void system_reset() {

    bank_set_bram(0);
    bank_set_brom(0);

#ifndef __INTELLISENSE__
    asm {
        jmp ($FFFC)
    }
#endif

    while(1);
}

/**
 * @brief 
 * 
 * @param info_text 
 * @param filter 
 * @return unsigned char 
 */
unsigned char util_wait_key(unsigned char* info_text, unsigned char* filter) {

    display_action_text(info_text);

    unsigned ch = 0;

    unsigned char bram = bank_get_bram();
    unsigned char brom = bank_get_brom();
    bank_set_bram(0);
    bank_set_brom(4);
    CLI();

    while (true) {
        ch = kbhit();
        // if there is a filter, check the filter, otherwise return ch.
        if (filter) {
            // Check if ch is part of the filter.
            if(strchr(filter, ch) != NULL) {
                break;
            }
        } else {
            if(ch)
                break;
        }
    }

    bank_set_bram(bram);
    bank_set_brom(brom);

    return ch;
}

void util_wait_space() {
    util_wait_key("Press [SPACE] to continue ...", " ");
}

/**
 * @brief 
 * 
 */
void wait_moment(unsigned char w) {
    for(unsigned char j=0; j<w; j++)
        for(unsigned int i=65535; i>0; i--);
}
