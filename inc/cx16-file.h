/**
 * @file cx16-load.h
 * @author Sven Van de Velde (sven.van.de.velde@telenet.be)
 * @brief 
 * @version 0.1
 * @date 2022-10-17
 * 
 * @copyright Copyright (c) 2022
 * 
 */


#ifndef __CX16__
#error "Target platform must be cx16"
#endif

#include <cx16-typedefs.h>
#include <mos6522.h>


unsigned char file_open(char channel, char device, char secondary, char*filename);
unsigned int file_load_size(char channel, char device, char secondary, bram_ptr_t dptr, unsigned int size);
unsigned char file_close(char channel);
unsigned int file_load_bram(char channel, char device, char secondary, char* filename, bram_bank_t dbank, bram_ptr_t dptr);
