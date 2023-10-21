/**
 * @file cx16-w25q16.c
 * 
 * @author Wavicle from CX16 community (https://gist.github.com/jburks) -- Advice and outline of the ROM update logic & overall support and test assistance of this program.
 * @author MooingLemur from CX16 community (https://github.com/mooinglemur) -- Advice and outline of the main SPI and W25Q16 update logic, and supply of new VERA firmware.
 * @author Stefan Jakobsson from CX16 community (https://github.com/stefan-b-jakobsson) -- Advice and outline of the SMC update logic, SMC firmware and bootloader and creation of SMC firmware.
 * @author Sven Van de Velde from CX16 community (https://github.com/FlightControl-User) -- Creation of this program, under the strong expertise by the people above.
 * 
 * @brief COMMANDER X16 UPDATE TOOL MAIN LOGIC FLOW
 *
 * @version 3.0
 * @date 2023-10-15
 *
 * @copyright Copyright (c) 2023
 *
 */

// Ensures the proper character set is used for the COMMANDER X16.
#pragma encoding(screencode_mixed)

// Uses all parameters to be passed using zero pages (fast).
#pragma var_model(mem)

// Linkage
#pragma link("cx16-update.ld")


#include "cx16-defines.h"
#include "cx16-globals.h"

#pragma var_model(zp)

#include "cx16-init.h"
#include "cx16-status.h"
#include "cx16-utils.h"
#include "cx16-display.h"
#include "cx16-display-text.h"
#include "cx16-smc.h"
#include "cx16-rom.h"
#include "cx16-w25q16.h"

#pragma code_seg(CodeOverwrite)

void main_intro() {

    display_progress_text(display_into_briefing_text, display_intro_briefing_count);
    util_wait_space();

    display_progress_text(display_into_colors_text, display_intro_colors_count);
    for(unsigned char intro_status=0; intro_status<11; intro_status++) {
        display_info_led(PROGRESS_X + 3, PROGRESS_Y + 3 + intro_status, status_color[intro_status], BLUE);
    }
    util_wait_space();
    display_progress_clear();
}

#pragma code_seg(CodeOverwrite)
#pragma data_seg(DataOverwrite)

void main_vera_detect() {

    // VD1 | VERA chip was detected 

    *VERA_CTRL = 126;

    vera_release = *VERA_DC63_VER1;
    vera_major = *VERA_DC63_VER2;
    vera_minor = *VERA_DC63_VER3;
    util_version_text(vera_version_text, vera_release, vera_major, vera_minor);

    display_chip_vera();
    display_info_vera(STATUS_DETECTED, NULL);
}


void main_vera_check() {

    display_action_progress("Checking VERA.BIN ...");

    // Read the VERA.BIN file.
    unsigned long vera_bytes_read = w25q16_read(STATUS_CHECKING);

    wait_moment(10);

    // In case no file was found, set the status to none and skip to the next, else, mention the amount of bytes read.
    if (!vera_bytes_read) {
        // VF1 | no VERA.BIN  | Ask the user to place the VERA.BIN file onto the SDcard. Set VERA to Issue. | Issue
        // VF2 | VERA.BIN size 0 | Ask the user to place a correct VERA.BIN file onto the SDcard. Set VERA to Issue. | Issue
        // TODO: VF4 | ROM.BIN size over 0x20000 | Ask the user to place a correct VERA.BIN file onto the SDcard. Set VERA to Issue. | Issue
        display_info_vera(STATUS_SKIP, "No VERA.BIN"); // No ROM flashing for this one.
    } else {
        // VF5 | VERA.BIN all ok | Display the VERA.BIN release version and github commit id (if any) and set VERA to Flash | Flash
        // We know the file size, so we indicate it in the status panel.
        vera_file_size = vera_bytes_read;

        // VF4 | VERA.BIN and all ok
        // The first 3 bytes of the vera file header is the version of VERA.BIN.
        vera_file_release = vera_file_header[0];
        vera_file_major = vera_file_header[1];
        vera_file_minor = vera_file_header[2];

        char vera_file_version_text[13]; 
        util_version_text(vera_file_version_text, vera_file_release, vera_file_major, vera_file_minor);
        sprintf(info_text, "VERA.BIN:%s", vera_file_version_text); // All ok, display file version.
        display_info_vera(STATUS_FLASH, info_text); // All ok, SMC can be updated.
    }

}

