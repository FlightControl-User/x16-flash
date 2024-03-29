/**
 * @file cx16-status.c
 * 
 * @author Wavicle from CX16 community (https://gist.github.com/jburks) -- Advice and outline of the ROM update logic & overall support and test assistance of this program.
 * @author MooingLemur from CX16 community (https://github.com/mooinglemur) -- Advice and outline of the main SPI and W25Q16 update logic, and supply of new VERA firmware.
 * @author Stefan Jakobsson from CX16 community (https://github.com/stefan-b-jakobsson) -- Advice and outline of the SMC update logic, SMC firmware and bootloader and creation of SMC firmware.
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

extern unsigned char status_smc;
extern unsigned char status_vera;
extern unsigned char status_rom[8];

inline unsigned char check_status_smc(unsigned char status);
inline unsigned char check_status_vera(unsigned char status);
inline unsigned char check_status_rom(unsigned char rom_chip, unsigned char status);
inline unsigned char check_status_cx16_rom(unsigned char status);
inline unsigned char check_status_card_roms(unsigned char status);
inline unsigned char check_status_roms(unsigned char status);
inline unsigned char check_status_roms_less(unsigned char status);
