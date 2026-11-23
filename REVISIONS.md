# Revisions

Every revision of every board in this repository, and what is known about each. The dates of the checks are at the end.

**Status** says what has happened to a revision:

- **Made, matches order:** JLCPCB's own copy of the order is byte-identical to the production zip here, and the PCB file regenerates the same copper, mask, outline and holes. This compares files with the order. It says nothing about whether the board works: that's the **Label**.
- **Made, not compared:** the board exists, but its files haven't been compared with an order.
- **Ordered:** placed, and not yet arrived.
- **Drawn:** the files are complete, and the board hasn't been ordered.
- **Never made**, or **To confirm** where nothing on record says either way.

**Label** says whether a builder can rely on a revision. Make the newest revision of a board, and check its label first:

- **Tested:** This revision was built and tested.
- **Proven design:** Not built at this revision, but its circuit is proven. Either it is a tested revision's circuit, or each change copies a circuit built and tested on another board or on the bench, or is a textbook circuit that leaves everything the tested revision does as it was. Any other change is silkscreen text, part values, mounting holes, outline clean-up, parts moved a fraction of a millimetre onto their grid, capacitor pitch, socket outlines, a footprint swap with the same holes, a solder jumper's default, the solder mask or paste at a card edge, or tracks rerouted or pours refilled with DRC and the netlist check passing. A builder can treat it as tested.
- **Untested:** The circuit, the power path or the layout changed in a way that only a built board proves, or the board has never been built at all.

**Holes** is how far the corner mounting holes sit from the board's edges. The standard is 6 mm, and 5 mm on the ACE Board, the CF Adapter and the Keyboard Helper. A dash means a card or cart, which has no corner holes.

| Board | Rev | Status | Label | Order | Ordered | Made from | Tindie stock | Size (mm) | Holes | Top panel | Enclosure | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| KIM Board | 1.0 | Made, matches order | **Untested**: made, but won't be built: its RAM can misread under a heavy load, and Rev 1.1, which fixes that, is built in its place | Y100 | 2026-11-02 | `5c88728` | — | 280×220 | 6 mm | yes | — |  |
| KIM Board | 1.1 | Drawn | **Untested**: no diode in the power path, a 74HCT00 at U5, the RAM's output enable from inverted `RWB`, the ACIA's crystal jumpers (open as made) and silkscreen, each proven on other boards; but no KIM Board has been built yet, and Rev 1.1 will be the first |  |  |  | — | 280×220 | 6 mm | yes | — |  |
| Keypad Card | 1.0 | Made, matches order | **Tested** | Y90 | 2026-05-10 | `5652134` | 4 | 100×57.62 | — | — | — |  |
| Keypad Card | 1.1 | Drawn | **Proven design**: silkscreen text and the bare card edge |  |  |  | — | 100×57.62 | — | — | — |  |
| Keypad Helper | 1.0 | Made, matches order | **Tested** | Y51 | 2024-07-07 | `6502-COB b8f89eb` | 4 | 100×150 | 6 mm | yes | — | copper drawn differently by today's KiCad, as recorded in audit.py |
| Keypad Helper | 1.1 | Drawn | **Proven design**: key names on the silkscreen, socket outlines, capacitor pitch, the keys on a true 19 mm grid |  |  |  | — | 100×150 | 6 mm | yes | — |  |
| Keypad LCD Helper | 1.0 | Made, matches order | **Tested** | Y54 | 2024-08-06 | `6502-COB 48c5bde` | 4 | 100.26×64.68 | 5.68–6.25 mm | yes | — |  |
| Keypad LCD Helper | 1.1 | Drawn | **Proven design**: silkscreen, outline clean-up |  |  |  | — | 100×65 | 6 mm | yes | — |  |

JLCPCB's orders were checked on 2026-11-04: each production zip marked *Made, matches order* was compared byte for byte with JLCPCB's copy, and its PCB regenerated to the same copper, mask, outline and holes. Each time this table is written, every PCB is checked again against its production zip, for copper and drill holes. Tindie stock is from the listings as saved on 2026-10-23.

<!-- History: hand-written. Tools/revision-audit/register.py keeps everything from here to the end. -->

## History

What changed in each revision of each board, newest first. The table above has the facts about each one.