void main_vera_flash() {

    display_progress_text(display_jp1_spi_vera_text, display_jp1_spi_vera_count);
    util_wait_space();
    display_progress_clear();

    sprintf(info_text, "Reading VERA.BIN ... (.) data ( ) empty");
    display_action_progress(info_text);

    unsigned long vera_bytes_read = w25q16_read(STATUS_READING);

    // If the ROM file was correctly read, verify the file ...
    if(vera_bytes_read) {

#ifdef __VERA_JP1_DETECT
        // Now we loop until jumper JP1 has been placed!
        display_action_progress("CLOSE the JP1 jumper header on the VERA board!");
        unsigned char spi_ensure_detect = 0;
        util_wait_space();
        while(spi_ensure_detect < 16) {
            w25q16_detect();
            wait_moment(1);
            if(spi_manufacturer == 0xEF && spi_memory_type == 0x40 && spi_memory_capacity == 0x15) {
                spi_ensure_detect++;
            } else {
                spi_ensure_detect = 0;
                display_info_vera(STATUS_WAITING, "Close JP1 jumper header!");
                util_wait_space();
            }
        }
        display_action_progress("VERA JP1 jumper header closed ...");
#endif

        // Now we compare the RAM with the actual VERA contents.
        display_action_progress("Comparing VERA ... (.) data, (=) same, (*) different.");
        display_info_vera(STATUS_COMPARING, "");

        // Verify VERA ...
        unsigned long vera_differences = w25q16_verify(0);
        
        if (!vera_differences) {
            // VFL1 | VERA and VERA.BIN equal | Display that there are no differences between the VERA and VERA.BIN. Set VERA to Flashed. | None
            display_info_vera(STATUS_SKIP, "No update required");
        } else {
            // If there are differences, the VERA needs to be flashed.
            sprintf(info_text, "%u differences!", vera_differences);
            display_info_vera(STATUS_FLASH, info_text);
            unsigned char vera_erase_error = w25q16_erase();
            if(vera_erase_error) {
                display_action_progress("There was an error cleaning your VERA flash memory!");
                display_action_text("DO NOT RESET or REBOOT YOUR CX16 AND WAIT!");
                display_info_vera(STATUS_ERROR, "ERASE ERROR!");
                display_info_smc(STATUS_ERROR, NULL);
                display_info_roms(STATUS_ERROR, NULL);
                wait_moment(32);
                spi_deselect();
                return;
            }

            __mem unsigned long vera_flashed = w25q16_flash();
            if (vera_flashed) {
                // VFL3 | Flash VERA and all ok
                display_info_vera(STATUS_FLASHED, NULL);
                __mem unsigned long vera_differences = w25q16_verify(1);
                if (vera_differences) {
                    sprintf(info_text, "%u differences!", vera_differences);
                    display_info_vera(STATUS_ERROR, info_text);
                }
            } else {
                // VFL2 | Flash VERA resulting in errors
                display_info_vera(STATUS_ERROR, info_text);
                display_action_progress("There was an error updating your VERA flash memory!");
                display_action_text("DO NOT RESET or REBOOT YOUR CX16 AND WAIT!");
                display_info_vera(STATUS_ERROR, "FLASH ERROR!");
                display_info_smc(STATUS_ERROR, NULL);
                display_info_roms(STATUS_ERROR, NULL);
                wait_moment(32);
                spi_deselect();
                return;
            }
        }


#ifdef __VERA_JP1_DETECT
        // Now we loop until jumper JP1 is open again!
        display_action_progress("OPEN the JP1 jumper header on the VERA board!");
        spi_ensure_detect = 0;
        util_wait_space();
        while(spi_ensure_detect < 16) {
            w25q16_detect();
            wait_moment(1);
            if(spi_manufacturer != 0xEF && spi_memory_type != 0x40 && spi_memory_capacity != 0x15) {
                spi_ensure_detect++;
            } else {
                spi_ensure_detect = 0;
                util_wait_space();
            }
        }
        display_action_progress("VERA JP1 jumper header opened ...");
#endif

    }

    spi_deselect();
    wait_moment(16);

}

