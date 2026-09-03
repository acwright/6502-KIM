.setcpu "65C02"

.include "kim.inc"

; =============================================================================
;   KC Monitor — KIM-1-style keypad/LCD memory monitor
; =============================================================================
;   Cartridge ROM for the Keypad Card (KC).  Drives a 16x2 HD44780 LCD and a
;   24-key keypad through a 65C21 PIA.  The cart overlays $C000-$FFFF; ROM
;   (AT28C64, 8 KB) lives at $E000-$FFFF and the PIA registers are mirrored
;   across the I/O window $C000-$DFFF.
;
;   The machine itself — PIA, LCD wiring, keypad codes, the surviving Kernal —
;   is described in kim.inc.  This file implements:
;     - Monitor state & build scaffolding
;     - LCD driver
;     - PIA init & keypad input
;     - Monitor state machine
;     - Entry point, interrupt handlers & CPU vectors
;     - ESC = break-to-monitor abort (handled in KeyIrq)
;     - Wozmon-compatible serial monitor (concurrent with the keypad)
; =============================================================================


; =============================================================================
;   Machine definitions
; =============================================================================
;   kim.inc describes the KIM as it actually is with this cartridge fitted:
;   the Keypad Card PIA ($C000-$C003) and its LCD/keypad wiring, the Serial
;   Card ACIA ($9000-$9003), the part of the BIOS Kernal that survives the
;   $C000-$FFFF overlay, and the RAM this monitor reserves.  Everything the
;   overlay removes — BASIC, the BIOS Monitor, Wozmon, the BIOS vectors — is
;   listed there as gone rather than silently omitted.
;
;   PORTA/CRA/PORTB/CRB, CR_DDR/CR_PORT, LCD_*, PIA_*, KEY_* and the ASCII
;   constants below all come from it.


; =============================================================================
;   Monitor zero-page state
; =============================================================================
;   Lives in the free user zero page; kim.inc reserves $40-$51 (KC_ZP_START..
;   KC_ZP_END) for the monitor so a program written for the KIM knows to keep
;   off it.  CUR_ADDR is the address the monitor is inspecting/editing; it
;   doubles as the (zp),y pointer for byte access and as the execute
;   trampoline target.  MODE holds the INS edit flag; MON_TMP is scratch for
;   the nibble-shift edits.
CUR_ADDR            := $40               ; 2 bytes — current address pointer
MODE                := $42               ; 1 byte  — INS edit-mode flag (0=off)
MON_TMP             := $43               ; 1 byte  — scratch for nibble edits
KEY_CODE            := $44               ; 1 byte  — last keycode latched by KeyIrq
KEY_READY           := $45               ; 1 byte  — nonzero when a key is pending

MODE_INS            = $01                ; MODE value: insert/edit mode active


; =============================================================================
;   Serial Wozmon zero-page state
; =============================================================================
;   A Wozmon-compatible serial monitor runs concurrently with the keypad
;   monitor, sharing the same memory.  Incoming bytes are pushed into a
;   256-byte RX ring by the IRQ handler and drained by the cooperative main
;   loop into a Wozmon line parser.  The parser variables mirror the original
;   Apple-1 Wozmon (XAML/XAMH, STL/STH, L/H, YSAV, MODE) but live in the free
;   user zero page since $24-$2B are reserved by the Kernal here.  WMODE is
;   kept distinct from the keypad MODE byte.
SER_RXHEAD          := $46               ; 1 byte  — RX ring write index (IRQ)
SER_RXTAIL          := $47               ; 1 byte  — RX ring read index (main loop)
XAML                := $48               ; 2 bytes — last "examined" address (lo/hi)
XAMH                := $49
STL                 := $4A               ; 2 bytes — current deposit address (lo/hi)
STH                 := $4B
L                   := $4C               ; 2 bytes — hex accumulator (lo/hi)
H                   := $4D
YSAV                := $4E               ; 1 byte  — saved index (hex-present test)
WMODE               := $4F               ; 1 byte  — Wozmon mode ($00=XAM, $74=STOR, $AE=BLOCK)
SER_IDX             := $50               ; 1 byte  — current line-buffer index
SER_DIRTY           := $51               ; 1 byte  — nonzero when a serial deposit changed memory

; The RX ring buffer (256 bytes, byte indices wrap naturally) and the Wozmon
; line buffer share the low-RAM input region; neither is used by the keypad
; monitor.  The line buffer is aliased onto the Kernal's input ring page,
; which is inert here (nothing feeds it once the cart owns IRQ_PTR) — kim.inc
; documents both pages as live so they are not mistaken for spare RAM.
SER_RXBUF           := KC_RXBUF          ; $0400 — 256-byte serial RX ring buffer
SER_LINEBUF         := KC_LINEBUF        ; $0200 — Wozmon line accumulation buffer


; =============================================================================
;   ROM
; =============================================================================

.segment "ROM"

; =============================================================================
;   CartReset — power-on entry point
; =============================================================================
;   RESET vectors here.  Resets the stack, runs KernalInit to bring up the
;   Kernal RAM vectors and probe the base system, overrides the BRK vector so
;   a BRK from executed user code returns cleanly instead of diving into the
;   now-overlaid BIOS monitor, brings up the LCD and keypad PIA, seeds the
;   monitor state, shows the splash on both consoles, then holds on the splash
;   gate until an ESC arrives.
;
;   Key entry is interrupt driven, so after init it repoints IRQ_PTR at the
;   local KeyIrq handler and enables interrupts (CLI) before showing the
;   splash.  BRK is unaffected by the I flag; the BRK_PTR override below keeps
;   a BRK in executed user code from entering the overlaid BIOS monitor.
;
;   THE SPLASH GATE.  Both consoles say "--ESC TO START--" and both mean the
;   same thing: ESC, and only ESC, starts the monitor.  ESC from either source
;   starts BOTH — it is caught in KeyIrq (the KEY_ESC keycode from the keypad,
;   a $1B byte from the serial card) and jumps to WarmStart, which discards
;   everything typed at the splash, paints the LCD, and only then emits the
;   first serial prompt.  Nothing is echoed or acted on before that, so the
;   terminal never shows a "> " with no parser behind it.
; =============================================================================