**The generated logos on the boards, 2026-11-14.** Every revision not yet made now prints its logo exactly as `Tools/logos/generate.py` draws it. KiCad keeps a copy of each footprint in the PCB, so when the library's logos were redrawn from Bebas Neue the boards still carried the older traced copies. `Tools/logos/embed.py` put the library's logo into each of the 4 revisions here (KIM Board 1.1, Keypad Card 1.1, Keypad Helper 1.1, Keypad LCD Helper 1.1), keeping the centre of the print where it was, and its check in `derived-check.py` keeps them in step. The difference is under 0.02 mm on each, below what the silkscreen prints. `Tools/revision-audit/gproof.py` shows only the front silkscreen changed on each. Made revisions keep the logo they were made with.

**Title blocks, 2026-11-14.** Every schematic's and PCB's title block names the family as it is: `AC6502 <Board>`, not `6502 <Board>`, on all 8 revisions, the made ones included. The Keypad LCD Helper's two projects pointed at a drawing sheet that exists nowhere (`Worksheets/6502.kicad_wks`); they now use KiCad's default sheet, as every other project does, and their PDFs look like the rest. The title block is drawing-sheet text, which no Gerber layer carries: every PCB plots exactly as before (`Tools/revision-audit/gproof.py`), so no board and no label changed, and the made revisions' production zips are as JLCPCB received them. The schematic PDFs are regenerated. The production zip of each revision not yet made (4) is named from the title, so it is now `AC6502_<Board>_<Rev>.zip`, its contents unchanged. The board logos still read "6502". `Tools/revision-audit/audit.py` checks the titles.

**Reference text size, 2026-11-14.** Every reference printed on the silkscreen of a revision not yet made is 1.0 mm high and wide, with a 0.15 mm stroke, as 970 of the family's 991 already were. `Tools/revision-audit/audit.py` checks it. Every reference here already was.

**IC designators and values, 2026-11-13.** On every revision not yet made, each IC's designator sits centred at one short end of its footprint, the text running along that end, and a through-hole IC's value sits at the other end. Where the centre is taken, the text is aligned to the end's left or right edge. A surface-mount IC's value is hidden, because a small package leaves no room for it, and a module whose outline names it keeps its silk as it is. A ZIF socket's texts sit on its silk outline, not its lever. `Tools/revision-audit/audit.py` checks the values. Moved: KIM Board 1.1 and Keypad Card 1.1. The KIM Board's U8 and U10 keep their texts at their ends, under the LCD module. Silk only: no copper moved, and no label changed. The made revisions keep their silk as made.

**The board logo's place, 2026-11-13.** Every board logo on a revision not yet made sits in one place for its kind of board. A card's or cart's logo reads bottom to top on the left, 2.5 mm from the edge and centred on the body; any other board's runs along its edge on the line of that edge's corner holes, centred or with its end 11.5 mm from the corner (`Tools/logos/standard.json`, checked by `Tools/logos/placement.py`). Moved, each by at most 2.5 mm: KIM Board 1.1, Keypad Card 1.1, Keypad Helper 1.1 and Keypad LCD Helper 1.1. Silk only: no copper moved, DRC is unchanged, and no label changed. The made revisions keep their logos where they are.

**JLCPCB's order-number marker, 2026-11-13.** The `JLCJLCJLCJLC` text is gone from the silkscreen of every revision not yet made: Keypad Card 1.1, Keypad Helper 1.1 and Keypad LCD Helper 1.1 (the KIM Board 1.1 never had it). It told JLCPCB where to print its order number. JLCPCB stopped printing order numbers in May 2026, and its help page now asks for the text not to be there. Only the front silkscreen changed, so no label did. The made revisions keep the text, which JLCPCB ignores.

**Schematic drawing, 2026-11-06.** Every schematic's 6502 bus, cart and card connectors are drawn one way, made revisions included: a short wire and a global label on each used pin, a no-connect flag on each unused one, and GND and VCC as global labels. Bus lines, bus entries and local labels for the bus are gone. Each label's name matches the board's silk. Where pins 4 and 6 carry `EXP1` and `EXP0`, or a cartridge grounds them, a note on the schematic says what `HRDB` does with them (see the README's *Extra pins*). No netlist changed, so no board did: the schematic PDFs are regenerated, and a few PCB files carry the new net names, as text only.

