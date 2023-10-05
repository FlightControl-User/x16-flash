/**
 * @mainpage cx16-update.c
 * 
 * @author Wavicle -- Overall support and startup assistance for the chipset upgrade program.
 * @author Stefan Jakobsson -- Main SMC update logic, SMC firmware and bootloader.
 * @author Sven Van de Velde -- Creation of this program, under guidance of the SME of the people above.
 * 
 * @brief COMMANDER X16 FIRMWARE UPDATE UTILITY
 *
 * @version 2.0
 * @date 2023-09-21
 *
 * @copyright Copyright (c) 2023
 *
 */

// Ensures the proper character set is used for the COMMANDER X16.
#pragma encoding(screencode_mixed)

// Uses all parameters to be passed using zero pages (fast).
#pragma var_model(mem)


// Main includes.
#include <6502.h>
#include <cx16.h>
#include <cx16-conio.h>
#include <kernal.h>
#include <printf.h>
#include <sprintf.h>
#include <stdio.h>
#include "cx16-vera.h"
#include "cx16-veralib.h"

#pragma var_model(zp, global_integer_ssa_mem, local_integer_ssa_mem, parameter_integer_ssa_zp, local_pointer_ssa_mem)

#include "cx16-defines.h"
#include "cx16-globals.h"
#include "cx16-display.h"
#include "cx16-display-text.h"
#include "cx16-smc.h"
#include "cx16-rom.h"

inline unsigned char check_smc(unsigned char status) {
    return (unsigned char)(status_smc == status);
}


inline unsigned char check_vera(unsigned char status) {
    return (unsigned char)(status_vera == status);
}


inline unsigned char check_rom(unsigned char rom_chip, unsigned char status) {
    return (unsigned char)(status_rom[rom_chip] == status);
}

inline unsigned char check_cx16_rom(unsigned char status) {
    return check_rom(0, status);
}

inline unsigned char check_card_roms(unsigned char status) {
    for(unsigned char rom_chip = 1; rom_chip < 8; rom_chip++) {
        if(check_rom(rom_chip, status)) {
            return status;
        }        
    }
    return STATUS_NONE;
}

inline unsigned char check_roms(unsigned char status) {
    for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++) {
        if(check_rom(rom_chip, status) == status) {
            return status;
        }        
    }
    return STATUS_NONE;
}

inline unsigned char check_roms_all(unsigned char status) {
    for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++) {
        if(check_rom(rom_chip, status) != status) {
            return 0;
        }        
    }
    return 1;
}


void main() {

    unsigned int bytes = 0;

    bank_set_bram(0);
    bank_set_brom(0);

    // Get the current screen mode ...
    /**
    screen_mode = cx16_k_screen_get_mode();
    printf("Screen mode: %x, x:%x, y:%x", screen_mode.mode, screen_mode.x, screen_mode.y);
    if(cx16_k_screen_mode_is_40(&screen_mode)) {
        printf("Running in 40 columns\n");
        wait_key("Press a key ...", NULL);
    } else {
        if(cx16_k_screen_mode_is_80(&screen_mode)) {
            printf("Running in 40 columns\n");
            wait_key("Press a key ...", NULL);
        } else {
            printf("Screen mode now known ...\n");
            wait_key("Press a key ...", NULL);
        }
    }
    */

    cx16_k_screen_set_charset(3, (char *)0);

    display_frame_init_64();
    display_frame_draw();

    display_frame_title("Commander X16 Flash Utility!");
    display_info_title();

    display_progress_clear();

    // info_print(0, "The SMC chip on the X16 board controls the power on/off, keyboard and mouse pheripherals.");
    // info_print(1, "It is essential that the SMC chip gets updated together with the latest ROM on the X16 board.");
    // info_print(2, "On the X16 board, near the SMC chip are two jumpers");

    display_action_progress("Detecting SMC, VERA and ROM chipsets ...");


#ifdef __SMC_CHIP_PROCESS

    SEI();

    // Detect the SMC bootloader and turn the SMC chip led WHITE if there is a bootloader present.
    // Otherwise, stop flashing and exit after explaining next steps.
    smc_bootloader = smc_detect();

    display_chip_smc();

    if(smc_bootloader == 0x0100) {
        // TODO: explain next steps ...
        display_info_smc(STATUS_ERROR, "No Bootloader!");
    } else {
        if(smc_bootloader == 0x0200) {
            // TODO: explain next steps ...
            display_info_smc(STATUS_ERROR, "Unreachable!");
        } else {
            if(smc_bootloader > 0x2) {
                // TODO: explain next steps ...
                sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader);
                display_info_smc(STATUS_ERROR, info_text);
            } else {
                sprintf(info_text, "Bootloader v%02x", smc_bootloader);
                display_info_smc(STATUS_DETECTED, info_text);
            }
        }
    } 

    CLI();

