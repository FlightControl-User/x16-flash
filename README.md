# --- WORK IN PROGRESS ---

# Commander X16 Flashing Utility

Contains the source code of the commander x16 update utility.
This utility allows you to upgrade (or downgrade) your CX16 on-board SMC firmware and main ROM, and/or, to flash external ROMs installed on a cartridge board.

Please see below for a short user manual.

## Notice of caution

Updating your on-board firmware requires you to carefully follow the instructions. There is a small risk that your on-board firmware may get damaged during the update process and may generate your CX16 unusable, resulting in a bricked CX16!

Further steps to mitigate and recover from such situations are pending to be documented. However, please direct youself in such situations to the Commander X16 [Discord](https://discord.gg/nS2PqEC) or [Forum](https://www.commanderx16.com/forum)!

# User Manual

Please consider this draft user manual as a first guide how to use the update tool.

## 0. What you need

Depending on your configuration and the new release artefacts available from the CX16 community site,  
specific hardware on your CX16 board will be updated. But in essence, the update should be fairly straightforward and user friendly!

- Ensure you have a valid and working SDCARD that has sufficient free space and is formatted in FAT32.
- You need a Commander X16 computer (the real thing).
- You optionally can have an add-on cartridge board, that is plugged in any of the 4 expansion slots. This RAM/ROM board can contain an extra 3.5 MB of RAM/ROM!

On the Commander X16 main board, you have 3 important compontents that this utility can update with new firmware:

- The **SMC** : This microcontroller handles your mouse, keyboard and timer. It is essential to boot your CX16.
- The **VERA** : This FPGA made by Frank Van den Hoef, handles the CX16 graphics and the SDCard operations.
- The **ROM** : The main CX16 ROM contains the DOS and KERNAL to run your CX16.

## 1. Download the program

The latest version of the program can be found on the [release page](https://github.com/FlightControl-User/x16-flash/releases) of this repository. Search for the file CX16-UPDATE.PRG and download the file. Copy the program into a directory of your SDCARD. You will run this program on your CX16 hardware. Ensure the file is copied onto the SDcard with the file name in CAPITAL letters.

## 2. Download the Commander X16 community firmware release files from the web site.

Download the latest SMC.BIN, VERA.BIN and ROM.BIN file from the Commander X16 community web sites. Any additional ROMs on the expansion card to be updated, require ROMn.BIN files to be added, according your rom update strategy.

- [SMC.BIN from the CX16 update tool release page](https://github.com/FlightControl-User/x16-flash/releases)
- [VERA.BIN from the VERA Release page](https://github.com/X16Community/vera-module/releases)
- [ROM.BIN from the ROM Release page](https://github.com/X16Community/x16-rom/releases)

Notes: 
-  SMC Release page is not yet containing the correct SMC.BIN files, so download from the CX16 update tool release page. Therefore, the CX16 update tool release page contains the SMC.BIN artefacts.
- The names of the artefacts can differ a bit. They might contain the release number of version number. Always rename the files to the correct name!

### 2.1. Update your SMC, VERA.BIN and main ROM firmware on your CX16 board

Copy the SMC.BIN, VERA.BIN and the ROM.BIN files on the SDcard at the same folder fro where your CX16-UPDATE.PRG file is located. Ensure the files are copied onto the SDcard with the file names in **CAPITAL** letters.

Ensure that the J1 jumper pins on the Commander X16 main board are closed, to remove the write protection of the on-board ROM. If the J1 jumper pins are not closed, the onboard ROM will not be recognized by the 
update utility and an issue will be reported by the software!

![ROM-onboard-dip](https://user-images.githubusercontent.com/13690775/225110062-8081d0a6-079a-405a-b03a-ab2f482fbfff.jpg)

Once you have the J1 jumper pins properly closed, the ROM on the main board of the Commander X16 will be detected by the update utility.

Ensure that the J5 jumper pins on the Commander X16 main board are closed, to ensure that no issue occurs reading the contents of the SMC chipset. The update utility can flash the SMC with the J5 jumper pins open, but to ensure that no issue occurs, it is safer to have them also closed.

### 2.2. Flash multiple ROMs on the external RAM/ROM board or cartridge.

First for all clarity, find below a picture of such a ROM expansion cartridge:

![ROM-cartridge](https://user-images.githubusercontent.com/13690775/225110167-546596e6-998a-464f-b6a9-53fb598c19b4.jpg)

On the ROM cartridge, 7 extra RAM/ROM chips can be placed for usage, and flashing. The cartridge is placed in one of the 4 CX16 extension slots, and provides an extra 3.5 MB of banked RAM/ROM to your CX16 between addresses $C000 and $FFFF, with zeropage $01 as the bank register. Each bank has $4000 bytes!

Each ROM is addressing wise 512K separated from each other, and can be flashed with its own ROM[N].BIN file(s), where N must be a number between 1 and 7! For example, ROM1.BIN will flash ROM#1 on the cartridge. ROM5.BIN will flash ROM#5. ROM devices are to be placed and counted, from left to right!

To ensure that no harmful program can damage your ROMs, jumper pins J1 and J2 on the cartridge are to be remained open. However, in order to flash the ROMs, close the relevant jumper pins.

Close the J1 jumper pins (at the left side of the cartridge board) to remove the write-protection for ROM#1 till ROM#6.

![ROM-DIP-J1](https://user-images.githubusercontent.com/13690775/225111120-56eeaca5-69a6-4812-a854-5cfc1246045a.jpg)

Close the J2 jumper pins (at the right side of the cartridge board) to remove the write-protection for ROM#7.

![ROM-DIP-J2](https://user-images.githubusercontent.com/13690775/225111150-c441812c-5331-46b1-805f-f769064507f7.jpg)

Once you have the J1 and/or J2 jumper pins properly closed on the cartridge board, the ROMs will be detected by the flashing program. If the jumper pins are open, the ROMs won't be recognized by the flashing program and your ROM[n].BIN file(s) will not be flashed!

## 3. Proceed with updating your Commander X16 firmware or ROMs.

Once you've copied the CX16-UPDATE.PRG and the relevant SMC.BIN and ROM[N].BIN files onto the SDcard, you are ready to update your Commander X16!

Place the SDcard in the VERA card slot, and again, verify that all indicated J1 and J5 jumper pins are closed properly on the Commander X16 main board and optionally on the cartridge board.

Boot/Start your Commander X16 computer.

Your Commander X16 startup screen might look like this ...

<img width="242" alt="FLASH-DOS" src="https://user-images.githubusercontent.com/13690775/225111204-88051585-ecb7-4614-8374-ba4de2623d43.png">

Load the program and run it, follow a small guide as described below.

  1. DOS "CD:folder" - Optionally ensure that you navigate to the right folder on the SDcard where you copied all the files using DOS "CD:folder" commands.
  2. LOAD "CX16-UPDATE.PRG",8
  3. RUN

The update utility will walk you through the update process in a very user friendly way.
At first 2 introduction screens are shown. Once those screens have been read and understood, the actual update process can commence.
The update utility detects each chipset and its properties. It will read each file, and will verify the contents of the file in terms of file presence, file size and contents. Once these checks are executed and everything is fine, the update process can proceed for the identified Commander X16 components to be updated. And finally, a debriefing screen is shown with the result of the update process. Depending on the type of components updated, different reboot actions will take place.

Please find below a detailed description of the complete process.

### 3.1. Introduction and briefing screens

You will see a first screen, which introduces the update process. The top shows the title of the utility.
Below are all the possible components shown that this update utility supports. Above each component, a led is shown that will light up in different colors indicating the status of the upgrade progress. Below the components is an overview shown of each chipset and its properties. Totally on the right of each line will show a short indication with additional information or issue, or even an error situation with the component during the process. In the middle of the screen are two lines shown that indicate the step of the overall flow of thee update process and an action line or additional information of the update action in progress. And at the bottom is an information pane, that shows additional textual or graphical information of the update action awaiting or being executed.


![into-1](https://github.com/FlightControl-User/x16-flash/blob/main/images/intro-1.jpg)

Please carefully read the text at the bottom panel of the screen, and press SPACE to continue ...

A second screen appears, which indicates the color schema used to indicate the update status of each component on your Commander X16 main board and/or your expansion cartridge board. Press SPACE to continue.

![intro-2](https://github.com/FlightControl-User/x16-flash/blob/main/images/intro-2.jpg)


### 3.2. Component detection

Next, the update utility detects which components are upgradable. The Commander X16 main board SMC, VERA and main ROM chip are detected, together with the remaining 7 ROM chips (the most right chip is ROM#7), which would be the right most chip on the expansion cartridge.

Each component detected will be highlighted with a Detected status and a WHITE led. The capacity of each detected ROM is shown in KBytes. Other components that are not detected are highlighed with a None staus and a BLACK led. These ROMs won't be considered for flashing.

![detected](https://github.com/FlightControl-User/x16-flash/blob/main/images/detected.jpg)

Note again, that ROMs that can be flashed, but which don't have the jumper pins closed, won't be detected and will be skipped!

Once all components have been detected, it will validate each file.
For each flashable ROM, the program will look for a related ROM[N].BIN file. 

If there is no file found, a message is shown to the user and this ROM will be skipped. The ROM will be highlighted with a GREY led. 

Otherwise, the ROM[N].BIN file will be loaded from the SDcard into low and high RAM.

### 3.2. ROM[N].BIN file load

The loading process is seamless, if there is a file, each byte in the file is loaded into low and high RAM. The first $4000 bytes are loaded in low RAM, while the remainder of the ROM[N].BIN file is loaded in high RAM. This is nothing for you to be concerned about, just explaining how the program works. But note that a ROM[N].BIN file that is 512KB large, will be fully loaded into RAM on the Commander X16!

<img width="634" alt="FLASH-LOAD" src="https://user-images.githubusercontent.com/13690775/225111367-df29cf5b-eeeb-4c5a-8a2a-1366345086a8.png">

Each $100 bytes loaded will be shown on the screen as a '.' in the memory matrix. Each row in the matrix represents $4000 bytes. There are $40 possible blocks of $100 bytes each in each row. A ROM can have a maximum of 512K, so there are maximum 32 rows possible to be shown in the matrix.

The ROM address ranges being processed are shown. The first column shows the ROM bank being processed, while the 2nd column indicates the "relative" ROM addres for each row. 

Loading and Comparing in progress is highlighted with a CYAN led on top of the ROM chip. 

### 3.3. ROM[N].BIN file changes

Once the ROM[N].BIN file has been loaded into RAM, the program will compare the RAM contents with the ROM contents.

<img width="642" alt="FLASH-CHANGES" src="https://user-images.githubusercontent.com/13690775/225111444-a87165cb-891c-4d63-a2a7-f6370c73c94d.png">

Equal blocks are shown with a '.', while different blocks are shown with a '*'. This provides the user a good idea of where the changes are, and more important, in which ROM banks!

Loading and Comparing in progress is highlighted with a CYAN led on top of the ROM chip. 

### 3.4. ROM[N].BIN file flashing

Once the user understands the changes and wants to continue with flashing, a key needs to be pressed.

The flashing is straightforward, but there is something that needs to be explained. The program will only flash the areas that have changes, and tries to do this in the most efficient way. Unfortunately, before flashing a byte in the ROM, the program need to execute an erase process for each byte that has changed in a 4K block. 

<img width="642" alt="FLASH-INPROGRESS" src="https://user-images.githubusercontent.com/13690775/225111500-4157374a-2e25-4f0d-9574-e7479cee0ae1.png">

So in other words, areas of 4K that are unchanged will be skipped, but if there are areas where 1 bit of a whole 4K block has changed, then this whole 4K block will be reased and re-flashed.

A 4K block being erased is indicated with ".". Each block of $100 bytes that is flashed is also verified to ensure that the ROM has correctly processed the flash!

Blocks of $100 bytes that have been correctly flashed, are indicated with a "+". Blocks of $100 bytes that have been skipped, are indicated with "-".

$100 byte blocks that have errors (after 3x retry) are indicated with a "!". Note that in the case of errors, it is highly likely that your ROM needs to be replaced and an emergency procedure is to be started.

Flashing in progress is highlighted with a PURPLE led. 

Successful flashed ROMs are highlighted with a GREEN led. 

Faulty flashed ROMs are highlighted with a RED led.

### 3.5. Each of the identified ROMs will be flashed

Once the ROM has been flashed, the next identified ROM is considered flashing, which has a lower sequence number than the one flashed. The last ROM that is considered for flashing is the on-board ROM (if identified).

### End of the flashing process

If there are no more ROMs identified to be flashed, the program will reset automatically.

<img width="642" alt="FLASH-RESET" src="https://user-images.githubusercontent.com/13690775/225111551-1df63cad-7c16-4aaf-a793-c6d29defeb16.png">

## Testing and next steps

Ensure that your ROM has been correctly flashed by testing your program or testing the onboard rom upgrade!

If you have an issue after a ROM upgrade, you always have the possibility to downgrade the ROM version if needed by reflashing an older version of a ROM.BIN file. However, since ROMs cannot be endlessly re-flashed it is highly recommended to first test your programs using the available emulators.






The identified ROMs for flashing will be flashed from the highest ROM# number to the lowest ROM number. The last ROM that is considered for flashing is the on-board ROM.

The reason why this sequence was chosen, is to ensure that the program has the ROM routines available for allowing the user to view the flashing results and press the keyboard to continue the process.

Once the onboard ROM has been flashed, the program will automatically reset the computer.

Please find in more details this sequence explained visually, with an explanation of the screens and the meaning of the symbols/colors.
