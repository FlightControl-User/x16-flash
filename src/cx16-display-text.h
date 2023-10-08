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

const char display_intro_briefing_count = 14;
const char* display_into_briefing_text[14] = {
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

const char display_no_valid_smc_bootloader_count = 9;
const char* display_no_valid_smc_bootloader_text[9] = {
    "The SMC chip in your CX16 system does not contain a valid bootloader.",
    "",
    "A valid bootloader is needed to update the SMC chip.",
    "Unfortunately, your SMC chip cannot be updated using this tool!",
    "",
    "You will either need to install or downgrade the bootloader onto",
    "the SMC chip on your CX16 using an arduino device,",
    "or alternatively to order a new SMC chip from TexElec or",
    "a CX16 community friend containing a valid bootloader!"
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
    "to avoid possible conflicts of firmware, bricking your CX16.",
    "",
    "The SMC.BIN does not support the current ROM.BIN file",
    "placed on your SDcard. Upgrade the CX16 upon your own risk!"
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