void main_smc_detect() {
    
    // Detect the SMC bootloader and turn the SMC chip led WHITE if there is a bootloader present.
    // Otherwise, stop flashing and exit after explaining next steps.
    smc_bootloader = smc_detect();

    display_chip_smc();

    if(smc_bootloader == 0x0100) {
        // SD1 | No Bootloader | Display that there is no bootloader and set SMC to Issue. | Issue
        display_info_smc(STATUS_ISSUE, "No Bootloader!"); // If the CX16 board does not have a bootloader, display info how to flash bootloader.
        display_progress_text(display_no_valid_smc_bootloader_text, display_no_valid_smc_bootloader_count);
    } else {
        if(smc_bootloader == 0x0200) {
            // SD2 | SMC chip not detected | Display that the SMC chip is not detected and set SMC to Error. | Error
            display_info_smc(STATUS_ERROR, "SMC Unreachable!"); // This is an error with the CX16 board. J5 jumpers doesn't matter when flashing the CX16 from this utility.
        } else {
            if(smc_bootloader > 0x2) {
                // SD3 | Bootloader version not supported | Display that the current bootloader is not supported and set SMC to Issue. | Issue
                sprintf(info_text, "Bootloader v%02x invalid! !", smc_bootloader);
                display_info_smc(STATUS_ISSUE, info_text); // Bootloader is not supported by this utility, but is not error.
                display_progress_text(display_no_valid_smc_bootloader_text, display_no_valid_smc_bootloader_count);
            } else {
                // SD4 | SMC chip was detected and bootloader ok | Display SMC chip version and bootloader version and set SMC to Check. | Check
                smc_release = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_VERSION);
                smc_major = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_MAJOR);
                smc_minor = cx16_k_i2c_read_byte(FLASH_I2C_SMC_DEVICE, FLASH_I2C_SMC_MINOR);
                util_version_text(smc_version_text, smc_release, smc_major, smc_minor);
                display_info_SMC_bootloader();
                display_info_smc(STATUS_DETECTED, NULL);
            }
        }
    } 

}

void main_smc_check() {

        if(check_status_smc(STATUS_DETECTED) || check_status_smc(STATUS_ISSUE) ) {

        display_action_progress("Checking SMC.BIN ...");

        // Check the SMC.BIN file size!
        smc_file_size = smc_read(STATUS_CHECKING);

        if (!smc_file_size) {
            // SF1 | no SMC.BIN | Ask user to place an SMC.BIN file onto the SDcard and don't flash. | Issue
            // SF2 | size SMC.BIN is 0 | Ask user to place an SMC.BIN file onto the SDcard and don't flash. | Issue
            display_info_smc(STATUS_SKIP, "No SMC.BIN!"); // Skip if there is no SMC.BIN file.
        } else {
            if(smc_file_size > 0x1E00) {
                // SF3 | size SMC.BIN is > 0x1E00 | Display SMC.BIN file size issue and don't flash. Ask the user to place a correct SMC.BIN file onto the SDcard. | Issue
                display_info_smc(STATUS_ISSUE, "SMC.BIN too large!"); // Stop with SMC issue, and reset the CX16.
            } else {
                // SF4 | SMC.BIN and all ok | Display the SMC.BIN file version and set SMC to Flash. | Flash
                // The first 3 bytes of the smc file header is the version of the SMC file.
                smc_file_release = smc_file_header[0];
                smc_file_major = smc_file_header[1];
                smc_file_minor = smc_file_header[2];

                char smc_file_version_text[13]; 
                util_version_text(smc_file_version_text, smc_file_release, smc_file_major, smc_file_minor);
                sprintf(info_text, "SMC.BIN:%s", smc_file_version_text); // All ok, display file version.
                display_info_smc(STATUS_FLASH, info_text); // All ok, SMC can be updated.
            }
        }
    }
}

