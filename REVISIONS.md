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
| Keypad Helper | 1.0 | Made, matches order | Yes | Y51 | 2024-07-07 | `6502-COB b8f89eb` | 4 | 100×150 | 6 mm | yes | — |  |
| Keypad LCD Helper | 1.0 | Made, matches order | Yes | Y54 | 2024-08-06 | `6502-COB 48c5bde` | 4 | 100.26×64.68 | 5.68–6.25 mm | yes | — |  |
| Keypad LCD Helper | 1.1 | Drawn | — |  |  |  | — | 100×65 | 6 mm | yes | — |  |

The audit last ran on 2026-11-04. Each production zip marked *Made, matches order* was compared byte for byte with JLCPCB's copy, and its PCB regenerated to the same copper, mask, outline and holes. Tindie stock is from the listings as saved on 2026-10-23.
