# M8SBC-486 AVR FPGA loader

Small AVR firmware that configures the FPGA from on-chip flash at power-up, stores CMOS configuration and manages system reset for the M8SBC-486 project

## Pin mapping (ATmega128)
| Pin  | Name           | Dir    | Notes                                             |
|------|----------------|--------|---------------------------------------------------|
| PE4  | FPGA DONE      | Input  |                                                   |
| PE5  | FPGA PROG_B    | Output |                                                   |
| PE6  | FPGA INIT_B    | In/Out | Used also for CMOS communication (DATA)           |
| PF0  | RESET_OUT      | Output | Active high                                       |
| PF1  | FPGA_REQ_RESET | Input  | Active low                                        |
| PB4  | RESET_BTN      | Input  | Active low                                        |
| PB0  | SPI SS         | Output | Kept high                                         |
| PB1  | SPI SCK        | Output | FPGA CCLK                                         |
| PB2  | SPI MOSI       | Output | FPGA DIN, Used also for CMOS communication (CLK)  |
| PD2  | UART1 RX1      | Input  | Debug UART                                        |
| PD3  | UART1 TX1      | Output | Debug UART                                        |


## Prerequisites
- avr-gcc, avr-objcopy, make
- Host gcc (for extract and checksum tools)
- Xilinx .bit file (default name: m8sbc_main.bit)

## Build
- Place .bit file in this folder (it's possible to override it by changing `BIT_ORIG` in Makefile)
- Build:
  - `make`
- Optional: verify embedded bitstream checksum:
  - `make checksum`

## Flashing
- Example with correct fuses for this project:
  - `avrdude -c avrisp -P /dev/ttyUSB0 -b 115200 -p m128 -U flash:w:fpga_loader.hex:i -U lfuse:w:0x3F:m -U hfuse:w:0xD6:m -U efuse:w:0xFF:m`

## Runtime behavior
- Debug UART: UART1 57600 8N1 on TX1 (PD3)
- On power on:
  - Checks internal EEPROM (CMOS storage)
  - Loads bitstream to the FPGA
  - Restores CMOS from EEPROM to the FPGA
- On idle:
  - Waits for altered CMOS configuration from FPGA and stores it to the EEPROM
  - Waits for reset button press or FPGA reset request signal to pull for a 1 second global system reset

