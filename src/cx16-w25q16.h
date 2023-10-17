/**
 * @file cx16-vera.h
 * 
 * @author Wavicle from CX16 community (https://gist.github.com/jburks) -- Advice and outline of the ROM update logic & overall support and test assistance of this program.
 * @author MooingLemur from CX16 community (https://github.com/mooinglemur) -- Advice and outline of the main SPI and W25Q16 update logic, and supply of new VERA firmware.
 * @author Stefan Jakobsson from CX16 community (https://github.com/stefan-b-jakobsson) -- Advice and outline of the SMC update logic, SMC firmware and bootloader and creation of SMC firmware.
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

#include "cx16-defines.h"
#include "cx16-globals.h"

#pragma code_seg(CodeVera)
#pragma data_seg(DataVera)

#include "cx16-spi.h"

extern char* const vera_file_name;
extern unsigned long vera_file_size;
extern unsigned long const vera_size;

void w25q16_detect();
unsigned char w25q16_preamable_RAM();
unsigned char w25q16_preamable_SPI();
unsigned long w25q16_read(unsigned char info_status);
unsigned long w25q16_verify();
unsigned char w25q16_erase();
unsigned long w25q16_flash();

#pragma code_seg(Code)
#pragma data_seg(Data)