void main_smc_flash() {

    display_action_progress("Reading SMC.BIN ... (.) data, ( ) empty");
    display_progress_clear();

    // Read the SMC.BIN to flash the SMC chip.
    smc_file_size = smc_read(STATUS_READING);
    if(smc_file_size) {
        // Flash the SMC chip.
        display_action_text("Press both POWER/RESET buttons on the CX16 board!");
        display_info_smc(STATUS_FLASHING, "Press POWER/RESET!");
        unsigned int flashed_bytes = smc_flash(smc_file_size);
        if(flashed_bytes) {
            // SFL1 | and POWER/RESET pressed
            display_info_smc(STATUS_FLASHED, NULL);
        } else {
            if(flashed_bytes == (unsigned int)0xFFFF) {
                // SFL3 | errors during flash
                display_info_smc(STATUS_ERROR, "SMC has errors!");
            } else {
                // SFL2 | no action on POWER/RESET press request
                display_info_smc(STATUS_ISSUE, "POWER/RESET not pressed!");
            }
        }
    }
}

#pragma code_seg(Code)
#pragma data_seg(Data)

void main_rom_detect() {

    // Block all interrupts to prevent a changed ROM bank to make an interrupt go wrong.
    SEI();
    bank_set_brom(0);

    // Detecting ROM chips
    rom_detect();
    display_chip_rom();

    for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++) {
        if(rom_device_ids[rom_chip] != UNKNOWN) {
            // RD1 | Known ROM chip device ID | Display ROM chip firmware release number and github commit ID if in hexadecimal format and set to Check. | None
            // Fill the version data ..., we need to set the ROM bank to find the version ids.
            bank_set_brom(rom_chip*32);
            rom_get_github_commit_id(&rom_github[rom_chip*8], (char*)0xC000);
            rom_release[rom_chip] = rom_get_release(*((char*)0xFF80));
            rom_prefix[rom_chip] = rom_get_prefix(*((char*)0xFF80));
            rom_get_version_text(&rom_release_text[rom_chip*13], rom_prefix[rom_chip], rom_release[rom_chip], &rom_github[rom_chip*8]);
            display_info_rom(rom_chip, STATUS_DETECTED, NULL); // Set the info for the ROMs to Detected.
        } else {
            // RD2 | Unknown ROM chip device ID | Don't do anything and set to None. | None
            // display_info_rom(rom_chip, STATUS_NONE, ""); // Set the info for the ROMs to None.
        }
    }

    bank_set_brom(4);
    CLI();
}

