#include "about.h"

#ifndef VERSION
#define VERSION "?.??"
#endif

void about_display() {
    vga_clear(0x17);

    vga_print_string("About SeaPig BIOS", 31, 0, 0x07);
    for(int x=0; x<80; x++) {
        vga_set_char_attr(0x2F, x, 0);
        vga_set_char_attr(0x0F, x, 24);
        vga_print_char('=', x, 23, 0x1F);
    }

    vga_print_string("SeaPig 486 Single Board Computer BIOS Version " VERSION, 2, 3, 0x1F);
    vga_print_string("Made for M8SBC-486 REV 1.0X (Hamster 1 chipset), Built " __DATE__ " " __TIME__, 2, 5, 0x1F);
    vga_print_string("By: maniek86 (Piotr Grzesik), 2024-2026,  maniek86.xyz", 2, 6, 0x1F);

    vga_print_string("Sources: https://github.com/maniekx86/M8SBC-486", 2, 8, 0x17);
    vga_print_string("See also: https://maniek86.xyz/projects/m8sbc_486.php", 2, 9, 0x17);

    
    vga_print_string("Base code derived from BIOS by d-mitry1 licensed under MIT", 2, 17, 0x1F);
    //vga_print_string("", 2, 18, 0x17);

    //vga_print_string("", 2, 20, 0x17);
    //vga_print_string("", 2, 21, 0x17);


    vga_print_string("Press ESC to exit and continue", 24, 24, 0x0F);
    


    kb_clear_buffer();

    while(1) {
        if(kb_is_available()) {
            uint8_t scancode = kb_get_scancode();
            if(scancode==0x01) { // ESC
                break;
            }
        }
    }

}