#endif

    // Detecting VERA FPGA.
    display_chip_vera();
    display_info_vera(STATUS_DETECTED, "VERA installed, OK"); // Set the info for the VERA to Detected.

#ifdef __ROM_CHIP_PROCESS

    SEI();

    // Detecting ROM chips
    rom_detect();
    display_chip_rom();

    for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++) {
        if(rom_device_ids[rom_chip] != UNKNOWN) {
            display_info_rom(rom_chip, STATUS_DETECTED, ""); // Set the info for the ROMs to Detected.
        } else {
            display_info_rom(rom_chip, STATUS_NONE, ""); // Set the info for the ROMs to None.
        }
    }

    CLI();

#endif

#ifdef __INTRO

    display_progress_text(display_into_briefing_text, display_intro_briefing_count);
    util_wait_key("Please read carefully the below, and press [SPACE] ...", " ");
    display_progress_clear();

    display_progress_text(display_into_colors_text, display_intro_colors_count);
    for(unsigned char intro_status=0; intro_status<11; intro_status++) {
        display_info_led(PROGRESS_X + 3, PROGRESS_Y + 3 + intro_status, status_color[intro_status], BLUE);
    }
    util_wait_key("If understood, press [SPACE] to start the update ...", " ");
    display_progress_clear();

#endif

#ifdef __SMC_CHIP_PROCESS
#ifdef __SMC_CHIP_CHECK

    SEI();

    if(check_smc(STATUS_DETECTED)) {

        // Check the SMC.BIN file size!
        smc_file_size = smc_read(8, 512);

        // In case no file was found, set the status to error and skip to the next, else, mention the amount of bytes read.
        if (!smc_file_size) {
            display_info_smc(STATUS_ERROR, "No SMC.BIN!");
        } else {
            // If the smc.bin file size is larger than 0x1E00 then there is an error!
            if(smc_file_size > 0x1E00) {
                display_info_smc(STATUS_ERROR, "SMC.BIN too large!");
            } else {
                sprintf(info_text, "Bootloader v%02x", smc_bootloader);
                display_info_smc(STATUS_FLASH, info_text);
            }
        }
    }

    CLI();

#endif
#endif

