/**
 * @file cx16-display-text.h
 * 
 * @author Wavicle from CX16 community (https://gist.github.com/jburks) -- Main ROM update logic & overall support and test assistance.
 * @author MooingLemur from CX16 community (https://github.com/mooinglemur) -- Main SPI and VERA update logic, VERA firmware.
 * @author Stefan Jakobsson from CX16 community (https://github.com/stefan-b-jakobsson) -- Main SMC update logic, SMC firmware and bootloader.
 * @author Sven Van de Velde from CX16 community (https://github.com/FlightControl-User) -- Creation of this program, under the strong expertise by the people above.
 * 
 * @brief COMMANDER X16 UPDATE TOOL BRIEFING TEXTS
 *
 * @version 3.0
 * @date 2023-10-15
 *
 * @copyright Copyright (c) 2023
 *
 */

#pragma code_seg(CodeIntro)
#pragma data_seg(DataIntro)

const char display_intro_briefing_count = 15;
const char* display_into_briefing_text[15] = {
    "Welcome to the CX16 update tool! This program updates the",
    "chipsets on your CX16 and ROM expansion boards.",
    "",
    "Depending on the files found on the SDCard, various",
    "components will be updated:",
    "- Mandatory: SMC.BIN for the SMC firmware.",
    "- Mandatory: ROM.BIN for the main ROM.",
    "- Optional: VERA.BIN for the VERA firmware.",
    "- Optional: ROMn.BIN for a ROM expansion board or cartridge.",
    "",
    "  Important: Ensure J1 write-enable jumper is closed",
    "  on both the main board and any ROM expansion board.",
    "",
    "Please carefully read the step-by-step instructions at ",
    "https://flightcontrol-user.github.io/x16-flash"
};

const char display_intro_colors_count = 16;
const char* display_into_colors_text[16] = {
    "The panels above indicate the update progress,",
    "using status indicators and colors as specified below:",
    "",
    " -   None       Not detected, no action.",
    " -   Skipped    Detected, but no action, eg. no file.",
    " -   Detected   Detected, verification pending.",
    " -   Checking   Verifying size of the update file.",
    " -   Reading    Reading the update file into RAM.",
    " -   Comparing  Comparing the RAM with the ROM.",
    " -   Update     Ready to update the firmware.",
    " -   Updating   Updating the firmware.",
    " -   Updated    Updated the firmware succesfully.",
    " -   Issue      Problem identified during update.",
    " -   Error      Error found during update.",
    "",
    "Errors can indicate J1 jumpers are not closed!"
};

#pragma code_seg(CodeVera)
#pragma data_seg(DataVera)
const char display_jp1_spi_vera_count = 16;
const char* display_jp1_spi_vera_text[16] = {
    "The following steps are IMPORTANT to update the VERA:",
    "",
    "1. In the next step you will be asked to close the JP1 jumper",
    "   pins on the VERA board.",
    "   The closure of the JP1 jumper pins is required",
    "   to allow the program to access VERA flash memory",
    "   instead of the SDCard!",
    "",
    "2. Once the VERA has been updated, you will be asked to open",
    "   the JP1 jumper pins!",
    "",
    "Reminder:",
    " - DON'T CLOSE THE JP1 JUMPER PINS BEFORE BEING ASKED!",
    " - DON'T OPEN THE JP1 JUMPER PINS WHILE VERA IS BEING UPDATED!",
    "",
    "The program continues once the JP1 pins are opened/closed.",
};

#pragma code_seg(Code)
#pragma data_seg(Data)
const char display_no_valid_smc_bootloader_count = 9;
const char* display_no_valid_smc_bootloader_text[9] = {
    "The SMC chip in your CX16 doesn't have a valid bootloader.",
    "",
    "A valid bootloader is needed to update the SMC chip.",
    "Unfortunately, your SMC chip cannot be updated using this tool!",
    "",
    "A bootloader can be installed onto the SMC chip using an",
    "an Arduino or an AVR ISP device.",
    "Alternatively a new SMC chip with a valid bootloader can be",
    "ordered from TexElec."
};

const char display_smc_rom_issue_count = 8;
const char* display_smc_rom_issue_text[8] = {
    "There is an issue with the CX16 SMC or ROM flash readiness.",
    "",
    "Both the SMC and the main ROM must be updated together,",
    "to avoid possible conflicts of firmware, bricking your CX16.",
    "",
    "Therefore, ensure you have the correct SMC.BIN and ROM.BIN",
    "files placed on your SDcard. Also ensure that the",
    "J1 jumper pins on the CX16 board are closed."
};

const char display_smc_unsupported_rom_count = 7;
const char* display_smc_unsupported_rom_text[7] = {
    "There is an issue with the CX16 SMC or ROM flash versions.",
    "",
    "Both the SMC and the main ROM must be updated together,",
    "to avoid possible conflicts, risking bricking your CX16.",
    "",
    "The SMC.BIN and ROM.BIN found on your SDCard may not be",
    "mutually compatible. Update the CX16 at your own risk!"
};


const char display_debriefing_count_smc = 14;
const char* display_debriefing_text_smc[14] = {
    "Your CX16 system has been successfully updated!",
    "",
    "DON'T DO ANYTHING UNTIL COUNTDOWN FINISHES!",
    "",
    "Because your SMC chipset has been updated,",
    "the restart process differs, depending on the",
    "SMC boootloader version installed on your CX16 board:",
    "",
    "- SMC bootloader v2.0: your CX16 will automatically shut down.",
    "",
    "- SMC bootloader v1.0: you need to ",
    "  COMPLETELY DISCONNECT your CX16 from the power source!",
    "  The power-off button won't work!",
    "  Then, reconnect and start the CX16 normally."
};

const char display_debriefing_count_rom = 4;
const char* display_debriefing_text_rom[4] = {
    "Your CX16 system has been successfully updated!",
    "",
    "Since your CX16 system SMC chip has not been updated",
    "your CX16 will just reset automatically after count down."
};
