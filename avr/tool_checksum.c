#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <filename>\n", argv[0]);
        return 1;
    }

    FILE *f = fopen(argv[1], "rb");
    if (!f) {
        perror("Error opening file");
        return 1;
    }

    uint32_t checksum = 0;
    int c;

    while ((c = fgetc(f)) != EOF) {
        checksum += (uint8_t)c;
    }

    fclose(f);

    printf("Checksum: %u (0x%08X)\n", checksum, checksum);
    return 0;
}
