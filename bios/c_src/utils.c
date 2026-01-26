#include "utils.h"

char *itoa(int value, char *str, int base) {
    char *rc = str;
    char *ptr;
    char *low;
 
    // Handle negative numbers for base 10
    if (value < 0 && base == 10) {
        *str++ = '-';
        value = -value;
    }
 
    ptr = str;
 
    // Convert integer to string
    do {
        int rem = value % base;
        *ptr++ = (rem < 10) ? (rem + '0') : (rem - 10 + 'A');
        value /= base;
    } while (value != 0);
 
    // Null-terminate the string
    *ptr-- = '\0';
 
    // Reverse the string
    low = str;
    while (low < ptr) {
        char tmp = *low;
        *low++ = *ptr;
        *ptr-- = tmp;
    }
 
    return rc;
}

char *strcat(char *dest, const char *src) {
    char *rdest = dest;
    while (*dest) dest++;
    while ((*dest++ = *src++) != '\0') {
    }
    return rdest;
}

char *strcpy(char *dest, const char *src) {
    char *rdest = dest;
    while ((*dest++ = *src++) != '\0') {
    }
    return rdest;
}

size_t strlen(const char *s) {
    const char *p = s;
    while (*p) p++;
    return (size_t)(p - s);
}

void *memset(void *s, int c, int n) {
    unsigned char *p = s;
    while (n--) {
        *p++ = (unsigned char)c;
    }
    return s;
}