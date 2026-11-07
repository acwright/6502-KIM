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
- **Proven design:** Not built at this revision, but its circuit is a tested revision's. The only changes are silkscreen text, part values, mounting holes, outline clean-up, capacitor pitch, socket outlines, a footprint swap with the same holes, a solder jumper's default, or tracks rerouted with DRC and the netlist check passing. A builder can treat it as tested.
- **Untested:** The circuit, the power path or the layout changed in a way that only a built board proves, or the board has never been built at all.

**Holes** is how far the corner mounting holes sit from the board's edges. The standard is 6 mm, and 5 mm on the ACE Board, the CF Adapter and the Keyboard Helper. A dash means a card or cart, which has no corner holes.

| Board | Rev | Status | Label | Order | Ordered | Made from | Tindie stock | Size (mm) | Holes | Top panel | Enclosure | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| KIM Board | 1.0 | Ordered | **Untested**: a new board, ordered and not tested yet |  |  |  | — | 280×220 | 6 mm | SVG only | — | Order 1, placed 2026-11-02 |
| KIM Board | 1.1 | Drawn | **Untested**: silkscreen only, but Rev 1.0 hasn't been tested yet |  |  |  | — | 280×220 | 6 mm | SVG only | — |  |
| Keypad Card | 1.0 | Made, matches order | **Tested** | Y90 | 2026-05-10 | `5652134` | 4 | 100×57.62 | — | — | — |  |
| Keypad Card | 1.1 | Drawn | **Proven design**: silkscreen text only |  |  |  | — | 100×57.62 | — | — | — |  |
| Keypad Helper | 1.0 | Made, matches order | **Tested** | Y51 | 2024-07-07 | `6502-COB b8f89eb` | 4 | 100×150 | 6 mm | yes | — | copper drawn differently by today's KiCad, as recorded in audit.py |
| Keypad LCD Helper | 1.0 | Made, matches order | **Tested** | Y54 | 2024-08-06 | `6502-COB 48c5bde` | 4 | 100.26×64.68 | 5.68–6.25 mm | yes | — |  |
| Keypad LCD Helper | 1.1 | Drawn | **Proven design**: silkscreen, outline clean-up |  |  |  | — | 100×65 | 6 mm | yes | — |  |

JLCPCB's orders were checked on 2026-11-04: each production zip marked *Made, matches order* was compared byte for byte with JLCPCB's copy, and its PCB regenerated to the same copper, mask, outline and holes. Each time this table is written, every PCB is checked again against its production zip, for copper and drill holes. Tindie stock is from the listings as saved on 2026-10-23.

<!-- History: hand-written. Tools/revision-audit/register.py keeps everything from here to the end. -->

## History

What changed in each revision of each board, newest first. The table above has the facts about each one.

**Schematic drawing, 2026-11-06.** Every schematic's 6502 bus, cart and card connectors are drawn one way, made revisions included: a short wire and a global label on each used pin, a no-connect flag on each unused one, and GND and VCC as global labels. Bus lines, bus entries and local labels for the bus are gone. Each label's name matches the board's silk. Where pins 4 and 6 carry `EXP1` and `EXP0`, or a cartridge grounds them, a note on the schematic says what `HRDB` does with them (see the README's *Extra pins*). No netlist changed, so no board did: the schematic PDFs are regenerated, and a few PCB files carry the new net names, as text only.

### KIM Board

**Rev 1.1** (drawn, not yet made; Rev 1.0 is built first)

- The silkscreen says `SERIAL (DCE)` at J2. Rev 1.0's says `DB9 FEMALE (DCE)`.
- The two breadboard outlines on the silkscreen are the breadboards' measured size, 165 × 54 mm each (two BusBoard BB830s, measured by the owner), centred on the same line between them as Rev 1.0's 165.1 × 57.15 outlines. The `BREADBOARDS` keep-out area, where no part may sit, is the same 165 × 108 block, so the bottom-left mounting hole is now clear of it.
- Nothing else changed: the copper, mask, holes and outline are Rev 1.0's.
- Rev 1.1 stays open until Rev 1.0 has been brought up. Anything the bring-up finds that the board needs is drawn here.

**Rev 1.0**

- Initial release. Ordered on 2026-11-02, and not yet built or tested.

### Keypad Card

**Rev 1.1** (drawn, not yet made; Rev 1.0 is sold first)

- The silkscreen says `W65C21N` at U3, as on the KIM Board. Rev 1.0's says `65C21`. Nothing else changed on the board: the copper, mask, holes and outline are Rev 1.0's.
- The schematic uses the library's current `PIA 6521` symbol. Rev 1.0's schematic holds an older copy with different pin types, which ERC reports as a mismatch. The pins and their connections are the same.

**Rev 1.0**

- Initial release, and the board on sale. Built and tested. `Hardware/Keypad Card/Rev 1.0/` and `Production/Keypad Card/Rev 1.0/` match the boards JLCPCB made (order Y90). The Gerbers and drill files in the production zip are byte-for-byte what JLCPCB received.

### Keypad Helper

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
