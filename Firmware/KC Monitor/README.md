KC Monitor
==========

A KIM-1-style keypad/LCD memory monitor for the **Keypad Card (KC)** of the
[A.C. Wright 6502-KIM project](https://github.com/acwright/6502-KIM).

KC Monitor is a 6502 cartridge ROM that turns the Keypad Card into a standalone
hex monitor. You can inspect and edit memory, navigate the address space, and
execute code directly from the 24-key keypad and 16×2 LCD. A concurrent, 
Wozmon-compatible serial monitor runs at the same time
over the Serial Card, so memory can also be examined, deposited, and executed
from a terminal while the keypad UI stays live.

## Features

- **KIM-1-style keypad monitor** — navigate addresses, edit bytes one nibble at
  a time, and run code from the keypad.
- **16×2 HD44780 LCD display** — shows the current address and the byte stored
  there, plus mode/help on the second line.
- **Execute & return** — launch a program with `UP`; it runs as a subroutine and
  returns to the monitor on `RTS`.
- **ESC = break-to-monitor** — press `ESC` to abort a running program from
  anywhere (keypad- or serial-launched) and return to the live monitor.
- **Concurrent Wozmon serial monitor** — a faithful Apple-1 Wozmon command set
  over the Serial Card, running alongside the keypad UI on shared memory.
- **bin2woz compatible** — stream the output of
  [bin2woz](https://github.com/acwright/bin2woz) into the serial port to "upload"
  a binary, then run it with `XXXX R`.

## Hardware

KC Monitor targets the Keypad Card, a cartridge that overlays the `$C000–$FFFF`
address space. It drives:

- A **16×2 HD44780 LCD** and a **24-key keypad** through a **65C21 PIA**.
- The **Serial Card** (R65C51 ACIA) for the concurrent serial monitor.

| Range | Contents |
|-------|----------|
| `$C000–$DFFF` | PIA registers (mirrored I/O window) |
| `$E000–$FFF9` | Cartridge ROM (AT28C64, 8 KB) |
| `$FFFA–$FFFF` | CPU vectors (NMI, RESET, IRQ) |

The PIA is mapped with A0=RS0, A1=RS1: `$C000` PORTA/DDRA, `$C001` CRA,
`$C002` PORTB/DDRB, `$C003` CRB. Port A carries the keypad code (PA0–PA4) and the
LCD control lines (PA5=RS, PA6=R/W, PA7=E); Port B is the LCD data bus. Keypad
input is interrupt driven via the 74C922 encoder's data-available signal on CA1.

### Keypad Layout

The 24 keys map to monitor functions:

| Key | Function |
|-----|----------|
| `0`–`F` | Enter a hex nibble (address or data) |
| `LEFT` / `RIGHT` | Move the current address ∓1 |
| `PGUP` / `PGDN` | Move the current address ∓`$0100` |
| `INS` | Toggle insert (data-edit) mode |
| `DEL` | Write `$00` at the current address |
| `UP` | Execute code at the current address (returns on `RTS`) |
| `ESC` | Abort a running program back to the monitor |

In navigation mode, hex keys shift the current address one nibble at a time
(KIM-1 style). In `INS` mode, hex keys edit the byte at the current address.

### Serial Monitor

The serial monitor speaks the Apple-1 Wozmon command language at **19200 baud,
8-N-1**. The only difference from original Wozmon is the prompt, which is `>`
(not `\`).

| Input | Action |
|-------|--------|
| `XXXX` | Examine the byte at address `XXXX` |
| `XXXX.YYYY` | Examine the range `XXXX` through `YYYY` |
| `XXXX: BB BB …` | Deposit bytes starting at `XXXX` |
| `XXXX R` | Run the program at `XXXX` |

Because the serial and keypad monitors share the same memory, a serial deposit is
visible on the LCD at the next refresh, and vice versa.

## Building

### Prerequisites

#### cc65 toolchain

KC Monitor is assembled with [cc65](https://github.com/cc65/cc65) (the `cl65`
driver). On macOS:

```bash
brew install cc65
```

#### Optional: minipro (for EEPROM burning)

```bash
brew install minipro
```

### Build Commands

| Command | Description |
|---------|-------------|
| `make` | Assemble the cartridge ROM (`KC Monitor.bin`) |
| `make view` | Display a hexdump of the built ROM |
| `make eeprom` | Burn the ROM to an AT28C64 EEPROM via a TL866 programmer |
| `make clean` | Remove build artifacts |

### Build Output

```bash
make
```

Produces:

- `KC Monitor.bin` — 8 KB ROM image (`$E000–$FFFF`), ready to burn to an AT28C64.
- `KC Monitor.lst` — assembly listing file for debugging.

### Programming the EEPROM

```bash
make eeprom
```

Burns `KC Monitor.bin` to an AT28C64 EEPROM using a TL866-compatible programmer
and minipro.

## Project Structure

| File | Purpose |
|------|---------|
| `KC Monitor.asm` | Firmware source — LCD driver, keypad input, monitor state machine, serial monitor, vectors |
| `6502.inc` | System include — Kernal jump table, hardware registers, constants |
| `6502.cfg` | Linker configuration — 8 KB ROM at `$E000` plus CPU vectors |
| `Makefile` | Build system |

## License

See [LICENSE](LICENSE).