### KIM Board

**Rev 1.1** (drawn, not yet made; the first KIM Board to build, in place of Rev 1.0)

- The silkscreen says `SERIAL (DCE)` at J2, the family's name for a serial port with its role. Rev 1.0's says `DB9 FEMALE (DCE)`.
- The two breadboard outlines on the silkscreen are the breadboards' measured size, 165 × 54 mm each (two BusBoard BB830s, measured by the owner), centred on the same line between them as Rev 1.0's 165.1 × 57.15 outlines. The `BREADBOARDS` keep-out area, where no part may sit, is the same 165 × 108 block, so the bottom-left mounting hole is now clear of it.
- D5, Rev 1.0's 1N5819 between the barrel jack (J7) and the power switch (SW27), is gone (owner, 2026-11-16): the jack goes straight to the switch, on the track that ran through D5, so `VCC` gets the supply's full 5 V. The diode guarded against a reversed supply but dropped `VCC` to about 4.6 V, close to the 4.5 V floor of several parts. Use a centre-positive 5 V supply.
- U5, the 74HC00 that makes the RAM's and ROM's `RB` and `WB` from `PHI2` and `RWB`, is a 74HCT00 (2026-11-11). Its TTL input threshold ends `RB` and `WB` a few nanoseconds later after `PHI2` falls. An Alliance AS6C62256 with a fast-releasing 74HC00 lot in this gate misread at 2 MHz; a 74HCT00 there cured it in the ACE, writes included. Rev 1.0 keeps its 74HC00; a 74HCT00 fits the same socket. The silkscreen's value at U5 reads `74HCT00`.
- U2's `/OE` (pin 22), the RAM's output enable, comes from inverted `RWB` in place of `RB`, as on the ACE Board 1.1 (owner, 2026-11-23): U5 pin 6, the inverter that already fed `WB`'s gate, now also drives the net `RAEB`. On `RB`, the NAND of `RWB` and `PHI2`, the Alliance AS6C62256 lets go of the data bus as soon as `PHI2` falls, before the W65C02S's 10 ns hold time is up, so under load the CPU can read a 0 bit as 1. On inverted `RWB` the RAM holds its byte to the end of every read. `/WE` stays on `WB` and `/CE` on `A15`. The fix was tested on an ACE Board Rev 1.0, the same RAM and gate: there it read clean at every supply from 4.5 to 5.24 V at the board, at 1 MHz and 2 MHz, and lost no write in 20 million. The 74HCT00 at U5 stays, as a second safety measure. While the RAM drives the bus with `PHI2` low, nothing else can: the ROM's `/OE` is on `RB`, the keypad ROM's select (U11) is enabled by `PHI2`, and the VIA and the ACIA drive only while `PHI2` is high.
- Apart from what this list names, the copper, mask, holes and outline are Rev 1.0's.
- Adds the ACIA's optional crystal parts, as on the COB Serial Card: `R24` (1M) across XTLI and XTLO through solder jumper `JP2`, and `C27` (22 pF) from XTLI to ground through `JP3`. Both jumpers ship open, for the R6551AP. Close both for a Rockwell R65C51P1 or R65C51P2, whose oscillator won't start on a bare crystal (an R65C51P2 ran clean this way on a Serial Card on 2026-11-11), or for a WDC W65C51.
- Rev 1.1 is built in place of Rev 1.0 (owner, 2026-11-23). Rev 1.0's RAM can misread under a heavy load, which the RAM output enable above fixes, so Rev 1.0's boards won't be built, and Rev 1.1 is the first KIM Board to be brought up. Anything that bring-up finds goes into a later revision.

**Rev 1.0**

- Initial release, ordered on 2026-11-02 and made by JLCPCB. Not built, and it won't be (owner, 2026-11-23): its RAM can misread under a heavy load, and Rev 1.1, which fixes that, is built in its place. `Hardware/KIM Board/Rev 1.0/` and `Production/KIM Board/Rev 1.0/` match the boards JLCPCB made (order Y100). The Gerbers and drill files in the production zip are byte-for-byte what JLCPCB received.
- D5 is marked do-not-fit in Rev 1.0's files, with a note on the schematic to fit a wire link in its place (owner, 2026-11-16). The board as made has its pads; the 1N5819 there dropped `VCC` to about 4.6 V.

