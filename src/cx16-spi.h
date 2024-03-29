/**
 * @file cx16-spi.h
 * 
 * @author Wavicle from CX16 community (https://gist.github.com/jburks) -- Advice and outline of the ROM update logic & overall support and test assistance of this program.
 * @author MooingLemur from CX16 community (https://github.com/mooinglemur) -- Advice and outline of the main SPI and W25Q16 update logic, and supply of new VERA firmware.
 * @author Stefan Jakobsson from CX16 community (https://github.com/stefan-b-jakobsson) -- Advice and outline of the SMC update logic, SMC firmware and bootloader and creation of SMC firmware.
 * @author Sven Van de Velde from CX16 community (https://github.com/FlightControl-User) -- Creation of this program, under the strong expertise by the people above.
 * 
 * @brief COMMANDER X16 UPDATE TOOL SPI FIRMWARE UPDATE ROUTINES
 *
 * @version 2.0
 * @date 2023-09-21
 *
 * @copyright Copyright (c) 2023
 *
 */

#pragma code_seg(CodeOverwrite)
#pragma data_seg(DataOverwrite)


extern unsigned char spi_manufacturer;
extern unsigned char spi_memory_type;
extern unsigned char spi_memory_capacity;


void spi_get_jedec();
void spi_get_uniq();
void spi_read_flash(unsigned long);
void spi_read_flash_to_bank(unsigned long);
void spi_block_erase(unsigned long);
void spi_write_page_begin(unsigned long);
unsigned char spi_wait_non_busy();
unsigned char spi_read();
void spi_write(unsigned char data);
void spi_fast();
unsigned char spi_deselect();
void spi_select();

unsigned char* const vera_reg_SPIData = (unsigned char*)0x9F3E;
unsigned char* const vera_reg_SPICtrl = (unsigned char*)0x9F3F;

#pragma code_seg(Code)
#pragma data_seg(Data)
