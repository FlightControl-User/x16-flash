/**
 * @file cx16-status.h
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

extern unsigned char status_smc;
extern unsigned char status_vera;
extern unsigned char status_rom[8];

inline unsigned char get_status_smc(unsigned char status);
inline unsigned char get_status_vera(unsigned char status);
inline unsigned char get_status_rom(unsigned char rom_chip, unsigned char status);
inline unsigned char get_status_cx16_rom(unsigned char status);
inline unsigned char get_status_card_roms(unsigned char status);
inline unsigned char get_status_roms(unsigned char status);
inline unsigned char get_status_roms_all(unsigned char status);