#ifdef __ROM_CHIP_PROCESS
#ifdef __ROM_CHIP_CHECK

    SEI();

    // We loop all the possible ROM chip slots on the board and on the extension card,
    // and we check the file contents.
    // Any error identified gets reported and this chip will not be flashed.
    // In case of ROM0.BIN in error, no flashing will be done!
    for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++) {

        bank_set_brom(0);

        if(rom_device_ids[rom_chip] != UNKNOWN) {

            display_progress_clear();

            unsigned char rom_bank = rom_chip * 32;
            unsigned char* file = rom_file(rom_chip);
            sprintf(info_text, "Checking %s ... (.) data ( ) empty", file);
            display_action_progress(info_text);


            unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_CHECKING, rom_bank, rom_sizes[rom_chip]);

            // In case no file was found, set the status to none and skip to the next, else, mention the amount of bytes read.
            if (!rom_bytes_read) {
                sprintf(info_text, "No %s, skipped", file);
                display_info_rom(rom_chip, STATUS_NONE, info_text);
            } else {
                // If the rom size is not a factor or 0x4000 bytes, then there is an error.
                unsigned long rom_file_modulo = rom_bytes_read % 0x4000;
                if(rom_file_modulo) {
                    sprintf(info_text, "File %s size error!", file);
                    display_info_rom(rom_chip, STATUS_ERROR, info_text);
                } else {
                    
                    // We know the file size, so we indicate it in the status panel.
                    file_sizes[rom_chip] = rom_bytes_read;
                    
                    // Fill the version data ...
                    strncpy(rom_github[rom_chip], (char*)RAM_BASE, 6);
                    bank_push_set_bram(1);
                    rom_release[rom_chip] = *((char*)0xBF80);
                    bank_pull_bram();

                    sprintf(info_text, "%s:R%u/%s", file, rom_release[rom_chip], rom_github[rom_chip]);
                    display_info_rom(rom_chip, STATUS_FLASH, info_text);
                }
            }
        }
    }

#endif
#endif

    bank_set_brom(0);
    CLI();


    // If the SMC and CX16 ROM is ready to flash, ok, go ahead and flash.
    if(!check_smc(STATUS_FLASH) || !check_cx16_rom(STATUS_FLASH)) {
        display_info_smc(STATUS_ISSUE, NULL);
        display_info_cx16_rom(STATUS_ISSUE, NULL);
        display_action_progress("There is an issue with either the SMC or the CX16 main ROM!");
        util_wait_key("Press [SPACE] to continue [ ]", " ");
    }

    if(check_smc(STATUS_FLASH) && check_cx16_rom(STATUS_FLASH) || check_card_roms(STATUS_FLASH)) {
        display_action_progress("Chipsets have been detected and update files validated!");
        unsigned char ch = util_wait_key("Continue with update? [Y/N]", "nyNY");        
        if(strchr("nN", ch)) {
            // We cancel all updates, the updates are skipped.
            display_info_smc(STATUS_SKIP, "Cancelled");
            display_info_vera(STATUS_SKIP, "Cancelled");
            for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++) {
                display_info_rom(rom_chip, STATUS_SKIP, "Cancelled");
            }
            display_action_text("You have selected not to cancel the update ... ");
        }
    }

    SEI();

    // Flash the SMC when it has the status!
    if (check_smc(STATUS_FLASH)) {

#ifdef __SMC_CHIP_PROCESS
#ifdef __SMC_CHIP_FLASH

        // Read the SMC.BIN to flash the SMC chip.
        smc_file_size = smc_read(8, 512);
        if(smc_file_size) {
            // Flash the SMC chip.
            display_action_text("Press both POWER/RESET buttons on the CX16 board!");
            display_info_smc(STATUS_FLASHING, "Press POWER/RESET!");
            unsigned long flashed_bytes = flash_smc(PROGRESS_X, PROGRESS_Y, PROGRESS_W, smc_file_size, 8, 512, (ram_ptr_t)RAM_BASE);
            if(flashed_bytes)
                display_info_smc(STATUS_FLASHED, "");
            else
                display_info_smc(STATUS_ERROR, "SMC not updated!");
        }

#endif
#endif

    }

