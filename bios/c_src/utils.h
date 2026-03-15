#ifndef UTILS_H
#define UTILS_H

#define size_t uint16_t

#include <stdint.h>

char *strrev(char *str);
char *itoa(int value, char *str, int base);
char *itoapad(int value, char *str, int base, int width);

char *strcat(char *dest, const char *src);
char *strcpy(char *dest, const char *src);

size_t strlen(const char *s);

void *memset(void *s, int c, int n);

#endif
