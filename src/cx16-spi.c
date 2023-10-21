/**
 * @file cx16-spi.c
 * 
 * @author Wavicle from CX16 community (https://gist.github.com/jburks) -- Advice and outline of the ROM update logic & overall support and test assistance of this program.
 * @author MooingLemur from CX16 community (https://github.com/mooinglemur) -- Advice and outline of the main SPI and W25Q16 update logic, and supply of new VERA firmware.
 * @author Stefan Jakobsson from CX16 community (https://github.com/stefan-b-jakobsson) -- Advice and outline of the SMC update logic, SMC firmware and bootloader and creation of SMC firmware.
 * @author Sven Van de Velde from CX16 community (https://github.com/FlightControl-User) -- Creation of this program, under the strong expertise by the people above.
 * 
 * @brief COMMANDER X16 UPDATE TOOL SPI FIRMWARE UPDATE ROUTINES
 *
 * @version 2.0
 * @date 2023-09-21
 *
 * @copyright Copyright (c) 2023
 *
 */

#include "cx16-defines.h"
#include "cx16-globals.h"

#include "cx16-spi.h"

#pragma code_seg(CodeOverwrite)
#pragma data_seg(DataOverwrite)

__mem unsigned char spi_buffer[256];

__mem unsigned char spi_manufacturer;
__mem unsigned char spi_memory_type;
__mem unsigned char spi_memory_capacity;

void spi_get_jedec() {

/* 
; Returns
; .X = Vendor ID
; .Y = Memory Type
; .A = Memory Capacity
.proc spi_get_jedec
    jsr spi_fast

    jsr spi_select
    lda #$9F
    jsr spi_write
    jsr spi_read
    tax
    jsr spi_read
    tay
    jsr spi_read
    rts
.endproc
 */


    spi_fast();
    spi_select();
    spi_write(0x9F);

    spi_manufacturer = spi_read();
    spi_memory_type = spi_read();
    spi_memory_capacity = spi_read();

    return;
}


void spi_get_uniq() {

/* 
.proc spi_get_uniq
    jsr spi_select

    lda #$4B
    jsr spi_write
    jsr spi_read
    jsr spi_read
    jsr spi_read
    jsr spi_read

    ldx #0
:
    jsr spi_read
    sta spi_buffer, x
    inx
    cpx #8
    bcc :-

    rts
.endproc
 */

    spi_select();
    spi_write(0x48);
    spi_read();
    spi_read();
    spi_read();
    spi_read();
    spi_read();

    for(unsigned char x=0; x<8; x++) {
        unsigned char v = spi_read();
        spi_buffer[x] = v;
    }

    return;
}


void spi_read_flash(unsigned long spi_data) {

/* 
; .X [7:0]
; .Y [15:8]
; .A [23:16]
.proc spi_read_flash
    pha

    jsr spi_select
    lda #$03
    jsr spi_write
    pla
    jsr spi_write
    tya
    jsr spi_write
    txa
    jsr spi_write

    rts
.endproc
 */

    spi_select();
    spi_write(0x03);
    spi_write(BYTE2(spi_data));
    spi_write(BYTE1(spi_data));
    spi_write(BYTE0(spi_data));
    return;
}

void spi_read_flash_to_bank(unsigned long data) {

/* 
; .X [7:0]
; .Y [15:8]
; .A [23:16]
.proc spi_read_flash_to_bank
    jsr spi_read_flash
.endproc
 */

    spi_read_flash(data);
    return;
}



void spi_block_erase(unsigned long data) {

/** 
; .X [7:0]
; .Y [15:8]
; .A [23:16]
.proc spi_block_erase ; 64k
    pha

    ; write enable
    jsr spi_select
    lda #$06
    jsr spi_write

    jsr spi_select
    lda #$d8
    jsr spi_write

    pla
    jsr spi_write
    tya
    jsr spi_write
    txa
    jsr spi_write

    jsr spi_deselect

    rts
.endproc
 */

    spi_select();
    spi_write(0x06);
    
    spi_select();
    spi_write(0xD8);

    spi_write(BYTE2(data));
    spi_write(BYTE1(data));
    spi_write(BYTE0(data));

    spi_deselect();

    return;

    return;
}


void spi_write_page_begin(unsigned long data) {

/** 
; .X [7:0]
; .Y [15:8]
; .A [23:16]
.proc spi_write_page_begin
    pha

    ; write enable
    jsr spi_select
    lda #$06
    jsr spi_write

    jsr spi_select
    lda #$02
    jsr spi_write
    pla
    jsr spi_write
    tya
    jsr spi_write
    txa
    jsr spi_write

    rts
.endproc
 */

    spi_select();
    spi_write(0x06);

    spi_select();
    spi_write(0x02);

    spi_write(BYTE2(data));
    spi_write(BYTE1(data));
    spi_write(BYTE0(data));

    return;
}


unsigned char spi_wait_non_busy() {

/** 
.proc spi_wait_non_busy
    ldy #0
top:
    jsr spi_select
    lda #$05
    jsr spi_write

    jsr spi_read
    and #1
    bne wait_restart
    clc
    rts
fail:
    sec
    rts
wait_restart:
    iny
    beq fail
    wai    
    bra top
.endproc
 */

    unsigned char y = 0;

    while(1) {

        spi_select();
        spi_write(0x05);

        unsigned char w = spi_read();
        w &= 1;

        if(w == 0) {
            return 0;
        } else {
            y++;
            if(y == 0) {
                return 1;
            }
#ifndef __INTELLISENSE__
            // WAI
            asm {
                .byte $CB 
            }
#endif
        }
    }

    return 0;

}

unsigned char spi_read() {
/*
    .proc spi_read
	stz Vera::Reg::SPIData
@1:	bit Vera::Reg::SPICtrl
	bmi @1
    lda Vera::Reg::SPIData
	rts
.endproc
*/

#ifndef __INTELLISENSE__
    asm {
        stz vera_reg_SPIData
        !: bit vera_reg_SPICtrl
        bmi !-
    }
#endif

    return *vera_reg_SPIData;
}

/**
 * @brief 
 * 
 * 
 */
void spi_write(unsigned char data) {
/*
.proc spi_write
	sta Vera::Reg::SPIData
@1:	bit Vera::Reg::SPICtrl
	bmi @1
	rts
.endproc
*/

#ifndef __INTELLISENSE__
    asm {
        lda data
        sta vera_reg_SPIData
        !: bit vera_reg_SPICtrl
        bmi !-
    }
#endif

    return;
}

void spi_fast() {
/*
.proc spi_fast
    lda Vera::Reg::SPICtrl
    and #%11111101
    sta Vera::Reg::SPICtrl
	rts
.endproc
*/

#ifndef __INTELLISENSE__
    asm {
        lda vera_reg_SPICtrl
        and #%11111101
        sta vera_reg_SPICtrl
    }
#endif

    return;
}

unsigned char spi_deselect() {
/*
.proc spi_deselect
    lda Vera::Reg::SPICtrl
    and #$fe
    sta Vera::Reg::SPICtrl
    jsr spi_read
	rts
.endproc
*/

    *vera_reg_SPICtrl &= 0xfe;

    unsigned char value = spi_read();
    return value;
}

void spi_select() {
/*
.proc spi_select
    jsr spi_deselect

    lda Vera::Reg::SPICtrl
    ora #$01
    sta Vera::Reg::SPICtrl
	rts
.endproc
*/

    spi_deselect();
    *vera_reg_SPICtrl |= 1;

    return;
}

#pragma code_seg(Code)
#pragma data_seg(Data)
