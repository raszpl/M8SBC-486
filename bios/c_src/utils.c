#include "utils.h"

char *strrev(char *str) {
    if (!str || !*str) return str;
    char *start = str;
    char *end = str + strlen(str) - 1;
    char tmp;
    while (start < end) {
        tmp = *start;
        *start++ = *end;
        *end-- = tmp;
    }
    return str;
}

char *itoa(int value, char *str, int base) {
    char *rc = str;
    char *ptr = str;
    unsigned int v = (value < 0 && base == 10) ? (unsigned int)-(long)value : (unsigned int)value;

    if (value < 0 && base == 10) {
        *ptr++ = '-';
        str++;
    }

    do {
        int rem = v % base;
        *ptr++ = (rem < 10) ? (rem + '0') : (rem - 10 + 'A');
        v /= base;
    } while (v != 0);

    *ptr = '\0';
    strrev(str);
    return rc;
}

char *itoapad(int value, char *str, int base, int width) {
    char *rc = str;
    char *ptr = str;
    unsigned int v = (value < 0 && base == 10) ? (unsigned int)-(long)value : (unsigned int)value;

    if (value < 0 && base == 10) {
        *ptr++ = '-';
        str++; 
    }

    do {
        int rem = v % base;
        *ptr++ = (rem < 10) ? (rem + '0') : (rem - 10 + 'A');
        v /= base;
        width--;
    } while (v != 0);

    while (width > 0) { // Pad
        *ptr++ = '0';
        width--;
    }

    *ptr = '\0';
    strrev(str); 
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