CartReset:
  sei
  ldx #$ff
  txs                           ; Reset the stack pointer (required by KernalInit)

  jsr KernalInit                ; Init Kernal RAM vectors + probe base system
                                ; (clears decimal mode, leaves interrupts off)

  ; Override the BRK vector: KernalInit points it at the BIOS monitor, which
  ; the cartridge has overlaid.  Route BRK to a local RTI handler instead.
  lda #<BrkHandler
  sta BRK_PTR
  lda #>BrkHandler
  sta BRK_PTR + 1

  ; Route the IRQ through our keypad handler.  KernalInit set IRQ_PTR to the
  ; Kernal's own IRQ service; the cart drives only the keypad, so take it over.
  lda #<KeyIrq
  sta IRQ_PTR
  lda #>KeyIrq
  sta IRQ_PTR + 1

  jsr LcdInit                   ; Bring up the LCD (must precede PiaInit)
  jsr PiaInit                   ; Configure keypad + enable CA1 IRQ, clear flag

  jsr SerInit                   ; Bring up the serial card + Wozmon parser state

  stz KEY_READY                 ; no key pending yet

  ; Seed monitor state: start at user RAM ($0800), edit mode off
  lda #<PROGRAM_START
  sta CUR_ADDR
  lda #>PROGRAM_START
  sta CUR_ADDR + 1
  stz MODE

  cli                           ; enable IRQs — keypad CA1 + serial RX drive input

  ; LCD splash first — it must never depend on the serial terminal being
  ; connected.  (SerialChrout/our serial TX blocks on TDRE, which the R65C51
  ; gates on /CTS; with no terminal connected the serial banner would stall.)
  jsr ShowSplash                ; "KIM MONITOR v1.0" / "--ESC TO START--"

  ; The same two lines over the wire, so the terminal is told exactly what the
  ; panel says.  Emitted through the non-blocking SerPutc path, so a missing or
  ; disconnected terminal just drops these bytes instead of hanging the keypad
  ; monitor.  No prompt yet — see the gate below.
  lda #CHAR_CR
  jsr SerEcho                   ; CR -> CR/LF: start on a clean line
  lda #<SplashL1
  sta STR_PTR
  lda #>SplashL1
  sta STR_PTR + 1
  jsr SerPrintStr               ; "KIM MONITOR v1.0"
  lda #CHAR_CR
  jsr SerEcho
  lda #<SplashL2
  sta STR_PTR
  lda #>SplashL2
  sta STR_PTR + 1
  jsr SerPrintStr               ; "--ESC TO START--"

  ; Splash gate.  ESC — and nothing else — starts the monitor, identically
  ; from either console: KeyIrq catches KEY_ESC from the keypad and $1B from
  ; the serial card and JMPs to WarmStart, which flushes both inputs, paints
  ; the address/byte display on the LCD, and only then emits the first serial
  ; prompt.  So there is nothing to poll for here; anything typed or pressed
  ; at the splash is discarded by WarmStart rather than echoed, acted on, or
  ; left in the ring to execute later.
@WaitStart:
  bra @WaitStart                ; ESC (either console) -> KeyIrq -> WarmStart


; =============================================================================
;   MONITOR STATE MACHINE
; =============================================================================
;   A KIM-1-style memory monitor.  The display shows the current address and
;   the byte stored there; the keypad navigates, edits, and executes.
;
;     LEFT / RIGHT   address -1 / +1
;     PGUP / PGDN    address +$0100 / -$0100
;     0-F            INS off: shift a hex nibble into the address (KIM-1 style)
;                    INS on : shift a hex nibble into the byte at the address
;     INS            toggle edit mode
;     DEL            zero the byte at the address, cancel edit mode
;     UP             execute via JSR (jmp (CUR_ADDR)); RTS returns to monitor
;     ESC            break-to-monitor abort (handled in KeyIrq -> WarmStart)
; =============================================================================

