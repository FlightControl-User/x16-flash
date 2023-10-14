/**
 * @file cx16-vera.h
 * @author MooingLemur (https://github.com/mooinglemur)
 * @author Sven Van de Velde (https://github.com/FlightControl-User)
 * @brief COMMANDER X16 VERA FIRMWARE UPDATE ROUTINES
 * @version 2.0
 * @date 2023-10-11
 * @copyright Copyright (c) 2023
 */

#include "cx16-spi.h"

extern char* const vera_file_name;
extern unsigned long vera_file_size;
extern unsigned long const vera_size;

void vera_detect();
unsigned char vera_preamable_RAM();
unsigned char vera_preamable_SPI();
unsigned long vera_read(unsigned char info_status);
unsigned char vera_erase();
unsigned long vera_flash();

