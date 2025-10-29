MCU      := atmega128
F_CPU    := 16000000UL
CC       := avr-gcc
OBJCOPY  := avr-objcopy
HOSTCC   := gcc

# original Xilinx .bit file
BIT_ORIG ?= m8sbc_main.bit

BIT_BIN  := data.bin
BITFILE  := $(BIT_BIN)

TARGET   := fpga_loader

CFLAGS   := -DF_CPU=$(F_CPU) -mmcu=$(MCU) -Os -Wall -Wextra -std=gnu11
LDFLAGS  := -mmcu=$(MCU) -Wl,-gc-sections

SRCS     := main.c
ASMS     := bitstream.S
OBJS     := main.o bitstream.o

TOOLS    := tool_extract_bit tool_checksum

.PHONY: all clean checksum

all: $(TARGET).hex

# Bit extract tool
tool_extract_bit: tool_extract_bit.c
	$(HOSTCC) -o $@ $<

tool_checksum: tool_checksum.c
	$(HOSTCC) -o $@ $<

# Raw bitstream data extraction from .bit
$(BIT_BIN): $(BIT_ORIG) tool_extract_bit
	./tool_extract_bit $(BIT_ORIG) $(BIT_BIN)

# .incbin wrapper generator
bitstream.S: $(BITFILE)
	@echo "Generating $@ from $<"
	@printf '%s\n' '.section .progmem.bit,"a"' '.global bitstream' '.global bitstream_end' '.type bitstream,@object' 'bitstream:' > $@
	@printf '.incbin "%s"\n' "$<" >> $@
	@printf '%s\n' 'bitstream_end:' >> $@

# ASM
bitstream.o: bitstream.S
	$(CC) $(CFLAGS) -x assembler-with-cpp -c -o $@ $<

# C
main.o: main.c
	$(CC) $(CFLAGS) -c -o $@ $<

# Link
$(TARGET).elf: $(OBJS)
	$(CC) $(CFLAGS) -o $@ $(OBJS) $(LDFLAGS)

# HEX
$(TARGET).hex: $(TARGET).elf
	$(OBJCOPY) -O ihex -R .eeprom $< $@

# Checksum tool
checksum: $(BIT_BIN) tool_checksum
	./tool_checksum $(BIT_BIN)

clean:
	rm -f $(OBJS) $(TARGET).elf $(TARGET).hex bitstream.S $(BIT_BIN) $(TOOLS)

