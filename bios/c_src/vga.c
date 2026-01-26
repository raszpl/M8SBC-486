#include "vga.h"
static volatile uint8_t *screen = (uint8_t*)0xB8000;
static volatile uint16_t *screen16 = (uint16_t*)0xB8000;



void vga_print_char(char c, int x, int y, uint8_t attr) {
    volatile uint16_t *pos = screen16 + (y * 80 + x);
    *pos = (c | (attr << 8));
}

void vga_print_string(const char *str, int x, int y, uint8_t attr) {
    volatile uint16_t *pos = screen16 + (y * 80 + x);
    while(*str) {
        *pos++ = ((*str++) | (attr << 8));
    }
}

void vga_print_itoa(int value, int x, int y, uint8_t attr, int base, int width) { // width = extra parameter spaces to clear previous data
    char str[16] = {0};
    itoa(value, str, base);
    vga_print_string(str, x, y, attr);
    // clear extra spaces
    int len = strlen(str);
    for(int i=len;i<width;i++) {
        vga_print_char(x, y + i, ' ', attr);
    }
}

void vga_set_char_attr(uint8_t attr, int x, int y) {
    volatile uint8_t *pos = screen + (y * 80 + x)*2 + 1;
    *pos = attr;
}

void vga_clear(uint8_t attr) {
    for(int x=0; x<80; x++) {
        for(int y=0; y<25; y++) {
            vga_print_char(' ', x, y, attr); // clear screen and set attributes to default
        }
    }
}


////// boot logo ////////
static volatile uint8_t *font_memory = (uint8_t*)0xA0000;

static inline void write_vga_register(uint16_t port, uint8_t index, uint8_t value) {
    outb(port, index);
    outb(port + 1, value);
}
uint8_t read_vga_register(uint16_t index_port, uint8_t index) {
    outb(index_port, index); 
    return inb(index_port + 1); 
}

static uint8_t backup_font_data[GLYPH_COUNT * GLYPH_HEIGHT];
//static uint8_t saved_seq_01;

void vga_load_logo() {
    // Set up memory access for plane 2
    write_vga_register(VGA_SEQ_INDEX, 0x02, 0x04); // enable writing to plane 2
    write_vga_register(VGA_SEQ_INDEX, 0x04, 0x07); // enable sequential memory access
    write_vga_register(VGA_GRAPHICS_INDEX, 0x04, 0x02); // select plane 2 for reading
    write_vga_register(VGA_GRAPHICS_INDEX, 0x05, 0x00); // disable odd/even mode
    write_vga_register(VGA_GRAPHICS_INDEX, 0x06, 0x04); // map font memory to 0xA0000

    // Backup the original font data (Characters 0xC0 to 0xC0+39)
    for (int char_idx = 0; char_idx < GLYPH_COUNT; char_idx++) {
        // Calculate the memory offset for the character
        // Each character slot is 32 bytes wide in the font map
        int char_offset = (0xC0 + char_idx) * 32;
        
        for (int y = 0; y < GLYPH_HEIGHT; y++) {
            // Read one byte (one row of pixels) from the VGA font memory
            backup_font_data[char_idx * GLYPH_HEIGHT + y] = font_memory[char_offset + y];
        }
    }

    for (int char_idx = 0; char_idx < GLYPH_COUNT; char_idx++) {
        int char_offset = (0xC0 + char_idx) * 32;
        
        for (int y = 0; y < GLYPH_HEIGHT; y++) {
            // Write one byte of the logo font data to the VGA memory
            font_memory[char_offset + y] = font_data[char_idx * GLYPH_HEIGHT + y];
        }
    }

    write_vga_register(VGA_SEQ_INDEX, 0x02, 0x03); // re-enable all planes
    write_vga_register(VGA_SEQ_INDEX, 0x04, 0x03); // restore memory mode
    write_vga_register(VGA_GRAPHICS_INDEX, 0x04, 0x00); // restore read map
    write_vga_register(VGA_GRAPHICS_INDEX, 0x05, 0x10); // restore odd/even mode
    write_vga_register(VGA_GRAPHICS_INDEX, 0x06, 0x0E); // restore graphics mode

    // Switch to 8 char width mode
    //saved_seq_01 = read_vga_register(VGA_SEQ_INDEX, 0x01);
    //write_vga_register(VGA_SEQ_INDEX, 0x01, saved_seq_01 | 0x01);
}

void vga_restore_font() {
    // Set up memory access for plane 2
    write_vga_register(VGA_SEQ_INDEX, 0x02, 0x04);
    write_vga_register(VGA_SEQ_INDEX, 0x04, 0x07);
    write_vga_register(VGA_GRAPHICS_INDEX, 0x04, 0x02);
    write_vga_register(VGA_GRAPHICS_INDEX, 0x05, 0x00);
    write_vga_register(VGA_GRAPHICS_INDEX, 0x06, 0x04);

    // Restore the original font data
    for (int char_idx = 0; char_idx < GLYPH_COUNT; char_idx++) {
        int char_offset = (0xC0 + char_idx) * 32;
        
        for (int y = 0; y < GLYPH_HEIGHT; y++) {
            // Write one byte of the backed-up font data back to the VGA memory
            font_memory[char_offset + y] = backup_font_data[char_idx * GLYPH_HEIGHT + y];
        }
    }

    write_vga_register(VGA_SEQ_INDEX, 0x02, 0x03); 
    write_vga_register(VGA_SEQ_INDEX, 0x04, 0x03);
    write_vga_register(VGA_GRAPHICS_INDEX, 0x04, 0x00);
    write_vga_register(VGA_GRAPHICS_INDEX, 0x05, 0x10);
    write_vga_register(VGA_GRAPHICS_INDEX, 0x06, 0x0E);

    //write_vga_register(VGA_SEQ_INDEX, 0x01, saved_seq_01);
}

void vga_draw_logo(uint8_t d_x, uint8_t d_y) {
    // maniek86 logo
    for(int y=0;y<3;y++) {
        for(int x=0;x<17;x++) {
            //int t_x = x + 60;
            //int t_y = y + 1;
            int addr = ((d_y+y) * 80 + (d_x+x)) * 2;
            uint8_t cell = cell_map[y][x];
            if(cell==0xC0 || cell==0xC1) cell = ' '; // PATCH, cells 0xC0 and 0xC1 contain extra logo
            screen[addr] = cell;
            
            if(y==2) {
                screen[addr + 1] = 0x0F; // white, for the bottom row
            } else {
                screen[addr + 1] = 0x09; // blue, for the top two rows
            }
        }
    }
}

void vga_draw_extra_logo(uint8_t d_x, uint8_t d_y) {
    int addr = (d_y*80 + d_x) * 2;
    screen[addr] = 0xC0;
    screen[addr+1] = 0x06;
    screen[addr+2] = 0xC1;
    screen[addr+3] = 0x06;
}