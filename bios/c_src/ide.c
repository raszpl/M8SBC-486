#include "ide.h"

static uint16_t disk_data[256];

void IDE_reset() {
    outb(IDE_DEV_CONTROL, 0b00000100);
    uint32_t start_ticks = irq0_ticks;

    while(1) {
        if(irq0_ticks > start_ticks+2) break;
        asm volatile("nop");
        io_wait();
    }

    outb(IDE_DEV_CONTROL, 0b00000000);

    start_ticks = irq0_ticks;
    while(1) {
        if(irq0_ticks > start_ticks+2) break;
        asm volatile("nop");
        io_wait();
    }
}

int IDE_wait_busy(int timeout) {
    uint32_t start_ticks = irq0_ticks;
    while(1) {
        if(irq0_ticks > start_ticks+timeout) return 0;
        uint8_t status = inb(IDE_STATUS);
        if(!(status & 0x80)) break;
        asm volatile("nop");
        io_wait();
    }
    return 1;
}

int IDE_detect(char *drive_name) {
    outb(IDE_NUM3, 0xA0); // select master drive
    io_wait();
    outb(IDE_COMMAND, 0xEC); // IDENTIFY command
    io_wait();

    memset(drive_name, 0, 41);

    uint32_t irq0_start = irq0_ticks;

    while(1) {
        io_wait();
        uint8_t status = inb(IDE_STATUS);

        uint32_t elapsed = irq0_ticks - irq0_start;
        if(elapsed > 500) return 0; // 5 seconds

        static uint32_t last_ticks = 0;
        if(last_ticks!=irq0_ticks) { // to not redraw every few cpu cycles
            vga_print_itoa(elapsed / 100, 20+13, 12, 0x07, 10, 0);
            last_ticks = irq0_ticks;
        }

        if(!(status & 0x80) && (status & 8)) {
            break;
        }
    }

    for(int i=0;i<256;i++) {
        disk_data[i] = inw(IDE_DATA);
        io_wait();
    }

    // check sanity of the data
    // TODO: fix detection in some cases
    int check = 1;
    
    if((disk_data[0] & 0x8000) != 0) check = 0;
    if(disk_data[0] == 0x0000 || disk_data[0] == 0xFFFF) check = 0;

    for(int i=0;i<20;i++) {
        // swap bytes
        drive_name[i*2] = (disk_data[27 + i] >> 8) & 0xFF;
        drive_name[i*2 + 1] = disk_data[27 + i] & 0xFF;
    }
    for(int i=0;i<40;i++) {
        if(!((uint8_t)drive_name[i] >= 32 || (uint8_t)drive_name[i] <= 127 || (uint8_t)drive_name[i] == 0)) check = 0;
    }
    // check if all data is not the same
    uint16_t f = disk_data[0];
    int fc = 0;
    for(int i=0;i<256;i++) {
        if(disk_data[i]==f) fc++;
    }
    if(fc>=255) check = 0;


    return check;
}
