/**
 * @mainpage cx16-rom-flash.c
 * @author Sven Van de Velde (https://www.commanderx16.com/forum/index.php?/profile/1249-svenvandevelde/)
 * @author Wavicle from CX16 forums (https://www.commanderx16.com/forum/index.php?/profile/1585-wavicle/)
 * @brief COMMANDER X16 ROM FLASH UTILITY
 *
 * Please find below some technical details how this flash ROM utility works, for those who are interested.
 *
 * This flash utility can be used to flash a new ROM.BIN into ROM banks of the COMMANDER X16.
 * ROM upgrades for the CX16 will come as ROM.BIN files, and will probably be downloadable from a dedicated location.
 * Because the ROM.BIN files are significantly large binaries, ROM flashing will only be possible from the SD card.
 * Therefore, this utility follows a simple and lean upload and flashing design, keeping it as simple as possible.
 * The utility program is to be placed onto a folder on the SD card, together with the ROM.BIN file.
 * The user can then simply load the program and run it from the SD card folder to flash the ROM.
 *
 *
 * The main principles of ROM flashing is to **unlock the ROM** for flashing following pre-defined read/write sequences
 * defined by the manufacturer of the chip. Once these sequences have been correctly initiated, a byte can be written
 * at a specified ROM address. And this is where it got tricky and interesting concerning the COMMANDER X16
 * address bus and architecture, to develop a COMMANDER X16 program that allows the flashing onto the hardware itself.
 *
 *
 * # ROM Adressing
 *
 * The addressing of the ROM chips follow 22 bit wide addressing mode, and is implemented on the CX16 in a special way.
 * The CX16 has 32 banks ROM of 16KB each, so it implements a banking solution to address the 22 bit wide ROM address,
 * where the most significant 8 bits of the 22 bit wide ROM address are configured through zero page $01,
 * configuring one of the 32 ROM banks,
 * while the CX16 main address bus is used to addresses the remaining 14 bits of the 22 bit ROM address.
 *
 * This results in the following architecture, where this flashing program uses a combination of setting the ROM bank
 * and using the main address bus to select the 22 bit wide ROM addresses.
 *
 *
 *                                   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 *                                   | 2 | 2 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
 *                                   | 1 | 0 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
 *                                   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 *                                   | BANK (ZP $01)     | MAIN ADDRESS BUS (+ $C000)                                        |
 *                                   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 *      ROM_BANK_MASK  0x3FC000      | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
 *                                   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 *      ROM_PTR_MASK   0x003FFF      | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
 *                                   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 *
 * Designing this program, there was also one important caveat to keep in mind ... What does the 6502 CPU see?
 * The CPU uses zero page $01 to set the ROM banks, but the lower 14 bits of the 22 bit wide ROM address is visible for the CPU
 * starting at address $C000 and ending at $FFFF (16KB), as the CPU uses a 16 bit address bus!
 * So the lower 14 bits of the ROM address requires the addition of $C000 to reach the correct memory in the ROM by the CPU!
 *
 * # Flashing the ROM
 *
 * ROM flashing is done by executing specific write sequences at specific addresses into the ROM, with specific bytes.
 * Depending on the write sequence, a specific ROM flashing functions are selected.
 *
 * This utility uses the following ROM flashing sequences (there are more available):
 *
 *   - Reading the ROM manufacturer and device ID information.
 *   - Clearing a ROM sector (filling with FF). Each ROM sector is 1KB wide.
 *   - Flashing the cleared ROM sector with new ROM bytes.
 *
 * That's it, simple and easy, but there is more to it than this ...
 *
 * # ROM flashing approach
 *
 * The ROM flashing requires a specific approach, as you need to keep in mind that while flashing ROM, there is **no ROM available**!
 * This utility flashes the ROM in four steps:
 *
 *   1. Read the complete ROM.BIN file from the SD card into (banked) RAM.
 *   2. Flash the ROM from (banked) RAM.
 *   3. Verify that the ROM has been correctly flashed (still TODO).
 *   4. Reset and reboot the COMMANDER X16 using the new ROM state.
 *
 * During and after ROM flash (from step 2), there cannot be any user interaction anymore and all interrupts must be disabled!
 * The screen writing that you see during flashing is executed directly from the program into the VERA, as no ROM screen IO functions can be used anymore.
 *
 *
 * @version 1.1
 * @date 2023-02-27
 *
 * @copyright Copyright (c) 2023
 *
 */

