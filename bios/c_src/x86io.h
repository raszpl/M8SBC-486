#ifndef X86IO_H
#define X86IO_H
#include <stdint.h>

static inline void outb(uint16_t port, uint8_t val) {
    __asm__ volatile ( "outb %0, %1" : : "a"(val), "d"(port) );
}

static inline uint8_t inb(uint16_t port) {
    uint8_t ret;
    __asm__ volatile ( "inb %1, %0" : "=a"(ret) : "d"(port) );
    return ret;
}

static inline void outw(uint16_t port, uint16_t data) {
    asm volatile("outw %w0, %w1" : : "a"(data), "d"(port));
}

static inline uint16_t inw(uint16_t port) {
    uint16_t result;
    asm volatile("inw %w1, %w0" : "=a"(result) : "d"(port));
    return result;
}


static inline void io_wait(void) {
    inb(0x80);
}

#endif