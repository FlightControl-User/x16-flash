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

unsigned char status_smc = 0;
unsigned char status_vera = 0;
unsigned char status_rom[8] = {0};

inline unsigned char get_status_smc(unsigned char status) {
    return (unsigned char)(status_smc == status);
}


inline unsigned char get_status_vera(unsigned char status) {
    return (unsigned char)(status_vera == status);
}


inline unsigned char get_status_rom(unsigned char rom_chip, unsigned char status) {
    return (unsigned char)(status_rom[rom_chip] == status);
}

inline unsigned char get_status_cx16_rom(unsigned char status) {
    return get_status_rom(0, status);
}

inline unsigned char get_status_card_roms(unsigned char status) {
    for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++) {
        if(get_status_rom(rom_chip, status)) {
            return status;
        }        
    }
    return STATUS_NONE;
}

inline unsigned char get_status_roms(unsigned char status) {
    for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++) {
        if(get_status_rom(rom_chip, status) == status) {
            return status;
        }        
    }
    return STATUS_NONE;
}

inline unsigned char get_status_roms_all(unsigned char status) {
    for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++) {
        if(get_status_rom(rom_chip, status) != status) {
            return 0;
        }        
    }
    return 1;
}