// Comment this pre-processor directive to disable ROM flashing routines (for emulator development purposes).
// #define __FLASH

// Ensures the proper character set is used for the COMMANDER X16.
#pragma encoding(petscii_mixed)

// Main includes.
#include <6502.h>
#include <conio.h>
#include <cx16-file.h>
#include <cx16.h>
#include <kernal.h>
#include <printf.h>
#include <sprintf.h>

// Uses all parameters to be passed using zero pages (fast).
#pragma var_model(zp)

// Some addressing constants.
#define ROM_BASE ((unsigned int)0xC000)
#define ROM_SIZE ((unsigned int)0x4000)
#define ROM_PTR_MASK ((unsigned long)0x003FFF)
#define ROM_BANK_MASK ((unsigned long)0x3FC000)
#define ROM_SECTOR ((unsigned int)0x1000)


// The different device IDs that can be returned from the manufacturer ID read sequence.
#define SST39SF010A ((unsigned char)0xB5)
#define SST39SF020A ((unsigned char)0xB6)
#define SST39SF040 ((unsigned char)0xB7)
#define UNKNOWN ((unsigned char)0x55)

// To print the graphics on the vera.
#define VERA_CHR_SPACE 0x20
#define VERA_CHR_UL 0x7E
#define VERA_CHR_UR 0x7C
#define VERA_CHR_BL 0x7B
#define VERA_CHR_BR 0x6C
#define VERA_CHR_HL 0x62
#define VERA_CHR_VL 0x61

#define VERA_REV_SPACE 0xA0
#define VERA_REV_UL 0xFE
#define VERA_REV_UR 0xFC
#define VERA_REV_BL 0xFB
#define VERA_REV_BR 0xEC
#define VERA_REV_HL 0xE2
#define VERA_REV_VL 0xE1

unsigned char wait_key() {

    unsigned ch = 0;
    bank_set_bram(0);
    bank_set_brom(4);

    while (!(ch = getin()))
        ;

    return ch;
}

void system_reset() {

    bank_set_bram(0);
    bank_set_brom(0);

    asm {
        jmp ($FFFC)
    }
}

void print_chip_line(char x, char y, char c) {

    gotoxy(x, y);

    textcolor(GREY);
    bgcolor(BLUE);
    cputc(VERA_CHR_UR);

    textcolor(WHITE);
    bgcolor(BLACK);
    cputc(VERA_CHR_SPACE);
    cputc(c);
    cputc(VERA_CHR_SPACE);

    textcolor(GREY);
    bgcolor(BLUE);
    cputc(VERA_CHR_UL);
}

void print_chip_end(char x, char y) {

    gotoxy(x, y);

    textcolor(GREY);
    bgcolor(BLUE);
    cputc(VERA_CHR_UR);

    textcolor(BLUE);
    bgcolor(BLACK);
    cputc(VERA_CHR_HL);
    cputc(VERA_CHR_HL);
    cputc(VERA_CHR_HL);

    textcolor(GREY);
    bgcolor(BLUE);
    cputc(VERA_CHR_UL);
}

void print_chip_led(char r, char tc, char bc) {

    gotoxy(4 + r * 10, 43);

    textcolor(tc);
    bgcolor(bc);
    cputc(VERA_REV_SPACE);
    cputc(VERA_REV_SPACE);
    cputc(VERA_REV_SPACE);
}

/**
 * @brief Calculates the 22 bit ROM size from the 8 bit ROM banks.
 * The ROM size is calcuated by taking the 8 bits and shifing those 14 bits to the left (bit 21-14).
 *
 * @param rom_bank The 8 bit ROM banks.
 * @return unsigned long The resulting 22 bit ROM address.
 */
unsigned long rom_size(unsigned char rom_banks) { return ((unsigned long)(rom_banks)) << 14; }

