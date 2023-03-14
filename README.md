# Commander X16 Flashing Utility

Contains the source code of the commander x16 rom flashing utility.
The artefact of this source code is a small program that allows to upgrade (or downgrade) your CX16 on-board ROM, or, to flash external ROMs etched on an ISA cardridge board.

Please find here a short user manual of this program.

## Notice of caution

Flashing your on-board rom requires you to carefully follow the instructions. There is a small risk that your on-board ROM may get damaged during the ROM flashing process and may generate your ROM unusable, resulting in a bricked CX16!

Further steps to mitigate and recover from such situations are pending to be documented. However, please direct youself in such situations to the commander X16 [Discord]() or [Forum](https://www.commanderx16.com/forum)!

# User Manual

Please consider this draft user manual as a first guide how to use the flashing tool.

## 0. What you need

There is not much that is needed to upgrade your ROM(s).

- Ensure you have a valid and working SDCARD that has sufficient free space and is formatted in FAT32.
- You need a CX16 computer (the real thing).
- You optionally can have an add-on ISA cardridge board, that is plugged in any of the 4 ISA slots. This ISA RA/ROM board can contain an extra 3.5 MB of RAM/ROM!

## 1. Download the program

The latest version of the program can be found on the [release page](https://github.com/FlightControl-User/x16-flash/releases) of this repository. Search for the file FLASH-CX16.PRG and download the file. Copy the program into a directory of your SDCARD. You will run this program on your CX16 hardware. Ensure the file is copied onto the SDcard with the file name in CAPITAL letters.

## 2. Download your rom.bin file(s) and name the bin files

Download your rom.bin files and name the files according your rom flashing strategy.  
There are two scenarios for rom flashing: flashing the on-board rom or flashing the off-board roms on the RAM/ROM external board.

### 2.1. Flash the single ROM on your CX16 board

Download the latest version of the rom.bin available at the CX16 github page. Copy the bin file at the same location where your FLASH-CX16.PRG file is located. Ensure the file is copied onto the SDcard with the file name in CAPITAL letters.

Ensure that the J1 jumper pins are closed, to remove the write protection of the on-board ROM.

![ROM-onboard-dip](https://user-images.githubusercontent.com/13690775/225110062-8081d0a6-079a-405a-b03a-ab2f482fbfff.jpg)

Once you have the J1 jumper properly closed, the ROM will be detected by the flashing program. If the J1 jumper pins are open, the ROM won't be recognized by the flashing program and your ROM.BIN file will not be flashed!

### 2.2. Flash multiple ROMs on the external RAM/ROM ISA cardidge.

First for all clarity, this is the cardridge:

![ROM-cardridge](https://user-images.githubusercontent.com/13690775/225110167-546596e6-998a-464f-b6a9-53fb598c19b4.jpg)

On the ROM cardridge, 7 extra RAM/ROM chips can be placed for usage, and flashing. The cardridge is placed in one of the 4 CX16 extension slots, and provides an extra 3.5 MB of banked RAM/ROM to your CX16 between addresses $C000 and $FFFF, with zeropage $01 as the bank register. Each bank has $4000 bytes!

Each ROM is addressing wise 512K separated from each other, and can be flashed with its own ROM[N].BIN file(s), where N must be a number between 1 and 7! For example, ROM1.BIN will flash ROM#1 on the cardridge. ROM5.BIN will flash ROM#5. ROM devices are to be placed and counted, from left to right!

To ensure that no harmful program can damage your ROMs, jumper pins J1 and J2 on the cardridge are to be remained open. However, in order to flash the ROMs, close the relevant jumper pins.

Close the J1 jumper pins (at the left side of the board) to remove the write-protection for ROM#1 till ROM#6. 

![ROM-DIP-J1](https://user-images.githubusercontent.com/13690775/225111120-56eeaca5-69a6-4812-a854-5cfc1246045a.jpg)

Close the J2 jumper pins (at the right side of the board) to remove the write-protection for ROM#7. 

![ROM-DIP-J2](https://user-images.githubusercontent.com/13690775/225111150-c441812c-5331-46b1-805f-f769064507f7.jpg)

Once you have the J1 and/or J2 jumper pins properly closed, the ROMs will be detected by the flashing program. If the jumper pins are open, the ROMs won't be recognized by the flashing program and your ROM[n].BIN file(s) will not be flashed!

## 3. Flashing the ROMs

Once you've copied the FLASH-CX16.PRG and the relevant ROM[N].BIN files onto the SDcard, you are ready for ROM flashing!

Place the SDcard in the foreseen VERA slot, and verify that all indicated jumper pins are closed properly.

Boot/Start your Commander X16 computer.

Your Commander X16 startup screen might look like this ...

<img width="242" alt="FLASH-DOS" src="https://user-images.githubusercontent.com/13690775/225111204-88051585-ecb7-4614-8374-ba4de2623d43.png">

Load the program and run it, follow a small guide as described below.

  1. DOS "CD:folder" - Optionally ensure that you navigate to the right folder on the SDcard where you copied all the files using DOS "CD:folder" commands.
  2. LOAD "FLASH-CX16.PRG",8
  3. RUN

The flashing program will first identify each ROM that is able to be flashed on the board and on the cardridge. Any ROM that is either not identified or not reachable will be shown as inactive and will be skipped.

The identified ROMs for flashing will be flashed from the highest ROM# number to the lowest ROM number. The last ROM that is considered for flashing is the on-board ROM.

The reason why this sequence was chosen, is to ensure that the program has the ROM routines available for allowing the user to view the flashing results and press the keyboard to continue the process.

Once the onboard ROM has been flashed, the program will automatically reset.

Please find in more details this sequence explained visually, with an explanation of the screens and the meaning of the symbols/colors.

### 3.1. ROM identification

Once the flashing program is started, it will first attempt to identify which ROMs are "flashable". You see 8 ROM chips with the left chip the on-board ROM chip and the most right chip the ROM#7, which would be the right most chip on the cardridge.

<img width="642" alt="FLASH-START" src="https://user-images.githubusercontent.com/13690775/225111270-385066a4-1b71-473f-8647-0c15f8c49da3.png">

Each ROM detected will be highlighted with a WHITE led. The ROM capacity is shown in KB and the manufacturer ID and device ID are shown (for your information).

Other ROM slots that could not be detected are highlighed with a BLACH led. These ROMs won't be considered for flashing.

Note that ROMs that can be flashed, but which don't have the jumper pins closed, won't be detected and will be skipped!

The user us requested to press a key to start the flashing procedure.

For each flashable ROM, the program will look for a related ROM[N].BIN file. 

<img width="642" alt="FLASH-NOFILE" src="https://user-images.githubusercontent.com/13690775/225111329-2528fc22-9e51-4bbd-9cf2-f06931e25dd5.png">

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


