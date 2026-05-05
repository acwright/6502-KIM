6502-KIM
========

<!-- ![6502-KIM.png](./Images/6502-KIM.png) -->

An **AC6502** retro-style 8-bit computer based on the **65C02** microprocessor.

---

## Overview

The AC6502 ecosystem is a family of open-source, 65C02-based computers sharing a common architecture, memory map, and [BIOS](https://github.com/acwright/6502-BIOS). Each computer in the family is purpose-built for a different use case but runs the same software and firmware.

The **KIM** (Keypad Input Monitor) is a complete, self-contained 65C02 computer built around three boards: the **KIM Board** (CPU, memory, serial, and GPIO), the **Keypad Helper** (keypad matrix), and the **Keypad LCD Helper** (16x2 LCD display). The **Keypad Expander** allows the Keypad Helper and Keypad LCD Helper to be used as accessories with other AC6502 systems.

---

## Architecture

All AC6502 computers share:

- **CPU**: 65C02 (or accurate emulation)
- **Memory**: 32KB RAM + 32KB ROM, with optional banked RAM expansion
- **Memory Map**: Standardized across the ecosystem — zero page, stack, I/O space ($8000–$9FFF), system ROM, and interrupt vectors at $FFFA–$FFFF
- **Bus**: 16-bit address bus, 8-bit bidirectional data bus, standard 65C02 control signals (RW, PHI2, RESET, IRQ, NMI, RDY, SYNC)
- **BIOS**: A common [BIOS](https://github.com/acwright/6502-BIOS) provides the kernel, monitor, and BASIC interpreter across all systems

---

## Hardware

This repository contains KiCad 7.0+ PCB designs for all KIM hardware.

### KIM Board
`Hardware/KIM Board/`

The main board hosting the W65C02S CPU and core peripherals. Provides:

- **CPU**: W65C02S running at 1 MHz
- **RAM**: 32KB SRAM (62256) at $0000–$7FFF
- **ROM**: 32KB EEPROM (28C256) at $8000–$FFFF
- **Serial**: 65C51 ACIA with MAX232 level shifter (RS-232 via DB9, 50–19200 baud)
- **GPIO**: 65C22 VIA (20 GPIO pins, 2× 16-bit timers, shift register)
- **Clock**: On-board oscillator (1–8 MHz, selectable by swapping oscillator)
- **Reset**: Power-on RC reset circuit and manual reset button
- **Power**: 5V DC, 2–3A

### Keypad Helper
`Hardware/Keypad Helper/`

Keyboard controller companion board for the KIM. Provides:

- **Keyboard Controller**: ATmega1284P running KIM Controller firmware
- **Input**: PS/2 keyboard connector and 8×8 keyboard matrix header

### Keypad LCD Helper
`Hardware/Keypad LCD Helper/`

Keyboard controller companion board with an integrated LCD display for the KIM. Provides:

- **Keyboard Controller**: ATmega1284P running KIM Controller firmware
- **Input**: PS/2 keyboard connector and 8×8 keyboard matrix header
- **Display**: Integrated LCD panel

### Keypad Expander
`Hardware/Keypad Expander/`

Adapter board that allows the Keypad Helper and Keypad LCD Helper to be used as accessories with other AC6502 systems.

---

## Firmware

`Firmware/KE Monitor/`

The **KE Monitor** is a 6502 assembly language cartridge ROM for the KIM system.

---

## CAD
`CAD/`

3D-printable enclosure bases and laser-cut top panels for the KIM system.

---

## Production
`Production/`

JLCPCB-ready Gerber files and BOM/CPL for PCB fabrication and assembly.

---

## Schematics
`Schematics/`

PDF schematics for all KIM hardware.

---

## Libraries
`Libraries/`

Shared KiCad symbol and footprint libraries used across all AC6502 hardware projects.

---

## AC6502 Projects

| Project | Description |
|---------|-------------|
| [6502-BIOS](https://github.com/acwright/6502-BIOS) | The shared BIOS (kernel, monitor, BASIC) for all AC6502 computers |
| [6502-PRG](https://github.com/acwright/6502-PRG) | Template for writing assembly language programs |
| [6502-CRT](https://github.com/acwright/6502-CRT) | Template for writing assembly language cartridges |
| [6502-EMULATOR](https://github.com/acwright/6502-EMULATOR) | Node.js-based AC6502 emulator |
| [6502-WEBULATOR](https://github.com/acwright/6502-WEBULATOR) | Web-based AC6502 emulator |

---

## AC6502 Systems

| Project | Description |
|---------|-------------|
| [6502-KIM](https://github.com/acwright/6502-KIM) | All-in-one single-PCB computer — the COB experience without the backplane |
| [6502-COB](https://github.com/acwright/6502-COB) | Computer on a Backplane — modular desktop computer with expandable card slots |
| [6502-DEV](https://github.com/acwright/6502-DEV) | Development Environment Vehicle — emulation-based dev system |
| [6502-KIM](https://github.com/acwright/6502-KIM) | KIM-1 inspired minimal computer (you are here) |
| [6502-VCS](https://github.com/acwright/6502-VCS) | Video Computer System — cartridge-based retro gaming console |

---

## License

Hardware designs are released under the [CERN Open Hardware Licence Version 2 – Permissive](https://ohwr.org/cern_ohl_p_v2.txt).  
Firmware is released under the [MIT License](./Firmware/KIM%20Controller/LICENSE).