/**
 * @brief Calculates the 22 bit ROM address from the 8 bit ROM bank.
 * The ROM bank number is calcuated by taking the 8 bits and shifing those 14 bits to the left (bit 21-14).
 *
 * @param rom_bank The 8 bit ROM address.
 * @return unsigned long The 22 bit ROM address.
 */
unsigned long rom_address(unsigned char rom_bank) { return ((unsigned long)(rom_bank)) << 14; }

/**
 * @brief Calculates the 8 bit ROM bank from the 22 bit ROM address.
 * The ROM bank number is calcuated by taking the upper 8 bits (bit 18-14) and shifing those 14 bits to the right.
 *
 * @param address The 22 bit ROM address.
 * @return unsigned char The ROM bank number for usage in ZP $01.
 */
unsigned char rom_bank(unsigned long address) { return (char)((unsigned long)(address & ROM_BANK_MASK) >> 14); }

/**
 * @brief Calcuates the 16 bit ROM pointer from the ROM using the 22 bit address.
 * The 16 bit ROM pointer is calculated by masking the lower 14 bits (bit 13-0), and then adding $C000 to it.
 * The 16 bit ROM pointer is returned as a char* (brom_ptr_t).
 * @param address The 22 bit ROM address.
 * @return brom_ptr_t The 16 bit ROM pointer for the main CPU addressing.
 */
brom_ptr_t rom_ptr(unsigned long address) { return (brom_ptr_t)((unsigned int)(address & ROM_PTR_MASK) + ROM_BASE); }

/**
 * @brief Read a byte from the ROM using the 22 bit address.
 * The lower 14 bits of the 22 bit ROM address are transformed into the **ptr_rom** 16 bit ROM address.
 * The higher 8 bits of the 22 bit ROM address are transformed into the **bank_rom** 8 bit bank number.
 * **bank_ptr* is used to set the bank using ZP $01.  **ptr_rom** is used to read the byte.
 *
 * @param address The 22 bit ROM address.
 * @return unsigned char The byte read from the ROM.
 */
unsigned char rom_read_byte(unsigned long address) {
    brom_bank_t bank_rom = rom_bank((unsigned long)address);
    brom_ptr_t ptr_rom = rom_ptr((unsigned long)address);

    bank_set_brom(bank_rom);
    return *ptr_rom;
}

/**
 * @brief Write a byte to the ROM using the 22 bit address.
 * The lower 14 bits of the 22 bit ROM address are transformed into the **ptr_rom** 16 bit ROM address.
 * The higher 8 bits of the 22 bit ROM address are transformed into the **bank_rom** 8 bit bank number.
 * **bank_ptr* is used to set the bank using ZP $01.  **ptr_rom** is used to write the byte into the ROM.
 *
 * @param address The 22 bit ROM address.
 * @param value The byte value to be written.
 */
void rom_write_byte(unsigned long address, unsigned char value) {
    brom_bank_t bank_rom = rom_bank((unsigned long)address);
    brom_ptr_t ptr_rom = rom_ptr((unsigned long)address);

    bank_set_brom(bank_rom);
    *ptr_rom = value;
}

/**
 * @brief Verify a byte with the flashed ROM using the 22 bit rom address.
 * The lower 14 bits of the 22 bit ROM address are transformed into the **ptr_rom** 16 bit ROM address.
 * The higher 8 bits of the 22 bit ROM address are transformed into the **bank_rom** 8 bit bank number.
 * **bank_ptr* is used to set the bank using ZP $01.  **ptr_rom** is used to write the byte into the ROM.
 *
 * @param address The 22 bit ROM address.
 * @param value The byte value to be written.
 */
unsigned char rom_byte_verify(unsigned long address, unsigned char value) {
    brom_bank_t bank_rom = rom_bank((unsigned long)address);
    brom_ptr_t ptr_rom = rom_ptr((unsigned long)address);

    bank_set_brom(bank_rom);

    unsigned char verified = 1;
    if (*ptr_rom != value) {
        verified = 0;
    }
    return verified;
}

