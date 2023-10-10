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

#include "cx16-defines.h"
#include "cx16-globals.h"

#pragma var_model(zp)

#include "cx16-status.h"
#include "cx16-utils.h"
#include "cx16-display.h"
#include "cx16-display-text.h"
#include "cx16-smc.h"
#include "cx16-rom.h"


void main() {

    SEI();

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

    
    display_frame_init_64(); // ST1 | Reset canvas to 64 columns
    display_frame_draw();
    display_frame_title("Commander X16 Update Utility (v2.2.0)."); // ST2 | Ensure correct version
    display_info_title();
    display_action_progress("Introduction, please read carefully the below!");
    display_progress_clear();
    display_chip_smc();
    display_chip_vera();
    display_chip_rom();
    display_info_smc(STATUS_COLOR_NONE, NULL);
    display_info_vera(STATUS_NONE, NULL);
    for(unsigned char rom_chip=0; rom_chip<8; rom_chip++) {
        strcpy(&rom_release_text[rom_chip*13], "          " );
        display_info_rom(rom_chip, STATUS_NONE, NULL);
    }

#ifdef __INTRO

    bank_set_brom(4);
    CLI();

    display_progress_text(display_into_briefing_text, display_intro_briefing_count);
    util_wait_space();

    display_progress_text(display_into_colors_text, display_intro_colors_count);
    for(unsigned char intro_status=0; intro_status<11; intro_status++) {
        display_info_led(PROGRESS_X + 3, PROGRESS_Y + 3 + intro_status, status_color[intro_status], BLUE);
    }
    util_wait_space();
    display_progress_clear();

    SEI();
    bank_set_brom(0);

#endif



#ifdef __SMC_CHIP_PROCESS

    // Detect the SMC bootloader and turn the SMC chip led WHITE if there is a bootloader present.
    // Otherwise, stop flashing and exit after explaining next steps.
    smc_bootloader = smc_detect();
    strcpy(smc_version_text, "0.0.0");

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
                smc_get_version_text(smc_version_text, smc_release, smc_major, smc_minor);
                display_info_smc(STATUS_DETECTED, NULL);
            }
        }
    } 

#endif

    // Detecting VERA FPGA.
    display_chip_vera();
    display_info_vera(STATUS_DETECTED, "VERA installed, OK"); // Set the info for the VERA to Detected.

#ifdef __ROM_CHIP_PROCESS

    // Detecting ROM chips
    rom_detect();
    display_chip_rom();

    for(unsigned char rom_chip = 0; rom_chip < 8; rom_chip++) {
        if(rom_device_ids[rom_chip] != UNKNOWN) {
            // RD1 | Known ROM chip device ID | Display ROM chip firmware release number and github commit ID if in hexadecimal format and set to Check. | None
            // Fill the version data ...
            bank_set_brom(rom_chip*32);
            rom_get_github_commit_id(&rom_github[rom_chip*8], (char*)0xC000);
            rom_release[rom_chip] = rom_get_release(*((char*)0xFF80));
            rom_prefix[rom_chip] = rom_get_prefix(*((char*)0xFF80));
            rom_get_version_text(&rom_release_text[rom_chip*13], rom_prefix[rom_chip], rom_release[rom_chip], &rom_github[rom_chip*8]);
            display_info_rom(rom_chip, STATUS_DETECTED, ""); // Set the info for the ROMs to Detected.
        } else {
            // RD2 | Unknown ROM chip device ID | Don't do anything and set to None. | None
            // display_info_rom(rom_chip, STATUS_NONE, ""); // Set the info for the ROMs to None.
        }
    }

#endif


#ifdef __SMC_CHIP_PROCESS
#ifdef __SMC_CHIP_CHECK

    SEI();

    if(check_status_smc(STATUS_DETECTED)) {

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
                smc_get_version_text(smc_file_version_text, smc_file_release, smc_file_major, smc_file_minor);
                sprintf(info_text, "SMC.BIN:%s", smc_file_version_text); // All ok, display file version.
                display_info_smc(STATUS_FLASH, info_text); // All ok, SMC can be updated.
            }
        }
    }

    CLI();

#endif
#endif

    display_info_vera(STATUS_SKIP, "VERA not yet supported"); // Set the info for the VERA to Detected.


#ifdef __ROM_CHIP_PROCESS
#ifdef __ROM_CHIP_CHECK

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
                    unsigned char rom_file_github[8];
                    rom_get_github_commit_id(rom_file_github, (char*)RAM_BASE);
                    bank_push_set_bram(1);
                    unsigned char rom_file_release = rom_get_release(*((char*)0xBF80));
                    unsigned char rom_file_prefix = rom_get_prefix(*((char*)0xBF80));
                    bank_pull_bram();

                    char rom_file_release_text[13]; 
                    rom_get_version_text(rom_file_release_text, rom_file_prefix, rom_file_release, rom_file_github);

                    sprintf(info_text, "%s:%s", file, rom_file_release_text);
                    display_info_rom(rom_chip, STATUS_FLASH, info_text);
                }
            }
        }
    }