void main_rom_flash() {
    // Flash the ROM chips. 
    // We loop first all the ROM chips and read the file contents.
    // Then we verify the file contents and flash the ROM only for the differences.
    // If the file contents are the same as the ROM contents, then no flashing is required.
    // IMPORTANT! We start to flash the ROMs on the extension card.
    // The last ROM flashed is the CX16 ROM on the CX16 board!
    for(unsigned char rom_chip = 7; rom_chip != 255; rom_chip--) {

        if(check_status_rom(rom_chip, STATUS_FLASH)) {

            // IMPORTANT! We only flash the CX16 ROM chip if the SMC got flashed succesfully!
            if((rom_chip == 0 && (check_status_smc(STATUS_FLASHED) || check_status_smc(STATUS_SKIP))) || (rom_chip != 0)) {

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
                    display_action_progress("Comparing ... (.) data, (=) same, (*) different.");
                    display_info_rom(rom_chip, STATUS_COMPARING, "");

                    // Verify the ROM...
                    unsigned long rom_differences = rom_verify(
                        rom_chip, rom_bank, file_sizes[rom_chip]);
                    
                    if (!rom_differences) {
                        // RFL1 | ROM and ROM.BIN equal | Display that there are no differences between the ROM and ROM.BIN. Set ROM to Flashed. | None
                        display_info_rom(rom_chip, STATUS_SKIP, "No update required");
                    } else {
                        // 
                        // If there are differences, the ROM needs to be flashed.
                        sprintf(info_text, "%05x differences!", rom_differences);
                        display_info_rom(rom_chip, STATUS_FLASH, info_text);
                        
                        unsigned long rom_flash_errors = rom_flash(
                            rom_chip, rom_bank, file_sizes[rom_chip]);
                        if(rom_flash_errors) {
                            // RFL2 | Flash ROM resulting in errors
                            sprintf(info_text, "%u flash errors!", rom_flash_errors);
                            display_info_rom(rom_chip, STATUS_ERROR, info_text);
                        } else {
                            // RFL3 | Flash ROM and all ok
                            display_info_rom(rom_chip, STATUS_FLASHED, NULL);
                        }
                    }
                }
            } else {
                display_info_rom(rom_chip, STATUS_ISSUE, "SMC Update failed!");
            }
        }
    }
}

void main_rom_check() {
        SEI();

    // We loop all the possible ROM chip slots on the board and on the extension card,
    // and we check the file contents.
    // Any error identified gets reported and this chip will not be flashed.
    // In case of ROM0.BIN in error, no flashing will be done!
    for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++) {

        bank_set_brom(0);

        // If the ROM chip was detected and is known ...
        if(rom_device_ids[rom_chip] != UNKNOWN) {

            display_progress_clear();

            unsigned char rom_bank = rom_chip * 32;
            unsigned char* file = rom_file(rom_chip); // Calculate the ROM(n).BIN input file name, based on the rom chip number.
            sprintf(info_text, "Checking %s ...", file);
            display_action_progress(info_text);

            // Read the ROM(n).BIN file.
            unsigned long rom_bytes_read = rom_read(rom_chip, file, STATUS_CHECKING, rom_bank, rom_sizes[rom_chip]);

            // In case no file was found, set the status to none and skip to the next, else, mention the amount of bytes read.
            if (!rom_bytes_read) {
                // RF1 | no ROM.BIN  | Ask the user to place the ROM.BIN file onto the SDcard. Set ROM to Issue. | Issue
                // RF2 | ROM.BIN size 0 | Ask the user to place a correct ROM.BIN file onto the SDcard. Set ROM to Issue. | Issue
                // TODO: RF4 | ROM.BIN size over 0x80000 | Ask the user to place a correct ROM.BIN file onto the SDcard. Set ROM to Issue. | Issue
                sprintf(info_text, "No %s", file);
                display_info_rom(rom_chip, STATUS_SKIP, info_text); // No ROM flashing for this one.
            } else {
                unsigned long rom_file_modulo = rom_bytes_read % 0x4000;
                if(rom_file_modulo) {
                    // RF3 | ROM.BIN size not % 0x4000 | Ask the user to place a correct ROM.BIN file onto the SDcard. Set ROM to Issue. | Issue
                    sprintf(info_text, "File %s size error!", file);
                    display_info_rom(rom_chip, STATUS_ISSUE, info_text); // No flash.
                } else {
                    // RF5 | ROM.BIN all ok | Display the ROM.BIN release version and github commit id (if any) and set ROM to Flash | Flash
                    // We know the file size, so we indicate it in the status panel.
                    file_sizes[rom_chip] = rom_bytes_read;
                    
                    // Fill the version data ...
                    unsigned char* rom_file_github_id = &rom_file_github[8*rom_chip];
                    unsigned char rom_file_release_id = rom_get_release(rom_file_release[rom_chip]);
                    unsigned char rom_file_prefix_id = rom_get_prefix(rom_file_release[rom_chip]);

                    char rom_file_release_text[13]; 
                    rom_get_version_text(rom_file_release_text, rom_file_prefix_id, rom_file_release_id, rom_file_github_id);

                    sprintf(info_text, "%s:%s", file, rom_file_release_text);
                    display_info_rom(rom_chip, STATUS_FLASH, info_text);
                }
            }
        }
    }
}

