
// Main includes.
#include <6502.h>
#include <conio.h>
#include <cx16-file.h>
#include <cx16.h>
#include <kernal.h>
#include <printf.h>
#include <sprintf.h>

// Uses all parameters to be passed using zero pages (fast).
#pragma var_model(zp)

#define VERA_CHR_SPACE 0x20
#define VERA_CHR_UL 0x7E
#define VERA_CHR_UR 0x7C
#define VERA_CHR_BL 0x7B
#define VERA_CHR_BR 0x6C
#define VERA_CHR_HL 0x62
#define VERA_CHR_VL 0x61


#define VERA_REV_SPACE 0xA0
#define VERA_REV_UL 0xFE
#define VERA_REV_UR 0xFC
#define VERA_REV_BL 0xFB
#define VERA_REV_BR 0xEC
#define VERA_REV_HL 0xE2
#define VERA_REV_VL 0xE1

void print_chip_line(char x, char y, char c) {

    gotoxy(x, y);

    textcolor(GREY);
    bgcolor(LIGHT_GREY);
    cputc(VERA_CHR_UR);

    textcolor(LIGHT_GREY);
    bgcolor(BLACK);
    cputc(VERA_CHR_SPACE);
    cputc(c);
    cputc(VERA_CHR_SPACE);

    textcolor(GREY);
    bgcolor(LIGHT_GREY);
    cputc(VERA_CHR_UL);
}

void print_chip_end(char x, char y) {

    gotoxy(x, y);

    textcolor(GREY);
    bgcolor(LIGHT_GREY);
    cputc(VERA_CHR_UR);

    textcolor(LIGHT_GREY);
    bgcolor(BLACK);
    cputc(VERA_CHR_HL);
    cputc(VERA_CHR_HL);
    cputc(VERA_CHR_HL);

    textcolor(GREY);
    bgcolor(LIGHT_GREY);
    cputc(VERA_CHR_UL);
}


void main() {

    unsigned int bytes = 0;

    // Set the charset to higher case.
    cbm_x_charset(2, (char *)0);

    textcolor(GREY);
    bgcolor(LIGHT_GREY);
    clrscr();

    for(unsigned char r=0; r<8; r++) {
        print_chip_line(2+r*10, 44, ' ');
        print_chip_line(2+r*10, 45, 'r');
        print_chip_line(2+r*10, 46, 'o');
        print_chip_line(2+r*10, 47, 'm');
        print_chip_line(2+r*10, 48, '0'+r);
        print_chip_line(2+r*10, 49, ' ');
        print_chip_line(2+r*10, 50, '5');
        print_chip_line(2+r*10, 51, '1');
        print_chip_line(2+r*10, 52, '2');
        print_chip_end(2+r*10, 53);
    }

}