/**
 * @brief Wait for the required time to allow the chip to flash the byte into the ROM.
 * This is a core wait routine which is the most important routine in this whole program.
 * Once a byte is flashed into the ROM, it takes time for the chip to actually flash the byte.
 * The chip has implemented a loop mechanism to guarantee correct flashing of the written byte.
 * It does this by requiring the execution of two sequential reads from the previously written ROM address.
 * And loop those sequential reads until bit 6 of the 2 read bytes are equal.
 * Once those two bits are equal, the chip has successfully flashed the byte into the ROM.
 *
 *
 * @param ptr_rom The 16 bit pointer where the byte was written. This pointer is used for the sequence reads to verify bit 6.
 */
void rom_wait(brom_ptr_t ptr_rom) {
    unsigned char test1;
    unsigned char test2;

    do {
        test1 = *((brom_ptr_t)ptr_rom);
        test2 = *((brom_ptr_t)ptr_rom);
    } while ((test1 & 0x40) != (test2 & 0x40));
}

/**
 * @brief Unlock a byte location for flashing using the 22 bit address.
 * This is a various purpose routine to unlock the ROM for flashing a byte.
 * The 3rd byte can be variable, depending on the write sequence used, so this byte is a parameter into the routine.
 *
 * @param address The 3rd write to model the specific unlock sequence.
 * @param unlock_code The 3rd write to model the specific unlock sequence.
 */
void rom_unlock(unsigned long address, unsigned char unlock_code) {
    rom_write_byte(0x05555, 0xAA);
    rom_write_byte(0x02AAA, 0x55);
    rom_write_byte(address, unlock_code);
}

/**
 * @brief Write a byte and wait until the byte has been successfully flashed into the ROM.
 *
 * @param address The 22 bit ROM address.
 * @param value The byte value to be written.
 */
void rom_byte_program(unsigned long address, unsigned char value) {
    brom_ptr_t ptr_rom = rom_ptr((unsigned long)address);


    rom_write_byte(address, value);
    rom_wait(ptr_rom);
}

/**
 * @brief Erases a 1KB sector of the ROM using the 22 bit address.
 * This is required before any new bytes can be flashed into the ROM.
 * Erasing a sector of the ROM requires an erase sector sequence to be initiated, which has the following steps:
 *
 *   1. Write byte $AA into ROM address $005555.
 *   2. Write byte $55 into ROM address $002AAA.
 *   3. Write byte $80 into ROM address $005555.
 *   4. Write byte $AA into ROM address $005555.
 *   5. Write byte $55 into ROM address $002AAA.
 *
 * Once this write sequence is finished, the ROM sector is erased by writing byte $30 into the 22 bit ROM sector address.
 * Then it waits until the chip has correctly flashed the ROM erasure.
 *
 * Note that a ROM sector is 1KB (not 4KB), so the most 7 significant bits (18-12) are used.
 * The remainder 12 low bits are ignored.
 *
 *                                   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 *                                   | 2 | 2 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
 *                                   | 1 | 0 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
 *                                   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 *      SECTOR          0x37F000     | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
 *                                   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 *      IGNORED         0x000FFF     | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
 *                                   +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 *
 * @param address The 22 bit ROM address.
 */
void rom_sector_erase(unsigned long address) {
    brom_ptr_t ptr_rom = rom_ptr((unsigned long)address);

#ifdef __FLASH
    rom_unlock(0x05555, 0x80);
    rom_unlock(address, 0x30);

    rom_wait(ptr_rom);
#endif
}

unsigned long flash_read(FILE *fp, ram_ptr_t flash_ram_address, unsigned char rom_bank_start, unsigned char rom_bank_size) {

    unsigned long flash_rom_address = rom_address(rom_bank_start);
    unsigned long flash_size = rom_size(rom_bank_size);
    unsigned long flash_bytes = 0; /// Holds the amount of bytes actually read in the memory to be flashed.

    textcolor(WHITE);

    while (flash_bytes < flash_size) {

        if (!(flash_rom_address % 0x04000)) {
            gotoxy(14, 4 + (rom_bank_start % 32));
            rom_bank_start++;
        }

        unsigned int read_bytes = fgets(flash_ram_address, 128, fp); // this will load 128 bytes from the rom.bin file or less if EOF is reached.
        if (!read_bytes) {
            return flash_bytes;
            // TODO return; results in an incomplete error message in the compiler.
        }

        if (!(flash_rom_address % 0x100))
            // cputc(0xE0);
            cputc('.');

        flash_ram_address += read_bytes;
        flash_rom_address += read_bytes;
        flash_bytes += read_bytes;

        if (flash_ram_address >= 0xC000) {
            flash_ram_address = flash_ram_address - 0x2000;
        }
    }

    return flash_bytes;
}

