/**
 * @file cx16-load.c
 * @author Sven Van de Velde (sven.van.de.velde@telenet.be)
 * @brief 
 * @version 0.1
 * @date 2022-10-17
 * 
 * @copyright Copyright (c) 2022
 * 
 */


#include <cx16.h>
#include <kernal.h>
#include <stdlib.h>
#include <cx16-vera.h>

/**
 * @brief Load a file to banked ram located between address 0xA000 and 0xBFFF incrementing the banks.
 *
 * @param channel Input channel.
 * @param device Input device.
 * @param secondary Secondary channel.
 * @param filename Name of the file to be loaded.
 * @return 
 *  - 0x0000: Something is wrong! Kernal Error Code (https://commodore.ca/manuals/pdfs/commodore_error_messages.pdf)
 *  - other: OK! The last pointer between 0xA000 and 0xBFFF is returned. Note that the last pointer is indicating the first free byte.
 */
unsigned char file_open(char channel, char device, char secondary, char* filename)
{
    unsigned char status = 0;

    #ifdef __DEBUG_FILE
        printf("open file, c=%u, d=%u, s=%u, f=%s", channel, device, secondary, filename);
    #endif

    cbm_k_setnam(filename);
    cbm_k_setlfs(channel, device, secondary);

    status = cbm_k_open();

    #ifdef __DEBUG_FILE
        printf(", open status=%u", status);
    #endif

    status = cbm_k_readst();
    #ifdef __DEBUG_FILE
        printf(", open status=%u", status);
    #endif
    if(status) return status;

    status = cbm_k_chkin(channel);
    status = cbm_k_readst();

    #ifdef __DEBUG_FILE
        printf(", chkin status=%u\n", status);
    #endif

    #ifdef __DEBUG_FILE
        // cbm_k_chkin(0);
        // while(!getin());
    #endif

    return status;
}


/**
 * @brief Load a file to ram or (banked ram located between address 0xA000 and 0xBFFF), incrementing the banks.
 * This function uses the new CX16 macptr kernal API at address $FF44.
 *
 * @param channel Input channel.
 * @param device Input device.
 * @param secondary Secondary channel.
 * @param filename Name of the file to be loaded.
 * @param bank The bank in banked ram to where the data of the file needs to be loaded.
 * @param sptr The pointer between 0xA000 and 0xBFFF in banked ram.
 * @return char status
 *  - not 0: Something is wrong! Kernal Error Code (https://commodore.ca/manuals/pdfs/commodore_error_messages.pdf)
 *  - 0: OK!
 */
unsigned int file_load_size(char channel, char device, char secondary, bram_ptr_t dptr, size_t size) 
{
    #ifdef __DEBUG_FILE
        printf("load file, c=%u, d=%u, s=%u, b=%x, p=%p, si=%u", channel, device, secondary, bank_get_bram(), dptr, size);
    #endif

    unsigned int status = 0;

    unsigned int read = 0;
    unsigned int remaining = size;

    status = cbm_k_chkin(channel);
    status = cbm_k_readst();
    #ifdef __DEBUG_FILE
        printf(", chkin status=%u", status);
    #endif
    if(status) return 0;

    char* ptr = dptr;
    if(BYTE1(ptr) == 0xC0) ptr -= 0x2000;

    unsigned int bytes = 0;
    do {
        if(!size) {
            #ifdef __DEBUG_FILE
                printf(", reading max ptr=%p", ptr);
            #endif
            bytes = cbm_k_macptr(0, ptr);
        } else {
            if(remaining >= 128) {
                #ifdef __DEBUG_FILE
                    printf(", reading 128 ptr=%p", ptr);
                #endif
                bytes = cbm_k_macptr(128, ptr);
            } else {
                #ifdef __DEBUG_FILE
                    printf(", reading remaining=%u ptr=%p", remaining, ptr);
                #endif
                bytes = cbm_k_macptr(remaining, ptr);
            }
        }

        status = cbm_k_readst();
        #ifdef __DEBUG_FILE
        printf(", macptr status=%u", status);
        #endif
        if(status & 0xBF) {
            #ifdef __DEBUG_FILE
            printf("macptr error status=%u", status);
            #endif
            return 0;
        }

        if(bytes == 0xFFFF) {
            #ifdef __DEBUG_FILE
            printf("read error!!!");
            #endif
            cbm_k_chkin(0);
            while(!getin());
            cbm_k_chkin(channel);
            return 0;
        }

        #ifdef __DEBUG_FILE
            printf(", bytes=%u", bytes);
        #endif

        read += bytes;
        ptr += bytes;
        if(BYTE1(ptr) == 0xC0) ptr -= 0x2000;
        remaining -= bytes;

        #ifdef __DEBUG_FILE
            printf(", size=%u, remaining=%u, read=%u", size, remaining, read);
        #endif


    } while ((status == 0) && ((size && remaining) || !size));

    #ifdef __DEBUG_FILE
        printf(", read bytes r=%u, status=%u\n", read, status);
    #endif

    cbm_k_chkin(0);

    #ifdef __DEBUG_FILE
        while(!getin());
    #endif

    return read;
}

/**
 * @brief Load a file to banked ram located between address 0xA000 and 0xBFFF incrementing the banks.
 *
 * @param channel Input channel.
 * @param device Input device.
 * @param secondary Secondary channel.
 * @return 
 *  - 0x0000: Something is wrong! Kernal Error Code (https://commodore.ca/manuals/pdfs/commodore_error_messages.pdf)
 *  - other: OK! The last pointer between 0xA000 and 0xBFFF is returned. Note that the last pointer is indicating the first free byte.
 */
unsigned char file_close(char channel) 
{
    byte status = 0;

    #ifdef __DEBUG_FILE
        printf("close file, c=%u", channel);
    #endif

    status = cbm_k_close(channel);
    cbm_k_clrchn();

    #ifdef __DEBUG_FILE
        printf(", status=%u\n", status);
    #endif

    #ifdef __DEBUG_FILE
        // cbm_k_chkin(0);
        // while(!getin());
    #endif

    return status;
}

/**
 * @brief Load a file to banked ram located between address 0xA000 and 0xBFFF incrementing the banks.
 *
 * @param channel Input channel.
 * @param device Input device.
 * @param secondary Secondary channel.
 * @param filename Name of the file to be loaded.
 * @param bank The bank in banked ram to where the data of the file needs to be loaded.
 * @param sptr The pointer between 0xA000 and 0xBFFF in banked ram.
 * @return bram_ptr_t
 *  - 0x0000: Something is wrong! Kernal Error Code (https://commodore.ca/manuals/pdfs/commodore_error_messages.pdf)
 *  - other: OK! The last pointer between 0xA000 and 0xBFFF is returned. Note that the last pointer is indicating the first free byte.
 */
unsigned int file_load_bram(char channel, char device, char secondary, char* filename, bram_bank_t dbank, bram_ptr_t dptr) 
{

    bram_bank_t bank = bank_get_bram();
    bank_set_bram(dbank);

    unsigned int read = 0;
    unsigned char status = file_open(channel, device, secondary, filename);
    if (!status) {
        read = file_load_size(channel, device, secondary, dptr, 0);
        if (read)
            status = file_close(channel);
    }

    bank_set_bram(bank);

    return read;
}
