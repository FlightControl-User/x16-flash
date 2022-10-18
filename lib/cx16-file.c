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
#include <cx16-file.h>

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
FILE* fopen(char channel, char device, char secondary, char* filename)
{
    FILE* fp = &__files[__filecount];
    fp->status = 0; 
    fp->channel = channel;
    fp->device = device;
    fp->secondary = secondary;
    strncpy(fp->filename, filename, 16);

    #ifdef __DEBUG_FILE
        printf("open file, c=%u, d=%u, s=%u, f=%s", channel, device, secondary, filename);
    #endif

    cbm_k_setnam(filename);
    cbm_k_setlfs(channel, device, secondary);

    fp->status = cbm_k_open();

    #ifdef __DEBUG_FILE
        printf(", open status=%u", fp->status);
    #endif

    if(fp->status) return NULL;

    cbm_k_chkin(channel);
    fp->status = cbm_k_readst();

    if(fp->status) return NULL;

    #ifdef __DEBUG_FILE
        printf(", chkin status=%u\n", fp->status);
    #endif

    #ifdef __DEBUG_FILE
        // cbm_k_chkin(0);
        // while(!getin());
    #endif

    __filecount++;

    return fp;
}


/**
 * @brief Load a file to ram or (banked ram located between address 0xA000 and 0xBFFF), incrementing the banks.
 * This function uses the new CX16 macptr kernal API at address $FF44.
 *
 * @param sptr The pointer between 0xA000 and 0xBFFF in banked ram.
 * @param size The amount of bytes to be read.
 * @param filename Name of the file to be loaded.
 * @return ptr the pointer advanced to the point where the stream ends.
 */
unsigned int fgets(char* ptr, unsigned int size, FILE* fp)
{
    #ifdef __DEBUG_FILE
        printf("load file, c=%u, d=%u, s=%u, b=%x, p=%p, si=%u", fp->channel, fp->device, fp->secondary, bank_get_bram(), ptr, size);
    #endif

    unsigned int read = 0;
    unsigned int remaining = size;

    cbm_k_chkin(fp->channel);
    fp->status = cbm_k_readst();
    #ifdef __DEBUG_FILE
        printf(", chkin status=%u", fp->status);
    #endif
    if(fp->status) return 0;

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

        fp->status = cbm_k_readst();
        #ifdef __DEBUG_FILE
        printf(", macptr status=%u", fp->status);
        #endif
        if(fp->status & 0xBF) {
            #ifdef __DEBUG_FILE
            printf("macptr error status=%u", status);
            #endif
            return 0;
        }

        if(bytes == 0xFFFF) {
            // #ifdef __DEBUG_FILE
            printf("read error in file %s, status=%u", fp->filename, fp->status);
            // #endif
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


    } while ((fp->status == 0) && ((size && remaining) || !size));

    #ifdef __DEBUG_FILE
        printf(", read bytes r=%u, status=%u\n", read, fp->status);
    #endif

    cbm_k_chkin(0);

    #ifdef __DEBUG_FILE
        while(!getin());
    #endif

    return read;
}

/**
 * @brief Close a file.
 *
 * @param fp The FILE pointer.
 * @return 
 *  - 0x0000: Something is wrong! Kernal Error Code (https://commodore.ca/manuals/pdfs/commodore_error_messages.pdf)
 *  - other: OK! The last pointer between 0xA000 and 0xBFFF is returned. Note that the last pointer is indicating the first free byte.
 */
int fclose(FILE* fp) 
{
    #ifdef __DEBUG_FILE
        printf("close file, c=%u", fp->channel);
    #endif

    fp->status = cbm_k_close(fp->channel);
    if(fp->status) return -1;


    cbm_k_clrchn();

    #ifdef __DEBUG_FILE
        printf(", status=%u\n", fp->status);
    #endif

    #ifdef __DEBUG_FILE
        // cbm_k_chkin(0);
        // while(!getin());
    #endif

    __filecount--;

    return 0;
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
unsigned int fload_bram(char channel, char device, char secondary, char* filename, bram_bank_t dbank, bram_ptr_t dptr) 
{

    bram_bank_t bank = bank_get_bram();
    bank_set_bram(dbank);

    unsigned int read = 0;
    FILE* fp = fopen(channel, device, secondary, filename);
    if(fp) {
        read = fgets(dptr, 0, fp);
        if(read) {
            fclose(fp);
        } else {
            fclose(fp);
            read = 0;
        }
    }

    bank_set_bram(bank);

    return read;
}
