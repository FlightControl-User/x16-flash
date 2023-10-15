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

- Ensure you have a valid and working SD card that has sufficient free space and is formatted in FAT32.
- You need a Commander X16 computer (the real thing).
- You optionally can have an add-on cartridge board, that is plugged in any of the 4 expansion slots. This RAM/ROM board can contain an extra 3.5 MB of RAM/ROM!

On the Commander X16 main board, you have 3 important compontents that this utility can update with new firmware:

- The **SMC** : This microcontroller handles your mouse, keyboard and timer. It is essential to boot your CX16.
- The **VERA** : This FPGA made by Frank Van den Hoef, handles the CX16 graphics and the SD card operations.
- The **ROM** : The main CX16 ROM contains the DOS and KERNAL to run your CX16.

## 1. Download the program

The latest version of the program can be found on the [release page](https://github.com/FlightControl-User/x16-flash/releases) of this repository. Search for the file CX16-UPDATE.PRG and download the file. Copy the program into a directory of your SD card. You will run this program on your CX16 hardware. Ensure the file is copied onto the SD card with the file name in CAPITAL letters.

## 2. Download the Commander X16 community firmware release files from the web site.

Download the latest SMC.BIN, VERA.BIN and ROM.BIN file from the Commander X16 community web sites. Any additional ROMs on the expansion card to be updated, require ROMn.BIN files to be added, according your rom update strategy.

- [SMC.BIN from the CX16 update tool release page](https://github.com/FlightControl-User/x16-flash/releases)
- [VERA.BIN from the VERA Release page](https://github.com/X16Community/vera-module/releases)
- [ROM.BIN from the ROM Release page](https://github.com/X16Community/x16-rom/releases)

Notes: 
-  The SMC Release page is not yet containing the correct SMC.BIN files, so download from the CX16 update tool release page. Therefore, the CX16 update tool release page contains the SMC.BIN artefacts.
- The names of the artefacts can differ a bit. They might contain the release number of version number. Always rename the files to the correct name!


## 3. Explanations of the update process.

### 3.1. Copy the files on the SD card.

Copy the SMC.BIN, VERA.BIN and the ROM.BIN files on the SD card at the same folder fro where your CX16-UPDATE.PRG file is located. Ensure the files are copied onto the SD card with the file names in **CAPITAL** letters.

### 3.2. Main CX16 ROM J1 jumper pins: CLOSED!

![CX16-J1](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/CX16-J1.jpg)

Ensure that the J1 jumper pins on the Commander X16 main board are **closed**, to **remove the write protection** of the main CX16 ROM.  
If the J1 jumper pins are **not closed**, the **main CX16 ROM will not be detected** by the update utility and an issue will be reported by the software!

### 3.3. SMC J5 jumper pins: CLOSED!

![CX16-J5](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/CX16-J5.jpg)

Ensure that the J5 jumper pins on the Commander X16 main board are **closed**. If the J5 jumper pins are not closed, the keyboard won't be functional!

### 3.4. VERA JP1 jumper pins: OPEN!

![VERA-JP1-OPEN](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/VERA-JP1-OPEN.jpg)

At the start position, before the update process, ensure that the JP1 jumper pins on the VERA board are **open**! (Picture above)

![VERA-JP1-CLOSED](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/VERA-JP1-CLOSED.jpg)

During the update process, the program will ask you to place a jumper cap, **closing** the JP1 jumper pins. 

Once the VERA memory has been updated, the program will ask you to remove the JP1 jumper cap, opening the pins again.

**Note that this will happen during the update process and it is crucial that you follow carefully the instructions given by the program!**

### 3.5. Flash multiple ROMs on the external RAM/ROM board or cartridge.

First for all clarity, find below a picture of such a ROM expansion cartridge:

![ROM-CARD](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/ROM-CARD.jpg)

On the ROM cartridge, 7 extra RAM/ROM chips can be placed for usage, and can be updated using this program. The cartridge is placed in one of the 4 PCI extension slots on the CX16 main board, and provides an extra 3.5 MB of banked RAM/ROM to your CX16 between addresses $C000 and $FFFF, with zeropage $01 as the bank register. Each bank has $4000 bytes!

Each ROM is addressing wise 512K separated from each other, and can be flashed with its own ROM*n*.BIN file(s), where *n* must be a number between 1 and 7! 

For example, `ROM1.BIN` will flash ROM#1 on the cartridge. `ROM5.BIN` will flash ROM#5. ROMs are to be counted from left to right!

To ensure that no harmful program can damage your ROMs, jumper pins J1 and J2 on the cartridge are to be remained **open**. In order to flash the ROMs, **close** the relevant jumper pins!

![ROM-CARD-J1-CLOSED](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/ROM-CARD-J1-CLOSED.jpg)

 - **Close** the J1 jumper pins (at the left side of the cartridge board) to remove the write-protection for ROM#1 till ROM#6.

![ROM-CARD-J2-CLOSED](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/ROM-CARD-J2-CLOSED.jpg)

 - **Close** the J2 jumper pins (at the right side of the cartridge board) to remove the write-protection for ROM#7.

Once you have the J1 and/or J2 jumper pins properly closed on the cartridge board, the ROMs will be detected by the flashing program. If the jumper pins are open, the ROMs won't be recognized by the flashing program and your ROM*n*.BIN file(s) will not be flashed!

## 4. Update checklist for the Commander X16.

Please consolidate the following checklist before you commence running the program:


## 4.0 Needed materials checklist:

  Ensure that you have in total 6 standard [computer jumper caps](https://www.amazon.com/s?k=computer+jumper+caps&crid=30ZIZP22RVD1R&sprefix=computer+jumper+caps%2Caps%2C169&ref=nb_sb_noss_1) available. These are needed to close:

  - 1 x jumper cap for the J1 jumper pins on the CX16 main board.
  - 2 x jumper caps for the J5 jumper pins on the CX16 main board.
  - 1 x jumper cap for the JP1 jumper pins on the VERA board.
  - 2 x jumper caps for the J1 and J2 jumper pins on the external ROM cardridge board.


## 4.1 SMC update checklist:

  1. Is the **version** of the `SMC.BIN` correct?
  2. Has the file been **copied** onto your SD card?
  3. Is the file named `SMC.BIN` in **capital** letters?
  4. Are the J5 jumper pins **closed** on the CX16 main board?


## 4.2 VERA update checklist:

  1. Is the **version** of the `VERA.BIN` correct?
  2. Has the file been **copied** onto your SD card?
  3. Is the file named `VERA.BIN` in **capital** letters?
  4. Do you have a jumper pin **connector** at your disposal?  
  You will need it to close the JP1 pins on the VERA board.  
  5. Are the **JP1 jumper pins open** on the **VERA board**?
  6. Have you understood why the JP1 jumper pins need to be closed and when it will be asked to close them?
  7. Have you understood why the JP1 jumper pins need to be opened again when the VERA memory has been updated? 

## 4.3 Main CX16 ROM checklist:

  1. Is the **version** of the `ROM.BIN` correct?
  2. Has the file been **copied** onto your SD card?
  3. Is the file named `ROM.BIN` in **capital** letters?
  4. Are the **J1 jumper pins** on the CX16 main board **closed**?

## 4.4 External CX16 ROMs update checklist:

  1. Are the **version** of the `ROMn.BIN` file(s) correct?  
  2. Has(ve) the file(s) been **copied** onto your SD card?
  3. Have the file(s) been named `ROMn.BIN` in **capital** letters, with the *n* being a number from 1 to 7?
  4. For the **ROMs 1 to 6** on the cardridge, are the **J1 jumper pins closed**?
  5. For the **ROM 7** on the cardridge, are the **J2 jumper pins closed**?
  
# 5. Start the CX16 update.

Place the SD card in the CX16 (VERA) card slot.  

Boot/Start your Commander X16 computer.

Type `LOAD CX16-UPDATE.PRG` or press `F7` on the keyboard (`DOS"$"`) and put the cursor in front of the program, then press `F3` on the keyboard (`LOAD`).

Type `RUN` or press `F5` on the keyboard.

# 6. Main flow of the CX16 update utility:

The update utility is very user friendly and walks you through the different steps.
Please find below a detailed description of the complete process.

## 6.1. Introduction and briefing screens

![Into-1](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/INTRO1.jpg)

At program start, you will see an introduction screen, introducing the update process. 

Please carefully read the text at the bottom panel of the screen, and press SPACE to continue ...

![Into-1](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/INTRO2.jpg)

A second screen appears, which indicates the color schema used to indicate the update status of each component on your Commander X16 main board and/or your expansion cartridge board. Press SPACE to continue.

### 6.2. Component detection

Next, the update utility detects which components are upgradable and will validate which files are found on the SD card. 

![FLASH-DETECT](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/FLASH-DETECT.jpg)

The Commander X16 main board SMC, VERA and main ROM chip are detected, together with the external cardridge 7 ROM chips.

- Each component detected will be highlighted with a Detected status and a **WHITE** led. The capacity of each detected ROM is shown in KBytes. 

- Other components that are not detected are highlighed with a None staus and a **BLACK** led. These ROMs won't be considered for flashing.

### 6.3. File presence and validation

After component detection, the program will immediately search for file presence for **each detected component** and will validate it.

![FLASH-CHECK](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/FLASH-CHECK.jpg)

The program will read each file and check on data size and any validation content to be used before flashing. 

- Detected and valid files will result in the status of the component in a **PURPLE** led and status `Update`.

- Files that are not present, will result in the component not to be updated. The component will get a GREY led and status `skipped`.

### 6.4 Pre-Update conditions.

Before the update commences, there are important conditions vaidated to ensure that any upgrade file or component compatibility risk or issues, potentially corrupting your CX16, are properly mitigated.

![SMC-ROM-COMPATIBILITY](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/SMC-ROM-COMPATIBILITY.jpg)


1. SMC and ROM must be flashed together: To avoid an SMC update corrupting your CX16 because it is not supportive or compatible with your ROM. The SMC file contains flags to ensure the compatibility between the SMC and the ROM.

2. An SMC not detected will stop the update process.

3. The main CX16 ROM not detected will stop the update process.

![UPDATE-CONFIRM](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/UPDATE-CONFIRM.jpg)

When there are no issues, the user is asked for a confirmation to proceed with the update:

 - Replying `N` will cancel the update. 
 - Replying `Y` will proceed with the update!

## 7. The update process, updating your components

The program will update each component that has status `Update`.

The program will read the firmware data into memory first, and will then commence with the update process, updating your component.

However, the update process differs for each component type, so please read carefully the below explanation:

### 7.1. Update the SMC

The SMC update is straightforward. 

It will first read the `SMC.BIN` into internal memory.



Then, the program asks you to press the `POWER` and the `RESET` button at the same time on the CX16 board.

![FLASH-CHECK](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/FLASH-CHECK.jpg)

Do so on the CX16 board.


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
