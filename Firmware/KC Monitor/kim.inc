; =============================================================================
;   kim.inc — Machine include file for the 6502-KIM running KC Monitor
; =============================================================================
;
;   CPU:       WDC 65C02S
;   BIOS:      v1.5   (Kernal only — see THE CARTRIDGE OVERLAY below)
;   Cartridge: KC Monitor v1.0 (Keypad Card, AT28C64)
;   Assembler: ca65 (cc65 toolchain) — uses := for absolute symbols
;
;   This file describes the KIM *as it actually is with the Keypad Card
;   fitted*.  It is deliberately NOT the family-wide 6502.inc from the BIOS
;   repository: that file documents the ACE, a machine with every card
;   populated and the full BIOS ROM intact.  On a KIM most of that is either
;   absent hardware or has been overlaid by the cartridge, and calling into it
;   does not do what 6502.inc says it does.
;
;   If a symbol is not in this file, it is not usable on a stock KIM.
;
;   MEMORY MAP (Keypad Card fitted)
;   ------------------------------
;   $0000-$0003   Zero Page: Kernal pointers (see Section 1)
;   $0004-$0023   Zero Page: was BASIC's — free on a KIM (BASIC is overlaid)
;   $0024-$0039   Zero Page: Kernal scratch (CF, serial, delay, XModem)
;   $003A-$003F   Zero Page: free for user programs
;   $0040-$0051   Zero Page: KC MONITOR state — do not touch (see Section 1)
;   $0052-$00FF   Zero Page: free for user programs
;   $0100-$01FF   CPU Stack
;   $0200-$027F   KC MONITOR Wozmon line buffer — LIVE, not spare RAM
;   $0280-$02FF   free (the upper half of the Kernal's unused input ring)
;   $0300-$03FF   Kernal Variables (vectors, HW flags, etc.)
;   $0400-$04FF   KC MONITOR serial RX ring — LIVE, not spare RAM
;   $0500-$05FF   User Variables
;   $0600-$07FF   free on a KIM (the Kernal's FS sector buffer; no CF fitted)
;   $0800-$7FFF   Program RAM (30 KB — load address for user code)
;   $8000-$8FFF   IO 1-4: unpopulated on a KIM (open bus)
;   $9000-$9003   IO 5: Serial (R65C51 ACIA) — optional, usually fitted
;   $9400-$9FFF   IO 6-8: unpopulated on a KIM (open bus)
;   $A000-$A0FF   Kernal Jump Table (stable entry points — SURVIVES the overlay)
;   $A100-$B7FF   Kernal Implementation                    (SURVIVES the overlay)
;   $B800-$BFFF   Character Set ROM (2 KB)                  (SURVIVES the overlay)
;   $C000-$DFFF   Keypad Card PIA registers (mirrored I/O window)
;   $E000-$FFF9   Keypad Card ROM (AT28C64, 8 KB) — KC Monitor
;   $FFFA-$FFFF   CPU Vectors (NMI, RESET, IRQ) — the cartridge's own
;
;   THE CARTRIDGE OVERLAY — what is GONE on a KIM
;   ---------------------------------------------
;   The Keypad Card overlays $C000-$FFFF.  Everything the BIOS ROM put there
;   is unreachable; the addresses now decode to the PIA or to cartridge ROM:
;
;     $C000-$EDFF   BASIC interpreter        -> gone (PIA window + cart ROM)
;     $EE00-$FEFF   Machine Code Monitor     -> gone (cart ROM)
;     $FF00-$FFF9   Wozmon                   -> gone (cart ROM)
;     $FFFA-$FFFF   BIOS CPU vectors         -> replaced by the cartridge's
;
;   So there is no MONITOR_ENTRY, no MONITOR_BRK_ENTRY, no BASIC entry, and no
;   BIOS Wozmon on this machine.  A BRK does NOT drop into the BIOS monitor —
;   KC Monitor points BRK_PTR at its own handler, which simply RTIs.  The BRK
;   register save area at $0310-$0316 is therefore never populated on a KIM.
;
;   What survives is $A000-$BFFF: the Kernal jump table, the Kernal itself,
;   and the character set ROM.  KC Monitor calls KernalInit at reset, so the
;   Kernal's RAM vectors and HW_PRESENT are set up normally.
;
;   HARDWARE ACTUALLY PRESENT
;   -------------------------
;   A stock KIM is a CPU Card, a Memory Card, a Keypad Card, and (usually) a
;   Serial Card.  IO slots 1-4 and 6-8 are empty: no banked RAM, no RTC, no
;   CompactFlash, no GPIO/VIA, no SID, no video.  Their register windows read
;   open bus, and the Kernal routines that drive them are inert (they check
;   HW_PRESENT first — see GRACEFUL DEGRADATION below).  Only Sections 4 and 5
;   below list what is real; nothing here defines a register for a card the
;   KIM does not have.
;
;   Everything is driven through the Keypad Card instead: a 24-key keypad and
;   a 16x2 HD44780 LCD on a 65C21 PIA, plus the Serial Card when fitted.
;
;   CONSOLE I/O IS NOT WHAT YOU EXPECT
;   ----------------------------------
;   There is no video card, so the Kernal's console layer has nowhere good to
;   go.  Two consequences bite user programs on a KIM:
;
;     * Chrout ($A000) dispatches on IO_MODE.  With a Serial Card fitted the
;       boot probe selects serial, and Chrout lands in SerialChrout, which
;       BLOCKS until TDRE — and the R65C51 gates TDRE on /CTS.  With no
;       terminal connected, a single Chrout hangs the machine forever.  With
;       no Serial Card fitted, IO_MODE is left as the probe found it and
;       output goes nowhere at all.  Everything built on Chrout (PrintStr,
;       PrintCRLF, PrintDecU16, FsPrintDisk) inherits this.
;
;     * Chrin ($A003) and the ring routines around it are INERT under KC
;       Monitor.  They read the Kernal's input ring at $0200, which is filled
;       only by the Kernal's own IRQ handler — and the cartridge takes over
;       IRQ_PTR at reset, so nothing ever calls WriteBuffer.  Chrin always
;       returns C=0.  Typed characters DO appear in $0200 while you watch, but
;       that is KC Monitor's own Wozmon line buffer aliased onto the same page
;       (see Section 3), not the Kernal ring filling up.
;
;   A program that wants console I/O on a KIM should talk to the Serial Card
;   directly (Section 5) rather than through Chrout/Chrin.
;
;   BOOT SEQUENCE (KC Monitor)
;   --------------------------
;   RESET vectors into the cartridge, not the BIOS.  KC Monitor resets the
;   stack, calls KernalInit to bring up the Kernal RAM vectors and probe the
;   base system, then takes over IRQ_PTR (keypad + serial RX) and BRK_PTR,
;   brings up the LCD and PIA, and shows the splash on both the LCD and the
;   serial port.  It then holds until ESC arrives from EITHER the keypad ESC
;   key or the serial port; only once the gate opens does the LCD paint the
;   address/byte display and the serial "> " prompt appear.  There is no boot
;   menu and no BASIC to launch.
;
;   GRACEFUL DEGRADATION
;   --------------------
;   Every Kernal routine that drives a card checks HW_PRESENT first, so a call
;   on a machine without that card is safe rather than a crash.  On a KIM that
;   means most of the jump table is a silent no-op or an immediate C=1 error
;   return.  The per-routine notes in Section 4 say which is which.
;
;   CALLING CONVENTION
;   ------------------
;   Kernal routines are called via JSR to the jump table addresses below.
;   Parameters are passed in A, X, Y, and/or zero-page pointers as documented
;   per routine.  Carry flag is used for success/error returns (C=0 success,
;   C=1 error) where noted.
;
;   RUNNING UNDER KC MONITOR
;   ------------------------
;   A program launched from the monitor (keypad UP, or the serial "XXXX R"
;   command) runs with the cartridge's IRQ handler still installed.  That
;   handler is what makes ESC a reliable break-to-monitor abort from anywhere,
;   so a program that wants to stay abortable should leave IRQ_PTR alone and
;   leave interrupts enabled.  A program that repoints IRQ_PTR or SEIs for a
;   long stretch gives up ESC and can only be recovered with RESET.
;
;   The monitor also owns the PIA (Section 5) and the zero page at $40-$51,
;   the line buffer at $0200-$027F and the RX ring at $0400-$04FF (Section 3).
;   Writing to any of those corrupts the monitor you are going to return to.
;
; =============================================================================


; =============================================================================
;   SECTION 1: ZERO PAGE
; =============================================================================

; --- Kernal pointers ---------------------------------------------------------
; Used as parameters to Kernal calls.  STR_PTR is the one that matters on a
; KIM; the CF and XModem pointers are listed for completeness (XModem works
; over the Serial Card, CF does not exist here).

STR_PTR             := $02               ; 2 bytes — String pointer (PrintStr, and KC Monitor's LcdPrintStr / SerPrintStr)
CF_BUF_PTR          := $24               ; 2 bytes — CF sector buffer pointer (no CF card on a KIM)
CF_LBA              := $26               ; 4 bytes — CF 28-bit LBA         (no CF card on a KIM)
XFER_PTR            := $2A               ; 2 bytes — XModem data pointer (source for XModemSave, dest for XModemLoad)

; --- KC Monitor state — RESERVED --------------------------------------------
; The cartridge keeps its whole working state here.  A user program that
; clobbers any of it corrupts the monitor it will return to on RTS or ESC.
; These are documented, not exported: the monitor defines them itself.
;
;   $40-$41  CUR_ADDR    current address (keypad monitor)
;   $42      MODE        INS edit-mode flag
;   $43      MON_TMP     nibble-edit scratch
;   $44      KEY_CODE    last keycode latched by the IRQ handler
;   $45      KEY_READY   nonzero when a keypad press is pending
;   $46-$47  SER_RXHEAD / SER_RXTAIL   serial RX ring indices
;   $48-$4F  XAML/XAMH, STL/STH, L/H, YSAV, WMODE   Wozmon parser state
;   $50      SER_IDX     line-buffer index
;   $51      SER_DIRTY   set when a serial deposit changed memory

KC_ZP_START         = $40                ; first byte owned by KC Monitor
KC_ZP_END           = $51                ; last byte owned by KC Monitor

; --- Free zero page ----------------------------------------------------------
; $04-$23 (BASIC's old scratch — BASIC is overlaid, so this is free on a KIM)
; $3A-$3F and $52-$FF
; Note: $24-$2D belong to the Kernal's CF/XModem routines and do not survive a
;       call into them; $2E-$39 was the BIOS Monitor's, which is overlaid.


; =============================================================================
;   SECTION 2: SYSTEM VARIABLES ($0300-$03FF)
; =============================================================================
; Set up by KernalInit, which KC Monitor calls at reset.  Only the entries
; that mean something on a KIM are listed.

IRQ_PTR             := $0300             ; 2 bytes — IRQ handler vector
                                         ;   KC Monitor points this at its own handler
                                         ;   (keypad CA1 + serial RX + ESC abort).
                                         ;   Repointing it costs you the ESC abort.
BRK_PTR             := $0302             ; 2 bytes — BRK handler vector
                                         ;   KC Monitor points this at a plain RTI, so a
                                         ;   BRK in user code resumes instead of entering
                                         ;   the (overlaid) BIOS monitor
NMI_PTR             := $0304             ; 2 bytes — NMI handler vector (Kernal default: RTI)

IO_MODE             := $0306             ; 1 byte  — Console output mode (bit 0: 0=video, 1=serial)
                                         ;   No video card on a KIM — see CONSOLE I/O above

HW_PRESENT          := $030D             ; 1 byte  — Hardware present bitmask (set by the boot probe)

; HW_PRESENT bit definitions (bit order matches IO slot numbers).  On a stock
; KIM only HW_SC is ever set, and only when a Serial Card is fitted.
HW_RAM_L            = %00000001          ; Bit 0: RAM card low  (IO 1) — absent on a KIM
HW_RAM_H            = %00000010          ; Bit 1: RAM card high (IO 2) — absent on a KIM
HW_RTC              = %00000100          ; Bit 2: RTC card      (IO 3) — absent on a KIM
HW_CF               = %00001000          ; Bit 3: Storage card  (IO 4) — absent on a KIM
HW_SC               = %00010000          ; Bit 4: Serial card   (IO 5) — the one to test on a KIM
HW_GPIO             = %00100000          ; Bit 5: GPIO card     (IO 6) — absent on a KIM
HW_SID              = %01000000          ; Bit 6: Sound card    (IO 7) — absent on a KIM
HW_VID              = %10000000          ; Bit 7: Video card    (IO 8) — absent on a KIM

; Test before using the Serial Card directly:
;     lda HW_PRESENT
;     and #HW_SC
;     beq @NoSerial

XFER_REMAIN         := $0317             ; 2 bytes — XModem byte count (output from XModemLoad; input to XModemSave)
XFER_IO_SAVE        := $0319             ; 1 byte  — Saved IO_MODE during XModem transfer (internal use)

BOOT_VECTOR         := $035B             ; 2 bytes — Boot redirect address, honoured by the BIOS
                                         ;   reset flow only.  INERT on a KIM: the cartridge
                                         ;   owns the RESET vector, so the BIOS boot flow that
                                         ;   reads this never runs.  KernalInit still zeroes it.

; Not listed, because they are meaningless on a KIM:
;   VID_CURSOR_X/Y ($0307-$0308)  no video card
;   CF_DISK ($030F), FS_IO_ADDR ($037F), FS_FILE_SIZE ($034A)   no CF card
;   BRK_P..BRK_SP ($0310-$0316)   populated by the BIOS monitor's BRK handler,
;                                 which is overlaid — never written on a KIM
;   PRG_IMAGE_END ($038E)         consumed by BASIC, which is overlaid


; =============================================================================
;   SECTION 3: KEY MEMORY LOCATIONS
; =============================================================================

PROGRAM_START       := $0800             ; User programs load here (KC Monitor's
                                         ;   power-on address).  Program space runs
                                         ;   to $7FFF (30 KB)
MEMORY_TOP          := $8000             ; First address past usable RAM (IO space starts here)

CHARSET_ROM         := $B800             ; 2 KB CP437 character set, 256 x 8-byte
                                         ;   patterns.  Survives the overlay and is
                                         ;   readable, though a KIM has no video card
                                         ;   to draw it on — useful as pattern data

; --- The pages KC Monitor lives in -------------------------------------------
; These are NOT spare RAM.  On a stock ACE, $0200-$02FF is the Kernal's input
; ring; on a KIM the Kernal ring is dead (nothing feeds it — see CONSOLE I/O)
; and the bottom half of the page is the monitor's live Wozmon line buffer,
; deliberately aliased onto it.  Anyone scavenging $0200 for scratch on the
; strength of the family-wide 6502.inc will corrupt the line being typed.

INPUT_BUFFER        := $0200             ; $0200-$02FF — the Kernal's input ring.
                                         ;   INERT on a KIM (never written by the Kernal).
KC_LINEBUF          := $0200             ; $0200-$027F — KC Monitor's Wozmon line buffer.
                                         ;   LIVE whenever the serial monitor is running.
KC_RXBUF            := $0400             ; $0400-$04FF — KC Monitor's serial RX ring,
                                         ;   filled by the cartridge IRQ handler.  LIVE.


; =============================================================================
;   SECTION 4: KERNAL JUMP TABLE ($A000-$A0FF)
; =============================================================================
; All entry points are stable 3-byte JMP instructions.  Call via JSR.  The
; whole table survives the cartridge overlay and every address below is real —
; but most of it drives cards a KIM does not have, and says so.
;
; The tag on each group says what to expect on a stock KIM:
;   [WORKS]   does its job
;   [SERIAL]  works when a Serial Card is fitted (test HW_SC), inert otherwise
;   [INERT]   returns silently having done nothing — no card to drive
;   [FAILS]   returns C=1 immediately — no card to drive
;   [BROKEN]  present, but does not do what it says on a KIM (see the note)

; --- Character I/O -----------------------------------------------------------
Chrout              := $A000             ; [SERIAL] Output character (dispatched by IO_MODE)
                                         ;   In: A = character.  Preserves: A, X, Y
                                         ;   WARNING: on a KIM this reaches SerialChrout, which
                                         ;   blocks until TDRE.  No terminal connected = hang.
                                         ;   Prefer talking to the ACIA directly (Section 5)

Chrin               := $A003             ; [BROKEN] Input character from the Kernal ring
                                         ;   Always returns C=0 on a KIM: the cartridge owns
                                         ;   IRQ_PTR, so nothing ever calls WriteBuffer
WriteBuffer         := $A006             ; [BROKEN] Write byte to the Kernal input ring
ReadBuffer          := $A009             ; [BROKEN] Read byte from the Kernal input ring
BufferSize          := $A00C             ; [BROKEN] Unread byte count — always 0 on a KIM

; --- IO Mode -----------------------------------------------------------------
SetIOMode           := $A00F             ; [WORKS] Set IO_MODE   In: A = mode (bit 0: 0=video, 1=serial)
GetIOMode           := $A012             ; [WORKS] Get IO_MODE   Out: A = current IO_MODE

; --- Video (IO 8) — no video card on a KIM -----------------------------------
InitVideo           := $A015             ; [INERT]
VideoClear          := $A018             ; [INERT]
VideoPutChar        := $A01B             ; [INERT]
VideoSetCursor      := $A01E             ; [INERT]
VideoGetCursor      := $A021             ; [INERT]
VideoScroll         := $A024             ; [INERT]
VideoSetColor       := $A027             ; [INERT]
VideoChroutRaw      := $A02A             ; [INERT]

; --- Sound (IO 7) — no SID on a KIM ------------------------------------------
InitSID             := $A02D             ; [INERT]
Beep                := $A030             ; [INERT]
SidPlayNote         := $A033             ; [INERT]
SidSilence          := $A036             ; [INERT]
SidSetVolume        := $A039             ; [INERT]

; --- Filesystem (IO 4) — no CompactFlash on a KIM ----------------------------
FsLoadFile          := $A03C             ; [FAILS] C=1
FsSaveFile          := $A03F             ; [FAILS] C=1
FsDeleteFile        := $A042             ; [FAILS] C=1
FsLoadFileAddr      := $A07E             ; [FAILS] C=1
FsSaveFileAddr      := $A081             ; [FAILS] C=1
FsFormatDisk        := $A084             ; [FAILS] C=1
FsSetDisk           := $A087             ; [INERT] sets CF_DISK; nothing reads it here
FsGetDisk           := $A08A             ; [INERT]
FsPrintDisk         := $A08D             ; [SERIAL] prints via Chrout — same caveat as Chrout

; --- Keyboard / GPIO (IO 6) — no GPIO card on a KIM --------------------------
;   The KIM's keypad is on the Keypad Card's PIA, not the VIA.  These drive the
;   GPIO card's encoders and are not the way to read the keypad.
InitKB              := $A045             ; [INERT]
ReadJoystick1       := $A048             ; [BROKEN] no HW_PRESENT check — reads a floating bus
ReadJoystick2       := $A04B             ; [BROKEN] no HW_PRESENT check — reads a floating bus
KBDisable           := $A099             ; [INERT]
KBEnable            := $A09C             ; [INERT]

; --- Serial (IO 5) — the KIM's one real I/O card -----------------------------
InitSC              := $A04E             ; [SERIAL] Initialize serial card (8-N-1, 19200 baud, RX IRQ on)
                                         ;   Modifies: A
                                         ;   KC Monitor calls this at reset when HW_SC is set

SerialChrout        := $A051             ; [SERIAL] Direct serial output (bypasses IO_MODE)
                                         ;   In: A = character
                                         ;   BLOCKS until TX register is empty.  The R65C51 gates
                                         ;   TDRE on /CTS, so this hangs forever with no terminal
                                         ;   attached — KC Monitor uses its own bounded-wait
                                         ;   SerPutc instead, and so should anything that must
                                         ;   survive a disconnected port

XModemLoad          := $A054             ; [SERIAL] Receive data via XModem into memory
                                         ;   In: XFER_PTR = destination address
                                         ;   Out: C=0 success, XFER_PTR advanced past last byte written
                                         ;        XFER_REMAIN = total bytes received
                                         ;        C=1 transfer failed (timeout or CAN received)
                                         ;   Modifies: A, X, Y

XModemSave          := $A057             ; [SERIAL] Send data via XModem from memory
                                         ;   In: XFER_PTR = source address, XFER_REMAIN = byte count
                                         ;   Out: C=0 success, C=1 transfer failed
                                         ;   Modifies: A, X, Y

; --- RTC (IO 3) — no RTC card on a KIM ---------------------------------------
RtcReadTime         := $A05A             ; [INERT]
RtcReadDate         := $A05D             ; [INERT]
RtcWriteTime        := $A060             ; [INERT]
RtcWriteDate        := $A063             ; [INERT]
RtcReadNVRAM        := $A066             ; [INERT]
RtcWriteNVRAM       := $A069             ; [INERT]

; --- CompactFlash sector I/O (IO 4) — no CF card on a KIM --------------------
StReadSector        := $A06C             ; [FAILS] C=1
StWriteSector       := $A06F             ; [FAILS] C=1
StWaitReady         := $A072             ; [FAILS] C=1 immediately (the boot probe found no card)

; --- Timing ------------------------------------------------------------------
SysDelay            := $A075             ; [WORKS] Delay for A/X centiseconds (10 ms units, 16-bit)
                                         ;   In: A = low byte, X = high byte
                                         ;   Uses VIA T1 if available — on a KIM there is no GPIO
                                         ;   card, so this always takes the software-loop path
                                         ;   Modifies: A, X, Y

; --- System ------------------------------------------------------------------
KernalInit          := $A078             ; [WORKS] Initialize Kernal vectors, probe & init all I/O
                                         ;   Caller MUST reset the stack pointer before JSR:
                                         ;     ldx #$ff / txs / jsr KernalInit
                                         ;   Sets HW_PRESENT, IO_MODE, IRQ/BRK/NMI ptrs
                                         ;   Does NOT reset the stack pointer
                                         ;   Does NOT enable interrupts (caller must CLI)
                                         ;   Does NOT play beep, display splash, or enter boot menu
                                         ;   Modifies: All registers, flags
                                         ;   KC Monitor calls this once at reset; a user program
                                         ;   should NOT call it again — it would undo the
                                         ;   cartridge's IRQ_PTR/BRK_PTR takeover

KernalVersion       := $A07B             ; [WORKS] Get BIOS version  Out: A = major, X = minor

; --- General output utilities (all routed through Chrout) --------------------
PrintStr            := $A090             ; [SERIAL] Print a NUL-terminated string
                                         ;   In : A = string addr low, Y = string addr high
                                         ;   Modifies: Flags, A, Y, STR_PTR (X preserved)
PrintCRLF           := $A093             ; [SERIAL] Print CR ($0D) then LF ($0A)
PrintDecU16         := $A096             ; [SERIAL] Print an unsigned 16-bit value as decimal
                                         ;   In : A = value low, X = value high (no leading zeros)


; =============================================================================
;   SECTION 5: IO HARDWARE REGISTERS
; =============================================================================
; Only what a KIM actually has.  IO slots 1-4 and 6-8 ($8000-$8FFF, $9400-$9FFF)
; are unpopulated and read open bus; if you fit one of those cards, take its
; register definitions from the BIOS's family-wide 6502.inc.

; -----------------------------------------------------------------------------
;   Serial Card (R65C51 ACIA) — IO 5: $9000-$9003
; -----------------------------------------------------------------------------
;   Optional hardware.  Test HW_SC in HW_PRESENT before touching these — with
;   no card fitted the window is open bus and a floating RDRF will hand you
;   phantom bytes.  Default config after InitSC: 8-N-1, 19200 baud, RX IRQ on.

SC_DATA             := $9000             ; R/W — Data register
SC_RESET            := $9001             ; Write — Programmatic reset (write any value)
SC_STATUS           := $9001             ; Read — Status register (reading clears the IRQ flag)
SC_CMD              := $9002             ; R/W — Command register
SC_CTRL             := $9003             ; R/W — Control register

; Serial Status Register bits:
SC_STATUS_IRQ       := %10000000         ; Interrupt occurred
SC_STATUS_DSR       := %01000000         ; Data Set Ready
SC_STATUS_DCD       := %00100000         ; Data Carrier Detect
SC_STATUS_TDRE      := %00010000         ; TX Data Register Empty (ready to send)
SC_STATUS_RDRF      := %00001000         ; RX Data Register Full (byte available)
SC_STATUS_OVR       := %00000100         ; Overrun error
SC_STATUS_FRME      := %00000010         ; Framing error
SC_STATUS_PARE      := %00000001         ; Parity error

; -----------------------------------------------------------------------------
;   Keypad Card PIA (65C21) — $C000-$C003, mirrored across $C000-$DFFF
; -----------------------------------------------------------------------------
;   The card that makes the KIM a KIM.  A0=RS0, A1=RS1.
;
;   Wiring:
;     PA0-PA4 = keypad code        (input)
;     PA5     = LCD RS             (output)
;     PA6     = LCD R/W            (output)
;     PA7     = LCD E              (output)
;     PB0-PB7 = LCD data bus       (output)
;     CA1     = keypad data-available
;     CA2     = active-low OE of the 74C922 keypad encoder
;
;   KC Monitor owns this PIA.  A program launched from the monitor that writes
;   here will scramble the LCD and can break keypad input — including the ESC
;   abort that would have got you back.

PORTA               := $C000             ; Port A data / DDRA (per CRA bit 2)
CRA                 := $C001             ; Control register A
PORTB               := $C002             ; Port B data / DDRB (per CRB bit 2)
CRB                 := $C003             ; Control register B

; Control-register bit 2 selects the data register (1) or the data direction
; register (0) at the shared port address.
CR_DDR              = %00000000          ; access DDRx
CR_PORT             = %00000100          ; access PORTx data register

; Data direction for Port A: PA5/PA6/PA7 outputs (LCD control),
; PA0-PA4 inputs (keypad code).
LCD_DDRA            = %11100000          ; $E0

; LCD control-line masks on Port A
LCD_RS              = %00100000          ; PA5 — register select (1=data, 0=cmd)
LCD_RW              = %01000000          ; PA6 — read/write (1=read, 0=write)
LCD_E               = %10000000          ; PA7 — enable strobe

; LCD busy flag (Port B DB7, valid when reading with RS=0 / R/W=1).  KC Monitor
; uses timed delays instead of polling this, so the read-back path is untested
; hardware — treat it with suspicion.
LCD_BUSY            = %10000000

; -----------------------------------------------------------------------------
;   Keypad (74C922 encoder via PIA Port A + CA1/CA2)
; -----------------------------------------------------------------------------
;   The encoder presents a 5-bit keycode on PA0-PA4 and raises CA1 (positive
;   edge) when a key becomes available.  CA2 is driven low to enable the
;   encoder's active-low output enable (OE).  Scanning, debounce and encoding
;   are all done in hardware on the Keypad Helper.
;
;   Read the keycode at the CA1 edge (in an interrupt handler), where the
;   74C922 outputs are guaranteed valid — polling at an arbitrary later time
;   can straddle a key transition.
;
;   CRA layout for the keypad:
;     bit 7   CA1 active-edge flag (IRQF1) — set on key-available, read-only
;     bit 5-3 110 = CA2 manual output low (enables 74C922 OE)
;     bit 2   1   = access PORTA data register (not DDRA)
;     bit 1   1   = CA1 active on the positive (rising) edge
;     bit 0   1   = CA1 interrupt enabled

PIA_CA1_FLAG        = %10000000          ; CRA bit 7 — CA1 active-edge flag
PIA_CRA_KEYPAD      = %00110111          ; $37 — CA2 out low, CA1 +edge, IRQ ON, PORT
KEY_MASK            = %00011111          ; PA0-PA4 carry the keycode (0-23)
KEY_COUNT           = 24                 ; valid keycodes are $00-$17

; Named keycodes.  The 24 keys are a 4x6 matrix; the sixteen hex keys are not
; contiguous, so use the layout below rather than arithmetic on the keycode.
;
;   $00 LEFT   $01 1   $02 2   $03 3   $04 4   $05 5
;   $06 6      $07 7   $08 8   $09 9   $0A 0   $0B RIGHT
;   $0C F      $0D E   $0E D   $0F C   $10 ESC $11 INS
;   $12 PGUP   $13 A   $14 UP  $15 DEL $16 PGDN $17 B

KEY_LEFT            = $00
KEY_RIGHT           = $0B
KEY_ESC             = $10
KEY_INS             = $11
KEY_PGUP            = $12
KEY_A               = $13
KEY_UP              = $14
KEY_DEL             = $15
KEY_PGDN            = $16
KEY_B               = $17


; =============================================================================
;   SECTION 6: CONSTANTS
; =============================================================================

; --- Versions ---
BIOS_VERSION_MAJOR  = 1
BIOS_VERSION_MINOR  = 5
KC_VERSION_MAJOR    = 1                  ; KC Monitor cartridge version
KC_VERSION_MINOR    = 0

; --- ASCII Control Characters ---
CHAR_BEL            = $07                ; Bell
CHAR_BS             = $08                ; Backspace
CHAR_LF             = $0A                ; Line Feed
CHAR_CR             = $0D                ; Carriage Return
CHAR_ESC            = $1B                ; Escape — break-to-monitor abort on a KIM,
                                         ;   from the keypad ESC key or the serial port
CHAR_SPACE          = $20                ; Space
CHAR_DEL            = $7F                ; Delete

; --- XModem protocol constants (used with XModemLoad / XModemSave) ---
XMODEM_SOH          = $01                ; Start of Header
XMODEM_EOT          = $04                ; End of Transmission
XMODEM_ACK          = $06                ; Acknowledge
XMODEM_NAK          = $15                ; Negative Acknowledge (receiver sends to initiate)
XMODEM_CAN          = $18                ; Cancel
XMODEM_SUB          = $1A                ; Padding byte (fills unused bytes in last block)
XMODEM_BLKSZ        = 128                ; Data bytes per block
XMODEM_MAXRETRY     = 10                 ; Max retries per block during transfer
XMODEM_STARTRETRY   = 60                 ; Retries waiting for initial connect (~60s)
