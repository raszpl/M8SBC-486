#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <input.bit> <output.bin>\n", argv[0]);
        return 1;
    }

    const char *input_path = argv[1];
    const char *output_path = argv[2];

    FILE *in = fopen(input_path, "rb");
    if (!in) {
        perror("Error opening input file");
        return 1;
    }

    // Read entire file into memory
    fseek(in, 0, SEEK_END);
    long filesize = ftell(in);
    rewind(in);

    uint8_t *buffer = malloc(filesize);
    if (!buffer) {
        fclose(in);
        fprintf(stderr, "Memory allocation failed\n");
        return 1;
    }

    fread(buffer, 1, filesize, in);
    fclose(in);

    // Sync marker: 0xFF FF FF FF AA 99 55 66
    const uint8_t sync[] = {0xFF, 0xFF, 0xFF, 0xFF, 0xAA, 0x99, 0x55, 0x66};
    uint8_t *start = NULL;

    for (long i = 0; i <= filesize - sizeof(sync); ++i) {
        if (memcmp(&buffer[i], sync, sizeof(sync)) == 0) {
            start = &buffer[i];
            break;
        }
    }

    if (!start) {
        fprintf(stderr, "Sync marker not found\n");
        free(buffer);
        return 1;
    }

    FILE *out = fopen(output_path, "wb");
    if (!out) {
        perror("Error opening output file");
        free(buffer);
        return 1;
    }

    fwrite(start, 1, filesize - (start - buffer), out);
    fclose(out);
    free(buffer);

    printf("Bitstream extracted to %s\n", output_path);
    return 0;
}

