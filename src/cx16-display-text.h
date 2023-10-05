/**
 * @file cx16-display-text.h
 * @author your name (you@domain.com)
 * @brief 
 * @version 0.1
 * @date 2023-10-05
 * 
 * @copyright Copyright (c) 2023
 * 
 */

const char display_intro_briefing_count = 16;
const char* display_into_briefing_text[16] = {
    "Welcome to the CX16 update tool! This program will update the",
    "chipsets on your CX16 board and on your ROM expansion cardridge.",
    "",
    "Depending on the type of files placed on your SDCard,",
    "different chipsets will be updated of the CX16:",
    "- The mandatory SMC.BIN file updates the SMC firmware.",
    "- The mandatory ROM.BIN file updates the main ROM.",
    "- An optional VERA.BIN file updates your VERA firmware.",
    "- Any optional ROMn.BIN file found on your SDCard ",
    "  updates the relevant ROMs on your ROM expansion cardridge.",
    "  Ensure your J1 jumpers are properly enabled on the CX16!",
    "",
    "Please read carefully the step by step instructions at ",
    "https://flightcontrol-user.github.io/x16-flash",
};

const char display_intro_colors_count = 16;
const char* display_into_colors_text[16] = {
    "The panels above indicate the update progress of your chipsets,",
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
    "Errors indicate your J1 jumpers are not properly set!",
};


const char display_debriefing_count_smc = 12;
const char* display_debriefing_text_smc[12] = {
    "Your CX16 system has been successfully updated!",
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
    "Since your CX16 system SMC and main ROM chipset",
    "have not been updated, your CX16 will just reset."
};
