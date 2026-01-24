#include "cpudetect.h"

#include <stdint.h>

// TODO: Check CPUID presence and use it as well?

//
// Detects Cyrix CPU (486) based on DIV flag behavior.
// Returns: 1 if Cyrix, 0 if Intel/AMD.
//
int is_cyrix_cpu(void) {
    uint16_t ax_out;

    __asm__ __volatile__(
        "pushf\n\t"
        "cli\n\t"
        "xor  %%ax, %%ax\n\t"
        "sahf\n\t"
        "mov  $5, %%ax\n\t"
        "mov  $2, %%bl\n\t"
        "div  %%bl\n\t"
        "lahf\n\t"       /* FLAGS -> AH */
        "popf\n\t"
        : "=&a"(ax_out)  /* AX is the output (AH contains the flags) */
        :                /* no inputs */
        : "bx", "cc", "memory"
    );

    return ((ax_out >> 8) & 0xFF) == 0x02;
}

void detect_486_model(uint16_t cpuid, uint16_t is_cyrix, char *buffer, int print_cpu_id) {
    /* Prefix with vendor */
    strcpy(buffer, (is_cyrix & 1) ? "Cyrix " : "Intel/AMD ");
    if(cpuid < 0x1500) strcat(buffer, "486");

    char cpu_id_buffer[8];
    itoa(cpuid, cpu_id_buffer, 16);

    /* Main model detection based on patterns */
    switch (cpuid & 0xFFF0) {  /* Mask stepping bits */
        case 0x0400: case 0x0410:
            strcat(buffer, "DX");
            break;

        case 0x0420:
            strcat(buffer, "SX");
            break;

        case 0x0430: case 0x0470:
            strcat(buffer, "DX2");
            break;

        case 0x0440:
            strcat(buffer, "SL");
            break;

        case 0x0450:
            strcat(buffer, "SX2");
            break;

        case 0x0480: 
            if (is_cyrix & 1) {
                strcat(buffer, "DX2"); // Cyrix DX2 CPUID is 0x0480
                break;    
            } else {
                strcat(buffer, "DX4");
            }
            break;
        case 0x0490:
            strcat(buffer, "DX4");
            break;

        case 0x1480:
            strcat(buffer, "DX4ODP");
            break;

        case 0x1530:
            strcat(buffer, "Pentium OD");
            break;

        default:
            strcat(buffer, "??");
            break;
    }

    if(print_cpu_id == 1) {
        strcat(buffer," (");
        strcat(buffer, cpu_id_buffer);
        strcat(buffer,"h)");
    }
    
}

int is_fpu_present(void) {
    uint16_t status_word = 0xFFFF;  // Non-zero init
    uint16_t control_word = 0xFFFF; // Non-zero init
    uint32_t cr0, original_cr0;

    // 1. Get CR0 and disable EM (Emulation) / TS (Task Switched)
    //    We need to disable EM so the CPU actually attempts the instruction
    //    instead of instantly faulting to the OS handler.
    asm volatile ("mov %%cr0, %0" : "=r"(original_cr0));
    cr0 = original_cr0 & ~(0x04 | 0x08); // Clear EM (bit 2) and TS (bit 3)
    asm volatile ("mov %0, %%cr0" :: "r"(cr0));

    // 2. The Detection 
    asm volatile (
        "fninit \n\t"        // Reset FPU (if present)
        "fnstsw %0 \n\t"     // Store Status Word (should become 0)
        "fnstcw %1"          // Store Control Word (should become 0x037F)
        : "+m"(status_word), "+m"(control_word) 
        : 
        : "memory"
    );

    // 3. Restore CR0 immediately
    asm volatile ("mov %0, %%cr0" :: "r"(original_cr0));

    // 4. Verification Logic
    //    - If FPU exists: Status is 0, Control is 0x037F.
    //    - If FPU missing: Values remain 0xFFFF (because instructions were NOPs/Ignored).
    if (status_word == 0 && (control_word & 0x103F) == 0x003F) {
        return 1; // FPU Present
    }

    return 0; // No FPU
}
