/**
 * @file cx16-init.c
 * 
 * @author Wavicle from CX16 community (https://gist.github.com/jburks) -- Advice and outline of the ROM update logic & overall support and test assistance of this program.
 * @author MooingLemur from CX16 community (https://github.com/mooinglemur) -- Advice and outline of the main SPI and W25Q16 update logic, and supply of new VERA firmware.
 * @author Stefan Jakobsson from CX16 community (https://github.com/stefan-b-jakobsson) -- Advice and outline of the SMC update logic, SMC firmware and bootloader and creation of SMC firmware.
 * @author Sven Van de Velde from CX16 community (https://github.com/FlightControl-User) -- Creation of this program, under the strong expertise by the people above.
 * 
 * @brief COMMANDER X16 UPDATE INITIALIZATION
 *
 * @version 3.0
 * @date 2023-10-15
 *
 * @copyright Copyright (c) 2023
 *
 */

#include "cx16-defines.h"
#include "cx16-globals.h"
#include "cx16-status.h"
#include "cx16-utils.h"
#include "cx16-display.h"
#include "cx16-display-text.h"
#include "cx16-smc.h"
#include "cx16-rom.h"
#include "cx16-w25q16.h"

#include "cx16-init.h"

#pragma code_seg(CodeOverwrite)

void init() {
    display_frame_init_64(); // ST1 | Reset canvas to 64 columns
    display_frame_draw();
    display_frame_title("Commander X16 Update Utility (v3.0.0) "); // ST2 | Ensure correct version
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

}

#pragma code_seg(Code)
#pragma data_seg(Data)

