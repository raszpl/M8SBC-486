#ifndef INTERRUPTS_H
#define INTERRUPTS_H

#include <stdint.h>
#include "x86io.h"

#ifndef NULL
#define NULL 0
#endif

// Initialize the IDT and load it
void idt_init(void);

void pic_remap(int offset1);

void idt_restore_real_mode(void);

static inline void sti() {
	asm volatile ("sti");
}
static inline void cli() {
	asm volatile ("cli");
}
static inline void pic_set_mask(uint8_t mask) {
    outb(0x21, mask);
}

void pit_set_int_freq(uint32_t freq);


void c_isr_irq0();
void c_isr_irq1();

typedef void (*irq1_callback_ptr)(void);
void irq1_register_callback(irq1_callback_ptr func);

extern uint32_t irq0_ticks;

int kb_is_available();
uint8_t kb_get_scancode();
void kb_clear_buffer();

#endif