void main_debriefing() {

    if(check_status_vera(STATUS_ERROR)) {
        // DE8 | There is a flash error with the VERA! We cannot reset the CX16!

        bank_set_brom(4);
        CLI();

        vera_display_set_border_color(RED);
        textcolor(WHITE);
        bgcolor(BLUE);
        clrscr();

        printf("There was a severe error updating your VERA!");
        printf("You are back at the READY prompt without resetting your CX16.\n\n");
        printf("Please don't reset or shut down your VERA until you've\n"),
        printf("managed to either reflash your VERA with the previous firmware ");
        printf("or have update successs retrying!\n\n");
        printf("PLEASE REMOVE THE JP1 JUMPER OR YOUR SDCARD WON'T WORK!\n");
        wait_moment(32);
        system_reset();
        return;
    }

    if((check_status_smc(STATUS_SKIP) || check_status_smc(STATUS_NONE)) && 
       (check_status_vera(STATUS_SKIP) || check_status_vera(STATUS_NONE)) && 
       (check_status_roms_less(STATUS_SKIP)) ) {
        // DE1 | All components skipped
        vera_display_set_border_color(BLACK);
        display_action_progress("No CX16 component has been updated with new firmware!");
    } else {
        if(check_status_smc(STATUS_ERROR) || check_status_vera(STATUS_ERROR) || check_status_roms(STATUS_ERROR)) {
            // DE2 | There is an error with one of the components
            vera_display_set_border_color(RED);
            display_action_progress("Update Failure! Your CX16 may no longer boot!");
            display_action_text("Take a photo of this screen and wait at leaast 60 seconds.");
            wait_moment(250);
            smc_reset();
            while(1);
        } else {
            if(check_status_smc(STATUS_ISSUE) || check_status_vera(STATUS_ISSUE) || check_status_roms(STATUS_ISSUE)) {
                // DE3 | There is an Issue with one of the components
                vera_display_set_border_color(YELLOW);
                display_action_progress("Update issues, your CX16 is not updated!");
            } else {
                vera_display_set_border_color(GREEN);
                display_action_progress("Your CX16 update is a success!");

                if(check_status_smc(STATUS_FLASHED)) {

                    // DE7 | Reset SMC when bootloader v1
                    // If SMC bootloader 1, reset the CX16 because the bootloader will hang anyway.
                    if(smc_bootloader == 1)
                        smc_reset();

                    display_progress_text(display_debriefing_smc_text, display_debriefing_smc_count);

                    textcolor(PINK);
                    display_progress_line(2, "DON'T DO ANYTHING UNTIL COUNTDOWN FINISHES!");
                    textcolor(WHITE);

                    for (unsigned char w=120; w>0; w--) {
                        wait_moment(1);
                        sprintf(info_text, "[%03u] Please read carefully the below ...", w);
                        display_action_text(info_text);
                    }

                    // DE4 | The components correctly updated, SMC bootloader 1
                    sprintf(info_text, "Please disconnect your CX16 from power source ...");
                    display_action_text(info_text);

                    // DE5 | The components correctly updated, SMC bootloader 2
                    // When bootloader 1, the CX16 won't shut down automatically and will hang! The user will see the above bootloader 1 action.
                    // When bootloader 2, the CX16 will shut down automatically. The user will never see the bootloader 1 action.
                    smc_reset(); // This call will reboot the SMC, which will reset the CX16 if bootloader R2.
                    while(1); // Wait until CX16 is disconnected from power or shuts down.
                } else {
                    display_progress_text(display_debriefing_text_rom, display_debriefing_count_rom);
                }
            }
        }
    }

    {
        // DE6 | Wait until reset
        textcolor(PINK);
        display_progress_line(2, "DON'T DO ANYTHING UNTIL COUNTDOWN FINISHES!");
        textcolor(WHITE);

        for (unsigned char w=120; w>0; w--) {
            wait_moment(1);
            sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w);
            display_action_text(info_text);
        }

        system_reset();
    }

}

