# Bill of materials: 6502-KIM

Every part for every board in this repository, by revision, with supplier numbers.

## How to use this

1. **Find your board and revision** in [Which revision do I have?](#which-revision-do-i-have)
2. **Read the [known issues](#known-issues)** for that revision, because they change what you buy or fit.
3. **Order from the table for your revision.** Each revision links to files you can upload to Digi-Key and Mouser. Those files are for one board, so multiply the quantities if you're building more. If a site asks which column is which, the first column is its part number and the third is the quantity. A cart only holds what that supplier sells, so check the table for anything else, such as chips from Jameco.
4. **Set the jumpers** before the first power-up. The README's [Jumpers](README.md#jumpers) section says which ones each board needs, and the table for your revision lists the shunts.

**Pre-soldered parts.** Some boards on Tindie come with their surface-mount parts already soldered. Parts marked **Yes** under Pre-soldered are the ones soldered on those boards. Check your listing, because others are sold as a bare PCB. Each revision that has such parts also has a `through-hole` cart that leaves them out. To solder a bare board yourself, use the full cart.

**Suppliers.** Every part has one set of numbers, so the same resistor is the same order line on every board. The numbers were read from Digi-Key and Mouser on 2026-11-04, and stock changes. A blank supplier cell means that supplier doesn't sell the part, or only sells it in bulk.

**The `bom.csv` files** under `Production/` are for JLCPCB assembly. They list the same parts. A blank LCSC cell there means JLCPCB doesn't place that part, and JLCPCB's "missing parts" warning about it is expected.

## Which revision do I have?

Look on the board: the silk prints the revision next to the copyright line. [REVISIONS.md](REVISIONS.md) has the facts for each one, and its history lists what changed between them.

**To make a new board, make the newest revision**, and check its label first. The README's [Which revision to make](README.md#which-revision-to-make) explains the three labels: **Tested**, **Proven design** and **Untested**.

| Board | Revision | What the silk says | Status | Label |
|---|---|---|---|---|
| [KIM Board](#kim-board) | 1.0 | Rev 1.0 | Ordered, not tested yet | **Untested**: a new board, ordered and not tested yet |
| [KIM Board](#kim-board) | 1.1 | Rev 1.1 | Drawn, not made yet | **Untested**: silkscreen and a 74HCT00 at U5, but Rev 1.0 hasn't been tested yet |
| [Keypad Card](#keypad-card) | 1.0 | Rev 1.0 | Made, tested | **Tested** |
| [Keypad Card](#keypad-card) | 1.1 | Rev 1.1 | Drawn, not made yet | **Proven design**: silkscreen text and the bare card edge |
| [Keypad Helper](#keypad-helper) | 1.0 | Rev 1.0 | Made, tested | **Tested** |
| [Keypad LCD Helper](#keypad-lcd-helper) | 1.0 | Rev 1.0 | Made, tested | **Tested** |
| [Keypad LCD Helper](#keypad-lcd-helper) | 1.1 | Rev 1.1 | Drawn, not made yet | **Proven design**: silkscreen, outline clean-up |

## Known issues

These change what you buy or fit. The boards themselves stay as they were made.

| Board | Revision | Parts | Issue |
|---|---|---|---|
| Keypad Card | 1.0 | U3 | The silk says 65C21; fit the W65C21N listed here. |

### Build notes

How to build each board, where it needs more than its parts list.

<!-- Build notes: hand-written. Tools/bom/gen_bom.py keeps everything between these two markers. -->

**KIM Board**

The keycaps are clear, with a separate cap, so a printed legend sits inside each one. [`CAD/Keycaps/KIM Keycaps.pdf`](./CAD/Keycaps/KIM%20Keycaps.pdf) is the sheet to print.

The base plate, the screws, the standoffs and the feet are in the [plate mounting drawing](./CAD/Bases/Plate%20Mounting%20Drawing.png).

U3 and U9 have to be programmed before they're fitted: U3 with a BIOS from [6502-BIOS](https://github.com/acwright/6502-BIOS)'s `v1.x` branch, because the KIM doesn't take BIOS 2.x, and U9 with `Firmware/KC Monitor/KC Monitor.bin`. That takes an EEPROM programmer.

<!-- End of build notes. -->

## KIM Board

### KIM Board Rev 1.1

Drawn, not made yet. **Untested**: silkscreen and a 74HCT00 at U5, but Rev 1.0 hasn't been tested yet.

Cart files: [digikey.csv](BOM/KIM%20Board/Rev%201.1/digikey.csv), [mouser.csv](BOM/KIM%20Board/Rev%201.1/mouser.csv)

| Reference | Qty | Value | Part | Digi-Key | Mouser | Other |
|---|---|---|---|---|---|---|
| C1–C5, C7, C12, C14–C25 | 19 | 100nF | KYOCERA AVX SR205C104KAR | [478-3187-ND](https://www.digikey.com/en/products/filter?keywords=478-3187-ND) | [581-SR205C104KAR](https://www.mouser.com/ProductDetail/581-SR205C104KAR) |  |
| C6, C26 | 2 | 10uF | Panasonic EEA-GA1C100 | [P14482-ND](https://www.digikey.com/en/products/filter?keywords=P14482-ND) | [667-EEA-GA1C100](https://www.mouser.com/ProductDetail/667-EEA-GA1C100) |  |
| C8–C11, C13 | 5 | 1uF | KYOCERA AVX SR205E105MAR | [478-7667-ND](https://www.digikey.com/en/products/filter?keywords=478-7667-ND) | [581-SR205E105MAR](https://www.mouser.com/ProductDetail/581-SR205E105MAR) |  |
| D1, D2 | 2 | BAT85 | Vishay BAT85S-TR | [BAT85SCT-ND](https://www.digikey.com/en/products/filter?keywords=BAT85SCT-ND) | [78-BAT85S](https://www.mouser.com/ProductDetail/78-BAT85S) |  |
| D3, D4 | 2 | 1N914 | onsemi 1N914 | [1N914FS-ND](https://www.digikey.com/en/products/filter?keywords=1N914FS-ND) | [512-1N914](https://www.mouser.com/ProductDetail/512-1N914) |  |
| D5 | 1 | 1N5819 | Vishay 1N5819-E3/54 | [1N5819-E3/54GICT-ND](https://www.digikey.com/en/products/filter?keywords=1N5819-E3%2F54GICT-ND) | [625-1N5819-E3](https://www.mouser.com/ProductDetail/625-1N5819-E3) |  |
| D6 | 1 | POWER LED | Würth Elektronik 151031VS06000 | [732-5008-ND](https://www.digikey.com/en/products/filter?keywords=732-5008-ND) | [710-151031VS06000](https://www.mouser.com/ProductDetail/710-151031VS06000) |  |
| J1 | 1 | KIM ENABLE | Pin header 1×3, 2.54 mm, cut from a strip | [S1011EC-40-ND](https://www.digikey.com/en/products/filter?keywords=S1011EC-40-ND) | [200-TSW14007TS](https://www.mouser.com/ProductDetail/200-TSW14007TS) |  |
| J2 | 1 | SERIAL (DCE) | Amphenol D09S33E4GX00LF | [609-1487-ND](https://www.digikey.com/en/products/filter?keywords=609-1487-ND) | [649-D09S33E4GX00LF](https://www.mouser.com/ProductDetail/649-D09S33E4GX00LF) |  |
| J3 | 1 | CTS EN | Pin header 1×3, 2.54 mm, cut from a strip | [S1011EC-40-ND](https://www.digikey.com/en/products/filter?keywords=S1011EC-40-ND) | [200-TSW14007TS](https://www.mouser.com/ProductDetail/200-TSW14007TS) |  |
| J4 | 1 | CART | TE Connectivity 5-5530843-4 | [A31723-ND](https://www.digikey.com/en/products/filter?keywords=A31723-ND) | [571-5-5530843-4](https://www.mouser.com/ProductDetail/571-5-5530843-4) |  |
| J5 | 1 | BUS | Würth Elektronik 61204021621 | [732-5401-ND](https://www.digikey.com/en/products/filter?keywords=732-5401-ND) | [710-61204021621](https://www.mouser.com/ProductDetail/710-61204021621) |  |
| J7 | 1 | 5V DC | Same Sky PJ-102AH | [CP-102AH-ND](https://www.digikey.com/en/products/filter?keywords=CP-102AH-ND) | [490-PJ-102AH](https://www.mouser.com/ProductDetail/490-PJ-102AH) |  |
| Q1 | 1 | 2N3904 | onsemi 2N3904BU | [2N3904FS-ND](https://www.digikey.com/en/products/filter?keywords=2N3904FS-ND) | [512-2N3904BU](https://www.mouser.com/ProductDetail/512-2N3904BU) |  |
| R1–R5, R15, R18, R23 | 8 | 10k | YAGEO MFR-12FTF52-10K | [13-MFR-12FTF52-10KCT-ND](https://www.digikey.com/en/products/filter?keywords=13-MFR-12FTF52-10KCT-ND) | [603-MFR-12FTF52-10K](https://www.mouser.com/ProductDetail/603-MFR-12FTF52-10K) |  |
| R6–R14 | 9 | 1k | YAGEO MFR-12FTF52-1K | [13-MFR-12FTF52-1KCT-ND](https://www.digikey.com/en/products/filter?keywords=13-MFR-12FTF52-1KCT-ND) | [603-MFR-12FTF52-1K](https://www.mouser.com/ProductDetail/603-MFR-12FTF52-1K) |  |
| R16 | 1 | 1M | YAGEO MFR-12FTF52-1M | [13-MFR-12FTF52-1MCT-ND](https://www.digikey.com/en/products/filter?keywords=13-MFR-12FTF52-1MCT-ND) | [603-MFR-12FTF52-1M](https://www.mouser.com/ProductDetail/603-MFR-12FTF52-1M) |  |
| R17 | 1 | 47k | YAGEO MFR-12FTF52-47K | [13-MFR-12FTF52-47KCT-ND](https://www.digikey.com/en/products/filter?keywords=13-MFR-12FTF52-47KCT-ND) | [603-MFR-12FTF52-47K](https://www.mouser.com/ProductDetail/603-MFR-12FTF52-47K) |  |
| R20, R21 | 2 | 100k | YAGEO MFR-12FTF52-100K | [13-MFR-12FTF52-100KCT-ND](https://www.digikey.com/en/products/filter?keywords=13-MFR-12FTF52-100KCT-ND) | [603-MFR-12FTF52-100K](https://www.mouser.com/ProductDetail/603-MFR-12FTF52-100K) |  |
| R22 | 1 | 330 | YAGEO MFR-12FTF52-330R | [13-MFR-12FTF52-330RCT-ND](https://www.digikey.com/en/products/filter?keywords=13-MFR-12FTF52-330RCT-ND) | [603-MFR-12FTF52-330R](https://www.mouser.com/ProductDetail/603-MFR-12FTF52-330R) |  |
| SW1–SW24 | 24 | Keyswitch | Cherry Americas LLC MX2A-E1NA | [1644-MX2A-E1NA-ND](https://www.digikey.com/en/products/filter?keywords=1644-MX2A-E1NA-ND) | [540-MX2A-E1NA](https://www.mouser.com/ProductDetail/540-MX2A-E1NA) |  |
| SW25 | 1 | IO ENABLE | CTS Electronic Components 206-8 | [CT2068-ND](https://www.digikey.com/en/products/filter?keywords=CT2068-ND) | [774-2068](https://www.mouser.com/ProductDetail/774-2068) |  |
| SW26 | 1 | RESET | Same Sky (Formerly CUI Devices) TS02-66-50-BK-160-LCR-D | [2223-TS02-66-50-BK-160-LCR-D-ND](https://www.digikey.com/en/products/filter?keywords=2223-TS02-66-50-BK-160-LCR-D-ND) | [179-TS026650BK160LCR](https://www.mouser.com/ProductDetail/179-TS026650BK160LCR) |  |
| SW27 | 1 | POWER | E-Switch 400MSP1R6BLKM6QE | [EG4326-ND](https://www.digikey.com/en/products/filter?keywords=EG4326-ND) | [612-400MSP1R6BLKM6QE](https://www.mouser.com/ProductDetail/612-400MSP1R6BLKM6QE) |  |
| U1 | 1 | 65C02 | Western Design Center (WDC) W65C02S6TPG-14 |  | [955-W65C02S6TPG-14](https://www.mouser.com/ProductDetail/955-W65C02S6TPG-14) |  |
| U2 | 1 | AS6C62256 | Alliance Memory AS6C62256-55PCN | [1450-1033-ND](https://www.digikey.com/en/products/filter?keywords=1450-1033-ND) | [913-AS6C62256-55PCN](https://www.mouser.com/ProductDetail/913-AS6C62256-55PCN) |  |
| U3 | 1 | AT28C256 | Microchip Technology AT28C256-15PU | [AT28C256-15PU-ND](https://www.digikey.com/en/products/filter?keywords=AT28C256-15PU-ND) | [556-AT28C25615PU](https://www.mouser.com/ProductDetail/556-AT28C25615PU) |  |
| U4, U6, U17 | 3 | 74HC00 | Texas Instruments SN74HC00N | [296-1563-5-ND](https://www.digikey.com/en/products/filter?keywords=296-1563-5-ND) | [595-SN74HC00N](https://www.mouser.com/ProductDetail/595-SN74HC00N) |  |
| U5 | 1 | 74HCT00 | Texas Instruments SN74HCT00N | [296-1603-5-ND](https://www.digikey.com/en/products/filter?keywords=296-1603-5-ND) | [595-SN74HCT00N](https://www.mouser.com/ProductDetail/595-SN74HCT00N) |  |
| U7, U10, U11 | 3 | 74HC138 | Texas Instruments SN74HC138N | [296-1575-5-ND](https://www.digikey.com/en/products/filter?keywords=296-1575-5-ND) | [595-SN74HC138N](https://www.mouser.com/ProductDetail/595-SN74HC138N) |  |
| U8 | 1 | W65C21N | Western Design Center (WDC) W65C21N6TPG-14 |  | [955-W65C21N6TPG-14](https://www.mouser.com/ProductDetail/955-W65C21N6TPG-14) |  |
| U9 | 1 | AT28C64 | Microchip Technology AT28C64B-15PU | [AT28C64B-15PU-ND](https://www.digikey.com/en/products/filter?keywords=AT28C64B-15PU-ND) | [556-AT28C64B15PU](https://www.mouser.com/ProductDetail/556-AT28C64B15PU) |  |
| U12 | 1 | LM555 | Texas Instruments LM555CN/NOPB | [LM555CNNS/NOPB-ND](https://www.digikey.com/en/products/filter?keywords=LM555CNNS%2FNOPB-ND) | [926-LM555CN/NOPB](https://www.mouser.com/ProductDetail/926-LM555CN%2FNOPB) |  |
| U13 | 1 | LCD-16X2 | LCD-16X2, LCD-16X2 |  |  | [Amazon](https://www.amazon.com/dp/B0DSFXK7QK) |
| U14 | 1 | MAX232 | Texas Instruments MAX232N | [296-1402-5-ND](https://www.digikey.com/en/products/filter?keywords=296-1402-5-ND) | [595-MAX232N](https://www.mouser.com/ProductDetail/595-MAX232N) |  |
| U15 | 1 | R6551AP | Rockwell R6551AP |  |  | [Jameco 43318](https://www.jameco.com/z/R6551AP-Rockwell-IC-6551-Asynchronous-Communication-Interface-Adapter-DIP-28-pin_43318.html) |
| U16 | 1 | MM74C922 | onsemi MM74C922N |  |  | [Jameco 44564](https://www.jameco.com/z/74C922-Major-Brands-IC-74C922-16-20-Key-Encoder-DIP-18-pin_44564.html) |
| VR1 | 1 | 10k | Bourns Inc. 3386F-1-103LF | [3386F-103LF-ND](https://www.digikey.com/en/products/filter?keywords=3386F-103LF-ND) | [652-3386F-1-103LF](https://www.mouser.com/ProductDetail/652-3386F-1-103LF) |  |
| X1 | 1 | 1 MHz | ECS Inc. ECS-100AX-010 | [X937-ND](https://www.digikey.com/en/products/filter?keywords=X937-ND) | [520-TCF100-X](https://www.mouser.com/ProductDetail/520-TCF100-X) |  |
| Y1 | 1 | 1.8432 MHz | Abracon LLC AB-1.8432MHZ-B2 | [535-9009-ND](https://www.digikey.com/en/products/filter?keywords=535-9009-ND) | [815-AB-1.8432-B2](https://www.mouser.com/ProductDetail/815-AB-1.8432-B2) |  |
| U4–U6, U17 | 4 | Socket | IC socket, 14-pin, 0.3 in | [3M5474-ND](https://www.digikey.com/en/products/filter?keywords=3M5474-ND) | [517-4814-3004-CP](https://www.mouser.com/ProductDetail/517-4814-3004-CP) | |
| U2, U9, U15 | 3 | Socket | IC socket, 28-pin, 0.6 in | [3M5481-ND](https://www.digikey.com/en/products/filter?keywords=3M5481-ND) | [517-4828-6004-CP](https://www.mouser.com/ProductDetail/517-4828-6004-CP) | |
| U7, U10, U11, U14 | 4 | Socket | IC socket, 16-pin, 0.3 in | [3M5475-ND](https://www.digikey.com/en/products/filter?keywords=3M5475-ND) | [517-4816-3004-CP](https://www.mouser.com/ProductDetail/517-4816-3004-CP) | |
| U1, U8 | 2 | Socket | IC socket, 40-pin, 0.6 in | [3M5471-ND](https://www.digikey.com/en/products/filter?keywords=3M5471-ND) | [517-4840-6000-CP](https://www.mouser.com/ProductDetail/517-4840-6000-CP) | |
| U16 | 1 | Socket | IC socket, 18-pin, 0.3 in | [3M5464-ND](https://www.digikey.com/en/products/filter?keywords=3M5464-ND) | [517-4818-3000-CP](https://www.mouser.com/ProductDetail/517-4818-3000-CP) | |
| U3 | 1 | Socket | 28-pin ZIF socket, or an ordinary 28-pin socket | [3M2802-ND](https://www.digikey.com/en/products/filter?keywords=3M2802-ND) | [517-228-1277-00](https://www.mouser.com/ProductDetail/517-228-1277-00) | |
| U12 | 1 | Socket | IC socket, 8-pin, 0.3 in | [3M5473-ND](https://www.digikey.com/en/products/filter?keywords=3M5473-ND) | [517-4808-3004-CP](https://www.mouser.com/ProductDetail/517-4808-3004-CP) | |
| J6 | 2 | | Female header 1×20, 2.54 mm | [S7018-ND](https://www.digikey.com/en/products/filter?keywords=S7018-ND) |  |  |
| J6 | 1 | | Female header 1×10, 2.54 mm | [S7008-ND](https://www.digikey.com/en/products/filter?keywords=S7008-ND) |  |  |
| U13 | 1 | | Female header 1×16, 2.54 mm | [S7014-ND](https://www.digikey.com/en/products/filter?keywords=S7014-ND) |  |  |
| The breadboards | 2 | | BusBoard BB830 breadboard | [4526-BB830-ND](https://www.digikey.com/en/products/filter?keywords=4526-BB830-ND) | [854-BB830](https://www.mouser.com/ProductDetail/854-BB830) |  |
| SW1–SW24 | 24 | | Clear two-piece keycap for Cherry MX switches |  |  | [Amazon](https://www.amazon.com/dp/B0G2WJBLBC) |
| J7 | 1 | | 5 V DC power supply, centre positive |  |  |  |
| J2 | 1 | | Straight-through DB-9 serial cable |  |  |  |
| J1, J3 | 2 | | Shunt, 2.54 mm | [S9337-ND](https://www.digikey.com/en/products/filter?keywords=S9337-ND) |  |  |

Pin headers are cut from strips, and the cart files count whole strips.

J6 is one footprint, built from three strips of header. U13 also takes a 1×16 pin header, cut from the strip above.

**Do not fit** R19: parallel with VR1 to make ~10 k.

- **D6:** Green shown. The colour is the builder's choice.
- **J5:** Male box header with a keying notch, for a 40-way ribbon cable.
- **J7:** Replaces GCT DCJ200-10-A-K1-K, now obsolete, which older builds used. Its pads and body match this footprint on the datasheet. No board has been built with it yet.
- **SW1–SW24:** Cherry MX2A RGB Blue, clear housing, as on the owner's Amazon kit. MX1A-E1NN (black housing) is the deeper-stocked alternative; Digi-Key CH196-ND, Mouser 540-MX1A-E1NN.
- **U5:** The RAM's RB/WB gate (2026-11-11): its TTL thresholds end RB and WB a few ns later after PHI2 falls. The part tested in the ACE's U14.
- **U13:** Common hobby 16×2 LCD; any HD44780-compatible module with the same pinout.
- **U15:** Rockwell R6551AP, out of production. Do not substitute a W65C51.
- **U16:** Buy from Jameco. Out of production at Digi-Key and Mouser.

### KIM Board Rev 1.0

Ordered, not tested yet. **Untested**: a new board, ordered and not tested yet.

Cart files: [digikey.csv](BOM/KIM%20Board/Rev%201.0/digikey.csv), [mouser.csv](BOM/KIM%20Board/Rev%201.0/mouser.csv)

| Reference | Qty | Value | Part | Digi-Key | Mouser | Other |
|---|---|---|---|---|---|---|
| C1–C5, C7, C12, C14–C25 | 19 | 100nF | KYOCERA AVX SR205C104KAR | [478-3187-ND](https://www.digikey.com/en/products/filter?keywords=478-3187-ND) | [581-SR205C104KAR](https://www.mouser.com/ProductDetail/581-SR205C104KAR) |  |
| C6, C26 | 2 | 10uF | Panasonic EEA-GA1C100 | [P14482-ND](https://www.digikey.com/en/products/filter?keywords=P14482-ND) | [667-EEA-GA1C100](https://www.mouser.com/ProductDetail/667-EEA-GA1C100) |  |
| C8–C11, C13 | 5 | 1uF | KYOCERA AVX SR205E105MAR | [478-7667-ND](https://www.digikey.com/en/products/filter?keywords=478-7667-ND) | [581-SR205E105MAR](https://www.mouser.com/ProductDetail/581-SR205E105MAR) |  |
| D1, D2 | 2 | BAT85 | Vishay BAT85S-TR | [BAT85SCT-ND](https://www.digikey.com/en/products/filter?keywords=BAT85SCT-ND) | [78-BAT85S](https://www.mouser.com/ProductDetail/78-BAT85S) |  |
| D3, D4 | 2 | 1N914 | onsemi 1N914 | [1N914FS-ND](https://www.digikey.com/en/products/filter?keywords=1N914FS-ND) | [512-1N914](https://www.mouser.com/ProductDetail/512-1N914) |  |
| D5 | 1 | 1N5819 | Vishay 1N5819-E3/54 | [1N5819-E3/54GICT-ND](https://www.digikey.com/en/products/filter?keywords=1N5819-E3%2F54GICT-ND) | [625-1N5819-E3](https://www.mouser.com/ProductDetail/625-1N5819-E3) |  |
| D6 | 1 | POWER LED | Würth Elektronik 151031VS06000 | [732-5008-ND](https://www.digikey.com/en/products/filter?keywords=732-5008-ND) | [710-151031VS06000](https://www.mouser.com/ProductDetail/710-151031VS06000) |  |
| J1 | 1 | KIM ENABLE | Pin header 1×3, 2.54 mm, cut from a strip | [S1011EC-40-ND](https://www.digikey.com/en/products/filter?keywords=S1011EC-40-ND) | [200-TSW14007TS](https://www.mouser.com/ProductDetail/200-TSW14007TS) |  |
| J2 | 1 | DB9 FEMALE (DCE) | Amphenol D09S33E4GX00LF | [609-1487-ND](https://www.digikey.com/en/products/filter?keywords=609-1487-ND) | [649-D09S33E4GX00LF](https://www.mouser.com/ProductDetail/649-D09S33E4GX00LF) |  |
| J3 | 1 | CTS EN | Pin header 1×3, 2.54 mm, cut from a strip | [S1011EC-40-ND](https://www.digikey.com/en/products/filter?keywords=S1011EC-40-ND) | [200-TSW14007TS](https://www.mouser.com/ProductDetail/200-TSW14007TS) |  |
| J4 | 1 | CART | TE Connectivity 5-5530843-4 | [A31723-ND](https://www.digikey.com/en/products/filter?keywords=A31723-ND) | [571-5-5530843-4](https://www.mouser.com/ProductDetail/571-5-5530843-4) |  |
| J5 | 1 | BUS | Würth Elektronik 61204021621 | [732-5401-ND](https://www.digikey.com/en/products/filter?keywords=732-5401-ND) | [710-61204021621](https://www.mouser.com/ProductDetail/710-61204021621) |  |
| J7 | 1 | 5V DC | Same Sky PJ-102AH | [CP-102AH-ND](https://www.digikey.com/en/products/filter?keywords=CP-102AH-ND) | [490-PJ-102AH](https://www.mouser.com/ProductDetail/490-PJ-102AH) |  |
| Q1 | 1 | 2N3904 | onsemi 2N3904BU | [2N3904FS-ND](https://www.digikey.com/en/products/filter?keywords=2N3904FS-ND) | [512-2N3904BU](https://www.mouser.com/ProductDetail/512-2N3904BU) |  |
| R1–R5, R15, R18, R23 | 8 | 10k | YAGEO MFR-12FTF52-10K | [13-MFR-12FTF52-10KCT-ND](https://www.digikey.com/en/products/filter?keywords=13-MFR-12FTF52-10KCT-ND) | [603-MFR-12FTF52-10K](https://www.mouser.com/ProductDetail/603-MFR-12FTF52-10K) |  |
| R6–R14 | 9 | 1k | YAGEO MFR-12FTF52-1K | [13-MFR-12FTF52-1KCT-ND](https://www.digikey.com/en/products/filter?keywords=13-MFR-12FTF52-1KCT-ND) | [603-MFR-12FTF52-1K](https://www.mouser.com/ProductDetail/603-MFR-12FTF52-1K) |  |
| R16 | 1 | 1M | YAGEO MFR-12FTF52-1M | [13-MFR-12FTF52-1MCT-ND](https://www.digikey.com/en/products/filter?keywords=13-MFR-12FTF52-1MCT-ND) | [603-MFR-12FTF52-1M](https://www.mouser.com/ProductDetail/603-MFR-12FTF52-1M) |  |
| R17 | 1 | 47k | YAGEO MFR-12FTF52-47K | [13-MFR-12FTF52-47KCT-ND](https://www.digikey.com/en/products/filter?keywords=13-MFR-12FTF52-47KCT-ND) | [603-MFR-12FTF52-47K](https://www.mouser.com/ProductDetail/603-MFR-12FTF52-47K) |  |
| R20, R21 | 2 | 100k | YAGEO MFR-12FTF52-100K | [13-MFR-12FTF52-100KCT-ND](https://www.digikey.com/en/products/filter?keywords=13-MFR-12FTF52-100KCT-ND) | [603-MFR-12FTF52-100K](https://www.mouser.com/ProductDetail/603-MFR-12FTF52-100K) |  |
| R22 | 1 | 330 | YAGEO MFR-12FTF52-330R | [13-MFR-12FTF52-330RCT-ND](https://www.digikey.com/en/products/filter?keywords=13-MFR-12FTF52-330RCT-ND) | [603-MFR-12FTF52-330R](https://www.mouser.com/ProductDetail/603-MFR-12FTF52-330R) |  |
| SW1–SW24 | 24 | Keyswitch | Cherry Americas LLC MX2A-E1NA | [1644-MX2A-E1NA-ND](https://www.digikey.com/en/products/filter?keywords=1644-MX2A-E1NA-ND) | [540-MX2A-E1NA](https://www.mouser.com/ProductDetail/540-MX2A-E1NA) |  |
| SW25 | 1 | IO ENABLE | CTS Electronic Components 206-8 | [CT2068-ND](https://www.digikey.com/en/products/filter?keywords=CT2068-ND) | [774-2068](https://www.mouser.com/ProductDetail/774-2068) |  |
| SW26 | 1 | RESET | Same Sky (Formerly CUI Devices) TS02-66-50-BK-160-LCR-D | [2223-TS02-66-50-BK-160-LCR-D-ND](https://www.digikey.com/en/products/filter?keywords=2223-TS02-66-50-BK-160-LCR-D-ND) | [179-TS026650BK160LCR](https://www.mouser.com/ProductDetail/179-TS026650BK160LCR) |  |
| SW27 | 1 | POWER | E-Switch 400MSP1R6BLKM6QE | [EG4326-ND](https://www.digikey.com/en/products/filter?keywords=EG4326-ND) | [612-400MSP1R6BLKM6QE](https://www.mouser.com/ProductDetail/612-400MSP1R6BLKM6QE) |  |
| U1 | 1 | 65C02 | Western Design Center (WDC) W65C02S6TPG-14 |  | [955-W65C02S6TPG-14](https://www.mouser.com/ProductDetail/955-W65C02S6TPG-14) |  |
| U2 | 1 | AS6C62256 | Alliance Memory AS6C62256-55PCN | [1450-1033-ND](https://www.digikey.com/en/products/filter?keywords=1450-1033-ND) | [913-AS6C62256-55PCN](https://www.mouser.com/ProductDetail/913-AS6C62256-55PCN) |  |
| U3 | 1 | AT28C256 | Microchip Technology AT28C256-15PU | [AT28C256-15PU-ND](https://www.digikey.com/en/products/filter?keywords=AT28C256-15PU-ND) | [556-AT28C25615PU](https://www.mouser.com/ProductDetail/556-AT28C25615PU) |  |
| U4–U6, U17 | 4 | 74HC00 | Texas Instruments SN74HC00N | [296-1563-5-ND](https://www.digikey.com/en/products/filter?keywords=296-1563-5-ND) | [595-SN74HC00N](https://www.mouser.com/ProductDetail/595-SN74HC00N) |  |
| U7, U10, U11 | 3 | 74HC138 | Texas Instruments SN74HC138N | [296-1575-5-ND](https://www.digikey.com/en/products/filter?keywords=296-1575-5-ND) | [595-SN74HC138N](https://www.mouser.com/ProductDetail/595-SN74HC138N) |  |
| U8 | 1 | W65C21N | Western Design Center (WDC) W65C21N6TPG-14 |  | [955-W65C21N6TPG-14](https://www.mouser.com/ProductDetail/955-W65C21N6TPG-14) |  |
| U9 | 1 | AT28C64 | Microchip Technology AT28C64B-15PU | [AT28C64B-15PU-ND](https://www.digikey.com/en/products/filter?keywords=AT28C64B-15PU-ND) | [556-AT28C64B15PU](https://www.mouser.com/ProductDetail/556-AT28C64B15PU) |  |
| U12 | 1 | LM555 | Texas Instruments LM555CN/NOPB | [LM555CNNS/NOPB-ND](https://www.digikey.com/en/products/filter?keywords=LM555CNNS%2FNOPB-ND) | [926-LM555CN/NOPB](https://www.mouser.com/ProductDetail/926-LM555CN%2FNOPB) |  |
| U13 | 1 | LCD-16X2 | LCD-16X2, LCD-16X2 |  |  | [Amazon](https://www.amazon.com/dp/B0DSFXK7QK) |
| U14 | 1 | MAX232 | Texas Instruments MAX232N | [296-1402-5-ND](https://www.digikey.com/en/products/filter?keywords=296-1402-5-ND) | [595-MAX232N](https://www.mouser.com/ProductDetail/595-MAX232N) |  |
| U15 | 1 | R6551AP | Rockwell R6551AP |  |  | [Jameco 43318](https://www.jameco.com/z/R6551AP-Rockwell-IC-6551-Asynchronous-Communication-Interface-Adapter-DIP-28-pin_43318.html) |
| U16 | 1 | MM74C922 | onsemi MM74C922N |  |  | [Jameco 44564](https://www.jameco.com/z/74C922-Major-Brands-IC-74C922-16-20-Key-Encoder-DIP-18-pin_44564.html) |
| VR1 | 1 | 10k | Bourns Inc. 3386F-1-103LF | [3386F-103LF-ND](https://www.digikey.com/en/products/filter?keywords=3386F-103LF-ND) | [652-3386F-1-103LF](https://www.mouser.com/ProductDetail/652-3386F-1-103LF) |  |
| X1 | 1 | 1 MHz | ECS Inc. ECS-100AX-010 | [X937-ND](https://www.digikey.com/en/products/filter?keywords=X937-ND) | [520-TCF100-X](https://www.mouser.com/ProductDetail/520-TCF100-X) |  |
| Y1 | 1 | 1.8432 MHz | Abracon LLC AB-1.8432MHZ-B2 | [535-9009-ND](https://www.digikey.com/en/products/filter?keywords=535-9009-ND) | [815-AB-1.8432-B2](https://www.mouser.com/ProductDetail/815-AB-1.8432-B2) |  |
| U4–U6, U17 | 4 | Socket | IC socket, 14-pin, 0.3 in | [3M5474-ND](https://www.digikey.com/en/products/filter?keywords=3M5474-ND) | [517-4814-3004-CP](https://www.mouser.com/ProductDetail/517-4814-3004-CP) | |
| U2, U9, U15 | 3 | Socket | IC socket, 28-pin, 0.6 in | [3M5481-ND](https://www.digikey.com/en/products/filter?keywords=3M5481-ND) | [517-4828-6004-CP](https://www.mouser.com/ProductDetail/517-4828-6004-CP) | |
| U7, U10, U11, U14 | 4 | Socket | IC socket, 16-pin, 0.3 in | [3M5475-ND](https://www.digikey.com/en/products/filter?keywords=3M5475-ND) | [517-4816-3004-CP](https://www.mouser.com/ProductDetail/517-4816-3004-CP) | |
| U1, U8 | 2 | Socket | IC socket, 40-pin, 0.6 in | [3M5471-ND](https://www.digikey.com/en/products/filter?keywords=3M5471-ND) | [517-4840-6000-CP](https://www.mouser.com/ProductDetail/517-4840-6000-CP) | |
| U16 | 1 | Socket | IC socket, 18-pin, 0.3 in | [3M5464-ND](https://www.digikey.com/en/products/filter?keywords=3M5464-ND) | [517-4818-3000-CP](https://www.mouser.com/ProductDetail/517-4818-3000-CP) | |
| U3 | 1 | Socket | 28-pin ZIF socket, or an ordinary 28-pin socket | [3M2802-ND](https://www.digikey.com/en/products/filter?keywords=3M2802-ND) | [517-228-1277-00](https://www.mouser.com/ProductDetail/517-228-1277-00) | |
| U12 | 1 | Socket | IC socket, 8-pin, 0.3 in | [3M5473-ND](https://www.digikey.com/en/products/filter?keywords=3M5473-ND) | [517-4808-3004-CP](https://www.mouser.com/ProductDetail/517-4808-3004-CP) | |
| J6 | 2 | | Female header 1×20, 2.54 mm | [S7018-ND](https://www.digikey.com/en/products/filter?keywords=S7018-ND) |  |  |
| J6 | 1 | | Female header 1×10, 2.54 mm | [S7008-ND](https://www.digikey.com/en/products/filter?keywords=S7008-ND) |  |  |
| U13 | 1 | | Female header 1×16, 2.54 mm | [S7014-ND](https://www.digikey.com/en/products/filter?keywords=S7014-ND) |  |  |
| The breadboards | 2 | | BusBoard BB830 breadboard | [4526-BB830-ND](https://www.digikey.com/en/products/filter?keywords=4526-BB830-ND) | [854-BB830](https://www.mouser.com/ProductDetail/854-BB830) |  |
| SW1–SW24 | 24 | | Clear two-piece keycap for Cherry MX switches |  |  | [Amazon](https://www.amazon.com/dp/B0G2WJBLBC) |
| J7 | 1 | | 5 V DC power supply, centre positive |  |  |  |
| J2 | 1 | | Straight-through DB-9 serial cable |  |  |  |
| J1, J3 | 2 | | Shunt, 2.54 mm | [S9337-ND](https://www.digikey.com/en/products/filter?keywords=S9337-ND) |  |  |

Pin headers are cut from strips, and the cart files count whole strips.

J6 is one footprint, built from three strips of header. U13 also takes a 1×16 pin header, cut from the strip above.

**Do not fit** R19: parallel with VR1 to make ~10 k.

- **D6:** Green shown. The colour is the builder's choice.
- **J5:** Male box header with a keying notch, for a 40-way ribbon cable.
- **J7:** Replaces GCT DCJ200-10-A-K1-K, now obsolete, which older builds used. Its pads and body match this footprint on the datasheet. No board has been built with it yet.
- **SW1–SW24:** Cherry MX2A RGB Blue, clear housing, as on the owner's Amazon kit. MX1A-E1NN (black housing) is the deeper-stocked alternative; Digi-Key CH196-ND, Mouser 540-MX1A-E1NN.
- **U13:** Common hobby 16×2 LCD; any HD44780-compatible module with the same pinout.
- **U15:** Rockwell R6551AP, out of production. Do not substitute a W65C51.
- **U16:** Buy from Jameco. Out of production at Digi-Key and Mouser.


## Keypad Card

### Keypad Card Rev 1.1

Drawn, not made yet. **Proven design**: silkscreen text and the bare card edge.

Cart files: [digikey.csv](BOM/Keypad%20Card/Rev%201.1/digikey.csv), [mouser.csv](BOM/Keypad%20Card/Rev%201.1/mouser.csv), [digikey-through-hole.csv](BOM/Keypad%20Card/Rev%201.1/digikey-through-hole.csv), [mouser-through-hole.csv](BOM/Keypad%20Card/Rev%201.1/mouser-through-hole.csv)

| Reference | Qty | Value | Part | Digi-Key | Mouser | Other | Pre-soldered |
|---|---|---|---|---|---|---|---|
| C1–C4 | 4 | 100nF | YAGEO CC0805KRX7R9BB104 | [311-1140-1-ND](https://www.digikey.com/en/products/filter?keywords=311-1140-1-ND) | [603-CC805KRX7R9BB104](https://www.mouser.com/ProductDetail/603-CC805KRX7R9BB104) | LCSC [C49678](https://www.lcsc.com/search?q=C49678) | Yes |
| J2 | 1 | PORT A | Adam Tech BHR-12-VUA | [2057-BHR-12-VUA-ND](https://www.digikey.com/en/products/filter?keywords=2057-BHR-12-VUA-ND) | [737-BHR-12-VUA](https://www.mouser.com/ProductDetail/737-BHR-12-VUA) | 2057-BHR-12-VUA-ND | |
| J3 | 1 | PORT B | Adam Tech BHR-12-VUA | [2057-BHR-12-VUA-ND](https://www.digikey.com/en/products/filter?keywords=2057-BHR-12-VUA-ND) | [737-BHR-12-VUA](https://www.mouser.com/ProductDetail/737-BHR-12-VUA) | 2057-BHR-12-VUA-ND | |
| U1, U2 | 2 | 74HC138 | Nexperia USA Inc. 74HC138D,653 | [1727-2781-1-ND](https://www.digikey.com/en/products/filter?keywords=1727-2781-1-ND) | [771-74HC138D-T](https://www.mouser.com/ProductDetail/771-74HC138D-T) | LCSC [C5602](https://www.lcsc.com/search?q=C5602) | Yes |
| U3 | 1 | W65C21N | Western Design Center (WDC) W65C21N6TPG-14 |  | [955-W65C21N6TPG-14](https://www.mouser.com/ProductDetail/955-W65C21N6TPG-14) |  | |
| U4 | 1 | AT28C64 | Microchip Technology AT28C64B-15PU | [AT28C64B-15PU-ND](https://www.digikey.com/en/products/filter?keywords=AT28C64B-15PU-ND) | [556-AT28C64B15PU](https://www.mouser.com/ProductDetail/556-AT28C64B15PU) |  | |
| U4 | 1 | Socket | IC socket, 28-pin, 0.6 in | [3M5481-ND](https://www.digikey.com/en/products/filter?keywords=3M5481-ND) | [517-4828-6004-CP](https://www.mouser.com/ProductDetail/517-4828-6004-CP) | | |
| U3 | 1 | Socket | IC socket, 40-pin, 0.6 in | [3M5471-ND](https://www.digikey.com/en/products/filter?keywords=3M5471-ND) | [517-4840-6000-CP](https://www.mouser.com/ProductDetail/517-4840-6000-CP) | | |

### Keypad Card Rev 1.0

Made, tested. **Tested**.

Cart files: [digikey.csv](BOM/Keypad%20Card/Rev%201.0/digikey.csv), [mouser.csv](BOM/Keypad%20Card/Rev%201.0/mouser.csv), [digikey-through-hole.csv](BOM/Keypad%20Card/Rev%201.0/digikey-through-hole.csv), [mouser-through-hole.csv](BOM/Keypad%20Card/Rev%201.0/mouser-through-hole.csv)

| Reference | Qty | Value | Part | Digi-Key | Mouser | Other | Pre-soldered |
|---|---|---|---|---|---|---|---|
| C1–C4 | 4 | 100nF | YAGEO CC0805KRX7R9BB104 | [311-1140-1-ND](https://www.digikey.com/en/products/filter?keywords=311-1140-1-ND) | [603-CC805KRX7R9BB104](https://www.mouser.com/ProductDetail/603-CC805KRX7R9BB104) | LCSC [C49678](https://www.lcsc.com/search?q=C49678) | Yes |
| J2 | 1 | PORT A | Adam Tech BHR-12-VUA | [2057-BHR-12-VUA-ND](https://www.digikey.com/en/products/filter?keywords=2057-BHR-12-VUA-ND) | [737-BHR-12-VUA](https://www.mouser.com/ProductDetail/737-BHR-12-VUA) | 2057-BHR-12-VUA-ND | |
| J3 | 1 | PORT B | Adam Tech BHR-12-VUA | [2057-BHR-12-VUA-ND](https://www.digikey.com/en/products/filter?keywords=2057-BHR-12-VUA-ND) | [737-BHR-12-VUA](https://www.mouser.com/ProductDetail/737-BHR-12-VUA) | 2057-BHR-12-VUA-ND | |
| U1, U2 | 2 | 74HC138 | Nexperia USA Inc. 74HC138D,653 | [1727-2781-1-ND](https://www.digikey.com/en/products/filter?keywords=1727-2781-1-ND) | [771-74HC138D-T](https://www.mouser.com/ProductDetail/771-74HC138D-T) | LCSC [C5602](https://www.lcsc.com/search?q=C5602) | Yes |
| U3 | 1 | 65C21 | Western Design Center (WDC) W65C21N6TPG-14 |  | [955-W65C21N6TPG-14](https://www.mouser.com/ProductDetail/955-W65C21N6TPG-14) |  | |
| U4 | 1 | AT28C64 | Microchip Technology AT28C64B-15PU | [AT28C64B-15PU-ND](https://www.digikey.com/en/products/filter?keywords=AT28C64B-15PU-ND) | [556-AT28C64B15PU](https://www.mouser.com/ProductDetail/556-AT28C64B15PU) |  | |
| U4 | 1 | Socket | IC socket, 28-pin, 0.6 in | [3M5481-ND](https://www.digikey.com/en/products/filter?keywords=3M5481-ND) | [517-4828-6004-CP](https://www.mouser.com/ProductDetail/517-4828-6004-CP) | | |
| U3 | 1 | Socket | IC socket, 40-pin, 0.6 in | [3M5471-ND](https://www.digikey.com/en/products/filter?keywords=3M5471-ND) | [517-4840-6000-CP](https://www.mouser.com/ProductDetail/517-4840-6000-CP) | | |


## Keypad Helper

### Keypad Helper Rev 1.0

Made, tested. **Tested**.

Cart files: [digikey.csv](BOM/Keypad%20Helper/Rev%201.0/digikey.csv), [mouser.csv](BOM/Keypad%20Helper/Rev%201.0/mouser.csv)

| Reference | Qty | Value | Part | Digi-Key | Mouser | Other |
|---|---|---|---|---|---|---|
| C1, C2, C4 | 3 | 100nF | KYOCERA AVX SR215C104KAR | [478-3188-ND](https://www.digikey.com/en/products/filter?keywords=478-3188-ND) | [581-SR215C104KAR](https://www.mouser.com/ProductDetail/581-SR215C104KAR) |  |
| C3 | 1 | 1uF | KYOCERA AVX SR215C105KAR | [478-SR215C105KAR-ND](https://www.digikey.com/en/products/filter?keywords=478-SR215C105KAR-ND) | [581-SR215C105KAR](https://www.mouser.com/ProductDetail/581-SR215C105KAR) |  |
| D1, D2 | 2 | 1N914 | onsemi 1N914 | [1N914FS-ND](https://www.digikey.com/en/products/filter?keywords=1N914FS-ND) | [512-1N914](https://www.mouser.com/ProductDetail/512-1N914) |  |
| J1 | 1 | PORT | Adam Tech BHR-12-VUA | [2057-BHR-12-VUA-ND](https://www.digikey.com/en/products/filter?keywords=2057-BHR-12-VUA-ND) | [737-BHR-12-VUA](https://www.mouser.com/ProductDetail/737-BHR-12-VUA) | 2057-BHR-12-VUA-ND |
| R1, R2 | 2 | 100k | YAGEO MFR-12FTF52-100K | [13-MFR-12FTF52-100KCT-ND](https://www.digikey.com/en/products/filter?keywords=13-MFR-12FTF52-100KCT-ND) | [603-MFR-12FTF52-100K](https://www.mouser.com/ProductDetail/603-MFR-12FTF52-100K) |  |
| SW1–SW24 | 24 | Keyswitch | Cherry Americas LLC MX2A-E1NA | [1644-MX2A-E1NA-ND](https://www.digikey.com/en/products/filter?keywords=1644-MX2A-E1NA-ND) | [540-MX2A-E1NA](https://www.mouser.com/ProductDetail/540-MX2A-E1NA) |  |
| U1 | 1 | MM74C922 | onsemi MM74C922N |  |  | [Jameco 44564](https://www.jameco.com/z/74C922-Major-Brands-IC-74C922-16-20-Key-Encoder-DIP-18-pin_44564.html) |
| U2 | 1 | 74HC00 | Texas Instruments SN74HC00N | [296-1563-5-ND](https://www.digikey.com/en/products/filter?keywords=296-1563-5-ND) | [595-SN74HC00N](https://www.mouser.com/ProductDetail/595-SN74HC00N) |  |

- **SW1–SW24:** Cherry MX2A RGB Blue, clear housing, as on the owner's Amazon kit. MX1A-E1NN (black housing) is the deeper-stocked alternative; Digi-Key CH196-ND, Mouser 540-MX1A-E1NN.
- **U1:** Buy from Jameco. Out of production at Digi-Key and Mouser.


## Keypad LCD Helper

### Keypad LCD Helper Rev 1.1

Drawn, not made yet. **Proven design**: silkscreen, outline clean-up.

Cart files: [digikey.csv](BOM/Keypad%20LCD%20Helper/Rev%201.1/digikey.csv), [mouser.csv](BOM/Keypad%20LCD%20Helper/Rev%201.1/mouser.csv)

| Reference | Qty | Value | Part | Digi-Key | Mouser | Other |
|---|---|---|---|---|---|---|
| J1 | 1 | PORT A | Adam Tech BHR-12-VUA | [2057-BHR-12-VUA-ND](https://www.digikey.com/en/products/filter?keywords=2057-BHR-12-VUA-ND) | [737-BHR-12-VUA](https://www.mouser.com/ProductDetail/737-BHR-12-VUA) | 2057-BHR-12-VUA-ND |
| J2 | 1 | PORT B | Adam Tech BHR-12-VUA | [2057-BHR-12-VUA-ND](https://www.digikey.com/en/products/filter?keywords=2057-BHR-12-VUA-ND) | [737-BHR-12-VUA](https://www.mouser.com/ProductDetail/737-BHR-12-VUA) | 2057-BHR-12-VUA-ND |
| J3 | 1 | KEYPAD HELPER | Adam Tech BHR-12-VUA | [2057-BHR-12-VUA-ND](https://www.digikey.com/en/products/filter?keywords=2057-BHR-12-VUA-ND) | [737-BHR-12-VUA](https://www.mouser.com/ProductDetail/737-BHR-12-VUA) | 2057-BHR-12-VUA-ND |
| U2 | 1 | LCD-16X2 | LCD-16X2, LCD-16X2 |  |  | [Amazon](https://www.amazon.com/dp/B0DSFXK7QK) |
| VR1 | 1 | 10k | Bourns Inc. 3386F-1-103LF | [3386F-103LF-ND](https://www.digikey.com/en/products/filter?keywords=3386F-103LF-ND) | [652-3386F-1-103LF](https://www.mouser.com/ProductDetail/652-3386F-1-103LF) |  |

**Do not fit** R1: parallel with VR1 to make ~10 k.

- **U2:** Common hobby 16×2 LCD; any HD44780-compatible module with the same pinout.

### Keypad LCD Helper Rev 1.0

Made, tested. **Tested**.

Cart files: [digikey.csv](BOM/Keypad%20LCD%20Helper/Rev%201.0/digikey.csv), [mouser.csv](BOM/Keypad%20LCD%20Helper/Rev%201.0/mouser.csv)

| Reference | Qty | Value | Part | Digi-Key | Mouser | Other |
|---|---|---|---|---|---|---|
| J1 | 1 | PORT A | Adam Tech BHR-12-VUA | [2057-BHR-12-VUA-ND](https://www.digikey.com/en/products/filter?keywords=2057-BHR-12-VUA-ND) | [737-BHR-12-VUA](https://www.mouser.com/ProductDetail/737-BHR-12-VUA) | 2057-BHR-12-VUA-ND |
| J2 | 1 | PORT B | Adam Tech BHR-12-VUA | [2057-BHR-12-VUA-ND](https://www.digikey.com/en/products/filter?keywords=2057-BHR-12-VUA-ND) | [737-BHR-12-VUA](https://www.mouser.com/ProductDetail/737-BHR-12-VUA) | 2057-BHR-12-VUA-ND |
| J3 | 1 | KEYBOARD HELPER | Adam Tech BHR-12-VUA | [2057-BHR-12-VUA-ND](https://www.digikey.com/en/products/filter?keywords=2057-BHR-12-VUA-ND) | [737-BHR-12-VUA](https://www.mouser.com/ProductDetail/737-BHR-12-VUA) | 2057-BHR-12-VUA-ND |
| U2 | 1 | LCD-16X2 | LCD-16X2, LCD-16X2 |  |  | [Amazon](https://www.amazon.com/dp/B0DSFXK7QK) |
| VR1 | 1 | 10k | Bourns Inc. 3386F-1-103LF | [3386F-103LF-ND](https://www.digikey.com/en/products/filter?keywords=3386F-103LF-ND) | [652-3386F-1-103LF](https://www.mouser.com/ProductDetail/652-3386F-1-103LF) |  |

**Do not fit** R1: parallel with VR1 to make ~10 k.

- **U2:** Common hobby 16×2 LCD; any HD44780-compatible module with the same pinout.
