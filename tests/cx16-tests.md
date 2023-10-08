# List of all test scenarios and expected results.

## SD - SMC chip Detection.

ID | Test Case | Action Description | Error Level
--- | --- | --- | ---
SD-1 | No Bootloader | Display that there is no bootloader and set SMC to Issue. | Issue
SD-2 | SMC chip not detected | Display that the SMC chip is not detected and set SMC to Error. | Error
SD-3 | Bootloader version not supported | Display that the current bootloader is not supported and set SMC to Issue. | Issue
SD-4 | SMC chip was detected and bootloader ok | Display SMC chip version and bootloader version and set SMC to Check. | Check

## RD - ROM chip Detection.
ID | Test Case | Action Description | Error Level
--- | --- | --- | ---
RD-1 | Known ROM chip device ID | Display ROM chip firmware release number and github commit ID if in hexadecimal format and set to Check. | None
RD-2 | Unknown ROM chip device ID | Don't do anything and set to None. | None

## RF - ROM.BIN file consistency, when SMC Detected and CX16 ROM Detected and SMC.BIN on SDcard.

ID | Test Case | Action Description | Error Level
--- | --- | --- | ---
RF-1 | no ROM.BIN  | Ask the user to place the ROM.BIN file onto the SDcard. Set ROM to Issue. | Issue
RF-2 | ROM.BIN size 0 | Ask the user to place a correct ROM.BIN file onto the SDcard. Set ROM to Issue. | Issue
RF-3 | ROM.BIN size not % 0x4000 | Ask the user to place a correct ROM.BIN file onto the SDcard. Set ROM to Issue. | Issue
RF-4 | ROM.BIN size over 0x80000 | Ask the user to place a correct ROM.BIN file onto the SDcard. Set ROM to Issue. | Issue
RF-5 | ROM.BIN all ok | Display the ROM.BIN release version and github commit id (if any) and set ROM to Flash | Flash


## SF - SMC.BIN file consistency, when SMC Detected and CX16 ROM Detected and ROM.BIN on SDcard.

ID | Test Case | Action Description | Error Level
--- | --- | --- | ---
SF-1 | no SMC.BIN | Ask user to place an SMC.BIN file onto the SDcard and don't flash. | Issue
SF-2 | size SMC.BIN is 0 | Ask user to place an SMC.BIN file onto the SDcard and don't flash. | Issue
SF-3 | size SMC.BIN is > 0x1E00 | Display SMC.BIN file size issue and don't flash. Ask the user to place a correct SMC.BIN file onto the SDcard. | Issue
SF-4 | SMC.BIN and all ok | Display the SMC.BIN file version and set SMC to Flash. | Flash

## VA - Additional Validations before Flashing

ID | Test Case | Action Description | Error Level
--- | --- | --- | ---
VA-1 | Version of SMC and SMC.BIN equal | Display that the SMC and SMC.BIN versions are equal and no flashing is required. Set SMC to Skip. | None
VA-2 | SMC.BIN does not support ROM.BIN release | Display warning that SMC.BIN does not support the ROM.BIN release. Ask for user confirmation to continue flashing Y/N. If the users selects not to flash, set both the SMC and the ROM as an Issue and don't flash. | Issue
VA-3 | SMC.BIN and CX16 ROM not Detected | Display issue and don't flash. Ask to close the J1 jumper pins on the CX16 main board. | Issue
VA-4 | SMC is Flash and CX16 is not Flash | Display CX16 ROM update issue and don't flash. | Issue
VA-5 | SMC is not Flash and CX16 is Flash | Display SMC update issue and don't flash. | Issue
VA-99 | One of the components is Flash | Request to continue with flashing from the user Y/N. | None

## SF - Flash SMC, when SMC is Flash and CX16 ROM is Flash

ID | Test Case | Action Description | Error Level
--- | --- | --- | ---
SF-1 | POWER/RESET pressed | Read the SMC.BIN again. Set SMC bootloader to wait, and ask POWER/RESET buttons to be pressed simultaneously. When user presses buttons, flash SMC and set SMC to Flashing. When finished, set SMC to Flashed. | None
SF-2 | no action on POWER/RESET press request | Read the SMC.BIN again. Set SMC bootloader to wait, and ask POWER/RESET buttons to be pressed simultaneously. When user does not press the POWER/RESET buttons, exit the process, reset the bootloader. Display warning that POWER/RESET was not flashed in time, and set SMC to Issue. | Issue
SF-3 | errors during flash | Read the SMC.BIN again. Set SMC bootloader to wait, and ask POWER/RESET buttons to be pressed simultaneously. When user presses buttons, flash SMC. When the flash returns with 0xFFFFFFFF, set SMC to Error. | Error

## RF - Flash ROM(s) when ROM(s) is Flash

ID | Test Case | Action Description | Error Level
--- | --- | --- | ---
RF-1 | ROM and ROM.BIN equal | Display that there are no differences between the ROM and ROM.BIN. Set ROM to Flashed. | None
RF-2 | Flash ROM resulting in errors | Display ROM differences. Flash the ROM and set ROM to Flashing. When the ROM flash results with errors, display Flash errors and set ROM to Error | Error
RF-3 | Flash ROM and all ok | Display ROM differences. Flash the ROM and set ROM to Flashing. When the ROM flash is ok, set ROM to Flashed | None

## DE - Debrief update results and reset actions

ID | Test Case | Action Description | Error Level
--- | --- | --- | ---
DE-1 | All components skipped | Display the update has been cancelled. Reset the CX16. | None
DE-2 | There is an Error with one of the components | Display the update has resulted in an error, and explain the severity of the result. Ask the user to take a digital picture of the CX16 display. Set border to red and go in endless loop. | Error
DE-3 | There is an Issue with one of the components | Display the issue, which could be due to Detection results, File Checking results, Validation results, Flashing results. Set border to yellow and reset the system automatically.
DE-4 | The components correctly updated, SMC bootloader 1 | Display success, set border to Green. Display message that power must be shut down and manual restart of the CX16 is required. | None
DE-5 | The components correctly updated, SMC bootloader 2 | Display success, set border to Green. Shut down CX16 automatically. | None
DE-6 | Wait until reset | In the cases where the debrief does not result in a hang or an endless loop, the CX16 will reset after the wait time. | None