unsigned long flash_write(unsigned char flash_ram_bank, ram_ptr_t flash_ram_address, unsigned long flash_rom_address) {

    unsigned long flashed_bytes = 0; /// Holds the amount of bytes actually flashed in the ROM.

    bank_set_bram(flash_ram_bank);
    while (flashed_bytes < 0x0100) {
#ifdef __FLASH
        rom_unlock(0x05555, 0xA0);
        rom_byte_program(flash_rom_address, *flash_ram_address);
#endif
        flash_rom_address++;
        flash_ram_address++;
        flashed_bytes++;
    }

    return flashed_bytes;
}

unsigned long flash_verify(bram_bank_t verify_ram_bank, ram_ptr_t verify_ram_address, unsigned long verify_rom_address, unsigned long verify_rom_size) {

    unsigned long verified_bytes = 0; /// Holds the amount of bytes actually verified between the ROM and the RAM.
    unsigned long correct_bytes = 0;  /// Holds the amount of correct and verified bytes flashed in the ROM.

    bank_set_bram(verify_ram_bank);
    while (verified_bytes < verify_rom_size) {

        if (rom_byte_verify(verify_rom_address, *verify_ram_address)) {
            correct_bytes++;
        }
        verify_rom_address++;
        verify_ram_address++;
        verified_bytes++;
    }

    return correct_bytes;
}

void frame_draw() {

    textcolor(WHITE);
    bgcolor(BLUE);

    clrscr();
    unsigned char y = 0;
    for (unsigned char x = 0; x < 79; x++) {
        cputcxy(x, y, 0x40);
    }
    cputcxy(0, y, 0x70);
    cputcxy(79, y, 0x6E);

    y++;
    cputcxy(0, y, 0x5d);
    cputcxy(79, y, 0x5d);

    y++;
    for (unsigned char x = 0; x < 79; x++) {
        cputcxy(x, y, 0x40);
    }
    cputcxy(0, y, 0x6B);
    cputcxy(79, y, 0x73);
    cputcxy(12, y, 0x72);

    y++;
    for (; y < 37; y++) {
        cputcxy(0, y, 0x5D);
        cputcxy(12, y, 0x5D);
        cputcxy(79, y, 0x5D);
    }

    for (unsigned char x = 0; x < 79; x++) {
        cputcxy(x, y, 0x40);
    }
    cputcxy(0, y, 0x6B);
    cputcxy(79, y, 0x73);
    cputcxy(12, y, 0x71);

    y++;
    for (; y < 41; y++) {
        cputcxy(0, y, 0x5D);
        cputcxy(79, y, 0x5D);
    }

    for (unsigned char x = 0; x < 79; x++) {
        cputcxy(x, y, 0x40);
    }
    cputcxy(0, y, 0x6B);
    cputcxy(79, y, 0x73);
    cputcxy(10, y, 0x72);
    cputcxy(20, y, 0x72);
    cputcxy(30, y, 0x72);
    cputcxy(40, y, 0x72);
    cputcxy(50, y, 0x72);
    cputcxy(60, y, 0x72);
    cputcxy(70, y, 0x72);
    cputcxy(79, y, 0x73);

    y++;
    for (; y < 55; y++) {
        cputcxy(0, y, 0x5D);
        cputcxy(79, y, 0x5D);
        cputcxy(10, y, 0x5D);
        cputcxy(20, y, 0x5D);
        cputcxy(30, y, 0x5D);
        cputcxy(40, y, 0x5D);
        cputcxy(50, y, 0x5D);
        cputcxy(60, y, 0x5D);
        cputcxy(70, y, 0x5D);
    }

    for (unsigned char x = 0; x < 79; x++) {
        cputcxy(x, y, 0x40);
    }
    cputcxy(0, y, 0x6B);
    cputcxy(79, y, 0x73);
    cputcxy(10, y, 0x5B);
    cputcxy(20, y, 0x5B);
    cputcxy(30, y, 0x5B);
    cputcxy(40, y, 0x5B);
    cputcxy(50, y, 0x5B);
    cputcxy(60, y, 0x5B);
    cputcxy(70, y, 0x5B);

    y++;
    for (; y < 59; y++) {
        cputcxy(0, y, 0x5D);
        cputcxy(79, y, 0x5D);
        cputcxy(10, y, 0x5D);
        cputcxy(20, y, 0x5D);
        cputcxy(30, y, 0x5D);
        cputcxy(40, y, 0x5D);
        cputcxy(50, y, 0x5D);
        cputcxy(60, y, 0x5D);
        cputcxy(70, y, 0x5D);
    }

    for (unsigned char x = 0; x < 79; x++) {
        cputcxy(x, y, 0x40);
    }
    cputcxy(0, y, 0x6D);
    cputcxy(79, y, 0x7D);
    cputcxy(10, y, 0x71);
    cputcxy(20, y, 0x71);
    cputcxy(30, y, 0x71);
    cputcxy(40, y, 0x71);
    cputcxy(50, y, 0x71);
    cputcxy(60, y, 0x71);
    cputcxy(70, y, 0x71);
    cputcxy(79, y, 0x7D);
}

