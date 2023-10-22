# --- WORK IN PROGRESS ---

# Commander X16 update program

This program allows you to upgrade (or downgrade) the firmware of your CX16 internal and external components in a very user friendly way and with minimal preparations and/or manual actions during the update process:

| Component | Location | Purpose | File(s) | Size |
| --- | --- | --- | --- | --- |
| **VERA**  | internal CX16 board | This FPGA made by Frank Van den Hoef, handles the CX16 - graphics and the SD card operations | `VERA.BIN` | 128KB |
| **VERA**  | external VERA cardridge | This cardridge allows to connect an extra monitor to your CX16, and has a separate graphics engine! | `VERA1.BIN` | 128KB |
| **SMC**   | internal CX16 board | This microcontroller handles your mouse, keyboard and timer. It is essential to boot your CX16. | `SMC.BIN` | 2KB |
| **ROM**   | internal CX16 board | The main CX16 ROM contains the DOS and KERNAL to run your CX16. | `ROM.BIN` | 512KB |
| **ROM** | external CX16 cardridge |  This cardridge allows you to extend the memory of your CX16 with (7) extra ROM or RAM ICs, fitted into a PCI slot on your CX16 board. | `ROMn.BIN` | 7x512KB |

**Please note that there are Manual Actions or Preparations needed to update your CX16 components! So don't just run this program but first carefully read this User Manual!**

# Table of contents:

1 [User Manual](#1-user-manual)
2 [Run the CX16 update program](#2-run-the-cx16-update-program)
3 [Issues and Resolutions](#3-issues-and-resolutions)
4 [Recovery from a bricked CX16](#4-recovery-procedures-from-a-bricked-cx16)


# Notice of caution

Updating your on-board firmware requires you to carefully follow the instructions. There is a small risk that your on-board firmware may get damaged during the update process and may generate your CX16 unusable, resulting in a bricked CX16!

Further steps to mitigate and recover from such situations is always possible. However, these actions are pending to be documented. Please direct youself in such situations to the Commander X16 [Discord](https://discord.gg/nS2PqEC) or [Forum](https://www.commanderx16.com/forum)!

# 1 User Manual

Please consider this draft user manual as a first guide how to use the update program.

## 1.0 What you need

Depending on your configuration and the new released artefacts available from the CX16 community site,  
specific hardware on your CX16 board will be updated. But in essence, the update should be fairly straightforward and user friendly!

1. Ensure you have a valid and working SD card that has sufficient free space and is formatted in FAT32.
2. You need a Commander X16 computer (the real thing).
3. You optionally can have an add-on cartridge board, that is plugged in any of the 4 expansion slots. This RAM/ROM board can contain an extra 3.5 MB of RAM/ROM!
4. Ensure that you have in total 6 standard [computer jumper caps](https://www.amazon.com/s?k=computer+jumper+caps&crid=30ZIZP22RVD1R&sprefix=computer+jumper+caps%2Caps%2C169&ref=nb_sb_noss_1) available:
    - 1 x jumper cap for the J1 jumper pins on the CX16 main board.
    - 2 x jumper caps for the J5 jumper pins on the CX16 main board.
    - 1 x jumper cap for the JP1 jumper pins on the VERA board.
    - 2 x jumper caps for the J1 and J2 jumper pins on the external ROM cardridge board.

That's it!

## 1.1 Download the program

The latest version of the program can be found on the [release page](https://github.com/FlightControl-User/x16-flash/releases) of this repository. Please read through the release notes for any specific actions!

- Search for the file CX16-UPDATE.PRG and download the file. 
- Copy the program into a directory of your SD card. 
- You will run this program on your CX16. 
- Ensure the file is copied onto the SD card with the file name in CAPITAL letters.

## 1.2 Download the Commander X16 community firmware release files from the web site.

Download the latest `VERA.BIN`, `SMC.BIN` and `ROM.BIN` file(s) from the Commander X16 community web sites. 

Any additional external ROMs on the expansion card to be updated, create the `ROMn.BIN` files to be according your external ROM update strategy.

If you own an external VERA, download or create an extra VERA1.BIN file and copy it onto your SD card.

- [SMC.BIN from the CX16 update program release page](https://github.com/FlightControl-User/x16-flash/releases)
- [VERA.BIN from the VERA Release page](https://github.com/X16Community/vera-module/releases)
- [ROM.BIN files from the ROM Release page](https://github.com/X16Community/x16-rom/releases).

Notes: 
-  The SMC Release page is not yet containing the correct SMC.BIN files, so download from the CX16 update program release page. Therefore, the CX16 update program release page contains the SMC.BIN artefacts.
- The names of the artefacts can differ a bit. They might contain the release number of version number. Always rename the files to the correct name before copying it onto the SD card!

## 1.3 The update PREPARATIONS:

### 1.3.1 Copy the files on the SD card.

Copy the `SMC.BIN`, `VERA.BIN`, `VERA1.BIN`, `ROM.BIN` and `ROMn.BIN` files on the SD card at the same folder fro where your CX16-UPDATE.PRG file is located according your update strategy and needs.

Ensure the files are copied onto the SD card with the file names in **CAPITAL** letters.

For an overview, please find the following checklists with all the actions and attention points, which are explained further below with pictures and further details.

### 1.3.1 PREPARE: OPEN VERA JP1 jumper pins + Be prepared for a manual action!

The VERA hosts both the SD card as the graphics FPGA engine. On the VERA main CX16 board, there are the JP1 jumper pins, which regulate whether any request to the VERA directs the request to the SD card or to the SPI. The SPI is a 2MB IC that is located on your VERA board, which is used to "flash" the FPGA at VERA startup. The CX16 ROM activates this process automatically, but in order to update the VERA firmware, the contents of this SPI IC must be updated. This requires you to place during the execution of the update program a jumper cap onto the JP1 jumper on the VERA board. This instructs the VERA to direct any memory instruction to the SPI instead of the SD card. Thus, once the SP1 jumper cap closes the JP1 jumper pins, the SPI update process will commence. Once the SPI update process is finished, you will be request to remove again the JP1 jumper cap from the VERA board, because the update program must be able to read all your further SMC.BIN, ROM.BIN, ROM1.BIN and VERA1.BIN files from the SD card.

So in summary, remember the following:
- JP1 jumper pins OPEN => VERA addresses the SD card.
- JP1 jumper pins CLOSED => VERA addresses the SPI IC.

|   |   |
| --- | --- |
| 1. For preparation, before running the CX16 update program, **ensure** that the JP1 jumper pins on the VERA board are **OPEN** (Picture above)! This is necessary to instruct VERA to address any memory instruction to the SD card. | ![VERA-JP1-OPEN](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/VERA-JP1-OPEN.jpg) |
| 2. During the update process, the program will ask you to place a jumper cap, **CLOSING** the JP1 jumper pins (picture above). This is necessary to instruct VERA to address any memory instruction to the SPI IC, in order to allow for the memory flashing of the VERA.BIN file now stored in RAM, onto the SPI IC memory (only the first 128KB will be updated). | ![VERA-JP1-CLOSED](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/VERA-JP1-CLOSED.jpg) |
| 3. Once the VERA memory has been updated, the program will ask you to remove the JP1 jumper cap, **opening** the pins again. This is necessary to direct VERA to address the SD card again for further file reads. | ![VERA-JP1-OPEN](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/VERA-JP1-OPEN.jpg) |

**Note that this will happen during the update process and it is crucial that you follow carefully the instructions given by the program! It might be advisory to practice this process before you execute the CX16 update program, with your CX16 board powered OFF! Put a jumper cap on the JP1 jumper pins closing it and re-opening it by removing. Simple, but if you've never done this, this may require a bit of practice!**

Updating the **external** VERA card won't require you to follow this process.

### 1.3.2 Prepare: CLOSE SMC J5 jumper pins!

|   |   |
| --- | --- |
| Ensure that the J5 jumper pins on the Commander X16 main board are **closed**. If the J5 jumper pins are not closed, the keyboard won't be functional! | ![CX16-J5](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/CX16-J5.jpg) |


### 1.3.3 Prepare: CLOSE Main CX16 ROM J1 jumper pins!



|   |   |
| --- | --- |
| Ensure that the J1 jumper pins on the Commander X16 main board are **closed**, to **remove the write protection** of the main CX16 ROM.  If the J1 jumper pins are **not closed**, the **main CX16 ROM will not be detected** by the update program! | ![CX16-J1](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/CX16-J1.jpg) |


### 1.3.4 Prepare: Flash multiple ROMs on the external RAM/ROM board or cartridge.

|   |   |
| --- | --- |
| First for all clarity, find below a picture of such a ROM expansion cartridge. | ![ROM-CARD](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/ROM-CARD.jpg) |

On the ROM cartridge, 7 extra RAM/ROM chips can be placed for usage, and can be updated using this program. The cartridge is placed in one of the 4 PCI extension slots on the CX16 main board, and provides an extra 3.5 MB of banked RAM/ROM to your CX16 between addresses $C000 and $FFFF, with zeropage $01 as the bank register. Each bank has $4000 bytes!

Each ROM is addressing wise 512K separated from each other, and can be flashed with its own ROM*n*.BIN file(s), where *n* must be a number between 1 and 7! 

For example, `ROM1.BIN` will flash ROM#1 on the cartridge. `ROM5.BIN` will flash ROM#5. ROMs are to be counted from left to right!

In order to flash the ROMs, **close** the relevant jumper pins:

| Preparation  |   |
| --- | --- |
| 1. **Close** the J1 jumper pins (at the left side of the cartridge board) to remove the write-protection for ROM#1 till ROM#6. | ![ROM-CARD-J1-CLOSED](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/ROM-CARD-J1-CLOSED.jpg) |
| 2. **Close** the J2 jumper pins (at the right side of the cartridge board) to remove the write-protection for ROM#7. | ![ROM-CARD-J2-CLOSED](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/ROM-CARD-J2-CLOSED.jpg) |

 


 

Once you have the J1 and/or J2 jumper pins properly closed on the cartridge board, the ROMs will be detected by the flashing program. If the jumper pins are open, the ROMs won't be recognized by the flashing program and your ROM*n*.BIN file(s) will not be flashed!

## 1.4. Final Update checklist for the Commander X16.

Please read through the following checklist before you commence running the CX16 update program, taking all the information you learned above:

## 1.4.1 Internal CX16 VERA update checklist:

  1. Is the **version** of the `VERA.BIN` correct?
  2. Has the file been **copied** onto your SD card?
  3. Is the file named `VERA.BIN` in **capital** letters?
  4. Do you have a jumper pin **connector** at your disposal?  
  You will need it to close the JP1 pins on the VERA board.  
  5. Are the **JP1 jumper pins open** on the **VERA board**?
  6. Have you understood why the JP1 jumper pins need to be closed and when it will be asked to close them?
  7. Have you understood why the JP1 jumper pins need to be opened again when the VERA memory has been updated? 
  8. if you don't have any electronics experience, **have you practiced** to place a JP1 jumper cap on the JP1 jumper pins, and remove it, with the CX16 board powered off?

## 1.4.2 Internal CX16 SMC update checklist:

  1. Is the **version** of the `SMC.BIN` correct?
  2. Has the file been **copied** onto your SD card?
  3. Is the file named `SMC.BIN` in **capital** letters?
  4. Are the J5 jumper pins **closed** on the CX16 main board?

## 1.4.3 Internal CX16 ROM update checklist:

  1. Is the **version** of the `ROM.BIN` correct?
  2. Has the file been **copied** onto your SD card?
  3. Is the file named `ROM.BIN` in **capital** letters?
  4. Are the **J1 jumper pins** on the CX16 main board **closed**?

## 1.4.4 External CX16 ROMs update checklist:

  1. Are the **version** of the `ROMn.BIN` file(s) correct?  
  2. Has(ve) the file(s) been **copied** onto your SD card?
  3. Have the file(s) been named `ROMn.BIN` in **capital** letters, with the *n* being a number from 1 to 7?
  4. For the **ROMs 1 to 6** on the cardridge, are the **J1 jumper pins closed**?
  5. For the **ROM 7** on the cardridge, are the **J2 jumper pins closed**?
  
# 2. Run the CX16 update program.

1. Place the SD card in the CX16 (VERA) card slot.  

2. Boot/Start your Commander X16 computer.

3. Type `LOAD CX16-UPDATE.PRG` or press `F7` on the keyboard (`DOS"$"`) and put the cursor in front of the program, then press `F3` on the keyboard (`LOAD`).

4. Type `RUN` or press `F5` on the keyboard.

# 2.1 Main flow of the CX16 update program:

The update program is very user friendly and walks you through the different steps.
Please find below a detailed description of the complete process.

## 2.1.1 Introduction and briefing screens

| Step  | Picture  |
| --- | --- |
| At program start, you will see an introduction screen, introducing the update process. Please carefully read the text at the bottom panel of the screen, and press SPACE to continue ... | ![Into-1](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/INTRO1.jpg) |
| A second screen appears, which indicates the color schema used to indicate the update status of each component on your Commander X16 main board and/or your expansion cartridge board. Press SPACE to continue. | ![Into-2](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/INTRO2.jpg) |


### 2.1.2 Component detection

|  |  |
| --- | --- |
| Next, the update program detects which components are upgradable and will validate which files are found on the SD card. The Commander X16 main board SMC, VERA and main ROM chip are detected, together with the external cardridge 7 ROM chips. | ![DETECTED](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/DETECTED.jpg) |

The Commander X16 main board SMC, VERA and main ROM chip are detected, together with the external cardridge 7 ROM chips.

- Each component detected will be highlighted with a Detected status and a **WHITE** led. The capacity of each detected ROM is shown in KBytes. 

- Other components that are not detected are highlighed with a None staus and a **BLACK** led. These ROMs won't be considered for flashing.

### 2.1.3 File presence and validation

|  |  |
| --- | --- |
| After component detection, the program will immediately search for file presence for **each detected component** and will validate it. The program will read each file and check on data size and any validation content to be used before flashing.  | ![CHECK](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/CHECK.jpg) |


- Detected and valid files will result in the status of the component in a **PURPLE** led and status `Update`.

- Files that are not present, will result in the component not to be updated. The component will get a GREY led and status `Skipped`.

### 2.1.4 Pre-Update conditions.

|  |  |
| --- | --- |
| Before the update commences, there are important conditions vaidated to ensure that any upgrade file or component compatibility risk or issues, potentially corrupting your CX16, are properly mitigated. |  |


1. SMC and ROM must be flashed together: To avoid an SMC update corrupting your CX16 because it is not supportive or compatible with your ROM. The SMC file contains flags to ensure the compatibility between the SMC and the ROM.

2. An SMC not detected will stop the update process.

3. The main CX16 ROM not detected will stop the update process.

|  |  |
| --- | --- |
| When there are no issues, the user is asked for a confirmation to proceed with the update. Replying `N` will cancel the update. Replying `Y` will proceed with the update! | ![UPDATE-CONFIRMATION](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/UPDATE-CONFIRMATION.jpg) |


## 2.2 The CX16 update program updating your CX16 internal and external components

The CX16 update program will update each component that has status `Update`.

For each component, program will read the firmware data into RAM memory first, and will then use the data stored in RAM to update your CX16 component.
The program guides you through the update process for each component in a very user friendly way, but mistakes are always possible, to please read carefully the below explanation. However, the **component update process differs for each component type**, so be aware! 

### 2.2.1 The VERA update process

|   |   |
| --- | --- |
| Once the CX16 update has verified all the the files, and the VERA.BIN file is accepted, you need to confirm here with typing `Y` on the CX16 keyboard. | ![VERA-UPDATE-CONFIRMATION](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/VERA-UPDATE-CONFIRMATION.jpg) |
| You will be presented with this briefing, that explains the importance of the JP1 jumper pins manual handing during the update process (Picture above). Press SPACE on the CX16 keyboard to continue. | ![VERA-UPDATE-BRIEFING](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/VERA-UPDATE-BRIEFING.jpg) |
| The program will then read the VERA.BIN file contents into RAM. | ![VERA-UPDATE-READING](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/VERA-UPDATE-READING.jpg) |
| Then you will be asked to place the JP1 jumper cap onto the JP1 jumper pins, thus closing the JP1 jumper pins, in order to instruct VERA to direct its instructions to the SPI IC (instead of the SD card). | ![VERA-UPDATE-READING](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/VERA-UPDATE-READING.jpg) |
| Place the JP1 jumper cap, closing the JP1 jumper pins on the VERA board. | ![VERA-JP1-CLOSED](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/VERA-JP1-CLOSED.jpg) |
| Before the program updates your VERA firmware, it will compare the contents of the current VERA firmware with the contents of the VERA.BIN, which was read into RAM. | ![VERA-UPDATE-COMPARING](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/VERA-UPDATE-COMPARING.jpg) |
| Once all the data has been compared, it will update your firmware if the compare results show differences. | ![VERA-UPDATE-FLASHING](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/VERA-UPDATE-FLASHING.jpg) |
| After the program has flashed your new VERA firmware, the program will compare the contents of the new VERA firmware flashed with the RAM contents. The comparison result should be equal. | ![VERA-UPDATE-COMPARING](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/VERA-UPDATE-COMPARING.jpg) |
| Once all VERA flashing and verification processes are complete, the program will ask you to remove the JP1 jumper cap from the JP1 jumper pins, thus opening the JP1 jumper pins to instruct VERA to direct its instructions back to the SD card. | ![VERA-UPDATE-JP1-OPEN](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/VERA-UPDATE-JP1-OPEN.jpg) |
| Remove the JP1 jumper cap from the JP1 jumper pins on the VERA board. | ![VERA-JP1-OPEN](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/VERA-JP1-OPEN.jpg) |
| When the comparison result is equal, the VERA led whill show a **GREEN** color and the status will show `Flashed`. |  |

### 2.2.2 The SMC update process

The SMC update is straightforward. 

|   |   |
| --- | --- |
| It will first read the `SMC.BIN` into internal memory. | |
| Then, the program asks you to press the `POWER` and the `RESET` button at the same time on the CX16 board. | ![POWER-RESET-SCREEN](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/POWER-RESET-SCREEN.jpg) |
| Do so on the CX16 board. | ![POWER-RESET](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/POWER-RESET.jpg) |
| When the POWER-RESET button is not pressed in time (there is a countdown), the program will cancel the update of the SMC but will continue updating any other component. The update of the ROM will be skipped, though! The cancellation of the SMC update results in a reported issue, as the SMC and the ROM must be flashed together. | ![SMC-ROM-ISSUE](https://raw.githubusercontent.com/FlightControl-User/x16-flash/main/images/SMC-ROM-ISSUE.jpg) |
| When POWER-RESET is pressed, the program will flash your SMC. Don't interrupt the process. | |
| To ensure that your SMC has been properly updated, the SMC will show as a **GREEN** led and status `Updated`. | |

 
**VERY IMPORTANT:**

**Once your SMC is updated, you MUST wait till the end of the program to continue to update process, or your CX16 will be BRICKED!!!**


### 2.2.3 The main CX16 ROM update process



### 2.2.4 The external cardridge ROMs update process

The loading process is seamless, if there is a file, each byte in the file is loaded into low and high RAM. The first $4000 bytes are loaded in low RAM, while the remainder of the ROM[N].BIN file is loaded in high RAM. This is nothing for you to be concerned about, just explaining how the program works. But note that a ROM[N].BIN file that is 512KB large, will be fully loaded into RAM on the Commander X16!

<img width="634" alt="FLASH-LOAD" src="https://user-images.githubusercontent.com/13690775/225111367-df29cf5b-eeeb-4c5a-8a2a-1366345086a8.png">

Each $100 bytes loaded will be shown on the screen as a '.' in the memory matrix. Each row in the matrix represents $4000 bytes. There are $40 possible blocks of $100 bytes each in each row. A ROM can have a maximum of 512K, so there are maximum 32 rows possible to be shown in the matrix.

The ROM address ranges being processed are shown. The first column shows the ROM bank being processed, while the 2nd column indicates the "relative" ROM addres for each row. 

Loading and Comparing in progress is highlighted with a CYAN led on top of the ROM chip. 

# 3 ISSUES AND RESOLUTIONS

| Component | Issue | Resolution |
| --- | --- | --- |
| VERA | No VERA.BIN | Place the correct VERA.BIN on your SD card. A valid VERA.BIN file must be lower than 128KB and may not be of size 0KB. |
| SMC | SMC no bootloader | When updating the SMC, a valid bootloader is required! You must resort to flash a bootloader onto your SMC using an external device. See the procedure under #4 Recovery procedures. |
| SMC | POWER-RESET buttons not pressed in time | Ensure that the POWER-RESET buttons are pressed on the CX16 board in time (before the counter drops to zero) |
| SMC | No SMC.BIN | Place the correct SMC.BIN on your SD card. A valid SMC.BIN file must not be larger than 2KB and may not be of size 0KB. The SMC.BIN file contains version and compatibility information, which is checked, so ensure you have a valid SMC.BIN file! |
| ROM | On-board CX16 ROM not detected. | Are the J1 jumper pins on the On-board CX16 closed? |
| ROM | External ROMs not detected on cardridge. | Are the J1 and J2 jumper pins on the On-bard CX16 closed? Are the values you see at the top of the screen B5, B6, B7? |
| ROM | No ROM.BIN | Place the correct ROM.BIN on your SD card. A ROM.BIN may vary in size, but must always be larger than 0KB. The size of the ROL.BIN must be equal to multiples of $4000 bytes! |

# 4 Recovery procedures (from a bricked CX16)


----

# OLD

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
