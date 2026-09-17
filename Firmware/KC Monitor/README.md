KC Monitor
==========

A KIM-1-style keypad/LCD memory monitor for the **Keypad Card (KC)** of the
[AC6502 KIM](https://github.com/acwright/6502-KIM).

KC Monitor is a 6502 cartridge ROM that turns the Keypad Card into a standalone
hex monitor. You can inspect and edit memory, navigate the address space, and
execute code directly from the 24-key keypad and 16×2 LCD. A concurrent,
Wozmon-compatible serial monitor runs at the same time
over the Serial Card, so memory can also be examined, deposited, and executed
from a terminal while the keypad UI stays live. Both consoles run a program the
same way — as a subroutine — so an `RTS` comes back to the monitor whichever one
you launched from.

## Features

- **KIM-1-style keypad monitor** — navigate addresses, edit bytes one nibble at
  a time, and run code from the keypad.
- **16×2 HD44780 LCD display** — shows the current address and the byte stored
  there, plus mode/help on the second line.
- **Execute & return** — launch a program with `UP` from the pad or `XXXX R`
  from the terminal; either runs it as a subroutine, and an `RTS` returns to the
  monitor (and, from the terminal, to a fresh prompt).
- **ESC = break-to-monitor** — press `ESC` to abort a running program from
  anywhere (keypad- or serial-launched) and return to the live monitor.
- **Concurrent Wozmon serial monitor** — the Apple-1 Wozmon command set over the
  Serial Card, running alongside the keypad UI on shared memory.
- **bin2woz compatible** — stream the output of
  [bin2woz](https://github.com/acwright/bin2woz) into the serial port to "upload"
  a binary, then run it with `XXXX R`.

## Hardware

KC Monitor targets the Keypad Card, a cartridge that overlays the `$C000–$FFFF`
address space. It drives:

- A **16×2 HD44780 LCD** and a **24-key keypad** through a **65C21 PIA**.
- The **Serial Card** (R65C51 ACIA) for the concurrent serial monitor. The
  Serial Card is optional: the ACIA is only touched when the BIOS boot probe
  set `HW_SC` in `HW_PRESENT`, so a machine assembled without it comes up as a
  keypad-only monitor rather than reading a floating bus at `$9000`.

| Range | Contents |
|-------|----------|
| `$C000–$DFFF` | PIA registers (mirrored I/O window) |
| `$E000–$FFF9` | Cartridge ROM (AT28C64, 8 KB) |
| `$FFFA–$FFFF` | CPU vectors (NMI, RESET, IRQ) |

The PIA is mapped with A0=RS0, A1=RS1: `$C000` PORTA/DDRA, `$C001` CRA,
`$C002` PORTB/DDRB, `$C003` CRB. Port A carries the keypad code (PA0–PA4) and the
LCD control lines (PA5=RS, PA6=R/W, PA7=E); Port B is the LCD data bus. Keypad
input is interrupt driven via the 74C922 encoder's data-available signal on CA1.

### Startup

Both consoles show the same splash and both hold at the same gate:

```
KIM MONITOR v1.0
--ESC TO START--
```

`ESC` — and only `ESC` — starts the monitor, and one `ESC` starts both. Press
the keypad `ESC` key or send `$1B` from the terminal; either is caught in the
interrupt handler, so the two behave identically. Nothing else is accepted, and
nothing typed or pressed at the splash is echoed, acted on, or held over: the
gate discards the keypad mailbox and the serial receive ring on the way through.

Once the gate opens, the LCD paints the address/byte display and *then* the
serial `> ` prompt appears. The prompt is the signal that the parser is running
— it is never shown ahead of one.

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
8-N-1**.

| Input | Action |
|-------|--------|
| `XXXX` | Examine the byte at address `XXXX` |
| `XXXX.YYYY` | Examine the range `XXXX` through `YYYY` |
| `XXXX: BB BB …` | Deposit bytes starting at `XXXX` |
| `XXXX R` | Run the program at `XXXX` (returns on `RTS`) |

Because the serial and keypad monitors share the same memory, a serial deposit is
visible on the LCD at the next refresh, and vice versa.

#### Two departures from original Wozmon

The syntax is Wozmon's, byte for byte; two behaviours are not.

- **The prompt is `> `**, not `\`.
- **`R` is a `JSR`, not Wozmon's `JMP (XAML)`.** The pad's `UP` key has always
  run the program under the cursor as a subroutine, so a program ending in `RTS`
  lands back in a live monitor. Serial `R` now does the same, and prints a fresh
  prompt on return. Under the original jump semantics an `RTS` left the terminal
  with no prompt and a line buffer still holding the `XXXX R` that launched the
  program, so the next line typed was appended to it and re-ran the program.
  A program that never returns is unaffected, and `ESC` still breaks out of one.

#### Pasting, and RTS/CTS flow control

A pasted program arrives faster than the monitor can swallow it, so the monitor
signals the far end with **RTS**, the same way the BIOS Kernal does: RTS goes up
at `$C0` unread bytes in the 256-byte receive ring and comes down again below
`$80`. **Set your terminal to RTS/CTS hardware flow control** and a paste of any
length arrives whole at 19200 baud; without it the monitor still never loses more
than the odd character, because a full ring now drops the incoming byte rather
than lapping its own reader.

Two consequences worth knowing, both of them the R6551's doing — TIC `00` raises
RTS *and turns the transmitter off*:

- **The monitor owns `$9002`.** Depositing a command-register value there holds
  only until the next character goes out, which puts RTS back where the ring
  says it belongs. There is no way to leave the board mute from the console.
- **The monitor goes quiet while the ring is full.** Above the high-water mark it
  drops what it was going to say rather than lowering RTS to say it, because
  every one of those windows would let the far end push more in and the ring
  would never recover. So a long paste is echoed only in part. The deposits all
  land; read them back when the paste is done.

The panel is repainted once at the end of a batch rather than once per line: a
full `RefreshDisplay` is about 22 ms of LCD time, which is more than a line of
paste takes to arrive at 19200 baud.

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
| `kim.inc` | Machine include — the KIM as it is *with the cartridge fitted* |
| `kim.cfg` | Linker configuration — 8 KB ROM at `$E000` plus CPU vectors |
| `Makefile` | Build system |

### `kim.inc` vs the family-wide `6502.inc`

The BIOS repository ships a `6502.inc` describing the AC6502 family, and it is
the wrong file to build a KIM against. It documents a fully populated ACE with
the whole 32 KB BIOS ROM intact — banked RAM, RTC, CompactFlash, GPIO, SID,
video, BASIC, the machine code monitor and Wozmon. On a KIM none of those cards
are fitted and the top of the ROM is overlaid by this cartridge, so following
that file leads you to call routines that quietly do nothing, to enter a monitor
that is no longer there, and to reuse "spare" RAM that this firmware is
actively using.

`kim.inc` is the KIM's own machine description and is the file to include. It
states what the overlay removes, tags every Kernal entry point with what it
actually does on a KIM (`[WORKS]`, `[SERIAL]`, `[INERT]`, `[FAILS]`, `[BROKEN]`),
defines only hardware the KIM really has — the Keypad Card PIA and the Serial
Card ACIA — and marks the RAM this monitor owns:

| Region | Reserved for |
|--------|--------------|
| `$40–$51` | Monitor and Wozmon parser state (zero page) |
| `$0200–$027F` | Wozmon line buffer — **live**, despite `6502.inc` calling this page the Kernal's input ring |
| `$0400–$04FF` | Serial RX ring, filled by the cartridge's IRQ handler |

Two consequences catch programs written against the family include: `Chrin` and
the ring routines around it always come back empty (the cartridge owns
`IRQ_PTR`, so the Kernal ring is never fed), and `Chrout` reaches the blocking
`SerialChrout`, which hangs forever if no terminal is asserting `/CTS`.

## License

See [LICENSE](LICENSE).
