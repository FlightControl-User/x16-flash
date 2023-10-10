# List of all test scenarios and expected results.

## ST - Startup.

ID | Test Case | Action Description | Error Level
--- | --- | --- | ---
ST1 | Reset canvas to 64 columns | Ensure that the scree mode is properly set. Disable sprites, disable layer 0, activate layer 1, set borders, set screen text white with blue background. | None
ST2 | Ensure correct version | Ensure that the title contains the correct release, major, minor numbers.

## SD - SMC chip Detection.

ID | Test Case | Action Description | Error Level
--- | --- | --- | ---
SD1 | No Bootloader | Display that there is no bootloader and set SMC to Issue. | Issue
SD2 | SMC chip not detected | Display that the SMC chip is not detected and set SMC to Error. | Error
SD3 | Bootloader version not supported | Display that the current bootloader is not supported and set SMC to Issue. | Issue
SD4 | SMC chip was detected and bootloader ok | Display SMC chip version and bootloader version and set SMC to Check. | Check

## RD - ROM chip Detection.
ID | Test Case | Action Description | Error Level
--- | --- | --- | ---
RD1 | Known ROM chip device ID | Display ROM chip firmware release number and github commit ID if in hexadecimal format and set to Check. | None
RD2 | Unknown ROM chip device ID | Don't do anything and set to None. | None

## RF - ROM.BIN file consistency, when SMC Detected and CX16 ROM Detected and SMC.BIN on SDcard.

ID | Test Case | Action Description | Error Level
--- | --- | --- | ---
RF1 | no ROM.BIN  | Ask the user to place the ROM.BIN file onto the SDcard. Set ROM to Issue. | Issue
RF2 | ROM.BIN size 0 | Ask the user to place a correct ROM.BIN file onto the SDcard. Set ROM to Issue. | Issue
RF3 | ROM.BIN size not % 0x4000 | Ask the user to place a correct ROM.BIN file onto the SDcard. Set ROM to Issue. | Issue
RF4 | ROM.BIN size over 0x80000 | Ask the user to place a correct ROM.BIN file onto the SDcard. Set ROM to Issue. | Issue
RF5 | ROM.BIN all ok | Display the ROM.BIN release version and github commit id (if any) and set ROM to Flash | Flash


## SF - SMC.BIN file consistency, when SMC Detected and CX16 ROM Detected and ROM.BIN on SDcard.

ID | Test Case | Action Description | Error Level
--- | --- | --- | ---
SF1 | no SMC.BIN | Ask user to place an SMC.BIN file onto the SDcard and don't flash. | Issue
SF2 | size SMC.BIN is 0 | Ask user to place an SMC.BIN file onto the SDcard and don't flash. | Issue
SF3 | size SMC.BIN is > 0x1E00 | Display SMC.BIN file size issue and don't flash. Ask the user to place a correct SMC.BIN file onto the SDcard. | Issue
SF4 | SMC.BIN and all ok | Display the SMC.BIN file version and set SMC to Flash. | Flash

## VA - Additional Validations before Flashing

ID | Test Case | Action Description | Error Level
--- | --- | --- | ---
VA1 | Version of SMC and SMC.BIN equal | Display that the SMC and SMC.BIN versions are equal and no flashing is required. Set SMC to Skip. | None
VA2 | SMC.BIN does not support ROM.BIN release | Display warning that SMC.BIN does not support the ROM.BIN release. Ask for user confirmation to continue flashing Y/N. If the users selects not to flash, set both the SMC and the ROM as an Issue and don't flash. | Issue
VA3 | SMC.BIN and CX16 ROM not Detected | Display issue and don't flash. Ask to close the J1 jumper pins on the CX16 main board. | Issue
VA4 | SMC is Flash and CX16 is not Flash | Display CX16 ROM update issue and don't flash. | Issue
VA5 | SMC is not Flash and CX16 is Flash | Display SMC update issue and don't flash. | Issue
VA6 | no SMC.BIN and no CX16 ROM.BIN | No action for flashing. Both SMC and CX16 ROM should be set to Skip. | None
VA99 | One of the components is Flash | Request to continue with flashing from the user Y/N. | None

## SF - Flash SMC, when SMC is Flash and CX16 ROM is Flash

ID | Test Case | Action Description | Error Level
--- | --- | --- | ---
SFL1 | POWER/RESET pressed | Read the SMC.BIN again. Set SMC bootloader to wait, and ask POWER/RESET buttons to be pressed simultaneously. When user presses buttons, flash SMC and set SMC to Flashing. When finished, set SMC to Flashed. | None
SFL2 | no action on POWER/RESET press request | Read the SMC.BIN again. Set SMC bootloader to wait, and ask POWER/RESET buttons to be pressed simultaneously. When user does not press the POWER/RESET buttons, exit the process, reset the bootloader. Display warning that POWER/RESET was not flashed in time, and set SMC to Issue. | Issue
SFL3 | errors during flash | Read the SMC.BIN again. Set SMC bootloader to wait, and ask POWER/RESET buttons to be pressed simultaneously. When user presses buttons, flash SMC. When the flash returns with 0xFFFFFFFF, set SMC to Error. | Error

## RF - Flash ROM(s) when ROM(s) is Flash

ID | Test Case | Action Description | Error Level
--- | --- | --- | ---
RFL1 | ROM and ROM.BIN equal | Display that there are no differences between the ROM and ROM.BIN. Set ROM to Skipped. | None
RFL2 | Flash ROM resulting in errors | Display ROM differences. Flash the ROM and set ROM to Flashing. When the ROM flash results with errors, display Flash errors and set ROM to Error | Error
RFL3 | Flash ROM and all ok | Display ROM differences. Flash the ROM and set ROM to Flashing. When the ROM flash is ok, set ROM to Flashed | None

## DE - Debrief update results and reset actions

ID | Test Case | Action Description | Error Level
--- | --- | --- | ---
DE1 | All components skipped | Display the update has been cancelled. Reset the CX16. | None
DE2 | There is an Error with one of the components | Display the update has resulted in an error, and explain the severity of the result. Ask the user to take a digital picture of the CX16 display. Set border to red and go in endless loop. | Error
DE3 | There is an Issue with one of the components | Display the issue, which could be due to Detection results, File Checking results, Validation results, Flashing results. Set border to yellow and reset the system automatically.
DE4 | The components correctly updated, SMC bootloader 1 | Display success, set border to Green. Display message that power must be shut down and manual restart of the CX16 is required. | None
DE5 | The components correctly updated, SMC bootloader 2 | Display success, set border to Green. Shut down CX16 automatically. | None
DE6 | Wait until reset | In the cases where the debrief does not result in a hang or an endless loop, the CX16 will reset after the wait time. | None
DE7 | Reset SMC when bootloader v1 | When the SMC contains bootloader 1, reset once the flash is a succes! This will prevent an unbootable CX16 when the user disconnects from power too early! | None

