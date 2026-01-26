#ifndef CPUDETECT_H
#define CPUDETECT_H

#include <stdint.h>
#include "utils.h"

int is_cyrix_cpu(void);
void detect_486_model(uint16_t cpuid, uint16_t is_cyrix, char *buffe, int print_cpu_id);
int is_fpu_present(void);

#endif