void table_chip_clear(unsigned char rom_bank) {

    textcolor(WHITE);
    bgcolor(BLUE);

    for (unsigned char y = 4; y < 36; y++) {

        unsigned long flash_rom_address = rom_address(rom_bank);

        gotoxy(2, y);
        printf("%02x", rom_bank);

        gotoxy(5, y);
        printf("%06x", flash_rom_address);

        gotoxy(14, y);
        printf("%64s", " ");

        rom_bank++;
    }
}

void print_text(char *text) {

    textcolor(WHITE);
    gotoxy(2, 39);
    printf("%-76s", text);
}

void main() {

    unsigned int bytes = 0;
    char buffer[160] = "";

    SEI();

    // Set the charset to lower case.
    cbm_x_charset(3, (char *)0);

    textcolor(WHITE);
    bgcolor(BLUE);
    scroll(0);
    clrscr();

    frame_draw();

    gotoxy(33, 1);
    printf("rom flash utility");

    for (unsigned char r = 0; r < 8; r++) {
        print_chip_line(3 + r * 10, 45, ' ');
        print_chip_line(3 + r * 10, 46, 'r');
        print_chip_line(3 + r * 10, 47, 'o');
        print_chip_line(3 + r * 10, 48, 'm');
        print_chip_line(3 + r * 10, 49, '0' + r);
        print_chip_line(3 + r * 10, 50, ' ');
        print_chip_line(3 + r * 10, 51, '5');
        print_chip_line(3 + r * 10, 52, '1');
        print_chip_line(3 + r * 10, 53, '2');
        print_chip_end(3 + r * 10, 54);

        print_chip_led(r, BLACK, BLUE);
    }

    unsigned char rom_error = 0;
    unsigned char rom_chip = 0;
    unsigned char rom_device_ids[8] = {0};
    unsigned char rom_manufacturer_ids[8] = {0};
    for (unsigned long flash_rom_address = 0; flash_rom_address < 8 * 0x80000; flash_rom_address += 0x80000) {

        rom_manufacturer_ids[rom_chip] = 0;
        rom_device_ids[rom_chip] = 0;

#ifdef __FLASH
        rom_unlock(0x05555, 0x90);
        rom_manufacturer_ids[rom_chip] = rom_read_byte(flash_rom_address);
        rom_device_ids[rom_chip] = rom_read_byte(flash_rom_address + 1);
        rom_unlock(0x05555, 0xF0);
#else
        // Simulate that there is one chip onboard and 2 chips on the isa card.
        if (flash_rom_address <= 0x100000) {
            rom_unlock(0x05555, 0x90);
            rom_manufacturer_ids[rom_chip] = 0x9f;
            rom_device_ids[rom_chip] = SST39SF040;
            rom_unlock(0x05555, 0xF0);
        }
#endif

        // Ensure the ROM is set to BASIC.
        bank_set_brom(4);

        char *rom_device = NULL;
        switch (rom_device_ids[rom_chip]) {
        case SST39SF010A:
            rom_device = "f010a";
            print_chip_led(rom_chip, WHITE, BLUE);
            break;
        case SST39SF020A:
            rom_device = "f020a";
            print_chip_led(rom_chip, WHITE, BLUE);
            break;
        case SST39SF040:
            rom_device = "f040";
            print_chip_led(rom_chip, WHITE, BLUE);
            break;
        default:
            rom_device = "----";
            print_chip_led(rom_chip, BLACK, BLUE);
            rom_device_ids[rom_chip] = UNKNOWN;
            break;
        }

        textcolor(WHITE);
        gotoxy(2 + rom_chip * 10, 56);
        printf("%x", rom_manufacturer_ids[rom_chip]);
        gotoxy(2 + rom_chip * 10, 57);
        printf("%s", rom_device);

        rom_chip++;
    }

    // gotoxy(0, 40);

    // if (rom_error) {
    //     printf("there is an unknown rom chip device in your system. cannot proceed with the upgrade process ...\n");
    //     printf("press any key for further instructions ...");
    //     wait_key();
    //     system_reset();
    // }

    CLI();

    // printf("\nsearching for a specific romnnn.bin to flash ROM banks between 32 and 255.");
    // printf("\nif such a rom[n].bin file is found, a confirmation will be required before flashing the rom.");
    // printf("\nafter confirmation, the romnnn.bin file is first read into ram at address 0x4000.");
    // printf("\nonce the romnnn.bin file is flashed, the new flashed rom is verified against the file contents.");
    // printf("\nin case of a flash or verify error, the flash program will abort.");

    // printf("press any key to start flashing ...\n");
    wait_key();

    for (unsigned char flash_chip = 7; flash_chip != 255; flash_chip--) {

        if (rom_device_ids[flash_chip] != UNKNOWN) {

            gotoxy(0, 2);
            bank_set_bram(1);
            bank_set_brom(4);

            char file[16] = "";
            if (flash_chip == 0) {
                sprintf(file, "rom.bin", flash_chip);
            } else {
                sprintf(file, "rom%u.bin", flash_chip);
            }

            unsigned char flash_rom_bank = flash_chip * 32;

            // Read the file content.
            FILE *fp = fopen(1, 8, 2, file);
            if (fp) {

                table_chip_clear(flash_chip * 32);

                textcolor(WHITE);
                gotoxy(2 + flash_chip * 10, 58);
                printf("%s", file);

                print_chip_led(flash_chip, CYAN, BLUE);

                sprintf(buffer, "reading in ram ...");
                print_text(buffer);

                unsigned long flash_rom_address_boundary = rom_address(flash_rom_bank);
                unsigned long flash_bytes = flash_read(fp, (ram_ptr_t)0x4000, flash_rom_bank, 1);
                if (flash_bytes != rom_size(1)) {
                    return;
                }
                flash_rom_address_boundary += flash_bytes;

                bank_set_bram(1); // read from bank 1 in bram.
                flash_bytes = flash_read(fp, (ram_ptr_t)0xA000, flash_rom_bank + 1, 31);
                flash_rom_address_boundary += flash_bytes;

                fclose(fp);

                bank_set_bram(1);
                bank_set_brom(4);

                // OK, so the flash file has been loaded into the 512 KBC memory.
                // We now reflash the rom banks.
                SEI();

                unsigned long flash_rom_address_sector = rom_address(flash_rom_bank);
                ram_ptr_t read_ram_address_sector = (ram_ptr_t)0x4000;
                bram_bank_t read_ram_bank_sector = 1;

                char *pattern;

                textcolor(WHITE);

                unsigned char x_sector = 14;
                unsigned char y_sector = 4;

                print_chip_led(flash_chip, PURPLE, BLUE);
                sprintf(buffer, "flashing in rom from ram ... (-) unchanged, (+) flashed, (!) error.");
                print_text(buffer);

                unsigned int flash_errors_sector = 0;

                while (flash_rom_address_sector < flash_rom_address_boundary) {

                    unsigned long equal_bytes = flash_verify(read_ram_bank_sector, (ram_ptr_t)read_ram_address_sector, flash_rom_address_sector, ROM_SECTOR);
                    if (equal_bytes != ROM_SECTOR) {

                        unsigned char flash_errors = 0;
                        unsigned char retries = 0;
                        
                        do {
                        
                            rom_sector_erase(flash_rom_address_sector);

                            unsigned long flash_rom_address_boundary = flash_rom_address_sector + ROM_SECTOR;
                            unsigned long flash_rom_address = flash_rom_address_sector;
                            ram_ptr_t read_ram_address = (ram_ptr_t)read_ram_address_sector;
                            bram_bank_t read_ram_bank = read_ram_bank_sector;
                            
                            unsigned char x = x_sector;
                            unsigned char y = y_sector;
                            gotoxy(x, y);
                            printf("................");

                            while(flash_rom_address < flash_rom_address_boundary) {

                                gotoxy(0,0);
                                printf("ram = %2x, %4p, rom = %6x ", read_ram_bank_sector, read_ram_address, flash_rom_address);

                                unsigned long written_bytes = flash_write(read_ram_bank_sector, (ram_ptr_t)read_ram_address, flash_rom_address);

                                equal_bytes = flash_verify(read_ram_bank_sector, (ram_ptr_t)read_ram_address, flash_rom_address, 0x0100);

                                if (equal_bytes != ROM_SECTOR) {
                                    pattern = "!";
                                    flash_errors++;
                                } else {
                                    pattern = "+";
                                }
                                read_ram_address += 0x0100;
                                flash_rom_address += 0x0100;

                                textcolor(WHITE);
                                gotoxy(x, y);
                                printf("%s", pattern);
                                x++; // This should never exceed the 64 char boundary.
                            }

                            retries++;       

                        } while(flash_errors && retries <= 3);      

                        flash_errors_sector += flash_errors;
                    
                    } else {
                        pattern = "----------------";

                        textcolor(WHITE);
                        gotoxy(x_sector, y_sector);
                        printf("%s", pattern);
                    }

                    read_ram_address_sector += ROM_SECTOR;
                    flash_rom_address_sector += ROM_SECTOR;

                    if (read_ram_address_sector == 0x8000) {
                        read_ram_address_sector = (ram_ptr_t)0xA000;
                        read_ram_bank_sector = 1;
                    }

                    if (read_ram_address_sector == 0xC000) {
                        read_ram_address_sector = (ram_ptr_t)0xA000;
                        read_ram_bank_sector++;
                    }

                    x_sector += 16;
                    if (!(flash_rom_address_sector % 0x4000)) {
                        x_sector = 14;
                        y_sector++;
                    }
                }

                bank_set_bram(1);
                bank_set_brom(4);

                CLI();
                if (!flash_errors_sector) {
                    textcolor(GREEN);
                    sprintf(buffer, "the flashing went perfectly ok. press a key to flash the next chip ...", file);
                    print_text(buffer);
                    print_chip_led(flash_chip, GREEN, BLUE);
                } else {
                    textcolor(RED);
                    sprintf(buffer, "the flashing went wrong, %u errors. press a key to flash the next chip ...", flash_errors_sector);
                    print_text(buffer);
                    print_chip_led(flash_chip, RED, BLUE);
                }
            } else {
                textcolor(WHITE);
                gotoxy(2 + flash_chip * 10, 58);
                printf("no file");
                print_chip_led(flash_chip, DARK_GREY, BLUE);
            }
            wait_key();
        }
    }

    textcolor(WHITE);
    sprintf(buffer, "resetting commander x16" );
    print_text(buffer);
    for (unsigned int w = 0; w < 32; w++) {
        for (unsigned int v = 0; v < 256 * 128; v++) {
        }
        cputc('.');
    }

    system_reset();
}
