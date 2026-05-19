6502-KIM
========

![6502-KIM.png](./Images/6502-KIM.png)

An **AC6502** retro-style 8-bit computer based on the **65C02** microprocessor.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Systems](#systems)
- [Software](#software)
- [Hardware](#hardware)
  - [Main Board](#main-board)
  - [Serial Card](#serial-card)
  - [Backplane Helper](#backplane-helper)
  - [Keypad Card](#keypad-card)
  - [Keypad Helper](#keypad-helper)
  - [Keypad LCD Helper](#keypad-lcd-helper)
- [Firmware](#firmware)
- [CAD](#cad)
- [Production](#production)
- [Schematics](#schematics)
- [Libraries](#libraries)
- [Bill of Materials](#bill-of-materials)
  - [Keypad Card](#keypad-card-1)
  - [Keypad Helper](#keypad-helper-1)
  - [Keypad LCD Helper](#keypad-lcd-helper-1)
- [License](#license)

## Overview

The AC6502 ecosystem is a family of open-source, 65C02-based computers sharing a common architecture, memory map, and [BIOS](https://github.com/acwright/6502-BIOS). Each computer in the family is purpose-built for a different use case but runs the same software and firmware.

The **KIM** (Keypad Input Monitor) is a complete, self-contained 65C02 computer built around the **[Main Board](https://github.com/acwright/6502-VCS)** from the VCS project, the **[Serial Card](https://github.com/acwright/6502-COB)** and **[Backplane Helper](https://github.com/acwright/6502-COB)** from the COB project, and the **Keypad Card** — a card that the **Keypad Helper** (keypad matrix) and **Keypad LCD Helper** (16x2 LCD display) attach to.

## Architecture

All AC6502 computers share:

- **CPU**: 65C02 (or accurate emulation)
- **Memory**: 32KB RAM + 32KB ROM, with optional banked RAM expansion
- **Memory Map**: Standardized across the ecosystem — zero page, stack, I/O space ($8000–$9FFF), system ROM, and interrupt vectors at $FFFA–$FFFF
- **Bus**: 16-bit address bus, 8-bit bidirectional data bus, standard 65C02 control signals (RW, PHI2, RESET, IRQ, NMI, RDY, SYNC)
- **BIOS**: A common [BIOS](https://github.com/acwright/6502-BIOS) provides the kernel, monitor, and BASIC interpreter across all systems

## Systems

| Project | Description |
|---------|-------------|
| [6502-ACE](https://github.com/acwright/6502-ACE) | All-in-one Computer Experience — A single board computer |
| [6502-COB](https://github.com/acwright/6502-COB) | Computer On a Backplane — Modular desktop computer with expandable card slots |
| [6502-DEV](https://github.com/acwright/6502-DEV) | Development Environment Vehicle — Emulation-based dev system |
| [6502-KIM](https://github.com/acwright/6502-KIM) | Keyboard Input Monitor - KIM-1 inspired minimal computer (YOU ARE HERE) |
| [6502-VCS](https://github.com/acwright/6502-VCS) | Video Computer System — Cartridge-based retro gaming console |

## Software

| Project | Description |
|---------|-------------|
| [6502-BIOS](https://github.com/acwright/6502-BIOS) | The shared BIOS (kernel, monitor, BASIC) for all AC6502 computers |
| [6502-PRG](https://github.com/acwright/6502-PRG) | Template project for writing assembly language programs |
| [6502-CRT](https://github.com/acwright/6502-CRT) | Template project for writing assembly language cartridges |
| [6502-EMULATOR](https://github.com/acwright/6502-EMULATOR) | Node.js-based AC6502 emulator |
| [6502-WEBULATOR](https://github.com/acwright/6502-WEBULATOR) | Web-based AC6502 emulator |

## Hardware

This repository contains KiCad 7.0+ PCB designs for the KIM-specific hardware. The KIM also uses boards, cards and helpers from the [6502-VCS](https://github.com/acwright/6502-VCS) and [6502-COB](https://github.com/acwright/6502-COB) projects.

### Main Board
[`Hardware/Main Board/`](https://github.com/acwright/6502-VCS/tree/main/Hardware/Main%20Board) *(6502-VCS)*

The core board containing the 65C02 CPU, 32KB SRAM, 32KB EEPROM, clock, and reset circuitry. Runs at 1 MHz and provides the bus connection for the other boards.

### Serial Card
[`Hardware/Serial Card/`](https://github.com/acwright/6502-COB/tree/main/Hardware/Serial%20Card) *(6502-COB)*

RS-232 serial communication via 65C51 ACIA and MAX232 level shifter.

### Backplane Helper
[`Hardware/Backplane Helper/`](https://github.com/acwright/6502-COB/tree/main/Hardware/Backplane%20Helper) *(6502-COB)*

Adds additional card slots to interconnect the Main Board, Serial Card, and Keypad Card on the KIM system.

### Keypad Card
`Hardware/Keypad Card/`

Interface card that the Keypad Helper and Keypad LCD Helper attach to. Connects the keypad accessories to the AC6502 bus via the Backplane Helper.

### Keypad Helper
`Hardware/Keypad Helper/`

Keyboard controller companion board that attaches to the Keypad Card. Provides:

- **Keyboard Controller**: ATmega1284P running KIM Controller firmware
- **Input**: PS/2 keyboard connector and 8×8 keyboard matrix header

### Keypad LCD Helper
`Hardware/Keypad LCD Helper/`

Keyboard controller companion board with an integrated LCD display that attaches to the Keypad Card. Provides:

- **Keyboard Controller**: ATmega1284P running KIM Controller firmware
- **Input**: PS/2 keyboard connector and 8×8 keyboard matrix header
- **Display**: Integrated LCD panel

## Firmware

`Firmware/KC Monitor/`

The **KC Monitor** is a 6502 assembly language cartridge ROM for the KIM system.

## CAD
`CAD/`

3D-printable enclosure bases and laser-cut top panels for the KIM system.

## Production
`Production/`

JLCPCB-ready Gerber files and BOM/CPL for PCB fabrication and assembly.

## Schematics
`Schematics/`

PDF schematics for all KIM hardware.

## Libraries
`Libraries/`

Shared KiCad symbol and footprint libraries used across all AC6502 hardware projects.

## Bill of Materials

### Keypad Card

| Reference | Qty | Value | Description | LCSC | DigiKey | Mouser | Other |
|-----------|-----|-------|-------------|------|---------|--------|-------|
| C1–C4 | 4 | 100nF | SMD Capacitor 0805 | [C49678](https://www.lcsc.com/search?q=C49678) | | | |
| J2, J3 | 2 | PORT A/B | Box Header 2×6 2.54mm | | [2057-BHR-12-VUA-ND](https://www.digikey.com/en/products/filter?keywords=2057-BHR-12-VUA-ND) | | |
| U1, U2 | 2 | 74HC138 | 3-to-8 Line Decoder | [C5602](https://www.lcsc.com/search?q=C5602) | | | |
| U3 | 1 | 65C21 | Peripheral Interface Adapter | | | [955-W65C21N6TPG-14](https://www.mouser.com/ProductDetail/955-W65C21N6TPG-14) | |
| U4 | 1 | AT28C64 | 8K×8 EEPROM | | [AT28C64B-15PU-ND](https://www.digikey.com/en/products/filter?keywords=AT28C64B-15PU-ND) | [556-AT28C64B15PU](https://www.mouser.com/ProductDetail/556-AT28C64B15PU) | |

### Keypad Helper

| Reference | Qty | Value | Description | DigiKey | Mouser | Other |
|-----------|-----|-------|-------------|---------|--------|-------|
| C1, C2, C4 | 3 | 100nF | Disc Capacitor | [478-5732-ND](https://www.digikey.com/en/products/filter?keywords=478-5732-ND) | | |
| C3 | 1 | 1µF | Disc Capacitor | [478-7667-ND](https://www.digikey.com/en/products/filter?keywords=478-7667-ND) | | |
| D1, D2 | 2 | 1N914 | Small Signal Diode | [1N914FS-ND](https://www.digikey.com/en/products/filter?keywords=1N914FS-ND) | | |
| J1 | 1 | PORT | Box Header 2×6 2.54mm | [2057-BHR-12-VUA-ND](https://www.digikey.com/en/products/filter?keywords=2057-BHR-12-VUA-ND) | | [AMAZON](https://www.amazon.com/uxcell-2-54mm-2x6-Pin-Straight-Connector/dp/B07DJYVZV2) |
| R1, R2 | 2 | 100kΩ | Resistor | | | [AMAZON](https://www.amazon.com/ALLECIN-8W-Metal-Film-Resistor/dp/B0C77TM3NR) |
| SW1–SW24 | 24 | 0–23 | Cherry MX Switch 1.00u | [CH196-ND](https://www.digikey.com/en/products/filter?keywords=CH196-ND) | | [AMAZON](https://www.amazon.com/dp/B0FYR5TV3X) |
| U1 | 1 | MM74C922 | 16-Key Encoder | | | [AMAZON](https://www.amazon.com/Todiys-74C922N-MM74C922N-Encoder-MM74C922/dp/B08MCJY9LP) |
| U2 | 1 | 74HC00 | Quad 2-Input NAND Gate | [296-1563-5-ND](https://www.digikey.com/en/products/filter?keywords=296-1563-5-ND) | [595-SN74HC00N](https://www.mouser.com/ProductDetail/595-SN74HC00N) | |

### Keypad LCD Helper

| Reference | Qty | Value | Description | DigiKey | Mouser | Other |
|-----------|-----|-------|-------------|---------|--------|-------|
| J1, J2, J3 | 3 | PORT A/B/KEYPAD | Box Header 2×6 2.54mm | [2057-BHR-12-VUA-ND](https://www.digikey.com/en/products/filter?keywords=2057-BHR-12-VUA-ND) | | [AMAZON](https://www.amazon.com/uxcell-2-54mm-2x6-Pin-Straight-Connector/dp/B07DJYVZV2) |
| R1 | 1 | R | Resistor | | | |
| U2 | 1 | LCD-16X2 | 16×2 LCD Display | | | [AMAZON](https://www.amazon.com/MECCANIXITY-Display-Backlight-Interface-Adapter/dp/B0DSFXK7QK) |
| VR1 | 1 | 10kΩ | Potentiometer | [3386F-103LF-ND](https://www.digikey.com/en/products/filter?keywords=3386F-103LF-ND) | | |

## License

Hardware designs are released under the [CERN Open Hardware Licence Version 2 – Permissive](https://ohwr.org/cern_ohl_p_v2.txt).  
Firmware is released under the [MIT License](./Firmware/KIM%20Controller/LICENSE).
