#ifndef VGA_H
#define VGA_H
#include <stdint.h>
#include "x86io.h"
#include "utils.h"
#include "bootlogo/fontdata.h"

#define VGA_SEQ_INDEX           0x3C4
#define VGA_GRAPHICS_INDEX      0x3CE

void vga_print_char(char c, int x, int y, uint8_t attr);
void vga_print_string(const char *str, int x, int y, uint8_t attr);
void vga_print_itoa(int value, int x, int y, uint8_t attr, int base, int width);
void vga_set_char_attr(uint8_t attr, int x, int y);
void vga_clear(uint8_t attr);

void vga_load_logo();
void vga_restore_font();
void vga_draw_logo(uint8_t d_x, uint8_t d_y);
void vga_draw_extra_logo(uint8_t d_x, uint8_t d_y);

#endif