#endif
#endif

    bank_set_brom(4);
    CLI();

    // VA5 | SMC is not Flash and CX16 is Flash | Display SMC update issue and don't flash. | Issue
    if(!check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH)) {
        display_action_progress("SMC update issue!");
        display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count);
        display_info_cx16_rom(STATUS_SKIP, "Issue with SMC!");
        display_info_smc(STATUS_ISSUE, NULL);
        util_wait_space();
    }

    // VA3 | SMC.BIN and CX16 ROM not Detected | Display issue and don't flash. Ask to close the J1 jumper pins on the CX16 main board. | Issue
    if(check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_NONE)) {
        display_action_progress("CX16 ROM update issue, ROM not detected!");
        display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count);
        display_info_smc(STATUS_SKIP, "Issue with main CX16 ROM!");
        display_info_cx16_rom(STATUS_ISSUE, "Are J1 jumper pins closed?");
        util_wait_space();
    } else {
        // VA4 | SMC is Flash and CX16 is not Flash | Display CX16 ROM update issue and don't flash. | Issue
        if(check_status_smc(STATUS_FLASH) && !check_status_cx16_rom(STATUS_FLASH)) {
            display_action_progress("CX16 ROM update issue!");
            display_progress_text(display_smc_rom_issue_text, display_smc_rom_issue_count);
            display_info_smc(STATUS_SKIP, "Issue with main CX16 ROM!");
            display_info_cx16_rom(STATUS_ISSUE, NULL);
            util_wait_space();
        }
    }

    // VA2 | SMC.BIN does not support ROM.BIN release | Display warning that SMC.BIN does not support the ROM.BIN release. Ask for user confirmation to continue flashing Y/N. If the users selects not to flash, set both the SMC and the ROM as an Issue and don't flash. | Issue
    if(check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH) && !smc_supported_rom(rom_release[0])) {
        display_action_progress("Compatibility between ROM.BIN and SMC.BIN can't be assured!");
        display_progress_text(display_smc_unsupported_rom_text, display_smc_unsupported_rom_count);
        unsigned char ch = util_wait_key("Continue with flashing anyway? [Y/N]", "YN");
        if(ch == 'N') {
            // Cancel flash
            display_info_smc(STATUS_ISSUE, NULL);
            display_info_cx16_rom(STATUS_ISSUE, NULL);
        }
    }

    // VA1 | Version of SMC and SMC.BIN equal | Display that the SMC and SMC.BIN versions are equal and no flashing is required. Set SMC to Skip. | None
    if(check_status_smc(STATUS_FLASH) && smc_release == smc_file_release && smc_major == smc_file_major && smc_minor == smc_file_minor) {
        display_action_progress("The SMC chip and SMC.BIN versions are equal, no flash required!");
        util_wait_space();
        display_info_smc(STATUS_SKIP, "SMC.BIN and SMC equal.");
    }

    // VA6 | no SMC.BIN and no CX16 ROM.BIN


    if(!check_status_smc(STATUS_ISSUE) && !check_status_vera(STATUS_ISSUE) && !check_status_roms(STATUS_ISSUE) &&
       !check_status_smc(STATUS_ERROR) && !check_status_vera(STATUS_ERROR) && !check_status_roms(STATUS_ERROR)) {

        // If the SMC and CX16 ROM is ready to flash, or, if one of the ROMs can be flashed, ok, go ahead and flash.
        if(check_status_smc(STATUS_FLASH) || check_status_cx16_rom(STATUS_FLASH) || check_status_card_roms(STATUS_FLASH)) {
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

        bank_set_bram(0);
        SEI();

#ifdef __SMC_CHIP_PROCESS
#ifdef __SMC_CHIP_FLASH

        // Flash the SMC when it has the status!
        if (check_status_smc(STATUS_FLASH) && check_status_cx16_rom(STATUS_FLASH)) {

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
                    display_info_smc(STATUS_FLASHED, "");
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


#endif
#endif


#ifdef __ROM_CHIP_PROCESS
#ifdef __ROM_CHIP_FLASH

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
                        display_action_progress("Comparing ... (.) same, (*) different.");
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

    display_progress_clear();

#endif
#endif

    }

    if((check_status_smc(STATUS_SKIP) || check_status_smc(STATUS_NONE)) && 
       (check_status_vera(STATUS_SKIP) || check_status_vera(STATUS_NONE)) && 
       check_status_roms_less(STATUS_SKIP)) {
        // DE1 | All components skipped
        vera_display_set_border_color(BLACK);
        display_action_progress("No CX16 component has been updated with new firmware!");
    } else {
        if(check_status_smc(STATUS_ERROR) || check_status_vera(STATUS_ERROR) || check_status_roms(STATUS_ERROR)) {
            // DE2 | There is an error with one of the components
            vera_display_set_border_color(RED);
            display_action_progress("Update Failure! Your CX16 may no longer boot!");
            display_action_text("Take a photo of this screen, shut down power and retry!");
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

                    display_progress_text(display_debriefing_text_smc, display_debriefing_count_smc);

                    textcolor(PINK);
                    display_progress_line(2, "DON'T DO ANYTHING UNTIL COUNTDOWN FINISHES!");
                    textcolor(WHITE);

                    for (unsigned char w=120; w>0; w--) {
                        wait_moment();
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
            wait_moment();
            sprintf(info_text, "(%u) Your CX16 will reset after countdown ...", w);
            display_action_text(info_text);
        }

        system_reset();
    }

    return;
}
