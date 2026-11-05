# Revisions

Every revision of every board in this repository, and what is known about each. The audit date is at the end.

**Status** says what has happened to a revision:

- **Made, matches order:** JLCPCB's own copy of the order is byte-identical to the production zip here, and the PCB file regenerates the same copper, mask, outline and holes. This compares files with the order. It says nothing about whether the board works: that's **Tested**.
- **Made, not compared:** the board exists, but its files haven't been compared with an order.
- **Ordered:** placed, and not yet arrived.
- **Drawn:** the files are complete, and the board hasn't been ordered.
- **Never made**, or **To confirm** where nothing on record says either way.

**Holes** is how far the corner mounting holes sit from the board's edges. The standard is 6 mm, and 5 mm on the ACE Board, the CF Adapter and the Keyboard Helper. A dash means a card or cart, which has no corner holes.

| Board | Rev | Status | Tested | Order | Ordered | Made from | Tindie stock | Size (mm) | Holes | Top panel | Enclosure | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| KIM Board | 1.0 | Ordered | — |  |  |  | — | 280×220 | 6 mm | — | — | Order 1, placed 2026-11-02 |
| Keypad Card | 1.0 | Made, matches order | Yes | Y90 | 2026-05-10 | `5652134` | 4 | 100×57.62 | — | — | — |  |
| Keypad Helper | 1.0 | Made, matches order | Yes | Y51 | 2024-07-07 | `6502-COB b8f89eb` | 4 | 100×150 | 6 mm | yes | — | copper drawn differently by today's KiCad, as recorded in audit.py |
| Keypad LCD Helper | 1.0 | Made, matches order | Yes | Y54 | 2024-08-06 | `6502-COB 48c5bde` | 4 | 100.26×64.68 | 5.68–6.25 mm | yes | — |  |
| Keypad LCD Helper | 1.1 | Drawn | — |  |  |  | — | 100×65 | 6 mm | yes | — |  |

The audit last ran on 2026-11-04. Each production zip marked *Made, matches order* was compared byte for byte with JLCPCB's copy, and its PCB regenerated to the same copper, mask, outline and holes. Tindie stock is from the listings as saved on 2026-10-23.

<!-- History: hand-written. tools/revision-audit/register.py keeps everything from here to the end. -->

## History

What changed in each revision of each board, newest first. The table above has the facts about each one.

### Keypad Card

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