### Keypad Card

**Rev 1.1** (drawn, not yet made; Rev 1.0 is sold first)

- The silkscreen says `W65C21N` at U3, as on the KIM Board. Rev 1.0's says `65C21`. Nothing else changed on the board: the tracks, pads and holes are Rev 1.0's.
- The schematic uses the library's current `PIA 6521` symbol. Rev 1.0's schematic holds an older copy with different pin types, which ERC reports as a mismatch. The pins and their connections are the same.
- The card edge is bare: no solder mask on the tab, front or back, from where its fillets end, so the fingers seat better in the slot and make better contact. Rev 1.0 has mask between the fingers. The fingers carry no solder paste, so no stencil prints paste onto them. The outline is redrawn to the one card shape every card shares, placed by the fingers: it moved up to 0.05 mm from Rev 1.0's, and no track, pad or hole moved. The ground pours are refilled to suit.

**Rev 1.0**

- Initial release, and the board on sale. Built and tested. `Hardware/Keypad Card/Rev 1.0/` and `Production/Keypad Card/Rev 1.0/` match the boards JLCPCB made (order Y90). The Gerbers and drill files in the production zip are byte-for-byte what JLCPCB received.

### Keypad Helper

**Rev 1.1** (drawn, not yet made; Rev 1.0 is sold first)

- U1 (MM74C922) and U2 (74HC00) have socket outlines, as every logic chip in the family does, so a chip can be changed without desoldering it. Their pads and holes are Rev 1.0's: the outline is only silkscreen, and the same sockets fit a Rev 1.0. The parts list adds an 18-pin and a 14-pin socket.
- C1–C4 are 2.5 mm pitch disc capacitors, the family's standard part, where Rev 1.0 has 5 mm. Each keeps its pin 1 where Rev 1.0 has it.
- The 24 keys sit on one true 19 mm grid, as the KIM Board's keypad does. On Rev 1.0, SW6 sits 0.08 mm and SW18–SW20 and SW22–SW24 0.19 mm to the right of their columns. The top's key windows move with them. The tracks to those keys' columns, `X2`–`X4`, move 0.19 mm with them, and the track carrying the `C2` signal, with its via, 0.55 mm to the right, clear of C3's new pad.
- The silkscreen and schematic name each key as the KIM Board's keypad does: `ESC`, `INS`, `PGUP`, `A`, `UP`, `DEL`, `PGDN`, `B`, the digits, `C`–`F`, `LEFT` and `RIGHT`. Rev 1.0 numbers them 0–23. Each key is in the same place and on the same encoder row and column as its namesake on the KIM Board, so it sends the same code.

**Rev 1.0**

- Initial release, and the board on sale. Built and tested. `Hardware/Keypad Helper/Rev 1.0/` and `Production/Keypad Helper/Rev 1.0/` match the boards JLCPCB made (order Y51). The Gerbers and drill files in the production zip are byte-for-byte what JLCPCB received.
- The PCB file was restored to that layout on 2026-11-04. Later edits only changed pad shapes, when footprints were refreshed, so they don't make a Rev 1.1. The schematic and BOM are today's, and they match this copper.
- U1 and U2 use the footprints the board was made with, without the socket outline.

### Keypad LCD Helper

**Rev 1.1** (drawn, not yet made; Rev 1.0 is sold first)

- The silkscreen labels J3 `KEYPAD HELPER`. Rev 1.0's says `KEYBOARD HELPER`.
- The outline is a clean 100 × 65 mm, centred on the mounting holes, which are 6 mm from each edge. Rev 1.0's outline is hand drawn, slightly skewed and 100.26 × 64.69 mm. The holes don't move, so both revisions fit the same plate and top panel.

**Rev 1.0**

- Initial release, and the board on sale. `Hardware/Keypad LCD Helper/Rev 1.0/` and `Production/Keypad LCD Helper/Rev 1.0/` match the boards JLCPCB made (order Y54). The Gerbers and drill files in the production zip are byte-for-byte what JLCPCB received.