; -----------------------------------------------------------------------------
;   WarmStart — break-to-monitor abort target
; -----------------------------------------------------------------------------
;   Entered by JMP from KeyIrq when an ESC arrives from EITHER source — the
;   keypad ESC key or an ESC byte over serial — from anywhere, including a
;   program launched with keypad UP or with the serial "R" command.  The
;   interrupted stack frame is abandoned: ESC is a panic "return to the
;   monitor" and does not restore the aborted caller.
;
;   Resets the stack pointer (the IRQ and whatever it interrupted are
;   discarded), cancels any in-progress INS edit, discards pending input from
;   BOTH sources, re-enables interrupts (KeyIrq was entered with I set),
;   repaints the keypad monitor (LCD) and re-arms the serial monitor with a
;   fresh prompt, then re-enters the monitor loop.
;
;   Discarding both inputs is what makes the two consoles agree.  This is also
;   the boot path (CartReset's splash gate falls in here on the first ESC), so
;   a key pressed or a line typed at the splash must not be dispatched or
;   parsed afterwards — an aborted program's leftover keystrokes have no more
;   business running than a splash-screen one does.
; -----------------------------------------------------------------------------
WarmStart:
  ldx #$ff
  txs                           ; discard the interrupted stack frame
  stz MODE                      ; cancel any in-progress INS edit
  stz KEY_READY                 ; drop any keypad press latched but not yet
                                ;   dispatched (still inside the IRQ-masked
  lda SER_RXHEAD                ;   window, so KeyIrq cannot race either flush)
  sta SER_RXTAIL                ; flush any buffered serial input
  stz SER_DIRTY                 ; (SerPrompt below resets the line buffer)
  cli                           ; KeyIrq left I set — re-enable IRQs
  jsr RefreshDisplay            ; repaint the keypad monitor (LCD)
  jsr SerPrompt                 ; and re-arm the serial monitor (fresh prompt)
  jmp MonitorLoop

; -----------------------------------------------------------------------------
;   MonitorLoop — cooperative poll of both inputs
; -----------------------------------------------------------------------------
;   The keypad and the Wozmon serial monitor run concurrently from this one
;   loop; neither input blocks.  A keypad press is dispatched and repaints the
;   LCD.  Serial bytes are drained one at a time into the Wozmon line parser;
;   when a serial line deposits into memory the SER_DIRTY flag triggers a
;   refresh so the change shows on the LCD at the current address.
; -----------------------------------------------------------------------------
MonitorLoop:
  jsr KeyPoll                   ; C=1 -> A = keycode (0-23)
  bcc @Serial
  jsr Dispatch
  jsr RefreshDisplay
@Serial:
  jsr SerService                ; process up to one pending serial byte
  lda SER_DIRTY                 ; did a serial deposit change memory?
  beq MonitorLoop
  stz SER_DIRTY
  jsr RefreshDisplay            ; reflect the serial deposit on the LCD
  bra MonitorLoop

; -----------------------------------------------------------------------------
;   Dispatch — act on a keycode
;   In: A = keycode (0-23)
;   Modifies: A, X, Y
; -----------------------------------------------------------------------------
Dispatch:
  cmp #KEY_LEFT
  beq DoLeft
  cmp #KEY_RIGHT
  beq DoRight
  cmp #KEY_PGUP
  beq DoPgUp
  cmp #KEY_PGDN
  beq DoPgDn
  cmp #KEY_INS
  beq DoIns
  cmp #KEY_DEL
  beq DoDel
  cmp #KEY_UP
  beq DoUp
  jsr KeyToHex                  ; hex digit?  C=1 -> A = nibble (0-15)
  bcc @Done                     ; non-hex key: ignore
  ldx MODE
  bne @EditData                 ; INS on: edit the byte at the address
  jmp ShiftAddrNibble           ; INS off: shift the nibble into the address
@EditData:
  jmp ShiftDataNibble
@Done:
  rts

; --- Navigation -------------------------------------------------------------
DoLeft:
  lda CUR_ADDR
  bne @NoBorrow
  dec CUR_ADDR + 1
@NoBorrow:
  dec CUR_ADDR
  rts

DoRight:
  inc CUR_ADDR
  bne @Done
  inc CUR_ADDR + 1
@Done:
  rts

DoPgUp:
  inc CUR_ADDR + 1              ; +$0100
  rts

DoPgDn:
  dec CUR_ADDR + 1              ; -$0100
  rts

; --- Mode / edit ------------------------------------------------------------
DoIns:
  lda MODE
  eor #MODE_INS                 ; toggle the edit-mode flag
  sta MODE
  rts

DoDel:
  lda #$00
  ldy #$00
  sta (CUR_ADDR),y              ; zero the byte at the address
  stz MODE                      ; cancel edit mode
  rts

; --- Execute ----------------------------------------------------------------
DoUp:
  jsr CallUser                  ; jmp (CUR_ADDR); user RTS returns here
  rts

CallUser:
  jmp (CUR_ADDR)

; -----------------------------------------------------------------------------
;   ShiftAddrNibble — shift one hex nibble into CUR_ADDR (KIM-1 style)
;   In: A = nibble (low 4 bits)
;   Modifies: A, X
; -----------------------------------------------------------------------------
ShiftAddrNibble:
  pha
  ldx #$04                      ; CUR_ADDR <<= 4 (16-bit)
@Shift:
  asl CUR_ADDR
  rol CUR_ADDR + 1
  dex
  bne @Shift
  pla
  ora CUR_ADDR                  ; OR the new nibble into the low byte
  sta CUR_ADDR
  rts

; -----------------------------------------------------------------------------
;   ShiftDataNibble — shift one hex nibble into the byte at CUR_ADDR
;   In: A = nibble (low 4 bits)
;   Modifies: A, Y
; -----------------------------------------------------------------------------
ShiftDataNibble:
  sta MON_TMP
  ldy #$00
  lda (CUR_ADDR),y
  asl a                         ; old byte <<= 4
  asl a
  asl a
  asl a
  ora MON_TMP                   ; OR in the new nibble
  sta (CUR_ADDR),y
  rts

; -----------------------------------------------------------------------------
;   RefreshDisplay — render the monitor screen
;   Line 1: ---$XXXX: $XX---   (address and the byte stored there)
;   Line 2: 16 dashes, or a centered "INS" indicator when editing
;   Modifies: A, X, Y
; -----------------------------------------------------------------------------
RefreshDisplay:
  ldx #$00
  ldy #$00
  jsr LcdSetPos                 ; line 1, column 0

  ldx #$03                      ; "---"
  jsr PrintDashN
  lda #'$'
  jsr LcdData
  lda CUR_ADDR + 1              ; address (high byte first)
  jsr PrintHexByte
  lda CUR_ADDR
  jsr PrintHexByte
  lda #':'
  jsr LcdData
  lda #CHAR_SPACE
  jsr LcdData
  lda #'$'
  jsr LcdData
  ldy #$00                      ; byte at the current address
  lda (CUR_ADDR),y
  jsr PrintHexByte
  ldx #$03                      ; "---"
  jsr PrintDashN

  ldx #$00
  ldy #$01
  jsr LcdSetPos                 ; line 2, column 0
  lda MODE
  bne @Ins
  ldx #$10                      ; 16 dashes
  jsr PrintDashN
  rts
@Ins:
  ldx #$06                      ; 6 dashes + "INS" + 7 dashes = 16
  jsr PrintDashN
  lda #'I'
  jsr LcdData
  lda #'N'
  jsr LcdData
  lda #'S'
  jsr LcdData
  ldx #$07
  jsr PrintDashN
  rts

; -----------------------------------------------------------------------------
;   PrintDashN — print X dash characters
;   In: X = count
;   Modifies: A, X, Y
; -----------------------------------------------------------------------------
PrintDashN:
@Loop:
  cpx #$00
  beq @Done
  phx                           ; LcdData (via LcdDelay) clobbers X/Y
  lda #'-'
  jsr LcdData
  plx
  dex
  bra @Loop
@Done:
  rts

; -----------------------------------------------------------------------------
;   ShowSplash — clear the display and render the splash screen
;   Modifies: A, X, Y
; -----------------------------------------------------------------------------
ShowSplash:
  jsr LcdClear
  ldx #$00
  ldy #$00
  jsr LcdSetPos
  lda #<SplashL1
  sta STR_PTR
  lda #>SplashL1
  sta STR_PTR + 1
  jsr LcdPrintStr
  ldx #$00
  ldy #$01
  jsr LcdSetPos
  lda #<SplashL2
  sta STR_PTR
  lda #>SplashL2
  sta STR_PTR + 1
  jsr LcdPrintStr
  rts


; =============================================================================
;   LCD DRIVER
; =============================================================================
;   HD44780-compatible 16x2 display in 8-bit mode.  Port B carries the data
;   bus; Port A carries RS/R-W/E on PA5/PA6/PA7.  Command/data writes use
;   timed software delays instead of busy-flag polling (the R/W read-back
;   path is not relied upon).
; =============================================================================

; -----------------------------------------------------------------------------
;   LcdDelay — short software busy delay (~640 us @ 1 MHz)
; -----------------------------------------------------------------------------
;   Used in place of busy-flag polling so the driver does not depend on the
;   LCD R/W read-back path (PA6) working.  An HD44780 finishes a normal
;   command/data write in ~37 us, so this single ~640 us loop carries a wide
;   margin while staying short enough that a full RefreshDisplay (~34 writes)
;   completes in ~22 ms — fast enough to keep the keypad responsive.  Callers
;   add LcdLongDelay for the slow clear/home commands (~1.5 ms).
;   Modifies: A, X
; -----------------------------------------------------------------------------
LcdDelay:
  ldx #$80                      ; 128 * 5 cycles ≈ 640 us @ 1 MHz
@Loop:
  dex
  bne @Loop
  rts

; -----------------------------------------------------------------------------
;   LcdLongDelay — generous software delay for the power-on init ritual
; -----------------------------------------------------------------------------
;   Covers the HD44780 power-on timing (>15 ms first delay, >4.1 ms / >100 us
;   between the function-set writes) and the slow clear/home commands (~1.5 ms).
;   Self-contained — does not depend on KernalInit / SysDelay (and therefore
;   not on HW_PRESENT / the VIA timer).  ~41 ms @ 1 MHz: comfortably above the
;   >15 ms power-on minimum, yet short enough that boot (run with IRQs masked)
;   no longer swallows early ESC presses.
;   Modifies: A, X, Y
; -----------------------------------------------------------------------------
LcdLongDelay:
  ldx #$20                      ; 32 * 256 * 5 cycles ≈ 41 ms @ 1 MHz
@Outer:
  ldy #$00
@Inner:
  dey
  bne @Inner
  dex
  bne @Outer
  rts

; -----------------------------------------------------------------------------
;   LcdStrobe — pulse E high then low (data already on Port B, RS/R-W in A)
; -----------------------------------------------------------------------------
;   In: A = Port A control value with E low (RS/R-W set, LCD_E clear)
;   Modifies: A
; -----------------------------------------------------------------------------
LcdStrobe:
  sta PORTA                     ; control lines, E low
  ora #LCD_E
  sta PORTA                     ; E high
  and #<~LCD_E
  sta PORTA                     ; E low — LCD latches on falling edge
  rts

; -----------------------------------------------------------------------------
;   LcdCmd — write a command byte (RS=0)
;   In: A = command
;   Modifies: A, X, Y
; -----------------------------------------------------------------------------
LcdCmd:
  sta PORTB                     ; command byte on the data bus
  lda #$00                      ; RS=0, R/W=0, E=0
  jsr LcdStrobe
  jsr LcdDelay
  rts

; -----------------------------------------------------------------------------
;   LcdData — write a data byte (RS=1)
;   In: A = data
;   Modifies: A, X, Y
; -----------------------------------------------------------------------------
LcdData:
  sta PORTB                     ; data byte on the data bus
  lda #LCD_RS                   ; RS=1, R/W=0, E=0
  jsr LcdStrobe
  jsr LcdDelay
  rts

; -----------------------------------------------------------------------------
;   LcdCmdRaw — write a command byte (alias of LcdCmd)
;   Retained for the power-on function-set sequence which adds its own
;   longer inter-command delays via LcdLongDelay.
;   In: A = command
;   Modifies: A, X, Y
; -----------------------------------------------------------------------------
LcdCmdRaw = LcdCmd

; -----------------------------------------------------------------------------
;   LcdInit — power-on initialization sequence
;   Configures the PIA ports the LCD needs, then runs the HD44780 8-bit
;   init: function set (2-line, 5x8), display on, clear, entry-mode increment.
;   Uses software delays only — no KernalInit / SysDelay dependency.
;   Modifies: A, X, Y
; -----------------------------------------------------------------------------
LcdInit:
  ; Port A: PA5-7 outputs (LCD control), PA0-4 inputs (keypad code)
  lda #CR_DDR
  sta CRA
  lda #LCD_DDRA
  sta PORTA                     ; (DDRA) = $E0
  lda #CR_PORT
  sta CRA
  lda #$00
  sta PORTA                     ; control lines low (RS=0, R/W=0, E=0)

  ; Port B: all outputs (LCD data bus)
  lda #CR_DDR
  sta CRB
  lda #$FF
  sta PORTB                     ; (DDRB) all outputs
  lda #CR_PORT
  sta CRB

  ; Power-on settle: > 15 ms
  jsr LcdLongDelay

  ; Function set x3 with long inter-command delays (HD44780 reset ritual)
  lda #$30
  jsr LcdCmdRaw
  jsr LcdLongDelay              ; > 4.1 ms
  lda #$30
  jsr LcdCmdRaw
  jsr LcdLongDelay              ; > 100 us
  lda #$30
  jsr LcdCmdRaw
  jsr LcdLongDelay

  ; Remaining configuration commands (each followed by LcdDelay)
  lda #$38                      ; function set: 8-bit, 2-line, 5x8 font
  jsr LcdCmd
  lda #$08                      ; display off
  jsr LcdCmd
  lda #$01                      ; clear display
  jsr LcdCmd
  jsr LcdLongDelay              ; clear is slow (~1.5 ms) — extra settle
  lda #$06                      ; entry mode: increment, no display shift
  jsr LcdCmd
  lda #$0C                      ; display on, cursor off, blink off
  jsr LcdCmd
  rts

; -----------------------------------------------------------------------------
;   LcdClear — clear the display and home the cursor
;   Modifies: A, X
; -----------------------------------------------------------------------------
LcdClear:
  lda #$01
  jsr LcdCmd
  jsr LcdLongDelay              ; clear/home is slow (~1.5 ms) — LcdDelay alone
  rts                           ;   is now too short to cover it

; -----------------------------------------------------------------------------
;   LcdSetPos — move the cursor to (column, row)
;   In: X = column (0-15), Y = row (0-1)
;   Modifies: A, X
; -----------------------------------------------------------------------------
LcdSetPos:
  txa
  cpy #$00
  beq @Row1
  clc
  adc #$40                      ; row 2 DDRAM base offset
@Row1:
  ora #$80                      ; "Set DDRAM address" command
  jsr LcdCmd
  rts

; -----------------------------------------------------------------------------
;   LcdPrintStr — print a null-terminated string
;   In: STR_PTR ($02-$03) = pointer to string
;   Modifies: A, X, Y
; -----------------------------------------------------------------------------
LcdPrintStr:
  ldy #$00
@Loop:
  lda (STR_PTR),y
  beq @Done                     ; null terminator
  phy                           ; LcdData (via delays) clobbers Y
  jsr LcdData
  ply
  iny
  bne @Loop                     ; max 256 chars per call
@Done:
  rts

; -----------------------------------------------------------------------------
;   PrintHexNib — print the low nibble of A as a hex digit
;   In: A = value (low nibble used)
;   Modifies: A, X
; -----------------------------------------------------------------------------
PrintHexNib:
  and #$0F
  cmp #$0A
  bcc @Digit
  adc #$36                      ; C=1: 10..15 + $37 -> 'A'..'F'
  bne @Send                     ; result always nonzero
@Digit:
  adc #$30                      ; C=0: 0..9 + $30 -> '0'..'9'
@Send:
  jsr LcdData
  rts

; -----------------------------------------------------------------------------
;   PrintHexByte — print A as two hex digits
;   In: A = byte
;   Modifies: A, X
; -----------------------------------------------------------------------------
PrintHexByte:
  pha
  lsr a
  lsr a
  lsr a
  lsr a
  jsr PrintHexNib               ; high nibble
  pla
  jsr PrintHexNib               ; low nibble
  rts

; -----------------------------------------------------------------------------
;   PrintHexWord — print a 16-bit value as four hex digits (high byte first)
;   In: X = high byte, A = low byte
;   Modifies: A, X
; -----------------------------------------------------------------------------
PrintHexWord:
  pha
  txa
  jsr PrintHexByte              ; high byte
  pla
  jsr PrintHexByte              ; low byte
  rts


; =============================================================================
;   KEYPAD DRIVER
; =============================================================================
;   The 74C922 keypad encoder drives PA0-PA4 with a 5-bit keycode and pulses
;   CA1 (positive edge) when a key becomes available.  CA2 is held low to
;   enable the encoder's active-low output enable.  Key entry is interrupt
;   driven: the CA1 edge fires KeyIrq, which latches the keycode into a small
;   mailbox (KEY_CODE/KEY_READY) that the monitor loop drains via KeyWait.
; =============================================================================

; -----------------------------------------------------------------------------
;   PiaInit — configure the PIA for keypad input (and Port B for LCD data)
; -----------------------------------------------------------------------------
;   Sets DDRA so PA5-7 are outputs (LCD control) and PA0-4 inputs (keycode),
;   DDRB all outputs (LCD data bus), then writes the keypad CRA value which
;   enables the 74C922 (CA2 low) and arms CA1 on the positive edge with its
;   interrupt ENABLED.  The CPU IRQ must stay masked until the caller is
;   ready — CartReset CLIs only after this returns.  Reads PORTA once to clear
;   any stale CA1 flag.  Must be called AFTER LcdInit (leaves CRA on PORT).
;   Modifies: A
; -----------------------------------------------------------------------------
PiaInit:
  ; Port A direction: PA5-7 outputs, PA0-4 inputs
  lda #CR_DDR
  sta CRA
  lda #LCD_DDRA                 ; $E0
  sta PORTA                     ; (DDRA)

  ; Port B direction: all outputs (LCD data bus)
  lda #CR_DDR
  sta CRB
  lda #$FF
  sta PORTB                     ; (DDRB)
  lda #CR_PORT
  sta CRB                       ; select PORTB data register

  ; Port A control: CA2 manual output low (74C922 OE), CA1 positive edge,
  ; CA1 IRQ enabled, PORTA data register selected
  lda #PIA_CRA_KEYPAD           ; $37
  sta CRA

  lda PORTA                     ; clear any pending CA1 flag
  rts

; -----------------------------------------------------------------------------
;   KeyIrq — CA1 (keypad data-available) interrupt handler
; -----------------------------------------------------------------------------
;   Installed in IRQ_PTR by CartReset and reached through the IRQ vector
;   trampoline (jmp (IRQ_PTR)).  Because the cartridge owns the IRQ, this
;   handler also dispatches BRK (which shares the vector) to BRK_PTR so
;   executed user code keeps its clean-return behaviour.
;
;   The IRQ has two sources sharing the line: the R65C51 serial RX
;   and the keypad CA1 edge.  Serial is serviced first so a fast host stream
;   is never dropped while a key is also pending: if SC_STATUS shows RDRF, the
;   byte is read; an ESC byte triggers a break-to-monitor abort (WarmStart),
;   any other byte is pushed into the SER_RXBUF ring.  The serial half is
;   skipped entirely when no Serial Card was probed (HW_SC clear), so a
;   keypad-only machine never reads a floating bus here.  Then, on a keypad CA1
;   edge it reads PORTA *once*, right at the data-available edge where the
;   74C922 outputs are valid, masks the 5-bit keycode, rejects out-of-range
;   phantom codes, and either aborts on the ESC key or stores the keycode in
;   the KEY_CODE/KEY_READY mailbox.  Reading PORTA clears the CA1 flag.
;   Modifies: nothing visible (saves/restores A and X)
; -----------------------------------------------------------------------------
KeyIrq:
  pha
  phx
  tsx
  lda $0103,x                   ; stacked processor status (P)
  and #$10                      ; B flag set -> this was a BRK, not an IRQ
  bne @Brk

  ; Two sources share the CPU /IRQ line: the keypad PIA (CA1 edge) and the
  ; R65C51 ACIA (serial RX).  Both are serviced every entry, and the loop
  ; below keeps draining until neither has work pending — this is what keeps a
  ; break-to-monitor ESC reliable from *either* source while a launched program
  ; is running (the cooperative main loop, and thus the SerFeed parser, is
  ; suspended then, so ESC must be caught here in the ISR).  The keypad is
  ; checked first because that path is the proven one; the serial
  ; drain loop guarantees a serial ESC can never be stranded behind an ACIA
  ; receive overrun.
@Scan:
  ; --- Keypad CA1 source ----------------------------------------------------
  lda CRA
  and #PIA_CA1_FLAG             ; keypad data-available?
  beq @Serial                   ; no keypad edge — go drain the serial card
  lda PORTA                     ; latch keycode (also clears the CA1 flag)
  and #KEY_MASK                 ; keep PA0-4 (0-31)
  cmp #KEY_ESC                  ; ESC is a break-to-monitor abort
  beq @Esc                      ; -> WarmStart, never reaches the mailbox
  cmp #KEY_COUNT
  bcs @Serial                   ; phantom code >= 24 — discard, still drain SC
  sta KEY_CODE                  ; mailbox: keycode
  lda #$01
  sta KEY_READY                 ; signal the monitor loop

  ; --- Serial RX source (R65C51 ACIA) ---------------------------------------
@Serial:
  lda HW_PRESENT
  and #HW_SC                    ; no Serial Card -> $9001 is open bus, and a
  beq @Exit                     ;   floating RDRF would inject phantom bytes
  lda SC_STATUS                 ; reading status also clears the ACIA IRQ flag
  and #SC_STATUS_RDRF           ; RX data register full?
  beq @Exit                     ; nothing buffered in the ACIA — done
  lda SC_DATA                   ; read it (clears RDRF / the overrun flag)
  cmp #CHAR_ESC                 ; serial ESC is a break-to-monitor abort, just
  beq @Esc                      ;   like the keypad ESC key -> WarmStart
  ldx SER_RXHEAD
  sta SER_RXBUF,x               ; otherwise push the byte into the RX ring
  inc SER_RXHEAD                ; byte index wraps naturally at 256
  bra @Scan                     ; got a byte — re-scan both sources (drains the
                                ;   ACIA fully so a queued ESC is never missed)
@Exit:
  plx
  pla
  rti
@Brk:
  plx                           ; restore regs; leave P/PCL/PCH on the stack
  pla
  jmp (BRK_PTR)                 ; BrkHandler RTIs back to the user code
@Esc:
  jmp WarmStart                 ; abandon the interrupted frame, re-enter monitor

; -----------------------------------------------------------------------------
;   KeyPoll — non-blocking keypad read (drains the KeyIrq mailbox)
;   Out: C=1 -> A = keycode (0-23);  C=0 -> no key pending (A undefined)
;   Modifies: A
; -----------------------------------------------------------------------------
KeyPoll:
  lda KEY_READY
  beq @None                     ; nothing latched
  sei                           ; grab the mailbox atomically vs KeyIrq
  lda KEY_CODE
  stz KEY_READY
  cli
  sec                           ; C=1: key available
  rts
@None:
  clc                           ; C=0: no key
  rts

; -----------------------------------------------------------------------------
;   KeyWait — block until a key is available
;   Out: A = keycode (0-23)
;   Modifies: A
; -----------------------------------------------------------------------------
KeyWait:
  jsr KeyPoll
  bcc KeyWait
  rts

; -----------------------------------------------------------------------------
;   KeyToSym — translate a keycode to a printable LCD symbol
;   In:  A = keycode (0-23)
;   Out: A = display character
;   Modifies: A, X
; -----------------------------------------------------------------------------
KeyToSym:
  tax
  lda KeySymTable,x
  rts


; -----------------------------------------------------------------------------
;   KeyToHex — translate a keycode to its hex nibble value
; -----------------------------------------------------------------------------
;   In:  A = keycode (0-23)
;   Out: C=1 -> A = nibble (0-15) for a hex-digit key (0-9, A-F)
;        C=0 -> the key is not a hex digit (A preserved as $FF)
;   Modifies: A, X
; -----------------------------------------------------------------------------
KeyToHex:
  tax
  lda HexValTable,x
  cmp #$FF                      ; sentinel: not a hex digit
  beq @NotHex
  sec                           ; C=1: A holds the nibble
  rts
@NotHex:
  clc                           ; C=0: not a hex key
  rts


; =============================================================================
;   SERIAL WOZMON MONITOR
; =============================================================================
;   A Wozmon-compatible serial monitor that shares memory with the keypad
;   monitor and runs concurrently with it.  The command language follows
;   Apple-1 Wozmon, so bin2woz output (deposit lines of the form
;   "ADDR: BB BB ...") is accepted byte-for-byte:
;
;     XXXX            examine the byte at XXXX
;     XXXX.YYYY       examine the block XXXX..YYYY
;     XXXX: BB BB ..  deposit bytes starting at XXXX (auto-incrementing)
;     XXXX R          call XXXX as a subroutine; RTS returns to the prompt
;
;   Two deliberate departures from the original, in syntax neither:
;
;     - the prompt is "> " rather than "\".
;     - "R" is a JSR, not Wozmon's JMP (XAML).  On this machine the keypad's
;       UP key already runs the program under the cursor as a subroutine
;       (DoUp -> CallUser), and an RTS comes back to a live monitor.  Serial
;       "R" behaving differently made the two consoles disagree about what
;       running a program means: original-Wozmon "R" left the parser for good,
;       so a program that ended in RTS came back to a monitor with no prompt
;       and a line buffer still holding the "XXXX R" that launched it — the
;       next line typed appended to it and re-ran the program.  One rule for
;       both consoles instead: run it, RTS comes home.  A program that never
;       returns is unaffected; ESC still breaks out of one.
;
;   The IRQ handler (KeyIrq) pushes received bytes into the SER_RXBUF ring;
;   the cooperative main loop drains the ring through SerService one byte at a
;   time so the keypad stays responsive during a host stream.
;
;   Faithfulness note: incoming bytes have bit 7 set before parsing, exactly as
;   the Apple-1 keyboard delivered them, so Wozmon's original byte comparisons
;   and hex-decode arithmetic work unmodified.  Output clears bit 7 (and maps
;   CR -> CR/LF) on the way to the serial port.
; =============================================================================

; -----------------------------------------------------------------------------
;   SerInit — bring up the serial card and reset the Wozmon parser state
;   Called from CartReset before interrupts are enabled.
;
;   The Serial Card is optional hardware, so the ACIA is only touched when the
;   boot probe actually found one (HW_PRESENT bit HW_SC), matching the guarding
;   convention the Kernal uses for every other card.  The parser state is reset
;   either way, so the Ser* routines stay safe to call on a keypad-only build.
;   Modifies: A
; -----------------------------------------------------------------------------
SerInit:
  lda HW_PRESENT
  and #HW_SC                    ; Serial Card fitted?  (it is optional hardware)
  beq @NoCard                   ; no — leave $9000 alone, run keypad-only
  jsr InitSC                    ; BIOS: 8-N-1, 19200 baud, RX IRQ enabled
@NoCard:
  stz SER_RXHEAD                ; empty RX ring
  stz SER_RXTAIL
  stz SER_IDX                   ; empty line buffer
  stz WMODE                     ; XAM mode
  stz SER_DIRTY
  rts

; -----------------------------------------------------------------------------
;   SerService — drain at most one byte from the RX ring into the parser
;   Non-blocking.  Tail-calls SerFeed (which may run a full line on CR).
;   Modifies: A, X, Y
; -----------------------------------------------------------------------------
SerService:
  jsr SerGetChar
  bcc @None
  jmp SerFeed                   ; tail-call: SerFeed returns to our caller
@None:
  rts

; -----------------------------------------------------------------------------
;   SerGetChar — pull one byte from the RX ring (filled by KeyIrq)
;   Out: C=1 -> A = byte with bit 7 set (Apple-1 style); C=0 -> ring empty
;   Modifies: A, X
; -----------------------------------------------------------------------------
SerGetChar:
  lda SER_RXTAIL
  cmp SER_RXHEAD
  beq @Empty                    ; tail == head -> nothing buffered
  tax
  lda SER_RXBUF,x               ; fetch the oldest byte
  inc SER_RXTAIL                ; advance (wraps at 256)
  ora #$80                      ; set bit 7 for the Wozmon parser
  sec
  rts
@Empty:
  clc
  rts

; -----------------------------------------------------------------------------
;   SerFeed — accumulate one received byte into the line buffer
;   In: A = byte (bit 7 set).  Handles backspace / CR like Wozmon's character
;   loop; a CR runs the line through SerProcess.  ESC is NOT handled here — it
;   is consumed in the ISR (KeyIrq) as a break-to-monitor abort, so it never
;   reaches the RX ring or this parser.
;   Modifies: A, X, Y
; -----------------------------------------------------------------------------
SerFeed:
  cmp #$DF                      ; "_" backspace (Apple-1)?
  beq @Bs
  cmp #$88                      ; BS ($08|$80)?
  beq @Bs
  cmp #$FF                      ; DEL ($7F|$80)?
  beq @Bs
  ldy SER_IDX
  sta SER_LINEBUF,y             ; store into the line buffer
  cmp #$8D                      ; CR ($0D|$80)?  (test before echo clobbers A)
  beq @Cr
  jsr SerEcho                   ; echo the typed character
  iny
  bpl @Store                    ; line < 128 chars — keep going
  bra @Cancel                   ; over-long line: discard it, fresh prompt
@Store:
  sty SER_IDX
  rts
@Cr:
  jsr SerEcho                   ; echo CR -> CR/LF
  jmp SerProcess                ; parse and act on the completed line
@Cancel:
  jmp SerPrompt                 ; discard the line, fresh prompt
@Bs:
  ldy SER_IDX
  beq @BsDone                   ; already at the start — nothing to erase
  dey
  sty SER_IDX
  lda #$88                      ; visually erase on the terminal: BS, space, BS
  jsr SerEcho
  lda #$A0                      ; space
  jsr SerEcho
  lda #$88
  jsr SerEcho
@BsDone:
  rts

; -----------------------------------------------------------------------------
;   SerProcess — parse and execute a completed Wozmon line
; -----------------------------------------------------------------------------
;   Port of the Apple-1 Wozmon line interpreter.  The line lives in
;   SER_LINEBUF, terminated by the CR ($8D) at SER_IDX.  Examine / block
;   examine / deposit follow the original semantics exactly; run is a
;   subroutine call rather than Wozmon's jump (see the section header).
;   Modifies: A, X, Y
; -----------------------------------------------------------------------------
SerProcess:
  ldy #$ff                      ; reset the text index (INY -> 0 below)
  lda #$00                      ; default XAM mode
  tax                           ; 0 -> X
@SetStor:
  asl a                         ; ":" arrives as $BA -> $74 (STOR); XAM stays 0
@SetMode:
  sta WMODE                     ; $00=XAM, $74=STOR, $AE=BLOCK XAM
@BlSkip:
  iny                           ; advance the text index
@NextItem:
  lda SER_LINEBUF,y             ; next character
  cmp #$8D                      ; CR -> end of line
  bne @ChkDot
  jmp SerPrompt                 ; line consumed — emit the next prompt
@ChkDot:
  cmp #$AE                      ; "."?
  bcc @BlSkip                   ; below "." -> delimiter, skip it
  beq @SetMode                  ; "." -> BLOCK XAM mode (A=$AE)
  cmp #$BA                      ; ":"?
  beq @SetStor                  ; ":" -> STOR mode (A=$BA)
  cmp #$D2                      ; "R"?
  beq @Run                      ; run user program
  stx L                         ; clear the hex accumulator
  stx H
  sty YSAV                      ; remember where the number started
@NextHex:
  lda SER_LINEBUF,y             ; get a character for the hex test
  eor #$B0                      ; map "0".."9" to $0-$9
  cmp #$0A                      ; decimal digit?
  bcc @Dig
  adc #$88                      ; map "A".."F" to $FA-$FF
  cmp #$FA                      ; valid hex letter?
  bcc @NotHex                   ; no — not a hex character
@Dig:
  asl a
  asl a                         ; hex digit to the MSD of A
  asl a
  asl a
  ldx #$04                      ; shift count
@HexShift:
  asl a                         ; hex digit left, MSB into carry
  rol L                         ; rotate into the accumulator
  rol H
  dex
  bne @HexShift
  iny                           ; advance the text index
  bne @NextHex                  ; always taken (Y < 256)
@NotHex:
  cpy YSAV                      ; were any hex digits given?
  beq @Escape                   ; none -> treat as ESC
  bit WMODE                     ; B6=1 STOR, B6=0 XAM/BLOCK
  bvc @NotStor
  lda L                         ; deposit: store the low byte
  sta (STL,x)                   ; X=0 -> via STH:STL
  inc STL                       ; auto-increment the deposit address
  bne @Deposited
  inc STH
@Deposited:
  lda #$01
  sta SER_DIRTY                 ; memory changed — flag an LCD refresh
  jmp @NextItem
@Run:
  jsr SerCallUser               ; run at the last examined address
  jmp SerPrompt                 ; a user RTS lands here — fresh prompt
@Escape:
  jmp SerPrompt                 ; nothing parsed — fresh prompt
@NotStor:
  bmi @XamNext                  ; B7=1 -> BLOCK XAM continuation
  ldx #$02                      ; copy the hex value to the store + examine
@SetAdr:
  lda L-1,x                     ;   indices (two bytes)
  sta STL-1,x
  sta XAML-1,x
  dex
  bne @SetAdr                   ; X reaches 0 with Z=1 (prints the address)
@NxtPrnt:
  bne @PrData                   ; NE -> mid-row, no new address label
  lda #$8D                      ; CR
  jsr SerEcho
  lda XAMH                      ; print the examine address
  jsr PrByte
  lda XAML
  jsr PrByte
  lda #$BA                      ; ":"
  jsr SerEcho
@PrData:
  lda #$A0                      ; space
  jsr SerEcho
  lda (XAML,x)                  ; print the data byte (X=0)
  jsr PrByte
@XamNext:
  stx WMODE                     ; X=0 -> back to XAM mode
  lda XAML                      ; more bytes to print in the range?
  cmp L
  lda XAMH
  sbc H
  bcs @ToNextItem               ; not less -> done with this range
  inc XAML                      ; advance the examine index
  bne @Mod8
  inc XAMH
@Mod8:
  lda XAML                      ; start a new row every 8 bytes
  and #$07
  bpl @NxtPrnt                  ; always taken (result is 0-7); Z drives the
@ToNextItem:                    ;   address-label decision in @NxtPrnt
  jmp @NextItem

; -----------------------------------------------------------------------------
;   SerCallUser — call the user program at XAML
;   The 6502 has no "jsr (addr)", so the call is a jsr to this jmp — the same
;   trampoline the keypad's UP key uses (DoUp -> CallUser), one address apiece.
;   Modifies: everything the user program modifies
; -----------------------------------------------------------------------------
SerCallUser:
  jmp (XAML)

; -----------------------------------------------------------------------------
;   SerPrompt — emit a CR/LF and the "> " prompt, reset the line buffer
;   Modifies: A
; -----------------------------------------------------------------------------
SerPrompt:
  lda #CHAR_CR
  jsr SerEcho                   ; CR -> CR/LF
  lda #'>'
  jsr SerPutc
  lda #CHAR_SPACE
  jsr SerPutc
  stz SER_IDX                   ; start a fresh line
  rts

; -----------------------------------------------------------------------------
;   PrByte / PrHex — print A as two hex digits over serial (Wozmon PRBYTE)
;   In: A = byte.  PrHex falls through into SerEcho.
;   Modifies: A
; -----------------------------------------------------------------------------
PrByte:
  pha
  lsr a
  lsr a
  lsr a                         ; high nibble to the low nibble position
  lsr a
  jsr PrHex
  pla
PrHex:
  and #$0F                      ; mask the low nibble
  ora #$B0                      ; "0".."9"
  cmp #$BA
  bcc SerEcho                   ; a digit — send it
  adc #$06                      ; letter offset: "A".."F"
  ; fall through to SerEcho

; -----------------------------------------------------------------------------
;   SerEcho — send one character to the serial port
;   In: A = character (bit 7 may be set).  Clears bit 7 and maps CR -> CR/LF.
;   Preserves X and Y (the line parser holds state in them across echoes).
;   Modifies: A
; -----------------------------------------------------------------------------
SerEcho:
  phx
  phy
  and #$7F                      ; back to plain ASCII
  cmp #CHAR_CR                  ; CR?
  bne @One
  lda #CHAR_CR
  jsr SerPutc
  lda #CHAR_LF                  ; CR -> CR + LF
  jsr SerPutc
  bra @Done
@One:
  jsr SerPutc
@Done:
  ply
  plx
  rts

; -----------------------------------------------------------------------------
;   SerPutc — send one byte to the serial port, NON-BLOCKING
; -----------------------------------------------------------------------------
;   In: A = byte (sent as-is).  Preserves X and Y.
;   Unlike the BIOS SerialChrout (which blocks until TDRE — and therefore
;   hangs forever when the R65C51's /CTS is not asserted by a connected
;   terminal), this waits for TX-ready only for a bounded time and then drops
;   the byte.  That keeps the keypad monitor fully alive whether or not a host
;   terminal is attached.  When a terminal IS connected it exits as soon as
;   TDRE sets, so back-to-back bytes are not dropped.
;   Modifies: A
; -----------------------------------------------------------------------------
SerPutc:
  pha                           ; save the byte on the stack
  phx
  phy
  lda HW_PRESENT
  and #HW_SC                    ; Serial Card fitted?
  beq @Drop                     ; no — drop the byte without touching $9000
                                ;   (and without paying the TDRE timeout)
  ldx #$08                      ; bounded TDRE wait (~16-bit countdown)
@WaitHi:
  ldy #$00
@WaitLo:
  lda SC_STATUS
  and #SC_STATUS_TDRE           ; TX data register empty?
  bne @Send
  dey
  bne @WaitLo
  dex
  bne @WaitHi
  ; timeout — no terminal; drop the byte
@Drop:
  ply
  plx
  pla
  rts
@Send:
  ply
  plx
  pla                           ; recover the byte
  sta SC_DATA                   ; transmit it
  rts

; -----------------------------------------------------------------------------
;   SerPrintStr — send a null-terminated string over serial
;   In: STR_PTR ($02-$03) = pointer to the string
;   Modifies: A, Y
; -----------------------------------------------------------------------------
SerPrintStr:
  ldy #$00
@Loop:
  lda (STR_PTR),y
  beq @Done                     ; null terminator
  jsr SerEcho                   ; SerEcho preserves Y
  iny
  bne @Loop
@Done:
  rts


; =============================================================================
;   INTERRUPT HANDLERS & VECTOR TRAMPOLINES
; =============================================================================
;   The cartridge owns the hardware vectors at $FFFA-$FFFF.  Following the
;   BIOS convention, the NMI and IRQ vectors trampoline through the writable
;   RAM vectors (NMI_PTR / IRQ_PTR) that KernalInit installs.  CartReset then
;   repoints IRQ_PTR at the local KeyIrq handler so the keypad CA1 edge drives
;   key input (see the keypad driver section); NMI_PTR keeps the Kernal
;   default (RTI).
;
;   BRK shares the IRQ vector.  KeyIrq detects the B flag and dispatches via
;   BRK_PTR (-> BrkHandler) with P/PCL/PCH still on the stack, so BrkHandler
;   only needs to RTI to resume the interrupted code.
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
;   NmiVector / IrqVector — hardware-vector trampolines through the RAM vectors
; -----------------------------------------------------------------------------
NmiVector:
  jmp (NMI_PTR)                  ; default: Kernal Nmi (RTI)

IrqVector:
  jmp (IRQ_PTR)                  ; CartReset points IRQ_PTR at KeyIrq

; -----------------------------------------------------------------------------
;   BrkHandler — local BRK handler
; -----------------------------------------------------------------------------
;   Reached via JMP (BRK_PTR) from KeyIrq after a BRK.  A/X are already
;   restored and the P/PCL/PCH frame is intact, so resuming is a plain RTI.
;   This keeps a stray BRK in executed user code from entering the overlaid
;   BIOS monitor.
; -----------------------------------------------------------------------------
BrkHandler:
  rti


; =============================================================================
;   Data
; =============================================================================

SplashL1:
  .byte "KIM MONITOR v1.0", $00
SplashL2:
  .byte "--ESC TO START--", $00

; -----------------------------------------------------------------------------
;   KeySymTable — keycode (0-23) -> printable LCD symbol
; -----------------------------------------------------------------------------
;   Hex digit keys map to their hex character; navigation/command keys map to
;   a distinct printable glyph for the keypad echo test.
;     $00 LEFT  $0B RIGHT  $10 ESC  $11 INS  $12 PGUP  $14 UP  $15 DEL  $16 PGDN
; -----------------------------------------------------------------------------
KeySymTable:
  .byte '<'                     ; $00 LEFT
  .byte '1'                     ; $01
  .byte '2'                     ; $02
  .byte '3'                     ; $03
  .byte '4'                     ; $04
  .byte '5'                     ; $05
  .byte '6'                     ; $06
  .byte '7'                     ; $07
  .byte '8'                     ; $08
  .byte '9'                     ; $09
  .byte '0'                     ; $0A
  .byte '>'                     ; $0B RIGHT
  .byte 'F'                     ; $0C
  .byte 'E'                     ; $0D
  .byte 'D'                     ; $0E
  .byte 'C'                     ; $0F
  .byte '*'                     ; $10 ESC
  .byte 'I'                     ; $11 INS
  .byte 'U'                     ; $12 PGUP
  .byte 'A'                     ; $13
  .byte '^'                     ; $14 UP
  .byte 'X'                     ; $15 DEL
  .byte 'N'                     ; $16 PGDN
  .byte 'B'                     ; $17


; -----------------------------------------------------------------------------
;   HexValTable — keycode (0-23) -> hex nibble value, $FF = not a hex digit
; -----------------------------------------------------------------------------
;   Used by KeyToHex.  Maps the ten digit keys (0-9) and the six letter keys
;   (A-F) to their 0-15 nibble value; every navigation/command key maps to the
;   $FF sentinel so the dispatch loop ignores it during address/data entry.
; -----------------------------------------------------------------------------
HexValTable:
  .byte $FF                     ; $00 LEFT
  .byte $01                     ; $01 1
  .byte $02                     ; $02 2
  .byte $03                     ; $03 3
  .byte $04                     ; $04 4
  .byte $05                     ; $05 5
  .byte $06                     ; $06 6
  .byte $07                     ; $07 7
  .byte $08                     ; $08 8
  .byte $09                     ; $09 9
  .byte $00                     ; $0A 0
  .byte $FF                     ; $0B RIGHT
  .byte $0F                     ; $0C F
  .byte $0E                     ; $0D E
  .byte $0D                     ; $0E D
  .byte $0C                     ; $0F C
  .byte $FF                     ; $10 ESC
  .byte $FF                     ; $11 INS
  .byte $FF                     ; $12 PGUP
  .byte $0A                     ; $13 A
  .byte $FF                     ; $14 UP
  .byte $FF                     ; $15 DEL
  .byte $FF                     ; $16 PGDN
  .byte $0B                     ; $17 B


; =============================================================================
;   CPU Vectors — cart owns $FFFA-$FFFF
; =============================================================================
;   NMI and IRQ trampoline through the Kernal RAM vectors (see above);
;   RESET enters the cartridge.

.segment "VECTORS"

.word   NmiVector                ; NMI vector   -> jmp (NMI_PTR)
.word   CartReset                ; RESET vector — cartridge entry point
.word   IrqVector                ; IRQ vector   -> jmp (IRQ_PTR)