#ifdef __ROM_CHIP_PROCESS
#ifdef __ROM_CHIP_FLASH

    // Flash the ROM chips. 
    // We loop first all the ROM chips and read the file contents.
    // Then we verify the file contents and flash the ROM only for the differences.
    // If the file contents are the same as the ROM contents, then no flashing is required.
    // IMPORTANT! We start to flash the ROMs on the extension card.
    // The last ROM flashed is the CX16 ROM on the CX16 board!
    for(unsigned char rom_chip = 7; rom_chip != 255; rom_chip--) {

        if(check_rom(rom_chip, STATUS_FLASH)) {

            // IMPORTANT! We only flash the CX16 ROM chip if the SMC got flashed succesfully!
            if((rom_chip == 0 && check_smc(STATUS_FLASHED)) || (rom_chip != 0)) {

                bank_set_brom(0);

                display_progress_clear();

                unsigned char rom_bank = rom_chip * 32;
                unsigned char* file = rom_file(rom_chip);
                sprintf(info_text, "Reading %s ... (.) data ( ) empty", file);
                display_action_progress(info_text);

                unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_READING, rom_bank, rom_sizes[rom_chip]);

                // If the ROM file was correctly read, verify the file ...
                if(rom_bytes_read) {

                    // Now we compare the RAM with the actual ROM contents.
                    display_action_progress("Comparing ... (.) same, (*) different.");
                    display_info_rom(rom_chip, STATUS_COMPARING, "");

                    // Verify the ROM...
                    unsigned long rom_differences = rom_verify(
                        rom_chip, rom_bank, file_sizes[rom_chip]);
                    
                    if (!rom_differences) {
                        display_info_rom(rom_chip, STATUS_FLASHED, "No update required");
                    } else {
                        // If there are differences, the ROM needs to be flashed.
                        sprintf(info_text, "%05x differences!", rom_differences);
                        display_info_rom(rom_chip, STATUS_FLASH, info_text);
                        
                        unsigned long rom_flash_errors = rom_flash(
                            rom_chip, rom_bank, file_sizes[rom_chip]);
                        if(rom_flash_errors) {
                            sprintf(info_text, "%u flash errors!", rom_flash_errors);
                            display_info_rom(rom_chip, STATUS_ERROR, info_text);
                        } else {
                            display_info_rom(rom_chip, STATUS_FLASHED, "OK!");
                        }
                    }
                }
            } else {
                display_info_rom(rom_chip, STATUS_ISSUE, "Update SMC failed!");
            }
        }
    }

#endif
#endif


    bank_set_brom(4);
    CLI();

    display_progress_clear();

    display_action_progress("Update finished ...");

    if(check_smc(STATUS_SKIP) && check_vera(STATUS_SKIP) && check_roms_all(STATUS_SKIP)) {
        vera_display_set_border_color(BLACK);
        display_action_progress("The update has been cancelled!");
    } else {
        if(check_smc(STATUS_ERROR) || check_vera(STATUS_ERROR) || check_roms(STATUS_ERROR)) {
            vera_display_set_border_color(RED);
            display_action_progress("Update Failure! Your CX16 may be bricked!");
            display_action_text("Take a foto of this screen. And shut down power ...");
            while(1);
        } else {
            if(check_smc(STATUS_ISSUE) || check_vera(STATUS_ISSUE) || check_roms(STATUS_ISSUE)) {
                vera_display_set_border_color(YELLOW);
                display_action_progress("Update issues, your CX16 is not updated!");
            } else {
                vera_display_set_border_color(GREEN);
                if(check_smc(STATUS_FLASHED)) {
                    display_progress_text(display_debriefing_text_smc, display_debriefing_count_smc);

                    for (unsigned char w=128; w>0; w--) {
                        wait_moment();
                        sprintf(info_text, "Please read carefully the below (%u) ...", w);
                        display_action_text(info_text);
                    }

                    sprintf(info_text, "Please disconnect your CX16 from power source ...");
                    display_action_text(info_text);

                    smc_reset(); // This call will reboot the SMC, which will reset the CX16 if bootloader R2.

                } else {
                    display_progress_text(display_debriefing_text_rom, display_debriefing_count_rom);
                }
            }
        }
    }

    {

        for (unsigned char w=200; w>0; w--) {
            wait_moment();
            sprintf(info_text, "Your CX16 will reset (%03u) ...", w);
            display_action_text(info_text);
        }

        system_reset();
    }

    return;
}