void main() {

    init();       

#ifdef __INTRO
    main_intro();
#endif


#ifdef __SMC_CHIP_PROCESS
    main_smc_detect();
#endif

#ifdef __VERA_CHIP_PROCESS
    main_vera_detect();
#endif

#ifdef __ROM_CHIP_PROCESS
    main_rom_detect();
#endif

#ifdef __SMC_CHIP_PROCESS
#ifdef __SMC_CHIP_CHECK
    main_smc_check();
#endif
#endif

#ifdef __VERA_CHIP_PROCESS
#ifdef __VERA_CHIP_CHECK
    // Here we allow for interrupts for the VERA check process.
    bank_set_brom(4);
    CLI();
    display_progress_clear();
    main_vera_check();
    SEI();
    bank_set_brom(0);
#endif
#endif


#ifdef __ROM_CHIP_PROCESS
#ifdef __ROM_CHIP_CHECK
    main_rom_check();
#endif
#endif

    // VA5 | SMC is not Flash and CX16 is Flash
    if(!check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH)) {
        display_action_progress("Issue with the CX16 SMC, check the issue ...");
        display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count);
        display_info_cx16_rom(STATUS_SKIP, "Issue with SMC!");
        display_info_smc(STATUS_ISSUE, NULL);
        unsigned char ch = util_wait_key("Proceed with the update? [Y/N]", "YN");
        if(ch == 'Y') {
            display_info_cx16_rom(STATUS_FLASH, "");
            display_info_smc(STATUS_SKIP, NULL);
        }
    }

    // VA3 | SMC.BIN and CX16 ROM not Detected
    if(check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_NONE)) {
        display_action_progress("Issue with the CX16 ROM: not detected! ...");
        display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count);
        display_info_smc(STATUS_SKIP, "Issue with CX16 ROM!");
        display_info_cx16_rom(STATUS_ISSUE, "Are J1 jumper pins closed?");
        unsigned char ch = util_wait_key("Proceed with the update? [Y/N]", "YN");
        if(ch == 'Y') {
            display_info_smc(STATUS_FLASH, "");
            display_info_cx16_rom(STATUS_SKIP, "");
        }
    } else {
        // VA4 | SMC is Flash and CX16 is not Flash
        if(check_status_smc(STATUS_FLASH) && !check_status_cx16_rom(STATUS_FLASH)) {
            display_action_progress("Issue with the CX16 ROM, check the issue ...");
            display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count);
            display_info_smc(STATUS_SKIP, "Issue with main CX16 ROM!");
            display_info_cx16_rom(STATUS_ISSUE, NULL);
            unsigned char ch = util_wait_key("Proceed with the update? [Y/N]", "YN");
            if(ch == 'Y') {
                display_info_smc(STATUS_FLASH, "");
                display_info_cx16_rom(STATUS_SKIP, "");
            }
        }
    }

    // VA2 | SMC.BIN does not support ROM.BIN release
    if(check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH) && !smc_supported_rom(rom_file_release[0])) {
        display_action_progress("Compatibility between ROM.BIN and SMC.BIN can't be assured!");
        display_progress_text(display_smc_unsupported_rom_text, display_smc_unsupported_rom_count);
        unsigned char ch = util_wait_key("Proceed with the update? [Y/N]", "YN");
        if(ch == 'N') {
            // Cancel flash
            display_info_smc(STATUS_ISSUE, NULL);
            display_info_cx16_rom(STATUS_ISSUE, NULL);
        }
    }

    // VAx | VERA.BIN does not support ROM.BIN release
    if(check_status_vera(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH) && !vera_supported_rom(rom_file_release[0])) {
        display_action_progress("Compatibility between ROM.BIN and VERA.BIN can't be assured!");
        display_progress_text(display_vera_unsupported_rom_bin_text, display_vera_unsupported_rom_bin_count);
        unsigned char ch = util_wait_key("Proceed with the update? [Y/N]", "YN");
        if(ch == 'N') {
            // Cancel flash
            display_info_vera(STATUS_ISSUE, NULL);
            display_info_cx16_rom(STATUS_ISSUE, NULL);
        }
    }

    // VAx | VERA.BIN does not support ROM release
    if(check_status_vera(STATUS_FLASH) && check_status_cx16_rom(STATUS_SKIP) && !vera_supported_rom(rom_release[0])) {
        display_action_progress("Compatibility between ROM and VERA.BIN can't be assured!");
        display_progress_text(display_vera_unsupported_rom_text, display_vera_unsupported_rom_count);
        unsigned char ch = util_wait_key("Proceed with the update? [Y/N]", "YN");
        if(ch == 'N') {
            // Cancel flash
            display_info_vera(STATUS_ISSUE, NULL);
            display_info_cx16_rom(STATUS_ISSUE, NULL);
        }
    }

    // VA1 | Version of SMC and SMC.BIN equal
    if(check_status_smc(STATUS_FLASH) && smc_release == smc_file_release && smc_major == smc_file_major && smc_minor == smc_file_minor) {
        display_action_progress("The CX16 SMC and SMC.BIN versions are equal, no flash required!");
        util_wait_space();
        display_info_smc(STATUS_SKIP, NULL);
    }

    // VA7 | Version of CX16 ROM and ROM.BIN are equal
    if(check_status_cx16_rom(STATUS_FLASH) && rom_release[0] == rom_file_release[0] && strncmp(&rom_github[0], &rom_file_github[0], 7) == 0) {
        display_action_progress("The CX16 ROM and ROM.BIN versions are equal, no flash required!");
        util_wait_space();
        display_info_cx16_rom(STATUS_SKIP, NULL);
    }


    // VA6 | no SMC.BIN and no CX16 ROM.BIN


    if(!check_status_smc(STATUS_ISSUE) && !check_status_vera(STATUS_ISSUE) && !check_status_roms(STATUS_ISSUE) &&
       !check_status_smc(STATUS_ERROR) && !check_status_vera(STATUS_ERROR) && !check_status_roms(STATUS_ERROR)) {

        // If the SMC and CX16 ROM is ready to flash, or, if one of the ROMs can be flashed, ok, go ahead and flash.
        if(check_status_vera(STATUS_FLASH) || check_status_smc(STATUS_FLASH) || check_status_cx16_rom(STATUS_FLASH) || check_status_card_roms(STATUS_FLASH)) {
            display_action_progress("Chipsets have been detected and update files validated!");
            unsigned char ch = util_wait_key("Continue with update of highlighted chipsets? [Y/N]", "nyNY");        
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

#ifdef __VERA_CHIP_PROCESS
#ifdef __VERA_CHIP_FLASH
        // Here we allow for interrupts for the VERA flash process.
        bank_set_brom(4);
        CLI();
        if(check_status_vera(STATUS_FLASH)) {
            main_vera_flash();
        }
        SEI();
        bank_set_brom(0);

        display_progress_clear();
#endif
#endif

#ifdef __SMC_CHIP_PROCESS
#ifdef __SMC_CHIP_FLASH
    // Flash the SMC when it has the status!
    if (check_status_smc(STATUS_FLASH) && !check_status_vera(STATUS_ERROR)) {
        main_smc_flash();
    }
#endif
#endif

    // Point of no return for the interrupts!
    SEI();

#ifdef __ROM_CHIP_PROCESS
#ifdef __ROM_CHIP_FLASH
        if(!check_status_vera(STATUS_ERROR)) {
            main_rom_flash();
        }

    display_progress_clear();
#endif
#endif

    }

    main_debriefing();

    return;
}
