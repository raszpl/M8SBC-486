# M8SBC-486 AVR FPGA loader

Small AVR firmware that configures the FPGA from on-chip flash at power-up and manages system reset for the M8SBC-486 project

## Pin mapping (ATmega128)
| Pin  | Name           | Dir    | Notes            |
|------|----------------|--------|------------------|
| PE4  | FPGA DONE      | Input  |                  |
| PE5  | FPGA PROG_B    | Output |                  |
| PE6  | FPGA INIT_B    | Input  |                  |
| PF0  | RESET_OUT      | Output | Active high      |
| PF1  | FPGA_REQ_RESET | Input  | Active low       |
| PB4  | RESET_BTN      | Input  | Active low       |
| PB0  | SPI SS         | Output | Kept high        |
| PB1  | SPI SCK        | Output | FPGA CCLK        |
| PB2  | SPI MOSI       | Output | FPGA DIN         |
| PD2  | UART1 RX1      | Input  | Debug UART       |
| PD3  | UART1 TX1      | Output | Debug UART       |


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
- Example:
  - `avrdude -c avrisp -P /dev/ttyUSB0 -b 115200 -p m128 -U flash:w:fpga_loader.hex:i`

## Runtime behavior
- Debug UART: UART1 9600 8N1 on TX1 (PD3)
- On boot:
  - Prints: 'S'
  - Sends bitstream, prints checksum 
  - Prints: 'D' on success, 'E' on DONE low, 'I' if INIT_B timeout
- Reset handling loop:
  - Asserts system reset if FPGA requests or button pressed, prints 'R' on release

## Notes
- I extracted my ATMega128 from a scrap board and the fuses were not quite right for this project. I had to set the fuse bits in avrdude. Correct fuses should be: LFUSE=0xFF, HFUSE=0xDE, EFUSE=0xFF. 
  - Example avrdude command line for flashing with fuses:  `avrdude -c avrisp -P /dev/ttyUSB0 -b 115200 -p m128 -U flash:w:fpga_loader.hex:i -U lfuse:w:0xFF:m -U hfuse:w:0xDE:m -U efuse:w:0xFF:m`