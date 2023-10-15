/**
 * @file cx16-vera.h
 * 
 * @author Wavicle from CX16 community (https://gist.github.com/jburks) -- Main ROM update logic & overall support and test assistance.
 * @author MooingLemur from CX16 community (https://github.com/mooinglemur) -- Main SPI and VERA update logic, VERA firmware.
 * @author Stefan Jakobsson from CX16 community (https://github.com/stefan-b-jakobsson) -- Main SMC update logic, SMC firmware and bootloader.
 * @author Sven Van de Velde from CX16 community (https://github.com/FlightControl-User) -- Creation of this program, under the strong expertise by the people above.
 * 
 * @brief COMMANDER X16 UPDATE VERA ROUTINES
 *
 * @version 3.0
 * @date 2023-10-15
 *
 * @copyright Copyright (c) 2023
 *
 */

#pragma code_seg(CodeVera)
#pragma data_seg(DataVera)

#include "cx16-spi.h"

extern char* const vera_file_name;
extern unsigned long vera_file_size;
extern unsigned long const vera_size;

void vera_detect();
unsigned char vera_preamable_RAM();
unsigned char vera_preamable_SPI();
unsigned long vera_read(unsigned char info_status);
unsigned long vera_verify();
unsigned char vera_erase();
unsigned long vera_flash();

#pragma code_seg(Code)
#pragma data_seg(Data)

